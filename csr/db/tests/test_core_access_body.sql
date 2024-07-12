CREATE OR REPLACE PACKAGE BODY csr.test_core_access_pkg AS

v_site_name		VARCHAR2(200);
v_regs			security_pkg.T_SID_IDS;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE RemoveSids(
	v_sids		security_pkg.T_SID_IDS
)
AS
BEGIN
	IF v_sids.COUNT > 0 THEN
		FOR i IN v_sids.FIRST..v_sids.LAST
		LOOP
			security.securableobject_pkg.deleteso(security_pkg.getact, v_sids(i));
		END LOOP;
	END IF;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_primary_root_sid				security.security_pkg.T_SID_ID;
	v_cust_comp_sid					security.security_pkg.T_SID_ID;
	v_xml							CLOB;
	v_str 							VARCHAR2(2000);
BEGIN
	Trace('SetUpFixture');
	v_site_name	:= in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	v_regs(1) := csr.unit_test_pkg.GetOrCreateRegion('REGION_RECORD_1');
	v_regs(2) := csr.unit_test_pkg.GetOrCreateRegion('REGION_RECORD_1_1', v_regs(1), csr.csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(3) := csr.unit_test_pkg.GetOrCreateRegion('REGION_RECORD_1_1_1', v_regs(2));
	v_regs(4) := csr.unit_test_pkg.GetOrCreateRegion('REGION_RECORD_1_2', v_regs(1), csr.csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(5) := csr.unit_test_pkg.GetOrCreateRegion('REGION_RECORD_1_3', v_regs(1), csr.csr_data_pkg.REGION_TYPE_PROPERTY);

	UPDATE region 
		SET active = 0
	WHERE region_sid = v_regs(5);

	FOR r IN (SELECT tab_sid FROM cms.tab WHERE oracle_schema = 'TESTCOREACCESS')
	LOOP
		security.securableobject_pkg.DeleteSO(
			in_act_id => security.security_pkg.getact,
			in_sid_id => r.tab_sid);
	END LOOP;
END;

PROCEDURE SetUp AS
	v_company_sid					security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;


PROCEDURE TestGetUserRecordByUserName AS
	in_user_name			csr.csr_user.user_name%TYPE;
	out_user				CSR.T_USER;
BEGIN
	
	in_user_name := 'admin';
	core_access_pkg.GetUserRecordByUserName(in_user_name => in_user_name, out_user => out_user);
	unit_test_pkg.AssertIsTrue(out_user.csr_user_sid > 0, 'csr_user_sid is not valid');

	in_user_name := 'invaliduser';
	BEGIN
		core_access_pkg.GetUserRecordByUserName(in_user_name => in_user_name, out_user => out_user);
		unit_test_pkg.TestFail('Should not succeed');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	unit_test_pkg.AssertAreEqual(1, 1, 'Expected success');
END;

PROCEDURE TestGetRegionRecord AS
	in_region_sid		region.region_sid%TYPE;
	out_region			csr.T_REGION;
BEGIN
	core_access_pkg.GetRegionRecord(in_region_sid => v_regs(2), out_region => out_region);

	unit_test_pkg.AssertAreEqual(v_regs(2), out_region.region_sid, 'Failed to get region record');
END;

PROCEDURE TestGetChildRegionRecords AS
	in_region_sid			region.region_sid%TYPE;
	in_include_inactive		NUMBER DEFAULT 0;
	out_regions				csr.T_REGIONS;
BEGIN
	core_access_pkg.GetChildRegionRecords(in_region_sid => v_regs(1), in_include_inactive => 0, out_regions => out_regions);

	unit_test_pkg.AssertAreEqual(2, out_regions.Count, 'Failed to get region children');
	unit_test_pkg.AssertAreEqual(v_regs(2), out_regions(1).region_sid, 'Failed to get region');
	unit_test_pkg.AssertAreEqual(v_regs(4), out_regions(2).region_sid, 'Failed to get region');

	core_access_pkg.GetChildRegionRecords(in_region_sid => v_regs(1), in_include_inactive => 1, out_regions => out_regions);

	unit_test_pkg.AssertAreEqual(3, out_regions.Count, 'Failed to get inactive region children');
	unit_test_pkg.AssertAreEqual(v_regs(2), out_regions(1).region_sid, 'Failed to get region');
	unit_test_pkg.AssertAreEqual(v_regs(4), out_regions(2).region_sid, 'Failed to get region');
	unit_test_pkg.AssertAreEqual(v_regs(5), out_regions(3).region_sid, 'Failed to get region');
END;

PROCEDURE TestUpdateAuditRegion
AS
	in_new_region_sid		security.security_pkg.T_SID_ID;
	v_user_sid				security.security_pkg.T_SID_ID;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_region_sid			security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
BEGIN
	v_regs(6) := csr.unit_test_pkg.GetOrCreateRegion('Old Region 1');
	v_user_sid := unit_test_pkg.GetOrCreateUser('User 1');

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'Audit 1',
		in_region_sid	=> 	v_regs(6),
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(v_audit_sid, 'Finding 1');
	audit_pkg.AddNonComplianceIssue(v_finding_id, 'Issue 1', NULL, NULL, v_user_sid, NULL, 0, 0, v_issue_id);

	core_access_pkg.UpdateAuditRegion(in_audit_sid => v_audit_sid, in_new_region_sid => v_regs(4));
	
	SELECT region_sid
	  INTO v_region_sid
	  FROM internal_audit
	 WHERE internal_audit_sid = v_audit_sid;
	
	unit_test_pkg.AssertAreEqual(v_regs(4), v_region_sid, 'Audit region not updated');

	SELECT MIN(region_sid)
	  INTO v_region_sid
	  FROM non_compliance
	 WHERE created_in_audit_sid = v_audit_sid;
	
	unit_test_pkg.AssertAreEqual(v_regs(4), v_region_sid, 'Finding region not updated');

	SELECT MIN(region_sid)
	  INTO v_region_sid
	  FROM issue
	 WHERE issue_id = v_issue_id;
	
	unit_test_pkg.AssertAreEqual(v_regs(4), v_region_sid, 'Issue region not updated');
END;

PROCEDURE TestUpdateAuditRegionNoIssue
AS
	in_new_region_sid		security.security_pkg.T_SID_ID;
	v_user_sid				security.security_pkg.T_SID_ID;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_region_sid			security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
BEGIN
	v_regs(6) := csr.unit_test_pkg.GetOrCreateRegion('Old Region 1');
	v_user_sid := unit_test_pkg.GetOrCreateUser('User 1');

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'Audit 2',
		in_region_sid	=> 	v_regs(6),
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(v_audit_sid, 'Finding 1');

	core_access_pkg.UpdateAuditRegion(in_audit_sid => v_audit_sid, in_new_region_sid => v_regs(4));
	
	SELECT region_sid
	  INTO v_region_sid
	  FROM internal_audit
	 WHERE internal_audit_sid = v_audit_sid;
	
	unit_test_pkg.AssertAreEqual(v_regs(4), v_region_sid, 'Audit region not updated');

	SELECT MIN(region_sid)
	  INTO v_region_sid
	  FROM non_compliance
	 WHERE created_in_audit_sid = v_audit_sid;
	
	unit_test_pkg.AssertAreEqual(v_regs(4), v_region_sid, 'Finding region not updated');
END;

PROCEDURE TestUpdateAuditRegionNoFinding
AS
	in_new_region_sid		security.security_pkg.T_SID_ID;
	v_user_sid				security.security_pkg.T_SID_ID;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_region_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_regs(6) := csr.unit_test_pkg.GetOrCreateRegion('Old Region 1');
	v_user_sid := unit_test_pkg.GetOrCreateUser('User 1');

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'Audit 3',
		in_region_sid	=> 	v_regs(6),
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	core_access_pkg.UpdateAuditRegion(in_audit_sid => v_audit_sid, in_new_region_sid => v_regs(4));
	
	SELECT region_sid
	  INTO v_region_sid
	  FROM internal_audit
	 WHERE internal_audit_sid = v_audit_sid;
	
	unit_test_pkg.AssertAreEqual(v_regs(4), v_region_sid, 'Audit region not updated');
END;

PROCEDURE TestSetCmsTableHelperPackage
AS
	v_tab_sid		cms.tab.tab_sid%TYPE;
	v_result		VARCHAR2(200);
BEGIN

	cms.tab_pkg.AddTable(
		in_oracle_schema				=>	'TESTCOREACCESS',
		in_oracle_table					=>	'TestCoreAccess_table01',
		in_managed						=>	0,
		in_auto_registered				=>	0,
		out_tab_sid						=>	v_tab_sid
	);
	
	core_access_pkg.SetCmsTableHelperPackage(
		in_schema			=> 'TESTCOREACCESS',
		in_oracle_table		=> 'someothertable',
		in_helper_pkg		=> 'helper_pkg'
	);

	SELECT helper_pkg
	  INTO v_result
	  FROM cms.tab
	 WHERE tab_sid = v_tab_sid;

	unit_test_pkg.AssertIsNull(v_result, 'Helper pkg should be null');

	core_access_pkg.SetCmsTableHelperPackage(
		in_schema			=> 'TESTCOREACCESS',
		in_oracle_table		=> 'TestCoreAccess_table01',
		in_helper_pkg		=> 'helper_pkg'
	);


	SELECT helper_pkg
	  INTO v_result
	  FROM cms.tab
	 WHERE tab_sid = v_tab_sid;

	unit_test_pkg.AssertAreEqual('helper_pkg', v_result, 'Helper pkg should be set');

	core_access_pkg.SetCmsTableHelperPackage(
		in_schema			=> 'TESTCOREACCESS',
		in_oracle_table		=> 'TestCoreAccess_table01',
		in_helper_pkg		=> NULL
	);

	SELECT helper_pkg
	  INTO v_result
	  FROM cms.tab
	 WHERE tab_sid = v_tab_sid;

	unit_test_pkg.AssertIsNull(v_result, 'Helper pkg should be null');


	security.securableobject_pkg.DeleteSO(
		in_act_id => security.security_pkg.getact,
		in_sid_id => v_tab_sid);

END;

PROCEDURE TestSetCmsTableFlowSid
AS
	v_tab_sid		cms.tab.tab_sid%TYPE;
	v_flow_sid		csr.flow.flow_sid%TYPE;
	v_workflows_sid	security.security_pkg.T_SID_ID;
	v_result		security.security_pkg.T_SID_ID;
BEGIN
	v_workflows_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Workflows');

	flow_pkg.CreateFlow(
		in_label				=> 'TestCoreAccess_SetCmsTableFlowSid_Workflow',
		in_parent_sid 			=> v_workflows_sid,
		in_flow_alert_class 	=> 'audit',
		out_flow_sid 			=> v_flow_sid
	);


	cms.tab_pkg.AddTable(
		in_oracle_schema				=>	'TESTCOREACCESS',
		in_oracle_table					=>	'TestCoreAccess_table02',
		in_managed						=>	0,
		in_auto_registered				=>	0,
		out_tab_sid						=>	v_tab_sid
	);

	SELECT flow_sid
	  INTO v_result
	  FROM cms.tab
	 WHERE app_sid = security.security_pkg.GetApp
	   AND oracle_table = 'TestCoreAccess_table02';

	unit_test_pkg.AssertIsNull(v_result, 'Flow Sid should be null');

	core_access_pkg.SetCmsTableFlowSid(
		in_workflow_label	=> 'TestCoreAccess_SetCmsTableFlowSid_Workflow',
		in_oracle_table		=> 'TestCoreAccess_table02'
	);

	SELECT flow_sid
	  INTO v_result
	  FROM cms.tab
	 WHERE app_sid = security.security_pkg.GetApp
	   AND oracle_table = 'TestCoreAccess_table02';

	unit_test_pkg.AssertAreEqual(v_flow_sid, v_result, 'Flow Sid should be set');

	core_access_pkg.SetCmsTableFlowSid(
		in_workflow_sid		=> NULL,
		in_oracle_table		=> 'TestCoreAccess_table02'
	);

	SELECT flow_sid
	  INTO v_result
	  FROM cms.tab
	 WHERE app_sid = security.security_pkg.GetApp
	   AND oracle_table = 'TestCoreAccess_table02';

	unit_test_pkg.AssertIsNull(v_result, 'Flow Sid should be null');


	core_access_pkg.SetCmsTableFlowSid(
		in_workflow_sid		=> v_flow_sid,
		in_oracle_table		=> 'TestCoreAccess_table02'
	);

	SELECT flow_sid
	  INTO v_result
	  FROM cms.tab
	 WHERE app_sid = security.security_pkg.GetApp
	   AND oracle_table = 'TestCoreAccess_table02';

	unit_test_pkg.AssertAreEqual(v_flow_sid, v_result, 'Flow Sid should be set');
END;

/*
* This doesn't seem to have any simple way to create this sort of test setup.

PROCEDURE TestSetCmsTableColumnNullable
AS
	v_tab_sid		cms.tab.tab_sid%TYPE;
	v_result		NUMBER;
BEGIN

	cms.tab_pkg.AddTable(
		in_oracle_schema				=>	'TESTCOREACCESS',
		in_oracle_table					=>	'C$TESTCOREACCESSTABLE03',
		in_managed						=>	1,
		in_auto_registered				=>	0,
		out_tab_sid						=>	v_tab_sid
	);

	cms.tab_pkg.AddColumn(
		in_oracle_schema			=>	'TESTCOREACCESS',
		in_oracle_table				=>	'C$TESTCOREACCESSTABLE03',
		in_oracle_column			=>	'TESTCOREACCESSCOLUMN01',
		in_type						=>	'varchar2'
	);

	SELECT nullable
	  INTO v_result
	  FROM cms.tab_column
	 WHERE tab_sid = v_tab_sid
	   AND oracle_column = 'TESTCOREACCESSCOLUMN01';

	unit_test_pkg.AssertAreEqual(v_result, 0, 'Flow Sid should be zero');

	core_access_pkg.SetCmsTableColumnNullable(
		in_oracle_schema	=> 'TESTCOREACCESS',
		in_oracle_table		=> 'C$TESTCOREACCESSTABLE03',
		in_oracle_column	=> 'TESTCOREACCESSCOLUMN01',
		in_nullable			=> 1
	);

	SELECT nullable
	  INTO v_result
	  FROM cms.tab_column
	 WHERE tab_sid = v_tab_sid
	   AND oracle_column = 'TESTCOREACCESSCOLUMN01';

	unit_test_pkg.AssertAreEqual(v_result, 1, 'Flow Sid should be one');

	core_access_pkg.SetCmsTableColumnNullable(
		in_oracle_schema	=> 'TESTCOREACCESS',
		in_oracle_table		=> 'C$TESTCOREACCESSTABLE03',
		in_oracle_column	=> 'TESTCOREACCESSCOLUMN01',
		in_nullable			=> 0
	);

	SELECT nullable
	  INTO v_result
	  FROM cms.tab_column
	 WHERE tab_sid = v_tab_sid
	   AND oracle_column = 'TESTCOREACCESSCOLUMN01';

	unit_test_pkg.AssertAreEqual(v_result, 0, 'Flow Sid should be zero');

END;
*/

PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
	v_flow_sid	security.security_pkg.T_SID_ID;
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);

	RemoveSids(v_regs);

	FOR r IN (SELECT tab_sid FROM cms.tab WHERE oracle_schema = 'TESTCOREACCESS')
	LOOP
		security.securableobject_pkg.DeleteSO(
			in_act_id => security.security_pkg.getact,
			in_sid_id => r.tab_sid);
	END LOOP;

	SELECT MIN(flow_sid)
	  INTO v_flow_sid
	  FROM flow
	 WHERE label like 'TestCoreAccess_%_Workflow';
	 
	IF v_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(
			in_act_id			=> security.security_pkg.GetACT,
			in_sid_id			=> v_flow_sid
		);
	END IF;
	
	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'audit';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;


END test_core_access_pkg;
/
