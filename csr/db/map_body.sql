CREATE OR REPLACE PACKAGE BODY CSR.Map_Pkg AS

-- wow, this is full of security checks

PROCEDURE GetMapByContext(
  in_map_context  IN  customer_map.map_context%TYPE,
  out_cur       OUT   security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT shpfile, config_path, geo_field, geo_country, cm.extent_n, cm.extent_s, cm.extent_w, cm.extent_e
		  FROM customer_map cm, map_shpfile ms 
		 WHERE cm.map_id = ms.map_id(+)
           AND cm.map_context = in_map_context
           AND cm.app_sid = sys_context('SECURITY', 'APP')
         ORDER BY z_order;
END;


PROCEDURE GetLocationsForCountry(
  in_country_code IN  region.geo_country%TYPE,
  out_cur         OUT   security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_sid, description, geo_type, geo_region, geo_latitude, geo_longitude, geo_city_id 
		  FROM v$region 
		 WHERE geo_country = LOWER(in_country_code)
		   AND geo_type IN( region_pkg.REGION_GEO_TYPE_CITY,region_pkg.REGION_GEO_TYPE_COUNTRY, region_pkg.REGION_GEO_TYPE_LOCATION);
END;

END Map_Pkg;
/

