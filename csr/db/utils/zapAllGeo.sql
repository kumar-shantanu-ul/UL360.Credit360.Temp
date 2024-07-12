PROMPT Enter the host name
begin
	user_pkg.logonadmin('&&1');
	update region 
	   set geo_type = 6, geo_region=null, geo_country = null, geo_longitude = null, geo_latitude = null, map_entity = null, egrid_ref = null, geo_city_id = null;
end;
/

