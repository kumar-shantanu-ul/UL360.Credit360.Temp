CREATE OR REPLACE PACKAGE BODY csr.test_region_picker_pkg AS

v_tag_group					security_pkg.T_SID_ID;
v_tags						security_pkg.T_SID_IDS;
v_regs						security_pkg.T_SID_IDS;
v_parent_regs				security_pkg.T_SID_IDS;				

-- Region Tree
-- v_regs(1) PICKER_REGION_1 N
-- ----v_regs(2) PICKER_REGION_1_1 P
-- --------v_regs(3) PICKER_REGION_1_1_1 N
-- ----v_regs(4) PICKER_REGION_1_2 P TAGGED
-- ----v_regs(5) PICKER_REGION_1_3 N
-- --------v_regs(6) PICKER_REGION_1_3_1 TAGGED
-- ------------v_regs(7) PICKER_REGION_1_3_1_1
-- ------------v_regs(8) PICKER_REGION_1_3_1_2 P
-- v_regs(9) PICKER_REGION_2 N

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
	
	v_tag_group :=	unit_test_pkg.GetOrCreateTagGroup(
			in_lookup_key			=>	'RPTEST_TAG_GROUP_1',
			in_multi_select			=>	0,
			in_applies_to_inds		=>	0,
			in_applies_to_regions	=>	1,
			in_tag_members			=>	'RPTEST_TAG_1,RPTEST_TAG_2,RPTEST_TAG_3'
		);
	
	v_tags(1) := unit_test_pkg.GetOrCreateTag('RPTEST_TAG_1', v_tag_group);
	
	v_regs(1) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1');
	v_regs(2) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_1', v_regs(1), csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(3) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_1_1', v_regs(2));
	v_regs(4) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_2', v_regs(1), csr_data_pkg.REGION_TYPE_PROPERTY);	
	tag_pkg.SetRegionTags(security_pkg.getact, v_regs(4), v_tags);
	v_regs(5) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_3', v_regs(1));
	v_regs(6) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_3_1', v_regs(5));
	tag_pkg.SetRegionTags(security_pkg.getact, v_regs(6), v_tags);
	v_regs(7) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_3_1_1', v_regs(6));
	v_regs(8) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_1_3_1_2', v_regs(6), csr_data_pkg.REGION_TYPE_PROPERTY);
	v_regs(9) := unit_test_pkg.GetOrCreateRegion('PICKER_REGION_2');
	
	UPDATE region
	   SET geo_type = region_pkg.REGION_GEO_TYPE_COUNTRY, geo_country = 'gb', geo_longitude = -2, geo_latitude = 54
	 WHERE region_sid = v_regs(9);
	 
	v_parent_regs(1) := v_regs(1);
	v_parent_regs(2) := v_regs(9);
END;

PROCEDURE INTERNAL_TestRegionsResult(
	in_expected_count		IN	NUMBER,
	in_expected_sids		IN	security.security_pkg.T_SID_IDS,
	in_region_cur			IN	SYS_REFCURSOR
)
AS
	v_count					NUMBER;
	v_expected_sids			security.T_SID_TABLE;
	v_expected_sids_count	NUMBER;	
	v_region_sid			NUMBER;
	v_description			region_description.description%TYPE;	
	v_region_match			NUMBER;	
BEGIN
	v_count := 0;
	v_expected_sids := security_pkg.SidArrayToTable(in_expected_sids);
	SELECT COUNT(*)
	  INTO v_expected_sids_count
	  FROM TABLE(v_expected_sids);
	
	LOOP
		FETCH in_region_cur INTO v_region_sid, v_description;		
		EXIT WHEN in_region_cur%NOTFOUND;
		-- Ignore non-test regions.
		IF v_description LIKE 'PICKER_REGION_%' THEN
			v_count := v_count + 1;
			v_region_match := 0;
			IF v_expected_sids_count = 0 THEN
				unit_test_pkg.AssertIsTrue(v_region_sid IS NULL, 'Region Sid not matched (null), was '||v_region_sid);
			ELSE
				FOR r IN (SELECT column_value FROM TABLE(v_expected_sids))
				LOOP
					IF r.column_value = v_region_sid THEN
						v_region_match := 1;
					END IF;
				END LOOP;
				unit_test_pkg.AssertIsTrue(v_region_match = 1, 'Region Sids not matched (explicit)');
			END IF;
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_expected_count = v_count, 'Actual count was '||v_count||', expected '||in_expected_count);
END;

PROCEDURE Test_GetRegionsByType
AS
	v_cur			SYS_REFCURSOR;
	v_result_regs	security_pkg.T_SID_IDS;
BEGIN
	region_picker_pkg.GetRegionsByType(
		in_parent_sids		=> v_parent_regs,
		in_show_inactive	=> 0,
		in_region_type		=> csr_data_pkg.REGION_TYPE_PROPERTY,
		out_cur				=> v_cur
	);
	
	v_result_regs(1) := v_regs(2);
	v_result_regs(2) := v_regs(4);
	v_result_regs(3) := v_regs(8);
	
	INTERNAL_TestRegionsResult(v_result_regs.COUNT, v_result_regs, v_cur);
END;

PROCEDURE Test_GetLeafRegions
AS
	v_cur			SYS_REFCURSOR;
	v_result_regs	security_pkg.T_SID_IDS;
BEGIN
	region_picker_pkg.GetLeafRegions(
		in_parent_sids		=> v_parent_regs,
		in_show_inactive	=> 0,
		out_cur				=> v_cur
	);
	
	v_result_regs(1) := v_regs(3);
	v_result_regs(2) := v_regs(4);
	v_result_regs(3) := v_regs(7);
	v_result_regs(4) := v_regs(8);
	v_result_regs(5) := v_regs(9);
	
	INTERNAL_TestRegionsResult(v_result_regs.COUNT, v_result_regs, v_cur);
END;

PROCEDURE Test_GetCountryRegions
AS
	v_cur			SYS_REFCURSOR;
	v_result_regs	security_pkg.T_SID_IDS;
BEGIN	 
	region_picker_pkg.GetCountryRegions(
		in_parent_sids		=> v_parent_regs,
		in_show_inactive	=> 0,
		out_cur				=> v_cur
	);
	
	v_result_regs(1) := v_regs(9);
	
	INTERNAL_TestRegionsResult(v_result_regs.COUNT, v_result_regs, v_cur);
END;

PROCEDURE Test_GetChildRegions
AS
	v_cur			SYS_REFCURSOR;
	v_result_regs	security_pkg.T_SID_IDS;
BEGIN
	region_picker_pkg.GetChildRegions(
		in_parent_sids		=> v_parent_regs,
		in_show_inactive	=> 0,
		out_cur				=> v_cur
	);
	
	v_result_regs(1) := v_regs(2);
	v_result_regs(2) := v_regs(4);
	v_result_regs(3) := v_regs(5);
	
	INTERNAL_TestRegionsResult(v_result_regs.COUNT, v_result_regs, v_cur);
END;

PROCEDURE Test_GetRegionsForTags
AS
	v_cur			SYS_REFCURSOR;
	v_result_regs	security_pkg.T_SID_IDS;
BEGIN

	region_picker_pkg.GetRegionsForTags(
		in_parent_sids		=> v_parent_regs,
		in_show_inactive	=> 0,
		in_tag_ids			=> v_tags,
		out_cur				=> v_cur
	);
	
	v_result_regs(1) := v_regs(4);
	v_result_regs(2) := v_regs(6);
	
	INTERNAL_TestRegionsResult(v_result_regs.COUNT, v_result_regs, v_cur);
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
	v_ignore_number					NUMBER;
BEGIN
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
END;


END test_region_picker_pkg;
/
