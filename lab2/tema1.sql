select * from reservation;
select * from rental;

--8
select distinct
    res.title_id, res.member_id,
    case
        when res.res_date = ren.book_date
            then 'DA'
            else 'NU'
        end as "Imprumutate la data rezervarii?"
from reservation res, rental ren;


--9
select 
    m.first_name || ' ' || m.last_name as nume,
    t.title as titlu,
    count(r.title_id) as num_inchirieri
from member m, rental r, title t
where m.member_id = r.member_id
    and r.title_id = t.title_id 
group by m.first_name, m.last_name, t.title
order by nume, titlu;

