-- Please update version.sql too -- this keeps clean builds in sync
define version=340
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count FROM all_tab_columns WHERE table_name = 'APPROVAL_STEP' AND owner = 'CSR' AND column_name = 'NEW_SID';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step ADD (new_sid NUMBER(10))';
	END IF;
END;
/

@..\pending_pkg.sql
@..\pending_body.sql
@..\schema_body.sql

/*

DECLARE
	v_act security_pkg.T_ACT_ID;
	v_step_sid security_pkg.T_SID_ID;
	v_csrapprovalstep_class_id security.securable_object.class_id%TYPE;
BEGIN
	v_csrapprovalstep_class_id := class_pkg.GetClassId('CSRApprovalStep');
	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	
	FOR app IN (SELECT app_sid FROM customer WHERE EXISTS (SELECT * FROM security.securable_object WHERE securable_object.sid_id = customer.app_sid AND securable_object.class_id = (SELECT class_id FROM security.securable_object_class WHERE class_name = 'CSRApp'))
			UNION SELECT app_sid FROM pending_dataset)
	LOOP
		FOR step IN (SELECT * FROM approval_step WHERE app_sid = app.app_sid AND new_sid IS NULL FOR UPDATE)
		LOOP
			securableobject_pkg.CreateSO(v_act, step.pending_dataset_id, v_csrapprovalstep_class_id, NULL, v_step_sid);
			UPDATE approval_step SET new_sid = v_step_sid WHERE approval_step_id = step.approval_step_id;
		END LOOP;
	END LOOP;
	
	user_pkg.LogOff(v_act);
END;
/

*/

@update_tail
