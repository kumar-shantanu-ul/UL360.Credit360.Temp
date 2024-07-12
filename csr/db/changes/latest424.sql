-- Please update version.sql too -- this keeps clean builds in sync
define version=424
@update_header

-- Recompute propagated geo information
declare
	v_geo_country 		region.geo_country%TYPE;
	v_geo_region		region.geo_region%TYPE;
	v_geo_city_id		region.geo_city_id%TYPE;
	v_map_entity		region.map_entity%TYPE;
	v_geo_latitude		region.geo_latitude%TYPE;
	v_geo_longitude		region.geo_longitude%TYPE;
begin
	for c in (select app_sid, host from customer) loop
		begin
			user_pkg.logonadmin(c.host);
			dbms_output.put_line('fixing '||c.host);
			
			for r in (select region_sid 
						from region 
							 start with app_sid = parent_sid
							 connect by prior app_sid = app_sid and prior region_sid = parent_sid) loop
				--dbms_output.put_line('rr' ||r.region_sid);
				select geo_country, geo_region, geo_city_id, map_entity, geo_latitude, geo_longitude
				  into v_geo_country, v_geo_region, v_geo_city_id, v_map_entity, v_geo_latitude, v_geo_longitude
				  from region
				 where region_sid = r.region_sid;
			
				update region
				   set geo_country = v_geo_country,
					   geo_region = v_geo_region,
					   geo_city_id = v_geo_city_id,
					   map_entity = v_map_entity,
					   geo_latitude = v_geo_latitude,
					   geo_longitude = v_geo_longitude
				 where (app_sid, region_sid) in (
				 		select app_sid, region_sid
				 		  from region
				 		 where parent_sid = r.region_sid and geo_type = 6);
			end loop;
		
			security_pkg.setapp(null);
	exception
			when security_pkg.object_not_found then
				dbms_output.put_line(c.host || ' not found');
		end;
	end loop;
end;
/

begin
	for r in (select * from user_tab_columns where table_name = 'REGION' and column_name='GEO_CODE') loop
		EXECUTE IMMEDIATE 'alter table region drop column geo_code';
	end loop;
end;
/

@..\region_body

@update_tail
