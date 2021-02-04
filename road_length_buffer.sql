do $$
declare 
	recpt text := 'eric_id_12_4479';
	roads text := 'china_osm_majorroads_4479'; --constant_nor_lur_bng, all_vehsum, allmv
	radii text[] = array['1000', '500','400', '200','300', '100', '50'];
	i text;
	sql text;
begin
	drop table if exists buffers;

	--Make buffers
	sql := 'create table buffers as	select ';
	foreach i in array radii
	loop 
		sql := sql || 'st_buffer(r.geom, ' || i || ') as b' || i || ',';
	end loop;
	sql := sql || 'r.gid from ' || recpt || ' as r';
	execute sql;

	--Perform intersections
	foreach i in array radii
	loop 
		raise notice '%', i;
		execute 'create index buf_indx_' || i || ' on buffers' || ' using gist (b' || i || ')';

		sql := '
		drop table if exists roadlen12' || i || ';
		create table roadlen12' || i || ' as
		select b.gid, coalesce(d.roadlength, 0) as roadlength
		from buffers as b left join
		(with intsct as (
			select b.gid, st_length(st_intersection(r.geom, b.b'|| i ||')) as length
			from '|| roads ||' as r, buffers as b
			where st_intersects(r.geom, b.b'|| i ||')
		)
		select RLN.gid, coalesce(RLN.roadlength, 0) as roadlength
		from 
			(select intsct.gid, sum(intsct.length) as roadlength
			from intsct 
			group by intsct.gid
			) as RLN)
			as d on b.gid=d.gid';
		execute sql;
	end loop;
end;
$$language plpgsql;
