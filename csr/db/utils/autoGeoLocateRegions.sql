declare
	v_cnt	number(10) := 0;
begin
	security.user_pkg.logonAdmin('&&1');
	for r in (
		select r.region_sid, r.description, r.active, r.pos, r.geo_type, r.info_xml,
			   nvl(cc.country, c.country) country, r.map_entity, r.egrid_ref, r.lookup_key,
			   r.acquisition_dtm, r.disposal_dtm
		  from csr.v$region r 
			left join postcode.country c on lower(trim(r.description)) = lower(c.name)
			left join postcode.country_alias ca on lower(trim(r.description)) = lower(ca.alias)
			left join postcode.country cc on ca.country = cc.country			
		 where lower(trim(r.description)) not in ('europe')
		   and r.geo_country is null
		   and r.region_sid in  (
				select region_sid
				  from csr.region
				  start with region_sid = (select region_tree_root_sid from csr.region_tree where is_primary = 1)
				 connect by prior region_sid = parent_sid
		   )
		   and nvl(cc.country, c.country) is not null
	)
	loop
		csr.region_pkg.AmendRegion(
			SYS_CONTEXT('SECURITY', 'ACT'),
			r.region_sid,
			r.description,
			r.active,
			r.pos,
			csr.region_pkg.REGION_GEO_TYPE_COUNTRY,
			r.info_xml,
			r.country,
			null, -- geo_region
			null, -- geo_city
			r.map_entity, -- map_entity
			r.egrid_ref, -- egrid_ref
			r.lookup_key, -- lookup_key
			r.acquisition_dtm,
			r.disposal_dtm);
			UPDATE csr.region 
			   SET region_type = 0
			 where region_sid = r.region_sid;
			v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line('count '||v_cnt);
end;
/
