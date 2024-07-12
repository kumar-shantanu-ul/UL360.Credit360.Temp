-- Please update version.sql too -- this keeps clean builds in sync
define version=2360
@update_header

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_TILESET'
	   AND column_name = 'JS_CLASS';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET ADD ( JS_CLASS VARCHAR2(255) )';
		EXECUTE IMMEDIATE 'UPDATE CSR.GEO_TILESET SET JS_CLASS = ''MQ.mapLayer''';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_TILESET MODIFY ( JS_CLASS VARCHAR2(255) NOT NULL )';

		COMMIT;

	END IF;
END;
/

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_MAP'
	   AND column_name = 'GEO_TILESET_ID'
	   AND nullable = 'Y';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE CSR.GEO_MAP MODIFY ( GEO_TILESET_ID NULL )';

		COMMIT;

	END IF;
END;
/

BEGIN
	UPDATE csr.geo_tileset 
	   SET label = 'Map',
		   lookup_key = 'MAPQUEST_MAP',
		   js_class = 'MQ.mapLayer'
	 WHERE geo_tileset_id = 1;
 
	UPDATE csr.geo_tileset 
	   SET label = 'Hybrid',
		   lookup_key = 'MAPQUEST_HYBRID',
		   js_class = 'MQ.hybridLayer'
	 WHERE geo_tileset_id = 2;
 
	UPDATE csr.geo_tileset 
	   SET label = 'Satellite',
		   lookup_key = 'MAPQUEST_SATELLITE',
		   js_class = 'MQ.satelliteLayer'
	 WHERE geo_tileset_id = 3;
 
	COMMIT;
END;
/

@update_tail
