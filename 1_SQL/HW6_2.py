
# coding: utf-8

# In[26]:


import os
import logging

import psycopg2
import psycopg2.extensions
from pymongo import MongoClient
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy import Table, Column, Integer, Float, MetaData, String
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from subprocess import call


logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

call("bash load_data.sh", shell=True)


# In[27]:



logger.info("Создаём подключёние к Postgres")
params = {
    "host": 'postgres_host',
    "port": '5432',
    "user": 'postgres'
}
conn = psycopg2.connect(**params)

# дополнительные настройки
psycopg2.extensions.register_type(
    psycopg2.extensions.UNICODE,
    conn
)
conn.set_isolation_level(
    psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT
)
cursor = conn.cursor()


# In[28]:



# ВАШ КОД ЗДЕСЬ
# -------------
# таблица movies_top
# movieId (id фильма), ratings_num(число рейтингов), ratings_avg (средний рейтинг фильма)

# "SELECT movieId, ratings_num, rating_avg INTO movies_top"
#drop table movies_top;
sql_str = """
SELECT movieid , count(rating) ratings_num, avg(rating) rating_avg
INTO movies_top
from public.ratings 
group by movieid; 
"""
# -------------

cursor.execute(sql_str)
conn.commit()

sql_str = ""


# In[29]:


# Проверка - выгружаем данные

sql_str = "select  movieid , ratings_num, rating_avg from movies_top where rating_avg >3 limit 10;"


cursor.execute(sql_str)
logger.info(
    "Выгружаем данные из таблицы movies_top: (movieId, ratings_num, ratings_avg)\n{}".format(
        [i for i in cursor.fetchall()])
)


# In[30]:



# Задание по SQLAlchemy
# --------------------------------------------------------------
Base = declarative_base()


class MoviesTop(Base):
    __tablename__ = 'movies_top'

    movieid = Column(Integer, primary_key=True)
    ratings_num = Column(Integer)
    rating_avg = Column(Float)

    def __repr__(self):
        return "<User(movieid='%s', ratings_num='%s', rating_avg='%s')>" % (self.movieid, self.ratings_num, self.rating_avg)


# In[31]:


# Создаём сессию

engine = create_engine('postgresql://postgres:@{}:{}'.format('postgres_host', '5432'))
Session = sessionmaker(bind=engine)
session = Session()


# In[32]:


# --------------------------------------------------------------
# Ваш код здесь
# выберите контент у которого больше 15 оценок (используйте filter)
# и средний рейтинг больше 3.5 (filter ещё раз)
# отсортированный по среднему рейтингу (используйте order_by())
# id такого контента нужно сохранить в массив top_rated_content_ids


top_rated_query = session.query(MoviesTop).filter("rating_avg > 3.5").filter("ratings_num > 15")

logger.info("Выборка из top_rated_query\n{}".format([i for i in top_rated_query.limit(4)]))

top_rated_content_ids = [
    i[0] for i in top_rated_query.values(MoviesTop.movieid)
][:5]
# --------------------------------------------------------------


# In[34]:


# Задание по PyMongo

#call("bash mongoimport --host $APP_MONGO_HOST --port $APP_MONGO_PORT --db movies --collection tags --file simple_tags.json", shell=True)

mongo = MongoClient('mongo_host',27017) #
mongo.server_info() # Forces a call.

#call("bash load_json.sh", shell=True)
call("""bash "mongoimport --host $APP_MONGO_HOST --port $APP_MONGO_PORT --db movies --collection tags --file work/simple_tags.json""", shell=True) 
# Получите доступ к коллекции tags
db = mongo["movie"]
tags_collection = db['tags']
#db.stats()
db.command("dbstats")


# In[47]:


# id контента используйте для фильтрации - передайте его в модификатор $in внутри find
# в выборку должны попать теги фильмов из массива top_rated_content_ids

top_rated_content_ids = tags_collection.find().limit(3)

top_rated_content_ids_docs = [
    i for i in top_rated_content_ids
]

print("Достали документы из Mongo: {}".format(top_rated_content_ids_docs[:5]))
id_tags = [(i['id'], i['name']) for i in top_rated_content_ids_docs]


mongo_query = tags_collection.find( 
{'id': {}}
)

mongo_docs = [
    i for i in mongo_query
]

print("Достали документы из Mongo: {}".format(mongo_docs[:5]))

id_tags = [(i['id'], i['name']) for i in mongo_docs]



# In[49]:


id_tags


# In[ ]:



# Задание по Pandas
# --------------------------------------------------------------
# Постройте таблицу их тегов и определите top-5 самых популярных

# формируем DataFrame
tags_df = pd.DataFrame(id_tags, columns=['movieid', 'tags'])

# --------------------------------------------------------------
# Ваш код здесь
# сгруппируйте по названию тега с помощью group_by
# для каждого тега вычислите, в каком количестве фильмов он встречается
# оставьте top-5 самых популярных тегов

top_5_tags = tags_df.head(5)

print(top_5_tags)

logger.info("Домашка выполнена!")
# --------------------------------------------------------------


# In[22]:


files = os.listdir(os.curdir)


# In[24]:


files

