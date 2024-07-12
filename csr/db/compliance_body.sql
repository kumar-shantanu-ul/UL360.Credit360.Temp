CREATE OR REPLACE PACKAGE BODY csr.compliance_pkg AS

PROCEDURE INT_GetComplianceItemsLangs(
	in_compliance_item_type			IN  NUMBER DEFAULT NULL,
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	in_reference_code				IN  compliance_item.reference_code%TYPE DEFAULT NULL,
	out_langs						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_langs FOR
		SELECT ci.compliance_item_id, cid.lang_id, l.lang, l.description
		  FROM compliance_item ci
		  JOIN compliance_item_description cid ON ci.compliance_item_id = cid.compliance_item_id AND ci.app_sid = cid.app_sid
		  JOIN aspen2.lang l ON cid.lang_id = l.lang_id
		 WHERE (in_compliance_item_id IS NULL OR ci.compliance_item_id = in_compliance_item_id)
		   AND (in_reference_code IS NULL OR ci.reference_code = in_reference_code)
		   AND (in_compliance_item_type IS NULL OR ci.compliance_item_type = in_compliance_item_type);
END;

PROCEDURE INTERNAL_GetComplianceItems(
	in_compliance_item_type			IN  NUMBER DEFAULT NULL,
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	in_reference_code				IN  compliance_item.reference_code%TYPE DEFAULT NULL,
	in_lang							IN	VARCHAR2 DEFAULT 'en',
	out_cur							OUT SYS_REFCURSOR,
	out_rollout_info				OUT	SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
)
AS
	v_lang							VARCHAR2(10);
	v_latest_major_ver				compliance_item.major_version%TYPE;
	v_latest_minor_ver				compliance_item.minor_version%TYPE;
BEGIN
	SELECT NVL(MIN(lang), 'en')
	  INTO v_lang
	  FROM compliance_item_description cid
	  JOIN aspen2.lang l ON l.lang_id = cid.lang_id AND l.lang = in_lang
	 WHERE cid.compliance_item_id = in_compliance_item_id;

	BEGIN
		SELECT major_version, minor_version 
		  INTO v_latest_major_ver, v_latest_minor_ver 
		  FROM ( 
			SELECT major_version, minor_version 
			FROM compliance_item_version_log 
			WHERE compliance_item_id = in_compliance_item_id 
			  AND lang_id = (SELECT lang_id FROM aspen2.lang WHERE lang = v_lang)
			ORDER BY major_version DESC, minor_version DESC
		)
		 WHERE ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	OPEN out_cur FOR
		SELECT ci.compliance_item_id,
			   cid.title,
			   cid.summary,
			   cid.details,
			   ci.source,
			   ci.reference_code,
			   ci.user_comment,
			   cid.citation,
			   ci.external_link,
			   ci.created_dtm,
			   ci.updated_dtm,
			   ci.compliance_item_status_id,
			   NVL(v_latest_major_ver, ci.major_version) major_version,
			   NVL(v_latest_minor_ver, ci.minor_version) minor_version,
			   ci.lookup_key,
			   ci.compliance_item_type,
			   -- Regulations
			   creg.external_id,
			   creg.adoption_dtm,
			   NVL(creg.is_policy, 0) is_policy,
			   -- Conditions (with permit info)
			   cpc.compliance_permit_id,
			   cpc.condition_type_id,
			   cpc.condition_sub_type_id,
			   -- Status
			   cis.description status_label,
			   l.lang
		  FROM compliance_item ci
		  JOIN compliance_item_description cid ON ci.compliance_item_id = cid.compliance_item_id AND ci.app_sid = cid.app_sid
		  JOIN aspen2.lang l ON l.lang_id = cid.lang_id AND l.lang = v_lang
		  JOIN compliance_item_status cis ON ci.compliance_item_status_id = cis.compliance_item_status_id
		  LEFT JOIN compliance_regulation creg ON ci.compliance_item_id = creg.compliance_item_id AND ci.app_sid = creg.app_sid
		  LEFT JOIN compliance_permit_condition cpc ON ci.compliance_item_id = cpc.compliance_item_id AND ci.app_sid = cpc.app_sid
		 WHERE (in_compliance_item_id IS NULL OR ci.compliance_item_id = in_compliance_item_id)
		   AND (in_reference_code IS NULL OR ci.reference_code = in_reference_code)
		   AND (in_compliance_item_type IS NULL OR ci.compliance_item_type = in_compliance_item_type);

	OPEN out_rollout_info FOR
		SELECT cr.compliance_item_id,
			   cr.country,
			   pc.name geo_country_label,
			   cr.region,
			   pr.name geo_region_label,
			   cr.country_group,
			   cg.group_name geo_country_group_label,
			   cr.region_group,
			   rg.group_name geo_region_group_label,
			   cr.rollout_dtm,
			   cr.rollout_pending,
			   cr.compliance_item_rollout_id
		  FROM compliance_item_rollout cr
		  JOIN compliance_item ci
			ON cr.app_sid = ci.app_sid AND cr.compliance_item_id = ci.compliance_item_id
		  LEFT JOIN compliance_permit_condition cpc
			ON ci.compliance_item_id = cpc.compliance_item_id AND ci.app_sid = cpc.app_sid
		  LEFT JOIN postcode.country pc ON cr.country = pc.country
		  LEFT JOIN postcode.region pr ON cr.country = pr.country AND cr.region = pr.region
		  LEFT JOIN country_group cg ON cr.country_group = cg.country_group_id
		  LEFT JOIN region_group rg ON cr.region_group = rg.region_group_id
		 WHERE (in_compliance_item_id IS NULL OR ci.compliance_item_id = in_compliance_item_id)
		   AND (in_reference_code IS NULL OR ci.reference_code = in_reference_code)
		   AND (in_compliance_item_type IS NULL OR ci.compliance_item_type = in_compliance_item_type);

	security.security_pkg.DebugMsg('in_compliance_item_type: ' || in_compliance_item_type || ' in_compliance_item_id: ' || in_compliance_item_id || ' in_reference_code: ' || in_reference_code);
	INT_GetComplianceItemsLangs(in_compliance_item_type, in_compliance_item_id, in_reference_code, out_langs);
END;

PROCEDURE GetComplianceItemLangs(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	out_langs						OUT SYS_REFCURSOR
)
AS
BEGIN
	INT_GetComplianceItemsLangs(
		in_compliance_item_id		=> in_compliance_item_id,
		out_langs					=> out_langs
	);
END;

FUNCTION INTERNAL_IsSuperAdmin RETURN BOOLEAN
AS
BEGIN
	RETURN csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct);
END;

FUNCTION INTERNAL_IsInAdminGroup RETURN BOOLEAN
AS
BEGIN
	RETURN (user_pkg.IsUserInGroup(
		security_pkg.GetAct,
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp(), 'Groups/Administrators')) = 1);
END;

PROCEDURE INTERNAL_AssertSuperAdmin
AS
BEGIN
	IF NOT (INTERNAL_IsSuperAdmin()) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;
END;

FUNCTION INTERNAL_IsAdmin RETURN BOOLEAN
AS
BEGIN
	RETURN (INTERNAL_IsSuperAdmin OR INTERNAL_IsInAdminGroup);
END;

PROCEDURE INTERNAL_AssertAdmin
AS
BEGIN
	IF NOT (INTERNAL_IsAdmin) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied. Only BuiltinAdministrator, super admins or members of the administrator group can run this.'
		);
	END IF;
END;

FUNCTION INTERNAL_IsComplianceManager RETURN BOOLEAN
AS
BEGIN
	return csr_data_pkg.CheckCapability('Manage compliance items');
END;

PROCEDURE AssertComplianceMgr
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage compliance items') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Missing "Manage compliance items" capability');
	END IF;
END;

PROCEDURE INTERNAL_AssertCanReadCompItem (
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE
)
AS
BEGIN
	-- allow anyone with capability
	IF csr_data_pkg.CheckCapability('Manage compliance items') THEN
		RETURN;
	END IF;

	-- or anyone assigned the compliance item via workflow
	FOR r IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS (
			SELECT *
			  FROM compliance_item_region cir
			  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
			 WHERE cir.compliance_item_id = in_compliance_item_id
			   AND (EXISTS (
						SELECT 1
						  FROM region_role_member rrm
						  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
						 WHERE rrm.app_sid = cir.app_sid
						   AND rrm.region_sid = cir.region_sid
						   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   AND fsr.flow_state_id = fi.current_state_id
					)
					OR EXISTS (
						SELECT 1
						  FROM flow_state_role fsr
						  JOIN security.act act ON act.sid_id = fsr.group_sid
						 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						   AND fsr.flow_state_id = fi.current_state_id
					))
		 )
	) LOOP
		RETURN;
	END LOOP;

	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading compliance item with id '||in_compliance_item_id);
END;

FUNCTION INTERNAL_HasFlowAccess (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_edit_only					NUMBER
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
			  FROM compliance_item_region cir
			  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
			 WHERE cir.flow_item_id = in_flow_item_id
			   AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cir.app_sid
					   AND rrm.region_sid = cir.region_sid
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

FUNCTION INTERNAL_HasFlowAccess (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNAL_HasFlowAccess(in_flow_item_id, NULL);
END;

PROCEDURE INTERNAL_AssertCanEditFlowItem (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE
)
AS
BEGIN
	IF NOT INTERNAL_HasFlowAccess(in_flow_item_id, 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied editing compliance item with flow item id '||in_flow_item_id);
	END IF;
END;

PROCEDURE INTERNAL_AssertFlowAccess (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE
)
AS
BEGIN
	IF NOT INTERNAL_HasFlowAccess(in_flow_item_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing compliance item with flow item id: '||in_flow_item_id);
	END IF;
END;

PROCEDURE INTERNAL_CheckTransitAccess (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
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
			  FROM compliance_item_region cir
			  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
			  JOIN flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
			 WHERE cir.flow_item_id = in_flow_item_id
			   AND fst.to_state_id = in_to_state_id
			   AND (EXISTS (
						SELECT 1
						  FROM region_role_member rrm
						  JOIN flow_state_transition_role fstr ON rrm.app_sid = fstr.app_sid AND rrm.role_sid = fstr.role_sid
						 WHERE rrm.app_sid = cir.app_sid
						   AND rrm.region_sid = cir.region_sid
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

FUNCTION INTERNAL_FlowForComplianceItem(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE
)
RETURN security_pkg.T_SID_ID
AS
   v_flow_sid                        security_pkg.T_SID_ID;
   v_item_type                        NUMBER;
BEGIN
   SELECT compliance_item_type
     INTO v_item_type
     FROM compliance_item ci
    WHERE ci.compliance_item_id = in_compliance_item_id;

   SELECT CASE WHEN v_item_type = COMPLIANCE_REQUIREMENT
              THEN requirement_flow_sid
			  WHEN v_item_type = COMPLIANCE_CONDITION
			  THEN condition_flow_sid
              ELSE regulation_flow_sid
          END
     INTO v_flow_sid
     FROM compliance_options
    WHERE app_sid = security_pkg.GetApp;

   RETURN v_flow_sid;
END;

FUNCTION INTERNAL_GetFlowStateNatures(
	in_class						IN	flow.flow_alert_class%TYPE
)
RETURN flow_state_natures
AS
	v_record						flow_state_natures;
BEGIN
	IF in_class = 'regulation' THEN
		v_record.new_item			:= csr_data_pkg.NATURE_REGULATION_NEW;
		v_record.updated			:= csr_data_pkg.NATURE_REGULATION_UPDATED;
		v_record.action_required	:= csr_data_pkg.NATURE_REGULATION_ACTION_REQ;
		v_record.compliant			:= csr_data_pkg.NATURE_REGULATION_COMPLIANT;
		v_record.not_applicable		:= csr_data_pkg.NATURE_REGULATION_NA;
		v_record.retired			:= csr_data_pkg.NATURE_REGULATION_RETIRED;
	ELSIF in_class = 'requirement' THEN
		v_record.new_item			:= csr_data_pkg.NATURE_REQUIREMENT_NEW;
		v_record.updated			:= csr_data_pkg.NATURE_REQUIREMENT_UPDATED;
		v_record.action_required	:= csr_data_pkg.NATURE_REQUIREMENT_ACTION_REQ;
		v_record.compliant			:= csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT;
		v_record.not_applicable		:= csr_data_pkg.NATURE_REQUIREMENT_NA;
		v_record.retired			:= csr_data_pkg.NATURE_REQUIREMENT_RETIRED;
	ELSIF in_class = 'condition' THEN
		v_record.not_created		:= csr_data_pkg.NATURE_CONDIT_NOT_CREATED;
		v_record.updated			:= csr_data_pkg.NATURE_CONDIT_UPDATED;
		v_record.active				:= csr_data_pkg.NATURE_CONDIT_ACTIVE;
		v_record.inactive			:= csr_data_pkg.NATURE_CONDIT_INACTIVE;
		v_record.action_required	:= csr_data_pkg.NATURE_CONDIT_ACTION_REQ;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Unexpected flow alert class');
	END IF;

	RETURN v_record;
END;

FUNCTION INTERNAL_GetFlowStateNatures(
	in_flow_sid						security_pkg.T_SID_ID
)
RETURN flow_state_natures
AS
	v_class							flow.flow_alert_class%TYPE;
BEGIN
	SELECT flow_alert_class
	  INTO v_class
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	RETURN INTERNAL_GetFlowStateNatures(v_class);
END;

FUNCTION INTERNAL_IsNew(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE
)
RETURN BOOLEAN
AS
	v_nature						flow_state_nature.flow_state_nature_id%TYPE;
	v_class							flow.flow_alert_class%TYPE;
BEGIN
	SELECT fs.flow_state_nature_id, f.flow_alert_class
	  INTO v_nature, v_class
	  FROM flow_item fi
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
	  JOIN flow f ON fi.flow_sid = f.flow_sid AND fi.app_sid = f.app_sid
	 WHERE fi.flow_item_id = in_flow_item_id;

	RETURN v_nature = INTERNAL_GetFlowStateNatures(v_class).new_item;
END;

FUNCTION INTERNAL_CreateDefaultWorkflow(
	in_label						flow.label%TYPE,
	in_class						flow.flow_alert_class%TYPE
)
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
		 WHERE flow_alert_class = in_class;
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
		in_label			=> in_label,
		in_parent_sid		=> v_wf_ct_sid,
		in_flow_alert_class	=> in_class,
		out_flow_sid		=> v_workflow_sid
	);

	compliance_setup_pkg.UpdateDefaultWorkflow(v_workflow_sid, in_class);

	RETURN v_workflow_sid;
END;

PROCEDURE INTERNAL_AddAuditLogEntry (
	in_flow_item_id					IN  flow_item_audit_log.flow_item_id%TYPE,
	in_description					IN  flow_item_audit_log.description%TYPE,
	in_param_1						IN  flow_item_audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2						IN  flow_item_audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3						IN  flow_item_audit_log.param_3%TYPE DEFAULT NULL,
	in_comment_text					IN  flow_item_audit_log.comment_text%TYPE
)
AS
BEGIN
	-- no security to insert into audit log
	INSERT INTO flow_item_audit_log (flow_item_audit_log_id, flow_item_id, description, param_1, param_2, param_3, comment_text)
	VALUES (flow_item_audit_log_id_seq.NEXTVAL, in_flow_item_id, in_description, in_param_1, in_param_2, in_param_3, in_comment_text);
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

FUNCTION INTERNAL_TransitionToNew(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE
)
RETURN flow_state.flow_state_id%TYPE
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_nature						flow_state_nature.flow_state_nature_id%TYPE;
	v_flow_state_id					flow_state.flow_state_id%TYPE;
BEGIN
	v_flow_sid := INTERNAL_FlowForComplianceItem(in_compliance_item_id);

	IF v_flow_sid IS NOT NULL THEN
		v_nature := INTERNAL_GetFlowStateNatures(v_flow_sid).new_item;
		v_flow_state_id := flow_pkg.SetItemStateNature(in_flow_item_id, v_nature, in_comment);

		RETURN v_flow_state_id;
	ELSE
		RETURN NULL;
	END IF;
END;

PROCEDURE INTERNAL_TransitionToRetired(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_nature						flow_state_nature.flow_state_nature_id%TYPE;
	v_to_state						flow_item.flow_sid%TYPE;
BEGIN
	v_flow_sid := INTERNAL_FlowForComplianceItem(in_compliance_item_id);

	IF v_flow_sid IS NOT NULL THEN
		v_nature := INTERNAL_GetFlowStateNatures(v_flow_sid).retired;
		v_to_state := flow_pkg.SetItemStateNature(in_flow_item_id, v_nature, in_comment);
	END IF;
END;

PROCEDURE INTERNAL_TransitionToUpdated(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_nature						flow_state_nature.flow_state_nature_id%TYPE;
	v_to_state						flow_item.flow_sid%TYPE;
	v_state_name					flow_state.label%TYPE;
BEGIN
	v_flow_sid := INTERNAL_FlowForComplianceItem(in_compliance_item_id);

	IF v_flow_sid IS NOT NULL THEN
		v_nature := INTERNAL_GetFlowStateNatures(v_flow_sid).updated;
		v_to_state := flow_pkg.SetItemStateNature(in_flow_item_id, v_nature, in_comment);
	END IF;
END;

PROCEDURE INTERNAL_TransitionToActionReq(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_comment						IN	flow_state_log.comment_text%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_nature						flow_state_nature.flow_state_nature_id%TYPE;
	v_state_name					flow_state.label%TYPE;
	v_final_state					NUMBER(1);
BEGIN
	SELECT NVL(MAX(fis.is_final), 0)
	  INTO v_final_state
	  FROM flow_item fi
	  JOIN flow_state fis
		ON fi.app_sid = fis.app_sid
	   AND fi.current_state_id = flow_state_id
	 WHERE flow_item_id = in_flow_item_id;

	v_flow_sid := INTERNAL_FlowForComplianceItem(in_compliance_item_id);

	IF v_flow_sid IS NOT NULL AND v_final_state = 0 THEN
		v_nature := INTERNAL_GetFlowStateNatures(v_flow_sid).action_required;
		BEGIN
			flow_pkg.SetItemStateNature(
				in_flow_item_id		=> in_flow_item_id,
				in_to_nature		=> v_nature,
				in_comment			=> in_comment,
				in_force			=> 0
			);
		EXCEPTION
			WHEN csr_data_pkg.CONCURRENCY_CONFLICT THEN -- means "no valid transition"
				flow_pkg.SetItemStateNature(
					in_flow_item_id		=> in_flow_item_id,
					in_to_nature		=> v_nature,
					in_comment			=> in_comment,
					in_force			=> 1
				);
		END;
	END IF;
END;

FUNCTION IsModuleEnabled RETURN NUMBER
AS
BEGIN
	FOR r IN (
		SELECT NULL
		  FROM compliance_options
		 WHERE requirement_flow_sid IS NOT NULL
		    OR regulation_flow_sid IS NOT NULL
	) LOOP
		RETURN 1;
	END LOOP;

	RETURN 0;
END;

FUNCTION GetComplianceItemUrl (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE
)  RETURN VARCHAR2
AS
BEGIN
	RETURN  '/csr/site/compliance/RegionCompliance.acds?flowItemId='||in_flow_item_id;
END;

-- Start of issue type helper procedures
PROCEDURE OnScheduledTaskCreated (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_parent_id					IN  NUMBER
)
AS
	v_label							issue_scheduled_task.label%TYPE;
BEGIN
	INTERNAL_AssertCanEditFlowItem(in_parent_id);

	SELECT label
	  INTO v_label
	  FROM issue_scheduled_task
	 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;

	BEGIN
		INSERT INTO comp_item_region_sched_issue (issue_scheduled_task_id, flow_item_id)
			 VALUES (in_issue_scheduled_task_id, in_parent_id);

		INTERNAL_AddAuditLogEntry(in_parent_id, 'New scheduled action {0} added', v_label, null, null, null);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			INTERNAL_AddAuditLogEntry(in_parent_id, 'Scheduled action {0} modified', v_label, null, null, null);
	END;
END;

PROCEDURE OnScheduledTaskDeleted (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE
)
AS
	v_flow_item_id					comp_item_region_sched_issue.flow_item_id%TYPE;
	v_label							issue_scheduled_task.label%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM comp_item_region_sched_issue
		 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;

	INTERNAL_AssertCanEditFlowItem(v_flow_item_id);

	DELETE FROM comp_item_region_sched_issue
	 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;

	SELECT label
	  INTO v_label
	  FROM issue_scheduled_task
	 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;

	INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Scheduled action {0} deleted', v_label, null, null, null);
END;

PROCEDURE OnScheduledIssueCreated (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_issue_id						IN  issue.issue_id%TYPE
)
AS
	v_flow_item_id					comp_item_region_sched_issue.flow_item_id%TYPE;
	v_issue_compliance_region_id	issue.issue_compliance_region_id%TYPE;
BEGIN
	-- no security check, called from scheduled task

	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM comp_item_region_sched_issue
		 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;

	v_issue_compliance_region_id := issue_compliance_region_id_seq.NEXTVAL;
	INSERT INTO issue_compliance_region (issue_compliance_region_id, flow_item_id)
	     VALUES (v_issue_compliance_region_id, v_flow_item_id);

	UPDATE issue
	   SET issue_compliance_region_id = v_issue_compliance_region_id
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

PROCEDURE OnCriticalIssueOverdue(
	in_issue_id						IN	issue.issue_id%TYPE
)
AS
	v_flow_item_id					flow_item.flow_item_id%TYPE;
	v_compliance_item_id			compliance_item.compliance_item_id%TYPE;
BEGIN
	BEGIN
		SELECT cir.flow_item_id, cir.compliance_item_id
		  INTO v_flow_item_id, v_compliance_item_id
		  FROM issue i
		  JOIN issue_compliance_region icr
			ON i.app_sid = icr.app_sid
		   AND i.issue_compliance_region_id = icr.issue_compliance_region_id
		  JOIN compliance_item_region cir
			ON icr.app_sid = cir.app_sid
		   AND icr.flow_item_id = cir.flow_item_id
		 WHERE issue_id = in_issue_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;

	INTERNAL_TransitionToActionReq(
		in_flow_item_id				=> v_flow_item_id,
		in_compliance_item_id		=> v_compliance_item_id,
		in_comment					=> 'Critical action overdue'
	);
END;

-- End of issue type helper procedures

-- Start of compliance language procedures
PROCEDURE GetComplianceLanguages (
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security check for get, may be required information for non-ehsmanager roles.
	OPEN out_cur FOR
		SELECT l.lang, l.description, cl.lang_id, cl.added_dtm
		  FROM compliance_language cl
		  JOIN aspen2.lang l ON cl.lang_id = l.lang_id
		 WHERE cl.app_sid = security_pkg.GetApp()
		   AND cl.active = 1
		 ORDER BY l.description;
END;

PROCEDURE AddComplianceLanguage (
	in_lang_id						IN	compliance_language.lang_id%TYPE
)
AS
	v_is_inactive_lang				NUMBER(1);
BEGIN
	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;

	-- If the language was previously used, reactivate
	SELECT COUNT(lang_id)
	  INTO v_is_inactive_lang
	  FROM compliance_language
	 WHERE app_sid =  security_pkg.GetApp()
	   AND lang_id = in_lang_id;

	IF v_is_inactive_lang = 1
	THEN
		UPDATE compliance_language
		   SET active = 1
		 WHERE app_sid = security_pkg.GetApp()
		   AND lang_id = in_lang_id;
	ELSE
		INSERT INTO compliance_language (lang_id)
		VALUES (in_lang_id);
	END IF;
END;

PROCEDURE AddComplianceLanguageByIso (
	in_lang							IN	VARCHAR2
)
AS
	v_lang_id						compliance_language.lang_id%TYPE;
BEGIN
	SELECT lang_id 
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = in_lang;
	 
	 AddComplianceLanguage(v_lang_id);
END;

PROCEDURE RemoveComplianceLanguages
AS
BEGIN
	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;

	UPDATE compliance_language
	   SET active = 0
	 WHERE app_sid = security_pkg.GetApp();
END;

PROCEDURE SaveComplianceItemDesc (
	in_compliance_item_id		IN compliance_item_description.compliance_item_id%TYPE,
	in_lang						IN VARCHAR2,
	in_title					IN compliance_item_description.title%TYPE,
	in_details					IN compliance_item_description.details%TYPE,
	in_summary					IN compliance_item_description.summary%TYPE,
	in_citation					IN compliance_item_description.citation%TYPE,
	in_major_version			IN compliance_item_description.major_version%TYPE,
	in_minor_version			IN compliance_item_description.minor_version%TYPE
)
AS
	v_lang_id					compliance_item_description.lang_id%TYPE;
	v_major_version				compliance_item_description.major_version%TYPE := in_major_version;
	v_minor_version				compliance_item_description.minor_version%TYPE := in_minor_version;
BEGIN
	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;
	
	SELECT lang_id 
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = in_lang;

	IF v_major_version = 0 AND v_minor_version = 0 THEN
		SELECT major_version, minor_version
		  INTO v_major_version, v_minor_version
		  FROM csr.compliance_item
		 WHERE compliance_item_id = in_compliance_item_id;
	END IF;
	
	BEGIN
		INSERT INTO compliance_item_description (compliance_item_id, lang_id, title, details, summary, citation, major_version, minor_version)
		VALUES (in_compliance_item_id, v_lang_id, in_title, in_details, in_summary, in_citation, in_major_version, in_minor_version);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE compliance_item_description
			   SET title = in_title,
				   details = in_details,
				   summary = in_summary,
				   citation = in_citation,
				   major_version = v_major_version,
				   minor_version = v_minor_version
			 WHERE compliance_item_id = in_compliance_item_id
			   AND lang_id = v_lang_id
			   AND app_sid = security_pkg.GetApp();
	END;
END;

PROCEDURE RemoveComplianceItemDesc (
	in_compliance_item_id		IN compliance_item_description.compliance_item_id%TYPE,
	in_lang_id					IN compliance_item_description.lang_id%TYPE
)
AS
BEGIN
	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;

	DELETE FROM compliance_item_description
	 WHERE compliance_item_id = in_compliance_item_id
	   AND lang_id = in_lang_id
	   AND app_sid = security_pkg.getApp();
END;

-- End of compliance language procedures

-- Start of compliance audit log procedures

PROCEDURE AddComplianceAuditLog (
	in_compliance_item_id		IN compliance_audit_log.compliance_item_id%TYPE,
	in_date_time				IN compliance_audit_log.date_time%TYPE DEFAULT SYSDATE,
	in_responsible_user			IN compliance_audit_log.responsible_user%TYPE,
	in_user_lang_id				IN compliance_audit_log.user_lang_id%TYPE,
	in_sys_lang_id				IN compliance_audit_log.sys_lang_id%TYPE,
	in_lang_id					IN compliance_audit_log.lang_id%TYPE,
	in_title					IN compliance_audit_log.title%TYPE,
	in_summary					IN compliance_audit_log.summary%TYPE,
	in_details					IN compliance_audit_log.details%TYPE,
	in_citation					IN compliance_audit_log.citation%TYPE
)
AS
BEGIN
	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;
	
	INSERT INTO compliance_audit_log (
		   compliance_audit_log_id, compliance_item_id, date_time, responsible_user, user_lang_id, sys_lang_id, lang_id, title, summary,
		   details, citation)
	VALUES (compliance_audit_log_id_seq.NEXTVAL, in_compliance_item_id, in_date_time, in_responsible_user, in_user_lang_id,
		   in_sys_lang_id, in_lang_id, in_title, in_summary, in_details, in_citation);

END;

PROCEDURE GetComplianceAuditLog (
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	in_search			IN	VARCHAR2,
	in_lang_id			IN	compliance_audit_log.lang_id%TYPE,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
  	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;

	SELECT COUNT(cal.compliance_audit_log_id)
	  INTO out_total
	  FROM compliance_audit_log cal
	  JOIN compliance_item ci on cal.compliance_item_id = ci.compliance_item_id
	 WHERE cal.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ci.source = 0
	   --AND cal.date_time >= in_start_date AND cal.date_time <= in_end_date + 1
	   AND (in_search IS NULL OR (
			LOWER(cal.responsible_user) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cal.title) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cal.summary) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cal.details) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cal.citation) LIKE '%'||LOWER(in_search)||'%')
		);

	OPEN out_cur FOR
		SELECT x.* 
		FROM (SELECT a.*, ROWNUM rn
				FROM (SELECT cal.compliance_audit_log_id, cal.compliance_item_id, cal.date_time, cal.responsible_user, cal.user_lang_id, cal.sys_lang_id,
						cal.lang_id, cal.title, cal.summary, cal.details, cal.citation
						FROM compliance_audit_log cal
						JOIN compliance_item ci on cal.compliance_item_id = ci.compliance_item_id
						WHERE cal.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						AND ci.source = 0
						--AND cal.date_time >= in_start_date AND cal.date_time <= in_end_date + 1
						AND (in_search IS NULL OR (
							LOWER(cal.responsible_user) LIKE '%'||LOWER(in_search)||'%'
							OR LOWER(cal.title) LIKE '%'||LOWER(in_search)||'%'
							OR LOWER(cal.summary) LIKE '%'||LOWER(in_search)||'%'
							OR LOWER(cal.details) LIKE '%'||LOWER(in_search)||'%'
							OR LOWER(cal.citation) LIKE '%'||LOWER(in_search)||'%')
						)
					) a
				WHERE ROWNUM < in_start_row + in_page_size
				) x
		 WHERE x.rn >= in_start_row
		 ORDER BY x.date_time DESC;
				
END;
-- End of compliance audit log procedures

PROCEDURE GetScheduledIssues (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_AssertFlowAccess(in_flow_item_id);

	OPEN out_cur FOR
		SELECT ist.issue_scheduled_task_id, ist.label, ist.schedule_xml, ist.period_xml,
			   ist.assign_to_user_sid, au.full_name assign_to_full_name,
			   ist.raised_by_user_sid, ru.full_name raised_by_full_name,
			   ist.last_created, ist.due_dtm_relative, ist.due_dtm_relative_unit, ist.scheduled_on_due_date,
			   ist.create_critical
		  FROM issue_scheduled_task ist
		  JOIN csr_user au ON ist.app_sid = au.app_sid AND ist.assign_to_user_sid = au.csr_user_sid
		  JOIN csr_user ru ON ist.app_sid = ru.app_sid AND ist.raised_by_user_sid = ru.csr_user_sid
		  JOIN comp_item_region_sched_issue cirsi ON ist.issue_scheduled_task_id = cirsi.issue_scheduled_task_id
		 WHERE cirsi.flow_item_id = in_flow_item_id;
END;

PROCEDURE INTERNAL_SaveTags(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_tags							IN  security_pkg.T_SID_IDS

)
AS
BEGIN
	DELETE FROM compliance_item_tag
	 WHERE compliance_item_id = in_compliance_item_id;

	IF in_tags IS NOT NULL AND in_tags.COUNT > 0 THEN
		FOR i IN in_tags.FIRST .. in_tags.LAST
		LOOP
			IF in_tags(i) IS NOT NULL THEN 
				INSERT INTO compliance_item_tag (compliance_item_id, tag_id)
				VALUES (in_compliance_item_id, in_tags(i));
			END IF;
		END LOOP;
	END IF;
END;


PROCEDURE INTERNAL_SaveRegions(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_rollout_regionsids			IN  security_pkg.T_SID_IDS
)
AS
BEGIN
	DELETE FROM CSR.compliance_rollout_regions
	 WHERE compliance_item_id = in_compliance_item_id;

	IF in_rollout_regionsids IS NOT NULL AND in_rollout_regionsids.COUNT > 0 THEN
		FOR i IN in_rollout_regionsids.FIRST .. in_rollout_regionsids.LAST
		LOOP
			IF in_rollout_regionsids(i) IS NOT NULL THEN 
				INSERT INTO csr.compliance_rollout_regions (compliance_item_id, region_sid)
				VALUES (in_compliance_item_id, in_rollout_regionsids(i));
			END IF;
		END LOOP;
	END IF;
END;

FUNCTION INTERNAL_IsEnhesaMajorChange(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE
) RETURN BOOLEAN
AS
	v_curr_major_version	compliance_item.major_version%TYPE;
BEGIN
	SELECT major_version
	  INTO v_curr_major_version
	  FROM compliance_item
	 WHERE compliance_item_id = in_compliance_item_id;

	RETURN in_major_version > v_curr_major_version;
END;

FUNCTION HasEnhesaRegionUpdated(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_rollout_country				IN  compliance_item_rollout.country%TYPE,
	in_rollout_region				IN  compliance_item_rollout.region%TYPE,
	in_rollout_country_group		IN  compliance_item_rollout.country_group%TYPE,
	in_rollout_region_group			IN  compliance_item_rollout.region_group%TYPE,
	in_federal_req_code				IN  compliance_item_rollout.federal_requirement_code%TYPE,
	in_is_federal_req				IN  compliance_item_rollout.is_federal_req%TYPE
)
RETURN BOOLEAN
AS
	v_has_updated_region				NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_has_updated_region
	  FROM compliance_item_rollout
	 WHERE compliance_item_id = in_compliance_item_id
	   AND (DECODE(country, in_rollout_country, 1, 0) = 0
	    OR DECODE(region, in_rollout_region, 1, 0) = 0
	    OR DECODE(country_group, in_rollout_country_group, 1, 0) = 0
	    OR DECODE(region_group, in_rollout_region_group, 1, 0) = 0
		OR DECODE(federal_requirement_code, in_federal_req_code, 1, 0) = 0
		OR DECODE(is_federal_req, in_is_federal_req, 1, 0) = 0);

	RETURN v_has_updated_region > 0;
END;

PROCEDURE CreateRolloutInfo(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	in_source						IN  compliance_item.source%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT 1,
	in_rollout_country				IN  compliance_item_rollout.country%TYPE,
	in_rollout_region				IN  compliance_item_rollout.region%TYPE,
	in_rollout_country_group		IN  compliance_item_rollout.country_group%TYPE,
	in_rollout_region_group			IN  compliance_item_rollout.region_group%TYPE,
	in_rollout_tags					IN  security_pkg.T_SID_IDS,
	in_rollout_regionsids			IN  security_pkg.T_SID_IDS,
	in_federal_req_code				IN  compliance_item_rollout.federal_requirement_code%TYPE DEFAULT NULL,
	in_is_federal_req				IN  compliance_item_rollout.is_federal_req%TYPE DEFAULT 0,
	in_compliance_item_rollout_id	IN	compliance_item_rollout.compliance_item_rollout_id%TYPE DEFAULT NULL,
	in_source_country				IN	compliance_item_rollout.source_country%TYPE DEFAULT NULL,
	in_source_region				IN	compliance_item_rollout.source_region%TYPE DEFAULT NULL,
	in_suppress_rollout				IN  compliance_item_rollout.suppress_rollout%TYPE DEFAULT 0
)
AS
	v_comp_item_rollout_id			NUMBER(10) DEFAULT NULL;
	v_comp_item_exists				NUMBER(1);
BEGIN
	AssertComplianceMgr();
	
	IF in_compliance_item_rollout_id IS NULL THEN
		v_comp_item_rollout_id := compliance_item_rollout_id_seq.nextval;
	ELSE
		v_comp_item_rollout_id := in_compliance_item_rollout_id;
	END IF;
		
	IF in_source = SOURCE_ENHESA THEN
		BEGIN
			INSERT INTO compliance_item_rollout (
				compliance_item_id,
				country,
				region,
				country_group,
				region_group,
				compliance_item_rollout_id,
				federal_requirement_code,
				is_federal_req,
				source_region,
				source_country,
				suppress_rollout
			)
			VALUES (
				in_compliance_item_id,
				LOWER(in_rollout_country),
				in_rollout_region,
				LOWER(in_rollout_country_group),
				in_rollout_region_group,
				v_comp_item_rollout_id,
				in_federal_req_code,
				in_is_federal_req,
				in_source_region,
				in_source_country,
				in_suppress_rollout);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
			BEGIN
				UPDATE compliance_item_rollout
					SET country = LOWER(in_rollout_country),
					region = in_rollout_region,
					country_group = LOWER(in_rollout_country_group),
					region_group = in_rollout_region_group,
					federal_requirement_code = in_federal_req_code,
					is_federal_req = in_is_federal_req,
					source_country = in_source_country,
					source_region = in_source_region,
					suppress_rollout = in_suppress_rollout
					WHERE compliance_item_rollout_id = v_comp_item_rollout_id;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
				-- INDEX is on compliance_item_id, country, region, country_group, region_group
				BEGIN
					-- remove duplicate
					DELETE compliance_item_rollout
						WHERE compliance_item_id = in_compliance_item_id
						AND ((country IS NULL AND in_rollout_country IS NULL) OR (country = LOWER(in_rollout_country)))
						AND ((region IS NULL AND in_rollout_region IS NULL) OR (region = in_rollout_region))
						AND ((country_group IS NULL AND in_rollout_country_group IS NULL) OR (country_group = LOWER(in_rollout_country_group)))
						AND ((region_group IS NULL AND in_rollout_region_group IS NULL) OR (region_group = in_rollout_region_group))
						AND compliance_item_rollout_id != v_comp_item_rollout_id;
					--retry
					UPDATE compliance_item_rollout
					SET country = LOWER(in_rollout_country),
						region = in_rollout_region,
						country_group = LOWER(in_rollout_country_group),
						region_group = in_rollout_region_group,
						federal_requirement_code = in_federal_req_code,
						is_federal_req = in_is_federal_req,
						source_country = in_source_country,
						source_region = in_source_region,
						suppress_rollout = in_suppress_rollout
					WHERE compliance_item_rollout_id = v_comp_item_rollout_id;
				END;
			END;
		END;
	ELSIF in_source = SOURCE_USER_DEFINED THEN
		SELECT COUNT(*) 
		  INTO v_comp_item_exists
		  FROM compliance_item_rollout
		 WHERE compliance_item_id = in_compliance_item_id;
		
		IF v_comp_item_exists = 0 THEN
			INSERT INTO compliance_item_rollout (
				compliance_item_id,
				country,
				region,
				country_group,
				region_group,
				compliance_item_rollout_id,
				federal_requirement_code,
				is_federal_req,
				source_region,
				source_country,
				suppress_rollout)
			VALUES (
				in_compliance_item_id,
				LOWER(in_rollout_country),
				in_rollout_region,
				LOWER(in_rollout_country_group),
				in_rollout_region_group,
				v_comp_item_rollout_id,
				in_federal_req_code,
				in_is_federal_req,
				in_source_region,
				in_source_country,
				in_suppress_rollout);
		ELSE		
			UPDATE compliance_item_rollout
			   SET country = LOWER(in_rollout_country),
				region = in_rollout_region,
				country_group = LOWER(in_rollout_country_group),
				region_group = in_rollout_region_group,
				federal_requirement_code = in_federal_req_code,
				is_federal_req = in_is_federal_req,
				source_country = in_source_country,
				source_region = in_source_region,
				suppress_rollout = in_suppress_rollout
			 WHERE compliance_item_id = in_compliance_item_id;
		END IF;
	END IF;

	INTERNAL_SaveTags(in_compliance_item_id, in_rollout_tags);
	INTERNAL_SaveRegions(in_compliance_item_id, in_rollout_regionsids);
END;

PROCEDURE INTERNAL_GetTags(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_id
		  FROM csr.compliance_item_tag
		 WHERE compliance_item_id = in_compliance_item_id
		   AND app_sid = security.security_pkg.getApp();
END;

PROCEDURE INTERNAL_GetRegions(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cs.region_sid,Description
		  FROM csr.compliance_rollout_regions cs
		  JOIN csr.v$region r ON r.region_sid = cs.REGION_SID
		 WHERE cs.compliance_item_id = in_compliance_item_id
		   AND cs.app_sid = security.security_pkg.getApp();	
END;

FUNCTION INTERNAL_ConvertReferenceCode(
	in_reference_code				IN  compliance_item.reference_code%TYPE
) RETURN compliance_item.reference_code%TYPE
AS
	v_adjusted_ref_code				compliance_item.reference_code%TYPE;
BEGIN
	v_adjusted_ref_code := in_reference_code;

	IF v_adjusted_ref_code is not null THEN
		v_adjusted_ref_code := UPPER(TRIM(v_adjusted_ref_code));
	END IF;

	RETURN v_adjusted_ref_code;
END;

PROCEDURE INT_UpdateCompItemHist(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_change_type					IN	compliance_item_version_log.change_type%TYPE,
	in_major_version				IN	compliance_item.major_version%TYPE,
	in_minor_version				IN	compliance_item.minor_version%TYPE,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN	compliance_item_version_log.description%TYPE,
	in_lang_id						IN	compliance_item_version_log.lang_id%TYPE,
	in_change_dtm					IN	compliance_item_version_log.change_dtm%TYPE DEFAULT SYSDATE
)
AS
BEGIN
	INSERT INTO compliance_item_version_log (
		compliance_item_version_log_id, compliance_item_id, change_type, change_dtm,
		major_version, minor_version, is_major_change, description, lang_id)
	VALUES (
		comp_item_version_log_seq.NEXTVAL, in_compliance_item_id, in_change_type, in_change_dtm,
		in_major_version, in_minor_version, in_is_major_change, in_change_reason, in_lang_id);
END;

-- only called from enhesa integration
PROCEDURE UNSEC_AddComplianceItemHistory(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_change_type					IN	compliance_item_version_log.change_type%TYPE,
	in_major_version				IN	compliance_item.major_version%TYPE,
	in_minor_version				IN	compliance_item.minor_version%TYPE,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN	compliance_item_version_log.description%TYPE,
	in_lang							IN	VARCHAR2,
	in_change_dtm					IN	compliance_item_version_log.change_dtm%TYPE
)
AS
	v_lang_id						compliance_item_version_log.lang_id%TYPE;
	v_comp_item_version_log_id	compliance_item_version_log.compliance_item_version_log_id%TYPE;
BEGIN
	SELECT lang_id 
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lower(lang) = lower(in_lang);
 
	BEGIN
		-- remove after we put UK on compliance_item_version_log after doing data cleanup
		SELECT compliance_item_version_log_id
		  INTO v_comp_item_version_log_id
		  FROM compliance_item_version_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND compliance_item_id = in_compliance_item_id
		   AND major_version = in_major_version
		   AND minor_version = in_minor_version
		   AND is_major_change = in_is_major_change
		   AND (lang_id = v_lang_id OR (v_lang_id = 53 AND lang_id IS NULL));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INT_UpdateCompItemHist(
				in_compliance_item_id		=>	in_compliance_item_id,
				in_change_type				=>	in_change_type,
				in_major_version			=>	in_major_version,
				in_minor_version			=>	in_minor_version,
				in_is_major_change			=>	in_is_major_change,
				in_change_reason			=>	in_change_reason,
				in_lang_id					=>	v_lang_id,
				in_change_dtm				=>	in_change_dtm
			);
		WHEN TOO_MANY_ROWS THEN
			RETURN;
	END;
END;

PROCEDURE INT_UpdateCompItemDescHist(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_lang_id						IN	compliance_language.lang_id%TYPE,
	in_major_version				IN	compliance_item.major_version%TYPE,
	in_minor_version				IN	compliance_item.minor_version%TYPE,
	in_title						IN	compliance_item.title%TYPE,
	in_summary						IN	compliance_item.summary%TYPE,
	in_details						IN	compliance_item.details%TYPE,
	in_citation						IN	compliance_item.citation%TYPE,
	in_description					IN	compliance_item_version_log.description%TYPE,
	in_change_dtm					IN	compliance_item_version_log.change_dtm%TYPE
)
AS
	v_default_language_id			compliance_language.lang_id%TYPE;
BEGIN
	SELECT l.lang_id
	  INTO v_default_language_id
	  FROM aspen2.lang l
	 WHERE l.lang = 'en';
	
	IF v_default_language_id IS NULL AND in_lang_id IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Missing language');
	END IF;

	INSERT INTO compliance_item_desc_hist (
		compliance_item_desc_hist_id, compliance_item_id, lang_id,
		major_version, minor_version, title, summary_clob, details, citation, description, change_dtm)
	VALUES (
		compliance_item_desc_hist_seq.NEXTVAL, in_compliance_item_id, NVL(in_lang_id, v_default_language_id),
		in_major_version, in_minor_version, in_title, in_summary, in_details, in_citation, in_description, in_change_dtm);
END;

PROCEDURE INTERNAL_CreateComplianceItem(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_title						IN	compliance_item.title%TYPE,
	in_summary						IN	compliance_item.summary%TYPE,
	in_details						IN	compliance_item.details%TYPE,
	in_reference_code				IN	compliance_item.reference_code%TYPE,
	in_user_comment					IN	compliance_item.user_comment%TYPE,
	in_citation						IN	compliance_item.citation%TYPE,
	in_external_link				IN	compliance_item.external_link%TYPE,
	in_status_id 					IN	compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_change_type					IN	compliance_item_version_log.change_type%TYPE,
	in_major_version				IN	compliance_item.major_version%TYPE DEFAULT 1,
	in_minor_version				IN	compliance_item.major_version%TYPE DEFAULT 0,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
	in_is_first_publication			IN	NUMBER DEFAULT 0,
	in_source						IN	compliance_item.source%TYPE,
	in_compliance_item_type			IN	compliance_item.compliance_item_type%TYPE,
	in_lang_id						IN	compliance_language.lang_id%TYPE DEFAULT NULL
)
AS
	v_new_major_version				compliance_item.major_version%TYPE;
	v_new_minor_version				compliance_item.minor_version%TYPE;
	v_change_type					compliance_item_version_log.change_type%TYPE;
	v_adjusted_ref_code				compliance_item.reference_code%TYPE;
	v_lang_id						compliance_language.lang_id%TYPE;
BEGIN
	-- Security asserted by externally facing procedures
	IF in_source = SOURCE_USER_DEFINED THEN
		v_new_major_version := 1;
		v_new_minor_version := 0;
		v_change_type := 2;
	ELSE
		v_new_major_version := in_major_version;
		v_new_minor_version := in_minor_version;
		v_change_type := in_change_type;
	END IF;

	v_adjusted_ref_code := INTERNAL_ConvertReferenceCode(in_reference_code);

	INSERT INTO compliance_item (compliance_item_id, title, summary, details, source,
								 reference_code, user_comment, citation, external_link,
								 major_version, minor_version, compliance_item_status_id, lookup_key,
								 compliance_item_type)
	VALUES (in_compliance_item_id, TRIM(in_title), in_summary, in_details, in_source,
			v_adjusted_ref_code, in_user_comment, in_citation, in_external_link,
			v_new_major_version, v_new_minor_version, in_status_id, in_lookup_key,
			in_compliance_item_type);

	-- 53 base data english
	v_lang_id := NVL(in_lang_id, 53);
	
	INSERT INTO compliance_item_description (compliance_item_id, lang_id, title, summary, details, citation)
	VALUES (in_compliance_item_id, v_lang_id, in_title, in_summary, in_details, in_citation);

	IF in_is_first_publication = 0 THEN
		INT_UpdateCompItemHist(
			in_compliance_item_id		=>	in_compliance_item_id,
			in_change_type				=>	v_change_type,
			in_major_version			=>	v_new_major_version,
			in_minor_version			=>	v_new_minor_version,
			in_is_major_change			=>	in_is_major_change,
			in_change_reason			=>	NULL,
			in_lang_id					=>	v_lang_id
		);
	END IF;

END;

PROCEDURE INTERNAL_GetComplianceChildren(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_compliance_item_type			IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT compliance_item_id, title, summary, reference_code, details
		  FROM compliance_item
		 WHERE compliance_item_id IN (
			SELECT
				CASE WHEN in_compliance_item_type = COMPLIANCE_REGULATION THEN
					requirement_id
				WHEN in_compliance_item_type = COMPLIANCE_REQUIREMENT THEN
					regulation_id
				END compliance_item_id
			  FROM compliance_req_reg
			 WHERE (in_compliance_item_type = COMPLIANCE_REQUIREMENT AND requirement_id = in_compliance_item_id)
			    OR (in_compliance_item_type = COMPLIANCE_REGULATION AND regulation_id = in_compliance_item_id)
		);
END;

PROCEDURE CreateRequirement(
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT 1,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT 0,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	out_compliance_item_id			OUT compliance_item.compliance_item_id%TYPE
)
AS
BEGIN
	AssertComplianceMgr();

	out_compliance_item_id := compliance_item_seq.NEXTVAL;

	INTERNAL_CreateComplianceItem(
		in_compliance_item_id 		=> out_compliance_item_id,
		in_title					=> in_title,
		in_summary					=> in_summary,
		in_details					=> in_details,
		in_source					=> in_source,
		in_reference_code			=> in_reference_code,
		in_user_comment				=> in_user_comment,
		in_citation					=> in_citation,
		in_external_link			=> in_external_link,
		in_change_type				=> in_change_type,
		in_major_version			=> in_major_version,
		in_minor_version			=> in_minor_version,
		in_is_major_change			=> in_is_major_change,
		in_status_id 				=> in_status_id,
		in_lookup_key			 	=> in_lookup_key,
		in_is_first_publication		=> in_is_first_publication,
		in_compliance_item_type		=> COMPLIANCE_REQUIREMENT
	);

	INSERT INTO compliance_requirement (compliance_item_id)
	VALUES (out_compliance_item_id);
END;

PROCEDURE CreateRegulation(
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_external_id					IN  csr.compliance_regulation.external_id%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT 1,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT 0,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	in_is_policy					IN	csr.compliance_regulation.is_policy%TYPE DEFAULT 0,
	in_adoption_dtm					IN  csr.compliance_regulation.adoption_dtm%TYPE,
	out_compliance_item_id			OUT compliance_item.compliance_item_id%TYPE
)
AS
BEGIN
	AssertComplianceMgr();

	out_compliance_item_id := compliance_item_seq.NEXTVAL;

	INTERNAL_CreateComplianceItem(
		in_compliance_item_id		=> out_compliance_item_id,
		in_title					=> in_title,
		in_summary					=> in_summary,
		in_details					=> in_details,
		in_source					=> in_source,
		in_reference_code			=> in_reference_code,
		in_user_comment				=> in_user_comment,
		in_citation					=> in_citation,
		in_external_link			=> in_external_link,
		in_change_type				=> in_change_type,
		in_major_version			=> in_major_version,
		in_minor_version			=> in_minor_version,
		in_is_major_change			=> in_is_major_change,
		in_status_id 				=> in_status_id,
		in_lookup_key				=> in_lookup_key,
		in_is_first_publication 	=> in_is_first_publication,
		in_compliance_item_type		=> COMPLIANCE_REGULATION
	);

	INSERT INTO compliance_regulation (compliance_item_id, adoption_dtm, external_id, is_policy)
	VALUES (out_compliance_item_id, in_adoption_dtm, in_external_id, in_is_policy);
END;

PROCEDURE CreatePermitCondition(
	in_title						IN  compliance_item.title%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_permit_id					IN	compliance_permit_condition.compliance_permit_id%TYPE,
	in_condition_type_id			IN	compliance_permit_condition.condition_type_id%TYPE,
	in_condition_sub_type_id		IN	compliance_permit_condition.condition_sub_type_id%TYPE,
	out_compliance_item_id			OUT compliance_item.compliance_item_id%TYPE
)
AS
	v_flow_item_id					security_pkg.T_SID_ID;
BEGIN
	AssertComplianceMgr();

	out_compliance_item_id := compliance_item_seq.NEXTVAL;

	INTERNAL_CreateComplianceItem(
		in_compliance_item_id		=> out_compliance_item_id,
		in_title					=> in_title,
		in_summary					=> NULL,
		in_details					=> in_details,
		in_source					=> 0,
		in_reference_code			=> in_reference_code,
		in_user_comment				=> NULL,
		in_citation					=> NULL,
		in_external_link			=> NULL,
		in_change_type				=> in_change_type,
		in_major_version			=> 1,
		in_minor_version			=> 0,
		in_is_major_change			=> 0,
		in_status_id 				=> COMPLIANCE_STATUS_PUBLISHED,
		in_lookup_key				=> NULL,
		in_is_first_publication 	=> 1,
		in_compliance_item_type		=> COMPLIANCE_CONDITION
	);

	INSERT INTO compliance_permit_condition (
		compliance_item_id, compliance_permit_id, condition_type_id, condition_sub_type_id)
	VALUES (
		out_compliance_item_id, in_permit_id, in_condition_type_id, in_condition_sub_type_id);

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM compliance_permit
	 WHERE compliance_permit_id = in_permit_id;

	INTERNAL_AddAuditLogEntry(v_flow_item_id, 'Condition number {0} and id {1} linked to permit.', in_reference_code, out_compliance_item_id, null, null);
END;

PROCEDURE CreatePermitConditionFlowItem (
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_flow_item_id				OUT	flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_new_state_id					security_pkg.T_SID_ID;
	v_region_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT condition_flow_sid
	  INTO v_flow_sid
	  FROM compliance_options;

	flow_pkg.AddFlowItem(v_flow_sid, out_flow_item_id);

	SELECT region_sid
	  INTO v_region_sid
	  FROM csr.compliance_permit
	 WHERE compliance_permit_id = in_permit_id;

	INSERT INTO compliance_item_region (compliance_item_id, region_sid, flow_item_id)
	VALUES (in_compliance_item_id, v_region_sid, out_flow_item_id);

	INTERNAL_AddAuditLogEntry(
		in_flow_item_id		=> out_flow_item_id,
		in_description		=> 'Condition created',
		in_comment_text		=> ''
	);

	BEGIN
		SELECT flow_state_id
		  INTO v_new_state_id
		  FROM flow_state
		 WHERE lookup_key = 'NEW'
		   AND flow_sid = v_flow_sid;

		flow_pkg.SetItemState(
			in_flow_item_id		=> out_flow_item_id,
			in_to_state_Id		=> v_new_state_id,
			in_comment_text		=> 'Created',
			in_user_sid			=> SYS_CONTEXT('SECURITY','SID')
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		-- Don't bother if workflow doesn't have a state to transition to on creation.
			NULL;
	END;
END;

PROCEDURE INTERNAL_UpdateVersionNumber
(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_change_reason				IN  compliance_item_version_log.description%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE,
	in_is_standard_audit_entry		IN	BOOLEAN DEFAULT true,
	out_new_major_version			OUT compliance_item.major_version%TYPE,
	out_new_minor_version			OUT compliance_item.minor_version%TYPE
)
AS
	v_current_major_version			compliance_item.major_version%TYPE;
	v_current_minor_version			compliance_item.minor_version%TYPE;
	v_new_major_version				compliance_item.major_version%TYPE;
	v_new_minor_version				compliance_item.minor_version%TYPE;
	v_source						compliance_item.source%TYPE;
	v_current_status				compliance_item.compliance_item_status_id%TYPE;

BEGIN
	SELECT major_version, minor_version, compliance_item_status_id, source
	  INTO v_current_major_version, v_current_minor_version, v_current_status, v_source
	  FROM compliance_item
	 WHERE compliance_item_id = in_compliance_item_id;

	IF in_is_standard_audit_entry AND v_current_status = COMPLIANCE_STATUS_DRAFT AND in_status_id = COMPLIANCE_STATUS_DRAFT THEN
		UPDATE compliance_item_version_log
		   SET change_dtm = SYSDATE
		 WHERE compliance_item_id = in_compliance_item_id;

	 	out_new_major_version := v_current_major_version;
		out_new_minor_version := v_current_minor_version;

		RETURN;
	END IF;

	v_new_major_version := v_current_major_version;
	v_new_minor_version := v_current_minor_version;

	IF v_source = SOURCE_USER_DEFINED THEN
		IF in_is_standard_audit_entry THEN
			IF v_current_status <> COMPLIANCE_STATUS_DRAFT THEN
				IF in_is_major_change = 0 THEN
					v_new_minor_version := v_current_minor_version + 1;
				ELSE
					v_new_major_version := v_current_major_version + 1;
					v_new_minor_version := 0;
				END IF;
			ELSE
				-- if we're changing status from draft, keep the existing version number
				-- this should be 1.0 as we can't move from published back to
				-- draft
				v_new_major_version := v_current_major_version;
				v_new_minor_version := v_current_minor_version;
			END IF;
		END IF;
	ELSE
		-- Third party provider - use their versioning
		v_new_major_version := in_major_version;
		v_new_minor_version := in_minor_version;
	END IF;

	IF (v_new_major_version != v_current_major_version 
	OR v_new_minor_version != v_current_minor_version) 
	OR in_is_standard_audit_entry = false THEN 
		INT_UpdateCompItemHist(
			in_compliance_item_id	=>	in_compliance_item_id,
			in_change_type			=>	in_change_type,
			in_major_version		=>	v_new_major_version,
			in_minor_version		=>	v_new_minor_version,
			in_is_major_change		=>	in_is_major_change,
			in_change_reason		=>	in_change_reason,
			in_lang_id				=>	53 -- default english basedata id
		);
	END IF;

	out_new_major_version := v_new_major_version;
	out_new_minor_version := v_new_minor_version;
END;

PROCEDURE INTERNAL_UpdateComplianceItem(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_change_reason				IN  compliance_item_version_log.description%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	in_lang_id						IN  compliance_language.lang_id%TYPE DEFAULT NULL
)
AS
	v_new_major_version				csr.compliance_item.major_version%TYPE;
	v_new_minor_version				csr.compliance_item.minor_version%TYPE;
	v_adjusted_ref_code				compliance_item.reference_code%TYPE;
	v_lang_id		compliance_language.lang_id%TYPE;
BEGIN
	SELECT major_version, minor_version
	  INTO v_new_major_version, v_new_minor_version
	  FROM compliance_item
	 WHERE compliance_item_id = in_compliance_item_id;

	-- A subsequent call to publish will deal with versioning in this case.
	IF in_is_first_publication = 0 THEN
		-- Security asserted by externally facing procedures
		INTERNAL_UpdateVersionNumber(
			in_compliance_item_id 	=> in_compliance_item_id,
			in_change_reason		=> in_change_reason,
			in_change_type			=> in_change_type,
			in_major_version		=> in_major_version,
			in_minor_version		=> in_minor_version,
			in_is_major_change		=> in_is_major_change,
			in_status_id			=> in_status_id,
			out_new_major_version	=> v_new_major_version,
			out_new_minor_version 	=> v_new_minor_version
		);

		INT_UpdateCompItemDescHist(
			in_compliance_item_id			=>	in_compliance_item_id,
			in_lang_id						=>	in_lang_id,
			in_major_version				=>	v_new_major_version,
			in_minor_version				=>	v_new_minor_version,
			in_title						=>	in_title,
			in_summary						=>	in_summary,
			in_details						=>	in_details,
			in_citation						=>	in_citation,
			in_description					=>	in_change_reason,
			in_change_dtm					=>	SYSDATE
		);

	END IF;

	v_adjusted_ref_code := INTERNAL_ConvertReferenceCode(in_reference_code);

	UPDATE compliance_item
	   SET title = TRIM(in_title),
		   summary = in_summary,
		   details = in_details,
		   source = in_source,
		   reference_code = v_adjusted_ref_code,
		   user_comment = in_user_comment,
		   citation = in_citation,
		   external_link = in_external_link,
		   updated_dtm = SYSDATE,
		   major_version = v_new_major_version,
		   minor_version = v_new_minor_version,
		   lookup_key = in_lookup_key
	 WHERE app_sid = security_pkg.GetApp
	   AND compliance_item_id = in_compliance_item_id;

	UPDATE compliance_item_description
	   SET title = TRIM(in_title),
		   summary = in_summary,
		   details = in_details,
		   citation = in_citation
	 WHERE app_sid = security_pkg.GetApp
	   AND lang_id = NVL(in_lang_id, 53)
	   AND compliance_item_id = in_compliance_item_id;

	IF in_is_major_change = 1 THEN
		FOR item IN (SELECT cir.flow_item_id
					   FROM csr.compliance_item_region cir
					   JOIN flow_item fi
						 ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
					   JOIN flow f
					     ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
					  WHERE compliance_item_id = in_compliance_item_id)
		LOOP
			INTERNAL_TransitionToUpdated(
				in_flow_item_id		=> item.flow_item_id,
				in_compliance_item_id => in_compliance_item_id,
				in_comment			=> 'Compliance library item updated'
			);
		END LOOP;
	END IF;
END;

PROCEDURE UpdateRegulation(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_adoption_dtm					IN  csr.compliance_regulation.adoption_dtm%TYPE,
	in_external_id					IN  csr.compliance_regulation.external_id%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN  compliance_item_version_log.description%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	in_is_policy					IN	csr.compliance_regulation.is_policy%TYPE DEFAULT 0
)
AS
BEGIN
	AssertComplianceMgr();

	UPDATE compliance_regulation
	   SET adoption_dtm = in_adoption_dtm,
		   external_id = in_external_id,
		   is_policy = in_is_policy
	 WHERE app_sid = security_pkg.GetApp
	   AND compliance_item_id = in_compliance_item_id;

	INTERNAL_UpdateComplianceItem(
		in_compliance_item_id 	=> in_compliance_item_id,
		in_title				=> in_title,
		in_summary				=> in_summary,
		in_details				=> in_details,
		in_source				=> in_source,
		in_reference_code		=> in_reference_code,
		in_user_comment			=> in_user_comment,
		in_citation				=> in_citation,
		in_external_link		=> in_external_link,
		in_change_reason		=> in_change_reason,
		in_change_type			=> in_change_type,
		in_is_major_change		=> in_is_major_change,
		in_status_id			=> in_status_id,
		in_lookup_key			=> in_lookup_key,
		in_major_version		=> in_major_version,
		in_minor_version		=> in_minor_version,
		in_is_first_publication => in_is_first_publication
	);

	IF in_status_id = COMPLIANCE_STATUS_PUBLISHED AND in_is_first_publication = 0 THEN
		PublishComplianceItem(in_compliance_item_id);
	END IF;
END;

PROCEDURE UpdatePermitCondition(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_condition_type_id			IN	compliance_permit_condition.condition_type_id%TYPE,
	in_condition_sub_type_id		IN	compliance_permit_condition.condition_sub_type_id%TYPE,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN	compliance_item_version_log.description%TYPE,
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE
)
AS
BEGIN
	AssertComplianceMgr();

	UPDATE compliance_permit_condition
	   SET condition_type_id = in_condition_type_id,
		   condition_sub_type_id = in_condition_sub_type_id
	 WHERE app_sid = security_pkg.GetApp
	   AND compliance_item_id = in_compliance_item_id;

	INTERNAL_UpdateComplianceItem(
		in_compliance_item_id 	=> in_compliance_item_id,
		in_title				=> in_title,
		in_summary				=> NULL,
		in_details				=> in_details,
		in_source				=> 0,
		in_reference_code		=> in_reference_code,
		in_user_comment			=> NULL,
		in_citation				=> NULL,
		in_external_link		=> NULL,
		in_change_reason		=> in_change_reason,
		in_change_type			=> in_change_type,
		in_is_major_change		=> in_is_major_change,
		in_status_id			=> COMPLIANCE_STATUS_PUBLISHED,
		in_lookup_key			=> NULL,
		in_major_version		=> 1,
		in_minor_version		=> 0,
		in_is_first_publication => 0
	);

	IF in_is_major_change = 1 THEN
		INTERNAL_AddAuditLogEntry(
			in_flow_item_id		=> in_flow_item_id,
			in_description		=> 'Condition updated (major change)',
			in_comment_text		=> in_change_reason
		);
	ELSE
		INTERNAL_AddAuditLogEntry(
			in_flow_item_id		=> in_flow_item_id,
			in_description		=> 'Condition updated',
			in_comment_text		=> in_change_reason
		);
	END IF;
END;

PROCEDURE UpdateRequirement(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN  compliance_item_version_log	.description%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_is_first_publication			IN  NUMBER DEFAULT 0
)
AS
BEGIN
	AssertComplianceMgr();

	INTERNAL_UpdateComplianceItem(
		in_compliance_item_id 	=> in_compliance_item_id,
		in_title				=> in_title,
		in_summary				=> in_summary,
		in_details				=> in_details,
		in_source				=> in_source,
		in_reference_code		=> in_reference_code,
		in_user_comment			=> in_user_comment,
		in_citation				=> in_citation,
		in_external_link		=> in_external_link,
		in_change_reason		=> in_change_reason,
		in_change_type			=> in_change_type,
		in_is_major_change		=> in_is_major_change,
		in_status_id			=> in_status_id,
		in_lookup_key			=> in_lookup_key,
		in_major_version		=> in_major_version,
		in_minor_version		=> in_minor_version,
		in_is_first_publication	=> in_is_first_publication
	);

	IF in_status_id = COMPLIANCE_STATUS_PUBLISHED AND in_is_first_publication = 0 THEN
		PublishComplianceItem(in_compliance_item_id);
	END IF;
END;

PROCEDURE GetComplianceItemHistory(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_compliance_lang				IN  VARCHAR2,
	in_sort_by						IN  VARCHAR2,
	in_sort_dir						IN  VARCHAR2,
	in_row_count					IN  NUMBER,
	in_start_row					IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR,
	out_total_rows					OUT NUMBER
)
AS
	v_lang_id		compliance_language.lang_id%TYPE;
BEGIN
	INTERNAL_AssertCanReadCompItem(in_compliance_item_id);

	SELECT lang_id
	  INTO v_lang_id
	  FROM aspen2.lang l
	 WHERE l.lang = in_compliance_lang;

	IF in_sort_by = 'version' THEN
		OPEN out_cur FOR
			-- to be ordered by the numeric version fields
			SELECT items.compliance_item_id, items.compliance_item_version_log_id, items.major_version, items.minor_version,
				items.description, items.is_major_change, items.change_dtm, "change_type_Description" as "change_type"
			FROM (
				SELECT civl.compliance_item_id, civl.compliance_item_version_log_id,  civl.major_version, civl.minor_version,
					civl.description, civl.is_major_change, civl.change_dtm,  cict.description as "change_type_Description",
					row_number() OVER (ORDER BY
							CASE WHEN in_sort_dir = 'DESC' THEN civl.major_version END DESC,
							CASE WHEN in_sort_dir = 'DESC' THEN civl.minor_version END DESC,
							CASE WHEN in_sort_dir = 'ASC' THEN civl.major_version END ASC,
							CASE WHEN in_sort_dir = 'ASC' THEN civl.minor_version END ASC
						) rn
				  FROM compliance_item_version_log civl
				  JOIN compliance_item_change_type cict ON civl.change_type = cict.compliance_item_change_type_id
				  JOIN compliance_item_description cid ON civl.compliance_item_id = cid.compliance_item_id AND cid.lang_id = v_lang_id
				 WHERE civl.compliance_item_id = in_compliance_item_id
				   AND NVL(civl.lang_id, 53) = v_lang_id) items
				WHERE rn-1 BETWEEN in_start_row AND in_start_row + in_row_count - 1
			ORDER BY rn;
	ELSE
		OPEN out_cur FOR
			--to be ordered by the string fields (or fields that can be sensibly converted to a sortable string)
			SELECT items.compliance_item_id, items.compliance_item_version_log_id, items.major_version, items.minor_version,
				   items.description, items.is_major_change, items.change_dtm, "change_type_Description" as "change_type"
			  FROM (
				SELECT civl.compliance_item_id, civl.compliance_item_version_log_id,  civl.major_version, civl.minor_version,
					civl.description, civl.is_major_change, civl.change_dtm, cict.description as "change_type_Description",
					row_number() OVER (ORDER BY
							CASE
								WHEN in_sort_by='changeReason' AND in_sort_dir = 'DESC' THEN LOWER(cast(civl.description as varchar2(4000)))
								WHEN in_sort_by='changeDate' AND in_sort_dir = 'DESC' THEN TO_CHAR(civl.change_dtm, 'YYYY-MM-DDHH24:MI:SS')
								WHEN in_sort_by='isMajorChange' AND in_sort_dir = 'DESC' THEN TO_CHAR(civl.is_major_change)
								WHEN in_sort_by='changeType' AND in_sort_dir = 'DESC' THEN TO_CHAR(cict.description)
							END DESC,
							CASE
								WHEN in_sort_by='changeReason' AND in_sort_dir = 'ASC' THEN LOWER(cast(civl.description as varchar2(4000)))
								WHEN in_sort_by='changeDate' AND in_sort_dir = 'ASC' THEN TO_CHAR(civl.change_dtm, 'YYYY-MM-DDHH24:MI:SS')
								WHEN in_sort_by='isMajorChange' AND in_sort_dir = 'ASC' THEN TO_CHAR(civl.is_major_change)
								WHEN in_sort_by='changeType' AND in_sort_dir = 'ASC' THEN TO_CHAR(cict.description)
							END ASC
						) rn
				  FROM compliance_item_version_log  civl
				  JOIN compliance_item_change_type cict ON civl.change_type = cict.compliance_item_change_type_id
				  JOIN compliance_item_description cid ON civl.compliance_item_id = cid.compliance_item_id AND cid.lang_id = v_lang_id
				 WHERE civl.compliance_item_id = in_compliance_item_id
				   AND NVL(civl.lang_id, 53) = v_lang_id) items
				WHERE rn-1 BETWEEN in_start_row AND in_start_row + in_row_count - 1
			ORDER BY rn;
	END IF;

	SELECT COUNT(1)
	  INTO out_total_rows
	  FROM compliance_item_version_log  civl
	 WHERE compliance_item_id = in_compliance_item_id
	   AND NVL(lang_id, 53) = v_lang_id;
END;

FUNCTION INTERNAL_GetCompItemClass(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE
)
RETURN NUMBER
AS
	v_item_type 					NUMBER(2);
BEGIN
	SELECT ci.compliance_item_type
	  INTO v_item_type
	  FROM compliance_item ci
	 WHERE ci.compliance_item_id = in_compliance_item_id;

	return v_item_type;
END;

--No security check. Only used by batch job import session.
PROCEDURE GetComplianceItemData(
	in_compliance_item_id		IN  compliance_item.compliance_item_id%TYPE,
	out_item_type				OUT NUMBER,
	out_compliance_item			OUT SYS_REFCURSOR
)
AS
BEGIN
	out_item_type := INTERNAL_GetCompItemClass(in_compliance_item_id);
	
	IF out_item_type = COMPLIANCE_CONDITION THEN
		GetPermitConditions(
			in_compliance_item_id	=> in_compliance_item_id,
			out_cur 				=> out_compliance_item
		);

		RETURN;
	END IF;
	
	OPEN out_compliance_item FOR
		SELECT ci.compliance_item_id,
			   cid.title,
			   cid.summary,
			   cid.details,
			   ci.source,
			   ci.reference_code,
			   ci.user_comment,
			   cid.citation,
			   ci.external_link,
			   ci.created_dtm,
			   ci.updated_dtm,
			   ci.compliance_item_status_id,
			   ci.major_version,
			   ci.minor_version,
			   ci.lookup_key,
			   ci.compliance_item_type,
			   -- Regulations
			   creg.external_id,
			   creg.adoption_dtm,
			   NVL(creg.is_policy, 0) is_policy,
			   -- Conditions (with permit info)
			   cpc.compliance_permit_id,
			   cpc.condition_type_id,
			   cpc.condition_sub_type_id,
			   -- Status
			   cis.description status_label
		  FROM compliance_item ci
		  JOIN compliance_item_description cid 
		    ON ci.compliance_item_id = cid.compliance_item_id AND cid.app_sid = ci.app_sid
		  JOIN compliance_language cl
		    ON cl.lang_id = cid.lang_id AND ci.app_sid = cid.app_sid
		  --This should go once we are passing the compliance_language selected
		  JOIN aspen2.lang l ON l.lang_id = cl.lang_id AND l.lang = 'en'
		  JOIN compliance_item_status cis ON ci.compliance_item_status_id = cis.compliance_item_status_id
		  LEFT JOIN compliance_regulation creg
			ON ci.compliance_item_id = creg.compliance_item_id AND ci.app_sid = creg.app_sid
		  LEFT JOIN compliance_permit_condition cpc
			ON ci.compliance_item_id = cpc.compliance_item_id AND ci.app_sid = cpc.app_sid
		 WHERE ci.compliance_item_id = in_compliance_item_id;
END;

PROCEDURE GetComplianceItem(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_lang							IN	VARCHAR2,
	out_item_type					OUT NUMBER,
	out_compliance_item				OUT SYS_REFCURSOR,
	out_rollout_info				OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_child_items					OUT SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_AssertCanReadCompItem(in_compliance_item_id);

	out_item_type := INTERNAL_GetCompItemClass(in_compliance_item_id);

	IF out_item_type = COMPLIANCE_CONDITION THEN
		GetPermitConditions(
			in_compliance_item_id	=> in_compliance_item_id,
			out_cur 				=> out_compliance_item
		);

		RETURN;
	END IF;

	INTERNAL_GetComplianceItems(
		in_compliance_item_id		=> in_compliance_item_id,
		in_lang						=> in_lang,
		out_cur						=> out_compliance_item,
		out_rollout_info			=> out_rollout_info,
		out_langs					=> out_langs
	);

	INTERNAL_GetTags(
		in_compliance_item_id		=> in_compliance_item_id,
		out_cur						=> out_tags
	);

	INTERNAL_GetRegions(
		in_compliance_item_id		=> in_compliance_item_id,
		out_cur						=> out_regions
	);

	INTERNAL_GetComplianceChildren(
		in_compliance_item_id		=> in_compliance_item_id,
		in_compliance_item_type		=> out_item_type,
		out_cur						=> out_child_items
	);
END;

PROCEDURE GetPermitConditions(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE DEFAULT NULL,
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE DEFAULT NULL,
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Flow permission checks done in query.

	OPEN out_cur FOR
		SELECT ci.compliance_item_id,
			   cid.title,
			   cid.summary,
			   cid.details,
			   ci.source,
			   ci.reference_code,
			   ci.user_comment,
			   cid.citation,
			   ci.external_link,
			   ci.created_dtm,
			   ci.updated_dtm,
			   ci.compliance_item_status_id,
			   ci.major_version,
			   ci.minor_version,
			   ci.lookup_key,
			   COMPLIANCE_CONDITION compliance_item_type,
			   cpc.compliance_permit_id,
			   cpc.condition_type_id,
			   cpc.condition_sub_type_id,
			   cp.activity_start_dtm,
			   cp.activity_end_dtm,
   			   cp.activity_type_id,
			   cp.activity_sub_type_id,
			   cp.permit_start_dtm,
			   cp.permit_end_dtm,
			   cp.permit_type_id,
			   cp.permit_sub_type_id,
			   cp.title permit_title,
			   cp.permit_reference,
			   cat.description activity_type_desc,
			   casbt.description activity_sub_type_desc,
			   cct.description condition_type_desc,
			   ccst.description condition_sub_type_desc,
			   cpt.description permit_type_desc,
			   cpst.description permit_sub_type_desc,
			   cir.flow_item_id,
			   fs.state_colour flow_state_colour,
			   fs.pos flow_state_pos,
			   fs.flow_state_nature_id,
			   r.name region,
			   -- Status
			   cis.description status_label
		  FROM compliance_item ci
		  JOIN compliance_item_description cid 
		    ON ci.compliance_item_id = cid.compliance_item_id AND cid.app_sid = ci.app_sid
		  JOIN compliance_language cl
		    ON cl.lang_id = cid.lang_id AND ci.app_sid = cid.app_sid
		  --This should go once we are passing the compliance_language selected
		  JOIN aspen2.lang l ON l.lang_id = cl.lang_id AND l.lang = 'en'
		  JOIN compliance_item_status cis
		    ON ci.compliance_item_status_id = cis.compliance_item_status_id
		  LEFT JOIN compliance_permit_condition cpc
			ON ci.compliance_item_id = cpc.compliance_item_id AND ci.app_sid = cpc.app_sid
		  JOIN compliance_condition_type cct
		  	ON cpc.condition_type_id = cct.condition_type_id
		  LEFT JOIN compliance_condition_sub_type ccst
		  	ON cpc.condition_type_id = ccst.condition_type_id and cpc.condition_sub_type_id = ccst.condition_sub_type_id
		  JOIN compliance_permit cp
		    ON cpc.compliance_permit_id = cp.compliance_permit_id AND cpc.app_sid = cp.app_sid
		  JOIN compliance_activity_type cat
		    ON cp.activity_type_id = cat.activity_type_id
		  LEFT JOIN compliance_activity_sub_type casbt
		    ON cp.activity_type_id = casbt.activity_type_id AND cp.activity_sub_type_id = casbt.activity_sub_type_id
		  JOIN compliance_permit_type cpt
		    ON cp.permit_type_id = cpt.permit_type_id
		  LEFT JOIN compliance_permit_sub_type cpst
		    ON cp.permit_type_id = cpst.permit_type_id AND cp.permit_sub_type_id = cpst.permit_sub_type_id
		  JOIN compliance_item_region cir
			ON cpc.compliance_item_id = cir.compliance_item_id and cp.app_sid = cir.app_sid
		  JOIN region r
			ON cp.Region_sid = r.region_sid
		  JOIN flow_item fi
		    ON cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs
		    ON fi.current_state_id = fs.flow_state_id
		 WHERE (in_permit_id IS NULL OR cp.compliance_permit_id = in_permit_id)
		   AND (in_flow_item_id IS NULL OR cir.flow_item_id = in_flow_item_id)
		   AND (in_compliance_item_id IS NULL OR ci.compliance_item_id = in_compliance_item_id)
		   AND (EXISTS (
				SELECT 1
				  FROM region_role_member rrm
				  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				 WHERE rrm.app_sid = cir.app_sid
				   AND rrm.region_sid = cir.region_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
				   AND fsr.flow_state_id = fi.current_state_id
			)
			OR EXISTS (
				SELECT 1
				  FROM flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND fsr.flow_state_id = fi.current_state_id
			))
		 ORDER BY fs.pos, ci.title ASC;
END;

PROCEDURE GetAllPermitConditions(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Flow permission checks done in query.

	OPEN out_cur FOR
		SELECT ci.title "Condition Title",
			   ci.details "Details",
			   cp.permit_reference "Permit Reference",
			   ci.reference_code "Condition Reference",
			   cct.description "Condition Type",
			   ccst.description "Condition Subtype",
			   fs.lookup_key "Workflow State"
		  FROM compliance_item ci
		  JOIN compliance_item_status cis
		    ON ci.compliance_item_status_id = cis.compliance_item_status_id
		  JOIN compliance_permit_condition cpc
			ON ci.compliance_item_id = cpc.compliance_item_id AND ci.app_sid = cpc.app_sid
		  JOIN compliance_condition_type cct
		  	ON cpc.condition_type_id = cct.condition_type_id
		  LEFT JOIN compliance_condition_sub_type ccst
		  	ON cpc.condition_type_id = ccst.condition_type_id and cpc.condition_sub_type_id = ccst.condition_sub_type_id
		  JOIN compliance_permit cp
		    ON cpc.compliance_permit_id = cp.compliance_permit_id AND cpc.app_sid = cp.app_sid
		  JOIN compliance_item_region cir
			ON cpc.compliance_item_id = cir.compliance_item_id and cp.app_sid = cir.app_sid
		  JOIN flow_item fi
		    ON cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs
		    ON fi.current_state_id = fs.flow_state_id
			WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cir.app_sid
					   AND rrm.region_sid = cir.region_sid
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
 					   AND fsr.is_editable = 1
					)
				);
END;

PROCEDURE GetNonCompliantCondsForUser(
	in_search						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total						OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_search						VARCHAR2(1024) := in_search;
BEGIN
	IF v_search IS NOT NULL THEN
		v_search := REPLACE(v_search, '\', '\\');		-- '
		v_search := REPLACE(v_search, '_', '\_');
		v_search := REPLACE(v_search, '%', '\%');
		v_search := '%' || LOWER(in_search) || '%';
	END IF;

	SELECT COUNT(*)
	  INTO out_total
	  FROM compliance_item_region cir
	  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
	  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
	  JOIN compliance_item ci
		ON cir.app_sid = ci.app_sid
	   AND cir.compliance_item_id = ci.compliance_item_id
	  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
	  LEFT JOIN compliance_item_rollout cr
		ON cr.app_sid = ci.app_sid
	   AND cr.compliance_item_id = ci.compliance_item_id
	  LEFT JOIN postcode.country pc ON cr.country = pc.country
	  LEFT JOIN postcode.region	pr ON cr.region = pr.region
	  LEFT JOIN country_group cg ON cg.country_group_id = cr.country_group
	  LEFT JOIN region_group rg ON rg.region_group_id = cr.region_group
	  JOIN compliance_permit_condition cpc
		ON ci.compliance_item_id = cpc.compliance_item_id
	   AND ci.app_sid = cpc.app_sid
	  JOIN compliance_condition_type cct
	    ON cpc.condition_type_id = cct.condition_type_id
	  JOIN compliance_permit cp
		ON cp.compliance_permit_id = cpc.compliance_permit_id
	   AND cp.app_sid = cpc.app_sid
	 WHERE (EXISTS (
				SELECT NULL
				  FROM region_role_member rrm
				  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				 WHERE rrm.app_sid = cir.app_sid
				   AND rrm.region_sid = cir.region_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
				   AND fsr.flow_state_id = fi.current_state_id
				)
			OR EXISTS (
				SELECT NULL
				  FROM flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND fsr.flow_state_id = fi.current_state_id
				   AND fsr.app_sid = cir.app_sid
				)
			)
	   AND ( fs.flow_state_nature_id IS NULL
	   			OR fs.flow_state_nature_id not in (csr_data_pkg.NATURE_CONDIT_INACTIVE, csr_data_pkg.NATURE_CONDIT_COMPLIANT)  )
	   AND (v_search IS NULL
	   			OR LOWER(cct.description) LIKE v_search ESCAPE '\'
				OR LOWER(fs.label) LIKE v_search ESCAPE '\'
				OR LOWER(ci.title) LIKE v_search ESCAPE '\'
				OR LOWER(ci.user_comment) LIKE v_search ESCAPE '\'
				OR LOWER(r.description) LIKE v_search ESCAPE '\'
				OR LOWER(ci.reference_code) LIKE v_search ESCAPE '\'
				OR LOWER(ci.citation) LIKE v_search ESCAPE '\'
				OR LOWER(cg.group_name) LIKE v_search ESCAPE '\'
				OR LOWER(rg.group_name) LIKE v_search ESCAPE '\'
				OR LOWER(pc.name) LIKE v_search ESCAPE '\'
				OR LOWER(pr.name) LIKE v_search  ESCAPE '\'
				OR LOWER(fs.label) LIKE v_search  ESCAPE '\'			-- '
		   );

	OPEN out_cur FOR
		WITH records AS (
			SELECT ci.compliance_item_id,
				   ci.compliance_item_status_id,
				   ci.title,
				   ci.updated_dtm,
				   r.description region_description,
				   NVL(i.open_issues, 0) open_issues,
				   ci.reference_code,
				   ci.citation,
				   cg.group_name country_group_name,
				   rg.group_name region_group_name,
				   pc.name country_name,
				   pr.name region_name,
				   fs.label flow_state_label,
				   fs.state_colour flow_state_colour,
				   cir.flow_item_id,
				   cct.description condition_type_description,
				   cp.permit_start_dtm
			  FROM compliance_item_region cir
			  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
			  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
			  JOIN compliance_item ci
				ON cir.app_sid = ci.app_sid
			   AND cir.compliance_item_id = ci.compliance_item_id
			  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
			  JOIN compliance_permit_condition cpc
				ON ci.compliance_item_id = cpc.compliance_item_id
			   AND ci.app_sid = cpc.app_sid
			  JOIN compliance_condition_type cct
			    ON cpc.condition_type_id = cct.condition_type_id
			  JOIN compliance_permit cp
				ON cp.compliance_permit_id = cpc.compliance_permit_id
			   AND cp.app_sid = cpc.app_sid
			  LEFT JOIN compliance_item_rollout cr
				ON cr.app_sid = ci.app_sid
			   AND cr.compliance_item_id = ci.compliance_item_id
			  LEFT JOIN postcode.country pc ON cr.country = pc.country
			  LEFT JOIN postcode.region	pr ON cr.region = pr.region
			  LEFT JOIN country_group cg ON cg.country_group_id = cr.country_group
			  LEFT JOIN region_group rg ON rg.region_group_id = cr.region_group
			  LEFT JOIN (
					SELECT icr.app_sid,
						   icr.flow_item_id,
						   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
								THEN i.issue_id
							END) open_issues
					  FROM issue_compliance_region icr
					  JOIN issue i
							ON icr.app_sid = i.app_sid
						   AND icr.issue_compliance_region_id = i.issue_compliance_region_id
					 WHERE i.deleted = 0
					 GROUP BY icr.app_sid, icr.flow_item_id
				   ) i
				   ON i.app_sid = cir.app_sid AND i.flow_item_id = cir.flow_item_id
			 WHERE (EXISTS (
						SELECT NULL
						  FROM region_role_member rrm
						  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
						 WHERE rrm.app_sid = cir.app_sid
						   AND rrm.region_sid = cir.region_sid
						   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   AND fsr.flow_state_id = fi.current_state_id
						)
					OR EXISTS (
						SELECT NULL
						  FROM flow_state_role fsr
						  JOIN security.act act ON act.sid_id = fsr.group_sid
						 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						   AND fsr.flow_state_id = fi.current_state_id
						   AND fsr.app_sid = cir.app_sid
						)
					)
			   AND (fs.flow_state_nature_id IS NULL
			   		OR fs.flow_state_nature_id not in (csr_data_pkg.NATURE_CONDIT_INACTIVE, csr_data_pkg.NATURE_CONDIT_COMPLIANT)
				   )
			   AND (v_search IS NULL
			   		OR LOWER(cct.description) LIKE v_search
					OR LOWER(fs.label) LIKE v_search
					OR LOWER(ci.title) LIKE v_search
					OR LOWER(ci.user_comment) LIKE v_search
					OR LOWER(r.description) LIKE v_search
					OR LOWER(ci.reference_code) LIKE v_search
					OR LOWER(ci.citation) LIKE v_search
					OR LOWER(cg.group_name) LIKE v_search
					OR LOWER(rg.group_name) LIKE v_search
					OR LOWER(pc.name) LIKE v_search
					OR LOWER(pr.name) LIKE v_search
					OR LOWER(fs.label) LIKE v_search
				   )
				ORDER BY
					permit_start_dtm ASC NULLS LAST,
					reference_code ASC
					)
		SELECT *
		  FROM (SELECT records.*, ROWNUM rn
				  FROM records
				 WHERE ROWNUM < in_start_row + in_page_size)
		 WHERE rn >= in_start_row;
END;

PROCEDURE GetNonCompliantItemsForUser(
	in_search						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total						OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_search						VARCHAR2(1024) := in_search;
BEGIN
	IF v_search IS NOT NULL THEN
		v_search := REPLACE(v_search, '\', '\\'); -- '
		v_search := REPLACE(v_search, '_', '\_');
		v_search := REPLACE(v_search, '%', '\%');
		v_search := '%' || LOWER(in_search) || '%';
	END IF;

	SELECT COUNT(*)
	  INTO out_total
	  FROM compliance_item_region cir
	  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
	  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
	  JOIN compliance_item ci
		ON cir.app_sid = ci.app_sid
	   AND cir.compliance_item_id = ci.compliance_item_id
	  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
	  LEFT JOIN compliance_item_rollout cr
		ON cr.app_sid = ci.app_sid
	   AND cr.compliance_item_id = ci.compliance_item_id
	  LEFT JOIN postcode.country pc ON cr.country = pc.country
	  LEFT JOIN postcode.region	pr ON cr.region = pr.region
	  LEFT JOIN country_group cg ON cg.country_group_id = cr.country_group
	  LEFT JOIN region_group rg ON rg.region_group_id = cr.region_group
	 WHERE (EXISTS (
				SELECT NULL
				  FROM region_role_member rrm
				  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				 WHERE rrm.app_sid = cir.app_sid
				   AND rrm.region_sid = cir.region_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
				   AND fsr.flow_state_id = fi.current_state_id
			)
			OR EXISTS (
				SELECT NULL
				  FROM flow_state_role fsr
				  JOIN security.act act ON act.sid_id = fsr.group_sid
				 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
				   AND fsr.flow_state_id = fi.current_state_id
				   AND fsr.app_sid = cir.app_sid

			))
	   -- Filter out compliant, retired, or not applicable items. Oracle tends to generate
	   -- a completely insane plan if we use the more obvious "NOT IN" expression.
	   AND (
			fs.flow_state_nature_id IS NULL OR fs.flow_state_nature_id IN (
				csr_data_pkg.NATURE_REGULATION_NEW,
				csr_data_pkg.NATURE_REGULATION_UPDATED,
				csr_data_pkg.NATURE_REGULATION_ACTION_REQ,
				csr_data_pkg.NATURE_REQUIREMENT_NEW,
				csr_data_pkg.NATURE_REQUIREMENT_UPDATED,
				csr_data_pkg.NATURE_REQUIREMENT_ACTION_REQ
			)
		   )
	   AND (v_search IS NULL
			OR LOWER(ci.title) LIKE v_search ESCAPE '\'
			OR LOWER(ci.user_comment) LIKE v_search ESCAPE '\'
			OR LOWER(r.description) LIKE v_search ESCAPE '\'
			OR LOWER(ci.reference_code) LIKE v_search ESCAPE '\'
			OR LOWER(ci.citation) LIKE v_search ESCAPE '\'
			OR LOWER(cg.group_name) LIKE v_search ESCAPE '\'
			OR LOWER(rg.group_name) LIKE v_search ESCAPE '\'
			OR LOWER(pc.name) LIKE v_search ESCAPE '\'
			OR LOWER(pr.name) LIKE v_search  ESCAPE '\'
			OR LOWER(fs.label) LIKE v_search  ESCAPE '\'	-- '
		   );

	OPEN out_cur FOR
		WITH records AS (
			SELECT ci.compliance_item_id,
				   CASE
					 WHEN creq.compliance_item_id IS NOT NULL THEN COMPLIANCE_REQUIREMENT
					 WHEN creg.compliance_item_id IS NOT NULL THEN COMPLIANCE_REGULATION
					 WHEN cpc.compliance_item_id IS NOT NULL THEN COMPLIANCE_CONDITION
				   END compliance_item_type,
				   creg.is_policy,
				   ci.compliance_item_status_id,
				   ci.title,
				   ci.user_comment,
				   ci.updated_dtm,
				   creg.adoption_dtm,
				   r.description region_description,
				   NVL(i.open_issues, 0) open_issues,
				   CASE WHEN creg.compliance_item_id IS NOT NULL
					   THEN NVL(req.open_requirements, 0)
				   END open_requirements,
				   ci.reference_code,
				   ci.citation,
				   cirl.country_group_names country_group_name,
				   cirl.region_group_names region_group_name,
				   cirl.countries country_name,
				   cirl.regions region_name,
				   fs.label flow_state_label,
				   fs.state_colour flow_state_colour,
				   cir.flow_item_id
			  FROM compliance_item_region cir
			  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
			  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
			  JOIN compliance_item ci ON cir.app_sid = ci.app_sid AND cir.compliance_item_id = ci.compliance_item_id
			  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
			  LEFT JOIN compliance_requirement creq ON ci.compliance_item_id = creq.compliance_item_id AND ci.app_sid = creq.app_sid
			  LEFT JOIN compliance_regulation creg ON ci.compliance_item_id = creg.compliance_item_id AND ci.app_sid = creg.app_sid
			  LEFT JOIN compliance_permit_condition cpc ON ci.compliance_item_id = cpc.compliance_item_id AND ci.app_sid = cpc.app_sid
			  LEFT JOIN v$comp_item_rollout_location cirl ON ci.app_sid = cirl.app_sid AND ci.compliance_item_id = cirl.compliance_item_id
			  LEFT JOIN (
					SELECT icr.app_sid,
						   icr.flow_item_id,
						   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
								THEN i.issue_id
							END) open_issues
					  FROM issue_compliance_region icr
					  JOIN issue i
							ON icr.app_sid = i.app_sid
						   AND icr.issue_compliance_region_id = i.issue_compliance_region_id
					 WHERE i.deleted = 0
					 GROUP BY icr.app_sid, icr.flow_item_id
				   ) i
				   ON i.app_sid = cir.app_sid AND i.flow_item_id = cir.flow_item_id
			  LEFT JOIN (
					SELECT crr.app_sid,
						   crr.regulation_id, ccir.region_sid,
						   COUNT(CASE WHEN fs.flow_state_nature_id NOT IN (
									csr_data_pkg.NATURE_REQUIREMENT_NA,
									csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT,
									csr_data_pkg.NATURE_REQUIREMENT_RETIRED)
								THEN fi.flow_item_id
						   END) open_requirements
					  FROM compliance_req_reg crr
					  JOIN compliance_item_region ccir ON ccir.app_sid = crr.app_sid AND ccir.compliance_item_id = crr.requirement_id
					  JOIN flow_item fi ON ccir.app_sid = fi.app_sid AND ccir.flow_item_id = fi.flow_item_id
					  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
					 GROUP BY crr.app_sid, crr.regulation_id, ccir.region_sid
				   ) req
				   ON cir.compliance_item_id = req.regulation_id AND cir.app_sid = req.app_sid AND cir.region_sid = req.region_sid
			 WHERE (EXISTS (
						SELECT NULL
						  FROM region_role_member rrm
						  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
						 WHERE rrm.app_sid = cir.app_sid
						   AND rrm.region_sid = cir.region_sid
						   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   AND fsr.flow_state_id = fi.current_state_id
					)
					OR EXISTS (
						SELECT NULL
						  FROM flow_state_role fsr
						  JOIN security.act act ON act.sid_id = fsr.group_sid
						 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						   AND fsr.flow_state_id = fi.current_state_id
						   AND fsr.app_sid = cir.app_sid

					))
			   -- Filter out compliant, retired, or not applicable items. Oracle tends to generate
			   -- a completely insane plan if we use the more obvious "NOT IN" expression.
			   AND (
					fs.flow_state_nature_id IS NULL OR fs.flow_state_nature_id IN (
						csr_data_pkg.NATURE_REGULATION_NEW,
						csr_data_pkg.NATURE_REGULATION_UPDATED,
						csr_data_pkg.NATURE_REGULATION_ACTION_REQ,
						csr_data_pkg.NATURE_REQUIREMENT_NEW,
						csr_data_pkg.NATURE_REQUIREMENT_UPDATED,
						csr_data_pkg.NATURE_REQUIREMENT_ACTION_REQ
					 )
					)
			   AND (v_search IS NULL
					OR LOWER(ci.title) LIKE v_search ESCAPE '\'
					OR LOWER(ci.user_comment) LIKE v_search ESCAPE '\'
					OR LOWER(r.description) LIKE v_search ESCAPE '\'
					OR LOWER(ci.reference_code) LIKE v_search ESCAPE '\'
					OR LOWER(ci.citation) LIKE v_search ESCAPE '\'
					OR LOWER(cirl.country_group_names) LIKE v_search ESCAPE '\'
					OR LOWER(cirl.region_group_names) LIKE v_search ESCAPE '\'
					OR LOWER(cirl.countries) LIKE v_search ESCAPE '\'
					OR LOWER(cirl.regions) LIKE v_search  ESCAPE '\'
					OR LOWER(fs.label) LIKE v_search  ESCAPE '\'	-- '
				   )
				ORDER BY
					CASE
						WHEN creg.compliance_item_id IS NOT NULL THEN 0
						WHEN creq.compliance_item_id IS NOT NULL THEN 1
						WHEN cpc.compliance_item_id IS NOT NULL THEN 2
					END,
					adoption_dtm ASC NULLS FIRST,
					region_description ASC,
					title ASC)
		SELECT *
		  FROM (SELECT records.*, ROWNUM rn
				  FROM records
				 WHERE ROWNUM < in_start_row + in_page_size)
		 WHERE rn >= in_start_row;
END;

PROCEDURE GetComplianceItemByRef(
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_lang							IN	VARCHAR2 DEFAULT 'en',
	out_item_type					OUT NUMBER,
	out_compliance_item				OUT SYS_REFCURSOR,
	out_rollout_info				OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_child_items					OUT SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
)
AS
	v_compliance_item_id			compliance_item.compliance_item_id%TYPE;
	v_reference_code				compliance_item.reference_code%TYPE;
BEGIN
	v_reference_code := INTERNAL_ConvertReferenceCode(in_reference_code);

	BEGIN
		SELECT compliance_item_id
		  INTO v_compliance_item_id
		  FROM compliance_item
		 WHERE reference_code = v_reference_code;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;

	GetComplianceItem(
		in_compliance_item_id		=> v_compliance_item_id,
		in_lang						=> in_lang,
		out_item_type				=> out_item_type,
		out_compliance_item			=> out_compliance_item,
		out_rollout_info			=> out_rollout_info,
		out_tags					=> out_tags,
		out_regions					=> out_regions,
		out_child_items				=> out_child_items,
		out_langs					=> out_langs
	);
END;


PROCEDURE GetRegionComplianceItem(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_lang							IN	VARCHAR2,
	out_item_type					OUT NUMBER,
	out_compliance_region			OUT SYS_REFCURSOR,
	out_compliance_item				OUT SYS_REFCURSOR,
	out_rollout_info				OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_child_items					OUT SYS_REFCURSOR,
	out_child_reqs					OUT SYS_REFCURSOR,
	out_parent_reg					OUT SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
)
AS
	v_compliance_item_id			compliance_item.compliance_item_id%TYPE default null;
	v_is_condition					NUMBER;
BEGIN
	INTERNAL_AssertFlowAccess(in_flow_item_id);

	SELECT compliance_item_id
	  INTO v_compliance_item_id
	  FROM compliance_item_region
	 WHERE flow_item_id = in_flow_item_id;

	SELECT MIN(compliance_item_id)
	  INTO v_is_condition
	  FROM compliance_permit_condition
	 WHERE compliance_item_id = v_compliance_item_id;

	OPEN out_compliance_region FOR
		SELECT cir.compliance_item_id, cir.region_sid, cir.flow_item_id, r.description region_description,
				fs.label flow_state_label, fs.flow_state_nature_id, cir.out_of_scope
		  FROM compliance_item_region cir
		  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid
		  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  WHERE cir.flow_item_id = in_flow_item_id;

	IF v_is_condition IS NOT NULL THEN
		out_item_type := COMPLIANCE_CONDITION;

		GetPermitConditions(
			in_flow_item_id => in_flow_item_id,
			out_cur => out_compliance_item
		);

		RETURN;
	END IF;


	GetComplianceItem(
		in_compliance_item_id		=> v_compliance_item_id,
		in_lang						=> in_lang,
		out_item_type				=> out_item_type,
		out_compliance_item			=> out_compliance_item,
		out_rollout_info			=> out_rollout_info,
		out_tags					=> out_tags,
		out_regions					=> out_regions,
		out_child_items				=> out_child_items,
		out_langs					=> out_langs
	);

	OPEN out_child_reqs FOR
		SELECT cir.compliance_item_id, cir.region_sid, cir.flow_item_id, cir.out_of_scope,
			decode(ci.compliance_item_status_id, COMPLIANCE_STATUS_RETIRED, 1, 0) is_global_retired_child,
		    fs.label flow_state_label, fs.flow_state_nature_id, fs.state_colour flow_state_colour, t.regulation_count
		  FROM compliance_item_region pcir
		  JOIN compliance_req_reg crr ON pcir.compliance_item_id = crr.regulation_id
		  JOIN compliance_item_region cir ON crr.requirement_id = cir.compliance_item_id AND pcir.region_sid = cir.region_sid
		  JOIN compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
		  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  JOIN (SELECT requirement_id, count(*) regulation_count FROM compliance_req_reg GROUP BY requirement_id) t ON t.requirement_id = cir.compliance_item_id 
		 WHERE pcir.flow_item_id = in_flow_item_id
		   AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cir.app_sid
					   AND rrm.region_sid = cir.region_sid
					   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND fsr.flow_state_id = fi.current_state_id
				)
				OR EXISTS (
					SELECT 1
					  FROM flow_state_role fsr
					  JOIN security.act act ON act.sid_id = fsr.group_sid
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					   AND fsr.flow_state_id = fi.current_state_id
				))
		 GROUP BY cir.compliance_item_id, cir.region_sid, cir.flow_item_id, fs.label, fs.flow_state_nature_id, fs.state_colour, cir.out_of_scope, t.regulation_count, ci.compliance_item_status_id;

	OPEN out_parent_reg FOR
		SELECT cir.compliance_item_id, cir.region_sid, cir.flow_item_id,
		       fs.label flow_state_label, fs.flow_state_nature_id, fs.state_colour flow_state_colour, cir.out_of_scope
		  FROM compliance_item_region pcir
		  JOIN compliance_req_reg crr ON pcir.compliance_item_id = crr.requirement_id
		  JOIN compliance_item_region cir ON crr.regulation_id = cir.compliance_item_id AND pcir.region_sid = cir.region_sid
		  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		 WHERE pcir.flow_item_id = in_flow_item_id
		   AND (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cir.app_sid
					   AND rrm.region_sid = cir.region_sid
					   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND fsr.flow_state_id = fi.current_state_id
				)
				OR EXISTS (
					SELECT 1
					  FROM flow_state_role fsr
					  JOIN security.act act ON act.sid_id = fsr.group_sid
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					   AND fsr.flow_state_id = fi.current_state_id
				))
		 GROUP BY cir.compliance_item_id, cir.region_sid, cir.flow_item_id, fs.label, fs.flow_state_nature_id, fs.state_colour, cir.out_of_scope;
END;

PROCEDURE GetComplianceItemTransitions(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_region_sids		security_pkg.T_SID_IDS;
BEGIN
	-- security check covered by GetFlowItemTransitions

	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM compliance_item_region
	 WHERE flow_item_id = in_flow_item_id;

	flow_pkg.GetFlowItemTransitions(
		in_flow_item_id		=> in_flow_item_id,
		in_region_sids		=> v_region_sids,
		out_cur 			=> out_cur
	);
END;

PROCEDURE RunFlowTransition(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_cache_keys					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_still_has_access 			OUT NUMBER
)
AS
	v_flow_state_label				flow_state.label%TYPE;
BEGIN
	INTERNAL_CheckTransitAccess(in_flow_item_id, in_to_state_id);

	flow_pkg.SetItemState(
		in_flow_item_id 	=> in_flow_item_id,
		in_to_state_id 		=> in_to_state_id,
		in_comment_text 	=> in_comment_text,
		in_cache_keys 		=> in_cache_keys
	);

	IF INTERNAL_HasFlowAccess(in_flow_item_id) THEN
		out_still_has_access := 1;
	ELSE
		out_still_has_access := 0;
	END IF;

	SELECT label
	  INTO v_flow_state_label
	  FROM flow_state
	 WHERE flow_state_id = in_to_state_id;
END;


PROCEDURE UNSEC_RunOrForceTransToNature(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_to_nature_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	out_still_has_access 			OUT NUMBER
)
AS
	v_ignore_flow_state_id		flow_state.flow_state_id%TYPE;
BEGIN
	v_ignore_flow_state_id := flow_pkg.TryTransitionToNatureOrForce(
		in_flow_item_id 	=> in_flow_item_id,
		in_to_nature 		=> in_to_nature_id,
		in_comment		 	=> in_comment_text,
		in_user_sid 		=> SYS_CONTEXT('SECURITY', 'SID')
	);

	IF INTERNAL_HasFlowAccess(in_flow_item_id) THEN
		out_still_has_access := 1;
	ELSE
		out_still_has_access := 0;
	END IF;
END;

PROCEDURE GetCountryGroups(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT country_group_id, group_name
		  FROM country_group;
END;

PROCEDURE GetCountryGroupCountries(
	in_group						IN  country_group.country_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT cg.country_group_id,
			   cg.group_name,
			   c.country country_id,
			   c.name country_name
		  FROM country_group_country cgc
		  JOIN country_group cg ON cg.country_group_id = cgc.country_group_id
		  JOIN postcode.country c ON c.country = cgc.country_id
		 WHERE in_group IS NULL
			OR in_group = cgc.country_group_id;
END;

PROCEDURE GetRegionGroups(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT region_group_id, group_name
		  FROM region_group;
END;

PROCEDURE GetRegionGroupsByCountry(
	in_country						IN  region_group_region.country%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT DISTINCT rg.region_group_id, rg.group_name
		  FROM region_group rg
		  JOIN region_group_region rgr ON rg.region_group_id = rgr.region_group_id
		 WHERE rgr.country = in_country
		 ORDER BY rg.group_name;
END;

PROCEDURE GetRegionGroupRegions(
	in_group						IN  country_group.country_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT rg.region_group_id,
			   rg.group_name,
			   r.country country_id,
			   r.region region_id,
			   r.name region_name,
			   c.name country_name
		  FROM region_group_region rgr
		  JOIN region_group rg ON rg.region_group_id = rgr.region_group_id
		  JOIN postcode.region r ON r.country = rgr.country AND r.region = rgr.region
		  JOIN postcode.country c ON r.country = c.country
		 WHERE in_group IS NULL
			OR in_group = rgr.region_group_id;
END;

PROCEDURE UNSEC_PublishComplianceItem(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE
)
AS
	v_rollout_delay					NUMBER;
	v_items_to_process				security.T_SID_TABLE;
BEGIN
	SELECT rollout_delay
	  INTO v_rollout_delay
	  FROM compliance_options
	 WHERE app_sid = security_pkg.GetApp();

	-- If in_compliance_item_id is not specified rollout to all previously published items
	SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item ci
	  JOIN compliance_item_rollout cir
		ON ci.app_sid = cir.app_sid
	   AND ci.compliance_item_id = cir.compliance_item_id
	 WHERE ci.app_sid = security_pkg.GetApp()
	   AND (ci.compliance_item_id = in_compliance_item_id
			OR (in_compliance_item_id IS NULL AND
				ci.compliance_item_status_id = COMPLIANCE_STATUS_PUBLISHED))
	   FOR UPDATE OF ci.compliance_item_status_id, cir.rollout_dtm, cir.rollout_pending;

	UPDATE compliance_item
	   SET compliance_item_status_id = COMPLIANCE_STATUS_PUBLISHED
	 WHERE compliance_item_id IN (SELECT column_value FROM TABLE(v_items_to_process));

	UPDATE compliance_item_rollout
	   SET rollout_dtm = SYS_EXTRACT_UTC(SYSTIMESTAMP) + v_rollout_delay / 1440,
	       rollout_pending = 1
	 WHERE compliance_item_id IN (SELECT column_value FROM TABLE(v_items_to_process));
END;

PROCEDURE UNSEC_SetExcludedTags(	in_response_id					IN quick_survey_response.survey_response_id%TYPE,
	in_add_exclusions				IN security_pkg.T_SID_IDS,
	in_remove_exclusions			IN security_pkg.T_SID_IDS
)
AS
	v_region_sid					security_pkg.T_SID_ID;
	v_add_exclusions_table			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_add_exclusions);
	v_remove_exclusions_table		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_remove_exclusions);
BEGIN
	SELECT MIN(region_sid)
	  INTO v_region_sid
	  FROM region_survey_response
	 WHERE survey_response_id = in_response_id;

	-- If no region to tag, just do nothing.
	IF v_region_sid IS NOT NULL THEN
		INSERT INTO compliance_region_tag (region_sid, tag_id)
		SELECT v_region_sid, t.column_value
			  FROM TABLE(v_add_exclusions_table) t
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM compliance_region_tag
			 WHERE region_sid = v_region_sid
			   AND tag_id = t.column_value
			);

		DELETE FROM compliance_region_tag crt
		WHERE region_sid = v_region_sid
		  AND EXISTS (
			SELECT NULL
				  FROM TABLE(v_remove_exclusions_table) t
			 WHERE t.column_value = crt.tag_id
			);

		UNSEC_PublishComplianceItem(NULL);
	END IF;
END;


PROCEDURE SetEnabledFlow(
	in_enable_requirement_flow		IN NUMBER,
	in_enable_regulation_flow		IN NUMBER
)
AS
	v_requirement_flow_sid			security_pkg.T_SID_ID;
	v_regulation_flow_sid			security_pkg.T_SID_ID;
	v_sids							security_pkg.T_SID_IDS;
BEGIN
	INTERNAL_AssertAdmin;

	SELECT requirement_flow_sid, regulation_flow_sid
	  INTO v_requirement_flow_sid, v_regulation_flow_sid
	  FROM compliance_options
	 WHERE app_sid = security_pkg.GetApp;
	
	IF in_enable_requirement_flow = 1 THEN
		IF v_requirement_flow_sid IS NULL THEN
			v_requirement_flow_sid := INTERNAL_CreateDefaultWorkflow('Requirement Workflow', 'requirement');
		END IF;
		
		IF trash_pkg.IsInTrash(security_pkg.GetAct, v_requirement_flow_sid) = 1 THEN
			v_sids(1) := v_requirement_flow_sid;
			trash_pkg.RestoreObjects(v_sids);
		END IF;
	ELSIF v_requirement_flow_sid IS NOT NULL AND trash_pkg.IsInTrash(security_pkg.GetAct, v_requirement_flow_sid) = 0 THEN
		flow_pkg.TrashFlow(v_requirement_flow_sid);
	END IF;
	
	IF in_enable_regulation_flow = 1 THEN
		IF v_regulation_flow_sid IS NULL THEN
			v_regulation_flow_sid := INTERNAL_CreateDefaultWorkflow('Regulation Workflow', 'regulation');
		END IF;
		
		IF trash_pkg.IsInTrash(security_pkg.GetAct, v_regulation_flow_sid) = 1 THEN
			v_sids(1) := v_regulation_flow_sid;
			trash_pkg.RestoreObjects(v_sids);
		END IF;
	ELSIF v_regulation_flow_sid IS NOT NULL AND trash_pkg.IsInTrash(security_pkg.GetAct, v_regulation_flow_sid) = 0 THEN
		flow_pkg.TrashFlow(v_regulation_flow_sid);
	END IF;
	
	UPDATE compliance_options
	   SET requirement_flow_sid = DECODE(in_enable_requirement_flow, 1, v_requirement_flow_sid),
		   regulation_flow_sid = DECODE(in_enable_regulation_flow, 1, v_regulation_flow_sid)
	 WHERE app_sid = security_pkg.GetApp;
END;

FUNCTION CreateApplicationWorkflow RETURN security_pkg.T_SID_ID
AS
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_wf_ct_sid						security.security_pkg.T_SID_ID;
BEGIN
	-- First try to find an existing workflow
	BEGIN
		SELECT flow_sid
		  INTO v_workflow_sid
		  FROM flow
		 WHERE flow_alert_class = 'application'
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
		in_label			=> 'Application Workflow',
		in_parent_sid		=> v_wf_ct_sid,
		in_flow_alert_class	=> 'application',
		out_flow_sid		=> v_workflow_sid
	);

	compliance_setup_pkg.UpdatePermApplicationWorkflow(v_workflow_sid, 'application');

	RETURN v_workflow_sid;
END;

FUNCTION CreateConditionWorkflow RETURN security_pkg.T_SID_ID
AS
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_wf_ct_sid						security.security_pkg.T_SID_ID;
BEGIN
	-- First try to find an existing workflow
	BEGIN
		SELECT flow_sid
		  INTO v_workflow_sid
		  FROM flow
		 WHERE flow_alert_class = 'condition'
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
		in_label			=> 'Condition Workflow',
		in_parent_sid		=> v_wf_ct_sid,
		in_flow_alert_class	=> 'condition',
		out_flow_sid		=> v_workflow_sid
	);

	compliance_setup_pkg.UpdatePermitConditionWorkflow(v_workflow_sid, 'condition');

	RETURN v_workflow_sid;
END;

PROCEDURE GetFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT a.app_sid, a.from_state_label, a.to_state_label, a.set_dtm,
			   a.customer_alert_type_id, a.flow_state_log_id, a.flow_state_transition_id,
			   a.flow_item_generated_alert_id, a.set_by_user_sid, a.set_by_user_name,
			   a.set_by_full_name, a.set_by_email, a.to_user_sid, a.to_user_name, a.to_full_name,
			   a.to_email, a.to_friendly_name, a.to_initiator, a.flow_alert_helper, a.flow_item_id,
			   a.comment_text,
			   cid.title, cid.summary, cid.details, ci.source, cr.country, cr.region, cr.region_group,
			   cr.country_group, ci.reference_code, ci.user_comment, cid.citation, ci.external_link,
			   ci.created_dtm, ci.updated_dtm,
			   creg.adoption_dtm,
			   r.region_sid, r.description region_description, r.region_ref
		  FROM v$open_flow_item_gen_alert a
		  JOIN compliance_item_region cir
			ON cir.app_sid = a.app_sid AND cir.flow_item_id = a.flow_item_id
		  JOIN v$region r
			ON r.app_sid = a.app_sid AND r.region_sid = cir.region_sid
		  JOIN compliance_item ci
			ON ci.app_sid = cir.app_sid AND ci.compliance_item_id = cir.compliance_item_id
		  JOIN compliance_item_description cid 
		    ON ci.compliance_item_id = cid.compliance_item_id AND cid.app_sid = ci.app_sid
		  JOIN compliance_language cl
		    ON cl.lang_id = cid.lang_id AND ci.app_sid = cid.app_sid
		  --This should go once we are passing the compliance_language selected
		  JOIN aspen2.lang l ON l.lang_id = cl.lang_id AND l.lang = 'en'
		  LEFT JOIN compliance_regulation creg
			ON creg.app_sid = ci.app_sid AND creg.compliance_item_id = ci.compliance_item_id
		  LEFT JOIN compliance_item_rollout cr
			ON cr.app_sid = ci.app_sid AND cr.compliance_item_id = ci.compliance_item_id;
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE
AS
	v_region_sids					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM compliance_item_region
	 WHERE app_sid = security_pkg.GetApp
	   AND flow_item_id = in_flow_item_id;

	RETURN v_region_sids;
END;

PROCEDURE GetRootRegions(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.description region_description, crr.region_type, crr.rollout_level
		  FROM compliance_root_regions crr
		  JOIN v$region r ON crr.app_sid = r.app_sid AND crr.region_sid = r.region_sid
		 WHERE crr.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetEnhesaOptions(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_errors						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertComplianceMgr;

	OPEN out_cur FOR
		SELECT eo.app_sid, eo.client_id, eo.username, eo.last_success, eo.last_run, eo.last_message, eo.next_run, eo.manual_run,
				eo.packages_imported, eo.packages_total, eo.items_imported, eo.items_total, eo.links_created, eo.links_total, decode(eo.password, null, 0, 1) has_password
		  FROM enhesa_options eo
		 WHERE app_sid = security_pkg.GetApp;
	
	OPEN out_errors FOR
		SELECT app_sid, error_log_id, error_dtm, error_message
		  FROM (
			SELECT eel.app_sid, eel.error_log_id, eel.error_dtm, eel.error_message
			  FROM enhesa_error_log eel, enhesa_options eo
			 WHERE eel.app_sid = security_pkg.GetApp
			   AND eel.error_dtm >= eo.last_run
			 ORDER BY eel.error_dtm DESC
			)
		 WHERE ROWNUM <= 20;
END;

-- Only used by sched task.
PROCEDURE GetAllEnhesaOptions(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT eo.app_sid, eo.client_id, eo.username, eo.password, eo.last_success, eo.last_run, eo.last_message, eo.next_run, eo.manual_run, decode(eo.password, null, 0, 1) has_password
		  FROM enhesa_options eo;
END;

PROCEDURE GetComplianceOptions(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, quick_survey_type_id, requirement_flow_sid, regulation_flow_sid,
			   permit_flow_sid, application_flow_sid, condition_flow_sid, rollout_option, rollout_delay,
			   auto_involve_managers
		  FROM compliance_options;
END;

PROCEDURE AddEnhesaError(
	in_error_dtm					IN	enhesa_error_log.error_dtm%TYPE,
	in_error_msg					IN	enhesa_error_log.error_message%TYPE,
	in_stack_trace					IN	enhesa_error_log.stack_trace%TYPE
)
AS
BEGIN
	INSERT INTO enhesa_error_log(error_log_id, error_dtm, error_message, stack_trace)
	VALUES(enhesa_error_log_id_seq.nextval, in_error_dtm, in_error_msg, in_stack_trace);
END;

PROCEDURE SetRootRegions(
	in_regions						IN	security_pkg.T_SID_IDS,
	in_types						IN	security_pkg.T_SID_IDS,
	in_rollout_level				IN	security_pkg.T_SID_IDS
)
AS
	v_changed_rows					PLS_INTEGER := 0;
	v_region_table					security.T_ORDERED_SID_TABLE;
	v_type_table					security.T_ORDERED_SID_TABLE;
	v_rollout_table					security.T_ORDERED_SID_TABLE;
BEGIN
	AssertComplianceMgr;

	IF in_regions.COUNT != in_types.COUNT THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Array sizes do not match');
	END IF;

	v_region_table := security_pkg.SidArrayToOrderedTable(in_regions);
	v_type_table := security_pkg.SidArrayToOrderedTable(in_types);
	v_rollout_table := security_pkg.SidArrayToOrderedTable(in_rollout_level);

	DELETE FROM compliance_root_regions
	 WHERE (region_sid, region_type, rollout_level) NOT IN (
				SELECT r.sid_id region_sid, t.sid_id region_type, rl.sid_id rollout_level
				  FROM TABLE(v_region_table) r
				  JOIN TABLE(v_type_table) t ON r.pos = t.pos
				  JOIN TABLE(v_rollout_table) rl ON t.pos = rl.pos
		   );
	v_changed_rows := v_changed_rows + SQL%ROWCOUNT;

	INSERT INTO compliance_root_regions (region_sid, region_type, rollout_level)
		SELECT r.sid_id region_sid,
			   (CASE WHEN rl.sid_id = ROLLOUT_LEVEL_THIS_REG_ONLY
					 THEN (SELECT region_type
							 FROM csr.region
							WHERE region_sid = r.sid_id)
					 ELSE t.sid_id
			   END) region_type,
			   rl.sid_id rolloutlevel
		  FROM TABLE(v_region_table) r
		  JOIN TABLE(v_type_table) t ON r.pos = t.pos
		  JOIN TABLE(v_rollout_table) rl ON t.pos = rl.pos
		 WHERE (r.sid_id, t.sid_id, rl.sid_id) NOT IN (
					SELECT region_sid, region_type, rollout_level
					  FROM compliance_root_regions
			   );
	v_changed_rows := v_changed_rows + SQL%ROWCOUNT;

	-- Republish everything if there are any changes
	IF v_changed_rows != 0 THEN
		PublishComplianceItem(NULL);
	END IF;
END;

PROCEDURE Internal_SetRolloutMode(
	in_rollout_mode					IN compliance_options.rollout_option%TYPE
)
AS
	v_rollout_mode					compliance_options.rollout_option%TYPE;
BEGIN
	--Security applied by calling proc

	SELECT rollout_option
	  INTO v_rollout_mode
	  FROM compliance_options
	 WHERE app_sid = security_pkg.GetApp
	   FOR UPDATE;

	IF v_rollout_mode != in_rollout_mode THEN
		UPDATE compliance_options
		   SET rollout_option = in_rollout_mode
		 WHERE app_sid = security_pkg.GetApp;

		IF in_rollout_mode != ROLLOUT_OPTION_DISABLED THEN
			PublishComplianceItem(NULL);
		END IF;
	END IF;
END;

PROCEDURE SetComplianceOptions(
	in_rollout_mode					IN compliance_options.rollout_option%TYPE,
	in_rollout_delay				IN	compliance_options.rollout_delay%TYPE,
	in_auto_involve_managers		IN	compliance_options.auto_involve_managers%TYPE
)
AS
	v_rollout_delay					compliance_options.rollout_delay%TYPE;
BEGIN
	IF NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;

	SELECT rollout_delay
	  INTO v_rollout_delay
	  FROM compliance_options
	 WHERE app_sid = security_pkg.GetApp
	   FOR UPDATE;

	UPDATE compliance_options
	   SET auto_involve_managers = in_auto_involve_managers
	 WHERE app_sid = security_pkg.GetApp;

	Internal_SetRolloutMode(in_rollout_mode);

	if INTERNAL_IsAdmin THEN

		UPDATE compliance_options
		SET rollout_delay = in_rollout_delay
		WHERE app_sid = security_pkg.GetApp;

		IF v_rollout_delay != in_rollout_delay THEN
			-- If the delay has been reduced, we may have to bring forward the rollout of any
			-- previously scheduled items
			UPDATE compliance_item_rollout
			SET rollout_dtm = LEAST(rollout_dtm, SYS_EXTRACT_UTC(SYSTIMESTAMP) + in_rollout_delay / 1440)
			WHERE app_sid = security_pkg.GetApp()
			AND rollout_pending = 1
			AND rollout_dtm IS NOT NULL;
		END IF;

	END IF;
END;

PROCEDURE SetEnhesaOptions(
	in_client_id					IN	enhesa_options.client_id%TYPE,
	in_next_run						IN	enhesa_options.next_run%TYPE,
	in_username						IN	enhesa_options.username%TYPE DEFAULT NULL,
	in_password						IN	enhesa_options.password%TYPE DEFAULT NULL,
	in_last_run						IN	enhesa_options.last_run%TYPE DEFAULT NULL,
	in_last_message					IN	enhesa_options.last_message%TYPE DEFAULT NULL,
	in_last_success					IN	enhesa_options.last_success%TYPE DEFAULT NULL,
	in_manual_run					IN	enhesa_options.manual_run%TYPE DEFAULT 0,
	in_packages_imported			IN	enhesa_options.packages_imported%TYPE DEFAULT 0,
	in_packages_total				IN	enhesa_options.packages_total%TYPE DEFAULT 0,
	in_items_imported				IN	enhesa_options.items_imported%TYPE DEFAULT 0,
	in_items_total					IN	enhesa_options.items_total%TYPE DEFAULT 0,
	in_links_created				IN	enhesa_options.links_created%TYPE DEFAULT 0,
	in_links_total					IN	enhesa_options.links_total%TYPE DEFAULT 0
)
AS
BEGIN
	IF (NOT INTERNAL_IsAdmin AND NOT INTERNAL_IsComplianceManager) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not an administrator or missing "Manage compliance items" capability');
	END IF;

	UPDATE enhesa_options
	   SET next_run = in_next_run,
		   manual_run = in_manual_run
	 WHERE app_sid = security_pkg.GetApp;

	IF (INTERNAL_IsSuperAdmin) THEN
		UPDATE enhesa_options
		   SET client_id = in_client_id,
			   username = in_username,
			   password = CASE WHEN in_username IS NOT NULL AND in_password IS NOT NULL THEN in_password WHEN in_username IS NOT NULL THEN NVL(in_password, password) ELSE NULL END,
			   last_run = NVL(in_last_run, last_run),
			   last_message = NVL(in_last_message, last_message),
			   last_success = NVL(in_last_success, last_success),
			   manual_run = in_manual_run,
			   packages_imported = in_packages_imported,
			   packages_total = in_packages_total,
			   items_imported = in_items_imported,
			   items_total = in_items_total,
			   links_created = in_links_created,
			   links_total = in_links_total
		 WHERE app_sid = security_pkg.GetApp;

		IF SQL%ROWCOUNT = 0 THEN
			INSERT INTO enhesa_options (app_sid, client_id, username, password, next_run, manual_run, packages_imported, packages_total, items_imported, items_total, links_created, links_total)
			VALUES (
				security_pkg.GetApp,
				in_client_id,
				in_username,
				in_password,
				in_next_run,
				in_manual_run,
				in_packages_imported,
				in_packages_total,
				in_items_imported,
				in_items_total,
				in_links_created,
				in_links_total
			);
		END IF;
	END IF;
END;

PROCEDURE CreateFlowItem(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_region_sid					IN	region.region_sid%TYPE,
	out_flow_item_id				OUT	compliance_item_region.flow_item_id%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_default_state_id				flow.default_state_id%TYPE;
	v_new_state						flow_state.flow_state_id%TYPE;
	v_natures						flow_state_natures;
	v_flow_state_log_id				flow_state_log.flow_state_log_id%TYPE;
BEGIN
	BEGIN
		-- Find existing flow item
		SELECT flow_item_id
		  INTO out_flow_item_id
		  FROM compliance_item_region
		 WHERE compliance_item_id = in_compliance_item_id
		   AND region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_sid := INTERNAL_FlowForComplianceItem(in_compliance_item_id);

			-- Do nothing if no flow workflow is configured for this item type
			IF v_flow_sid IS NOT NULL THEN
				v_natures := INTERNAL_GetFlowStateNatures(v_flow_sid);

				SELECT default_state_id
				  INTO v_default_state_id
				  FROM flow
				 WHERE flow_sid = v_flow_sid;

				INSERT INTO flow_item (flow_item_id, flow_sid, current_state_id)
				VALUES (flow_item_id_seq.NEXTVAL, v_flow_sid, v_default_state_id)
				RETURNING flow_item_id INTO out_flow_item_id;

				INSERT INTO compliance_item_region (compliance_item_id, region_sid, flow_item_id)
				VALUES (in_compliance_item_id, in_region_sid, out_flow_item_id);

				v_new_state := INTERNAL_TransitionToNew(
					in_flow_item_id			=> out_flow_item_id,
					in_compliance_item_id	=> in_compliance_item_id,
					in_comment				=> 'Created'
				);

				IF v_new_state IS NULL THEN
					-- Flow items must have a log item
					v_flow_state_log_id := flow_pkg.AddToLog(
						in_flow_item_id		=> out_flow_item_id,
						in_comment_text		=> 'Created'
					);
				END IF;
			END IF;
	END;
END;

PROCEDURE GetSourceTypes(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT compliance_item_source_id id, description
		  FROM compliance_item_source;
END;

PROCEDURE GetItemStates(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security - its basedata
	OPEN out_cur FOR
		SELECT compliance_item_status_id id, description
		  FROM compliance_item_status;
END;

PROCEDURE RetireComplianceItem(
	in_compliance_item_id			IN compliance_item.compliance_item_id%TYPE
)
AS
	v_change_type					compliance_item_version_log.change_type%TYPE;
	v_new_major_version				compliance_item.major_version%TYPE;
	v_new_minor_version				compliance_item.minor_version%TYPE;
BEGIN
	AssertComplianceMgr();

	UPDATE compliance_item
	   SET compliance_item_status_id = COMPLIANCE_STATUS_RETIRED
	 WHERE app_sid = security.security_pkg.GetApp()
	   AND compliance_item_id = in_compliance_item_id;

	SELECT compliance_item_change_type_id
	  INTO v_change_type
	  FROM compliance_item_change_type
	 WHERE source = SOURCE_USER_DEFINED
	   AND change_type_index = USER_CHANGE_TYPE_RETIRED;

	INTERNAL_UpdateVersionNumber(
		in_compliance_item_id		=> in_compliance_item_id,
		in_status_id 				=> COMPLIANCE_STATUS_RETIRED,
		in_change_reason			=> 'Retired',
		in_change_type				=> v_change_type,
		in_is_major_change			=> CHANGE_TYPE_MAJOR,
		in_is_standard_audit_entry 	=> true,
		out_new_major_version		=> v_new_major_version,
		out_new_minor_version		=> v_new_minor_version
	);

	UPDATE compliance_item 
	   SET major_version = v_new_major_version,
	       minor_version = v_new_minor_version
	 WHERE compliance_item_id = in_compliance_item_id;

	FOR item IN (SELECT cir.flow_item_id
				   FROM csr.compliance_item_region cir
				   JOIN flow_item fi
					 ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
				   JOIN flow f
					 ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
				  WHERE compliance_item_id = in_compliance_item_id)
	LOOP
		INTERNAL_TransitionToUpdated(
			in_flow_item_id			=> item.flow_item_id,
			in_compliance_item_id	=> in_compliance_item_id,
			in_comment				=> 'Compliance library item retired'
		);
	END LOOP;
END;

PROCEDURE GetChangeTypes(
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT compliance_item_change_type_id, description, source, change_type_index, enhesa_id
		  FROM compliance_item_change_type;
END;

PROCEDURE PublishComplianceItem(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_is_first_publication			IN NUMBER DEFAULT 0
)
AS
	v_change_type					compliance_item_version_log.change_type%TYPE;
	v_new_major_version				compliance_item.major_version%TYPE;
	v_new_minor_version				compliance_item.minor_version%TYPE;
BEGIN
	AssertComplianceMgr();

	UNSEC_PublishComplianceItem(in_compliance_item_id);

	-- Only add a specific publication version history on first publication
	-- When publishing (changing) an existing item, no 'published' entry is required.
	IF in_is_first_publication = 1 THEN

		SELECT compliance_item_change_type_id
		  INTO v_change_type
		  FROM compliance_item_change_type
		 WHERE source = SOURCE_USER_DEFINED
		   AND change_type_index = USER_CHANGE_TYPE_NO_CHANGE;

		INTERNAL_UpdateVersionNumber(
			in_compliance_item_id		=> in_compliance_item_id,
			in_status_id 				=> COMPLIANCE_STATUS_PUBLISHED,
			in_change_reason			=> 'Published',
			in_change_type				=> v_change_type,
			in_is_major_change			=> CHANGE_TYPE_MAJOR,
			in_is_standard_audit_entry 	=> false,
			out_new_major_version		=> v_new_major_version,
			out_new_minor_version		=> v_new_minor_version
		);
	END IF;

END;

-- called by scheduled task
PROCEDURE GetAppsPendingRollout(
	in_due_dtm						IN  DATE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT co.app_sid
		  FROM compliance_options co
		 WHERE co.rollout_option != ROLLOUT_OPTION_DISABLED
		   AND EXISTS (
			SELECT NULL
			  FROM compliance_item_rollout cir
			 WHERE cir.rollout_pending = 1
			   AND cir.rollout_dtm <= in_due_dtm
			   AND cir.app_sid = co.app_sid
		   );
END;

-- Fills a collection with the lowest level regions of a particular type. The lowest level region
-- is the region closest to the leaf node in each branch with a matching type.
FUNCTION GetLowestLevelRegions(in_region_sid IN NUMBER, in_type IN NUMBER)
RETURN security.T_SID_TABLE
AS
	v_results						security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	--
	-- There are three hierarchical queries here:
	--
	--	  1) First we find all the leaf regions under the root
	--
	--	  2) Then go back up the tree until we encounter a region of the required type, this is our
	--		 candidate lowest level region.
	--
	--	  4) Finally we go back down the tree to remove any regions that have any descendants of
	--		 the same type on a different branch.
	--
	-- Surprisingly enough Oracle does a fairly decent job of this. It's more work than needed, but
	-- is still faster than an iterative approach in PL/SQL (it takes up to a few seconds for large
	-- trees).
	--
	SELECT region_sid
	  BULK COLLECT INTO v_results
	  FROM (
			SELECT DISTINCT region_sid
			  FROM region
			 WHERE region_type = in_type
			 START WITH region_sid IN (
					SELECT region_sid
					  FROM region
					 WHERE CONNECT_BY_ISLEAF = 1
					 START WITH region_sid = in_region_sid
				   CONNECT BY PRIOR region_sid = parent_sid
				 )
		   CONNECT BY PRIOR parent_sid = region_sid
			   AND PRIOR region_type != in_type
			   AND PRIOR region_sid != in_region_sid
		 ) lowest_in_branch
	 WHERE NOT EXISTS (
			SELECT region_type
			  FROM region
			 WHERE region_type = in_type
		START WITH parent_sid = lowest_in_branch.region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
	);

	RETURN v_results;
END;

-- Gets all the regions in the rollout set defined by compliance_root_regions
FUNCTION GetRegionsForRollout(in_require_survey_response BOOLEAN := FALSE)
RETURN security.T_SID_TABLE
AS
	v_regions						security.T_SID_TABLE;
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_regions
	  FROM (
		-- Specificly selected regions
		SELECT region_sid
		  FROM csr.compliance_root_regions
		 WHERE rollout_level = ROLLOUT_LEVEL_THIS_REG_ONLY

		-- All regions of type
		 UNION
		SELECT r.region_sid
		  FROM (
			SELECT r.app_sid,
				   r.region_sid,
		           r.region_type,
		           CONNECT_BY_ROOT region_sid root_region_sid
			  FROM region r
			 -- This clause is not required but speeds up the query with large trees
		     START WITH r.region_sid IN (
				SELECT DISTINCT region_sid
				  FROM csr.compliance_root_regions
				 WHERE rollout_level = ROLLOUT_LEVEL_ALL_REGS_OF_TYPE
			 )
		   CONNECT BY r.parent_sid = PRIOR r.region_sid
			 ) r
		  JOIN csr.compliance_root_regions crr
			ON crr.app_sid = r.app_sid
		   AND crr.region_sid = r.root_region_sid
		   AND crr.region_type = r.region_type
		   AND crr.rollout_level = ROLLOUT_LEVEL_ALL_REGS_OF_TYPE
	 );

	-- "Lowest level" regions
	FOR r IN (SELECT region_sid, region_type
				FROM compliance_root_regions
			   WHERE rollout_level = ROLLOUT_LEVEL_LOWEST)
	LOOP
		v_regions :=
			v_regions MULTISET UNION DISTINCT GetLowestLevelRegions(r.region_sid, r.region_type);
	END LOOP;

	-- Filter out regions that don't have a survey response
	IF in_require_survey_response THEN
		DECLARE
			v_filtered_regions		security.T_SID_TABLE;
		BEGIN
			SELECT column_value
			  BULK COLLECT INTO v_filtered_regions
			  FROM TABLE(v_regions) r
			  JOIN region_survey_response rsr ON r.column_value = rsr.region_sid
			  JOIN quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id
			  JOIN quick_survey qs on qs.survey_sid = rsr.survey_sid
			  JOIN compliance_options co on co.quick_survey_type_id = qs.quick_survey_type_id
			 WHERE qsr.last_submission_id IS NOT NULL;

			v_regions := v_filtered_regions;
		END;
	END IF;

	RETURN v_regions;
END;

PROCEDURE RolloutComplianceItems(
	in_due_dtm						IN	DATE,
	in_max_items					IN	NUMBER,
	out_updated						OUT	NUMBER
)
AS
	v_rollout_items					T_COMPLIANCE_ROLLOUT_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
	v_flow_item_id					security_pkg.T_SID_ID;
	v_items_to_process				security.T_SID_TABLE;
	v_rollout_option				compliance_options.rollout_option%TYPE;
	v_flagged_federal_item_count	NUMBER(10);
	v_rollout_regions				security.T_SID_TABLE;
BEGIN
	out_updated := 0;

	AssertComplianceMgr();

	SELECT rollout_option
	  INTO v_rollout_option
	  FROM compliance_options;

	IF v_rollout_option = ROLLOUT_OPTION_DISABLED THEN
		RETURN;
	END IF;

	v_rollout_regions := GetRegionsForRollout(v_rollout_option = ROLLOUT_OPTION_ENABLED_SURVEY);

	SELECT COUNT(1)
	  INTO v_flagged_federal_item_count
	  FROM csr.compliance_item_rollout cirag
	 WHERE is_federal_req = 1 OR federal_requirement_code IS NOT NULL;

	-- Non federal requirements are proccessed first, to make it easier to exclude redundant
	-- federal requirements later on.
	SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item_rollout cir
	  JOIN (SELECT ncir.compliance_item_id
			  FROM compliance_item_rollout ncir
			  JOIN compliance_item ci ON ncir.app_sid = ci.app_sid AND ncir.compliance_item_id = ci.compliance_item_id
			 WHERE ncir.rollout_pending = 1
			   AND ncir.rollout_dtm <= in_due_dtm
			   AND ncir.suppress_rollout = 0
			   AND ci.compliance_item_status_id = COMPLIANCE_STATUS_PUBLISHED
			 ORDER BY is_federal_req) ordered
		ON cir.compliance_item_id = ordered.compliance_item_id
	 WHERE in_max_items IS NULL OR ROWNUM <= in_max_items
	-- This lock prevents compliance item or region tree edits, so try not to hold it for long
	   FOR UPDATE OF cir.rollout_pending;

	IF v_items_to_process.COUNT = 0 THEN
		RETURN;
	END IF;

	compliance_pkg.FilterRolloutItems(
		v_items_to_process,
		v_rollout_regions,
		v_filtered_rollout_items
	);

	v_rollout_items := v_filtered_rollout_items;

	-- Filtering list to only roll out items that are regional and federal if no other regional
	-- item is using it as their federal req. Only do this if there's been an import which
	-- updates the new federal requirement tracking fields. For this to work federal items must be
	-- rolled out *after* non-federal items. We can get away with this because these items arrive
	-- all at once through the ENHESA feed.
	IF (v_flagged_federal_item_count > 0) THEN
		SELECT T_COMPLIANCE_ROLLOUT_ITEM(cirr.compliance_item_id, irr.region_sid)
		  BULK COLLECT INTO v_filtered_rollout_items
		  FROM TABLE(v_rollout_items) irr
		  JOIN compliance_item_rollout cirr ON irr.compliance_item_id = cirr.compliance_item_id
		  JOIN compliance_item ci ON ci.compliance_item_id = cirr.compliance_item_id
		 WHERE cirr.is_federal_req = 0
			OR (cirr.is_federal_req = 1 AND NOT EXISTS (
				SELECT lro.federal_requirement_code
				  FROM compliance_item_rollout lro
				  JOIN compliance_item_region lr
					ON lr.compliance_item_id = lro.compliance_item_id
				 WHERE lro.federal_requirement_code = ci.reference_code
				   AND lro.is_federal_req = 0
				   AND lr.region_sid = irr.region_sid)
			);
		v_rollout_items := v_filtered_rollout_items;
	END IF;

	-- Create flow items where they don't already exist
	FOR item IN (SELECT compliance_item_id, region_sid FROM TABLE(v_rollout_items))
	LOOP
		CreateFlowItem(
			item.compliance_item_id,
			item.region_sid,
			v_flow_item_id
		);

		UPDATE compliance_item_region
		   SET out_of_scope = 0
		 WHERE flow_item_id = v_flow_item_id;
	END LOOP;

	-- Find library items that have flow items, but are not in the rollout list. These have
	-- probably been excluded by a tag or geography change.
	FOR item IN (SELECT cir.flow_item_id, cir.compliance_item_id
				   FROM compliance_item_region cir
				  WHERE cir.compliance_item_id IN (
							SELECT column_value
							  FROM TABLE(v_items_to_process)
							)
					AND (cir.region_sid, cir.compliance_item_id) NOT IN (
							SELECT region_sid, compliance_item_id
							  FROM TABLE(v_rollout_items)
					)
				)
	LOOP
		INTERNAL_TransitionToUpdated(
			in_flow_item_id			=> item.flow_item_id,
			in_compliance_item_id	=> item.compliance_item_id,
			in_comment				=> 'Library item no longer applicable'
		);

		UPDATE compliance_item_region
		   SET out_of_scope = 1
		 WHERE flow_item_id = item.flow_item_id;
	END LOOP;

	UPDATE compliance_item_rollout
	   SET rollout_pending = 0
	 WHERE compliance_item_id IN (SELECT column_value FROM TABLE(v_items_to_process));

	out_updated := v_items_to_process.COUNT;
END;

PROCEDURE FilterRolloutItems(
	in_items_to_process				IN security.T_SID_TABLE,
	in_rollout_regions				IN security.T_SID_TABLE,
	out_filtered_rollout_items		OUT T_COMPLIANCE_ROLLOUT_TABLE
)
AS
	v_rollout_items					T_COMPLIANCE_ROLLOUT_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
BEGIN
	-- Any filtering that does not depend on the join between regions and compliance items
	-- should be done before this point!
	
	SELECT T_COMPLIANCE_ROLLOUT_ITEM(cir.compliance_item_id, r.region_sid)
	  BULK COLLECT INTO v_rollout_items
	  FROM compliance_item_rollout cir
	  JOIN TABLE(in_items_to_process) i
		ON cir.compliance_item_id = i.column_value
	  LEFT JOIN compliance_rollout_regions crrs
		ON cir.app_sid = crrs.app_sid
	   AND cir.compliance_item_id = crrs.compliance_item_id
	  JOIN region r
		ON (r.region_sid = crrs.region_sid)
		OR (crrs.region_sid IS NULL
			AND (
				-- Only Country set
				(r.geo_country = cir.country AND
					-- Region is set
					(cir.region IS NULL OR r.geo_region = cir.region) AND
					cir.region_group IS NULL AND
					cir.country_group IS NULL)
				-- Country group is set
				OR (r.geo_country IN (
						SELECT country_id
						  FROM country_group_country
						 WHERE country_group_id = cir.country_group))
				-- Region group is set
				OR (r.geo_country, r.geo_region) IN (
						SELECT country, region
						  FROM region_group_region
						 WHERE region_group_id = cir.region_group)
			   )
		   )
	  JOIN TABLE(in_rollout_regions) rr
		ON rr.column_value = r.region_sid
	 ORDER BY cir.compliance_item_id;

	-- Filter items excluded by region tags (from screening survey responses)
	SELECT T_COMPLIANCE_ROLLOUT_ITEM(compliance_item_id, region_sid)
	  BULK COLLECT INTO v_filtered_rollout_items
	  FROM (
			SELECT i.compliance_item_id, i.region_sid
			  FROM TABLE(v_rollout_items) i
			  JOIN compliance_requirement cr ON i.compliance_item_id = cr.compliance_item_id
			 WHERE NOT EXISTS(
								SELECT crt.tag_id
								  FROM compliance_item_tag ct
								  JOIN compliance_region_tag crt
								    ON crt.app_sid = ct.app_sid
								   AND crt.tag_id = ct.tag_id
								 WHERE ct.compliance_item_id = i.compliance_item_id
								   AND crt.region_sid = i.region_sid
							)
		UNION ALL
			SELECT vri.compliance_item_id, vri.region_sid
			  FROM TABLE(v_rollout_items) vri
			  JOIN compliance_regulation cr
			    ON vri.compliance_item_id = cr.compliance_item_id
			 WHERE EXISTS(  -- UD-15758: For Regulation we need to exclude a tag only when all of the tags are excluded in Survey Response.
							SELECT cit.tag_id FROM compliance_item_tag cit WHERE cit.compliance_item_id = vri.compliance_item_id
							 MINUS
							SELECT crt.tag_id FROM compliance_region_tag crt WHERE crt.region_sid = vri.region_sid
					     )
				);

	out_filtered_rollout_items := v_filtered_rollout_items;
END;

PROCEDURE RolloutComplianceItems(
	in_due_dtm						IN	DATE,
	out_updated						OUT	NUMBER
)
AS
BEGIN
	RolloutComplianceItems(
		in_due_dtm => in_due_dtm,
		in_max_items => NULL,
		out_updated => out_updated
	);
END;

PROCEDURE UNSEC_LinkItemsByCode(
	in_reg_lookup_key				IN  compliance_item.lookup_key%TYPE,
	in_req_lookup_key				IN  compliance_item.lookup_key%TYPE
)
AS
	v_reg_item_id					compliance_item.compliance_item_id%TYPE;
	v_req_item_id					compliance_item.compliance_item_id%TYPE;
BEGIN
	SELECT compliance_item_id
	  INTO v_reg_item_id
	  FROM compliance_item
	 WHERE lookup_key = in_reg_lookup_key;

	SELECT compliance_item_id
	  INTO v_req_item_id
	  FROM compliance_item
	 WHERE lookup_key = in_req_lookup_key;

	BEGIN
		INSERT INTO compliance_req_reg (requirement_id, regulation_id)
		VALUES (v_req_item_id, v_reg_item_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE GetTagsFromHeadingCodes (
	in_heading_codes				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_heading_code_tbl		security.T_VARCHAR2_TABLE;
BEGIN
	IF in_heading_codes IS NULL OR (in_heading_codes.COUNT = 1 AND in_heading_codes(1) IS NULL) THEN
		-- do nothing
        NULL;
    ELSE
		v_heading_code_tbl := security_pkg.Varchar2ArrayToTable(in_heading_codes);
		OPEN out_cur FOR
			SELECT t.tag_id
			  FROM TABLE(v_heading_code_tbl) hc
			  JOIN tag t ON t.lookup_key = hc.value
			  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
			  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id
			 WHERE tg.lookup_key = 'ENHESA';
	END IF;
END;

FUNCTION GetIdByLookupKeyForEnhesa (
	in_key						IN  compliance_item.lookup_key%TYPE
) RETURN NUMBER
AS
	v_id	compliance_item.compliance_item_id%TYPE;
BEGIN
	SELECT MIN(compliance_item_id)
	  INTO v_id
	  FROM compliance_item
	 WHERE lookup_key = in_key
	   AND source = SOURCE_ENHESA;

	RETURN NVL(v_id, -1);
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
BEGIN
	-- Some security check?
	INTERNAL_AssertFlowAccess(in_flow_item_id);

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
	 WHERE al.flow_item_id = in_flow_item_id
		AND al.log_dtm >= in_start_date AND al.log_dtm <= in_end_date + 1
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
		SELECT al.log_dtm audit_date, cu.full_name, cu.user_name, cu.csr_user_sid,
		       al.description, al.comment_text, al.param_1, al.param_2, al.param_3
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
				SELECT fsl.app_sid, fsl.flow_state_log_id, fsl.flow_item_id, fsl.set_dtm log_dtm, fsl.set_by_user_sid user_sid, 'Entered state: {0}' description,
					   fsl.comment_text, fs.label flow_state_label, fs.label param_1, null param_2, null param_3
				  FROM flow_state_log fsl
				  JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id
			) al ON x.flow_item_audit_log_id = al.flow_item_audit_log_id
		  JOIN csr_user cu ON al.user_sid = cu.csr_user_sid
		 WHERE al.flow_item_id = in_flow_item_id
		   AND x.rn >= in_start_row
		 ORDER BY al.log_dtm DESC;
END;

-- Transition (Retire):
-- Local item -> Retired
PROCEDURE OnLocalComplianceItemRetire(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
	v_global_reg_status_id		NUMBER(10);
	v_is_regulation				NUMBER(10);

BEGIN
	SELECT compliance_item_status_id, cr.compliance_item_id
	  INTO v_global_reg_status_id, v_is_regulation
	  FROM compliance_item_region cir
	  JOIN compliance_item ci
	    ON ci.compliance_item_id = cir.compliance_item_id
	  LEFT JOIN compliance_regulation cr
	    ON ci.compliance_item_id = cr.compliance_item_id
	 WHERE flow_item_id = in_flow_item_id;

	IF v_global_reg_status_id != COMPLIANCE_STATUS_RETIRED THEN
		IF v_is_regulation IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'You can only retire a regulation when the global regulation has been retired.');
		ELSE
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'You can only retire a requirement when the global requirement has been retired.');
		END IF;
	END IF;
END;

PROCEDURE UpdateConditionsOnAcknowledged(
	in_flow_sid 				IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	v_permit_id					NUMBER(10);
	v_state_name				VARCHAR(255);
BEGIN 
	SELECT compliance_permit_id 
	  INTO v_permit_id
	  FROM compliance_permit
	 WHERE flow_item_id = in_flow_item_id;

	SELECT label
	  INTO v_state_name
	  FROM flow_state
	 WHERE Is_deleted = 0
	  AND FLOW_STATE_NATURE_ID = csr.csr_data_PKG.NATURE_CONDIT_INACTIVE
	  AND ROWNUM = 1
	 ORDER BY POS, label, flow_state_id;

	FOR item IN (
		SELECT  fi.flow_item_id
		  FROM flow_item fi
		  JOIN compliance_item_region cir
		    ON fi.app_sid =cir.app_sid  AND  fi.flow_item_id =cir.flow_item_id
		  JOIN compliance_permit_condition cpc
		    ON cir.app_sid = cpc.app_sid AND cir.COMPLIANCE_ITEM_ID = cpc.COMPLIANCE_ITEM_ID
		 WHERE cpc.compliance_permit_id  = v_permit_id
	) LOOP
		flow_pkg.SetItemStateNature(
			in_flow_item_id		=> item.flow_item_id,
			in_to_nature		=> csr.csr_data_PKG.NATURE_CONDIT_INACTIVE,
			in_comment			=> 'Permit surrendered '||v_state_name,
			in_user_sid			=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_force			=> 1
		);
	END LOOP;
END;

PROCEDURE INTERNAL_CreateLinkHistoryItem(
	in_compliance_item_id			IN compliance_item.compliance_item_id%TYPE,
	in_change_reason				IN compliance_item_version_log.description%TYPE
)
AS
	v_status_id						compliance_item.compliance_item_status_id%TYPE;
	v_linked_code					compliance_item.compliance_item_id%TYPE;
	v_change_type					compliance_item_version_log.change_type%TYPE;
	v_new_major_version				compliance_item.major_version%TYPE;
	v_new_minor_version				compliance_item.minor_version%TYPE;

BEGIN

	SELECT compliance_item_status_id
	  INTO v_status_id
	  FROM compliance_item
	 WHERE compliance_item_id = in_compliance_item_id;

	SELECT compliance_item_change_type_id
	  INTO v_change_type
	  FROM compliance_item_change_type
	 WHERE source = SOURCE_USER_DEFINED
	   AND change_type_index = USER_CHANGE_TYPE_NO_CHANGE;

	INTERNAL_UpdateVersionNumber(
		in_compliance_item_id		=> in_compliance_item_id,
		in_status_id 				=> v_status_id,
		in_change_reason			=> in_change_reason,
		in_change_type				=> v_change_type,
		in_is_major_change			=> CHANGE_TYPE_MINOR,
		in_is_standard_audit_entry 	=> true,
		out_new_major_version		=> v_new_major_version,
		out_new_minor_version		=> v_new_minor_version
	);

	UPDATE compliance_item 
	   SET major_version = v_new_major_version,
	       minor_version = v_new_minor_version
	 WHERE compliance_item_id = in_compliance_item_id;

END;

PROCEDURE LinkComplianceItems(
	in_regulation_id				IN compliance_item.compliance_item_id%TYPE,
	in_requirement_id				IN compliance_item.compliance_item_id%TYPE
)
AS
	v_requirement_ref				compliance_item.reference_code%TYPE;
	v_requirement_title				compliance_item.title%TYPE;
	v_regulation_ref				compliance_item.reference_code%TYPE;
	v_regulation_title				compliance_item.title%TYPE;
	v_compliance_item_class			NUMBER(2);
BEGIN
	AssertComplianceMgr();

	BEGIN
		INSERT INTO compliance_req_reg (requirement_id, regulation_id)
		VALUES (in_requirement_id, in_regulation_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;

	SELECT reference_code, title
	  INTO v_requirement_ref, v_requirement_title
	  FROM compliance_item
	 WHERE compliance_item_id = in_requirement_id;

	INTERNAL_CreateLinkHistoryItem(
		in_compliance_item_id		=> in_regulation_id,
		in_change_reason			=> 'Linked to requirement ' || v_requirement_title || ' (Ref: ' || v_requirement_ref || ')'
	);
	SELECT reference_code, title
	  INTO v_regulation_ref, v_regulation_title
	  FROM compliance_item
	 WHERE compliance_item_id = in_regulation_id;

	INTERNAL_CreateLinkHistoryItem(
		in_compliance_item_id		=> in_requirement_id,
		in_change_reason			=> 'Linked to regulation ' || v_regulation_title || ' (Ref: ' || v_regulation_ref || ')'
	);
END;

PROCEDURE UnlinkComplianceItems(
	in_regulation_id				IN  compliance_item.compliance_item_id%TYPE,
	in_requirement_id				IN  compliance_item.compliance_item_id%TYPE
)
AS
	v_requirement_ref				compliance_item.reference_code%TYPE;
	v_regulation_ref				compliance_item.reference_code%TYPE;
	v_requirement_title				compliance_item.title%TYPE;
	v_regulation_title				compliance_item.title%TYPE;
BEGIN
	AssertComplianceMgr();

	DELETE FROM compliance_req_reg
	 WHERE requirement_id = in_requirement_id AND regulation_id  = in_regulation_id;

	SELECT reference_code, title
	  INTO v_requirement_ref, v_requirement_title
	  FROM compliance_item
	 WHERE compliance_item_id = in_requirement_id;

	INTERNAL_CreateLinkHistoryItem(
		in_compliance_item_id		=> in_regulation_id,
		in_change_reason			=> 'Unlinked from requirement ' || v_requirement_title || ' (Ref: ' || v_requirement_ref || ')'
	);

	SELECT reference_code, title
	  INTO v_regulation_ref, v_regulation_title
	  FROM compliance_item
	 WHERE compliance_item_id = in_regulation_id;

	INTERNAL_CreateLinkHistoryItem(
		in_compliance_item_id		=> in_requirement_id,
		in_change_reason			=> 'Unlinked from regulation ' || v_regulation_title || ' (Ref: ' || v_regulation_ref || ')'
	);

END;

PROCEDURE GetLinkableComplianceItems(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	in_search_phrase				IN  VARCHAR2,
	in_sort_by						IN  VARCHAR2,
	in_sort_dir						IN  VARCHAR2,
	in_row_count					IN  NUMBER,
	in_start_row					IN  NUMBER,
	out_total_rows					OUT NUMBER,
	out_cur							OUT security_pkg.t_output_cur
)
AS
	v_phrase						varchar2(255);
	v_item_type						NUMBER;
	v_compliance_item_ids 			security_pkg.T_SID_IDS;
	v_compliance_item_table			security.T_SID_TABLE;
BEGIN
	AssertComplianceMgr();

	v_phrase := LOWER(in_search_phrase);

	SELECT compliance_item_type
	  INTO v_item_type
	  FROM compliance_item ci
	 WHERE ci.compliance_item_id = in_compliance_item_id;

	SELECT DISTINCT ci.compliance_item_id
	  BULK COLLECT INTO v_compliance_item_ids
	  FROM compliance_item ci
	  JOIN compliance_item_description cid 
		ON ci.compliance_item_id = cid.compliance_item_id AND cid.app_sid = ci.app_sid
	  JOIN compliance_language cl
		ON cl.lang_id = cid.lang_id AND ci.app_sid = cid.app_sid
	  --This should go once we are passing the compliance_language selected
	  JOIN aspen2.lang l ON l.lang_id = cl.lang_id AND l.lang = 'en'
	 WHERE ci.compliance_item_type != v_item_type
	   AND ci.compliance_item_type IN (COMPLIANCE_REGULATION, COMPLIANCE_REQUIREMENT)
	   AND ci.compliance_item_id NOT IN (
				SELECT DISTINCT CASE WHEN v_item_type = COMPLIANCE_REQUIREMENT THEN REGULATION_ID ELSE REQUIREMENT_ID END
				  FROM csr.compliance_req_reg crr
				 WHERE crr.REQUIREMENT_ID = in_compliance_item_id OR crr.REGULATION_ID = in_compliance_item_id
			)
		AND ci.source = SOURCE_USER_DEFINED
		AND (LOWER(cid.title) LIKE '%'||v_phrase||'%'
			OR LOWER(cid.summary) LIKE '%'||v_phrase||'%'
			OR LOWER(cid.details) LIKE '%'||v_phrase||'%'
			OR LOWER(ci.user_comment) LIKE '%'||v_phrase||'%'
			OR LOWER(ci.reference_code) LIKE '%'||v_phrase||'%'
			OR LOWER(cid.citation) LIKE '%'||v_phrase||'%');

	v_compliance_item_table := security_pkg.SidArrayToTable(v_compliance_item_ids);

	OPEN out_cur FOR
		SELECT sorted_ci.compliance_item_id, sorted_ci.reference_code, sorted_ci.title, sorted_ci.summary
		  FROM (
			SELECT ci.compliance_item_id, ci.reference_code, cid.title, cid.summary,
				row_number() OVER (ORDER BY
					CASE
						WHEN in_sort_by='referenceCode' AND in_sort_dir = 'DESC' THEN TO_CHAR(ci.reference_code)
						WHEN in_sort_by='title' AND in_sort_dir = 'DESC' THEN TO_CHAR(ci.title)
					END DESC,
					CASE
						WHEN in_sort_by='referenceCode' AND in_sort_dir = 'ASC' THEN TO_CHAR(ci.reference_code)
						WHEN in_sort_by='title' AND in_sort_dir = 'ASC' THEN TO_CHAR(ci.title)
					END ASC
				) rn
			  FROM compliance_item ci
			  JOIN compliance_item_description cid 
				ON ci.compliance_item_id = cid.compliance_item_id AND cid.app_sid = ci.app_sid
			  JOIN compliance_language cl
				ON cl.lang_id = cid.lang_id AND ci.app_sid = cid.app_sid
			  --This should go once we are passing the compliance_language selected
			  JOIN aspen2.lang l ON l.lang_id = cl.lang_id AND l.lang = 'en'
			  JOIN TABLE(v_compliance_item_table) t ON ci.compliance_item_id = t.column_value
			) sorted_ci
		 WHERE rn-1 BETWEEN in_start_row AND in_start_row + in_row_count - 1
		 ORDER BY rn;

	 out_total_rows := CARDINALITY(v_compliance_item_table);
END;

PROCEDURE OnRegionMove(
	in_region_sid					IN	region.region_sid%TYPE
)
AS
BEGIN
	-- Just republish everything
	IF IsModuleEnabled = 1 THEN
		UNSEC_PublishComplianceItem(NULL);
	END IF;
END;

PROCEDURE OnRegionUpdate(
	in_region_sid					IN	region.region_sid%TYPE
)
AS
BEGIN
	IF IsModuleEnabled = 1 THEN
		UNSEC_PublishComplianceItem(NULL);
	END IF;
END;

PROCEDURE OnRegionCreate(
	in_region_sid					IN	region.region_sid%TYPE
)
AS
BEGIN
	IF IsModuleEnabled = 1 THEN
		UNSEC_PublishComplianceItem(NULL);
	END IF;
END;

PROCEDURE GetAllComplianceLevelsPaged(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_has_capability	NUMBER(1) := 0;
	v_comp_id_table		security.T_SID_TABLE;
BEGIN
	IF csr_data_pkg.CheckCapability('Manage compliance items') THEN
		v_has_capability := 1;
	END IF;

	SELECT ci.compliance_item_id
	  BULK COLLECT INTO v_comp_id_table
	  FROM compliance_item ci
	  JOIN compliance_item_status cis ON cis.compliance_item_status_id = ci.compliance_item_status_id
	  JOIN compliance_regulation creg ON creg.compliance_item_id = ci.compliance_item_id
	 WHERE creg.compliance_item_id IS NOT NULL
	   AND (in_search IS NULL OR (
			LOWER(ci.title) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(ci.reference_code) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cis.description) LIKE '%'||LOWER(in_search)||'%'
	   ))
	   AND cis.description NOT IN ('retired')
	   AND (v_has_capability = 1 OR EXISTS(
			SELECT 1
			  FROM v$my_compliance_items mci
			 WHERE ci.compliance_item_id = mci.compliance_item_id
	   ))
	   AND EXISTS (
			SELECT NULL FROM compliance_item_region cir
			  JOIN region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
			 WHERE cir.compliance_item_id = ci.compliance_item_id AND cir.app_sid = ci.app_sid
	   )
	  GROUP BY ci.compliance_item_id;

	out_total := v_comp_id_table.COUNT;

	OPEN out_cur FOR
		SELECT compliance_item_id, regions_count, type_label, status, title, reference_code, adoption_dtm, updated_dtm, pct_compliant, rag_colour, rn
		  FROM (
			SELECT compliance_item_id, regions_count, type_label, status, title, reference_code, adoption_dtm, updated_dtm, pct_compliant, rag_colour, rownum rn
			  FROM (
				SELECT ci.compliance_item_id, regions_count.total_items regions_count,
						CASE
							WHEN creg.is_policy = 0 THEN 'Regulation'
							WHEN creg.is_policy = 1 THEN 'Policy'
						END type_label,
						cis.description status, ci.title, ci.reference_code, creg.adoption_dtm, ci.updated_dtm, pct_compliant,
						(SELECT DISTINCT FIRST_VALUE(text_colour)
						   OVER (ORDER BY st.max_value ASC) AS text_colour
						   FROM compliance_options co
						   JOIN score_threshold st ON co.score_type_id = st.score_type_id AND st.app_sid = co.app_sid
						  WHERE co.app_sid = security.security_pkg.GetApp
						    AND pct_compliant <= st.max_value) rag_colour
				  FROM compliance_item ci
				  JOIN TABLE (v_comp_id_table) cit ON ci.compliance_item_id = cit.column_value
				  JOIN compliance_item_status cis ON cis.compliance_item_status_id = ci.compliance_item_status_id
				  JOIN compliance_regulation creg ON creg.compliance_item_id = ci.compliance_item_id
				  LEFT JOIN (
						SELECT compliance_item_id, total_items, ROUND(DECODE(total_items, 0, 0, (100*compliant_items/total_items)), 0)  pct_compliant
						FROM (
							SELECT cir.compliance_item_id, COUNT(*) total_items, SUM(DECODE(fsn.label, 'Compliant', 1, 0)) compliant_items
							  FROM compliance_item_region cir
							  JOIN v$my_compliance_items mci ON cir.flow_item_id = mci.flow_item_id
							  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id
							  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
							  JOIN flow_state_nature fsn ON fs.flow_state_nature_id = fsn.flow_state_nature_id
							  JOIN region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
							 WHERE fsn.flow_alert_class = 'regulation'
							   AND LOWER(fsn.label) NOT IN ('retired', 'not applicable')
							 GROUP BY cir.compliance_item_id
						)
				  ) regions_count ON ci.compliance_item_id = regions_count.compliance_item_id
				 WHERE creg.compliance_item_id IS NOT NULL
				   AND (v_has_capability = 1 OR EXISTS(
						SELECT 1
						  FROM v$my_compliance_items mci
						 WHERE ci.compliance_item_id = mci.compliance_item_id
				   ))
				 ORDER BY pct_compliant
				)
			)
		 WHERE rn BETWEEN in_start_row AND in_start_row + in_page_size -1;
END;

FUNCTION GetChangeTypeForEnhesa (
	in_enhesa_change_type			IN  NUMBER
) RETURN NUMBER
AS
	v_change_type	compliance_item_change_type.compliance_item_change_type_id%TYPE;
BEGIN
	SELECT compliance_item_change_type_id
	  INTO v_change_type
	  FROM compliance_item_change_type
	 WHERE enhesa_id = in_enhesa_change_type
	   AND source = SOURCE_ENHESA;

	RETURN v_change_type;
END;

PROCEDURE GetRegionDataFromSourceData (
	in_source					IN	compliance_region_map.compliance_item_source_id%TYPE,
	in_source_country_code		IN	compliance_region_map.source_country%TYPE,
	in_source_region_code		IN	compliance_region_map.source_region%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_mapped_country			compliance_region_map.source_country%TYPE;
BEGIN
	--There is probably a better way I can't think of to do this.

	-- check for country map only first

	SELECT NVL(MIN(country), in_source_country_code)
	  INTO v_mapped_country
	  FROM csr.compliance_region_map
	 WHERE source_country = UPPER(in_source_country_code)
	   AND source_region IS null
	   AND region IS null;

	OPEN out_cur FOR
		SELECT NVL(map_country, country) country, NVL(map_region, region) region, region_group
		FROM (
			SELECT country map_country, region map_region, NULL country, NULL region, NULL region_group
			  FROM compliance_region_map
			 WHERE compliance_item_source_id = in_source
			   AND source_country = v_mapped_country
			   AND source_region = in_source_region_code
			 UNION
			SELECT NULL map_country, NULL map_region, c.country, r.region, NULL region_group
			  FROM postcode.country c
			  LEFT JOIN postcode.region r ON c.country = r.country AND DECODE(LOWER(r.region), LOWER(in_source_region_code), 1, 0) = 1
			 WHERE c.country = LOWER(v_mapped_country)
			 UNION
			SELECT NULL map_country, NULL map_region, country, NULL region, region_group_id region_group
			  FROM region_group_region
			 WHERE country = LOWER(v_mapped_country)
			   AND region_group_id = in_source_region_code
			UNION
			--Finally, ensure the odd country only cases get dealt with (currently Kosovo, East Timor + North Korea...)
			SELECT country map_country, region map_region, NULL country, NULL region, NULL region_group
			  FROM compliance_region_map
			 WHERE compliance_item_source_id = in_source
			   AND source_country = in_source_country_code
			   AND source_region = in_source_region_code
		);
END;

PROCEDURE AddIssue(
	in_flow_item_id					IN  issue_compliance_region.flow_item_id%TYPE,
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
	v_issue_compliance_region_id 	issue_compliance_region.issue_compliance_region_id%TYPE;
	v_issue_type_id					issue.issue_type_id%TYPE;
	v_permit_id						compliance_permit.compliance_permit_id%TYPE;
	v_due_dtm						issue.due_dtm%TYPE;
BEGIN
	INTERNAL_AssertCanEditFlowItem(in_flow_item_id);

	-- Select issue type based on compliance item type
	SELECT CASE WHEN ci.compliance_item_type = COMPLIANCE_CONDITION
			   THEN csr_data_pkg.ISSUE_PERMIT
			   ELSE csr_data_pkg.ISSUE_COMPLIANCE
		   END,
		   compliance_permit_id
	  INTO v_issue_type_id, v_permit_id
	  FROM compliance_item_region cir
	  LEFT JOIN compliance_item ci
		ON cir.app_sid = ci.app_sid
	   AND cir.compliance_item_id = ci.compliance_item_id
	  LEFT JOIN compliance_permit_condition cpc
		ON cpc.app_sid = cir.app_sid
	   AND cpc.compliance_item_id = cir.compliance_item_id
	 WHERE cir.flow_item_id = in_flow_item_id;

	issue_pkg.CreateIssue(
		in_label					=> in_label,
		in_description				=> in_description,
		in_source_label				=> NULL,
		in_issue_type_id			=> v_issue_type_id,
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

	IF in_is_critical != 0 THEN
		INTERNAL_AddManagersToIssue(in_issue_id => out_issue_id);
	END IF;

	v_issue_compliance_region_id := issue_compliance_region_id_seq.NEXTVAL;

	INSERT INTO issue_compliance_region (issue_compliance_region_id, flow_item_id)
	VALUES (v_issue_compliance_region_id, in_flow_item_id);

	UPDATE issue
	   SET issue_compliance_region_id = v_issue_compliance_region_id,
		   permit_id = v_permit_id
	 WHERE issue_id = out_issue_id;

	issue_pkg.RefreshRelativeDueDtm(in_issue_id => out_issue_id);

	INTERNAL_AddAuditLogEntry(in_flow_item_id, 'New action {0} added.', in_label, null, null, null);
END;

PROCEDURE GetComplianceRagThresholds (
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security other than app_sid check, its just a bunch of labels and hex colours
	OPEN out_cur FOR
		SELECT st.description label, TRIM(TO_CHAR(st.text_colour, 'XXXXXX')) colour
		  FROM compliance_options co
		  JOIN score_threshold st ON co.score_type_id = st.score_type_id;
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
				JOIN region_role_member rrr on cir.region_sid = rrr.region_sid and rrr.role_sid = in_role_sid
				JOIN csr_user cu on rrr.user_sid = cu.csr_user_sid
				JOIN v$region r on cir.region_sid = r.region_sid AND cir.app_sid = r.app_sid AND r.active = 1
				WHERE in_search IS NULL OR (
					LOWER(cu.full_name) LIKE '%'||LOWER(in_search)||'%'
					OR LOWER(r.description) LIKE '%'||LOWER(in_search)||'%'
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
						SUM(DECODE(fs.flow_state_nature_id, csr_data_pkg.NATURE_REGULATION_NEW, 1, csr_data_pkg.NATURE_REQUIREMENT_NEW, 1, 0)) count_new,
						SUM(DECODE(fs.flow_state_nature_id, csr_data_pkg.NATURE_REGULATION_UPDATED, 1, csr_data_pkg.NATURE_REQUIREMENT_UPDATED, 1, 0)) count_updated,
						SUM(DECODE(fs.flow_state_nature_id, csr_data_pkg.NATURE_REGULATION_ACTION_REQ, 1, csr_data_pkg.NATURE_REQUIREMENT_ACTION_REQ, 1, 0)) count_action_req,
						SUM(DECODE(fs.flow_state_nature_id, csr_data_pkg.NATURE_REGULATION_COMPLIANT, 1, csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT, 1, 0)) count_compliant
				  FROM compliance_item_region cir
				  JOIN v$my_compliance_items mci ON cir.flow_item_id = mci.flow_item_id
				  JOIN temp_comp_region_lvl_ids tcrli ON tcrli.region_sid = cir.region_sid
				  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id
				  JOIN flow_state fs on fi.current_state_id = fs.flow_state_id
				  JOIN region r on cir.region_sid = r.region_sid AND cir.app_sid = r.app_sid AND r.active = 1
				 GROUP BY cir.region_sid, tcrli.region_description, tcrli.mgr_full_name
				) cir
			  JOIN v$compliance_item_rag cirag on cir.region_sid = cirag.region_sid
			 ORDER BY pct_compliant
			)
		 WHERE rn BETWEEN in_start_row AND in_start_row + in_page_size -1;
END;

PROCEDURE GetEnhesaRolloutInfo(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cir.compliance_item_id, cir.country, cir.region, cir.country_group, cir.region_group, cir.rollout_dtm, cir.rollout_pending, cir.compliance_item_rollout_id, cir.source_country, cir.source_region
		  FROM compliance_item_rollout cir
		  JOIN compliance_item ci on cir.compliance_item_id = ci.compliance_item_id
		 WHERE ci.source = SOURCE_ENHESA;
END;

PROCEDURE GetEnhesaRegionMappings(
	in_source_country				IN	VARCHAR2,
	in_source_region				IN	VARCHAR2,
	in_alert_sent					IN	NUMBER,
	out_map_cur						OUT SYS_REFCURSOR,
	out_item_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No sensitive information here
	OPEN out_map_cur FOR
		SELECT RTRIM(enhesa_country) enhesa_country, RTRIM(enhesa_region) enhesa_region, alert_sent
		  FROM compliance_enhesa_map
		 WHERE (in_source_country IS NULL OR in_source_country = enhesa_country)
		   AND (in_source_region IS NULL OR in_source_region = enhesa_region)
		   AND (in_alert_sent IS NULL
				OR (in_alert_sent = 0 AND alert_sent IS NULL)
				OR (in_alert_sent <> 0 AND alert_sent IS NOT NULL));

	OPEN out_item_cur FOR
		SELECT RTRIM(emi.enhesa_country) enhesa_country, RTRIM(emi.enhesa_region) enhesa_region, emi.region_sid,
			   r.description region_description
		  FROM compliance_enhesa_map_item emi
		  JOIN v$region r ON emi.app_sid = r.app_sid AND emi.region_sid = r.region_sid
		 WHERE (emi.enhesa_country, emi.enhesa_region) IN (
			SELECT enhesa_country, enhesa_region
			  FROM compliance_enhesa_map
			 WHERE (in_source_country IS NULL OR in_source_country = RTRIM(enhesa_country))
			   AND (in_source_region IS NULL OR in_source_region = RTRIM(enhesa_region))
			   AND (in_alert_sent IS NULL
					OR (in_alert_sent = 0 AND alert_sent IS NULL)
					OR (in_alert_sent <> 0 AND alert_sent IS NOT NULL))
		);
END;

PROCEDURE SaveEnhesaRegionMappings(
	in_source_country				IN	VARCHAR2,
	in_source_region				IN	VARCHAR2,
	in_alert_sent					IN  DATE,
	in_regions						IN	security_pkg.T_SID_IDS
)
AS
	v_region_table					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_regions);
	v_count NUMBER(10);
BEGIN
	AssertComplianceMgr();

	BEGIN
		INSERT INTO compliance_enhesa_map (enhesa_country, enhesa_region, alert_sent)
		VALUES (in_source_country, in_source_region, in_alert_sent);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE compliance_enhesa_map
			   SET alert_sent = in_alert_sent
			 WHERE enhesa_country = in_source_country
			   AND enhesa_region = in_source_region;
	END;

	DELETE FROM compliance_enhesa_map_item
	 WHERE enhesa_country = RPAD(in_source_country, 3)
	   AND enhesa_region = RPAD(in_source_region, 3);

	INSERT INTO compliance_enhesa_map_item (enhesa_country, enhesa_region, region_sid)
		SELECT DISTINCT in_source_country, in_source_region, column_value
		  FROM TABLE(v_region_table);
END;

PROCEDURE SaveEnhesaSiteType(
	in_site_type_id					IN	enhesa_site_type.site_type_id%TYPE,
	in_label						IN	enhesa_site_type.label%TYPE,
	out_site_type_cur				OUT	SYS_REFCURSOR
)
AS
	v_site_type_id					enhesa_site_type.site_type_id%TYPE;
BEGIN
	AssertComplianceMgr();
	
	IF in_site_type_id IS NULL THEN
		INSERT INTO enhesa_site_type(site_type_id, label)
		VALUES(enhesa_site_type_id_seq.NEXTVAL, in_label)
		RETURNING site_type_id INTO v_site_type_id;
	ELSE
		UPDATE enhesa_site_type
		   SET label = in_label
		 WHERE site_type_id = in_site_type_id;

		 v_site_type_id := in_site_type_id;
	END IF;

	OPEN out_site_type_cur FOR
		SELECT site_type_id, label
		  FROM enhesa_site_type
		 WHERE site_type_id = v_site_type_id;
END;

PROCEDURE DeleteEnhesaSiteType(
	in_site_type_id					IN	enhesa_site_type.site_type_id%TYPE
)
AS
BEGIN
	AssertComplianceMgr();
	
	DELETE FROM enhesa_site_type_heading
	 WHERE site_type_id = in_site_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM enhesa_site_type
	 WHERE site_type_id = in_site_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SaveEnhesaSiteTypeMap(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	in_site_type_heading_id			IN	enhesa_site_type_heading.site_type_heading_id%TYPE,
	in_heading_code					IN	enhesa_site_type_heading.heading_code%TYPE
)
AS
	v_throwaway_cur					SYS_REFCURSOR;
BEGIN
	SaveEnhesaSiteTypeMap(in_site_type_id, in_site_type_heading_id, in_heading_code, v_throwaway_cur);
END;

PROCEDURE SaveEnhesaSiteTypeMap(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	in_site_type_heading_id			IN	enhesa_site_type_heading.site_type_heading_id%TYPE,
	in_heading_code					IN	enhesa_site_type_heading.heading_code%TYPE,
	out_site_type_cur				OUT	SYS_REFCURSOR
)
AS
	v_site_type_heading_id			enhesa_site_type_heading.site_type_heading_id%TYPE;
BEGIN
	AssertComplianceMgr();
	
	IF in_site_type_heading_id IS NULL THEN
		INSERT INTO enhesa_site_type_heading(site_type_id, site_type_heading_id, heading_code)
		VALUES(in_site_type_id, enhesa_site_typ_heading_id_seq.NEXTVAL, in_heading_code)
		RETURNING site_type_heading_id INTO v_site_type_heading_id;
	ELSE
		UPDATE enhesa_site_type_heading
		   SET heading_code = in_heading_code
		 WHERE site_type_heading_id = in_site_type_heading_id;

		 v_site_type_heading_id := in_site_type_heading_id;
	END IF;

	OPEN out_site_type_cur FOR
		SELECT site_type_heading_id, heading_code
		  FROM enhesa_site_type_heading
		 WHERE site_type_heading_id = v_site_type_heading_id;
END;

PROCEDURE DeleteEnhesaSiteTypeMap(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	in_site_type_heading_id			IN	enhesa_site_type_heading.site_type_heading_id%TYPE
)
AS
BEGIN
	AssertComplianceMgr();

	DELETE FROM enhesa_site_type_heading
	 WHERE site_type_id = in_site_type_id
	   AND site_type_heading_id = in_site_type_heading_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetEnhesaSiteTypeMappings(
	out_site_type_cur				OUT	SYS_REFCURSOR,
	out_headings_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	AssertComplianceMgr();
	
	OPEN out_site_type_cur FOR
		SELECT site_type_id, label, TRIM(LOWER(label)) || site_type_id lookup_key
		  FROM enhesa_site_type;
		 
	OPEN out_headings_cur FOR
		SELECT site_type_id, site_type_heading_id, heading_code
		  FROM enhesa_site_type_heading
		 ORDER BY site_type_id, heading_code;
END;

PROCEDURE GetEnhesaSiteTypeMapping(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	out_site_type_cur				OUT	SYS_REFCURSOR,
	out_headings_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	AssertComplianceMgr();
	
	OPEN out_site_type_cur FOR
		SELECT site_type_id, label, TRIM(LOWER(label)) || site_type_id lookup_key
		  FROM enhesa_site_type
		 WHERE site_type_id = in_site_type_id;
		 
	OPEN out_headings_cur FOR
		SELECT site_type_id, site_type_heading_id, heading_code
		  FROM enhesa_site_type_heading
		 WHERE site_type_id = in_site_type_id
		 ORDER BY heading_code;
END;

PROCEDURE PopulateSiteHeadingCodes
AS
	v_curr_type_id		NUMBER(10);
	v_office_label		enhesa_site_type.label%TYPE := 'Office';
	v_warehouse_label	enhesa_site_type.label%TYPE := 'Warehouse';
	v_industrial_label	enhesa_site_type.label%TYPE := 'Industrial';
	PROCEDURE AddHeadingCode(
		in_site_type_id				NUMBER,
		in_heading_code				VARCHAR2
	) AS
		v_id	NUMBER(10);
	BEGIN
		SELECT MIN(site_type_heading_id)
		  INTO v_id
		  FROM enhesa_site_type_heading
		 WHERE site_type_id = in_site_type_id
		   AND heading_code = in_heading_code;
		
		IF v_id IS NULL THEN 
			INSERT INTO enhesa_site_type_heading
			(site_type_heading_id, site_type_id, heading_code)
			VALUES
			(enhesa_site_typ_heading_id_seq.nextval, in_site_type_id, in_heading_code);
		END IF;
	END;
BEGIN
	SELECT MIN(site_type_id)
	  INTO v_curr_type_id
	  FROM enhesa_site_type
	 WHERE label = v_office_label;
	
	IF v_curr_type_id IS NULL THEN
		v_curr_type_id := enhesa_site_type_id_seq.nextval;
		INSERT INTO enhesa_site_type (site_type_id, label) VALUES (v_curr_type_id, v_office_label);
	ELSE
		DELETE FROM enhesa_site_type_heading
		 WHERE site_type_id = v_curr_type_id;	
	END IF;
	
	BEGIN
		AddHeadingCode(v_curr_type_id, '0201');
		AddHeadingCode(v_curr_type_id, '020101');
		AddHeadingCode(v_curr_type_id, '020102');
		AddHeadingCode(v_curr_type_id, '020103');
		AddHeadingCode(v_curr_type_id, '020104');
		AddHeadingCode(v_curr_type_id, '020105');
		AddHeadingCode(v_curr_type_id, '020106');
		AddHeadingCode(v_curr_type_id, '020107');
		AddHeadingCode(v_curr_type_id, '0202');
		AddHeadingCode(v_curr_type_id, '020201');
		AddHeadingCode(v_curr_type_id, '020203');
		AddHeadingCode(v_curr_type_id, '0203');
		AddHeadingCode(v_curr_type_id, '0204');
		AddHeadingCode(v_curr_type_id, '020401');
		AddHeadingCode(v_curr_type_id, '020402');
		AddHeadingCode(v_curr_type_id, '020403');
		AddHeadingCode(v_curr_type_id, '0301'); -- This should be excluded but that would break things
		AddHeadingCode(v_curr_type_id, '030103');
		AddHeadingCode(v_curr_type_id, '030104');
		AddHeadingCode(v_curr_type_id, '030106');
		AddHeadingCode(v_curr_type_id, '030108');
		AddHeadingCode(v_curr_type_id, '0302'); -- This should be excluded but that would break things
		AddHeadingCode(v_curr_type_id, '030202');
		AddHeadingCode(v_curr_type_id, '030203');
		AddHeadingCode(v_curr_type_id, '030204');
		AddHeadingCode(v_curr_type_id, '030206');
		AddHeadingCode(v_curr_type_id, '0303');
		AddHeadingCode(v_curr_type_id, '030301');
		AddHeadingCode(v_curr_type_id, '030302');
		AddHeadingCode(v_curr_type_id, '030303');
		AddHeadingCode(v_curr_type_id, '0401');
		AddHeadingCode(v_curr_type_id, '040101');
		AddHeadingCode(v_curr_type_id, '040102');
		AddHeadingCode(v_curr_type_id, '040103');
		AddHeadingCode(v_curr_type_id, '040104');
		AddHeadingCode(v_curr_type_id, '0402');
		AddHeadingCode(v_curr_type_id, '040201');
		AddHeadingCode(v_curr_type_id, '040202');
		AddHeadingCode(v_curr_type_id, '040203');
		AddHeadingCode(v_curr_type_id, '040204');
		AddHeadingCode(v_curr_type_id, '040205');
		AddHeadingCode(v_curr_type_id, '040206');
		AddHeadingCode(v_curr_type_id, '0501');
		AddHeadingCode(v_curr_type_id, '050101');
		AddHeadingCode(v_curr_type_id, '050102');
		AddHeadingCode(v_curr_type_id, '050104');
		AddHeadingCode(v_curr_type_id, '050105');
		AddHeadingCode(v_curr_type_id, '050106');
		AddHeadingCode(v_curr_type_id, '050107');
		AddHeadingCode(v_curr_type_id, '0502');
		AddHeadingCode(v_curr_type_id, '050201');
		AddHeadingCode(v_curr_type_id, '050202');
		AddHeadingCode(v_curr_type_id, '050203');
		AddHeadingCode(v_curr_type_id, '050204');
		AddHeadingCode(v_curr_type_id, '050205');
		AddHeadingCode(v_curr_type_id, '050206');
		AddHeadingCode(v_curr_type_id, '050209');
		AddHeadingCode(v_curr_type_id, '0602');
		AddHeadingCode(v_curr_type_id, '060201');
		AddHeadingCode(v_curr_type_id, '060202');
		AddHeadingCode(v_curr_type_id, '0603');
		AddHeadingCode(v_curr_type_id, '060301');
		AddHeadingCode(v_curr_type_id, '060302');
		AddHeadingCode(v_curr_type_id, '060303');
		AddHeadingCode(v_curr_type_id, '060304');
		AddHeadingCode(v_curr_type_id, '060305');
		AddHeadingCode(v_curr_type_id, '060308');
		AddHeadingCode(v_curr_type_id, '0604');
		AddHeadingCode(v_curr_type_id, '0605');
		AddHeadingCode(v_curr_type_id, '0701');
		AddHeadingCode(v_curr_type_id, '070101');
		AddHeadingCode(v_curr_type_id, '070102');
		AddHeadingCode(v_curr_type_id, '0703');
		AddHeadingCode(v_curr_type_id, '0704');
		AddHeadingCode(v_curr_type_id, '0801');
		AddHeadingCode(v_curr_type_id, '080101');
		AddHeadingCode(v_curr_type_id, '080102');
		AddHeadingCode(v_curr_type_id, '080103');
		AddHeadingCode(v_curr_type_id, '080104');
		AddHeadingCode(v_curr_type_id, '080105');
		AddHeadingCode(v_curr_type_id, '0802');
		AddHeadingCode(v_curr_type_id, '080201');
		AddHeadingCode(v_curr_type_id, '080202');
		AddHeadingCode(v_curr_type_id, '080203');
		AddHeadingCode(v_curr_type_id, '0803');
		AddHeadingCode(v_curr_type_id, '080301');
		AddHeadingCode(v_curr_type_id, '080302');
		AddHeadingCode(v_curr_type_id, '0804');
		AddHeadingCode(v_curr_type_id, '080401');
		AddHeadingCode(v_curr_type_id, '080402');
		AddHeadingCode(v_curr_type_id, '080403');
		AddHeadingCode(v_curr_type_id, '080404');
		AddHeadingCode(v_curr_type_id, '080405');
		AddHeadingCode(v_curr_type_id, '080406');
		AddHeadingCode(v_curr_type_id, '080407');
		AddHeadingCode(v_curr_type_id, '0805');
		AddHeadingCode(v_curr_type_id, '080501');
		AddHeadingCode(v_curr_type_id, '080502');
		AddHeadingCode(v_curr_type_id, '0901');
		AddHeadingCode(v_curr_type_id, '0902');
		AddHeadingCode(v_curr_type_id, '0903');
		AddHeadingCode(v_curr_type_id, '0904');
		AddHeadingCode(v_curr_type_id, '0905');
		AddHeadingCode(v_curr_type_id, '090501');
		AddHeadingCode(v_curr_type_id, '090502');
		AddHeadingCode(v_curr_type_id, '0906');
		AddHeadingCode(v_curr_type_id, '0907');
		AddHeadingCode(v_curr_type_id, '0908');
		AddHeadingCode(v_curr_type_id, '0909');
		AddHeadingCode(v_curr_type_id, '0912');
		AddHeadingCode(v_curr_type_id, '1001');
		AddHeadingCode(v_curr_type_id, '100101');
		AddHeadingCode(v_curr_type_id, '100102');
		AddHeadingCode(v_curr_type_id, '100103');
		AddHeadingCode(v_curr_type_id, '1101');
		AddHeadingCode(v_curr_type_id, '1102');
		AddHeadingCode(v_curr_type_id, '110201');
		AddHeadingCode(v_curr_type_id, '110202');
		AddHeadingCode(v_curr_type_id, '1103');
		AddHeadingCode(v_curr_type_id, '1104');
		AddHeadingCode(v_curr_type_id, '110401');
		AddHeadingCode(v_curr_type_id, '110402');
		AddHeadingCode(v_curr_type_id, '110403');
		AddHeadingCode(v_curr_type_id, '110404');
		AddHeadingCode(v_curr_type_id, '110405');
		AddHeadingCode(v_curr_type_id, '110406');
		AddHeadingCode(v_curr_type_id, '110407');
		AddHeadingCode(v_curr_type_id, '110408');
		AddHeadingCode(v_curr_type_id, '110409');
		AddHeadingCode(v_curr_type_id, '1105');
		AddHeadingCode(v_curr_type_id, '110501');
		AddHeadingCode(v_curr_type_id, '110502');
		AddHeadingCode(v_curr_type_id, '110503');
		AddHeadingCode(v_curr_type_id, '1106');
		AddHeadingCode(v_curr_type_id, '110601');
		AddHeadingCode(v_curr_type_id, '110602');
		AddHeadingCode(v_curr_type_id, '110603');
		AddHeadingCode(v_curr_type_id, '110604');
		AddHeadingCode(v_curr_type_id, '110607');
		AddHeadingCode(v_curr_type_id, '110608');
		AddHeadingCode(v_curr_type_id, '110609');
		AddHeadingCode(v_curr_type_id, '1107');
		AddHeadingCode(v_curr_type_id, '110701');
		AddHeadingCode(v_curr_type_id, '110702');
	END;

	SELECT MIN(site_type_id)
	  INTO v_curr_type_id
	  FROM enhesa_site_type
	 WHERE label = v_warehouse_label;
	
	IF v_curr_type_id IS NULL THEN
		v_curr_type_id := enhesa_site_type_id_seq.nextval;
		INSERT INTO enhesa_site_type (site_type_id, label) VALUES (v_curr_type_id, v_warehouse_label);
	ELSE
		DELETE FROM enhesa_site_type_heading
		 WHERE site_type_id = v_curr_type_id;	
	END IF;
	
	BEGIN
		AddHeadingCode(v_curr_type_id, '0201');
		AddHeadingCode(v_curr_type_id, '020101');
		AddHeadingCode(v_curr_type_id, '020102');
		AddHeadingCode(v_curr_type_id, '020103');
		AddHeadingCode(v_curr_type_id, '020104');
		AddHeadingCode(v_curr_type_id, '020105');
		AddHeadingCode(v_curr_type_id, '020106');
		AddHeadingCode(v_curr_type_id, '020107');
		AddHeadingCode(v_curr_type_id, '0202');
		AddHeadingCode(v_curr_type_id, '020201');
		AddHeadingCode(v_curr_type_id, '020202');
		AddHeadingCode(v_curr_type_id, '020203');
		AddHeadingCode(v_curr_type_id, '020204');
		AddHeadingCode(v_curr_type_id, '020205');
		AddHeadingCode(v_curr_type_id, '0203');
		AddHeadingCode(v_curr_type_id, '0204');
		AddHeadingCode(v_curr_type_id, '020401');
		AddHeadingCode(v_curr_type_id, '020402');
		AddHeadingCode(v_curr_type_id, '020403');
		AddHeadingCode(v_curr_type_id, '0301');
		AddHeadingCode(v_curr_type_id, '030101');
		AddHeadingCode(v_curr_type_id, '030102');
		AddHeadingCode(v_curr_type_id, '030103');
		AddHeadingCode(v_curr_type_id, '030104');
		AddHeadingCode(v_curr_type_id, '030105');
		AddHeadingCode(v_curr_type_id, '030106');
		AddHeadingCode(v_curr_type_id, '030108');
		AddHeadingCode(v_curr_type_id, '0302');
		AddHeadingCode(v_curr_type_id, '030201');
		AddHeadingCode(v_curr_type_id, '030202');
		AddHeadingCode(v_curr_type_id, '030203');
		AddHeadingCode(v_curr_type_id, '030204');
		AddHeadingCode(v_curr_type_id, '030206');
		AddHeadingCode(v_curr_type_id, '0303');
		AddHeadingCode(v_curr_type_id, '030301');
		AddHeadingCode(v_curr_type_id, '030302');
		AddHeadingCode(v_curr_type_id, '030303');
		AddHeadingCode(v_curr_type_id, '0401');
		AddHeadingCode(v_curr_type_id, '040101');
		AddHeadingCode(v_curr_type_id, '040102');
		AddHeadingCode(v_curr_type_id, '040103');
		AddHeadingCode(v_curr_type_id, '040104');
		AddHeadingCode(v_curr_type_id, '040105');
		AddHeadingCode(v_curr_type_id, '0402');
		AddHeadingCode(v_curr_type_id, '040201');
		AddHeadingCode(v_curr_type_id, '040202');
		AddHeadingCode(v_curr_type_id, '040203');
		AddHeadingCode(v_curr_type_id, '040204');
		AddHeadingCode(v_curr_type_id, '040205');
		AddHeadingCode(v_curr_type_id, '040206');
		AddHeadingCode(v_curr_type_id, '040207');
		AddHeadingCode(v_curr_type_id, '0501');
		AddHeadingCode(v_curr_type_id, '050101');
		AddHeadingCode(v_curr_type_id, '050102');
		AddHeadingCode(v_curr_type_id, '050103');
		AddHeadingCode(v_curr_type_id, '050104');
		AddHeadingCode(v_curr_type_id, '050105');
		AddHeadingCode(v_curr_type_id, '050106');
		AddHeadingCode(v_curr_type_id, '050107');
		AddHeadingCode(v_curr_type_id, '0502');
		AddHeadingCode(v_curr_type_id, '050201');
		AddHeadingCode(v_curr_type_id, '050202');
		AddHeadingCode(v_curr_type_id, '050203');
		AddHeadingCode(v_curr_type_id, '050204');
		AddHeadingCode(v_curr_type_id, '050205');
		AddHeadingCode(v_curr_type_id, '050206');
		AddHeadingCode(v_curr_type_id, '050207');
		AddHeadingCode(v_curr_type_id, '050209');
		AddHeadingCode(v_curr_type_id, '0503');
		AddHeadingCode(v_curr_type_id, '0504');
		AddHeadingCode(v_curr_type_id, '050401');
		AddHeadingCode(v_curr_type_id, '0602');
		AddHeadingCode(v_curr_type_id, '060201');
		AddHeadingCode(v_curr_type_id, '060202');
		AddHeadingCode(v_curr_type_id, '0603');
		AddHeadingCode(v_curr_type_id, '060305');
		AddHeadingCode(v_curr_type_id, '060308');
		AddHeadingCode(v_curr_type_id, '0604');
		AddHeadingCode(v_curr_type_id, '0605');
		AddHeadingCode(v_curr_type_id, '0701');
		AddHeadingCode(v_curr_type_id, '070101');
		AddHeadingCode(v_curr_type_id, '070102');
		AddHeadingCode(v_curr_type_id, '0702');
		AddHeadingCode(v_curr_type_id, '070201');
		AddHeadingCode(v_curr_type_id, '070202');
		AddHeadingCode(v_curr_type_id, '070206');
		AddHeadingCode(v_curr_type_id, '0703');
		AddHeadingCode(v_curr_type_id, '0704');
		AddHeadingCode(v_curr_type_id, '0705');
		AddHeadingCode(v_curr_type_id, '0801');
		AddHeadingCode(v_curr_type_id, '080101');
		AddHeadingCode(v_curr_type_id, '080102');
		AddHeadingCode(v_curr_type_id, '080103');
		AddHeadingCode(v_curr_type_id, '080104');
		AddHeadingCode(v_curr_type_id, '080105');
		AddHeadingCode(v_curr_type_id, '0802');
		AddHeadingCode(v_curr_type_id, '080201');
		AddHeadingCode(v_curr_type_id, '080202');
		AddHeadingCode(v_curr_type_id, '080203');
		AddHeadingCode(v_curr_type_id, '0803');
		AddHeadingCode(v_curr_type_id, '080301');
		AddHeadingCode(v_curr_type_id, '080302');
		AddHeadingCode(v_curr_type_id, '0804');
		AddHeadingCode(v_curr_type_id, '080401');
		AddHeadingCode(v_curr_type_id, '080402');
		AddHeadingCode(v_curr_type_id, '080403');
		AddHeadingCode(v_curr_type_id, '080404');
		AddHeadingCode(v_curr_type_id, '080405');
		AddHeadingCode(v_curr_type_id, '080406');
		AddHeadingCode(v_curr_type_id, '080407');
		AddHeadingCode(v_curr_type_id, '0805');
		AddHeadingCode(v_curr_type_id, '080501');
		AddHeadingCode(v_curr_type_id, '080502');
		AddHeadingCode(v_curr_type_id, '0901');
		AddHeadingCode(v_curr_type_id, '0902');
		AddHeadingCode(v_curr_type_id, '0903');
		AddHeadingCode(v_curr_type_id, '0904');
		AddHeadingCode(v_curr_type_id, '0905');
		AddHeadingCode(v_curr_type_id, '090501');
		AddHeadingCode(v_curr_type_id, '090502');
		AddHeadingCode(v_curr_type_id, '090503');
		AddHeadingCode(v_curr_type_id, '090504');
		AddHeadingCode(v_curr_type_id, '0906');
		AddHeadingCode(v_curr_type_id, '0907');
		AddHeadingCode(v_curr_type_id, '0908');
		AddHeadingCode(v_curr_type_id, '0909');
		AddHeadingCode(v_curr_type_id, '0910');
		AddHeadingCode(v_curr_type_id, '0911');
		AddHeadingCode(v_curr_type_id, '0912');
		AddHeadingCode(v_curr_type_id, '1001');
		AddHeadingCode(v_curr_type_id, '100101');
		AddHeadingCode(v_curr_type_id, '100102');
		AddHeadingCode(v_curr_type_id, '100103');
		AddHeadingCode(v_curr_type_id, '1002');
		AddHeadingCode(v_curr_type_id, '1003');
		AddHeadingCode(v_curr_type_id, '1101');
		AddHeadingCode(v_curr_type_id, '1102');
		AddHeadingCode(v_curr_type_id, '110201');
		AddHeadingCode(v_curr_type_id, '110202');
		AddHeadingCode(v_curr_type_id, '1103');
		AddHeadingCode(v_curr_type_id, '1104');
		AddHeadingCode(v_curr_type_id, '110401');
		AddHeadingCode(v_curr_type_id, '110402');
		AddHeadingCode(v_curr_type_id, '110403');
		AddHeadingCode(v_curr_type_id, '110404');
		AddHeadingCode(v_curr_type_id, '110405');
		AddHeadingCode(v_curr_type_id, '110406');
		AddHeadingCode(v_curr_type_id, '110407');
		AddHeadingCode(v_curr_type_id, '110408');
		AddHeadingCode(v_curr_type_id, '110409');
		AddHeadingCode(v_curr_type_id, '1105');
		AddHeadingCode(v_curr_type_id, '110501');
		AddHeadingCode(v_curr_type_id, '110502');
		AddHeadingCode(v_curr_type_id, '110503');
		AddHeadingCode(v_curr_type_id, '1106');
		AddHeadingCode(v_curr_type_id, '110601');
		AddHeadingCode(v_curr_type_id, '110602');
		AddHeadingCode(v_curr_type_id, '110603');
		AddHeadingCode(v_curr_type_id, '110604');
		AddHeadingCode(v_curr_type_id, '110605');
		AddHeadingCode(v_curr_type_id, '110606');
		AddHeadingCode(v_curr_type_id, '110607');
		AddHeadingCode(v_curr_type_id, '110608');
		AddHeadingCode(v_curr_type_id, '110609');
		AddHeadingCode(v_curr_type_id, '1107');
		AddHeadingCode(v_curr_type_id, '110701');
		AddHeadingCode(v_curr_type_id, '110702');
	END;
	
	SELECT MIN(site_type_id)
	  INTO v_curr_type_id
	  FROM enhesa_site_type
	 WHERE label = v_industrial_label;
	
	IF v_curr_type_id IS NULL THEN
		v_curr_type_id := enhesa_site_type_id_seq.nextval;
		INSERT INTO enhesa_site_type (site_type_id, label) VALUES (v_curr_type_id, v_industrial_label);
	ELSE
		DELETE FROM enhesa_site_type_heading
		 WHERE site_type_id = v_curr_type_id;	
	END IF;
	
	BEGIN
		AddHeadingCode(v_curr_type_id, '0201');
		AddHeadingCode(v_curr_type_id, '020101');
		AddHeadingCode(v_curr_type_id, '020102');
		AddHeadingCode(v_curr_type_id, '020103');
		AddHeadingCode(v_curr_type_id, '020104');
		AddHeadingCode(v_curr_type_id, '020105');
		AddHeadingCode(v_curr_type_id, '020106');
		AddHeadingCode(v_curr_type_id, '020107');
		AddHeadingCode(v_curr_type_id, '0202');
		AddHeadingCode(v_curr_type_id, '020201');
		AddHeadingCode(v_curr_type_id, '020202');
		AddHeadingCode(v_curr_type_id, '020203');
		AddHeadingCode(v_curr_type_id, '020204');
		AddHeadingCode(v_curr_type_id, '020205');
		AddHeadingCode(v_curr_type_id, '0203');
		AddHeadingCode(v_curr_type_id, '0204');
		AddHeadingCode(v_curr_type_id, '020401');
		AddHeadingCode(v_curr_type_id, '020402');
		AddHeadingCode(v_curr_type_id, '020403');
		AddHeadingCode(v_curr_type_id, '0301');
		AddHeadingCode(v_curr_type_id, '030101');
		AddHeadingCode(v_curr_type_id, '030102');
		AddHeadingCode(v_curr_type_id, '030103');
		AddHeadingCode(v_curr_type_id, '030104');
		AddHeadingCode(v_curr_type_id, '030105');
		AddHeadingCode(v_curr_type_id, '030106');
		AddHeadingCode(v_curr_type_id, '030107');
		AddHeadingCode(v_curr_type_id, '030108');
		AddHeadingCode(v_curr_type_id, '0302');
		AddHeadingCode(v_curr_type_id, '030201');
		AddHeadingCode(v_curr_type_id, '030202');
		AddHeadingCode(v_curr_type_id, '030203');
		AddHeadingCode(v_curr_type_id, '030204');
		AddHeadingCode(v_curr_type_id, '030205');
		AddHeadingCode(v_curr_type_id, '030206');
		AddHeadingCode(v_curr_type_id, '0303');
		AddHeadingCode(v_curr_type_id, '030301');
		AddHeadingCode(v_curr_type_id, '030302');
		AddHeadingCode(v_curr_type_id, '030303');
		AddHeadingCode(v_curr_type_id, '0304');
		AddHeadingCode(v_curr_type_id, '030401');
		AddHeadingCode(v_curr_type_id, '030402');
		AddHeadingCode(v_curr_type_id, '0401');
		AddHeadingCode(v_curr_type_id, '040101');
		AddHeadingCode(v_curr_type_id, '040102');
		AddHeadingCode(v_curr_type_id, '040103');
		AddHeadingCode(v_curr_type_id, '040104');
		AddHeadingCode(v_curr_type_id, '040105');
		AddHeadingCode(v_curr_type_id, '0402');
		AddHeadingCode(v_curr_type_id, '040201');
		AddHeadingCode(v_curr_type_id, '040202');
		AddHeadingCode(v_curr_type_id, '040203');
		AddHeadingCode(v_curr_type_id, '040204');
		AddHeadingCode(v_curr_type_id, '040205');
		AddHeadingCode(v_curr_type_id, '040206');
		AddHeadingCode(v_curr_type_id, '040207');
		AddHeadingCode(v_curr_type_id, '0501');
		AddHeadingCode(v_curr_type_id, '050101');
		AddHeadingCode(v_curr_type_id, '050102');
		AddHeadingCode(v_curr_type_id, '050103');
		AddHeadingCode(v_curr_type_id, '050104');
		AddHeadingCode(v_curr_type_id, '050105');
		AddHeadingCode(v_curr_type_id, '050106');
		AddHeadingCode(v_curr_type_id, '050107');
		AddHeadingCode(v_curr_type_id, '0502');
		AddHeadingCode(v_curr_type_id, '050201');
		AddHeadingCode(v_curr_type_id, '050202');
		AddHeadingCode(v_curr_type_id, '050203');
		AddHeadingCode(v_curr_type_id, '050204');
		AddHeadingCode(v_curr_type_id, '050205');
		AddHeadingCode(v_curr_type_id, '050206');
		AddHeadingCode(v_curr_type_id, '050207');
		AddHeadingCode(v_curr_type_id, '050208');
		AddHeadingCode(v_curr_type_id, '050209');
		AddHeadingCode(v_curr_type_id, '0503');
		AddHeadingCode(v_curr_type_id, '050301');
		AddHeadingCode(v_curr_type_id, '050302');
		AddHeadingCode(v_curr_type_id, '050303');
		AddHeadingCode(v_curr_type_id, '050304');
		AddHeadingCode(v_curr_type_id, '0504');
		AddHeadingCode(v_curr_type_id, '050401');
		AddHeadingCode(v_curr_type_id, '050402');
		AddHeadingCode(v_curr_type_id, '050403');
		AddHeadingCode(v_curr_type_id, '050404');
		AddHeadingCode(v_curr_type_id, '0601');
		AddHeadingCode(v_curr_type_id, '060101');
		AddHeadingCode(v_curr_type_id, '060102');
		AddHeadingCode(v_curr_type_id, '060103');
		AddHeadingCode(v_curr_type_id, '060104');
		AddHeadingCode(v_curr_type_id, '0602');
		AddHeadingCode(v_curr_type_id, '060201');
		AddHeadingCode(v_curr_type_id, '060202');
		AddHeadingCode(v_curr_type_id, '0603');
		AddHeadingCode(v_curr_type_id, '060301');
		AddHeadingCode(v_curr_type_id, '060302');
		AddHeadingCode(v_curr_type_id, '060303');
		AddHeadingCode(v_curr_type_id, '060304');
		AddHeadingCode(v_curr_type_id, '060305');
		AddHeadingCode(v_curr_type_id, '060306');
		AddHeadingCode(v_curr_type_id, '060307');
		AddHeadingCode(v_curr_type_id, '060308');
		AddHeadingCode(v_curr_type_id, '060309');
		AddHeadingCode(v_curr_type_id, '0604');
		AddHeadingCode(v_curr_type_id, '0605');
		AddHeadingCode(v_curr_type_id, '0701');
		AddHeadingCode(v_curr_type_id, '070101');
		AddHeadingCode(v_curr_type_id, '070102');
		AddHeadingCode(v_curr_type_id, '0702');
		AddHeadingCode(v_curr_type_id, '070201');
		AddHeadingCode(v_curr_type_id, '070202');
		AddHeadingCode(v_curr_type_id, '070203');
		AddHeadingCode(v_curr_type_id, '070204');
		AddHeadingCode(v_curr_type_id, '070205');
		AddHeadingCode(v_curr_type_id, '070206');
		AddHeadingCode(v_curr_type_id, '0703');
		AddHeadingCode(v_curr_type_id, '0704');
		AddHeadingCode(v_curr_type_id, '0705');
		AddHeadingCode(v_curr_type_id, '0706');
		AddHeadingCode(v_curr_type_id, '0801');
		AddHeadingCode(v_curr_type_id, '080101');
		AddHeadingCode(v_curr_type_id, '080102');
		AddHeadingCode(v_curr_type_id, '080103');
		AddHeadingCode(v_curr_type_id, '080104');
		AddHeadingCode(v_curr_type_id, '080105');
		AddHeadingCode(v_curr_type_id, '0802');
		AddHeadingCode(v_curr_type_id, '080201');
		AddHeadingCode(v_curr_type_id, '080202');
		AddHeadingCode(v_curr_type_id, '080203');
		AddHeadingCode(v_curr_type_id, '0803');
		AddHeadingCode(v_curr_type_id, '080301');
		AddHeadingCode(v_curr_type_id, '080302');
		AddHeadingCode(v_curr_type_id, '0804');
		AddHeadingCode(v_curr_type_id, '080401');
		AddHeadingCode(v_curr_type_id, '080402');
		AddHeadingCode(v_curr_type_id, '080403');
		AddHeadingCode(v_curr_type_id, '080404');
		AddHeadingCode(v_curr_type_id, '080405');
		AddHeadingCode(v_curr_type_id, '080406');
		AddHeadingCode(v_curr_type_id, '080407');
		AddHeadingCode(v_curr_type_id, '0805');
		AddHeadingCode(v_curr_type_id, '080501');
		AddHeadingCode(v_curr_type_id, '080502');
		AddHeadingCode(v_curr_type_id, '0901');
		AddHeadingCode(v_curr_type_id, '0902');
		AddHeadingCode(v_curr_type_id, '0903');
		AddHeadingCode(v_curr_type_id, '0904');
		AddHeadingCode(v_curr_type_id, '0905');
		AddHeadingCode(v_curr_type_id, '090501');
		AddHeadingCode(v_curr_type_id, '090502');
		AddHeadingCode(v_curr_type_id, '090503');
		AddHeadingCode(v_curr_type_id, '090504');
		AddHeadingCode(v_curr_type_id, '0906');
		AddHeadingCode(v_curr_type_id, '0907');
		AddHeadingCode(v_curr_type_id, '0908');
		AddHeadingCode(v_curr_type_id, '0909');
		AddHeadingCode(v_curr_type_id, '0910');
		AddHeadingCode(v_curr_type_id, '0911');
		AddHeadingCode(v_curr_type_id, '0912');
		AddHeadingCode(v_curr_type_id, '1001');
		AddHeadingCode(v_curr_type_id, '100101');
		AddHeadingCode(v_curr_type_id, '100102');
		AddHeadingCode(v_curr_type_id, '100103');
		AddHeadingCode(v_curr_type_id, '1002');
		AddHeadingCode(v_curr_type_id, '1003');
		AddHeadingCode(v_curr_type_id, '1101');
		AddHeadingCode(v_curr_type_id, '1102');
		AddHeadingCode(v_curr_type_id, '110201');
		AddHeadingCode(v_curr_type_id, '110202');
		AddHeadingCode(v_curr_type_id, '1103');
		AddHeadingCode(v_curr_type_id, '1104');
		AddHeadingCode(v_curr_type_id, '110401');
		AddHeadingCode(v_curr_type_id, '110402');
		AddHeadingCode(v_curr_type_id, '110403');
		AddHeadingCode(v_curr_type_id, '110404');
		AddHeadingCode(v_curr_type_id, '110405');
		AddHeadingCode(v_curr_type_id, '110406');
		AddHeadingCode(v_curr_type_id, '110407');
		AddHeadingCode(v_curr_type_id, '110408');
		AddHeadingCode(v_curr_type_id, '110409');
		AddHeadingCode(v_curr_type_id, '1105');
		AddHeadingCode(v_curr_type_id, '110501');
		AddHeadingCode(v_curr_type_id, '110502');
		AddHeadingCode(v_curr_type_id, '110503');
		AddHeadingCode(v_curr_type_id, '1106');
		AddHeadingCode(v_curr_type_id, '110601');
		AddHeadingCode(v_curr_type_id, '110602');
		AddHeadingCode(v_curr_type_id, '110603');
		AddHeadingCode(v_curr_type_id, '110604');
		AddHeadingCode(v_curr_type_id, '110605');
		AddHeadingCode(v_curr_type_id, '110607');
		AddHeadingCode(v_curr_type_id, '110608');
		AddHeadingCode(v_curr_type_id, '110609');
		AddHeadingCode(v_curr_type_id, '1107');
		AddHeadingCode(v_curr_type_id, '110701');
		AddHeadingCode(v_curr_type_id, '110702');
	END;
END;

-- This is executed from scheduled task so no need for security check
PROCEDURE GetEhsManagersForSite(
	out_cur		OUT	SYS_REFCURSOR
)
AS
	v_ehs_managers_group	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_ehs_managers_group := securableobject_pkg.GetSidFromPath(
			in_act					=> security_pkg.GetAct,
			in_parent_sid_id		=> security_pkg.GetApp,
			in_path					=> 'Groups/EHS Managers'
		);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN;
	END;

	OPEN out_cur FOR
		SELECT users.sid_id, cu.full_name name 
		  FROM TABLE(group_pkg.GetMembersAsTableUNSEC(v_ehs_managers_group)) users
		  JOIN csr_user cu on cu.csr_user_sid = users.sid_id;
END;


-- This is executed from scheduled task so no need for security check
PROCEDURE MarkComplianceAlertSent(
	in_csr_user_sid		IN	compliance_alert.csr_user_sid%TYPE
)
AS
BEGIN
	INSERT INTO compliance_alert (app_sid, compliance_alert_id, csr_user_sid, sent_dtm) 
	VALUES (security_pkg.GetApp, compliance_alert_id_seq.nextval, in_csr_user_sid, SYSDATE);
END;

-- This is executed from scheduled task so no need for security check
PROCEDURE GetFailedRollOutRegions(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cem.app_sid, cem.enhesa_country || '/' || cem.enhesa_region region_name
		  FROM compliance_enhesa_map cem
		 WHERE cem.alert_sent IS NULL
		   AND NOT EXISTS (
				SELECT NULL 
				  FROM compliance_enhesa_map_item cemi
				 WHERE cemi.enhesa_country = cem.enhesa_country
				   AND cemi.enhesa_region = cem.enhesa_region
				   AND cemi.app_sid = cem.app_sid
		   );
END;

-- This is executed from scheduled task so no need for security check
PROCEDURE MarkUnmappedRegionSent(
	in_app_sid						IN	compliance_enhesa_map.app_sid%TYPE
)
AS
	v_compliance_alert_id NUMBER(10);
BEGIN
	UPDATE compliance_enhesa_map cem
	   SET cem.alert_sent = SYSDATE
	 WHERE cem.app_sid = in_app_sid
	   AND cem.alert_sent IS NULL
	   AND NOT EXISTS (
			SELECT NULL 
			  FROM compliance_enhesa_map_item cemi
			 WHERE cemi.enhesa_country = cem.enhesa_country
			   AND cemi.enhesa_region = cem.enhesa_region
			   AND cemi.app_sid = cem.app_sid
	   );
END;

-- Used as part of compliance template export
PROCEDURE GetComplianceItems(
	out_cur							OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertComplianceMgr();
	
	OPEN out_cur FOR
		SELECT ci.compliance_item_id, 
				CASE
					WHEN creg.compliance_item_id IS NOT NULL AND creg.is_policy = 0 THEN 'Regulation'
					WHEN creg.compliance_item_id IS NOT NULL AND creg.is_policy = 1 THEN 'Policy'
					WHEN creq.compliance_item_id IS NOT NULL THEN 'Requirement'
				END type, title, summary, details, pc.name country, pr.name administrative_area, 
				cg.group_name organisation, crrs.rollout_regions regions,
				creg.adoption_dtm, reference_code, citation, external_link
		  FROM compliance_item ci
		  JOIN compliance_item_status cis ON ci.compliance_item_status_id = cis.compliance_item_status_id
		  JOIN compliance_item_source cisrc ON ci.source = cisrc.compliance_item_source_id
		  LEFT JOIN compliance_regulation creg ON ci.compliance_item_id = creg.compliance_item_id
		  LEFT JOIN compliance_requirement creq ON ci.compliance_item_id = creq.compliance_item_id
		  LEFT JOIN compliance_item_rollout cir ON ci.compliance_item_id = cir.compliance_item_id
		  LEFT JOIN postcode.country pc ON cir.country = pc.country
		  LEFT JOIN postcode.region pr ON cir.country = pr.country AND cir.region = pr.region
		  LEFT JOIN country_group cg ON cir.country_group = cg.country_group_id
		  LEFT JOIN (
			SELECT crs.compliance_item_id, listagg(r.description,', ') within group(order by crs.compliance_item_id)  as rollout_regions
			  FROM compliance_rollout_regions crs
			  JOIN v$region r ON r.region_sid = crs.REGION_SID
			 GROUP BY crs.compliance_item_id
				) crrs ON crrs.compliance_item_id = ci.compliance_item_id
		 WHERE ci.compliance_item_id NOT IN (
			SELECT compliance_item_id 
			  FROM csr.compliance_permit_condition
			)
		   AND ci.source = SOURCE_USER_DEFINED;
				
	OPEN out_tags FOR
		SELECT cit.compliance_item_id, t.tag_id, t.tag, tgm.tag_group_id
		  FROM compliance_item_tag cit
		  JOIN tag_group_member tgm ON cit.tag_id = tgm.tag_id AND cit.app_sid = tgm.app_sid
		  JOIN v$tag t ON cit.tag_id = t.tag_id AND cit.app_sid = t.app_sid
		 ORDER BY tgm.tag_group_id, tgm.pos;
END;

-- Used as part of compliance variant template export
PROCEDURE GetComplianceItemVariants(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertComplianceMgr();

	OPEN out_cur FOR
		SELECT cid.compliance_item_id, l.lang, cid.title, cid.summary, cid.details, cid.citation
		  FROM compliance_language cl
		  JOIN compliance_item_description cid ON cid.lang_id = cl.lang_id
		  JOIN compliance_item ci ON ci.compliance_item_id = cid.compliance_item_id
		  JOIN aspen2.lang l ON l.lang_id = cl.lang_id
		 WHERE cl.active = 1
		   AND ci.source = SOURCE_USER_DEFINED
		   AND NOT EXISTS (
				SELECT NULL
				  FROM compliance_permit_condition
				 WHERE compliance_item_id = ci.compliance_item_id
			);
END;

-- only called from enhesa integration
PROCEDURE UNSEC_DeleteComplianceItemHistory(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE
)
AS
BEGIN
	DELETE FROM compliance_item_version_log 
	 WHERE compliance_item_id = in_compliance_item_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION FeatureComplianceLanguages RETURN BOOLEAN
AS
BEGIN
	RETURN csr_data_pkg.CheckCapability('Compliance Languages');
END;

FUNCTION GetCIIdForFlowItemId(
	in_flow_item_id					IN compliance_item_region.flow_item_id%TYPE
) RETURN NUMBER
AS
	v_id	NUMBER(10);
BEGIN
	SELECT MIN(compliance_item_id)
	  INTO v_id
	  FROM compliance_item_region
	 WHERE flow_item_id = in_flow_item_id;
	 
	RETURN NVL(v_id, -1);
END;

END;
/
