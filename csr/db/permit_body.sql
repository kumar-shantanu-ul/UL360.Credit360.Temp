CREATE OR REPLACE PACKAGE BODY csr.permit_pkg AS

PROCEDURE INTERNAL_AssertSystemMgr
AS
BEGIN
	IF NOT (csr_data_pkg.CheckCapability('System management') OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'The requested function is only available to built-in admin or users with system ' ||
			'management capability'
		);
	END IF;
END;

FUNCTION INTERNAL_HasFlowAccessPmt (
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE,
	in_edit_only					NUMBER DEFAULT NULL
) RETURN BOOLEAN
AS
BEGIN	
	IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;

	FOR r IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS (
			SELECT *
			  FROM compliance_permit cp
			  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id			  
			 WHERE cp.flow_item_id = in_flow_item_id
			   AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cp.app_sid
					   AND rrm.region_sid = cp.region_sid
					   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND fsr.flow_state_id = fi.current_state_id
					   AND fsr.is_editable = NVL(in_edit_only, fsr.is_editable)
				)
				OR EXISTS (
					SELECT 1
					  FROM flow_state_role fsr
					  JOIN security.act act ON act.sid_id = fsr.group_sid 
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					   AND fsr.flow_state_id = fi.current_state_id
					   AND fsr.is_editable = NVL(in_edit_only, fsr.is_editable)
				))
		 )
	) LOOP
		RETURN TRUE;
	END LOOP;
	
	RETURN FALSE;
END;


PROCEDURE INTERNAL_AssertFlowAccessPmt(
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE
)
AS
BEGIN
	IF NOT INTERNAL_HasFlowAccessPmt(in_flow_item_id) THEN	
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied accessing permit with flow item id: '|| in_flow_item_id
		);
	END IF;
END;

PROCEDURE INTERNAL_AssertCanEditFlowItem (
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE
)
AS
BEGIN	
	IF NOT INTERNAL_HasFlowAccessPmt(in_flow_item_id,1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied editing permit with flow item id '||in_flow_item_id);
	END IF;
END;


FUNCTION INTERNAL_HasFlowAccessApp (
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE,
	in_edit_only					NUMBER DEFAULT NULL
) RETURN BOOLEAN
AS
BEGIN	
	IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;

	FOR r IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS (
			SELECT *
			  FROM compliance_permit_application cpa
			  JOIN compliance_permit cp ON cpa.permit_id = cp.compliance_permit_id
			  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id			  
			 WHERE cpa.flow_item_id = in_flow_item_id
			   AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cp.app_sid
					   AND rrm.region_sid = cp.region_sid
					   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND fsr.flow_state_id = fi.current_state_id
					   AND fsr.is_editable = NVL(in_edit_only, fsr.is_editable)
				)
				OR EXISTS (
					SELECT 1
					  FROM flow_state_role fsr
					  JOIN security.act act ON act.sid_id = fsr.group_sid 
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					   AND fsr.flow_state_id = fi.current_state_id
					   AND fsr.is_editable = NVL(in_edit_only, fsr.is_editable)
				))
			)
	) LOOP
		RETURN TRUE;
	END LOOP;
	
	RETURN FALSE;
END;

PROCEDURE INTERNAL_AssertFlowAccessApp(
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE
)
AS
BEGIN
	IF NOT INTERNAL_HasFlowAccessApp(in_flow_item_id) THEN	
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied accessing the application with flow item id: '|| in_flow_item_id
		);
	END IF;
END;

PROCEDURE INTERNAL_AddAuditLogEntry (
	in_flow_item_id					IN  flow_item_audit_log.flow_item_id%TYPE,
	in_description					IN  flow_item_audit_log.description%TYPE,
	in_param_1						IN  flow_item_audit_log.param_1%TYPE,
	in_param_2						IN  flow_item_audit_log.param_2%TYPE,
	in_param_3						IN  flow_item_audit_log.param_3%TYPE,
	in_comment_text					IN  flow_item_audit_log.comment_text%TYPE
)
AS
BEGIN
	-- no security to insert into audit log
	INSERT INTO flow_item_audit_log (flow_item_audit_log_id, flow_item_id, description, param_1, param_2, param_3, comment_text)
	VALUES (flow_item_audit_log_id_seq.NEXTVAL, in_flow_item_id, in_description, in_param_1, in_param_2, in_param_3, in_comment_text);
END;

-- Gets the unique human readable doc folder name for a permit, with the format
-- "{title} ({reference})" to maintain uniqueness. If this results in a string that is too long for
-- a securable object, the title is truncated to fit. If the reference is too long to fit in this
-- template, the reference alone is used as the doc folder name (it shouldn't overflow).
FUNCTION INTERNAL_DocFolderName(
	in_permit_id					IN security_pkg.T_SID_ID
)
RETURN security_pkg.T_SO_NAME
AS
	c_max_length					CONSTANT NUMBER := 255;

	v_permit_ref					compliance_permit.permit_reference%TYPE;
	v_permit_title					compliance_permit.title%TYPE;
	v_suffix						security_pkg.T_SO_NAME;
	v_formatted						security_pkg.T_SO_NAME;
	v_suffix_bytes					NUMBER;
	v_title_bytes					NUMBER;
BEGIN
	SELECT NVL(permit_reference, compliance_permit_id), title
	  INTO v_permit_ref, v_permit_title
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;

	v_suffix := ' (' || v_permit_ref || ')';
	v_suffix_bytes := LENGTHB(v_suffix);
	v_title_bytes := LENGTHB(v_permit_title);

	IF v_suffix_bytes > c_max_length THEN
		-- It is unlikely, but the permit reference may be too long for fancy formatting
		v_formatted := v_permit_ref;
	ELSIF v_suffix_bytes + v_title_bytes > c_max_length THEN
		-- Truncate the title to fit
		v_formatted := RTRIM(SUBSTRB(v_permit_title, 1, c_max_length - v_suffix_bytes)) || v_suffix;
	ELSE
		v_formatted := v_permit_title || v_suffix;
	END IF;

	RETURN REPLACE(v_formatted, '/', NULL);
END;

FUNCTION IsModuleEnabled RETURN NUMBER
AS
BEGIN
	FOR r IN (
		SELECT NULL 
		  FROM compliance_options 
		 WHERE permit_flow_sid IS NOT NULL
	) LOOP
		RETURN 1;
	END LOOP;

	RETURN 0;
END;

PROCEDURE INTERNAL_AddManagersToIssue(
	in_issue_id						IN  issue.issue_id%TYPE
)
AS 
	v_involve_managers				compliance_options.auto_involve_managers%TYPE;
BEGIN
	SELECT auto_involve_managers
	  INTO v_involve_managers
	  FROM compliance_options
     WHERE app_sid = security_pkg.GetApp;

	IF v_involve_managers = 1 THEN
		DECLARE 
			v_user_cur				SYS_REFCURSOR;			
			v_managers_group		security_pkg.T_SID_ID;
		BEGIN		
			BEGIN
				v_managers_group := securableobject_pkg.GetSidFromPath(
					in_act					=> security_pkg.GetAct,
					in_parent_sid_id		=> security_pkg.GetApp,
					in_path					=> 'Groups/EHS Managers'
				);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					RETURN;
			END;
			
			FOR u IN (SELECT sid_id FROM TABLE(group_pkg.GetMembersAsTableUNSEC(v_managers_group)))
			LOOP
				issue_pkg.AddUser(
					in_act_id			=> security_pkg.GetAct, 
					in_issue_id			=> in_issue_id,
					in_user_sid			=> u.sid_id,
					out_cur				=> v_user_cur
				);
			END LOOP;
		END;
	END IF;
END;


FUNCTION GetFlowRegionSids(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE
AS
	v_flow_alert_class				flow.flow_alert_class%TYPE;
	v_region_sids					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
		SELECT f.flow_alert_class
		  INTO v_flow_alert_class
		  FROM flow_item fi
		  JOIN flow f
			ON f.flow_sid = fi.flow_sid
		 WHERE fi.flow_item_id = in_flow_item_id;

		IF LOWER(v_flow_alert_class) = 'permit' THEN
			SELECT region_sid
			  BULK COLLECT INTO v_region_sids
			  FROM compliance_permit
			 WHERE app_sid = security_pkg.GetApp
			   AND flow_item_id = in_flow_item_id;
		ELSIF LOWER(v_flow_alert_class) = 'application' THEN
			SELECT cp.region_sid
			  BULK COLLECT INTO v_region_sids
			  FROM compliance_permit_application cpa
			  JOIN compliance_permit cp
				ON cpa.permit_id = cp.compliance_permit_id
			 WHERE cp.app_sid = security.security_pkg.GetApp
			   AND cpa.flow_item_id = in_flow_item_id;
		ELSIF LOWER(v_flow_alert_class) = 'condition' THEN
			v_region_sids := compliance_pkg.GetFlowRegionSids(in_flow_item_id);
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Unexpected flow alert class');
		END IF;

	RETURN v_region_sids;
END;


FUNCTION CreatePermitWorkflow
RETURN security_pkg.T_SID_ID
AS
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_wf_ct_sid						security.security_pkg.T_SID_ID;
BEGIN
	-- First try to find an existing workflow
	BEGIN
		SELECT flow_sid 
		  INTO v_workflow_sid
		  FROM flow 
		 WHERE flow_alert_class = 'permit'
		   AND trash_pkg.IsInTrash(security_pkg.GetAct, flow_sid) = 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			v_workflow_sid := NULL;

		WHEN TOO_MANY_ROWS THEN
			-- No reasonable way to select from multiple workflows, just give up
			RAISE; 
	END;

	IF v_workflow_sid IS NOT NULL THEN
		RETURN v_workflow_sid;
	END IF;

	v_wf_ct_sid:= securableobject_pkg.GetSIDFromPath(
		SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');	

	-- create our workflow
	flow_pkg.CreateFlow(
		in_label			=> 'Permit Workflow', 
		in_parent_sid		=> v_wf_ct_sid, 
		in_flow_alert_class	=> 'permit',
		out_flow_sid		=> v_workflow_sid
	);
	
	compliance_setup_pkg.UpdatePermitWorkflow(v_workflow_sid, 'permit');

	RETURN v_workflow_sid;
END;

PROCEDURE GetActivityTypes(
	out_cur							OUT SYS_REFCURSOR,
	out_sub_typ_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security for basedata
	
	OPEN out_cur FOR
		SELECT activity_type_id, description, pos
		  FROM compliance_activity_type
		 ORDER BY pos, LOWER(description);
		 
	OPEN out_sub_typ_cur FOR
		SELECT activity_type_id, activity_sub_type_id, description, pos
		  FROM compliance_activity_sub_type
		 ORDER BY activity_type_id, pos, LOWER(description);
END;

PROCEDURE SaveActivityType(
	in_activity_type_id				IN  compliance_activity_type.activity_type_id%TYPE,
	in_description					IN  compliance_activity_type.description%TYPE,
	in_pos							IN  compliance_activity_type.pos%TYPE,
	out_activity_type_id			OUT compliance_activity_type.activity_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_activity_type_id IS NULL THEN
		INSERT INTO compliance_activity_type (activity_type_id, description, pos)
			VALUES (compliance_activity_type_seq.NEXTVAL, in_description, in_pos)
			RETURNING activity_type_id INTO out_activity_type_id;
	ELSE
		UPDATE compliance_activity_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE activity_type_id = in_activity_type_id;
		 
		out_activity_type_id := in_activity_type_id;
	END IF;
END;

PROCEDURE SaveActivitySubType(
	in_activity_type_id				IN  compliance_activity_sub_type.activity_type_id%TYPE,
	in_activity_sub_type_id			IN  compliance_activity_sub_type.activity_sub_type_id%TYPE,
	in_description					IN  compliance_activity_sub_type.description%TYPE,
	in_pos							IN  compliance_activity_sub_type.pos%TYPE,
	out_activity_sub_type_id		OUT compliance_activity_sub_type.activity_sub_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_activity_sub_type_id IS NULL THEN
		INSERT INTO compliance_activity_sub_type (activity_type_id, activity_sub_type_id, description, pos)
			VALUES (in_activity_type_id, compliance_activ_sub_type_seq.NEXTVAL, in_description, in_pos)
			RETURNING activity_sub_type_id INTO out_activity_sub_type_id;
	ELSE
		UPDATE compliance_activity_sub_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE activity_type_id = in_activity_type_id
		   AND activity_sub_type_id = in_activity_sub_type_id;
		 
		out_activity_sub_type_id := in_activity_sub_type_id;
	END IF;
END;

PROCEDURE SetActivitySubTypes(
	in_activity_type_id				IN  compliance_activity_sub_type.activity_type_id%TYPE,
	in_sub_type_ids_to_keep			IN  security_pkg.T_SID_IDS
)
AS
	v_keeper_id_tbl					security.T_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;

	IF in_sub_type_ids_to_keep IS NULL OR (in_sub_type_ids_to_keep.COUNT = 1 AND in_sub_type_ids_to_keep(1) IS NULL) THEN
		-- all removed
		DELETE FROM compliance_activity_sub_type
		 WHERE activity_type_id = in_activity_type_id;
	ELSE
		v_keeper_id_tbl := security_pkg.SidArrayToTable(in_sub_type_ids_to_keep);
		DELETE FROM compliance_activity_sub_type
		 WHERE activity_type_id = in_activity_type_id
		   AND activity_sub_type_id NOT IN (
			SELECT column_value FROM TABLE(v_keeper_id_tbl)
		   );
	END IF;
END;

PROCEDURE DeleteActivityType(
	in_activity_type_id				IN  compliance_activity_type.activity_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	DELETE FROM compliance_activity_sub_type
		  WHERE activity_type_id = in_activity_type_id;
	
	DELETE FROM compliance_activity_type
		  WHERE activity_type_id = in_activity_type_id;
END;

PROCEDURE GetApplicationTypes(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security for basedata
	
	OPEN out_cur FOR
		SELECT application_type_id, description, pos
		  FROM compliance_application_type
		 ORDER BY pos, LOWER(description);
END;

PROCEDURE SaveApplicationType(
	in_application_type_id			IN  compliance_application_type.application_type_id%TYPE,
	in_description					IN  compliance_application_type.description%TYPE,
	in_pos							IN  compliance_application_type.pos%TYPE,
	out_application_type_id			OUT compliance_application_type.application_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_application_type_id IS NULL THEN
		INSERT INTO compliance_application_type (application_type_id, description, pos)
			VALUES (compliance_application_tp_seq.NEXTVAL, in_description, in_pos)
			RETURNING application_type_id INTO out_application_type_id;
	ELSE
		UPDATE compliance_application_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE application_type_id = in_application_type_id;
		 
		out_application_type_id := in_application_type_id;
	END IF;
END;

PROCEDURE DeleteApplicationType(
	in_application_type_id			IN  compliance_application_type.application_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	DELETE FROM compliance_application_type
		  WHERE application_type_id = in_application_type_id;
END;

PROCEDURE GetConditionTypes(
	out_cur							OUT SYS_REFCURSOR,
	out_sub_typ_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security for basedata
	
	OPEN out_cur FOR
		SELECT condition_type_id, description, pos
		  FROM compliance_condition_type
		 ORDER BY pos, LOWER(description);
		 
	OPEN out_sub_typ_cur FOR
		SELECT condition_type_id, condition_sub_type_id, description, pos
		  FROM compliance_condition_sub_type
		 ORDER BY condition_type_id, pos, LOWER(description);
END;

PROCEDURE SaveConditionType(
	in_condition_type_id			IN  compliance_condition_type.condition_type_id%TYPE,
	in_description					IN  compliance_condition_type.description%TYPE,
	in_pos							IN  compliance_condition_type.pos%TYPE,
	out_condition_type_id			OUT compliance_condition_type.condition_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_condition_type_id IS NULL THEN
		INSERT INTO compliance_condition_type (condition_type_id, description, pos)
			VALUES (compliance_condition_type_seq.NEXTVAL, in_description, in_pos)
			RETURNING condition_type_id INTO out_condition_type_id;
	ELSE
		UPDATE compliance_condition_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE condition_type_id = in_condition_type_id;
		 
		out_condition_type_id := in_condition_type_id;
	END IF;
END;

PROCEDURE SaveConditionSubType(
	in_condition_type_id			IN  compliance_condition_sub_type.condition_type_id%TYPE,
	in_condition_sub_type_id		IN  compliance_condition_sub_type.condition_sub_type_id%TYPE,
	in_description					IN  compliance_condition_sub_type.description%TYPE,
	in_pos							IN  compliance_condition_sub_type.pos%TYPE,
	out_condition_sub_type_id		OUT compliance_condition_sub_type.condition_sub_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_condition_sub_type_id IS NULL THEN
		INSERT INTO compliance_condition_sub_type (condition_type_id, condition_sub_type_id, description, pos)
			VALUES (in_condition_type_id, compliance_activ_sub_type_seq.NEXTVAL, in_description, in_pos)
			RETURNING condition_sub_type_id INTO out_condition_sub_type_id;
	ELSE
		UPDATE compliance_condition_sub_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE condition_type_id = in_condition_type_id
		   AND condition_sub_type_id = in_condition_sub_type_id;
		 
		out_condition_sub_type_id := in_condition_sub_type_id;
	END IF;
END;

PROCEDURE SetConditionSubTypes(
	in_condition_type_id			IN  compliance_condition_sub_type.condition_type_id%TYPE,
	in_sub_type_ids_to_keep			IN  security_pkg.T_SID_IDS
)
AS
	v_keeper_id_tbl					security.T_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;

	IF in_sub_type_ids_to_keep IS NULL OR (in_sub_type_ids_to_keep.COUNT = 1 AND in_sub_type_ids_to_keep(1) IS NULL) THEN
		-- all removed
		DELETE FROM compliance_condition_sub_type
		 WHERE condition_type_id = in_condition_type_id;
	ELSE
		v_keeper_id_tbl := security_pkg.SidArrayToTable(in_sub_type_ids_to_keep);
		DELETE FROM compliance_condition_sub_type
		 WHERE condition_type_id = in_condition_type_id
		   AND condition_sub_type_id NOT IN (
			SELECT column_value FROM TABLE(v_keeper_id_tbl)
		   );
	END IF;
END;

PROCEDURE DeleteConditionType(
	in_condition_type_id			IN  compliance_condition_type.condition_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	DELETE FROM compliance_condition_sub_type
		  WHERE condition_type_id = in_condition_type_id;
	
	DELETE FROM compliance_condition_type
		  WHERE condition_type_id = in_condition_type_id;
END;

PROCEDURE GetPermitTypes(
	out_cur							OUT SYS_REFCURSOR,
	out_sub_typ_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security for basedata
	
	OPEN out_cur FOR
		SELECT permit_type_id, description, pos
		  FROM compliance_permit_type
		 ORDER BY pos, LOWER(description);
		 
	OPEN out_sub_typ_cur FOR
		SELECT permit_type_id, permit_sub_type_id, description, pos
		  FROM compliance_permit_sub_type
		 ORDER BY permit_type_id, pos, LOWER(description);
END;

PROCEDURE SavePermitType(
	in_permit_type_id				IN  compliance_permit_type.permit_type_id%TYPE,
	in_description					IN  compliance_permit_type.description%TYPE,
	in_pos							IN  compliance_permit_type.pos%TYPE,
	out_permit_type_id				OUT compliance_permit_type.permit_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_permit_type_id IS NULL THEN
		INSERT INTO compliance_permit_type (permit_type_id, description, pos)
			VALUES (compliance_permit_type_seq.NEXTVAL, in_description, in_pos)
			RETURNING permit_type_id INTO out_permit_type_id;
	ELSE
		UPDATE compliance_permit_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE permit_type_id = in_permit_type_id;
		 
		out_permit_type_id := in_permit_type_id;
	END IF;
END;

PROCEDURE SavePermitSubType(
	in_permit_type_id				IN  compliance_permit_sub_type.permit_type_id%TYPE,
	in_permit_sub_type_id			IN  compliance_permit_sub_type.permit_sub_type_id%TYPE,
	in_description					IN  compliance_permit_sub_type.description%TYPE,
	in_pos							IN  compliance_permit_sub_type.pos%TYPE,
	out_permit_sub_type_id			OUT compliance_permit_sub_type.permit_sub_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	IF in_permit_sub_type_id IS NULL THEN
		INSERT INTO compliance_permit_sub_type (permit_type_id, permit_sub_type_id, description, pos)
			VALUES (in_permit_type_id, compliance_activ_sub_type_seq.NEXTVAL, in_description, in_pos)
			RETURNING permit_sub_type_id INTO out_permit_sub_type_id;
	ELSE
		UPDATE compliance_permit_sub_type
		   SET description = in_description,
			   pos = in_pos
		 WHERE permit_type_id = in_permit_type_id
		   AND permit_sub_type_id = in_permit_sub_type_id;
		 
		out_permit_sub_type_id := in_permit_sub_type_id;
	END IF;
END;

PROCEDURE SetPermitSubTypes(
	in_permit_type_id				IN  compliance_permit_sub_type.permit_type_id%TYPE,
	in_sub_type_ids_to_keep			IN  security_pkg.T_SID_IDS
)
AS
	v_keeper_id_tbl					security.T_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;

	IF in_sub_type_ids_to_keep IS NULL OR (in_sub_type_ids_to_keep.COUNT = 1 AND in_sub_type_ids_to_keep(1) IS NULL) THEN
		-- all removed
		DELETE FROM compliance_permit_sub_type
		 WHERE permit_type_id = in_permit_type_id;
	ELSE
		v_keeper_id_tbl := security_pkg.SidArrayToTable(in_sub_type_ids_to_keep);
		DELETE FROM compliance_permit_sub_type
		 WHERE permit_type_id = in_permit_type_id
		   AND permit_sub_type_id NOT IN (
			SELECT column_value FROM TABLE(v_keeper_id_tbl)
		   );
	END IF;
END;

PROCEDURE DeletePermitType(
	in_permit_type_id				IN  compliance_permit_type.permit_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit permit types.');
	END IF;
	
	DELETE FROM compliance_permit_sub_type
		  WHERE permit_type_id = in_permit_type_id;
	
	DELETE FROM compliance_permit_type
		  WHERE permit_type_id = in_permit_type_id;
END;

PROCEDURE SavePermit(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	in_region_sid					IN	compliance_permit.region_sid%TYPE,
	in_title						IN	compliance_permit.title%TYPE,
	in_activity_type_id				IN	compliance_permit.activity_type_id%TYPE,
	in_activity_sub_type_id			IN	compliance_permit.activity_sub_type_id%TYPE,
	in_activity_start_dtm			IN	compliance_permit.activity_start_dtm%TYPE,
	in_activity_end_dtm				IN	compliance_permit.activity_end_dtm%TYPE,
	in_activity_details				IN	compliance_permit.activity_details%TYPE,
	in_permit_ref					IN	compliance_permit.permit_reference%TYPE,
	in_permit_type_id				IN	compliance_permit.permit_type_id%TYPE,
	in_permit_sub_type_id			IN	compliance_permit.permit_sub_type_id%TYPE,
	in_site_commissioning_required	IN	compliance_permit.site_commissioning_required%TYPE,
	in_site_commissioning_dtm 		IN	compliance_permit.site_commissioning_dtm%TYPE,
	in_permit_start_dtm				IN	compliance_permit.permit_start_dtm%TYPE,
	in_permit_end_dtm				IN	compliance_permit.permit_end_dtm%TYPE,
	in_is_major_change				IN	NUMBER,
	in_change_reason				IN  VARCHAR2,
	out_permit_id					OUT	compliance_permit.compliance_permit_id%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_flow_item_id					security_pkg.T_SID_ID;
	v_permit_flow_state_nature_id	flow_state.flow_state_nature_id%TYPE;
	v_default_state_id				security_pkg.T_SID_ID;
	v_doc_folder_sid				security_pkg.T_SID_ID;
	v_update_title					NUMBER(1);
BEGIN
	compliance_pkg.AssertComplianceMgr;
	
	IF in_permit_id IS NULL THEN
		SELECT permit_flow_sid
		  INTO v_flow_sid
		  FROM compliance_options;
		
		flow_pkg.AddFlowItem(v_flow_sid, v_flow_item_id);
	
		INSERT INTO compliance_permit(compliance_permit_id, region_sid, flow_item_id, title, permit_reference,
			activity_start_dtm, activity_end_dtm, permit_type_id, permit_sub_type_id, permit_start_dtm, permit_end_dtm,
			activity_type_id, activity_sub_type_id, activity_details, site_commissioning_required, site_commissioning_dtm)
		VALUES(compliance_permit_seq.nextval, in_region_sid, v_flow_item_id, in_title, in_permit_ref, in_activity_start_dtm,
			in_activity_end_dtm, in_permit_type_id, in_permit_sub_type_id, in_permit_start_dtm, in_permit_end_dtm, in_activity_type_id,
			in_activity_sub_type_id, in_activity_details, in_site_commissioning_required, in_site_commissioning_dtm)
		RETURNING compliance_permit_id INTO out_permit_id;
		
		flow_pkg.SetItemStateNature(
			in_flow_item_id			=> v_flow_item_id,
			in_to_nature			=> csr_data_pkg.NATURE_PERMIT_APPLICATION, 
			in_comment				=> 'Created'
		);
	ELSE
		SELECT COUNT(*)
		  INTO v_update_title
		  FROM compliance_permit
		 WHERE compliance_permit_id = in_permit_id
		   AND (permit_reference != in_permit_ref OR title != in_title);
		
		UPDATE compliance_permit
		   SET region_sid = in_region_sid,
			   title = in_title,
			   permit_reference = in_permit_ref,
			   activity_start_dtm = in_activity_start_dtm,
			   activity_end_dtm = in_activity_end_dtm,
			   permit_type_id = in_permit_type_id,
			   permit_sub_type_id = in_permit_sub_type_id,
			   site_commissioning_required = in_site_commissioning_required,
			   site_commissioning_dtm = in_site_commissioning_dtm,
			   permit_start_dtm = in_permit_start_dtm,
			   permit_end_dtm = in_permit_end_dtm,
			   activity_type_id = in_activity_type_id,
			   activity_sub_type_id = in_activity_sub_type_id,
			   activity_details = in_activity_details
		WHERE compliance_permit_id = in_permit_id;
		
		FOR r IN (SELECT issue_id
					FROM issue
				   WHERE permit_id = in_permit_id 
			         AND issue_due_source_id IN (
							csr_data_pkg.ISSUE_SOURCE_PERMIT_START,
							csr_data_pkg.ISSUE_SOURCE_PERMIT_EXPIRY,
							csr_data_pkg.ISSUE_SOURCE_ACTIVITY_START,
							csr_data_pkg.ISSUE_SOURCE_ACTIVITY_END,
							csr_data_pkg.ISSUE_SOURCE_PERMIT_CMN_DTM
						 ))
		LOOP
			issue_pkg.RefreshRelativeDueDtm(in_issue_id => r.issue_id);
		END LOOP;
		
		SELECT cp.flow_item_id, fs.flow_state_nature_id
	 	  INTO v_flow_item_id, v_permit_flow_state_nature_id
	 	  FROM compliance_permit cp
	 	  JOIN flow_item fi ON fi.flow_item_id = cp.flow_item_id
	 	  JOIN flow_state fs ON fs.flow_state_id = fi.current_state_id
	 	 WHERE cp.compliance_permit_id = in_permit_id;
		 	 	
	 	IF v_permit_flow_state_nature_id = csr_data_pkg.NATURE_PERMIT_ACTIVE AND in_is_major_change > 0 THEN 
			flow_pkg.SetItemStateNature(
				in_flow_item_id			=> v_flow_item_id,
				in_to_nature			=> csr_data_pkg.NATURE_PERMIT_UPDATED, 
				in_comment				=> in_change_reason
			);
		ELSE
			INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Permit changed.', null, null, null, in_change_reason);
	 	END IF;
				   
		IF v_update_title = 1 THEN 
			BEGIN
				SELECT doc_folder_sid
				  INTO v_doc_folder_sid
				  FROM doc_folder
				 WHERE permit_item_id = in_permit_id
				   AND is_system_managed = 1;
			
				securableobject_pkg.RenameSO(
					in_act_id			=> security_pkg.GetAct(),
					in_sid_id			=> v_doc_folder_sid,
					in_object_name		=> REPLACE(in_title || ' (' || in_permit_ref || ')', '/', NULL)
				);
				
				FOR r IN (
					SELECT lang
					  FROM v$customer_lang
				)
				LOOP
					doc_folder_pkg.SetFolderTranslation(
						in_folder_sid		=>	v_doc_folder_sid,
						in_lang				=>	r.lang,
						in_translated		=>	in_title || ' (' || in_permit_ref || ')'
					);
				END LOOP;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
		END IF;
		out_permit_id := in_permit_id;
	END IF;
END;

PROCEDURE GetPermit(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_predecessors				OUT SYS_REFCURSOR,
	out_successors					OUT SYS_REFCURSOR
)
AS
	v_flow_item_id					compliance_permit.flow_item_id%TYPE;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;

	INTERNAL_AssertFlowAccessPmt(v_flow_item_id);

	OPEN out_cur FOR
		SELECT cp.compliance_permit_id, cp.region_sid, cp.flow_item_id, cp.title, 
			   cp.permit_reference, cp.activity_start_dtm, cp.activity_end_dtm, cp.permit_type_id, 
			   cp.permit_sub_type_id, cp.permit_start_dtm, cp.permit_end_dtm, cp.activity_type_id, 
			   cp.activity_sub_type_id, cp.activity_details, cpt.description permit_type_desc, 
			   cp.site_commissioning_required, cp.site_commissioning_dtm,
			   pst.description permit_sub_type_desc, cat.description activity_type_desc,
			   cast.description activity_sub_type_desc, r.description region_desc, fs.label flow_state_label,
			   fi.current_state_id, fs.flow_state_nature_id
		  FROM compliance_permit cp
		  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  JOIN v$region r
			ON r.app_sid = cp.app_sid AND r.region_sid = cp.region_sid
		  LEFT JOIN compliance_permit_type cpt
			ON cpt.app_sid = cp.app_sid AND cpt.permit_type_id = cp.permit_type_id
		  LEFT JOIN compliance_permit_sub_type pst
			ON pst.app_sid = cp.app_sid AND pst.permit_sub_type_id = cp.permit_sub_type_id AND pst.permit_type_id = cp.permit_type_id
		  LEFT JOIN compliance_activity_type cat
			ON cat.app_sid = cp.app_sid AND cat.activity_type_id = cp.activity_type_id
		  LEFT JOIN compliance_activity_sub_type cast
			ON cast.app_sid = cp.app_sid AND cast.activity_sub_type_id = cp.activity_sub_type_id AND cast.activity_type_id = cp.activity_type_id
		 WHERE cp.compliance_permit_id = in_permit_id;

	GetPredecessors(in_permit_id, out_predecessors);
	GetSuccessors(in_permit_id, out_successors);
END;

PROCEDURE GetAllPermits(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Flow permission checks done in query.
	
	OPEN out_cur FOR
		SELECT cp.title "Permit Title", cp.activity_details "Details", r.description "Region", cat.description "Activity Type", cast.description "Activity Sub Type",
			   cp.activity_start_dtm "Activity Start Date", cp.activity_end_dtm "Activity End Date",
			   cpt.description "Permit Type", pst.description "Permit Sub Type",
			   cp.permit_start_dtm "Permit Start Date", cp.permit_end_dtm "Permit Expiry Date",
			   cp.permit_reference "Permit Reference",
			   CASE WHEN cp.site_commissioning_required=1 THEN 'Y' ELSE 'N' END "Site Commissioning Required", cp.site_commissioning_dtm "Site Commissioning Date",
			   fs.lookup_key "Workflow State"
		  FROM compliance_permit cp
		  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  JOIN v$region r
			ON r.app_sid = cp.app_sid AND r.region_sid = cp.region_sid
		  LEFT JOIN compliance_permit_type cpt
			ON cpt.app_sid = cp.app_sid AND cpt.permit_type_id = cp.permit_type_id
		  LEFT JOIN compliance_permit_sub_type pst
			ON pst.app_sid = cp.app_sid AND pst.permit_sub_type_id = cp.permit_sub_type_id and cp.permit_type_id = pst.permit_type_id
		  LEFT JOIN compliance_activity_type cat
			ON cat.app_sid = cp.app_sid AND cat.activity_type_id = cp.activity_type_id
		  LEFT JOIN compliance_activity_sub_type cast
			ON cast.app_sid = cp.app_sid AND cast.activity_sub_type_id = cp.activity_sub_type_id and cp.activity_type_id = cast.activity_type_id
		   WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
 			AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cp.app_sid
					   AND rrm.region_sid = cp.region_sid
					   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND fsr.flow_state_id = fi.current_state_id
					   AND fsr.is_editable = 1
				)
				OR EXISTS (
					SELECT 1
					  FROM flow_state_role fsr
					  JOIN security.act act ON act.sid_id = fsr.group_sid 
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					   AND fsr.flow_state_id = fi.current_state_id
					   AND fsr.is_editable =1
				));

END;

PROCEDURE GetPermitByRef(
	in_reference					IN	compliance_permit.permit_reference%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_predecessors				OUT	SYS_REFCURSOR,
	out_successors					OUT	SYS_REFCURSOR
)
AS
	v_permit_id						compliance_permit.compliance_permit_id%TYPE;
BEGIN
	SELECT MIN(compliance_permit_id)
	  INTO v_permit_id
	  FROM compliance_permit
	 WHERE permit_reference = in_reference;

	IF v_permit_id IS NULL THEN
		OPEN out_cur FOR
			SELECT NULL
			  FROM dual;
		
		RETURN;
	END IF;
	 
	GetPermit(
		in_permit_id		=> v_permit_id, 
		out_cur				=> out_cur,
		out_predecessors	=> out_predecessors,
		out_successors		=> out_successors
	);
END;

PROCEDURE GetPermitTabs(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_is_super_admin				NUMBER := csr_user_pkg.IsSuperAdmin;
BEGIN
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.tab_sid, 
			   p.form_path, p.group_key, p.control_lookup_keys, p.use_reporting_period, 
			   p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid, pt.tab_label, pt.pos
		  FROM plugin p
		  JOIN compliance_permit_tab pt ON p.plugin_id = pt.plugin_id
		  JOIN compliance_permit_tab_group ptg ON pt.plugin_id = ptg.plugin_id
		  LEFT JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) ug
			ON ptg.group_sid = ug.column_value
		 WHERE (in_permit_id IS NULL 
				OR v_is_super_admin = 1
				OR (ptg.group_sid IS NOT NULL AND ug.column_value IS NOT NULL))
		 GROUP BY 
			   p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, pt.tab_label, 
			   pt.pos, p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, 
			   p.use_reporting_period, p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid
		 ORDER BY pt.pos;
END;

PROCEDURE SavePermitTab(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_tab_label					IN	compliance_permit_tab.tab_label%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE
)
AS
	v_pos 							meter_tab.pos%TYPE := in_pos;
BEGIN
	INTERNAL_AssertSystemMgr();
	
	IF in_pos IS NULL OR in_pos < 0 THEN
		SELECT NVL(MAX(pos) + 1, 1) 
		  INTO v_pos 
		  FROM compliance_permit_tab;
	END IF;
	 
	BEGIN
		INSERT INTO compliance_permit_tab (plugin_type_id, plugin_id, pos, tab_label)
			VALUES (csr_data_pkg.PLUGIN_TYPE_PERMIT_TAB, in_plugin_id, v_pos, in_tab_label);
			
		-- default access
		INSERT INTO compliance_permit_tab_group (plugin_id, group_sid)
			 VALUES (
				in_plugin_id, 
				security.securableobject_pkg.GetSidFromPath(
					security.security_pkg.GetAct, 
					security.security_pkg.GetApp, 
					'groups/RegisteredUsers'
				)
			);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE compliance_permit_tab
			   SET tab_label = in_tab_label,
				   pos = v_pos
			 WHERE plugin_id = in_plugin_id;
	END;
END;

PROCEDURE SavePermitTab(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_tab_label					IN	compliance_permit_tab.tab_label%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	SavePermitTab(
		in_plugin_id => in_plugin_id,
		in_tab_label => in_tab_label,
		in_pos => in_pos
	);

	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
			   p.details, p.preview_image_path, pt.pos, pt.tab_label
		  FROM plugin p
		  JOIN compliance_permit_tab pt ON p.plugin_id = pt.plugin_id
		 WHERE pt.plugin_id = in_plugin_id;
END;

PROCEDURE RemovePermitTab(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE
)
AS
BEGIN
	INTERNAL_AssertSystemMgr();

	DELETE FROM compliance_permit_tab_group
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;
	   
	DELETE FROM compliance_permit_tab
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetPermitHeaders(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_is_super_admin				NUMBER := csr_user_pkg.IsSuperAdmin;
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.tab_sid, 
			   p.form_path, p.group_key, p.control_lookup_keys, p.use_reporting_period, 
			   p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid, pt.pos, p.description
		  FROM plugin p
		  JOIN compliance_permit_header pt ON p.plugin_id = pt.plugin_id
		  JOIN compliance_permit_header_group ptg ON pt.plugin_id = ptg.plugin_id
		  LEFT JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) ug
			ON ptg.group_sid = ug.column_value
		 WHERE (in_permit_id IS NULL 
				OR v_is_super_admin = 1
				OR (ptg.group_sid IS NOT NULL AND ug.column_value IS NOT NULL))
		 ORDER BY pt.pos;
END;

PROCEDURE SavePermitHeader(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE
)
AS
	v_pos 							compliance_permit_tab.pos%TYPE := in_pos;
BEGIN
	INTERNAL_AssertSystemMgr();
	
	IF in_pos IS NULL OR in_pos < 0 THEN
		SELECT NVL(MAX(pos) + 1, 1) 
		  INTO v_pos 
		  FROM compliance_permit_header;
	END IF;
	 
	BEGIN
		INSERT INTO compliance_permit_header (plugin_type_id, plugin_id, pos)
			VALUES (csr_data_pkg.PLUGIN_TYPE_PERMIT_HEADER, in_plugin_id, v_pos);
			
		-- default access
		INSERT INTO compliance_permit_header_group (plugin_id, group_sid)
			 VALUES (
				in_plugin_id, 
				security.securableobject_pkg.GetSidFromPath(
					security.security_pkg.GetAct, 
					security.security_pkg.GetApp, 
					'groups/RegisteredUsers'
				)
			);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE compliance_permit_header
			   SET pos = v_pos
			 WHERE plugin_id = in_plugin_id;
	END;
END;

PROCEDURE SavePermitHeader(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	SavePermitHeader(
		in_plugin_id => in_plugin_id,
		in_pos => in_pos
	);

	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
			   p.details, p.preview_image_path, pt.pos
		  FROM plugin p
		  JOIN compliance_permit_header pt ON p.plugin_id = pt.plugin_id
		 WHERE pt.plugin_id = in_plugin_id;
END;

PROCEDURE RemovePermitHeader(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE
)
AS
BEGIN
	INTERNAL_AssertSystemMgr();

	DELETE FROM compliance_permit_header_group
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;
	   
	DELETE FROM compliance_permit_header
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SaveApplication(
	in_application_id				IN	compliance_permit_application.permit_application_id%TYPE,
	in_permit_id					IN	compliance_permit_application.permit_id%TYPE,
	in_application_reference		IN	compliance_permit_application.application_reference%TYPE,
	in_title						IN	compliance_permit_application.title%TYPE,
	in_application_type_id			IN	compliance_permit_application.application_type_id%TYPE,
	in_submission_dtm				IN	compliance_permit_application.submission_dtm%TYPE,
	in_duly_made_dtm				IN	compliance_permit_application.duly_made_dtm%TYPE,
	in_determined_dtm				IN	compliance_permit_application.determined_dtm%TYPE,
	in_notes						IN	compliance_permit_application.notes%TYPE,
	in_app_result_id				IN	compliance_permit_application.compl_permit_app_status_id%TYPE,
	in_paused_dtm					IN	compl_permit_application_pause.paused_dtm%TYPE DEFAULT NULL,
	in_resumed_dtm					IN	compl_permit_application_pause.resumed_dtm%TYPE DEFAULT NULL,
	out_application_id				OUT	compliance_permit_application.permit_application_id%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_flow_item_id					security_pkg.T_SID_ID;
	v_permit_flow_item_id			security_pkg.T_SID_ID;
	v_currently_paused				compl_permit_application_pause.paused_dtm%TYPE;
BEGIN
	compliance_pkg.AssertComplianceMgr;
	
	SELECT flow_item_id 
	  INTO v_permit_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;

	IF in_application_id IS NULL THEN
		SELECT application_flow_sid
		  INTO v_flow_sid
		  FROM compliance_options;
		
		flow_pkg.AddFlowItem(v_flow_sid, v_flow_item_id);
		
		INSERT INTO compliance_permit_application(permit_application_id, permit_id, notes, application_reference,
			application_type_id, submission_dtm, duly_made_dtm, determined_dtm, title, flow_item_id, compl_permit_app_status_id)
		VALUES(compliance_permit_appl_seq.nextval, in_permit_id, in_notes, in_application_reference, in_application_type_id,
			in_submission_dtm, in_duly_made_dtm, in_determined_dtm, in_title, v_flow_item_id, in_app_result_id)
		RETURNING permit_application_id INTO out_application_id;
		
		flow_pkg.SetItemStateNature(
			in_flow_item_id			=> v_flow_item_id,
			in_to_nature			=> csr_data_pkg.NATURE_APPLIC_PRE_APPLICATION, 
			in_comment				=> 'Created'
		);
		
		INTERNAL_AddAuditLogEntry(v_permit_flow_item_id, 'Application with ref {0} and id {1} linked to permit.', in_application_reference, out_application_id, null, null);
		
	ELSE
		UPDATE compliance_permit_application
		   SET permit_id = in_permit_id,
			   application_reference = in_application_reference,
			   title = in_title,
			   submission_dtm = in_submission_dtm,
			   duly_made_dtm = in_duly_made_dtm,
			   determined_dtm = in_determined_dtm,
			   notes = in_notes,
			   compl_permit_app_status_id = in_app_result_id
		WHERE permit_application_id = in_application_id
		RETURNING flow_item_id INTO v_flow_item_id;
		
		flow_pkg.SetItemStateNature(
			in_flow_item_id			=> v_permit_flow_item_id,
			in_to_nature 			=> csr_data_pkg.NATURE_PERMIT_APPLICATION,
			in_comment				=> 'Edited'
		);
		
		out_application_id := in_application_id;
		
		INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Application with ref {0} and id {1} changed.', in_application_reference, out_application_id, null, null);
		
		SELECT MIN(paused_dtm)
		  INTO v_currently_paused
		  FROM compl_permit_application_pause
		 WHERE resumed_dtm IS NULL
		   AND permit_application_id = out_application_id;
		
		IF v_currently_paused IS NULL AND in_paused_dtm IS NOT NULL THEN
			INSERT INTO compl_permit_application_pause
			(application_pause_id, permit_application_id, paused_dtm)
			VALUES
			(application_pause_id_seq.nextval, out_application_id, in_paused_dtm);
			
			INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Application with ref {0} and id {1} determination paused set to {2}.', in_application_reference, out_application_id, in_paused_dtm, null);
		END IF;
		
		IF v_currently_paused IS NOT NULL AND in_resumed_dtm IS NOT NULL THEN
			UPDATE compl_permit_application_pause
			   SET resumed_dtm = in_resumed_dtm
			 WHERE resumed_dtm IS NULL
			   AND permit_application_id = out_application_id;
			   
			INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Application with ref {0} and id {1} detemination resumed set to {2}.', in_application_reference, out_application_id, in_resumed_dtm, null);
		END IF;
		
	END IF;	
END;

PROCEDURE GetApplication(
	in_application_id				IN	compliance_permit_application.permit_application_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_transitions					OUT SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
)
AS
	v_flow_item_id					compliance_permit.flow_item_id%TYPE;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit_application
	 WHERE permit_application_id = in_application_id;

	INTERNAL_AssertFlowAccessApp(v_flow_item_id);
	
	OPEN out_cur FOR
		SELECT cpa.permit_application_id, cpa.permit_id, cpa.notes, cpa.application_reference, cpa.compl_permit_app_status_id,
			   cpa.application_type_id, cpa.submission_dtm, cpa.duly_made_dtm, cpa.determined_dtm, cpa.title,
			   fs.flow_sid, fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key,
			   fs.state_colour flow_state_colour, fs.pos flow_state_pos, cpa.flow_item_id, p.paused_dtm, fs.flow_state_nature_id
		  FROM compliance_permit_application cpa
		  JOIN flow_item fi ON cpa.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN compl_permit_application_pause p ON p.permit_application_id = cpa.permit_application_id AND p.resumed_dtm IS NULL
		 WHERE cpa.permit_application_id = in_application_id;

	GetApplicationTransitions(v_flow_item_id, out_transitions);
	
	OPEN out_pauses FOR
		SELECT application_pause_id, permit_application_id, paused_dtm, NVL(resumed_dtm, SYSDATE) resumed_dtm
		  FROM compl_permit_application_pause
		 WHERE permit_application_id = in_application_id;
END;

PROCEDURE GetApplications(
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_transitions					OUT SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
	v_flow_item_id					compliance_permit.flow_item_id%TYPE;
	v_region_sids					security_pkg.T_SID_IDS;
	v_flow_item_ids					security_pkg.T_SID_IDS;
	v_regions_table 				security.T_SID_TABLE;
	v_flow_items_table				security.T_SID_TABLE;
BEGIN
	-- security check covered by GetFlowItemTransitions
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_compliance_permit_id;

	v_regions_table := security_pkg.SidArrayToTable(v_region_sids);
	
	SELECT fi.flow_item_id
	  BULK COLLECT INTO v_flow_item_ids
	  FROM compliance_permit_application cpa
	  JOIN compliance_permit cp ON cpa.permit_id = cp.compliance_permit_id
	  JOIN flow_item fi ON cpa.flow_item_id = fi.flow_item_id
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	 WHERE cpa.permit_id = in_compliance_permit_id
	   AND (EXISTS (
				SELECT 1
				  FROM region_role_member rrm
				  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				 WHERE rrm.app_sid = cpa.app_sid
				   AND rrm.region_sid = cp.region_sid
				   AND rrm.user_sid = v_user_sid
				   AND fsr.flow_state_id = fi.current_state_id
			)
			OR EXISTS (
				SELECT 1
				  FROM flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid 
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND fsr.flow_state_id = fi.current_state_id
			)
		);
	
	v_flow_items_table := security_pkg.SidArrayToTable(v_flow_item_ids);
	
	OPEN out_cur FOR
		SELECT cpa.permit_application_id, cpa.permit_id, cpa.notes, cpa.application_reference, cpa.compl_permit_app_status_id, 
			   cpa.application_type_id, cpa.submission_dtm, cpa.duly_made_dtm, cpa.determined_dtm, cpa.title,
			   fs.flow_sid, fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key,
			   fs.state_colour flow_state_colour, fs.pos flow_state_pos, fi.flow_item_id, p.paused_dtm, fs.flow_state_nature_id
		  FROM compliance_permit_application cpa
		  JOIN compliance_permit cp ON cpa.permit_id = cp.compliance_permit_id
		  JOIN flow_item fi ON cpa.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  JOIN TABLE(v_flow_items_table) fit ON fi.flow_item_id = fit.column_value
		  LEFT JOIN compl_permit_application_pause p ON p.permit_application_id = cpa.permit_application_id AND p.resumed_dtm IS NULL
		  ORDER BY fs.state_colour, fs.pos;
	
	IF v_flow_item_ids.COUNT > 0 THEN
		flow_pkg.GetFlowItemTransitions(
			in_flow_item_ids	=> v_flow_item_ids,
			in_region_sids		=> v_region_sids,
			out_cur				=> out_transitions
		);
	ELSE
		OPEN out_transitions FOR
			SELECT NULL
			  FROM dual
			 WHERE 1 = 0;
	END IF;
	
	OPEN out_pauses FOR
		SELECT application_pause_id, permit_application_id, paused_dtm, NVL(resumed_dtm, SYSDATE) resumed_dtm
		  FROM compl_permit_application_pause;
END;

PROCEDURE GetApplicationByRef(
	in_reference					IN	compliance_permit_application.application_reference%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_transitions					OUT SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
)
AS
	v_application_id				compliance_permit_application.permit_application_id%TYPE;
BEGIN
	SELECT MIN(permit_application_id)
	  INTO v_application_id
	  FROM compliance_permit_application
	 WHERE application_reference = in_reference;

	IF v_application_id IS NULL THEN
		OPEN out_cur FOR
			SELECT NULL
			  FROM dual;
		
		RETURN;
	END IF;
	
	GetApplication(
		in_application_id	=> v_application_id, 
		out_cur				=> out_cur,
		out_transitions		=> out_transitions,
		out_pauses			=> out_pauses
	);
END;

FUNCTION IsPermitRefInUse(
	in_permit_id					IN  compliance_permit.compliance_permit_id%TYPE,
	in_reference					IN	compliance_permit_application.application_reference%TYPE
)
RETURN NUMBER
AS
	v_permit_id						security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(compliance_permit_id)
	  INTO v_permit_id
	  FROM compliance_permit
	 WHERE LOWER(permit_reference) = LOWER(in_reference);
	
	IF v_permit_id IS NULL OR v_permit_id = in_permit_id THEN
		RETURN 0;
	END IF;

	IF v_permit_id = in_permit_id THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;

FUNCTION IsApplicationRefInUse(
	in_application_id				IN  compliance_permit_application.permit_application_id%TYPE,
	in_reference					IN	compliance_permit_application.application_reference%TYPE
)
RETURN NUMBER
AS
	v_application_id				security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(permit_application_id)
	  INTO v_application_id
	  FROM compliance_permit_application
	 WHERE LOWER(application_reference) = LOWER(in_reference);
	
	IF v_application_id IS NULL OR v_application_id = in_application_id THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;

PROCEDURE GetPermitFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT cp.title, r.name region_name, cat.description activity_type,
			   cats.description activity_sub_type, cp.activity_start_dtm, 
			   cp.activity_end_dtm, cpt.description permit_type, cpst.description permit_sub_type,
			   cp.permit_start_dtm, cp.permit_end_dtm, cp.permit_reference,
			   a.app_sid, a.customer_alert_type_id, a.flow_item_generated_alert_id, 
			   a.set_by_user_sid, a.to_user_sid, a.flow_item_id, a.flow_alert_helper, a.to_initiator,
			   cp.compliance_permit_id permit_id
		  FROM v$open_flow_item_gen_alert a
		  JOIN compliance_permit cp 
			ON cp.app_sid = a.app_sid AND cp.flow_item_id = a.flow_item_id
		  JOIN compliance_permit_type cpt
			ON cp.app_sid = cpt.app_sid AND cp.permit_type_id = cpt.permit_type_id
		  LEFT JOIN compliance_permit_sub_type cpst
			ON cp.app_sid = cpst.app_sid AND cp.permit_sub_type_id = cpst.permit_sub_type_id AND cp.permit_type_id = cpst.permit_type_id
		  JOIN compliance_activity_type cat
			ON cp.app_sid = cat.app_sid AND cp.activity_type_id = cat.activity_type_id
		  LEFT JOIN compliance_activity_sub_type cats
			ON cp.app_sid = cats.app_sid AND cp.activity_type_id = cats.activity_type_id AND cp.activity_sub_type_id = cats.activity_sub_type_id
		  JOIN v$region r
			ON r.app_sid = a.app_sid AND r.region_sid = cp.region_sid;
END;

PROCEDURE GetPermitApplicationFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT cat.description application_type, cpa.application_reference, cpa.title,
			   cpa.submission_dtm, cpa.duly_made_dtm, cpa.determined_dtm,
			   a.app_sid, a.customer_alert_type_id, a.flow_item_generated_alert_id, 
			   a.set_by_user_sid, a.to_user_sid, a.flow_item_id, a.flow_alert_helper, a.to_initiator,
			   cpa.permit_id
		  FROM v$open_flow_item_gen_alert a
		  JOIN compliance_permit_application cpa
			ON cpa.app_sid = a.app_sid AND cpa.flow_item_id = a.flow_item_id
		  JOIN compliance_application_type cat
			ON cpa.app_sid = cat.app_sid AND cpa.application_type_id = cat.application_type_id;
END;

PROCEDURE GetPermitConditionFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT ci.reference_code condition_reference, cct.description condition_type,
			   ccst.description condition_sub_type, ci.title condition_title,
			   cp.permit_reference, cp.title permit_title,
			   a.app_sid, a.customer_alert_type_id, a.flow_item_generated_alert_id, 
			   a.set_by_user_sid, a.to_user_sid, a.flow_item_id, a.flow_alert_helper,
			   a.to_initiator
		  FROM v$open_flow_item_gen_alert a
		  JOIN compliance_item_region cir
			ON cir.app_sid = a.app_sid AND cir.flow_item_id = a.flow_item_id
		  JOIN compliance_permit_condition cpc
			ON cpc.app_sid = a.app_sid AND cpc.compliance_item_id = cir.compliance_item_id
		  JOIN compliance_permit cp
			ON cpc.compliance_permit_id = cp.compliance_permit_id
		  JOIN compliance_item ci
			ON cpc.app_sid = ci.app_sid AND cpc.compliance_item_id = ci.compliance_item_id
		  JOIN compliance_condition_type cct
			ON cpc.app_sid = cct.app_sid AND cpc.condition_type_id = cct.condition_type_id
		  LEFT JOIN compliance_condition_sub_type ccst
			ON cpc.app_sid = ccst.app_sid AND cpc.condition_type_id = ccst.condition_type_id 
		   AND cpc.condition_sub_type_id = ccst.condition_sub_type_id;
END;

PROCEDURE GetPredecessors(
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cp.compliance_permit_id permit_id, cp.title, cp.permit_reference reference,
			   cp.permit_start_dtm start_date, fs.label status
		  FROM compliance_permit cp
		  JOIN compliance_permit_history cph
			ON cp.compliance_permit_id = cph.prev_permit_id
		  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE cph.next_permit_id = in_compliance_permit_id;
END;

PROCEDURE GetSuccessors(
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cp.compliance_permit_id permit_id, cp.title, cp.permit_reference reference,
			   cp.permit_start_dtm start_date, fs.label status
		  FROM compliance_permit cp
		  JOIN compliance_permit_history cph
			ON cp.compliance_permit_id = cph.next_permit_id
		  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE cph.prev_permit_id = in_compliance_permit_id;
END;

PROCEDURE GetPermits(
	in_linkable_to_permit_id		IN  compliance_permit.compliance_permit_id%TYPE DEFAULT NULL,
	in_search_phrase				IN  VARCHAR2,
	in_region_sid					IN	compliance_permit.region_sid%TYPE,
	in_sort_by						IN  VARCHAR2,
	in_sort_dir						IN  VARCHAR2,
	in_row_count					IN  NUMBER,
	in_start_row					IN  NUMBER,
	out_total_rows					OUT NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_phrase						varchar2(255);
	v_item_type						NUMBER;
	v_permit_ids 					security_pkg.T_SID_IDS;
	v_permit_table					security.T_SID_TABLE;
BEGIN
	compliance_pkg.AssertComplianceMgr();
	
	v_phrase := LOWER(in_search_phrase);
	
	SELECT DISTINCT cp.compliance_permit_id
	  BULK COLLECT INTO v_permit_ids
	  FROM compliance_permit cp
	 WHERE (in_region_sid IS NULL 
			OR cp.region_sid IN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid
				  FROM region r
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = in_region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
			 )
		    ) 
		AND (in_linkable_to_permit_id IS NULL 
			OR (cp.compliance_permit_id != in_linkable_to_permit_id
			    AND cp.compliance_permit_id NOT IN (
					SELECT DISTINCT cph.next_permit_id
					  FROM compliance_permit_history cph
					 WHERE cph.prev_permit_id = in_linkable_to_permit_id
				)
				AND cp.compliance_permit_id NOT IN (
					SELECT DISTINCT cph.prev_permit_id
					  FROM compliance_permit_history cph
					 WHERE cph.next_permit_id = in_linkable_to_permit_id
				)
			)
		   )
	   AND (LOWER(cp.title) LIKE '%'||v_phrase||'%'
			OR LOWER(cp.activity_details) LIKE '%'||v_phrase||'%'
			OR LOWER(cp.permit_reference) LIKE '%'||v_phrase||'%'
	   );

	v_permit_table := security_pkg.SidArrayToTable(v_permit_ids);

	OPEN out_cur FOR
		SELECT sorted_cp.compliance_permit_id permit_id, sorted_cp.permit_reference reference, 
			   sorted_cp.title, sorted_cp.permit_start_dtm start_date, sorted_cp.label status
		  FROM (
			SELECT cp.compliance_permit_id, cp.permit_reference, cp.title, cp.permit_start_dtm, fs.label,
				row_number() OVER (ORDER BY 
					CASE
						WHEN in_sort_by='reference' AND in_sort_dir = 'DESC' THEN TO_CHAR(cp.permit_reference)
						WHEN in_sort_by='title' AND in_sort_dir = 'DESC' THEN TO_CHAR(cp.title)
						WHEN in_sort_by='status' AND in_sort_dir = 'DESC' THEN TO_CHAR(fs.label)
					END DESC,
					CASE
						WHEN in_sort_by='reference' AND in_sort_dir = 'ASC' THEN TO_CHAR(cp.permit_reference)
						WHEN in_sort_by='title' AND in_sort_dir = 'ASC' THEN TO_CHAR(cp.title)
						WHEN in_sort_by='status' AND in_sort_dir = 'ASC' THEN TO_CHAR(fs.label)
					END ASC
				) rn
			  FROM compliance_permit cp
			  JOIN TABLE(v_permit_table) t ON cp.compliance_permit_id = t.column_value
			  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id
			  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
			) sorted_cp
		 WHERE rn-1 BETWEEN in_start_row AND in_start_row + in_row_count - 1
		 ORDER BY rn;

	 out_total_rows := CARDINALITY(v_permit_table);
END;

PROCEDURE LinkPermits(
	in_prev_permit_id				IN compliance_permit.compliance_permit_id%TYPE,
	in_next_permit_id				IN compliance_permit.compliance_permit_id%TYPE
)
AS
	v_prev_flow_item_id				compliance_permit.flow_item_id%TYPE;
	v_prev_item_ref					compliance_permit.permit_reference%TYPE;
	v_next_flow_item_id				compliance_permit.flow_item_id%TYPE;
	v_next_item_ref					compliance_permit.permit_reference%TYPE;
BEGIN
	compliance_pkg.AssertComplianceMgr();						
	
	SELECT flow_item_id, permit_reference
	  INTO v_prev_flow_item_id, v_prev_item_ref
	  FROM compliance_permit 
	 WHERE compliance_permit_id = in_prev_permit_id;
	 
	SELECT flow_item_id, permit_reference
 	  INTO v_next_flow_item_id , v_next_item_ref
 	  FROM compliance_permit 
 	 WHERE compliance_permit_id = in_next_permit_id;

	INSERT INTO compliance_permit_history (prev_permit_id, next_permit_id)
	VALUES (in_prev_permit_id, in_next_permit_id);
	
	INTERNAL_AddAuditLogEntry(v_prev_flow_item_id, 'Added permit number {0} and id {1} as a successor.', in_next_permit_id, v_next_item_ref, null, null);
	INTERNAL_AddAuditLogEntry(v_next_flow_item_id, 'Added permit number {0} and id {1} as a predecessor.', in_prev_permit_id, v_prev_item_ref, null, null);
END;

PROCEDURE UnlinkPermits(
	in_prev_permit_id				IN compliance_permit.compliance_permit_id%TYPE,
	in_next_permit_id				IN compliance_permit.compliance_permit_id%TYPE
)
AS
	v_prev_flow_item_id				compliance_permit.flow_item_id%TYPE;
	v_prev_item_ref					compliance_permit.permit_reference%TYPE;
	v_next_flow_item_id				compliance_permit.flow_item_id%TYPE;
	v_next_item_ref					compliance_permit.permit_reference%TYPE;
BEGIN
	compliance_pkg.AssertComplianceMgr();

	SELECT flow_item_id, permit_reference
	  INTO v_prev_flow_item_id, v_prev_item_ref
	  FROM compliance_permit 
	 WHERE compliance_permit_id = in_prev_permit_id;
	 
	SELECT flow_item_id, permit_reference
 	  INTO v_next_flow_item_id , v_next_item_ref
 	  FROM compliance_permit 
 	 WHERE compliance_permit_id = in_next_permit_id;

	DELETE FROM compliance_permit_history
	 WHERE prev_permit_id = in_prev_permit_id
	   AND next_permit_id  = in_next_permit_id;

	INTERNAL_AddAuditLogEntry(v_prev_flow_item_id, 'Removed permit number {0} and id {1} as a successor.', in_next_permit_id, v_next_item_ref, null, null);
	INTERNAL_AddAuditLogEntry(v_next_flow_item_id, 'Removed permit number {0} and id {1} as a predecessor.', in_prev_permit_id, v_prev_item_ref, null, null);
END;

PROCEDURE GetPermitTransitions(
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_region_sids		security_pkg.T_SID_IDS;
BEGIN
	-- security check covered by GetFlowItemTransitions
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM compliance_permit
	 WHERE flow_item_id = in_flow_item_id;

	flow_pkg.GetFlowItemTransitions(
		in_flow_item_id		=> in_flow_item_id,
		in_region_sids		=> v_region_sids,
		out_cur 			=> out_cur
	);
END;

PROCEDURE GetIssueDueDtm(
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE,
	out_due_dtm						OUT	issue.due_dtm%TYPE
)
AS
	v_permit_id						issue.permit_id%TYPE;
BEGIN
	SELECT CASE i.issue_due_source_id
			   WHEN csr_data_pkg.ISSUE_SOURCE_PERMIT_START THEN p.permit_start_dtm
			   WHEN csr_data_pkg.ISSUE_SOURCE_PERMIT_EXPIRY THEN p.permit_end_dtm
			   WHEN csr_data_pkg.ISSUE_SOURCE_ACTIVITY_START THEN p.activity_start_dtm
			   WHEN csr_data_pkg.ISSUE_SOURCE_ACTIVITY_END THEN p.activity_end_dtm
			   WHEN csr_data_pkg.ISSUE_SOURCE_PERMIT_CMN_DTM THEN p.site_commissioning_dtm
		   END
	  INTO out_due_dtm
	  FROM issue i
	  JOIN compliance_permit p
		ON i.app_sid = p.app_sid
	   AND i.permit_id = p.compliance_permit_id
	 WHERE i.issue_id = in_issue_id;
END;

FUNCTION GetPermitUrl(
	in_permit_id					IN  compliance_permit.compliance_permit_id%TYPE
)
RETURN VARCHAR2
AS
BEGIN
	RETURN '/csr/site/compliance/ViewPermit.acds?permitId=' || in_permit_id;
END;


PROCEDURE INTERNAL_CheckTransitAccess (
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE
)
AS
BEGIN
	IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RETURN;
	END IF;

	FOR r IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS (
			SELECT *
			  FROM compliance_permit cp
			  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id
			  JOIN flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
			 WHERE cp.flow_item_id = in_flow_item_id
			   AND fst.to_state_id = in_to_state_id
			   AND (EXISTS (
						SELECT 1
						  FROM region_role_member rrm
						  JOIN flow_state_transition_role fstr ON rrm.app_sid = fstr.app_sid AND rrm.role_sid = fstr.role_sid
						 WHERE rrm.app_sid = cp.app_sid
						   AND rrm.region_sid = cp.region_sid
						   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   AND fst.flow_state_transition_id = fstr.flow_state_transition_id
					)
					OR EXISTS (
						SELECT 1
						  FROM flow_state_transition_role fstr 
						  JOIN security.act act ON act.sid_id = fstr.group_sid 
						 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						   AND fst.flow_state_transition_id = fstr.flow_state_transition_id
					))
		 )
	) LOOP
		RETURN;
	END LOOP;
	
	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing running transition for permit with flow item id: '||in_flow_item_id||' state id: '||in_to_state_id);
END;

PROCEDURE RunFlowTransition(
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_cache_keys					IN	security_pkg.T_VARCHAR2_ARRAY,	
	out_still_has_access 			OUT NUMBER
)
AS
BEGIN

	INTERNAL_CheckTransitAccess(in_flow_item_id, in_to_state_id); 

	flow_pkg.SetItemState(
		in_flow_item_id 	=> in_flow_item_id,
		in_to_state_id 		=> in_to_state_id,
		in_comment_text 	=> in_comment_text,
		in_cache_keys 		=> in_cache_keys
	);

	IF INTERNAL_HasFlowAccessPmt(in_flow_item_id) THEN
		out_still_has_access := 1;
	ELSE
		out_still_has_access := 0;
	END IF;
END;

PROCEDURE GetApplicationTransitions(
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_region_sids		security_pkg.T_SID_IDS;
BEGIN
	-- security check covered by GetFlowItemTransitions
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM compliance_permit_application cpa
	  JOIN compliance_permit cp ON cpa.permit_id = cp.compliance_permit_id
	 WHERE cpa.flow_item_id = in_flow_item_id;

	flow_pkg.GetFlowItemTransitions(
		in_flow_item_id		=> in_flow_item_id,
		in_region_sids		=> v_region_sids,
		out_cur 			=> out_cur
	);
END;

PROCEDURE INTERNAL_CheckAppTransitAccess (
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE
)
AS
BEGIN
	IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RETURN;
	END IF;

	FOR r IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS (
			SELECT *
			  FROM compliance_permit_application pa
			  JOIN compliance_permit p ON p.compliance_permit_id = pa.permit_id
			  JOIN flow_item fi ON pa.app_sid = fi.app_sid AND pa.flow_item_id = fi.flow_item_id
			  JOIN flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
			 WHERE pa.flow_item_id = in_flow_item_id
			   AND fst.to_state_id = in_to_state_id
			   AND (EXISTS (
						SELECT 1
						  FROM region_role_member rrm
						  JOIN flow_state_transition_role fstr ON rrm.app_sid = fstr.app_sid AND rrm.role_sid = fstr.role_sid
						 WHERE rrm.app_sid = pa.app_sid
						   AND rrm.region_sid = p.region_sid
						   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   AND fst.flow_state_transition_id = fstr.flow_state_transition_id
					)
					OR EXISTS (
						SELECT 1
						  FROM flow_state_transition_role fstr 
						  JOIN security.act act ON act.sid_id = fstr.group_sid 
						 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						   AND fst.flow_state_transition_id = fstr.flow_state_transition_id
					))
		 )
	) LOOP
		RETURN;
	END LOOP;
	
	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing running transition for compliance item with flow item id: '||in_flow_item_id||' state id: '||in_to_state_id);
END;

FUNCTION INTERNAL_TryPermitTransition (
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE
) 
RETURN NUMBER
AS
	v_to_state_id					flow_state.flow_state_id%TYPE;
	v_permit_flow_item_id			flow_item.flow_item_id%TYPE;
BEGIN

	BEGIN
		SELECT tfs.flow_state_id, cp.flow_item_id
		  INTO v_to_state_id, v_permit_flow_item_id
		  FROM compliance_permit_application cpa
		  JOIN compliance_permit cp ON cpa.permit_id = cp.compliance_permit_id
		  JOIN flow_item fi ON fi.flow_item_id = cp.flow_item_id
		  JOIN flow_state ffs ON ffs.flow_state_id = fi.current_state_id
		  JOIN flow_state_transition fst ON fst.from_state_id = ffs.flow_state_id
		  JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id 
			AND tfs.flow_state_nature_id = DECODE(cpa.compl_permit_app_status_id, 1, csr_data_pkg.NATURE_PERMIT_ACTIVE, 2, csr_data_pkg.NATURE_PERMIT_REFUSED, NULL) 
		 WHERE cpa.flow_item_id = in_flow_item_id
		   AND tfs.pos IN (SELECT MIN(pos) FROM flow_state WHERE flow_state_nature_id = tfs.flow_state_nature_id)
		   AND ffs.flow_state_nature_id = csr_data_pkg.NATURE_PERMIT_APPLICATION; 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Don't bother if workflow doesn't have a state to transition to.
			RETURN 0;
	END;

	flow_pkg.SetItemState(
		in_flow_item_id 	=> v_permit_flow_item_id,
		in_to_state_id 		=> v_to_state_id,
		in_comment_text 	=> 'Automatic transition from application',
		in_user_sid			=> 3
	);
	
	RETURN 1;
END;

PROCEDURE RunApplicationFlowTransition(
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_cache_keys					IN	security_pkg.T_VARCHAR2_ARRAY,	
	out_still_has_access 			OUT NUMBER
)
AS
	v_flow_state_label				flow_state.label%TYPE;
	v_to_state_nature_id			flow_state.flow_state_nature_id%TYPE;
	v_curr_state_nature_id			flow_state.flow_state_nature_id%TYPE;
BEGIN
	INTERNAL_CheckAppTransitAccess(in_flow_item_id, in_to_state_id);
	
	SELECT MIN(fs.flow_state_nature_id)
	  INTO v_curr_state_nature_id
	  FROM flow_item fi
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	 WHERE flow_item_id = in_flow_item_id;
	
	flow_pkg.SetItemState(
		in_flow_item_id 	=> in_flow_item_id,
		in_to_state_id 		=> in_to_state_id,
		in_comment_text 	=> in_comment_text,
		in_cache_keys 		=> in_cache_keys
	);
	
	IF INTERNAL_HasFlowAccessApp(in_flow_item_id) THEN
		out_still_has_access := 1;
	ELSE
		out_still_has_access := 0;
	END IF;

END;

PROCEDURE GetAuditLogForItemPaged(
	in_flow_item_id		IN	security_pkg.T_SID_ID,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_flow_item_ids 	aspen2.t_number_table;
	v_permit_id			compliance_permit.compliance_permit_id%TYPE;
	v_region_sid		compliance_permit.region_sid%TYPE;
BEGIN
	INTERNAL_AssertFlowAccessPmt(in_flow_item_id);
	
	SELECT compliance_permit_id, region_sid
	  INTO v_permit_id, v_region_sid
	  FROM compliance_permit
	 WHERE flow_item_id = in_flow_item_id;
	
	SELECT flow_item_id 
	  BULK COLLECT INTO v_flow_item_ids 
	  FROM (
	  	SELECT flow_item_id
		  FROM compliance_permit
	 	 WHERE compliance_permit_id = v_permit_id
	 	 UNION
		SELECT flow_item_id 
		  FROM compliance_permit_application
		 WHERE permit_id = v_permit_id
		 );
	
	INSERT INTO temp_flow_item_audit_log(flow_item_audit_log_id, audit_dtm)
	SELECT al.flow_item_audit_log_id, al.log_dtm
	  FROM (
			SELECT flow_item_audit_log_id, flow_item_id, log_dtm, user_sid, description, comment_text, param_1, param_2, param_3
			  FROM flow_item_audit_log
		 	 UNION ALL
			SELECT fsl.flow_state_log_id, fsl.flow_item_id, fsl.set_dtm log_dtm, fsl.set_by_user_sid user_sid, 'Entered state: {0}' description, 
				   fsl.comment_text, fs.label param_1, null param_2, null param_3
			  FROM flow_state_log fsl
			  JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id
		) al 
		JOIN csr_user cu ON al.user_sid = cu.csr_user_sid
		JOIN TABLE(v_flow_item_ids) fi ON fi.column_value = al.flow_item_id
	 WHERE al.log_dtm >= in_start_date AND al.log_dtm <= in_end_date + 1
	   AND (in_search IS NULL OR (
			LOWER(cu.full_name) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(al.comment_text) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(al.description) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(al.param_1) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(al.param_2) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(al.param_3) LIKE '%'||LOWER(in_search)||'%'
		));
	
	SELECT COUNT(flow_item_audit_log_id)
	  INTO out_total
	  FROM temp_flow_item_audit_log;
	
	OPEN out_cur FOR
		SELECT al.log_dtm audit_date, cu.full_name, cu.user_name, cu.csr_user_sid, al.description, 
			   al.comment_text, f.flow_alert_class, al.param_1, al.param_2, al.param_3
		  FROM (SELECT flow_item_audit_log_id, rn
				  FROM (SELECT flow_item_audit_log_id, ROWNUM rn
						  FROM (SELECT flow_item_audit_log_id
								  FROM temp_flow_item_audit_log
								 ORDER BY audit_dtm DESC, flow_item_audit_log_id DESC
								)
						 WHERE ROWNUM < in_start_row + in_page_size
						)
				) x
		  JOIN (
				SELECT app_sid, flow_item_audit_log_id, flow_item_id, log_dtm, user_sid, description, comment_text, null flow_state_label, param_1, param_2, param_3
				  FROM flow_item_audit_log
			 	 UNION ALL
				SELECT fsl.app_sid, fsl.flow_state_log_id, fsl.flow_item_id, fsl.set_dtm log_dtm, fsl.set_by_user_sid user_sid, 'Entered state: {0}' zdescription, 
					   fsl.comment_text, fs.label flow_state_label, fs.label param_1, null param_2, null param_3
				  FROM flow_state_log fsl
				  JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id
			) al ON x.flow_item_audit_log_id = al.flow_item_audit_log_id
		  JOIN csr_user cu ON al.user_sid = cu.csr_user_sid
		  JOIN TABLE(v_flow_item_ids) fi ON fi.column_value = al.flow_item_id
		  JOIN flow_item fi2 ON fi2.flow_item_id = al.flow_item_id
		  JOIN flow f ON fi2.flow_sid = f.flow_sid 
		 WHERE x.rn >= in_start_row
		 ORDER BY al.log_dtm DESC;
END;

PROCEDURE AddIssue(
	in_permit_id					IN  compliance_permit.compliance_permit_id%TYPE,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE,
	in_is_urgent					IN	NUMBER,
	in_region_sid					IN  region.region_sid%TYPE,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE,
	in_issue_due_offset_days		IN	issue.issue_due_offset_days%TYPE,
	in_issue_due_offset_months		IN	issue.issue_due_offset_months%TYPE,
	in_issue_due_offset_years		IN	issue.issue_due_offset_years%TYPE,
	in_is_critical					IN	issue.is_critical%TYPE,
	out_issue_id					OUT issue.issue_id%TYPE
)
AS
	v_flow_item_id					compliance_permit.flow_item_id%TYPE;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;

	INTERNAL_AssertFlowAccessPmt(v_flow_item_id);

	issue_pkg.CreateIssue(
		in_label					=> in_label,
		in_description				=> in_description,
		in_source_label				=> NULL,
		in_issue_type_id			=> csr_data_pkg.ISSUE_PERMIT,
		in_correspondent_id			=> NULL,
		in_raised_by_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_user_sid		=> in_assigned_to_user_sid,
		in_assigned_to_role_sid		=> NULL,
		in_priority_id				=> NULL,
		in_due_dtm					=> in_due_dtm,
		in_source_url				=> in_source_url,
		in_region_sid				=> in_region_sid,
		in_is_urgent				=> in_is_urgent,
		in_issue_due_source_id		=> in_issue_due_source_id,
		in_issue_due_offset_days	=> in_issue_due_offset_days,
		in_issue_due_offset_months	=> in_issue_due_offset_months,
		in_issue_due_offset_years	=> in_issue_due_offset_years,
		in_is_critical				=> in_is_critical,
		out_issue_id				=> out_issue_id
	);

	UPDATE issue 	
	   SET permit_id = in_permit_id
	 WHERE issue_id = out_issue_id;

	issue_pkg.RefreshRelativeDueDtm(in_issue_id => out_issue_id);

	INTERNAL_AddAuditLogEntry(v_flow_item_id, 'New action {0} added.', in_label, null, null, null);
END;

PROCEDURE SearchPermits (
	in_search_term			VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_sanitised_search		VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search_term);
BEGIN

	OPEN out_cur FOR
		SELECT cp.compliance_permit_id, cp.permit_reference, cp.title
		  FROM compliance_permit cp
		  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id
		 WHERE (in_search_term IS NULL
			OR CONTAINS (cp.title, v_sanitised_search) > 0
			OR CONTAINS (cp.permit_reference, v_sanitised_search) > 0
			)
		  AND (EXISTS (
					 SELECT 1
					   FROM region_role_member rrm
					   JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					  WHERE rrm.app_sid = cp.app_sid
						AND rrm.region_sid = cp.region_sid
						AND rrm.user_sid = security.security_pkg.GetSid
						AND fsr.flow_state_id = fi.current_state_id
				 )
				 OR EXISTS (
					 SELECT 1
					   FROM flow_state_role fsr
					   JOIN security.act act ON act.sid_id = fsr.group_sid 
					  WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						AND fsr.flow_state_id = fi.current_state_id
				 ));
END;

FUNCTION GetDocLibFolder (
	in_permit_id					IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_doc_lib						security_pkg.T_SID_ID := GetPermitDocLib;
	v_doc_folder					security_pkg.T_SID_ID := NULL;
BEGIN
	IF v_doc_lib IS NOT NULL THEN
		BEGIN
			SELECT df.doc_folder_sid
			  INTO v_doc_folder
			  FROM doc_folder df
			  JOIN security.securable_object so ON so.sid_id = df.doc_folder_sid
			 WHERE df.permit_item_id = in_permit_id
			   AND df.is_system_managed = 1
			   AND so.parent_sid_id = doc_folder_pkg.GetDocumentsFolder(v_doc_lib);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				BEGIN
					doc_folder_pkg.CreateFolder(
						in_parent_sid					=> doc_folder_pkg.GetDocumentsFolder(v_doc_lib),
						in_name							=> INTERNAL_DocFolderName(in_permit_id),
						in_description					=> ' ',
						in_is_system_managed			=> 1,
						in_permit_item_id				=> in_permit_id,
						out_sid_id						=> v_doc_folder
					);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						NULL;
					WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
						NULL;
				END;
		END;
	END IF;

	RETURN v_doc_folder;
END;

FUNCTION GetPermitDocLib 
  RETURN security_pkg.T_SID_ID
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_doc_lib_sid					security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT permit_doc_lib_sid 
		  INTO v_doc_lib_sid
		  FROM compliance_options 
		 WHERE app_sid = v_app_sid;
		 
		 RETURN v_doc_lib_sid;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN 
			RETURN NULL;
	END;
END;

FUNCTION GetPermissibleDocumentFolders (
	in_doc_library_sid				IN  security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE
AS
	v_sids							security.T_SID_TABLE;
BEGIN
	SELECT DISTINCT df.doc_folder_sid
	  BULK COLLECT INTO v_sids
	  FROM doc_folder df 
	 WHERE df.permit_item_id IN (
		 SELECT compliance_permit_id
		   FROM compliance_permit cp
		   JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id
		  WHERE EXISTS (
				SELECT 1
				  FROM region_role_member rrm
				  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				 WHERE rrm.app_sid = cp.app_sid
				   AND rrm.region_sid = cp.region_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
				   AND fsr.flow_state_id = fi.current_state_id )
		     OR EXISTS (
				SELECT 1
				  FROM flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid 
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND fsr.flow_state_id = fi.current_state_id ) 
	);
	RETURN v_sids;
END;

FUNCTION CheckDocumentPermissions (
	in_permit_id					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_permit_flow_item_id			compliance_permit.flow_item_id%TYPE;
	v_can_view						BOOLEAN;
	v_can_edit						BOOLEAN;
	v_mapped						security_pkg.T_PERMISSION := 0;
BEGIN
	SELECT flow_item_id 
	  INTO v_permit_flow_item_id
	  FROM compliance_permit 
	 WHERE compliance_permit_id = in_permit_id; 
	 
	v_can_view := INTERNAL_HasFlowAccessPmt(v_permit_flow_item_id);
	v_can_edit := INTERNAL_HasFlowAccessPmt(v_permit_flow_item_id, 1);
	
	IF v_can_view THEN
		v_mapped := v_mapped + 
			security_pkg.PERMISSION_READ + 
			security_pkg.PERMISSION_READ_ATTRIBUTES + 
			security_pkg.PERMISSION_LIST_CONTENTS;
	END IF;

	IF v_can_edit THEN
		v_mapped := v_mapped + 
			security_pkg.PERMISSION_WRITE + 
			security_pkg.PERMISSION_ADD_CONTENTS + 
			security_pkg.PERMISSION_DELETE;
	END IF;

	RETURN BITAND(v_mapped, in_permission_set) = in_permission_set;
END;

PROCEDURE DocSaved (
	in_permit_id 					IN  security_pkg.T_SID_ID,
	in_filename						IN  VARCHAR2
)
AS
	v_flow_item_id					security_pkg.T_SID_ID;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;
	 
	INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Document {0} added.', in_filename, null, null, null);
END;

PROCEDURE DocDeleted (
	in_permit_id 					IN  security_pkg.T_SID_ID,
	in_filename						IN  VARCHAR2
)
AS
	v_flow_item_id					security_pkg.T_SID_ID;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;
	 
	INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Document {0} deleted.', in_filename, null, null, null);
END;
 
PROCEDURE GetPermConditionRagThresholds (
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security other than app_sid check, its just a bunch of labels and hex colours
	OPEN out_cur FOR 
		SELECT st.description label, TRIM(TO_CHAR(st.text_colour, 'XXXXXX')) colour
		  FROM compliance_options co
		  JOIN score_threshold st ON co.permit_score_type_id = st.score_type_id;
END;

PROCEDURE INT_UpdateTempCompLevels(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_search			IN	VARCHAR2
)
AS
	v_max_names_len		NUMBER := 250;
BEGIN
	INSERT INTO temp_comp_region_lvl_ids(region_sid, region_description, mgr_full_name)
	SELECT region_sid, description, 
		CASE
			WHEN LENGTH(all_names) > v_max_names_len THEN CONCAT(SUBSTR(all_names, 1, v_max_names_len), '...')
			ELSE all_names
		END all_names
	  FROM (
		SELECT region_sid, description, substr(stragg3(' '||full_name),2) as all_names
		FROM (
			SELECT region_sid, description, full_name
			FROM  (
				SELECT DISTINCT cir.region_sid, r.description, cu.full_name
				FROM compliance_item_region cir
				JOIN compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
				JOIN region_role_member rrr on cir.region_sid = rrr.region_sid and rrr.role_sid = in_role_sid
				JOIN csr_user cu on rrr.user_sid = cu.csr_user_sid
				JOIN v$region r on cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
				WHERE ci.compliance_item_type = compliance_pkg.COMPLIANCE_CONDITION 
				AND (in_search IS NULL OR (
					LOWER(cu.full_name) LIKE '%'||LOWER(in_search)||'%'
					OR LOWER(r.description) LIKE '%'||LOWER(in_search)||'%')
			)
				ORDER BY r.description, cu.full_name
			)
		)
		GROUP BY region_sid, description
	);
END;

PROCEDURE GetAllSiteCompLevelsPaged(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_has_capability	NUMBER(1) := 0;
	v_id_table			security.T_SID_TABLE;
	v_role_sid			security_pkg.T_SID_ID;
BEGIN
	-- Permissions handled by query (using workflow).
	v_role_sid := NVL(role_pkg.GetRoleID(security_pkg.GetApp, 'Compliance Manager'), role_pkg.GetRoleID(security_pkg.GetApp, 'Property Manager'));

	INT_UpdateTempCompLevels(
		in_role_sid => v_role_sid,
		in_search => in_search
	);

	SELECT COUNT(*)
	  INTO out_total
	  FROM temp_comp_region_lvl_ids;
	
	OPEN out_cur FOR
		SELECT region_sid, region_description, mgr_full_name, count_new, count_updated, count_action_req, count_compliant, total_items, pct_compliant, pct_compliant_colour
		  FROM (
			SELECT cir.region_sid, cir.region_description, cir.mgr_full_name, count_new, count_updated, count_action_req, count_compliant, cirag.total_items, cirag.pct_compliant, cirag.pct_compliant_colour, rownum rn
			  FROM (
				SELECT cir.region_sid, tcrli.region_description, tcrli.mgr_full_name,
						SUM(DECODE(fs.lookup_key, 'NEW', 1, 0)) count_new,
						SUM(DECODE(fs.lookup_key, 'UPDATED', 1, 0)) count_updated,
						SUM(DECODE(fs.lookup_key, 'ACTION_REQUIRED', 1, 0)) count_action_req,
						SUM(DECODE(fs.lookup_key, 'COMPLIANT', 1, 0)) count_compliant
				  FROM compliance_item_region cir
				  JOIN compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
				  JOIN v$my_compliance_items mci ON cir.flow_item_id = mci.flow_item_id
				  JOIN temp_comp_region_lvl_ids tcrli ON tcrli.region_sid = cir.region_sid
				  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id
				  JOIN flow_state fs on fi.current_state_id = fs.flow_state_id
				 WHERE ci.compliance_item_type = compliance_pkg.COMPLIANCE_CONDITION
				 GROUP BY cir.region_sid, tcrli.region_description, tcrli.mgr_full_name
				) cir
			  JOIN v$permit_item_rag cirag on cir.region_sid = cirag.region_sid
			 ORDER BY pct_compliant
			)
		 WHERE rn BETWEEN in_start_row AND in_start_row + in_page_size -1;
END; 

PROCEDURE CopyPermitActions(
	in_from_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_target_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_action_assignee_user_sid		IN	security_pkg.T_SID_ID
)
AS
	v_copy_issue_id					issue.issue_id%TYPE;
	v_target_region					security_pkg.T_SID_ID;
BEGIN
	compliance_pkg.AssertComplianceMgr;

	SELECT region_sid
	  INTO v_target_region
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_target_permit_id;

	FOR action IN (
		SELECT i.issue_id,
			   i.label,
			   i.description,
			   i.due_dtm,
			   i.source_url,
			   i.assigned_to_user_sid,
			   p.region_sid,
			   i.issue_due_source_id, 
			   i.issue_due_offset_days,
			   i.issue_due_offset_months,
			   i.issue_due_offset_years, 
			   i.is_critical
		  FROM issue i
		  JOIN compliance_permit p 
			ON i.app_sid = p.app_sid 
		   AND i.permit_id = p.compliance_permit_id
		 WHERE i.permit_id = in_from_permit_id 
		   AND i.issue_compliance_region_id IS NULL
		   AND i.closed_dtm IS NULL
		   AND i.resolved_dtm IS NULL
		   AND i.rejected_dtm IS NULL
		   AND (i.app_sid, i.issue_id) NOT IN (
				SELECT app_sid, copied_from_id
				  FROM issue
				 WHERE permit_id = in_target_permit_id
			)
	) 
	LOOP
		AddIssue(
			in_permit_id			=> in_target_permit_id,
			in_label				=> action.label,
			in_description			=> action.description,
			in_due_dtm				=> NULL,
			in_source_url			=> '/csr/site/compliance/ViewPermit.acds?permitId=' 
										|| in_target_permit_id,
			in_assigned_to_user_sid	=> in_action_assignee_user_sid,
			in_is_urgent			=> 0, 
			in_region_sid			=> v_target_region,
			in_issue_due_source_id	=> action.issue_due_source_id,
			in_issue_due_offset_days =>	action.issue_due_offset_days,
			in_issue_due_offset_months => action.issue_due_offset_months,
			in_issue_due_offset_years => action.issue_due_offset_years,
			in_is_critical			=> action.is_critical,
			out_issue_id			=> v_copy_issue_id
		);

		UPDATE issue
		   SET copied_from_id = action.issue_id
		 WHERE issue_id = v_copy_issue_id;
	END LOOP;
END;

PROCEDURE CopyPermitScheduledActions(
	in_from_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_target_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_action_assignee_user_sid		IN	security_pkg.T_SID_ID
)
AS
	v_copy_issue_scheduled_task_id	issue_scheduled_task.issue_scheduled_task_id%TYPE;
	v_flow_item_id					compliance_permit.flow_item_id%TYPE;
BEGIN
	compliance_pkg.AssertComplianceMgr;

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_target_permit_id;

	FOR scheduled_action IN (
			SELECT ist.issue_scheduled_task_id, 
				   ist.label,
				   ist.schedule_xml, 
				   ist.period_xml,
				   ist.assign_to_user_sid,
				   ist.next_run_dtm, 
				   ist.raised_by_user_sid,
				   ist.last_created,
				   ist.due_dtm_relative, 
				   ist.due_dtm_relative_unit,
				   ist.scheduled_on_due_date,
				   ist.issue_type_id, 
				   ist.create_critical
			  FROM issue_scheduled_task ist
			  JOIN comp_permit_sched_issue cpsi 
				ON ist.app_sid = cpsi.app_sid 
			   AND ist.issue_scheduled_task_id = cpsi.issue_scheduled_task_id
			  JOIN compliance_permit cp
				ON cpsi.app_sid = cp.app_sid
			   AND cpsi.flow_item_id = cp.flow_item_id
			 WHERE cp.compliance_permit_id = in_from_permit_id
			   AND (ist.app_sid, ist.issue_scheduled_task_id) NOT IN (
					SELECT cist.app_sid, cist.copied_from_id
					  FROM issue_scheduled_task cist
					  JOIN comp_permit_sched_issue ccpsi 
						ON cist.app_sid = ccpsi.app_sid 
					   AND cist.issue_scheduled_task_id = ccpsi.issue_scheduled_task_id
					  JOIN compliance_permit ccp
						ON ccpsi.app_sid = ccp.app_sid
					   AND ccpsi.flow_item_id = ccp.flow_item_id
					 WHERE ccp.compliance_permit_id = in_target_permit_id
				)
	)
	LOOP
		issue_pkg.SaveScheduledTask(
			in_issue_scheduled_task_id	=> NULL,
			in_label					=> scheduled_action.label,
			in_schedule_xml				=> scheduled_action.schedule_xml,
			in_period_xml				=> scheduled_action.period_xml,
			in_raised_by_user_sid		=> security_pkg.GetSID(),
			in_assign_to_user_sid		=> NVL(in_action_assignee_user_sid, security_pkg.GetSID()),
			in_next_run_dtm				=> scheduled_action.next_run_dtm,
			in_due_dtm_relative			=> scheduled_action.due_dtm_relative,
			in_due_dtm_relative_unit	=> scheduled_action.due_dtm_relative_unit,
			in_scheduled_on_due_date	=> scheduled_action.scheduled_on_due_date,
			in_parent_id				=> v_flow_item_id,
			in_issue_type_id			=> scheduled_action.issue_type_id,
			in_create_critical			=> scheduled_action.create_critical,
			out_issue_scheduled_task_id	=> v_copy_issue_scheduled_task_id
		);

		UPDATE issue_scheduled_task
		   SET copied_from_id = v_copy_issue_scheduled_task_id
		 WHERE issue_scheduled_task_id = scheduled_action.issue_scheduled_task_id;
	END LOOP;
END;

PROCEDURE CopyPermitConditions(
	in_from_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_target_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_clone_cond_actions			IN	NUMBER,
	in_clone_cond_schduled_actions	IN	NUMBER,
	in_action_assignee_user_sid		IN	security_pkg.T_SID_ID
)
AS
	v_copy_condition_id				compliance_item.compliance_item_id%TYPE;
	v_copy_condition_flow_item_id	flow_item.flow_item_id%TYPE;
	v_copy_issue_id					issue.issue_id%TYPE;
	v_copy_issue_scheduled_task_id	issue_scheduled_task.issue_scheduled_task_id%TYPE;
	v_target_region					security_pkg.T_SID_ID;
BEGIN
	compliance_pkg.AssertComplianceMgr;

	SELECT region_sid
	  INTO v_target_region
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_target_permit_id;

	FOR condition IN (
		SELECT ci.app_sid,
			   ci.compliance_item_id,
			   ci.title,
			   ci.details,
			   ci.reference_code,
			   cpc.condition_type_id,
			   cpc.condition_sub_type_id,
			   cir.flow_item_id,
			   copy.compliance_item_id copy_id,
			   copy_cir.flow_item_id copy_flow_item_id
		  FROM compliance_item ci
		  JOIN compliance_permit_condition cpc 
			ON ci.app_sid = cpc.app_sid
		   AND ci.compliance_item_id = cpc.compliance_item_id 
		  JOIN compliance_permit cp 
			ON cp.app_sid = cpc.app_sid
		   AND cp.compliance_permit_id = cpc.compliance_permit_id
		  JOIN compliance_item_region cir
			ON cir.app_sid = cp.app_sid
		   AND cir.compliance_item_id = ci.compliance_item_id
		  LEFT JOIN compliance_permit_condition copy
			ON copy.app_sid = ci.app_sid
		   AND copy.copied_from_id = ci.compliance_item_id
		   AND copy.compliance_permit_id = in_target_permit_id 
		  LEFT JOIN compliance_item_region copy_cir
			ON copy_cir.app_sid = copy.app_sid
		   AND copy_cir.compliance_item_id = copy.compliance_item_id
		 WHERE cpc.compliance_permit_id = in_from_permit_id
	)
	LOOP
		IF condition.copy_id IS NULL THEN
			compliance_pkg.CreatePermitCondition(
				in_title					=> condition.title,
				in_details					=> condition.details,
				in_reference_code			=> condition.reference_code,
				in_change_type				=> NULL,
				in_permit_id				=> in_target_permit_id,
				in_condition_type_id		=> condition.condition_type_id,
				in_condition_sub_type_id	=> condition.condition_sub_type_id,
				out_compliance_item_id		=> v_copy_condition_id
			);

			compliance_pkg.CreatePermitConditionFlowItem(
				in_compliance_item_id		=> v_copy_condition_id,
				in_permit_id				=> in_target_permit_id,
				out_flow_item_id			=> v_copy_condition_flow_item_id
			);

			UPDATE compliance_permit_condition
			   SET copied_from_id = condition.compliance_item_id
			 WHERE app_sid = condition.app_sid
			   AND compliance_item_id = v_copy_condition_id;
		ELSE
			v_copy_condition_id := condition.copy_id;
			v_copy_condition_flow_item_id := condition.copy_flow_item_id;
		END IF;

		IF in_clone_cond_actions != 0 THEN
			FOR condition_action IN (
				SELECT i.issue_id,
					   cir.flow_item_id,
					   i.label,
					   i.description,
					   i.due_dtm,
					   i.source_url,
					   i.assigned_to_user_sid,
					   cir.region_sid,
					   i.issue_due_source_id, 
					   i.issue_due_offset_days,
					   i.issue_due_offset_months,
					   i.issue_due_offset_years, 
					   i.is_critical
				  FROM issue i
				  JOIN issue_compliance_region icr
					ON icr.app_sid = i.app_sid
				   AND icr.issue_compliance_region_id = i.issue_compliance_region_id
				  JOIN compliance_item_region cir
					ON cir.app_sid = icr.app_sid
				   AND cir.flow_item_id = icr.flow_item_id
				 WHERE cir.app_sid = condition.app_sid 
				   AND cir.compliance_item_id = condition.compliance_item_id
				   AND i.closed_dtm IS NULL
				   AND i.resolved_dtm IS NULL
				   AND i.rejected_dtm IS NULL
				   AND (i.app_sid, i.issue_id) NOT IN (
						SELECT ci.app_sid, ci.copied_from_id
						  FROM issue ci
						  JOIN issue_compliance_region cicr
							ON cicr.app_sid = ci.app_sid
						   AND cicr.issue_compliance_region_id = ci.issue_compliance_region_id
						 WHERE cicr.flow_item_id = v_copy_condition_flow_item_id
				)
			) 
			LOOP
				compliance_pkg.AddIssue(
					in_flow_item_id				=> v_copy_condition_flow_item_id,
					in_label					=> condition_action.label,
					in_description				=> condition_action.description,
					in_due_dtm					=> NULL,
					in_source_url				=> '/csr/site/compliance/RegionCompliance.acds?flowItemId=' 
														|| v_copy_condition_flow_item_id,
					in_assigned_to_user_sid		=> in_action_assignee_user_sid,
					in_is_urgent				=> 0,
					in_region_sid				=> v_target_region,
					in_issue_due_source_id		=> condition_action.issue_due_source_id,
					in_issue_due_offset_days	=> condition_action.issue_due_offset_days,
					in_issue_due_offset_months	=> condition_action.issue_due_offset_months,
					in_issue_due_offset_years	=> condition_action.issue_due_offset_years,
					in_is_critical				=> condition_action.is_critical,
					out_issue_id				=> v_copy_issue_id
				);

				UPDATE issue
				   SET copied_from_id = condition_action.issue_id
				 WHERE issue_id = v_copy_issue_id;
			END LOOP;
		END IF;

		IF in_clone_cond_schduled_actions != 0 THEN
			FOR scheduled_action IN (
					SELECT ist.issue_scheduled_task_id, 
						   ist.label,
						   ist.schedule_xml, 
						   ist.period_xml,
						   ist.assign_to_user_sid,
						   ist.next_run_dtm, 
						   ist.raised_by_user_sid,
						   ist.last_created,
						   ist.due_dtm_relative, 
						   ist.due_dtm_relative_unit,
						   ist.scheduled_on_due_date,
						   ist.issue_type_id, 
						   ist.create_critical
					  FROM issue_scheduled_task ist
					  JOIN comp_item_region_sched_issue cirsi
						ON ist.app_sid = cirsi.app_sid 
					   AND ist.issue_scheduled_task_id = cirsi.issue_scheduled_task_id
					  JOIN compliance_item_region cir
						ON cir.app_sid = cirsi.app_sid
					   AND cir.flow_item_id = cirsi.flow_item_id
					 WHERE cir.compliance_item_id = condition.compliance_item_id
					   AND (ist.app_sid, ist.issue_scheduled_task_id) NOT IN (
							SELECT cist.app_sid, cist.copied_from_id
							  FROM issue_scheduled_task cist
							  JOIN comp_item_region_sched_issue ccirsi
								ON cist.app_sid = ccirsi.app_sid 
							   AND cist.issue_scheduled_task_id = ccirsi.issue_scheduled_task_id
							 WHERE ccirsi.flow_item_id = v_copy_condition_flow_item_id
					)
			)
			LOOP
				issue_pkg.SaveScheduledTask(
					in_issue_scheduled_task_id	=> NULL,
					in_label					=> scheduled_action.label,
					in_schedule_xml				=> scheduled_action.schedule_xml,
					in_period_xml				=> scheduled_action.period_xml,
					in_raised_by_user_sid		=> security_pkg.GetSID(),
					in_assign_to_user_sid		=> NVL(in_action_assignee_user_sid, security_pkg.GetSID()),
					in_next_run_dtm				=> scheduled_action.next_run_dtm,
					in_due_dtm_relative			=> scheduled_action.due_dtm_relative,
					in_due_dtm_relative_unit	=> scheduled_action.due_dtm_relative_unit,
					in_scheduled_on_due_date	=> scheduled_action.scheduled_on_due_date,
					in_parent_id				=> v_copy_condition_flow_item_id,
					in_issue_type_id			=> scheduled_action.issue_type_id,
					in_create_critical			=> scheduled_action.create_critical,
					out_issue_scheduled_task_id	=> v_copy_issue_scheduled_task_id
				);

				UPDATE issue_scheduled_task
				   SET copied_from_id = v_copy_issue_scheduled_task_id
				 WHERE issue_scheduled_task_id = scheduled_action.issue_scheduled_task_id;
			END LOOP;
		END IF;
	END LOOP;
END;

PROCEDURE CopyPermitItems(
	in_from_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_target_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_clone_actions				IN	NUMBER,
	in_clone_scheduled_actions		IN	NUMBER,
	in_clone_conditions				IN	NUMBER,
	in_clone_cond_actions			IN	NUMBER,
	in_clone_cond_schduled_actions	IN	NUMBER,
	in_action_assignee_user_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	compliance_pkg.AssertComplianceMgr;

	IF in_clone_actions != 0 THEN
		CopyPermitActions(
			in_from_permit_id		=> in_from_permit_id,
			in_target_permit_id		=> in_target_permit_id,
			in_action_assignee_user_sid => in_action_assignee_user_sid
		);
	END IF;

	IF in_clone_scheduled_actions != 0 THEN
		CopyPermitScheduledActions(
			in_from_permit_id		=> in_from_permit_id,
			in_target_permit_id		=> in_target_permit_id,
			in_action_assignee_user_sid => in_action_assignee_user_sid
		);
	END IF;

	IF in_clone_conditions != 0 THEN
		CopyPermitConditions(
			in_from_permit_id		=> in_from_permit_id,
			in_target_permit_id		=> in_target_permit_id,
			in_clone_cond_actions	=> 	in_clone_cond_actions,
			in_clone_cond_schduled_actions => in_clone_cond_schduled_actions,
			in_action_assignee_user_sid => in_action_assignee_user_sid
		);
	END IF;
END;

-- Start of issue type helper procedures
PROCEDURE OnScheduledTaskCreated (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_parent_id					IN  NUMBER
)
AS
	v_label							issue_scheduled_task.label%TYPE;
	v_permit_cnt					NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_permit_cnt
	  FROM csr.compliance_permit cp
	 WHERE cp.flow_item_id = in_parent_id;

	IF v_permit_cnt > 0 THEN
		INTERNAL_AssertCanEditFlowItem(in_parent_id);

		SELECT label
		  INTO v_label
		  FROM issue_scheduled_task
		 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;

		BEGIN
			INSERT INTO comp_permit_sched_issue (issue_scheduled_task_id, flow_item_id)
				 VALUES (in_issue_scheduled_task_id, in_parent_id);

			INTERNAL_AddAuditLogEntry(in_parent_id, 'New scheduled action {0} added', v_label, null, null, null);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				INTERNAL_AddAuditLogEntry(in_parent_id, 'Scheduled action {0} modified', v_label, null, null, null);
		END;
	ELSE
		compliance_pkg.OnScheduledTaskCreated(in_issue_scheduled_task_id, in_parent_id);
	END IF;
END; 
 
PROCEDURE OnScheduledTaskDeleted (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE
)
AS
	v_flow_item_id					comp_permit_sched_issue.flow_item_id%TYPE;
	v_label							issue_scheduled_task.label%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM comp_permit_sched_issue
		 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--Check in compliance for permit conditions
			compliance_pkg.OnScheduledTaskDeleted(in_issue_scheduled_task_id);
	END;

	IF v_flow_item_id > 0 THEN
		INTERNAL_AssertCanEditFlowItem(v_flow_item_id);

		DELETE FROM comp_permit_sched_issue
		 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;

		SELECT label
		  INTO v_label
		  FROM issue_scheduled_task
		 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;

		INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Scheduled action {0} deleted', v_label, null, null, null);
	END IF;
 
END; 

PROCEDURE OnScheduledIssueCreated (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_issue_id						IN  issue.issue_id%TYPE
)
AS
	v_permit_id						compliance_permit.compliance_permit_id%TYPE;
	v_issue_compliance_region_id	issue.issue_compliance_region_id%TYPE;
BEGIN
	-- no security check, called from scheduled task
	BEGIN
		SELECT compliance_permit_id
		  INTO v_permit_id
		  FROM compliance_permit
		 WHERE flow_item_id = (SELECT flow_item_id
								 FROM comp_permit_sched_issue
								WHERE issue_scheduled_task_id = in_issue_scheduled_task_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			BEGIN
				SELECT cpc.compliance_permit_id
				  INTO v_permit_id
				  FROM comp_item_region_sched_issue cirsi
				  JOIN compliance_item_region cir ON cirsi.flow_item_id = cir.flow_item_id
				  JOIN compliance_permit_condition cpc ON cir.compliance_item_id  = cpc.compliance_item_id
				 WHERE cirsi.issue_scheduled_task_id = in_issue_scheduled_task_id;
			
				compliance_pkg.OnScheduledIssueCreated(in_issue_scheduled_task_id, in_issue_id);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
	END;
	
	UPDATE issue 	
	   SET permit_id = v_permit_id
	 WHERE issue_id = in_issue_id;  
	
END;

PROCEDURE OnSetIssueCritical(
	in_issue_id						IN  issue.issue_id%TYPE,
	in_value						IN  issue.is_critical%TYPE,
	out_issue_changed				OUT	NUMBER
)
AS
BEGIN
	IF in_value != 0 THEN
		INTERNAL_AddManagersToIssue(in_issue_id);
		out_issue_changed := 1;
	END IF;
END;

PROCEDURE GetScheduledIssues ( 
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_flow_item_id					compliance_permit.flow_item_id%TYPE;
BEGIN

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_compliance_permit_id;
	
	INTERNAL_AssertFlowAccessPmt(v_flow_item_id);
	
	OPEN out_cur FOR
		SELECT ist.issue_scheduled_task_id, ist.label, ist.schedule_xml, ist.period_xml,
			   ist.assign_to_user_sid, au.full_name assign_to_full_name,
			   ist.raised_by_user_sid, ru.full_name raised_by_full_name,
			   ist.last_created, ist.due_dtm_relative, ist.due_dtm_relative_unit, ist.scheduled_on_due_date,
			   ist.create_critical
		  FROM issue_scheduled_task ist
		  JOIN csr_user au ON ist.app_sid = au.app_sid AND ist.assign_to_user_sid = au.csr_user_sid
		  JOIN csr_user ru ON ist.app_sid = ru.app_sid AND ist.raised_by_user_sid = ru.csr_user_sid
		  JOIN comp_permit_sched_issue cpsi ON ist.issue_scheduled_task_id = cpsi.issue_scheduled_task_id
		 WHERE cpsi.flow_item_id = v_flow_item_id;
END;
 
-- End of issue type helper procedures 

--For ActiveApplicationsPortlet
PROCEDURE GetActiveApplicationsForUser(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR,
	out_pauses			OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
	v_flow_item_ids					security_pkg.T_SID_IDS;
	v_flow_items_table				security.T_SID_TABLE;
BEGIN
	SELECT cpa.flow_item_id
	  BULK COLLECT INTO v_flow_item_ids
	  FROM compliance_permit_application cpa
	  JOIN compliance_permit cp ON cpa.permit_id = cp.compliance_permit_id
	  JOIN compl_permit_app_status cpas ON cpas.compl_permit_app_status_id = cpa.compl_permit_app_status_id
	  JOIN compliance_application_type cpat ON cpat.application_type_id = cpa.application_type_id
	  JOIN flow_item fi ON cpa.flow_item_id = fi.flow_item_id
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	  JOIN v$region r ON cp.app_sid = r.app_sid AND cp.region_sid = r.region_sid AND r.active = 1
	 WHERE fs.flow_state_nature_id NOT IN (csr_data_pkg.NATURE_APPLIC_DETERMINED, csr_data_pkg.NATURE_APPLIC_WITHDRAWN)
	   AND (in_search IS NULL OR (
			LOWER(cpa.title) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cpa.application_reference) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cpas.label) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cpat.description) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(r.description) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(fs.label) LIKE '%'||LOWER(in_search)||'%')
	   )
	   AND (EXISTS (
				SELECT 1
				  FROM region_role_member rrm
				  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				 WHERE rrm.app_sid = cpa.app_sid
				   AND rrm.region_sid = cp.region_sid
				   AND rrm.user_sid = v_user_sid
				   AND fsr.flow_state_id = fi.current_state_id
			)
			OR EXISTS (
				SELECT 1
				  FROM flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid 
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND fsr.flow_state_id = fi.current_state_id
			)
		);
	
	v_flow_items_table := security_pkg.SidArrayToTable(v_flow_item_ids);
	
	out_total := v_flow_items_table.COUNT;
	
	OPEN out_cur FOR
		SELECT permit_id, permit_application_id, application_reference, flow_state_label, title, submission_dtm, duly_made_dtm, 
			region_description, flow_updated_dtm, application_type_label
		  FROM (
			SELECT cpa.permit_id, cpa.permit_application_id, cpa.application_Reference, fs.label flow_state_label, cpa.title, cpa.submission_dtm, cpa.duly_made_dtm, 
				r.description region_description, fsl.set_dtm flow_updated_dtm, cpat.description application_type_label, rownum rn			
			  FROM compliance_permit_application cpa
			  JOIN compliance_permit cp ON cp.compliance_permit_id = cpa.permit_id
			  JOIN compliance_application_type cpat ON cpat.application_type_id = cpa.application_type_id
			  JOIN v$region r ON cp.region_sid = r.region_sid
			  JOIN flow_item fi ON cpa.flow_item_id = fi.flow_item_id
			  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
			  JOIN flow_state_log fsl ON fi.last_flow_state_log_id = fsl.flow_state_log_id
			  JOIN TABLE(v_flow_items_table) fit ON fi.flow_item_id = fit.column_value
			 ORDER BY fs.label)
	     WHERE rn BETWEEN in_start_row AND in_start_row + in_page_size -1;
	OPEN out_pauses FOR
		SELECT cpap.application_pause_id, cpap.permit_application_id, cpap.paused_dtm, NVL(cpap.resumed_dtm, SYSDATE) resumed_dtm
		  FROM compl_permit_application_pause cpap
		  JOIN compliance_permit_application cpa ON cpap.permit_application_id = cpa.permit_application_id
		  JOIN TABLE(v_flow_items_table) fit ON cpa.flow_item_id = fit.column_value;
		  
END;

--For ApplicationSummaryPortlet
PROCEDURE GetApplicationSummaryForUser (
	out_cur							OUT	SYS_REFCURSOR	
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_app_ids						security_pkg.T_SID_IDS;
	v_apps_table					security.T_SID_TABLE;
BEGIN
	
	SELECT application_flow_sid
	  INTO v_flow_sid
	  FROM compliance_options;
	
	SELECT cpa.permit_application_id
	   BULK COLLECT INTO v_app_ids
	   FROM compliance_permit cp
	   JOIN compliance_permit_application cpa ON cp.compliance_permit_id = cpa.permit_id
	   JOIN flow_item fi ON cpa.app_sid = fi.app_sid AND cpa.flow_item_id = fi.flow_item_id
	   JOIN region r ON cp.app_sid = r.app_sid AND cp.region_sid = r.region_sid AND r.active = 1
	  WHERE EXISTS (
			SELECT 1
			  FROM region_role_member rrm
			  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
			 WHERE rrm.app_sid = cp.app_sid
			   AND rrm.region_sid = cp.region_sid
			   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND fsr.flow_state_id = fi.current_state_id )
		 OR EXISTS (
			SELECT 1
			  FROM flow_state_role fsr
			  JOIN security.act act ON act.sid_id = fsr.group_sid 
			 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
			   AND fsr.flow_state_id = fi.current_state_id ); 
	
	v_apps_table := security_pkg.SidArrayToTable(v_app_ids);
	
	OPEN out_cur FOR
		WITH user_cpas AS (
			SELECT permit_application_id, application_type_id, flow_item_id 
			  FROM compliance_permit_application cpa
			  JOIN TABLE(v_apps_table) appt ON cpa.permit_application_id = appt.column_value
		)
		SELECT ts.application_type_id, ts.flow_state_id, COUNT(user_cpas.permit_application_id) application_count
		  FROM (
			SELECT fs.flow_state_id, cpat.application_type_id
			  FROM flow_state fs
			 CROSS JOIN compliance_application_type cpat
			 WHERE fs.flow_sid = v_flow_sid
			   AND fs.is_deleted = 0) ts
		  LEFT JOIN flow_item fi ON ts.flow_state_id = fi.current_state_id
		  LEFT JOIN user_cpas ON user_cpas.flow_item_id = fi.flow_item_id AND user_cpas.application_type_id = ts.application_type_id
		 GROUP BY ts.application_type_id, ts.flow_state_id
		 UNION ALL
		SELECT -1, ts.flow_state_id, COUNT(user_cpas.permit_application_id) application_count
		  FROM (
			SELECT fs.flow_state_id
			  FROM flow_state fs
			 WHERE fs.flow_sid = v_flow_sid
			   AND fs.is_deleted = 0) ts
		  LEFT JOIN flow_item fi ON ts.flow_state_id = fi.current_state_id
		  LEFT JOIN user_cpas ON user_cpas.flow_item_id = fi.flow_item_id
		 GROUP BY ts.flow_state_id
		 UNION ALL 
		SELECT ts.application_type_id, -1, COUNT(user_cpas.permit_application_id) application_count
		  FROM (
			SELECT cpat.application_type_id
			  FROM compliance_application_type cpat) ts
			  LEFT JOIN user_cpas ON user_cpas.application_type_id = ts.application_type_id
		 GROUP BY ts.application_type_id;		  
END;

--Permit score stuff
PROCEDURE SetPermitScore (
	in_permit_id				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	score_threshold.score_threshold_id%TYPE,
	in_score					IN	compliance_permit_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  compliance_permit_score.set_dtm%TYPE DEFAULT TRUNC(SYSDATE),
	in_valid_until_dtm			IN  compliance_permit_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  compliance_permit_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  compliance_permit_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  compliance_permit_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  compliance_permit_score.comment_text%TYPE DEFAULT NULL
)
AS
	v_count						NUMBER;
	v_comp_perm_score_id		compliance_permit_score.compliance_permit_score_id%TYPE;
	v_flow_item_id				compliance_permit.flow_item_id%TYPE;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;
	
	INTERNAL_AssertFlowAccessPmt(v_flow_item_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM score_type
	 WHERE app_sid = security_pkg.GetApp
	   AND score_type_id = in_score_type_id
	   AND allow_manual_set = 1;

	IF v_count != 1 AND in_is_override = 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot manually set score threshold for a score type that doesn''t allow manual setting');
	END IF;
	
	BEGIN    
		INSERT INTO compliance_permit_score (compliance_permit_score_id, compliance_permit_id, score_threshold_id, 
					score_type_id, score, set_dtm, valid_until_dtm, is_override, score_source_type, score_source_id, comment_text)
		VALUES (compliance_permit_score_id_seq.NEXTVAL, in_permit_id, in_threshold_id, 
					in_score_type_id, in_score, in_set_dtm, in_valid_until_dtm, in_is_override, in_score_source_type, in_score_source_id, in_comment_text)
		RETURNING compliance_permit_score_id INTO v_comp_perm_score_id;
					
		-- end any other scores where there is no valid_until_dtm set or valid_until_dtm is after the start date of the new score - the new score id the only one that matters
		UPDATE compliance_permit_score
		   SET valid_until_dtm = in_set_dtm
		 WHERE compliance_permit_id = in_permit_id
		   AND score_type_id = in_score_type_id
		   AND is_override = in_is_override
		   AND (valid_until_dtm IS NULL OR valid_until_dtm >= in_set_dtm)
		   AND compliance_permit_score_id <> v_comp_perm_score_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE compliance_permit_score 
			   SET  score_threshold_id = in_threshold_id, 
					score = in_score, 
					valid_until_dtm = in_valid_until_dtm, 
					score_source_type = in_score_source_type, 
					score_source_id = in_score_source_id, 
					comment_text = in_comment_text
			 WHERE compliance_permit_id = in_permit_id
			   AND score_type_id = in_score_type_id
			   AND set_dtm = in_set_dtm
			   AND is_override = in_is_override;
	END;
END;

PROCEDURE SetPermitScore (
	in_permit_id				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_thresh_lookup_key		IN	score_threshold.lookup_key%TYPE,
	in_score					IN	compliance_permit_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  compliance_permit_score.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  compliance_permit_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  compliance_permit_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  compliance_permit_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  compliance_permit_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  compliance_permit_score.comment_text%TYPE DEFAULT NULL
)
AS
	v_threshold_id				compliance_permit_score.score_threshold_id%TYPE;
BEGIN
	-- want to blow up if we can't find a lookup key here
	SELECT score_threshold_id 
	  INTO v_threshold_id
	  FROM score_threshold
	 WHERE score_type_id = in_score_type_id
	   AND lookup_key = in_thresh_lookup_key;

	SetPermitScore(in_permit_id, in_score_type_id, v_threshold_id,	in_score, in_set_dtm,
					in_valid_until_dtm, in_is_override, in_score_source_type, in_score_source_id, in_comment_text);
END;

PROCEDURE DeletePermitScore (
	in_permit_id				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_set_dtm					IN  compliance_permit_score.set_dtm%TYPE,
	in_valid_until_dtm			IN  compliance_permit_score.valid_until_dtm%TYPE,
	in_is_override				IN  compliance_permit_score.is_override%TYPE DEFAULT 0
)
AS
	v_count						NUMBER;
BEGIN
	compliance_pkg.AssertComplianceMgr;

	SELECT COUNT(*)
	  INTO v_count
	  FROM score_type
	 WHERE app_sid = security_pkg.GetApp
	   AND score_type_id = in_score_type_id
	   AND allow_manual_set = 1;

	IF v_count != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot manually delete score threshold for a score type that doesn''t allow manual setting');
	END IF;

	DELETE FROM compliance_permit_score 
	 WHERE compliance_permit_id = in_permit_id
	   AND score_type_id = in_score_type_id
	   AND set_dtm = in_set_dtm
	   AND valid_until_dtm = in_valid_until_dtm
	   AND is_override = in_is_override;	
END;

PROCEDURE GetPermitScores(
	in_permit_id				IN  security_pkg.T_SID_ID,
	out_permit_scores_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_flow_item_id						security_pkg.T_SID_ID;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;
	
	INTERNAL_AssertFlowAccessPmt(v_flow_item_id);

	OPEN out_permit_scores_cur FOR
		SELECT s.compliance_permit_id, st.score_threshold_id, s.set_dtm, s.valid_until_dtm, s.score, 
			   t.score_type_id, st.description, st.text_colour, st.background_colour, t.format_mask, 
			   t.allow_manual_set, t.label score_type_label
		  FROM score_type t
		  LEFT JOIN v$current_compl_perm_score s 
			ON t.score_type_id = s.score_type_id 
		   AND s.compliance_permit_id = in_permit_id
		  LEFT JOIN score_threshold st ON st.score_threshold_id = s.score_threshold_id
		 WHERE (t.allow_manual_set = 1 OR s.score IS NOT NULL OR s.score_threshold_id IS NOT NULL)
		   AND t.hidden = 0
		   AND t.applies_to_permits = 1
		 ORDER BY t.pos, t.score_type_id;
END;

PROCEDURE INTERNAL_DeleteApplication(
	in_application_id				IN  security_pkg.T_SID_ID	
)
AS
	v_flow_item_id					security_pkg.T_SID_ID;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit_application
	 WHERE permit_application_id = in_application_id;

	DELETE FROM compl_permit_application_pause
	 WHERE permit_application_id = in_application_id;
	 
	DELETE FROM compliance_permit_application
	 WHERE permit_application_id = in_application_id;
	
	DELETE FROM flow_state_log
	 WHERE flow_item_id = v_flow_item_id;
	
	DELETE FROM flow_item
	 WHERE flow_item_id = v_flow_item_id;
END;

PROCEDURE UNSEC_DeletePermit(
	in_permit_id					IN  security_pkg.T_SID_ID
)
AS
	v_conditions				security.T_SID_TABLE;
	v_flow_item_id					security_pkg.T_SID_ID;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;
	 
	SELECT cpc.compliance_item_id 
	  BULK COLLECT INTO v_conditions
	  FROM compliance_permit_condition cpc
	  JOIN compliance_permit cp
		ON cpc.app_sid = cp.app_sid 
	   AND cpc.compliance_permit_id = cp.compliance_permit_id
	 WHERE cp.compliance_permit_id = in_permit_id
	   FOR UPDATE;
	
	FOR r IN (SELECT permit_application_id FROM compliance_permit_application WHERE permit_id = in_permit_id)
	LOOP
		INTERNAL_DeleteApplication(r.permit_application_id);
	END LOOP;
	
	FOR R IN (
		SELECT issue_id
		  FROM issue
		 WHERE permit_id = in_permit_id
	) LOOP
		issue_pkg.UNSEC_DeleteIssue(r.issue_id);	
	END LOOP;
	
	FOR R IN (
		SELECT ist.issue_scheduled_task_id
		  FROM issue_scheduled_task ist
		  JOIN comp_permit_sched_issue cpsi ON ist.app_sid = cpsi.app_sid AND ist.issue_scheduled_task_id = cpsi.issue_scheduled_task_id
	) LOOP
		--UNSEC
		issue_pkg.DeleteScheduledTask(r.issue_scheduled_task_id);
	END LOOP;
	
	DELETE FROM comp_permit_sched_issue
	 WHERE flow_item_id = v_flow_item_id; 
	
	DELETE FROM compliance_permit_condition
	 WHERE compliance_item_id IN (SELECT column_value FROM TABLE(v_conditions));

	DELETE FROM compliance_item
	 WHERE compliance_item_id IN (SELECT column_value FROM TABLE(v_conditions));
			
	DELETE FROM doc_folder_name_translation
	 WHERE doc_folder_sid IN (
		SELECT doc_folder_sid
		  FROM doc_folder df
		  JOIN compliance_permit cp ON df.permit_item_id = cp.compliance_permit_id
		 WHERE compliance_permit_id = in_permit_id
		);
		 
	DELETE FROM doc_folder
	 WHERE permit_item_id = in_permit_id;
	
	DELETE FROM compliance_permit 
	 WHERE compliance_permit_id = in_permit_id;
	 
	DELETE FROM flow_state_log
	 WHERE flow_item_id = v_flow_item_id;
	
	DELETE FROM flow_item
	 WHERE flow_item_id = v_flow_item_id;
END;	

END;
/
