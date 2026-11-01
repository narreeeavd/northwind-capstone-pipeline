# Northwind Capstone Pipeline

An end-to-end analytics pipeline built on the classic **Northwind Traders** dataset. Raw, normalized OLTP CSV files are ingested into a staging schema, modeled into a star-schema data warehouse with idempotent SQL upserts, analysed statistically in Python, and presented in a Power BI executive dashboard.

Final capstone of the **ACA Data Analyst Profession** program.

---

## Table of Contents

- [Northwind Capstone Pipeline](#northwind-capstone-pipeline)
  - [Table of Contents](#table-of-contents)
  - [Project Overview](#project-overview)
  - [Architecture \& Data Flow](#architecture--data-flow)
  - [Repository Structure](#repository-structure)
  - [Setup \& Installation](#setup--installation)
  - [Running the Pipeline](#running-the-pipeline)
  - [Database Design](#database-design)
    - [Staging schema (`stg`)](#staging-schema-stg)
    - [Warehouse schema (`dw`) – star schema](#warehouse-schema-dw--star-schema)
  - [Idempotency](#idempotency)
  - [Analytical SQL Queries](#analytical-sql-queries)
  - [Statistical Analysis \& Insights](#statistical-analysis--insights)
    - [Headline figures](#headline-figures)
    - [Tests](#tests)
  - [Business Recommendations](#business-recommendations)
  - [Power BI Dashboard](#power-bi-dashboard)
  - [Assumptions \& Limitations](#assumptions--limitations)
  - [Author](#author)

---

## Project Overview

| Item | Detail |
|---|---|
| Dataset | Northwind Traders (normalized OLTP, CSV format) |
| Period covered | 1996-07-04 to 1998-05-06 |
| Volume | 830 orders, 2,155 order lines, 91 customers, 77 products, 29 suppliers |
| Net revenue (after discounts) | about **$1.27M** |
| Database | MySQL 8.x |
| Flow | Raw CSV -> `stg` (staging) -> `dw` (star schema) -> statistics + Power BI |

Steps of the project:

1. **Extraction & staging** – load the raw CSV files 1:1 into the `stg` schema.
2. **Warehouse modeling** – build a star schema in `dw` and load it with idempotent upserts.
3. **Statistical thinking** – query `dw` from Python, formulate hypotheses and test them.
4. **Power BI dashboard** – executive report connected to the warehouse.

---

## Architecture & Data Flow

```
  data/raw/*.csv                      Northwind OLTP export
        |
        |  pandas + SQLAlchemy        src/stage_raw_data.py
        v
  +--------------------+
  |  stg schema        |  raw 1:1 tables (all columns as text, no transformation)
  +--------------------+
        |
        |  Python -> SQL              src/transform_warehouse.py
        |  INSERT ... ON DUPLICATE KEY UPDATE      sql/04_*.sql, sql/05_*.sql
        v
  +--------------------+
  |  dw schema         |  star schema: dim_customers, dim_products, dim_employees,
  +--------------------+               dim_suppliers, dim_date, fact_orders
        |                     |
        v                     v
  notebooks/statistical_    reports/northwind_executive_dashboard.pbix
  analysis.ipynb            (Power BI)
```

`stg` and `dw` are kept physically separate: `stg` holds untouched raw data, `dw` only modeled, analytics-ready tables. (In MySQL a *schema* is a synonym for a *database*, so these are two databases.)

---

## Repository Structure

```
northwind-capstone-pipeline/
├── .gitignore
├── .env.example                         # template for local DB credentials
├── README.md
├── requirements.txt
├── run_pipeline.py                      # master entry point
├── data/raw/                            # raw Northwind CSV files
├── sql/
│   ├── 01_create_db_and_schemas.sql     # database + stg and dw schemas
│   ├── 02_create_staging.sql            # 1:1 staging tables
│   ├── 03_create_warehouse.sql          # star schema + date dimension generator
│   ├── 04_upsert_dimensions.sql         # stg -> dw dimensions (upsert)
│   ├── 05_upsert_fact_sales.sql         # stg -> dw fact table (upsert)
│   └── 06_analytical_queries.sql        # business queries on dw
├── src/
│   ├── __init__.py
│   ├── config.py                        # settings read from environment variables
│   ├── db_connector.py                  # SQLAlchemy engine factory
│   ├── stage_raw_data.py                # CSV -> stg loader
│   └── transform_warehouse.py           # runs the SQL scripts
├── notebooks/statistical_analysis.ipynb # EDA + hypothesis testing on dw
└── reports/northwind_executive_dashboard.pbix
```

---

## Setup & Installation

**Prerequisites:** Python 3.10+, a running MySQL 8.x server, Power BI Desktop (only to open the `.pbix`).

```bash
git clone https://github.com/narreeeavd/northwind-capstone-pipeline.git
cd northwind-capstone-pipeline

python -m venv venv
source venv/bin/activate            # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**Database credentials** are read from environment variables (never commit them). Copy the template and edit it:

```bash
cp .env.example .env                # then set DB_USER and DB_PASSWORD
```

| Variable | Default |
|---|---|
| `DB_USER` | `root` |
| `DB_PASSWORD` | *(empty)* |
| `DB_HOST` | `localhost` |
| `DB_PORT` | `3306` |
| `DB_NAME` | `northwind_warehouse` |

**Raw data:** the 11 core CSV files are in `data/raw/`. The two optional tables of the 13-table schema (`customer_customer_demo.csv`, `customer_demographics.csv`) are loaded if present and skipped otherwise.

---

## Running the Pipeline

```bash
python run_pipeline.py             # normal, idempotent run
python run_pipeline.py --reset     # drop stg and dw first, then rebuild from scratch
```

The pipeline:

1. creates the database and the `stg` / `dw` schemas (`sql/01`)
2. creates the staging tables (`sql/02`) and the warehouse tables, including the generated date dimension (`sql/03`)
3. truncates and reloads every staging table from `data/raw/*.csv`, checking row counts
4. upserts the dimensions (`sql/04`), then the fact table (`sql/05`)
5. prints the row count of every `dw` table

It stops with a non-zero exit code if any step fails. The first run takes longer because `dim_date` generates about 2.9 million rows (1990-01-01 to 9999-12-31); later runs skip that step.

> If you built the warehouse with an earlier version of these scripts, run `python run_pipeline.py --reset` once, because the table definitions changed.

Afterwards open `notebooks/statistical_analysis.ipynb` in Jupyter or `reports/northwind_executive_dashboard.pbix` in Power BI Desktop.

---

## Database Design

### Staging schema (`stg`)

One table per CSV file with the original table and column names. Every column is stored as raw text; the source's literal `NULL` strings become SQL `NULL`. Types are cast only when loading `dw`.

### Warehouse schema (`dw`) – star schema

```
   dim_customers   dim_products   dim_employees   dim_suppliers   dim_date
          \             |              |               |            /
           \            |              |               |           /
                          fact_orders  (view: fact_sales)
```

**Fact table `dw.fact_orders`** – grain: one row per order line.

| Column | Description |
|---|---|
| `order_id`, `product_sk` | Primary key (order x product) |
| `customer_sk`, `employee_sk`, `supplier_sk` | Foreign keys to the dimensions |
| `date_key` | Foreign key to `dim_date` (`YYYYMMDD`, order date) |
| `unit_price`, `quantity`, `discount` | Measures from the order line |
| `line_total` | `unit_price * quantity * (1 - discount)` |

The brief names the fact table `fact_sales`. The physical table keeps its original name `fact_orders` so the existing Power BI report keeps working, and `dw.fact_sales` is a view over it.

**Dimensions** (each has a surrogate key and a `UNIQUE` business key)

| Table | Business key | Attributes |
|---|---|---|
| `dim_customers` | `customer_id` | company, contact name/title, city, region, postal code, country |
| `dim_products` | `product_id` | name, category (id + name, flattened), supplier id, quantity per unit, unit price, units in stock, discontinued flag |
| `dim_employees` | `employee_id` | full name, title, hire date, city, country, reports-to |
| `dim_suppliers` | `supplier_id` | company, contact, city, country |
| `dim_date` | `date_key` (`YYYYMMDD`) | year, quarter, month number/name/short, `YYYY-MM` text, day of month/year, ISO week, day of week/name, weekend flag, month-end flag, fiscal year/quarter/month |

`dim_date` is generated inside the database (no source table) for every day from **1990-01-01 to 9999-12-31**.

---

## Idempotency

Running the pipeline repeatedly on the same data produces the same state in `dw`:

- Dimensions use `INSERT ... ON DUPLICATE KEY UPDATE` on a `UNIQUE` business key, so rows are updated, never duplicated.
- The fact table is keyed on `(order_id, product_sk)`, so lines are updated in place.
- The fact load uses `INNER JOIN`s to all dimensions and the table has foreign keys, so orphan or `NULL`-key rows cannot be inserted.
- Staging tables are truncated and reloaded on each run, so `stg` always mirrors the CSV files.
- `dim_date` is only populated when empty.

---

## Analytical SQL Queries

`sql/06_analytical_queries.sql` reads only from `dw`: revenue by category, monthly trend, revenue by country, revenue by discount tier, revenue by supplier, employee performance, and revenue by year and quarter.

---

## Statistical Analysis & Insights

`notebooks/statistical_analysis.ipynb` queries the `dw` schema (2,155 order lines joined to product and customer dimensions). Numbers below come from the same data.

### Headline figures

| Metric | Value |
|---|---|
| Net revenue | about $1,265,793 |
| Top categories | Beverages ($267.9K), Dairy Products ($234.5K), Confections ($167.4K) |
| Smallest categories | Produce ($100.0K), Grains/Cereals ($95.7K) |
| Top countries | USA ($245.6K), Germany ($230.3K), Austria ($128.0K), Brazil ($106.9K), France ($81.4K) |
| Discounted order lines | 838 of 2,155 (about 39%) |

### Tests

| # | Question | H0 | Test | Result | Decision |
|---|---|---|---|---|---|
| 1 | What drives line value? | – | Correlation matrix | `unit_price` r = 0.70, `quantity` r = 0.48, `discount` r = 0.01 | Price and quantity drive value; discount does not |
| 2 | Does category affect line value? | Equal mean `line_total` in all categories | One-way ANOVA, Kruskal-Wallis, Tukey HSD | F = 7.20, p = 1.5e-08; H = 85.0, p = 1.3e-15 | Reject H0 |
| 3 | Do discounts change quantity? | Equal mean quantity | Welch t-test, Mann-Whitney | 27.1 vs 21.7 units, difference CI [3.7, 7.1], p < 0.001 | Reject H0 |
| 4 | Do discounts change revenue per line? | Equal mean `line_total` | Welch t-test, Mann-Whitney | $615 vs $570, p = 0.30 (MWU p = 0.07) | Fail to reject H0 |
| 5 | Is category mix independent of country (top 5)? | Independent | Chi-square | chi2 = 30.7, dof = 28, p = 0.33 | Fail to reject H0 |

**Interpretation**

- **Price drives value.** `unit_price` is the strongest driver of line value; price and quantity are almost uncorrelated (r = 0.007).
- **Category matters.** Meat/Poultry has the highest average line value (about $942) and differs significantly from most categories; Seafood is the lowest (about $398). Beverages has a mean ($663) far above its median ($252), so a few very large lines inflate the average.
- **Discounts raise volume, not revenue.** Discounted lines sell about 5 more units, but revenue per line is not significantly higher, so the extra volume is largely paid for by the lower price.
- **Same product mix across top markets.** There is no evidence that the top five countries buy different categories.

---

## Business Recommendations

1. **Protect Beverages and Dairy Products** – together about 40% of revenue; keep stock and supplier reliability high.
2. **Defend the top markets, grow the next tier** – the USA and Germany give about 38% of revenue; Austria, Brazil, and France are the best targets for campaigns.
3. **Do not extend discounts without a margin check** – they increase quantity but not revenue per line (p = 0.30). Test discount depth against profitability first.
4. **Lead with pricing and assortment** – `unit_price` explains far more line value than quantity does, and Meat/Poultry lines are the most valuable.
5. **One assortment for the top markets** – category mix does not differ significantly by country, so growth should come from customer volume rather than regional assortments.

---

## Power BI Dashboard

`reports/northwind_executive_dashboard.pbix` connects to the `dw` schema. It uses one-to-many, single-direction relationships from each dimension to the fact table, DAX measures, and multi-page executive views (KPIs, trends, product/category and customer/regional analysis).

---

## Assumptions & Limitations

- **Fiscal year** in `dim_date` starts on 1 July (an assumption; edit the formulas in `sql/03_create_warehouse.sql` to change it).
- **Freight, shipper, and shipping dates** are not modeled in the fact table (freight is order-level and would be double-counted at order-line grain).
- Only 11 of the 13 source CSV files are included; the two customer-demographics tables are optional and empty in the standard Northwind data.
- The raw CSV files are committed (small, about 3,300 rows) so the repository is reproducible.
- The Power BI file is binary and was not changed. If its model points to a table or column that was renamed, refresh the connection in Power BI.

---

## Author

**Nare Avdalyan**
Data Analytics student, Yerevan State University (Actuarial and Financial Mathematics)
Capstone project for the Armenian Code Academy (ACA) Data Analyst Profession program
[LinkedIn](https://linkedin.com/in/nare-avdalyan) · [GitHub](https://github.com/narreeeavd)
