CREATE DATABASE IF NOT EXISTS startup_funding_db;

USE startup_funding_db;

DROP TABLE IF EXISTS startup_funding;
DROP TABLE IF EXISTS deal_investors;

CREATE TABLE startup_funding (
    deal_id             INT PRIMARY KEY,
    sr_no               INT,
    funding_date        DATE NOT NULL,
    year                SMALLINT,
    quarter             CHAR(2),
    month               TINYINT,
    month_name          CHAR(3),
    `year_month`        CHAR(7),
    startup_name        VARCHAR(150),
    industry_vertical   VARCHAR(200),
    sector              VARCHAR(60),
    sub_vertical        VARCHAR(300),
    city                VARCHAR(60),
    is_international_hq TINYINT,
    is_multi_city       TINYINT,
    investors_name      VARCHAR(600),
    investor_count      SMALLINT,
    investment_type     VARCHAR(80),
    funding_stage       VARCHAR(60),
    amount_usd          DECIMAL(18,2) NULL,
    amount_usd_mn       DECIMAL(14,4) NULL,
    amount_disclosed    TINYINT,
    deal_size_bucket    VARCHAR(20),
    remarks             VARCHAR(300)
);

CREATE TABLE deal_investors (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    deal_id        INT,
    startup_name   VARCHAR(150),
    sector         VARCHAR(60),
    city           VARCHAR(60),
    funding_stage  VARCHAR(60),
    year           SMALLINT,
    amount_usd     DECIMAL(18,2) NULL,
    investor_name  VARCHAR(200),
    FOREIGN KEY (deal_id) REFERENCES startup_funding(deal_id)
);

select count(*) as total_rows from startup_funding_db.startup_funding;

-- Q1.1 Headline KPIs for the whole period
SELECT
    COUNT(*)                                        AS total_deals,
    COUNT(DISTINCT startup_name)                    AS unique_startups,
    ROUND(SUM(amount_usd) / 1e9, 2)                 AS total_funding_usd_bn,
    ROUND(AVG(amount_usd) / 1e6, 2)                 AS avg_deal_usd_mn,
    ROUND(100 * AVG(amount_disclosed), 1)           AS pct_deals_disclosed,
    MIN(funding_date)                               AS first_deal,
    MAX(funding_date)                               AS last_deal
FROM startup_funding;

-- Q1.2 Deals and funding by year
SELECT
    year,
    COUNT(*)                          AS deals,
    ROUND(SUM(amount_usd) / 1e9, 2)   AS funding_usd_bn,
    ROUND(AVG(amount_usd) / 1e6, 2)   AS avg_deal_usd_mn
FROM startup_funding
GROUP BY year
ORDER BY year;

-- Q1.3 Ten largest single deals
SELECT funding_date, startup_name, sector, city, funding_stage,
       ROUND(amount_usd / 1e6, 1) AS amount_usd_mn, investors_name
FROM startup_funding
WHERE amount_usd IS NOT NULL
ORDER BY amount_usd DESC
LIMIT 10;

-- Q2.1 Sectors: deals, funding, average size (only sectors with 20+ deals)
SELECT
    sector,
    COUNT(*)                          AS deals,
    COUNT(amount_usd)                 AS disclosed_deals,
    ROUND(SUM(amount_usd) / 1e6, 1)   AS funding_usd_mn,
    ROUND(AVG(amount_usd) / 1e6, 2)   AS avg_deal_usd_mn
FROM startup_funding
WHERE sector <> 'Unknown'
GROUP BY sector
HAVING COUNT(*) >= 20
ORDER BY funding_usd_mn DESC;

-- Q2.2 Top 10 cities by number of deals, with share of all deals (scalar subquery)
SELECT
    city,
    COUNT(*) AS deals,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM startup_funding WHERE city <> 'Unknown'), 1) AS pct_of_deals,
    ROUND(SUM(amount_usd) / 1e6, 1) AS funding_usd_mn
FROM startup_funding
WHERE city <> 'Unknown'
GROUP BY city
ORDER BY deals DESC
LIMIT 10;

-- Q2.3 Deal-size buckets with CASE (re-derived in SQL, not taken from the CSV)
SELECT
    CASE
        WHEN amount_usd IS NULL     THEN '6. Undisclosed'
        WHEN amount_usd <  1000000  THEN '1. < $1M'
        WHEN amount_usd <  5000000  THEN '2. $1M-5M'
        WHEN amount_usd < 20000000  THEN '3. $5M-20M'
        WHEN amount_usd < 100000000 THEN '4. $20M-100M'
        ELSE                             '5. $100M+'
    END                                AS deal_size,
    COUNT(*)                           AS deals,
    ROUND(SUM(amount_usd) / 1e6, 1)    AS funding_usd_mn
FROM startup_funding
GROUP BY deal_size
ORDER BY deal_size;

-- Q2.4 Funding stage mix: deals and average ticket
SELECT funding_stage,
       COUNT(*)                        AS deals,
       ROUND(AVG(amount_usd) / 1e6, 2) AS avg_deal_usd_mn,
       ROUND(SUM(amount_usd) / 1e6, 1) AS funding_usd_mn
FROM startup_funding
GROUP BY funding_stage
ORDER BY deals DESC;

-- Q2.5 Startups that raised more than the average deal size (subquery in WHERE)
SELECT startup_name, sector, city, ROUND(SUM(amount_usd) / 1e6, 1) AS total_raised_usd_mn
FROM startup_funding
GROUP BY startup_name, sector, city
HAVING SUM(amount_usd) > (SELECT AVG(amount_usd) FROM startup_funding)
ORDER BY total_raised_usd_mn DESC
LIMIT 20;

-- Q2.6 Transparency: % of deals with undisclosed amount, by sector
SELECT sector,
       COUNT(*)                                   AS deals,
       SUM(amount_disclosed = 0)                  AS undisclosed_deals,
       ROUND(100 * AVG(amount_disclosed = 0), 1)  AS pct_undisclosed
FROM startup_funding
WHERE sector <> 'Unknown'
GROUP BY sector
ORDER BY pct_undisclosed DESC;

-- Q2.7 Most active investors (named investors only)
SELECT investor_name,
       COUNT(DISTINCT deal_id)         AS deals,
       COUNT(DISTINCT startup_name)    AS startups_backed,
       COUNT(DISTINCT sector)          AS sectors_covered
FROM deal_investors
WHERE investor_name NOT LIKE '%Undisclosed%'
GROUP BY investor_name
ORDER BY deals DESC
LIMIT 15;

-- Q3.1 Year-over-year growth with a CTE + LAG()
WITH yearly AS (
    SELECT year,
           COUNT(*)        AS deals,
           SUM(amount_usd) AS funding
    FROM startup_funding
    GROUP BY year
)
SELECT
    year,
    deals,
    ROUND(funding / 1e9, 2)                                                        AS funding_usd_bn,
    LAG(deals) OVER (ORDER BY year)                                                AS prev_year_deals,
    ROUND(100 * (deals - LAG(deals) OVER (ORDER BY year)) / LAG(deals) OVER (ORDER BY year), 1)
                                                                                   AS deals_yoy_pct,
    ROUND(100 * (funding - LAG(funding) OVER (ORDER BY year)) / LAG(funding) OVER (ORDER BY year), 1)
                                                                                   AS funding_yoy_pct
FROM yearly
ORDER BY year;

-- Q3.2 Running total of funding by month + 3-month moving average of deal count
WITH monthly AS (
    SELECT `year_month`,
           COUNT(*)                   AS deals,
           COALESCE(SUM(amount_usd),0) AS funding
    FROM startup_funding
    GROUP BY `year_month`
)
SELECT
    `year_month`,
    deals,
    ROUND(AVG(deals) OVER (ORDER BY `year_month` ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS deals_3m_moving_avg,
    ROUND(SUM(funding) OVER (ORDER BY `year_month`) / 1e9, 2)                                AS cumulative_funding_usd_bn
FROM monthly
ORDER BY `year_month`;

-- Q3.3 Top 3 sectors by funding in EVERY year (RANK + PARTITION BY = top-N per group)
WITH sector_year AS (
    SELECT year, sector, SUM(amount_usd) AS funding, COUNT(*) AS deals
    FROM startup_funding
    WHERE sector <> 'Unknown' AND amount_usd IS NOT NULL
    GROUP BY year, sector
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY year ORDER BY funding DESC) AS rnk
    FROM sector_year
)
SELECT year, rnk, sector, deals, ROUND(funding / 1e6, 1) AS funding_usd_mn
FROM ranked
WHERE rnk <= 3
ORDER BY year, rnk;

-- Q3.4 Each sector's share of its year's funding (window SUM over a partition)
SELECT year, sector,
       ROUND(SUM(amount_usd) / 1e6, 1)                                               AS funding_usd_mn,
       ROUND(100 * SUM(amount_usd) / SUM(SUM(amount_usd)) OVER (PARTITION BY year), 1) AS pct_of_year
FROM startup_funding
WHERE amount_usd IS NOT NULL AND sector <> 'Unknown'
GROUP BY year, sector
ORDER BY year, pct_of_year DESC;

-- Q3.5 Median deal size per year (MySQL has no MEDIAN(), so use ROW_NUMBER + COUNT)
WITH ordered AS (
    SELECT year, amount_usd,
           ROW_NUMBER() OVER (PARTITION BY year ORDER BY amount_usd) AS rn,
           COUNT(*)     OVER (PARTITION BY year)                     AS n
    FROM startup_funding
    WHERE amount_usd IS NOT NULL
)
SELECT year,
       MAX(n)                          AS disclosed_deals,
       ROUND(AVG(amount_usd) / 1e6, 2) AS median_deal_usd_mn
FROM ordered
WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
GROUP BY year
ORDER BY year;

-- Q3.6 Pareto / concentration: what share of money goes to the top 1% and 10% of deals?
WITH ranked AS (
    SELECT amount_usd,
           ROW_NUMBER() OVER (ORDER BY amount_usd DESC)                 AS rn,
           COUNT(*)     OVER ()                                          AS n,
           SUM(amount_usd) OVER (ORDER BY amount_usd DESC
                                 ROWS UNBOUNDED PRECEDING)               AS running_sum,
           SUM(amount_usd) OVER ()                                       AS total
    FROM startup_funding
    WHERE amount_usd IS NOT NULL
)
SELECT
    ROUND(100 * MAX(CASE WHEN rn = FLOOR(n * 0.01) THEN running_sum / total END), 1) AS pct_money_top_1pct_deals,
    ROUND(100 * MAX(CASE WHEN rn = FLOOR(n * 0.10) THEN running_sum / total END), 1) AS pct_money_top_10pct_deals,
    ROUND(100 * MAX(CASE WHEN rn = FLOOR(n * 0.50) THEN running_sum / total END), 1) AS pct_money_top_50pct_deals
FROM ranked;

-- Q3.7 Deal-size quartiles with NTILE(4) and the range of each quartile
WITH q AS (
    SELECT amount_usd, NTILE(4) OVER (ORDER BY amount_usd) AS quartile
    FROM startup_funding
    WHERE amount_usd IS NOT NULL
)
SELECT quartile,
       COUNT(*)                          AS deals,
       ROUND(MIN(amount_usd) / 1e6, 3)   AS min_usd_mn,
       ROUND(MAX(amount_usd) / 1e6, 2)   AS max_usd_mn,
       ROUND(100 * SUM(amount_usd) / (SELECT SUM(amount_usd) FROM startup_funding), 1) AS pct_of_total_funding
FROM q
GROUP BY quartile
ORDER BY quartile;

-- Q3.8 Funding journey of repeat startups: round number, gap between rounds, growth in ticket size
WITH rounds AS (
    SELECT startup_name, funding_date, funding_stage, amount_usd,
           ROW_NUMBER() OVER (PARTITION BY startup_name ORDER BY funding_date, deal_id) AS round_no,
           COUNT(*)     OVER (PARTITION BY startup_name)                              AS total_rounds,
           LAG(funding_date) OVER (PARTITION BY startup_name ORDER BY funding_date, deal_id) AS prev_date,
           LAG(amount_usd)   OVER (PARTITION BY startup_name ORDER BY funding_date, deal_id) AS prev_amount
    FROM startup_funding
)
SELECT startup_name, round_no, total_rounds, funding_date, funding_stage,
       ROUND(amount_usd / 1e6, 2)                      AS amount_usd_mn,
       DATEDIFF(funding_date, prev_date)               AS days_since_last_round,
       ROUND(amount_usd / NULLIF(prev_amount, 0), 1)   AS x_previous_round
FROM rounds
WHERE total_rounds >= 4
ORDER BY startup_name, round_no;


-- Q3.10 City leader in each sector and its share of that sector's deals
WITH sc AS (
    SELECT sector, city, COUNT(*) AS deals
    FROM startup_funding
    WHERE sector <> 'Unknown' AND city <> 'Unknown'
    GROUP BY sector, city
), r AS (
    SELECT sc.*,
           ROW_NUMBER() OVER (PARTITION BY sector ORDER BY deals DESC) AS rn,
           SUM(deals)   OVER (PARTITION BY sector)                     AS sector_total
    FROM sc
)
SELECT sector, city AS leading_city, deals, sector_total,
       ROUND(100 * deals / sector_total, 1) AS pct_of_sector_deals
FROM r
WHERE rn = 1
ORDER BY sector_total DESC;

-- Q3.11 Investor co-investment network: which pairs invest together most often (self-join)
SELECT a.investor_name AS investor_1,
       b.investor_name AS investor_2,
       COUNT(*)        AS deals_together
FROM deal_investors a
JOIN deal_investors b
  ON a.deal_id = b.deal_id
 AND a.investor_name < b.investor_name
WHERE a.investor_name NOT LIKE '%Undisclosed%'
  AND b.investor_name NOT LIKE '%Undisclosed%'
GROUP BY a.investor_name, b.investor_name
HAVING COUNT(*) >= 3
ORDER BY deals_together DESC
LIMIT 15;

-- Q3.12 Investor ranking per year with DENSE_RANK (top 3 most active each year)
WITH iy AS (
    SELECT year, investor_name, COUNT(DISTINCT deal_id) AS deals
    FROM deal_investors
    WHERE investor_name NOT LIKE '%Undisclosed%'
    GROUP BY year, investor_name
)
SELECT year, investor_name, deals, rnk
FROM (
    SELECT iy.*, DENSE_RANK() OVER (PARTITION BY year ORDER BY deals DESC) AS rnk
    FROM iy
) t
WHERE rnk <= 3
ORDER BY year, rnk, investor_name;


-- Q3.14 Above / below sector average: compare each startup's total raise with its sector average
WITH startup_total AS (
    SELECT startup_name, sector, SUM(amount_usd) AS raised
    FROM startup_funding
    WHERE amount_usd IS NOT NULL AND sector <> 'Unknown'
    GROUP BY startup_name, sector
)
SELECT startup_name, sector,
       ROUND(raised / 1e6, 1)                                         AS raised_usd_mn,
       ROUND(AVG(raised) OVER (PARTITION BY sector) / 1e6, 1)         AS sector_avg_usd_mn,
       ROUND(raised / AVG(raised) OVER (PARTITION BY sector), 1)      AS x_sector_avg,
       ROUND(100 * PERCENT_RANK() OVER (PARTITION BY sector ORDER BY raised), 1) AS percentile_in_sector
FROM startup_total
ORDER BY x_sector_avg DESC
LIMIT 20;

-- Q3.15 Emerging sectors: compare 2015-16 vs 2018-19 share of deals (conditional aggregation)
SELECT sector, deals_2015_16, deals_2018_19, share_2015_16, share_2018_19,
       ROUND(share_2018_19 - share_2015_16, 1) AS share_change_pts
FROM (
    SELECT sector,
           SUM(year IN (2015, 2016)) AS deals_2015_16,
           SUM(year IN (2018, 2019)) AS deals_2018_19,
           ROUND(100 * SUM(year IN (2015, 2016)) / (SELECT COUNT(*) FROM startup_funding WHERE year IN (2015, 2016)), 1) AS share_2015_16,
           ROUND(100 * SUM(year IN (2018, 2019)) / (SELECT COUNT(*) FROM startup_funding WHERE year IN (2018, 2019)), 1) AS share_2018_19
    FROM startup_funding
    WHERE sector <> 'Unknown'
    GROUP BY sector
) t
ORDER BY share_change_pts DESC;
