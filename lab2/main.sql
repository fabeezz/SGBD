--Jiglau Fabrizzio

select category, count(distinct title) as nr_titluri, count(r.copy_id) as nr_imprumutate
from title t, rental r
where r.title_id = t.title_id
group by t.category
having count(*) = (
            select max(count(*))
            from rental r, title t
            where r.title_id = t.title_id
            group by t.category
);

--5
--Jiglau Fabrizzio
select distinct(title_id), count(copy_id) as nrc
from title_copy where status like 'AVAILABLE'
group by title_id
order by title_id;

select tc.title_id
from title_copy tc, rental r
where tc.title_id = r.title_id;


