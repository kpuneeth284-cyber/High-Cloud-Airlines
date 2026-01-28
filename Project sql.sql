create database excelr_project; 
use excelr_project;
desc maindata;
                                        -- 1. KPI 1.
CREATE TABLE calendar (
  datekey DATE,
  year_num INT,
  month_no INT,
  month_fullname VARCHAR(20),
  quarter VARCHAR(2),
  yearmonth VARCHAR(10),
  weekday_no INT,
  weekday_name VARCHAR(20),
  financial_month INT,
  financial_quarter VARCHAR(2)
);

INSERT INTO calendar (
  datekey, year_num, month_no, month_fullname, quarter, yearmonth,
  weekday_no, weekday_name, financial_month, financial_quarter
)
SELECT
    -- Create DATE from Year, Month(#) and Day
    STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d') AS datekey,
    
    Year AS year_num,
    `Month (#)` AS month_no,
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d'),
        '%M'
    ) AS month_fullname,
    
    CONCAT('Q', QUARTER(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    )) AS quarter,
    
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d'),
        '%Y-%b'
    ) AS yearmonth,
    
    DAYOFWEEK(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    ) AS weekday_no,
    
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d'),
        '%W'
    ) AS weekday_name,

    -- FINANCIAL MONTH (FY = April–March)
    CASE 
        WHEN `Month (#)` >= 4 THEN `Month (#)` - 3
        ELSE `Month (#)` + 9
    END AS financial_month,

    -- FINANCIAL QUARTER
    CASE 
        WHEN `Month (#)` BETWEEN 4 AND 6 THEN 'Q1'
        WHEN `Month (#)` BETWEEN 7 AND 9 THEN 'Q2'
        WHEN `Month (#)` BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS financial_quarter

FROM maindata;

select * from calendar;


								 -- 2.Load factor % FOR YEAR ,MONTH, AND QUARTER

SELECT
    Year,
    concat(round((avg(`# Transported Passengers`) * 1.0 / avg(`# Available Seats`)*100),2),"%") AS Yearly_LoadFactor
FROM maindata
GROUP BY Year
ORDER BY Year;

SELECT
    Year,
    QUARTER(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    ) AS Quarter,
    concat(round((avg(`# Transported Passengers`) * 1.0 / avg(`# Available Seats`)*100),2),"%") AS Quarterly_LoadFactor
FROM maindata
GROUP BY 
    Year,
    QUARTER(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    )
ORDER BY Year, Quarter;

SELECT
    Year,
    `Month (#)` AS MonthNo,
    concat(round((avg(`# Transported Passengers`) * 1.0 / avg(`# Available Seats`)*100),2),"%") AS Monthly_LoadFactor
FROM maindata
GROUP BY 
    Year,
    `Month (#)`
ORDER BY 
    Year,
    MonthNo;


                                        -- 3.Load Factor% of CARRIER name basis

SELECT
  `Carrier Name` AS CarrierName,
  ifnull(concat(round(avg(`# Transported Passengers`) / avg(`# Available Seats`)*100,2),"%"),concat(0,"%")) AS LoadFactor,
  SUM(`# Transported Passengers`) AS TotalPassengers,
  SUM(`# Available Seats`) AS TotalSeats
FROM maindata
GROUP BY `Carrier Name`
ORDER BY LoadFactor DESC;


								-- 4.Top 10 Carrier Names based passengers preference 
                                
SELECT
    `Carrier Name` AS CarrierName,
    SUM(`# Transported Passengers`) AS TotalPassengers
FROM maindata
GROUP BY `Carrier Name`
ORDER BY TotalPassengers DESC
LIMIT 10;



							-- 5.top 5 Routes ( from-to City) based on Number of Flights 
                            
SELECT
  `From - To City` AS Route,
  COUNT(*) AS NumberOfFlights,
  SUM(`# Transported Passengers`) AS Passengers
FROM maindata
GROUP BY `From - To City`
ORDER BY NumberOfFlights DESC
LIMIT 5;

							  -- 6.load factor is occupied on Weekends vs Weekdays
SELECT
    CASE 
        WHEN DAYNAME(
            STR_TO_DATE(CONCAT(Year,'-', LPAD(`Month (#)`,2,'0'), '-', LPAD(Day,2,'0')), '%Y-%m-%d')
        ) IN ('Saturday','Sunday') 
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,

    SUM(`# Transported Passengers`) AS TotalPassengers,
    SUM(`# Available Seats`) AS TotalSeats,
    concat(round(avg(`# Transported Passengers`)/ NULLIF(avg(`# Available Seats`),0),2)*100,"%") AS LoadFactor

FROM maindata
WHERE STR_TO_DATE(CONCAT(Year,'-', LPAD(`Month (#)`,2,'0'), '-', LPAD(Day,2,'0')), '%Y-%m-%d') IS NOT NULL
GROUP BY DayType;


                                -- 7.number of flights based on Distance group
                                
select `%distance group id` as distance_group,count(`%airline id`) as No_of_flights
from maindata
group by distance_group
order by `%distance group id`
