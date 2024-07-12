CREATE OR REPLACE PACKAGE BODY csr.test_company_cms_role_pkg AS

v_site_name				VARCHAR2(200);
v_company_region_sid	security.security_pkg.T_SID_ID;
v_fail_user_sid			security.security_pkg.T_SID_ID;
v_pass_user_sid			security.security_pkg.T_SID_ID;
v_group_1_sid			security.security_pkg.T_SID_ID;
v_role_success_sid		security.security_pkg.T_SID_ID;
v_role_fail_sid			security.security_pkg.T_SID_ID;
v_cmp_region_sids_tbl	security.security_pkg.T_SID_IDS;
v_test_company_1_sid	security.security_pkg.T_SID_ID;
v_test_company_2_sid	security.security_pkg.T_SID_ID;
v_flow_sid_1			security.security_pkg.T_SID_ID;
v_flow_sid_2			security.security_pkg.T_SID_ID;

-- Private
PROCEDURE CleanupCmsTables
AS
BEGIN
	FOR r IN (
		SELECT flow_sid
		  FROM cms.tab
		 WHERE flow_sid IS NOT NULL
		   AND oracle_table IN ('CMP_FLOW_SIMPLE_STAGING', 'CMP_FLOW_MULTIPLE_STAGING', 'CMP_FLOW_PK_COMPANY')
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.flow_sid);
	END LOOP;
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'RAG'
		   AND table_name in ('CMP_FLOW_SIMPLE_STAGING', 'CMP_FLOW_MULTIPLE_STAGING', 'CMP_FLOW_PK_COMPANY')
	) LOOP
		cms.tab_pkg.DropTable('RAG', r.table_name);
	END LOOP;
END;

-- Private
PROCEDURE CreateWorkflow 
AS
	v_workflow_sid			security.security_pkg.T_SID_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_g1					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
BEGIN
	
	-- Simple workflow
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Unit_Test_WF_1');
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
				   AND cfac.flow_alert_class = 'cms';
			EXCEPTION 
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please enable the cms module first');
			END; 
			
			-- create our workflow
			csr.flow_pkg.CreateFlow(
				in_label			=> 'Unit_Test_WF_1', 
				in_parent_sid		=> v_wf_ct_sid, 
				in_flow_alert_class	=> 'cms',
				out_flow_sid		=> v_workflow_sid
			);
	END;
	
	-- Get CMS Tab Sids.
	SELECT tab_sid
	  INTO v_cms_tab_sid
	  FROM cms.tab
	 WHERE oracle_table = 'CMP_FLOW_SIMPLE_STAGING';

	-- Initiate variables and populate temp tables
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, ''), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, ''), csr.flow_pkg.GetNextStateID);

	csr.flow_pkg.SetGroup('Administrators', v_g1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s1,
		in_label => '1',
		in_lookup_key => '',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => v_role_success_sid,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="916" y="998.4" />',
		in_flow_state_nature_id => null);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
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
		in_verb => 'Test_Transition',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_role_success_sid,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s2,
		in_label => '2',
		in_lookup_key => '',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1164.4" y="999.6" />',
		in_flow_state_nature_id => null);

	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => 'Unit_Test_WF_1',
		in_flow_alert_class => 'cms',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s1);
	
	v_flow_sid_1 := v_workflow_sid;
	
	-- Multiple Company workflow
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Unit_Test_WF_2');
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
				   AND cfac.flow_alert_class = 'cms';
			EXCEPTION 
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please enable the cms module first');
			END; 
			
			-- create our workflow
			csr.flow_pkg.CreateFlow(
				in_label			=> 'Unit_Test_WF_2', 
				in_parent_sid		=> v_wf_ct_sid, 
				in_flow_alert_class	=> 'cms',
				out_flow_sid		=> v_workflow_sid
			);
	END;
	
	-- Get CMS Tab Sids.
	SELECT tab_sid
	  INTO v_cms_tab_sid
	  FROM cms.tab
	 WHERE oracle_table = 'CMP_FLOW_MULTIPLE_STAGING';

	-- Initiate variables and populate temp tables
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, ''), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, ''), csr.flow_pkg.GetNextStateID);

	csr.flow_pkg.SetGroup('Administrators', v_g1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s1,
		in_label => '1',
		in_lookup_key => '',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => v_role_success_sid,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="916" y="998.4" />',
		in_flow_state_nature_id => null);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
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
		in_verb => 'Test_Transition',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_role_success_sid,
		in_column_sids => null,
		in_involved_type_ids => null,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s2,
		in_label => '2',
		in_lookup_key => '',
		in_is_final => 0,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => v_g1,
		in_non_editable_group_sids => null,
		in_flow_state_group_ids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1164.4" y="999.6" />',
		in_flow_state_nature_id => null);

	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => 'Unit_Test_WF_2',
		in_flow_alert_class => 'cms',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s1);
	
	v_flow_sid_2 := v_workflow_sid;
	
END;


PROCEDURE TestCompanyUserRoleAccess
AS
	v_count				NUMBER(10);
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_item_id		NUMBER(10);
	v_permission		NUMBER(10);
	v_flow_state_id		NUMBER(10);
	v_company_sids_tbl	security.security_pkg.T_SID_IDS;
	v_failed			NUMBER(1);
BEGIN

	CreateWorkflow;
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'CMP_FLOW_SIMPLE_STAGING');
	
	 SELECT	v_test_company_1_sid
	   BULK	COLLECT INTO v_company_sids_tbl
	   FROM	dual;
	
	security_pkg.SetContext('SID', v_pass_user_sid);
	csr.flow_pkg.AddCmsItemByComp(v_flow_sid_1, v_company_sids_tbl, v_flow_item_id);
	EXECUTE IMMEDIATE 'INSERT INTO RAG.CMP_FLOW_SIMPLE_STAGING (FLOW_COMPANY_SIMPLE_ID, FLOW_ITEM_ID, FLOW_ITEM_DESCRIPTION, FLOW_COMPANY_SID) VALUES (CMS.ITEM_ID_SEQ.NEXTVAL, :1, :2, :3)' USING v_flow_item_id, 'This is a test flow item', v_test_company_1_sid;
	
	--Tests on simple table
	security_pkg.SetContext('SID', v_fail_user_sid);
	v_failed := 0;
	BEGIN
		CMS.TAB_PKG.CHECKFLOWENTRYBYCOMP(v_tab_sid, v_flow_item_id, v_company_sids_tbl);
		EXCEPTION
			WHEN OTHERS THEN
				v_failed := 1;
    END;
	csr.unit_test_pkg.AssertAreEqual(1, v_failed, 'User should not have entry access, but does.');
	
	cms.tab_pkg.GetFlowItemEditableByComp(v_flow_item_id, v_company_sids_tbl, v_tab_sid, v_failed);
	csr.unit_test_pkg.AssertAreEqual(0, v_failed, 'User should not have edit access, but does.');
	
	security_pkg.SetContext('SID', v_pass_user_sid);
	
	v_failed := 0;
	BEGIN
		CMS.TAB_PKG.CHECKFLOWENTRYBYCOMP(v_tab_sid, v_flow_item_id, v_company_sids_tbl);
		EXCEPTION
			WHEN OTHERS THEN
				v_failed := 1;
    END;
	csr.unit_test_pkg.AssertAreEqual(0, v_failed, 'User should have entry access, but does not.');
	
	cms.tab_pkg.GetFlowItemEditableByComp(v_flow_item_id, v_company_sids_tbl, v_tab_sid, v_failed);
	csr.unit_test_pkg.AssertAreEqual(1, v_failed, 'User should have edit access, but does not.');
	
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'CMP_FLOW_MULTIPLE_STAGING');
	
	csr.flow_pkg.AddCmsItemByComp(v_flow_sid_2, v_company_sids_tbl, v_flow_item_id);
	EXECUTE IMMEDIATE 'INSERT INTO RAG.CMP_FLOW_MULTIPLE_STAGING (FLOW_COMPANY_MULTI_ID, FLOW_ITEM_ID, FLOW_ITEM_DESCRIPTION, FLOW_COMPANY_SID, FLOW_COMPANY_2_SID) VALUES (CMS.ITEM_ID_SEQ.NEXTVAL, :1, :2, :3, :4)' USING v_flow_item_id, 'This is a test flow item', v_test_company_1_sid, v_test_company_2_sid;
	
	--Tests on Multiple company staging table
	security_pkg.SetContext('SID', v_fail_user_sid);
	v_failed := 0;
	BEGIN
		CMS.TAB_PKG.CHECKFLOWENTRYBYCOMP(v_tab_sid, v_flow_item_id, v_company_sids_tbl);
		EXCEPTION
			WHEN OTHERS THEN
				v_failed := 1;
    END;
	csr.unit_test_pkg.AssertAreEqual(1, v_failed, 'User should not have entry access, but does.');
	
	cms.tab_pkg.GetFlowItemEditableByComp(v_flow_item_id, v_company_sids_tbl, v_tab_sid, v_failed);
	csr.unit_test_pkg.AssertAreEqual(0, v_failed, 'User should not have edit access, but does.');
	
	security_pkg.SetContext('SID', v_pass_user_sid);
	
	v_failed := 0;
	BEGIN
		CMS.TAB_PKG.CHECKFLOWENTRYBYCOMP(v_tab_sid, v_flow_item_id, v_company_sids_tbl);
		EXCEPTION
			WHEN OTHERS THEN
				v_failed := 1;
    END;
	csr.unit_test_pkg.AssertAreEqual(0, v_failed, 'User should have entry access, but does not.');
	
	cms.tab_pkg.GetFlowItemEditableByComp(v_flow_item_id, v_company_sids_tbl, v_tab_sid, v_failed);
	csr.unit_test_pkg.AssertAreEqual(1, v_failed, 'User should have edit access, but does not.');
	
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
v_region_root_sid			NUMBER(10);
v_test_company_type			NUMBER(10);
v_top_company_sid			NUMBER(10);
BEGIN
	-- Safest to log on once per test (instead of in StartupFixture) because we unset
	-- the user sid futher down (otherwise any permission test on any ACT returns true)
	
	security.user_pkg.logonadmin(v_site_name);
	
	chain.test_chain_utils_pkg.SetupTwoTier;
	
	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
		VALUES ('cms');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT	MIN(company_type_id)
	   INTO	v_test_company_type
	   FROM	chain.company_type
	  WHERE	lookup_key = 'VENDOR'
	  GROUP	BY lookup_key;
	
	 SELECT	MIN(region_sid)
	   INTO	v_region_root_sid
	   FROM	csr.region
	  WHERE	name = 'gb'
	  GROUP	BY name;
	  
	 UPDATE	chain.company_type
	    SET	region_root_sid = v_region_root_sid
	  WHERE	company_type_id = v_test_company_type;
	  
	 SELECT	MIN(company_sid)
	   INTO	v_top_company_sid
	   FROM	chain.company
	  WHERE	name = 'CR360'
	  GROUP	BY name;
	
	 SELECT	MIN(company_sid)
	   INTO	v_test_company_1_sid
	   FROM	chain.company
	  WHERE	name = 'Test Company 1';
	
	IF v_test_company_1_sid IS NULL THEN
		chain.company_pkg.CreateSubCompany(
		in_parent_sid			=>	v_top_company_sid,
		in_name					=>	'Test Company 1',
		in_country_code			=>	'gb',
		in_company_type_id		=>	v_test_company_type,
		in_sector_id			=>	NULL,
		out_company_sid			=>	v_test_company_1_sid);
	END IF;
	
	 SELECT	region_sid
	   INTO	v_company_region_sid
	   FROM	csr.supplier
	  WHERE	company_sid = v_test_company_1_sid;
	
	 SELECT	v_company_region_sid
	   BULK	COLLECT INTO v_cmp_region_sids_tbl
	   FROM	dual;
	
	 SELECT	MIN(company_sid)
	   INTO	v_test_company_2_sid
	   FROM	chain.company
	  WHERE	name = 'Test Company 2';
	
	IF v_test_company_2_sid IS NULL THEN
		chain.company_pkg.CreateSubCompany(
		in_parent_sid			=>	v_top_company_sid,
		in_name					=>	'Test Company 2',
		in_country_code			=>	'gb',
		in_company_type_id		=>	v_test_company_type,
		in_sector_id			=>	NULL,
		out_company_sid			=>	v_test_company_2_sid);
	END IF;
	
	v_fail_user_sid := csr.unit_test_pkg.GetOrCreateUser('FAIL_USER');
	v_pass_user_sid := csr.unit_test_pkg.GetOrCreateUser('PASS_USER');
	
	v_group_1_sid := csr.unit_test_pkg.GetOrCreateGroup('GROUP_1');
	security.group_pkg.AddMember(security_pkg.getAct, v_fail_user_sid, v_group_1_sid);
	security.group_pkg.AddMember(security_pkg.getAct, v_pass_user_sid, v_group_1_sid);
	
	csr.role_pkg.SetRole('Success Role', 'Success Role', v_role_success_sid);
	csr.role_pkg.SetRole('Fail Role', 'Fail Role', v_role_fail_sid);
	
	csr.role_pkg.SetRoleMembersForUser(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid					=> v_role_success_sid,
		in_user_sid					=> v_pass_user_sid,
		in_region_sids				=> v_cmp_region_sids_tbl);
		
	csr.role_pkg.SetRoleMembersForUser(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid					=> v_role_fail_sid,
		in_user_sid					=> v_fail_user_sid,
		in_region_sids				=> v_cmp_region_sids_tbl);
	
	-- Remove built in admin sid from user context - otherwise we can't check the permissions
	-- of test-built acts (security_pkg.IsAdmin checks sys_context sid before passed act)
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	IF v_flow_sid_1 IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_flow_sid_1);
		v_flow_sid_1 := NULL;
	END IF;
	
	IF v_flow_sid_2 IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_flow_sid_2);
		v_flow_sid_2 := NULL;
	END IF;
	
	IF v_fail_user_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_fail_user_sid);
		v_fail_user_sid := NULL;
	END IF;
	
	IF v_pass_user_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_pass_user_sid);
		v_pass_user_sid := NULL;
	END IF;
	
	IF v_test_company_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_test_company_1_sid);
		v_test_company_1_sid := NULL;
	END IF;
	
	IF v_test_company_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_test_company_2_sid);
		v_test_company_2_sid := NULL;
	END IF;
	
	IF v_group_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_group_1_sid);
		v_group_1_sid := NULL;
	END IF;
	
	IF v_role_success_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_role_success_sid);
		v_role_success_sid := NULL;
	END IF;
	
	IF v_role_fail_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security.security_pkg.getact, v_role_fail_sid);
		v_role_fail_sid := NULL;
	END IF;
	
	CleanupCmsTables;

	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'cms';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;

	chain.test_chain_utils_pkg.TearDownTwoTier;
	
END;

END;
/
