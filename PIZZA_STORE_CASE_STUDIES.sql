/*Basic:
Retrieve the total number of orders placed.
Calculate the total revenue generated from pizza sales.
Identify the highest-priced pizza.
Identify the most common pizza size ordered.
List the top 5 most ordered pizza types along with their quantities.


Intermediate:
Join the necessary tables to find the total quantity of each pizza category ordered.
Determine the distribution of orders by hour of the day.
Join relevant tables to find the category-wise distribution of pizzas.
Group the orders by date and calculate the average number of pizzas ordered per day.
Determine the top 3 most ordered pizza types based on revenue.

Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.*/


drop schema pizza;
create schema pizza;
use pizza;
drop table if exists order_details;
create table if not exists order_details
(
order_details_id int,
order_id int,
pizza_id varchar(255),
quantity int);

select *
from order_details;


drop table if exists orders;
create table if not exists order_id
(
order_id  int,
date date,
time time
);
select *
from orders;


drop table if exists pizza_types;
create table if not exists pizza_types
(
pizza_type_id varchar(255),
name text,
category text,
ingredients varchar(255)
);

select *
from pizza_types;


drop table if exists pizzas;
create table if not exists pizzas
( pizza_id varchar(255),
pizza_type_id varchar(255),
size text,
price float
);


select *
from pizzas;



-- BASIC

#1. Retrieve the total number of orders placed.

SELECT COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDER_PLACED
FROM ORDER_DETAILS;


#2. Calculate the total revenue generated from pizza sales.


WITH CTE AS 
(SELECT OD.PIZZA_ID, QUANTITY, PRICE,  (QUANTITY * PRICE ) AS BILL
FROM 
ORDER_DETAILS AS OD
INNER JOIN
PIZZAS AS P
ON OD.PIZZA_ID = P.PIZZA_ID
)
SELECT ROUND(SUM(BILL),2) AS TOTAL_REVENUE
FROM CTE;
 ;
 
 #3. Identify the highest-priced pizza.
 
 WITH CTE AS 
 (SELECT PIZZA_ID, PIZZA_TYPE_ID, PRICE 
 FROM
 PIZZAS
 WHERE PRICE IN (SELECT MAX(PRICE) FROM PIZZAS) 
 ) 
 SELECT PT.NAME, CTE.PRICE
 FROM CTE
 JOIN
 PIZZA_TYPES AS PT
 ON CTE.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
 ;
 
 
 
 
  #4. Identify the most common pizza size ordered.
  WITH CTE AS
  (
  SELECT P.PIZZA_ID, SIZE, QUANTITY
  FROM
  PIZZAS AS P
  INNER JOIN
  ORDER_DETAILS AS OD
  ON OD.PIZZA_ID = P.PIZZA_ID
  ),
  T2 AS (
  SELECT  CTE.SIZE, COUNT(CTE.QUANTITY) AS TOTAL_NO_OF_ORDERS
  FROM
  CTE 
  GROUP BY CTE.SIZE
  )
  SELECT *
  FROM
  (
  SELECT *, DENSE_RANK() OVER (ORDER BY TOTAL_NO_OF_ORDERS DESC ) AS SR
  FROM 
  T2)  AS T3
  WHERE SR = 1
  ;
  
  
  #5. List the top 5 most ordered pizza types along with their quantities.
  
  WITH CTE AS 
  (
  SELECT PIZZA_TYPE_ID , SUM(QUANTITY) AS TOTAL_COUNT, DENSE_RANK() OVER( ORDER BY COUNT(QUANTITY) DESC)  AS SR
  FROM
  PIZZAS AS P
  INNER JOIN
  ORDER_DETAILS AS OD
  ON
  P.PIZZA_ID = OD.PIZZA_ID
  GROUP BY PIZZA_TYPE_ID
  ORDER BY TOTAL_COUNT DESC
  )
  SELECT * FROM CTE WHERE SR <= 5
  ;
  
  -- INTERMIDEATE 
  
#6. Join the necessary tables to find the total quantity of each pizza category ordered.

WITH T1 AS
(
SELECT OD.PIZZA_ID, P.PIZZA_TYPE_ID,QUANTITY, CATEGORY
FROM
ORDER_DETAILS AS OD 
INNER JOIN
PIZZAS AS P
ON P.PIZZA_ID = OD.PIZZA_ID
INNER JOIN
PIZZA_TYPES AS PT
ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
)
SELECT CATEGORY , SUM(QUANTITY) AS TOTAL_COUNT
FROM
T1 
GROUP BY CATEGORY
ORDER BY TOTAL_COUNT DESC
;

#7 Determine the distribution of PIZZAS by hour of the day.  
  WITH T1 AS 
  (
  SELECT OD.ORDER_ID, OD.QUANTITY, O.TIME
  FROM
  ORDER_DETAILS AS OD 
  INNER JOIN
  ORDERS AS O
  ON OD.ORDER_ID = O.ORDER_ID
  ),
  T2 AS (
 SELECT *, HOUR(TIME) AS HR
 FROM
 T1
 )
 SELECT HR, COUNT(QUANTITY) AS TOTAL_NUMBER
 FROM T2
 GROUP BY HR
  ORDER BY TOTAL_NUMBER DESC
  ;
  
                                              -- OR,
 # Determine the distribution of ORDERS by hour of the day.  
 
 SELECT HOUR(TIME) AS HR, COUNT(ORDER_ID) AS TOTAL_COUNT
 FROM
 ORDERS 
 GROUP BY HR
 ORDER BY HR ASC
 ;
  
  #8. Join relevant tables to find the category-wise distribution of pizzas.
  
  SELECT CATEGORY, COUNT(NAME) AS TOTAL
  FROM
  PIZZA_TYPES
  GROUP BY CATEGORY 
  ORDER BY TOTAL DESC;
  
  
  #9. Group the orders by date and calculate the average number of pizzas ordered per day.
  
WITH T1 AS 
(
SELECT O.DATE, OD.QUANTITY
FROM
ORDER_DETAILS AS OD
INNER JOIN
ORDERS AS O
ON OD.ORDER_ID = O.ORDER_ID
),
T2 AS (
SELECT  DATE , SUM(QUANTITY) AS TOTAL
FROM
T1
GROUP BY DATE
)
SELECT  ROUND(AVG(TOTAL),2) AS AVG_NUMBER_OF_PIZZAS_ORDER_PER_DAY 
FROM
T2 ;
  
#10. Determine the top 3 most ordered pizza types based on revenue.  

WITH T1 AS
(
SELECT P.PIZZA_ID, P.PIZZA_TYPE_ID, P.PRICE, OD.QUANTITY, ROUND((P.PRICE * OD.QUANTITY),2) AS REVENUE
FROM
PIZZAS AS P 
INNER JOIN
ORDER_DETAILS AS OD
ON
P.PIZZA_ID = OD.PIZZA_ID
)
SELECT *
FROM
(
SELECT PIZZA_TYPE_ID, SUM(REVENUE) AS REVENUE, DENSE_RANK() OVER(ORDER BY SUM(REVENUE) DESC) AS SR
FROM
T1 
GROUP BY PIZZA_TYPE_ID
) TOP_3
WHERE SR <= 3;

                                       -- ADVANCED

  #11. Calculate the percentage contribution of each pizza type to total revenue.
  WITH T1 AS 
  (
  SELECT PT.CATEGORY ,P.PRICE, OD.QUANTITY, (PRICE * QUANTITY) AS REVENUE
  FROM
  ORDER_DETAILS AS OD
  JOIN
  PIZZAS AS P
  ON P.PIZZA_ID = OD.PIZZA_ID 
  JOIN
  PIZZA_TYPES AS PT
  ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
  )
  
  SELECT *, ROUND((REV / (SELECT SUM(REVENUE) FROM T1 ) *100),2) AS PERCENTAGE_CONTRIBUTION
  FROM
  (
  SELECT CATEGORY, ROUND(SUM(REVENUE),2) AS REV
  FROM T1
  GROUP BY CATEGORY
  ) AS PERC
  ORDER BY PERCENTAGE_CONTRIBUTION DESC;
  
 #12. Analyze the cumulative revenue generated over time.
 WITH T1 AS 
 ( 
 SELECT O.DATE,  ROUND((P.PRICE * OD.QUANTITY),2) AS REVENUE
 FROM
 PIZZAS AS P 
 JOIN
 ORDER_DETAILS AS OD 
 ON P.PIZZA_ID = OD.PIZZA_ID
 JOIN
 ORDERS AS O
 ON O.ORDER_ID = OD.ORDER_ID
 
 )
 SELECT DATE, SUM(REVENUE1) OVER(ORDER BY DATE) AS CUMULATIVE_REVENUE
 FROM
 (
 SELECT DATE, ROUND(SUM(REVENUE),2) AS REVENUE1
 FROM T1
 GROUP BY DATE
 ) AS SALES;
 
#13. Determine the top 3 pizza types based on revenue for each pizza category 

WITH T1 AS
(
SELECT  PT.CATEGORY, PT.NAME, SUM( ROUND((P.PRICE * OD.QUANTITY),2)) AS REVENUE, 
DENSE_RANK() OVER( PARTITION BY CATEGORY ORDER BY SUM( ROUND((P.PRICE * OD.QUANTITY),2)) DESC) AS SR
FROM
PIZZAS AS P
INNER JOIN
ORDER_DETAILS AS OD
ON P.PIZZA_ID = OD.PIZZA_ID
INNER JOIN
PIZZA_TYPES AS PT
ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
GROUP BY  PT.CATEGORY, PT.NAME
)
SELECT *
FROM
T1
WHERE SR <= 3
;

 
 
 
 
 
 
 
 