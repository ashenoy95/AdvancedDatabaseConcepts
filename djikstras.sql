
create table g(source int, target int, weight int);

create table paths(target int, distance int);

create table fringe(val int);

create table nodes (node int, f int, g int, visited int);

create or replace function dijkstra(source int)
returns table(tar int, dis int) as $$
declare 
	initial int = source;
	n nodes%rowtype;
	sdash g%rowtype;
	s int;
	d int;
	temp int;
	goal int;
	dist int;
begin	
	if (select not exists(select * from nodes where node=initial)) then
		return;
	end if;
	truncate paths;
	truncate nodes;
	insert into nodes (node,f,g,visited) select g.source as node,0,0,0 from g g union select g.target as node,0,0,0 from g g order by node; 
	--raise notice 'source: %', initial;
	for n in select * from nodes
	loop
		insert into paths values(n.node,0);
	end loop;
	for n in select * from nodes
	loop
		update nodes set f=0,g=0,visited=0;
		goal = n.node;
		--raise notice 'goal: %', goal;
		if initial=goal then
			update paths set distance=0 where target=goal;
			--raise notice 'Initial=goal';
			continue;
		end if;
		truncate fringe;
		insert into fringe values(initial);
		loop
			if (select not exists(select * from fringe)) then
				update paths set distance=null where target=goal;
				--raise notice 'No path exists!';
				exit;
			end if;
			select f.val into s from fringe f inner join nodes nod on (nod.node=f.val) where nod.f<=all(select nod.f from nodes nod inner join fringe f on (nod.node=f.val));
			--raise notice 'Removing s from fringe: %', s;
			update nodes set visited=1 where node=s;
			delete from fringe where val=s;
			if s=goal then
				select f into d from nodes where node=s;
				select distance into temp from paths where target=s;
				update paths set distance=distance+(select f from nodes where node=goal) where target=s;
				--raise notice 's=goal and dist=% + %', temp,d;
				exit;
			end if;
			if (select exists(select * from g g where g.source=s)) then
				for sdash in select * from g g where g.source=s
				loop
					if (select visited from nodes where node=sdash.target)=1 then
						continue;
					end if;
					select g.weight into dist from g g where g.source=s and sdash.target=g.target;
					update nodes set g=dist where node=sdash.target;
					select f into temp from nodes where node=s;
					update nodes set f=temp+dist where node=sdash.target;
					insert into fringe values(sdash.target);
					--raise notice 'Inserting into fringe: %', sdash.target;
					--raise notice 'weight:% + %', temp,dist;
					
				end loop;
			end if;
		end loop;
	end loop;
	return query
		select target, distance from paths order by target;
end;
$$ language plpgsql;

