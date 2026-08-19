/*
===========================================================================================
DATA CLEANING and EAD SCRIPT: Exploratory Data Analysis
Description: This script transforms a raw, messy dataset of global layoffs into a clean, 
            analyzable format, and then performs in-depth exploratory data analysis.

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
==============================================================================================
*/


CREATE DATABASE WORLD_LAYOFFS;
USE WORLD_LAYOFFS; 

-- ===========================================================================================
-- UPLOAD dataset buy using "TABLE DATA IMPORT WIZARD"
-- ===========================================================================================
CREATE TABLE layoffs2 LIKE layoffs;
INSERT INTO layoffs2
SELECT *
FROM layoffs;
	SELECT *
	FROM layoffs2;

-- finding the dublicat entry
SELECT *,
row_number () over(partition by company, location, industry, total_laid_off, percentage_laid_off, `date`,country) company_rank
FROM layoffs2;

WITH dublicat_cte AS 
(SELECT *,
row_number () OVER (partition by  company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) row_no
FROM layoffs2)
SELECT *
FROM dublicat_cte
WHERE row_no > 1;

-- copy to clipboard create statment
-- creating new table with row numbers 
CREATE TABLE `layoff` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` DATE,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_no` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- changing date format 
SELECT `date`,
str_to_date (`date`, '%m/%d/%y')
FROM layoffs2;

UPDATE layoffs2
SET `date` = str_to_date (`date`, '%m/%d/%Y');

ALTER TABLE layoffs2
MODIFY COLUMN `date` DATE;

INSERT INTO layoff
	SELECT *,
	row_number () OVER (partition by  company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) row_no
	FROM layoffs2;

-- deleting dublicat rows
SELECT *
FROM layoff
WHERE row_no > 1;
DELETE 
FROM layoff
WHERE row_no > 1;

-- removing row_no
ALTER TABLE layoff
DROP COLUMN row_no;

select *
from layoff;
-- Standardizing data
select *,
trim(company)
from layoff;
UPDATE layoff
SET company = trim(company);

SELECT distinct(country)
FROM layoff
ORDER BY 1;
SELECT country, trim(trailing '.' from country)
FROM layoff;
UPDATE layoff
SET country = trim(trailing '.' from country);

SELECT industry
FROM layoff
ORDER BY 1;
SELECT industry
FROM layoff
WHERE industry LIKE'crypto%'
ORDER BY 1;
UPDATE layoff
SET industry = 'crypto'
WHERE industry LIKE'crypto%'; 

-- removing the null values
UPDATE layoff
SET total_laid_off = NULL
WHERE total_laid_off = 0 OR  '';
UPDATE layoff
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 0 OR  '';
UPDATE layoff
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 0 OR  '';

-- deletin null values from percentage_laid_off and total_laid_off
DELETE
FROM layoff
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

-- finding null value in industry
SELECT *
FROM layoff
WHERE industry = '';
UPDATE layoff
SET industry = null
WHERE industry = '';

SELECT l1.industry, l2.industry,l1.company
FROM layoff l1
JOIN layoff l2
	ON l1.company = l2.company
    AND l1.location = l2.location
WHERE l1.industry IS NULL 
	AND l2.industry IS NOT NULL;

UPDATE layoff L1
JOIN layoff L2
	ON L1.company = l2.company
     AND l1.location = l2.location
SET L1.industry = L2.industry
WHERE L1.industry IS NULL 
	AND L2.industry IS NOT NULL;
    
    -- finding any null values in industry
SELECT company, industry
FROM layoff
WHERE industry IS NULL;
-- Bally's Interactive is still have null value in industry
SELECT company
FROM layoff
WHERE company LIKE 'bally%'; -- we dont have any other entry for Bally's Interactive so it cant be filled

-- ====================================
-- exploratory data analysis
-- ====================================
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoff;

SELECT*
FROM layoffs_2
WHERE percentage_laid_off = 1
ORDER BY  funds_raised_millions desc;

-- finding out which total layoff based on industry
SELECT industry,
(SUM(total_laid_off)) total_industry_laid_off
FROM layoff
GROUP BY industry
ORDER BY 2 DESC ;

-- finding out which total layoff based on company
SELECT company,
(SUM(total_laid_off)) total_company_laid_off
FROM layoff
GROUP BY company
ORDER BY 2 DESC;

-- finding out which total layoff based on country
SELECT country,
(SUM(total_laid_off)) total_country_laid_off
FROM layoff
GROUP BY country
ORDER BY 2 DESC;

-- yearly laid off
SELECT year(`date`),
(SUM(total_laid_off)) total_yearly_laid_off
FROM layoff
GROUP BY year(`date`)
ORDER BY 1 ;

-- which company raised maximum funds from layoff
SELECT company,
(SUM(funds_raised_millions)) total_fund_raised
FROM layoff
GROUP BY company
ORDER BY 2 DESC;

-- monthly rolling total asper the industry
WITH rolling_total AS (
SELECT substring(`date`,1,7) `Month`, SUM(total_laid_off) Monthly_laid_off
FROM layoff
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY substring(`date`,1,7)
ORDER BY 1)
SELECT `Month`, Monthly_laid_off,
SUM(Monthly_laid_off) OVER (ORDER BY `month`) AS rolling_total
FROM rolling_total;

-- yearly rolling total asper the industry
WITH rolling_total AS (
SELECT substring(`date`,1,4) `year`, SUM(total_laid_off) yearly_laid_off
FROM layoff
WHERE substring(`date`,1,4) IS NOT NULL
GROUP BY substring(`date`,1,4)
ORDER BY 1)
SELECT `year`, yearly_laid_off,
SUM(yearly_laid_off) OVER (ORDER BY `year`) AS rolling_total
FROM rolling_total;

-- total laid off by company in a year
SELECT company, YEAR(`date`),
SUM(total_laid_off)
FROM layoff
GROUP BY company, YEAR(`date`)
ORDER BY company ;

-- top 5 company rank based on yearly layoff of each year
with yearly_company_layoff (company,years, total_laid_off_yearly)AS (
	SELECT company, YEAR(`date`) AS `year`,
	SUM(total_laid_off) total_laid_off_yearly
	FROM layoff
	GROUP BY company, YEAR(`date`)),
company_rank AS
    (SELECT *,
    DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off_yearly DESC) ranking
    FROM yearly_company_layoff
    WHERE years IS NOT NULL)
SELECT *
FROM company_rank
WHERE ranking <= 5;

SELECT stage, COUNT(company) total_company
FROM layoff
GROUP BY stage
ORDER BY stage;
SELECT * FROM LAYOFF WHERE STAGE IS NULL;

-- ============================================
-- Company Funding Efficiency vs. Layoffs
-- ============================================
 SELECT 
    stage,
    SUM(total_laid_off) AS total_laid_off, 
    ROUND(AVG(total_laid_off), 0) AS avg_laid_off_stage,
    SUM(funds_raised_millions) AS total_fund_raised, 
    ROUND(AVG(funds_raised_millions), 0) AS fund_raised_per_stage,
    COUNT(*) AS total_events
FROM layoff
WHERE stage NOT IN ('Unknown') AND stage IS NOT NULL
GROUP BY stage
ORDER BY total_laid_off DESC;

-- 100% layoff analysis
SELECT industry, SUM(percentage_laid_off), SUM(funds_raised_millions) total_fund_loss
FROM layoff
WHERE percentage_laid_off = 1
GROUP BY industry
ORDER BY SUM(percentage_laid_off) DESC;

-- FINDING THE Repeat Offenders
SELECT company,
	SUM(total_laid_off) total_laid_off,
	COUNT(*) total_event,
	MIN(`DATE`) first_layoff,
	MAX(`DATE`) last_layoff
FROM layoff
GROUP BY company
HAVING total_event >= 3
ORDER BY 2;

-- MoM growth in layoff
SELECT *,
ROUND(((current_month - privious_month )/privious_month) * 100,2) per_change
FROM (SELECT substring(`date`,1,7) `Month`,
	SUM(total_laid_off) current_month,
	LAG(SUM(total_laid_off),1) OVER(ORDER BY substring(`date`,1,7)) privious_month
	FROM layoff
	WHERE substring(`date`,1,7) IS NOT NULL
	GROUP BY substring(`date`,1,7)
	ORDER BY 1) AS monthly_data;

-- top 3 industry layoff in a country
WITH cte_total AS (
	SELECT country, industry,
	SUM(total_laid_off) total_industry_laid_off
	FROM layoff
    WHERE industry IS NOT NULL AND country IS NOT NULL
	 GROUP BY  country, industry),
	cte_ranking AS (
    SELECT *,
	DENSE_RANK() OVER(PARTITION BY COUNTRY ORDER BY total_industry_laid_off DESC ) ranking
	FROM cte_total)
SELECT *
FROM cte_ranking
WHERE ranking <=3;

-- Ctegoraising layoffs
SELECT category,COUNT(*)
FROM (SELECT total_laid_off,
	CASE 
		WHEN total_laid_off < 100 THEN 'small'
		WHEN total_laid_off >= 100 AND total_laid_off <= 500 THEN 'medium'
		WHEN total_laid_off > 500 AND total_laid_off <= 2000 THEN 'large'
		ELSE 'massive' END category
	FROM layoff
	WHERE total_laid_off IS NOT NULL) sub_cat
GROUP BY category;

