CREATE OR REPLACE PACKAGE BODY csr.test_user_cover_pkg AS

v_site_name				VARCHAR2(200);
v_region_1_sid			security.security_pkg.T_SID_ID;
v_region_1_1_sid		security.security_pkg.T_SID_ID;
v_region_1_1_1_sid		security.security_pkg.T_SID_ID;
v_ind_1_sid				security.security_pkg.T_SID_ID;
v_user_1_sid			security.security_pkg.T_SID_ID;
v_user_2_sid			security.security_pkg.T_SID_ID;
v_user_cover_1_sid		security.security_pkg.T_SID_ID;
v_user_cover_2_sid		security.security_pkg.T_SID_ID;
v_deleg_1_sid			security.security_pkg.T_SID_ID;
v_audit_1_sid			security.security_pkg.T_SID_ID;
v_audit_2_sid			security.security_pkg.T_SID_ID;
v_group_1_sid			security.security_pkg.T_SID_ID;
v_role_1_sid			security.security_pkg.T_SID_ID;
v_audit_flow_sid		security.security_pkg.T_SID_ID;

v_flow_inv_type_id		NUMBER(10);
v_flow_item_id			NUMBER(10);
v_audit_3_sid			security.security_pkg.T_SID_ID;
v_audit_inv_user_1_sid	security.security_pkg.T_SID_ID;
v_audit_inv_user_2_sid	security.security_pkg.T_SID_ID;
v_audit_inv_user_3_sid	security.security_pkg.T_SID_ID;

-- Private
PROCEDURE CreateAuditWorkflow_
AS
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_xml					CLOB;
	v_str					VARCHAR2(2000);
BEGIN
	v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
	csr.flow_pkg.CreateFlow('UNIT_TEST_WF', v_wf_ct_sid, 'audit', v_audit_flow_sid);
	v_xml := '<';
	v_str := UNISTR('flow label="UNIT_TEST_WF" cmsTabSid="" default-state-id="$S0$"><state id="$S0$" label="Draft" final="0" colour="" lookup-key="DRAFT"><attributes x="750.5" y="884" /><transition to-state-id="$S1$" verb="Close" helper-sp="" lookup-key="CLOSE" ask-for-comment="optional" mandatory-fields-message="" button-icon-path="" /></state><state id="$S1$" label="Closed" final="0" colour="" lookup-key="CLOSED"><attributes x="918.5" y="884" /></state></flow>');
	dbms_lob.writeappend(v_xml, LENGTH(v_str), v_str);
	v_xml := REPLACE(v_xml, '$S0$', NVL(csr.flow_pkg.GetStateId(v_audit_flow_sid, 'DRAFT'), csr.flow_pkg.GetNextStateID));
	v_xml := REPLACE(v_xml, '$S1$', NVL(csr.flow_pkg.GetStateId(v_audit_flow_sid, 'CLOSED'), csr.flow_pkg.GetNextStateID));
	csr.flow_pkg.SetFlowFromXml(v_audit_flow_sid, XMLType(v_xml));
	
	INSERT INTO csr.flow_state_involvement (flow_state_id, flow_involvement_type_id)
	VALUES(csr.flow_pkg.GetStateId(v_audit_flow_sid, 'DRAFT'), csr.csr_data_pkg.FLOW_INV_TYPE_AUDITOR);
	
	INSERT INTO csr.flow_state_involvement (flow_state_id, flow_involvement_type_id)
	VALUES(csr.flow_pkg.GetStateId(v_audit_flow_sid, 'CLOSED'), csr.csr_data_pkg.FLOW_INV_TYPE_AUDITOR);
	
	INSERT INTO csr.flow_state_transition_inv (flow_state_transition_id, from_state_id, flow_involvement_type_id)
	SELECT flow_state_transition_id, from_state_id, csr.csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	  FROM csr.flow_state_transition
	 WHERE flow_sid = v_audit_flow_sid
	   AND lookup_key='CLOSE';
	
	INSERT INTO csr.flow_state_role_capability (flow_state_rl_cap_id, flow_state_id,
		   flow_capability_id, flow_involvement_type_id, permission_set)
	VALUES (flow_state_rl_cap_id_seq.nextval, csr.flow_pkg.GetStateId(v_audit_flow_sid, 'DRAFT'),
		   csr.csr_data_pkg.FLOW_CAP_AUDIT, csr.csr_data_pkg.FLOW_INV_TYPE_AUDITOR,
		   security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	
	INSERT INTO csr.flow_state_role_capability (flow_state_rl_cap_id, flow_state_id,
		   flow_capability_id, flow_involvement_type_id, permission_set)
	VALUES (flow_state_rl_cap_id_seq.nextval, csr.flow_pkg.GetStateId(v_audit_flow_sid, 'CLOSED'),
		   csr.csr_data_pkg.FLOW_CAP_AUDIT, csr.csr_data_pkg.FLOW_INV_TYPE_AUDITOR,
		   security.security_pkg.PERMISSION_READ);
	
END;


PROCEDURE SimpleDelegationCover
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_act				security_pkg.T_ACT_ID;
BEGIN
	csr.delegation_pkg.UNSEC_AddUser(security_pkg.GetAct, v_deleg_1_sid, v_user_1_sid);
	
	-- log on as cover user - but we don't want to set the security context
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_user_cover_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	
	IF delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		csr.unit_test_pkg.TestFail('Cover user has access to delegation before cover has started');
	END IF;
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$delegation_user
	 WHERE delegation_sid = v_deleg_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User was not added to v$delegation_user view');
	
	-- re log on as cover user (as their groups have changed)
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	IF NOT delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		csr.unit_test_pkg.TestFail('Cover user does not have access to delegation');
	END IF;
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$delegation_user
	 WHERE delegation_sid = v_deleg_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'User was not removed from delegation_user table');
	
	-- re log on as cover user (as their groups have changed)
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	IF delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		csr.unit_test_pkg.TestFail('Cover user still has access to delegation after cover is over');
	END IF;
END;

PROCEDURE DelegationCoverViaARole
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_act				security_pkg.T_ACT_ID;
BEGIN
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_region_1_1_sid, v_user_1_sid);
	csr.delegation_pkg.UNSEC_AddRole(security_pkg.GetAct, v_deleg_1_sid, v_role_1_sid);
	
	-- log on as cover user - but we don't want to set the security context
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_user_cover_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	
	IF delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		csr.unit_test_pkg.TestFail('Cover user has access to delegation before cover has started');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$delegation_user
	 WHERE delegation_sid = v_deleg_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'User was in v$delegation_user view before cover started');
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$delegation_user
	 WHERE delegation_sid = v_deleg_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User was not added to delegation_user table');
	
	-- re log on as cover user (as their groups have changed)
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	IF NOT delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		csr.unit_test_pkg.TestFail('Cover user does not have access to delegation');
	END IF;
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.v$delegation_user
	 WHERE delegation_sid = v_deleg_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'User was removed from delegation_user table');
	
	-- re log on as cover user (as their groups have changed)
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	IF delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		csr.unit_test_pkg.TestFail('Cover user still has access to delegation after cover is over');
	END IF;
END;

PROCEDURE AuditCoverReplaceAuditorName
AS
	v_auditor			VARCHAR2(255);
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT auditor_full_name
	  INTO v_auditor
	  FROM v$audit
	 WHERE internal_audit_sid = v_audit_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual('USER_COVER_1', v_auditor, 'Cover user did not become the audit co-ordinator');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT auditor_full_name
	  INTO v_auditor
	  FROM v$audit
	 WHERE internal_audit_sid = v_audit_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual('USER_1', v_auditor, 'Original auditor was not restored as the audit co-ordinator');
END;

PROCEDURE AuditCover2UsrsCvringSameUser
AS
	v_auditor			VARCHAR2(255);
	v_cover_id_1		NUMBER(10);
	v_cover_id_2		NUMBER(10);
	v_count				NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	csr.unit_test_pkg.StartTest('csr.test_user_cover_pkg.AuditCoverTwoUsersCoveringSameUser'); -- More meaningful name
	
	v_user_cover_2_sid := csr.unit_test_pkg.GetOrCreateUser('USER_COVER_2');
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-2, null, v_cover_id_1);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_1, v_cur);
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_2_sid, sysdate-1, null, v_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT auditor_full_name
	  INTO v_auditor
	  FROM v$audit
	 WHERE internal_audit_sid = v_audit_1_sid;
	
	-- Expect more recent cover user to be the cover user in the view (as audits can only have 1 auditor)
	csr.unit_test_pkg.AssertAreEqual('USER_COVER_2', v_auditor, 'Cover user did not become the audit co-ordinator');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_1, sysdate-2, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_1);
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_2, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_2);
	
	SELECT auditor_full_name
	  INTO v_auditor
	  FROM v$audit
	 WHERE internal_audit_sid = v_audit_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual('USER_1', v_auditor, 'Original auditor was not restored as the audit co-ordinator');
END;

PROCEDURE AuditCoverOfCoverDntRplAdtrNm
AS
	v_auditor			VARCHAR2(255);
	v_cover_id_1		NUMBER(10);
	v_cover_id_2		NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	csr.unit_test_pkg.StartTest('csr.test_user_cover_pkg.AuditCoverOfCoverShouldntReplaceAuditorName'); -- More meaningful name
	
	v_user_cover_2_sid := csr.unit_test_pkg.GetOrCreateUser('USER_COVER_2');
	
	-- Add + start the user covers
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-2, null, v_cover_id_1);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_1, v_cur);
	csr.user_cover_pkg.AddUserCover(v_user_cover_1_sid, v_user_cover_2_sid, sysdate-1, null, v_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT auditor_full_name
	  INTO v_auditor
	  FROM v$audit
	 WHERE internal_audit_sid = v_audit_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual('USER_COVER_1', v_auditor, 'Cover user did not become the audit co-ordinator');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_1, sysdate-2, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_1);
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_2, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_2);
	
	SELECT auditor_full_name
	  INTO v_auditor
	  FROM v$audit
	 WHERE internal_audit_sid = v_audit_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual('USER_1', v_auditor, 'Original auditor was not restored as the audit co-ordinator');
END;

PROCEDURE AuditCoverAddToInvolvedIss
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_nc_id				NUMBER(10);
	v_issue_id			NUMBER(10);
	v_count				NUMBER(10);
BEGIN
	csr.unit_test_pkg.StartTest('csr.test_user_cover_pkg.AuditCoverAddUserAsInvolvedOnIssues'); -- More meaningful name
	
	security_pkg.SetContext('SID', v_user_1_sid);
	v_nc_id := csr.unit_test_pkg.GetOrCreateNonComplianceId(v_audit_1_sid, 'NON_COMPLIANCE_1');
	audit_pkg.AddNonComplianceIssue(
		in_non_compliance_id	=> v_nc_id,
		in_label				=> 'NON_COMP_ACTION_1',
		in_description			=> 'Description for NON_COMP_ACTION_1',
		out_issue_id			=> v_issue_id
	);
	security_pkg.SetContext('SID', NULL);
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT count(*)
	  INTO v_count
	  FROM issue_involvement
	 WHERE issue_id = v_issue_id
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not become involved in the audit''s issues');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT count(*)
	  INTO v_count
	  FROM issue_involvement
	 WHERE issue_id = v_issue_id
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not become remain involved in the audit''s issues after cover ended');
END;

PROCEDURE AuditCoverDontAddToClosdIss
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_nc_id				NUMBER(10);
	v_issue_id			NUMBER(10);
	v_count				NUMBER(10);
BEGIN
	csr.unit_test_pkg.StartTest('csr.test_user_cover_pkg.AuditCoverDontAddUserToClosedIssues'); -- More meaningful name
	
	security_pkg.SetContext('SID', v_user_1_sid);
	v_nc_id := csr.unit_test_pkg.GetOrCreateNonComplianceId(v_audit_1_sid, 'NON_COMPLIANCE_1');
	audit_pkg.AddNonComplianceIssue(
		in_non_compliance_id	=> v_nc_id,
		in_label				=> 'NON_COMP_ACTION_1',
		in_description			=> 'Description for NON_COMP_ACTION_1',
		out_issue_id			=> v_issue_id
	);	
	security_pkg.SetContext('SID', 3); -- be built-in admin to close the issue
	issue_pkg.MarkAsClosed(security_pkg.getact, v_issue_id, ' ', NULL, NULL, v_cur, v_cur);
	security_pkg.SetContext('SID', NULL);
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT count(*)
	  INTO v_count
	  FROM issue_involvement
	 WHERE issue_id = v_issue_id
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user became involved in the audit''s closed issues');
	
END;

PROCEDURE AuditCoverChangeIssueOwner
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_nc_id				NUMBER(10);
	v_issue_id			NUMBER(10);
	v_owner_sid			NUMBER(10);
BEGIN
	security_pkg.SetContext('SID', v_user_1_sid);
	v_nc_id := csr.unit_test_pkg.GetOrCreateNonComplianceId(v_audit_1_sid, 'NON_COMPLIANCE_1');
	audit_pkg.AddNonComplianceIssue(
		in_non_compliance_id	=> v_nc_id,
		in_label				=> 'NON_COMP_ACTION_1',
		in_description			=> 'Description for NON_COMP_ACTION_1',
		out_issue_id			=> v_issue_id
	);
	security_pkg.SetContext('SID', NULL);
	
	SELECT owner_user_sid
	  INTO v_owner_sid
	  FROM V$issue
	 WHERE issue_id = v_issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'Original user was not owner of the audit''s issues before cover started');
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT owner_user_sid
	  INTO v_owner_sid
	  FROM V$issue
	 WHERE issue_id = v_issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_cover_1_sid, v_owner_sid, 'Cover user did not become owner of the audit''s issues');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT owner_user_sid
	  INTO v_owner_sid
	  FROM V$issue
	 WHERE issue_id = v_issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'Original user did not be restored as the audit''s issues'' owner after cover ended');
END;

PROCEDURE AuditCoverKeepIssueOwner
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_nc_id				NUMBER(10);
	v_issue_id			NUMBER(10);
	v_count				NUMBER(10);
BEGIN
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	security_pkg.SetContext('SID', v_user_cover_1_sid);
	v_nc_id := csr.unit_test_pkg.GetOrCreateNonComplianceId(v_audit_1_sid, 'NON_COMPLIANCE_1');
	audit_pkg.AddNonComplianceIssue(
		in_non_compliance_id	=> v_nc_id,
		in_label				=> 'NON_COMP_ACTION_1',
		in_description			=> 'Description for NON_COMP_ACTION_1',
		out_issue_id			=> v_issue_id
	);
	security_pkg.SetContext('SID', NULL);
	
	SELECT count(*)
	  INTO v_count
	  FROM V$issue
	 WHERE issue_id = v_issue_id
	   AND owner_user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not start as the owner of the audit''s new issue');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT count(*)
	  INTO v_count
	  FROM V$issue
	 WHERE issue_id = v_issue_id
	   AND owner_user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not remain owner of an issue they created on an audit');
END;

PROCEDURE AuditCoverInvolvedUser
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_act_user_1		security.security_pkg.T_ACT_ID := security.user_pkg.GenerateACT();
	v_act_cover_user_1	security.security_pkg.T_ACT_ID := security.user_pkg.GenerateACT();
	v_original_act		security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	security.act_pkg.Issue(v_user_1_sid, v_act_user_1, 3600, SYS_CONTEXT('SECURITY','APP'));
	security.act_pkg.Issue(v_user_cover_1_sid, v_act_cover_user_1, 3600, SYS_CONTEXT('SECURITY','APP'));
	
	security.security_pkg.SetContext('SID', v_user_1_sid);
	security.security_pkg.SetContext('ACT', v_act_user_1);
	csr.unit_test_pkg.AssertIsTrue(
		csr.audit_pkg.HasCapabilityAccess(v_audit_2_sid, csr.csr_data_pkg.FLOW_CAP_AUDIT, security.security_pkg.PERMISSION_WRITE),
		'User to be covered does not have write access before cover begins');
	
	security.security_pkg.SetContext('SID', v_user_cover_1_sid);
	security.security_pkg.SetContext('ACT', v_act_cover_user_1);
	csr.unit_test_pkg.AssertIsFalse(
		csr.audit_pkg.HasCapabilityAccess(v_audit_2_sid, csr.csr_data_pkg.FLOW_CAP_AUDIT, security.security_pkg.PERMISSION_WRITE),
		'Cover user has write access before cover begins');
	
	-- Add + start the user cover
	security.security_pkg.SetContext('ACT', v_original_act);
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	security.security_pkg.SetContext('SID', v_user_1_sid);
	security.security_pkg.SetContext('ACT', v_act_user_1);
	csr.unit_test_pkg.AssertIsTrue(
		csr.audit_pkg.HasCapabilityAccess(v_audit_2_sid, csr.csr_data_pkg.FLOW_CAP_AUDIT, security.security_pkg.PERMISSION_WRITE),
		'User being covered does not have write access after cover started');
	
	security.security_pkg.SetContext('SID', v_user_cover_1_sid);
	security.security_pkg.SetContext('ACT', v_act_cover_user_1);
	csr.unit_test_pkg.AssertIsTrue(
		csr.audit_pkg.HasCapabilityAccess(v_audit_2_sid, csr.csr_data_pkg.FLOW_CAP_AUDIT, security.security_pkg.PERMISSION_WRITE),
		'Cover user does not have write access after cover started');
	
	-- End cover
	security.security_pkg.SetContext('ACT', v_original_act);
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	security.security_pkg.SetContext('SID', v_user_cover_1_sid);
	security.security_pkg.SetContext('ACT', v_act_cover_user_1);
	csr.unit_test_pkg.AssertIsFalse(
		csr.audit_pkg.HasCapabilityAccess(v_audit_2_sid, csr.csr_data_pkg.FLOW_CAP_AUDIT, security.security_pkg.PERMISSION_WRITE),
		'Cover user has write access after cover finished');
	
END;

PROCEDURE GroupCoverNewGroup
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have group after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user did not lose group after cover ended');
END;

PROCEDURE GroupCoverExistingGroup
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	security.group_pkg.AddMember(security_pkg.getAct, v_user_cover_1_sid, v_group_1_sid);
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have group after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not retain group after cover ended');
END;

PROCEDURE GroupCoverExistingCover
AS
	v_cover_id			NUMBER(10);
	v_cover_id_2		NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	v_user_cover_2_sid := csr.unit_test_pkg.GetOrCreateUser('USER_COVER_2');
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.AddUserCover(v_user_cover_1_sid, v_user_cover_2_sid, sysdate-1, null, v_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_2_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user 2 should not have group after cover started');
END;

PROCEDURE GroupCoverSameGroupFrom2Users
AS
	v_cover_id_1		NUMBER(10);
	v_cover_id_2		NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	v_user_2_sid := csr.unit_test_pkg.GetOrCreateUser('USER_2');
	security.group_pkg.AddMember(security_pkg.getAct, v_user_2_sid, v_group_1_sid);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user should not have group before cover started');
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id_1);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_1, v_cur);
	csr.user_cover_pkg.AddUserCover(v_user_2_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have group after cover started');
	
	-- End first cover, keep second cover
	-- This assumes second cover will be refreshed after first cover is terminated
	-- This is how the scheduled task works now - but there isn't a unit test to check
	-- that is always the case
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_1, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_1);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user should still have group after first cover ended but before second cover ended');
	
	-- End second cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_2, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_2);
	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user did not lose group after all covers ended');
END;

PROCEDURE GroupCoverGroupRemovedAfter
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have group after cover started');
	
	-- Remove group manually and refresh
	security.group_pkg.DeleteMember(security_pkg.getAct, v_user_cover_1_sid, v_group_1_sid);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user regained group after cover was refreshed following being removed manually');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_group_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user did not lose group after cover ended');
END;

PROCEDURE FlowInvCoverNew
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_1_sid, v_audit_inv_user_2_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_2_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user was not involved in audit after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_2_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user involvement was not removed after cover ended');
END;

PROCEDURE FlowInvCoverExistingCover
AS
	v_cover_id			NUMBER(10);
	v_cover_cover_id	NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_1_sid, v_audit_inv_user_2_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_2_sid, v_audit_inv_user_3_sid, sysdate-1, null, v_cover_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id, v_cur);	
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_3_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user was not involved in audit after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id, v_cur);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_3_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user involvement was not removed after cover ended');
END;

PROCEDURE FlowInvCoverSurvivesHistoricCover
AS
	v_cover_id			NUMBER(10);
	v_cover_cover_id	NUMBER(10);
	v_cover_cover_id_2	NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_1_sid, v_audit_inv_user_2_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_2_sid, v_audit_inv_user_3_sid, sysdate-1, null, v_cover_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id, v_cur);	
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id, v_cur);
	
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_3_sid, v_audit_inv_user_1_sid, sysdate-1, null, v_cover_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id_2, v_cur);	
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_cover_id_2, v_cur);
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	-- Passed! This is just testing the cycle doesn't mess up when presented with a cycle
END;

PROCEDURE FlowInvCoverAlreadyInvolved
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	INSERT INTO flow_item_involvement(flow_involvement_type_id, flow_item_id, user_sid)
	VALUES (v_flow_inv_type_id, v_flow_item_id, v_audit_inv_user_2_sid);
	
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_1_sid, v_audit_inv_user_2_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_2_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user was not involved in audit after cover started');
	   
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_2_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user should still be involved after cover ended because they were also involved prior to cover.');	
END;

PROCEDURE FlowInvCoverManuallyRemove
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN	
	csr.user_cover_pkg.AddUserCover(v_audit_inv_user_1_sid, v_audit_inv_user_2_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	DELETE FROM flow_item_involvement
	 WHERE flow_involvement_type_id = v_flow_inv_type_id
	   AND flow_item_id = v_flow_item_id
	   AND user_sid = v_audit_inv_user_2_sid;
	   
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);	   
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);	  
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item_involvement
	 WHERE flow_item_id = v_flow_item_id
	   AND flow_involvement_type_id = v_flow_inv_type_id
	   AND user_sid = v_audit_inv_user_2_sid;	   
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user was manually removed so should not be re-added when cover is refreshed.');	   
	
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
END;


PROCEDURE RoleCoverNewRole
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have role after cover started');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_role_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have get added to role as a group');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user did not remove role after cover ended');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_role_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user should not have get retained the role as a group');
END;

PROCEDURE RoleCoverExistingRole
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_region_1_1_sid, v_user_cover_1_sid);
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have role after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not retain role after cover ended');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_role_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user should have retained the role as a group');
END;

PROCEDURE RoleCoverExistingParentRole
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_region_1_sid, v_user_cover_1_sid);
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have role after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not retain role after cover ended');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_role_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user should have retained the role as a group');
END;

PROCEDURE RoleCoverExistingChildRole
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_region_1_1_1_sid, v_user_cover_1_sid);
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not have role after cover started');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user did not retain existing role after cover ended');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover user still retains role after cover ended');
	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_1_sid)) t
	 WHERE t.sid_id = v_role_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cover user should have retained the role as a group');
END;

PROCEDURE RoleCoverExistingCover
AS
	v_cover_id			NUMBER(10);
	v_cover_id_2		NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
BEGIN
	v_user_cover_2_sid := csr.unit_test_pkg.GetOrCreateUser('USER_COVER_2');
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	csr.user_cover_pkg.AddUserCover(v_user_cover_1_sid, v_user_cover_2_sid, sysdate-1, null, v_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_role_member rrm
	 WHERE rrm.role_sid = v_role_1_sid
	   AND region_sid = v_region_1_1_sid
	   AND user_sid = v_user_cover_2_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover of cover user should not have role after cover started');
	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(security.group_pkg.GetGroupsForMemberAsTable(security_pkg.getact, v_user_cover_2_sid)) t
	 WHERE t.sid_id = v_role_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover of cover user should not have gained the role as a group');
END;

PROCEDURE IssueCoverNewIssue
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_count2			NUMBER(10);
	v_issue_id			NUMBER(10);
	v_owner_sid			NUMBER(10);
BEGIN
	issue_pkg.CreateIssue (
		in_label => 'ISSUE TEST 1',
		in_source_label => '?',
		in_issue_type_id => csr.csr_data_pkg.ISSUE_CMS,
		in_correspondent_id => NULL,
		in_raised_by_user_sid => v_user_1_sid,
		in_assigned_to_user_sid => v_user_1_sid,
		in_assigned_to_role_sid => NULL,
		in_due_dtm => NULL,
		out_issue_id => v_issue_id
	);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue before cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(0, v_count2, 'Cover user should not be involved before cover starts');
	
	security_pkg.SetContext('SID', v_user_1_sid);	
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_cover_1_sid, v_owner_sid, 'Cover User should be owner of issue after cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should be involved after cover starts');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue after cover ends');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should still be involved after cover ends?');
	
	issue_pkg.UNSEC_DeleteIssue(v_issue_id);
END;

PROCEDURE IssueCoverExistingIssue
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_count2			NUMBER(10);
	v_issue_id			NUMBER(10);
	v_owner_sid			NUMBER(10);
BEGIN
	issue_pkg.CreateIssue (
		in_label => 'ISSUE TEST 1',
		in_source_label => '?',
		in_issue_type_id => csr.csr_data_pkg.ISSUE_CMS,
		in_correspondent_id => NULL,
		in_raised_by_user_sid => v_user_1_sid,
		in_assigned_to_user_sid => v_user_1_sid,
		in_assigned_to_role_sid => NULL,
		in_due_dtm => NULL,
		out_issue_id => v_issue_id
	);
	
	security_pkg.SetContext('SID', v_user_1_sid);	
	issue_pkg.AddUser(security_pkg.GetAct, v_issue_id, v_user_cover_1_sid, v_cur);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue before cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should be involved througout');
	
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_cover_1_sid, v_owner_sid, 'Cover User should be owner of issue after cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should be involved througout');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue after cover ends');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should be involved througout');
	
	issue_pkg.UNSEC_DeleteIssue(v_issue_id);
END;

PROCEDURE IssueCoverExistingCover
AS
	v_cover_id_1		NUMBER(10);
	v_cover_id_2		NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_count2			NUMBER(10);
	v_count3			NUMBER(10);
	v_issue_id			NUMBER(10);
	v_owner_sid			NUMBER(10);
BEGIN
	issue_pkg.CreateIssue (
		in_label => 'ISSUE TEST 1',
		in_source_label => '?',
		in_issue_type_id => csr.csr_data_pkg.ISSUE_CMS,
		in_correspondent_id => NULL,
		in_raised_by_user_sid => v_user_1_sid,
		in_assigned_to_user_sid => v_user_1_sid,
		in_assigned_to_role_sid => NULL,
		in_due_dtm => NULL,
		out_issue_id => v_issue_id
	);
	
	v_user_cover_2_sid := csr.unit_test_pkg.GetOrCreateUser('USER_COVER_2');
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_2_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2, v_count3
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue before cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(0, v_count2, 'Cover user should not be involved before cover starts');
	csr.unit_test_pkg.AssertAreEqual(0, v_count3, 'Cover of cover user should not be involved throughout');

	security_pkg.SetContext('SID', v_user_1_sid);	
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-2, null, v_cover_id_1);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_1, v_cur);
	csr.user_cover_pkg.AddUserCover(v_user_cover_1_sid, v_user_cover_2_sid, sysdate-1, null, v_cover_id_2);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id_2, v_cur);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_2_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2, v_count3
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_cover_1_sid, v_owner_sid, 'Cover User should be owner of issue after cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should be involved after cover starts');
	csr.unit_test_pkg.AssertAreEqual(0, v_count3, 'Cover of cover user should not be involved throughout');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_1, sysdate-2, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_1);
	csr.user_cover_pkg.UpdateUserCover(v_cover_id_2, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id_2);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_2_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2, v_count3
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue after cover ends');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should still be involved after cover ends?');
	csr.unit_test_pkg.AssertAreEqual(0, v_count3, 'Cover of cover user should not be involved throughout');
	
	issue_pkg.UNSEC_DeleteIssue(v_issue_id);
END;

PROCEDURE IssueCoverUserRemovedAfter
AS
	v_cover_id			NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_count				NUMBER(10);
	v_count2			NUMBER(10);
	v_issue_id			NUMBER(10);
	v_owner_sid			NUMBER(10);
BEGIN
	issue_pkg.CreateIssue (
		in_label => 'ISSUE TEST 1',
		in_source_label => '?',
		in_issue_type_id => csr.csr_data_pkg.ISSUE_CMS,
		in_correspondent_id => NULL,
		in_raised_by_user_sid => v_user_1_sid,
		in_assigned_to_user_sid => v_user_1_sid,
		in_assigned_to_role_sid => NULL,
		in_due_dtm => NULL,
		out_issue_id => v_issue_id
	);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue before cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(0, v_count2, 'Cover user should not be involved before cover starts');
	
	security_pkg.SetContext('SID', v_user_1_sid);	
	
	-- Add + start the user cover
	csr.user_cover_pkg.AddUserCover(v_user_1_sid, v_user_cover_1_sid, sysdate-1, null, v_cover_id);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_cover_1_sid, v_owner_sid, 'Cover User should be owner of issue after cover starts');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(1, v_count2, 'Cover user should be involved after cover starts');
	
	csr.issue_pkg.removeuser(security.security_pkg.getact, v_issue_id, v_user_cover_1_sid);
	csr.user_cover_pkg.StartOrRefreshCover(v_cover_id, v_cur);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM issue_involvement ii
	 WHERE ii.issue_id = v_issue_id
	   AND user_sid = v_user_cover_1_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Cover User should not be re-involved');
	
	-- End cover
	csr.user_cover_pkg.UpdateUserCover(v_cover_id, sysdate-1, sysdate-1);
	csr.user_cover_pkg.FullyEndCover(v_cover_id);
	
	SELECT i.owner_user_sid, COUNT(CASE WHEN ii.user_sid = v_user_1_sid THEN 1 END),
		   COUNT(CASE WHEN ii.user_sid = v_user_cover_1_sid THEN 1 END)
	  INTO v_owner_sid, v_count, v_count2
	  FROM issue i
	  JOIN issue_involvement ii ON i.issue_id = ii.issue_id
	 WHERE i.issue_id = v_issue_id
	 GROUP BY i.owner_user_sid, i.issue_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_user_1_sid, v_owner_sid, 'User should be owner of issue after cover ends');
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'User should be involved througout');
	csr.unit_test_pkg.AssertAreEqual(0, v_count2, 'Cover User should not be re-involved');
	
	issue_pkg.UNSEC_DeleteIssue(v_issue_id);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	-- From tab_pkg.CreateIssueTable
	begin
		insert into issue_type
			(issue_type_id, label)
		values
			(csr_data_pkg.ISSUE_CMS, 'CMS issue');
	exception
		when dup_val_on_index then
			null;
	end;

	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
		VALUES ('audit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class)
			VALUES (security.security_pkg.getapp, csr_data_pkg.FLOW_INV_TYPE_AUDITOR, 'audit', 'Audit co-ordinator', 'CSRUser');

		INSERT INTO flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
			VALUES (security.security_pkg.getapp, csr_data_pkg.FLOW_INV_TYPE_AUDITOR, 'audit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	DELETE FROM flow_inv_type_alert_class where flow_alert_class = 'audit';
	DELETE FROM flow_involvement_type where product_area = 'audit';
	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'audit';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	BEGIN
		DELETE FROM issue_type 
		 WHERE issue_type_id = csr_data_pkg.ISSUE_CMS;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;	
END;

PROCEDURE SetUp
AS
	v_regs		security.security_pkg.T_SID_IDS;
	v_inds		security.security_pkg.T_SID_IDS;
BEGIN
	-- Safest to log on once per test (instead of in StartupFixture) because we unset
	-- the user sid futher down (otherwise any permission test on any ACT returns true)
	
	security.user_pkg.logonadmin(v_site_name);
	
	v_region_1_sid := csr.unit_test_pkg.GetOrCreateRegion('USER_COVER_REGION_1');
	v_ind_1_sid := csr.unit_test_pkg.GetOrCreateInd('USER_COVER_IND_1');
	v_regs(1) := v_region_1_sid;
	v_inds(1) := v_ind_1_sid;
	v_deleg_1_sid := csr.unit_test_pkg.GetOrCreateDeleg('USER_COVER_DELEG_1', v_regs, v_inds);
	
	v_user_1_sid := csr.unit_test_pkg.GetOrCreateUser('USER_1');
	v_user_cover_1_sid := csr.unit_test_pkg.GetOrCreateUser('USER_COVER_1');
		
	v_audit_inv_user_1_sid := csr.unit_test_pkg.GetOrCreateUser('INV_USER_1');
	v_audit_inv_user_2_sid := csr.unit_test_pkg.GetOrCreateUser('INV_USER_2');
	v_audit_inv_user_3_sid := csr.unit_test_pkg.GetOrCreateUser('INV_USER_3');
	
	v_audit_1_sid := csr.unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'AUDIT_1',
		in_region_sid	=> 	v_region_1_sid,
		in_user_sid		=> 	v_user_1_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);
	CreateAuditWorkflow_;
	v_audit_2_sid := csr.unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT_2',
		in_region_sid	=> 	v_region_1_sid,
		in_user_sid		=> 	v_user_1_sid,
		in_flow_sid		=>  v_audit_flow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_3_sid := csr.unit_test_pkg.GetOrCreateAuditWithInvType('AUDIT_3', v_audit_flow_sid, v_region_1_sid, v_user_1_sid, v_audit_inv_user_1_sid, v_flow_item_id, v_flow_inv_type_id);
	
	v_group_1_sid := csr.unit_test_pkg.GetOrCreateGroup('GROUP_1');
	security.group_pkg.AddMember(security_pkg.getAct, v_user_1_sid, v_group_1_sid);
	
	csr.role_pkg.SetRole('ROLE_1', 'ROLE_1', v_role_1_sid);
	v_region_1_1_sid := csr.unit_test_pkg.GetOrCreateRegion('USER_COVER_REGION_1_1', v_region_1_sid);
	v_region_1_1_1_sid := csr.unit_test_pkg.GetOrCreateRegion('USER_COVER_REGION_1_1_1', v_region_1_1_sid);
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_region_1_1_sid, v_user_1_sid);
	
	-- Remove built in admin sid from user context - otherwise we can't check the permissions
	-- of test-built acts (security_pkg.IsAdmin checks sys_context sid before passed act)
	security_pkg.SetContext('SID', NULL);
	
END;

PROCEDURE TearDown
AS
BEGIN
	-- Log in as built-in admin again in case test changed logged in user in a way that would break teardown
	security.user_pkg.logonadmin(v_site_name);
	
	IF v_deleg_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_deleg_1_sid);
		v_deleg_1_sid := NULL;
	END IF;
	
	IF v_audit_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_1_sid);
		v_audit_1_sid := NULL;
	END IF;
	
	IF v_audit_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_2_sid);
		v_audit_2_sid := NULL;
	END IF;
	
	IF v_audit_3_sid IS NOT NULL THEN
		v_flow_item_id := NULL;
		flow_pkg.DeleteCustomerInvolvementType(v_flow_inv_type_id);
		v_flow_inv_type_id := NULL;
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_3_sid);
		v_audit_3_sid := NULL;
	END IF;
	
	IF v_user_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_1_sid);
		v_user_1_sid := NULL;
	END IF;
	
	IF v_user_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_2_sid);
		v_user_2_sid := NULL;
	END IF;
	
	IF v_user_cover_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_cover_1_sid);
		v_user_cover_1_sid := NULL;
	END IF;
	
	IF v_user_cover_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_cover_2_sid);
		v_user_cover_2_sid := NULL;
	END IF;
	
	IF v_audit_inv_user_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_inv_user_1_sid);
		v_audit_inv_user_1_sid := NULL;
	END IF;
	
	IF v_audit_inv_user_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_inv_user_2_sid);
		v_audit_inv_user_2_sid := NULL;
	END IF;
	
	IF v_audit_inv_user_3_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_inv_user_3_sid);
		v_audit_inv_user_3_sid := NULL;
	END IF;
	
	IF v_group_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_group_1_sid);
		v_group_1_sid := NULL;
	END IF;
	
	IF v_role_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_role_1_sid);
		v_role_1_sid := NULL;
	END IF;
	
	IF v_audit_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_audit_flow_sid);
		v_audit_flow_sid := NULL;
	END IF;
	
END;

END;
/
