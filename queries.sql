-- 1. Данный запро считает общее количество покупателей из таблицы.

SELECT COUNT(*) AS customers_count
FROM customers;


-- 2. Данный запрос отображает топ 10 продавцов по объему выручки.
-- 2.1. Для начала создадим временную таблицу, чтобы в ней собрать необходимые для запроса колонки.

WITH t1 AS (
    SELECT
        e.first_name,
        e.last_name,
        s.sales_person_id,
        s.quantity,
        p.price
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
)

-- 2.2. Затем уже выполняем основной запрос для вычисления топ 10 продавцов.

SELECT
    first_name || ' ' || last_name AS seller,
    COUNT(sales_person_id) AS operations,
    FLOOR(SUM(quantity * price)) AS income
FROM t1
GROUP BY seller
ORDER BY income DESC
LIMIT 10;


-- 3. Данный запрос отображает продавцов с наиболее низкой выручкой за сделку (ниже показателя средней выручки за сделку среди всех продавцов).
-- 3.1. Для начала, как и в прошлом запросе, также создадим временную таблицу, чтобы посчитать среднюю выручку за сделку у каждого продавца.

WITH t1 AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        FLOOR(AVG(s.quantity * p.price)) AS average_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        seller
)

-- 3.2. Затем, используя получившуюся временную таблицу и применяя подзапрос,определим наименее успешных продавцов (у каких продавцов средняя выручка за сделку ниже средней выручки за сделку среди всех продавцов).

SELECT *
FROM t1
WHERE
    average_income < (
        SELECT AVG(s.quantity * p.price) AS ovr_avg_income
        FROM sales AS s
        INNER JOIN products AS p
            ON s.product_id = p.product_id
    )
ORDER BY average_income ASC;
-- 4. Данный запрос отображает информацию о выручке каждого продавца в разбивке по дням недели.

WITH t1 AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        TO_CHAR(s.sale_date, 'day') AS day_of_week,
        TO_CHAR(s.sale_date, 'ID') AS number_of_day,
        FLOOR(SUM(s.quantity * p.price)) AS income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        day_of_week,
        number_of_day,
        seller
    ORDER BY
        number_of_day ASC,
        seller ASC
)

SELECT
    seller,
    day_of_week,
    income
FROM t1;


-- 5. Данный запрос позволяет отобразить покупателей в разрезе 3-х заданных возрастных категорий.

SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(age) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category ASC;


-- 6. Данный запрос отображает количество уникальных покупателей в каждом месяце и выручку, которую они принесли.

SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    selling_month
ORDER BY selling_month ASC;


-- 7. Данный запрос позволяет отобразить клиентов, которые первую свою покупку совершили в ходе проведения акции.
-- 7.1. Для начала с помощью временной таблицы и подзапроса найдем все сделки, в которых были товары по акции.

WITH t1 AS (
    SELECT
        s.customer_id,
        s.sale_date,
        p.product_id,
        p.price,
        s.sales_person_id,
        c.first_name || ' ' || c.last_name AS customer,
        e.first_name || ' ' || e.last_name AS seller
    FROM sales AS s
    INNER JOIN customers AS c
        ON s.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    WHERE
        p.product_id IN (
            SELECT product_id
            FROM products
            WHERE price = 0
        )
    ORDER BY s.sale_date ASC
),

-- 7.2. Затем с помощью еще одной временной таблицы определим очередность сделок всех покупателей из таблицы t1. 
t2 AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY sale_date) AS rn
    FROM t1
)

-- 7.3. И теперь с помощью основного запроса выведем именно тех покупателей (и продавцов, участвоваших в сделке), в первой сделке которых были товары по акции.
SELECT
    customer,
    sale_date,
    seller
FROM t2
WHERE rn = 1
ORDER BY customer_id ASC;
