whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

exec dbms_output.enable(10000);

DEFINE host = '&&1'
DEFINE usr = '&&2'
DEFINE feed_id = '&&3'
DEFINE ref = '&&4'

DECLARE
	v_matched_sids security.T_SID_TABLE := security.T_SID_TABLE();
	v_matched_text	VARCHAR2(2000);
BEGIN
	security.user_pkg.logonadmin('&&host');
	
	v_matched_sids := chain.company_dedupe_pkg.GetExactMatches(
		in_feed_id		=> &&feed_id,
		in_company_ref	=> &&ref
	);
	
	SELECT listagg(column_value, ',') WITHIN GROUP (ORDER BY column_value)
	  INTO v_matched_text
	  FROM TABLE(v_matched_sids); 
	  
	dbms_output.put_line('-------------');
	dbms_output.put_line('Matched sids:');
	dbms_output.put_line(v_matched_text);
END;
/
