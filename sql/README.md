# SQL

This folder contains the SQL layer supporting the iGaming Fraud & Risk Analytics project.

The portfolio version focuses on database architecture, ETL, analytical SQL and data-quality validation. The underlying bulk dataset is synthetic and is not included in the repository.

## SQL Components

### `database_schema.sql`
Defines the analytical database structure, including dimension and fact tables, relationships, integrity constraints, reporting views and indexes.

### `player_daily_etl.sql`
Stored procedure that aggregates wallet transactions, gaming activity and bonus activity to player-date grain for Player 360 reporting.

The ETL calculates player-level metrics including deposits, withdrawals, wagering, GGR, bonus cost and NGR.

### `analytics_queries.sql`
Analytical SQL demonstrating aggregation, subqueries, `CASE` logic and window functions including `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG` and `LEAD`.

### `data_quality_checks.sql`
Validation queries covering duplicate detection, NGR reconciliation, date and registration rules, and reporting consistency.

## Key Business Logic

**GGR**

`GGR = Wager Amount - Payout Amount`

**NGR**

`NGR = GGR - Bonus Cost - Payment Fees - Provider Cost - Gaming Tax - Chargeback Cost`

## Data Model

The SQL model supports analysis across:

- Players and account activity
- Wallet transactions and payments
- Gaming activity
- Bonus cost
- Player segmentation
- Risk indicators
- Country and product performance
- Player-level reporting
