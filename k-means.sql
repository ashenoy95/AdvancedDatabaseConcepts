
create table points(pid int primary key, x float, y float);

create table centroids(cid int primary key, x float, y float);

create table clusters(pid int references points(pid), cid int);

create or replace function init(k int)
returns void as $$
declare
	ctr int = 0;
	p points%rowtype;
begin
	truncate centroids;
	truncate clusters;
	loop
		insert into centroids values ((ctr+1),(select random()*(10-1)+1),(select random()*(10-1)+1));
		ctr = ctr+1;
		if ctr=k then
		exit;
		end if;
	end loop;
	truncate clusters;
	for p in select * from points loop
		insert into clusters values(p.pid,0);
	end loop;
end;
$$ language plpgsql;

create or replace function kmeans(k int)
returns table(p int, c int) as $$ 
declare 
	p points%rowtype;
	c centroids%rowtype;
	dist float;
	temp float;
	nearest int;
	ctr integer = 0; 
Begin
	perform init(k);
	loop
		for p in select * from points 
		loop 
			dist = 1000;
			for c in select * from centroids
			loop 
				temp = ((p.x-c.x)^2+(p.y-c.y)^2)^.5;
				if temp<dist then
					dist = temp;
					nearest = c.cid;
				end if; 
			end loop; 
			update clusters set cid=nearest where pid=p.pid;
		end loop;
		for c in select * from centroids
		loop
			if c.cid in (select clust.cid from clusters clust) then
				update centroids set x=(select avg(po.x) from clusters clust inner join points po on clust.pid=po.pid where clust.cid=c.cid group by clust.Cid), y=(select avg(po.y) from clusters clust inner join points po on clust.pid=po.pid where clust.cid=c.cid group by clust.Cid) where c.cid=cid;
			end if;
		end loop;
		ctr = ctr+1;
		if ctr=200 then
			exit;
		end if; 
	end loop; 
	return query
		select * from clusters;
end; 
$$language plpgsql;

