CREATE OR REPLACE PACKAGE BODY csr.test_region_pkg AS

v_site_name					VARCHAR2(200);
v_region_sid_1_a1			security.security_pkg.T_SID_ID;
v_new_region_sid_2_b1		security.security_pkg.T_SID_ID;
v_new_region_sid_2_b2		security.security_pkg.T_SID_ID;
v_new_region_sid_2_b3		security.security_pkg.T_SID_ID;
v_new_region_sid_3_c1		security.security_pkg.T_SID_ID;
v_new_region_sid_3_c2		security.security_pkg.T_SID_ID;
v_new_region_sid_4_d1		security.security_pkg.T_SID_ID;


PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_region_root_sid			security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;

	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'RegTestReg1_Level1_A1',
		in_description => 'RegTestReg1_Level1_A1',
		out_region_sid => v_region_sid_1_a1
	);
		csr.region_pkg.CreateRegion(in_parent_sid => v_region_sid_1_a1,
			in_name => 'RegTestReg1_Level2_B1',
			in_description => 'RegTestReg1_Level2_B1',
			in_geo_type => csr.region_pkg.REGION_GEO_TYPE_COUNTRY,
			in_geo_country => 'ac',
			out_region_sid => v_new_region_sid_2_b1
		);
		csr.region_pkg.CreateRegion(in_parent_sid => v_region_sid_1_a1,
			in_name => 'RegTestReg1_Level2_B2',
			in_description => 'RegTestReg1_Level2_B2',
			in_geo_type => csr.region_pkg.REGION_GEO_TYPE_COUNTRY,
			in_geo_country => 'af',
			out_region_sid => v_new_region_sid_2_b2
		);
			csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_2_b1,
				in_name => 'RegTestReg1_Level3_C1',
				in_description => 'RegTestReg1_Level3_C1',
				in_geo_type => csr.region_pkg.REGION_GEO_TYPE_REGION,
				in_geo_country => 'af',
				in_geo_region => '01',
				out_region_sid => v_new_region_sid_3_c1
			);
				csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_3_c1,
					in_name => 'RegTestReg1_Level4_D1',
					in_description => 'RegTestReg1_Level4_D1',
					in_geo_type => csr.region_pkg.REGION_GEO_TYPE_CITY,
					in_geo_country => 'af',
					in_geo_region => '01',
					in_geo_city => 41201,
					out_region_sid => v_new_region_sid_4_d1
				);
		csr.region_pkg.CreateRegion(in_parent_sid => v_region_sid_1_a1,
			in_name => 'RegTestReg1_Level2_B3',
			in_description => 'RegTestReg1_Level2_B3',
			in_geo_type => csr.region_pkg.REGION_GEO_TYPE_COUNTRY,
			in_geo_country => 'gb',
			out_region_sid => v_new_region_sid_2_b3
		);
			csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_2_b3,
				in_name => 'RegTestReg1_Level3_C2',
				in_description => 'RegTestReg1_Level3_C2',
				in_geo_type => csr.region_pkg.REGION_GEO_TYPE_LOCATION,
				in_geo_country => 'gb',
				in_geo_latitude => 52.2,
				in_geo_longitude => 0.1166667,
				out_region_sid => v_new_region_sid_3_c2
			);
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;



-- HELPER PROCS

-- Tests
PROCEDURE Test_MoveRegion_MovingGeoRegionUnderDifferentCountry_ShouldBePrevented AS
	v_geo_country		VARCHAR2(1024);
	v_geo_region		NUMBER;
	v_geo_city_id		NUMBER;
	v_geo_longitude		NUMBER;
	v_geo_latitude		NUMBER;
	v_geo_type			NUMBER;
	v_success			NUMBER;
BEGIN
	Trace('Test_MoveRegion_MovingGeoRegionUnderDifferentCountry_ShouldBePrevented');

	v_success := 0;
	SELECT geo_type, geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude
	  INTO v_geo_type, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude
	  FROM region
	 WHERE region_sid = v_new_region_sid_3_c1;

	unit_test_pkg.AssertIsTrue(v_geo_type = region_pkg.REGION_GEO_TYPE_REGION, 'Region geo type is not REGION_GEO_TYPE_REGION');
	unit_test_pkg.AssertIsTrue(v_geo_country = 'af', 'Region geo country should be af, but is ' || v_geo_country);

	-- move region under under something with country, region and city geo data set
	BEGIN
		region_pkg.MoveRegion(
			in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
			in_region_sid => v_new_region_sid_3_c1,
			in_parent_sid => v_new_region_sid_2_b3
		);
	EXCEPTION
		WHEN csr_data_pkg.REGION_CANT_MOVE_REGION_GEO THEN
			v_success := 1;
		WHEN OTHERS THEN
			NULL;
	END;

	unit_test_pkg.AssertIsTrue(v_success = 1, 'An unhandled error occurred when moving regions');
END;

PROCEDURE Test_MoveRegion_MovingRegionWithGeoLocation_InheritsParentGeoDetails AS
	v_geo_country		VARCHAR2(1024);
	v_geo_region		NUMBER;
	v_geo_city_id		NUMBER;
	v_geo_longitude		NUMBER;
	v_geo_latitude		NUMBER;
	v_geo_type			NUMBER;
BEGIN
	Trace('Test_MoveRegion_MovingRegionWithGeoLocation_InheritsParentGeoDetails');

	SELECT geo_type, geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude
	  INTO v_geo_type, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude
	  FROM region
	 WHERE region_sid = v_new_region_sid_3_c2;

	unit_test_pkg.AssertIsTrue(v_geo_type = region_pkg.REGION_GEO_TYPE_LOCATION, 'Region geo type is not REGION_GEO_TYPE_LOCATION');
	unit_test_pkg.AssertIsTrue(v_geo_country = 'gb', 'Region geo country should be gb, but is ' || v_geo_country);

	-- move region under under something with country, region and city geo data set
	region_pkg.MoveRegion(
		in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
		in_region_sid => v_new_region_sid_3_c2,
		in_parent_sid => v_new_region_sid_4_d1
	);

	SELECT geo_type, geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude
	  INTO v_geo_type, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude
	  FROM region
	 WHERE region_sid = v_new_region_sid_3_c2;

	unit_test_pkg.AssertIsTrue(v_geo_type = region_pkg.REGION_GEO_TYPE_LOCATION, 'Region geo type has changed from REGION_GEO_TYPE_LOCATION to ' || v_geo_type);
	unit_test_pkg.AssertIsTrue(v_geo_country = 'af', 'Region geo country should be af, but is ' || v_geo_country);
	unit_test_pkg.AssertIsTrue(v_geo_region = '01', 'Region geo region should be 01, but is ' || v_geo_region);
	unit_test_pkg.AssertIsTrue(v_geo_city_id = 41201, 'Region geo city id should be 41201, but is ' || v_geo_city_id);

	-- move it back
	region_pkg.MoveRegion(
		in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
		in_region_sid => v_new_region_sid_3_c2,
		in_parent_sid => v_new_region_sid_2_b3
	);

	SELECT geo_type, geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude
	  INTO v_geo_type, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude
	  FROM region
	 WHERE region_sid = v_new_region_sid_3_c2;

	unit_test_pkg.AssertIsTrue(v_geo_type = region_pkg.REGION_GEO_TYPE_LOCATION, 'Region geo type has changed from REGION_GEO_TYPE_LOCATION to ' || v_geo_type);
	unit_test_pkg.AssertIsTrue(v_geo_country = 'gb', 'Region geo country should be gb, but is ' || v_geo_country);
	unit_test_pkg.AssertIsTrue(v_geo_region = null, 'Region geo region should be empty, but is ' || v_geo_region);
	unit_test_pkg.AssertIsTrue(v_geo_city_id = null, 'Region geo city id should be empty, but is ' || v_geo_city_id);
END;

PROCEDURE TestGetTreeWithDepth AS
	v_tree					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_sid_id			NUMBER;
	v_parent_sid_id		NUMBER;
	v_description		VARCHAR2(1024);
	v_link_to_region_sid NUMBER;
	v_lvl				NUMBER;
	v_is_leaf			NUMBER;
	v_class_name		VARCHAR2(1024);
	v_active			NUMBER;
	v_pos				NUMBER;
	v_info_xml			VARCHAR2(1024);
	v_flag				NUMBER;
	v_acquisition_dtm	DATE;
	v_disposal_dtm		DATE;
	v_region_type		NUMBER;
	v_region_ref		VARCHAR2(1024);
	v_lookup_key		VARCHAR2(1024);
	v_geo_country		VARCHAR2(1024);
	v_geo_region		NUMBER;
	v_geo_city_id		NUMBER;
	v_geo_longitude		NUMBER;
	v_geo_latitude		NUMBER;
	v_geo_type			NUMBER;
	v_map_entity		VARCHAR2(1024);
	v_egrid_ref			VARCHAR2(1024);
	v_egrid_ref_overridden	NUMBER;
	v_last_modified_dtm	DATE;
	v_is_primary		NUMBER;

	v_regs		security_pkg.T_SID_IDS;
BEGIN
	Trace('TestGetTreeWithDepth');
	v_regs(1) := v_region_sid_1_a1;

	region_pkg.GetTreeWithDepth(
		in_act_id						=>	security.security_pkg.getACT,
		in_parent_sids					=>	v_regs,
		in_include_root					=>	1,
		in_fetch_depth					=>	2,
		in_show_inactive				=>	0,
		out_cur							=>	v_tree
	);

	v_count := 0;
	LOOP
		FETCH v_tree INTO 
				v_sid_id, v_parent_sid_id, v_description, v_link_to_region_sid, v_lvl, v_is_leaf, v_class_name,
				v_active, v_pos, v_info_xml, v_flag, v_acquisition_dtm, v_disposal_dtm, v_region_type, v_region_ref,
				v_lookup_key, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude,
				v_geo_type, v_map_entity, v_egrid_ref, v_egrid_ref_overridden, v_last_modified_dtm, v_is_primary
		;
		EXIT WHEN v_tree%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_sid_id||' '||v_parent_sid_id||' '||v_description||' '||v_lvl||' '||v_is_leaf);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_region_sid_1_a1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 1, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 3 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b2, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 1, 'Unexpected leaf.');
		ELSIF v_count = 4 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b3, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 4, 'Expected 4, found '||v_count);
END;

PROCEDURE TestGetTreeWithDepthAndSecondaryTreeTag AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_tag_id				tag.tag_id%TYPE;
	v_tree					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_sid_id			NUMBER;
	v_parent_sid_id		NUMBER;
	v_description		VARCHAR2(1024);
	v_link_to_region_sid NUMBER;
	v_lvl				NUMBER;
	v_is_leaf			NUMBER;
	v_class_name		VARCHAR2(1024);
	v_active			NUMBER;
	v_pos				NUMBER;
	v_info_xml			VARCHAR2(1024);
	v_flag				NUMBER;
	v_acquisition_dtm	DATE;
	v_disposal_dtm		DATE;
	v_region_type		NUMBER;
	v_region_ref		VARCHAR2(1024);
	v_lookup_key		VARCHAR2(1024);
	v_geo_country		VARCHAR2(1024);
	v_geo_region		NUMBER;
	v_geo_city_id		NUMBER;
	v_geo_longitude		NUMBER;
	v_geo_latitude		NUMBER;
	v_geo_type			NUMBER;
	v_map_entity		VARCHAR2(1024);
	v_egrid_ref			VARCHAR2(1024);
	v_egrid_ref_overridden	NUMBER;
	v_last_modified_dtm	DATE;
	v_is_primary		NUMBER;

	
	v_test_name		VARCHAR2(100) := 'TagST';
	v_regs		security_pkg.T_SID_IDS;
BEGIN
	Trace('TestGetTreeWithDepthAndSecondaryTreeTag');
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);

	-- tag regions and resync
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_region_sid_1_a1, in_tag_id => v_tag_id);
	region_tree_pkg.SyncSecondaryForTag(in_secondary_root_sid => v_secondary_tree_root, in_tag_id => v_tag_id);

	v_regs(1) := v_secondary_tree_root;
	v_regs(2) := v_region_sid_1_a1;

	region_pkg.GetTreeWithDepth(
		in_act_id						=>	security.security_pkg.getACT,
		in_parent_sids					=>	v_regs,
		in_include_root					=>	1,
		in_fetch_depth					=>	2,
		in_show_inactive				=>	0,
		out_cur							=>	v_tree
	);


	v_count := 0;
	LOOP
		FETCH v_tree INTO 
				v_sid_id, v_parent_sid_id, v_description, v_link_to_region_sid, v_lvl, v_is_leaf, v_class_name,
				v_active, v_pos, v_info_xml, v_flag, v_acquisition_dtm, v_disposal_dtm, v_region_type, v_region_ref,
				v_lookup_key, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude,
				v_geo_type, v_map_entity, v_egrid_ref, v_egrid_ref_overridden, v_last_modified_dtm, v_is_primary
		;
		EXIT WHEN v_tree%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_sid_id||' '||v_parent_sid_id||' '||v_link_to_region_sid||' '||v_description||' '||v_lvl||' '||v_is_leaf);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_region_sid_1_a1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 1, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 3 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b2, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 1, 'Unexpected leaf.');
		ELSIF v_count = 4 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b3, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 5 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_secondary_tree_root, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 1, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 6 THEN
			unit_test_pkg.AssertIsTrue(v_link_to_region_sid = v_region_sid_1_a1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 6, 'Expected 6, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);

	tag_pkg.SetRegionTags(
		in_act_id => security.security_pkg.getACT,
		in_region_sid => v_region_sid_1_a1,
		in_tag_ids => ''
	);
	tag_pkg.RemoveTagFromGroup(
		in_act_id => security.security_pkg.getACT,
		in_tag_group_id => v_taggroup_id,
		in_tag_id => v_tag_id
	);
	tag_pkg.DeleteTagGroup(
		in_act_id => security.security_pkg.getACT,
		in_tag_group_id => v_taggroup_id
	);
END;

PROCEDURE TestGetTreeWithDepthAndSecondaryTreeTagGroup AS
	v_secondary_tree_root	NUMBER;
	v_taggroup_id			tag_group.tag_group_id%TYPE;
	v_tag_id				tag.tag_id%TYPE;
	v_tree					SYS_REFCURSOR;
	v_count					NUMBER;
	
	v_sid_id			NUMBER;
	v_parent_sid_id		NUMBER;
	v_description		VARCHAR2(1024);
	v_link_to_region_sid NUMBER;
	v_lvl				NUMBER;
	v_is_leaf			NUMBER;
	v_class_name		VARCHAR2(1024);
	v_active			NUMBER;
	v_pos				NUMBER;
	v_info_xml			VARCHAR2(1024);
	v_flag				NUMBER;
	v_acquisition_dtm	DATE;
	v_disposal_dtm		DATE;
	v_region_type		NUMBER;
	v_region_ref		VARCHAR2(1024);
	v_lookup_key		VARCHAR2(1024);
	v_geo_country		VARCHAR2(1024);
	v_geo_region		NUMBER;
	v_geo_city_id		NUMBER;
	v_geo_longitude		NUMBER;
	v_geo_latitude		NUMBER;
	v_geo_type			NUMBER;
	v_map_entity		VARCHAR2(1024);
	v_egrid_ref			VARCHAR2(1024);
	v_egrid_ref_overridden	NUMBER;
	v_last_modified_dtm	DATE;
	v_is_primary		NUMBER;

	
	v_test_name		VARCHAR2(100) := 'TagGroupST';
	v_regs		security_pkg.T_SID_IDS;
BEGIN
	Trace('TestGetTreeWithDepthAndSecondaryTreeTagGroup');
	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);
	
	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	tag_pkg.CreateTagGroup(in_name => v_test_name||'_TagGroup1', out_tag_group_id => v_taggroup_id);
	tag_pkg.SetTag(in_tag_group_id => v_taggroup_id, in_tag => v_test_name||'_Tag1', out_tag_id => v_tag_id);

	-- tag regions and resync
	tag_pkg.UNSEC_SetRegionTag(in_region_sid => v_region_sid_1_a1, in_tag_id => v_tag_id);
	region_tree_pkg.SyncSecondaryForTagGroup(in_secondary_root_sid => v_secondary_tree_root, in_tag_group_id => v_taggroup_id);

	v_regs(1) := v_secondary_tree_root;
	v_regs(2) := v_region_sid_1_a1;

	region_pkg.GetTreeWithDepth(
		in_act_id						=>	security.security_pkg.getACT,
		in_parent_sids					=>	v_regs,
		in_include_root					=>	1,
		in_fetch_depth					=>	2,
		in_show_inactive				=>	0,
		out_cur							=>	v_tree
	);


	v_count := 0;
	LOOP
		FETCH v_tree INTO 
				v_sid_id, v_parent_sid_id, v_description, v_link_to_region_sid, v_lvl, v_is_leaf, v_class_name,
				v_active, v_pos, v_info_xml, v_flag, v_acquisition_dtm, v_disposal_dtm, v_region_type, v_region_ref,
				v_lookup_key, v_geo_country, v_geo_region, v_geo_city_id, v_geo_longitude, v_geo_latitude,
				v_geo_type, v_map_entity, v_egrid_ref, v_egrid_ref_overridden, v_last_modified_dtm, v_is_primary
		;
		EXIT WHEN v_tree%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_sid_id||' '||v_parent_sid_id||' '||v_link_to_region_sid||' '||v_description||' '||v_lvl||' '||v_is_leaf);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_region_sid_1_a1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 1, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b1, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 3 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b2, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 1, 'Unexpected leaf.');
		ELSIF v_count = 4 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_new_region_sid_2_b3, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 5 THEN
			unit_test_pkg.AssertIsTrue(v_sid_id = v_secondary_tree_root, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_lvl = 1, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		ELSIF v_count = 6 THEN
			unit_test_pkg.AssertIsNull(v_link_to_region_sid, 'Unexpected sid id.');
			unit_test_pkg.AssertIsTrue(v_description = 'TagGroupST_Tag1', 'Unexpected sid desc.');
			unit_test_pkg.AssertIsTrue(v_lvl = 2, 'Unexpected level.');
			unit_test_pkg.AssertIsTrue(v_is_leaf = 0, 'Unexpected leaf.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 6, 'Expected 6, found '||v_count);

	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);

	tag_pkg.SetRegionTags(
		in_act_id => security.security_pkg.getACT,
		in_region_sid => v_region_sid_1_a1,
		in_tag_ids => ''
	);
	tag_pkg.RemoveTagFromGroup(
		in_act_id => security.security_pkg.getACT,
		in_tag_group_id => v_taggroup_id,
		in_tag_id => v_tag_id
	);
	tag_pkg.DeleteTagGroup(
		in_act_id => security.security_pkg.getACT,
		in_tag_group_id => v_taggroup_id
	);
END;

PROCEDURE TestGetSystemManagedRegion 
AS
	v_secondary_tree_root		NUMBER;
	v_is_system_managed			BINARY_INTEGER;
	v_test_name		VARCHAR2(100) := 'TestGetSystemManagedRegion';
BEGIN
	Trace('TestGetSystemManagedRegion');	

	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);

	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;
	
	v_is_system_managed := region_pkg.GetRegionIsSystemManaged(in_region_sid => v_secondary_tree_root);
	
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);

	unit_test_pkg.AssertIsTrue(v_is_system_managed = 1, 'Expected 1, found '||v_is_system_managed);
END;


PROCEDURE TestGetSystemManagedRegionWhenIsNotSystemManaged
AS
	v_secondary_tree_root		NUMBER;
	v_is_system_managed			BINARY_INTEGER;
	v_test_name		VARCHAR2(100) := 'TestGetSystemManagedRegionWhenIsNotSystemManaged';
BEGIN
	Trace('TestGetSystemManagedRegionWhenIsNotSystemManaged');	

	enable_pkg.CreateSecondaryRegionTree(secondaryTreeName => v_test_name);

	SELECT region_sid
	  INTO v_secondary_tree_root
	  FROM v$region
	 WHERE description = v_test_name;

	region_tree_pkg.SaveSecondaryTree(
		in_region_sid => v_secondary_tree_root,
		in_description => v_test_name,
		in_is_system_managed => 0);
	
	v_is_system_managed := region_pkg.GetRegionIsSystemManaged(in_region_sid => v_secondary_tree_root);
	
	region_pkg.DeleteObject(security.security_pkg.getACT, v_secondary_tree_root);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_secondary_tree_root);

	unit_test_pkg.AssertIsTrue(v_is_system_managed = 0, 'Expected 0, found '||v_is_system_managed);
END;

--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixtureRegions AS
BEGIN 
	Trace('TearDownFixtureRegions');
	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'RegTestReg%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	DELETE FROM secondary_region_tree_log;
	DELETE FROM secondary_region_tree_ctrl;
	TearDownFixtureRegions;
END;

END test_region_pkg;
/
