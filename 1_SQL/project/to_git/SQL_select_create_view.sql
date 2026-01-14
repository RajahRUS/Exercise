#/bin/sh

-- SQL запросы 

/*
echo "Download t_department.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c \
*/


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


-- 11. Создание второй view по клиенту с набольшим количеством средств

create or replace view v_accounts_max_sum_client
as 
select v.client_name, max(v.acc_value)
from v_accounts v
group by v.client_name
order by 2 desc
limit 1;

-- 12. Select из view - 10 SQL запрос

select client_name from v_accounts_max_sum_client;