USE iGamingBI;
GO

/* Check for duplicate player-date rows in the daily player fact table. */
SELECT
    player_id,
    date_key,
    COUNT(*) AS duplicate_count
FROM dbo.fact_player_daily
GROUP BY
    player_id,
    date_key
HAVING COUNT(*) > 1;
GO


/* Validate that calculated NGR matches GGR minus bonus cost. */
SELECT TOP (100)
    k.date_key,
    k.country_id,
    k.ggr_gel,
    k.bonus_cost_gel,
    k.ngr_gel,
    k.ggr_gel - k.bonus_cost_gel AS recalculated_ngr_gel,
    k.ngr_gel - (k.ggr_gel - k.bonus_cost_gel) AS ngr_difference
FROM dbo.fact_daily_business_kpi k
WHERE ABS
(
    k.ngr_gel - (k.ggr_gel - k.bonus_cost_gel)
) > 0.01
ORDER BY ABS
(
    k.ngr_gel - (k.ggr_gel - k.bonus_cost_gel)
) DESC;
GO


/* Check daily KPI date coverage. */
SELECT
    MIN(d.full_date) AS first_date,
    MAX(d.full_date) AS last_date,
    COUNT(DISTINCT k.date_key) AS covered_dates
FROM dbo.fact_daily_business_kpi k
INNER JOIN dbo.dim_date d
    ON k.date_key = d.date_key;
GO


/* Validate that Bulgaria has no activity before its allowed business start date. */
SELECT
    c.country_name,
    MIN(d.full_date) AS first_activity_date,
    COUNT(*) AS invalid_rows
FROM dbo.fact_daily_business_kpi k
INNER JOIN dbo.dim_country c
    ON k.country_id = c.country_id
INNER JOIN dbo.dim_date d
    ON k.date_key = d.date_key
WHERE c.country_name = 'Bulgaria'
  AND d.full_date < '2026-01-01'
GROUP BY c.country_name;
GO


/* Check for bonus activity before player registration date. */
SELECT TOP (100)
    b.player_id,
    p.registration_date,
    d.full_date AS bonus_date,
    b.bonus_cost_gel
FROM dbo.fact_bonus_cost b
INNER JOIN dbo.dim_player p
    ON b.player_id = p.player_id
INNER JOIN dbo.dim_date d
    ON b.date_key = d.date_key
WHERE d.full_date < p.registration_date
ORDER BY b.player_id, bonus_date;
GO


/* Check for wallet transactions dated before player registration. */
SELECT TOP (100)
    wt.player_id,
    p.registration_date,
    CAST(wt.transaction_ts AS DATE) AS transaction_date,
    wt.transaction_type,
    wt.amount_gel
FROM dbo.fact_wallet_transaction wt
INNER JOIN dbo.dim_player p
    ON wt.player_id = p.player_id
WHERE CAST(wt.transaction_ts AS DATE) < p.registration_date
ORDER BY wt.player_id, transaction_date;
GO
