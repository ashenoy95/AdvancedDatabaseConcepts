
create table r(a int, b int);

create table s(b int, c int);

insert into r values (1,2),(3,4);

insert into s values (2,3),(5,6);

select * from r;

select * from s;

drop type if exists custom;

create type custom as (relation text, val int);

drop function map(int,text);

create or replace function map(val int, relation text)
returns table(key int, value custom) as $$
declare
	cust custom;
begin
	select relation into cust.relation;
	if relation='R' then
		select a into cust.val from r where b=val;
	else
		select c into cust.val from s where b=val;
	end if;
	return query
		select val, cust;
end;
$$ language plpgsql;

create or replace function reduce(key int, bag_relations custom[])
returns table(a int, b int, c int) as $$
declare
	rec1 record;
	i int = 0;
	a int;
	c int;
begin 
	for rec1 in select * from unnest(bag_relations)
	loop
		if rec1.relation='R' then
			a = rec1.val;
		else
   			c = rec1.val;
		end if;
		i = i+1;
	end loop;
	if i>1 then
		return query
			select a, key, c;
	end if;	
end;
$$ language plpgsql;

--map phase
drop table if exists key_value;

select distinct s.key as k, s.value as v into key_value from
((select distinct l1.key, l1.value from r r, lateral(select m1.key, m1.value from map(r.b,'R') m1) l1)
union
(select distinct l2.key, l2.value from s s, lateral(select m2.key, m2.value from map(s.b,'S') m2) l2)) s;

--group phase
drop table if exists input_reduce;

select distinct k_v.k as k, 
(select array(select k_v1.v from key_value k_v1 where k_v.k=k_v1.k)) as v into input_reduce
from key_value k_v;

--reduce phase
select l.a, l.b, l.c from input_reduce pair, lateral(select * from reduce(pair.k,pair.v)) l order by l.a;

