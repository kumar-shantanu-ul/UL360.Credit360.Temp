CREATE OR REPLACE PACKAGE BODY csr.test_audit_report_pkg AS

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-audit-report.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_administrator_sid			security.security_pkg.T_SID_ID;

v_region_sid				security.security_pkg.T_SID_ID;
v_workflow_sid				security.security_pkg.T_SID_ID;

v_default_audit_type_id		csr.internal_audit_type.internal_audit_type_id%TYPE;
v_audit_report_id			csr.internal_audit_type_report.internal_audit_type_report_id%TYPE;
v_audit_type_report_id		csr.internal_audit_type_report.internal_audit_type_report_id%TYPE;
v_issue_type_id				csr.issue_type.issue_type_id%TYPE;

-- Scenario scope
v_restrict_group_sid		security.security_pkg.T_SID_ID;
v_user_to_test_sid			security.security_pkg.T_SID_ID;

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

FUNCTION CreateUser (
	in_name				IN	csr.csr_user.user_name%TYPE,
	in_group_sid		IN	security.security_pkg.T_SID_ID
) RETURN security.security_pkg.T_SID_ID
AS
	v_user_sid			security.security_pkg.T_SID_ID;
BEGIN
	
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser (
		in_name			=> in_name,
		in_group_sid	=> in_group_sid
	);
	commit; -- we have to commit the above user creation so that we can log on as them
	
	RETURN v_user_sid;
END;

PROCEDURE AddUserToGroup (
	in_user_sid		IN security.security_pkg.T_SID_ID,
	in_group_sid	IN security.security_pkg.T_SID_ID
)
AS
BEGIN
	csr.csr_user_pkg.AddUserToGroupLogged(in_user_sid, in_group_sid, in_group_sid);
	commit; -- we have to commit this so that the group is included in the act groups when the user next logs on
END;

FUNCTION GetGroup (
	in_name		IN security.securable_object.name%TYPE
) RETURN security.security_pkg.T_SID_ID
AS
	v_groups_sid	security.security_pkg.T_SID_ID;
BEGIN

	v_groups_sid := security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups');
	RETURN security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, v_groups_sid, in_name);
END;

PROCEDURE CreateWorkflow
AS
	v_flow_state_id		csr.flow_state.flow_state_id%TYPE;
BEGIN
	csr.unit_test_pkg.GetOrCreateWorkflow(
		in_label						=> 'Audit workflow for audit report database tests',
		in_flow_alert_class				=> 'audit',
		out_sid							=> v_workflow_sid);

	csr.unit_test_pkg.GetOrCreateWorkflowState(
		in_flow_sid			=> v_workflow_sid,
		in_state_label		=> 'Default state',
		in_state_lookup_key	=> 'DEFAULT',
		out_flow_state_id	=> v_flow_state_id);
END;

FUNCTION CreateAuditTypeReport(
	in_internal_audit_type_id	csr.internal_audit_type.internal_audit_type_id%TYPE
) RETURN csr.internal_audit_type_report.internal_audit_type_report_id%TYPE
AS
	v_id	csr.internal_audit_type_report.internal_audit_type_report_id%TYPE;
BEGIN
	INSERT INTO internal_audit_type_report (
		internal_audit_type_id, internal_audit_type_report_id, report_filename, label, word_doc, use_merge_field_guid)
	VALUES (
		in_internal_audit_type_id, csr.internal_audit_type_report_seq.nextval, 'testfile', 'test report', EMPTY_BLOB, 0)
	RETURNING internal_audit_type_report_id INTO v_id;
	
	RETURN v_id;
END;

FUNCTION CreateIssueCustomField (
	in_issue_type_id			IN csr.issue_type.issue_type_id%TYPE,
	in_label					IN csr.issue_custom_field.label%TYPE,
	in_field_type				IN csr.issue_custom_field.field_type%TYPE DEFAULT 'T',
	in_pos						IN csr.issue_custom_field.pos%TYPE DEFAULT 0,
	in_is_mandatory				IN csr.issue_custom_field.is_mandatory%TYPE DEFAULT 0,
	in_restrict_to_group_sid	IN issue_custom_field.restrict_to_group_sid%TYPE DEFAULT NULL
) RETURN csr.issue_custom_field.issue_custom_field_id%TYPE
AS
	v_out_cur						SYS_REFCURSOR;
	v_custom_field_issue_type_id	csr.issue_type.issue_type_id%TYPE;
	v_custom_field_id				csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_field_type					csr.issue_custom_field.field_type%TYPE;
	v_label							csr.issue_custom_field.label%TYPE;
	v_pos							csr.issue_custom_field.pos%TYPE;
	v_sort_data						csr.issue_custom_field.label%TYPE;
	v_restrict_to_group_sid			csr.issue_custom_field.restrict_to_group_sid%TYPE;
BEGIN
	csr.issue_pkg.SaveCustomField(
		in_field_id					=> null,
		in_issue_type_id			=> in_issue_type_id,
		in_field_type				=> in_field_type,
		in_label					=> in_label,
		in_pos						=> in_pos,
		in_is_mandatory				=> in_is_mandatory,
		in_restrict_to_group_sid	=> in_restrict_to_group_sid,
		out_cur						=> v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_custom_field_id, v_custom_field_issue_type_id, v_field_type, v_label, v_pos, v_sort_data, v_restrict_group_sid;
		EXIT WHEN v_out_cur%NOTFOUND;
	END LOOP;

	RETURN v_custom_field_id;
END;

FUNCTION CreateIssueCustomFieldOption (
	in_field_id		IN	issue_custom_field_option.issue_custom_field_id%TYPE,
	in_label		IN	issue_custom_field_option.label%TYPE
) RETURN csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE
AS
	v_out_cur						SYS_REFCURSOR;
	v_issue_custom_field_opt_id		csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_issue_custom_field_id			csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_label							csr.issue_custom_field.label%TYPE;
BEGIN
	csr.issue_pkg.	SaveCustomFieldOption (
		in_option_id	=> null,
		in_field_id		=> in_field_id,
		in_label		=> in_label,
		out_cur			=> v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_issue_custom_field_opt_id, v_issue_custom_field_id, v_label;
		EXIT WHEN v_out_cur%NOTFOUND;
	END LOOP;

	RETURN v_issue_custom_field_opt_id;
END;

FUNCTION AddAudit(
	in_label				IN	csr.internal_audit.label%TYPE,
	in_audit_dtm			IN	csr.internal_audit.audit_dtm%TYPE,
	in_audit_type_id		IN	csr.internal_audit_type.internal_audit_type_id%TYPE,
	in_region_sid			IN	security.security_pkg.T_SID_ID
) RETURN security.security_pkg.T_SID_ID
AS
	v_audit_sid		security.security_pkg.T_SID_ID;
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
		in_auditor_company_sid		=> null,
		in_created_by_company_sid	=> null,
		in_permit_id				=> null,
		out_sid_id					=> v_audit_sid);

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

FUNCTION GetCustomFieldStringValue (
	in_actual_cursor	SYS_REFCURSOR,
	in_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE
) RETURN VARCHAR
AS
	v_issue_id				csr.issue.issue_id%TYPE;
	v_non_compliance_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_label	csr.issue_custom_field.label%TYPE;
	v_value					VARCHAR2(4000);
	v_field_type			csr.issue_custom_field.field_type%TYPE;
BEGIN
	LOOP
		FETCH in_actual_cursor INTO v_issue_id, v_non_compliance_id, v_issue_custom_field_id, v_custom_field_label, v_value, v_field_type;
		EXIT WHEN in_actual_cursor%NOTFOUND;
			IF v_issue_custom_field_id = in_custom_field_id THEN
				RETURN v_value;
				EXIT;
			END IF;
	END LOOP;
	
	RETURN null;
END;

FUNCTION GetCustomFieldOptionValue (
	in_actual_cursor	SYS_REFCURSOR,
	in_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE
) RETURN VARCHAR
AS
	v_issue_id				csr.issue.issue_id%TYPE;
	v_non_compliance_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_label	csr.issue_custom_field.label%TYPE;
	v_value					VARCHAR2(4000);
	v_field_type			csr.issue_custom_field.field_type%TYPE;
BEGIN
	LOOP
		FETCH in_actual_cursor INTO v_issue_id, v_non_compliance_id, v_issue_custom_field_id, v_custom_field_label, v_value, v_field_type;
		EXIT WHEN in_actual_cursor%NOTFOUND;
			IF v_issue_custom_field_id = in_custom_field_id THEN
				RETURN v_value;
				EXIT;
			END IF;
	END LOOP;
	
	RETURN null;
END;

FUNCTION GetCustomFieldDateValue (
	in_actual_cursor	SYS_REFCURSOR,
	in_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE
) RETURN DATE
AS
	v_issue_id				csr.issue.issue_id%TYPE;
	v_non_compliance_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_label	csr.issue_custom_field.label%TYPE;
	v_value					VARCHAR2(4000);
	v_field_type			csr.issue_custom_field.field_type%TYPE;
BEGIN
	LOOP
		FETCH in_actual_cursor INTO v_issue_id, v_non_compliance_id, v_issue_custom_field_id, v_custom_field_label, v_value, v_field_type;
		EXIT WHEN in_actual_cursor%NOTFOUND;
			IF v_issue_custom_field_id = in_custom_field_id THEN
				RETURN TO_DATE(v_value, 'DD/MM/YYYY HH24:MI:SS');
				EXIT;
			END IF;
	END LOOP;
	
	RETURN null;
END;

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	v_user_to_test_sid 		:= CreateUser(SYS_GUID, GetGroup('Audit administrators'));
	v_restrict_group_sid 	:= csr.unit_test_pkg.GetOrCreateGroup('GroupToRestrictCustomFields');
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

-- Called once before all tests
PROCEDURE SetUpFixture
AS
BEGIN
	CreateSite;

	security.user_pkg.LogonAdmin(v_site_name);

	v_region_sid := unit_test_pkg.GetOrCreateRegion('RegionToAudit');

	csr.unit_test_pkg.EnableAudits;
	csr.enable_pkg.EnableWorkflow;

	CreateWorkflow;

	SELECT csr_user_sid INTO v_administrator_sid FROM csr.csr_user WHERE user_name = 'builtinadministrator';
	SELECT internal_audit_type_id INTO v_default_audit_type_id FROM csr.internal_audit_type WHERE label = 'Default';
	SELECT issue_type_id INTO v_issue_type_id FROM csr.issue_type WHERE label = 'Corrective Action';

	v_audit_type_report_id := CreateAuditTypeReport(v_default_audit_type_id);
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
FUNCTION IsCustomFieldPresent (
	in_actual_cursor			SYS_REFCURSOR,
	in_expected_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE
) RETURN NUMBER
AS
	v_issue_id				csr.issue.issue_id%TYPE;
	v_non_compliance_id		csr.non_compliance.non_compliance_id%TYPE;
	v_issue_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_label	csr.issue_custom_field.label%TYPE;
	v_value					VARCHAR2(4000);
	v_field_type			csr.issue_custom_field.field_type%TYPE;

	v_custom_field_is_present	NUMBER := 0;
BEGIN
	LOOP
		FETCH in_actual_cursor INTO v_issue_id, v_non_compliance_id, v_issue_custom_field_id, v_custom_field_label, v_value, v_field_type;
		EXIT WHEN in_actual_cursor%NOTFOUND;
			IF v_issue_custom_field_id = in_expected_custom_field_id THEN
				v_custom_field_is_present := 1;
				EXIT;
			END IF;
	END LOOP;
	
	RETURN v_custom_field_is_present;
END;

PROCEDURE AssertCustomFieldNotPresent (
	in_actual_cursor			SYS_REFCURSOR,
	in_expected_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE
)
AS
	v_is_present				NUMBER;
BEGIN
	v_is_present := IsCustomFieldPresent(in_actual_cursor, in_expected_custom_field_id);
	csr.unit_test_pkg.AssertAreEqual(0, v_is_present, 'Expected the custom field to NOT be in the cursor but it was.');
END;

PROCEDURE AssertCustomFieldIsPresent (
	in_actual_cursor			SYS_REFCURSOR,
	in_expected_custom_field_id	csr.issue_custom_field.issue_custom_field_id%TYPE
)
AS
	v_is_present				NUMBER;
BEGIN
	v_is_present := IsCustomFieldPresent(in_actual_cursor, in_expected_custom_field_id);
	csr.unit_test_pkg.AssertAreEqual(1, v_is_present, 'Expected the custom field to be in the cursor but it was not');
END;

-----------------------------------------
-- TESTS
-----------------------------------------
-- Scenario: Values for string type issue custom fields are returned
PROCEDURE StringCustomFieldValuesAreReturned
AS
	v_custom_field_id		csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
	v_test_value			VARCHAR(4000);
	v_actual_value			VARCHAR(4000);

	out_ignore_cur			SYS_REFCURSOR;
	out_issues_fields_cur	SYS_REFCURSOR;
BEGIN
	-- Given a string type custom issue field
	v_custom_field_id := CreateIssueCustomField(
		in_issue_type_id			=> v_issue_type_id,
		in_field_type				=> 'T',
		in_label					=> SYS_GUID);

	-- And an audit that has a finding that has an issue that has a value in the custom field
	v_test_value := 'Working from home during the sars-cov-2 pandemic';
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);
	csr.issue_pkg.SetCustomFieldTextVal(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_str_val	=> v_test_value
	);

	-- When I get the data for the audit report for the audit
	csr.audit_pkg.GetDetailsForMailMergeAllFiles (
		in_sid_id					=> v_audit_sid,
		in_report_id 				=> v_audit_report_id,
		out_details_cur				=> out_ignore_cur,
		out_nc_cur					=> out_ignore_cur,
		out_nc_upload_cur			=> out_ignore_cur,
		out_nc_tag_cur				=> out_ignore_cur,
		out_issues_cur				=> out_ignore_cur,
		out_template_cur			=> out_ignore_cur,
		out_issues_fields_cur		=> out_issues_fields_cur,
		out_postit_files_cur		=> out_ignore_cur,
		out_audit_files_cur			=> out_ignore_cur,
		out_issue_logs_cur			=> out_ignore_cur,
		out_issue_log_files_cur		=> out_ignore_cur,
		out_issue_action_log_cur	=> out_ignore_cur
	);


	-- Then the value of the string type custom field is correct
	v_actual_value := GetCustomFieldStringValue(out_issues_fields_cur, v_custom_field_id);
	csr.unit_test_pkg.AssertAreEqual(v_test_value, v_actual_value, 'Incorrect custom field value');
END;

-- Scenario: Values for single select option type issue custom fields are returned
PROCEDURE SingleOptionCustomFieldValuesAreReturned
AS
	v_custom_field_id		csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
	v_option1_id			csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_option2_id			csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_option3_id			csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_actual_value			VARCHAR(4000);

	out_ignore_cur			SYS_REFCURSOR;
	out_issues_fields_cur	SYS_REFCURSOR;
BEGIN
	-- Given a single select option type custom issue field
	v_custom_field_id := CreateIssueCustomField(
		in_issue_type_id			=> v_issue_type_id,
		in_field_type				=> 'O',
		in_label					=> SYS_GUID);
		
	v_option1_id := CreateIssueCustomFieldOption(v_custom_field_id, 'Option1');
	v_option2_id := CreateIssueCustomFieldOption(v_custom_field_id, 'Option2');
	v_option3_id := CreateIssueCustomFieldOption(v_custom_field_id, 'Option3');

	-- And an audit that has a finding that has an issue that has a value in the custom field
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);
	csr.issue_pkg.SetCustomFieldOptionSel(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_opt_sel	=> v_option2_id
	);

	-- When I get the data for the audit report for the audit
	csr.audit_pkg.GetDetailsForMailMergeAllFiles (
		in_sid_id					=> v_audit_sid,
		in_report_id 				=> v_audit_report_id,
		out_details_cur				=> out_ignore_cur,
		out_nc_cur					=> out_ignore_cur,
		out_nc_upload_cur			=> out_ignore_cur,
		out_nc_tag_cur				=> out_ignore_cur,
		out_issues_cur				=> out_ignore_cur,
		out_template_cur			=> out_ignore_cur,
		out_issues_fields_cur		=> out_issues_fields_cur,
		out_postit_files_cur		=> out_ignore_cur,
		out_audit_files_cur			=> out_ignore_cur,
		out_issue_logs_cur			=> out_ignore_cur,
		out_issue_log_files_cur		=> out_ignore_cur,
		out_issue_action_log_cur	=> out_ignore_cur
	);

	-- Then the value of the single select option type custom field is correct
	v_actual_value := GetCustomFieldOptionValue(out_issues_fields_cur, v_custom_field_id);
	csr.unit_test_pkg.AssertAreEqual('Option2', v_actual_value, 'Incorrect custom field value');
END;

-- Scenario: Values for multi select option type issue custom fields are returned
PROCEDURE MultiOptionCustomFieldValuesAreReturned
AS
	v_custom_field_id		csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
	v_option1_id			csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_option2_id			csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_option3_id			csr.issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_actual_value			VARCHAR(4000);

	out_ignore_cur			SYS_REFCURSOR;
	out_issues_fields_cur	SYS_REFCURSOR;
BEGIN
	-- Given a date type custom issue field
	v_custom_field_id := CreateIssueCustomField(
		in_issue_type_id			=> v_issue_type_id,
		in_field_type				=> 'M',
		in_label					=> SYS_GUID);
		
	v_option1_id := CreateIssueCustomFieldOption(v_custom_field_id, 'Option1');
	v_option2_id := CreateIssueCustomFieldOption(v_custom_field_id, 'Option2');
	v_option3_id := CreateIssueCustomFieldOption(v_custom_field_id, 'Option3');

	-- And an audit that has a finding that has an issue that has a value in the custom field
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);
	csr.issue_pkg.AddCustomFieldOptionSel(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_opt_sel	=> v_option2_id
	);
	csr.issue_pkg.AddCustomFieldOptionSel(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_opt_sel	=> v_option3_id
	);

	-- When I get the data for the audit report for the audit
	csr.audit_pkg.GetDetailsForMailMergeAllFiles (
		in_sid_id					=> v_audit_sid,
		in_report_id 				=> v_audit_report_id,
		out_details_cur				=> out_ignore_cur,
		out_nc_cur					=> out_ignore_cur,
		out_nc_upload_cur			=> out_ignore_cur,
		out_nc_tag_cur				=> out_ignore_cur,
		out_issues_cur				=> out_ignore_cur,
		out_template_cur			=> out_ignore_cur,
		out_issues_fields_cur		=> out_issues_fields_cur,
		out_postit_files_cur		=> out_ignore_cur,
		out_audit_files_cur			=> out_ignore_cur,
		out_issue_logs_cur			=> out_ignore_cur,
		out_issue_log_files_cur		=> out_ignore_cur,
		out_issue_action_log_cur	=> out_ignore_cur
	);

	-- Then the value of the date type custom field is correct
	v_actual_value := GetCustomFieldOptionValue(out_issues_fields_cur, v_custom_field_id);
	csr.unit_test_pkg.AssertAreEqual('Option2,Option3', v_actual_value, 'Incorrect custom field value');
END;

-- Scenario: Values for date type issue custom fields are returned
PROCEDURE DateCustomFieldValuesAreReturned
AS
	v_custom_field_id		csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
	v_test_value			DATE;
	v_actual_value			DATE;

	out_ignore_cur			SYS_REFCURSOR;
	out_issues_fields_cur	SYS_REFCURSOR;
BEGIN
	-- Given a date type custom issue field
	v_custom_field_id := CreateIssueCustomField(
		in_issue_type_id			=> v_issue_type_id,
		in_field_type				=> 'D',
		in_label					=> SYS_GUID);

	-- And an audit that has a finding that has an issue that has a value in the custom field
	v_test_value := TRUNC(SYSDATE());
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);
	csr.issue_pkg.SetCustomFieldDateVal(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_date_val	=> v_test_value
	);

	-- When I get the data for the audit report for the audit
	csr.audit_pkg.GetDetailsForMailMergeAllFiles (
		in_sid_id					=> v_audit_sid,
		in_report_id 				=> v_audit_report_id,
		out_details_cur				=> out_ignore_cur,
		out_nc_cur					=> out_ignore_cur,
		out_nc_upload_cur			=> out_ignore_cur,
		out_nc_tag_cur				=> out_ignore_cur,
		out_issues_cur				=> out_ignore_cur,
		out_template_cur			=> out_ignore_cur,
		out_issues_fields_cur		=> out_issues_fields_cur,
		out_postit_files_cur		=> out_ignore_cur,
		out_audit_files_cur			=> out_ignore_cur,
		out_issue_logs_cur			=> out_ignore_cur,
		out_issue_log_files_cur		=> out_ignore_cur,
		out_issue_action_log_cur	=> out_ignore_cur
	);


	-- Then the value of the date type custom field is correct
	v_actual_value := GetCustomFieldDateValue(out_issues_fields_cur, v_custom_field_id);
	csr.unit_test_pkg.AssertAreEqual(v_test_value, v_actual_value, 'Incorrect custom field value');
END;

PROCEDURE SecuredCustomFieldsNotReturned
AS
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
	v_custom_field_id		csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_act_id				security.security_pkg.T_ACT_ID;

	out_ignore_cur			SYS_REFCURSOR;
	out_issues_fields_cur	SYS_REFCURSOR;
BEGIN
	-- Given a custom issue field that is restricted to a group
	v_custom_field_id := CreateIssueCustomField(
		in_issue_type_id			=> v_issue_type_id,
		in_label					=> SYS_GUID,
		in_restrict_to_group_sid	=> v_restrict_group_sid);

	-- And an audit that has a finding that has an issue that has a value in the restricted custom field
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);
	csr.issue_pkg.SetCustomFieldTextVal(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_str_val	=> 'The Bedlam in Goliath'
	);

	-- When I log in as a user that is not in the group
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- And I get the data for the audit report for the audit
	csr.audit_pkg.GetDetailsForMailMergeAllFiles (
		in_sid_id					=> v_audit_sid,
		in_report_id 				=> v_audit_report_id,
		out_details_cur				=> out_ignore_cur,
		out_nc_cur					=> out_ignore_cur,
		out_nc_upload_cur			=> out_ignore_cur,
		out_nc_tag_cur				=> out_ignore_cur,
		out_issues_cur				=> out_ignore_cur,
		out_template_cur			=> out_ignore_cur,
		out_issues_fields_cur		=> out_issues_fields_cur,
		out_postit_files_cur		=> out_ignore_cur,
		out_audit_files_cur			=> out_ignore_cur,
		out_issue_logs_cur			=> out_ignore_cur,
		out_issue_log_files_cur		=> out_ignore_cur,
		out_issue_action_log_cur	=> out_ignore_cur
	);

	-- Then the restricted custom field is not included
	AssertCustomFieldNotPresent(out_issues_fields_cur, v_custom_field_id);
END;

PROCEDURE SecuredCustomFieldsAreReturned
AS
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;
	v_custom_field_id		csr.issue_custom_field.issue_custom_field_id%TYPE;
	v_act_id				security.security_pkg.T_ACT_ID;

	out_ignore_cur			SYS_REFCURSOR;
	out_issues_fields_cur	SYS_REFCURSOR;
BEGIN
	-- Given a custom issue field that is restricted to a group
	v_custom_field_id := CreateIssueCustomField(
		in_issue_type_id			=> v_issue_type_id,
		in_label					=> SYS_GUID,
		in_restrict_to_group_sid	=> v_restrict_group_sid);

	-- And an audit that has a finding that has an issue that has a value in the restricted custom field
	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := AddFinding(v_audit_sid);
	v_issue_id := AddIssue(v_finding_id);

	csr.issue_pkg.SetCustomFieldTextVal(
		in_issue_id => v_issue_id,
		in_field_id	=> v_custom_field_id,
		in_str_val	=> 'The Bedlam in Goliath'
	);

	-- When I log in as a user that is in the group
	AddUserToGroup(v_user_to_test_sid, v_restrict_group_sid);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- And I get the data for the audit report for the audit
	csr.audit_pkg.GetDetailsForMailMergeAllFiles (
		in_sid_id					=> v_audit_sid,
		in_report_id 				=> v_audit_report_id,
		out_details_cur				=> out_ignore_cur,
		out_nc_cur					=> out_ignore_cur,
		out_nc_upload_cur			=> out_ignore_cur,
		out_nc_tag_cur				=> out_ignore_cur,
		out_issues_cur				=> out_ignore_cur,
		out_template_cur			=> out_ignore_cur,
		out_issues_fields_cur		=> out_issues_fields_cur,
		out_postit_files_cur		=> out_ignore_cur,
		out_audit_files_cur			=> out_ignore_cur,
		out_issue_logs_cur			=> out_ignore_cur,
		out_issue_log_files_cur		=> out_ignore_cur,
		out_issue_action_log_cur	=> out_ignore_cur
	);

	-- Then the restricted custom field is included
	AssertCustomFieldIsPresent(out_issues_fields_cur, v_custom_field_id);
END;

END;
/