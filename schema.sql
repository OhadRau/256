CREATE TABLE members (
  user_id INTEGER PRIMARY KEY,
  first_name STRING NOT NULL
);

CREATE TABLE offers (
  user_id INTEGER UNIQUE,
  price INTEGER,
  FOREIGN KEY (user_id) REFERENCES members(user_id)
);
