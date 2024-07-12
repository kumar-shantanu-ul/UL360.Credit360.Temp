DECLARE
	v_schema		varchar2(30);
	v_schema_part	varchar2(30);
	v_req_version	version.db_version%TYPE;
	v_version		version.db_version%TYPE;
BEGIN
	
	v_schema := '&1';
	v_req_version := &2;
	v_schema_part := '&3';
	
	IF v_schema_part IS NULL THEN
		EXECUTE IMMEDIATE 'SELECT db_version FROM '||v_schema||'.version'
		INTO v_version;
	ELSE
		EXECUTE IMMEDIATE 'SELECT db_version FROM '||v_schema||'.version where part='''||v_schema_part||''''
		INTO v_version;
	END IF;
	
	IF v_version < v_req_version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= '||v_schema||'.VERSION IS CURRENTLY '||v_version||'. VERSION '||v_req_version||' IS REQUIRED =======');
	END IF;
END;
/
