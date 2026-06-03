# Zipplo — Rental Operations Database & Data Warehouse

A data engineering project covering the full pipeline from operational database design through SQL ETL to Power BI reporting, built for **Zipplo** — a light transport equipment rental company operating across multiple countries and cities.

---

## Table of Contents

- [Zipplo — Rental Operations Database \& Data Warehouse](#zipplo--rental-operations-database--data-warehouse)
  - [Table of Contents](#table-of-contents)
  - [1. Project Overview](#1-project-overview)
    - [Project Context](#project-context)
    - [Business Scenario](#business-scenario)
  - [2. Repository Structure](#2-repository-structure)
  - [3. Operational Database (ZipploDB)](#3-operational-database-zipplodb)
    - [Key modeling decisions](#key-modeling-decisions)
  - [4. Data Warehouse (ZipploDW)](#4-data-warehouse-zipplodw)
    - [Fact table grain](#fact-table-grain)
    - [Star Schema](#star-schema)
    - [Dimension Tables](#dimension-tables)
    - [Fact Table](#fact-table)
  - [5. ETL Process](#5-etl-process)
    - [Surrogate key resolution in the fact load](#surrogate-key-resolution-in-the-fact-load)
  - [6. Source Data Summary](#6-source-data-summary)
  - [7. Power BI Reports \& Business Questions](#7-power-bi-reports--business-questions)
    - [Revenue \& Volume](#revenue--volume)
    - [Location](#location)
    - [Customer](#customer)
    - [Time](#time)
  - [8. Prerequisites \& How to Run](#8-prerequisites--how-to-run)
    - [Prerequisites](#prerequisites)
    - [How to Run](#how-to-run)

---

## 1. Project Overview

### Project Context

This project was built as part of a **Data Engineering Program** mini-project. It covers the complete data engineering workflow:

- Designing a normalized **operational (OLTP) database** to support the rental business process
- Designing a **dimensional data warehouse** (star schema) optimized for analytical reporting
- Implementing **SQL-based ETL scripts** to load the data warehouse from the operational database
- Building **Power BI reports** on top of the data warehouse to answer real business questions

### Business Scenario

Zipplo rents light transport equipment — electric bicycles, scooters, electric kickboards, and electric mopeds — across multiple countries and cities. Rentals happen through two channels:

- **Rental stores** — employees process rentals and payments via a browser-based application.
- **Unoccupied stations** — customers retrieve and return devices and pay through a mobile app.

The data warehouse is designed to give analysts and business users a clear view of rental performance across time, equipment, location, and customer segments.

---

## 2. Repository Structure

```
zipplo-mini-project/
│
├── docs/
│   ├── dw_model.jpeg                # Data warehouse model
│   └── operational_model.png        # Operational data model
│
├── reports/
│   └── Zipplo_Reports.pbix          # Power BI reports
│
├── sql/
│   ├── operational/
│   │   ├── 01_create_tables.sql            # DDL for all OLTP tables
│   │   ├── 02_create_staging_tables.sql    # CREATE and INSERT staging tables
│   │   ├── 03_load_data_to_tables.sql      # INSERT scripts for test data
│   │   │
│   │   ├── procedures/
│   │   │   └── 01_load_tables.sql          # Run all operational steps at once
│   │   │
│   │   └── sample_data/
│   │       ├── Customer.csv                # 14,250 customer records
│   │       ├── Employee.csv                # 12 employee records
│   │       ├── Equipment.csv               # 14 equipment types
│   │       ├── Equipment_Unit.csv          # 1,680 individual rentable units
│   │       ├── Rental_Place.csv            # 48 rental locations (stores & stations)
│   │       └── Rental_Transaction.csv      # 237,054 rental transactions
│   │
│   └── datawarehouse/
│       ├── etl/
│       │   ├── 01_create_dw_tables.sql      # Creates ZipploDW database and all DW tables
│       │   ├── 02_load_dim_customer.sql     # ETL: loads dim_customer
│       │   ├── 03_load_dim_equipment.sql    # ETL: loads dim_equipment
│       │   ├── 04_load_dim_location.sql     # ETL: loads dim_location
│       │   ├── 05_load_dim_date.sql         # ETL: populates dim_date (2020–2040)
│       │   └── 06_load_fact_rental.sql      # ETL: loads fact_rental
│       │
│       ├── procedures/
│       │   ├── 01_execute_full_pipeline_procedure.sql
│       │   ├── 02_create_dw_tables_procedure.sql
│       │   └── 03_load_dw_tables_procedure.sql
│       │
│       └── validation/
│           └── 01_validate_dw_tables.sql    # Validate data inserted into warehouse
│
└── README.md
```

---
## 3. Operational Database (ZipploDB)

The source operational database (`ZipploDB`) is normalized and covers the following entities:

| Table | Description |
|---|---|
| `Customer` | Individual and corporate customers |
| `Employee` | Store employees |
| `RentalPlace` | Rental stores and unoccupied stations with address and city |
| `Equipment` | Equipment types with category, subcategory, model, and price per minute |
| `EquipmentUnit` | Individual physical devices with serial number, condition, and maintenance dates |
| `RentalTransaction` | Each rental event: customer, device, pickup/return location, start/end time, amount, and distance |

### Key modeling decisions

- **Equipment vs EquipmentUnit** — `Equipment` holds the type/model information shared across the fleet; `EquipmentUnit` represents each individual physical device. This cleanly separates catalog data from fleet management data.
- **RentalPlace** covers both staffed stores and unstaffed stations using a `type` column, avoiding two separate tables for the same location concept.
- Pricing is stored on `Equipment` as `price_per_minute` and applied against actual duration, keeping the billed amount in `RentalTransaction` fully auditable.

---
## 4. Data Warehouse (ZipploDW)

The data warehouse follows a **star schema** with one central fact table and four dimension tables, optimized for analytical queries and Power BI reporting.

### Fact table grain

> **One row per rental transaction.**

Each row in `fact_rental` represents a single completed rental and stores foreign keys to all relevant dimensions plus the additive measures needed for analysis.

### Star Schema

```
                    ┌──────────────┐
                    │  dim_date    │ (role-playing: start date & end date)
                    └──────┬───────┘
                           │
┌──────────────┐    ┌──────┴────────┐    ┌──────────────────┐
│ dim_customer │────│  fact_rental  │────│  dim_equipment   │
└──────────────┘    └──────┬────────┘    └──────────────────┘
                           │
                    ┌──────┴───────┐
                    │ dim_location │ (role-playing: pickup & return location)
                    └──────────────┘
```

### Dimension Tables

| Table | Surrogate Key | Business / Alt Key | Key Columns |
|---|---|---|---|
| `dim_date` | `date_id` (YYYYMMDD INT) | — | date, day, month, quarter, year |
| `dim_customer` | `customer_id` (IDENTITY) | `customer_alt_key` | customer_name, type, company |
| `dim_equipment` | `equipment_unit_id` (IDENTITY) | `equipment_unit_alt_key`, `equipment_alt_key` | category, subcategory, model, serial_number, price_per_minute, condition |
| `dim_location` | `location_id` (IDENTITY) | `place_alt_key` | location_type, location_name, address, city, country |

### Fact Table

| Column | Type | Description |
|---|---|---|
| `transaction_id` | INT PK | Natural key from the operational system |
| `amount` | DECIMAL(10,2) | Revenue charged to the customer |
| `start_date_id` | INT FK → dim_date | Rental start date |
| `end_date_id` | INT FK → dim_date | Rental end date |
| `customer_id` | INT FK → dim_customer | Surrogate key |
| `equipment_unit_id` | INT FK → dim_equipment | Surrogate key |
| `pick_up_location` | INT FK → dim_location | Surrogate key (role: pickup) |
| `return_location` | INT FK → dim_location | Surrogate key (role: return) |
| `duration` | INT | Rental duration in minutes |
| `count` | INT | Always 1 — used for rental count aggregation |
| `km` | DECIMAL(10,3) | Distance travelled |
| `start_time` | TIME | Time of rental start |
| `end_time` | TIME | Time of rental end |

---
## 5. ETL Process

Scripts must be run in order. Each dimension load uses a `NOT EXISTS` guard to prevent duplicate inserts, making reruns safe.

```
01_create_dw_tables.sql   →  Create ZipploDW schema and pre-populate dim_date
02_load_dim_customer.sql  →  Load customers from ZipploDB.Customer
03_load_dim_equipment.sql →  Load equipment (joining EquipmentUnit + Equipment)
04_load_dim_location.sql  →  Load locations from ZipploDB.RentalPlace
05_load_dim_date.sql      →  (Re)populate dim_date if needed separately
06_load_fact_rental.sql   →  Load facts, resolving all surrogate keys via alt-key joins
```

### Surrogate key resolution in the fact load

The fact ETL joins on business/alternate keys to resolve each dimension's surrogate key before inserting into the fact table:

```sql
LEFT JOIN dim_customer dc      ON rt.customer_id         = dc.customer_alt_key
LEFT JOIN dim_equipment de     ON rt.equipment_unit_id   = de.equipment_unit_alt_key
LEFT JOIN dim_location dl_pick ON rt.pickup_location_id  = dl_pick.place_alt_key
LEFT JOIN dim_location dl_ret  ON rt.return_location_id  = dl_ret.place_alt_key
```

Date keys are derived by converting the source datetime to YYYYMMDD integer format to match `dim_date.date_id`:

```sql
CONVERT(INT, CONVERT(VARCHAR(8), rt.start_time, 112)) AS start_date_id
```

---

## 6. Source Data Summary
| File | Rows | Description |
|---|---|---|
| Customer.csv | 14,250 | Individual and corporate customers |
| Employee.csv | 12 | Store staff |
| Equipment.csv | 14 | Equipment types / models |
| Equipment_Unit.csv | 1,680 | Individual physical rentable devices |
| Rental_Place.csv | 48 | Stores and stations across multiple cities |
| Rental_Transaction.csv | 237,054 | Rental transactions |

---
## 7. Power BI Reports & Business Questions

Reports are built directly from `ZipploDW`. The report pages are designed to answer the following business questions.

### Revenue & Volume

- What is the total rental revenue by country and city?
- Which month or quarter generates the most rental revenue?
- How many rentals are made per day / week / month?
- What is the average rental amount per transaction?

Equipment
1. Which equipment category generates the most total revenue?
Electric Bicycle vs. Electric Scooter vs. Electric Kickboard vs. Electric Moped — comparing total revenue across categories.
2. Which subcategory has the highest average revenue per rental?
Comparing all subcategories across categories — revenue per individual rental.
3. What is the average rental duration by category and subcategory?
How long are different categories and subcategories rented on average — reveals usage patterns.
4. What are the top 5 most revenue-generating equipment models?
Model-level revenue ranking — the only model-level question.

### Location

- How do stores and stations compare in terms of rental revenue and rental volume?
- Which countries and cities generate the highest rental volume?
- Which rental locations generate the highest revenue and rental volume?
- Which locations experience the largest imbalance between pickups and returns?

### Customer

1. What is the revenue split between individual and corporate customers?
2. What is the average rental amount for individual customers compared to corporate customers?
3. What is the average rental duration for individual customers compared to corporate customers?
4. Which equipment categories are rented most frequently by individual customers compared to corporate customers?
5. How has revenue from individual and corporate customers developed over time?

### Time

- Are there peak hours, days, or seasons for rentals?
- How does rental volume compare across weekdays vs. weekends?

---
## 8. Prerequisites & How to Run

### Prerequisites

- Microsoft SQL Server (2016 or later)
- Two databases on the same server instance: `ZipploDB` (operational source) and `ZipploDW` (data warehouse)
- Source data loaded into `ZipploDB` from the CSV files before running ETL
- Power BI Desktop for reports

### How to Run

1. Create and populate `ZipploDB` with data from the CSV files in the `data/` folder.
2. Run `01_create_dw_tables.sql` to create the `ZipploDW` schema and pre-populate `dim_date`.
3. Run scripts `02` through `04` to load all dimension tables.
4. Run `05_load_dim_date.sql` only if you need to refresh `dim_date` independently.
5. Run `06_load_fact_rental.sql` to load the fact table.
6. Open Power BI Desktop and connect to `ZipploDW` on `localhost`.
