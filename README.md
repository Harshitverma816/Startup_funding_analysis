# Indian Startup Funding Analysis (2015–2020)

> An end-to-end data analytics project exploring where disclosed startup funding went across India by year, sector, city, funding stage, and investor.

**Author:** Harshit Verma  
**Tools:** Python · MySQL · Power BI · Excel

---

## 🎯 Project Overview

India's startup funding records contain inconsistent names, dates, locations, industry labels, investor lists, and funding amounts. This project turns a raw public startup-funding dataset into a cleaned analytical dataset, SQL analysis tables, exploratory analysis, and an interactive Power BI dashboard.

The analysis covers funding deals recorded from **January 2015 to January 2020**. It focuses on five questions:

- How did funding-deal volume and disclosed funding change over time?
- Which sectors and cities attracted the most deals and disclosed capital?
- How does deal size differ by funding stage?
- Which investors appear most frequently in the recorded deals?
- How concentrated is disclosed funding among the largest deals?

### At a glance

| Metric | Result from the cleaned dataset / EDA |
|---|---:|
| Funding deals | 3,043 |
| Unique startup names | 2,276 |
| Unique named investors in investor-level file | 3,107 |
| Deals with disclosed amounts | 2,072 (68.1%) |
| Total disclosed funding | $34.30 billion |
| Date coverage | 2 Jan 2015 – 13 Jan 2020 |
| Investor-level records | 6,280 |

**Important:** “Undisclosed” amounts are missing values, not zero-dollar investments. Funding totals therefore represent *disclosed funding in the dataset*, not necessarily the complete value of all investment activity.

## 🗂️ Repository Structure

The files supplied for this project are organized as follows. If you place them in a GitHub repository, keep the filenames consistent with the references in the notebooks.

```text
Startup_funding_analysis/
├── startup_funding_data_cleaning(2).ipynb   # Data cleaning and preparation workflow
├── startup_funding_EDA(3).ipynb              # Exploratory analysis, charts, and insights
├── startup_funding_clean.csv                 # Cleaned deal-level dataset (3,043 rows)
├── investors_long.csv                        # Investor-level table (6,280 rows)
├── Startup_funding_queries.sql                # MySQL schema and analytical SQL queries
├── Startup_Fund_Dashboard.pbix                # Power BI dashboard file
├── Startup_Funding_Presentation.pptx          # Project presentation / case study
└── README.md                                  # Project documentation
```

## 🧱 Data Model

The project uses two linked datasets at different grains.

### `startup_funding_clean.csv` — deal-level table

**Grain:** one row per recorded funding deal.  
**Primary identifier:** `deal_id`.

Key fields include:

| Field | Purpose |
|---|---|
| `deal_id` | Unique identifier for the cleaned deal |
| `funding_date`, `year`, `quarter`, `month`, `month_name`, `year_month` | Time analysis |
| `startup_name` | Standardized startup name |
| `industry_vertical`, `sector`, `sub_vertical` | Industry classification |
| `city` | Standardized city / location label |
| `investors_name`, `investor_count` | Investor list and investor count recorded for a deal |
| `investment_type`, `funding_stage` | Type or stage of funding |
| `amount_usd`, `amount_usd_mn` | Funding amount in USD and USD millions; undisclosed amounts remain null |
| `amount_disclosed` | Flag indicating whether the amount was disclosed |
| `deal_size_bucket` | Funding-size band |
| `is_international_hq`, `is_multi_city` | Location-related flags |
| `remarks` | Cleaning notes or contextual remarks where available |

### `investors_long.csv` — investor-level table

**Grain:** one row per investor–deal association. A deal with multiple investors appears on multiple rows.

| Field | Purpose |
|---|---|
| `deal_id` | Links an investor record to a deal |
| `startup_name`, `sector`, `city` | Deal context |
| `funding_stage`, `year`, `amount_usd` | Funding context |
| `investor_name` | Individual investor name extracted from the original investor list |

### Relationship

```text
startup_funding_clean.csv
  deal_id (one row per deal)
          |
          | one-to-many
          v
investors_long.csv
  deal_id + investor_name (one row per investor–deal association)
```

## 🛠️ Tech Stack

- **Python:** data cleaning, transformation, exploratory data analysis, and charting.
- **pandas / NumPy:** tabular manipulation, aggregation, and numerical calculations.
- **Matplotlib / Seaborn:** exploratory visualizations.
- **MySQL:** structured storage and analytical queries using aggregations, subqueries, CTEs, and window functions.
- **Power BI:** interactive reporting, data modelling, DAX measures, slicers, and cross-filtering.
- **PowerPoint:** presentation of the business problem, methodology, findings, limitations, and recommendations.

## 📊 Python EDA & Insights

The EDA notebook investigates funding trends, sector and city performance, deal-size distribution, funding stages, startups, investors, concentration, disclosure, and repeat funding.

### Main findings

1. **Deal activity declined sharply after 2016.** The cleaned dataset records 993 deals in 2016, compared with 111 in 2019 — an approximately **88.8% decline**. The source presentation notes that coverage becomes thinner after 2017, so this should not be interpreted as a definitive measure of the entire Indian startup market.
2. **Median disclosed deal size increased.** The annual median rose from **$1.0 million in 2016** to **$12.0 million in 2019**. This does not mean every startup raised more; the distribution is highly skewed and the number of recorded deals fell.
3. **Funding is concentrated in a small number of large deals.** The top 10% of disclosed deals accounted for approximately **78.2%** of disclosed funding. The EDA calculated a deal-size Gini coefficient of approximately **0.856**.
4. **E-commerce & Retail led disclosed funding by sector.** The notebook reports approximately **$11.60 billion**, followed by Consumer Internet at about **$6.25 billion** and Technology, SaaS & IT at about **$4.34 billion**.
5. **Bengaluru led recorded deal activity and disclosed funding.** The notebook records 853 deals associated with Bengaluru and approximately **$14.97 billion** in disclosed funding. Bengaluru, Mumbai, and New Delhi accounted for about **66.2% of deals among records with a known city**.
6. **Most startups have only one recorded deal.** The EDA reports that 78.8% of startup names have one recorded deal and 21.2% have two or more. These are counts in this dataset, not verified complete financing histories.
7. **Funding disclosure is incomplete.** The cleaned dataset contains 971 deals with undisclosed amounts. Analysis of funding totals should therefore be separated from analysis of deal counts.

### Cleaning and preparation

The data-cleaning notebook documents these operations:

- Clean text fields and normalize inconsistent spellings / encodings.
- Parse funding dates and convert funding amounts into numeric USD values.
- Standardize startup names, city names, industry sectors, and funding-stage labels.
- Preserve missing funding amounts as null and add an `amount_disclosed` flag.
- Create time features such as year, quarter, month, and year-month.
- Create deal-size buckets and investor counts.
- Split investor lists into the separate investor-level dataset.
- Check duplicates and remove the record with an invalid/missing funding date.

The original notebook starts with 3,044 rows; the exported cleaned file contains **3,043 rows** after removing one record. The cleaned CSV has 24 columns.

## 🔍 SQL Analysis

`Startup_funding_queries.sql` creates the `startup_funding_db` database and defines the `startup_funding` and `deal_investors` tables.

The query collection covers:

- **Headline KPIs:** deal count, unique startups, disclosed funding, average deal size, disclosure rate, and date range.
- **Time trends:** yearly and monthly deal/funding summaries, year-over-year change, running funding totals, and moving averages.
- **Sector and city analysis:** sector funding, deal counts, city rankings, sector leaders by city, and funding share.
- **Deal-size analysis:** SQL-derived size buckets, stage mix, median deal size, quartiles, and concentration / Pareto calculations.
- **Investor analysis:** most active investors, investor rankings by year, and investor co-investment pairs.
- **Startup analysis:** repeat funding rounds, time between rounds, change in ticket size, and comparisons with sector averages.
- **Advanced SQL techniques:** CTEs, `LAG()`, `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`, window aggregates, conditional aggregation, subqueries, and self-joins.

### Run the SQL analysis

1. Install and start MySQL Server, then open MySQL Workbench.
2. Open `Startup_funding_queries.sql`.
3. Run the database and table-creation statements.
4. Import `startup_funding_clean.csv` into `startup_funding` and `investors_long.csv` into `deal_investors`, matching the column order and data types in the SQL definitions.
5. Confirm the row counts and check that `deal_id` values in the investor table match the main table.
6. Run the analytical queries in sections.


## 📈 Power BI Dashboard

The Power BI report is provided as `Startup_Fund_Dashboard.pbix`. The project presentation describes a four-page interactive report built around a star-schema model.

### Dashboard features documented in the presentation

- KPI cards for deal count, disclosed funding, median deal size, startups, and undisclosed-amount share.
- Yearly and monthly funding trends, including a three-month moving average.
- Sector, city, and funding-stage analysis.
- Top-deal concentration analysis.
- Year selectors and Sector, City, and Stage slicers intended to synchronize across pages.
- Sidebar page-navigation buttons, a reset-filters control, cross-filtering, and visual tooltips.
- A model described as a Funding fact table with Calendar and Investors tables, supported by DAX measures.

### How to open it

1. Download or clone the repository.
2. Open `Startup_Fund_Dashboard.pbix` in Power BI Desktop.
3. If Power BI prompts for data sources, update the source paths to the local CSV files.
4. Refresh the model and validate headline KPIs against the cleaned CSV / EDA notebook.
5. Explore the report using the slicers, navigation buttons, and chart interactions.

## 💡 Key Business Recommendations

These are data-informed recommendations, not proof of causation.

### For founders
- Benchmark a proposed raise against **median deal sizes for the relevant stage and sector**, rather than using the overall mean.
- Build an investor shortlist based on cheque-size fit, sector experience, and prior participation in comparable deals.
- Plan for a funding environment in which deal counts may be lower and large rounds account for a disproportionate share of capital.
- Treat the recorded time between funding rounds as a historical reference point, not a guaranteed fundraising timetable.

### For investors
- Monitor both deal volume and disclosed capital; they tell different stories when a few large rounds dominate totals.
- Use sector-, stage-, and year-specific benchmarks when evaluating opportunities.
- Track concentration risk: the top 10% of disclosed deals account for roughly 78% of disclosed funding in this dataset.
- Interpret sector rankings carefully because industry labels were standardized from inconsistent source text.

### For policymakers and ecosystem builders
- Investigate whether early-stage founders and cities outside major hubs face gaps in access to capital.
- Encourage more consistent disclosure of funding amounts and deal metadata.
- Support city- and stage-level analysis using more complete and current data before allocating programmes or funding.

## 🚀 How to Explore This Project

Recommended order:

1. **Start with the presentation:** `Startup_Funding_Presentation.pptx` for the problem statement, methodology, findings, limitations, and recommendations.
2. **Review data preparation:** `startup_funding_data_cleaning.ipynb` to understand the cleaning rules and output tables.
3. **Inspect the cleaned data:** `startup_funding_clean.csv` and `investors_long.csv`.
4. **Reproduce the EDA:** run `startup_funding_EDA.ipynb` from top to bottom after updating file paths if needed.
5. **Run SQL analysis:** execute `Startup_funding_queries.sql` in MySQL Workbench after importing both CSVs.
6. **Explore the dashboard:** open `Startup_Fund_Dashboard.pbix` in Power BI Desktop and refresh the data sources.

### Requirements

- Python 3
- Jupyter Notebook / JupyterLab
- pandas, NumPy, Matplotlib, Seaborn, and any additional packages imported by the notebooks
- MySQL Server and MySQL Workbench
- Power BI Desktop

Install the common Python dependencies with:

```bash
pip install pandas numpy matplotlib seaborn jupyter
```

## Limitations

- **Incomplete disclosure:** 971 of 3,043 deals have no disclosed funding amount. Funding totals are lower-bound summaries of disclosed values.
- **Uneven time coverage:** 2020 includes January only, and the presentation flags thinner coverage after 2017. A decline in recorded deals may partly reflect source coverage.
- **Inconsistent source labels:** sector and stage groups are inferred by standardizing free-text labels. Changes in classification can affect trend comparisons.
- **Recorded names are not verified entities:** name normalization may not resolve every alias, spelling variant, or website mistakenly entered as a startup.
- **Association is not causation:** the analysis describes patterns in recorded funding deals; it does not establish that city, sector, stage, or investor activity caused funding outcomes.
- **Not a live feed:** the project is based on the supplied dataset and is not automatically refreshed.

## 👤 About Me

**Harshit Verma** Aspiring Data Analyst focused on turning raw transactional data into decisions — comfortable across the full stack from SQL data modeling to Python analysis to BI storytelling. Open to data analyst roles in reporting, dashboarding, and analysis.
I use Python, SQL, and Power BI to clean data, investigate business questions, and communicate findings through dashboards and analysis.
This project demonstrates an end-to-end workflow: preparing messy data, building a linked deal/investor data model, analysing trends with Python and SQL, and presenting business recommendations in Power BI.

- **Email :** Harsh692002@gmail.com
- **LinkedIn :** [Harshit Verma](https://www.linkedin.com/in.harshit-verma-468b94398)
- **GitHub:** [Harshitverma816](https://github.com/Harshitverma816)
- **Project repository:** [Startup Funding Analysis](https://github.com/Harshitverma816/Startup_funding_analysis)

---

