/*
=========================================================================================
Project: Global Tech Layoffs - Data Cleaning & Exploratory Data Analysis (EDA)
Description: This script transforms a raw, messy dataset of global layoffs into a clean, 
             analyzable format, and then performs in-depth exploratory data analysis. 
             It extracts business insights regarding job losses, company shutdowns, 
             funding impacts, and geographic trends over time.

Techniques & SQL Skills Demonstrated:
- Data Cleaning: Handling NULLs, Self-Joins, String formatting (TRIM, trailing characters)
- Duplicate Removal: Common Table Expressions (CTEs) and ROW_NUMBER() window functions
- Standard Aggregations: SUM, AVG, MIN, MAX, COUNT, and filtering with HAVING clauses
- Advanced Window Functions: DENSE_RANK(), LAG(), and Rolling Totals (OVER / PARTITION BY)
- Conditional Logic: Dynamic CASE expressions for data categorization

Script Structure:
Phase 1: Database Setup & Data Cleaning (Removing duplicates, standardizing dates/strings)
Phase 2: Basic Exploratory Data Analysis (Macro trends by company, industry, and country)
Phase 3: Advanced Business Insights (MoM growth, repeat offenders, top 3 rankings)
=========================================================================================
*/
