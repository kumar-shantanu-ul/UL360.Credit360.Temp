CREATE OR REPLACE PACKAGE BODY csr.test_permits_pkg AS

v_site_name					VARCHAR2(200);
v_regs						security_pkg.T_SID_IDS;
v_users						security_pkg.T_SID_IDS;
v_role_1_sid				security.security_pkg.T_SID_ID;

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

	DELETE FROM COMPLIANCE_REGULATION
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_permit_condition
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM COMPLIANCE_ITEM_ROLLOUT
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_item_description
	 WHERE app_sid = security_pkg.GetApp;

	DELETE FROM compliance_item_region
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


PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	TearDownCIData;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	security.user_pkg.logonadmin(v_site_name);

	TearDownCIData;
	RemoveSids(v_regs);
	RemoveSids(v_users);

	IF v_role_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_role_1_sid);
		v_role_1_sid := NULL;
	END IF;
END;

PROCEDURE SetUp
AS
BEGIN
	NULL;
END;

PROCEDURE TearDown AS
BEGIN
	NULL;
END;


PROCEDURE TestTempCompLevelsNone AS
	v_count	NUMBER;

	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_flow_item_id					compliance_item_region.flow_item_id%TYPE;
BEGIN
	permit_pkg.INT_UpdateTempCompLevels(
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
	-- Insert some test data

	csr_data_pkg.EnableCapability('System management');
	enable_pkg.EnableSurveys;
	enable_pkg.EnableCompliance('Y', 'Y', 'N');
	enable_pkg.EnablePermits;

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('Permits_Region1');
	v_users(1) := csr.unit_test_pkg.GetOrCreateUser('Permits_USER_1');

	compliance_pkg.INTERNAL_CreateComplianceItem(
		in_compliance_item_id			=>	1234,
		in_title						=>	'title',
		in_summary						=>	'summary',
		in_details						=>	'details',
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
		in_compliance_item_type			=>	compliance_pkg.COMPLIANCE_CONDITION,
		in_lang_id						=>	53 -- english compliance_language.lang_id%TYPE DEFAULT NULL
	);

	compliance_pkg.CreateFlowItem(
		in_compliance_item_id			=>	1234,
		in_region_sid					=>	v_regs(1),
		out_flow_item_id				=>	v_flow_item_id
	);

	unit_test_pkg.AssertIsTrue(v_flow_item_id IS NOT NULL, 'missing flow item');

	csr.role_pkg.SetRole('PERMITS_ROLE_1', 'PERMITS_ROLE_1', v_role_1_sid);


	-- One
	dbms_output.put_line(' Test one');
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(1));
	permit_pkg.INT_UpdateTempCompLevels(
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
		unit_test_pkg.AssertIsTrue(r.region_description = 'Permits_Region1', 'Expected region Permits_Region1'||' - '||r.region_description||' found.');
		unit_test_pkg.AssertIsTrue(r.mgr_full_name = 'Permits_USER_1', 'Expected name Permits_USER_1'||' - '||r.mgr_full_name||' found.');
	END LOOP;

	DELETE FROM temp_comp_region_lvl_ids;
	
	-- Many
	dbms_output.put_line(' Test many');

	v_users(2) := csr.unit_test_pkg.GetOrCreateUser('Permits_USER_2');
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(2));
	permit_pkg.INT_UpdateTempCompLevels(
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
		unit_test_pkg.AssertIsTrue(r.region_description = 'Permits_Region1', 'Expected region Permits_Region1'||' - '||r.region_description||' found.');
		unit_test_pkg.AssertIsTrue(r.mgr_full_name = 'Permits_USER_1, Permits_USER_2', 'Expected name Permits_USER_1, Permits_USER_2'||' - '||r.mgr_full_name||' found.');
	END LOOP;

	DELETE FROM temp_comp_region_lvl_ids;
	
	-- overflow
	dbms_output.put_line(' Test overflow');

	v_users(3) := csr.unit_test_pkg.GetOrCreateUser('Permits_USER_3_VeryLongNameXX_1234567890123456789012345678901234567890');
	v_users(4) := csr.unit_test_pkg.GetOrCreateUser('Permits_USER_4_VeryLongNameXX_1234567890123456789012345678901234567890');
	v_users(5) := csr.unit_test_pkg.GetOrCreateUser('Permits_USER_5_VeryLongNameXX_1234567890123456789012345678901234567890');
	v_users(6) := csr.unit_test_pkg.GetOrCreateUser('Permits_USER_6_OverTheEdge');
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(3));
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(4));
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(5));
	csr.role_pkg.AddRoleMemberForRegion(v_role_1_sid, v_regs(1), v_users(6));
	permit_pkg.INT_UpdateTempCompLevels(
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
		unit_test_pkg.AssertIsTrue(r.region_description = 'Permits_Region1', 'Expected region Permits_Region1'||' - '||r.region_description||' found.');
		unit_test_pkg.AssertIsTrue(LENGTH(r.mgr_full_name) = v_max_name_length + 3,
			 'Expected truncated length'||' - '||LENGTH(r.mgr_full_name)||' found.');
		unit_test_pkg.AssertIsTrue(SUBSTR(r.mgr_full_name, v_max_name_length + 1) = '...',
			 'Expected truncated str'||' - '||SUBSTR(r.mgr_full_name, v_max_name_length + 1)||' found.');
	END LOOP;

END;

END test_permits_pkg;
/
