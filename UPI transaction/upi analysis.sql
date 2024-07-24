-- Switch to the appropriate database
USE upi_modes;

-- Show tables in the database
SHOW TABLES;

-- Display the first few rows from the dataset
SELECT * FROM `upi transactions 23 24` LIMIT 5;

-- Show column details of the dataset
SHOW COLUMNS FROM `upi transactions 23 24`;

-- Count the total number of rows in the dataset
SELECT COUNT(*) AS total_rows FROM `upi transactions 23 24`;

-- Transaction Analysis by Age Group and Amount
-- Problem Statement :- Analyze the distribution of transaction amounts across different age groups.


-- Create a view to analyze transaction amounts by age group
CREATE VIEW age_grouped_transactions AS
SELECT `Transaction ID`, `Customer Age`, `Transaction Amount`,
    CASE
        WHEN `Customer Age` BETWEEN 0 AND 17 THEN '0-17'
        WHEN `Customer Age` BETWEEN 18 AND 25 THEN '18-25'
        WHEN `Customer Age` BETWEEN 26 AND 30 THEN '26-30'
        WHEN `Customer Age` BETWEEN 31 AND 40 THEN '31-40'
        WHEN `Customer Age` BETWEEN 41 AND 50 THEN '41-50'
        WHEN `Customer Age` BETWEEN 51 AND 60 THEN '51-60'
        ELSE 'above 61'
    END AS age_group
FROM `upi transactions 23 24`;

-- Count transactions by age group
SELECT age_group, COUNT(`Transaction ID`) AS count
FROM age_grouped_transactions
GROUP BY age_group
ORDER BY count DESC;

-- According to this we can say that most number of transacitions are done by the age group of 31-40 years old

-- Average transaction amount by age group
SELECT age_group, ROUND(AVG(`Transaction Amount`), 2) AS `Avg Amount`
FROM age_grouped_transactions
GROUP BY age_group
ORDER BY `Avg Amount` DESC;

-- According to this we can say that the most spender age group is 31-40 years old

-- Transaction Volume and Distribution by State
-- Problem Statement:- Determine which states have the highest transaction volume and analyze the distribution of transaction amounts within each state.

-- Transaction count by state (top 10)
SELECT `From State`, COUNT(`Transaction ID`) AS `Count`
FROM `upi transactions 23 24`
GROUP BY `From State`
ORDER BY `Count` DESC
LIMIT 10;

-- Transaction count by state (bottom 10)
SELECT `From State`, COUNT(`Transaction ID`) AS `Count`
FROM `upi transactions 23 24`
GROUP BY `From State`
ORDER BY `Count` ASC
LIMIT 10;

-- Average transaction amount by state (top 10)
SELECT `From State`, ROUND(AVG(`Transaction Amount`), 2) AS `Avg Amount`
FROM `upi transactions 23 24`
GROUP BY `From State`
ORDER BY `Avg Amount` DESC
LIMIT 10;

-- Average transaction amount by state (bottom 10)
SELECT `From State`, ROUND(AVG(`Transaction Amount`), 2) AS `Avg Amount`
FROM `upi transactions 23 24`
GROUP BY `From State`
ORDER BY `Avg Amount` ASC
LIMIT 10;

-- Bank-wise Transaction Analysis
-- Problem Statement:- Compare transaction volumes and amounts across different banks (Sender Bank and Receiver Bank).

-- Create views to analyze transaction volumes and amounts by banks
CREATE VIEW sender_bank_count AS
SELECT `Sender Bank` AS `Bank`, COUNT(`Transaction ID`) AS `Sender`
FROM `upi transactions 23 24`
GROUP BY `Sender Bank`
ORDER BY `Sender` DESC;

CREATE VIEW receiver_bank_count AS
SELECT `Receiver Bank` AS `Bank`, COUNT(`Transaction ID`) AS `Receiver`
FROM `upi transactions 23 24`
GROUP BY `Receiver Bank`
ORDER BY `Receiver` DESC;

-- Compare sender and receiver banks
SELECT s.Bank, s.Sender, r.Receiver
FROM sender_bank_count s
INNER JOIN receiver_bank_count r ON s.Bank = r.Bank;

-- Total amount sent by sender banks (top 10)
SELECT `Sender Bank`, SUM(`Transaction Amount`) AS `Sent`
FROM `upi transactions 23 24`
GROUP BY `Sender Bank`
ORDER BY `Sent` DESC
LIMIT 10;

-- Total amount received by receiver banks (top 10)
SELECT `Receiver Bank`, SUM(`Transaction Amount`) AS `Received`
FROM `upi transactions 23 24`
GROUP BY `Receiver Bank`
ORDER BY `Received` DESC
LIMIT 10;

-- Create views to calculate cash flow for banks
CREATE VIEW receiver_amount AS
SELECT `Receiver Bank` AS `Bank`, SUM(`Transaction Amount`) AS `count received`
FROM `upi transactions 23 24`
GROUP BY `Receiver Bank`;

CREATE VIEW sender_amount AS
SELECT `Sender Bank` AS `Bank`, SUM(`Transaction Amount`) AS `count sent`
FROM `upi transactions 23 24`
GROUP BY `Sender Bank`;

CREATE VIEW cashflow AS
SELECT s.Bank,
       s.`count sent`,
       COALESCE(r.`count received`, 0) - COALESCE(s.`count sent`, 0) AS `CashFlow`
FROM sender_amount s
LEFT JOIN receiver_amount r ON s.Bank = r.Bank
ORDER BY `CashFlow` DESC;

-- Time Series Analysis of Transaction Trends
-- Analyze transaction trends over time (daily, monthly)

-- Analyze transaction trends over time
CREATE VIEW avg_sent AS
SELECT DAY(`Amount Sent DateTime`) AS `Day`,
       AVG(`Transaction Amount`) AS `sent`
FROM `upi transactions 23 24`
GROUP BY DAY(`Amount Sent DateTime`);

CREATE VIEW avg_received AS
SELECT DAY(`Amount Received DateTime`) AS `Day`,
       AVG(`Transaction Amount`) AS `received`
FROM `upi transactions 23 24`
GROUP BY DAY(`Amount Received DateTime`);

-- Merge sent and received data by day
SELECT s.`Day`, s.`sent`, r.`received`
FROM avg_sent s
LEFT JOIN avg_received r ON s.`Day` = r.`Day`;

-- Monthly transaction amounts
DROP VIEW IF EXISTS monthly_sent;

CREATE VIEW monthly_sent AS
SELECT
    CASE MONTH(`Amount Sent DateTime`)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS `Month`,
    SUM(`Transaction Amount`) AS `Sent`
FROM `upi transactions 23 24`
GROUP BY MONTH(`Amount Sent DateTime`)
ORDER BY MONTH(`Amount Sent DateTime`);

-- Comparison of Transaction Devices
-- Compare transaction volumes and amounts between different transaction devices (Mobile vs. Tablet)

DROP VIEW IF EXISTS device_counts;

CREATE VIEW device_counts AS
SELECT
    `Transaction Device`,
    COUNT(`Transaction ID`) AS `count`
FROM `upi transactions 23 24`
GROUP BY `Transaction Device`
ORDER BY `count` DESC;

DROP VIEW IF EXISTS total_count;

CREATE VIEW total_count AS
SELECT
    COUNT(`Transaction ID`) AS `total_count`
FROM `upi transactions 23 24`;

CREATE VIEW device_percentages AS
SELECT
    d.`Transaction Device`,
    d.`count`,
    (d.`count` / t.`total_count`) * 100 AS `percent_device`
FROM device_counts d
CROSS JOIN total_count t;

-- Total amount by transaction device
CREATE VIEW device_amounts AS
SELECT
    `Transaction Device`,
    SUM(`Transaction Amount`) AS `Amount`
FROM `upi transactions 23 24`
GROUP BY `Transaction Device`;

-- Convert total amount to crores
CREATE VIEW device_amounts_in_crores AS
SELECT
    `Transaction Device`,
    `Amount`,
    ROUND(`Amount` / 10000000, 2) AS `In Crores`
FROM device_amounts;

-- Analysis of Transaction Categories
-- Explore the distribution of transaction categories (Electricity Bill, Movie Bill, etc.) and their corresponding transaction amounts.

CREATE VIEW category_counts AS
SELECT
    `Transaction Category`,
    COUNT(`Transaction ID`) AS `count`
FROM `upi transactions 23 24`
GROUP BY `Transaction Category`;

CREATE VIEW category_percentages AS
SELECT
    c.`Transaction Category`,
    c.`count`,
    ROUND((c.`count` / t.`total_count`) * 100, 2) AS `%`
FROM category_counts c
CROSS JOIN (SELECT COUNT(`Transaction ID`) AS `total_count` FROM `upi transactions 23 24`) t
ORDER BY `%` DESC;

CREATE VIEW category_amounts AS
SELECT
    `Transaction Category`,
    SUM(`Transaction Amount`) AS `Sum`
FROM `upi transactions 23 24`
GROUP BY `Transaction Category`;

CREATE VIEW category_amounts_in_crores AS
SELECT
    `Transaction Category`,
    `Sum`,
    ROUND(`Sum` / 10000000, 2) AS `in cr`
FROM category_amounts
ORDER BY `in cr` DESC;

-- Correlation between transaction amount and age
-- Investigate if there is a correlation between transaction amounts and customer age.

CREATE VIEW age_amounts AS
SELECT
    `Customer Age`,
    SUM(`Transaction Amount`) AS `sum`
FROM `upi transactions 23 24`
GROUP BY `Customer Age`;

CREATE VIEW age_amounts_in_crores AS
SELECT
    `Customer Age`,
    `sum`,
    ROUND(`sum` / 10000000, 2) AS `in cr`
FROM age_amounts
ORDER BY `in cr` DESC;

-- Comparison of UPI Apps Used for Transactions
-- Compare transaction volumes and amounts between different UPI apps (PhonePe, Google Pay, etc.).

CREATE VIEW app_volume AS
SELECT
    `UPI App`,
    COUNT(`Transaction ID`) AS `Count`
FROM `upi transactions 23 24`
GROUP BY `UPI App`;

CREATE VIEW app_volume_percentages AS
SELECT
    a.`UPI App`,
    a.`Count`,
    ROUND((a.`Count` / t.`total_count`) * 100, 2) AS `%`
FROM app_volume a
CROSS JOIN (SELECT COUNT(`Transaction ID`) AS `total_count` FROM `upi transactions 23 24`) t
ORDER BY `%` DESC;

CREATE VIEW app_amounts AS
SELECT
    `UPI App`,
    SUM(`Transaction Amount`) AS `sum`
FROM `upi transactions 23 24`
GROUP BY `UPI App`;

CREATE VIEW app_amounts_in_crores AS
SELECT
    `UPI App`,
    `sum`,
    ROUND(`sum` / 10000000, 2) AS `in cr`
FROM app_amounts
ORDER BY `in cr` DESC;

