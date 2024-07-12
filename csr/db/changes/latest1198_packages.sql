CREATE OR REPLACE PACKAGE CSR.flow_pkg AS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashFlow(
	in_flow_sid		IN security_pkg.T_SID_ID
);

PROCEDURE CreateFlow(
	in_label			IN	flow.label%TYPE,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_flow_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE RenameFlow(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_label		IN	flow.label%TYPE
);

PROCEDURE GetFlows(
	in_parent_sid		IN		security_pkg.T_SID_ID,
	out_flow_cur		OUT		SYS_REFCURSOR
);

PROCEDURE GetFlow(
	in_flow_sid				IN		security_pkg.T_SID_ID,
	out_flow_cur			OUT		SYS_REFCURSOR,
	out_state_cur			OUT		SYS_REFCURSOR,
	out_state_role_cur		OUT		SYS_REFCURSOR,
	out_trans_cur			OUT		SYS_REFCURSOR,
	out_trans_role_cur		OUT		SYS_REFCURSOR,
	out_trans_helper_cur	OUT		SYS_REFCURSOR
);

PROCEDURE CreateState(
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_label			IN	flow_state.label%TYPE,
	in_lookup_key		IN	flow_state.lookup_key%TYPE DEFAULT NULL,
	out_flow_state_id	OUT	flow_state.flow_state_id%TYPE
);

PROCEDURE SetStateTransHelper(	
	in_flow_sid		IN 	security_pkg.T_SID_ID,
	in_helper_sp	IN	flow_state_trans_helper.helper_sp%TYPE,
	in_label		IN	flow_state_trans_helper.label%TYPE
);

PROCEDURE SetDefaultStateId(
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE
);

PROCEDURE SetStateRoles(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_editable_role_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_role_sids	IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteState(
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_move_items_to	IN	flow_state.flow_state_id%TYPE DEFAULT NULL 
);

PROCEDURE AmendState(
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_label			IN	flow_state.label%TYPE,
	in_lookup_key		IN	flow_state.lookup_key%TYPE
);

PROCEDURE SetTransition(
	in_from_state_id				IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id					IN	flow_state_transition.to_state_id%TYPE,
	in_verb							IN	flow_state_transition.verb%TYPE,  
	in_lookup_key					IN	flow_state_transition.lookup_key%TYPE,  
	in_helper_sp					IN 	flow_state_transition.helper_sp%TYPE,
	in_ask_for_comment				IN	flow_state_transition.ask_for_comment%TYPE DEFAULT 'optional',
	in_mandatory_fields_message		IN	flow_state_transition.mandatory_fields_message%TYPE,
	in_button_icon_path				IN	flow_state_transition.button_icon_path%TYPE,
	in_pos							IN	flow_state_transition.pos%TYPE,
	in_role_sids					IN	security_pkg.T_SID_IDS,
	out_transition_id				OUT	flow_state_transition.flow_state_transition_id%TYPE
);

PROCEDURE RemoveTransition(
	in_from_state_id	IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id		IN	flow_state_transition.to_state_id%TYPE
);

FUNCTION GetStateId(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_lookup_key	IN	flow_state.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION GetNextStateID
RETURN flow_state.flow_state_id%TYPE;


PROCEDURE SetFlowFromXml(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_xml			IN	XMLType
);

PROCEDURE NewFlowAlertType(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	flow_alert_type.label%TYPE,
	out_customer_alert_type_id	OUT	customer_alert_type.customer_alert_type_Id%TYPE
);

PROCEDURE MarkFlowItemAlertsProcessed(
	in_flow_item_alert_ids	IN	security_pkg.T_SID_IDS
);

PROCEDURE AddApprovalDashboardInstance(
	in_dashboard_instance_id	IN	approval_dashboard_instance.dashboard_instance_id%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddQuickSurveyResponse(
	in_survey_response_id	IN	flow_item.survey_response_id%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	out_flow_item_id		OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE AddCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sid				IN	region.region_sid%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT sYS_CONTEXT('SECURITY','SID')
);

FUNCTION GetToStateIdFromLookupKey(
	in_from_state_id	IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY
) RETURN csr_data_pkg.T_FLOW_STATE_ID;

FUNCTION GetTransitionLookupKey(
	in_transition_id	IN	csr_data_pkg.T_FLOW_STATE_TRANSITION_ID
) RETURN csr_data_pkg.T_LOOKUP_KEY;

FUNCTION GetStateLookupKey(
	in_state_id	IN	csr_data_pkg.T_FLOW_STATE_ID
) RETURN csr_data_pkg.T_LOOKUP_KEY;

FUNCTION SQL_HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID
) RETURN NUMBER;

-- will anyone be able to see thing in this state, for the given region?
FUNCTION HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE GetChangeLog(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION GetFlowItemIsEditable(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN NUMBER;

END;
/









CREATE OR REPLACE PACKAGE BODY CSR.flow_pkg AS


/*
 email alerts on state change (email different roles / define custom messages)
   - do as "states?" (.e.g like timer state)
   
 call stored procs
 
 associate dates with status changes? (compelted on X) maybe not generic
*/

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
	DELETE FROM flow_item_alert
	 WHERE flow_state_transition_id IN (
		SELECT flow_state_transition_id
		  FROM flow_state_transition
		 WHERE flow_sid = in_sid_id
	 );
	 
	DELETE FROM flow_state_transition_role
	 WHERE flow_state_transition_id IN (
		SELECT flow_state_transition_id
		  FROM flow_state_transition
		 WHERE flow_sid = in_sid_id
	 );
	 
	DELETE FROM flow_transition_alert_role
	 WHERE flow_state_transition_id IN (
		SELECT flow_state_transition_id
		  FROM flow_state_transition
		 WHERE flow_sid = in_sid_id
	 );

	UPDATE csr.property
	   SET flow_item_id = NULL
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE flow_sid = in_sid_id
	 );
	 
	DELETE FROM flow_transition_alert
	 WHERE flow_state_transition_id IN (
		SELECT flow_state_transition_id
		  FROM flow_state_transition
		 WHERE flow_sid = in_sid_id
	 );
	 
	DELETE FROM flow_alert_type 
	 WHERE flow_sid = in_sid_id;
	  
	DELETE FROM flow_state_transition
	 WHERE flow_sid = in_sid_Id;
	
	DELETE FROM flow_state_log
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );
	
	DELETE FROM flow_item
	 WHERE flow_sid = in_sid_id;
	 
	DELETE FROM flow_state_role
	 WHERE flow_state_id IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_sid_id
	 );

	DELETE FROM cms.flow_tab_column_cons
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

	DELETE FROM flow
	 WHERE flow_sid = in_sid_id;
	
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
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
	securableobject_pkg.CreateSO(security_pkg.getACT,
		in_parent_sid, 
		class_pkg.getClassID('CSRFlow'),
		REPLACE(in_label,'/','\'), --'
		out_flow_sid);	
	
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
		out_flow_sid,
		'Created workflow "{0}"', 
		in_label);

	INSERT INTO FLOW (flow_sid, label)
		VALUES (out_flow_sid, in_label);
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

PROCEDURE GetFlows(
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
		SELECT f.flow_sid, f.label, dfs.label default_flow_state_label, COUNT(fs.flow_state_id) state_cnt
		  FROM flow f
			JOIN security.securable_object so ON f.flow_sid = so.sid_id AND so.parent_sid_id = in_parent_sid
			LEFT JOIN flow_state dfs ON f.default_state_id = dfs.flow_state_id AND f.app_sid = dfs.app_sid
			LEFT JOIN flow_state fs ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
         GROUP BY f.flow_sid, f.label, dfs.label;
END;


PROCEDURE GetFlow(
	in_flow_sid				IN		security_pkg.T_SID_ID,
	out_flow_cur			OUT		SYS_REFCURSOR,
	out_state_cur			OUT		SYS_REFCURSOR,
	out_state_role_cur		OUT		SYS_REFCURSOR,
	out_trans_cur			OUT		SYS_REFCURSOR,
	out_trans_role_cur		OUT		SYS_REFCURSOR,
	out_trans_helper_cur	OUT		SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||in_flow_sid);
	END IF;	
	
	OPEN out_flow_cur FOR
		SELECT flow_sid, label, default_state_id
		  FROM flow
		 WHERE flow_sid = in_flow_sid;
		 
	OPEN out_state_cur FOR
		-- sorted so that default state is first
		SELECT fs.flow_state_id, fs.label, fs.lookup_Key, fs.attributes_xml
		  FROM flow_state fs
		  JOIN flow f ON fs.flow_sid = f.flow_sid AND fs.app_sid = f.app_sid
		 WHERE fs.flow_sid = in_flow_sid
		   AND fs.is_deleted = 0
		 ORDER BY CASE WHEN f.default_state_id = fs.flow_state_id THEN 1 ELSE 0 END DESC;
	
	OPEN out_state_role_cur FOR
		SELECT flow_state_id, fsr.role_sid, r.name role_name, fsr.is_editable
		  FROM flow_state_role fsr
		  JOIN role r ON fsr.role_sid = r.role_sid
		 WHERE flow_state_id IN (
			SELECT flow_state_id 
			  FROM flow_state
			 WHERE flow_sid = in_flow_sid
				AND is_deleted = 0
		 );
		 
	OPEN out_trans_cur FOR
		SELECT flow_state_transition_id, from_state_id, to_state_id, verb, lookup_key, ask_for_comment, 
			   mandatory_fields_message, button_icon_path, attributes_xml, helper_sp
		  FROM flow_state_transition fst
		 WHERE flow_sid = in_flow_sid
		 ORDER BY from_state_id, pos; -- need this for ordering the XML
		 
	OPEN out_trans_role_cur FOR
		SELECT flow_state_transition_id, fstr.role_sid, r.name role_name
		  FROM flow_state_transition_role fstr
		  JOIN role r ON fstr.role_sid = r.role_sid
		 WHERE flow_state_transition_id IN (
			SELECT flow_state_transition_id 
			  FROM flow_state_transition
			 WHERE flow_sid = in_flow_sid
		 );
		 
	OPEN out_trans_helper_cur FOR
		SELECT helper_sp, label
		  FROM flow_state_trans_helper
		 WHERE flow_sid = in_flow_sid;
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


-- internal use only (i.e. for xml synching)
PROCEDURE CreateState(
	in_flow_state_id	IN  flow_state.flow_state_id%TYPE,
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_label			IN	flow_state.label%TYPE,	
	in_lookup_key		IN	flow_state.lookup_key%TYPE DEFAULT NULL
)
AS
	v_flow_label	flow.label%TYPE;
	v_flow_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;	
	
	INSERT INTO flow_state (flow_state_id, flow_sid, label, lookup_key)
		VALUES (in_flow_state_id, in_flow_sid, in_label, in_lookup_key);

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
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_label			IN	flow_state.label%TYPE,
	in_lookup_key		IN	flow_state.lookup_key%TYPE DEFAULT NULL,	
	out_flow_state_id	OUT	flow_state.flow_state_id%TYPE
)
AS
BEGIN
	SELECT flow_state_id_seq.nextval
	  INTO out_flow_state_Id
	  FROM DUAL;
	
	CreateState(out_flow_state_Id, in_flow_sid, in_label, in_lookup_key);
END;


PROCEDURE SetDefaultStateId(
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE
)
AS
	v_flow_label				flow.label%TYPE;
	v_flow_state_label			flow_state.label%TYPE;
	v_flow_sid					security_pkg.T_SID_ID;
	v_prev_default_state_id		flow.default_state_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;	
	
	SELECT label, default_state_id, flow_sid
	  INTO v_flow_label, v_prev_default_state_id, v_flow_sid
	  FROM flow
	 WHERE flow_sid = in_flow_sid;
	
	IF v_prev_default_state_id != in_flow_state_id THEN
		SELECT label
		  INTO v_flow_state_label
		  FROM flow_state
		 WHERE flow_state_id = in_flow_state_id;
		 
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
			v_flow_sid,
			'Altered workflow "{0}", set default state to "{1}"', 
			v_flow_label, 
			v_flow_state_label);
	END IF;
	
	UPDATE flow
	   SET default_state_id = in_flow_state_id
	 WHERE flow_sid = in_flow_sid;
END;

PROCEDURE SetStateRoles(
	in_state_id					IN	flow_state.flow_state_id%TYPE,
	in_editable_role_sids		IN	security_pkg.T_SID_IDS,
	in_non_editable_role_sids	IN	security_pkg.T_SID_IDS
)
AS
	CURSOR c IS
		SELECT f.flow_sid, f.label flow_label, fs.label state_label
		  FROM flow_state fs  
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE fs.flow_state_id = in_state_id;
	ar	c%ROWTYPE;
    t_editable_role_sids 		security.T_SID_TABLE;
    t_non_editable_role_sids 	security.T_SID_TABLE;
BEGIN
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow state '||in_state_id||' not found');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, ar.flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||ar.flow_sid);
	END IF;	

	-- we audit this, so the long way round (rather than just deleting)
	t_editable_role_sids 		:= security_pkg.SidArrayToTable(in_editable_role_sids);        
	t_non_editable_role_sids	:= security_pkg.SidArrayToTable(in_non_editable_role_sids);        
	
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
	DELETE FROM flow_state_transition_role
	 WHERE flow_state_transition_id IN (
		SELECT flow_state_transition_id
		  FROM flow_state_transition
		 WHERE from_state_id = in_flow_state_id 
		    OR to_state_id = in_flow_state_Id
	 );
	 
	DELETE FROM flow_state_transition
	 WHERE from_state_id = in_flow_state_id 
		OR to_state_id = in_flow_state_Id;
	
	UPDATE flow_state
	   SET is_deleted = 1
	 WHERE flow_state_id = in_flow_state_id;
	
	IF in_move_items_to IS NOT NULL THEN
		UPDATE flow_item
		   SET current_state_id = in_move_items_to
		 WHERE current_state_id = in_flow_state_id;
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
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_label			IN	flow_state.label%TYPE,
	in_lookup_key		IN	flow_state.lookup_key%TYPE
)
AS
	CURSOR c IS
		SELECT fs.flow_sid, fs.label, f.label flow_label, fs.lookup_key
		  FROM flow_state fs	
			JOIN flow f ON fs.flow_sid = f.flow_sid
		 WHERE flow_state_id = in_flow_state_id;
	r	c%ROWTYPE;
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
		r.flow_sid, 'Workflow '||r.flow_label||' state lookup key', r.lookup_key, in_lookup_key);
	
	UPDATE flow_state
	   SET label = in_label, 
		lookup_key = in_lookup_key
	 WHERE flow_state_id = in_flow_state_id;
END;

PROCEDURE SetTransition(
	in_from_state_id				IN	flow_state_transition.from_state_id%TYPE,
	in_to_state_id					IN	flow_state_transition.to_state_id%TYPE,
	in_verb							IN	flow_state_transition.verb%TYPE,  
	in_lookup_key					IN	flow_state_transition.lookup_key%TYPE,  
	in_helper_sp					IN 	flow_state_transition.helper_sp%TYPE,
	in_ask_for_comment				IN	flow_state_transition.ask_for_comment%TYPE DEFAULT 'optional',
	in_mandatory_fields_message		IN	flow_state_transition.mandatory_fields_message%TYPE,
	in_button_icon_path				IN	flow_state_transition.button_icon_path%TYPE,
	in_pos							IN	flow_state_transition.pos%TYPE,
	in_role_sids					IN	security_pkg.T_SID_IDS,
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
    t_role_sids 					security.T_SID_TABLE;
    v_old_verb						flow_state_transition.verb%TYPE;
    v_old_lookup_key				flow_state_transition.lookup_key%TYPE;
    v_old_mandatory_fields_message	flow_state_transition.mandatory_fields_message%TYPE;
    v_old_button_icon_path			flow_state_transition.button_icon_path%TYPE;
    v_old_ask_for_comment			flow_state_transition.ask_for_comment%TYPE;
    v_old_pos						flow_state_transition.pos%TYPE;
BEGIN
	OPEN c;
	FETCH c INTO ar;
	IF c%NOTFOUND THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow states from different workflows, or workflow states not found');
	END IF;

	BEGIN
		INSERT INTO flow_state_transition
			(flow_state_transition_id, flow_sid, from_state_id, to_state_id, verb, lookup_key, ask_for_comment, 
			 mandatory_fields_message, button_icon_path, pos)
		VALUES
			(flow_state_transition_id_seq.nextval, ar.flow_sid, in_from_state_id, in_to_state_id, 
			 in_verb, in_lookup_key, in_ask_for_comment, in_mandatory_fields_message, in_button_icon_path, in_pos)
		RETURNING flow_state_transition_id INTO out_transition_id;
		
		-- audit		
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
			ar.flow_sid,
			'Create transition for workflow "{0}" from "{1}" to "{2}"', 
			ar.flow_label, ar.from_Label, ar.to_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT verb, lookup_key, mandatory_fields_message, ask_for_comment, button_icon_path
			  INTO v_old_verb, v_old_lookup_key, v_old_mandatory_fields_message, v_old_ask_for_comment, v_old_button_icon_path
			  FROM flow_state_transition
			 WHERE from_state_id = in_from_state_id
			   AND to_state_id = in_to_state_id;
		
			-- update
			UPDATE flow_state_transition
			   SET verb = in_verb,
				   lookup_key = in_lookup_key, 
				   mandatory_fields_message = in_mandatory_fields_message,
				   button_icon_path = in_button_icon_path,
				   ask_for_comment = in_ask_for_comment,
				   pos = in_pos
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
		ar.flow_sid, 'Icon path', v_old_button_icon_path, in_button_icon_path, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Comments', v_old_ask_for_comment, in_ask_for_comment, out_transition_id);
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'),
		ar.flow_sid, 'Position', v_old_pos, in_pos, out_transition_id);
	
	-- we ought to audit this, so the long way round (rather than just deleting)
	t_role_sids := security_pkg.SidArrayToTable(in_role_sids);        
	
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
	
	DELETE FROM flow_state_transition_role
	 WHERE flow_state_transition_id IN (
		SELECT flow_state_transition_id 
		  FROM flow_state_transition
		 WHERE from_state_id = in_from_state_id
		   AND to_state_id = in_to_state_Id
	 );
	 
	DELETE FROM flow_state_transition
	 WHERE from_state_id = in_from_state_id
	   AND to_state_id = in_to_state_Id;
	
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
	SELECT flow_state_id
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

-- private
FUNCTION SidListToArray(
	in_role_sid_list	VARCHAR2
) RETURN security_pkg.T_SID_IDS
AS
	v_role_sids		security_pkg.T_SID_IDS;
BEGIN
	-- bit icky -- i.e. random spacing etc would probably blow this up
	IF in_role_sid_list IS NOT NULL THEN
		 SELECT TO_NUMBER(REGEXP_SUBSTR(in_role_sid_list, '[^,]+',1,ROWNUM))
		   BULK COLLECT INTO v_role_sids
		   FROM DUAL
		 CONNECT BY ROWNUM <= (LENGTH(in_role_sid_list) - LENGTH(REPLACE(in_role_sid_list,',')) + 1);				
	ELSE
		SELECT null
		  BULK COLLECT INTO v_role_sids
		  FROM DUAL;
	END IF;
	
	RETURN v_role_sids;
END;		

PROCEDURE SetFlowFromXml(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	in_xml			IN	XMLType
)
AS
	v_flow_label				flow.label%TYPE;
	v_default_state_id			flow_state.flow_state_id%TYPE;
	t_state						T_FLOW_STATE_TABLE;
	t_trans						T_FLOW_STATE_TRANS_TABLE;
	v_transition_id				flow_state_transition.flow_state_transition_id%TYPE;
	v_role_sids					security_pkg.T_SID_IDS;
	v_editable_role_sids		security_pkg.T_SID_IDS;
	v_non_editable_role_sids	security_pkg.T_SID_IDS;
BEGIN
	SELECT EXTRACT(in_xml,'/flow/@label').getStringVal()
	  INTO v_flow_label
	  FROM dual;
     
    RenameFlow(in_flow_sid, v_flow_label);
      
    /****************** process states *********************/
	SELECT T_FLOW_STATE_ROW(xt.pos, xt.id, xt.label, xt.lookup_key, REPLACE(xt.editable_role_sids,' ',','), 
		REPLACE(xt.non_editable_role_sids,' ',','), xt.attributes_xml)
	  BULK COLLECT INTO t_state
	  FROM XMLTABLE(
		 'for $i in /flow/state
			 return
		        <state id="{$i/@id}" label="{$i/@label}" lookup-key="{$i/@lookup-key}">
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
                </state>'
		PASSING in_xml
		COLUMNS
			pos              		FOR ORDINALITY,
			id               		NUMBER(10) PATH '@id',
			label            		VARCHAR2(255) PATH '@label',
			lookup_key       		VARCHAR2(255) PATH '@lookup-key',
            editable_role_sids      VARCHAR2(2000) PATH 'editable-role-sids',
            non_editable_role_sids	VARCHAR2(2000) PATH 'non-editable-role-sids',
			attributes_xml   		XMLTYPE PATH 'attributes'
		)xt;
    
	-- delete states
    FOR r IN (
		SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid AND is_deleted = 0
		  MINUS
		SELECT id FROM TABLE(t_state)		
    )
    LOOP
		flow_pkg.DeleteState(r.flow_state_id, null); -- assume something has cleaned items up
    END LOOP;
    
    -- update states
    FOR r IN (
		SELECT pos, id, label, lookup_key, editable_role_sids, non_editable_role_sids, attributes_xml
		  FROM TABLE(t_state)
		 WHERE id IN (
			SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid
		 )
    )
    LOOP
		flow_pkg.AmendState(r.id, r.label, r.lookup_key);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state
		   SET attributes_xml = r.attributes_xml
		 WHERE flow_state_id = r.id;
		 
		v_editable_role_sids     := SidListToArray(r.editable_role_sids);
		v_non_editable_role_sids := SidListToArray(r.non_editable_role_sids);
		SetStateRoles(r.id, v_editable_role_sids, v_non_editable_role_sids);
    END LOOP;
    
    -- create states
    FOR r IN (
		SELECT pos, id, label, lookup_key, editable_role_sids, non_editable_role_sids, attributes_xml
		  FROM TABLE(t_state)
		 WHERE id NOT IN (
			SELECT flow_state_id FROM flow_state WHERE flow_sid = in_flow_sid
		 )
    )
    LOOP
		flow_pkg.CreateState(r.id, in_flow_sid, r.label, r.lookup_key);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state
		   SET attributes_xml = r.attributes_xml
		 WHERE flow_state_id = r.id;
		 		 
		v_editable_role_sids     := SidListToArray(r.editable_role_sids);
		v_non_editable_role_sids := SidListToArray(r.non_editable_role_sids);
		SetStateRoles(r.id, v_editable_role_sids, v_non_editable_role_sids);
    END LOOP;
    
    /****************** process transitions *********************/	
	SELECT T_FLOW_STATE_TRANS_ROW(xt.pos, xt.id, xt.from_state_id, xt.to_state_id, 
			NVL(xt.ask_for_comment,'optional'), xt.mandatory_fields_message, xt.button_icon_path, xt.verb, 
			xt.lookup_key, xt.helper_sp, REPLACE(xt.role_sids,' ',','), xt.attributes_xml)
	  BULK COLLECT INTO t_trans
	  FROM XMLTABLE(
		'for $i in /flow/state/transition
			return  
                <tr from-state-id="{$i/../@id}" to-state-id="{$i/@to-state-id}" lookup-key="{$i/@lookup-key}" 
					helper-sp="{$i/@helper-sp}" verb="{$i/@verb}" ask-for-comment="{$i/@ask-for-comment}" 
					mandatory-fields-message="{$i/@mandatory-fields-message}"
					button-icon-path="{$i/@button-icon-path}">
                    {$i/attributes}
                    <role-sids>
                    { for $j in $i/role
                        return string ($j/@sid)
                    }
                    </role-sids>
                </tr>'
		PASSING in_xml
		COLUMNS
			pos							FOR ORDINALITY,
			id							NUMBER(10) PATH '@id',
			from_state_id				NUMBER(10) PATH '@from-state-id',
			to_state_id					NUMBER(10) PATH '@to-state-id',
			ask_for_comment				VARCHAR2(16) PATH '@ask-for-comment',
			mandatory_fields_message	VARCHAR2(255) PATH '@mandatory-fields-message',
			button_icon_path			VARCHAR2(255) PATH '@button-icon-path',
			lookup_key					VARCHAR2(255) PATH '@lookup-key',
			helper_sp					VARCHAR2(255) PATH '@helper-sp',
			verb						VARCHAR2(255) PATH '@verb',
            role_sids					VARCHAR2(2000) PATH 'role-sids',
			attributes_xml				XMLTYPE PATH 'attributes'
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
		SELECT pos, id, from_state_id, to_state_id, ask_for_comment, mandatory_fields_message,
			   button_icon_path, verb, lookup_key, helper_sp, role_sids, attributes_xml
		  FROM TABLE(t_trans)
    )
    LOOP
		v_role_sids := SidListToArray(r.role_sids);
		
		flow_pkg.SetTransition(r.from_state_id, r.to_state_id, r.verb, r.lookup_key, r.helper_sp, 
			r.ask_for_comment, r.mandatory_fields_message, r.button_icon_path, r.pos, v_role_sids, v_transition_id);
		-- attribute stuff is really for the Flash stuff for storing coordinates etc so we've not put this into the SP interface
		UPDATE flow_state_transition
		   SET attributes_xml = r.attributes_xml, helper_sp = r.helper_sp
		 WHERE flow_state_transition_id = v_transition_id;
    END LOOP;
    
    SELECT default_state_id
      INTO v_default_state_id
      FROM flow
     WHERE flow_sid = in_flow_sid;
     
    IF v_default_state_id IS NULL THEN
		RAISE csr_data_pkg.FLOW_HAS_NO_DEFAULT_STATE;
    END IF;
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
	-- XXX: should we complain if there isn't a helper? We're fairly stuffed it it's not present since we'll have no alert parameters etc
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM flow
	 WHERE flow_sid = in_flow_sid;
	
	IF v_helper_pkg IS NOT NULL THEN
	    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.NewFlowAlertType(:1,:2);end;'
			USING in_flow_sid, out_customer_alert_type_id;
	END IF;
END;



PROCEDURE MarkFlowItemAlertsProcessed(
	in_flow_item_alert_ids	IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	FORALL i IN in_flow_item_alert_ids.FIRST..in_flow_item_alert_ids.LAST
		UPDATE flow_item_alert 
		   SET processed_dtm = SYSDATE
		 WHERE flow_item_alert_id = in_flow_item_alert_ids(i);
	 
	COMMIT;
END;


FUNCTION AddToLog(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE DEFAULT NULL,
	in_user_sid				IN	security_pkg.T_SID_ID DEFAULT sYS_CONTEXT('SECURITY','SID')
) RETURN flow_state_log.flow_state_log_id%TYPE
AS
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	INSERT INTO flow_state_log
		(flow_state_log_id, flow_item_id, flow_state_id, set_by_user_sid, comment_text)
		SELECT flow_state_log_id_seq.nextval, in_flow_item_id, current_state_id, 
			in_user_sid, in_comment_text
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	
	SELECT flow_state_log_id_seq.currval INTO v_flow_state_log_id FROM DUAL;
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
	
	INSERT INTO FLOW_ITEM (flow_item_id, flow_sid, current_state_id, survey_response_id)
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

PROCEDURE AddCmsItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_region_sid				IN	region.region_sid%TYPE,	
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_default_state_id		flow.default_state_id%TYPE;
	v_count					NUMBER;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	-- check if the logged on user can see the default state based on the region
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow f, flow_state fs, flow_state_role fsr, region_role_member rrm
	 WHERE f.flow_sid = in_flow_sid
	   AND f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
	   AND fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
	   AND fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
	   AND rrm.region_sid = in_region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID');

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 
			'The flow with sid '||in_flow_sid||' has no default state available for the region with sid '||
			in_region_sid||' and the user with sid '||SYS_CONTEXT('SECURITY', 'SID'));
	END IF;
	
	SELECT default_state_id
	  INTO v_default_state_id
	  FROM flow
	 WHERE flow_sid = in_flow_sid;
	
	INSERT INTO flow_item
		(flow_item_id, flow_sid, current_state_id)
	VALUES
		(flow_item_id_seq.NEXTVAL, in_flow_sid, v_default_state_id)
	RETURNING
		flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := AddToLog(in_flow_item_id => out_flow_item_id);
END;

-- generic proc -- needs to check the roles table etc? i.e. provide implementation specific functions
-- which call this internal version?
PROCEDURE SetItemState(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_user_sid			IN	security_pkg.T_SID_ID	DEFAULT sYS_CONTEXT('SECURITY','SID')
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
	v_lookup_key				flow_state_transition.lookup_key%TYPE;
	v_flow_state_transition_id	flow_state_transition.flow_state_transition_id%TYPE;	
	v_flow_state_log_id			flow_state_log.flow_state_log_id%TYPE;
BEGIN
	-- lock it
	OPEN c;
	FETCH c INTO rfi;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'Flow item id '||in_flow_item_id||' not found.');
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
			RAISE_APPLICATION_ERROR(-20001, 'Transition for item id '||in_flow_item_id||', from state id '||rfi.current_state_Id||' to state id '||in_to_state_id||' is invalid.');
	END;
	
	UPDATE flow_item
	   SET current_state_id = in_to_state_id
	 WHERE flow_item_id = in_flow_item_id;
	
	v_flow_state_log_id := AddToLog(in_flow_item_id, in_comment_text, in_user_sid);	
	
	-- mark any unprocessed alerts as not to be processed -- no point in notifying people
	-- if things have moved on.
	UPDATE flow_item_alert
	   SET processed_dtm = SYSDATE
	 WHERE flow_item_Id = in_flow_item_id
	   AND processed_dtm IS NULL;
	
	-- insert any new alerts
	INSERT INTO flow_item_alert (flow_item_alert_id, flow_item_id, flow_state_log_id, flow_state_transition_id, customer_alert_type_id)
		SELECT flow_item_alert_id_seq.nextval, in_flow_item_id, v_flow_state_log_id, flow_state_transition_id, customer_alert_type_id
		  FROM flow_transition_alert
		 WHERE flow_state_transition_id = v_flow_state_transition_id;
	
	-- fire sp?
	IF v_helper_sp IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_sp||'(:1,:2,:3,:4,:5,:6,:7);end;'
			USING rfi.flow_sid, in_flow_item_id, rfi.current_state_id, in_to_state_id, v_lookup_key, in_comment_text, in_user_sid;	
	END IF;
END;


PROCEDURE GetChangeLog(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_now_dtm	DATE;
BEGIN
	v_now_dtm := SYSDATE;
	-- TODO: how do we secure this stuff?
	OPEN out_cur FOR
		SELECT fsl.flow_state_Id, cu.full_name set_by_full_name, fs.label set_to_state_label, set_dtm, comment_text, v_now_dtm now_dtm
		  FROM flow_state_log fsl
			JOIN csr_user cu ON fsl.set_by_user_sid = cu.csr_user_sid
			JOIN flow_state fs ON fsl.flow_state_Id = fs.flow_state_id
		 WHERE flow_item_id = in_flow_item_id
		 ORDER BY flow_state_log_id DESC;
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

FUNCTION GetTransitionLookupKey(
	in_transition_id	IN	csr_data_pkg.T_FLOW_STATE_TRANSITION_ID
) RETURN csr_data_pkg.T_LOOKUP_KEY
AS
	v_key				csr_data_pkg.T_LOOKUP_KEY;
BEGIN
	-- no security but it's hardly leaking anything of value
	SELECT MIN(lookup_key) -- min() to avoid NO_DATA_FOUND -- i.e. null just means nothing found.
	  INTO v_key
	  FROM flow_state_transition
	 WHERE flow_state_transition_id = in_transition_id;
	
	RETURN v_key; -- null means nothing found
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


-- will anyone be able to see thing in this state, for the given region?
FUNCTION HasRoleMembersForRegion(
    in_flow_state_id    IN  csr_data_pkg.T_FLOW_STATE_ID,
    in_region_sid       IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
    v_cnt   NUMBER(10);
BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM region r 
        JOIN region_role_member rrm on r.region_sid = rrm.region_sid AND r.app_sid = rrm.app_sid
        JOIN role ro ON rrm.role_sid = ro.role_sid AND rrm.app_sid = ro.app_sid
        JOIN flow_state_transition_role fsr ON ro.role_sid = fsr.role_sid AND ro.app_sid = fsr.app_sid AND fsr.from_state_id = in_flow_state_id
		JOIN v$active_user cu ON rrm.user_sid = cu.csr_user_sid -- make sure it's active users only
     WHERE r.region_sid = in_region_sid;
    
    IF v_cnt > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;


-- add this stuff in a tab on the edit page
-- for the other tab, show stuff from the audit log using  csr_data_pkg.GetAuditLogForObject
PROCEDURE GetItemsInFlow(
	in_flow_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check permission....
	-- We use WRITE to indicate the user can administer the flow
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;
	
	OPEN out_cur FOR
		 -- list of things currently in this workflow
		SELECT flow_item_id, current_state_label, item_type, format_string, param_1, param_2, param_3, stragg(role_name) role_names
		  FROM (
			 SELECT fi.flow_item_id, fs.label current_state_label, 
				    'Approval dashboard' item_type, '{1} - {2} ({3})' format_string,
				    ad.label param_1, r.description param_2, val_pkg.formatperiod(di.start_dtm, di.end_dtm, null) param_3,
				    ro.name role_name -- stragg this
			   FROM v$flow_item fi
			   JOIN flow_state fs ON fi.current_state_Id = fs.flow_state_Id
			   JOIN flow_state_role fsr ON fs.flow_state_id = fsr.flow_state_Id
			   JOIN role ro ON fsr.role_sid = ro.role_sid
			   JOIN approval_dashboard_instance di ON fi.dashboard_instance_id = di.dashboard_instance_id
			   JOIN approval_dashboard ad ON di.approval_dashboard_sid = ad.approval_dashboard_sid        
			   JOIN v$region r ON di.region_sid = r.region_sid
			  WHERE fi.flow_sid = in_flow_sid
			  UNION
			 SELECT fi.flow_item_id, fs.label current_state_label, 
				    'Survey' item_type, '{1}' format_string,
				    qs.label param_1, null param_2, null param_3,
				    ro.name role_name -- stragg this
			   FROM v$flow_item fi
			   JOIN flow_state fs ON fi.current_state_Id = fs.flow_state_Id
			   JOIN flow_state_role fsr ON fs.flow_state_id = fsr.flow_state_Id
			   JOIN role ro ON fsr.role_sid = ro.role_sid
			   JOIN quick_survey_response qsr ON fi.survey_response_Id = qsr.survey_response_Id
			   JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
			  WHERE fi.flow_sid = in_flow_sid
		 )
		 GROUP BY flow_item_id, current_state_label, item_type, format_string, param_1, param_2, param_3;
END;

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
	   AND fi.flow_item_id = in_flow_item_id;
	
	RETURN v_is_editable;
END;

END;
/












CREATE OR REPLACE PACKAGE cms.calc_xml_pkg AS

PROCEDURE GenerateCalc(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
);

END;
/

CREATE OR REPLACE PACKAGE BODY cms.calc_xml_pkg AS

PROCEDURE WriteAppend(
	in_clob						IN OUT NOCOPY	CLOB,
	in_str						IN				VARCHAR2
)
AS
BEGIN
	dbms_lob.writeappend(in_clob, LENGTH(in_str), in_str);
END;

PROCEDURE CheckLeftRightNodes(
	in_node							IN	dbms_xmldom.domnode,
	out_left						OUT	dbms_xmldom.domnode,
	out_right						OUT	dbms_xmldom.domnode
)
AS
BEGIN
	out_left := dbms_xslprocessor.selectSingleNode(in_node, 'left/*');
	IF dbms_xmldom.isnull(out_left) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing a left child');
	END IF;
	out_right := dbms_xslprocessor.selectSingleNode(in_node, 'right/*');
	IF dbms_xmldom.isnull(out_right) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing a right child');
	END IF;
END;

PROCEDURE GenerateTest(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
)
AS
	v_op							varchar2(100);
	v_left_node						dbms_xmldom.domnode;
	v_right_node					dbms_xmldom.domnode;
BEGIN
	v_op := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'op');

	v_left_node := dbms_xslprocessor.selectSingleNode(in_node, 'left/*');
	IF dbms_xmldom.isnull(v_left_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'A test node is missing a left child');
	END IF;
	
	GenerateCalc(in_clob, v_left_node);
	IF v_op IN ('null', 'nnull') THEN
		IF v_op = 'nnull' THEN
			WriteAppend(in_clob, ' IS NOT NULL');
		ELSE
			WriteAppend(in_clob, ' IS NULL');
		END IF;
		RETURN;
	END IF;
	
	v_right_node := dbms_xslprocessor.selectSingleNode(in_node, 'right/*');
	IF dbms_xmldom.isnull(v_right_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'A test node is missing a right child');
	END IF;

	IF v_op NOT IN ('=', '!=', '<', '<=', '>', '>=') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown test operator '||v_op);
	END IF;
	WriteAppend(in_clob, ' '||v_op||' ');
	GenerateCalc(in_clob, v_right_node);
END;

PROCEDURE GenerateCondition(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
)
AS
	v_node_name						varchar2(100);
	v_left_node						dbms_xmldom.domnode;
	v_right_node					dbms_xmldom.domnode;
BEGIN
	v_node_name := dbms_xmldom.getnodename(in_node);

	IF v_node_name = 'test' THEN
		GenerateTest(in_clob, in_node);
		RETURN;
	END IF;
	
	IF v_node_name NOT IN ('and', 'or') THEN
		RAISE_APPLICATION_ERROR(-20001, 'condition node has an unknown child '||v_node_name);
	END IF;

	CheckLeftRightNodes(in_node, v_left_node, v_right_node);
	WriteAppend(in_clob, '(');
	GenerateCondition(in_clob, v_left_node);
	WriteAppend(in_clob, ') '||v_node_name||' (');
	GenerateCondition(in_clob, v_right_node);
	WriteAppend(in_clob, ')');
END;

PROCEDURE GenerateIf(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
)
AS
	v_condition_node				dbms_xmldom.domnode;
	v_then_node						dbms_xmldom.domnode;
	v_else_node						dbms_xmldom.domnode;
BEGIN
	v_condition_node := dbms_xslprocessor.selectSingleNode(in_node, 'condition/*');
	IF dbms_xmldom.isnull(v_condition_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing a condition child');
	END IF;
	v_then_node := dbms_xslprocessor.selectSingleNode(in_node, 'then/*');
	IF dbms_xmldom.isnull(v_then_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing a then child');
	END IF;
	v_else_node := dbms_xslprocessor.selectSingleNode(in_node, 'else/*');
	IF dbms_xmldom.isnull(v_else_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing an else child');
	END IF;
	WriteAppend(in_clob, 'CASE WHEN ');
	GenerateCondition(in_clob, v_condition_node);
	WriteAppend(in_clob, ' THEN ');
	GenerateCalc(in_clob, v_then_node);
	WriteAppend(in_clob, ' ELSE ');
	GenerateCalc(in_clob, v_else_node);
	WriteAppend(in_clob, ' END');
END;

PROCEDURE GenerateWhen(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
)
AS
	v_condition_node				dbms_xmldom.domnode;
	v_then_node						dbms_xmldom.domnode;
BEGIN
	v_condition_node := dbms_xslprocessor.selectSingleNode(in_node, 'condition/*');
	IF dbms_xmldom.isnull(v_condition_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing a condition child');
	END IF;
	v_then_node := dbms_xslprocessor.selectSingleNode(in_node, 'then/*');
	IF dbms_xmldom.isnull(v_then_node) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The '||dbms_xmldom.getnodename(in_node)||' node is missing a left child');
	END IF;
	WriteAppend(in_clob, 'WHEN ');
	GenerateCondition(in_clob, v_condition_node);
	WriteAppend(in_clob, ' THEN ');
	GenerateCalc(in_clob, v_then_node);
END;

PROCEDURE GenerateChoose(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
)
AS
	v_when_nodes					dbms_xmldom.domnodelist;
	v_otherwise_node				dbms_xmldom.domnode;
BEGIN
	v_when_nodes := dbms_xslprocessor.selectNodes(in_node, 'when');
	v_otherwise_node := dbms_xslprocessor.selectSingleNode(in_node, 'otherwise/*');
	IF dbms_xmldom.getLength(v_when_nodes) = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The choose node is missing a when child');
	END IF;

	WriteAppend(in_clob, 'CASE ');
	FOR i IN 0 .. dbms_xmldom.getlength(v_when_nodes) - 1 LOOP
		GenerateWhen(in_clob, dbms_xmldom.item(v_when_nodes, i));
	END LOOP;
	IF NOT dbms_xmldom.isnull(v_otherwise_node) THEN
		WriteAppend(in_clob, ' ELSE ');
		GenerateCalc(in_clob, v_otherwise_node);
	END IF;
	WriteAppend(in_clob, ' END');
END;

PROCEDURE GenerateCalc(
	in_clob							IN OUT NOCOPY	CLOB,
	in_node							IN				dbms_xmldom.domnode
)
AS
	v_child							dbms_xmldom.domnode;	
	v_node_name						varchar2(100);
	v_column						varchar2(100);
	v_number						varchar2(100);
	v_string						varchar2(100);
	v_left							dbms_xmldom.domnode;
	v_right							dbms_xmldom.domnode;
	v_calc							clob;
BEGIN
	v_node_name := dbms_xmldom.getnodename(in_node);
	--dbms_output.put_line(v_node_name|| ' which is a '||dbms_xmldom.getnodetype(in_node));
	IF v_node_name IN ('add', 'subtract', 'multiply', 'divide') THEN
		CheckLeftRightNodes(in_node, v_left, v_right);
		WriteAppend(in_clob, '(');
		GenerateCalc(in_clob, v_left);
		WriteAppend(in_clob, ')');
		WriteAppend(in_clob,
			CASE v_node_name
				WHEN 'add' THEN '+'
				WHEN 'subtract' THEN '-'
				WHEN 'multiply' THEN '*'
				WHEN 'divide' THEN '/'
			END);
		WriteAppend(in_clob, '(');
		GenerateCalc(in_clob, v_right);
		WriteAppend(in_clob, ')');
		RETURN;
	END IF;
	
	IF v_node_name IN ('power', 'trunc', 'round', 'nvl') THEN
		CheckLeftRightNodes(in_node, v_left, v_right);
		WriteAppend(in_clob, v_node_name||'(');
		GenerateCalc(in_clob, v_left);
		WriteAppend(in_clob, ',');
		GenerateCalc(in_clob, v_right);
		WriteAppend(in_clob, ')');
		RETURN;
	END IF;
	
	IF v_node_name = 'column' THEN
		v_column := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'name');
		IF v_column IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'column node without name attribute');
		END IF;
		-- TODO: validate against database
		WriteAppend(in_clob, v_column);
		RETURN;
	END IF;
	
	IF v_node_name = 'number' THEN
		v_number := dbms_xmldom.getnodevalue(dbms_xslProcessor.selectSingleNode(in_node, 'text()'));
		IF v_number IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'empty number node');
		END If;
		WriteAppend(in_clob, v_number);
		RETURN;
	END IF;
	
	IF v_node_name = 'string' THEN
		v_string := dbms_xmldom.getnodevalue(dbms_xslProcessor.selectSingleNode(in_node, 'text()'));
		IF v_string IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'empty string node');
		END If;
		WriteAppend(in_clob, tab_pkg.sq(v_string));
		RETURN;
	END IF;

	IF v_node_name = 'sysdate' THEN
		WriteAppend(in_clob, 'SYSDATE');
		RETURN;
	END IF;
	
	IF v_node_name = 'null' THEN
		WriteAppend(in_clob, 'NULL');
		RETURN;
	END IF;
	
	IF v_node_name = 'if' THEN
		GenerateIf(in_clob, in_node);
		RETURN;
	END IF;

	RAISE_APPLICATION_ERROR(-20001, 'Unknown node '||v_node_name||' in calc xml');
END;

END;
/

CREATE OR REPLACE PACKAGE CMS.tab_pkg AS

-- Errors.  We don't use normal error codes since it's impossible
-- to add detail to them.  Instead, the Oracle Workspace Manager
-- approach is taken whereby we have specific error codes for what
-- would be normal Oracle errors.  The error codes are the same
-- as for Workspace manager on the offchance that it becomes
-- possible to use it as a basis for this stuff.
TYPE t_error_array IS VARRAY(300) OF VARCHAR2(500);

-- Oracle errors with no predefined exceptions that we want to catch
FGA_ALREADY_EXISTS		EXCEPTION;
PRAGMA EXCEPTION_INIT(FGA_ALREADY_EXISTS, -28101);

FGA_NOT_FOUND			EXCEPTION;
PRAGMA EXCEPTION_INIT(FGA_NOT_FOUND, -28102);

TABLE_DOES_NOT_EXIST	EXCEPTION;
PRAGMA EXCEPTION_INIT(TABLE_DOES_NOT_EXIST, -04043);

PACKAGE_DOES_NOT_EXIST	EXCEPTION;
PRAGMA EXCEPTION_INIT(PACKAGE_DOES_NOT_EXIST, -00942);
	
-- WM_ERROR_3
ERR_PK_MODIFIED					CONSTANT NUMBER := -20003;
PK_MODIFIED						EXCEPTION;
PRAGMA EXCEPTION_INIT(PK_MODIFIED, -20003);

-- WM_ERROR_5
ERR_RI_CONS_CHILD_FOUND			CONSTANT NUMBER := -20005;
RI_CONS_CHILD_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(RI_CONS_CHILD_FOUND, -20005);

-- WM_ERROR_6
ERR_RI_CONS_NO_PARENT			CONSTANT NUMBER := -20006;
RI_CONS_NO_PARENT				EXCEPTION;
PRAGMA EXCEPTION_INIT(RI_CONS_NO_PARENT, -20006);
	
-- WM_ERROR_10
ERR_UK_VIOLATION				CONSTANT NUMBER := -20010;
UK_VIOLATION					EXCEPTION;
PRAGMA EXCEPTION_INIT(UK_VIOLATION, -20010);

-- TODO: probably ought to be WM_ERROR_170
ERR_ROW_LOCKED					CONSTANT NUMBER := -20011;
ROW_LOCKED						EXCEPTION;
PRAGMA EXCEPTION_INIT(ROW_LOCKED, -20011);

-- Column types
SUBTYPE T_COL_TYPE				IS tab_column.col_type%TYPE;
CT_NORMAL						CONSTANT T_COL_TYPE := 0;
CT_FILE_DATA					CONSTANT T_COL_TYPE := 1;
CT_FILE_MIME					CONSTANT T_COL_TYPE := 2;
CT_FILE_NAME					CONSTANT T_COL_TYPE := 3;
CT_HTML							CONSTANT T_COL_TYPE := 4;
CT_IMAGE						CONSTANT T_COL_TYPE := 5;
CT_LINK							CONSTANT T_COL_TYPE := 6;
CT_ENUMERATED					CONSTANT T_COL_TYPE := 7;
CT_USER							CONSTANT T_COL_TYPE := 8;
CT_REGION						CONSTANT T_COL_TYPE := 9;
CT_INDICATOR					CONSTANT T_COL_TYPE := 10;
CT_TIME							CONSTANT T_COL_TYPE := 11;
CT_MEASURE						CONSTANT T_COL_TYPE := 12;
CT_MEASURE_SID					CONSTANT T_COL_TYPE := 13;
CT_SEARCH_ENUM					CONSTANT T_COL_TYPE := 14;	
CT_VIDEO_CODE					CONSTANT T_COL_TYPE := 15;	
CT_AUTO_INCREMENT				CONSTANT T_COL_TYPE := 16;
CT_POSITION						CONSTANT T_COL_TYPE := 17;
CT_CHART						CONSTANT T_COL_TYPE := 18;
CT_DOCUMENT						CONSTANT T_COL_TYPE := 19;
CT_BOOLEAN						CONSTANT T_COL_TYPE := 20;
CT_APP_SID						CONSTANT T_COL_TYPE := 21;
CT_CASCADE_ENUM					CONSTANT T_COL_TYPE := 22;
CT_FLOW_ITEM					CONSTANT T_COL_TYPE := 23;
CT_FLOW_REGION					CONSTANT T_COL_TYPE := 24;
CT_CALC							CONSTANT T_COL_TYPE := 25;
CT_ENFORCE_NULLABILITY			CONSTANT T_COL_TYPE := 26;
CT_FLOW_STATE					CONSTANT T_COL_TYPE := 27;
CT_COMPANY						CONSTANT T_COL_TYPE := 28;
CT_TREE							CONSTANT T_COL_TYPE := 29;

SUBTYPE T_TAB_COLUMN_PERMISSION	IS tab_column_role_permission.permission%TYPE;
TAB_COL_PERM_NONE				CONSTANT T_TAB_COLUMN_PERMISSION := 0;
TAB_COL_PERM_READ				CONSTANT T_TAB_COLUMN_PERMISSION := 1;
TAB_COL_PERM_READ_WRITE			CONSTANT T_TAB_COLUMN_PERMISSION := 2;

PROCEDURE CreateObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id	 				IN	security_pkg.T_SID_ID,
	in_class_id 				IN	security_pkg.T_CLASS_ID,
	in_name 					IN	security_pkg.T_SO_NAME,
	in_parent_sid_id 			IN	security_pkg.T_SID_ID);

PROCEDURE RenameObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_name 				IN	security_pkg.T_SO_NAME);

PROCEDURE DeleteObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID);

PROCEDURE MoveObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id 		IN	security_pkg.T_SID_ID);

-- Raises the given error
PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_args		IN	t_error_array
);

-- Variants with different numbers of arguments
PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2,
	in_arg3		IN	VARCHAR2
);

FUNCTION sq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;

-- Internal: dequote a quoted identifier, converting to upper case
-- if it wasn't quoted.  For passing in a table/column/schema name
-- and identifying the correct thing in the metadata tables.
FUNCTION dq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;
PRAGMA RESTRICT_REFERENCES(dq, RNPS, RNDS, WNDS, WNPS);

FUNCTION q( 
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;


FUNCTION GetAppSidForTable(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetAppSidForTable, RNPS, WNDS, WNPS);

-- Escapes a primary key value as '\' -> '\\', ',' -> '\,'
-- This is used in the item description view for tables that
-- have non-numeric primary key columns.
FUNCTION PkEscape(
	in_s						IN	VARCHAR2
) 
RETURN VARCHAR2
DETERMINISTIC;
PRAGMA RESTRICT_REFERENCES(PkEscape, RNDS, RNPS, WNDS, WNPS);

FUNCTION GetTableSid(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
) 
RETURN security_pkg.T_SID_ID;
-- TODO: Deterministic? pragma?
--PRAGMA RESTRICT_REFERENCES(GetTableSid,  RNPS, WNDS, WNPS);


-- Enable tracing of DDL to dbms_output (defaults to OFF)
PROCEDURE EnableTrace;

-- Disable tracing of DDL to dbms_output
PROCEDURE DisableTrace;

-- Enable tracing of DDL to dbms_output WITHOUT running it (defaults to OFF)
PROCEDURE EnableTraceOnly;

-- Disable tracing of DDL to dbms_output WITHOUT running it
PROCEDURE DisableTraceOnly;

-- For upgrading/recreating views for all CMS tables/packages/triggers
-- Useful for testing (or when bugs are found!)
PROCEDURE RecreateViews;

PROCEDURE RecreateView(
	in_tab_sid					IN	tab.tab_sid%TYPE
);

PROCEDURE RecreateView(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
);

PROCEDURE ReParseComments(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table		        IN	tab.oracle_table%TYPE
);

PROCEDURE RefreshUnmanaged(
	in_app_sid					IN	tab.app_sid%TYPE DEFAULT NULL
);

PROCEDURE RegisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	VARCHAR2,
	in_managed					IN	BOOLEAN DEFAULT TRUE,
	in_allow_entire_schema		IN	BOOLEAN DEFAULT TRUE	
);

PROCEDURE UnregisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
);

PROCEDURE AllowTable(
	in_oracle_schema			IN	app_schema_table.oracle_schema%TYPE,
	in_oracle_table				IN	app_schema_table.oracle_table%TYPE
);

-- Totally unsafe -- drops all tables for the current application
PROCEDURE DropAllTables;

-- Totally unsafe -- drop a single table by name (registered, will not clean up orphaned table SOs)
PROCEDURE DropTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_cascade_constraints		IN	BOOLEAN DEFAULT FALSE,
	in_drop_physical			IN	BOOLEAN DEFAULT TRUE
);

PROCEDURE SetColumnDescription(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_description				IN	tab_column.description%TYPE
);

PROCEDURE SetColumnHelp(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_help					OUT	tab_column.help%TYPE
);

PROCEDURE SetEnumeratedColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL
);

PROCEDURE SetSearchEnumColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL
);

PROCEDURE SetVideoColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_video_code				IN	NUMBER DEFAULT 1
);

PROCEDURE SetChartColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_chart					IN	NUMBER DEFAULT 1
);

PROCEDURE SetHtmlColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_html						IN	NUMBER DEFAULT 1
);

PROCEDURE SetFileColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_file_column				IN	tab_column.oracle_column%TYPE,
	in_mime_column				IN	tab_column.oracle_column%TYPE,
	in_name_column				IN	tab_column.oracle_column%TYPE
);

PROCEDURE RenameColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_old_name					IN	tab_column.oracle_column%TYPE,
	in_new_name					IN	tab_column.oracle_column%TYPE
);

PROCEDURE DropColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE
);

PROCEDURE AddColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_type						IN	VARCHAR2,
	in_comment					IN	VARCHAR2 DEFAULT NULL,
	in_pos						IN	tab_column.pos%TYPE DEFAULT 0,
	in_calc_xml					IN	tab_column.calc_xml%TYPE DEFAULT NULL
);

PROCEDURE AddForeignKey(
	in_from_schema				IN	tab.oracle_schema%TYPE,
	in_from_table				IN	tab.oracle_table%TYPE,
	in_from_columns				IN	VARCHAR2,
	in_to_schema				IN	tab.oracle_schema%TYPE,
	in_to_table					IN	tab.oracle_table%TYPE,
	in_to_columns				IN	VARCHAR2,
	in_delete_rule				IN 	VARCHAR2 DEFAULT 'RESTRICT'	
);

PROCEDURE AddUniqueKey(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_columns			IN	VARCHAR2
);


PROCEDURE GetDetails(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetTableDefinition(
	in_tab_sid					IN	security_pkg.T_SID_ID,
	out_tab_cur					OUT	SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_ck_cur					OUT	SYS_REFCURSOR,
	out_ck_col_cur				OUT	SYS_REFCURSOR,
	out_uk_cur					OUT	SYS_REFCURSOR,
	out_fk_cur					OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur	OUT	SYS_REFCURSOR	
);

PROCEDURE GetTableDefinitions(
	out_tab_cur					OUT SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_ck_cur					OUT	SYS_REFCURSOR,
	out_ck_col_cur				OUT	SYS_REFCURSOR,
	out_uk_cur					OUT	SYS_REFCURSOR,
	out_fk_cur					OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur	OUT	SYS_REFCURSOR	
);

PROCEDURE GoToContextIfExists(
	in_context_id				IN	security_pkg.T_SID_ID
);

PROCEDURE GoToContext(
	in_context_id				IN	security_pkg.T_SID_ID
);

PROCEDURE PublishItem(
	in_from_context				IN	context.context_id%TYPE,
	in_to_context				IN	context.context_id%TYPE,
	in_tab_sid					IN	tab.tab_sid%TYPE,
	in_item_id					IN	security_pkg.T_SID_ID
);

PROCEDURE SearchContent(
	in_tab_sids					IN	security_pkg.T_SID_IDS,
	in_part_description			IN  varchar2,
	in_item_ids					IN  security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAppDisplayTemplates(
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE EnsureContextExists(
	in_context					IN	context.context_id%TYPE
);

PROCEDURE GetItemsBeingTracked(
	in_path						IN  link_track.path%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE SearchTableFilters(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	in_prefix					IN	VARCHAR2,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAllSharedFilters(
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetTableFilters(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE LoadTableFilter(
	in_filter_sid				IN	filter.filter_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetSessionTableFilter(
	in_tab_name					IN	tab.oracle_table%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE RemoveSessionTableFilter(
	in_tab_name					IN	tab.oracle_table%TYPE
);

PROCEDURE SaveTableFilter(
	in_tab_sid					IN	filter.tab_sid%TYPE,
	in_name						IN	filter.name%TYPE,
	in_public					IN	NUMBER,
	in_filter_xml				IN	filter.filter_xml%TYPE,
	in_is_active_session_filter	IN	filter.is_active_session_filter%TYPE,
	out_filter_sid				OUT	filter.filter_sid%TYPE
);

PROCEDURE GetUserContent(
	out_cur						OUT	SYS_REFCURSOR
); 

PROCEDURE GetFlowRegions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_properties_only				IN	NUMBER,
	in_phrase						IN  VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowItemRegions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetCurrentFlowState(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDefaultFlowState(
	in_tab_sid						IN	tab.tab_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowTransitions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE EnterFlow(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_flow_item_id				OUT	csr.flow_item.flow_item_id%TYPE
);

PROCEDURE GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
);

PROCEDURE GetDefaultFlowStateEditable(
	in_flow_label					IN	csr.flow.label%TYPE,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
);

PROCEDURE UpdateUnmanagedFlowStateLabel(
    in_tab_sid                      security_pkg.T_SID_ID,
    in_flow_state_id                csr.flow_state.flow_state_id%TYPE,
    in_where_clause                 VARCHAR2
);

PROCEDURE GetFlowStatesForTables(
	in_table_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

END;
/

CREATE OR REPLACE PACKAGE BODY CMS.tab_pkg AS

m_trace BOOLEAN DEFAULT FALSE;
m_trace_only BOOLEAN DEFAULT FALSE;

TYPE t_ddl IS TABLE OF CLOB;
TYPE t_tab_set IS TABLE OF NUMBER(1) INDEX BY PLS_INTEGER;
TYPE t_string_list IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;

TYPE CommentParseState IS RECORD
(
	name	VARCHAR2(1000),
	value	VARCHAR2(4000),
	sep		VARCHAR2(1),
	pos		BINARY_INTEGER DEFAULT 1,
	quoted	BOOLEAN
);

PROCEDURE ParseQuotedList(
	in_quoted_list				IN	VARCHAR2,
	out_string_list				OUT	t_string_list
);

PROCEDURE GetTableForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE GetTableForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE GetColumnForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE GetColumnForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE RegisterTable_(
	in_tables_sid				IN				security_pkg.T_SID_ID,
	in_owner					IN				tab.oracle_schema%TYPE,
	in_table_name				IN				tab.oracle_table%TYPE,
	in_managed					IN				BOOLEAN,
	in_auto_registered			IN				BOOLEAN,
	in_refresh					IN				BOOLEAN,
	io_ddl						IN OUT NOCOPY	t_ddl,
	io_tab_set					IN OUT NOCOPY	t_tab_set
);

-- Errors we generate
m_errors t_error_array := t_error_array(
'',
'',
'cannot modify primary key values for version-enabled table (constraint id %1)',
'',
'integrity constraint (%1) violated - child record found',
'integrity constraint (%1) violated - parent key not found',
'',
'',
'',
'unique constraint (%1) violated',
'the row is locked for editing in context %1'
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_args		IN	t_error_array
)
AS
	v_msg		VARCHAR2(4000);
	v_start		BINARY_INTEGER;
	v_pos		BINARY_INTEGER := 1;
	v_n			BINARY_INTEGER;
	v_error		VARCHAR2(500);
BEGIN
	v_error := m_errors(-in_num-20000);
	LOOP
		v_start := v_pos;
		v_pos := INSTR(v_error, '%', v_pos);
		IF v_pos > 0 THEN
			v_n := TO_NUMBER(SUBSTR(v_error, v_pos + 1, 1));
			v_msg := v_msg || SUBSTR(v_error, v_start, v_pos - v_start) ||
					 in_args(v_n);
			v_pos := v_pos + 2;
		ELSE
			v_msg := v_msg || SUBSTR(v_error, v_start, LENGTH(v_error) - v_start + 1);
			RAISE_APPLICATION_ERROR(in_num, v_msg);
		END IF;
	END LOOP;
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER
)
AS
BEGIN
	RaiseError(in_num, t_error_array());
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2
)
AS
BEGIN
	RaiseError(in_num, t_error_array(in_arg1));
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2
)
AS
BEGIN
	RaiseError(in_num, t_error_array(in_arg1, in_arg2));
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2,
	in_arg3		IN	VARCHAR2
)
AS
BEGIN
	RaiseError(in_num, t_error_array(in_arg1, in_arg2, in_arg3));
END;

PROCEDURE WriteAppend(
	in_clob						IN OUT NOCOPY	CLOB,
	in_str						IN				VARCHAR2
)
AS
BEGIN
	dbms_lob.writeappend(in_clob, LENGTH(in_str), in_str);
END;

-- security interface procs
PROCEDURE CreateObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id	 				IN	security_pkg.T_SID_ID,
	in_class_id 				IN	security_pkg.T_CLASS_ID,
	in_name 					IN	security_pkg.T_SO_NAME,
	in_parent_sid_id 			IN	security_pkg.T_SID_ID)
IS
BEGIN
	NULL;
END CreateObject;


PROCEDURE RenameObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_name 				IN	security_pkg.T_SO_NAME)
IS
BEGIN
	NULL;
END RenameObject;

PROCEDURE DeleteObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID)
IS
BEGIN
	-- Delete all FKs
	DELETE
	  FROM fk_cons_col
	 WHERE fk_cons_id IN (SELECT fk_cons_id
	 						FROM fk_cons
	 					   WHERE tab_sid = in_sid_id);
	DELETE
	  FROM fk_cons
	 WHERE tab_sid = in_sid_id;
	 
	 
	DELETE 
	  FROM fk_cons_col
	 WHERE fk_cons_id IN (
        SELECT fk_cons_id 
          FROM fk_cons f, uk_cons u
         WHERE f.r_cons_id = u.uk_cons_id  
           AND u.tab_sid = in_sid_id
    );
    
	DELETE 
	  FROM fk_cons
	 WHERE fk_cons_id IN (
        SELECT fk_cons_id 
          FROM fk_cons f, uk_cons u
         WHERE f.r_cons_id = u.uk_cons_id  
           AND u.tab_sid = in_sid_id
    );
    
	-- Clean the PK off for RI
	UPDATE tab
	   SET pk_cons_id = NULL
	 WHERE tab_sid = in_sid_id;
	 
	-- Clean up constraints
	DELETE
	  FROM uk_cons_col
	 WHERE uk_cons_id IN (SELECT uk_cons_id
	 						FROM uk_cons
	 					   WHERE tab_sid = in_sid_id);
	DELETE
	  FROM uk_cons
	 WHERE tab_sid = in_sid_id;

	-- clean up web publications
	FOR r IN (SELECT wp.web_publication_id
				FROM web_publication wp, display_template dt
			   WHERE wp.display_template_id = dt.display_template_id AND dt.tab_sid = in_sid_id) LOOP
		SecurableObject_pkg.DeleteSO(in_act, r.web_publication_id);
	END LOOP;

	-- clean up templates
	DELETE
	  FROM display_template 
	 WHERE tab_sid = in_sid_id;
	 
	-- clean up link tracking
	DELETE
	  FROM link_track
	 WHERE column_sid IN (
	 	SELECT column_sid
	 	  FROM tab_column
	 	 WHERE tab_sid = in_sid_id
	 );
	 
	-- clean up saved search filters
	DELETE
	  FROM filter
	 WHERE tab_sid = in_sid_id;
	
	-- clean up forms
	DELETE
	  FROM form
	 WHERE parent_tab_sid = in_sid_id;
	 
	-- clean up table info
    DELETE 
      FROM CK_CONS_COL
     WHERE column_sid IN (
        SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
     );

	DELETE 
	  FROM flow_tab_column_cons 
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );

	DELETE
	  FROM tab_column
	 WHERE tab_sid = in_sid_id;

    DELETE
      FROM CK_CONS
     WHERE tab_sid = in_sid_id;
     
	DELETE
	  FROM tab
	 WHERE tab_sid = in_sid_id;
END DeleteObject;

PROCEDURE MoveObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id 		IN	security_pkg.T_SID_ID)
IS
BEGIN
	NULL;
END MoveObject;

FUNCTION comma(
	s							IN	VARCHAR2,
	sep							IN	VARCHAR2 default ', '
)
RETURN VARCHAR2
DETERMINISTIC
AS
BEGIN
	IF s IS NULL THEN
		RETURN s;
	END IF;
	RETURN s || sep;
END;

FUNCTION q( 
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN '"'||s||'"';
END;
	
FUNCTION qs(
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN '"'||REPLACE(s,'''','''''')||'"';
END;

FUNCTION sq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN ''''||REPLACE(s,'''','''''')||'''';
END;

FUNCTION dq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
	v_r		VARCHAR2(30);
BEGIN
	IF SUBSTR(s, 1, 1) = '"' THEN
		IF SUBSTR(s, -1, 1) <> '"' THEN
			RAISE_APPLICATION_ERROR(-20001, 'Missing quote in identifier '||s);
		END IF;
		v_r := SUBSTR(s, 2, LENGTH(s) - 2);
		IF INSTR(v_r, '"') <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Embedded quote in quoted identifier '||s);
		END IF;
		RETURN v_r;
	END IF;
	RETURN UPPER(s);
END;

FUNCTION QuotedList(
	in_string_list					IN	t_string_list
)
RETURN VARCHAR
DETERMINISTIC
AS
	v_result	VARCHAR2(32767);
BEGIN
	FOR i IN 1 .. in_string_list.COUNT LOOP
		IF v_result IS NOT NULL THEN
			v_result := v_result || ',';
		END IF;
		v_result := v_result || q(in_string_list(i));
	END LOOP;
	RETURN v_result;
END;

PROCEDURE GetPkCols(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cols					OUT	t_string_list
)
AS
BEGIN
    SELECT tc.oracle_column
      BULK COLLECT INTO out_cols
      FROM tab_column tc, tab t, uk_cons uk, uk_cons_col ukc
     WHERE t.pk_cons_id = uk.uk_cons_id AND uk.uk_cons_id = ukc.uk_cons_id AND
           ukc.column_sid = tc.column_sid AND t.tab_sid = in_tab_sid
     ORDER BY ukc.pos;
END;

FUNCTION BoolToNum(
	in_bool						IN BOOLEAN
) RETURN NUMBER
DETERMINISTIC
AS
BEGIN
	IF in_bool THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE WriteHelperPackageCalls(
	in_tab_sid						IN				tab.tab_sid%TYPE,
	io_lob							IN OUT NOCOPY	CLOB,
	in_pk_columns					IN				t_string_list,
	in_fn							IN				VARCHAR2,
	in_pk_from						IN				VARCHAR2,
	in_old_values					IN				BOOLEAN,
	in_new_values					IN				BOOLEAN
)
AS
	v_last_helper_pkg								tab_column.helper_pkg%TYPE;
BEGIN
	v_last_helper_pkg := NULL;
	FOR r IN (SELECT helper_pkg, oracle_column
				FROM tab_column
			   WHERE tab_sid = in_tab_sid
			     AND helper_pkg IS NOT NULL
			   ORDER BY LOWER(helper_pkg), pos) LOOP
		IF v_last_helper_pkg IS NULL OR v_last_helper_pkg != r.helper_pkg THEN
			IF v_last_helper_pkg IS NOT NULL THEN
				WriteAppend(io_lob, ');'||chr(10));
			END IF;
			
			WriteAppend(io_lob, 
				'    '||r.helper_pkg||'.'||in_fn||'(');
			FOR i IN 1 .. in_pk_columns.COUNT LOOP
				IF i != 1 THEN
					WriteAppend(io_lob, ', ');
				END IF;
				WriteAppend(io_lob, in_pk_from||'.'||q(in_pk_columns(i)));
			END LOOP;
			
			v_last_helper_pkg := r.helper_pkg;
		END IF;
		
		IF in_old_values THEN
			WriteAppend(io_lob, ', :OLD.'||q(r.oracle_column));
		END IF;
		IF in_new_values THEN
			WriteAppend(io_lob, ', :NEW.'||q(r.oracle_column));
		END IF;		
	END LOOP;
	IF v_last_helper_pkg IS NOT NULL THEN
		WriteAppend(io_lob, ');'||chr(10));
	END IF;
END;

FUNCTION GetTableSid(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
) 
RETURN security_pkg.T_SID_ID
AS
	v_tab_sid 		security_pkg.T_SID_ID;
BEGIN
	SELECT tab_sid INTO v_tab_sid FROM tab WHERE oracle_schema = in_oracle_schema AND oracle_table = in_oracle_table;
	RETURN v_tab_sid;
END;

PROCEDURE CreateTriggers(
	in_tab_sid					IN			  tab.tab_sid%TYPE,
	io_ddl						IN OUT NOCOPY t_ddl
)
AS
	v_s					CLOB;
	v_d					CLOB;
	v_u					CLOB;
	v_i					CLOB;
	v_p					CLOB;
	v_c					VARCHAR2(200);
	v_c_tab				VARCHAR2(100);
	v_l_tab				VARCHAR2(100);
	v_tab				VARCHAR2(100);
	v_cols				VARCHAR2(4000);			-- cols for view
	v_u_vals			VARCHAR2(4000);			-- vals for updates ("N$COL")
	v_i_vals			VARCHAR2(4000);			-- vals for inserts (NVL("N$COL", column_default))
	v_i_args			VARCHAR2(4000);			-- args for i calls in package
	v_u_args			VARCHAR2(4000);			-- args for u calls in package
	v_d_args			VARCHAR2(4000);			-- args for d calls in package
	v_owner				tab.oracle_schema%TYPE;
	v_table_name		tab.oracle_table%TYPE;	
	v_pk_columns		t_string_list;
	v_uk_columns		t_string_list;
	v_parent_lock		VARCHAR2(32767);
	v_t					VARCHAR2(32767);
	v_t2				VARCHAR2(32767);
	v_t3				VARCHAR2(32767);
	v_t4				VARCHAR2(32767);
	v_uk_check			VARCHAR2(32767);
	v_first				BOOLEAN;
	v_pk_cons_id		tab.pk_cons_id%TYPE;
	v_base_tab			VARCHAR2(30);
BEGIN
	SELECT oracle_schema, oracle_table, pk_cons_id
	  INTO v_owner, v_table_name, v_pk_cons_id
	  FROM tab 
	 WHERE tab_sid = in_tab_sid;
	GetPkCols(in_tab_sid, v_pk_columns);

	-- Figure out the current base table name (it's either C$TABLE, if already registered
	-- and we are recreating the triggers, or just TABLE if it's not)
	BEGIN
		SELECT table_name
		  INTO v_base_tab
		  FROM all_tables
		 WHERE table_name = 'C$'||v_table_name
		   AND owner = v_owner;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_base_tab := v_table_name;
	END;
	
	-- Get all UK key columns -- the trigger has to pass these on to the package
    SELECT tc.oracle_column
      BULK COLLECT INTO v_uk_columns
      FROM tab_column tc, uk_cons uk, uk_cons_col ukc
     WHERE uk.tab_sid = in_tab_sid AND uk.uk_cons_id = ukc.uk_cons_id AND
           ukc.column_sid = tc.column_sid
     GROUP BY tc.oracle_column;
	
	v_c_tab := q(v_owner) || '.' || q('C$' || v_table_name);
 	v_l_tab := q(v_owner) || '.' || q('L$' || v_table_name);
	v_tab   := q(v_owner) || '.' || q(v_table_name);
	
	v_s :=
		'create or replace package '||q(v_owner)||'.'||q('T$'||v_table_name)||chr(10)||
		'as'||chr(10);
	v_i :=
		'    procedure i'||chr(10)||
		'    ('||chr(10);
	v_u :=
		'    procedure u'||chr(10)||
		'    ('||chr(10);
	v_d :=
		'    procedure d'||chr(10)||
		'    ('||chr(10);
	v_p :=
		'    procedure p'||chr(10)||
		'    ('||chr(10)||
		'        '||rpad(q('FROM_CONTEXT'), 32)||' in  '||v_c_tab||'."CONTEXT_ID"%TYPE,'||chr(10)||
		'        '||rpad(q('TO_CONTEXT'), 32)||' in  '||v_c_tab||'."CONTEXT_ID"%TYPE,'||chr(10);
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_p,
		'        '||rpad(q('N$'||v_pk_columns(i)), 32)||' in  '||v_c_tab||'.'||q(v_pk_columns(i))||'%TYPE');
		IF i <> v_pk_columns.COUNT THEN
			WriteAppend(v_p, ',');
		END IF;
		WriteAppend(v_p, chr(10));
	END LOOP;
	WriteAppend(v_p,
		'    )');
	v_first := TRUE;
	v_t := NULL;
	FOR r IN (SELECT tc.oracle_column c, atc.data_default
		  		FROM tab_column tc, all_tab_columns atc
		 	   WHERE tc.tab_sid = in_tab_sid AND atc.owner = v_owner AND
		 	   		 atc.table_name = v_base_tab AND atc.column_name = tc.oracle_column
	  	    ORDER BY tc.pos) LOOP
		IF NOT v_first THEN
			WriteAppend(v_i, ',' || chr(10));
			WriteAppend(v_u, ',' || chr(10));
		END IF;
		v_first := FALSE;
		FOR i IN 1 .. v_uk_columns.COUNT LOOP
			IF r.c = v_uk_columns(i) THEN
				v_c := 
					'        '||rpad(q('O$'||r.c), 32)||' in  ' || v_c_tab || '.' || q(r.c) ||
					'%TYPE';
				v_u_args := comma(v_u_args) || ':OLD.' || q(r.c);
				v_d_args := comma(v_d_args) || ':OLD.' || q(r.c);
				v_t := comma(v_t, ','||chr(10)) || v_c;
				WriteAppend(v_u, v_c || ',' || chr(10));
				EXIT;
			END IF;
		END LOOP;
		v_c := '        '||rpad(q('N$'||r.c), 32)||' in  ';
		v_c := v_c || v_c_tab || '.' || q(r.c);			
		v_cols := comma(v_cols) || q(r.c);
		v_u_vals := comma(v_u_vals) || q('N$'||r.c);
		IF r.data_default IS NOT NULL THEN
			v_i_vals := comma(v_i_vals) || 'nvl(' || q('N$'||r.c) || ',' || r.data_default || ')';
		ELSE
			v_i_vals := comma(v_i_vals) || q('N$'||r.c);
		END IF;		
		v_i_args := comma(v_i_args) || ':NEW.' || q(r.c);
		v_u_args := comma(v_u_args) || ':NEW.' || q(r.c);
		v_c := v_c || '%TYPE';
		WriteAppend(v_i, v_c);
		WriteAppend(v_u, v_c);				
	END LOOP;
	v_d := v_d || v_t;
	
	v_i_args := comma(v_i_args) || ':NEW.' || q('CHANGE_DESCRIPTION');
	v_u_args := comma(v_u_args) || ':NEW.' || q('CHANGE_DESCRIPTION');
	WriteAppend(v_i,
		 ',' || chr(10)||'        '||rpad(q('N$CHANGE_DESCRIPTION'), 32)||' in  ' || v_c_tab || '.' || q('CHANGE_DESCRIPTION') || '%TYPE');
	WriteAppend(v_u,
		 ',' || chr(10)||'        '||rpad(q('N$CHANGE_DESCRIPTION'), 32)||' in  ' || v_c_tab || '.' || q('CHANGE_DESCRIPTION') || '%TYPE');
		
	v_s := v_s || v_i;
	WriteAppend(v_s, chr(10) ||
		'    );'||chr(10)||
		chr(10));
	v_s := v_s || v_u;
	WriteAppend(v_s, chr(10) ||
		'    );'||chr(10)||
		chr(10));
	v_s := v_s || v_d;
	WriteAppend(v_s, chr(10) ||
		'    );'||chr(10)||
		chr(10));
	v_s := v_s || v_p;
	WriteAppend(v_s, ';' || chr(10) ||
		chr(10)||
		'    procedure sx'||chr(10)||
		'    ('||chr(10)||
		'        in_object_schema                 in  varchar2,'||chr(10)||
		'        in_object_name                   in  varchar2,'||chr(10)||
		'        in_policy_name                   in  varchar2'||chr(10)||
		'    );'||chr(10)||
		chr(10)||
		'    procedure ux;'||chr(10)||
		'    procedure ix;'||chr(10)||
		'    procedure dx;'||chr(10)||
		'end;');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := v_s;
	
	v_s := 
		'create or replace package body '||q(v_owner)||'.'||q('T$'||v_table_name)||chr(10)||
		'as'||chr(10)||
		chr(10)||
		'    g_tab_sid CONSTANT NUMBER(10) := '||in_tab_sid||';'||chr(10);
		
	---------------------------------
	-- INSERT PROCEDURE GENERATION --
	---------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_i;
	WriteAppend(v_s, chr(10) ||
		'    )' || chr(10) ||
		'    as' || chr(10) ||
  		'        v_vers         number(10);'||chr(10)||
  		'        v_child        number(10);'||chr(10)||
  		'        v_locked_by    number(10);'||chr(10)||
  		'        v_context_id   number(10);'||chr(10)||
  		'        v_uk_cons_id   number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        v_context_id := NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0);' || chr(10));
 
	-- Check + lock parent records
	-- Basically if all parts of the FK are non-null then we need to select the parent
	-- rows FOR UPDATE to prevent them being removed / updated half way through this transaction
	-- Also don't check parent records for unmanaged tables (as we have real RI there!)
	FOR r IN (SELECT fkc.fk_cons_id, fkc.r_cons_id
				FROM fk_cons fkc, uk_cons ukc, tab ukt
			   WHERE fkc.tab_sid = in_tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
			   	     ukc.tab_sid = ukt.tab_sid AND ukt.managed = 1) LOOP
		v_t := NULL;
		v_t2 := NULL;
	
		FOR s IN (SELECT pt.oracle_schema owner, pt.oracle_table table_name, ptc.oracle_column column_name, 
						 rtc.oracle_column r_column_name
					FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc, tab pt
				   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
				   		 ptc.tab_sid = pt.tab_sid AND ukcc.uk_cons_id = r.r_cons_id AND 
				   		 ukcc.pos = fkcc.pos AND ukcc.column_sid = ptc.column_sid) LOOP
				   		 
			IF v_t IS NULL THEN
				v_t :=
				'                select 1'||chr(10)||
				'                  into v_child'||chr(10)||
				'                  from '||q(s.owner)||'.'||q(s.table_name)||chr(10)||
				'                 where ';
			ELSE
				v_t := v_t || ' and'||chr(10)||
				'                       ';
			END IF;
			v_t := v_t || q(s.column_name)||' = '||q('N$'||s.r_column_name);

			IF v_t2 IS NULL THEN
				v_t2 :=
				'        if ';
			ELSE
				v_t2 := v_t2 || ' and'||chr(10)||
				'           ';
			END IF;
			
			v_t2 := v_t2 ||
				q('N$'||s.r_column_name)||' is not null ';
		END LOOP;
		
		v_parent_lock := v_parent_lock || v_t2 || 'then'||chr(10)||
			'            begin'||chr(10)||
			v_t||chr(10)||
			'                       for update;'||chr(10)||
			'            exception'||chr(10)||
			'                when no_data_found then'||chr(10)||
			'                    cms.tab_pkg.RaiseError(cms.tab_pkg.err_ri_cons_no_parent, '||r.fk_cons_id||');'||chr(10)||
	 		'            end;'||chr(10)||
			'        end if;'||chr(10);
	END LOOP;

	WriteAppend(v_s, 
		v_parent_lock ||
		'        begin'||chr(10)||
    	'            select 1, locked_by'||chr(10)||
		'              into v_child, v_locked_by'||chr(10)||
		'              from '||v_l_tab||chr(10)||
     	'             where ');
     	
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and '||chr(10) ||
				'                    ');
		END IF; 
		WriteAppend(v_s, q(v_pk_columns(i)) || ' = ' || q('N$'||v_pk_columns(i)));
	END LOOP;

	WriteAppend(v_s, chr(10) ||
		'                   for update;'||chr(10)||
  		'        exception'||chr(10)||
    	'            when no_data_found then'||chr(10)||
		'                v_child := null;'||chr(10)||
  		'        end;'||chr(10)||
  		'        if nvl(v_locked_by, v_context_id) <> v_context_id then'||chr(10)||
    	'            select count(*)'||chr(10)||
      	'              into v_child'||chr(10)||
      	'              from cms.fast_context'||chr(10)||
     	'             where parent_context_id = v_locked_by and context_id = v_context_id;'||chr(10)||
      	'            if v_child = 0 then'||chr(10)||
		'                cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||      	
      	'            end if;'||chr(10)||
      	'        end if;'||chr(10)||
  		'        if v_child is not null then'||chr(10)||
  		'            cms.tab_pkg.RaiseError(cms.tab_pkg.err_uk_violation, '||v_pk_cons_id||');'||chr(10)||
  		'        end if;'||chr(10));
  		
	-- Now check any unique keys defined on the table.  There's nothing good
	-- to lock on here, so we have to lock the constraint definition row.
	-- This is overkill, but otherwise we need a separate table for enforcing the unique constraint.
	FOR r IN (SELECT ukc.uk_cons_id
				FROM uk_cons ukc, tab t
			   WHERE ukc.tab_sid = in_tab_sid AND t.tab_sid = ukc.tab_sid AND t.tab_sid = in_tab_sid AND
			   		 t.pk_cons_id <> ukc.uk_cons_id) LOOP

		-- UKs seem to do "if any part of the key is non-null then check the row is unique 
		-- (with null=null => true) otherwise if all nulls don't check
		-- seems a bit crazy
		v_t := NULL;
		v_t2 := NULL;
		FOR s IN (SELECT tc.oracle_column
		            FROM tab_column tc, uk_cons_col ukcc
		           WHERE ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = tc.column_sid) LOOP
			IF v_t IS NULL THEN
				v_t := 
					'        if ';
			ELSE
				v_t := v_t || ' or'||chr(10) ||
					'           ';
			END IF;
			v_t := v_t || q('N$'||s.oracle_column) || ' is not null';
			IF v_t2 IS NOT NULL THEN
				v_t2 := v_t2 ||' and'||chr(10) ||
					'                                  ';
			END IF;	
			v_t2 := v_t2 || '(' || q(s.oracle_column) || '=' || q('N$'||s.oracle_column) || ' or ('||
							q(s.oracle_column) || ' is null and ' || q('N$'||s.oracle_column) || ' is null))';
		END LOOP;
		
		WriteAppend(v_s,
		v_t||' then'||chr(10)||
		'            select uk_cons_id'||chr(10)||
		'              into v_uk_cons_id'||chr(10)||
		'              from cms.uk_cons'||chr(10)||
		'             where uk_cons_id = '||r.uk_cons_id||chr(10)||
		'                   for update;'||chr(10)||
		'            select min(1)'||chr(10)||
		'              into v_child'||chr(10)||
		'              from dual'||chr(10)||
		'             where exists (select 1'||chr(10)||
		'                             from '||v_c_tab||chr(10)||
		'                            where retired_dtm is null and vers > 0 and '||v_t2||');'||chr(10)||
		'            if v_child is not null then'||chr(10)||
		'                cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_UK_VIOLATION, '||r.uk_cons_id||');'||chr(10)||
		'            end if;'||chr(10)||
		'        end if;'||chr(10));
	END LOOP;
	
	WriteAppend(v_s,
    	'        select NVL(max(vers), 0)'||chr(10)||
      	'          into v_vers'||chr(10)||
      	'          from '||v_c_tab||chr(10)||
     	'         where context_id = v_context_id and'||chr(10)||
     	'               ');
    FOR i IN 1 .. v_pk_columns.COUNT LOOP
    	IF i <> 1 THEN
    		WriteAppend(v_s,' and' || chr(10) || '               ');
    	END IF;
    	WriteAppend(v_s, q(v_pk_columns(i)) || ' = ' || q('N$'||v_pk_columns(i)));
    END LOOP;
    WriteAppend(v_s, ';' || chr(10) ||
		'        insert into '||v_l_tab||' (locked_by');
		
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, ', ' || q(v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, ')' || chr(10) ||
		'        values (v_context_id');

	FOR r IN (SELECT tc.oracle_column c, atc.data_default
      			FROM tab_column tc, tab t, uk_cons uk, uk_cons_col ukc, all_tab_columns atc
     		   WHERE t.pk_cons_id = uk.uk_cons_id AND uk.uk_cons_id = ukc.uk_cons_id AND
           		     ukc.column_sid = tc.column_sid AND t.tab_sid = in_tab_sid AND
           		     atc.owner = v_owner AND atc.table_name = v_base_tab AND
           		     atc.column_name = tc.oracle_column
     		ORDER BY ukc.pos) LOOP
		IF r.data_default IS NOT NULL THEN
			WriteAppend(v_s, ', nvl(' || q('N$'||r.c) || ',' || r.data_default || ')');
		ELSE
			WriteAppend(v_s, ', ' || q('N$'||r.c));
		END IF;
	END LOOP;	

	WriteAppend(v_s, ');' || chr(10) ||
		'        insert into '||v_c_tab||' ('||comma(v_cols)||'context_id, locked_by, vers, changed_by, change_description)'||chr(10)||
		'        values ('||comma(v_i_vals)||'v_context_id, null, v_vers + 1, security.security_pkg.GetSID(), "N$CHANGE_DESCRIPTION");'||chr(10)||
		'    end;'||chr(10));
		
	---------------------------------
	-- UPDATE PROCEDURE GENERATION --
	---------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_u;
	WriteAppend(v_s, chr(10) ||
		'    )' || chr(10) ||
		'    as' || chr(10) || 
  		'        v_vers         number(10);'||chr(10)||
  		'        v_child        number(10);'||chr(10)||
  		'        v_locked_by    number(10);'||chr(10)||
  		'        v_context_id   number(10);'||chr(10)||
  		'        v_uk_cons_id   number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        v_context_id := NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0);' || chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s,
		'        if '||q('N$'||v_pk_columns(i))||' <> '||q('O$'||v_pk_columns(i))||' then'||chr(10)||
		'            cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_PK_MODIFIED, '||v_pk_cons_id||');'||chr(10)||
		'        end if;'||chr(10));
	END LOOP;
		WriteAppend(v_s,
		v_parent_lock ||
		'        begin'||chr(10)||
		'            select locked_by'||chr(10)||
		'              into v_locked_by'||chr(10)||
		'              from '||v_l_tab||chr(10)||
		'             where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '              	    ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i)) || '=' || q('N$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, chr(10) ||	
		'                   for update;'||chr(10)||
		'            if nvl(v_locked_by, v_context_id) <> v_context_id then'||chr(10)||
		'                select count(*)'||chr(10)||
		'                  into v_child'||chr(10)||
		'                  from cms.fast_context'||chr(10)||
		'                 where parent_context_id = v_locked_by and context_id = v_context_id;'||chr(10)||
		'                if v_child = 0 then'||chr(10)||
		'                    cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||		
		'                end if;'||chr(10)||
		'            end if;'||chr(10)||
		'        exception'||chr(10)||
		'            when no_data_found then'||chr(10)||
		'                raise_application_error(-20001, ''row is missing (this should not happen!)'');'||chr(10)||
		'        end;'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where context_id in (select parent_context_id'||chr(10)||
		'                                from cms.fast_context'||chr(10)|| 
		'                               where context_id = v_context_id) and'||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               ' || q(v_pk_columns(i))||' = '||q('N$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'				retired_dtm is null and vers > 0 and (locked_by = v_context_id or locked_by is null);'||chr(10)||
		'        if sql%rowcount = 0 then'||chr(10)||
		'            raise_application_error(-20001, ''row went missing!'');'||chr(10)||
		'        end if;'||chr(10)||		
		'        update '||v_l_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '               ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i)) || '=' || q('N$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, ';' || chr(10));

	-- Now check any unique keys defined on the table.  There's nothing good
	-- to lock on here, so we have to lock the constraint definition row.
	-- This is overkill, but otherwise we need a separate table for enforcing the unique constraint.
	FOR r IN (SELECT ukc.uk_cons_id
				FROM uk_cons ukc, tab t
			   WHERE ukc.tab_sid = in_tab_sid AND t.tab_sid = ukc.tab_sid AND t.tab_sid = in_tab_sid AND
			   		 t.pk_cons_id <> ukc.uk_cons_id) LOOP

		-- UKs seem to do "if any part of the key is non-null then check the row is unique 
		-- (with null=null => true) otherwise if all nulls don't check
		-- seems a bit crazy
		v_t := NULL;
		v_t2 := NULL;
		v_t3 := NULL;
		FOR s IN (SELECT tc.oracle_column
		            FROM tab_column tc, uk_cons_col ukcc
		           WHERE ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = tc.column_sid) LOOP			
			IF v_t IS NULL THEN
				v_t := 
					'        if ';
			ELSE
				v_t := v_t || ' or'||chr(10) ||
					'           ';
			END IF;
			v_t := v_t || q('N$'||s.oracle_column) || ' is not null';
			IF v_t2 IS NOT NULL THEN
				v_t2 := v_t2 ||' and'||chr(10) ||
					'                   ';
			END IF;	
			v_t2 := v_t2 || '(' || q(s.oracle_column) || '=' || q('N$'||s.oracle_column) || ' or ('||
							q(s.oracle_column) || ' is null and ' || q('N$'||s.oracle_column) || ' is null))';
							
			IF v_t3 IS NOT NULL THEN
				v_t3 := v_t3 || ' or'||chr(10)||
					'                     ';
				v_t4 := v_t4 || ' and'||chr(10)||
					'                     ';				
			END IF;

			-- If old was all nulls then it's fine, otherwise we have to run the child check
			v_t3 := v_t3 || q('O$' || s.oracle_column) || ' != ' || q('N$' || s.oracle_column);
			v_t4 := v_t4 || q('O$' || s.oracle_column) || ' is null';
		END LOOP;
		
		WriteAppend(v_s,
		v_t||' then'||chr(10)||
		'            select uk_cons_id'||chr(10)||
		'              into v_uk_cons_id'||chr(10)||
		'              from cms.uk_cons'||chr(10)||
		'             where uk_cons_id = '||r.uk_cons_id||chr(10)||
		'                   for update;'||chr(10)||		
		'            select min(1)'||chr(10)||
		'              into v_child'||chr(10)||
		'              from dual'||chr(10)||
		'             where exists (select 1'||chr(10)||
		'                             from '||v_c_tab||chr(10)||
		'                            where retired_dtm is null and vers > 0 and '||v_t2);
		
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			WriteAppend(v_s, ' and' || chr(10) ||
				'                                  ' || q(v_pk_columns(i)) || ' <> ' || q('N$' || v_pk_columns(i)));
		END LOOP;
		
		WriteAppend(v_s, ');' || chr(10) ||
		'            if v_child is not null then'||chr(10)||
  		'                cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_UK_VIOLATION, '||r.uk_cons_id||');'||chr(10)||
		'            end if;'||chr(10));
		
		-- See if we are changing any UKs.  If so, check to see if there was a child
		-- record of the old UK and if that's true then complain about it.		
		v_t := NULL;
		FOR s IN (SELECT fkc.fk_cons_id, t.oracle_schema, t.oracle_table
					FROM fk_cons fkc, tab t
				   WHERE r_cons_id = r.uk_cons_id AND fkc.tab_sid = t.tab_sid) LOOP
			v_t := v_t ||
			'                select min(1)'||chr(10)||
			'                  into v_child'||chr(10)||
			'                  from dual'||chr(10)||
			'                 where exists (select *'||chr(10)||
			'                                 from '||q(s.oracle_schema)||'.'||q('C$'||s.oracle_table)||chr(10)||
			'                                where ';
		
			v_first := TRUE;
			FOR t IN (SELECT ptc.oracle_column column_name, rtc.oracle_column r_column_name
					    FROM fk_cons_col fkcc, tab_column rtc, uk_cons_col ukcc, tab_column ptc
				       WHERE fkcc.fk_cons_id = s.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND
				       		 ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = ptc.column_sid) LOOP
				IF NOT v_first THEN
					v_t := v_t || ' and' || chr(10) ||
					'                                          ';
				END IF;
				v_first := FALSE;
				v_t := v_t || '(' || q(t.r_column_name) || ' = ' || q('O$' || t.column_name) || ' or ('||
								q(t.r_column_name) || ' is null and ' || q('O$' || t.column_name) || ' is null))';
			END LOOP;
			
			v_t := v_t || ');' || chr(10) ||
			'                if v_child is not null then'||chr(10)||
			'                    cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_RI_CONS_CHILD_FOUND, '||s.fk_cons_id||');'||chr(10)||
			'                end if;'||chr(10);
		END LOOP;
		
		IF v_t IS NOT NULL THEN
			WriteAppend(v_s,
			'            if not ('||v_t4||') and ('||v_t3||') then'||chr(10)||
			v_t||
			'            end if;'||chr(10));
		END IF;		
		WriteAppend(v_s,
		'        end if;'||chr(10));
	END LOOP;

	WriteAppend(v_s,
		'        select NVL(max(vers), 0)'||chr(10)||
		'          into v_vers'||chr(10)||
      	'          from '||v_c_tab||chr(10)||
     	'         where context_id = v_context_id and'||chr(10)||
     	'               ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '               ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i))||' = '||q('N$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, ';' || chr(10) ||
		'        update '||v_c_tab||chr(10)||
		'           set retired_dtm = sys_extract_utc(systimestamp)'||chr(10)||
		'         where context_id = v_context_id and'||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               '||q(v_pk_columns(i))||' = '||q('O$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'               retired_dtm is null;'||chr(10)||
		'        insert into '||v_c_tab||' ('||comma(v_cols)||'context_id, locked_by, vers, changed_by, change_description)'||chr(10)||
		'        values ('||comma(v_u_vals)||'v_context_id, null, v_vers + 1, security.security_pkg.GetSID(), "N$CHANGE_DESCRIPTION");'||chr(10)||		
		'    end;'||chr(10));
		
	---------------------------------
	-- DELETE PROCEDURE GENERATION --
	---------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_d;
	WriteAppend(v_s, chr(10) ||
		'    )' || chr(10) ||
		'    as' || chr(10) ||
  		'        v_vers         number(10);'||chr(10)||
  		'        v_child        number(10);'||chr(10)||
  		'        v_locked_by    number(10);'||chr(10)||
  		'        v_context_id   number(10);'||chr(10)||
  		'        v_locks        number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        v_context_id := NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0);' || chr(10)||
		'        -- ok, now check if we can lock'||chr(10)||
		'        select locked_by'||chr(10)||
		'          into v_locked_by'||chr(10)||
		'          from '||v_l_tab||chr(10)||
		'         where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '              	    ');
		END IF;		
		WriteAppend(v_s, q(v_pk_columns(i)) || ' = ' || q('O$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, chr(10) ||
		'               for update;'||chr(10)||
		'        if nvl(v_locked_by, v_context_id) <> v_context_id then'||chr(10)||
		'            select count(*)'||chr(10)||
		'              into v_child'||chr(10)||
		'              from cms.fast_context'||chr(10)||
		'             where parent_context_id = v_locked_by and context_id = v_context_id;'||chr(10)||
		'            if v_child = 0 then'||chr(10)||
		'                cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||		
		'            end if;'||chr(10)||
		'        end if;'||chr(10)||
		'        -- lock the row in all parent contexts for MVCC'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where context_id in (select parent_context_id from cms.fast_context where context_id = v_context_id) and'||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               '||q(v_pk_columns(i))||' = '||q('O$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'               retired_dtm is null and vers > 0;'||chr(10)||
		'        v_locks := sql%rowcount;'||chr(10)|| -- yeah, this is no good
		'        -- history it in the current context'||chr(10)||
		'        -- if it doesn''t exist, that''s ok -- the lock is good enough'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set vers = -(vers + 1)'||chr(10)||
		'         where context_id = v_context_id and '||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               '||q(v_pk_columns(i))||' = '||q('O$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'               retired_dtm is null and vers > 0;'||chr(10)||
		'        if v_locks + sql%rowcount = 0 then'||chr(10)||
		'            -- this is the best we can do, there is no way to have 0 rows deleted'||chr(10)||
		'            raise_application_error(-20001, ''row was deleted by another session'');'||chr(10)||
		'        end if;'||chr(10)||

		'        update '||v_l_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '              	    ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i)) || '=' || q('O$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s,
		';' || chr(10));
		
	-- Enforce delete rules.
	-- We have already locked the row we are trying to delete
	-- and insert/update statements try to lock all parent rows, therefore
	-- any concurrent insert/updates will have to wait, so it's safe to 
	-- check/delete/set null child records without locking them (I hope!).
	FOR r IN (SELECT fkc.fk_cons_id, fkc.r_cons_id, fkc.delete_rule, t.oracle_schema, t.oracle_table
  				FROM fk_cons fkc, uk_cons ukc, tab t
			   WHERE ukc.tab_sid = in_tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
			   		 fkc.tab_sid = t.tab_sid) LOOP

		IF r.delete_rule = 'R' THEN
			v_t := NULL;
			FOR s IN (SELECT ptc.oracle_column column_name, 
							 rtc.oracle_column r_column_name
						FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc
					   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
					   		 ukcc.uk_cons_id = r.r_cons_id AND ukcc.pos = fkcc.pos AND 
					   		 ukcc.column_sid = ptc.column_sid) LOOP
				IF v_t IS NOT NULL THEN
					v_t := v_t || ' and' || chr(10) || '                              ';
				END IF;
				v_t := v_t || q(s.r_column_name) || ' = ' || q('O$'||s.column_name);
			END LOOP;

/*
DECLARE
	v_q VARCHAR2(32767);
BEGIN
	v_q :=
			'        select min(1)'||chr(10)||
			'          into v_child'||chr(10)||
			'          from dual'||chr(10)||
			'         where exists (select *'||chr(10)||
			'                         from'||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||
			'                        where '||v_t||');'||chr(10)||
			'        if v_child is not null then'||chr(10)||
			'            cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_RI_CONS_CHILD_FOUND, '||r.fk_cons_id||');'||chr(10)||
			'        end if;'||chr(10);
	security_pkg.debugmsg(v_q);
	security_pkg.debugmsg('len (v_t) ='||length(v_t));
	v_s := v_s||v_q;
END;*/
			WriteAppend(v_s,
			'        select min(1)'||chr(10)||
			'          into v_child'||chr(10)||
			'          from dual'||chr(10)||
			'         where exists (select *'||chr(10)||
			'                         from'||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||
			'                        where '||v_t||');'||chr(10)||
			'        if v_child is not null then'||chr(10)||
			'            cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_RI_CONS_CHILD_FOUND, '||r.fk_cons_id||');'||chr(10)||
			'        end if;'||chr(10));
		ELSIF r.delete_rule = 'C' THEN
			-- Note when cascading the cascaded delete will double lock the parent
			-- row, but that's not much of an issue (it could be more efficient)
			v_t := NULL;
			FOR s IN (SELECT ptc.oracle_column column_name, 
							 rtc.oracle_column r_column_name
						FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc
					   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
					   		 ukcc.uk_cons_id = r.r_cons_id AND ukcc.pos = fkcc.pos AND 
					   		 ukcc.column_sid = ptc.column_sid) LOOP
				IF v_t IS NOT NULL THEN
					v_t := v_t || ' and' || chr(10) || '               ';
				END IF;
				v_t := v_t || q(s.r_column_name) || ' = ' || q('O$'||s.column_name);
			END LOOP;

			WriteAppend(v_s,
			'        delete'||chr(10)||
			'          from '||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||			
			'         where '||v_t||';'||chr(10));
		ELSIF r.delete_rule = 'N' THEN
			v_t := NULL;
			v_t2 := NULL;
			FOR s IN (SELECT ptc.oracle_column column_name, 
							 rtc.oracle_column r_column_name
						FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc
					   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
					   		 ukcc.uk_cons_id = r.r_cons_id AND ukcc.pos = fkcc.pos AND 
					   		 ukcc.column_sid = ptc.column_sid) LOOP
				IF v_t IS NOT NULL THEN
					v_t := v_t || ' and' || chr(10) || '               ';
					v_t2 := v_t2 || ',' || chr(10) || '               ';
				END IF;
				v_t := v_t || q(s.r_column_name) || ' = ' || q('O$'||s.column_name);
				v_t2 := v_t2 || q(s.r_column_name) || ' = null';
			END LOOP;

			WriteAppend(v_s,
			'        update '||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||
			'           set '||v_t2||chr(10)||
			'         where '||v_t||';'||chr(10));
		ELSE
			-- The check constraint should ensure this is never reached
			RAISE_APPLICATION_ERROR(-20001,
				'Unknown delete_rule '||r.delete_rule||': should be R, C or N');
		END IF;
	END LOOP;

	WriteAppend(v_s,
		'    end;'||chr(10));
		
		
	----------------------------------
	-- PUBLISH PROCEDURE GENERATION --
	----------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_p;
	WriteAppend(v_s, chr(10) ||
		'    as' || chr(10) ||
  		'        v_locked_by    number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        select locked_by'||chr(10)||
        '          into v_locked_by'||chr(10)||
      	'          from '||v_l_tab||chr(10)||
		'         where ');
	v_t := NULL;
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			v_t := v_t || ' and' || chr(10) ||
			'               ';
		END IF;
		v_t := v_t || q(v_pk_columns(i)) || ' = ' || q('N$' || v_pk_columns(i));
	END LOOP;
	WriteAppend(v_s, v_t || chr(10)||
		'               for update;'||chr(10)||
        '        if nvl(v_locked_by, -1) <> "FROM_CONTEXT" then'||chr(10)||
		'           cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||		
		'        end if;'||chr(10)||
		chr(10)||
		'        -- move a row from context A to context B'||chr(10)||
		'        update '||v_l_tab||chr(10)||
		'           set locked_by = "TO_CONTEXT"'||chr(10)||
		'         where '||v_t||';'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set retired_dtm = sys_extract_utc(systimestamp)'||chr(10)||
		'         where context_id in ('||chr(10)||
		'                 select context_id'||chr(10)||
		'                   from (select context_id, parent_context_id'||chr(10)||
		'                           from cms.context'||chr(10)||
		'                                start with context_id = "FROM_CONTEXT"'||chr(10)||
		'                                connect by prior parent_context_id = context_id'||chr(10)||
		'                      intersect'||chr(10)||
		'                         select context_id, parent_context_id'||chr(10)||
		'                           from cms.context'||chr(10)||
		'                                start with context_id = "TO_CONTEXT"'||chr(10)||
		'                                connect by prior context_id = parent_context_id'||chr(10)||
		'                         )'||chr(10)||
		'                  minus'||chr(10)||
		'                  select "FROM_CONTEXT"'||chr(10)||
		'                    from dual) and'||chr(10)||
		'               '||v_t||' and'||chr(10)||
		'               retired_dtm is null;'||chr(10)||
		'         update '||v_c_tab||chr(10)||
		'           set locked_by = "TO_CONTEXT"'||chr(10)||
		'         where context_id in (select parent_context_id'||chr(10)||
		'                                from cms.context'||chr(10)||
		'                               where context_id = "TO_CONTEXT") and'||chr(10)||
		'               '||v_t||' and'||chr(10)||		
		'                retired_dtm is null and vers > 0;'||chr(10)||
		'        update '||v_c_tab||' c'||chr(10)||
		'           set vers = (select case when c.vers < 0 then -1 else 1 end * (nvl(max(vers), 0) + 1)'||chr(10)||
		'                         from '||v_c_tab||chr(10)||
		'                        where context_id = "TO_CONTEXT" and'||chr(10)||
		'                              '||REPLACE(v_t, '               ', '                              ')||'),'||chr(10)||
		'               context_id = "TO_CONTEXT", locked_by = null'||chr(10)||
		'         where context_id = "FROM_CONTEXT" and'||chr(10)||
		'               '||v_t||' and'||chr(10)||
		'               retired_dtm is null;'||chr(10)||
		'        if sql%rowcount = 0 then'||chr(10)||
		'            raise_application_error(-20001, ''row went missing!'');'||chr(10)||
		'        end if;'||chr(10)||
		'    end;'||chr(10));
		
	----------------------------------
	-- STATEMENT HANDLER GENERATION --
	----------------------------------
	-- Note that it's generating multiple handlers that could be merged, however
	-- we might want some more specific permission types in the future (and it 
	-- doesn't hurt anything if things stay like that)
	WriteAppend(v_s, chr(10)||
		'    procedure checkSecurity'||chr(10)||
		'    ('||chr(10)||
		'        in_permission                    in  security.security_pkg.t_permission'||chr(10)||
		'    )'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        if not security.security_pkg.IsAccessAllowedSid(sys_context(''SECURITY'', ''ACT''),'||chr(10)||
		'                                               g_tab_sid, in_permission) then'||chr(10)||
		'            raise_application_error(security.security_pkg.err_access_denied,'||chr(10)||
		'                ''Access was denied on the table with sid ''||g_tab_sid);'||chr(10)||
		'        end if;'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure sx'||chr(10)||
		'    ('||chr(10)||
		'        in_object_schema                 in  varchar2,'||chr(10)||
		'        in_object_name                   in  varchar2,'||chr(10)||
		'        in_policy_name                   in  varchar2'||chr(10)||
		'    )'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_read);'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure ix'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_write);'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure ux'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_write);'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure dx'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_write);'||chr(10)||
		'    end;'||chr(10)||
		'end;');
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := v_s;
					
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('I$'||v_table_name)||chr(10)||
		'    instead of insert on '||v_tab||chr(10)||
		'    for each row'||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.i(' || v_i_args || ');' || chr(10);	
	WriteHelperPackageCalls(in_tab_sid, io_ddl(io_ddl.count), v_pk_columns, 'i', ':NEW', FALSE, TRUE);
	WriteAppend(io_ddl(io_ddl.count), 
		'end;');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('U$'||v_table_name)||chr(10)||
		'    instead of update on '||v_tab||chr(10)||
		'    for each row'||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.u('||
												  v_u_args||');' || chr(10);
	WriteHelperPackageCalls(in_tab_sid, io_ddl(io_ddl.count), v_pk_columns, 'u', ':OLD', TRUE, TRUE);
	WriteAppend(io_ddl(io_ddl.count), 
		'end;');
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('D$'||v_table_name)||chr(10)||
		'    instead of delete on '||v_tab||chr(10)||
		'    for each row'||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.d('||
												  v_d_args||');' || chr(10);
	WriteHelperPackageCalls(in_tab_sid, io_ddl(io_ddl.count), v_pk_columns, 'd', ':OLD', TRUE, FALSE);
	WriteAppend(io_ddl(io_ddl.count), 
		'end;');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('J$'||v_table_name)||chr(10)||
		'    before insert on '||v_c_tab||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.IX;'||chr(10)||
		'end;';
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('V$'||v_table_name)||chr(10)||
		'    before update on '||v_c_tab||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.UX;'||chr(10)||
		'end;';
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('E$'||v_table_name)||chr(10)||
		'    before delete on '||v_c_tab||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.DX;'||chr(10)||
		'end;';

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'begin'||CHR(10)||
			'dbms_fga.add_policy('||chr(10)||
			'object_schema => '||sq(q(v_owner))||','||chr(10)||
			'object_name => '||sq(q(v_table_name))||','||chr(10)||
			'policy_name => '||sq(q('S$'||v_table_name))||','||chr(10)||
			'handler_schema => '||sq(q(v_owner))||','||chr(10)||
			'handler_module => '||sq(q('T$'||v_table_name)||'.SX')||');'||chr(10)||
		'exception'||chr(10)||
			'when cms.tab_pkg.fga_already_exists then'||chr(10)||
				'null;'||chr(10)||
		'end;';
END;

PROCEDURE CreateView(
	in_tab_sid					IN				tab.tab_sid%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS	
	v_c_tab							VARCHAR2(100);
	v_tab							VARCHAR2(100);
	v_cols							CLOB;					-- cols for view
	v_from_tables					VARCHAR2(4000);
	v_where							VARCHAR2(4000);
	v_owner							tab.oracle_schema%TYPE;
	v_table_name					tab.oracle_table%TYPE;	
	v_pk_columns					t_string_list;
	v_first							BOOLEAN;
BEGIN
	SELECT oracle_schema, oracle_table
	  INTO v_owner, v_table_name
	  FROM tab 
	 WHERE tab_sid = in_tab_sid;
	GetPkCols(in_tab_sid, v_pk_columns);
	
	v_c_tab := q(v_owner) || '.' || q('C$' || v_table_name);
	v_tab   := q(v_owner) || '.' || q(v_table_name);

	dbms_lob.createtemporary(v_cols, TRUE, dbms_lob.call);
	v_from_tables := v_c_tab ||' i';
	v_first := TRUE;
	FOR r IN (SELECT oracle_column c, col_type, calc_xml
		  		FROM tab_column
		 	   WHERE tab_sid = in_tab_sid
	  	    ORDER BY pos) LOOP
		IF NOT v_first THEN
			WriteAppend(v_cols, ', ');
		END IF;
		v_first := FALSE;
		IF r.col_type = CT_CALC THEN
			WriteAppend(v_cols, '(');
			calc_xml_pkg.GenerateCalc(v_cols, dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(dbms_xmldom.newdomdocument(r.calc_xml))));
			WriteAppend(v_cols, ') ');
			WriteAppend(v_cols, q(r.c));
		ELSE
			WriteAppend(v_cols, 'i.' || q(r.c));
		END IF;
	END LOOP;
	IF NOT v_first THEN
		WriteAppend(v_cols, ', ');
	END IF;
	WriteAppend(v_cols, 'i.changed_by, i.change_description, NVL(i.locked_by, i.context_id) locked_by ');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'create or replace view '||v_tab||' as'||chr(10)||
		'    select ';
	dbms_lob.append(io_ddl(io_ddl.count), v_cols);
	WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'      from '||v_from_tables||chr(10)||
		'     where ((i.context_id in ('||chr(10)||
		'                select parent_context_id '||chr(10)||
		'                  from cms.fast_context '||chr(10)||
		'                 where context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0))'||chr(10)||
		'             and'||chr(10)||
		'             (i.locked_by is null or '||chr(10)||
		'              (i.locked_by <> nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0)'||chr(10)||
 		'               and i.locked_by not in (select parent_context_id'||chr(10)||
		'                                         from cms.fast_context'||chr(10)||
		'                                        where context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0))'||chr(10)||
		'            )))'||chr(10)||
		'            or'||chr(10)||
        '            i.context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0)'||chr(10)||
 		'           )'||chr(10)||
		'           and systimestamp >= i.created_dtm'||chr(10)||
		'           and ( systimestamp < i.retired_dtm or i.retired_dtm is null )'||chr(10)||
		'           and i.vers > 0'||v_where);

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'create or replace view '||q(v_owner)||'.'||q('H$' || v_table_name)||' as'||chr(10)||
		'    select i.created_dtm, i.retired_dtm, i.vers, ';
	dbms_lob.append(io_ddl(io_ddl.count), v_cols);
	WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'      from '||v_c_tab||' i'||chr(10)||
		'     where ((i.context_id in ('||chr(10)||
		'                select parent_context_id '||chr(10)||
		'                  from cms.fast_context '||chr(10)||
		'                 where context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0))'||chr(10)||
		'             and'||chr(10)||
		'             (i.locked_by is null or '||chr(10)||
		'              (i.locked_by <> nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0)'||chr(10)||
 		'               and i.locked_by not in (select parent_context_id'||chr(10)||
		'                                         from cms.fast_context'||chr(10)||
		'                                        where context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0))'||chr(10)||
		'            )))'||chr(10)||
		'            or'||chr(10)||
        '            i.context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0)'||chr(10)||
 		'           )'||chr(10));
END;


FUNCTION GetAppSidForTable(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
RETURN security_pkg.T_SID_ID
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid
	  INTO v_app_sid
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	RETURN v_app_sid;
END;

FUNCTION PkEscape(
	in_s						IN	VARCHAR2
) 
RETURN VARCHAR2
DETERMINISTIC
AS
BEGIN
	RETURN REPLACE(REPLACE(in_s, '\', '\\'), ',', '\,');  --'
END;

PROCEDURE CreateItemDescriptionView(
	in_app_sid					IN				security_pkg.T_SID_ID,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_union         varchar2(100);
	v_s				CLOB;
BEGIN
	FOR r IN (
		SELECT tab_sid, format_sql, pk_cons_id, oracle_schema, oracle_table
		  FROM tab
		 WHERE app_sid = in_app_sid AND format_sql IS NOT NULL AND 
		 	   pk_cons_id IS NOT NULL AND managed = 1
	) LOOP
		IF v_union IS NULL THEN
			io_ddl.extend(1);
			io_ddl(io_ddl.count) := 'create or replace view cms.item_description_'||in_app_sid||' as '||chr(10);
		END IF;
		
		v_s := '';
		FOR s IN (
			SELECT tc.oracle_column, atc.data_type
			  FROM uk_cons_col ukcc, tab_column tc, tab t, all_tab_columns atc
			 WHERE ukcc.uk_cons_id = r.pk_cons_id AND ukcc.column_sid = tc.column_sid AND
			 	   tc.tab_sid = t.tab_sid AND t.oracle_schema = atc.owner AND 
			 	   t.oracle_table = atc.table_name AND tc.oracle_column = atc.column_name
		  ORDER BY ukcc.pos) LOOP
		  	
		  	v_s := comma(v_s, ' || ');
		  	IF s.data_type = 'NUMBER' THEN
		  		v_s := v_s || 'to_char(' || q(s.oracle_column) || ')';
		  	ELSE 
		  		v_s := v_s || 'cms.tab_pkg.pkEscape(' || q(s.oracle_column) || ')';
		  	END IF;
		END LOOP;

		io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || v_union || 
			'    select '||r.tab_sid||' tab_sid,'||chr(10)||
			'           '||v_s||' item_id, '||chr(10)||
			'           to_char('||q(r.format_sql)||') description,'||chr(10)||
			'           locked_by'||chr(10)||
			'      from '||q(r.oracle_schema)||'.'||q(r.oracle_table);

		v_union := chr(10)||'    union all'||chr(10);
	END LOOP;
END;

PROCEDURE ExecuteClob(
	in_sql			CLOB
)
AS
	v_sql			DBMS_SQL.VARCHAR2S;
	v_upperbound	NUMBER;
	v_cur			INTEGER;
	v_ret			NUMBER;
BEGIN
	-- Split the SQL statement into chunks of 256 characters (one varchar2s entry)
	v_upperbound := ceil(dbms_lob.getlength(in_sql) / 256);
	FOR i IN 1..v_upperbound
	LOOP
		-- TODO: this is screwed with UTF8, i.e. creates the wrong size chunk
		v_sql(i) := dbms_lob.substr(in_sql, 256, ((i - 1) * 256) + 1);	
	END LOOP;
	
	-- Now parse and execute the SQL statement
	v_cur := dbms_sql.open_cursor;
	BEGIN
		dbms_sql.parse(v_cur, v_sql, 1, v_upperbound, false, dbms_sql.native);
		v_ret := dbms_sql.execute(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			dbms_sql.close_cursor(v_cur);
			RAISE;
	END;
	dbms_sql.close_cursor(v_cur);
END;


PROCEDURE TraceClob(
	in_sql			CLOB
)
AS
	v_sql			DBMS_SQL.VARCHAR2S;
	v_chunk			VARCHAR2(32767);
	v_upperbound	NUMBER;
	v_cur			INTEGER;
	v_ret			NUMBER;
BEGIN
	v_upperbound := ceil(dbms_lob.getlength(in_sql) / 32767);
	FOR i IN 1..v_upperbound
	LOOP
		v_chunk := dbms_lob.substr(in_sql, 32767, ((i - 1) * 32767) + 1);
		dbms_output.put(v_chunk);
	END LOOP;
	dbms_output.put_line('');
	IF SUBSTR(v_chunk, -1) = ';' THEN
		dbms_output.put_line('/');
	ELSE
		dbms_output.put_line(';');
	END IF;
END;

PROCEDURE ExecuteDDL(
	in_ddl			t_ddl
)
AS
BEGIN
	IF in_ddl.count = 0 THEN
		RETURN;
	END IF;
	FOR i in in_ddl.first .. in_ddl.last LOOP
		IF m_trace THEN
			TraceClob(in_ddl(i));
		END IF;
		IF NOT m_trace_only THEN
			ExecuteClob(in_ddl(i));
		END IF;
	END LOOP;
END;

PROCEDURE EnableTrace
AS
BEGIN
	m_trace := TRUE;
END;

PROCEDURE DisableTrace
AS
BEGIN
	m_trace := FALSE;
END;

PROCEDURE EnableTraceOnly
AS
BEGIN
	m_trace := TRUE;
	m_trace_only := TRUE;
END;

PROCEDURE DisableTraceOnly
AS
BEGIN
	m_trace := FALSE;
	m_trace_only := FALSE;
END;

PROCEDURE RecreateViews
AS
	v_ddl t_ddl default t_ddl();
BEGIN
	FOR r IN (SELECT tab_sid
				FROM tab
			   WHERE managed = 1) LOOP
		CreateView(r.tab_sid, v_ddl);
	END LOOP;
	
	FOR r IN (SELECT DISTINCT app_sid
	            FROM tab) loop
	    CreateItemDescriptionView(r.app_sid, v_ddl);
	END LOOP;
	
	FOR r IN (SELECT tab_sid
				FROM tab
			   WHERE managed = 1) LOOP
		CreateTriggers(r.tab_sid, v_ddl);
	END LOOP;
	IF v_ddl.count = 0 THEN
		RETURN;
	END IF;

	ExecuteDDL(v_ddl);
END;

PROCEDURE RecreateViewInternal(
	in_tab_sid			IN				tab.tab_sid%TYPE,
	io_ddl				IN OUT NOCOPY	t_ddl
)
AS
	v_managed					tab.managed%TYPE;
BEGIN
	-- Recreate the view + triggers if the table is managed
	SELECT managed
	  INTO v_managed
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	IF v_managed = 1 THEN
		CreateView(in_tab_sid, io_ddl);
		CreateItemDescriptionView(GetAppSidForTable(in_tab_sid), io_ddl);
		CreateTriggers(in_tab_sid, io_ddl);
		ExecuteDDL(io_ddl);
	END IF;
END;

PROCEDURE RecreateViewInternal(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
AS
	v_ddl		t_ddl DEFAULT t_ddl();
BEGIN
	RecreateViewInternal(in_tab_sid, v_ddl);
END;

PROCEDURE RecreateView(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
AS
BEGIN
	-- XXX: need some separate permission type?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied writing to table with sid '||in_tab_sid);
	END IF;
	
	RecreateViewInternal(in_tab_sid);
END;

PROCEDURE RecreateView(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
)
AS
	v_tab_sid					tab.tab_sid%TYPE;
BEGIN
	
	BEGIN
		SELECT tab_sid
		  INTO v_tab_sid
		  FROM tab
		 WHERE oracle_schema = dq(in_oracle_schema)
		   AND oracle_table = dq(in_oracle_table)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find table '||in_oracle_schema||'.'||in_oracle_table);
	END;
	RecreateView(v_tab_sid);
END;

PROCEDURE Normalise(
	in_owner					IN	VARCHAR2,
	in_table_name				IN	VARCHAR2,
	out_owner					OUT	VARCHAR2,
	out_table_name				OUT	VARCHAR2
)
AS
BEGIN
	BEGIN
		SELECT owner, table_name
		  INTO out_owner, out_table_name
		  FROM all_tables
		 WHERE owner = dq(in_owner) AND table_name = dq(in_table_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Could not find the table '||in_owner||'.'||in_table_name);
	END;
END;

/*
Comments are:

attribute_list: attribute | attribute "," att_list
attribute: name | name "=" value
name: [A-Za-z][A-Za-z0-9-_]*
value: quoted | unquoted
unquoted: [A-Za-z0-9]
quoted: "[^"]*"
[ \t]+: chomped

e.g.

description="This is a column description", file, file_mime=doc_mime, file_name=doc_name

Note: this doesn't allow quotes in descriptions, that's probably ok to be going on with...
*/
FUNCTION ParseComments(
	in_comments		IN				all_tab_comments.comments%TYPE,
	io_state		IN OUT NOCOPY	CommentParseState
)
RETURN BOOLEAN
AS
BEGIN
	IF in_comments IS NULL OR io_state.pos > LENGTH(in_comments) THEN
		RETURN FALSE;
	END IF;

	io_state.name := REGEXP_SUBSTR(in_comments, '[ \t]*[A-Za-z][A-Za-z0-9-_]*[ \t]*', io_state.pos);
	IF io_state.name IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Expected "name" at offset '||io_state.pos||' in the comment '||in_comments);
	END IF;
	io_state.pos := io_state.pos + LENGTH(io_state.name);
	io_state.name := LOWER(TRIM(io_state.name));
	
	io_state.sep := SUBSTR(in_comments, io_state.pos, 1);
	IF io_state.sep IS NOT NULL AND io_state.sep NOT IN ('=', ',') THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Expected "=" at offset '||io_state.pos||' in the comment '||in_comments);
	END IF;		
	io_state.pos := io_state.pos + 1;
	
	IF io_state.sep = '=' THEN
		io_state.value := REGEXP_SUBSTR(in_comments, '[ \t]*(("[^"]*")|([A-Za-z0-9-_]+))[ \t]*', io_state.pos);
		io_state.pos := io_state.pos + LENGTH(io_state.value);
		io_state.value := TRIM(io_state.value);
		IF io_state.value IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 
				'Expected "quoted_value" or "unquoted_value" at offset '||io_state.pos||
				' in the comment '||in_comments);
		END IF;
		IF SUBSTR(io_state.value, 1, 1) = '"' THEN
			io_state.quoted := TRUE;
			io_state.value := SUBSTR(io_state.value, 2, LENGTH(io_state.value) - 2);
		ELSE
			io_state.quoted := FALSE;
		END IF;
    
		io_state.sep := SUBSTR(in_comments, io_state.pos, 1);
		IF io_state.sep IS NOT NULL AND io_state.sep <> ',' THEN
			RAISE_APPLICATION_ERROR(-20001, 
				'Expected "," at offset '||io_state.pos||' in the comment '||in_comments);
		END IF;
		io_state.pos := io_state.pos + 1;
	ELSE
		io_state.value := NULL;
		io_state.quoted := FALSE;
	END IF;

	RETURN TRUE;
END;

PROCEDURE CreateIssueTable(
	in_tab_sid					IN				tab_column.tab_sid%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_owner					tab.oracle_schema%TYPE;
	v_table_name			tab.oracle_table%TYPE;
	v_managed				tab.managed%TYPE;
	v_pk_columns			t_string_list;
	v_s						VARCHAR2(4000);
	v_cols					VARCHAR2(4000);
	v_cnt					NUMBER;
	v_col_type				tab_column.col_type%TYPE;
	v_app_col_name			tab_column.oracle_column%TYPE;
	v_pk_cons_id			tab.pk_cons_id%TYPE;
	v_parent_pk_cons_id		tab.pk_cons_id%TYPE;
	v_fk_cons_id			fk_cons.fk_cons_id%TYPE;
	v_j						NUMBER;
	v_itab_sid				tab.tab_sid%TYPE;
	v_l_tab					VARCHAR2(100);
	v_issue_pk_cons_id		tab.pk_cons_id%TYPE;
	v_app_sid_column_sid	tab_column.column_sid%TYPE;
	v_issue_id_column_sid	tab_column.column_sid%TYPE;
BEGIN
	UPDATE tab
	   SET issues = 1
	 WHERE tab_sid = in_tab_sid;

	SELECT oracle_schema, oracle_table, managed, pk_cons_id
	  INTO v_owner, v_table_name, v_managed, v_parent_pk_cons_id
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	
	-- check for an existing issue join table 
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tables
	 WHERE owner = v_owner AND (
		(table_name = 'I$' || v_table_name AND v_managed = 0)
		OR (table_name = 'C$I$' || v_table_name AND v_managed = 1));
		
	IF v_cnt > 0 THEN
		RETURN;
	END IF;

	-- get the pk columns
	GetPkCols(in_tab_sid, v_pk_columns);
	IF v_pk_columns.COUNT = 0 THEN
		-- the table is partially registered, so read the table definition			
	    SELECT acc.column_name
	      BULK COLLECT INTO v_pk_columns
	      FROM all_cons_columns acc, all_constraints ac
	     WHERE ac.constraint_type = 'P' AND ac.owner = v_owner AND ac.table_name = v_table_name
	       AND ac.owner = acc.owner AND ac.constraint_name = acc.constraint_name
	     ORDER BY acc.position; 
	     
		IF v_pk_columns.COUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue must have a primary key');
		END IF;
	END IF;


	-- get a comma separated list of the primary key columns (we'll use this later when
	-- adding a primary key constraint to our new table, but we do it here as it applies
	-- to both managed and unmanaged tables	
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		-- skip the column if it's in the PK and marked app as we are going to add one
		IF v_app_col_name IS NULL OR v_pk_columns(i) != v_app_col_name THEN
			v_cols := comma(v_cols)||q(v_pk_columns(i));
		END IF;
	END LOOP;
	v_cols := v_cols||',app_sid,issue_id';
	dbms_output.put_line('hello, cols = '||v_cols||', cnt= '||v_pk_columns.COUNT);

	-- if the parent table is managed, then we need to manage the issues table too -- add the extra
	-- required columns to do this, and also insert relevant column data in tab / tab_column
	IF v_managed = 1 THEN
		SecurableObject_pkg.CreateSO(security_pkg.GetACT(), SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms'), class_pkg.GetClassID('CMSTable'), 
			q(v_owner)||'.'||q('I$'||v_table_name), v_itab_sid);

		INSERT INTO tab
			(tab_sid, app_sid, oracle_schema, oracle_table, managed, auto_registered)
		VALUES
			(v_itab_sid, SYS_CONTEXT('SECURITY', 'APP'), v_owner, 'I$'||v_table_name, 1, 0);

		INSERT INTO uk_cons
			(uk_cons_id, tab_sid)
		VALUES
			(uk_cons_id_seq.NEXTVAL, v_itab_sid)
		RETURNING
			uk_cons_id INTO v_pk_cons_id;
			
		UPDATE tab
		   SET pk_cons_id = v_pk_cons_id
		 WHERE tab_sid = v_itab_sid;

		v_s :=
			'create table '||q(v_owner)||'.'||q('C$I$' || v_table_name)||' as'||chr(10)||
			'    select ';
		v_j := 1;
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF v_pk_columns(i) = 'ISSUE_ID' THEN
				RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has a column named ISSUE_ID which is not supported');
			END IF;			
	
			-- skip the column if it's in the PK and marked app as we are going to add one
			-- XXX: ought to check for two app columns in the PK (but that's nuts)
			SELECT col_type
			  INTO v_col_type
			  FROM tab_column
			 WHERE tab_sid = in_tab_sid and oracle_column = v_pk_columns(i);
			IF v_col_type = CT_APP_SID THEN
				IF v_app_col_name IS NOT NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has two app columns in the primary key, which is not supported');
				END IF;
				v_app_col_name := v_pk_columns(i);
			ELSE
				v_s := v_s||'t.'||q(v_pk_columns(i))||', ';
				INSERT INTO tab_column
					(column_sid, tab_sid, oracle_column, pos)
				VALUES
					(column_id_seq.NEXTVAL, v_itab_sid, v_pk_columns(i), v_j);
				INSERT INTO uk_cons_col
					(uk_cons_id, column_sid, pos)
				VALUES
					(v_pk_cons_id, column_id_seq.CURRVAL, v_j);
				v_j := v_j + 1;
			END IF;
		END LOOP;
		v_s := v_s||'i.app_sid, i.issue_id'||chr(10)||
			'      from '||q(v_owner)||'.'||q('C$'||v_table_name)||' t, csr.issue i'||chr(10)||
			'     where 1 = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
		
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' modify app_sid default sys_context(''security'',''app'')';
		
		INSERT INTO tab_column
			(column_sid, tab_sid, oracle_column, pos)
		VALUES
			(column_id_seq.NEXTVAL, v_itab_sid, 'APP_SID', v_j)
		RETURNING
			column_sid INTO v_app_sid_column_sid;
		INSERT INTO uk_cons_col
			(uk_cons_id, column_sid, pos)
		VALUES
			(v_pk_cons_id, column_id_seq.CURRVAL, v_j);
		INSERT INTO tab_column
			(column_sid, tab_sid, oracle_column, pos)
		VALUES
			(column_id_seq.NEXTVAL, v_itab_sid, 'ISSUE_ID', v_j + 1)
		RETURNING
			column_sid INTO v_issue_id_column_sid;
		INSERT INTO uk_cons_col
			(uk_cons_id, column_sid, pos)
		VALUES
			(v_pk_cons_id, column_id_seq.CURRVAL, v_j + 1);

		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' add'||chr(10)||
			'('||chr(10)||
			'    context_id number(10) default 0 not null,'||chr(10)||
			'    created_dtm timestamp default sys_extract_utc(systimestamp) not null,'||chr(10)||
			'    retired_dtm timestamp,'||chr(10)||
			'    locked_by number(10),'||chr(10)||
			'    vers number(10) default 1 not null,'||chr(10)||
			'    changed_by number(10) not null,'||chr(10)||
			'    change_description varchar2(2000)'||chr(10)||
			')';

		-- Add a PK constraint on context,pk columns,vers
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' add primary key (context_id,'||v_cols||',vers)';

		-- Create and populate the lock table
		v_l_tab := q(v_owner)||'.'||q('L$I$'||v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'create table '||v_l_tab||' as'||chr(10)||
			'    select '||v_cols||chr(10)||
			'      from '||q(v_owner)||'.'||q('C$I$'||v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'alter table '||v_l_tab||' add primary key ('||v_cols||')';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' add locked_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'update '||v_l_tab||' set locked_by = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' modify locked_by not null';
			
		-- fk to issue
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'grant references on csr.issue to '||q(v_owner);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' add foreign key (app_sid, issue_id) references csr.issue (app_sid, issue_id) on delete cascade';
		
		-- if issue is already registered then add the shadow RI constraint
		BEGIN
			SELECT pk_cons_id
			  INTO v_issue_pk_cons_id
			  FROM tab
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND oracle_schema = 'CSR' AND oracle_table = 'ISSUE';
			  
			INSERT INTO fk_cons
				(fk_cons_id, tab_sid, r_cons_id, delete_rule)
			VALUES
				(fk_cons_id_seq.NEXTVAL, v_itab_sid, v_issue_pk_cons_id, 'C');
			INSERT INTO fk_cons_col 
				(fk_cons_id, column_sid, pos)
			VALUES
				(fk_cons_id_seq.CURRVAL, v_app_sid_column_sid, 1);
			INSERT INTO fk_cons_col 
				(fk_cons_id, column_sid, pos)
			VALUES
				(fk_cons_id_seq.CURRVAL, v_issue_id_column_sid, 2);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- issue doesn't exist, this constraint will be created when it is registered
		END;				
		
		-- fk to the parent table
		INSERT INTO fk_cons
			(fk_cons_id, tab_sid, r_cons_id, delete_rule)
		VALUES
			(fk_cons_id_seq.NEXTVAL, v_itab_sid, v_parent_pk_cons_id, 'C');
		v_j := 1;
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF v_app_col_name IS NULL OR v_pk_columns(i) != v_app_col_name THEN -- skip app_sid as this always goes last
				INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
					SELECT fk_cons_id_seq.CURRVAL, tc.column_sid, v_j
					  FROM tab_column tc
					 WHERE tc.tab_sid = v_itab_sid
					   AND oracle_column = v_pk_columns(i);
				v_j := v_j + 1;
			END IF;
		END LOOP;
		IF v_app_col_name IS NOT NULL THEN
			INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
				SELECT fk_cons_id_seq.CURRVAL, ukcc.column_sid, v_j
				  FROM uk_cons_col ukcc, tab_column tc
				 WHERE ukcc.uk_cons_id = v_pk_cons_id
				   AND ukcc.app_sid = tc.app_sid AND ukcc.column_sid = tc.column_sid
				   AND tc.oracle_column = v_app_col_name;
		END IF;
	
		-- We need to run CreateView/CreateTriggers after the table is created
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'begin'||chr(10)||
			'    cms.tab_pkg.RecreateView('||v_itab_sid||');'||chr(10)||
			'end;';
	ELSE
		v_s :=
			'create table '||q(v_owner)||'.'||q('I$' || v_table_name)||' as'||chr(10)||
			'    select ';
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF v_pk_columns(i) = 'ISSUE_ID' THEN
				RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has a column named ISSUE_ID which is not supported');
			END IF;			
	
			-- skip the column if it's in the PK and marked app as we are going to add one
			-- XXX: ought to check for two app columns in the PK (but that's nuts)
			SELECT col_type
			  INTO v_col_type
			  FROM tab_column
			 WHERE tab_sid = in_tab_sid and oracle_column = v_pk_columns(i);
			IF v_col_type = CT_APP_SID THEN
				IF v_app_col_name IS NOT NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has two app columns in the primary key, which is not supported');
				END IF;
				v_app_col_name := v_pk_columns(i);
			ELSE
				v_s := v_s||'t.'||q(v_pk_columns(i))||', ';
			END IF;
		END LOOP;

		v_s := v_s||'i.app_sid, i.issue_id'||chr(10)||
			'      from '||q(v_owner)||'.'||q(v_table_name)||' t, csr.issue i'||chr(10)||
			'     where 1 = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
		
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' modify app_sid default sys_context(''security'',''app'')';

		-- we now need to add a primary key constraint since we created it using
		-- create table select....
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' add primary key ('||v_cols||')';
			
		-- fk to issue
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'grant references on csr.issue to '||q(v_owner);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' add foreign key (app_sid, issue_id) references csr.issue (app_sid, issue_id) on delete cascade';
		
		-- fk to the parent table
		v_s := 'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' add foreign key (';
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF i != v_pk_columns.COUNT THEN 
				v_s := v_s||', ';
			END IF;
			IF v_col_type = CT_APP_SID THEN
				v_s := v_s||'APP_SID';
			ELSE
				v_s := v_s||q(v_pk_columns(i));
			END IF;
		END LOOP;
		v_s := v_s||') references '||q(v_owner)||'.'||q(v_table_name)||' (';
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF i != v_pk_columns.COUNT THEN 
				v_s := v_s||', ';
			END IF;
			v_s := v_s||q(v_pk_columns(i));
		END LOOP;
		v_s := v_s||') on delete cascade';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
		
		-- ensure i$xxx is marked as NOT autoregistered
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'begin'||chr(10)||
			'    cms.tab_pkg.RegisterTable('''||v_owner||''', ''I$'||v_table_name||''', FALSE, FALSE);'||chr(10)||
			'end;';
	END IF;

	-- add the issue type for the app (not sure if this is used though?)
	-- this is done via the generated DDL to avoid this package depending on csr
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'begin'||chr(10)||
		'    begin'||chr(10)||
		'        insert into csr.issue_type'||chr(10)||
		'            (issue_type_id, label)'||chr(10)||
		'        values'||chr(10)||
		'            (csr.csr_data_pkg.ISSUE_CMS, ''CMS issue'');'||chr(10)||
		'    exception'||chr(10)||
		'        when dup_val_on_index then'||chr(10)||
		'            null;'||chr(10)||
		'    end;'||chr(10)||
		'end;';

	-- ensure csr.issue is registered unmanaged
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'begin'||chr(10)||
		'    cms.tab_pkg.RegisterTable(''CSR'', ''ISSUE'', FALSE, FALSE);'||chr(10)||
		'end;';
END;

PROCEDURE ParseTableComments(
	in_tab_sid					IN				tab_column.tab_sid%TYPE,
	in_comments					IN				all_tab_comments.comments%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_state		CommentParseState;
BEGIN
	-- Clear existing fields
	UPDATE tab
	   SET format_sql = null,
	   	   description = null
	 WHERE tab_sid = in_tab_sid;

	WHILE ParseComments(in_comments, v_state) LOOP
		CASE
			WHEN v_state.name IN ('description', 'desc') THEN
				UPDATE tab
				   SET description = v_state.value
				 WHERE tab_sid = in_tab_sid;
				 
			WHEN v_state.name IN ('description_column', 'description_col', 'desc_col') THEN
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				
				-- Check the column exists in the table
				DECLARE
					v_dummy NUMBER(1);
				BEGIN
					SELECT 1
					  INTO v_dummy
					  FROM tab_column
					 WHERE tab_sid = in_tab_sid AND oracle_column = v_state.value;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table with sid '||
							in_tab_sid||' does not have the description column named '||v_state.value);
				END;
				
				UPDATE tab
				   SET format_sql = v_state.value
				 WHERE tab_sid = in_tab_sid;
			
			WHEN v_state.name IN ('cmseditor') THEN	 
				UPDATE tab
				   SET cms_editor = 1
				 WHERE tab_sid = in_tab_sid;
				
			WHEN v_state.name IN ('issues') THEN
				CreateIssueTable(in_tab_sid, io_ddl);
				
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'The attribute '||v_state.name||
					' is not known in the table comment '||in_comments);
		END CASE;
	END LOOP;
END;

PROCEDURE ParseColumnComments(
	in_tab_sid					IN		tab_column.tab_sid%TYPE,
	in_column_sid				IN		tab_column.column_sid%TYPE,
	in_comments					IN		all_col_comments.comments%TYPE
)
AS
	v_state							CommentParseState;
BEGIN
	-- Clear existing fields
	UPDATE tab_column
	   SET help = null,
	   	   description = null,
	   	   check_msg = null,
	   	   enumerated_desc_field = null,
	   	   enumerated_pos_field = null,
	   	   enumerated_hidden_field = null,
	   	   tree_desc_field = null,
	   	   tree_id_field = null,
	   	   tree_parent_id_field = null
	 WHERE tab_sid = in_tab_sid AND column_sid = in_column_sid;
	UPDATE tab_column
	   SET master_column_sid = NULL
	 WHERE master_column_sid = in_column_sid;
	 
	WHILE ParseComments(in_comments, v_state) LOOP
		CASE
			WHEN v_state.name = 'html' THEN
				UPDATE tab_column 
				   SET col_type = tab_pkg.CT_HTML
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('desc', 'description') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"description" without a value in the column comment '||in_comments);
				END IF;
				UPDATE tab_column
				   SET description = v_state.value
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'help' THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001,
						'"help" without a value in the column comment '||in_comments);
				END IF;
				UPDATE tab_column
				   SET help = v_state.value
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'check' THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001,
						'"check" without a value in the column comment '||in_comments);
				END IF;
				UPDATE tab_column
				   SET check_msg = v_state.value
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'file' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FILE_DATA, master_column_sid = in_column_sid
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'link' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_LINK
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'image' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_IMAGE
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'time' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_TIME
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'user' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_USER
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'region' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_REGION
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'indicator' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_INDICATOR
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'measure' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_MEASURE
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'measure_sid' THEN
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_MEASURE_SID, master_column_sid = in_column_sid
				 WHERE oracle_column = v_state.value AND tab_sid = in_tab_sid;
				IF SQL%ROWCOUNT = 0 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The column '||v_state.value||
						' specified as "measure_sid" does not exist in the column comment '||in_comments);
				END IF;

			WHEN v_state.name = 'file_mime' THEN
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FILE_MIME, master_column_sid = in_column_sid
				 WHERE oracle_column = v_state.value AND tab_sid = in_tab_sid;
				IF SQL%ROWCOUNT = 0 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The column '||v_state.value||
						' specified as "file_mime" does not exist in the column comment '||in_comments);
				END IF;

			WHEN v_state.name = 'file_name' THEN
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FILE_NAME, master_column_sid = in_column_sid
				 WHERE oracle_column = v_state.value AND tab_sid = in_tab_sid;
				IF SQL%ROWCOUNT = 0 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The column '||v_state.value||
						' specified as "file_name" does not exist in the column comment '||in_comments);
				END IF;
				
			WHEN v_state.name IN ('enumerated', 'enum') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_ENUMERATED
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'search_enum' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_SEARCH_ENUM
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'cascade_enum' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CASCADE_ENUM
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'video' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_VIDEO_CODE
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'chart' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CHART
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name IN ('document','doc') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_DOCUMENT
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name IN ('enumerated_pos_field', 'enum_pos_field', 'enum_pos_col') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"enumerated_pos_field" without a value in the column comment '||in_comments);
				END IF;
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET enumerated_pos_field = v_state.value
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('enumerated_hidden_field', 'enum_hidden_field', 'enum_hidden_col') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"enumerated_hidden_field" without a value in the column comment '||in_comments);
				END IF;
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET enumerated_hidden_field = v_state.value
				 WHERE column_sid = in_column_sid;
				 				 
			WHEN v_state.name IN ('enumerated_desc_field', 'enum_desc_field', 'enum_desc_col') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"enumerated_desc_field" without a value in the column comment '||in_comments);
				END IF;
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET enumerated_desc_field = v_state.value
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name IN ('autoincrement', 'auto') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_AUTO_INCREMENT
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('app', 'app_sid') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_APP_SID
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('pos', 'position') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_POSITION
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('bool', 'boolean') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_BOOLEAN
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'flow_item' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FLOW_ITEM
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'flow_region' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FLOW_REGION
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'calc' THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"calc" without a value in the column comment '||in_comments);
				END IF;
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CALC, calc_xml = v_state.value
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'helper_pkg' THEN
				IF v_state.value IS NULL THEN				
					RAISE_APPLICATION_ERROR(-20001, 
						'"helper_pkg" without a value in the column comment '||in_comments);
				END IF;
				UPDATE tab_column
				   SET helper_pkg = v_state.value
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'value_placeholder' THEN
				UPDATE tab_column
				   SET value_placeholder = 1
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'enforce_nullability' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_ENFORCE_NULLABILITY
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'company' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_COMPANY
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name = 'tree' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_TREE
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('tree_desc_field', 'tree_desc_col') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"tree_desc_field" without a value in the column comment '||in_comments);
				END IF;
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET tree_desc_field = v_state.value
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('tree_id_field', 'tree_id_col') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"tree_id_field" without a value in the column comment '||in_comments);
				END IF;
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET tree_id_field = v_state.value
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('tree_parent_id_field', 'tree_parent_id_col') THEN
				IF v_state.value IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 
						'"tree_parent_id_field" without a value in the column comment '||in_comments);
				END IF;
				IF NOT v_state.quoted THEN
					v_state.value := UPPER(v_state.value);
				END IF;
				UPDATE tab_column
				   SET tree_parent_id_field = v_state.value
				 WHERE column_sid = in_column_sid;

			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'The attribute '||v_state.name||
					' is not known in the column comment '||in_comments);
		END CASE;
	END LOOP;
END;

PROCEDURE ReParseComments(
	in_oracle_schema			IN		tab.oracle_schema%TYPE,
	in_oracle_table		        IN		tab.oracle_table%TYPE
)
AS
	v_tab_sid						tab.tab_sid%TYPE;
	v_managed						tab.managed%TYPE;
	v_ddl 							t_ddl DEFAULT t_ddl();
	v_table_name					VARCHAR2(30);
	v_owner							VARCHAR2(30);
	v_flow_item_count				NUMBER;
	v_flow_region_count				NUMBER;
BEGIN
	BEGIN
		SELECT tab_sid, managed, oracle_schema, oracle_table
		  INTO v_tab_sid, v_managed, v_owner, v_table_name
		  FROM tab
		 WHERE oracle_schema = dq(in_oracle_schema)
		   AND oracle_table = dq(in_oracle_table)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find table '||in_oracle_schema||'.'||in_oracle_table);
	END;
	IF v_managed = 1 THEN
		v_table_name := 'C$'||v_table_name;
	END IF;

	FOR r IN (SELECT atc.comments
			   FROM all_tab_comments atc
			  WHERE atc.owner = v_owner AND atc.table_name = v_table_name) LOOP
		ParseTableComments(v_tab_sid, r.comments, v_ddl);
	END LOOP;

	FOR r IN (SELECT tc.column_sid, acc.comments
			   FROM tab_column tc, all_col_comments acc
			  WHERE tc.tab_sid = v_tab_sid AND 
				   acc.owner = v_owner AND acc.table_name = v_table_name AND 
				   acc.column_name = tc.oracle_column AND acc.comments IS NOT NULL
	) LOOP
		ParseColumnComments(v_tab_sid, r.column_sid, r.comments);
    END LOOP;
    
	-- Check the workflow configuration is correct (1 flow item column, 1 flow region column)
	SELECT COUNT(*)
	  INTO v_flow_item_count
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid
	   AND col_type = tab_pkg.CT_FLOW_ITEM;

	IF v_flow_item_count > 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'At most one column can be marked flow_item');
	END IF;
	 
	SELECT COUNT(*)
	  INTO v_flow_region_count
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid
	   AND col_type = tab_pkg.CT_FLOW_REGION;

	IF v_flow_region_count > 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'At most one column can be marked flow_region');
	END IF;
	 
	IF v_flow_item_count != v_flow_region_count THEN
		RAISE_APPLICATION_ERROR(-20001, 'For workflow items, both a flow_region and a flow_item column must be present');
	END IF;
    
	ExecuteDDL(v_ddl);    
END;

/* Steps for refreshing:

   1. Drop any shadow foreign key constraints that involve unmanaged tables
   2. Drop any check constraints for either managed or unmanaged tables
   3. Drop all structure information for unmanaged tables: that's all
      foreign / unique keys, the columns, the check constraints, but leaving
      the table object. This is so that security on the table SO, filters, 
      publications etc that hang off the table SOs are not destroyed.
   4. Re-register all the unmanaged tables.
   5. Register all the parent tables of the managed tables again (to 
      account for any new REFERENCES PARENT(PARENT_COLUMN) that may
      have appeared)
   6. Clean up any dropped tables
   7. Reshadow the check constraints on the managed tables
   8. Reshadow column nullability on the managed tables
 */
PROCEDURE RefreshUnmanaged(
	in_app_sid				IN	tab.app_sid%TYPE DEFAULT NULL
)
AS
	v_tables_sid	security_pkg.T_SID_ID;
	v_ddl 			t_ddl DEFAULT t_ddl();
	v_tab_set		t_tab_set;
    v_col_name 		VARCHAR(30);
    v_cnt      		NUMBER;
    v_all_apps		BOOLEAN DEFAULT FALSE;
    v_last_app		security_pkg.T_SID_ID;
    v_nullable		VARCHAR2(1);
BEGIN
	IF SYS_CONTEXT('SECURITY', 'ACT') IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001,
			'You need to be logged on to refresh tables');
	END IF;
	IF NOT NVL(SYS_CONTEXT('SECURITY', 'APP'), -1) = NVL(in_app_sid, -1) THEN
		RAISE_APPLICATION_ERROR(-20001,
			'You can only refresh tables for the application set in your security context');
	END IF;	
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		v_all_apps := TRUE;
	END IF;
	
	-- We need to delete all FKs on unmanaged tables, and also all FKs on
	-- managed tables that reference unmanaged tables.
	DELETE
	  FROM fk_cons_col
	 WHERE fk_cons_id IN (
	 		SELECT fkc.fk_cons_id
	 		  FROM fk_cons fkc, uk_cons ukc, tab ukt, tab fkt
	 		 WHERE fkc.r_cons_id = ukc.uk_cons_id AND fkc.tab_sid = fkt.tab_sid AND
	 		 	   ukc.tab_sid = ukt.tab_sid AND ukt.managed = 0 AND
	 		 	   (in_app_sid IS NULL OR (ukt.app_sid = fkt.app_sid AND
	 		 	   						   ukt.app_sid = in_app_sid AND 
	 		 	   						   fkt.app_sid = in_app_sid)));
	DELETE
	  FROM fk_cons
	 WHERE fk_cons_id IN (
	 		SELECT fkc.fk_cons_id
	 		  FROM fk_cons fkc, uk_cons ukc, tab ukt, tab fkt
	 		 WHERE fkc.r_cons_id = ukc.uk_cons_id AND fkc.tab_sid = fkt.tab_sid AND
	 		 	   ukc.tab_sid = ukt.tab_sid AND ukt.managed = 0 AND
	 		 	   (in_app_sid IS NULL OR (ukt.app_sid = fkt.app_sid AND
	 		 	   						   ukt.app_sid = in_app_sid AND 
	 		 	   						   fkt.app_sid = in_app_sid)));
	 		 	   								  
	-- Delete all uks on unmanaged tables
	UPDATE tab
	   SET pk_cons_id = NULL
	 WHERE managed = 0 AND
	 	   (in_app_sid IS NULL OR app_sid = in_app_sid);
	DELETE
	  FROM uk_cons_col
	 WHERE uk_cons_id IN (
	 		SELECT uk_cons_id
	 		  FROM uk_cons ukc, tab ukt
	 		 WHERE ukc.tab_sid = ukt.tab_sid AND ukt.managed = 0 AND 
	 		 	   (in_app_sid IS NULL OR ukt.app_sid = in_app_sid));
	DELETE
	  FROM uk_cons
	 WHERE uk_cons_id IN (
	 		SELECT uk_cons_id
	 		  FROM uk_cons ukc, tab ukt
	 		 WHERE ukc.tab_sid = ukt.tab_sid AND ukt.managed = 0 AND
	 		 	   (in_app_sid IS NULL OR ukt.app_sid = in_app_sid));

	-- Delete all check constraints
	DELETE
	  FROM ck_cons_col
	 WHERE ck_cons_id IN (
	 		SELECT ck_cons_id
	 		  FROM ck_cons ck, tab ckt
		 		 WHERE ck.tab_sid = ckt.tab_sid AND
		 		 	   (in_app_sid IS NULL OR ckt.app_sid = in_app_sid));
	DELETE
	  FROM ck_cons
	 WHERE ck_cons_id IN (
	 		SELECT ck_cons_id
	 		  FROM ck_cons ck, tab ckt
	 		 WHERE ck.tab_sid = ckt.tab_sid AND
	 		 	   (in_app_sid IS NULL OR ckt.app_sid = in_app_sid));

	-- Save the tab sids of the tables we want to reregister
	DELETE
	  FROM temp_refresh_table;
	INSERT INTO temp_refresh_table (tab_sid, app_sid, oracle_schema, oracle_table)
		SELECT tab_sid, app_sid, oracle_schema, oracle_table
		  FROM tab
		 WHERE managed = 0 AND (in_app_sid IS NULL OR app_sid = in_app_sid);

	-- Nuke the columns (to account for structure changes)
	DELETE
	  FROM tab_column
	 WHERE tab_sid IN (
	 		SELECT tab_sid
	 		  FROM tab
	 		 WHERE managed = 0 AND
	 		 	  (in_app_sid IS NULL OR app_sid = in_app_sid));
	
	-- We have to leave the rows in tab hanging around to keep associated 
	-- filters, publications, etc alive

	-- Run over the temporary list and reregister the tables
	FOR r IN (SELECT tt.app_sid, tt.oracle_schema, tt.oracle_table
				FROM temp_refresh_table tt, all_tables atc
			   WHERE tt.oracle_schema = atc.owner AND tt.oracle_table = atc.table_name
			ORDER BY tt.app_sid) LOOP
		
		-- Ensure we create new objects with the correct application sid
		IF NVL(v_last_app, 0) <> r.app_sid AND v_all_apps THEN
			security_pkg.SetApp(r.app_sid);
			v_last_app := r.app_sid;
		END IF;
		
		-- Get the cms container, if nothing found we assume the table is
		-- hanging around from a deleted application and leave it in the 'munched' state
		BEGIN
			v_tables_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), r.app_sid, 'cms');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				v_tables_sid := NULL;
		END;
		
		IF v_tables_sid IS NOT NULL THEN
			RegisterTable_(v_tables_sid, r.oracle_schema, r.oracle_table, FALSE, TRUE, TRUE, v_ddl, v_tab_set);
		END IF;
	END LOOP;
	
	-- now we want to refresh RI + check constraints on all of the managed tables
	-- to do that, all we need to do is register any new parents -- reregistering
	-- old parents has already added the appropriate fks
	-- note all of the parents are unmanaged (otherwise the RI wouldn't be in the
	-- data dictionary)
	v_last_app := NULL;
	FOR r IN (SELECT t.app_sid, pap.owner, pap.table_name
				FROM tab t, all_constraints pap, all_constraints cac
			   WHERE cac.owner = t.oracle_schema AND cac.table_name = 'C$'||t.oracle_table AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
			   		 cac.r_constraint_name = pap.constraint_name AND			   		 
			   		 (pap.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = t.app_sid) OR
			   		  (pap.owner, pap.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = t.app_sid)) AND
			   		 (in_app_sid IS NULL OR t.app_sid = in_app_sid) AND
			   		 t.managed = 1
			GROUP BY t.app_sid, pap.owner, pap.table_name) LOOP
		
		-- Ensure we create new objects with the correct application sid
		IF NVL(v_last_app, 0) <> r.app_sid AND v_all_apps THEN
			security_pkg.SetApp(r.app_sid);
			v_last_app := r.app_sid;
		END IF;

		-- Get the cms container.  If it's not found assume this is a hangover
		-- from a deleted application.
		-- XXX: should we should munch it?
		BEGIN
			v_tables_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'APP'), r.app_sid, 'cms');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_tables_sid := NULL;
		END;
		
		IF v_tables_sid IS NOT NULL THEN
			RegisterTable_(v_tables_sid, r.owner, r.table_name, FALSE, TRUE, TRUE, v_ddl, v_tab_set);		
		END IF;
	END LOOP;

	-- Clean up any dropped tables
	IF v_all_apps THEN
		security_pkg.SetApp(NULL);
	END IF;
	FOR r IN (SELECT tab_sid
				FROM temp_refresh_table
			   WHERE done = 0) LOOP	
		BEGIN
			SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), r.tab_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				-- clean up metadata for missing SOs
				DeleteObject(security_pkg.GetACT(), r.tab_sid);
		END;		
	END LOOP;

	-- shadow check constraints on managed tables
    FOR r IN (SELECT t.tab_sid, ac.owner, ac.constraint_name, ac.search_condition
                FROM all_constraints ac, tab t
               WHERE ac.constraint_type = 'C' AND t.oracle_schema = ac.owner AND 
               		 t.managed = 1 AND 'C$'||t.oracle_table = ac.table_name AND
               		 (in_app_sid IS NULL OR t.app_sid = in_app_sid))  LOOP
        
        SELECT COUNT(*), MIN(acc.column_name), MIN(atc.nullable)
          INTO v_cnt, v_col_name, v_nullable
          FROM all_cons_columns acc, all_tab_columns atc
         WHERE acc.owner = r.owner AND acc.constraint_name = r.constraint_name AND
         	   acc.owner = atc.owner AND acc.table_name = atc.table_name AND
         	   acc.column_name = atc.column_name;

        IF NOT (v_cnt = 1 AND r.search_condition = '"'||v_col_name||'" IS NOT NULL' AND v_nullable = 'N') THEN
            INSERT INTO ck_cons (ck_cons_id, tab_sid, search_condition)
            VALUES (ck_cons_id_seq.nextval, r.tab_sid, r.search_condition);
            
            INSERT INTO ck_cons_col (ck_cons_id, column_sid)
                SELECT ck_cons_id_seq.currval, tc.column_sid
                  FROM tab_column tc, all_cons_columns acc
                 WHERE acc.column_name = tc.oracle_column AND tc.tab_sid = r.tab_sid AND
                       acc.owner = r.owner AND acc.constraint_name = r.constraint_name;
        END IF;
    END LOOP;
    
   	-- Reshadow column nullability on the managed tables
   	-- XXX: Using a loop as can't see a good correlated update statement involving all_tab_columns
   	-- and merge into doesn't work with the some security policy on tab_column
   	FOR r IN (
   		SELECT tc.tab_sid, tc.column_sid, atc.nullable
	   	  FROM tab t, tab_column tc, all_tab_columns atc
	   	 WHERE (in_app_sid IS NULL OR t.app_sid = in_app_sid)
	   	   AND t.managed = 1 
	   	   AND tc.tab_sid = t.tab_sid
	   	   AND atc.owner = t.oracle_schema
	   	   AND atc.table_name = 'C$'||t.oracle_table
	   	   AND atc.column_name = tc.oracle_column
	   	   AND tc.nullable != atc.nullable
   	) LOOP
   		UPDATE tab_column
   		   SET nullable = r.nullable
   		 WHERE tab_sid = r.tab_sid
   		   AND column_sid = r.column_sid;
   	END LOOP;
   
END;

PROCEDURE RegisterTable_(
	in_tables_sid				IN				security_pkg.T_SID_ID,
	in_owner					IN				tab.oracle_schema%TYPE,
	in_table_name				IN				tab.oracle_table%TYPE,
	in_managed					IN				BOOLEAN,
	in_auto_registered			IN				BOOLEAN,
	in_refresh					IN				BOOLEAN,
	io_ddl						IN OUT NOCOPY	t_ddl,
	io_tab_set					IN OUT NOCOPY	t_tab_set
)
AS
	v_sid_id			security_pkg.T_SID_ID;
	v_pk_name			VARCHAR2(30);
	v_c_tab				VARCHAR2(100);
	v_l_tab				VARCHAR2(100);
	v_item_desc_col		VARCHAR2(30);
	v_table_name		VARCHAR2(30) DEFAULT in_table_name;
	v_ctable_name		VARCHAR2(30);
	v_s					CLOB;
	v_cols				CLOB;
    v_col_name 			VARCHAR2(30);
    v_nullable			VARCHAR2(1);
    v_cnt      			NUMBER;	
    v_cnt2				NUMBER;
    v_problem_col_names	VARCHAR2(2000);
	v_managed			tab.managed%TYPE DEFAULT 0;
	v_registered		BOOLEAN DEFAULT FALSE;
	v_auto_registered	tab.auto_registered%TYPE;
	v_actual_table_name	VARCHAR2(30);
	v_upgrade			BOOLEAN DEFAULT FALSE;
	v_parse_comments	BOOLEAN DEFAULT FALSE;
	v_parent_managed	tab.managed%TYPE;
	v_uk_cons_id		uk_cons.uk_cons_id%TYPE;
	v_fk_cons_id		fk_cons.fk_cons_id%TYPE;
	v_x			number(10);
BEGIN
	security_pkg.debugmsg('register '||in_owner||'.'||in_table_name);
	-- Catch dodgy calls
	IF in_managed AND in_refresh THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Cannot refresh the managed table '||in_owner||'.'||in_table_name);
	END IF;
	
	-- XXX: this is an assumption, probably good enough though
	-- it happens when managing a table that a managed table already
	-- has a reference on
	IF SUBSTR(in_table_name, 1, 2) = 'C$' THEN
		v_table_name := SUBSTR(in_table_name, 3);
	END IF;

	-- Check if this table has been versioned already
	IF NOT in_refresh THEN
		BEGIN
			SELECT tab_sid, managed, auto_registered
			  INTO v_sid_id, v_managed, v_auto_registered
			  FROM tab
			 WHERE oracle_schema = in_owner AND oracle_table = v_table_name AND
			 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');

			-- see if this is an upgrade to managed
			v_upgrade := v_managed = 0 AND in_managed;
			
			-- If we are manually registering a previously automatically registered table,
			-- then just flip the flag
			IF NOT v_upgrade THEN
				IF v_auto_registered = 1 AND NOT in_auto_registered THEN
					UPDATE tab
					   SET auto_registered = 0
					 WHERE tab_sid = v_sid_id;
				END IF;
			
				RETURN;
			END IF;
	
			v_registered := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	
	-- If we are refreshing, then check if this one has already been refreshed,
	-- or if it's managed.
	ELSE
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM temp_refresh_table
		 WHERE oracle_schema = in_owner AND oracle_table = v_table_name AND done = 1;
		IF v_cnt = 1 THEN
			RETURN;
		END IF;
		
		SELECT NVL(SUM(managed), 0)
		  INTO v_cnt
		  FROM tab
		 WHERE oracle_schema = in_owner AND oracle_table = v_table_name AND
		 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
		IF v_cnt = 1 THEN
			RETURN;
		END IF;
		
		-- mark it as done
		UPDATE temp_refresh_table
		   SET done = 1
		 WHERE oracle_schema = in_owner AND oracle_table = v_table_name;
		IF SQL%ROWCOUNT = 0 THEN
			INSERT INTO temp_refresh_table
				(oracle_schema, oracle_table, done)
			VALUES
				(in_owner, v_table_name, 1);
		END IF;
	END IF;
		
	-- Set the base table name (v_managed = 1 => the table is _currently_ managed)
	IF v_managed = 1 THEN
		v_actual_table_name := 'C$'||v_table_name;
	ELSE
		v_actual_table_name := v_table_name;
	END IF;

	-- Check that we have a primary key (only required for managed tables)
	IF in_managed THEN
		BEGIN
			SELECT constraint_name
			  INTO v_pk_name
			  FROM all_constraints
			 WHERE owner = in_owner AND table_name = v_actual_table_name AND constraint_type = 'P';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table '||
					in_owner||'.'||v_table_name||' does not have a primary key');
		END;

		-- check that the columns we'll add don't already exist (not as silly as it sounds since CREATED_DTM
		-- is a perfectly likely column to exist!)		
		BEGIN
			SELECT LTRIM(SYS_CONNECT_BY_PATH(column_name, ', '),', ')
			  INTO v_problem_col_names
			  FROM (
				SELECT column_name, rownum rn
				  FROM all_tab_columns
				 WHERE owner = in_owner AND table_name = v_actual_table_name
				   AND column_name IN ('CREATED_DTM','RETIRED_DTM','LOCKED_BY','VERS','CHANGED_BY','CHANGE_DESCRIPTION')
			  )
			  WHERE connect_by_isleaf = 1
			  START WITH rn = 1
			 CONNECT BY PRIOR rn = rn - 1;
			 
			IF v_problem_col_names IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table '||
					in_owner||'.'||v_table_name||' contains one or more reserved column names: '||v_problem_col_names);
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- no problems...
		END;
	END IF;

	-- Create the SO and table metadata if it's not already present
	IF NOT v_registered THEN
		v_managed := BoolToNum(in_managed);

		-- If refreshing check if there is already an SO / tab entry
		IF in_refresh THEN
			BEGIN
				SELECT tab_sid
				  INTO v_sid_id
				  FROM temp_refresh_table
				 WHERE oracle_schema = in_owner AND oracle_table = v_table_name;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- ok, it's new
			END;
		END IF;

		IF v_sid_id IS NULL THEN
			SecurableObject_pkg.CreateSO(security_pkg.GetACT(), in_tables_sid, class_pkg.GetClassID('CMSTable'), 
				q(in_owner)||'.'||q(v_table_name), v_sid_id);

			-- Managed tables are always considered to be manually registered (even those that
			-- were grabbed via a cascade to register the children).
			--
			-- This seems to be sensible since they are protected by triggers hooked up to
			-- the table SO, and by default only admins will be able to do anything to the table.
			--
			IF v_managed = 1 THEN
				v_auto_registered := 0;
			ELSE
				v_auto_registered := BoolToNum(in_auto_registered);
			END IF;

			INSERT INTO tab
				(tab_sid, app_sid, oracle_schema, oracle_table, managed, auto_registered)
			VALUES
				(v_sid_id, SYS_CONTEXT('SECURITY', 'APP'), in_owner, v_table_name, v_managed, v_auto_registered);
		END IF;
		
		-- umm -- stragg belongs in another schema so use this approach instead to avoid an unneeded dependency
		IF v_managed = 1 THEN
			BEGIN
				SELECT LTRIM(SYS_CONNECT_BY_PATH(column_name, ', '),', ')
				  INTO v_problem_col_names
				  FROM (
					SELECT column_name, rownum rn
					  FROM all_tab_columns
					 WHERE owner = in_owner AND table_name = v_actual_table_name
					   AND LENGTH(column_name) > 28 -- to allow for N$ prefixes etc
				  )
				  WHERE connect_by_isleaf = 1
				  START WITH rn = 1
				 CONNECT BY PRIOR rn = rn - 1;
				IF v_problem_col_names IS NOT NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'The table '||in_owner||'.'||v_table_name||' has column names longer than the maximum size of 28 characters: '||v_problem_col_names);			
				END IF;
	
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- jolly good -- no problems.
			END;
		END IF;

		-- Stuff in columns		
		INSERT INTO tab_column (column_sid, tab_sid, oracle_column, description, pos, data_type, data_length, data_precision, data_scale, nullable, char_length)
			SELECT column_id_seq.NEXTVAL, v_sid_id, column_name, null, column_id, data_type, data_length, data_precision, data_scale, nullable, char_length
			  FROM all_tab_columns
			 WHERE owner = in_owner AND table_name = v_actual_table_name;
			 
		-- Parse table comments -- we do this later so that the keys have been shadowed which is
		-- necessary for handling the issues join table		
		v_parse_comments := TRUE;

	-- If it's an upgrade to managed then note we've done this
	ELSE
		IF in_managed THEN
			UPDATE tab
			   SET managed = 1, auto_registered = 0
			 WHERE tab_sid = v_sid_id;
		END IF;
	END IF;

	IF in_managed THEN
		-- Remember this for view generation
		io_tab_set(v_sid_id) := 1;

		-- Rename the underlying table to the C$ variant
		v_c_tab := q(in_owner) || '.' || q('C$' || v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||q(in_owner)||'.'||q(v_table_name)||' rename to '||q('C$'||v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add context_id number(10) default 0 not null';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add created_dtm timestamp default sys_extract_utc(systimestamp) not null';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add retired_dtm timestamp';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add locked_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add vers number(10) default 1 not null';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add changed_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add change_description varchar2(2000)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'update '||v_c_tab||' set changed_by = '||security_pkg.GetSID();
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' modify changed_by not null';
			
		-- Create and populate the lock table
		v_l_tab := q(in_owner)||'.'||q('L$'||v_table_name);
		v_s :=
			'create table '||v_l_tab||' as'||chr(10)||
			'    select ';
		FOR r IN (SELECT column_name
					FROM all_cons_columns
				   WHERE owner = in_owner AND constraint_name = v_pk_name) LOOP
			v_cols := comma(v_cols) || q(r.column_name);
		END LOOP;
		v_s := v_s || v_cols || chr(10) ||
			'      from '||v_c_tab;		
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			v_s;
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'alter table '||v_l_tab||' add primary key ('||v_cols||')';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' add locked_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'update '||v_l_tab||' set locked_by = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' modify locked_by not null';		
	END IF;	

	-- Shadow or manage the UKs/PKs on this table
	-- If we are upgrading to managed, they are already shadowed, so we just drop the original keys
	IF NOT v_registered OR v_upgrade THEN
		
		security_pkg.debugmsg('shadowing uks/pks for '||in_owner||'.'||v_actual_table_name);
		if not v_upgrade then
			security_pkg.debugmsg('!upgrade');
		else
			security_pkg.debugmsg('upgrade');
		end if;

		-- Shadow UK/PKs
		FOR r IN (SELECT /*+all_rows*/ constraint_name, constraint_type
					FROM all_constraints
				   WHERE owner = in_owner AND table_name = v_actual_table_name and constraint_type in ('U','P')) LOOP
			security_pkg.debugmsg('shadowing '||r.constraint_name||' ('||r.constraint_type||')');

			IF NOT v_upgrade THEN
				INSERT INTO uk_cons (uk_cons_id, tab_sid)
				VALUES (uk_cons_id_seq.NEXTVAL, v_sid_id);
		
				INSERT INTO uk_cons_col (uk_cons_id, column_sid, pos)
					SELECT uk_cons_id_seq.CURRVAL, tc.column_sid, acc.position
					  FROM tab_column tc, all_cons_columns acc
					 WHERE acc.owner = in_owner AND acc.constraint_name = r.constraint_name AND
					 	   tc.oracle_column = acc.column_name AND tc.tab_sid = v_sid_id;

				IF r.constraint_type = 'P' THEN
					UPDATE tab
					   SET pk_cons_id = uk_cons_id_seq.CURRVAL
					 WHERE oracle_schema = in_owner AND oracle_table = v_table_name;
				END IF;
			END IF;
			
			IF in_managed THEN
				-- Drop the UK/PK constraint
				io_ddl.extend(1);
				io_ddl(io_ddl.count) :=
					'alter table '||q(in_owner)||'.'||q('C$'||v_table_name)||
					' drop constraint '||q(r.constraint_name)||' cascade';
					
				-- Add a PK constraint on context,pk columns,vers
				-- (We don't do this for UKs as there's nothing to key on)
				IF r.constraint_type = 'P' THEN
					v_s := 'alter table '||v_c_tab||' add primary key (context_id';
					FOR s IN (SELECT /*+all_rows*/ column_name
								FROM all_cons_columns acc
							   WHERE acc.owner = in_owner AND acc.constraint_name = r.constraint_name) LOOP
						v_s := v_s || ',' || q(s.column_name);
					END LOOP;
					v_s := v_s || ',vers)';
					
					io_ddl.extend(1);
					io_ddl(io_ddl.count) := v_s;
				END IF;
			END IF;			
		END LOOP;
			
		-- shadow check constraints
		IF NOT v_upgrade THEN
		    FOR r IN (SELECT ac.owner, ac.constraint_name, ac.search_condition
		                FROM all_constraints ac
		               WHERE ac.constraint_type = 'C' AND ac.owner = in_owner AND
		               		 ac.table_name = v_actual_table_name) LOOP
		        
		        SELECT COUNT(*), MIN(acc.column_name), MIN(atc.nullable)
		          INTO v_cnt, v_col_name, v_nullable
		          FROM all_cons_columns acc, all_tab_columns atc
		         WHERE acc.owner = r.owner AND acc.constraint_name = r.constraint_name AND
		         	   acc.owner = atc.owner AND acc.table_name = atc.table_name AND
		         	   acc.column_name = atc.column_name;
	
		        IF NOT (v_cnt = 1 AND r.search_condition = '"'||v_col_name||'" IS NOT NULL' AND v_nullable = 'N') THEN
		            INSERT INTO ck_cons (ck_cons_id, tab_sid, search_condition)
		            VALUES (ck_cons_id_seq.nextval, v_sid_id, r.search_condition);
		            
		            INSERT INTO ck_cons_col (ck_cons_id, column_sid)
		                SELECT ck_cons_id_seq.currval, tc.column_sid
		                  FROM tab_column tc, all_cons_columns acc
		                 WHERE acc.column_name = tc.oracle_column AND tc.tab_sid = v_sid_id AND
		                       acc.owner = r.owner AND acc.constraint_name = r.constraint_name;
		        END IF;
		    END LOOP;
		END IF;
	END IF;

	-- Register child tables
	FOR r IN (SELECT cac.owner, cac.table_name
			    FROM all_constraints cac, all_constraints pap
			   WHERE pap.owner = in_owner AND pap.table_name = v_actual_table_name AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = in_owner AND 
			   		 cac.r_owner = pap.owner AND cac.r_constraint_name = pap.constraint_name AND
			   		 (cac.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
			   		  (cac.owner, cac.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))
			GROUP BY cac.owner, cac.table_name) LOOP
		security_pkg.debugmsg('from: '||in_owner||'.'||v_actual_table_name||', registering child table '||r.owner||'.'||r.table_name);
		RegisterTable_(in_tables_sid, r.owner, r.table_name, in_managed, TRUE, in_refresh, io_ddl, io_tab_set);
	END LOOP;

	-- Shadow FKs from child tables
	-- If we are upgrading to managed, they are already shadowed, so we just drop the original keys
	IF NOT v_registered OR v_upgrade THEN
		
		security_pkg.debugmsg('shadowing fks for '||in_owner||'.'||v_actual_table_name);

		-- Shadow UK/PKs
		FOR r IN (SELECT /*+all_rows*/ owner, constraint_name, constraint_type
					FROM all_constraints
				   WHERE owner = in_owner AND table_name = v_actual_table_name and constraint_type in ('U','P')) LOOP
				   	
			-- find the UK constraint that matches	   
			SELECT DISTINCT suk.uk_cons_id
			  INTO v_uk_cons_id
			  FROM cms.uk suk, all_cons_columns uk, all_constraints u
			 WHERE suk.owner = uk.owner AND suk.table_name = uk.table_name
			   AND suk.column_name = uk.column_name AND suk.pos = uk.position
			   AND u.owner = uk.owner AND u.constraint_name = uk.constraint_name
			   AND u.owner = r.owner AND u.constraint_name = r.constraint_name
			   AND (SELECT COUNT(*) 
			   		  FROM uk_cons_col sukcc
			   		 WHERE sukcc.app_sid = suk.app_sid AND sukcc.uk_cons_id = suk.uk_cons_id) =
			   	   (SELECT COUNT(*)
			   	      FROM all_cons_columns acc
			   	     WHERE acc.owner = uk.owner AND acc.constraint_name = uk.constraint_name);
			security_pkg.debugmsg('shadowing fks for '||r.constraint_name||' ('||r.constraint_type||')');
	
			-- Shadow FKs for child tables
			FOR s IN (SELECT /*+all_rows*/ ac.owner, ac.constraint_name, ac.table_name, ac.delete_rule
		  			    FROM all_constraints ac
		 			   WHERE ac.r_owner = in_owner AND ac.r_constraint_name = r.constraint_name AND
		       				 ac.constraint_type = 'R' AND 
					   		 (ac.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
					   		  (ac.owner, ac.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))) LOOP
				security_pkg.debugmsg('shadowing '||s.owner||'.'||s.constraint_name||', '||s.table_name);

				-- TODO: check this assumption?
				IF SUBSTR(s.table_name, 1, 2) = 'C$' THEN
					v_ctable_name := SUBSTR(s.table_name, 3);
				ELSE
					v_ctable_name := s.table_name;
				END IF;
		
				IF NOT v_upgrade THEN
					-- check that the constraint doesn't already exist
					security_pkg.debugmsg('matching up on '||s.owner||'.'||v_ctable_name||'.'||s.constraint_name);
					
					SELECT MIN(fk_cons_id)
					  INTO v_fk_cons_id
					  FROM (SELECT COUNT(*) ora_cnt, COUNT(fuk.fk_cons_id) fk_cnt, MIN(fuk.fk_cons_id) fk_cons_id
							  FROM all_constraints u 
							  JOIN all_cons_columns uk ON u.owner = uk.owner AND u.constraint_name = uk.constraint_name
							  LEFT JOIN cms.fk fuk ON fuk.owner = uk.owner AND fuk.table_name = v_ctable_name AND fuk.column_name = uk.column_name AND fuk.pos = uk.position
							  WHERE u.owner = s.owner
								AND u.constraint_name = s.constraint_name			   
							  GROUP BY u.owner, u.constraint_name)
					 WHERE fk_cnt = ora_cnt;
					
					   
					IF v_fk_cons_id IS NULL THEN
						INSERT INTO fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule)
							SELECT fk_cons_id_seq.NEXTVAL, tab_sid, v_uk_cons_id,
								   DECODE(s.delete_rule, 'CASCADE', 'C', 'SET NULL', 'N', 'R')
							  FROM tab
							 WHERE oracle_schema = s.owner AND oracle_table = v_ctable_name AND
							 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
							 
						INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
							SELECT fk_cons_id_seq.CURRVAL, tc.column_sid, acc.position
							  FROM tab_column tc, tab t, all_cons_columns acc
							 WHERE acc.owner = s.owner AND t.oracle_schema = s.owner AND t.oracle_schema = acc.owner AND
							 	   t.oracle_table = v_ctable_name AND acc.constraint_name = s.constraint_name AND 
							 	   t.tab_sid = tc.tab_sid AND acc.column_name = tc.oracle_column AND
							 	   t.app_sid = SYS_CONTEXT('SECURITY', 'APP');
						select fk_cons_id_seq.CURRVAL into v_cnt from dual;
						security_pkg.debugmsg('didn''t match so added fk with id '||v_cnt);
							 	   
					ELSE
						security_pkg.debugmsg(' constraint already exists with id ' || v_fk_cons_id);
					END IF;
				END IF;
					
				IF in_managed THEN
					-- Drop the FK constraint
					io_ddl.extend(1);
					io_ddl(io_ddl.count) :=
						'begin'||chr(10)||
						'    for r in (select constraint_name from all_constraints where owner = '||sq(in_owner)||' and constraint_name = '||sq(v_table_name)||') loop'||chr(10)||
						'        execute immediate ''alter table '||replace(q(in_owner),'''','''''')||'.'||replace(q('C$'||v_table_name),'''','''''')||' drop constraint ''||r.constraint_name;'||chr(10)||
						'    end loop;'||chr(10)||
						'end;';
				END IF;
			END LOOP;
			
		END LOOP;
		
	END IF;

	-- Register parent tables unmanaged.  This is done to simplify
	-- the handling of e.g. foreign key pickers on user tables or similar things.
	FOR r IN (SELECT pap.owner, pap.table_name
				FROM all_constraints pap, all_constraints cac
			   WHERE cac.owner = in_owner AND cac.table_name = v_actual_table_name AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
			   		 cac.r_constraint_name = pap.constraint_name AND
			   		 (pap.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
			   		  (pap.owner, pap.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))
			GROUP BY pap.owner, pap.table_name) LOOP
		security_pkg.debugmsg('from: '||in_owner||'.'||v_actual_table_name||', registering parent table '||r.owner||'.'||r.table_name);		
		RegisterTable_(in_tables_sid, r.owner, r.table_name, FALSE, TRUE, in_refresh, io_ddl, io_tab_set);
	END LOOP;

	-- Add FKs to parent tables that are unmanaged and already registered
	FOR r IN (SELECT pap.owner, pap.table_name, t.tab_sid, t.managed
				FROM all_constraints pap, all_constraints cac, tab t
			   WHERE t.oracle_schema = pap.owner AND t.oracle_table = pap.table_name AND t.managed = 0 AND
			   	     cac.owner = in_owner AND cac.table_name = v_actual_table_name AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
			   		 cac.r_constraint_name = pap.constraint_name AND
			   		 (pap.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
			   		  (pap.owner, pap.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))
			GROUP BY pap.owner, pap.table_name, t.tab_sid, t.managed) LOOP
		security_pkg.debugmsg('from: '||in_owner||'.'||v_actual_table_name||', finding RI for parent table '||r.owner||'.'||r.table_name);
		
		FOR s IN (SELECT pap.owner, pap.table_name, pap.constraint_name, 
				 		 cac.owner child_owner, cac.delete_rule child_delete_rule, cac.constraint_name child_constraint_name
					FROM all_constraints pap, all_constraints cac
				   WHERE cac.owner = in_owner AND cac.table_name = v_actual_table_name AND
				   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
				   		 cac.r_constraint_name = pap.constraint_name AND
				   		 pap.owner = r.owner AND pap.table_name = r.table_name) LOOP
			
			security_pkg.debugmsg('adding R constraint from '||in_owner||'.'||v_actual_table_name||'.'||s.child_constraint_name||
				' to existing unmanaged table constraint '||s.owner||'.'||s.table_name||'.'||s.constraint_name);

			-- now we need to find the shadowed PK/UK corresponding to this constraint
			BEGIN
				SELECT DISTINCT suk.uk_cons_id
				  INTO v_uk_cons_id
				  FROM cms.uk suk, all_cons_columns uk, all_constraints u
				 WHERE suk.owner = uk.owner AND suk.table_name = uk.table_name
				   AND suk.column_name = uk.column_name AND suk.pos = uk.position
				   AND u.owner = uk.owner AND u.constraint_name = uk.constraint_name
				   AND u.owner = s.owner AND u.constraint_name = s.constraint_name
				   AND (SELECT COUNT(*) 
				   		  FROM uk_cons_col sukcc
				   		 WHERE sukcc.app_sid = suk.app_sid AND sukcc.uk_cons_id = suk.uk_cons_id) =
				   	   (SELECT COUNT(*)
				   	      FROM all_cons_columns acc
				   	     WHERE acc.owner = uk.owner AND acc.constraint_name = uk.constraint_name);
			EXCEPTION
				WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
					-- (this is just for debugging, it can go eventually)
					declare 
						v_num number;
					begin
						select count(*) into v_num from uk_cons where tab_sid=r.tab_sid;
						security_pkg.debugmsg('parent sid is '||r.tab_sid||', uks='||v_num);
					end;
					FOR qr IN (SELECT * FROM cms.uk WHERE owner = s.owner AND table_name = s.table_name) LOOP
						security_pkg.debugmsg(qr.uk_cons_id||','||qr.uk_tab_sid||','||qr.owner||','||qr.table_name||','||qr.column_name||','||qr.pos);
					END LOOP;
					RAISE;
			END;
			security_pkg.debugmsg('matched constraint to shadow uk constraint '||v_uk_cons_id);
			
			-- check that the constraint doesn't already exist
			security_pkg.debugmsg('matching up on '||s.owner||'.'||v_actual_table_name||'.'||s.child_constraint_name);
			
			for qx in ( 
				SELECT owner, constraint_name, fk_cons_id
				  FROM (
					SELECT u.owner, u.constraint_name, count(*) ora_cnt, count(fuk.fk_cons_id) fk_cnt, MIN(fuk.fk_cons_id) fk_cons_id
					  FROM all_constraints u 
						JOIN all_cons_columns uk ON u.owner = uk.owner AND u.constraint_name = uk.constraint_name
						LEFT JOIN cms.fk fuk ON fuk.owner = uk.owner AND fuk.table_name = v_actual_table_name AND fuk.column_name = uk.column_name AND fuk.pos = uk.position
					  WHERE u.owner = s.child_owner
						AND u.constraint_name = s.child_constraint_name
					GROUP BY u.owner, u.constraint_name
				 )
				 WHERE fk_cnt = ora_cnt) loop
				security_pkg.debugmsg('match '||qx.owner||'.'||qx.constraint_name||' to '||qx.fk_cons_id);
			end loop;
			
			-- we have to check that the columns match AND the number of columns match too
			SELECT MIN(fk_cons_id)
			  INTO v_fk_cons_id
			  FROM (SELECT COUNT(*) ora_cnt, COUNT(fuk.fk_cons_id) fk_cnt, MIN(fuk.fk_cons_id) fk_cons_id
					  FROM all_constraints u 
					  JOIN all_cons_columns uk ON u.owner = uk.owner AND u.constraint_name = uk.constraint_name
					  LEFT JOIN cms.fk fuk ON fuk.owner = uk.owner AND fuk.table_name = v_actual_table_name AND fuk.column_name = uk.column_name AND fuk.pos = uk.position
					  WHERE u.owner = s.child_owner
						AND u.constraint_name = s.child_constraint_name			   
					  GROUP BY u.owner, u.constraint_name)
			 WHERE fk_cnt = ora_cnt;
			   
			   for qr in (
					select fkcc.fk_cons_id,fkcc.column_sid 
					  from fk_cons_col fkcc,fk_cons fkc 
					 where fkc.tab_sid = v_sid_id 
						and fkc.fk_cons_id=fkcc.fk_cons_id 
					  order by fkcc.fk_cons_id, fkcc.pos
			   ) 
			   loop
					security_pkg.debugmsG('fk '||qr.fk_cons_id||', col_sid = '||qr.column_sid);
			   end loop;
			   
			IF v_fk_cons_id IS NULL THEN
--			IF v_cnt2 != v_cnt THEN -- not the same constraint or missing
				INSERT INTO fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule)
					SELECT fk_cons_id_seq.NEXTVAL, v_sid_id, v_uk_cons_id,
						   DECODE(s.child_delete_rule, 'CASCADE', 'C', 'SET NULL', 'N', 'R')
					  FROM dual;
	
				INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
					SELECT fk_cons_id_seq.CURRVAL, tc.column_sid, acc.position
					  FROM tab_column tc, tab t, all_cons_columns acc
					 WHERE acc.owner = s.child_owner AND t.oracle_schema = s.child_owner AND t.oracle_schema = acc.owner AND
					 	   t.oracle_table = v_actual_table_name AND acc.constraint_name = s.child_constraint_name AND 
					 	   t.tab_sid = tc.tab_sid AND acc.column_name = tc.oracle_column AND
					 	   t.app_sid = SYS_CONTEXT('SECURITY', 'APP');
				
				select fk_cons_id_seq.CURRVAL into v_cnt from dual;
				security_pkg.debugmsg('didn''t match so added fk with id '||v_cnt);
			ELSE
				security_pkg.debugmsg('existing fk is '||v_fk_cons_id);
			END IF;
		END LOOP;
	END LOOP;
	
	IF v_parse_comments THEN
		dbms_output.put_line('PARSING TABLE COMMENTS for ' ||v_actual_table_name||', MANAGED = '||v_managed);
		-- note that we get 0 or 1 rows from the query below
		FOR r IN (SELECT comments
					FROM all_tab_comments
				   WHERE owner = in_owner AND table_name = v_actual_table_name AND comments IS NOT NULL) LOOP
			ParseTableComments(v_sid_id, r.comments, io_ddl);
		END LOOP;
		
		-- Parse metadata in column descriptions, if any
		FOR r IN (SELECT tc.column_sid, acc.comments
					FROM all_col_comments acc, tab_column tc
				   WHERE tc.tab_sid = v_sid_id AND acc.owner = in_owner AND
			   			 acc.table_name = v_actual_table_name AND acc.column_name = tc.oracle_column AND 
			   			 acc.comments IS NOT NULL) LOOP
			ParseColumnComments(v_sid_id, r.column_sid, r.comments);
		END LOOP;
	END IF;		
END;

PROCEDURE UnregisterTable_(
	in_tab_sid					IN				tab.tab_sid%TYPE,
	in_owner					IN				tab.oracle_schema%TYPE,
	in_table_name				IN				tab.oracle_table%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_first			BOOLEAN;
	v_a				VARCHAR2(4000);
	v_b				VARCHAR2(4000);
	v_child_name	VARCHAR2(60);
BEGIN
	-- drop all the stuff that was created
	-- views
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop view ' || q(in_owner) || '.' || q('H$' || in_table_name);
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop view ' || q(in_owner) || '.' || q(in_table_name);
	-- lock table
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop table ' || q(in_owner) || '.' || q('L$' || in_table_name);
	-- triggers	(only triggers on the table; triggers on the view are dropped with the view,
	-- as is the fga policy)
	io_ddl(io_ddl.count) := 'drop trigger '||q(in_owner)||'.'||q('J$'||in_table_name);
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop trigger '||q(in_owner)||'.'||q('V$'||in_table_name);
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop trigger '||q(in_owner)||'.'||q('E$'||in_table_name);

	-- package wrapper
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop package ' || q(in_owner) || '.' || q('T$' || in_table_name);
	
	-- rename the table back to the base name
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q('C$' || in_table_name) || 
		' rename to ' || q(in_table_name);
	-- drop the pk
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) || 
		' drop primary key';
	-- delete any retired or unpublished data
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'delete from ' || q(in_owner) || '.' || q(in_table_name) || chr(10) ||
		 'where retired_dtm is not null or context_id <> 0';
		
	-- drop the extra columns we added
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) || 
		' drop column context_id';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) || 
		' drop column created_dtm';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column retired_dtm';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column locked_by';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column vers';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column changed_by';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column change_description';

	-- reinstate the unique constraints
	FOR r IN (SELECT ukc.uk_cons_id, 
					 CASE WHEN t.pk_cons_id = ukc.uk_cons_id THEN 1 ELSE 0 END is_pk
				FROM uk_cons ukc, tab t
			   WHERE t.tab_sid = in_tab_sid AND ukc.tab_sid = in_tab_sid AND
			   		 t.tab_sid = ukc.tab_sid) LOOP
	
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
			' add ';
		IF r.is_pk = 1 THEN
			io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || 'primary key (';
		ELSE
			io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || 'unique (';
		END IF;
		
		v_first := TRUE;
		FOR s IN (SELECT tc.oracle_column
					FROM uk_cons_col ukcc, tab_column tc
				   WHERE ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = tc.column_sid
				ORDER BY ukcc.pos) LOOP
			IF NOT v_first THEN
				io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || ',';
			END IF;
			v_first := FALSE;
			io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || q(s.oracle_column);
		END LOOP;
		io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || ')';
		
		-- reinstate any child FKs of the UK under consideration
		FOR fk IN (SELECT fkc.fk_cons_id, fkt.oracle_schema owner, fkt.oracle_table table_name, fkt.managed
					 FROM fk_cons fkc, tab fkt
				    WHERE fkc.r_cons_id = r.uk_cons_id AND fkc.tab_sid = fkt.tab_sid) LOOP
			v_a := NULL;
			v_b := NULL;

			FOR fkc IN (SELECT fktc.oracle_column column_name, uktc.oracle_column r_column_name
						  FROM fk_cons_col fkcc, tab_column fktc, uk_cons_col ukcc, tab_column uktc
					     WHERE fkcc.fk_cons_id = fk.fk_cons_id AND fkcc.column_sid = fktc.column_sid AND
					   		   ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = uktc.column_sid AND
					   		   ukcc.pos = fkcc.pos
					  ORDER BY ukcc.pos) LOOP
				IF v_a IS NOT NULL THEN
					v_a := v_a || ',';
					v_b := v_b || ',';
				END IF;
				v_a := v_a || q(fkc.column_name);
				v_b := v_b || q(fkc.r_column_name);
			END LOOP;
			
			IF fk.managed = 1 THEN
				v_child_name := q('C$' || fk.table_name);
			ELSE
				v_child_name := fk.table_name;
			END IF;
			io_ddl.extend(1);
			io_ddl(io_ddl.count) := 'alter table ' || q(fk.owner) || '.' || v_child_name ||
				' add foreign key (' || v_a || ') references ' || q(in_owner) || '.' || q(in_table_name) ||
				' (' || v_b || ')';
		END LOOP;
	END LOOP;
	
	-- stuff this table in a list so we don't try and unregister it twice
	INSERT INTO temp_refresh_table (tab_sid)
	VALUES (in_tab_sid);

	-- unregister any managed parent tables
	FOR r IN (SELECT ukt.tab_sid, ukt.oracle_schema, ukt.oracle_table
				FROM fk_cons fkc, uk_cons ukc, tab ukt
			   WHERE fkc.tab_sid = in_tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
			   		 ukc.tab_sid = ukt.tab_sid AND ukt.managed = 1 AND
			   		 ukt.tab_sid NOT IN (SELECT tab_sid FROM temp_refresh_table)
			GROUP BY ukt.tab_sid, ukt.oracle_schema, ukt.oracle_table) LOOP		
		UnregisterTable_(r.tab_sid, r.oracle_schema, r.oracle_table, io_ddl);
	END LOOP;
	
	-- Delete the SO
	securableObject_pkg.DeleteSO(security_pkg.GetACT(), in_tab_sid);
END;

PROCEDURE UnregisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
)
AS
	v_managed		tab.managed%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
	v_owner			tab.oracle_schema%TYPE;
	v_table_name	tab.oracle_table%TYPE;
	v_cms_sid		security_pkg.T_SID_ID;
	v_ddl 			t_ddl DEFAULT t_ddl();
BEGIN
	-- Get the CMS container
	v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	
	-- Get the table object
	BEGIN
		SELECT tab_sid, managed, oracle_schema, oracle_table
		  INTO v_tab_sid, v_managed, v_owner, v_table_name
		  FROM tab
		 WHERE oracle_schema = dq(in_oracle_schema) AND oracle_table = dq(in_oracle_table) AND
		 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'The table '||in_oracle_schema||'.'||in_oracle_table||' could not be found');
	END;
	
	-- TODO: probably want some stronger permission for altering the schema
	-- also might want to check the parent tables
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), v_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied unregistering the table '||in_oracle_schema||'.'||in_oracle_table||' with sid '||v_tab_sid);
	END IF;
	
	-- If it's managed, then we need to recurse to unregister the parent tables too
	IF v_managed = 1 THEN
		DELETE FROM temp_refresh_table;
		UnregisterTable_(v_tab_sid, v_owner, v_table_name, v_ddl);
		ExecuteDDL(v_ddl);
		
	-- Otherwise just drop the table SO
	ELSE
		-- Delete the SO
		securableobject_pkg.DeleteSO(security_pkg.GetACT(), v_tab_sid);
	END IF;
END;
	
PROCEDURE RegisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	VARCHAR2,
	in_managed					IN	BOOLEAN DEFAULT TRUE,
	in_allow_entire_schema		IN	BOOLEAN DEFAULT TRUE
)
AS
	v_ddl 			t_ddl DEFAULT t_ddl();
	v_tab_set		t_tab_set;
	v_owner			VARCHAR2(30);
	v_table_names	t_string_list;
	v_table_name	tab.oracle_table%TYPE;
	v_sid_id		security_pkg.T_SID_ID;
	v_cms_sid		security_pkg.T_SID_ID;
	v_managed		tab.managed%TYPE;
BEGIN	
	-- Get or create the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.SO_CONTAINER, 'cms', v_cms_sid);
	END;
	
	-- Treat the table name as a quoted list so we can do less typing
	ParseQuotedList(in_oracle_table, v_table_names);

	FOR i IN 1 .. v_table_names.COUNT LOOP
		v_table_name := dq(v_table_names(i));
		IF LENGTH(v_table_name) > 28 THEN
			RAISE_APPLICATION_ERROR(-20001,
				'The table name '||v_table_name||' is too long -- it can be at most 28 characters');
		END IF;

		-- Check if the table is already registered
		BEGIN
			SELECT managed, oracle_schema, oracle_table
			  INTO v_managed, v_owner, v_table_name
			  FROM tab
			 WHERE oracle_schema = dq(in_oracle_schema) AND oracle_table = v_table_name AND
				   app_sid = SYS_CONTEXT('SECURITY', 'APP');

			-- It's already registered, is this a request to unmanage the table?
			IF NOT in_managed AND v_managed = 1 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Cannot make the table '||in_oracle_schema||'.'||v_table_name||' unmanaged');
			END IF;
	
			-- RegisterTable_ can now do the business...
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- Normalise the owner/table name
				Normalise(in_oracle_schema, v_table_name, v_owner, v_table_name);		
		END;
	
		-- Add the schema or table to the application
		BEGIN
			IF in_allow_entire_schema THEN
				INSERT INTO app_schema
					(app_sid, oracle_schema)
				VALUES
					(SYS_CONTEXT('SECURITY', 'APP'), v_owner);
			ELSE
				INSERT INTO app_schema_table
					(app_sid, oracle_schema, oracle_table)
				VALUES
					(SYS_CONTEXT('SECURITY', 'APP'), v_owner, v_table_name);
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		RegisterTable_(v_cms_sid, v_owner, v_table_name, in_managed, FALSE, FALSE, v_ddl, v_tab_set);
		v_sid_id := v_tab_set.first;
		WHILE v_sid_id IS NOT NULL
		LOOP	
			CreateView(v_sid_id, v_ddl);
			v_sid_id := v_tab_set.next(v_sid_id);
		END LOOP;
		CreateItemDescriptionView(SYS_CONTEXT('SECURITY', 'APP'), v_ddl);
	
		v_sid_id := v_tab_set.first;
		WHILE v_sid_id IS NOT NULL
		LOOP	
			CreateTriggers(v_sid_id, v_ddl);
			v_sid_id := v_tab_set.next(v_sid_id);
		END LOOP;
	END LOOP;
	
	ExecuteDDL(v_ddl);
END;

PROCEDURE AllowTable(
	in_oracle_schema			IN	app_schema_table.oracle_schema%TYPE,
	in_oracle_table				IN	app_schema_table.oracle_table%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO app_schema_table (app_sid, oracle_schema, oracle_table)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_oracle_schema, in_oracle_table);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

-- TODO: nullable, default
PROCEDURE AddColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_type						IN	VARCHAR2,
	in_comment					IN	VARCHAR2 DEFAULT NULL,
	in_pos						IN	tab_column.pos%TYPE DEFAULT 0,
	in_calc_xml					IN	tab_column.calc_xml%TYPE DEFAULT NULL
)
AS
	v_ddl			t_ddl DEFAULT t_ddl();
	v_count			NUMBER;
	v_max_pos		tab_column.pos%TYPE;
	v_pos			tab_column.pos%TYPE DEFAULT in_pos;
	v_type			VARCHAR2(100) DEFAULT in_type;
	v_i				BINARY_INTEGER;
	v_j				BINARY_INTEGER;
	v_k				BINARY_INTEGER;
	v_prec			BINARY_INTEGER;
	v_scale			BINARY_INTEGER;
	v_tab_sid		tab.tab_sid%TYPE;
	v_column_sid	tab_column.column_sid%TYPE;
	v_ref_tab_sid	tab.tab_sid%TYPE;
	v_ref_col_sid	tab_column.column_sid%TYPE;
	v_data_length	NUMBER;
	v_char_length	NUMBER;
BEGIN
	GetTableForDDL(in_oracle_schema, in_oracle_table, v_tab_sid);
	
	IF LENGTH(in_oracle_column) > 28 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The column name '||in_oracle_column||' is too long -- it can be at most 28 characters'); -- to allow for N$ prefixes etc
	END IF;
	   
	-- Check for a duplicate name (TODO: ought to be a constraint...)
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_column
	 WHERE oracle_column = dq(in_oracle_column)
	   AND tab_sid = v_tab_sid;
	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 
			'The table '||in_oracle_schema||'.'||in_oracle_table||' already has a column named '||in_oracle_column);
	END IF;
	
	-- If pos is out of range, then fix it up
	SELECT MAX(pos)
	  INTO v_max_pos
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid;
	IF v_pos < 1 OR v_pos > v_max_pos THEN
		v_pos := v_max_pos + 1;
	END IF;
	
	-- parse type, prec '()'
	v_i := INSTR(in_type, '(');
	IF v_i <> 0 THEN
		v_j := INSTR(in_type, ')', v_i);
		IF v_j <= v_i + 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Invalid type '||in_type);
		END IF;
		v_type := SUBSTR(in_type, v_i + 1, v_j - v_i - 1);
		v_k := INSTR(v_type, ',');
		IF v_k <> 0 THEN
			v_prec := TO_NUMBER(SUBSTR(v_type, 1, v_k - 1));
			v_scale := TO_NUMBER(SUBSTR(v_type, v_k + 1));
			IF v_prec IS NULL OR v_scale IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Invalid type '||in_type);
			END IF;
		ELSE
			v_prec := TO_NUMBER(v_type);
			IF v_prec IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Invalid type '||in_type);
			END IF;
		END IF;
		v_type := SUBSTR(in_type, 1, v_i - 1);
	END IF;
	v_type := LOWER(v_type);
	IF v_type NOT IN ('varchar2','clob','blob','number','int','binary_double','date') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unsupported datatype '||in_type);
	END IF;
	IF v_type = 'varchar2' THEN
		IF v_scale IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'varchar2 may not have a scale ('||in_type||')');
		END IF;
		IF v_prec < 1 OR v_prec > 4000 THEN
			RAISE_APPLICATION_ERROR(-20001, 'varchar2 may have at minimum 1 and at most 4,000 characters ('||in_type||')');
		END IF;
		v_type := v_type || '('||v_prec||')';
		v_char_length := v_prec;
		v_data_length := v_prec;
		v_prec := NULL;
		v_scale := NULL;
	ELSIF v_type = 'number' THEN
		v_data_length := 22;
		IF v_scale IS NULL THEN
			v_scale := 0;
		END IF;
		IF v_prec IS NULL THEN
			v_prec := 0;
		END IF;
		IF v_prec < 1 OR v_prec > 38 THEN
			RAISE_APPLICATION_ERROR(-20001, 'numeric precision of specifier '||v_prec||' is out of range (1 to 38)');
		END IF;
		IF v_scale < -84 OR v_scale > 127 THEN
			RAISE_APPLICATION_ERROR(-20001, 'numeric scale of specifier '||v_scale||' is out of range (1 to 38)');
		END IF;
		v_type := v_type || '('||v_prec||','||v_scale||')';
	ELSE
		IF v_prec IS NOT NULL OR v_scale IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'precision or scale cannot be used with '||v_type);
		END IF;
	END IF;

	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'ALTER TABLE '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||
						  ' ADD '||q(dq(in_oracle_column))||' '||v_type;
	IF in_comment IS NOT NULL THEN
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'COMMENT ON COLUMN '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||
							  '.'||q(dq(in_oracle_column))||' IS '''||REPLACE(in_comment,'''','''''')||'''';
	END IF;
	  
	-- fix up metadata
	UPDATE tab_column
	   SET pos = pos + 1
	 WHERE pos >= v_pos;

	INSERT INTO tab_column 
		(column_sid, tab_sid, col_type, oracle_column, description, pos, calc_xml, 
		 data_type, data_length, data_precision, data_scale, nullable, char_length)
	VALUES
		(column_id_seq.NEXTVAL, v_tab_sid, CASE WHEN in_calc_xml IS NOT NULL THEN CT_CALC ELSE CT_NORMAL END, dq(in_oracle_column), null, v_pos, in_calc_xml,
		 UPPER(v_type), v_data_length, v_prec, v_scale, 'Y', v_char_length)
	RETURNING
		column_sid INTO v_column_sid;
	IF in_comment IS NOT NULL THEN
		ParseColumnComments(v_tab_sid, v_column_sid, in_comment);
	END IF;
	
	-- execute the DDL first, then recreate views -- we have to do it this way around
	-- as CreateTriggers looks at all_tab_columns
	ExecuteDDL(v_ddl);
	RecreateViewInternal(v_tab_sid);
END;

PROCEDURE ParseQuotedList(
	in_quoted_list				IN	VARCHAR2,
	out_string_list				OUT	t_string_list
)
AS
	v_pos	BINARY_INTEGER DEFAULT 1;
	v_name	VARCHAR2(1000);
	v_len	BINARY_INTEGER;
BEGIN
	v_len := NVL(LENGTH(in_quoted_list), 0);
	WHILE v_pos <= v_len LOOP
		v_name := REGEXP_SUBSTR(in_quoted_list, '[ \t]*(("[^"]*")|([^,]*))[ \t]*', v_pos);
		v_pos := v_pos + LENGTH(v_name);
		v_name := TRIM(v_name);
        IF v_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Expected a name at offset '||v_pos||' in the quoted list '||in_quoted_list);
        END IF;
		out_string_list(out_string_list.count + 1) := v_name;
		
		IF v_pos <= v_len THEN
			IF SUBSTR(in_quoted_list, v_pos, 1) <> ',' THEN
				RAISE_APPLICATION_ERROR(-20001,
					'Expected '','' at offset '||v_pos||' in the quoted list '||in_quoted_list);
			END IF;
            v_pos := v_pos + 1;
		END IF;		
	END LOOP;
	IF out_string_list.count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Empty quoted list');
	END IF;
END;

-- alter table X add unique (foo, bar);
PROCEDURE AddUniqueKey(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_columns			IN	VARCHAR2
)
AS
	v_cols			t_string_list;
	v_tab_sid		tab.tab_sid%TYPE;
	v_col_sid		tab_column.column_sid%TYPE;
	v_uk_cons_id	uk_cons.uk_cons_id%TYPE;
	v_check_sql		VARCHAR2(32767);
	v_violated		NUMBER;
BEGIN
	GetTableForDDL(in_oracle_schema, in_oracle_table, v_tab_sid);
	ParseQuotedList(in_oracle_columns, v_cols);
	
	INSERT INTO uk_cons
		(uk_cons_id, tab_sid)
	VALUES
		(uk_cons_id_seq.nextval, v_tab_sid)
	RETURNING
		uk_cons_id INTO v_uk_cons_id;
	FOR i IN 1 .. v_cols.COUNT LOOP
		BEGIN
			SELECT column_sid
			  INTO v_col_sid
			  FROM tab_column
			 WHERE tab_sid = v_tab_sid AND oracle_column = dq(v_cols(i));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001,
					'The column '||v_cols(i)||' does not exist in the table '||in_oracle_schema||'.'||in_oracle_table);
		END;
		INSERT INTO uk_cons_col
			(uk_cons_id, column_sid, pos)
		VALUES
			(v_uk_cons_id, v_col_sid, i);
	END LOOP;
	
	-- check the constraint wasn't violated
	v_check_sql := 
		'select min(1)'||chr(10)||
		'  from dual'||chr(10)||
		' where exists (select 1'||chr(10)||
		'                 from '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||chr(10)||
		'                where retired_dtm is null and vers > 0'||chr(10)||
		'             group by ';
	FOR i IN 1 .. v_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql || ', ';
		END IF;
		v_check_sql := v_check_sql || v_cols(i);
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||
		'               having count(*) > 1)';	
	EXECUTE IMMEDIATE v_check_sql INTO v_violated;
	
	IF v_violated IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001,
			'Cannot add a unique key on '||in_oracle_columns||' to the table '||in_oracle_schema||'.'||in_oracle_table||
			' since it contains duplicate rows');
	END IF;
	RecreateViewInternal(v_tab_sid);
END;

-- XXX: ought to check for duplicate fks
-- XXX: only checks for key violations globally (could have contexts with violated keys)
PROCEDURE AddForeignKey(
	in_from_schema				IN	tab.oracle_schema%TYPE,
	in_from_table				IN	tab.oracle_table%TYPE,
	in_from_columns				IN	VARCHAR2,
	in_to_schema				IN	tab.oracle_schema%TYPE,
	in_to_table					IN	tab.oracle_table%TYPE,
	in_to_columns				IN	VARCHAR2,
	in_delete_rule				IN 	VARCHAR2 DEFAULT 'RESTRICT'
)
AS
	v_ddl			t_ddl DEFAULT t_ddl();
	v_check_sql		VARCHAR2(32767);
	v_violated		NUMBER;
	v_from_cols		t_string_list;
    v_from_tab_sid	tab.tab_sid%TYPE;
    v_to_tab_sid	tab.tab_sid%TYPE;
    v_to_cols		t_string_list;
    v_to_count		BINARY_INTEGER;
    v_uk_cons_id	uk_cons.uk_cons_id%TYPE;
    v_fk_cons_id	fk_cons.fk_cons_id%TYPE;
    v_delete_rule	fk_cons.delete_rule%TYPE;
BEGIN
	GetTableForDDL(in_from_schema, in_from_table, v_from_tab_sid);
	GetTableForDDL(in_to_schema, in_to_table, v_to_tab_sid);
	
	IF UPPER(in_delete_rule) IN ('RESTRICT', 'R') THEN
		v_delete_rule := 'R';
	ELSIF UPPER(in_delete_rule) IN ('CASCADE', 'C') THEN
		v_delete_rule := 'C';
	ELSIF UPPER(in_delete_rule) IN ('SET NULL', 'SETNULL', 'N') THEN
		v_delete_rule := 'N';
	ELSE
		RAISE_APPLICATION_ERROR(-20001,
			'Unknown delete rule '||in_delete_rule||' - must be one of RESTRICT, CASCADE or SET NULL');
	END IF;
		
	ParseQuotedList(in_from_columns, v_from_cols);
	ParseQuotedList(in_to_columns, v_to_cols);	
	IF v_from_cols.COUNT <> v_to_cols.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001,
			'Cannot add a foreign key from the columns '||in_from_columns||' in the table '||in_from_schema||'.'||in_from_table||
			' to the columns '||in_to_columns||' in the table '||in_to_schema||'.'||in_to_table||' because there are not the same number '||
			' of columns in each list');
	END IF;
	
	-- find the uk we are referencing
	DELETE FROM temp_string_list;
	v_to_count := v_to_cols.COUNT; -- can't use .COUNT in SQL, sigh
	FOR i IN 1 .. v_to_count LOOP
		INSERT INTO temp_string_list (pos, value)
		VALUES (i, dq(v_to_cols(i)));
	END LOOP;
		
	BEGIN
		SELECT MIN(ukc.uk_cons_id)
		  INTO v_uk_cons_id
		  FROM uk_cons ukc, uk_cons_col ukcc, tab_column uktc, temp_string_list tl
		 WHERE ukc.tab_sid = v_to_tab_sid AND ukc.uk_cons_id = ukcc.uk_cons_id AND
		  	   ukcc.column_sid = uktc.column_sid AND 
		  	   tl.value = uktc.oracle_column AND tl.pos = ukcc.pos
		 GROUP BY ukc.uk_cons_id
		HAVING COUNT(*) = v_to_count;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,
				'No unique key could be found for the columns '||in_to_columns||
				' in the table '||in_to_schema||'.'||in_to_table);
	END;
	
	-- check the columns have the same types
	FOR i IN 1 .. v_from_cols.COUNT LOOP
	    SELECT COUNT(*)
	      INTO v_violated
	      FROM all_tab_columns ftc, all_tab_columns ttc
	     WHERE ftc.owner = dq(in_from_schema) AND ftc.table_name = 'C$'||dq(in_from_table) AND
	           ftc.column_name = dq(v_from_cols(i)) AND
	           ttc.owner = dq(in_to_schema) AND ttc.table_name = 'C$'||dq(in_to_table) AND
	           ttc.column_name = dq(v_to_cols(i)) AND
	           (ftc.data_length != ttc.data_length OR
	            ftc.data_precision != ttc.data_precision OR
	            ftc.data_scale != ttc.data_scale OR
	            ftc.data_type != ttc.data_type);
	            
		IF v_violated <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001,
				'Cannot create a foreign key relationship between '||in_from_schema||'.'||in_from_table||'.'||v_from_cols(i)||
				' and '||in_to_schema||'.'||in_to_table||'.'||v_to_cols(i)||' because the column datatypes differ');
		END IF;
	END LOOP;
	
	-- check the fk isn't violated
	v_check_sql :=
		'select count(*) '||chr(10)||
		'  from ('||chr(10)||
		'        select ';
	FOR i IN 1 .. v_from_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql||',';
		END IF;
		v_check_sql := v_check_sql||q(dq(v_from_cols(i)));
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||
		'          from '||q(dq(in_from_schema))||'.'||q('C$'||dq(in_from_table))||chr(10)||
		'         where retired_dtm is null and vers > 0 and'||chr(10)||
		'              ';
	FOR i IN 1 .. v_from_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql||' and ';
		END IF;
		v_check_sql := v_check_sql||q(dq(v_from_cols(i)))||' is not null';
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||		
		'         minus'||chr(10)||
		'        select ';
	FOR i IN 1 .. v_to_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql||',';
		END IF;
		v_check_sql := v_check_sql||q(dq(v_to_cols(i)));
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||
		'          from '||q(dq(in_to_schema))||'.'||q('C$'||dq(in_to_table))||chr(10)||
		'         where retired_dtm is null and vers > 0'||chr(10)||
		'       )';
	EXECUTE IMMEDIATE v_check_sql INTO v_violated;
	
	IF v_violated <> 0 THEN
		RAISE_APPLICATION_ERROR(-20001,
			'Cannot add a foreign key from '||in_from_columns||' in the table '||in_from_schema||'.'||in_from_table||
			' to the columns '||in_to_columns||' in the table '||in_to_schema||'.'||in_to_table||
			' since there are '||v_violated||' rows with missing parent keys');
	END IF;
		
	-- stuff an fk in
	INSERT INTO fk_cons 
		(fk_cons_id, tab_sid, r_cons_id, delete_rule)
	VALUES
		(fk_cons_id_seq.nextval, v_from_tab_sid, v_uk_cons_id, v_delete_rule);

	-- stuff columns in
	FOR i IN 1 .. v_from_cols.COUNT LOOP
		INSERT INTO fk_cons_col (app_sid, fk_cons_id, column_sid, pos)
			SELECT tc.app_sid, fk_cons_id_seq.currval, tc.column_sid, i
			  FROM tab_column tc
			 WHERE tab_sid = v_from_tab_sid AND tc.oracle_column = dq(v_from_cols(i));
	END LOOP;
	
    -- recreate the triggers
    CreateTriggers(v_to_tab_sid, v_ddl);
    CreateTriggers(v_from_tab_sid, v_ddl);
    ExecuteDDL(v_ddl);
END;

PROCEDURE DropColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE
)
AS
	v_tab_sid		tab_column.tab_sid%TYPE;
	v_column_sid	tab_column.column_sid%TYPE;
	v_ddl			t_ddl DEFAULT t_ddl();
BEGIN
	GetColumnForDDL(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_column_sid);

	-- dropping a column drops any fks that it is part of as per usual oracle behaviour
	FOR r IN (SELECT DISTINCT fk_cons_id
				FROM fk_cons_col
			   WHERE column_sid = v_column_sid) LOOP
		DELETE
		  FROM fk_cons_col
		 WHERE fk_cons_id = r.fk_cons_id;
		 
		DELETE
		  FROM fk_cons
		 WHERE fk_cons_id = r.fk_cons_id;
	END LOOP;

	-- same for check constraints
	FOR r IN (SELECT DISTINCT ck_cons_id
			    FROM ck_cons_col
			   WHERE column_sid = v_column_sid) LOOP
		DELETE
		  FROM ck_cons_col
		 WHERE ck_cons_id = r.ck_cons_id;
		 
		DELETE
		  FROM ck_cons
		 WHERE ck_cons_id = r.ck_cons_id;
	END LOOP;

	UPDATE tab_column
	   SET pos = pos - 1
	 WHERE tab_sid = v_tab_sid AND pos > (
	 		SELECT pos 
	 		  FROM tab_column
	 		 WHERE column_sid = v_column_sid);

	DELETE
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid AND column_sid = v_column_sid;

	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'ALTER TABLE '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||
						  'DROP COLUMN '||q(dq(in_oracle_column));

	-- execute the DDL first, then recreate views -- we have to do it this way around
	-- as CreateTriggers looks at all_tab_columns
	ExecuteDDL(v_ddl);
	RecreateViewInternal(v_tab_sid);
END;

PROCEDURE GetTableForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT t.tab_sid
  		  INTO out_tab_sid
  		  FROM tab t
 	     WHERE oracle_schema = dq(in_oracle_schema) AND
 	     	   oracle_table = dq(in_oracle_table) AND
			   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find the table '||in_oracle_schema||'.'||in_oracle_table);
	END;

	-- XXX: need some separate permission type?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), out_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Write access denied on the table '||q(in_oracle_schema)||'.'||q(in_oracle_table));
	END IF;
END;

PROCEDURE GetColumnForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
)
AS
BEGIN	
	BEGIN
		SELECT t.tab_sid, tc.column_sid
  		  INTO out_tab_sid, out_col_sid
  		  FROM tab t, tab_column tc
 	     WHERE t.oracle_schema = dq(in_oracle_schema) AND
 	     	   t.oracle_table = dq(in_oracle_table) AND 
			   t.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
 	     	   tc.oracle_column = dq(in_oracle_column) AND
 	     	   t.tab_sid = tc.tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_oracle_column);
	END;

	-- XXX: need some separate permission type?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), out_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied writing to the column '||
				q(in_oracle_column)||' in the table '||q(in_oracle_schema)||'.'||q(in_oracle_table));
	END IF;
END;

PROCEDURE GetTableForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
)
AS
	v_managed		tab.managed%TYPE;
BEGIN
	GetTableForWrite(in_oracle_schema, in_oracle_table, out_tab_sid);
	
	SELECT managed
	  INTO v_managed
	  FROM tab
	 WHERE tab_sid = out_tab_sid;
	IF v_managed = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Cannot modify the unmanaged table '||in_oracle_schema||'.'||in_oracle_table);
	END IF;

	EXECUTE IMMEDIATE 'lock table '||q(dq(in_oracle_schema))||'.'||q(dq(in_oracle_table))||' in exclusive mode';
END;

PROCEDURE GetColumnForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
)
AS
BEGIN
	GetTableForDDL(in_oracle_schema, in_oracle_table, out_tab_sid);
	BEGIN
		SELECT column_sid
  		  INTO out_col_sid
  		  FROM tab_column
 	     WHERE oracle_column = dq(in_oracle_column) AND tab_sid = out_tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_oracle_column);
	END;
END;
	
PROCEDURE SetColumnDescription(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_description				IN	tab_column.description%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET description = in_description
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetColumnHelp(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_help					OUT	tab_column.help%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET help = EMPTY_CLOB()
	 WHERE column_sid = v_col_sid
 		   RETURNING help INTO out_help;
END;

PROCEDURE SetEnumeratedColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_ENUMERATED, 
	   	   enumerated_desc_field = dq(in_enumerated_desc_field),
	   	   enumerated_pos_field = dq(in_enumerated_pos_field)
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetSearchEnumColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_SEARCH_ENUM, 
	   	   enumerated_desc_field = dq(in_enumerated_desc_field),
	   	   enumerated_pos_field = dq(in_enumerated_pos_field)
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetVideoColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_video_code				IN	NUMBER DEFAULT 1
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = CASE WHEN in_video_code = 0 THEN tab_pkg.CT_NORMAL ELSE tab_pkg.CT_VIDEO_CODE END
	 WHERE column_sid = v_col_sid;
END;


PROCEDURE SetChartColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_chart					IN	NUMBER DEFAULT 1
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = CASE WHEN in_chart = 0 THEN tab_pkg.CT_NORMAL ELSE tab_pkg.CT_CHART END
	 WHERE column_sid = v_col_sid;
END;


PROCEDURE SetHtmlColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_html						IN	NUMBER DEFAULT 1
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = CASE WHEN in_html = 0 THEN tab_pkg.CT_NORMAL ELSE tab_pkg.CT_HTML END
	 WHERE column_sid = v_col_sid;
END;


PROCEDURE SetFileColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_file_column				IN	tab_column.oracle_column%TYPE,
	in_mime_column				IN	tab_column.oracle_column%TYPE,
	in_name_column				IN	tab_column.oracle_column%TYPE
)
AS
	v_tab_sid		tab_column.tab_sid%TYPE;
	v_col_sid		tab_column.column_sid%TYPE;
BEGIN
	GetTableForWrite(in_oracle_schema, in_oracle_table, v_tab_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_FILE_DATA, master_column_sid = column_sid
	 WHERE tab_sid = v_tab_sid AND oracle_column = dq(in_file_column)
  		   RETURNING column_sid INTO v_col_sid;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
			'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_file_column);
	END IF;
	IF in_mime_column IS NOT NULL THEN
		UPDATE tab_column
		   SET col_type = tab_pkg.CT_FILE_MIME, master_column_sid = v_col_sid
		 WHERE tab_sid = v_tab_sid AND oracle_column = dq(in_mime_column);
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_mime_column);
		END IF;
	END IF;
	IF in_name_column IS NOT NULL THEN
		UPDATE tab_column
		   SET col_type = tab_pkg.CT_FILE_NAME, master_column_sid = v_col_sid
		 WHERE tab_sid = v_tab_sid AND oracle_column = dq(in_name_column);
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_name_column);
		END IF;
	END IF;
END;

PROCEDURE DropAllTables
AS
	v_cms_sid		security_pkg.T_SID_ID;
	v_drop_physical	BOOLEAN;
BEGIN
	
	-- Clean up registered managed tables
	FOR r IN (SELECT oracle_schema, oracle_table, managed
				FROM cms.tab 
			   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) LOOP
		IF r.managed = 1 THEN
			-- HMM... this scares me! i.e. if your register a managed table that is 
			-- shared (i.e. via APP_SID) then it'll be dropped from Oracle.
			-- Someone could blindly call this and delete (say) the RISKS schema
			-- stuff and more.
			v_drop_physical := FALSE; --TRUE; 
		ELSE
			v_drop_physical := FALSE;
		END IF;
		DropTable(r.oracle_schema, r.oracle_table, TRUE, v_drop_physical);
	END LOOP;
	
	-- Clean up possibly left over SOs
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
		FOR r IN (SELECT sid_id
					FROM security.securable_object 
				   WHERE parent_sid_id = v_cms_sid) LOOP
			SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), r.sid_id);
		END LOOP;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Clean up any granted/automatically granted permissions
	DELETE
	  FROM app_schema
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE
	  FROM app_schema_table
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DropTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_cascade_constraints		IN	BOOLEAN DEFAULT FALSE,
	in_drop_physical			IN	BOOLEAN DEFAULT TRUE
)
AS
	v_tab_sid		security_pkg.T_SID_ID;
	v_itab_sid		security_pkg.T_SID_ID;
	v_so_tab_sid	security_pkg.T_SID_ID;
	v_ddl			t_ddl DEFAULT t_ddl();
	v_owner			VARCHAR2(30);
	v_table_name	VARCHAR2(30);
	v_has_fks		NUMBER;
--	v_managed		tab.managed%TYPE DEFAULT 0;
BEGIN
	-- Normalise owner/table
	v_owner := dq(in_oracle_schema);
	v_table_name := dq(in_oracle_table);
	
	-- Check for an issue join table and kill that as well
	-- XXX: should this check from all_tables? i.e. when we create, we check all_tables
	-- and if there's a problem during registration then when we re-run, the I$XXX table
	-- exists but it doesn't get dropped.
	BEGIN
		SELECT tab_sid
		  INTO v_itab_sid
		  FROM tab
		 WHERE oracle_schema = v_owner AND oracle_table = 'I$'||v_table_name
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		DropTable(v_owner, q('I$'||v_table_name), TRUE, TRUE);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Check for an SO
			BEGIN
				v_so_tab_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms/' || 
					q(v_owner) || '.' ||q('I$'||v_table_name));
					DropTable(v_owner, q('I$'||v_table_name), TRUE, TRUE);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
			END;
	END;

	-- Check for an SO
	BEGIN
		v_so_tab_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms/' || 
			q(v_owner) || '.' ||q(v_table_name));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Check for an entry in TAB
	BEGIN
		SELECT tab_sid
  		  INTO v_tab_sid
  		  FROM tab
 	     WHERE oracle_schema = v_owner AND oracle_table = v_table_name AND
 	     	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- Check for FK constraints if we have an entry in TAB
	IF v_tab_sid IS NOT NULL THEN
		-- Cascading constraints so just drop them
		IF in_cascade_constraints THEN
			DELETE
			  FROM fk_cons_col
			 WHERE fk_cons_id IN (SELECT fk_cons_id
			 						FROM fk_cons fk, uk_cons uk
			 					   WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
	
			DELETE
			  FROM fk_cons
			 WHERE fk_cons_id IN (SELECT fk_cons_id
			 						FROM fk_cons fk, uk_cons uk
			 					   WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
		ELSE
			SELECT MIN(1)
			  INTO v_has_fks
			  FROM DUAL
			 WHERE EXISTS (SELECT *
							 FROM fk_cons fk, uk_cons uk
							WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
			IF v_has_fks IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'The table '||q(v_owner)||'.'||q(v_table_name)||
					' with sid '||v_tab_sid||' has cannot be dropped because it has foreign keys that refer to it');
			END IF;
		END IF;
	END IF;
			
	-- Nuke the SO if found.  Also cleans up keys, etc.
	IF v_so_tab_sid IS NOT NULL THEN
		BEGIN
			SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), v_so_tab_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

	-- If we had a missing SO but data in the TAB then clean that up too
	ELSIF v_tab_sid IS NOT NULL THEN
		DeleteObject(security_pkg.GetACT(), v_tab_sid);
	END IF;
		
	IF NOT in_drop_physical THEN
		RETURN;
	END IF;

	-- Nuke the views, base table and packages if found
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP VIEW ' || q(v_owner) || '.' || q('H$' || v_table_name);
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP VIEW ' || q(v_owner) || '.' || q(v_table_name);
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP TABLE ' || q(v_owner) || '.' || q('L$' || v_table_name);
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP TABLE ' || q(v_owner) || '.' || q('C$' || v_table_name) || ' CASCADE CONSTRAINTS';
	-- probably generates ORA-00942 (table/view doesn't exist, but if registration was incomplete the table may still exist)
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP TABLE ' || q(v_owner) || '.' || q(v_table_name) || ' CASCADE CONSTRAINTS';
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP PACKAGE ' || q(v_owner) || '.' || q('T$' || v_table_name);

	FOR i in v_ddl.first .. v_ddl.last LOOP
		BEGIN
			IF m_trace THEN
				IF SUBSTR(v_ddl(i), -1) = ';' THEN
					dbms_output.put_line(v_ddl(i));
					dbms_output.put_line('/');
				ELSE
					dbms_output.put_line(v_ddl(i)||';');
				END IF;
			END IF;
			IF NOT m_trace_only THEN
				ExecuteClob(v_ddl(i));
			END IF;
		EXCEPTION
			-- skip bits that don't exist
			WHEN PACKAGE_DOES_NOT_EXIST THEN
				NULL;
			WHEN TABLE_DOES_NOT_EXIST THEN
				NULL;
		END;
	END LOOP;
END;

PROCEDURE RenameColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_old_name					IN	tab_column.oracle_column%TYPE,
	in_new_name					IN	tab_column.oracle_column%TYPE
)
AS
	v_cms_sid		security_pkg.T_SID_ID;
	v_tab_sid		security_pkg.T_SID_ID;
	v_col_sid		security_pkg.T_SID_ID;
	v_new_name		VARCHAR2(30);
	v_count			NUMBER;
	v_ddl 			t_ddl default t_ddl();
	v_managed		NUMBER;
	v_tab_name		VARCHAR2(30);
BEGIN
	GetColumnForDDL(in_oracle_schema, in_oracle_table, in_old_name, v_tab_sid, v_col_sid);
	 
	v_new_name := dq(in_new_name);
	UPDATE tab_column
	   SET oracle_column = v_new_name
	 WHERE column_sid = v_col_sid;

	-- Check for a duplicate name (TODO: ought to be a constraint...)
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_column
	 WHERE oracle_column = v_new_name
	   AND tab_sid = v_tab_sid;
	IF v_count > 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 
			'The table '||in_oracle_schema||'.'||in_oracle_table||' already has a column named '||in_new_name);
	END IF;

	SELECT managed
	  INTO v_managed
	  FROM tab
	 WHERE tab_sid = v_tab_sid;
	IF v_managed = 1 THEN
		v_tab_name := 'C$'||dq(in_oracle_table);
	ELSE
		v_tab_name := dq(in_oracle_table);
	END IF;

	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 
		'alter table '||q(dq(in_oracle_schema))||'.'||q(v_tab_name)||' rename column '||q(dq(in_old_name))||' to '||q(v_new_name);

	-- execute the DDL first, then recreate views -- we have to do it this way around
	-- as CreateTriggers looks at all_tab_columns
	ExecuteDDL(v_ddl);
	RecreateViewInternal(v_tab_sid);
END;

PROCEDURE GetTableDefinitions_(
	in_tables					IN	security.T_SO_TABLE,
	out_tab_cur					OUT SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_ck_cur					OUT	SYS_REFCURSOR,
	out_ck_col_cur				OUT	SYS_REFCURSOR,
	out_uk_cur					OUT	SYS_REFCURSOR,
	out_fk_cur					OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur	OUT	SYS_REFCURSOR	
)
AS
BEGIN
	OPEN out_tab_cur FOR
		SELECT t.tab_sid, t.oracle_schema, t.oracle_table, t.description, t.format_sql, 
			   t.pk_cons_id, t.managed, t.auto_registered, t.cms_editor, t.issues
		  FROM tab t, TABLE (in_tables) c
		 WHERE t.tab_sid = c.sid_id;
	
	OPEN out_col_cur FOR
		SELECT t.tab_sid, NVL(atc.data_type, tc.data_type) data_type, NVL(atc.data_length, tc.data_length) data_length, 
			   NVL(atc.data_precision, tc.data_precision) data_precision, NVL(atc.data_scale, tc.data_scale) data_scale, 
			   NVL(atc.nullable, tc.nullable) nullable, NVL(atc.char_length, tc.char_length) char_length,
			   tc.column_sid, tc.pos, tc.oracle_column, tc.description, tc.col_type, tc.master_column_sid, 
			   tc.enumerated_desc_field, tc.enumerated_pos_field, tc.enumerated_hidden_field,
			   tc.help, tc.check_msg, atc.default_length, atc.data_default, tc.value_placeholder,
			   CASE WHEN pa.column_sid IS NULL THEN TAB_COL_PERM_READ_WRITE -- no role based permissions in use
			   		ELSE NVL(p.permission, TAB_COL_PERM_NONE) -- role based permissions, so use max granted permission or default to none
			   END permission, tc.calc_xml, tc.tree_desc_field, tc.tree_id_field, tc.tree_parent_id_field
		  FROM tab t
		  JOIN tab_column tc ON t.tab_sid = tc.tab_sid
		  -- left join because calc columns don't appear in atc
		  LEFT JOIN all_tab_columns atc ON t.oracle_schema = atc.owner AND tc.oracle_column = atc.column_name AND ((t.managed = 0 AND t.oracle_table = atc.table_name) OR (t.managed = 1 AND 'C$' || t.oracle_table = atc.table_name))
		  JOIN TABLE (in_tables) c ON t.tab_sid = c.sid_id AND tc.tab_sid = c.sid_id
		  LEFT JOIN (
				SELECT tcrp.column_sid, MAX(tcrp.permission) permission
				  FROM cms.tab_column_role_permission tcrp, security.act act, TABLE (in_tables) t, tab_column tc
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND tcrp.role_sid = act.sid_id
				   AND t.sid_id = tc.tab_sid
				   AND tc.app_sid = tcrp.app_sid AND tc.column_sid = tcrp.column_sid
				 GROUP BY tcrp.column_sid
			   ) p ON tc.column_sid = p.column_sid
		  LEFT JOIN (
				SELECT tcrp.column_sid
				  FROM cms.tab_column_role_permission tcrp
				 GROUP BY tcrp.column_sid
			   ) pa ON tc.column_sid = pa.column_sid;
		  
	-- Cached check constraints			     	  
	OPEN out_ck_cur FOR
		SELECT ck.ck_cons_id, ck.tab_sid, ck.search_condition
		  FROM ck_cons ck, TABLE (in_tables) c
		 WHERE c.sid_id = ck.tab_sid;
	OPEN out_ck_col_cur FOR
		SELECT ckc.ck_cons_id, ckc.column_sid
		  FROM ck_cons ck, ck_cons_col ckc, TABLE (in_tables) c
		 WHERE c.sid_id = ck.tab_sid AND ck.ck_cons_id = ckc.ck_cons_id;
               
	OPEN out_uk_cur FOR
		SELECT ukcc.uk_cons_id, ukc.tab_sid, ukcc.column_sid, ukcc.pos
		  FROM uk_cons ukc, uk_cons_col ukcc, TABLE (in_tables) c
		 WHERE c.sid_id = ukc.tab_sid AND ukc.uk_cons_id = ukcc.uk_cons_id
	     ORDER BY ukcc.uk_cons_id, ukcc.pos;
	
	OPEN out_fk_cur FOR
		SELECT fkcc.fk_cons_id, fkc.tab_sid, fkc.r_cons_id, fkcc.column_sid, fkcc.pos
		  FROM TABLE (in_tables) c, uk_cons ukc, fk_cons fkc, fk_cons_col fkcc
		 WHERE c.sid_id = fkc.tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
		 	   fkc.fk_cons_id = fkcc.fk_cons_id
	  ORDER BY fkcc.fk_cons_id, fkcc.pos;

	OPEN out_flow_tab_col_cons_cur FOR
		SELECT ftcc.column_sid, ftcc.flow_state_id, ftcc.nullable
		  FROM flow_tab_column_cons ftcc, TABLE (in_tables) t, tab_column tc
		 WHERE t.sid_id = tc.tab_sid
		   AND tc.app_sid = ftcc.app_sid AND tc.column_sid = ftcc.column_sid;
END;

PROCEDURE GetTableDefinition(
	in_tab_sid					IN	security_pkg.T_SID_ID,
	out_tab_cur					OUT	SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_ck_cur					OUT	SYS_REFCURSOR,
	out_ck_col_cur				OUT	SYS_REFCURSOR,
	out_uk_cur					OUT	SYS_REFCURSOR,
	out_fk_cur					OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur	OUT	SYS_REFCURSOR	
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_tables					security.T_SO_TABLE;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the table with SID '||in_tab_sid);
	END IF;
	
	v_tables := security.T_SO_TABLE();
	v_tables.extend(1);
	v_tables(1) := security.T_SO_ROW(in_tab_sid, null, null, null, null, null, null);
	GetTableDefinitions_(v_tables, out_tab_cur, out_col_cur, out_ck_cur, out_ck_col_cur, out_uk_cur, out_fk_cur, out_flow_tab_col_cons_cur);
END;

PROCEDURE GetTableDefinitions(
	out_tab_cur					OUT SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_ck_cur					OUT	SYS_REFCURSOR,
	out_ck_col_cur				OUT	SYS_REFCURSOR,
	out_uk_cur					OUT	SYS_REFCURSOR,
	out_fk_cur					OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur	OUT	SYS_REFCURSOR	
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
	v_cms_sid	security_pkg.T_SID_ID;
	v_tables	security.T_SO_TABLE;
BEGIN
	-- Get the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.SO_CONTAINER, 'cms', v_cms_sid);
	END;
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the schema with SID '||v_cms_sid);
	END IF;
	
	v_tables := SecurableObject_pkg.GetChildrenWithPermAsTable(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ);
	GetTableDefinitions_(v_tables, out_tab_cur, out_col_cur, out_ck_cur, out_ck_col_cur, out_uk_cur, out_fk_cur, out_flow_tab_col_cons_cur);
END;

PROCEDURE GetTables(
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
	v_tab_class	security_pkg.T_CLASS_ID;
	v_cms_sid	security_pkg.T_SID_ID;
BEGIN
	-- Get the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.SO_CONTAINER, 'cms', v_cms_sid);
	END;
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the schema with SID '||v_cms_sid);
	END IF;

	v_tab_class := class_pkg.GetClassID('CMSTable');
	OPEN out_cur FOR
		SELECT t.tab_sid, t.oracle_schema, t.oracle_table, t.description, t.format_sql, t.cms_editor, t.issues
		  FROM tab t,
		  	   TABLE (SecurableObject_pkg.GetChildrenWithPermAsTable(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ) ) c
		 WHERE t.tab_sid = c.sid_id AND c.class_id = v_tab_class
  	  ORDER BY c.sid_id;
END;

PROCEDURE GetDetails(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_act_id			security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the table with SID '||in_tab_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT tab_sid, app_sid, oracle_schema, oracle_table, description, format_sql, pk_cons_id, 
			   managed, auto_registered, cms_editor, issues
		  FROM tab
		 WHERE tab_sid = in_tab_sid;
END;

PROCEDURE GoToContextIfExists(
	in_context_id				IN	security_pkg.T_SID_ID
)
AS
	v_count 					NUMBER(10);
	v_context_id				security_pkg.T_SID_ID;
BEGIN
	SELECT COUNT (*)
	  INTO v_count
	  FROM fast_context
 	 WHERE context_id = in_context_id 
 	   AND parent_context_id = in_context_id;
	
	v_context_id := in_context_id;	
	IF v_count = 0 THEN
		v_context_id := 0;
	END IF;
	
	GoToContext(v_context_id);
END;

PROCEDURE GoToContext(
	in_context_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	security_pkg.GoToContext(in_context_id);
END;

PROCEDURE PublishItem(
	in_from_context				IN	context.context_id%TYPE,
	in_to_context				IN	context.context_id%TYPE,
	in_tab_sid					IN	tab.tab_sid%TYPE,
	in_item_id					IN	security_pkg.T_SID_ID
)
AS
	v_table_name		tab.oracle_table%TYPE;
	v_owner				tab.oracle_schema%TYPE;
	v_count				NUMBER(10);
BEGIN	
	SELECT COUNT (*)
	  INTO v_count
	  FROM fast_context
	 WHERE context_id = in_from_context 
       AND parent_context_id = in_to_context;
       
    IF v_count = 0 THEN
    	RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Cannot publish from context '|| in_from_context || ' to context ' || in_to_context);    
    END IF;
	
	BEGIN
		SELECT t.oracle_schema, t.oracle_table
		  INTO v_owner, v_table_name
		  FROM tab t
		 WHERE t.tab_sid = in_tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The item with id '||in_item_id||' could not be found');
	END;
	EXECUTE IMMEDIATE
		'begin '||q(v_owner)||'.'||q('T$'||v_table_name)||'.p(:1,:2,:3); end;'
	USING
		in_from_context, in_to_context, in_item_id;
		
	DELETE FROM link_track
	 WHERE item_id = in_item_id
	   AND context_id IN (SELECT parent_context_id
	                        FROM context
	                       WHERE context_id <> in_to_context
	                  CONNECT BY PRIOR parent_context_id = context_id
	                  START WITH context_id = in_from_context);

	UPDATE link_track
	   SET context_id = in_to_context
	 WHERE item_id = in_item_id
	   AND context_id = in_from_context;
END;

PROCEDURE SearchContent(
	in_tab_sids					IN	security_pkg.T_SID_IDS,
	in_part_description			IN  varchar2,
	in_item_ids					IN  security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_sql 						VARCHAR2(32767);
	v_tab_sids 					security.T_SID_TABLE;
	v_tab_sid_count				NUMBER(10);
	v_item_ids					security.T_SID_TABLE;
	v_item_id_count				NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the application with SID '||SYS_CONTEXT('SECURITY', 'APP'));
	END IF;	
	
	v_tab_sids := security_pkg.SidArrayToTable(in_tab_sids);
	v_tab_sid_count := v_tab_sids.COUNT;
	
	v_item_ids := security_pkg.SidArrayToTable(in_item_ids);
	v_item_id_count := v_item_ids.COUNT;
	
	v_sql := 
		'   SELECT t.tab_sid, t.oracle_schema, t.oracle_table, t.description tab_description,'||chr(10)||
		'          id.item_id, id.description, id.locked_by, u.full_name locked_by_name, fc.CONTEXT_ID can_steal' ||chr(10)||
		'     FROM tab t, cms.item_description_'||SYS_CONTEXT('SECURITY', 'APP')||' id, cms_user u, fast_context fc' ||chr(10)||
		'    WHERE id.tab_sid = t.tab_sid'||chr(10)||
		'      AND u.user_sid(+) = id.locked_by' ||chr(10)||
		'      AND fc.context_id(+) = NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0)' ||chr(10)||
		'      AND fc.parent_context_id(+) = id.locked_by' ||chr(10)||
		'      AND LOWER(id.description) like LOWER(''%''||:1||''%'')'||chr(10)||
		'      AND (0 = :2 OR t.tab_sid IN (SELECT * FROM TABLE(:3)))'||chr(10)||
		'      AND (0 = :4 OR id.item_id IN (SELECT * FROM TABLE(:5)))'||chr(10);

	OPEN out_cur FOR v_sql
	USING in_part_description, v_tab_sid_count, v_tab_sids, v_item_id_count, v_item_ids;
END;

PROCEDURE GetAppDisplayTemplates(
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the application with SID '||SYS_CONTEXT('SECURITY', 'APP'));
	END IF;
	
	OPEN out_cur FOR
		SELECT dt.*
		  FROM tab t, display_template dt
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.tab_sid = dt.tab_sid;
END;

PROCEDURE EnsureContextExists(
	in_context					IN	context.context_id%TYPE
)
AS
	v_count						number(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM context
	 WHERE context_id = in_context;

	IF (v_count = 0) THEN
	   INSERT INTO context
	   VALUES (in_context, 0);

	   INSERT INTO fast_context
	   VALUES (in_context, 0);

	   INSERT INTO fast_context
	   VALUES (in_context, in_context);	    
	END IF;
END;

PROCEDURE GetItemsBeingTracked(
	in_path						IN  link_track.path%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_path						link_track.path%TYPE;
BEGIN
	IF SUBSTR(in_path, LENGTH(in_path), 1) = '/' THEN
		v_path := SUBSTR(in_path, 1, LENGTH(in_path) - 1);
	ELSE
		v_path := in_path;
	END IF;

	OPEN out_cur FOR
		'SELECT lt.item_id, lt.context_id, lt.column_sid, lt.path, id.description, cu.full_name'||chr(10)||
		'  FROM link_track lt, item_description_'||SYS_CONTEXT('SECURITY', 'APP')||' id, cms_user cu'||chr(10)||
		' WHERE (LOWER (lt.path) LIKE LOWER (:1||''/%'')'||chr(10)||
		'        OR LOWER (lt.path) = LOWER (:2))'||chr(10)||
		'   AND id.item_id(+) = lt.item_id'||chr(10)|| -- hmm, foul. try to think of something better than item_description here.
		'   AND cu.user_sid(+) = lt.context_id'||chr(10)||
		' ORDER BY context_id'
	USING v_path, v_path;		
END;

PROCEDURE GetAllSharedFilters(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT filter_sid, name, tab_sid, user_sid, filter_xml
		  FROM filter
		 WHERE user_sid IS NULL
		   AND is_active_session_filter = 0;
END;

PROCEDURE GetTableFilters(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT filter_sid, name, user_sid, filter_xml
		  FROM filter
		 WHERE (user_sid IS NULL OR user_sid = security_pkg.GetSID()) AND
		 	   tab_sid = in_tab_sid AND
		 	   is_active_session_filter = 0;
END;

PROCEDURE SearchTableFilters(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	in_prefix					IN	VARCHAR2,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT filter_sid, name, user_sid, filter_xml
		  FROM filter
		 WHERE (user_sid IS NULL OR user_sid = security_pkg.GetSID()) AND
		 	   tab_sid = in_tab_sid AND
		 	   LOWER(name) LIKE LOWER(in_prefix)||'%' AND
		 	   is_active_session_filter = 0;
END;

PROCEDURE LoadTableFilter(
	in_filter_sid				IN	filter.filter_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tab_sid, filter_sid, name, user_sid, filter_xml
		  FROM filter
		 WHERE (user_sid IS NULL OR user_sid = security_pkg.GetSID()) AND
		 	   filter_sid = in_filter_sid;
END;

-- XXX: guaranteed to break - why is this taking tab_name without oracle_schema and not SID?
PROCEDURE GetSessionTableFilter(
	in_tab_name					IN	tab.oracle_table%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT f.filter_xml
		  FROM filter f
		  JOIN tab t ON f.tab_sid = t.tab_sid AND f.app_sid = t.app_sid
		 WHERE t.oracle_table = in_tab_name
		   AND user_sid = security_pkg.GetSID()
		   AND is_active_session_filter = 1;
END;

-- XXX: guaranteed to break - why is this taking tab_name without oracle_schema and not SID?
PROCEDURE RemoveSessionTableFilter(
	in_tab_name					IN	tab.oracle_table%TYPE
)
AS
BEGIN
	DELETE FROM filter
	 WHERE tab_sid IN (
		SELECT tab_sid 
		  FROM tab 
		 WHERE app_sid = security_pkg.getApp() 
		   AND oracle_table = in_tab_name
	)
	   AND is_active_session_filter = 1
	   AND user_sid = security_pkg.getSID();
END;

PROCEDURE SaveTableFilter(
	in_tab_sid					IN	filter.tab_sid%TYPE,
	in_name						IN	filter.name%TYPE,
	in_public					IN	NUMBER,
	in_filter_xml				IN	filter.filter_xml%TYPE,
	in_is_active_session_filter	IN	filter.is_active_session_filter%TYPE,
	out_filter_sid				OUT	filter.filter_sid%TYPE
)
AS
	v_user_sid		filter.user_sid%TYPE;
BEGIN
	-- User sid is NULL for public filters
	IF in_public = 0 THEN
		v_user_sid := security_pkg.GetSID();
	END IF;

	-- Update the filter by name
	-- Note: races with hammering save -- oh well, this needs to be redone to 
	-- have a chartlib like structure anyway
	SELECT MIN(filter_sid)
	  INTO out_filter_sid
	  FROM filter
	 WHERE NVL(user_sid, -1) = NVL(v_user_sid, -1) AND 
	 	   LOWER(name) = LOWER(in_name) AND
	 	   tab_sid = in_tab_sid;
	
	IF out_filter_sid IS NUlL THEN
		INSERT INTO filter 
			(filter_sid, tab_sid, name, user_sid, filter_xml, is_active_session_filter)
		VALUES 
			(security.sid_id_seq.NEXTVAL, in_tab_sid, in_name, v_user_sid, in_filter_xml, in_is_active_session_filter)
		RETURNING filter_sid INTO out_filter_sid;
	ELSE
		UPDATE filter
		   SET user_sid = v_user_sid, filter_xml = in_filter_xml
		 WHERE filter_sid = out_filter_sid;
	END IF;
END;

PROCEDURE GetUserContent(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		'SELECT id.* '||
		'  FROM tab t, item_description_'||SYS_CONTEXT('SECURITY', 'APP')||' id '||
		' WHERE id.locked_by = :1 '||
		'   AND t.tab_sid = id.tab_sid '||
		' ORDER BY t.oracle_table'
	USING security_pkg.getsid();
END;

PROCEDURE GetFlowSidFromLabel(
	in_flow_label					IN	csr.flow.label%TYPE,
	out_flow_sid					OUT	csr.flow.flow_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT flow_sid
		  INTO out_flow_sid
		  FROM csr.flow
		 WHERE label = in_flow_label;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'The workflow with label '||in_flow_label||' could not be found');
	END;
	
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), out_flow_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the flow '||in_flow_label||' with sid '||out_flow_sid);
	END IF;
END;

PROCEDURE GetFlowRegions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_properties_only				IN	NUMBER,
	in_phrase						IN  VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);

	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT region_sid, description
		  FROM csr.v$region
		 WHERE (app_sid, region_sid) IN (
		 		SELECT rrm.app_sid, rrm.region_sid
				  FROM csr.flow f, csr.flow_state fs, csr.flow_state_role fsr, csr.region_role_member rrm, csr.region r
				 WHERE f.flow_sid = v_flow_sid
				   AND f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
				   AND fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
				   AND fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
				   AND rrm.app_sid = r.app_sid AND rrm.region_sid = r.region_sid
				   AND (in_properties_only = 0 OR r.region_type = csr.csr_data_pkg.REGION_TYPE_PROPERTY)
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID'))
		   AND (in_phrase IS NULL OR LOWER(description) LIKE LOWER(in_phrase||'%'))
		 ORDER BY description;
END;

PROCEDURE GetFlowItemRegions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT region_sid, description
		  FROM csr.v$region
		 WHERE (app_sid, region_sid) IN (	
		 		SELECT rrm.app_sid, rrm.region_sid
				  FROM csr.flow_item fi, csr.flow_state fs, csr.flow_state_role fsr, csr.region_role_member rrm
				 WHERE fi.flow_item_id = in_flow_item_id
				   AND fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
				   AND fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
				   AND fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID'));
END;

PROCEDURE GetCurrentFlowState(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM csr.flow_item
	 WHERE flow_item_id = in_flow_item_id;
	 
	IF NOT security.security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the workflow with sid '||v_flow_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT fs.flow_state_id, fs.flow_sid, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_deleted
		  FROM csr.flow_state fs, csr.flow_item fi
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND fi.current_state_id = fs.flow_state_id;
END;

PROCEDURE GetDefaultFlowState(
	in_tab_sid						IN	tab.tab_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the table with sid '||in_tab_sid);
	END IF;
	
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	IF v_flow_sid IS NULL THEN
		OPEN out_cur FOR
			SELECT null flow_state_id, null flow_sid, null label, null lookup_key, null attributes_xml, null is_deleted
			  FROM dual
			 WHERE 1 = 0;
		RETURN;
	END IF;
	   
	IF NOT security.security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the workflow with sid '||v_flow_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT fs.flow_state_id, fs.flow_sid, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_deleted
		  FROM csr.flow_state fs, csr.flow f
		 WHERE f.flow_sid = v_flow_sid
		   AND fs.flow_state_id = f.default_state_id;
END;
	
PROCEDURE GetFlowTransitions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);

	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT flow_state_transition_id, from_state_id, to_state_id, flow_sid, verb, ask_for_comment, 
			   pos, attributes_xml, helper_sp, lookup_key, mandatory_fields_message, button_icon_path
		  FROM csr.flow_state_transition
		 WHERE (app_sid, flow_state_transition_id) IN ( -- IN because you can be in more than one role
		 		SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow f, csr.flow_state_transition fst, csr.flow_state_transition_role fstr, csr.region_role_member rrm
				 WHERE f.flow_sid = v_flow_sid
				   AND f.app_sid = fst.app_sid AND f.default_state_id = fst.from_state_id
				   AND fst.app_sid = fstr.app_sid AND fst.flow_state_transition_id = fstr.flow_state_transition_id
				   AND fstr.app_sid = rrm.app_sid AND fstr.role_sid = rrm.role_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
				   AND rrm.region_sid = in_region_sid);
END;

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT flow_state_transition_id, from_state_id, to_state_id, flow_sid, verb, ask_for_comment, 
			   pos, attributes_xml, helper_sp, lookup_key, mandatory_fields_message, button_icon_path
		  FROM csr.flow_state_transition
		 WHERE (app_sid, flow_state_transition_id) IN ( -- IN because you can be in more than one role
		 		SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow_item fi, csr.flow_state_transition fst, csr.flow_state_transition_role fstr, csr.region_role_member rrm
				 WHERE fi.flow_item_id = in_flow_item_id
				   AND fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
				   AND fst.app_sid = fstr.app_sid AND fst.flow_state_transition_id = fstr.flow_state_transition_id
				   AND fstr.app_sid = rrm.app_sid AND fstr.role_sid = rrm.role_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
				   AND rrm.region_sid = in_region_sid);
END;

PROCEDURE EnterFlow(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_flow_item_id				OUT	csr.flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);
	csr.flow_pkg.AddCmsItem(v_flow_sid, in_region_sid, out_flow_item_id);	
END;

PROCEDURE GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
)
AS
BEGIN
	SELECT NVL(MAX(fsr.is_editable), 0) -- if it's editable in any role, then you can edit it, e.g. if an admin and a data provider
	  INTO out_editable
	  FROM csr.flow_item fi, csr.flow_state_role fsr, csr.region_role_member rrm
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND fi.app_sid = fsr.app_sid AND fi.current_state_id = fsr.flow_state_id
	   AND fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	   AND rrm.region_sid = in_region_sid;
END;

PROCEDURE GetDefaultFlowStateEditable(
	in_flow_label					IN	csr.flow.label%TYPE,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);

	SELECT NVL(MAX(is_editable), 0)
	  INTO out_editable
	  FROM csr.flow f
	  JOIN csr.flow_state fs ON f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
	  JOIN csr.flow_state_role fsr ON fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
	  JOIN security.act ON act.sid_id = fsr.role_sid
	 WHERE f.flow_sid = v_flow_sid
	   AND act.act_id = sys_context('SECURITY', 'ACT');
END;

PROCEDURE UpdateUnmanagedFlowStateLabel(
    in_tab_sid                      security_pkg.T_SID_ID,
    in_flow_state_id                csr.flow_state.flow_state_id%TYPE,
    in_where_clause                 VARCHAR2
)
AS
    v_label         csr.flow_state.label%TYPE;
    v_ora_schema    VARCHAR2(30 BYTE);
    v_tab_name      VARCHAR2(30 BYTE);
BEGIN
    SELECT oracle_schema, oracle_table INTO v_ora_schema, v_tab_name FROM cms.tab WHERE tab_sid = in_tab_sid;
    SELECT label INTO v_label FROM csr.flow_state WHERE flow_state_id = in_flow_state_id;

    -- dynamic SQL, risky and nasty! Must find a better way of dealing with unmanaged cms tables in workflows!
    EXECUTE IMMEDIATE 'UPDATE ' || v_ora_schema || '.' || v_tab_name || ' SET flow_state_label = ''' || v_label || ''' WHERE ' || in_where_clause;
END;

PROCEDURE GetFlowStatesForTables(
	in_table_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_tab_sids 					security.T_SID_TABLE;
BEGIN
	v_tab_sids := security_pkg.SidArrayToTable(in_table_sids);
	OPEN out_cur FOR
		SELECT fsperm.tab_sid, fs.flow_state_id, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_deleted
		  FROM csr.flow_state fs, (
				SELECT t.tab_sid, fs.flow_state_id
				  FROM tab t, csr.flow_state fs, csr.flow_state_role fsr,
				  	   TABLE(v_tab_sids) ts,
						(SELECT group_sid_id
						   FROM security.group_members 
								START WITH member_sid_id = SYS_CONTEXT('SECURITY','SID')
								CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id) g
			  	 WHERE t.tab_sid = ts.column_value
			  	   AND t.app_sid = fs.app_sid AND t.flow_sid = fs.flow_sid
				   AND fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
				   AND fsr.role_sid = g.group_sid_id 
			  	 GROUP BY t.tab_sid, fs.flow_state_id) fsperm
		 WHERE fs.flow_state_id = fsperm.flow_state_id
		   AND fs.is_deleted = 0
		 ORDER BY fsperm.tab_sid, LOWER(fs.label);
END;

END;
/
