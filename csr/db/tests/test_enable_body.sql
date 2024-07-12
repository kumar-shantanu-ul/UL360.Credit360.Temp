CREATE OR REPLACE PACKAGE BODY csr.test_enable_pkg AS

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-enable.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_administrator_sid			security.security_pkg.T_SID_ID;
v_workflow_sid				security.security_pkg.T_SID_ID;
v_test_group_sid			security.security_pkg.T_SID_ID;
v_unauthed_user_sid			security.security_pkg.T_SID_ID;

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
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_unauthed_user_sid := unit_test_pkg.GetOrCreateUser('unauthed.user');

	COMMIT; -- need to commit before logging as this user
END;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE DeleteDataCreatedDuringTests
AS
BEGIN
	-- delete data that could have been created during tests, in case of previously aborted/failed runs.
	NULL;
END;


PROCEDURE SetUpFixture 
AS
	v_menu						security.security_pkg.T_SID_ID;
	v_admin_menu				security.security_pkg.T_SID_ID;
	v_user_sid					security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUpFixture');
	CreateSite;
	security.user_pkg.LogonAdmin(v_site_name);
	SELECT csr_user_sid INTO v_administrator_sid FROM csr.csr_user WHERE user_name = 'builtinadministrator';
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	v_user_sid := unit_test_pkg.GetOrCreateUser('admin');

	unit_test_pkg.EnableAudits;
	enable_pkg.EnableSurveys;
	unit_test_pkg.EnableChain;

	DeleteDataCreatedDuringTests;
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
	DeleteDataCreatedDuringTests;

	security.user_pkg.LogonAdmin(v_site_name);
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;


-- HELPER PROCS
PROCEDURE AssertMenuCreatedByLink_(
	in_link						VARCHAR2
)
AS
	v_menu_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(m.sid_id)
	  INTO v_menu_sid
	  FROM security.menu m
	  JOIN security.securable_object so ON m.sid_id = so.sid_id AND application_sid_id = security_pkg.GetApp
	 WHERE action = in_link;
	 
	unit_test_pkg.AssertNotEqual(NULL, v_menu_sid, 'Menu for '|| in_link ||' not created');
END;

/*
 * COPY FROM ENABLE_PKG - Create a menu or reset details on existing menu and return the SO ID.
 *
 * in_relocate_existing		Set to TRUE if you want to move existing menu to the specified parent
 * */
PROCEDURE INTERNAL_CreateOrSetMenu_(
	in_act_id				IN	security.security_pkg.T_ACT_ID,
	in_parent_sid_id		IN 	security.security_pkg.T_SID_ID,
	in_name					IN	security.security_pkg.T_SO_NAME,
	in_description			IN	security.menu.description%TYPE,
	in_action				IN	security.menu.action%TYPE,
	in_pos					IN	security.menu.pos%TYPE,
	in_context				IN	security.menu.context%TYPE,
	in_relocate_existing	IN	BOOLEAN,
	out_menu_sid_id			OUT	security.security_pkg.T_SID_ID
)
AS
	v_parent_match	NUMBER(1);
BEGIN
	-- Find menu by name, working out if it is in the correct location.
	-- If there are multiple menus with the same name, take the one with a matching parent first. Then whatever is next!
	SELECT sid_id, parent_match
	  INTO out_menu_sid_id, v_parent_match
	 FROM (
			SELECT m.sid_id, DECODE(so.parent_sid_id, in_parent_sid_id, 1, 0) parent_match, rownum rn
			  FROM security.menu m
			  JOIN security.securable_object so
					ON so.sid_id = m.sid_id
			 WHERE so.application_sid_id = SYS_CONTEXT('security', 'app')
			   AND LOWER(so.name) = LOWER(in_name)
			 ORDER BY parent_match DESC
		   )
	 WHERE rn = 1;

	IF v_parent_match = 0 AND in_relocate_existing = TRUE THEN
		security.securableobject_pkg.MoveSO(
			in_act_id			=> in_act_id,
			in_sid_id			=> out_menu_sid_id,
			in_new_parent_sid	=> in_parent_sid_id
		);
	END IF;

	security.menu_pkg.SetMenu(
		in_act_id		=> in_act_id,
		in_sid_id		=> out_menu_sid_id,
		in_description	=> in_description,
		in_action		=> in_action,
		in_pos			=> in_pos,
		in_context		=> in_context
	);
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		security.menu_pkg.CreateMenu(
			in_act_id			=> in_act_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_name				=> in_name,
			in_description		=> in_description,
			in_action			=> in_action,
			in_pos				=> in_pos,
			in_context			=> in_context,
			out_sid_id			=> out_menu_sid_id
		);
END;

PROCEDURE DisableSurveysIfEnabled_ AS
	v_www_csr_quicksurvey	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_www_csr_quicksurvey := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'wwwroot/csr/site/quickSurvey');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_www_csr_quicksurvey := NULL;
	END;
	
	IF v_www_csr_quicksurvey IS NOT NULL THEN
		disable_pkg.DisableSurveys();
	END IF;
END;

PROCEDURE DisableQuestionLibIfEnabled_ AS
	v_question_library_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_question_library_sid := security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'QuestionLibrary');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_question_library_sid := NULL;
	END;
	
	IF v_question_library_sid IS NOT NULL THEN
		disable_pkg.DisableQuestionLibrary();
	END IF;
END;

-- TESTS
PROCEDURE EnableAmfori 
AS	
	v_cnt NUMBER;
BEGIN
	disable_pkg.DisableAmforiIntegration;
	
	enable_pkg.EnableWorkflow;
	enable_pkg.EnableAmforiIntegration;
	
	SELECT COUNT(internal_audit_type_id)
	  INTO v_cnt
	  FROM internal_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'AMFORI_BSCI';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing internal audit type.');	
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'A';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure type A.');	
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'B';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure type B.');	
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'C';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure type C.');	
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'D';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure type D.');	
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'E';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure type E.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM audit_type_closure_type
	 WHERE app_sid = security.security_pkg.getapp;
	
	unit_test_pkg.AssertAreEqual(5, v_cnt, 'Missing audit type closure types');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'AMFORI_ANNOUNCE';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing Announcement tag group.');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'AMFORI_MONITORING';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing Monitoring tag group.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM internal_audit_type_tag_group atg
	  JOIN internal_audit_type a on a.internal_audit_type_id = atg.internal_audit_type_id
	  JOIN tag_group tg on tg.tag_group_id = atg.tag_group_id
	 WHERE a.lookup_key = 'AMFORI_BSCI'
	   AND tg.lookup_key = 'AMFORI_ANNOUNCE';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Announcement tag group not associated with internal audit type.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM internal_audit_type_tag_group atg
	  JOIN internal_audit_type a on a.internal_audit_type_id = atg.internal_audit_type_id
	  JOIN tag_group tg on tg.tag_group_id = atg.tag_group_id
	 WHERE a.lookup_key = 'AMFORI_BSCI'
	   AND tg.lookup_key = 'AMFORI_MONITORING';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Monitoring tag group not associated with internal audit type.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM chain.reference
	 WHERE lookup_key = 'AMFORI_SITEAMFORIID';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing chain reference.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM flow
	 WHERE label = 'Amfori_BSCI'
	   AND flow_alert_class = 'audit';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing workflow.');
	
	SELECT COUNT(internal_audit_type_id)
	  INTO v_cnt
	  FROM internal_audit_type iat
	  JOIN flow f ON f.app_sid = iat.app_sid AND f.flow_sid = iat.flow_sid 
	 WHERE iat.app_sid = security.security_pkg.getapp
	   AND UPPER(iat.lookup_key) = 'AMFORI_BSCI'
	   AND f.label = 'Amfori_BSCI'
	   AND f.flow_alert_class = 'audit';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing link between internal audit type and workflow.');
	
	disable_pkg.DisableAmforiIntegration;
END;

-- TESTS
PROCEDURE EnableAmforiSurvivesAuditClosureTypeWithDuplicateLabelAndNullLookup
AS	
	v_cnt NUMBER;
BEGIN
	disable_pkg.DisableAmforiIntegration;
	
	INSERT INTO csr.audit_closure_type (app_sid, audit_closure_type_id, label, is_failure, lookup_key)
		VALUES (security.security_pkg.GetApp, csr.audit_closure_type_id_seq.NEXTVAL, 'A', 0, NULL);
	
	enable_pkg.EnableAmforiIntegration;
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'A';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure types.');
	
	disable_pkg.DisableAmforiIntegration;
END;

PROCEDURE EnableAmforiSurvivesReusesAuditClosureTypeWithRequestedLookup
AS
	v_cnt NUMBER;
BEGIN
	disable_pkg.DisableAmforiIntegration;
	
	INSERT INTO csr.audit_closure_type (app_sid, audit_closure_type_id, label, is_failure, lookup_key)
		VALUES (security.security_pkg.GetApp, csr.audit_closure_type_id_seq.NEXTVAL, 'OTHER LABEL A', 0, 'A');
	
	enable_pkg.EnableAmforiIntegration;
	
	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(label) = 'OTHER LABEL A'
	   AND UPPER(lookup_key) = 'A';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure types.');
	
	disable_pkg.DisableAmforiIntegration;
END;


PROCEDURE CreateWorkflow
AS
	v_flow_state_id		csr.flow_state.flow_state_id%TYPE;
BEGIN
	csr.unit_test_pkg.GetOrCreateWorkflow(
		in_label						=> 'Audit workflow for Amfori database tests',
		in_flow_alert_class				=> 'audit',
		out_sid							=> v_workflow_sid);

	csr.unit_test_pkg.GetOrCreateWorkflowState(
		in_flow_sid			=> v_workflow_sid,
		in_state_label		=> 'Default state',
		in_state_lookup_key	=> 'DEFAULT',
		out_flow_state_id	=> v_flow_state_id);
END;

PROCEDURE EnableAmforiFailsWhenAuditWithLookupKeyExists
AS
	v_cnt NUMBER;
	v_audit_type_cur				security.security_pkg.T_OUTPUT_CUR;
	v_bsci_impostor_audit_type_id	NUMBER;
	v_dummy_sids					security.security_pkg.T_SID_IDS;
BEGIN
	disable_pkg.DisableAmforiIntegration;

	CreateWorkflow;

	audit_pkg.saveinternalaudittype(
		in_internal_audit_type_id		=> null,
		in_label						=> 'BSCI',
		in_every_n_months				=> null,
		in_auditor_role_sid				=> null,
		in_audit_contact_role_sid		=> null,
		in_default_survey_sid			=> null,
		in_default_auditor_org			=> '',
		in_override_issue_dtm			=> 0,
		in_assign_issues_to_role		=> 0,
		in_auditor_can_take_ownership	=> 0,
		in_add_nc_per_question			=> 0,
		in_nc_audit_child_region		=> 0,
		in_flow_sid						=> v_workflow_sid,
		in_internal_audit_source_id		=> 1,
		in_summary_survey_sid			=> null,
		in_send_auditor_expiry_alerts	=> 1,
		in_expiry_alert_roles			=> v_dummy_sids,
		in_validity_months				=> null,
		in_involve_auditor_in_issues	=> 0,
		in_active						=> 0,
		out_cur							=> v_audit_type_cur
	);
	SELECT internal_audit_type_id
		INTO v_bsci_impostor_audit_type_id
		FROM internal_audit_type
		WHERE app_sid = security.security_pkg.getapp
		AND label = 'BSCI';

	BEGIN
		enable_pkg.EnableAmforiIntegration;
		unit_test_pkg.TestFail('Amfori should not be enabled.');
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Expecting 20001.');
			END IF;
	END;

	FOR r in (
			SELECT internal_audit_type_id
			  FROM internal_audit_type
			 WHERE app_sid = security.security_pkg.getapp
			   AND label = 'BSCI'
	)
	LOOP
		--dbms_output.put_line('delete iat:'||r.internal_audit_type_id);
		audit_pkg.DeleteInternalAuditType(r.internal_audit_type_id);
	END LOOP;

	disable_pkg.DisableAmforiIntegration;
END;


-- RBA TESTS
PROCEDURE RBA01_EnableRBAFailsWhenChainNotEnabled
AS	
	v_cnt NUMBER;
BEGIN
	-- disable chain (or simulate it at least)
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM chain.customer_options
	 WHERE app_sid = security.security_pkg.getapp;
	
	IF v_cnt > 0 THEN
		dbms_output.put_line('EnableRBAFailsWhenChainNotEnabled - chain is enabled, test ignored.');
	ELSE
		BEGIN
			enable_pkg.EnableRBAIntegration;
			enable_pkg.DeleteRBAIntegration;
			unit_test_pkg.TestFail('Unexpected success');
		EXCEPTION
			WHEN OTHERS THEN 
				IF SQLCODE = -20363 THEN unit_test_pkg.TestFail('Unexpected success');
				ELSIF SQLCODE = -20001 THEN NULL;
				ELSE unit_test_pkg.TestFail('Unexpected exception');
				END IF;
		END;
		-- reenable chain
	END IF;
END;

PROCEDURE RBA02_EnableRBA
AS	
	v_cnt NUMBER;
BEGIN
	enable_pkg.DeleteRBAIntegration;
	enable_pkg.EnableRBAIntegration;
	
	v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/RBA Audit Workflow');
	unit_test_pkg.AssertIsTrue(v_workflow_sid > 0, 'Missing workflow.');

	SELECT COUNT(reference_id)
	  INTO v_cnt
	  FROM chain.reference
	 WHERE lookup_key IN ('RBA_SITECODE');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing references.');

	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'PASS';
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure types.');
	
	SELECT COUNT(internal_audit_type_id)
	  INTO v_cnt
	  FROM internal_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Deleted internal audit type should not be found.');

	SELECT COUNT(internal_audit_type_id)
	  INTO v_cnt
	  FROM internal_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_TYPE');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing internal audit type.');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_TYPE');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing tag group.');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_CAT');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing tag group.');
	
	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_VAP', 'RBA_VAP_MEDIUM_BUSINESS', 'RBA_VAP_SMALL_BUSINESS', 'RBA_EMPLOYMENT_SITE_SVAP_ONLY', 'RBA_EMPLOYMENT_SITE_SVAP_AND_V');
	unit_test_pkg.AssertAreEqual(5, v_cnt, 'Missing RBA Audit Category tags.');

	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_INITIAL_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT', 'RBA_CLOSURE_AUDIT');
	unit_test_pkg.AssertAreEqual(3, v_cnt, 'Missing RBA Audit Type tags.');
	
	/*SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_F_FINDING_SEVERITY');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing tag group.');
	
	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_F_PRIORITY_NONCONFORMANCE', 'RBA_F_MAJOR_NONCONFORMANCE', 'RBA_F_MINOR_NONCONFORMANCE',
	   'RBA_F_RISK_OF_NONCONFORMANCE', 'RBA_F_OPPORTUNITY_FOR_IMPROVEM', 'RBA_F_CONFORMANCE', 'RBA_F_NOT_APPLICABLE');
	unit_test_pkg.AssertAreEqual(7, v_cnt, 'Missing tags.');*/


	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SECTION%');
	unit_test_pkg.AssertAreEqual(5, v_cnt, 'Missing RBA_SECTION tag groups.');
	
	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SUBSECTION_A%');
	unit_test_pkg.AssertAreEqual(8, v_cnt, 'Missing RBA_SUBSECTION_A tags.');

	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SUBSECTION_B%');
	unit_test_pkg.AssertAreEqual(9, v_cnt, 'Missing RBA_SUBSECTION_B tags.');

	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SUBSECTION_C%');
	unit_test_pkg.AssertAreEqual(9, v_cnt, 'Missing RBA_SUBSECTION_C tags.');

	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SUBSECTION_D%');
	unit_test_pkg.AssertAreEqual(9, v_cnt, 'Missing RBA_SUBSECTION_D tags.');

	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SUBSECTION_E%');
	unit_test_pkg.AssertAreEqual(14, v_cnt, 'Missing RBA_SUBSECTION_E tags.');


	SELECT COUNT(*)
	  INTO v_cnt
	  FROM non_compliance_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_F_PRIORITY_NONCONFORMANCE', 'RBA_F_MAJOR_NONCONFORMANCE', 'RBA_F_MINOR_NONCONFORMANCE',
	   'RBA_F_RISK_OF_NONCONFORMANCE', 'RBA_F_OPPORTUNITY_FOR_IMPROVEM', 'RBA_F_CONFORMANCE', 'RBA_F_NOT_APPLICABLE');
	unit_test_pkg.AssertAreEqual(7, v_cnt, 'Missing non compliance types.');
	
	/*SELECT COUNT(*)
	  INTO v_cnt
	  FROM non_compliance_type_tag_group a
	  JOIN non_compliance_type b ON a.app_sid = b.app_sid AND a.non_compliance_type_id = b.non_compliance_type_id
	  JOIN tag_group c ON a.app_sid = c.app_sid AND a.tag_group_id = c.tag_group_id
	 WHERE a.app_sid = security.security_pkg.getapp
	   AND UPPER(b.lookup_key) IN ('RBA_FINDING')
	   AND UPPER(c.lookup_key) IN ('RBA_F_FINDING_SEVERITY');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing non compliance tag mapping.');*/
	
	SELECT COUNT(score_type_id)
	  INTO v_cnt
	  FROM score_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_SCORE');
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing score type.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM score_type_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND internal_audit_type_id IN (SELECT internal_audit_type_id FROM internal_audit_type WHERE UPPER(lookup_key) IN ('RBA_AUDIT_TYPE'))
	   AND score_type_id IN (SELECT score_type_id FROM score_type WHERE UPPER(lookup_key) IN ('RBA_AUDIT_SCORE'));
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing audit type score types.');
	
	BEGIN
		v_cnt := security.securableobject_pkg.getSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'menu/ia/csr_ia_qa_list');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			unit_test_pkg.TestFail('List menu item missing.');
	END;
	
	enable_pkg.DeleteRBAIntegration;
END;

PROCEDURE RBA03_DisableRBA
AS	
	v_cnt NUMBER;
BEGIN
	enable_pkg.DeleteRBAIntegration;
	enable_pkg.EnableRBAIntegration;
	
	v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/RBA Audit Workflow');
	unit_test_pkg.AssertIsTrue(v_workflow_sid > 0, 'Missing workflow.');

	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'PASS';
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure types.');
	

	enable_pkg.DisableRBAIntegration;

	v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/RBA Audit Workflow');
	unit_test_pkg.AssertIsTrue(v_workflow_sid > 0, 'Missing workflow.');

	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'PASS';
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Missing closure types.');

	SELECT COUNT(reference_id)
	  INTO v_cnt
	  FROM chain.reference
	 WHERE lookup_key IN ('RBA_SITECODE');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected references.');

	enable_pkg.DeleteRBAIntegration;
END;

PROCEDURE RBA04_DeleteRBA
AS	
	v_cnt NUMBER;
	v_sid NUMBER;
BEGIN
	enable_pkg.DeleteRBAIntegration;

	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/RBA Audit Workflow');
		unit_test_pkg.TestFail('Unexpected workflow.');
		EXCEPTION
			WHEN OTHERS THEN 
				IF SQLCODE = -20102 THEN NULL;
				ELSE unit_test_pkg.TestFail('Unexpected workflow');
				END IF;
		END;

	SELECT COUNT(reference_id)
	  INTO v_cnt
	  FROM chain.reference
	 WHERE lookup_key IN ('RBA_SITECODE');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected references.');

	SELECT COUNT(audit_closure_type_id)
	  INTO v_cnt
	  FROM audit_closure_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'PASS';
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected closure types.');
	
	SELECT COUNT(internal_audit_type_id)
	  INTO v_cnt
	  FROM internal_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected internal audit type.');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_TYPE');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected tag group.');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_CAT');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected tag group.');
	
	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_VAP', 'RBA_VAP_MEDIUM_BUSINESS', 'RBA_EMPLOYMENT_SITE_SVA_ONLY');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected tags.');
	
	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_F_FINDING_SEVERITY');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected tag group.');
	
	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_F_PRIORITY_NONCONFORMANCE', 'RBA_F_MAJOR_NONCONFORMANCE', 'RBA_F_MINOR_NONCONFORMANCE',
	   'RBA_F_RISK_OF_NONCONFORMANCE', 'RBA_F_OPPORTUNITY_FOR_IMPROVEM', 'RBA_F_CONFORMANCE', 'RBA_F_NOT_APPLICABLE');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected tags.');


	SELECT COUNT(tag_group_id)
	  INTO v_cnt
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SECTION%');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected RBA_SECTION tag group.');

	SELECT COUNT(tag_id)
	  INTO v_cnt
	  FROM tag
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) LIKE ('RBA_SUBSECTION%');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected RBA_SUBSECTION tags.');


	SELECT COUNT(score_type_id)
	  INTO v_cnt
	  FROM score_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) IN ('RBA_AUDIT_SCORE');
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected score type.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM score_type_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND internal_audit_type_id IN (SELECT internal_audit_type_id FROM internal_audit_type WHERE UPPER(lookup_key) IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT'))
	   AND score_type_id IN (SELECT score_type_id FROM score_type WHERE UPPER(lookup_key) IN ('RBA_AUDIT_SCORE'));
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Unexpected audit type score types.');
	
	BEGIN
		v_sid := security.securableobject_pkg.getSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'menu/ia/csr_ia_qa_list');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_sid := null;
	END;
	
	unit_test_pkg.AssertIsNull(v_sid, 'List menu item remaining,');
END;




-- QL TESTS
PROCEDURE QuestionLibraryMenuStructure AS
	v_moved_menu_sid		security_pkg.T_SID_ID;
	v_www_sid				security_pkg.T_SID_ID;
	v_www_csr_quicksurvey	security_pkg.T_SID_ID;
	v_groups_sid			security_pkg.T_SID_ID;
	v_reg_users 			security_pkg.T_SID_ID;
	v_admins 				security_pkg.T_SID_ID;
	v_menu_acl				Security_Pkg.T_ACL_ID;
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_cnt					NUMBER;
BEGIN
	v_www_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	DisableSurveysIfEnabled_;

	enable_pkg.EnableSurveys;

	-- Move Survey Menus
	BEGIN
		INTERNAL_CreateOrSetMenu_(
			in_act_id				=> SYS_CONTEXT('security', 'act'),
			in_parent_sid_id		=> securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/data'),
			in_name					=> 'csr_quicksurvey_admin',
			in_description			=> 'QuickSurveys',
			in_action				=> '/csr/site/quicksurvey/admin/list.acds',
			in_pos					=> NULL,
			in_context				=> NULL,
			in_relocate_existing	=> TRUE,
			out_menu_sid_id			=> v_moved_menu_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			--Don't know what causes this but if it is already in the right place then whatever...
			v_moved_menu_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/data/csr_quicksurvey_admin');
	END;

	security.acl_pkg.DeleteAllACES(v_act_id, acl_pkg.GetDACLIDForSID(v_moved_menu_sid));

	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Groups');
	v_reg_users 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins 				:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_menu_acl				:= acl_pkg.GetDACLIDForSID(v_moved_menu_sid);

	security.acl_pkg.AddACE(
		v_act_id,
		v_menu_acl,
		1,
		security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_reg_users,
		security_pkg.PERMISSION_STANDARD_READ
	);

	security.acl_pkg.AddACE(
		v_act_id,
		v_menu_acl,
		2,
		security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins,
		security.security_pkg.PERMISSION_STANDARD_ALL
	);

	DisableQuestionLibIfEnabled_;

	enable_pkg.EnableQuestionLibrary;

	AssertMenuCreatedByLink_('/csr/site/quickSurvey/library/library.acds');
	AssertMenuCreatedByLink_('/csr/site/quicksurvey/library/list.acds');
	AssertMenuCreatedByLink_('/csr/site/surveys/config.acds');

	SELECT COUNT(sid_id)
	  INTO v_cnt
	  FROM security.ACL
	 WHERE acl_id = v_menu_acl
	   AND sid_id NOT IN (v_reg_users, v_admins);

	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Menu permissions have changed on old surveys list.');

	securableobject_pkg.DeleteSO(v_act_id, v_moved_menu_sid);

	DisableQuestionLibIfEnabled_;
	DisableSurveysIfEnabled_;
END;

-- Gresb tests
PROCEDURE EnableGresb
AS	
	v_property_admin_sid	SECURITY.SECURITY_PKG.T_SID_ID;
	v_gresb_service_config	property_options.gresb_service_config%TYPE;
	v_measure_sid			measure.measure_sid%TYPE;
	v_name					measure.name%TYPE;
	v_description			measure.description%TYPE;
BEGIN
	enable_pkg.DisableGresb;

	-- Properties is not easily reversible, simulate by removing a menu
	BEGIN
		v_property_admin_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/admin/csr_property_admin_menu');
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, v_property_admin_sid);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	BEGIN
		enable_pkg.EnableGresb(
			in_environment => NULL,
			in_floor_area_measure_type => NULL
		);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Expecting 20001.');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual(SQLERRM, 'ORA-20001: The Property Admin menu does not exist - enable Properties first.', 'Unexpected exception');
			END IF;
	END;

	csr_data_pkg.enablecapability('System management');
	enable_pkg.EnableProperties(
		in_company_name => 'ENABLEGRESB_COMPANY',
		in_property_type => 'ENABLEGRESB_PROPTYPE'
	);

	BEGIN
		enable_pkg.EnableGresb(
			in_environment => NULL,
			in_floor_area_measure_type => NULL
		);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Expecting 20001.');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual(SQLERRM, 'ORA-20001: The Gresb environment must be set to sandbox or live.', 'Unexpected exception');
			END IF;
	END;


	BEGIN
		enable_pkg.EnableGresb(
			in_environment => 'not sandbox',
			in_floor_area_measure_type => NULL
		);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Expecting 20001.');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual(SQLERRM, 'ORA-20001: The Gresb environment must be sandbox or live.', 'Unexpected exception');
			END IF;
	END;

	BEGIN
		enable_pkg.EnableGresb(
			in_environment => 'sandbox',
			in_floor_area_measure_type => NULL
		);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Expecting 20001.');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual(SQLERRM, 'ORA-20001: An existing measure with lookup key GRESB_FLOORAREA was not found. A floor area label must be supplied.', 'Unexpected exception');
			END IF;
	END;

	BEGIN
		enable_pkg.EnableGresb(
			in_environment => 'sandbox',
			in_floor_area_measure_type => 'not valid'
		);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Expecting 20001.');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual(SQLERRM, 'ORA-20001: The floor area label must be m^2 or ft^2', 'Unexpected exception');
			END IF;
	END;

	enable_pkg.EnableGresb(
		in_environment => 'sandbox',
		in_floor_area_measure_type => 'm^2'
	);

	SELECT gresb_service_config
	  INTO v_gresb_service_config
	  FROM property_options
	 WHERE app_sid = security.security_pkg.GetApp;
	unit_test_pkg.AssertAreEqual('sandbox', v_gresb_service_config, 'Unexpected value');

	SELECT measure_sid, name, description
	  INTO v_measure_sid, v_name, v_description
	  FROM measure
	 WHERE app_sid = security.security_pkg.GetApp
	   AND lookup_key = 'GRESB_FLOORAREA';
	unit_test_pkg.AssertAreEqual('GRESB m^2', v_name, 'Unexpected value');
	unit_test_pkg.AssertAreEqual('m^2', v_description, 'Unexpected value');


	enable_pkg.EnableGresb(
		in_environment => 'live',
		in_floor_area_measure_type => 'ft^2'
	);

	SELECT gresb_service_config
	  INTO v_gresb_service_config
	  FROM property_options
	 WHERE app_sid = security.security_pkg.GetApp;
	unit_test_pkg.AssertAreEqual('live', v_gresb_service_config, 'Unexpected value');

	SELECT measure_sid, name, description
	  INTO v_measure_sid, v_name, v_description
	  FROM measure
	 WHERE app_sid = security.security_pkg.GetApp
	   AND lookup_key = 'GRESB_FLOORAREA';
	unit_test_pkg.AssertAreEqual('GRESB ft^2', v_name, 'Unexpected value');
	unit_test_pkg.AssertAreEqual('ft^2', v_description, 'Unexpected value');
	
	enable_pkg.DisableGresb;
END;

PROCEDURE EnableCarbonEmissions
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_www_carbon			security_pkg.T_SID_ID;
	v_www_emissionfactors	security_pkg.T_SID_ID;
BEGIN
	enable_pkg.EnableCarbonEmissions;

	BEGIN
		v_www_carbon := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/admin/carbon');
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unable to get carbon webresource');
	END;
	
	BEGIN
		v_www_emissionfactors := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/admin/emissionFactors');
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unable to get emissionFactors webresource');
	END;
END;

PROCEDURE EnableLandingPages
AS	
	v_act_id			security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_setup		security_pkg.T_SID_ID;
	v_count				NUMBER;
BEGIN
	enable_pkg.LogDelete('Landing Pages');
	
	enable_pkg.DisableLandingPages;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM module_history
	 WHERE module_id = enable_pkg.GetModuleId('Landing Pages')
	   AND enabled_dtm IS NULL
	   AND last_enabled_dtm IS NULL
	   AND disabled_dtm IS NOT NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Unexpected module count');
	
	enable_pkg.EnableLandingPages;

	SELECT COUNT(*)
	  INTO v_count
	  FROM module_history
	 WHERE module_id = enable_pkg.GetModuleId('Landing Pages')
	   AND enabled_dtm IS NOT NULL
	   AND last_enabled_dtm IS NOT NULL
	   AND disabled_dtm IS NOT NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Unexpected module count');

	enable_pkg.LogDelete('Landing Pages');

	enable_pkg.EnableLandingPages;

	SELECT COUNT(*)
	  INTO v_count
	  FROM module_history
	 WHERE module_id = enable_pkg.GetModuleId('Landing Pages')
	   AND enabled_dtm IS NOT NULL
	   AND last_enabled_dtm IS NOT NULL
	   AND disabled_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Unexpected module count');
	
	v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_users_landing_page');
	unit_test_pkg.AssertIsTrue(v_menu_setup IS NOT NULL, 'Menu not found');

	-- re--enable
	enable_pkg.EnableLandingPages;

	SELECT COUNT(*)
	  INTO v_count
	  FROM module_history
	 WHERE module_id = enable_pkg.GetModuleId('Landing Pages')
	   AND enabled_dtm IS NOT NULL
	   AND last_enabled_dtm IS NOT NULL
	   AND disabled_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Unexpected module count');
	
	enable_pkg.DisableLandingPages;

	SELECT COUNT(*)
	  INTO v_count
	  FROM module_history
	 WHERE module_id = enable_pkg.GetModuleId('Landing Pages')
	   AND enabled_dtm IS NOT NULL
	   AND last_enabled_dtm IS NOT NULL
	   AND disabled_dtm IS NOT NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Unexpected module count');
END;


PROCEDURE DisableLandingPages
AS	
	v_act_id			security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_setup		security_pkg.T_SID_ID;
BEGIN
	enable_pkg.EnableLandingPages;

	enable_pkg.DisableLandingPages;

	BEGIN
		v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_users_landing_page');
		unit_test_pkg.TestFail('Menu should not be found');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;
END;

PROCEDURE EnableDelegationPlan
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_edit_plan		security_pkg.T_SID_ID;
	v_menu_plan_list		security_pkg.T_SID_ID;
BEGIN
	enable_pkg.EnableDelegPlan;

	BEGIN
		v_menu_edit_plan := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin/csr_delegation_edit_plan');
		unit_test_pkg.TestFail('Edit delegation plan menu item exists. ' || v_menu_edit_plan);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;

	BEGIN
		v_menu_plan_list := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin/csr_delegation_plan');
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unable to get delegation plan list menu item');
	END;
END;

PROCEDURE EnableConsentSettings
AS	
	v_act_id			security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_setup		security_pkg.T_SID_ID;
	v_ga_cap			BOOLEAN;
BEGIN
	enable_pkg.EnableConsentSettings(in_enable => 1, in_position => -1);

	BEGIN
		v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin/csr_site_admin_consent_settings');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN unit_test_pkg.TestFail('Menu should be found');
	END;

	v_ga_cap := csr_data_pkg.CheckCapability('Google Analytics Management');
	unit_test_pkg.AssertIsTrue(v_ga_cap, 'Expected capability to be present');
END;

PROCEDURE DisableConsentSettings
AS	
	v_act_id			security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_setup		security_pkg.T_SID_ID;
	v_ga_cap			BOOLEAN;
BEGIN
	enable_pkg.EnableConsentSettings(in_enable => 1, in_position => -1);

	enable_pkg.EnableConsentSettings(in_enable => 0, in_position => -1);

	BEGIN
		v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_users_landing_page');
		unit_test_pkg.TestFail('Menu should not be found');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	v_ga_cap := csr_data_pkg.CheckCapability('Google Analytics Management');
	unit_test_pkg.AssertIsFalse(v_ga_cap, 'Expected capability to be not present');

END;

PROCEDURE EnableTargetPlanning
AS	
	v_act_id			security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_setup		security_pkg.T_SID_ID;
	v_tp_cap			BOOLEAN;
BEGIN
	enable_pkg.EnableTargetPlanning(in_enable => 1, in_position => -1);

	BEGIN
		v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/analysis/csr_site_analysis_target_planning');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN unit_test_pkg.TestFail('Menu should be found');
	END;

	v_tp_cap := csr_data_pkg.CheckCapability('Target Planning');
	unit_test_pkg.AssertIsTrue(v_tp_cap, 'Expected capability to be present');
END;

PROCEDURE DisableTargetPlanning
AS	
	v_act_id			security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid			security_pkg.T_SID_ID := security_pkg.GetApp;
	v_menu_setup		security_pkg.T_SID_ID;
	v_tp_cap			BOOLEAN;
BEGIN
	enable_pkg.EnableTargetPlanning(in_enable => 1, in_position => -1);

	enable_pkg.EnableTargetPlanning(in_enable => 0, in_position => -1);

	BEGIN
		v_menu_setup := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/analysis/csr_site_analysis_target_planning');
		unit_test_pkg.TestFail('Menu should not be found');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;

	v_tp_cap := csr_data_pkg.CheckCapability('Target Planning');
	unit_test_pkg.AssertIsFalse(v_tp_cap, 'Expected capability to be not present');

END;

END test_enable_pkg;
/
