-- Please update version.sql too -- this keeps clean builds in sync
define version=318
@update_header

-- there are rows with geo_type = 0 (location) but without latitude or longitude ... strange!
UPDATE region 
   SET geo_type = NULL 
 WHERE geo_type = 0
   AND geo_city_id IS NULL;


DECLARE
	v_cnt	NUMBER(10);
BEGIN
	-- check if column exists in the table (in theory it got dropped at latest315 but I kept in on live
	-- in case of mistakes which needed fixing (like this!)
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM user_tab_columns 
	 WHERE table_name = 'REGION' 
	   AND column_name='GEO_CODE';
	   
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE('
		BEGIN
			FOR r IN (
				SELECT geo_city_id, region_sid 
				  FROM region 
				 WHERE geo_code = ''4'' 
				   AND geo_city_id IS NOT NULL 
			)
			LOOP	
				-- update current row
				UPDATE region 
				   SET (geo_type, geo_country, geo_region, geo_code) = (
					SELECT 4 geo_type, country, region, country
					  FROM postcode.city
					 WHERE city_id = r.geo_city_id
				  )
				 WHERE region_sid = r.region_sid;
			END LOOP;
		END;');
	END IF;
END;
/

-- fixes 
begin
	update region set geo_latitude=49.45, geo_longitude = -2.58 where geo_longitude is null and geo_country='gg';
	update region set geo_latitude=54.23,geo_longitude =-4.57 where geo_longitude is null and geo_country='im';
	update region set geo_latitude=49.2167,geo_longitude =-2.1167 where geo_longitude is null and geo_country='je';
	update region set geo_latitude=-24.36146,geo_longitude =-128.316376 where geo_longitude is null and geo_country='pn';
	update region set geo_latitude=-8.5,geo_longitude =125.55 where geo_longitude is null and geo_country='tl';
	update region set geo_latitude=60.15,geo_longitude =20 where geo_longitude is null and geo_country='ax';
	update region set geo_latitude=42,geo_longitude =43.5 where geo_longitude is null and geo_country='ao';    
end;
/

@update_tail