CREATE OR REPLACE PACKAGE BODY csr.test_audit_pkg AS

-- Fixture scope
v_site_name					VARCHAR(200);
v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_administrators_sid		security.security_pkg.T_SID_ID;

v_regs						security.security_pkg.T_SID_IDS;
v_users						security.security_pkg.T_SID_IDS;

--TagsAreCreated
v_tag_id					security.security_pkg.T_SID_ID;
v_tag_ids					security.security_pkg.T_SID_IDS;
v_audit_sid 				security.security_pkg.T_SID_ID;
v_survey_sid				security.security_pkg.T_SID_ID;
v_non_comp_default_id		security.security_pkg.T_SID_ID;	
v_internal_audit_type_id	security.security_pkg.T_SID_ID;
v_non_comp_type_id 			security.security_pkg.T_SID_ID;
v_flow_sid					security.security_pkg.T_SID_ID;
v_tag_group_id				security.security_pkg.T_SID_ID;

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE RemoveSids(
	v_sids					security_pkg.T_SID_IDS
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

PROCEDURE SetUp
AS
	v_sids						security.security_pkg.T_SID_IDS;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_surveys_sid				security.security_pkg.T_SID_ID;
	v_flow_state_id				security.security_pkg.T_SID_ID;
	v_out_cur					SYS_REFCURSOR;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;
	
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'surveys');
		
	-- CREATE AUDIT
	unit_test_pkg.GetOrCreateWorkflow(
		in_label => 'Audit Workflow',
		in_flow_alert_class => 'audit',
		out_sid => v_flow_sid
	);	
	
	unit_test_pkg.GetOrCreateWorkflowState (
		in_flow_sid						=> v_flow_sid,
		in_state_label					=> 'Only',
		in_state_lookup_key				=> 'ONLY',
		out_flow_state_id				=> v_flow_state_id
	);
	
	unit_test_pkg.SetFlowCapability(
		in_flow_capability 	=> csr_data_pkg.FLOW_CAP_AUDIT_NC_TAGS,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set 	=> 1,
		in_group_sid 		=> v_administrators_sid
	);
	
	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name				=> 'Flow Audit',
		in_flow_sid			=> v_flow_sid,
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_audit_type_name	=> 'AUDIT_TYPE_WITH_FLOW',
		in_audit_dtm		=> '01-JAN-2020'
	);
	
	-- CREATE DEFAULT FINDING	
	audit_pkg.SetNonComplianceType (
		in_non_compliance_type_id			=> NULL,
		in_label							=> 'Label',
		in_lookup_key						=> 'NCT',
		in_position							=> 1,
		in_colour_when_open					=> 16712965,
		in_colour_when_closed				=> 3777539,
		in_can_have_actions					=> 1,
		in_closure_behaviour_id				=> 2,
		in_repeat_audit_type_ids			=> v_sids,
		out_non_compliance_type_id			=> v_non_comp_type_id
	);
	
	audit_pkg.SetNonComplianceDefault(
		in_non_comp_default_id			=> NULL,
		in_folder_id					=> NULL,
		in_label						=> 'Label',
		in_detail						=> 'Detail',
		in_non_compliance_type_id		=> v_non_comp_type_id,
		in_root_cause					=> NULL,
		in_suggested_action				=> NULL,
		in_unique_reference				=> 'NCD',
		out_non_comp_default_id			=> v_non_comp_default_id
	);
	
	tag_pkg.SetTagGroup(
		in_name					=>	'Tag group',
		in_multi_select			=>	0,
		in_mandatory			=>	0,
		in_applies_to_non_comp	=>	1,
		in_lookup_key			=>	'TG',
		out_tag_group_id		=>	v_tag_group_id
	);
	
	tag_pkg.SetTag(
		in_tag_group_id			=>	v_tag_group_id,
		in_tag					=>	'Tag',
		in_explanation			=>	'A tag',
		in_lookup_key			=>	'TAG',
		out_tag_id				=>	v_tag_id
	);
	
	INSERT INTO non_comp_default_tag (non_comp_default_id, tag_id)
	VALUES (v_non_comp_default_id, v_tag_id);
	
	v_tag_ids(1) := v_tag_id;
	
		-- CREATE AUDIT SURVEY
	quick_survey_pkg.AddTempQuestion(
		in_question_id				=> 22,
		in_question_version			=> 0,	
		in_parent_id				=> NULL,
		in_parent_version			=> NULL,
		in_label					=> 'Raise Finding?',
		in_question_type			=> 'radio',
		in_score					=> NULL,
		in_max_score				=> NULL,
		in_upload_score				=> NULL,
		in_lookup_key				=> 'RADIO',
		in_invert_score				=> 0,
		in_custom_question_type_id	=> NULL,
		in_weight					=> NULL,
		in_dont_normalise_score		=> 0,
		in_has_score_expression		=> 0,
		in_has_max_score_expr		=> 0,
		in_remember_answer			=> 0,
		in_count_question			=> 0,
		in_action					=> NULL,
		in_question_xml				=> '<question type="radio" id="22" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0"><description>Raise Finding?</description><tags matchEveryCategory="false" /><option action="none" id="21" lookup_key="DB_TEST_YES" ncId="'||v_non_comp_default_id||'" ncPopup="true" ncTagIds="'||v_tag_id||'">Yes, Please</option><option action="none" lookup_key="DB_TEST_NO" id="22">No, Thanks</option><helpText></helpText><helpTextLong></helpTextLong><helpTextLongLink></helpTextLongLink><infoPopup></infoPopup></question>'
	);
	
	quick_survey_pkg.AddTempQuestionOption(
		in_question_id				=> 22,
		in_question_version			=> 0,
		in_question_option_id		=> 21,
		in_label					=> 'Yes, Please',
		in_score					=> NULL,
		in_has_override				=> 0,
		in_score_override			=> 0,
		in_hidden					=> 0,
		in_color					=> NULL,
		in_lookup_key				=> 'DB_TEST_YES',
		in_option_action			=> NULL,
		in_non_compliance_popup		=> 1,
		in_non_comp_default_id		=> v_non_comp_default_id,
		in_non_compliance_type_id	=> NULL,
		in_non_compliance_label		=> 'Label',
		in_non_compliance_detail	=> 'Details',
		in_non_comp_root_cause		=> NULL,
		in_non_comp_suggested_action => NULL,
		in_question_option_xml		=> '<option action="none" id="21" lookup_key="DB_TEST_YES" ncId="'||v_non_comp_default_id||'" ncPopup="true" ncTagIds="'||v_tag_id||'">Yes, Please</option>'
	);
	
	quick_survey_pkg.AddTempQuestionOption(
		in_question_id				=> 22,
		in_question_version			=> 0,
		in_question_option_id		=> 22,
		in_label					=> 'No, Thanks',
		in_score					=> NULL,
		in_has_override				=> 0,
		in_score_override			=> 0,
		in_hidden					=> 0,
		in_color					=> NULL,
		in_lookup_key				=> 'DB_TEST_NO',
		in_option_action			=> NULL,
		in_non_compliance_popup		=> 0,
		in_non_comp_default_id		=> NULL,
		in_non_compliance_type_id	=> NULL,
		in_non_compliance_label		=> NULL,
		in_non_compliance_detail	=> NULL,
		in_non_comp_root_cause		=> NULL,
		in_non_comp_suggested_action => NULL,
		in_question_option_xml		=> '<option action="none" id="22" lookup_key="DB_TEST_NO">No, Thanks</option>'
	);
	
	quick_survey_pkg.AddTempQstnOptionNCTag(
		in_question_id				=> 22,
		in_question_version			=> 0,
		in_question_option_id		=> 21,
		in_tag_ids					=> v_tag_ids
	);
	
	quick_survey_pkg.ImportSurvey(
		in_xml					=> '<?xml version="1.0" encoding="UTF-8"?><questions sid="119009"><pageBreak id="21" version="0" isTop="1" /><question type="radio" id="22" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0"><description>Raise Finding?</description><tags matchEveryCategory="false" /><option action="none" id="21" lookup_key="DB_TEST_YES" ncId="'||v_non_comp_default_id||'" ncPopup="true" ncTagIds="'||v_tag_id||'">Yes, Please</option><option action="none" id="22" lookup_key="DB_TEST_NO">No, Thanks</option><helpText></helpText><helpTextLong></helpTextLong><helpTextLongLink></helpTextLongLink><infoPopup></infoPopup></question><actionImport /><objectImport><tagGroup tagGroupId="66" name="Tag group" appliesToNonCompliances="True" appliesToQuickSurvey="False" mandatory="False" multiSelect="False"><tag id="'||v_tag_id||'" label="Finding Tag 1" lookupKey="TAG" pos="1" /></tagGroup><DefaultNonCompliance xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><DefaultNonComplianceId/><FolderId xsi:nil="true" /><UniqueReference>NCD</UniqueReference><Label>Default Finding 1</Label><Detail>123</Detail><NonComplianceTypeId/></DefaultNonCompliance><NonComplianceTypeDto xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><NonComplianceTypeId/><Label>New</Label><LookupKey>NCT</LookupKey><Position>0</Position><ColourWhenOpen>16712965</ColourWhenOpen><ColourWhenClosed>3777539</ColourWhenClosed><CanHaveActions>true</CanHaveActions><ClosureBehaviourId>2</ClosureBehaviourId><RootCauseEnabled>false</RootCauseEnabled><SuggestedActionEnabled>false</SuggestedActionEnabled><Score xsi:nil="true" /><RepeatScore xsi:nil="true" /><MatchRepeatsByCarryFwd>false</MatchRepeatsByCarryFwd><MatchRepeatsByDefaultNcs>false</MatchRepeatsByDefaultNcs><MatchRepeatsBySurveys>false</MatchRepeatsBySurveys><FindRepeatsInUnit>none</FindRepeatsInUnit><FindRepeatsInQty xsi:nil="true" /><CarryFwdRepeatType>normal</CarryFwdRepeatType><IsDefaultSurveyFinding>false</IsDefaultSurveyFinding><IsFlowCapabilityEnabled>false</IsFlowCapabilityEnabled></NonComplianceTypeDto></objectImport></questions>',
		in_name					=> 'SURVEY',
		in_label				=> 'Finding Survey',
		in_audience				=> 'audit',
		in_parent_sid			=> v_surveys_sid,
		out_survey_sid          => v_survey_sid
	);
	
	quick_survey_pkg.PublishSurvey (
		in_survey_sid				=> v_survey_sid,
		in_update_responses_from	=> NULL,
		out_publish_result			=> v_out_cur
	);
	
	-- SET AUDIT DEFAULT SURVEY
	INSERT INTO internal_audit_type (internal_audit_type_id, label, flow_sid, internal_audit_type_source_id)
	VALUES (internal_audit_type_id_seq.nextval, 'AUDIT_TYPE_WITH_FLOW', v_flow_sid, 1)
	RETURNING internal_audit_type_id INTO v_internal_audit_type_id;
	
	audit_pkg.SetDefaultSurvey(
		in_internal_audit_type_id 	=> v_internal_audit_type_id,
		in_default_survey_sid 		=> v_survey_sid
	);
	
	-- CREATE AUDIT
	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name				=> 'Flow Audit',
		in_flow_sid			=> v_flow_sid,
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_survey_sid		=> v_survey_sid,
		in_audit_type_name	=> 'AUDIT_TYPE_WITH_FLOW',
		in_audit_dtm		=> '01-JAN-2020'
	);
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	-- Delete Audit
	IF v_audit_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(v_act_id, v_audit_sid);
	END IF;
	-- Delete Finding Type
	IF v_non_comp_type_id IS NOT NULL THEN
		audit_pkg.DeleteNonComplianceType(v_non_comp_type_id);
	END IF;
	-- Delete Audit Type
	IF v_internal_audit_type_id IS NOT NULL THEN
		DELETE FROM csr.internal_audit_type_survey WHERE internal_audit_type_id = v_internal_audit_type_id;
		DELETE FROM csr.internal_audit_type WHERE internal_audit_type_id = v_internal_audit_type_id;
	END IF;
	--Delete Default Finding
	IF v_non_comp_default_id IS NOT NULL THEN
		DELETE FROM qs_question_option_nc_tag WHERE question_option_id IN (SELECT question_option_id FROM qs_question_option WHERE non_comp_default_id = v_non_comp_default_id);
		DELETE FROM qs_question_option WHERE non_comp_default_id = v_non_comp_default_id;
		audit_pkg.DeleteNonComplianceDefault(v_non_comp_default_id);
	END IF;
	-- Delete Survey
	IF v_survey_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(v_act_id, v_survey_sid);
		DELETE FROM tempor_question;
		DELETE FROM temp_question_option;
		DELETE FROM temp_question_option_nc_tag;
	END IF;
	-- Delete Flow
	IF v_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(v_act_id, v_flow_sid);
	END IF;	
END;

-- Called once before all tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
		
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('REGION_1');

	v_administrators_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Administrators');
	
	v_users(1) := unit_test_pkg.GetOrCreateUser('USER_1', v_administrators_sid);
	
	enable_pkg.EnableAudit();
	
	enable_pkg.EnableSurveys();
END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	RemoveSids(v_regs);
	RemoveSids(v_users);
	
	IF v_tag_group_id IS NOT NULL THEN 
		tag_pkg.DeleteTagGroup(
			in_act_id			=> v_act_id,
			in_tag_group_id		=> v_tag_group_id
		);
	END IF;

	-- disable_pkg.DisableAudit();
END;

-----------------------------------------
-- TESTS
-----------------------------------------
PROCEDURE TrashAudit
AS
	v_audit_sid 	security.security_pkg.T_SID_ID;
	v_finding_id 	security.security_pkg.T_SID_ID;
	v_issue_id 		security.security_pkg.T_SID_ID;
	v_sid			NUMBER;
	v_deleted		NUMBER;
	v_cnt			NUMBER;
BEGIN	
	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name				=> 'Trash Audit',
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_audit_dtm		=> '01-JAN-2020'
	);
	
	v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(v_audit_sid, 'Finding 1');
	audit_pkg.AddNonComplianceIssue(v_finding_id, 'Issue 1', NULL, NULL, v_users(1), NULL, 0, 0, v_issue_id);
	audit_pkg.AddNonComplianceIssue(v_finding_id, 'Issue 2', NULL, NULL, v_users(1), NULL, 0, 0, v_issue_id);
	
	audit_pkg.TrashAudit(
		in_internal_audit_sid			=> v_audit_sid
	);
	
	SELECT internal_audit_sid, deleted
      INTO v_sid, v_deleted
	  FROM internal_audit ia
	  JOIN trash t ON ia.internal_audit_sid = t.trash_sid
	 WHERE internal_audit_sid = v_audit_sid;	  
	
	unit_test_pkg.AssertAreEqual(v_audit_sid, v_sid, 'Item not in trash');
	unit_test_pkg.AssertAreEqual(1, v_deleted, 'Item not marked deleted');
	
	SELECT SUM(deleted)
	  INTO v_deleted
	  FROM issue	  
	 WHERE issue_non_compliance_id IN (
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
		 WHERE anc.internal_audit_sid = v_audit_sid
	);
	
	unit_test_pkg.AssertAreEqual(2, v_deleted, 'Issues not marked deleted');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM audit_log
	 WHERE object_sid = v_audit_sid
	   AND description LIKE 'Moved to trash:%';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Trash not logged');
	
	security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, v_audit_sid);
END;

PROCEDURE DeleteAudit
AS
	v_l_audit_sid 	security.security_pkg.T_SID_ID;
	v_cnt			NUMBER;
BEGIN
	v_l_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name				=> 'Delete Audit',
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_audit_dtm		=> '01-JAN-2020'
	);
	
	audit_pkg.DeleteAudit(
		in_internal_audit_sid			=> v_l_audit_sid
	);

	SELECT COUNT(*)
      INTO v_cnt
	  FROM internal_audit ia
	 WHERE internal_audit_sid = v_l_audit_sid;	  
	
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Item not deleted');

	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM audit_log
	 WHERE object_sid = v_l_audit_sid
	   AND description LIKE 'Deleted:%';
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Delete not logged');
END;

PROCEDURE TestGetIndLookup
AS
	v_parent_lookup_key		VARCHAR2(100);
	v_prefix				VARCHAR2(100);
	v_lookup_key			VARCHAR2(100);
	v_name					VARCHAR2(100);
	v_expected_result				VARCHAR2(400);
BEGIN
	v_parent_lookup_key:= NULL;
	v_prefix:= NULL;
	v_lookup_key:= NULL;
	v_name:= NULL;
	v_expected_result := NULL;
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');

	v_parent_lookup_key:= 'PLK';
	v_prefix:= NULL;
	v_lookup_key:= NULL;
	v_name:= NULL;
	v_expected_result := 'PLK';
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');

	v_parent_lookup_key:= 'PLK';
	v_prefix:= '_PF';
	v_lookup_key:= NULL;
	v_name:= NULL;
	v_expected_result := 'PLK_PF';
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');

	v_parent_lookup_key:= 'PLK';
	v_prefix:= '_PF_';
	v_lookup_key:= 'LK';
	v_name:= NULL;
	v_expected_result := 'PLK_PF_LK';
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');

	v_parent_lookup_key:= 'PLK';
	v_prefix:= NULL;
	v_lookup_key:= 'LK';
	v_name:= 'name';
	v_expected_result := 'PLKLK';
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');

	v_parent_lookup_key:= 'PLK';
	v_prefix:= '_PF_';
	v_lookup_key:= 'LK';
	v_name:= 'name';
	v_expected_result := 'PLK_PF_LK';
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');

	v_parent_lookup_key:= 'PLK';
	v_prefix:= '_PF_';
	v_lookup_key:= NULL;
	v_name:= 'name';
	v_expected_result := 'PLK_PF_name';
	unit_test_pkg.AssertAreEqual(audit_pkg.GetIndLookup(v_parent_lookup_key, v_prefix, v_lookup_key, v_name), v_expected_result, 'Not matched');
END;

PROCEDURE AuditorNameGetsSetWhenNull
AS
	v_l_audit_sid 		security.security_pkg.T_SID_ID;
	v_auditor_name		VARCHAR2(100);
BEGIN
	v_l_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name				=> 'Auditor Name Audit',
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_audit_dtm		=> '01-JAN-2020'
	);

	SELECT auditor_name
	  INTO v_auditor_name
	  FROM csr.internal_audit
	 WHERE internal_audit_sid = v_l_audit_sid;
	 
	unit_test_pkg.AssertAreEqual(v_auditor_name, 'USER_1', 'Auditor name not equal.');
END;

PROCEDURE TagsAreCreatedForNewDefaultFindingsFromReadOnlyUser
AS
	v_cnt 						security.security_pkg.T_SID_ID;	
	v_new_file_uploads			audit_pkg.T_CACHE_KEYS;
	v_out_cur					SYS_REFCURSOR;
	v_sids						security.security_pkg.T_SID_IDS;
BEGIN
	v_tag_ids(1) := v_tag_id;
	
	audit_pkg.SaveNonCompliance(
		in_non_compliance_id		=> NULL,
		in_region_sid				=> v_regs(1),
		in_internal_audit_sid		=> v_audit_sid,
		in_from_non_comp_default_id	=> v_non_comp_default_id,
		in_label					=> 'DEFAULT_SURVEY',
		in_detail					=> 'Detail',
		in_non_compliance_type_id	=> v_non_comp_type_id,
		in_is_closed				=> 0,
		in_current_file_uploads		=> v_sids,
		in_new_file_uploads			=> v_new_file_uploads,
		in_tag_ids					=> v_tag_ids,
		in_question_id				=> NULL,
		in_question_option_id		=> NULL,
		out_nc_cur					=> v_out_cur,
		out_nc_upload_cur			=> v_out_cur,
		out_nc_tag_cur				=> v_out_cur
	);
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM non_compliance nc
	  JOIN non_compliance_tag nct ON nc.non_compliance_id = nct.non_compliance_id
	 WHERE nct.tag_id = v_tag_id
	   AND nc.label = 'DEFAULT_SURVEY';
	   
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Default finding tag not created.');	
END;

PROCEDURE TagsAreCreatedForNewDefaultFindingsForDefaultSurveyFromReadOnlyUser
AS
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_question_id 				security.security_pkg.T_SID_ID;
	v_question_option_id 		security.security_pkg.T_SID_ID;
	v_cnt 						security.security_pkg.T_SID_ID;
	v_sids						security.security_pkg.T_SID_IDS;
	v_new_file_uploads			audit_pkg.T_CACHE_KEYS;
	v_out_cur					SYS_REFCURSOR;
BEGIN
	audit_pkg.SetDefaultSurvey(
		in_internal_audit_type_id 	=> v_internal_audit_type_id,
		in_default_survey_sid 		=> v_survey_sid
	);
	
	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name				=> 'Flow Audit',
		in_flow_sid			=> v_flow_sid,
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_survey_sid		=> v_survey_sid,
		in_audit_type_name	=> 'AUDIT_TYPE_WITH_FLOW',
		in_audit_dtm		=> '01-JAN-2020'
	);
	
	-- Act	
	SELECT q.question_id, qo.question_option_id
	  INTO v_question_id, v_question_option_id
	  FROM question q
	  JOIN question_option qo ON q.question_id = qo.question_id
	 WHERE owned_by_survey_sid = v_survey_sid
	   AND qo.lookup_key = 'DB_TEST_YES'
	   AND qo.question_version = 1;
	
	audit_pkg.SaveNonCompliance(
		in_non_compliance_id		=> NULL,
		in_region_sid				=> v_regs(1),
		in_internal_audit_sid		=> v_audit_sid,
		in_from_non_comp_default_id	=> v_non_comp_default_id,
		in_label					=> 'DEFAULT_SURVEY',
		in_detail					=> 'Detail',
		in_non_compliance_type_id	=> v_non_comp_type_id,
		in_is_closed				=> 0,
		in_current_file_uploads		=> v_sids,
		in_new_file_uploads			=> v_new_file_uploads,
		in_tag_ids					=> v_tag_ids,
		in_question_id				=> v_question_id,
		in_question_option_id		=> v_question_option_id,
		out_nc_cur					=> v_out_cur,
		out_nc_upload_cur			=> v_out_cur,
		out_nc_tag_cur				=> v_out_cur
	);
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM non_compliance nc
	  JOIN non_compliance_tag nct ON nc.non_compliance_id = nct.non_compliance_id
	 WHERE nct.tag_id = v_tag_id
	   AND nc.label = 'DEFAULT_SURVEY';
	   
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Default finding tag not created.');
END;

PROCEDURE TagsAreCreatedForNewDefaultFindingsForSurveyFromReadOnlyUser
AS
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_question_id 				security.security_pkg.T_SID_ID;
	v_question_option_id 		security.security_pkg.T_SID_ID;
	v_cnt 						security.security_pkg.T_SID_ID;
	v_sids						security.security_pkg.T_SID_IDS;
	v_new_file_uploads			audit_pkg.T_CACHE_KEYS;
	v_out_cur					SYS_REFCURSOR;
	v_ia_type_survey_id			security.security_pkg.T_SID_ID;
BEGIN
	enable_pkg.EnableMultipleAuditSurveys;
	
	audit_pkg.SetAuditTypeSurvey(
		in_internal_audit_type_id		=> v_internal_audit_type_id,
		in_ia_type_survey_id			=> NULL,
		in_active						=> 1,
		in_label						=> 'Label',
		in_ia_type_survey_group_id		=> NULL,
		in_default_survey_sid			=> v_survey_sid,
		in_mandatory					=> 0,
		in_survey_fixed					=> 0,
		in_survey_group_key				=> NULL,
		out_ia_type_survey_id			=> v_ia_type_survey_id
	);
	
	-- CREATE AUDIT
	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name				=> 'Flow Audit',
		in_flow_sid			=> v_flow_sid,
		in_region_sid		=> v_regs(1),
		in_user_sid			=> v_users(1),
		in_survey_sid		=> v_survey_sid,
		in_audit_type_name	=> 'AUDIT_TYPE_WITH_FLOW',
		in_audit_dtm		=> '01-JAN-2020'
	);
	
	-- Act
	SELECT q.question_id, qo.question_option_id
	  INTO v_question_id, v_question_option_id
	  FROM question q
	  JOIN question_option qo ON q.question_id = qo.question_id
	 WHERE owned_by_survey_sid = v_survey_sid
	   AND qo.lookup_key = 'DB_TEST_YES'
	   AND qo.question_version = 1;
	
	v_tag_ids(1) := v_tag_id;
	
	audit_pkg.SaveNonCompliance(
		in_non_compliance_id		=> NULL,
		in_region_sid				=> v_regs(1),
		in_internal_audit_sid		=> v_audit_sid,
		in_from_non_comp_default_id	=> v_non_comp_default_id,
		in_label					=> 'DEFAULT_SURVEY',
		in_detail					=> 'Detail',
		in_non_compliance_type_id	=> v_non_comp_type_id,
		in_is_closed				=> 0,
		in_current_file_uploads		=> v_sids,
		in_new_file_uploads			=> v_new_file_uploads,
		in_tag_ids					=> v_tag_ids,
		in_question_id				=> v_question_id,
		in_question_option_id		=> v_question_option_id,
		out_nc_cur					=> v_out_cur,
		out_nc_upload_cur			=> v_out_cur,
		out_nc_tag_cur				=> v_out_cur
	);
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM non_compliance nc
	  JOIN non_compliance_tag nct ON nc.non_compliance_id = nct.non_compliance_id
	 WHERE nct.tag_id = v_tag_id
	   AND nc.label = 'DEFAULT_SURVEY';
	   
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Default finding tag not created.');
END;

END;
/