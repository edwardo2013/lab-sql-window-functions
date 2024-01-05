/*
Rank films by their length and create an output table that includes the title,
 length, and rank columns only. 
Filter out any rows with null or zero values in the length column.
*/
SELECT 
title,
length,
RANK() OVER(ORDER BY length DESC) as simple_rank,
DENSE_RANK() OVER(ORDER BY length DESC) as dense_rank_column,
ROW_NUMBER() OVER(ORDER BY length DESC) as row_number_rank
FROM 
film
WHERE length IS NOT NULL;

/*Rank films by length within the rating category and 
create an output table that includes the title, length, rating and rank columns only.
 Filter out any rows with null or zero values in the length column.*/
SELECT 
title,
length,
rating,
RANK() OVER(PARTITION BY rating ORDER BY length DESC),
RANK() OVER(ORDER BY rating,length DESC),
DENSE_RANK() OVER(PARTITION BY rating ORDER BY length DESC),
ROW_NUMBER() OVER(PARTITION BY rating ORDER BY length DESC)
FROM 
film
WHERE length IS NOT NULL; 
/*
Produce a list that shows for each film in the Sakila database,
 the actor or actress who has acted in the greatest number of films,
 as well as the total number of films in which they have acted. 
 Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries
*/
with movies_by_actor AS
(SELECT 
actor.actor_id,actor.first_name,actor.last_name
,COUNT(*) AS number_of_movies
FROM
film_actor
JOIN actor ON film_actor.actor_id = actor.actor_id
GROUP BY actor.actor_id,actor.first_name,actor.last_name),
max_movies AS
(SELECT film_actor.film_id,MAX(number_of_movies) maximum_movies
from film_actor 
JOIN movies_by_actor ON film_actor.actor_id=movies_by_actor.actor_id
GROUP BY film_actor.film_id)

SELECT title,
CONCAT(first_name,' ',last_name),
number_of_movies
FROM film
JOIN max_movies ON film.film_id= max_movies.film_id
JOIN film_actor ON film.film_id= film_actor.film_id
JOIN movies_by_actor ON film_actor.actor_id=movies_by_actor.actor_id
WHERE maximum_movies=number_of_movies
ORDER BY title
;

with movies_by_actor AS
(SELECT 
actor.actor_id,actor.first_name,actor.last_name
,COUNT(*) AS number_of_movies
FROM
film_actor
JOIN actor ON film_actor.actor_id = actor.actor_id
GROUP BY actor.actor_id,actor.first_name,actor.last_name),
max_movies AS
(SELECT 
title,
CONCAT(first_name,' ',last_name),
number_of_movies,
MAX(number_of_movies) OVER(PARTITION BY film.film_id) AS maximum_movies
FROM movies_by_actor 
JOIN film_actor ON movies_by_actor.actor_id= film_actor.actor_id
JOIN film ON film.film_id=film_actor.film_id)

SELECT * 
FROM max_movies
WHERE number_of_movies=maximum_movies
;

/*
Step 1. Retrieve the number of monthly active customers, i.e.,
 the number of unique customers who rented a movie in each month.
 
 Step 2. Retrieve the number of active users in the previous month.
 Step 3. Calculate the percentage change in the number of active customers between
 the current and previous month.
 
Step 4. Calculate the number of retained customers every month, i.e., 
customers who rented movies in the current and previous months.
*/
WITH step1 AS
(SELECT 
month(rental_date) as rental_month,
year(rental_date) rental_year,
COUNT( DISTINCT customer_id) number_of_clients 
FROM rental
GROUP BY month(rental_date),
year(rental_date)
ORDER BY year(rental_date), month(rental_date))
,step2 AS
(SELECT *,
LAG(number_of_clients,1) OVER() previous_month 
FROM step1),
step3 AS
(SELECT 
*,
((number_of_clients-previous_month)/number_of_clients)*100 AS percentage_change
FROM step2)
,step4 AS
(SELECT 
*,
CASE WHEN number_of_clients >= previous_month 
	THEN previous_month 
    ELSE number_of_clients
    END
FROM 
step3)
SELECT
*
FROM step4 
;

WITH month_id AS
(SELECT DISTINCT
month(rental_date) as rental_month,
year(rental_date) rental_year,
customer_id
FROM rental
ORDER BY year(rental_date), month(rental_date))

SELECT 
*
FROM month_id as t1
JOIN month_id as t2 ON t1.customer_id =t2.customer_id AND  t1.rental_month!=t2.rental_month
;

