CREATE TABLE users (
	id integer PRIMARY KEY,
	name varchar(32),
	email varchar(100)
);

INSERT INTO users VALUES
	(1, 'admin', 'admin@example.ru');
	 
SELECT * FROM users;