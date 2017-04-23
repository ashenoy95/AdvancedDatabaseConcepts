
create table if not exists r(a int, b int);

insert into r values (1,2),(3,4),(5,6);

select * from r;

create or replace function map(a int, b int)
returns table(a1 int, a2 int) as $$
	select a, a;
$$ language sql;

create or replace function reduce(key int, bag int[])
returns table(w int, value int) as $$
	select key, key;
$$ language sql;

--map phase
drop table if exists temp;

select l.a1 as a, l.a2 as b into temp from r r, lateral(select m.a1, m.a2 from Map(r.a,r.b) m) l; 

--group phase
drop table if exists input_reduce;

select distinct t1.a, (select array(select t2.b from temp t2 where t1.a=t2.a)) as ones into input_reduce from temp t1;

--reduce phase
select distinct l.w as a from input_reduce pair, lateral(select * from reduce(pair.a,pair.ones)) l order by l.w;
