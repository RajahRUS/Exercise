#/bin/sh

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.t_account"

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.t_client"

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.t_department"

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.t_balance"	
	
	
	
echo "Download t_department.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS t_department (
    department_id bigint PRIMARY KEY,
    department_name varchar(255)
 );'

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "\\copy t_department FROM '/data/t_department.csv' DELIMITER ',' CSV HEADER"

echo "Download t_client.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS t_client (
    client_id bigint PRIMARY KEY,
    client_name varchar(255)
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy t_client FROM '/data/t_client.csv' DELIMITER ',' CSV HEADER"


echo "Download t_balance.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS t_balance (
    report_date  date,
    account_id  bigint REFERENCES t_balance(account_id),
    acc_value FLOAT
	
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy t_balance FROM '/data/t_balance.csv' DELIMITER ',' CSV HEADER"

	
echo "Download t_account.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS t_account (
    account_id  bigint PRIMARY KEY,
	account_number,
	account_name,
	client_id REFERENCES t_client(client_id),
	departmen_id REFERENCES t_department(department_id)
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy t_account FROM '/data/t_account.csv' DELIMITER ',' CSV HEADER"