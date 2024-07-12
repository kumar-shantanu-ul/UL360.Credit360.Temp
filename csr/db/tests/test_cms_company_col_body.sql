CREATE OR REPLACE PACKAGE BODY cms.test_cms_company_col_pkg AS

v_site_name				VARCHAR2(200);
v_region_1_sid			security.security_pkg.T_SID_ID;
v_user_1_sid			security.security_pkg.T_SID_ID;
v_company_1_sid			security.security_pkg.T_SID_ID;

-- Private
PROCEDURE CleanupCmsTables
AS
BEGIN
	FOR r IN (
		SELECT flow_sid
		  FROM cms.tab
		 WHERE flow_sid IS NOT NULL
		   AND oracle_table IN ('COMPANY_TEST_1')
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.flow_sid);
	END LOOP;
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'RAG'
		   AND table_name in ('COMPANY_TEST_1')
	) LOOP
		cms.tab_pkg.DropTable('RAG', r.table_name);
	END LOOP;
END;

-- Private
PROCEDURE CreateWorkflow (
	in_tab_sid				IN	security.security_pkg.T_SID_ID,
	out_flow_sid			OUT	security.security_pkg.T_SID_ID
)
AS
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_xml					CLOB;
	v_str					VARCHAR2(2000);
BEGIN
	v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
	csr.flow_pkg.CreateFlow('UNIT_TEST_WF', v_wf_ct_sid, out_flow_sid);
	v_xml := '<';
	v_str := UNISTR('flow label="UNIT_TEST_WF" cmsTabSid="" default-state-id="$S0$"><state id="$S0$" label="Draft" final="0" colour="" lookup-key="DRAFT"><attributes x="750.5" y="884" /><transition to-state-id="$S1$" verb="Close" helper-sp="" lookup-key="CLOSE" ask-for-comment="optional" mandatory-fields-message="" button-icon-path="" /></state><state id="$S1$" label="Closed" final="0" colour="" lookup-key="CLOSED"><attributes x="918.5" y="884" /></state></flow>');
	dbms_lob.writeappend(v_xml, LENGTH(v_str), v_str);
	v_xml := REPLACE(v_xml, '$S0$', NVL(csr.flow_pkg.GetStateId(out_flow_sid, 'DRAFT'), csr.flow_pkg.GetNextStateID));
	v_xml := REPLACE(v_xml, '$S1$', NVL(csr.flow_pkg.GetStateId(out_flow_sid, 'CLOSED'), csr.flow_pkg.GetNextStateID));
	csr.flow_pkg.SetFlowFromXml(out_flow_sid, XMLType(v_xml));
	
	UPDATE cms.tab
	   SET flow_sid = out_flow_sid
	 WHERE tab_sid = in_tab_sid;
	
	UPDATE csr.flow
	   SET owner_can_create = 1
	 WHERE flow_sid = out_flow_sid;
	
	INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
	VALUES(csr.flow_pkg.GetStateId(out_flow_sid, 'DRAFT'), cms.tab_pkg.GetColumnSid(in_tab_sid, 'COMPANY_SID_1'), 1);
	
	INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
	VALUES(csr.flow_pkg.GetStateId(out_flow_sid, 'CLOSED'), cms.tab_pkg.GetColumnSid(in_tab_sid, 'COMPANY_SID_1'), 0);
	
	INSERT INTO csr.flow_state_transition_cms_col (flow_state_transition_id, from_state_id, column_sid)
	SELECT flow_state_transition_id, from_state_id, cms.tab_pkg.GetColumnSid(in_tab_sid, 'COMPANY_SID_1')
	  FROM csr.flow_state_transition
	 WHERE flow_sid = out_flow_sid
	   AND lookup_key='CLOSE';
	
END;


PROCEDURE With_UserInCompany_GetAccess
AS
	v_count				NUMBER(10);
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_sid			security.security_pkg.T_SID_ID;
	v_region_sids		security.security_pkg.T_SID_IDS;
	v_flow_item_id		NUMBER(10);
	v_permission		NUMBER(10);
	v_flow_state_id		NUMBER(10);
BEGIN
	EXECUTE IMMEDIATE 'CREATE TABLE RAG.COMPANY_TEST_1 (id number(10), company_sid_1 number(10), flow_item_id number(10), region_sid number(10) not null, constraint pk_COMPANY_TEST_1 primary key (id))';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.ID IS ''auto''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.company_sid_1 IS ''company''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.FLOW_ITEM_ID IS ''flow_item''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.REGION_SID IS ''flow_region''';
	cms.tab_pkg.RegisterTable('RAG', 'COMPANY_TEST_1', FALSE, FALSE);
	
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_TEST_1');
	CreateWorkflow(v_tab_sid, v_flow_sid);
	
	SELECT v_region_1_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	
	security_pkg.SetContext('SID', v_user_1_sid);
	security_pkg.SetContext('CHAIN_COMPANY', v_company_1_sid);

	csr.flow_pkg.AddCmsItem(v_flow_sid, v_region_1_sid, v_flow_item_id);
	EXECUTE IMMEDIATE 'INSERT INTO RAG.COMPANY_TEST_1 (id, company_sid_1, region_sid, flow_item_id) VALUES (CMS.ITEM_ID_SEQ.NEXTVAL, :1, :2, :3)' USING v_company_1_sid, v_region_1_sid, v_flow_item_id;
	cms.tab_pkg.CheckFlowEntry(v_tab_sid, v_flow_item_id, v_region_1_sid);
	
	v_permission := cms.tab_pkg.GetAccessLevelForState(v_tab_sid, v_flow_item_id, csr.flow_pkg.GetStateId(v_flow_sid, 'DRAFT'), v_region_sids);
	
	csr.unit_test_pkg.AssertAreEqual(2, v_permission, 'User did not have write access to row they have a company on');
END;

PROCEDURE With_UserNotInCompany_TestFail
AS
	v_count				NUMBER(10);
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_sid			security.security_pkg.T_SID_ID;
	v_region_sids		security.security_pkg.T_SID_IDS;
	v_flow_item_id		NUMBER(10);
	v_permission		NUMBER(10);
	v_flow_state_id		NUMBER(10);
BEGIN
	csr.unit_test_pkg.StartTest('csr.test_cms_company_col_pkg.CmsCompanyColNoAccess'); -- More meaningful name
	
	EXECUTE IMMEDIATE 'CREATE TABLE RAG.COMPANY_TEST_1 (id number(10), company_sid_1 number(10), flow_item_id number(10), region_sid number(10) not null, constraint pk_COMPANY_TEST_1 primary key (id))';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.ID IS ''auto''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.company_sid_1 IS ''company''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.FLOW_ITEM_ID IS ''flow_item''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.COMPANY_TEST_1.REGION_SID IS ''flow_region''';
	cms.tab_pkg.RegisterTable('RAG', 'COMPANY_TEST_1', FALSE, FALSE);
	
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_TEST_1');
	CreateWorkflow(v_tab_sid, v_flow_sid);
	
	SELECT v_region_1_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	
	security_pkg.SetContext('SID', v_user_1_sid);
	csr.flow_pkg.AddCmsItem(v_flow_sid, v_region_1_sid, v_flow_item_id);
	EXECUTE IMMEDIATE 'INSERT INTO RAG.COMPANY_TEST_1 (id, company_sid_1, region_sid, flow_item_id) VALUES (CMS.ITEM_ID_SEQ.NEXTVAL, :1, :2, :3)' USING v_company_1_sid, v_region_1_sid, v_flow_item_id;
	BEGIN
		cms.tab_pkg.CheckFlowEntry(v_tab_sid, v_flow_item_id, v_region_1_sid);
		csr.unit_test_pkg.TestFail('User should not have access to flow item');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			NULL; -- Expected result
	END;
	
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
BEGIN
	-- Safest to log on once per test (instead of in StartupFixture) because we unset
	-- the user sid futher down (otherwise any permission test on any ACT returns true)
	
	security.user_pkg.logonadmin(v_site_name);
	
	v_region_1_sid := csr.unit_test_pkg.GetOrCreateRegion('CMS_COMPANY_COL_REGION_1');
	v_user_1_sid := csr.unit_test_pkg.GetOrCreateUser('USER_1');
	
	-- since we're only checking the security context, we don't need a real company.
	v_company_1_sid := 123456;
	
	CleanupCmsTables;
	
	-- Remove built in admin sid from user context - otherwise we can't check the permissions
	-- of test-built acts (security_pkg.IsAdmin checks sys_context sid before passed act)
	security_pkg.SetContext('SID', NULL);
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
	
END;

PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	IF v_region_1_sid IS NOT NULL THEN
		dbms_output.put_line('cms_company_col.TearDown: v_region_1_sid' || v_region_1_sid);
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;
	
	IF v_user_1_sid IS NOT NULL THEN
		dbms_output.put_line('cms_company_col.TearDown: v_user_1_sid' || v_user_1_sid);
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_1_sid);
		v_user_1_sid := NULL;
	END IF;
	
	CleanupCmsTables;
	
END;

END;
/
