-- ============================================================
-- SQL DATA ANALYSIS CASE STUDIES
-- MySQL 8+
-- Each case study contains schema, sample data, and analysis queries.
-- ============================================================

-- ============================================================
-- CASE STUDY 1: E-COMMERCE SALES ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    gender VARCHAR(10),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    cost DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    payment_method VARCHAR(30),
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO customers VALUES
(1,'Aman','Male','Delhi','2025-01-10'),
(2,'Priya','Female','Lucknow','2025-02-12'),
(3,'Rohit','Male','Noida','2025-03-15'),
(4,'Neha','Female','Delhi','2025-04-18'),
(5,'Arjun','Male','Bareilly','2025-05-20'),
(6,'Simran','Female','Lucknow','2025-06-05'),
(7,'Karan','Male','Noida','2025-06-15'),
(8,'Riya','Female','Delhi','2025-07-01');

INSERT INTO products VALUES
(101,'Laptop','Electronics',65000,52000),
(102,'Mouse','Electronics',1200,700),
(103,'Keyboard','Electronics',2200,1300),
(104,'Headphones','Electronics',3500,2200),
(105,'Office Chair','Furniture',9000,6000),
(106,'Desk','Furniture',12000,8000),
(107,'Backpack','Accessories',1800,1000),
(108,'Monitor','Electronics',18000,13000);

INSERT INTO orders VALUES
(1001,1,'2025-07-01','UPI','Completed'),
(1002,2,'2025-07-03','Card','Completed'),
(1003,3,'2025-07-05','UPI','Completed'),
(1004,1,'2025-07-10','Card','Completed'),
(1005,4,'2025-07-15','COD','Cancelled'),
(1006,5,'2025-08-01','UPI','Completed'),
(1007,6,'2025-08-05','Card','Completed'),
(1008,7,'2025-08-10','UPI','Completed'),
(1009,1,'2025-08-15','Card','Completed'),
(1010,8,'2025-08-20','COD','Completed');

INSERT INTO order_items VALUES
(1,1001,101,1),
(2,1001,102,2),
(3,1002,104,1),
(4,1002,107,2),
(5,1003,105,1),
(6,1004,108,1),
(7,1004,103,1),
(8,1005,106,1),
(9,1006,101,1),
(10,1007,102,3),
(11,1008,105,1),
(12,1009,104,2),
(13,1010,107,1);

-- Basic KPIs
SELECT COUNT(*) AS total_customers FROM customers;
SELECT COUNT(*) AS total_orders FROM orders;
SELECT SUM(oi.quantity * p.price) AS total_revenue
FROM order_items oi JOIN products p ON oi.product_id=p.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.status='Completed';

SELECT AVG(order_value) AS average_order_value
FROM (
    SELECT o.order_id, SUM(oi.quantity*p.price) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id=oi.order_id
    JOIN products p ON oi.product_id=p.product_id
    WHERE o.status='Completed'
    GROUP BY o.order_id
) x;

-- Top customers by spending
SELECT c.customer_id,c.customer_name,
       SUM(oi.quantity*p.price) AS total_spending
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed'
GROUP BY c.customer_id,c.customer_name
ORDER BY total_spending DESC;

-- Category revenue
SELECT p.category,
       SUM(oi.quantity*p.price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.status='Completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- Product performance
SELECT p.product_name,
       SUM(oi.quantity) AS units_sold,
       SUM(oi.quantity*p.price) AS revenue,
       SUM(oi.quantity*(p.price-p.cost)) AS profit
FROM products p
JOIN order_items oi ON p.product_id=oi.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.status='Completed'
GROUP BY p.product_id,p.product_name
ORDER BY revenue DESC;

-- Monthly revenue
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS month,
       SUM(oi.quantity*p.price) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed'
GROUP BY month
ORDER BY month;

-- Customers with no orders
SELECT c.customer_id,c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id=o.customer_id
WHERE o.order_id IS NULL;

-- Products never sold
SELECT p.product_id,p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id=oi.product_id
WHERE oi.product_id IS NULL;

-- Orders greater than 5000
SELECT o.order_id,o.customer_id,
       SUM(oi.quantity*p.price) AS order_value
FROM orders o
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed'
GROUP BY o.order_id,o.customer_id
HAVING order_value > 5000;

-- Repeat customers
SELECT c.customer_id,c.customer_name,COUNT(o.order_id) AS orders_count
FROM customers c JOIN orders o ON c.customer_id=o.customer_id
WHERE o.status='Completed'
GROUP BY c.customer_id,c.customer_name
HAVING COUNT(o.order_id)>1;

-- Ranking products
SELECT product_name,revenue,
       RANK() OVER(ORDER BY revenue DESC) AS revenue_rank
FROM (
    SELECT p.product_name,
           SUM(oi.quantity*p.price) AS revenue
    FROM products p JOIN order_items oi ON p.product_id=oi.product_id
    JOIN orders o ON oi.order_id=o.order_id
    WHERE o.status='Completed'
    GROUP BY p.product_id,p.product_name
) x;

-- Running revenue
SELECT month,revenue,
       SUM(revenue) OVER(ORDER BY month) AS running_revenue
FROM (
    SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS month,
           SUM(oi.quantity*p.price) AS revenue
    FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
    JOIN products p ON oi.product_id=p.product_id
    WHERE o.status='Completed'
    GROUP BY month
) x;


-- ============================================================
-- CASE STUDY 2: RETAIL / SUPERMARKET ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS retail_db;
CREATE DATABASE retail_db;
USE retail_db;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(50),
    membership VARCHAR(20)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    cost DECIMAL(10,2)
);

CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    store_id INT,
    sale_date DATE,
    quantity INT,
    discount DECIMAL(5,2),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id),
    FOREIGN KEY(store_id) REFERENCES stores(store_id)
);

INSERT INTO customers VALUES
(1,'Rahul','Male',24,'Delhi','Gold'),
(2,'Sneha','Female',29,'Noida','Silver'),
(3,'Vikas','Male',35,'Delhi','Gold'),
(4,'Anjali','Female',41,'Lucknow','Platinum'),
(5,'Mohit','Male',27,'Bareilly','Silver'),
(6,'Pooja','Female',32,'Noida','Gold');

INSERT INTO products VALUES
(1,'Rice','Grocery',800,650),
(2,'Oil','Grocery',180,140),
(3,'Shampoo','Personal Care',250,160),
(4,'Soap','Personal Care',60,35),
(5,'Biscuit','Food',40,25),
(6,'Tea','Food',220,150),
(7,'Detergent','Home Care',180,120),
(8,'Toothpaste','Personal Care',110,70);

INSERT INTO stores VALUES
(1,'Central Store','Delhi'),
(2,'City Mall Store','Noida'),
(3,'Main Market Store','Lucknow');

INSERT INTO sales VALUES
(1,1,1,1,'2025-08-01',2,5),
(2,2,3,2,'2025-08-02',3,10),
(3,3,6,1,'2025-08-03',4,5),
(4,4,7,3,'2025-08-05',2,8),
(5,5,5,2,'2025-08-06',10,0),
(6,1,4,1,'2025-08-10',5,5),
(7,6,8,2,'2025-08-12',4,10),
(8,3,2,1,'2025-08-15',5,5),
(9,4,1,3,'2025-08-18',3,8),
(10,2,6,2,'2025-08-20',5,10);

-- Revenue after discount
SELECT SUM(quantity*price*(1-discount/100)) AS revenue
FROM sales s JOIN products p ON s.product_id=p.product_id;

-- Profit after discount
SELECT SUM(quantity*(price*(1-discount/100)-cost)) AS profit
FROM sales s JOIN products p ON s.product_id=p.product_id;

-- Category performance
SELECT p.category,
       SUM(s.quantity) AS units_sold,
       SUM(s.quantity*p.price*(1-s.discount/100)) AS revenue
FROM sales s JOIN products p ON s.product_id=p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Store performance
SELECT st.store_name,
       SUM(s.quantity*p.price*(1-s.discount/100)) AS revenue
FROM sales s
JOIN stores st ON s.store_id=st.store_id
JOIN products p ON s.product_id=p.product_id
GROUP BY st.store_id,st.store_name
ORDER BY revenue DESC;

-- Customer spending
SELECT c.customer_name,
       SUM(s.quantity*p.price*(1-s.discount/100)) AS spending
FROM customers c JOIN sales s ON c.customer_id=s.customer_id
JOIN products p ON s.product_id=p.product_id
GROUP BY c.customer_id,c.customer_name
ORDER BY spending DESC;

-- Customers spending above 2000
SELECT c.customer_name,
       SUM(s.quantity*p.price*(1-s.discount/100)) AS spending
FROM customers c JOIN sales s ON c.customer_id=s.customer_id
JOIN products p ON s.product_id=p.product_id
GROUP BY c.customer_id,c.customer_name
HAVING spending>2000;

-- Top 3 products
SELECT product_name,revenue
FROM (
    SELECT p.product_name,
           SUM(s.quantity*p.price*(1-s.discount/100)) AS revenue,
           DENSE_RANK() OVER(ORDER BY SUM(s.quantity*p.price*(1-s.discount/100)) DESC) AS rnk
    FROM sales s JOIN products p ON s.product_id=p.product_id
    GROUP BY p.product_id,p.product_name
) x
WHERE rnk<=3;


-- ============================================================
-- CASE STUDY 3: BANKING ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS bank_db;
CREATE DATABASE bank_db;
USE bank_db;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    age INT
);

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    account_type VARCHAR(30),
    balance DECIMAL(12,2),
    branch VARCHAR(50),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_date DATE,
    transaction_type VARCHAR(20),
    amount DECIMAL(12,2),
    FOREIGN KEY(account_id) REFERENCES accounts(account_id)
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    loan_type VARCHAR(30),
    loan_amount DECIMAL(12,2),
    branch VARCHAR(50),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

INSERT INTO customers VALUES
(1,'Aman','Delhi',29),
(2,'Priya','Lucknow',34),
(3,'Rohit','Noida',42),
(4,'Neha','Bareilly',31),
(5,'Karan','Delhi',45),
(6,'Simran','Lucknow',27);

INSERT INTO accounts VALUES
(101,1,'Savings',75000,'Delhi'),
(102,2,'Savings',120000,'Lucknow'),
(103,3,'Current',250000,'Noida'),
(104,4,'Savings',45000,'Bareilly'),
(105,5,'Savings',180000,'Delhi'),
(106,6,'Current',90000,'Lucknow');

INSERT INTO transactions VALUES
(1,101,'2025-08-01','Deposit',20000),
(2,101,'2025-08-03','Withdrawal',5000),
(3,102,'2025-08-02','Deposit',30000),
(4,103,'2025-08-04','Deposit',50000),
(5,103,'2025-08-05','Withdrawal',10000),
(6,104,'2025-08-07','Deposit',10000),
(7,105,'2025-08-10','Deposit',40000),
(8,106,'2025-08-11','Withdrawal',15000),
(9,102,'2025-08-15','Withdrawal',20000),
(10,105,'2025-08-20','Deposit',25000);

INSERT INTO loans VALUES
(1,1,'Home Loan',500000,'Delhi'),
(2,2,'Personal Loan',150000,'Lucknow'),
(3,3,'Business Loan',800000,'Noida'),
(4,5,'Car Loan',300000,'Delhi');

-- Total deposits
SELECT SUM(amount) AS total_deposits
FROM transactions
WHERE transaction_type='Deposit';

-- Total withdrawals
SELECT SUM(amount) AS total_withdrawals
FROM transactions
WHERE transaction_type='Withdrawal';

-- Average account balance
SELECT AVG(balance) AS avg_balance FROM accounts;

-- Branch-wise deposits
SELECT branch,SUM(balance) AS deposits
FROM accounts
GROUP BY branch
ORDER BY deposits DESC;

-- Most active customers
SELECT c.customer_name,COUNT(t.transaction_id) AS transaction_count
FROM customers c JOIN accounts a ON c.customer_id=a.customer_id
JOIN transactions t ON a.account_id=t.account_id
GROUP BY c.customer_id,c.customer_name
ORDER BY transaction_count DESC;

-- Customers with loans
SELECT c.customer_name,l.loan_type,l.loan_amount
FROM customers c JOIN loans l ON c.customer_id=l.customer_id;

-- Customers having both account and loan
SELECT DISTINCT c.customer_name
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
JOIN loans l ON c.customer_id=l.customer_id;

-- Loan-to-balance ratio
SELECT c.customer_name,
       SUM(l.loan_amount) AS total_loan,
       SUM(a.balance) AS total_balance,
       ROUND(SUM(l.loan_amount)/NULLIF(SUM(a.balance),0),2) AS loan_balance_ratio
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
JOIN loans l ON c.customer_id=l.customer_id
GROUP BY c.customer_id,c.customer_name;


-- ============================================================
-- CASE STUDY 4: CAB / RIDE ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS ride_db;
CREATE DATABASE ride_db;
USE ride_db;

CREATE TABLE drivers (
    driver_id INT PRIMARY KEY,
    driver_name VARCHAR(100),
    city VARCHAR(50),
    rating DECIMAL(3,2)
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE rides (
    ride_id INT PRIMARY KEY,
    customer_id INT,
    driver_id INT,
    pickup_location VARCHAR(50),
    drop_location VARCHAR(50),
    ride_date DATE,
    distance DECIMAL(8,2),
    fare DECIMAL(10,2),
    rating DECIMAL(3,2),
    status VARCHAR(20),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY(driver_id) REFERENCES drivers(driver_id)
);

INSERT INTO drivers VALUES
(1,'Raj','Delhi',4.8),
(2,'Vivek','Noida',4.5),
(3,'Amit','Delhi',4.9),
(4,'Suresh','Lucknow',4.2),
(5,'Manoj','Noida',4.6);

INSERT INTO customers VALUES
(1,'Riya','Delhi'),
(2,'Ankit','Noida'),
(3,'Pankaj','Delhi'),
(4,'Kriti','Lucknow'),
(5,'Nisha','Noida');

INSERT INTO rides VALUES
(1,1,1,'CP','Airport','2025-08-01',18,450,5,'Completed'),
(2,2,2,'Sector 18','Station','2025-08-01',8,220,4,'Completed'),
(3,3,3,'Rohini','CP','2025-08-02',15,390,5,'Completed'),
(4,4,4,'Hazratganj','Airport','2025-08-03',14,350,4,'Completed'),
(5,5,5,'Sector 62','Mall','2025-08-04',7,200,4,'Completed'),
(6,1,1,'CP','Mall','2025-08-05',6,180,5,'Completed'),
(7,2,2,'Sector 18','Airport','2025-08-06',20,500,3,'Completed'),
(8,3,3,'Rohini','Station','2025-08-07',12,320,5,'Completed'),
(9,4,4,'Mall','Station','2025-08-08',5,150,4,'Cancelled'),
(10,5,5,'Sector 62','Airport','2025-08-09',22,550,5,'Completed');

SELECT COUNT(*) AS total_rides FROM rides;

SELECT status,COUNT(*) AS rides
FROM rides
GROUP BY status;

SELECT SUM(fare) AS total_revenue
FROM rides WHERE status='Completed';

SELECT AVG(fare) AS avg_fare
FROM rides WHERE status='Completed';

SELECT AVG(distance) AS avg_distance
FROM rides WHERE status='Completed';

-- Driver performance
SELECT d.driver_name,
       COUNT(r.ride_id) AS rides,
       SUM(CASE WHEN r.status='Completed' THEN r.fare ELSE 0 END) AS revenue,
       AVG(r.rating) AS avg_customer_rating
FROM drivers d LEFT JOIN rides r ON d.driver_id=r.driver_id
GROUP BY d.driver_id,d.driver_name
ORDER BY revenue DESC;

-- Cancellation rate
SELECT ROUND(
    100*SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END)/COUNT(*),2
) AS cancellation_rate
FROM rides;

-- Fare per KM
SELECT ROUND(AVG(fare/distance),2) AS avg_fare_per_km
FROM rides WHERE status='Completed';

-- Top customers
SELECT c.customer_name,COUNT(r.ride_id) AS rides,
       SUM(r.fare) AS spending
FROM customers c JOIN rides r ON c.customer_id=r.customer_id
WHERE r.status='Completed'
GROUP BY c.customer_id,c.customer_name
ORDER BY rides DESC;

-- Peak day
SELECT DAYNAME(ride_date) AS day_name,COUNT(*) AS rides
FROM rides
WHERE status='Completed'
GROUP BY DAYNAME(ride_date)
ORDER BY rides DESC;


-- ============================================================
-- CASE STUDY 5: OTT / NETFLIX ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS ott_db;
CREATE DATABASE ott_db;
USE ott_db;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(100),
    age INT,
    city VARCHAR(50),
    subscription VARCHAR(30)
);

CREATE TABLE movies (
    movie_id INT PRIMARY KEY,
    movie_name VARCHAR(100),
    genre VARCHAR(50),
    release_year INT
);

CREATE TABLE watch_history (
    watch_id INT PRIMARY KEY,
    user_id INT,
    movie_id INT,
    watch_date DATE,
    watch_minutes INT,
    FOREIGN KEY(user_id) REFERENCES users(user_id),
    FOREIGN KEY(movie_id) REFERENCES movies(movie_id)
);

CREATE TABLE ratings (
    rating_id INT PRIMARY KEY,
    user_id INT,
    movie_id INT,
    rating DECIMAL(2,1),
    FOREIGN KEY(user_id) REFERENCES users(user_id),
    FOREIGN KEY(movie_id) REFERENCES movies(movie_id)
);

INSERT INTO users VALUES
(1,'Aman',22,'Delhi','Premium'),
(2,'Riya',28,'Noida','Basic'),
(3,'Karan',35,'Delhi','Premium'),
(4,'Neha',25,'Lucknow','Standard'),
(5,'Rohit',31,'Bareilly','Premium'),
(6,'Simran',23,'Noida','Basic');

INSERT INTO movies VALUES
(101,'Action One','Action',2023),
(102,'Love Story','Romance',2022),
(103,'Dark World','Thriller',2024),
(104,'Comedy Night','Comedy',2023),
(105,'Family Time','Drama',2021),
(106,'Crime Files','Thriller',2024);

INSERT INTO watch_history VALUES
(1,1,101,'2025-08-01',120),
(2,2,102,'2025-08-01',100),
(3,3,103,'2025-08-02',140),
(4,4,104,'2025-08-03',90),
(5,5,106,'2025-08-04',150),
(6,1,103,'2025-08-05',130),
(7,3,101,'2025-08-06',120),
(8,6,102,'2025-08-07',110),
(9,5,103,'2025-08-08',140),
(10,2,104,'2025-08-09',95);

INSERT INTO ratings VALUES
(1,1,101,4.5),
(2,2,102,4.0),
(3,3,103,4.8),
(4,4,104,3.8),
(5,5,106,4.6),
(6,1,103,4.7),
(7,3,101,4.4),
(8,6,102,3.9),
(9,5,103,4.9),
(10,2,104,3.7);

-- Most watched movies
SELECT m.movie_name,COUNT(w.watch_id) AS views,
       SUM(w.watch_minutes) AS total_watch_minutes
FROM movies m JOIN watch_history w ON m.movie_id=w.movie_id
GROUP BY m.movie_id,m.movie_name
ORDER BY views DESC;

-- Genre performance
SELECT m.genre,
       COUNT(w.watch_id) AS views,
       SUM(w.watch_minutes) AS watch_minutes
FROM movies m JOIN watch_history w ON m.movie_id=w.movie_id
GROUP BY m.genre
ORDER BY watch_minutes DESC;

-- Average rating by movie
SELECT m.movie_name,ROUND(AVG(r.rating),2) AS avg_rating,
       COUNT(r.rating_id) AS rating_count
FROM movies m LEFT JOIN ratings r ON m.movie_id=r.movie_id
GROUP BY m.movie_id,m.movie_name
ORDER BY avg_rating DESC;

-- Most active users
SELECT u.user_name,SUM(w.watch_minutes) AS minutes_watched
FROM users u JOIN watch_history w ON u.user_id=w.user_id
GROUP BY u.user_id,u.user_name
ORDER BY minutes_watched DESC;

-- Subscription performance
SELECT u.subscription,
       COUNT(DISTINCT u.user_id) AS users,
       SUM(w.watch_minutes) AS watch_minutes
FROM users u LEFT JOIN watch_history w ON u.user_id=w.user_id
GROUP BY u.subscription;

-- Users watching more than 200 minutes
SELECT u.user_name,SUM(w.watch_minutes) AS minutes
FROM users u JOIN watch_history w ON u.user_id=w.user_id
GROUP BY u.user_id,u.user_name
HAVING minutes>200;


-- ============================================================
-- CASE STUDY 6: HOSPITAL ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db;
USE hospital_db;

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    patient_name VARCHAR(100),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(50)
);

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    doctor_name VARCHAR(100),
    department VARCHAR(50)
);

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date DATE,
    status VARCHAR(20),
    FOREIGN KEY(patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY(doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE admissions (
    admission_id INT PRIMARY KEY,
    patient_id INT,
    admission_date DATE,
    discharge_date DATE,
    department VARCHAR(50),
    bill_amount DECIMAL(12,2),
    FOREIGN KEY(patient_id) REFERENCES patients(patient_id)
);

INSERT INTO patients VALUES
(1,'Aman','Male',32,'Delhi'),
(2,'Riya','Female',28,'Noida'),
(3,'Rohit','Male',55,'Lucknow'),
(4,'Neha','Female',42,'Bareilly'),
(5,'Karan','Male',61,'Delhi'),
(6,'Pooja','Female',35,'Noida');

INSERT INTO doctors VALUES
(1,'Dr Sharma','Cardiology'),
(2,'Dr Verma','Neurology'),
(3,'Dr Khan','Orthopedics'),
(4,'Dr Gupta','General');

INSERT INTO appointments VALUES
(1,1,1,'2025-08-01','Completed'),
(2,2,4,'2025-08-02','Completed'),
(3,3,2,'2025-08-03','Completed'),
(4,4,3,'2025-08-04','Missed'),
(5,5,1,'2025-08-05','Completed'),
(6,6,4,'2025-08-06','Completed'),
(7,1,1,'2025-08-10','Completed'),
(8,3,2,'2025-08-11','Missed');

INSERT INTO admissions VALUES
(1,1,'2025-08-01','2025-08-04','Cardiology',45000),
(2,2,'2025-08-02','2025-08-03','General',12000),
(3,3,'2025-08-03','2025-08-08','Neurology',65000),
(4,5,'2025-08-05','2025-08-10','Cardiology',80000),
(5,6,'2025-08-06','2025-08-07','General',10000);

-- Total patients
SELECT COUNT(*) AS total_patients FROM patients;

-- Department appointments
SELECT d.department,COUNT(a.appointment_id) AS appointments
FROM doctors d JOIN appointments a ON d.doctor_id=a.doctor_id
GROUP BY d.department
ORDER BY appointments DESC;

-- Hospital revenue
SELECT SUM(bill_amount) AS total_revenue FROM admissions;

-- Average bill
SELECT AVG(bill_amount) AS avg_bill FROM admissions;

-- Average length of stay
SELECT AVG(DATEDIFF(discharge_date,admission_date)) AS avg_stay_days
FROM admissions;

-- Patient expenses
SELECT p.patient_name,SUM(a.bill_amount) AS total_expense
FROM patients p JOIN admissions a ON p.patient_id=a.patient_id
GROUP BY p.patient_id,p.patient_name
ORDER BY total_expense DESC;

-- Doctors with most patients
SELECT d.doctor_name,COUNT(a.appointment_id) AS appointments
FROM doctors d JOIN appointments a ON d.doctor_id=a.doctor_id
GROUP BY d.doctor_id,d.doctor_name
ORDER BY appointments DESC;

-- Missed appointment rate
SELECT ROUND(100*SUM(status='Missed')/COUNT(*),2) AS missed_rate
FROM appointments;

-- Patients with multiple admissions
SELECT p.patient_name,COUNT(a.admission_id) AS admissions
FROM patients p JOIN admissions a ON p.patient_id=a.patient_id
GROUP BY p.patient_id,p.patient_name
HAVING admissions>1;


-- ============================================================
-- CASE STUDY 7: HR / EMPLOYEE ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS hr_db;
CREATE DATABASE hr_db;
USE hr_db;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(12,2),
    joining_date DATE,
    experience_years INT
);

CREATE TABLE performance (
    performance_id INT PRIMARY KEY,
    employee_id INT,
    review_year INT,
    score DECIMAL(5,2),
    FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY,
    employee_id INT,
    attendance_date DATE,
    status VARCHAR(20),
    FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);

INSERT INTO employees VALUES
(1,'Aman','Data Science',70000,'2022-06-01',4),
(2,'Riya','HR',55000,'2023-01-10',3),
(3,'Rohit','Development',80000,'2021-03-15',5),
(4,'Neha','Data Science',75000,'2022-08-20',4),
(5,'Karan','Sales',50000,'2024-01-05',2),
(6,'Simran','Development',85000,'2020-07-01',6),
(7,'Pooja','HR',60000,'2023-06-10',3);

INSERT INTO performance VALUES
(1,1,2025,88),
(2,2,2025,72),
(3,3,2025,91),
(4,4,2025,95),
(5,5,2025,68),
(6,6,2025,93),
(7,7,2025,81);

INSERT INTO attendance VALUES
(1,1,'2025-08-01','Present'),
(2,1,'2025-08-02','Present'),
(3,1,'2025-08-03','Absent'),
(4,2,'2025-08-01','Present'),
(5,2,'2025-08-02','Absent'),
(6,3,'2025-08-01','Present'),
(7,3,'2025-08-02','Present'),
(8,4,'2025-08-01','Present'),
(9,4,'2025-08-02','Present'),
(10,5,'2025-08-01','Absent'),
(11,6,'2025-08-01','Present'),
(12,6,'2025-08-02','Present'),
(13,7,'2025-08-01','Present');

-- Basic HR KPIs
SELECT COUNT(*) AS total_employees FROM employees;
SELECT AVG(salary) AS average_salary FROM employees;

-- Department salary
SELECT department,COUNT(*) AS employees,
       AVG(salary) AS avg_salary,
       MAX(salary) AS max_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- Employees earning above company average
SELECT employee_name,salary
FROM employees
WHERE salary>(SELECT AVG(salary) FROM employees);

-- Performance ranking
SELECT e.employee_name,e.department,p.score,
       RANK() OVER(ORDER BY p.score DESC) AS performance_rank
FROM employees e JOIN performance p ON e.employee_id=p.employee_id;

-- Attendance percentage
SELECT e.employee_name,
       ROUND(100*SUM(a.status='Present')/COUNT(a.attendance_id),2) AS attendance_pct
FROM employees e JOIN attendance a ON e.employee_id=a.employee_id
GROUP BY e.employee_id,e.employee_name;

-- High performance + low attendance
SELECT e.employee_name,p.score,
       ROUND(100*SUM(a.status='Present')/COUNT(a.attendance_id),2) AS attendance_pct
FROM employees e
JOIN performance p ON e.employee_id=p.employee_id
JOIN attendance a ON e.employee_id=a.employee_id
GROUP BY e.employee_id,e.employee_name,p.score
HAVING p.score>=85 AND attendance_pct<80;

-- Top performer per department
SELECT employee_name,department,score
FROM (
    SELECT e.employee_name,e.department,p.score,
           ROW_NUMBER() OVER(PARTITION BY e.department ORDER BY p.score DESC) AS rn
    FROM employees e JOIN performance p ON e.employee_id=p.employee_id
) x
WHERE rn=1;


-- ============================================================
-- CASE STUDY 8: AMAZON / E-COMMERCE ADVANCED ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS marketplace_db;
CREATE DATABASE marketplace_db;
USE marketplace_db;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_id INT,
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    FOREIGN KEY(category_id) REFERENCES categories(category_id)
);

CREATE TABLE sellers (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    seller_id INT,
    order_date DATE,
    status VARCHAR(20),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY(order_id) REFERENCES orders(order_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id)
);

CREATE TABLE reviews (
    review_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    rating DECIMAL(2,1),
    review_date DATE,
    FOREIGN KEY(product_id) REFERENCES products(product_id),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE returns (
    return_id INT PRIMARY KEY,
    order_id INT,
    return_date DATE,
    reason VARCHAR(100),
    FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

INSERT INTO customers VALUES
(1,'Aman','Delhi'),(2,'Riya','Noida'),(3,'Rohit','Lucknow'),
(4,'Neha','Delhi'),(5,'Karan','Bareilly'),(6,'Pooja','Noida');

INSERT INTO categories VALUES
(1,'Electronics'),(2,'Fashion'),(3,'Home'),(4,'Books');

INSERT INTO products VALUES
(101,'Laptop',1,65000,52000),
(102,'Phone',1,30000,24000),
(103,'T-Shirt',2,900,500),
(104,'Shoes',2,2500,1400),
(105,'Mixer',3,4500,3000),
(106,'Chair',3,7000,4800),
(107,'SQL Book',4,800,450),
(108,'Python Book',4,900,500);

INSERT INTO sellers VALUES
(1,'Tech Seller','Delhi'),
(2,'Fashion Hub','Noida'),
(3,'Home Store','Lucknow'),
(4,'Book World','Delhi');

INSERT INTO orders VALUES
(1001,1,1,'2025-08-01','Completed'),
(1002,2,2,'2025-08-02','Completed'),
(1003,3,3,'2025-08-03','Completed'),
(1004,4,1,'2025-08-04','Completed'),
(1005,5,4,'2025-08-05','Cancelled'),
(1006,1,1,'2025-08-06','Completed'),
(1007,6,2,'2025-08-07','Completed'),
(1008,2,4,'2025-08-08','Completed'),
(1009,3,3,'2025-08-09','Completed'),
(1010,4,1,'2025-08-10','Completed');

INSERT INTO order_items VALUES
(1,1001,101,1),
(2,1002,103,3),
(3,1003,105,1),
(4,1004,102,1),
(5,1005,107,2),
(6,1006,108,2),
(7,1007,104,2),
(8,1008,107,3),
(9,1009,106,1),
(10,1010,102,2);

INSERT INTO reviews VALUES
(1,101,1,4.5,'2025-08-05'),
(2,103,2,4.0,'2025-08-06'),
(3,105,3,3.8,'2025-08-07'),
(4,102,4,4.7,'2025-08-08'),
(5,108,1,4.8,'2025-08-09'),
(6,104,6,4.1,'2025-08-10'),
(7,107,2,3.5,'2025-08-11'),
(8,106,3,4.2,'2025-08-12');

INSERT INTO returns VALUES
(1,1002,'2025-08-10','Size issue'),
(2,1009,'2025-08-12','Damaged');

-- Marketplace KPIs
SELECT COUNT(*) AS total_orders FROM orders WHERE status='Completed';

SELECT SUM(oi.quantity*p.price) AS revenue
FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed';

SELECT SUM(oi.quantity*(p.price-p.cost)) AS gross_profit
FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed';

-- Category performance
SELECT c.category_name,
       SUM(oi.quantity) AS units,
       SUM(oi.quantity*p.price) AS revenue,
       SUM(oi.quantity*(p.price-p.cost)) AS profit
FROM categories c
JOIN products p ON c.category_id=p.category_id
JOIN order_items oi ON p.product_id=oi.product_id
JOIN orders o ON oi.order_id=o.order_id
WHERE o.status='Completed'
GROUP BY c.category_id,c.category_name
ORDER BY revenue DESC;

-- Seller performance
SELECT s.seller_name,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity*p.price) AS revenue,
       SUM(oi.quantity*(p.price-p.cost)) AS profit
FROM sellers s
JOIN orders o ON s.seller_id=o.seller_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed'
GROUP BY s.seller_id,s.seller_name
ORDER BY revenue DESC;

-- Customer lifetime value / spending
SELECT c.customer_name,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity*p.price) AS total_spending
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.status='Completed'
GROUP BY c.customer_id,c.customer_name
ORDER BY total_spending DESC;

-- Return rate
SELECT ROUND(
    100*COUNT(DISTINCT r.order_id)/COUNT(DISTINCT o.order_id),2
) AS return_rate
FROM orders o
LEFT JOIN returns r ON o.order_id=r.order_id
WHERE o.status='Completed';

-- Product rating
SELECT p.product_name,AVG(r.rating) AS avg_rating
FROM products p LEFT JOIN reviews r ON p.product_id=r.product_id
GROUP BY p.product_id,p.product_name
ORDER BY avg_rating DESC;

-- Top 3 products in each category
SELECT category_name,product_name,revenue
FROM (
    SELECT c.category_name,p.product_name,
           SUM(oi.quantity*p.price) AS revenue,
           ROW_NUMBER() OVER(
               PARTITION BY c.category_id
               ORDER BY SUM(oi.quantity*p.price) DESC
           ) AS rn
    FROM categories c
    JOIN products p ON c.category_id=p.category_id
    JOIN order_items oi ON p.product_id=oi.product_id
    JOIN orders o ON oi.order_id=o.order_id
    WHERE o.status='Completed'
    GROUP BY c.category_id,c.category_name,p.product_id,p.product_name
) x
WHERE rn<=3;

-- Customers who bought from multiple categories
SELECT c.customer_name,COUNT(DISTINCT cat.category_id) AS categories_bought
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
JOIN categories cat ON p.category_id=cat.category_id
WHERE o.status='Completed'
GROUP BY c.customer_id,c.customer_name
HAVING categories_bought>1;


-- ============================================================
-- CASE STUDY 9: SOCIAL MEDIA ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS social_db;
CREATE DATABASE social_db;
USE social_db;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE posts (
    post_id INT PRIMARY KEY,
    user_id INT,
    post_date DATE,
    category VARCHAR(50),
    FOREIGN KEY(user_id) REFERENCES users(user_id)
);

CREATE TABLE likes (
    like_id INT PRIMARY KEY,
    post_id INT,
    user_id INT,
    FOREIGN KEY(post_id) REFERENCES posts(post_id),
    FOREIGN KEY(user_id) REFERENCES users(user_id)
);

CREATE TABLE comments (
    comment_id INT PRIMARY KEY,
    post_id INT,
    user_id INT,
    FOREIGN KEY(post_id) REFERENCES posts(post_id),
    FOREIGN KEY(user_id) REFERENCES users(user_id)
);

INSERT INTO users VALUES
(1,'Aman','Delhi'),(2,'Riya','Noida'),(3,'Rohit','Lucknow'),
(4,'Neha','Delhi'),(5,'Karan','Bareilly');

INSERT INTO posts VALUES
(1,1,'2025-08-01','Tech'),
(2,2,'2025-08-01','Travel'),
(3,3,'2025-08-02','Tech'),
(4,4,'2025-08-03','Food'),
(5,1,'2025-08-04','Education'),
(6,5,'2025-08-05','Tech'),
(7,2,'2025-08-06','Travel');

INSERT INTO likes VALUES
(1,1,2),(2,1,3),(3,1,4),(4,2,1),(5,2,3),
(6,3,1),(7,3,2),(8,3,4),(9,3,5),(10,4,1),
(11,5,2),(12,5,3),(13,6,1),(14,6,2),(15,7,4);

INSERT INTO comments VALUES
(1,1,2),(2,1,3),(3,2,1),(4,3,1),(5,3,2),
(6,3,4),(7,4,1),(8,5,2),(9,6,1),(10,7,4);

-- Posts per user
SELECT u.user_name,COUNT(p.post_id) AS posts
FROM users u LEFT JOIN posts p ON u.user_id=p.user_id
GROUP BY u.user_id,u.user_name
ORDER BY posts DESC;

-- Likes per post
SELECT p.post_id,u.user_name,
       COUNT(l.like_id) AS likes
FROM posts p
JOIN users u ON p.user_id=u.user_id
LEFT JOIN likes l ON p.post_id=l.post_id
GROUP BY p.post_id,u.user_name
ORDER BY likes DESC;

-- Engagement per post
SELECT p.post_id,u.user_name,
       COUNT(DISTINCT l.like_id) AS likes,
       COUNT(DISTINCT c.comment_id) AS comments,
       COUNT(DISTINCT l.like_id)+COUNT(DISTINCT c.comment_id) AS engagement
FROM posts p
JOIN users u ON p.user_id=u.user_id
LEFT JOIN likes l ON p.post_id=l.post_id
LEFT JOIN comments c ON p.post_id=c.post_id
GROUP BY p.post_id,u.user_name
ORDER BY engagement DESC;

-- Category performance
SELECT p.category,
       COUNT(DISTINCT p.post_id) AS posts,
       COUNT(DISTINCT l.like_id) AS likes,
       COUNT(DISTINCT c.comment_id) AS comments
FROM posts p
LEFT JOIN likes l ON p.post_id=l.post_id
LEFT JOIN comments c ON p.post_id=c.post_id
GROUP BY p.category
ORDER BY likes DESC;

-- Most active users by interaction
SELECT u.user_name,
       COUNT(DISTINCT l.like_id) AS likes_given,
       COUNT(DISTINCT c.comment_id) AS comments_given
FROM users u
LEFT JOIN likes l ON u.user_id=l.user_id
LEFT JOIN comments c ON u.user_id=c.user_id
GROUP BY u.user_id,u.user_name
ORDER BY (likes_given+comments_given) DESC;


-- ============================================================
-- CASE STUDY 10: STUDENT PERFORMANCE ANALYTICS
-- ============================================================

DROP DATABASE IF EXISTS student_db;
CREATE DATABASE student_db;
USE student_db;

CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100),
    batch VARCHAR(30),
    course VARCHAR(50),
    gender VARCHAR(10)
);

CREATE TABLE marks (
    mark_id INT PRIMARY KEY,
    student_id INT,
    subject VARCHAR(50),
    marks DECIMAL(5,2),
    FOREIGN KEY(student_id) REFERENCES students(student_id)
);

CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY,
    student_id INT,
    attendance_date DATE,
    status VARCHAR(20),
    FOREIGN KEY(student_id) REFERENCES students(student_id)
);

INSERT INTO students VALUES
(1,'Aman','Batch A','Data Science','Male'),
(2,'Riya','Batch A','Data Science','Female'),
(3,'Rohit','Batch A','Data Science','Male'),
(4,'Neha','Batch B','Data Analytics','Female'),
(5,'Karan','Batch B','Data Analytics','Male'),
(6,'Pooja','Batch B','Data Analytics','Female'),
(7,'Simran','Batch C','Machine Learning','Female'),
(8,'Vikas','Batch C','Machine Learning','Male');

INSERT INTO marks VALUES
(1,1,'Python',88),(2,1,'SQL',92),(3,1,'ML',85),
(4,2,'Python',78),(5,2,'SQL',81),(6,2,'ML',75),
(7,3,'Python',95),(8,3,'SQL',89),(9,3,'ML',91),
(10,4,'Excel',90),(11,4,'SQL',86),(12,4,'Power BI',88),
(13,5,'Excel',65),(14,5,'SQL',70),(15,5,'Power BI',68),
(16,6,'Excel',92),(17,6,'SQL',94),(18,6,'Power BI',90),
(19,7,'Python',91),(20,7,'SQL',96),(21,7,'ML',93),
(22,8,'Python',70),(23,8,'SQL',75),(24,8,'ML',72);

INSERT INTO attendance VALUES
(1,1,'2025-08-01','Present'),(2,1,'2025-08-02','Present'),(3,1,'2025-08-03','Present'),
(4,2,'2025-08-01','Present'),(5,2,'2025-08-02','Absent'),(6,2,'2025-08-03','Present'),
(7,3,'2025-08-01','Present'),(8,3,'2025-08-02','Present'),(9,3,'2025-08-03','Present'),
(10,4,'2025-08-01','Present'),(11,4,'2025-08-02','Present'),(12,4,'2025-08-03','Absent'),
(13,5,'2025-08-01','Absent'),(14,5,'2025-08-02','Present'),(15,5,'2025-08-03','Absent'),
(16,6,'2025-08-01','Present'),(17,6,'2025-08-02','Present'),(18,6,'2025-08-03','Present'),
(19,7,'2025-08-01','Present'),(20,7,'2025-08-02','Present'),(21,7,'2025-08-03','Present'),
(22,8,'2025-08-01','Present'),(23,8,'2025-08-02','Absent'),(24,8,'2025-08-03','Present');

-- Student average
SELECT s.student_name,ROUND(AVG(m.marks),2) AS average_marks
FROM students s JOIN marks m ON s.student_id=m.student_id
GROUP BY s.student_id,s.student_name
ORDER BY average_marks DESC;

-- Top 5 students
SELECT student_name,average_marks
FROM (
    SELECT s.student_name,AVG(m.marks) AS average_marks,
           RANK() OVER(ORDER BY AVG(m.marks) DESC) AS rnk
    FROM students s JOIN marks m ON s.student_id=m.student_id
    GROUP BY s.student_id,s.student_name
) x
WHERE rnk<=5;

-- Subject-wise average
SELECT subject,ROUND(AVG(marks),2) AS average_marks
FROM marks
GROUP BY subject
ORDER BY average_marks DESC;

-- Course-wise performance
SELECT s.course,ROUND(AVG(m.marks),2) AS avg_marks
FROM students s JOIN marks m ON s.student_id=m.student_id
GROUP BY s.course
ORDER BY avg_marks DESC;

-- Attendance percentage
SELECT s.student_name,
       ROUND(100*SUM(a.status='Present')/COUNT(a.attendance_id),2) AS attendance_pct
FROM students s JOIN attendance a ON s.student_id=a.student_id
GROUP BY s.student_id,s.student_name
ORDER BY attendance_pct DESC;

-- Low attendance
SELECT s.student_name,
       ROUND(100*SUM(a.status='Present')/COUNT(a.attendance_id),2) AS attendance_pct
FROM students s JOIN attendance a ON s.student_id=a.student_id
GROUP BY s.student_id,s.student_name
HAVING attendance_pct<75;

-- Low marks
SELECT s.student_name,ROUND(AVG(m.marks),2) AS avg_marks
FROM students s JOIN marks m ON s.student_id=m.student_id
GROUP BY s.student_id,s.student_name
HAVING avg_marks<75;

-- Low attendance AND low marks
SELECT s.student_name,
       ROUND(AVG(m.marks),2) AS avg_marks,
       ROUND(100*SUM(a.status='Present')/COUNT(a.attendance_id),2) AS attendance_pct
FROM students s
JOIN marks m ON s.student_id=m.student_id
JOIN attendance a ON s.student_id=a.student_id
GROUP BY s.student_id,s.student_name
HAVING avg_marks<75 AND attendance_pct<75;

-- Top student in each course
SELECT student_name,course,avg_marks
FROM (
    SELECT s.student_name,s.course,AVG(m.marks) AS avg_marks,
           ROW_NUMBER() OVER(
               PARTITION BY s.course
               ORDER BY AVG(m.marks) DESC
           ) AS rn
    FROM students s JOIN marks m ON s.student_id=m.student_id
    GROUP BY s.student_id,s.student_name,s.course
) x
WHERE rn=1;

-- ============================================================
-- END
-- ============================================================
