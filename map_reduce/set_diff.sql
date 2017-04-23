
create table if not exists r(a int);

create table if not exists s(a int);

insert into r values (1),(2),(3);

insert into s values (2),(3),(4);

select * from r;

select * from s;

create or replace function map(val int, relation text)
returns table(val int, relation text) as $$
	select val, relation;
$$ language sql;

create or replace function reduce(key int, bag_relations text[])
returns table(a int) as $$
begin
	if (select 'R' in (select * from unnest(bag_relations))) and (select 'S' not in (select * from unnest(bag_relations))) then
		return query
			select key;
	end if;
end;
$$ language plpgsql; 

--map phase
drop table if exists key_value;

select distinct s.val as k, s.relation as v into key_value from
((select distinct l1.val, l1.relation from r r, lateral(select m1.val, m1.relation from map(r.a,'R') m1) l1)
union
(select distinct l2.val, l2.relation from s s, lateral(select m2.val, m2.relation from map(s.a,'S') m2) l2)) s;

--group phase
drop table if exists input_reduce;

select distinct k_v.k as k, 
(select array(select k_v1.v from key_value k_v1 where k_v.k=k_v1.k)) as v into input_reduce
from key_value k_v;

--reduce phase
select distinct l.a from input_reduce pair, lateral(select * from reduce(pair.k,pair.v)) l order by l.a;

