USE iGamingBI;
GO

/* ============================================================
   CORE DIMENSION TABLES
   ============================================================ */

CREATE TABLE dbo.dim_currency
(
    currency_id       SMALLINT IDENTITY(1,1) PRIMARY KEY,
    currency_code     CHAR(3) NOT NULL UNIQUE,
    currency_name     VARCHAR(50) NOT NULL,
    is_base_currency  BIT NOT NULL,
    is_active         BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_date
(
    date_key       INT PRIMARY KEY,
    full_date      DATE NOT NULL UNIQUE,
    [year]         SMALLINT NOT NULL,
    quarter_no     TINYINT NOT NULL,
    month_no       TINYINT NOT NULL,
    month_name     VARCHAR(20) NOT NULL,
    week_no        TINYINT NOT NULL,
    day_no         TINYINT NOT NULL,
    weekday_no     TINYINT NOT NULL,
    weekday_name   VARCHAR(20) NOT NULL,
    is_weekend     BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_country
(
    country_id           SMALLINT IDENTITY(1,1) PRIMARY KEY,
    country_code         CHAR(2) NOT NULL UNIQUE,
    country_name         VARCHAR(100) NOT NULL,
    region_name          VARCHAR(50) NULL,
    default_currency_id  SMALLINT NULL,
    is_active            BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_player
(
    player_id                    BIGINT IDENTITY(1,1) PRIMARY KEY,
    registration_ts              DATETIME2(0) NOT NULL,
    registration_date AS CONVERT(DATE, registration_ts) PERSISTED,
    country_id                   SMALLINT NOT NULL,
    preferred_currency_id        SMALLINT NOT NULL,
    age_band                     VARCHAR(20) NULL,
    gender_code                  CHAR(1) NULL,
    acquisition_source           VARCHAR(50) NULL,
    registration_channel         VARCHAR(50) NULL,
    affiliate_code               VARCHAR(50) NULL,
    vip_level                    VARCHAR(20) NOT NULL,
    kyc_status                   VARCHAR(20) NOT NULL,
    account_status               VARCHAR(20) NOT NULL,
    risk_segment                 VARCHAR(20) NOT NULL,
    responsible_gambling_flag    BIT NOT NULL,
    self_excluded_flag           BIT NOT NULL,
    first_deposit_date           DATE NULL,
    last_active_date             DATE NULL,
    user_id                      BIGINT NOT NULL
);
GO


CREATE TABLE dbo.dim_provider
(
    provider_id    INT IDENTITY(1,1) PRIMARY KEY,
    provider_name  VARCHAR(100) NOT NULL UNIQUE,
    provider_type  VARCHAR(30) NULL,
    is_active      BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_game
(
    game_id           INT IDENTITY(1,1) PRIMARY KEY,
    game_name         VARCHAR(150) NOT NULL,
    product_vertical  VARCHAR(30) NOT NULL,
    provider_id       INT NULL,
    is_active         BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_bonus
(
    bonus_id        INT IDENTITY(1,1) PRIMARY KEY,
    bonus_name      VARCHAR(150) NOT NULL,
    bonus_type      VARCHAR(30) NOT NULL,
    campaign_code   VARCHAR(50) NULL,
    valid_from      DATE NULL,
    valid_to        DATE NULL,
    is_active       BIT NOT NULL
);
GO
/* ============================================================
   PAYMENT & TRANSACTION DIMENSIONS
   ============================================================ */

CREATE TABLE dbo.dim_transaction_channel
(
    channel_id    SMALLINT IDENTITY(1,1) PRIMARY KEY,
    channel_name  VARCHAR(50) NOT NULL UNIQUE,
    is_cash       BIT NOT NULL,
    is_bank       BIT NOT NULL,
    is_online     BIT NOT NULL,
    is_active     BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_bank
(
    bank_id      SMALLINT IDENTITY(1,1) PRIMARY KEY,
    bank_name    VARCHAR(100) NOT NULL UNIQUE,
    country_id   SMALLINT NULL,
    is_active    BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_cash_desk
(
    cash_desk_id    SMALLINT IDENTITY(1,1) PRIMARY KEY,
    cash_desk_code  VARCHAR(20) NOT NULL UNIQUE,
    cash_desk_name  VARCHAR(100) NOT NULL,
    city_name       VARCHAR(100) NULL,
    country_id      SMALLINT NULL,
    is_active       BIT NOT NULL
);
GO


CREATE TABLE dbo.dim_payment_method
(
    payment_method_id    SMALLINT IDENTITY(1,1) PRIMARY KEY,
    payment_method_name  VARCHAR(100) NOT NULL UNIQUE,
    channel_id           SMALLINT NOT NULL,
    is_active            BIT NOT NULL
);
GO


/* ============================================================
   FX & TRANSACTION FACTS
   ============================================================ */

CREATE TABLE dbo.fact_fx_rate
(
    fx_rate_id    BIGINT IDENTITY(1,1) PRIMARY KEY,
    rate_date     DATE NOT NULL,
    currency_id   SMALLINT NOT NULL,
    rate_to_gel   DECIMAL(18,8) NOT NULL,
    source_name   VARCHAR(100) NULL,
    loaded_at     DATETIME2(0) NOT NULL,

    CONSTRAINT UQ_fact_fx_rate_date_currency
        UNIQUE (rate_date, currency_id)
);
GO


CREATE TABLE dbo.fact_wallet_transaction
(
    transaction_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    player_id                 BIGINT NOT NULL,
    transaction_ts            DATETIME2(0) NOT NULL,

    transaction_date AS
        CONVERT(DATE, transaction_ts) PERSISTED,

    date_key                  INT NOT NULL,
    transaction_type          VARCHAR(20) NOT NULL,
    transaction_status        VARCHAR(20) NOT NULL,

    channel_id                SMALLINT NOT NULL,
    payment_method_id         SMALLINT NULL,
    bank_id                   SMALLINT NULL,
    cash_desk_id              SMALLINT NULL,

    currency_id               SMALLINT NOT NULL,
    amount_original           DECIMAL(18,2) NOT NULL,
    fx_rate_to_gel            DECIMAL(18,8) NULL,
    amount_gel                DECIMAL(18,2) NULL,

    processing_fee_original   DECIMAL(18,2) NOT NULL,
    processing_fee_gel        DECIMAL(18,2) NULL,

    provider_reference_hash   VARCHAR(100) NULL,
    decline_reason            VARCHAR(100) NULL,

    fraud_flag                BIT NOT NULL,
    manual_review_flag        BIT NOT NULL,
    created_at                DATETIME2(0) NOT NULL
);
GO
/* ============================================================
   GAMING & BONUS FACTS
   ============================================================ */

CREATE TABLE dbo.fact_game_activity
(
    activity_id                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    player_id                   BIGINT NOT NULL,
    date_key                    INT NOT NULL,
    game_id                     INT NOT NULL,
    currency_id                 SMALLINT NOT NULL,
    bet_count                   INT NOT NULL,
    wager_amount_original       DECIMAL(18,2) NOT NULL,
    payout_amount_original      DECIMAL(18,2) NOT NULL,
    fx_rate_to_gel              DECIMAL(18,8) NULL,
    wager_amount_gel            DECIMAL(18,2) NULL,
    payout_amount_gel           DECIMAL(18,2) NULL,
    free_bet_stake_original     DECIMAL(18,2) NOT NULL,
    voided_bet_amount_original  DECIMAL(18,2) NOT NULL
);
GO


CREATE TABLE dbo.fact_bonus_cost
(
    bonus_event_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    player_id                 BIGINT NOT NULL,
    bonus_id                  INT NOT NULL,
    date_key                  INT NOT NULL,
    currency_id               SMALLINT NOT NULL,
    bonus_issued_original     DECIMAL(18,2) NOT NULL,
    bonus_used_original       DECIMAL(18,2) NOT NULL,
    bonus_converted_original  DECIMAL(18,2) NOT NULL,
    bonus_expired_original    DECIMAL(18,2) NOT NULL,
    fx_rate_to_gel            DECIMAL(18,8) NULL,
    bonus_cost_gel            DECIMAL(18,2) NULL
);
GO


CREATE TABLE dbo.dim_vertical_cost_rate
(
    product_vertical    VARCHAR(30) PRIMARY KEY,
    provider_cost_rate  DECIMAL(8,4) NOT NULL,
    is_active           BIT NOT NULL
);
GO


/* ============================================================
   DAILY BUSINESS KPI FACT
   Grain: one row per date and country
   ============================================================ */

CREATE TABLE dbo.fact_daily_business_kpi
(
    date_key               INT NOT NULL,
    country_id             SMALLINT NOT NULL,
    active_players         INT NOT NULL,
    deposit_count          BIGINT NOT NULL,
    deposit_amount_gel     DECIMAL(24,2) NOT NULL,
    withdrawal_count       BIGINT NOT NULL,
    withdrawal_amount_gel  DECIMAL(24,2) NOT NULL,
    wager_amount_gel       DECIMAL(24,2) NOT NULL,
    payout_amount_gel      DECIMAL(24,2) NOT NULL,
    ggr_gel                DECIMAL(24,2) NOT NULL,
    bonus_cost_gel         DECIMAL(24,2) NOT NULL,
    payment_fee_gel        DECIMAL(24,2) NOT NULL,
    provider_cost_gel      DECIMAL(24,2) NOT NULL,
    gaming_tax_gel         DECIMAL(24,2) NOT NULL,
    chargeback_cost_gel    DECIMAL(24,2) NOT NULL,
    ngr_gel                DECIMAL(24,2) NOT NULL,
    loaded_at              DATETIME2(0) NOT NULL,

    CONSTRAINT PK_fact_daily_business_kpi
        PRIMARY KEY (date_key, country_id)
);
GO


/* ============================================================
   PLAYER-LEVEL DAILY FACT
   Grain: one row per player per active date
   ============================================================ */

CREATE TABLE dbo.fact_player_daily
(
    player_id               BIGINT NOT NULL,
    date_key                INT NOT NULL,
    deposit_count           BIGINT NOT NULL,
    deposit_amount_gel      DECIMAL(24,2) NOT NULL,
    withdrawal_count        BIGINT NOT NULL,
    withdrawal_amount_gel   DECIMAL(24,2) NOT NULL,
    bet_count               BIGINT NOT NULL,
    wager_amount_gel        DECIMAL(24,2) NOT NULL,
    payout_amount_gel       DECIMAL(24,2) NOT NULL,
    ggr_gel                 DECIMAL(24,2) NOT NULL,
    bonus_cost_gel          DECIMAL(24,2) NOT NULL,
    payment_fee_gel         DECIMAL(24,2) NOT NULL,
    provider_cost_gel       DECIMAL(24,2) NOT NULL,
    gaming_tax_gel          DECIMAL(24,2) NOT NULL,
    chargeback_cost_gel     DECIMAL(24,2) NOT NULL,
    ngr_gel                 DECIMAL(24,2) NOT NULL,
    active_flag             BIT NOT NULL,

    CONSTRAINT PK_fact_player_daily
        PRIMARY KEY (player_id, date_key)
);
GO
/* ============================================================
   PLAYER SUMMARY FACT
   Grain: one row per player
   ============================================================ */

CREATE TABLE dbo.fact_player_summary
(
    player_id               BIGINT NOT NULL,
    deposit_count           BIGINT NOT NULL,
    deposit_amount_gel      DECIMAL(24,2) NOT NULL,
    withdrawal_count        BIGINT NOT NULL,
    withdrawal_amount_gel   DECIMAL(24,2) NOT NULL,
    payment_fee_gel         DECIMAL(24,2) NOT NULL,
    chargeback_cost_gel     DECIMAL(24,2) NOT NULL,
    bet_count               BIGINT NOT NULL,
    wager_amount_gel        DECIMAL(24,2) NOT NULL,
    payout_amount_gel       DECIMAL(24,2) NOT NULL,
    ggr_gel                 DECIMAL(24,2) NOT NULL,
    bonus_event_count       BIGINT NOT NULL,
    bonus_cost_gel          DECIMAL(24,2) NOT NULL,
    first_activity_date     DATE NULL,
    last_activity_date      DATE NULL,
    active_days             INT NOT NULL,
    net_deposit_gel         DECIMAL(24,2) NOT NULL,
    loaded_at               DATETIME2(0) NOT NULL,

    CONSTRAINT PK_fact_player_summary
        PRIMARY KEY (player_id)
);
GO


/* ============================================================
   RELATIONSHIPS
   ============================================================ */

ALTER TABLE dbo.dim_country
ADD CONSTRAINT FK_dim_country_currency
    FOREIGN KEY (default_currency_id)
    REFERENCES dbo.dim_currency(currency_id);
GO

ALTER TABLE dbo.dim_player
ADD CONSTRAINT FK_dim_player_country
    FOREIGN KEY (country_id)
    REFERENCES dbo.dim_country(country_id);
GO

ALTER TABLE dbo.dim_player
ADD CONSTRAINT FK_dim_player_currency
    FOREIGN KEY (preferred_currency_id)
    REFERENCES dbo.dim_currency(currency_id);
GO

ALTER TABLE dbo.dim_game
ADD CONSTRAINT FK_dim_game_provider
    FOREIGN KEY (provider_id)
    REFERENCES dbo.dim_provider(provider_id);
GO

ALTER TABLE dbo.dim_payment_method
ADD CONSTRAINT FK_dim_payment_method_channel
    FOREIGN KEY (channel_id)
    REFERENCES dbo.dim_transaction_channel(channel_id);
GO

ALTER TABLE dbo.dim_bank
ADD CONSTRAINT FK_dim_bank_country
    FOREIGN KEY (country_id)
    REFERENCES dbo.dim_country(country_id);
GO

ALTER TABLE dbo.dim_cash_desk
ADD CONSTRAINT FK_dim_cash_desk_country
    FOREIGN KEY (country_id)
    REFERENCES dbo.dim_country(country_id);
GO


ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_player
    FOREIGN KEY (player_id)
    REFERENCES dbo.dim_player(player_id);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_date
    FOREIGN KEY (date_key)
    REFERENCES dbo.dim_date(date_key);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_channel
    FOREIGN KEY (channel_id)
    REFERENCES dbo.dim_transaction_channel(channel_id);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_payment_method
    FOREIGN KEY (payment_method_id)
    REFERENCES dbo.dim_payment_method(payment_method_id);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_bank
    FOREIGN KEY (bank_id)
    REFERENCES dbo.dim_bank(bank_id);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_cash_desk
    FOREIGN KEY (cash_desk_id)
    REFERENCES dbo.dim_cash_desk(cash_desk_id);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT FK_fact_wallet_currency
    FOREIGN KEY (currency_id)
    REFERENCES dbo.dim_currency(currency_id);
GO


ALTER TABLE dbo.fact_game_activity
ADD CONSTRAINT FK_fact_game_player
    FOREIGN KEY (player_id)
    REFERENCES dbo.dim_player(player_id);
GO

ALTER TABLE dbo.fact_game_activity
ADD CONSTRAINT FK_fact_game_date
    FOREIGN KEY (date_key)
    REFERENCES dbo.dim_date(date_key);
GO

ALTER TABLE dbo.fact_game_activity
ADD CONSTRAINT FK_fact_game_game
    FOREIGN KEY (game_id)
    REFERENCES dbo.dim_game(game_id);
GO

ALTER TABLE dbo.fact_game_activity
ADD CONSTRAINT FK_fact_game_currency
    FOREIGN KEY (currency_id)
    REFERENCES dbo.dim_currency(currency_id);
GO


ALTER TABLE dbo.fact_bonus_cost
ADD CONSTRAINT FK_fact_bonus_player
    FOREIGN KEY (player_id)
    REFERENCES dbo.dim_player(player_id);
GO

ALTER TABLE dbo.fact_bonus_cost
ADD CONSTRAINT FK_fact_bonus_bonus
    FOREIGN KEY (bonus_id)
    REFERENCES dbo.dim_bonus(bonus_id);
GO

ALTER TABLE dbo.fact_bonus_cost
ADD CONSTRAINT FK_fact_bonus_date
    FOREIGN KEY (date_key)
    REFERENCES dbo.dim_date(date_key);
GO

ALTER TABLE dbo.fact_bonus_cost
ADD CONSTRAINT FK_fact_bonus_currency
    FOREIGN KEY (currency_id)
    REFERENCES dbo.dim_currency(currency_id);
GO


ALTER TABLE dbo.fact_daily_business_kpi
ADD CONSTRAINT FK_daily_kpi_date
    FOREIGN KEY (date_key)
    REFERENCES dbo.dim_date(date_key);
GO

ALTER TABLE dbo.fact_daily_business_kpi
ADD CONSTRAINT FK_daily_kpi_country
    FOREIGN KEY (country_id)
    REFERENCES dbo.dim_country(country_id);
GO


ALTER TABLE dbo.fact_player_daily
ADD CONSTRAINT FK_fact_player_daily_player
    FOREIGN KEY (player_id)
    REFERENCES dbo.dim_player(player_id);
GO

ALTER TABLE dbo.fact_player_daily
ADD CONSTRAINT FK_fact_player_daily_date
    FOREIGN KEY (date_key)
    REFERENCES dbo.dim_date(date_key);
GO


ALTER TABLE dbo.fact_player_summary
ADD CONSTRAINT FK_fact_player_summary_player
    FOREIGN KEY (player_id)
    REFERENCES dbo.dim_player(player_id);
GO


ALTER TABLE dbo.fact_fx_rate
ADD CONSTRAINT FK_fact_fx_rate_currency
    FOREIGN KEY (currency_id)
    REFERENCES dbo.dim_currency(currency_id);
GO
/* ============================================================
   INTEGRITY CONSTRAINTS
   ============================================================ */

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT CK_wallet_amount_nonnegative
    CHECK (amount_original >= 0);
GO

ALTER TABLE dbo.fact_wallet_transaction
ADD CONSTRAINT CK_wallet_processing_fee_nonnegative
    CHECK (processing_fee_original >= 0);
GO

ALTER TABLE dbo.fact_game_activity
ADD CONSTRAINT CK_game_wager_nonnegative
    CHECK (wager_amount_original >= 0);
GO

ALTER TABLE dbo.fact_game_activity
ADD CONSTRAINT CK_game_payout_nonnegative
    CHECK (payout_amount_original >= 0);
GO

ALTER TABLE dbo.fact_bonus_cost
ADD CONSTRAINT CK_bonus_cost_nonnegative
    CHECK (bonus_cost_gel IS NULL OR bonus_cost_gel >= 0);
GO

ALTER TABLE dbo.fact_fx_rate
ADD CONSTRAINT CK_fx_rate_positive
    CHECK (rate_to_gel > 0);
GO


/* ============================================================
   PERFORMANCE INDEXES
   ============================================================ */

CREATE INDEX IX_wallet_player_date
ON dbo.fact_wallet_transaction
(
    player_id,
    date_key
);
GO

CREATE INDEX IX_wallet_date_status_type
ON dbo.fact_wallet_transaction
(
    date_key,
    transaction_status,
    transaction_type
)
INCLUDE
(
    player_id,
    amount_gel,
    processing_fee_gel,
    fraud_flag,
    manual_review_flag
);
GO

CREATE INDEX IX_wallet_fraud_review
ON dbo.fact_wallet_transaction
(
    fraud_flag,
    manual_review_flag
)
INCLUDE
(
    player_id,
    transaction_ts,
    transaction_type,
    transaction_status,
    amount_gel
);
GO

CREATE INDEX IX_game_player_date
ON dbo.fact_game_activity
(
    player_id,
    date_key
);
GO

CREATE INDEX IX_game_date_game
ON dbo.fact_game_activity
(
    date_key,
    game_id
)
INCLUDE
(
    player_id,
    bet_count,
    wager_amount_gel,
    payout_amount_gel
);
GO

CREATE INDEX IX_bonus_player_date
ON dbo.fact_bonus_cost
(
    player_id,
    date_key
);
GO

CREATE INDEX IX_bonus_date_bonus
ON dbo.fact_bonus_cost
(
    date_key,
    bonus_id
)
INCLUDE
(
    player_id,
    bonus_cost_gel
);
GO

CREATE INDEX IX_player_country
ON dbo.dim_player
(
    country_id
);
GO

CREATE INDEX IX_player_risk_kyc
ON dbo.dim_player
(
    risk_segment,
    kyc_status
)
INCLUDE
(
    vip_level,
    account_status,
    self_excluded_flag
);
GO

CREATE INDEX IX_daily_kpi_country_date
ON dbo.fact_daily_business_kpi
(
    country_id,
    date_key
);
GO
