PROMPT Deletes all delegation values between two dates
PROMPT Enter host name, from date, to date
PROMPT Enter dates in the format yyyy-mm-dd

define host = "&&1"
define from = "&&2"
define to   = "&&3"

SET serveroutput ON

DECLARE
	v_cnt_values		NUMBER(10) :=0;
	v_cnt_delegations	NUMBER(10) :=0;
	v_app_sid			security_pkg.T_SID_ID;

	v_from 				DATE:=NULL;
	v_to				DATE:=NULL;
BEGIN
    security.user_pkg.LogonAdmin('&host');
    v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	v_from:= DATE '&from';
	v_to:= DATE '&to';

	-- Delete values 
	FOR v IN (
		SELECT val_id, period_start_dtm, period_end_dtm
		  FROM csr.val
		 WHERE (v_from IS NULL OR period_start_dtm >= v_from)
		   AND (v_to IS NULL OR period_end_dtm <= v_to)
		   AND app_sid = v_app_sid
	)
	LOOP	
		v_cnt_values := v_cnt_values + 1;
		DBMS_OUTPUT.PUT_LINE('Deleting val:'||v.val_id||'; PStart'||v.period_start_dtm||'; PEnd:'||v.period_end_dtm);
		csr.indicator_pkg.deleteval(SYS_CONTEXT('SECURITY','ACT'), v.val_id, 'Deleted delegation values between '||v_from||' and '||v_to);
	END LOOP;

	-- Delete delegations
	FOR r IN (
		SELECT d.delegation_sid, d.start_dtm, d.end_dtm 
		  FROM csr.delegation d
		 WHERE (v_from IS NULL OR start_dtm >= v_from)
		   AND (v_to IS NULL OR end_dtm <= v_to)
		   AND d.app_sid = v_app_sid
	)
	LOOP
		v_cnt_delegations := v_cnt_delegations + 1;
		DBMS_OUTPUT.PUT_LINE('Deleting deleg:'||r.delegation_sid||'; PStart'||r.start_dtm||'; PEnd:'||r.end_dtm);
		security.securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), r.delegation_sid);
	END LOOP;
	
	DBMS_OUTPUT.PUT_LINE('deleted '||v_cnt_values||' values');
	DBMS_OUTPUT.PUT_LINE('deleted '||v_cnt_delegations||' delegations');
END;
/
