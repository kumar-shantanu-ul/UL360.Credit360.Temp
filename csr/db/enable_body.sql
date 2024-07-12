CREATE OR REPLACE PACKAGE BODY CSR.enable_pkg IS

/*
	ADDING AN ENABLE SCRIPT HERE? Please add it to the enable page!
	https://fogbugz.credit360.com/default.asp?W1721
*/


/*
	Enable page procedures
*/

PROCEDURE GetAllModules(
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT m.module_id, m.module_name, m.description, m.license_warning, m.warning_msg
		  FROM MODULE m
		 ORDER BY LOWER(m.module_name) ASC;
END;

PROCEDURE GetModuleParams(
	in_module_id	IN MODULE.module_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT param_name, param_hint, pos, allow_blank
		  FROM module_param
		 WHERE module_id = in_module_id
		 ORDER BY pos;
END;

PROCEDURE GetEnableModule(
	in_module_id	IN MODULE.module_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT enable_sp, enable_class, post_enable_class
		  FROM module
		 WHERE module_id = in_module_id;
END;

PROCEDURE LogEnableAction(
	in_module_id	IN MODULE.module_id%TYPE,
	in_user_sid		IN security.security_pkg.T_SID_ID
)
AS
	v_module_name	module.module_name%TYPE;
BEGIN
	SELECT module_name INTO v_module_name
	  FROM module
	 WHERE module_id = in_module_id;

	-- Write log entry
	csr_data_pkg.WriteAuditLogEntryForSid(in_user_sid, csr_data_pkg.AUDIT_TYPE_MODULE_ENABLED, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'APP'), 'Module enabled : {0}', v_module_name);
END;

/*
	End Enable page procedures
	Please place the actual enable scripts below this block.
*/



/*
 * Create a web resource or find existing web resource return the SO ID.
 * Parameters match security.web_pkg.CreateResource for easy search and replace.
 *
 * in_relocate_existing		Set to TRUE if you want to move existing menu to the specified parent
 * */
PROCEDURE INTERNAL_CreateOrGetResource(
	in_act_id			IN 	security.security_pkg.T_ACT_ID,
	in_web_root_sid_id	IN 	security.security_pkg.T_SID_ID,
	in_parent_sid_id	IN 	security.security_pkg.T_SID_ID,
	in_page_name		IN 	security.web_resource.path%TYPE,
	out_page_sid_id		OUT security.web_resource.sid_id%TYPE
)
AS
BEGIN
	security.web_pkg.CreateResource(
		in_act_id			=> in_act_id,
		in_web_root_sid_id	=> in_web_root_sid_id,
		in_parent_sid_id	=> in_parent_sid_id,
		in_page_name		=> in_page_name,
		in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
		in_rewrite_path		=> NULL,
		out_page_sid_id		=> out_page_sid_id
	);
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		out_page_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_parent_sid_id, in_page_name);
END;

/*
 *
 * Create a CSR user group or find existing one and return the SO ID.
 *
 */
FUNCTION INTERNAL_CreateOrGetGroup(
	in_act_id				security_pkg.T_ACT_ID,
	in_app_sid				security_pkg.T_SID_ID,
	in_group_name			security_pkg.T_SO_NAME
) RETURN security_pkg.T_SID_ID
AS
	v_class_id				security_pkg.T_CLASS_ID;
	v_groups_sid			security_pkg.T_SID_ID;
	v_new_group_sid			security_pkg.T_SID_ID;
BEGIN
	-- read groups
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'Groups');
	-- create groups
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(in_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, in_group_name, v_class_id, v_new_group_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_new_group_sid := security.securableobject_pkg.GetSidFromPath(in_act_id, v_groups_sid, in_group_name);
	END;

	RETURN v_new_group_sid;
END;

/*
 * AddAce for SID but remove first to avoid duplicates
 * Parameters match security.acl_pkg.AddACE for easy search and replace.
 * */
 --XXX: This seems wrong this could remove an ace with more permissions to add one with less?
PROCEDURE INTERNAL_AddACE_NoDups(
	in_act_id			IN 	security.security_pkg.T_ACT_ID,
	in_acl_id			IN Security_Pkg.T_ACL_ID,
	in_acl_index		IN Security_Pkg.T_ACL_INDEX,
	in_ace_type			IN Security_Pkg.T_ACE_TYPE,
	in_ace_flags		IN Security_Pkg.T_ACE_FLAGS,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_permission_set	IN Security_Pkg.T_PERMISSION
)
AS
BEGIN
	security.acl_pkg.RemoveACEsForSid(in_act_id, in_acl_id, in_sid_id);
	security.acl_pkg.AddACE(in_act_id, in_acl_id, in_acl_index, in_ace_type, in_ace_flags, in_sid_id, in_permission_set);
END;


/*
 * Create a menu or reset details on existing menu and return the SO ID.
 *
 * in_relocate_existing		Set to TRUE if you want to move existing menu to the specified parent
 * */
PROCEDURE INTERNAL_CreateOrSetMenu(
	in_act_id				IN	security.security_pkg.T_ACT_ID,
	in_parent_sid_id		IN 	security.security_pkg.T_SID_ID,
	in_name					IN	security.security_pkg.T_SO_NAME,
	in_description			IN	security.menu.description%TYPE,
	in_action				IN	security.menu.action%TYPE,
	in_pos					IN	security.menu.pos%TYPE,
	in_context				IN	security.menu.context%TYPE,
	in_relocate_existing	IN	BOOLEAN,
	out_menu_sid_id			OUT	security.security_pkg.T_SID_ID
)
AS
	v_parent_match	NUMBER(1);
BEGIN
	-- Find menu by name, working out if it is in the correct location.
	-- If there are multiple menus with the same name, take the one with a matching parent first. Then whatever is next!
	SELECT sid_id, parent_match
	  INTO out_menu_sid_id, v_parent_match
	 FROM (
			SELECT m.sid_id, DECODE(so.parent_sid_id, in_parent_sid_id, 1, 0) parent_match, rownum rn
			  FROM security.menu m
			  JOIN security.securable_object so
					ON so.sid_id = m.sid_id
			 WHERE so.application_sid_id = SYS_CONTEXT('security', 'app')
			   AND LOWER(so.name) = LOWER(in_name)
			 ORDER BY parent_match DESC
		   )
	 WHERE rn = 1;

	IF v_parent_match = 0 AND in_relocate_existing = TRUE THEN
		security.securableobject_pkg.MoveSO(
			in_act_id			=> in_act_id,
			in_sid_id			=> out_menu_sid_id,
			in_new_parent_sid	=> in_parent_sid_id
		);
	END IF;

	security.menu_pkg.SetMenu(
		in_act_id		=> in_act_id,
		in_sid_id		=> out_menu_sid_id,
		in_description	=> in_description,
		in_action		=> in_action,
		in_pos			=> in_pos,
		in_context		=> in_context
	);
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		security.menu_pkg.CreateMenu(
			in_act_id			=> in_act_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_name				=> in_name,
			in_description		=> in_description,
			in_action			=> in_action,
			in_pos				=> in_pos,
			in_context			=> in_context,
			out_sid_id			=> out_menu_sid_id
		);
END;

/*
 * (OVERRIDE) Create a menu or reset details on existing and return the SO ID.
 * Parameters match menu_pkg.CreateMenu for easy search and replace.
 * */
PROCEDURE INTERNAL_CreateOrSetMenu(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid_id	IN 	security_pkg.T_SID_ID,
	in_name				IN	security_pkg.T_SO_NAME,
	in_description		IN	security.menu.description%TYPE,
	in_action			IN	security.menu.action%TYPE,
	in_pos				IN	security.menu.pos%TYPE,
	in_context			IN	security.menu.context%TYPE,
	out_menu_sid_id		OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	INTERNAL_CreateOrSetMenu(
		in_act_id				=> in_act_id,
		in_parent_sid_id		=> in_parent_sid_id,
		in_name					=> in_name,
		in_description			=> in_description,
		in_action				=> in_action,
		in_pos					=> in_pos,
		in_context				=> in_context,
		in_relocate_existing	=> FALSE,
		out_menu_sid_id			=> out_menu_sid_id
	);
END;

PROCEDURE INTERNAL_DeleteMenu(in_path	IN VARCHAR2) 
AS
	v_menu_sid					security.security_pkg.T_SID_ID;
BEGIN
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(
		in_act => security.security_pkg.GetAct,
		in_parent_sid_id => security.security_pkg.GetApp,
		in_path => in_path
	);
	security.securableobject_pkg.DeleteSO(
		in_act_id => security.security_pkg.GetAct,
		in_sid_id => v_menu_sid
	);
EXCEPTION
	WHEN security.security_pkg.OBJECT_NOT_FOUND THEN RETURN;
END;



/* Generic procedure to reset menu positions for any / all enable scripts
 */
PROCEDURE INTERNAL_ResetTopMenuPositions
AS
	v_act_id	security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_menu_root	security.security_pkg.T_SID_ID;
BEGIN
	v_menu_root := security.securableobject_pkg.GetSidFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Menu');

	FOR m IN (
		SELECT sid_id, new_pos
		  FROM	(
				 SELECT so.sid_id, sm.pos,
						CASE
							WHEN LOWER(so.name) = 'data' THEN 1
							WHEN LOWER(so.name) = 'csr_properties_menu' THEN 2
							WHEN LOWER(so.name) = 'metering' THEN 3
							WHEN LOWER(so.name) = 'initiatives' THEN 4
							WHEN LOWER(so.name) = 'forms' THEN 5
							WHEN LOWER(so.name) = 'analysis' THEN 6
							WHEN LOWER(so.name) = 'csr_text_admin_list' THEN 7 -- frameworks
							WHEN LOWER(so.name) = 'admin' THEN 10
							WHEN LOWER(so.name) = 'setup' THEN 11
							WHEN LOWER(so.name) = 'support' THEN 12
							WHEN LOWER(so.name) = 'login' THEN 20
							WHEN LOWER(so.name) = 'logout' THEN 21
							WHEN LOWER(so.name) = 'csr_help_viewhelp' THEN 22 -- help
							ELSE sm.pos -- unknown
						END new_pos
				   FROM security.menu sm
				   JOIN security.securable_object so ON so.sid_id = sm.sid_id
				  WHERE so.parent_sid_id = v_menu_root
					AND so.application_sid_id = v_app_sid
				)
		  WHERE pos <> new_pos
	   ORDER BY new_pos
	)
	LOOP
		security.menu_pkg.SetPos(v_act_id, m.sid_id, m.new_pos);
	END LOOP;
END;

PROCEDURE INTERNAL_CreateCampaignAndWF
AS
	v_campaigns_sid			security_pkg.T_SID_ID;
	v_qs_campaign_sid		security_pkg.T_SID_ID;
	v_frame_id				NUMBER;
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	-- Workflow vars
	v_workflow_sid			security.security_pkg.T_SID_ID;
	v_act					security.security_pkg.T_ACT_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_r1					security.security_pkg.T_SID_ID;
	v_r2					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
	v_st2					security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_campaigns_sid := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'Campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_campaigns_sid := NULL;
	END;

	IF v_campaigns_sid IS NOT NULL THEN
		-- Add Workflow
		BEGIN
			v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Compliance Applicability');
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
					   AND cfac.flow_alert_class = 'campaign';
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'Please enable the campaign module first');
				END;

				-- create our workflow
				csr.flow_pkg.CreateFlow(
					in_label			=> 'Compliance Applicability',
					in_parent_sid		=> v_wf_ct_sid,
					in_flow_alert_class	=> 'campaign',
					out_flow_sid		=> v_workflow_sid
				);

				-- Helpers
				csr.flow_pkg.SetStateTransHelper(v_workflow_sid, 'campaigns.campaign_pkg.ApplyCampaignScoresToProperty', 'Update property scores from campaign');
				csr.flow_pkg.SetStateTransHelper(v_workflow_sid, 'campaigns.campaign_pkg.ApplyCampaignScoresToSupplier', 'Update supplier scores from campaign');


				-- Initiate variables and populate temp tables
				v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, ''), csr.flow_pkg.GetNextStateID);
				v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, ''), csr.flow_pkg.GetNextStateID);

				csr.role_pkg.SetRole('Property Manager', v_r1);
				csr.role_pkg.SetRole('EHS Regional Manager', v_r2);

				csr.flow_pkg.SetTempFlowState(
					in_flow_sid => v_workflow_sid,
					in_pos => 1,
					in_flow_state_id => v_s1,
					in_label => 'Pending',
					in_lookup_key => '',
					in_is_final => 0,
					in_state_colour => '16737792',
					in_editable_role_sids => null,
					in_non_editable_role_sids => v_r1||','||v_r2,
					in_editable_col_sids => null,
					in_non_editable_col_sids => null,
					in_involved_type_ids => null,
					in_editable_group_sids => null,
					in_non_editable_group_sids => null,
					in_flow_state_group_ids => null,
					in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="769.2" y="839.6" />',
					in_flow_state_nature_id => null,
					in_survey_editable => 1,
					in_survey_tag_ids => null);

				csr.flow_pkg.SetTempFlowStateRoleCap(
					in_flow_sid => v_workflow_sid,
					in_flow_state_id => v_s1,
					in_flow_capability_id => 1001,
					in_role_sid => v_r1,
					in_flow_involvement_type_id => null,
					in_permission_set => 3,
					in_group_sid => null);

				csr.flow_pkg.SetTempFlowStateRoleCap(
					in_flow_sid => v_workflow_sid,
					in_flow_state_id => v_s1,
					in_flow_capability_id => 1001,
					in_role_sid => v_r2,
					in_flow_involvement_type_id => null,
					in_permission_set => 3,
					in_group_sid => null);

				csr.flow_pkg.SetTempFlowStateTrans(
					in_flow_sid => v_workflow_sid,
					in_pos => 0,
					in_flow_state_transition_id => null,
					in_from_state_id => v_s1,
					in_to_state_id => v_s2,
					in_ask_for_comment => 'optional',
					in_mandatory_fields_message => '',
					in_auto_trans_type => 0,
					in_hours_before_auto_tran => null,
					in_auto_schedule_xml => null,
					in_button_icon_path => 'https://dpqqrlml95jk6.cloudfront.net/fp/shared/images/ic_tick.gif',
					in_verb => 'Submit',
					in_lookup_key => 'SUBMIT',
					in_helper_sp => '',
					in_role_sids => v_r1||','||v_r2,
					in_column_sids => null,
					in_involved_type_ids => null,
					in_group_sids => null,
					in_attributes_xml => null,
					in_enforce_validation => 0,
					out_flow_state_transition_id => v_st1);

				csr.flow_pkg.SetTempFlowState(
					in_flow_sid => v_workflow_sid,
					in_pos => 2,
					in_flow_state_id => v_s2,
					in_label => 'Complete',
					in_lookup_key => '',
					in_is_final => 1,
					in_state_colour => '3777539',
					in_editable_role_sids => null,
					in_non_editable_role_sids => v_r1||','||v_r2,
					in_editable_col_sids => null,
					in_non_editable_col_sids => null,
					in_involved_type_ids => null,
					in_editable_group_sids => null,
					in_non_editable_group_sids => null,
					in_flow_state_group_ids => null,
					in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="996.6" y="896" />',
					in_flow_state_nature_id => null,
					in_survey_editable => 1,
					in_survey_tag_ids => null);

				csr.flow_pkg.SetTempFlowStateRoleCap(
					in_flow_sid => v_workflow_sid,
					in_flow_state_id => v_s2,
					in_flow_capability_id => 1001,
					in_role_sid => v_r1,
					in_flow_involvement_type_id => null,
					in_permission_set => 1,
					in_group_sid => null);

				csr.flow_pkg.SetTempFlowStateRoleCap(
					in_flow_sid => v_workflow_sid,
					in_flow_state_id => v_s2,
					in_flow_capability_id => 1001,
					in_role_sid => v_r2,
					in_flow_involvement_type_id => null,
					in_permission_set => 3,
					in_group_sid => null);

				csr.flow_pkg.SetTempFlowStateTrans(
					in_flow_sid => v_workflow_sid,
					in_pos => 0,
					in_flow_state_transition_id => null,
					in_from_state_id => v_s2,
					in_to_state_id => v_s1,
					in_ask_for_comment => 'none',
					in_mandatory_fields_message => '',
					in_auto_trans_type => 0,
					in_hours_before_auto_tran => null,
					in_auto_schedule_xml => null,
					in_button_icon_path => 'https://dpqqrlml95jk6.cloudfront.net/fp/shared/images/ic_return.gif',
					in_verb => 'Reopen',
					in_lookup_key => '',
					in_helper_sp => '',
					in_role_sids => v_r2,
					in_column_sids => null,
					in_involved_type_ids => null,
					in_group_sids => null,
					in_attributes_xml => null,
					in_enforce_validation => 0,
					out_flow_state_transition_id => v_st2);

				csr.flow_pkg.SetFlowFromTempTables(
					in_flow_sid => v_workflow_sid,
					in_flow_label => 'Compliance Applicability',
					in_flow_alert_class => 'campaign',
					in_cms_tab_sid => v_cms_tab_sid,
					in_default_state_id => v_s1);
			END;

		-- Add Default Campaign
		BEGIN
			v_qs_campaign_sid := campaigns.campaign_pkg.GetCampaignSid('default compliance campaign');

			IF v_qs_campaign_sid IS NULL THEN
				SELECT MAX(alert_frame_id)
				  INTO v_frame_id
				  FROM alert_frame
				 WHERE name = 'Default';

				campaigns.campaign_pkg.SaveCampaign(
					in_campaign_sid				=> NULL,
					in_parent_sid				=> v_campaigns_sid,
					in_name						=> 'Default Compliance Campaign',
					in_audience_type			=> 'WF',
					in_table_sid				=> NULL,
					in_filter_sid				=> NULL,
					in_flow_sid					=> v_workflow_sid,
					in_inc_regions_w_no_users	=> 0,
					in_skip_overlapping_regions => 0,
					in_survey_sid				=> NULL,
					in_frame_id					=> v_frame_id,
					in_subject					=> 'Survey Invitation',
					in_body						=> 'Hello,<br><br>Please fill in the following survey:<br><br><img title="A hyperlink to the survey" style="vertical-align: middle;" alt="Survey link" src="/csr/site/alerts/renderMergeField.ashx?field=SURVEY_URL' || chr(38) || 'amp;text=Survey+link' || chr(38) || 'amp;lang=en"><br><br>Thank you for your cooperation. Sincerely, yours<br><img title="The name of the user who changed the delegation state" style="vertical-align: middle;" alt="From name" src="/csr/site/alerts/renderMergeField.ashx?field=FROM_NAME' || chr(38) || 'amp;text=From+name' || chr(38) || 'amp;lang=en">',
					in_send_after_dtm			=> NULL,
					in_end_dtm					=> NULL,
					in_period_start_dtm			=> NULL,
					in_period_end_dtm			=> NULL,
					in_carry_forward_answers	=> 0,
					in_send_to_column_sid		=> NULL,
					in_region_column_sid		=> NULL,
					in_send_alert				=> 1,
					in_dynamic					=> 0,
					out_campaign_sid			=> v_qs_campaign_sid
				);
			END IF;
		END;
	END IF;
END;

PROCEDURE INTERNAL_AddCampaignsGrants
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_ehs_managers_sid				security_pkg.T_SID_ID;
	v_campaigns_sid					security_pkg.T_SID_ID;
	v_menu_sid						security_pkg.T_SID_ID;
	v_cms							security_pkg.T_SID_ID;
	v_trash_sid						security_pkg.T_SID_ID;
	v_admin_wr						security_pkg.T_SID_ID;
	v_results_wr					security_pkg.T_SID_ID;
BEGIN
	-- Add the grants that EHS Managers need to use the campaigns module
	BEGIN
		v_ehs_managers_sid := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'Groups/EHS Managers');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN RETURN;
	END;

	BEGIN
		v_campaigns_sid := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'Campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_campaigns_sid := NULL;
	END;

	IF v_campaigns_sid IS NOT NULL THEN
		security.acl_pkg.AddACE(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_campaigns_sid),
			in_acl_index			=> -1,
			in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
			in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
			in_sid_id				=> v_ehs_managers_sid,
			in_permission_set		=> security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;

	BEGIN
		v_menu_sid := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'menu/admin/csr_quicksurvey_campaignlist');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_menu_sid := NULL;
	END;

	IF v_menu_sid IS NOT NULL THEN
		security.acl_pkg.AddACE(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_menu_sid),
			in_acl_index			=> -1,
			in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
			in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
			in_sid_id				=> v_ehs_managers_sid,
			in_permission_set		=> security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;

	BEGIN
		v_cms := securableobject_pkg.GetSidFromPath(
			in_act						=> v_act_id,
			in_parent_sid_id			=> v_app_sid,
			in_path						=> 'cms');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_cms := NULL;
	END;

	IF v_cms IS NOT NULL THEN
		security.acl_pkg.AddACE(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_cms),
			in_acl_index			=> -1,
			in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
			in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
			in_sid_id				=> v_ehs_managers_sid,
			in_permission_set		=> security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	BEGIN
		v_admin_wr := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'wwwroot/csr/site/quickSurvey/admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_admin_wr := NULL;
	END;

	IF v_admin_wr IS NOT NULL THEN
		security.acl_pkg.AddACE(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_admin_wr),
			in_acl_index			=> -1,
			in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
			in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
			in_sid_id				=> v_ehs_managers_sid,
			in_permission_set		=> security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	BEGIN
		v_results_wr := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'wwwroot/csr/site/quickSurvey/results');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_cms := NULL;
	END;

	IF v_admin_wr IS NOT NULL THEN
		security.acl_pkg.AddACE(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_results_wr),
			in_acl_index			=> -1,
			in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
			in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
			in_sid_id				=> v_ehs_managers_sid,
			in_permission_set		=> security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	SELECT trash_sid
	  INTO v_trash_sid
	  FROM customer
	 WHERE app_sid = security_pkg.GetApp;

	security.acl_pkg.AddACE(
		in_act_id				=> v_act_id,
		in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_trash_sid),
		in_acl_index			=> -1,
		in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id				=> v_ehs_managers_sid,
		in_permission_set		=> security.security_pkg.PERMISSION_ADD_CONTENTS);
END;

PROCEDURE CreateSecondaryRegionTree(
	secondaryTreeName IN VARCHAR2
)
AS
	v_sid security.security_pkg.T_SID_ID;
BEGIN
	region_pkg.CreateRegionTreeRoot(security.security_pkg.getACT, security.security_pkg.getAPP, secondaryTreeName, 0, v_sid);
END;

PROCEDURE EnableActions
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_ind_root_sid					security.security_pkg.T_SID_ID;
	v_ind_sid						security.security_pkg.T_SID_ID;
	v_measure_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_class_id						security.security_pkg.T_CLASS_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_actions_users_sid				security.security_pkg.T_SID_ID;
	v_actions_admins_sid			security.security_pkg.T_SID_ID;
	v_auditors_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_menu_actions_sid				security.security_pkg.T_SID_ID;
	v_menu_actions_main_sid			security.security_pkg.T_SID_ID;
	v_menu_actions_projects_sid		security.security_pkg.T_SID_ID;
	v_menu_actions_setup_sid		security.security_pkg.T_SID_ID;
	-- web resources
	v_www_actions 					security.security_pkg.T_SID_ID;
	v_www_actions_admin 			security.security_pkg.T_SID_ID;
	v_www_actions2 					security.security_pkg.T_SID_ID;
	-- visibility sec objects
	v_actions_sid					security.security_pkg.T_SID_ID;
	v_visibility_sid				security.security_pkg.T_SID_ID;
	v_visibility_public_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;

	InsertIntoOWLClientModule('SCORECARDING', NULL);

	/*** add portlets ***/
	FOR r IN (
		SELECT portlet_id
		  FROM portlet
		 WHERE type IN (
			'Credit360.Portlets.GanttChart',
			'Credit360.Portlets.ActionsMyInitiatives',
			'Credit360.Portlets.ActionsMyTasks'
		) AND portlet_Id NOT IN (SELECT portlet_id FROM customer_portlet)
	) LOOP
	  portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;

	-- get details from customer
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = v_app_sid;
	-- Create 'Actions' indicator folder (inactive)
	BEGIN
		indicator_pkg.CreateIndicator(
		  in_act_id        => v_act_id,
		  in_parent_sid_id => v_ind_root_sid,
		  in_app_sid       => v_app_sid,
		  in_name          => 'Actions',
		  in_description   => 'Actions',
		  in_active		   => 0,
		  in_aggregate     => 'SUM',
		  out_sid_id	   => v_ind_sid
	  );
	  EXCEPTION
		  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			  v_ind_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ind_root_sid, 'Actions');
	  END;
	-- Create actions progress indicator folder (under actions)
	BEGIN
		indicator_pkg.CreateIndicator(
			in_act_id        => v_act_id,
			in_parent_sid_id => v_ind_sid,
			in_app_sid       => v_app_sid,
			in_name          => 'Progress',
			in_description   => 'Progress',
			in_aggregate     => 'SUM',
			out_sid_id		 => v_ind_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			null;
	END;
	-- Create 'action_progress' measure
	BEGIN
		measure_pkg.CreateMeasure(
			in_name						=> 'action_progress',
			in_description				=> 'Action Progress',
			in_scale					=> 1,
			in_format_mask				=> '0.00',
			in_pct_ownership_applies	=> 0,
			in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
			out_measure_sid				=> v_measure_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_measure_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Measures/action_progress');
	END;
	--
	BEGIN
		INSERT INTO actions.customer_options
			(app_sid, show_regions, use_actions_v2, aggregate_task_tree, show_weightings, region_level, country_level, property_level)
		VALUES
			(v_app_sid, 1, 1, 1, 1, 2, 3, 3);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE actions.customer_options
			   SET show_regions = 1,
				   use_actions_v2 = 1,
				   aggregate_task_tree = 1,
				   show_weightings = 1
			 WHERE app_sid = security.security_pkg.GetAPP;
	END;

	-- insert an ind_template for action_progress
	INSERT INTO actions.ind_template (
			ind_template_id, name, description, app_sid,
			tolerance_type, pct_upper_tolerance, pct_lower_tolerance,
			measure_sid, scale, format_mask, target_direction, info_xml,
			divisibility, aggregate, input_label
		) VALUES (
			actions.ind_template_id_seq.NEXTVAL, 'action_progress', 'Progress', v_app_sid,
			0, 1, 1, v_measure_sid, NULL, NULL, 1, NULL, 0, 'AVERAGE', 'Progress'
		);

	-- read groups
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_auditors_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	-- create groups
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Actions Users', v_class_id, v_actions_users_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_actions_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Actions Users');
	END;
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Actions Admins', v_class_id, v_actions_admins_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_actions_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Actions Admins');
	END;
	-- make actions admins members of actions users
	security.group_pkg.AddMember(v_act_id, v_actions_admins_sid, v_actions_users_sid);
	-- make admins members of actions admins
	security.group_pkg.AddMember(v_act_id, v_admins_sid, v_actions_admins_sid);

	--create "actions" container
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Actions', v_actions_sid);
		-- add admins
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_actions_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_actions_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Actions');
	END;

	-- create "Visibility" container
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_actions_sid,
			security.security_pkg.SO_CONTAINER,
			'Visibility',
			v_visibility_sid
		);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_visibility_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_actions_sid, 'Visibility');
	END;

	-- create "Public" container
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_visibility_sid,
			security.security_pkg.SO_CONTAINER,
			'Public',
			v_visibility_public_sid
		);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_visibility_public_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_visibility_sid, 'Public');
	END;

	-- grant reg users permissions on the public container
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_visibility_public_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	-- add menu items
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'actions', 'Scorecards', '/csr/site/actions/browse.acds', 5, null, v_menu_actions_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_menu_actions_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/actions');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_actions_sid, 'actions_main', 'Browse', '/csr/site/actions/browse.acds', 1, null, v_menu_actions_main_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_menu_actions_main_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/actions/actions_main');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_actions_sid, 'actions_projects', 'Projects', '/csr/site/actions/admin/projects.acds', 2, null, v_menu_actions_projects_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_menu_actions_projects_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/actions/actions_projects');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_actions_sid, 'actions_setup', 'Setup', '/csr/site/actions/admin/setup.acds', 3, null, v_menu_actions_setup_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_menu_actions_setup_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/actions/actions_setup');
	END;
	--
	-- add actions admins to top level menu option (inheritable)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_actions_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_DEFAULT, v_actions_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- add action users to specific items (just BROWSE atm)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_actions_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_actions_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_actions_main_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_actions_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- add auditors to specific items (just BROWSE atm)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_actions_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_actions_main_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_menu_actions_sid);
	--
	-- add permissions on pre-created web-resources
	v_www_actions       := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/actions');
	v_www_actions2      := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/actions2');
	v_www_actions_admin := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/actions/admin');
	--
	-- clear flag on actions/admin and add administrators + actions_admins
	security.securableobject_pkg.ClearFlag(v_act_id, v_www_actions_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_actions_admin), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_DEFAULT, v_actions_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- add auditors and actionsusers to actions + actions2
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_actions), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_actions2), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_actions), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_DEFAULT, v_actions_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_actions2), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
	  security.security_pkg.ACE_FLAG_DEFAULT, v_actions_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_www_actions);
	security.acl_pkg.PropogateACEs(v_act_id, v_www_actions2);
END;

PROCEDURE EnableAudit
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_class_id					security.security_pkg.T_CLASS_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_auditors_sid				security.security_pkg.T_SID_ID;
	v_auditor_admins_sid		security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	-- audits container
	v_audits_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_audit				security.security_pkg.T_SID_ID;
	v_menu_audit_browse			security.security_pkg.T_SID_ID;
	v_menu_audit_new			security.security_pkg.T_SID_ID;
	v_menu_audit_type			security.security_pkg.T_SID_ID;
	v_menu_tag_groups			security.security_pkg.T_SID_ID;
	v_menu_issue				security.security_pkg.T_SID_ID;
	v_menu_def_non_comp			security.security_pkg.T_SID_ID;
	v_menu_non_comp_type		security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site_audit		security.security_pkg.T_SID_ID;
	v_www_csr_site_public_audit	security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_issue 		security.security_pkg.T_SID_ID;
	-- reporting
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
	-- temp variables
	v_sid						security.security_pkg.T_SID_ID;
	v_count						NUMBER;
	v_dummy_cur					security.security_pkg.T_OUTPUT_CUR;
	v_dummy_sids				security.security_pkg.T_SID_IDS;
BEGIN
	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_class_id 				:= security.class_pkg.GetClassId('CSRUserGroup');

	InsertIntoOWLClientModule('INTERNAL_AUDIT', null);
	--
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Audit users', v_class_id, v_auditors_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_auditors_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Audit users');
	END;

	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Audit administrators', v_class_id, v_auditor_admins_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_auditor_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Audit administrators');
	END;

	-- make audit admins members of audit users
	security.group_pkg.AddMember(v_act_id, v_auditor_admins_sid, v_auditors_sid);

	BEGIN
		v_audits_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Audits');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Audits', v_audits_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audits_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audits_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_auditors_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_ADD_CONTENTS);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audits_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_auditor_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	--
	/*** ADD MENU ITEMS ***/
	BEGIN
		v_menu_audit := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/ia');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu'),
				'ia', 'Audit management', '/csr/site/audit/auditList.acds', 8, null, v_menu_audit);
	END;

	-- add auditors to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_audit), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_audit,
			'csr_audit_list', 'Audits', '/csr/site/audit/auditList.acds', 1, null, v_menu_audit_browse);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_audit_browse := security.securableobject_pkg.getSidFromPath(v_act_id, v_menu_audit, 'csr_audit_list');
	END;

	-- add auditors to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_audit_browse), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_audit,
			'csr_non_compliance_list', 'Findings', '/csr/site/audit/nonComplianceList.acds', 2, null, v_menu_audit_browse);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_audit_browse := security.securableobject_pkg.getSidFromPath(v_act_id, v_menu_audit, 'csr_non_compliance_list');
	END;

	-- add auditors to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_audit_browse), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_audit,
			'csr_new_audit', 'Create audit', '/csr/site/audit/editAudit.acds', 3, null, v_menu_audit_new);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_audit_new := security.securableobject_pkg.getSidFromPath(v_act_id, v_menu_audit, 'csr_new_audit');
	END;

	-- add auditors to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_audit_new), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_audit,
			'csr_audit_type_list', 'Audit types', '/csr/site/audit/typeList.acds', 4, null, v_menu_audit_type);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_audit_type := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/ia/csr_audit_type_list');
	END;

	-- add audit admins to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_audit_type), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
		v_auditor_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- check if it's under setup... if not, create it under admin (legacy thing)
	BEGIN
		v_menu_tag_groups := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/setup/csr_schema_tag_groups');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_menu_tag_groups := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/admin/csr_schema_tag_groups');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id,  security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
						'csr_schema_tag_groups', 'Tag groups', '/csr/site/schema/new/tagGroups.acds', 10, null, v_menu_tag_groups);
			END;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
				'csr_default_non_compliances', 'Default findings', '/csr/site/audit/admin/defaultNonCompliances.acds', 11, null, v_menu_def_non_comp);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
				'non_compliance_types', 'Finding types', '/csr/site/audit/admin/nonComplianceTypes.acds', 12, null, v_menu_non_comp_type);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	--
	/*** WEB RESOURCE ***/
	-- add permissions on pre-created web-resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'audit');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'audit', v_www_csr_site_audit);
	END;

	-- add web resource for audit public
	BEGIN
		v_www_csr_site_public_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_audit, 'public');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_audit, 'public', v_www_csr_site_public_audit);
	END;

	--
	-- add administrators and auditors to web resource
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_audit), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_audit), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	v_www_csr_site_issue := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'issues');
	-- add auditors to issues web resource
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_issue), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- add everyone to public audit report download
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_csr_site_public_audit),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		security.security_pkg.SID_BUILTIN_EVERYONE,
		security.security_pkg.PERMISSION_STANDARD_READ
	);

	BEGIN
		INSERT INTO issue_type (issue_type_id, label, applies_to_audit)
			VALUES (csr_data_pkg.ISSUE_NON_COMPLIANCE, 'Corrective Action', csr_data_pkg.IT_APPLIES_TO_AUDIT);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT count(*)
	  INTO v_count
	  FROM internal_audit_type;

	IF v_count = 0 THEN
	-- Add an audit type if there aren't any already
		 audit_pkg.SaveInternalAuditType(
			in_internal_audit_type_id		=> NULL,
			in_label						=> 'Default',
			in_every_n_months				=> NULL,
			in_auditor_role_sid				=> NULL,
			in_audit_contact_role_sid		=> NULL,
			in_default_survey_sid			=> NULL,
			in_default_auditor_org			=> NULL,
			in_override_issue_dtm			=> 0,
			in_assign_issues_to_role		=> 0,
			in_auditor_can_take_ownership	=> 0,
			in_add_nc_per_question			=> 0,
			in_nc_audit_child_region		=> 0,
			in_flow_sid						=> NULL,
			in_internal_audit_source_id		=> csr.audit_pkg.INTERNAL_AUDIT_SOURCE_ID,
			in_summary_survey_sid			=> NULL,
			in_send_auditor_expiry_alerts	=> 1,
			in_expiry_alert_roles			=> v_dummy_sids,
			in_validity_months				=> NULL,
			in_ia_type_group_id				=> NULL,
			in_involve_auditor_in_issues	=> 0,
			out_cur							=> v_dummy_cur
		);
	END IF;

	-- Create calculation ind group
	BEGIN
		SELECT aggregate_ind_group_id
		  INTO v_aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE name = 'InternalAudit';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO aggregate_ind_group (aggregate_ind_group_id, name, helper_proc, label)
			VALUES (aggregate_ind_group_id_seq.NEXTVAL, 'InternalAudit', 'csr.audit_pkg.GetIndicatorValues', 'Internal Audit')
			RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;
	END;

	csr_data_pkg.EnableCapability('Close audits');

	-- Enable alert type (if not enabled already)
	BEGIN
		INSERT INTO customer_alert_type (customer_alert_type_id, std_alert_type_id)
		VALUES (customer_alert_type_id_seq.nextval, 45);

		INSERT INTO customer_alert_type (customer_alert_type_id, std_alert_type_id)
		VALUES (customer_alert_type_id_seq.nextval, 46);

		INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type)
		SELECT cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
		  FROM alert_frame af
		  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
		 WHERE af.app_sid = security.security_pkg.GetApp
		   AND cat.std_alert_type_id IN (45, 46)
		 GROUP BY cat.customer_alert_type_id
		HAVING MIN(af.alert_frame_id) > 0;


		INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
		  FROM default_alert_template_body d
		  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
		  CROSS JOIN aspen2.translation_set t
		 WHERE d.std_alert_type_id IN (45, 46)
		   AND d.lang='en'
		   AND t.application_sid = security.security_pkg.GetApp
		   AND cat.app_sid = security.security_pkg.GetApp;
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
	END;

	-- Create calendar object if calendars are enabled
	BEGIN
		v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Calendars');
		calendar_pkg.RegisterCalendar(
			in_name => 'audits',
			in_js_include => '/csr/shared/calendar/includes/audits.js',
			in_js_class_type => 'Credit360.Calendars.Audits',
			in_description => 'Audits',
			out_calendar_sid => v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- Skip sites that don't have calendars enabled
	END;

	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class)
		VALUES ('audit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	chain.card_pkg.SetGroupCards('Internal Audit Filter', chain.T_STRING_LIST('Credit360.Audit.Filters.InternalAuditFilter', 'Credit360.Audit.Filters.AuditFilterAdapter', 'Credit360.Audit.Filters.AuditCMSFilter', 'Credit360.Audit.Filters.SurveyResponse'));
	chain.card_pkg.SetGroupCards('Non-compliance Filter', chain.T_STRING_LIST('Credit360.Audit.Filters.NonComplianceFilter', 'Credit360.Audit.Filters.NonComplianceFilterAdapter'));
	BEGIN
		chain.card_pkg.InsertGroupCard('Survey Response Filter', 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_AUDITOR, 'audit', 'Audit co-ordinator', 'CSRUser');

		INSERT INTO flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_AUDITOR, 'audit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY, 'audit', 'Auditor company', 'CSRUsers');

		INSERT INTO flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY, 'audit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.flow_inv_type_alert_class(flow_involvement_type_id, flow_alert_class)
		SELECT csr_data_pkg.FLOW_INV_TYPE_PURCHASER, 'audit'
		  FROM dual
		 WHERE EXISTS (
				SELECT 1
				  FROM csr.flow_involvement_type fit
				 WHERE fit.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_PURCHASER
		   );
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;

PROCEDURE EnableAuditMaps
AS
BEGIN
	UPDATE customer
	   SET show_map_on_audit_list = 1
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE EnableAuditFiltering
AS
	v_act_id					security.security_pkg.T_ACT_ID := sys_context('security','act');
	v_app_sid					security.security_pkg.T_SID_ID := sys_context('security','app');
	v_parent_sid				security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_parent_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/ia');
		security.menu_pkg.SetMenuAction(v_act_id, v_parent_sid, '/csr/site/audit/auditList.acds');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu'),
				'ia', 'Audit management', '/csr/site/audit/auditList.acds', 8, null, v_parent_sid);
	END;

	BEGIN
		v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_parent_sid, 'csr_audit_browse');
		security.menu_pkg.SetMenuAction(v_act_id, v_sid, '/csr/site/audit/auditList.acds');
		security.menu_pkg.SetMenuDescription(v_act_id, v_sid, 'Audits');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_parent_sid, 'csr_audit_list');
				security.menu_pkg.SetMenuAction(v_act_id, v_sid, '/csr/site/audit/auditList.acds');
				security.menu_pkg.SetMenuDescription(v_act_id, v_sid, 'Audits');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_parent_sid,
						'csr_audit_list', 'Audits', '/csr/site/audit/auditList.acds', 1, null, v_sid);
			END;
	END;

	BEGIN
		v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_parent_sid, 'csr_non_compliance_list');
		security.menu_pkg.SetMenuAction(v_act_id, v_sid, '/csr/site/audit/nonComplianceList.acds');
		security.menu_pkg.SetMenuDescription(v_act_id, v_sid, 'Findings');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id,  v_parent_sid,
				'csr_non_compliance_list', 'Findings', '/csr/site/audit/nonComplianceList.acds', 1, null, v_sid);
	END;

	chain.card_pkg.SetGroupCards('Internal Audit Filter', chain.T_STRING_LIST('Credit360.Audit.Filters.InternalAuditFilter', 'Credit360.Audit.Filters.AuditFilterAdapter', 'Credit360.Audit.Filters.AuditCMSFilter'));
	chain.card_pkg.SetGroupCards('Non-compliance Filter', chain.T_STRING_LIST('Credit360.Audit.Filters.NonComplianceFilter', 'Credit360.Audit.Filters.NonComplianceFilterAdapter'));
END;

PROCEDURE EnableAuditsOnUsers
AS
BEGIN
	UPDATE customer
	   SET audits_on_users = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EnableMultipleAuditSurveys
AS
BEGIN
	UPDATE customer
	   SET multiple_audit_surveys = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EnableBounceTracking
-- test data
AS
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	-- menu
	v_menu_bounces			security.security_pkg.T_SID_ID;
	-- web resources
	v_www				 	security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	/*** ADD MENU ITEM ***/
	BEGIN
	security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
		'csr_alerts_bounces', 'Alert bounces', '/csr/site/alerts/bounces.acds', 8, null, v_menu_bounces);
	EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
	END;

	UPDATE customer
	   SET bounce_tracking_enabled = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.EnableCapability('View alert bounces', 1);
END;

PROCEDURE EnableCompanyDedupePreProc
AS
	v_act_id			security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;

	v_sa_sid			security.security_pkg.T_SID_ID;

	v_wwwroot_sid		security.security_pkg.T_SID_ID;

	v_csr_forms_sid 		security.security_pkg.T_SID_ID;
	v_forms_chain_sid 	security.security_pkg.T_SID_ID;

	v_sub_table_sid 	security.security_pkg.T_SID_ID;
BEGIN

	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run SetupModules');
	END IF;

	-- set customer option flags
	UPDATE chain.customer_options
	   SET enable_dedupe_preprocess = 1
	 WHERE app_sid = security_pkg.getApp;

	INSERT INTO chain.dd_customer_blcklst_email (email_domain)
	SELECT LOWER(email_domain)
	  FROM chain.dd_def_blcklst_email
	 WHERE LOWER(email_domain) NOT IN (SELECT LOWER(email_domain) FROM chain.dd_customer_blcklst_email);

	-- register the chain dedupe_sub table
	cms.tab_pkg.registerTable('CHAIN', 'DEDUPE_SUB', FALSE, FALSE);

	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_sub_table_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'cms/"CHAIN"."DEDUPE_SUB"');
	v_sa_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_sub_table_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_sa_sid, cms.tab_pkg.PERMISSION_BULK_EXPORT);

	-- add a csr/forms web resource if there isn't one
	v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid,
			security.securableobject_pkg.GetSIDFromPath(v_act_id, v_wwwroot_sid, 'csr'), 'forms',
			security.Security_Pkg.SO_WEB_RESOURCE, null, v_csr_forms_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_csr_forms_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_wwwroot_sid, 'forms');
	END;

	--add a csr/forms/chain web resource if there isn't one
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_csr_forms_sid, 'chain', security.Security_Pkg.SO_WEB_RESOURCE, null, v_forms_chain_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_forms_chain_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_forms_sid, 'chain');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_forms_chain_sid), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'),
		security.security_pkg.PERMISSION_STANDARD_READ);

END;

PROCEDURE EnableAmforiIntegration
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_audit_type_cur				security.security_pkg.T_OUTPUT_CUR;
	v_expiry_alert_roles			security.security_pkg.T_SID_IDS;
	v_audit_types					security.security_pkg.T_SID_IDS;
	v_bsci_19_audit_type_id 		security.security_pkg.T_SID_ID;
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_wf_ct_sid						security.security_pkg.T_SID_ID;
	v_s1							security.security_pkg.T_SID_ID;
	v_flow_type						VARCHAR2(256);
	v_tag_group_id					tag_group.tag_group_id%TYPE;
	v_tag_id						tag.tag_id%TYPE;
	v_superadmins_sid				security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_app_sid      				security.security_pkg.T_SID_ID;
	v_www_ui_amfori_integration		security.security_pkg.T_SID_ID;
	v_www_app_ui_amfori_integration	security.security_pkg.T_SID_ID;
	v_survey_sid					security.security_pkg.T_SID_ID;
	v_measure_sid					security.security_pkg.T_SID_ID;
	v_curr_id						security.security_pkg.T_SID_ID;
	v_parent_1 						security.security_pkg.T_SID_ID;
	v_parent_2						security.security_pkg.T_SID_ID;
	v_xml							VARCHAR2(32000);
	v_create_internal_audit			BOOLEAN;
	v_audit_admin					security.security_pkg.T_SID_ID;
	--v_score_type_id					security.security_pkg.T_SID_ID;

	E_TOO_MANY_ROWS			EXCEPTION;
	PRAGMA EXCEPTION_INIT (E_TOO_MANY_ROWS, -01422);

	PROCEDURE AddClosureType(
		in_audit_type_id			csr.internal_audit_type.internal_audit_type_id%TYPE,
		in_label					VARCHAR2,
		in_lookup					VARCHAR2
	) AS
		v_audit_closure_type_id		csr.audit_closure_type.audit_closure_type_id%TYPE;
		v_create_failed				NUMBER:=0;
	BEGIN
		BEGIN
			INSERT INTO csr.audit_closure_type (app_sid, audit_closure_type_id, label, is_failure, lookup_key)
			VALUES (security.security_pkg.GetApp, csr.audit_closure_type_id_seq.NEXTVAL, in_label, 0, in_lookup)
			RETURNING audit_closure_type_id INTO v_audit_closure_type_id;
		EXCEPTION
			WHEN dup_val_on_index THEN
				v_create_failed := 1;
		END;

		BEGIN
			IF v_create_failed = 1 THEN
				SELECT audit_closure_type_id
					  INTO v_audit_closure_type_id
					  FROM csr.audit_closure_type
					 WHERE app_sid = security.security_pkg.GetApp
					   AND (label = in_label AND lookup_key IS NULL) OR lookup_key = in_lookup;

				UPDATE csr.audit_closure_type
				   SET lookup_key = in_lookup
				 WHERE app_sid = security.security_pkg.GetApp
				   AND audit_closure_type_id = v_audit_closure_type_id;
			END IF;
			EXCEPTION
				WHEN no_data_found THEN
					RAISE_APPLICATION_ERROR(-20001, 'Could not add or update the Closure Type ' || in_label || '. This may mean that there is already a closure type with the label ' || in_label || ' whose lookup key is not null and is not ' || in_lookup || '.');
		END;

		BEGIN
			INSERT INTO csr.audit_type_closure_type (app_sid, internal_audit_type_id, audit_closure_type_id, re_audit_due_after,
					re_audit_due_after_type, reminder_offset_days, reportable_for_months, ind_sid)
			VALUES (security.security_pkg.GetApp, in_audit_type_id, v_audit_closure_type_id, NULL, NULL, NULL, NULL, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN NULL;
		END;
	END;
	PROCEDURE AddQuestionOptions (
		in_id	NUMBER
	 ) AS
		v_id NUMBER;
	 BEGIN
		v_id := qs_question_option_id_seq.nextval;
		Insert into TEMP_QUESTION_OPTION (QUESTION_ID,QUESTION_VERSION,QUESTION_OPTION_ID,POS,LABEL,SCORE,HAS_OVERRIDE,SCORE_OVERRIDE,HIDDEN,COLOR,LOOKUP_KEY,OPTION_ACTION,NON_COMPLIANCE_POPUP,NON_COMP_DEFAULT_ID,NON_COMPLIANCE_TYPE_ID,NON_COMPLIANCE_LABEL,NON_COMPLIANCE_DETAIL,NON_COMP_ROOT_CAUSE,NON_COMP_SUGGESTED_ACTION,QUESTION_OPTION_XML)
		values (in_id,0,v_id,0,'A',null,0,null,0,null,null,'none',0,null,null,null,null,null,null,'<option action="none" id="'||v_id||'">A</option>');
		v_id := qs_question_option_id_seq.nextval;
		Insert into TEMP_QUESTION_OPTION (QUESTION_ID,QUESTION_VERSION,QUESTION_OPTION_ID,POS,LABEL,SCORE,HAS_OVERRIDE,SCORE_OVERRIDE,HIDDEN,COLOR,LOOKUP_KEY,OPTION_ACTION,NON_COMPLIANCE_POPUP,NON_COMP_DEFAULT_ID,NON_COMPLIANCE_TYPE_ID,NON_COMPLIANCE_LABEL,NON_COMPLIANCE_DETAIL,NON_COMP_ROOT_CAUSE,NON_COMP_SUGGESTED_ACTION,QUESTION_OPTION_XML)
		values (in_id,0,v_id,0,'B',null,0,null,0,null,null,'none',0,null,null,null,null,null,null,'<option action="none" id="'||v_id||'">B</option>');
		v_id := qs_question_option_id_seq.nextval;
		Insert into TEMP_QUESTION_OPTION (QUESTION_ID,QUESTION_VERSION,QUESTION_OPTION_ID,POS,LABEL,SCORE,HAS_OVERRIDE,SCORE_OVERRIDE,HIDDEN,COLOR,LOOKUP_KEY,OPTION_ACTION,NON_COMPLIANCE_POPUP,NON_COMP_DEFAULT_ID,NON_COMPLIANCE_TYPE_ID,NON_COMPLIANCE_LABEL,NON_COMPLIANCE_DETAIL,NON_COMP_ROOT_CAUSE,NON_COMP_SUGGESTED_ACTION,QUESTION_OPTION_XML)
		values (in_id,0,v_id,0,'C',null,0,null,0,null,null,'none',0,null,null,null,null,null,null,'<option action="none" id="'||v_id||'">C</option>');
		v_id := qs_question_option_id_seq.nextval;
		Insert into TEMP_QUESTION_OPTION (QUESTION_ID,QUESTION_VERSION,QUESTION_OPTION_ID,POS,LABEL,SCORE,HAS_OVERRIDE,SCORE_OVERRIDE,HIDDEN,COLOR,LOOKUP_KEY,OPTION_ACTION,NON_COMPLIANCE_POPUP,NON_COMP_DEFAULT_ID,NON_COMPLIANCE_TYPE_ID,NON_COMPLIANCE_LABEL,NON_COMPLIANCE_DETAIL,NON_COMP_ROOT_CAUSE,NON_COMP_SUGGESTED_ACTION,QUESTION_OPTION_XML)
		values (in_id,0,v_id,0,'D',null,0,null,0,null,null,'none',0,null,null,null,null,null,null,'<option action="none" id="'||v_id||'">D</option>');
		v_id := qs_question_option_id_seq.nextval;
		Insert into TEMP_QUESTION_OPTION (QUESTION_ID,QUESTION_VERSION,QUESTION_OPTION_ID,POS,LABEL,SCORE,HAS_OVERRIDE,SCORE_OVERRIDE,HIDDEN,COLOR,LOOKUP_KEY,OPTION_ACTION,NON_COMPLIANCE_POPUP,NON_COMP_DEFAULT_ID,NON_COMPLIANCE_TYPE_ID,NON_COMPLIANCE_LABEL,NON_COMPLIANCE_DETAIL,NON_COMP_ROOT_CAUSE,NON_COMP_SUGGESTED_ACTION,QUESTION_OPTION_XML)
		values (in_id,0,v_id,0,'E',null,0,null,0,null,null,'none',0,null,null,null,null,null,null,'<option action="none" id="'||v_id||'">E</option>');
	 END;
BEGIN
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	-- Add Workflow
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Amfori_BSCI');
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
				   AND cfac.flow_alert_class = 'audit';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please enable the audit module first');
			END;

			v_audit_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Audit administrators');

			-- create our workflow
			csr.flow_pkg.CreateFlow(
				in_label			=> 'Amfori_BSCI',
				in_parent_sid		=> v_wf_ct_sid,
				in_flow_alert_class	=> 'audit',
				out_flow_sid		=> v_workflow_sid
			);

			-- Initiate variables and populate temp tables
			v_s1 := csr.flow_pkg.GetNextStateId;

			csr.flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s1,
				in_label => 'Created',
				in_lookup_key => '',
				in_is_final => 1,
				in_state_colour => '3777539',
				in_editable_role_sids => null,
				in_non_editable_role_sids => null,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => v_audit_admin,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="769.2" y="839.6" />',
				in_flow_state_nature_id => null,
				in_survey_editable => 0,
				in_survey_tag_ids => null
			);

			csr.flow_pkg.SetFlowFromTempTables(
				in_flow_sid => v_workflow_sid,
				in_flow_label => 'Amfori_BSCI',
				in_flow_alert_class => 'audit',
				in_cms_tab_sid => null,
				in_default_state_id => v_s1
			);
	END;

	v_create_internal_audit := FALSE;
	BEGIN
		SELECT internal_audit_type_id
		  INTO v_bsci_19_audit_type_id
		  FROM internal_audit_type
		 WHERE app_sid = security.security_pkg.getapp
		   AND upper(lookup_key) = 'AMFORI_BSCI';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_create_internal_audit := TRUE;
	END;

	IF v_create_internal_audit = TRUE THEN
		BEGIN
			audit_pkg.saveinternalaudittype(
				in_internal_audit_type_id		=> null,
				in_label						=> 'BSCI',
				in_every_n_months				=> null,
				in_auditor_role_sid				=> null,
				in_audit_contact_role_sid		=> null,
				in_default_survey_sid			=> null,
				in_default_auditor_org			=> '',
				in_override_issue_dtm			=> 0,
				in_assign_issues_to_role		=> 0,
				in_auditor_can_take_ownership	=> 0,
				in_add_nc_per_question			=> 0,
				in_nc_audit_child_region		=> 0,
				in_flow_sid						=> v_workflow_sid,
				in_internal_audit_source_id		=> csr.audit_pkg.integration_audit_source_id,
				in_summary_survey_sid			=> null,
				in_send_auditor_expiry_alerts	=> 1,
				in_expiry_alert_roles			=> v_expiry_alert_roles,
				in_validity_months				=> null,
				in_involve_auditor_in_issues	=> 0,
				in_active						=> 0,
				out_cur							=> v_audit_type_cur
			);

			SELECT internal_audit_type_id
			  INTO v_bsci_19_audit_type_id
			  FROM internal_audit_type
			 WHERE app_sid = security.security_pkg.getapp
			   AND label = 'BSCI';

			UPDATE internal_audit_type
			   SET lookup_key = 'AMFORI_BSCI'
			 WHERE internal_audit_type_id = v_bsci_19_audit_type_id;
		EXCEPTION
			WHEN E_TOO_MANY_ROWS THEN
				RAISE_APPLICATION_ERROR(-20001, 'An Audit Type with label "BSCI" already exists. Rename/remove this type to remove the clash or set the lookup key to AMFORI_BSCI to reuse it.');
		END;
	END IF;

	v_audit_types(1) := v_bsci_19_audit_type_id;

	AddClosureType(v_bsci_19_audit_type_id, 'A', 'A');
	AddClosureType(v_bsci_19_audit_type_id, 'B', 'B');
	AddClosureType(v_bsci_19_audit_type_id, 'C', 'C');
	AddClosureType(v_bsci_19_audit_type_id, 'D', 'D');
	AddClosureType(v_bsci_19_audit_type_id, 'E', 'E');

	/* Don't add this here. The closure type score is used instead.
	SELECT MIN(score_type_id)
	  INTO v_score_type_id
	  FROM score_type
	 WHERE lookup_key = 'AMFORI_AUDIT_SCORE';

	IF v_score_type_id IS NULL THEN
		csr.quick_survey_pkg.SaveScoreType (
			in_score_type_id		=> NULL,
			in_label				=> 'Score',
			in_pos					=> 1,
			in_hidden				=> 0,
			in_allow_manual_set		=> 0,
			in_lookup_key			=> 'AMFORI_AUDIT_SCORE',
			in_applies_to_supplier	=> 0,
			in_reportable_months	=> 24,
			in_format_mask			=> '##0.00',
			in_applies_to_audits	=> 1,
			out_score_type_id		=> v_score_type_id
		);

		csr.quick_survey_pkg.SetScoreTypeAuditTypes(v_score_type_id, v_audit_types);
	END IF;
	*/

	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'Announcement Type',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_audits	=> 1,
		in_lookup_key			=> 'AMFORI_ANNOUNCE',
		out_tag_group_id		=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Semi Announced',
		in_pos					=> 0,
		in_lookup_key			=> 'AMFORI_SEMI_ANNOUNCED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Fully Unannounced',
		in_pos					=> 1,
		in_lookup_key			=> 'AMFORI_FULLY_UNANNOUNCED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Fully Announced',
		in_pos					=> 2,
		in_lookup_key			=> 'AMFORI_FULLY_ANNOUNCED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupIATypes(
		in_tag_group_id			=> v_tag_group_id,
		in_ia_ids				=> v_audit_types
	);

	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'Monitoring Type',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_audits	=> 1,
		in_lookup_key			=> 'AMFORI_MONITORING',
		out_tag_group_id		=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Full Monitoring',
		in_pos					=> 0,
		in_lookup_key			=> 'AMFORI_FULL_MONITORING',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Follow Up Monitoring',
		in_pos					=> 1,
		in_lookup_key			=> 'AMFORI_FOLLOW_UP_MONITORING',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupIATypes(
		in_tag_group_id			=> v_tag_group_id,
		in_ia_ids				=> v_audit_types
	);

	BEGIN
		INSERT INTO chain.reference (lookup_key, label, mandatory, reference_uniqueness_id, reference_location_id, show_in_filter, reference_id, reference_validation_id)
		VALUES ('AMFORI_SITEAMFORIID', 'Amfori Site ID', 0, chain.chain_pkg.REF_UNIQUE_NONE, chain.chain_pkg.REF_LOC_COMPANY_DETAILS, 1, chain.reference_id_seq.NEXTVAL, chain.chain_pkg.REFERENCE_VALIDATION_ALL);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		WHEN OTHERS THEN
			-- ORA-02291
			RAISE_APPLICATION_ERROR(-20001, 'Unable to add chain reference. Enable chain before enabling this module.');
	END;

	BEGIN
		INSERT INTO chain.reference (lookup_key, label, mandatory, reference_uniqueness_id, reference_location_id, show_in_filter, reference_id, reference_validation_id)
		VALUES ('AMFORI_COMPANYAMFORIID', 'Amfori Company ID', 0, chain.chain_pkg.REF_UNIQUE_NONE, chain.chain_pkg.REF_LOC_COMPANY_DETAILS, 1, chain.reference_id_seq.NEXTVAL, chain.chain_pkg.REFERENCE_VALIDATION_ALL);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	-- NEW STACK UI
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'app');

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.amfori-integration', v_www_ui_amfori_integration);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.amfori-integration', v_www_app_ui_amfori_integration);

	-- Superadmin wwwroot/ui.amfori-integration webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_amfori_integration), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Superadmin wwwroot/app/ui.amfori-integration webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_amfori_integration), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

END;

PROCEDURE EnableCalendar
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_calendar				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_calendar		security.security_pkg.T_SID_ID;
	-- temp variables
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := security_pkg.getAct;
	v_app_sid := security_pkg.getApp;

	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	BEGIN
	security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data'),
		'csr_calendar', 'Calendar', '/csr/site/calendar/calendar.acds', 10, null, v_menu_calendar);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_calendar := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data'), 'csr_calendar');
	END;

	/*** WEB RESOURCE ***/
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_calendar := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'calendar');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_calendar), v_reg_users_sid);
		-- add reg users to calendar web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_calendar), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'calendar', v_www_csr_site_calendar);
			-- add reg users to issues web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_calendar), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	BEGIN
		calendar_pkg.RegisterCalendar(
			in_name => 'issues',
			in_js_include => '/csr/shared/calendar/includes/issues.js',
			in_js_class_type => 'Credit360.Calendars.Issues',
			in_cs_class => 'Credit360.Issues.IssueCalendarDto',
			in_description => 'Issues coming due',
			out_calendar_sid => v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Audits');
		calendar_pkg.RegisterCalendar(
			in_name => 'audits',
			in_js_include => '/csr/shared/calendar/includes/audits.js',
			in_js_class_type => 'Credit360.Calendars.Audits',
			in_cs_class => 'Credit360.Audit.AuditCalendarDto',
			in_description => 'Audits',
			out_calendar_sid => v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- Skip sites that don't have audits enabled
	END;
END;

PROCEDURE EnableCampaigns
AS
	v_act_id					security.security_pkg.T_ACT_ID := security_pkg.getAct;
	v_app_sid					security.security_pkg.T_SID_ID := security_pkg.getApp;
	v_af_id						NUMBER(10,0);
	v_cust_alert_type_id 		NUMBER(10);
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_campaign				security.security_pkg.T_SID_ID;
	v_campaigns_sid				security.security_pkg.T_SID_ID;

	-- api.campaigns
	v_www_root				security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_api_campaigns		security.security_pkg.T_SID_ID;
	-- credit360.regions api
	v_www_regions_api	security.security_pkg.T_SID_ID;
	-- ui.campaigns
	v_www_ui_campaigns		security.security_pkg.T_SID_ID;
	v_www_app				security.security_pkg.T_SID_ID;
BEGIN
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	-- campaign list
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_quicksurvey_campaignlist', 'Survey campaigns', '/csr/site/quicksurvey/admin/CampaignList.acds', 7, null, v_menu_campaign);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	DELETE FROM alert_template_body
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND customer_alert_type_id IN (select customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id=31);

	DELETE FROM alert_template
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND customer_alert_type_id IN (select customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id=31);

	DELETE FROM customer_alert_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND customer_alert_type_id IN (select customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id=31);

	INSERT INTO customer_alert_type (app_sid, std_alert_type_id, customer_alert_type_id)
		VALUES (SYS_CONTEXT('SECURITY','APP'), 31, customer_alert_type_id_seq.nextval)
		RETURNING customer_alert_type_id INTO v_cust_alert_type_id;

	BEGIN
		SELECT MIN(alert_frame_id)
		  INTO v_af_id
		  FROM alert_frame
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		 GROUP BY app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			alert_pkg.CreateFrame('Default', v_af_id);
	END;

	INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES (SYS_CONTEXT('SECURITY','APP'), v_cust_alert_type_id, v_af_id, 'automatic');

	-- set the same template values for all langs in the app
	FOR r IN (
		SELECT lang
		  FROM aspen2.translation_set
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND hidden = 0
	) LOOP
		INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES (SYS_CONTEXT('SECURITY','APP'), v_cust_alert_type_id, r.lang,
			'<template>Survey Invitation</template>',
			'<template>'||
				'Hello,<br />'||
				'<br />'||
				'Please fill in the following survey:<br />'||
				'<br />'||
				'<mergefield name="SURVEY_URL" /><br />'||
				'<br />'||
				'Thank you for your cooperation. Sincerely, yours<br />'||
				'<mergefield name="FROM_NAME" />'||
			'</template>',
			'<template></template>');
	END LOOP;

	BEGIN
		v_campaigns_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Campaigns', v_campaigns_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_campaigns_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'),
				security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	BEGIN
		INSERT INTO CUSTOMER_FLOW_ALERT_CLASS (FLOW_ALERT_CLASS) VALUES ('campaign');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	INSERT INTO csr.flow_inv_type_alert_class(flow_involvement_type_id, flow_alert_class)
	SELECT csr_data_pkg.FLOW_INV_TYPE_PURCHASER, 'campaign'
	  FROM dual
	 WHERE EXISTS (
			SELECT 1
			  FROM csr.flow_involvement_type fit
			 WHERE fit.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_PURCHASER
	   );

	-- web resource for the api
	BEGIN
		v_www_api_campaigns := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'api.campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'api.campaigns', v_www_api_campaigns);
	END;

	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_campaigns), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- web resource for the app (that hosts the ui)
	BEGIN
		v_www_app := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'app');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'app', v_www_app);
	END;

	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- web resource for the credit360.regions api
	BEGIN
		v_www_regions_api := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'credit360.regions');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'credit360.regions', v_www_regions_api);
	END;
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_regions_api), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_regions_api), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- web resource for the ui
	BEGIN
		v_www_ui_campaigns := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'ui.campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'ui.campaigns', v_www_ui_campaigns);
	END;

	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_campaigns), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_AddCampaignsGrants;
END;

PROCEDURE ResetACEsToSpecificGroupOnly(
	in_object_sid	IN security.security_pkg.T_SID_ID,
	in_group_sid	IN security.security_pkg.T_SID_ID
	)
AS
	v_act			security.security_pkg.T_ACT_ID := sys_context('security','act');
BEGIN
	security.securableobject_pkg.ClearFlag(v_act, in_object_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(v_act, security.acl_pkg.GetDACLIDForSID(in_object_sid));
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(in_object_sid),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		in_group_sid,
		security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act, in_object_sid);
END;

PROCEDURE EnableCarbonEmissions
AS
	v_class_id					security.security_pkg.T_CLASS_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_carbon_admins_sid			security.security_pkg.T_SID_ID;
	v_auditors_sid				security.security_pkg.T_SID_ID;
	v_sa_sid					security.security_pkg.T_SID_ID;

	v_menu_admin				security.security_pkg.T_SID_ID;
	v_menu_carbon				security.security_pkg.T_SID_ID;
	v_menu_factorset			security.security_pkg.T_SID_ID;
	v_menu_setup				security.security_pkg.T_SID_ID;

	v_www						security.security_pkg.T_SID_ID;
	v_www_carbon				security.security_pkg.T_SID_ID;
	v_www_emissionfactors		security.security_pkg.T_SID_ID;

	v_act						security.security_pkg.T_ACT_ID;
	v_app						security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app := sys_context('security','app');
	v_act := sys_context('security','act');

	-- enable
	UPDATE customer
	   SET use_carbon_emission = 1
	 WHERE app_sid = v_app;

	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');

	-- create groups
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Emission factor Admins', v_class_id, v_carbon_admins_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_carbon_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Emission factor Admins');
	END;

	-- make admins members of carbon admins
	security.group_pkg.AddMember(v_act, v_admins_sid, v_carbon_admins_sid);

	-- add carbon menu items
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu/admin');

	-- Profile EF tool
	BEGIN
		security.menu_pkg.CreateMenu(
			in_act_id => v_act,
			in_parent_sid_id => v_menu_admin,
			in_name => 'csr_site_admin_emissionFactors_manage',
			in_description => 'Manage emission factors',
			in_action => '/csr/site/admin/emissionFactors/new/manage.acds',
			in_pos => 6,
			in_context => null,
			out_sid_id => v_menu_carbon
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_carbon := security.securableobject_pkg.GetSidFromPath(v_act, v_menu_admin, 'csr_site_admin_emissionFactors_manage');
	END;

	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_menu_carbon), -1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_carbon_admins_sid,
		security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.PropogateACEs(v_act, v_menu_carbon);

	v_menu_setup := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'menu/setup');

	BEGIN
		v_menu_factorset := security.securableobject_pkg.GetSidFromPath(v_act, v_menu_setup, 'csr_admin_factor_sets');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act, v_menu_setup, 'csr_admin_factor_sets', 'Factor sets',
				'/csr/site/admin/emissionFactors/new/factorsetgroups.acds', 0, null, v_menu_factorset);
	END;

	-- don't inherit dacls
	security.securableobject_pkg.SetFlags(v_act, v_menu_factorset, 0);
	--Remove inherited ones
	security.acl_pkg.DeleteAllACEs(v_act, security.acl_pkg.GetDACLIDForSID(v_menu_factorset));
	-- Add SA permission
	v_sa_sid := security.securableobject_pkg.GetSIDFromPath(v_act, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');

	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_menu_factorset), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);


	-- create web-resources
	v_www := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'wwwroot');
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www, security.securableobject_pkg.GetSidFromPath(v_act, v_www, 'csr/site/admin'), 'carbon', v_www_carbon);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_carbon := security.securableobject_pkg.GetSidFromPath(v_act, v_www, 'csr/site/admin/carbon');
	END;
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www, security.securableobject_pkg.GetSidFromPath(v_act, v_www, 'csr/site/admin'), 'emissionFactors', v_www_emissionfactors);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_emissionfactors := security.securableobject_pkg.GetSidFromPath(v_act, v_www, 'csr/site/admin/emissionFactors');
	END;

	ResetACEsToSpecificGroupOnly(v_www_carbon, v_carbon_admins_sid);
	ResetACEsToSpecificGroupOnly(v_www_emissionfactors, v_carbon_admins_sid);

	-- enable the manage emission factors capability
	csr_data_pkg.enablecapability('Manage emission factors');
	-- grant permission to carbon admins
	security.acl_pkg.AddACE(v_act,
		security.acl_pkg.GetDACLIDForSID(
		security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Capabilities/Manage emission factors')),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_carbon_admins_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);

	-- enable the view emission factors capability
	csr_data_pkg.enablecapability('View emission factors');
	EnableRegionEmFactorCascading(1);

	-- (SAT) Auditors don't seem to exist in all installations (?), so make it optional
	GetSidOrNullFromPath(v_groups_sid, 'Auditors', v_auditors_sid);

	-- grant permission to auditors
	IF v_auditors_sid IS NOT NULL THEN
		security.acl_pkg.AddACE(v_act,
			security.acl_pkg.GetDACLIDForSID(
				security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Capabilities/View emission factors')),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_auditors_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
END;

PROCEDURE EnableChain(
	siteName IN VARCHAR2
)
AS
	v_site_name				VARCHAR2(1000) DEFAULT siteName;
BEGIN
	chain.setup_pkg.EnableSite(v_site_name);
END;

PROCEDURE EnableChainActivities
AS
BEGIN
	chain.setup_pkg.EnableActivities;
END;

PROCEDURE EnableChainOneTier(
	in_site_name			IN VARCHAR2,
	in_top_company_name		IN VARCHAR2
)
AS
	v_sid					security_pkg.T_SID_ID;
	v_company_type			chain.company_type.lookup_key%TYPE;
	v_top_company_group_sid	security_pkg.T_SID_ID;
BEGIN
	chain.setup_pkg.EnableSite(
		in_site_name => in_site_name,
		in_overwrite_default_url => TRUE
	);
	chain.setup_pkg.EnableOneTier;

	IF in_top_company_name IS NOT NULL THEN
		SELECT lookup_key
		  INTO v_company_type
		  FROM chain.company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_top_company = 1;

		v_sid := chain.setup_pkg.CreateCompany(in_top_company_name, 'gb', v_company_type);

		v_top_company_group_sid := chain.setup_pkg.CreateUserGroupForCompany(v_sid);

	END IF;
END;

PROCEDURE EnableChainTwoTier(
	in_top_company_name		IN VARCHAR2
)
AS
	v_sid					security_pkg.T_SID_ID;
	v_company_type			chain.company_type.lookup_key%TYPE;
	v_top_company_group_sid	security_pkg.T_SID_ID;
BEGIN
	-- log on
	IF NOT chain.setup_pkg.IsChainEnabled THEN
		chain.setup_pkg.EnableSite;
	END IF;

	chain.setup_pkg.EnableTwoTier;
	IF in_top_company_name IS NOT NULL THEN
		SELECT lookup_key
		  INTO v_company_type
		  FROM chain.company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_top_company = 1;

		v_sid := chain.setup_pkg.CreateCompany(in_top_company_name, 'gb', v_company_type);

		v_top_company_group_sid := chain.setup_pkg.CreateUserGroupForCompany(v_sid);

	END IF;
END;

PROCEDURE CreateOwlClient(
	in_admin_access			IN VARCHAR2,
	in_handling_office		IN VARCHAR2,
	in_customer_name		IN VARCHAR2,
	in_parenthost			IN VARCHAR2
)
AS
	v_owl_counter			NUMBER := 0;
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;

	v_temp					security.security_pkg.T_SID_ID;
	v_handling_office_id	security.security_pkg.T_SID_ID;
	v_credit_module_id      NUMBER;
	TABLE_NOT_FOUND EXCEPTION;
	PRAGMA EXCEPTION_INIT(table_not_found, -942);
BEGIN
	-- log on
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := sys_context('security','act');

	-- To get this to work locally, make sure you're set up for OWL development - you've created owl.credit360.com
	-- and run client\owl\clean.bat - and then use CreateWebsiteDomainSoftLink.sql owl.credit360.com www.credit360.com

	-- there's RLS on this which breaks things if we don't do it like this...
	security.user_pkg.logonadmin(in_parenthost);

	-- check if OWL is available
	BEGIN
		EXECUTE IMMEDIATE
		'SELECT COUNT(*)'||CHR(10)||
		 'FROM OWL.CLIENT_MODULE'
		   INTO v_owl_counter;
	EXCEPTION
		WHEN TABLE_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR( -20001, 'No OWL defined' );
	END;

	BEGIN
		EXECUTE IMMEDIATE
			'SELECT  handling_Office_id'||CHR(10)||
			'FROM  owl.handling_office'||CHR(10)||
			'WHERE  UPPER(description) = UPPER(:1)'
		  INTO  v_handling_office_id
		USING in_handling_office;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Handling office "' || in_handling_office || '" not found');
	END;

	BEGIN
		-- owl.client_app gets written to via a trigger
		EXECUTE IMMEDIATE
			'INSERT INTO owl.owl_client (client_sid, name, handling_office_id, prospective, po_required, report_period)'||CHR(10)||
			'VALUES (:1, :2, :3, 1, 1, SYSDATE)'
		USING v_app_sid, in_customer_name, v_handling_office_id;

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE
				'SELECT  owl.credit_module.credit_module_id'||CHR(10)||
				'FROM  owl.client_module'||CHR(10)||
				'JOIN  owl.credit_module ON owl.client_module.credit_module_id = owl.credit_module.credit_module_id'||CHR(10)||
				'WHERE  lookup_Key = ''CLIENTCONNECT'' AND client_sid = :1'
		INTO v_credit_module_id
		USING v_app_sid;
	EXCEPTION
		 WHEN   NO_DATA_FOUND THEN
			EXECUTE IMMEDIATE
				'INSERT INTO owl.client_module (client_module_id, client_sid, credit_module_id, enabled, date_enabled)'||CHR(10)||
				'SELECT cms.item_id_seq.nextval, :1, credit_module_id, 1, SYSDATE'||CHR(10)||
				'FROM owl.credit_module'||CHR(10)||
				'WHERE lookup_Key = ''CLIENTCONNECT'''
			USING v_app_sid;
	END;

	BEGIN
		v_temp := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, '/Capabilities/Can view account manager details');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			csr_data_pkg.enablecapability('Can view account manager details');
	END;
END;

PROCEDURE CreateSectionStatus(
	in_act_id				security.security_pkg.T_ACT_ID,
	in_app_sid				security.security_pkg.T_SID_ID
)
AS
	v_default_status_sid	security.security_pkg.T_SID_ID;
	v_sid					security.security_pkg.T_SID_ID;
BEGIN
	-- XXX: this lot really dont' need to be SIDs - not sure if anyone uses the transition stuff on them? Hope not!
	-- update default status to be called 'Not covered'
	-- (red colour by default)
	SELECT MIN (default_status_sid) INTO v_default_status_sid FROM section_module;

	IF v_default_status_sid IS NULL THEN
		BEGIN
			SELECT DISTINCT section_status_sid INTO v_default_status_sid FROM section_status WHERE description = 'Not covered';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT DISTINCT section_status_sid INTO v_default_status_sid FROM section_status WHERE description = 'Editing';
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
					-- Add the default status (red) - from csr_app_body
					section_status_pkg.CreateSectionStatus('Editing', 15728640, 0, v_default_status_sid);
				END;
		END;
	END IF;

	UPDATE section_status
	   SET description = 'Not covered',
				 icon_path = '/csr/styles/images/griIcons/notCovered.gif',
				 pos = 3
	 WHERE section_status_sid = v_default_status_sid;

	-- create additional statuses and populate with icons

	-- dark green
	BEGIN
		section_status_pkg.CreateSectionStatus('Covered', 32768, 1, v_sid);
	EXCEPTION
		WHEN security_pkg.duplicate_object_name THEN
			v_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Text/Statuses/Covered');
	END;
	UPDATE section_status
	   SET icon_path = '/csr/styles/images/griIcons/covered.gif'
	 WHERE section_status_sid = v_sid;

	-- light green
	BEGIN
		section_status_pkg.CreateSectionStatus('Partly covered', 1107474, 2, v_sid);
	EXCEPTION
		WHEN security_pkg.duplicate_object_name THEN
			v_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Text/Statuses/Partly covered');
	END;
	UPDATE section_status
	   SET icon_path = '/csr/styles/images/griIcons/partlyCovered.gif'
	 WHERE section_status_sid = v_sid;

	-- white
	BEGIN
		section_status_pkg.CreateSectionStatus('Not applicable', 16777215, 4, v_sid);
	EXCEPTION
		WHEN security_pkg.duplicate_object_name THEN
			v_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Text/Statuses/Not applicable');
	END;
	UPDATE section_status
	   SET icon_path = '/csr/styles/images/griIcons/notApplicable.gif'
	 WHERE section_status_sid = v_sid;
END;

PROCEDURE CreateDocLibReportsFolder
AS
	v_def_doc_lib_sid		security.security_pkg.T_SID_ID;
	v_doc_folder_sid		security.security_pkg.T_SID_ID;
	v_reports_folder_sid	security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_def_doc_lib_sid := security.securableobject_pkg.GetSidFromPath(
			in_act				=> security.security_pkg.GetAct,
			in_parent_sid_id	=> security.security_pkg.GetApp,
			in_path				=> 'Documents'
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			EnableDocLib;
	END;

	v_doc_folder_sid := security.securableobject_pkg.GetSidFromPath(
		in_act				=> security.security_pkg.GetAct,
		in_parent_sid_id	=> security.security_pkg.GetApp,
		in_path				=> 'Documents/Documents'
	);

	BEGIN
		doc_folder_pkg.CreateFolder(
			in_parent_sid			=> v_doc_folder_sid,
			in_name					=> 'Reports',
			in_is_system_managed	=> 1,
			out_sid_id				=> v_reports_folder_sid
		);
	EXCEPTION
		WHEN security_pkg.duplicate_object_name THEN NULL;
	END;
END;

PROCEDURE EnableCorpReporter
AS
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_ACT_ID;
	-- groups
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_auditors_sid			security.security_pkg.T_SID_ID;
	v_reporters_sid			security.security_pkg.T_SID_ID;
	v_data_providers_sid	security.security_pkg.T_SID_ID;
	v_data_approvers_sid	security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_class_id				security.security_pkg.T_CLASS_ID;
	-- menu
	v_menu_parent_sid		security.security_pkg.T_SID_ID;
	v_menu_sid				security.security_pkg.T_SID_ID;
	v_menu_old_ctst_sid		security.security_pkg.T_SID_ID;
	v_menu_indexes			security.security_pkg.T_SID_ID;

	type T_STR is table of varchar2(128);
	v_names T_STR;
	v_menus T_STR;
	v_actions T_STR;
	v_perms T_STR;

	-- workflow
	v_indexes_root_sid		security.security_pkg.T_SID_ID;
	v_id					flow_item.flow_item_id%TYPE;
	v_default_status_sid	security.security_pkg.T_SID_ID;
	v_sid					security.security_pkg.T_SID_ID;
	v_workflow_sid			security.security_pkg.T_SID_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cr_role_sid			security.security_pkg.T_SID_ID;
	v_legal_role_sid		security.security_pkg.T_SID_ID;
	v_contrib_role_sid		security.security_pkg.T_SID_ID;
	v_doclib_sid			security.security_pkg.T_SID_ID;
	v_corp_lib_folder_sid	security.security_pkg.T_SID_ID;

	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_s3					security.security_pkg.T_SID_ID;
	v_s4					security.security_pkg.T_SID_ID;
	v_s5					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
	v_st2					security.security_pkg.T_SID_ID;
	v_st3					security.security_pkg.T_SID_ID;
	v_st4					security.security_pkg.T_SID_ID;
	v_st5					security.security_pkg.T_SID_ID;
	v_st6					security.security_pkg.T_SID_ID;
	v_st7					security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := security.security_pkg.getact;
	v_app_sid := security.security_pkg.GetApp;
	--
	InsertIntoOWLClientModule('CORP_REPORTER', null);

	-- new stuff
	csr_data_pkg.EnableCapability('Can edit section tags');
	csr_data_pkg.EnableCapability('Can view section tags');
	csr_data_pkg.EnableCapability('Can delete section comments');
	csr_data_pkg.EnableCapability('Manage text question carts');
	csr_data_pkg.EnableCapability('Ask for section edit message');
	csr_data_pkg.EnableCapability('Can view section history');
	csr_data_pkg.EnableCapability('Ask for section state change message');
	csr_data_pkg.EnableCapability('Can edit section docs');
	csr_data_pkg.EnableCapability('Can edit transition comment');

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_auditors_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');

	-- Reporters should exist but is missing on some older systems
	BEGIN
		v_reporters_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Reporters');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
			security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY,
				'Reporters', v_class_id, v_reporters_sid);
	END;

	-- May not be present
	GetSidOrNullFromPath(v_groups_sid, 'Data Providers', v_data_providers_sid);
	GetSidOrNullFromPath(v_groups_sid, 'Data Approvers', v_data_approvers_sid);

	GetSidOrNullFromPath(v_app_sid, 'Menu/indexes', v_menu_indexes);
	IF v_menu_indexes IS NOT NULL THEN
		-- just delete the old one.
		security.securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), v_menu_indexes);
	END IF;

	--delete old menu item from previous version
	GetSidOrNullFromPath(security.security_pkg.getApp, 'menu/data/csr_text_admin_list', v_menu_old_ctst_sid);
	IF v_menu_old_ctst_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), v_menu_old_ctst_sid);
	END IF;

	--
	-- /*** ADD MENU ITEM ***/
	v_names := T_STR(
		'frameworks',
		'csr_text_overview_user_view',
		'csr_text_admin_list2',
		'csr_text_overview_dashboard',
		'csr_text_overview_search',
		'csr_text_overview_filter',
		'csr_text_admin_cartfolder'
	);
	v_menus := T_STR(
		'Frameworks',
		'Your questions',
		'Framework list',
		'Dashboard',
		'Search',
		'Manage questions',
		'Manage carts'
	);
	v_actions := T_STR(
		'/csr/site/text/overview/userview.acds',
		'/csr/site/text/overview/userview.acds',
		'/csr/site/text/admin/list2.acds',
		'/csr/site/text/overview/dashboard.acds',
		'/csr/site/text/overview/search.acds',
		'/csr/site/text/overview/filter.acds',
		'/csr/site/text/admin/CartFolder.acds'
	);
	v_perms := T_STR(
		'ALL',
		'ALL',
		'ADMIN',
		'ADMIN',
		'ALL',
		'ADMIN',
		'ADMIN'
	);

	v_menu_parent_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.getApp, 'menu');

	FOR i IN 1 .. v_names.COUNT
	LOOP
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, v_menu_parent_sid,
				v_names(i), v_menus(i), v_actions(i), 1 + i, null, v_menu_sid);

			IF i = 1 THEN
				-- if it's the top, clear the inherits flag
				security.securableobject_pkg.ClearFlag(v_act_id, v_menu_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid));

				-- add admins to menu option (these propagate down so we don't set them lower)
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				-- add auditors to menu option (these propagate down so we don't set them lower)
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
					v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				--
				security.acl_pkg.PropogateACEs(v_act_id, v_menu_sid);
			END IF;

			IF v_perms(i) = 'ALL' THEN
				-- add data providers and approvers to menu option
				IF v_data_providers_sid IS NOT NULL THEN
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
						security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
						v_data_providers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				END IF;
				IF v_data_approvers_sid IS NOT NULL THEN
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
						security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
						v_data_approvers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				END IF;
				-- add reporters users to menu option
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
					v_reporters_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			END IF;

		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_parent_sid, v_names(i));
		END;
		IF i = 1 THEN
			-- the first item is the parent
			v_menu_parent_sid := v_menu_sid;
		END IF;
	END LOOP;

	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class)
		VALUES ('corpreporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- create workflow
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Corporate Reporter');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please run csr\db\utils\enableworkflow.sql first');
			END;

			-- create our workflow
			flow_pkg.CreateFlow('Corporate Reporter', v_wf_ct_sid, 'corpreporter', v_workflow_sid);

			v_s1 := flow_pkg.GetNextStateID;
			v_s2 := flow_pkg.GetNextStateID;
			v_s3 := flow_pkg.GetNextStateID;
			v_s4 := flow_pkg.GetNextStateID;
			v_s5 := flow_pkg.GetNextStateID;

			role_pkg.SetRole('Contributors', v_contrib_role_sid);
			role_pkg.SetRole('CR Team', v_cr_role_sid);
			role_pkg.SetRole('Legal Team', v_legal_role_sid);

			flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s1,
				in_label => 'Initial check',
				in_lookup_key => '',
				in_is_final => 0,
				in_state_colour => '10066329',
				in_editable_role_sids => null,
				in_non_editable_role_sids => null,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => null,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="679.5" y="808" />');

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s1,
				in_to_state_id => v_s2,
				in_ask_for_comment => 'optional',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '',
				in_verb => 'Send to business experts',
				in_lookup_key => '',
				in_helper_sp => '',
				in_role_sids => null,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st1);

			flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s2,
				in_label => 'With business experts',
				in_lookup_key => '',
				in_is_final => 0,
				in_state_colour => '16744960',
				in_editable_role_sids => null,
				in_non_editable_role_sids => v_contrib_role_sid,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => null,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="943.5" y="804" />');

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 6,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s2,
				in_to_state_id => v_s3,
				in_ask_for_comment => 'optional',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '',
				in_verb => 'Submit',
				in_lookup_key => '',
				in_helper_sp => '',
				in_role_sids => v_contrib_role_sid,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st2);

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 7,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s2,
				in_to_state_id => v_s1,
				in_ask_for_comment => 'required',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '/fp/shared/images/ic_return.gif',
				in_verb => 'Return to CR Team',
				in_lookup_key => 'RETURN_TO_CR',
				in_helper_sp => '',
				in_role_sids => v_contrib_role_sid,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st3);

			flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s4,
				in_label => 'Approved',
				in_lookup_key => '',
				in_is_final => 0,
				in_state_colour => '56576',
				in_editable_role_sids => null,
				in_non_editable_role_sids => null,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => null,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1223.5" y="801" />');

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 2,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s4,
				in_to_state_id => v_s2,
				in_ask_for_comment => 'optional',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '',
				in_verb => 'Return to business experts',
				in_lookup_key => '',
				in_helper_sp => '',
				in_role_sids => null,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st4);

			flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s3,
				in_label => 'Ready for review',
				in_lookup_key => '',
				in_is_final => 0,
				in_state_colour => '32513',
				in_editable_role_sids => null,
				in_non_editable_role_sids => v_cr_role_sid,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => null,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="920.5" y="952" />');

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 3,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s3,
				in_to_state_id => v_s5,
				in_ask_for_comment => 'optional',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '',
				in_verb => 'Send for legal review',
				in_lookup_key => '',
				in_helper_sp => '',
				in_role_sids => v_cr_role_sid,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st5);

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 4,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s3,
				in_to_state_id => v_s4,
				in_ask_for_comment => 'optional',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '',
				in_verb => 'Approve',
				in_lookup_key => '',
				in_helper_sp => '',
				in_role_sids => null,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st6);

			flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s5,
				in_label => 'Review by legal',
				in_lookup_key => '',
				in_is_final => 0,
				in_state_colour => '32513',
				in_editable_role_sids => null,
				in_non_editable_role_sids => v_legal_role_sid,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => null,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1211.5" y="945" />');

			flow_pkg.SetTempFlowStateTrans(
				in_flow_sid => v_workflow_sid,
				in_pos => 5,
				in_flow_state_transition_id => null,
				in_from_state_id => v_s5,
				in_to_state_id => v_s3,
				in_ask_for_comment => 'optional',
				in_mandatory_fields_message => '',
				in_hours_before_auto_tran => null,
				in_button_icon_path => '/fp/shared/images/ic_tick.gif',
				in_verb => 'Review completed',
				in_lookup_key => '',
				in_helper_sp => '',
				in_role_sids => v_legal_role_sid,
				in_column_sids => null,
				in_involved_type_ids => null,
				in_group_sids => null,
				in_attributes_xml => null,
				in_enforce_validation => 0,
				out_flow_state_transition_id => v_st7);

			flow_pkg.SetFlowFromTempTables(
				in_flow_sid => v_workflow_sid,
				in_flow_label => 'Corporate Reporter',
				in_flow_alert_class => 'corpreporter',
				in_cms_tab_sid => null,
				in_default_state_id => v_s1);
	END;

	-- link to arbirary top-level child of primary region tree
	UPDATE section_module
		SET flow_sid = v_workflow_sid,
			region_sid = (SELECT MIN(region_sid)
							FROM region
						WHERE parent_sid = (SELECT region_tree_root_sid
											  FROM region_tree
											 WHERE is_primary = 1
											   AND app_sid = security.security_pkg.getApp))
	 WHERE app_sid = security.security_pkg.getapp;

	FOR r IN (
		SELECT s.section_sid
		  FROM section_module sm
		  JOIN section s ON sm.module_root_sid = s.module_root_sid
		 WHERE sm.flow_sid IS NOT NULL
		   AND s.flow_item_id IS NULL
	)
	LOOP
		flow_pkg.AddSectionItem(r.section_sid, v_id);
	END LOOP;

	-- modules now go under a consistent root container
	BEGIN
		security.SecurableObject_pkg.CreateSO(v_act_id, security.security_pkg.getapp, security.security_pkg.SO_CONTAINER, 'Indexes', v_indexes_root_sid);
		security.securableobject_pkg.ClearFlag(v_act_id, v_indexes_root_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid));
		-- admins get all
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_cr_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE);
		-- the rest, less
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_legal_role_sid, security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_contrib_role_sid, security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_indexes_root_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.getapp, 'Indexes');
	END;

	FOR r IN (
		SELECT sm.module_root_sid, sm.label
		  FROM section_module sm
		  JOIN security.securable_object so ON sm.module_root_sid = so.sid_id
		 WHERE sm.app_sid = security.security_pkg.getApp
		   AND so.parent_sid_id != v_indexes_root_sid
	)
	LOOP
		dbms_output.put_line('Moving '||r.label||' under Indexes container...');
		security.securableobject_pkg.moveso(v_act_id, r.module_root_sid, v_indexes_root_Sid);
	END LOOP;

	security.acl_pkg.PropogateACEs(v_act_id, v_indexes_root_sid);


	-- TODO: add roles to web-resource (/text and /issues and /issues2)

	-- apply to all + do colours
	--UPDATE section_module
	--  SET show_flow_summary_tab = 1;

	-- fix up states
	BEGIN
		INSERT INTO section_routed_flow_state (flow_sid, flow_state_Id)
		 SELECT flow_sid, flow_state_id
		   FROM flow_state
		  WHERE	flow_sid = v_workflow_sid;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	FOR r IN (SELECT from_state_id, flow_state_Transition_id
				FROM flow_state_Transition
			   WHERE lookup_key IN ('RETURN_TO_CR')) LOOP
		UPDATE section_routed_flow_state SET reject_fs_transition_id = 	r.flow_state_Transition_id
		 WHERE app_sid = security.security_pkg.getApp
		   AND flow_state_id = r.from_state_id
		   AND flow_sid = v_workflow_sid;
	END LOOP;

	-- show summary
	UPDATE section_module
	   SET show_summary_tab = 1
	 WHERE app_sid = security.security_pkg.getApp;

	-- section status
	CreateSectionStatus(v_act_id, v_app_sid);

	-- create reports folder for publishing framework to doclib
	CreateDocLibReportsFolder;

	-- Enable alert type (if not enabled already)
	BEGIN
		INSERT INTO customer_alert_type (customer_alert_type_id, std_alert_type_id)
			SELECT customer_alert_type_id_seq.nextval, std_alert_type_Id
			  FROM std_alert_type
			 WHERE std_alert_type_id IN (44, 48, 49, 52, 53, 56);

		INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type)
			SELECT cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
			  FROM alert_frame af
			  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = security.security_pkg.GetApp
			   AND cat.std_alert_type_id IN (44, 48, 49, 52, 53, 56)
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;

		INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM default_alert_template_body d
			  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			 CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id IN (44, 48, 49, 52, 53, 56)
			   AND d.lang='en'
			   AND t.application_sid = security.security_pkg.GetApp
			   AND cat.app_sid = security.security_pkg.GetApp;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	FOR r IN (SELECT sm.app_sid, sm.label, sm.module_root_sid FROM section_module sm)
	LOOP
		BEGIN
			security.SecurableObject_pkg.CreateSO(v_act_id, r.app_sid, security.security_pkg.SO_CONTAINER, 'IndexLibs', v_corp_lib_folder_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_corp_lib_folder_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'IndexLibs');
		END;

		BEGIN
			doc_lib_pkg.CreateLibrary(
				v_corp_lib_folder_sid,
				r.label,
				'Documents',
				'Recycle bin',
				r.app_sid,
				v_doclib_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_doclib_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'IndexLibs/' || r.label);
		END;

		UPDATE section_module
		   SET library_sid = (SELECT documents_sid FROM doc_library WHERE doc_library_sid = v_doclib_sid)
		 WHERE app_sid = r.app_sid
		   AND module_root_sid = r.module_root_sid;
	END LOOP;
END;

PROCEDURE EnableCustomIssues
-- test data
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_issue_type			security.security_pkg.T_SID_ID;
	v_menu_create				security.security_pkg.T_SID_ID;
	v_menu_field_list			security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	--
	/*** ADD MENU ITEM ***/
	-- will inherit permissions from admin menu parent
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup'),
			'csr_issues2_admin_issuetype', 'Action types', '/csr/site/issues2/admin/issueType.acds', 10, null, v_menu_issue_type);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup'),
			'csr_issue_field_list', 'Action custom fields', '/csr/site/issues2/admin/fieldList.acds', 11, null, v_menu_field_list);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- will inherit permissions from data menu parent
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data'),
			'csr_issue_create', 'New action', '/csr/site/issues2/create.acds', 10, null, v_menu_create);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	UPDATE customer SET allow_custom_issue_types = 1;

	BEGIN
		INSERT INTO issue_type (issue_type_id, label, allow_children, create_raw)
			VALUES (csr_data_pkg.ISSUE_BASIC, 'Action', 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnableDelegPlan
AS
	v_class_id						security.security_pkg.T_CLASS_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;

	v_menu_admin					security.security_pkg.T_SID_ID;
	v_menu1							security.security_pkg.T_SID_ID;

	v_act							security.security_pkg.T_ACT_ID;
	v_app							security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app := sys_context('security','app');
	v_act := sys_context('security','act');

	-- enable
	UPDATE customer
	   SET allow_deleg_plan = 1
	 WHERE app_sid = v_app;

	-- Add foldering capability
	csr_data_pkg.enablecapability('Enable Delegation Plan Folders');

	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');

	-- add deleg plan menu items
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu_admin,
			'csr_delegation_plan',
			'Manage delegation plans',
			'/csr/site/delegation/manage/planList.acds',
			6, null, v_menu1);

		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
		security.acl_pkg.PropogateACEs(v_act, v_menu1);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE EnableDivisions
-- test data
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	-- groups
	v_class_id						security.security_pkg.T_CLASS_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_auditors_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_menu_regions_sid				security.security_pkg.T_SID_ID;
	v_menu_csr_imp_region_tree		security.security_pkg.T_SID_ID;
	v_menu_division_property		security.security_pkg.T_SID_ID;
	v_menu_division_report			security.security_pkg.T_SID_ID;
	-- web resources
	v_www							security.security_pkg.T_SID_ID;
	v_www_divisions					security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;

	-- read groups
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_auditors_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');


	-- add menu items
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'regions', 'Business structure', '/csr/site/schema/indRegion/regionTree.acds', 7, null, v_menu_regions_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_regions_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/regions');
	END;


	-- move existing region tree node
	BEGIN
		v_menu_csr_imp_region_tree := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin/csr_imp_region_tree');
		security.securableobject_pkg.MoveSO(v_act_id, v_menu_csr_imp_region_tree, v_menu_regions_sid);
		security.menu_pkg.SetPos(v_act_id, v_menu_csr_imp_region_tree, 0);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
			--Assume it has already been moved for rerunablity
	END;

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_regions_sid, 'division_report', 'Divisions', '/csr/site/division/DivisionReport.acds', 1, null, v_menu_division_report);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_division_report := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/regions/division_report');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_regions_sid, 'division_property', 'Properties', '/csr/site/division/Property.acds', 2, null, v_menu_division_property);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_division_property := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/regions/division_property');
	END;


	security.acl_pkg.PropogateACEs(v_act_id, v_menu_regions_sid);


	--
	-- add actions admins to top level menu option (inheritable)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_regions_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_regions_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_menu_regions_sid);
	--
	-- add permissions on new web-resource
	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site');
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www, v_www_csr_site, 'division', v_www_divisions);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			 v_www_divisions := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'division');
	END;
	-- add auditors and admins actions
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_divisions), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_divisions), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
END;

PROCEDURE EnableDocLib
-- test data
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_doclib_sid				security.security_pkg.T_SID_ID;
	v_doc_folder_sid			security.security_pkg.T_SID_ID;
	v_new_folder_sid			security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_doclib				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_root 					security.security_pkg.T_SID_ID;
	v_www_csr_site 				security.security_pkg.T_SID_ID;
	v_www_doclib 				security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	--

	InsertIntoOWLClientModule('DOCLIB', null);

	/*** CREATE LIBRARY ***/

	BEGIN
	doc_lib_pkg.CreateLibrary(
		v_app_sid,
		'Documents',
		'Documents',
		'Recycle bin',
		v_app_sid,
		v_doclib_sid);
	-- add in alerts for document library customers (19)
	INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT v_app_sid, customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM std_alert_type
		 WHERE std_alert_type_id = 19;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_doclib_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Documents');
	END;

	--
	-- set permissions on doclib itself
	security.securableobject_pkg.ClearFlag(v_act_id, v_doclib_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_doclib_sid), security.security_pkg.SID_BUILTIN_EVERYONE);
	-- add administrators
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_doclib_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	-- add reg users
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_doclib_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.PropogateACEs(v_act_id, v_doclib_sid);
	--
	/*** ADD MENU ITEM ***/

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data'),
			'csr_doclib', 'Documents', '/csr/site/doclib/doclib.acds', 8, null, v_menu_doclib);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_doclib := security.securableobject_pkg.GetSidFromPath(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data'), 'csr_doclib');
	END;

	--
	-- add registered users to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_doclib), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	--
	/*** WEB RESOURCE ***/
	-- add permissions on pre-created web-resources
	BEGIN
		v_www_doclib := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/doclib');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'doclib', v_www_doclib);
	END;

	--
	-- add registered users to web resource
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_doclib), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Add public and admins folders

	v_doc_folder_sid := security.securableobject_pkg.GetSidFromPath(
		in_act				=> v_act_id,
		in_parent_sid_id	=> v_app_sid,
		in_path				=> 'Documents/Documents'
	);

	doc_folder_pkg.CreateFolder(
		in_parent_sid			=> v_doc_folder_sid,
		in_name					=> 'Public',
		out_sid_id				=> v_new_folder_sid
	);

	doc_folder_pkg.CreateFolder(
		in_parent_sid			=> v_doc_folder_sid,
		in_name					=> 'Admin',
		out_sid_id				=> v_new_folder_sid
	);
	security.securableobject_pkg.ClearFlag(
		in_act_id	=> v_act_id,
		in_sid_id	=> v_new_folder_sid,
		in_flag		=> security.security_pkg.SOFLAG_INHERIT_DACL
	);
	security.acl_pkg.DeleteAllACEs(
		in_act_id	=> v_act_id,
		in_acl_id	=> security.acl_pkg.GetDACLIDForSID(v_new_folder_sid)
	);
	security.acl_pkg.AddACE(
		in_act_id			=> v_act_id,
		in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_new_folder_sid),
		in_acl_index		=> security_pkg.ACL_INDEX_LAST,
		in_ace_type			=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags		=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id			=> v_admins_sid,
		in_permission_set	=> security_pkg.PERMISSION_STANDARD_ALL
	);

END;

PROCEDURE EnableDonations
-- test data
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	-- groups
	v_class_id						security.security_pkg.T_CLASS_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_community_users_sid			security.security_pkg.T_SID_ID;
	v_community_admins_sid			security.security_pkg.T_SID_ID;
	v_auditors_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_menu_setup					security.security_pkg.T_SID_ID;
	v_menu_setup_fields				security.security_pkg.T_SID_ID;
	v_menu_donations				security.security_pkg.T_SID_ID;
	v_menu_donations_browse			security.security_pkg.T_SID_ID;
	v_menu_donations_reports		security.security_pkg.T_SID_ID;
	v_menu_donations_setup			security.security_pkg.T_SID_ID;
	v_menu_donations_letters		security.security_pkg.T_SID_ID;
	-- web resources
	v_www_donations 				security.security_pkg.T_SID_ID;
	v_www_donations_admin 			security.security_pkg.T_SID_ID;
	v_www_donations_reports			security.security_pkg.T_SID_ID;
	v_www_donations2 				security.security_pkg.T_SID_ID;
	v_www_donations2_admin			security.security_pkg.T_SID_ID;
	v_www_donations2_reports		security.security_pkg.T_SID_ID;
	-- containers
	v_donations_sid 				security.security_pkg.T_SID_ID;
	v_donations_recipients_sid		security.security_pkg.T_SID_ID;
	v_donations_regiongroups_sid	security.security_pkg.T_SID_ID;
	v_donations_schemes_sid			security.security_pkg.T_SID_ID;
	v_donations_statuses_sid		security.security_pkg.T_SID_ID;
	v_donations_taggroups_sid		security.security_pkg.T_SID_ID;
	v_donations_transitions_sid		security.security_pkg.T_SID_ID;

BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id := SYS_CONTEXT('SECURITY', 'Act');

	InsertIntoOWLClientModule('COMMUNITY', null);

	--
	-- read groups
	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_auditors_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
	v_admins_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	-- create groups
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Community Users', v_class_id, v_community_users_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_community_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Community Users');
	END;
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Community Admins', v_class_id, v_community_admins_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_community_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Community Admins');
	END;
	-- make community admins members of community users
	security.group_pkg.AddMember(v_act_id, v_community_admins_sid, v_community_users_sid);
	-- make admins members of community admins
	security.group_pkg.AddMember(v_act_id, v_admins_sid, v_community_admins_sid);
	-- Set the default URL for these community users because they won't have access to the main my data
	-- Except that Super admins = admins = community users => this home page!
	-- should be resolved with the introduction of the portal page (i.e. everyone goes to same place)
	-- security.web_pkg.SetHomePage(v_act_id, v_app_sid, v_community_users_sid, '/csr/site/donations2/browse.acds');
	--
	-- add menu items
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu');

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'donations_schemes', 'Community Involvement', '/csr/site/donations2/browse.acds', 5, null, v_menu_donations);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_donations := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_sid, 'donations_schemes');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_donations, 'donations_browse_2', 'Browse', '/csr/site/donations2/browse.acds', 1, null, v_menu_donations_browse);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_donations_browse := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_donations, 'donations_browse_2');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_donations, 'donations_reports_pivot_table_2', 'Reports', '/csr/site/donations/reports/pivotTable2.acds', 2, null, v_menu_donations_reports);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_donations_reports := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_donations, 'donations_reports_pivot_table_2');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_donations, 'donations_setup', 'Setup', '/csr/site/donations/admin/setup.acds', 3, null, v_menu_donations_setup);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_donations_setup := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_donations, 'donations_setup');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_donations, 'donations_letters', 'Configure letters', '/csr/site/donations2/admin/letters.acds', 3, null,v_menu_donations_letters);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_donations_letters := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_donations, 'donations_letters');
	END;

	-- setup menu bits
	v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_sid, 'setup');

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_setup, 'csr_site_donations2_admin_editfield', 'Edit donation fields', '/csr/site/donations2/admin/editField.acds', 9, null, v_menu_setup_fields);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_menu_setup_fields := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_setup, 'csr_site_donations2_admin_editfield');
	END;

	/*** add community admins to TOP level menu option (inheritable) ***/

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_community_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	---
	/*** add community users to specific items (just TOP, BROWSE + REPORTS atm) ***/
	-- top
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- browse
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations_browse), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- reports
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations_reports), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	---
	/*** add auditors to specific items (just TOP, BROWSE + REPORTS atm) ***/
	-- top
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- browse
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations_browse), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- reports
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_donations_reports), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_menu_donations);
	--
	-- add permissions on pre-created web-resources
	v_www_donations 		 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/donations');
	v_www_donations_admin 	 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/donations/admin');
	v_www_donations_reports	 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/donations/reports');
	v_www_donations2 		 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/donations2');
	v_www_donations2_admin 	 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/donations2/admin');
	v_www_donations2_reports := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/donations2/reports');

	-- clear flag on donations/admin + donations2/admin and add community_admins
	security.securableobject_pkg.ClearFlag(v_act_id, v_www_donations_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.securableobject_pkg.ClearFlag(v_act_id, v_www_donations2_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	--
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_donations_admin), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_donations2_admin), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--

	-- add auditors and donations users to donations + donations2
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_donations), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_donations2), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_donations), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_donations2), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_www_donations);
	security.acl_pkg.PropogateACEs(v_act_id, v_www_donations2);
	--

	/*** add portlets ***/
	FOR r IN( SELECT portlet_id
				FROM portlet
			   WHERE type IN ('Credit360.Portlets.Donated', 'Credit360.Portlets.AddDonation')
				 AND portlet_id NOT IN (SELECT portlet_id FROM customer_portlet WHERE app_sid = v_app_sid))
	LOOP
		portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;


	/*** Create Donations container ***/
	-- Donations
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER,
			'Donations', v_donations_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Donations');
	END;

	/*** Set permission for main Donations container ***/

	-- Add ALL for Community Admins to Donations
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_donations_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Add READ for Community Users to Donations
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_donations_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);


	/*** Create donation sub containers ***/
	-- Recipients
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'Recipients', v_donations_recipients_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_recipients_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'Recipients');
	END;

	-- Add ALL for Community Users to Donations/Recipients
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_donations_recipients_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- RegionGroups
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'RegionGroups', v_donations_regiongroups_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_regiongroups_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'RegionGroups');
	END;

	-- Schemes
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'Schemes', v_donations_schemes_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_schemes_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'Schemes');
	END;

	-- Add WRITE for Community Users to Donations/Schemes (so by default they're able to update donation)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_donations_schemes_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_WRITE);

	-- Statuses
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'Statuses', v_donations_statuses_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_statuses_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'Statuses');
	END;

	-- Add WRITE for Community Users to Donations/Statuses (so by default they're able to update donation)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_donations_statuses_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_community_users_sid, security.security_pkg.PERMISSION_WRITE);

	-- TagGroups
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'TagGroups', v_donations_taggroups_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_taggroups_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'TagGroups');
	END;

	-- Transitions
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_donations_sid, security.security_pkg.SO_CONTAINER, 'Transitions', v_donations_transitions_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_donations_transitions_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_donations_sid, 'Transitions');
	END;

	--
	security.acl_pkg.PropogateACEs(v_act_id, v_donations_sid);


	csr_data_pkg.enablecapability('Configure Community Involvement module');
	-- enable reports
	sqlreport_pkg.EnableReport('donations.reports_pkg.getrecipients');
	sqlreport_pkg.EnableReport('donations.reports_pkg.getpossibleduperecipients');

	DONATIONS.SYS_PKG.Enabledonations(v_act_id, v_app_sid);
END;

PROCEDURE EnableExcelModels
AS
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	-- groups
	v_class_id				security.security_pkg.T_CLASS_ID;
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_model_users_sid		security.security_pkg.T_SID_ID;
	v_model_admins_sid		security.security_pkg.T_SID_ID;
	-- menu
	v_menu  				security.security_pkg.T_SID_ID;
	v_menu_admin			security.security_pkg.T_SID_ID;
	v_menu_models			security.security_pkg.T_SID_ID;
	-- web resources
	v_www					security.security_pkg.T_SID_ID;
	v_www_models 			security.security_pkg.T_SID_ID;
	-- containers
	v_models_sid 			security.security_pkg.T_SID_ID;
	v_model_can_edit_sid	security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	InsertIntoOWLClientModule('EXCEL_MODELS', null);

	-- create groups
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Model Users', v_class_id, v_model_users_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_model_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Model Users');
	END;
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Model Admins', v_class_id, v_model_admins_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_model_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Model Admins');
	END;
	-- make model admins members of model users
	security.group_pkg.AddMember(v_act_id, v_model_admins_sid, v_model_users_sid);
	-- make admins members of model admins
	security.group_pkg.AddMember(v_act_id, v_admins_sid, v_model_admins_sid);

	/* MENU */
	-- add model menu items
	v_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/analysis');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu, 'csr_models', 'Models', '/csr/site/models/models.acds', 6, null, v_menu_models);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_models := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'csr_models');
	END;
	--
	/*** add model users to TOP level menu options (inheritable) ***/
	-- top
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_models), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_model_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_menu_models);
	--
	-- create web-resources
	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	-- create csr/site/models
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site'), 'models', v_www_models);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_models := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site/models');
	END;

	security.securableobject_pkg.ClearFlag(v_act_id, v_www_models, security.security_pkg.SOFLAG_INHERIT_DACL);

	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_models));

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_models), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_model_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	--
	security.acl_pkg.PropogateACEs(v_act_id, v_www_models);

	/*** Create Models container***/
	-- Models
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER,
			'Models', v_models_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_models_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Models');
	END;

	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_models_sid));

	/*** Set permission for main Model container ***/
	-- Add ALL for Supplier Admins to Supplier
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_models_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_model_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Add READ for Supplier Users to Supplier
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_models_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_model_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);


	/*** Create model sub containers ***/
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_models_sid, security.security_pkg.SO_CONTAINER,
			'CanEditModel', v_model_can_edit_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_model_can_edit_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Models/CanEditModel');
	END;

	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_model_can_edit_sid));

	/*** Set permission for main Model container ***/
	-- Add ALL for Model Admins to Models
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_model_can_edit_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_model_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Add READ for Model Users to Models
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_model_can_edit_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_model_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act_id, v_models_sid);

	-- enable the model loading capability
	csr_data_pkg.enablecapability('Load models into the calculation engine');
END;

PROCEDURE EnableFeeds(
	in_user IN CSR_USER.user_NAME%TYPE,
	in_password IN VARCHAR2
)
AS
	v_user_sid		security.security_pkg.T_SID_ID;
	v_feeds_sid		security.security_pkg.T_SID_ID;
	v_feeds_grp		security.security_pkg.T_SID_ID;
	v_inds_sid		security.security_pkg.T_SID_ID;
	v_regions_sid	security.security_pkg.T_SID_ID;
BEGIN
	-- try to create a user group (better for setting permissions)
	BEGIN
		security.group_pkg.CreateGroupWithClass(
			security.security_pkg.getACT,
			security.securableobject_pkg.getSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Groups'),
			security.security_pkg.GROUP_TYPE_SECURITY,
			'Data feeds',
			security.class_pkg.getclassid('CSRUserGroup'),
			v_feeds_grp
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_feeds_grp := security.securableobject_pkg.getSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Groups/Data feeds');
	END;

	csr_user_pkg.createUser(
		in_act			 			=> security.security_pkg.getACT,
		in_app_sid					=> security.security_pkg.getApp,
		in_user_name				=> in_user,
		in_password 				=> in_password,
		in_full_name				=> 'Feed User',
		in_friendly_name			=> 'Feed User',
		in_email		 			=> 'no-reply@cr360.com',
		in_job_title				=> null,
		in_phone_number				=> null,
		in_info_xml					=> null,
		in_send_alerts				=> 0,
		in_account_expiry_enabled	=> 0,
		out_user_sid 				=> v_user_sid
	);

	security.group_pkg.AddMember(
		security.security_pkg.getACT,
		v_user_sid,
		v_feeds_grp
	);

	BEGIN
		security.securableobject_pkg.CreateSO(
			security.security_pkg.getACT, security.security_pkg.getApp, security.security_pkg.SO_CONTAINER, 'Feeds',
			v_feeds_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_feeds_sid := security.securableobject_pkg.getSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Feeds');
	END;
	-- set some permissions
	v_inds_sid := security.securableobject_pkg.getSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Indicators');
		security.acl_pkg.AddACE(security.security_pkg.getACT,
		security.acl_pkg.GetDACLIDForSID(v_inds_sid),
		security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_feeds_grp, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(security.security_pkg.getACT, v_inds_sid);

	v_regions_sid := security.securableobject_pkg.getSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Regions');
		security.acl_pkg.AddACE(security.security_pkg.getACT,
		security.acl_pkg.GetDACLIDForSID(v_regions_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_feeds_grp, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(security.security_pkg.getACT, v_regions_sid);

	security.acl_pkg.AddACE(security.security_pkg.getACT,
		security.acl_pkg.GetDACLIDForSID(v_feeds_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_feeds_grp, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(security.security_pkg.getACT, v_feeds_sid);
END;

PROCEDURE EnableFilterAlerts
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_admin_sid				security_pkg.T_SID_ID;
	v_menu_admin_manage_sid			security_pkg.T_SID_ID;

	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_site					security_pkg.T_SID_ID;
	v_www_csr_site_filter			security_pkg.T_SID_ID;
	v_reg_users_sid					security_pkg.T_SID_ID;
BEGIN

	-- Create menu item (if not created already)
	v_menu_admin_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin_sid, 'filters_manage_alerts', 'Filter alerts', '/csr/site/filters/manageAlerts.acds', 15, null, v_menu_admin_manage_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_menu_admin_manage_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_admin_sid, 'filters_manage_alerts');
	END;

	-- Enable capability
	csr_data_pkg.EnableCapability('Can manage filter alerts');

	-- Grant access to web resource (if doesn't exist already)
	v_www_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_filter := securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'filters');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'filters', v_www_csr_site_filter);

			-- Grant ACEs only if doesn't exist
			v_reg_users_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_filter), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;


	-- Enable alert template (if not enabled already)
	-- Use hard-coded template instead of default_alert_template because the latter
	-- would add to all new sites, regardless of whether they have this feature enabled
	BEGIN
		INSERT INTO customer_alert_type (customer_alert_type_id, std_alert_type_id)
		VALUES (customer_alert_type_id_seq.nextval, 71);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
	END;

	BEGIN
		INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type)
		SELECT cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
		  FROM alert_frame af
		  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
		 WHERE af.app_sid = v_app_sid
		   AND cat.std_alert_type_id IN (71)
		 GROUP BY cat.customer_alert_type_id
		HAVING MIN(af.alert_frame_id) > 0;

		INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.customer_alert_type_id, t.lang,
			   '<template>There are new items in your saved filter</template>',
			   '<template>Hello,<br /><br />There are new items in your saved filter. <mergefield name="LIST_PAGE_URL" /><br /><br /><mergefield name="ITEMS" /><br /></template>',
			   '<template><mergefield name="OBJECT_ID" /><br /><br /></template>'
		  FROM customer_alert_type cat
		  JOIN alert_template at ON cat.customer_alert_type_id = at.customer_alert_type_id
		  CROSS JOIN aspen2.translation_set t
		 WHERE cat.std_alert_type_id IN (71)
		   AND t.application_sid = v_app_sid
		   AND cat.app_sid = v_app_sid;
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
	END;
END;

PROCEDURE EnableFogbugz(
	in_customer_fogbugz_project_id 	IN NUMBER,
	in_customer_fogbugz_area 		IN VARCHAR2
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_groups_sid				security_pkg.T_SID_ID;
	v_owl_support_sid			security_pkg.T_SID_ID;
	v_support_menu				security_pkg.T_SID_ID;
	v_menu						security_pkg.T_SID_ID;

	v_ix_prj					customer.fogbugz_ixproject%TYPE DEFAULT in_customer_fogbugz_project_id;
	v_s_area					customer.fogbugz_sarea%TYPE DEFAULT in_customer_fogbugz_area;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	v_groups_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	BEGIN
		v_owl_support_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_groups_sid, 'OwlSupport');
		v_support_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Menu/support');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND	THEN
			RAISE_APPLICATION_ERROR(-20001, 'OWL Support must be enabled first -- try running Enable Owl Support');
	END;

	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			v_support_menu,
			'owl_support_caselist',
			'Support cases',
			'/owl/support/caselist.acds',
			3,
			null,
			v_menu
		);

		-- don't inherit
		security.securableObject_pkg.ClearFlag(
			v_act_id,
			v_menu,
			security.security_pkg.SOFLAG_INHERIT_DACL
		);

		-- Set permissions
		security.acl_pkg.DeleteAllACEs(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_menu)
		);

		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_menu),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_owl_support_sid,
			security.security_pkg.PERMISSION_STANDARD_READ
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			DBMS_OUTPUT.PUT_LINE('Support cases menu already exists');
	END;

	UPDATE customer
	   SET FOGBUGZ_IXPROJECT = NVL(v_ix_prj, 0),
			FOGBUGZ_SAREA = v_s_area
	 WHERE app_sid = security_pkg.GetApp;

	BEGIN
		csr_data_pkg.EnableCapability('Read Fogbugz');
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

FUNCTION IsGRESBEnabled
RETURN NUMBER
AS
	v_check	NUMBER(1);
BEGIN
	SELECT CASE
				WHEN gresb_service_config = 'live' OR gresb_service_config = 'sandbox' THEN 1
				ELSE 0
			END
	  INTO v_check
	  FROM property_options
	 WHERE app_sid = SYS_CONTEXT('security', 'app');

	RETURN v_check;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;
END;

PROCEDURE EnableGRESB(
	in_environment				IN VARCHAR2,
	in_floor_area_measure_type	IN VARCHAR2
)
AS
	v_property_admin_sid	security.security_pkg.T_SID_ID;
	v_property_sid			security.security_pkg.T_SID_ID;
	v_menu_sid				security.security_pkg.T_SID_ID;
	v_www_sid				security.security_pkg.T_SID_ID;
	v_www_property			security.security_pkg.T_SID_ID;
	v_web_sid				security.security_pkg.T_SID_ID;
	v_old_gresb_menu_sid	security.security_pkg.T_SID_ID;

	v_measure_sid				measure.measure_sid%TYPE;
	v_measure_desc				measure.description%TYPE;
	v_std_measure_conversion_id	measure.std_measure_conversion_id%TYPE;
	v_gresb_service_config		property_options.gresb_service_config%TYPE;
BEGIN
	/*** ADD MENU ITEMS ***/
	BEGIN
		-- will inherit permissions from admin menu parent
		v_property_admin_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/admin/csr_property_admin_menu');
	EXCEPTION
		WHEN OTHERS THEN RAISE_APPLICATION_ERROR(-20001, 'The Property Admin menu does not exist - enable Properties first.');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_property_admin_sid, 'csr_property_gresb_entitylist', 'GRESB', '/csr/site/property/gresb/entityList.acds', 10, null, v_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_property_admin_sid, 'csr_gresb', 'GRESB Indicator Mapping', '/csr/site/property/admin/gresb/indicatorMapping.acds', 11, null, v_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		v_old_gresb_menu_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/admin/csr_property_admin_menu/csr_gresb');
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, v_old_gresb_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	v_property_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/csr_properties_menu');
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_property_sid, 'csr_property_gresb_entitylist', 'GRESB', '/csr/site/property/gresb/entityList.acds', -1, null, v_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_property_sid, 'csr_gresb', 'GRESB Indicator Mapping', '/csr/site/property/admin/gresb/indicatorMapping.acds', -1, null, v_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;


	v_www_sid := securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'wwwroot');
	v_www_property := securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_www_sid, 'csr/site/property');

	BEGIN
		v_web_sid := securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_www_property, 'gresb');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.GetACT, v_www_sid, v_www_property, 'gresb', v_web_sid);

			-- Grant ACEs only if doesn't exist
			security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_web_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Groups/Administrators'), security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	IF in_environment IS NOT NULL AND
	   LOWER(in_environment) != 'sandbox' AND
	   LOWER(in_environment) != 'live' THEN
		RAISE_APPLICATION_ERROR(-20001, 'The Gresb environment must be sandbox or live.');
	END IF;
	IF in_environment IS NULL THEN
		BEGIN
			SELECT gresb_service_config
			  INTO v_gresb_service_config
			  FROM property_options
			 WHERE app_sid = security.security_pkg.GetApp;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20001, 'Missing property options record.');
		END;
		IF v_gresb_service_config IS NULL OR
		   (v_gresb_service_config != 'sandbox' AND
			v_gresb_service_config != 'live') THEN
			RAISE_APPLICATION_ERROR(-20001, 'The Gresb environment must be set to sandbox or live.');
		END IF;
	END IF;


	IF in_environment IS NOT NULL THEN
		UPDATE property_options
		   SET gresb_service_config = LOWER(in_environment)
		 WHERE app_sid = security.security_pkg.GetApp;
	END IF;

	property_pkg.EnableMultiFund();

	BEGIN
		SELECT measure_sid, description
		  INTO v_measure_sid, v_measure_desc
		  FROM measure
		 WHERE app_sid = security.security_pkg.GetApp
		   AND lookup_key = 'GRESB_FLOORAREA';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;
	
	IF v_measure_sid IS NULL AND
		in_floor_area_measure_type IS NULL
	THEN
		-- error, need to create one, so need a label
		RAISE_APPLICATION_ERROR(-20001, 'An existing measure with lookup key GRESB_FLOORAREA was not found. A floor area label must be supplied.');
	END IF;

	IF in_floor_area_measure_type != 'm^2' AND
	   in_floor_area_measure_type != 'ft^2' THEN
		RAISE_APPLICATION_ERROR(-20001, 'The floor area label must be m^2 or ft^2');
	END IF;

	IF in_floor_area_measure_type = 'm^2' THEN
		SELECT std_measure_conversion_id
		  INTO v_std_measure_conversion_id
		  FROM std_measure_conversion
		 WHERE description = 'm^2';
	ELSIF in_floor_area_measure_type = 'ft^2' THEN
		SELECT std_measure_conversion_id
		  INTO v_std_measure_conversion_id
		  FROM std_measure_conversion
		 WHERE description = 'ft^2';
	END IF;

	IF v_measure_sid IS NULL
	THEN
		measure_pkg.CreateMeasure(
			in_name => 'GRESB ' || in_floor_area_measure_type,
			in_description => in_floor_area_measure_type,
			in_lookup_key => 'GRESB_FLOORAREA',
			in_std_measure_conversion_id => v_std_measure_conversion_id,
			out_measure_sid => v_measure_sid
		); 
	ELSIF in_floor_area_measure_type IS NOT NULL AND
		v_measure_sid IS NOT NULL AND
		v_measure_desc != in_floor_area_measure_type
	THEN
		UPDATE measure
		   SET name = 'GRESB ' || in_floor_area_measure_type,
			   description = in_floor_area_measure_type,
			   std_measure_conversion_id = v_std_measure_conversion_id
		 WHERE app_sid = security.security_pkg.GetApp
		   AND lookup_key = 'GRESB_FLOORAREA';
	END IF;
END;

PROCEDURE DisableGresb
AS
	v_measure_sid	security.security_pkg.T_SID_ID;
BEGIN
	UPDATE property_options
	   SET gresb_service_config = NULL
	 WHERE app_sid = security.security_pkg.GetApp;

	BEGIN
		SELECT measure_sid
		  INTO v_measure_sid
		  FROM measure
	 	 WHERE app_sid = security.security_pkg.GetApp
		   AND lookup_key = 'GRESB_FLOORAREA';
		
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, v_measure_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
		WHEN OTHERS THEN
			UPDATE measure
			   SET name = name || ' - disabled ' || SYSDATE,
				   description = description || ' - disabled ' || SYSDATE,
				   lookup_key = NULL
			WHERE app_sid = security.security_pkg.GetApp
			  AND lookup_key = 'GRESB_FLOORAREA';
	END;
END;

PROCEDURE INTERNAL_SetHiggModuleTagGroup(
	in_app_sid						IN	security.security_pkg.T_SID_ID,
	in_higg_module_id				IN	chain.higg_module.higg_module_id%TYPE,
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO chain.higg_module_tag_group (app_sid, higg_module_id,tag_group_id) VALUES (in_app_sid, in_higg_module_id, in_tag_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE INTERNAL_CreateHiggTags
AS
	v_app_sid						security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
	v_env_tag_group_id				tag_group.tag_group_id%TYPE;
	v_soc_tag_group_id				tag_group.tag_group_id%TYPE;
	v_resp_year_tag_group_id		tag_group.tag_group_id%TYPE;
	v_out_tag_id					csr.tag.tag_id%TYPE;
BEGIN
	--Internal - security check performed in SetupModules
	tag_pkg.SetTagGroup(
		in_name 				=> 'Higg environment',
		in_applies_to_audits 	=> 1,
		in_lookup_key 			=> 'HIGG_ENVIRONMENT',
		out_tag_group_id 		=> v_env_tag_group_id
	);

	tag_pkg.SetTag(
		in_act_id => security.security_pkg.getAct,
		in_tag_group_id => v_env_tag_group_id,
		in_tag => 'On-Site',
		in_pos => 1,
		in_lookup_key => 'On-Site',
		out_tag_id => v_out_tag_id
	);
	tag_pkg.SetTag(
		in_act_id => security.security_pkg.getAct,
		in_tag_group_id => v_env_tag_group_id,
		in_tag => 'Off-Site',
		in_pos => 2,
		in_lookup_key => 'Off-Site',
		out_tag_id => v_out_tag_id
	);
	tag_pkg.SetTag(
		in_act_id => security.security_pkg.getAct,
		in_tag_group_id => v_env_tag_group_id,
		in_tag => 'Self-Assessment',
		in_pos => 3,
		in_lookup_key => 'Self-Assessment',
		out_tag_id => v_out_tag_id
	);

	tag_pkg.SetTagGroup(
		in_name 				=> 'Higg social',
		in_applies_to_audits 	=> 1,
		in_lookup_key 			=> 'HIGG_SOCIAL',
		out_tag_group_id		=> v_soc_tag_group_id
	);

	tag_pkg.SetTag(
		in_act_id => security.security_pkg.getAct,
		in_tag_group_id => v_soc_tag_group_id,
		in_tag => 'On-Site',
		in_pos => 1,
		in_lookup_key => 'On-Site',
		out_tag_id => v_out_tag_id
	);
	tag_pkg.SetTag(
		in_act_id => security.security_pkg.getAct,
		in_tag_group_id => v_soc_tag_group_id,
		in_tag => 'Off-Site',
		in_pos => 2,
		in_lookup_key => 'Off-Site',
		out_tag_id => v_out_tag_id
	);
	tag_pkg.SetTag(
		in_act_id => security.security_pkg.getAct,
		in_tag_group_id => v_soc_tag_group_id,
		in_tag => 'Self-Assessment',
		in_pos => 3,
		in_lookup_key => 'Self-Assessment',
		out_tag_id => v_out_tag_id
	);

	tag_pkg.SetTagGroup(
		in_name 				=> 'Response year',
		in_applies_to_audits 	=> 1,
		in_lookup_key 			=> chain.higg_pkg.HIGG_RESPONSE_YR_LOOKUP_KEY,
		out_tag_group_id		=> v_resp_year_tag_group_id
	);

	INTERNAL_SetHiggModuleTagGroup(v_app_sid, 5, v_soc_tag_group_id);
	INTERNAL_SetHiggModuleTagGroup(v_app_sid, 6, v_env_tag_group_id);
	INTERNAL_SetHiggModuleTagGroup(v_app_sid, 5, v_resp_year_tag_group_id);
	INTERNAL_SetHiggModuleTagGroup(v_app_sid, 6, v_resp_year_tag_group_id);
END;

PROCEDURE EnableHigg (
	in_ftp_profile					VARCHAR2,
	in_ftp_folder					VARCHAR2
)
AS
	v_ftp_profile_id				csr.ftp_profile.ftp_profile_id%TYPE;
	v_count							NUMBER(10);
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_cmsdataimports_container_sid 	security.security_pkg.T_SID_ID;
	v_cmsdataimports_so_class		security.security_pkg.T_CLASS_ID;
	v_cms_data_imp_sid				security.security_pkg.T_SID_ID;
	v_exportimport_container_sid	security.security_pkg.T_SID_ID;
	v_fileread_ftp_id				NUMBER(10);
	v_tab_sid						NUMBER(10);
	v_auto_imp_cms_id				NUMBER(10);
	v_payload_path					VARCHAR2(2000);
	v_mappings						XMLTYPE;
	v_job_lookup_key				VARCHAR2(255) := 'HIGG';
	v_job_label						VARCHAR2(255) := 'Higg import';
	v_auto_imp_class_sid			security.security_pkg.T_SID_ID;
	v_cms_table_count				NUMBER(10);
	v_score_types_cur				security.security_pkg.T_OUTPUT_CUR;
	v_score_type_lookup_key 		VARCHAR2(255);
	v_score_type_format_mask 		VARCHAR2(20);
	v_parent						security.security_pkg.T_SID_ID;
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run SetupModules');
	END IF;

	EnableAutomatedExportImport;

	SELECT COUNT(*)
	  INTO v_cms_table_count
	  FROM cms.tab
	 WHERE oracle_schema = 'CHAIN'
	   AND oracle_table LIKE 'HIGG%';

	IF v_cms_table_count = 0 THEN
		-- Register CMS tables
		cms.tab_pkg.registertable(UPPER('CHAIN'), 'HIGG_MODULE,HIGG_MODULE_SECTION,HIGG_MODULE_SUB_SECTION,HIGG_QUESTION,HIGG_QUESTION_OPTION,HIGG_RESPONSE,HIGG_SECTION_SCORE,HIGG_SUB_SECTION_SCORE,HIGG_QUESTION_RESPONSE,HIGG_PROFILE', FALSE, FALSE);
	END IF;

	INTERNAL_CreateHiggTags;

	-- create higg score types
	BEGIN
		SELECT score_type_lookup_key, score_type_format_mask
		  INTO v_score_type_lookup_key, v_score_type_format_mask
		  FROM chain.higg_module
		 WHERE higg_module_id = chain.higg_setup_pkg.SOCIAL_MODULE;

		csr.quick_survey_pkg.SaveScoreType(
			in_score_type_id 		=> NULL,
			in_label 				=> 'Higg Social score',
			in_pos 					=> 0,
			in_hidden 				=> 0,
			in_allow_manual_set 	=> 0,
			in_lookup_key 			=> v_score_type_lookup_key,
			in_applies_to_supplier 	=> 1,
			in_reportable_months	=> 12,
			in_format_mask 			=> NVL(v_score_type_format_mask, '#,##0.0%'),
			in_applies_to_audits	=> 1,
			out_cur 				=> v_score_types_cur
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		SELECT score_type_lookup_key, score_type_format_mask
		  INTO v_score_type_lookup_key, v_score_type_format_mask
		  FROM chain.higg_module
		 WHERE higg_module_id = chain.higg_setup_pkg.ENV_MODULE;

		csr.quick_survey_pkg.SaveScoreType(
			in_score_type_id 		=> NULL,
			in_label 				=> 'Higg Environmental score',
			in_pos 					=> 0,
			in_hidden 				=> 0,
			in_allow_manual_set 	=> 0,
			in_lookup_key 			=> v_score_type_lookup_key,
			in_applies_to_supplier 	=> 1,
			in_reportable_months	=> 12,
			in_format_mask 			=> NVL(v_score_type_format_mask, '#,##0.0%'),
			in_max_score 			=> 100,
			in_applies_to_audits	=> 1,
			out_cur 				=> v_score_types_cur
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.higg
	 WHERE app_sid = security.security_pkg.GetApp;

	IF v_count > 0 THEN
		RETURN;
	END IF;

	BEGIN
		SELECT ftp_profile_id
		  INTO v_ftp_profile_id
		  FROM csr.ftp_profile
		 WHERE UPPER(label) = UPPER(in_ftp_profile);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'The FTP profile ' || in_ftp_profile || ' was not found. This must be created by a database administrator first.');
	END;

	INSERT INTO chain.higg (ftp_folder, ftp_profile_label)
	VALUES (in_ftp_folder, in_ftp_profile);

	BEGIN
		SELECT automated_import_class_sid
		  INTO v_auto_imp_class_sid
		  FROM csr.automated_import_class
		 WHERE lookup_key = 'HIGG';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	IF v_auto_imp_class_sid IS NOT NULL THEN
		-- already created
		RETURN;
	END IF;

	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExportImport');
	v_cmsdataimports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_exportimport_container_sid, 'AutomatedImports');

	v_cmsdataimports_so_class := security.class_pkg.GetClassId('CSRAUTOMATEDIMPORT');

	-- Response
	v_fileread_ftp_id := NULL;
	v_auto_imp_cms_id := NULL;

	v_parent := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
	csr.automated_import_pkg.CreateClass(
		in_parent				=> v_parent,
		in_label				=> v_job_label,
		in_lookup_key			=> v_job_lookup_key,
		in_schedule_xml			=> NULL, /* TODO: set schedule */
		in_abort_on_error		=> 0,
		in_email_on_error		=> NULL,
		in_email_on_partial		=> NULL,
		in_email_on_success		=> NULL,
		in_on_completion_sp		=> NULL,
		in_import_plugin		=> 'Credit360.ExportImport.Automated.Import.Plugins.HiggImportPlugin',
		out_class_sid			=> v_cms_data_imp_sid
	);

	v_payload_path := '/' || in_ftp_folder || '/';
	v_payload_path := REPLACE(v_payload_path, '//', '/');
	v_tab_sid := cms.tab_pkg.GetTableSid('CHAIN', 'HIGG_PROFILE');
	v_mappings := XMLTYPE('<table name="HIGG_PROFILE" xpath="//Records/Record/SurveyStructure/ModuleGeneralInformation">
   <column xpath="ProfileId" to="HIGG_PROFILE_ID"/>
   <column xpath="ResponseYear" to="RESPONSE_YEAR"/>
   <child-table name="HIGG_RESPONSE" xpath=".">
	  <column xpath="ResponseId" to="HIGG_RESPONSE_ID"/>
	  <column xpath="SurveyId" to="HIGG_MODULE_ID"/>
	  <column xpath="AccountId" to="HIGG_ACCOUNT_ID"/>
	  <column xpath="ModuleName" to="MODULE_NAME"/>
	  <column xpath="Posted" to="POSTED"/>
	  <column xpath="VerificationStatus" to="VERIFICATION_STATUS"/>
	  <column xpath="VerificationDocumentURL" to="VERIFICATION_DOCUMENT_URL"/>
	  <column xpath="IsBenchmarked" to="IS_BENCHMARKED"/>
	  <column xpath="ResponseScore" to="RESPONSE_SCORE"/>
	  <column xpath="LastUpdated" to="LAST_UPDATED_DTM"/>
	  <child-table name="HIGG_SECTION_SCORE" xpath="../ModuleResponseContent/Sections/Section">
		 <column xpath="SectionId" to="HIGG_SECTION_ID"/>
		 <column xpath="ActualScore" to="SCORE"/>
		 <child-table name="HIGG_SUB_SECTION_SCORE" xpath="SubSections/SubSection">
			<column xpath="../../../../../ModuleGeneralInformation/ResponseId" to="HIGG_RESPONSE_ID"/>
			<column xpath="SubSectionId" to="HIGG_SUB_SECTION_ID"/>
			<column xpath="ActualScore" to="SCORE"/>
		 </child-table>
	  </child-table>
	  <child-table name="HIGG_QUESTION_RESPONSE" xpath="../ModuleResponseContent//Questions/Question">
		 <column xpath="QuestionId" to="HIGG_QUESTION_ID"/>
		 <column xpath="ActualScore" to="SCORE"/>
		 <column xpath="Answer" to="ANSWER"/>
		 <column xpath="OptionId" to="OPTION_ID"/>
	  </child-table>
   </child-table>
</table>
	');

	csr.automated_import_pkg.AddClassStep (
		in_import_class_sid				=> v_cms_data_imp_sid,
		in_step_number					=> 1,
		in_on_completion_sp				=> NULL,
		in_days_to_retain_payload		=> 30,
		in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.HiggImportStepPlugin',
		in_importer_plugin_id			=> 3,
		in_fileread_plugin_id			=> 4
	);

	v_fileread_ftp_id := csr.automated_import_pkg.MakeFTPReaderSettings(
		in_ftp_profile_id				=> v_ftp_profile_id,
		in_payload_path					=> v_payload_path,
		in_file_mask					=> '*',
		in_sort_by						=> 'DATE',
		in_sort_by_direction			=> 'ASC',
		in_move_to_path_on_success		=> NULL,
		in_move_to_path_on_error		=> NULL,
		in_delete_on_success			=> 1,
		in_delete_on_error				=> 1
	);

	v_auto_imp_cms_id := csr.automated_import_pkg.MakeCmsImporterSettings(
		in_tab_sid						=> v_tab_sid,
		in_mapping_xml					=> v_mappings,
		in_cms_imp_file_type_id			=> 2,
		in_dsv_separator				=> NULL,
		in_dsv_quotes_as_literals		=> NULL,
		in_excel_worksheet_index		=> NULL,
		in_all_or_nothing				=> 0
	);

	csr.automated_import_pkg.SetStepFtpAndCmsSettings (
		in_import_class_sid				=> v_cms_data_imp_sid,
		in_step_number					=> 1,
		in_cms_settings_id				=> v_auto_imp_cms_id,
		in_ftp_settings_id				=> v_fileread_ftp_id
	);
END;

PROCEDURE EnableImageChart
-- test data
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_imagechart			security.security_pkg.T_SID_ID;
	-- web resources
	v_www_root 					security.security_pkg.T_SID_ID;
	v_www_csr_site 				security.security_pkg.T_SID_ID;
	v_www_imagechart 			security.security_pkg.T_SID_ID;
	--
	v_portlet_id				NUMBER(10);
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	--
	--
	/*** ADD MENU ITEM ***/
	-- will inherit permissions from analysis menu parent

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/analysis'),
			'csr_imagechart', 'Image charts', '/csr/site/imagechart/list.acds', 8, null, v_menu_imagechart);

		security.securableobject_pkg.ClearFlag(v_act_id, v_menu_imagechart, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_imagechart));
		-- add administrators
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_imagechart), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	--
	/*** WEB RESOURCE ***/
	BEGIN
		v_www_imagechart := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/imagechart');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'imagechart', v_www_imagechart);
	END;

	security.securableobject_pkg.ClearFlag(v_act_id, v_www_imagechart, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_imagechart));
	-- add administrators
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_imagechart), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	/*** ENABLE PORTLET ***/
	SELECT portlet_id
	  INTO v_portlet_id
	  FROM PORTLET
	 WHERE type = 'Credit360.Portlets.ImageChart';

	portlet_pkg.EnablePortletForCustomer(v_portlet_id);
END;

PROCEDURE InitiativeBaseData
AS
	v_energy_project_sid		security.security_pkg.T_SID_ID;
	v_waste_project_sid			security.security_pkg.T_SID_ID;
	v_transport_project_sid		security.security_pkg.T_SID_ID;
	v_water_project_sid			security.security_pkg.T_SID_ID;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_live_flow_state_id		security.security_pkg.T_SID_ID;
	v_fields_xml				VARCHAR2(4000);
	v_measure_sid				security.security_pkg.T_SID_ID;

	TYPE T_VARCHAR IS TABLE OF VARCHAR2(255);
	TYPE T_MEASURE_MAP IS TABLE OF NUMBER INDEX BY VARCHAR2(255);
	v_list 						T_VARCHAR;
	v_measure_map 				T_MEASURE_MAP;

	v_number					NUMBER;
BEGIN

	-- Safety check (don't allow the base data to be installed if config already exists)
	-- Checking the project and metric tables will probably suffice
	v_number := 0;

	SELECT v_number + COUNT(*)
	  INTO v_number
	  FROM initiative_project
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT v_number + COUNT(*)
	  INTO v_number
	  FROM initiative_metric
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_number > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'An initiatives configuration already exists for this site.');
	END IF;

	SELECT f.flow_sid, s.flow_state_id
	  INTO v_flow_sid, v_live_flow_state_id
	  FROM flow f, flow_state s
	 WHERE LOWER(f.label) = LOWER('Initiatives')
	   AND LOWER(s.label) = LOWER('Proposed')
	   AND f.flow_sid = s.flow_sid;

	v_fields_xml :=
		'<fields>
			<field id="description" name="Project description" description="Project description" mandatory="n"/>
			<field id="commentary" name="Commentary" description="Comments" mandatory="n"/>
			<field id="owner" name="Project owner" description="Project owner" mandatory="n"/>
		</fields>'
	;

	-- ensure a bunch of measures exist
	v_list := T_VARCHAR(
		'GJ',
		'tonne CO2 eq.',
		'tonne',
		'm3',
		'GBP'
	);
	FOR i IN 1 .. v_list.count
	LOOP
		SELECT MIN(measure_sid)
		  INTO v_measure_sid
		  FROM measure
		 WHERE description = v_list(i);

		IF v_measure_sid IS NULL THEN
			BEGIN
				measure_pkg.CreateMeasure(
					in_name => v_list(i),
					in_description  => v_list(i),
					out_measure_sid => v_measure_sid
				);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_measure_sid := security.securableobject_pkg.getSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'Measures/'||v_list(i));
			END;
		END IF;
		v_measure_map(v_list(i)) := v_measure_sid;
	END LOOP;

	-- PROJECTS
	initiative_project_pkg.CreateProject(
		in_name 				=> 'Energy',
		in_flow_sid 			=> v_flow_sid,
		in_live_flow_state_id 	=> v_live_flow_state_id,
		in_fields_xml 			=> XMLType(v_fields_xml),
		in_icon 				=> 'energy_bulb',
		in_abbreviation 		=> 'E',
		in_pos_group 			=> '1',
		in_pos					=> '1',
		out_project_sid 		=> v_energy_project_sid
	);
	initiative_project_pkg.CreateProject(
		in_name 				=> 'Water',
		in_flow_sid 			=> v_flow_sid,
		in_live_flow_state_id 	=> v_live_flow_state_id,
		in_fields_xml 			=> XMLType(v_fields_xml),
		in_icon 				=> 'water_drop',
		in_abbreviation 		=> 'W',
		in_pos_group 			=> '1',
		in_pos					=> '2',
		out_project_sid 		=> v_water_project_sid
	);
	initiative_project_pkg.CreateProject(
		in_name 				=> 'Waste',
		in_flow_sid 			=> v_flow_sid,
		in_live_flow_state_id 	=> v_live_flow_state_id,
		in_fields_xml 			=> XMLType(v_fields_xml),
		in_icon 				=> 'waste_bin',
		in_abbreviation 		=> 'W1',
		in_pos_group 			=> '1',
		in_pos					=> '3',
		out_project_sid 		=> v_waste_project_sid
	);
	initiative_project_pkg.CreateProject(
		in_name 				=> 'Transport',
		in_flow_sid 			=> v_flow_sid,
		in_live_flow_state_id 	=> v_live_flow_state_id,
		in_fields_xml 			=> XMLType(v_fields_xml),
		in_icon 				=> 'travel_plane',
		in_abbreviation 		=> 'T',
		in_pos_group 			=> '1',
		in_pos					=> '4',
		out_project_sid 		=> v_transport_project_sid
	);

	INSERT INTO initiative_metric (initiative_metric_id, measure_sid, divisibility, is_saving, per_period_duration, one_off_period, is_during, is_running, is_rampable, label,lookup_key, is_external)
		VALUES (initiative_metric_id_seq.NEXTVAL, v_measure_map('GJ'), csr_data_pkg.DIVISIBILITY_DIVISIBLE, 1, null, null, 1, 1, 0, 'Energy savings','ENERGY',0);
	INSERT INTO initiative_metric (initiative_metric_id, measure_sid, divisibility, is_saving, per_period_duration, one_off_period, is_during, is_running, is_rampable, label,lookup_key, is_external)
		VALUES (initiative_metric_id_seq.NEXTVAL, v_measure_map('tonne CO2 eq.'), csr_data_pkg.DIVISIBILITY_DIVISIBLE, 1, null, null, 1, 1, 0, 'GHG savings','GHG',0);
	INSERT INTO initiative_metric (initiative_metric_id, measure_sid, divisibility, is_saving, per_period_duration, one_off_period, is_during, is_running, is_rampable, label,lookup_key, is_external)
		VALUES (initiative_metric_id_seq.NEXTVAL, v_measure_map('tonne'), csr_data_pkg.DIVISIBILITY_DIVISIBLE, 1, null, null, 1, 1, 0, 'Waste savings','WASTE',0);
	INSERT INTO initiative_metric (initiative_metric_id, measure_sid, divisibility, is_saving, per_period_duration, one_off_period, is_during, is_running, is_rampable, label,lookup_key, is_external)
		VALUES (initiative_metric_id_seq.NEXTVAL, v_measure_map('m3'), csr_data_pkg.DIVISIBILITY_DIVISIBLE, 1, null, null, 1, 1, 0, 'Water savings','WATER',0);
	INSERT INTO initiative_metric (initiative_metric_id, measure_sid, divisibility, is_saving, per_period_duration, one_off_period, is_during, is_running, is_rampable, label,lookup_key, is_external)
		VALUES (initiative_metric_id_seq.NEXTVAL, v_measure_map('GBP'), csr_data_pkg.DIVISIBILITY_DIVISIBLE, 1, null, null, 1, 1, 0, 'Cost savings','COST_SAVE',0);

	INSERT INTO initiative_metric_group (project_sid, pos_group, is_group_mandatory, label)
		 SELECT p.project_sid, 1, 1, 'Environmental Savings'
		   FROM initiative_project p;

	INSERT INTO initiative_metric_group (project_sid, pos_group, is_group_mandatory, label)
		 SELECT p.project_sid, 2, 0, 'Financial Savings'
		   FROM initiative_project p;

	-- energy
	INSERT INTO project_initiative_metric (project_sid, initiative_metric_id, pos, pos_group, update_per_period, default_value, input_dp, flow_sid, info_text)
		SELECT p.project_sid, m.initiative_metric_id, rownum, 1, 0, NULL, 0, v_flow_sid, null
		  FROM initiative_project p
		 CROSS JOIN initiative_metric m
		 WHERE m.lookup_key IN ('ENERGY')
		   AND p.project_sid = v_energy_project_sid;
	-- water
	INSERT INTO project_initiative_metric (project_sid, initiative_metric_id, pos, pos_group, update_per_period, default_value, input_dp, flow_sid, info_text)
		SELECT p.project_sid, m.initiative_metric_id, rownum, 1, 0, NULL, 0, v_flow_sid, null
		  FROM initiative_project p
		 CROSS JOIN initiative_metric m
		 WHERE m.lookup_key IN ('WATER')
		   AND p.project_sid = v_water_project_sid;
	-- waste
	INSERT INTO project_initiative_metric (project_sid, initiative_metric_id, pos, pos_group, update_per_period, default_value, input_dp, flow_sid, info_text)
		SELECT p.project_sid, m.initiative_metric_id, rownum, 1, 0, NULL, 0, v_flow_sid, null
		  FROM initiative_project p
		 CROSS JOIN initiative_metric m
		 WHERE m.lookup_key IN ('WASTE')
		   AND p.project_sid = v_waste_project_sid;
	-- transport
	INSERT INTO project_initiative_metric (project_sid, initiative_metric_id, pos, pos_group, update_per_period, default_value, input_dp, flow_sid, info_text)
		SELECT p.project_sid, m.initiative_metric_id, rownum, 1, 0, NULL, 0, v_flow_sid, null
		  FROM initiative_project p
		 CROSS JOIN initiative_metric m
		 WHERE m.lookup_key IN ('GHG')
		   AND p.project_sid = v_transport_project_sid;

	-- apply to all init projects
	INSERT INTO project_initiative_metric (project_sid, initiative_metric_id, pos, pos_group, update_per_period, default_value, input_dp, flow_sid, info_text)
		SELECT p.project_sid, m.initiative_metric_id, rownum, 2, 0, NULL, 0, v_flow_sid, null
		  FROM initiative_project p
		  CROSS JOIN initiative_metric m
		 WHERE m.lookup_key IN ('COST_SAVE');

	-- make all metrics visible
	INSERT INTO project_init_metric_flow_state (initiative_metric_id, flow_state_id, mandatory, visible, project_sid, flow_sid)
		SELECT pim.initiative_metric_id, fs.flow_state_id, 0, 1, pim.project_sid, pim.flow_sid
		 FROM project_initiative_metric pim
		 JOIN flow_State fs on pim.flow_sid = fs.flow_Sid AND pim.app_sid = fs.app_sid;

	INSERT INTO initiative_project_user_group (project_sid, initiative_user_group_id)
		SELECT project_sid, 1
		  FROM initiative_project
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	initiative_metric_pkg.SyncFilterAggregateTypes;
END;

PROCEDURE EnableInitiatives (
	in_setup_base_data			IN VARCHAR2,
	in_metrics_end_year			IN NUMBER
)
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_auditors_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_user_role_sid				security.security_pkg.T_SID_ID;
	v_approver_role_sid			security.security_pkg.T_SID_ID;
	v_admin_role_sid			security.security_pkg.T_SID_ID;
	v_initiatives_sid			security.security_pkg.T_SID_ID;
	-- menu
	v_menu_sid					security.security_pkg.T_SID_ID;
	v_menu_initiatives_sid		security.security_pkg.T_SID_ID;
	v_myinitiatives				security.security_pkg.T_SID_ID;
	v_create					security.security_pkg.T_SID_ID;
	v_timeline					security.security_pkg.T_SID_ID;
	v_import					security.security_pkg.T_SID_ID;
	v_setup_menu_sid			security.security_pkg.T_SID_ID;
	v_init_admin				security.security_pkg.T_SID_ID;
	-- web
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_initiatives_sid		security.security_pkg.T_SID_ID;
	-- workflow
	v_workflow_sid				security.security_pkg.T_SID_ID;
	v_wf_ct_sid					security.security_pkg.T_SID_ID;
	v_complete_xml				CLOB;
	v_r0						security.security_pkg.T_SID_ID;
	v_r1						security.security_pkg.T_SID_ID;
	v_s0						security.security_pkg.T_SID_ID;
	v_s1						security.security_pkg.T_SID_ID;
	v_s2						security.security_pkg.T_SID_ID;
	v_xml_p1					CLOB;
	v_str						VARCHAR2(2000);
	v_element_id				NUMBER;
BEGIN
	v_act_id := security.security_pkg.getAct;
	v_app_sid := security.security_pkg.getApp;

	-- TOOD: New initiatives portlets?
	-- ...
	csr_Data_pkg.enablecapability('Can import initiatives');
	csr_Data_pkg.enablecapability('Can purge initiatives');
	csr_Data_pkg.enablecapability('View initiatives audit log');
	csr_Data_pkg.enablecapability('Create users for approval');
	BEGIN
		INSERT INTO customer_init_saving_type (app_sid, saving_type_id)
			SELECT v_app_sid, saving_type_id
			  FROM initiative_saving_type
			 WHERE lookup_key IN ('temporary', 'ongoing');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Already configured
	END;

	initiative_pkg.SetOptions(
		in_auto_complete_date => 0,
		in_my_initiatives_options => '{
			  completeDlgShowDates: true,
			  completeDlgShowMetrics: false,
			  showStatus: true,
			  showAddComment: true,
			  showStateChange: true,
			  showProgressUpdate: true,
			  enableMetricDetails: false,
			  createPage:"/csr/site/initiatives/create.acds"
			}',
		in_metrics_end_year => NVL(in_metrics_end_year, 2030)
	);

	-- read groups
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_auditors_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- Add roles
	BEGIN
		role_pkg.SetRole(v_act_id, v_app_sid, 'Initiative user', v_user_role_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_user_role_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Initiative user');
	END;

	BEGIN
		role_pkg.SetRole(v_act_id, v_app_sid, 'Initiative approver', v_approver_role_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_approver_role_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Initiative approver');
	END;

	BEGIN
		role_pkg.SetRole(v_act_id, v_app_sid, 'Initiative administrator', v_admin_role_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_admin_role_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Initiative administrator');
	END;

	--Create "initiatives" container
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Initiatives', v_initiatives_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_initiatives_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Initiatives');
	END;

	-- Give admins all standard perms on the initiatives object
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_initiatives_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Give initiative admins role all standard perms on the initiatives object
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_initiatives_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Give initiative approvers role all standard perms on the initiatives object
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_initiatives_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_approver_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Give initiative user role read perms on initiatives object
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_initiatives_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_user_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Propogate perms
	security.acl_pkg.PropogateACEs(v_act_id, v_initiatives_sid);

	-- Add initiatives menus
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu');
	v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/setup');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'initiatives', 'Initiatives', '/csr/site/Initiatives/List.acds', 4, null, v_menu_initiatives_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_initiatives_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/initiatives');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_initiatives_sid, 'initiatives_myinitiatives', 'My initiatives', '/csr/site/initiatives/List.acds', 1, null, v_myinitiatives);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_myinitiatives := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/initiatives/initiatives_myinitiatives');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_initiatives_sid, 'initiatives_create', 'New initiative', '/csr/site/initiatives/create.acds', 2, null, v_create);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_create := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/initiatives/initiatives_create');
	END;
	/*
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_initiatives_sid, 'initiatives_timeline', 'Timeline', '/csr/site/initiatives/timeline.acds', 3, null, v_timeline);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_timeline := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/initiatives/initiatives_timeline');
	END;
	*/
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_initiatives_sid, 'initiatives_import', 'Import initiatives', '/csr/site/initiatives/import/initiativesImport.acds', 7, null, v_import);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_import := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/initiatives/initiatives_import');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_setup_menu_sid, 'csr_site_initiatives_admin_menu', 'Initiatives admin', '/csr/site/initiatives/admin/menu.acds', 7, null, v_init_admin);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_init_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/setup/csr_site_initiatives_admin_menu');
	END;

	-- Add menu perms
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_approver_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_user_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_init_admin), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act_id, v_menu_initiatives_sid);

	-- Web resource
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www_root, security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site'), 'Initiatives', v_www_initiatives_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_initiatives_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, '/csr/site/Initiatives');
	END;

	-- Web resource perms
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_approver_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_user_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		INSERT INTO issue_type (issue_type_id, label, allow_children, create_raw)
			VALUES (csr_data_pkg.ISSUE_INITIATIVE, 'Initiative Action', 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO customer_region_type (region_type)
			VALUES (csr_data_pkg.REGION_TYPE_AGGR_REGION);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO initiative_user_group (initiative_user_group_id, label)
			VALUES (1, 'Associated users');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class) values ('initiatives');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	chain.card_pkg.SetGroupCards('Initiative Filter', chain.T_STRING_LIST('Credit360.Initiatives.Filters.InitiativeFilter'));

	-- workflow
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Initiatives');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please run csr\db\utils\enableworkflow.sql first');
			END;

			-- create our workflow
			flow_pkg.CreateFlow(
				in_label			=> 'Initiatives',
				in_parent_sid		=> v_wf_ct_sid,
				in_flow_alert_class	=> 'initiatives',
				out_flow_sid		=> v_workflow_sid
			);
	END;

	-- Roles
	role_pkg.SetRole('Initiative user', v_r0);
	role_pkg.SetRole('Initiative approver', v_r1);

	-- Get/Create States and store vals here so we don't end up
	-- using different IDs if the place-holders are in different
	-- workflow XML chunks.
	v_s0 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'PROPOSED'), flow_pkg.GetNextStateID);
	v_s1 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'VALIDATED'), flow_pkg.GetNextStateID);
	v_s2 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'CANCELLED'), flow_pkg.GetNextStateID);

	v_xml_p1 := '<';
	v_str := UNISTR('flow label="Initiatives" cmsTabSid="" default-state-id="$S0$" flow-alert-class="initiatives"><state id="$S0$" label="Proposed" pos="1" final="0" colour="2388223" lookup-key="PROPOSED"><attributes x="477.5" y="800" /><role sid="$R0$" is-editable="0" /><role sid="$R1$" is-editable="1" /><transition flow-state-transition-id="38366" to-state-id="$S1$" verb="Validate project" helper-sp="" lookup-key="VALIDATE" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif"><role sid="$R1$" /></transition><transition flow-state-transition-id="38367" to-state-id="$S2$" verb="Cancel project" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_cross.gif"><role sid="$R1$" /></transition>');
	dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
	v_str := UNISTR('</state><state id="$S1$" label="Validated" pos="2" final="0" colour="3777539" lookup-key="VALIDATED"><attributes x="1092" y="799" /><role sid="$R0$" is-editable="0" /><role sid="$R1$" is-editable="1" /><transition flow-state-transition-id="38368" to-state-id="$S2$" verb="Cancel project" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_cross.gif"><role sid="$R1$" /></transition><transition flow-state-transition-id="38507" to-state-id="$S0$" verb="Return to Proposed" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R1$" /></transition></state><state id="$S2$" label="Cancelled" pos="3" final="0" colour="10329243" lookup-key="CANCELLED"><attributes x="777" y="932" /><role sid="$R0$" is-editable="0" /><role sid="$R1$" is-editable="1" /><');
	dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
	v_str := UNISTR('transition flow-state-transition-id="38369" to-state-id="$S0$" verb="Reopen as Proposed" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_return2.png"><role sid="$R1$" /></transition><transition flow-state-transition-id="38509" to-state-id="$S1$" verb="Reopen as Validated" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R1$" /></transition></state></flow>');
	dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);

	-- Roles
	v_xml_p1 := REPLACE(v_xml_p1, '$R0$', v_r0);
	v_xml_p1 := REPLACE(v_xml_p1, '$R1$', v_r1);

	-- States
	v_xml_p1 := REPLACE(v_xml_p1, '$S0$', v_s0);
	v_xml_p1 := REPLACE(v_xml_p1, '$S1$', v_s1);
	v_xml_p1 := REPLACE(v_xml_p1, '$S2$', v_s2);

	dbms_lob.createtemporary(v_complete_xml, true);

	v_complete_xml := v_xml_p1;

	flow_pkg.SetFlowFromXml(v_workflow_sid, XMLType(v_complete_xml));
	dbms_lob.freetemporary (v_complete_xml);

	initiative_pkg.SaveHeaderElement(
		in_pos							=> 0,
		in_col							=> 0,
		in_init_header_core_element_id	=> 9, -- timeline
		out_init_header_element_id		=> v_element_id
	);
	initiative_pkg.SaveHeaderElement(
		in_pos							=> 1,
		in_col							=> 1,
		in_init_header_core_element_id	=> 3, -- project
		out_init_header_element_id		=> v_element_id
	);
	initiative_pkg.SaveHeaderElement(
		in_pos							=> 1,
		in_col							=> 2,
		in_init_header_core_element_id	=> 11, -- flow status
		out_init_header_element_id		=> v_element_id
	);

	IF NVL(UPPER(in_setup_base_data), 'N') = 'Y' THEN
		InitiativeBaseData;
	END IF;

	BEGIN
		INSERT INTO project_doc_folder (app_sid, project_sid, NAME, label)
			SELECT app_sid, project_sid, 'supporting_docs', 'Supporting Documents'
			  FROM initiative_project
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnableInitiativesAuditTab
AS
	v_app_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_act_id			SECURITY.SECURITY_PKG.T_ACT_ID;
	v_plugin_id			plugin.plugin_id%TYPE;
BEGIN
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;

	BEGIN
		INSERT INTO plugin
			(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES
			(plugin_id_seq.nextval, 8, 'Audit Log', '/csr/site/initiatives/detail/controls/AuditLogPanel.js', 'Credit360.Initiatives.AuditLogPanel', 'Credit360.Plugins.PluginDto', 'Audit Log');
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Initiatives.AuditLogPanel');
	FOR r IN (SELECT project_sid FROM initiative_project)
	LOOP
		BEGIN
			INSERT INTO initiative_project_tab (project_sid, plugin_id, plugin_type_id, pos, tab_label)
			VALUES (r.project_sid, v_plugin_id,
					csr_data_pkg.PLUGIN_TYPE_INITIAT_TAB,
					2, 'Audit Log');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE initiative_project_tab
				   SET pos=2
				 WHERE plugin_id = v_plugin_id;
		END;

		BEGIN
			INSERT INTO initiative_project_tab_group (project_sid, plugin_id, group_sid)
			VALUES (r.project_sid, v_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;

END;

PROCEDURE EnableIssues2
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
	v_www_csr_site_issue			security.security_pkg.T_SID_ID;
	v_www_csr_site_issue_admin		security.security_pkg.T_SID_ID;
	-- menus
	v_menu_admin					security.security_pkg.T_SID_ID;
	v_menu_issue					security.security_pkg.T_SID_ID;
	v_menu1							security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := security.security_pkg.getAct;
	v_app_sid := security.security_pkg.getApp;

	UPDATE customer
	   SET issue_editor_url = '/csr/site/issues2/public/editIssueDialog.jsi'
	 WHERE app_sid = security.security_pkg.getApp;

	-- ensure issue tracking turned on
	FOR r IN (
		SELECT security.security_pkg.getapp, portlet_id
		  FROM portlet
		 WHERE type IN (
			'Credit360.Portlets.Issue2'
		 ) AND portlet_Id NOT IN (SELECT portlet_id FROM customer_portlet))
	LOOP
		portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;

	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- create menu - just show to admins ATM
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/data'),
			'csr_issue', 'Actions', '/csr/site/issues/issueList.acds', 6, null, v_menu_issue);
		security.securableobject_pkg.ClearFlag(v_act_id, v_menu_issue, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_issue));
		-- add administrators
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_issue), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	/*** WEB RESOURCE ***/
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_issue := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'issues2');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_issue), v_reg_users_sid);
		-- add reg users to issues web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_issue), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'issues2', v_www_csr_site_issue);
			-- add reg users to issues web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_issue), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	BEGIN
		v_www_csr_site_issue_admin := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_issue, 'admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_issue, 'admin', v_www_csr_site_issue_admin);
			security.securableobject_pkg.ClearFlag(v_act_id, v_www_csr_site_issue_admin,security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_issue_admin), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_issue_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
			'csr_issue_reports',
			'Issue reports',
			'/csr/site/issues2/reports/reports.acds',
			10, null, v_menu1);

		 security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	sqlreport_pkg.EnableReport('csr.issue_pkg.GetReportInactiveUsers');
	sqlreport_pkg.EnableReport('csr.issue_pkg.GetReportInactiveUsersSummary');
	sqlreport_pkg.EnableReport('csr.issue_pkg.GetReportAuditIssues');
END;

PROCEDURE EnableLandingPages
AS
	v_act_id				security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	-- menu
	v_menu_setup			security.security_pkg.T_SID_ID;
	v_menu_landingpagelist	security.security_pkg.T_SID_ID;
BEGIN
	v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup');

	/*** ADD MENU ITEM ***/
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup'),
			'csr_users_landing_page', 'Landing Pages', '/csr/site/users/landingPage/landingPageList.acds', 8, null, v_menu_landingpagelist);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_landingpagelist := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_setup, 'csr_users_landing_page');
	END;

	LogEnable('Landing Pages');
END;

PROCEDURE DisableLandingPages
AS
	v_act_id				security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	/*** DELETE MENU ITEM ***/
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id,
			security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/setup/csr_users_landing_page')
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	LogDisable('Landing Pages');
END;

PROCEDURE EnableMeasureConversions
AS
	v_act_id			security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	-- groups
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_admins_sid		security.security_pkg.T_SID_ID;
	-- menu
	v_menu_admin		security.security_pkg.T_SID_ID;
	v_menu_measureconversions	security.security_pkg.T_SID_ID;
	-- www
	v_wwwroot_sid		security.security_pkg.T_SID_ID;
	v_www_sid           security.security_pkg.T_SID_ID;
	v_www_csr_site		security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');


	InsertIntoOWLClientModule('MEASURE_CONVERSIONS', null);

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');

	/*** ADD MENU ITEM ***/
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_measure_conversions', 'Measure conversions', '/csr/site/schema/measureConversions/measureConversions.acds', 8, null, v_menu_measureconversions);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_measureconversions := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_admin, 'csr_measure_conversions');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_measureconversions), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.PropogateACEs(v_act_id, v_menu_measureconversions);

	/*** ADD WEB RESOURCE ***/
	v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, sys_context('security','app'), 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site/schema');

	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'measureConversions', v_www_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'measureConversions');
	END;
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_sid), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_ALL);

END;

PROCEDURE EnablePropertyMeterListTab
AS
	v_plugin_id			plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin
			(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
		VALUES
			(plugin_id_seq.nextval, 1, 'Meter data quick chart',
				'/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterListTab', 'Credit360.Metering.Plugins.MeterList',
				'Quick Charts tab for meter data', '/csr/shared/plugins/screenshots/property_tab_meter_list.png');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Metering.MeterListTab');

	BEGIN
		INSERT INTO property_tab (plugin_id, plugin_type_id, pos, tab_label)
		VALUES (v_plugin_id, 1, 11, 'Meter reporting'); -- Name of the tab?
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO property_tab_group (plugin_id, group_sid)
		VALUES (v_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnablePortal
AS
	v_act_id			security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;
	v_tab_count			NUMBER;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	SELECT COUNT(*)
	  INTO v_tab_count
	  FROM csr.tab
	 WHERE app_sid = v_app_sid;

	IF v_tab_count = 0 THEN
		enable_pkg.EnablePortalPLSQL();
	END IF;
END;

PROCEDURE EnablePortalPLSQL
AS
	v_act_id					security.security_pkg.T_ACT_ID	DEFAULT security.security_pkg.GetACT;
	v_app_sid					security.security_pkg.T_SID_ID	DEFAULT security.security_pkg.GetApp;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_data_providers_sid		security.security_pkg.T_SID_ID;
	v_data_approvers_sid		security.security_pkg.T_SID_ID;
	-- menu
	v_menu_data					security.security_pkg.T_SID_ID;
	v_menu_portal				security.security_pkg.T_SID_ID;
	v_menu_portal_admin			security.security_pkg.T_SID_ID;
	v_menu_rss					security.security_pkg.T_SID_ID;
	-- web resources
	v_www						security.security_pkg.T_SID_ID;
	v_www_rss					security.security_pkg.T_SID_ID;
	v_www_site_rss				security.security_pkg.T_SID_ID;
	v_www_site_portal			security.security_pkg.T_SID_ID;
	v_www_site_portal_admin		security.security_pkg.T_SID_ID;
	--portlets
	v_portlets					security.security_pkg.T_SID_ID;
	-- tabs
	v_tab_id					tab.tab_id%TYPE;
	-- misc
	v_cur						security.security_pkg.T_OUTPUT_CUR;
	v_tab_ids					security.security_pkg.T_SID_IDS;
BEGIN
	-- read groups
	v_groups_sid 				:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid				:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- (MDW) Data Providers don't seem to exist in all installations (?), so make it optional
	GetSidOrNullFromPath(v_groups_sid, 'Data Providers', v_data_providers_sid);
	-- (ARJ) Data Approvers don't seem to exist in all installations (?), so make it optional
	GetSidOrNullFromPath(v_groups_sid, 'Data Approvers', v_data_approvers_sid);

	--
	-- update site default url
	UPDATE aspen2.application
	   SET default_url = '/csr/site/portal/Home.acds'
	 WHERE app_sid = v_app_sid;
	--
	v_menu_data := null;
	BEGIN
		-- add a menu item
		v_menu_data				:= security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/data');
		-- repoint top-level level
		security.menu_pkg.SetMenu(v_act_id, v_menu_data,
			'Data entry', '/csr/site/portal/Home.acds', 1, null);
		BEGIN
			v_menu_portal := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_data, 'csr_portal_home');
		EXCEPTION
			WHEN security.security_pkg.object_not_found THEN
				security.menu_pkg.CreateMenu(v_act_id, v_menu_data,
					'csr_portal_home', 'Home', '/csr/site/portal/Home.acds', 1, null, v_menu_portal);
				-- add registered users to menu option
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_portal), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
					v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				-- move old menu item as submenu item of portal, so we got it portal menu item selected when we're on sheet page
				security.securableobject_pkg.MoveSO(v_act_id, 	security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_data,'csr_my_delegations'), v_menu_portal);
		END;
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	/* TAB MATRIX MENU OPTION */
	BEGIN
		v_menu_portal_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin/csr_portal_admin_tabmatrix');
	EXCEPTION
		WHEN security.security_pkg.object_not_found THEN
			security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
				'csr_portal_admin_tabmatrix', 'Home page tabs', '/csr/site/portal/admin/tabMatrix.acds', 5, null, v_menu_portal_admin);
			-- add admins to menu option
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_portal_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	/* RSS EDIT MENU OPTION */
	BEGIN
		v_menu_rss := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin/csr_site_rss_rss_edit');
	EXCEPTION
		WHEN security.security_pkg.object_not_found THEN
			security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
				'csr_site_rss_rss_edit', 'RSS feeds', '/csr/site/rss/rssEdit.acds', 6, null, v_menu_rss);
			-- add admins to menu option
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_rss), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	--
	/*** WEB RESOURCE ***/
	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	-- RSS
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www, v_www, 'rss', v_www_rss);
		-- add admins to web resource (inheritable, ALL)
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_rss), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		-- add everyone to web resource (non inheritable, READ)
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_rss), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
			security.security_pkg.SID_BUILTIN_EVERYONE, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_rss := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'rss');
	END;

	-- add permissions on pre-created web-resources or create if missing
	BEGIN
		v_www_site_portal := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/portal');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www,
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site'),
				'portal', v_www_site_portal);
	END;
	-- now admin page
	BEGIN
		v_www_site_portal_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_www_site_portal, 'admin');
	EXCEPTION
		WHEN security.security_pkg.object_not_found THEN
			security.web_pkg.CreateResource(v_act_id, v_www, v_www_site_portal, 'admin', v_www_site_portal_admin);
			security.securableobject_pkg.ClearFlag(v_act_id, v_www_site_portal_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
			-- add registered users to portal web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_site_portal), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			-- add admins users to portal admin web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_site_portal_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	--
	-- create site/rss web-resource
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site'), 'rss', v_www_site_rss);
		-- add admins users to rss web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_site_rss), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_site_rss := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site/rss');
	END;

	BEGIN
		v_portlets := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Portlets');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Portlets', v_portlets);

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_portlets), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	IF v_menu_data IS NOT NULL THEN
		--
		-- insert a bunch of default portlets
		FOR r IN(
			SELECT portlet_id
			  FROM portlet
			 WHERE type IN (
				-- in portlet_id order
				'Credit360.Portlets.Chart',
				'Credit360.Portlets.Table',
				'Credit360.Portlets.StickyNote',
				'Credit360.Portlets.NormalForms',
				'Credit360.Portlets.ReportContent',
				'Credit360.Portlets.FeedViewer',
				'Credit360.Portlets.TargetDashboard',
				'Credit360.Portlets.RegionPicker',
				'Credit360.Portlets.MyMessages',
				'Credit360.Portlets.RegionList',
				'Credit360.Portlets.RegionRoles',
				'Credit360.Portlets.MySheets',
				'Credit360.Portlets.RecordLoader',
				'Credit360.Portlets.Button',
				'Credit360.Portlets.PeriodPicker2'
			) AND portlet_id NOT IN (SELECT portlet_id
									   FROM customer_portlet
									  WHERE app_sid = v_app_sid)
		) LOOP
			portlet_pkg.EnablePortletForCustomer(r.portlet_id);
		END LOOP;

		--
		-- create a tab
		portlet_pkg.AddTabReturnTabId(v_app_sid, 'My data',
			1, -- shared
			1, -- hideable
			2, -- layout full width
			NULL,
			v_tab_id);
		portlet_pkg.CreateTabDescriptions(v_tab_id);
		FOR r in (
			SELECT customer_portlet_sid
			  FROM portlet p, customer_portlet cp
			 WHERE name='My forms'
			   AND p.portlet_id=cp.portlet_id
			   AND cp.app_sid = SYS_CONTEXT('SECURITY','APP')
		)
		LOOP
			portlet_pkg.AddPortletToTab(v_tab_id, r.customer_portlet_sid, v_cur);
		END LOOP;
		-- share the tab
		v_tab_ids(1) := v_tab_id;
		IF v_data_providers_sid IS NOT NULL THEN
			portlet_pkg.SetTabsForGroup(NULL, v_data_providers_sid, v_tab_ids);
		END IF;
		IF v_data_approvers_sid IS NOT NULL THEN
			portlet_pkg.SetTabsForGroup(NULL, v_data_approvers_sid, v_tab_ids);
		END IF;
		portlet_pkg.SetTabsForGroup(NULL, v_admins_sid, v_tab_ids); -- superadmins aren't members of data providers

		-- Make the app admin user the owner (not builtin/administrator)
		UPDATE tab_user
		   SET user_sid = security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'users/admin')
		 WHERE is_owner = 1
		   AND tab_id = v_tab_id;
	END IF;
	-- reset to the previous ACT
	security.security_pkg.SetACT(v_act_id, v_app_sid);
END;

PROCEDURE EnableRestAPI (
	in_enable_guest_access IN VARCHAR2 DEFAULT NULL
)
AS
	v_act_id							security.security_pkg.T_ACT_ID;
	v_app_sid							security.security_pkg.T_SID_ID;

	-- users
	v_groups_sid						security.security_pkg.T_SID_ID;
	v_registered_users_sid				security.security_pkg.T_SID_ID;
	v_everyone_sid						security.security_pkg.T_SID_ID;
	v_superadmins_sid					security.security_pkg.T_SID_ID;

	-- web resources
	v_www_sid							security.security_pkg.T_SID_ID;
	v_www_restapi						security.security_pkg.T_SID_ID;
	v_www_restapi_v1					security.security_pkg.T_SID_ID;
	v_www_restapi_v1_user				security.security_pkg.T_SID_ID;
	v_www_restapi_v1_surveys			security.security_pkg.T_SID_ID := NULL;
	v_www_restapi_v1_files				security.security_pkg.T_SID_ID := NULL;
	v_www_restapi_v1_files_up			security.security_pkg.T_SID_ID := NULL;
	v_www_csr_site						security.security_pkg.T_SID_ID;
	v_www_csr_site_restapi				security.security_pkg.T_SID_ID;

BEGIN
	v_act_id := security_pkg.getAct;
	v_app_sid := security_pkg.getApp;

	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_registered_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');

	-- grant registered users read permission on the groups node
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_groups_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	BEGIN
		-- clear existing permissions from wwwroot/restapi
		v_www_restapi := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'restapi');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_restapi), v_registered_users_sid);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create wwwroot/restapi
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_sid, 'restapi', v_www_restapi);
	END;

	-- add registered users to wwwroot/restapi
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_restapi), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		-- find wwwroot/restapi/v1
		v_www_restapi_v1 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_restapi, 'v1');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create wwwroot/restapi/v1
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_restapi, 'v1', v_www_restapi_v1);
	END;

	BEGIN
		-- find wwwroot/restapi/v1/user
		v_www_restapi_v1_user := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_restapi_v1, 'user');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create wwwroot/restapi/v1/user
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_restapi_v1, 'user', v_www_restapi_v1_user);
	END;

	-- add everyone to wwwroot/restapi/v1/user
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_restapi_v1_user), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		v_www_restapi_v1_surveys := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_restapi_v1, 'surveys');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	BEGIN
		v_www_restapi_v1_files := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_restapi_v1, 'files');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	IF v_www_restapi_v1_files IS NOT NULL THEN
		BEGIN
			v_www_restapi_v1_files_up := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_restapi_v1_files, 'upload');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
		END;
	END IF;

	IF lower(substr(trim(in_enable_guest_access), 0, 1)) in ('t', 'y', 'e') THEN

		UPDATE customer SET rest_api_guest_access = 1 WHERE app_sid = v_app_sid;

		IF v_www_restapi_v1_surveys IS NULL THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_restapi_v1, 'surveys', v_www_restapi_v1_surveys);
		END IF;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_restapi_v1_surveys), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		IF v_www_restapi_v1_files IS NULL THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_restapi_v1, 'files', v_www_restapi_v1_files);
		END IF;

		IF v_www_restapi_v1_files_up IS NULL THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_restapi_v1_files, 'upload', v_www_restapi_v1_files_up);
		END IF;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_restapi_v1_files_up), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	ELSIF lower(substr(trim(in_enable_guest_access), 0, 1)) in ('f', 'n', 'd') THEN

		UPDATE customer SET rest_api_guest_access = 0 WHERE app_sid = v_app_sid;

		IF v_www_restapi_v1_surveys IS NOT NULL THEN
			security.web_pkg.DeleteResource(v_act_id, v_www_restapi_v1_surveys);
		END IF;

		IF v_www_restapi_v1_files IS NOT NULL THEN
			security.web_pkg.DeleteResource(v_act_id, v_www_restapi_v1_files);
		END IF;

	ELSIF in_enable_guest_access IS NOT NULL THEN

		RAISE_APPLICATION_ERROR( -20001, 'Input "' || in_enable_guest_access || '" not valid for in_enable_guest_access');

	END IF;

	-- create resource for csr/site/restapi
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_restapi := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'restApi');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'restApi', v_www_csr_site_restapi);
	END;

	-- add superadmins to csr/site/restapi
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_restapi), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
END;

PROCEDURE EnableDroidAPI (
	in_enable_guest_access IN VARCHAR2 DEFAULT NULL
)
AS
	v_act_id							security.security_pkg.T_ACT_ID;
	v_app_sid							security.security_pkg.T_SID_ID;

	-- users
	v_groups_sid						security.security_pkg.T_SID_ID;
	v_registered_users_sid				security.security_pkg.T_SID_ID;
	v_everyone_sid						security.security_pkg.T_SID_ID;
	v_superadmins_sid					security.security_pkg.T_SID_ID;

	-- web resources
	v_www_sid							security.security_pkg.T_SID_ID;
	v_www_droidapi						security.security_pkg.T_SID_ID;
	v_www_droidapi_v1					security.security_pkg.T_SID_ID;
	v_www_droidapi_v1_user				security.security_pkg.T_SID_ID;
	v_www_droidapi_v1_surveys			security.security_pkg.T_SID_ID := NULL;
	v_www_droidapi_v1_files				security.security_pkg.T_SID_ID := NULL;
	v_www_droidapi_v1_files_up			security.security_pkg.T_SID_ID := NULL;
	v_www_csr_site						security.security_pkg.T_SID_ID;
	v_www_csr_site_droidapi				security.security_pkg.T_SID_ID;

BEGIN
	v_act_id := security_pkg.getAct;
	v_app_sid := security_pkg.getApp;

	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_registered_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');

	-- grant registered users read permission on the groups node
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_groups_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	BEGIN
		-- clear existing permissions from wwwroot/droidapi
		v_www_droidapi := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'droidapi');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_droidapi), v_registered_users_sid);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create wwwroot/droidapi
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_sid, 'droidapi', v_www_droidapi);
	END;

	-- add registered users to wwwroot/droidapi
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_droidapi), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		-- find wwwroot/droidapi/v1
		v_www_droidapi_v1 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_droidapi, 'v1');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create wwwroot/droidapi/v1
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_droidapi, 'v1', v_www_droidapi_v1);
	END;

	BEGIN
		-- find wwwroot/droidapi/v1/user
		v_www_droidapi_v1_user := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_droidapi_v1, 'user');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create wwwroot/droidapi/v1/user
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_droidapi_v1, 'user', v_www_droidapi_v1_user);
	END;

	-- add everyone to wwwroot/droidapi/v1/user
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_droidapi_v1_user), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		v_www_droidapi_v1_surveys := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_droidapi_v1, 'surveys');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	BEGIN
		v_www_droidapi_v1_files := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_droidapi_v1, 'files');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	IF v_www_droidapi_v1_files IS NOT NULL THEN
		BEGIN
			v_www_droidapi_v1_files_up := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_droidapi_v1_files, 'upload');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
		END;
	END IF;

	IF lower(substr(trim(in_enable_guest_access), 0, 1)) in ('t', 'y', 'e') THEN

		UPDATE customer SET rest_api_guest_access = 1 WHERE app_sid = v_app_sid;

		IF v_www_droidapi_v1_surveys IS NULL THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_droidapi_v1, 'surveys', v_www_droidapi_v1_surveys);
		END IF;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_droidapi_v1_surveys), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		IF v_www_droidapi_v1_files IS NULL THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_droidapi_v1, 'files', v_www_droidapi_v1_files);
		END IF;

		IF v_www_droidapi_v1_files_up IS NULL THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_droidapi_v1_files, 'upload', v_www_droidapi_v1_files_up);
		END IF;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_droidapi_v1_files_up), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	ELSIF lower(substr(trim(in_enable_guest_access), 0, 1)) in ('f', 'n', 'd') THEN

		UPDATE customer SET rest_api_guest_access = 0 WHERE app_sid = v_app_sid;

		IF v_www_droidapi_v1_surveys IS NOT NULL THEN
			security.web_pkg.DeleteResource(v_act_id, v_www_droidapi_v1_surveys);
		END IF;

		IF v_www_droidapi_v1_files IS NOT NULL THEN
			security.web_pkg.DeleteResource(v_act_id, v_www_droidapi_v1_files);
		END IF;

	ELSIF in_enable_guest_access IS NOT NULL THEN

		RAISE_APPLICATION_ERROR( -20001, 'Input "' || in_enable_guest_access || '" not valid for in_enable_guest_access');

	END IF;

	-- create resource for csr/site/droidapi
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_droidapi := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'droidapi');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'droidapi', v_www_csr_site_droidapi);
	END;

	-- add superadmins to csr/site/droidapi
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_droidapi), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
END;

PROCEDURE EnableRReports
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_class_id					security.security_pkg.T_CLASS_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_auditors_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	-- r reports container
	v_r_reports_sid				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_rreports		security.security_pkg.T_SID_ID;
	v_www_csr_site_rr_admin		security.security_pkg.T_SID_ID;
	-- menu
	v_menu_rreports				security.security_pkg.T_SID_ID;
	v_menu_rreports_list		security.security_pkg.T_SID_ID;
	v_menu_rreports_joblist		security.security_pkg.T_SID_ID;
	v_menu_rreports_enqueue		security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	-- create container
	BEGIN
		v_r_reports_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'R Reports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'R Reports', v_r_reports_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_r_reports_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;
	-- web resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_rreports := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'rreports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'rreports', v_www_csr_site_rreports);
	END;
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_rreports), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	BEGIN
		v_www_csr_site_rr_admin := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_rreports, 'admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_rreports, 'admin', v_www_csr_site_rr_admin);
	END;
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_rr_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- menu
	BEGIN
		v_menu_rreports := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/rreports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu'),
				'rreports', 'R Reports', '/csr/site/rreports/list.acds', 8, null, v_menu_rreports);
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_rreports,
			'csr_rreports_enqueue', 'New Report', '/csr/site/rreports/enqueueJob.acds', 1, null, v_menu_rreports_enqueue);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_rreports,
			'csr_rreports_joblist', 'Reports being processed', '/csr/site/rreports/jobList.acds', 2, null, v_menu_rreports_joblist);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id,  v_menu_rreports,
			'csr_rreports_list', 'Reports', '/csr/site/rreports/list.acds', 3, null, v_menu_rreports_list);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE EnableRBAIntegration
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_audit_type_cur				security.security_pkg.T_OUTPUT_CUR;
	v_expiry_alert_roles			security.security_pkg.T_SID_IDS;
	v_audit_types					security.security_pkg.T_SID_IDS;
	v_audit_type_id 				security.security_pkg.T_SID_ID;
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_wf_ct_sid						security.security_pkg.T_SID_ID;
	v_s1							security.security_pkg.T_SID_ID;
	v_flow_type						VARCHAR2(256);
	v_tag_group_id					tag_group.tag_group_id%TYPE;
	v_tag_id						tag.tag_id%TYPE;
	v_superadmins_sid				security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_app_sid      				security.security_pkg.T_SID_ID;
	v_www_ui_rba_integration		security.security_pkg.T_SID_ID;
	v_www_app_ui_rba_integration	security.security_pkg.T_SID_ID;
	v_count							NUMBER;
	v_score_type_id					security.security_pkg.T_SID_ID;
	v_nct_id						NUMBER(10);
	v_nc_types						security.security_pkg.T_SID_IDS;
	v_dummy_sids					security.security_pkg.T_SID_IDS;
	v_position						NUMBER;
	v_index							NUMBER;
	v_menu_audit					security.security_pkg.T_SID_ID;
	v_audit_admin					security.security_pkg.T_SID_ID;

	E_TOO_MANY_ROWS			EXCEPTION;
	PRAGMA EXCEPTION_INIT (E_TOO_MANY_ROWS, -01422);

	PROCEDURE AddClosureType(
		in_audit_type_id			csr.internal_audit_type.internal_audit_type_id%TYPE,
		in_label					VARCHAR2,
		in_lookup					VARCHAR2
	) AS
		v_audit_closure_type_id		csr.audit_closure_type.audit_closure_type_id%TYPE;
		v_create_failed				NUMBER:=0;
	BEGIN
		BEGIN
			SELECT audit_closure_type_id
				INTO v_audit_closure_type_id
				FROM csr.audit_closure_type
				WHERE app_sid = security.security_pkg.GetApp
				AND (label = in_label AND lookup_key IS NULL) OR lookup_key = in_lookup;

			UPDATE csr.audit_closure_type
				SET lookup_key = in_lookup
				WHERE app_sid = security.security_pkg.GetApp
				AND audit_closure_type_id = v_audit_closure_type_id;
		EXCEPTION
			WHEN no_data_found THEN
				INSERT INTO csr.audit_closure_type (app_sid, audit_closure_type_id, label, is_failure, lookup_key)
				VALUES (security.security_pkg.GetApp, csr.audit_closure_type_id_seq.NEXTVAL, in_label, 0, in_lookup)
				RETURNING audit_closure_type_id INTO v_audit_closure_type_id;
		END;

		BEGIN
			INSERT INTO csr.audit_type_closure_type (app_sid, internal_audit_type_id, audit_closure_type_id, re_audit_due_after,
					re_audit_due_after_type, reminder_offset_days, reportable_for_months, ind_sid)
			VALUES (security.security_pkg.GetApp, in_audit_type_id, v_audit_closure_type_id, NULL, NULL, NULL, NULL, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN NULL;
		END;
	END;
	PROCEDURE AddInternalAuditType(
		in_workflow_sid		IN security.security_pkg.T_SID_ID,
		in_label			IN VARCHAR2,
		in_lookup_key		IN VARCHAR2,
		out_audit_type_id	OUT security.security_pkg.T_SID_ID
	)
	AS
		v_internal_audit_type_id		security.security_pkg.T_SID_ID;
	BEGIN
		BEGIN
			SELECT internal_audit_type_id
			  INTO v_internal_audit_type_id
			  FROM internal_audit_type
			 WHERE app_sid = security.security_pkg.getapp
			   AND UPPER(lookup_key) = in_lookup_key;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_internal_audit_type_id := NULL;
		END;

		BEGIN
			audit_pkg.saveinternalaudittype(
				in_internal_audit_type_id		=> v_internal_audit_type_id,
				in_label						=> in_label,
				in_every_n_months				=> null,
				in_auditor_role_sid				=> null,
				in_audit_contact_role_sid		=> null,
				in_default_survey_sid			=> null,
				in_default_auditor_org			=> '',
				in_override_issue_dtm			=> 0,
				in_assign_issues_to_role		=> 0,
				in_auditor_can_take_ownership	=> 0,
				in_add_nc_per_question			=> 0,
				in_nc_audit_child_region		=> 0,
				in_flow_sid						=> in_workflow_sid,
				in_internal_audit_source_id		=> csr.audit_pkg.integration_audit_source_id,
				in_summary_survey_sid			=> null,
				in_send_auditor_expiry_alerts	=> 1,
				in_expiry_alert_roles			=> v_expiry_alert_roles,
				in_validity_months				=> null,
				in_involve_auditor_in_issues	=> 0,
				in_active						=> 1,
				out_cur							=> v_audit_type_cur
			);

			SELECT internal_audit_type_id
			  INTO v_internal_audit_type_id
			  FROM internal_audit_type
			 WHERE app_sid = security.security_pkg.getapp
			   AND label = in_label;

			UPDATE internal_audit_type
			   SET lookup_key = in_lookup_key
			 WHERE internal_audit_type_id = v_internal_audit_type_id;
		EXCEPTION
			WHEN E_TOO_MANY_ROWS THEN
				RAISE_APPLICATION_ERROR(-20001, 'An Audit Type with label "'||in_label||'" already exists. Rename/remove this type to remove the clash or set the lookup key to '||in_lookup_key||' to reuse it.');
		END;
		out_audit_type_id := v_internal_audit_type_id;
	END;
BEGIN
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	-- Chain specific
	UPDATE chain.reference
		SET label = 'RBA Site Code'
		WHERE lookup_key = 'RBA_SITECODE';
	IF SQL%ROWCOUNT = 0 THEN
		BEGIN
			INSERT INTO chain.reference (lookup_key, label, mandatory, reference_uniqueness_id, reference_location_id, show_in_filter, reference_id, reference_validation_id)
			VALUES ('RBA_SITECODE', 'RBA Site Code', 0, chain.chain_pkg.REF_UNIQUE_NONE, chain.chain_pkg.REF_LOC_COMPANY_DETAILS, 1, chain.reference_id_seq.NEXTVAL, chain.chain_pkg.REFERENCE_VALIDATION_ALL);
		EXCEPTION
			WHEN OTHERS THEN
				-- ORA-02291
				RAISE_APPLICATION_ERROR(-20001, 'Unable to add chain reference. Enable chain before enabling this module.');
		END;
	END IF;

	-- Add Workflow
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/RBA Audit Workflow');
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
				   AND cfac.flow_alert_class = 'audit';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please enable the audit module first');
			END;

			-- create our workflow
			csr.flow_pkg.CreateFlow(
				in_label			=> 'RBA Audit Workflow',
				in_parent_sid		=> v_wf_ct_sid,
				in_flow_alert_class	=> 'audit',
				out_flow_sid		=> v_workflow_sid
			);

			-- Initiate variables and populate temp tables
			v_s1 := csr.flow_pkg.GetNextStateId;
			v_audit_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Audit administrators');

			csr.flow_pkg.SetTempFlowState(
				in_flow_sid => v_workflow_sid,
				in_pos => 1,
				in_flow_state_id => v_s1,
				in_label => 'Created',
				in_lookup_key => '',
				in_is_final => 1,
				in_state_colour => '3777539',
				in_editable_role_sids => null,
				in_non_editable_role_sids => null,
				in_editable_col_sids => null,
				in_non_editable_col_sids => null,
				in_involved_type_ids => null,
				in_editable_group_sids => v_audit_admin,
				in_non_editable_group_sids => null,
				in_flow_state_group_ids => null,
				in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="769.2" y="839.6" />',
				in_flow_state_nature_id => null,
				in_survey_editable => 0,
				in_survey_tag_ids => null
			);

			csr.flow_pkg.SetFlowFromTempTables(
				in_flow_sid => v_workflow_sid,
				in_flow_label => 'RBA Audit Workflow',
				in_flow_alert_class => 'audit',
				in_cms_tab_sid => null,
				in_default_state_id => v_s1
			);
			
			-- Audit - Audit capability 
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 1,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - Survey capability 
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 2,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - Findings capability 
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 3,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - Add actions capability 
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 4,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 2,
				in_group_sid => v_audit_admin
			);
			-- Audit - Download report capability 
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 5,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 2,
				in_group_sid => v_audit_admin
			);
			-- Audit - Pinboard capability 
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 6,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - View audit log
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 7,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 2,
				in_group_sid => v_audit_admin
			);
			-- Audit - Closure result
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 8,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - Copy audit
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 9,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 2,
				in_group_sid => v_audit_admin
			);
			-- Audit - Delete audit
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 10,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 0,
				in_group_sid => v_audit_admin
			);
			-- Audit - Import findings
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 11,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 0,
				in_group_sid => v_audit_admin
			);
			-- Audit - Documents
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 12,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - Audit scores
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 13,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 0,
				in_group_sid => v_audit_admin
			);
			-- Audit - Executive summary
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 14,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
			-- Audit - View Users
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 16,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 0,
				in_group_sid => v_audit_admin
			);
			-- Audit - Finding type
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 17,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 3,
				in_group_sid => v_audit_admin
			);
			-- Audit - Close findings
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 18,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 2,
				in_group_sid => v_audit_admin
			);
			-- Audit - Change survey
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 19,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 0,
				in_group_sid => v_audit_admin
			);
			-- Audit - Finding tags
			csr.flow_pkg.SetTempFlowStateRoleCap(
				in_flow_sid => v_workflow_sid,
				in_flow_state_id => v_s1,
				in_flow_capability_id => 23,
				in_role_sid => null,
				in_flow_involvement_type_id => null,
				in_permission_set => 1,
				in_group_sid => v_audit_admin
			);
	END;

	AddInternalAuditType(v_workflow_sid, 'RBA', 'RBA_AUDIT_TYPE', v_audit_type_id);
	v_audit_types(1) := v_audit_type_id;
	AddClosureType(v_audit_type_id, 'Pass', 'PASS');

	SELECT MIN(score_type_id)
	  INTO v_score_type_id
	  FROM score_type
	 WHERE lookup_key = 'RBA_AUDIT_SCORE';

	IF v_score_type_id IS NULL THEN
		csr.quick_survey_pkg.SaveScoreType (
			in_score_type_id		=> NULL,
			in_label				=> 'Score',
			in_pos					=> 1,
			in_hidden				=> 0,
			in_allow_manual_set		=> 0,
			in_lookup_key			=> 'RBA_AUDIT_SCORE',
			in_applies_to_supplier	=> 0,
			in_reportable_months	=> 24,
			in_format_mask			=> '##0.00',
			in_applies_to_audits	=> 1,
			out_score_type_id		=> v_score_type_id
		);

		csr.quick_survey_pkg.SetScoreTypeAuditTypes(v_score_type_id, v_audit_types);
	END IF;

	BEGIN -- Tag Group: Audit Type
	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'RBA Audit Type',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_audits	=> 1,
		in_lookup_key			=> 'RBA_AUDIT_TYPE',
		out_tag_group_id		=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Initial Audit',
		in_pos					=> 0,
		in_lookup_key			=> 'RBA_INITIAL_AUDIT',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Priority Closure Audit',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_PRIORITY_CLOSURE_AUDIT',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Closure Audit',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_CLOSURE_AUDIT',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupIATypes(
		in_tag_group_id			=> v_tag_group_id,
		in_ia_ids				=> v_audit_types
	);
	END;
	BEGIN -- Tag Group: Audit Status
	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'RBA Audit Status',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_audits	=> 1,
		in_lookup_key			=> 'RBA_AUDIT_STATUS',
		out_tag_group_id		=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'AFA Feedback Provided',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_AFA_FEEDBACK_PROVIDED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'AFA Submitted',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_AFA_SUBMITTED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Bidding Initiated',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_BIDDING_INITIATED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Cancelled',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_CANCELLED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Closed',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_CLOSED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Contracting Initiated',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_CONTRACTING_INITIATED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Contracting signed by Auditee',
		in_pos					=> 7,
		in_lookup_key			=> 'RBA_CONTRACTING_SIGNED_BY_AUDI',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Final Draft Submitted',
		in_pos					=> 8,
		in_lookup_key			=> 'RBA_FINAL_DRAFT_SUBMITTED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Initial Draft Submitted',
		in_pos					=> 9,
		in_lookup_key			=> 'RBA_INITIAL_DRAFT_SUBMITTED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'QC Complete',
		in_pos					=> 10,
		in_lookup_key			=> 'RBA_QC_COMPLETE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'SA Signed',
		in_pos					=> 11,
		in_lookup_key			=> 'RBA_SA_SIGNED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'SA to Payer for Signature',
		in_pos					=> 12,
		in_lookup_key			=> 'RBA_SA_TO_PAYER_FOR_SIGNATURE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Scoping Completed',
		in_pos					=> 13,
		in_lookup_key			=> 'RBA_SCOPING_COMPLETED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'VAR Released',
		in_pos					=> 14,
		in_lookup_key			=> 'RBA_VAR_RELEASED',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupIATypes(
		in_tag_group_id			=> v_tag_group_id,
		in_ia_ids				=> v_audit_types
	);
	END;
	
	BEGIN -- Tag Group: Audit VAP/CMA
	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'RBA VAP/CMA',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_audits	=> 1,
		in_lookup_key			=> 'RBA_AUDIT_VAP_CMA',
		out_tag_group_id		=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'VAP',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_VC_VAP',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'CMA',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_VC_CMA',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTagGroupIATypes(
		in_tag_group_id			=> v_tag_group_id,
		in_ia_ids				=> v_audit_types
	);
	END;

	BEGIN -- Tag Group: Audit Category
	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'RBA Audit Category',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_audits	=> 1,
		in_lookup_key			=> 'RBA_AUDIT_CAT',
		out_tag_group_id		=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'VAP',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_VAP',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'VAP: Small Business',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_VAP_SMALL_BUSINESS',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'VAP: Medium Business',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_VAP_MEDIUM_BUSINESS',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Employment Site: SVAP Only',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_EMPLOYMENT_SITE_SVAP_ONLY',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Employment Site: SVAP and VAP',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_EMPLOYMENT_SITE_SVAP_AND_V', -- Max length is 30 so RBA integration truncates the string
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Manufacturer: Chemical Mgmt SVAP',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_MANUFACTURER_CHEMICAL_MGMT', -- Max length is 30 so RBA integration truncates the string
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTagGroupIATypes(
		in_tag_group_id			=> v_tag_group_id,
		in_ia_ids				=> v_audit_types
	);
	END;
	
	BEGIN --Finding Types Region
	-- Finding Severity Types
	v_position := 0;
	v_index := 1;

	-- RBA Priority Non-Conformance
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Priority Non-Conformance',
		in_lookup_key					=> 'RBA_F_PRIORITY_NONCONFORMANCE',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);

	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;

	-- RBA Major Non-Conformance
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Major Non-Conformance',
		in_lookup_key					=> 'RBA_F_MAJOR_NONCONFORMANCE',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;

	-- RBA Minor Non-Conformance
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Minor Non-Conformance',
		in_lookup_key					=> 'RBA_F_MINOR_NONCONFORMANCE',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;

	-- RBA Risk of Non-Conformance
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Risk of Non-Conformance',
		in_lookup_key					=> 'RBA_F_RISK_OF_NONCONFORMANCE',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;

	-- RBA Opportunity for Improvement
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Opportunity for Improvement',
		in_lookup_key					=> 'RBA_F_OPPORTUNITY_FOR_IMPROVEM',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;

	-- RBA Conformance
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Conformance',
		in_lookup_key					=> 'RBA_F_CONFORMANCE',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;

	-- RBA Not Applicable
	csr.audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> 'RBA Not Applicable',
		in_lookup_key					=> 'RBA_F_NOT_APPLICABLE',
		in_position						=> v_position,
		in_colour_when_open				=> 16712965,
		in_colour_when_closed			=> 3777539, 
		in_can_have_actions				=> 1,
		in_closure_behaviour_id			=> 1,
		in_root_cause_enabled			=> 1,
		in_suggested_action_enabled		=> 1,
		in_repeat_audit_type_ids		=> v_dummy_sids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	csr.audit_pkg.SetAuditTypeNonCompType(
		in_internal_audit_type_id	=> v_audit_types(1),
		in_non_compliance_type_id	=> v_nct_id
	);
	
	v_nc_types(v_index) := v_nct_id;

	v_position := v_position + 1;
	v_index := v_index + 1;
	END;
	
	-- Sections/Subsections
	-- Sections based on the report sample.
	-- Subsections based on the 7.x template.
	-- Both are here: https://ul.sharepoint.com/sites/Ventures/621/Software_Dev/cr360/Teamspace/Unusual%20Suspects/Forms/AllItems.aspx?id=%2Fsites%2FVentures%2F621%2FSoftware%5FDev%2Fcr360%2FTeamspace%2FUnusual%20Suspects%2FRBA
	BEGIN -- Region
	-- Section A (Labor)
	csr.tag_pkg.SetTagGroup(
		in_name					=> 'RBA Labor',
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_SECTION_A',
		out_tag_group_id		=> v_tag_group_id
	);
	
	-- A1 FREELY CHOSEN EMPLOYMENT
	-- A2 CHILD LABOR AVOIDANCE
	-- A3 WORKING HOURS
	-- A4 WAGES AND BENEFITS
	-- A5 HUMANE TREATMENT
	-- A6 NON-DISCRIMINATION
	-- A7 FREEDOM OF ASSOCIATION
	-- A8 LABOR PROVISION GOOD PRACTICES
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'FREELY CHOSEN EMPLOYMENT',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_A1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'CHILD LABOR AVOIDANCE',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_A2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'WORKING HOURS',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_A3',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'WAGES AND BENEFITS',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_SUBSECTION_A4',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'HUMANE TREATMENT',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_SUBSECTION_A5',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'NON-DISCRIMINATION',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_SUBSECTION_A6',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'FREEDOM OF ASSOCIATION',
		in_pos					=> 7,
		in_lookup_key			=> 'RBA_SUBSECTION_A7',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'LABOR PROVISION GOOD PRACTICES',
		in_pos					=> 8,
		in_lookup_key			=> 'RBA_SUBSECTION_A8',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	

	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- Section B (Health and Safety)
	csr.tag_pkg.SetTagGroup(
		in_name					=> 'RBA Health and Safety',
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_SECTION_B',
		out_tag_group_id		=> v_tag_group_id
	);
	
	-- B1 OCCUPATIONAL SAFETY
	-- B2 EMERGENCY PREPAREDNESS
	-- B3 OCCUPATIONAL INJURY AND ILLNESS
	-- B4 INDUSTRIAL HYGIENE
	-- B5 PHYSICALLY DEMANDING WORK
	-- B6 MACHINE SAFEGUARDING
	-- B7 FOOD, SANITATION AND HOUSING
	-- B8 HEALTH AND SAFETY COMMUNICATION
	-- B9 HEALTH ampersand SAFETY PROVISION GOOD PRACTICES

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'OCCUPATIONAL SAFETY',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_SUBSECTION_B1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'EMERGENCY PREPAREDNESS',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_SUBSECTION_B2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'OCCUPATIONAL INJURY AND ILLNESS',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_B3',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'INDUSTRIAL HYGIENE',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_SUBSECTION_B4',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'PHYSICALLY DEMANDING WORK',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_SUBSECTION_B5',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'MACHINE SAFEGUARDING',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_SUBSECTION_B6',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'FOOD, SANITATION AND HOUSING',
		in_pos					=> 7,
		in_lookup_key			=> 'RBA_SUBSECTION_B7',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'HEALTH AND SAFETY COMMUNICATION',
		in_pos					=> 8,
		in_lookup_key			=> 'RBA_SUBSECTION_B8',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'HEALTH ' || chr(38) || ' SAFETY PROVISION GOOD PRACTICES',
		in_pos					=> 9,
		in_lookup_key			=> 'RBA_SUBSECTION_B9',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- Section C (Environment)
	csr.tag_pkg.SetTagGroup(
		in_name					=> 'RBA Environment',
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_SECTION_C',
		out_tag_group_id		=> v_tag_group_id
	);
	
	-- C1 ENVIRONMENTAL PERMITS AND REPORTING
	-- C2 POLLUTION PREVENTION AND RESOURCE REDUCTION 
	-- C3 HAZARDOUS SUBSTANCES
	-- C4 SOLID WASTE
	-- C5 AIR EMISSIONS
	-- C6 MATERIALS RESTRICTIONS
	-- C7 WATER MANAGEMENT
	-- C8 ENERGY CONSUMPTION AND GREENHOUSE GAS EMISSIONS
	-- C9 ENVIRONMENT PROVISION GOOD PRACTICES

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'ENVIRONMENTAL PERMITS AND REPORTING',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_SUBSECTION_C1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'POLLUTION PREVENTION AND RESOURCE REDUCTION',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_SUBSECTION_C2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'HAZARDOUS SUBSTANCES',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_C3',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'SOLID WASTE',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_SUBSECTION_C4',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'AIR EMISSIONS',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_SUBSECTION_C5',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'MATERIALS RESTRICTIONS',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_SUBSECTION_C6',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'WATER MANAGEMENT',
		in_pos					=> 7,
		in_lookup_key			=> 'RBA_SUBSECTION_C7',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'ENERGY CONSUMPTION AND GREENHOUSE GAS EMISSIONS',
		in_pos					=> 8,
		in_lookup_key			=> 'RBA_SUBSECTION_C8',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'ENVIRONMENT PROVISION GOOD PRACTICES',
		in_pos					=> 9,
		in_lookup_key			=> 'RBA_SUBSECTION_C9',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- Section D (Ethics)
	csr.tag_pkg.SetTagGroup(
		in_name					=> 'RBA Ethics',
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_SECTION_D',
		out_tag_group_id		=> v_tag_group_id
	);
	
	-- D1 BUSINESS INTEGRITY
	-- D2 NO IMPROPER ADVANTAGE
	-- D3 DISCLOSURE OF INFORMATION
	-- D4 INTELLECTUAL PROPERTY
	-- D5 FAIR BUSINESS, ADVERTISING AND COMPETITION
	-- D6 PROTECTION OF IDENTITY AND NON-RETALIATION
	-- D7 RESPONSIBLE SOURCING OF MINERALS
	-- D8 PRIVACY
	-- D9 ETHICS PROVISION GOOD PRACTICES

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'BUSINESS INTEGRITY',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_SUBSECTION_D1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'NO IMPROPER ADVANTAGE',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_SUBSECTION_D2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'DISCLOSURE OF INFORMATION',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_D3',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'INTELLECTUAL PROPERTY',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_SUBSECTION_D4',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'FAIR BUSINESS, ADVERTISING AND COMPETITION',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_SUBSECTION_D5',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'PROTECTION OF IDENTITY AND NON-RETALIATION',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_SUBSECTION_D6',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RESPONSIBLE SOURCING OF MINERALS',
		in_pos					=> 7,
		in_lookup_key			=> 'RBA_SUBSECTION_D7',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'PRIVACY',
		in_pos					=> 8,
		in_lookup_key			=> 'RBA_SUBSECTION_D8',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'ETHICS PROVISION GOOD PRACTICES',
		in_pos					=> 9,
		in_lookup_key			=> 'RBA_SUBSECTION_D9',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- Section E (Mgt. System)
	csr.tag_pkg.SetTagGroup(
		in_name					=> 'RBA Mgt. System',
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_SECTION_E',
		out_tag_group_id		=> v_tag_group_id
	);
	
	-- E1 CERTIFICATIONS
	-- E2 COMPANY COMMITMENT
	-- E3 MANAGEMENT ACCOUNTABILITY AND RESPONSIBILITY
	-- E4 LEGAL AND CUSTOMER REQUIREMENTS
	-- E5 RISK ASSESSMENT AND RISK MANAGEMENT
	-- E6 IMPROVEMENT OBJECTIVES
	-- E7 TRAINING
	-- E8 COMMUNICATION
	-- E9 WORKER FEEDBACK AND PARTICIPATION
	-- E10 AUDITS AND ASSESSMENTS
	-- E11 CORRECTIVE ACTION PROCESS
	-- E12 DOCUMENTATION AND RECORDS
	-- E13 SUPPLIER RESPONSIBILITY
	-- E14 MANAGEMENT SYSTEM PROVISION GOOD PRACTICES

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'CERTIFICATIONS',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_SUBSECTION_E1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'COMPANY COMMITMENT',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_SUBSECTION_E2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'MANAGEMENT ACCOUNTABILITY AND RESPONSIBILITY',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_SUBSECTION_E3',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'LEGAL AND CUSTOMER REQUIREMENTS',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_SUBSECTION_E4',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RISK ASSESSMENT AND RISK MANAGEMENT',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_SUBSECTION_E5',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'IMPROVEMENT OBJECTIVES',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_SUBSECTION_E6',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'TRAINING',
		in_pos					=> 7,
		in_lookup_key			=> 'RBA_SUBSECTION_E7',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'COMMUNICATION',
		in_pos					=> 8,
		in_lookup_key			=> 'RBA_SUBSECTION_E8',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'WORKER FEEDBACK AND PARTICIPATION',
		in_pos					=> 9,
		in_lookup_key			=> 'RBA_SUBSECTION_E9',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'AUDITS AND ASSESSMENTS',
		in_pos					=> 10,
		in_lookup_key			=> 'RBA_SUBSECTION_E10',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'CORRECTIVE ACTION PROCESS',
		in_pos					=> 11,
		in_lookup_key			=> 'RBA_SUBSECTION_E11',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'DOCUMENTATION AND RECORDS',
		in_pos					=> 12,
		in_lookup_key			=> 'RBA_SUBSECTION_E12',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'SUPPLIER RESPONSIBILITY',
		in_pos					=> 13,
		in_lookup_key			=> 'RBA_SUBSECTION_E13',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'MANAGEMENT SYSTEM PROVISION GOOD PRACTICES',
		in_pos					=> 14,
		in_lookup_key			=> 'RBA_SUBSECTION_E14',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- This is present in the offline VAP protocol. Isn't required now, but is here for future reference.
	-- Info
	-- GENERAL AUDITEE FACILITY INFORMATION
	-- POPULATION SIZE
	-- POPULATION CHARACTERISTICS
	-- SITE ACTIVITIES AND PROCESSES
	-- PRIMARY TYPES OF OPERATION
	-- ON-SITE SERVICES
	-- CERTIFICATIONS
	-- CONSULTING SERVICES USED IN LAST YEAR
	-- LABOR AGENT/CONTRACTOR SERVICES USED IN LAST 2 YEARS
	-- OTHER CONSULTING SERVICES USED IN LAST 3 YEARS
	-- AUDIT TEAM: LEAD AUDITOR
	-- LABOR AUDITOR
	-- ETHICS AUDITOR
	-- HEALTH AND SAFETY AUDITOR
	-- ENVIRONMENT AUDITOR
	-- MANAGEMENT SYSTEMS AUDITOR
	-- STAFF INTERVIEWS
	-- TOTAL INTERVIEWS
	-- MINIMUM NUMBER OF INTERVIEWS TO BE CARRIED OUT IN THIS AUDIT
	-- PROCESS AND SUMMARY
	END;
	
		-- Previous Finding Severity:
	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'Previous Severity',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_PREV_FINDING_SEVERITY',
		out_tag_group_id		=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Priority Non-Conformance',
		in_pos					=> 0,
		in_lookup_key			=> 'RBA_PREV_PRIORITY_NONCONFORMAN',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Major Non-Conformance',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_PREV_MAJOR_NONCONFORMANCE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Minor Non-Conformance',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_PREV_MINOR_NONCONFORMANCE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Risk of Non-Conformance',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_PREV_RISK_OF_NONCONFORMANC',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Opportunity for Improvement',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_PREV_OPPORTUNITY_FOR_IMPRO',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Conformance',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_PREV_CONFORMANCE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Not Applicable',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_PREV_NOT_APPLICABLE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- Initial Finding Severity:
	csr.tag_pkg.SetTagGroup(
		in_act_id				=> v_act_id,
		in_app_sid				=> v_app_sid,
		in_name					=> 'Initial Severity',
		in_multi_select			=> 0,
		in_mandatory			=> 0,
		in_applies_to_non_comp	=> 1,
		in_lookup_key			=> 'RBA_INIT_FINDING_SEVERITY',
		out_tag_group_id		=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Priority Non-Conformance',
		in_pos					=> 0,
		in_lookup_key			=> 'RBA_INIT_PRIORITY_NONCONFORMAN',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Major Non-Conformance',
		in_pos					=> 1,
		in_lookup_key			=> 'RBA_INIT_MAJOR_NONCONFORMANCE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Minor Non-Conformance',
		in_pos					=> 2,
		in_lookup_key			=> 'RBA_INIT_MINOR_NONCONFORMANCE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Risk of Non-Conformance',
		in_pos					=> 3,
		in_lookup_key			=> 'RBA_INIT_RISK_OF_NONCONFORMANC',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Opportunity for Improvement',
		in_pos					=> 4,
		in_lookup_key			=> 'RBA_INIT_OPPORTUNITY_FOR_IMPRO',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Conformance',
		in_pos					=> 5,
		in_lookup_key			=> 'RBA_INIT_CONFORMANCE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTag(
		in_act_id				=> v_act_id,
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Not Applicable',
		in_pos					=> 6,
		in_lookup_key			=> 'RBA_INIT_NOT_APPLICABLE',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	csr.tag_pkg.SetTagGroupNCTypes(
		in_tag_group_id			=> v_tag_group_id,
		in_nc_ids				=> v_nc_types
	);

	-- NEW STACK UI
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'app');

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.rba-integration', v_www_ui_rba_integration);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.rba-integration', v_www_app_ui_rba_integration);

	-- Superadmin wwwroot/ui.rba-integration webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_rba_integration), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Superadmin wwwroot/app/ui.rba-integration webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_rba_integration), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- QUESTION/ANSWER QUICK CHART MENU ITEM
	v_audit_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Audit administrators');
	BEGIN
		v_menu_audit := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/ia/csr_ia_qa_list');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/ia'),
				'csr_ia_qa_list', 'Integration Question/Answer List', '/csr/site/audit/integrationquestionanswerlist.acds', 8, null, v_menu_audit);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_audit), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_audit_admin, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	enable_pkg.EnableAuditsApi();
	enable_pkg.EnableIntegrationQuestionAnswer();
	enable_pkg.EnableIntegrationQuestionAnswerApi();
END;

PROCEDURE DisableRBAIntegration
AS
BEGIN
	DELETE FROM chain.reference_capability WHERE reference_id IN (
		SELECT reference_id FROM chain.reference WHERE lookup_key IN ('RBA_SITECODE')
	);
	DELETE FROM chain.company_reference WHERE reference_id IN (
		SELECT reference_id FROM chain.reference WHERE lookup_key IN ('RBA_SITECODE')
	);
	DELETE FROM chain.reference WHERE lookup_key IN ('RBA_SITECODE');
END;

PROCEDURE DeleteRBAIntegration
AS
BEGIN
	DisableRBAIntegration;

	-- There's only one TG for each lookup due to a Unique constraint.
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key = 'RBA_AUDIT_TYPE')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key = 'RBA_AUDIT_CAT')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key = 'RBA_AUDIT_STATUS')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key = 'RBA_AUDIT_VAP_CMA')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key = 'RBA_F_FINDING_SEVERITY')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key LIKE 'RBA_SECTION%')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	FOR r IN (SELECT * FROM tag_group WHERE lookup_key LIKE 'RBA_INIT_FINDING_SEVERITY')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;

	FOR r IN (SELECT * FROM tag_group WHERE lookup_key LIKE 'RBA_PREV_FINDING_SEVERITY')
	LOOP
		tag_pkg.DeleteTagGroup(security.security_pkg.getact, r.tag_group_id);
	END LOOP;
	
	UPDATE internal_audit
	   SET audit_closure_type_id = NULL
	  WHERE audit_closure_type_id IN (
		SELECT audit_closure_type_id
		  FROM audit_closure_type
		 WHERE label = 'Pass'
	);
	DELETE FROM audit_type_closure_type
	 WHERE audit_closure_type_id IN (
		SELECT audit_closure_type_id
		  FROM audit_closure_type
		 WHERE label = 'Pass'
		);
	DELETE FROM audit_closure_type WHERE lookup_key = 'PASS';

	DELETE FROM non_comp_type_audit_type
	 WHERE internal_audit_type_id IN (
		SELECT internal_audit_type_id
		  FROM internal_audit_type
		 WHERE label LIKE 'RBA%'
		)
	   OR non_compliance_type_id IN (
		SELECT non_compliance_type_id
		  FROM non_compliance_type 
		 WHERE lookup_key LIKE 'RBA_%'
		);
	DELETE FROM audit_type_tab
	 WHERE internal_audit_type_id IN (
		SELECT internal_audit_type_id
		  FROM internal_audit_type
		 WHERE label LIKE 'RBA%'
		);
	DELETE FROM audit_type_header
	 WHERE internal_audit_type_id IN (
		SELECT internal_audit_type_id
		  FROM internal_audit_type
		 WHERE label LIKE 'RBA%'
		);
	DELETE FROM internal_audit
	 WHERE internal_audit_type_id IN (
		SELECT internal_audit_type_id
		  FROM internal_audit_type
		 WHERE lookup_key LIKE 'RBA_%'
	);

	DELETE FROM score_type_audit_type WHERE score_type_id IN (SELECT score_type_id FROM score_type WHERE UPPER(lookup_key) = ('RBA_AUDIT_SCORE'));

	DELETE FROM internal_audit_type WHERE lookup_key LIKE 'RBA_%';

	DELETE FROM score_type WHERE UPPER(lookup_key) = 'RBA_AUDIT_SCORE';

	DELETE FROM non_compliance_type WHERE UPPER(lookup_key) LIKE 'RBA_%';
	
	FOR r in (
		SELECT flow_sid
		FROM flow
		WHERE label = 'RBA Audit Workflow')
	LOOP
		BEGIN
			flow_pkg.DeleteObject(security.security_pkg.getact, r.flow_sid);
			security.securableobject_pkg.DeleteSO(security.security_pkg.getact, r.flow_sid);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;
	END LOOP;
	
	BEGIN
		security.securableobject_pkg.DeleteSO(security.security_pkg.getact,
			security.securableobject_pkg.getSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'menu/ia/csr_ia_qa_list')
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;
END;

PROCEDURE EnableSalesSite
AS
	v_tag_group_id	tag_group.tag_group_id%TYPE;
	v_id			tag.tag_id%TYPE;
BEGIN
	-- breeam
	tag_pkg.setTagGroup(
		in_name 				=> 'BREEAM',
		in_multi_select 		=> 1,
		in_applies_to_regions 	=> 1,
		out_tag_group_id 		=> v_tag_group_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'A',
		in_pos => 1,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'B',
		in_pos => 2,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'C',
		in_pos => 3,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'D',
		in_pos => 4,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'E',
		in_pos => 5,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'F',
		in_pos => 6,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'G',
		in_pos => 7,
		out_tag_id => v_id
	);

	-- leed
	tag_pkg.setTagGroup(
		in_name 				=> 'LEED',
		in_multi_select 		=> 1,
		in_applies_to_regions 	=> 1,
		out_tag_group_id 		=> v_tag_group_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Certified',
		in_pos => 1,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Silver',
		in_pos => 2,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Gold',
		in_pos => 3,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Platinum',
		in_pos => 4,
		out_tag_id => v_id
	);

	-- econ19
	tag_pkg.setTagGroup(
		in_name 				=> 'econ19',
		in_multi_select 		=> 1,
		in_applies_to_regions 	=> 1,
		out_tag_group_id 		=> v_tag_group_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Type 1',
		in_pos => 1,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Type 2',
		in_pos => 2,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Type 3',
		in_pos => 3,
		out_tag_id => v_id
	);
	tag_pkg.SetTag(
		in_act_id => security_pkg.getAct,
		in_tag_group_id => v_tag_group_id,
		in_tag => 'Type 4',
		in_pos => 4,
		out_tag_id => v_id
	);
END;

PROCEDURE EnableScenarios
--test data
AS
	v_act_id			security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;
	v_scenarios_sid		security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
	v_admins_sid		security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	InsertIntoOWLClientModule('SCENARIOS', null);

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	--
	/*** CREATE CONTAINER ***/
	BEGIN
		security.securableobject_pkg.CreateSO(
			v_act_id,
			v_app_sid,
			security.security_pkg.SO_CONTAINER,
			'Scenarios',
			v_scenarios_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- already enabled
			RETURN;
	END;
	--
	-- set permissions on scenarios itself
	security.securableobject_pkg.ClearFlag(v_act_id, v_scenarios_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_scenarios_sid), security.security_pkg.SID_BUILTIN_EVERYONE);
	-- add administrators
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_scenarios_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	-- add reg users
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_scenarios_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.PropogateACEs(v_act_id, v_scenarios_sid);
	--
	/*** SCENARIO OPTIONS (all defaults atm) ***/
	INSERT INTO scenario_options (app_sid) VAlUES (v_app_sid);

	UPDATE customer
	   SET scenarios_enabled = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	--
END;

PROCEDURE EnableScheduledTasks
--test data
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_scheduled_tasks	security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	--
	/*** ADD MENU ITEM ***/
	-- will inherit permissions from admin menu parent
	security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
		'csr_issue_scheduled_tasks', 'Scheduled actions', '/csr/site/issues/scheduledTasks.acds', 10, null, v_menu_scheduled_tasks);

	BEGIN
		INSERT INTO issue_type (issue_type_id, label) values (4, 'Scheduled Task');
	EXCEPTION
		WHEN dup_val_on_index then
			null;
	END;
END;

PROCEDURE EnableSheets2
--test data
AS
BEGIN
	UPDATE customer
	   SET editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
	 WHERE app_sid = security.security_pkg.getApp;

	UPDATE delegation
	   SET editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
	 WHERE editing_url LIKE '/csr/site/delegation/sheet.acds?%'; -- just swap over bog standard old sheets

	-- we do core here too because it's easier
	InsertIntoOWLClientModule('DELEGATIONS', 'CORE');

	-- ensure issue tracking turned on
	FOR r IN(
		SELECT security.security_pkg.getapp, portlet_id
		  FROM portlet
		 WHERE type IN (
			'Credit360.Portlets.Issue'
		 ) AND portlet_Id NOT IN (SELECT portlet_id FROM customer_portlet)
	) LOOP
		portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;


	INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_Type_id)
		SELECT app_sid, customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM customer, std_alert_type
		 WHERE editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
		   AND std_alert_Type_id in (17,18)
		   AND app_sid = security.security_pkg.getapp
		   AND std_alert_type_id NOT IN (
				SELECT std_alert_type_id FROM customer_alert_type WHERE app_sid = security.security_pkg.getapp
		);
END;

PROCEDURE EnableSupplierMaps
AS
BEGIN
	UPDATE chain.customer_options
	   SET show_map_on_supplier_list = 1
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE EnableSurveys
--test data
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	v_audits_sid					security.security_pkg.T_SID_ID;
	-- surveys web resource
	v_surveys_sid					security.security_pkg.T_SID_ID;
	v_campaigns_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_survey_list				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_quicksurvey			security.security_pkg.T_SID_ID;
	v_www_csr_quicksurvey_admin		security.security_pkg.T_SID_ID;
	v_www_csr_quicksurvey_results	security.security_pkg.T_SID_ID;
	v_www_csr_quicksurvey_public	security.security_pkg.T_SID_ID;
	v_www_csr_postits				security.security_pkg.T_SID_ID;
	v_publish_survey_permission 	security_pkg.T_PERMISSION := 131072; -- from surveys.question_library_pkg.PERMISSION_PUBLISH_SURVEY
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_regusers_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');


	InsertIntoOWLClientModule('SURVEY_MGR', null);

	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	BEGIN
		v_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'surveys');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_sid, 'surveys', v_surveys_sid);

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	BEGIN
		v_www_csr_postits := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site/postits');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site'), 'postits', v_www_csr_postits);

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_postits), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	/*** ADD MENU ITEMS ***/
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
		'csr_quicksurvey_admin', 'Surveys', '/csr/site/quicksurvey/admin/list.acds', 6, null, v_menu_survey_list);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	/*** WEB RESOURCE ***/
	-- add permissions on pre-created web-resources
	BEGIN
		v_www_csr_quicksurvey := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site/quickSurvey');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site'), 'quickSurvey', v_www_csr_quicksurvey);
	END;

	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_quicksurvey, 'admin', v_www_csr_quicksurvey_admin);
		security.securableobject_pkg.ClearFlag(v_act_id, v_www_csr_quicksurvey_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		-- results
		security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_quicksurvey, 'results', v_www_csr_quicksurvey_results);
		security.securableobject_pkg.ClearFlag(v_act_id, v_www_csr_quicksurvey_results, security.security_pkg.SOFLAG_INHERIT_DACL);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		-- add everyone to the new webresource
		security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_quicksurvey, 'public', v_www_csr_quicksurvey_public);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_quicksurvey_public), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			security.security_pkg.SID_BUILTIN_EVERYONE, security.security_pkg.PERMISSION_STANDARD_ALL);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- add default filtering
	chain.card_pkg.SetGroupCards('Simple Survey Filter', chain.T_STRING_LIST('QuickSurvey.Cards.SurveyResultsFilter'));
	chain.card_pkg.SetGroupCards('Survey Response Filter', chain.T_STRING_LIST('Credit360.QuickSurvey.Filters.SurveyResponseFilter'));

	BEGIN
		v_audits_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Audits');
		chain.card_pkg.InsertGroupCard('Survey Response Filter', 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter', 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	-- add campaigns
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Campaigns', v_campaigns_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE EnableTemplatedReports
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	v_reporters_sid					security.security_pkg.T_SID_ID;
	v_auditors_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_analysis					security.security_pkg.T_SID_ID;
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_menu_tpl_reports				security.security_pkg.T_SID_ID;
	v_myreports_menu				security.security_pkg.T_SID_ID;
	-- container
	v_tpl_reports_container_sid 	security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_auditors_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
	v_reporters_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Reporters');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	--
	-- add a menu item
	v_menu_analysis             := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/analysis');
	BEGIN
	security.menu_pkg.CreateMenu(v_act_id, v_menu_analysis,
		'csr_reports_word', 'Templated reports', '/csr/site/reports/word2/reports.acds', 3, null, v_menu_tpl_reports);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_tpl_reports := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_analysis, 'csr_reports_word');
			-- Make sure the path is to word2 so that this script also works as an upgrade
			security.menu_pkg.SetMenuAction(v_act_id, v_menu_tpl_reports, '/csr/site/reports/word2/reports.acds');
	END;
	-- add admin + reporters to menu option
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_tpl_reports), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reporters_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_tpl_reports), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- "My reports" menu item
	v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/Admin');
	BEGIN
		v_myreports_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_site_reports_word_myreports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_site_reports_word_myreports',  'My reports',  '/csr/site/reports/word2/myreports.acds',  0, null, v_myreports_menu);
	END;
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_myreports_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- create TemplatedReports container
	BEGIN
	security.securableobject_pkg.CreateSO(v_act_id,
		v_app_sid,
		security.security_pkg.SO_CONTAINER,
		'TemplatedReports',
		v_tpl_reports_container_sid
	);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_tpl_reports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'TemplatedReports');
	END;
	-- add reporters/auditors with read (admins will propagate down from parent)
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_tpl_reports_container_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_reporters_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_tpl_reports_container_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	csr_app_pkg.AddAdminAndPublicSubFolders(
		in_parent_sid		=> v_tpl_reports_container_sid
	);
END;

PROCEDURE EnableWorkflow
AS
	-- workflow stuff
	v_wf_ct_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users 					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_admin_workflow_menu			security.security_pkg.T_SID_ID;
	v_setup_menu					security.security_pkg.T_SID_ID;
	v_setup_inv_type_menu			security.security_pkg.T_SID_ID;
	-- web resources
	v_www_root 						security.security_pkg.T_SID_ID;
	v_www_csr_site 					security.security_pkg.T_SID_ID;
	v_www_csr_site_flow				security.security_pkg.T_SID_ID;
	v_www_csr_site_flow_admin		security.security_pkg.T_SID_ID;
	-- misc
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Groups');
	v_reg_users 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins 				:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- make sure we've got a Workflows node
	BEGIN
		v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Workflows');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Workflows', v_wf_ct_sid);
			-- grant registered users READ on workflow (inheritable)
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_wf_ct_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	-- Associate the dfault alert class (cms)
	BEGIN
		INSERT INTO customer_flow_alert_class (app_sid, flow_alert_class)
			VALUES (v_app_sid, 'cms');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- add workflow menu item
	v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
			'csr_flow_admin',
			'Workflows',
			'/csr/site/flow/admin/list.acds',
			12, null, v_admin_workflow_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- add workflow pseudo-roles menu item
	v_setup_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/setup');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_setup_menu,
			'csr_inv_type_setup',
			'Workflow pseudo-roles',
			'/csr/site/flow/admin/pseudoRoles.acds',
			null, null, v_setup_inv_type_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;


	/*** WEB RESOURCE ***/
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	-- /csr/site/flow
	BEGIN
		v_www_csr_site_flow := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/flow');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'flow', v_www_csr_site_flow);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_flow), -1, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	-- /csr/site/flow/admin
	BEGIN
		v_www_csr_site_flow_admin := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/flow/admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/flow');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site_flow, 'admin', v_www_csr_site_flow_admin);
			security.securableobject_pkg.ClearFlag(v_act_id, v_www_csr_site_flow_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_flow_admin));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_flow_admin), -1, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_admins, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

END;

/**
 *	Looks up a credit module and associates it with a client
 *
 *  @param in_lookup_key1	The lookup key for the module being added
 *  @param in_lookup_key2	The lookup key for another module to be enabled at the same time; usually NULL
 */
PROCEDURE InsertIntoOWLClientModule(
	in_lookup_key1 IN	VARCHAR2,
	in_lookup_key2 IN	VARCHAR2
)
AS
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tables
		  WHERE owner = 'OWL' AND table_name = 'CLIENT_MODULE')
	LOOP
		EXECUTE IMMEDIATE
			'INSERT INTO owl.CLIENT_MODULE (client_module_id, client_sid, credit_module_id, enabled, date_enabled)'||CHR(10)||
				'SELECT cms.item_id_seq.nextval, security.security_pkg.getApp, credit_module_id, 1, SYSDATE'||CHR(10)||
				  'FROM owl.credit_module'||CHR(10)||
				 'WHERE ((:k1 IS NOT NULL AND :k2 IS NULL AND lookup_key = :k1) OR (:k1 IS NOT NULL AND :k2 IS NOT NULL AND lookup_Key IN (:k1, :k2))) AND EXISTS ('||CHR(10)||
							'SELECT null FROM owl.owl_client WHERE client_sid = security.security_pkg.getApp'||CHR(10)||
					   ')'
		USING in_lookup_key1, in_lookup_key2, in_lookup_key1, in_lookup_key1, in_lookup_key2, in_lookup_key1, in_lookup_key2;
	END LOOP;
END;

PROCEDURE EnableChangeBranding
AS
	TYPE T_GROUPNAME_TAB        IS TABLE OF security_pkg.T_SO_NAME;

	v_act_id					security_pkg.T_ACT_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_www						security_pkg.T_SID_ID;
	v_www_client				security_pkg.T_SID_ID;
	v_www_admin_branding		security_pkg.T_SID_ID;

	v_menu						security_pkg.T_SID_ID;
	v_menu_changebranding		security_pkg.T_SID_ID;

	v_groups					security_pkg.T_SID_ID;
	v_new_group_sid             security_pkg.T_SID_ID;
	v_admins					security_pkg.T_SID_ID;
	v_demo_site_admins			security_pkg.T_SID_ID;
	v_super_admins				security_pkg.T_SID_ID;
	v_tab_branding_groups       T_GROUPNAME_TAB;
	v_current_branding_title	VARCHAR2(50);
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;

	v_groups := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');

	v_admins := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'Administrators');
	v_super_admins := securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');

	v_current_branding_title := branding_pkg.GetCurrentClientFolderName;

	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_client := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, v_current_branding_title);

	/* GROUPS */
	v_tab_branding_groups := T_GROUPNAME_TAB(
		'Demo Site Administrators'
	);

	FOR i IN v_tab_branding_groups.FIRST..v_tab_branding_groups.LAST
	LOOP
		BEGIN
			security.group_pkg.CreateGroupWithClass(
				v_act_id,
				v_groups,
				security.security_pkg.GROUP_TYPE_SECURITY,
				v_tab_branding_groups(i),
				security.class_pkg.getclassid('CSRUserGroup'),
				v_new_group_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_new_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups,
				v_tab_branding_groups(i));
		END;
		security.group_pkg.AddMember(v_act_id, v_super_admins, v_new_group_sid);
		IF i = 1 THEN
			v_demo_site_admins := v_new_group_sid;
		END IF;
	END LOOP;
	/* WEB RESOURCES */

	/* Allow demo-site administrators to add new client folders to the application root (non-inheritable) */
	security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_www),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_demo_site_admins,
		security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS + security.security_pkg.PERMISSION_WRITE);

	/* Give demo-site administrators write access to the current client root, for renaming if required */
	security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_www_client), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_demo_site_admins, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);

	/* Create the 'branding' resource under 'admin' */
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site/admin'), 'branding', v_www_admin_branding);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_admin_branding := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site/admin/branding');
	END;

	/* Give Demo Site Administrators inheritable standard read access to the new web resource */
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_admin_branding),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_demo_site_admins,
		security.security_pkg.PERMISSION_STANDARD_READ);

	/* MENU */
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup'),
			'csr_site_admin_branding_changebranding', 'Change site branding', '/csr/site/admin/branding/changeBranding.acds', 11, null, v_menu_changebranding);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_changebranding := security.securableobject_pkg.GetSidFromPath(v_act_id,
			security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup'), 'csr_site_admin_branding_changebranding');
	END;

	/* Give Demo Site Administators standard read access to the menu item */
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup')), -1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_demo_site_admins,
		security.security_pkg.PERMISSION_STANDARD_READ);

	/* Give Demo Site Administators standard read access to the menu item */
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_changebranding), -1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_demo_site_admins,
		security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act_id, v_menu_changebranding);

	/* CAPABILITIES */
	/* Change brandings */
	csr_data_pkg.enablecapability('Change brandings');

	/* Give Demo Site Administrators the 'Change brandings' capability */
	security.acl_pkg.AddACE(v_act_id,
		security.acl_pkg.GetDACLIDForSID(
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Change brandings')),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_demo_site_admins,
			security.security_pkg.PERMISSION_STANDARD_ALL);

	/* Lock brandings */
	csr_data_pkg.enablecapability('Lock brandings');

	/* Give Demo Site Administrators the 'Lock brandings' capability */
	security.acl_pkg.AddACE(v_act_id,
		security.acl_pkg.GetDACLIDForSID(
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Lock brandings')),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_demo_site_admins,
			security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Add the current branding if it doesn't exist.
	branding_pkg.AddBranding(v_current_branding_title, 'Original site branding (' || v_current_branding_title || ')', null);

	-- Allow it to be switched to
	branding_pkg.AllowBranding(v_current_branding_title);

	-- Add our default style, brandingtemplate, if it doesn't exist already
	branding_pkg.AddBranding('brandingtemplate', 'CRedit360 Default Style', 'Curtis Woodward, Ricky Dutton');

	-- Allow it to be switched to by default
	branding_pkg.AllowBranding('brandingtemplate');
END;

PROCEDURE EnableFrameworks
AS
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;

	--groups
	v_class_id				security.security_pkg.T_CLASS_ID;
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_superadmins_sid		security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_auditors_sid			security.security_pkg.T_SID_ID;
	v_reporters_sid			security.security_pkg.T_SID_ID;

	--indexes container
	v_indexes_root_sid		security.security_pkg.T_SID_ID;

	-- menu
	v_menu_frameworks		security.security_pkg.T_SID_ID;
	v_menu_data_entry		security.security_pkg.T_SID_ID;

	-- web resources
	v_www_sid 				security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_www_csr_site_text		security.security_pkg.T_SID_ID;

	TYPE GroupList IS VARRAY(6) OF security.security_pkg.T_SID_ID;
	v_group_list 			GroupList;
BEGIN
	-- log on
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.getACT;

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_auditors_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_superadmins_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, 0, 'csr/SuperAdmins');

	-- Reporters should exist but is missing on some older systems
	BEGIN
		v_reporters_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Reporters');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
			security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY,
				'Reporters', v_class_id, v_reporters_sid);
	END;

	--Create the indexes container
		BEGIN
		security.SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Indexes', v_indexes_root_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_indexes_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Indexes');
		END;

	-- Set permissions on Indexes
	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid)
	);
	-- Super Admins: All
				security.acl_pkg.AddACE(
					v_act_id,
					security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid),
					-1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_superadmins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE
				);
	-- Administrators: Read and Write (to save section/answer)
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE
		);
	-- Auditors: Read
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_indexes_root_sid),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_auditors_sid,
			security.security_pkg.PERMISSION_STANDARD_READ
		);

	GetSidOrNullFromPath(v_app_sid, 'Menu/data', v_menu_data_entry);
	GetSidOrNullFromPath(v_menu_data_entry, 'csr_text_admin_list', v_menu_frameworks);

	-- Ensure the top level names/desc/actions are all correct.
	IF v_menu_frameworks IS NOT NULL THEN
		security.securableobject_pkg.RenameSO(v_act_id, v_menu_frameworks, 'csr_text_admin_list');
		security.menu_pkg.SetMenuDescription(v_act_id, v_menu_frameworks, 'Frameworks');
		security.menu_pkg.SetMenuAction(v_act_id, v_menu_frameworks, '/csr/site/text/admin/list.acds');
	END IF;

	IF v_menu_frameworks IS NULL THEN
		-- Create Data entry -> Frameworks menu
	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			v_menu_data_entry,
			'csr_text_admin_list',
			'Frameworks',
			'/csr/site/text/admin/list.acds',
			7,
			null,
			v_menu_frameworks
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				 v_menu_frameworks := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_data_entry, 'csr_text_admin_list');
	END;
	END IF;

	-- Set permissions on frameworks menu
	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_menu_frameworks)
	);

	v_group_list := GroupList(v_admins_sid, v_auditors_sid);
	FOR i IN 1..v_group_list.COUNT
	LOOP
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_menu_frameworks),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_group_list(i),
			security.security_pkg.PERMISSION_STANDARD_READ
		);
	END LOOP;

	-- Direct submenu links to individual frameworks are no longer required.
	-- Can't rely on the appsid being set on these, so check the parent is the frameworks menu.
	FOR r IN (
		SELECT m.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so on so.sid_id=m.sid_id
		 WHERE m.action LIKE '%text/overview/overview.acds?module%'
		   AND so.parent_sid_id = v_menu_frameworks
	)
	LOOP
		security.securableobject_pkg.DeleteSO(v_act_id, r.sid_id);
	END LOOP;

	/*** WEB RESOURCES ***/
	-- add permissions on pre-created web-resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');

	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'text', v_www_csr_site_text);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_csr_site_text := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'text');
	END;

	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_csr_site_text)
	);
	FOR i IN 1..v_group_list.COUNT
	LOOP
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_text), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
					v_group_list(i), security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;

	-- create reports folder for publishing framework to doclib
	CreateDocLibReportsFolder;

	-- section status
	CreateSectionStatus(v_act_id, v_app_sid);
END;

PROCEDURE EnableReportingIndicators
AS
	v_act_id						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_rep_ind_root_sid				security_pkg.T_SID_ID;
BEGIN
	/*** INDICATORS ***/
	-- create as a group so we can add members (for permissions)
	security.group_pkg.CreateGroupWithClass(
		v_act_id,
		v_app_sid,
		security.security_pkg.GROUP_TYPE_SECURITY,
		'Reporting Indicators',
		security.security_pkg.SO_CONTAINER,
		v_rep_ind_root_sid);

	-- add object to the DACL (the container is a group, so it has permissions on itself)
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_rep_ind_root_sid),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_rep_ind_root_sid,
		security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- make Indicators and Regions members of themselves
	security.group_pkg.AddMember(v_act_id, v_rep_ind_root_sid, v_rep_ind_root_sid);

	INSERT INTO ind (
		ind_sid, parent_sid, name, app_sid, period_set_id, period_interval_id
	) VALUES (
		v_rep_ind_root_sid, v_app_sid, 'Reporting Indicators', v_app_sid, 1, 1
	);
	INSERT INTO ind_description (ind_sid, lang, description)
		SELECT v_rep_ind_root_sid, cl.lang, 'Reporting Indicators'
		  FROM v$customer_lang cl;

	UPDATE customer
	   SET reporting_ind_root_sid = v_rep_ind_root_sid
	 WHERE app_sid = v_app_sid;
END;

PROCEDURE EnableAutomatedExportImport
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;
	-- container
	v_exportimport_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_imports_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_exports_container_sid 	security.security_pkg.T_SID_ID;
	-- web resources
	v_www_root 						security.security_pkg.T_SID_ID;
	v_www_csr_site 					security.security_pkg.T_SID_ID;
	v_www_csr_site_automated		security.security_pkg.T_SID_ID;
	--Menu
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_admin_automated_menu			security.security_pkg.T_SID_ID;
	--Alert id
	v_importcomplete_alert_type_id	NUMBER;
	v_exportcomplete_alert_type_id	NUMBER;
BEGIN

	--Variables
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Groups');
	v_admins 		:= security.securableobject_pkg.GetSIDFromPath(v_act_id, v_groups_sid, 'Administrators');

	v_importcomplete_alert_type_id := csr_data_pkg.ALERT_AUTO_IMPORT_COMPLETED;
	v_exportcomplete_alert_type_id := csr_data_pkg.ALERT_AUTO_EXPORT_COMPLETED;

	--Create the container for the SOs
	--I don't add any ACLs as the administrators group should inherit down from root node
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_app_sid,
			security.security_pkg.SO_CONTAINER,
			'AutomatedExportImport',
			v_exportimport_container_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExportImport');
	END;
	BEGIN
	security.securableobject_pkg.CreateSO(v_act_id,
		v_exportimport_container_sid,
		security.security_pkg.SO_CONTAINER,
		'AutomatedImports',
		v_auto_imports_container_sid
	);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_auto_imports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_exportimport_container_sid, 'AutomatedImports');
	END;
	BEGIN
	security.securableobject_pkg.CreateSO(v_act_id,
		v_exportimport_container_sid,
		security.security_pkg.SO_CONTAINER,
		'AutomatedExports',
		v_auto_exports_container_sid
	);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_auto_exports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_exportimport_container_sid, 'AutomatedExports');
	END;

	--Create the web resources
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	BEGIN
		v_www_csr_site_automated := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/automatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'automatedExportImport', v_www_csr_site_automated);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_automated), -1, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_admins, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	--Create the menu item
	v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
			'csr_site_cmsimp_impinstances',
			'Scheduled exports and imports',
			'/csr/site/automatedExportImport/admin/list.acds',
			12, null, v_admin_automated_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	--Add the capability - will inherit from the container (administrators)
	csr_data_pkg.enablecapability('Manually import automated import instances');
	csr_data_pkg.enablecapability('Can run additional automated import instances');
	csr_data_pkg.enablecapability('Can run additional automated export instances');
	csr_data_pkg.enablecapability('Can preview automated exports');

	--Create the alerts
	BEGIN
			INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (v_app_sid, customer_alert_type_id_seq.nextval, v_importcomplete_alert_type_id);

			INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT v_app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
			  FROM alert_frame af
			  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = v_app_sid
			   AND cat.std_alert_type_id = v_importcomplete_alert_type_id
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;

			INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT v_app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM default_alert_template_body d
			  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id = v_importcomplete_alert_type_id
			   AND d.lang='en'
			   AND t.application_sid = v_app_sid
			   AND cat.app_sid = v_app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
			INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (v_app_sid, customer_alert_type_id_seq.nextval, v_exportcomplete_alert_type_id);

			INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT v_app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
			  FROM alert_frame af
			  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = v_app_sid
			   AND cat.std_alert_type_id = v_exportcomplete_alert_type_id
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;

			INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT v_app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM default_alert_template_body d
			  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id = v_exportcomplete_alert_type_id
			   AND d.lang='en'
			   AND t.application_sid = v_app_sid
			   AND cat.app_sid = v_app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

END;

FUNCTION IsDashboardsEnabled
RETURN NUMBER
AS
	v_sid_id	security.security_pkg.T_SID_ID;
BEGIN
	v_sid_id := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('security', 'act'), SYS_CONTEXT('security', 'app'), 'Dashboards');

	RETURN 1;

EXCEPTION
	WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		RETURN 0;
END;

PROCEDURE EnableApprovalDashboards
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_scenarios_sid					security.security_pkg.T_SID_ID;
	v_dashboards_container_sid		security.security_pkg.T_SID_ID;
	v_merged_scenario_sid			security.security_pkg.T_SID_ID;
	v_unmerged_scenario_sid			security.security_pkg.T_SID_ID;
	--Menu
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_admin_approvallist_menu		security.security_pkg.T_SID_ID;
BEGIN

	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- Must have scenarios enabled
	BEGIN
		v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Scenarios');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Scenarios object not found -- run EnableScenarios.sql first');
	END;

	-- Must have scrag++ for both merged and unmerged
	SELECT MERGED_SCENARIO_RUN_SID, UNMERGED_SCENARIO_RUN_SID
	  INTO v_merged_scenario_sid, v_unmerged_scenario_sid
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_merged_scenario_sid IS NULL OR v_unmerged_scenario_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged and/or unmerged scenario data are NOT on scrag++. Approval dashboards requires Scrag++.');
	END IF;

	-- Create the container for the dashboards
	-- Inherit the ACLs from the parent (ie site root) node
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_app_sid,
			security.security_pkg.SO_CONTAINER,
			'Dashboards',
			v_dashboards_container_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_dashboards_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Dashboards');
	END;

	-- Shouldn't need web resources, as it's all within the "portal" folder.

	-- Menus
	--Create the menu item
	v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
			'csr_portal_approvallist',
			'Approval dashboards',
			'/csr/site/portal/approvalList.acds',
			12, null, v_admin_approvallist_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- They already have it
			NULL;
	END;

	FOR r IN (
		SELECT portlet_id
		  FROM portlet
		 WHERE type IN ('Credit360.Portlets.MyApprovalDashboards', 'Credit360.Portlets.ApprovalMatrix', 'Credit360.Portlets.ApprovalChart', 'Credit360.Portlets.ApprovalNote')
	)
	LOOP
		portlet_pkg.EnablePortletForCustomer(r.portlet_Id);
	END LOOP;

	-- Workflows
	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class)
		VALUES ('approvaldashboard');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnableDelegationSummary
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	-- enable capability
	csr_data_pkg.enablecapability('Can export delegation summary');
	-- grant permission to registered users
	security.acl_pkg.AddACE(v_act_id,
		security.acl_pkg.GetDACLIDForSID(
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Can export delegation summary')),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);
END;

PROCEDURE EnableMultipleDashboards
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_dashboards_container_sid		security.security_pkg.T_SID_ID;
	v_admins_sid 					security.security_pkg.T_SID_ID;
	--Menu
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_admin_portallist_menu			security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	-- Create the container for the dashboards
	-- Inherit the ACLs from the parent (ie site root) node
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_app_sid,
			security.security_pkg.SO_CONTAINER,
			'PortalDashboards',
			v_dashboards_container_sid
		);

		-- Set the permissions manually
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_dashboards_container_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			security.security_pkg.PERMISSION_STANDARD_ALL);
		security.acl_pkg.PropogateACEs(v_act_id, v_dashboards_container_sid);

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_dashboards_container_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL);
		security.acl_pkg.PropogateACEs(v_act_id, v_dashboards_container_sid);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_dashboards_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'PortalDashboards');
	END;

	-- Add menu for portal list
	v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
			'csr_portal_portallist',
			'Portal dashboards',
			'/csr/site/portal/portalList.acds',
			12, null, v_admin_portallist_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- They already have it
			NULL;
	END;

END;

PROCEDURE EnableDelegationReports
AS
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	v_menu_admin					security.security_pkg.T_SID_ID;
	v_menu1							security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	-- add deleg plan menu items
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
			'csr_delegation_reports',
			'Delegation reports',
			'/csr/site/delegation/reports/reports.acds',
			10, null, v_menu1);

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- this grants admins access automatically
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportDelegationBlockers');
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportSubmissionPromptness');
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetCoverage');
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetDelegationSummaryReport');
	sqlreport_pkg.EnableReport('csr.csr_data_pkg.GetValueChangeReport');
END;

PROCEDURE EnableDelegationStatusReports
AS
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_container_sid			security.security_pkg.T_SID_ID;
	v_menu_admin			security.security_pkg.T_SID_ID;
	v_menu_deleg_status		security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid				security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
BEGIN
	-- read admin group
	v_admins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	-- enable deleg status reports
	BEGIN
		v_container_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Delegation Reports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Delegation Reports', v_container_sid);

			-- grant admins full permissions on the container
			security.acl_pkg.AddACE(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_container_sid),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL
			);
	END;

	-- add deleg plan menu items
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
			'status_overview',
			'Delegation status overview',
			'/csr/site/delegation/manage/statusOverview.acds',
			10, null, v_menu_deleg_status);

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_deleg_status), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE EnableFactorStartMonth(
	in_enable					IN	NUMBER
)
AS
	v_app_sid					security.security_pkg.T_SID_ID;
	v_enable					NUMBER(1);
	v_is_enabled				NUMBER(1);
	v_factor_start_month		NUMBER(2);
BEGIN
	v_app_sid := security.security_pkg.getApp;

	SELECT adj_factorset_startmonth
	  INTO v_is_enabled
	  FROM customer
	 WHERE app_sid=v_app_sid;

	v_enable := in_enable;
	IF v_enable > 1 THEN
		v_enable := 1;
	END IF;

	IF v_is_enabled = v_enable THEN
		RETURN;
	END IF;

	UPDATE customer
	   SET adj_factorset_startmonth = v_enable
	 WHERE app_sid = v_app_sid;

	SELECT DECODE(v_enable, 0, 1, 1, start_month) factor_start_month
	  INTO v_factor_start_month
	  FROM customer
	 WHERE app_sid = v_app_sid;

	UPDATE factor
	   SET end_dtm = CASE
						WHEN end_dtm IS NULL THEN NULL
						ELSE ADD_MONTHS(TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(end_dtm, start_dtm))
					  END,
		   start_dtm = TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(start_dtm,'YYYY'), 'MMYYYY')
	 WHERE app_sid = v_app_sid
	   AND std_factor_id IS NOT NULL
	   AND custom_factor_id IS NULL;

	util_script_pkg.RecalcOne;
END;

PROCEDURE EnableAuditLogReports
AS
	v_groups_sid					security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;
	v_menu_admin					security_pkg.T_SID_ID;
	v_menu1							security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_site_audit			security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
	v_act							security_pkg.T_ACT_ID;
	v_app							security_pkg.T_SID_ID;
BEGIN

	-- log on
	v_app := SYS_CONTEXT('security','app');
	v_act := SYS_CONTEXT('security','act');

	-- read groups
	v_groups_sid 	:= securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid 	:= securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');

	-- add deleg plan menu items
	v_menu_admin := securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu_admin,
			'csr_auditlog_reports',
			'Audit log reports',
			'/csr/site/auditlog/reports.acds',
			10, null, v_menu1);

		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_READ);

	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;


	/*** WEB RESOURCE ***/
	-- add permissions on pre-created web-resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'csr/site');
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_www_csr_site, 'auditlog', v_www_csr_site_audit);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_csr_site_audit := security.securableobject_pkg.GetSidFromPath(v_act, v_www_csr_site, 'auditlog');
	END;
	-- add administrators to web resource
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_audit), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	/*** CAPABILITY ***/
	csr_data_pkg.enablecapability('Can generate audit log reports');

	/*** REPORT ***/
	sqlreport_pkg.EnableReport('csr.csr_data_pkg.GenerateAuditReport');
END;

PROCEDURE EnableDashboardAuditLogReports
AS
BEGIN

	EnableAuditLogReports;

	/*** REPORT ***/
	sqlreport_pkg.EnableReport('csr.portlet_pkg.DashboardAuditLogReport');
END;

PROCEDURE EnableAlert(
	in_alert_id 			IN NUMBER
)
AS
	v_alert_frame_id			NUMBER;
	v_customer_alert_type_id	NUMBER;
BEGIN
	-- get alert frame
	BEGIN
		SELECT MIN(alert_frame_id)
		  INTO v_alert_frame_id
		  FROM alert_frame
		 WHERE name = 'Default';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			alert_pkg.CreateFrame('Default', v_alert_frame_id);
	END;

	-- create or retrieve alert
	BEGIN
		INSERT INTO customer_alert_type (customer_alert_type_id, std_alert_type_id)
			 VALUES (customer_alert_type_id_seq.nextval, in_alert_id)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- The data change request alert is already enabled.
			SELECT customer_alert_type_id INTO v_customer_alert_type_id
			  FROM customer_alert_type
			 WHERE std_alert_type_id = in_alert_id;
	END;

	-- create alert template
	BEGIN
		INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type) VALUES (v_customer_alert_type_id, v_alert_frame_id, 'manual');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- Customer Alert Template already created.
			NULL;
	END;

	-- add templates for each lang on site
	INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
	SELECT v_customer_alert_type_id, ts.lang, dt.subject, dt.body_html, dt.item_html
	  FROM default_alert_template_body dt
	  JOIN aspen2.translation_set ts
		ON ts.lang = dt.lang
	   AND dt.std_alert_type_id = in_alert_id
	  LEFT JOIN alert_template_body atb
		ON atb.lang = dt.lang
	   AND atb.customer_alert_type_id = v_customer_alert_type_id
	   AND atb.app_sid = ts.application_sid
	 WHERE ts.application_sid = security.security_pkg.getapp
	   AND ts.hidden = 0
	   AND atb.body_html IS NULL;
END;

PROCEDURE EnableDataChangeRequests
AS
BEGIN
	-- capability
	csr_data_pkg.enablecapability('Allow users to raise data change requests');

	-- enable alerts
	EnableAlert(csr_data_pkg.ALERT_SHEET_CHANGE_REQ);
	EnableAlert(csr_data_pkg.ALERT_SHEET_CHANGE_REQ_REJ);
	EnableAlert(csr_data_pkg.ALERT_SHEET_CHANGE_REQ_APPR);
END;

PROCEDURE EnablePropertyDashboards
AS
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;

	v_dashboards_sid		security.SECURITY_PKG.T_SID_ID;

	v_property_menu_sid		security.security_pkg.T_SID_ID;
	v_property_manager_sid	security.security_pkg.T_SID_ID;

	v_www_sid				security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_www_csr_site_dash		security.security_pkg.T_SID_ID;
	v_www_csr_site_dash_md	security.security_pkg.T_SID_ID;

	v_tmp_sid			    security.security_pkg.T_SID_ID;
BEGIN
	v_act_id                := security.security_pkg.GetAct;
	v_app_sid               := security.security_pkg.GetApp;

	v_property_manager_sid  := role_pkg.GetRoleIDByKey('PROPERTY_MANAGER');

	IF v_property_manager_sid IS NULL THEN
		v_property_manager_sid 	:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
	END IF;

	BEGIN
		v_property_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/csr_properties_menu');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_property_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/gp_properties');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					v_tmp_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
					security.menu_pkg.CreateMenu(v_act_id, v_tmp_sid, 'csr_properties_benchmarking', 'Benchmarking', '/csr/site/dashboard/metricDashboard/benchmarkingDashboard.acds', 0, null, v_property_menu_sid);
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			END;
	END;

	-- create 'Dashboards' container
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Dashboards', v_dashboards_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_dashboards_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
	END;

	-- create 'dashboard' web resource
	BEGIN
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
		v_www_csr_site_dash := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'dashboard');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'dashboard', v_www_csr_site_dash);
	END;

	-- create 'metricDashboard' web resource
	BEGIN
		v_www_csr_site_dash_md := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_dash, 'metricDashboard');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_dash, 'metricDashboard', v_www_csr_site_dash_md);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_dash_md), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	-- add 'Benchmarking' menu item
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_property_menu_sid, 'csr_properties_benchmarking', 'Benchmarking', '/csr/site/dashboard/metricDashboard/benchmarkingDashboard.acds', 0, null, v_tmp_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_tmp_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
	END;

	-- add 'Performance' menu item
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_property_menu_sid, 'csr_properties_performance', 'Performance', '/csr/site/dashboard/metricDashboard/metricDashboard.acds', 0, null, v_tmp_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_tmp_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
	END;

	-- create 'Benchmarking' dashboard
	BEGIN
		benchmarking_dashboard_pkg.SaveDashboard(
			in_dashboard_sid        => NULL,
			in_name                 => 'Benchmarking',
			in_start_dtm            => TRUNC(SYSDATE,'YEAR'),
			in_end_dtm              => NULL,
			in_period_set_id        => 1,
			in_period_interval_id   => 4,
			in_lookup_key           => 'DEFAULT_BENCHMARKING_DASHBOARD',
			out_dashboard_sid       => v_tmp_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
	END;

	-- create 'Performance' dashboard
	BEGIN
		metric_dashboard_pkg.SaveDashboard(
			in_dashboard_sid        => NULL,
			in_name                 => 'Performance',
			in_start_dtm            => TRUNC(SYSDATE,'YEAR'),
			in_end_dtm              => NULL,
			in_period_set_id        => 1,
			in_period_interval_id   => 4,
			in_lookup_key           => 'DEFAULT_METRIC_DASHBOARD',
			out_dashboard_sid       => v_tmp_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
	END;
END;


PROCEDURE EnableChainCountryRisk
AS
	v_act_id					security.security_pkg.T_ACT_ID := security_pkg.getAct;
	v_app_sid					security.security_pkg.T_SID_ID := security_pkg.getApp;
	v_menu_crc					security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'chain_country_risk_levels', 'Country risk levels', '/csr/site/chain/admin/countryrisklevel.acds', 99, null, v_menu_crc);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	UPDATE chain.customer_options
	   SET country_risk_enabled = 1
	 WHERE app_sid = security.security_pkg.GetApp;
END;

FUNCTION IsEnergyStarEnabled
RETURN NUMBER
AS
	v_sid_id	security.security_pkg.T_SID_ID;
BEGIN
	v_sid_id := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('security', 'act'), SYS_CONTEXT('security', 'app'), 'EnergyStar');
	RETURN 1;

EXCEPTION
	WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		RETURN 0;
END;

PROCEDURE EnableEnergyStar
AS
	v_act_id					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;

	v_account_id				est_account_global.est_account_id%TYPE;
	v_account_sid				security_pkg.T_SID_ID;
	v_energy_star_sid			security_pkg.T_SID_ID;

	v_property_admin_menu		security_pkg.T_SID_ID;
	v_admins_sid				security_pkg.T_SID_ID;
	v_menu_energy_star			security_pkg.T_SID_ID;

	v_enabled					NUMBER;
BEGIN
	-- Check property module is enabled
	BEGIN
		SELECT app_sid
		  INTO v_enabled
		  FROM property_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Please enable the Property Module first');
	END;

	-- Check metring is enabled
	SELECT metering_enabled
	  INTO v_enabled
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	IF v_enabled = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Please enable "Metering - base" first.');
	END IF;

	csr_data_pkg.enablecapability('Remap Energy Star property');

	BEGIN
		INSERT INTO app_lock (app_sid, lock_type)
			 VALUES (v_app_sid, csr_data_pkg.LOCK_TYPE_ENERGY_STAR);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'EnergyStar', v_energy_star_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_energy_star_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'EnergyStar');
	END;

	SELECT MIN(est_account_id)
	  INTO v_account_id
	  FROM est_account_global;
	  
	IF v_account_id IS NULL THEN
		INSERT INTO est_account_global (est_account_id)
			 VALUES (est_account_id_seq.NEXTVAL)
		  RETURNING est_account_id INTO v_account_id;
	END IF;

	energy_star_pkg.MapAccount(
		v_account_id,
		v_account_sid
	);

	BEGIN
		INSERT INTO est_options
			(default_account_sid, auto_create_prop_type, auto_create_space_type, show_compat_icons)
		VALUES (v_account_sid, 1, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Set sensible polling intervals
	UPDATE est_account
	   SET share_job_interval = 120,
		   building_job_interval = 1440,
		   meter_job_interval = 1440
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = v_account_sid;

	-- add menu item
	v_property_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin/csr_property_admin_menu');
	v_admins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			v_property_admin_menu,
			'csr_energy_star',
			'Energy Star',
			'/csr/site/property/admin/energyStar/menu.acds',
			-1, null, v_menu_energy_star);

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_energy_star), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE SetDisabledChartFeatureFlags(
	in_data_explorer_show_ranking	IN	customer.data_explorer_show_ranking%TYPE,
	in_data_explorer_show_markers	IN	customer.data_explorer_show_markers%TYPE,
	in_data_explorer_show_trends	IN	customer.data_explorer_show_trends%TYPE,
	in_data_explorer_show_scatter	IN	customer.data_explorer_show_scatter%TYPE,
	in_data_explorer_show_radar		IN	customer.data_explorer_show_radar%TYPE,
	in_data_explorer_show_gauge		IN	customer.data_explorer_show_gauge%TYPE,
	in_data_explorer_show_wfall		IN	customer.data_explorer_show_waterfall%TYPE)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE customer
	   SET data_explorer_show_ranking = in_data_explorer_show_ranking,
		   data_explorer_show_markers = in_data_explorer_show_markers,
		   data_explorer_show_trends = in_data_explorer_show_trends,
		   data_explorer_show_scatter = in_data_explorer_show_scatter,
		   data_explorer_show_radar = in_data_explorer_show_radar,
		   data_explorer_show_gauge = in_data_explorer_show_gauge,
		   data_explorer_show_waterfall = in_data_explorer_show_wfall
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

-- TODO: Move to security?
PROCEDURE GetSidOrNullFromPath(
	in_parent_sid 	IN security.security_pkg.T_SID_ID,
	in_path 		IN VARCHAR2,
	out_sid_id 		OUT security.security_pkg.T_SID_ID)
AS
	v_act_sid		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN
	BEGIN
		out_sid_id := security.securableobject_pkg.GetSidFromPath(v_act_sid, in_parent_sid, in_path);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
END GetSidOrNullFromPath;

PROCEDURE EnableOwlSupport
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_class_id					security.security_pkg.T_CLASS_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_superadmins_sid			security.security_pkg.T_SID_ID;
	v_owl_support_sid			security.security_pkg.T_SID_ID;

	-- Menus
	v_support_menu				security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;

	-- Web resources
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_owl					security.security_pkg.T_SID_ID;
	v_www_support				security.security_pkg.T_SID_ID;
	v_www_folder				security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	-- read groups
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');

	BEGIN
		v_owl_support_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_groups_sid, 'OwlSupport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('OwlSupport group not found. Creating group... ');

			security.group_pkg.CreateGroupWithClass(
				security.security_pkg.getACT,
				v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'OwlSupport',
				security.class_pkg.GetClassId('CSRUserGroup'),
				v_owl_support_sid
			);

			security.group_pkg.AddMember(
				v_act_id,
				v_superadmins_sid,
				v_owl_support_sid
			);

			security.acl_pkg.DeleteAllACEs(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_owl_support_sid)
			);

			security.securableObject_pkg.ClearFlag(
				v_act_id,
				v_owl_support_sid,
				security.security_pkg.SOFLAG_INHERIT_DACL
			);

			security.acl_pkg.AddACE(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_owl_support_sid),
				-1,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_superadmins_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL
			);
	END;

	-- Create support menu items
	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Menu'),
			'support',
			'Support',
			'/owl/support/overview.acds',
			-1,
			null,
			v_support_menu
		);

		-- don't inherit
		security.securableObject_pkg.ClearFlag(
			v_act_id,
			v_support_menu,
			security.security_pkg.SOFLAG_INHERIT_DACL
		);

		-- Set permissions on main support menu
		security.acl_pkg.DeleteAllACEs(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_support_menu)
		);

		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_support_menu),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_owl_support_sid,
			security.security_pkg.PERMISSION_STANDARD_READ
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			DBMS_OUTPUT.PUT_LINE('Support menu already exists');

			v_support_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu/support');
	END;

	-- sub menu items
	BEGIN
		-- Leave it to inherit
		security.menu_pkg.CreateMenu(
			v_act_id,
			v_support_menu,
			'owl_support_overview',
			'Overview',
			'/owl/support/overview.acds',
			1,
			null,
			v_menu
		);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			DBMS_OUTPUT.PUT_LINE('Support overview already exists');
	END;

	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			v_support_menu,
			'owl_support_summary',
			'Account information',
			'/owl/support/summary.acds',
			2,
			null,
			v_menu
		);

		-- don't inherit
		security.securableObject_pkg.ClearFlag(
			v_act_id,
			v_menu,
			security.security_pkg.SOFLAG_INHERIT_DACL
		);

		-- Set permissions
		security.acl_pkg.DeleteAllACEs(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_menu)
		);

		-- Add
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_menu),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_owl_support_sid,
			security.security_pkg.PERMISSION_STANDARD_READ
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			DBMS_OUTPUT.PUT_LINE('Account information menu already exists');
	END;

	-- Web resources and permissions
	-- add permissions on pre-created web-resources
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	-- Not sure where we are going to keep location /owl/support, /csr/support or /cr360/support
	-- Create parent "owl" for now
	BEGIN
		security.Web_Pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'owl', v_www_owl);

		-- don't inherit
		security.securableObject_pkg.ClearFlag(
			v_act_id,
			v_www_owl,
			security.security_pkg.SOFLAG_INHERIT_DACL
		);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_owl := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'owl');
	END;

	-- Main Support folder
	BEGIN
		security.Web_Pkg.CreateResource(v_act_id, v_www_root, v_www_owl, 'support', v_www_support);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_support := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_owl, 'support');
	END;

	-- don't inherit
	security.securableObject_pkg.ClearFlag(
		v_act_id,
		v_www_support,
		security.security_pkg.SOFLAG_INHERIT_DACL
	);

	-- Set permissions on main client connect webresource
	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_support)
	);

	-- Give access to main group
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_support),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_owl_support_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Account information page
	BEGIN
		security.Web_Pkg.CreateResource(v_act_id, v_www_root, v_www_support, 'summary.acds', v_www_folder);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_folder := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_support, 'summary.acds');
	END;

	-- Don't inherit
	security.securableObject_pkg.ClearFlag(
		v_act_id,
		v_www_folder,
		security.security_pkg.SOFLAG_INHERIT_DACL
	);

	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_folder)
	);

	-- Give access to main group
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_folder),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_owl_support_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Case list page
	BEGIN
		security.Web_Pkg.CreateResource(v_act_id, v_www_root, v_www_support, 'caselist.acds', v_www_folder);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_folder := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_support, 'caselist.acds');
	END;

	-- Don't inherit
	security.securableObject_pkg.ClearFlag(
		v_act_id,
		v_www_folder,
		security.security_pkg.SOFLAG_INHERIT_DACL
	);

	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_folder)
	);

	-- Give access to main group
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_folder),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_owl_support_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Propogate after creating children (Phase two will include all registered users on this propogation)
	security.acl_pkg.PropogateACEs(
		v_act_id,
		v_www_support
	);

END;

PROCEDURE EnableCompanySelfReg
AS
BEGIN
	chain.setup_pkg.EnableCompanySelfReg;
END;







--- METERING ---

PROCEDURE INTERNAL_AddAceForCapability (
	in_capability_name			IN	VARCHAR2,
	in_admins_sid				IN	security.security_pkg.T_SID_ID
)
AS
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_count					NUMBER;
BEGIN
	v_capability_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, '/Capabilities/'||in_capability_name);

	SELECT COUNT(*)
	  INTO v_count
	  FROM security.ACL
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_capability_sid)
	   AND sid_id = in_admins_sid
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;

	IF v_count = 0 THEN
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_capability_sid), security.security_pkg.ACL_INDEX_LAST,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, in_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;
END;

PROCEDURE EnableMeteringBase
AS
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	v_auditors_sid					security.security_pkg.T_SID_ID;

	-- roles
	v_meter_admin_role_sid			security.security_pkg.T_SID_ID;
	v_meter_reader_role_sid			security.security_pkg.T_SID_ID;

	-- menu
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_menu_metering					security.security_pkg.T_SID_ID;
	v_menu_admin					security.security_pkg.T_SID_ID;
	v_menu_leaf						security.security_pkg.T_SID_ID;

	-- web resources
	v_www_meter 					security.security_pkg.T_SID_ID;

	-- plugins
	v_plugin_id						plugin.plugin_id%TYPE;

	-- meter input ids
	v_meter_input_id_consumption	meter_input.meter_input_id%TYPE;
	v_meter_input_id_cost 			meter_input.meter_input_id%TYPE;

	v_count							NUMBER;
BEGIN

	InsertIntoOWLClientModule('METERING', null);

	BEGIN
		INSERT INTO metering_options (analytics_months, analytics_current_month, period_set_id, period_interval_id)
		VALUES (NULL, 0, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Groups');
	v_auditors_sid 			:= security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_groups_sid, 'Auditors');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_groups_sid, 'Administrators');

	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter administrator', v_meter_admin_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_admin_role_sid;

	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter reader', v_meter_reader_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_reader_role_sid;

	-- Get the menu root
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu');
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/admin');

	-- Create Metering root menu item
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_sid, 'metering', 'Metering', '/csr/site/meter/meterList.acds', 3, null, v_menu_metering);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_metering := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/metering');
	END;

	-- Admins (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_metering), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Metering admins (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_metering), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_meter_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Auditors (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_metering), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_metering), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'csr_meter', 'Meters', '/csr/site/meter/meterList.acds', 1, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'csr_meter');
	END;

	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Import readings
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'import_meter_readings', 'Import readings', '/csr/site/meter/import/import.acds', 3, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'import_meter_readings');
	END;

	-- Propogate menu ACEs (meter menu)
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_metering);

	-- Admin menu
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_admin, 'csr_meter_admin', 'Metering admin', '/csr/site/meter/admin/menu.acds', 20, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Propogate menu ACEs (admin menu)
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_admin);

	--
	-- Web resource permissions (no granularity)
	BEGIN
		v_www_meter := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'wwwroot/csr/site/meter');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.getACT,
				security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'wwwroot'),
				security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'wwwroot/csr/site'),
				'meter', v_www_meter
			);

		-- Propogate web resource ACEs (site)
		security.acl_pkg.PropogateACEs(security.security_pkg.GetACT,
			security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'wwwroot/csr/site')
		);
	END;

	-- Admins (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_www_meter), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Metering admins (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_www_meter), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_meter_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Auditors (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_www_meter), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_auditors_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Meter reader (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_www_meter), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Propogate web resource ACEs
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_www_meter);

	--
	-- ADD CAPABILITIES
	csr_data_pkg.enablecapability('View all meters', 1);
	INTERNAL_AddAceForCapability('View all meters', v_admins_sid);
	INTERNAL_AddAceForCapability('View all meters', v_meter_admin_role_sid);

	csr_data_pkg.EnableCapability('Edit Region Docs', 1);
	INTERNAL_AddAceForCapability('Edit Region Docs', v_admins_sid);

	/*
	-- Not sure we need this (base data defaults to allow)
	csr_data_pkg.enablecapability('Manage meter readings', 1);
	INTERNAL_AddAceForCapability('Manage meter readings', v_admins_sid);
	INTERNAL_AddAceForCapability('Manage meter readings', v_meter_admin_role_sid);
	INTERNAL_AddAceForCapability('Manage meter readings', v_meter_reader_role_sid);
	*/

	--
	-- BASE DATA

	-- Add metering region type to this app
	BEGIN
		INSERT INTO customer_region_type (app_sid, region_type)
		VALUES (security.security_pkg.GetAPP, 1); -- Meter
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	BEGIN
		INSERT INTO customer_region_type (app_sid, region_type)
		VALUES (security.security_pkg.GetAPP, 5); -- Rate
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	-- Add meter source types for this app
	BEGIN
		INSERT INTO meter_source_type (app_sid, meter_source_type_id, name, description,
			arbitrary_period, add_invoice_data, show_in_meter_list)
		VALUES (security.security_pkg.GetAPP, 1, 'point', 'Point in time', 0, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;
	BEGIN
		INSERT INTO meter_source_type (app_sid, meter_source_type_id, name, description,
			arbitrary_period, add_invoice_data, show_in_meter_list)
		VALUES (security.security_pkg.GetAPP, 2, 'period', 'Arbitrary period', 1, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	-- System period bucket
	DECLARE
		v_count		NUMBER;
	BEGIN
		SELECT COUNT(meter_bucket_id)
		  INTO v_count
		  FROM meter_bucket
		 WHERE description = 'Monthly'
		   AND is_export_period = 1;

		IF v_count = 0 THEN
			INSERT INTO meter_bucket (app_sid, meter_bucket_id, description, is_export_period, period_set_id, period_interval_id)
			VALUES(security_pkg.GetAPP, meter_bucket_id_seq.NEXTVAL, 'Monthly', 1, 1, 1);
		END IF;
	END;

	-- Daily bucket
	DECLARE
		v_count		NUMBER;
	BEGIN
		SELECT COUNT(meter_bucket_id)
		  INTO v_count
		  FROM meter_bucket
		 WHERE description = 'Daily'
		   AND duration = 24
		   AND is_hours = 1;

		IF v_count = 0 THEN
			INSERT INTO meter_bucket (app_sid, meter_bucket_id, description, duration, is_hours)
			VALUES(security_pkg.GetAPP, meter_bucket_id_seq.NEXTVAL, 'Daily', 24, 1);
		END IF;
	END;

	-- Input types
	BEGIN
		INSERT INTO meter_input (app_sid, meter_input_id, label, lookup_key, is_consumption_based)
		VALUES (security_pkg.GetAPP, 1, 'Consumption', 'CONSUMPTION', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	BEGIN
		INSERT INTO meter_input (app_sid, meter_input_id, label, lookup_key, is_consumption_based)
		VALUES (security_pkg.GetAPP, 2, 'Cost','COST', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	SELECT meter_input_id
	  INTO v_meter_input_id_consumption
	  FROM meter_input
	 WHERE lookup_key = 'CONSUMPTION';

	SELECT meter_input_id
	  INTO v_meter_input_id_cost
	  FROM meter_input
	 WHERE lookup_key = 'COST';

	-- Input -> aggregator type mappings (aggregator types are global)
	BEGIN
		INSERT INTO meter_input_aggregator(app_sid, meter_input_id, aggregator, is_mandatory)
		VALUES(security_pkg.GetAPP, v_meter_input_id_consumption, 'SUM', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	BEGIN
		INSERT INTO meter_input_aggregator(app_sid, meter_input_id, aggregator)
		VALUES(security_pkg.GetAPP, v_meter_input_id_cost, 'SUM');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	-- Add data priority levels (auto-patch at level 1 added when auto patching enabled)
	BEGIN
		INSERT INTO meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (security.security_pkg.GetAPP, 0, 'Auto patch', 'AUTO', 0, 0, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (security.security_pkg.GetAPP, 1, 'Estimate', 'ESTIMATE', 1, 0, 0, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (security_pkg.GetAPP, 2, 'Low resolution', 'LO_RES', 1, 0, 0, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	BEGIN
		INSERT INTO meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (security_pkg.GetAPP, 3, 'High resolution', 'HI_RES', 1, 0, 0, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	BEGIN
		INSERT INTO meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (security_pkg.GetAPP, 4, 'User patch', 'PATCH_01', 0, 0, 1, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	BEGIN
		INSERT INTO meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (security_pkg.GetAPP, 100, 'Patched output', 'OUTPUT', 0, 1, 0, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if already esists
	END;

	SELECT COUNT(*)
	  INTO v_count
	  FROM meter_header_element;

	IF v_count = 0 THEN
		-- setup some sensible default headers on the meter page
		INSERT INTO meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
			 VALUES (meter_header_element_id_seq.NEXTVAL, 1, 1, meter_pkg.METER_HEADER_SERIAL_NUMBER);
		INSERT INTO meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
			 VALUES (meter_header_element_id_seq.NEXTVAL, 1, 2, meter_pkg.METER_HEADER_METER_SOURCE);
		INSERT INTO meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
			 VALUES (meter_header_element_id_seq.NEXTVAL, 2, 1, meter_pkg.METER_HEADER_PARENT_SPACE);
		INSERT INTO meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
			 VALUES (meter_header_element_id_seq.NEXTVAL, 2, 2, meter_pkg.METER_HEADER_METER_TYPE);
	END IF;

	-- Add meter issue type.
	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, csr_data_pkg.ISSUE_METER, 'Meter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- list page cards
	chain.card_pkg.SetGroupCards('Meter Filter', chain.T_STRING_LIST('Credit360.Metering.Filters.MeterFilter'));

	--
	-- Turn on metering on the app
	UPDATE customer
	   SET metering_enabled = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	IF SQL%ROWCOUNT <> 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Expected exactly one row in CUSTOMER but got '||SQL%ROWCOUNT);
	END IF;
END;

PROCEDURE EnableMeterUtilities
AS
	v_enabled					NUMBER;
	v_admins_sid				security_pkg.T_SID_ID;
	v_meter_admin_role_sid		security_pkg.T_SID_ID;
	v_meter_reader_role_sid		security_pkg.T_SID_ID;
	v_menu_metering				security_pkg.T_SID_ID;
	v_menu_leaf					security_pkg.T_SID_ID;
BEGIN

	-- Check metring is enabled
	SELECT metering_enabled
	  INTO v_enabled
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	IF v_enabled = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Please enable "Metering - base" first.');
	END IF;

	-- Read groups
	v_admins_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Administrators');

	-- Read/create roles
	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter administrator', v_meter_admin_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_admin_role_sid;

	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter reader', v_meter_reader_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_admin_role_sid;

	--
	-- MENU ITEMS

	-- Get/ensure base metering menu item
	BEGIN
		v_menu_metering := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/metering');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(security.security_pkg.getACT,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu'),
				'metering', 'Metering', '/csr/site/meter/meterList.acds', 8, null, v_menu_metering);
	END;

	-- Invoices
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'utility_invoice', 'Invoices', '/csr/site/meter/invoiceList.acds', 4, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'utility_invoice');
	END;

	-- We might decide to add permission for meter reader?
	/* ??
	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);
	*/

	-- Contracts
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'contract_search', 'Contracts', '/csr/site/meter/contractSearch.acds', 5, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'contract_search');
	END;

	-- We might decide to add permission for meter reader?
	/* ??
	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);
	*/

	-- Suppliers
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'utility_supplier', 'Suppliers', '/csr/site/meter/supplierList.acds', 6, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'utility_supplier');
	END;

	-- We might decide to add permission for meter reader?
	/* ??
	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);
	*/

	-- Exception reports
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'utility_reports_exception', 'Exception reports', '/csr/site/meter/reports/exception.acds', 7, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'utility_reports_exception');
	END;

	-- We might decide to add permission for meter reader?
	/* ??
	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);
	*/

	-- Data extract
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'utility_reports_extract', 'Data extract', '/csr/site/meter/reports/extract.acds', 8, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'utility_reports_extract');
	END;

	-- We might decide to add permission for meter reader?
	/* ??
	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);
	*/

	-- Propogate menu ACEs (admin and metering amdin perms will propogate down from parent, so not set above)
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_metering);

	--
	-- ADD CAPABILITIES
	csr_data_pkg.EnableCapability('Delete Utility Supplier', 1);
	csr_data_pkg.EnableCapability('Delete Utility Contract', 1);
	csr_data_pkg.EnableCapability('Delete Utility Invoice', 1);
	csr_data_pkg.EnableCapability('Access All contracts', 1);

	INTERNAL_AddAceForCapability('Delete Utility Supplier', v_admins_sid);
	INTERNAL_AddAceForCapability('Delete Utility Contract', v_admins_sid);
	INTERNAL_AddAceForCapability('Delete Utility Invoice', v_admins_sid);
	INTERNAL_AddAceForCapability('Access All Contracts', v_admins_sid);

	INTERNAL_AddAceForCapability('Delete Utility Supplier', v_meter_admin_role_sid);
	INTERNAL_AddAceForCapability('Delete Utility Contract', v_meter_admin_role_sid);
	INTERNAL_AddAceForCapability('Delete Utility Invoice', v_meter_admin_role_sid);
	INTERNAL_AddAceForCapability('Access All Contracts', v_meter_admin_role_sid);
END;

PROCEDURE INTERNAL_InsertMeterAlarmStat(
	in_bucket_id					IN	meter_alarm_statistic.meter_bucket_id%TYPE,
	in_stat_name					IN	meter_alarm_statistic.name%TYPE,
	in_is_avg						IN	meter_alarm_statistic.is_average%TYPE,
	in_is_sum						IN	meter_alarm_statistic.is_sum%TYPE,
	in_comp_proc					IN	meter_alarm_statistic.comp_proc%TYPE,
	in_input_id						IN	meter_alarm_statistic.meter_input_id%TYPE,
	in_aggregator					IN	meter_alarm_statistic.aggregator%TYPE,
	in_pos							IN	meter_alarm_statistic.pos%TYPE,
	in_core_working_hours			IN	meter_alarm_statistic.core_working_hours%TYPE DEFAULT 0,
	in_all_meters					IN	meter_alarm_statistic.all_meters%TYPE	DEFAULT 0,
	in_lookup						IN	meter_alarm_statistic.lookup_key%TYPE	DEFAULT NULL
)
AS
	v_id							meter_alarm_statistic.statistic_id%TYPE;
BEGIN
	BEGIN
		BEGIN
			SELECT statistic_id
			  INTO v_id
			  FROM meter_alarm_statistic
			 WHERE name = in_stat_name;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum,
					comp_proc, meter_input_id, aggregator, pos, core_working_hours, all_meters, lookup_key)
				VALUES (security.security_pkg.GetAPP, meter_statistic_id_seq.nextval, in_bucket_id, in_stat_name, in_is_avg, in_is_sum, in_comp_proc,
					in_input_id, in_aggregator, in_pos, in_core_working_hours, in_all_meters, in_lookup);
		END;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- IGNORE DUPE LOOKUP KEY
	END;
END;

PROCEDURE EnableRealtimeMetering
AS
	v_cnt							NUMBER;
	v_id							NUMBER(10);
	v_class_id						security.security_pkg.T_CLASS_ID;
	v_source_type_id				meter_source_type.meter_source_type_id%TYPE;

	-- roles
	v_meter_admin_role_sid			security.security_pkg.T_SID_ID;
	v_meter_reader_role_sid			security.security_pkg.T_SID_ID;

	-- buckets
	v_hourly_bucket_id				meter_bucket.meter_bucket_id%TYPE;
	v_daily_bucket_id				meter_bucket.meter_bucket_id%TYPE;

	-- meter input ids
	v_meter_input_id_consumption	meter_input.meter_input_id%TYPE;
BEGIN

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM meter_source_type;
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001,'Please enable "Metering - base" first');
	END IF;

	BEGIN
		INSERT INTO metering_options (analytics_months, analytics_current_month, period_set_id,
									  period_interval_id, realtime_metering_enabled)
		VALUES (NULL, 0, 1, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE metering_options
			   SET realtime_metering_enabled = 1
			 WHERE app_sid = security_pkg.GetApp;
	END;

	-- Add hourly bucket
	BEGIN
		SELECT meter_bucket_id
		  INTO v_hourly_bucket_id
		  FROM meter_bucket
		 WHERE duration = 1
		   AND is_hours = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_bucket (meter_bucket_id, duration, description, is_hours, is_weeks, week_start_day, is_months, start_month, high_resolution_only)
				VALUES (meter_bucket_id_seq.NEXTVAL, 1, 'Hourly', 1, 0, NULL, 0, NULL, 1)
			 RETURNING meter_bucket_id INTO v_hourly_bucket_id;
	END;

	-- Use the hourly bucket for core working hours
	UPDATE meter_bucket
	   SET core_working_hours = CASE WHEN is_hours = 1 AND duration = 1 THEN 1 ELSE 0 END
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT meter_bucket_id
	  INTO v_daily_bucket_id
	  FROM meter_bucket
	 WHERE is_hours = 1
	   AND duration = 24;

	-- Add issue types
	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, 6 /*csr_data_pkg.ISSUE_METER_MONITOR*/, 'Meter monitor');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, 7 /*csr_data_pkg.ISSUE_METER_ALARM*/, 'Meter alarm');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, 8 /*csr_data_pkg.ISSUE_METER_RAW_DATA*/, 'Meter raw data');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, 12 /*csr_data_pkg.ISSUE_METER_DATA_SOURCE*/, 'Meter data source');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, 18 /*csr_data_pkg.ISSUE_METER_MISSING_DATA*/, 'Meter missing data');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Customer region type mapping for realtime meter type
	BEGIN
		INSERT INTO customer_region_type (app_sid, region_type)
		  VALUES (security.security_pkg.GetAPP, 8 /*csr_data_pkg.REGION_TYPE_REALTIME_METER*/);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Enable issue management capability???
	BEGIN
		csr_data_pkg.EnableCapability('Issue management');
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Ensure required base metering roles exist
	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter administrator', v_meter_admin_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_admin_role_sid;

	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter reader', v_meter_reader_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_reader_role_sid;

	--
	-- Add meter alarm base data:

	-- statistics
	SELECT meter_input_id
	  INTO v_meter_input_id_consumption
	  FROM meter_input
	 WHERE lookup_key = 'CONSUMPTION';

	-- Standard statistic set
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Daily usage', 0, 0, 'meter_alarm_stat_pkg.ComputeDailyUsage', v_meter_input_id_consumption, 'SUM', 0);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average daily usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgDailyUsage', v_meter_input_id_consumption, 'SUM', 1);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Weekday usage', 0, 0, 'meter_alarm_stat_pkg.ComputeWeekdayUsage', v_meter_input_id_consumption, 'SUM', 2);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average weekday usage', 0, 0, 'meter_alarm_stat_pkg.ComputeAvgWeekdayUsage', v_meter_input_id_consumption, 'SUM', 3);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Weekend usage', 0, 0, 'meter_alarm_stat_pkg.ComputeWeekendUsage', v_meter_input_id_consumption, 'SUM', 4);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average weekend usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgWeekendUsage', v_meter_input_id_consumption, 'SUM', 5);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Last month''s average usage', 1, 0, 'meter_alarm_stat_pkg.ComputeLastMonthDailyAvg', v_meter_input_id_consumption, 'SUM', 8);
	INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'This month''s average usage', 1, 0, 'meter_alarm_stat_pkg.ComputeThisMonthDailyAvg', v_meter_input_id_consumption, 'SUM', 9);

	-- Standard core working hours statistic set
	INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours - daily usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreDayUse', v_meter_input_id_consumption, 'SUM', 100, 1);
	INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours - daily average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreDayAvg', v_meter_input_id_consumption, 'SUM', 101, 1);
	INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours daily usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreDayUse', v_meter_input_id_consumption, 'SUM', 103, 1);
	INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours daily average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreDayAvg', v_meter_input_id_consumption, 'SUM', 104, 1);

	-- test time
	BEGIN
		SELECT test_time_id
		  INTO v_id
		  FROM meter_alarm_test_time
		 WHERE name = 'Every day';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_test_time (app_sid, test_time_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_test_time_id_seq.nextval, 'Every day', 'meter_alarm_pkg.TestEveryDay');
	END;

	BEGIN
		SELECT test_time_id
		  INTO v_id
		  FROM meter_alarm_test_time
		 WHERE name = 'First day of the month';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_test_time (app_sid, test_time_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_test_time_id_seq.nextval, 'First day of the month', 'meter_alarm_pkg.TestFirstDayOfMonth');
	END;

	BEGIN
		SELECT test_time_id
		  INTO v_id
		  FROM meter_alarm_test_time
		 WHERE name = 'Last day of the month';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_test_time (app_sid, test_time_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_test_time_id_seq.nextval, 'Last day of the month', 'meter_alarm_pkg.TestLastDayOfMonth');
	END;

	-- issue period
	BEGIN
		SELECT issue_period_id
		  INTO v_id
		  FROM meter_alarm_issue_period
		 WHERE name = 'Since the last issue generated';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_issue_period (app_sid, issue_period_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_issue_period_id_seq.nextval, 'Since the last issue generated', 'meter_alarm_pkg.IssuePeriodLastIssue');
	END;

	BEGIN
		SELECT issue_period_id
		  INTO v_id
		  FROM meter_alarm_issue_period
		 WHERE name = 'In the last rolling month';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_issue_period (app_sid, issue_period_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_issue_period_id_seq.nextval, 'In the last rolling month', 'meter_alarm_pkg.IssuePeriodLastRollingMonth');
	END;

	BEGIN
		SELECT issue_period_id
		  INTO v_id
		  FROM meter_alarm_issue_period
		 WHERE name = 'In this calendar month';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_issue_period (app_sid, issue_period_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_issue_period_id_seq.nextval, 'In this calendar month', 'meter_alarm_pkg.IssuePeriodLastCalendarMonth');
	END;

	BEGIN
		SELECT issue_period_id
		  INTO v_id
		  FROM meter_alarm_issue_period
		 WHERE name = 'In the last rolling quarter';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_issue_period (app_sid, issue_period_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_issue_period_id_seq.nextval, 'In the last rolling quarter', 'meter_alarm_pkg.IssuePeriodLastRollingQuarter');
	END;

	BEGIN
		SELECT issue_period_id
		  INTO v_id
		  FROM meter_alarm_issue_period
		 WHERE name = 'In this calendar quarter';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO meter_alarm_issue_period (app_sid, issue_period_id, name, test_function)
			VALUES (security.security_pkg.GetAPP, meter_issue_period_id_seq.nextval, 'In this calendar quarter', 'meter_alarm_pkg.IssuePeriodLastCalendarQuarter');
	END;

	-- Comparison
	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'GT_PCT';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_PCT');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'GT_ABS';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_ABS');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'GT_ADD';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_ADD');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'GT_SUB';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is more than', 'GT_SUB');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'LT_PCT';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_PCT');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'LT_ABS';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_ABS');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'LT_ADD';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_ADD');
	END;

	BEGIN
		SELECT comparison_id
		  INTO v_id
		  FROM meter_alarm_comparison
		 WHERE op_code = 'LT_SUB';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.meter_alarm_comparison (app_sid, comparison_id, name, op_code)
			VALUES (security.security_pkg.GetAPP, csr.meter_comparison_id_seq.NEXTVAL, 'Usage is less than', 'LT_SUB');
	END;

END;

PROCEDURE EnableMeteringFeeds
AS
	v_realtime_metering_enabled	NUMBER;
	v_menu_metering				security.security_pkg.T_SID_ID;
	v_menu_leaf					security.security_pkg.T_SID_ID;
	v_primary_root_sid			security.security_pkg.T_SID_ID;
	v_holding_region_sid		security.security_pkg.T_SID_ID;
BEGIN
	-- Check for and enable real-time metering
	SELECT MAX(realtime_metering_enabled)
	  INTO v_realtime_metering_enabled
	  FROM metering_options;

	IF v_realtime_metering_enabled != 1 THEN
		EnableRealtimeMetering;
	END IF;

	EnableAutomatedExportImport;

	--
	-- Add menu items

	-- Get/ensure base metering menu item
	BEGIN
		v_menu_metering := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/metering');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(security.security_pkg.getACT,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu'),
				'metering', 'Metering', '/csr/site/meter/meterList.acds', 8, null, v_menu_metering);
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'data_source_list', 'Data sources', '/csr/site/meter/monitor/dataSource/DataSourceList.acds', 9, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'raw_data_list', 'Raw feed data', '/csr/site/meter/monitor/RawDataList.acds', 10, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'orphan_data_list', 'Meter errors', '/csr/site/meter/monitor/OrphanMeterRegions.acds', 11, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'csr_newmeters', 'Orphan meters', '/csr/site/meter/NewMeters.acds', 12, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'csr_issue', 'Meter actions', '/csr/site/meter/meterIssuesList.acds', 13, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Propogate menu ACEs
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_metering);

	-- Need holding region (previously un c)
	SELECT MIN(region_sid)
	  INTO v_holding_region_sid
	  FROM region
	 WHERE UPPER(lookup_key) = 'HOLDING';

	IF v_holding_region_sid IS NULL THEN
		v_primary_root_sid := region_tree_pkg.GetPrimaryRegionTreeRootSid;

		region_pkg.CreateRegion(
			in_parent_sid => v_primary_root_sid,
			in_name => 'Unmapped meters',
			in_description => 'Unmapped meters',
			out_region_sid => v_holding_region_sid
		);

		UPDATE region
		   SET lookup_key = 'HOLDING'
		 WHERE region_sid = v_holding_region_sid;
	END IF;

END;

PROCEDURE EnableMeterMonitoring
AS
	v_menu_metering				security.security_pkg.T_SID_ID;
	v_menu_leaf					security.security_pkg.T_SID_ID;
BEGIN
	-- Depends on feeds
	EnableMeteringFeeds;

	-- Add menu items


	-- Get/ensure base metering menu item
	BEGIN
		v_menu_metering := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/metering');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(security.security_pkg.getACT,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu'),
				'metering', 'Metering', '/csr/site/meter/meterList.acds', 8, null, v_menu_metering);
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'meter_monitor_alarms_setup', 'Alarms', '/csr/site/meter/monitor/alarms/alarmsSetup.acds', 14, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Propogate menu ACEs
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_metering);
END;

PROCEDURE EnableMeterReporting
AS
	v_cnt					NUMBER;
	v_menu_metering			security.security_pkg.T_SID_ID;
	v_menu_leaf				security.security_pkg.T_SID_ID;
	v_meter_reader_role_sid security.security_pkg.T_SID_ID;
BEGIN
	-- Check metering has been enabled first
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM meter_source_type;
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Please enable "Metering - base" first');
	END IF;

	-- Ensure the Meter reader role exists (and get the sid if it does)
	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter reader', v_meter_reader_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_reader_role_sid;

	-- Add menu items

	-- Get/ensure base metering menu item
	BEGIN
		v_menu_metering := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/metering');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(security.security_pkg.getACT,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu'),
				'metering', 'Metering', '/csr/site/meter/meterList.acds', 8, null, v_menu_metering);
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_metering, 'meter_list', 'Charts', '/csr/site/meter/List.acds', 2, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_metering, 'meter_list');
	END;

	-- Meter reader (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_reader_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Propogate menu ACEs
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_metering);

	-- add default filtering
	chain.card_pkg.SetGroupCards('Meter Data Filter', chain.T_STRING_LIST('Credit360.Metering.Filters.MeterDataFilter'));

END;

PROCEDURE EnableMeteringGapDetection
AS
	v_menu_metering				security.security_pkg.T_SID_ID;
	v_menu_leaf					security.security_pkg.T_SID_ID;
	v_realtime_metering_enabled	NUMBER;
BEGIN
	-- Check real-time metering has been enabled
	SELECT MAX(realtime_metering_enabled)
	  INTO v_realtime_metering_enabled
	  FROM metering_options;

	IF v_realtime_metering_enabled != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Please enable "Metering - data feeds" first');
	END IF;

	-- Get/ensure base metering menu item
	BEGIN
		v_menu_metering := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/metering');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(security.security_pkg.getACT,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu'),
				'metering', 'Metering', '/csr/site/meter/meterList.acds', 8, null, v_menu_metering);
	END;

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_metering, 'meter_missing_data_report', 'Missing data report', '/csr/site/meter/monitor/MetersWithMissingData.acds', 17, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Propogate menu ACEs
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_metering);

	UPDATE customer
	  SET LIVE_METERING_SHOW_GAPS = 1,
		  METERING_GAPS_FROM_ACQUISITION = 0
	 WHERE app_sid = security.security_pkg.getAPP;
END;

PROCEDURE EnableMeteringAutoPatching
AS
	v_realtime_metering_enabled							NUMBER;
	v_bucket_id						meter_bucket.meter_bucket_id%TYPE;
	v_meter_input_id_consumption	meter_input.meter_input_id%TYPE;
BEGIN
	-- Check real-time metering has been enabled
	SELECT MAX(realtime_metering_enabled)
	  INTO v_realtime_metering_enabled
	  FROM metering_options;

	IF v_realtime_metering_enabled != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Please enable "Metering - data feeds" first');
	END IF;

	SELECT meter_bucket_id
	  INTO v_bucket_id
	  FROM meter_bucket
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND duration = 24
	   AND is_hours = 1;

	SELECT meter_input_id
	  INTO v_meter_input_id_consumption
	  FROM meter_input
	 WHERE lookup_key = 'CONSUMPTION';

	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Monday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgMondayUsage', v_meter_input_id_consumption, 'SUM', 57, 0, 1, 'MONDAY_AVG');
	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Tuesday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgTuesdayUsage', v_meter_input_id_consumption, 'SUM', 58, 0, 1, 'TUESDAY_AVG');
	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Wednesday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgWednesdayUsage', v_meter_input_id_consumption, 'SUM', 59, 0, 1, 'WEDNESDAY_AVG');
	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Thursday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgThursdayUsage', v_meter_input_id_consumption, 'SUM', 60, 0, 1, 'THURSDAY_AVG');
	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Friday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgFridayUsage', v_meter_input_id_consumption, 'SUM', 61, 0, 1, 'FRIDAY_AVG');
	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Saturday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgSaturdayUsage', v_meter_input_id_consumption, 'SUM', 62, 0, 1, 'SATURDAY_AVG');
	INTERNAL_InsertMeterAlarmStat(v_bucket_id, 'Average Sunday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgSundayUsage', v_meter_input_id_consumption, 'SUM', 63, 0, 1, 'SUNDAY_AVG');
END;

PROCEDURE EnableUrjanet (
	in_ftp_path						IN  VARCHAR2
)
AS
	v_meter_admin_role_sid			security_pkg.T_SID_ID;
	v_menu_admin					security_pkg.T_SID_ID;
	v_menu_leaf						security_pkg.T_SID_ID;
	v_www							security_pkg.T_SID_ID;
	v_www_site						security_pkg.T_SID_ID;
	v_www_autoexpimp				security_pkg.T_SID_ID;

	v_automated_import_class_sid	security.security_pkg.T_SID_ID;
	v_ftp_profile_id				auto_imp_fileread_ftp.ftp_profile_id%TYPE;
	v_ftp_settings_id				automated_import_class_step.auto_imp_fileread_ftp_id%TYPE;
	v_ftp_path						VARCHAR2(255) := '/'||in_ftp_path||'/';
	v_raw_data_source_id			meter_raw_data_source.raw_data_source_id%TYPE;
	v_mapping_xml					VARCHAR2(3000);
	v_count							NUMBER;

	v_meter_source_type_id			csr.meter_source_type.meter_source_type_id%TYPE;
	v_parent						security.security_pkg.T_SID_ID;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied enabling Urjanet importer, only super admins can run this.');
	END IF;

	-- Enable things this depends on
	EnableMeteringFeeds;

	-- Get/ensure the meter administrator role
	role_pkg.SetRole(security.security_pkg.getACT, security.security_pkg.getApp, 'Meter administrator', v_meter_admin_role_sid);
	UPDATE role SET is_metering = 1 WHERE role_sid = v_meter_admin_role_sid;

	-- Add menu item
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'menu/admin');

	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.getACT, v_menu_admin, 'csr_site_cmsimp_impinstances', 'Scheduled imports', '/csr/site/automatedExportImport/admin/list.acds', 21, null, v_menu_leaf);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_leaf := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_menu_admin, 'csr_site_cmsimp_impinstances');
	END;

	-- Metering admins (non-inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_leaf), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
		v_meter_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Propogate menu ACEs (admin menu)
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_admin);

	-- Web resource
	v_www := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'wwwroot');
	v_www_site := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, v_www, 'csr/site');
	BEGIN
		v_www_autoexpimp := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, v_www_site, 'automatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.getACT, v_www, v_www_site, 'automatedExportImport', v_www_autoexpimp);
	END;

	-- Metering admins (inheritable)
	security.acl_pkg.AddACE(
		security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_www_autoexpimp), -1,
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
		v_meter_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ
	);

	-- Propogate menu ACEs (web resource)
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_www_autoexpimp);

	-- create class
	BEGIN
		SELECT automated_import_class_sid
		  INTO v_automated_import_class_sid
		  FROM automated_import_class
		 WHERE lookup_key = 'URJANET_IMPORTER';
	EXCEPTION
		WHEN no_data_found THEN
			v_parent := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
			automated_import_pkg.CreateClass(
				in_parent				=> v_parent,
				in_label				=> 'Urjanet importer',
				in_lookup_key			=> 'URJANET_IMPORTER',
				in_schedule_xml			=> XMLType('<recurrences><daily/></recurrences>'),
				in_abort_on_error		=> 0,
				in_email_on_error		=> 'support@credit360.com',
				in_email_on_partial		=> NULL,
				in_email_on_success		=> NULL,
				in_on_completion_sp		=> NULL,
				in_import_plugin		=> NULL,
				out_class_sid			=> v_automated_import_class_sid
			);
	END;

	-- create FTP profile
	v_ftp_profile_id := automated_export_import_pkg.CreateCr360FTPProfile;

	-- create FTP settings
	BEGIN
		SELECT auto_imp_fileread_ftp_id
		  INTO v_ftp_settings_id
		  FROM auto_imp_fileread_ftp
		 WHERE ftp_profile_id = v_ftp_profile_id
		   AND payload_path = '/' || in_ftp_path || '/'
		   AND file_mask = '*.csv';
	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			RAISE_APPLICATION_ERROR(-20001, 'Multiple auto_imp_fileread_ftp records for path /'||in_ftp_path||'/ and mask *.csv');
		WHEN no_data_found THEN
			v_ftp_settings_id := automated_import_pkg.MakeFTPReaderSettings(
				in_ftp_profile_id				=> v_ftp_profile_id,
				in_payload_path					=> v_ftp_path,
				in_file_mask					=> '*.csv',
				in_sort_by						=> 'DATE',
				in_sort_by_direction			=> 'ASC',
				in_move_to_path_on_success		=> v_ftp_path||'processed/',
				in_move_to_path_on_error		=> v_ftp_path||'error/',
				in_delete_on_success			=> 0,
				in_delete_on_error				=> 0
			);
	END;

	-- create step
	BEGIN
		automated_import_pkg.AddFtpClassStep(
			in_import_class_sid				=> v_automated_import_class_sid,
			in_step_number					=> 1,
			in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
			in_days_to_retain_payload		=> 30,
			in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
			in_ftp_settings_id				=> v_ftp_settings_id,
			in_importer_plugin_id			=> automated_import_pkg.IMPORT_PLUGIN_TYPE_METER_RD
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL; -- must already exist
	END;

	-- Statement ID aggregation switched on by default for urjanet data
	-- (just by including the StatementID column mapping)
	v_mapping_xml := '<columnMappings>
			<column name="LogicalMeterId" column-type="urjanet-meter-id" mandatory="yes"/>
			<column name="StatementId" column-type="statement-id"/>
			<column name="StartDate" format="MM/dd/yyyy" column-type="start-date"/>
			<column name="EndDate" format="MM/dd/yyyy" column-type="end-date"/>
			<column name="ConsumptionUnit" column-type="meter-input-unit" format="CONSUMPTION" filter-type="exclude" filter="kW"/>
			<column name="Consumption" column-type="meter-input" format="CONSUMPTION" />
			<column name="Cost" column-type="meter-input" format="COST" />
			<column name="Currency" column-type="meter-input-unit" format="COST" />
			<column name="ConsumptionReadType" column-type="is-estimate" />
			<column name="ServiceAddress"/>
			<column name="SiteCode" column-type="region-ref" mandatory="yes"/>
			<column name="ServiceType" column-type="service-type" filter-type="exclude" filter="sanitation" mandatory="yes" />
			<column name="MeterNumber" column-type="meter-number" mandatory="yes"/>
			<column name="Name" format="{MeterNumber} {ServiceAddress} {ServiceType}" column-type="name" />
			<column name="Url" column-type="note" />
		 </columnMappings>';

	csr.automated_import_pkg.SetGenericImporterSettings(
		in_import_class_sid			=> v_automated_import_class_sid,
		in_step_number				=> 1,
		in_mapping_xml				=> XMLTYPE(v_mapping_xml),
		in_imp_file_type_id			=> 0,
		in_dsv_separator			=> ',',
		in_dsv_quotes_as_literals	=> 0,
		in_excel_worksheet_index	=> 0,
		in_excel_row_index			=> 0,
		in_all_or_nothing			=> 0);

	SELECT MIN(mrds.raw_data_source_id)
	  INTO v_raw_data_source_id
	  FROM meter_raw_data_source mrds
	 WHERE mrds.automated_import_class_sid = v_automated_import_class_sid;

	IF v_raw_data_source_id IS NULL THEN
		INSERT INTO meter_raw_data_source(raw_data_source_id, parser_type, helper_pkg, export_system_values, automated_import_class_sid, create_meters, label)
			 VALUES (raw_data_source_id_seq.NEXTVAL, 'CSV', 'meter_monitor_pkg', 0, v_automated_import_class_sid, 1, 'Urjanet importer')
		  RETURNING raw_data_source_id INTO v_raw_data_source_id;
	END IF;

	BEGIN
		SELECT meter_source_type_id
		  INTO v_meter_source_type_id
		  FROM meter_source_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND name = 'period-null-start-dtm';

	EXCEPTION
		WHEN NO_DATA_FOUND THEN

			SELECT MAX(meter_source_type_id) + 1
			  INTO v_meter_source_type_id
			  FROM meter_source_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

			INSERT INTO meter_source_type (app_sid, meter_source_type_id, name, description,
				arbitrary_period, add_invoice_data, show_in_meter_list, allow_null_start_dtm)
			VALUES (security.security_pkg.GetAPP, v_meter_source_type_id,
				'period-null-start-dtm', 'Urjanet meter', 1, 0, 1, 1);
	END;
END;

PROCEDURE EnableManagementCompanyTree
AS
	v_root_sid						security_pkg.T_SID_ID;
BEGIN
	-- Create the secondary tree
	BEGIN
		v_root_sid := region_tree_pkg.GetSecondaryRegionTreeRootSid('By Management Company');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			 region_pkg.CreateRegionTreeRoot(
				in_act_id					=> security.security_pkg.GetAct,
				in_app_sid					=> security.security_pkg.GetApp,
				in_name						=> 'By Management Company',
				in_is_primary				=> 0,
				out_region_tree_root_sid	=> v_root_sid
			);
	END;

	-- Register the sync job
	BEGIN
		INSERT INTO mgt_company_tree_sync_job (app_sid, tree_root_sid)
		VALUES (security.security_pkg.GetApp, v_root_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL; -- Already registered
	END;

	-- Just this once, trigger the sync immediately
	region_tree_pkg.SyncPropTreeByMgtCompany(in_secondary_root_sid => v_root_sid);
END;

PROCEDURE EnableLikeforlike
AS
	v_sid							security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_site					security_pkg.T_SID_ID;
	v_www_csr_site_likeforlike		security_pkg.T_SID_ID;
	v_admin_menu_sid				security_pkg.T_SID_ID;
	v_menu_sid						security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;
	v_like4like_alert_type_id		NUMBER;
BEGIN

	-- Adding like for like container
	BEGIN
		security.Securableobject_Pkg.CreateSO(security.security_pkg.GetAct, security.security_pkg.GetApp, security.security_pkg.SO_CONTAINER, 'Like for like datasets', v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Setting default max number of slots
	UPDATE customer
	   SET like_for_like_slots = 4
	 WHERE app_sid = security.security_pkg.GetApp;

	-- Web resource
	v_www_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_www_sid, 'csr/site');

	BEGIN
		v_www_csr_site_likeforlike := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_www_csr_site, 'likeForLike');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(
				in_act_id => security.security_pkg.GetAct,
				in_web_root_sid_id => v_www_sid,
				in_parent_sid_id => v_www_csr_site,
				in_page_name => 'likeForLike',
				in_rewrite_path => null,
				out_page_sid_id => v_www_csr_site_likeforlike
			);
	END;

	-- Add administrators to web resource
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_groups_sid, 'Administrators');

	security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_likeforlike), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Creating like for like scenario
	BEGIN
		like_for_like_pkg.CreateScenario;

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Menu
	v_admin_menu_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'menu/admin');

	-- Adding menu link
	BEGIN
		security.menu_pkg.CreateMenu(
			in_act_id => security.security_pkg.GetAct,
			in_parent_sid_id => v_admin_menu_sid,
			in_name => 'csr_like_for_like_admin',
			in_description => 'Like for like',
			in_action => '/csr/site/likeForLike/LikeForLikeList.acds',
			in_pos => -1,
			in_context => null,
			out_sid_id => v_menu_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL; -- link already exists
	END;

--Create the alerts
	BEGIN
		v_like4like_alert_type_id := csr_data_pkg.ALERT_LIKE_FOR_LIKE_SCENARIO;

		INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		VALUES (security.security_pkg.GetApp, customer_alert_type_id_seq.nextval, v_like4like_alert_type_id);

		INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT security.security_pkg.GetApp, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
		  FROM alert_frame af
		  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
		 WHERE af.app_sid = security.security_pkg.GetApp
		   AND cat.std_alert_type_id = v_like4like_alert_type_id
		 GROUP BY cat.customer_alert_type_id
		HAVING MIN(af.alert_frame_id) > 0;

		INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT security.security_pkg.GetApp, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
		  FROM default_alert_template_body d
		  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
		  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
		  CROSS JOIN aspen2.translation_set t
		 WHERE d.std_alert_type_id = v_like4like_alert_type_id
		   AND d.lang='en'
		   AND t.application_sid = security.security_pkg.GetApp
		   AND cat.app_sid = security.security_pkg.GetApp;

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;

END;

PROCEDURE EnableDegreeDays(
	in_account_name					degreeday_settings.account_name%TYPE
)
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_ind_root_sid					security_pkg.T_SID_ID;
	v_ctr_sid						security_pkg.T_SID_ID;
	v_cdd_base_sid					security_pkg.T_SID_ID;
	v_hdd_base_sid					security_pkg.T_SID_ID;
	v_cdd_val_sid					security_pkg.T_SID_ID;
	v_hdd_val_sid					security_pkg.T_SID_ID;
	v_cdd_avg_sid					security_pkg.T_SID_ID;
	v_hdd_avg_sid					security_pkg.T_SID_ID;
	v_celsius_sid					security_pkg.T_SID_ID;
	v_cdd_measure_sid				security_pkg.T_SID_ID;
	v_hdd_measure_sid				security_pkg.T_SID_ID;
	v_superadmins_sid				security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_site					security_pkg.T_SID_ID;
	v_property						security_pkg.T_SID_ID;
	v_property_adm					security_pkg.T_SID_ID;
	v_conv_id						measure_conversion.measure_conversion_id%TYPE;
BEGIN
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = v_app_sid;

	BEGIN
		measure_pkg.CreateMeasure(
			in_name						=> 'celsius',
			in_description				=> 'Celsius',
			in_scale					=> 1,
			in_format_mask				=> '0.00',
			in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
			in_std_measure_conversion_id => 12437, -- 'Celsius'
			out_measure_sid				=> v_celsius_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_celsius_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Measures/celsius');
	END;

	BEGIN
		measure_pkg.SetConversion(
			in_act_id => v_act_id,
			in_conversion_id => NULL,
			in_measure_sid => v_celsius_sid,
			in_description => 'Fahrenheit',
			in_std_measure_conversion_id => 12493, -- 'degrees Fahrenheit'
			out_conversion_id => v_conv_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		measure_pkg.CreateMeasure(
			in_name						=> 'cdd',
			in_description				=> 'CDD',
			in_scale					=> 1,
			in_format_mask				=> '0.00',
			in_divisibility				=> csr_data_pkg.DIVISIBILITY_DIVISIBLE,
			in_std_measure_conversion_id => 1, -- 'constant'
			out_measure_sid				=> v_cdd_measure_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_cdd_measure_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Measures/cdd');
	END;

	BEGIN
		measure_pkg.CreateMeasure(
			in_name						=> 'hdd',
			in_description				=> 'HDD',
			in_scale					=> 1,
			in_format_mask				=> '0.00',
			in_divisibility				=> csr_data_pkg.DIVISIBILITY_DIVISIBLE,
			in_std_measure_conversion_id => 1, -- 'constant'
			out_measure_sid				=> v_hdd_measure_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_hdd_measure_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Measures/hdd');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ind_root_sid,
			in_name          => 'degree_days',
			in_description   => 'Degree days',
			in_is_system_managed => 1,
			out_sid_id	     => v_ctr_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_ctr_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ind_root_sid, 'degree_days');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ctr_sid,
			in_name          => 'cdd',
			in_description   => 'CDD',
			in_aggregate     => 'DOWN',
			in_measure_sid	 => v_cdd_measure_sid,
			in_is_system_managed => 1,
			out_sid_id	     => v_cdd_val_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_cdd_val_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ctr_sid, 'cdd');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ctr_sid,
			in_name          => 'hdd',
			in_description   => 'HDD',
			in_aggregate     => 'DOWN',
			in_measure_sid	 => v_hdd_measure_sid,
			in_is_system_managed => 1,
			out_sid_id	     => v_hdd_val_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_hdd_val_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ctr_sid, 'hdd');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ctr_sid,
			in_name          => 'cdd_average',
			in_description   => 'CDD average',
			in_aggregate     => 'DOWN',
			in_is_system_managed => 1,
			in_measure_sid	 => v_cdd_measure_sid,
			out_sid_id	     => v_cdd_avg_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_cdd_avg_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ctr_sid, 'cdd_average');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ctr_sid,
			in_name          => 'hdd_average',
			in_description   => 'HDD average',
			in_aggregate     => 'DOWN',
			in_is_system_managed => 1,
			in_measure_sid	 => v_hdd_measure_sid,
			out_sid_id	     => v_hdd_avg_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_hdd_avg_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ctr_sid, 'hdd_average');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ctr_sid,
			in_name          => 'cdd_base',
			in_description   => 'CDD base temperature',
			in_aggregate     => 'DOWN',
			in_is_system_managed => 1,
			in_measure_sid	 => v_celsius_sid,
			out_sid_id	     => v_cdd_base_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_cdd_base_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ctr_sid, 'cdd_base');
	END;

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ctr_sid,
			in_name          => 'hdd_base',
			in_description   => 'HDD base temperature',
			in_aggregate     => 'DOWN',
			in_is_system_managed => 1,
			in_measure_sid	 => v_celsius_sid,
			out_sid_id       => v_hdd_base_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_hdd_base_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_ctr_sid, 'hdd_base');
	END;

	degreedays_pkg.SetSettings(
		in_account_name => in_account_name,
		in_download_enabled => 1,
		in_earliest_fetch_dtm => TO_DATE('2010-01-01', 'YYYY-MM-DD'),
		in_average_years => 5,
		in_heating_base_temp_ind_sid => v_hdd_base_sid,
		in_cooling_base_temp_ind_sid => v_cdd_base_sid,
		in_heating_degree_days_ind_sid => v_hdd_val_sid,
		in_cooling_degree_days_ind_sid => v_cdd_val_sid,
		in_heating_average_ind_sid => v_hdd_avg_sid,
		in_cooling_average_ind_sid => v_cdd_avg_sid
	);

	-- Create web resources
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');

	BEGIN
		v_property := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'property');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'property', v_property);
	END;

	-- Administrators for 'property/admin'
	BEGIN
		v_property_adm := security.securableobject_pkg.GetSidFromPath(v_act_id, v_property, 'admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_property, 'admin', v_property_adm);
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_adm), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
END;

PROCEDURE EnableTraining
AS
	v_training_flow_sid		SECURITY.SECURITY_PKG.T_SID_ID;

	v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID;
	v_act_id				SECURITY.SECURITY_PKG.T_ACT_ID;

	-- groups
	v_groups_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_reg_users_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_admins_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_client_admins_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_superadmins_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_t_admin_group_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_t_man_group_sid		SECURITY.SECURITY_PKG.T_SID_ID;

	-- role
	v_role_sid				SECURITY.SECURITY_PKG.T_SID_ID;

	-- menu
	v_root_menu_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_setup_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_menu_training			SECURITY.SECURITY_PKG.T_SID_ID;
	v_menu_training_admin	SECURITY.SECURITY_PKG.T_SID_ID;
	v_menu_item				SECURITY.SECURITY_PKG.T_SID_ID;

	-- web resources
	v_www_root 				SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_csr_site			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_schema			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_schema_new		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training 			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_cr 		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_myt		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_t		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_c		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_cs		SECURITY.SECURITY_PKG.T_SID_ID;

	v_capability_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_calendar_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_flow_root_sid			SECURITY.SECURITY_PKG.T_SID_ID;
BEGIN
	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('START ENABLE TRAINING');
	-----------------------------------------------------------------------------------------------
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;

	BEGIN
		v_flow_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Workflows');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'Workflows not enable on site. Run csr\db\utils\enableWorkflow first.');
			RETURN;
	END;

	BEGIN
		INSERT INTO training_options (app_sid)
			 VALUES (SYS_CONTEXT('SECURITY','APP'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('GROUPS');
	-----------------------------------------------------------------------------------------------
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_client_admins_sid     := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_admins_sid 			:= security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'BuiltIn/Administrators');
	v_superadmins_sid 		:= security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	DBMS_OUTPUT.PUT_LINE('create training administrator group');
	BEGIN
		v_t_admin_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Training Administrator');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			DBMS_OUTPUT.PUT_LINE('Create empty group, add admins and super admins');
			security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Training Administrator', security.class_pkg.GetClassId('CSRUserGroup'), v_t_admin_group_sid);
			security.group_pkg.DeleteAllMembers(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin));
			security.group_pkg.AddMember(v_act_id, v_superadmins_sid, v_t_admin_group_sid);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_t_admin_group_sid);

			DBMS_OUTPUT.PUT_LINE('Clear permissions, add admins and super admins');
			security.securableObject_pkg.ClearFlag(v_act_id, v_t_admin_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	DBMS_OUTPUT.PUT_LINE('create training manager group');
	BEGIN
		v_t_man_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Training Manager');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			DBMS_OUTPUT.PUT_LINE('Create empty group, add admins and super admins');
			security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Training Manager', security.class_pkg.GetClassId('CSRUserGroup'), v_t_man_group_sid);
			security.group_pkg.DeleteAllMembers(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin));
			security.group_pkg.AddMember(v_act_id, v_superadmins_sid, v_t_admin_group_sid);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_t_admin_group_sid);

			DBMS_OUTPUT.PUT_LINE('Clear permissions, add admins and super admins');
			security.securableObject_pkg.ClearFlag(v_act_id, v_t_admin_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('ROLES');
	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('create training admin role');
	BEGIN
		v_t_man_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Training Admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			role_pkg.SetRole(v_act_id, v_app_sid, 'Training Admin', 'TRAINING_ADMIN', v_role_sid);

			DBMS_OUTPUT.PUT_LINE('Clear permissions, add admins and super admins');
			security.securableObject_pkg.ClearFlag(v_act_id, v_role_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_client_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('MENU ITEMS');
	-----------------------------------------------------------------------------------------------
	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');

	BEGIN
		v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'setup');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'admin');
	END;

	DBMS_OUTPUT.PUT_LINE('Add to top menu : Training');
	security.menu_pkg.CreateMenu(v_act_id, v_root_menu_sid, 'csr_training', 'Training', '/csr/site/training/myTraining/myTraining.acds', 3, null, v_menu_training);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_training, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training, 'training_admin', 'Training admin', '/csr/site/training/course/courseList.acds', 4, null, v_menu_training_admin);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_training_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Course Schedules');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_course_schedules', 'Manage course schedules', '/csr/site/training/courseSchedule/courseSchedule.acds', 6, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Course Types');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_course_type', 'Manage course types', '/csr/site/training/courseType/courseType.acds', 8, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Courses');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_courses', 'Manage courses', '/csr/site/training/course/courseList.acds', 5, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Places');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_places', 'Manage places', '/csr/site/schema/new/places.acds', 9, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Trainers');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_trainer', 'Manage trainers', '/csr/site/training/trainer/trainer.acds', 7, null, v_menu_item);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : My Learning');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training, 'training_my_training', 'My learning', '/csr/site/training/myTraining/myTraining.acds', 1, null, v_menu_item);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : Employee Directory');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training, 'training_requests', 'Employee directory', '/csr/site/training/courseRequests/courseRequests.acds', 2, null, v_menu_item);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_man_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.menu_pkg.CreateMenu(v_act_id, v_setup_menu_sid, 'user_rel_types', 'User relationship types', '/csr/site/schema/new/userRelationshipTypes.acds', 21, null, v_menu_item);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_item, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.menu_pkg.CreateMenu(v_act_id, v_setup_menu_sid, 'job_functions', 'Job functions', '/csr/site/schema/new/jobFunctions.acds', 22, null, v_menu_item);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_item, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('WEB RESOURCES');
	-----------------------------------------------------------------------------------------------
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'csr/site');

	BEGIN
		v_www_training := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'training');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'training', v_www_training);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Inherit for ''training/myTraining''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'myTraining', v_www_training_myt);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_myt), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_myt), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_myt), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Managers (all) for ''training/courseRequests''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'courseRequests', v_www_training_cr);
			security.securableObject_pkg.ClearFlag(v_act_id, v_www_training_cr, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cr), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cr), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_man_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cr), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) and Registered Users (read only) for ''training/course''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'course', v_www_training_c);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_c), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_c), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_c), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) and Registered Users (read only) for ''training/courseSchedule''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'courseSchedule', v_www_training_cs);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cs), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cs), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cs), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) for ''training/trainer''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'trainer', v_www_training_t);
			security.securableObject_pkg.ClearFlag(v_act_id, v_www_training_t, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_t), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_t), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_t), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) for ''schema''');
			BEGIN
				v_www_schema := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'schema');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'schema', v_www_schema);
					security.securableObject_pkg.ClearFlag(v_act_id, v_www_schema, security.security_pkg.SOFLAG_INHERIT_DACL);
					security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema), v_reg_users_sid);
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			END;

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) for ''schema/new''');
			BEGIN
				v_www_schema_new := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_schema, 'new');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_schema, 'new', v_www_schema_new);
					security.securableObject_pkg.ClearFlag(v_act_id, v_www_schema_new, security.security_pkg.SOFLAG_INHERIT_DACL);
					security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema_new), v_reg_users_sid);
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema_new), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			END;

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema_new), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	DBMS_OUTPUT.PUT_LINE('don''t inherit');
	security.securableObject_pkg.ClearFlag(v_act_id, v_www_training, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), security.security_pkg.SID_BUILTIN_EVERYONE);
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), v_admins_sid);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('CAPABILITIES');
	-----------------------------------------------------------------------------------------------
	BEGIN
		csr_data_pkg.enablecapability('Edit user relationships');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Edit user relationships');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr_data_pkg.enablecapability('Edit user job functions');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Edit user job functions');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr_data_pkg.enablecapability('Can edit course details');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Can edit course details');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr_data_pkg.enablecapability('Can edit course schedule');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Can edit course schedule');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr_data_pkg.enablecapability('Can manage course requests');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Can manage course requests');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_man_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('PLUGIN');
	-----------------------------------------------------------------------------------------------
	BEGIN
		INSERT INTO plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, app_sid, details, preview_image_path, tab_sid, form_path, group_key, control_lookup_keys)
		VALUES (
			plugin_id_seq.NEXTVAL,
			(SELECT plugin_type_id FROM plugin_type WHERE description = 'Calendar'),
			'Course schedules',
			'/csr/shared/calendar/includes/training.js',
			'Credit360.Calendars.Training',
			'Credit360.Plugins.PluginDto',
			NULL, NULL, NULL, NULL, NULL, NULL, NULL
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('CALENDAR');
	-----------------------------------------------------------------------------------------------
	BEGIN
		calendar_pkg.RegisterCalendar(
			'courseSchedules',
			'/csr/shared/calendar/includes/training.js',
			'Credit360.Calendars.Training',
			'Course schedules',
			1, -- Global
			0, -- not teamrooms
			0, -- not initiatives
			'Credit360.Plugins.PluginDto',
			v_calendar_sid
		);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_calendar_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		BEGIN
			INSERT INTO training_options (app_sid, calendar_sid) VALUES (v_app_sid, v_calendar_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE training_options
				   SET calendar_sid = v_calendar_sid
				   WHERE app_sid = v_app_sid;
		END;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('WORKFLOW');
	-----------------------------------------------------------------------------------------------

	-- Generate standard involvement types csr_data_pkg.FLOW_INV_TYPE_TRAINEE and csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER for this Application
	training_flow_helper_pkg.SetupFlowInvolvementTypes;

	BEGIN
		INSERT INTO CUSTOMER_FLOW_ALERT_CLASS (APP_SID, FLOW_ALERT_CLASS)
		VALUES (v_app_sid, 'training');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- it's in DB already
			NULL;
	END;

	SELECT MIN(flow_sid) INTO v_training_flow_sid
	  FROM training_options
	 WHERE app_sid = v_app_sid;

	IF v_training_flow_sid IS NULL THEN
		training_flow_helper_pkg.SetupTrainingWorkflow(v_training_flow_sid);

		UPDATE training_options
		   SET flow_sid = v_training_flow_sid
		 WHERE app_sid = v_app_sid;
	END IF;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('FINISH ENABLE TRAINING');
	-----------------------------------------------------------------------------------------------

	COMMIT;
END;

PROCEDURE EnableSSO
AS
	v_sso_daemon_name				VARCHAR2(1024) := 'SSO';
	v_sso_daemon_full_name 			VARCHAR2(1024) := 'Single Sign On system';
	v_sso_daemons_group_name		VARCHAR2(1024) := 'SSO Logon Daemons';
	v_sso_users_group_name			VARCHAR2(1024) := 'SSO Users';
	v_administrators_group_name		VARCHAR2(1024) := 'Administrators';
	v_direct_logon_capability		VARCHAR2(1024) := 'Logon directly';
	v_users_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_sso_daemon_sid				security.security_pkg.T_SID_ID;
	v_sso_daemons_group_sid			security.security_pkg.T_SID_ID;
	v_sso_users_group_sid			security.security_pkg.T_SID_ID;
	v_reg_users_group_sid			security.security_pkg.T_SID_ID;
	v_super_admins_group_sid		security.security_pkg.T_SID_ID;
	v_administrators_group_sid		security.security_pkg.T_SID_ID;
	v_direct_logon_capability_sid	security.security_pkg.T_SID_ID;
	v_permission_set				security.security_pkg.T_PERMISSION;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_app_resource_sid				security.security_pkg.T_SID_ID;
	v_sid							security.security_pkg.T_SID_ID;
BEGIN

	v_users_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Users');
	v_groups_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Groups');

	v_reg_users_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, 'RegisteredUsers');
	v_www_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'wwwroot');

	begin
		v_sso_daemon_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_users_sid, v_sso_daemon_name);
		csr_user_pkg.activateUser(security.security_pkg.GetACT, v_sso_daemon_sid);
		dbms_output.put_line('"' || v_sso_daemon_name || '" user found (#' || v_sso_daemon_sid || '). Activated user if it was disabled.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
				csr_user_pkg.createUser(
					in_act			 			=> security.security_pkg.getACT,
					in_app_sid					=> security.security_pkg.getApp,
					in_user_name				=> v_sso_daemon_name,
					in_password 				=> null,
					in_full_name				=> v_sso_daemon_full_name,
					in_friendly_name			=> v_sso_daemon_name,
					in_email		 			=> 'no-reply@cr360.com',
					in_job_title				=> null,
					in_phone_number				=> null,
					in_info_xml					=> null,
					in_send_alerts				=> 0,
					in_account_expiry_enabled	=> 0,
					out_user_sid 				=> v_sso_daemon_sid
				);
		dbms_output.put_line('"' || v_sso_daemon_name || '" user not found. Created one. (#' || v_sso_daemon_sid || ')');
	end;

	-- Don't want SSO logon daemon to be visible in the UI
	update csr_user set hidden = 1 where app_sid = security.security_pkg.getApp and csr_user_sid = v_sso_daemon_sid;

	begin
		v_sso_daemons_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_sso_daemons_group_name);
		dbms_output.put_line('"' || v_sso_daemons_group_name || '" group (#' || v_sso_daemons_group_sid || ') found.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.group_pkg.CreateGroupWithClass(security.security_pkg.GetACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, v_sso_daemons_group_name, security.security_pkg.SO_GROUP, v_sso_daemons_group_sid);
			dbms_output.put_line('"' || v_sso_daemons_group_name || '" group not found. Created one. (#' || v_sso_daemons_group_sid || ')');
	end;

	begin
		v_sso_users_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_sso_users_group_name);
		dbms_output.put_line('"' || v_sso_users_group_name || '" group (#' || v_sso_users_group_sid || ') found.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.group_pkg.CreateGroupWithClass(security.security_pkg.GetACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, v_sso_users_group_name, security.class_pkg.GetClassID('CSRUserGroup'), v_sso_users_group_sid);
			dbms_output.put_line('"' || v_sso_users_group_name || '" group not found. Created one. (#' || v_sso_users_group_sid || ')');
	end;

	begin
		v_administrators_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_administrators_group_name);
		dbms_output.put_line('Site has an "' || v_administrators_group_name || '" group (#' || v_administrators_group_sid || '). Members will be given permission to manage "' || v_sso_users_group_name || '" group membership.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			v_administrators_group_sid := NULL;
			dbms_output.put_line('Site does not have an "' || v_administrators_group_name || '" group. Only super admins will be able to manage "' || v_sso_users_group_name || '" group membership unless existing inheritable permission dictate otherwise.');
	end;

	-- Restrict access to the SSO Logon Daemons group, which also hides it from the UI for normal users.

	security.securableobject_pkg.ClearFlag(security.security_pkg.GetACT, v_sso_daemons_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_daemons_group_sid));
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_daemons_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_users_sid, 'UserCreatorDaemon'), security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_daemons_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, security.security_pkg.SID_BUILTIN_ADMINISTRATOR, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.group_pkg.AddMember(security.security_pkg.GetACT, v_sso_daemon_sid, v_sso_daemons_group_sid);

	dbms_output.put_line('Permissions on the "' || v_sso_daemons_group_name || '" group restricted to remove it from the UI. You do not need to modify membership of this group.');

	-- Give the SSO Logon Daemons group permission to log on as users who are members of the SSO Users group.

	SELECT p.permission INTO v_permission_set
	  FROM security.securable_object so
	  JOIN security.permission_name p ON so.class_id = p.class_id
	 WHERE p.permission_name = 'Logon as another user'
	   AND so.sid_id = v_sso_users_group_sid;

	v_permission_set := security.bitwise_pkg.bitor(v_permission_set, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), v_sso_daemons_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, v_permission_set);

	dbms_output.put_line('"' || v_sso_daemons_group_name || '" group has been given permission to log on as members of the "' || v_sso_users_group_name || '" group.');

	-- Give the SSO Logon Daemons group permission to read users, which it needs to do to find out if they are SSO Users or not.
	-- Also give write permission on users, to allow them to amend user details.

	security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), v_sso_daemons_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_users_sid);

	dbms_output.put_line('"' || v_sso_daemons_group_name || '" group has been given permission read and write all users.');

	-- Allow CRedit360 employees to manage SSO User group membership.

	security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), security.security_pkg.SID_BUILTIN_ADMINISTRATORS);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, security.security_pkg.SID_BUILTIN_ADMINISTRATORS, security.bitwise_pkg.bitor(security.security_pkg.PERMISSION_STANDARD_READ, security.security_pkg.PERMISSION_WRITE));

	dbms_output.put_line('Super Admins have given permission to manage "' || v_sso_users_group_name || '" group membership.');

	-- If there is an Administrators group, then allow its memmbers to manage SSO User group membership as well.

	if v_administrators_group_sid is not null then
		security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), v_administrators_group_sid);
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_administrators_group_sid, security.bitwise_pkg.bitor(security.security_pkg.PERMISSION_STANDARD_READ, security.security_pkg.PERMISSION_WRITE));
		dbms_output.put_line('Members of the "' || v_administrators_group_name || '" group have given permission to manage "' || v_sso_users_group_name || '" group membership.');
	end if;

	-- Deny SSO Users the ability to log on directly with a user name and password, and ensure than non-SSO users can still log on directly.

	csr_data_pkg.EnableCapability(v_direct_logon_capability, 1);

	v_direct_logon_capability_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Capabilities/' || v_direct_logon_capability);

	security.securableobject_pkg.ClearFlag(security.security_pkg.GetACT, v_direct_logon_capability_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid));

	-- If RegisteredUsers group later gets added to the SSO Users group, this is required to allow SuperAdmins to log in directly.
	v_super_admins_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, 0, 'csr/SuperAdmins');

	security.acl_pkg.AddACE(security.security_pkg.GetACT,
		security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid),
		0,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_super_admins_group_sid,
		security.security_pkg.PERMISSION_WRITE);

	security.acl_pkg.AddACE(security.security_pkg.GetACT,
		security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid),
		0,
		security.security_pkg.ACE_TYPE_DENY,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_sso_users_group_sid,
		security.security_pkg.PERMISSION_WRITE);

	dbms_output.put_line('Members of the "' || v_sso_users_group_name || '" group have been denied permission to log on directly using a user name and password. Edit the "' || v_direct_logon_capability || '" capability''s permissions if you want to change this.');

	security.acl_pkg.AddACE(security.security_pkg.GetACT,
		security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users_group_sid,
		security.security_pkg.PERMISSION_WRITE);

	-- Add sign-in UI web resources (primarily used by mobile apps).
	BEGIN
		security.web_pkg.CreateResource(security.security_pkg.GetACT, v_www_sid, v_www_sid, 'app', v_app_resource_sid);
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security.securableobject_pkg.getsidfrompath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- Make sure permissions aren't inheritable if resource already exists (for example if created from enabling Suggestions).
			v_app_resource_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_www_sid, 'app');
			security.acl_pkg.RemoveACEsForSid(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), v_reg_users_group_sid);
			security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	BEGIN
		security.web_pkg.CreateResource(security.security_pkg.GetACT, v_www_sid, v_app_resource_sid, 'ui.signin', v_sid);
		security.securableObject_pkg.ClearFlag(security.security_pkg.GetACT, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Create web resource for sign-in UI resources (bundles etc).
	BEGIN
		security.web_pkg.CreateResource(security.security_pkg.GetACT, v_www_sid, v_www_sid, 'ui.signin', v_sid);
		security.securableObject_pkg.ClearFlag(security.security_pkg.GetACT, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	dbms_output.put_line('All non-SSO users still have permission to log on directly.');
	dbms_output.put_line('Done. This script is safe to re-run if necessary.');
END;

PROCEDURE EnableCapabilitiesUserListPage
AS
BEGIN

	--Add the capability - will inherit from the container (administrators)
	csr_data_pkg.enablecapability('Can manage group membership list page');
	csr_data_pkg.enablecapability('Can deactivate users list page');
	csr_data_pkg.enablecapability('Message users');

END;

FUNCTION GetOrCreateCustomerPortlet (
	in_portlet_type					IN  portlet.type%TYPE
) RETURN NUMBER
AS
	v_portlet_id					portlet.portlet_id%TYPE;
	v_portlet_sid					security_pkg.T_SID_ID;
	v_portlet_enabled				NUMBER;
BEGIN
	SELECT portlet_id
	  INTO v_portlet_id
	  FROM portlet
	 WHERE type = in_portlet_type;

	SELECT COUNT(*)
	  INTO v_portlet_enabled
	  FROM customer_portlet
	 WHERE portlet_id = v_portlet_id;

	IF v_portlet_enabled = 0 THEN
		portlet_pkg.EnablePortletForCustomer(v_portlet_id);
	END IF;

	SELECT customer_portlet_sid
	  INTO v_portlet_sid
	  FROM customer_portlet
	 WHERE portlet_id = v_portlet_id;

	RETURN v_portlet_sid;
END;

FUNCTION IsPortletOnTab(
	in_tab_id						IN  tab_portlet.tab_id%TYPE,
	in_customer_portlet_sid			IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		SELECT 1
		  FROM tab_portlet
		 WHERE tab_id = in_tab_id
		   AND customer_portlet_sid = in_customer_portlet_sid
	) LOOP
		RETURN TRUE;
	END LOOP;

	RETURN FALSE;
END;

PROCEDURE EnableComplianceBase
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_groups_sid					security_pkg.T_SID_ID;
	v_class_id						security_pkg.T_SID_ID;
	v_ehs_managers_sid				security_pkg.T_SID_ID;
	v_survey_type					quick_survey_type.quick_survey_type_id%TYPE;
	v_flow_root_sid					security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_site					security_pkg.T_SID_ID;
	v_www_csr_site_compliance		security_pkg.T_SID_ID;
	v_www_csr_site_compl_admin		security_pkg.T_SID_ID;
	v_www_api_compliance			security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;
	v_property_manager_sid			security_pkg.T_SID_ID;
	v_menu_sid						security_pkg.T_SID_ID;
	v_admin_menu_sid				security_pkg.T_SID_ID;
	v_compliance_menu_sid			security_pkg.T_SID_ID;
	v_legal_register_menu			security_pkg.T_SID_ID;
	v_compliance_calendar_menu		security_pkg.T_SID_ID;
	v_compliance_setting_menu		security_pkg.T_SID_ID;
	v_compliance_create_menu		security_pkg.T_SID_ID;
	v_data_entry_menu				security_pkg.T_SID_ID;
	v_compliance_capability_sid		security_pkg.T_SID_ID;
	v_issue_man_capability_sid		security_pkg.T_SID_ID;
	v_portlet_ehs_mgr_tab_id		security_pkg.T_SID_ID;
	v_portlet_prop_mgr_tab_id		security_pkg.T_SID_ID;
	v_tab_portlet_id				tab_portlet.tab_portlet_id%TYPE;
	v_portlet_sid					security_pkg.T_SID_ID;
	v_score_type_id					security_pkg.T_SID_ID;
	v_dummy_sid						security_pkg.T_SID_ID;
	v_is_property_enable			NUMBER(1);
	v_tab_pos						property_tab.pos%TYPE;
	v_plugin_id						plugin.plugin_id%TYPE;
	v_regusers_sid					security.security_pkg.T_SID_ID;

BEGIN


	-- create group
	v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_class_id := security.class_pkg.GetClassID('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'EHS Managers', v_class_id, v_ehs_managers_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
	END;

	/*** WEB RESOURCES ***/
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	role_pkg.SetRole('Property Manager', v_property_manager_sid);

	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_compliance := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'compliance');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'compliance', v_www_csr_site_compliance);
	END;

	BEGIN
		v_www_api_compliance := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'api.compliance');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		BEGIN
			v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_sid, 'api.compliance', v_www_api_compliance);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_compliance), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
	END;

	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_csr_site_compliance),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid,
		security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_csr_site_compliance),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_ehs_managers_sid,
		security.security_pkg.PERMISSION_STANDARD_READ);

	-- TODO: property managers should probably not be able to see everything by default
	IF v_property_manager_sid IS NOT NULL THEN
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_www_csr_site_compliance),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_property_manager_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	BEGIN
		v_www_csr_site_compl_admin := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_compliance, 'admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_compliance, 'admin', v_www_csr_site_compl_admin);
	END;
	security.securableObject_pkg.ClearFlag(v_act_id, v_www_csr_site_compl_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_compl_admin));
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_www_csr_site_compl_admin),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_INHERITABLE,
		v_admins_sid,
		security.security_pkg.PERMISSION_STANDARD_READ);

	-- Enable capability
	csr_data_pkg.EnableCapability('Manage compliance items', 1);
	v_compliance_capability_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities/Manage compliance items');

	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_compliance_capability_sid),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_ehs_managers_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_compliance_capability_sid),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);

	v_issue_man_capability_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities/Issue management');
	security.acl_pkg.AddACE(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_issue_man_capability_sid),
		-1,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_ehs_managers_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);

	-- add menu items
	v_menu_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'csr_compliance', 'Compliance', '/csr/site/compliance/LegalRegister.acds', 5, null, v_compliance_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_compliance_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/csr_compliance');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_compliance_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_ehs_managers_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_compliance_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		0 /* not inheritable */, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_compliance_menu_sid, 'csr_compliance_legal_register', 'Legal register', '/csr/site/compliance/LegalRegister.acds', 1, null, v_legal_register_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_legal_register_menu := security.securableObject_pkg.GetSidFromPath(v_act_id, v_compliance_menu_sid, 'csr_compliance_legal_register');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_legal_register_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act_id, v_compliance_menu_sid, v_legal_register_menu);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_compliance_menu_sid, 'csr_compliance_calendar', 'Compliance calendar', '/csr/site/compliance/ComplianceCalendar.acds', 2, null, v_compliance_calendar_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_compliance_calendar_menu := security.securableObject_pkg.GetSidFromPath(v_act_id, v_compliance_menu_sid, 'csr_compliance_calendar');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_compliance_calendar_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act_id, v_compliance_menu_sid, v_compliance_calendar_menu);

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_compliance_menu_sid, 'csr_compliance_setting', 'Settings', '/csr/site/compliance/ConfigureSettings.acds', 5, null, v_compliance_setting_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_compliance_setting_menu := security.securableObject_pkg.GetSidFromPath(v_act_id, v_compliance_menu_sid, 'csr_compliance_setting');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_compliance_setting_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_ehs_managers_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act_id, v_compliance_menu_sid, v_compliance_setting_menu);

	v_admin_menu_sid := security.securableObject_pkg.getSIDFromPath(v_act_id, v_menu_sid, 'admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu_sid, 'csr_compliance_admin', 'Compliance admin', '/csr/site/compliance/admin/menu.acds', 21, null, v_dummy_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Enable data entry menu for EHS/Property Managers
	BEGIN
		v_data_entry_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu_sid, 'data');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_data_entry_menu := NULL;
	END;

	IF v_data_entry_menu IS NOT NULL THEN
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_data_entry_menu),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_ehs_managers_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);

		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_data_entry_menu),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_property_manager_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	-- Add new issue types
	BEGIN
	INSERT INTO ISSUE_TYPE (app_sid, issue_type_id, label, helper_pkg, allow_critical)
			VALUES (v_app_sid, csr_data_pkg.ISSUE_COMPLIANCE, 'Compliance', 'csr.compliance_pkg', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO ISSUE_TYPE (app_sid, issue_type_id, label, helper_pkg, allow_critical)
		VALUES (v_app_sid, csr_data_pkg.ISSUE_PERMIT, 'Permit', 'csr.permit_pkg', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	-- Issue due dtm sources
	BEGIN
		INSERT INTO csr.issue_due_source
			(issue_due_source_id, issue_type_id, source_description, fetch_proc)
		VALUES
			(csr_data_pkg.ISSUE_SOURCE_PERMIT_START, csr_data_pkg.ISSUE_PERMIT,
			 'Permit start date', 'permit_pkg.GetIssueDueDtm');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.issue_due_source
			(issue_due_source_id, issue_type_id, source_description, fetch_proc)
		VALUES
			(csr_data_pkg.ISSUE_SOURCE_PERMIT_EXPIRY, csr_data_pkg.ISSUE_PERMIT,
			 'Permit expiry date', 'permit_pkg.GetIssueDueDtm');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.issue_due_source
			(issue_due_source_id, issue_type_id, source_description, fetch_proc)
		VALUES
			(csr_data_pkg.ISSUE_SOURCE_ACTIVITY_START, csr_data_pkg.ISSUE_PERMIT,
			 'Permit activity start date', 'permit_pkg.GetIssueDueDtm');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.issue_due_source
			(issue_due_source_id, issue_type_id, source_description, fetch_proc)
		VALUES
			(csr_data_pkg.ISSUE_SOURCE_ACTIVITY_END, csr_data_pkg.ISSUE_PERMIT,
			 'Permit activity end date', 'permit_pkg.GetIssueDueDtm');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;


	BEGIN
		INSERT INTO csr.issue_due_source
			(issue_due_source_id, issue_type_id, source_description, fetch_proc)
		VALUES
			(csr_data_pkg.ISSUE_SOURCE_PERMIT_CMN_DTM, csr_data_pkg.ISSUE_PERMIT,
			 'Permit site commissioned date', 'permit_pkg.GetIssueDueDtm');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	SELECT MIN(quick_survey_type_id)
	  INTO v_survey_type
	  FROM quick_survey_type
	 WHERE cs_class = 'Credit360.QuickSurvey.ComplianceSurveyType';

	quick_survey_pkg.SaveSurveyType(
		in_quick_survey_type_id		=> v_survey_type,
		in_description				=> 'Compliance Survey',
		in_enable_question_count	=> 0,
		in_show_answer_set_dtm		=> 0,
		in_oth_txt_req_for_score	=> 0,
		in_cs_class					=> 'Credit360.QuickSurvey.ComplianceSurveyType',
		in_helper_pkg				=> NULL,
		out_quick_survey_type_id	=> v_survey_type
	);

	BEGIN
		INSERT INTO compliance_options (quick_survey_type_id)
		VALUES (v_survey_type);
	EXCEPTION
		WHEN dup_val_on_index THEN
			-- Must have been enabled already
			NULL;
	END;

	BEGIN
		INSERT INTO score_type (score_type_id, label, pos, hidden, allow_manual_set, lookup_key, applies_to_supplier, reportable_months)
		VALUES (score_type_id_seq.nextval, 'Compliance RAG', 0, 0, 0, 'COMPLIANCE_RAG', 0, 0)
		RETURNING score_type_id INTO v_score_type_id;

		INSERT INTO score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
		VALUES (score_threshold_id_seq.NEXTVAL, 'Low',	89, 16712965, 16712965,	16712965, v_score_type_id);
		INSERT INTO score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
		VALUES (score_threshold_id_seq.NEXTVAL, 'Medium',	94, 16770048, 16770048,	16770048, v_score_type_id);
		INSERT INTO score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
		VALUES (score_threshold_id_seq.NEXTVAL, 'High',	100, 3777539, 3777539,	3777539, v_score_type_id);

		UPDATE csr.compliance_options SET score_type_id = v_score_type_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			-- Must have been enabled already
			NULL;
	END;

	-- Check if tabs already exist.
	SELECT MIN(tab_id)
	  INTO v_portlet_ehs_mgr_tab_id
	  FROM csr.tab
	 WHERE name = 'Company compliance';

	SELECT MIN(tab_id)
	  INTO v_portlet_prop_mgr_tab_id
	  FROM csr.tab
	 WHERE name = 'Site compliance';

	-- ## Setup dashboards and portlets. ##
	IF v_portlet_ehs_mgr_tab_id IS NULL THEN
		portlet_pkg.AddTabReturnTabId(
			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
			in_tab_name => 'Company compliance',
			in_is_shared => 1,
			in_is_hideable => 1,
			in_layout => 6,
			in_portal_group => NULL,
			out_tab_id => v_portlet_ehs_mgr_tab_id
		);
	END IF;

	IF v_portlet_prop_mgr_tab_id IS NULL THEN
		portlet_pkg.AddTabReturnTabId(
			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
			in_tab_name => 'Site compliance',
			in_is_shared => 1,
			in_is_hideable => 1,
			in_layout => 1,
			in_portal_group => NULL,
			out_tab_id => v_portlet_prop_mgr_tab_id
		);
	END IF;

	-- Add permissions on tabs.
	BEGIN
		INSERT INTO tab_group(group_sid, tab_id)
		VALUES(v_ehs_managers_sid, v_portlet_ehs_mgr_tab_id);

		INSERT INTO tab_group(group_sid, tab_id)
		VALUES(v_property_manager_sid, v_portlet_prop_mgr_tab_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;


	-- EHS Manager portlet tab contents.
	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.GeoMap');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"portletHeight":460,"pickerMode":0,"filterMode":0,"selectedRegionList":[],"includeInactiveRegions":false,"colourBy":"complianceRag","portletTitle":"Site Compliance RAG Status"}',
			out_tab_portlet_id => v_tab_portlet_id
		);
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.SiteComplianceLevels');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '',
			out_tab_portlet_id => v_tab_portlet_id
		);

		-- Adjust pos.
		UPDATE tab_portlet
		SET column_num = 1, pos = 1
		WHERE tab_portlet_id = v_tab_portlet_id;
	END IF;

	SELECT COUNT(*)
	  INTO v_is_property_enable
	  FROM property_options;

	IF v_is_property_enable = 1 THEN
		SELECT MAX(pos)
		  INTO v_tab_pos
		  FROM property_tab;

		v_plugin_id := plugin_pkg.GetPluginId('Controls.ComplianceTab');

		BEGIN
			INSERT INTO property_tab (plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_plugin_id, csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,  v_tab_pos+1, 'Compliance');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE property_tab
				   SET pos = v_tab_pos+1
				 WHERE plugin_id = v_plugin_id;
		END;

		BEGIN
			INSERT INTO property_tab_group (plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/RegisteredUsers'));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END IF;

	chain.card_pkg.SetGroupCards('Compliance Register Filter', chain.T_STRING_LIST('Credit360.Compliance.Filters.LegalRegisterFilter'));

	BEGIN
		INSERT INTO compliance_language (lang_id)
		 SELECT l.lang_id FROM aspen2.lang l
		  WHERE l.lang = 'en';
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnableCompliance (
	in_enable_regulation_flow		IN	VARCHAR2,
	in_enable_requirement_flow		IN	VARCHAR2,
	in_enable_campaign				IN	VARCHAR2
)
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_flow_root_sid					security_pkg.T_SID_ID;
	v_campaigns_sid					security_pkg.T_SID_ID;
	v_compliance_menu_sid			security_pkg.T_SID_ID;
	v_portlet_ehs_mgr_tab_id		security_pkg.T_SID_ID;
	v_portlet_prop_mgr_tab_id		security_pkg.T_SID_ID;
	v_tab_portlet_id				tab_portlet.tab_portlet_id%TYPE;
	v_portlet_sid					security_pkg.T_SID_ID;
	v_survey_type					quick_survey_type.quick_survey_type_id%TYPE;
	v_dummy_sid						security_pkg.T_SID_ID;
	v_is_already_enabled			BOOLEAN;
	v_is_permit_enabled				BOOLEAN;
	v_count							NUMBER(10);
BEGIN

	v_is_already_enabled := compliance_pkg.IsModuleEnabled = 1;
	v_is_permit_enabled := permit_pkg.IsModuleEnabled = 1;
	-- Check pre-requisite
	BEGIN
		v_flow_root_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Workflows');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Workflow must be enabled.');
	END;

	BEGIN
		v_campaigns_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Surveys/campaigns must be enabled.');
	END;

	IF UPPER(in_enable_regulation_flow) <> 'Y' AND UPPER(in_enable_requirement_flow) <> 'Y' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Regulation or requirement workflow must be enabled.');
	END IF;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class) VALUES ('requirement');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class) VALUES ('regulation');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	EnableComplianceBase;

	-- add menu items
	v_compliance_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/csr_compliance');

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_compliance_menu_sid, 'csr_compliance_library', 'Compliance library', '/csr/site/compliance/Library.acds', 3, null, v_dummy_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	IF v_is_permit_enabled THEN
		security.menu_pkg.SetMenuAction(v_act_id, v_compliance_menu_sid, '/csr/site/compliance/LegalRegister.acds');
	END IF;

	security.acl_pkg.PropogateACEs(v_act_id, v_compliance_menu_sid, v_dummy_sid);

	-- Check if tabs already exist.
	SELECT MIN(tab_id)
	  INTO v_portlet_ehs_mgr_tab_id
	  FROM csr.tab
	 WHERE name = 'Company compliance';

	SELECT MIN(tab_id)
	  INTO v_portlet_prop_mgr_tab_id
	  FROM csr.tab
	 WHERE name = 'Site compliance';

	-- Property Manager portlet tab contents.
	SELECT MIN(quick_survey_type_id)
	  INTO v_survey_type
	  FROM quick_survey_type
	 WHERE cs_class = 'Credit360.QuickSurvey.ComplianceSurveyType';

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.MySurveys');
	IF NOT IsPortletOnTab(v_portlet_prop_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_prop_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"portletTitle":"Surveys awaiting reply","portletSurveyTypes":[' || v_survey_type || '],"removeSubmitted":true}',
			out_tab_portlet_id => v_tab_portlet_id
		);
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.Compliance.NonCompliantItems');
	IF NOT IsPortletOnTab(v_portlet_prop_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_prop_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"portletHeight":250}',
			out_tab_portlet_id => v_tab_portlet_id
		);

		DECLARE
			v_portlet_ids				security_pkg.T_SID_IDS;
		BEGIN
			v_portlet_ids(1) := v_tab_portlet_id;
			portlet_pkg.UpdatePortletPosition(
				in_tab_id => v_portlet_prop_mgr_tab_id,
				in_column => 1,
				in_tab_portlet_ids => v_portlet_ids
			);
		END;
	END IF;

	-- Property Manager portlet tab contents.
	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.Issue2');
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_portlet
	 WHERE tab_id = v_portlet_prop_mgr_tab_id
	   AND customer_portlet_sid = v_portlet_sid
	   AND DBMS_LOB.INSTR(state, '"defaultIssueType":'||csr_data_pkg.ISSUE_COMPLIANCE ) > 0;
	IF v_count = 0 THEN	-- there is another property manager Issue2 portlet for permits, so can't just check that there's one already there.
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_prop_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"overdue":true,"unresolved":true,"resolved":false,"closed":false,"rejected":false,"defaultIssueType":'||csr_data_pkg.ISSUE_COMPLIANCE||'}',
			out_tab_portlet_id => v_tab_portlet_id
		);
	END IF;

	-- EHS Manager portlet tab contents.
	IF v_campaigns_sid > 0 THEN
		v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.MySurveyCampaigns');

		IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
			portlet_pkg.AddPortletToTab(
				in_tab_id => v_portlet_ehs_mgr_tab_id,
					in_customer_portlet_sid => v_portlet_sid,
				in_initial_state => '{"portletTitle":"Survey campaign status","selectedFolderSid":'||v_campaigns_sid||',"ragGreen":"95","ragAmber":"90","ragRed":"0"}',
					out_tab_portlet_id => v_tab_portlet_id
			);

				UPDATE tab_portlet
				   SET column_num = 1, pos = 0
				 WHERE tab_portlet_id = v_tab_portlet_id;
		END IF;
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.ComplianceLevels');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
				in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '',
				out_tab_portlet_id => v_tab_portlet_id
		);

		UPDATE tab_portlet
		   SET pos = 2
		 WHERE tab_portlet_id = v_tab_portlet_id;
	END IF;

	chain.card_pkg.SetGroupCards('Compliance Library Filter', chain.T_STRING_LIST('Credit360.Compliance.Filters.ComplianceLibraryFilter'));

	-- Default workflows
	compliance_pkg.SetEnabledFlow(
		in_enable_requirement_flow	=> CASE WHEN UPPER(in_enable_requirement_flow) = 'Y' THEN 1 ELSE 0 END,
		in_enable_regulation_flow	=> CASE WHEN UPPER(in_enable_regulation_flow) = 'Y' THEN 1 ELSE 0 END
	);

	-- Campaigns does not have to be enabled, but if it is, give EHS Manager the grants they need to
	-- use it
	INTERNAL_AddCampaignsGrants;
	IF UPPER(in_enable_campaign) = 'Y' THEN
		INTERNAL_CreateCampaignAndWF;
	END IF;


	--Add alerts
	BEGIN
		FOR alert IN (
			SELECT std_alert_type_id
			  FROM std_alert_type
			 WHERE std_alert_type_group_id = (SELECT std_alert_type_group_id
												FROM std_alert_type_group
											   WHERE description = 'Compliance')
		)
		LOOP
			util_script_pkg.AddMissingAlert(alert.std_alert_type_id);
			-- inactivating alerts
			UPDATE alert_template
			   SET send_type = 'inactive'
			 WHERE customer_alert_type_id
				IN (SELECT customer_alert_type_id
					  FROM customer_alert_type
				 	 WHERE std_alert_type_id = alert.std_alert_type_id);
		END LOOP;
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
	END;

END;

PROCEDURE EnableEnhesa(
	in_client_id					IN	enhesa_options.client_id%TYPE,
	in_username						IN	enhesa_options.username%TYPE DEFAULT NULL,
	in_password						IN	enhesa_options.password%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT compliance_pkg.IsModuleEnabled = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The compliance module must be enabled.');
	END IF;

	compliance_pkg.SetEnhesaOptions(
		in_client_id => in_client_id,
		in_username => in_username,
		in_password => in_password,
		in_manual_run => 1,
		in_next_run => NULL
	);

	compliance_pkg.PopulateSiteHeadingCodes;
END;

PROCEDURE EnableIncidents
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security.security_pkg.T_ACT_ID := security.security_pkg.getAct;
	v_groups_sid 					security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(
										v_act_id, v_app_sid, 'Groups');
	v_admins_sid					security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(
										v_act_id, v_groups_sid, 'Administrators');
	v_reg_users_sid					security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(
										v_act_id, v_groups_sid, 'RegisteredUsers');
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
	v_www_csr_site_incident			security.security_pkg.T_SID_ID;
	v_www_cs_incident_admin			security.security_pkg.T_SID_ID;
BEGIN
	-- incident portlet
	FOR r IN (
		SELECT security.security_pkg.getapp, portlet_id
		  FROM portlet
		 WHERE type IN (
			'Credit360.Portlets.Incident'
		 ) AND portlet_Id NOT IN (select portlet_id from customer_portlet))
	LOOP
		portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;

	/*** WEB RESOURCE ***/
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_incident := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'incidents');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_incident), v_reg_users_sid);
		-- add reg users to incidents web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_incident), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'incidents', v_www_csr_site_incident);
			-- add reg users to issues web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_incident), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	BEGIN
		v_www_cs_incident_admin := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_incident, 'admin');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_cs_incident_admin), v_admins_sid);
		-- add admins to incidents web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_cs_incident_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_incident, 'admin', v_www_cs_incident_admin);
			-- add admins to incidents web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_cs_incident_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
END;

FUNCTION IsPropertyEnabled
RETURN NUMBER
AS
	v_check	NUMBER(1);
BEGIN
	SELECT CASE
				WHEN property_flow_sid IS NOT NULL THEN 1
				ELSE 0
			END
	  INTO v_check
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	RETURN v_check;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;
END;

PROCEDURE EnableProperties(
	in_company_name		IN	VARCHAR2,
	in_property_type	IN	VARCHAR2
)
AS
	v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id				SECURITY.SECURITY_PKG.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_www_sid				SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_csr_site			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_new_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_primary_root_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_suppliers_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_property				SECURITY.SECURITY_PKG.T_SID_ID;
	v_property_adm			SECURITY.SECURITY_PKG.T_SID_ID;
	v_property_prop			SECURITY.SECURITY_PKG.T_SID_ID;
	v_property_stat			SECURITY.SECURITY_PKG.T_SID_ID;
	v_property_prop_new		SECURITY.SECURITY_PKG.T_SID_ID;
	v_company_type_id		SECURITY.SECURITY_PKG.T_SID_ID;
	v_cust_comp_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_company_name			chain.company.name%TYPE;
	v_root_menu_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_property_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_setup_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_admin_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_new_menu_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_new_sub_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_registeredUsers_sid	SECURITY.SECURITY_PKG.T_SID_ID;
	v_administrators_sid	SECURITY.SECURITY_PKG.T_SID_ID;
	v_role_sid				SECURITY.SECURITY_PKG.T_SID_ID;
	v_tab_id				NUMBER(10);
	v_flow_root_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_plugin_id				plugin.plugin_id%TYPE;
	v_capabilities_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_capability_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_card_id				NUMBER(10);
	v_is_module_enable		NUMBER(1);
	v_tab_pos				property_tab.pos%TYPE;
BEGIN
	BEGIN
		v_flow_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Workflows');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'Workflows not enabled on site. Run csr\db\utils\enableWorkflow first.');
			RETURN;
	END;

	BEGIN
		INSERT INTO property_options (app_sid)
			 VALUES (v_app_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	-- Web resource permissions
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');

	v_registeredUsers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/RegisteredUsers');
	v_administrators_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/Administrators');

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_csr_site, 'property', v_property);

	-- Administrators for 'property/admin'
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_property, 'admin', v_property_adm);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_adm), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_administrators_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Registered Users for 'property/properties'
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_property, 'properties', v_property_prop);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_prop), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registeredUsers_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Just Administrators for 'property/properties/New.acds'
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_property_prop, 'New.acds', v_property_prop_new);
	security.securableobject_pkg.SetFlags(v_act_id, v_property_prop_new, 0); -- unset inherited
	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_prop_new));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_prop_new), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_administrators_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Registered Users for 'property/status'
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_property, 'status', v_property_stat);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_stat), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registeredUsers_sid, security.security_pkg.PERMISSION_STANDARD_READ);


	-- Check if there are any companies, if not, create one as the top company and add
	-- all existing users to that company. If there is at least one company, then
	-- it's already a chain site and we don't want to interfere with that site - so
	-- do nothing.
	BEGIN
		-- If chain has already been set up, just rename the top company.
		SELECT c.company_sid, c.name
		  INTO v_cust_comp_sid, v_company_name
		  FROM chain.company c
		  JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
		 WHERE ct.is_top_company = 1
		   AND c.app_sid = v_app_sid;

		IF v_company_name <> in_company_name THEN
			chain.company_pkg.UpdateCompany(
				in_company_sid		=> v_cust_comp_sid,
				in_name				=> in_company_name
			);
		END IF;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_primary_root_sid := region_tree_pkg.GetPrimaryRegionTreeRootSid;

			chain.setup_pkg.EnableSiteLightweight();

			-- remove the Suppliers node -- we don't need it
			BEGIN
				v_suppliers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_primary_root_sid, 'Suppliers');
				security.securableobject_pkg.DeleteSO(v_act_id, v_suppliers_sid);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
			END;

			-- create default company (this still works if company already exists!)
			chain.company_type_pkg.AddCompanyType(
				in_lookup_key				=> 'TOP',
				in_singular					=> 'TOP',
				in_plural					=> 'TOP',
				in_default_region_type		=> csr_data_pkg.REGION_TYPE_NORMAL,
				in_region_root_sid			=> v_primary_root_sid,
				-- dummy value so that it doesn't default to COUNTRY; we know we will not be using sectors as we are creating the company immediately
				in_default_region_layout	=> '{SECTOR}'
			);
			chain.company_type_pkg.SetTopCompanyType('TOP');
			chain.company_type_pkg.SetDefaultCompanyType(chain.company_type_pkg.GetCompanyTypeId('TOP'));
			-- In order to create funds, we need a company type.  Now we have one, use it.
			v_company_type_id := chain.company_type_pkg.GetCompanyTypeId('TOP');
			UPDATE property_options
			   SET fund_company_type_id = v_company_type_id
			 WHERE app_sid = v_app_sid;

			v_cust_comp_sid := chain.setup_pkg.CreateCompanyLightweight(in_company_name, 'gb', 'TOP');	-- Country defaults to GB.. can be changed in UI.
			--supplier_pkg.AddCompany(v_cust_comp_sid);

			-- update the default type
			chain.company_type_pkg.AddCompanyType(
				in_lookup_key				=> 'DEFAULT',
				in_singular					=> 'Company',
				in_plural					=> 'Companies',
				in_default_region_type		=> csr_data_pkg.REGION_TYPE_NORMAL,
				in_region_root_sid			=> v_primary_root_sid,
				in_default_region_layout	=> '{SECTOR}'
			);

			-- Add existing site users to top company
			FOR r IN (
				SELECT cu.csr_user_sid, cu.user_name
				  FROM csr_user cu, security.securable_object so, customer c
				 WHERE cu.app_sid = c.app_sid
				   AND cu.csr_user_sid = so.sid_id
				   AND so.parent_sid_id != c.trash_sid
				   AND cu.hidden = 0
				   AND so.name != 'admin'
				   AND csr_user_sid NOT IN (
					SELECT user_sid FROM chain.chain_user
				 ) AND csr_user_sid NOT IN (
					SELECT csr_user_sid FROM superadmin
				 )
			) LOOP
				INSERT INTO chain.chain_user (user_sid, visibility_id, registration_status_id,
					default_company_sid, tmp_is_chain_user, receive_scheduled_alerts)
				VALUES (r.csr_user_sid, chain.chain_pkg.NAMEJOBTITLE,
					chain.chain_pkg.REGISTERED, v_cust_comp_sid, chain.chain_pkg.ACTIVE, 1
				);

				chain.company_user_pkg.AddUserToCompany(v_cust_comp_sid, r.csr_user_sid);
				chain.company_user_pkg.ApproveUser(v_cust_comp_sid, r.csr_user_sid); -- just to be safe
			END LOOP;
	END;

	-- create property manager role
	role_pkg.SetRole(v_act_id, v_app_sid, 'Property Manager', 'PROPERTY_MANAGER', v_role_sid);

	UPDATE role
	   SET is_property_manager = 1
	 WHERE role_sid = v_role_sid;

	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'setup');
	v_admin_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'admin');

	-- Create property menus:
	-- Property
	INTERNAL_CreateOrSetMenu(v_act_id, v_root_menu_sid, 'csr_properties_menu', 'Property', '/csr/site/property/properties/List.acds', 2, null, TRUE, v_property_menu_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_property_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Property / Properties
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'gp_properties_myproperties', 'Properties', '/csr/site/property/properties/List.acds', 1, null, TRUE, v_new_menu_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Property / Properties / 'Create New'
	INTERNAL_CreateOrSetMenu(v_act_id, v_new_menu_sid, 'gp_properties_createnew', 'Create property', '/csr/site/property/properties/New.acds', 1, null, TRUE, v_new_sub_menu_sid);
	-- Property manager can't create properties by default
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_sub_menu_sid), v_role_sid);

	-- Property / Management Companies
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_management_company', 'Management companies', '/csr/site/property/admin/managementCompanyList.acds', 2, null, TRUE, v_new_menu_sid);

	-- Property / Funds
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_fund', 'Funds', '/csr/site/property/admin/fundList.acds', 3, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin
	INTERNAL_CreateOrSetMenu(v_act_id, v_admin_menu_sid, 'csr_property_admin_menu', 'Property admin', '/csr/site/property/admin/menu.acds', null, null, TRUE, v_property_menu_sid);

	-- Admin / Property Admin / Property types
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_property_type', 'Property types', '/csr/site/property/admin/propertyTypeList.acds', 1, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Space types
	INTERNAL_CreateOrSetMenu(v_act_id, v_setup_menu_sid, 'csr_property_admin_space_type', 'Space types', '/csr/site/property/admin/spaceTypeList.acds', 2, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Fund types
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_fund_type', 'Fund types', '/csr/site/property/admin/fundTypeList.acds', 3, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Property settings
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_property_options', 'Property settings', '/csr/site/property/admin/propertyOptions.acds', 4, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Region metrics
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_region_metric', 'Region metrics', '/csr/site/property/admin/regionMetricList.acds', 5, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Tenants
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_tenant', 'Tenants', '/csr/site/property/admin/tenantList.acds', 6, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Layout
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_characteristics', 'Layout', '/csr/site/property/admin/propertyCharacteristics.acds', 7, null, TRUE, v_new_menu_sid);

	-- Admin / Property Admin / Tabs
	INTERNAL_CreateOrSetMenu(v_act_id, v_property_menu_sid, 'csr_property_admin_tabs', 'Tabs', '/csr/site/property/admin/propertytab.acds', 8, null, TRUE, v_new_menu_sid);

	INTERNAL_ResetTopMenuPositions;

	-- Remove old Property map menu (/csr/site/property/properties/Map.acds)... and it's child menus. Just in case they exist
	FOR r IN (
		 SELECT level, m.sid_id, m.description
		   FROM security.menu m
		   JOIN security.securable_object so
					 ON so.sid_id = m.sid_id
		  WHERE so.application_sid_id = v_app_sid
		  START WITH LOWER(m.action) = '/csr/site/property/properties/map.acds'
		CONNECT BY PRIOR so.sid_id = so.parent_sid_id
		  ORDER BY LEVEL DESC
	)
	LOOP
		security.securableobject_pkg.DeleteSO(v_act_id, r.sid_id);
	END LOOP;

	-- Create a default workflow if there isn't a flow on customer
	DECLARE
		v_prop_flow_sid security.security_pkg.T_SID_ID;
		v_xml 			CLOB;
		v_str 			VARCHAR2(2000);
		v_r0 			security.security_pkg.T_SID_ID;
		v_s0			security.security_pkg.T_SID_ID;
		v_s1			security.security_pkg.T_SID_ID;
	BEGIN
		FOR no_flow_check IN (
			SELECT * FROM dual
			 WHERE NOT EXISTS (SELECT * FROM customer WHERE app_sid = v_app_sid AND property_flow_sid IS NOT NULL)
		) LOOP
			INSERT INTO customer_flow_alert_class (flow_alert_class)
			VALUES ('property');

			flow_pkg.CreateFlow('Property workflow', v_flow_root_sid, 'property', v_prop_flow_sid);

			v_xml := '<';
			v_str := UNISTR('flow label="Property workflow" cmsTabSid="" default-state-id="$S1$"><state id="$S0$" label="Details entered" final="0" colour="" lookup-key="PROP_DETS_ENTERED"><attributes x="1078.5" y="801.5" /><role sid="$R0$" is-editable="1" /><transition to-state-id="$S1$" verb="Details required" helper-sp="" lookup-key="MARK_DETS_REQD" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state><state id="$S1$" label="Details required" final="0" colour="" lookup-key="PROP_DETS_REQD"><attributes x="726.5" y="799.5" /><role sid="$R0$" is-editable="1" /><transition to-state-id="$S0$" verb="Details entered" helper-sp="" lookup-key="MARK_DETS_ENTERED" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state></flow>');
			dbms_lob.writeappend(v_xml, LENGTH(v_str), v_str);

			-- roles
			role_pkg.SetRole('Property Manager', v_r0);

			-- states
			v_s0 := NVL(flow_pkg.GetStateId(v_prop_flow_sid, 'PROP_DETS_ENTERED'), flow_pkg.GetNextStateID);
			v_s1 := NVL(flow_pkg.GetStateId(v_prop_flow_sid, 'PROP_DETS_REQD'), flow_pkg.GetNextStateID);

			v_xml := REPLACE(v_xml, '$R0$', v_r0);
			v_xml := REPLACE(v_xml, '$S0$', v_s0);
			v_xml := REPLACE(v_xml, '$S1$', v_s1);

			flow_pkg.SetFlowFromXml(v_prop_flow_sid, XMLType(v_xml));

			 UPDATE customer
				SET property_flow_sid = v_prop_flow_sid
			  WHERE app_sid =  v_app_sid;
		END LOOP;
	END;

	BEGIN
		INSERT INTO ISSUE_TYPE (app_sid, issue_type_Id, label)
			VALUES (v_app_sid, 15, 'Property');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Support space region type
	BEGIN
		INSERT INTO customer_region_type (region_type)
		VALUES (csr_data_pkg.REGION_TYPE_SPACE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Set up basic plugins for managing properties, if there aren't any already
	FOR check_property_plugins IN (
		SELECT * FROM dual
		 WHERE NOT EXISTS (SELECT * FROM property_tab WHERE app_sid = v_app_sid)
	) LOOP
		v_plugin_id := plugin_pkg.GetPluginId('Controls.SpaceListMetricPanel');

		BEGIN
			INSERT INTO property_tab (plugin_id, plugin_type_id, pos, tab_label)
				VALUES (v_plugin_id, csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB, 1, 'Spaces');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE property_tab
				   SET pos=1
				 WHERE plugin_id = v_plugin_id;
		END;

		BEGIN
			INSERT INTO property_tab_group (plugin_id, group_sid)
				 VALUES (v_plugin_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/RegisteredUsers'));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	SELECT DECODE(compliance_pkg.IsModuleEnabled, 1 ,1 , DECODE(permit_pkg.IsModuleEnabled,1,1,0))
		INTO v_is_module_enable FROM dual;

	IF v_is_module_enable = 1 THEN
		SELECT MAX(pos)
		  INTO v_tab_pos
		  FROM property_tab;

		v_plugin_id := plugin_pkg.GetPluginId('Controls.ComplianceTab');

		BEGIN
			INSERT INTO property_tab (plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_plugin_id, csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB, v_tab_pos+1,'Compliance');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE property_tab
				   SET pos= v_tab_pos+1
				 WHERE plugin_id = v_plugin_id;
		END;

		BEGIN
			INSERT INTO property_tab_group (plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/RegisteredUsers'));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END IF;

	BEGIN
		v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id,
				v_app_sid,
				security.security_pkg.SO_CONTAINER,
				'Capabilities',
				v_capabilities_sid
			);
	END;

	BEGIN
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_capabilities_sid, 'Choose new property parent');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id,
				v_capabilities_sid,
				security.class_pkg.GetClassId('CSRCapability'),
				'Choose new property parent',
				v_capability_sid
			);
	END;

	-- don't inherit dacls
	security.securableobject_pkg.SetFlags(v_act_id, v_capability_sid, 0);
	-- clean existing ACE's
	security.acl_pkg.DeleteAllACEs(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_capability_sid));
	-- admins can read and change
	security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_capability_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				0, v_administrators_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_READ_PERMISSIONS + security.security_pkg.PERMISSION_CHANGE_PERMISSIONS);

	-- Add permissions to existing menus, web resources and tabs
	-- Permissions on Data entry
	v_new_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, '/data');
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	v_new_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, '/data/csr_portal_home');
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	SELECT MIN(tab_id) tab_id
	  INTO v_tab_id
	  FROM tab
	 WHERE name = 'My data';

	IF v_tab_id IS NOT NULL THEN
		portlet_pkg.AddTabForGroup(
			in_group_sid	=> v_role_sid,
			in_tab_id		=> v_tab_id);
	END IF;

	-- Permissions on Metering. This safely fails out if metering not enabled
	BEGIN
		-- meter base
		v_www_new_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site, 'meter');
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_new_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		csr_data_pkg.enablecapability('Edit region categories', 1);
		INTERNAL_AddAceForCapability('Edit region categories', v_role_sid);

		v_new_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, 'metering');
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		v_new_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, 'metering/csr_meter');
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		-- meter quick charts
		v_new_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, 'metering/meter_list');
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	-- setup property filter card
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Property.Filters.PropertyFilter';

	BEGIN
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (v_app_sid, chain.filter_pkg.FILTER_TYPE_PROPERTY, v_card_id, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- Enable geo-maps portlet
	portlet_pkg.EnablePortletForCustomer(csr_data_pkg.PORTLET_TYPE_GEOMAP);

	--Convert any existing region properties to properties in property module
	util_script_pkg.AddMissingProperties(in_property_type);

	-- Property document library is enabled by default for new clients
	EnablePropertyDocLib;
END;

FUNCTION GetEmissionFactorAdmin
RETURN security.security_pkg.T_SID_ID
AS
	v_act						security.security_pkg.T_ACT_ID;
	v_app						security.security_pkg.T_SID_ID;
	v_carbon_admins_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_act := security.security_pkg.GetAct;
	v_app := security.security_pkg.GetApp;
	BEGIN
		v_carbon_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups/Emission factor Admins');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				-- There are a handful of sites that have a different name for the Admin group.
				v_carbon_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups/Carbon Admins');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Emission factor Admins or Carbon Admins group not found.');
			END;
	END;
	RETURN v_carbon_admins_sid;
END;

PROCEDURE EnableEmFactorsProfileTool(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
)
AS
	v_act						security.security_pkg.T_ACT_ID;
	v_app						security.security_pkg.T_SID_ID;
	v_admin_menu_sid			NUMBER;
	v_menu_sid					NUMBER;
	v_carbon_admins_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_act := security.security_pkg.GetAct;
	v_app := security.security_pkg.GetApp;

	v_admin_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'menu/admin');
	v_carbon_admins_sid := GetEmissionFactorAdmin;

	IF in_enable > 0 THEN
		BEGIN
			security.menu_pkg.CreateMenu(
				in_act_id => v_act,
				in_parent_sid_id => v_admin_menu_sid,
				in_name => 'csr_site_admin_emissionFactors_manage',
				in_description => 'Manage emission factors',
				in_action => '/csr/site/admin/emissionFactors/new/manage.acds',
				in_pos => in_position,
				in_context => null,
				out_sid_id => v_menu_sid
			);

			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_carbon_admins_sid,
				security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.PropogateACEs(v_act, v_menu_sid);
		EXCEPTION
		  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL; -- link already exists
		END;

		BEGIN
			--Sequences start at 1 so safe to use 0
			INSERT INTO CSR.factor_set_group (FACTOR_SET_GROUP_ID, NAME, CUSTOM)
			VALUES (0, 'Custom factor set(s)', 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN NULL;
		END;

	ELSE
		-- Delete the menu, if present.
		BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'menu/admin/csr_site_admin_emissionFactors_manage');
			security.securableobject_pkg.DeleteSO(v_act, v_menu_sid);
		EXCEPTION
		  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
		END;
	END IF;
END;

PROCEDURE EnableEmFactorsClassicTool(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
)
AS
	v_act						security.security_pkg.T_ACT_ID;
	v_app						security.security_pkg.T_SID_ID;
	v_admin_menu_sid			NUMBER;
	v_menu_sid					NUMBER;
	v_carbon_admins_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_act := security.security_pkg.GetAct;
	v_app := security.security_pkg.GetApp;

	v_admin_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'menu/admin');
	v_carbon_admins_sid := GetEmissionFactorAdmin;

	IF in_enable > 0 THEN
		BEGIN
			security.menu_pkg.CreateMenu(
				in_act_id => v_act,
				in_parent_sid_id => v_admin_menu_sid,
				in_name => 'csr_admin_emission_factors',
				in_description => 'Emission factors',
				in_action => '/csr/site/admin/emissionFactors/emissionFactors.acds',
				in_pos => in_position,
				in_context => null,
				out_sid_id => v_menu_sid
			);

			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_carbon_admins_sid,
				security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.PropogateACEs(v_act, v_menu_sid);
		EXCEPTION
		  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL; -- link already exists
		END;
	ELSE
		-- Delete the menu, if present.
		BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'menu/admin/csr_admin_emission_factors');
			security.securableobject_pkg.DeleteSO(v_act, v_menu_sid);
		EXCEPTION
		  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
		END;
	END IF;
END;

PROCEDURE EnableDocLibDocTypes
AS
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_root_menu_sid					security.security_pkg.T_SID_ID;
	v_setup_menu_sid				security.security_pkg.T_ACT_ID;
	v_doctypes_menu_sid				security.security_pkg.T_ACT_ID;
	v_superadmins_sid				security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_ACT_ID;
	v_www_doclib					security.security_pkg.T_ACT_ID;
	v_www_doctypes					security.security_pkg.T_ACT_ID;
BEGIN
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;

	v_superadmins_sid := security.securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> 0,
		in_path						=> 'csr/SuperAdmins'
	);

	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'menu'
	);

	v_www_root := security.securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'wwwroot'
	);

	v_www_doclib := security.securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'wwwroot/csr/site/doclib'
	);

	BEGIN
		security.web_pkg.CreateResource(
			in_act_id				=> v_act_id,
			in_web_root_sid_id		=> v_www_root,
			in_parent_sid_id		=> v_www_doclib,
			in_page_name			=> 'setup',
			in_rewrite_path			=> NULL,
			out_page_sid_id			=> v_www_doctypes
		);
		security.securableObject_pkg.ClearFlag(
			in_act_id				=> v_act_id,
			in_sid_id				=> v_www_doctypes,
			in_flag					=> security.security_pkg.SOFLAG_INHERIT_DACL
		);
		security.acl_pkg.DeleteAllACEs(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_www_doctypes)
		);
		security.acl_pkg.AddACE(
			in_act_id				=> v_act_id,
			in_acl_id				=> security.acl_pkg.GetDACLIDForSID(v_www_doctypes),
			in_acl_index			=> -1,
			in_ace_type				=> security.security_pkg.ACE_TYPE_ALLOW,
			in_ace_flags			=> security.security_pkg.ACE_FLAG_DEFAULT,
			in_sid_id				=> v_superadmins_sid,
			in_permission_set		=> security.security_pkg.PERMISSION_STANDARD_ALL
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_root_menu_sid,
		in_path						=> 'setup'
	);

	BEGIN
		security.menu_pkg.CreateMenu(
			in_act_id				=> v_act_id,
			in_parent_sid_id		=> v_setup_menu_sid,
			in_name					=> 'csr_doclib_doctype_setup',
			in_description			=> 'Document types',
			in_action				=> '/csr/site/doclib/setup/doctypes.acds',
			in_pos					=> NULL,
			in_context				=> NULL,
			out_sid_id				=> v_doctypes_menu_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE EnableForecasting
AS
	v_sid							security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_site					security_pkg.T_SID_ID;
	v_www_csr_site_forecasting		security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_menu_forecasting				security_pkg.T_SID_ID;
	v_forecasting_alert_type_id		NUMBER;
BEGIN
	-- Adding container
	BEGIN
		security.Securableobject_Pkg.CreateSO(v_act_id, v_app_sid,
			security.security_pkg.SO_CONTAINER, forecasting_pkg.FORECASTING_FOLDER, v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Web resource
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');

	BEGIN
		v_www_csr_site_forecasting := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'forecasting');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(
				in_act_id => v_act_id,
				in_web_root_sid_id => v_www_sid,
				in_parent_sid_id => v_www_csr_site,
				in_page_name => 'forecasting',
				in_rewrite_path => null,
				out_page_sid_id => v_www_csr_site_forecasting
			);
	END;

	-- Add administrators to web resource
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_forecasting), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);


	-- Add menu item.
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_admin_forecasting_forecastinglist', 'Forecasting', '/csr/site/forecasting/ForecastingList.acds', -1, null, v_menu_forecasting);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Setting default max number of slots
	UPDATE customer
	   SET forecasting_slots = 4
	 WHERE app_sid = security.security_pkg.GetApp;


	--Create the alerts
	BEGIN
		v_forecasting_alert_type_id := csr_data_pkg.ALERT_FORECASTING_SCENARIO;

		INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		VALUES (security.security_pkg.GetApp, customer_alert_type_id_seq.nextval, v_forecasting_alert_type_id);

		INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT security.security_pkg.GetApp, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
		  FROM alert_frame af
		  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
		 WHERE af.app_sid = security.security_pkg.GetApp
		   AND cat.std_alert_type_id = v_forecasting_alert_type_id
		 GROUP BY cat.customer_alert_type_id
		HAVING MIN(af.alert_frame_id) > 0;

		INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT security.security_pkg.GetApp, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
		  FROM default_alert_template_body d
		  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
		  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
		  CROSS JOIN aspen2.translation_set t
		 WHERE d.std_alert_type_id = v_forecasting_alert_type_id
		   AND d.lang='en'
		   AND t.application_sid = security.security_pkg.GetApp
		   AND cat.app_sid = security.security_pkg.GetApp;

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

END;

PROCEDURE EnableAuditsApi
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_www_sid						security_pkg.T_SID_ID;
	v_api_resource_sid				security_pkg.T_SID_ID;
	v_health_resource_sid			security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_regusers_sid					security_pkg.T_SID_ID;
	v_everyone_sid					security_pkg.T_SID_ID;
BEGIN
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'wwwroot');

	BEGIN
		v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.audits');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		BEGIN
			v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups');
			v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
			v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Everyone');

			security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.audits', v_api_resource_sid);
			security.web_pkg.CreateResource(v_act, v_www_sid, v_api_resource_sid, 'health', v_health_resource_sid);

			INTERNAL_AddACE_NoDups(
				v_act, acl_pkg.GetDACLIDForSID(v_api_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

			INTERNAL_AddACE_NoDups(
				v_act, acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
	END;
END;

PROCEDURE EnableCmsApi
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_www_sid						security_pkg.T_SID_ID;
	v_api_resource_sid				security_pkg.T_SID_ID;
	v_health_resource_sid			security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_regusers_sid					security_pkg.T_SID_ID;
	v_everyone_sid					security_pkg.T_SID_ID;
BEGIN
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'wwwroot');

	BEGIN
		v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.cms');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		BEGIN
			v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups');
			v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
			v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Everyone');

			security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.cms', v_api_resource_sid);
			security.web_pkg.CreateResource(v_act, v_www_sid, v_api_resource_sid, 'health', v_health_resource_sid);

			INTERNAL_AddACE_NoDups(v_act, acl_pkg.GetDACLIDForSID(v_api_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

			INTERNAL_AddACE_NoDups(
				v_act, acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
	END;
END;

PROCEDURE EnableScheduledExportApi(
	in_enable			IN	NUMBER
)
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_www_sid						security_pkg.T_SID_ID;
	v_api_resource_sid				security_pkg.T_SID_ID;
	v_health_resource_sid			security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_regusers_sid					security_pkg.T_SID_ID;
	v_everyone_sid					security_pkg.T_SID_ID;
BEGIN
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'wwwroot');
	BEGIN
		IF in_enable > 0 THEN
			BEGIN
				v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.scheduledExport');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				BEGIN
					v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups');
					v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
					v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Everyone');

					security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.scheduledExport', v_api_resource_sid);
					INTERNAL_AddACE_NoDups(v_act, acl_pkg.GetDACLIDForSID(v_api_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

					security.web_pkg.CreateResource(v_act, v_www_sid, v_api_resource_sid, 'health', v_health_resource_sid);
					INTERNAL_AddACE_NoDups(v_act, acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);
				END;
			END;
		ELSE
			BEGIN
				v_health_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.scheduledExport/health');
				v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.scheduledExport');

				security.web_pkg.DeleteResource(v_act, v_health_resource_sid);
				security.web_pkg.DeleteResource(v_act, v_api_resource_sid);
			END;
		END IF;
	END;
END;

PROCEDURE EnableForms
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_sid 							security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
	v_superadmin_sid				security_pkg.T_SID_ID;
	v_app_resource_sid				security_pkg.T_SID_ID;
	v_api_resource_sid				security_pkg.T_SID_ID;
	v_health_resource_sid			security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_regusers_sid					security_pkg.T_SID_ID;
	v_everyone_sid					security_pkg.T_SID_ID;
	v_tenant_id						VARCHAR2(255);
BEGIN
	v_superadmin_sid := security.securableobject_pkg.getsidfrompath(v_act, 0, 'csr/SuperAdmins');
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'wwwroot');
	v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups');
	v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
	v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Everyone');

	BEGIN
		SELECT tenant_id
		  INTO v_tenant_id
		  FROM security.tenant
		 WHERE application_sid_id = v_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Please create a tenant ID first from: "csr/site/admin/SuperAdmin/tenantIdGeneration.acds"');
	END;

	-- Web resources.
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'ui.formeditor', v_sid);

		security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'app', v_app_resource_sid);
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security.securableobject_pkg.getsidfrompath(v_act, v_app_sid, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- Make sure permissions aren't inheritable if resource already exists (for example if created from enabling Suggestions).
			v_app_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'app');
			security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.securableobject_pkg.getsidfrompath(v_act, v_app_sid, 'Groups/RegisteredUsers'));
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security.securableobject_pkg.getsidfrompath(v_act, v_app_sid, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Enable here for superadmin login on sites that may not have SSO setup.
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_app_resource_sid, 'ui.signin', v_sid);

		security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	-- Create web resource for sign-in UI resources (bundles etc).
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'ui.signin', v_sid);
		security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_app_resource_sid, 'ui.formeditor', v_sid);

		security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Create web resource for API
	BEGIN
		v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.forms');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		BEGIN
			security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.forms', v_api_resource_sid);
			security.web_pkg.CreateResource(v_act, v_www_sid, v_api_resource_sid, 'health', v_health_resource_sid);

			INTERNAL_AddACE_NoDups(v_act, acl_pkg.GetDACLIDForSID(v_api_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);
			INTERNAL_AddACE_NoDups(v_act, acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
	END;

	-- Create menu item.
	DECLARE
		v_admin_menu_sid		security.security_pkg.T_SID_ID;
	BEGIN
		v_admin_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act, v_app_sid, 'menu/setup');

		security.menu_pkg.CreateMenu(
			in_act_id => v_act,
			in_parent_sid_id => v_admin_menu_sid,
			in_name => 'formeditor',
			in_description => 'Form editor',
			in_action => '/app/ui.formeditor/formeditor',
			in_pos => NULL,
			in_context => NULL,
			out_sid_id => v_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_sid := security.securableObject_pkg.GetSidFromPath(v_act, v_app_sid, 'menu/setup/formeditor');
	END;

	security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act, security.acl_pkg.GetDACLIDForSID(v_sid));
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
END;

PROCEDURE EnablePropertyDocLib
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_lib_sid						security_pkg.T_SID_ID;
	v_lib_daclid					security.securable_object.dacl_id%TYPE;
	v_admins						security_pkg.T_SID_ID;
	v_registered_users				security_pkg.T_SID_ID;
	v_parent_menu					security_pkg.T_SID_ID;
	v_menu_item						security_pkg.T_SID_ID;
	v_menu_item_dacl				security.securable_object.dacl_id%TYPE;
	v_doclib_web_resource			security_pkg.T_SID_ID;
	v_doclib_web_resource_dacl		security.securable_object.dacl_id%TYPE;
	v_root_menu						security_pkg.T_SID_ID;
	v_doc_folder					security_pkg.T_SID_ID;
BEGIN
	BEGIN
		doc_lib_pkg.CreateLibrary(
			in_parent_sid_id		=> v_app_sid,
			in_library_name			=> 'PropertyDocuments',
			in_documents_name		=> 'Documents',
			in_trash_name			=> 'Recycle Bin',
			in_app_sid				=> v_app_sid,
			out_doc_library_sid		=> v_lib_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_lib_sid := property_pkg.GetPropertyDocLib;
	END;

	v_doc_folder := securableobject_pkg.GetSIDFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_lib_sid,
		in_path						=> 'Documents'
	);

	securableobject_pkg.ClearFlag(
		in_act_id					=> v_act_id,
		in_sid_id					=> v_lib_sid,
		in_flag						=> security_pkg.SOFLAG_INHERIT_DACL
	);

	-- Clear ACL
	v_lib_daclid := acl_pkg.GetDACLIDForSID(v_lib_sid);
	acl_pkg.DeleteAllACEs(
		in_act_id					=> v_act_id,
		in_acl_id 					=> v_lib_daclid
	);

	-- Read/write for admins
	v_admins := securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'Groups/Administrators'
	);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_lib_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_admins,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Read only for other users (property workflow permission check will also apply)
	v_registered_users := securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'Groups/RegisteredUsers'
	);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_lib_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> 0, -- Not inheritable
		in_sid_id					=> v_registered_users,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
	);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> acl_pkg.GetDACLIDForSID(v_doc_folder),
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_registered_users,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
	);

	acl_pkg.PropogateACEs(
		in_act_id					=> v_act_id,
		in_parent_sid_id			=> v_lib_sid
	);


	v_root_menu := security.securableobject_pkg.GetSIDFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'menu'
	);

	-- Look for parent menu item
	BEGIN
		v_parent_menu := securableobject_pkg.GetSIDFromPath(
			in_act						=> v_act_id,
			in_parent_sid_id			=> v_root_menu,
			in_path						=> 'csr_properties_menu'
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				-- Fall back to data entry menu if properties menu is missing
				v_parent_menu := securableobject_pkg.GetSIDFromPath(
					in_act						=> v_act_id,
					in_parent_sid_id			=> v_root_menu,
					in_path						=> 'data'
				);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					-- Create properties menu with the doclib as the default action
					security.menu_pkg.CreateMenu(
						in_act_id					=> v_act_id,
						in_parent_sid_id			=> v_root_menu,
						in_name						=> 'csr_properties_menu',
						in_description				=> 'Property',
						in_action					=> '/csr/site/doclib/doclib.acds?lib=' || v_lib_sid,
						in_pos						=> 2,
						in_context					=> NULL,
						out_sid_id					=> v_parent_menu
					);

					acl_pkg.AddACE(
						in_act_id					=> v_act_id,
						in_acl_id					=> security.acl_pkg.GetDACLIDForSID(v_parent_menu),
						in_acl_index				=> -1,
						in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
						in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
						in_sid_id					=> v_registered_users,
						in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
					);
			END;
	END;

	-- Create menu item
	BEGIN
		v_menu_item := securableobject_pkg.GetSidFromPath(
			in_act				=> v_act_id,
			in_parent_sid_id	=> v_parent_menu,
			in_path				=> 'csr_properties_doclib'
		);

		security.menu_pkg.SetMenu(
			in_act_id			=> v_act_id,
			in_sid_id			=> v_menu_item,
			in_description		=> 'Documents',
			in_action			=> '/csr/site/doclib/doclib.acds?lib=' || v_lib_sid,
			in_pos				=> NULL,
			in_context			=> NULL
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(
				in_act_id				=> v_act_id,
				in_parent_sid_id		=> v_parent_menu,
				in_name					=> 'csr_properties_doclib',
				in_description			=> 'Documents',
				in_action				=> '/csr/site/doclib/doclib.acds?lib=' || v_lib_sid,
				in_pos					=> NULL,
				in_context				=> NULL,
				out_sid_id				=> v_menu_item
			);
	END;

	-- Visible to all
	v_menu_item_dacl := security.acl_pkg.GetDACLIDForSID(v_menu_item);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_menu_item_dacl,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_registered_users,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
	);

	-- Web resource (shared with standard doclib)
	BEGIN
		v_doclib_web_resource := securableobject_pkg.GetSidFromPath(
			in_act					=> v_act_id,
			in_parent_sid_id		=> v_app_sid,
			in_path					=> 'wwwroot/csr/site/doclib'
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			DECLARE
				v_www_root			security_pkg.T_SID_ID := securableobject_pkg.GetSidFromPath(
					in_act				=> v_act_id,
					in_parent_sid_id	=> v_app_sid,
					in_path				=> 'wwwroot'
				);
				v_www_csr_site		security_pkg.T_SID_ID := securableobject_pkg.GetSidFromPath(
					in_act				=> v_act_id,
					in_parent_sid_id	=> v_www_root,
					in_path				=> 'csr/site'
				);
			BEGIN
				security.web_pkg.CreateResource(
					in_act_id			=> v_act_id,
					in_web_root_sid_id	=> v_www_root,
					in_parent_sid_id	=> v_www_csr_site,
					in_page_name		=> 'doclib',
					in_rewrite_path		=> NULL,
					out_page_sid_id		=> v_doclib_web_resource
				);
			END;
	END;

	v_doclib_web_resource_dacl := security.acl_pkg.GetDACLIDForSID(v_doclib_web_resource);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_doclib_web_resource_dacl,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_registered_users,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
	);

	-- Create initial property folders
	property_pkg.CreateMissingDocLibFolders;

	BEGIN
		INSERT INTO plugin
			(plugin_id, app_sid, plugin_type_id, description, js_include, js_class, cs_class,
			 details, preview_image_path)
		VALUES
			(plugin_id_seq.nextval,
			 v_app_sid,
			 csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
			 'Document library',
			 '/csr/site/property/properties/controls/DoclibTab.js',
			 'Credit360.Property.Controls.DocLibTab',
			 'Credit360.Property.Plugins.DocLibTab',
			 'Download and manage documents for a property. Documents saved in the tab will be '
				|| 'accessible from a folder in the property document library.',
			 '/csr/shared/plugins/screenshots/property_tab_doc_lib.png');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnableTranslationsImport
AS
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;
	v_admin_menu				security.security_pkg.T_SID_ID;
	v_translations_menu			security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
BEGIN

	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');

	BEGIN
		v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_menu, 'admin',  'Admin',  '/csr/site/userSettings/edit.acds',  0, null, v_admin_menu);
	END;

	BEGIN
		v_translations_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_admin_translations_import');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_admin_translations_import',  'Translations import',  '/csr/site/admin/translations/translationsImport.acds',  12, null, v_translations_menu);
	END;

	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_translations_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	csr_data_pkg.EnableCapability('Import core translations');

END;

PROCEDURE EnableProductCompliance
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_headers				NUMBER;
	v_tabs					NUMBER;
	v_top_company_sid		chain.company.company_sid%TYPE;
	v_top_company_type_id	chain.company.company_type_id%TYPE;
	v_aux					NUMBER;
BEGIN
	-- This procedure must be re-runnable.
	UPDATE chain.customer_options
	   SET enable_product_compliance = 1
	 WHERE app_sid = v_app_sid;

	chain.card_pkg.SetGroupCards('Product Filter', chain.T_STRING_LIST('Chain.Cards.Filters.ProductFilter', 'Credit360.Chain.Filters.ProductCompanyFilterAdapter', 'Credit360.Chain.Filters.ProductSupplierFilterAdapter', 'Chain.Cards.Filters.ProductCmsFilterAdapter'));
	chain.card_pkg.SetGroupCards('Product Supplier Filter', chain.T_STRING_LIST('Chain.Cards.Filters.ProductSupplierFilter', 'Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter', 'Chain.Cards.Filters.ProductSupplierProductFilterAdapter'));
	chain.card_pkg.SetGroupCards('Product Metric Value Filter', chain.T_STRING_LIST('Chain.Cards.Filters.ProductMetricValFilter', 'Chain.Cards.Filters.ProductMetricValProductFilterAdapter'));
	chain.card_pkg.SetGroupCards('Product Supplier Metric Value Filter', chain.T_STRING_LIST('Chain.Cards.Filters.ProductSupplierMetricValFilter', 'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter'));
	v_aux := chain.product_type_pkg.CreateRootProductType;

END;

PROCEDURE EnableQuestionLibrary
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;

	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;

	-- menu
	v_root_menu_sid					security_pkg.T_SID_ID;
	v_admin_menu_sid				security_pkg.T_SID_ID;
	v_library_menu_sid				security_pkg.T_SID_ID;
	v_menu_survey_list				security.security_pkg.T_SID_ID;
	v_pos							NUMBER;
	v_login_sid						security_pkg.T_SID_ID;
	v_logout_sid					security_pkg.T_SID_ID;
	v_menu_survey_config			security.security_pkg.T_SID_ID;

	-- web resources
	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_quicksurvey			security_pkg.T_SID_ID;
	v_www_csr_quicksurvey_library	security_pkg.T_SID_ID;
	v_www_csr_site					security_pkg.T_SID_ID;
	v_www_csr_surveys				security_pkg.T_SID_ID;
	v_www_api_question_library		security_pkg.T_SID_ID;
	v_www_api_question_core			security_pkg.T_SID_ID;
	v_surveys_sid					security_pkg.T_SID_ID;
	v_www_surveys_sid				security_pkg.T_SID_ID;
	v_audits_sid 					security_pkg.T_SID_ID;
	v_www_api_schema				security_pkg.T_SID_ID;
	v_www_app_sid					security_pkg.T_SID_ID;
	v_www_app_ui_surveys			security_pkg.T_SID_ID;

	v_www_survey_view				security_pkg.T_SID_ID;
	v_www_validatesharedkey			security_pkg.T_SID_ID;

	-- question library permissions
	v_question_libray_class_id		security_pkg.T_CLASS_ID;
	v_question_library_sid			security_pkg.T_SID_ID;
	v_approve_question_permission	security_pkg.T_PERMISSION := 65536; -- from surveys.question_library_pkg.PERMISSION_APPROVE_QUESTION
	v_publish_survey_permission		security_pkg.T_PERMISSION := 131072; -- from surveys.question_library_pkg.PERMISSION_PUBLISH_SURVEY
	v_question_library_admin_sid	security_pkg.T_SID_ID;
	v_question_library_editor_sid	security_pkg.T_SID_ID;
	v_surveys_class_sid 			security_pkg.T_SID_ID;

	-- SurveyAuthorisedGuest user sid
	v_sag_sid						security_pkg.T_SID_ID;
	v_sag_start_points				security_pkg.T_SID_IDS;
	v_registered_users_group_sid	security_pkg.T_SID_ID;
	v_www_csr_surveys_view			security_pkg.T_SID_ID;

	-- credit360 regions api
	v_www_credit360_regions			security_pkg.T_SID_ID;
	v_www_credit360_regions_health	security_pkg.T_SID_ID;

	-- credit360 measures api
	v_www_credit360_measures		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAdmin(v_act_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run EnableQuestionLibrary');
	END IF;

	v_www_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	v_admin_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'admin');
	v_login_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'login');
	v_logout_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'logout');

	v_groups_sid			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_regusers_sid			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_everyone_sid			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');

	-- new groups
	v_question_library_admin_sid := INTERNAL_CreateOrGetGroup(v_act_id, v_app_sid, 'Question library admins');
	v_question_library_editor_sid := INTERNAL_CreateOrGetGroup(v_act_id, v_app_sid, 'Question library editors');

	-- TODO: DETERMINE WHETHER QUICK SURVEYS IS ENABLED USING OTHER MEANS AS csr/site/quickSurvey IS PRESENT EVEN WHEN SURVEYS 1 HAS NOT BEEN ENABLED
	-- TODO: Change this after UI is moved to a new location and don't require the enabling of old surveys.
	BEGIN
		v_www_csr_quicksurvey := securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site/quickSurvey');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Surveys module must be enabled first');
	END;

	-- Surveys SO container
	BEGIN
		v_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Surveys');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Surveys', v_surveys_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_question_library_admin_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_question_library_editor_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-- Create web resource. It inherits quickSurvey ACLs (by default just Administrators)
	-- Technically we don't need this but it may be useful to push additional permissions here
	-- (e.g. for question library user types).
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_csr_quicksurvey, 'library', v_www_csr_quicksurvey_library);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_csr_quicksurvey_library), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_csr_quicksurvey_library), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_admin_sid, security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_csr_quicksurvey_library), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_editor_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- Web resource for survey view + builder
	v_www_csr_site := securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_csr_site, 'surveys', v_www_csr_surveys);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_csr_surveys), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.surveys', v_www_app_ui_surveys);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_app_ui_surveys), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- TODO: REMOVE THIS BLOCK AS IT'S A DUPLICATE OF EARLIER IN THE SCRIPT
	-- Web resource for to level survey - permissions for admins and question library admins
	v_www_surveys_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'Surveys');
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_surveys_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_admin_sid, security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_surveys_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_editor_sid, security_pkg.PERMISSION_STANDARD_ALL);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_surveys_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);

	security.acl_pkg.PropogateACEs(v_act_id, v_www_surveys_sid, NULL);

	BEGIN
		SELECT MIN(pos)
		  INTO v_pos
		  FROM security.menu
		 WHERE sid_id = securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin/csr_quicksurvey_admin');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_pos := NULL;
	END;

	/*** ADD MENU ITEMS ***/
	BEGIN
		SELECT m.sid_id
		  INTO v_library_menu_sid
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id AND application_sid_id = v_app_sid
		 WHERE action = '/csr/site/quickSurvey/library/library.acds';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INTERNAL_CreateOrSetMenu(v_act_id, v_admin_menu_sid, 'csr_question_library', 'Question library', '/csr/site/quickSurvey/library/library.acds', NVL(v_pos, 7), null, TRUE, v_library_menu_sid);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_library_menu_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_library_menu_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_admin_sid, security_pkg.PERMISSION_STANDARD_READ);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_library_menu_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_editor_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;

	BEGIN
		SELECT m.sid_id
		  INTO v_menu_survey_list
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id AND application_sid_id = v_app_sid
		 WHERE action = '/csr/site/quicksurvey/library/list.acds';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INTERNAL_CreateOrSetMenu(v_act_id, v_admin_menu_sid, 'csr_question_library_surveys', 'Question Library Surveys', '/csr/site/quicksurvey/library/list.acds', null, null, TRUE, v_menu_survey_list);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_menu_survey_list), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_menu_survey_list), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_admin_sid, security_pkg.PERMISSION_STANDARD_READ);
			INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_menu_survey_list), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_editor_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;

	BEGIN
		SELECT m.sid_id
		  INTO v_menu_survey_config
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id AND application_sid_id = v_app_sid
		 WHERE action = '/csr/site/surveys/config.acds';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INTERNAL_CreateOrSetMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup'), 'csr_surveys_config', 'Surveys Config', '/csr/site/surveys/config.acds', null, null, TRUE, v_menu_survey_config);
	END;

	UPDATE csr.customer
	   SET question_library_enabled = 1
	 WHERE app_sid = v_app_sid;

	-- Add Survey Campaign Response plugin
	--  plugin type 10 = 'Chain Company Tab'
	BEGIN
		INSERT INTO csr.plugin
			(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, app_sid, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Surveys 2 Campaign Responses',
			'/csr/site/chain/managecompany/controls/SurveyResponses.js', 'Chain.ManageCompany.SurveyResponses',
			'Credit360.Chain.Plugins.SurveyResponses', security.security_pkg.GetApp,
			'Displays a list of Surveys 2 Campaign Responses for the page company that the user has read access to. Includes a link to the survey for each response.');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Create web api web resources.
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.surveys', v_www_api_question_library);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_question_library), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.core', v_www_api_question_core);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_question_core), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- Web resource permissions
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.regions', v_www_credit360_regions);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_regions), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_credit360_regions, 'health', v_www_credit360_regions_health);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_regions_health), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.measures', v_www_credit360_measures);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_measures), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- Everyone can read on validatesharedkey endpoint.
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_api_question_library, 'surveyview', v_www_survey_view);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_survey_view, 'validatesharedkey', v_www_validatesharedkey);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_validatesharedkey), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- Question library permissions
	BEGIN
		v_question_libray_class_id := security.class_pkg.GetClassID('QuestionLibrary');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.class_pkg.CreateClass(v_act_id, NULL, 'QuestionLibrary', NULL, NULL, v_question_libray_class_id);
	END;

	BEGIN
		v_question_library_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'QuestionLibrary');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, v_question_libray_class_id, 'QuestionLibrary', v_question_library_sid);
			-- TODO: THESE LOOK LIKE DUPLICATE PERMISSINS AGAIN - INVESTIGATE
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'),
				security.security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_question_library_admin_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL + v_publish_survey_permission);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_surveys_sid), -1,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_question_library_editor_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_question_library_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL + v_approve_question_permission);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_question_library_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_admin_sid, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE + security_pkg.PERMISSION_DELETE + v_approve_question_permission);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_question_library_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_question_library_editor_sid, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE + security_pkg.PERMISSION_DELETE);

	EnableFileSharingApi;

	-- TODO: Set cards up for filtering

	-- create SurveyAuthorisedGuest
	BEGIN
		csr_user_pkg.INTERNAL_CreateUser(
			in_act			 			=> v_act_id,
			in_app_sid					=> v_app_sid,
			in_user_name				=> 'surveyauthorisedguest',
			in_password 				=> NULL,
			in_full_name				=> 'Anonymous',
			in_friendly_name			=> 'Anonymous',
			in_email		 			=> NULL,
			in_job_title				=> NULL,
			in_phone_number				=> NULL,
			in_info_xml					=> NULL,
			in_send_alerts				=> 0,
			in_enable_aria				=> 0,
			in_line_manager_sid			=> NULL,
			in_primary_region_sid		=> NULL,
			in_user_ref					=> NULL,
			in_account_expiry_enabled	=> 0,
			out_user_sid 				=> v_sag_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT csr_user_sid
			  INTO v_sag_sid
			  FROM csr_user
			  WHERE user_name = 'surveyauthorisedguest';
	END;

	-- hide the user
	UPDATE csr_user
	   SET hidden = 1
	 WHERE csr_user_sid = v_sag_sid;

	-- set some starting points so we don't get funny errors
	BEGIN
		csr_user_pkg.SetRegionStartPoints(v_sag_sid, v_sag_start_points);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	 -- remove user from registered users group
	v_registered_users_group_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
	group_pkg.DeleteMember(v_act_id, v_sag_sid, v_registered_users_group_sid);

	-- give user read-only permissions on itself
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_sag_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- web resources access for survey authorised guest
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_csr_surveys, 'view.acds', v_www_csr_surveys_view);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_csr_surveys_view), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_app_ui_surveys), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_question_core), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.PropogateACEs(v_act_id, v_www_api_question_core, NULL);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_question_library), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.PropogateACEs(v_act_id, v_www_api_question_library, NULL);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.schema', v_www_api_schema);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_schema), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_regions), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_measures), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- Permissions on login and logout buttons
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_login_sid), -2, security_pkg.ACE_TYPE_DENY, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_logout_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security_pkg.PERMISSION_STANDARD_READ);

	csr_data_pkg.EnableCapability('System management');
END;

PROCEDURE EnableFileSharingApi(
	in_provider_hint			IN	VARCHAR2 DEFAULT NULL,
	in_switch_confirmation		IN	NUMBER DEFAULT 0
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security_pkg.T_SID_ID;
	v_www_api_filesharing			security_pkg.T_SID_ID;
	v_www_api_filesharingfilestore	security_pkg.T_SID_ID;
	-- New user sid
	v_user_sid						security_pkg.T_SID_ID;
BEGIN
	/*
		Note: The two parameters aren't used here, but are picked up by enablePage.ashx.cs and passed on to the endpoint.
	*/

	IF NOT security_pkg.IsAdmin(v_act_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run EnableFileSharingApi');
	END IF;

	v_www_sid 			:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_regusers_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- Create web api web resources.
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.filesharing', v_www_api_filesharing);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_filesharing), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.filesharing.filestore', v_www_api_filesharingfilestore);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_filesharingfilestore), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);
END;


PROCEDURE EnablePermitsDocLib
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_lib_sid						security_pkg.T_SID_ID;
	v_doc_folder_daclid				security.securable_object.dacl_id%TYPE;
	v_doc_lib_daclid				security.securable_object.dacl_id%TYPE;
	v_admins						security_pkg.T_SID_ID;
	v_registered_users				security_pkg.T_SID_ID;
	v_ehs_managers					security_pkg.T_SID_ID;
	v_prop_managers					security_pkg.T_SID_ID;
	v_parent_menu					security_pkg.T_SID_ID;
	v_doclib_web_resource			security_pkg.T_SID_ID;
	v_doclib_web_resource_dacl		security.securable_object.dacl_id%TYPE;
	v_doc_folder					security_pkg.T_SID_ID;
	v_comp_lib_folder_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		security.SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'ComplianceDocLibs', v_comp_lib_folder_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_comp_lib_folder_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'ComplianceDocLibs');
	END;

	BEGIN
		doc_lib_pkg.CreateLibrary(
			in_parent_sid_id		=> v_comp_lib_folder_sid,
			in_library_name			=> 'Permits',
			in_documents_name		=> 'Documents',
			in_trash_name			=> 'Recycle bin',
			in_app_sid				=> v_app_sid,
			out_doc_library_sid		=> v_lib_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_lib_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_comp_lib_folder_sid, 'Permits');
	END;

	v_doc_folder := securableobject_pkg.GetSIDFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_lib_sid,
		in_path						=> 'Documents'
	);

	securableobject_pkg.ClearFlag(
		in_act_id					=> v_act_id,
		in_sid_id					=> v_lib_sid,
		in_flag						=> security_pkg.SOFLAG_INHERIT_DACL
	);

	-- Clear ACL
	v_doc_lib_daclid := acl_pkg.GetDACLIDForSID(v_lib_sid);
	acl_pkg.DeleteAllACEs(
		in_act_id					=> v_act_id,
		in_acl_id 					=> v_doc_lib_daclid
	);

	v_doc_folder_daclid := acl_pkg.GetDACLIDForSID(v_doc_folder);
	acl_pkg.DeleteAllACEs(
		in_act_id					=> v_act_id,
		in_acl_id 					=> v_doc_folder_daclid
	);

	-- Read/write for admins at top level
	v_admins := securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'Groups/Administrators'
	);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_doc_lib_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_admins,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Read/write for EHS Managers at documents level
	v_ehs_managers := securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'Groups/EHS Managers'
	);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_doc_folder_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_ehs_managers,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Read/write for Property Manager at documents level
	v_prop_managers := securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'Groups/Property Manager'
	);
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_doc_folder_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_prop_managers,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_ALL
	);

	-- Read only for other users (property workflow permission check will also apply)
	v_registered_users := securableobject_pkg.GetSidFromPath(
		in_act						=> v_act_id,
		in_parent_sid_id			=> v_app_sid,
		in_path						=> 'Groups/RegisteredUsers'
	);
	-- read/inheritable at documents level
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_doc_folder_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id					=> v_registered_users,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
	);

	-- read/not inheritable at doc lib level (so they can't access trash)
	acl_pkg.AddACE(
		in_act_id					=> v_act_id,
		in_acl_id					=> v_doc_lib_daclid,
		in_acl_index				=> -1,
		in_ace_type					=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags				=> 0, -- Not inheritable,
		in_sid_id					=> v_registered_users,
		in_permission_set			=> security_pkg.PERMISSION_STANDARD_READ
	);

	acl_pkg.PropogateACEs(
		in_act_id					=> v_act_id,
		in_parent_sid_id			=> v_lib_sid
	);

	UPDATE compliance_options
	   SET permit_doc_lib_sid = v_lib_sid
	 WHERE app_sid = v_app_sid;
END;

PROCEDURE EnablePermits
AS
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_count							NUMBER(10);
	v_plugin_id						plugin.plugin_id%TYPE;
	v_card_group_id					NUMBER(10);
	v_card_id						NUMBER(10);
	v_dummy_sid						security_pkg.T_SID_ID;
	v_permit_lib_menu				security_pkg.T_SID_ID;
	v_atg_menu						security_pkg.T_SID_ID;
	v_compliance_menu_sid			security_pkg.T_SID_ID;
	v_audit_menu_sid				security_pkg.T_SID_ID;
	v_ehs_managers_sid				security_pkg.T_SID_ID;
	v_property_manager_sid			security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_portlet_prop_mgr_tab_id		security_pkg.T_SID_ID;
	v_portlet_ehs_mgr_tab_id		security_pkg.T_SID_ID;
	v_portlet_sid					security_pkg.T_SID_ID;
	v_tab_portlet_id				tab_portlet.tab_portlet_id%TYPE;
	v_is_already_enabled 			BOOLEAN;
	v_score_type_id					NUMBER(10);
	v_only_permits_enabled			NUMBER(1);
BEGIN
	v_is_already_enabled := permit_pkg.IsModuleEnabled = 1;

	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run SetupModules');
	END IF;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class) VALUES ('permit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class) VALUES ('application');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class) VALUES ('condition');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	EnableComplianceBase;

	v_workflow_sid := permit_pkg.CreatePermitWorkflow();
	UPDATE compliance_options
	   SET permit_flow_sid = v_workflow_sid;

	v_workflow_sid := compliance_pkg.CreateApplicationWorkflow();
	UPDATE compliance_options
	   SET application_flow_sid = v_workflow_sid;

	v_workflow_sid := compliance_pkg.CreateConditionWorkflow();
	UPDATE compliance_options
	   SET condition_flow_sid = v_workflow_sid;

	v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
	role_pkg.SetRole('Property Manager', v_property_manager_sid);

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_permit_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_permit_type (permit_type_id, pos, description)
			SELECT permit_type_id, permit_type_id, description
			  FROM std_compl_permit_type;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_permit_sub_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_permit_sub_type (permit_type_id, permit_sub_type_id, pos, description)
			SELECT permit_type_id, permit_sub_type_id, permit_sub_type_id, description
			  FROM std_compl_permit_sub_type;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_condition_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_condition_type (condition_type_id, pos, description)
			SELECT condition_type_id, condition_type_id, description
			  FROM std_compl_condition_type;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_condition_sub_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_condition_sub_type (condition_type_id, condition_sub_type_id, pos, description)
			SELECT condition_type_id, condition_sub_type_id, condition_sub_type_id, description
			  FROM std_compl_condition_sub_type;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_activity_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_activity_type (activity_type_id, pos, description)
			SELECT activity_type_id, activity_type_id, description
			  FROM std_compl_activity_type;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_activity_sub_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_activity_sub_type (activity_type_id, activity_sub_type_id, pos, description)
			SELECT activity_type_id, activity_sub_type_id, activity_sub_type_id, description
			  FROM std_compl_activity_sub_type;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_application_type;

	IF v_count = 0 THEN
		INSERT INTO compliance_application_type (application_type_id, pos, description)
			SELECT application_type_id, application_type_id, description
			  FROM std_compl_application_type;
	END IF;

	-- add menu items
	v_compliance_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/csr_compliance');

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_compliance_menu_sid, 'csr_compliance_permit_library', 'Permits', '/csr/site/compliance/permitlist.acds', 4, null, v_permit_lib_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_permit_lib_menu := security.securableObject_pkg.GetSidFromPath(v_act_id, v_compliance_menu_sid, 'csr_compliance_permit_library');
	END;

	SELECT DECODE(compliance_pkg.IsModuleEnabled, 1, 0, DECODE(permit_pkg.IsModuleEnabled, 1, 1, 0))
	  INTO v_only_permits_enabled
	  FROM dual;

	IF v_only_permits_enabled = 1 THEN
		security.menu_pkg.SetMenuAction(v_act_id, v_compliance_menu_sid, '/csr/site/compliance/permitlist.acds');
	END IF;

	security.acl_pkg.PropogateACEs(v_act_id, v_compliance_menu_sid, v_permit_lib_menu);

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_permit_lib_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_property_manager_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- add menu items
	BEGIN
		v_audit_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/ia');

		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, v_audit_menu_sid, 'csr_audit_type_groups', 'Audit type groups', '/csr/site/audit/admin/auditTypeGroups.acds', 4, null, v_atg_menu);
			security.acl_pkg.PropogateACEs(v_act_id, v_audit_menu_sid, v_atg_menu);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_atg_menu := security.securableObject_pkg.GetSidFromPath(v_act_id, v_audit_menu_sid, 'csr_audit_type_groups');
		END;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	--plugins
	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Compliance.Controls.PermitDetailsTab');
	permit_pkg.SavePermitTab(
		in_plugin_id => v_plugin_id,
		in_tab_label => 'Details'
	);

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Compliance.Controls.PermitApplicationTab');
	permit_pkg.SavePermitTab(
		in_plugin_id => v_plugin_id,
		in_tab_label => 'Applications'
	);

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Compliance.Controls.PermitConditionsTab');
	permit_pkg.SavePermitTab(
		in_plugin_id => v_plugin_id,
		in_tab_label => 'Conditions'
	);

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Compliance.Controls.PermitActionsTab');
	permit_pkg.SavePermitTab(
		in_plugin_id => v_plugin_id,
		in_tab_label => 'Actions'
	);

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Compliance.Controls.DocLibTab');
	permit_pkg.SavePermitTab(
		in_plugin_id => v_plugin_id,
		in_tab_label => 'Documents'
	);

	v_plugin_id := plugin_pkg.GetPluginId('Credit360.Compliance.Controls.PermitScheduledActionsTab');
	permit_pkg.SavePermitTab(
		in_plugin_id => v_plugin_id,
		in_tab_label => 'Scheduled Actions'
	);

	chain.card_pkg.SetGroupCards('Compliance Permit Filter', chain.T_STRING_LIST('Credit360.Compliance.Filters.PermitFilter', 'Credit360.Compliance.Filters.PermitCmsFilterAdapter', 'Credit360.Compliance.Filters.PermitAuditFilterAdapter'));

	-- Add portlets
	SELECT MIN(tab_id)
	  INTO v_portlet_prop_mgr_tab_id
	  FROM csr.tab
	 WHERE name = 'Site compliance';

	SELECT MIN(tab_id)
	  INTO v_portlet_ehs_mgr_tab_id
	  FROM csr.tab
	 WHERE name = 'Permit compliance';

	 IF v_portlet_ehs_mgr_tab_id IS NULL THEN
		portlet_pkg.AddTabReturnTabId(
			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
			in_tab_name => 'Permit compliance',
			in_is_shared => 1,
			in_is_hideable => 1,
			in_layout => 6,
			in_portal_group => NULL,
			out_tab_id => v_portlet_ehs_mgr_tab_id
		);
	END IF;

	-- Add permissions on tabs.
	BEGIN
		INSERT INTO tab_group(group_sid, tab_id)
		VALUES(v_ehs_managers_sid, v_portlet_ehs_mgr_tab_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- EHS Manager portlet tab contents.
	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.GeoMap');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"portletHeight":460,"pickerMode":0,"filterMode":0,"selectedRegionList":[],"includeInactiveRegions":false,"colourBy":"permitRag","portletTitle":"Site Permit RAG Status"}',
			out_tab_portlet_id => v_tab_portlet_id
		);
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.SitePermitComplianceLevels');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '',
			out_tab_portlet_id => v_tab_portlet_id
		);

		UPDATE tab_portlet
		  SET column_num = 0, pos = 1
		WHERE tab_portlet_id = v_tab_portlet_id;
	END IF;


	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.Compliance.ActivePermitApplications');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '',
			out_tab_portlet_id => v_tab_portlet_id
		);

		UPDATE tab_portlet
		  SET column_num = 0, pos = 2
		WHERE tab_portlet_id = v_tab_portlet_id;
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.Compliance.PermitApplicationSummary');
	IF NOT IsPortletOnTab(v_portlet_ehs_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_ehs_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '',
			out_tab_portlet_id => v_tab_portlet_id
		);

		UPDATE tab_portlet
		  SET column_num = 0, pos = 3
		WHERE tab_portlet_id = v_tab_portlet_id;
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.Issue2');
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_portlet
	 WHERE tab_id = v_portlet_prop_mgr_tab_id
	   AND customer_portlet_sid = v_portlet_sid
	   AND DBMS_LOB.INSTR(state, '"defaultIssueType":'||csr_data_pkg.ISSUE_PERMIT ) > 0;
	IF v_count = 0 THEN	-- there is another property manager Issue2 portlet for permits, so can't just check that there's one already there.
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_prop_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"overdue":true,"unresolved":true,"resolved":false,"closed":false,"rejected":false,"defaultIssueType":'||csr_data_pkg.ISSUE_PERMIT||'}',
			out_tab_portlet_id => v_tab_portlet_id
		);
	END IF;

	v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.Compliance.NonCompliantConditions');
	IF NOT IsPortletOnTab(v_portlet_prop_mgr_tab_id, v_portlet_sid) THEN
		portlet_pkg.AddPortletToTab(
			in_tab_id => v_portlet_prop_mgr_tab_id,
			in_customer_portlet_sid => v_portlet_sid,
			in_initial_state => '{"portletHeight":250}',
			out_tab_portlet_id => v_tab_portlet_id
		);
	END IF;

	BEGIN
		INSERT INTO score_type (score_type_id, label, pos, hidden, allow_manual_set, lookup_key, applies_to_supplier, reportable_months)
		VALUES (score_type_id_seq.nextval, 'Permit RAG', 0, 0, 0, 'PERMIT_RAG', 0, 0)
		RETURNING score_type_id INTO v_score_type_id;

		INSERT INTO score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
		VALUES (score_threshold_id_seq.NEXTVAL, 'Poor',	89, 16712965, 16712965,	16712965, v_score_type_id);
		INSERT INTO score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
		VALUES (score_threshold_id_seq.NEXTVAL, 'Low',	94, 16770048, 16770048,	16770048, v_score_type_id);
		INSERT INTO score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
		VALUES (score_threshold_id_seq.NEXTVAL, 'Good',	100, 3777539, 3777539,	3777539, v_score_type_id);

		UPDATE csr.compliance_options SET permit_score_type_id = v_score_type_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			-- Must have been enabled already
			NULL;
	END;

	BEGIN
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'auditDtm','Date',1,75,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'label','Label',2,130,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'internalAuditTypeLabel','Audit type',3,100,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'surveyScore','Survey score',4,90,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'flowStateLabel','Status',5,80,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'auditClosureTypeLabel','Result',6,80,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'openNonCompliances','Open findings',7,60,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'surveyCompleted','Survey submitted',8,110,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'auditorFullName','Audit coordinator',9,100,0,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'regionDescription','Region',10,100,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'internalAuditSid','ID',11,75,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'regionPath','Region path',12,100,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'ncScore','Finding score',13,60,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'surveyLabel','Survey',14,100,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'auditorName','Auditor',15,100,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'auditorOrganisation','Auditor Organisation',16,120,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'auditorCompany','Auditor Company',17,120,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'notes','Notes',18,130,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'createdDtm','Created date',19,75,1,'csr_site_compliance_auditlist_');

		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (v_app_sid,41,'nextAuditDueDtm','Expiry date',20,75,1,'csr_site_compliance_auditlist_');
	EXCEPTION
		WHEN dup_val_on_index THEN
			-- Must have been enabled already
			NULL;
	END;

	EnablePermitsDocLib;

END;

FUNCTION IsApiIntegrationsEnabled RETURN BOOLEAN
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	-- web resources
	v_www_sid						security_pkg.T_SID_ID;
	v_www_api_integrations			security_pkg.T_SID_ID;
BEGIN
	v_www_sid 			:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	BEGIN
	v_www_api_integrations := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'api.integration');
	EXCEPTION
		WHEN OTHERS THEN
			RETURN FALSE;
	END;
	RETURN TRUE;
END;

PROCEDURE EnableApiIntegrations
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security_pkg.T_SID_ID;
	v_www_api_integrations			security_pkg.T_SID_ID;
BEGIN

	IF NOT security_pkg.IsAdmin(v_act_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run EnableApiIntegrations');
	END IF;

	IF IsApiIntegrationsEnabled = TRUE THEN
		RAISE_APPLICATION_ERROR(-20001, 'Api Integrations are already enabled');
	END IF;

	v_www_sid 			:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_regusers_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- Create web api web resources.
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.integration', v_www_api_integrations);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_integrations), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);
END;

PROCEDURE EnableHrIntegration(
	in_enable			IN	NUMBER
)
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_menu_sid						security_pkg.T_SID_ID;
	v_capability_sid				security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;

	IF in_enable > 0 THEN
		BEGIN
			security.menu_pkg.CreateMenu(
				in_act_id => v_act_id,
				in_parent_sid_id => security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin'),
				in_name => 'csr_staged_hr_profiles',
				in_description => 'Staged HR Profiles',
				in_action => '/csr/site/automatedExportImport/faileduserrows.acds',
				in_pos => null,
				in_context => null,
				out_sid_id => v_menu_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		csr_data_pkg.EnableCapability('View user profiles');
	ELSE
		BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin/csr_staged_hr_profiles');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/View user profiles');
			security.securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
		EXCEPTION
		  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
		END;
	END IF;
END;

PROCEDURE EnableRegionEmFactorCascading(
	in_enable			IN	NUMBER
)
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_capability_sid				security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security.security_pkg.getACT;

	IF in_enable > 0 THEN
		csr_data_pkg.EnableCapability('Region Emission Factor Cascading');
	ELSE
		DELETE FROM csr.factor
		 WHERE app_sid = v_app_sid
		   AND is_virtual <> 0;
		BEGIN
			v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/Region Emission Factor Cascading');
			security.securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
		EXCEPTION
		  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
		END;
	END IF;
END;

PROCEDURE EnableRegionFiltering
AS
BEGIN

	chain.card_pkg.SetGroupCards('Region Filter', chain.T_STRING_LIST('Credit360.Region.Filters.RegionFilter'));
END;

PROCEDURE EnableValuesApi
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security_pkg.T_SID_ID;
	v_www_api_values				security_pkg.T_SID_ID;
	v_www_credit360_indicators		security_pkg.T_SID_ID;
	v_www_credit360_measures		security_pkg.T_SID_ID;
	v_www_credit360_regions			security_pkg.T_SID_ID;
	v_www_credit360_scenarios		security_pkg.T_SID_ID;
BEGIN
	/*
		Note: The two parameters aren't used here, but are picked up by enablePage.ashx.cs and passed on to the endpoint.
	*/

	IF NOT security_pkg.IsAdmin(v_act_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run EnableValuesApi');
	END IF;

	v_www_sid 			:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_regusers_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	-- Create web api web resources.
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.values', v_www_api_values);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_api_values), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'credit360.indicators', v_www_credit360_indicators);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_indicators), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'credit360.measures', v_www_credit360_measures);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_measures), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'credit360.regions', v_www_credit360_regions);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_regions), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'credit360.scenarios', v_www_credit360_scenarios);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_credit360_scenarios), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

END;

PROCEDURE EnableOSHAModule
AS
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_admins_sid 			security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid 				security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_www_csr_site_osha		security.security_pkg.T_SID_ID;
	v_osha_admin_menu		security.security_pkg.T_SID_ID;
	v_admin_menu			security.security_pkg.T_SID_ID;
	v_menu_osha_export		security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.getACT;

	IF NOT security_pkg.IsAdmin(v_act_id) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run Enable OSHA Module');
	END IF;

	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	/*** WEB RESOURCES ***/
	-- add permissions on pre-created web-resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');

	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'osha', v_www_csr_site_osha);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_csr_site_osha := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'osha');
	END;

	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_osha), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Add menu for osha mapping page
	v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
			'csr_site_osha_admin_oshafieldmapping',
			'OSHA Mapping',
			'/csr/site/osha/admin/oshaFieldMapping.acds',
			null, null, v_osha_admin_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Add menu for osha export page
	BEGIN
		SELECT m.sid_id
		  INTO v_menu_osha_export
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id AND application_sid_id = v_app_sid
		 WHERE action = '/csr/site/osha/export.acds';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INTERNAL_CreateOrSetMenu(v_act_id, v_admin_menu, 'csr_site_osha_admin_export', 'OSHA Export', '/csr/site/osha/export.acds', null, null, TRUE, v_menu_osha_export);
			INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_osha_export), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
END;

PROCEDURE EnableBranding
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_class_id						security_pkg.T_CLASS_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_branding_admin_sid			security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;
	v_regusers_sid					security_pkg.T_SID_ID;
	v_admin_menu_sid				security_pkg.T_SID_ID;
	v_superadmins_sid				security_pkg.T_SID_ID;
	v_branding_menu					security_pkg.T_SID_ID;
	v_www_sid						security_pkg.T_SID_ID;
	v_www_ui_branding				security_pkg.T_SID_ID;
	v_www_ui_brandingnew			security_pkg.T_SID_ID;
	v_www_api_branding				security_pkg.T_SID_ID;
	v_www_auth						security_pkg.T_SID_ID;
	v_www_app_sid					security_pkg.T_SID_ID;
	v_www_app_ui_branding			security_pkg.T_SID_ID;
	v_www_app_ui_brandingnew		security_pkg.T_SID_ID;
	v_www_beta_menu_sid				security_pkg.T_SID_ID;
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run SetupModules');
	END IF;

	v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	v_class_id := security.class_pkg.GetClassID('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Branding Administrator', v_class_id, v_branding_admin_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_branding_admin_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Branding Administrator');
	END;

	-- Add superadmins to branding administrators because people keep messing with administrators group
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	-- Checks for dupes
	security.group_pkg.AddMember(v_act_id, v_superadmins_sid, v_branding_admin_sid);

	-- add menu item
	v_admin_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin');

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu_sid, 'ui.branding_branding', 'Branding tool', '/app/ui.branding/branding', 4, null, v_branding_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_branding_menu := security.securableObject_pkg.GetSidFromPath(v_act_id, v_admin_menu_sid, 'ui.branding_branding');
	END;

	security.acl_pkg.PropogateACEs(v_act_id, v_admin_menu_sid, v_branding_menu);
	-- Web resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.branding', v_www_ui_branding);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.brandingnew', v_www_ui_brandingnew);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.branding', v_www_app_ui_branding);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.brandingnew', v_www_app_ui_brandingnew);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.menu', v_www_beta_menu_sid);

	-- Branding admin branding menu ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_branding_menu), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_branding_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Branding admin wwwroot/ui.branding webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_branding), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_branding_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_brandingnew), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_branding_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Admin wwwroot/ui.branding webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_branding), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_brandingnew), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Branding admin wwwroot/app/ui.branding webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_branding), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_branding_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Admin wwwroot/app/ui.branding webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_branding), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_brandingnew), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- Admin wwwroot/ui.menu webresource ace
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_beta_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Create web api web resources.
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'api.branding', v_www_api_branding);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_branding), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'authorization', v_www_auth);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_auth), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Enable UI_DESIGN_TEMPLATE by default
	branding_pkg.EnableUlDesignSystem(in_value => 1);
END;

PROCEDURE EnableDataBuckets
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_dashbuckets_container_sid		security.security_pkg.T_SID_ID;
BEGIN

	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- Create the container
	-- Inherit the ACLs from the parent (ie site root) node
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_app_sid,
			security.security_pkg.SO_CONTAINER,
			'DataBuckets',
			v_dashbuckets_container_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_dashbuckets_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'DataBuckets');
	END;
END;


PROCEDURE EnableCredentialManagement(
		in_position			IN	NUMBER
)
AS
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;
	v_admin_menu				security.security_pkg.T_SID_ID;
	v_cm_menu					security.security_pkg.T_SID_ID;
	--
	v_www_root					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_www_resource				security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_regusers_sid				security.security_pkg.T_SID_ID;
BEGIN

	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	-- Bootstrap the Admin menu if not present (unlikely)
	v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu');
	BEGIN
		v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(
				in_act_id => v_act_id,
				in_parent_sid_id => v_menu,
				in_name => 'admin',
				in_description => 'Admin',
				in_action => '/csr/site/userSettings.acds',
				in_pos => 0,
				in_context => NULL,
				out_sid_id => v_admin_menu
			);
	END;

	-- Add the Admin | Credential Management menu
	BEGIN
		v_cm_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_site_admin_credential_management');
		security.menu_pkg.SetPos(
			in_act_id => v_act_id,
			in_sid_id => v_cm_menu,
			in_pos => in_position
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(
				in_act_id => v_act_id,
				in_parent_sid_id => v_admin_menu,
				in_name => 'csr_site_admin_credential_management',
				in_description => 'Credential Management',
				in_action => '/csr/site/credentialmanagement/credentialmanagementlist.acds',
				in_pos => in_position,
				in_context => NULL,
				out_sid_id => v_cm_menu
			);
	END;


	-- Add the webresource for Credential Management
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	BEGIN
		v_www_resource := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/credentialManagement');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'credentialManagement', v_www_resource);

			v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
			v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_resource), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END;
	END;

END;

PROCEDURE EnableManagedPackagedContent(
	in_package_name	IN VARCHAR2,
	in_package_ref	IN VARCHAR2
)
AS
	v_package_ref		VARCHAR2(1024);
	v_act				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_sid 				security_pkg.T_SID_ID;
	v_superadmin_sid	security_pkg.T_SID_ID;
BEGIN
	v_package_ref := in_package_ref || '-' || SYS_GUID();

	csr.managed_content_pkg.EnableManagedPackagedContent(in_package_name, v_package_ref);
END;

PROCEDURE EnableManagedContentRegistryUI
AS
	v_app_sid								security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id								security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_super_admin_setup_menu_sid			security_pkg.T_SID_ID;
	v_managed_content_registry_menu			security_pkg.T_SID_ID;
	v_www_sid								security_pkg.T_SID_ID;
	v_www_app_sid							security_pkg.T_SID_ID;
	-- v_www_ui_managedcontent_registry		security_pkg.T_SID_ID;
	v_www_app_ui_managedcontent_registry	security_pkg.T_SID_ID;
	v_super_admins_sid						security_pkg.T_SID_ID;
BEGIN
	-- add menu item
	v_super_admin_setup_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup');
	INTERNAL_CreateOrSetMenu(v_act_id, v_super_admin_setup_menu_sid, 'ui.managedcontent.registry', 'Managed Content Registry', '/app/ui.managedcontent.registry/managedcontentregistry', null, null, TRUE, v_managed_content_registry_menu);

	-- add web resource
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
	v_super_admins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.managedcontent.registry', v_www_app_ui_managedcontent_registry);
	security.securableobject_pkg.ClearFlag(v_act_id, v_www_app_ui_managedcontent_registry, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_managedcontent_registry));
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_app_ui_managedcontent_registry), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_super_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
END;

PROCEDURE EnableFrameworkDisclosures
AS
	v_app_sid								security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id								security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_question_library_enabled				customer.question_library_enabled%TYPE;
	v_flow_root_sid							security_pkg.T_SID_ID;
	v_disclosures_admin_sid					security_pkg.T_SID_ID;
	v_reg_users_sid							security_pkg.T_SID_ID;
	v_root_menu_sid							security_pkg.T_SID_ID;
	v_fd_menu_sid							security_pkg.T_SID_ID;
	v_fd_assignments_menu_sid				security_pkg.T_SID_ID;
	v_fd_disclosures_menu_sid				security_pkg.T_SID_ID;
	v_fd_frameworks_menu_sid				security_pkg.T_SID_ID;
	v_www_sid								security_pkg.T_SID_ID;
	v_www_app_sid							security_pkg.T_SID_ID;
	v_www_app_ui_disclosures				security_pkg.T_SID_ID;
	v_admins_sid							security_pkg.T_SID_ID;
BEGIN
	-- Make sure Surveys2 is enabled first
	SELECT question_library_enabled
	  INTO v_question_library_enabled
	  FROM csr.customer
	 WHERE app_sid = v_app_sid;
	IF v_question_library_enabled = 0 THEN
		RAISE_APPLICATION_ERROR(-20001,'Question Library not enabled on site. Enable Question Library first.');
		RETURN;
	END IF;

	-- Make sure Workflows is enabled first
	BEGIN
		v_flow_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Workflows');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'Workflows not enabled on site. Enable Workflows first.');
			RETURN;
	END;

	-- Adding a 'Framework Disclosure Admin' group. No need to use its returned sid value as this enable script will not automatically add any member to it.
	v_disclosures_admin_sid := INTERNAL_CreateOrGetGroup(v_act_id, v_app_sid, 'Framework Disclosure Admins');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
	security.group_pkg.AddMember(v_act_id, v_admins_sid, v_disclosures_admin_sid);

	-- Registered Users group
	v_reg_users_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');

	-- add Framework Disclosures menu item
	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	INTERNAL_CreateOrSetMenu(v_act_id, v_root_menu_sid, 'ui.disclosures_disclosures', 'ESG Disclosures', '/app/ui.disclosures/disclosures#/', 2, null, TRUE, v_fd_menu_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrSetMenu(v_act_id, v_fd_menu_sid, 'assignments', 'Assignments', '/app/ui.disclosures/disclosures#/', 1, null, TRUE, v_fd_assignments_menu_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_assignments_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrSetMenu(v_act_id, v_fd_menu_sid, 'disclosures', 'Disclosures', '/app/ui.disclosures/disclosures#/disclosures', 2, null, TRUE, v_fd_disclosures_menu_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_disclosures_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	INTERNAL_CreateOrSetMenu(v_act_id, v_fd_menu_sid, 'frameworks', 'Frameworks', '/app/ui.disclosures/disclosures#/frameworks', 3, null, TRUE, v_fd_frameworks_menu_sid);
	INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_frameworks_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_disclosures_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- add web resource
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'app', v_www_app_sid);
	INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_app_sid, 'ui.disclosures', v_www_app_ui_disclosures);
	security.securableobject_pkg.ClearFlag(v_act_id, v_www_app_ui_disclosures, security.security_pkg.SOFLAG_INHERIT_DACL);
	INTERNAL_AddACE_NoDups(v_act_id, acl_pkg.GetDACLIDForSID(v_www_app_ui_disclosures), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);

	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class) VALUES ('disclosure');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class) VALUES ('disclosureassignment');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE EnableIntegrationQuestionAnswer
AS
BEGIN
	-- Requires an app context, so has to be part of a client "enable" step.
	chain.card_pkg.SetGroupCards('Integration Question/Answers', chain.T_STRING_LIST('Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'));
END;

PROCEDURE EnableIntegrationQuestionAnswerApi
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_www_sid						security_pkg.T_SID_ID;
	v_api_resource_sid				security_pkg.T_SID_ID;
	v_groups_sid					security_pkg.T_SID_ID;
	v_regusers_sid					security_pkg.T_SID_ID;
BEGIN
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'wwwroot');

	BEGIN
		v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.integrationQuestionanswer');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		BEGIN
			v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups');
			v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
			security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.integrationQuestionanswer', v_api_resource_sid);
			INTERNAL_AddACE_NoDups(v_act, acl_pkg.GetDACLIDForSID(v_api_resource_sid), -1, security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
	END;
END;

PROCEDURE EnableSustainEssentials(
	in_include_cat	IN VARCHAR2
)
AS
BEGIN
	--sustain_essentials_pkg.EnableEssentials;
	NULL;
END;

PROCEDURE EnableDelegStatusOverview
AS
	v_admin_menu		security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'menu/Admin');
	v_sid				security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		-- This should be an enable script, or part of standard enable.
		security.menu_pkg.CreateMenu(
			in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_parent_sid_id	=> v_admin_menu,
			in_name				=> 'status_report',
			in_description		=> 'Delegation status overview',
			in_action			=> '/csr/site/delegation/manage/statusReport.acds',
			in_pos				=> NULL,
			in_context			=> NULL,
			out_sid_id			=> v_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE EnableMeasureConversionsPage
AS
	v_admin_menu		security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'menu/Admin');
	v_sid				security.security_pkg.T_SID_ID;
BEGIN

	BEGIN
		-- This should be an enable script, or part of standard enable.
		security.menu_pkg.CreateMenu(
			in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_parent_sid_id	=> v_admin_menu,
			in_name				=> 'csr_measure_conversions',
			in_description		=> 'Measure conversions',
			in_action			=> '/csr/site/schema/measureConversions/measureConversions.acds',
			in_pos				=> NULL,
			in_context			=> NULL,
			out_sid_id			=> v_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
END;

PROCEDURE EnableConsentSettings(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
)
AS
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;
	v_admin_menu				security.security_pkg.T_SID_ID;
	v_ga_menu					security.security_pkg.T_SID_ID;
	--
	v_www_root					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_www_resource				security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_regusers_sid				security.security_pkg.T_SID_ID;

	v_module_name				VARCHAR2(64) := 'Consent Settings';
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	IF in_enable = 1 THEN

		-- Bootstrap the Admin menu if not present (unlikely)
		v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu');
		BEGIN
			v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_menu,
					in_name => 'admin',
					in_description => 'Admin',
					in_action => '/csr/site/userSettings.acds',
					in_pos => 0,
					in_context => NULL,
					out_sid_id => v_admin_menu
				);
		END;

		-- Add the Admin | Consent Settings menu
		BEGIN
			v_ga_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_site_admin_consent_settings');
			security.menu_pkg.SetPos(
				in_act_id => v_act_id,
				in_sid_id => v_ga_menu,
				in_pos => in_position
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_admin_menu,
					in_name => 'csr_site_admin_consent_settings',
					in_description => 'Consent Settings',
					in_action => '/csr/site/admin/superadmin/consentSettings/consentSettings.acds',
					in_pos => in_position,
					in_context => NULL,
					out_sid_id => v_ga_menu
				);
				-- Menu should get admin dacl by inheritance.
		END;

		csr_data_pkg.EnableCapability('Google Analytics Management');
		-- Cap should get admin dacl by inheritance.

		LogEnable(v_module_name);

	ELSE

		-- remove it
		INTERNAL_DeleteMenu('Menu/admin/csr_site_admin_consent_settings');
		csr_data_pkg.DeleteCapability('Google Analytics Management');

		LogDisable(v_module_name);
	END IF;
END;

PROCEDURE EnableSuperadminSsoSite
AS
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_everyone_sid				security.security_pkg.T_SID_ID;
	v_sasso_resource_sid		security.security_pkg.T_SID_ID;
	v_sso_signon_sid			security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_login_resource_sid		security.security_pkg.T_SID_ID;
	v_resource_sid				security.security_pkg.T_SID_ID;	
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;
	v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Everyone');
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_sasso_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/sasso');

	BEGIN
		v_sso_signon_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_sasso_resource_sid, 'singlesignon.acds');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	IF v_sso_signon_sid IS NOT NULL THEN
		security.web_pkg.DeleteResource(v_act_id, v_sso_signon_sid);
	END IF;

	security.web_pkg.CreateResource(v_act_id, v_www_root, v_sasso_resource_sid, 'login', v_login_resource_sid);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_login_resource_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	UPDATE aspen2.application
	   SET logon_url = '/csr/sasso/login/superadminlogin.acds',
	   	   default_url = '/csr/sasso/login/superadminlogin.acds',
	       display_cookie_policy = 0
	 WHERE app_sid = v_app_sid;

END;

PROCEDURE EnableMaxMind(
	in_enable			IN	NUMBER
)
AS
BEGIN
	UPDATE aspen2.application
	   SET maxmind_enabled = in_enable
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE EnableTargetPlanning(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
)
AS
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;
	v_analysis_menu				security.security_pkg.T_SID_ID;
	v_tp_menu					security.security_pkg.T_SID_ID;
	--
	v_www_root					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_www_resource				security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_regusers_sid				security.security_pkg.T_SID_ID;

	v_module_name				VARCHAR2(64) := 'Target Planning';
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	IF in_enable = 1 THEN

		-- Bootstrap the Analysis menu if not present (unlikely)
		v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu');
		BEGIN
			v_analysis_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'analysis');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_menu,
					in_name => 'analysis',
					in_description => 'Analysis',
					in_action => '/csr/site/dataExplorer5/explorer.acds',
					in_pos => 0,
					in_context => NULL,
					out_sid_id => v_analysis_menu
				);
		END;

		-- Add the Analysis | Target Planning menu
		BEGIN
			v_tp_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_analysis_menu, 'csr_site_analysis_target_planning');
			security.menu_pkg.SetPos(
				in_act_id => v_act_id,
				in_sid_id => v_tp_menu,
				in_pos => in_position
			);
			security.menu_pkg.SetMenuAction(v_act_id, v_tp_menu, '/app/ui.targetplanning/targetplanning');
			security.menu_pkg.SetMenuDescription(v_act_id, v_tp_menu, 'Target Planning');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_analysis_menu,
					in_name => 'csr_site_analysis_target_planning',
					in_description => 'Target Planning',
					in_action => '/app/ui.targetplanning/targetplanning',
					in_pos => in_position,
					in_context => NULL,
					out_sid_id => v_tp_menu
				);
				-- Menu should get dacl by inheritance.
		END;

		csr_data_pkg.EnableCapability('Target Planning');
		-- Cap should get dacl by inheritance.

		LogEnable(v_module_name);

	ELSE

		-- remove it
		INTERNAL_DeleteMenu('Menu/analysis/csr_site_analysis_target_planning');
		csr_data_pkg.DeleteCapability('Target Planning');

		LogDisable(v_module_name);
	END IF;
END;

---------------------------------------

FUNCTION GetModuleId (
	in_module_name	IN	VARCHAR2
) RETURN NUMBER
AS
	v_module_id		NUMBER;
BEGIN
	SELECT module_id
	  INTO v_module_id
	  FROM module
	 WHERE module_name = in_module_name;

	IF v_module_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001,'Unknown Module Id');
	END IF;
	
	RETURN v_module_id;
END;

PROCEDURE LogEnable(
	in_module_name	IN	VARCHAR2
)
AS
	v_module_id		NUMBER;
BEGIN
	v_module_id := GetModuleId(in_module_name);

	UPDATE module_history
	   SET last_enabled_dtm = SYSDATE
	 WHERE module_id = v_module_id;

	IF SQL%ROWCOUNT = 0 THEN
		INSERT INTO module_history (module_id, enabled_dtm, last_enabled_dtm)
		VALUES (v_module_id, SYSDATE, SYSDATE);
	ELSE
		-- If we've just enabled it but it never had an initial enableddate set,
		-- perhaps due to a disable first, then set enabled = lastenabled
		UPDATE module_history
		   SET enabled_dtm = last_enabled_dtm
		 WHERE module_id = v_module_id
		   AND enabled_dtm IS NULL
		   AND last_enabled_dtm IS NOT NULL;
	END IF;

END;

PROCEDURE LogDisable(
	in_module_name	IN	VARCHAR2
)
AS
	v_module_id		NUMBER;
BEGIN
	v_module_id := GetModuleId(in_module_name);

	UPDATE module_history
	   SET disabled_dtm = SYSDATE
	 WHERE module_id = v_module_id;

	IF SQL%ROWCOUNT = 0 THEN
		INSERT INTO module_history (module_id, disabled_dtm)
		VALUES (v_module_id, SYSDATE);
	END IF;
END;

PROCEDURE LogDelete(
	in_module_name	IN	VARCHAR2
)
AS
	v_module_id		NUMBER;
BEGIN
	v_module_id := GetModuleId(in_module_name);

	DELETE module_history
	 WHERE module_id = v_module_id;
END;


END enable_pkg;
/
