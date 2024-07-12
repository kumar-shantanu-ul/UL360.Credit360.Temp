CREATE OR REPLACE PACKAGE BODY csr.test_tag_pkg AS

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-tags.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_administrator_sid			security.security_pkg.T_SID_ID;

v_region_sid				security.security_pkg.T_SID_ID;

v_default_audit_type_id		csr.internal_audit_type.internal_audit_type_id%TYPE;

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

FUNCTION AddIssue(
	in_finding_id	csr.non_compliance.non_compliance_id%TYPE
) RETURN csr.issue.issue_id%TYPE
AS
	v_issue_id	csr.issue.issue_id%TYPE;
BEGIN
	csr.audit_pkg.AddNonComplianceIssue(in_finding_id, 'Issue 1', null, null, v_administrator_sid, null, 0, 0, v_issue_id);
	RETURN v_issue_id;
END;

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
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

	SELECT csr_user_sid INTO v_administrator_sid FROM csr.csr_user WHERE user_name = 'builtinadministrator';
	SELECT internal_audit_type_id INTO v_default_audit_type_id FROM csr.internal_audit_type WHERE label = 'Default';
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

PROCEDURE AssertTagGroupAppliesToChain(
	in_tag_group_id			IN csr.tag_group.tag_group_id%TYPE
)
AS
	v_applies_to_non_comp	csr.tag_group.applies_to_non_compliances%TYPE;
	v_applies_to_chain		csr.tag_group.applies_to_chain%TYPE;
BEGIN
	SELECT applies_to_non_compliances, applies_to_chain
	  INTO v_applies_to_non_comp, v_applies_to_chain
	  FROM csr.tag_group
	 WHERE tag_group_id = in_tag_group_id;
	 
	csr.unit_test_pkg.AssertAreEqual(v_applies_to_non_comp, 0, 'Tag group still applies to non-compliances');
	csr.unit_test_pkg.AssertAreEqual(v_applies_to_chain, 1, 'Tag group does not apply to Chain');
END;

-----------------------------------------
-- TESTS
-----------------------------------------
-- Scenario: Trying to change a Tag Group applies to after the Tag Group has been used should throw an exception
PROCEDURE TagAppliesToCantBeChanged
AS
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;

	v_tag_group_name		VARCHAR(50) := 'This is a TagGroup for testing1';
	v_tag_group_lookup_key	VARCHAR(50) := 'GROUP_LOOKUP_KEY';

	v_tag_ids				security.security_pkg.T_SID_IDS;
	
	out_tag_group_id		csr.tag_group.tag_group_id%TYPE;
	out_tag_id				csr.tag.tag_id%TYPE;
BEGIN
	csr.tag_pkg.CreateTagGroup(
		in_name							=> v_tag_group_name,
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> v_tag_group_lookup_key,
		out_tag_group_id				=> out_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> out_tag_group_id,
		in_tag					=> 'Poop',
		in_pos					=> 1,
		in_lookup_key			=> 'TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> out_tag_id
	);

	SELECT out_tag_id
	  BULK COLLECT INTO v_tag_ids
	  FROM dual;

	v_audit_sid := AddAudit('Audit1', SYSDATE, v_default_audit_type_id, v_region_sid);
	v_finding_id := csr.unit_test_pkg.GetOrCreateNonComplianceId(v_audit_sid, 'Finding 1', NULL, v_tag_ids);
	v_issue_id := AddIssue(v_finding_id);

	BEGIN
		csr.tag_pkg.SetTagGroup(
			in_tag_group_id					=> out_tag_group_id,
			in_name							=> v_tag_group_name,
			in_applies_to_chain				=> 1,
			out_tag_group_id				=> out_tag_group_id
		);
		
		csr.unit_test_pkg.TestFail('Should RAISE_APPLICATION_ERROR');
	EXCEPTION
		WHEN csr.csr_data_pkg.INVALID_TAG_APPLIES_CHANGE THEN
			NULL;
	END;
END;

-- Scenario: Trying to change a Tag Group applies to before the Tag Group has been used should update the Tag Group
PROCEDURE TagAppliesToCanBeChanged
AS
	v_audit_sid				security.security_pkg.T_SID_ID;
	v_finding_id			csr.non_compliance.non_compliance_id%TYPE;
	v_issue_id				csr.issue.issue_id%TYPE;

	v_tag_group_name		VARCHAR(50) := 'This is a TagGroup for testing2';
	v_tag_group_lookup_key	VARCHAR(50) := 'GROUP_LOOKUP_KEY_2';	

	v_tag_ids				security.security_pkg.T_SID_IDS;
	
	out_tag_group_id		tag_group.tag_group_id%TYPE;
	out_tag_group_id2		tag_group.tag_group_id%TYPE;
	out_tag_id				tag.tag_id%TYPE;
BEGIN
	csr.tag_pkg.CreateTagGroup(
		in_name							=> v_tag_group_name,
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> v_tag_group_lookup_key,
		out_tag_group_id				=> out_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> out_tag_group_id,
		in_tag					=> 'Poop',
		in_pos					=> 1,
		in_lookup_key			=> 'TAG_LOOKUP_KEY',
		in_active				=> 1,
		out_tag_id				=> out_tag_id
	);

	csr.tag_pkg.SetTagGroup(
		in_tag_group_id					=> out_tag_group_id,
		in_name							=> v_tag_group_name,
		in_applies_to_chain				=> 1,
		out_tag_group_id				=> out_tag_group_id2
	);
	
	csr.unit_test_pkg.AssertAreEqual(out_tag_group_id, out_tag_group_id2, 'Unexpected new Tag Group Id');
	AssertTagGroupAppliesToChain(out_tag_group_id2);
END;

-- Scenario: CRUD test
PROCEDURE TagCRUD
AS
	v_tag_group_name1		VARCHAR(50) := 'This is a TagGroup for testing CRUD 1';
	v_tag_group_name2		VARCHAR(50) := 'This is a TagGroup for testing CRUD 2';
	v_tag_group_lookup_key1	VARCHAR(50) := 'GROUP_LOOKUP_KEY_CRUD1';
	v_tag_group_lookup_key2	VARCHAR(50) := 'GROUP_LOOKUP_KEY_CRUD2';

	v_count					NUMBER;
	v_name					VARCHAR(50);
	
	out_tag_group_id1		tag_group.tag_group_id%TYPE;
	out_tag_group_id2		tag_group.tag_group_id%TYPE;
	out_tag_group_id3		tag_group.tag_group_id%TYPE;
BEGIN
	-- Explicit create
	csr.tag_pkg.CreateTagGroup(
		in_name							=> v_tag_group_name1,
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> v_tag_group_lookup_key1,
		out_tag_group_id				=> out_tag_group_id1
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Expected 1 Tag group, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Expected 1 Tag group view, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group_description
	 WHERE tag_group_id = out_tag_group_id1;
	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Expected 1 Tag group description, found '||v_count);
	SELECT name
	  INTO v_name
	  FROM csr.tag_group_description
	 WHERE tag_group_id IN (out_tag_group_id1);
	csr.unit_test_pkg.AssertAreEqual(v_tag_group_name1, v_name, 'Expected matching Tag group description');


	-- Set, expecting create
	csr.tag_pkg.SetTagGroup(
		in_name							=> v_tag_group_name2,
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> v_tag_group_lookup_key2,
		out_tag_group_id				=> out_tag_group_id2
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 2, 'Expected 2 Tag group, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 2, 'Expected 2 Tag group view, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group_description
	 WHERE tag_group_id IN (out_tag_group_id1, out_tag_group_id2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 2, 'Expected 2 Tag group description, found '||v_count);
	SELECT name
	  INTO v_name
	  FROM csr.tag_group_description
	 WHERE tag_group_id IN (out_tag_group_id2);
	csr.unit_test_pkg.AssertAreEqual(v_tag_group_name2, v_name, 'Expected matching Tag group description');


	-- Set, expecting update
	csr.tag_pkg.SetTagGroup(
		in_tag_group_id					=> out_tag_group_id2,
		in_name							=> v_tag_group_name2 || ' Updated',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> v_tag_group_lookup_key2,
		out_tag_group_id				=> out_tag_group_id3
	);
	csr.unit_test_pkg.AssertAreEqual(out_tag_group_id2, out_tag_group_id3, 'Expected out to eq in');
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 2, 'Expected 2 Tag group, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 2, 'Expected 2 Tag group view, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group_description
	 WHERE tag_group_id IN (out_tag_group_id1, out_tag_group_id2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 2, 'Expected 2 Tag group description, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group_description
	 WHERE name = v_tag_group_name2;
	csr.unit_test_pkg.AssertAreEqual(v_count, 0, 'Expected 0 Non-updated Tag group description, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group_description
	 WHERE name = v_tag_group_name2 || ' Updated';
	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Expected 1 Updated Tag group description, found '||v_count);
	SELECT name
	  INTO v_name
	  FROM csr.tag_group_description
	 WHERE tag_group_id IN (out_tag_group_id2);
	csr.unit_test_pkg.AssertAreEqual(v_tag_group_name2 || ' Updated', v_name, 'Expected matching Tag group description');

	
	csr.tag_pkg.DeleteTagGroup(
		in_act_id						=> security.security_pkg.getAct,
		in_tag_group_id					=> out_tag_group_id1
	);
	csr.tag_pkg.DeleteTagGroup(
		in_act_id						=> security.security_pkg.getAct,
		in_tag_group_id					=> out_tag_group_id2
	);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 0, 'Expected 0 Tag group, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$tag_group
	 WHERE lookup_key IN (v_tag_group_lookup_key1, v_tag_group_lookup_key2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 0, 'Expected 0 Tag group view, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.tag_group_description
	 WHERE tag_group_id IN (out_tag_group_id1, out_tag_group_id2);
	csr.unit_test_pkg.AssertAreEqual(v_count, 0, 'Expected 0 Tag group description, found '||v_count);
END;

END;
/
