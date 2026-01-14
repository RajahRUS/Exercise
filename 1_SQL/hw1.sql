SELECT ('Егоров Р.В.');


-- 1. Загрузка данных

https://drive.google.com/file/d/16pOf_g6gZMPiepX0jWdXTJqYD5xnsPS9/view?usp=sharing

python download_google_drive/download_gdrive.py 16pOf_g6gZMPiepX0jWdXTJqYD5xnsPS9 Egorov_data.zip


rm -rf /tmp/data; unzip Egorov_data.zip -d  /tmp/data

sudo docker-compose --project-name postgres-client -f docker-compose.yml up --build -d	
sudo docker-compose --project-name postgres-client -f docker-compose.yml run --rm postgres-client
psql --host $APP_POSTGRES_HOST -U postgres

sh /home/Egorov_load_data.sh

-- 2. Листинг Egorov_load_data.sh


#/bin/sh

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.Egorov_films"

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.Egorov_persons"

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "DROP TABLE IF EXISTS public.egorov_persons2content"

echo "Download Egorov_fims.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS Egorov_films (
    id bigint,
    title varchar(255),
    country varchar(255),
    box_office float,
    release_year timestamp
 );'

psql --host $APP_POSTGRES_HOST  -U postgres -c \
    "\\copy Egorov_films FROM '/data/Egorov_films.csv' DELIMITER ',' CSV HEADER"

echo "Download Egorov_persons.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS Egorov_persons (
    id bigint,
    fio varchar(255)
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy Egorov_persons FROM '/data/Egorov_persons.csv' DELIMITER ',' CSV HEADER"


echo "Download Egorov_persons2content.csv..."
psql --host $APP_POSTGRES_HOST -U postgres -c '
  CREATE TABLE IF NOT EXISTS Egorov_persons2content (
    person_id  bigint,
    film_id  bigint,
    person_type varchar(255)
  );'

psql --host $APP_POSTGRES_HOST -U postgres -c \
    "\\copy Egorov_persons2content FROM '/data/Egorov_persons2content.csv' DELIMITER ',' CSV HEADER"



--3. Запрос из загруженных таблиц



postgres=# select * from public.egorov_films
postgres-# ;
 id |        title        | country | box_office |    release_year     
----+---------------------+---------+------------+---------------------
  1 | Вальсирующие        | Франция |    5700000 | 1974-01-01 00:00:00
  2 | Жмурки              | Россия  |    4180000 | 2005-01-01 00:00:00
  3 | Бумер               | Россия  |    1670000 | 2003-01-01 00:00:00
  4 | Магия лунного света | США     |  323339326 | 2014-01-01 00:00:00
  5 | Ла-Ла Лэнд          | США     |  446050389 | 2016-01-01 00:00:00
(5 rows)

postgres=# select * from public.egorov_persons;
 id |        fio        
----+-------------------
  1 | Бертран Блие
  2 | Жерар Депардье
  3 | Алексей Балабанов
  4 | Андрей Мерзликин
  5 | Вуди Аллен
  6 | Эмма Стоун
(6 rows)

postgres=# select * from public.egorov_persons2content;
 person_id | film_id | person_type 
-----------+---------+-------------
         1 |       1 | режиссер
         2 |       1 | актер
         3 |       2 | режиссер
         4 |       3 | актер
         5 |       4 | режиссер
         6 |       5 | актер
(6 rows)






-- 4. Создание двух таблиц из слайдов 15,17

CREATE TABLE IF NOT EXISTS form2 (
    film varchar(255),
	director varchar(255),
	oskar_flag boolean,
	IMDB_rating float
	);
	
INSERT INTO form2 VALUES ('Энни Холл', 'Вуди Аллен', 'True' , 8);

INSERT INTO form2 VALUES ('Быть Джоном Малковичем', 'Спайк Джонс', 'True' , 7);
INSERT INTO form2 VALUES ('Любовь и смерть', 'Вуди Аллен', 'False' , 8);



CREATE TABLE IF NOT EXISTS form3 (
    film varchar(255),
	oskar_flag boolean,
	location varchar(255)
	);

INSERT INTO form3 VALUES ('Энни Холл',  'True' , 'США');
INSERT INTO form3 VALUES ('Быть Джоном Малковичем', 'True' , 'США');
INSERT INTO form3 VALUES ('Любовь и смерть', 'False' , 'Россия');



-- 5. Результат

postgres=# select * from form2                                                                                      
;select * from form3;
          film          |  director   | oskar_flag | imdb_rating 
------------------------+-------------+------------+-------------
 Энни Холл              | Вуди Аллен  | t          |           8
 Быть Джоном Малковичем | Спайк Джонс | t          |           7
 Любовь и смерть        | Вуди Аллен  | f          |           8
(3 rows)
          film          | oskar_flag | location 
------------------------+------------+----------
 Энни Холл              | t          | США
 Быть Джоном Малковичем | t          | США
 Любовь и смерть        | f          | Россия
(3 rows)





