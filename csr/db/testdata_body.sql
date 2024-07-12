CREATE OR REPLACE PACKAGE BODY CSR.TestData_Pkg AS

---------------------------------------------------------------------------
-- Please make sure this script is rerunnable
-- The easiest way to check this is to run it twice each time you change it
-- and check any data you have added is not duplicated
---------------------------------------------------------------------------

-- some IDs need sharing between procedures, and it's more convenient to
-- declare global variables than to pass them back and forth
gv_region_root_sid					security.security_pkg.T_SID_ID; -- the root of the primary region tree
gv_main_test_region_sid				security.security_pkg.T_SID_ID; -- "UITestSuite Region - DO NOT DELETE"
gv_create_delete_del_reg_sid		security.security_pkg.T_SID_ID; -- "UITestSuite-CreateDeleteDelegReg-DoNotDelete"
gv_framework_region_sid				security.security_pkg.T_SID_ID; -- "UITestSuite-FrameworkRegion-DoNotDelete"
gv_audit_sid						security.security_pkg.T_SID_ID;
gv_audit_type_id					internal_audit_type.internal_audit_type_id%TYPE;
gv_property_ind_sid					security.security_pkg.T_SID_ID;
gv_host								customer.host%TYPE;
gv_approval_dashboard_ind_sid		security.security_pkg.T_SID_ID;
gv_approval_dashboard_reg_sid		security.security_pkg.T_SID_ID;
gv_uitest_user_sid					security.security_pkg.T_SID_ID;
gv_uitest_user1_sid					security.security_pkg.T_SID_ID;
gv_uitest_user2_sid					security.security_pkg.T_SID_ID;
gv_uitest_user3_sid					security.security_pkg.T_SID_ID;
gv_uitest_user_full_rights			security.security_pkg.T_SID_ID;

FUNCTION INTERNAL_GetHashMeasureSid
RETURN security.security_pkg.T_SID_ID
AS
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	SELECT measure_sid
	  INTO v_sid
	  FROM measure
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND name = '#';

	RETURN v_sid;
END;

PROCEDURE INTERNAL_CreateUser(
	in_name							IN	VARCHAR2,
	out_user_sid					OUT	security.security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT csr_user_sid
	  INTO out_user_sid
	  FROM csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND UPPER(user_name) = UPPER(in_name);
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		csr_user_pkg.CreateUser(
			in_act			 				=>	security.security_pkg.getAct,
			in_app_sid						=>	security.security_pkg.getApp,
			in_user_name					=>	in_name,
			in_password 					=>	'doesntMatter1Bit!',
			in_full_name					=>	in_name,
			in_friendly_name				=>	in_name,
			in_email		 				=>	in_name||'@invalid.invalid',
			in_job_title					=>  NULL,
			in_phone_number					=>  NULL,
			in_info_xml						=>  NULL,
			in_send_alerts					=>	0,
			in_enable_aria					=>  0,
			in_line_manager_sid				=>  NULL,
			in_chain_company_sid			=>  NULL,
			out_user_sid 					=>	out_user_sid
		);
END;

FUNCTION INTERNAL_CreateOrFindRegion(
	in_name							IN	region.name%TYPE,
	in_description					IN	region_description.description%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID			DEFAULT NULL,
	in_region_type					IN	region.region_type%TYPE					DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
)
RETURN security.security_pkg.T_SID_ID
AS
	v_parent_sid				security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_parent_sid := NVL(in_parent_sid, gv_region_root_sid);

	DBMS_OUTPUT.PUT_LINE('In INTERNAL_CreateOrFindRegion(' || in_name || ', ' || in_description || ', ' || in_parent_sid || ', ' || in_region_type || ')');

	BEGIN
		region_pkg.CreateRegion(
			in_parent_sid => v_parent_sid,
			in_name => in_name,
			in_description => in_description,
			in_region_type => in_region_type,
			out_region_sid => v_sid);

			DBMS_OUTPUT.PUT_LINE('- created new region with sid: ' || v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT region_sid
			  INTO v_sid
			  FROM region
			 WHERE parent_sid = v_parent_sid
			   AND name = in_name;

			DBMS_OUTPUT.PUT_LINE('- found existing region with sid: ' || v_sid);
	END;

	RETURN v_sid;
END;

FUNCTION INTERNAL_CreateOrFindMeterType
RETURN meter_type.meter_type_id%TYPE
AS
	v_meter_type				meter_type.meter_type_id%TYPE;
BEGIN
	BEGIN
		SELECT meter_type_id
		  INTO v_meter_type
		  FROM meter_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND label = 'TEST_METER_TYPE';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			meter_pkg.SaveMeterType(
				in_meter_type_id => NULL,
				in_label => 'TEST_METER_TYPE',
				in_group_key => 'TEST_METER_GROUP',
				in_days_ind_sid => NULL,
				in_costdays_ind_sid => NULL,
				out_meter_type_id => v_meter_type);
	END;

	RETURN v_meter_type;
END;

FUNCTION INTERNAL_CreateOrFindMeter(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	region.name%TYPE,
	in_description					IN	region_description.description%TYPE
)
RETURN security.security_pkg.T_SID_ID
AS
	v_sid						security.security_pkg.T_SID_ID;
	v_region_type				region_type.label%TYPE;
	v_contract_ids				security_pkg.T_SID_IDS;
BEGIN
	BEGIN
		SELECT r.region_sid, rt.label
		  INTO v_sid, v_region_type
		  FROM region r
		  JOIN region_type rt ON r.region_type = rt.region_type
		 WHERE r.parent_sid = in_parent_sid
		   AND r.name = in_name;

		IF v_region_type NOT IN ('Meter', 'Real-time meter') THEN
			RAISE_APPLICATION_ERROR(-20001, 'Expected Meter region; got ' || v_region_type);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_sid := INTERNAL_CreateOrFindRegion(
				in_name => in_name,
				in_description => in_description,
				in_parent_sid => in_parent_sid,
				in_region_type => csr_data_pkg.REGION_TYPE_METER);

			meter_pkg.MakeMeter(
				in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
				in_region_sid => v_sid,
				in_meter_type_id => INTERNAL_CreateOrFindMeterType,
				in_note => NULL,
				in_source_type_id => 2, -- same default as meter_pkg.CreateMeter
				in_manual_data_entry => 0, -- will be needed for the latest import from subversion
				in_reference => NULL,
				in_contract_ids => v_contract_ids,
				in_active_contract_id => NULL
			);
	END;

	RETURN v_sid;
END;

FUNCTION INTERNAL_GetMainRegionSid
RETURN security.security_pkg.T_SID_ID
AS
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_sid
	  FROM v$region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND description = 'UITestSuite Region - DO NOT DELETE';

	RETURN v_sid;
END;

FUNCTION INTERNAL_CreateOrFindIndicator(
	in_name							IN	ind.name%TYPE,
	in_description					IN	ind_description.description%TYPE,
	in_measure_sid					IN	security.security_pkg.T_SID_ID, -- passing in NULL here will create a folder not an indicator with values
	in_divisibility					IN	ind.divisibility%TYPE					DEFAULT NULL,
	in_aggregate					IN	ind.aggregate%TYPE						DEFAULT 'NONE'
)
RETURN security.security_pkg.T_SID_ID
AS
	v_ind_root_sid				security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id => v_ind_root_sid,
			in_name => in_name,
			in_description => in_description,
			in_measure_sid => in_measure_sid,
			in_divisibility => in_divisibility,
			in_aggregate => in_aggregate,
			out_sid_id => v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT ind_sid
			  INTO v_sid
			  FROM ind
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND name = in_name;
	END;

	RETURN v_sid;
END;

PROCEDURE INTERNAL_CreateRegions
AS
	v_ignore						security.security_pkg.T_SID_ID;
	v_analysis_region_sid			security.security_pkg.T_SID_ID;
	v_parent_region_for_db_sid		security.security_pkg.T_SID_ID;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Creating regions');

	gv_main_test_region_sid := INTERNAL_CreateOrFindRegion('UITestSuit_ELETE',  'UITestSuite Region - DO NOT DELETE');
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_lete,2', 'UITestSuite-CreateDelegsOnSameReg-DoNotDelete');
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_elete2', 'UITestSuite-CreateDeleteDeleg-DoNotDelete'); -- old (but tests might still need it?)
	gv_create_delete_del_reg_sid := INTERNAL_CreateOrFindRegion('UITestSuit_CDDR', 'UITestSuite-CreateDeleteDelegReg-DoNotDelete');
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_lete,',  'UITestSuite-CreateDupDelegsTest-DoNotDelete');
	gv_approval_dashboard_reg_sid := INTERNAL_CreateOrFindRegion('UITestR_ApprovalD',  'UiTestRegionApprovalDashboard-DoNotDelete');

	v_ignore := INTERNAL_CreateOrFindMeter(gv_region_root_sid, 'UITestSuit_lete3,', 'UITestSuite Meter - Do not delete');

	-- new regions needed for tests created by Mindtree
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_CDDR_S', 'UITestSuite-CreateDeleteDelegReg-DoNotDelete_Split', gv_create_delete_del_reg_sid);
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_CDDR_R', 'UITestSuite-CreateDeleteDelegRegRename-DoNotDelete');
	-- "Unmapped meters" ... virtual region created by the metering framework?
	v_analysis_region_sid := INTERNAL_CreateOrFindRegion('UITestSuit_AR',  'UITestSuite-AnalysisReg-DoNotDelete');
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_ARC',  'UITestSuite-AnalysisRegChild-DoNotDelete', v_analysis_region_sid);
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_ARC2',  'UITestSuite-AnalysisRegChild2-DoNotDelete', v_analysis_region_sid);
	gv_framework_region_sid := INTERNAL_CreateOrFindRegion('UITestSuit_FRDND',  'UITestSuite-FrameworkRegion-DoNotDelete');
	v_ignore := INTERNAL_CreateOrFindRegion('UITestSuit_IRDND',  'UITestSuite-RegionForIssues-DoNotDelete');
	v_parent_region_for_db_sid := INTERNAL_CreateOrFindRegion('UITestParentRFD', 'ParentRegionForDataBrowser-DoNotDelete'); 
	v_ignore := INTERNAL_CreateOrFindRegion('UITestRFD', 'RegionForDataBrowser-DoNotDelete', v_parent_region_for_db_sid); 
END;

-- TODO update the tests and the test databases so this isn't necessary
PROCEDURE INTERNAL_RenameMenus
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	--Rename issues menu item
	BEGIN
		v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/data/csr_issue');
		security.menu_pkg.SetMenu(v_act_id, v_menu_sid, 'Queries', '/csr/site/issues/issueList.acds', 4, NULL);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Issue menu item not found. Run utils\EnableIssues2');
	END;

	-- Point tpl reports at the old version for now:
	-- EDIT: does not exist any more so can't do that!
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/analysis/csr_reports_word');
	security.menu_pkg.SetMenu(v_act_id, v_menu_sid, 'Templated reports', '/csr/site/reports/word2/reports.acds', 3, NULL);

	-- Add a tag groups menu item under admin (if there isn't one already)
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_schema_tag_groups', 'Tag groups', '/csr/site/schema/new/tagGroups.acds', 10, NULL, v_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Add a QC user list menu item under admin (if there isn't one already)
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_users_userlist', 'User list SM', '/csr/site/users/list/list.acds', 11, NULL, v_menu_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

-- we should never have allowed users to pick different superadmin users in C:\cvs\UITestSuite\TestSuiteData\TestSuiteConfig.xml
-- but, since we have, try to pick the right user as best we can
FUNCTION INTERNAL_GetSuperAdminUserSid
RETURN security.security_pkg.T_SID_ID
AS
	v_superadmin_user_sid		security.security_pkg.T_SID_ID;
BEGIN
	SELECT csr_user_sid
	  INTO v_superadmin_user_sid
	  FROM (
		SELECT csr_user_sid
		  FROM csr.csr_user
		 WHERE UPPER(user_name) IN ('SUPERUSER', 'NEWADMIN', 'UITESTUSER')
		 ORDER BY CASE
		 	WHEN user_name = 'SUPERUSER' THEN 3
			WHEN user_name = 'NEWADMIN' THEN 2
			WHEN user_name = 'UITESTUSER' THEN 1
		 END
	)
	WHERE ROWNUM = 1;

	RETURN v_superadmin_user_sid;
END;

PROCEDURE UNSEC_AddGroupMember(
	in_member_sid	IN security.security_pkg.T_SID_ID,
	in_group_sid	IN security.security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END;

PROCEDURE INTERNAL_CreateUsers
AS
	v_user_sid						security.security_pkg.T_SID_ID;
	v_group_data_contributors_sid	security.security_pkg.T_SID_ID;
	v_administrators_group			security.security_pkg.T_SID_ID;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Creating super admin');

	BEGIN
		BEGIN
			v_user_sid := INTERNAL_GetSuperAdminUserSid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr_user_pkg.createSuperAdmin(
					in_act			 				=>	security.security_pkg.GetAct,
					in_user_name					=>	'UITestUser',
					in_password 					=>	'qwerty123',
					in_full_name					=>	'UITestUser',
					in_friendly_name				=>	'UITestUser',
					in_email		 				=>	'UITestUser@credit360.com',
					out_user_sid 					=>	v_user_sid
				);
		END;

		-- but make it "not hidden" so it appears in user pickers
		UPDATE csr_user
		   SET hidden = 0
		 WHERE csr_user_sid = v_user_sid;
	END;

	DBMS_OUTPUT.PUT_LINE('Creating users');

	-- creating the superuser logs us out?
	security.user_pkg.logonadmin(gv_host);

	INTERNAL_CreateUser('uitest1', v_user_sid);
	INTERNAL_CreateUser('uitest2', v_user_sid);
	INTERNAL_CreateUser('uitest3', v_user_sid);
	INTERNAL_CreateUser('uitest4', v_user_sid);
	INTERNAL_CreateUser('TestUser_DONOTDELETE_SETPASS', v_user_sid);

	-- users for tests on SM user list page
	INTERNAL_CreateUser('noGroupBulk', v_user_sid);
	INTERNAL_CreateUser('noDeactBulk', v_user_sid);
	INTERNAL_CreateUser('noEmailBulk', v_user_sid);

	-- users for Mindtree
	INTERNAL_CreateUser('UITestUser_DoNotDelete', gv_uitest_user_sid);
	INTERNAL_CreateUser('UITestUser_DoNotDelete1', gv_uitest_user1_sid);
	INTERNAL_CreateUser('UITestUser_DoNotDelete2', gv_uitest_user2_sid);
	INTERNAL_CreateUser('UITestUser_DoNotDelete3', gv_uitest_user3_sid);

	INTERNAL_CreateUser('UITestUser-WithfullRights-DoNotDelete', gv_uitest_user_full_rights);

	v_group_data_contributors_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Data Contributors');
	v_administrators_group := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Administrators');

	UNSEC_AddGroupMember(gv_uitest_user3_sid, v_group_data_contributors_sid);
	UNSEC_AddGroupMember(gv_uitest_user_full_rights, v_group_data_contributors_sid);
	UNSEC_AddGroupMember(gv_uitest_user_full_rights, v_administrators_group);	
END;

PROCEDURE INTERNAL_CreateMeasures
AS
	PROCEDURE CreateMeasure(
		in_name						IN	measure.name%TYPE,
		in_description				IN	measure.description%TYPE,
		in_custom_field				IN	measure.custom_field%TYPE				DEFAULT NULL,
		in_divisibility				IN	measure.divisibility%TYPE				DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
	)
	AS
		v_measure_sid			security.security_pkg.T_SID_ID;
	BEGIN
		SELECT measure_sid
		  INTO v_measure_sid
		  FROM measure
		 WHERE LOWER(name) = in_name
		   AND app_sid = security.security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name				=> in_name,
				in_description		=> in_description,
				in_custom_field		=> in_custom_field,
				in_divisibility		=> in_divisibility,
				out_measure_sid		=> v_measure_sid
			);
	END;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Creating measures');

	CreateMeasure('quick_survey_score', 'Score');
	CreateMeasure('text', 'Text', '|');
	CreateMeasure('#', '#', NULL, csr_data_pkg.DIVISIBILITY_LAST_PERIOD);
END;

PROCEDURE INTERNAL_CreateIndicators
AS
	v_ind_calc_target			security.security_pkg.T_SID_ID;
	v_calc_ind_sid				security.security_pkg.T_SID_ID;
	v_action_progress_measure	security.security_pkg.T_SID_ID;
	v_text_measure				security.security_pkg.T_SID_ID;
	v_ignore					security.security_pkg.T_SID_ID;
	v_quality_indicator_sid		security.security_pkg.T_SID_ID;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Creating indicators');

	SELECT measure_sid
	  INTO v_text_measure
	  FROM measure
	 WHERE app_sid = security.security_pkg.GetApp
	   AND LOWER(name) = 'text';

	BEGIN
		SELECT measure_sid
		  INTO v_action_progress_measure
		  FROM measure
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND name = 'action_progress';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			enable_pkg.EnableActions;

			SELECT measure_sid
			  INTO v_action_progress_measure
			  FROM measure
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND name = 'action_progress';
	END;

	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_elete2',
		in_description	=>	'UITestSuite-CreateDelegsOnSameInd-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_elete',
		in_description	=>	'UITestSuite-CreateDeleteDelegInd-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure,
		in_aggregate	=>	'SUM'
	);
	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_elete3',
		in_description	=>	'UITestSuite-CreateDupDelegsTest-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure
	);
	gv_property_ind_sid := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_elete4',
		in_description	=>	'UITestSuite-PropertyRegionMetric-DoNotDelete',
		in_measure_sid	=>  v_text_measure,
		in_aggregate	=>	'NONE'
	);

	-- inds for Excel Models

	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_ELETE5',
		in_description	=>	'UITestSuite Ind - DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);

	v_calc_ind_sid := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_elete6',
		in_description	=>	'UITestSuite-CalculatedIndicator-DoNotDelete',
		in_measure_sid	=>	INTERNAL_GetHashMeasureSid,
		in_divisibility	=>	csr_data_pkg.DIVISIBILITY_LAST_PERIOD
	);
	indicator_pkg.SetCalcXML(
		in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_calc_ind_sid			=> v_calc_ind_sid,
		in_calc_xml				=> '<path sid="'||v_ind_calc_target||'" description="UITestSuite Ind - DO NOT DELETE" node-id="1"/>'
	);

	-- inds for Delegation
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND1',
		in_description	=>	'UITestSuite Ind-1- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND2',
		in_description	=>	'UITestSuite Ind-2- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND3',
		in_description	=>	'UITestSuite Ind-3- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND4',
		in_description	=>	'UITestSuite Ind-4- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND5',
		in_description	=>	'UITestSuite Ind-5- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND6',
		in_description	=>	'UITestSuite Ind-6- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND7',
		in_description	=>	'UITestSuite Ind-7- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND8',
		in_description	=>	'UITestSuite Ind-8- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	v_ind_calc_target := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IND9',
		in_description	=>	'UITestSuite Ind-9- DO NOT DELETE',
		in_measure_sid	=>	v_action_progress_measure
	);
	
	-- inds for approval dashboards
	gv_approval_dashboard_ind_sid := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestI_ApprovalD',
		in_description	=>	'UiTestIndicatorApprovalDashboard-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure
	);

	-- other indicators introduced by Mindtree
	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_MCDND1',
		in_description	=>	'UITestSuite Meter Consumption-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure
	);

	v_quality_indicator_sid := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_QIDND1',
		in_description	=>	'UITestSuite-QualityIndicator-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure,
		in_aggregate	=>	'SUM'
	);

	DECLARE
		v_flags			csr_data_pkg.T_VARCHAR_ARRAY;
		v_requires_note	csr_data_pkg.T_NUMBER_ARRAY;
	BEGIN
		SELECT 'Estimate'
		  BULK COLLECT INTO v_flags
		  FROM DUAL;

		SELECT 0
		  BULK COLLECT INTO v_requires_note
		  FROM DUAL;

		indicator_pkg.SetFlags(
			in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
			in_ind_sid => v_quality_indicator_sid,
			in_flags => v_flags,
			in_requires_note => v_requires_note
		);
	END;

	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_VIDND1',
		in_description	=>	'UITestSuite-VisibilityIndicator-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure,
		in_aggregate	=>	'SUM'
	);

	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_AIDND1',
		in_description	=>	'UITestSuite-AnalysisInd-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure
	);

	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_FAIDND',
		in_description	=>	'UITestSuite-FrameworkAttachmentIndicator-DoNotDelete',
		in_measure_sid	=>	v_text_measure,
		in_aggregate	=>	'NONE'
	);

	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IDND',
		in_description	=>	'UITestSuiteInd-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure,
		in_aggregate	=>	'SUM'
	);

	v_ignore := INTERNAL_CreateOrFindIndicator(
		in_name			=>	'UITestSuit_IFDB',
		in_description	=>	'IndicatorForDataBrowser-DoNotDelete',
		in_measure_sid	=>	v_action_progress_measure
	);
END;

PROCEDURE INTERNAL_CreatePtyRegionMetric
AS
	v_out_metric				SYS_REFCURSOR;
	v_out_reg_types				SYS_REFCURSOR;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Create a region metric for the property ind.');

	region_metric_pkg.SaveRegionMetric(
		in_ind_sid				=> gv_property_ind_sid,
		in_is_mandatory			=> 0,
		in_element_pos			=> 1,
		in_region_types			=> '3',
		in_show_measure			=> 1,
		out_cur					=> v_out_metric,
		out_region_types_cur	=> v_out_reg_types
	);
END;

PROCEDURE INTERNAL_AddScorecarding(
	in_cms_user						IN	VARCHAR2
)
AS
	v_project_sid				NUMBER;
	v_task_status_id			NUMBER;
BEGIN
	actions.project_pkg.CreateProject(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_name						=> 'UITestSuiteProject-DoNotDelete',
		in_start_dtm				=> DATE '2012-01-01',
		in_duration					=> 120,
		in_max_period_duration		=> 1,
		in_task_fields_xml			=> '<fields/>',
		in_task_period_fields_xml	=> '<fields/>',
		out_project_sid				=> v_project_sid
	);

	actions.setup_pkg.SetTaskStatus(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid		=> SYS_CONTEXT('SECURITY', 'APP'),
		in_id			=> -1,
		in_label		=> 'UITestSuiteStatus-DoNotDelete',
		in_is_live		=> 1,
		in_colour		=> 16323861,	-- Red same number everywhere.
		in_is_default	=> 1,
		out_id			=> v_task_status_id
	);

	-- Link task status to project.
	actions.setup_pkg.AddAssociatedProjects(
		in_act_id	=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid	=> SYS_CONTEXT('SECURITY', 'APP'),
		in_id		=> v_task_status_id,
		in_type		=> 'task_status',
		in_sids		=> v_project_sid
	);

	-- TODO probably need to call actions.project_pkg.SetRoleMembers too
	-- but this wasn't specified in the wiki
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		DBMS_OUTPUT.PUT_LINE('Skipping scorecarding - already set up');
END;

PROCEDURE INTERNAL_AddGermanLanguage
AS
	v_lang_id					aspen2.lang.lang_id%TYPE;
BEGIN
	SELECT lang_id
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = 'de-de';

	csr_app_pkg.AddApplicationTranslation(
		in_application_sid => SYS_CONTEXT('SECURITY', 'APP'),
		in_lang_id => v_lang_id
	);
END;

PROCEDURE INTERNAL_AddMoreModules
AS
BEGIN
	BEGIN
		enable_pkg.EnableDocLib;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableTemplatedReports;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableSurveys;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableIssues2;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableImageChart;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableScenarios;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableFrameworks;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- doesn't seem properly rerunnable, so only enable Corporate Reporter if we haven't already
	DECLARE
		v_workflow_sid				security.security_pkg.T_SID_ID;
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Corporate Reporter');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				enable_pkg.EnableCorpReporter;
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					NULL;
			END;
	END;

	BEGIN
		enable_pkg.EnableMeteringBase;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableMeterUtilities;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableRealtimeMetering;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableAutomatedExportImport;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableMeteringFeeds;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableMeterMonitoring;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableMeterReporting;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableMeteringGapDetection;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableMeteringAutoPatching;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableUrjanet('UITESTSUITE-FTP-PATH');
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		util_script_pkg.EnableMeterWashingMachine;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableCalendar;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableDivisions;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableAudit;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		csr.enable_pkg.EnableForecasting;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		csr.enable_pkg.EnableActions;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		csr.enable_pkg.EnableCarbonEmissions;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		csr.enable_pkg.EnableEmFactorsProfileTool(1, -1);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		csr.enable_pkg.EnableApprovalDashboards;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- "Portal Dashboards"
	BEGIN
		csr.enable_pkg.EnableMultipleDashboards;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;

PROCEDURE INTERNAL_SetUpPropertyTypes
AS
BEGIN
	INSERT INTO property_type (property_type_id, label)
		SELECT property_type_id_seq.NEXTVAL, labels.label
		  FROM (
			SELECT 'Office' label FROM DUAL
			UNION ALL
			SELECT 'Warehouse' FROM DUAL
		) labels;

	INSERT INTO space_type (space_type_id, label, is_tenantable)
		SELECT space_type_id_seq.NEXTVAL, labels.label, 0
		  FROM (
			SELECT 'Common' label FROM DUAL
			UNION ALL
			SELECT 'Parking' FROM DUAL
		) labels;

	INSERT INTO property_type_space_type (property_type_id, space_type_id)
		SELECT property_type_id, space_type_id
		  FROM property_type
		 CROSS JOIN space_type;
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- They are already in the group
		NULL;
END;

PROCEDURE INTERNAL_SetUpPropertyRoles
AS
	v_role_sid		role.role_sid%TYPE;
	v_roles			T_VARCHAR2_TABLE;
	v_role			VARCHAR2(4000);
BEGIN
	v_roles := T_VARCHAR2_TABLE('Invoice owner', 'Meter administrator', 'Meter reader', 'Property Manager');

	FOR i IN 1..v_roles.COUNT LOOP
		v_role := v_roles(i);

		-- SetRole only creates a new role if one doesn't exist with the same name
		role_pkg.SetRole(
			in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
			in_role_name => v_role,
			in_lookup_key => NULL,
			out_role_sid => v_role_sid);

		role_pkg.SetRoleFlags(
			in_role_sid => v_role_sid,
			in_is_property_manager => 1);

		BEGIN
			INSERT INTO property_mandatory_roles (role_sid)
			VALUES (v_role_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;

PROCEDURE INTERNAL_CreateFundType
AS
	v_dummy_cur		security.security_pkg.T_OUTPUT_CUR;
	v_fund_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_fund_count
	  FROM fund_type
	 WHERE label = 'UITestSuite-FundType-DoNotDelete';

	IF v_fund_count = 0 THEN
		-- Fund types.
		property_pkg.SaveFundType(
			in_fund_type_id		=> -1,
			in_fund_type_label	=> 'UITestSuite-FundType-DoNotDelete',
			out_cur				=> v_dummy_cur
		);
	END IF;
END;

PROCEDURE INTERNAL_SetUpAlertTemplates
AS
	v_frame_id		security.security_pkg.T_SID_ID;
BEGIN
	alert_pkg.GetOrCreateFrame('Default', v_frame_id);

	alert_pkg.saveTemplateAndBody(alert_pkg.GetCustomerAlertType(csr_data_pkg.ALERT_NEW_USER), v_frame_id, 'manual', NULL, NULL, 'en',
		'<template>Sbj</template>', '<template>Msg</template>', '<template></template>');

	alert_pkg.saveTemplateAndBody(alert_pkg.GetCustomerAlertType(csr_data_pkg.ALERT_GENERIC_MAILOUT), v_frame_id, 'manual', NULL, NULL, 'en',
		'<template>Sbj</template>', '<template>Msg</template>', '<template></template>');
END;

PROCEDURE INTERNAL_SetUpBulkSmUserList
AS
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_user_sid				security.security_pkg.T_SID_ID;
	v_count					NUMBER;
	v_admin_group_sid		security.security_pkg.T_SID_ID;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM security.securable_object
	 WHERE name = 'Can deactivate users list page'
	   AND class_id = 100043;

	IF v_count > 0 THEN
		RETURN;
	END IF;

	csr_data_pkg.enablecapability('Can manage group membership list page');
	csr_data_pkg.enablecapability('Can deactivate users list page');
	csr_data_pkg.enablecapability('Message users');

	-- denying capabilities for some users and adding to admin group
	v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'),
		'/Capabilities/Can manage group membership list page');

	v_admin_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct,
		security.security_pkg.Getapp, 'Groups/Administrators');

	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'noGroupBulk';

	UNSEC_AddGroupMember(v_user_sid,v_admin_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_capability_sid),
		-2, security.security_pkg.ACE_TYPE_DENY, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);

	v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'),
		'/Capabilities/Can deactivate users list page');

	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'noDeactBulk';

	UNSEC_AddGroupMember(v_user_sid,v_admin_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_capability_sid),
		-2, security.security_pkg.ACE_TYPE_DENY, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);

	v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'),
		'/Capabilities/Message users');

	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'noEmailBulk';

	UNSEC_AddGroupMember(v_user_sid,v_admin_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_capability_sid),
		-2, security.security_pkg.ACE_TYPE_DENY, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL);
END;

PROCEDURE INTERNAL_SetupTabOptionTests
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_out_tab_id				tab.tab_id%TYPE;
	v_everyone_group			security.security_pkg.T_SID_ID;
	v_my_data_tab				number(10);
	v_count						number(10);
	v_user_sid					security.security_pkg.T_SID_ID;
	v_add_portal_tabs_sid		security.security_pkg.T_SID_ID;
	v_manage_any_port_sid		security.security_pkg.T_SID_ID;
	v_data_contributor_group	security.security_pkg.T_SID_ID;
	v_administrators_group		security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;

	PROCEDURE AddAcl(
		in_user_sid						IN	security.security_pkg.T_SID_ID,
		in_so_sid						IN	security.security_pkg.T_SID_ID
	)
	AS
	BEGIN
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(in_so_sid),
			security.security_pkg.ACL_INDEX_LAST,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			in_user_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL
		);
	END;
BEGIN
	v_act_id := security.security_pkg.getAct;
	v_app_sid := security.security_pkg.getApp;
	csr_data_pkg.enablecapability('Add portal tabs');
	csr_data_pkg.enablecapability('Manage any portal');
	v_add_portal_tabs_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities/Add portal tabs');
	v_manage_any_port_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities/Manage any portal');

	v_data_contributor_group := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Data Contributors');
	v_administrators_group := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
	v_groups_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');

	SELECT COUNT(user_name)
	  INTO v_count
	  FROM csr_user
	 WHERE user_name = 'uitest3';

	IF v_count = 0 THEN
		INTERNAL_CreateUser('uitest3', v_user_sid);
		AddAcl(v_user_sid, v_add_portal_tabs_sid);
		AddAcl(v_user_sid, v_manage_any_port_sid);
		AddAcl(v_user_sid, v_groups_sid);
		security.group_pkg.addMember(v_act_id, v_user_sid, v_data_contributor_group);

		INTERNAL_CreateUser('uitest4', v_user_sid);
		AddAcl(v_user_sid, v_add_portal_tabs_sid);
		AddAcl(v_user_sid, v_groups_sid);
		security.group_pkg.addMember(v_act_id, v_user_sid, v_data_contributor_group);
		security.group_pkg.addMember(v_act_id, v_user_sid, v_administrators_group);
		
		INTERNAL_CreateUser('TestUser_DONOTDELETE_SETPASS', v_user_sid);
		security.group_pkg.addMember(v_act_id, v_user_sid, v_administrators_group);

		v_count := 0;
	END IF;

	SELECT COUNT(tab_id)
	  INTO v_count
	  FROM tab
	 WHERE name = 'testTabOptions';

	IF v_count = 0 THEN
		portlet_pkg.AddTabReturnTabId(
			in_app_sid => v_app_sid,
			in_tab_name => 'testTabOptions',
			in_is_shared => 1,
			in_is_hideable => 1,
			in_layout => 2,
			in_portal_group => NULL,
			out_tab_id => v_out_tab_id
		);

		v_everyone_group := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Everyone');

		portlet_pkg.AddTabForGroup(
			in_group_sid => v_everyone_group,
			in_tab_id => v_out_tab_id
		);

		SELECT MAX(tab_id)
		  INTO v_my_data_tab
		  FROM tab
		 WHERE name = 'My data';

		portlet_pkg.AddTabForGroup(
			in_group_sid => v_everyone_group,
			in_tab_id => v_my_data_tab
		);
	END IF;
END;

PROCEDURE INTERNAL_SetupLikeForLike
AS
	v_sid						security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_likeforlike	security.security_pkg.T_SID_ID;
	v_admin_menu_sid			security.security_pkg.T_SID_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Adding like for like container
	BEGIN
		security.Securableobject_Pkg.CreateSO(security.security_pkg.GetAct, security.security_pkg.GetApp, security.security_pkg.SO_CONTAINER, 'Like for like datasets', v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-- Setting default max number of slots
	UPDATE customer
	   SET like_for_like_slots = 4
	 WHERE app_sid = security.security_pkg.GetApp;

	-- Web resource
	v_www_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_www_sid, 'csr/site');

	BEGIN
		v_www_csr_site_likeforlike := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_www_csr_site, 'likeForLike');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(
				in_act_id => security.security_pkg.GetAct,
				in_web_root_sid_id => v_www_sid,
				in_parent_sid_id => v_www_csr_site,
				in_page_name => 'likeForLike',
				in_rewrite_path => NULL,
				out_page_sid_id => v_www_csr_site_likeforlike
			);
	END;

	-- Add administrators to web resource
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_groups_sid, 'Administrators');

	security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_likeforlike), -1,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	-- Creating like for like scenario
	like_for_like_pkg.CreateScenario;

	-- Menu
	v_admin_menu_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'menu/admin');

	BEGIN
		security.menu_pkg.CreateMenu(
			in_act_id => security.security_pkg.GetAct,
			in_parent_sid_id => v_admin_menu_sid,
			in_name => 'csr_like_for_like_admin',
			in_description => 'Like for like',
			in_action => '/csr/site/likeForLike/LikeForLikeList.acds',
			in_pos => -1,
			in_context => NULL,
			out_sid_id => v_menu_sid
		);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL; -- link already exists
	END;
END;

PROCEDURE INTERNAL_SetupFactorSets
AS
	v_app_sid					security.security_pkg.T_SID_ID;
	v_factor_set_group_id		security.security_pkg.T_SID_ID;
	v_custom_factor_set_id		security.security_pkg.T_SID_ID;

	PROCEDURE CreateStdFactorSet(
		in_name			VARCHAR2,
		in_published	NUMBER
	)
	AS
		v_std_factor_set_id		security.security_pkg.T_SID_ID;
	BEGIN
		INSERT INTO csr.std_factor_set (std_factor_set_id, name, factor_set_group_id, published)
		VALUES (csr.factor_set_id_seq.nextval, in_name, v_factor_set_group_id, in_published)
		RETURNING std_factor_set_id INTO v_std_factor_set_id;

		INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, std_measure_conversion_id, start_dtm, value)
		VALUES (csr.std_factor_id_seq.nextval, v_std_factor_set_id, 3, 1, 17, TRUNC(SYSDATE, 'MON'), 0.5);
	END;
BEGIN
	v_app_sid := security.security_pkg.getApp;

	csr.csr_data_pkg.EnableCapability('Can import std factor set', 1);
	csr.csr_data_pkg.EnableCapability('Can publish std factor set', 1);

	BEGIN
		INSERT INTO csr.factor_set_group (factor_set_group_id, name)
		VALUES (csr.FACTOR_SET_GRP_ID_SEQ.nextval, 'Std factor set group')
		RETURNING factor_set_group_id INTO v_factor_set_group_id;

		CreateStdFactorSet('Unpublished1_DO_NOT_DELETE', 0);
		CreateStdFactorSet('Unpublished2_DO_NOT_DELETE', 0);

		v_custom_factor_set_id := factor_pkg.CreateCustomFactorSet('CustomFactorSet_DO_NOT_DELETE', 0);

		INSERT INTO csr.custom_factor (app_sid, custom_factor_id, custom_factor_set_id, factor_type_id, gas_type_id, std_measure_conversion_id, start_dtm, value)
		VALUES (v_app_sid, csr.custom_factor_id_seq.nextval, v_custom_factor_set_id, 3, 1, 17, TRUNC(SYSDATE, 'MON'), 0.2);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.std_factor_set_active (app_sid, std_factor_set_id)
		SELECT v_app_sid, std_factor_set_id
		  FROM csr.std_factor_set;
	EXCEPTION
	  WHEN DUP_VAL_ON_INDEX THEN
		NULL;
	END;
END;

PROCEDURE INTERNAL_SetupApprovalDboards
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_workflows_sid					security.security_pkg.T_SID_ID;
	v_wf_sid						security.security_pkg.T_SID_ID;
	v_xml							VARCHAR2(4000);
	v_global_approver_role_sid		security.security_pkg.T_SID_ID;
	v_data_providers_role_sid		security.security_pkg.T_SID_ID;
	v_dashboard_sid					security.security_pkg.T_SID_ID;
	v_group_data_contributors_sid	security.security_pkg.T_SID_ID;
	v_group_data_providers_sid		security.security_pkg.T_SID_ID;
	v_group_administrators_sid		security.security_pkg.T_SID_ID;
	v_group_registeredusers_sid		security.security_pkg.T_SID_ID;
	v_data_provider_role_sid		security.security_pkg.T_SID_ID;
	-- v_administrators_role_sid		security.security_pkg.T_SID_ID;

	FUNCTION TabExists(
		in_name							IN VARCHAR2
	)
	RETURN BOOLEAN
	AS
		v_tab_count					NUMBER;
	BEGIN
		SELECT COUNT(*)
		  INTO v_tab_count
		  FROM tab
		 WHERE name = in_name
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		RETURN v_tab_count > 0;
	END;
BEGIN
	v_act_id := security.security_pkg.getAct;
	v_app_sid := security.security_pkg.getApp;

	v_workflows_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Workflows');

	-- create the workflow
	SELECT NVL(MAX(flow_sid), 0) -- max prevents "no rows"
		INTO v_wf_sid
		FROM csr.flow
		WHERE app_sid = v_app_sid
		AND label = 'ApprovalDashboard';

	IF v_wf_sid = 0 THEN
		csr.flow_pkg.CreateFlow(
			in_label => 'ApprovalDashboard',
			in_parent_sid => v_workflows_sid,
			in_flow_alert_class => 'approvaldashboard',
			out_flow_sid => v_wf_sid);
	END IF;

	v_xml := '<flow label="ApprovalDashboard" default-state-id="$S1$">' ||
	             '<state id="$S1$" label="Data submission">' ||
	                 '<attributes x="600" y="1000" />' ||
	                 '<role sid="$A$" name="Global Approvers" is-editable="1">' ||
	                     '<capability cap-id="2003" description="Edit matrix notes" permission-set="2"/>' ||
	                     '<capability cap-id="2001" description="Refresh data" permission-set="2"/>' ||
	                     '<capability cap-id="2002" description="Run templated report" permission-set="0"/>' ||
	                 '</role>' ||
	                 '<role sid="$P$" name="Data Providers" is-editable="1">' ||
	                     '<capability cap-id="2003" description="Edit matrix notes" permission-set="2"/>' ||
	                     '<capability cap-id="2001" description="Refresh data" permission-set="2"/>' ||
	                     '<capability cap-id="2002" description="Run templated report" permission-set="0"/>' ||
	                 '</role>' ||
	                 '<transition id="$S1$" to-state-id="$S2$" verb="Data submit" lookup-key="" ask-for-comment="optional">' ||
	                     '<role sid="$A$" name="Global Approvers" />' ||
	                     '<role sid="$P$" name="Data Providers" />' ||
	                 '</transition>' ||
	             '</state>' ||
	             '<state id="$S2$" label="Verification">' ||
	                 '<attributes x="1000" y="1000" />' ||
	                 '<role sid="$A$" name="Global Approvers" is-editable="1">' ||
	                     '<capability cap-id="2003" description="Edit matrix notes" permission-set="2"/>' ||
	                     '<capability cap-id="2001" description="Refresh data" permission-set="2"/>' ||
	                     '<capability cap-id="2002" description="Run templated report" permission-set="0"/>' ||
	                 '</role>' ||
	                 '<role sid="$P$" name="Data Providers" is-editable="1">' ||
	                     '<capability cap-id="2003" description="Edit matrix notes" permission-set="2"/>' ||
	                     '<capability cap-id="2001" description="Refresh data" permission-set="2"/>' ||
	                     '<capability cap-id="2002" description="Run templated report" permission-set="0"/>' ||
	                 '</role>' ||
	                 '<transition id="$S2$" to-state-id="$S3$" verb="Submit" lookup-key="" ask-for-comment="optional">' ||
	                     '<role sid="$A$" name="Global Approvers" />' ||
	                     '<role sid="$P$" name="Data Providers" />' ||
	                 '</transition>' ||
	                 '<transition id="$S2$" to-state-id="$S1$" verb="Return" lookup-key="" ask-for-comment="optional">' ||
	                     '<role sid="$A$" name="Global Approvers" />' ||
	                     '<role sid="$P$" name="Data Providers" />' ||
	                 '</transition>' ||
	             '</state>' ||
	             '<state id="$S3$" label="Signed off" final="1">' ||
	                 '<attributes x="1400" y="1000" />' ||
	                 '<role sid="$A$" name="Global Approvers" is-editable="1">' ||
	                     '<capability cap-id="2003" description="Edit matrix notes" permission-set="2"/>' ||
	                     '<capability cap-id="2001" description="Refresh data" permission-set="2"/>' ||
	                     '<capability cap-id="2002" description="Run templated report" permission-set="0"/>' ||
	                 '</role>' ||
	                 '<role sid="$P$" name="Data Providers" is-editable="1">' ||
	                     '<capability cap-id="2003" description="Edit matrix notes" permission-set="2"/>' ||
	                     '<capability cap-id="2001" description="Refresh data" permission-set="2"/>' ||
	                     '<capability cap-id="2002" description="Run templated report" permission-set="0"/>' ||
	                 '</role>' ||
	                 '<transition id="$S3$" to-state-id="$S2$" verb="Return" lookup-key="" ask-for-comment="optional">' ||
	                     '<role sid="$A$" name="Global Approvers" />' ||
	                     '<role sid="$P$" name="Data Approvers" />' ||
	                 '</transition>' ||
	             '</state>' ||
	         '</flow>';

	-- SetRole creates the roles if they don't already exist
	csr.role_pkg.SetRole('Global Approvers', v_global_approver_role_sid);
	DBMS_OUTPUT.PUT_LINE('v_global_approver_role_sid = "' || v_global_approver_role_sid || '"');
	v_xml := REPLACE(v_xml, '$A$', v_global_approver_role_sid);
	csr.role_pkg.SetRole('Data Providers', v_data_providers_role_sid);
	-- if this comes back NULL, delete the Data Providers and Data Approvers GROUPS (they need to be roles)
	DBMS_OUTPUT.PUT_LINE('v_data_providers_role_sid = "' || v_data_providers_role_sid || '"');
	IF v_data_providers_role_sid IS NULL THEN
		DBMS_OUTPUT.PUT_LINE('it is null');

		DECLARE
			v_sid		security.security_pkg.T_SID_ID;
		BEGIN
			SELECT role_sid
			  INTO v_sid
			  FROM role
			 WHERE upper(name) = 'DATA PROVIDERS';

			 DBMS_OUTPUT.PUT_LINE('v_sid = ' || v_sid);
		END;

	END IF;
	v_xml := REPLACE(v_xml, '$P$', v_data_providers_role_sid);
	v_xml := REPLACE(v_xml, '$S1$', csr.flow_pkg.GetNextStateID);
	v_xml := REPLACE(v_xml, '$S2$', csr.flow_pkg.GetNextStateID);
	v_xml := REPLACE(v_xml, '$S3$', csr.flow_pkg.GetNextStateID);

	DBMS_OUTPUT.PUT_LINE('v_xml = ' || chr(13) || v_xml);

	csr.role_pkg.SetRole('Data provider', v_data_provider_role_sid); -- no 's'
	DBMS_OUTPUT.PUT_LINE('v_data_provider_role_sid = ' || v_data_provider_role_sid);
	-- csr.role_pkg.SetRole('Administrators', v_administrators_role_sid);

	BEGIN
		csr.flow_pkg.SetFlowFromXml(v_wf_sid, XMLTYPE(v_xml));
	EXCEPTION
		WHEN OTHERS THEN
			-- ignore: Cannot delete state id 1336 because 1 items are linked to it
			IF SQLERRM NOT LIKE 'ORA-20001: Cannot delete state id%' THEN
				RAISE;
			END IF;
	END;

	-- Create the dashboard
	DECLARE
		v_ind_sids				security.security_pkg.T_SID_IDS;
		v_region_sids			security.security_pkg.T_SID_IDS;
		v_single_zero			security.security_pkg.T_SID_IDS;
	BEGIN
		v_ind_sids(1) := gv_approval_dashboard_ind_sid;
		v_region_sids(1) := gv_approval_dashboard_reg_sid;
		v_single_zero(1) := 0;

		approval_dashboard_pkg.CreateDashboard(
			in_parent_sid => security.securableobject_pkg.getSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Dashboards'),
			in_label => 'UiTestApprovalDashboard-DoNotDelete',
			in_ind_sids => v_ind_sids,
			in_ind_pos => v_single_zero,
			in_ind_allow_est => v_single_zero,
			in_ind_is_hidden => v_single_zero,
			in_region_sids => v_region_sids,
			in_period_start => DATE '2017-01-01',
			in_period_end => DATE '2018-01-01',
			in_period_set_id => 1,
			in_period_interval_id => 1,
			in_workflow_sid => v_wf_sid,
			in_instance_schedule => XMLTYPE('<recurrences><monthly every-n="1"><day number="1"></day></monthly></recurrences>'),
			in_publish_doc_folder_sid => NULL,
			in_active_period_scenario_run => NULL,
			in_signed_off_scenario_run => NULL,
			in_source_scenario_run => NULL,
			out_dashboard_sid => v_dashboard_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT approval_dashboard_sid
			  INTO v_dashboard_sid
			  FROM approval_dashboard
			 WHERE label = 'UiTestApprovalDashboard-DoNotDelete'
			   AND app_sid = v_app_sid;
	END;

	v_group_data_contributors_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Data Contributors');
	v_group_data_providers_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Data Providers');
	v_group_administrators_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
	v_group_registeredusers_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');

	-- Create approval dashboard tab
	DECLARE
		v_tab_id					tab.tab_id%TYPE;
		v_approval_note_sid			security.security_pkg.T_SID_ID;
		v_approval_matrix_sid		security.security_pkg.T_SID_ID;
		v_tab_portlet_id			tab_portlet.tab_portlet_id%TYPE;
	BEGIN
		-- don't keep adding new ones
		IF NOT TabExists('TestApprovalDashboardTab-DoNotDelete') THEN
			-- the tab on the approval dashboard
			portlet_pkg.AddTabReturnTabId(
				in_app_sid => v_app_sid,
				in_tab_name => 'TestApprovalDashboardTab-DoNotDelete',
				in_is_shared => 1,
				in_is_hideable => 1,
				in_layout => 2,
				in_portal_group => 'ApprovalDashboard',
				out_tab_id => v_tab_id);

			-- add approval note
			SELECT cp.customer_portlet_sid
			  INTO v_approval_note_sid
			  FROM portlet p
			  JOIN customer_portlet cp ON p.portlet_id = cp.portlet_id
			 WHERE p.type = 'Credit360.Portlets.ApprovalNote'
			   AND cp.app_sid = v_app_sid;

			portlet_pkg.AddPortletToTab(
				in_tab_id => v_tab_id,
				in_customer_portlet_sid => v_approval_note_sid,
				in_initial_state => '{"portletHeight":200,"portletTitle":"Approval Note-DoNotDelete"}',
				out_tab_portlet_id => v_tab_portlet_id);

			-- add approval matrix
			SELECT cp.customer_portlet_sid
			  INTO v_approval_matrix_sid
			  FROM portlet p
			  JOIN customer_portlet cp ON p.portlet_id = cp.portlet_id
			 WHERE p.type = 'Credit360.Portlets.ApprovalMatrix'
			   AND cp.app_sid = v_app_sid;

			portlet_pkg.AddPortletToTab(
				in_tab_id => v_tab_id,
				in_customer_portlet_sid => v_approval_matrix_sid,
				in_initial_state => '{"portletHeight":200,"portletTitle":"Approval Matrix-DoNotDelete"}',
				out_tab_portlet_id => v_tab_portlet_id);

			-- add groups
			portlet_pkg.AddTabForGroup(
				in_group_sid => v_group_data_providers_sid,
				in_tab_id => v_tab_id);

			-- Register the tab with the approval dashboard
			approval_dashboard_pkg.AddTab(
				in_dashboard_sid => v_dashboard_sid,
				in_tab_id => v_tab_id);
		END IF;
	END;

	DECLARE
		v_superadmin_user_sid			security.security_pkg.T_SID_ID;
		v_gateway_tab_id				security.security_pkg.T_SID_ID;
		v_customer_portlet_sid			security.security_pkg.T_SID_ID;
		v_gateway_portlet_id			security.security_pkg.T_SID_ID;
	BEGIN
		IF NOT TabExists('TestHomePageTab_DoNotDelete') THEN
			v_superadmin_user_sid := INTERNAL_GetSuperAdminUserSid;

			-- make sure the test user has the right role on the approval dashboards region
			role_pkg.AddRoleMemberForRegion(
				in_role_sid => v_data_providers_role_sid,
				in_region_sid => gv_approval_dashboard_reg_sid,
				in_user_sid => v_superadmin_user_sid);

			role_pkg.AddRoleMemberForRegion(
				in_role_sid => v_data_provider_role_sid, -- no 's'
				in_region_sid => gv_approval_dashboard_reg_sid,
				in_user_sid => v_superadmin_user_sid);

			-- There's no such thing as an administrator role, just a group -- checking with Ashish
			-- role_pkg.AddRoleMemberForRegion(
			-- 	in_role_sid => v_administrators_role_sid,
			-- 	in_region_sid => gv_approval_dashboard_reg_sid,
			-- 	in_user_sid => v_superadmin_user_sid);

			-- create a standard shared portlet as a gateway to the new (separate) approvals dashboard
			portlet_pkg.AddTabReturnTabId(
				in_app_sid => v_app_sid,
				in_tab_name => 'TestHomePageTab_DoNotDelete',
				in_is_shared => 1,
				in_is_hideable => 0,
				in_layout => 2,
				in_portal_group => NULL,
				out_tab_id => v_gateway_tab_id);

			SELECT cp.customer_portlet_sid
			  INTO v_customer_portlet_sid
			  FROM portlet p
			  JOIN customer_portlet cp ON p.portlet_id = cp.portlet_id
			 WHERE p.type = 'Credit360.Portlets.MyApprovalDashboards'
			   AND cp.app_sid = v_app_sid;

			portlet_pkg.AddPortletToTab(
				in_tab_id => v_gateway_tab_id,
				in_customer_portlet_sid => v_customer_portlet_sid,
				in_initial_state => NULL,
				out_tab_portlet_id => v_gateway_portlet_id);

			-- allow all data contributors to see the new tab
			portlet_pkg.AddTabForGroup(
				in_group_sid => v_group_data_contributors_sid,
				in_tab_id => v_gateway_tab_id);
		END IF;
	END;

	-- set up Mindtree's "user 3"
	DECLARE
		v_uitest3_tab_id		security.security_pkg.T_SID_ID;
	BEGIN
		IF NOT TabExists('TestTab - DoNotDelete') THEN
			-- the tab on the approval dashboard, just for this user
			portlet_pkg.AddTabReturnTabId(
				in_app_sid => v_app_sid,
				in_tab_name => 'TestTab - DoNotDelete',
				in_is_shared => 0,
				in_is_hideable => 1,
				in_layout => 2,
				in_portal_group => 'ApprovalDashboard',
				out_tab_id => v_uitest3_tab_id);

			-- Register the tab with the approval dashboard
			approval_dashboard_pkg.AddTab(
				in_dashboard_sid => v_dashboard_sid,
				in_tab_id => v_uitest3_tab_id);

			-- forcibly assign the new tab to uitest3

			UPDATE tab_user
			   SET user_sid = gv_uitest_user3_sid
			 WHERE app_sid = v_app_sid
			   AND tab_id = v_uitest3_tab_id
			   AND user_sid = 3;

			-- make sure uitest3 is in the Data Providers group so they can see the new dashboard tab
			security.group_pkg.AddMember(v_act_id, gv_uitest_user3_sid, v_group_data_providers_sid);

			-- make sure uitest3 has the right role on the approval dashboards region
			role_pkg.AddRoleMemberForRegion(
				in_role_sid => v_data_providers_role_sid,
				in_region_sid => gv_approval_dashboard_reg_sid,
				in_user_sid => gv_uitest_user3_sid);
		END IF;
	END;

	COMMIT;
END;

PROCEDURE INTERNAL_SetupDelegPlanner
AS
	v_act_id							security.security_pkg.T_ACT_ID;
	v_app_sid							security.security_pkg.T_SID_ID;
	v_deleg_plan_sid					security.security_pkg.T_SID_ID;

	-- makes the template deleg, or gets the sid if it already exists
	FUNCTION MakeTemplateDeleg(
		in_name							IN	delegation.name%TYPE
	)
	RETURN security.security_pkg.T_SID_ID
	AS
		v_deleg_sid					security.security_pkg.T_SID_ID;
	BEGIN
		SELECT delegation_sid
		  INTO v_deleg_sid
		  FROM delegation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND name = in_name;

		RETURN v_deleg_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			delegation_pkg.CreateTopLevelDelegation(
				in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
				in_name => in_name,
				in_date_from => DATE '2016-01-01',
				in_date_to => DATE '2017-01-01',
				in_period_set_id => 1,
				in_period_interval_id => 1,
				in_allocate_users_to => 'region',
				in_app_sid => v_app_sid,
				in_note => NULL,
				in_group_by => 'region,indicator',
				-- definitely "recurrences" here not "recurrence" -- see comment below
				in_schedule_xml => '<recurrences><monthly every-n="1"><day number="1"></day></monthly></recurrences>',
				in_submission_offset => 0,
				in_reminder_offset => 5,
				in_note_mandatory => 0,
				in_flag_mandatory => 0,
				out_delegation_sid => v_deleg_sid);

			deleg_plan_pkg.SetAsTemplate(v_deleg_sid, 1);

			RETURN v_deleg_sid;
	END;
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	enable_pkg.EnableDelegPlan;

	BEGIN
		SELECT deleg_plan_sid
		  INTO v_deleg_plan_sid
		  FROM deleg_plan
		 WHERE app_sid = v_app_sid
		   AND name = 'UITestSuite-DoNotDelete_DelegationPlan';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- create the delegation plan
			v_deleg_plan_sid := deleg_plan_pkg.NewDelegPlan(
				in_name => 'UITestSuite-DoNotDelete_DelegationPlan',
				in_start_date => DATE '2016-01-01',
				in_end_date => DATE '2017-01-01',
				in_reminder_offset => 5,
				in_period_set_id => 1,
				in_period_interval_id => 1,
				-- not sure why this is "recurrence" here and "recurrences" elsewhere, but it breaks if we use recurrences here
				in_schedule_xml => '<recurrence><monthly every-n="1"><day number="1"></day></monthly></recurrence>',
				in_dynamic => 1);
	END;

	-- create delegation templates
	DECLARE
		v_template_1_sid				security.security_pkg.T_SID_ID;
		v_template_2_sid				security.security_pkg.T_SID_ID;
	BEGIN
		v_template_1_sid := MakeTemplateDeleg('UITestSuite-DoNotDelete_DelegationTemplate1');
		v_template_2_sid := MakeTemplateDeleg('UITestSuite-DoNotDelete_DelegationTemplate2');
	END;

	COMMIT;
END;

FUNCTION ImportSurvey(
	in_xml 							IN XMLTYPE,
	in_name							IN VARCHAR2,
	in_label						IN VARCHAR2
) RETURN security.security_pkg.T_SID_ID
AS
	v_xml							XMLTYPE := in_xml;
	v_survey_sid					security.security_pkg.T_SID_ID;
	v_publish_result				security.security_pkg.T_OUTPUT_CUR;
	v_wwwroot_sid					security.security_pkg.T_SID_ID;
	v_question_id					NUMBER(10);
BEGIN
	v_wwwroot_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot/surveys');
	BEGIN
		--TODO: make this re-runnable (just using quick_survey_pkg.OverwriteSurvey won't work because the versions will get in a mess. Will need
		--to delete the survey and corresponding audits/audit types, then start again)
		v_survey_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_wwwroot_sid, in_name);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	IF v_survey_sid IS NOT NULL THEN
		-- Delete and recreate
		UPDATE internal_audit_type
		   SET default_survey_sid = DECODE(default_survey_sid, v_survey_sid, NULL, default_survey_sid),
			   summary_survey_sid = DECODE(summary_survey_sid, v_survey_sid, NULL, summary_survey_sid)
		 WHERE summary_survey_sid = v_survey_sid OR default_survey_sid = v_survey_sid;
		
		UPDATE internal_audit
		   SET summary_response_id = NULL
		 WHERE summary_response_id IN (
			SELECT survey_response_id
			  FROM quick_survey_response
			 WHERE survey_sid = v_survey_sid
		);
		
		UPDATE internal_audit
		   SET survey_response_id = NULL, survey_sid = NULL
		 WHERE survey_response_id IN (
			SELECT survey_response_id
			  FROM quick_survey_response
			 WHERE survey_sid = v_survey_sid
		);
		
		UPDATE internal_audit_survey
		   SET survey_response_id = NULL, survey_sid = NULL
		 WHERE survey_response_id IN (
			SELECT survey_response_id
			  FROM quick_survey_response
			 WHERE survey_sid = v_survey_sid
		);

		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, v_survey_sid);
		v_survey_sid := NULL;
	END IF;

	FOR r IN (
		SELECT *
		  FROM XMLTABLE('/questions//question' PASSING v_xml
			COLUMNS
			   id NUMBER(10) PATH '@id')
	)
	LOOP
		v_question_id := csr.question_id_seq.NEXTVAL;
		SELECT UPDATEXML(v_xml, '//question[@id="'||r.id||'"]/@id', v_question_id) INTO v_xml FROM dual;
		SELECT UPDATEXML(v_xml, '//actionImport/expression/showQ[@questionId="'||r.id||'"]/@questionId', v_question_id) INTO v_xml FROM dual;
	END LOOP;

	FOR r IN (
		SELECT *
		  FROM XMLTABLE('/questions//pageBreak' PASSING v_xml
			COLUMNS
			   id NUMBER(10) PATH '@id')
	)
	LOOP
		v_question_id := csr.question_id_seq.NEXTVAL;
		SELECT UPDATEXML(v_xml, '//pageBreak[@id="'||r.id||'"]/@id', v_question_id) INTO v_xml FROM dual;
	END LOOP;

	FOR r IN (
		SELECT *
		  FROM XMLTABLE('//checkbox' PASSING v_xml
			COLUMNS
			   id NUMBER(10) PATH '@id')
	)
	LOOP
		v_question_id := csr.question_id_seq.NEXTVAL;
		SELECT UPDATEXML(v_xml, '//checkbox[@id="'||r.id||'"]/@id', v_question_id) INTO v_xml FROM dual;
	END LOOP;

	FOR r IN (
		SELECT *
		  FROM XMLTABLE('//section|//question|//pageBreak|//question[@type="checkboxgroup"]/checkbox|//question[@type="matrix"]/radioRow' PASSING v_xml
			COLUMNS
			   id NUMBER(10) PATH '@id',
			   question_type VARCHAR2(255) PATH '@type',
			   description VARCHAR2(4000) PATH 'description',
			   mandatory NUMBER(10) PATH '@mandatory',
			   weight NUMBER(10) PATH '@weight',
			   dont_normalise_score NUMBER(10) PATH '@dontNormaliseScore',
			   lookup_key VARCHAR2(255) PATH '@lookupKey',
			   node_name VARCHAR2(255) PATH 'name()')
	)
	LOOP
		csr.quick_survey_pkg.AddTempQuestion(
			in_question_id => r.id,
			in_question_version => 0,
			in_parent_id => NULL,
			in_parent_version => 0,
			in_label => r.description,
			in_question_type => CASE WHEN r.node_name = 'question' THEN r.question_type ELSE LOWER(r.node_name) END,
			in_score => NULL,
			in_max_score => NULL,
			in_upload_score => NULL,
			in_lookup_key => r.lookup_key,
			in_invert_score => 0,
			in_custom_question_type_id => NULL,
			in_weight => r.weight,
			in_dont_normalise_score => CASE WHEN r.dont_normalise_score IS NULL THEN 0 ELSE r.dont_normalise_score END,
			in_has_score_expression => 0,
			in_has_max_score_expr => 0,
			in_remember_answer => 0,
			in_count_question => 0,
			in_action => NULL, -- ... will be needed when syncing with a later trunk
			in_question_xml => to_clob('<' || r.node_name || ' id="' || r.id || '"><description>' || r.description || '</description></' || r.node_name || '>')
		);
	END LOOP;

	--TODO: support matrix rows
	FOR r IN (
		SELECT *
		  FROM XMLTABLE('
			for $question in //question[option]
			for $questionOption in $question/option
			  return <row>
			  {
				$question
				,$questionOption
			  }
			  </row>' PASSING v_xml
			COLUMNS
				question_id  NUMBER(10) PATH 'question/@id',
			   question_option_id NUMBER(10) PATH 'option/@id',
			   action VARCHAR2(255) PATH 'option/@action',
			   lookup_key VARCHAR2(255) PATH 'option/@lookupKey',
			   default_value NUMBER(10) PATH 'option/@defaultValue',
			   label VARCHAR2(4000) PATH 'option/text()',
			   score NUMBER(10) PATH 'option/@score',
			   override_id NUMBER(10) PATH 'option/scoreOverride/@columnId',
			   score_override NUMBER(10) PATH 'option/scoreOverride/@score',
			   hidden NUMBER(10) PATH 'option/scoreOverride/@hidden',
			   color VARCHAR2(4000) PATH 'option/@color',
			   nc_popup VARCHAR2(255) PATH 'option/@ncPopup',
			   nc_id NUMBER(10) PATH 'option/@ncId',
			   nc_type_id NUMBER(10) PATH 'option/@ncTypeId',
			   nc_label VARCHAR2(4000) PATH 'option/@ncLabel',
			   nc_detail VARCHAR2(4000) PATH 'option/@ncDetail',
			   nc_root_cause VARCHAR2(4000) PATH 'option/@ncRootCause',
			   nc_suggested_action VARCHAR2(4000) PATH 'option/@ncSuggestedAction',
			   node_name VARCHAR2(255) PATH 'option/name()')
	)
	LOOP
		csr.quick_survey_pkg.AddTempQuestionOption(
			in_question_id				=> r.question_id,
			in_question_version			=> 0,
			in_question_option_id		=> r.question_option_id,
			in_label					=> r.label,
			in_score					=> r.score,
			in_has_override				=> CASE WHEN r.override_id IS NULL THEN 0 ELSE 1 END,
			in_score_override			=> r.score_override,
			in_hidden					=> r.hidden,
			in_color					=> r.color,
			in_lookup_key				=> r.lookup_key,
			in_option_action			=> r.action,
			in_non_compliance_popup		=> CASE WHEN UPPER(r.nc_popup) = 'TRUE' THEN 1 ELSE 0 END,
			in_non_comp_default_id		=> r.nc_id,
			in_non_compliance_type_id	=> r.nc_type_id,
			in_non_compliance_label		=> r.nc_label,
			in_non_compliance_detail	=> r.nc_detail,
			in_non_comp_root_cause		=> r.nc_root_cause,
			in_non_comp_suggested_action => r.nc_suggested_action,
			in_question_option_xml 		=> to_clob('<' || r.node_name || ' id="' || r.question_option_id || '">' || r.label || '</' || r.node_name || '>')
		);
	END LOOP;

	--TODO: support tags

	csr.quick_survey_pkg.ImportSurvey(
		in_xml						=> v_xml.getclobval(),
		in_name						=> in_name,
		in_label					=> in_label,
		in_audience					=> 'audit',
		in_parent_sid				=> v_wwwroot_sid,
		out_survey_sid				=> v_survey_sid
	);

	DELETE FROM csr.tempor_question;
	DELETE FROM csr.temp_question_option;

	csr.quick_survey_pkg.PublishSurvey(
		in_survey_sid				=> v_survey_sid,
		in_update_responses_from	=> NULL,
		out_publish_result			=> v_publish_result
	);

	RETURN v_survey_sid;
END;

PROCEDURE INTERNAL_SetupAuditType (
	in_audit_type_id		IN	csr.internal_audit_type.internal_audit_type_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO csr.internal_audit_type_carry_fwd (app_sid, from_internal_audit_type_id, to_internal_audit_type_id)
		VALUES (security.security_pkg.getApp, in_audit_type_id, in_audit_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	DBMS_OUTPUT.PUT_LINE('Configure plug-ins for the audit type');
	DECLARE
		v_out_cur							SYS_REFCURSOR;
		v_plugin_id							csr.plugin.plugin_id%TYPE;
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 14
		   AND description = 'Full audit details header';

		csr.audit_pkg.SetAuditHeader(
			in_internal_audit_type_id => in_audit_type_id,
			in_plugin_id => v_plugin_id,
			in_pos => 0,
			out_cur => v_out_cur
		);

		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 13
		   AND description = 'Executive Summary';

		csr.audit_pkg.SetAuditTab(
			in_internal_audit_type_id => in_audit_type_id,
			in_plugin_id => v_plugin_id,
			in_pos => 0,
			in_tab_label => 'Executive summary',
			out_cur => v_out_cur
		);

		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 13
		   AND description = 'Findings';

		csr.audit_pkg.SetAuditTab(
			in_internal_audit_type_id => in_audit_type_id,
			in_plugin_id => v_plugin_id,
			in_pos => 1,
			in_tab_label => 'Findings',
			out_cur => v_out_cur
		);

		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 13
		   AND description = 'Documents';

		csr.audit_pkg.SetAuditTab(
			in_internal_audit_type_id => in_audit_type_id,
			in_plugin_id => v_plugin_id,
			in_pos => 2,
			in_tab_label => 'Documents',
			out_cur => v_out_cur
		);

		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 13
		   AND description = 'Audit Log';

		csr.audit_pkg.SetAuditTab(
			in_internal_audit_type_id => in_audit_type_id,
			in_plugin_id => v_plugin_id,
			in_pos => 6,
			in_tab_label => 'Audit Log',
			out_cur => v_out_cur
		);
	END;
END;

PROCEDURE INTERNAL_SetupAudits(
	in_is_multiple_survey_audits	IN	NUMBER
)
AS
	v_sid								security.security_pkg.T_SID_ID;
	v_act_id							security.security_pkg.T_ACT_ID;
	v_app_sid							security.security_pkg.T_SID_ID;
	v_audit_type_id						csr.internal_audit_type.internal_audit_type_id%TYPE;
	v_region_root_sid					security.security_pkg.T_SID_ID;
	v_audit_region_sid					security.security_pkg.T_SID_ID;

	PROCEDURE SetupStandardAudits
	AS
		v_carryForwardXml					XMLTYPE := XMLTYPE('
<questions sid="1039920">
  <pageBreak isTop="1" id="96219" />
  <question id="96218" type="note" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1" lookupKey="V1TXT">
    <description>Version 1</description>
    <tags matchEveryCategory="false" />
    <helpText />
    <helpTextLong />
    <helpTextLongLink />
    <infoPopup />
  </question>
  <question id="96219" type="note" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1" lookupKey="V1TXT2">
    <description>V1 - question to delete</description>
    <tags matchEveryCategory="false" />
    <helpText />
    <helpTextLong />
    <helpTextLongLink />
    <infoPopup />
  </question>
  <objectImport /></questions>
');
		v_expressionsXml					XMLTYPE := XMLTYPE('<questions sid="1031699">
		<pageBreak id="77221" isTop="1" rememberAnswer="0">
		<description>Questions hidden by radio buttons</description>
		<tags matchEveryCategory="false" />
		</pageBreak>
		<question type="richtext" id="77222" displayOn="" treatAsHelpTextIfPrintable="false">
		<question type="radio" id="77223" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC1RB1">
		  <description>ETC1 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78781" lookupKey="OPT1">ETC1 RB1 OPT1</option>
		  <option action="none" id="78782" lookupKey="OPT2">ETC1 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="note" id="77224" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		  <description>ETC1 TXT1</description>
		  <tags matchEveryCategory="false" />
		  <helpText>
		Visible if ETC1 RB1 OPT1 is selected, hidden otherwise
		</helpText>
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;Test case 1'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Text box is displayed only when the first option of a radio button list is selected'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		</question>
		<question type="richtext" id="77225" displayOn="" treatAsHelpTextIfPrintable="false">
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Test case 2'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Radio button question has first option selected by default. First text box displays only if the the first option is selected. Second text box displays only if the second option is selected.'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		<question type="radio" id="77226" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC2RB1">
		  <description>ETC2 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78783" lookupKey="OPT1" defaultValue="1">ETC2 RB1 OPT1</option>
		  <option action="none" id="78784" lookupKey="OPT2">ETC2 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="note" id="77227" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		  <description>ETC2 TXT1</description>
		  <tags matchEveryCategory="false" />
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="note" id="77228" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		  <description>ETC2 TXT2</description>
		  <tags matchEveryCategory="false" />
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		</question>
		<question type="richtext" id="77229" displayOn="" treatAsHelpTextIfPrintable="false">
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;Test case 3'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Two radio button question with a separate expression on each. Textbox should show if either of the first options is selected.'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		<question type="radio" id="77230" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC3RB1">
		  <description>ETC3 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78785" lookupKey="ETC3RB1OPT1">ETC3 RB1 OPT1</option>
		  <option action="none" id="78786" lookupKey="ETC3RB1OPT2">ETC3 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="radio" id="77231" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC3RB2">
		  <description>ETC3 RB2</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78787" lookupKey="ETC3RB2OPT1">ETC3 RB2 OPT1</option>
		  <option action="none" id="78788" lookupKey="ETC3RB2OPT2">ETC3 RB2 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="note" id="77232" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		  <description>ETC3 TXT1</description>
		  <tags matchEveryCategory="false" />
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		</question>
		<question type="richtext" id="77233" displayOn="" treatAsHelpTextIfPrintable="false">
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;Test case 4'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Two radio buttons questions, one of which is the parent of the text box with an action on the first option to ''show subsection''. The other has a condition to show the text box only if the first option is selected. The text box should only show if both the condition and action are met.'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		<question type="radio" id="77234" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC4RB1">
		  <description>ETC4 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78789" lookupKey="OPT1">ETC4 RB1 OPT1</option>
		  <option action="none" id="78790" lookupKey="OPT2">ETC4 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="radio" id="77235" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0">
		  <description>ETC4 RB2</description>
		  <tags matchEveryCategory="false" />
		  <option action="showsubsection" id="78791">ETC4 RB2 OPT1</option>
		  <option action="none" id="78792">ETC4 RB2 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		  <question type="note" id="77236" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
			<description>ETC4 TXT1</description>
			<tags matchEveryCategory="false" />
			<helpText />
			<helpTextLong />
			<helpTextLongLink />
			<infoPopup />
		  </question>
		</question>
		</question>
		<question type="richtext" id="77237" displayOn="" treatAsHelpTextIfPrintable="false">
		<question type="radio" id="77238" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC5RB1">
		  <description>ETC5 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78793" lookupKey="OPT1" defaultValue="1">ETC5 RB1 OPT1</option>
		  <option action="none" id="78794" lookupKey="OPT2">ETC5 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="radio" id="77239" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0">
		  <question type="note" id="77240" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
			<description>ETC5 TXT1</description>
			<tags matchEveryCategory="false" />
			<helpText />
			<helpTextLong />
			<helpTextLongLink />
			<infoPopup />
		  </question>
		  <description>ETC5 RB2</description>
		  <tags matchEveryCategory="false" />
		  <option action="showsubsection" id="78795">ETC5 RB2 OPT1</option>
		  <option action="none" id="78796">ETC5 RB2 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;Test case 5'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;As test case 4, but the condition is met by default'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		</question>
		<question type="richtext" id="77241" displayOn="" treatAsHelpTextIfPrintable="false">
		<question type="radio" id="77242" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC6RB1">
		  <description>ETC6 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78797" lookupKey="OPT1">ETC6 RB1 OPT1</option>
		  <option action="none" id="78798" lookupKey="OPT2">ETC6 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<question type="radio" id="77243" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0">
		  <question type="note" id="77244" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
			<description>ETC6 TXT1</description>
			<tags matchEveryCategory="false" />
			<helpText />
			<helpTextLong />
			<helpTextLongLink />
			<infoPopup />
		  </question>
		  <description>ETC6 RB2</description>
		  <tags matchEveryCategory="false" />
		  <option action="showsubsection" id="78799" defaultValue="1">ETC6 RB2 OPT1</option>
		  <option action="none" id="78800">ETC6 RB2 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;Test case 6'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;As test case 4, but the action is met by default'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		</question>
		<question type="richtext" id="77245" displayOn="" treatAsHelpTextIfPrintable="false">
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;Test case 7'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Radio button controls visibility of a question on the next page'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		<question type="radio" id="77246" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC7RB1">
		  <description>ETC7 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78801" lookupKey="OPT1">ETC7 RB1 OPT1</option>
		  <option action="none" id="78802" lookupKey="OPT2">ETC7 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		</question>
		<question type="richtext" id="77247" displayOn="" treatAsHelpTextIfPrintable="false">
		<description />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		<text>'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;b'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;Test case 8'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/b'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		'||CHR(38)||'lt;p'||CHR(38)||'gt;'||CHR(38)||'lt;font face="arial" size="4"'||CHR(38)||'gt;As test case 7 but with option 2 controlling the visibility of a second question and the default answer set as option 1.'||CHR(38)||'lt;/font'||CHR(38)||'gt;'||CHR(38)||'lt;/p'||CHR(38)||'gt;
		</text>
		<question type="radio" id="77248" displayAs="radio" mandatory="0" rememberAnswer="0" countQuestion="0" allowFileUploads="0" showCommentsBox="0" scoreExpression="" maxScoreExpression="" weight="1" showScore="0" lookupKey="ETC8RB1">
		  <description>ETC8 RB1</description>
		  <tags matchEveryCategory="false" />
		  <option action="none" id="78803" lookupKey="OPT1" defaultValue="1">ETC8 RB1 OPT1</option>
		  <option action="none" id="78804" lookupKey="OPT2">ETC8 RB1 OPT2</option>
		  <helpText />
		  <helpTextLong />
		  <helpTextLongLink />
		  <infoPopup />
		</question>
		</question>
		<pageBreak id="77249" rememberAnswer="0">
		<description>Questions hidden by radio buttons 2</description>
		<tags matchEveryCategory="false" />
		</pageBreak>
		<question type="note" id="77250" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		<description>ETC7 TXT1</description>
		<tags matchEveryCategory="false" />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		</question>
		<question type="note" id="77251" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		<description>ETC8 TXT1</description>
		<tags matchEveryCategory="false" />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		</question>
		<question type="note" id="77252" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1">
		<description>ETC8 TXT2</description>
		<tags matchEveryCategory="false" />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
		</question>
		<actionImport><expression expr="VALUE(''ETC2RB1'')==''OPT1''"><showQ questionId="77227" /></expression><expression expr="VALUE(''ETC2RB1'')==''OPT2''"><showQ questionId="77228" /></expression><expression expr="VALUE(''ETC4RB1'')==''OPT1''"><showQ questionId="77236" /></expression><expression expr="VALUE(''ETC1RB1'')==''OPT1''"><showQ questionId="77224" /></expression><expression expr="VALUE(''ETC5RB1'')==''OPT1''"><showQ questionId="77240" /></expression><expression expr="VALUE(''ETC6RB1'')==''OPT1''"><showQ questionId="77244" /></expression><expression expr="VALUE(''ETC3RB2'')==''ETC3RB2OPT1''"><showQ questionId="77232" /></expression><expression expr="VALUE(''ETC3RB1'')==''ETC3RB1OPT1''"><showQ questionId="77232" /></expression><expression expr="VALUE(''ETC7RB1'')==''OPT1''"><showQ questionId="77250" /></expression><expression expr="VALUE(''ETC8RB1'')==''OPT1''"><showQ questionId="77251" /></expression><expression expr="VALUE(''ETC8RB1'')==''OPT2''"><showQ questionId="77252" /></expression></actionImport><objectImport /></questions>');
		v_auditSurveyXml					XMLTYPE := XMLTYPE('<questions>
		  <section id="22345" textCssClassName="surveyTextH1" weight="1">
			<description>Audit Survey</description>
			<question id="123456" type="note" mandatory="0" weight="1" singleLine="0" defaultValue="" allowFileUploads="0">
			  <description>Text question</description>
			  <helpText></helpText>
			  <infoPopup></infoPopup>
			</question>
			<question id="123457" type="radio" displayAs="radio" mandatory="0" weight="1" allowFileUploads="0" showCommentsBox="0">
			  <description>Radio question</description>
			  <option id="123458" score="0" lookupKey="S0" defaultValue="1">Sample option 1</option>
			  <option id="123459" score="1" lookupKey="S1" defaultValue="0">Sample option 2</option>
			  <option id="123460" action="other" score="2" lookupKey="S2" defaultValue="0">Sample option 3</option>
			  <helpText></helpText>
			  <infoPopup></infoPopup>
			</question>
		  </section>
		<actionImport /></questions>');

		v_survey_sid						security.security_pkg.T_SID_ID;

		FUNCTION CreateStandardAuditType (
			in_label						VARCHAR2,
			in_survey_sid					security.security_pkg.T_SID_ID
		) RETURN NUMBER
		AS
			v_act_id						security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
			v_app_sid						security.security_pkg.T_SID_ID := security.security_pkg.GetApp;
			v_audit_type_id					csr.internal_audit_type.internal_audit_type_id%TYPE;
		BEGIN
			BEGIN
				SELECT internal_audit_type_id
				  INTO v_audit_type_id
				  FROM csr.internal_audit_type
				 WHERE app_sid = v_app_sid
				   AND label = in_label;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
			
			IF v_audit_type_id IS NOT NULL THEN
				-- Delete and recreate
				FOR r IN (
					SELECT internal_audit_sid
					  FROM csr.internal_audit
					 WHERE internal_audit_type_id = v_audit_type_id
				)
				LOOP
					security.securableobject_pkg.DeleteSO(v_act_id, r.internal_audit_sid);
				END LOOP;
				csr.audit_pkg.DeleteInternalAuditType(v_audit_type_id);
			END IF;
			
			INSERT INTO csr.internal_audit_type (internal_audit_type_id, label, default_survey_sid, internal_audit_type_source_id)
			VALUES (csr.internal_audit_type_id_seq.NEXTVAL, in_label, in_survey_sid, 1)
			RETURNING internal_audit_type_id INTO v_audit_type_id;

			INTERNAL_SetupAuditType(v_audit_type_id);

			RETURN v_audit_type_id;
		END;
	BEGIN
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;

		SELECT region_root_sid
		  INTO v_region_root_sid
		  FROM csr.customer
		 WHERE app_sid = v_app_sid;

		--csr.enable_pkg.EnableAudit;
		--csr.enable_pkg.EnableAuditFiltering;

		 -- Rename menu item from "Audits" to "Internal audit"
		BEGIN
			v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/ia');
			security.menu_pkg.SetMenu(v_act_id, v_sid, 'Internal audit', '/csr/site/audit/auditlist.acds', 8, NULL);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'It seems the audit module has not been enabled for this site. Run utils\enableAudit');
		END;

		DBMS_OUTPUT.PUT_LINE('Create an audit type');
		v_survey_sid := ImportSurvey(v_auditSurveyXml, 'UITestSuite-Test-Survey-DO-NOT-DELETE', 'UITestSuite Test Survey - DO NOT DELETE');
		v_audit_type_id := CreateStandardAuditType('UITest Audit Type - DO NOT DELETE', v_survey_sid);

		v_audit_region_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_region_root_sid, 'Main/UITestSuit_ELETE');

		DBMS_OUTPUT.PUT_LINE('Create an audit for creating Non-Compliances etc against');
		
		csr.audit_pkg.Save(
			in_sid_id				=> NULL,
			in_audit_ref			=> NULL,
			in_survey_sid			=> NULL,
			in_region_sid			=> v_audit_region_sid,
			in_label				=> 'UITestSuite Audit - DO NOT DELETE',
			in_audit_dtm			=> DATE '2013-03-20',
			in_auditor_user_sid		=> security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/admin'),
			in_notes				=> 'UITestSuite Audit Notes',
			in_internal_audit_type	=> v_audit_type_id,
			in_auditor_name			=> 'UITestSuite Auditor',
			in_auditor_org			=> 'UITestSuite Audit Organisation',
			in_response_to_audit	=> NULL,
			in_created_by_sid		=> NULL,
			in_auditee_user_sid		=> NULL,
			out_sid_id				=> v_sid
		);

		DBMS_OUTPUT.PUT_LINE('Create a UITestSuite non-compliance against the Audit.');
		DECLARE
			v_dummy_cur		security.security_pkg.T_OUTPUT_CUR;
			v_dummy_sids  security.security_pkg.T_SID_IDS;
			v_dummy_keys  csr.audit_pkg.T_CACHE_KEYS;
			v_count			NUMBER;
		BEGIN
			SELECT COUNT(*)
			  INTO v_count
			  FROM csr.non_compliance
			 WHERE label = 'UITestSuite Non-Compliance - DO NOT DELETE';

			IF v_count = 0 THEN
				csr.audit_pkg.SaveNonCompliance(
					in_non_compliance_id		=>	NULL,
					in_internal_audit_sid		=>	v_sid,
					in_from_non_comp_default_id =>	NULL,
					in_label					=>	'UITestSuite Non-Compliance - DO NOT DELETE',
					in_detail					=>	'UITestSuite non-compliance detail.',
					in_non_compliance_type_id	=>	NULL,
					in_is_closed				=>	NULL,
					in_current_file_uploads		=>	v_dummy_sids,
					in_new_file_uploads			=>	v_dummy_keys,
					in_tag_ids					=>	v_dummy_sids,
					in_question_id				=>	NULL,
					in_question_option_id		=>	NULL,
					out_nc_cur					=>	v_dummy_cur,
					out_nc_upload_cur			=>	v_dummy_cur,
					out_nc_tag_cur				=>	v_dummy_cur
				);

				-- Get the ID of the non-compliance we just created.
				SELECT non_compliance_id
				  INTO v_sid
				  FROM csr.non_compliance
				 WHERE label = 'UITestSuite Non-Compliance - DO NOT DELETE';

				-- Create a UITestSuite non-compliance issue against the Audit.
				csr.audit_pkg.AddNonComplianceIssue(
					in_non_compliance_id	=> v_sid,
					in_label				=> 'UITestSuite Non Comp - DO NOT DELETE',
					in_description			=> 'UITestSuite Non-compliance.',
					out_issue_id			=> v_sid
				);
			END IF;
		END;

		v_survey_sid := ImportSurvey(v_carryForwardXml, 'carryForward', 'Carry Forward - DO NOT DELETE');
		v_audit_type_id := CreateStandardAuditType('UITest Carry Forward Audit Type - DO NOT DELETE', v_survey_sid);

		DECLARE
			v_is_new_response NUMBER(10);
			v_response_id NUMBER(10);
			v_response_guid VARCHAR2(255);
			v_question_id NUMBER(10);
			v_submission_id NUMBER(10);
		BEGIN
			csr.audit_pkg.Save(
				in_sid_id				=> NULL,
				in_audit_ref			=> NULL,
				in_survey_sid			=> v_survey_sid,
				in_region_sid			=> v_audit_region_sid,
				in_label				=> 'UITestSuite Carry Forward Original - DO NOT DELETE',
				in_audit_dtm			=> DATE '2013-03-20',
				in_auditor_user_sid		=> security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/admin'),
				in_notes				=> 'UITestSuite Audit Notes',
				in_internal_audit_type	=> v_audit_type_id,
				in_auditor_name			=> 'UITestSuite Auditor',
				in_auditor_org			=> 'UITestSuite Audit Organisation',
				in_response_to_audit	=> NULL,
				in_created_by_sid		=> NULL,
				in_auditee_user_sid		=> NULL,
				out_sid_id				=> v_sid
			);

			csr.audit_pkg.GetOrCreateSurveyResponse(
				in_internal_audit_sid => v_sid,
				in_ia_type_survey_id => csr.audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID,
				out_is_new_response => v_is_new_response,
				out_survey_sid => v_survey_sid,
				out_response_id => v_response_id
			);

			SELECT question_id
			  INTO v_question_id
			  FROM csr.quick_survey_question
			 WHERE survey_sid = v_survey_sid
			   AND survey_version = 0
			   AND lookup_key = 'V1TXT';

			v_response_guid := csr.quick_survey_pkg.GetGUIDFromResponseId(v_response_id);

			csr.quick_survey_pkg.SetAnswerForResponseGuid(
				in_question_id => v_question_id,
				in_guid => v_response_guid,
				in_answer => 'test'
			);

			csr.quick_survey_pkg.Submit(
				in_response_id => v_response_id,
				out_submission_id => v_submission_id
			);
		END;

		v_survey_sid := ImportSurvey(v_expressionsXml, 'expressions', 'Expressions Test - DO NOT DELETE');
		v_audit_type_id := CreateStandardAuditType('UITest Expressions Audit Type - DO NOT DELETE', v_survey_sid);
	END;

	PROCEDURE SetupMultipleSurveyAudits
	AS
		v_primary_survey_sid				security.security_pkg.T_SID_ID;
		v_secondary_survey_sid				security.security_pkg.T_SID_ID;
		v_secondary_survey_type				NUMBER(10);

		v_primaryXml						XMLTYPE := XMLTYPE('
<questions sid="1039920">
  <pageBreak isTop="1" id="96219" />
  <question id="96218" type="note" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1" lookupKey="V1TXT">
    <description>Version 1</description>
    <tags matchEveryCategory="false" />
    <helpText />
    <helpTextLong />
    <helpTextLongLink />
    <infoPopup />
  </question>
  <objectImport /></questions>
');
		v_secondaryXml						XMLTYPE := XMLTYPE('
	<questions>
	  <pageBreak isTop="1" id="16219" />
	  <question id="16218" type="note" mandatory="0" rememberAnswer="0" countQuestion="0" singleLine="0" defaultValue="" allowFileUploads="0" scoreExpression="" maxScoreExpression="" weight="1" lookupKey="V1TXT">
		<description>Version 1</description>
		<tags matchEveryCategory="false" />
		<helpText />
		<helpTextLong />
		<helpTextLongLink />
		<infoPopup />
	  </question>
	  <objectImport /></questions>
	');

		FUNCTION CreateMultipleSurveyAuditType (
			in_label						VARCHAR2,
			in_primary_survey_sid			security.security_pkg.T_SID_ID,
			in_secondary_survey_sid			security.security_pkg.T_SID_ID
		) RETURN NUMBER
		AS
			v_act_id						security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
			v_app_sid						security.security_pkg.T_SID_ID := security.security_pkg.GetApp;
			v_audit_type_id					csr.internal_audit_type.internal_audit_type_id%TYPE;
			v_secondary_survey_group		csr.ia_type_survey_group.ia_type_survey_group_id%TYPE;
			v_ia_type_survey_id				csr.internal_audit_type_survey.internal_audit_type_survey_id%TYPE;
		BEGIN
			BEGIN
				SELECT internal_audit_type_id
				  INTO v_audit_type_id
				  FROM csr.internal_audit_type
				 WHERE app_sid = v_app_sid
				   AND label = in_label;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
			
			IF v_audit_type_id IS NOT NULL THEN
				-- Delete and recreate
				FOR r IN (
					SELECT internal_audit_sid
					  FROM csr.internal_audit
					 WHERE internal_audit_type_id = v_audit_type_id
				)
				LOOP
					csr.audit_pkg.DeleteObject(v_act_id, r.internal_audit_sid);
				END LOOP;
				csr.audit_pkg.DeleteInternalAuditType(v_audit_type_id);
			END IF;
			
			INSERT INTO csr.internal_audit_type (internal_audit_type_id, label, show_primary_survey_in_header)
			VALUES (csr.internal_audit_type_id_seq.NEXTVAL, in_label, 1)
			RETURNING internal_audit_type_id INTO v_audit_type_id;

			IF in_primary_survey_sid IS NOT NULL THEN
				csr.audit_pkg.SetAuditTypeSurvey(
					in_internal_audit_type_id => v_audit_type_id,
					in_ia_type_survey_id => csr.audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID,
					in_active => 1,
					in_label => 'Primary',
					in_ia_type_survey_group_id => NULL,
					in_default_survey_sid => in_primary_survey_sid,
					in_mandatory => 0,
					in_survey_fixed => 0,
					in_survey_group_key => 'PRIMARY',
					out_ia_type_survey_id => v_ia_type_survey_id
				);
			END IF;

			IF in_secondary_survey_sid IS NOT NULL THEN
				csr.audit_pkg.SetAuditTypeSurveyGroup(
					in_ia_type_survey_group_id => NULL,
					in_label => 'Secondary',
					in_lookup_key => NULL,
					out_ia_type_survey_group_id => v_secondary_survey_group
				);

				csr.audit_pkg.SetAuditTypeSurvey(
					in_internal_audit_type_id => v_audit_type_id,
					in_ia_type_survey_id => NULL,
					in_active => 1,
					in_label => 'Secondary',
					in_ia_type_survey_group_id => v_secondary_survey_group,
					in_default_survey_sid => in_secondary_survey_sid,
					in_mandatory => 0,
					in_survey_fixed => 0,
					in_survey_group_key => 'SECONDARY',
					out_ia_type_survey_id => v_ia_type_survey_id
				);
			END IF;

			INTERNAL_SetupAuditType(v_audit_type_id);

			RETURN v_audit_type_id;

		END;

		PROCEDURE SubmitAuditSurveyResponse(
			in_internal_audit_sid		security.security_pkg.T_SID_ID,
			in_ia_survey_type_id		NUMBER
		)
		AS
			v_survey_sid security.security_pkg.T_SID_ID;
			v_is_new_response NUMBER(10);
			v_response_id NUMBER(10);
			v_response_guid VARCHAR2(255);
			v_question_id NUMBER(10);
			v_submission_id NUMBER(10);
		BEGIN
			csr.audit_pkg.GetOrCreateSurveyResponse(
				in_internal_audit_sid => in_internal_audit_sid,
				in_ia_type_survey_id => in_ia_survey_type_id,
				out_is_new_response => v_is_new_response,
				out_survey_sid => v_survey_sid,
				out_response_id => v_response_id
			);

			SELECT question_id
			  INTO v_question_id
			  FROM csr.quick_survey_question
			 WHERE survey_sid = v_survey_sid
			   AND survey_version = 0
			   AND lookup_key = 'V1TXT';

			v_response_guid := csr.quick_survey_pkg.GetGUIDFromResponseId(v_response_id);

			csr.quick_survey_pkg.SetAnswerForResponseGuid(
				in_question_id => v_question_id,
				in_guid => v_response_guid,
				in_answer => 'test'
			);

			csr.quick_survey_pkg.Submit(
				in_response_id => v_response_id,
				out_submission_id => v_submission_id
			);
		END;
	BEGIN
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;

		csr.enable_pkg.EnableAudit;
		csr.enable_pkg.EnableAuditFiltering;
		csr.enable_pkg.EnableMultipleAuditSurveys;

		-- Rename menu item from "Audits" to "Internal audit"
		BEGIN
			v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/ia');
			security.menu_pkg.SetMenu(v_act_id, v_sid, 'Internal audit', '/csr/site/audit/auditlist.acds', 8, NULL);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'It seems the audit module has not been enabled for this site. Run utils\enableAudit');
		END;

		SELECT region_root_sid
		  INTO v_region_root_sid
		  FROM csr.customer
		 WHERE app_sid = v_app_sid;

		DBMS_OUTPUT.PUT_LINE('Create an audit type');
		v_audit_type_id := CreateMultipleSurveyAuditType('UITest Audit Type - DO NOT DELETE', NULL, NULL);

		v_audit_region_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_region_root_sid, 'Main/UITestSuit_ELETE');

		DBMS_OUTPUT.PUT_LINE('Create an audit for creating Non-Compliances etc against');
		BEGIN
			SELECT internal_audit_sid
			  INTO v_sid
			  FROM csr.internal_audit
			 WHERE app_sid = v_app_sid
			   AND label = 'UITestSuite Audit - DO NOT DELETE';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.audit_pkg.Save(
					in_sid_id				=> NULL,
					in_audit_ref			=> NULL,
					in_survey_sid			=> NULL,
					in_region_sid			=> v_audit_region_sid,
					in_label				=> 'UITestSuite Audit - DO NOT DELETE',
					in_audit_dtm			=> DATE '2013-03-20',
					in_auditor_user_sid		=> security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/admin'),
					in_notes				=> 'UITestSuite Audit Notes',
					in_internal_audit_type	=> v_audit_type_id,
					in_auditor_name			=> 'UITestSuite Auditor',
					in_auditor_org			=> 'UITestSuite Audit Organisation',
					in_response_to_audit	=> NULL,
					in_created_by_sid		=> NULL,
					in_auditee_user_sid		=> NULL,
					out_sid_id				=> v_sid
				);
		END;

		DBMS_OUTPUT.PUT_LINE('Create a UITestSuite non-compliance against the Audit.');
		DECLARE
			v_dummy_cur		security.security_pkg.T_OUTPUT_CUR;
			v_dummy_sids  security.security_pkg.T_SID_IDS;
			v_dummy_keys  csr.audit_pkg.T_CACHE_KEYS;
			v_count			NUMBER;
		BEGIN
			SELECT COUNT(*)
			  INTO v_count
			  FROM csr.non_compliance
			 WHERE label = 'UITestSuite Non-Compliance - DO NOT DELETE';

			IF v_count = 0 THEN
				csr.audit_pkg.SaveNonCompliance(
					in_non_compliance_id		=>	NULL,
					in_internal_audit_sid		=>	v_sid,
					in_from_non_comp_default_id =>	NULL,
					in_label					=>	'UITestSuite Non-Compliance - DO NOT DELETE',
					in_detail					=>	'UITestSuite non-compliance detail.',
					in_non_compliance_type_id	=>	NULL,
					in_is_closed				=>	NULL,
					in_current_file_uploads		=>	v_dummy_sids,
					in_new_file_uploads			=>	v_dummy_keys,
					in_tag_ids					=>	v_dummy_sids,
					in_question_id				=>	NULL,
					in_question_option_id		=>	NULL,
					out_nc_cur					=>	v_dummy_cur,
					out_nc_upload_cur			=>	v_dummy_cur,
					out_nc_tag_cur				=>	v_dummy_cur
				);

				-- Get the ID of the non-compliance we just created.
				SELECT non_compliance_id
				  INTO v_sid
				  FROM csr.non_compliance
				 WHERE label = 'UITestSuite Non-Compliance - DO NOT DELETE';

				-- Create a UITestSuite non-compliance issue against the Audit.
				csr.audit_pkg.AddNonComplianceIssue(
					in_non_compliance_id	=> v_sid,
					in_label				=> 'UITestSuite Non Comp - DO NOT DELETE',
					in_description			=> 'UITestSuite Non-compliance.',
					out_issue_id			=> v_sid
				);
			END IF;
		END;

		v_primary_survey_sid := ImportSurvey(v_primaryXml, 'carryForwardPrimary', 'Carry Forward Primary - DO NOT DELETE');
		v_secondary_survey_sid := ImportSurvey(v_secondaryXml, 'carryForwardSecondary', 'Carry Forward Secondary - DO NOT DELETE');
		v_audit_type_id := CreateMultipleSurveyAuditType('UITest Carry Forward Audit Type - DO NOT DELETE', v_primary_survey_sid, v_secondary_survey_sid);

		BEGIN
			SELECT internal_audit_sid
			  INTO v_sid
			  FROM csr.internal_audit
			 WHERE app_sid = v_app_sid
			   AND label = 'UITestSuite Carry Forward Original - DO NOT DELETE';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.audit_pkg.Save(
					in_sid_id				=> NULL,
					in_audit_ref			=> NULL,
					in_survey_sid			=> NULL,
					in_region_sid			=> v_audit_region_sid,
					in_label				=> 'UITestSuite Carry Forward Original - DO NOT DELETE',
					in_audit_dtm			=> DATE '2013-03-20',
					in_auditor_user_sid		=> security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/admin'),
					in_notes				=> 'UITestSuite Audit Notes',
					in_internal_audit_type	=> v_audit_type_id,
					in_auditor_name			=> 'UITestSuite Auditor',
					in_auditor_org			=> 'UITestSuite Audit Organisation',
					in_response_to_audit	=> NULL,
					in_created_by_sid		=> NULL,
					in_auditee_user_sid		=> NULL,
					out_sid_id				=> v_sid
				);

				SubmitAuditSurveyResponse(v_sid, csr.audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID);

				SELECT internal_audit_type_survey_id
				  INTO v_secondary_survey_type
				  FROM csr.internal_audit_type_survey
				 WHERE internal_audit_type_id = v_audit_type_id
				   AND survey_group_key = 'SECONDARY';

				SubmitAuditSurveyResponse(v_sid, v_secondary_survey_type);
		END;
	END;
BEGIN
	IF in_is_multiple_survey_audits = 1 THEN
		SetupMultipleSurveyAudits;
	ELSE
		SetupStandardAudits;
	END IF;
END;

PROCEDURE INTERNAL_SetupUserRegionRoles
AS
	v_contributors_role_sid		security.security_pkg.T_SID_ID;
	v_data_providers_role_sid	security.security_pkg.T_SID_ID;
	v_role_sids					security.security_pkg.T_SID_IDS;
	v_region_sids				security.security_pkg.T_SID_IDS;
	v_user_sids					security.security_pkg.T_SID_IDS;
BEGIN
	csr.role_pkg.SetRole('Contributors', v_contributors_role_sid);
	csr.role_pkg.SetRole('Data Providers', v_data_providers_role_sid);
	v_role_sids(0) := v_contributors_role_sid;
	v_role_sids(1) := v_data_providers_role_sid;

	v_region_sids(0) := gv_main_test_region_sid;
	v_region_sids(1) := gv_create_delete_del_reg_sid;

	v_user_sids(0) := gv_uitest_user_sid;
	v_user_sids(1) := gv_uitest_user1_sid;
	v_user_sids(2) := gv_uitest_user2_sid;
	v_user_sids(3) := gv_uitest_user3_sid;

	FOR r IN v_role_sids.FIRST .. v_role_sids.LAST
	LOOP
		FOR region IN v_region_sids.FIRST .. v_region_sids.LAST
		LOOP
			FOR u IN v_user_sids.FIRST .. v_user_sids.LAST
			LOOP
				role_pkg.AddRoleMemberForRegion(
					in_role_sid => v_role_sids(r),
					in_region_sid => v_region_sids(region),
					in_user_sid => v_user_sids(u));
			END LOOP;
		END LOOP;
	END LOOP;
END;

PROCEDURE INTERNAL_SetupAlerts
AS
	v_customer_alert_type_id	customer_alert_type.customer_alert_type_id%TYPE;
	v_default_alert_frame_id	alert_frame.alert_frame_id%TYPE;
BEGIN
	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM customer_alert_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND std_alert_type_id = csr.csr_data_pkg.ALERT_NEW_DELEGATION;

	SELECT alert_frame_id
	  INTO v_default_alert_frame_id
	  FROM alert_frame
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND name = 'Default';

	alert_pkg.SaveTemplateAndBody(
		in_customer_alert_type_id => v_customer_alert_type_id,
		in_alert_frame_id => v_default_alert_frame_id,
		in_send_type => 'inactive',
		in_reply_to_name => NULL,
		in_reply_to_email => NULL,
		in_lang => 'en',
		in_subject => '<template />',
		in_body_html => '<template />',
		in_item_html => '<template />'
	);
END;

PROCEDURE INTERNAL_SetupHomePageTabs
AS
	v_data_providers_role_sid	security.security_pkg.T_SID_ID;
	v_data_approvers_role_sid	security.security_pkg.T_SID_ID;
	v_my_data_tab_id			security.security_pkg.T_SID_ID;
BEGIN
	csr.role_pkg.SetRole('Data Providers', v_data_providers_role_sid);
	csr.role_pkg.SetRole('Data Approvers', v_data_approvers_role_sid);

	SELECT tab_id
	  INTO v_my_data_tab_id
	  FROM tab
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND name = 'My data';

	BEGIN
		INSERT INTO tab_group(group_sid, tab_id)
		VALUES (v_data_providers_role_sid, v_my_data_tab_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO tab_group(group_sid, tab_id)
		VALUES (v_data_approvers_role_sid, v_my_data_tab_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE INTERNAL_SetupFrameworks
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_flow_sid						security.security_pkg.T_SID_ID;
	v_indexes_sid					security.security_pkg.T_SID_ID;
	v_framework_root_sid			security.security_pkg.T_SID_ID;
	v_framework_root_sid2			security.security_pkg.T_SID_ID;
	v_demo_framework_root_sid		security.security_pkg.T_SID_ID;
	v_folder_sid					security.security_pkg.T_SID_ID;
	v_initial_check_flow_state_id	flow_state.flow_state_id%TYPE;
	v_with_bus_exp_flow_state_id	flow_state.flow_state_id%TYPE;
	v_approved_flow_state_id		flow_state.flow_state_id%TYPE;
	v_ready_for_rvw_flow_state_id	flow_state.flow_state_id%TYPE;
	v_review_by_lgl_flow_state_id	flow_state.flow_state_id%TYPE;
	v_send_to_business_experts		section_routed_flow_state.reject_fs_transition_id%TYPE;
	v_return_to_cr_team				section_routed_flow_state.reject_fs_transition_id%TYPE;
	v_submit						section_routed_flow_state.reject_fs_transition_id%TYPE;
	v_send_for_legal_review			section_routed_flow_state.reject_fs_transition_id%TYPE;
	v_review_completed				section_routed_flow_state.reject_fs_transition_id%TYPE;
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	v_indexes_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Indexes');

	v_flow_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Workflows/Corporate Reporter');

	SELECT flow_state_id
	  INTO v_initial_check_flow_state_id
	  FROM flow_state
	 WHERE flow_sid = v_flow_sid
	   AND label = 'Initial check';

	SELECT flow_state_id
	  INTO v_with_bus_exp_flow_state_id
	  FROM flow_state
	 WHERE flow_sid = v_flow_sid
	   AND label = 'With business experts';

	SELECT flow_state_id
	  INTO v_approved_flow_state_id
	  FROM flow_state
	 WHERE flow_sid = v_flow_sid
	   AND label = 'Approved';

	SELECT flow_state_id
	  INTO v_ready_for_rvw_flow_state_id
	  FROM flow_state
	 WHERE flow_sid = v_flow_sid
	   AND label = 'Ready for review';

	SELECT flow_state_id
	  INTO v_review_by_lgl_flow_state_id
	  FROM flow_state
	 WHERE flow_sid = v_flow_sid
	   AND label = 'Review by legal';

	SELECT flow_state_transition_id
	  INTO v_send_to_business_experts
	  FROM flow_state_transition
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND verb = 'Send to business experts';

	SELECT flow_state_transition_id
	  INTO v_return_to_cr_team
	  FROM flow_state_transition
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND verb = 'Return to CR Team';

	SELECT flow_state_transition_id
	  INTO v_submit
	  FROM flow_state_transition
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND verb = 'Submit';

	SELECT flow_state_transition_id
	  INTO v_send_for_legal_review
	  FROM flow_state_transition
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND verb = 'Send for legal review';

	SELECT flow_state_transition_id
	  INTO v_review_completed
	  FROM flow_state_transition
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND verb = 'Review completed';

	-- make sure the roles in the Corporate Reporter workflow are set up the way the tests expect
	DECLARE
		v_contributors_role_sid			security.security_pkg.T_SID_ID;
		v_cr_team_role_sid				security.security_pkg.T_SID_ID;
		v_data_approvers_role_sid		security.security_pkg.T_SID_ID;
	BEGIN
		role_pkg.SetRole('Contributors', v_contributors_role_sid);
		role_pkg.SetRole('CR Team', v_cr_team_role_sid);
		role_pkg.SetRole('Data Approvers', v_data_approvers_role_sid);

		-- roles on states
		BEGIN
			INSERT INTO flow_state_role(flow_state_id, role_sid, is_editable)
				VALUES (v_initial_check_flow_state_id, v_contributors_role_sid, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_role(flow_state_id, role_sid, is_editable)
				VALUES (v_initial_check_flow_state_id, v_cr_team_role_sid, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_role(flow_state_id, role_sid, is_editable)
				VALUES (v_with_bus_exp_flow_state_id, v_cr_team_role_sid, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_role(flow_state_id, role_sid, is_editable)
				VALUES (v_approved_flow_state_id, v_data_approvers_role_sid, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		-- roles on transitions
		BEGIN
			INSERT INTO flow_state_transition_role(flow_state_transition_id, from_state_id, role_sid, group_sid)
				VALUES (v_send_to_business_experts, v_initial_check_flow_state_id, v_contributors_role_sid, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_transition_role(flow_state_transition_id, from_state_id, role_sid, group_sid)
				VALUES (v_send_to_business_experts, v_initial_check_flow_state_id, v_cr_team_role_sid, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_transition_role(flow_state_transition_id, from_state_id, role_sid, group_sid)
				VALUES (v_return_to_cr_team, v_with_bus_exp_flow_state_id, v_contributors_role_sid, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_transition_role(flow_state_transition_id, from_state_id, role_sid, group_sid)
				VALUES (v_return_to_cr_team, v_with_bus_exp_flow_state_id, v_cr_team_role_sid, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO flow_state_transition_role(flow_state_transition_id, from_state_id, role_sid, group_sid)
				VALUES (v_submit, v_with_bus_exp_flow_state_id, v_cr_team_role_sid, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END;

	-- make sure the POS attributes in the Corporate Reporter flow are set as expected (for some reason, they're all set to 1 initially)
	UPDATE flow_state
	   SET pos = 2
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND label = 'With business experts'
	   AND pos = 1;

	UPDATE flow_state
	   SET pos = 3
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND label = 'Ready for review'
	   AND pos = 1;

	UPDATE flow_state
	   SET pos = 4
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND label = 'Review by legal'
	   AND pos = 1;

	UPDATE flow_state
	   SET pos = 5
	 WHERE app_sid = v_app_sid
	   AND flow_sid = v_flow_sid
	   AND label = 'Approved'
	   AND pos = 1;

	-- make sure the "Transition for Rejecting" options are set as expected (mostly seem to be null by default)
	BEGIN
		UPDATE section_routed_flow_state
		   SET reject_fs_transition_id = v_send_to_business_experts
		 WHERE app_sid = v_app_sid
		   AND flow_sid = v_flow_sid
		   AND flow_state_id = v_initial_check_flow_state_id;

		UPDATE section_routed_flow_state
		   SET reject_fs_transition_id = v_send_for_legal_review
		 WHERE app_sid = v_app_sid
		   AND flow_sid = v_flow_sid
		   AND flow_state_id = v_ready_for_rvw_flow_state_id;

		UPDATE section_routed_flow_state
		   SET reject_fs_transition_id = v_review_completed
		 WHERE app_sid = v_app_sid
		   AND flow_sid = v_flow_sid
		   AND flow_state_id = v_review_by_lgl_flow_state_id;
	END;

	-- make sure final flow states are marked as final
	UPDATE flow_state
	   SET is_final = 1
	 WHERE flow_state_id = v_approved_flow_state_id;

	DECLARE
		v_introduction_sid			security.security_pkg.T_SID_ID;
		v_w0_introduction_sid		security.security_pkg.T_SID_ID;
		v_current_state				security.security_pkg.T_SID_ID;
		v_w1_context_sid			security.security_pkg.T_SID_ID;
		v_risk_assessment			security.security_pkg.T_SID_ID;
		v_w2_procedures_and_reqs	security.security_pkg.T_SID_ID;
		v_response					security.security_pkg.T_SID_ID;
		v_w7_compliance				security.security_pkg.T_SID_ID;
		v_w7_1_penalties			security.security_pkg.T_SID_ID;
		v_sign_off					security.security_pkg.T_SID_ID;
		v_ignore					security.security_pkg.T_SID_ID;
	
		PROCEDURE CreateSection(
			in_module_root_sid			IN	security.security_pkg.T_SID_ID DEFAULT NULL, -- NULL=>v_demo_framework_root_sid
			in_parent_sid_id			IN	security.security_pkg.T_SID_ID,
			in_title					IN	VARCHAR2,
			in_body						IN	CLOB,
			in_is_form					IN	BOOLEAN DEFAULT FALSE,
			out_sid_id					OUT	security.security_pkg.T_SID_ID
		)
		AS
		BEGIN
			section_pkg.CreateSectionWithPerms(
				in_act_id => v_act_id,
				in_app_sid => v_app_sid,
				in_module_root_sid => NVL(in_module_root_sid, v_demo_framework_root_sid),
				in_access_perms => 227,
				in_parent_sid_id => in_parent_sid_id,
				in_title => in_title,
				in_title_only => CASE WHEN in_body IS NULL THEN 1 ELSE 0 END,
				in_body => in_body,
				in_help_text => NULL,
				in_ref => NULL,
				in_further_info_url => NULL,
				in_plugin => CASE WHEN in_is_form THEN 'Credit360.Text.FormPlugin' ELSE NULL END,
				in_auto_checkout => 0,
				out_sid_id => out_sid_id
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;

		PROCEDURE CreateTestFramework
		AS
		BEGIN
			v_framework_root_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_indexes_sid, 'Test Framework-DoNotDelete');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				section_root_pkg.CreateRoot(
					in_act_id => v_act_id,
					in_app_sid_id => v_app_sid,
					in_name => 'Test Framework-DoNotDelete',
					in_flow_sid => v_flow_sid,
					in_flow_region_sid => gv_framework_region_sid,
					in_default_start => NULL,
					in_default_end => NULL,
					out_sid_id => v_framework_root_sid
				);

				CreateSection(
					in_module_root_sid => v_framework_root_sid,
					in_parent_sid_id => NULL,
					in_title => 'TestQuestion-DoNotDelete',
					in_body => 'Keyword',
					out_sid_id => v_ignore
				);

				CreateSection(
					in_module_root_sid => v_framework_root_sid,
					in_parent_sid_id => NULL,
					in_title => 'TestFolderInFramework-DoNotDelete',
					in_body => NULL,
					out_sid_id => v_ignore
				);

				CreateSection(
					in_module_root_sid => v_framework_root_sid,
					in_parent_sid_id => NULL,
					in_title => 'SearchQuestion-DoNotDelete',
					in_body => 'Some body content',
					out_sid_id => v_ignore
				);
		END;

		PROCEDURE CreateFrameworkForDupScenario
		AS
		BEGIN
			v_framework_root_sid2 := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_indexes_sid, 'FrameworkForDuplicateScenario-DoNotDelete');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				section_root_pkg.CreateRoot(
					in_act_id => v_act_id,
					in_app_sid_id => v_app_sid,
					in_name => 'FrameworkForDuplicateScenario-DoNotDelete',
					in_flow_sid => v_flow_sid,
					in_flow_region_sid => gv_framework_region_sid,
					in_default_start => NULL,
					in_default_end => NULL,
					out_sid_id => v_framework_root_sid2
				);
		END;

		PROCEDURE CreateDemoFramework
		AS
		BEGIN
			v_demo_framework_root_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_indexes_sid, 'DemoFramework-DoNotDelete');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				section_root_pkg.CreateRoot(
					in_act_id => v_act_id,
					in_app_sid_id => v_app_sid,
					in_name => 'DemoFramework-DoNotDelete',
					in_flow_sid => v_flow_sid,
					in_flow_region_sid => gv_framework_region_sid,
					in_default_start => NULL,
					in_default_end => NULL,
					out_sid_id => v_demo_framework_root_sid
				);

				-- indentation below follows the tree hierarchy

				CreateSection(
					in_parent_sid_id => NULL,
					in_title => 'Introduction',
					in_body => NULL,
					out_sid_id => v_introduction_sid
				);

					CreateSection(
						in_parent_sid_id => v_introduction_sid,
						in_title => 'W0. Introduction',
						in_body => NULL,
						out_sid_id => v_w0_introduction_sid
					);

						CreateSection(
							in_parent_sid_id => v_w0_introduction_sid,
							in_title => 'W0.1 Please give a general description and introduction to your organization',
							in_body => 'Response editedfgfgfgh<br />',
							out_sid_id => v_ignore
						);

						CreateSection(
							in_parent_sid_id => v_w0_introduction_sid,
							in_title => 'W0.2 Please state the start and end date of the year for which you are reporting data',
							in_body => '|#Start date|#End Date|' || chr(10) || '|[20]|[20]|',
							in_is_form => TRUE,
							out_sid_id => v_ignore
						);

						CreateSection(
							in_parent_sid_id => v_w0_introduction_sid,
							in_title => 'W0.3 Please indicate the category that describes the reporting boundary for companies, entities or groups for which water-related impacts are reported',
							in_body => 'Another response',
							out_sid_id => v_ignore
						);

						CreateSection(
							in_parent_sid_id => v_w0_introduction_sid,
							in_title => 'W0.4 Are there any geographies, facilities or types of water inputs/outputs within this boundary which are not included in your disclosure?',
							in_body => 'o Yes' || chr(10) || 'o No',
							in_is_form => TRUE,
							out_sid_id => v_ignore
						);

				CreateSection(
					in_parent_sid_id => NULL,
					in_title => 'Current state',
					in_body => NULL,
					out_sid_id => v_current_state
				);

					CreateSection(
						in_parent_sid_id => v_current_state,
						in_title => 'W1. Context',
						in_body => NULL,
						out_sid_id => v_w1_context_sid
					);

						CreateSection(
							in_parent_sid_id => v_w1_context_sid,
							in_title => 'W1.1 Please rate the importance (current and future) of water quality and water quantity to the success of your organization',
							in_body => '|#Water quality and quantity|#Direct use importance rating|#Indirect use importance rating|#Please explain (500 characters max)|' || chr(10) ||
									'|#Sufficient amounts of good quality freshwater available for use|{Not important at all|Not very important|Neutral|Important|Vital for operations|Have not evaluated}|{Not important at all|Not very important|Neutral|Important|Vital for operations|Have not evaluated}|[200++]|' || chr(10) ||
									'|#Sufficient amounts of recycled, brackish and/or produced water available for use|{Not important at all|Not very important|Neutral|Important|Vital for operations|Have not evaluated}|{Not important at all|Not very important|Neutral|Important|Vital for operations|Have not evaluated}|[200++]|',
							in_is_form => TRUE,
							out_sid_id => v_ignore
						);

				CreateSection(
					in_parent_sid_id => NULL,
					in_title => 'Risk assessment',
					in_body => NULL,
					out_sid_id => v_risk_assessment
				);

					CreateSection(
						in_parent_sid_id => v_risk_assessment,
						in_title => 'W2. Procedures and requirements',
						in_body => NULL,
						out_sid_id => v_w2_procedures_and_reqs
					);

						CreateSection(
							in_parent_sid_id => v_w2_procedures_and_reqs,
							in_title => 'W2.1 Does your organization undertake a water-related risk assessment?',
							in_body => '{Water risks are not assessed|Water risks are assessed}' || chr(10) || chr(10) ||
									'If Water risks are assessed, you will be required to answer questions W2.2-W2.7. If you select Water risks are not assessed you will proceed to question W2.8',
							in_is_form => TRUE,
							out_sid_id => v_ignore
						);

						CreateSection(
							in_parent_sid_id => v_w2_procedures_and_reqs,
							in_title => 'W2.2 Please select the options that best describe your procedures with regard to assessing water risks',
							in_body => '|#Risk assessment procedure|#Coverage|#Choose option|#Comment|' || chr(10) ||
									'|{Comprehensive company-wide risk assessment|Water risk assessment undertaken independently of other risk assessments}|{Direct operations and supply chain|Direct operations|Supply chain}|{All facilities and suppliers|All facilities and some suppliers|Some facilities and all suppliers|Some facilities and some suppliers|All facilities|Some facilities|All suppliers|Some suppliers}|[200++]|',
							in_is_form => TRUE,
							out_sid_id => v_ignore
						);

				CreateSection(
					in_parent_sid_id => NULL,
					in_title => 'Response',
					in_body => NULL,
					out_sid_id => v_response
				);

					CreateSection(
						in_parent_sid_id => v_response,
						in_title => 'W7. Compliance',
						in_body => NULL,
						out_sid_id => v_w7_compliance
					);

						CreateSection(
							in_parent_sid_id => v_w7_compliance,
							in_title => 'W7.1 If Yes: Was your organization subject to any penalties, fines, and/or enforcement orders for breaches of abstraction licenses, discharge consents or other water and wastewater related regulations in the reporting year?',
							in_body => 'o Yes, significant' || chr(10) ||
									'o Yes, not significant' || chr(10) ||
									'o No' || chr(10) ||
									'o Don''t know',
							in_is_form => TRUE,
							out_sid_id => v_w7_1_penalties
						);

							CreateSection(
								in_parent_sid_id => v_w7_1_penalties,
								in_title => 'W7.1a If Yes: Please describe the penalties, fines and/or enforcement orders for breaches of abstraction licenses, discharge consents or other water and wastewater related regulations and your plans for resolving them',
								in_body => '|#Facility name (500 characters max)|#Incident|#Incident description (500 characters max)|#Frequency of occurrence in reporting year|#Financial impact|#Currency|#Incident resolution (500 characters max)|' || chr(10) ||
										'|[200]|{Penalty|Fine|Enforcement order}|[200]|[40]|[40]|[40]|[200]|*' || chr(10) ||
										'|[200]|{Penalty|Fine|Enforcement order}|[200]|[40]|[40]|[40]|[200]|+',
								in_is_form => TRUE,
								out_sid_id => v_ignore
							);

							CreateSection(
								in_parent_sid_id => v_w7_1_penalties,
								in_title => 'W7.1b What percentage of your total facilities/operations are associated with the incidents listed in W7.1a?',
								in_body => NULL,
								out_sid_id => v_ignore
							);

							CreateSection(
								in_parent_sid_id => v_w7_1_penalties,
								in_title => 'W7.1c If Yes: Please indicate the total financial impacts of all incidents reported in W7.1a as a proportion of total operating expenditure (OPEX) for the reporting year. Please also provided a comparison of this proportion compared to the previous reporting year',
								in_body => '|#Impact as % of OPEX|#Comparison to last year|' || chr(10) ||
										'|[20]|{Much lower|Lower|No change|Higher|Much higher}|',
								in_is_form => TRUE,
								out_sid_id => v_ignore
							);

				CreateSection(
					in_parent_sid_id => NULL,
					in_title => 'Sign off',
					in_body => NULL,
					out_sid_id => v_sign_off
				);

					CreateSection(
						in_parent_sid_id => v_sign_off,
						in_title => 'W10.1 Please provide the following information for the person that has signed off (approved) your CDP water response',
						in_body => '|#Name|#Job title|#Corresponding job category|' || chr(10) ||
								'|[200]|[200]|Select from: {Board chairman|Board/Executive board|Director on board|Chief Executive Officer (CEO)|Chief Financial Officer (CFO)|Chief Operating Officer (COO)|Business unit manager|Energy manager|Environment/Sustainability manager|Facilities manager|Head of risk|Head of strategy|Process operation manager|Public affairs manager|Risk manager} Other, please specify: [40]|',
						in_is_form => TRUE,
						out_sid_id => v_ignore
					);
			END CreateDemoFramework;

		PROCEDURE CreateFrameworkSearchFramework
		AS
			v_some_other_body				security.security_pkg.T_SID_ID;
			v_framework_search_framework	security.security_pkg.T_SID_ID;
		BEGIN
			v_framework_search_framework := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_indexes_sid, 'FrameworkSearch-DoNotDelete');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				section_root_pkg.CreateRoot(
					in_act_id => v_act_id,
					in_app_sid_id => v_app_sid,
					in_name => 'FrameworkSearch-DoNotDelete',
					in_flow_sid => v_flow_sid,
					in_flow_region_sid => gv_framework_region_sid,
					in_default_start => NULL,
					in_default_end => NULL,
					out_sid_id => v_framework_search_framework
				);

				-- the way Frameworks is designed, top-level sections are expected to be title only
				-- so any body assigned to the top-level section won't show up sensibly in the UI
				-- we could create a second section as a child, with a body of, say, '# Feedback' || CHR(10) || '[20] What do you think of it so far?'

				CreateSection(
					in_module_root_sid => v_framework_search_framework,
					in_parent_sid_id => NULL,
					in_title => 'FrameworkSearchTestQuestion-DoNotDelete',
					in_body => NULL,
					in_is_form => FALSE,
					out_sid_id => v_ignore
				);
		END;

		PROCEDURE CreateFrameworkForDownload
		AS
			v_framework_for_download		security.security_pkg.T_SID_ID;
		BEGIN
			v_framework_for_download := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_indexes_sid, 'FrameworkForDownload-DoNotDelete');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				section_root_pkg.CreateRoot(
					in_act_id => v_act_id,
					in_app_sid_id => v_app_sid,
					in_name => 'FrameworkForDownload-DoNotDelete',
					in_flow_sid => v_flow_sid,
					in_flow_region_sid => gv_framework_region_sid,
					in_default_start => NULL,
					in_default_end => NULL,
					out_sid_id => v_framework_for_download
				);

				CreateSection(
					in_module_root_sid => v_framework_for_download,
					in_parent_sid_id => NULL,
					in_title => 'Cr360 Automation Team',
					in_body => 'Automation status', -- no point setting a body in a top-level section
					out_sid_id => v_ignore
				);
		END;

	BEGIN
		CreateTestFramework;

		CreateFrameworkForDupScenario;

		CreateDemoFramework;

		CreateFrameworkSearchFramework;

		CreateFrameworkForDownload;
	END;

	-- create carts
	DECLARE
		PROCEDURE CreateEmptyCart(
			in_cart_name				section_cart.name%TYPE
		)
		AS
			v_no_section_sids			security.security_pkg.T_SID_IDS;
			v_matching_cart_count		NUMBER;
			v_cart_id					security.security_pkg.T_SID_ID;
		BEGIN
			SELECT COUNT(*)
			  INTO v_matching_cart_count
			  FROM section_cart
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND name = in_cart_name;

			IF v_matching_cart_count = 0 THEN
				section_pkg.CreateCart(
					in_name => in_cart_name,
					in_section_sids => v_no_section_sids,
					out_id => v_cart_id);
			END IF;
		END;
	BEGIN
		CreateEmptyCart(in_cart_name => 'TestCart-DoNotDelete');
		CreateEmptyCart(in_cart_name => 'CartForDuplicateScenario-DoNotDelete');
	END;

	-- create section tags
	DECLARE
		v_tag_id					security.security_pkg.T_SID_ID;
	BEGIN
		-- ignores duplicates (sets out_tag_id to -1 if we ask for a dupe) so we can just call it
		section_pkg.CreateSectionTag(
			in_tag => 'TestTag-DoNotDelete',
			in_parent_id => NULL,
			out_tag_id => v_tag_id
		);

		section_pkg.CreateSectionTag(
			in_tag => 'TagForDuplicateScenario-DoNotDelete',
			in_parent_id => NULL,
			out_tag_id => v_tag_id
		);
	END;

	BEGIN
		v_folder_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_indexes_sid, 'TestFolderOnFrameworksList-DoNotDelete');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			folderlib_pkg.CreateFolder(
				in_parent_sid => v_indexes_sid,
				in_name => 'TestFolderOnFrameworksList-DoNotDelete',
				out_sid_id => v_folder_sid
			);
	END;

	-- create business expert user
	DECLARE
		v_user_business_expert_sid		security.security_pkg.T_SID_ID;
		v_admin_group_sid				security.security_pkg.T_SID_ID;
		v_contributors_role_sid			security.security_pkg.T_SID_ID;
		v_cr_team_role_sid				security.security_pkg.T_SID_ID;
	BEGIN
		INTERNAL_CreateUser('User-BusinessExpert', v_user_business_expert_sid);
		v_admin_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct,
			security.security_pkg.Getapp, 'Groups/Administrators');
		UNSEC_AddGroupMember(v_user_business_expert_sid, v_admin_group_sid);

		role_pkg.SetRole('Contributors', v_contributors_role_sid);

		role_pkg.SetRole('CR Team', v_cr_team_role_sid);

		role_pkg.AddRoleMemberForRegion(
			in_role_sid => v_contributors_role_sid,
			in_region_sid => gv_framework_region_sid,
			in_user_sid => v_user_business_expert_sid);

		role_pkg.AddRoleMemberForRegion(
			in_role_sid => v_cr_team_role_sid,
			in_region_sid => gv_framework_region_sid,
			in_user_sid => v_user_business_expert_sid);
	END;

	-- create user with "ready for review" rights
	DECLARE
		v_user_ready_for_review_sid		security.security_pkg.T_SID_ID;
		v_admin_group_sid				security.security_pkg.T_SID_ID;
		v_cr_team_role_sid				security.security_pkg.T_SID_ID;
	BEGIN
		INTERNAL_CreateUser('User-ReadyForReview', v_user_ready_for_review_sid);
		v_admin_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct,
			security.security_pkg.Getapp, 'Groups/Administrators');
		UNSEC_AddGroupMember(v_user_ready_for_review_sid, v_admin_group_sid);

		role_pkg.SetRole('CR Team', v_cr_team_role_sid);

		role_pkg.AddRoleMemberForRegion(
			in_role_sid => v_cr_team_role_sid,
			in_region_sid => gv_framework_region_sid,
			in_user_sid => v_user_ready_for_review_sid);
	END;

	COMMIT;
END;

PROCEDURE INTERNAL_SetupPortalDashboards
AS
	v_user_with_auditor_rights_sid		security.security_pkg.T_SID_ID;
	v_auditors_group_sid				security.security_pkg.T_SID_ID;
	v_administrators_group_sid			security.security_pkg.T_SID_ID;
	v_dashboard_root_sid				security.security_pkg.T_SID_ID;
	v_dashboard_sid						security.security_pkg.T_SID_ID;
	v_dashboard_menu_group_sids			security.security_pkg.T_SID_IDS;
	v_dashboard_group_sids				security.security_pkg.T_SID_IDS;
	v_admin_menu_sid					security.security_pkg.T_SID_ID;
	v_act_id							security.security_pkg.T_ACT_ID;
	v_app_sid							security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := security.security_pkg.GetAct;
	v_app_sid := security.security_pkg.GetApp;

	-- create user
	INTERNAL_CreateUser('UserWithAuditorsRights - DoNotDelete', v_user_with_auditor_rights_sid);
	v_auditors_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Auditors');
	UNSEC_AddGroupMember(v_user_with_auditor_rights_sid, v_auditors_group_sid);

	-- create test dashboard
	SELECT v_auditors_group_sid BULK COLLECT INTO v_dashboard_menu_group_sids FROM DUAL;

	v_administrators_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
	SELECT v_administrators_group_sid BULK COLLECT INTO v_dashboard_group_sids FROM DUAL;

	v_dashboard_root_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'PortalDashboards');

	v_admin_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Menu/admin');

	DECLARE
		PROCEDURE AddTabWithChart(
			in_tab_name					IN	VARCHAR2,
			in_portlet_type				IN	VARCHAR2,
			in_chart_name				IN	VARCHAR2
		)
		AS
			v_tab_id							security.security_pkg.T_SID_ID;
			v_customer_chart_portlet_sid		security.security_pkg.T_SID_ID;
			v_tab_portlet_id					security.security_pkg.T_SID_ID;
			v_everyone_group					security.security_pkg.T_SID_ID;
			v_ignore_cur						SYS_REFCURSOR;
		BEGIN
			portlet_pkg.AddTabReturnTabId(
				in_app_sid => v_app_sid,
				in_tab_name => in_tab_name,
				in_is_shared => 1,
				in_is_hideable => 1,
				in_layout => 2,
				in_portal_group => 'TestPortalDashboard - DoNotDelete',
				out_tab_id => v_tab_id
			);

			-- make sure everyone can see the new tab (since we're creating it as built-in admin)
			v_everyone_group := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Everyone');

			portlet_pkg.AddTabForGroup(
				in_group_sid => v_everyone_group,
				in_tab_id => v_tab_id
			);

			SELECT cp.customer_portlet_sid
			  INTO v_customer_chart_portlet_sid
			  FROM csr.customer_portlet cp
			  JOIN csr.portlet p ON cp.portlet_id = p.portlet_id
			 WHERE cp.app_sid = v_app_sid
			   AND p.name = in_portlet_type;

			portlet_pkg.AddPortletToTab(
				in_tab_id => v_tab_id,
				in_customer_portlet_sid => v_customer_chart_portlet_sid,
				out_cur => v_ignore_cur
			);

			SELECT tab_portlet_id
			  INTO v_tab_portlet_id
			  FROM tab_portlet
			 WHERE tab_id = v_tab_id
			   AND customer_portlet_sid = v_customer_chart_portlet_sid;

			-- yuck!
			portlet_pkg.SaveState(
				in_tab_portlet_id => v_tab_portlet_id,
				in_state => '{"subscribeToPicker":"","rankingPicker":"","allowDownload":false,"snapEndDateToCurrentDate":false,' ||
							'"chartType":null,"allowDrillDown":false,"drillDownInactiveAllowed":false,"portletHeight":200,' ||
							'"portletTitle":"' || in_chart_name || '"}'
			);

			-- v_auditors_group_sid is set in the outer scope
			portlet_pkg.AddTabForGroup(
				in_group_sid => v_auditors_group_sid,
				in_tab_id => v_tab_id
			);
		END;
	BEGIN
		portal_dashboard_pkg.CreateDashboard(
			in_dashboard_container_sid => v_dashboard_root_sid,
			in_label => 'TestPortalDashboard - DoNotDelete',
			in_message => 'DashboardMessage',
			in_parent_menu_sid => v_admin_menu_sid,
			in_menu_label => 'AutoMenuLabelShared',
			in_menu_group_sids => v_dashboard_menu_group_sids,
			in_dashboard_group_sids => v_dashboard_group_sids,
			out_dashboard_sid => v_dashboard_sid
		);

		-- if we're still going, clean up any old portlet tabs before adding the new ones
		DELETE FROM csr.tab_group WHERE app_sid = v_app_sid AND tab_id IN (SELECT tab_id FROM csr.tab WHERE portal_group = 'TestPortalDashboard - DoNotDelete');
		DELETE FROM csr.tab_user WHERE app_sid = v_app_sid AND tab_id IN (SELECT tab_id FROM csr.tab WHERE portal_group = 'TestPortalDashboard - DoNotDelete');
		DELETE FROM csr.tab_portlet WHERE app_sid = v_app_sid AND tab_id IN (SELECT tab_id FROM csr.tab WHERE portal_group = 'TestPortalDashboard - DoNotDelete');
		DELETE FROM csr.tab WHERE app_sid = v_app_sid AND portal_group = 'TestPortalDashboard - DoNotDelete';

		AddTabWithChart('PortalDashboardTabToHide - DoNotDelete', 'Chart', 'TestChart - DoNotDelete');
		AddTabWithChart('SharedPortalDashboardTab - DoNotDelete', 'Image chart', 'TestImageChart - DoNotDelete');
		AddTabWithChart('TestPortalDashboardTab - DoNotDelete', 'Chart', 'TestChart - DoNotDelete');
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	COMMIT;
END;

/**
 * Add test data to the current site
 *
 * @param 	in_cms_user						Name of the schema for the CMS user
 * @param 	in_is_multiple_survey_audits	0 => create standard audits; 1 => create multiple survey audits
 */
PROCEDURE AddTestData(
	in_cms_user						IN	VARCHAR2,
	in_is_multiple_survey_audits	IN	NUMBER
)
AS
BEGIN
	cms.testdata_pkg.SanityCheck;

	-- need to make sure there's a secondary region tree BEFORE we start creating regions
	-- and before setting gv_region_root_sid
	BEGIN
		DBMS_OUTPUT.PUT_LINE('set up the secondary region tree');
		enable_pkg.CreateSecondaryRegionTree('Secondary hierarchy');
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			DBMS_OUTPUT.PUT_LINE('skipping -- secondary region tree already exists');
	END;

	gv_region_root_sid := region_tree_pkg.GetPrimaryRegionTreeRootSid;

	SELECT host
	  INTO gv_host
	  FROM customer
	 WHERE app_sid = security.security_pkg.GetApp;

	BEGIN
		enable_pkg.EnablePortal;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableIssues2;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		enable_pkg.EnableWorkflow;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	INTERNAL_AddMoreModules;

	cms.testdata_pkg.CreateCmsUser(in_cms_user);

	cms.testdata_pkg.CreateHsTable(in_cms_user);

	UPDATE customer
	   SET oracle_schema = UPPER(in_cms_user)
	 WHERE app_sid = security.security_pkg.GetApp;
	
	INTERNAL_CreateRegions;

	INTERNAL_RenameMenus;

	INTERNAL_CreateUsers;

	INTERNAL_CreateMeasures;

	INTERNAL_CreateIndicators;

	INTERNAL_CreatePtyRegionMetric;

	INTERNAL_SetupAudits(in_is_multiple_survey_audits);

	cms.testdata_pkg.DoCmsStuff(in_cms_user);

	cms.testdata_pkg.AddCmsDelegation;

	security.user_pkg.logonadmin(gv_host);
	cms.testdata_pkg.AddIncidents(in_cms_user);

	INTERNAL_AddScorecarding(in_cms_user);

	INTERNAL_AddGermanLanguage;

	DBMS_OUTPUT.PUT_LINE('Running enableincidents');
	enable_pkg.EnableIncidents;

	enable_pkg.EnableProperties(in_cms_user, 'Office');

	INTERNAL_SetUpPropertyTypes;

	INTERNAL_SetUpPropertyRoles;

	INTERNAL_CreateFundType;

	BEGIN
		DBMS_OUTPUT.PUT_LINE('set up the secondary region tree');
		enable_pkg.CreateSecondaryRegionTree('Secondary hierarchy');
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	INTERNAL_SetUpAlertTemplates;

	INTERNAL_SetUpBulkSmUserList;

	INTERNAL_SetupTabOptionTests;

	INTERNAL_SetupLikeForLike;

	INTERNAL_SetupFactorSets;

	INTERNAL_SetupApprovalDboards;

	INTERNAL_SetupDelegPlanner;

	INTERNAL_SetupUserRegionRoles;

	INTERNAL_SetupAlerts;

	INTERNAL_SetupHomePageTabs;

	INTERNAL_SetupFrameworks;

	INTERNAL_SetupPortalDashboards;

	UPDATE customer
	   SET data_explorer_show_ranking = 1,
	       data_explorer_show_markers = 1,
	       data_explorer_show_trends = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END TestData_pkg;
/
