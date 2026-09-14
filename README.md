### Net Gaming Revenue

The analytical model uses:

```text
NGR =
GGR
- Bonus Cost
- Payment Fees
- Provider Cost
- Gaming Tax
- Chargeback Cost
```

## Fraud & Risk Focus

The model includes fields and analytical logic related to:

- Fraud-flagged transactions
- Manual review activity
- Chargeback cost
- Payment declines
- KYC status
- Player risk segments
- Self-exclusion and responsible gaming indicators
- Bonus activity
- Transaction behavior

These components allow the project to be analyzed from both commercial and fraud/risk perspectives.

## Power BI

The Power BI reporting layer covers the overall iGaming business, combining commercial, player and risk-focused analysis.

### Executive Overview

![Executive Overview](screenshots/executive-overview.png)

Business-level KPIs and trends covering deposits, withdrawals, wagering, GGR, NGR, operating costs, country performance and product mix.

### Player Analysis

![Player Analysis](screenshots/player-analysis.png)

Player segmentation using RFM, activity status, potential VIP identification and acquisition-source analysis.

### Risk & Value Analysis

![Risk & Value Analysis](screenshots/risk-value-analysis.png)

Risk and value segmentation combining player risk level, commercial value, GGR, potential VIP exposure and chargeback cost.

### Player 360

![Player 360 Risk Review](screenshots/player-360-risk-review.png)

Player-level investigation view combining profile, KYC, risk, financial activity and recommended review action.

## Tools

`SQL Server` `Power BI` `Power Query` `DAX` `Excel`

## Repository Structure

```text
igaming-fraud-risk-analytics/
│
├── screenshots/
│   ├── executive-overview.png
│   ├── player-analysis.png
│   ├── risk-value-analysis.png
│   └── player-360-risk-review.png
│
├── sql/
│   ├── README.md
│   ├── database_schema.sql
│   ├── player_daily_etl.sql
│   ├── analytics_queries.sql
│   └── data_quality_checks.sql
│
└── README.md
```

## Portfolio Purpose

This project demonstrates how SQL and Power BI can be applied to iGaming business analysis, player behavior, payment activity and fraud/risk monitoring.
