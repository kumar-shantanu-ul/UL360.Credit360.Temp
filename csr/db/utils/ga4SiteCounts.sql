/*
GA4 Site Counts
Parameters: NONE
Purpose: show counts of sites for each of the 3 possible GA4 states.
*/

SET feedback OFF
SET serveroutput ON
DECLARE
	v_ga4_disabled NUMBER := 0;
	v_ga4_enabled NUMBER := 0;
	v_ga4_force_enabled NUMBER := 0;
BEGIN
	SELECT COUNT(*) 
	  INTO v_ga4_disabled
	  FROM aspen2.application
	 WHERE ga4_enabled = 0;

	SELECT COUNT(*) 
	  INTO v_ga4_enabled
	  FROM aspen2.application
	 WHERE ga4_enabled = 1;

	SELECT COUNT(*) 
	  INTO v_ga4_force_enabled
	  FROM aspen2.application
	 WHERE ga4_enabled = 2;
	
	dbms_output.put_line('**********************************************');
	dbms_output.put_line('***            GA4 Site counts             ***');
	dbms_output.put_line('**********************************************');
	dbms_output.put_line('Disabled:             '|| v_ga4_disabled);
	dbms_output.put_line('Enabled:              '|| v_ga4_enabled);
	dbms_output.put_line('ForceEnabled (Beta):  '|| v_ga4_force_enabled);
	dbms_output.put_line('**********************************************');
END;
/
SET feedback ON


exit