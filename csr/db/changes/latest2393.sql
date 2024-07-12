-- Please update version.sql too -- this keeps clean builds in sync
define version=2393
@update_header

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_MAP_TAB_CHART'
	   AND column_name = 'CHART_HEIGHT';

	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.geo_map_tab_chart ADD ( CHART_HEIGHT NUMBER(10, 0) )';
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'GEO_MAP_TAB_CHART'
	   AND column_name = 'CHART_WIDTH';

	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.geo_map_tab_chart ADD ( CHART_WIDTH NUMBER(10, 0) )';
	END IF;
END;
/

@../geo_map_pkg
@../geo_map_body

@update_tail
