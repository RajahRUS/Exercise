SELECT ('Егоров Р.В.');


-- 1.1

SELECT * from public.ratings limit 10;

-- 1.2

SELECT * 
from public.links
where 
imdbid like '%42'
and movieid between 100 and 1000
limit 10;


--2.1


SELECT l.* , r.rating
from public.links l inner join public.ratings r on r.movieid = l.movieid
where 
r.rating = 5
limit 10;


-- 3.1



SELECT count(distinct l.* )
from public.links l left join public.ratings r on l.movieid = r.movieid
where 
r.rating  is null
limit 10;



--3.2

SELECT userid, avg(rating) avg_rating
from public.ratings 
group by userid
having avg(rating) > 3.5
order by 2 desc
limit 10;


--4.1 

with rating_more_35 as 
(
SELECT movieid , avg(rating) avg_rating
from public.ratings 
group by movieid 
having avg(rating) > 3.5
)
select l.imdbid
from public.links l inner join rating_more_35 r on l.movieid = r.movieid
limit 10;



--4.2
SELECT avg(rating) avg_rating
from public.ratings r
where r.userid in (
	select rr.userid 
	from(
		SELECT userid, count(*) count_rating
		from public.ratings 
		group by userid
		having count(*) > 10
		) rr
				  )
;


