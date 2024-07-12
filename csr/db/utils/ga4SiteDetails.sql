/*
GA4 Site Details
Parameters: 
	1: site name, can be a partial name (e.g xxx, meaning xxx.credit360.[env])
Purpose: show detail for site identified by param 1
*/

PROMPT Enter site name (e.g. name.credit360.com)

SET feedback OFF
SET verify OFF
SET serveroutput ON

DECLARE
	v_param VARCHAR2(256) := LOWER('&&1');
	v_host VARCHAR2(256);
	no_host EXCEPTION;

	v_ga4_state NUMBER := 0;
	v_ga4_last_updated DATE;
BEGIN
	security.user_pkg.logonadmin();
	
	BEGIN
		SELECT distinct c.host
		  INTO v_host
		  FROM csr.customer c
		  JOIN security.website w on w.application_sid_id = c.app_sid
		 WHERE LOWER(host) LIKE v_param||'.credit360.%' OR 
			   LOWER(host) LIKE v_param||'.cr360.%' OR 
			   LOWER(host) LIKE v_param||'.ul360.%' OR 
			   LOWER(name) = v_param OR 
			   LOWER(website_name) = v_param;
	EXCEPTION
		WHEN no_data_found THEN
			dbms_output.put_line('No host found.');
			RAISE no_host;
	END;
	 
	dbms_output.put_line('host '||v_host);
	 
	--dbms_output.put_line(v_host);
	security.user_pkg.logonadmin(v_host);

	SELECT ga4_enabled
	  INTO v_ga4_state
	  FROM aspen2.application
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		SELECT audit_date
		  INTO v_ga4_last_updated
		  FROM csr.audit_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND description LIKE '%Google Analytics%'
		   AND ROWNUM = 1
		   ORDER BY audit_date desc;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;
	
	dbms_output.put_line('**********************************************');
	dbms_output.put_line('***            GA4 Site status             ***');
	dbms_output.put_line('**********************************************');
	dbms_output.put_line('Host:             '|| v_host);
	dbms_output.put_line('State:            '|| CASE WHEN v_ga4_state = 0 THEN 'Disabled' WHEN v_ga4_state = 1 THEN 'Enabled' WHEN v_ga4_state = 2 THEN 'Force enabled (Beta)' ELSE 'Unknown' END );
	
	IF v_ga4_last_updated IS NOT NULL THEN
		dbms_output.put_line('Last updated:     '|| v_ga4_last_updated);
	ELSE
		dbms_output.put_line('Last updated:     '|| 'Never changed');
	END IF;
	dbms_output.put_line('**********************************************');
EXCEPTION
	WHEN no_host THEN NULL;
END;
/
SET feedback ON


exit