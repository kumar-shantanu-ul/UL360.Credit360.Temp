CREATE OR REPLACE PACKAGE BODY csr.test_delegation_plan_pkg AS

v_site_name					VARCHAR2(200);
v_delegation_sid			security_pkg.T_SID_ID;
v_new_delegation_sid		security_pkg.T_SID_ID;
v_deleg_plan_sid			security_pkg.T_SID_ID;
v_tag_group					security_pkg.T_SID_ID;
v_users						security_pkg.T_SID_IDS;
v_tags						security_pkg.T_SID_IDS;
v_regs						security_pkg.T_SID_IDS;
v_root_regions				security_pkg.T_SID_IDS;
v_inds						security_pkg.T_SID_IDS;
v_new_inds					security_pkg.T_SID_IDS;
v_roles						security_pkg.T_SID_IDS;
v_deleg_plan_cols			security_pkg.T_SID_IDS;
v_empty_templates			security_pkg.T_SID_IDS;
v_empty_roles				security_pkg.T_SID_IDS;
v_new_roles					security_pkg.T_SID_IDS;
v_apply_dynamic				NUMBER := 1;
v_nest_test					BOOLEAN := false;
v_logged_on_user			security_pkg.T_SID_ID;

-- Region Tree
-- v_regs(1) DELEG_PLAN_REGION_1 N
-- ----v_regs(2) DELEG_PLAN_REGION_1_1 P
-- --------v_regs(3) DELEG_PLAN_REGION_1_1_1 N
-- ----v_regs(4) DELEG_PLAN_REGION_1_2 P TAGGED
-- ----v_regs(5) DELEG_PLAN_REGION_1_3 N
-- --------v_regs(6) DELEG_PLAN_REGION_1_3_1 T TAGGED
-- ------------v_regs(7) DELEG_PLAN_REGION_1_3_1_1 T
-- ------------v_regs(8) DELEG_PLAN_REGION_1_3_1_2 P
-- v_regs(9) DELEG_PLAN_REGION_2 N

PROCEDURE ProcessJobIfExists(
	in_plan_name	IN 	VARCHAR2
)
AS
	v_bj_id							NUMBER;
	v_local_deleg_plan_sid			NUMBER;
	v_is_dynamic_plan				NUMBER;
	v_override_dates				NUMBER;
	v_created						NUMBER;
BEGIN
	SELECT MIN(batch_job_id), MIN(dpj.deleg_plan_sid), MIN(is_dynamic_plan), MIN(overwrite_dates)
	  INTO v_bj_id, v_local_deleg_plan_sid, v_is_dynamic_plan, v_override_dates
	  FROM csr.deleg_plan_job dpj
	  JOIN csr.deleg_plan dp ON dpj.deleg_plan_sid = dp.deleg_plan_sid
	 WHERE name = in_plan_name;
	
	unit_test_pkg.AssertNotEqual(NVL(v_bj_id, -1), -1, 'Batch job not created');
	
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_local_deleg_plan_sid,
		in_is_dynamic_plan	=>	v_is_dynamic_plan,
		in_overwrite_dates	=>	v_override_dates,
		out_created			=>	v_created
	);
END;


-- Tests
PROCEDURE SetAsTemplate_False_FailsIfAnyVisibleDelegPlanReference 
AS
	v_deleg_template_cur	SYS_REFCURSOR;
	v_schedule_xml			CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SetAsTemplate_False_FailsIfAnyVisibleDelegPlanReference');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2002-01-01',
		in_end_date			=>	DATE '2003-01-01',
		in_schedule_xml		=>	v_schedule_xml
	);

	-- Add second template
	v_new_delegation_sid := unit_test_pkg.GetOrCreateDeleg('PLAN_DELEG_NEW_TEMPLATE', v_regs, v_new_inds);
	deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 1);
	deleg_plan_pkg.AddDelegToPlan(v_deleg_plan_sid, v_new_delegation_sid, v_deleg_template_cur);
	
	BEGIN
		deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 0);
		
		unit_test_pkg.TestFail('Expecting an Exception here');
	EXCEPTION
		WHEN csr.csr_data_pkg.DELEGATION_USED_AS_TPL THEN
			NULL; -- Expected result
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('Unexpected Exception was thrown');
	END;
END;

PROCEDURE SetAsTemplate_False_SucceedsIfAllDelegPlanReferencesHidden 
AS
	v_deleg_template_cur	SYS_REFCURSOR;
	v_schedule_xml			CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
	v_deleg_plan_col_id 	security_pkg.T_SID_ID;
	v_label 				VARCHAR2(1023);
	v_type 					VARCHAR2(10);
	v_object_sid 			security_pkg.T_SID_ID;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SetAsTemplate_False_SucceedsIfAllDelegPlanReferencesHidden');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2002-01-01',
		in_end_date			=>	DATE '2003-01-01',
		in_schedule_xml		=>	v_schedule_xml
	);

	-- Add second template
	v_new_delegation_sid := unit_test_pkg.GetOrCreateDeleg('PLAN_DELEG_NEW_TEMPLATE', v_regs, v_new_inds);
	deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 1);
	deleg_plan_pkg.AddDelegToPlan(v_deleg_plan_sid, v_new_delegation_sid, v_deleg_template_cur);
	
	FETCH v_deleg_template_cur INTO v_deleg_plan_col_id, v_label, v_type, v_object_sid;
	CLOSE v_deleg_template_cur;
	
	deleg_plan_pkg.DeleteDelegPlanCol(v_deleg_plan_col_id, 0);
	
	deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 0);
END;

PROCEDURE CreateBasicDelegPlan
AS
	v_count				NUMBER(10);
	v_schedule_xml		CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.CreateBasicDelegPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation plan was created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation plan template was created.');
END;

PROCEDURE ApplyDelegationPlanStatic
AS
	v_act				security_pkg.T_ACT_ID;
	v_count				NUMBER(10);
	v_created			NUMBER;
	v_schedule_xml		CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	role_pkg.DeleteAllRolesFromUser(
		in_user_sid 	=> v_users(2)
	);
	
	role_pkg.DeleteAllRolesFromUser(
		in_user_sid 	=> v_users(3)
	);
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegationPlanStatic');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
		in_dynamic			=>	0
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	0,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--No delegations should have been created region : v_regs(1) but there is an issue DE8679, so one is always created for the template owner
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(1, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations regions were created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegations were created.');
	
	role_pkg.AddRoleMemberForRegion(
		in_role_sid		=> v_roles(2),
		in_region_sid	=> v_regs(1),
		in_user_sid 	=> v_users(2)
	);
	
	role_pkg.AddRoleMemberForRegion(
		in_role_sid		=> v_roles(3),
		in_region_sid	=> v_regs(1),
		in_user_sid 	=> v_users(3)
	);
END;

/* 
	Region selection:

	Below options create a delegation with all regions;

	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION		R = select the specified region
	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT		L = select leaf nodes of specified region type (or any)
	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWER_RT		P = select nodes of specified region type (or any)

	Below options create an individual delegation per each region:

	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION		RT = select the specified region
	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT		LT = select leaf nodes of specified region type (or any)
	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT		PT = select nodes of specified region type (or any)
*/
-- Apply plan to single region
PROCEDURE ApplyDelegationPlan
AS
	v_act				security_pkg.T_ACT_ID;
	v_count				NUMBER(10);
	v_created			NUMBER;
	v_schedule_xml		CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegationPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Created delegations for selected region : v_regs(1)
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(3, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations regions were created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(3, v_count, 'Delegations were created.');
END;

-- Rollout behaviours
-- Not a test, reusable procedure that create, applies and checks number of delegations created and number of delegations created per region.
PROCEDURE CreateAndApplyPlan (
	in_root_region				IN	security.security_pkg.T_SID_ID,				
	in_region_selected			IN	security.security_pkg.T_SID_ID,
	in_region_selection			IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_tag_id					IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_region_type				IN	region.region_type%TYPE,
	in_deleg_count				IN	NUMBER,
	in_deleg_regions			IN	security.security_pkg.T_SID_IDS,
	in_deleg_region_counts		IN	security.security_pkg.T_SID_IDS
)
AS
	v_act				security_pkg.T_ACT_ID;
	v_count				NUMBER(10);
	v_created			NUMBER;
	v_schedule_xml		CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_root_regions		security_pkg.T_SID_IDS;
	v_sel_regions		security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);
	
	v_root_regions(1) := in_root_region;
	v_sel_regions(1) := in_region_selected;
	
	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_selected_regions	=>	v_sel_regions,
		in_region_selection	=>	in_region_selection,
		in_tag_id			=>	in_tag_id,
		in_region_type		=>	in_region_type
	);
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	v_apply_dynamic,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	FOR i IN in_deleg_regions.FIRST..in_deleg_regions.LAST
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM delegation_region 
		 WHERE region_sid = in_deleg_regions(i);
	  
		unit_test_pkg.AssertAreEqual(in_deleg_region_counts(i), v_count, 'For region '|| in_deleg_regions(i) || ', ' || v_count || ' delegations regions were created.');
	END LOOP;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(in_deleg_count, v_count, 'Delegations were not created.');
END;

-- Multi form, this, any region type, without Tag
PROCEDURE MultiThisRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiThisRTAnyWithoutTag');
	END IF;
	
	v_regions(1) := v_regs(1);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lower, any region type, without Tag
PROCEDURE MultiLowerRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowerRTAnyWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(1);
	v_region_counts(1) := 0;
	v_regions(2) := v_regs(2);
	v_region_counts(2) := 0;
	v_regions(3) := v_regs(3);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(4);
	v_region_counts(4) := v_roles.COUNT;
	v_regions(5) := v_regs(5);
	v_region_counts(5) := 0;
	v_regions(6) := v_regs(6);
	v_region_counts(6) := 0;
	v_regions(7) := v_regs(7);
	v_region_counts(7) := v_roles.COUNT;
	v_regions(8) := v_regs(8);
	v_region_counts(8) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT*4,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lowest, any region type, without Tag
PROCEDURE MultiLowestRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowestRTAnyWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(3);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(2) := v_regs(4);
	v_region_counts(2) := v_roles.COUNT;
	v_regions(3) := v_regs(7);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(8);
	v_region_counts(4) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT*4,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, this, specific region type, without Tag
PROCEDURE MultiThisRTTenantWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiThisRTTenantWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(6),
		in_region_selected		=>	v_regs(6),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lower, specific region type, without Tag
PROCEDURE MultiLowerRTTenantWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowerRTTenantWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(6);
	v_region_counts(1) := 0;
	v_regions(2) := v_regs(7);
	v_region_counts(2) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lowest, specific region type, without Tag
PROCEDURE MultiLowestRTTenantWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowestRTTenantWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(7);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, this, any region type, with Tag
PROCEDURE MultiThisRTAnyWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiThisRTAnyWithTag');
	END IF;
		
	v_regions(1) := v_regs(4);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(4),
		in_region_selected		=>	v_regs(4),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lower, any region type, with Tag
PROCEDURE MultiLowerRTAnyWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowerRTAnyWithTag');
	END IF;
		
	v_regions(1) := v_regs(4);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT*2,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lowest, any region type, with Tag
PROCEDURE MultiLowestRTAnyWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowestRTAnyWithTag');
	END IF;
		
	v_regions(1) := v_regs(3);
	v_region_counts(1) := 0;
	v_regions(2) := v_regs(4);
	v_region_counts(2) := v_roles.COUNT;
	v_regions(3) := v_regs(7);
	v_region_counts(3) := 0;
	v_regions(4) := v_regs(8);
	v_region_counts(4) := 0;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, this, specific region type, with Tag
PROCEDURE MultiThisRTTenantWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiThisRTTenantWithTag');
	END IF;
	
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(6),
		in_region_selected		=>	v_regs(6),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lower, specific region type, with Tag
PROCEDURE MultiLowerRTTenantWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowerRTTenantWithTag');
	END IF;
		
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Multi form, lowest, specific region type, with Tag
PROCEDURE MultiLowestRTTenantWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.MultiLowestRTTenantWithTag');
	END IF;
		
	v_regions(1) := v_regs(6);
	v_region_counts(1) := 0;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	0,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, this, any region type, without Tag
PROCEDURE SingleThisRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleThisRTAnyWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(1);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lower, any region type, without Tag
PROCEDURE SingleLowerRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowerRTAnyWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(1);
	v_region_counts(1) := 0;
	v_regions(2) := v_regs(2);
	v_region_counts(2) := 0;
	v_regions(3) := v_regs(3);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(4);
	v_region_counts(4) := v_roles.COUNT;
	v_regions(5) := v_regs(5);
	v_region_counts(5) := 0;
	v_regions(6) := v_regs(6);
	v_region_counts(6) := 0;
	v_regions(7) := v_regs(7);
	v_region_counts(7) := v_roles.COUNT;
	v_regions(8) := v_regs(8);
	v_region_counts(8) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lowest, any region type, without Tag
PROCEDURE SingleLowestRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowestRTAnyWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(3);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(2) := v_regs(4);
	v_region_counts(2) := v_roles.COUNT;
	v_regions(3) := v_regs(7);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(8);
	v_region_counts(4) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, this, specific region type, without Tag
PROCEDURE SingleThisRTTenantWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleThisRTTenantWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(7);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(7),
		in_region_selected		=>	v_regs(7),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lower, specific region type, without Tag
PROCEDURE SingleLowerRTTenantWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowerRTTenantWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(7);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lowest, specific region type, without Tag
PROCEDURE SingleLowestRTTenantWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowestRTTenantWithoutTag');
	END IF;
		
	v_regions(1) := v_regs(7);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, this, any region type, with Tag
PROCEDURE SingleThisRTAnyWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleThisRTAnyWithTag');
	END IF;
		
	v_regions(1) := v_regs(4);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(4),
		in_region_selected		=>	v_regs(4),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lower, any region type, with Tag
PROCEDURE SingleLowerRTAnyWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowerRTAnyWithTag');
	END IF;
		
	v_regions(1) := v_regs(4);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWER_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lowest, any region type, with Tag
PROCEDURE SingleLowestRTAnyWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowestRTAnyWithTag');
	END IF;
		
	v_regions(1) := v_regs(4);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, this, specific region type, with Tag
PROCEDURE SingleThisRTTenantWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleThisRTTenantWithTag');
	END IF;
		
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(6),
		in_region_selected		=>	v_regs(6),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lower, specific region type, with Tag
PROCEDURE SingleLowerRTTenantWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowerRTTenantWithTag');
	END IF;
		
	v_regions(1) := v_regs(6);
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWER_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- Single form, lowest, specific region type, with Tag
PROCEDURE SingleLowestRTTenantWithTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.SingleLowestRTTenantWithTag');
	END IF;
	
	v_regions(1) := v_regs(6);
	v_region_counts(1) := 0;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT,
		in_deleg_count			=>	0,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
END;
-- end rollout behaviours
-- Change rollouts
PROCEDURE LowestToLowerAny
AS
	v_regions			security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.LowestToLowerAny');
	v_nest_test := true;
	
	v_regions(1) := v_regs(1);
	MultiLowestRTAnyWithoutTag;
	unit_test_pkg.SetSelectionForDelegPlan(
		in_name					=>	'DELEGATION_PLAN',
		in_root_regions			=>	v_regions,
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL
	);
	MultiLowerRTAnyWithoutTag;	
	v_nest_test := false;
END;

PROCEDURE LowerToLowestAny
AS
	v_regions			security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.LowerToLowestAny');
	v_nest_test := true;
	
	v_regions(1):= v_regs(1);
	MultiLowerRTAnyWithoutTag;
	unit_test_pkg.SetSelectionForDelegPlan(
		in_name					=>	'DELEGATION_PLAN',
		in_root_regions			=>	v_regions,
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL
	);
	MultiLowestRTAnyWithoutTag;
	v_nest_test := false;
END;

PROCEDURE LowestToLowerRT
AS
	v_regions			security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.LowestToLowerRT');
	v_nest_test := true;
	
	v_regions(1) := v_regs(1);
	MultiLowestRTTenantWithoutTag;
	unit_test_pkg.SetSelectionForDelegPlan(
		in_name					=>	'DELEGATION_PLAN',
		in_root_regions			=>	v_regions,
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT
	);
	MultiLowerRTTenantWithoutTag;
	v_nest_test := false;
END;

PROCEDURE LowerToLowestRT
AS
	v_regions			security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.LowerToLowestRT');
	v_nest_test := true;
	
	v_regions(1) := v_regs(1);
	MultiLowerRTTenantWithoutTag;
	unit_test_pkg.SetSelectionForDelegPlan(
		in_name					=>	'DELEGATION_PLAN',
		in_root_regions			=>	v_regions,
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT
	);
	MultiLowestRTTenantWithoutTag;
	v_nest_test := false;
END;

PROCEDURE LowestToLowerTag
AS
	v_regions			security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.LowestToLowerTag');
	v_nest_test := true;
	
	v_regions(1) := v_regs(1);
	MultiLowestRTTenantWithTag;
	unit_test_pkg.SetSelectionForDelegPlan(
		in_name					=>	'DELEGATION_PLAN',
		in_root_regions			=>	v_regions,
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT
	);
	MultiLowerRTTenantWithTag;
	v_nest_test := false;	
END;

PROCEDURE LowerToLowestTag
AS
	v_regions			security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.LowerToLowestTag');
	v_nest_test := true;
	
	v_regions(1) := v_regs(1);
	MultiLowerRTTenantWithTag;
	unit_test_pkg.SetSelectionForDelegPlan(
		in_name					=>	'DELEGATION_PLAN',
		in_root_regions			=>	v_regions,
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	v_tags(1),
		in_region_type			=>	CSR_DATA_PKG.REGION_TYPE_TENANT
	);
	MultiLowestRTTenantWithTag;
	v_nest_test := false;
END;

-- Date and periods tests
PROCEDURE CreateDelegPlanWithRecDates
AS
	v_count				NUMBER(10);
	v_schedule_xml		CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.CreateDelegPlanWithRecDates');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml
	);

	--Change recurring schedule per role
 	v_schedule_xml := '<recurrence><yearly every-n="1"><day number="2" month="jan"/></yearly></recurrence>';
 	
	unit_test_pkg.SetScheduleForDelegPlan(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_deleg_templates	=>	v_empty_templates,
		in_roles			=>	v_roles,
		in_schedule_xml		=>	v_schedule_xml,
		in_reminder_offset	=>	10
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_date_schedule
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	unit_test_pkg.AssertAreEqual(3, v_count, 'Delegation plan schedule for each role was created.');

	FOR i IN v_roles.FIRST..v_roles.LAST
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM deleg_plan_date_schedule
		 WHERE deleg_plan_sid = v_deleg_plan_sid
		   AND role_sid = v_roles(i)
		 GROUP BY role_sid;
	
		unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation plan schedule for role '|| v_roles(i) ||' was created.');
	END LOOP;
END;


PROCEDURE CreateDelegPlanWithFixDates (
	in_start_dtm					IN DATE DEFAULT DATE '2018-01-01',
	in_end_dtm						IN DATE DEFAULT DATE '2019-01-01',
	in_period_set_id				IN NUMBER DEFAULT 1,
	in_period_interval_id			IN NUMBER DEFAULT 4
)	
AS
	v_count_start					NUMBER(10);
	v_count_end						NUMBER(10);
	v_interval_members				NUMBER(10);
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.CreateDelegPlanWithFixDates');
	END IF;
	
	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	in_start_dtm,
		in_end_date				=>	in_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	in_period_set_id,
		in_period_interval_id	=>	in_period_interval_id
	);
	
	SELECT COUNT(*)
	  INTO v_count_start
	  FROM sheet_date_schedule;
	
	-- Change to fixed dates per role
	-- 3 roles x 1 template x 1(Annual)
	-- 3 sheet should be generated
	-- This needs user input in the UI to set dates. To reproduce that, this is using inserts to a temp table
	-- that will then get picked up from unit_test_pkg.SetScheduleForDelegPlan
	EXECUTE IMMEDIATE 'INSERT INTO temp_deleg_test_schedule_entry (role_sid, deleg_plan_col_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm)
					   VALUES ( '|| v_roles(1)||', NULL, DATE '''||TO_CHAR(in_start_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_start_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_end_dtm + 10, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_end_dtm, 'YYYY-MM-DD')||''')';
	EXECUTE IMMEDIATE 'INSERT INTO temp_deleg_test_schedule_entry (role_sid, deleg_plan_col_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm)
					   VALUES ( '|| v_roles(2)||', NULL, DATE '''||TO_CHAR(in_start_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_start_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_end_dtm + 5, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_end_dtm - 5, 'YYYY-MM-DD')||''')';
	EXECUTE IMMEDIATE 'INSERT INTO temp_deleg_test_schedule_entry (role_sid, deleg_plan_col_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm)
					   VALUES ( '|| v_roles(3)||', NULL, DATE '''||TO_CHAR(in_start_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_start_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_end_dtm, 'YYYY-MM-DD')||''', DATE '''||TO_CHAR(in_end_dtm - 10, 'YYYY-MM-DD')||''')';
	
	
	unit_test_pkg.SetScheduleForDelegPlan(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_deleg_templates	=>	v_empty_templates,
		in_roles			=>	v_roles
	);
	
	SELECT COUNT(*)
	  INTO v_interval_members
	  FROM period_interval_member
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id;
	
	SELECT COUNT(*)
	  INTO v_count_end
	  FROM sheet_date_schedule;
	
	unit_test_pkg.AssertAreEqual(3 * v_interval_members, (v_count_end - v_count_start), 'Delegation date scheduled entries were created.');
END;

PROCEDURE CreateDelegPlanForCustomPeriod
AS
	v_count							NUMBER(10);
	v_period_set_id					NUMBER(10);
	v_created						NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_start_dtm						DATE;
	v_end_dtm						DATE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.CreateDelegPlanForCustomPeriod');

	v_period_set_id := unit_test_pkg.GetOrCreatePeriodSet;
	
	SELECT pds.start_dtm, pde.end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM period_interval_member pim
	  JOIN period_dates pds ON pds.period_id = pim.start_period_id AND pds.year = '2018'
	  JOIN period_dates pde ON pde.period_id = pim.end_period_id AND pde.year = '2018'
	 WHERE pim.period_set_id = v_period_set_id
	   AND pim.period_interval_id = 4; -- Assuming 4 is Yearly
	
	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_start_dtm,
		in_end_date				=>	v_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=>	v_period_set_id,
		in_period_interval_id	=>	2 -- Assuming 2 is Quarterly 
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan dp
	  JOIN deleg_plan_date_schedule ds ON dp.deleg_plan_sid = ds.deleg_plan_sid
	  JOIN sheet_date_schedule ss ON ds.delegation_date_schedule_id = ss.delegation_date_schedule_id
	  JOIN period_interval_member pim ON dp.period_set_id = pim.period_set_id AND dp.period_interval_id = pim.period_interval_id
	  JOIN period_dates pds ON pds.period_id = pim.start_period_id AND pds.year = '2018' AND pds.start_dtm = ss.start_dtm
	  JOIN period_dates pde ON pde.period_id = pim.end_period_id AND pde.year = '2018' AND pde.end_dtm = ss.submission_dtm
	 WHERE dp.deleg_plan_sid = v_deleg_plan_sid;
	
	unit_test_pkg.AssertAreEqual(4, v_count, 'Delegation schedule has incorrect date for custom period.');
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	FOR drow IN (	
		SELECT period_set_id, period_interval_id 
		  FROM delegation
		 WHERE master_delegation_sid = v_delegation_sid
	) LOOP
		unit_test_pkg.AssertAreEqual(v_period_set_id, drow.period_set_id, 'Period set is incorrect on delegation.');
		unit_test_pkg.AssertAreEqual(2, drow.period_interval_id, 'Period interval is incorrect on delegation.');
	END LOOP;
	
	FOR srow IN (
		SELECT s.submission_dtm s1, s.reminder_dtm r1, sds.submission_dtm s2, sds.reminder_dtm r2
		  FROM delegation d
		  JOIN sheet s ON s.delegation_sid = d.delegation_sid
		  JOIN delegation_date_schedule dds ON d.delegation_date_schedule_id = dds.delegation_date_schedule_id
		  JOIN sheet_date_schedule sds ON dds.delegation_date_schedule_id = sds.delegation_date_schedule_id AND s.start_dtm = sds.start_dtm
		 WHERE master_delegation_sid = v_delegation_sid
	) LOOP
		unit_test_pkg.AssertAreEqual(srow.s2, srow.s1, 'Submission sheet date not set to custom date.');
		unit_test_pkg.AssertAreEqual(srow.r2, srow.r1, 'Reminder sheet date not set to custom date.');
	END LOOP;
END;

PROCEDURE CreateDPForCPComplex
AS
	v_count							NUMBER(10);
	v_period_set_id					NUMBER(10);
	v_created						NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_start_dtm						DATE;
	v_end_dtm						DATE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.CreateDelegPlanForCustomPeriodComplex');

	v_period_set_id := unit_test_pkg.GetOrCreatePeriodSet;
	
	SELECT pds.start_dtm, pde.end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM period_interval_member pim
	  JOIN period_dates pds ON pds.period_id = pim.start_period_id AND pds.year = '2018'
	  JOIN period_dates pde ON pde.period_id = pim.end_period_id AND pde.year = '2018'
	 WHERE pim.period_set_id = v_period_set_id
	   AND pim.period_interval_id = 4; -- Assuming 4 is Yearly
	
	v_nest_test := true;
	CreateDelegPlanWithFixDates (
		in_start_dtm			=>	v_start_dtm,
		in_end_dtm				=>	v_end_dtm,
		in_period_set_id		=>	v_period_set_id,
		in_period_interval_id	=>	4
	);
	v_nest_test := false;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan dp
	  JOIN deleg_plan_date_schedule ds ON dp.deleg_plan_sid = ds.deleg_plan_sid
	  JOIN sheet_date_schedule ss ON ds.delegation_date_schedule_id = ss.delegation_date_schedule_id
	  JOIN period_interval_member pim ON dp.period_set_id = pim.period_set_id AND dp.period_interval_id = pim.period_interval_id
	 WHERE dp.deleg_plan_sid = v_deleg_plan_sid
	   AND role_sid IS NOT NULL;
	
	unit_test_pkg.AssertAreEqual(3, v_count, 'Delegation schedule has incorrect date for custom period.');
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	FOR drow IN (	
		SELECT period_set_id, period_interval_id 
		  FROM delegation
		 WHERE master_delegation_sid = v_delegation_sid
	) LOOP
		unit_test_pkg.AssertAreEqual(v_period_set_id, drow.period_set_id, 'Period set is incorrect on delegation.');
		unit_test_pkg.AssertAreEqual(4, drow.period_interval_id, 'Period interval is incorrect on delegation.');
	END LOOP;
	
	FOR srow IN (
		SELECT s.submission_dtm s1, s.reminder_dtm r1, sds.submission_dtm s2, sds.reminder_dtm r2
		  FROM delegation d
		  JOIN sheet s ON s.delegation_sid = d.delegation_sid
		  JOIN delegation_date_schedule dds ON d.delegation_date_schedule_id = dds.delegation_date_schedule_id
		  JOIN sheet_date_schedule sds ON dds.delegation_date_schedule_id = sds.delegation_date_schedule_id AND s.start_dtm = sds.start_dtm
		 WHERE master_delegation_sid = v_delegation_sid
	) LOOP
		unit_test_pkg.AssertAreEqual(srow.s2, srow.s1, 'Submission sheet date not set to custom date.');
		unit_test_pkg.AssertAreEqual(srow.r2, srow.r1, 'Reminder sheet date not set to custom date.');
	END LOOP;

	FOR srow IN (
		SELECT sds.submission_dtm s1, sds.reminder_dtm r1, sds2.submission_dtm s2, sds2.reminder_dtm r2
		  FROM delegation d
		  JOIN delegation_role dr ON d.delegation_sid = dr.delegation_sid AND dr.inherited_from_sid = d.delegation_sid
		  JOIN sheet_date_schedule sds ON d.delegation_date_schedule_id = sds.delegation_date_schedule_id
		  JOIN sheet_date_schedule sds2 ON sds.start_dtm = sds2.start_dtm
		  JOIN deleg_plan_date_schedule dps ON sds2.delegation_date_schedule_id = dps.delegation_date_schedule_id AND dps.role_sid = dr.role_sid
		 WHERE d.master_delegation_sid = v_delegation_sid
		   AND dps.deleg_plan_sid = v_deleg_plan_sid
	) LOOP
		unit_test_pkg.AssertAreEqual(srow.s2, srow.s1, 'Submission sheet date not set to role custom date.');
		unit_test_pkg.AssertAreEqual(srow.r2, srow.r1, 'Reminder sheet date not set to role custom date.');
	END LOOP;	
	
END;

PROCEDURE ApplyDelegRecDatesPerTemplate
AS
	v_count					NUMBER(10);
	v_deleg_template_cur	SYS_REFCURSOR;
	v_deleg_plan_col_id		NUMBER(10);
	v_created				NUMBER;
	v_udpated_schedule_xml	CLOB;
	v_schedule_xml			CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegRecDatesPerTemplate');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2002-01-01',
		in_end_date			=>	DATE '2003-01-01',
		in_schedule_xml		=>	v_schedule_xml
	);

	-- Add second template
	v_new_delegation_sid := unit_test_pkg.GetOrCreateDeleg('PLAN_DELEG_NEW_TEMPLATE', v_regs, v_new_inds);
	deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 1);
	deleg_plan_pkg.AddDelegToPlan(v_deleg_plan_sid, v_new_delegation_sid, v_deleg_template_cur);

	-- Make selection 
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND delegation_sid = v_new_delegation_sid;

	deleg_plan_pkg.UpdateDelegPlanColRegion(v_deleg_plan_col_id, v_regs(1), CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION, NULL, NULL);  
 
	--Change recurring schedule per template
 	v_schedule_xml := '<recurrence><yearly every-n="1"><day number="3" month="jan"/></yearly></recurrence>';
	
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_cols(1)
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND delegation_sid = v_delegation_sid;

	v_deleg_plan_cols(2) := v_deleg_plan_col_id;
	
	unit_test_pkg.SetScheduleForDelegPlan(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_deleg_templates	=>	v_deleg_plan_cols,
		in_roles			=>	v_empty_roles,
		in_schedule_xml		=>	v_schedule_xml,
		in_reminder_offset	=>	8
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_date_schedule
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Delegation plan schedule for each template was created.');

	FOR i IN v_deleg_plan_cols.FIRST..v_deleg_plan_cols.LAST
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM deleg_plan_date_schedule
		 WHERE deleg_plan_sid = v_deleg_plan_sid
		   AND deleg_plan_col_id = v_deleg_plan_cols(i)
		 GROUP BY deleg_plan_col_id;
	
		unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation plan schedule for role '|| v_deleg_plan_cols(i) ||' was created.');
	END LOOP;

	--Apply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert that generated delegations now have the new schedule
	SELECT schedule_xml
	  INTO v_schedule_xml
	  FROM delegation
	 WHERE master_delegation_sid IN (v_delegation_sid, v_new_delegation_sid)
	   AND ROWNUM = 1;

	v_udpated_schedule_xml := '<recurrences><yearly every-n="1"><day number="3" month="jan"/></yearly></recurrences>';

	FOR r IN (
		SELECT schedule_xml
		  FROM delegation
		 WHERE master_delegation_sid IN (v_delegation_sid, v_new_delegation_sid)
	)
	LOOP
		unit_test_pkg.AssertAreEqual(v_udpated_schedule_xml, r.schedule_xml, 'Delegation plan schedule was updated');
	END LOOP;
END;


PROCEDURE ApplyDelegFixDatesPerRole
AS
	v_count					NUMBER(10);
	v_created				NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegFixDatesPerRole');

	--Create delegation with fix dates per role
	v_nest_test := true;
	CreateDelegPlanWithFixDates;
	v_nest_test := false;

	--Apply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	1,
		out_created			=>	v_created
	);
	
	-- Get count of sheet date schedules where the plan dates equal the delegation's dates.
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.deleg_plan dp
	  JOIN csr.deleg_plan_date_schedule ds ON dp.deleg_plan_sid = ds.deleg_plan_sid
	  JOIN csr.sheet_date_schedule ss ON ds.delegation_date_schedule_id = ss.delegation_date_schedule_id
	  JOIN csr.sheet_date_schedule ss2 ON ss.start_dtm = ss2.start_dtm AND ss.creation_dtm = ss2.creation_dtm AND ss.reminder_dtm = ss2.reminder_dtm
	  JOIN csr.delegation d ON ss2.delegation_date_schedule_id = d.delegation_date_schedule_id;

	unit_test_pkg.AssertAreEqual(3, v_count, 'Delegation date scheduled entries were duplicated?');
END;

PROCEDURE ReApplyDelegationPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_updated_reminder_offset	NUMBER;
	v_updated_schedule_xml		CLOB;
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ReApplyDelegationPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Created delegations same region : v_regs(1)
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations regions were created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations were created.');

	--Re Apply plan shouldn't remove delegations and update date if date override was selected
	
	--Change dates
	deleg_plan_pkg.DeleteDelegPlanDateSchedules(v_deleg_plan_sid);
	
	v_schedule_xml := '<recurrence><yearly every-n="1"><day number="2" month="jan"/></yearly></recurrence>';
 	
	unit_test_pkg.SetScheduleForDelegPlan(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_deleg_templates	=>	v_empty_templates,
		in_roles			=>	v_roles,
		in_schedule_xml		=>	v_schedule_xml,
		in_reminder_offset	=>	10
	);

	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	1,
		out_created			=>	v_created
	);

	--Assert delegations weren't removed
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.delegation_region 
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations still exist.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations still exist.');
	
	--Assert delegation dates were updated
	SELECT reminder_offset, schedule_xml
	  INTO v_updated_reminder_offset, v_updated_schedule_xml
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid
	   AND ROWNUM = 1;

	--Delegations use recurrences instead of recurrence as in delegation plan
	v_schedule_xml := '<recurrences><yearly every-n="1"><day number="2" month="jan"/></yearly></recurrences>'; 
	
	unit_test_pkg.AssertAreEqual(10, v_updated_reminder_offset, 'Reminder offset was udpated for delegations');
	unit_test_pkg.AssertAreEqual(v_schedule_xml, v_updated_schedule_xml, 'Schedule was udpated for delegations');
END;

-- Template delegation tests
PROCEDURE AddDelegTemplateToDelegPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_deleg_template_cur		SYS_REFCURSOR;
	v_deleg_plan_col_id			NUMBER(10);
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.AddDelegTemplateToDelegPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	--Created delegations region : v_regs(1)
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1) || ', ' || v_count || ' delegations regions were created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations were created.');

	--Re Apply plan shouldn't remove delegations of existing templates, if we added a new template

	-- Add template	
	v_new_delegation_sid := unit_test_pkg.GetOrCreateDeleg('PLAN_DELEG_NEW_TEMPLATE', v_regs, v_new_inds);
	deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 1);
	deleg_plan_pkg.AddDelegToPlan(v_deleg_plan_sid, v_new_delegation_sid, v_deleg_template_cur);

	-- Make selection 
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_deleg_id = (SELECT deleg_plan_col_deleg_id
									    FROM deleg_plan_col_deleg
									   WHERE delegation_sid = v_new_delegation_sid);

	deleg_plan_pkg.UpdateDelegPlanColRegion(v_deleg_plan_col_id , v_regs(1), CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION, NULL, NULL);  

	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert delegation were added for new template
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT*2, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations were created.');
END;

PROCEDURE RemoveTemplateFromPlanNoData
AS
	v_count						NUMBER(10);
	v_deleg_plan_col_id			NUMBER(10);
BEGIN
	--Create the plan with two templates
	AddDelegTemplateToDelegPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveTemplateFromPlanNoData');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT*2, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations existed.');
	
	--Remove one template
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_deleg_id = (SELECT deleg_plan_col_deleg_id
									    FROM deleg_plan_col_deleg
									   WHERE delegation_sid = v_new_delegation_sid);
									   
	deleg_plan_pkg.DeleteDelegPlanCol(v_deleg_plan_col_id, 1);

	--Assert that the delegation were reduced to 3
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations were removed.');
END;

PROCEDURE RemoveTemplFromPlanWithData_
AS
	v_count						NUMBER(10);
	v_deleg_plan_col_id			NUMBER(10);
	v_generated_sheet			NUMBER(10);
	v_var_expl_ids				security_pkg.T_SID_IDS;
	v_changed_inds				SYS_REFCURSOR;
	v_created					NUMBER;
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	--Create the plan with two templates
	AddDelegTemplateToDelegPlan;
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveTemplFromPlanWithData');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT*2, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations existed.');

	--Get one of generated sheets and insert value
	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(1) AND ROWNUM = 1)
	   AND ROWNUM = 1;

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(1),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);

	--Remove one template
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_deleg_id = (SELECT deleg_plan_col_deleg_id
									    FROM deleg_plan_col_deleg
									   WHERE delegation_sid = v_new_delegation_sid);
									   
	deleg_plan_pkg.DeleteDelegPlanCol(v_deleg_plan_col_id, 1);

	--Assert that the delegation sheet with values was not removed
	SELECT COUNT(*)
	  INTO v_count
	  FROM sheet
	 WHERE sheet_id = v_generated_sheet;
	
	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation sheet with values was not removed');
END;

PROCEDURE HideTemplateFromPlan
AS
	v_count						NUMBER(10);
	v_deleg_plan_col_id			NUMBER(10);
	v_created					NUMBER;
BEGIN
	--Create the plan with two templates
	AddDelegTemplateToDelegPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.HideTemplateFromPlan');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(6, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations existed.');
	
	--Hide one template
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_deleg_id = (SELECT deleg_plan_col_deleg_id
									    FROM deleg_plan_col_deleg
									   WHERE delegation_sid = v_new_delegation_sid);

	deleg_plan_pkg.DeleteDelegPlanCol(v_deleg_plan_col_id, 0);

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT*2, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegation remain after hiding template.');
	
	-- Reapplying the plan removes the delegations if template has been removed
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert that the delegation were not removed
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations are removed if applying plan again.');
END;

-- Overlap tests
PROCEDURE ApplyDelegIndicatorWithOverlap
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_old_count					NUMBER(10);
	v_new_count					NUMBER(10);
	v_created					NUMBER;
	v_deleg_template_cur		SYS_REFCURSOR;
	v_deleg_plan_col_id			NUMBER(10);
	v_deleg_plan_col_deleg_id	NUMBER(10);
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegIndicatorWithOverlap');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	unit_test_pkg.AssertAreEqual(1, v_created, 'Nothing created');
	
	--Created delegations region : v_regs(1)
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations regions were created.');

	--Re Apply plan shouldn't add new delegations if there is indicator overlap

	-- Add template	
	v_new_delegation_sid := unit_test_pkg.GetOrCreateDeleg('PLAN_DELEG_NEW_TEMPLATE', v_regs, v_inds);
	deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 1);
	deleg_plan_pkg.AddDelegToPlan(v_deleg_plan_sid, v_new_delegation_sid, v_deleg_template_cur);

	-- Make selection 
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_deleg_id = (SELECT deleg_plan_col_deleg_id
									    FROM deleg_plan_col_deleg
									   WHERE delegation_sid = v_new_delegation_sid);

	deleg_plan_pkg.UpdateDelegPlanColRegion(v_deleg_plan_col_id , v_regs(1), CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION, NULL, NULL);  

	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert delegations weren't added since there is indicator overlap
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	  WHERE region_sid = v_regs(1);
	 
	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.temp_deleg_plan_overlap
	 WHERE tpl_deleg_sid = v_new_delegation_sid;
	 
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(1)|| ', ' || v_count || ' delegations remain.');
	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Overlap should be recorded.');
END;

PROCEDURE ApplyDelegRegionWithOverlap
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_old_count					NUMBER(10);
	v_new_count					NUMBER(10);
	v_created					NUMBER;
	v_deleg_template_cur		SYS_REFCURSOR;
	v_deleg_plan_col_id			NUMBER(10);
	v_deleg_plan_col_deleg_id	NUMBER(10);
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';

BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegRegionWithOverlap');

	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.temp_deleg_plan_overlap;

	v_new_delegation_sid := unit_test_pkg.GetOrCreateDeleg('DELEG_OVERLAP', v_root_regions, v_inds);

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2010-01-01',
		in_end_date			=>	DATE '2011-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--No delegations should have been created since there is region overlap
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation 
	 WHERE master_delegation_sid = v_delegation_sid;

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.temp_deleg_plan_overlap;

	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(1)|| ', no delegations were created from the plan.');
	unit_test_pkg.AssertAreEqual(v_old_count +1 , v_new_count, 'Overlap Count should be incremented.');
END;

PROCEDURE ApplyDelegRegionWithOverlapRemovesOverlapWhenRelinked
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_old_count					NUMBER(10);
	v_new_count					NUMBER(10);
	v_created					NUMBER;
	v_deleg_template_cur		SYS_REFCURSOR;
	v_deleg_plan_col_id			NUMBER(10);
	v_deleg_plan_col_deleg_id	NUMBER(10);
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';

BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegRegionWithOverlapRemovesOverlapWhenRelinked');

	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.temp_deleg_plan_overlap;

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2010-01-01',
		in_end_date			=>	DATE '2011-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	unit_test_pkg.AssertAreEqual(1, v_created, 'No delegation is created.');
	
	deleg_plan_pkg.DeleteDelegPlan(
		in_deleg_plan_sid	=> v_deleg_plan_sid,
		in_all				=> 0
	);
	
	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2010-01-01',
		in_end_date			=>	DATE '2011-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);
	
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	unit_test_pkg.AssertAreEqual(0, v_created, 'Delegation was created.');
	
	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.temp_deleg_plan_overlap;

	unit_test_pkg.AssertAreEqual(v_old_count, v_new_count, 'Overlap Count should be the same.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_deleg_region_deleg d_d
	  JOIN deleg_plan_col dpc ON d_d.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
	 WHERE dpc.deleg_plan_sid = v_deleg_plan_sid;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation not relinked to plan.');
END;

-- Region Tests
PROCEDURE AddRegionToDelegPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.AddRegionToDelegPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--There should be 12 delegations generated 4 regions x 3 roles
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertAreEqual(v_roles.COUNT*4, v_count,  v_count || 'delegations were created, 3 for each region.');
	
	--Add region to region used in plan, should create delegations

	--Add lowest level region
	
	v_regs(10) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_4', v_regs(1));
	
	ProcessJobIfExists('DELEGATION_PLAN');

	--Assert delegation was created for new region 
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(10);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(10)|| ', ' || v_count || ' were created.');

	-- There should be 15 delegations generated 5 regions x 3 roles
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertAreEqual(v_roles.COUNT*5, v_count,  v_count || 'delegations were created, 3 for each region.');
END;

PROCEDURE DeselectRegionFromDelPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB := '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_deleg_plan_col_id			NUMBER(10);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.DeselectRegionFromDelPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2001-01-01',
		in_end_date			=>	DATE '2002-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Deselecting a region used in plan, should remove delegations

	--Deselect region
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND delegation_sid = v_delegation_sid;

	deleg_plan_pkg.UpdateDelegPlanColRegion(v_deleg_plan_col_id, v_regs(1), NULL, NULL, NULL);  
	
	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert delegations were not removed
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(1)|| ', all delegations were removed.');
END;

PROCEDURE DeselectRegWithDataFromDelPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB := '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_changed_inds				SYS_REFCURSOR;
	v_generated_sheet			NUMBER(10);
	v_var_expl_ids				security_pkg.T_SID_IDS;
	v_deleg_plan_col_id			NUMBER(10);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.DeselectRegWithDataFromDelPlan');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2001-01-01',
		in_end_date			=>	DATE '2002-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Get one of generated sheets and insert value
	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(1) AND ROWNUM = 1)
	   AND ROWNUM = 1;
	  
	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(1),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	--Deselecting a region used in plan, should not remove delegations with data

	--Deselect region
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND delegation_sid = v_delegation_sid;

	deleg_plan_pkg.UpdateDelegPlanColRegion(v_deleg_plan_col_id , v_regs(1), NULL, NULL, NULL);  

	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert delegations were not removed
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	  WHERE region_sid = v_regs(1);

	unit_test_pkg.AssertNotEqual(0, v_count, 'For region '|| v_regs(1)|| ', delegations were not removed.');
END;

PROCEDURE RemoveRegionFromDelegPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB := '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_single_region				security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveRegionFromDelegPlan');
	
	v_regs(10) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_4', v_regs(1));
	
	v_single_region(1) := v_regs(10);

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_single_region,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(10);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(10)|| ', ' || v_count || ' delegations regions were created.');

	--Remove region used in plan, should remove delegations and sheets
	--Remove region 
	region_pkg.TrashObject(security_pkg.getact, v_regs(10));

	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert delegations were removed
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.delegation_region 
	  WHERE region_sid = v_regs(10);

	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(10)|| ', all delegations were removed.');
END;

PROCEDURE RemoveRegWithDataFromDelPlan
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB := '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_single_region				security_pkg.T_SID_IDS;
	v_changed_inds				SYS_REFCURSOR;
	v_generated_sheet			NUMBER(10);
	v_var_expl_ids				security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveRegWithDataFromDelPlan');

	v_single_region(1) := v_regs(9);

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_single_region,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2014-01-01',
		in_end_date			=>	DATE '2015-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Get one of generated sheets and insert value
	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(9) AND ROWNUM = 1)
	   AND ROWNUM = 1;

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(9),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	--Remove region used in plan, should no remove delegations and sheets if values were inserted

	--Remove region 
	region_pkg.TrashObject(security_pkg.getact, v_regs(9));
	
	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Assert sheet with data was not removed	
	SELECT COUNT(*)
	  INTO v_count
	  FROM sheet
	 WHERE sheet_id = v_generated_sheet;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation sheet was not removed.');
	
	csr.trash_pkg.RestoreObjects(v_single_region);
END;

PROCEDURE SetRegionTag (
	in_region_sid	IN 	NUMBER,
	in_by_name		IN 	NUMBER
)
AS
BEGIN
	IF in_by_name = 1 THEN
		tag_pkg.SetRegionTag(
			in_region_sid		=>	in_region_sid,
			in_tag_group_name	=>	'DPTEST_TAG_GROUP_1',
			in_tag				=> 	'DPTEST_TAG_1'
		);
	ELSE
		tag_pkg.SetRegionTags(
			in_act_id			=>	security.security_pkg.getact,
			in_region_sid		=>	in_region_sid,
			in_tag_ids			=>	v_tags 
		);
	END IF;
	COMMIT;
END;
	
PROCEDURE ChangeRegionTagWithDynamicPlanSingleLowerTagged
AS
	v_count NUMBER;
	v_out	NUMBER;
BEGIN
	SingleLowerRTAnyWithTag();
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanSingleLowerTagged');
		
	SetRegionTag(v_regs(7), 1);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(6);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(6)|| ', ' || v_count || ' delegations regions were created.');
	
	
	tag_pkg.RemoveRegionTag(
		in_act_id				=> security.security_pkg.getact,
		in_region_sid			=> v_regs(7),
		in_tag_id				=> v_tags(1),
		in_apply_dynamic_plans	=> 1,
		out_rows_updated		=> v_out
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(6);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(6)|| ', ' || v_count || ' delegations regions were created.');
END;

PROCEDURE ChangeRegionTagWithDynamicPlanSingleLowestTagged
AS
	v_count NUMBER;
	v_out	NUMBER;
BEGIN
	SingleLowestRTAnyWithTag();
	
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanSingleLowestTagged');
	END IF;
		
	SetRegionTag(v_regs(7), 1);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
		
	tag_pkg.RemoveRegionTag(
		in_act_id				=> security.security_pkg.getact,
		in_region_sid			=> v_regs(7),
		in_tag_id				=> v_tags(1),
		in_apply_dynamic_plans	=> 1,
		out_rows_updated		=> v_out
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
END;

PROCEDURE ChangeRegionTagWithStaticPlanSingleLowestTagged
AS
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithStaticPlanSingleLowestTagged');
	
	v_apply_dynamic := 0;
	v_nest_test := true;
	ChangeRegionTagWithDynamicPlanSingleLowestTagged();	
	v_apply_dynamic := 1;
	v_nest_test := false;
END;

PROCEDURE ChangeRegionTagWithDynamicPlanMultiLowerTagged
AS
	v_count NUMBER;
	v_out	NUMBER;
BEGIN
	MultiLowerRTAnyWithTag();
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanMultiLowerTagged');
		
	SetRegionTag(v_regs(7), 0);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(6);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(6)|| ', ' || v_count || ' delegations regions were created.');
	
	tag_pkg.RemoveRegionTag(
		in_act_id				=> security.security_pkg.getact,
		in_region_sid			=> v_regs(7),
		in_tag_id				=> v_tags(1),
		in_apply_dynamic_plans	=> 1,
		out_rows_updated		=> v_out
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(6);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(6)|| ', ' || v_count || ' delegations regions were created.');
END;

PROCEDURE ChangeRegionTagWithDynamicPlanMultiLowestTagged
AS
	v_count NUMBER;
	v_out	NUMBER;
BEGIN
	MultiLowestRTAnyWithTag();
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanMultiLowestTagged');
	
	
	SetRegionTag(v_regs(7), 0);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	tag_pkg.RemoveRegionTag(
		in_act_id				=> security.security_pkg.getact,
		in_region_sid			=> v_regs(7),
		in_tag_id				=> v_tags(1),
		in_apply_dynamic_plans	=> 1,
		out_rows_updated		=> v_out
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
END;

PROCEDURE ChangeRegionTagWithStaticPlanMultiLowestTagged
AS
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithStaticPlanMultiLowestTagged');
	v_apply_dynamic := 0;
	ChangeRegionTagWithDynamicPlanMultiLowestTagged();	
	v_apply_dynamic := 1;
END;

PROCEDURE ChangeRegionTypeWithDynamicPlanSingleLower
AS
	v_count NUMBER;
BEGIN
	SingleLowerRTTenantWithoutTag();
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanSingleLowerTagged');
	
	region_pkg.SetRegionType(
		in_region_sid	=> v_regs(7),
		in_region_type	=> csr_data_pkg.REGION_TYPE_PROPERTY
	);	
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(6);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(6)|| ', ' || v_count || ' delegations regions were created.');
	
	region_pkg.SetRegionType(
		in_region_sid	=> v_regs(7),
		in_region_type	=> csr_data_pkg.REGION_TYPE_TENANT
	);
END;

PROCEDURE ChangeRegionTypeWithDynamicPlanSingleLowest
AS
	v_count NUMBER;
BEGIN
	SingleLowestRTTenantWithoutTag();
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanSingleLowestTagged');
		
	region_pkg.SetRegionType(
		in_region_sid	=> v_regs(7),
		in_region_type	=> csr_data_pkg.REGION_TYPE_PROPERTY
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	region_pkg.SetRegionType(
		in_region_sid	=> v_regs(7),
		in_region_type	=> csr_data_pkg.REGION_TYPE_TENANT
	);
END;

PROCEDURE ChangeRegionTypeWithStaticPlanSingleLowest
AS
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithStaticPlanSingleLowestTagged');
	
	v_apply_dynamic := 0;
	ChangeRegionTypeWithDynamicPlanSingleLowest();	
	v_apply_dynamic := 1;
END;

PROCEDURE ChangeRegionTypeWithDynamicPlanMultiLower
AS
	v_count NUMBER;
BEGIN
	MultiLowerRTTenantWithoutTag();
	
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanMultiLowerTagged');
	
	region_pkg.AmendRegion(
		in_act_id			=>	security.security_pkg.getact,
		in_region_sid		=>	v_regs(7),
		in_description		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_active			=>	1,
		in_pos				=>	0,
		in_geo_type			=>	region_pkg.REGION_GEO_TYPE_INHERITED,
		in_info_xml			=>	NULL,
		in_geo_country		=>	NULL,
		in_geo_region		=>	NULL,
		in_geo_city			=>	NULL,
		in_map_entity		=>	NULL,
		in_egrid_ref		=>	NULL,
		in_region_ref		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_acquisition_dtm 	=>	NULL,
		in_disposal_dtm		=>	NULL,
		in_region_type		=>	csr_data_pkg.REGION_TYPE_PROPERTY
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(6);
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(6)|| ', ' || v_count || ' delegations regions were created.');
	
	region_pkg.AmendRegion(
		in_act_id			=>	security.security_pkg.getact,
		in_region_sid		=>	v_regs(7),
		in_description		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_active			=>	1,
		in_pos				=>	0,
		in_geo_type			=>	region_pkg.REGION_GEO_TYPE_INHERITED,
		in_info_xml			=>	NULL,
		in_geo_country		=>	NULL,
		in_geo_region		=>	NULL,
		in_geo_city			=>	NULL,
		in_map_entity		=>	NULL,
		in_egrid_ref		=>	NULL,
		in_region_ref		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_acquisition_dtm 	=>	NULL,
		in_disposal_dtm		=>	NULL,
		in_region_type		=>	csr_data_pkg.REGION_TYPE_TENANT
	);
END;

PROCEDURE ChangeRegionTypeWithDynamicPlanMultiLowest
AS
	v_count NUMBER;
BEGIN
	MultiLowestRTTenantWithoutTag();
	
	IF NOT v_nest_test THEN
		unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithDynamicPlanMultiLowestTagged');
	END IF;
		
	region_pkg.AmendRegion(
		in_act_id			=>	security.security_pkg.getact,
		in_region_sid		=>	v_regs(7),
		in_description		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_active			=>	1,
		in_pos				=>	0,
		in_geo_type			=>	region_pkg.REGION_GEO_TYPE_INHERITED,
		in_info_xml			=>	NULL,
		in_geo_country		=>	NULL,
		in_geo_region		=>	NULL,
		in_geo_city			=>	NULL,
		in_map_entity		=>	NULL,
		in_egrid_ref		=>	NULL,
		in_region_ref		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_acquisition_dtm 	=>	NULL,
		in_disposal_dtm		=>	NULL,
		in_region_type		=>	csr_data_pkg.REGION_TYPE_PROPERTY
	);
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(7);
	  
	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(7)|| ', ' || v_count || ' delegations regions were created.');
	
	region_pkg.AmendRegion(
		in_act_id			=>	security.security_pkg.getact,
		in_region_sid		=>	v_regs(7),
		in_description		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_active			=>	1,
		in_pos				=>	0,
		in_geo_type			=>	region_pkg.REGION_GEO_TYPE_INHERITED,
		in_info_xml			=>	NULL,
		in_geo_country		=>	NULL,
		in_geo_region		=>	NULL,
		in_geo_city			=>	NULL,
		in_map_entity		=>	NULL,
		in_egrid_ref		=>	NULL,
		in_region_ref		=>	'DELEG_PLAN_REGION_1_3_1_1',
		in_acquisition_dtm 	=>	NULL,
		in_disposal_dtm		=>	NULL,
		in_region_type		=>	csr_data_pkg.REGION_TYPE_TENANT
	);
END;

PROCEDURE ChangeRegionTypeWithStaticPlanMultiLowest
AS
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangeRegionTagWithStaticPlanMultiLowest');
	v_apply_dynamic := 0;
	v_nest_test := true;
	ChangeRegionTypeWithDynamicPlanMultiLowest();	
	v_apply_dynamic := 1;
	v_nest_test := false;
END;

PROCEDURE AddLowestRegionToMultiLowestRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
	v_generated_sheet	NUMBER(10);
	v_count				NUMBER(10);
	v_var_expl_ids		security_pkg.T_SID_IDS;
	v_changed_inds		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.AddLowestRegionToMultiLowestRTAnyWithoutTag');
	
	v_regions(1) := v_regs(3);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(2) := v_regs(4);
	v_region_counts(2) := v_roles.COUNT;
	v_regions(3) := v_regs(7);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(8);
	v_region_counts(4) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT*4,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
	
	-- Add Data	
	SELECT MIN(sheet_id)
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT MIN(delegation_sid) FROM delegation_region WHERE region_sid = v_regs(4));

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(4),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	-- Add lowest level region	
	v_regs(10) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_2_1', v_regs(4));
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	--Assert nothing was created for new region 
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(10);

	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(10)|| ', ' || v_count || ' were created.');
	
	security.securableobject_pkg.deleteso(security_pkg.getact, v_regs(10));
	v_regs(10) := NULL;
END;

PROCEDURE AddLowerRegionToMultiLowerRTAnyWithoutTag
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
	v_generated_sheet	NUMBER(10);
	v_count				NUMBER(10);
	v_var_expl_ids		security_pkg.T_SID_IDS;
	v_changed_inds		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.AddLowerRegionToMultiLowerRTAnyWithoutTag');
	
	v_regions(1) := v_regs(3);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(2) := v_regs(4);
	v_region_counts(2) := v_roles.COUNT;
	v_regions(3) := v_regs(7);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(8);
	v_region_counts(4) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT*4,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
	
	-- Add Data	
	SELECT MIN(sheet_id)
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT MIN(delegation_sid) FROM delegation_region WHERE region_sid = v_regs(4));

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(4),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	-- Add lowest level region	
	v_regs(10) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_2_1', v_regs(4));
	
	ProcessJobIfExists('DELEGATION_PLAN');
	
	--Assert nothing was created for new region 
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(10);

	unit_test_pkg.AssertAreEqual(0, v_count, 'For region '|| v_regs(10)|| ', ' || v_count || ' were created.');
	
	security.securableobject_pkg.deleteso(security_pkg.getact, v_regs(10));
	v_regs(10) := NULL;
END;

-- Delete Plans
PROCEDURE RemoveDelegPlanWithNoData
AS
	v_count				NUMBER(10);
BEGIN
	--Plan with delegations generated
	ApplyDelegationPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveDelegPlanWithNoData');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	  WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations exist.');

	-- Remove plan
	deleg_plan_pkg.DeleteDelegPlan(v_deleg_plan_sid, 1);
	v_deleg_plan_sid := NULL;
		
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Delegations were removed.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM sheet s
	 WHERE NOT EXISTS (SELECT NULL FROM master_deleg WHERE delegation_sid = s.delegation_sid);

	unit_test_pkg.AssertAreEqual(0, v_count, 'Delegations sheets were removed.');
END;

PROCEDURE RemoveDelegPlanWithData
AS
	v_count				NUMBER(10);
	v_generated_sheet	NUMBER(10);
	v_var_expl_ids		security_pkg.T_SID_IDS;
	v_changed_inds		SYS_REFCURSOR;
BEGIN
	--Plan with delegations generated
	ApplyDelegationPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveDelegPlanWithData');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations exist.');

	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(1) AND ROWNUM = 1)
	   AND ROWNUM = 1;

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(1),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);

	-- Remove plan
	deleg_plan_pkg.DeleteDelegPlan(v_deleg_plan_sid, 1);
	v_deleg_plan_sid := NULL;

	SELECT COUNT(*)
	  INTO v_count
	  FROM sheet
	 WHERE sheet_id = v_generated_sheet;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation sheet was not removed.');
END;

PROCEDURE RemoveDelegPlanWithoutDelegs
AS
	v_count				NUMBER(10);
BEGIN
	--Plan with delegations generated
	ApplyDelegationPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveDelegPlanWithoutDelegs');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	  WHERE master_delegation_sid = v_delegation_sid;
	  
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations exist.');

	-- Remove plan without delegations
	deleg_plan_pkg.DeleteDelegPlan(v_deleg_plan_sid, 0);
	v_deleg_plan_sid := NULL;

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	  WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertNotEqual(0, v_count, 'Delegations were not removed.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM sheet;

	unit_test_pkg.AssertNotEqual(0, v_count, 'Delegations sheets were not removed.');
END;

-- Role tests
PROCEDURE ApplyDelegPlanForLowestReg
AS
	v_act				security_pkg.T_ACT_ID;
	v_count				NUMBER(10);
	v_created			NUMBER;
	v_schedule_xml		CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ApplyDelegPlanForLowestReg');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	--Created delegations for lowest level regions : v_regs(3) and v_regs(4)
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(3);
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(3)|| ', ' || v_count || ' delegations regions were created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region 
	 WHERE region_sid = v_regs(4);

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'For region '|| v_regs(4)|| ', ' || v_count || ' delegations regions were created.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegations were created.');
END;

PROCEDURE AddRoleToDelegPlan
AS
	v_count				NUMBER(10);
	v_created			NUMBER;
BEGIN
	ApplyDelegPlanForLowestReg;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.AddRoleToDelegPlan');

	--Plan with delegations generated

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	  WHERE master_delegation_sid = v_delegation_sid;

	unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, '3 delegations exist.');

	v_new_roles(1) := v_roles(1);
	v_new_roles(2) := v_roles(2);
	v_new_roles(3) := v_roles(3);
	v_new_roles(4) := unit_test_pkg.GetOrCreateRole('DELEG_PLAN_NEW_APPROVER');

	--Add a set of roles which includes the new role
	deleg_plan_pkg.SetPlanRoles(v_deleg_plan_sid, v_new_roles);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;

	 unit_test_pkg.AssertAreEqual(v_new_roles.COUNT, v_count, 'Delegation for new level was added.');
END;

PROCEDURE RemoveRoleFromDelegPlan
AS
	v_count				NUMBER(10);
	v_created			NUMBER;
BEGIN
	--Plan with delegations generated
	AddRoleToDelegPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveRoleFromDelegPlan');
	
	--Add a set of roles which doesn't include the last role added
	deleg_plan_pkg.SetPlanRoles(v_deleg_plan_sid, v_roles);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE master_delegation_sid = v_delegation_sid;

	 unit_test_pkg.AssertAreEqual(v_roles.COUNT, v_count, 'Delegation for level was removed.');
END;

PROCEDURE RemoveRoleFromPlanWithData
AS
	v_count				NUMBER(10);
	v_created			NUMBER;
	v_generated_sheet	NUMBER(10);
	v_var_expl_ids		security_pkg.T_SID_IDS;
	v_changed_inds		SYS_REFCURSOR;
BEGIN
	--Plan with delegations generated
	AddRoleToDelegPlan;

	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RemoveRoleFromPlanWithData');

	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(3) AND ROWNUM = 1)
	   AND ROWNUM = 1;

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(3),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);

	--Add a set of roles which doesn't include the last role added
	deleg_plan_pkg.SetPlanRoles(v_deleg_plan_sid, v_roles);
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM sheet
	 WHERE sheet_id = v_generated_sheet;
	
	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegation sheet was not removed.'); 
END;

-- Plan status export tests
PROCEDURE GetPlanStatusForDelegationWithSpecifiedRegionsHasCorrectSheets
AS
	v_act							security_pkg.T_ACT_ID;
	v_count							NUMBER(10) := 0;
	v_r1_count						NUMBER := 0;
	v_created						NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_deleg_plan_cursor 			SYS_REFCURSOR;
	v_region_role_members_cursor	SYS_REFCURSOR;
	v_roles_cursor					SYS_REFCURSOR;
	v_deleg_plan_col_cursor			SYS_REFCURSOR;
	v_regions_cursor				SYS_REFCURSOR;
	v_sheets_cursor					SYS_REFCURSOR;
	v_deleg_user_cursor				SYS_REFCURSOR;
	v_deleg_plan_col_id				csr.deleg_plan_col.deleg_plan_col_id%TYPE;
	v_actual_delegation_sid			csr.delegation.delegation_sid%TYPE;
	v_actual_region_sid				csr.delegation_region.region_sid%TYPE;
	v_level							NUMBER(10);
	v_sheet_sid						csr.sheet_with_last_action.sheet_id%TYPE;
	v_start_dtm						csr.sheet_with_last_action.start_dtm%TYPE;
	v_end_dtm						csr.sheet_with_last_action.end_dtm%TYPE;
	v_reminder_dtm					csr.sheet_with_last_action.reminder_dtm%TYPE;
	v_submission_dtm				csr.sheet_with_last_action.submission_dtm%TYPE;
	v_last_action_id				csr.sheet_with_last_action.last_action_id%TYPE;
	v_last_action_dtm				csr.sheet_with_last_action.last_action_dtm%TYPE;
	v_last_action_from_user_sid		csr.sheet_with_last_action.last_action_from_user_sid%TYPE;
	v_last_action_note				csr.sheet_with_last_action.last_action_note%TYPE;
	v_status						csr.sheet_with_last_action.status%TYPE;
	v_last_action_desc				csr.sheet_with_last_action.last_action_desc%TYPE;
	v_percent_complete				csr.sheet_with_last_action.percent_complete%TYPE;
	v_other_cursor					SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetPlanStatusForDelegationWithSpecifiedRegionsHasCorrectSheets');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	-- Get the plan status
	deleg_plan_pkg.GetPlanStatus(
		in_deleg_plan_sid			=>	v_deleg_plan_sid, 
		out_deleg_plan_cur			=>	v_deleg_plan_cursor, 
		out_region_role_members_cur	=>	v_region_role_members_cursor, 
		out_roles_cur				=>	v_roles_cursor, 
		out_deleg_plan_col_cur		=>	v_deleg_plan_col_cursor, 
		out_regions_cur				=>	v_regions_cursor, 
		out_sheets_cur				=>	v_sheets_cursor, 
		out_deleg_user_cur			=>	v_deleg_user_cursor);
	
	-- Ensure cursors have the right number of entries
	v_count := 0;
	
	LOOP
		FETCH v_sheets_cursor
		INTO v_deleg_plan_col_id, v_actual_region_sid, v_actual_delegation_sid, v_level, v_sheet_sid, v_start_dtm, v_end_dtm,
			 v_reminder_dtm, v_submission_dtm, v_last_action_id, v_last_action_dtm, v_last_action_from_user_sid,
			 v_last_action_note, v_status, v_last_action_desc, v_percent_complete;
		EXIT WHEN v_sheets_cursor%NOTFOUND;
		v_count:= v_count + 1;
		IF v_actual_region_sid = v_regs(1)
		THEN
			v_r1_count := v_r1_count + 1;
		END IF;
	END LOOP;
	CLOSE v_sheets_cursor;
	
	unit_test_pkg.AssertAreEqual(36, v_r1_count, ' sheets present for root region');
	unit_test_pkg.AssertAreEqual(36, v_count, ' sheets (3 delegations x 12 sheets per year) present in sheets cursor');
END;

PROCEDURE GetPlanStatusForDelegationPlanWithOneDelegationPerRegionHasCorrectSheets
AS
	v_act							security_pkg.T_ACT_ID;
	v_count							NUMBER(10) := 0;
	v_r1_count						NUMBER := 0;
	v_r11_count						NUMBER := 0;
	v_r111_count					NUMBER := 0;
	v_r12_count						NUMBER := 0;
	v_r13_count						NUMBER := 0;
	v_r131_count					NUMBER := 0;
	v_r1311_count					NUMBER := 0;
	v_r1312_count					NUMBER := 0;
	v_r2_count						NUMBER := 0;
	v_created						NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_deleg_plan_cursor 			SYS_REFCURSOR;
	v_region_role_members_cursor	SYS_REFCURSOR;
	v_roles_cursor					SYS_REFCURSOR;
	v_deleg_plan_col_cursor			SYS_REFCURSOR;
	v_regions_cursor				SYS_REFCURSOR;
	v_sheets_cursor					SYS_REFCURSOR;
	v_deleg_user_cursor				SYS_REFCURSOR;
	v_deleg_plan_col_id				csr.deleg_plan_col.deleg_plan_col_id%TYPE;
	v_actual_delegation_sid			csr.delegation.delegation_sid%TYPE;
	v_actual_region_sid				csr.delegation_region.region_sid%TYPE;
	v_level							NUMBER(10);
	v_sheet_sid						csr.sheet_with_last_action.sheet_id%TYPE;
	v_start_dtm						csr.sheet_with_last_action.start_dtm%TYPE;
	v_end_dtm						csr.sheet_with_last_action.end_dtm%TYPE;
	v_reminder_dtm					csr.sheet_with_last_action.reminder_dtm%TYPE;
	v_submission_dtm				csr.sheet_with_last_action.submission_dtm%TYPE;
	v_last_action_id				csr.sheet_with_last_action.last_action_id%TYPE;
	v_last_action_dtm				csr.sheet_with_last_action.last_action_dtm%TYPE;
	v_last_action_from_user_sid		csr.sheet_with_last_action.last_action_from_user_sid%TYPE;
	v_last_action_note				csr.sheet_with_last_action.last_action_note%TYPE;
	v_status						csr.sheet_with_last_action.status%TYPE;
	v_last_action_desc				csr.sheet_with_last_action.last_action_desc%TYPE;
	v_percent_complete				csr.sheet_with_last_action.percent_complete%TYPE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetPlanStatusForDelegationPlanWithOneDelegationPerRegionHasCorrectSheets');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	-- Get the plan status
	deleg_plan_pkg.GetPlanStatus(
		in_deleg_plan_sid			=>	v_deleg_plan_sid, 
		out_deleg_plan_cur			=>	v_deleg_plan_cursor, 
		out_region_role_members_cur	=>	v_region_role_members_cursor, 
		out_roles_cur				=>	v_roles_cursor, 
		out_deleg_plan_col_cur		=>	v_deleg_plan_col_cursor, 
		out_regions_cur				=>	v_regions_cursor, 
		out_sheets_cur				=>	v_sheets_cursor, 
		out_deleg_user_cur			=>	v_deleg_user_cursor);
	
	-- Ensure cursors have the right number of entries
	v_count := 0;
	
	LOOP
		FETCH v_sheets_cursor
		INTO v_deleg_plan_col_id, v_actual_region_sid, v_actual_delegation_sid, v_level, v_sheet_sid, v_start_dtm, v_end_dtm,
			 v_reminder_dtm, v_submission_dtm, v_last_action_id, v_last_action_dtm, v_last_action_from_user_sid,
			 v_last_action_note, v_status, v_last_action_desc, v_percent_complete;
		EXIT WHEN v_sheets_cursor%NOTFOUND;
		v_count:= v_count + 1;
		IF v_actual_region_sid = v_regs(1)
		THEN
			v_r1_count := v_r1_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(2)
		THEN
			v_r11_count := v_r11_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(3)
		THEN
			v_r111_count := v_r111_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(4)
		THEN
			v_r12_count := v_r12_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(5)
		THEN
			v_r13_count := v_r13_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(6)
		THEN
			v_r131_count := v_r131_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(7)
		THEN
			v_r1311_count := v_r1311_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(8)
		THEN
			v_r1312_count := v_r1312_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(9)
		THEN
			v_r2_count := v_r2_count + 1;
		END IF;
	END LOOP;
	CLOSE v_sheets_cursor;
	
	unit_test_pkg.AssertAreEqual(0, v_r1_count, ' sheets for region 1');
	unit_test_pkg.AssertAreEqual(0, v_r11_count, ' sheets for region 11');
	unit_test_pkg.AssertAreEqual(36, v_r111_count, ' sheets for region 111');
	unit_test_pkg.AssertAreEqual(36, v_r12_count, ' sheets for region 12');
	unit_test_pkg.AssertAreEqual(0, v_r13_count, ' sheets for region 13');
	unit_test_pkg.AssertAreEqual(0, v_r131_count, ' sheets for region 131');
	unit_test_pkg.AssertAreEqual(36, v_r1311_count, ' sheets for region 1311');
	unit_test_pkg.AssertAreEqual(36, v_r1312_count, ' sheets for region 1312');
	unit_test_pkg.AssertAreEqual(0, v_r2_count, ' sheets for region 2');
	unit_test_pkg.AssertAreEqual(144, v_count, ' sheets  (4 regions x 3 levels of delegation x 12 sheets per year) present in sheets cursor');
END;

-- Region Tree
-- v_regs(1) DELEG_PLAN_REGION_1 N
-- ----v_regs(2) DELEG_PLAN_REGION_1_1 P
-- --------v_regs(3) DELEG_PLAN_REGION_1_1_1 N
-- ----v_regs(4) DELEG_PLAN_REGION_1_2 P TAGGED
-- ----v_regs(5) DELEG_PLAN_REGION_1_3 N
-- --------v_regs(6) DELEG_PLAN_REGION_1_3_1 T TAGGED
-- ------------v_regs(7) DELEG_PLAN_REGION_1_3_1_1 T
-- ------------v_regs(8) DELEG_PLAN_REGION_1_3_1_2 P
-- v_regs(9) DELEG_PLAN_REGION_2 N

PROCEDURE GetPlanStatusForDelegationPlanWithMultipleRegionsOnOneDelegationHasCorrectSheets
AS
	v_act							security_pkg.T_ACT_ID;
	v_count							NUMBER(10) := 0;
	v_r1_count						NUMBER := 0;
	v_r11_count						NUMBER := 0;
	v_r111_count					NUMBER := 0;
	v_r12_count						NUMBER := 0;
	v_r13_count						NUMBER := 0;
	v_r131_count					NUMBER := 0;
	v_r1311_count					NUMBER := 0;
	v_r1312_count					NUMBER := 0;
	v_r2_count						NUMBER := 0;
	v_created						NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_deleg_plan_cursor 			SYS_REFCURSOR;
	v_region_role_members_cursor	SYS_REFCURSOR;
	v_roles_cursor					SYS_REFCURSOR;
	v_deleg_plan_col_cursor			SYS_REFCURSOR;
	v_regions_cursor				SYS_REFCURSOR;
	v_sheets_cursor					SYS_REFCURSOR;
	v_deleg_user_cursor				SYS_REFCURSOR;
	v_deleg_plan_col_id				csr.deleg_plan_col.deleg_plan_col_id%TYPE;
	v_actual_delegation_sid			csr.delegation.delegation_sid%TYPE;
	v_actual_region_sid				csr.delegation_region.region_sid%TYPE;
	v_level							NUMBER(10);
	v_sheet_sid						csr.sheet_with_last_action.sheet_id%TYPE;
	v_start_dtm						csr.sheet_with_last_action.start_dtm%TYPE;
	v_end_dtm						csr.sheet_with_last_action.end_dtm%TYPE;
	v_reminder_dtm					csr.sheet_with_last_action.reminder_dtm%TYPE;
	v_submission_dtm				csr.sheet_with_last_action.submission_dtm%TYPE;
	v_last_action_id				csr.sheet_with_last_action.last_action_id%TYPE;
	v_last_action_dtm				csr.sheet_with_last_action.last_action_dtm%TYPE;
	v_last_action_from_user_sid		csr.sheet_with_last_action.last_action_from_user_sid%TYPE;
	v_last_action_note				csr.sheet_with_last_action.last_action_note%TYPE;
	v_status						csr.sheet_with_last_action.status%TYPE;
	v_last_action_desc				csr.sheet_with_last_action.last_action_desc%TYPE;
	v_percent_complete				csr.sheet_with_last_action.percent_complete%TYPE;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetPlanStatusForDelegationPlanWithMultipleRegionsOnOneDelegationHasCorrectSheets');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	-- Get the plan status
	deleg_plan_pkg.GetPlanStatus(
		in_deleg_plan_sid			=>	v_deleg_plan_sid, 
		out_deleg_plan_cur			=>	v_deleg_plan_cursor, 
		out_region_role_members_cur	=>	v_region_role_members_cursor, 
		out_roles_cur				=>	v_roles_cursor, 
		out_deleg_plan_col_cur		=>	v_deleg_plan_col_cursor, 
		out_regions_cur				=>	v_regions_cursor, 
		out_sheets_cur				=>	v_sheets_cursor, 
		out_deleg_user_cur			=>	v_deleg_user_cursor
	);
	
	-- Ensure cursors have the right number of entries
	v_count := 0;
	
	LOOP
		FETCH v_sheets_cursor
		INTO v_deleg_plan_col_id, v_actual_region_sid, v_actual_delegation_sid, v_level, v_sheet_sid, v_start_dtm, v_end_dtm,
			 v_reminder_dtm, v_submission_dtm, v_last_action_id, v_last_action_dtm, v_last_action_from_user_sid,
			 v_last_action_note, v_status, v_last_action_desc, v_percent_complete;
		EXIT WHEN v_sheets_cursor%NOTFOUND;
		v_count:= v_count + 1;
		IF v_actual_region_sid = v_regs(1)
		THEN
			v_r1_count := v_r1_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(2)
		THEN
			v_r11_count := v_r11_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(3)
		THEN
			v_r111_count := v_r111_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(4)
		THEN
			v_r12_count := v_r12_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(5)
		THEN
			v_r13_count := v_r13_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(6)
		THEN
			v_r131_count := v_r131_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(7)
		THEN
			v_r1311_count := v_r1311_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(8)
		THEN
			v_r1312_count := v_r1312_count + 1;
		END IF;
		IF v_actual_region_sid = v_regs(9)
		THEN
			v_r2_count := v_r2_count + 1;
		END IF;
	END LOOP;
	CLOSE v_sheets_cursor;
	
	unit_test_pkg.AssertAreEqual(0, v_r1_count, ' sheets for region 1');
	unit_test_pkg.AssertAreEqual(0, v_r11_count, ' sheets for region 11');
	unit_test_pkg.AssertAreEqual(36, v_r111_count, ' sheets for region 111');
	unit_test_pkg.AssertAreEqual(36, v_r12_count, ' sheets for region 12');
	unit_test_pkg.AssertAreEqual(0, v_r13_count, ' sheets for region 13');
	unit_test_pkg.AssertAreEqual(0, v_r131_count, ' sheets for region 131');
	unit_test_pkg.AssertAreEqual(36, v_r1311_count, ' sheets for region 1311');
	unit_test_pkg.AssertAreEqual(36, v_r1312_count, ' sheets for region 1312');
	unit_test_pkg.AssertAreEqual(0, v_r2_count, ' sheets for region 2');
	unit_test_pkg.AssertAreEqual(144, v_count, ' sheets (3 levels of delegation x 12 sheets per year x 4 regions per sheet - we are intentionally duplicating sheets per region to make the plan status report work as per DE13219) present in sheets cursor');
END;
------------------------------------------------------------------------------------------------

PROCEDURE UpdateDelegPlanColRegionThrowsIfGivenNegativeOne
AS
	v_success 					BOOLEAN := false; 
BEGIN
	csr.deleg_plan_pkg.UpdateDelegPlanColRegion(
	in_deleg_plan_col_id		=>	0,
	in_region_sid				=>	0,
	in_region_selection			=>	0,
	in_tag_id					=>	0,
	in_region_type				=>	-1
	);
	
	unit_test_pkg.TestFail('Expected an invalid region type error');
	
	EXCEPTION
		WHEN csr_data_pkg.INVALID_REGION_TYPE THEN
			v_success := true; -- This is a pass!
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('Expected an invalid region type error, but got a different error instead');
END;

PROCEDURE RTAnyWithoutTagDoesNotIncorrectlyDeleteDelegations
AS 
	v_count				NUMBER;
	v_created			NUMBER;
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.RTAnyWithoutTagDoesNotIncorrectlyDeleteDelegations');
	
	v_regions(1) := v_regs(3);
	v_region_counts(1) := v_roles.COUNT;
	v_regions(2) := v_regs(4);
	v_region_counts(2) := v_roles.COUNT;
	v_regions(3) := v_regs(7);
	v_region_counts(3) := v_roles.COUNT;
	v_regions(4) := v_regs(8);
	v_region_counts(4) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1),
		in_region_selected		=>	v_regs(1),
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT*4,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
		
	--Re-apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	--Assert nothing was created
	unit_test_pkg.AssertAreEqual(0, v_created, 'Nothing should be created on reapply');
	
	-- Assert nothing was deleted
	SELECT COUNT(*)
	  INTO v_count
	  FROM audit_log
	 WHERE object_sid = v_deleg_plan_sid
	   AND param_2 = v_regions(1)
	   AND description LIKE 'Delegation safe deleted%';
	   
	unit_test_pkg.AssertAreEqual(0, v_count, 'Nothing should be deleted on reapply');
END;

PROCEDURE GetActiveDelegPlansReturnsNothingWhenNoActivePlansExist
AS 
	v_cur							SYS_REFCURSOR;
	v_count							NUMBER;

	v_period_set_id					NUMBER := 1;
	v_period_interval_id			NUMBER := 4;
	v_count_start					NUMBER(10);
	v_count_end						NUMBER(10);
	v_interval_members				NUMBER(10);
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';

	v_inactive_start_dtm			DATE := DATE '2010-01-01';
	v_inactive_end_dtm				DATE := DATE '2011-01-01';
	v_test_deleg_plan_inactive_sid	NUMBER;

	v_cur_deleg_plan_sid			NUMBER;
	v_cur_name						VARCHAR2(100);
	v_cur_start_dtm					DATE;
	v_cur_end_dtm					DATE;
	v_cur_reminder_offset			NUMBER;
	v_cur_period_set_id				NUMBER;
	v_cur_period_interval_id		NUMBER;
	v_cur_period_interval_label		VARCHAR2(100);
	v_cur_schedule_xml				VARCHAR2(100);
	v_cur_dynamic					NUMBER;
	v_cur_parent_sid				NUMBER;
	v_cur_custom_date_schedule		NUMBER;
	v_cur_multiple_date_schedule	NUMBER;
	v_cur_can_write					NUMBER;
	v_cur_can_delete				NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetActiveDelegPlansReturnsNothingWhenNoActivePlansExist');

	deleg_plan_pkg.GetActiveDelegPlans(out_cur => v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur 
		 INTO 
			v_cur_deleg_plan_sid,
			v_cur_name,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_reminder_offset,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_period_interval_label,
			v_cur_schedule_xml,
			v_cur_dynamic,
			v_cur_parent_sid,
			v_cur_custom_date_schedule,
			v_cur_multiple_date_schedule,
			v_cur_can_write,
			v_cur_can_delete
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 active plans, found'||v_count);

	v_test_deleg_plan_inactive_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_LIST_TEST_INACTIVE',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_inactive_start_dtm,
		in_end_date				=>	v_inactive_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	v_period_set_id,
		in_period_interval_id	=>	v_period_interval_id
	);
	UPDATE deleg_plan
	   SET active = 0
	 WHERE deleg_plan_sid = v_test_deleg_plan_inactive_sid;

	deleg_plan_pkg.GetActiveDelegPlans(out_cur => v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur 
		 INTO 
			v_cur_deleg_plan_sid,
			v_cur_name,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_reminder_offset,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_period_interval_label,
			v_cur_schedule_xml,
			v_cur_dynamic,
			v_cur_parent_sid,
			v_cur_custom_date_schedule,
			v_cur_multiple_date_schedule,
			v_cur_can_write,
			v_cur_can_delete
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 active plans, found'||v_count);

	IF v_test_deleg_plan_inactive_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_inactive_sid, 1);
		v_test_deleg_plan_inactive_sid := NULL;
	END IF;
END;

PROCEDURE GetActiveDelegPlansReturnsActivePlanWhenPlansExist
AS 
	v_cur							SYS_REFCURSOR;
	v_count							NUMBER;

	v_period_set_id					NUMBER := 1;
	v_period_interval_id			NUMBER := 4;
	v_count_start					NUMBER(10);
	v_count_end						NUMBER(10);
	v_interval_members				NUMBER(10);
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';

	v_start_dtm						DATE := DATE '2018-01-01';
	v_end_dtm						DATE := DATE '2019-01-01';
	v_test_deleg_plan_sid			NUMBER;

	v_inactive_start_dtm			DATE := DATE '2010-01-01';
	v_inactive_end_dtm				DATE := DATE '2011-01-01';
	v_test_deleg_plan_inactive_sid	NUMBER;

	v_cur_deleg_plan_sid			NUMBER;
	v_cur_name						VARCHAR2(100);
	v_cur_start_dtm					DATE;
	v_cur_end_dtm					DATE;
	v_cur_reminder_offset			NUMBER;
	v_cur_period_set_id				NUMBER;
	v_cur_period_interval_id		NUMBER;
	v_cur_period_interval_label		VARCHAR2(100);
	v_cur_schedule_xml				VARCHAR2(100);
	v_cur_dynamic					NUMBER;
	v_cur_parent_sid				NUMBER;
	v_cur_custom_date_schedule		NUMBER;
	v_cur_multiple_date_schedule	NUMBER;
	v_cur_can_write					NUMBER;
	v_cur_can_delete				NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetActiveDelegPlansReturnsActivePlanWhenPlansExist');

	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_LIST_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_start_dtm,
		in_end_date				=>	v_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	v_period_set_id,
		in_period_interval_id	=>	v_period_interval_id
	);

	v_test_deleg_plan_inactive_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_LIST_TEST_INACTIVE',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_inactive_start_dtm,
		in_end_date				=>	v_inactive_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	v_period_set_id,
		in_period_interval_id	=>	v_period_interval_id
	);
	UPDATE deleg_plan
	   SET active = 0
	 WHERE deleg_plan_sid = v_test_deleg_plan_inactive_sid;

	deleg_plan_pkg.GetActiveDelegPlans(out_cur => v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur 
		 INTO 
			v_cur_deleg_plan_sid,
			v_cur_name,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_reminder_offset,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_period_interval_label,
			v_cur_schedule_xml,
			v_cur_dynamic,
			v_cur_parent_sid,
			v_cur_custom_date_schedule,
			v_cur_multiple_date_schedule,
			v_cur_can_write,
			v_cur_can_delete
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
		unit_test_pkg.AssertAreEqual(v_cur_deleg_plan_sid, v_test_deleg_plan_sid, 'Unexpected plan sid, found'||v_cur_deleg_plan_sid);
		unit_test_pkg.AssertAreEqual(v_cur_name, 'DELEGATION_PLAN_LIST_TEST', 'Unexpected plan name, found'||v_cur_name);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 active plans, found'||v_count);

	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
	IF v_test_deleg_plan_inactive_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_inactive_sid, 1);
		v_test_deleg_plan_inactive_sid := NULL;
	END IF;
END;

PROCEDURE GetHiddenDelegPlansReturnsNothingWhenNoInactivePlansExist
AS
	v_cur							SYS_REFCURSOR;
	v_count							NUMBER;

	v_period_set_id					NUMBER := 1;
	v_period_interval_id			NUMBER := 4;
	v_count_start					NUMBER(10);
	v_count_end						NUMBER(10);
	v_interval_members				NUMBER(10);
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';

	v_start_dtm						DATE := DATE '2018-01-01';
	v_end_dtm						DATE := DATE '2019-01-01';
	v_test_deleg_plan_sid			NUMBER;

	v_cur_deleg_plan_sid			NUMBER;
	v_cur_name						VARCHAR2(100);
	v_cur_start_dtm					DATE;
	v_cur_end_dtm					DATE;
	v_cur_reminder_offset			NUMBER;
	v_cur_period_set_id				NUMBER;
	v_cur_period_interval_id		NUMBER;
	v_cur_period_interval_label		VARCHAR2(100);
	v_cur_schedule_xml				VARCHAR2(100);
	v_cur_dynamic					NUMBER;
	v_cur_parent_sid				NUMBER;
	v_cur_custom_date_schedule		NUMBER;
	v_cur_multiple_date_schedule	NUMBER;
	v_cur_can_write					NUMBER;
	v_cur_can_delete				NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetHiddenDelegPlansReturnsNothingWhenNoInactivePlansExist');
	
	security_pkg.SetContext('SID', 3);
	
	deleg_plan_pkg.GetHiddenDelegPlans(out_cur => v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur 
		 INTO 
			v_cur_deleg_plan_sid,
			v_cur_name,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_reminder_offset,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_period_interval_label,
			v_cur_schedule_xml,
			v_cur_dynamic,
			v_cur_parent_sid,
			v_cur_custom_date_schedule,
			v_cur_multiple_date_schedule,
			v_cur_can_write,
			v_cur_can_delete
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected no hidden plans, found'||v_count);

	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_LIST_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_start_dtm,
		in_end_date				=>	v_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	v_period_set_id,
		in_period_interval_id	=>	v_period_interval_id
	);

	deleg_plan_pkg.GetHiddenDelegPlans(out_cur => v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur 
		 INTO 
			v_cur_deleg_plan_sid,
			v_cur_name,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_reminder_offset,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_period_interval_label,
			v_cur_schedule_xml,
			v_cur_dynamic,
			v_cur_parent_sid,
			v_cur_custom_date_schedule,
			v_cur_multiple_date_schedule,
			v_cur_can_write,
			v_cur_can_delete
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected no hidden plans, found'||v_count);

	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
	
	security_pkg.SetContext('SID', v_logged_on_user);
END;

PROCEDURE GetHiddenDelegPlansReturnsInactivePlanWhenPlansExist
AS 
	v_cur							SYS_REFCURSOR;
	v_count							NUMBER;

	v_period_set_id					NUMBER := 1;
	v_period_interval_id			NUMBER := 4;
	v_count_start					NUMBER(10);
	v_count_end						NUMBER(10);
	v_interval_members				NUMBER(10);
	v_schedule_xml					CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';

	v_start_dtm						DATE := DATE '2018-01-01';
	v_end_dtm						DATE := DATE '2019-01-01';
	v_test_deleg_plan_sid			NUMBER;

	v_inactive_start_dtm			DATE := DATE '2010-01-01';
	v_inactive_end_dtm				DATE := DATE '2011-01-01';
	v_test_deleg_plan_inactive_sid	NUMBER;

	v_cur_deleg_plan_sid			NUMBER;
	v_cur_name						VARCHAR2(100);
	v_cur_start_dtm					DATE;
	v_cur_end_dtm					DATE;
	v_cur_reminder_offset			NUMBER;
	v_cur_period_set_id				NUMBER;
	v_cur_period_interval_id		NUMBER;
	v_cur_period_interval_label		VARCHAR2(100);
	v_cur_schedule_xml				VARCHAR2(100);
	v_cur_dynamic					NUMBER;
	v_cur_parent_sid				NUMBER;
	v_cur_custom_date_schedule		NUMBER;
	v_cur_multiple_date_schedule	NUMBER;
	v_cur_can_write					NUMBER;
	v_cur_can_delete				NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.GetHiddenDelegPlansReturnsInactivePlanWhenPlansExist');
	
	security_pkg.SetContext('SID', 3);
	
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_LIST_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_start_dtm,
		in_end_date				=>	v_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	v_period_set_id,
		in_period_interval_id	=>	v_period_interval_id
	);

	v_test_deleg_plan_inactive_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_LIST_TEST_INACTIVE',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	v_inactive_start_dtm,
		in_end_date				=>	v_inactive_end_dtm,
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	v_period_set_id,
		in_period_interval_id	=>	v_period_interval_id
	);
	UPDATE deleg_plan
	   SET active = 0
	 WHERE deleg_plan_sid = v_test_deleg_plan_inactive_sid;

	deleg_plan_pkg.GetHiddenDelegPlans(out_cur => v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur 
		 INTO 
			v_cur_deleg_plan_sid,
			v_cur_name,
			v_cur_start_dtm,
			v_cur_end_dtm,
			v_cur_reminder_offset,
			v_cur_period_set_id,
			v_cur_period_interval_id,
			v_cur_period_interval_label,
			v_cur_schedule_xml,
			v_cur_dynamic,
			v_cur_parent_sid,
			v_cur_custom_date_schedule,
			v_cur_multiple_date_schedule,
			v_cur_can_write,
			v_cur_can_delete
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
		unit_test_pkg.AssertAreEqual(v_cur_deleg_plan_sid, v_test_deleg_plan_inactive_sid, 'Unexpected plan sid, found'||v_cur_deleg_plan_sid);
		unit_test_pkg.AssertAreEqual(v_cur_name, 'DELEGATION_PLAN_LIST_TEST_INACTIVE', 'Unexpected plan name, found'||v_cur_name);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 hidden plans, found'||v_count);


	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
	IF v_test_deleg_plan_inactive_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_inactive_sid, 1);
		v_test_deleg_plan_inactive_sid := NULL;
	END IF;
	
	security_pkg.SetContext('SID', v_logged_on_user);
END;

PROCEDURE MovingARegionOutRemovesRegionFromPlan
AS 
	v_test_deleg_plan_sid			NUMBER;
	v_deleg_plan_col_id				NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_MOVE_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2002-01-01',
		in_end_date				=>	DATE '2003-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_test_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	NULL,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(9)  -- DELEG_PLAN_REGION_2
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3); -- DELEG_PLAN_REGION_1_1_1
	 
	unit_test_pkg.AssertAreEqual(0, v_exist_count, 'Region not removed from plan.');
	
	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
END;

PROCEDURE MovingARegionOutMarksForDeletionForAppliedPlans
AS 
	v_test_deleg_plan_sid			NUMBER;
	v_deleg_plan_col_id				NUMBER;
	v_deleg_plan_col_deleg_id		NUMBER;
	v_dummy_num						NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_MOVE_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2002-01-01',
		in_end_date				=>	DATE '2003-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id, deleg_plan_col_deleg_id
	  INTO v_deleg_plan_col_id, v_deleg_plan_col_deleg_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_test_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.ApplyPlanToRegion(
		in_deleg_plan_sid				=> v_test_deleg_plan_sid,
		in_is_dynamic_plan				=> 0,
		in_name_template				=> 'N/A',
		in_deleg_plan_col_deleg_id		=> v_deleg_plan_col_deleg_id,
		in_master_delegation_name		=> 'N/A',
		in_maps_to_root_deleg_sid		=> NULL,
		in_apply_to_region_sid			=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_apply_to_region_lookup_key	=> NULL,
		in_apply_to_region_desc			=> NULL,
		in_plan_region_sid				=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_tpl_delegation_sid			=> v_delegation_sid,
		in_region_selection				=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_region_type					=> NULL,
		in_tag_id						=> NULL,
		in_overwrite_dates				=> 0,
		out_created						=> v_dummy_num
	);
	
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(9)  -- DELEG_PLAN_REGION_2
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3) -- DELEG_PLAN_REGION_1_1_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Region not marked as to be deleted.');
	
	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
END;

PROCEDURE MovingARegionBackInUnMarksForDeletionForAppliedPlans
AS 
	v_test_deleg_plan_sid			NUMBER;
	v_deleg_plan_col_id				NUMBER;
	v_deleg_plan_col_deleg_id		NUMBER;
	v_dummy_num						NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_MOVE_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2002-01-01',
		in_end_date				=>	DATE '2003-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id, deleg_plan_col_deleg_id
	  INTO v_deleg_plan_col_id, v_deleg_plan_col_deleg_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_test_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.ApplyPlanToRegion(
		in_deleg_plan_sid				=> v_test_deleg_plan_sid,
		in_is_dynamic_plan				=> 0,
		in_name_template				=> 'N/A',
		in_deleg_plan_col_deleg_id		=> v_deleg_plan_col_deleg_id,
		in_master_delegation_name		=> 'N/A',
		in_maps_to_root_deleg_sid		=> NULL,
		in_apply_to_region_sid			=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_apply_to_region_lookup_key	=> NULL,
		in_apply_to_region_desc			=> NULL,
		in_plan_region_sid				=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_tpl_delegation_sid			=> v_delegation_sid,
		in_region_selection				=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_region_type					=> NULL,
		in_tag_id						=> NULL,
		in_overwrite_dates				=> 0,
		out_created						=> v_dummy_num
	);
	
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(9)  -- DELEG_PLAN_REGION_2
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3); -- DELEG_PLAN_REGION_1_1_1
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Region not removed from plan.');
	
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(2)  -- DELEG_PLAN_REGION_1_1
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3) -- DELEG_PLAN_REGION_1_1_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(0, v_exist_count, 'Region still marked as to be deleted.');
	
	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
END;

PROCEDURE MovingARegionBackDoeNotUnMarkUnrelatedRegionsForDeletionForAppliedPlans
AS 
	v_test_deleg_plan_sid			NUMBER;
	v_deleg_plan_col_id				NUMBER;
	v_deleg_plan_col_deleg_id		NUMBER;
	v_dummy_num						NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_MOVE_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2002-01-01',
		in_end_date				=>	DATE '2003-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id, deleg_plan_col_deleg_id
	  INTO v_deleg_plan_col_id, v_deleg_plan_col_deleg_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_test_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	NULL,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(6), -- DELEG_PLAN_REGION_1_3_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.ApplyPlanToRegion(
		in_deleg_plan_sid				=> v_test_deleg_plan_sid,
		in_is_dynamic_plan				=> 0,
		in_name_template				=> 'N/A',
		in_deleg_plan_col_deleg_id		=> v_deleg_plan_col_deleg_id,
		in_master_delegation_name		=> 'N/A',
		in_maps_to_root_deleg_sid		=> NULL,
		in_apply_to_region_sid			=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_apply_to_region_lookup_key	=> NULL,
		in_apply_to_region_desc			=> NULL,
		in_plan_region_sid				=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_tpl_delegation_sid			=> v_delegation_sid,
		in_region_selection				=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_region_type					=> NULL,
		in_tag_id						=> NULL,
		in_overwrite_dates				=> 0,
		out_created						=> v_dummy_num
	);
	
	deleg_plan_pkg.ApplyPlanToRegion(
		in_deleg_plan_sid				=> v_test_deleg_plan_sid,
		in_is_dynamic_plan				=> 0,
		in_name_template				=> 'N/A',
		in_deleg_plan_col_deleg_id		=> v_deleg_plan_col_deleg_id,
		in_master_delegation_name		=> 'N/A',
		in_maps_to_root_deleg_sid		=> NULL,
		in_apply_to_region_sid			=> v_regs(6), -- DELEG_PLAN_REGION_1_3_1
		in_apply_to_region_lookup_key	=> NULL,
		in_apply_to_region_desc			=> NULL,
		in_plan_region_sid				=> v_regs(6), -- DELEG_PLAN_REGION_1_3_1
		in_tpl_delegation_sid			=> v_delegation_sid,
		in_region_selection				=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_region_type					=> NULL,
		in_tag_id						=> NULL,
		in_overwrite_dates				=> 0,
		out_created						=> v_dummy_num
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(6), -- DELEG_PLAN_REGION_1_3_1
		in_region_selection			=>	NULL,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(6) -- DELEG_PLAN_REGION_1_3_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Region not marked for deletion.');
	
	--Move out
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(9)  -- DELEG_PLAN_REGION_2
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3) -- DELEG_PLAN_REGION_1_1_1
	 AND pending_deletion = 1; 
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Region not marked for deletion.');
	
	-- Move Back
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(2)  -- DELEG_PLAN_REGION_1_1
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3) -- DELEG_PLAN_REGION_1_1_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(0, v_exist_count, 'Region still marked as to be deleted.');
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(6) -- DELEG_PLAN_REGION_1_3_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Unrelated region un-marked as to be deleted.');
	
	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
END;

PROCEDURE MovingARegionUnderAMarkedRegionMarksForDeletionForAppliedPlans
AS 
	v_test_deleg_plan_sid			NUMBER;
	v_deleg_plan_col_id				NUMBER;
	v_deleg_plan_col_deleg_id		NUMBER;
	v_dummy_num						NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_MOVE_TEST',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2002-01-01',
		in_end_date				=>	DATE '2003-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id, deleg_plan_col_deleg_id
	  INTO v_deleg_plan_col_id, v_deleg_plan_col_deleg_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_test_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	NULL,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(5), -- DELEG_PLAN_REGION_1_3
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.ApplyPlanToRegion(
		in_deleg_plan_sid				=> v_test_deleg_plan_sid,
		in_is_dynamic_plan				=> 0,
		in_name_template				=> 'N/A',
		in_deleg_plan_col_deleg_id		=> v_deleg_plan_col_deleg_id,
		in_master_delegation_name		=> 'N/A',
		in_maps_to_root_deleg_sid		=> NULL,
		in_apply_to_region_sid			=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_apply_to_region_lookup_key	=> NULL,
		in_apply_to_region_desc			=> NULL,
		in_plan_region_sid				=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_tpl_delegation_sid			=> v_delegation_sid,
		in_region_selection				=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_region_type					=> NULL,
		in_tag_id						=> NULL,
		in_overwrite_dates				=> 0,
		out_created						=> v_dummy_num
	);
	
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(5)  -- DELEG_PLAN_REGION_1_3
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3) -- DELEG_PLAN_REGION_1_1_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Region not marked as to be deleted.');
	
	-- Tidy
	region_pkg.MoveRegion(
		in_act_id 		=> security.security_pkg.GetACT,
		in_region_sid 	=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_parent_sid 	=> v_regs(2)  -- DELEG_PLAN_REGION_1_1
	);
	
	IF v_test_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_test_deleg_plan_sid, 1);
		v_test_deleg_plan_sid := NULL;
	END IF;
END;

PROCEDURE SelectingAParentRegionWillMarkAllChildSelectionsForDeletion
AS
	v_regions			security_pkg.T_SID_IDS;
	v_region_counts		security_pkg.T_SID_IDS;
	v_exist_count		NUMBER;
	v_deleg_plan_col_id security_pkg.T_SID_ID;
BEGIN
	v_apply_dynamic := 1;
	v_regions(1) := v_regs(3); -- DELEG_PLAN_REGION_1_1_1
	v_region_counts(1) := v_roles.COUNT;
	
	CreateAndApplyPlan(
		in_root_region			=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selected		=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection		=>	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
		in_tag_id				=>	NULL,
		in_region_type			=>	NULL,
		in_deleg_count			=>	v_roles.COUNT,
		in_deleg_regions		=>	v_regions,
		in_deleg_region_counts	=>	v_region_counts
	);
	
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM deleg_plan_deleg_region
	 WHERE region_sid = v_regs(3) -- DELEG_PLAN_REGION_1_1_1
	   AND pending_deletion = 1;
	 
	unit_test_pkg.AssertAreEqual(1, v_exist_count, 'Region not marked as to be deleted.');
	
END;

PROCEDURE ChangingSingleDelegationLevelDoesNotCreateDuplicateRegions
AS
	v_regions			security_pkg.T_SID_IDS;
	v_root_regions		security_pkg.T_SID_IDS;
	v_schedule_xml		CLOB :=  '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_region_counts		security_pkg.T_SID_IDS;
	v_created			NUMBER;
	v_generated_sheet	security_pkg.T_SID_ID;
	v_var_expl_ids		security_pkg.T_SID_IDS;
	v_changed_inds		SYS_REFCURSOR;
	v_exist_count		NUMBER;
	v_deleg_plan_col_id security_pkg.T_SID_ID;
BEGIN
	v_root_regions(1) := v_regs(1); -- DELEG_PLAN_REGION_1
	
	v_regions(1) := v_regs(2); -- DELEG_PLAN_REGION_1_1
	v_regions(2) := v_regs(5); -- DELEG_PLAN_REGION_1_3
	
	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2018-01-01',
		in_end_date			=>	DATE '2019-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_selected_regions	=>	v_regions,
		in_region_selection	=>	csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id			=>	NULL,
		in_region_type		=>	NULL
	);
	
	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	SELECT MAX(sheet_id)
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT MAX(delegation_sid) FROM delegation_region WHERE region_sid = v_regs(3));
	
	--Add value to ind in lowest level sheet
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(3),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	SELECT MAX(sheet_id)
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT MAX(delegation_sid) FROM delegation_region WHERE region_sid = v_regs(7));
	
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(7),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	SELECT MAX(sheet_id)
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT MAX(delegation_sid) FROM delegation_region WHERE region_sid = v_regs(8));
	
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(8),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);
	
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	DELETE FROM temp_deleg_plan_overlap;
	
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM delegation_region dr
	  JOIN delegation d ON d.delegation_sid = dr.delegation_sid
	 WHERE d.start_dtm = '01-JAN-2018' AND d.end_dtm = '01-JAN-2019'
	   AND d.master_delegation_sid = v_delegation_sid
	   AND region_sid IN (v_regs(3), v_regs(7), v_regs(8));
	
	unit_test_pkg.AssertAreEqual(v_roles.COUNT*3, v_exist_count, 'Duplicate regions created');
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM temp_deleg_plan_overlap;
	  
	unit_test_pkg.AssertAreEqual(3, v_exist_count, 'No overlaps created');
END;

PROCEDURE SelectingAChildRegionWillErrorIfParentSelected
AS 
	v_deleg_plan_col_id				NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>';
BEGIN
	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2002-01-01',
		in_end_date				=>	DATE '2003-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_deleg_plan_sid;
	
	BEGIN
		deleg_plan_pkg.UpdateDelegPlanColRegion(
			in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
			in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
			in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
			in_tag_id					=>	NULL,
			in_region_type				=>	NULL
		);
		
		unit_test_pkg.TestFail('Expecting an Exception here');
	EXCEPTION
		WHEN security.security_pkg.UNEXPECTED THEN
			NULL; -- Expected result
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('Unexpected Exception was thrown');
	END;
END;

PROCEDURE ChangingTypeRelinksExistingDelegations
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB := '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_changed_inds				SYS_REFCURSOR;
	v_generated_sheet			NUMBER(10);
	v_var_expl_ids				security_pkg.T_SID_IDS;
	v_deleg_plan_col_id			NUMBER(10);
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.ChangingTypeRelinksExistingDelegations');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2001-01-01',
		in_end_date			=>	DATE '2002-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_region_type		=>	4
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_deleg_region_deleg d1
	  JOIN deleg_plan_col d2 ON d1.deleg_plan_col_deleg_id = d2.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND applied_to_region_sid = v_regs(7);

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegations were not created.');

	--Get one of generated sheets and insert value
	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(7) AND ROWNUM = 1)
	   AND ROWNUM = 1;

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(7),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);

	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND delegation_sid = v_delegation_sid;

	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT,
		in_region_type				=>	NULL,
		in_tag_id 					=>	NULL
	);

	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_deleg_region_deleg d1
	  JOIN deleg_plan_col d2 ON d1.deleg_plan_col_deleg_id = d2.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND applied_to_region_sid = v_regs(7);

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegations were not adopted.');
END;

PROCEDURE PlanDoesNotRelinkDelegForSelfWhenRolloutChangedToChildren
AS
	v_act						security_pkg.T_ACT_ID;
	v_count						NUMBER(10);
	v_created					NUMBER;
	v_schedule_xml				CLOB := '<recurrence><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrence>';
	v_changed_inds				SYS_REFCURSOR;
	v_generated_sheet			NUMBER(10);
	v_var_expl_ids				security_pkg.T_SID_IDS;
	v_deleg_plan_col_id			NUMBER(10);
	v_exist_count				NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.test_delegation_plan_pkg.PlanDoesNotRelinkDelegForSelfWhenRolloutChangedToChildren');

	v_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 			=>	'DELEGATION_PLAN',
		in_delegation_sid 	=>	v_delegation_sid,
		in_root_regions		=>	v_root_regions,
		in_roles			=>	v_roles,
		in_start_date		=>	DATE '2001-01-01',
		in_end_date			=>	DATE '2002-01-01',
		in_schedule_xml		=>	v_schedule_xml,
		in_region_selection	=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION,
		in_region_type		=>	NULL
	);

	security.user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, SYS_CONTEXT('SECURITY', 'APP'), v_act);

	--Apply plan 
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_deleg_region_deleg d1
	  JOIN deleg_plan_col d2 ON d1.deleg_plan_col_deleg_id = d2.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND region_sid = v_regs(1);

	unit_test_pkg.AssertAreEqual(1, v_count, 'Delegations were not created.');

	--Get one of generated sheets and insert value
	SELECT sheet_id
	  INTO v_generated_sheet
	  FROM sheet
	 WHERE delegation_sid = (SELECT delegation_sid FROM delegation_region WHERE region_sid = v_regs(1) AND ROWNUM = 1)
	   AND ROWNUM = 1;

	--Add value to ind in one of the generated sheets
	delegation_pkg.SaveValue2(
		in_sheet_id					=>	v_generated_sheet,
		in_ind_sid					=>	v_inds(1),
		in_region_sid				=>	v_regs(1),
		in_entry_val_number			=>	100,
		in_entry_conversion_id		=>	NULL,
		in_note						=>	NULL,
		in_flag						=>	NULL,
		in_is_na					=>	0,
		in_var_expl_ids				=>	v_var_expl_ids,
		in_var_expl_note			=>	NULL,
		out_changed_inds_cur		=>	v_changed_inds
	);

	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = v_deleg_plan_sid
	   AND delegation_sid = v_delegation_sid;

	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT,
		in_region_type				=>	NULL,
		in_tag_id 					=>	NULL
	);
	
	DELETE FROM temp_deleg_plan_overlap;
	
	-- Reapply plan
	deleg_plan_pkg.TestOnly_ProcessApplyPlanJob(
		in_deleg_plan_sid	=>	v_deleg_plan_sid,
		in_is_dynamic_plan	=>	1,
		in_overwrite_dates	=>	0,
		out_created			=>	v_created
	);

	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM temp_deleg_plan_overlap;
	
	DELETE FROM temp_deleg_plan_overlap;
	
	unit_test_pkg.AssertAreEqual(4, v_exist_count, 'No overlaps created');
END;

PROCEDURE ApplyPlanCreatesSheetCreatedAlerts
AS 
	v_test_deleg_plan_sid			NUMBER;
	v_deleg_plan_col_id				NUMBER;
	v_deleg_plan_col_deleg_id		NUMBER;
	v_dummy_num						NUMBER;
	v_exist_count					NUMBER;
	v_schedule_xml					CLOB :=  '<recurrence><monthly every-n="1"><day number="1"></day></monthly></recurrence>';
BEGIN
	UPDATE alert_template
	   SET send_type = 'manual'
	 WHERE customer_alert_type_id = (SELECT customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CREATED);
	 
	v_test_deleg_plan_sid := unit_test_pkg.GetOrCreateDelegPlan(
		in_name 				=>	'DELEGATION_PLAN_ALERTS',
		in_delegation_sid 		=>	v_delegation_sid,
		in_root_regions			=>	v_root_regions,
		in_roles				=>	v_roles,
		in_start_date			=>	DATE '2021-01-01',
		in_end_date				=>	DATE '2022-01-01',
		in_schedule_xml			=>	v_schedule_xml,
		in_period_set_id		=> 	1,
		in_period_interval_id	=>	1
	);
	
	SELECT deleg_plan_col_id, deleg_plan_col_deleg_id
	  INTO v_deleg_plan_col_id, v_deleg_plan_col_deleg_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_test_deleg_plan_sid;
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(1), -- DELEG_PLAN_REGION_1
		in_region_selection			=>	NULL,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.UpdateDelegPlanColRegion(
		in_deleg_plan_col_id		=>	v_deleg_plan_col_id,
		in_region_sid				=>	v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_region_selection			=>	csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_tag_id					=>	NULL,
		in_region_type				=>	NULL
	);
	
	deleg_plan_pkg.ApplyPlanToRegion(
		in_deleg_plan_sid				=> v_test_deleg_plan_sid,
		in_is_dynamic_plan				=> 1,
		in_name_template				=> 'N/A',
		in_deleg_plan_col_deleg_id		=> v_deleg_plan_col_deleg_id,
		in_master_delegation_name		=> 'N/A',
		in_maps_to_root_deleg_sid		=> NULL,
		in_apply_to_region_sid			=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_apply_to_region_lookup_key	=> NULL,
		in_apply_to_region_desc			=> NULL,
		in_plan_region_sid				=> v_regs(3), -- DELEG_PLAN_REGION_1_1_1
		in_tpl_delegation_sid			=> v_delegation_sid,
		in_region_selection				=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
		in_region_type					=> NULL,
		in_tag_id						=> NULL,
		in_overwrite_dates				=> 0,
		out_created						=> v_dummy_num
	);
	
	SELECT COUNT(*)
	  INTO v_exist_count
	  FROM sheet_created_alert
	 WHERE sheet_id IN (
		SELECT sheet_id
		  FROM csr.sheet s
		  JOIN csr.deleg_plan_deleg_region_deleg d ON s.delegation_sid = d.maps_to_root_deleg_sid
		  JOIN csr.deleg_plan_col d2 ON d.deleg_plan_col_deleg_id = d2.deleg_plan_col_deleg_id
		 WHERE deleg_plan_sid = v_test_deleg_plan_sid
	);
	
	unit_test_pkg.AssertAreEqual(12, v_exist_count, 'Expected alerts generated');
	
	UPDATE alert_template
	   SET send_type = 'inactive'
	 WHERE customer_alert_type_id = (SELECT customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CREATED);
END;

PROCEDURE Trace(in_name VARCHAR2)
AS
BEGIN
	dbms_output.put_line(in_name);
	--NULL;
END;

PROCEDURE SetUp
AS
BEGIN
	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
	
	v_logged_on_user := unit_test_pkg.GetOrCreateUser('DELEG_PLAN_TEST_USER');
	
	-- Un-set the Built-in admin's user sid from the session,
	-- otherwise all permissions tests against any ACT will return true
	-- because of the internal workings of security pkgs
	security_pkg.SetContext('SID', v_logged_on_user);
END;

PROCEDURE TearDown
AS
	v_throwaway_id					NUMBER(10);
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	IF v_deleg_plan_sid IS NOT NULL THEN
		deleg_plan_pkg.DeleteDelegPlan(v_deleg_plan_sid, 1);
		v_deleg_plan_sid := NULL;
	END IF;

	-- Remove any delegations that aren't the master delegation
	FOR r IN(
		SELECT d.delegation_sid delegation_sid, md.delegation_sid is_master_deleg_sid
		  FROM delegation d
		  LEFT JOIN master_deleg md on d.delegation_sid = md.delegation_sid
		  WHERE md.delegation_sid IS NULL
	)
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;

	EXECUTE IMMEDIATE 'DELETE FROM csr.temp_deleg_test_schedule_entry';
	
	IF v_new_delegation_sid IS NOT NULL THEN
		deleg_plan_pkg.SetAsTemplate(v_new_delegation_sid, 0);
		security.securableobject_pkg.deleteso(security_pkg.getact, v_new_delegation_sid);
		v_new_delegation_sid := NULL;
	END IF;
	
	SELECT MIN(region_sid)
	  INTO v_throwaway_id
	  FROM csr.region
	 WHERE lookup_key = 'DELEG_PLAN_REGION_1_4';
	 
	IF v_throwaway_id IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact,v_throwaway_id);
		v_regs(10) := NULL;
	END IF;
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
	v_throwaway_id					NUMBER(10);
	v_throwaway_id2					NUMBER(10);
	v_single_region					SECURITY.security_pkg.T_SID_IDS;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	FOR r IN (
		SELECT deleg_plan_sid
		 FROM csr.deleg_plan
		WHERE name LIKE 'DELEGATION_PLAN%'
	)
	LOOP
		deleg_plan_pkg.DeleteDelegPlan(r.deleg_plan_sid, 1);
	END LOOP;
	
	TearDownFixture;
	
	SELECT MIN(region_sid)
	  INTO v_throwaway_id
	  FROM csr.region
	 WHERE lookup_key = 'DELEG_PLAN_REGION_1_3_1_1'; 
	 
	IF v_throwaway_id IS NOT NULL THEN
		region_pkg.SetRegionType(
			in_region_sid	=> v_throwaway_id,
			in_region_type	=> csr_data_pkg.REGION_TYPE_TENANT
		);
		
		SELECT MIN(tag_id)
		  INTO v_throwaway_id2
		  FROM tag
		 WHERE lookup_key = 'DPTEST_TAG_1';
		
		tag_pkg.RemoveRegionTag(
			in_act_id				=> security.security_pkg.getact,
			in_region_sid			=> v_throwaway_id,
			in_tag_id				=> v_throwaway_id2,
			in_apply_dynamic_plans	=> 1,
			out_rows_updated		=> v_throwaway_id2
		);
	END IF;
	
	--Anything that was left from messing with the delegation plan
	FOR r IN(
		SELECT delegation_sid 
		  FROM delegation
		 WHERE master_delegation_sid IS NOT NULL
	)
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
	
	SELECT MIN(region_sid)
	  INTO v_throwaway_id
	  FROM csr.region
	 WHERE lookup_key = 'DELEG_PLAN_REGION_1_4';
	 
	IF v_throwaway_id IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact,v_throwaway_id);
	END IF;
	
	SELECT MIN(region_sid)
	  INTO v_throwaway_id
	  FROM csr.region
	 WHERE lookup_key = 'DELEG_PLAN_REGION_1_2_1';
	 
	IF v_throwaway_id IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact,v_throwaway_id);
	END IF;
	
	EXECUTE IMMEDIATE 'DELETE FROM csr.temp_deleg_test_schedule_entry';
	
	SELECT MIN(region_sid)
	  INTO v_throwaway_id
	  FROM csr.region
	 WHERE lookup_key = 'DELEG_PLAN_REGION_2';
	 
	BEGIN
		v_single_region(1) := v_throwaway_id;
		csr.trash_pkg.RestoreObjects(v_single_region);
	EXCEPTION 
		WHEN OTHERS THEN
			NULL;
	END;	
	--END TIDY
	v_inds(1) := unit_test_pkg.GetOrCreateInd('DELEGATION_IND_1');
	
	v_new_inds(1) := unit_test_pkg.GetOrCreateInd('DELEGATION_IND_2');
	
	v_tag_group :=	unit_test_pkg.GetOrCreateTagGroup(
			in_lookup_key			=>	'DPTEST_TAG_GROUP_1',
			in_multi_select			=>	0,
			in_applies_to_inds		=>	0,
			in_applies_to_regions	=>	1,
			in_tag_members			=>	'DPTEST_TAG_1,DPTEST_TAG_2,DPTEST_TAG_3'
		);
	
	v_tags(1) := unit_test_pkg.GetOrCreateTag('DPTEST_TAG_1', v_tag_group);
	
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1');
	v_regs(2) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_1', v_regs(1), csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(3) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_1_1', v_regs(2));
	v_regs(4) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_2', v_regs(1), csr_data_pkg.REGION_TYPE_PROPERTY);	
	tag_pkg.SetRegionTags(security_pkg.getact, v_regs(4), v_tags);
	v_regs(5) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_3', v_regs(1));
	v_regs(6) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_3_1', v_regs(5), csr_data_pkg.REGION_TYPE_TENANT);
	tag_pkg.SetRegionTags(security_pkg.getact, v_regs(6), v_tags);
	v_regs(7) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_3_1_1', v_regs(6), csr_data_pkg.REGION_TYPE_TENANT);
	v_regs(8) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_1_3_1_2', v_regs(6), csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(9) := unit_test_pkg.GetOrCreateRegion('DELEG_PLAN_REGION_2');

	v_root_regions(1) := v_regs(1);

	v_roles(1) := unit_test_pkg.GetOrCreateRole('DELEG_PLAN_PROVIDER');
	v_roles(2) := unit_test_pkg.GetOrCreateRole('DELEG_PLAN_APPROVER');
	v_roles(3) := unit_test_pkg.GetOrCreateRole('DELEG_PLAN_FIN_APPROVER');
	
	v_users(1) := unit_test_pkg.GetOrCreateUser('USER_1');
	v_users(2) := unit_test_pkg.GetOrCreateUser('USER_2');
	v_users(3) := unit_test_pkg.GetOrCreateUser('USER_3');
	
	role_pkg.AddRoleMemberForRegion(
		in_role_sid		=> v_roles(1),
		in_region_sid	=> v_regs(1),
		in_user_sid 	=> v_users(1)
	);
	
	role_pkg.AddRoleMemberForRegion(
		in_role_sid		=> v_roles(2),
		in_region_sid	=> v_regs(1),
		in_user_sid 	=> v_users(2)
	);
	
	role_pkg.AddRoleMemberForRegion(
		in_role_sid		=> v_roles(3),
		in_region_sid	=> v_regs(1),
		in_user_sid 	=> v_users(3)
	);
	
	
	v_delegation_sid := unit_test_pkg.GetOrCreateDeleg('PLAN_DELEG_TEMPLATE', v_regs, v_inds);
	deleg_plan_pkg.SetAsTemplate(v_delegation_sid, 1);
	
	v_throwaway_id := unit_test_pkg.GetOrCreatePeriodSet;

	INTERNAL_SetUpAlertTemplates();
END;

PROCEDURE RemoveSids(
	v_sids		security_pkg.T_SID_IDS
)
AS
BEGIN
	IF v_sids.COUNT > 0 THEN
		FOR i IN REVERSE v_sids.FIRST..v_sids.LAST
		LOOP
			security.securableobject_pkg.deleteso(security_pkg.getact, v_sids(i));
		END LOOP;
	END IF;
END;

PROCEDURE TearDownFixture
AS
	v_sids		security.T_SID_TABLE;
	v_count		NUMBER;
	v_ignore_number	NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	FOR r IN (SELECT deleg_plan_sid FROM deleg_plan)
	LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.deleg_plan_sid);
	END LOOP;
	
	FOR r IN (SELECT d.delegation_sid FROM delegation d JOIN master_deleg m ON d.delegation_sid = m.delegation_sid WHERE name = 'PLAN_DELEG_TEMPLATE')
	LOOP
		deleg_plan_pkg.SetAsTemplate(r.delegation_sid, 0);
		security.securableobject_pkg.deleteso(security_pkg.getact, r.delegation_sid);
	END LOOP;
	
	IF v_tag_group IS NOT NULL THEN
		-- remove the tags from the regions
		FOR i in v_regs.FIRST..v_regs.LAST
		LOOP
			FOR j in v_tags.FIRST..v_tags.LAST
				LOOP
					csr.tag_pkg.RemoveRegionTag(
						in_act_id				=>	security_pkg.getact,
						in_region_sid			=>	v_regs(i),
						in_tag_id				=>	v_tags(j),
						in_apply_dynamic_plans	=>	0,
						out_rows_updated		=>  v_ignore_number
					);
			END LOOP;
		END LOOP;
		
		-- delete the tag group
		tag_pkg.DeleteTagGroup(security_pkg.getact, v_tag_group);
		v_tag_group := NULL;
	END IF;
	
	RemoveSids(v_regs);
	RemoveSids(v_roles);
	RemoveSids(v_new_roles);
	RemoveSids(v_inds);
	RemoveSids(v_new_inds);
	RemoveSids(v_users);
	
	DELETE FROM period_interval_member
	 WHERE period_set_id != 1;
	 
	DELETE FROM period_interval
	 WHERE period_set_id != 1;
	 
	DELETE FROM period_dates
	 WHERE period_set_id != 1;
	 
	DELETE FROM period
	 WHERE period_set_id != 1;
	 
	DELETE FROM period_set
	 WHERE period_set_id != 1;

	INTERNAL_TearDownAlertTemplates;
END;

END;
/