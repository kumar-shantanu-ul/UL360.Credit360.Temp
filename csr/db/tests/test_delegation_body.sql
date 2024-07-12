CREATE OR REPLACE PACKAGE BODY csr.test_delegation_pkg AS

v_site_name					VARCHAR2(200);
v_delegation_sid			security_pkg.T_SID_ID;
v_delegation2_sid			security_pkg.T_SID_ID;
v_sub_delegation_sid		security_pkg.T_SID_ID;
v_sub_delegation2_sid		security_pkg.T_SID_ID;
v_deleg_user_1_sid			security_pkg.T_SID_ID;
v_deleg_user_2_sid			security_pkg.T_SID_ID;
v_deleg_user_3_sid			security_pkg.T_SID_ID;
v_regs						security_pkg.T_SID_IDS;
v_root_regions				security_pkg.T_SID_IDS;
v_inds						security_pkg.T_SID_IDS;
v_users						security_pkg.T_SID_IDS;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

-- Tests
PROCEDURE ChkDelegAccessAndPermsAsAdmin
AS
	v_act					security_pkg.T_ACT_ID;
	v_deleg_cur				SYS_REFCURSOR;
	v_row_count				NUMBER := 0;
	v_deleg_sid				NUMBER(10);
	v_group_by				VARCHAR2(64);
	v_name					VARCHAR2(1023);
	v_description			VARCHAR2(1023);
	v_note					CLOB;
	v_alloc_users_to		VARCHAR2(64);
	v_period_set_id			NUMBER(10);
	v_period_int_id			NUMBER(10);
	v_app_sid				NUMBER(10);
	v_start_date			DATE;
	v_end_date				DATE;
	v_full_name				VARCHAR2(256);
	v_period_frmt			VARCHAR2(200);
	v_note_mandatory		NUMBER(1);
	v_flag_mandatory		NUMBER(1);
	v_show_aggregate		NUMBER(1);
	v_parent_sid			NUMBER(10);
	v_is_top_level			NUMBER(1);
	v_is_delegator			NUMBER(1);
	v_section_xml			CLOB;
	v_can_alter				NUMBER(1);
	v_editing_url			VARCHAR2(255);
	v_schedule_xml			CLOB;
	v_reminder_offset		NUMBER(10);
	v_submission_offset		NUMBER(10);
	v_fully_delegated		NUMBER(1);
	v_can_delegate			NUMBER(1);
	v_deleg_policy			VARCHAR2(500);
	v_layout_id				NUMBER(10);
	v_tag_vis_matr_grp_id	NUMBER(10);
	v_allow_multi_period	NUMBER(1);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.ChkDelegAccessAndPermsAsAdmin');
	
	-- Log on as admin user - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));

	delegation_pkg.GetDelegation(
		v_act,
		v_delegation_sid,
		v_deleg_cur
	);

	LOOP
		FETCH v_deleg_cur INTO v_deleg_sid, v_group_by, v_name, v_description,
			v_note, v_alloc_users_to, v_period_set_id, v_period_int_id, v_app_sid, v_start_date,
			v_end_date, v_full_name, v_period_frmt, v_note_mandatory, v_flag_mandatory, v_show_aggregate,
			v_parent_sid, v_is_top_level, v_is_delegator, v_section_xml, v_can_alter, v_editing_url,
			v_schedule_xml, v_reminder_offset, v_submission_offset, v_fully_delegated, v_can_delegate,
			v_deleg_policy, v_layout_id, v_tag_vis_matr_grp_id, v_allow_multi_period;
		EXIT WHEN v_deleg_cur%NOTFOUND;
		
		v_row_count := v_row_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_row_count, 'GetDelegation returned more than one row!');
	unit_test_pkg.AssertIsTrue(v_can_alter = 1, 'User should be able to alter delegation!');
	unit_test_pkg.AssertIsTrue(v_can_delegate = 1, 'User should be able to delegate!');
END;

PROCEDURE ChkDelegAccessPermsAsAuditor
AS
	v_act					security_pkg.T_ACT_ID;
	v_deleg_cur				SYS_REFCURSOR;
	v_row_count				NUMBER := 0;
	v_deleg_sid				NUMBER(10);
	v_group_by				VARCHAR2(64);
	v_name					VARCHAR2(1023);
	v_description			VARCHAR2(1023);
	v_note					CLOB;
	v_alloc_users_to		VARCHAR2(64);
	v_period_set_id			NUMBER(10);
	v_period_int_id			NUMBER(10);
	v_app_sid				NUMBER(10);
	v_start_date			DATE;
	v_end_date				DATE;
	v_full_name				VARCHAR2(256);
	v_period_frmt			VARCHAR2(200);
	v_note_mandatory		NUMBER(1);
	v_flag_mandatory		NUMBER(1);
	v_show_aggregate		NUMBER(1);
	v_parent_sid			NUMBER(10);
	v_is_top_level			NUMBER(1);
	v_is_delegator			NUMBER(1);
	v_section_xml			CLOB;
	v_can_alter				NUMBER(1);
	v_editing_url			VARCHAR2(255);
	v_schedule_xml			CLOB;
	v_reminder_offset		NUMBER(10);
	v_submission_offset		NUMBER(10);
	v_fully_delegated		NUMBER(1);
	v_can_delegate			NUMBER(1);
	v_deleg_policy			VARCHAR2(500);
	v_layout_id				NUMBER(10);
	v_tag_vis_matr_grp_id	NUMBER(10);
	v_allow_multi_period	NUMBER(1);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.ChkDelegAccessAndPermsAsAuditor');
	
	-- Log on as auditor user - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_2_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	delegation_pkg.GetDelegation(
		v_act,
		v_delegation_sid,
		v_deleg_cur
	);

	LOOP
		FETCH v_deleg_cur INTO v_deleg_sid, v_group_by, v_name, v_description,
			v_note, v_alloc_users_to, v_period_set_id, v_period_int_id, v_app_sid, v_start_date,
			v_end_date, v_full_name, v_period_frmt, v_note_mandatory, v_flag_mandatory, v_show_aggregate,
			v_parent_sid, v_is_top_level, v_is_delegator, v_section_xml, v_can_alter, v_editing_url,
			v_schedule_xml, v_reminder_offset, v_submission_offset, v_fully_delegated, v_can_delegate,
			v_deleg_policy, v_layout_id, v_tag_vis_matr_grp_id, v_allow_multi_period;
		EXIT WHEN v_deleg_cur%NOTFOUND;
		
		v_row_count := v_row_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_row_count, 'GetDelegation returned more than one row!');
	unit_test_pkg.AssertIsTrue(v_can_alter = 0, 'User should NOT be able to alter delegation!');
	unit_test_pkg.AssertIsTrue(v_can_delegate = 0, 'User should NOT be able to delegate!');
END;

PROCEDURE ChkDelegAccessPermsAsNormUser
AS
	v_act					security_pkg.T_ACT_ID;
	v_no_err				BOOLEAN := FALSE;
	
	v_deleg_cur				SYS_REFCURSOR;
	v_row_count				NUMBER := 0;
	v_deleg_sid				NUMBER(10);
	v_group_by				VARCHAR2(64);
	v_name					VARCHAR2(1023);
	v_description			VARCHAR2(1023);
	v_note					CLOB;
	v_alloc_users_to		VARCHAR2(64);
	v_period_set_id			NUMBER(10);
	v_period_int_id			NUMBER(10);
	v_app_sid				NUMBER(10);
	v_start_date			DATE;
	v_end_date				DATE;
	v_full_name				VARCHAR2(256);
	v_period_frmt			VARCHAR2(200);
	v_note_mandatory		NUMBER(1);
	v_flag_mandatory		NUMBER(1);
	v_show_aggregate		NUMBER(1);
	v_parent_sid			NUMBER(10);
	v_is_top_level			NUMBER(1);
	v_is_delegator			NUMBER(1);
	v_section_xml			CLOB;
	v_can_alter				NUMBER(1);
	v_editing_url			VARCHAR2(255);
	v_schedule_xml			CLOB;
	v_reminder_offset		NUMBER(10);
	v_submission_offset		NUMBER(10);
	v_fully_delegated		NUMBER(1);
	v_can_delegate			NUMBER(1);
	v_deleg_policy			VARCHAR2(500);
	v_layout_id				NUMBER(10);
	v_tag_vis_matr_grp_id	NUMBER(10);
	v_allow_multi_period	NUMBER(1);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.ChkDelegAccessAndPermsAsNormUser');
	
	-- Log on as a normal user who has no permissions on the delegation - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_3_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	
	BEGIN
		delegation_pkg.GetDelegation(
			v_act,
			v_delegation_sid,
			v_deleg_cur
		);
		
		v_no_err := TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_ACCESS_DENIED, 'Exception should have been Access Denied!');
	END;
	
	IF v_no_err THEN
		unit_test_pkg.TestFail('User was not denied access to read delegation details!');
	END IF;
END;

PROCEDURE CopyDelegAsAdminReadWrite
AS
	v_act					security_pkg.T_ACT_ID;
	v_deleg_parent_sid		security_pkg.T_SID_ID;
	v_out_copied_deleg_sid	security_pkg.T_SID_ID;
	v_new_deleg_name		delegation.name%TYPE := 'Copied deleg';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.CopyDelegAsAdminReadWrite');
	
	-- Log on as admin user who has read/write permissions on the delegation + container - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	SELECT parent_sid
	  INTO v_deleg_parent_sid
	  FROM delegation
	 WHERE delegation_sid = v_delegation_sid;
	
	delegation_pkg.CopyDelegation(
		in_act_id => v_act,
		in_copy_delegation_sid => v_delegation_sid,
		in_new_name => v_new_deleg_name,
		out_new_delegation_sid => v_out_copied_deleg_sid
	);

	unit_test_pkg.AssertIsTrue(v_out_copied_deleg_sid IS NOT NULL, 'copy should return a sid');

	IF v_out_copied_deleg_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_out_copied_deleg_sid);
		v_out_copied_deleg_sid := NULL;
	END IF;
END;

PROCEDURE CopyDelegAsAuditorRead
AS
	v_act					security_pkg.T_ACT_ID;
	v_deleg_parent_sid		security_pkg.T_SID_ID;
	v_out_copied_deleg_sid	security_pkg.T_SID_ID;
	v_new_deleg_name		delegation.name%TYPE := 'Copied deleg';
	v_no_err				BOOLEAN := FALSE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.CopyDelegAsAuditorRead');
	
	-- Log on as auditor user who has read permissions on the delegation but not
	-- add contents on the delegation container - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_2_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	SELECT parent_sid
	  INTO v_deleg_parent_sid
	  FROM delegation
	 WHERE delegation_sid = v_delegation_sid;
	
	BEGIN
		delegation_pkg.CopyDelegation(
			in_act_id => v_act,
			in_copy_delegation_sid => v_delegation_sid,
			in_new_name => v_new_deleg_name,
			out_new_delegation_sid => v_out_copied_deleg_sid
		);

		v_no_err := TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_ACCESS_DENIED, 'Exception should have been Access Denied!');
	END;
	
	IF v_no_err THEN
		unit_test_pkg.TestFail('User was not prevented from copying the delegation!');
	END IF;
END;

PROCEDURE UpdateDelegTranslationsAsAdmin
AS
	v_act					security_pkg.T_ACT_ID;
	v_sid	number(10);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.UpdateDelegTranslationsAsAdmin');
	
	-- Log on as an admin user who should have necessary permissions - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	-- Set the context for this test as the SP we call uses security_pkg.GetACT rather than letting us pass it one.
	security_pkg.SetContext('ACT', v_act);
	
	select delegation_sid into v_sid from csr.delegation where delegation_sid = v_delegation_sid;
	
	delegation_pkg.SetTranslation(
		in_delegation_sid => v_delegation_sid,
		in_lang => 'en',
		in_description => v_delegation_sid
	);
END;

PROCEDURE UpdateDelegTranslationsAsAudit
AS
	v_act					security_pkg.T_ACT_ID;
	v_no_err				BOOLEAN := FALSE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.UpdateDelegTranslationsAsAudit');
	
	-- Log on as an auditor user who should not have write access on delegation.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_2_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	-- Set the context for this test as the SP we call uses security_pkg.GetACT rather than letting us pass it one.
	security_pkg.SetContext('ACT', v_act);
	
	BEGIN
		delegation_pkg.SetTranslation(
			in_delegation_sid => v_delegation_sid,
			in_lang => 'en',
			in_description => v_delegation_sid
		);

		v_no_err := TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_ACCESS_DENIED, 'Exception should have been Access Denied!');
	END;
	
	IF v_no_err THEN
		unit_test_pkg.TestFail('User was not prevented from updating translations on the delegation!');
	END IF;
END;

PROCEDURE TerminateDelegAsAdmin
AS
	v_act					security_pkg.T_ACT_ID;
	v_deleg_to_del_sid		security_pkg.T_SID_ID;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.TerminateDelegAsAdmin');
	
	v_deleg_to_del_sid := unit_test_pkg.GetOrCreateDeleg('DELEG_PERMS_DELEG_DELETE', v_regs, v_inds);
	
	-- Log on as an admin user who should have necessary permissions - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	delegation_pkg.Terminate(
		in_act_id => v_act,
		in_delegation_sid => v_deleg_to_del_sid
	);
END;

PROCEDURE TerminateDelegAsAuditor
AS
	v_act					security_pkg.T_ACT_ID;
	v_no_err				BOOLEAN := FALSE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.TerminateDelegAsAuditor');
	
	-- Log on as an auditor user who should not be able to terminate delegations- but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_2_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));

	BEGIN
		delegation_pkg.Terminate(
			in_act_id => v_act,
			in_delegation_sid => v_delegation_sid
		);

		v_no_err := TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_ACCESS_DENIED, 'Exception should have been Access Denied!');
	END;
	
	IF v_no_err THEN
		unit_test_pkg.TestFail('User was not prevented from terminating the delegation!');
	END IF;
END;

PROCEDURE SaveValueInEditDateLockPreventsSave
AS
	v_act					security_pkg.T_ACT_ID;
	v_no_err				BOOLEAN := FALSE;
	v_out_cur				SYS_REFCURSOR;
	v_out_id				NUMBER(10);
	v_sheet_id				NUMBER(10);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.SaveValueInEditDateLockPreventsSave');
	
	-- Log on as an auditor user who should not be able to terminate delegations- but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	SELECT MIN(sheet_id)
	  INTO v_sheet_id
	  FROM sheet
	 WHERE delegation_sid = v_delegation_sid;
	
	UPDATE customer 
	   SET lock_end_dtm = '01-JAN-2020', lock_prevents_editing = 1
     WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	BEGIN
		delegation_pkg.SaveValue(
			in_act_id 					=> v_act,
			in_sheet_id					=> v_sheet_id,
			in_ind_sid					=> v_inds(1),
			in_region_sid				=> v_regs(1),
			in_val_number				=> 5,
			in_entry_conversion_id		=> NULL,
			in_entry_val_number			=> NULL,
			in_note						=> 'NOTE',
			in_reason					=> 'REASON',
			in_file_count				=> 0,
			in_flag						=> NULL,
			in_write_history			=> 0,
			in_force_change_reason		=> 0,
			in_no_check_permission		=> 1,
			in_is_na					=> 0,
			in_apply_percent_ownership	=> 0,
			out_cur						=> v_out_cur,
			out_val_id					=> v_out_id
		);

		v_no_err := TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			UPDATE customer 
			   SET lock_end_dtm = '01-JAN-1980', lock_prevents_editing = 0
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	 
			unit_test_pkg.AssertAreEqual(SQLCODE, CSR_DATA_PKG.ERR_NOT_ALLOWED_WRITE, 'Exception should have been ERR_NOT_ALLOWED_WRITE!');
	END;
	
	UPDATE customer 
	   SET lock_end_dtm = '01-JAN-1980', lock_prevents_editing = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_no_err THEN
		unit_test_pkg.TestFail('User was not prevented from saving the value!');
	END IF;	
END;

PROCEDURE SaveValueInMergeDateLockAllowsSave
AS
	v_act					security_pkg.T_ACT_ID;
	v_out_cur				SYS_REFCURSOR;
	v_out_id				NUMBER(10);
	v_sheet_id				NUMBER(10);
	v_cnt					NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.SaveValueInMergeDateLockAllowsSave');
	
	-- Log on as an auditor user who should not be able to terminate delegations- but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	SELECT MIN(sheet_id)
	  INTO v_sheet_id
	  FROM sheet
	 WHERE delegation_sid = v_delegation_sid;
	
	UPDATE customer 
	   SET lock_end_dtm = '01-JAN-2020', lock_prevents_editing = 0
     WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	BEGIN
		delegation_pkg.SaveValue(
			in_act_id 					=> v_act,
			in_sheet_id					=> v_sheet_id,
			in_ind_sid					=> v_inds(1),
			in_region_sid				=> v_regs(1),
			in_val_number				=> 5,
			in_entry_conversion_id		=> NULL,
			in_entry_val_number			=> NULL,
			in_note						=> 'NOTE',
			in_reason					=> 'REASON',
			in_file_count				=> 0,
			in_flag						=> NULL,
			in_write_history			=> 0,
			in_force_change_reason		=> 0,
			in_no_check_permission		=> 1,
			in_is_na					=> 0,
			in_apply_percent_ownership	=> 0,
			out_cur						=> v_out_cur,
			out_val_id					=> v_out_id
		);

	EXCEPTION
		WHEN OTHERS THEN
			UPDATE customer 
			   SET lock_end_dtm = '01-JAN-1980', lock_prevents_editing = 0
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	END;
	
	UPDATE customer 
	   SET lock_end_dtm = '01-JAN-1980', lock_prevents_editing = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	 
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sheet_value
	 WHERE sheet_id = v_sheet_id
	   AND ind_sid = v_inds(1)
	   AND region_sid = v_regs(1)
	   AND val_number = 5;
	
	unit_test_pkg.AssertAreEqual(v_cnt, 1, 'Sheet value not created.');
END;

PROCEDURE SaveValueInEditDateLockWithCapAllowsSave
AS
	v_act					security_pkg.T_ACT_ID;
	v_out_cur				SYS_REFCURSOR;
	v_out_id				NUMBER(10);
	v_sheet_id				NUMBER(10);
	v_cnt					NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.SaveValueInEditDateLockWithCapAllowsSave');
	
	-- Log on as an auditor user who should not be able to terminate delegations- but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	csr_data_pkg.enablecapability('Can edit forms before system lock date');
	
	SELECT MIN(sheet_id)
	  INTO v_sheet_id
	  FROM sheet
	 WHERE delegation_sid = v_delegation_sid;
	
	UPDATE customer 
	   SET lock_end_dtm = '01-JAN-2020', lock_prevents_editing = 1
     WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	BEGIN
		delegation_pkg.SaveValue(
			in_act_id 					=> v_act,
			in_sheet_id					=> v_sheet_id,
			in_ind_sid					=> v_inds(1),
			in_region_sid				=> v_regs(1),
			in_val_number				=> 5,
			in_entry_conversion_id		=> NULL,
			in_entry_val_number			=> NULL,
			in_note						=> 'NOTE',
			in_reason					=> 'REASON',
			in_file_count				=> 0,
			in_flag						=> NULL,
			in_write_history			=> 0,
			in_force_change_reason		=> 0,
			in_no_check_permission		=> 1,
			in_is_na					=> 0,
			in_apply_percent_ownership	=> 0,
			out_cur						=> v_out_cur,
			out_val_id					=> v_out_id
		);

	EXCEPTION
		WHEN OTHERS THEN
			UPDATE customer 
			   SET lock_end_dtm = '01-JAN-1980', lock_prevents_editing = 0
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
			 
			capability_pkg.ChangeCapability('Can edit forms before system lock date', 0);
	END;
	
	UPDATE customer 
	   SET lock_end_dtm = '01-JAN-1980', lock_prevents_editing = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	 
	capability_pkg.ChangeCapability('Can edit forms before system lock date', 0);
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sheet_value
	 WHERE sheet_id = v_sheet_id
	   AND ind_sid = v_inds(1)
	   AND region_sid = v_regs(1)
	   AND val_number = 5;
	
	unit_test_pkg.AssertAreEqual(v_cnt, 1, 'Sheet value not created.');
END;

PROCEDURE InsertStepBeforeAllowsApprovalOfChild
AS
	v_act					security_pkg.T_ACT_ID;
	v_new_deleg_sid			security_pkg.T_SID_ID;
	v_cnt					NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.InsertStepBeforeAllowsApprovalOfChild');
	
	-- Log on as an admin user who should have necessary permissions - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	delegation_pkg.InsertBefore(
		in_act_id				=> v_act,
		in_delegation_sid		=> v_sub_delegation_sid,
		in_user_sid_list		=> TO_CHAR(v_deleg_user_3_sid),
		out_new_delegation_sid	=> v_new_deleg_sid
	);
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM delegation_user
	 WHERE delegation_sid = v_sub_delegation_sid
	   AND user_sid = v_deleg_user_3_sid
	   AND deleg_permission_set = delegation_pkg.DELEG_PERMISSION_DELEGATOR;
	   
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'New user missing delegator permission.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM delegation_user
	 WHERE delegation_sid = v_sub_delegation_sid
	   AND user_sid = 3
	   AND deleg_permission_set = delegation_pkg.DELEG_PERMISSION_DELEGATOR;
	   
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'Parent user missing delegator permission.');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM delegation_user
	 WHERE delegation_sid = v_sub_delegation_sid
	   AND user_sid = v_deleg_user_2_sid
	   AND deleg_permission_set = delegation_pkg.DELEG_PERMISSION_DELEGATOR;
	   
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Child user given delegator permission.');
END;

PROCEDURE SetSheetResendAlerts
AS
	v_act					security_pkg.T_ACT_ID;
	v_sids					security_pkg.T_SID_IDS;
	v_reminder_dtm			DATE;
	v_overdue_dtm			DATE;
	v_cnt					NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.SetSheetResendAlerts');
	
	-- Log on as an admin user who should have necessary permissions - but we don't want to set the security context.
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_deleg_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	-- For some reason created group members are not added through issue, possibly due to auton trans so set in this transaction?
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	v_sids(1) := v_delegation_sid;
	
	delegation_pkg.SetSheetResendAlerts(
		in_delegation_sids				=>	v_sids,
		in_start_dtm					=>	'01-JAN-10',
		in_end_dtm						=>	'01-FEB-10',
		in_level						=>	1,
		in_resend_reminder				=>  1,
		in_resend_overdue				=>  1,
		out_affected					=>	v_cnt
	);
	
	unit_test_pkg.AssertAreEqual(1, v_cnt, 'More than 1 sheet affected');
	
	delegation_pkg.SetSheetResendAlerts(
		in_delegation_sids				=>	v_sids,
		in_start_dtm					=>	'01-MAR-10',
		in_end_dtm						=>	'01-APR-10',
		in_level						=>	1,
		in_resend_reminder				=>  1,
		in_resend_overdue				=>  0,
		out_affected					=>	v_cnt
	);
	
	SELECT reminder_sent_dtm, overdue_sent_dtm 
	  INTO v_reminder_dtm, v_overdue_dtm
	  FROM sheet_alert
	 WHERE sheet_id = (
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = v_delegation_sid
		   AND start_dtm = '01-MAR-10'
		   AND end_dtm = '01-APR-10'
	 );
	 
	 unit_test_pkg.AssertAreEqual(1, v_cnt, 'More than 1 sheet affected');
	 unit_test_pkg.AssertAreEqual(v_reminder_dtm, null, 'Reminder sent date does not match');
	 unit_test_pkg.AssertAreEqual(TO_CHAR(v_overdue_dtm, 'dd-MON-yy'), TO_CHAR(SYSDATE, 'dd-MON-yy'), 'Overdue sent date does not match');
	 
	 delegation_pkg.SetSheetResendAlerts(
		in_delegation_sids				=>	v_sids,
		in_start_dtm					=>	'01-AUG-10',
		in_end_dtm						=>	'01-SEP-10',
		in_level						=>	1,
		in_resend_reminder				=>  0,
		in_resend_overdue				=>  1,
		out_affected					=>	v_cnt
	);
	
	SELECT reminder_sent_dtm, overdue_sent_dtm 
	  INTO v_reminder_dtm, v_overdue_dtm
	  FROM sheet_alert
	 WHERE sheet_id = (
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = v_delegation_sid
		   AND start_dtm = '01-AUG-10'
		   AND end_dtm = '01-SEP-10'
	 );
	 
	 unit_test_pkg.AssertAreEqual(1, v_cnt, 'More than 1 sheet affected');
	 unit_test_pkg.AssertAreEqual(TO_CHAR(v_reminder_dtm, 'dd-MON-yy'), TO_CHAR(SYSDATE, 'dd-MON-yy'), 'Reminder sent date does not match');
	 unit_test_pkg.AssertAreEqual(v_overdue_dtm, null, 'Overdue sent date does not match');
END;

PROCEDURE TestSynchChildWithParent
AS
	v_no_regs						security_pkg.T_SID_IDS;
	v_new_inds						security_pkg.T_SID_IDS;
	v_new_regs						security_pkg.T_SID_IDS;
	v_template_deleg_sid			NUMBER(10);
	v_applied_deleg_sid				NUMBER(10);
	v_applied_child_deleg_sid		NUMBER(10);
	v_applied_grand_deleg_sid		NUMBER(10);
	v_other_deleg_sid				NUMBER(10);
	v_deleg_chg						NUMBER(10) := 0;
	v_overlaps						NUMBER(10) := 0;
	v_varchar						VARCHAR2(1024);
	v_deleg_regs_cur				delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;
	v_deleg_reg_rec					delegation_pkg.T_OVERLAP_DELEG_REGIONS_REC;
BEGIN
	-- Arrange
	security.user_pkg.logonadmin(v_site_name);
	
	v_new_regs(1) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_3');
	
	v_template_deleg_sid := unit_test_pkg.GetOrCreateDeleg('TEMPL_DELEG', v_no_regs, v_inds);
	
	DELETE FROM delegation_user WHERE delegation_sid = v_template_deleg_sid;
	
	v_applied_deleg_sid := unit_test_pkg.GetOrCreateDeleg('APPLIED_DELEG', v_new_regs, v_inds);
	
	v_new_inds(1) := unit_test_pkg.GetOrCreateInd('DELEGATION_IND_3');
		
	v_other_deleg_sid := unit_test_pkg.GetOrCreateDeleg('OTHER_DELEG', v_new_regs, v_new_inds);
	
	INSERT INTO master_deleg (delegation_sid)
	VALUES (v_template_deleg_sid);

	UPDATE delegation
	   SET master_delegation_sid = v_template_deleg_sid
	 WHERE delegation_sid = v_applied_deleg_sid;
	
	delegation_pkg.CreateNonTopLevelDelegation(
		in_parent_sid 			=> v_applied_deleg_sid,
		in_name 				=> 'APPLIED_CHILD_DELEG',
		in_indicators_list 		=> TO_CHAR(v_inds(1))||','||TO_CHAR(v_inds(2)),
		in_regions_list 		=> TO_CHAR(v_new_regs(1)),
		in_user_sid_list 		=> TO_CHAR(v_deleg_user_2_sid),
		in_period_set_id 		=> 1,
		in_period_interval_id 	=> 1,
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_note 				=> 'new',
		out_delegation_sid 		=> v_applied_child_deleg_sid
	);
	
	UPDATE delegation
	   SET master_delegation_sid = v_template_deleg_sid
	 WHERE delegation_sid = v_applied_child_deleg_sid;
	 
	delegation_pkg.CreateNonTopLevelDelegation(
		in_parent_sid 			=> v_applied_child_deleg_sid,
		in_name 				=> 'APPLIED_GRAND_DELEG',
		in_indicators_list 		=> TO_CHAR(v_inds(1))||','||TO_CHAR(v_inds(2)),
		in_regions_list 		=> TO_CHAR(v_new_regs(1)),
		in_user_sid_list 		=> TO_CHAR(v_deleg_user_3_sid),
		in_period_set_id 		=> 1,
		in_period_interval_id 	=> 1,
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_note 				=> 'new',
		out_delegation_sid 		=> v_applied_grand_deleg_sid
	);
	
	UPDATE delegation
	   SET master_delegation_sid = v_template_deleg_sid
	 WHERE delegation_sid = v_applied_grand_deleg_sid;
	 
	-- Act
	
	delegation_pkg.SynchChildWithParent(
		in_act_id				=> security.security_pkg.getact,
		in_parent_sid			=> v_template_deleg_sid,
		in_child_sid			=> v_applied_deleg_sid, 
		out_delegation_changed	=> v_deleg_chg,
		out_has_overlaps		=> v_overlaps,
		out_overlap_reg_cur		=> v_deleg_regs_cur
	);
	
	-- Assert
	
	unit_test_pkg.AssertAreEqual(0, v_deleg_chg, 'Expected delegation not changed');
	unit_test_pkg.AssertAreEqual(0, v_overlaps, 'Expected no overlap');
	
	-- Act
	
	delegation_pkg.SynchChildWithParent(
		in_act_id				=> security.security_pkg.getact,
		in_parent_sid			=> v_template_deleg_sid,
		in_child_sid			=> v_applied_child_deleg_sid, 
		out_delegation_changed	=> v_deleg_chg,
		out_has_overlaps		=> v_overlaps,
		out_overlap_reg_cur		=> v_deleg_regs_cur
	);
	
	-- Assert
	
	unit_test_pkg.AssertAreEqual(0, v_deleg_chg, 'Expected delegation not changed');
	unit_test_pkg.AssertAreEqual(0, v_overlaps, 'Expected no overlap');
	
	-- Arrange Add overlap ind
	
	delegation_pkg.AddIndicatorToTLD(
		in_act_id			=> security.security_pkg.getact,
		in_delegation_sid	=> v_template_deleg_sid,
		in_sid_id			=> v_new_inds(1),
		in_description		=> 'A Description',
		in_pos				=> 3
	);
	
	-- Act
	
	delegation_pkg.SynchChildWithParent(
		in_act_id				=> security.security_pkg.getact,
		in_parent_sid			=> v_template_deleg_sid,
		in_child_sid			=> v_applied_deleg_sid, 
		out_delegation_changed	=> v_deleg_chg,
		out_has_overlaps		=> v_overlaps,
		out_overlap_reg_cur		=> v_deleg_regs_cur
	);
	
	-- Assert
	
	unit_test_pkg.AssertAreEqual(0, v_deleg_chg, 'Expected delegation not changed');
	unit_test_pkg.AssertAreEqual(1, v_overlaps, 'Expected overlap');
	
	-- Act
	
	delegation_pkg.SynchChildWithParent(
		in_act_id				=> security.security_pkg.getact,
		in_parent_sid			=> v_template_deleg_sid,
		in_child_sid			=> v_applied_child_deleg_sid, 
		out_delegation_changed	=> v_deleg_chg,
		out_has_overlaps		=> v_overlaps,
		out_overlap_reg_cur		=> v_deleg_regs_cur
	);
	
	-- Assert
	
	unit_test_pkg.AssertAreEqual(0, v_deleg_chg, 'Expected delegation not changed');
	unit_test_pkg.AssertAreEqual(1, v_overlaps, 'Expected overlap');
	
	-- Act
	
	delegation_pkg.SynchChildWithParent(
		in_act_id				=> security.security_pkg.getact,
		in_parent_sid			=> v_template_deleg_sid,
		in_child_sid			=> v_applied_grand_deleg_sid, 
		out_delegation_changed	=> v_deleg_chg,
		out_has_overlaps		=> v_overlaps,
		out_overlap_reg_cur		=> v_deleg_regs_cur
	);

	-- Assert

	LOOP
		FETCH v_deleg_regs_cur INTO v_deleg_reg_rec;
		EXIT WHEN v_deleg_regs_cur%notfound;
			unit_test_pkg.AssertAreEqual(v_new_regs(1), v_deleg_reg_rec.region_sid, 'Overlapping Region Sid should match');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_deleg_chg, 'Expected delegation not changed');
	unit_test_pkg.AssertAreEqual(1, v_overlaps, 'Expected overlap');
	unit_test_pkg.AssertAreEqual(1, v_deleg_regs_cur%rowcount, 'Expected overlap Count');
END;

/* 19C Temp table fixs */
PROCEDURE TestGetDelegations
AS
	v_ind_sid			security_pkg.T_SID_ID;
	v_region_sid		security_pkg.T_SID_ID;
	v_user_sid			security_pkg.T_SID_ID;
	v_filter_ind		security_pkg.T_SID_ID;
	v_filter_region		security_pkg.T_SID_ID;
	v_start_dtm			DATE;
	v_end_dtm			DATE;
	v_deleg_cur			SYS_REFCURSOR;
	v_sheet_cur			SYS_REFCURSOR;
	v_users_cur			SYS_REFCURSOR;

	v_user_act_id		security.security_pkg.T_ACT_ID;
	v_count				NUMBER;

	v_deleg_cur_delegation_sid		NUMBER;
	v_deleg_cur_parent_sid			NUMBER;
	v_deleg_cur_name 				VARCHAR2(100);
	v_deleg_cur_description 		VARCHAR2(100);
	v_deleg_cur_period_set_id		NUMBER;
	v_deleg_cur_period_interval_id	NUMBER;
	v_deleg_cur_start_dtm			DATE;
	v_deleg_cur_end_dtm				DATE;
	v_deleg_cur_editing_url 		VARCHAR2(100);
	v_deleg_cur_root_delegation_sid	NUMBER;

	v_sheet_cur_delegation_sid		NUMBER;
	v_sheet_cur_sheet_id			NUMBER;
	v_sheet_cur_start_dtm			DATE;
	v_sheet_cur_end_dtm				DATE;
	v_sheet_cur_last_action_id		NUMBER;
	v_sheet_cur_submission_dtm		DATE;
	v_sheet_cur_status				NUMBER;
	v_sheet_cur_sheet_action_description	VARCHAR2(100);
	v_sheet_cur_last_action_colour	VARCHAR2(100);

	v_users_cur_delegation_sid		NUMBER;
	v_users_cur_csr_user_sid		NUMBER;
	v_users_cur_full_name			VARCHAR2(100);
	v_users_cur_email				VARCHAR2(100);
	v_users_cur_active				NUMBER;
BEGIN
	v_ind_sid := v_inds(1);
	v_region_sid := v_regs(1);
	v_user_sid := v_deleg_user_1_sid;

	-- login as user
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	delegation_pkg.GetDelegations(
		in_ind_sid			=>	v_ind_sid,
		in_region_sid		=>	v_region_sid,
		in_user_sid			=>	v_user_sid,
		in_filter_ind		=>	v_filter_ind,
		in_filter_region	=>	v_filter_region,
		in_start_dtm		=>	v_start_dtm,
		in_end_dtm			=>	v_end_dtm,
		out_deleg_cur		=>	v_deleg_cur,
		out_sheet_cur		=>	v_sheet_cur,
		out_users_cur		=>	v_users_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_deleg_cur INTO 
			v_deleg_cur_delegation_sid,
			v_deleg_cur_parent_sid,
			v_deleg_cur_name,
			v_deleg_cur_description,
			v_deleg_cur_period_set_id,
			v_deleg_cur_period_interval_id,
			v_deleg_cur_start_dtm,
			v_deleg_cur_end_dtm,
			v_deleg_cur_editing_url,
			v_deleg_cur_root_delegation_sid
		;
		EXIT WHEN v_deleg_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_deleg_cur_name||'('||v_deleg_cur_delegation_sid||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 deleg results');

	v_count := 0;
	LOOP
		FETCH v_sheet_cur INTO 
			v_sheet_cur_delegation_sid,
			v_sheet_cur_sheet_id,
			v_sheet_cur_start_dtm,
			v_sheet_cur_end_dtm,
			v_sheet_cur_last_action_id,
			v_sheet_cur_submission_dtm,
			v_sheet_cur_status,
			v_sheet_cur_sheet_action_description,
			v_sheet_cur_last_action_colour
		;
		EXIT WHEN v_deleg_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_sheet_cur_delegation_sid||'('||v_sheet_cur_sheet_id||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 sheet results');

	v_count := 0;
	LOOP
		FETCH v_users_cur INTO 
			v_users_cur_delegation_sid,
			v_users_cur_csr_user_sid,
			v_users_cur_full_name,
			v_users_cur_email,
			v_users_cur_active
		;
		EXIT WHEN v_users_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_users_cur_delegation_sid||'('||v_users_cur_csr_user_sid||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 users results');
END;

PROCEDURE TestGetMyDelegations
AS
	v_region_sid			NUMBER;
	v_days					NUMBER;
	v_sheets				SYS_REFCURSOR;
	v_users					SYS_REFCURSOR;
	v_deleg_regions			SYS_REFCURSOR;

	v_count					NUMBER;

	v_sheets_cur_parent_sheet_id			NUMBER;
	v_sheets_cur_delegated_by_user			NUMBER;
	v_sheets_cur_is_visible					NUMBER;
	v_sheets_cur_sheet_id					NUMBER;
	v_sheets_cur_delegation_sid				NUMBER;
	v_sheets_cur_name						VARCHAR2(100);
	v_sheets_cur_start_dtm					DATE;
	v_sheets_cur_end_dtm					DATE;
	v_sheets_cur_period_set_id				NUMBER;
	v_sheets_cur_period_interval_id			NUMBER;
	v_sheets_cur_delegation_start_dtm		DATE;
	v_sheets_cur_delegation_end_dtm			DATE;
	v_sheets_cur_duration					NUMBER;
	v_sheets_cur_now_dtm					DATE;
	v_sheets_cur_submission_dtm				DATE;
	v_sheets_cur_submission_dtm_fmt			VARCHAR2(100);
	v_sheets_cur_status						NUMBER;
	v_sheets_cur_sheet_action_description	VARCHAR2(100);
	v_sheets_cur_sheet_action_downstream	VARCHAR2(100);
	v_sheets_cur_fully_delegated			NUMBER;
	v_sheets_cur_parent_delegation_sid		NUMBER;
	v_sheets_cur_editing_url				VARCHAR2(100);
	v_sheets_cur_last_action_id				NUMBER;
	v_sheets_cur_is_top_level				NUMBER;
	v_sheets_cur_approve_dtm				DATE;
	v_sheets_cur_sheet_change_req_id		NUMBER;
	v_sheets_cur_child_sheet_colour			VARCHAR2(100);
	v_sheets_cur_percent_complete			NUMBER;

BEGIN
	delegation_pkg.GetMyDelegations(
		in_region_sid			=>	v_region_sid,
		in_days					=>	v_days,
		out_sheets				=>	v_sheets,
		out_users				=>	v_users,
		out_deleg_regions		=>	v_deleg_regions
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_sheets INTO 
			v_sheets_cur_parent_sheet_id,
			v_sheets_cur_delegated_by_user,
			v_sheets_cur_is_visible,
			v_sheets_cur_sheet_id,
			v_sheets_cur_delegation_sid,
			v_sheets_cur_name,
			v_sheets_cur_start_dtm,
			v_sheets_cur_end_dtm,
			v_sheets_cur_period_set_id,
			v_sheets_cur_period_interval_id,
			v_sheets_cur_delegation_start_dtm,
			v_sheets_cur_delegation_end_dtm,
			v_sheets_cur_duration, 
			v_sheets_cur_now_dtm,
			v_sheets_cur_submission_dtm, 
			v_sheets_cur_submission_dtm_fmt,
			v_sheets_cur_status,
			v_sheets_cur_sheet_action_description,
			v_sheets_cur_sheet_action_downstream,
			v_sheets_cur_fully_delegated,
			v_sheets_cur_parent_delegation_sid,
			v_sheets_cur_editing_url,
			v_sheets_cur_last_action_id,
			v_sheets_cur_is_top_level,
			v_sheets_cur_approve_dtm,
			v_sheets_cur_sheet_change_req_id,
			v_sheets_cur_child_sheet_colour,
			v_sheets_cur_percent_complete
		;
		EXIT WHEN v_sheets%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_sheets_cur_parent_sheet_id||'('||v_sheets_cur_sheet_id||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 sheets results');
END;

PROCEDURE TestExFindOverlaps
AS
	v_act_id			security_pkg.T_ACT_ID;

	v_ignore_self		NUMBER;
	v_parent_sid		security_pkg.T_SID_ID;
	v_start_dtm			delegation.start_dtm%TYPE;
	v_end_dtm			delegation.end_dtm%TYPE;
	v_deleg_cur			delegation_pkg.T_OVERLAP_DELEG_CUR;
	v_deleg_inds_cur	delegation_pkg.T_OVERLAP_DELEG_INDS_CUR;
	v_deleg_regions_cur delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;

	v_count NUMBER;

	v_deleg_cur_delegation_sid					NUMBER;
	v_deleg_cur_parent_sid						NUMBER;
	v_deleg_cur_name							VARCHAR2(100);
	v_deleg_cur_description						VARCHAR2(100);
	v_deleg_cur_allocate_users_to				VARCHAR2(100);
	v_deleg_cur_group_by						VARCHAR2(100);
	v_deleg_cur_reminder_offset					NUMBER;
	v_deleg_cur_is_note_mandatory				NUMBER;
	v_deleg_cur_is_flag_mandatory				NUMBER;
	v_deleg_cur_fully_delegated					NUMBER;
	v_deleg_cur_start_dtm						DATE;
	v_deleg_cur_end_dtm							DATE;
	v_deleg_cur_period_set_id					NUMBER;
	v_deleg_cur_period_interval_id				NUMBER;
	v_deleg_cur_schedule_xml					VARCHAR2(100);
	v_deleg_cur_show_aggregate					NUMBER;
	v_deleg_cur_delegation_policy				NUMBER;
	v_deleg_cur_submission_offset				NUMBER;
	v_deleg_cur_tag_visibility_matrix_group_id	NUMBER;
	v_deleg_cur_allow_multi_period				NUMBER;

BEGIN
	v_act_id := security.security_pkg.GetACT;
	v_ignore_self := 0;

	SELECT parent_sid
	  INTO v_parent_sid
	  FROM delegation
	 WHERE delegation_sid = v_delegation_sid;

	v_start_dtm	:= DATE '2000-01-01';
	v_end_dtm	:= DATE '2022-01-01';

	delegation_pkg.ExFindOverlaps(
		in_act_id		 		=>	v_act_id,
		in_delegation_sid		=>	v_delegation_sid,
		in_ignore_self			=>	v_ignore_self,
		in_parent_sid			=>	v_parent_sid,
		in_start_dtm			=>	v_start_dtm,
		in_end_dtm				=>	v_end_dtm,
		in_indicators_list		=>	v_inds,
		in_regions_list			=>	v_regs,
		out_deleg_cur			=>	v_deleg_cur,
		out_deleg_inds_cur		=>	v_deleg_inds_cur,
		out_deleg_regions_cur	=>	v_deleg_regions_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_deleg_cur INTO 
			v_deleg_cur_delegation_sid,
			v_deleg_cur_parent_sid,
			v_deleg_cur_name,
			v_deleg_cur_description,
			v_deleg_cur_allocate_users_to,
			v_deleg_cur_group_by,
			v_deleg_cur_reminder_offset,
			v_deleg_cur_is_note_mandatory,
			v_deleg_cur_is_flag_mandatory,
			v_deleg_cur_fully_delegated,
			v_deleg_cur_start_dtm,
			v_deleg_cur_end_dtm, 
			v_deleg_cur_period_set_id,
			v_deleg_cur_period_interval_id,
			v_deleg_cur_schedule_xml,
			v_deleg_cur_show_aggregate,
			v_deleg_cur_delegation_policy,
			v_deleg_cur_submission_offset,
			v_deleg_cur_tag_visibility_matrix_group_id,
			v_deleg_cur_allow_multi_period
		;
		EXIT WHEN v_deleg_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_deleg_cur_name||'('||v_deleg_cur_delegation_sid||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 deleg results');
END;

PROCEDURE TestGetReportSubmissionPromptness
AS
	v_in_start_dtm			DATE;
	v_in_end_dtm			DATE;
	v_out_cur				SYS_REFCURSOR;

	v_count					NUMBER;

	v_period_set_id			NUMBER;
	v_period_interval_id	NUMBER;
	v_start_dtm				DATE;
	v_end_dtm				DATE;
	v_name					VARCHAR2(100);
	v_description			VARCHAR2(100);
	v_region				VARCHAR2(100);
	v_users					VARCHAR2(100);
	v_status				VARCHAR2(100);
	v_date_of_first_action	DATE;
	v_submission_deadline	DATE;
	v_submission_date		DATE;
	v_delegation_sid		NUMBER;
	v_sheet_id				NUMBER;
	v_delegation_start		DATE;
	v_delegation_end		DATE;
	v_sheet_start			DATE;
	v_sheet_end				DATE;

BEGIN
	delegation_pkg.GetReportSubmissionPromptness(
		in_sheet_start_date => v_in_start_dtm,
		in_sheet_end_date => v_in_end_dtm,
		out_cur => v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	-- The table involved here is tt_filter_object_data.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_period_set_id,
			v_period_interval_id,
			v_start_dtm,
			v_end_dtm,
			v_name,
			v_description,
			v_region,
			v_users,
			v_status,
			v_date_of_first_action,
			v_submission_deadline,
			v_submission_date,
			v_delegation_sid,
			v_sheet_id,
			v_delegation_start,
			v_delegation_end,
			v_sheet_start,
			v_sheet_end
		;
		EXIT WHEN v_out_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_name||'('||v_start_dtm||' - '||v_end_dtm||')');

	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');
END;

PROCEDURE GetNewAlerts
AS
	v_customer_alert_type_id 			NUMBER;
	v_new_delegation_alert_id			NUMBER;
	v_test_sheet_id						NUMBER;
	v_app_sid							NUMBER;

	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_new_delegation_alert_id		NUMBER;
	v_cur_notify_user_sid				NUMBER;
	v_cur_delegator_full_name			VARCHAR2(100);
	v_cur_full_name						VARCHAR2(100);
	v_cur_friendly_name					VARCHAR2(100);
	v_cur_email							VARCHAR2(100);
	v_cur_user_name						VARCHAR2(100);
	v_cur_csr_user_sid					NUMBER;
	v_cur_app_sid						NUMBER;
    v_cur_delegation_name				VARCHAR2(100);
	v_cur_delegation_description		VARCHAR2(100);
	v_cur_submission_dtm				DATE;
	v_cur_delegator_email				VARCHAR2(100);
	v_cur_delegation_sid				NUMBER;
	v_cur_sheet_id						NUMBER;
	v_cur_sheet_url						VARCHAR2(100);
	v_cur_deleg_assigned_to				VARCHAR2(100);
	v_cur_sheet_start_dtm				DATE;
	v_cur_sheet_end_dtm					DATE;
	v_cur_period_set_id					NUMBER;
	v_cur_period_interval_id			NUMBER;
	v_cur_raised_by_user_sid			NUMBER;
	v_cur_region_count					NUMBER;
	v_cur_region_names					VARCHAR2(100);

	v_count					 			NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.GetNewAlerts');

	security.user_pkg.logonadmin(v_site_name);
	v_app_sid := security.security_pkg.getapp;

	-- ensure clean starting point
	DELETE FROM new_delegation_alert;

	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM customer_alert_type
	 WHERE std_alert_type_id = csr_data_pkg.ALERT_NEW_DELEGATION
	;

	enable_pkg.EnableAlert(csr_data_pkg.ALERT_NEW_DELEGATION);

	-- setup the alert data
	TRACE('v_delegation_sid='||v_delegation_sid);
	SELECT MIN(sheet_id)
	  INTO v_test_sheet_id
	  FROM sheet
	 WHERE delegation_sid = v_delegation_sid;

	TRACE('v_deleg_user_1_sid='||v_deleg_user_1_sid);
	TRACE('v_deleg_user_2_sid='||v_deleg_user_2_sid);
	TRACE('v_test_sheet_id='||v_test_sheet_id);

	INSERT INTO new_delegation_alert
	(new_delegation_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
	VALUES (new_delegation_alert_id_seq.nextval, v_deleg_user_1_sid, v_deleg_user_2_sid, v_test_sheet_id);

	SELECT new_delegation_alert_id_seq.currval
	  INTO v_new_delegation_alert_id
	  FROM DUAL;

	-- fiddle with the abr to ensure it fires.
	DELETE FROM alert_batch_run
	 WHERE csr_user_sid IN (v_deleg_user_1_sid, v_deleg_user_2_sid);

	security.user_pkg.logonadmin();
	delegation_pkg.GetNewAlerts(
		in_alert_pivot_dtm => SYSDATE + 1,
		out_cur	=>	v_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted, although the
	-- table involved here (temp_alert_batch_run) actually does an ON COMMIT PRESERVE ROWS.
	-- So an error can't be simulated here.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_cur_new_delegation_alert_id,
			v_cur_notify_user_sid,
			v_cur_delegator_full_name,
			v_cur_full_name,
			v_cur_friendly_name,
			v_cur_email,
			v_cur_user_name,
			v_cur_csr_user_sid,
			v_cur_app_sid,
			v_cur_delegation_name,
			v_cur_delegation_description, 
			v_cur_submission_dtm,
			v_cur_delegator_email,
			v_cur_delegation_sid,
			v_cur_sheet_id, 
			v_cur_sheet_url,
			v_cur_deleg_assigned_to,
			v_cur_sheet_start_dtm,
			v_cur_sheet_end_dtm,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_raised_by_user_sid,
			v_cur_region_count, 
			v_cur_region_names
		;

		TRACE('deleg alert '||v_cur_new_delegation_alert_id||' for app '||v_cur_app_sid);

		IF v_cur_app_sid = v_app_sid AND
		   v_cur_new_delegation_alert_id = v_new_delegation_alert_id AND
		   v_cur_notify_user_sid = v_deleg_user_1_sid AND
		   v_cur_raised_by_user_sid = v_deleg_user_2_sid AND
		   v_cur_sheet_id = v_test_sheet_id
		THEN
			TRACE('cur contains '||v_cur_new_delegation_alert_id||','||v_cur_notify_user_sid||','||v_cur_raised_by_user_sid||','||v_cur_sheet_id);
			TRACE('and '||v_cur_delegator_full_name||','||v_cur_full_name||','||v_cur_friendly_name||','||v_cur_email||','||v_cur_user_name);
			TRACE('and '||v_cur_csr_user_sid||','||v_cur_delegation_name||','||v_cur_delegation_description||','||v_cur_submission_dtm||','||v_cur_delegator_email);
			TRACE('and '||v_cur_delegation_sid||','||v_cur_sheet_id||','||v_cur_sheet_url||','||v_cur_deleg_assigned_to||','||v_cur_sheet_start_dtm);
			TRACE('and '||v_cur_sheet_end_dtm||','||v_cur_period_set_id||','||v_cur_period_interval_id||','||v_cur_raised_by_user_sid||','||v_cur_region_count);
			TRACE('and '||v_cur_region_names);
			v_count := v_count + 1;
		END IF;

		EXIT WHEN v_cur%NOTFOUND;
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 cur entry for app '||v_app_sid); 

	security.user_pkg.logonadmin(v_site_name);
END;
/* 19C Temp table fixs end */


PROCEDURE TestGetAllTranslations
AS
	v_region_sids			security_pkg.T_SID_IDS;
	v_ind_sids				security_pkg.T_SID_IDS;
	v_validation_lang		delegation_description.lang%TYPE;
	v_changed_since			DATE;
	v_cur					SYS_REFCURSOR;

	v_sid					NUMBER;
	v_description			VARCHAR2(100);
	v_lang					VARCHAR2(100);
	v_start_dtm				DATE;
	v_end_dtm				DATE;
	v_period_set_id			NUMBER;
	v_period_interval_id	NUMBER;
	v_from_plan				NUMBER;
	v_so_level				NUMBER;
	v_has_changed			NUMBER;

	v_count					NUMBER;
BEGIN
	delegation_pkg.GetAllTranslations(
		in_region_sids			=>	v_region_sids,
		in_ind_sids				=>	v_ind_sids,
		in_validation_lang		=>	v_validation_lang,
		in_changed_since		=>	v_changed_since,
		out_cur					=>	v_cur
	);
	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_sid,
			v_description,
			v_lang,
			v_start_dtm,
			v_end_dtm,
			v_period_set_id,
			v_period_interval_id,
			v_from_plan,
			v_so_level,
			v_has_changed
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Unexpected value');

	-- Use the global regs/inds
	delegation_pkg.GetAllTranslations(
		in_region_sids			=>	v_regs,
		in_ind_sids				=>	v_inds,
		in_validation_lang		=>	v_validation_lang,
		in_changed_since		=>	v_changed_since,
		out_cur					=>	v_cur
	);

	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_sid,
			v_description,
			v_lang,
			v_start_dtm,
			v_end_dtm,
			v_period_set_id,
			v_period_interval_id,
			v_from_plan,
			v_so_level,
			v_has_changed
		;
		EXIT WHEN v_cur%NOTFOUND;

		Trace('v_sid='||v_sid||'v_description='||v_description);
		v_count := v_count + 1;

		IF v_count = 1 THEN
			unit_test_pkg.AssertAreEqual('DELEG_PERMS_DELEG desc en 1.06', v_description, 'Unexpected desc');
		END IF;
		IF v_count = 2 OR v_count = 3 THEN
			unit_test_pkg.AssertAreEqual('DELEG_PERMS_DELEG desc en 1.09', v_description, 'Unexpected desc');
		END IF;
		IF v_count = 4 THEN
			unit_test_pkg.AssertAreEqual('DELEG_PERMS_DELEG desc en sub 1.08', v_description, 'Unexpected desc');
		END IF;
		IF v_count = 5 THEN
			unit_test_pkg.AssertAreEqual('DELEG_PERMS_DELEG desc en sub 1.05', v_description, 'Unexpected desc');
		END IF;
	END LOOP;

	unit_test_pkg.AssertAreEqual(5, v_count, 'Unexpected count');
END;

PROCEDURE CreateSheetsForDelegationAlerts
AS
	v_regs							security_pkg.T_SID_IDS;
	v_deleg_sid						NUMBER(10);
	v_cur							SYS_REFCURSOR;
	v_cnt							NUMBER(10);
BEGIN
	UPDATE alert_template
	   SET send_type = 'manual'
	 WHERE customer_alert_type_id = (SELECT customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id = 80);
	 
	-- Arrange
	security.user_pkg.logonadmin(v_site_name);
	
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1');
	
	v_deleg_sid := unit_test_pkg.GetOrCreateDeleg('SHEET_ALERT_DELEG', v_regs, v_inds);	
	
	DELETE FROM sheet_created_alert;
	-- Act
	delegation_pkg.CreateSheetsForDelegation(
		in_delegation_sid		=> v_deleg_sid,
		in_at_least_one			=> 0,
		in_date_to				=> SYSDATE,
		in_send_alerts			=> 0,
		out_cur					=> v_cur
	);
	
	-- Assert	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sheet_created_alert
	 WHERE sheet_id IN (SELECT sheet_id FROM csr.sheet WHERE delegation_sid = v_deleg_sid);
	
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Expected no alerts generated');
	
	-- Arrange
	delegation_pkg.CreateTopLevelDelegation(
		in_act_id				=> security.security_pkg.GetACT,
		in_name					=> 'SHEET_ALERT_DELEG2',
		in_date_from			=> date '2022-01-01',
		in_date_to				=> date '2023-01-01',
		in_period_set_id		=> 1,
		in_period_interval_id	=> 1,
		in_allocate_users_to	=> 'region',
		in_app_sid 				=> security.security_pkg.GetApp,
		in_note 				=> 'Test delegation',
		in_group_by 			=> 'region,indicator',
		in_schedule_xml 		=> '<recurrences><monthly every-n="1"><day number="1"/></monthly></recurrences>',
		in_reminder_offset 		=> 5,
		in_submission_offset	=> 0,
		in_note_mandatory 		=> 0,
		in_flag_mandatory 		=> 0,
		in_policy 				=> NULL,
		out_delegation_sid 		=> v_deleg_sid
	);
	delegation_pkg.AddIndicatorToTLD(
		in_act_id						=> security.security_pkg.GetACT,
		in_delegation_sid				=> v_deleg_sid,
		in_sid_id						=> v_inds(1),
		in_description					=> 'Test Indicator',
		in_pos							=> 1
	);
	delegation_pkg.AddRegionToTLD(
		in_act_id						=> security.security_pkg.GetACT,
		in_delegation_sid				=> v_deleg_sid,
		in_sid_id						=> v_regs(1),
		in_description					=> 'Test Region',
		in_pos							=> 1
	);
	delegation_pkg.SetUsers(
		in_act_id			=> security.security_pkg.GetACT,
		in_delegation_sid	=> v_deleg_sid,
		in_users_list		=> TO_CHAR(v_deleg_user_1_sid)||','||TO_CHAR(v_deleg_user_2_sid)||','||TO_CHAR(v_deleg_user_3_sid)
	);
	
	-- Act	
	delegation_pkg.CreateSheetsForDelegation(
		in_delegation_sid		=> v_deleg_sid,
		in_at_least_one			=> 0,
		in_date_to				=> SYSDATE,
		in_send_alerts			=> 1,
		out_cur					=> v_cur
	);
	
	-- Assert	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sheet_created_alert
	 WHERE sheet_id IN (SELECT sheet_id FROM csr.sheet WHERE delegation_sid = v_deleg_sid);
	
	unit_test_pkg.AssertAreEqual(36, v_cnt, 'Expected alerts generated');
	
	FOR r IN (
		SELECT delegation_sid FROM delegation
		WHERE name IN ('SHEET_ALERT_DELEG', 'SHEET_ALERT_DELEG2'))
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
END;

PROCEDURE CreateSheetsForDelegationAlertsInactive
AS
	v_regs							security_pkg.T_SID_IDS;
	v_deleg_sid						NUMBER(10);
	v_cur							SYS_REFCURSOR;
	v_cnt							NUMBER(10);
BEGIN
	UPDATE alert_template
	   SET send_type = 'inactive'
	 WHERE customer_alert_type_id = (SELECT customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id = 80);
	 
	-- Arrange
	security.user_pkg.logonadmin(v_site_name);
	
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1');
	
	v_deleg_sid := unit_test_pkg.GetOrCreateDeleg('SHEET_ALERT_DELEG', v_regs, v_inds);	
	
	DELETE FROM sheet_created_alert;
	-- Act
	delegation_pkg.CreateSheetsForDelegation(
		in_delegation_sid		=> v_deleg_sid,
		in_at_least_one			=> 0,
		in_date_to				=> SYSDATE,
		in_send_alerts			=> 0,
		out_cur					=> v_cur
	);
	
	-- Assert	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sheet_created_alert
	 WHERE sheet_id IN (SELECT sheet_id FROM csr.sheet WHERE delegation_sid = v_deleg_sid);
	
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Expected no alerts generated');
	
	-- Act
	delegation_pkg.CreateTopLevelDelegation(
		in_act_id				=> security.security_pkg.GetACT,
		in_name					=> 'SHEET_ALERT_DELEG2',
		in_date_from			=> date '2022-01-01',
		in_date_to				=> date '2023-01-01',
		in_period_set_id		=> 1,
		in_period_interval_id	=> 1,
		in_allocate_users_to	=> 'region',
		in_app_sid 				=> security.security_pkg.GetApp,
		in_note 				=> 'Test delegation',
		in_group_by 			=> 'region,indicator',
		in_schedule_xml 		=> '<recurrences><monthly every-n="1"><day number="1"/></monthly></recurrences>',
		in_reminder_offset 		=> 5,
		in_submission_offset	=> 0,
		in_note_mandatory 		=> 0,
		in_flag_mandatory 		=> 0,
		in_policy 				=> NULL,
		out_delegation_sid 		=> v_deleg_sid
	);
	delegation_pkg.AddIndicatorToTLD(
		in_act_id						=> security.security_pkg.GetACT,
		in_delegation_sid				=> v_deleg_sid,
		in_sid_id						=> v_inds(1),
		in_description					=> 'Test Indicator',
		in_pos							=> 1
	);
	delegation_pkg.AddRegionToTLD(
		in_act_id						=> security.security_pkg.GetACT,
		in_delegation_sid				=> v_deleg_sid,
		in_sid_id						=> v_regs(1),
		in_description					=> 'Test Region',
		in_pos							=> 1
	);
	delegation_pkg.SetUsers(
		in_act_id			=> security.security_pkg.GetACT,
		in_delegation_sid	=> v_deleg_sid,
		in_users_list		=> TO_CHAR(v_deleg_user_1_sid)||','||TO_CHAR(v_deleg_user_2_sid)||','||TO_CHAR(v_deleg_user_3_sid)
	);	
	
	delegation_pkg.CreateSheetsForDelegation(
		in_delegation_sid		=> v_deleg_sid,
		in_at_least_one			=> 0,
		in_date_to				=> SYSDATE,
		in_send_alerts			=> 1,
		out_cur					=> v_cur
	);
	
	-- Assert	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sheet_created_alert
	 WHERE sheet_id IN (SELECT sheet_id FROM csr.sheet WHERE delegation_sid = v_deleg_sid);
	
	unit_test_pkg.AssertAreEqual(0, v_cnt, 'Expected alerts generated');

	FOR r IN (
		SELECT delegation_sid FROM delegation
		WHERE name IN ('SHEET_ALERT_DELEG', 'SHEET_ALERT_DELEG2'))
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
END;

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

/* Setup, Teardown */

PROCEDURE SetUp
AS
BEGIN
	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
	
	-- Un-set the Built-in admin's user sid from the session,
	-- otherwise all permissions tests against any ACT will return true
	-- because of the internal workings of security pkgs
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE TearDown
AS
BEGIN
	-- No harm doing this again just in case.
	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE INTERNAL_SetUpAlertTemplates
AS
	v_frame_id		security.security_pkg.T_SID_ID;
BEGIN
	alert_pkg.GetOrCreateFrame('Default', v_frame_id);

	BEGIN
		INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
		VALUES (csr.customer_alert_type_id_seq.nextval, csr.csr_data_pkg.ALERT_SHEET_CREATED);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	alert_pkg.saveTemplateAndBody(alert_pkg.GetCustomerAlertType(csr_data_pkg.ALERT_SHEET_CREATED), v_frame_id, 'manual', NULL, NULL, 'en',
		'<template>Sbj</template>', '<template>Msg</template>', '<template></template>');
END;

PROCEDURE INTERNAL_TearDownAlertTemplates
AS
	v_cust_alert_type_id		NUMBER;
BEGIN
	BEGIN
		SELECT customer_alert_type_id
		  INTO v_cust_alert_type_id
		  FROM csr.customer_alert_type
		 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CREATED;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RETURN;
	END;

	DELETE FROM csr.alert_template_body
	 WHERE customer_alert_type_id = v_cust_alert_type_id;
	DELETE FROM csr.alert_template
	 WHERE customer_alert_type_id = v_cust_alert_type_id;

	DELETE FROM csr.customer_alert_type
	 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CREATED;
END;


PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_auditors_grp_sid			NUMBER;
	v_admins_grp_sid			NUMBER;
	v_sheets_cur				SYS_REFCURSOR;
	v_sheet_id					NUMBER;
	v_sheet_start_dtm			DATE;
	v_sheet_end_dtm				DATE;
	v_submission_dtm			DATE;
	v_reminder_dtm				DATE;
	v_editing_url				VARCHAR2(255);
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	TearDownFixture;

	FOR r IN (SELECT delegation_sid 
				FROM delegation
			  WHERE name = 'Copied deleg')
	LOOP
		securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;

	v_inds(1) := unit_test_pkg.GetOrCreateInd('DELEGATION_IND_1');
	v_inds(2) := unit_test_pkg.GetOrCreateInd('DELEGATION_IND_2');
	
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1');
	v_regs(2) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1_1', v_regs(1), csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(3) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1_1_1', v_regs(2));
	v_regs(4) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1_2', v_regs(1), csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(5) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_2');
	
	v_root_regions(1) := v_regs(1);

	v_auditors_grp_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Auditors');
	v_admins_grp_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Administrators');
	
	-- Enable can delegate capability and grant permission on administrators group.
	csr_data_pkg.enablecapability('Subdelegation');
	
	v_deleg_user_1_sid := csr.unit_test_pkg.GetOrCreateUser('DELEG_USER_1', v_admins_grp_sid);
	v_deleg_user_2_sid := csr.unit_test_pkg.GetOrCreateUser('DELEG_USER_2', v_auditors_grp_sid);
	v_deleg_user_3_sid := csr.unit_test_pkg.GetOrCreateUser('DELEG_USER_3');
	
	v_users(1) := v_deleg_user_1_sid;
	v_users(2) := v_deleg_user_2_sid;
	v_users(3) := v_deleg_user_3_sid;
	
	v_delegation_sid := unit_test_pkg.GetOrCreateDeleg('DELEG_PERMS_DELEG 1.03', v_regs, v_inds);
	delegation_pkg.AddDescriptionToDelegation(security.security_pkg.GetAct, v_delegation_sid, 'en', 'DELEG_PERMS_DELEG desc en 1.09');

	v_delegation2_sid := unit_test_pkg.GetOrCreateDeleg('DELEG_PERMS_DELEG 1.01', v_regs, v_inds);
	delegation_pkg.AddDescriptionToDelegation(security.security_pkg.GetAct, v_delegation2_sid, 'en', 'DELEG_PERMS_DELEG desc en 1.06');


	delegation_pkg.CreateSheetsForDelegation(v_delegation_sid, 0, v_sheets_cur);
	delegation_pkg.CreateNonTopLevelDelegation(
		in_parent_sid 			=> v_delegation_sid,
		in_name 				=> 'Sub Deleg',
		in_indicators_list 		=> TO_CHAR(v_inds(1))||','||TO_CHAR(v_inds(2)),
		in_regions_list 		=> TO_CHAR(v_regs(1))||','||TO_CHAR(v_regs(2))||','||TO_CHAR(v_regs(3))||','||TO_CHAR(v_regs(4))||','||TO_CHAR(v_regs(5)),
		in_user_sid_list 		=> TO_CHAR(v_deleg_user_2_sid),
		in_period_set_id 		=> 1,
		in_period_interval_id 	=> 1,
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_note 				=> 'new',
		out_delegation_sid 		=> v_sub_delegation_sid
	);
	delegation_pkg.SetTranslation(v_sub_delegation_sid, 'en', 'DELEG_PERMS_DELEG desc en sub 1.08');

	delegation_pkg.CreateNonTopLevelDelegation(
		in_parent_sid 			=> v_delegation_sid,
		in_name 				=> 'Sub Deleg 2',
		in_indicators_list 		=> TO_CHAR(v_inds(1))||','||TO_CHAR(v_inds(2)),
		in_regions_list 		=> TO_CHAR(v_regs(1))||','||TO_CHAR(v_regs(2))||','||TO_CHAR(v_regs(3))||','||TO_CHAR(v_regs(4))||','||TO_CHAR(v_regs(5)),
		in_user_sid_list 		=> TO_CHAR(v_deleg_user_2_sid),
		in_period_set_id 		=> 1,
		in_period_interval_id 	=> 1,
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_note 				=> 'new',
		out_delegation_sid 		=> v_sub_delegation2_sid
	);
	delegation_pkg.SetTranslation(v_sub_delegation2_sid, 'en', 'DELEG_PERMS_DELEG desc en sub 1.05');
	LOOP
		FETCH v_sheets_cur INTO v_sheet_id, v_sheet_start_dtm, v_sheet_end_dtm, v_submission_dtm, v_reminder_dtm, v_editing_url;
		EXIT WHEN v_sheets_cur%NOTFOUND;
		--TRACE('v_sheet_id='||v_sheet_id);
		sheet_pkg.RecordReminderSent(v_sheet_id, v_deleg_user_1_sid);
		sheet_pkg.RecordOverdueSent(v_sheet_id, v_deleg_user_1_sid);
	END LOOP;

	INTERNAL_SetUpAlertTemplates();
	--commit;
END;

PROCEDURE TearDownFixture
AS
	v_sids		security.T_SID_TABLE;
	v_count		NUMBER;
	v_sid		NUMBER;
BEGIN

	INTERNAL_TearDownAlertTemplates();

	DELETE FROM delegation_description
	 WHERE delegation_sid IN (SELECT delegation_sid FROM delegation WHERE name LIKE 'DELEG_PERMS_DELEG%');
	
	FOR r IN (SELECT delegation_sid FROM delegation WHERE name LIKE 'DELEG_PERMS_DELEG%')
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
	
	FOR r IN (
		SELECT delegation_sid FROM delegation
		WHERE name IN ('APPLIED_GRAND_DELEG', 'APPLIED_CHILD_DELEG', 'APPLIED_DELEG', 'OTHER_DELEG', 'SHEET_ALERT_DELEG', 'SHEET_ALERT_DELEG2'))
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
	
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 WHERE name = 'TEMPL_DELEG'
	) LOOP
		DELETE FROM master_deleg WHERE delegation_sid = r.delegation_sid;
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
	
	SELECT MIN(ind_sid)
	  INTO v_sid
	  FROM ind
	 WHERE name = 'DELEGATION_IND_3';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	SELECT MIN(region_sid)
	  INTO v_sid
	  FROM region
	 WHERE name = 'DELEG_REGION_3';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	RemoveSids(v_regs);
	RemoveSids(v_inds);
	RemoveSids(v_users);
END;

END;
/
