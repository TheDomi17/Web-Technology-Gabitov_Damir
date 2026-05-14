BEGIN;

-- TASK 1 & 2: Add films and actors
WITH fav_films AS (
    SELECT 'Spider-Man: No Way Home' AS title, 7 AS dur, 4.99 AS rate UNION ALL
    SELECT 'Transformers', 14, 9.99 UNION ALL
    SELECT 'Hacksaw Ridge', 21, 19.99
),
inserted_films AS (
    INSERT INTO film (title, language_id, rental_duration, rental_rate, last_update)
    SELECT ff.title, (SELECT language_id FROM language WHERE name = 'English'), ff.dur, ff.rate, CURRENT_DATE
    FROM fav_films ff
    WHERE NOT EXISTS (SELECT 1 FROM film f WHERE f.title = ff.title)
    RETURNING film_id, title
),
new_actors AS (
    SELECT 'Tom' AS fn, 'Holland' AS ln UNION ALL
    SELECT 'Zendaya', 'Coleman' UNION ALL
    SELECT 'Shia', 'LaBeouf' UNION ALL
    SELECT 'Megan', 'Fox' UNION ALL
    SELECT 'Andrew', 'Garfield' UNION ALL
    SELECT 'Sam', 'Worthington'
)
INSERT INTO actor (first_name, last_name, last_update)
SELECT na.fn, na.ln, CURRENT_DATE
FROM new_actors na
WHERE NOT EXISTS (SELECT 1 FROM actor a WHERE a.first_name = na.fn AND a.last_name = na.ln);

-- Link actors to films
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT (SELECT actor_id FROM actor WHERE first_name = 'Tom' AND last_name = 'Holland'), (SELECT film_id FROM film WHERE title = 'Spider-Man: No Way Home'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'Zendaya' AND last_name = 'Coleman'), (SELECT film_id FROM film WHERE title = 'Spider-Man: No Way Home'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'Shia' AND last_name = 'LaBeouf'), (SELECT film_id FROM film WHERE title = 'Transformers'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'Megan' AND last_name = 'Fox'), (SELECT film_id FROM film WHERE title = 'Transformers'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'Andrew' AND last_name = 'Garfield'), (SELECT film_id FROM film WHERE title = 'Hacksaw Ridge'), CURRENT_DATE UNION ALL
SELECT (SELECT actor_id FROM actor WHERE first_name = 'Sam' AND last_name = 'Worthington'), (SELECT film_id FROM film WHERE title = 'Hacksaw Ridge'), CURRENT_DATE
ON CONFLICT DO NOTHING;

-- TASK 3: Add films to inventory
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title IN ('Spider-Man: No Way Home', 'Transformers', 'Hacksaw Ridge')
  AND NOT EXISTS (SELECT 1 FROM inventory i WHERE i.film_id = f.film_id AND i.store_id = 1);

-- TASK 4: Update customer information
UPDATE customer
SET first_name = 'DAMIR',           
    last_name = 'GABITOV',         
    email = 'dgabitov@gmail.com', 
    address_id = (SELECT address_id FROM address LIMIT 1),
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
)
OR email = 'dgabitov@gmail.com';
-- TASK 5: Clean old records
-- Check and delete payments
SELECT * FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'dgabitov@gmail.com');
DELETE FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'dgabitov@gmail.com');

-- Check and delete rentals
SELECT * FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'dgabitov@gmail.com');
DELETE FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE email = 'dgabitov@gmail.com');

-- TASK 6: New rental and payment
WITH new_rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT 
        '2017-02-01 10:00:00'::timestamp,
        i.inventory_id,
        c.customer_id,
        '2017-02-01 10:00:00'::timestamp + (f.rental_duration * INTERVAL '1 day'),
        (SELECT staff_id FROM staff LIMIT 1),
        CURRENT_DATE
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    CROSS JOIN customer c
    WHERE f.title IN ('Spider-Man: No Way Home', 'Transformers', 'Hacksaw Ridge')
      AND c.email = 'dgabitov@gmail.com'
    RETURNING rental_id, customer_id, inventory_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    nr.customer_id,
    (SELECT staff_id FROM staff LIMIT 1),
    nr.rental_id,
    f.rental_rate,
    '2017-02-15 14:30:00'::timestamp
FROM new_rentals nr
JOIN inventory i ON nr.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id;

COMMIT;


--TO CHECK
--
--SELECT title, rental_rate, rental_duration 
--FROM film 
--WHERE title IN ('Spider-Man: No Way Home', 'Transformers', 'Hacksaw Ridge');
--
--
--
--SELECT c.first_name, c.last_name, f.title, p.payment_date 
--FROM customer c
--JOIN payment p ON c.customer_id = p.customer_id
--JOIN rental r ON p.rental_id = r.rental_id
--JOIN inventory i ON r.inventory_id = i.inventory_id
--JOIN film f ON i.film_id = f.film_id
--WHERE c.first_name = 'DAMIR'; 