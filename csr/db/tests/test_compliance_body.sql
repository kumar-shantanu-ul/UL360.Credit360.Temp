CREATE OR REPLACE PACKAGE BODY csr.test_compliance_pkg AS

v_regs						security_pkg.T_SID_IDS;
v_users						security_pkg.T_SID_IDS;
v_role_1_sid				security.security_pkg.T_SID_ID;
v_comp_item_id				compliance_item.compliance_item_id%TYPE;
v_comp_item_id_2			compliance_item.compliance_item_id%TYPE;
v_rollout_test_compliance_item_id	NUMBER := 2234;

PROCEDURE TearDownCIData AS
BEGIN
	DELETE FROM COMPLIANCE_OPTIONS
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM COMPLIANCE_ITEM_DESC_HIST
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM COMPLIANCE_ITEM_VERSION_LOG
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM COMPLIANCE_REGULATION
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM COMPLIANCE_REQUIREMENT
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_permit_condition
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM COMPLIANCE_ITEM_ROLLOUT
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_item_description
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_item_region
	 WHERE app_sid = security_pkg.GetApp;
	
	DELETE FROM compliance_item_tag
	 WHERE app_sid = security_pkg.GetApp;
	
	DELETE FROM compliance_item
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_language
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM flow_state_log
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM flow_item
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM region_role_member
	 WHERE app_sid = security_pkg.GetApp;	
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


PROCEDURE SetUpFixture 
AS
BEGIN
	TearDownCIData;

	-- Insert some test data

	csr_data_pkg.EnableCapability('System management');
	csr_data_pkg.EnableCapability('Issue management');
	enable_pkg.EnableSurveys;
	enable_pkg.EnableCompliance('Y', 'Y', 'N');
	--enable_pkg.EnablePermits;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('Compliance_Region1');
	v_users(1) := csr.unit_test_pkg.GetOrCreateUser('Compliance_USER_1');
END;

PROCEDURE TearDownFixture AS
BEGIN 	
	TearDownCIData;
	RemoveSids(v_regs);
	RemoveSids(v_users);

	IF v_role_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_role_1_sid);
		v_role_1_sid := NULL;
	END IF;
		
	DELETE FROM csr.tag_group_member;
	DELETE FROM csr.tag_description;
	DELETE FROM csr.compliance_item_tag;
	DELETE FROM csr.tag;
	DELETE FROM csr.tag_group_description;
	DELETE FROM csr.tag_group;
END;

PROCEDURE SetUp
AS
BEGIN
	NULL;
END;

PROCEDURE TearDown AS
BEGIN
	DELETE FROM csr.tag_group_member;
	DELETE FROM csr.tag_description;
	DELETE FROM csr.compliance_item_tag;
	DELETE FROM csr.tag;
	DELETE FROM csr.tag_group_description;
	DELETE FROM csr.tag_group;
END;

PROCEDURE TestTempCompLevelsNone AS
	v_count	NUMBER;

	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_flow_item_id					compliance_item_region.flow_item_id%TYPE;
BEGIN
	compliance_pkg.INT_UpdateTempCompLevels(
		in_role_sid => 1,
		in_search => NULL
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_comp_region_lvl_ids;
	
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 records'||' - '||v_count||' found.');
END;

PROCEDURE TestTempCompLevelsOneManyOverflow AS
	v_count				NUMBER;
	v_flow_item_id		compliance_item_region.flow_item_id%TYPE;
	v_max_name_length	NUMBER:= 250;
BEGIN

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_rollout_test_compliance_item_id,
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_reference_code				=>	'refcode',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lk',
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		--in_major_version				=>	compliance_item.major_version%TYPE DEFAULT 1,
		--in_minor_version				=>	compliance_item.major_version%TYPE DEFAULT 0,
		--in_is_major_change				=>	compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
		in_is_first_publication			=>	1, -- avoid creating hist
		in_source						=>	0, --compliance_item_source "userDefined",
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REQUIREMENT,
		in_lang_id						=>	53 -- english compliance_language.lang_id%TYPE DEFAULT NULL
	);

	compliance_pkg.CreateFlowItem(
		in_compliance_item_id			=>	v_rollout_test_compliance_item_id,
		in_region_sid					=>	v_regs(1),
		out_flow_item_id				=>	v_flow_item_id
	);

	unit_test_pkg.AssertIsTrue(v_flow_item_id IS NOT NULL, 'missing flow item');

	csr.role_pkg.SetRole('COMPLIANCE_ROLE_1', 'COMPLIANCE_ROLE_1', v_role_1_sid);


	-- One
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(1));
	compliance_pkg.INT_UpdateTempCompLevels(
		in_role_sid => v_role_1_sid,
		in_search => NULL
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_comp_region_lvl_ids;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	FOR r in (SELECT * FROM temp_comp_region_lvl_ids)
	LOOP
		unit_test_pkg.AssertIsTrue(r.region_sid = v_regs(1), 'Expected region'||v_regs(1)||' - '||r.region_sid||' found.');
		unit_test_pkg.AssertIsTrue(r.region_description = 'Compliance_Region1', 'Expected region Compliance_Region1'||' - '||r.region_description||' found.');
		unit_test_pkg.AssertIsTrue(r.mgr_full_name = 'Compliance_USER_1', 'Expected name Compliance_USER_1'||' - '||r.mgr_full_name||' found.');
	END LOOP;

	DELETE FROM temp_comp_region_lvl_ids;
	
	-- Many
	v_users(2) := csr.unit_test_pkg.GetOrCreateUser('Compliance_USER_2');
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(2));
	compliance_pkg.INT_UpdateTempCompLevels(
		in_role_sid => v_role_1_sid,
		in_search => NULL
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_comp_region_lvl_ids;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	FOR r in (SELECT * FROM temp_comp_region_lvl_ids)
	LOOP
		unit_test_pkg.AssertIsTrue(r.region_sid = v_regs(1), 'Expected region'||v_regs(1)||' - '||r.region_sid||' found.');
		unit_test_pkg.AssertIsTrue(r.region_description = 'Compliance_Region1', 'Expected region Compliance_Region1'||' - '||r.region_description||' found.');
		unit_test_pkg.AssertIsTrue(r.mgr_full_name = 'Compliance_USER_1, Compliance_USER_2', 'Expected name Compliance_USER_1, Compliance_USER_2'||' - '||r.mgr_full_name||' found.');
	END LOOP;

	DELETE FROM temp_comp_region_lvl_ids;
	
	-- overflow
	v_users(3) := csr.unit_test_pkg.GetOrCreateUser('Compliance_USER_3_VeryLongNameXX_1234567890123456789012345678901234567890');
	v_users(4) := csr.unit_test_pkg.GetOrCreateUser('Compliance_USER_4_VeryLongNameXX_1234567890123456789012345678901234567890');
	v_users(5) := csr.unit_test_pkg.GetOrCreateUser('Compliance_USER_5_VeryLongNameXX_1234567890123456789012345678901234567890');
	v_users(6) := csr.unit_test_pkg.GetOrCreateUser('Compliance_USER_6_OverTheEdge');
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(3));
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(4));
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(5));
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(6));
	compliance_pkg.INT_UpdateTempCompLevels(
		in_role_sid => v_role_1_sid,
		in_search => NULL
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_comp_region_lvl_ids;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	FOR r in (SELECT * FROM temp_comp_region_lvl_ids)
	LOOP
		unit_test_pkg.AssertIsTrue(r.region_sid = v_regs(1), 'Expected region'||v_regs(1)||' - '||r.region_sid||' found.');
		unit_test_pkg.AssertIsTrue(r.region_description = 'Compliance_Region1', 'Expected region Compliance_Region1'||' - '||r.region_description||' found.');
		unit_test_pkg.AssertIsTrue(LENGTH(r.mgr_full_name) = v_max_name_length + 3,
			 'Expected truncated length'||' - '||LENGTH(r.mgr_full_name)||' found.');
		unit_test_pkg.AssertIsTrue(SUBSTR(r.mgr_full_name, v_max_name_length + 1) = '...',
			 'Expected truncated str'||' - '||SUBSTR(r.mgr_full_name, v_max_name_length + 1)||' found.');
	END LOOP;

END;

PROCEDURE TestCreateRolloutInfo
AS
	v_tag_group_id				security.security_pkg.T_SID_ID;
	v_tag_id					security.security_pkg.T_SID_ID;
	v_tags						security.security_pkg.T_SID_IDS;
	v_regions					security.security_pkg.T_SID_IDS;
	v_count						NUMBER;
BEGIN
	csr.tag_pkg.CreateTagGroup(
		in_name							=> 'Group',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> 'GRP',
		out_tag_group_id				=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'Tag',
		in_pos					=> 1,
		in_lookup_key			=> 'TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	v_tags(1) := v_tag_id;
	
dbms_output.put_line('v_rollout_test_compliance_item_id='||v_rollout_test_compliance_item_id);

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_rollout_test_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'us',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_tags,
		in_rollout_regionsids		=> v_regions
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_rollout_test_compliance_item_id
	   AND tag_id = v_tag_id;
	   
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');
END;

PROCEDURE TestUpdateRegulationFailsWhenDuplicateVers
AS
BEGIN
	-- Insert some test data
	compliance_pkg.CreateRegulation(
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_source						=>	1, --compliance_item_source "Enhesa",
		in_reference_code				=>	'refcode',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lookup',
		in_external_id					=>  1,
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		in_major_version				=>	1,
		in_minor_version				=>	0,
		in_is_major_change				=>	1,
		in_is_first_publication			=>  1,
		in_adoption_dtm					=>  '01-JAN-10',
		out_compliance_item_id			=>  v_comp_item_id
	);
	
	compliance_pkg.UpdateRegulation(
		in_compliance_item_id			=>  v_comp_item_id,
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_source						=>	1, --compliance_item_source "Enhesa",
		in_reference_code				=>	'refcode',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_adoption_dtm					=>  '01-JAN-10',
		in_external_id					=>  1,
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lookup',
		in_major_version				=>	1,
		in_minor_version				=>	1,
		in_is_major_change				=>	0,
		in_change_reason				=>  'test',
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		in_is_first_publication			=>  0
	);
	
	compliance_pkg.UpdateRegulation(
		in_compliance_item_id			=>  v_comp_item_id,
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_source						=>	1, --compliance_item_source "Enhesa",
		in_reference_code				=>	'refcode',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_adoption_dtm					=>  '01-JAN-10',
		in_external_id					=>  1,
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lookup',
		in_major_version				=>	1,
		in_minor_version				=>	99,
		in_is_major_change				=>	0,
		in_change_reason				=>  'test',
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		in_is_first_publication			=>  0
	);

	BEGIN
		compliance_pkg.UpdateRegulation(
			in_compliance_item_id			=>  v_comp_item_id,
			in_title						=>	'Compliancetitle',
			in_summary						=>	'Compliancesummary',
			in_details						=>	'Compliancedetails',
			in_source						=>	1, --compliance_item_source "Enhesa",
			in_reference_code				=>	'refcode',
			in_user_comment					=>	'uc',
			in_citation						=>	'citation',
			in_external_link				=>	'link',
			in_adoption_dtm					=>  '01-JAN-10',
			in_external_id					=>  1,
			in_status_id 					=>	2, -- compliance_item_status "Published"
			in_lookup_key					=>	'lookup',
			in_major_version				=>	1,
			in_minor_version				=>	1,
			in_is_major_change				=>	0,
			in_change_reason				=>  'test',
			in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
			in_is_first_publication			=>  0
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		WHEN OTHERS THEN
			RAISE;
	END;
END;

PROCEDURE TestClearingVersionHistoryWorksForReg
AS
	v_count		NUMBER;
BEGIN
	-- Insert some test data

	compliance_pkg.UNSEC_DeleteComplianceItemHistory(v_comp_item_id);

	BEGIN
		compliance_pkg.UpdateRegulation(
			in_compliance_item_id			=>  v_comp_item_id,
			in_title						=>	'Compliancetitle',
			in_summary						=>	'Compliancesummary',
			in_details						=>	'Compliancedetails',
			in_source						=>	1, --compliance_item_source "Enhesa",
			in_reference_code				=>	'refcode',
			in_user_comment					=>	'uc',
			in_citation						=>	'citation',
			in_external_link				=>	'link',
			in_adoption_dtm					=>  '01-JAN-10',
			in_external_id					=>  1,
			in_status_id 					=>	2, -- compliance_item_status "Published"
			in_lookup_key					=>	'lookup',
			in_major_version				=>	1,
			in_minor_version				=>	1,
			in_is_major_change				=>	0,
			in_change_reason				=>  'test',
			in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
			in_is_first_publication			=>  0
		);
		v_count := 1;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE;
	END;
	
	IF v_count = 0 THEN
		unit_test_pkg.TestFail('Regulation updated with a duplicate version compliance item version log');
	END IF;
END;

PROCEDURE TestUpdateRequirementFailsWhenDuplicateVers
AS
BEGIN
	-- Insert some test data
	compliance_pkg.CreateRequirement(
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_source						=>	1, --compliance_item_source "Enhesa",
		in_reference_code				=>	'refcode2',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lookup2',
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		in_major_version				=>	1,
		in_minor_version				=>	0,
		in_is_major_change				=>	1,
		in_is_first_publication			=>  1,
		out_compliance_item_id			=>  v_comp_item_id_2
	);
		
	compliance_pkg.UpdateRequirement(
		in_compliance_item_id			=>  v_comp_item_id_2,
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_source						=>	1, --compliance_item_source "Enhesa",
		in_reference_code				=>	'refcode2',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lookup2',
		in_major_version				=>	1,
		in_minor_version				=>	1,
		in_is_major_change				=>	0,
		in_change_reason				=>  'test',
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		in_is_first_publication			=>  0
	);
	
	compliance_pkg.UpdateRequirement(
		in_compliance_item_id			=>  v_comp_item_id_2,
		in_title						=>	'Compliancetitle',
		in_summary						=>	'Compliancesummary',
		in_details						=>	'Compliancedetails',
		in_source						=>	1, --compliance_item_source "Enhesa",
		in_reference_code				=>	'refcode2',
		in_user_comment					=>	'uc',
		in_citation						=>	'citation',
		in_external_link				=>	'link',
		in_status_id 					=>	2, -- compliance_item_status "Published"
		in_lookup_key					=>	'lookup2',
		in_major_version				=>	1,
		in_minor_version				=>	99,
		in_is_major_change				=>	0,
		in_change_reason				=>  'test',
		in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
		in_is_first_publication			=>  0
	);

	BEGIN
		compliance_pkg.UpdateRequirement(
			in_compliance_item_id			=>  v_comp_item_id_2,
			in_title						=>	'Compliancetitle',
			in_summary						=>	'Compliancesummary',
			in_details						=>	'Compliancedetails',
			in_source						=>	1, --compliance_item_source "Enhesa",
			in_reference_code				=>	'refcode2',
			in_user_comment					=>	'uc',
			in_citation						=>	'citation',
			in_external_link				=>	'link',
			in_status_id 					=>	2, -- compliance_item_status "Published"
			in_lookup_key					=>	'lookup2',
			in_major_version				=>	1,
			in_minor_version				=>	1,
			in_is_major_change				=>	0,
			in_change_reason				=>  'test',
			in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
			in_is_first_publication			=>  0
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		WHEN OTHERS THEN
			RAISE;
	END;
END;

PROCEDURE TestClearingVersionHistoryWorksForReq
AS
	v_count		NUMBER;
BEGIN
	-- Insert some test data

	compliance_pkg.UNSEC_DeleteComplianceItemHistory(v_comp_item_id_2);

	BEGIN
		compliance_pkg.UpdateRequirement(
			in_compliance_item_id			=>  v_comp_item_id_2,
			in_title						=>	'Compliancetitle',
			in_summary						=>	'Compliancesummary',
			in_details						=>	'Compliancedetails',
			in_source						=>	1, --compliance_item_source "Enhesa",
			in_reference_code				=>	'refcode2',
			in_user_comment					=>	'uc',
			in_citation						=>	'citation',
			in_external_link				=>	'link',
			in_status_id 					=>	2, -- compliance_item_status "Published"
			in_lookup_key					=>	'lookup2',
			in_major_version				=>	1,
			in_minor_version				=>	1,
			in_is_major_change				=>	0,
			in_change_reason				=>  'test',
			in_change_type					=>	1, --COMPLIANCE_ITEM_CHANGE_TYPE "NoChange"
			in_is_first_publication			=>  0
		);
		v_count := 1;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE;
	END;
	
	IF v_count = 0 THEN
		unit_test_pkg.TestFail('Requirement updated with a duplicate version compliance item version log');
	END IF;
END;

PROCEDURE TestSingleTagWithSingleExclusion
AS
	v_tag_group_id					security.security_pkg.T_SID_ID;
	v_tag_id						security.security_pkg.T_SID_ID;
	v_tags							security.security_pkg.T_SID_IDS;
	v_excluded_tags					security.security_pkg.T_SID_IDS;
	v_regions						security.security_pkg.T_SID_IDS;
	v_first_compliance_item_id		NUMBER;
	v_second_compliance_item_id		NUMBER;
	v_count							NUMBER;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_items_to_process				security.T_SID_TABLE;
	v_rollout_regions				security.T_SID_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
BEGIN
	unit_test_pkg.StartTest('csr.compliance_pkg.TestSingleTagWithSingleExclusion');
	
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	enable_pkg.EnableCompliance('Y', 'Y', 'N');

	UPDATE csr.compliance_options
	   SET rollout_option = 1
	 WHERE app_sid = v_app_sid;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('RolloutCompliance_RootRegion');
	
	INSERT INTO csr.compliance_root_regions 
			(app_sid, region_sid, region_type,rollout_level)
	VALUES 	(v_app_sid, v_regs(1), 0, 0);

	SELECT NVL(MAX(compliance_item_id), 0)
	  INTO v_first_compliance_item_id
	  FROM compliance_item_rollout;

	v_first_compliance_item_id := compliance_item_seq.NEXTVAL + 1;
	v_second_compliance_item_id := v_first_compliance_item_id + 1;
	dbms_output.put_line('v_first_compliance_item_id='||v_first_compliance_item_id);

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_first_compliance_item_id,
		in_title						=>	'FirstRolloutComplianceItemTitle',
		in_summary						=>	'FirstRolloutComplianceItemSummary',
		in_details						=>	'FirstRolloutComplianceItemDetails',
		in_reference_code				=>	'FirstRolloutComplianceItemRefcode',
		in_user_comment					=>	'FirstRolloutComplianceItemComment',
		in_citation						=>	'FirstRolloutComplianceItemCitation',
		in_external_link				=>	'FirstRolloutComplianceItemLink',
		in_status_id 					=>	2,
		in_lookup_key					=>	'FirstRolloutComplianceItemLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_second_compliance_item_id,
		in_title						=>	'ComplianceItemTitle',
		in_summary						=>	'ComplianceItemSummary',
		in_details						=>	'ComplianceItemDetails',
		in_reference_code				=>	'ComplianceItemRefcode',
		in_user_comment					=>	'ComplianceItemComment',
		in_citation						=>	'ComplianceItemCitation',
		in_external_link				=>	'ComplianceItemLink',
		in_status_id 					=>	 2, 
		in_lookup_key					=>	'ComplianceItemLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);

	csr.tag_pkg.CreateTagGroup(
		in_name							=> 'RolloutComplianceItemGroup',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> 'RolloutComplianceItemGRP',
		out_tag_group_id				=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceTagItem',
		in_pos					=> 1,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	v_tags(1) := v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceTagItem2',
		in_pos					=> 2,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	v_excluded_tags(1) := v_tag_id;
	
	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_first_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_tags,
		in_rollout_regionsids		=> v_regions
	);

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_second_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_excluded_tags,
		in_rollout_regionsids		=> v_regions
	);

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_first_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_second_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_first_compliance_item_id);

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_second_compliance_item_id);

	INSERT INTO compliance_region_tag   -- List used to filter excluded tags
			(tag_id,region_sid)
	VALUES	(v_excluded_tags(1), v_regs(1));

	UPDATE compliance_item_rollout
	   SET rollout_pending = 1,
	       rollout_dtm =  (sysdate - 1)
	 WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id) 
	   AND app_sid = v_app_sid;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_first_compliance_item_id
	   AND tag_id = v_tags(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_second_compliance_item_id
	   AND tag_id = v_excluded_tags(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

    SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item_rollout cir
	  JOIN (SELECT ncir.compliance_item_id
			  FROM compliance_item_rollout ncir
			  JOIN compliance_item ci ON ncir.app_sid = ci.app_sid AND ncir.compliance_item_id = ci.compliance_item_id
			 WHERE ncir.rollout_pending = 1
			   AND ncir.rollout_dtm <= sysdate 
			   AND ncir.suppress_rollout = 0
			   AND ci.compliance_item_status_id = 2
			 ORDER BY is_federal_req) ordered
		ON cir.compliance_item_id = ordered.compliance_item_id
	WHERE  ROWNUM <= 500;

	SELECT v_regs(1)
	  BULK COLLECT INTO v_rollout_regions
	  FROM DUAL;

	csr.compliance_pkg.FilterRolloutItems(
		in_items_to_process			 => v_items_to_process,
		in_rollout_regions			 => v_rollout_regions,
		out_filtered_rollout_items	 => v_filtered_rollout_items
	);	

	unit_test_pkg.AssertAreEqual(1 , v_filtered_rollout_items.Count, 'Compliance Item with excluded tags should be filtered');
	
	unit_test_pkg.AssertAreEqual(v_first_compliance_item_id , v_filtered_rollout_items(1).compliance_item_id, 
								'Compliance Item with non-excluded tags should be returned');

	unit_test_pkg.AssertAreEqual(v_regs(1) , v_filtered_rollout_items(1).region_sid,
								'Compliance Item should belong to correct region');
	--Clean-up
	  DELETE FROM compliance_rollout_regions WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_regulation WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_item_description WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_tag WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_region WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_rollout WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_region_tag WHERE region_sid = v_regs(1) AND app_sid = v_app_sid;
	  DELETE FROM compliance_root_regions WHERE app_sid = v_app_sid;
END;

PROCEDURE TestSingleTagWithNoExclusion
AS
	v_tag_group_id					security.security_pkg.T_SID_ID;
	v_tag_id						security.security_pkg.T_SID_ID;
	v_tags							security.security_pkg.T_SID_IDS;
	v_excluded_tags					security.security_pkg.T_SID_IDS;
	v_regions						security.security_pkg.T_SID_IDS;
	v_first_compliance_item_id		NUMBER;
	v_second_compliance_item_id		NUMBER;
	v_count							NUMBER;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_items_to_process				security.T_SID_TABLE;
	v_rollout_regions				security.T_SID_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
BEGIN
	unit_test_pkg.StartTest('csr.compliance_pkg.TestSingleTagWithNoExclusion');
	
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := sys_context('SECURITY','ACT');

	enable_pkg.EnableCompliance('Y', 'Y', 'N');

	UPDATE csr.compliance_options
	   SET rollout_option = 1
	 WHERE app_sid = v_app_sid;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('RolloutComplianceRootRegion');
	
	INSERT INTO csr.compliance_root_regions 
			(app_sid, region_sid, region_type,rollout_level)
	VALUES 	(v_app_sid, v_regs(1), 0, 0);

	v_first_compliance_item_id := compliance_item_seq.NEXTVAL + 1;
	v_second_compliance_item_id := v_first_compliance_item_id + 1;
	

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_first_compliance_item_id,
		in_title						=>	'FirstRolloutComplianceItemTitle',
		in_summary						=>	'FirstRolloutComplianceItemSummary',
		in_details						=>	'FirstRolloutComplianceItemDetails',
		in_reference_code				=>	'FirstRolloutComplianceItemRefcode',
		in_user_comment					=>	'FirstRolloutComplianceItemComment',
		in_citation						=>	'FirstRolloutComplianceItemCitation',
		in_external_link				=>	'FirstRolloutComplianceItemLink',
		in_status_id 					=>	2,
		in_lookup_key					=>	'FirstRolloutComplianceItemLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_second_compliance_item_id,
		in_title						=>	'ComplianceItemTitle',
		in_summary						=>	'ComplianceItemSummary',
		in_details						=>	'ComplianceItemDetails',
		in_reference_code				=>	'ComplianceItemRefcode',
		in_user_comment					=>	'ComplianceItemComment',
		in_citation						=>	'ComplianceItemCitation',
		in_external_link				=>	'ComplianceItemLink',
		in_status_id 					=>	 2, 
		in_lookup_key					=>	'ComplianceItemLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);


	csr.tag_pkg.CreateTagGroup(
		in_name							=> 'RolloutComplianceItemGroupWithExcludedTags',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> 'RolloutComplianceItemGRPWithExcludedTags',
		out_tag_group_id				=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceNonExcludedTagItem',
		in_pos					=> 1,
		in_lookup_key			=> 'NON_EXCLUDED_LOOKUP_KEY',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	v_tags(1) := v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutCompliancExcludedTagItem',
		in_pos					=> 2,
		in_lookup_key			=> 'EXCLUDED_LOOKUP_KEY',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	v_excluded_tags(1) := v_tag_id;
	
	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_first_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_tags,
		in_rollout_regionsids		=> v_regions
	);

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_second_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_tags,
		in_rollout_regionsids		=> v_regions
	);

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_first_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_second_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_first_compliance_item_id);

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_second_compliance_item_id);

	INSERT INTO compliance_region_tag   -- List used to filter excluded tags
			(tag_id,region_sid)
	VALUES	(v_excluded_tags(1), v_regs(1));

	UPDATE compliance_item_rollout
	   SET rollout_pending = 1,
	       rollout_dtm =  (sysdate - 1)
	 WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id) 
	   AND app_sid = v_app_sid;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_first_compliance_item_id
	   AND tag_id = v_tags(1);
	   
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_second_compliance_item_id
	   AND tag_id = v_tags(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

    SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item_rollout cir
	  JOIN (SELECT ncir.compliance_item_id
			  FROM compliance_item_rollout ncir
			  JOIN compliance_item ci ON ncir.app_sid = ci.app_sid AND ncir.compliance_item_id = ci.compliance_item_id
			 WHERE ncir.rollout_pending = 1
			   AND ncir.rollout_dtm <= sysdate 
			   AND ncir.suppress_rollout = 0
			   AND ci.compliance_item_status_id = 2
			 ORDER BY is_federal_req) ordered
		ON cir.compliance_item_id = ordered.compliance_item_id
	WHERE  ROWNUM <= 500;

	SELECT v_regs(1)
	  BULK COLLECT INTO v_rollout_regions
	  FROM DUAL;

	csr.compliance_pkg.FilterRolloutItems(
		in_items_to_process			 => v_items_to_process,
		in_rollout_regions			 => v_rollout_regions,
		out_filtered_rollout_items	 => v_filtered_rollout_items
	);

	unit_test_pkg.AssertAreEqual(2, v_filtered_rollout_items.Count, 'Compliance Item with excluded tags should be filtered');

	unit_test_pkg.AssertAreEqual(v_first_compliance_item_id , v_filtered_rollout_items(1).compliance_item_id, 
								'Compliance Item with non-excluded tags should be returned');
	unit_test_pkg.AssertAreEqual(v_second_compliance_item_id , v_filtered_rollout_items(2).compliance_item_id, 
								'Compliance Item with non-excluded tags should be returned');

	unit_test_pkg.AssertAreEqual(v_regs(1) , v_filtered_rollout_items(1).region_sid, 
								'First Compliance Item should belong to the correct region');
	unit_test_pkg.AssertAreEqual(v_regs(1) , v_filtered_rollout_items(2).region_sid, 
								'Second Compliance Item should belong to the correct region');

	--Clean-up
	  DELETE FROM compliance_rollout_regions WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_regulation WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_item_description WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_tag WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_region WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_rollout WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_region_tag WHERE region_sid = v_regs(1) AND app_sid = v_app_sid;
	  DELETE FROM compliance_root_regions WHERE app_sid = v_app_sid;
END;

PROCEDURE TestMultipleTagsWithSomeExclusion
AS
	v_tag_group_id					security.security_pkg.T_SID_ID;
	v_tag_id						security.security_pkg.T_SID_ID;
	v_single_tag_list				security.security_pkg.T_SID_IDS;
	v_multi_tag_list				security.security_pkg.T_SID_IDS;
	v_excluded_tags					security.security_pkg.T_SID_IDS;
	v_regions						security.security_pkg.T_SID_IDS;
	v_first_compliance_item_id		NUMBER;
	v_second_compliance_item_id		NUMBER;
	v_count							NUMBER;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_items_to_process				security.T_SID_TABLE;
	v_rollout_regions				security.T_SID_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
BEGIN
	unit_test_pkg.StartTest('csr.compliance_pkg.TestMultipleTagsWithSomeExclusion');
	
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	enable_pkg.EnableCompliance('Y', 'Y', 'N');

	UPDATE csr.compliance_options
	   SET rollout_option = 1
	 WHERE app_sid = v_app_sid;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('RolloutCompliance_RootRegion');
	
	INSERT INTO csr.compliance_root_regions 
			(app_sid, region_sid, region_type,rollout_level)
	VALUES 	(v_app_sid, v_regs(1), 0, 0);

	v_first_compliance_item_id := compliance_item_seq.NEXTVAL + 1;
	v_second_compliance_item_id := v_first_compliance_item_id + 1;

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_first_compliance_item_id,
		in_title						=>	'ComplianceItemTitleWithSingleTag',
		in_summary						=>	'ComplianceItemSummaryWithSingleTag',
		in_details						=>	'ComplianceItemDetailsWithSingleTag',
		in_reference_code				=>	'ComplianceItemRefcodeWithSingleTag',
		in_user_comment					=>	'ComplianceItemCommentWithSingleTag',
		in_citation						=>	'ComplianceItemCitatioWithSingleTag',
		in_external_link				=>	'ComplianceItemLinkWithSingleTag',
		in_status_id 					=>	2,
		in_lookup_key					=>	'ComplianceItemWithSingleTagLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_second_compliance_item_id,
		in_title						=>	'ComplianceItemTitleWithMultiTags',
		in_summary						=>	'ComplianceItemSummaryWithMultiTags',
		in_details						=>	'ComplianceItemDetailsWithMultiTags',
		in_reference_code				=>	'ComplianceItemRefcodeWithMultiTags',
		in_user_comment					=>	'ComplianceItemCommentWithMultiTags',
		in_citation						=>	'ComplianceItemCitationWithMultiTags',
		in_external_link				=>	'ComplianceItemLinkWithMultiTags',
		in_status_id 					=>	2, 
		in_lookup_key					=>	'ComplianceItemWithMultiTagsLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);

	csr.tag_pkg.CreateTagGroup(
		in_name							=> 'RolloutComplianceItemGroup',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> 'RolloutComplianceItemGRP',
		out_tag_group_id				=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceTagFirstItem',
		in_pos					=> 1,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	v_single_tag_list(1) := v_tag_id;
	v_multi_tag_list(1):= v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceTagSecondItem',
		in_pos					=> 2,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);	

	v_multi_tag_list(2):= v_tag_id;
	v_excluded_tags(1) := v_tag_id;

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_first_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_single_tag_list,
		in_rollout_regionsids		=> v_regions
	);

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_second_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_multi_tag_list,
		in_rollout_regionsids		=> v_regions
	);

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_first_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_second_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_first_compliance_item_id);

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_second_compliance_item_id);

	INSERT INTO compliance_region_tag   -- List used to filter excluded tags
			(tag_id,region_sid)
	VALUES	(v_excluded_tags(1), v_regs(1));

	UPDATE compliance_item_rollout
	   SET rollout_pending = 1,
	       rollout_dtm = (sysdate - 1)
	 WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id) 
	   AND app_sid = v_app_sid;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_first_compliance_item_id
	   AND tag_id = v_single_tag_list(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_second_compliance_item_id
	   AND tag_id = v_multi_tag_list(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

    SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item_rollout cir
	  JOIN (SELECT ncir.compliance_item_id
			  FROM compliance_item_rollout ncir
			  JOIN compliance_item ci ON ncir.app_sid = ci.app_sid AND ncir.compliance_item_id = ci.compliance_item_id
			 WHERE ncir.rollout_pending = 1
			   AND ncir.rollout_dtm <= sysdate 
			   AND ncir.suppress_rollout = 0
			   AND ci.compliance_item_status_id = 2
			 ORDER BY is_federal_req) ordered
		ON cir.compliance_item_id = ordered.compliance_item_id
	WHERE  ROWNUM <= 500;

	SELECT v_regs(1)
	  BULK COLLECT INTO v_rollout_regions
	  FROM DUAL;

	csr.compliance_pkg.FilterRolloutItems(
		in_items_to_process			 => v_items_to_process,
		in_rollout_regions			 => v_rollout_regions,
		out_filtered_rollout_items	 => v_filtered_rollout_items
	);	

	unit_test_pkg.AssertAreEqual(2 , v_filtered_rollout_items.Count, 'Only Compliance Item with All excluded tags should be filtered');
	
	unit_test_pkg.AssertAreEqual(v_first_compliance_item_id , v_filtered_rollout_items(1).compliance_item_id, 
								'Compliance Item should be returned since not all of its tags are excluded');
	unit_test_pkg.AssertAreEqual(v_second_compliance_item_id , v_filtered_rollout_items(2).compliance_item_id, 
								'Compliance Item should be returned since not all of its tags are excluded');

	unit_test_pkg.AssertAreEqual(v_regs(1) , v_filtered_rollout_items(1).region_sid, 
								'First Compliance Item should belong to the correct region');
	unit_test_pkg.AssertAreEqual(v_regs(1) , v_filtered_rollout_items(2).region_sid, 
								'Second Compliance Item should belong to the correct region');

	--Clean-up
	  DELETE FROM compliance_rollout_regions WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_regulation WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_item_tag WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_region WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item_rollout WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_item WHERE compliance_item_id IN (v_first_compliance_item_id, v_second_compliance_item_id);
	  DELETE FROM compliance_region_tag WHERE region_sid = v_regs(1) AND app_sid = v_app_sid;
	  DELETE FROM compliance_root_regions WHERE app_sid = v_app_sid;
END;

PROCEDURE TestMultipleTagsWithAllExclusion
AS
	v_tag_group_id					security.security_pkg.T_SID_ID;
	v_tag_id						security.security_pkg.T_SID_ID;
	v_tags							security.security_pkg.T_SID_IDS;
	v_regions						security.security_pkg.T_SID_IDS;
	v_compliance_item_id			NUMBER;
	v_count							NUMBER;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_items_to_process				security.T_SID_TABLE;
	v_rollout_regions				security.T_SID_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
BEGIN
	unit_test_pkg.StartTest('csr.compliance_pkg.TestMultipleTagsWithAllExclusion');
	
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	enable_pkg.EnableCompliance('Y', 'Y', 'N');

	UPDATE csr.compliance_options
	   SET rollout_option = 1
	 WHERE app_sid = v_app_sid;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('RolloutCompliance_RootRegion');
	
	INSERT INTO csr.compliance_root_regions 
			(app_sid, region_sid, region_type,rollout_level)
	VALUES 	(v_app_sid, v_regs(1), 0, 0);

	v_compliance_item_id := compliance_item_seq.NEXTVAL + 2;

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_compliance_item_id,
		in_title						=>	'ComplianceItemTitleWithManyTags',
		in_summary						=>	'ComplianceItemSummaryWithManyTags',
		in_details						=>	'ComplianceItemDetailsWithManyTags',
		in_reference_code				=>	'ComplianceItemRefcodeWithManyTags',
		in_user_comment					=>	'ComplianceItemCommentWithManyTags',
		in_citation						=>	'ComplianceItemCitatioWithManyTags',
		in_external_link				=>	'ComplianceItemLinkWithManyTags',
		in_status_id 					=>	2,
		in_lookup_key					=>	'ComplianceItemWithManyTagsLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REGULATION,
		in_lang_id						=>	53
	);

	csr.tag_pkg.CreateTagGroup(
		in_name							=> 'RolloutComplianceItemGroup',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> 'RolloutComplianceItemGRP',
		out_tag_group_id				=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceFirstTagItem',
		in_pos					=> 1,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	v_tags(1) := v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceSecondTagItem',
		in_pos					=> 2,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);	

	v_tags(2):= v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceThirdTagItem',
		in_pos					=> 3,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_3',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);	

	v_tags(3):= v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceFourthTagItem',
		in_pos					=> 4,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_4',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);	

	v_tags(4):= v_tag_id;

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_tags,
		in_rollout_regionsids		=> v_regions
	);


	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_compliance_item_id, v_regs(1));

	INSERT INTO csr.compliance_regulation
			(compliance_item_id)
	VALUES  (v_compliance_item_id);

	 -- List used to filter excluded tags
	INSERT INTO compliance_region_tag (tag_id,region_sid) VALUES (v_tags(1), v_regs(1));
	INSERT INTO compliance_region_tag (tag_id,region_sid) VALUES (v_tags(2), v_regs(1));
	INSERT INTO compliance_region_tag (tag_id,region_sid) VALUES (v_tags(3), v_regs(1));
	INSERT INTO compliance_region_tag (tag_id,region_sid) VALUES (v_tags(4), v_regs(1));


	UPDATE compliance_item_rollout
	   SET rollout_pending = 1,
	       rollout_dtm = (sysdate - 1)
	 WHERE compliance_item_id IN (v_compliance_item_id) 
	   AND app_sid = v_app_sid;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_compliance_item_id
	   AND tag_id = v_tags(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_compliance_item_id
	   AND tag_id = v_tags(4);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

    SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item_rollout cir
	  JOIN (SELECT ncir.compliance_item_id
			  FROM compliance_item_rollout ncir
			  JOIN compliance_item ci ON ncir.app_sid = ci.app_sid AND ncir.compliance_item_id = ci.compliance_item_id
			 WHERE ncir.rollout_pending = 1
			   AND ncir.rollout_dtm <= sysdate 
			   AND ncir.suppress_rollout = 0
			   AND ci.compliance_item_status_id = 2
			 ORDER BY is_federal_req) ordered
		ON cir.compliance_item_id = ordered.compliance_item_id
	WHERE  ROWNUM <= 500;

	SELECT v_regs(1)
	  BULK COLLECT INTO v_rollout_regions
	  FROM DUAL;

	csr.compliance_pkg.FilterRolloutItems(
		in_items_to_process			 => v_items_to_process,
		in_rollout_regions			 => v_rollout_regions,
		out_filtered_rollout_items	 => v_filtered_rollout_items
	);

	unit_test_pkg.AssertAreEqual(0 , v_filtered_rollout_items.Count, 'Compliance Item Should be filtered since all tags are excluded');
	
	--Clean-up
	  DELETE FROM compliance_rollout_regions WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_regulation WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_item_tag WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_item_region WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_item_rollout WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_item WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_region_tag WHERE region_sid = v_regs(1) AND app_sid = v_app_sid;
	  DELETE FROM compliance_root_regions WHERE app_sid = v_app_sid;
END;

PROCEDURE TestRequirementWithSingleExclusion
AS
	v_tag_group_id					security.security_pkg.T_SID_ID;
	v_tag_id						security.security_pkg.T_SID_ID;
	v_tags							security.security_pkg.T_SID_IDS;
	v_excluded_tags					security.security_pkg.T_SID_IDS;
	v_regions						security.security_pkg.T_SID_IDS;
	v_compliance_item_id			NUMBER;
	v_count							NUMBER;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_items_to_process				security.T_SID_TABLE;
	v_rollout_regions				security.T_SID_TABLE;
	v_filtered_rollout_items		T_COMPLIANCE_ROLLOUT_TABLE;
BEGIN
	unit_test_pkg.StartTest('csr.compliance_pkg.TestRequirementWithSingleExclusion');
	
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	enable_pkg.EnableCompliance('Y', 'Y', 'N');

	UPDATE csr.compliance_options
	   SET rollout_option = 1
	 WHERE app_sid = v_app_sid;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('RolloutComplianceRootRegion');
	
	INSERT INTO csr.compliance_root_regions 
			(app_sid, region_sid, region_type,rollout_level)
	VALUES 	(v_app_sid, v_regs(1), 0, 0);	

	v_compliance_item_id := compliance_item_seq.NEXTVAL + 2;

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	v_compliance_item_id,
		in_title						=>	'ComplianceItemRequirementTitle',
		in_summary						=>	'ComplianceItemRequirementSummary',
		in_details						=>	'ComplianceItemRequirementDetails',
		in_reference_code				=>	'ComplianceItemRequirementRefcode',
		in_user_comment					=>	'ComplianceItemRequirementComment',
		in_citation						=>	'ComplianceItemRequirementCitation',
		in_external_link				=>	'ComplianceItemRequirementLink',
		in_status_id 					=>	2,
		in_lookup_key					=>	'ComplianceItemRequirementLK',
		in_change_type					=>	1,
		in_is_first_publication			=>	1,
		in_source						=>	0,
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_REQUIREMENT,
		in_lang_id						=>	53
	);	

	INSERT INTO compliance_requirement (compliance_item_id)
	VALUES (v_compliance_item_id);

	csr.tag_pkg.CreateTagGroup(
		in_name							=> 'RolloutComplianceItemGroup',
		in_applies_to_non_comp			=> 1,
		in_lookup_key					=> 'RolloutComplianceItemGRP',
		out_tag_group_id				=> v_tag_group_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceTagItem',
		in_pos					=> 1,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);

	v_tags(1) := v_tag_id;

	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_tag_group_id,
		in_tag					=> 'RolloutComplianceTagItem2',
		in_pos					=> 2,
		in_lookup_key			=> 'ROLLOUT_TAG_LOOKUP_KEY_2',
		in_active				=> 1,
		out_tag_id				=> v_tag_id
	);
	
	v_tags(2) := v_tag_id;
	v_excluded_tags(1) := v_tag_id;

	csr.compliance_pkg.CreateRolloutInfo(
		in_compliance_item_id		=> v_compliance_item_id,
		in_source					=> compliance_pkg.SOURCE_ENHESA,
		in_major_version			=> 1,
		in_rollout_country			=> 'US',
		in_rollout_region			=> 'MA',
		in_rollout_country_group	=> NULL,
		in_rollout_region_group		=> NULL,
		in_rollout_tags				=> v_tags,
		in_rollout_regionsids		=> v_regions
	);

	INSERT INTO csr.compliance_rollout_regions
			(compliance_item_id, region_sid)
	VALUES  (v_compliance_item_id, v_regs(1));

	INSERT INTO compliance_region_tag   -- List used to filter excluded tags
			(tag_id,region_sid)
	VALUES	(v_excluded_tags(1), v_regs(1));

	UPDATE compliance_item_rollout
	   SET rollout_pending = 1,
	       rollout_dtm =  (sysdate - 1)
	 WHERE compliance_item_id IN (v_compliance_item_id) 
	   AND app_sid = v_app_sid;

	SELECT COUNT(*)
	  INTO v_count
	  FROM compliance_item_tag
	 WHERE compliance_item_id = v_compliance_item_id
	   AND tag_id = v_tags(1);

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 records'||' - '||v_count||' found.');

    SELECT cir.compliance_item_id
	  BULK COLLECT INTO v_items_to_process
	  FROM compliance_item_rollout cir
	  JOIN (SELECT ncir.compliance_item_id
			  FROM compliance_item_rollout ncir
			  JOIN compliance_item ci ON ncir.app_sid = ci.app_sid AND ncir.compliance_item_id = ci.compliance_item_id
			 WHERE ncir.rollout_pending = 1
			   AND ncir.rollout_dtm <= sysdate 
			   AND ncir.suppress_rollout = 0
			   AND ci.compliance_item_status_id = 2
			 ORDER BY is_federal_req) ordered
		ON cir.compliance_item_id = ordered.compliance_item_id
	WHERE  ROWNUM <= 500;

	SELECT v_regs(1)
	  BULK COLLECT INTO v_rollout_regions
	  FROM DUAL;

	csr.compliance_pkg.FilterRolloutItems(
		in_items_to_process			 => v_items_to_process,
		in_rollout_regions			 => v_rollout_regions,
		out_filtered_rollout_items	 => v_filtered_rollout_items
	);

	unit_test_pkg.AssertAreEqual(0 , v_filtered_rollout_items.Count, 'Compliance Item should be filtered even if single requirement is not met');

	--Clean-up
	  DELETE FROM compliance_rollout_regions WHERE app_sid = v_app_sid;
	  DELETE FROM compliance_item_tag WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_item_region WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_item_rollout WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_requirement WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_item WHERE compliance_item_id IN (v_compliance_item_id);
	  DELETE FROM compliance_region_tag WHERE region_sid = v_regs(1) AND app_sid = v_app_sid;
	  DELETE FROM compliance_root_regions WHERE app_sid = v_app_sid;
END;

END test_compliance_pkg;
/
