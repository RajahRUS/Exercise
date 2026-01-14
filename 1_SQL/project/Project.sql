--Project

sudo cp * /tmp/data

-- Создание таблиц

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
    account_id  bigint REFERENCES t_account(account_id),
    acc_value FLOAT
	
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy t_balance FROM '/data/t_balance.csv' DELIMITER ',' CSV HEADER"

	
echo "Download t_account.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS t_account (
    account_id  bigint PRIMARY KEY,
	account_number varchar(255),
	account_name varchar(255),
	client_id bigint REFERENCES t_client(client_id),
	department_id bigint REFERENCES t_department(department_id)
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy t_account FROM '/data/t_account.csv' DELIMITER ',' CSV HEADER"
	
	
	
	
-- SQL запросы 

--1.

select * from 
public.t_balance b inner join public.t_account a on b.account_id = a.account_id ;

--2. 
	
select * from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id ;

--3. 


select * from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id;

--4. Средств у клиента

select c.client_name, sum(b.acc_value) sums from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id
group by c.client_name
order by 2
;


--5. количество счетов у клиента

select c.client_name, count(b.acc_value) acc_count from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id
group by c.client_name
order by 2
;


--6. количество счетов у клиента у которого больше всех средств

select distinct  c.client_name  
from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id
where c.client_id = ( select client_id from (
select a.client_id, sum(b.acc_value) sums
from public.t_balance b 
inner join	 public.t_account a on b.account_id = a.account_id
group by a.client_id
order by 2 desc
limit 1
) aa
)
;


--7. количество счетов у клиента у которого больше всех средств

select c.client_name, count(b.acc_value) acc_count 
from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id
where c.client_id = ( select client_id from (
select a.client_id, sum(b.acc_value) sums
from public.t_balance b 
inner join	 public.t_account a on b.account_id = a.account_id
group by a.client_id
order by 2 desc
limit 1
) aa
)
group by c.client_name
order by 2
;

--8. Тоже самое тольк с конструкцией with 

with AA as 
( 
select a.client_id, sum(b.acc_value) sums
from public.t_balance b 
inner join	 public.t_account a on b.account_id = a.account_id
group by a.client_id
order by 2 desc
limit 1
) 
select c.client_name, count(b.acc_value) acc_count 
from public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id
inner join AA on c.client_id = AA.client_id
group by c.client_name
order by 2
;


--9 Ранжирование клиентов по положительному остатку

select AA.client_name, AA.sums , AA.counts, rank() over (order by AA.sums desc) rate  
from (
select   c.client_name, sum(b.acc_value) sums, count(distinct a.account_id)   counts
from public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id
group by c.client_name
having sum(b.acc_value) > 0
order by 2 desc
) AA;


-- 10 Создание общей view .
create or replace view v_accounts
as 
select a.account_number, a.account_name, c.client_name, b.report_date, b.acc_value, d.department_name 
from 
public.t_balance b inner join 
public.t_account a on b.account_id = a.account_id
inner join 	public.t_client c on a.client_id = c.client_id 
inner join 	public.t_department d on d.department_id = a.department_id;


-- select из view