DECLARE
	v_host			csr.customer.host%TYPE := '&host';
	v_startD		csr.sheet.end_dtm%TYPE := '&startDate'; -- e.g. '01-JAN-2012'
	v_endD			csr.sheet.end_dtm%TYPE := '&endDate'; -- e.g. '01-JAN-2013'	
	v_act_id		security.security_pkg.T_ACT_ID;
	v_cnt 			NUMBER(10);
	v_user_name		VARCHAR2(256) := '&userName';
	v_deleg_name    VARCHAR2(256) := '&delegName'; -- restrict to named delegation, % allowed
	deadlock_detected EXCEPTION;
	PRAGMA EXCEPTION_INIT(deadlock_detected, -60);
BEGIN

	SECURITY.user_pkg.logonAdmin(v_host);

	v_user_name := '/users/' || v_user_name;
	SECURITY.user_pkg.LogonAuthenticatedPath(security_pkg.getapp(), v_user_name, 100000, v_act_id);
	
	v_cnt := 1;

	FOR r_d IN (		
		SELECT delegation_sid, name, CASE WHEN parent_sid = app_sid THEN 1 ELSE 0 END is_top_level
		  FROM csr.delegation
		 WHERE start_dtm < v_endD AND end_dtm > v_startD
			AND name LIKE v_deleg_name
			START WITH parent_sid = app_sid
			CONNECT BY parent_sid = PRIOR delegation_sid
		 ORDER BY LEVEL DESC
	)
	LOOP
		dbms_output.put_line(v_cnt || '. Processing deleg ' || r_d.delegation_sid);

		-- Find any sheets that can't be submitted because the parent has been submitted, and return the parent sheet
		FOR r_s IN (
			SELECT sp.sheet_id
			  FROM csr.delegation d
			  JOIN csr.sheet_with_last_action s ON d.delegation_sid = s.delegation_sid
			  JOIN csr.sheet_with_last_action sp ON d.parent_sid = sp.delegation_sid AND s.start_dtm = sp.start_dtm
			 WHERE d.delegation_sid = r_d.delegation_sid
			   AND s.end_dtm > v_startD AND s.end_dtm <= v_endD
			   AND s.last_action_id IN (csr.csr_data_pkg.ACTION_SUBMITTED, csr.csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, csr.csr_data_pkg.ACTION_WAITING, csr.csr_data_pkg.ACTION_WAITING_WITH_MOD, csr.csr_data_pkg.ACTION_RETURNED, csr.csr_data_pkg.ACTION_RETURNED_WITH_MOD)
			   AND sp.last_action_id IN (csr.csr_data_pkg.ACTION_SUBMITTED, csr.csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, csr.csr_data_pkg.ACTION_ACCEPTED, csr.csr_data_pkg.ACTION_ACCEPTED_WITH_MOD)
		)
		LOOP
			csr.sheet_pkg.ReturnToDelegees(v_act_id, r_s.sheet_id, v_startD || ' data - automatically returned to allow child sheets to be approved');
			COMMIT;
		END LOOP;

		FOR r_s IN (
			SELECT sheet_id, last_action_id, start_dtm, end_dtm
			  FROM csr.sheet_with_last_action
			 WHERE delegation_sid = r_d.delegation_sid
			   AND end_dtm > v_startD AND end_dtm <= v_endD
		)
		LOOP
			dbms_output.put_line('Processing sheet ' || r_s.sheet_id);

			FOR i IN 1..10
			LOOP
				BEGIN
					SAVEPOINT start_transaction;
					IF r_d.is_top_level = 1 AND r_s.last_action_id IN (csr.csr_data_pkg.ACTION_WAITING, csr.csr_data_pkg.ACTION_WAITING_WITH_MOD, csr.csr_data_pkg.ACTION_MERGED_WITH_MOD) THEN
						dbms_output.put_line('Merging...');
						csr.sheet_pkg.MergeLowest(v_act_id, r_s.sheet_id, 'Data - automatically merged.', 0, 1);
					ELSIF r_s.last_action_id IN (csr.csr_data_pkg.ACTION_WAITING, csr.csr_data_pkg.ACTION_WAITING_WITH_MOD, csr.csr_data_pkg.ACTION_RETURNED, csr.csr_data_pkg.ACTION_RETURNED_WITH_MOD) THEN
						dbms_output.put_line('Submitting...');
						csr.sheet_pkg.Submit(v_act_id, r_s.sheet_id, 'Data - automatically submited.', 1);
						dbms_output.put_line('and accepting...');
						csr.sheet_pkg.Accept(v_act_id, r_s.sheet_id, 'Data - automatically approved.', 1);
					ELSIF r_s.last_action_id IN (csr.csr_data_pkg.ACTION_SUBMITTED, csr.csr_data_pkg.ACTION_SUBMITTED_WITH_MOD) THEN
						dbms_output.put_line('Accepting...');
						csr.sheet_pkg.Accept(v_act_id, r_s.sheet_id, 'Data - automatically approved.', 1);
					END IF;
					COMMIT;
					EXIT;
				EXCEPTION
					WHEN deadlock_detected THEN
						ROLLBACK TO start_transaction;
				END;
			END LOOP;
		END LOOP;

		v_cnt := v_cnt + 1;
	END LOOP;
END;
/
