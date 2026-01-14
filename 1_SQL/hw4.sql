
SELECT ('Егоров Р.В.');

-- 1

SELECT t.table_name, pg_size_pretty(pg_total_relation_size(t.table_name))
FROM information_schema.tables t
where table_schema NOT IN ('information_schema','pg_catalog')
order  by 2 desc
limit 5;
	
	
--2 

SELECT userID, array_agg(movieId) as user_views 
FROM ratings 
WHERE userID=1 
group by userID;	


SELECT userID, array_agg(movieId) as user_views 
INTO public.user_movies_agg 
FROM ratings 
--WHERE userID=1 
group by userID;	



CREATE OR REPLACE FUNCTION cross_arr (bigint[], bigint[]) RETURNS bigint[] 
language sql as $FUNCTION$ 
 SELECT ARRAY(
        SELECT UNNEST($1)
        INTERSECT
        SELECT UNNEST($2)
    );
; 
$FUNCTION$;

CREATE OR REPLACE FUNCTION diff_arr (bigint[], bigint[]) RETURNS bigint[] 
language sql as $FUNCTION$ 
 SELECT ARRAY(
        SELECT UNNEST($1)
        EXCEPT 
        SELECT UNNEST($2)
    );
; 
$FUNCTION$;


CREATE OR REPLACE FUNCTION agg_arr (bigint[], bigint[]) RETURNS bigint[] 
language sql as $FUNCTION$ 
 SELECT ARRAY(
        SELECT UNNEST($1)
        union  
        SELECT UNNEST($2)
    );
; 
$FUNCTION$;



-- function test
select cross_arr(array[1,2],array[1,2,3]);
select diff_arr(array[1,2,5],array[1,2,3]);
select count(*) from unnest(cross_arr(array[1,2],array[1,2,3])) ;
select count(*) from unnest(diff_arr(array[1,2],array[1,2])) ;


-- Таблица пересечений и реккомендаций
select 
t1.userID userID_1, 
t2.userID userID_2, 
t1.user_views user_views_1, 
t2.user_views user_views_2, 
(select count(*) from UNNEST(t1.user_views)) cnt_1,
(select count(*) from UNNEST(t2.user_views)) cnt_2,
cross_arr(t1.user_views,t2.user_views) as intersect_views,
(select count(*) from UNNEST(cross_arr(t1.user_views,t2.user_views))) as intersect_count,
(select count(*) from UNNEST(diff_arr(t2.user_views,t1.user_views))) as recommend_count, 
diff_arr(t2.user_views,t1.user_views) as recommend_views
into common_user_views 
from public.user_movies_agg t1
inner join public.user_movies_agg t2
on t1.userID <> t2.userID
--where t1.userID = 1 
order by 1 ;




-- top 10 пересечений для каждого пользователя и реккомендации

select 
userID_1, 
userID_2, 
user_views_1, 
user_views_2, 
cnt_1,
cnt_2,
intersect_views,
intersect_count,
recommend_count, 
recommend_views,
rank_intrsct
into t_recomendations
from (
		select 
		userID_1, 
		userID_2, 
		user_views_1, 
		user_views_2, 
		cnt_1,
		cnt_2,
		intersect_views,
		intersect_count,
		recommend_count, 
		recommend_views,
		rank() over (partition by userID_1 order by intersect_count desc) as rank_intrsct
		from public.common_user_views t
		order by 1, intersect_count desc
		
) rnk
where rnk.rank_intrsct <=10
--limit 1
;

 \copy (select * from t_recomendations) to '/data/recomendations.tsv' with delimiter E'\t';


