
-- Please update version.sql too -- this keeps clean builds in sync
define version=827
@update_header

BEGIN
	FOR r IN (
		SELECT DISTINCT c.host, c.oracle_schema, a.cms_table 
		  FROM csr.customer c, csr.axis a 
		 WHERE c.app_sid IN ( SELECT DISTINCT app_sid FROM csr.axis )
		   AND a.app_sid = c.app_sid
	)
	LOOP
		--dbms_output.put_line('fixing: ' || r.oracle_schema);
		EXECUTE IMMEDIATE
			'GRANT SELECT, UPDATE ON '||r.oracle_schema||'.'||r.cms_table||' to csr';
	END LOOP;
END;
/

@update_tail
