-- Please update version.sql too -- this keeps clean builds in sync
define version=325
@update_header

-- modify constraint doesn't seem to work! (just get SQL command not properly ended)
ALTER TABLE REGION DROP CONSTRAINT GEO_TYPE_CHK;

ALTER TABLE REGION ADD CONSTRAINT GEO_TYPE_CHK CHECK (
(GEO_TYPE IS NULL) OR
(GEO_TYPE = 0 AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
(GEO_TYPE = 1 AND GEO_COUNTRY IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
(GEO_TYPE = 2 AND MAP_ENTITY IS NOT NULL) OR
(GEO_TYPE = 3 AND GEO_COUNTRY IS NOT NULL AND GEO_REGION IS NOT NULL) OR
(GEO_TYPE = 4 AND GEO_COUNTRY IS NOT NULL AND GEO_REGION IS NOT NULL AND GEO_CITY_ID IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL)
);

-- find all regions where GEO_TYPE is NOT NULL, and propagate GEO information down until
-- we hit a descendant region where it IS NOT NULL (or the bottom of the tree).
BEGIN
	FOR r IN (
	   SELECT *
		 FROM (
			 SELECT region_sid, description, level lvl,
				connect_by_root geo_country root_geo_country,
				connect_by_root geo_region root_geo_region, 
				connect_by_root geo_city_id root_geo_city_id, 
				connect_by_root geo_latitude root_geo_latitude, 
				connect_by_root geo_longitude root_geo_longitude
			   FROM region
			  START WITH geo_type IS NOT NULL
			CONNECT BY PRIOR region_sid = parent_sid
				AND geo_type IS NULL
		  )
		WHERE lvl > 1 -- skip the root since it's already set to these values
	)
	LOOP
		UPDATE region 
		   SET geo_country = r.root_geo_country,
			   geo_region = r.root_geo_region,
			   geo_city_id = r.root_geo_city_id,
			   geo_latitude = r.root_geo_latitude,
			   geo_longitude = r.root_geo_longitude
		 WHERE region_sid = r.region_sid;
	END LOOP;
END;
/


@update_tail