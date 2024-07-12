CREATE OR REPLACE PACKAGE BODY csr.compliance_setup_pkg AS

PROCEDURE UpdateDefaultWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
)
AS
	v_workflow_sid					security_pkg.T_SID_ID := in_flow_sid;
	v_label							flow.label%TYPE;
	v_s1							security_pkg.T_SID_ID;
	v_s2							security_pkg.T_SID_ID;
	v_s3							security_pkg.T_SID_ID;
	v_s4							security_pkg.T_SID_ID;
	v_s5							security_pkg.T_SID_ID;
	v_s6							security_pkg.T_SID_ID;
	v_s7							security_pkg.T_SID_ID;
	v_r1							security_pkg.T_SID_ID;
	v_st1							security_pkg.T_SID_ID;
	v_st2							security_pkg.T_SID_ID;
	v_st3							security_pkg.T_SID_ID;
	v_st4							security_pkg.T_SID_ID;
	v_st5							security_pkg.T_SID_ID;
	v_st6							security_pkg.T_SID_ID;
	v_st7							security_pkg.T_SID_ID;
	v_st8							security_pkg.T_SID_ID;
	v_st9							security_pkg.T_SID_ID;
	v_st10							security_pkg.T_SID_ID;
	v_st11							security_pkg.T_SID_ID;
	v_st12							security_pkg.T_SID_ID;
	v_st13							security_pkg.T_SID_ID;
	v_st14							security_pkg.T_SID_ID;
	v_st15							security_pkg.T_SID_ID;
	v_st16							security_pkg.T_SID_ID;
	v_st17							security_pkg.T_SID_ID;
	v_st18							security_pkg.T_SID_ID;
	v_st19							security_pkg.T_SID_ID;
	v_st20							security_pkg.T_SID_ID;
	v_st21							security_pkg.T_SID_ID;
	v_st22							security_pkg.T_SID_ID;
	v_natures						compliance_pkg.flow_state_natures := compliance_pkg.INTERNAL_GetFlowStateNatures(in_class);
	v_retire_helper_sp				VARCHAR2(255);
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_groups_sid					security_pkg.T_SID_ID;
	v_class_id						security_pkg.T_SID_ID;
	v_ehs_managers_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT label
	  INTO v_label
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	csr.role_pkg.SetRole('Property Manager', v_r1);

	v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups');
	v_class_id := security.class_pkg.GetClassID('CSRUserGroup');
	BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'EHS Managers', v_class_id, v_ehs_managers_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
	END;

	-- Initiate variables and populate temp tables
	v_s1 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'NOT_CREATED'), flow_pkg.GetNextStateID);
	v_s2 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'NEW'), flow_pkg.GetNextStateID);
	v_s3 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'UPDATED'), flow_pkg.GetNextStateID);
	v_s4 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'RETIRED'), flow_pkg.GetNextStateID);
	v_s5 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'NOT_APPLICABLE'), flow_pkg.GetNextStateID);
	v_s6 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'COMPLIANT'), flow_pkg.GetNextStateID);
	v_s7 := NVL(flow_pkg.GetStateId(v_workflow_sid, 'ACTION_REQUIRED'), flow_pkg.GetNextStateID);

	
	v_retire_helper_sp := 'csr.compliance_pkg.OnLocalComplianceItemRetire';
	IF in_class = 'regulation' THEN
		csr.flow_pkg.SetStateTransHelper(v_workflow_sid, v_retire_helper_sp, 'On regulation retire');
	ELSE
		csr.flow_pkg.SetStateTransHelper(v_workflow_sid, v_retire_helper_sp, 'On requirement retire');
	END IF;

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 6,
		in_flow_state_id => v_s1,
		in_label => 'Not created',
		in_lookup_key => 'NOT_CREATED',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1030.5" y="662.3" />',
		in_flow_state_nature_id => null);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Create',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s2,
		in_label => 'New',
		in_lookup_key => 'NEW',
		in_is_final => 0,
		in_state_colour => '16755968',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_ehs_managers_sid,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1031" y="807" />',
		in_flow_state_nature_id => v_natures.new_item);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Updated',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st2);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_lock.gif',
		in_verb => 'Retire',
		in_lookup_key => '',
		in_helper_sp => v_retire_helper_sp,
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st3);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Not applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st4);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st5);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Action required',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st6);

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 1,
		in_flow_state_id => v_s3,
		in_label => 'Updated',
		in_lookup_key => 'UPDATED',
		in_is_final => 0,
		in_state_colour => '16770048',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_ehs_managers_sid,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="623.5" y="880" />',
		in_flow_state_nature_id => v_natures.updated);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_lock.gif',
		in_verb => 'Retire',
		in_lookup_key => '',
		in_helper_sp => v_retire_helper_sp,
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st7);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st8);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Not applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st9);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Action required',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st10);

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 2,
		in_flow_state_id => v_s7,
		in_label => 'Action Required',
		in_lookup_key => 'ACTION_REQUIRED',
		in_is_final => 0,
		in_state_colour => '16712965',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_ehs_managers_sid,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="625.5" y="1113" />',
		in_flow_state_nature_id => v_natures.action_required);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s7,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Not applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st11);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s7,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st12);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s7,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Updated',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st13);

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 3,
		in_flow_state_id => v_s6,
		in_label => 'Compliant',
		in_lookup_key => 'COMPLIANT',
		in_is_final => 0,
		in_state_colour => '3777539',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_ehs_managers_sid,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1029.5" y="1272" />',
		in_flow_state_nature_id => v_natures.compliant);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Not applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st14);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_lock.gif',
		in_verb => 'Retire',
		in_lookup_key => '',
		in_helper_sp => v_retire_helper_sp,
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st15);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Action required',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st16);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Updated',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st17);

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 4,
		in_flow_state_id => v_s5,
		in_label => 'Not Applicable',
		in_lookup_key => 'NOT_APPLICABLE',
		in_is_final => 0,
		in_state_colour => '10933610',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_ehs_managers_sid,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1436.5" y="1113" />',
		in_flow_state_nature_id => v_natures.not_applicable);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st18);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_lock.gif',
		in_verb => 'Retire',
		in_lookup_key => '',
		in_helper_sp => v_retire_helper_sp,
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st19);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Updated',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st20);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Action required',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st21);

	flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s7,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_lock.gif',
		in_verb => 'Retire',
		in_lookup_key => '',
		in_helper_sp => v_retire_helper_sp,
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st22);

	flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 5,
		in_flow_state_id => v_s4,
		in_label => 'Retired',
		in_lookup_key => 'RETIRED',
		in_is_final => 0,
		in_state_colour => '6644836',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_ehs_managers_sid,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1436.5" y="877" />',
		in_flow_state_nature_id => v_natures.retired);

	flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => v_label,
		in_flow_alert_class => in_class,
		in_cms_tab_sid => null,
		in_default_state_id => v_s1);
END;

PROCEDURE UpdatePermitWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
)
AS
	v_workflow_sid			security.security_pkg.T_SID_ID := in_flow_sid;
	v_act					security.security_pkg.T_ACT_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_s3					security.security_pkg.T_SID_ID;
	v_s4					security.security_pkg.T_SID_ID;
	v_s5					security.security_pkg.T_SID_ID;
	v_s6					security.security_pkg.T_SID_ID;
	v_s7					security.security_pkg.T_SID_ID;
	v_r1					security.security_pkg.T_SID_ID;
	v_g1					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
	v_st2					security.security_pkg.T_SID_ID;
	v_st3					security.security_pkg.T_SID_ID;
	v_st4					security.security_pkg.T_SID_ID;
	v_st5					security.security_pkg.T_SID_ID;
	v_st6					security.security_pkg.T_SID_ID;
	v_st7					security.security_pkg.T_SID_ID;
	v_st8					security.security_pkg.T_SID_ID;
	v_permit_ack_helper_sp	VARCHAR2(255);
BEGIN
	-- Initiate variables and populate temp tables
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'APPLICATION'), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'ACTIVE'), csr.flow_pkg.GetNextStateID);
	v_s3 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'REFUSED'), csr.flow_pkg.GetNextStateID);
	v_s4 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'NOT_CREATED'), csr.flow_pkg.GetNextStateID);
	v_s5 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'UPDATED'), csr.flow_pkg.GetNextStateID);
	v_s6 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'SURRENDERED'), csr.flow_pkg.GetNextStateID);
	v_s7 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'SURRENDER_ACKNOWLEDGED'), csr.flow_pkg.GetNextStateID);
	
	v_permit_ack_helper_sp := 'csr.compliance_pkg.UpdateConditionsOnAcknowledged';

	csr.flow_pkg.SetStateTransHelper(v_workflow_sid, v_permit_ack_helper_sp, 'On Surrender Acknowlege Conditions Inactive');
	csr.role_pkg.SetRole('Property Manager', v_r1);

	csr.flow_pkg.SetGroup('EHS Managers', v_g1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 1,
		in_flow_state_id => v_s1,
		in_label => 'Application',
		in_lookup_key => 'APPLICATION',
		in_is_final => 0,
		in_state_colour => '16755968',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="996.6" y="864" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_APPLICATION);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Granted',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Refused',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st2);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s4,
		in_label => 'Not created',
		in_lookup_key => 'NOT_CREATED',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="994.3" y="715.35" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_NOT_CREATED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s1,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Apply',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st3);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 3,
		in_flow_state_id => v_s2,
		in_label => 'Active',
		in_lookup_key => 'ACTIVE',
		in_is_final => 0,
		in_state_colour => '3777539',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="881.9" y="996" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_ACTIVE);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Update',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st4);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_return2.png',
		in_verb => 'Surrender',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st5);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 2,
		in_flow_state_id => v_s5,
		in_label => 'Updated',
		in_lookup_key => 'UPDATED',
		in_is_final => 0,
		in_state_colour => '16764928',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="635.9" y="996.9" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_UPDATED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_return2.png',
		in_verb => 'Surrender',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st6);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Acknowledge',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st7);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 4,
		in_flow_state_id => v_s6,
		in_label => 'Surrendered',
		in_lookup_key => 'SURRENDERED',
		in_is_final => 0,
		in_state_colour => '6644836',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="758" y="1137.4" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_SURRENDERED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Acknowledge',
		in_lookup_key => '',
		in_helper_sp => v_permit_ack_helper_sp,
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st8);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 5,
		in_flow_state_id => v_s7,
		in_label => 'Surrender Acknowledged',
		in_lookup_key => 'SURRENDER_ACKNOWLEDGED',
		in_is_final => 1,
		in_state_colour => '10329243',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="757.4" y="1276.5" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_SURR_ACK);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 6,
		in_flow_state_id => v_s3,
		in_label => 'Refused',
		in_lookup_key => 'REFUSED',
		in_is_final => 1,
		in_state_colour => '16712965',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1118.6" y="997.6" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_PERMIT_REFUSED);

	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => 'Permit Workflow',
		in_flow_alert_class => 'permit',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s4);
END;

PROCEDURE UpdatePermApplicationWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
)
AS
	v_workflow_sid			security.security_pkg.T_SID_ID := in_flow_sid;
	v_act					security.security_pkg.T_ACT_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_s3					security.security_pkg.T_SID_ID;
	v_s4					security.security_pkg.T_SID_ID;
	v_s5					security.security_pkg.T_SID_ID;
	v_s6					security.security_pkg.T_SID_ID;
	v_s7					security.security_pkg.T_SID_ID;
	v_s8					security.security_pkg.T_SID_ID;
	v_s9					security.security_pkg.T_SID_ID;
	v_s10					security.security_pkg.T_SID_ID;
	v_s11					security.security_pkg.T_SID_ID;
	v_r1					security.security_pkg.T_SID_ID;
	v_g1					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
	v_st2					security.security_pkg.T_SID_ID;
	v_st3					security.security_pkg.T_SID_ID;
	v_st4					security.security_pkg.T_SID_ID;
	v_st5					security.security_pkg.T_SID_ID;
	v_st6					security.security_pkg.T_SID_ID;
	v_st7					security.security_pkg.T_SID_ID;
	v_st8					security.security_pkg.T_SID_ID;
	v_st9					security.security_pkg.T_SID_ID;
	v_st10					security.security_pkg.T_SID_ID;
	v_st11					security.security_pkg.T_SID_ID;
	v_st12					security.security_pkg.T_SID_ID;
	v_st13					security.security_pkg.T_SID_ID;
	v_st14					security.security_pkg.T_SID_ID;
	v_st15					security.security_pkg.T_SID_ID;
	v_st16					security.security_pkg.T_SID_ID;
	v_st17					security.security_pkg.T_SID_ID;
	v_st18					security.security_pkg.T_SID_ID;
	v_st19					security.security_pkg.T_SID_ID;
	v_st20					security.security_pkg.T_SID_ID;

BEGIN
	-- Initiate variables and populate temp tables
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE-APPLICATION'), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'SUBMITTED'), csr.flow_pkg.GetNextStateID);
	v_s3 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'INQUIRY'), csr.flow_pkg.GetNextStateID);
	v_s4 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'WITHDRAWN'), csr.flow_pkg.GetNextStateID);
	v_s5 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'NOT_CREATED'), csr.flow_pkg.GetNextStateID);
	v_s6 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'RESPONDED'), csr.flow_pkg.GetNextStateID);
	v_s7 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'INFORMATION_REQUESTED'), csr.flow_pkg.GetNextStateID);
	v_s8 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'DULY_MADE'), csr.flow_pkg.GetNextStateID);
	v_s9 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'REFUSED'), csr.flow_pkg.GetNextStateID);
	v_s10 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CONSULTATION_APPEAL'), csr.flow_pkg.GetNextStateID);
	v_s11 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'DRAFT_RECEIVED'), csr.flow_pkg.GetNextStateID);

	csr.role_pkg.SetRole('Property Manager', v_r1);

	csr.flow_pkg.SetGroup('EHS Managers', v_g1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 1,
		in_flow_state_id => v_s1,
		in_label => 'Pre-application',
		in_lookup_key => 'PRE-APPLICATION',
		in_is_final => 0,
		in_state_colour => '16770048',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="561.75" y="686.3" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_PRE_APPLICATION);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Submit',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Inquire',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st2);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Abandon',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st3);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s5,
		in_label => 'Not created',
		in_lookup_key => 'NOT_CREATED',
		in_is_final => 0,
		in_state_colour => '6644836',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="326.25" y="684.5" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_NOT_CREATED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s1,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Create',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st4);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 2,
		in_flow_state_id => v_s3,
		in_label => 'Inquiry',
		in_lookup_key => 'INQUIRY',
		in_is_final => 0,
		in_state_colour => '16770048',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="425.2" y="943.3" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_PRE_APPLICATION);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_return.gif',
		in_verb => 'Respond',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st5);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 3,
		in_flow_state_id => v_s6,
		in_label => 'Responded',
		in_lookup_key => 'RESPONDED',
		in_is_final => 0,
		in_state_colour => '16770048',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="707.25" y="945.8" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_PRE_APPLICATION);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Submit',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st6);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s1,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Acknowledge',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st7);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Withdraw',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st8);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 4,
		in_flow_state_id => v_s2,
		in_label => 'Submitted',
		in_lookup_key => 'SUBMITTED',
		in_is_final => 0,
		in_state_colour => '16755968',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="934.75" y="686.2" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_INITIAL_CHECKS);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Information requested',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st9);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s8,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Duly made',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st10);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s9,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Determined',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st11);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 5,
		in_flow_state_id => v_s7,
		in_label => 'Information requested',
		in_lookup_key => 'INFORMATION_REQUESTED',
		in_is_final => 0,
		in_state_colour => '16755968',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="940.45" y="809.85" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_INITIAL_CHECKS);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s7,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Respond',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st12);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s7,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Withdraw',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st13);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 6,
		in_flow_state_id => v_s8,
		in_label => 'Duly made',
		in_lookup_key => 'DULY_MADE',
		in_is_final => 0,
		in_state_colour => '10933610',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1174.2" y="808.85" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_DETERMINATION);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s8,
		in_to_state_id => v_s9,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Determined',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st14);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s8,
		in_to_state_id => v_s10,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Information requested',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st15);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s8,
		in_to_state_id => v_s11,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Draft received',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st16);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 7,
		in_flow_state_id => v_s11,
		in_label => 'Draft received',
		in_lookup_key => 'DRAFT_RECEIVED',
		in_is_final => 0,
		in_state_colour => '10933610',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1471.95" y="940.8" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_DETERMINATION);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s11,
		in_to_state_id => v_s9,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Determined',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st17);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s11,
		in_to_state_id => v_s10,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Information requested',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st18);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 8,
		in_flow_state_id => v_s10,
		in_label => 'Paused, waiting information',
		in_lookup_key => 'CONSULTATION_APPEAL',
		in_is_final => 0,
		in_state_colour => '10933610',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1174.7" y="943.15" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_PAUSED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s10,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Withdraw',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st19);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s10,
		in_to_state_id => v_s8,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Request fulfilled',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st20);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 10,
		in_flow_state_id => v_s9,
		in_label => 'Determined',
		in_lookup_key => 'DETERMINED',
		in_is_final => 1,
		in_state_colour => '3777539',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1471.1" y="686" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_DETERMINED);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 11,
		in_flow_state_id => v_s4,
		in_label => 'Withdrawn',
		in_lookup_key => 'WITHDRAWN',
		in_is_final => 1,
		in_state_colour => '16712965',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="940.85" y="946.6" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_APPLIC_WITHDRAWN);

	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => 'Application Workflow',
		in_flow_alert_class => 'application',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s5);
END;

PROCEDURE UpdatePermitConditionWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
)
AS
	v_workflow_sid			security.security_pkg.T_SID_ID := in_flow_sid;
	v_act					security.security_pkg.T_ACT_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_s3					security.security_pkg.T_SID_ID;
	v_s4					security.security_pkg.T_SID_ID;
	v_s5					security.security_pkg.T_SID_ID;
	v_s6					security.security_pkg.T_SID_ID;
	v_r1					security.security_pkg.T_SID_ID;
	v_g1					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
	v_st2					security.security_pkg.T_SID_ID;
	v_st3					security.security_pkg.T_SID_ID;
	v_st4					security.security_pkg.T_SID_ID;
	v_st5					security.security_pkg.T_SID_ID;
	v_st6					security.security_pkg.T_SID_ID;
	v_st7					security.security_pkg.T_SID_ID;
	v_st8					security.security_pkg.T_SID_ID;
	v_st9					security.security_pkg.T_SID_ID;
	v_st10					security.security_pkg.T_SID_ID;
	v_st11					security.security_pkg.T_SID_ID;
	v_st12					security.security_pkg.T_SID_ID;
	v_st13					security.security_pkg.T_SID_ID;
	v_st14					security.security_pkg.T_SID_ID;
BEGIN
	-- Initiate variables and populate temp tables
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'NOT_CREATED'), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'NEW'), csr.flow_pkg.GetNextStateID);
	v_s3 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'NLA'), csr.flow_pkg.GetNextStateID);
	v_s4 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'UPDATED'), csr.flow_pkg.GetNextStateID);
	v_s5 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'ACTION_REQUIRED'), csr.flow_pkg.GetNextStateID);
	v_s6 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'COMPLIANT'), csr.flow_pkg.GetNextStateID);
	csr.role_pkg.SetRole('Property Manager', v_r1);

	csr.flow_pkg.SetGroup('EHS Managers', v_g1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s1,
		in_label => 'Not Created',
		in_lookup_key => 'NOT_CREATED',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="516.5" y="700.05" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_CONDIT_NOT_CREATED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Create',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 1,
		in_flow_state_id => v_s2,
		in_label => 'New',
		in_lookup_key => 'NEW',
		in_is_final => 0,
		in_state_colour => '16755968',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="820.75" y="699.75" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_CONDIT_ACTIVE);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Not Applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st2);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Update',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st3);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Action',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st4);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st5);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 2,
		in_flow_state_id => v_s4,
		in_label => 'Updated',
		in_lookup_key => 'UPDATED',
		in_is_final => 0,
		in_state_colour => '16755968',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="686.9" y="1016.4" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_CONDIT_UPDATED);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'No longer applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st6);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Acknowledge and action',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st7);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Acknowledge and compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st8);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 3,
		in_flow_state_id => v_s5,
		in_label => 'Action Required',
		in_lookup_key => 'ACTION_REQUIRED',
		in_is_final => 0,
		in_state_colour => '16712965',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1299.55" y="1018.7" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_CONDIT_ACTION_REQ);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'No longer applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st9);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Compliant',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st10);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Update',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st11);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 4,
		in_flow_state_id => v_s6,
		in_label => 'Compliant',
		in_lookup_key => 'COMPLIANT',
		in_is_final => 0,
		in_state_colour => '8570183',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1000.35" y="1287.15" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_CONDIT_COMPLIANT);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'No longer applicable',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st12);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Action',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st13);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Update',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st14);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 5,
		in_flow_state_id => v_s3,
		in_label => 'No longer applicable',
		in_lookup_key => 'NLA',
		in_is_final => 1,
		in_state_colour => '3777539',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1180.05" y="699.85" />',
		in_flow_state_nature_id => csr_data_pkg.NATURE_CONDIT_INACTIVE);

	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => 'Condition Workflow',
		in_flow_alert_class => 'condition',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s1);
END;

END;
/
