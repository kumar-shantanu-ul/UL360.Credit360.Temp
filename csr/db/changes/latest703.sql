-- Please update version.sql too -- this keeps clean builds in sync
define version=703
@update_header

DECLARE
	v_role_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonadmin(NULL);
	FOR r IN (
		SELECT DISTINCT app_sid
	  	  FROM csr.issue_type
	  	 WHERE issue_type_id = 6
	) LOOP
		-- Add the new issue type
		BEGIN
			INSERT INTO csr.issue_type
			  (app_sid, issue_type_id, label)
			 VALUES (r.app_sid, 7, 'Meter alarm');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		-- Add the new role to the same set of apps
		csr.role_pkg.SetRole(security_pkg.getACT, r.app_sid, 'Meter alarms', v_role_sid);
	END LOOP;
END;
/

@../issue_pkg
@../meter_alarm_pkg
@../meter_alarm_stat_pkg

@../issue_body
@../meter_alarm_body	
@../meter_alarm_stat_body

@update_tail
