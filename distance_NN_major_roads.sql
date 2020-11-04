create or replace function  nnid(nearto geometry, initialdistance real, distancemultiplier real, 
maxpower integer, nearthings text, nearthingsidfield text, nearthingsgeometryfield  text)
returns integer as $$
declare 
  sql text;
  result integer;
begin
  sql := ' select ' || quote_ident(nearthingsidfield) 
      || ' from '   || quote_ident(nearthings)
      || ' where st_dwithin($1, ' 
      ||   quote_ident(nearthingsgeometryfield) || ', $2 * ($3 ^ $4))'
      || ' order by st_distance($1, ' || quote_ident(nearthingsgeometryfield) || ')'
      || ' limit 1';
  for i in 0..maxpower loop
     execute sql into result using nearto             -- $1
                                , initialdistance     -- $2
                                , distancemultiplier  -- $3
                                , i;                  -- $4
     if result is not null then return result; end if;
  end loop;
  return null;
end
$$ language 'plpgsql' stable;


do $$
declare 
	recpt text := 'eric_id_12_4479';
	roads text := 'china_osm_majorroads_4479'; --constant_nor_lur_bng_dists, all_vehsum, allmv
	sql text;
begin
	--find nearest neighbours
	sql := '
	drop table if exists traf12;
	create table traf12 as 
	with nn as (
		select distinct r.gid, r.geom, 
		nnid(r.geom, 0.00001, 2, 100, '''|| roads ||''', ''gid'', ''geom'') as nn_maj
		from '|| recpt ||' as r
	)
	select DMR.gid, DMR.distnear, (1 / DMR.distnear) as distinvnear1
	from
		(select nn.gid, st_distance(nn.geom, t.geom) as distnear
		from nn left join '|| roads ||' as t 
		on nn.nn_maj = t.gid
		) as DMR';
	execute sql;
end;
$$language plpgsql;