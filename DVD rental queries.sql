/*Who are the Most Popular Actors Based on Number of Movie Rentals?*/
WITH categorized_by_family AS (
	SELECT category_id c_id, name,
	CASE WHEN name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') THEN 'Family_Film' ELSE 'Other' END AS simplified_category
	FROM category),

quartile AS (
	SELECT title, name, rental_duration,
	NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
	FROM film
	JOIN film_category fc
	ON film.film_id = fc.film_id
	JOIN categorized_by_family cbf
	ON cbf.c_id = fc.category_id
	WHERE simplified_category = 'Family_Film')

SELECT name, standard_quartile AS duration_quartile, COUNT(*)
FROM quartile
GROUP BY 1, 2
ORDER BY 2;

/*Which Category Performs Better Month-Over-Month?*/
WITH categorized_by_family AS (
		SELECT category_id AS c_id, name,
		CASE WHEN name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') THEN 'Family_Film' ELSE 'Other' END AS simplified_category
		FROM category),

	join_table AS (
		SELECT c.category_id AS c_id, rental_date, rental_id
		FROM film
		JOIN film_category fc
		ON film.film_id = fc.film_id
		JOIN category c
		ON c.category_id = fc.category_id
		JOIN inventory i
		ON i.film_id = film.film_id
		JOIN rental r
		ON r.inventory_id = i.inventory_id)

SELECT simplified_category,
DATE_TRUNC('month', rental_date) AS month_time,
COUNT(rental_id) total_rentals,
RANK() OVER (PARTITION BY simplified_category ORDER BY DATE_TRUNC('month', rental_date)) AS month_order
FROM join_table jt
JOIN categorized_by_family cbf
ON cbf.c_id = jt.c_id
GROUP BY 1, 2
ORDER BY 1, 4;

/*What are the Month-by-Month Spending Changes of the Top 10 Movie Renters?*/
WITH question2_tbl AS (
	SELECT DATE_TRUNC('month', payment_date) AS pay_mon,
	full_name,
	COUNT(*) pay_countpermon,
	SUM(amount) pay_amount
	FROM payment p
	JOIN(
		SELECT c.customer_id c_id, CONCAT(first_name, ' ', last_name) AS full_name,
		SUM(amount) total_spend
		FROM customer c
		JOIN payment p
		ON c.customer_id = p.customer_id
		GROUP BY 1, 2
		ORDER BY 3 DESC
		LIMIT 10) inner_table
	ON p.customer_id = inner_table.c_id
	GROUP BY 1, 2
	ORDER BY 2)

SELECT full_name, pay_mon, pay_amount,
COALESCE((LAG(pay_amount) OVER pay_window), 0) AS previous_month_payment,
COALESCE((pay_amount - LAG(pay_amount) OVER pay_window), 0) AS difference
FROM question2_tbl
WINDOW pay_window AS (PARTITION BY full_name ORDER BY pay_mon)

/*Who are the Most Popular Actors Based on Number of Movie Rentals?*/
WITH actor_movies AS (
		SELECT title, first_name||' '||last_name AS actor_name
		FROM actor a
		JOIN film_actor fa
		ON a.actor_id = fa.actor_id
		JOIN film f
		ON fa.film_id = f.film_id),

	title_rent_count AS (
		SELECT title, COUNT(r.*) rental_count
		FROM inventory i
		JOIN rental r
		ON i.inventory_id = r.inventory_id
		JOIN film f
		ON f.film_id = i.film_id
		GROUP BY 1
		ORDER BY 2 DESC)

SELECT DISTINCT actor_name,
SUM(rental_count) OVER (PARTITION BY actor_name) AS actor_rent_count
FROM title_rent_count trc
JOIN actor_movies am
ON trc.title = am.title
ORDER BY 2 DESC
LIMIT 5;

/*MY Question 4 (using Group BY)*/
WITH actor_movies AS (
		SELECT title, first_name||' '||last_name AS actor_name
		FROM actor a
		JOIN film_actor fa
		ON a.actor_id = fa.actor_id
		JOIN film f
		ON fa.film_id = f.film_id),

	title_rent_count AS (
		SELECT title, COUNT(r.*) rental_count
		FROM inventory i
		JOIN rental r
		ON i.inventory_id = r.inventory_id
		JOIN film f
		ON f.film_id = i.film_id
		GROUP BY 1
		ORDER BY 2 DESC)

SELECT DISTINCT actor_name,
SUM(rental_count) AS actor_rent_count
FROM title_rent_count trc
JOIN actor_movies am
ON trc.title = am.title
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;
