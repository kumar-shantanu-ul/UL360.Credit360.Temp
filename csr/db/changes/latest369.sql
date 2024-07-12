-- Please update version.sql too -- this keeps clean builds in sync
define version=369
@update_header

alter table region drop constraint geo_type_chk;
update region set geo_type = 6 where geo_type is null;
alter table region modify geo_type default 6 not null;
alter table region add constraint ck_geo_type CHECK (
(GEO_TYPE = 0 AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
(GEO_TYPE = 1 AND GEO_COUNTRY IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
(GEO_TYPE = 2 AND MAP_ENTITY IS NOT NULL) OR
(GEO_TYPE = 3 AND GEO_COUNTRY IS NOT NULL AND GEO_REGION IS NOT NULL) OR
(GEO_TYPE = 4 AND GEO_COUNTRY IS NOT NULL AND GEO_REGION IS NOT NULL AND GEO_CITY_ID IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
(GEO_TYPE = 5 AND GEO_COUNTRY IS NULL AND GEO_REGION IS NULL AND GEO_CITY_ID IS NULL AND GEO_LONGITUDE IS NULL AND GEO_LATITUDE IS NULL) OR
(GEO_TYPE = 6)
);

-- stop people editing "regions"
update region set region_type = 2 where parent_sid = app_sid;

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

@..\region_pkg
@..\region_body

@update_tail
