-- Delete sheets after the given date for a single delegation.
-- This script differs from TruncateDelegation as it does not curtail the delegation, just removes sheets.
PROMPT Enter host, delegationsid, date (as YYYY-MM-DD) and root (1/0)
PROMPT Date parameter is the date from which sheets are deleted.
PROMPT If root is 1, the sid must be a root delegation.
DECLARE
	v_root_sid	security.security_pkg.T_SID_ID;
	v_dtm		csr.sheet.start_dtm%TYPE;
	v_root		NUMBER;
	v_is_root	NUMBER;
BEGIN
	security.user_pkg.logonadmin('&&1');
	v_root_sid := &&2;
	v_dtm := date '&&3';
	v_root := &&4;


	IF v_root=0 THEN
		FOR r IN (	
			SELECT sheet_id 
			  FROM csr.sheet 
			 WHERE delegation_sid = &&2
			   AND start_dtm >= v_dtm
		)
		LOOP
			csr.sheet_pkg.DeleteSheet(r.sheet_id);	
		END LOOP;
	ELSE
		SELECT CASE WHEN app_sid = parent_sid THEN 1 ELSE 0 END
		  INTO v_is_root
		  FROM csr.delegation
		 WHERE delegation_sid = v_root_sid;

		IF v_is_root = 0 THEN
			RAISE_APPLICATION_ERROR(-20001,'Delegation isn''t root deleg');
		END IF;

		FOR r IN (	
			SELECT sheet_id 
			  FROM csr.sheet 
			 WHERE delegation_sid IN (
				SELECT delegation_sid 
				  FROM csr.delegation 
				 START WITH delegation_sid = v_root_sid
			   CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
			 ) AND start_dtm >= v_dtm
		)
		LOOP
			csr.sheet_pkg.DeleteSheet(r.sheet_id);	
		END LOOP;
	END IF;

END;
/
