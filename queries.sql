-- 1. Данный запрос отображает топ 10 продавцов по объему выручки.
-- 1.1. Для начала создадим временную таблицу, чтобы в ней собрать необходимые для запроса колонки.

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

-- 1.2. Затем уже выполняем основной запрос для вычисления топ 10 продавцов.

SELECT
    first_name || ' ' || last_name AS seller,
    COUNT(sales_person_id) AS operations,
    FLOOR(SUM(quantity * price)) AS income
FROM t1
GROUP BY seller
ORDER BY income DESC
LIMIT 10;


-- 2. Данный запрос отображает продавцов с наиболее низкой выручкой за сделку (ниже показателя средней выручки за сделку среди всех продавцов).
-- 2.1. Для начала, как и в прошлом запросе, также создадим временную таблицу, чтобы посчитать среднюю выручку за сделку у каждого продавца.

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

-- 2.2. Затем, используя получившуюся временную таблицу и применяя подзапрос,определим наименее успешных продавцов (у каких продавцов средняя выручка за сделку ниже средней выручки за сделку среди всех продавцов).

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


-- 3. Данный запрос отображает информацию о выручке каждого продавца в разбивке по дням недели.

SELECT
    e.first_name || ' ' || e.last_name AS seller,
    TO_CHAR(s.sale_date, 'day') AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    sale_date,
    seller
ORDER BY
    sale_date ASC,
    seller ASC;
