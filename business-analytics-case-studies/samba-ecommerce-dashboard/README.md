# Samba Ecommerce Dashboard

Three interactive dashboards for a Brazilian e-commerce company, built in Tableau and Looker Studio in two styles: an executive dashboard and a tactical dashboard.

**Tools:** Looker Studio, Tableau

## Business context
Samba Commerce is a fast-growing Brazilian e-commerce company with more than 15,000 products in over 50 categories. In 2022 it wanted to use data more to support growth, and the CEO requested a company-wide dashboard.

## Process
1. **Requirements:** users are the CEO and other executives, who need to follow the business performance of Samba Commerce.
2. **Looker Studio (executive dashboard)**
   - Existing fields: scorecards for customers, sellers, and orders; orders per customer city and state.
   - Filtered: top 10 product categories by delivered orders.
   - Calculated fields: average orders per customer (overall and per city); orders per payment value group (<0, 0-50, 51-100, 101-200, 201-500, 501-1000, >1000).
   - Filters for customer city, customer state, and order purchase time, plus cross-filtering between charts.
3. **Tableau (executive and tactical dashboards)**
   - Existing fields: customers, sellers, total orders; monthly orders vs. total payment value (dual axis).
   - Filtered: top 10 sellers by total orders; hierarchy of customer state and city with average customers.
   - Calculated fields: average order value, average unique items per customer, orders per quantity bin.
   - Filters for customer city, customer state, order purchase time, and product category, plus cross-filtering.

## Contents
- [report.pdf](report.pdf): dashboard walkthrough and details

## Online dashboards
- [Looker Studio dashboard](https://lookerstudio.google.com/u/0/reporting/f8d5c8f7-9e67-4dba-a197-19f814b80fe9/page/tz8JD/edit)
- [Tableau dashboard (advanced)](https://public.tableau.com/app/profile/akhmad.fauzi.nurulhamzah/viz/W10W11_JAN23_Akhmaf_Fauzi_Advanced_Samba_Commerce/Dashboard2)
- [Tableau dashboard (intermediate)](https://public.tableau.com/app/profile/akhmad.fauzi.nurulhamzah/viz/W10W11AkhmadFauziNurulhamzahIntermediate/Dashboard)
