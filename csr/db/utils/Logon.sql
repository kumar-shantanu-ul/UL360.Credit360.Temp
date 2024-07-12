PROMPT Enter name (i.e. name.credit360.com)
DECLARE
v_host VARCHAR2(1000);
BEGIN
	BEGIN
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	EXCEPTION WHEN OTHERS THEN NULL;
	END;
	
	SELECT distinct c.host
	  INTO v_host
	  FROM csr.customer c
	  JOIN security.website w on w.application_sid_id = c.app_sid
	 WHERE LOWER(host) LIKE '&&1..credit360.%' OR LOWER(name) = LOWER('&&1') OR LOWER(website_name) = LOWER('&&1');
	 
	 dbms_output.put_line(v_host);

	security.user_pkg.logonadmin(v_host);
END;
/
SELECT app_sid, name
  FROM csr.customer c;
SELECT tenant_id
  FROM csr.customer c
  LEFT JOIN security.tenant t on t.application_sid_id = c.app_sid;
