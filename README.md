
# FinSight — Product Growth & Retention Analytics

An end-to-end product analytics project analyzing user activation, KYC conversion, product engagement, cohort retention, and retention opportunities for a financial platform.

## Project Overview

FinSight analyzes the complete user journey from signup to KYC completion, activation, product engagement, and long-term retention.

The project combines Python, PostgreSQL, SQL, and Power BI to transform raw event and user data into actionable product insights.

## Business Questions

- How effectively do users move from signup to KYC completion and activation?
- Which acquisition channels perform best?
- How does retention change across user cohorts?
- Is higher feature engagement associated with better retention?
- Which acquisition segments have the greatest retention opportunity?

## Data

The analysis uses five PostgreSQL tables:

| Table | Description |
|---|---|
| `users` | User profile, signup, KYC, acquisition and account information |
| `products` | Financial products |
| `transactions` | User transaction activity |
| `product_events` | Product and feature engagement events |
| `support_tickets` | Customer support interactions |

## Analytics Workflow

```text
Raw Data
   ↓
Python Data Generation & Cleaning
   ↓
PostgreSQL
   ↓
SQL Analysis
   ↓
Power BI
   ↓
Business Insights & Recommendations
```

## SQL Analysis

The project includes analysis of:

* Executive KPIs
* Product performance
* User activation funnel
* Acquisition channels
* Cohort retention
* Feature engagement
* Retention opportunities

## Power BI Dashboard

The dashboard includes:

* Executive KPI cards
* Activation funnel
* Activation rate by acquisition channel
* KYC completion rate by acquisition channel
* Cohort retention heatmap
* Month-1 retention by feature usage
* Retention opportunity by acquisition channel

## Key Findings

### User Activation

Out of 50,000 users:

* 38,898 completed KYC
* 33,834 activated within 30 days
* KYC completion rate: **77.80%**
* 30-day activation rate: **67.67%**

### Feature Engagement & Retention

| Feature Usage | Month-1 Retention |
| ------------- | ----------------: |
| 0 uses        |            43.57% |
| 1 use         |            51.16% |
| 2 uses        |            57.13% |
| 3+ uses       |            61.66% |

Users with 3+ feature uses show an **18.09 percentage-point higher Month-1 retention rate** than users with no feature usage.

This is an observed association and does not establish causality.

### Retention Opportunity

The benchmark-based analysis identified an estimated **1,357 potential incremental retained users** across acquisition channels.

| Acquisition Channel | Potential Incremental Retained Users |
| ------------------- | -----------------------------------: |
| Organic             |                                  325 |
| Referral            |                                  254 |
| Google Ads          |                                  249 |
| Instagram           |                                  228 |
| Partner             |                                  173 |
| YouTube             |                                  128 |

## Business Recommendations

1. **Increase early product engagement** by encouraging new users to discover and use important features.
2. **Target low-engagement users** with onboarding and lifecycle interventions.
3. **Investigate early retention drop-offs** identified through cohort analysis.
4. **Prioritize high-opportunity segments** where benchmark-based retention improvements could generate the largest gains.

## Technology Stack

* Python
* Pandas
* NumPy
* PostgreSQL
* SQL
* Power BI
* Git
* Git LFS

## Repository Structure

```text
FinSight/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── notebooks/
│
├── powerbi/
│   └── FinSight_Analytics.pbix
│
├── reports/
│   └── FinSight_Insights.md
│
├── sql/
│   ├── 01_executive_metrics.sql
│   ├── 02_product_analysis.sql
│   ├── 03_funnel_analysis.sql
│   ├── 04_opportunity_analysis.sql
│   └── 05_retention_analysis.sql
│
├── src/
│   ├── clean_events.py
│   ├── db_connection.py
│   ├── generate_data.py
│   └── load_data.py
│
├── .gitignore
├── .gitattributes
├── requirements.txt
└── README.md
```

## Note on Data

The project uses generated/synthetic data for analytics practice and portfolio demonstration.

Large raw datasets are intentionally excluded from the Git repository. The data-generation and processing scripts are included so the workflow can be reproduced.

## Author

**Varun Bhatlawande**
