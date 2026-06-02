# zipplo-mini-project
#### A team-based project focused on designing and implementing a full data stack for Zipplo, a fictional light transport equipment rental company: normalized operational database → data warehouse → SQL ETL → Power BI reporting.
---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Business Scenario](#business-scenario)
- [Repository Structure](#repository-structure)
- [Part 1 — Operational Database](#part-1--operational-database)
- [Part 2 — Test Data](#part-2--test-data)
- [Part 3 — Data Warehouse](#part-3--data-warehouse)
- [Part 4 — SQL ETL](#part-4--sql-etl)
- [Part 5 — Power BI Reports](#part-5--power-bi-reports)
- [Presentation](#presentation)
- [Modeling Decisions & Assumptions](#modeling-decisions--assumptions)

## Project Overview

This project covers the full lifecycle of a data solution for a fictional light transport rental company operating across multiple countries and cities. The goal is to practice:
- Normalized OLTP database design (3NF)
- Dimensional data warehouse design (star schema)
- SQL-based ETL from operational to analytical layer
- Data validation with SQL
- Business reporting in Power BI
---

## Business Scenario
### Company Overview
Zipplo operates a light transport equipment rental service across multiple countries and cities. Customers can rent **electric bicycles,
scooters, and electric kickboards** through a mobile application. Equipment is managed through a network of rental places distributed across 
cities.

### Rental Places
A rental place is either a **store** or a **station**.
| Type | Description |
|---|---|
| **Store** | A physical office with a staff member responsible for managing the location |
| **Station** | An unmanned docking point around the city — street corners, train stations, parks

### Rental Process
- All rentals are initiated and completed through the mobile application — no employee is directl
- A customer selects a device, picks it up at any rental place, and returns it to any rental plac
- The rental starts at pickup and ends at return. The customer is charged based on rental duratio

### Equipment
Equipment is organised into three levels:
| Level | Example |
|---|---|
| **Category** | E-Bike, Scooter, Kickboard |
| **Subcategory** | City, Mountain (within E-Bike) |
| **Model** | Bafang E500, Xiaomi Pro 2 |

Each physical device is tracked individually by serial number, condition, and current location. E
calculate the rental amount.

### Customers
- Customers are either **private individuals** or **corporate clients**.
- Corporate customers are identified by company name and business ID.
- All customers interact with the service through the mobile application.

### Cities and Countries
The company currently operates in **Finland, Sweden, and Germany**. Each country has at least one city with one or more stores and stations.

### Reporting and Analytics
The company tracks rental activity to answer business questions as follows:

Revenue & Volume
- What is the total rental revenue by country and city?
- Which month or quarter generates the most rental revenue?
- How many rentals are made per day / week / month?
- What is the average rental amount per transaction?

Equipment
- Which equipment category (bicycle, scooter, kickboard) generates the most revenue?
- Which individual equipment units are rented most frequently?
- What is the average rental duration by equipment category?

Location
- Which rental places (stores vs. stations) generate the most rentals?
- What is the revenue split between store rentals and station rentals?
- Which city has the highest rental volume?

Customer
- What is the revenue split between individual and corporate customers?
- Which customers have the highest total rental spend?

Time
- Are there peak hours, days, or seasons for rentals?
- How does rental volume compare across weekdays vs. weekends?

A separate data warehouse is maintained for analytics and Power BI reporting, loaded from the operational database through an ETL process.

---

## Repository Structure

```
rental-project/
│
├── docs/
│   ├── operational_model_erd.png       # ERD screenshot of the OLTP database
│   ├── datawarehouse_star_schema.png   # Star schema diagram
│   └── assumptions.md                  # Modeling decisions and assumptions
│
├── sql/
│   ├── operational/
│   │   ├── 01_create_tables.sql        # DDL for all OLTP tables
│   │   └── 02_sample_data.sql          # INSERT scripts for test data
│   │
│   ├── datawarehouse/
│   │   ├── 01_create_dimensions.sql    # DDL for dimension tables
│   │   └── 02_create_facts.sql         # DDL for fact tables
│   │
│   ├── etl/
│   │   ├── 01_load_dimensions.sql      # ETL: populate dimension tables
│   │   ├── 02_load_facts.sql           # ETL: populate fact tables
│   │   └── 03_validation_queries.sql   # Queries that verify totals
│   │
│   └── reports/
│       └── example_queries.sql         # Sample analytical queries
│
├── powerbi/
│   └── RentalReport_<initials>.pbix    # Power BI report file
│
├── backlog/
│   └── product_backlog.md              # Scrum product backlog
│
└── README.md
```
---