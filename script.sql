-- If we want autoincrement, use command ALTER below instead id int PRIMARY KEY:
-- ALTER TABLE restaurant ADD COLUMN id BIGSERIAL PRIMARY KEY;
-- For create index use:
-- CREATE INDEX test1_id_index ON test1 (id);

DROP TABLE IF EXISTS restaurants CASCADE;
DROP TABLE IF EXISTS menu CASCADE;
DROP TABLE IF EXISTS chapters CASCADE;
DROP TABLE IF EXISTS dishes CASCADE;
DROP TABLE IF EXISTS menu_dish CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_dish CASCADE;


CREATE TABLE restaurants (
	id integer PRIMARY KEY,
	name varchar(64) NOT NULL,
	city varchar(128) NOT NULL,
	email varchar(128) NOT NULL
);

CREATE INDEX resaurants_name_index ON restaurants (name);
CREATE INDEX resaurants_city_index ON restaurants (city);
CREATE UNIQUE INDEX resaurants_email_index ON restaurants (email);

INSERT INTO restaurants VALUES
	(1, 'Mexico Rest', 'Mexico', 'admin@mixico.com'),
	(2, 'Ufa Rest', 'Ufa', 'admin@ufa.com'),
	(3, 'Monaco Rest', 'Monaco', 'admin@monaco.com'),
	(4, 'Pafos Rest', 'Pafos', 'admin@pafos.com');


CREATE TABLE menu (
	id integer PRIMARY KEY,
	name varchar (64) NOT NULL,
	time_create timestamptz NOT NULL,
	time_close timestamptz DEFAULT NULL,
	restaurant_id integer REFERENCES restaurants (id) ON DELETE RESTRICT
);

CREATE INDEX menu_n_idx ON menu (name);
CREATE INDEX menu_tc_idx ON menu (time_create);
CREATE INDEX menu_r_idx ON menu (restaurant_id);

INSERT INTO menu VALUES
	(1, 'Summer Menu', '2022-06-01 10:23:54', NULL, 1),
	(2, 'Winter Menu', '2022-01-01 00:23:54', NULL, 2),
	(3, 'Spring Menu', '2022-04-01 00:00:54', NULL, 2);

CREATE TABLE chapters (
	id integer PRIMARY KEY,
	name varchar (64) 
);

CREATE UNIQUE INDEX chapters_name_index ON chapters (name);

INSERT INTO chapters VALUES
	(1, 'Drinks'),
	(2, 'Main'),
	(3, 'Delishes');


CREATE TABLE dishes (
	id integer PRIMARY KEY,
	name varchar (64) NOT NULL,
	description text,
	price money DEFAULT 0,
	chapters_id integer REFERENCES chapters (id) ON DELETE RESTRICT 
);

CREATE INDEX dishes_name_idx ON dishes (name);
CREATE INDEX dishes_description_idx ON dishes USING GIN (to_tsvector('english', description));
CREATE INDEX dishes_c_idx ON dishes (chapters_id);

INSERT INTO dishes VALUES
	(1, 'Kvas', 'Water and Sugar', 20, 1),
	(2, 'Fish and Chips', 'Fish and potatos', 30, 1 ),
	(3, 'Pancake', 'Milk and egg', 12, 3),
	(4, 'Airan', 'Water and milk', 100, 1);


CREATE TABLE menu_dish (
	menu_id integer REFERENCES menu ON DELETE RESTRICT,
    dish_id integer REFERENCES dishes ON DELETE RESTRICT,
    PRIMARY KEY (menu_id, dish_id)
);

-- индексы не нужны поскольку таблица содержит составной Primary Key

INSERT INTO menu_dish VALUES
	(1, 1),
	(2, 2),
	(2, 3),
	(3, 3);


CREATE TABLE orders (
	id integer PRIMARY KEY,
	time_create timestamptz NOT NULL,
	customer varchar (128),
	table_num integer,
	status_order varchar (32),
	waiter varchar (64)
);

CREATE INDEX orders_tc_idx ON orders (time_create);
CREATE INDEX orders_so_idx ON orders (status_order);
CREATE INDEX orders_c_idx ON orders (customer);


INSERT INTO orders VALUES
	(1, '2023-01-01 10:23:54', 'Ivan', 1, 'ready', 'Kolya'),
	(2, '2023-01-01 10:23:54', 'Peter', 1, 'ready', 'Kolya'),
	(3, '2023-02-01 10:23:54', 'Fedya', 1, 'ready', 'Kolya');


CREATE TABLE order_dish (
	order_id integer REFERENCES menu ON DELETE CASCADE,
	dish_id integer REFERENCES dishes ON DELETE RESTRICT,
	quantity integer,
    PRIMARY KEY (order_id, dish_id)
);

-- индексы не нужны поскольку таблица содержит составной Primary Key

INSERT INTO order_dish VALUES
	(1, 1, 1),
	(2, 2, 5),
	(2, 3, 2),
	(3, 3, 1);

-- SELECT distinct r.name, m.name 
-- 	FROM restaurants as r, menu as m 
-- 		WHERE m.restaurant_id=r.id;

-- SELECT distinct m.name, d.name 
-- 	FROM menu_dish as md, menu as m, dishes as d 
-- 		WHERE md.menu_id=m.id AND md.dish_id=d.id

-- SELECT o.id as order_id, o.time_create, d.name as name_dish, o.waiter
-- 	FROM order_dish as od, orders as o, dishes as d
-- 		WHERE od.order_id=o.id AND od.dish_id=d.id AND o.time_create > '2023-01-01 00:00:00'

-- SELECT * 
-- 	FROM dishes
-- 		WHERE id IN (
-- 			SELECT d.id 
-- 				FROM order_dish as od, orders as o, dishes as d
-- 					WHERE od.order_id=o.id AND od.dish_id=d.id AND NOT (o.time_create > '2023-02-01 00:00:00' AND o.time_create < '2023-02-28 00:00:00')
-- 			);

SELECT id, name FROM dishes
	EXCEPT 
		SELECT d.id, d.name 
			FROM order_dish as od, orders as o, dishes as d
				WHERE od.order_id=o.id 
						AND od.dish_id=d.id 
						AND (o.time_create > '2023-02-01 00:00:00' AND o.time_create < '2023-02-28 00:00:00');