/*
    iGamingBI Final Project
    02_REFRESH_PLAYER_DAILY.sql

    Adds the player-date reporting ETL used by Player 360.
    Grain of dbo.fact_player_daily: one row per active player per date.

    NGR:
      GGR
      - Bonus Cost
      - Payment Fees
      - Provider Cost
      - Gaming Tax (15% of positive GGR)
      - Chargeback Cost
*/
USE iGamingBI;
GO

CREATE OR ALTER PROCEDURE dbo.sp_refresh_player_daily
    @FromDate DATE,
    @ToDate   DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @FromDate IS NULL
       OR @ToDate IS NULL
       OR @FromDate > @ToDate
    BEGIN
        RAISERROR('Valid @FromDate and @ToDate are required.',16,1);
        RETURN;
    END;

    IF OBJECT_ID('tempdb..#WalletDaily') IS NOT NULL DROP TABLE #WalletDaily;

    SELECT
        wt.player_id,
        wt.date_key,
        SUM(CASE WHEN wt.transaction_type = 'Deposit'
                  AND wt.transaction_status = 'Completed' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN wt.transaction_type = 'Deposit'
                  AND wt.transaction_status = 'Completed' THEN wt.amount_gel ELSE 0 END) AS deposit_amount_gel,
        SUM(CASE WHEN wt.transaction_type = 'Withdrawal'
                  AND wt.transaction_status = 'Completed' THEN 1 ELSE 0 END) AS withdrawal_count,
        SUM(CASE WHEN wt.transaction_type = 'Withdrawal'
                  AND wt.transaction_status = 'Completed' THEN wt.amount_gel ELSE 0 END) AS withdrawal_amount_gel,
        SUM(CASE WHEN wt.transaction_status = 'Completed'
                 THEN wt.processing_fee_gel ELSE 0 END) AS payment_fee_gel,
        SUM(CASE WHEN wt.transaction_type = 'Chargeback'
                  AND wt.transaction_status = 'Completed' THEN wt.amount_gel ELSE 0 END) AS chargeback_cost_gel
    INTO #WalletDaily
    FROM dbo.fact_wallet_transaction wt
    INNER JOIN dbo.dim_date d ON wt.date_key = d.date_key
    WHERE d.full_date BETWEEN @FromDate AND @ToDate
    GROUP BY wt.player_id, wt.date_key;

    CREATE UNIQUE CLUSTERED INDEX IX_WalletDaily
        ON #WalletDaily(player_id,date_key);

    IF OBJECT_ID('tempdb..#GamingDaily') IS NOT NULL DROP TABLE #GamingDaily;

    SELECT
        ga.player_id,
        ga.date_key,
        SUM(CAST(ga.bet_count AS BIGINT)) AS bet_count,
        SUM(ga.wager_amount_gel) AS wager_amount_gel,
        SUM(ga.payout_amount_gel) AS payout_amount_gel,
        SUM(ga.wager_amount_gel - ga.payout_amount_gel) AS ggr_gel,
        SUM(
            CASE
                WHEN ga.wager_amount_gel - ga.payout_amount_gel > 0
                THEN (ga.wager_amount_gel - ga.payout_amount_gel) * r.provider_cost_rate
                ELSE 0
            END
        ) AS provider_cost_gel
    INTO #GamingDaily
    FROM dbo.fact_game_activity ga
    INNER JOIN dbo.dim_game g
        ON ga.game_id = g.game_id
    INNER JOIN dbo.dim_vertical_cost_rate r
        ON g.product_vertical = r.product_vertical
       AND r.is_active = 1
    INNER JOIN dbo.dim_date d
        ON ga.date_key = d.date_key
    WHERE d.full_date BETWEEN @FromDate AND @ToDate
    GROUP BY ga.player_id, ga.date_key;

    CREATE UNIQUE CLUSTERED INDEX IX_GamingDaily
        ON #GamingDaily(player_id,date_key);

    IF OBJECT_ID('tempdb..#BonusDaily') IS NOT NULL DROP TABLE #BonusDaily;

    SELECT
        b.player_id,
        b.date_key,
        SUM(b.bonus_cost_gel) AS bonus_cost_gel
    INTO #BonusDaily
    FROM dbo.fact_bonus_cost b
    INNER JOIN dbo.dim_date d
        ON b.date_key = d.date_key
    WHERE d.full_date BETWEEN @FromDate AND @ToDate
    GROUP BY b.player_id, b.date_key;

    CREATE UNIQUE CLUSTERED INDEX IX_BonusDaily
        ON #BonusDaily(player_id,date_key);

    IF OBJECT_ID('tempdb..#Keys') IS NOT NULL DROP TABLE #Keys;

    SELECT player_id, date_key
    INTO #Keys
    FROM
    (
        SELECT player_id,date_key FROM #WalletDaily
        UNION
        SELECT player_id,date_key FROM #GamingDaily
        UNION
        SELECT player_id,date_key FROM #BonusDaily
    ) x;

    CREATE UNIQUE CLUSTERED INDEX IX_Keys
        ON #Keys(player_id,date_key);

    BEGIN TRY
        BEGIN TRAN;

        DELETE f
        FROM dbo.fact_player_daily f
        INNER JOIN dbo.dim_date d
            ON f.date_key = d.date_key
        WHERE d.full_date BETWEEN @FromDate AND @ToDate;

        INSERT INTO dbo.fact_player_daily
        (
            player_id, date_key,
            deposit_count, deposit_amount_gel,
            withdrawal_count, withdrawal_amount_gel,
            bet_count, wager_amount_gel, payout_amount_gel, ggr_gel,
            bonus_cost_gel, payment_fee_gel, provider_cost_gel,
            gaming_tax_gel, chargeback_cost_gel, ngr_gel, active_flag
        )
        SELECT
            k.player_id,
            k.date_key,
            ISNULL(w.deposit_count,0),
            ISNULL(w.deposit_amount_gel,0),
            ISNULL(w.withdrawal_count,0),
            ISNULL(w.withdrawal_amount_gel,0),
            ISNULL(g.bet_count,0),
            ISNULL(g.wager_amount_gel,0),
            ISNULL(g.payout_amount_gel,0),
            ISNULL(g.ggr_gel,0),
            ISNULL(b.bonus_cost_gel,0),
            ISNULL(w.payment_fee_gel,0),
            ISNULL(g.provider_cost_gel,0),
            CASE WHEN ISNULL(g.ggr_gel,0) > 0
                 THEN ISNULL(g.ggr_gel,0) * 0.15 ELSE 0 END,
            ISNULL(w.chargeback_cost_gel,0),
            ISNULL(g.ggr_gel,0)
              - ISNULL(b.bonus_cost_gel,0)
              - ISNULL(w.payment_fee_gel,0)
              - ISNULL(g.provider_cost_gel,0)
              - CASE WHEN ISNULL(g.ggr_gel,0) > 0
                     THEN ISNULL(g.ggr_gel,0) * 0.15 ELSE 0 END
              - ISNULL(w.chargeback_cost_gel,0),
            CAST(1 AS BIT)
        FROM #Keys k
        LEFT JOIN #WalletDaily w
            ON k.player_id = w.player_id AND k.date_key = w.date_key
        LEFT JOIN #GamingDaily g
            ON k.player_id = g.player_id AND k.date_key = g.date_key
        LEFT JOIN #BonusDaily b
            ON k.player_id = b.player_id AND k.date_key = b.date_key;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

/* Example refresh used for the final Player 360 date window:
EXEC dbo.sp_refresh_player_daily
    @FromDate = '2026-07-21',
    @ToDate   = '2026-08-19';
*/
