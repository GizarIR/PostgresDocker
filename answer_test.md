Задание:
Представьте, что вы участвуете в разработке бэкенда данного сервиса.
Ваша задача - спроектировать структуру базы данных для хранения информации о меню - разделах меню и 
блюдах в этих разделах - и заказах блюд.
1. Пришлите описание используемых таблиц, включая информацию о названиях и формате полей.
2. Предложите индексы для каждой из таблиц, которые помогут быстрее выдавать информацию по идентификатору ресторана.
3. Напишите SQL-запрос, который выведет все блюда, для которых не было ни одного заказа за текущий месяц.

Ответ:
1) Подготовка ответа осуществлялась в среде PostsreSQL 14.5. Скрипт полностью работоспособен. Для подготовки и проверки 
   ответа был развернут стенд с использованием Docker Compose и созданием контеqнеров для Postgres DB и pgadmin. 
   Результаты работы размещены в репозитории по адресу: https://github.com/GizarIR/PostgresDocker
2) Наличие некоторых индексов в таблице может быть избыточным для разных типов запросов.
   Но поскольку в задании было указано предложить индексы для каждой таблицы, то в скрипте были внесены индексы 
   или информация для каждой таблицы.   
4) Исходя из описания задачи выделяем сущности для организации таблиц: Ресторан, Меню, Раздел, Блюдо, Заказ. 
   Структура базы данных представлена в виде диаграммы в репозитории в файле structure_db.png
5) Для таблиц с отношением "Многие Ко Многим" создадим дополнительные таблицы: Меню-Блюда и Заказ-Блюдо  

SELECT version(); -- версия PostsreSQL 14.5

--Удалаяем ранее созданные таблицы
DROP TABLE IF EXISTS restaurants CASCADE;
DROP TABLE IF EXISTS menu CASCADE;
DROP TABLE IF EXISTS chapters CASCADE;
DROP TABLE IF EXISTS dishes CASCADE;
DROP TABLE IF EXISTS menu_dish CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_dish CASCADE;

--Создаем таблицу с описанием Ресторанов
CREATE TABLE restaurants (
	id integer PRIMARY KEY,
	name varchar(64) NOT NULL,
	city varchar(128) NOT NULL,
	email varchar(128) NOT NULL
);

--Добавляем индексы для таблицы Рестораны
CREATE INDEX resaurants_name_index ON restaurants (name);
CREATE INDEX resaurants_city_index ON restaurants (city);
CREATE UNIQUE INDEX resaurants_email_index ON restaurants (email); -должен быть уникальным, по нему можно делать авторизацию

--Добавляем тестовые данные для таблицы Рестораны
INSERT INTO restaurants VALUES
	(1, 'Mexico Rest', 'Mexico', 'admin@mixico.com'),
	(2, 'Ufa Rest', 'Ufa', 'admin@ufa.com'),
	(3, 'Monaco Rest', 'Monaco', 'admin@monaco.com'),
	(4, 'Pafos Rest', 'Pafos', 'admin@pafos.com');


--Создаем таблицу с описанием Меню
--Таблица имеет внешний ключ к таблице Рестораны
CREATE TABLE menu (
	id integer PRIMARY KEY,
	name varchar (64) NOT NULL,
	time_create timestamptz NOT NULL, --дата и время с учетом тайм зоны , так как рестораны могут быть по всему миру
	time_close timestamptz DEFAULT NULL,
	restaurant_id integer REFERENCES restaurants (id) ON DELETE RESTRICT --удалить Ресторан который есть в Меню не получится
);

--Добавляем индексы в таблицу с Меню
CREATE INDEX menu_n_idx ON menu (name);
CREATE INDEX menu_tc_idx ON menu (time_create);
CREATE INDEX menu_r_idx ON menu (restaurant_id);

--Добавляем тестовые данные в таблицу Меню
INSERT INTO menu VALUES
	(1, 'Summer Menu', '2022-06-01 10:23:54', NULL, 1),
	(2, 'Winter Menu', '2022-01-01 00:23:54', NULL, 2),
	(3, 'Spring Menu', '2022-04-01 00:00:54', NULL, 2);


--Создаем таблицу с описанием Разделов меню Индекс и Тестовые данные
CREATE TABLE chapters (
	id integer PRIMARY KEY,
	name varchar (64) 
);

CREATE UNIQUE INDEX chapters_name_index ON chapters (name);

INSERT INTO chapters VALUES
	(1, 'Drinks'),
	(2, 'Main'),
	(3, 'Delishes');


--Создаем таблицу с описанием Блюд, Индексы и Тестовый данные
CREATE TABLE dishes (
	id integer PRIMARY KEY,
	name varchar (64) NOT NULL,
	description text,
	price money DEFAULT 0,
	chapters_id integer REFERENCES chapters (id) ON DELETE RESTRICT 
);

CREATE INDEX dishes_name_idx ON dishes (name);
CREATE INDEX dishes_description_idx ON dishes USING GIN (to_tsvector('english', description)); -- индекс для полнотекстового поиска по описанию блюда
CREATE INDEX dishes_c_idx ON dishes (chapters_id);

INSERT INTO dishes VALUES
	(1, 'Kvas', 'Water and Sugar', 20, 1),
	(2, 'Fish and Chips', 'Fish and potatos', 30, 1 ),
	(3, 'Pancake', 'Milk and egg', 12, 3),
	(4, 'Airan', 'Water and milk', 100, 1);


--Создаем таблицу вспомогательную для отношения М2М Меню-Блюдо и Тестовые данные
CREATE TABLE menu_dish (
	menu_id integer REFERENCES menu ON DELETE RESTRICT,
    dish_id integer REFERENCES dishes ON DELETE RESTRICT,
    PRIMARY KEY (menu_id, dish_id)
);

-- индексы не нужны поскольку таблица содержит составной Primary Key
-- который автоматически создает индекс

INSERT INTO menu_dish VALUES
	(1, 1),
	(2, 2),
	(2, 3),
	(3, 3);


--Создаем таблицу с описанием Заказов, Индексы и Тестовые данные
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


--Создаем таблицу вспомогательную для отношени М2М Заказ-Блюдо, Тестовые данные
CREATE TABLE order_dish (
	order_id integer REFERENCES order ON DELETE CASCADE, --при удалении заказа удалиться и его содержимое
	dish_id integer REFERENCES dishes ON DELETE RESTRICT, --удалить продукты которые участвуют в заказах не получится
	quantity integer,
    PRIMARY KEY (order_id, dish_id)
);

-- индексы не нужны поскольку таблица содержит составной Primary Key,
-- который индексируется автоматически

INSERT INTO order_dish VALUES
	(1, 1, 1),
	(2, 2, 5),
	(2, 3, 2),
	(3, 3, 1);


-- Делаем выборку данных из модели в соответсвии с заданием пункт 3. Используем исключение при работе со множествами.
SELECT id, name FROM dishes
	EXCEPT 
		SELECT d.id, d.name 
			FROM order_dish as od, orders as o, dishes as d
				WHERE od.order_id=o.id 
						AND od.dish_id=d.id 
						AND (o.time_create > '2023-02-01 00:00:00' AND o.time_create < '2023-02-28 00:00:00');


-- Результат выборки, блюда по которым небло заказов в феврале 2023:
-- 2	"Fish and Chips"
-- 1	"Kvas"
-- 4	"Airan"

--Делаем проверку, смотрим что было в заказе номер 3 
SELECT o.id, d.name FROM orders as o, dishes as d, order_dish as od
	WHERE od.order_id=o.id AND od.dish_id=d.id AND o.id = 3

-- Проверка: Заказ номер 3 содержал Pancake и был сделан в феврале 2023