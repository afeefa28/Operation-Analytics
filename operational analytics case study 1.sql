create database if not exists operational_analytics;
CREATE TABLE job_data2 (
    ds DATE,
    job_id INT,
    actor_id INT,
    event_name VARCHAR(20),
    language_name VARCHAR(20),
    time_spent INT,
    org CHAR(2)
);
insert into job_data2(ds,job_id,actor_id,event_name,language_name,time_spent,org) values('2020-11-30',21,1001,'skip','English',15,'A'),
('2020-11-30',22,1006,'transfer','Arabic',25,'B'),
('2020-11-29',23,1003,'decision','Persian',20,'C'),
('2020-11-28',23,1005,'transfer','Persian',22,'D'),
('2020-11-28',25,1002,'decision','Hindi',11,'B'),
('2020-11-27',11,1007,'decision','French',104,'D'),
('2020-11-26',23,1004,'skip','Persian',56,'A'),
('2020-11-25',20,1003,'transfer','Italian',45,'C');

#Calculate the number of jobs reviewed per hour for each day in November 2020.
WITH daily_throughput AS (
    SELECT 
        ds AS review_date,
        COUNT(job_id) / 86400.0 AS events_per_second
    FROM 
        job_data2
    GROUP BY 
        ds
)
SELECT
    review_date,
    events_per_second,
    AVG(events_per_second) OVER (
        ORDER BY review_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_throughput
FROM
    daily_throughput
ORDER BY
    review_date;

#or

SELECT 
    ds,
    COUNT(job_id) AS no_of_jobs_reviewed,
    SUM(time_spent) / 3600 AS reviewed_per_hour
FROM
    job_data2
WHERE
    ds BETWEEN '2020-11-01' AND '2020-11-30'
GROUP BY ds;


SELECT 
    *
FROM
    job_data2;
    
#Write an SQL query to calculate the 7-day rolling average of throughput. no.of eventas per sec
#Additionally, explain whether you prefer using the daily metric or the 7-day rolling average for throughput, and why.



WITH daily_throughput AS (
    SELECT 
        ds,
        COUNT(event_name) / SUM(time_spent) AS throughput
    FROM 
        job_data2
    WHERE 
        ds BETWEEN '2020-11-24' AND '2020-11-30'
    GROUP BY 
        ds
    ORDER BY 
        ds
)
SELECT 
    ds,
    throughput,
    AVG(throughput) OVER (
        ORDER BY ds 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_throughput
FROM 
    daily_throughput;

 
#Objective: Calculate the percentage share of each language in the last 30 days.
#Your Task: Write an SQL query to calculate the pecentage share of each language over the last 30 days.

SELECT 
    language_name,
    COUNT(job_id) AS jobs,
     COUNT(job_id) * 100 /sum( count(job_id))over()
              AS percentage_share
FROM
    job_data2
GROUP BY language_name
order by percentage_share desc;

#Duplicate Rows Detection:
#Objective: Identify duplicate rows in the data.
#Your Task: Write an SQL query to display duplicate rows from the job_data table.

select job_id,count(*) as duplicate_count
from job_data2
group by job_id
having
count(*)>1
order by duplicate_count desc;