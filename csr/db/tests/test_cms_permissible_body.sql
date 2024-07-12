CREATE OR REPLACE PACKAGE BODY cms.test_cms_permissible_pkg AS

v_site_name				VARCHAR2(200);
v_region_1_sid			security.security_pkg.T_SID_ID;
v_region_1_1_sid		security.security_pkg.T_SID_ID;
v_region_1_1_1_sid		security.security_pkg.T_SID_ID;
v_region_1_1_2_sid		security.security_pkg.T_SID_ID;
v_user_1_sid			security.security_pkg.T_SID_ID;
v_user_2_sid			security.security_pkg.T_SID_ID;
v_user_cover_1_sid		security.security_pkg.T_SID_ID;
v_tab_sid				security.security_pkg.T_SID_ID;
v_flow_sid				security.security_pkg.T_SID_ID;
v_flow_item_id_1		security.security_pkg.T_SID_ID;
v_flow_item_id_2		security.security_pkg.T_SID_ID;

-- Private
PROCEDURE CleanupCmsTables
AS
BEGIN
	FOR r IN (
		SELECT flow_sid
		  FROM cms.tab
		 WHERE flow_sid IS NOT NULL
		   AND oracle_table IN ('PERM_TEST')
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.flow_sid);
	END LOOP;
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'RAG'
		   AND table_name in ('PERM_TEST')
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
	csr.flow_pkg.CreateFlow('UNIT_TEST_WF', v_wf_ct_sid, 'cms', out_flow_sid);
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
	VALUES(csr.flow_pkg.GetStateId(out_flow_sid, 'DRAFT'), cms.tab_pkg.GetColumnSid(in_tab_sid, 'USER_SID_1'), 1);
	
	INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
	VALUES(csr.flow_pkg.GetStateId(out_flow_sid, 'CLOSED'), cms.tab_pkg.GetColumnSid(in_tab_sid, 'USER_SID_2'), 0);
	
	INSERT INTO csr.flow_state_transition_cms_col (flow_state_transition_id, from_state_id, column_sid)
	SELECT flow_state_transition_id, from_state_id, cms.tab_pkg.GetColumnSid(in_tab_sid, 'USER_SID_1')
	  FROM csr.flow_state_transition
	 WHERE flow_sid = out_flow_sid
	   AND lookup_key='CLOSE';
	
END;


PROCEDURE A_With_UserInCol_GetAccess
AS
	v_count				NUMBER(10);
	v_ids				chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	-- Users in column have access to the record when in correct state.
	security_pkg.SetContext('SID', v_user_1_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_1_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds (
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for draft state, user 1.');
	
	security_pkg.SetContext('SID', v_user_2_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_2_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds(
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Incorrect number of records returned for draft state, user 2.');
	
	csr.flow_pkg.SetItemState(
		in_flow_item_id		=> v_flow_item_id_1,
		in_to_state_Id		=> csr.flow_pkg.GetStateId(v_flow_sid, 'CLOSED'),
		in_comment_text		=> 'A COMMENT',
		in_user_sid			=> 3
	);
	
	security_pkg.SetContext('SID', v_user_1_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_1_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds(
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Incorrect number of records returned for closed state, user 1.');
	
	security_pkg.SetContext('SID', v_user_2_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_2_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds(
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Incorrect number of records returned for closed state, user 2.');
END;

PROCEDURE B_With_CoverUserInCol_GetAccess
AS
	v_count				NUMBER(10);
	v_ids				chain.T_FILTERED_OBJECT_TABLE;
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	-- Cover user has access via user in column when in correct state.
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	security_pkg.SetContext('SID', v_user_cover_1_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_cover_1_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds (
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for draft state.');
	
	csr.flow_pkg.SetItemState(
		in_flow_item_id		=> v_flow_item_id_1,
		in_to_state_Id		=> csr.flow_pkg.GetStateId(v_flow_sid, 'CLOSED'),
		in_comment_text		=> 'A COMMENT',
		in_user_sid			=> 3
	);
	
	chain.filter_pkg.ClearCacheForUser(null, v_user_cover_1_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds (
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Incorrect number of records returned for closed state.');
END;

PROCEDURE C_With_CoverMultiUserInCol_GetAccess
AS
	v_count				NUMBER(10);
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_ids				chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	-- User is covering both user columns.
	csr.user_cover_pkg.AddUserCover(v_user_2_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);

	security_pkg.SetContext('SID', v_user_cover_1_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_cover_1_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds (
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for draft state.');
	
	csr.flow_pkg.SetItemState(
		in_flow_item_id		=> v_flow_item_id_1,
		in_to_state_Id		=> csr.flow_pkg.GetStateId(v_flow_sid, 'CLOSED'),
		in_comment_text		=> 'A COMMENT',
		in_user_sid			=> 3
	);
	
	chain.filter_pkg.ClearCacheForUser(null, v_user_cover_1_sid);
	cms.filter_pkg.GetFilteredIds (
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for closed state.');
END;

PROCEDURE D_With_MultiState_UserInCol_GetAccess
AS
	v_count				NUMBER(10);
	v_ids				chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	-- User columns are on multiple states.
	INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
	VALUES(csr.flow_pkg.GetStateId(v_flow_sid, 'DRAFT'), cms.tab_pkg.GetColumnSid(v_tab_sid, 'USER_SID_2'), 1);
	
	INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
	VALUES(csr.flow_pkg.GetStateId(v_flow_sid, 'CLOSED'), cms.tab_pkg.GetColumnSid(v_tab_sid, 'USER_SID_1'), 0);

	security_pkg.SetContext('SID', v_user_1_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_1_sid);
	cms.filter_pkg.GetFilteredIds (
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for draft state, user 1.');
	
	security_pkg.SetContext('SID', v_user_2_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_2_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds(
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for draft state, user 2.');
	
	csr.flow_pkg.SetItemState(
		in_flow_item_id		=> v_flow_item_id_1,
		in_to_state_Id		=> csr.flow_pkg.GetStateId(v_flow_sid, 'CLOSED'),
		in_comment_text		=> 'A COMMENT',
		in_user_sid			=> 3
	);
	
	security_pkg.SetContext('SID', v_user_1_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_1_sid); -- permissible ids are cached.
	cms.filter_pkg.GetFilteredIds(
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for closed state, user 1.');
	
	security_pkg.SetContext('SID', v_user_2_sid);
	chain.filter_pkg.ClearCacheForUser(null, v_user_2_sid);
	cms.filter_pkg.GetFilteredIds(
		in_parent_id			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ID'),
		in_compound_filter_id	=> NULL,
		out_id_list				=> v_ids
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_ids);
	  
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Incorrect number of records returned for closed state, user 2.');
END;


PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	TearDownFixture;
	
	v_region_1_sid := csr.unit_test_pkg.GetOrCreateRegion('PERM_REGION_1');
	
	v_user_1_sid := csr.unit_test_pkg.GetOrCreateUser('PERM_USER_1');
	v_user_2_sid := csr.unit_test_pkg.GetOrCreateUser('PERM_USER_2');
	v_user_cover_1_sid := csr.unit_test_pkg.GetOrCreateUser('PERM_USER_COVER_1');
	
	v_region_1_1_sid := csr.unit_test_pkg.GetOrCreateRegion('PERM_REGION_1_1', v_region_1_sid);
	v_region_1_1_1_sid := csr.unit_test_pkg.GetOrCreateRegion('PERM_REGION_1_1_1', v_region_1_1_1_sid);
	v_region_1_1_2_sid := csr.unit_test_pkg.GetOrCreateRegion('PERM_REGION_1_1_2', v_region_1_1_2_sid);
	
	EXECUTE IMMEDIATE 'CREATE TABLE RAG.PERM_TEST (id number(10), user_sid_1 number(10), user_sid_2 number(10), flow_item_id number(10), region_sid number(10) not null, constraint pk_ROLE_TEST_1 primary key (id))';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.PERM_TEST.ID IS ''auto''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.PERM_TEST.USER_SID_1 IS ''user''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.PERM_TEST.USER_SID_2 IS ''user''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.PERM_TEST.FLOW_ITEM_ID IS ''flow_item''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN RAG.PERM_TEST.REGION_SID IS ''flow_region''';
	cms.tab_pkg.RegisterTable('RAG', 'PERM_TEST', FALSE, FALSE);
	
	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
		VALUES ('cms');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'PERM_TEST');
	CreateWorkflow(v_tab_sid, v_flow_sid);

	security_pkg.SetContext('SID', v_user_1_sid);
	csr.flow_pkg.AddCmsItem(v_flow_sid, v_region_1_1_1_sid, v_flow_item_id_1);
	EXECUTE IMMEDIATE 'INSERT INTO RAG.PERM_TEST (id, user_sid_1, user_sid_2, region_sid, flow_item_id) VALUES (CMS.ITEM_ID_SEQ.NEXTVAL, :1, :2, :3, :4)' USING v_user_1_sid, v_user_2_sid, v_region_1_1_1_sid, v_flow_item_id_1;
	
	security_pkg.SetContext('SID', v_user_2_sid);
	csr.flow_pkg.AddCmsItem(v_flow_sid, v_region_1_1_2_sid, v_flow_item_id_2);
	EXECUTE IMMEDIATE 'INSERT INTO RAG.PERM_TEST (id, user_sid_1, user_sid_2, region_sid, flow_item_id) VALUES (CMS.ITEM_ID_SEQ.NEXTVAL, :1, :2, :3, :4)' USING v_user_1_sid, v_user_2_sid, v_region_1_1_2_sid, v_flow_item_id_2;
END;

PROCEDURE SetUp
AS
	v_cache_keys	security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	-- Remove built in admin sid from user context - otherwise we can't check the permissions
	-- of test-built acts (security_pkg.IsAdmin checks sys_context sid before passed act)
	security_pkg.SetContext('SID', NULL);
	
	csr.flow_pkg.SetItemState(
		in_flow_item_id		=> v_flow_item_id_1,
		in_to_state_Id		=> csr.flow_pkg.GetStateId(v_flow_sid, 'DRAFT'),
		in_comment_text		=> 'A COMMENT',
		in_user_sid			=> 3,
		in_force			=> 1,
		in_cache_keys		=> v_cache_keys
	);
END;

PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	SELECT MIN(csr_user_sid)
	  INTO v_user_1_sid
	  FROM csr.csr_user
	 WHERE UPPER(user_name) = 'PERM_USER_1';
	
	IF v_user_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_1_sid);
		v_user_1_sid := NULL;
	END IF;
	
	SELECT MIN(csr_user_sid)
	  INTO v_user_2_sid
	  FROM csr.csr_user
	 WHERE UPPER(user_name) = 'PERM_USER_2';
	
	IF v_user_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_2_sid);
		v_user_2_sid := NULL;
	END IF;
	
	SELECT MIN(csr_user_sid)
	  INTO v_user_cover_1_sid
	  FROM csr.csr_user
	 WHERE UPPER(user_name) = 'PERM_USER_COVER_1';
	
	IF v_user_cover_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_cover_1_sid);
		v_user_cover_1_sid := NULL;
	END IF;
	
	SELECT MIN(region_sid)
	  INTO v_region_1_sid
	  FROM csr.region
	 WHERE UPPER(name) = 'PERM_REGION_1';
	
	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
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

END;
/
