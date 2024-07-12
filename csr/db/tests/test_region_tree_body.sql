CREATE OR REPLACE PACKAGE BODY csr.test_region_tree_pkg AS

v_role_sid	security.security_pkg.T_SID_ID;
v_user_sid	security.security_pkg.T_SID_ID;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE AddUserCreatorPermsToRegions
AS
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_usercreatordaemon_sid		security.security_pkg.T_SID_ID;
	v_app_sid					security.security_pkg.T_SID_ID := security.security_pkg.getApp;
	v_act_id					security.security_pkg.T_ACT_ID := security.security_pkg.getACT;
	v_exists					NUMBER;
begin
	v_region_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Regions');
	v_usercreatordaemon_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users/usercreatordaemon');

	SELECT COUNT(*)
	  INTO v_exists
	  FROM security.securable_object so
	  JOIN security.acl ON so.dacl_id = acl.acl_id
	  JOIN security.securable_object so_grantee ON acl.sid_id = so_grantee.sid_id
	 WHERE so.sid_id = v_region_root_sid
	   AND so_grantee.sid_id = v_usercreatordaemon_sid;

	IF v_exists = 0 THEN
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		security.acl_pkg.PropogateACEs(v_act_id, v_region_root_sid);
	END IF;
END;


PROCEDURE SetUpFixture
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	Trace('SetUpFixture');
	security.user_pkg.LogonAdmin;
	csr.csr_app_pkg.CreateApp('regiontree.credit360.com', '/standardbranding/styles', 1, v_app_sid);
	security.user_pkg.LogonAdmin('regiontree.credit360.com');
	csr.unit_test_pkg.EnableChain;
	csr.enable_pkg.EnableWorkflow;
	
	AddUserCreatorPermsToRegions;
	
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');
	v_user_sid := unit_test_pkg.GetOrCreateUser('DUMMY');
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin('regiontree.credit360.com');
END;



-- HELPER PROCS



-- Logging tests

PROCEDURE SyncSecondaryForTag AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_tag_id				tag.tag_id%TYPE;
	v_logs					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_log_id		NUMBER;
	v_region_sid	NUMBER;
	v_user			VARCHAR2(1024);
	v_log_dtm		DATE;
	
	v_test_name		VARCHAR2(100) := 'SecondaryForTag';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	region_tree_pkg.SyncSecondaryForTag(in_secondary_root_sid => v_secondary_tree_root, in_tag_id => v_tag_id);
	
	region_tree_pkg.GetSecondaryRegionTreeLogs(v_secondary_tree_root, out_cur => v_logs);

	v_count := 0;
	LOOP
		FETCH v_logs INTO v_log_id, v_region_sid, v_user, v_log_dtm;
		EXIT WHEN v_logs%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_log_id > 0, 'Expected log id.');
		unit_test_pkg.AssertIsTrue(v_region_sid = v_secondary_tree_root, 'Expected correct region sid.');
		unit_test_pkg.AssertIsTrue(v_log_dtm IS NOT NULL, 'Expected log dtm.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one log returned, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncSecondaryForTagGroup AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_logs					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_log_id		NUMBER;
	v_region_sid	NUMBER;
	v_user			VARCHAR2(1024);
	v_log_dtm		DATE;
	
	v_test_name		VARCHAR2(100) := 'SecondaryForTagGroup';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	
	region_tree_pkg.SyncSecondaryForTagGroup(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id => v_taggroup_id);
	
	region_tree_pkg.GetSecondaryRegionTreeLogs(v_secondary_tree_root, out_cur => v_logs);

	v_count := 0;
	LOOP
		FETCH v_logs INTO v_log_id, v_region_sid, v_user, v_log_dtm;
		EXIT WHEN v_logs%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_log_id > 0, 'Expected log id.');
		unit_test_pkg.AssertIsTrue(v_region_sid = v_secondary_tree_root, 'Expected correct region sid.');
		unit_test_pkg.AssertIsTrue(v_log_dtm IS NOT NULL, 'Expected log dtm.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one log returned, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncSecondaryActivePropOnly AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_logs					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_log_id		NUMBER;
	v_region_sid	NUMBER;
	v_user			VARCHAR2(1024);
	v_log_dtm		DATE;
	
	v_test_name		VARCHAR2(100) := 'SecondaryActivePropOnly';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	region_tree_pkg.SyncSecondaryActivePropOnly(in_secondary_root_sid => v_secondary_tree_root);
	
	region_tree_pkg.GetSecondaryRegionTreeLogs(v_secondary_tree_root, out_cur => v_logs);

	v_count := 0;
	LOOP
		FETCH v_logs INTO v_log_id, v_region_sid, v_user, v_log_dtm;
		EXIT WHEN v_logs%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_log_id > 0, 'Expected log id.');
		unit_test_pkg.AssertIsTrue(v_region_sid = v_secondary_tree_root, 'Expected correct region sid.');
		unit_test_pkg.AssertIsTrue(v_log_dtm IS NOT NULL, 'Expected log dtm.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one log returned, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;


PROCEDURE SyncSecondaryForTagGroupList AS
	v_secondary_tree_root	NUMBER;
	v_taggroup1_id			tag_group.tag_group_id%TYPE;
	v_taggroup2_id			tag_group.tag_group_id%TYPE;
	v_logs					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_log_id		NUMBER;
	v_region_sid	NUMBER;
	v_user			VARCHAR2(1024);
	v_log_dtm		DATE;
	
	v_test_name		VARCHAR2(100) := 'SecondaryForTagGroupList';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup1_id);
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup2', out_tag_group_id => v_taggroup2_id);
	
	region_tree_pkg.SyncSecondaryForTagGroupList(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id_list => v_taggroup1_id||','||v_taggroup2_id);
	
	region_tree_pkg.GetSecondaryRegionTreeLogs(v_secondary_tree_root, out_cur => v_logs);

	v_count := 0;
	LOOP
		FETCH v_logs INTO v_log_id, v_region_sid, v_user, v_log_dtm;
		EXIT WHEN v_logs%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_log_id > 0, 'Expected log id.');
		unit_test_pkg.AssertIsTrue(v_region_sid = v_secondary_tree_root, 'Expected correct region sid.');
		unit_test_pkg.AssertIsTrue(v_log_dtm IS NOT NULL, 'Expected log dtm.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one log returned, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup1_id);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup2_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;


PROCEDURE SyncSecondaryPropByFunds AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_logs					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_log_id		NUMBER;
	v_region_sid	NUMBER;
	v_user			VARCHAR2(1024);
	v_log_dtm		DATE;
	
	v_test_name		VARCHAR2(100) := 'SecondaryPropByFunds';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	region_tree_pkg.SyncSecondaryPropByFunds(in_secondary_root_sid => v_secondary_tree_root);
	
	region_tree_pkg.GetSecondaryRegionTreeLogs(v_secondary_tree_root, out_cur => v_logs);

	v_count := 0;
	LOOP
		FETCH v_logs INTO v_log_id, v_region_sid, v_user, v_log_dtm;
		EXIT WHEN v_logs%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_log_id > 0, 'Expected log id.');
		unit_test_pkg.AssertIsTrue(v_region_sid = v_secondary_tree_root, 'Expected correct region sid.');
		unit_test_pkg.AssertIsTrue(v_log_dtm IS NOT NULL, 'Expected log dtm.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one log returned, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;


PROCEDURE SyncPropTreeByMgtCompany AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_logs					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_log_id		NUMBER;
	v_region_sid	NUMBER;
	v_user			VARCHAR2(1024);
	v_log_dtm		DATE;
	
	v_test_name		VARCHAR2(100) := 'PropTreeByMgtCompany';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	region_tree_pkg.SyncPropTreeByMgtCompany(in_secondary_root_sid => v_secondary_tree_root);
	
	region_tree_pkg.GetSecondaryRegionTreeLogs(v_secondary_tree_root, out_cur => v_logs);

	v_count := 0;
	LOOP
		FETCH v_logs INTO v_log_id, v_region_sid, v_user, v_log_dtm;
		EXIT WHEN v_logs%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_log_id > 0, 'Expected log id.');
		unit_test_pkg.AssertIsTrue(v_region_sid = v_secondary_tree_root, 'Expected correct region sid.');
		unit_test_pkg.AssertIsTrue(v_log_dtm IS NOT NULL, 'Expected log dtm.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one log returned, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;



-- Sync test helpers

PROCEDURE CheckSecondaryTreeEmpty(
	in_secondary_tree_root	IN	security.security_pkg.T_SID_ID
)
AS
	v_count		NUMBER;
	v_msg		VARCHAR(2000);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$region
	 WHERE parent_sid = in_secondary_tree_root;

	IF v_count > 0 THEN
		FOR r IN (
			SELECT region_sid, description
			  FROM csr.v$region
			 WHERE parent_sid = in_secondary_tree_root)
		LOOP
			v_msg := v_msg || '; ' ||r.region_sid || ' ' || r.description;
		END LOOP;
	END IF;

	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected empty tree, found '||v_count||' regions - '||v_msg);
END;

PROCEDURE DeleteMenu(in_path	IN VARCHAR2) 
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

PROCEDURE CreateCompany(
	in_test_name		IN	VARCHAR2,
	in_region_root_sid	IN	security.security_pkg.T_SID_ID,
	out_company_sid		OUT	security.security_pkg.T_SID_ID,
	out_flow_sid		OUT	security.security_pkg.T_SID_ID
)
AS
	v_workflows_sid		security.security_pkg.T_SID_ID;
	v_xml				CLOB;
	v_str 				VARCHAR2(2000);
	v_r0 				security.security_pkg.T_SID_ID;
	v_s0				security.security_pkg.T_SID_ID;
	v_s1				security.security_pkg.T_SID_ID;

BEGIN

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
		VALUES ('property');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	
	v_workflows_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
	flow_pkg.CreateFlow(
		in_label			=>	in_test_name||'_Flow',
		in_parent_sid		=>	v_workflows_sid,
		in_flow_alert_class	=>	'property',
		out_flow_sid		=>	out_flow_sid
	);
	
	UPDATE customer
	   SET property_flow_sid = out_flow_sid
	 WHERE app_sid = security.security_pkg.GetApp;

	v_xml := '<';
	v_str := UNISTR('flow label="Property workflow" cmsTabSid="" default-state-id="$S1$"><state id="$S0$" label="Details entered" final="0" colour="" lookup-key="PROP_DETS_ENTERED"><attributes x="1078.5" y="801.5" /><role sid="$R0$" is-editable="1" /><transition to-state-id="$S1$" verb="Details required" helper-sp="" lookup-key="MARK_DETS_REQD" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state><state id="$S1$" label="Details required" final="0" colour="" lookup-key="PROP_DETS_REQD"><attributes x="726.5" y="799.5" /><role sid="$R0$" is-editable="1" /><transition to-state-id="$S0$" verb="Details entered" helper-sp="" lookup-key="MARK_DETS_ENTERED" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state></flow>');
	dbms_lob.writeappend(v_xml, LENGTH(v_str), v_str);

	role_pkg.SetRole('Property Manager', v_r0);
	v_s0 := NVL(flow_pkg.GetStateId(out_flow_sid, 'PROP_DETS_ENTERED'), flow_pkg.GetNextStateID);
	v_s1 := NVL(flow_pkg.GetStateId(out_flow_sid, 'PROP_DETS_REQD'), flow_pkg.GetNextStateID);
	
	v_xml := REPLACE(v_xml, '$R0$', v_r0);
	v_xml := REPLACE(v_xml, '$S0$', v_s0);
	v_xml := REPLACE(v_xml, '$S1$', v_s1);
	
	flow_pkg.SetFlowFromXml(out_flow_sid, XMLType(v_xml));

	-- make a company and set up fund data
	-- create default company (this still works if company already exists!)
	chain.company_type_pkg.AddCompanyType(
		in_lookup_key				=> 'TOP',
		in_singular					=> 'TOP',
		in_plural					=> 'TOP',
		in_default_region_type		=> csr_data_pkg.REGION_TYPE_NORMAL,
		in_region_root_sid			=> in_region_root_sid,
		-- dummy value so that it doesn't default to COUNTRY; we know we will not be using sectors as we are creating the company immediately
		in_default_region_layout	=> '{SECTOR}'
	);
	chain.company_type_pkg.SetTopCompanyType('TOP');

	out_company_sid := chain.setup_pkg.CreateCompanyLightweight(in_test_name||'_TestCompany', 'gb', 'TOP');
END;

PROCEDURE DeleteCompany
AS
	v_flow_sid			security.security_pkg.T_SID_ID;
BEGIN
	SELECT property_flow_sid
	  INTO v_flow_sid
	  FROM customer
	 WHERE app_sid = security.security_pkg.GetApp;

	UPDATE customer
	   SET property_flow_sid = NULL
	 WHERE app_sid = security.security_pkg.GetApp;

	UPDATE customer
	   SET property_flow_sid = NULL
	 WHERE property_flow_sid = v_flow_sid;

	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_flow_sid);

	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'property';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	DeleteMenu('menu/admin/chain_dedupe_records');
	DeleteMenu('menu/admin/chain_company_requests');
	DeleteMenu('menu/chain');
	
	chain.test_chain_utils_pkg.DeleteFullyCompaniesOfType(in_company_type_lookup => 'TOP');
	chain.test_chain_utils_pkg.TearDownSingleTier;
	
	UPDATE chain.customer_options SET force_login_as_company = 0;
	
END;

PROCEDURE CheckSyncedRegionCount(
	in_sec_tree_root	IN security.security_pkg.T_SID_ID,
	in_count			IN NUMBER)
AS
	v_synced_region_sid_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_synced_region_sid_count
	  FROM csr.v$region
	 WHERE parent_sid = in_sec_tree_root;
	unit_test_pkg.AssertIsTrue(v_synced_region_sid_count = in_count, 'Expected one synced region sid, found '||v_synced_region_sid_count);
END;

PROCEDURE CheckSyncedRegionLink(
	in_sec_tree_root	IN security.security_pkg.T_SID_ID,
	in_new_region_sid 	IN security.security_pkg.T_SID_ID)
AS
	v_synced_region_sid			security.security_pkg.T_SID_ID;
BEGIN
	SELECT link_to_region_sid
	  INTO v_synced_region_sid
	  FROM csr.v$region
	 WHERE parent_sid = in_sec_tree_root;
	unit_test_pkg.AssertIsTrue(v_synced_region_sid IS NOT NULL, 'Expected synced region sid');
	unit_test_pkg.AssertIsTrue(v_synced_region_sid = in_new_region_sid, 'Expected synced region sid to link to '||in_new_region_sid);
END;

PROCEDURE CheckRegionHasRole(
	in_region_sid	IN security.security_pkg.T_SID_ID,
	in_role_sid 	IN security.security_pkg.T_SID_ID
)
AS
	v_matched_region_sid			security.security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(region_sid)
	  INTO v_matched_region_sid
	  FROM region_role_member
	 WHERE region_sid = in_region_sid
	   AND role_sid = in_role_sid;

	unit_test_pkg.AssertIsTrue(in_region_sid = NVL(v_matched_region_sid, -1), 'Expected region sid '|| in_region_sid || ' to have role '|| in_role_sid);
END;

-- Sync tests

PROCEDURE SyncSecondaryForTag_One AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	
	v_test_name					VARCHAR2(100) := 'SecondaryForTag_One';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new primary region
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);

	-- Check sync does nothing
	region_tree_pkg.SyncSecondaryForTag(in_secondary_root_sid => v_secondary_tree_root, in_tag_id => v_tag_id);
	CheckSecondaryTreeEmpty(in_secondary_tree_root => v_secondary_tree_root);

	-- tag region and resync
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_a, in_tag_id => v_tag_id);
	region_tree_pkg.SyncSecondaryForTag(in_secondary_root_sid => v_secondary_tree_root, in_tag_id => v_tag_id);
	
	-- Check the secondary tree has the tagged region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	CheckSyncedRegionLink(v_secondary_tree_root, v_new_region_sid_a);

	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	CheckSyncedRegionLink(v_secondary_tree_root, v_new_region_sid_a);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncSecondaryForTagGroup_One AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_stg_region_sid			security.security_pkg.T_SID_ID;
	v_stg_region_desc			region_description.description%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryForTagGroup_One';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new primary region
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	-- Check sync does nothing
	region_tree_pkg.SyncSecondaryForTagGroup(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id => v_taggroup_id);
	CheckSecondaryTreeEmpty(in_secondary_tree_root => v_secondary_tree_root);

	-- tag region and resync
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_a, in_tag_id => v_tag_id);
	region_tree_pkg.SyncSecondaryForTagGroup(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id => v_taggroup_id);
	
	-- Check the secondary tree has the tagged region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_stg_region_sid, v_stg_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	CheckSyncedRegionCount(v_stg_region_sid, 1);
	CheckSyncedRegionLink(v_stg_region_sid, v_new_region_sid_a);
	unit_test_pkg.AssertIsTrue(v_stg_region_desc = v_test_name||'_Tag1', 'Expected one tag group link region sid with name "'||v_test_name||'_Tag1", found '||v_stg_region_desc);

	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_stg_region_sid, v_stg_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	CheckSyncedRegionCount(v_stg_region_sid, 1);
	CheckSyncedRegionLink(v_stg_region_sid, v_new_region_sid_a);
	unit_test_pkg.AssertIsTrue(v_stg_region_desc = v_test_name||'_Tag1', 'Expected one tag group link region sid with name "'||v_test_name||'_Tag1", found '||v_stg_region_desc);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncScndryActivePropOnly_One AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_property_type_id			property_type.property_type_id%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryActivePropOnly_One';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new primary region.
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	-- Check sync does nothing
	region_tree_pkg.SyncSecondaryActivePropOnly(in_secondary_root_sid => v_secondary_tree_root);
	CheckSecondaryTreeEmpty(in_secondary_tree_root => v_secondary_tree_root);

	-- make it a property and resync
	UPDATE region
	   SET region_type = csr_data_pkg.REGION_TYPE_PROPERTY
	 WHERE region_sid = v_new_region_sid_a;
	
	region_tree_pkg.SyncSecondaryActivePropOnly(in_secondary_root_sid => v_secondary_tree_root);
	
	-- Check the secondary tree has the property region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	CheckSyncedRegionLink(v_secondary_tree_root, v_new_region_sid_a);

	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	CheckSyncedRegionLink(v_secondary_tree_root, v_new_region_sid_a);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncScndryForTagGroupList_One AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_stg_region_sid			security.security_pkg.T_SID_ID;
	v_stg_region_desc			region_description.description%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryForTagGroupList_One';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new primary region
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	-- Check sync does nothing
	region_tree_pkg.SyncSecondaryForTagGroupList(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id_list => TO_CHAR(v_taggroup_id));
	CheckSecondaryTreeEmpty(in_secondary_tree_root => v_secondary_tree_root);

	-- tag region and resync
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_a, in_tag_id => v_tag_id);
	region_tree_pkg.SyncSecondaryForTagGroupList(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id_list => TO_CHAR(v_taggroup_id));
	
	-- Check the secondary tree has the tagged region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_stg_region_sid, v_stg_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	CheckSyncedRegionCount(v_stg_region_sid, 1);
	CheckSyncedRegionLink(v_stg_region_sid, v_new_region_sid_a);
	unit_test_pkg.AssertIsTrue(v_stg_region_desc = v_test_name||'_Tag1', 'Expected one tag group link region sid with name "'||v_test_name||'_Tag1", found '||v_stg_region_desc);
 
	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_stg_region_sid, v_stg_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	CheckSyncedRegionCount(v_stg_region_sid, 1);
	CheckSyncedRegionLink(v_stg_region_sid, v_new_region_sid_a);
	unit_test_pkg.AssertIsTrue(v_stg_region_desc = v_test_name||'_Tag1', 'Expected one tag group link region sid with name "'||v_test_name||'_Tag1", found '||v_stg_region_desc);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncSecondaryPropByFunds_One AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_company_type_id			chain.company_type.company_type_id%TYPE;
	v_company_sid				security_pkg.T_SID_ID;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_property_region_sid		security.security_pkg.T_SID_ID;
	v_property_type_id			property_type.property_type_id%TYPE;
	v_fund_type_id				fund_type.fund_type_id%TYPE;
	v_fund_id					fund.fund_id%TYPE;
	v_first_region_sid			security.security_pkg.T_SID_ID;
	v_first_region_desc			region_description.description%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryPropByFunds_One';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new primary region.
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	-- Check sync does nothing
	region_tree_pkg.SyncSecondaryPropByFunds(in_secondary_root_sid => v_secondary_tree_root);
	CheckSecondaryTreeEmpty(in_secondary_tree_root => v_secondary_tree_root);

	-- Create a company and property.
	CreateCompany(
		in_test_name		=>	v_test_name,
		in_region_root_sid	=>	v_region_root_sid,
		out_company_sid		=>	v_company_sid,
		out_flow_sid		=>	v_flow_sid
	);
	
	property_pkg.SavePropertyType(
		in_property_type_id		=>	NULL,
		in_property_type_name	=>	'TestPropType',
		in_space_type_ids		=>	'',
		in_gresb_prop_type		=>	'',
		out_property_type_id	=>	v_property_type_id
	);
	
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestProperty',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_property_region_sid
	);

	v_fund_type_id := fund_type_id_seq.NEXTVAL;
	INSERT INTO fund_type (fund_type_id, label)
	VALUES (v_fund_type_id, 'Test Fund Type');

	v_fund_id := fund_id_seq.NEXTVAL;
	INSERT INTO fund (fund_id, company_sid, name, year_of_inception, fund_type_id)
	VALUES (v_fund_id, v_company_sid, v_test_name||'_TestFund1', 2018, v_fund_type_id);

	INSERT INTO property_fund ( fund_id, region_sid)
	VALUES (v_fund_id, v_property_region_sid);
	
	INSERT INTO property_fund_ownership (region_sid, fund_id, start_dtm, ownership)
	VALUES (v_property_region_sid, v_fund_id, SYSDATE, 1);
	
	region_tree_pkg.SyncSecondaryPropByFunds(in_secondary_root_sid => v_secondary_tree_root);

	-- Check the secondary tree has the property region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_first_region_sid, v_first_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	unit_test_pkg.AssertIsTrue(v_first_region_desc = v_fund_id||'-'||v_test_name||'_TestFund1', 'Expected '||v_fund_id||'-'||v_test_name||'_TestFund1 region, found '||v_first_region_desc);
	-- Check sub tree contains linked prop region
	CheckSyncedRegionLink(v_first_region_sid, v_property_region_sid);

	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_first_region_sid, v_first_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	unit_test_pkg.AssertIsTrue(v_first_region_desc = v_fund_id||'-'||v_test_name||'_TestFund1', 'Expected '||v_fund_id||'-'||v_test_name||'_TestFund1 region, found '||v_first_region_desc);
	-- Check sub tree contains linked prop region
	CheckSyncedRegionLink(v_first_region_sid, v_property_region_sid);

	DELETE FROM property_fund_ownership
	 WHERE fund_id = v_fund_id;
	DELETE FROM property_fund
	 WHERE fund_id = v_fund_id;
	DELETE FROM fund
	 WHERE fund_id = v_fund_id;
	DELETE FROM fund_type
	 WHERE fund_type_id = v_fund_type_id;
	
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_property_region_sid);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
	
	property_pkg.DeletePropertyType(in_property_type_id => v_property_type_id);

	DeleteCompany;
END;

PROCEDURE SyncPropTreeByMgtCompany_One AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_company_sid				security.security_pkg.T_SID_ID;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_first_region_sid			security.security_pkg.T_SID_ID;
	v_first_region_desc			region_description.description%TYPE;
	v_property_region_sid		security.security_pkg.T_SID_ID;
	v_property_type_id			property_type.property_type_id%TYPE;
	
	v_test_name					VARCHAR2(100) := 'PropTreeByMgtCompany_One';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new primary region.
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	-- Check sync does nothing
	region_tree_pkg.SyncPropTreeByMgtCompany(in_secondary_root_sid => v_secondary_tree_root);
	CheckSecondaryTreeEmpty(in_secondary_tree_root => v_secondary_tree_root);

	-- Create a company and property
	CreateCompany(
		in_test_name		=>	v_test_name,
		in_region_root_sid	=>	v_region_root_sid,
		out_company_sid		=>	v_company_sid,
		out_flow_sid		=>	v_flow_sid
	);
	
	property_pkg.SavePropertyType(
		in_property_type_id		=>	NULL,
		in_property_type_name	=>	'TestPropType',
		in_space_type_ids		=>	'',
		in_gresb_prop_type		=>	'',
		out_property_type_id	=>	v_property_type_id
	);
	
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestProperty',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_property_region_sid
	);

	region_tree_pkg.SyncPropTreeByMgtCompany(in_secondary_root_sid => v_secondary_tree_root);
	
	-- Check the secondary tree has the "Others" region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_first_region_sid, v_first_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	unit_test_pkg.AssertIsTrue(v_first_region_desc = 'Other', 'Expected Other region, found '||v_first_region_desc);
	-- Check sub tree contains linked prop region
	CheckSyncedRegionLink(v_first_region_sid, v_property_region_sid);
	

	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_first_region_sid, v_first_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	unit_test_pkg.AssertIsTrue(v_first_region_desc = 'Other', 'Expected Other region, found '||v_first_region_desc);
	-- Check sub tree contains linked prop region
	CheckSyncedRegionLink(v_first_region_sid, v_property_region_sid);


	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;

	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_property_region_sid);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_first_region_sid);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);

	property_pkg.DeletePropertyType(in_property_type_id => v_property_type_id);

	DeleteCompany;
END;

-- Sync tests with secondary tree roles.

PROCEDURE SyncSecondaryForTag_WithRole AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_new_region_sid_b			security.security_pkg.T_SID_ID;
	v_new_region_sid_c			security.security_pkg.T_SID_ID;
	v_child_of_link				security.security_pkg.T_SID_ID;
	v_first_region				security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	
	v_test_name					VARCHAR2(100) := 'SecondaryForTag_WithRole';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new tagged primary region
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	-- Add extra region to add role to
	region_pkg.CreateRegion(
		in_parent_sid => v_region_root_sid,
		in_name => v_test_name,
		in_description => v_test_name,
		out_region_sid => v_new_region_sid_a
	);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_a,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_b
	);
	
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_b, in_tag_id => v_tag_id);
	-- Sync Tree
	region_tree_pkg.SyncSecondaryForTag(in_secondary_root_sid => v_secondary_tree_root, in_tag_id => v_tag_id);
	
	-- Check the secondary tree has the tagged region in it.
	SELECT region_sid
	  INTO v_first_region
	  FROM region
	 WHERE parent_sid = v_secondary_tree_root;
	 
	CheckSyncedRegionCount(v_first_region, 1);	 
	CheckSyncedRegionLink(v_first_region, v_new_region_sid_b);

	-- Add role to secondary tree region
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = v_secondary_tree_root
	) LOOP
		role_pkg.AddRoleMemberForRegion(
			in_role_sid		=> v_role_sid,
			in_region_sid	=> r.region_sid,
			in_user_sid 	=> v_user_sid
		);

		CheckRegionHasRole(r.region_sid, v_role_sid);
	END LOOP;
	
	CheckRegionHasRole(v_new_region_sid_b, v_role_sid);
	
	-- Create another new tagged primary region
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_a,
		in_name => v_test_name||'_WithTagC',
		in_description => v_test_name||'_WithTagC',
		out_region_sid => v_new_region_sid_c
	);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_c,
		in_name => v_test_name||'_LinkChild',
		in_description => v_test_name||'_LinkChild',
		out_region_sid => v_child_of_link
	);
	
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_c, in_tag_id => v_tag_id);
	
	-- Re-sync Tree
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	
	-- Check role was applied to new region
	CheckRegionHasRole(v_new_region_sid_c, v_role_sid);
	CheckRegionHasRole(v_child_of_link, v_role_sid);
	
	-- Clean up
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_b);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_c);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncSecondaryForTagGroup_WithRole AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_new_region_sid_b			security.security_pkg.T_SID_ID;
	v_child_of_link				security.security_pkg.T_SID_ID;	
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_stg_region_sid			security.security_pkg.T_SID_ID;
	v_stg_region_desc			region_description.description%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryForTagGroup_WithRole';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new tagged primary region
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_a, in_tag_id => v_tag_id);
	
	-- Sync Tree	
	region_tree_pkg.SyncSecondaryForTagGroup(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id => v_taggroup_id);
	
	-- Check the secondary tree has the tagged region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_stg_region_sid, v_stg_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	CheckSyncedRegionCount(v_stg_region_sid, 1);
	CheckSyncedRegionLink(v_stg_region_sid, v_new_region_sid_a);
	unit_test_pkg.AssertIsTrue(v_stg_region_desc = v_test_name||'_Tag1', 'Expected one tag group link region sid with name "'||v_test_name||'_Tag1", found '||v_stg_region_desc);
	
	-- Add role to secondary tree region
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = v_secondary_tree_root
	) LOOP
		role_pkg.AddRoleMemberForRegion(
			in_role_sid		=> v_role_sid,
			in_region_sid	=> r.region_sid,
			in_user_sid 	=> v_user_sid
		);
		
		CheckRegionHasRole(r.region_sid, v_role_sid);
	END LOOP;
	
	CheckRegionHasRole(v_new_region_sid_a, v_role_sid);
	
	-- Create another new tagged primary region
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTagB',
		in_description => v_test_name||'_WithTagB',
		out_region_sid => v_new_region_sid_b
	);

	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_b, in_tag_id => v_tag_id);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_b,
		in_name => v_test_name||'_LinkChild',
		in_description => v_test_name||'_LinkChild',
		out_region_sid => v_child_of_link
	);
	
	-- Call refresh and check again
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	
	-- Check role was applied to new region
	CheckRegionHasRole(v_new_region_sid_b, v_role_sid);
	CheckRegionHasRole(v_child_of_link, v_role_sid);
	
	-- Clean Up	
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_b);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncScndryActivePropOnly_WithRole AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_new_region_sid_b			security.security_pkg.T_SID_ID;
	v_new_region_sid_c			security.security_pkg.T_SID_ID;
	v_child_of_link				security.security_pkg.T_SID_ID;	
	v_first_region				security.security_pkg.T_SID_ID;		
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_property_type_id			property_type.property_type_id%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryActivePropOnly_WithRole';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	-- Create a new property primary region.
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	-- Add extra region to add role to
	region_pkg.CreateRegion(
		in_parent_sid => v_region_root_sid,
		in_name => v_test_name,
		in_description => v_test_name,
		out_region_sid => v_new_region_sid_a
	);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_a,
		in_name => v_test_name||'B',
		in_description => v_test_name||'B',
		out_region_sid => v_new_region_sid_b
	);

	UPDATE region
	   SET region_type = csr_data_pkg.REGION_TYPE_PROPERTY
	 WHERE region_sid = v_new_region_sid_b;
	
	region_tree_pkg.SyncSecondaryActivePropOnly(in_secondary_root_sid => v_secondary_tree_root);
	
	-- Check the secondary tree has the property region in it.
	SELECT region_sid
	  INTO v_first_region
	  FROM region
	 WHERE parent_sid = v_secondary_tree_root;
	 
	CheckSyncedRegionCount(v_first_region, 1);
	CheckSyncedRegionLink(v_first_region, v_new_region_sid_b);
	
	-- Add role to secondary tree region
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = v_secondary_tree_root
	) LOOP
		role_pkg.AddRoleMemberForRegion(
			in_role_sid		=> v_role_sid,
			in_region_sid	=> r.region_sid,
			in_user_sid 	=> v_user_sid
		);
		
		CheckRegionHasRole(r.region_sid, v_role_sid);
	END LOOP;
	
	CheckRegionHasRole(v_new_region_sid_b, v_role_sid);
	
	-- Create another new tagged primary region
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_a,
		in_name => v_test_name||'C',
		in_description => v_test_name||'C',
		out_region_sid => v_new_region_sid_c
	);

	UPDATE region
	   SET region_type = csr_data_pkg.REGION_TYPE_PROPERTY
	 WHERE region_sid = v_new_region_sid_c;	
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_c,
		in_name => v_test_name||'_LinkChild',
		in_description => v_test_name||'_LinkChild',
		out_region_sid => v_child_of_link
	);
	
	-- Re-sync Tree
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	
	-- Check role was applied to new region
	CheckRegionHasRole(v_new_region_sid_c, v_role_sid);
	CheckRegionHasRole(v_child_of_link, v_role_sid);
	
	-- Clean Up
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_b);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_c);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncScndryForTagGroupList_WithRole AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	v_taggroup_id				tag_group.tag_group_id%TYPE;
	v_tag_id					tag.tag_id%TYPE;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_new_region_sid_b			security.security_pkg.T_SID_ID;
	v_child_of_link				security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_stg_region_sid			security.security_pkg.T_SID_ID;
	v_stg_region_desc			region_description.description%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryForTagGroupList_WithRole';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);
	
	-- Create a new tagged primary region
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTag',
		in_description => v_test_name||'_WithTag',
		out_region_sid => v_new_region_sid_a
	);
	
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_a, in_tag_id => v_tag_id);
	region_tree_pkg.SyncSecondaryForTagGroupList(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id_list => TO_CHAR(v_taggroup_id));
	
	-- Check the secondary tree has the tagged region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_stg_region_sid, v_stg_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	CheckSyncedRegionCount(v_stg_region_sid, 1);
	CheckSyncedRegionLink(v_stg_region_sid, v_new_region_sid_a);
	unit_test_pkg.AssertIsTrue(v_stg_region_desc = v_test_name||'_Tag1', 'Expected one tag group link region sid with name "'||v_test_name||'_Tag1", found '||v_stg_region_desc);
 
	-- Add role to secondary tree region
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = v_secondary_tree_root
	) LOOP
		role_pkg.AddRoleMemberForRegion(
			in_role_sid		=> v_role_sid,
			in_region_sid	=> r.region_sid,
			in_user_sid 	=> v_user_sid
		);
		
		CheckRegionHasRole(r.region_sid, v_role_sid);
	END LOOP;
	
	CheckRegionHasRole(v_new_region_sid_a, v_role_sid);
	
	-- Create another new tagged primary region
	region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => v_test_name||'_WithTagB',
		in_description => v_test_name||'_WithTagB',
		out_region_sid => v_new_region_sid_b
	);

	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_new_region_sid_b, in_tag_id => v_tag_id);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_b,
		in_name => v_test_name||'_LinkChild',
		in_description => v_test_name||'_LinkChild',
		out_region_sid => v_child_of_link
	);
	
	-- Re-sync Tree
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	
	-- Check role was applied to new region
	CheckRegionHasRole(v_new_region_sid_b, v_role_sid);
	CheckRegionHasRole(v_child_of_link, v_role_sid);
	-- Clean Up	
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_b);
	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_taggroup_id);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
END;

PROCEDURE SyncSecondaryPropByFunds_WithRole AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_new_region_sid_b			security.security_pkg.T_SID_ID;
	v_child_of_link				security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_company_type_id			chain.company_type.company_type_id%TYPE;
	v_company_sid				security_pkg.T_SID_ID;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_property_type_id			property_type.property_type_id%TYPE;
	v_fund_type_id				fund_type.fund_type_id%TYPE;
	v_fund_id					fund.fund_id%TYPE;
	v_first_region_sid			security.security_pkg.T_SID_ID;
	v_first_region_desc			region_description.description%TYPE;
	
	v_test_name					VARCHAR2(100) := 'SecondaryPropByFunds_WithRole';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	-- Create a new primary region.
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;

	-- Create a company and property.
	CreateCompany(
		in_test_name		=>	v_test_name,
		in_region_root_sid	=>	v_region_root_sid,
		out_company_sid		=>	v_company_sid,
		out_flow_sid		=>	v_flow_sid
	);
	
	property_pkg.SavePropertyType(
		in_property_type_id		=>	NULL,
		in_property_type_name	=>	'TestPropType',
		in_space_type_ids		=>	'',
		in_gresb_prop_type		=>	'',
		out_property_type_id	=>	v_property_type_id
	);
	
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestProperty',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_new_region_sid_a
	);

	v_fund_type_id := fund_type_id_seq.NEXTVAL;
	INSERT INTO fund_type (fund_type_id, label)
	VALUES (v_fund_type_id, 'Test Fund Type');

	v_fund_id := fund_id_seq.NEXTVAL;
	INSERT INTO fund (fund_id, company_sid, name, year_of_inception, fund_type_id)
	VALUES (v_fund_id, v_company_sid, v_test_name||'_TestFund1', 2018, v_fund_type_id);

	INSERT INTO property_fund ( fund_id, region_sid)
	VALUES (v_fund_id, v_new_region_sid_a);
	
	INSERT INTO property_fund_ownership (region_sid, fund_id, start_dtm, ownership)
	VALUES (v_new_region_sid_a, v_fund_id, SYSDATE, 1);
	
	--Sync
	region_tree_pkg.SyncSecondaryPropByFunds(in_secondary_root_sid => v_secondary_tree_root);

	-- Check the secondary tree has the property region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_first_region_sid, v_first_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	unit_test_pkg.AssertIsTrue(v_first_region_desc = v_fund_id||'-'||v_test_name||'_TestFund1', 'Expected '||v_fund_id||'-'||v_test_name||'_TestFund1 region, found '||v_first_region_desc);
	-- Check sub tree contains linked prop region
	CheckSyncedRegionLink(v_first_region_sid, v_new_region_sid_a);

	-- Add role to secondary tree region
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = v_secondary_tree_root
	) LOOP
		role_pkg.AddRoleMemberForRegion(
			in_role_sid		=> v_role_sid,
			in_region_sid	=> r.region_sid,
			in_user_sid 	=> v_user_sid
		);
		
		CheckRegionHasRole(r.region_sid, v_role_sid);
	END LOOP;
	
	CheckRegionHasRole(v_new_region_sid_a, v_role_sid);
	
	-- Create another new tagged primary region
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestPropertyB',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_new_region_sid_b
	);

	INSERT INTO property_fund ( fund_id, region_sid)
	VALUES (v_fund_id, v_new_region_sid_b);
	
	INSERT INTO property_fund_ownership (region_sid, fund_id, start_dtm, ownership)
	VALUES (v_new_region_sid_b, v_fund_id, SYSDATE, 1);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_b,
		in_name => v_test_name||'_LinkChild',
		in_description => v_test_name||'_LinkChild',
		out_region_sid => v_child_of_link
	);
	
	-- Re-sync Tree
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	
	-- Check role was applied to new region
	CheckRegionHasRole(v_new_region_sid_b, v_role_sid);
	CheckRegionHasRole(v_child_of_link, v_role_sid);
	
	-- Clean Up
	DELETE FROM property_fund_ownership
	 WHERE fund_id = v_fund_id;
	DELETE FROM property_fund
	 WHERE fund_id = v_fund_id;
	DELETE FROM fund
	 WHERE fund_id = v_fund_id;
	DELETE FROM fund_type
	 WHERE fund_type_id = v_fund_type_id;
	
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_b);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);
	
	property_pkg.DeletePropertyType(in_property_type_id => v_property_type_id);

	DeleteCompany;
END;

PROCEDURE SyncPropTreeByMgtCompany_WithRole AS
	v_secondary_tree_root		security.security_pkg.T_SID_ID;
	
	v_region_root_sid			security.security_pkg.T_SID_ID;
	v_new_region_sid_a			security.security_pkg.T_SID_ID;
	v_new_region_sid_b			security.security_pkg.T_SID_ID;
	v_child_of_link				security.security_pkg.T_SID_ID;
	v_synced_region_sid			security.security_pkg.T_SID_ID;
	v_synced_region_sid_count	NUMBER;
	v_company_sid				security.security_pkg.T_SID_ID;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_first_region_sid			security.security_pkg.T_SID_ID;
	v_first_region_desc			region_description.description%TYPE;
	v_property_type_id			property_type.property_type_id%TYPE;
	
	v_test_name					VARCHAR2(100) := 'PropTreeByMgtCompany_WithRole';
BEGIN
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	-- Create a company and property
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	 
	CreateCompany(
		in_test_name		=>	v_test_name,
		in_region_root_sid	=>	v_region_root_sid,
		out_company_sid		=>	v_company_sid,
		out_flow_sid		=>	v_flow_sid
	);
	
	property_pkg.SavePropertyType(
		in_property_type_id		=>	NULL,
		in_property_type_name	=>	'TestPropType',
		in_space_type_ids		=>	'',
		in_gresb_prop_type		=>	'',
		out_property_type_id	=>	v_property_type_id
	);
	
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestProperty',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_new_region_sid_a
	);
	
	region_tree_pkg.SyncPropTreeByMgtCompany(in_secondary_root_sid => v_secondary_tree_root);
	
	-- Check the secondary tree has the "Others" region in it.
	CheckSyncedRegionCount(v_secondary_tree_root, 1);
	SELECT region_sid, description
	  INTO v_first_region_sid, v_first_region_desc
	  FROM csr.v$region
	 WHERE parent_sid = v_secondary_tree_root;
	unit_test_pkg.AssertIsTrue(v_first_region_desc = 'Other', 'Expected Other region, found '||v_first_region_desc);

	-- Check sub tree contains linked prop region
	CheckSyncedRegionLink(v_first_region_sid, v_new_region_sid_a);
	
	-- Add role to secondary tree region
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = v_secondary_tree_root
	) LOOP
		role_pkg.AddRoleMemberForRegion(
			in_role_sid		=> v_role_sid,
			in_region_sid	=> r.region_sid,
			in_user_sid 	=> v_user_sid
		);
		
		CheckRegionHasRole(r.region_sid, v_role_sid);
	END LOOP;
	
	CheckRegionHasRole(v_new_region_sid_a, v_role_sid);
	
	-- Create another new property primary region
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestPropertyB',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_new_region_sid_b
	);
	
	region_pkg.CreateRegion(
		in_parent_sid => v_new_region_sid_b,
		in_name => v_test_name||'_LinkChild',
		in_description => v_test_name||'_LinkChild',
		out_region_sid => v_child_of_link
	);
	
	-- Re-sync Tree
	region_tree_pkg.RefreshSecondaryRegionTree(in_region_sid => v_secondary_tree_root, in_user_sid => 3);
	
	-- Check role was applied to new region
	CheckRegionHasRole(v_new_region_sid_b, v_role_sid);
	CheckRegionHasRole(v_child_of_link, v_role_sid);
	
	-- Clean Up
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;

	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_b);
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);

	property_pkg.DeletePropertyType(in_property_type_id => v_property_type_id);

	DeleteCompany;
END;

--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin('regiontree.credit360.com');
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_role_sid);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_user_sid);

	chain.test_chain_utils_pkg.TearDownTwoTier;
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;

END test_region_tree_pkg;
/
