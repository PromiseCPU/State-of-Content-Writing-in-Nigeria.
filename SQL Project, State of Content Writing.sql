# DATABASE SETUP IN MYSQL

## Creating the Database & Schema
-- PROJECT: State of Content Writing in Nigeria, 2025
-- Author: Utoh C. Promise (PromiseCPU)
-- Date: 2026
-- Tool: MySQL Workbench

## Creating the Raw Import Table
CREATE DATABASE IF NOT EXISTS nigeria_content_writing;
USE nigeria_content_writing;

DROP TABLE IF EXISTS raw_responses;

CREATE TABLE raw_responses (
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    response_timestamp    VARCHAR(50),
    experience_years      VARCHAR(50),
    gender                VARCHAR(20),
    age_range             VARCHAR(20),
    location              VARCHAR(50),
    education_level       VARCHAR(50),
    content_types         TEXT,
    industries            TEXT,
    client_sources        TEXT,
    monthly_income_range  VARCHAR(80),
    client_type           VARCHAR(100),
    ai_workflow_pct       VARCHAR(20),
    ai_tools_used         TEXT,
    ai_use_cases          TEXT,
    work_days_per_week    VARCHAR(30),
    challenges            TEXT,
    important_skills      TEXT,
    career_choice_today   VARCHAR(20),
    success_factors       TEXT,
    top_client_strategy   TEXT,
    future_trends         TEXT,
    growth_niches         TEXT,
    advice_for_newbies    TEXT,
    community_strengthening TEXT
);

## Importing my CSV File.
-- 1. Right-click your table (raw_response) → Table Data Import Wizard
-- 2. Browse to 'nigeria_content_writers_clean.csv'  (my csv file)
-- 3. Match columns, set encoding to 'UTF-8'
-- 4. Click Next → Finish

-- To Verify Import:
SELECT COUNT(*) AS total_rows FROM raw_responses;
SELECT * FROM raw_responses LIMIT 10;
DESCRIBE raw_responses;


# DATA CLEANING IN MYSQL

## Auditing Nulls and Blanks/ Missing Values
-- To Count NULLs and empty strings across key columns
SELECT
    SUM(gender IS NULL OR gender = '')                AS missing_gender,
    SUM(education_level IS NULL OR education_level = '') AS missing_education,
    SUM(ai_tools_used IS NULL OR ai_tools_used = '')  AS missing_ai_tools,
    SUM(work_days_per_week IS NULL OR work_days_per_week = '') AS missing_workdays,
    SUM(success_factors IS NULL OR success_factors = '')  AS missing_success,
    SUM(top_client_strategy IS NULL OR top_client_strategy = '') AS missing_strategy,
    SUM(future_trends IS NULL OR future_trends = '')  AS missing_trends,
    SUM(growth_niches IS NULL OR growth_niches = '')  AS missing_niches,
    SUM(advice_for_newbies IS NULL OR advice_for_newbies = '') AS missing_advice,
    SUM(community_strengthening IS NULL OR community_strengthening = '') AS missing_community
FROM raw_responses;

## Creating the Cleaned Table

DROP TABLE IF EXISTS cleaned_responses;

CREATE TABLE cleaned_responses AS
SELECT
    id,

    -- Parse timestamp: strip timezone, convert to DATETIME
    STR_TO_DATE(
        TRIM(REPLACE(REPLACE(response_timestamp, 'AM GMT+1', 'AM'), 'PM GMT+1', 'PM')),
        '%Y/%m/%d %h:%i:%s %p'
    ) AS response_date,

    -- Experience: standardize
    TRIM(experience_years) AS experience_years,

    -- Gender: filling NULL with 'Not Specified'
    COALESCE(NULLIF(TRIM(gender), ''), 'Not Specified') AS gender,

    -- Age range: clean
    TRIM(age_range) AS age_range,

    -- Location: standardizing inconsistent spellings
    CASE
        WHEN TRIM(location) IN ('Port - Harcourt', 'Port-Harcourt', 'Port Harcourt') THEN 'Port Harcourt'
        WHEN TRIM(location) IN ('Ilorin, Kwara', 'Ilorin') THEN 'Kwara'
        WHEN TRIM(location) IN ('Akwa - Ibom', 'AkwaIbom', 'Akwa Ibom') THEN 'Akwa Ibom'
        ELSE TRIM(location)
    END AS location,

    -- Education: filling NULL
    COALESCE(NULLIF(TRIM(education_level), ''), 'Not Specified') AS education_level,

    -- Multi-select columns: keeping as-is for now (will explode later)
    TRIM(content_types)    AS content_types,
    TRIM(industries)       AS industries,
    TRIM(client_sources)   AS client_sources,

    -- Income: standardizing the hybrid entry
    CASE
        WHEN monthly_income_range LIKE '%200,000%500,000%500%2,000%'
            THEN '₦200,000 - ₦500,000'
        ELSE TRIM(monthly_income_range)
    END AS monthly_income_range,

    -- Adding numeric income rank for ordering
    CASE
        WHEN monthly_income_range LIKE '%Below%200%'          THEN 1
        WHEN monthly_income_range LIKE '%200,000%500,000%'    THEN 2
        WHEN monthly_income_range LIKE '%500,000%2,000,000%'  THEN 3
        WHEN monthly_income_range LIKE '%Above%2,000,000%'    THEN 4
        ELSE 0
    END AS income_rank,

    TRIM(client_type)         AS client_type,
    TRIM(ai_workflow_pct)     AS ai_workflow_pct,

    -- AI workflow percentage: add numeric midpoint for analysis
    CASE
        WHEN ai_workflow_pct = '0-25%'    THEN 12.5
        WHEN ai_workflow_pct = '26-50%'   THEN 38
        WHEN ai_workflow_pct = '51-75%'   THEN 63
        WHEN ai_workflow_pct = '76-100%'  THEN 88
        ELSE NULL
    END AS ai_workflow_midpoint,

    COALESCE(NULLIF(TRIM(ai_tools_used), ''), 'Not Specified') AS ai_tools_used,
    TRIM(ai_use_cases) AS ai_use_cases,

    -- Work days: standardizing the edge cases
    CASE
        WHEN TRIM(work_days_per_week) = 'No day for now' THEN '0 days'
        WHEN TRIM(work_days_per_week) = '7 days' THEN '7 days'
        ELSE COALESCE(NULLIF(TRIM(work_days_per_week), ''), 'Not Specified')
    END AS work_days_per_week,

    TRIM(challenges)          AS challenges,
    TRIM(important_skills)    AS important_skills,
    TRIM(career_choice_today) AS career_choice_today,

    -- Open text: trimming only
    COALESCE(NULLIF(TRIM(success_factors), ''), 'Not Provided')          AS success_factors,
    COALESCE(NULLIF(TRIM(top_client_strategy), ''), 'Not Provided')      AS top_client_strategy,
    COALESCE(NULLIF(TRIM(future_trends), ''), 'Not Provided')            AS future_trends,
    COALESCE(NULLIF(TRIM(growth_niches), ''), 'Not Provided')            AS growth_niches,
    COALESCE(NULLIF(TRIM(advice_for_newbies), ''), 'Not Provided')       AS advice_for_newbies,
    COALESCE(NULLIF(TRIM(community_strengthening), ''), 'Not Provided')  AS community_strengthening

FROM raw_responses;

-- Verifying Cleaning:
SELECT COUNT(*) FROM cleaned_responses;                      -- Should still be 105
SELECT * FROM cleaned_responses LIMIT 40;

-- Category Standardization at experience_years column
SET SQL_SAFE_UPDATES = 0;

UPDATE cleaned_responses
SET experience_years = '2 - 4 years'
WHERE experience_years = '2-5 years';

SET SQL_SAFE_UPDATES = 1;

SELECT * FROM cleaned_responses WHERE experience_years =  '2 - 4 years';
SELECT DISTINCT experience_years FROM cleaned_responses;
SELECT experience_years, COUNT(*) AS Total FROM cleaned_responses GROUP BY experience_years;

-- Category Standardization at monthly_income_range column
SET SQL_SAFE_UPDATES = 0;

UPDATE cleaned_responses
SET monthly_income_range =   'â‚¦200,000 - â‚¦500,000'
WHERE monthly_income_range =   '2 - 4 years';

SET SQL_SAFE_UPDATES = 1;

SELECT * FROM cleaned_responses WHERE monthly_income_range =  'â‚¦200,000 - â‚¦500,000';
                                             -- 'â‚¦200,000 - â‚¦500,000'             '₦200,000 - ₦500,000'
SELECT DISTINCT monthly_income_range FROM cleaned_responses;
SELECT DISTINCT monthly_income_range, COUNT(*) FROM cleaned_responses GROUP BY monthly_income_range;


## Creating Exploded (Normalized) Tables for Multi-Select Columns(content types, industries, client sources,
															      ## challenges, important skills, AI tools)

-- Multi-select columns contain semicolon-separated values. 
-- We create separate exploded tables for proper analysis and accurate counting.

-- Content Types:
DROP TABLE IF EXISTS writer_content_types;

CREATE TABLE writer_content_types AS
WITH RECURSIVE splitter AS (
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(content_types, ';', 1)) AS content_type,
        IF(LOCATE(';', content_types) > 0,
           SUBSTRING(content_types, LOCATE(';', content_types) + 1),
           NULL) AS remainder
    FROM cleaned_responses
    UNION ALL
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(remainder, ';', 1)),
        IF(LOCATE(';', remainder) > 0,
           SUBSTRING(remainder, LOCATE(';', remainder) + 1),
           NULL)
    FROM splitter
    WHERE remainder IS NOT NULL
)
SELECT id, content_type FROM splitter WHERE content_type != '';

-- Verifying String splitting/ columning exploding/ normalizing a delimited field.
-- (a delimited is a single column that holds multiple values seperated by a special charcter, the delimiter):
SELECT COUNT(*) FROM writer_content_types; 
SELECT * FROM writer_content_types LIMIT 100;


-- Industries:
DROP TABLE IF EXISTS writer_industries;

CREATE TABLE writer_industries AS
WITH RECURSIVE splitter AS (
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(industries, ';', 1)) AS industry,
        IF(LOCATE(';', industries) > 0,
           SUBSTRING(industries, LOCATE(';', industries) + 1),
           NULL) AS remainder
    FROM cleaned_responses
    UNION ALL
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(remainder, ';', 1)),
        IF(LOCATE(';', remainder) > 0,
           SUBSTRING(remainder, LOCATE(';', remainder) + 1),
           NULL)
    FROM splitter
    WHERE remainder IS NOT NULL
)
SELECT id, industry FROM splitter WHERE industry != '';

-- Verifying String splitting
SELECT COUNT(*) FROM writer_industries; 
SELECT * FROM writer_industries LIMIT 100;


-- Client Sources:
DROP TABLE IF EXISTS writer_client_sources;

CREATE TABLE writer_client_sources AS
WITH RECURSIVE splitter AS (
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(client_sources, ';', 1)) AS client_source,
        IF(LOCATE(';', client_sources) > 0,
           SUBSTRING(client_sources, LOCATE(';', client_sources) + 1),
           NULL) AS remainder
    FROM cleaned_responses
    UNION ALL
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(remainder, ';', 1)),
        IF(LOCATE(';', remainder) > 0,
           SUBSTRING(remainder, LOCATE(';', remainder) + 1),
           NULL)
    FROM splitter
    WHERE remainder IS NOT NULL
)
SELECT id, client_source FROM splitter WHERE client_source != '';

-- Verifying String splitting
SELECT COUNT(*) FROM writer_client_sources; 
SELECT * FROM writer_client_sources LIMIT 100;


-- Challenges:
DROP TABLE IF EXISTS writer_challenges;

CREATE TABLE writer_challenges AS
WITH RECURSIVE splitter AS (
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(challenges, ';', 1)) AS challenge,
        IF(LOCATE(';', challenges) > 0,
           SUBSTRING(challenges, LOCATE(';', challenges) + 1),
           NULL) AS remainder
    FROM cleaned_responses
    UNION ALL
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(remainder, ';', 1)),
        IF(LOCATE(';', remainder) > 0,
           SUBSTRING(remainder, LOCATE(';', remainder) + 1),
           NULL)
    FROM splitter
    WHERE remainder IS NOT NULL
)
SELECT id, challenge FROM splitter WHERE challenge != '';

-- Verifying String splitting
SELECT COUNT(*) FROM writer_challenges; 
SELECT * FROM writer_challenges LIMIT 100;


-- Important Skills:
DROP TABLE IF EXISTS writer_important_skills;

CREATE TABLE writer_important_skills AS
WITH RECURSIVE splitter AS (
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(important_skills, ';', 1)) AS skill,
        IF(LOCATE(';', important_skills) > 0,
           SUBSTRING(important_skills, LOCATE(';', important_skills) + 1),
           NULL) AS remainder
    FROM cleaned_responses
    UNION ALL
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(remainder, ';', 1)),
        IF(LOCATE(';', remainder) > 0,
           SUBSTRING(remainder, LOCATE(';', remainder) + 1),
           NULL)
    FROM splitter
    WHERE remainder IS NOT NULL
)
SELECT id, skill FROM splitter WHERE skill != '';

-- Verifying String splitting
SELECT COUNT(*) FROM writer_important_skills; 
SELECT * FROM writer_important_skills LIMIT 100;


-- AI Tools Used:
DROP TABLE IF EXISTS writer_ai_tools;

CREATE TABLE writer_ai_tools AS
WITH RECURSIVE splitter AS (
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(ai_tools_used, ';', 1)) AS ai_tool,
        IF(LOCATE(';', ai_tools_used) > 0,
           SUBSTRING(ai_tools_used, LOCATE(';', ai_tools_used) + 1),
           NULL) AS remainder
    FROM cleaned_responses
    WHERE ai_tools_used != 'Not Specified'
    UNION ALL
    SELECT
        id,
        TRIM(SUBSTRING_INDEX(remainder, ';', 1)),
        IF(LOCATE(';', remainder) > 0,
           SUBSTRING(remainder, LOCATE(';', remainder) + 1),
           NULL)
    FROM splitter
    WHERE remainder IS NOT NULL
)
SELECT id, ai_tool FROM splitter WHERE ai_tool != '';

-- Verifying String splitting
SELECT COUNT(*) FROM writer_ai_tools; 



# EXPLORATORY DATA ANALYSIS (EDA) IN MySQL (KPIs & BUSINESS QUESIONS)

## KPI 1 — Respondent Demographics

-- KPI 1a: Gender Distribution
SELECT
    gender,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS percentage
FROM cleaned_responses
GROUP BY gender
ORDER BY count DESC;

-- KPI 1b: Age Distribution
SELECT
    age_range,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY age_range
ORDER BY FIELD(age_range, '18-30', '31-35', '36-40', 'Above 40');

-- KPI 1c: Top Cities/Locations (Top 10)
SELECT
    location,
    COUNT(*) AS respondents,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY location
ORDER BY respondents DESC
LIMIT 10;

-- KPI 1d: Education Levels
SELECT
    education_level,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY education_level
ORDER BY count DESC;

## KPI 2 — Experience & Career Longevity

-- KPI 2a: Experience Distribution
SELECT
    experience_years,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY experience_years
ORDER BY FIELD(experience_years,
    'Less than 2 years', '2 - 4 years', '4 - 6 years',
    '6 - 8 years', '8 - 10 years', 'More than 10 years');

-- KPI 2b: Would they choose writing again? By Experience
SELECT
    experience_years,
    career_choice_today,
    COUNT(*) AS count
FROM cleaned_responses
GROUP BY experience_years, career_choice_today
ORDER BY FIELD(experience_years,
    'Less than 2 years', '2 - 4 years', '4 - 6 years',
    '6 - 8 years', '8 - 10 years');

## KPI 3 — Income Analysis

-- KPI 3a: Income Distribution
SELECT
    monthly_income_range,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY monthly_income_range, income_rank
ORDER BY income_rank;

-- KPI 3b: Income vs Experience (Cross-tab) 
SELECT
    experience_years,
    monthly_income_range,
    COUNT(*) AS count
FROM cleaned_responses
GROUP BY experience_years, monthly_income_range, income_rank
ORDER BY
    FIELD(experience_years,
        'Less than 2 years', '2 - 4 years', '4 - 6 years',
        '6 - 8 years', '8 - 10 years'),
    income_rank;

-- KPI 3c: Income vs Client Type
SELECT
    client_type,
    monthly_income_range,
    COUNT(*) AS writers,
    ROUND(AVG(income_rank), 2) AS avg_income_rank
FROM cleaned_responses
GROUP BY client_type, monthly_income_range, income_rank
ORDER BY client_type, income_rank;

-- KPI 3d: Income vs Location
SELECT
    location,
    ROUND(AVG(income_rank), 2) AS avg_income_rank,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY location
ORDER BY avg_income_rank DESC;

-- KPI 3e: % of writers earning top bracket by gender
SELECT
    gender,
    COUNT(*) AS total,
    SUM(income_rank = 4) AS top_earners,
    ROUND(SUM(income_rank = 4) * 100.0 / COUNT(*), 1) AS top_earner_pct
FROM cleaned_responses
GROUP BY gender;

## KPI 4 — AI Adoption & Usage

-- KPI 4a: AI workflow percentage distribution
SELECT
    ai_workflow_pct,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY ai_workflow_pct
ORDER BY FIELD(ai_workflow_pct, '0-25%', '26-50%', '51-75%', '76-100%');

-- KPI 4b: Most used AI tools
SELECT
    ai_tool,
    COUNT(*) AS frequency,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct_of_writers
FROM writer_ai_tools
GROUP BY ai_tool
ORDER BY frequency DESC;

-- KPI 4c: What writers use AI for
SELECT
    ai_use_cases,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY ai_use_cases
ORDER BY writers DESC
LIMIT 10;

-- KPI 4d: AI adoption vs income (Does more AI = more $?)
SELECT
    ai_workflow_pct,
    ROUND(AVG(income_rank), 2) AS avg_income_rank,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY ai_workflow_pct
ORDER BY FIELD(ai_workflow_pct, '0-25%', '26-50%', '51-75%', '76-100%');

-- KPI 4e: AI adoption vs experience
SELECT
    experience_years,
    ROUND(AVG(ai_workflow_midpoint), 1) AS avg_ai_usage_pct,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY experience_years
ORDER BY FIELD(experience_years,
    'Less than 2 years', '2 - 4 years', '4 - 6 years',
    '6 - 8 years', '8 - 10 years');

## KPI 5 — Content Types & Industries

-- KPI 5a: Most common content types written
SELECT
    content_type,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM writer_content_types
GROUP BY content_type
ORDER BY writers DESC;

-- KPI 5b: Top industries Nigerian writers serve
SELECT
    industry,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM writer_industries
GROUP BY industry
ORDER BY writers DESC;

-- KPI 5c: Industry vs Income (which industry pays most?) 
SELECT
    wi.industry,
    ROUND(AVG(cr.income_rank), 2) AS avg_income_rank,
    COUNT(DISTINCT wi.id) AS writers
FROM writer_industries wi
JOIN cleaned_responses cr ON wi.id = cr.id
GROUP BY wi.industry
ORDER BY avg_income_rank DESC;

## KPI 6 — Client Acquisition

-- KPI 6a: Top client sourcing channels
SELECT
    client_source,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM writer_client_sources
GROUP BY client_source
ORDER BY writers DESC;

-- KPI 6b: Client type distribution
SELECT
    client_type,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY client_type
ORDER BY writers DESC;

-- KPI 6c: Client type vs Income
SELECT
    client_type,
    ROUND(AVG(income_rank), 2) AS avg_income_rank,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY client_type
ORDER BY avg_income_rank DESC;

-- KPI 6d: Sourcing channel vs income rank
SELECT
    wcs.client_source,
    ROUND(AVG(cr.income_rank), 2) AS avg_income_rank,
    COUNT(DISTINCT wcs.id) AS writers
FROM writer_client_sources wcs
JOIN cleaned_responses cr ON wcs.id = cr.id
GROUP BY wcs.client_source
ORDER BY avg_income_rank DESC;

## KPI 7 — Work Patterns

-- KPI 7a: Days worked per week
SELECT
    work_days_per_week,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY work_days_per_week
ORDER BY FIELD(work_days_per_week,
    '0 days', '1 - 2 days', '3 - 4 days', '5 - 6 days', '7 days');

-- KPI 7b: Work days vs Income
SELECT
    work_days_per_week,
    ROUND(AVG(income_rank), 2) AS avg_income_rank,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY work_days_per_week
ORDER BY avg_income_rank DESC;

## KPI 8 — Challenges Writers Face

-- KPI 8a: Top challenges overall
SELECT
    challenge,
    COUNT(*) AS frequency,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct_of_writers
FROM writer_challenges
GROUP BY challenge
ORDER BY frequency DESC;

-- KPI 8b: Challenges by income bracket
SELECT
    cr.monthly_income_range,
    wc.challenge,
    COUNT(*) AS frequency
FROM writer_challenges wc
JOIN cleaned_responses cr ON wc.id = cr.id
GROUP BY cr.monthly_income_range, cr.income_rank, wc.challenge
ORDER BY cr.income_rank, frequency DESC;

-- KPI 8c: Challenges by experience 
SELECT
    cr.experience_years,
    wc.challenge,
    COUNT(*) AS frequency
FROM writer_challenges wc
JOIN cleaned_responses cr ON wc.id = cr.id
GROUP BY cr.experience_years, wc.challenge
ORDER BY FIELD(cr.experience_years,
    'Less than 2 years', '2 - 4 years', '4 - 6 years',
    '6 - 8 years', '8 - 10 years'),
    frequency DESC;

## KPI 9 — Skills & Career Outlook

-- KPI 9a: Top skills gaining importance
SELECT
    skill,
    COUNT(*) AS frequency,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM writer_important_skills
GROUP BY skill
ORDER BY frequency DESC;

-- KPI 9b: Career sentiment — Would they choose writing again?
SELECT
    career_choice_today,
    COUNT(*) AS writers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_responses), 1) AS pct
FROM cleaned_responses
GROUP BY career_choice_today;

-- KPI 9c: Career sentiment vs income
SELECT
    career_choice_today,
    ROUND(AVG(income_rank), 2) AS avg_income_rank,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY career_choice_today
ORDER BY avg_income_rank DESC;

-- KPI 9d: Career sentiment by gender
SELECT
    gender,
    career_choice_today,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY gender, career_choice_today
ORDER BY gender, writers DESC;

## KPI 10 — Composite Profiling (Advanced)

-- KPI 10a: Profile of a Top Earner
-- Identify patterns of writers earning Above ₦2,000,000
SELECT
    experience_years,
    gender,
    client_type,
    ai_workflow_pct,
    work_days_per_week,
    COUNT(*) AS count
FROM cleaned_responses
WHERE income_rank = 4
GROUP BY experience_years, gender, client_type, ai_workflow_pct, work_days_per_week
ORDER BY count DESC
LIMIT 10;

-- KPI 10b: Profile of lowest earners
SELECT
    experience_years,
    client_type,
    ai_workflow_pct,
    COUNT(*) AS count
FROM cleaned_responses
WHERE income_rank = 1
GROUP BY experience_years, client_type, ai_workflow_pct
ORDER BY count DESC
LIMIT 10;

-- KPI 10c: "Happy writers" — those who said YES to career choice
SELECT
    experience_years,
    income_rank,
    ROUND(AVG(ai_workflow_midpoint), 1) AS avg_ai_usage,
    COUNT(*) AS writers
FROM cleaned_responses
WHERE career_choice_today = 'Yes'
GROUP BY experience_years, income_rank
ORDER BY income_rank DESC, writers DESC;

-- KPI 10d: Location vs AI usage 
SELECT
    location,
    ROUND(AVG(ai_workflow_midpoint), 1) AS avg_ai_pct,
    COUNT(*) AS writers
FROM cleaned_responses
GROUP BY location
ORDER BY avg_ai_pct DESC
LIMIT 10;



# EXPORTING RESULTS TO MS EXCEL (or POWER BI) FOR VISUALIZATION

## Export Queries

-- Run each KPI query and export via:
-- MySQL Workbench → Result Grid → Export → as CSV

-- Recommended exports and their target Excel sheet names:
-- | Query     | Excel Sheet Name |

-- | KPI 1a–1d | Demographics |
-- | KPI 2a–2b | Experience |
-- | KPI 3a–3e | Income Analysis |
-- | KPI 4a–4e | AI Adoption |
-- | KPI 5a–5c | Content & Industries |
-- | KPI 6a–6d | Client Acquisition |
-- | KPI 7a–7b | Work Patterns |
-- | KPI 8a–8c | Challenges |
-- | KPI 9a–9d | Skills & Sentiment |
-- | KPI 10a–10d | Writer Profiles |
