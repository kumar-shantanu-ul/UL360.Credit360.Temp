CREATE OR REPLACE PACKAGE BODY csr.test_sheet_pkg AS

v_site_name					VARCHAR2(200);
v_delegation_sid			security_pkg.T_SID_ID;
v_sub_delegation_sid		security_pkg.T_SID_ID;
v_sub_sub_delegation_sid	security_pkg.T_SID_ID;
v_deleg_user_1_sid			security_pkg.T_SID_ID;
v_deleg_user_2_sid			security_pkg.T_SID_ID;
v_deleg_user_3_sid			security_pkg.T_SID_ID;
v_regs						security_pkg.T_SID_IDS;
v_root_regions				security_pkg.T_SID_IDS;
v_inds						security_pkg.T_SID_IDS;
v_users						security_pkg.T_SID_IDS;

-- Tests
PROCEDURE AutoApproveDCR
AS
	v_act								security_pkg.T_ACT_ID;
	v_app_sid							NUMBER(10);
	v_sheet1_id							security_pkg.T_SID_ID;
	v_sheet2_id							security_pkg.T_SID_ID;
	v_sheet3_id							security_pkg.T_SID_ID;
	v_last_action_id					NUMBER(10);
BEGIN
	unit_test_pkg.StartTest('csr.test_sheet_pkg.AutoApproveDCR');
	
	security.user_pkg.LogonAuthenticated(
		in_sid_id 		=> v_deleg_user_3_sid,
		in_act_timeout 	=> 3600,
		out_act_id		=> v_act
	);
		
	SELECT MIN(sheet_id)
	  INTO v_sheet3_id
	  FROM sheet
	 WHERE delegation_sid = v_sub_sub_delegation_sid;
	
	sheet_pkg.Submit(
		in_act_id 		=> v_act,
		in_sheet_id 	=> v_sheet3_id,
		in_note 		=> 'Random Submit Note',
		in_skip_check 	=> 1
	);
	
	security.user_pkg.LogonAuthenticated(
		in_sid_id 		=> v_deleg_user_2_sid,
		in_act_timeout 	=> 3600,
		out_act_id		=> v_act
	);
		
	sheet_pkg.Accept(
		in_act_id 		=> v_act,
		in_sheet_id 	=> v_sheet3_id,
		in_note 		=> 'Random Accept Note',
		in_skip_check 	=> 1
	);
	
	security.user_pkg.LogonAuthenticated(
		in_sid_id 		=> v_deleg_user_1_sid,
		in_act_timeout 	=> 3600,
		out_act_id		=> v_act
	);
	
	SELECT MIN(sheet_id)
	  INTO v_sheet2_id
	  FROM sheet
	 WHERE delegation_sid = v_sub_delegation_sid;
	
	sheet_pkg.Accept(
		in_act_id 		=> v_act,
		in_sheet_id 	=> v_sheet2_id,
		in_note 		=> 'Random Accept Note',
		in_skip_check 	=> 1
	);
		
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_sheet3_id;
	 
	unit_test_pkg.AssertAreEqual(csr_data_pkg.ACTION_ACCEPTED, v_last_action_id, 'Lowest sheet not set as approved');
	
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_sheet2_id;
	 
	unit_test_pkg.AssertAreEqual(csr_data_pkg.ACTION_ACCEPTED, v_last_action_id, 'Mid sheet not set as approved');
	
	SELECT MIN(sheet_id)
	  INTO v_sheet1_id
	  FROM sheet
	 WHERE delegation_sid = v_delegation_sid;
	
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_sheet1_id;
	 
	unit_test_pkg.AssertAreEqual(csr_data_pkg.ACTION_MERGED, v_last_action_id, 'Top sheet not set as merged');
	
	security.user_pkg.LogonAuthenticated(
		in_sid_id 		=> v_deleg_user_3_sid,
		in_act_timeout 	=> 3600,
		out_act_id		=> v_act
	);
	
	sheet_pkg.ChangeRequest(
		in_act_id 		=> v_act,
		in_sheet_id 	=> v_sheet3_id,
		in_note 		=> 'Random CR Note'
	);
	
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_sheet3_id;
	 
	unit_test_pkg.AssertAreEqual(csr_data_pkg.ACTION_RETURNED, v_last_action_id, 'Lowest sheet not set as returned');
	
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_sheet2_id;
	 
	unit_test_pkg.AssertAreEqual(csr_data_pkg.ACTION_WAITING, v_last_action_id, 'Mid sheet not set as data being entered');
	
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_sheet1_id;
	 
	unit_test_pkg.AssertAreEqual(csr_data_pkg.ACTION_WAITING, v_last_action_id, 'Top sheet not set as data being entered');
END;

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
	
	-- Un-set the Built-in admin's user sid from the session,
	-- otherwise all permissions tests against any ACT will return true
	-- because of the internal workings of security pkgs
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_auditors_grp_sid			NUMBER;
	v_admins_grp_sid			NUMBER;
	v_cap_sid					NUMBER;
	v_cnt						NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	v_inds(1) := unit_test_pkg.GetOrCreateInd('DELEGATION_IND_1');
	
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('DELEG_REGION_1');
	
	v_root_regions(1) := v_regs(1);

	v_auditors_grp_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Auditors');
	v_admins_grp_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Administrators');
	
	-- Enable can delegate capability and grant permission on administrators group.
	csr_data_pkg.enablecapability('Subdelegation');
	csr_data_pkg.enablecapability('Allow users to raise data change requests');
	
	v_cap_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Allow users to raise data change requests');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM security.acl
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_cap_sid)
	   AND sid_id = v_auditors_grp_sid;
	
	IF v_cnt = 0 THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
			v_auditors_grp_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
	
	csr_data_pkg.enablecapability('Automatically approve Data Change Requests');
	
	v_cap_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Automatically approve Data Change Requests');
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM security.acl
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_cap_sid)
	   AND sid_id = v_auditors_grp_sid;
	
	IF v_cnt = 0 THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
			v_auditors_grp_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
	
	v_deleg_user_1_sid := csr.unit_test_pkg.GetOrCreateUser('DELEG_USER_1', v_admins_grp_sid);
	v_deleg_user_2_sid := csr.unit_test_pkg.GetOrCreateUser('DELEG_USER_2', v_auditors_grp_sid);
	v_deleg_user_3_sid := csr.unit_test_pkg.GetOrCreateUser('DELEG_USER_3', v_auditors_grp_sid);
	
	v_users(0) := v_deleg_user_1_sid;
	v_users(1) := v_deleg_user_2_sid;
	v_users(2) := v_deleg_user_3_sid;
	
	v_delegation_sid := unit_test_pkg.GetOrCreateDeleg('DELEG_PERMS_DELEG', v_regs, v_inds);
	
	delegation_pkg.UNSEC_AddUser(
		in_act_id 			=> SYS_CONTEXT('SECURITY','ACT'),
		in_delegation_sid 	=> v_delegation_sid,
		in_user_sid 		=> v_deleg_user_1_sid
	);
	
	delegation_pkg.CreateNonTopLevelDelegation(
		in_parent_sid 			=> v_delegation_sid,
		in_name 				=> 'Sub Deleg',
		in_indicators_list 		=> TO_CHAR(v_inds(1)),
		in_regions_list 		=> TO_CHAR(v_regs(1)),
		in_user_sid_list 		=> TO_CHAR(v_deleg_user_2_sid),
		in_period_set_id 		=> 1,
		in_period_interval_id 	=> 1,
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_note 				=> 'new',
		out_delegation_sid 		=> v_sub_delegation_sid
	);
	
	delegation_pkg.CreateNonTopLevelDelegation(
		in_parent_sid 			=> v_sub_delegation_sid,
		in_name 				=> 'Sub Sub Deleg',
		in_indicators_list 		=> TO_CHAR(v_inds(1)),
		in_regions_list 		=> TO_CHAR(v_regs(1)),
		in_user_sid_list 		=> TO_CHAR(v_deleg_user_3_sid),
		in_period_set_id 		=> 1,
		in_period_interval_id 	=> 1,
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_note 				=> 'new',
		out_delegation_sid 		=> v_sub_sub_delegation_sid
	);
	
	delegation_pkg.CreateSheetsForDelegation(v_delegation_sid);
	delegation_pkg.CreateSheetsForDelegation(v_sub_delegation_sid);
	delegation_pkg.CreateSheetsForDelegation(v_sub_sub_delegation_sid);
	
	COMMIT; -- I hate this but logging on as a user relies on commited data/uses an auton trans.
END;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
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

PROCEDURE GetReminderAlerts
AS
	
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_csr_user_sid					NUMBER;
	v_cur_full_name						VARCHAR2(100);
	v_cur_friendly_name					VARCHAR2(100);
	v_cur_email							VARCHAR2(100);
	v_cur_user_name						VARCHAR2(100);
	v_cur_sheet_id						NUMBER;
	v_cur_sheet_url						VARCHAR2(100);
	v_cur_deleg_assigned_to				VARCHAR2(100);
	v_cur_delegation_name				VARCHAR2(100);
	v_cur_submission_dtm 				DATE;
	v_cur_submission_dtm_fmt			DATE;
	v_cur_start_dtm 					DATE;
	v_cur_end_dtm 						DATE;
	v_cur_period_set_id					NUMBER;
	v_cur_period_interval_id			NUMBER;
	v_cur_for_regions_description		VARCHAR2(100);
	v_cur_region_count 					NUMBER;
	v_cur_region_names					VARCHAR2(100);


	v_count					 			NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.GetReminderAlerts');

	security.user_pkg.logonadmin(v_site_name);

	sheet_pkg.GetReminderAlerts(
		out_cur	=>	v_cur
	);
	
	COMMIT; --To simulate ORA-01002: fetch out of sequence

	LOOP
		FETCH v_cur INTO 
			v_cur_app_sid,
			v_cur_csr_user_sid,
			v_cur_full_name,
			v_cur_friendly_name,
			v_cur_email,
			v_cur_user_name,
			v_cur_sheet_id,
			v_cur_sheet_url,
			v_cur_deleg_assigned_to,
			v_cur_delegation_name,
			v_cur_submission_dtm,
			v_cur_submission_dtm_fmt,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_for_regions_description,
			v_cur_region_count,
			v_cur_region_names
		;
		EXIT WHEN v_cur%NOTFOUND;
	END LOOP;

	--If no exception test is successful
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE GetOverdueAlerts
AS
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_csr_user_sid					NUMBER;
	v_cur_full_name						VARCHAR2(100);
	v_cur_friendly_name					VARCHAR2(100);
	v_cur_email							VARCHAR2(100);
	v_cur_user_name						VARCHAR2(100);
	v_cur_sheet_id						NUMBER;
	v_cur_sheet_url						VARCHAR2(100);
	v_cur_deleg_assigned_to				VARCHAR2(100);
	v_cur_delegation_name				VARCHAR2(100);
	v_cur_submission_dtm 				DATE;
	v_cur_submission_dtm_fmt 			DATE;
	v_cur_start_dtm 					DATE;
	v_cur_end_dtm 						DATE;
	v_cur_period_set_id					NUMBER;
	v_cur_period_interval_id			NUMBER;
	v_cur_region_desc					VARCHAR2(100);
	v_cur_region_count 					NUMBER;
	v_cur_region_names					VARCHAR2(100);

BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_pkg.GetOverdueAlerts');

	security.user_pkg.logonadmin(v_site_name);

	sheet_pkg.GetOverdueAlerts(
		out_cur	=>	v_cur
	);
	
	COMMIT; --To simulate ORA-01002: fetch out of sequence

	LOOP
		FETCH v_cur INTO
			v_cur_app_sid,
			v_cur_csr_user_sid,
			v_cur_full_name,
			v_cur_friendly_name,
			v_cur_email,
			v_cur_user_name,
			v_cur_sheet_id,
			v_cur_sheet_url,
			v_cur_deleg_assigned_to,
			v_cur_delegation_name,
			v_cur_submission_dtm,
			v_cur_submission_dtm_fmt,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_region_desc,
			v_cur_region_count,
			v_cur_region_names
		;
		EXIT WHEN v_cur%NOTFOUND;
	END LOOP;

	--If no exception test is successful
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDownFixture
AS
	v_sids		security.T_SID_TABLE;
	v_count		NUMBER;
BEGIN	
	IF v_sub_sub_delegation_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sub_sub_delegation_sid);
		v_sub_sub_delegation_sid := NULL;
	END IF;
	
	IF v_sub_delegation_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sub_delegation_sid);
		v_sub_delegation_sid := NULL;
	END IF;
	
	IF v_delegation_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_delegation_sid);
		v_delegation_sid := NULL;
	END IF;
	
	RemoveSids(v_regs);
	RemoveSids(v_inds);
	RemoveSids(v_users);
END;

END;
/
