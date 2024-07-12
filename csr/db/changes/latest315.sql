-- Please update version.sql too -- this keeps clean builds in sync
define version=315
@update_header

-- check for right version of postcode
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM postcode.version;
	IF v_version < 3 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A ***POSTCODE*** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

PROMPT Enter connection string (e.g. aspen)

connect postcode/postcode@&&1;
grant select, references on country to csr;
grant select, references on region to csr;
grant select, references on city to csr;

connect csr/csr@&&1;

ALTER TABLE REGION ADD (
    GEO_COUNTRY           VARCHAR2(2),
    GEO_REGION            VARCHAR2(2),
    GEO_CITY_ID           NUMBER(10, 0),
    MAP_ENTITY            VARCHAR2(32)
);

UPDATE REGION SET MAP_ENTITY = GEO_CODE WHERE GEO_TYPE = 2;

UPDATE REGION SET GEO_COUNTRY = GEO_CODE WHERE GEO_TYPE = 1;


DECLARE
	CURSOR c(in_lat number, in_long number) IS
		select city_id, city_name 
		  from postcode.city 
		 where latitude = in_lat AND longitude = in_long;
	r	c%ROWTYPE;
BEGIN
	-- icky but no indexes on lat/long etc, so it'll do.
	FOR ar IN (
		SELECT REGION_SID, description, GEO_LATITUDE, GEO_LONGITUDE 
		  FROM REGION r
		 WHERE GEO_TYPE = 0
	)
	LOOP
		OPEN c(ar.geo_latitude, ar.geo_longitude);
		FETCH c INTO r;
		IF c%FOUND THEN
			DBMS_OUTPUT.PUT_LINE('mapped '||ar.description||' to '||r.city_name);
			UPDATE region 
			   SET geo_city_id = r.city_id,
				geo_code = 4
			 WHERE region_sid = ar.region_sid;
		END IF;
		CLOSE c;
		commit; -- commit in case of errors so we don't have to start from scratch!
	END LOOP;
END;
/


ALTER TABLE CSR.REGION ADD CONSTRAINT RefCOUNTRY1152 
    FOREIGN KEY (GEO_COUNTRY)
    REFERENCES POSTCODE.COUNTRY(COUNTRY)
;

ALTER TABLE CSR.REGION ADD CONSTRAINT RefREGION1153 
    FOREIGN KEY (GEO_COUNTRY, GEO_REGION)
    REFERENCES POSTCODE.REGION(COUNTRY, REGION)
;

ALTER TABLE CSR.REGION ADD CONSTRAINT RefCITY1154 
    FOREIGN KEY (GEO_CITY_ID)
    REFERENCES POSTCODE.CITY(CITY_ID)
;

/*
0 = location (just lat/long) 
1 = country (country + lat/long)
2 = map entity (eg.AP, EMEA -- used by Flash Map only)
3 = region (country + region + lat/long)
4 = city (lat/long)
*/
ALTER TABLE REGION ADD CONSTRAINT GEO_TYPE_CHK CHECK (
	(GEO_TYPE IS NULL) OR 
	(GEO_TYPE = 0 AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
	(GEO_TYPE = 1 AND GEO_COUNTRY IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL) OR
	(GEO_TYPE = 2 AND MAP_ENTITY IS NOT NULL) OR
	(GEO_TYPE = 3 AND GEO_COUNTRY IS NOT NULL AND GEO_REGION IS NOT NULL) OR
	(GEO_TYPE = 4 AND GEO_COUNTRY IS NOT NULL AND GEO_REGION IS NOT NULL AND GEO_CITY_ID IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_LATITUDE IS NOT NULL)
);

ALTER TABLE REGION DROP COLUMN GEO_CODE;

@update_tail
