create database if not exists jobdata;
show databases;
create table job_data (
ds varchar(20), job_id int, actor_id int, event varchar(20),languauge varchar(20),time_spent int, org char);
desc job_data;
insert into job_data(ds,job_id,actor_id,event_name,language_name,time_spent,org) values(11/30/2020,21,1001,skip,English,15,A),
(11/30/2020,22,1006,transfer,Arabic,25,B),
(11/29/2020,23,1003,decision,Persian,20,C),
(11/28/2020,23,1005,transfer,Persian,22,D),
(11/28/2020,25,1002,decision,Hindi,11,B),
(11/27/2020,11,1007,decision,French,104,D),
(11/26/2020,23,1004,skip,Persian,56,A),
(11/25/2020,20,1003,transfer,Italian,45,C));

create database if not exists operational_analytics;
create table job_data2(ds date, job_id int, actor_id int, event_name varchar(20),language_name varchar(20),time_spent int, org char(2));
insert into job_data2(ds,job_id,actor_id,event_name,language_name,time_spent,org) values('2020-11-30',21,1001,'skip','English',15,'A'),
('2020-11-30',22,1006,'transfer','Arabic',25,'B'),
('2020-11-29',23,1003,'decision','Persian',20,'C'),
('2020-11-28',23,1005,'transfer','Persian',22,'D'),
('2020-11-28',25,1002,'decision','Hindi',11,'B'),
('2020-11-27',11,1007,'decision','French',104,'D'),
('2020-11-26',23,1004,'skip','Persian',56,'A'),
('2020-11-25',20,1003,'transfer','Italian',45,'C');

insert into job_data(ds,job_id,actor_id,event_name,language_name,time_spent,org) values
('2020-11-30',21,1001,'skip','English',15,'A'),
('2020-11-30',22,1006,'transfer','Arabic',25,'B'),
('2020-11-29',23,1003,'decision','Persian',20,'C'),
('2020-11-28',23,1005,'transfer','Persian',22,'D'),
('2020-11-28',25,1002,'decision','Hindi',11,'B'),
('2020-11-27',11,1007,'decision','French',104,'D'),
('2020-11-26',23,1004,'skip','Persian',56,'A'),
('2020-11-25',20,1003,'transfer','Italian',45,'C'),
('2020-11-30',21,1001,'skip','English',15,'A'),
('2020-11-30',22,1006,'transfer','Arabic',25,'B'),
('2020-11-29',23,1003,'decision','Persian',20,'C'),
('2020-11-28',23,1005,'transfer','Persian',22,'D'),
('2020-11-28',25,1002,'decision','Hindi',11,'B'),
('2020-11-27',11,1007,'decision','French',104,'D'),
('2020-11-26',23,1004,'skip','Persian',56,'A'),
('2020-11-25',20,1003,'transfer','Italian',45,'C');




select ds,count(job_id) as no_of_jobs_reviewed,sum(time_spent)/3600 as reviewed_per_hour from job_data2
 where ds between '2020-11-01' and '2020-11-30'
 group by ds;
select * from job_data2;
#Write an SQL query to calculate the 7-day rolling average of throughput. no.of eventas per sec
#Additionally, explain whether you prefer using the daily metric or the 7-day rolling average for throughput, and why.

WITH daily_throughput AS (
    SELECT
        DATE(ds) AS event_date,
        COUNT(job_id) AS total_events,
        COUNT(job_id) / 86400.0 AS events_per_second  -- 86400 seconds in a day
    FROM
        job_data2
    GROUP BY
        DATE(ds)
)
SELECT
    event_date,
    total_events,
    events_per_second,
    AVG(events_per_second) OVER (
        ORDER BY event_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_throughput
FROM
    daily_throughput
ORDER BY
event_date;

SELECT
        DATE(ds) AS event_date,
        COUNT(job_id) AS total_events,
        COUNT(job_id) / sum(time_spent) AS events_per_second  -- 86400 seconds in a day
    FROM
        job_data2
    GROUP BY
        DATE(ds);


WITH CTE AS ( SELECT ds, COUNT(job_id) AS jobs, SUM(time_spent) AS times
FROM job_data2
GROUP BY ds)
SELECT ds, SUM(jobs) OVER (ORDER BY ds ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) / 
SUM(times) OVER (ORDER BY ds ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
AS throughput_7d_rolling_avg FROM CTE;

#Objective: Calculate the percentage share of each language in the last 30 days.
#Your Task: Write an SQL query to calculate the pecentage share of each language over the last 30 days.

SELECT 
    language_name,
    COUNT(job_id) AS jobs,
    ROUND(100 * COUNT(job_id) /sum( count(job_id))over(),
            2)  AS percentage_share
FROM
    job_data2
GROUP BY language_name;

#Duplicate Rows Detection:
#Objective: Identify duplicate rows in the data.
#Your Task: Write an SQL query to display duplicate rows from the job_data table.

select job_id,count(*) as duplicate_count
from job_data2
group by job_id
having
count(*)>1;