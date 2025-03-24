-- Create working table to preserve the raw data
CREATE TABLE layoffs_staging
LIKE layoffs

-- Insert raw data into working table
INSERT layoffs_staging
SELECT *
FROM layoffs

-- Removing Duplicates--

-- Create a row number column to identify duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, insdustry, total_laid_off,percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging

-- Create a CTE to filter the table by any row number greate than 1
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, insdustry, total_laid_off,percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1

--Create a 2nd staging database
CREATE TABLE layoffs_staging2 (
'company' text,
'location' text,
'industry' text,
'total_laid_off' INT DEFAULT NULL,
'percentage_laid_off' text,
'date' text,
'stage' text,
'country' text,
'funds_raised_millions' INT DEFAULT NULL,
'row_num' INT) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci

--Insert layoffs_staging data into layoffs_staging2
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, insdustry, total_laid_off,percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging

-- Delete Duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1

-- Standardizing Data --

-- Remove sapces from company name
SELECT company, TRIM(company)
FROM layoffs_staging2

UPDATE layoffs_staging2
SET company = TRIM(company)

-- Make industry names consistent
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1

SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'

-- Remove period from country naems
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'

--Change date column from text to date
SELECT 'date',
STR_TO_DATE('date',;%m/%d/%Y')
FROM layoffs_staging2

UPDATE layoffs_staging2
SET 'date' = STR_TO_DATE('date',;%m/%d/%Y')

ALTER TABLE layoffs_staging2
MODIFY COLUMN 'date' DATE

-- Null and Blank values --

-- Inner join on industry to popuulate blank fields
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = ''
 
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	AND t1.location = t2. location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL

-- Remove Columns and Rows --

-- Delete where there is no data	
DELETE layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL

-- Remove self created column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num






