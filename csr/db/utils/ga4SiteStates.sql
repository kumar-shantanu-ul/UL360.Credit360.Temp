/*
GA4 Site States
Parameters: 
	1: ga4_enabled filter, only display data for sites with this ga4_enabled value
	2: offset (in days), only show data for sites where the audit indicates that the
	   ga4_enabled value has been changed since "today-offset".
	   If the offset is 0, then sites that have never changed the ga4_enabled value are shown.
	   If the offset is -1, then all sites are shown.
Purpose: show detail for site identified by param 1
*/


PROMPT Enter ga4_enabled filter value (e.g. 0, 1, 2), date offset days filter value (e.g. -1, 0, 30)

SET feedback OFF
SET verify OFF
SET serveroutput ON
DECLARE
	v_ga4_last_updated DATE;
	v_ga4_day_offset NUMBER := '&&2';
	v_output BOOLEAN;
BEGIN
	security.user_pkg.logonadmin();
	
	dbms_output.put_line('**********************************************');
	dbms_output.put_line('*** GA4 Sites where ga4_enabled = '|| &&1);
	dbms_output.put_line('***             and day_offset = '|| v_ga4_day_offset);
	dbms_output.put_line('**********************************************');

	FOR r IN (
		SELECT c.app_sid, c.host, a.ga4_enabled
		  FROM csr.customer c
		  JOIN aspen2.application a ON a.app_sid = c.app_sid
		 WHERE a.ga4_enabled = &&1
		   AND c.host not like 'ujtests%'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		--dbms_output.put_line(r.host || ' '|| r.app_sid);
		v_ga4_last_updated := NULL;
		BEGIN
			SELECT audit_date
			  INTO v_ga4_last_updated
			  FROM csr.audit_log
			 WHERE app_sid = r.app_sid
			   AND description LIKE '%Google Analytics%'
			   ORDER BY audit_date desc
			FETCH FIRST 1 ROWS ONLY;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;
	
		v_output := FALSE;
		IF v_ga4_day_offset = -1
		THEN
			v_output := TRUE;
		END IF;
	
		IF v_ga4_day_offset = 0
			AND v_ga4_last_updated IS NULL
		THEN
			v_output := TRUE;
		END IF;
	
		IF v_ga4_day_offset > 0
			AND v_ga4_last_updated IS NOT NULL
			AND v_ga4_last_updated > SYSDATE - v_ga4_day_offset
		THEN
			--dbms_output.put_line(v_ga4_last_updated || ' > '|| (SYSDATE - v_ga4_day_offset));
			v_output := TRUE;
		END IF;

		IF v_output = TRUE THEN
			dbms_output.put(r.host || ' ('||r.app_sid||'); ');
			
			IF v_ga4_last_updated IS NOT NULL THEN
				dbms_output.put_line('Last updated: '|| v_ga4_last_updated);
			ELSE
				dbms_output.put_line('Last updated: '|| 'Never');
			END IF;
		END IF;
	END LOOP;

	dbms_output.put_line('**********************************************');
	security.user_pkg.logonadmin();
END;
/
SET feedback ON


exit