-- Please update version.sql too -- this keeps clean builds in sync
define version=348
@update_header

-- Switch approval step IDs to SIDs.

DECLARE
	TYPE t_string_list IS TABLE OF VARCHAR2(100);
	v_tables t_string_list := t_string_list(
		'APPROVAL_STEP',
		'APPROVAL_STEP_IND',
		'APPROVAL_STEP_MILESTONE',
		'APPROVAL_STEP_REGION',
		'APPROVAL_STEP_ROLE',
		'APPROVAL_STEP_SHEET',
		'APPROVAL_STEP_SHEET_LOG',
		'APPROVAL_STEP_USER',
		'PENDING_VAL'
		);
	v_count NUMBER;
BEGIN
	FOR i IN v_tables.FIRST .. v_tables.LAST
	LOOP
		SELECT COUNT(*) INTO v_count FROM all_tab_columns WHERE table_name = v_tables(i) AND owner = 'CSR' AND column_name = 'OLD_APPROVAL_STEP_ID';

		IF v_count = 0 THEN
		--IF v_count = 1 THEN
			EXECUTE IMMEDIATE 'CREATE TABLE csr.' || v_tables(i) || '_lee AS SELECT * FROM csr.' || v_tables(i);
			EXECUTE IMMEDIATE 'ALTER TABLE csr.' || v_tables(i) || ' ADD (old_approval_step_id NUMBER(10))';
			EXECUTE IMMEDIATE 'UPDATE csr.' || v_tables(i) || ' SET old_approval_step_id = approval_step_id';
			--EXECUTE IMMEDIATE 'ALTER TABLE csr.' || v_tables(i) || ' DROP COLUMN old_approval_step_id';
			--EXECUTE IMMEDIATE 'DROP TABLE csr.' || v_tables(i) || '_lee';
		END IF;
	END LOOP;
END;
/

DECLARE
	v_act security_pkg.T_ACT_ID;
	v_approval_step_sid security_pkg.T_SID_ID;
	v_parent_step_sid security_pkg.T_SID_ID;
BEGIN	
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step DISABLE CONSTRAINT RefAPPROVAL_STEP460 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step DISABLE CONSTRAINT RefAPPROVAL_STEP461 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_ind DISABLE CONSTRAINT RefAPPROVAL_STEP462 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_milestone DISABLE CONSTRAINT RefAPPROVAL_STEP614 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_region DISABLE CONSTRAINT RefAPPROVAL_STEP466 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_role DISABLE CONSTRAINT RefAPPROVAL_STEP895 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_sheet DISABLE CONSTRAINT RefAPPROVAL_STEP546 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_sheet_log DISABLE CONSTRAINT RefAPPROVAL_STEP_SHEET547 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_user DISABLE CONSTRAINT RefAPPROVAL_STEP468 KEEP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.pending_val DISABLE CONSTRAINT RefAPPROVAL_STEP484 KEEP INDEX';

	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	FOR step IN (SELECT app_sid, approval_step_id, parent_step_id, pending_dataset_id FROM csr.approval_step WHERE new_sid IS NULL START WITH parent_step_id IS NULL CONNECT BY parent_step_id = PRIOR approval_step_id ORDER BY level)
	LOOP
		v_parent_step_sid := NULL;

		IF step.parent_step_id IS NOT NULL THEN
			SELECT new_sid INTO v_parent_step_sid FROM csr.approval_step WHERE approval_step_id = step.parent_step_id;
		END IF;

		securableobject_pkg.CreateSO(v_act, NVL(v_parent_step_sid, step.pending_dataset_id), class_pkg.GetClassId('CSRApprovalStep'), NULL, v_approval_step_sid);
		UPDATE csr.approval_step SET new_sid = v_approval_step_sid WHERE approval_step_id = step.approval_step_id AND app_sid = step.app_sid;
	END LOOP;

	UPDATE csr.pending_val SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = pending_val.approval_step_id AND approval_step.app_sid = pending_val.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_user SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_user.approval_step_id AND approval_step.app_sid = approval_step_user.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_sheet_log SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_sheet_log.approval_step_id AND approval_step.app_sid = approval_step_sheet_log.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_sheet SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_sheet.approval_step_id AND approval_step.app_sid = approval_step_sheet.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_role SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_role.approval_step_id AND approval_step.app_sid = approval_step_role.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_region SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_region.approval_step_id AND approval_step.app_sid = approval_step_region.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_milestone SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_milestone.approval_step_id AND approval_step.app_sid = approval_step_milestone.app_sid) WHERE approval_step_id IS NOT NULL;
	UPDATE csr.approval_step_ind SET approval_step_id = (SELECT new_sid FROM csr.approval_step WHERE approval_step.approval_step_id = approval_step_ind.approval_step_id AND approval_step.app_sid = approval_step_ind.app_sid) WHERE approval_step_id IS NOT NULL;

	UPDATE csr.approval_step SET parent_step_id = (SELECT new_sid FROM csr.approval_step lookup WHERE lookup.approval_step_id = approval_step.parent_step_id AND lookup.app_sid = approval_step.app_sid) WHERE parent_step_id IS NOT NULL;
	UPDATE csr.approval_step SET approval_step_id = new_sid;

	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP460';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP461';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_ind ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP462';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_milestone ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP614';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_region ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP466';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_role ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP895';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_sheet ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP546';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_sheet_log ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP_SHEET547';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_user ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP468';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.pending_val ENABLE NOVALIDATE CONSTRAINT RefAPPROVAL_STEP484';

	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP460';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP461';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_ind ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP462';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_milestone ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP614';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_region ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP466';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_role ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP895';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_sheet ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP546';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_sheet_log ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP_SHEET547';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step_user ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP468';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.pending_val ENABLE VALIDATE CONSTRAINT RefAPPROVAL_STEP484';
END;
/

@..\pending_pkg.sql
@..\pending_body.sql
@..\schema_body.sql

@update_tail
