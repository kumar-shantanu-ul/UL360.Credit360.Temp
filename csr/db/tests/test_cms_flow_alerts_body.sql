CREATE OR REPLACE PACKAGE BODY cms.test_cms_flow_alerts_pkg AS

v_site_name					VARCHAR(200);
v_cms_flow_sid 				security.security_pkg.T_SID_ID;
v_flow_item_id 				security.security_pkg.T_SID_ID;
v_s1						security.security_pkg.T_SID_ID;
v_s2						security.security_pkg.T_SID_ID;
v_u1						security.security_pkg.T_SID_ID;
v_st1						security.security_pkg.T_SID_ID;
v_flow_transition_alert_id	security.security_pkg.T_SID_ID;
v_region_1_sid				security_pkg.T_SID_ID;
m_table_name				VARCHAR2(30) := 'CMS_FLOW_ALERT_TEST';
m_schema					VARCHAR2(30) := 'RAG';

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

PROCEDURE CleanupCmsTables
AS
BEGIN	
	cms.tab_pkg.DropTable(in_oracle_schema => m_schema, in_oracle_table => m_table_name, in_drop_physical => TRUE);
END;

PROCEDURE CreateCmsTables
AS
BEGIN
	EXECUTE IMMEDIATE 'CREATE TABLE '||m_schema||'.'||m_table_name||' (id NUMBER(10) NOT NULL, region_sid NUMBER(10) NOT NULL, flow_item_id NUMBER(10) NOT NULL, constraint pk_'||m_table_name||' primary key (id))';
	EXECUTE IMMEDIATE 'COMMENT ON TABLE '||m_schema||'.'||m_table_name||' IS ''desc="Simple table"''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||m_schema||'.'||m_table_name||'.ID IS ''desc="ID Ref",auto''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||m_schema||'.'||m_table_name||'.REGION_SID IS ''desc="Flow region",flow_region''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||m_schema||'.'||m_table_name||'.FLOW_ITEM_ID IS ''desc="Flow item ID",flow_item''';
	cms.tab_pkg.registertable(UPPER(m_schema), m_table_name, TRUE);
END;

PROCEDURE CreateCmsWorkflow
AS
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_g1					security.security_pkg.T_SID_ID;
	v_cat1					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_frame0				csr.alert_frame.alert_frame_id%TYPE;
BEGIN
	BEGIN
		v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');	
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Please run csr\db\utils\enableworkflow.sql first');
	END;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	
	csr.flow_pkg.CreateFlow(
		in_label			=> 'Simple table WF', 
		in_parent_sid		=> v_wf_ct_sid, 
		in_flow_alert_class	=> 'cms',
		out_flow_sid		=> v_cms_flow_sid
	);
	
	SELECT tab_sid
	  INTO v_cms_tab_sid
	  FROM cms.tab
	 WHERE oracle_table = m_table_name;
	 
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_cms_flow_sid, 'SIMPLE_NEW'), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_cms_flow_sid, 'SIMPLE_CLOSED'), csr.flow_pkg.GetNextStateID);

	csr.flow_pkg.SetGroup('Administrators', v_g1);

	v_u1 := csr.unit_test_pkg.GetOrCreateUser('Administrator');
	csr.alert_pkg.GetOrCreateFrame(UNISTR('Default'), v_frame0);
	csr.alert_pkg.SaveFrameBody(v_frame0, 'en', UNISTR('<template><table width="700"><tbody><tr><td><div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE\2122 Platform by UL EHS Sustainability</div><table border="0"><tbody><tr><td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;"><mergefield name="BODY" /></td></tr></tbody></table><div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;"></div></td></tr></tbody></table></template>'));
	csr.flow_pkg.SaveCmsAlertTemplate(v_cms_tab_sid, null, UNISTR('Simple Table WF Close Alert'), '', v_frame0, 'manual', '', '', 0, 0, v_cat1);

	csr.flow_pkg.SaveCmsAlertTemplateBody(v_cat1, 'en', UNISTR('<template>
		Simple Table WF Close Alert
		</template>'), UNISTR('<template>
		Simple Table WF Close Alert
		</template>'), UNISTR('<template></template>')
	);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_cms_flow_sid,
		in_pos => 0,
		in_flow_state_id => v_s1,
		in_label => 'New',
		in_lookup_key => 'SIMPLE_NEW',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => v_g1,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1000" y="1000" />',
		in_flow_state_nature_id => null,
		in_survey_editable => 0,
		in_survey_tag_ids => null);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_cms_flow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_auto_trans_type => 0,
		in_hours_before_auto_tran => null,
		in_auto_schedule_xml => null,
		in_button_icon_path => '',
		in_verb => 'Close',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => v_g1,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_cms_flow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st1,
		in_customer_alert_type_id => v_cat1,
		in_description => 'Simple Table Close',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => v_u1,
		in_role_sids => null,
		in_group_sids => null,
		in_cc_user_sids => null,
		in_cc_role_sids => null,
		in_cc_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => null);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_cms_flow_sid,
		in_pos => 0,
		in_flow_state_id => v_s2,
		in_label => 'Closed',
		in_lookup_key => 'SIMPLE_CLOSED',
		in_is_final => 1,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1300" y="1000" />',
		in_flow_state_nature_id => null,
		in_survey_editable => 0,
		in_survey_tag_ids => null);

	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_cms_flow_sid,
		in_flow_label => 'Simple table WF',
		in_flow_alert_class => 'cms',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s1);	

END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS	
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	TearDownFixture;
	CreateCmsTables;
	CreateCmsWorkflow;
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	
	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	IF v_cms_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(
			in_act_id			=> security.security_pkg.GetACT,
			in_sid_id			=> v_cms_flow_sid
		);
	END IF;

	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'cms';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;

	CleanupCmsTables;
END;

-- Tests
/*
	This test is to ensure no one switches the temp table TT_ALERT_FLOW_ITEMS
	from PRESERVE ON COMMIT to DELETE ON COMMIT. 
*/
PROCEDURE TestGetOpenGeneratedAlertsWorksIn19c AS
	v_cache_keys						security_pkg.T_VARCHAR2_ARRAY;
	v_flow_state_log_id					NUMBER;
	v_data_cur							SYS_REFCURSOR;
	v_flow_t_alert_id					NUMBER;
	
	v_app_sid							NUMBER;
	v_flow_transition_alert_id			NUMBER;
	v_customer_alert_type_id			NUMBER; 
	v_helper_sp							VARCHAR2(255);
	v_from_state_id						NUMBER;
	v_from_state_label					VARCHAR2(255);
	v_to_state_id						NUMBER;
	v_to_state_label					VARCHAR2(255);	
	v_set_dtm	                    	DATE;
	v_set_by_user_sid					NUMBER; 
	v_comment_text						VARCHAR2(255);	
	v_set_by_full_name					VARCHAR2(255);
	v_set_by_email						VARCHAR2(255);
	v_set_by_user_name					VARCHAR2(255);
	v_to_user_sid						NUMBER;
	v_to_full_name						VARCHAR2(255);
	v_to_email							VARCHAR2(255);
	v_to_user_name						VARCHAR2(255);
	v_to_friendly_name					VARCHAR2(255);
	v_figa_flow_item_id					NUMBER;
	v_flow_sid							NUMBER;
	v_current_state_id					NUMBER;
	v_survey_response_id				NUMBER;
	v_dashboard_instance_id				NUMBER;
	v_to_initiator						VARCHAR2(255);
	v_flow_alert_helper					VARCHAR2(255);
	v_to_column_sid						NUMBER;
	v_flow_item_generated_alert_id		NUMBER;
	v_is_batched						NUMBER;
	v_alert_manager_flag				NUMBER;
	v_created_dtm						DATE;
	v_flow_state_transition_id			NUMBER;
BEGIN
	Trace('TestGetOpenGeneratedAlertsWorksIn19c');
	
	csr.flow_pkg.AddFlowItem(
		in_flow_sid 		=> v_cms_flow_sid,
		out_flow_item_id 	=> v_flow_item_id
	);
	
	v_region_1_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION_1');
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (ID, REGION_SID, FLOW_ITEM_ID, CHANGE_DESCRIPTION) VALUES (1, '|| v_region_1_sid ||', '|| v_flow_item_id ||', ''Change Desc'')';
	
	csr.flow_pkg.SetItemState(
		in_flow_item_id			=> v_flow_item_id,
		in_to_state_Id			=> v_s2,
		in_comment_text			=> '',
		in_cache_keys			=> v_cache_keys,
		in_user_sid				=> v_u1,
		in_force				=> 0,
		in_cancel_alerts		=> 0,
		out_flow_state_log_id	=> v_flow_state_log_id
	);
	
	SELECT flow_transition_alert_id 
	  INTO v_flow_t_alert_id
	  FROM csr.flow_transition_alert
	 WHERE flow_state_transition_id = v_st1;
	 
	csr.flow_pkg.GenerateAlertEntries(
		in_flow_item_id					=> v_flow_item_id,
		in_set_by_user_sid				=> v_u1,
		in_flow_state_log_id			=> v_flow_state_log_id,
		in_flow_state_transition_id		=> v_flow_t_alert_id
	);
		
	csr.flow_pkg.GetOpenGeneratedAlerts(
		in_flow_transition_alert_id 	=> v_flow_t_alert_id,
		in_is_batched				 	=> 0,
		out_cur							=> v_data_cur
	);
	
	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	-- The table involved here is TT_ALERT_FLOW_ITEMS.
	COMMIT;
	
	LOOP
		FETCH v_data_cur INTO 
			v_flow_transition_alert_id,	
		    v_customer_alert_type_id,	
		    v_helper_sp,	
		    v_from_state_id,	
		    v_from_state_label,	
		    v_to_state_id,	
		    v_to_state_label,	
		    v_flow_state_log_Id,	
		    v_set_dtm,   
		    v_set_by_user_sid,	
		    v_comment_text,	
		    v_set_by_full_name,	
		    v_set_by_email,	
		    v_set_by_user_name,	
		    v_to_user_sid,	
		    v_to_full_name,	
		    v_to_email,	
		    v_to_user_name,	
		    v_to_friendly_name,	
		    v_app_sid,	
		    v_figa_flow_item_id,	
		    v_flow_sid,	
		    v_current_state_id,	
		    v_survey_response_id,	
		    v_dashboard_instance_id,	
		    v_to_initiator,	
		    v_flow_alert_helper,	
		    v_to_column_sid,	
		    v_flow_item_generated_alert_id,
		    v_is_batched,
		    v_alert_manager_flag,
		    v_created_dtm,
		    v_flow_state_transition_id		
		;
		csr.unit_test_pkg.AssertAreEqual(v_st1, v_flow_state_transition_id, 'Expected cursor to contain flow state transition id (' || v_st1 || ') but was ('|| v_flow_state_transition_id ||')');
		EXIT WHEN v_data_cur%NOTFOUND;
	END LOOP;
END;

END test_cms_flow_alerts_pkg;
/
