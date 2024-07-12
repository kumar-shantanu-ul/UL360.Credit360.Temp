CREATE OR REPLACE PACKAGE BODY csr.test_issue_co_involve_upd_pkg AS

CARRY_FWD					number(1, 0) := 1;

v_site_name					VARCHAR(50) := 'auditor-company-involvement-test.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_administrator_sid			security.security_pkg.T_SID_ID;

v_top_company_sid			security.security_pkg.T_SID_ID;
v_vendor_sid_1				security.security_pkg.T_SID_ID;
v_vendor_sid_2				security.security_pkg.T_SID_ID;
v_site_sid					security.security_pkg.T_SID_ID;
v_site_company_region_sid	security.security_pkg.T_SID_ID;

v_workflow_sid				security.security_pkg.T_SID_ID;
v_flow_state_id 			csr.flow_state.flow_state_id%TYPE;
v_audit_type_involved		csr.internal_audit_type.internal_audit_type_id%TYPE;
v_audit_type_not_involved	csr.internal_audit_type.internal_audit_type_id%TYPE;

PROCEDURE CreateSite
AS
BEGIN
	security.user_pkg.LogonAdmin;

	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, '//Aspen/Applications/' || v_site_name);
		security.user_pkg.LogonAdmin(v_site_name);
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);
END;

PROCEDURE CreateWorkflow
AS
BEGIN
	csr.unit_test_pkg.GetOrCreateWorkflow(
		in_label						=> 'Audit workflow for auditor company involvement database tests',
		in_flow_alert_class				=> 'audit',
		out_sid							=> v_workflow_sid);

	csr.unit_test_pkg.GetOrCreateWorkflowState(
		in_flow_sid         => v_workflow_sid,
		in_state_label      => 'Default state',
		in_state_lookup_key => 'DEFAULT',
		out_flow_state_id   => v_flow_state_id);
END;

PROCEDURE EnableAuditCapabilities
AS
	v_top_company_type_sid		security.security_pkg.T_SID_ID;
	v_vendor_company_type_sid	security.security_pkg.T_SID_ID;
	v_site_company_type_sid		security.security_pkg.T_SID_ID;
	v_capability_id				chain.capability.capability_id%TYPE;
BEGIN
	v_top_company_type_sid := chain.company_type_pkg.GetCompanyTypeId('TOP');
	v_vendor_company_type_sid := chain.company_type_pkg.GetCompanyTypeId('VENDOR');		
	v_site_company_type_sid := chain.company_type_pkg.GetCompanyTypeId('SITE');

	SELECT capability_id
	  INTO v_capability_id
	  FROM chain.capability
	 WHERE lower(capability_name) = 'create supplier audit on behalf of';
 
	chain.type_capability_pkg.SetPermission(
		in_capability_id				=> v_capability_id,
		in_primary_company_type_id		=> v_top_company_type_sid,
		in_secondary_company_type_id	=> v_vendor_company_type_sid,
		in_tertiary_company_type_id		=> v_site_company_type_sid,
		in_company_group_type_id		=> 1,
		in_role_sid						=> null,
		in_permission_set				=> 2);
END;

FUNCTION AddCompany(
	in_label			chain.company.name%TYPE,
	in_company_type_id	chain.company_type.company_type_id%TYPE
) RETURN security.security_pkg.T_SID_ID
AS
	v_out_company_sid	security.security_pkg.T_SID_ID;
BEGIN
	chain.test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> in_label,
		in_country_code		=> 'gb',
		in_company_type_id	=> in_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_out_company_sid);

	RETURN v_out_company_sid;
END;

FUNCTION AddAuditType(
	in_label						IN	csr.internal_audit_type.label%TYPE,
	in_involve_auditor_in_issues	IN	csr.internal_audit_type.involve_auditor_in_issues%TYPE
) RETURN csr.internal_audit_type.internal_audit_type_id%TYPE
AS
	v_empty_sids	security.security_pkg.T_SID_IDS;
	v_type_sids		security.security_pkg.T_SID_IDS;
	v_out_cur		SYS_REFCURSOR;
	v_audit_type_id	csr.internal_audit_type.internal_audit_type_id%TYPE;
BEGIN
	csr.audit_pkg.SaveInternalAuditType(
		in_internal_audit_type_id		=> null,
		in_label						=> in_label,
		in_every_n_months				=> null,
		in_auditor_role_sid				=> null,
		in_audit_contact_role_sid		=> null,
		in_default_survey_sid			=> null,
		in_default_auditor_org			=> null,
		in_override_issue_dtm			=> 0,
		in_assign_issues_to_role		=> 0,
		in_involve_auditor_in_issues	=> in_involve_auditor_in_issues,
		in_auditor_can_take_ownership	=> 0,
		in_add_nc_per_question			=> 0,
		in_nc_audit_child_region		=> 0,
		in_flow_sid						=> v_workflow_sid,
		in_internal_audit_source_id		=> 1,
		in_summary_survey_sid			=> null,
		in_send_auditor_expiry_alerts	=> 0,
		in_expiry_alert_roles			=> v_empty_sids,
		in_validity_months				=> null,
		in_audit_c_role_or_group_sid	=> null,
		in_tab_sid						=> null,
		in_form_path					=> null,
		in_form_sid						=> null,
		in_ia_type_group_id				=> null,
		in_nc_score_type_id				=> null,
		in_active						=> 1,
		in_show_primary_survey_in_hdr	=> 0,
		in_use_legacy_closed_def		=> 0,
		out_cur							=> v_out_cur);

	SELECT max(internal_audit_type_id) INTO v_audit_type_id FROM csr.internal_audit_type WHERE label = in_label;

	-- Update the audit type to enable carrying forward of open issues
	v_type_sids(1) := v_audit_type_id;

	csr.audit_pkg.SetAuditTypeCarryForwards(
		in_to_ia_type_id	=> v_audit_type_id,
		in_from_ia_type_ids	=> v_type_sids);

	RETURN v_audit_type_id;
END;

FUNCTION AddAudit(
	in_label				IN	csr.internal_audit.label%TYPE,
	in_audit_dtm			IN	csr.internal_audit.audit_dtm%TYPE,
	in_audit_type_id		IN	csr.internal_audit_type.internal_audit_type_id%TYPE,
	in_region_sid			IN	security.security_pkg.T_SID_ID,
	in_auditor_company_sid	IN	security.security_pkg.T_SID_ID,
	in_carry_fwd			IN	NUMBER DEFAULT 0
) RETURN security.security_pkg.T_SID_ID
AS
	v_audit_sid		security.security_pkg.T_SID_ID;
	v_carry_fwd_sid	security.security_pkg.T_SID_ID;
	v_audit_label	csr.internal_audit.label%TYPE;
BEGIN
	csr.audit_pkg.Save(
		in_sid_id 					=> null,
		in_audit_ref				=> null,
		in_survey_sid				=> null,
		in_region_sid				=> in_region_sid,
		in_label					=> in_label,
		in_audit_dtm				=> in_audit_dtm,
		in_auditor_user_sid			=> security.security_pkg.GetSID(),
		in_notes					=> null,
		in_internal_audit_type		=> in_audit_type_id,
		in_auditor_name				=> null,
		in_auditor_org				=> null,
		in_response_to_audit		=> null,
		in_created_by_sid			=> null,
		in_auditee_user_sid			=> null,
		in_auditee_company_sid		=> null,
		in_auditor_company_sid		=> in_auditor_company_sid,
		in_created_by_company_sid	=> null,
		in_permit_id				=> null,
		out_sid_id					=> v_audit_sid);

	IF in_carry_fwd = CARRY_FWD THEN
		SELECT MAX(ia.internal_audit_sid)
		  INTO v_carry_fwd_sid
		  FROM csr.internal_audit ia
		 WHERE region_sid = in_region_sid
		   AND internal_audit_type_id = in_audit_type_id
		   AND audit_dtm < in_audit_dtm;

		csr.audit_pkg.CarryForwardOpenNCs(v_carry_fwd_sid, v_audit_sid, 0);
	END IF;

	RETURN v_audit_sid;
END;

FUNCTION AddFinding(
	in_audit_sid	security.security_pkg.T_SID_ID
) RETURN csr.non_compliance.non_compliance_id%TYPE
AS
BEGIN
	RETURN csr.unit_test_pkg.GetOrCreateNonComplianceId(in_audit_sid, 'Finding 1');
END;

FUNCTION AddIssue(
	in_finding_id	csr.non_compliance.non_compliance_id%TYPE
) RETURN csr.issue.issue_id%TYPE
AS
	v_issue_id	csr.issue.issue_id%TYPE;
BEGIN
	csr.audit_pkg.AddNonComplianceIssue(in_finding_id, 'Issue 1', null, null, v_administrator_sid, null, 0, 0, v_issue_id);
	RETURN v_issue_id;
END;

PROCEDURE SwitchAuditorCompany(
	in_audit_sid		security.security_pkg.T_SID_ID,
	in_new_company_sid	security.security_pkg.T_SID_ID
)
AS
	v_audit_sid			security.security_pkg.T_SID_ID;
	v_label				csr.internal_audit.label%TYPE;
	v_audit_dtm			csr.internal_audit.audit_dtm%TYPE;
	v_audit_type_id		csr.internal_audit_type.internal_audit_type_id%TYPE;
	v_region_sid		security.security_pkg.T_SID_ID;
BEGIN
	SELECT label, audit_dtm, internal_audit_type_id, region_sid
	  INTO v_label, v_audit_dtm, v_audit_type_id, v_region_sid
	  FROM csr.internal_audit
	 WHERE internal_audit_sid = in_audit_sid;

	csr.audit_pkg.Save(
		in_sid_id					=> in_audit_sid,
		in_audit_ref				=> null,
		in_survey_sid				=> null,
		in_region_sid				=> v_region_sid,
		in_label					=> v_label,
		in_audit_dtm				=> v_audit_dtm,
		in_auditor_user_sid			=> security.security_pkg.GetSID(),
		in_notes					=> null,
		in_internal_audit_type		=> v_audit_type_id,
		in_auditor_name				=> null,
		in_auditor_org				=> null,
		in_response_to_audit		=> null,
		in_created_by_sid			=> null,
		in_auditee_user_sid			=> null,
		in_auditee_company_sid		=> null,
		in_auditor_company_sid		=> in_new_company_sid,
		in_created_by_company_sid	=> null,
		in_permit_id				=> null,
		out_sid_id					=> v_audit_sid);
END;

PROCEDURE RemoveCompanies
AS
BEGIN
	chain.company_pkg.DeleteCompany(v_vendor_sid_1);
	chain.company_pkg.DeleteCompany(v_vendor_sid_2);
	chain.company_pkg.DeleteCompany(v_site_sid);
END;

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	v_vendor_sid_1 := AddCompany('Vendor 1', chain.company_type_pkg.GetCompanyTypeId('VENDOR'));
	v_vendor_sid_2 := AddCompany('Vendor 2', chain.company_type_pkg.GetCompanyTypeId('VENDOR'));
	v_site_sid := AddCompany('Site 1', chain.company_type_pkg.GetCompanyTypeId('SITE'));

	SELECT region_sid INTO v_site_company_region_sid FROM csr.region WHERE name = 'Site 1 (' || v_site_sid || ')';

	v_audit_type_involved 		:= AddAuditType('INVOLVED', 1);
	v_audit_type_not_involved	:= AddAuditType('NOT_INVOLVED', 0);
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	RemoveCompanies;
END;

-- Called once before all tests
PROCEDURE SetUpFixture
AS
BEGIN
	CreateSite;

	security.user_pkg.LogonAdmin(v_site_name);

	SELECT csr_user_sid
	  INTO v_administrator_sid
	  FROM csr.csr_user
	 WHERE user_name = 'builtinadministrator';

	csr.unit_test_pkg.EnableAudits;
	csr.unit_test_pkg.EnableChain;
	csr.enable_pkg.EnableWorkflow;

	CreateWorkflow;

	chain.company_type_pkg.AddTertiaryRelationship('TOP', 'VENDOR', 'SITE');

	EnableAuditCapabilities;

	SELECT top_company_sid
	  INTO v_top_company_sid
	  FROM chain.customer_options
	 WHERE app_sid = security.security_pkg.GetApp;

END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;

-----------------------------------------
-- ASSERTS
-----------------------------------------
PROCEDURE AssertInvolvementCount(
	in_expected_count		NUMBER,
	in_issue_id				csr.issue.issue_id%TYPE,
	in_company_sid			security.security_pkg.T_SID_ID,
	in_company_description	VARCHAR2
)
AS
	v_actual_involvements	NUMBER(10, 0);
BEGIN
	SELECT COUNT(*)
	  INTO v_actual_involvements
	  FROM csr.issue_involvement
	 WHERE issue_id = in_issue_id
	   AND company_sid = in_company_sid;

	csr.unit_test_pkg.AssertAreEqual(
		in_expected_count,
		v_actual_involvements,
		'Incorrect number of issue involvements for the ' || in_company_description);
END;

-----------------------------------------
-- TESTS
-----------------------------------------
PROCEDURE SwitchTopToInterOneAudit
AS
	v_audit_sid			security.security_pkg.T_SID_ID;
	v_finding_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id			csr.issue.issue_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit of an audit type that automatically involves the auditor company with issues
	-- And the auditor company is the top company
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_top_company_sid);

	-- And a finding that has an issue
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);

	-- When the auditor company is switched to an intermediary company
	-- Then the intermediary company is involved with the issue
	SwitchAuditorCompany(v_audit_sid, v_vendor_sid_1);
	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_1, 'intermediary company');
END;

PROCEDURE SwitchInterToTopOneAudit
AS
	v_audit_sid			security.security_pkg.T_SID_ID;
	v_finding_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id			csr.issue.issue_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit of an audit type that automatically involves the auditor company with issues
	-- And the auditor company is an intermediary company
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1);

	-- And a finding that has an issue
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);

	-- When the auditor company is switched to an intermediary company
	-- Then the intermediary company is not involved with the issue
	SwitchAuditorCompany(v_audit_sid, v_top_company_sid);
	AssertInvolvementCount(0, v_issue_id, v_vendor_sid_1, 'intermediary company');
END;

PROCEDURE SwitchIntersOneAudit
AS
	v_audit_sid			security.security_pkg.T_SID_ID;
	v_finding_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id			csr.issue.issue_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit of an audit type that automatically involves the auditor company with issues
	-- And the auditor company is an intermediary company
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1);

	-- And a finding that has an issue
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);

	-- When the auditor company is switched to another intermediary company
	-- Then the previous intermediary company is no longer involved with the issue
	-- And the new intermediary company is involved with the issue
	SwitchAuditorCompany(v_audit_sid, v_vendor_sid_2);

	AssertInvolvementCount(0, v_issue_id, v_vendor_sid_1, 'original intermediary company');
	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_2, 'new intermediary company');
END;

PROCEDURE SwitchTopToInterTwoAudits
AS
	v_audit_sid_1		security.security_pkg.T_SID_ID;
	v_audit_sid_2		security.security_pkg.T_SID_ID;
	v_finding_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id			csr.issue.issue_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit type that automatically involves the auditor company with issues and also allows the carrying forward of data from itself
	-- And an audit of that type that has a finding and an issue and an auditor company of the top company
	v_audit_sid_1 := AddAudit('Audit1', SYSDATE - 1, v_audit_type_involved, v_site_company_region_sid, v_top_company_sid);
	v_finding_id := AddFinding(v_audit_sid_1);
	v_issue_id := AddIssue(v_finding_id);

	-- And a second audit is created of the same audit type that also has an auditor company of the top company
	v_audit_sid_2 := AddAudit('Audit2', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_top_company_sid);

	-- When the auditor company of the first audit is switched to an intermediary company
	-- Then the intermediary company is involved with the issue
	SwitchAuditorCompany(v_audit_sid_1, v_vendor_sid_1);
	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_1, 'intermediary company');
END;

PROCEDURE SwitchInterToTopTwoAudits
AS
	v_audit_sid_1		security.security_pkg.T_SID_ID;
	v_audit_sid_2		security.security_pkg.T_SID_ID;
	v_finding_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id			csr.issue.issue_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit type that automatically involves the auditor company with issues and also allows the carrying forward of data from itself
	-- And an audit of that type that has a finding and an issue and an auditor company of an intermediary company
	v_audit_sid_1 := AddAudit('Audit1', SYSDATE - 7, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1);
	v_finding_id := AddFinding(v_audit_sid_1);
	v_issue_id := AddIssue(v_finding_id);

	-- And a second audit is created of the same audit type that also has an auditor company of the same intermediary company
	v_audit_sid_2 := AddAudit('Audit2', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1, CARRY_FWD);

	-- When the auditor company of the first audit is switched to the top company
	-- Then the intermediary company remains involved with the issue
	SwitchAuditorCompany(v_audit_sid_1, v_top_company_sid);
	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_1, 'intermediary company');

	-- When the auditor company of the second audit is also switched to the top company
	-- Then the intermediary company is no longer involved with the issue
	SwitchAuditorCompany(v_audit_sid_2, v_top_company_sid);
	AssertInvolvementCount(0, v_issue_id, v_vendor_sid_1, 'intermediary company');
END;

PROCEDURE SwitchIntersTwoAudits
AS
	v_audit_sid_1		security.security_pkg.T_SID_ID;
	v_audit_sid_2		security.security_pkg.T_SID_ID;
	v_finding_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id			csr.issue.issue_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit type that automatically involves the auditor company with issues and also allows the carrying forward of data from itself
	-- And an audit of that type that has a finding and an issue and an auditor company of an intermediary company
	v_audit_sid_1 := AddAudit('Audit1', SYSDATE - 7, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1);
	v_finding_id := AddFinding(v_audit_sid_1);
	v_issue_id := AddIssue(v_finding_id);

	-- And a second audit is created of the same audit type that also has an auditor company of the same intermediary company
	v_audit_sid_2 := AddAudit('Audit2', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1, CARRY_FWD);

	-- When the auditor company of the first audit is switched to another intermediary company
	-- Then the first intermediary company is involved with the issue
	-- And the second intermediary company is also involved with the issue
	SwitchAuditorCompany(v_audit_sid_1, v_vendor_sid_2);

	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_1, 'first intermediary company');
	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_2, 'second intermediary company');

	-- When the auditor company of the second audit is also switched to the other intermediary company
	-- Then the first intermediary company is no longer involved with the issue
	-- And the second intermediary company remains involved with the issue
	SwitchAuditorCompany(v_audit_sid_2, v_vendor_sid_2);

	AssertInvolvementCount(0, v_issue_id, v_vendor_sid_1, 'first intermediary company');
	AssertInvolvementCount(1, v_issue_id, v_vendor_sid_2, 'second intermediary company');

END;

PROCEDURE SwitchIntersManyFindings
AS
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id_1			csr.non_compliance.non_compliance_id%TYPE;
	v_finding_id_2			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id_1			csr.issue.issue_id%TYPE;
	v_issue_id_2			csr.issue.issue_id%TYPE;
	v_issue_id_3			csr.issue.issue_id%TYPE;
	v_issue_id_4			csr.issue.issue_id%TYPE;
	v_actual_involvements	security.security_pkg.T_SID_ID;
	v_actual_issues			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	-- Given an audit type that automatically involves the auditor company with issues
	-- And an audit of that type that has two findings each with two issues
	-- And an auditor company of an intermediary company
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_audit_type_involved, v_site_company_region_sid, v_vendor_sid_1);

	-- And a finding that has an issue
	v_finding_id_1 := AddFinding(v_audit_sid);
	v_finding_id_2 := AddFinding(v_audit_sid);
	v_issue_id_1 := AddIssue(v_finding_id_1);
	v_issue_id_2 := AddIssue(v_finding_id_1);
	v_issue_id_3 := AddIssue(v_finding_id_2);
	v_issue_id_4 := AddIssue(v_finding_id_2);

	-- When the auditor company is switched to another intermediary company
	SwitchAuditorCompany(v_audit_sid, v_vendor_sid_2);

	-- Then the previous intermediary company is no longer involved with any of the issues
	SELECT COUNT(*), COUNT(DISTINCT issue_id)
	  INTO v_actual_involvements, v_actual_issues
	  FROM csr.issue_involvement
	 WHERE issue_id IN (v_issue_id_1, v_issue_id_2, v_issue_id_3, v_issue_id_4)
	   AND company_sid = v_vendor_sid_1;

	csr.unit_test_pkg.AssertAreEqual(0, v_actual_involvements, 'Incorrect number of issue involvements for the original auditor company');

	-- And the new intermediary company is involved with all of the issues
	SELECT COUNT(*), COUNT(DISTINCT issue_id)
	  INTO v_actual_involvements, v_actual_issues
	  FROM csr.issue_involvement
	 WHERE issue_id IN (v_issue_id_1, v_issue_id_2, v_issue_id_3, v_issue_id_4)
	   AND company_sid = v_vendor_sid_2;

	csr.unit_test_pkg.AssertAreEqual(4, v_actual_involvements, 'Incorrect number of issue involvements for the new auditor company.');
	csr.unit_test_pkg.AssertAreEqual(4, v_actual_issues, 'Incorrect number of issues for the new auditor company.');
END;

END;
/