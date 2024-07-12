CREATE OR REPLACE PACKAGE BODY CSR.flow_pkg AS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

/*
 email alerts on state change (email different roles / define custom messages)
   - do as "states?" (.e.g like timer state)

 call stored procs

 associate dates with status changes? (compelted on X) maybe not generic
*/

FUNCTION EmptySidIds
RETURN security_pkg.T_SID_IDS
AS
	v security_pkg.T_SID_IDS;
BEGIN
	RETURN v;
END;

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_regions_table	IN	security.T_SID_TABLE
) RETURN NUMBER;

PROCEDURE GetItemCapabilityPermissions (
	in_flow_item_id		IN  flow_item.flow_item_id%TYPE,
	in_region_sids				security.T_SID_TABLE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE Internal_DeleteTransitions (
	in_flow_sid						IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_state_ids 				IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_flow_state_transition_ids	IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_from_flow_state_id			IN	flow_state.flow_state_id%TYPE DEFAULT NULL,
	in_to_flow_state_id				IN	flow_state.flow_state_id%TYPE DEFAULT NULL
)
AS
	v_flow_state_transition_ids		security_pkg.T_SID_IDS := in_flow_state_transition_ids;
	v_flow_state_ids_table			security.T_SID_TABLE;
	v_flow_state_trans_ids_table	security.T_SID_TABLE;
BEGIN


	IF v_flow_state_transition_ids IS NULL OR v_flow_state_transition_ids.COUNT = 0 THEN
		IF in_from_flow_state_id IS NOT NULL AND in_to_flow_state_id IS NOT NULL THEN
			SELECT flow_state_transition_id
			  BULK COLLECT INTO v_flow_state_transition_ids
			  FROM flow_state_transition
			 WHERE from_state_id = in_from_flow_state_id
			   AND to_state_id = in_to_flow_state_id;
		ELSIF in_flow_state_ids IS NOT NULL AND in_flow_state_ids.COUNT > 0 THEN
			v_flow_state_ids_table := security_pkg.SidArrayToTable(in_flow_state_ids);

			SELECT flow_state_transition_id
			  BULK COLLECT INTO v_flow_state_transition_ids
			  FROM flow_state_transition
			 WHERE from_state_id IN (SELECT column_value FROM TABLE(v_flow_state_ids_table))
			    OR to_state_id IN (SELECT column_value FROM TABLE(v_flow_state_ids_table));
		ELSIF in_flow_sid IS NOT NULL THEN
			SELECT flow_state_transition_id
			  BULK COLLECT INTO v_flow_state_transition_ids
			  FROM flow_state_transition
			 WHERE flow_sid = in_flow_sid;
		ELSE
			NULL; -- TODO: throw exception
		END IF;

	END IF;

	IF v_flow_state_transition_ids IS NULL OR v_flow_state_transition_ids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_flow_state_trans_ids_table := security_pkg.SidArrayToTable(v_flow_state_transition_ids);

	UPDATE flow_item
	   SET last_flow_state_transition_id = NULL
	 WHERE last_flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));

	UPDATE section_routed_flow_state
	   SET reject_fs_transition_id = NULL
	 WHERE reject_fs_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));

	DELETE FROM flow_item_generated_alert
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table))
	 );

	DELETE FROM flow_transition_alert_role
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table))
	 );
	
	DELETE FROM flow_transition_alert_cc_role
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table))
	 );
	
	DELETE FROM flow_transition_alert_user
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table))
	 );
	
	DELETE FROM flow_transition_alert_cc_user
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table))
	 );

	DELETE FROM flow_transition_alert_inv
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table))
	 );

	DELETE FROM flow_transition_alert
	 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));

	DELETE FROM flow_state_transition_role
	 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));
	
	DELETE FROM flow_state_transition_inv
	 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));

	DELETE FROM flow_state_transition_cms_col
	 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));

	DELETE FROM flow_state_transition
	 WHERE flow_state_transition_id IN (SELECT column_value FROM TABLE(v_flow_state_trans_ids_table));
END;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	null;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN

	Internal_DeleteTransitions(
		in_flow_sid => in_sid_id
	 );


	DELETE FROM default_initiative_user_state
	 WHERE flow_sid = in_sid_id;

	UPDATE initiative
	   SET flow_item_id = NULL
	 WHERE flow_sid = in_sid_id;

	UPDATE csr.all_property
	   SET flow_item_id = NULL
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE flow_sid = in_sid_id
	 );

	UPDATE csr.section
	   SET flow_item_id = NULL
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE flow_sid = in_sid_id
	 );


	DELETE FROM flow_alert_type
	 WHERE flow_sid = in_sid_id;

	DELETE FROM section_routed_flow_state
	 WHERE flow_sid = in_sid_id;


	DELETE FROM flow_state_log
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	UPDATE chain.supplier_relationship
	   SET flow_item_id = NULL
	 WHERE flow_item_id IN (
		SELECT flow_item_id FROM flow_item WHERE flow_sid = in_sid_id
	 );

	DELETE FROM flow_item_region
	 WHERE flow_item_id IN (
		SELECT flow_item_id FROM flow_item WHERE flow_sid = in_sid_id
	 );

	-- other FK's to FLOW_ITEM are:
	-- csr.activity*, csr.compliance_permit, csr.compliance_permit_application, csr.comp_permit_sched_issue,
	-- CSR.FLOW_INVOLVEMENT_COVERCSR.FLOW_ITEM_REGION, CSR.FLOW_ITEM_INVOLVEMENT, CSR.FLOW_ITEM_SUBSCRIPTION, 
	-- CSR.INTERNAL_AUDIT, CSR.METER_READING, CSR.USER_TRAINING
	-- *appears to be empty/redundant

	DELETE FROM flow_item
	 WHERE flow_sid = in_sid_id;

	DELETE FROM flow_state_role_capability
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM flow_state_role
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM flow_state_cms_col
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM flow_state_involvement
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM cms.flow_tab_column_cons
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM flow_state_survey_tag
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM flow_state
	 WHERE flow_sid = in_sid_id;

	DELETE FROM flow_state_trans_helper
	 WHERE flow_sid = in_sid_id;

	UPDATE cms.tab
	   SET flow_sid = NULL
	 WHERE flow_sid = in_sid_id;

	UPDATE internal_audit_type
	   SET flow_sid = NULL
	 WHERE flow_sid = in_sid_id;

	UPDATE chain.company_type_relationship
	   SET flow_sid = NULL
	 WHERE flow_sid = in_sid_id;

	DELETE FROM flow
	 WHERE flow_sid = in_sid_id;

END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;


PROCEDURE TrashFlow(
	in_flow_sid		IN security_pkg.T_SID_ID
)
AS
	v_act			security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_label			flow.label%TYPE;
BEGIN
	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_flow_sid,
		'Moved to trash');

	SELECT label
	  INTO v_label
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	trash_pkg.TrashObject(v_act, in_flow_sid,
		securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Trash'),
		v_label);
END;

PROCEDURE CreateFlow(
	in_label			IN	flow.label%TYPE,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_flow_sid		OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	CreateFlow(in_label, in_parent_sid, null, out_flow_sid);
END;

PROCEDURE CreateFlow(
	in_label			IN	flow.label%TYPE,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_flow_alert_class	IN  flow.flow_alert_class%TYPE,
	out_flow_sid		OUT	security_pkg.T_SID_ID
)
AS
BEGIN

	securableobject_pkg.CreateSO(security_pkg.getACT,
		in_parent_sid,
		class_pkg.getClassID('CSRFlow'),
		REPLACE(in_label,'/','\'), --'
		out_flow_sid);

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		out_flow_sid,
		'Created workflow "{0}"',
		in_label);

	INSERT INTO FLOW (flow_sid, label, flow_alert_class)
		VALUES (out_flow_sid, in_label, in_flow_alert_class);

	IF in_flow_alert_class = 'corpreporter' THEN
		section_pkg.SetSplitQuestionFlowState(out_flow_sid, NULL);
	END IF;

END;

PROCEDURE RenameFlow(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_label		IN	flow.label%TYPE
)
AS
	v_prev_flow_label	flow.label%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;

	SELECT label
	  INTO v_prev_flow_label
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		in_flow_sid, 'Worflow name', v_prev_flow_label, in_label);

	UPDATE flow
	   SET label = in_label
	 WHERE flow_sid = in_flow_sid;

	-- rename securable object for good measure
	securableobject_pkg.RenameSO(security_pkg.getACT, in_flow_sid,
		REPLACE(in_label,'/','\') --'
		);
END;

PROCEDURE GetFlowsWithForms(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
)
AS
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_parent_sid, Security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED,
			'Permission denied listing contents on the workflow container object with sid '||in_parent_sid);
	END IF;

	OPEN out_flow_cur FOR
		SELECT f.flow_sid, f.label,
			   dfs.flow_state_id default_flow_state_id, dfs.label default_flow_state_label, COUNT(fs.flow_state_id) state_cnt
		  FROM flow f
			JOIN security.securable_object so ON f.flow_sid = so.sid_id AND so.parent_sid_id = in_parent_sid
			LEFT JOIN flow_state dfs ON f.default_state_id = dfs.flow_state_id AND f.app_sid = dfs.app_sid
			LEFT JOIN flow_state fs ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid AND fs.is_deleted = 0
			JOIN cms.tab t ON t.flow_sid = f.flow_sid
         GROUP BY f.flow_sid, f.label, dfs.flow_state_id, dfs.label;
END;

PROCEDURE GetFlows(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
)
AS
BEGIN
	GetFlows(in_parent_sid, null, out_flow_cur);
END;

PROCEDURE GetFlows(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	in_flow_type		IN      flow.flow_alert_class%TYPE,
	out_flow_cur		OUT		SYS_REFCURSOR
)
AS
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_parent_sid, Security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED,
			'Permission denied listing contents on the workflow container object with sid '||in_parent_sid);
	END IF;

	OPEN out_flow_cur FOR
		SELECT f.flow_sid, f.label, f.flow_alert_class,
			   dfs.flow_state_id default_flow_state_id, dfs.label default_flow_state_label, COUNT(fs.flow_state_id) state_cnt
		  FROM flow f
		  JOIN security.securable_object so ON f.flow_sid = so.sid_id AND so.parent_sid_id = in_parent_sid
		  LEFT JOIN flow_state dfs ON f.default_state_id = dfs.flow_state_id AND f.app_sid = dfs.app_sid
		  LEFT JOIN flow_state fs ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid AND fs.is_deleted = 0
		 WHERE (f.flow_alert_class IS NULL AND in_flow_type IS NULL OR
		       f.flow_alert_class = NVL(in_flow_type, f.flow_alert_class))
         GROUP BY f.flow_sid, f.label, f.flow_alert_class, dfs.flow_state_id, dfs.label;
END;

PROCEDURE GetFlowsAndStates(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	in_flow_type		IN      flow.flow_alert_class%TYPE,
	out_flow_cur		OUT		SYS_REFCURSOR,
	out_state_cur		OUT		SYS_REFCURSOR
)
AS
BEGIN
	-- security check done in GetFlows
	GetFlows(in_parent_sid, in_flow_type, out_flow_cur);

	OPEN out_state_cur FOR
		-- sorted so that default state is first
		SELECT fs.flow_sid, fs.flow_state_id, fs.label, fs.lookup_Key, fs.attributes_xml, fs.is_final, fs.state_colour, fs.pos, fs.flow_state_nature_id
		  FROM flow_state fs
		  JOIN flow f ON fs.flow_sid = f.flow_sid AND fs.app_sid = f.app_sid
		  JOIN security.securable_object so ON f.flow_sid = so.sid_id AND so.parent_sid_id = in_parent_sid
		 WHERE fs.is_deleted = 0
		   AND (f.flow_alert_class IS NULL AND in_flow_type IS NULL OR
		       f.flow_alert_class = NVL(in_flow_type, f.flow_alert_class))
		 ORDER BY CASE WHEN f.default_state_id = fs.flow_state_id THEN 1 ELSE 0 END DESC, fs.pos;
END;

PROCEDURE GetFlow(
	in_flow_sid						IN		security_pkg.T_SID_ID,
	out_flow_cur					OUT		SYS_REFCURSOR,
	out_state_cur					OUT		SYS_REFCURSOR,
	out_state_role_cur				OUT		SYS_REFCURSOR,
	out_state_group_cur				OUT		SYS_REFCURSOR,
	out_state_col_cur				OUT		SYS_REFCURSOR,
	out_state_inv_cur				OUT		SYS_REFCURSOR,
	out_state_inv_cap_cur			OUT		SYS_REFCURSOR,
	out_trans_cur					OUT		SYS_REFCURSOR,
	out_trans_role_cur				OUT		SYS_REFCURSOR,
	out_trans_group_cur				OUT		SYS_REFCURSOR,
	out_trans_cms_user_cur			OUT		SYS_REFCURSOR,
	out_trans_inv_cur				OUT		SYS_REFCURSOR,
	out_trans_helper_cur			OUT		SYS_REFCURSOR,
	out_transition_alert_cur        OUT		SYS_REFCURSOR,
	out_transition_alert_role_cur	OUT		SYS_REFCURSOR,
	out_transition_alert_grp_cur	OUT		SYS_REFCURSOR,
	out_transition_alert_user_cur	OUT		SYS_REFCURSOR,
	out_trans_alert_cc_role_cur		OUT		SYS_REFCURSOR,
	out_trans_alert_cc_grp_cur		OUT		SYS_REFCURSOR,
	out_trans_alert_cc_user_cur		OUT		SYS_REFCURSOR,
	out_tsition_alert_cms_col_cur	OUT		SYS_REFCURSOR,
	out_transition_alert_inv_cur	OUT		SYS_REFCURSOR,
	out_state_alert_cur        		OUT		SYS_REFCURSOR,
	out_state_alert_role_cur		OUT		SYS_REFCURSOR,
	out_state_alert_group_cur		OUT		SYS_REFCURSOR,
	out_state_alert_user_cur		OUT		SYS_REFCURSOR,
	out_flow_state_group_cur		OUT		SYS_REFCURSOR,
	out_survey_tag_cur				OUT		SYS_REFCURSOR
)
AS
	v_cms_tab_sid					cms.tab.tab_sid%TYPE;
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	-- check security on all requested sids
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||in_flow_sid);
	END IF;

	OPEN out_flow_cur FOR
		SELECT f.flow_sid, f.label, f.label raw_label, f.default_state_id, t.tab_sid cms_tab_sid, f.flow_alert_class
		  FROM flow f, (
		  		-- XXX: we probably need a constraint here to ensure flow_sid is unique in cms.tab
		  		-- although there's still the hole to fix (child tables of flow tables aren't restricted
		  		-- by the same rules as the master table, and you can query them directly if you can
		  		-- read them) so this will do for now.
		  		SELECT t.app_sid, t.flow_sid, MIN(t.tab_sid) tab_sid
		  		  FROM cms.tab t
		  		 GROUP BY t.app_sid, t.flow_sid) t
		 WHERE f.flow_sid = in_flow_sid
		   AND f.app_sid = t.app_sid(+) AND f.flow_sid = t.flow_sid(+);

	OPEN out_state_cur FOR
		-- sorted so that default state is first
		SELECT fs.flow_sid, fs.flow_state_id, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_final, fs.state_colour, fs.pos, fs.flow_state_nature_id, fs.survey_editable,
				(SELECT COUNT(*)
				   FROM csr.flow_item
				  WHERE current_state_id = fs.flow_state_id
				    AND flow_sid = in_flow_sid) items_in_state
		  FROM flow_state fs
		  JOIN flow f ON fs.flow_sid = f.flow_sid AND fs.app_sid = f.app_sid
		 WHERE fs.flow_sid = in_flow_sid
		   AND fs.is_deleted = 0
		 ORDER BY CASE WHEN f.default_state_id = fs.flow_state_id THEN 1 ELSE 0 END DESC, fs.pos;

	OPEN out_state_role_cur FOR
		SELECT fs.flow_sid, fsr.flow_state_id, fsr.role_sid sid, r.name, fsr.is_editable
		  FROM flow_state_role fsr
		  JOIN role r ON fsr.role_sid = r.role_sid
		  JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id
		 WHERE fs.is_deleted = 0
		   AND fs.flow_sid = in_flow_sid;

	OPEN out_state_group_cur FOR
		SELECT fs.flow_sid, fsr.flow_state_id, fsr.group_sid sid, so.name, fsr.is_editable
		  FROM flow_state_role fsr
		  JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id
		  JOIN security.securable_object so ON so.sid_id = fsr.group_sid AND so.application_sid_id = fsr.app_sid
		 WHERE fs.is_deleted = 0
		   AND fs.flow_sid = in_flow_sid;

	OPEN out_state_col_cur FOR
		SELECT fs.flow_sid, fsc.flow_state_id, fsc.column_sid sid, c.tab_sid,
			   NVL(c.description, c.oracle_column) description, c.oracle_column name,
			   fsc.is_editable
		  FROM flow_state_cms_col fsc
		  JOIN cms.tab_column c ON fsc.column_sid = c.column_sid
		  JOIN flow_state fs ON fsc.flow_state_id = fs.flow_state_id
		 WHERE fs.is_deleted = 0
		   AND fs.flow_sid = in_flow_sid;

	OPEN out_state_inv_cur FOR
		SELECT fs.flow_sid, fsi.flow_state_id, fsi.flow_involvement_type_id, fit.label involvment_type_label,
			   fit.css_class
		  FROM flow_state_involvement fsi
		  JOIN flow_involvement_type fit ON fsi.flow_involvement_type_id = fit.flow_involvement_type_id
		  JOIN flow_state fs ON fsi.flow_state_id = fs.flow_state_id
		 WHERE fs.is_deleted = 0
		   AND fs.flow_sid = in_flow_sid
		   AND fit.app_sid = v_app_sid;

	OPEN out_state_inv_cap_cur FOR
		SELECT fs.flow_sid, fsrc.flow_state_id, fsrc.flow_capability_id, fsrc.role_sid,
			   fsrc.flow_involvement_type_id, fsrc.permission_set, fc.description, fsrc.group_sid
		  FROM flow_state_role_capability fsrc
		  JOIN flow_state fs ON fsrc.flow_state_id = fs.flow_state_id
		  JOIN v$flow_capability fc on fsrc.flow_capability_id = fc.flow_capability_id
		 WHERE fs.is_deleted = 0
		   AND fs.flow_sid = in_flow_sid;

	OPEN out_trans_cur FOR
		SELECT flow_sid, flow_state_transition_id, from_state_id, to_state_id, verb, lookup_key, ask_for_comment,
			   mandatory_fields_message, hours_before_auto_tran, button_icon_path, attributes_xml, helper_sp, pos, owner_can_set,
			   auto_trans_type, auto_schedule_xml, enforce_validation
		  FROM flow_state_transition fst
		 WHERE flow_sid = in_flow_sid
		 ORDER BY from_state_id, pos; -- need this for ordering the XML

	OPEN out_trans_role_cur FOR
		SELECT flow_sid, flow_state_transition_id, fstr.role_sid sid, r.name
		  FROM flow_state_transition_role fstr
		  JOIN role r ON fstr.role_sid = r.role_sid
		  JOIN flow_state fs ON fs.flow_state_id = fstr.from_state_id
		 WHERE flow_state_transition_id IN (
			SELECT flow_state_transition_id
			  FROM flow_state_transition
			 WHERE flow_sid = in_flow_sid
		 );

	OPEN out_trans_group_cur FOR
		SELECT flow_sid, flow_state_transition_id, fstr.group_sid sid, so.name
		  FROM flow_state_transition_role fstr
		  JOIN flow_state fs ON fs.flow_state_id = fstr.from_state_id
		  JOIN security.securable_object so ON so.sid_id = fstr.group_sid AND so.application_sid_id = fstr.app_sid
		 WHERE flow_state_transition_id IN (
			SELECT flow_state_transition_id
			  FROM flow_state_transition
			 WHERE flow_sid = in_flow_sid
		 );

	OPEN out_trans_cms_user_cur FOR
		SELECT flow_sid, flow_state_transition_id, fstc.column_sid sid, c.tab_sid,
			   NVL(c.description, c.oracle_column) description, c.oracle_column name
		  FROM flow_state_transition_cms_col fstc
		  JOIN cms.tab_column c ON fstc.column_sid = c.column_sid
		  JOIN flow_state fs ON fs.flow_state_id = fstc.from_state_id
		 WHERE flow_state_transition_id IN (
			SELECT flow_state_transition_id
			  FROM flow_state_transition
			 WHERE flow_sid = in_flow_sid
		 );

	OPEN out_trans_inv_cur FOR
		SELECT fs.flow_sid, fsti.flow_state_transition_id, fsti.flow_involvement_type_id,
			   fit.label involvment_type_label, fit.css_class
		  FROM flow_state_transition_inv fsti
		  JOIN flow_involvement_type fit ON fsti.flow_involvement_type_id = fit.flow_involvement_type_id
		  JOIN flow_state fs ON fsti.from_state_id = fs.flow_state_id
		 WHERE fit.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND fsti.flow_state_transition_id IN (
			SELECT fst.flow_state_transition_id
			  FROM flow_state_transition fst
			 WHERE fst.flow_sid = in_flow_sid
		 );

	OPEN out_trans_helper_cur FOR
		SELECT fstr.flow_sid, fstr.helper_sp, fstr.label
		  FROM flow_state_trans_helper fstr
		 WHERE fstr.flow_sid = in_flow_sid;

	OPEN out_transition_alert_cur FOR
		SELECT ta.flow_transition_alert_id, ta.flow_state_transition_id, ta.customer_alert_type_id, ta.description, ta.to_initiator,
			ta.can_be_edited_before_sending, DECODE(f.flow_alert_class, 'cms', ta.helper_sp, ta.flow_alert_helper) helper_sp
		  FROM flow f, flow_transition_alert ta
		 WHERE f.flow_sid = in_flow_sid
		   AND ta.flow_state_transition_id IN (
				SELECT flow_state_transition_id
				  FROM flow_state_transition
				 WHERE flow_sid = in_flow_sid
				)
		   AND deleted = 0;

	OPEN out_transition_alert_role_cur FOR
		SELECT ftar.flow_transition_alert_id, ftar.role_sid sid, r.name
		  FROM flow_transition_alert_role ftar, flow_transition_alert fta,
		  	   flow_state_transition fst, role r
		 WHERE fst.flow_sid = in_flow_sid
		   AND fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		   AND fta.app_sid = ftar.app_sid AND fta.flow_transition_alert_id = ftar.flow_transition_alert_id
		   AND ftar.app_sid = r.app_sid AND ftar.role_sid = r.role_sid
		   AND fta.deleted = 0;

	OPEN out_transition_alert_grp_cur FOR
		SELECT ftar.flow_transition_alert_id, ftar.group_sid sid, so.name
		  FROM flow_transition_alert_role ftar
		  JOIN flow_transition_alert fta ON fta.app_sid = ftar.app_sid AND fta.flow_transition_alert_id = ftar.flow_transition_alert_id
		  JOIN flow_state_transition fst ON fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN security.securable_object so ON so.sid_id = ftar.group_sid AND ftar.app_sid = so.application_sid_id
		 WHERE fst.flow_sid = in_flow_sid
		   AND fta.deleted = 0;

	OPEN out_transition_alert_user_cur FOR
		SELECT ftau.flow_transition_alert_id, ftau.user_sid, cu.full_name
		  FROM flow_transition_alert_user ftau, flow_transition_alert fta,
		  	   flow_state_transition fst, csr_user cu
		 WHERE fst.flow_sid = in_flow_sid
		   AND fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		   AND fta.app_sid = ftau.app_sid AND fta.flow_transition_alert_id = ftau.flow_transition_alert_id
		   AND ftau.app_sid = cu.app_sid AND ftau.user_sid = cu.csr_user_sid
		   AND fta.deleted = 0;

	OPEN out_trans_alert_cc_role_cur FOR
		SELECT ftar.flow_transition_alert_id, ftar.role_sid sid, r.name
		  FROM flow_transition_alert_cc_role ftar, flow_transition_alert fta,
		  	   flow_state_transition fst, role r
		 WHERE fst.flow_sid = in_flow_sid
		   AND fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		   AND fta.app_sid = ftar.app_sid AND fta.flow_transition_alert_id = ftar.flow_transition_alert_id
		   AND ftar.app_sid = r.app_sid AND ftar.role_sid = r.role_sid
		   AND fta.deleted = 0;

	OPEN out_trans_alert_cc_grp_cur FOR
		SELECT ftar.flow_transition_alert_id, ftar.group_sid sid, so.name
		  FROM flow_transition_alert_cc_role ftar
		  JOIN flow_transition_alert fta ON fta.app_sid = ftar.app_sid AND fta.flow_transition_alert_id = ftar.flow_transition_alert_id
		  JOIN flow_state_transition fst ON fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN security.securable_object so ON so.sid_id = ftar.group_sid AND ftar.app_sid = so.application_sid_id
		 WHERE fst.flow_sid = in_flow_sid
		   AND fta.deleted = 0;

	OPEN out_trans_alert_cc_user_cur FOR
		SELECT ftau.flow_transition_alert_id, ftau.user_sid, cu.full_name
		  FROM flow_transition_alert_cc_user ftau, flow_transition_alert fta,
		  	   flow_state_transition fst, csr_user cu
		 WHERE fst.flow_sid = in_flow_sid
		   AND fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		   AND fta.app_sid = ftau.app_sid AND fta.flow_transition_alert_id = ftau.flow_transition_alert_id
		   AND ftau.app_sid = cu.app_sid AND ftau.user_sid = cu.csr_user_sid
		   AND fta.deleted = 0;

	OPEN out_tsition_alert_cms_col_cur FOR
		SELECT ftacc.flow_transition_alert_id, ftacc.column_sid sid, ftacc.alert_manager_flag,
			   NVL(ct.description, ct.oracle_column) description, ct.oracle_column name
		  FROM flow_transition_alert_cms_col ftacc, flow_transition_alert fta,
		  	   flow_state_transition fst, cms.tab_column ct
		 WHERE fst.flow_sid = in_flow_sid
		   AND fst.app_sid = fta.app_sid AND fst.flow_state_transition_id = fta.flow_state_transition_id
		   AND fta.app_sid = ftacc.app_sid AND fta.flow_transition_alert_id = ftacc.flow_transition_alert_id
		   AND ftacc.app_sid = ct.app_sid AND ftacc.column_sid = ct.column_sid
		   AND fta.deleted = 0;

	OPEN out_transition_alert_inv_cur FOR
		SELECT ftai.flow_transition_alert_id, ftai.flow_involvement_type_id, fit.label involvment_type_label,
			   fit.css_class
		  FROM flow_transition_alert_inv ftai
		  JOIN flow_transition_alert fta ON ftai.app_sid = fta.app_sid
		   AND ftai.flow_transition_alert_id = fta.flow_transition_alert_id
		  JOIN flow_state_transition fst ON fta.app_sid = fst.app_sid
		   AND fta.flow_state_transition_id = fst.flow_state_transition_id
		  JOIN flow_involvement_type fit ON ftai.flow_involvement_type_id = fit.flow_involvement_type_id
		 WHERE fst.flow_sid = in_flow_sid
		   AND fta.deleted = 0
		   AND fit.app_sid = v_app_sid;

	OPEN out_state_alert_cur FOR
		SELECT flow_state_alert_id, flow_state_id, customer_alert_type_id,
			description, flow_alert_helper helper_sp, recurrence_pattern
		  FROM flow_state_alert
		 WHERE flow_sid = in_flow_sid
		   AND deleted = 0;

	OPEN out_state_alert_role_cur FOR
		SELECT ar.flow_state_alert_id, ar.role_sid sid, r.name
		  FROM flow_state_alert a, flow_State_alert_role ar, role r
		 WHERE a.flow_sid = in_flow_sid
		   AND a.deleted = 0
		   AND ar.app_sid = a.app_sid
		   AND ar.flow_state_alert_id = a.flow_state_alert_id
		   AND ar.flow_sid = a.flow_sid
		   AND r.app_sid = ar.app_sid
		   AND r.role_sid = ar.role_sid;

	OPEN out_state_alert_group_cur FOR
		SELECT ar.flow_state_alert_id, ar.group_sid sid, so.name
		  FROM flow_state_alert a
		  JOIN flow_State_alert_role ar ON ar.flow_state_alert_id = a.flow_state_alert_id AND ar.flow_sid = a.flow_sid AND ar.app_sid = a.app_sid
		  JOIN security.securable_object so ON ar.group_sid = so.sid_id AND ar.app_sid = so.application_sid_id
		 WHERE a.flow_sid = in_flow_sid
		   AND a.deleted = 0;

	OPEN out_state_alert_user_cur FOR
		SELECT au.flow_state_alert_id, au.user_sid, u.full_name
		  FROM flow_state_alert a, flow_state_alert_user au, csr_user u
		 WHERE a.flow_sid = in_flow_sid
		   AND a.deleted = 0
		   AND au.app_sid = a.app_sid
		   AND au.flow_State_alert_id = a.flow_state_alert_id
		   AND au.flow_sid = a.flow_sid
		   AND u.app_sid = au.app_sid
		   AND u.csr_user_sid = au.user_sid;

	OPEN out_flow_state_group_cur FOR
		SELECT fs.flow_sid, fs.flow_state_id, fsg.flow_state_group_id, fsg.lookup_key, fsg.label
		  FROM flow_state fs
		  JOIN flow_state_group_member fsgm
				 ON fs.app_sid = fsgm.app_sid
				AND fs.flow_state_id = fsgm.flow_state_id
		  JOIN flow_state_group fsg
				 ON fsg.app_sid = fsgm.app_sid
				AND fsg.flow_state_group_id = fsgm.flow_state_group_id
		 WHERE fs.flow_sid = in_flow_sid
		   AND fs.app_sid = v_app_sid
		   AND fs.is_deleted = 0
	  ORDER BY fs.flow_state_id, fsg.flow_state_group_id, fsg.flow_state_group_id;

	OPEN out_survey_tag_cur FOR
		SELECT fsst.flow_state_id, fsst.tag_id, tg.name tag_group_name, t.tag tag_label
		  FROM flow_state fs
		  JOIN flow_state_survey_tag fsst ON fs.app_sid = fsst.app_sid AND fs.flow_state_id = fsst.flow_state_id
		  JOIN v$tag t ON fsst.app_sid = t.app_sid AND fsst.tag_id = t.tag_id
		  JOIN tag_group_member tgm ON t.app_sid = tgm.app_sid AND t.tag_id = tgm.tag_id
		  JOIN v$tag_group tg ON tgm.app_sid = tg.app_sid AND tgm.tag_group_id = tg.tag_group_id
		 WHERE fs.flow_sid = in_flow_sid
		   AND fs.app_sid = v_app_sid
		   AND fs.is_deleted = 0
		 ORDER BY fsst.flow_state_id, LOWER(tg.name), LOWER(t.tag);

END;

/**
 * Returns flow states in as best order as we can manage
 */
PROCEDURE GetFlowStates(
	in_flow_sid 	IN 	security_pkg.T_SID_ID,
	out_cur 		OUT SYS_REFCURSOR,
	out_transitions OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||in_flow_sid);
	END IF;

	OPEN out_cur FOR
		SELECT fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key, pos,
		       fs.label untranslated_label,
				(SELECT COUNT(*)
				   FROM csr.flow_item
				  WHERE current_state_id = fs.flow_state_id
					AND flow_sid = in_flow_sid) items_in_state,
			   fs.flow_state_nature_id
	      FROM flow_state fs
	     WHERE is_deleted = 0
		   AND flow_sid = NVL(in_flow_sid, flow_sid)
		 ORDER BY pos;

	     -- argh - this doesn't work due to the way nocycle works
	     /*
		SELECT fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key, MIN(level) seq
	      FROM flow_state fs
	        LEFT JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
	     WHERE fs.is_deleted = 0
	     START WITH flow_state_id = (
	        SELECT f.default_state_id
	          FROM flow f
	         WHERE flow_sid = in_flow_sid
	     )
	     CONNECT BY NOCYCLE PRIOR fst.to_state_id = fs.flow_state_id
	     GROUP BY fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key
	     ORDER BY seq;
	     */

	OPEN out_transitions for
		SELECT flow_state_transition_id, from_state_id, to_state_id, verb, lookup_key, ask_for_comment,
			mandatory_fields_message, hours_before_auto_tran, button_icon_path, enforce_validation
		  FROM flow_state_transition fst
		 WHERE flow_sid = in_flow_sid
		 ORDER BY from_state_id, pos;
END;

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id		IN  flow_item.flow_item_id%TYPE,
	in_regions_table	IN  security.T_SID_TABLE,
	out_cur 			OUT SYS_REFCURSOR
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM flow_item
	 WHERE flow_item_id = in_flow_item_id;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;

	OPEN out_cur FOR
		-- would return multiple rows if multiple roles on the transition
		SELECT DISTINCT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id,
			trm.transition_pos, trm.to_state_label, trm.ask_for_comment, trm.to_state_colour,
			trm.button_icon_path, trm.flow_state_nature_id, trm.lookup_key to_state_lookup_key, trm.enforce_validation
		  FROM (
			SELECT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id,
				   trm.transition_pos, trm.to_state_label, trm.ask_for_comment, trm.to_state_colour,
				   trm.button_icon_path, trm.flow_state_nature_id, tfs.lookup_key, trm.enforce_validation
			  FROM v$flow_item_trans_role_member trm
			  JOIN TABLE (in_regions_table) rs
			    ON trm.region_sid = rs.column_value
			  JOIN flow_state tfs ON trm.to_state_id = tfs.flow_state_id
			 WHERE trm.flow_item_id = in_flow_item_id
			 UNION ALL
			SELECT fi.flow_item_id, fst.flow_state_transition_id, fst.verb, tfs.flow_state_id,
			       fst.pos, tfs.label, fst.ask_for_comment, tfs.state_colour,
				   fst.button_icon_path, tfs.flow_state_nature_id, tfs.lookup_key, fst.enforce_validation
			  FROM flow_item fi
			  JOIN flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
			  JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND tfs.is_deleted = 0
			  JOIN flow_state_transition_role fstr ON fst.flow_state_transition_id = fstr.flow_state_transition_id
			  JOIN security.act act ON act.sid_id = fstr.group_sid
			 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
			   AND fi.flow_item_id = in_flow_item_id
		 ) trm
		 ORDER BY transition_pos, verb;
END;

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id		IN  flow_item.flow_item_id%TYPE,
	in_region_sids		IN  security_pkg.T_SID_IDS,
	out_cur 			OUT SYS_REFCURSOR
)
AS
	v_regions_table 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	GetFlowItemTransitions(in_flow_item_id, v_regions_table, out_cur);
END;

PROCEDURE GetFlowItemTransitions(
	in_flow_item_ids	IN  security_pkg.T_SID_IDS,
	in_region_sids		IN  security_pkg.T_SID_IDS,
	out_cur 			OUT SYS_REFCURSOR
)
AS
	v_flow_sid			security_pkg.T_SID_ID;
	v_regions_table 	security.T_SID_TABLE;
	v_flow_items_table	security.T_SID_TABLE;
BEGIN
	v_flow_items_table := security_pkg.SidArrayToTable(in_flow_item_ids);
	v_regions_table := security_pkg.SidArrayToTable(in_region_sids);

	SELECT fi.flow_sid
	  INTO v_flow_sid
	  FROM TABLE(v_flow_items_table) fit
	  JOIN flow_item fi ON fit.column_value = fi.flow_item_id
	 GROUP BY fi.flow_sid;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;

	OPEN out_cur FOR
		-- would return multiple rows if multiple roles on the transition
		SELECT DISTINCT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id,
			trm.transition_pos, trm.to_state_label, trm.ask_for_comment, trm.to_state_colour,
			trm.button_icon_path, trm.flow_state_nature_id, trm.enforce_validation
		  FROM (
			SELECT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id,
				   trm.transition_pos, trm.to_state_label, trm.ask_for_comment, trm.to_state_colour,
				   trm.button_icon_path, trm.flow_state_nature_id, trm.enforce_validation
			  FROM v$flow_item_trans_role_member trm
			  JOIN TABLE(v_flow_items_table) fit ON trm.flow_item_id = fit.column_value
			  JOIN TABLE (v_regions_table) rs
			    ON trm.region_sid = rs.column_value
			 UNION ALL
			SELECT fi.flow_item_id, fst.flow_state_transition_id, fst.verb, tfs.flow_state_id,
			       fst.pos, tfs.label, fst.ask_for_comment, tfs.state_colour,
				   fst.button_icon_path, tfs.flow_state_nature_id, fst.enforce_validation
			  FROM flow_item fi
			  JOIN flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
			  JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND tfs.is_deleted = 0
			  JOIN flow_state_transition_role fstr ON fst.flow_state_transition_id = fstr.flow_state_transition_id
			  JOIN TABLE(v_flow_items_table) fit ON fi.flow_item_id = fit.column_value
			  JOIN security.act act ON act.sid_id = fstr.group_sid
			 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		 ) trm
		 ORDER BY transition_pos, verb;
END;

PROCEDURE SetStateTransHelper(
	in_flow_sid		IN 	security_pkg.T_SID_ID,
	in_helper_sp	IN	flow_state_trans_helper.helper_sp%TYPE,
	in_label		IN	flow_state_trans_helper.label%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;

	BEGIN
		INSERT INTO flow_state_trans_helper (flow_sid, helper_sp, label)
			VALUES (in_flow_sid, in_helper_sp, in_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE flow_state_trans_helper
			    SET label = in_label
			  WHERE flow_sid = in_flow_sid
			    AND helper_sp = in_helper_sp;
	END;
END;

PROCEDURE SetAlertHelper(
	in_helper_sp	IN	flow_alert_helper.flow_alert_helper%TYPE,
	in_label		IN	flow_alert_helper.label%TYPE
)
AS
	v_workflows_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Workflows');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_workflows_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing workflow');
	END IF;

	BEGIN
		INSERT INTO flow_alert_helper (flow_alert_helper, label)
			VALUES (in_helper_sp, in_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE flow_alert_helper
			    SET label = in_label
			  WHERE flow_alert_helper = in_helper_sp;
	END;
END;

PROCEDURE SetCmsAlertHelper(
	in_tab_sid		IN	cms_alert_helper.tab_sid%TYPE,
	in_helper_sp	IN	cms_alert_helper.helper_sp%TYPE,
	in_label		IN	cms_alert_helper.description%TYPE
)
AS
	v_workflows_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Workflows');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_workflows_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing workflow');
	END IF;

	BEGIN
		INSERT INTO cms_alert_helper (tab_sid, helper_sp, description)
			VALUES (in_tab_sid, in_helper_sp, in_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE cms_alert_helper
			    SET description = in_label
			  WHERE tab_sid = in_tab_sid
			    AND helper_sp = in_helper_sp;
	END;
END;

PROCEDURE RemoveStateTransHelper(
	in_flow_sid		IN 	security_pkg.T_SID_ID,
	in_helper_sp	IN	flow_state_trans_helper.helper_sp%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;

	DELETE FROM flow_state_trans_helper
	 WHERE flow_sid = in_flow_sid AND UPPER(in_helper_sp) = UPPER(helper_sp);
END;

-- internal use only (i.e. for xml synching)
PROCEDURE CreateState(
	in_flow_state_id		IN  flow_state.flow_state_id%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_label				IN	flow_state.label%TYPE,
	in_lookup_key			IN	flow_state.lookup_key%TYPE DEFAULT NULL,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE,
	in_survey_editable		IN	flow_state.survey_editable%TYPE DEFAULT 1
)
AS
	v_flow_label	flow.label%TYPE;
	v_flow_sid		security_pkg.T_SID_ID;
	v_lookup_count 		NUMBER;
	v_duplicate_state	VARCHAR2(1024);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;
	
	SELECT COUNT(*) 
	  INTO v_lookup_count 
	  FROM flow_state 
	 WHERE lookup_key = in_lookup_key
	   AND label != in_label
	   AND flow_sid = in_flow_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_lookup_count > 0 THEN
		SELECT label
		  INTO v_duplicate_state
		  FROM flow_state
		 WHERE lookup_key = in_lookup_key
		   AND flow_sid = in_flow_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_LOOKUP_KEY_CONSTRAINT_VIOLATED, 'States:' || v_duplicate_state || ', ' || in_label);
	END IF;
	
	INSERT INTO flow_state (flow_state_id, flow_sid, label, lookup_key, flow_state_nature_id, survey_editable)
		VALUES (in_flow_state_id, in_flow_sid, in_label, in_lookup_key, in_flow_state_nature_id, in_survey_editable);

	SELECT label, flow_sid
	  INTO v_flow_label, v_flow_sid
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		v_flow_sid,
		'Added state "{0}" to workflow "{1}"',
		in_label,
		v_flow_label);

	-- set the default state if this is the first one
	UPDATE flow
	   SET default_state_id = in_flow_state_id
	 WHERE flow_sid = in_flow_sid
	   AND default_state_id IS NULL;
END;


PROCEDURE CreateState(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_label				IN	flow_state.label%TYPE,
	in_lookup_key			IN	flow_state.lookup_key%TYPE DEFAULT NULL,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE,
	in_survey_editable		IN	flow_state.survey_editable%TYPE DEFAULT 1,
	out_flow_state_id		OUT	flow_state.flow_state_id%TYPE
)
AS
BEGIN
	SELECT flow_state_id_seq.nextval
	  INTO out_flow_state_Id
	  FROM DUAL;

	CreateState(out_flow_state_Id, in_flow_sid, in_label, in_lookup_key, in_flow_state_nature_id, in_survey_editable);
END;

PROCEDURE SetStateRoles(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_editable_role_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_role_sids	IN	security_pkg.T_SID_IDS,
	in_editable_col_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_col_sids	IN	security_pkg.T_SID_IDS,
	in_involved_type_ids		IN	security_pkg.T_SID_IDS,
	in_editable_group_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_group_sids	IN	security_pkg.T_SID_IDS
)
AS
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fs.label state_label
		  FROM flow_state fs
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE fs.flow_state_id = in_state_id;
	ar	c%ROWTYPE;
    t_editable_role_sids 		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_editable_role_sids);
    t_non_editable_role_sids 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_non_editable_role_sids);
    t_editable_col_sids 		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_editable_col_sids);
    t_non_editable_col_sids 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_non_editable_col_sids);
    t_involved_type_ids			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_involved_type_ids);
    t_editable_group_sids 		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_editable_group_sids);
    t_non_editable_group_sids 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_non_editable_group_sids);
BEGIN
	-- we audit this, so the long way round (rather than just deleting)
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow state '||in_state_id||' not found');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, ar.flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||ar.flow_sid);
	END IF;

	-- deleted roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT role_sid
			  FROM flow_state_role
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_editable_role_sids)
			 MINUS
			SELECT column_value FROM TABLE(t_non_editable_role_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted role "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		DELETE FROM flow_state_role_capability
		 WHERE flow_state_id = in_state_id
		   AND role_sid = r.role_sid;

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_role too
		DELETE FROM flow_state_role
		 WHERE flow_state_id = in_state_Id
		   AND role_sid = r.role_sid;
	END LOOP;

	-- deleted groups
	FOR r IN (
		SELECT gt.sid_id, so.name
		  FROM security.group_table gt
		  JOIN security.securable_object so on gt.sid_id = so.sid_id
		  JOIN security.securable_object_class soc on so.class_id = soc.class_id
		 WHERE (soc.class_name = 'Group' or soc.class_name = 'CSRUserGroup')
		   AND gt.sid_id IN (
			SELECT group_sid
			  FROM flow_state_role
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_editable_group_sids)
			 MINUS
			SELECT column_value FROM TABLE(t_non_editable_group_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted group "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		DELETE FROM flow_state_role_capability
		 WHERE flow_state_id = in_state_id
		   AND group_sid = r.sid_id;

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_role too
		DELETE FROM flow_state_role
		 WHERE flow_state_id = in_state_Id
		   AND group_sid = r.sid_id;
	END LOOP;

	-- added roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			(
				SELECT column_value FROM TABLE(t_editable_role_sids)
				 UNION
				SELECT column_value FROM TABLE(t_non_editable_role_sids)
			)
			  MINUS
			SELECT role_sid
			  FROM flow_state_role
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added role "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		INSERT INTO flow_state_role(flow_state_id, role_sid, is_editable)
			VALUES (in_state_id, r.role_sid, 0);
	END LOOP;

	-- added groups
	FOR r IN (
		SELECT gt.sid_id, so.name
		  FROM security.group_table gt
		  JOIN security.securable_object so on gt.sid_id = so.sid_id
		  JOIN security.securable_object_class soc on so.class_id = soc.class_id
		 WHERE (soc.class_name = 'Group' or soc.class_name = 'CSRUserGroup')
		   AND gt.sid_id IN (
			(
				SELECT column_value FROM TABLE(t_editable_group_sids)
				 UNION
				SELECT column_value FROM TABLE(t_non_editable_group_sids)
			)
			MINUS
			SELECT group_sid
			  FROM flow_state_role
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added group "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		INSERT INTO flow_state_role(flow_state_id, group_sid, is_editable)
			VALUES (in_state_id, r.sid_id, 0);
	END LOOP;

	-- deleted columns
	FOR r IN (
		SELECT column_sid, oracle_column name
		  FROM cms.tab_column
		 WHERE column_sid IN (
			SELECT column_sid
			  FROM flow_state_cms_col
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_editable_col_sids)
			 MINUS
			SELECT column_value FROM TABLE(t_non_editable_col_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted column "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_column too
		DELETE FROM flow_state_cms_col
		 WHERE flow_state_id = in_state_Id
		   AND column_sid = r.column_sid;
	END LOOP;

	-- added columns
	FOR r IN (
		SELECT column_sid, oracle_column name
		  FROM cms.tab_column
		 WHERE column_sid IN (
			(
				SELECT column_value FROM TABLE(t_editable_col_sids)
				 UNION
				SELECT column_value FROM TABLE(t_non_editable_col_sids)
			)
			  MINUS
			SELECT column_sid
			  FROM flow_state_cms_col
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		INSERT INTO flow_state_cms_col (flow_state_id, column_sid, is_editable)
			VALUES (in_state_id, r.column_sid, 0);
	END LOOP;

	-- deleted invoved
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM csr.flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			SELECT flow_involvement_type_id
			  FROM flow_state_involvement
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_involved_type_ids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted involvement "{1}" for state "{2}"',
			ar.flow_label, r.label, ar.state_label);

		DELETE FROM flow_state_role_capability
		 WHERE flow_state_id = in_state_id
		   AND flow_involvement_type_id = r.flow_involvement_type_id;

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_column too
		DELETE FROM flow_state_involvement
		 WHERE flow_state_id = in_state_Id
		   AND flow_involvement_type_id = r.flow_involvement_type_id;
	END LOOP;

	-- added involved
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM csr.flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			(
				SELECT column_value FROM TABLE(t_involved_type_ids)
			)
			  MINUS
			SELECT flow_involvement_type_id
			  FROM flow_state_involvement
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for state "{2}"',
			ar.flow_label, r.label, ar.state_label);

		INSERT INTO flow_state_involvement (flow_state_id, flow_involvement_type_id)
			VALUES (in_state_id, r.flow_involvement_type_id);
	END LOOP;

	-- finally set editable or not
	UPDATE flow_state_role
	   SET is_editable = 1
	 WHERE flow_state_id = in_state_id
	   AND role_sid IN (SELECT column_value FROM TABLE(t_editable_role_sids))
	   AND is_editable = 0;

	UPDATE flow_state_role
	   SET is_editable = 1
	 WHERE flow_state_id = in_state_id
	   AND group_sid IN (SELECT column_value FROM TABLE(t_editable_group_sids))
	   AND is_editable = 0;

	UPDATE flow_state_role
	   SET is_editable = 0
	 WHERE flow_state_id = in_state_id
	   AND role_sid IN (SELECT column_value FROM TABLE(t_non_editable_role_sids))
	   AND is_editable = 1;

	UPDATE flow_state_role
	   SET is_editable = 0
	 WHERE flow_state_id = in_state_id
	   AND group_sid IN (SELECT column_value FROM TABLE(t_non_editable_group_sids))
	   AND is_editable = 1;

	UPDATE flow_state_cms_col
	   SET is_editable = 1
	 WHERE flow_state_id = in_state_id
	   AND column_sid IN (SELECT column_value FROM TABLE(t_editable_col_sids))
	   AND is_editable = 0;

	UPDATE flow_state_cms_col
	   SET is_editable = 0
	 WHERE flow_state_id = in_state_id
	   AND column_sid IN (SELECT column_value FROM TABLE(t_non_editable_col_sids))
	   AND is_editable = 1;
END;


PROCEDURE DeleteState(
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_move_items_to	IN	flow_state.flow_state_id%TYPE DEFAULT NULL
)
AS
	v_flow_sid			security_pkg.T_SID_ID;
	v_flow_label		flow.label%TYPE;
	v_flow_state_label	flow_state.label%TYPE;
	v_cnt				NUMBER(10);
	v_ids				security_pkg.T_SID_IDS;
BEGIN
	SELECT f.flow_sid, fs.label, f.label
	  INTO v_flow_sid, v_flow_state_label, v_flow_label
	  FROM flow_state fs
		JOIN flow f ON fs.flow_sid = f.flow_sid
	 WHERE flow_state_id = in_flow_state_Id;

	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||v_flow_sid);
	END IF;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		v_flow_sid,
		'Deleted state "{0}" from workflow "{1}"',
		v_flow_state_label, v_flow_label);

	-- we don't actually delete states but delete associated data
	-- so we don't get in a mess
	SELECT in_flow_state_id
	  BULK COLLECT INTO v_ids
	  FROM DUAL;

	Internal_DeleteTransitions(
		in_flow_state_ids => v_ids
	);

	UPDATE flow_state
	   SET is_deleted = 1,
		   lookup_key = NULL
	 WHERE flow_state_id = in_flow_state_id;

	IF in_move_items_to IS NOT NULL THEN
		UPDATE flow_item
		   SET current_state_id = in_move_items_to, last_flow_state_transition_id = null
		 WHERE current_state_id = in_flow_state_id;
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		v_flow_sid,
		'Moved all items from state "{0}" to state "{1}"',
		in_flow_state_id, in_move_items_to);
	ELSE
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM flow_item
		 WHERE current_state_id = in_flow_state_Id;

		IF v_cnt > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot delete state id '||in_flow_state_Id||' because '||v_cnt||' items are linked to it.');
		END IF;
	END IF;

END;

PROCEDURE AmendState(
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_label				IN	flow_state.label%TYPE,
	in_final				IN 	NUMBER,
	in_lookup_key			IN	flow_state.lookup_key%TYPE,
	in_state_colour			IN	flow_state.state_colour%TYPE,
	in_pos					IN	flow_state.pos%TYPE DEFAULT NULL,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE DEFAULT NULL,
	in_survey_editable		IN	flow_state.survey_editable%TYPE DEFAULT 1
)
AS
	CURSOR c IS
		SELECT fs.flow_sid, fs.label, f.label flow_label, fs.lookup_key, fs.survey_editable
		  FROM flow_state fs
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE flow_state_id = in_flow_state_id;
	r	c%ROWTYPE;
	v_ind_name			VARCHAR2(1000);
	v_lookup_count 		NUMBER;
	v_duplicate_state	VARCHAR2(1024);
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Flow state id '||in_flow_state_id||' not found');
	END IF;

	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, r.flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||r.flow_sid);
	END IF;

	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		r.flow_sid, 'Workflow '||r.flow_label||' state label', r.label, in_label);
	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
	r.flow_sid, 'Workflow '||r.flow_label||' state final', CASE in_final WHEN 1 THEN 'false' WHEN 0 THEN 'true' ELSE 'err' END,
	CASE in_final WHEN 1 THEN 'true' WHEN 0 THEN 'false' ELSE 'err' END);

	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		r.flow_sid, 'Workflow '||r.flow_label||' state lookup key', r.lookup_key, in_lookup_key);
	
	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		r.flow_sid, 'Workflow '||r.flow_label||' state survey editable', r.survey_editable, in_survey_editable);
		
	SELECT COUNT(*) 
	  INTO v_lookup_count 
	  FROM flow_state 
	 WHERE lookup_key = in_lookup_key
	   AND label != in_label
	   AND flow_state_id != in_flow_state_id
	   AND flow_sid = r.flow_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_lookup_count > 0 THEN
		SELECT label
		  INTO v_duplicate_state
		  FROM flow_state
		 WHERE lookup_key = in_lookup_key
		   AND flow_sid = r.flow_sid
	       AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_LOOKUP_KEY_CONSTRAINT_VIOLATED, 'States:' || v_duplicate_state || ', ' || in_label);
	END IF;

	UPDATE flow_state
	   SET label = in_label,
		   lookup_key = in_lookup_key,
		   is_final = NVL(in_final,0),
		   state_colour = in_state_colour,
		   pos = NVL(in_pos, pos),
		   flow_state_nature_id = in_flow_state_nature_id,
		   survey_editable = in_survey_editable
	 WHERE flow_state_id = in_flow_state_id;

	-- Update corresponding indicator's name. This might not necessarily be the name of the state, so we
	-- need some way to get the indicator's name. This is only supported for audit flow indicators.
	FOR r IN (
		SELECT ind_sid, flow_state_audit_ind_type_id
		  FROM csr.flow_state_audit_ind
		 WHERE flow_state_id = in_flow_state_id
	)
	LOOP
		v_ind_name := audit_pkg.GetAuditFlowStateIndName(in_flow_state_id, r.flow_state_audit_ind_type_id);
		indicator_pkg.RenameIndicator(r.ind_sid, v_ind_name);
	END LOOP;
END;

PROCEDURE SetTransition(
	in_flow_state_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_from_state_id				IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id					IN	flow_state_transition.to_state_id%TYPE,
	in_verb							IN	flow_state_transition.verb%TYPE,
	in_lookup_key					IN	flow_state_transition.lookup_key%TYPE,
	in_helper_sp					IN 	flow_state_transition.helper_sp%TYPE,
	in_ask_for_comment				IN	flow_state_transition.ask_for_comment%TYPE DEFAULT 'optional',
	in_mandatory_fields_message		IN	flow_state_transition.mandatory_fields_message%TYPE,
	in_auto_trans_type				IN	flow_state_transition.auto_trans_type%TYPE,
	in_hours_before_auto_tran		IN	flow_state_transition.hours_before_auto_tran%TYPE,
	in_auto_schedule_xml			IN	VARCHAR2,
	in_button_icon_path				IN	flow_state_transition.button_icon_path%TYPE,
	in_pos							IN	flow_state_transition.pos%TYPE,
	in_role_sids					IN	security_pkg.T_SID_IDS,
	in_column_sids					IN	security_pkg.T_SID_IDS,
	in_involved_type_ids			IN	security_pkg.T_SID_IDS,
	in_group_sids					IN	security_pkg.T_SID_IDS,
	in_attributes_xml				IN	flow_state_transition.attributes_xml%TYPE,
	in_enforce_validation			IN	flow_state_transition.enforce_validation%TYPE DEFAULT 0
)
AS
	-- there's also a constraint which will force both states to be from the same workflow
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fsf.label from_label, fst.label to_label
		  FROM flow f
		  JOIN flow_state fsf ON f.flow_sid = fsf.flow_sid
		  JOIN flow_state fst ON f.flow_sid = fst.flow_sid
		 WHERE fsf.flow_state_id = in_from_state_Id
		   AND fst.flow_state_id = in_to_state_id;
	ar	c%ROWTYPE;
	t_role_sids						security.T_SID_TABLE := security_pkg.SidArrayToTable(in_role_sids);
	t_column_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_column_sids);
	t_involved_type_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_involved_type_ids);
	t_group_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_group_sids);
    v_old_verb						flow_state_transition.verb%TYPE;
    v_old_lookup_key				flow_state_transition.lookup_key%TYPE;
    v_old_mandatory_fields_message	flow_state_transition.mandatory_fields_message%TYPE;
	v_old_hours_before_auto_tran	flow_state_transition.hours_before_auto_tran%TYPE;
    v_old_button_icon_path			flow_state_transition.button_icon_path%TYPE;
    v_old_ask_for_comment			flow_state_transition.ask_for_comment%TYPE;
    v_old_pos						flow_state_transition.pos%TYPE;
	v_flow_state_transition_id		flow_state_transition.flow_state_transition_id%TYPE;
	v_old_auto_trans_type			flow_state_transition.auto_trans_type%TYPE;
	v_old_auto_schedule_xml			flow_state_transition.auto_schedule_xml%TYPE;
    v_old_enforce_validation		flow_state_transition.enforce_validation%TYPE;
	v_lookup_count 					NUMBER;
	v_duplicate_trans				VARCHAR2(1024);
BEGIN
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow states from different workflows, or workflow states not found');
	END IF;
	
	SELECT COUNT(*) 
	  INTO v_lookup_count 
	  FROM flow_state_transition 
	 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
	   AND from_state_id = in_from_state_id
	   AND to_state_id != in_to_state_id
	   AND flow_sid = ar.flow_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_lookup_count > 0 THEN
		SELECT verb
		  INTO v_duplicate_trans
		  FROM flow_state_transition
		 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
		   AND from_state_id = in_from_state_id
		   AND to_state_id != in_to_state_id
		   AND flow_sid = ar.flow_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_LOOKUP_KEY_CONSTRAINT_VIOLATED, 'Transitions:' || v_duplicate_trans || ', ' || in_verb);
	END IF;
	
	BEGIN
		INSERT INTO flow_state_transition
			(flow_state_transition_id, flow_sid, from_state_id, to_state_id, verb, lookup_key, last_run_dtm, ask_for_comment,
			 mandatory_fields_message, auto_trans_type, hours_before_auto_tran, auto_schedule_xml, button_icon_path, pos, enforce_validation)
		VALUES
			(in_flow_state_transition_id, ar.flow_sid, in_from_state_id, in_to_state_id, in_verb, in_lookup_key, TRUNC(SYSDATE, 'DD'),
			in_ask_for_comment, in_mandatory_fields_message, in_auto_trans_type, in_hours_before_auto_tran, in_auto_schedule_xml, in_button_icon_path, in_pos, in_enforce_validation);

		-- audit
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid,
			'Create transition for workflow "{0}" from "{1}" to "{2}"',
			ar.flow_label, ar.from_Label, ar.to_label);

		v_flow_state_transition_id := in_flow_state_transition_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT verb, lookup_key, mandatory_fields_message, hours_before_auto_tran, ask_for_comment, button_icon_path, auto_trans_type, auto_schedule_xml, enforce_validation
			  INTO v_old_verb, v_old_lookup_key, v_old_mandatory_fields_message, v_old_hours_before_auto_tran, v_old_ask_for_comment, v_old_button_icon_path, v_old_auto_trans_type, v_old_auto_schedule_xml, v_old_enforce_validation
			  FROM flow_state_transition
			 WHERE from_state_id = in_from_state_id
			   AND to_state_id = in_to_state_id;

			-- update
			UPDATE flow_state_transition
			   SET verb = in_verb,
				   lookup_key = in_lookup_key,
				   mandatory_fields_message = in_mandatory_fields_message,
				   auto_trans_type = in_auto_trans_type,
				   hours_before_auto_tran = in_hours_before_auto_tran,
				   auto_schedule_xml = in_auto_schedule_xml,
				   button_icon_path = in_button_icon_path,
				   ask_for_comment = in_ask_for_comment,
				   pos = in_pos,
				   last_run_dtm = DECODE(in_auto_trans_type, AUTO_TRANS_SCHEDULE, NVL(last_run_dtm, SYSDATE), NULL),
				   enforce_validation = in_enforce_validation
			 WHERE from_state_id = in_from_state_id
			   AND to_state_id = in_to_state_id
			RETURNING flow_state_transition_id INTO v_flow_state_transition_id;

			-- audit transition properties
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Verb', v_old_verb, in_verb, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Tag', v_old_lookup_key, in_lookup_key, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Mandatory fields message', v_old_mandatory_fields_message, in_mandatory_fields_message, in_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Hours before Auto Transition', v_old_hours_before_auto_tran, in_hours_before_auto_tran, in_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Icon path', v_old_button_icon_path, in_button_icon_path, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Comments', v_old_ask_for_comment, in_ask_for_comment, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Position', v_old_pos, in_pos, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Auto transition type', v_old_auto_trans_type, in_auto_trans_type, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Auto transition schedule', CASE WHEN v_old_auto_schedule_xml IS NULL THEN NULL ELSE v_old_auto_schedule_xml.getStringVal() END, 
				in_auto_schedule_xml, v_flow_state_transition_id);
			csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
				ar.flow_sid, 'Enforce validation', v_old_enforce_validation, in_enforce_validation, v_flow_state_transition_id);
	END;

	-- deleted roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT role_sid
			  FROM flow_state_transition_role
			 WHERE flow_state_transition_id = v_flow_state_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_role_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted role "{1}" for transition "{2}"',
			ar.flow_label, r.name, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_role
		 WHERE flow_state_transition_id = v_flow_state_transition_id
		   AND role_sid = r.role_sid;
	END LOOP;

	-- added roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT column_value FROM TABLE(t_role_sids)
			  MINUS
			SELECT role_sid
			  FROM flow_state_transition_role
			 WHERE flow_state_transition_id = v_flow_state_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added role "{1}" for transition "{2}"',
			ar.flow_label, r.name, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_role (flow_state_transition_id, from_State_id, role_sid)
			VALUES (v_flow_state_transition_id, in_from_state_id, r.role_sid);
	END LOOP;

	-- deleted groups
	FOR r IN (
		SELECT gt.sid_id, so.name
		  FROM security.group_table gt
		  JOIN security.securable_object so on gt.sid_id = so.sid_id
		  JOIN security.securable_object_class soc on so.class_id = soc.class_id
		 WHERE (soc.class_name = 'Group' or soc.class_name = 'CSRUserGroup')
		   AND gt.sid_id IN (
			SELECT group_sid
			  FROM flow_state_transition_role
			 WHERE flow_state_transition_id = v_flow_state_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_group_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted group "{1}" for transition "{2}"',
			ar.flow_label, r.name, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_role
		 WHERE flow_state_transition_id = v_flow_state_transition_id
		   AND group_sid = r.sid_id;
	END LOOP;

	-- added groups
	FOR r IN (
		SELECT gt.sid_id, so.name
		  FROM security.group_table gt
		  JOIN security.securable_object so on gt.sid_id = so.sid_id
		  JOIN security.securable_object_class soc on so.class_id = soc.class_id
		 WHERE (soc.class_name = 'Group' or soc.class_name = 'CSRUserGroup')
		   AND gt.sid_id IN (
			SELECT column_value FROM TABLE(t_group_sids)
			 MINUS
			SELECT group_sid
			  FROM flow_state_transition_role
			 WHERE flow_state_transition_id = v_flow_state_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added group "{1}" for transition "{2}"',
			ar.flow_label, r.name, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_role (flow_state_transition_id, from_State_Id, group_sid)
			VALUES (v_flow_state_transition_id, in_from_state_Id, r.sid_id);
	END LOOP;

	-- deleted columns
	FOR r IN (
		SELECT column_sid, oracle_column
		  FROM cms.tab_column
		 WHERE column_sid IN (
			SELECT column_sid
			  FROM flow_state_transition_cms_col
			 WHERE flow_state_transition_id = v_flow_state_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_column_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted column "{1}" for transition "{2}"',
			ar.flow_label, r.oracle_column, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_cms_col
		 WHERE flow_state_transition_id = v_flow_state_transition_id
		   AND column_sid = r.column_sid;
	END LOOP;

	-- added column
	FOR r IN (
		SELECT column_sid, oracle_column
		  FROM cms.tab_column
		 WHERE column_sid IN (
			SELECT column_value FROM TABLE(t_column_sids)
			  MINUS
			SELECT column_sid
			  FROM flow_state_transition_cms_col
			 WHERE flow_state_transition_id = v_flow_state_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for transition "{2}"',
			ar.flow_label, r.oracle_column, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_cms_col (flow_state_transition_id, from_State_Id, column_sid)
			VALUES (v_flow_state_transition_id, in_from_state_Id, r.column_sid);
	END LOOP;

	-- deleted involvement types
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			SELECT flow_involvement_type_id
			  FROM flow_state_transition_inv
			 WHERE flow_state_transition_id = v_flow_state_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_involved_type_ids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted invovlement type "{1}" for transition "{2}"',
			ar.flow_label, r.label, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_inv
		 WHERE flow_state_transition_id = v_flow_state_transition_id
		   AND flow_involvement_type_id = r.flow_involvement_type_id;
	END LOOP;

	-- added involvement types
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			SELECT column_value FROM TABLE(t_involved_type_ids)
			  MINUS
			SELECT flow_involvement_type_id
			  FROM flow_state_transition_inv
			 WHERE flow_state_transition_id = v_flow_state_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added involement type "{1}" for transition "{2}"',
			ar.flow_label, r.label, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_inv (flow_state_transition_id, from_State_Id, flow_involvement_type_id)
			VALUES (v_flow_state_transition_id, in_from_state_Id, r.flow_involvement_type_id);
	END LOOP;

		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
	UPDATE flow_state_transition
	   SET attributes_xml = in_attributes_xml,
		   helper_sp = in_helper_sp
	 WHERE flow_state_transition_id = v_flow_state_transition_id;
END;

PROCEDURE RemoveTransition(
	in_from_state_id	IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id		IN	flow_state_transition.to_state_id%TYPE
)
AS
	-- there's also a constraint which will force both states to be from the same workflow
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fsf.label from_label, fst.label to_label
		  FROM flow f
			JOIN flow_state fsf ON f.flow_sid = fsf.flow_sid
			JOIN flow_state fst ON f.flow_sid = fst.flow_sid
		 WHERE fsf.flow_state_id = in_from_state_Id
		   AND fst.flow_state_id = in_to_state_id;
	ar	c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow states from different workflows, or workflow states not found');
	END IF;

	Internal_DeleteTransitions(
		in_from_flow_state_id => in_from_state_id,
		in_to_flow_state_id => in_to_state_id
	 );


	IF SQL%ROWCOUNT > 0 THEN
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid,
			'Altered workflow "{0}", deleted transition from "{1}" to "{2}"',
			ar.flow_label, ar.from_label, ar.to_label);
	END IF;
END;

FUNCTION GetStateId(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_lookup_key	IN	flow_state.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_flow_state_id		flow_state.flow_state_id%TYPE;
BEGIN
	SELECT MIN(flow_state_id)
	  INTO v_flow_state_Id
	  FROM flow_state
	 WHERE flow_sid = in_flow_sid
	   AND UPPER(lookup_Key) = UPPER(in_lookup_key);
	RETURN v_flow_state_id;
END;

FUNCTION GetNextStateID
RETURN flow_state.flow_state_id%TYPE
AS
	v_id 	flow_state.flow_state_id%TYPE;
BEGIN
	SELECT flow_state_id_seq.nextval
	  INTO v_id
	  FROM DUAL;
	RETURN v_id;
END;

FUNCTION GetNextStateGroupID
RETURN flow_state_group.flow_state_group_id%TYPE
AS
	v_id 	flow_state_group.flow_state_group_id%TYPE;
BEGIN
	SELECT flow_state_group_id_seq.nextval
	  INTO v_id
	  FROM DUAL;
	RETURN v_id;
END;

-- private
FUNCTION SidListToArray(
	in_sid_list	VARCHAR2
) RETURN security_pkg.T_SID_IDS
AS
	v_sids		security_pkg.T_SID_IDS;
BEGIN
	-- bit icky -- i.e. random spacing etc would probably blow this up
	IF in_sid_list IS NOT NULL THEN
		 SELECT TO_NUMBER(REGEXP_SUBSTR(in_sid_list, '[^,]+',1,ROWNUM))
		   BULK COLLECT INTO v_sids
		   FROM DUAL
		 CONNECT BY ROWNUM <= (LENGTH(in_sid_list) - LENGTH(REPLACE(in_sid_list,',')) + 1);
	ELSE
		SELECT null
		  BULK COLLECT INTO v_sids
		  FROM DUAL;
	END IF;

	RETURN v_sids;
END;

PROCEDURE SetTempFlowState(
	in_flow_sid					IN	t_flow_state.flow_sid%TYPE,
	in_pos						IN	t_flow_state.pos%TYPE,
	in_flow_state_id			IN	t_flow_state.flow_state_id%TYPE,
	in_label					IN	t_flow_state.label%TYPE,
	in_lookup_key				IN	t_flow_state.lookup_key%TYPE,
	in_is_final					IN	t_flow_state.is_final%TYPE,
	in_state_colour				IN	t_flow_state.state_colour%TYPE,
	in_editable_role_sids		IN	t_flow_state.editable_role_sids%TYPE,
	in_non_editable_role_sids	IN	t_flow_state.non_editable_role_sids%TYPE,
	in_editable_col_sids		IN	t_flow_state.editable_col_sids%TYPE,
	in_non_editable_col_sids	IN	t_flow_state.non_editable_col_sids%TYPE,
	in_involved_type_ids		IN	t_flow_state.involved_type_ids%TYPE,
	in_editable_group_sids		IN	t_flow_state.editable_group_sids%TYPE,
	in_non_editable_group_sids	IN	t_flow_state.non_editable_group_sids%TYPE,
	in_move_from_flow_state_id 	IN  t_flow_state.move_from_flow_state_id%TYPE DEFAULT NULL,
	in_flow_state_group_ids		IN	t_flow_state.flow_state_group_ids%TYPE DEFAULT NULL,
	in_attributes_xml			IN	VARCHAR2,
	in_flow_state_nature_id		IN	t_flow_state.flow_state_nature_id%TYPE DEFAULT NULL,
	in_survey_editable			IN	t_flow_state.survey_editable%TYPE DEFAULT 1,
	in_survey_tag_ids			IN	t_flow_state.survey_tag_ids%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO t_flow_state
		(flow_sid, pos, flow_state_id, label, lookup_key, is_final, state_colour, editable_role_sids, non_editable_role_sids, move_from_flow_state_id, editable_col_sids, non_editable_col_sids, involved_type_ids, editable_group_sids, non_editable_group_sids, attributes_xml, flow_state_nature_id, flow_state_group_ids, survey_editable, survey_tag_ids)
	VALUES
		(in_flow_sid, in_pos, in_flow_state_id, in_label, in_lookup_key, in_is_final, in_state_colour, in_editable_role_sids, in_non_editable_role_sids, in_move_from_flow_state_id, in_editable_col_sids, in_non_editable_col_sids, in_involved_type_ids, in_editable_group_sids, in_non_editable_group_sids, in_attributes_xml, in_flow_state_nature_id, in_flow_state_group_ids, in_survey_editable, in_survey_tag_ids);
END;

PROCEDURE SetTempFlowStateAlert(
	in_flow_sid					IN	t_flow_state_alert.flow_sid%TYPE,
	in_flow_state_id			IN	t_flow_state_alert.flow_state_id%TYPE,
	in_customer_alert_type_id	IN	t_flow_state_alert.customer_alert_type_id%TYPE,
	in_flow_state_alert_id		IN	t_flow_state_alert.flow_state_alert_id%TYPE,
	in_flow_alert_description	IN	t_flow_state_alert.flow_alert_description%TYPE,
	in_helper_sp				IN	t_flow_state_alert.helper_sp%TYPE,
	in_role_sids				IN	t_flow_state_alert.role_sids%TYPE,
	in_group_sids				IN	t_flow_state_alert.group_sids%TYPE,
	in_user_sids				IN	t_flow_state_alert.user_sids%TYPE,
	in_recurrence_xml			IN	t_flow_state_alert.recurrence_xml%TYPE
)
AS
	v_flow_state_alert_id	NUMBER(10);
BEGIN
	IF in_flow_state_alert_id IS NULL THEN
		SELECT flow_state_alert_id_seq.NEXTVAL
		  INTO v_flow_state_alert_id
		  FROM DUAL;
	ELSE
		v_flow_state_alert_id := in_flow_state_alert_id;
	END IF;

	INSERT INTO t_flow_state_alert
		(flow_sid, flow_state_id, customer_alert_type_id, flow_state_alert_id, flow_alert_description, helper_sp, role_sids, group_sids, user_sids, recurrence_xml)
	VALUES
		(in_flow_sid, in_flow_state_id, in_customer_alert_type_id, v_flow_state_alert_id, in_flow_alert_description, in_helper_sp, in_role_sids, in_group_sids, in_user_sids, in_recurrence_xml);
END;

PROCEDURE SetTempFlowStateRoleCap(
	in_flow_sid						IN	t_flow_state_role_cap.flow_sid%TYPE,
	in_flow_state_id				IN	t_flow_state_role_cap.flow_state_id%TYPE,
	in_flow_capability_id			IN	t_flow_state_role_cap.flow_capability_id%TYPE,
	in_role_sid						IN	t_flow_state_role_cap.role_sid%TYPE,
	in_flow_involvement_type_id		IN	t_flow_state_role_cap.flow_involvement_type_id%TYPE,
	in_permission_set				IN	t_flow_state_role_cap.permission_set%TYPE,
	in_group_sid					IN	t_flow_state_role_cap.group_sid%TYPE
)
AS
BEGIN
	INSERT INTO t_flow_state_role_cap
		(flow_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set, group_sid)
	VALUES
		(in_flow_sid, flow_state_rl_cap_id_seq.nextval, in_flow_state_id, in_flow_capability_id, in_role_sid, in_flow_involvement_type_id, in_permission_set, in_group_sid);
END;

PROCEDURE SetTempFlowStateTrans(
	in_flow_sid						IN	t_flow_state_trans.flow_sid%TYPE,
	in_pos							IN	t_flow_state_trans.pos%TYPE,
	in_flow_state_transition_id		IN	t_flow_state_trans.flow_state_transition_id%TYPE,
	in_from_state_id				IN	t_flow_state_trans.from_state_id%TYPE,
	in_to_state_id					IN	t_flow_state_trans.to_state_id%TYPE,
	in_ask_for_comment				IN	t_flow_state_trans.ask_for_comment%TYPE,
	in_mandatory_fields_message		IN	t_flow_state_trans.mandatory_fields_message%TYPE,
	in_auto_trans_type				IN	t_flow_state_trans.auto_trans_type%TYPE DEFAULT 0,
	in_hours_before_auto_tran		IN	t_flow_state_trans.hours_before_auto_tran%TYPE,
	in_auto_schedule_xml			IN	VARCHAR2 DEFAULT NULL,
	in_button_icon_path				IN	t_flow_state_trans.button_icon_path%TYPE,
	in_verb							IN	t_flow_state_trans.verb%TYPE,
	in_lookup_key					IN	t_flow_state_trans.lookup_key%TYPE,
	in_helper_sp					IN	t_flow_state_trans.helper_sp%TYPE,
	in_role_sids					IN	t_flow_state_trans.role_sids%TYPE,
	in_column_sids					IN	t_flow_state_trans.column_sids%TYPE,
	in_involved_type_ids			IN	t_flow_state_trans.involved_type_ids%TYPE,
	in_group_sids					IN	t_flow_state_trans.group_sids%TYPE,
	in_attributes_xml				IN	VARCHAR2,
	in_enforce_validation			IN	t_flow_state_trans.enforce_validation%TYPE DEFAULT 0,
	out_flow_state_transition_id	OUT	t_flow_state_trans.flow_state_transition_id%TYPE
)
AS
BEGIN
	IF in_flow_state_transition_id IS NULL THEN
		BEGIN
			SELECT flow_state_transition_id
			  INTO out_flow_state_transition_id
			  FROM flow_state_transition
			 WHERE from_state_id = in_from_state_id
			   AND to_state_id = in_to_state_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				SELECT flow_state_transition_id_seq.nextval
				  INTO out_flow_state_transition_id
				  FROM DUAL;
		END;
	ELSE
		out_flow_state_transition_id := in_flow_state_transition_id;
	END IF;

	INSERT INTO t_flow_state_trans
		(flow_sid, pos, flow_state_transition_id, from_state_id, to_state_id, ask_for_comment, mandatory_fields_message, auto_trans_type, hours_before_auto_tran, auto_schedule_xml, button_icon_path, verb, lookup_key, helper_sp, role_sids, column_sids, involved_type_ids, group_sids, attributes_xml, enforce_validation)
	VALUES
		(in_flow_sid, in_pos, out_flow_state_transition_id, in_from_state_id, in_to_state_id, NVL(in_ask_for_comment,'none'), in_mandatory_fields_message, in_auto_trans_type, in_hours_before_auto_tran, in_auto_schedule_xml, in_button_icon_path, in_verb, in_lookup_key, in_helper_sp, in_role_sids, in_column_sids, in_involved_type_ids, in_group_sids, in_attributes_xml, in_enforce_validation);
END;

PROCEDURE SetTempFlowTransAlert(
	in_flow_sid						IN	t_flow_trans_alert.flow_sid%TYPE,
	in_flow_transition_alert_id		IN	t_flow_trans_alert.flow_transition_alert_id%TYPE,
	in_flow_state_transition_id		IN	t_flow_trans_alert.flow_state_transition_id%TYPE,
	in_customer_alert_type_id		IN	t_flow_trans_alert.customer_alert_type_id%TYPE,
	in_description					IN	t_flow_trans_alert.description%TYPE,
	in_to_initiator					IN	t_flow_trans_alert.to_initiator%TYPE,
	in_can_edit_before_send			IN	t_flow_trans_alert.can_be_edited_before_sending%TYPE,
	in_helper_sp					IN	t_flow_trans_alert.helper_sp%TYPE,
	in_flow_cms_cols				IN	t_flow_trans_alert.flow_cms_cols%TYPE,
	in_user_sids					IN	t_flow_trans_alert.user_sids%TYPE,
	in_role_sids					IN	t_flow_trans_alert.role_sids%TYPE,
	in_group_sids					IN	t_flow_trans_alert.group_sids%TYPE,
	in_cc_user_sids					IN	t_flow_trans_alert.cc_user_sids%TYPE,
	in_cc_role_sids					IN	t_flow_trans_alert.cc_role_sids%TYPE,
	in_cc_group_sids				IN	t_flow_trans_alert.cc_group_sids%TYPE,
	in_alert_manager_flags			IN	t_flow_trans_alert.alert_manager_flags%TYPE,
	in_involved_type_ids			IN	t_flow_trans_alert.involved_type_ids%TYPE
)
AS
	v_flow_transition_alert_id	t_flow_state_trans.flow_state_transition_id%TYPE;
BEGIN
	IF in_flow_transition_alert_id IS NULL THEN
		SELECT flow_transition_alert_id_seq.nextval
		  INTO v_flow_transition_alert_id
		  FROM DUAL;
	ELSE
		v_flow_transition_alert_id := in_flow_transition_alert_id;
	END IF;

	INSERT INTO t_flow_trans_alert
		(flow_sid, flow_transition_alert_id, flow_state_transition_id, customer_alert_type_id, description, to_initiator, can_be_edited_before_sending, helper_sp, flow_cms_cols, user_sids, role_sids, group_sids, alert_manager_flags, involved_type_ids, cc_user_sids, cc_role_sids, cc_group_sids)
	VALUES
		(in_flow_sid, v_flow_transition_alert_id, in_flow_state_transition_id, in_customer_alert_type_id, in_description, in_to_initiator, in_can_edit_before_send, in_helper_sp, in_flow_cms_cols, in_user_sids, in_role_sids, in_group_sids, in_alert_manager_flags, in_involved_type_ids, in_cc_user_sids, in_cc_role_sids, in_group_sids);
END;

PROCEDURE SetFlowFromTempTables(
	in_flow_sid				IN	flow.flow_sid%TYPE,
	in_flow_label			IN	flow.label%TYPE,
	in_flow_alert_class		IN	flow.flow_alert_class%TYPE,
	in_cms_tab_sid			IN	cms.tab.tab_sid%TYPE,
	in_default_state_id		IN	flow_state.flow_state_id%TYPE
)
AS
	v_flow_alert_class			flow.flow_alert_class%TYPE;
	v_default_state_id			flow_state.flow_state_id%TYPE;
	v_role_sids					security_pkg.T_SID_IDS;
	v_group_sids				security_pkg.T_SID_IDS;
	v_column_sids				security_pkg.T_SID_IDS;
	v_editable_role_sids		security_pkg.T_SID_IDS;
	v_non_editable_role_sids	security_pkg.T_SID_IDS;
	v_editable_col_sids			security_pkg.T_SID_IDS;
	v_non_editable_col_sids		security_pkg.T_SID_IDS;
	v_involved_type_ids			security_pkg.T_SID_IDS;
	v_editable_group_sids		security_pkg.T_SID_IDS;
	v_non_editable_group_sids	security_pkg.T_SID_IDS;
	v_flow_state_group_ids		security_pkg.T_SID_IDS;
	v_survey_tag_ids			security_pkg.T_SID_IDS;
	v_user_sids					security_pkg.T_SID_IDS;
	v_flow_cms_cols				security_pkg.T_SID_IDS;
	v_alert_manager_flags		security_pkg.T_SID_IDS;
	v_first_state_id			csr_data_pkg.T_FLOW_STATE_ID;
	v_is_deleted				flow_state.is_deleted%TYPE;
	v_helper_sp					flow_transition_alert.helper_sp%TYPE;
	v_on_save_helper_sp			flow_alert_class.on_save_helper_sp%TYPE;
BEGIN
	-- update the flow alert class if given one
	IF in_flow_alert_class IS NOT NULL THEN
		UPDATE flow
		   SET flow_alert_class = in_flow_alert_class
		 WHERE flow_sid = in_flow_sid;

		 v_flow_alert_class := in_flow_alert_class;
	ELSE
		SELECT flow_alert_class
		  INTO v_flow_alert_class
		  FROM flow
		 WHERE flow_sid = in_flow_sid;
	END IF;

    RenameFlow(in_flow_sid, in_flow_label);

    IF in_cms_tab_sid IS NOT NULL THEN
	    UPDATE cms.tab
	       SET flow_sid = in_flow_sid
	     WHERE tab_sid = in_cms_tab_sid;
	ELSE
		UPDATE cms.tab
		   SET flow_sid = NULL
		 WHERE flow_sid = in_flow_sid;
	END IF;

	-- Remove all lookup keys from updated transitions incase lookup keys have been swapped.
	-- Without this it will block changing 2 lookup keys LookupKey1 -> LookupKey2 and LookupKey2 -> LookupKey1
	UPDATE flow_state
	   SET lookup_key = null
	 WHERE flow_state_id IN (SELECT flow_state_id FROM t_flow_state);
	 
	-- update states
    v_first_state_id := null;
    FOR r IN (
		SELECT pos, flow_state_id, label, lookup_key, is_final, state_colour, editable_role_sids,
			   non_editable_role_sids, editable_col_sids, non_editable_col_sids,
			   involved_type_ids, editable_group_sids, non_editable_group_sids, attributes_xml,
			   flow_state_nature_id, flow_state_group_ids, survey_editable, survey_tag_ids, move_from_flow_state_id
		  FROM t_flow_state
		 WHERE flow_sid = in_flow_sid
		   AND flow_state_id IN (
			SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid
		 )
    ) LOOP
		v_first_state_id := NVL(v_first_state_id, r.flow_state_id);
		AmendState(r.flow_state_id, r.label, r.is_final, r.lookup_key, r.state_colour, r.pos, r.flow_state_nature_id, r.survey_editable);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state
		   SET attributes_xml = r.attributes_xml
		 WHERE flow_state_id = r.flow_state_id;

		-- Move items before deleting
		IF r.move_from_flow_state_id IS NOT NULL THEN
			UPDATE flow_item
			   SET current_state_id = r.flow_state_id, last_flow_state_transition_id = null
			 WHERE current_state_id = r.move_from_flow_state_id;

			csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			in_flow_sid,
			'Moved all items from state "{0}" to state "{1}"',
			r.move_from_flow_state_id, r.flow_state_id);
		END IF;
		
		v_editable_role_sids      := SidListToArray(r.editable_role_sids);
		v_non_editable_role_sids  := SidListToArray(r.non_editable_role_sids);
		v_editable_col_sids       := SidListToArray(r.editable_col_sids);
		v_non_editable_col_sids   := SidListToArray(r.non_editable_col_sids);
		v_involved_type_ids       := SidListToArray(r.involved_type_ids);
		v_editable_group_sids     := SidListToArray(r.editable_group_sids);
		v_non_editable_group_sids := SidListToArray(r.non_editable_group_sids);
		v_flow_state_group_ids    := SidListToArray(r.flow_state_group_ids);
		v_survey_tag_ids          := SidListToArray(r.survey_tag_ids);

		SetStateRoles(r.flow_state_id, v_editable_role_sids, v_non_editable_role_sids, v_editable_col_sids, v_non_editable_col_sids, v_involved_type_ids, v_editable_group_sids, v_non_editable_group_sids);

		SetStateGroupMembers(r.flow_state_id, v_flow_state_group_ids);

		SetStateSurveyTags(r.flow_state_id, v_survey_tag_ids);
    END LOOP;

    /****************** process states *********************/
	-- delete states
    FOR r IN (
		SELECT flow_state_id, move_from_flow_state_id
		  FROM flow_state
		 WHERE flow_sid = in_flow_sid AND is_deleted = 0
		 MINUS
		SELECT flow_state_id, null FROM t_flow_state WHERE flow_sid = in_flow_sid
    ) LOOP
		flow_pkg.DeleteState(r.flow_state_id, r.move_from_flow_state_id); -- assume something has cleaned items up
    END LOOP;

    -- create states
    FOR r IN (
		SELECT pos, flow_state_id, label, lookup_key, editable_role_sids, non_editable_role_sids, attributes_xml,
			   editable_col_sids, non_editable_col_sids, involved_type_ids, editable_group_sids, non_editable_group_sids, is_final, state_colour,
			   flow_state_nature_id, flow_state_group_ids, survey_editable, survey_tag_ids
		  FROM t_flow_state
		 WHERE flow_sid = in_flow_sid
		   AND flow_state_id NOT IN (
			SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid
		 )
    )
    LOOP
		v_first_state_id := NVL(v_first_state_id, r.flow_state_id);
		CreateState(r.flow_state_id, in_flow_sid, r.label, r.lookup_key, r.flow_state_nature_id, r.survey_editable);

		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state
		   SET attributes_xml = r.attributes_xml,
			   is_final = NVL(r.is_final,0),
			   state_colour = r.state_colour,
			   pos = NVL(r.pos,1)
		 WHERE flow_state_id = r.flow_state_id;

		v_editable_role_sids     := SidListToArray(r.editable_role_sids);
		v_non_editable_role_sids := SidListToArray(r.non_editable_role_sids);
		v_editable_col_sids      := SidListToArray(r.editable_col_sids);
		v_non_editable_col_sids  := SidListToArray(r.non_editable_col_sids);
		v_involved_type_ids      := SidListToArray(r.involved_type_ids);
		v_editable_group_sids     := SidListToArray(r.editable_group_sids);
		v_non_editable_group_sids := SidListToArray(r.non_editable_group_sids);
		v_flow_state_group_ids    := SidListToArray(r.flow_state_group_ids);
		v_survey_tag_ids          := SidListToArray(r.survey_tag_ids);

		SetStateRoles(r.flow_state_id, v_editable_role_sids, v_non_editable_role_sids, v_editable_col_sids, v_non_editable_col_sids, v_involved_type_ids, v_editable_group_sids, v_non_editable_group_sids);

		SetStateGroupMembers(r.flow_state_id, v_flow_state_group_ids);
		
		SetStateSurveyTags(r.flow_state_id, v_survey_tag_ids);
    END LOOP;

    -- set default state
    IF in_default_state_id IS NOT NULL THEN
		UPDATE flow
		   SET default_state_id = in_default_state_id
		 WHERE flow_sid = in_flow_sid;
	END IF;

	-- Process state alerts
	FOR r IN (
		SELECT flow_sid, flow_state_id, customer_alert_type_id, flow_state_alert_id,
			   flow_alert_description, helper_sp, role_sids, group_sids, user_sids, recurrence_xml
		  FROM t_flow_state_alert
		 WHERE flow_sid = in_flow_sid
	) LOOP
		BEGIN
			INSERT INTO flow_state_alert
				(flow_state_alert_id, flow_sid, flow_state_id, description, customer_alert_type_id, flow_alert_helper, recurrence_pattern)
			VALUES
				(r.flow_state_alert_id, in_flow_sid, r.flow_state_id, r.flow_alert_description, r.customer_alert_type_id, r.helper_sp, r.recurrence_xml);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE flow_state_alert
				   SET customer_alert_type_id = r.customer_alert_type_id,
					   description = r.flow_alert_description,
					   flow_alert_helper = r.helper_sp,
					   recurrence_pattern = r.recurrence_xml
				 WHERE flow_sid = in_flow_sid
				   AND flow_state_alert_id = r.flow_state_alert_id;
		END;

		DELETE FROM flow_state_alert_role
		 WHERE flow_state_alert_id = r.flow_state_alert_id;

		INSERT INTO flow_state_alert_role (flow_sid, flow_state_alert_id, role_sid)
		SELECT in_flow_sid, r.flow_state_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.role_sids,','));

		INSERT INTO flow_state_alert_role (flow_sid, flow_state_alert_id, group_sid)
		SELECT in_flow_sid, r.flow_state_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.group_sids,','));

		  DELETE FROM flow_state_alert_user
		 WHERE flow_state_alert_id = r.flow_state_alert_id;

		INSERT INTO flow_state_alert_user (flow_sid, flow_state_alert_id, user_sid)
		SELECT in_flow_sid, r.flow_state_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.user_sids,','));
	END LOOP;

	UPDATE flow_state_alert
	   SET deleted = 1
	 WHERE flow_sid = in_flow_sid
	   AND flow_state_alert_id NOT IN (
			SELECT flow_state_alert_id
			  FROM t_flow_state_alert
			 WHERE flow_sid = in_flow_sid);

	/****************** process capabilities *********************/
	FOR r IN (
		SELECT flow_state_rl_cap_id, flow_state_id, flow_capability_id,
			   role_sid, permission_set, group_sid, flow_involvement_type_id
		  FROM t_flow_state_role_cap
		 WHERE flow_sid = in_flow_sid
	) LOOP
		BEGIN
			INSERT INTO flow_state_role_capability
				(flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, permission_set, group_sid, flow_involvement_type_id)
			VALUES
				(r.flow_state_rl_cap_id, r.flow_state_id, r.flow_capability_id, r.role_sid, r.permission_set, r.group_sid, r.flow_involvement_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE flow_state_role_capability
				   SET permission_set = r.permission_set
				 WHERE flow_state_id = r.flow_state_id
				   AND flow_capability_id = r.flow_capability_id
				   AND ((role_sid IS NULL AND r.role_sid IS NULL) OR role_sid = r.role_sid)
				   AND ((group_sid IS NULL AND r.group_sid IS NULL) OR group_sid = r.group_sid)
				   AND ((flow_involvement_type_id IS NULL AND r.flow_involvement_type_id IS NULL) OR flow_involvement_type_id = r.flow_involvement_type_id);
		END;
	END LOOP;

    /****************** process transitions *********************/
	-- delete
    FOR r IN (
		SELECT from_state_id, to_state_id FROM flow_state_transition WHERE flow_sid = in_flow_sid
		 MINUS
		SELECT from_state_id, to_state_id FROM t_flow_state_trans WHERE flow_sid = in_flow_sid
    ) LOOP
		flow_pkg.RemoveTransition(r.from_state_id, r.to_state_id);
    END LOOP;
	
	-- Remove all lookup keys from updated transitions incase lookup keys have been swapped.
	-- Without this it will block changing 2 lookup keys LookupKey1 -> LookupKey2 and LookupKey2 -> LookupKey1
	UPDATE flow_state_transition
	   SET lookup_key = null
	 WHERE flow_state_transition_id IN (SELECT flow_state_transition_id FROM t_flow_state_trans);
	
    -- create/update transitions
    FOR r IN (
		SELECT flow_state_transition_id, from_state_id, to_state_id, NVL(ask_for_comment,'optional') ask_for_comment, mandatory_fields_message,
			   hours_before_auto_tran, button_icon_path, verb, lookup_key, helper_sp, role_sids,
			   column_sids, involved_type_ids, group_sids, attributes_xml, pos, auto_trans_type, auto_schedule_xml, enforce_validation 
		  FROM t_flow_state_trans
		 WHERE flow_sid = in_flow_sid
    ) LOOP
		v_role_sids 		:= SidListToArray(r.role_sids);
		v_column_sids 		:= SidListToArray(r.column_sids);
		v_involved_type_ids := SidListToArray(r.involved_type_ids);
		v_group_sids 		:= SidListToArray(r.group_sids);

		SetTransition(r.flow_state_transition_id, r.from_state_id, r.to_state_id, r.verb, r.lookup_key, r.helper_sp,
			r.ask_for_comment, r.mandatory_fields_message, r.auto_trans_type, r.hours_before_auto_tran, 
			CASE WHEN r.auto_schedule_xml IS NULL THEN NULL ELSE r.auto_schedule_xml.getStringVal() END, r.button_icon_path, r.pos, 
			v_role_sids, v_column_sids, v_involved_type_ids, v_group_sids, r.attributes_xml, r.enforce_validation);
	END LOOP;

	FOR r IN (
		SELECT flow_transition_alert_id, flow_state_transition_id, customer_alert_type_id, description,
			   to_initiator, can_be_edited_before_sending, helper_sp, role_sids, flow_cms_cols, involved_type_ids,
			   group_sids, user_sids, alert_manager_flags, cc_role_sids, cc_group_sids, cc_user_sids
		  FROM t_flow_trans_alert
		 WHERE flow_sid = in_flow_sid
	) LOOP
		v_flow_cms_cols			:= SidListToArray(r.flow_cms_cols);
		v_alert_manager_flags	:= SidListToArray(r.alert_manager_flags);

		BEGIN
			INSERT INTO flow_transition_alert (flow_transition_alert_id, flow_state_transition_id, description,
				customer_alert_type_id, to_initiator, can_be_edited_before_sending, helper_sp, flow_alert_helper)
			VALUES
				(r.flow_transition_alert_id, r.flow_state_transition_id, r.description, r.customer_alert_type_id,
					r.to_initiator, r.can_be_edited_before_sending,
					DECODE(v_flow_alert_class, 'cms', r.helper_sp, NULL),
					DECODE(v_flow_alert_class, 'cms', NULL, r.helper_sp)
				);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE flow_transition_alert
				   SET customer_alert_type_id = r.customer_alert_type_id,
					   description = r.description,
					   helper_sp = DECODE(v_flow_alert_class, 'cms', r.helper_sp, NULL),
					   flow_alert_helper = DECODE(v_flow_alert_class, 'cms', NULL, r.helper_sp),
					   to_initiator = r.to_initiator,
					   can_be_edited_before_sending = r.can_be_edited_before_sending
				 WHERE flow_transition_alert_id = r.flow_transition_alert_id;
		END;

		DELETE FROM flow_transition_alert_role
		 WHERE flow_transition_alert_id = r.flow_transition_alert_id;

		INSERT INTO flow_transition_alert_role (flow_transition_alert_id, role_sid)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.role_sids,','));

		INSERT INTO flow_transition_alert_role (flow_transition_alert_id, group_sid)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.group_sids,','));

		DELETE FROM flow_transition_alert_user
		 WHERE flow_transition_alert_id = r.flow_transition_alert_id;

		INSERT INTO flow_transition_alert_user (flow_transition_alert_id, user_sid)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.user_sids,','));
		
		DELETE FROM flow_transition_alert_cc_role
		 WHERE flow_transition_alert_id = r.flow_transition_alert_id;

		INSERT INTO flow_transition_alert_cc_role (flow_transition_alert_id, role_sid)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.cc_role_sids,','));

		INSERT INTO flow_transition_alert_cc_role (flow_transition_alert_id, group_sid)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.cc_group_sids,','));

		DELETE FROM flow_transition_alert_cc_user
		 WHERE flow_transition_alert_id = r.flow_transition_alert_id;

		INSERT INTO flow_transition_alert_cc_user (flow_transition_alert_id, user_sid)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.cc_user_sids,','));

		DELETE FROM flow_transition_alert_cms_col
		 WHERE flow_transition_alert_id = r.flow_transition_alert_id;

		IF NOT (v_flow_cms_cols.COUNT = 1 AND v_flow_cms_cols(1) IS NULL) THEN
			FOR j IN 1 .. v_flow_cms_cols.COUNT LOOP
				INSERT INTO flow_transition_alert_cms_col
					(flow_transition_alert_id, column_sid, alert_manager_flag)
				VALUES
					(r.flow_transition_alert_id, v_flow_cms_cols(j), v_alert_manager_flags(j));
			END LOOP;
		END IF;

		DELETE FROM flow_transition_alert_inv
		 WHERE flow_transition_alert_id = r.flow_transition_alert_id;

		INSERT INTO flow_transition_alert_inv (flow_transition_alert_id, flow_involvement_type_id)
		SELECT r.flow_transition_alert_id, item
		  FROM TABLE(utils_pkg.SplitString(r.involved_type_ids,','));
	END LOOP;

	-- hide deleted alerts (we can't actually delete them without throwing away history if they
	-- happen to have fired)
	UPDATE flow_transition_alert
	   SET deleted = 1
	 WHERE flow_transition_alert_id NOT IN (
			SELECT flow_transition_alert_id
			  FROM t_flow_trans_alert
			 WHERE flow_sid = in_flow_sid)
	   AND flow_transition_alert_id IN (
			SELECT flow_transition_alert_id
			  FROM flow_transition_alert fta
			  JOIN flow_state_transition fst ON fst.flow_state_transition_id = fta.flow_state_transition_id
			 WHERE fst.flow_sid = in_flow_sid
	   );

    -- check that the default flow state hasn't been deleted
    SELECT f.default_state_id, fs.is_deleted
      INTO v_default_state_id, v_is_deleted
      FROM flow f
	  LEFT JOIN flow_state fs ON f.default_state_id = fs.flow_state_id AND f.app_sid = fs.app_sid
     WHERE f.flow_sid = in_flow_sid;

    -- a deleted default flow state is a seriously bad idea because then there will be
    -- no transitions etc, so switch it to the first state we were passed. The UI ought
    -- to cope with this better (i.e. flagging that there's no default / easily letting
    -- the user change the default). This will save the 2+ hours that MDW and I spent
    -- trying to figure out a weird problem pre some demo!
    IF v_is_deleted = 1 THEN
		--security_pkg.debugmsg('Default state showing as deleted so setting to; '||v_first_state_id);
		UPDATE flow
		   SET default_state_id = v_first_state_id
		 WHERE flow_sid = in_flow_sid;
		v_default_state_id := v_first_state_id;
    END IF;

    IF v_default_state_id IS NULL THEN
		RAISE csr_data_pkg.FLOW_HAS_NO_DEFAULT_STATE;
    END IF;

	-- Fire save helper?
	BEGIN
		SELECT on_save_helper_sp
		  INTO v_on_save_helper_sp
		  FROM flow_alert_class
		 WHERE flow_alert_class = v_flow_alert_class;

		IF v_on_save_helper_sp IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||v_on_save_helper_sp||'(:1);end;'
				USING in_flow_sid;
		END IF;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	IF in_cms_tab_sid IS NOT NULL THEN
		IF cms.filter_pkg.INTERNAL_GetPrimaryIdColSid(in_cms_tab_sid) IS NOT NULL THEN
			-- Clear any CMS cache for linked table
			chain.filter_pkg.ClearCacheForAllUsers (
				in_card_group_id => chain.filter_pkg.FILTER_TYPE_CMS,
				in_cms_col_sid   => cms.filter_pkg.INTERNAL_GetPrimaryIdColSid(in_cms_tab_sid)
			);
		END IF;
	ELSIF v_flow_alert_class = 'audit' THEN
		chain.filter_pkg.ClearCacheForAllUsers (
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
		);

		chain.filter_pkg.ClearCacheForAllUsers (
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
		);
	END IF;
END;

PROCEDURE SetStateRoles(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_editable_role_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_role_sids	IN	security_pkg.T_SID_IDS,
	in_editable_col_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_col_sids	IN	security_pkg.T_SID_IDS,
	in_involved_type_ids		IN	security_pkg.T_SID_IDS
)
AS
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fs.label state_label
		  FROM flow_state fs
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE fs.flow_state_id = in_state_id;
	ar	c%ROWTYPE;
    t_editable_role_sids 		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_editable_role_sids);
    t_non_editable_role_sids 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_non_editable_role_sids);
    t_editable_col_sids 		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_editable_col_sids);
    t_non_editable_col_sids 	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_non_editable_col_sids);
    t_involved_type_ids			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_involved_type_ids);
BEGIN
	-- we audit this, so the long way round (rather than just deleting)

	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow state '||in_state_id||' not found');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, ar.flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||ar.flow_sid);
	END IF;

	-- deleted roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT role_sid
			  FROM flow_state_role
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_editable_role_sids)
			 MINUS
			SELECT column_value FROM TABLE(t_non_editable_role_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted role "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		DELETE FROM flow_state_role_capability
		 WHERE flow_state_id = in_state_id
		   AND role_sid = r.role_sid;

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_role too
		DELETE FROM flow_state_role
		 WHERE flow_state_id = in_state_Id
		   AND role_sid = r.role_sid;
	END LOOP;

	-- added roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			(
				SELECT column_value FROM TABLE(t_editable_role_sids)
				 UNION
				SELECT column_value FROM TABLE(t_non_editable_role_sids)
			)
			  MINUS
			SELECT role_sid
			  FROM flow_state_role
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added role "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		INSERT INTO flow_state_role(flow_state_id, role_sid, is_editable)
			VALUES (in_state_id, r.role_sid, 0);
	END LOOP;

	-- deleted columns
	FOR r IN (
		SELECT column_sid, oracle_column name
		  FROM cms.tab_column
		 WHERE column_sid IN (
			SELECT column_sid
			  FROM flow_state_cms_col
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_editable_col_sids)
			 MINUS
			SELECT column_value FROM TABLE(t_non_editable_col_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted column "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_column too
		DELETE FROM flow_state_cms_col
		 WHERE flow_state_id = in_state_Id
		   AND column_sid = r.column_sid;
	END LOOP;

	-- added columns
	FOR r IN (
		SELECT column_sid, oracle_column name
		  FROM cms.tab_column
		 WHERE column_sid IN (
			(
				SELECT column_value FROM TABLE(t_editable_col_sids)
				 UNION
				SELECT column_value FROM TABLE(t_non_editable_col_sids)
			)
			  MINUS
			SELECT column_sid
			  FROM flow_state_cms_col
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for state "{2}"',
			ar.flow_label, r.name, ar.state_label);

		INSERT INTO flow_state_cms_col (flow_state_id, column_sid, is_editable)
			VALUES (in_state_id, r.column_sid, 0);
	END LOOP;

	-- deleted involved
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM csr.flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			SELECT flow_involvement_type_id
			  FROM flow_state_involvement
			 WHERE flow_state_id = in_state_id
			 MINUS
			SELECT column_value FROM TABLE(t_involved_type_ids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted involvement "{1}" for state "{2}"',
			ar.flow_label, r.label, ar.state_label);

		DELETE FROM flow_state_role_capability
		 WHERE flow_state_id = in_state_id
		   AND flow_involvement_type_id = r.flow_involvement_type_id;

		-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_column too
		DELETE FROM flow_state_involvement
		 WHERE flow_state_id = in_state_Id
		   AND flow_involvement_type_id = r.flow_involvement_type_id;
	END LOOP;

	-- added involved
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM csr.flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			(
				SELECT column_value FROM TABLE(t_involved_type_ids)
			)
			  MINUS
			SELECT flow_involvement_type_id
			  FROM flow_state_involvement
			 WHERE flow_state_id = in_state_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for state "{2}"',
			ar.flow_label, r.label, ar.state_label);

		INSERT INTO flow_state_involvement (flow_state_id, flow_involvement_type_id)
			VALUES (in_state_id, r.flow_involvement_type_id);
	END LOOP;

	-- finally set editable or not
	UPDATE flow_state_role
	   SET is_editable = 1
	 WHERE flow_state_id = in_state_id
	   AND role_sid IN (SELECT column_value FROM TABLE(t_editable_role_sids))
	   AND is_editable = 0;

	UPDATE flow_state_role
	   SET is_editable = 0
	 WHERE flow_state_id = in_state_id
	   AND role_sid IN (SELECT column_value FROM TABLE(t_non_editable_role_sids))
	   AND is_editable = 1;

	UPDATE flow_state_cms_col
	   SET is_editable = 1
	 WHERE flow_state_id = in_state_id
	   AND column_sid IN (SELECT column_value FROM TABLE(t_editable_col_sids))
	   AND is_editable = 0;

	UPDATE flow_state_cms_col
	   SET is_editable = 0
	 WHERE flow_state_id = in_state_id
	   AND column_sid IN (SELECT column_value FROM TABLE(t_non_editable_col_sids))
	   AND is_editable = 1;
END;

PROCEDURE SetTransition(
	in_from_state_id				IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id					IN	flow_state_transition.to_state_id%TYPE,
	in_verb							IN	flow_state_transition.verb%TYPE,
	in_lookup_key					IN	flow_state_transition.lookup_key%TYPE,
	in_helper_sp					IN 	flow_state_transition.helper_sp%TYPE,
	in_ask_for_comment				IN	flow_state_transition.ask_for_comment%TYPE DEFAULT 'optional',
	in_mandatory_fields_message		IN	flow_state_transition.mandatory_fields_message%TYPE,
	in_auto_trans_type				IN	flow_state_transition.auto_trans_type%TYPE,
	in_hours_before_auto_tran		IN	flow_state_transition.hours_before_auto_tran%TYPE,
	in_auto_schedule_xml			IN	VARCHAR2,
	in_button_icon_path				IN	flow_state_transition.button_icon_path%TYPE,
	in_pos							IN	flow_state_transition.pos%TYPE,
	in_role_sids					IN	security_pkg.T_SID_IDS,
	in_column_sids					IN	security_pkg.T_SID_IDS,
	in_involved_type_ids			IN	security_pkg.T_SID_IDS,
	in_enforce_validation			IN	flow_state_transition.enforce_validation%TYPE DEFAULT 0,
	out_transition_id				OUT	flow_state_transition.flow_state_transition_id%TYPE
)
AS
	-- there's also a constraint which will force both states to be from the same workflow
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fsf.label from_label, fst.label to_label
		  FROM flow f
		  JOIN flow_state fsf ON f.flow_sid = fsf.flow_sid
		  JOIN flow_state fst ON f.flow_sid = fst.flow_sid
		 WHERE fsf.flow_state_id = in_from_state_Id
		   AND fst.flow_state_id = in_to_state_id;
	ar	c%ROWTYPE;
	t_role_sids						security.T_SID_TABLE := security_pkg.SidArrayToTable(in_role_sids);
	t_column_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_column_sids);
	t_involved_type_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_involved_type_ids);
    v_old_verb						flow_state_transition.verb%TYPE;
    v_old_lookup_key				flow_state_transition.lookup_key%TYPE;
    v_old_mandatory_fields_message	flow_state_transition.mandatory_fields_message%TYPE;
	v_old_hours_before_auto_tran	flow_state_transition.hours_before_auto_tran%TYPE;
    v_old_button_icon_path			flow_state_transition.button_icon_path%TYPE;
    v_old_ask_for_comment			flow_state_transition.ask_for_comment%TYPE;
    v_old_pos						flow_state_transition.pos%TYPE;
	v_old_auto_trans_type			flow_state_transition.auto_trans_type%TYPE;
	v_old_auto_schedule_xml			flow_state_transition.auto_schedule_xml%TYPE;
	v_old_enforce_validation		flow_state_transition.enforce_validation%TYPE;
	v_lookup_count 					NUMBER;
	v_duplicate_trans				VARCHAR2(1024);
BEGIN
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow states from different workflows, or workflow states not found');
	END IF;
	 
	SELECT COUNT(*) 
	  INTO v_lookup_count 
	  FROM flow_state_transition 
	 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
	   AND from_state_id = in_from_state_id
	   AND to_state_id != in_to_state_id
	   AND flow_sid = ar.flow_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_lookup_count > 0 THEN
		SELECT verb
		  INTO v_duplicate_trans
		  FROM flow_state_transition
		 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
		   AND from_state_id = in_from_state_id
		   AND to_state_id != in_to_state_id
		   AND flow_sid = ar.flow_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_LOOKUP_KEY_CONSTRAINT_VIOLATED, 'Transitions:' || v_duplicate_trans || ', ' || in_verb);
	END IF;
	
	BEGIN
		INSERT INTO flow_state_transition
			(flow_state_transition_id, flow_sid, from_state_id, to_state_id, verb, lookup_key, last_run_dtm, ask_for_comment,
			 mandatory_fields_message, auto_trans_type, hours_before_auto_tran, auto_schedule_xml, button_icon_path, pos, enforce_validation)
		VALUES
			(flow_state_transition_id_seq.nextval, ar.flow_sid, in_from_state_id, in_to_state_id, in_verb, in_lookup_key, TRUNC(SYSDATE, 'DD'),
			in_ask_for_comment, in_mandatory_fields_message, in_auto_trans_type, in_hours_before_auto_tran, in_auto_schedule_xml, in_button_icon_path, in_pos, in_enforce_validation)
		RETURNING flow_state_transition_id INTO out_transition_id;

		-- audit
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid,
			'Create transition for workflow "{0}" from "{1}" to "{2}"',
			ar.flow_label, ar.from_Label, ar.to_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT verb, lookup_key, mandatory_fields_message, hours_before_auto_tran, ask_for_comment, button_icon_path, auto_trans_type, auto_schedule_xml, enforce_validation
			  INTO v_old_verb, v_old_lookup_key, v_old_mandatory_fields_message, v_old_hours_before_auto_tran, v_old_ask_for_comment, v_old_button_icon_path, v_old_auto_trans_type, v_old_auto_schedule_xml, v_old_enforce_validation
			  FROM flow_state_transition
			 WHERE from_state_id = in_from_state_id
			   AND to_state_id = in_to_state_id;

			-- update
			UPDATE flow_state_transition
			   SET verb = in_verb,
				   lookup_key = in_lookup_key,
				   mandatory_fields_message = in_mandatory_fields_message,
				   auto_trans_type = in_auto_trans_type,
				   hours_before_auto_tran = in_hours_before_auto_tran,
				   auto_schedule_xml = in_auto_schedule_xml,
				   button_icon_path = in_button_icon_path,
				   ask_for_comment = in_ask_for_comment,
				   pos = in_pos,
				   last_run_dtm = DECODE(in_auto_trans_type, AUTO_TRANS_SCHEDULE, NVL(last_run_dtm, TRUNC(SYSDATE, 'DD')), NULL),
				   enforce_validation = in_enforce_validation
			 WHERE from_state_id = in_from_state_id
			   AND to_state_id = in_to_state_id
		    RETURNING flow_state_transition_id INTO out_transition_id;
	END;

	-- audit transition properties
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Verb', v_old_verb, in_verb, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Tag', v_old_lookup_key, in_lookup_key, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Mandatory fields message', v_old_mandatory_fields_message, in_mandatory_fields_message, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Hours before Auto Transition', v_old_hours_before_auto_tran, in_hours_before_auto_tran, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Icon path', v_old_button_icon_path, in_button_icon_path, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Comments', v_old_ask_for_comment, in_ask_for_comment, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Position', v_old_pos, in_pos, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Auto transition type', v_old_auto_trans_type, in_auto_trans_type, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Auto transition schedule', CASE WHEN v_old_auto_schedule_xml IS NULL THEN NULL ELSE v_old_auto_schedule_xml.getStringVal() END, 
		in_auto_schedule_xml, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Enforce validation', v_old_enforce_validation, in_enforce_validation, out_transition_id);

	-- we ought to audit this, so the long way round (rather than just deleting)
	-- deleted roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT role_sid
			  FROM flow_state_transition_role
			 WHERE flow_state_transition_id = out_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_role_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted role "{1}" for transition "{2}"',
			ar.flow_label, r.name, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_role
		 WHERE flow_state_transition_id = out_transition_id
		   AND role_sid = r.role_sid;
	END LOOP;

	-- added roles
	FOR r IN (
		SELECT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT column_value FROM TABLE(t_role_sids)
			  MINUS
			SELECT role_sid
			  FROM flow_state_transition_role
			 WHERE flow_state_transition_id = out_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added role "{1}" for transition "{2}"',
			ar.flow_label, r.name, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_role (flow_state_transition_id, from_State_Id, role_sid)
			VALUES (out_transition_id, in_from_state_Id, r.role_sid);
	END LOOP;

	-- deleted columns
	FOR r IN (
		SELECT column_sid, oracle_column
		  FROM cms.tab_column
		 WHERE column_sid IN (
			SELECT column_sid
			  FROM flow_state_transition_cms_col
			 WHERE flow_state_transition_id = out_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_column_sids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted column "{1}" for transition "{2}"',
			ar.flow_label, r.oracle_column, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_cms_col
		 WHERE flow_state_transition_id = out_transition_id
		   AND column_sid = r.column_sid;
	END LOOP;

	-- added column
	FOR r IN (
		SELECT column_sid, oracle_column
		  FROM cms.tab_column
		 WHERE column_sid IN (
			SELECT column_value FROM TABLE(t_column_sids)
			  MINUS
			SELECT column_sid
			  FROM flow_state_transition_cms_col
			 WHERE flow_state_transition_id = out_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for transition "{2}"',
			ar.flow_label, r.oracle_column, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_cms_col (flow_state_transition_id, from_State_Id, column_sid)
			VALUES (out_transition_id, in_from_state_Id, r.column_sid);
	END LOOP;

	-- deleted involvement types
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			SELECT flow_involvement_type_id
			  FROM flow_state_transition_inv
			 WHERE flow_state_transition_id = out_transition_id
			 MINUS
			SELECT column_value FROM TABLE(t_involved_type_ids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", deleted invovlement type "{1}" for transition "{2}"',
			ar.flow_label, r.label, ar.from_label||' -> '||ar.to_label);

		DELETE FROM flow_state_transition_inv
		 WHERE flow_state_transition_id = out_transition_id
		   AND flow_involvement_type_id = r.flow_involvement_type_id;
	END LOOP;

	-- added involvement types
	FOR r IN (
		SELECT flow_involvement_type_id, label
		  FROM flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND flow_involvement_type_id IN (
			SELECT column_value FROM TABLE(t_involved_type_ids)
			  MINUS
			SELECT flow_involvement_type_id
			  FROM flow_state_transition_inv
			 WHERE flow_state_transition_id = out_transition_id
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			ar.flow_sid, 'Altered workflow "{0}", added involement type "{1}" for transition "{2}"',
			ar.flow_label, r.label, ar.from_label||' -> '||ar.to_label);

		INSERT INTO flow_state_transition_inv (flow_state_transition_id, from_State_Id, flow_involvement_type_id)
			VALUES (out_transition_id, in_from_state_Id, r.flow_involvement_type_id);
	END LOOP;
END;

PROCEDURE SetFlowFromXml(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_xml			IN	XMLType
)
AS
	v_flow_label				flow.label%TYPE;
	v_flow_alert_class			flow.flow_alert_class%TYPE;
	v_default_state_id			flow_state.flow_state_id%TYPE;
	t_state						T_FLOW_STATE_TABLE;
	t_trans						T_FLOW_STATE_TRANS_TABLE;
	v_transition_id				flow_state_transition.flow_state_transition_id%TYPE;
	v_role_sids					security_pkg.T_SID_IDS;
	v_column_sids				security_pkg.T_SID_IDS;
	v_editable_role_sids		security_pkg.T_SID_IDS;
	v_non_editable_role_sids	security_pkg.T_SID_IDS;
	v_editable_col_sids			security_pkg.T_SID_IDS;
	v_non_editable_col_sids		security_pkg.T_SID_IDS;
	v_involved_type_ids			security_pkg.T_SID_IDS;
	v_first_state_id			csr_data_pkg.T_FLOW_STATE_ID;
	v_is_deleted				flow_state.is_deleted%TYPE;
	v_doc						dbms_xmldom.DOMDocument;
	v_doc_node					dbms_xmldom.DOMNode;
	v_nodes						dbms_xmldom.DOMNodeList;
	v_role_nodes				dbms_xmldom.DOMNodeList;
	v_group_nodes				dbms_xmldom.DOMNodeList;
	v_user_nodes				dbms_xmldom.DOMNodeList;
	v_flow_cms_col_nodes		dbms_xmldom.DOMNodeList;
	v_flow_cms_col_alrt_mgr_nds	dbms_xmldom.DOMNodeList;
	v_node						dbms_xmldom.DOMNode;
	v_element					dbms_xmldom.DOMElement;
	v_customer_alert_type_id	customer_alert_type.customer_alert_type_id%TYPE;
	v_transition_alerts			security.T_SID_TABLE;
	v_flow_transition_alert_id	flow_transition_alert.flow_transition_alert_id%TYPE;
	v_flow_alert_description	flow_transition_alert.description%TYPE;
	v_to_initiator				flow_transition_alert.to_initiator%TYPE;
	v_can_edit_before_send		flow_transition_alert.can_be_edited_before_sending%TYPE;
	v_role_sid					flow_transition_alert_role.role_sid%TYPE;
	v_group_sid					flow_transition_alert_role.group_sid%TYPE;
	v_user_sid					flow_transition_alert_user.user_sid%TYPE;
	v_involved_type_id			flow_transition_alert_inv.flow_involvement_type_id%TYPE;
	v_flow_cms_col_sid			flow_transition_alert_cms_col.column_sid%TYPE;
	v_flow_cms_alert_mgr_flag	flow_transition_alert_cms_col.alert_manager_flag%TYPE;
	v_cms_tab_sid				cms.tab.tab_sid%TYPE;
	v_helper_sp					flow_transition_alert.helper_sp%TYPE;
	v_state_alerts				security.T_SID_TABLE;
	v_flow_state_alert_id		flow_state_alert.flow_state_alert_id%TYPE;
	v_recurrence_node			dbms_xmldom.DOMNode;
	v_recurrence_clob			CLOB;
	v_on_save_helper_sp			flow_alert_class.on_save_helper_sp%TYPE;
BEGIN
	v_doc := dbms_xmldom.newDOMDocument(in_xml);
	v_doc_node := dbms_xmldom.makeNode(v_doc);

	SELECT EXTRACT(in_xml,'/flow/@label').getStringVal(),
		   EXTRACT(in_xml,'/flow/@cmsTabSid').getStringVal(),
		   EXTRACT(in_xml,'/flow/@default-state-id').getStringVal(),
		   EXTRACT(in_xml,'/flow/@flow-alert-class').getStringVal()
	  INTO v_flow_label, v_cms_tab_sid, v_default_state_id, v_flow_alert_class
	  FROM dual;

	-- update the flow alert class if given one
	IF v_flow_alert_class IS NOT NULL THEN
		UPDATE flow
		   SET flow_alert_class = v_flow_alert_class
		 WHERE flow_sid = in_flow_sid;
	ELSE
		SELECT flow_alert_class
		  INTO v_flow_alert_class
		  FROM flow
		 WHERE flow_sid = in_flow_sid;
	END IF;

    RenameFlow(in_flow_sid, v_flow_label);
    IF v_cms_tab_sid IS NOT NULL THEN
	    UPDATE cms.tab
	       SET flow_sid = in_flow_sid
	     WHERE tab_sid = v_cms_tab_sid;
	ELSE
		UPDATE cms.tab
		   SET flow_sid = NULL
		 WHERE flow_sid = in_flow_sid;
	END IF;

    /****************** process states *********************/
	SELECT T_FLOW_STATE_ROW(xt.xml_pos, xt.pos, xt.id, xt.label, xt.lookup_key, xt.is_final, xt.state_colour,
		   REPLACE(xt.editable_role_sids,' ',','), REPLACE(xt.non_editable_role_sids,' ',','),
		   REPLACE(xt.editable_col_sids,' ',','), REPLACE(xt.non_editable_col_sids,' ',','),
		   REPLACE(xt.involved_type_ids,' ',','), xt.attributes_xml, xt.flow_state_nature_id,
		   xt.move_from_flow_state_id)
	  BULK COLLECT INTO t_state
	  FROM XMLTABLE(
		 'for $i in /flow/state
			 return
		        <state id="{$i/@id}" label="{$i/@label}" lookup-key="{$i/@lookup-key}" final="{$i/@final}" colour="{$i/@colour}" pos="{$i/@pos}" move-from-flow-state-id="{$i/@move-from-flow-state-id}">
                    {$i/attributes}
                    <editable-role-sids>
                    { for $j in $i/role
                        return string ($j[@is-editable="1"]/@sid)
                    }
                    </editable-role-sids>
                    <non-editable-role-sids>
                    { for $j in $i/role
                        return string ($j[@is-editable="0"]/@sid)
                    }
                    </non-editable-role-sids>
                    <editable-col-sids>
                    { for $j in $i/cms-user-col
                        return string ($j[@is-editable="1"]/@sid)
                    }
                    </editable-col-sids>
                    <non-editable-col-sids>
                    { for $j in $i/cms-user-col
                        return string ($j[@is-editable="0"]/@sid)
                    }
                    </non-editable-col-sids>
                    <involved-type-ids>
                    { for $j in $i/involved
                        return string ($j/@type-id)
                    }
                    </involved-type-ids>
					{$i/flow-state-nature-id}
                </state>'
		PASSING in_xml
		COLUMNS
			xml_pos            		FOR ORDINALITY,
			pos              		NUMBER(10) PATH '@pos',
			id               		NUMBER(10) PATH '@id',
			label            		VARCHAR2(255) PATH '@label',
			lookup_key       		VARCHAR2(255) PATH '@lookup-key',
			is_final				NUMBER(1) PATH '@final',
			state_colour			NUMBER(10) PATH '@colour',
			editable_role_sids      VARCHAR2(2000) PATH 'editable-role-sids',
			non_editable_role_sids	VARCHAR2(2000) PATH 'non-editable-role-sids',
			editable_col_sids		VARCHAR2(2000) PATH 'editable-col-sids',
			non_editable_col_sids	VARCHAR2(2000) PATH 'non-editable-col-sids',
			involved_type_ids		VARCHAR2(2000) PATH 'involved-type-ids',
			attributes_xml   		XMLTYPE PATH 'attributes',
			flow_state_nature_id	NUMBER(10) PATH 'flow-state-nature-id',
			move_from_flow_state_id NUMBER(10) PATH 'move-from-flow-state-id'
		)xt;

	FOR r IN (
		SELECT id, move_from_flow_state_id
		  FROM TABLE(t_state)
		 WHERE move_from_flow_state_id IS NOT NULL
	) LOOP
		-- Move items before deleting
		IF r.move_from_flow_state_id IS NOT NULL THEN
			UPDATE flow_item
			   SET current_state_id = r.id, last_flow_state_transition_id = null
			 WHERE current_state_id = r.move_from_flow_state_id;

			csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
			in_flow_sid,
			'Moved all items from state "{0}" to state "{1}"',
			r.move_from_flow_state_id, r.id);
		END IF;
	END LOOP;

	-- delete states
    FOR r IN (
		SELECT flow_state_id, move_from_flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid AND is_deleted = 0
		  MINUS
		SELECT id, null FROM TABLE(t_state)
    )
    LOOP
		flow_pkg.DeleteState(r.flow_state_id, r.move_from_flow_state_id); -- assume something has cleaned items up
    END LOOP;

    -- update states
    v_first_state_id := null;
    FOR r IN (
		SELECT xml_pos, pos, id, label, lookup_key, is_final, state_colour, editable_role_sids,
			   non_editable_role_sids, editable_col_sids, non_editable_col_sids,
			   involved_type_ids, attributes_xml, flow_state_nature_id, move_from_flow_state_id
		  FROM TABLE(t_state)
		 WHERE id IN (
			SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid
		 )
    )
    LOOP
		v_first_state_id := NVL(v_first_state_id, r.id);
		AmendState(r.id, r.label, r.is_final, r.lookup_key, r.state_colour, r.pos, r.flow_state_nature_id);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state
		   SET attributes_xml = r.attributes_xml
		 WHERE flow_state_id = r.id;

		v_editable_role_sids     := SidListToArray(r.editable_role_sids);
		v_non_editable_role_sids := SidListToArray(r.non_editable_role_sids);
		v_editable_col_sids      := SidListToArray(r.editable_col_sids);
		v_non_editable_col_sids  := SidListToArray(r.non_editable_col_sids);
		v_involved_type_ids      := SidListToArray(r.involved_type_ids);
		SetStateRoles(r.id, v_editable_role_sids, v_non_editable_role_sids, v_editable_col_sids, v_non_editable_col_sids, v_involved_type_ids);
    END LOOP;

    -- create states
    FOR r IN (
		SELECT xml_pos, pos, id, label, lookup_key, editable_role_sids, non_editable_role_sids, attributes_xml,
			   editable_col_sids, non_editable_col_sids, involved_type_ids, is_final, state_colour, flow_state_nature_id
		  FROM TABLE(t_state)
		 WHERE id NOT IN (
			SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid
		 )
    )
    LOOP
		v_first_state_id := NVL(v_first_state_id, r.id);
		CreateState(r.id, in_flow_sid, r.label, r.lookup_key, r.flow_state_nature_id);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state
		   SET attributes_xml = r.attributes_xml,
			   is_final = NVL(r.is_final,0),
			   state_colour = r.state_colour,
			   pos = NVL(r.pos,1)
		 WHERE flow_state_id = r.id;

		v_editable_role_sids     := SidListToArray(r.editable_role_sids);
		v_non_editable_role_sids := SidListToArray(r.non_editable_role_sids);
		v_editable_col_sids      := SidListToArray(r.editable_col_sids);
		v_non_editable_col_sids  := SidListToArray(r.non_editable_col_sids);
		v_involved_type_ids      := SidListToArray(r.involved_type_ids);
		SetStateRoles(r.id, v_editable_role_sids, v_non_editable_role_sids, v_editable_col_sids, v_non_editable_col_sids, v_involved_type_ids);
    END LOOP;

    -- set default state
    IF v_default_state_id IS NOT NULL THEN
		--security_pkg.debugmsg('Setting default state id to; '||v_default_state_id);
		UPDATE flow
		   SET default_state_id = v_default_state_id
		 WHERE flow_sid = in_flow_sid;
	END IF;

	-- Process state alerts
	FOR r IN (
		SELECT xml_pos, pos, id, label, lookup_key, editable_role_sids, non_editable_role_sids, attributes_xml,
			   editable_col_sids, non_editable_col_sids, involved_type_ids
		  FROM TABLE(t_state)
	) LOOP
		v_state_alerts := security.T_SID_TABLE();
		v_nodes := dbms_xslprocessor.selectNodes(v_doc_node, '(/flow/state)[' || r.xml_pos || ']/alerts/alert');
		FOR i IN 0 .. dbms_xmldom.getLength(v_nodes) - 1
		LOOP
			v_node := dbms_xmldom.item(v_nodes, i);
			v_element := dbms_xmldom.makeElement(v_node);
			v_customer_alert_type_id := dbms_xmldom.getAttribute(v_element, 'customerAlertTypeId');
			v_flow_state_alert_id := dbms_xmldom.getAttribute(v_element, 'flowStateAlertId');
			v_flow_alert_description := dbms_xmldom.getAttribute(v_element, 'description');
			v_helper_sp := dbms_xmldom.getAttribute(v_element, 'helperSp');

			-- Extract Recurrence pattern (hmm, into a CLOB)
			v_recurrence_node := dbms_xslprocessor.selectSingleNode(v_node, 'recurrences');
			dbms_lob.createTemporary(v_recurrence_clob, TRUE);
			dbms_xmldom.writeToClob(v_recurrence_node, v_recurrence_clob);

			--security_pkg.debugmsg('v_flow_state_alert_id = '||v_flow_state_alert_id);

			-- Upsert the alert
			IF v_flow_state_alert_id IS NULL THEN
				--security_pkg.debugmsg('inserting new flow statr alert');
				INSERT INTO flow_state_alert
					(flow_state_alert_id, flow_sid, flow_state_id, description, customer_alert_type_id, flow_alert_helper, recurrence_pattern)
				VALUES
					(flow_state_alert_id_seq.NEXTVAL, in_flow_sid, r.id, v_flow_alert_description, v_customer_alert_type_id, v_helper_sp, XMLType(v_recurrence_clob))
				RETURNING
					flow_state_alert_id INTO v_flow_state_alert_id;
			ELSE
				--security_pkg.debugmsg('updating existing flow statr alert');
				UPDATE flow_state_alert
				   SET customer_alert_type_id = v_customer_alert_type_id,
				   	   description = v_flow_alert_description,
				   	   flow_alert_helper = v_helper_sp,
				   	   recurrence_pattern = XMLType(v_recurrence_clob)
				 WHERE flow_sid = in_flow_sid
				   AND flow_state_alert_id = v_flow_state_alert_id;
			END IF;

			-- Free recurrence pattern CLOB
			dbms_lob.freeTemporary(v_recurrence_clob);

			--security_pkg.debugmsg('v_flow_state_alert_id = '||v_flow_state_alert_id);

			-- Record the state alert id
			v_state_alerts.EXTEND;
			v_state_alerts(v_state_alerts.COUNT) := v_flow_state_alert_id;

			DELETE FROM flow_state_alert_role
			 WHERE flow_state_alert_id = v_flow_state_alert_id;

			v_role_nodes := dbms_xslprocessor.selectNodes(v_node, 'role/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_role_nodes) - 1 LOOP
				v_role_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_role_nodes, j));
				INSERT INTO flow_state_alert_role (flow_sid, flow_state_alert_id, role_sid)
				VALUES (in_flow_sid, v_flow_state_alert_id, v_role_sid);
			END LOOP;

			DELETE FROM flow_state_alert_user
			 WHERE flow_state_alert_id = v_flow_state_alert_id;

			v_user_nodes := dbms_xslprocessor.selectNodes(v_node, 'user/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_user_nodes) - 1 LOOP
				v_user_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_user_nodes, j));
				INSERT INTO flow_state_alert_user (flow_sid, flow_state_alert_id, user_sid)
				VALUES (in_flow_sid, v_flow_state_alert_id, v_user_sid);
			END LOOP;
		END LOOP;

		-- hide deleted alerts (we can't actually delete them without throwing away history if they happen to have fired)
		--security_pkg.debugmsg('r.id = '||r.id);

		UPDATE flow_state_alert
		   SET deleted = 1
		 WHERE flow_sid = in_flow_sid
		   AND flow_state_id = r.id
		   AND flow_state_alert_id NOT IN (
		   		SELECT column_value
		   		  FROM TABLE(v_state_alerts));

	END LOOP;

	/****************** process capabilities *********************/
	FOR r IN (
		SELECT xt.state_id, xt.capability_id, xt.permission_set, xt.role_sid
		  FROM XMLTABLE(
			 'for $i in /flow/state/role/capability
				 return
					<cap state-id="{$i/../../@id}" capability-id="{$i/@cap-id}"
						permission-set="{$i/@permission-set}" role-sid="{$i/../@sid}" />'
			PASSING in_xml
			COLUMNS
				pos              		FOR ORDINALITY,
				state_id           		NUMBER(10) PATH '@state-id',
				capability_id    		NUMBER(10) PATH '@capability-id',
				permission_set    		NUMBER(10) PATH '@permission-set',
				role_sid				NUMBER(10) PATH '@role-sid'
			)xt
	) LOOP
		BEGIN
			INSERT INTO flow_state_role_capability (flow_state_rl_cap_id, flow_state_id,
				flow_capability_id, role_sid, permission_set)
			VALUES (flow_state_rl_cap_id_seq.nextval, r.state_id,
				r.capability_id, r.role_sid, r.permission_set);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE flow_state_role_capability
				   SET permission_set = r.permission_set
				 WHERE flow_state_id = r.state_id
				   AND flow_capability_id = r.capability_id
				   AND role_sid = r.role_sid;
		END;
	END LOOP;

	-- TODO: Ideally this and the block above could be combined
	FOR r IN (
		SELECT xt.state_id, xt.capability_id, xt.permission_set, xt.involvement_type_id
		  FROM XMLTABLE(
			 'for $i in /flow/state/involved/capability
				 return
					<cap state-id="{$i/../../@id}" capability-id="{$i/@cap-id}"
						permission-set="{$i/@permission-set}" type-id="{$i/../@type-id}" />'
			PASSING in_xml
			COLUMNS
				pos              		FOR ORDINALITY,
				state_id           		NUMBER(10) PATH '@state-id',
				capability_id    		NUMBER(10) PATH '@capability-id',
				permission_set    		NUMBER(10) PATH '@permission-set',
				involvement_type_id		NUMBER(10) PATH '@type-id'
			)xt
	) LOOP
		BEGIN
			INSERT INTO flow_state_role_capability (flow_state_rl_cap_id, flow_state_id,
				flow_capability_id, flow_involvement_type_id, permission_set)
			VALUES (flow_state_rl_cap_id_seq.nextval, r.state_id, r.capability_id,
				r.involvement_type_id, r.permission_set);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE flow_state_role_capability
				   SET permission_set = r.permission_set
				 WHERE flow_state_id = r.state_id
				   AND flow_capability_id = r.capability_id
				   AND flow_involvement_type_id = r.involvement_type_id;
		END;
	END LOOP;

    /****************** process transitions *********************/
	SELECT T_FLOW_STATE_TRANS_ROW(xt.pos, xt.id, xt.from_state_id, xt.to_state_id,
			NVL(xt.ask_for_comment,'optional'), xt.mandatory_fields_message, xt.hours_before_auto_tran, xt.button_icon_path, xt.verb,
			xt.lookup_key, xt.helper_sp, REPLACE(xt.role_sids,' ',','), REPLACE(xt.column_sids,' ',','), REPLACE(xt.involved_type_ids,' ',','),
			NVL(xt.enforce_validation, 0), xt.attributes_xml)
	  BULK COLLECT INTO t_trans
	  FROM XMLTABLE(
		'for $i in /flow/state/transition
			return
                <tr from-state-id="{$i/../@id}" to-state-id="{$i/@to-state-id}" lookup-key="{$i/@lookup-key}"
					helper-sp="{$i/@helper-sp}" verb="{$i/@verb}" ask-for-comment="{$i/@ask-for-comment}"
					mandatory-fields-message="{$i/@mandatory-fields-message}"
					hours-before-auto-tran="{$i/@hours-before-auto-tran}"
					button-icon-path="{$i/@button-icon-path}"
					enforce-validation="{$i/@enforce-validation}">
                    {$i/attributes}
                    <role-sids>
						{ for $j in $i/role
							return string ($j/@sid)
						}
                    </role-sids>
                    <cms-column-sids>
						{ for $j in $i/cms-user-col
							return string ($j/@sid)
						}
                    </cms-column-sids>
                    <involved-type-ids>
						{ for $j in $i/involved
							return string ($j/@type-id)
						}
                    </involved-type-ids>
                </tr>'
		PASSING in_xml
		COLUMNS
			pos							FOR ORDINALITY,
			id							NUMBER(10) PATH '@id',
			from_state_id				NUMBER(10) PATH '@from-state-id',
			to_state_id					NUMBER(10) PATH '@to-state-id',
			ask_for_comment				VARCHAR2(16) PATH '@ask-for-comment',
			mandatory_fields_message	VARCHAR2(255) PATH '@mandatory-fields-message',
			hours_before_auto_tran		NUMBER(10) PATH '@hours-before-auto-tran',
			button_icon_path			VARCHAR2(255) PATH '@button-icon-path',
			lookup_key					VARCHAR2(255) PATH '@lookup-key',
			helper_sp					VARCHAR2(255) PATH '@helper-sp',
			verb						VARCHAR2(255) PATH '@verb',
			role_sids					VARCHAR2(2000) PATH 'role-sids',
			column_sids					VARCHAR2(2000) PATH 'cms-column-sids',
			involved_type_ids			VARCHAR2(2000) PATH 'involved-type-ids',
			attributes_xml				XMLTYPE PATH 'attributes',
			enforce_validation			NUMBER(1) PATH '@enforce-validation'
		)xt;

	-- delete
    FOR r IN (
		SELECT from_state_Id, to_state_id FROM flow_state_transition WHERE flow_sid = in_flow_sid
		  MINUS
		SELECT from_state_id, to_state_id FROM TABLE(t_trans)
    )
    LOOP
		flow_pkg.RemoveTransition(r.from_state_id, r.to_state_id);
    END LOOP;

    -- create/update transitions
    FOR r IN (
		SELECT pos, id, from_state_id, to_state_id, ask_for_comment, mandatory_fields_message, hours_before_auto_tran,
			   button_icon_path, verb, lookup_key, helper_sp, role_sids, column_sids, involved_type_ids, attributes_xml, enforce_validation
		  FROM TABLE(t_trans)
    )
    LOOP
		v_role_sids := SidListToArray(r.role_sids);
		v_column_sids := SidListToArray(r.column_sids);
		v_involved_type_ids := SidListToArray(r.involved_type_ids);

		SetTransition(r.from_state_id, r.to_state_id, r.verb, r.lookup_key, r.helper_sp,
			r.ask_for_comment, r.mandatory_fields_message, 0, r.hours_before_auto_tran, null, r.button_icon_path, r.pos, v_role_sids,
			v_column_sids, v_involved_type_ids, r.enforce_validation, v_transition_id);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state_transition
		   SET attributes_xml = r.attributes_xml, helper_sp = r.helper_sp
		 WHERE flow_state_transition_id = v_transition_id;

		v_transition_alerts	:= security.T_SID_TABLE();

		-- TODO: helper
		--<alerts><alert customerAlertTypeId="1" description="New alert" helperSp="foo.foo_pkg.bar"><role name="Data Providers" sid="100595"/></alert><alert customerAlertTypeId="-2" description="New alert2"><role name="MHRP Site Manager" sid="754676"/></alert></alerts>
		--security_pkg.debugmsg('processing alerts for pos '||r.pos||' trid '||v_transition_id|| ' from '||r.from_state_id||' to '||r.to_state_id);
		v_nodes := dbms_xslprocessor.selectNodes(v_doc_node, '(/flow/state/transition)[' || r.pos || ']/alerts/alert');
		FOR i IN 0 .. dbms_xmldom.getLength(v_nodes) - 1 LOOP
			v_node := dbms_xmldom.item(v_nodes, i);
			v_element := dbms_xmldom.makeElement(v_node);
			v_customer_alert_type_id := dbms_xmldom.getAttribute(v_element, 'customerAlertTypeId');
			v_to_initiator := NVL(dbms_xmldom.getAttribute(v_element, 'toInitiator'), 0);
			v_can_edit_before_send := NVL(dbms_xmldom.getAttribute(v_element, 'canBeEditedBeforeSending'), 0);
			v_flow_transition_alert_id := dbms_xmldom.getAttribute(v_element, 'flowTransitionAlertId');

			v_flow_alert_description := dbms_xmldom.getAttribute(v_element, 'description');
			v_helper_sp := dbms_xmldom.getAttribute(v_element, 'helperSp');

			IF v_flow_transition_alert_id IS NULL THEN
				INSERT INTO flow_transition_alert
					(flow_transition_alert_id, flow_state_transition_id, description, customer_alert_type_id, to_initiator, can_be_edited_before_sending, helper_sp, flow_alert_helper)
				VALUES
					(flow_transition_alert_id_seq.nextval, v_transition_id, v_flow_alert_description, v_customer_alert_type_id, v_to_initiator, v_can_edit_before_send,
						DECODE(v_flow_alert_class, 'cms', v_helper_sp, NULL),
						DECODE(v_flow_alert_class, 'cms', NULL, v_helper_sp)
					)
				RETURNING
					flow_transition_alert_id INTO v_flow_transition_alert_id;
			ELSE
				UPDATE flow_transition_alert
				   SET customer_alert_type_id = v_customer_alert_type_id,
				   	   description = v_flow_alert_description,
				   	   helper_sp = DECODE(v_flow_alert_class, 'cms', v_helper_sp, NULL),
				   	   flow_alert_helper = DECODE(v_flow_alert_class, 'cms', NULL, v_helper_sp),
				   	   to_initiator = v_to_initiator,
					   can_be_edited_before_sending = v_can_edit_before_send
				 WHERE flow_transition_alert_id = v_flow_transition_alert_id;
			END IF;
			v_transition_alerts.extend;
			v_transition_alerts(v_transition_alerts.count) := v_flow_transition_alert_id;

			DELETE FROM flow_transition_alert_role
			 WHERE flow_transition_alert_id = v_flow_transition_alert_id;

			v_role_nodes := dbms_xslprocessor.selectNodes(v_node, 'role/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_role_nodes) - 1 LOOP
				v_role_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_role_nodes, j));
				INSERT INTO flow_transition_alert_role (flow_transition_alert_id, role_sid)
				VALUES (v_flow_transition_alert_id, v_role_sid);
			END LOOP;

			v_group_nodes := dbms_xslprocessor.selectNodes(v_node, 'group/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_group_nodes) - 1 LOOP
				v_group_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_group_nodes, j));
				INSERT INTO flow_transition_alert_role (flow_transition_alert_id, group_sid)
				VALUES (v_flow_transition_alert_id, v_group_sid);
			END LOOP;

			DELETE FROM flow_transition_alert_user
			 WHERE flow_transition_alert_id = v_flow_transition_alert_id;

			v_user_nodes := dbms_xslprocessor.selectNodes(v_node, 'user/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_user_nodes) - 1 LOOP
				v_user_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_user_nodes, j));
				INSERT INTO flow_transition_alert_user (flow_transition_alert_id, user_sid)
				VALUES (v_flow_transition_alert_id, v_user_sid);
			END LOOP;

			DELETE FROM flow_transition_alert_cc_role
			 WHERE flow_transition_alert_id = v_flow_transition_alert_id;

			v_role_nodes := dbms_xslprocessor.selectNodes(v_node, 'cc-role/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_role_nodes) - 1 LOOP
				v_role_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_role_nodes, j));
				INSERT INTO flow_transition_alert_cc_role (flow_transition_alert_id, role_sid)
				VALUES (v_flow_transition_alert_id, v_role_sid);
			END LOOP;

			v_group_nodes := dbms_xslprocessor.selectNodes(v_node, 'cc-group/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_group_nodes) - 1 LOOP
				v_group_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_group_nodes, j));
				INSERT INTO flow_transition_alert_cc_role (flow_transition_alert_id, group_sid)
				VALUES (v_flow_transition_alert_id, v_group_sid);
			END LOOP;

			DELETE FROM flow_transition_alert_cc_user
			 WHERE flow_transition_alert_id = v_flow_transition_alert_id;

			v_user_nodes := dbms_xslprocessor.selectNodes(v_node, 'cc-user/@sid');
			FOR j IN 0 .. dbms_xmldom.getLength(v_user_nodes) - 1 LOOP
				v_user_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_user_nodes, j));
				INSERT INTO flow_transition_alert_cc_user (flow_transition_alert_id, user_sid)
				VALUES (v_flow_transition_alert_id, v_user_sid);
			END LOOP;

			DELETE FROM flow_transition_alert_cms_col
			 WHERE flow_transition_alert_id = v_flow_transition_alert_id;

			v_flow_cms_col_nodes := dbms_xslprocessor.selectNodes(v_node, 'flow-cms-cols/@sid');
			v_flow_cms_col_alrt_mgr_nds := dbms_xslprocessor.selectNodes(v_node, 'flow-cms-cols/@alert-manager-flag');
			FOR j IN 0 .. dbms_xmldom.getLength(v_flow_cms_col_nodes) - 1 LOOP
				v_flow_cms_col_sid := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_flow_cms_col_nodes, j));
				v_flow_cms_alert_mgr_flag := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_flow_cms_col_alrt_mgr_nds, j));

				INSERT INTO flow_transition_alert_cms_col (flow_transition_alert_id, column_sid, alert_manager_flag)
				VALUES (v_flow_transition_alert_id, v_flow_cms_col_sid, v_flow_cms_alert_mgr_flag);
			END LOOP;

			DELETE FROM flow_transition_alert_inv
			 WHERE flow_transition_alert_id = v_flow_transition_alert_id;

			v_role_nodes := dbms_xslprocessor.selectNodes(v_node, 'involved/@type-id');
			FOR j IN 0 .. dbms_xmldom.getLength(v_role_nodes) - 1 LOOP
				v_involved_type_id := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_role_nodes, j));
				INSERT INTO flow_transition_alert_inv (flow_transition_alert_id, flow_involvement_type_id)
				VALUES (v_flow_transition_alert_id, v_involved_type_id);
			END LOOP;
		END LOOP;

		-- hide deleted alerts (we can't actually delete them without throwing away history if they
		-- happen to have fired)
		UPDATE flow_transition_alert
		   SET deleted = 1
		 WHERE flow_state_transition_id = v_transition_id
		   AND flow_transition_alert_id NOT IN (
		   		SELECT column_value
		   		  FROM TABLE(v_transition_alerts));
    END LOOP;

    -- check that the default flow state hasn't been deleted
    SELECT f.default_state_id, fs.is_deleted
      INTO v_default_state_id, v_is_deleted
      FROM flow f
	  LEFT JOIN flow_state fs ON f.default_state_id = fs.flow_state_id AND f.app_sid = fs.app_sid
     WHERE f.flow_sid = in_flow_sid;

    -- a deleted default flow state is a seriously bad idea because then there will be
    -- no transitions etc, so switch it to the first state we were passed. The UI ought
    -- to cope with this better (i.e. flagging that there's no default / easily letting
    -- the user change the default). This will save the 2+ hours that MDW and I spent
    -- trying to figure out a weird problem pre some demo!
    IF v_is_deleted = 1 THEN
		--security_pkg.debugmsg('Default state showing as deleted so setting to; '||v_first_state_id);
		UPDATE flow
		   SET default_state_id = v_first_state_id
		 WHERE flow_sid = in_flow_sid;
		v_default_state_id := v_first_state_id;
    END IF;

    IF v_default_state_id IS NULL THEN
		RAISE csr_data_pkg.FLOW_HAS_NO_DEFAULT_STATE;
    END IF;

	-- Fire save helper?
	BEGIN
		SELECT on_save_helper_sp
		  INTO v_on_save_helper_sp
		  FROM flow_alert_class
		 WHERE flow_alert_class = v_flow_alert_class;

		IF v_on_save_helper_sp IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||v_on_save_helper_sp||'(:1);end;'
				USING in_flow_sid;
		END IF;

	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

END;

PROCEDURE NewFlowAlertType(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	flow_alert_type.label%TYPE,
	out_customer_alert_type_id	OUT	customer_alert_type.customer_alert_type_Id%TYPE
)
AS
	v_helper_pkg	flow.helper_pkg%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;

	INSERT INTO customer_alert_type (customer_alert_type_id)
		VALUES (customer_alert_type_Id_seq.nextval)
		RETURNING customer_alert_type_id INTO out_customer_alert_type_id;

	INSERT INTO flow_alert_type (customer_alert_type_id, flow_sid, label)
		VALUES (out_customer_alert_type_id, in_flow_sid, in_label);

	-- now call our helper package if present
	-- XXX: should we complain if there isn't a helper? We're fairly stuffed if it's not present since we'll have no alert parameters etc
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	IF v_helper_pkg IS NOT NULL THEN
	    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.NewFlowAlertType(:1,:2);end;'
			USING in_flow_sid, out_customer_alert_type_id;
	END IF;
END;


PROCEDURE GetFile(
	in_flow_state_log_file_id	IN	flow_state_log_file.flow_state_log_file_id%TYPE,
	in_sha1						IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_flow_state_id	flow_state.flow_state_id%TYPE;
BEGIN
	SELECT flow_state_id
	  INTO v_flow_state_id
	  FROM flow_state_log_file fslf
		JOIN flow_state_log fsl ON fslf.flow_state_log_id = fsl.flow_state_log_id AND fslf.app_sid = fsl.app_sid
	 WHERE flow_state_log_file_id = in_flow_state_log_file_id
	   AND sha1 = in_sha1;
	/*
	-- TODO
	IF NOT IsReadAccessAllowed(v_flow_state_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied download the flow state log file id '||in_flow_state_log_file_id);
	END IF;
	*/
	OPEN out_cur FOR
		SELECT filename, mime_type, data, cast(sha1 as varchar2(40)) sha1, uploaded_dtm
		  FROM flow_state_log_file
		 WHERE flow_state_log_file_id = in_flow_state_log_file_id;
END;



FUNCTION AddToLog(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE DEFAULT NULL,
	in_user_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID')
) RETURN flow_state_log.flow_state_log_id%TYPE
AS
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	SELECT flow_state_log_id_seq.nextval INTO v_flow_state_log_id FROM DUAL;

	INSERT INTO flow_state_log
		(flow_state_log_id, flow_item_id, flow_state_id, set_by_user_sid, comment_text)
		SELECT v_flow_state_log_id, in_flow_item_id, current_state_id,
			in_user_sid, in_comment_text
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;

	UPDATE flow_item
	   SET last_flow_state_log_id = v_flow_state_log_id
	 WHERE flow_item_id = in_flow_item_id;

	RETURN v_flow_state_log_id;
END;


FUNCTION AddToLog(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE DEFAULT NULL,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_user_sid			IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID')
) RETURN flow_state_log.flow_state_log_id%TYPE
AS
	v_cache_key_tbl			security.T_VARCHAR2_TABLE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	v_flow_state_log_id := AddToLog(in_flow_item_id, in_comment_text, in_user_sid);

	-- crap hack for ODP.NET
    IF in_cache_keys IS NULL OR (in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		-- do nothing
        NULL;
    ELSE
		v_cache_key_tbl := security_pkg.Varchar2ArrayToTable(in_cache_keys);
		INSERT INTO flow_state_log_file
			(flow_state_log_file_id, flow_state_log_id, filename, mime_type, data, sha1)
			SELECT flow_state_log_file_Id_seq.nextval, v_flow_state_log_id, filename, mime_type, object,
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache
			 WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)
			 );
	END IF;

	RETURN v_flow_state_log_id;
END;


PROCEDURE AddQuickSurveyResponse(
	in_survey_response_id	IN	flow_item.survey_response_id%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	out_flow_item_id		OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow.default_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	SELECT default_state_id
	  INTO v_default_state_id
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	INSERT INTO flow_item (flow_item_id, flow_sid, current_state_id, survey_response_id)
		VALUES (flow_item_id_seq.nextval, in_flow_sid, v_default_state_id, in_survey_response_id)
		RETURNING flow_Item_id INTO out_flow_item_id;

	v_flow_state_log_id := AddToLog(in_flow_item_id => out_flow_item_id);
END;

PROCEDURE AddApprovalDashboardInstance(
	in_dashboard_instance_id	IN	approval_dashboard_instance.dashboard_instance_id%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow.default_state_id%TYPE;
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	SELECT MIN(flow.default_state_id), MIN(flow.flow_sid)
	  INTO v_default_state_id, v_flow_sid
	  FROM approval_dashboard_instance adi
		JOIN approval_dashboard ad ON adi.approval_dashboard_sid = ad.approval_dashboard_sid
		JOIN flow ON ad.flow_sid = flow.flow_sid
	 WHERE adi.dashboard_instance_id = in_dashboard_instance_id;

	IF v_flow_sid IS NULL THEN
		-- no workflow attached
		out_flow_item_id := NULL;
		RETURN;
	END IF;

	INSERT INTO FLOW_ITEM (flow_item_id, flow_sid, current_state_id, dashboard_instance_id)
		VALUES (flow_item_id_seq.nextval, v_flow_sid, v_default_state_id, in_dashboard_instance_id)
		RETURNING flow_Item_id INTO out_flow_item_id;

	v_flow_state_log_id := AddToLog(in_flow_item_id => out_flow_item_id);
END;

PROCEDURE GetInboundCmsAccounts(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as this is run from a batch job
	OPEN out_cur FOR
		SELECT c.host, t.oracle_schema, t.oracle_table, t.description tab_description, f.label flow_label,
			   a.inbox_sid, ica.tab_sid, ica.flow_sid, ica.default_region_sid
		  FROM inbound_cms_account ica
		  JOIN cms.tab t ON ica.tab_sid = t.tab_sid AND ica.app_sid = t.app_sid
		  JOIN csr.flow f ON ica.flow_sid = f.flow_sid
		  JOIN csr.customer c ON ica.app_sid = c.app_sid
		  JOIN mail.account a ON ica.account_sid = a.account_sid;
END;

-- this is coming in from an email so let's not be so picky about the
-- user.
PROCEDURE AddInboundCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sid				IN	region.region_sid%TYPE,
	in_comment_text				IN	flow_state_log.comment_text%TYPE,
	in_flow_state_id			IN  flow_state.flow_state_Id%TYPE DEFAULT NULL,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow_state.flow_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	IF in_flow_state_id IS NULL THEN
		SELECT default_state_id
		  INTO v_default_state_id
		  FROM flow
		 WHERE flow_sid = in_flow_sid;
	ELSE
		v_default_state_id := in_flow_state_id;
	END IF;

	INSERT INTO flow_item
		(flow_item_id, flow_sid, current_state_id)
	VALUES
		(flow_item_id_seq.NEXTVAL, in_flow_sid, v_default_state_id)
	RETURNING
		flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := AddToLog(
		in_flow_item_id => out_flow_item_id,
		in_comment_text => in_comment_text
	);
END;

FUNCTION CanSeeDefaultState(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	RETURN CanAccessDefaultState(in_flow_sid, in_region_sid, 0);
END;

FUNCTION CanSeeDefaultState(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_region_sids				IN	security_pkg.T_SID_IDS
) RETURN NUMBER
AS
BEGIN
	RETURN CanAccessDefaultState(in_flow_sid, in_region_sids, 0);
END;

FUNCTION CanAccessDefaultState(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_can_edit					IN	NUMBER DEFAULT 0
) RETURN NUMBER
AS
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;

	RETURN CanAccessDefaultState(in_flow_sid, v_region_sids, in_can_edit);
END;

FUNCTION CanAccessDefaultState(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_region_sids				IN	security_pkg.T_SID_IDS,
	in_can_edit					IN	NUMBER DEFAULT 0
) RETURN NUMBER
AS
	v_count_roles			NUMBER DEFAULT 0;
	v_count_groups			NUMBER DEFAULT 0;
	v_regions_table			security.T_SID_TABLE;
BEGIN
	v_regions_table	:= security_pkg.SidArrayToTable(in_region_sids);

	-- check if the logged on user can see the default state based on the region
	SELECT COUNT(*)
	  INTO v_count_roles
	  FROM flow f
	  JOIN flow_state fs ON f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
	  JOIN flow_state_role fsr ON fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
	  JOIN region_role_member rrm ON fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
	  JOIN TABLE(v_regions_table) rs ON rrm.region_sid = rs.column_value
	 WHERE f.flow_sid = in_flow_sid
	   AND fsr.role_sid IS NOT NULL
	   AND (in_can_edit = 0 OR fsr.is_editable = 1)
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID');

	SELECT COUNT(*)
	  INTO v_count_groups
	  FROM flow f
	  JOIN flow_state fs ON f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
	  JOIN flow_state_role fsr ON fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
	  JOIN security.act act ON act.sid_id = fsr.group_sid
	 WHERE f.flow_sid = in_flow_sid
	   AND (in_can_edit = 0 OR fsr.is_editable = 1)
	   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT');

	IF v_count_roles + v_count_groups > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE AddFlowItem_UNSEC(
	in_flow_sid				IN	flow.flow_sid%TYPE,
	in_resource_uuid 		IN	flow_item.resource_uuid%TYPE DEFAULT NULL,
	out_flow_item_id		OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow.default_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	SELECT default_state_id
	  INTO v_default_state_id
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	INSERT INTO flow_item
		(flow_item_id, flow_sid, current_state_id, resource_uuid)
	VALUES
		(flow_item_id_seq.NEXTVAL, in_flow_sid, v_default_state_id, in_resource_uuid)
	RETURNING
		flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := AddToLog(in_flow_item_id => out_flow_item_id);
END;

PROCEDURE AddFlowItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow.default_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	-- security?
	
	AddFlowItem_UNSEC (
		in_flow_sid			=> in_flow_sid,
		out_flow_item_id	=> out_flow_item_id
	);

END;

PROCEDURE AddOrGetFlowItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_resource_uuid			IN	flow_item.resource_uuid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow.default_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
	v_resource_uuid		 	flow_item.resource_uuid%TYPE DEFAULT lower(in_resource_uuid);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can create flow items');
	END IF;
	
	BEGIN
		AddFlowItem_UNSEC(
			in_flow_sid			=> in_flow_sid,
			in_resource_uuid	=> v_resource_uuid,
			out_flow_item_id	=> out_flow_item_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT flow_item_id
			  INTO out_flow_item_id
			  FROM flow_item
			 WHERE resource_uuid = v_resource_uuid;
	END;
END;

PROCEDURE AddCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sid				IN	region.region_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	AddCmsItem(in_flow_sid, v_region_sids, out_flow_item_id);
END;

PROCEDURE AddCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sids				IN	security_pkg.T_SID_IDS,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_owner_can_create		flow.owner_can_create%TYPE;
	t_region_sids			security.T_SID_TABLE;
	v_error_regions			VARCHAR2(255) := '';
BEGIN
	-- check to see if we're using owners. Assumption is that if we're inserting a new
	-- row then we're the owner. There's a check in the C# once we've done the insert
	-- to see if that's really the case.
	SELECT owner_can_create
	  INTO v_owner_can_create
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	IF v_owner_can_create = 0 AND CanSeeDefaultState(in_flow_sid, in_region_sids) = 0 AND cms.tab_pkg.CanSetDefaultStateTrans(in_flow_sid) = 0
	AND NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
		FOR r IN (SELECT column_value FROM TABLE(t_region_sids))
		LOOP
			v_error_regions := v_error_regions||r.column_value||', ';
		END LOOP;
		IF v_error_regions IS NULL THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED,
				'You cannot add a new cms item. User with sid '||SYS_CONTEXT('SECURITY', 'SID')||' has no permissions to make a transition from the default state of the flow with sid '||in_flow_sid);
		ELSE
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED,
				'You cannot add a new cms item. The flow with sid '||in_flow_sid||' has no default state available for the region with sid '||
					v_error_regions||' and the user with sid '||SYS_CONTEXT('SECURITY', 'SID'));
		END IF;

	END IF;

	AddFlowItem(in_flow_sid, out_flow_item_id);
END;

PROCEDURE AddCmsItemByComp(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_region_sids					security_pkg.T_SID_IDS;
BEGIN
	v_region_sids := supplier_pkg.GetRegSidsFromCompSids(in_company_sids);
	
	AddCmsItem(in_flow_sid, v_region_sids, out_flow_item_id);
END;

PROCEDURE AddSectionItem(
	in_section_sid				IN  section.section_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_item_id			section.flow_item_id%TYPE;
BEGIN
	-- TODO: security checks
	-- what if section has flow_item_id already?
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM section where section_sid = in_section_sid;

	IF v_flow_item_id IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Can''t create section flow item for section with sid ' || in_section_sid || ' because it has flow_item_id already: ' || v_flow_item_id);
	END IF;

	SELECT flow_sid
	  INTO v_flow_sid
	  FROM section_module
	 WHERE module_root_sid = (
		SELECT module_root_sid FROM section WHERE section_sid = in_section_sid
	 );

	AddFlowItem(v_flow_sid, out_flow_item_id);

	UPDATE section
	   SET flow_item_id = out_flow_item_id
	 WHERE section_sid = in_section_sid;
END;

PROCEDURE AddAuditItem(
	in_audit_sid				IN  internal_audit.internal_audit_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
	v_flow_item_id			internal_audit.flow_item_id%TYPE;
BEGIN
	-- TODO: security checks
	-- what if audit has flow_item_id already?
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM internal_audit where internal_audit_sid = in_audit_sid;

	IF v_flow_item_id IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Can''t create audit flow item for audit with sid ' || in_audit_sid || ' because it has flow_item_id already: ' || v_flow_item_id);
	END IF;

	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM internal_audit_type
		 WHERE internal_audit_type_id = (
			SELECT internal_audit_type_id FROM internal_audit WHERE internal_audit_sid = in_audit_sid
		 );
	EXCEPTION
		WHEN no_data_found THEN
			-- flow_sid is optional on audits
			NULL;
	END;

	IF v_flow_sid IS NOT NULL THEN
		AddFlowItem(v_flow_sid, out_flow_item_id);

		UPDATE internal_audit
		   SET flow_item_id = out_flow_item_id
		 WHERE internal_audit_sid = in_audit_sid;
	END IF;
END;

FUNCTION GetAlertClassHelperPkg(
	in_flow_item_id	IN	flow_item.flow_item_id%TYPE
)RETURN flow_alert_class.helper_pkg%TYPE
AS
	v_flow_alert_class_helper_pkg	flow_alert_class.helper_pkg%TYPE;
BEGIN
	BEGIN
		SELECT fac.helper_pkg
		  INTO v_flow_alert_class_helper_pkg
		  FROM flow f
		  JOIN flow_item fi ON fi.flow_sid = f.flow_sid
		  JOIN flow_alert_class fac ON f.flow_alert_class = fac.flow_alert_class
		 WHERE f.app_sid = security_pkg.getApp
		   AND fi.flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_alert_class_helper_pkg := NULL;
	END;

	RETURN v_flow_alert_class_helper_pkg;
END;

FUNCTION GetFlowRegionSids (
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE
AS
	v_flow_alert_class_helper_pkg	flow_alert_class.helper_pkg%TYPE;
	v_region_sids_t					security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	--check the flow_alert_class and redirect the call to fill the region_sids
	v_flow_alert_class_helper_pkg := GetAlertClassHelperPkg(in_flow_item_id);

	IF v_flow_alert_class_helper_pkg IS NULL THEN
		RETURN NULL;
	END IF;
	
	EXECUTE IMMEDIATE
		'BEGIN :v_region_sids_t := ' || v_flow_alert_class_helper_pkg || '.GetFlowRegionSids(:in_flow_item_id);END;'
	USING OUT v_region_sids_t, IN in_flow_item_id;
	RETURN v_region_sids_t;
EXCEPTION
	WHEN PROC_NOT_FOUND THEN
		RETURN NULL;
END;

PROCEDURE GetFlowItem(
	in_flow_item_id				IN  flow_item.flow_item_id%TYPE,
	out_cur						OUT SYS_REFCURSOR,
	out_transition_cur			OUT SYS_REFCURSOR,
	out_capability_cur			OUT SYS_REFCURSOR,
	out_survey_tag_cur			OUT SYS_REFCURSOR
)
AS
	v_region_sids_t				security.T_SID_TABLE;
	v_flow_sid					security_pkg.T_SID_ID;
	v_is_editable				NUMBER(1);
	v_current_state_id			flow_item.current_state_id%TYPE;
BEGIN
	v_region_sids_t := GetFlowRegionSids(in_flow_item_id);
	
	IF v_region_sids_t IS NULL THEN 
		RAISE_APPLICATION_ERROR(-20001, 'GetFlowRegionSids returned NULL for flow_item_id: '||in_flow_item_id);
	END IF;
	
	BEGIN
		SELECT flow_sid, current_state_id
		  INTO v_flow_sid, v_current_state_id
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;
	
	-- check permission on the workflow - bit lame
	-- TODO: how do we secure this stuff better?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;
	
	v_is_editable := GetFlowItemIsEditable(in_flow_item_id, v_region_sids_t);
	
	OPEN out_cur FOR
		SELECT fi.flow_sid, f.label flow_label, fi.flow_item_id, fi.current_state_id,
			   fs.label current_state_label, fs.lookup_key current_state_lookup_key,
			   fs.flow_state_nature_id current_state_nature_id, v_is_editable is_editable,
			   case when f.flow_alert_class = 'campaign' THEN fs.survey_editable END current_state_survey_editable,
			   fi.last_flow_state_log_id, fi.last_flow_state_transition_id, fs.state_colour current_state_colour
		  FROM flow_item fi
		  JOIN flow f ON fi.flow_sid = f.flow_sid
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE fi.flow_item_id = in_flow_item_id;
	
	GetFlowItemTransitions(in_flow_item_id, v_region_sids_t, out_transition_cur);
	
	GetItemCapabilityPermissions(
		in_flow_item_id					=>	in_flow_item_id,
		in_region_sids					=>	v_region_sids_t,
		out_cur							=>	out_capability_cur
	);
	
	OPEN out_survey_tag_cur FOR
		SELECT t.tag_id, t.tag tag_label, tg.name tag_group_label
		  FROM flow_state_survey_tag fsst
		  JOIN v$tag t ON fsst.tag_id = t.tag_id
		  JOIN tag_group_member tgm ON t.app_sid = tgm.app_sid AND t.tag_id = tgm.tag_id
		  JOIN v$tag_group tg ON tgm.app_sid = tg.app_sid AND tgm.tag_group_id = tg.tag_group_id
		 WHERE fsst.flow_state_id = v_current_state_id;
END;

PROCEDURE GenerateRecipientAlerts (
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_state_log_id			IN	flow_state_log.flow_state_log_id%TYPE,
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE,
	in_user_sids					IN	security.security_pkg.T_SID_IDS,
	in_role_sids					IN	security.security_pkg.T_SID_IDS,
	in_group_sids					IN	security.security_pkg.T_SID_IDS,
	in_inv_type_ids					IN	security.security_pkg.T_SID_IDS,
	in_subject_override				IN	flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN	flow_item_generated_alert.body_override%TYPE DEFAULT NULL
)
AS
	v_set_by_user_sid				security.security_pkg.T_SID_ID;
	v_role_user_sids				security.security_pkg.T_SID_IDS;
	t_user_sids 					security.T_SID_TABLE;
	t_role_user_sids 				security.T_SID_TABLE;
	t_group_user_sids 				security.T_SID_TABLE;
	t_tmp_group_user_sids			security.T_SID_TABLE;
	t_inv_type_ids					security.T_SID_TABLE;
	t_role_sids 					security.T_SID_TABLE DEFAULT security.security_pkg.SidArrayToTable(in_role_sids);
	t_group_sids 					security.T_SID_TABLE DEFAULT security.security_pkg.SidArrayToTable(in_group_sids);
	v_region_sids_t					security.T_SID_TABLE;
	v_flow_alert_class_helper_pkg	flow_alert_class.helper_pkg%TYPE;
BEGIN
	v_set_by_user_sid := in_set_by_user_sid;
	IF v_set_by_user_sid IS NULL THEN
		v_set_by_user_sid := SYS_CONTEXT('SECURITY','SID');
	END IF;
	
	v_flow_alert_class_helper_pkg := GetAlertClassHelperPkg(in_flow_item_id);

	IF v_flow_alert_class_helper_pkg IS NULL THEN
		RETURN;
	END IF;

	v_region_sids_t := GetFlowRegionSids(in_flow_item_id);
	
	IF v_region_sids_t IS NULL THEN
		v_region_sids_t := security.T_SID_TABLE();
	END IF;

	t_user_sids := security.security_pkg.SidArrayToTable(in_user_sids);

	SELECT DISTINCT rrm.user_sid
	  BULK COLLECT INTO v_role_user_sids
	  FROM region_role_member rrm
	  JOIN TABLE(t_role_sids) r ON r.column_value = rrm.role_sid
	  JOIN TABLE(v_region_sids_t) t ON t.column_value = rrm.region_sid  --perf may be improved if we pass region_sid value when v_region_sids_t length = 1
	  JOIN csr_user cu ON cu.app_sid = rrm.app_sid AND cu.csr_user_sid = rrm.user_sid AND cu.send_alerts = 1;

	t_role_user_sids := security.security_pkg.SidArrayToTable(v_role_user_sids);

	--TODO: looks pretty inefficient, and groups may have loads of users, so probably best to use
	--a temp table to store which users belong to the specified groups.
	t_group_user_sids := security.T_SID_TABLE();
	FOR r IN (
		SELECT column_value group_sid
		  FROM TABLE(t_group_sids)
	)
	LOOP
		SELECT t.sid_id
		  BULK COLLECT INTO t_tmp_group_user_sids
		  FROM TABLE(security.group_pkg.GetMembersAsTableUNSEC(r.group_sid)) t
		 WHERE NOT EXISTS (
			SELECT 1
			  FROM flow_item_generated_alert figa
			 WHERE figa.app_sid = security.security_pkg.GetApp
			   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
			   AND figa.flow_state_log_id = in_flow_state_log_id
			   AND figa.to_user_sid = t.sid_id
			);
		t_group_user_sids := t_group_user_sids MULTISET UNION t_tmp_group_user_sids;
	END LOOP;

	INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id,
		from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, subject_override, body_override)
	SELECT security.security_pkg.GetApp, flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, in_set_by_user_sid,
		t.column_value, NULL, in_flow_item_id, in_flow_state_log_id, in_subject_override, in_body_override
	  FROM (
		SELECT column_value FROM TABLE(t_user_sids)
		 UNION
		SELECT column_value FROM TABLE(t_role_user_sids)
		 UNION
		SELECT column_value FROM TABLE(t_group_user_sids)
		) t
	  JOIN csr.csr_user u ON u.csr_user_sid = t.column_value
	 WHERE u.send_alerts = 1;

	t_inv_type_ids := security.security_pkg.SidArrayToTable(in_inv_type_ids);
	FOR r IN (
		SELECT column_value flow_involvement_type_id
		  FROM TABLE(t_inv_type_ids)
	)
	LOOP
		INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id,
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, subject_override, body_override)
		SELECT app_sid, flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, in_set_by_user_sid, user_sid, NULL,
			in_flow_item_id, in_flow_state_log_id, in_subject_override, in_body_override
		  FROM (
			SELECT DISTINCT fii.app_sid, fii.user_sid
			  FROM flow_item_involvement fii
			 WHERE fii.flow_item_id = in_flow_item_id
			   AND fii.flow_involvement_type_id = r.flow_involvement_type_id
			   AND NOT EXISTS (
				SELECT 1
				  FROM flow_item_generated_alert figa
				 WHERE figa.app_sid = fii.app_sid
				   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = fii.user_sid
				)
		);

		--call specific module helpers to generate alert entries
		BEGIN
			--security_pkg.debugmsg('Running GenerateInvolmTypeAlertEntries for alert_class:' || v_flow_alert_class_helper_pkg || ' flow_involvement_type_id:' || r.flow_involvement_type_id);
			EXECUTE IMMEDIATE
					'BEGIN ' || v_flow_alert_class_helper_pkg || '.GenerateInvolmTypeAlertEntries(
						:in_flow_item_id,
						:in_set_by_user_sid,
						:in_flow_transition_alert_id,
						:in_flow_involvement_type_id,
						:in_flow_state_log_id,
						:in_subject_override,
						:in_body_override
					);END;'
				USING IN in_flow_item_id, in_set_by_user_sid, in_flow_transition_alert_id, r.flow_involvement_type_id, in_flow_state_log_id, in_subject_override, in_body_override;
			EXCEPTION
				WHEN PROC_NOT_FOUND THEN
					NULL;
		END;
	END LOOP;
END;

FUNCTION GetUsersForFlowTranAlert (
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE
)
RETURN security.security_pkg.T_SID_IDS
AS
	v_user_sids						security.security_pkg.T_SID_IDS;
BEGIN
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM flow_transition_alert_user
	 WHERE flow_transition_alert_id = in_flow_transition_alert_id;

	RETURN v_user_sids;
END;

FUNCTION GetRolesForFlowTranAlert (
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE
)
RETURN security.security_pkg.T_SID_IDS
AS
	v_role_sids						security.security_pkg.T_SID_IDS;
BEGIN
	SELECT role_sid
	  BULK COLLECT INTO v_role_sids
	  FROM flow_transition_alert_role
	 WHERE flow_transition_alert_id = in_flow_transition_alert_id
	   AND role_sid IS NOT NULL;

	RETURN v_role_sids;
END;

FUNCTION GetGroupsForFlowTranAlert(
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE
)
RETURN security.security_pkg.T_SID_IDS
AS
	v_group_sids					security.security_pkg.T_SID_IDS;
BEGIN
	SELECT group_sid
	  BULK COLLECT INTO v_group_sids
	  FROM flow_transition_alert_role
	 WHERE flow_transition_alert_id = in_flow_transition_alert_id
	   AND group_sid IS NOT NULL;

	RETURN v_group_sids;
END;

FUNCTION GetInvTypesForFlowTranAlert(
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE
)
RETURN security.security_pkg.T_SID_IDS
AS
	v_involvement_type_ids			security.security_pkg.T_SID_IDS;
BEGIN
	SELECT flow_involvement_type_id
	  BULK COLLECT INTO v_involvement_type_ids
	  FROM flow_transition_alert_inv
	 WHERE flow_transition_alert_id = in_flow_transition_alert_id;

	RETURN v_involvement_type_ids;
END;

PROCEDURE GetCCUsersForFlowTranAlert(
	in_flow_transition_alert_id		IN	flow_transition_alert.flow_transition_alert_id%TYPE,
	in_region_sid					IN	flow_transition_alert.flow_transition_alert_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Get users CC'd on this alert type given the region_sid (for region role member lookups)
	-- Other workflow types can have more than one region_sid, but currently this functionality is only used by workflow types that have one
	OPEN out_cur FOR
		SELECT cu.csr_user_sid user_sid, cu.full_name, cu.email
		  FROM csr_user cu
		 WHERE csr_user_sid IN (
			SELECT fu.user_sid
			  FROM flow_transition_alert_cc_user fu
			 WHERE fu.flow_transition_alert_id = in_flow_transition_alert_id
			 UNION
			SELECT rrm.user_sid
			  FROM region_role_member rrm
			  JOIN flow_transition_alert_cc_role fr ON rrm.role_sid = fr.role_sid
			 WHERE fr.flow_transition_alert_id = in_flow_transition_alert_id
			   AND rrm.region_sid = in_region_sid
			 UNION
			SELECT gm.member_sid_id
			  FROM security.group_members gm
			  JOIN flow_transition_alert_cc_role fg ON gm.group_sid_id = fg.group_sid
			 WHERE fg.flow_transition_alert_id = in_flow_transition_alert_id
		);
END;

PROCEDURE GenerateAlertEntries(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id			IN	flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id		IN flow_state_transition.flow_state_transition_id%TYPE
)
AS
	v_flow_alert_class_helper_pkg	flow_alert_class.helper_pkg%TYPE;
	v_region_sids_t					security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_send_alert					NUMBER;
	v_figa_to_be_deleted_sids_t		security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_user_sids						security.security_pkg.T_SID_IDS;
	v_role_sids						security.security_pkg.T_SID_IDS;
	v_group_sids					security.security_pkg.T_SID_IDS;
	v_involvement_type_ids			security.security_pkg.T_SID_IDS;
BEGIN
	--check the flow_alert_class and redirect the call to fill the region_sids
	v_flow_alert_class_helper_pkg := GetAlertClassHelperPkg(in_flow_item_id);

	IF v_flow_alert_class_helper_pkg IS NULL THEN
		RETURN;
	END IF;
	
	BEGIN
		EXECUTE IMMEDIATE
			'BEGIN :v_region_sids_t := ' || v_flow_alert_class_helper_pkg || '.GetFlowRegionSids(:in_flow_item_id);END;'
		USING OUT v_region_sids_t, IN in_flow_item_id;
	EXCEPTION
		WHEN PROC_NOT_FOUND THEN
			NULL;
	END;

	FOR r IN (
		SELECT fta.flow_transition_alert_id, fta.to_initiator
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		 WHERE fta.can_be_edited_before_sending = 0
		   AND fta.deleted = 0
		   AND fi.flow_item_id = in_flow_item_id
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
	)
	LOOP
		IF r.to_initiator = 1 THEN
			SELECT in_set_by_user_sid
			  BULK COLLECT INTO v_user_sids
			  FROM dual;

			v_role_sids.DELETE;
			v_group_sids.DELETE;
			v_involvement_type_ids.DELETE;
		ELSE
			v_user_sids := GetUsersForFlowTranAlert(r.flow_transition_alert_id);
			v_role_sids := GetRolesForFlowTranAlert(r.flow_transition_alert_id);
			v_group_sids := GetGroupsForFlowTranAlert(r.flow_transition_alert_id);
			v_involvement_type_ids := GetInvTypesForFlowTranAlert(r.flow_transition_alert_id);
		END IF;

		GenerateRecipientAlerts (
			in_flow_item_id					=>	in_flow_item_id,
			in_set_by_user_sid				=>	in_set_by_user_sid,
			in_flow_state_log_id			=>	in_flow_state_log_id,
			in_flow_transition_alert_id		=>	r.flow_transition_alert_id,
			in_user_sids					=>	v_user_sids,
			in_role_sids					=>	v_role_sids,
			in_group_sids					=>	v_group_sids,
			in_inv_type_ids					=>	v_involvement_type_ids);
	END LOOP;

	IF UPPER(v_flow_alert_class_helper_pkg) = 'CMS.TAB_PKG' THEN --no reason to call the SP for the other modules
		-- CMS user column.
		cms.tab_pkg.GenerateUserColumnAlerts(in_flow_item_id, in_set_by_user_sid, in_flow_state_log_id, in_flow_state_transition_id);
		-- CMS role column.
		cms.tab_pkg.GenerateRoleColumnAlerts(in_flow_item_id, in_set_by_user_sid, in_flow_state_log_id, in_flow_state_transition_id, v_region_sids_t);
		-- CMS company column.
		cms.tab_pkg.GenerateCompanyColumnAlerts(in_flow_item_id, in_set_by_user_sid, in_flow_state_log_id, in_flow_state_transition_id);
	END IF;

	--extra custom call outs
	BEGIN
		EXECUTE IMMEDIATE
			'BEGIN ' || v_flow_alert_class_helper_pkg || '.GenerateExtraFLowAlertEntries(
					:in_flow_item_id,
					:in_set_by_user_sid,
					:in_flow_state_transition_id,
					:in_flow_state_log_id
				);END;'
			USING IN in_flow_item_id, in_set_by_user_sid, in_flow_state_transition_id, in_flow_state_log_id;
	EXCEPTION
		WHEN PROC_NOT_FOUND THEN
			NULL;
	END;

	FOR r IN (
		SELECT flow_item_generated_alert_id, flow_item_id, set_by_user_sid, to_user_sid, to_initiator, helper_sp
		  FROM v$open_flow_item_gen_alert
		 WHERE app_sid = security_pkg.getApp
		   AND flow_state_log_Id = in_flow_state_log_id
		   AND flow_item_id = in_flow_item_id
		   AND helper_sp IS NOT NULL
	)
	LOOP
		v_send_alert := 1;
		BEGIN
			EXECUTE IMMEDIATE
			'BEGIN ' || r.helper_sp || '(
					:flow_item_generated_alert_id,
					:flow_item_id,
					:set_by_user_sid,
					:to_user_sid,
					:to_initiator,
					:send_alert
			);END;'
			USING IN r.flow_item_generated_alert_id, r.flow_item_id, r.set_by_user_sid, r.to_user_sid, r.to_initiator, OUT v_send_alert;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL;
		END;
		IF v_send_alert = 0 THEN
			v_figa_to_be_deleted_sids_t.extend;
			v_figa_to_be_deleted_sids_t(v_figa_to_be_deleted_sids_t.COUNT) := r.flow_item_generated_alert_id;
		END IF;
	END LOOP;

	IF v_figa_to_be_deleted_sids_t.count > 0 THEN
		DELETE FROM flow_item_generated_alert
		 WHERE flow_item_generated_alert_id IN (
			SELECT column_value
			  FROM TABLE(v_figa_to_be_deleted_sids_t)
		 );
	END IF;
END;

FUNCTION TryTransitionToNatureOrForce(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_to_nature					IN	flow_state_nature.flow_state_nature_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
RETURN flow_state.flow_state_id%TYPE
AS
	v_flow_state_id					flow_state.flow_state_id%TYPE;
BEGIN
	v_flow_state_id := SetItemStateNature(
		in_flow_item_id => 	in_flow_item_id,
		in_to_nature	=>	in_to_nature,
		in_comment		=>	in_comment,
		in_user_sid		=>	in_user_sid
	);
	
	IF v_flow_state_id IS NULL THEN
		v_flow_state_id := SetItemStateNature(
			in_flow_item_id => 	in_flow_item_id,
			in_to_nature	=>	in_to_nature,
			in_comment		=>	in_comment,
			in_user_sid		=>	in_user_sid,
			in_force		=>	1
		);
	END IF;
	
	RETURN v_flow_state_id;	
END;

PROCEDURE SetItemStateNature(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_to_nature					IN	flow_state_nature.flow_state_nature_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_force						IN	NUMBER	DEFAULT 0
)
AS
	v_state_id						flow_state.flow_state_id%TYPE;
BEGIN
	v_state_id := SetItemStateNature(
		in_flow_item_id				=> in_flow_item_id,
		in_to_nature				=> in_to_nature,
		in_comment					=> in_comment,
		in_user_sid					=> in_user_sid,
		in_force					=> in_force
	);
END;

FUNCTION SetItemStateNature(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_to_nature					IN	flow_state_nature.flow_state_nature_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_force						IN	NUMBER	DEFAULT 0
)
RETURN flow_state.flow_state_id%TYPE
AS
	v_flow_sid						flow_item.flow_sid%TYPE;
	v_current_state					flow_state.flow_state_id%TYPE;
	v_target_state					flow_state.flow_state_id%TYPE;
	v_cache_keys					security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	IF in_force = 0 THEN
		FOR r IN (
			SELECT fs.flow_state_id
			  FROM flow_item fi
			  JOIN flow_state_transition fst
			   ON fi.app_sid = fst.app_sid AND fst.from_state_id = fi.current_state_id
			  JOIN flow_state fs
			   ON fst.app_sid = fs.app_sid AND fst.to_state_id = fs.flow_state_id
			 WHERE fi.flow_item_id = in_flow_item_id
			   AND fs.flow_state_nature_id = in_to_nature
			 ORDER BY fs.pos, fs.label, fs.flow_state_id
		) LOOP
			BEGIN
				SetItemState(
					in_flow_item_id		=> in_flow_item_id,
					in_to_state_id		=> r.flow_state_id,
					in_comment_text		=> in_comment,
					in_user_sid			=> in_user_sid,
					in_force			=> in_force,
					in_cache_keys		=> v_cache_keys
				);

				RETURN r.flow_state_id;
			EXCEPTION
				-- Indicates the transition is invalid, try the next one
				WHEN csr_data_pkg.CONCURRENCY_CONFLICT THEN CONTINUE;
			END;
		END LOOP;
	ELSE
		SELECT flow_state_id
		  INTO v_target_state
		  FROM flow_state
		 WHERE is_deleted = 0
		   AND flow_state_nature_id = in_to_nature
		   AND ROWNUM = 1
		 ORDER BY POS, label, flow_state_id;

		SetItemState(
			in_flow_item_id		=> in_flow_item_id,
			in_to_state_id		=>  v_target_state,
			in_comment_text		=> in_comment,
			in_user_sid			=> in_user_sid,
			in_force			=> in_force,
			in_cache_keys		=> v_cache_keys
		);
	END IF;
	RETURN NULL;
END;

-- generic proc -- needs to check the roles table etc? i.e. provide implementation specific functions
-- which call this internal version?
PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID')
)
AS
	v_cache_keys	security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	SetItemState(in_flow_item_id, in_to_state_id, in_comment_text, v_cache_keys, in_user_Sid, 0);
END;

-- generic proc -- needs to check the roles table etc? i.e. provide implementation specific functions
-- which call this internal version?
PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force			IN	NUMBER	DEFAULT 0
)
AS
BEGIN
	SetItemState(in_flow_item_id, in_to_state_id, in_comment_text, in_cache_keys, in_user_sid, in_force, 0);
END;

-- generic proc -- needs to check the roles table etc? i.e. provide implementation specific functions
-- which call this internal version?
PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force			IN	NUMBER,
	in_cancel_alerts	IN	NUMBER
)
AS
	v_flow_state_log_id flow_state_log.flow_state_log_id%TYPE;
BEGIN
	SetItemState(
		in_flow_item_id			=> in_flow_item_id,
		in_to_state_Id			=> in_to_state_Id,
		in_comment_text			=> in_comment_text,
		in_cache_keys			=> in_cache_keys,
		in_user_sid				=> in_user_sid,
		in_force				=> in_force,
		in_cancel_alerts		=> in_cancel_alerts,
		out_flow_state_log_id	=> v_flow_state_log_id
	);
END;

PROCEDURE SetItemState(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id			IN	flow_state.flow_state_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_user_sid				IN	security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_force				IN	NUMBER,
	in_cancel_alerts		IN	NUMBER,
	out_flow_state_log_id	OUT flow_state_log.flow_state_log_id%TYPE
)
AS
	CURSOR c IS
		SELECT current_state_id, flow_sid
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id
		   FOR UPDATE;
	rfi	c%ROWTYPE;
	v_ask_for_comment			flow_state_transition.ask_for_comment%TYPE;
	v_helper_sp					flow_state_transition.helper_sp%TYPE;
	v_helper_pkg				flow_alert_class.helper_pkg%TYPE;
	v_lookup_key				flow_state_transition.lookup_key%TYPE;
	v_flow_state_transition_id	flow_state_transition.flow_state_transition_id%TYPE;
	v_flow_state_log_id			flow_state_log.flow_state_log_id%TYPE;
	v_sysdate					DATE := SYSDATE;
	v_flow_alert_class			flow.flow_alert_class%TYPE;
	v_tab_sid					security_pkg.T_SID_ID;
	v_owner_record_exists		NUMBER;
BEGIN
	-- lock it
	OPEN c;
	FETCH c INTO rfi;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Flow item id '||in_flow_item_id||' not found.');
	END IF;

	-- umm is it valid?
	BEGIN
		SELECT ask_for_comment, helper_sp, lookup_key, flow_state_transition_id
		  INTO v_ask_for_comment, v_helper_sp, v_lookup_key, v_flow_state_transition_id
		  FROM flow_state_transition
		 WHERE from_state_id = rfi.current_state_id
		   AND to_state_id = in_to_state_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_force = 0 THEN
				-- we use ERR_CONCURRENCY_CONFLICT because this is usually caused by two people editing the row at once,
				-- or a user editing the row while another edits the workflow. We can't use ERR_FLOW_STATE_CHANGE_FAILED
				-- because that's reserved for use by customer helper packages.
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CONCURRENCY_CONFLICT, 'Transition for item id '||in_flow_item_id||', from state id '||rfi.current_state_Id||' to state id '||in_to_state_id||' is invalid.');
			ELSE
				NULL;
			END IF;
	END;

	UPDATE flow_item
	   SET current_state_id = in_to_state_id,
	   	   last_flow_state_transition_id = v_flow_state_transition_id,
		   auto_failure_count = 0
	 WHERE flow_item_id = in_flow_item_id;

	v_flow_state_log_id := AddToLog(in_flow_item_id, in_comment_text, in_cache_keys, in_user_sid);
	out_flow_state_log_id := v_flow_state_log_id;

	IF in_cancel_alerts != 0 THEN
		-- mark any unprocessed alerts as not to be processed -- no point in notifying people
		-- if things have moved on.
		UPDATE flow_item_generated_alert
		   SET processed_dtm = v_sysdate
		 WHERE app_sid =security_pkg.getApp
		   AND processed_dtm IS NULL
		   AND flow_item_Id = in_flow_item_id;
	END IF;

	SELECT f.flow_alert_class, t.tab_sid, fac.helper_pkg
	  INTO v_flow_alert_class, v_tab_sid, v_helper_pkg
	  FROM flow f
	  JOIN flow_alert_class fac ON fac.flow_alert_class = f.flow_alert_class
	  LEFT JOIN cms.tab t ON f.app_sid = t.app_sid AND f.flow_sid = t.flow_sid
	 WHERE f.flow_sid = rfi.flow_sid;

	-- insert any new alerts
	IF in_force = 0 THEN
		BEGIN	
			EXECUTE IMMEDIATE
				'BEGIN :v_record_exists := ' || v_helper_pkg || '.FlowItemRecordExists(:flow_item_id);END;'
			 	USING OUT v_owner_record_exists, IN in_flow_item_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				v_owner_record_exists := 1;
		END;

		IF v_owner_record_exists = 1 THEN
			GenerateAlertEntries(
				in_flow_item_id			=> in_flow_item_id,
				in_set_by_user_sid		=> in_user_sid,
				in_flow_state_log_id	=> v_flow_state_log_id,
				in_flow_state_transition_id => v_flow_state_transition_id
			);
		END IF;
	END IF;

	-- fire sp?
	--should we run the transition helper when we force the state?
	IF in_force = 0 AND v_helper_sp IS NOT NULL AND v_owner_record_exists = 1 THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_sp||'(:1,:2,:3,:4,:5,:6,:7);end;'
			USING rfi.flow_sid, in_flow_item_id, rfi.current_state_id, in_to_state_id, v_lookup_key, in_comment_text, in_user_sid;
	END IF;

	-- trigger aggregates?
	FOR r IN (SELECT aggregate_ind_group_id FROM flow WHERE flow_sid = rfi.flow_sid AND aggregate_ind_group_id IS NOT NULL) LOOP
		aggregate_ind_pkg.RefreshGroup(r.aggregate_ind_group_id, TRUNC(v_sysdate,'MONTH'), ADD_MONTHS(TRUNC(v_sysdate,'MONTH'), 1));
	END LOOP;

	IF v_flow_alert_class = 'audit' THEN
		chain.filter_pkg.ClearCacheForAllUsers (
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
		);

		chain.filter_pkg.ClearCacheForAllUsers (
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
		);
	ELSIF v_flow_alert_class = 'cms' AND v_tab_sid IS NOT NULL AND cms.filter_pkg.INTERNAL_GetPrimaryIdColSid(v_tab_sid) IS NOT NULL THEN
		chain.filter_pkg.ClearCacheForAllUsers (
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_CMS,
			in_cms_col_sid => cms.filter_pkg.INTERNAL_GetPrimaryIdColSid(v_tab_sid)
		);
	END IF;

END;

PROCEDURE AutonomouslyIncreaseFailureCnt(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
		 
	UPDATE flow_item
	   SET auto_failure_count = auto_failure_count + 1
	 WHERE flow_item_id = in_flow_item_id;
	
	COMMIT;
END;

PROCEDURE GetChangeLog(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR,
	out_files			OUT	SYS_REFCURSOR
)
AS
	v_now_dtm	DATE;
	v_flow_sid	security_pkg.T_SID_ID;
BEGIN
	v_now_dtm := SYSDATE;

	SELECT flow_Sid
	  INTO v_flow_sid
	  FROM flow_Item
	 WHERE flow_item_id = in_flow_item_id;

	-- check permission on the workflow - bit lame
	-- TODO: how do we secure this stuff better?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;

	OPEN out_cur FOR
		SELECT fsl.flow_state_log_id, fsl.flow_state_Id,
			   cu.csr_user_sid set_by_user_sid, cu.full_name set_by_full_name,
			   fs.flow_state_id set_to_state_id, fs.label set_to_state_label,
			   set_dtm, comment_text, v_now_dtm now_dtm, fsl.flow_item_id
		  FROM flow_state_log fsl
		  JOIN csr_user cu ON fsl.set_by_user_sid = cu.csr_user_sid
		  JOIN flow_state fs ON fsl.flow_state_Id = fs.flow_state_id
		 WHERE flow_item_id = in_flow_item_id
		 ORDER BY fsl.flow_state_log_id DESC;

	OPEN out_files FOR
		SELECT fslf.flow_state_log_id, fslf.flow_state_log_file_id, fslf.filename, fslf.mime_type, cast(fslf.sha1 as varchar2(40)) sha1, fslf.uploaded_dtm
		  FROM flow_state_log fsl
		  JOIN flow_state_log_file fslf ON fsl.flow_state_log_id = fslf.flow_state_log_id
		 WHERE fsl.flow_item_id = in_flow_item_id
		 ORDER BY fsl.flow_state_log_id DESC, fslf.filename; -- sort order must match the first cursor (C# relies on it)

END;

PROCEDURE GetLastChangeLog_UNSEC(
	in_flow_item_ids		IN	security.security_pkg.T_SID_IDS,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_flow_item_ids	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_flow_item_ids);
BEGIN
	OPEN out_cur FOR
		SELECT p.flow_state_log_id, p.flow_item_id,
			   p.set_by_user_sid, cu.full_name set_by_full_name,
			   p.set_to_state_label, p.set_to_state_id,
			   p.set_dtm 
		  FROM (
			SELECT ROW_NUMBER() OVER (PARTITION BY fsl.flow_item_id ORDER BY fsl.flow_state_log_id DESC) rn,
				 fsl.flow_state_log_id, fsl.set_by_user_sid, fsl.flow_state_id set_to_state_id,
				 fs.label set_to_state_label, fsl.set_dtm, fsl.flow_item_id
			  FROM flow_state_log fsl
			  JOIN TABLE(v_flow_item_ids) t ON t.column_value = fsl.flow_item_id
			  JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id
			 WHERE (in_flow_state_nature_id IS NULL OR fs.flow_state_nature_id = in_flow_state_nature_id) -- when passed as null, we collect logs regardless the nature, not just the empty ones 
		  ) p
		  JOIN csr_user cu ON p.set_by_user_sid = cu.csr_user_sid
		 WHERE p.rn = 1;
END;

PROCEDURE GetFlowItemsBasicInfo_UNSEC(
	in_flow_item_ids		IN	security.security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_flow_item_ids	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_flow_item_ids);
BEGIN
	OPEN out_cur FOR
		SELECT fi.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.state_colour current_state_colour
		  FROM flow_item fi
		  JOIN TABLE(v_flow_item_ids) t ON t.column_value = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id;
END;

-- pass the current state and a lookup key and it returns the next state
FUNCTION GetToStateIdFromLookupKey(
	in_from_state_id	IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY
) RETURN csr_data_pkg.T_FLOW_STATE_ID
AS
	v_new_state_id		csr_data_pkg.T_FLOW_STATE_ID;
BEGIN
	SELECT MIN(to_state_Id) -- min() to avoid NO_DATA_FOUND -- i.e. null just means nothing found.
	  INTO v_new_state_id
	  FROM flow_state_transition
	 WHERE from_state_id = in_from_state_id
	   AND lookup_key = in_lookup_key;

	RETURN v_new_state_id; -- null means nothing found
END;

FUNCTION GetStateLookupKey(
	in_state_id	IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN csr_data_pkg.T_LOOKUP_KEY
AS
	v_key				csr_data_pkg.T_LOOKUP_KEY;
BEGIN
	-- no security but it's hardly leaking anything of value
	SELECT MIN(lookup_key) -- min() to avoid NO_DATA_FOUND -- i.e. null just means nothing found.
	  INTO v_key
	  FROM flow_state
	 WHERE flow_state_id = in_state_id;

	RETURN v_key; -- null means nothing found
END;

FUNCTION GetCurrentStateLookupKey(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN csr_data_pkg.T_LOOKUP_KEY
AS
	v_current_state_lookup_key	csr_data_pkg.T_LOOKUP_KEY;
BEGIN
	-- no security but it's hardly leaking anything of value
	SELECT MIN(fs.lookup_key)  -- min() to avoid NO_DATA_FOUND -- i.e. null just means nothing found.
	  INTO v_current_state_lookup_key
	  FROM csr.flow_item fi
	  JOIN csr.flow_state fs
	    ON fi.current_state_id = fs.flow_state_id
	 WHERE fi.flow_item_id = in_flow_item_id;

	 RETURN v_current_state_lookup_key; -- null means nothing found
END;


FUNCTION SQL_HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	IF HasRoleMembersForRegion(in_flow_state_id, in_region_sid) THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

FUNCTION SQL_HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sids      IN  security_pkg.T_SID_IDS
) RETURN NUMBER
AS
BEGIN
	IF HasRoleMembersForRegions(in_flow_state_id, in_region_sids) THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

-- will anyone be able to see thing in this state, for the given region?
FUNCTION HasRoleMembersForRegions(
    in_flow_state_id	IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sids		IN  security.security_pkg.T_SID_IDS,
    in_role_sid			IN  role.role_sid%TYPE
) RETURN BOOLEAN;

FUNCTION HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID,
    in_role_sid			IN  role.role_sid%TYPE := NULL
) RETURN BOOLEAN
AS
	v_region_sids					security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;

	RETURN HasRoleMembersForRegions(in_flow_state_id, v_region_sids, in_role_sid);
END;

FUNCTION HasRoleMembersForRegions(
    in_flow_state_id    			IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sids       			IN  security_pkg.T_SID_IDS
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasRoleMembersForRegions(in_flow_state_id, in_region_sids, NULL);
END;

FUNCTION HasRoleMembersForRegions(
    in_flow_state_id	IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sids		IN  security.security_pkg.T_SID_IDS,
    in_role_sid			IN  role.role_sid%TYPE
) RETURN BOOLEAN
AS
    v_cnt   						NUMBER(10);
	v_regions_table					security.T_SID_TABLE;
BEGIN
	v_regions_table	:= security_pkg.SidArrayToTable(in_region_sids);

    SELECT COUNT(*)
      INTO v_cnt
      FROM flow_state_transition_role fsr
      JOIN region_role_member rrm ON rrm.role_sid = fsr.role_sid AND rrm.app_sid = fsr.app_sid
	  JOIN v$active_user cu ON rrm.user_sid = cu.csr_user_sid -- make sure it's active users only
      JOIN TABLE(v_regions_table) rs ON rrm.region_sid = rs.column_value
	 WHERE fsr.from_state_id = in_flow_state_id
	   AND fsr.role_sid IS NOT NULL
	   AND (in_role_sid IS NULL OR fsr.role_sid = in_role_sid);

	RETURN v_cnt > 0;
END;
-- this seems an odd place for this
PROCEDURE GetRolesForRegions(
	in_region_sids		IN  security_pkg.T_SID_IDS,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_regions_table					security.T_SID_TABLE;
BEGIN
	v_regions_table	:= security_pkg.SidArrayToTable(in_region_sids);

	OPEN out_cur FOR
		SELECT DISTINCT r.lookup_key
		  FROM TABLE (v_regions_table) rs
		  JOIN region_role_member rrm ON rs.column_value = rrm.region_sid
		  JOIN role r ON rrm.role_sid = r.role_sid
		 WHERE r.lookup_key IS NOT NULL
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

-- this seems an odd place for this - but following pattern of GetRolesForRegions
PROCEDURE GetRolesForCompanies(
	in_company_sids		IN  security_pkg.T_SID_IDS,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_regions_sids					security_pkg.T_SID_IDS;
	v_regions_table					security.T_SID_TABLE;
BEGIN
	v_regions_sids := supplier_pkg.GetRegSidsFromCompSids(in_company_sids);
	GetRolesForRegions(v_regions_sids, out_cur);
END;

-- DEPRECATED
FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER
AS
	v_is_editable		NUMBER;
BEGIN
	SELECT NVL(MAX(fsr.is_editable), -1)
	  INTO v_is_editable
	  FROM flow_item fi
	  JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id
	  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = fi.survey_response_id
	  LEFT JOIN approval_dashboard_instance adi ON fi.dashboard_instance_id = adi.dashboard_instance_id
	  JOIN region_role_member rrm ON NVL(rsr.region_sid, adi.region_sid) = rrm.region_sid AND rrm.role_sid = fsr.role_sid
	 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND fsr.role_sid IS NOT NULL
	   AND fi.flow_item_id = in_flow_item_id;

	RETURN v_is_editable;
END;

-- more generic version but needs region_sid
FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_region_sids		security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;

	RETURN GetFlowItemIsEditable(in_flow_item_id, v_region_sids);
END;

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_regions_table	IN	security.T_SID_TABLE
) RETURN NUMBER
AS
	v_is_editable		NUMBER;
BEGIN

	SELECT NVL(MAX(fsr.is_editable), 0)
	  INTO v_is_editable
	  FROM flow_item fi
	  JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id
	  LEFT JOIN region_role_member rrm
	    ON rrm.role_sid = fsr.role_sid
	   AND rrm.region_sid IN (SELECT column_value FROM TABLE(in_regions_table))
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	  LEFT JOIN security.act act ON fsr.group_sid = act.sid_id
	   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND (
	        (fsr.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL) OR
	        (fsr.group_sid IS NOT NULL AND act.act_id IS NOT NULL )
	    );

	RETURN v_is_editable;

END;

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_region_sids		IN	security.security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	v_regions_table		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN

	RETURN GetFlowItemIsEditable(in_flow_item_id, v_regions_table);

END;

PROCEDURE GetItemCapabilityPermissions (
	in_flow_item_id		IN  flow_item.flow_item_id%TYPE,
	in_region_sids		security.T_SID_TABLE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN

	-- Could use bitoragg for permission set, but the only possible values in the UI
	-- currently are either off/on or none/read/read+write, no no need for bitwise aggregate
	OPEN out_cur FOR
		SELECT fsrc.flow_capability_id, MIN(fc.description) description, MAX(fsrc.permission_set) permission_set
			FROM flow_item fi
			JOIN flow_state_role_capability fsrc ON fi.current_state_id = fsrc.flow_state_id
			JOIN flow_capability fc ON fsrc.flow_capability_id = fc.flow_capability_id
			LEFT JOIN region_role_member rrm
			ON rrm.role_sid = fsrc.role_sid
			AND rrm.region_sid IN (SELECT DISTINCT column_value FROM TABLE(in_region_sids))
			AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
			AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		 WHERE fi.flow_item_id = in_flow_item_id
			AND (
				(fsrc.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL) OR
				(fsrc.group_sid IS NOT NULL AND act.act_id IS NOT NULL ))
		 GROUP BY fsrc.flow_capability_id;
END;

PROCEDURE GetStateCapabilityPermissions (
	in_state_id			IN	flow_state.flow_state_id%TYPE,
	in_region_sids		security.T_SID_TABLE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT fsrc.flow_capability_id, MIN(fc.description) description, MAX(fsrc.permission_set) permission_set
		  FROM flow_state_role_capability fsrc
		  JOIN flow_capability fc ON fsrc.flow_capability_id = fc.flow_capability_id
		  LEFT JOIN region_role_member rrm ON rrm.role_sid = fsrc.role_sid
		   AND rrm.region_sid IN (SELECT DISTINCT column_value FROM TABLE(in_region_sids))
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
		   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		 WHERE fsrc.flow_state_id = in_state_id
		   AND ((fsrc.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL) OR
			   (fsrc.group_sid IS NOT NULL AND act.act_id IS NOT NULL ))
		 GROUP BY fsrc.flow_capability_id;
END;

PROCEDURE GetFlowItemStatePermissions(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_region_sids_t				security.T_SID_TABLE;
	v_flow_sid					security_pkg.T_SID_ID;
BEGIN
	v_region_sids_t := GetFlowRegionSids(in_flow_item_id);

	IF v_region_sids_t IS NULL THEN 
		RAISE_APPLICATION_ERROR(-20001, 'GetFlowRegionSids returned NULL for flow_item_id: '||in_flow_item_id);
	END IF;

	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;

	-- check permission on the workflow - bit lame
	-- TODO: how do we secure this stuff better?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;

	GetStateCapabilityPermissions(in_state_id, v_region_sids_t, out_cur);
END;

FUNCTION INTERNAL_GetItemCapPerms (
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE,
	in_region_sid		IN  region.region_sid%TYPE DEFAULT NULL
) RETURN T_FLOW_ITEM_PERM_TABLE
AS
	v_flow_item_perm_table			T_FLOW_ITEM_PERM_TABLE;
BEGIN
	SELECT T_FLOW_ITEM_PERM_ROW(fi.flow_item_id, MAX(fsrc.permission_set))
	  BULK COLLECT INTO v_flow_item_perm_table
	  FROM flow_item fi
	  JOIN flow_item_region fir on fir.flow_item_id = fi.flow_item_id
	  JOIN flow_state_role_capability fsrc ON fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN region_role_member rrm
		ON rrm.role_sid = fsrc.role_sid
	   AND rrm.region_sid = fir.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	  LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
	   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
	 WHERE fsrc.flow_capability_id = in_capability_id
	   AND (rrm.role_sid IS NOT NULL OR act.act_id IS NOT NULL)
	   AND (in_region_sid IS NULL OR fir.region_sid = in_region_sid)
	 GROUP BY fi.flow_item_id;

	RETURN v_flow_item_perm_table;
END;

FUNCTION GetPermissibleRegionItems(
	in_capability_id				IN	flow_capability.flow_capability_id%TYPE,
	in_region_sid					IN  region.region_sid%TYPE
) RETURN security.T_SID_TABLE
AS
	v_flow_item_perm_table			T_FLOW_ITEM_PERM_TABLE;
	v_flow_item_ids					security.T_SID_TABLE;
BEGIN
	v_flow_item_perm_table :=
		INTERNAL_GetItemCapPerms(
			in_capability_id			=>	in_capability_id,
			in_region_sid				=>	in_region_sid
		);
	
	SELECT flow_item_id
	  BULK COLLECT INTO v_flow_item_ids
	  FROM TABLE(v_flow_item_perm_table)
	 WHERE permission_set > 0;
	
	RETURN v_flow_item_ids;
END;

PROCEDURE GetItemCapabilityPermissions (
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_flow_item_perm_table			T_FLOW_ITEM_PERM_TABLE;
BEGIN
	-- No security check as it only returns data permissable by logged in user
	v_flow_item_perm_table := 
		INTERNAL_GetItemCapPerms(
			in_capability_id			=>	in_capability_id,
			in_region_sid				=>	NULL
		);
	
	OPEN out_cur FOR
		SELECT flow_item_id, permission_set
		  FROM TABLE(v_flow_item_perm_table);
END;

-- To be removed
-- Previous version wasn't using the passed in list of flow item IDs correctly and wouldn't scale.
-- Leaving this for backwards compability as called from api.core (which will soon be retired)
PROCEDURE GetItemCapabilityPermissions (
	in_flow_item_ids	IN  security.security_pkg.T_SID_IDS,
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_flow_item_perm_table			T_FLOW_ITEM_PERM_TABLE;
BEGIN
	v_flow_item_perm_table := 
		INTERNAL_GetItemCapPerms(
			in_capability_id			=>	in_capability_id,
			in_region_sid				=>	NULL
		);

	OPEN out_cur FOR
		SELECT flow_item_id, permission_set
		  FROM TABLE(v_flow_item_perm_table);
END;

FUNCTION GetItemCapabilityPermission (
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE
) RETURN security_pkg.T_PERMISSION
AS
	v_permission_set	security_pkg.T_PERMISSION DEFAULT 0;
BEGIN
	FOR r IN (
		SELECT fsrc.permission_set
		  FROM flow_item fi
		  JOIN flow_item_region fir on fir.flow_item_id = fi.flow_item_id
		  JOIN flow_state_role_capability fsrc ON fi.current_state_id = fsrc.flow_state_id
		  LEFT JOIN region_role_member rrm
			ON rrm.role_sid = fsrc.role_sid
		   AND rrm.region_sid = fir.region_sid
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
		   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND fsrc.flow_capability_id = in_capability_id
		   AND (
				(fsrc.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL) OR
				(fsrc.group_sid IS NOT NULL AND act.act_id IS NOT NULL )
			)
	) LOOP
		v_permission_set := security.bitwise_pkg.bitor(v_permission_set, r.permission_set);
	END LOOP;
	
	RETURN v_permission_set;
END;

PROCEDURE GetAlertTemplates(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	out_alert_type_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_body_cur			OUT	SYS_REFCURSOR,
	out_alert_helper_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the flow with SID '||in_flow_sid);
	END IF;

	OPEN out_alert_type_cur FOR
		SELECT fat.customer_alert_type_id, fat.label description, fat.lookup_key
		  FROM flow_alert_type fat
		 WHERE fat.flow_sid = in_flow_sid
		   AND fat.deleted = 0;

	OPEN out_alert_tpl_cur FOR
		SELECT at.customer_alert_type_id, at.alert_frame_id, at.send_type, at.reply_to_name, at.reply_to_email
		  FROM flow_alert_type fat, alert_template at
		 WHERE fat.customer_alert_type_id = at.customer_alert_type_id
		   AND fat.flow_sid = in_flow_sid
		   AND fat.deleted = 0;

	OPEN out_alert_tpl_body_cur FOR
		SELECT fat.customer_alert_type_id, atb.lang, atb.subject, atb.body_html, atb.item_html
		  FROM flow_alert_type fat, alert_template_body atb
		 WHERE fat.customer_alert_type_id = atb.customer_alert_type_id
		   AND fat.flow_sid = in_flow_sid
		   AND fat.deleted = 0;

	OPEN out_alert_helper_cur FOR
		SELECT fah.flow_alert_helper helper_sp, fah.label description
		  FROM flow_alert_helper fah;
END;

PROCEDURE GetEditableFlowAlerts(
	in_flow_state_transition_id IN  flow_state_transition.flow_state_transition_id%TYPE,
	in_lang						IN  alert_template_body.lang%TYPE,
	out_alerts_cur 				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_alerts_cur FOR
		SELECT fta.customer_alert_type_id, fta.flow_transition_alert_id, fta.description label, atb.body_html, atb.subject, atb.item_html, 1 allow_manual_editing, fst.flow_sid
		  FROM csr.flow_transition_alert fta
		  JOIN csr.alert_template_body atb ON fta.customer_alert_type_id = atb.customer_alert_type_id
		  JOIN csr.flow_state_transition fst ON fst.flow_state_transition_id = fta.flow_state_transition_id
		 WHERE fta.flow_state_transition_id = in_flow_state_transition_id
		   AND fta.deleted = 0
		   AND fta.can_be_edited_before_sending = 1
		   AND atb.lang = in_lang;
END;

PROCEDURE GetEditableAlertsRecipients(
	in_flow_item_id				IN 	csr.flow_item.flow_item_id%TYPE,
	in_flow_state_transition_id IN  flow_state_transition.flow_state_transition_id%TYPE,
	out_user_cur 				OUT SYS_REFCURSOR,
	out_roles_cur 				OUT SYS_REFCURSOR,
	out_groups_cur 				OUT SYS_REFCURSOR,
	out_involm_type_cur			OUT SYS_REFCURSOR
)
AS
	v_temp_user_t 		security.T_ORDERED_SID_TABLE;
	v_user_sids 		security.T_SID_TABLE;
	v_user_t 			security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();

	v_temp_role_t 		security.T_ORDERED_SID_TABLE;
	v_role_sids 		security.T_SID_TABLE;
	v_role_t	 		security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();

	v_temp_group_t		security.T_ORDERED_SID_TABLE;
	v_group_sids  		security.T_SID_TABLE;
	v_group_t			security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();

	v_temp_involvement_type_t	security.T_ORDERED_SID_TABLE;
	v_involvement_type_ids	security.T_SID_TABLE;
	v_involvement_type_t	security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN

	FOR r IN (
		SELECT fta.flow_transition_alert_id, fta.to_initiator
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		 WHERE fta.can_be_edited_before_sending = 1
		   AND fta.deleted = 0
		   AND fi.flow_item_id = in_flow_item_id
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
	)
	LOOP
		IF r.to_initiator = 1 THEN
			SELECT security.T_ORDERED_SID_ROW(SYS_CONTEXT('SECURITY', 'SID'), r.flow_transition_alert_id)
			  BULK COLLECT INTO v_temp_user_t
			  FROM dual;

			v_user_t := v_user_t MULTISET UNION v_temp_user_t;

		ELSE
			--users
			v_user_sids := security_pkg.SidArrayToTable(GetUsersForFlowTranAlert(r.flow_transition_alert_id));

			SELECT security.T_ORDERED_SID_ROW(t.column_value, r.flow_transition_alert_id)
			  BULK COLLECT INTO v_temp_user_t
			  FROM TABLE(v_user_sids) t;

			v_user_t := v_user_t MULTISET UNION v_temp_user_t;

			--roles
			v_role_sids := security_pkg.SidArrayToTable(GetRolesForFlowTranAlert(r.flow_transition_alert_id));

			SELECT security.T_ORDERED_SID_ROW(t.column_value, r.flow_transition_alert_id)
			  BULK COLLECT INTO v_temp_role_t
			  FROM TABLE(v_role_sids) t;

			v_role_t := v_role_t MULTISET UNION v_temp_role_t;

			--groups
			v_group_sids := security_pkg.SidArrayToTable(GetGroupsForFlowTranAlert(r.flow_transition_alert_id));

			SELECT security.T_ORDERED_SID_ROW(t.column_value, r.flow_transition_alert_id)
			  BULK COLLECT INTO v_temp_group_t
			  FROM TABLE(v_group_sids) t;

			v_group_t := v_group_t MULTISET UNION v_temp_group_t;

			--involment type
			v_involvement_type_ids := security_pkg.SidArrayToTable(GetInvTypesForFlowTranAlert(r.flow_transition_alert_id));

			SELECT security.T_ORDERED_SID_ROW(t.column_value, r.flow_transition_alert_id)
			  BULK COLLECT INTO v_temp_involvement_type_t
			  FROM TABLE(v_involvement_type_ids) t;

			v_involvement_type_t := v_involvement_type_t MULTISET UNION v_temp_involvement_type_t;
		END IF;
	END LOOP;

	OPEN out_user_cur FOR
		SELECT cu.csr_user_sid user_sid, cu.full_name name, t.POS flow_transition_alert_id
		  FROM csr_user cu
		  JOIN (SELECT SID_ID, POS FROM TABLE(v_user_t) ORDER BY SID_ID) t ON t.SID_ID = cu.csr_user_sid;

	OPEN out_roles_cur FOR
		SELECT r.role_sid, r.name, t.POS flow_transition_alert_id
		  FROM role r
		  JOIN TABLE(v_role_t) t ON t.SID_ID = r.role_sid;

	OPEN out_groups_cur FOR
		SELECT so.sid_id group_sid, so.name, t.POS flow_transition_alert_id
		  FROM security.securable_object so
		  JOIN TABLE(v_group_t) t ON t.SID_ID = so.sid_id;

	OPEN out_involm_type_cur FOR
		SELECT fit.flow_involvement_type_id involvement_type_id, fit.label name, t.POS flow_transition_alert_id
		  FROM flow_involvement_type fit
		  JOIN TABLE(v_involvement_type_t) t ON t.SID_ID = fit.flow_involvement_type_id;
END;

PROCEDURE GetCmsAlertTemplates(
	out_cms_alert_type_cur			OUT	SYS_REFCURSOR,
	out_alert_tpl_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_body_cur			OUT	SYS_REFCURSOR,
	out_alert_helper_cur			OUT	SYS_REFCURSOR
)
AS
	v_cms_sid	security_pkg.T_SID_ID;
BEGIN
	-- Get the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.SO_CONTAINER, 'cms', v_cms_sid);
	END;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the schema with SID '||v_cms_sid);
	END IF;

	OPEN out_cms_alert_type_cur FOR
		SELECT cat.tab_sid, cat.customer_alert_type_id, cat.description, cat.lookup_key
		  FROM cms_alert_type cat,
		  	   TABLE (SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ)) c
		 WHERE c.sid_id = cat.tab_sid
		   AND cat.deleted = 0;

	OPEN out_alert_tpl_cur FOR
		SELECT at.customer_alert_type_id, at.alert_frame_id, at.send_type, at.reply_to_name, at.reply_to_email, cat.is_batched
		  FROM cms_alert_type cat, alert_template at,
		  	   TABLE (SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ)) c
		 WHERE cat.customer_alert_type_id = at.customer_alert_type_id
		   AND c.sid_id = cat.tab_sid
		   AND cat.deleted = 0;

	OPEN out_alert_tpl_body_cur FOR
		SELECT cat.customer_alert_type_id, cat.tab_sid, atb.lang, atb.subject, atb.body_html, atb.item_html
		  FROM cms_alert_type cat, alert_template_body atb,
		  	   TABLE (SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ)) c
		 WHERE cat.customer_alert_type_id = atb.customer_alert_type_id
		   AND c.sid_id = cat.tab_sid
		   AND cat.deleted = 0;

	OPEN out_alert_helper_cur FOR
		SELECT cah.tab_sid, cah.helper_sp, cah.description
		  FROM cms_alert_helper cah,
		  	   TABLE (SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ)) c
		 WHERE cah.tab_sid = c.sid_id;
END;


PROCEDURE SaveFlowAlertTemplate(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id		IN	flow_alert_type.customer_alert_type_id%TYPE,
	in_description					IN	flow_alert_type.label%TYPE,
	in_lookup_key					IN	flow_alert_type.lookup_key%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_deleted						IN	flow_alert_type.deleted%TYPE,
	out_customer_alert_type_id		OUT flow_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	out_customer_alert_type_id := in_customer_alert_type_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the flow with sid '||in_flow_sid);
	END IF;

	IF in_customer_alert_type_id IS NULL AND in_lookup_key IS NOT NULL THEN
		BEGIN
			SELECT customer_alert_type_id
			  INTO out_customer_alert_type_id
			  FROM flow_alert_type
			 WHERE flow_sid = in_flow_sid
			   AND lookup_key = in_lookup_key;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- create as normal
		END;
	END IF;

	IF out_customer_alert_type_id IS NULL OR out_customer_alert_type_id < 0 THEN
		INSERT INTO customer_alert_type (customer_alert_type_id)
			VALUES (customer_alert_type_id_seq.NEXTVAL)
				RETURNING customer_alert_type_id INTO out_customer_alert_type_id;

		INSERT INTO flow_alert_type (flow_sid, customer_alert_type_id, label, lookup_key)
			VALUES (in_flow_sid, out_customer_alert_type_id, in_description, in_lookup_key);

		INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
			VALUES (out_customer_alert_type_id, in_alert_frame_id, in_send_type, in_reply_to_name, in_reply_to_email);
	ELSE
		UPDATE flow_alert_type
		   SET label = in_description,
			   lookup_key = in_lookup_key,
			   deleted = in_deleted
		 WHERE customer_alert_type_id = out_customer_alert_type_id
		   AND flow_sid = in_flow_sid;

		IF SQL%ROWCOUNT != 1 THEN
			-- ensure the alert is actually associated with the table
			RAISE_APPLICATION_ERROR(-20001, 'Missing cms_alert_template row with customer_alert_type_id='||in_customer_alert_type_id);
		END IF;

		UPDATE alert_template
		   SET alert_frame_id = in_alert_frame_id,
		       send_type = in_send_type,
		       reply_to_name = in_reply_to_name,
		       reply_to_email = in_reply_to_email
		 WHERE customer_alert_type_id = out_customer_alert_type_id;
	END IF;
END;


PROCEDURE SaveCmsAlertTemplate(
	in_tab_sid						IN	cms_alert_type.tab_sid%TYPE,
	in_customer_alert_type_id		IN	cms_alert_type.customer_alert_type_id%TYPE,
	in_description					IN	cms_alert_type.description%TYPE,
	in_lookup_key					IN	cms_alert_type.lookup_key%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	out_customer_alert_type_id		OUT cms_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	SaveCmsAlertTemplate(in_tab_sid, in_customer_alert_type_id, in_description, in_lookup_key, in_alert_frame_id, in_send_type, in_reply_to_name, in_reply_to_email, 0, 0, out_customer_alert_type_id);
END;

PROCEDURE SaveCmsAlertTemplate(
	in_tab_sid						IN	cms_alert_type.tab_sid%TYPE,
	in_customer_alert_type_id		IN	cms_alert_type.customer_alert_type_id%TYPE,
	in_description					IN	cms_alert_type.description%TYPE,
	in_lookup_key					IN	cms_alert_type.lookup_key%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_deleted						IN	cms_alert_type.deleted%TYPE,
	in_is_batched					IN	cms_alert_type.is_batched%TYPE DEFAULT 0,
	out_customer_alert_type_id		OUT cms_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	out_customer_alert_type_id := in_customer_alert_type_id;

	-- XXX: needs to be some stronger check than this, but on what?  (this lets people who can write to the table change
	-- alerts)
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the table with sid '||in_tab_sid);
	END IF;

	IF in_customer_alert_type_id IS NULL AND in_lookup_key IS NOT NULL THEN
		BEGIN
			SELECT customer_alert_type_id
			  INTO out_customer_alert_type_id
			  FROM cms_alert_type
			 WHERE lookup_key = in_lookup_key;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- create as normal
		END;
	END IF;

	IF out_customer_alert_type_id IS NULL OR out_customer_alert_type_id < 0 THEN
		INSERT INTO customer_alert_type
			(customer_alert_type_id)
		VALUES
			(customer_alert_type_id_seq.NEXTVAL)
		RETURNING
			customer_alert_type_id INTO out_customer_alert_type_id;

		INSERT INTO cms_alert_type
			(tab_sid, customer_alert_type_id, description, lookup_key, is_batched)
		VALUES
			(in_tab_sid, customer_alert_type_id_seq.CURRVAL, in_description, in_lookup_key, in_is_batched);

		INSERT INTO alert_template
			(customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
		VALUES
			(customer_alert_type_id_seq.CURRVAL, in_alert_frame_id, in_send_type, in_reply_to_name, in_reply_to_email);
	ELSE
		UPDATE cms_alert_type
		   SET description = in_description,
			   lookup_key = in_lookup_key,
			   deleted = in_deleted,
			   is_batched = in_is_batched
		 WHERE customer_alert_type_id = out_customer_alert_type_id
		   AND tab_sid = in_tab_sid;
		IF SQL%ROWCOUNT != 1 THEN
			-- ensure the alert is actually associated with the table
			RAISE_APPLICATION_ERROR(-20001, 'Missing cms_alert_template row with customer_alert_type_id='||in_customer_alert_type_id);
		END IF;

		UPDATE alert_template
		   SET alert_frame_id = in_alert_frame_id,
		       send_type = in_send_type,
		       reply_to_name = in_reply_to_name,
		       reply_to_email = in_reply_to_email
		 WHERE customer_alert_type_id = out_customer_alert_type_id;
	END IF;

END;

PROCEDURE SaveCmsAlertTemplateBody(
	in_customer_alert_type_id		IN	alert_template_body.customer_alert_type_id%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE
)
AS
BEGIN
	SaveFlowAlertTemplateBody(in_customer_alert_type_id, in_lang, in_subject, in_body_html, in_item_html);
END;

PROCEDURE SaveFlowAlertTemplateBody(
	in_customer_alert_type_id		IN	alert_template_body.customer_alert_type_id%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE
)
AS
BEGIN
	-- No security: always preceded by a call to SaveCmsAlertTemplate and in the same transaction
	IF in_subject IS NULL AND in_body_html IS NULL AND in_item_html IS NULL THEN
		DELETE FROM alert_template_body
		 WHERE customer_alert_type_id = in_customer_alert_type_id
		   AND lang = in_lang;
	ELSE
		BEGIN
			INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES (in_customer_alert_type_id, in_lang, in_subject, in_body_html, in_item_html);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE alert_template_body
				   SET subject = in_subject,
					   body_html = in_body_html,
					   item_html = in_item_html
				 WHERE customer_alert_type_id = in_customer_alert_type_id
				   AND lang = in_lang;
		END;
	END IF;
END;

PROCEDURE GetPendingCmsAlerts(
	in_is_batched				IN cms_alert_type.is_batched%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security, only called by credit360.scheduledtasks.flow
	IF in_is_batched = 0 THEN
		OPEN out_cur FOR
			SELECT cat.app_sid, figa.flow_transition_alert_id, cat.customer_alert_type_id, cat.tab_sid
			  FROM flow_item_generated_alert figa
			  JOIN flow_transition_alert fta ON figa.app_sid = fta.app_sid AND figa.flow_transition_alert_id = fta.flow_transition_alert_id
			  JOIN cms_alert_type cat ON fta.app_sid = cat.app_sid AND fta.customer_alert_type_id = cat.customer_alert_type_id
			 WHERE fta.deleted = 0
			   AND cat.is_batched = 0
			   AND figa.processed_dtm IS NULL
			 GROUP BY cat.app_sid, figa.flow_transition_alert_id, cat.customer_alert_type_id, cat.tab_sid
			 ORDER BY cat.app_sid, cat.customer_alert_type_id, figa.flow_transition_alert_id;--order matters for sched task
	ELSE
		OPEN out_cur FOR
			-- we need to return ones that are due a batch run, even if they don't have a flow item alert to send so we can update
			-- the run schedule, for now send all to account for ones that don't have a schedule yet.
			SELECT cat.app_sid, figa.flow_transition_alert_id, cat.customer_alert_type_id, cat.tab_sid
			  FROM cms_alert_type cat
			  JOIN flow_transition_alert fta ON cat.app_sid = fta.app_sid AND cat.customer_alert_type_id = fta.customer_alert_type_id
			  LEFT JOIN flow_item_generated_alert figa ON fta.app_sid = figa.app_sid AND fta.flow_transition_alert_id = figa.flow_transition_alert_id AND figa.processed_dtm IS NULL
			 WHERE cat.deleted = 0
			   AND fta.deleted = 0
			   AND cat.is_batched = 1
			 GROUP BY cat.app_sid, figa.flow_transition_alert_id, cat.customer_alert_type_id, cat.tab_sid
			 ORDER BY cat.app_sid, cat.customer_alert_type_id, figa.flow_transition_alert_id;
	END IF;
END;

PROCEDURE GetOpenGeneratedAlerts(
	in_flow_transition_alert_id IN flow_transition_alert.flow_transition_alert_id %TYPE,
	in_is_batched				IN cms_alert_type.is_batched%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	--do some clean up first..
	cms.tab_pkg.MarkGenAlertsRefDeletedCms(in_flow_transition_alert_id);

	--need to clear the table as it maintains data across transactions
	DELETE FROM TT_ALERT_FLOW_ITEMS;

	IF in_is_batched = 0 THEN
		--capture the flow_items we need to process (might lose slightly in perf however we ensure that sched task processes only "captured" cms flow item records)
		INSERT INTO TT_ALERT_FLOW_ITEMS
		SELECT DISTINCT flow_item_id
		  FROM v$open_flow_item_gen_alert
		 WHERE app_sid = security_pkg.getApp
		   AND is_batched = 0
		   AND flow_transition_alert_id = in_flow_transition_alert_id;

		OPEN out_cur FOR
			SELECT flow_transition_alert_id, customer_alert_type_id, helper_sp,
					from_state_id, from_state_label,
					to_state_id, to_state_label,
					flow_state_log_Id, set_dtm, set_by_user_sid, comment_text,
					set_by_full_name, set_by_email, set_by_user_name,
					to_user_sid, to_full_name,
					to_email, to_user_name, to_friendly_name,
					app_sid, figa.flow_item_id, flow_sid, current_state_id,
					survey_response_id, dashboard_instance_id, to_initiator, flow_alert_helper,
					to_column_sid, flow_item_generated_alert_id,
					is_batched, alert_manager_flag, created_dtm, flow_state_transition_id
			  FROM v$open_flow_item_gen_alert figa
			  JOIN TT_ALERT_FLOW_ITEMS tt ON figa.flow_item_id = tt.flow_item_id
			 WHERE app_sid = security_pkg.getApp
			   AND is_batched = 0
			   AND flow_transition_alert_id = in_flow_transition_alert_id
			 ORDER BY figa.flow_item_id, flow_state_log_id; --order matters for scheduled task
	ELSIF in_is_batched = 1 THEN
		INSERT INTO TT_ALERT_FLOW_ITEMS
		SELECT /*+ALL_ROWS CARDINALITY(tabr, 70000)*/ DISTINCT flow_item_id
		  FROM v$open_flow_item_gen_alert figa
		  JOIN csr.temp_alert_batch_run tabr
		    ON figa.app_sid = tabr.app_sid
		   AND figa.to_user_sid = tabr.csr_user_sid
		   AND figa.customer_alert_type_id = tabr.customer_alert_type_id
		 WHERE figa.app_sid = security_pkg.getApp
		   AND is_batched = 1
		   AND flow_transition_alert_id = in_flow_transition_alert_id;

		OPEN out_cur FOR
			SELECT /*+ALL_ROWS CARDINALITY(tabr, 70000)*/ figa.flow_transition_alert_id, figa.customer_alert_type_id, figa.helper_sp,
					figa.from_state_id, figa.from_state_label,
					figa.to_state_id, figa.to_state_label,
					figa.flow_state_log_Id, figa.set_dtm, figa.set_by_user_sid, figa.comment_text,
					figa.set_by_full_name, figa.set_by_email, figa.set_by_user_name,
					figa.to_user_sid, figa.to_full_name,
					figa.to_email, figa.to_user_name, figa.to_friendly_name,
					figa.app_sid, figa.flow_item_id, figa.flow_sid, figa.current_state_id,
					figa.survey_response_id, figa.dashboard_instance_id, figa.to_initiator, figa.flow_alert_helper,
					figa.to_column_sid, figa.flow_item_generated_alert_id,
					figa.is_batched, figa.alert_manager_flag, figa.created_dtm, figa.flow_state_transition_id
			  FROM v$open_flow_item_gen_alert figa
			  JOIN TT_ALERT_FLOW_ITEMS tt ON figa.flow_item_id = tt.flow_item_id
			  JOIN csr.temp_alert_batch_run tabr
				ON figa.app_sid = tabr.app_sid
			   AND figa.to_user_sid = tabr.csr_user_sid
			   AND figa.customer_alert_type_id = tabr.customer_alert_type_id
			 WHERE figa.app_sid = security_pkg.getApp
			   AND is_batched = 1
			   AND flow_transition_alert_id = in_flow_transition_alert_id
			 ORDER BY figa.to_user_sid, flow_item_Id, flow_state_log_id; --order matters for sched task
	END IF;

END;

PROCEDURE MarkFlowItemGeneratedAlert(
	in_flow_item_gen_alert_id	IN flow_item_generated_alert.flow_item_generated_alert_id%TYPE
)
AS
BEGIN
	UPDATE flow_item_generated_alert
	   SET processed_dtm = SYSDATE
	 WHERE flow_item_generated_alert_id = in_flow_item_gen_alert_id
	   AND processed_dtm IS NULL;
END;

PROCEDURE MarkFlowItemGeneratedAlert(
	in_flow_item_gen_alert_ids	IN security_pkg.T_SID_IDS
)
AS
BEGIN
	FOR i IN in_flow_item_gen_alert_ids.FIRST..in_flow_item_gen_alert_ids.LAST
	LOOP
		MarkFlowItemGeneratedAlert(in_flow_item_gen_alert_ids(i));
	END LOOP;
END;

PROCEDURE GetItemsNeedImmediateProgress(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_occuring_fst			security.T_SID_TABLE;
BEGIN
	security.user_pkg.logonadmin;
	
	OPEN out_cur FOR
		SELECT fi.app_sid, fi.flow_item_id, fst.to_state_id
		  FROM flow_state_transition fst
		  JOIN flow_item fi ON fi.current_state_id = fst.from_state_id AND fi.app_sid = fst.app_sid
		 WHERE fst.hours_before_auto_tran = 0
		   AND fst.auto_schedule_xml IS NULL
		 ORDER BY fi.app_sid ASC;
END;

PROCEDURE GetItemsNeedScheduledProgress(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_occuring_fst			security.T_SID_TABLE;
BEGIN
	security.user_pkg.logonadmin;
	
	SELECT flow_state_transition_id
	  BULK COLLECT INTO v_occuring_fst
	  FROM flow_state_transition
	 WHERE CASE WHEN auto_schedule_xml IS NULL THEN NULL 
				WHEN last_run_dtm IS NULL THEN NULL 
			    ELSE CSR.RECURRENCE_PATTERN_PKG.GETNEXTOCCURRENCE(auto_schedule_xml, last_run_dtm) END <= trunc(SYSDATE, 'DD');
	
	OPEN out_cur FOR
		WITH DUE_FST AS (
			SELECT flow_state_transition_id, CSR.RECURRENCE_PATTERN_PKG.GETNEXTOCCURRENCE(auto_schedule_xml, last_run_dtm) next_run_dtm
			  FROM flow_state_transition fst
			 WHERE EXISTS (SELECT NULL FROM TABLE(v_occuring_fst) WHERE column_value = fst.flow_state_transition_id)
		)
		SELECT c.host, fsl.flow_item_id, fst.to_state_id, fsl.app_sid,
				CASE WHEN df.next_run_dtm IS NOT NULL THEN df.next_run_dtm ELSE fsl.set_dtm + (fst.hours_before_auto_tran/24) END next_run_dtm, fi.auto_failure_count
		  FROM flow_state_transition fst
		  JOIN flow_item fi ON fi.current_state_id = fst.from_state_id AND fi.app_sid = fst.app_sid
		  JOIN flow_state_log fsl on fsl.flow_state_log_id = fi.last_flow_state_log_id AND fi.app_sid = fsl.app_sid
		  JOIN flow f ON fi.flow_sid = f.flow_sid AND fi.app_sid = f.app_sid
		  JOIN customer c ON f.app_sid = c.app_sid
		  LEFT JOIN due_fst df ON df.flow_state_transition_id = fst.flow_state_transition_id
		 WHERE (fst.hours_before_auto_tran > 0 AND (fsl.set_dtm + (fst.hours_before_auto_tran/24) <= SYSDATE)) -- filter out immediate auto-trans (set as 0)
			OR (df.next_run_dtm IS NOT NULL AND df.next_run_dtm <= SYSDATE)
		 ORDER BY fsl.app_sid ASC;
		 
	UPDATE flow_state_transition fst 
	   SET last_run_dtm = trunc(SYSDATE, 'DD')
	 WHERE EXISTS (SELECT NULL FROM TABLE(v_occuring_fst) WHERE column_value = fst.flow_state_transition_id);
END;

FUNCTION IsFinalState(
	in_flow_sid        IN	security.security_pkg.T_SID_ID,
	in_state_id        IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN NUMBER
AS
	v_is_final NUMBER;
BEGIN

	SELECT is_final
	  INTO v_is_final
	  FROM flow_state
	 WHERE flow_sid = in_flow_sid
	   AND flow_state_id = in_state_id;

	RETURN v_is_final;
END;

FUNCTION IsDefaultState(
	in_flow_sid        IN	security.security_pkg.T_SID_ID,
	in_state_id        IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN NUMBER
AS
	v_is_default		NUMBER;
BEGIN

	SELECT DECODE (default_state_id, in_state_id, 1, 0)
	  INTO v_is_default
	  FROM flow f
	 WHERE flow_sid = in_flow_sid;

	RETURN v_is_default;
END;

PROCEDURE GetCustomerFlowTypes(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cfac.flow_alert_class flow_type, fac.label, fac.allow_create
		  FROM customer_flow_alert_class cfac
		  JOIN flow_alert_class fac
		    ON cfac.flow_alert_class = fac.flow_alert_class
		 WHERE cfac.app_sid = security.security_pkg.GetApp;
END;

PROCEDURE GetInvolvmentTypes(
	in_flow_class					IN	flow_alert_class.flow_alert_class%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_company_count					NUMBER;
BEGIN
	-- Only show audit company type if we have suppliers
	SELECT count(*)
	  INTO v_company_count
	  FROM supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	-- no need for security - this is just basedata at the moment
	OPEN out_cur FOR
		SELECT fit.flow_involvement_type_id, fit.label, fit.css_class
		  FROM v$flow_involvement_type fit
		 WHERE fit.flow_alert_class = in_flow_class
		   AND fit.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND (fit.flow_involvement_type_id != csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY OR v_company_count > 1);
END;

PROCEDURE VerifyFlowExists(
	in_flow_sid 	IN flow.flow_sid%TYPE
)
AS
	v_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified workflow ('||in_flow_sid||') cannot be found.');
	END IF;
END;

PROCEDURE VerifyAlertClassExists(
	in_flow_alert_class	IN	flow_alert_class.flow_alert_class%TYPE
)
AS
	v_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM customer_flow_alert_class
	 WHERE flow_alert_class = in_flow_alert_class;

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow alert class ('||in_flow_alert_class||') cannot be found.');
	END IF;
END;

PROCEDURE GetInvolvementTypesByWorkflow(
	in_flow_sid		IN flow_state.flow_sid%TYPE,
	out_cur		 	OUT SYS_REFCURSOR
)
AS
BEGIN
	VerifyFlowExists(in_flow_sid);

	OPEN out_cur FOR
		SELECT DISTINCT fit.flow_involvement_type_id, fit.label
		  FROM flow_state fs
		  JOIN flow_state_involvement fsi ON fs.flow_state_id = fsi.flow_state_id
		  JOIN flow_involvement_type fit ON fsi.flow_involvement_type_id = fit.flow_involvement_type_id
		 WHERE fit.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND fs.flow_sid = in_flow_sid;
END;

PROCEDURE GetInvolvementTypesByAlertClass(
	in_flow_alert_class	IN	flow_alert_class.flow_alert_class%TYPE,
	out_cur		 		OUT SYS_REFCURSOR
)
AS
BEGIN
	VerifyAlertClassExists(in_flow_alert_class);

	OPEN out_cur FOR
		SELECT DISTINCT fit.flow_involvement_type_id, fit.label
		  FROM flow_involvement_type fit
		  JOIN flow_inv_type_alert_class fitac ON fitac.flow_involvement_type_id = fit.flow_involvement_type_id
		 WHERE fit.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND fitac.flow_alert_class = in_flow_alert_class;
END;

PROCEDURE GetCapabilities(
	in_flow_class					IN	flow_alert_class.flow_alert_class%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_audits_on_users				customer.audits_on_users%TYPE;
BEGIN
	-- Only show auditee if we have audits on users
	SELECT audits_on_users
	  INTO v_audits_on_users
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	OPEN out_cur FOR
		SELECT flow_capability_id, description, perm_type, default_permission_set, lookup_key
		  FROM v$flow_capability
		 WHERE flow_alert_class = in_flow_class
		   AND (flow_capability_id != csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE OR v_audits_on_users = 1)
		 ORDER BY description;
END;

PROCEDURE BeginAlertBatchRun(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id	IN	flow_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the flow with sid '||in_flow_sid);
	END IF;

	alert_pkg.BeginCustomerAlertBatchRun(in_customer_alert_type_id);

	-- Fill in the next fire date for any missing users
	FOR r IN (
		SELECT x.flow_state_alert_id, x.user_sid, x.this_fire_date, x.recurrence_pattern
		  FROM (
			SELECT t.csr_user_sid user_sid, TRUNC(t.this_fire_time, 'DD') this_fire_date, a.flow_state_alert_id, a.recurrence_pattern, r.next_fire_date
			  FROM temp_alert_batch_run t
			  JOIN flow_state_alert a ON a.customer_alert_type_id = t.customer_alert_type_id AND a.deleted = 0
			  LEFT JOIN flow_state_alert_run r ON r.flow_sid = a.flow_sid AND r.flow_state_alert_id = a.flow_state_alert_id AND r.user_sid = t.csr_user_sid
			 WHERE t.customer_alert_type_id = in_customer_alert_type_id
			   AND a.flow_sid = in_flow_sid
		  ) x
		 WHERE x.next_fire_date IS NULL
	) LOOP
		INSERT INTO flow_state_alert_run (flow_sid, flow_State_alert_id, user_sid, next_fire_date)
		  VALUES (in_flow_sid, r.flow_state_alert_id, r.user_sid,
		   	recurrence_pattern_pkg.GetNextOccurrence(r.recurrence_pattern, r.this_fire_date));
	END LOOP;

	DELETE FROM temp_flow_state_alert_run
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO temp_flow_state_alert_run (flow_sid, flow_state_alert_id, user_sid, this_fire_date)
		SELECT a.flow_sid, a.flow_state_alert_id, r.user_sid, TRUNC(t.this_fire_time, 'DD')
		  FROM temp_alert_batch_run t
		  JOIN flow_state_alert a ON a.flow_sid = in_flow_sid AND a.customer_alert_type_id = t.customer_alert_type_id AND a.deleted = 0
		  JOIN flow_state_alert_run r ON r.flow_sid = in_flow_sid AND r.flow_state_alert_id = a.flow_state_alert_id AND r.user_sid = t.csr_user_sid
		 WHERE t.customer_alert_type_id = in_customer_alert_type_id
		   AND TRUNC(t.this_fire_time, 'DD') >= TRUNC(r.next_fire_date, 'DD')
	;

	COMMIT;
END;

PROCEDURE RecordUserBatchRun(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_flow_state_alert_id		IN	flow_state_alert.flow_state_alert_id%TYPE
)
AS
	v_this_fire_date			DATE;
	v_customer_alert_type_id	flow_state_alert.customer_alert_type_id%TYPE;
	v_recurrence_pattern		flow_state_alert.recurrence_pattern%TYPE;
BEGIN
	-- XXX: We can't call alert_pkg.RecordUserBatchRun because there may be
	-- more than one flow state alert for a given customer alert type and
	-- we're recording the fact we sent a flow state alert, not the alert type

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the flow with sid '||in_flow_sid);
	END IF;

	SELECT r.this_fire_date, a.recurrence_pattern
	  INTO v_this_fire_date, v_recurrence_pattern
	  FROM temp_flow_state_alert_run r
	  JOIN flow_state_alert a ON a.flow_sid = r.flow_sid AND a.flow_state_alert_id = r.flow_state_alert_id AND a.deleted = 0
	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND r.flow_sid = in_flow_sid
	   AND r.user_sid = in_user_sid
	   AND r.flow_state_alert_id = in_flow_state_alert_id;

	UPDATE flow_state_alert_run
	   SET last_fire_date = next_fire_date,
	       next_fire_date = recurrence_pattern_pkg.GetNextOccurrence(v_recurrence_pattern, v_this_fire_date)
	 WHERE flow_sid = in_flow_sid
	   AND flow_state_alert_id = in_flow_state_alert_id
	   AND user_sid = in_user_sid;

	DELETE FROM temp_flow_state_alert_run
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND flow_sid = in_flow_sid
	   AND flow_state_alert_id = in_flow_state_alert_id
	   AND user_sid = in_user_sid;

	COMMIT;
END;

PROCEDURE EndAlertBatchRun(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id	IN	flow_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	-- Record that we ran for anything we didn't record an alert for
	FOR r IN (
		SELECT t.flow_sid, t.flow_state_alert_id, t.user_sid, t.this_fire_date, a.recurrence_pattern
		  FROM temp_flow_state_alert_run t
		  JOIN flow_state_alert a ON a.flow_sid = t.flow_sid AND a.flow_state_alert_id = t.flow_State_alert_id
		 WHERE t.flow_sid = in_flow_sid
		   AND a.customer_alert_type_id = in_customer_alert_type_id
		   AND a.deleted = 0
	) LOOP
		UPDATE flow_state_alert_run
		   SET last_fire_date = next_fire_date,
		       next_fire_date = recurrence_pattern_pkg.GetNextOccurrence(r.recurrence_pattern, r.this_fire_date)
		 WHERE flow_sid = r.flow_sid
		   AND flow_state_alert_id = r.flow_state_alert_id
		   AND user_sid = r.user_sid;
	END LOOP;

	-- Clean up
	DELETE FROM temp_flow_state_alert_run
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND flow_sid = in_flow_sid
	   AND flow_state_alert_id IN (
	   	SELECT flow_State_alert_id
	   	  FROM flow_state_alert
	   	 WHERE flow_sid = in_flow_sid
	   	   AND customer_alert_type_id = in_customer_alert_type_id
	 );

	-- End the alert batch run (this commits)
	alert_pkg.EndCustomerAlertBatchRun(in_customer_alert_type_id);
END;

FUNCTION GetPreviousState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER
AS
	v_flow_state_id		flow_state.flow_state_id%TYPE;
BEGIN
		--try and get the previous state
	  SELECT flow_state_id
	    INTO v_flow_state_id
	    FROM (
			SELECT flow_state_log_id, flow_state_id, ROWNUM AS rn FROM (
				SELECT flow_state_log_id, flow_state_id FROM csr.flow_state_log WHERE flow_item_id = in_flow_item_id ORDER BY flow_state_log_id DESC
				)
			)
	   WHERE rn = 2;

	 RETURN v_flow_state_id;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
END;

PROCEDURE SetFlowStateMoveToId(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_from_flow_state_id		IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_flow_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID
)
AS
BEGIN
	UPDATE flow_state
	   SET move_from_flow_state_id = in_to_flow_state_id
	 WHERE flow_state_id = in_from_flow_state_id
	   AND flow_sid = in_flow_sid;
END;

PROCEDURE GetAvailableUsersForState(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT	SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_region_sid					security_pkg.T_SID_ID;
	v_table							csr.T_USER_FILTER_TABLE;
	v_show_email					NUMBER;
	v_show_user_name				NUMBER;
	v_show_user_ref					NUMBER;

BEGIN
	-- get the region
	SELECT region_sid
	  INTO v_region_sid
	  FROM csr.section_module
	WHERE module_root_sid IN (
		SELECT module_root_sid
		  FROM csr.section
		 WHERE section_sid = in_section_sid);

	csr_user_pkg.FilterUsersToTable(in_filter, in_include_inactive, v_table);

	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM customer
	 WHERE app_sid = v_app_sid;

	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, csr_user_pkg.MAX_USERS max_size
		  FROM csr_user cu, TABLE(v_table) t
		 WHERE cu.app_sid = v_app_sid
		   AND cu.csr_user_sid = t.csr_user_sid
		   AND (cu.csr_user_sid IN (
			--restrict the users with the right roles
			SELECT DISTINCT(rrm.user_sid)
			  FROM region_role_member rrm
			  JOIN TABLE(v_table) u
				ON rrm.user_sid = u.csr_user_sid
			 WHERE rrm.role_sid IN (
				SELECT DISTINCT role_sid
				  FROM csr.flow_state_role
				 WHERE flow_state_id = in_state_id
				)
			   AND rrm.region_sid = v_region_sid
			)
		   OR EXISTS (
				SELECT 1
				  FROM security.act
				 WHERE sid_id IN (
					SELECT DISTINCT group_sid
					  FROM flow_state_role
					 WHERE flow_state_id = in_state_id
				 )))
		   AND NOT EXISTS( SELECT NULL FROM trash WHERE trash_sid = cu.csr_user_sid);

	OPEN out_cur FOR
		SELECT csr_user_sid, full_name, email, user_name, account_enabled,
			   user_sid, sid,
			   user_ref, v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
		  FROM (
			SELECT x.*, rownum rn
			   FROM (
				SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, t.account_enabled,
					cu.csr_user_sid user_sid, cu.csr_user_sid sid , --we use csr_user_sid AND sid in some legacy things
					cu.user_ref
				  FROM csr_user cu
				  JOIN TABLE(v_table) t ON cu.csr_user_sid = t.csr_user_sid
				  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
				 WHERE cu.app_sid = v_app_sid
				   AND (cu.csr_user_sid IN (
					--restrict the users with the right roles
					SELECT DISTINCT(rrm.user_sid)
					  FROM region_role_member rrm
					  JOIN TABLE(v_table) u
						ON rrm.user_sid = u.csr_user_sid
					 WHERE rrm.role_sid IN (
						SELECT DISTINCT role_sid
						  FROM csr.flow_state_role
						 WHERE flow_state_id = in_state_id
						)
					   AND rrm.region_sid = v_region_sid
					)
				   OR EXISTS (
						SELECT 1
						  FROM security.act
						 WHERE sid_id IN (
							SELECT DISTINCT group_sid
							  FROM flow_state_role
							 WHERE flow_state_id = in_state_id
						 )))
				   AND NOT EXISTS( SELECT NULL FROM trash WHERE trash_sid = cu.csr_user_sid)
				) x
				ORDER BY account_enabled DESC,
				      CASE WHEN in_filter IS NULL OR LOWER(TRIM(full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
					  CASE WHEN in_filter IS NULL OR LOWER(TRIM(full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
					  LOWER(TRIM(full_name))
			)
		 WHERE rn <= csr_user_pkg.MAX_USERS
		 ORDER BY rn;
END;

-- Called when a new workflow of type 'approvaldashboard' is created.
PROCEDURE OnCreateAppDashFlow(
	in_flow_sid					IN	security_pkg.T_SID_ID
)
AS
	v_default_state_id					flow_state.flow_state_id%TYPE;
BEGIN

	--security_pkg.debugmsg('Helper SP running');

	-- Inject the helpers.
	SetStateTransHelper(in_flow_sid, 'csr.approval_dashboard_pkg.TransitionLockInstance',			'Lock instance');
	SetStateTransHelper(in_flow_sid, 'csr.approval_dashboard_pkg.TransitionSignOffInstance',		'Sign off instance');
	SetStateTransHelper(in_flow_sid, 'csr.approval_dashboard_pkg.TransitionUnlockInstance',			'Unlock instance');
	SetStateTransHelper(in_flow_sid, 'csr.approval_dashboard_pkg.TransitionReopenSignedOffInst', 	'Reopen instance (from signed off)');
	SetStateTransHelper(in_flow_sid, 'csr.approval_dashboard_pkg.TransitionPublish', 				'Publish');

	-- Now add them to the transitions. The basic application is;
		-- 'Lock instance' goes onto any transition OUT of the default state
		-- 'Unlock instance' goes onto any transition INTO the default state - ie returning it
		-- 'Sign off' Goes onto any transition INTO the final state
		-- 'Reopen' Should go onto any transition BACK from the final state, but does not get automatically set because it can go wrong if the final state has more states
		-- 'Publish' does not get automatically set.

	BEGIN
		SELECT default_state_id
		  INTO v_default_state_id
		  FROM FLOW
		 WHERE flow_sid = in_flow_sid;

		UPDATE FLOW_STATE_TRANSITION
		   SET helper_sp = 'csr.approval_dashboard_pkg.TransitionLockInstance'
		 WHERE from_state_id = v_default_state_id
		   AND flow_sid = in_flow_sid;

		 UPDATE FLOW_STATE_TRANSITION
		   SET helper_sp = 'csr.approval_dashboard_pkg.TransitionUnlockInstance'
		 WHERE to_state_id = v_default_state_id
		   AND flow_sid = in_flow_sid;

	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	UPDATE FLOW_STATE_TRANSITION
	   SET helper_sp = 'csr.approval_dashboard_pkg.TransitionSignOffInstance'
	 WHERE to_state_id IN (
		SELECT flow_state_id
		  FROM FLOW_STATE
		 WHERE is_final = 1
		   AND flow_sid = in_flow_sid
	 );

END;

PROCEDURE OnCreateCampaignFlow(
	in_flow_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
  	SetStateTransHelper(in_flow_sid, 'campaigns.campaign_pkg.ApplyCampaignScoresToSupplier','Update supplier scores from campaign');
  	SetStateTransHelper(in_flow_sid, 'campaigns.campaign_pkg.ApplyCampaignScoresToProperty','Update property scores from campaign');
END;

PROCEDURE OnCreateAuditFlow(
	in_flow_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.ApplyAuditScoresToSupplier','Apply audit scores to supplier');
	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.ApplyAuditNCScoreToSupplier','Apply audit findings score to supplier');
  	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.SetMatchingSupplierFlowState','Transition supplier flow based on lookup key');
  	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.PublishSurveyScoresToSupplier','Update supplier scores from surveys');
  	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.PublishSurveyScoresToProperty','Update property scores from surveys');
  	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.ReaggregateAllIndicators','Re-aggregate all indicators');
  	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.CheckSurveySubmission','Check Survey Submission');
	SetStateTransHelper(in_flow_sid, 'csr.audit_helper_pkg.PublishSurveyScoresToPermit','Apply audit scores to permit');
END;

PROCEDURE SetGroup(
	in_group_name		IN	security.securable_object.name%TYPE,
	out_group_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_class_id			security_pkg.T_CLASS_ID;
	v_groups_sid		security_pkg.T_SID_ID;
	v_act_id			security_pkg.T_ACT_ID := security_pkg.getACT;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.getApp;
BEGIN
	BEGIN
		v_class_id := class_pkg.GetClassId('Group');
        v_groups_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');

        -- this will check permissions on the Groups node
        group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security_pkg.SO_SECURITY_GROUP,
            REPLACE(in_group_name,'/','\'), v_class_id, out_group_sid); --'

		csr_data_pkg.WriteAuditLogEntry(v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid,
			v_app_sid, 'Created group "{0}"', in_group_name);
    EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			out_group_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, in_group_name);
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_group_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, in_group_name);
	END;
END;

PROCEDURE GetCustomerInvolvementTypes (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR,
	out_flow_alert_cls_cur			OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_workflows_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Workflows');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_workflows_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading workflow');
	END IF;

	OPEN out_cur FOR
		SELECT fit.flow_involvement_type_id, fit.label, fit.product_area, fit.css_class, fit.lookup_key,
				   COUNT(fi.flow_involvement_type_id) involvement_count
		  FROM flow_involvement_type fit
		  LEFT JOIN (
				SELECT app_sid, flow_involvement_type_id
				  FROM flow_state_involvement
				 UNION
				SELECT app_sid, flow_involvement_type_id
				  FROM flow_state_transition_inv
				 UNION
				SELECT app_sid, flow_involvement_type_id
				  FROM flow_transition_alert_inv
			 ) fi ON fi.flow_involvement_type_id = fit.flow_involvement_type_id
		   AND fi.app_sid = fit.app_sid
		 WHERE fit.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND fit.flow_involvement_type_id >= CUSTOMER_INV_TYPE_MIN
		 GROUP BY fit.flow_involvement_type_id, fit.label, fit.product_area, fit.css_class, fit.lookup_key;

	OPEN out_flow_alert_cls_cur FOR
		SELECT flow_involvement_type_id, flow_alert_class
		  FROM flow_inv_type_alert_class;
END;

PROCEDURE SaveCustomerInvolvementType (
	in_involvement_type_id			IN	flow_involvement_type.flow_involvement_type_id%TYPE,
	in_label						IN	flow_involvement_type.label%TYPE,
	in_product_area					IN	flow_involvement_type.product_area%TYPE,
	in_flow_alert_classes			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_css_class					IN	flow_involvement_type.css_class%TYPE,
	in_lookup_key					IN	flow_involvement_type.lookup_key%TYPE,
	out_involvement_type_id			OUT	flow_involvement_type.flow_involvement_type_id%TYPE
)
AS
	v_css_class							flow_involvement_type.css_class%TYPE;
	v_workflows_sid						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Workflows');
	v_flow_alert_classes				security.T_VARCHAR2_TABLE := security.security_pkg.Varchar2ArrayToTable(in_flow_alert_classes);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_workflows_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing workflow');
	END IF;

	v_css_class := in_css_class;
	IF v_css_class IS NULL THEN
		v_css_class := 'CSRUser';
	END IF;

	BEGIN
		IF NVL(in_involvement_type_id, 0) > 0 THEN
			UPDATE flow_involvement_type
			   SET label = in_label,
				   css_class = v_css_class,
				   lookup_key = in_lookup_key
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND flow_involvement_type_id = in_involvement_type_id;

			out_involvement_type_id := in_involvement_type_id;
		ELSE
			INSERT INTO flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class, lookup_key)
			VALUES (SYS_CONTEXT('SECURITY','APP'), flow_involvement_type_id_seq.NEXTVAL, in_product_area, in_label, v_css_class, in_lookup_key)
			RETURNING flow_involvement_type_id INTO out_involvement_type_id;
		END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'The lookup key ' || in_lookup_key || ' is already in use');
	END;

	DELETE FROM flow_inv_type_alert_class
	 WHERE flow_involvement_type_id = out_involvement_type_id
	   AND flow_alert_class NOT IN (SELECT value FROM TABLE(v_flow_alert_classes));

	INSERT INTO flow_inv_type_alert_class (flow_involvement_type_id, flow_alert_class)
	SELECT out_involvement_type_id, value
	  FROM TABLE(v_flow_alert_classes)
	 MINUS
	SELECT out_involvement_type_id, flow_alert_class
	  FROM flow_inv_type_alert_class
	 WHERE flow_involvement_type_id = out_involvement_type_id;
END;

PROCEDURE DeleteCustomerInvolvementType (
	in_involvement_type_id			IN	flow_involvement_type.flow_involvement_type_id%TYPE
)
AS
	v_workflows_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Workflows');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_workflows_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing workflow');
	END IF;

	DELETE FROM flow_transition_alert_inv
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_state_transition_inv
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_state_role_capability
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_state_involvement
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM audit_type_flow_inv_type
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_item_involvement
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_inv_type_alert_class
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_involvement_type
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SetInvolvementType (
	in_flow_sid						IN	security.security_pkg.T_SID_ID,
	in_label						IN	flow_involvement_type.label%TYPE,
	in_css_class					IN	flow_involvement_type.css_class%TYPE,
	out_flow_involvement_type_id	OUT	flow_involvement_type.flow_involvement_type_id%TYPE
)
AS
	v_flow_alert_class				flow.flow_alert_class%TYPE;
	v_flow_involvement_type_id		flow_involvement_type.flow_involvement_type_id%TYPE;
	v_workflows_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Workflows');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_workflows_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing workflow');
	END IF;

	SELECT flow_alert_class
	  INTO v_flow_alert_class
	  FROM csr.flow
	 WHERE flow_sid = in_flow_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	BEGIN
		SELECT flow_involvement_type_id
		  INTO v_flow_involvement_type_id
		  FROM flow_involvement_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND label = in_label;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO flow_involvement_type (flow_involvement_type_id, product_area, label, css_class, lookup_key)
			VALUES (flow_involvement_type_id_seq.NEXTVAL, v_flow_alert_class, in_label, in_css_class, NULL)
			RETURNING flow_involvement_type_id INTO v_flow_involvement_type_id;

			INSERT INTO flow_inv_type_alert_class (flow_involvement_type_id, flow_alert_class)
			VALUES (v_flow_involvement_type_id, v_flow_alert_class);
	END;

	out_flow_involvement_type_id := v_flow_involvement_type_id;
END;

PROCEDURE GetCustomerFlowCapabilities(
	in_flow_alert_class				IN	customer_flow_capability.flow_alert_class%TYPE DEFAULT NULL,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security, these aren't a secret

	OPEN out_cur FOR
		SELECT cfc.flow_capability_id, cfc.flow_alert_class, cfc.description, cfc.perm_type, cfc.default_permission_set,
			   CASE WHEN atc.flow_capability_id IS NULL THEN 0 ELSE 1 END is_audit_tab_capability,
			   CASE WHEN chc.flow_capability_id IS NULL THEN 0 ELSE 1 END is_chain_capability,
			   CASE WHEN ctc.flow_capability_id IS NULL THEN 0 ELSE 1 END is_company_tab_capability,
			   CASE WHEN sgc.flow_capability_id IS NULL THEN 0 ELSE 1 END is_ia_survey_capability,
			   cfc.is_system_managed
		  FROM customer_flow_capability cfc
		  LEFT JOIN (
			SELECT DISTINCT flow_capability_id FROM audit_type_tab
		  ) atc ON atc.flow_capability_id = cfc.flow_capability_id
		  LEFT JOIN (
			SELECT DISTINCT flow_capability_id FROM chain.capability_flow_capability
		  ) chc ON chc.flow_capability_id = cfc.flow_capability_id
		  LEFT JOIN (
			SELECT DISTINCT flow_capability_id FROM chain.company_tab
		  ) ctc ON ctc.flow_capability_id = cfc.flow_capability_id
		  LEFT JOIN (
			SELECT DISTINCT survey_capability_id flow_capability_id FROM ia_type_survey_group
			UNION
			SELECT DISTINCT change_survey_capability_id flow_capability_id FROM ia_type_survey_group
		  ) sgc ON sgc.flow_capability_id = cfc.flow_capability_id
		  WHERE NVL(in_flow_alert_class, flow_alert_class) = cfc.flow_alert_class
		 ORDER BY description;
END;

PROCEDURE SaveCustomerFlowCapability(
	in_flow_capability_id			IN	customer_flow_capability.flow_capability_id%TYPE,
	in_flow_alert_class				IN	customer_flow_capability.flow_alert_class%TYPE DEFAULT NULL,
	in_description					IN	customer_flow_capability.description%TYPE DEFAULT NULL,
	in_perm_type					IN	customer_flow_capability.perm_type%TYPE DEFAULT NULL,
	in_default_permission_set		IN	customer_flow_capability.default_permission_set%TYPE DEFAULT NULL,
	in_copy_capability_id			IN	customer_flow_capability.flow_capability_id%TYPE DEFAULT NULL,
	in_is_system_managed			IN	customer_flow_capability.is_system_managed%TYPE DEFAULT 0,
	out_flow_capability_id			OUT	customer_flow_capability.flow_capability_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage customer flow capabilities');
	END IF;

	IF in_flow_capability_id IS NULL THEN
		INSERT INTO csr.customer_flow_capability (
			flow_capability_id, flow_alert_class, description, perm_type, default_permission_set, is_system_managed
		) VALUES (
			customer_flow_cap_id_seq.NEXTVAL, in_flow_alert_class, in_description, in_perm_type, NVL(in_default_permission_set, 0), in_is_system_managed
		) RETURNING flow_capability_id INTO out_flow_capability_id;

		IF in_copy_capability_id IS NOT NULL THEN
			INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id,
													   role_sid, flow_involvement_type_id, permission_set, group_sid)
			SELECT app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL flow_state_rl_cap_id, flow_state_id, out_flow_capability_id flow_capability_id,
														role_sid, flow_involvement_type_id, permission_set, group_sid
			FROM csr.flow_state_role_capability WHERE flow_capability_id = in_copy_capability_id;
		ELSE
			INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id,
													   role_sid, flow_involvement_type_id, permission_set, group_sid)
			SELECT fsr.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL flow_state_rl_cap_id, fsr.flow_state_id, out_flow_capability_id flow_capability_id,
														fsr.role_sid, NULL flow_involvement_type_id, in_default_permission_set permission_set, fsr.group_sid
			  FROM csr.flow_state_role fsr
			  JOIN csr.flow_state fs ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
			  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
			 WHERE f.flow_alert_class = in_flow_alert_class;

			INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id,
													   role_sid, flow_involvement_type_id, permission_set, group_sid)
			SELECT fsi.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL flow_state_rl_cap_id, fsi.flow_state_id, out_flow_capability_id flow_capability_id,
														NULL role_sid, fsi.flow_involvement_type_id, in_default_permission_set permission_set, NULL group_sid
			  FROM csr.flow_state_involvement fsi
			  JOIN csr.flow_state fs ON fs.flow_state_id = fsi.flow_state_id AND fs.app_sid = fsi.app_sid
			  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
			 WHERE f.flow_alert_class = in_flow_alert_class;
		END IF;
	ELSE
		UPDATE csr.customer_flow_capability
		   SET flow_alert_class = NVL(in_flow_alert_class, flow_alert_class),
			   description = NVL(in_description, description),
			   perm_type = NVL(in_perm_type, perm_type),
			   default_permission_set = NVL(in_default_permission_set, default_permission_set),
			   is_system_managed = in_is_system_managed
		 WHERE flow_capability_id = in_flow_capability_id;

		out_flow_capability_id := in_flow_capability_id;
	END IF;
END;

PROCEDURE DeleteCustomerFlowCapability(
	in_flow_capability_id			IN	customer_flow_capability.flow_capability_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage customer flow capabilities');
	END IF;

	UPDATE audit_type_tab
	   SET flow_capability_id = NULL
	 WHERE flow_capability_id = in_flow_capability_id;

	UPDATE chain.company_tab
	   SET flow_capability_id = NULL
	 WHERE flow_capability_id = in_flow_capability_id;
	
	DELETE FROM csr.non_compliance_type_flow_cap
		  WHERE flow_capability_id = in_flow_capability_id;
	
	DELETE FROM csr.flow_state_role_capability
		  WHERE flow_capability_id = in_flow_capability_id;

	DELETE FROM csr.customer_flow_capability
		  WHERE flow_capability_id = in_flow_capability_id;
END;

PROCEDURE GetFlowStateNatures(
	in_flow_alert_class		IN flow_state_nature.flow_alert_class%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT flow_state_nature_id, label, flow_alert_class
		  FROM flow_state_nature
		 WHERE flow_alert_class = in_flow_alert_class
	  ORDER BY flow_state_nature_id;
END;

PROCEDURE GetStateGroups(
	out_cur	OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No need for security. This is just client specific base data.
	OPEN out_cur FOR
		SELECT flow_state_group_id, lookup_key, label
		  FROM flow_state_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  ORDER BY LOWER(label);
END;

PROCEDURE SaveStateGroup (
	in_flow_state_group_id	IN	flow_state_group.flow_state_group_id%TYPE,
	in_label				IN	flow_state_group.label%TYPE,
	in_lookup_key			IN	flow_state_group.lookup_key%TYPE,
	out_flow_state_group_id	OUT	flow_state_group.flow_state_group_id%TYPE
)
AS
	v_act			security.security_pkg.T_ACT_ID;
	v_app_sid		security.security_pkg.T_SID_ID;
	v_workflows_sid	security.security_pkg.T_SID_ID;
	v_exists		NUMBER(1);
BEGIN
	v_act := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_workflows_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'Workflows');

	IF NOT security_pkg.IsAccessAllowedSID(v_act, v_workflows_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied editing workflow');
	END IF;

	IF in_flow_state_group_id IS NULL THEN
		v_exists := 0;
		out_flow_state_group_id := flow_state_group_id_seq.NEXTVAL;
	ELSE
		-- Workflow admin page pre-selects flow_state_group_id_seq.NEXTVAL for new records.
		-- Check if the record exists or not
		SELECT COUNT(*) INTO v_exists
		  FROM flow_state_group
		 WHERE flow_state_group_id = in_flow_state_group_id;

		out_flow_state_group_id := in_flow_state_group_id;
	END IF;

	IF v_exists = 1 THEN
		UPDATE flow_state_group
		   SET label = in_label,
			   lookup_key = in_lookup_key
		 WHERE app_sid = v_app_sid
		   AND flow_state_group_id = in_flow_state_group_id;
	ELSE
		INSERT INTO flow_state_group (app_sid, flow_state_group_id, label, lookup_key)
		VALUES (v_app_sid, out_flow_state_group_id, in_label, in_lookup_key);
	END IF;
END;

PROCEDURE SetStateGroupMembers(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_flow_state_group_ids		IN	security_pkg.T_SID_IDS
)
AS
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fs.label state_label
		  FROM flow_state fs
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE fs.flow_state_id = in_state_id;
	ar	c%ROWTYPE;
	v_act						security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
    t_flow_state_group_ids		security.T_SID_TABLE;
BEGIN
	v_act := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	t_flow_state_group_ids := security_pkg.SidArrayToTable(in_flow_state_group_ids);

	-- we audit this, so edit the long way round (rather than just deleting)
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow state '||in_state_id||' not found');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(v_act, ar.flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||ar.flow_sid);
	END IF;

	-- Deleted flow state group members
	FOR r IN (
		SELECT fs.flow_state_group_id, fs.label
		  FROM flow_state_group fs
		 WHERE flow_state_group_id IN (
			SELECT flow_state_group_id
			  FROM flow_state_group_member
			 WHERE flow_state_id = in_state_Id
			 MINUS
			SELECT column_value
			  FROM TABLE(t_flow_state_group_ids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid,
			ar.flow_sid, 'Altered workflow "{0}", deleted flow state group category "{1}" for state "{2}"',
			ar.flow_label, r.label, ar.state_label);

		DELETE FROM flow_state_group_member
		 WHERE flow_state_id = in_state_id
		   AND flow_state_group_id = r.flow_state_group_id;
	END LOOP;

	-- Added flow state group members
	FOR r IN (
		SELECT fs.flow_state_group_id, fs.label
		  FROM flow_state_group fs
		 WHERE flow_state_group_id IN (
				SELECT column_value
				  FROM TABLE(t_flow_state_group_ids)
				 MINUS
				SELECT flow_state_group_id
				  FROM flow_state_group_member
				 WHERE flow_state_id = in_state_Id
				)
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid,
			ar.flow_sid, 'Altered workflow "{0}", added flow state group category "{1}" for state "{2}"',
			ar.flow_label, r.label, ar.state_label);

		INSERT INTO flow_state_group_member(flow_state_id, flow_state_group_id)
			VALUES (in_state_id, r.flow_state_group_id);
	END LOOP;
END;

PROCEDURE SaveSurveyTag (
	in_tag_group_name			IN	tag_group_description.name%TYPE,
	in_tag_label				IN	tag_description.tag%TYPE,
	out_tag_id					OUT	tag.tag_id%TYPE
)
AS
BEGIN
	-- all we know about the tag group is its name and that it must apply to surveys
	-- get it if it exists but if not we won't create a full reconstruction
	tag_pkg.INTERNAL_TryCreateTag(
		in_tag_group_name => in_tag_group_name,
		in_tag => in_tag_label,
		in_applies_to_quick_survey => 1,
		out_tag_id => out_tag_id
	);
END;

PROCEDURE SetStateSurveyTags(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_survey_tag_ids			IN	security_pkg.T_SID_IDS
)
AS
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fs.label state_label
		  FROM flow_state fs
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE fs.flow_state_id = in_state_id;
	ar	c%ROWTYPE;
	v_act						security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
    t_survey_tag_ids			security.T_SID_TABLE;
BEGIN
	v_act := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	t_survey_tag_ids := security_pkg.SidArrayToTable(in_survey_tag_ids);

	-- we audit this, so edit the long way round (rather than just deleting)
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow state '||in_state_id||' not found');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(v_act, ar.flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||ar.flow_sid);
	END IF;

	-- Deleted flow state survey tags
	FOR r IN (
		SELECT fs.tag_id, t.tag
		  FROM flow_state_survey_tag fs
		  JOIN v$tag t ON fs.tag_id = t.tag_id
		 WHERE flow_state_id = in_state_id
		   AND fs.tag_id IN (
			SELECT old.tag_id
			  FROM flow_state_survey_tag old
			 WHERE old.flow_state_id = in_state_Id
			 MINUS
			SELECT column_value
			  FROM TABLE(t_survey_tag_ids)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid,
			ar.flow_sid, 'Altered workflow "{0}", deleted flow state survey tag "{1}" for state "{2}"',
			ar.flow_label, r.tag, ar.state_label);

		DELETE FROM flow_state_survey_tag
		 WHERE flow_state_id = in_state_id
		   AND tag_id = r.tag_id;
	END LOOP;

	-- Added flow state group members
	FOR r IN (
		SELECT t.tag_id, t.tag
		  FROM v$tag t
		 WHERE t.tag_id IN (
			SELECT column_value
			  FROM TABLE(t_survey_tag_ids)
			 MINUS
			SELECT old.tag_id
			  FROM flow_state_survey_tag old
			 WHERE old.flow_state_id = in_state_Id
			)
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid,
			ar.flow_sid, 'Altered workflow "{0}", added flow state survey tag "{1}" for state "{2}"',
			ar.flow_label, r.tag, ar.state_label);

		INSERT INTO flow_state_survey_tag(flow_state_id, tag_id)
			VALUES (in_state_id, r.tag_id);
	END LOOP;
END;

PROCEDURE GetFlowAlertHelpers(
	in_flow_sid						IN		security_pkg.T_SID_ID,
	out_flow_alert_helpers_cur		OUT		SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	OPEN out_flow_alert_helpers_cur FOR
		SELECT fst.flow_sid, fah.flow_alert_helper helper_sp, fah.label description
		  FROM flow_alert_helper fah
		  JOIN flow_transition_alert fta ON fah.flow_alert_helper = fta.flow_alert_helper
		  JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id
		 WHERE fst.flow_sid = in_flow_sid
		   AND fst.app_sid = v_app_sid
		 UNION
		SELECT fs.flow_sid, fah.flow_alert_helper helper_sp, fah.label helper_sp
		  FROM flow_alert_helper fah
		  JOIN flow_state_alert fsa on fah.flow_alert_helper = fsa.flow_alert_helper
		  JOIN flow_state fs ON fs.flow_state_id = fsa.flow_state_id
		 WHERE fs.flow_sid = in_flow_sid
		   AND fs.app_sid = v_app_sid;
END;

PROCEDURE GetCmsAlertHelpers(
	in_flow_sid						IN		security_pkg.T_SID_ID,
	in_tab_sid						IN		security_pkg.T_SID_ID,
	out_cms_alert_helpers_cur		OUT		SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	OPEN out_cms_alert_helpers_cur FOR
		SELECT DISTINCT fst.flow_sid, cah.tab_sid, cah.helper_sp, cah.description
		  FROM cms_alert_helper cah
		  JOIN flow_transition_alert fta ON cah.helper_sp = fta.helper_sp
		  JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id
		 WHERE fst.flow_sid = in_flow_sid
		   AND cah.tab_sid = in_tab_sid
		   AND fst.app_sid = v_app_sid;
END;

PROCEDURE OnCreateSupplierFlowHelpers(
	in_flow_sid					IN	security_pkg.T_SID_ID
)
AS
	v_default_state_id					flow_state.flow_state_id%TYPE;
BEGIN
	-- Inject the helpers.
	SetStateTransHelper(in_flow_sid, 'chain.company_pkg.DeactivateSupplierHelper','Deactivate Supplier Company');
	SetStateTransHelper(in_flow_sid, 'chain.company_pkg.ActivateSupplierHelper','Activate Supplier Company');

END;

-- JB: This is from the proof of concept CMS/Mongo stuff. We'd need a way for flow to know what we have access to
-- which means it would need to know the region sid to do the permission checks (as well as pseudo groups/companies etc.
-- for other modules). At the moment the region sid is on the flow item table, but since it should be able to support
-- multiple region sids, this might have to be a child table, but we should review the performance, as we might want
-- a primary region sid directly on the table if its quicker for most cases. We also need to review the index on the
-- table if the region sid stays (to cover the columns in this query).
-- If we start populating the region sid, then we need to add the code to clean up flow items when the region 
-- gets deleted.
PROCEDURE UNFINISHED_GetFlowItemIds(
	in_flow_sid					IN  security_pkg.T_SID_ID,
	out_flow_item_ids			OUT SYS_REFCURSOR
)
AS
	v_user_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_act						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN

	OPEN out_flow_item_ids FOR
		SELECT DISTINCT fi.flow_item_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_item_region fir on fir.flow_item_id = fi.flow_item_id
		 WHERE fi.flow_sid = in_flow_sid
		   AND (EXISTS (
				SELECT 1
				  FROM csr.region_role_member rrm
				  JOIN csr.flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid  
				 WHERE rrm.app_sid = fi.app_sid
				   AND rrm.region_sid = fir.region_sid
				   AND rrm.user_sid = v_user_sid
				   AND fsr.flow_state_id = fi.current_state_id
			)
			OR EXISTS (
				SELECT 1
				  FROM csr.flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid 
				 WHERE act.act_id = v_act
				   AND fsr.flow_state_id = fi.current_state_id
			));
END;

PROCEDURE GetPermissibleTransitions(
	in_flow_item_id		IN flow_item.flow_item_id%TYPE,
	out_transitions_cur	OUT SYS_REFCURSOR 
)
AS
	v_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	OPEN out_transitions_cur FOR 
		SELECT DISTINCT verb, fst.pos, fst.flow_state_transition_id
		  FROM flow_item fi
		  JOIN flow_item_region fir on fir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid
		  JOIN flow_state_transition fst ON fst.from_state_id = fs.flow_state_id
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND EXISTS (
			   SELECT 1
				 FROM region_role_member rrm 
				 JOIN flow_state_transition_role fstr ON rrm.role_sid = fstr.role_sid
				WHERE fstr.flow_state_transition_id = fst.flow_state_transition_id
				  AND rrm.app_sid = fi.app_sid
				  AND rrm.region_sid = fir.region_sid
				  AND rrm.user_sid = v_user_sid
		   );
END;

FUNCTION HasPermissionsOnTransition(
	in_flow_item_id					IN flow_item.flow_item_id%TYPE,
	in_flow_state_transition_id		IN flow_state_transition.flow_state_transition_id%TYPE
) RETURN NUMBER
AS
	v_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_region_sids_t		security.T_SID_TABLE;
	v_has_perm			NUMBER;
BEGIN

	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_has_perm	 
	  FROM flow_state_transition_role fstr
	  JOIN region_role_member rrm ON rrm.role_sid = fstr.role_sid 
	   AND rrm.user_sid = v_user_sid 
	 WHERE flow_state_transition_id = in_flow_state_transition_id
	   AND rrm.region_sid IN (
		   SELECT fir.region_sid
			 FROM flow_item_region fir
			WHERE fir.flow_item_id = in_flow_item_id
	   );

	RETURN v_has_perm;
END;

FUNCTION GetToStateId(
	in_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE
) RETURN NUMBER
AS	v_to_state_id 	flow_state.flow_state_id%TYPE;
BEGIN
	SELECT to_state_id
	  INTO v_to_state_id
	  FROM flow_state_transition
	 WHERE flow_state_transition_id = in_transition_id;

	RETURN v_to_state_id;
END;

FUNCTION GetNatureOfState(
	in_flow_state_id	IN flow_state.flow_state_id%TYPE
) RETURN NUMBER
AS	v_flow_state_nature_id 	flow_state.flow_state_nature_id%TYPE;
BEGIN
	SELECT flow_state_nature_id
	  INTO v_flow_state_nature_id
	  FROM flow_state
	 WHERE flow_state_id = in_flow_state_id;

	RETURN v_flow_state_nature_id;
END;

PROCEDURE VerifyFlowItemExists(
	in_flow_item_id 	IN flow_item.flow_item_id%TYPE
)
AS
	v_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item
	 WHERE flow_item_id = in_flow_item_id;

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END IF;
END;

PROCEDURE GetCurStateTransitions_UNSEC(
	in_flow_item_id 		IN flow_item.flow_item_id%TYPE,
	out_transitions_cur		OUT SYS_REFCURSOR,
	out_roles_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	VerifyFlowItemExists(in_flow_item_id);

	OPEN out_transitions_cur FOR
		SELECT verb, fst.pos, fst.flow_state_transition_id, fst.ask_for_comment, fst.to_state_id, fst.enforce_validation
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
		 WHERE fi.flow_item_id = in_flow_item_id;

	OPEN out_roles_cur FOR
		SELECT group_sid, NULL flow_involvement_type_id, fst.flow_state_transition_id
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
		  JOIN flow_state_transition_role fstr ON fstr.flow_state_transition_id = fst.flow_state_transition_id
		 WHERE fi.flow_item_id = in_flow_item_id
		 UNION 
		SELECT NULL group_sid, flow_involvement_type_id, fst.flow_state_transition_id
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
		  JOIN flow_state_transition_inv fsti ON fsti.flow_state_transition_id = fst.flow_state_transition_id
		 WHERE fi.flow_item_id = in_flow_item_id;
END;

PROCEDURE GetCurStateCapabilities_UNSEC(
	in_flow_item_id 		IN flow_item.flow_item_id%TYPE,
	out_capabilities_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	VerifyFlowItemExists(in_flow_item_id);

	OPEN out_capabilities_cur FOR
		SELECT DISTINCT fsrc.flow_state_id, fsrc.group_sid, fsrc.flow_involvement_type_id, fc.description flow_capability_name, fsrc.permission_set
		  FROM flow_item fi
		  JOIN flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
		  JOIN flow_capability fc ON fc.flow_capability_id = fsrc.flow_capability_id
		 WHERE fi.flow_item_id = in_flow_item_id;
END;

PROCEDURE SetItemState_SEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	out_flow_state_log_id	OUT flow_state_log.flow_state_log_id%TYPE
)
AS
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	IF HasPermissionsOnTransition(in_flow_item_id, in_transition_id) = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'User with SID:'||SYS_CONTEXT('SECURITY', 'SID')||' doesn''t have permissions on transition with id:'||in_transition_id||' for flow item id:'||in_flow_item_id);
	END IF;

	SetItemState(
		in_flow_item_id			=> in_flow_item_id,
		in_to_state_Id			=> GetToStateId(in_transition_id),
		in_comment_text			=> in_comment_text,
		in_cache_keys			=> v_cache_keys,
		in_user_sid				=> SYS_CONTEXT('SECURITY','SID'),
		in_force				=> 0,
		in_cancel_alerts		=> 0,
		out_flow_state_log_id	=> out_flow_state_log_id
	);
END;

PROCEDURE AddFlowItemRegion(
	in_flow_item_id		IN flow_item.flow_item_id%TYPE,
	in_region_sid		IN security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO flow_item_region(flow_item_id, region_sid)
		VALUES(in_flow_item_id, in_region_sid);
END;

PROCEDURE GetStateTransitionDetail(
	in_flow_transition_id			IN	flow_state_transition.flow_state_transition_id%TYPE,
	out_detail						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_detail FOR
		SELECT fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.flow_state_nature_id,
			pfs.flow_state_id prev_flow_state_id, pfs.label prev_flow_state_label, pfs.lookup_key prev_flow_state_lookup_key,
			pfs.flow_state_nature_id prev_flow_state_nature_id
		  FROM flow_state_transition fst
		  JOIN flow_state fs ON fs.flow_state_id = fst.to_state_id
		  JOIN flow_state pfs ON pfs.flow_state_id = fst.from_state_id
		 WHERE fst.flow_state_transition_id = in_flow_transition_id;
END;

PROCEDURE GetFlowStateSurveyTags_UNSEC(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	out_flow_state_tags_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_flow_state_tags_cur FOR
		SELECT fsst.tag_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id
		  JOIN csr.flow_state_survey_tag fsst ON fs.flow_state_id = fsst.flow_state_id
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND fi.app_sid = security_pkg.getApp;
END;

FUNCTION GetFlowIsSurveyEditable(
	in_flow_item_id	IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER
AS
	v_is_survey_editable 	flow_state.survey_editable%TYPE;
BEGIN
	SELECT survey_editable
	  INTO v_is_survey_editable
	  FROM flow_item fi
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	 WHERE fi.flow_item_id = in_flow_item_id;

	RETURN v_is_survey_editable;
END;

PROCEDURE GetFlowState_UNSEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	out_flow_state_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_flow_state_cur FOR 
		SELECT fs.label flow_state_label, fs.state_colour, fsn.label flow_state_nature_label
		  FROM flow_item fi
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
		 WHERE fi.flow_item_id = in_flow_item_id;
END;

PROCEDURE GetStateByFlowItemIds_UNSEC(
	in_flow_item_ids				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_item_ids					security.T_SID_TABLE;
BEGIN
	v_flow_item_ids := security_pkg.SidArrayToTable(in_flow_item_ids);

	OPEN out_cur FOR
		SELECT fi.flow_item_id, fs.label
		  FROM flow_item fi
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE fi.flow_item_id IN (SELECT column_value FROM TABLE(v_flow_item_ids));
END;

FUNCTION GetFlowAlerts(
	in_flow_alert_class		IN	flow.flow_alert_class%TYPE
)
RETURN T_FLOW_ALERT_TABLE
AS
	v_flow_alert_tab	T_FLOW_ALERT_TABLE;
BEGIN
	SELECT csr.T_FLOW_ALERT_ROW(x.app_sid, x.flow_state_transition_id, x.flow_item_generated_alert_id,
		   x.customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label,
		   x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
		   x.to_user_sid, x.flow_alert_helper, x.to_user_name, x.to_full_name, x.to_email,
		   x.to_friendly_name, x.to_initiator, x.flow_item_id, x.flow_transition_alert_id,
		   x.comment_text, x.set_dtm)
	  BULK COLLECT INTO v_flow_alert_tab 
	  FROM csr.v$open_flow_item_gen_alert x
	  JOIN csr.flow_item fi ON x.flow_item_id = fi.flow_item_id AND x.app_sid = fi.app_sid
	  JOIN csr.flow f ON f.flow_sid = fi.flow_Sid
	 WHERE f.flow_alert_class = in_flow_alert_class;

	RETURN v_flow_alert_tab;
END;

PROCEDURE GetCampaignFlows(
	in_parent_sid		IN		security.security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
)
AS
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.getACT, in_parent_sid, security.security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED,
			'Permission denied listing contents on the workflow container object with sid '||in_parent_sid);
	END IF;

	OPEN out_flow_cur FOR
		SELECT f.flow_sid, f.label, f.flow_alert_class,
			   dfs.flow_state_id default_flow_state_id, dfs.label default_flow_state_label,
			   COUNT(fs.flow_state_id) state_cnt, DECODE(COUNT(fsrc.flow_state_rl_cap_id), 0, 0, 1) has_editable_default_state
		  FROM csr.flow f
		  JOIN security.securable_object so ON f.flow_sid = so.sid_id AND so.parent_sid_id = in_parent_sid
		  LEFT JOIN csr.flow_state dfs ON f.default_state_id = dfs.flow_state_id AND f.app_sid = dfs.app_sid
		  LEFT JOIN csr.flow_state fs ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid AND fs.is_deleted = 0
		  LEFT JOIN csr.flow_state_role dfsr ON f.default_state_id = dfsr.flow_state_id AND f.app_sid = dfsr.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = dfsr.flow_state_id
		   AND fsrc.role_sid = dfsr.role_sid
		   AND fsrc.flow_capability_id = csr.csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
		   AND BITAND(permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE
		   AND fsrc.app_sid = dfsr.app_sid
		 GROUP BY f.flow_sid, f.label, f.flow_alert_class, dfs.flow_state_id, dfs.label;
END;

PROCEDURE ArchiveOldFlowItemGenEntries
AS
	v_arch_prior_to_timestamp	DATE := SYSDATE - 15;
BEGIN
	security.user_pkg.LogonAdmin;

	INSERT INTO flow_item_gen_alert_archive (app_sid, flow_item_generated_alert_id,
		flow_transition_alert_id, from_user_sid, to_user_sid, to_column_sid, flow_item_id,
		flow_state_log_id, processed_dtm, created_dtm, subject_override, body_override)
	SELECT app_sid, flow_item_generated_alert_id,
		flow_transition_alert_id, from_user_sid, to_user_sid, to_column_sid, flow_item_id,
		flow_state_log_id, processed_dtm, created_dtm, subject_override, body_override
	  FROM flow_item_generated_alert figa
	 WHERE figa.processed_dtm < v_arch_prior_to_timestamp
	   AND NOT EXISTS (
			SELECT NULL
			  FROM flow_item_gen_alert_archive figaa
			 WHERE figaa.app_sid = figa.app_sid
			   AND figaa.flow_item_generated_alert_id = figa.flow_item_generated_alert_id
		);

	DELETE FROM flow_item_generated_alert
	 WHERE processed_dtm < v_arch_prior_to_timestamp;

	security.user_pkg.Logoff(SYS_CONTEXT('SECURITY','ACT'));
END;

FUNCTION GetOrCreateFlow (
	in_workflow_label		IN	flow.label%TYPE,
	in_flow_alert_class		IN	flow.flow_alert_class%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_workflow_sid 			security.security_pkg.T_SID_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
BEGIN
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/' || in_workflow_label);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');	
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please run csr\db\utils\enableworkflow.sql first');
			END;

			BEGIN
				SELECT cfac.flow_alert_class 
				  INTO v_flow_type
				  FROM csr.customer_flow_alert_class cfac
				  JOIN csr.flow_alert_class fac
				    ON cfac.flow_alert_class = fac.flow_alert_class
				 WHERE cfac.app_sid = security.security_pkg.GetApp
				   AND cfac.flow_alert_class = in_flow_alert_class;
			EXCEPTION 
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please enable the ' || in_flow_alert_class || ' module first');
			END; 
			
			-- create our workflow
			csr.flow_pkg.CreateFlow(
				in_label			=> in_workflow_label, 
				in_parent_sid		=> v_wf_ct_sid, 
				in_flow_alert_class	=> in_flow_alert_class,
				out_flow_sid		=> v_workflow_sid
			);
	END;
	
	RETURN v_workflow_sid;
END;

END;
/