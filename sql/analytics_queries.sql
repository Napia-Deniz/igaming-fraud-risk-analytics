USE iGamingBI;
GO

/* Players whose total completed deposits exceed the average player deposit total. */
SELECT
    x.player_id,
    x.total_deposit_gel
FROM
(
    SELECT
        player_id,
        SUM(amount_gel) AS total_deposit_gel
    FROM dbo.fact_wallet_transaction
    WHERE transaction_type = 'Deposit'
      AND transaction_status = 'Completed'
    GROUP BY player_id
) x
WHERE x.total_deposit_gel >
(
    SELECT AVG(CAST(y.total_deposit_gel AS DECIMAL(24,2)))
    FROM
    (
        SELECT
            player_id,
            SUM(amount_gel) AS total_deposit_gel
        FROM dbo.fact_wallet_transaction
        WHERE transaction_type = 'Deposit'
          AND transaction_status = 'Completed'
        GROUP BY player_id
    ) y
)
ORDER BY x.total_deposit_gel DESC;
GO


/* Player profile with operational risk classification. */
SELECT TOP (100)
    p.player_id,
    UPPER(p.vip_level) AS vip_level_upper,
    CONCAT(p.age_band, ' / ', p.gender_code) AS demographic_profile,
    CASE
        WHEN p.self_excluded_flag = 1 THEN 'Restricted'
        WHEN p.risk_segment = 'High Risk' THEN 'Manual Review'
        WHEN p.kyc_status <> 'Verified' THEN 'KYC Review'
        ELSE 'Standard Monitoring'
    END AS operational_action
FROM dbo.dim_player p
ORDER BY p.player_id;
GO


/* Sequence completed wallet transactions for each player. */
SELECT TOP (500)
    wt.player_id,
    wt.transaction_id,
    wt.transaction_ts,
    wt.transaction_type,
    wt.amount_gel,
    ROW_NUMBER() OVER
    (
        PARTITION BY wt.player_id
        ORDER BY wt.transaction_ts, wt.transaction_id
    ) AS transaction_sequence
FROM dbo.fact_wallet_transaction wt
WHERE wt.transaction_status = 'Completed'
ORDER BY wt.player_id, transaction_sequence;
GO


/* Rank countries by GGR. */
WITH CountryGGR AS
(
    SELECT
        c.country_name,
        SUM(k.ggr_gel) AS ggr_gel
    FROM dbo.fact_daily_business_kpi k
    INNER JOIN dbo.dim_country c
        ON k.country_id = c.country_id
    GROUP BY c.country_name
)
SELECT
    country_name,
    ggr_gel,
    RANK() OVER (ORDER BY ggr_gel DESC) AS ggr_rank
FROM CountryGGR
ORDER BY ggr_rank, country_name;
GO


/* Rank product verticals by GGR without gaps between ranks. */
WITH ProductGGR AS
(
    SELECT
        g.product_vertical,
        SUM(a.wager_amount_gel - a.payout_amount_gel) AS ggr_gel
    FROM dbo.fact_game_activity a
    INNER JOIN dbo.dim_game g
        ON a.game_id = g.game_id
    GROUP BY g.product_vertical
)
SELECT
    product_vertical,
    ggr_gel,
    DENSE_RANK() OVER (ORDER BY ggr_gel DESC) AS product_ggr_rank
FROM ProductGGR
ORDER BY product_ggr_rank, product_vertical;
GO


/* Month-over-month and next-month comparison of GGR. */
WITH MonthlyGGR AS
(
    SELECT
        DATEFROMPARTS(d.[year], d.month_no, 1) AS month_start,
        SUM(k.ggr_gel) AS ggr_gel
    FROM dbo.fact_daily_business_kpi k
    INNER JOIN dbo.dim_date d
        ON k.date_key = d.date_key
    GROUP BY d.[year], d.month_no
)
SELECT
    month_start,
    ggr_gel,
    LAG(ggr_gel)  OVER (ORDER BY month_start) AS previous_month_ggr,
    LEAD(ggr_gel) OVER (ORDER BY month_start) AS next_month_ggr,
    ggr_gel - LAG(ggr_gel) OVER (ORDER BY month_start) AS mom_ggr_change
FROM MonthlyGGR
ORDER BY month_start;
GO
