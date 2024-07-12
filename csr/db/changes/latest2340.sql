-- Please update version.sql too -- this keeps clean builds in sync
define version=2340
@update_header

DECLARE
	v_cnt NUMBER;
BEGIN

	SELECT count(*) INTO v_cnt
	  FROM dba_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'PROPERTY_OPTIONS'
	   AND column_name = 'PROPERTIES_GEO_MAP_SID';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE csr.property_options ADD properties_geo_map_sid NUMBER(10, 0)';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.property_options ADD CONSTRAINT fk_propopt_geomap FOREIGN KEY (app_sid, properties_geo_map_sid) REFERENCES csr.geo_map(app_sid, geo_map_sid)';

	END IF;
END;
/

@../property_pkg
@../property_body

@update_tail
