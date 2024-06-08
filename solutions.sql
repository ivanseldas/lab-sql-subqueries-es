/*
1. ¿Cuántas copias de la película El Jorobado Imposible existen en el sistema de inventario?
2. Lista todas las películas cuya duración sea mayor que el promedio de todas las películas.
3. Usa subconsultas para mostrar todos los actores que aparecen en la película Viaje Solo.
4. Las ventas han estado disminuyendo entre las familias jóvenes, y deseas dirigir todas las películas familiares a una promoción. Identifica todas las películas categorizadas como películas familiares.
5. Obtén el nombre y correo electrónico de los clientes de Canadá usando subconsultas. Haz lo mismo con uniones. Ten en cuenta que para crear una unión, tendrás que identificar las tablas correctas con sus claves primarias y claves foráneas, que te ayudarán a obtener la información relevante.
6. ¿Cuáles son las películas protagonizadas por el actor más prolífico? El actor más prolífico se define como el actor que ha actuado en el mayor número de películas. Primero tendrás que encontrar al actor más prolífico y luego usar ese actor_id para encontrar las diferentes películas en las que ha protagonizado.
7. Películas alquiladas por el cliente más rentable. Puedes usar la tabla de clientes y la tabla de pagos para encontrar al cliente más rentable, es decir, el cliente que ha realizado la mayor suma de pagos.
8. Obtén el client_id y el total_amount_spent de esos clientes que gastaron más que el promedio del total_amount gastado por cada cliente.
*/

-- QUERY 1: ¿Cuántas copias de la película El Jorobado Imposible existen en el sistema de inventario?
SELECT 
	f.title AS title,
    COUNT(i.inventory_id) AS copies
FROM inventory i
INNER JOIN film f ON f.film_id = i.film_id 
WHERE title like '%hunchback%' AND title like '%impossible%'
GROUP BY title;

-- QUERY 2: Lista todas las películas cuya duración sea mayor que el promedio de todas las películas.
WITH FilmLengthAvg AS (
	SELECT
		AVG(length) AS avglength
	FROM film
)
SELECT DISTINCT
	f.film_id,
    f.title,
    f.length,
    favg.avglength
FROM film f, FilmLengthAvg favg
WHERE f.length > favg.avglength;

-- QUERY 3: Usa subconsultas para mostrar todos los actores que aparecen en la película Viaje Solo.
SELECT actor_id, first_name, last_name FROM actor
WHERE actor_id IN 
	(SELECT DISTINCT actor_id
    FROM film_actor
	WHERE film_id IN 
		(SELECT DISTINCT film_id
        FROM film
        WHERE title = 'ALONE TRIP'));

-- QUERY 4: Identifica todas las películas categorizadas como películas familiares.
SELECT title FROM film
WHERE film_id IN
	(SELECT film_id
    FROM film_category
    WHERE category_id IN 
		(SELECT category_id
        FROM category
        WHERE name = 'Family'));

-- QUERY 5: Obtén el nombre y correo electrónico de los clientes de Canadá.
SELECT first_name, last_name, email FROM customer 
WHERE address_id IN 
	(SELECT address_id FROM address 
    WHERE city_id IN 
		(SELECT city_id FROM city 
        WHERE country_id in
			(SELECT country_id FROM country 
            WHERE country = 'Canada')));

-- QUERY 6: ¿Cuáles son las películas protagonizadas por el actor más prolífico (ha participado en mayor número de películas)?
WITH ProlificActor AS (
	SELECT
		actor_id,
		COUNT(film_id) AS total_films
	FROM film_actor	
	GROUP BY actor_id
	ORDER BY total_films DESC
	LIMIT 1
)
SELECT title FROM film
WHERE film_id IN 
	(SELECT film_id FROM film_actor
    WHERE actor_id IN 
		(SELECT actor_id FROM ProlificActor));

-- QUERY 7: Películas alquiladas por el cliente más rentable.
WITH BestClient AS (
	SELECT
		customer_id,
		SUM(amount) AS SumAmount
	FROM payment
	GROUP BY customer_id
	ORDER BY SumAmount DESC
	LIMIT 1
)
SELECT title FROM film
WHERE film_id IN 
	(SELECT film_id FROM inventory
    WHERE inventory_id IN
		(SELECT inventory_id FROM rental
        WHERE customer_id IN 
			(SELECT customer_id FROM BestClient)));

-- QUERY 8: Obtén el client_id y el total_amount_spent de esos clientes que gastaron 
-- más que el promedio del total_amount gastado por cada cliente.
WITH 
	ClientExpenses AS (
		SELECT 
			customer_id,
			SUM(amount) AS SumAmount
		FROM payment
		GROUP BY customer_id
		ORDER BY SumAmount DESC
		),
	AvgAmount AS (
		SELECT
		AVG(SumAmount) AS AmountSpentAvg
		FROM ClientExpenses
        )
SELECT 
	ce.customer_id AS client_id,
	ce.SumAmount AS total_amount
FROM ClientExpenses ce
WHERE ce.SumAmount > (SELECT aa.AmountSpentAvg FROM AvgAmount aa);
