CREATE OR REPLACE PACKAGE BODY csr.test_issue_custom_field_pkg AS

v_site_name							VARCHAR(50) := 'dbtest-issue-custom-field.credit360.com';
v_app_sid							security.security_pkg.T_SID_ID;
v_user_to_test_sid					security.security_pkg.T_SID_ID;
v_restrict_to_group_sid				security.security_pkg.T_SID_ID;
v_issue_type_id						issue_type.issue_type_id%TYPE;
v_custom_field_id					issue_custom_field.issue_custom_field_id%TYPE;
v_administrator_sid					security.security_pkg.T_SID_ID;
v_audit_type_id						internal_audit_type.internal_audit_type_id%TYPE;
v_region_sid						security.security_pkg.T_SID_ID;
v_audit_sid							internal_audit.internal_audit_sid%TYPE;

------------------------------------
-- Helpers
------------------------------------

PROCEDURE CreateSite
AS
BEGIN
	security.user_pkg.LogonAdmin();

	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), 0, '//Aspen/Applications/' || v_site_name);
		security.user_pkg.LogonAdmin(v_site_name);
		csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	-- Clear app sid from sys context
	security.user_pkg.LogonAdmin();
	csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);
END;

FUNCTION CreateUser(
	in_name							IN	csr_user.user_name%TYPE,
	in_group_sid					IN	security.security_pkg.T_SID_ID
) RETURN security.security_pkg.T_SID_ID
AS
	v_user_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_user_sid := unit_test_pkg.GetOrCreateUser(
		in_name			=> in_name,
		in_group_sid	=> in_group_sid
	);

	COMMIT;

	RETURN v_user_sid;
END;

PROCEDURE AddUserToGroup(
	in_user_sid						IN	security.security_pkg.T_SID_ID,
	in_group_sid					IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	csr_user_pkg.AddUserToGroupLogged(in_user_sid, in_group_sid, in_group_sid);
	COMMIT;
END;

PROCEDURE RemoveUserFromGroup(
	in_user_sid						IN	security.security_pkg.T_SID_ID,
	in_group_sid					IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	security.group_pkg.DeleteMember(SYS_CONTEXT('SECURITY', 'ACT'), in_group_sid, in_group_sid);
	COMMIT;
END;

FUNCTION CreateIssueCustomField(
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE,
	in_label						IN	issue_custom_field.label%TYPE,
	in_field_type					IN	issue_custom_field.field_type%TYPE DEFAULT 'O',
	in_pos							IN	issue_custom_field.pos%TYPE DEFAULT 0,
	in_is_mandatory					IN	issue_custom_field.is_mandatory%TYPE DEFAULT 0,
	in_restrict_to_group_sid		IN	issue_custom_field.restrict_to_group_sid%TYPE DEFAULT NULL
) RETURN issue_custom_field.issue_custom_field_id%TYPE
AS
	v_out_cur						SYS_REFCURSOR;
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_issue_type_id	issue_type.issue_type_id%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_label							issue_custom_field.label%TYPE;
	v_pos							issue_custom_field.pos%TYPE;
	v_ret_restrict_to_group_sid		issue_custom_field.restrict_to_group_sid%TYPE;
	v_sort_data						VARCHAR2(255);
BEGIN
	issue_pkg.SaveCustomField(
		in_field_id					=> NULL,
		in_issue_type_id			=> in_issue_type_id,
		in_field_type				=> in_field_type,
		in_label					=> in_label,
		in_pos						=> in_pos,
		in_is_mandatory				=> in_is_mandatory,
		in_restrict_to_group_sid	=> in_restrict_to_group_sid,
		out_cur						=> v_out_cur
	);

	LOOP
		FETCH v_out_cur
		 INTO v_issue_custom_field_id, v_custom_field_issue_type_id, v_field_type, v_label, v_pos, v_sort_data, v_ret_restrict_to_group_sid;
		EXIT WHEN v_out_cur%NOTFOUND;
	END LOOP;

	RETURN v_issue_custom_field_id;
END;

PROCEDURE AddIssueCustomOptionVal(
	in_issue_id						issue.issue_id%TYPE,
	in_issue_custom_field_id		issue_custom_field.issue_custom_field_id%TYPE
)
AS
	v_opt_cur						SYS_REFCURSOR;
	v_issue_custom_field_opt_id		issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_custom_field_id				issue_custom_field_option.issue_custom_field_id%TYPE;
	v_label							issue_custom_field_option.label%TYPE;
BEGIN
	issue_pkg.SaveCustomFieldOption(NULL, in_issue_custom_field_id, SYS_GUID, v_opt_cur);

	LOOP
		FETCH v_opt_cur
		 INTO v_issue_custom_field_opt_id, v_custom_field_id, v_label;
		EXIT WHEN v_opt_cur%NOTFOUND;
	END LOOP;

	issue_pkg.SetCustomFieldOptionSel(in_issue_id, in_issue_custom_field_id, v_issue_custom_field_opt_id);
END;

FUNCTION AddIssue
RETURN issue.issue_id%TYPE
AS
	v_finding_id					non_compliance.non_compliance_id%TYPE;
	v_issue_id						issue.issue_id%TYPE;
BEGIN
	audit_pkg.Save(
		in_sid_id					=> NULL,
		in_audit_ref				=> NULL,
		in_survey_sid				=> NULL,
		in_region_sid				=> v_region_sid,
		in_label					=> 'Audit 1',
		in_audit_dtm				=> SYSDATE,
		in_auditor_user_sid			=> security.security_pkg.GetSID(),
		in_notes					=> NULL,
		in_internal_audit_type		=> v_audit_type_id,
		in_auditor_name				=> NULL,
		in_auditor_org				=> NULL,
		in_response_to_audit		=> NULL,
		in_created_by_sid			=> NULL,
		in_auditee_user_sid			=> NULL,
		in_auditee_company_sid		=> NULL,
		in_auditor_company_sid		=> NULL,
		in_created_by_company_sid	=> NULL,
		in_permit_id				=> NULL,
		out_sid_id					=> v_audit_sid
	);
	v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(v_audit_sid, 'Finding 1');
	audit_pkg.AddNonComplianceIssue(v_finding_id, 'Issue 1', NULL, NULL, v_user_to_test_sid, NULL, 0, 0, v_issue_id);
	RETURN v_issue_id;
END;

------------------------------------
-- SETUP and TEARDOWN
------------------------------------

-- Called before each test
PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	v_user_to_test_sid := CreateUser(SYS_GUID, unit_test_pkg.GetOrCreateGroup('Audit Administrators'));
	v_restrict_to_group_sid := unit_test_pkg.GetOrCreateGroup('GroupToRestrictCustomFields');
END;

-- Called after each passed test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
END;

-- Called once before all tests
PROCEDURE SetUpFixture
AS
BEGIN
	CreateSite;
	security.user_pkg.LogonAdmin(v_site_name);

	unit_test_pkg.EnableAudits;

	SELECT csr_user_sid
	  INTO v_administrator_sid
	  FROM csr_user
	 WHERE user_name = 'builtinadministrator';

	SELECT internal_audit_type_id
	  INTO v_audit_type_id
	  FROM internal_audit_type
	 WHERE label = 'Default';

	SELECT issue_type_id
	  INTO v_issue_type_id
	  FROM issue_type
	 WHERE label = 'Corrective Action';

	v_region_sid := unit_test_pkg.GetOrCreateRegion('AuditRegion');
END;

-- Called once after all tests have passed
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;

------------------------------------
-- Asserts
------------------------------------
FUNCTION GetIssueDetails_IsCustomFieldPresentInFieldsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_id						issue.issue_id%TYPE;
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_label							issue_custom_field.label%TYPE;
	v_custom_field_issue_type_id	issue_custom_field.issue_type_id%TYPE;
	v_is_mandatory					issue_custom_field.is_mandatory%TYPE;
	v_field_reference_name			issue_custom_field.field_reference_name%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_issue_id, v_issue_custom_field_id, v_field_type, v_label, v_custom_field_issue_type_id, v_is_mandatory, v_field_reference_name;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id AND v_custom_field_issue_type_id = v_issue_type_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

FUNCTION GetIssueDetails_IsCustomFieldPresentInFieldOptsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_issue_custom_field_opt_id		issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_label							issue_custom_field_option.label%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor INTO v_issue_custom_field_id, v_issue_custom_field_opt_id, v_label;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

FUNCTION GetIssueDetails_IsCustomFieldPresentInFieldValsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_id						issue.issue_id%TYPE;
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_string_value					issue_custom_field_str_val.string_value%TYPE;
	v_issue_custom_field_opt_id		issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_date_value					issue_custom_field_date_val.date_value%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_issue_id, v_issue_custom_field_id, v_string_value, v_issue_custom_field_opt_id, v_date_value;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

PROCEDURE GetIssueDetails_AssertCustomField(
	in_is_expected					NUMBER,
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR,
	in_custom_field_vals_cur		SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetIssueDetails_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in out_custom_fields_cur');

	v_is_present := GetIssueDetails_IsCustomFieldPresentInFieldOptsCursor(in_custom_field_id, in_custom_field_opts_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in in_custom_field_opts_cur');

	v_is_present := GetIssueDetails_IsCustomFieldPresentInFieldValsCursor(in_custom_field_id, in_custom_field_vals_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in in_custom_field_vals_cur');
END;

PROCEDURE GetIssueDetails_AssertCustomFieldPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR,
	in_custom_field_vals_cur		SYS_REFCURSOR
)
AS
BEGIN
	GetIssueDetails_AssertCustomField(1, in_custom_field_id, in_custom_fields_cur, in_custom_field_opts_cur, in_custom_field_vals_cur);
END;

PROCEDURE GetIssueDetails_AssertCustomFieldNotPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR,
	in_custom_field_vals_cur		SYS_REFCURSOR
)
AS
BEGIN
	GetIssueDetails_AssertCustomField(0, in_custom_field_id, in_custom_fields_cur, in_custom_field_opts_cur, in_custom_field_vals_cur);
END;

FUNCTION GetIssueType_IsCustomFieldPresentInFieldsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_label							issue_custom_field.label%TYPE;
	v_is_mandatory					issue_custom_field.is_mandatory%TYPE;
	v_field_reference_name			issue_custom_field.field_reference_name%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_issue_custom_field_id, v_field_type, v_label, v_is_mandatory, v_field_reference_name;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

FUNCTION GetIssueType_IsCustomFieldPresentInFieldOptsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_issue_custom_field_opt_id		issue_custom_field_option.issue_custom_field_opt_id%TYPE;
	v_label							issue_custom_field_option.label%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor INTO v_issue_custom_field_id, v_issue_custom_field_opt_id, v_label;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

PROCEDURE GetIssueType_AssertCustomField(
	in_is_expected					NUMBER,
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetIssueType_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in out_custom_fields_cur');
	v_is_present := GetIssueType_IsCustomFieldPresentInFieldOptsCursor(in_custom_field_id, in_custom_field_opts_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in in_custom_field_opts_cur');
END;

PROCEDURE GetIssueType_AssertCustomFieldPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR
)
AS
BEGIN
	GetIssueType_AssertCustomField(1, in_custom_field_id, in_custom_fields_cur, in_custom_field_opts_cur);
END;

PROCEDURE GetIssueType_AssertCustomFieldNotPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR
)
AS
BEGIN
	GetIssueType_AssertCustomField(0, in_custom_field_id, in_custom_fields_cur, in_custom_field_opts_cur);
END;

FUNCTION GetCustomFieldsForIssues_IsCustomFieldPresentInFieldsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_issue_type_id	issue_custom_field.issue_type_id%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_label							issue_custom_field.label%TYPE;
	v_pos							issue_custom_field.pos%TYPE;
	v_is_mandatory					issue_custom_field.is_mandatory%TYPE;
	v_ret_restrict_to_group_sid		issue_custom_field.restrict_to_group_sid%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_issue_custom_field_id, v_custom_field_issue_type_id, v_field_type, v_label, v_pos, v_is_mandatory, v_ret_restrict_to_group_sid;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id AND v_custom_field_issue_type_id = v_issue_type_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

PROCEDURE GetCustomFieldsForIssues_AssertCustomField(
	in_is_expected					NUMBER,
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetCustomFieldsForIssues_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in out_custom_fields_cur');
	v_is_present := GetIssueType_IsCustomFieldPresentInFieldOptsCursor(in_custom_field_id, in_custom_field_opts_cur);
	unit_test_pkg.AssertAreEqual(in_is_expected, v_is_present, 'Expected the custom field to'||CASE WHEN in_is_expected = 0 THEN ' not' END||' be in in_custom_field_opts_cur');
END;

PROCEDURE GetCustomFieldsForIssues_AssertCustomFieldPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR
)
AS
BEGIN
	GetCustomFieldsForIssues_AssertCustomField(1, in_custom_field_id, in_custom_fields_cur, in_custom_field_opts_cur);
END;

PROCEDURE GetCustomFieldsForIssues_AssertCustomFieldNotPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR,
	in_custom_field_opts_cur		SYS_REFCURSOR
)
AS
BEGIN
	GetCustomFieldsForIssues_AssertCustomField(0, in_custom_field_id, in_custom_fields_cur, in_custom_field_opts_cur);
END;

FUNCTION GetList_IsCustomFieldPresentInCustValsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_id						issue.issue_id%TYPE;
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_label							issue_custom_field.label%TYPE;
	v_string_value					issue_custom_field_str_val.string_value%TYPE;
	v_date_value					issue_custom_field_date_val.date_value%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_issue_id, v_issue_custom_field_id, v_field_type, v_label, v_string_value, v_date_value;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id AND v_string_value IS NOT NULL THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

PROCEDURE GetList_AssertCustomFieldPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cust_vals_cur				SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetList_IsCustomFieldPresentInCustValsCursor(in_custom_field_id, in_cust_vals_cur);
	unit_test_pkg.AssertAreEqual(1, v_is_present, 'Expected the custom field to be in out_cust_vals');
END;

PROCEDURE GetList_AssertCustomFieldNotPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cust_vals_cur				SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetList_IsCustomFieldPresentInCustValsCursor(in_custom_field_id, in_cust_vals_cur);
	unit_test_pkg.AssertAreEqual(0, v_is_present, 'Expected the custom field to not be in out_cust_vals');
END;

FUNCTION GetCustomFields_IsCustomFieldPresentInFieldsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_issue_type_id	issue_custom_field.issue_type_id%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_label							issue_custom_field.label%TYPE;
	v_pos							issue_custom_field.pos%TYPE;
	v_sort_data						VARCHAR2(255);
	v_is_mandatory					issue_custom_field.is_mandatory%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_issue_custom_field_id, v_custom_field_issue_type_id, v_field_type, v_label, v_pos, v_sort_data, v_is_mandatory;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id AND v_custom_field_issue_type_id = v_issue_type_id THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

PROCEDURE GetCustomFields_AssertCustomFieldPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetCustomFields_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(1, v_is_present, 'Expected the custom field to be in out_custom_fields_cur');
END;

PROCEDURE GetCustomFields_AssertCustomFieldNotPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := GetCustomFields_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(0, v_is_present, 'Expected the custom field to not be in out_custom_fields_cur');
END;


FUNCTION ExportFindingsAndActions_IsCustomFieldPresentInFieldsCursor(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_cursor						SYS_REFCURSOR
)
RETURN NUMBER
AS
	v_action_id						issue.issue_id%TYPE;
	v_issue_custom_field_id			issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_label			issue_custom_field.label%TYPE;
	v_value							issue_custom_field_str_val.string_value%TYPE;
	v_date_value					issue_custom_field_date_val.date_value%TYPE;
	v_field_type					issue_custom_field.field_type%TYPE;
	v_is_present					NUMBER := 0;
BEGIN
	LOOP
		FETCH in_cursor
		 INTO v_action_id, v_issue_custom_field_id, v_custom_field_label, v_value, v_date_value, v_field_type;
		 EXIT WHEN in_cursor%NOTFOUND;

		IF v_issue_custom_field_id = in_custom_field_id AND v_value IS NOT NULL THEN
			v_is_present := 1;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_is_present;
END;

PROCEDURE ExportFindingsAndActions_AssertCustomFieldPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := ExportFindingsAndActions_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(1, v_is_present, 'Expected the custom field to be in out_issue_fields_cur');
END;

PROCEDURE ExportFindingsAndActions_AssertCustomFieldNotPresent(
	in_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE,
	in_custom_fields_cur			SYS_REFCURSOR
)
AS
	v_is_present					NUMBER;
BEGIN
	v_is_present := ExportFindingsAndActions_IsCustomFieldPresentInFieldsCursor(in_custom_field_id, in_custom_fields_cur);
	unit_test_pkg.AssertAreEqual(0, v_is_present, 'Expected the custom field to not be in out_issue_fields_cur');
END;

------------------------------------
-- Tests
------------------------------------
PROCEDURE GetIssueDetails_UserHasAccessToCustomFieldsWithSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_ignore_cur					SYS_REFCURSOR;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
	out_custom_field_vals_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	AddUserToGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetIssueDetails(
		v_act_id,
		v_issue_id,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_custom_fields_cur,
		out_custom_field_opts_cur,
		out_custom_field_vals_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur
	);

	-- Assert
	GetIssueDetails_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur, out_custom_field_vals_cur);
END;

PROCEDURE GetIssueDetails_UserHasNoAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_ignore_cur					SYS_REFCURSOR;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
	out_custom_field_vals_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	RemoveUserFromGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetIssueDetails(
		v_act_id,
		v_issue_id,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_custom_fields_cur,
		out_custom_field_opts_cur,
		out_custom_field_vals_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur
	);

	-- Assert
	GetIssueDetails_AssertCustomFieldNotPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur, out_custom_field_vals_cur);
END;

PROCEDURE GetIssueDetails_UserWithIssueManagementCapabilityHasAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_ignore_cur					SYS_REFCURSOR;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
	out_custom_field_vals_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_administrator_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetIssueDetails(
		v_act_id,
		v_issue_id,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_custom_fields_cur,
		out_custom_field_opts_cur,
		out_custom_field_vals_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur,
		out_ignore_cur
	);

	-- Assert
	GetIssueDetails_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur, out_custom_field_vals_cur);
END;

PROCEDURE GetIssueType_UserHasAccessToCustomFieldsWithSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_ignore_cur					SYS_REFCURSOR;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	AddUserToGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetIssueType(
		v_issue_type_id,
		out_ignore_cur,
		out_custom_fields_cur,
		out_custom_field_opts_cur
	);

	-- Assert
	GetIssueType_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur);
END;

PROCEDURE GetIssueType_UserHasNoAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_ignore_cur					SYS_REFCURSOR;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	RemoveUserFromGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetIssueType(
		v_issue_type_id,
		out_ignore_cur,
		out_custom_fields_cur,
		out_custom_field_opts_cur
	);

	-- Assert
	GetIssueType_AssertCustomFieldNotPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur);
END;

PROCEDURE GetIssueType_UserWithIssueManagementCapabilityHasAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_ignore_cur					SYS_REFCURSOR;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_administrator_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetIssueType(
		v_issue_type_id,
		out_ignore_cur,
		out_custom_fields_cur,
		out_custom_field_opts_cur
	);

	-- Assert
	GetIssueType_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur);
END;

PROCEDURE GetCustomFieldsForIssues_UserHasAccessToCustomFieldsWithSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	AddUserToGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetCustomFieldsForIssues(
		v_issue_type_id,
		out_custom_fields_cur,
		out_custom_field_opts_cur
	);

	-- Assert
	GetCustomFieldsForIssues_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur);
END;

PROCEDURE GetCustomFieldsForIssues_UserHasNoAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	RemoveUserFromGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetCustomFieldsForIssues(
		v_issue_type_id,
		out_custom_fields_cur,
		out_custom_field_opts_cur
	);

	-- Assert
	GetCustomFieldsForIssues_AssertCustomFieldNotPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur);
END;

PROCEDURE GetCustomFieldsForIssues_UserWithIssueManagementCapabilityHasAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_custom_fields_cur			SYS_REFCURSOR;
	out_custom_field_opts_cur		SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_administrator_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetCustomFieldsForIssues(
		v_issue_type_id,
		out_custom_fields_cur,
		out_custom_field_opts_cur
	);

	-- Assert
	GetCustomFieldsForIssues_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur, out_custom_field_opts_cur);
END;

PROCEDURE GetList_UserHasAccessToCustomFieldsWithSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_empty_array					security.security_pkg.T_SID_IDS;
	v_total_rows					NUMBER;
	out_ignore_cur					SYS_REFCURSOR;
	out_cust_vals_cur				SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	AddUserToGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_report_pkg.GetList(
		in_search => '',
		in_group_key => NULL,
		in_pre_filter_sid => NULL,
		in_parent_type => NULL,
		in_parent_id => NULL,
		in_compound_filter_id => 0,
		in_start_row => 0,
		in_end_row => 20,
		in_order_by => 'issueId',
		in_order_dir => 'DESC',
		in_bounds_north => NULL,
		in_bounds_east => NULL,
		in_bounds_south => NULL,
		in_bounds_west => NULL,
		in_breadcrumb => v_empty_array,
		in_aggregation_type => NULL,
		in_region_sids => v_empty_array,
		in_start_dtm => NULL,
		in_end_dtm => NULL,
		in_region_col_type => NULL,
		in_date_col_type => NULL,
		in_id_list_populated => 0,
		in_session_prefix => 'csr_site_issues_issuelist_',
		out_total_rows => v_total_rows,
		out_cur => out_ignore_cur,
		out_cust_vals => out_cust_vals_cur
	);

	-- Assert
	GetList_AssertCustomFieldPresent(v_custom_field_id, out_cust_vals_cur);
END;

PROCEDURE GetList_UserHasNoAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_empty_array					security.security_pkg.T_SID_IDS;
	v_total_rows					NUMBER;
	out_ignore_cur					SYS_REFCURSOR;
	out_cust_vals_cur				SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	RemoveUserFromGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_report_pkg.GetList(
		in_search => '',
		in_group_key => NULL,
		in_pre_filter_sid => NULL,
		in_parent_type => NULL,
		in_parent_id => NULL,
		in_compound_filter_id => 0,
		in_start_row => 0,
		in_end_row => 20,
		in_order_by => 'issueId',
		in_order_dir => 'DESC',
		in_bounds_north => NULL,
		in_bounds_east => NULL,
		in_bounds_south => NULL,
		in_bounds_west => NULL,
		in_breadcrumb => v_empty_array,
		in_aggregation_type => NULL,
		in_region_sids => v_empty_array,
		in_start_dtm => NULL,
		in_end_dtm => NULL,
		in_region_col_type => NULL,
		in_date_col_type => NULL,
		in_id_list_populated => 0,
		in_session_prefix => 'csr_site_issues_issuelist_',
		out_total_rows => v_total_rows,
		out_cur => out_ignore_cur,
		out_cust_vals => out_cust_vals_cur
	);

	-- Assert
	GetList_AssertCustomFieldNotPresent(v_custom_field_id, out_cust_vals_cur);
END;

PROCEDURE GetList_UserWithIssueManagementCapabilityHasAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_empty_array					security.security_pkg.T_SID_IDS;
	v_total_rows					NUMBER;
	out_ignore_cur					SYS_REFCURSOR;
	out_cust_vals_cur				SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_administrator_sid, 60000, v_act_id);

	-- Act
	issue_report_pkg.GetList(
		in_search => '',
		in_group_key => NULL,
		in_pre_filter_sid => NULL,
		in_parent_type => NULL,
		in_parent_id => NULL,
		in_compound_filter_id => 0,
		in_start_row => 0,
		in_end_row => 20,
		in_order_by => 'issueId',
		in_order_dir => 'DESC',
		in_bounds_north => NULL,
		in_bounds_east => NULL,
		in_bounds_south => NULL,
		in_bounds_west => NULL,
		in_breadcrumb => v_empty_array,
		in_aggregation_type => NULL,
		in_region_sids => v_empty_array,
		in_start_dtm => NULL,
		in_end_dtm => NULL,
		in_region_col_type => NULL,
		in_date_col_type => NULL,
		in_id_list_populated => 0,
		in_session_prefix => 'csr_site_issues_issuelist_',
		out_total_rows => v_total_rows,
		out_cur => out_ignore_cur,
		out_cust_vals => out_cust_vals_cur
	);

	-- Assert
	GetList_AssertCustomFieldPresent(v_custom_field_id, out_cust_vals_cur);
END;

PROCEDURE GetCustomFields_UserHasAccessToCustomFieldsWithSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_custom_fields_cur			SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	AddUserToGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetCustomFields(
		v_issue_type_id,
		0,
		out_custom_fields_cur
	);

	-- Assert
	GetCustomFields_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur);
END;

PROCEDURE GetCustomFields_UserHasNoAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_custom_fields_cur			SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	RemoveUserFromGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetCustomFields(
		v_issue_type_id,
		0,
		out_custom_fields_cur
	);

	-- Assert
	GetCustomFields_AssertCustomFieldNotPresent(v_custom_field_id, out_custom_fields_cur);
END;

PROCEDURE GetCustomFields_UserWithIssueManagementCapabilityHasAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_custom_fields_cur			SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_administrator_sid, 60000, v_act_id);

	-- Act
	issue_pkg.GetCustomFields(
		v_issue_type_id,
		0,
		out_custom_fields_cur
	);

	-- Assert
	GetCustomFields_AssertCustomFieldPresent(v_custom_field_id, out_custom_fields_cur);
END;


PROCEDURE ExportFindingsAndActions_UserHasAccessToCustomFieldsWithSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_issue_fields_cur			SYS_REFCURSOR;
	out_ignore_cur					SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	AddUserToGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	audit_pkg.ExportFindingsAndActions(
		v_audit_sid,
		out_ignore_cur,
		out_ignore_cur,
		out_issue_fields_cur
	);

	-- Assert
	ExportFindingsAndActions_AssertCustomFieldPresent(v_custom_field_id, out_issue_fields_cur);
END;

PROCEDURE ExportFindingsAndActions_UserHasNoAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_issue_fields_cur			SYS_REFCURSOR;
	out_ignore_cur					SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	RemoveUserFromGroup(v_user_to_test_sid, v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_user_to_test_sid, 60000, v_act_id);

	-- Act
	audit_pkg.ExportFindingsAndActions(
		v_audit_sid,
		out_ignore_cur,
		out_ignore_cur,
		out_issue_fields_cur
	);

	-- Assert
	ExportFindingsAndActions_AssertCustomFieldNotPresent(v_custom_field_id, out_issue_fields_cur);
END;

PROCEDURE ExportFindingsAndActions_UserWithIssueManagementCapabilityHasAccessToCustomFieldsWithNoSharedGroup
AS
	v_issue_id						issue.issue_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID;
	out_issue_fields_cur			SYS_REFCURSOR;
	out_ignore_cur					SYS_REFCURSOR;
BEGIN
	-- Arrange
	v_custom_field_id := CreateIssueCustomField(in_issue_type_id => v_issue_type_id, in_label => SYS_GUID, in_restrict_to_group_sid => v_restrict_to_group_sid);
	v_issue_id := AddIssue();
	AddIssueCustomOptionVal(v_issue_id, v_custom_field_id);
	security.user_pkg.LogonAuthenticated(v_administrator_sid, 60000, v_act_id);

	-- Act
	audit_pkg.ExportFindingsAndActions(
		v_audit_sid,
		out_ignore_cur,
		out_ignore_cur,
		out_issue_fields_cur
	);

	-- Assert
	ExportFindingsAndActions_AssertCustomFieldPresent(v_custom_field_id, out_issue_fields_cur);
END;

END;
/
