
--https://en.wikipedia.org/wiki/HITS_algorithm#Pseudocode

create table graph(source int, target int);

create table hub(hid int primary key, score float);

create table authority(aid int primary key, score float);

create view pages as (select hid from hub union select aid from authority);

create or replace function hits()
returns void as $$
declare
	k int = 20;
	--temp float;
	norm float;
	p pages%rowtype;
	q graph%rowtype;
	r graph%rowtype;
begin
	truncate hub;
	truncate authority;
	insert into hub(hid,score) select distinct source, 1 from graph;
	insert into authority(aid,score) select distinct target, 1 from graph;
	loop
		norm = 0;
		for p in select * from pages order by pid
		loop
			--raise notice '%', p.pid;
			update authority set score=0 where aid=p.pid;
			if (select exists(select * from graph where target=p.pid)) then
				for q in select * from graph where target=p.pid
				loop
					--raise notice '%', q.source;
					--select score into temp from hub where hid=q.source;
					--raise notice '%', temp;
					update authority set score=score+(select score from hub where hid=q.source) where aid=p.pid;	
				end loop;
				--select score into temp from hub where hid=p.pid;
				--norm = norm + temp^2;
				norm = norm + (select score from authority where aid=p.pid)^2;
				--raise notice '%', norm;
			end if;
		end loop;
		norm = norm^.5;
		for p in select * from pages order by pid
		loop
			update authority set score = score/norm where aid=p.pid;
		end loop;
		norm = 0;
		for p in select *from  pages order by pid
		loop
			update hub set score=0 where hid=p.pid;
			if (select exists(select * from graph where source=p.pid)) then
				for r in select * from graph where source=p.pid
				loop
					--select score into temp from authority where aid=r.target;
					update hub set score=score+(select score from authority where aid=r.target) where hid=p.pid;
				end loop;
				--select score into temp from authority where aid=p.pid;
				norm = norm + (select score from hub where hid=p.pid)^2;
			end if;
		end loop;
		norm = norm^.5;
		for p in select * from pages order by pid
		loop
			update hub set score = score/norm where hid=p.pid;
		end loop;
		k = k-1;
		if k=0 then
			exit;
		end if;
	end loop;
	--perform disp_hub();
	--perform disp_auth();
end;
$$ language plpgsql;

select * from hub;

select * from authority;

