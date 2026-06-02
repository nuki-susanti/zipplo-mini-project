-- ===================================================================
-- Script to populate dim_date
-- ===================================================================
USE ZipploDW;
GO

-- Optional: Clear the table before repopulating
-- TRUNCATE TABLE dim_date;

-- Set the date range for the dimension
DECLARE @StartDate DATE = '2020-01-01'; -- Start date
DECLARE @EndDate DATE = '2040-12-31';   -- End date (covers 20 years)

-- Use a recursive CTE to generate all days between @StartDate and @EndDate
WITH DateDimension_CTE AS (
    SELECT @StartDate AS CurrentDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CurrentDate)
    FROM DateDimension_CTE
    WHERE CurrentDate < @EndDate
)
INSERT INTO dim_date (date_id, [date], [day], [month], [quarter], [year])
SELECT 
    -- Generates a numeric ID in YYYYMMDD format (e.g., 20260601 for today)
    -- This format is highly efficient for joins and remains human-readable.
    CONVERT(INT, CONVERT(VARCHAR(8), CurrentDate, 112)) AS date_id,
    CurrentDate AS [date],
    DAY(CurrentDate) AS [day],
    MONTH(CurrentDate) AS [month],
    DATEPART(QUARTER, CurrentDate) AS [quarter],
    YEAR(CurrentDate) AS [year]
FROM DateDimension_CTE
-- OPTION (MAXRECURSION 0) is mandatory to allow more than 100 recursive steps
OPTION (MAXRECURSION 0); 
GO