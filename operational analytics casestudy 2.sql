create database op;
use op;
CREATE TABLE users (
    user_id INT,
    created_at VARCHAR(50),
    company INT,
    language VARCHAR(30),
    activated_at VARCHAR(50),
    state VARCHAR(30)
);

show variables like 'secure_file_priv';

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users.csv"
into table users
fields terminated by','
enclosed by '"'
lines terminated by'\n'
ignore 1 rows;

select * from users;

alter table users add column temp_created_at datetime;

update users set temp_created_at = str_to_date(created_at, '%d-%m-%Y %H:%i');

alter table users drop column created_at;

alter table users change column temp_created_at created_at datetime;

#first remove blanks inn the .csv file by clicking a1 column and selecting entire table ctrl+a
#thenclick find and select in toolbar -go to spevial-blanks-ok-delete sheet rows
create table events(
user_id	int,
occurred_at varchar(30),
event_type varchar(30),
event_name varchar(30),
location varchar(30),
device varchar(50),
user_type int);

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/events.csv"
into table events
fields terminated by','
enclosed by '"'
lines terminated by'\n'
ignore 1 rows;

select * from events;
desc events;

alter table events add column temp_occurred_at datetime;

update events set temp_occurred_at = str_to_date(occurred_at, '%d-%m-%Y %H:%i');

alter table events drop column occurred_at;

alter table events change column temp_occurred_at occurred_at datetime;

#table 3
 create table email_events(
 user_id int,
 occurred_at varchar(40),
 action	varchar(40),
 user_type int);
 
load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/email_events.csv"
into table  email_events
fields terminated by','
enclosed by '"'
lines terminated by'\n'
ignore 1 rows;

select * from  email_events;

alter table  email_events add column temp_occurred_at datetime;

update  email_events set temp_occurred_at = str_to_date(occurred_at, '%d-%m-%Y %H:%i');

alter table  email_events drop column occurred_at;

alter table email_events change column temp_occurred_at occurred_at datetime;

#Measure the activeness of users on a weekly basis.
#your Task: Write an SQL query to calculate the weekly user engagement.

SELECT 
    EXTRACT(YEAR FROM occurred_at) AS activity_year, 
    EXTRACT(WEEK FROM occurred_at) AS activity_week,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(*) AS total_activities,
    COUNT(*) / COUNT(DISTINCT user_id) AS avg_activities_per_user
FROM 
    events
GROUP BY 
    EXTRACT(YEAR FROM occurred_at), 
    EXTRACT(WEEK FROM occurred_at)
ORDER BY 
    activity_year, 
    activity_week;

SELECT 
    DATE_TRUNC('week', occurred_at) AS week_start,
    COUNT(DISTINCT user_id) AS active_users,
    AVG(event_count) AS avg_events_per_user
FROM (
    SELECT 
        user_id,
        DATE_TRUNC('week', occurred_at) AS week_start,
        COUNT(*) AS event_count
    FROM events
    GROUP BY user_id, DATE_TRUNC('week', eoccurred_at)
) AS weekly_events
GROUP BY week_start
ORDER BY week_start;
#nalyze the growth of users over time for a product.
#Your Task: Write an SQL query to calculate the user growth for the product.
SELECT 
    month(created_at) AS month, 
    COUNT(user_id) AS new_users,
    SUM(COUNT(user_id)) OVER (ORDER BY month(created_at)) AS cumulative_users
FROM 
    users
GROUP BY 
    month(created_at)
ORDER BY 
    month;
    
    #Weekly Retention Analysis:
#Your Task: Write an SQL query to calculate the weekly retention of users based on their sign-up cohort.
    
    SELECT 
    EXTRACT(WEEK FROM occurred_at) AS week_no,
    COUNT(DISTINCT user_id) AS no_of_users
FROM
    events
WHERE
    event_type = 'engagement'
        AND event_name = 'login'
GROUP BY week_no
ORDER BY week_no;


SELECT
    DATE(u.created_at) AS signup_date,
    DATE_ADD(DATE(u.created_at), INTERVAL 7 DAY) AS week1_start,
    DATE_ADD(DATE(u.created_at), INTERVAL 14 DAY) AS week2_start,
    DATE_ADD(DATE(u.created_at), INTERVAL 21 DAY) AS week3_start,
    DATE_ADD(DATE(u.created_at), INTERVAL 28 DAY) AS week4_start,
    COUNT(DISTINCT CASE WHEN e.occurred_at >= DATE_ADD(DATE(u.created_at), INTERVAL 7 DAY) THEN u.user_id END) AS week1_retention,
    COUNT(DISTINCT CASE WHEN e.occurred_at >= DATE_ADD(DATE(u.created_at), INTERVAL 14 DAY) THEN u.user_id END) AS week2_retention,
    COUNT(DISTINCT CASE WHEN e.occurred_at >= DATE_ADD(DATE(u.created_at), INTERVAL 21 DAY) THEN u.user_id END) AS week3_retention,
    COUNT(DISTINCT CASE WHEN e.occurred_at >= DATE_ADD(DATE(u.created_at), INTERVAL 28 DAY) THEN u.user_id END) AS week4_retention
FROM
    users u
LEFT JOIN
    events e ON u.user_id = e.user_id
GROUP BY
    signup_date, week1_start, week2_start, week3_start, week4_start
ORDER BY
    signup_date;

  WITH sign_up_weekly AS (
    SELECT 
        user_id, 
        DATEPART(YEAR, created_at) AS sign_up_year, 
        DATEPART(WEEK, created_at) AS sign_up_week
    FROM 
        users
),

-- Step 2: Capture weekly user activities
activity_weekly AS (
    SELECT 
        user_id, 
        DATEPART(YEAR, occurred_at) AS activity_year, 
        DATEPART(WEEK, occurred_at) AS activity_week
    FROM 
        events
)

-- Step 3: Calculate weekly retention
SELECT 
    s.sign_up_year,
    s.sign_up_week,
    a.activity_year,
    a.activity_week,
     COUNT(DISTINCT a.user_id) AS retained_users,
    DATEDIFF(WEEK, DATEFROMPARTS(s.sign_up_year, 1, 1) + (s.sign_up_week - 1) * 7, DATEFROMPARTS(a.activity_year, 1, 1) + (a.activity_week - 1) * 7) AS week_since_sign_up
   
FROM 
    sign_up_weekly s
LEFT JOIN 
    activity_weekly a ON s.user_id = a.user_id
WHERE 
    DATEDIFF(WEEK, DATEFROMPARTS(s.sign_up_year, 1, 1) + (s.sign_up_week - 1) * 7, DATEFROMPARTS(a.activity_year, 1, 1) + (a.activity_week - 1) * 7) >= 0
GROUP BY 
    s.sign_up_year, 
    s.sign_up_week, 
    a.activity_year, 
    a.activity_week
ORDER BY 
    s.sign_up_year, 
    s.sign_up_week, 
    week_since_sign_up;
    
    #Weekly Engagement Per Device:
#Objective: Measure the activeness of users on a weekly basis per device.
#Your Task: Write an SQL query to calculate the weekly

SELECT 
    EXTRACT(YEAR FROM occurred_at) AS activity_year, 
    EXTRACT(WEEK FROM occurred_at) AS activity_week,
    device,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(*) AS total_activities,
    COUNT(*) / COUNT(DISTINCT user_id) AS avg_activities_per_user
FROM 
    events where event_type="engagement"
GROUP BY 
	device,
    EXTRACT(YEAR FROM occurred_at), 
    EXTRACT(WEEK FROM occurred_at)
    
ORDER BY 
    activity_year, 
    activity_week,
    active_users;    
    #Email Engagement Analysis:
#Objective: Analyze how users are engaging with the email service.
#Your Task: Write an SQL query to calculate the email engagement metrics.

SELECT 
    action,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(*) AS total_actions,
    COUNT(*) / COUNT(DISTINCT user_id) AS avg_actions_per_user
FROM 
    email_events 
GROUP BY 
	action;


SELECT 
    (SUM(CASE
        WHEN email_category = 'email_opened' THEN 1 ELSE 0 END) / SUM(CASE
        WHEN email_category = 'email_sent' THEN 1 ELSE 0 END)) * 100 AS email_open_rate,
    (SUM(CASE
        WHEN email_category = 'email_clicked' THEN 1 ELSE 0 END) / SUM(CASE
        WHEN email_category = 'email_sent' THEN 1 ELSE 0
    END)) * 100 AS email_clicked_rate
FROM
    (SELECT *,
            CASE
                WHEN action IN ('sent_weekly_digest' , 'sent_reengagement_email') THEN ('email_sent')
                WHEN action IN ('email_open') THEN ('email_opened')
                WHEN action IN ('email_clickthrough') THEN ('email_clicked')
            END AS email_category
    FROM
        email_events) AS a;
        
        SELECT
    -- Total emails sent by type
    COUNT(CASE WHEN ee.action = 'sent_weekly_digest' THEN 1 END) AS total_weekly_digests_sent,
    COUNT(CASE WHEN ee.action = 'sent_reengagement_email' THEN 1 END) AS total_reengagement_emails_sent,
    
    -- Total opened and clicked actions
    COUNT(CASE WHEN ee.action = 'email_open' THEN 1 END) AS total_emails_opened,
    COUNT(CASE WHEN ee.action = 'email_clickthrough' THEN 1 END) AS total_email_clickthroughs,
    
    -- Open rate by type of email sent
    COUNT(CASE WHEN ee.action = 'email_open' AND ee.user_id IN (
        SELECT user_id FROM email_events ee_sub WHERE ee_sub.action = 'sent_weekly_digest'
    ) THEN 1 END) / 
    NULLIF(COUNT(CASE WHEN ee.action = 'sent_weekly_digest' THEN 1 END), 0) * 100 AS open_rate_weekly_digest,
    
    COUNT(CASE WHEN ee.action = 'email_open' AND ee.user_id IN (
        SELECT user_id FROM email_events ee_sub WHERE ee_sub.action = 'sent_reengagement_email'
    ) THEN 1 END) / 
    NULLIF(COUNT(CASE WHEN ee.action = 'sent_reengagement_email' THEN 1 END), 0) * 100 AS open_rate_reengagement_email,
    
    -- Click rate by type of email sent
    COUNT(CASE WHEN ee.action = 'email_clickthrough' AND ee.user_id IN (
        SELECT user_id FROM email_events ee_sub WHERE ee_sub.action = 'sent_weekly_digest'
    ) THEN 1 END) / 
    NULLIF(COUNT(CASE WHEN ee.action = 'sent_weekly_digest' THEN 1 END), 0) * 100 AS click_rate_weekly_digest,
    
    COUNT(CASE WHEN ee.action = 'email_clickthrough' AND ee.user_id IN (
        SELECT user_id FROM email_events ee_sub WHERE ee_sub.action = 'sent_reengagement_email'
    ) THEN 1 END) / 
    NULLIF(COUNT(CASE WHEN ee.action = 'sent_reengagement_email' THEN 1 END), 0) * 100 AS click_rate_reengagement_email,
    
    -- Overall open rate and click rate
    COUNT(CASE WHEN ee.action = 'email_open' THEN 1 END) / 
    NULLIF(COUNT(CASE WHEN ee.action LIKE 'sent_%' THEN 1 END), 0) * 100 AS overall_open_rate,
    
    COUNT(CASE WHEN ee.action = 'email_clickthrough' THEN 1 END) / 
    NULLIF(COUNT(CASE WHEN ee.action LIKE 'sent_%' THEN 1 END), 0) * 100 AS overall_click_rate

FROM email_events ee;

SELECT
    DATE(ee.occurred_at) AS event_date,
    COUNT(DISTINCT CASE WHEN ee.action = 'sent_weekly_digest' THEN ee.user_id END) AS emails_sent,
    COUNT(DISTINCT CASE WHEN ee.action = 'email_open' THEN ee.user_id END) AS emails_opened,
    COUNT(DISTINCT CASE WHEN ee.action = 'email_clickthrough' THEN ee.user_id END) AS emails_clicked,
    ROUND(
        (COUNT(DISTINCT CASE WHEN ee.action = 'email_open' THEN ee.user_id END) * 100.0 / 
        COUNT(DISTINCT CASE WHEN ee.action = 'sent_weekly_digest' THEN ee.user_id END)), 2
    ) AS open_rate,
    ROUND(
        (COUNT(DISTINCT CASE WHEN ee.action = 'email_clickthrough' THEN ee.user_id END) * 100.0 / 
        COUNT(DISTINCT CASE WHEN ee.action = 'email_open' THEN ee.user_id END)), 2
    ) AS click_rate
FROM
    email_events ee
GROUP BY
    event_date
ORDER BY
    event_date;
    
