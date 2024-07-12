CREATE OR REPLACE PACKAGE BODY csr.test_val_datasource_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_region_root_sid			security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;



-- HELPER PROCS



-- Tests

PROCEDURE TestGetRegionTreeForSheets AS
	v_count					NUMBER;

	v_in_sheet_ids			security_pkg.T_SID_IDS;
	v_out_region_cur		SYS_REFCURSOR;
	v_out_region_tag_cur	SYS_REFCURSOR;

	v_regs					security_pkg.T_SID_IDS;
	v_inds					security_pkg.T_SID_IDS;
	v_ind_1_sid				NUMBER;
	v_region_1_sid			NUMBER;
	v_region_1_tag_group_id	NUMBER;
	v_region_1_tag_id		NUMBER;
	v_deleg_1_sid			NUMBER;
	v_sheet_id				NUMBER;

	v_parent_sid			NUMBER;
	v_active				NUMBER;
	v_region_sid			NUMBER;
	v_description			VARCHAR2(100);
	v_pos					NUMBER;
	v_geo_latitude			NUMBER;
	v_geo_longitude			NUMBER;
	v_geo_country			VARCHAR2(100);
	v_geo_region			VARCHAR2(100);
	v_geo_city_id			VARCHAR2(100);
	v_map_entity			VARCHAR2(100);
	v_egrid_ref				VARCHAR2(100);
	v_geo_type				NUMBER;
	v_disposal_dtm			DATE;
	v_acquisition_dtm		DATE;
	v_lookup_key			VARCHAR2(100);
	v_region_ref			VARCHAR2(100);
	v_region_type			NUMBER;
	v_lvl					NUMBER;
	v_rn					NUMBER;

	v_tag_id				NUMBER;
BEGIN
	Trace('TestGetRegionTreeForSheets');

	-- no data
	val_datasource_pkg.GetRegionTreeForSheets(
		in_sheet_ids => v_in_sheet_ids,
		out_region_cur => v_out_region_cur,
		out_region_tag_cur => v_out_region_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_region_cur INTO 
			v_parent_sid,
			v_active,
			v_region_sid,
			v_description,
			v_pos,
			v_geo_latitude,
			v_geo_longitude,
			v_geo_country,
			v_geo_region,
			v_geo_city_id,
			v_map_entity,
			v_egrid_ref,
			v_geo_type,
			v_disposal_dtm,
			v_acquisition_dtm,
			v_lookup_key,
			v_region_ref,
			v_region_type,
			v_lvl,
			v_rn
		;
		EXIT WHEN v_out_region_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_active);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 region, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_region_tag_cur INTO 
			v_region_sid,
			v_tag_id
		;
		EXIT WHEN v_out_region_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_region_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 tags, found '||v_count);


	-- ind
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');

	-- region
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('VAL_DATASOURCE_REGION_1');
	INSERT INTO region_list (region_sid) VALUES (v_region_1_sid);

	BEGIN
		csr.tag_pkg.CreateTagGroup(
			in_name							=> 'VDS Group',
			in_applies_to_regions			=> 1,
			in_lookup_key					=> 'VDS GRP',
			out_tag_group_id				=> v_region_1_tag_group_id
		);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT tag_group_id
			  INTO v_region_1_tag_group_id
			  FROM tag_group
			 WHERE lookup_key = 'VDS GRP'
		;
	END;
	
	BEGIN
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_region_1_tag_group_id,
		in_tag					=> 'VDS Tag',
		in_pos					=> 1,
		in_lookup_key			=> 'VDS_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_region_1_tag_id
	);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT tag_id
			  INTO v_region_1_tag_id
			  FROM tag
			 WHERE lookup_key = 'VDS_TAG_LOOKUP_KEY_1'
		;
	END;
	BEGIN
		INSERT INTO region_tag (tag_id, region_sid) VALUES (v_region_1_tag_id, v_region_1_sid);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	-- sheet
	v_regs(1) := v_region_1_sid;
	v_inds(1) := v_ind_1_sid;
	v_deleg_1_sid := unit_test_pkg.GetOrCreateDeleg('VDS_DELEG_1', v_regs, v_inds);
	INSERT INTO sheet (sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, is_visible, is_read_only)
		VALUES (1, v_deleg_1_sid, DATE '2022-01-01', DATE '2022-02-01', DATE '2022-01-20', DATE '2022-01-21', 1, 0)
		RETURNING sheet_id INTO v_sheet_id;

	-- input sheet id
	v_in_sheet_ids(1) := v_sheet_id;

	val_datasource_pkg.GetRegionTreeForSheets(
		in_sheet_ids => v_in_sheet_ids,
		out_region_cur => v_out_region_cur,
		out_region_tag_cur => v_out_region_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_region_cur INTO 
			v_parent_sid,
			v_active,
			v_region_sid,
			v_description,
			v_pos,
			v_geo_latitude,
			v_geo_longitude,
			v_geo_country,
			v_geo_region,
			v_geo_city_id,
			v_map_entity,
			v_egrid_ref,
			v_geo_type,
			v_disposal_dtm,
			v_acquisition_dtm,
			v_lookup_key,
			v_region_ref,
			v_region_type,
			v_lvl,
			v_rn
		;
		EXIT WHEN v_out_region_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_active);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 region, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_region_tag_cur INTO 
			v_region_sid,
			v_tag_id
		;
		EXIT WHEN v_out_region_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_region_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 tags, found '||v_count);

	IF v_deleg_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_deleg_1_sid);
		v_deleg_1_sid := NULL;
	END IF;

	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_region_1_tag_group_id);
END;

PROCEDURE TestGetRegionTree AS
	v_count					NUMBER;

	v_out_region_cur		SYS_REFCURSOR;
	v_out_region_tag_cur	SYS_REFCURSOR;

	v_region_1_sid			NUMBER;
	v_region_1_tag_group_id	NUMBER;
	v_region_1_tag_id		NUMBER;

	v_parent_sid			NUMBER;
	v_active				NUMBER;
	v_region_sid			NUMBER;
	v_description			VARCHAR2(100);
	v_pos					NUMBER;
	v_geo_latitude			NUMBER;
	v_geo_longitude			NUMBER;
	v_geo_country			VARCHAR2(100);
	v_geo_region			VARCHAR2(100);
	v_geo_city_id			VARCHAR2(100);
	v_map_entity			VARCHAR2(100);
	v_egrid_ref				VARCHAR2(100);
	v_geo_type				NUMBER;
	v_disposal_dtm			DATE;
	v_acquisition_dtm		DATE;
	v_lookup_key			VARCHAR2(100);
	v_region_ref			VARCHAR2(100);
	v_region_type			NUMBER;
	v_lvl					NUMBER;
	v_rn					NUMBER;

	v_tag_id				NUMBER;
BEGIN
	Trace('TestGetRegionTree');
	-- no regions

	val_datasource_pkg.GetRegionTree(
		out_region_cur => v_out_region_cur,
		out_region_tag_cur => v_out_region_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_region_cur INTO 
			v_parent_sid,
			v_active,
			v_region_sid,
			v_description,
			v_pos,
			v_geo_latitude,
			v_geo_longitude,
			v_geo_country,
			v_geo_region,
			v_geo_city_id,
			v_map_entity,
			v_egrid_ref,
			v_geo_type,
			v_disposal_dtm,
			v_acquisition_dtm,
			v_lookup_key,
			v_region_ref,
			v_region_type,
			v_lvl,
			v_rn
		;
		EXIT WHEN v_out_region_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_active);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 region, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_region_tag_cur INTO 
			v_region_sid,
			v_tag_id
		;
		EXIT WHEN v_out_region_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_region_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 tags, found '||v_count);


	-- one region
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('VAL_DATASOURCE_REGION_1');
	INSERT INTO region_list (region_sid) VALUES (v_region_1_sid);

	BEGIN
		csr.tag_pkg.CreateTagGroup(
			in_name							=> 'VDS Group',
			in_applies_to_regions			=> 1,
			in_lookup_key					=> 'VDS GRP',
			out_tag_group_id				=> v_region_1_tag_group_id
		);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT tag_group_id
			  INTO v_region_1_tag_group_id
			  FROM tag_group
			 WHERE lookup_key = 'VDS GRP'
		;
	END;
	
	BEGIN
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_region_1_tag_group_id,
		in_tag					=> 'VDS Tag',
		in_pos					=> 1,
		in_lookup_key			=> 'VDS_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_region_1_tag_id
	);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT tag_id
			  INTO v_region_1_tag_id
			  FROM tag
			 WHERE lookup_key = 'VDS_TAG_LOOKUP_KEY_1'
		;
	END;
	BEGIN
		INSERT INTO region_tag (tag_id, region_sid) VALUES (v_region_1_tag_id, v_region_1_sid);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	val_datasource_pkg.GetRegionTree(
		out_region_cur => v_out_region_cur,
		out_region_tag_cur => v_out_region_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_region_cur INTO 
			v_parent_sid,
			v_active,
			v_region_sid,
			v_description,
			v_pos,
			v_geo_latitude,
			v_geo_longitude,
			v_geo_country,
			v_geo_region,
			v_geo_city_id,
			v_map_entity,
			v_egrid_ref,
			v_geo_type,
			v_disposal_dtm,
			v_acquisition_dtm,
			v_lookup_key,
			v_region_ref,
			v_region_type,
			v_lvl,
			v_rn
		;
		EXIT WHEN v_out_region_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_active);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 region, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_region_tag_cur INTO 
			v_region_sid,
			v_tag_id
		;
		EXIT WHEN v_out_region_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_region_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 tags, found '||v_count);



	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_region_1_tag_group_id);
END;

PROCEDURE TestGetRegions AS
	v_count					NUMBER;

	v_out_region_cur		SYS_REFCURSOR;
	v_out_region_tag_cur	SYS_REFCURSOR;

	v_region_1_sid			NUMBER;
	v_region_1_tag_group_id	NUMBER;
	v_region_1_tag_id		NUMBER;

	v_parent_sid			NUMBER;
	v_active				NUMBER;
	v_region_sid			NUMBER;
	v_description			VARCHAR2(100);
	v_pos					NUMBER;
	v_geo_latitude			NUMBER;
	v_geo_longitude			NUMBER;
	v_geo_country			VARCHAR2(100);
	v_geo_region			VARCHAR2(100);
	v_geo_city_id			NUMBER;
	v_map_entity			VARCHAR2(100);
	v_egrid_ref				VARCHAR2(100);
	v_geo_type				NUMBER;
	v_disposal_dtm			DATE;
	v_acquisition_dtm		DATE;
	v_lookup_key			VARCHAR2(100);
	v_region_type			NUMBER;
	v_region_ref			VARCHAR2(100);

	v_tag_id				NUMBER;
BEGIN
	Trace('TestGetRegions');
	-- no regions

	val_datasource_pkg.GetRegions(
		out_cur => v_out_region_cur,
		out_tag_cur => v_out_region_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_region_cur INTO 
			v_parent_sid,
			v_active,
			v_region_sid,
			v_description,
			v_pos,
			v_geo_latitude,
			v_geo_longitude,
			v_geo_country,
			v_geo_region,
			v_geo_city_id,
			v_map_entity,
			v_egrid_ref,
			v_geo_type,
			v_disposal_dtm,
			v_acquisition_dtm,
			v_lookup_key,
			v_region_type,
			v_region_ref
		;
		EXIT WHEN v_out_region_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_active);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 region, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_region_tag_cur INTO 
			v_region_sid,
			v_tag_id
		;
		EXIT WHEN v_out_region_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_region_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 tags, found '||v_count);


	-- one region
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('VAL_DATASOURCE_REGION_1');
	INSERT INTO region_list (region_sid) VALUES (v_region_1_sid);

	BEGIN
		csr.tag_pkg.CreateTagGroup(
			in_name							=> 'VDS Group',
			in_applies_to_regions			=> 1,
			in_lookup_key					=> 'VDS GRP',
			out_tag_group_id				=> v_region_1_tag_group_id
		);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT tag_group_id
			  INTO v_region_1_tag_group_id
			  FROM tag_group
			 WHERE lookup_key = 'VDS GRP'
		;
	END;
	
	BEGIN
	csr.tag_pkg.SetTag(
		in_tag_group_id			=> v_region_1_tag_group_id,
		in_tag					=> 'VDS Tag',
		in_pos					=> 1,
		in_lookup_key			=> 'VDS_TAG_LOOKUP_KEY_1',
		in_active				=> 1,
		out_tag_id				=> v_region_1_tag_id
	);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT tag_id
			  INTO v_region_1_tag_id
			  FROM tag
			 WHERE lookup_key = 'VDS_TAG_LOOKUP_KEY_1'
		;
	END;
	BEGIN
		INSERT INTO region_tag (tag_id, region_sid) VALUES (v_region_1_tag_id, v_region_1_sid);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	val_datasource_pkg.GetRegions(
		out_cur => v_out_region_cur,
		out_tag_cur => v_out_region_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_region_cur INTO 
			v_parent_sid,
			v_active,
			v_region_sid,
			v_description,
			v_pos,
			v_geo_latitude,
			v_geo_longitude,
			v_geo_country,
			v_geo_region,
			v_geo_city_id,
			v_map_entity,
			v_egrid_ref,
			v_geo_type,
			v_disposal_dtm,
			v_acquisition_dtm,
			v_lookup_key,
			v_region_type,
			v_region_ref
		;
		EXIT WHEN v_out_region_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_active);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 region, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_region_tag_cur INTO 
			v_region_sid,
			v_tag_id
		;
		EXIT WHEN v_out_region_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_region_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 tags, found '||v_count);

	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	tag_pkg.DeleteTagGroup(security.security_pkg.getACT, v_region_1_tag_group_id);

END;

PROCEDURE TestGetAllIndDetailsNoInds AS
	v_count					NUMBER;

	v_out_cur				SYS_REFCURSOR;
	v_out_tag_cur			SYS_REFCURSOR;

	v_ind_sid	NUMBER;
	v_description	VARCHAR2(100);
	v_scale	NUMBER;
	v_format_mask	VARCHAR2(100); 
	v_divisibility	NUMBER;
	v_aggregate	VARCHAR2(100); 
	v_period_set_id	NUMBER;
	v_period_interval_id	NUMBER;
	v_do_temporal_aggregation	NUMBER; 
	v_calc_description	VARCHAR2(100);
	v_calc_xml	VARCHAR2(100);
	v_ind_type	NUMBER;
	v_calc_start_dtm_adjustment	NUMBER;
	v_calc_end_dtm_adjustment	NUMBER;
	v_measure_description	VARCHAR2(100);
	v_measure_sid	NUMBER;
	v_info_xml	VARCHAR2(100);
	v_start_month	NUMBER;
	v_gri	VARCHAR2(100); 
	v_parent_sid	NUMBER;
	v_pos	NUMBER;
	v_target_direction	NUMBER;
	v_active	NUMBER;
	v_tolerance_type	NUMBER; 
	v_pct_lower_tolerance	NUMBER;
	v_pct_upper_tolerance	NUMBER;
	v_tolerance_number_of_periods	NUMBER;
	v_tolerance_number_of_standard_deviations_from_average	NUMBER;
	v_factor_type_id	NUMBER;
	v_gas_measure_sid	NUMBER;
	v_gas_type_id	NUMBER;
	v_map_to_ind_sid	NUMBER;
	v_normalize	NUMBER;
	v_ind_activity_type_id	NUMBER;
	v_core	NUMBER;
	v_roll_forward	NUMBER;
	v_prop_down_region_tree_sid	NUMBER;
	v_is_system_managed	NUMBER;
	v_calc_fixed_start_dtm	DATE;
	v_calc_fixed_end_dtm	DATE;
	v_lookup_key	VARCHAR2(100);
	v_calc_output_round_dp	NUMBER;

	v_tag_id	NUMBER;
BEGIN
	Trace('TestGetAllIndDetailsNoInds');
	
	val_datasource_pkg.GetAllIndDetails(
		out_cur			=>	v_out_cur,
		out_tag_cur		=>	v_out_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_ind_sid,
			v_description,
			v_scale,
			v_format_mask, 
			v_divisibility,
			v_aggregate, 
			v_period_set_id,
			v_period_interval_id,
			v_do_temporal_aggregation, 
			v_calc_description,
			v_calc_xml,
			v_ind_type,
			v_calc_start_dtm_adjustment,
			v_calc_end_dtm_adjustment,
			v_measure_description,
			v_measure_sid,
			v_info_xml,
			v_start_month,
			v_gri, 
			v_parent_sid,
			v_pos,
			v_target_direction,
			v_active,
			v_tolerance_type, 
			v_pct_lower_tolerance,
			v_pct_upper_tolerance,
			v_tolerance_number_of_periods,
			v_tolerance_number_of_standard_deviations_from_average,
			v_factor_type_id,
			v_gas_measure_sid,
			v_gas_type_id,
			v_map_to_ind_sid,
			v_normalize,
			v_ind_activity_type_id,
			v_core,
			v_roll_forward,
			v_prop_down_region_tree_sid,
			v_is_system_managed,
			v_calc_fixed_start_dtm,
			v_calc_fixed_end_dtm,
			v_lookup_key,
			v_calc_output_round_dp
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_description);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 inds, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_tag_cur INTO 
			v_ind_sid,
			v_tag_id
		;
		EXIT WHEN v_out_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 tags, found '||v_count);
END;

PROCEDURE TestGetAllIndDetailsInds AS
	v_count					NUMBER;

	v_out_cur				SYS_REFCURSOR;
	v_out_tag_cur			SYS_REFCURSOR;

	v_ind_sid	NUMBER;
	v_description	VARCHAR2(100);
	v_scale	NUMBER;
	v_format_mask	VARCHAR2(100); 
	v_divisibility	NUMBER;
	v_aggregate	VARCHAR2(100); 
	v_period_set_id	NUMBER;
	v_period_interval_id	NUMBER;
	v_do_temporal_aggregation	NUMBER; 
	v_calc_description	VARCHAR2(100);
	v_calc_xml	VARCHAR2(100);
	v_ind_type	NUMBER;
	v_calc_start_dtm_adjustment	NUMBER;
	v_calc_end_dtm_adjustment	NUMBER;
	v_measure_description	VARCHAR2(100);
	v_measure_sid	NUMBER;
	v_info_xml	VARCHAR2(100);
	v_start_month	NUMBER;
	v_gri	VARCHAR2(100); 
	v_parent_sid	NUMBER;
	v_pos	NUMBER;
	v_target_direction	NUMBER;
	v_active	NUMBER;
	v_tolerance_type	NUMBER; 
	v_pct_lower_tolerance	NUMBER;
	v_pct_upper_tolerance	NUMBER;
	v_tolerance_number_of_periods	NUMBER;
	v_tolerance_number_of_standard_deviations_from_average	NUMBER;
	v_factor_type_id	NUMBER;
	v_gas_measure_sid	NUMBER;
	v_gas_type_id	NUMBER;
	v_map_to_ind_sid	NUMBER;
	v_normalize	NUMBER;
	v_ind_activity_type_id	NUMBER;
	v_core	NUMBER;
	v_roll_forward	NUMBER;
	v_prop_down_region_tree_sid	NUMBER;
	v_is_system_managed	NUMBER;
	v_calc_fixed_start_dtm	DATE;
	v_calc_fixed_end_dtm	DATE;
	v_lookup_key	VARCHAR2(100);
	v_calc_output_round_dp	NUMBER;

	v_tag_id	NUMBER;

	v_ind_1_sid	NUMBER;
	v_tag_group_1_id	NUMBER;
	v_tag_1_id	NUMBER;
	v_out_ignore_number	NUMBER;
BEGIN
	Trace('TestGetAllIndDetailsInds');
	
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_tag_group_1_id :=	unit_test_pkg.GetOrCreateTagGroup(
			in_lookup_key			=>	'VAL_DATASOURCETAG_GROUP_1',
			in_multi_select			=>	0,
			in_applies_to_inds		=>	0,
			in_applies_to_regions	=>	1,
			in_tag_members			=>	'VAL_DATASOURCE_TAG_1,VAL_DATASOURCE_TAG_2,VAL_DATASOURCE_TAG_3'
		);
	v_tag_1_id := unit_test_pkg.GetOrCreateTag('VAL_DATASOURCE_TAG_1', v_tag_group_1_id);


	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	BEGIN
		INSERT INTO ind_tag (ind_sid, tag_id) VALUES (v_ind_1_sid, v_tag_1_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	val_datasource_pkg.GetAllIndDetails(
		out_cur			=>	v_out_cur,
		out_tag_cur		=>	v_out_tag_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_ind_sid,
			v_description,
			v_scale,
			v_format_mask, 
			v_divisibility,
			v_aggregate, 
			v_period_set_id,
			v_period_interval_id,
			v_do_temporal_aggregation, 
			v_calc_description,
			v_calc_xml,
			v_ind_type,
			v_calc_start_dtm_adjustment,
			v_calc_end_dtm_adjustment,
			v_measure_description,
			v_measure_sid,
			v_info_xml,
			v_start_month,
			v_gri, 
			v_parent_sid,
			v_pos,
			v_target_direction,
			v_active,
			v_tolerance_type, 
			v_pct_lower_tolerance,
			v_pct_upper_tolerance,
			v_tolerance_number_of_periods,
			v_tolerance_number_of_standard_deviations_from_average,
			v_factor_type_id,
			v_gas_measure_sid,
			v_gas_type_id,
			v_map_to_ind_sid,
			v_normalize,
			v_ind_activity_type_id,
			v_core,
			v_roll_forward,
			v_prop_down_region_tree_sid,
			v_is_system_managed,
			v_calc_fixed_start_dtm,
			v_calc_fixed_end_dtm,
			v_lookup_key,
			v_calc_output_round_dp
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_description);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 inds, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_tag_cur INTO 
			v_ind_sid,
			v_tag_id
		;
		EXIT WHEN v_out_tag_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_tag_id);

	END LOOP;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 tags, found '||v_count);



	IF v_tag_group_1_id IS NOT NULL THEN
		-- remove the tags from the ind
		csr.tag_pkg.RemoveIndicatorTag(
			in_act_id				=>	security_pkg.getact,
			in_ind_sid				=>	v_ind_1_sid,
			in_tag_id				=>	v_tag_1_id,
			out_rows_updated		=>  v_out_ignore_number
		);
	
		-- delete the tag group
		tag_pkg.DeleteTagGroup(security_pkg.getact, v_tag_group_1_id);
		v_tag_group_1_id := NULL;
	END IF;


	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
END;


PROCEDURE TestGetIndAndReportCalcDetailsInds AS
	v_count					NUMBER;

	v_out_cur				SYS_REFCURSOR;
	v_out_tag_cur			SYS_REFCURSOR;
	v_out_rep_calc_agg_child_cur	SYS_REFCURSOR;

	v_parent_sid	NUMBER;
	v_ind_sid	NUMBER;

	v_tag_id	NUMBER;

	v_ind_1_sid	NUMBER;
	v_ind_2_sid	NUMBER;
BEGIN
	Trace('TestGetIndAndReportCalcDetailsInds');
	
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_ind_2_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_2');
	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_REPORT_CALC,
			parent_sid = v_ind_1_sid
	 WHERE ind_sid = v_ind_2_sid;

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	INSERT INTO ind_list (ind_sid) VALUES (v_ind_2_sid);

	BEGIN
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_2_sid, v_ind_1_sid, csr_data_pkg.DEP_ON_CHILDREN);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	val_datasource_pkg.GetIndAndReportCalcDetails(
		out_cur			=>	v_out_cur,
		out_tag_cur		=>	v_out_tag_cur,
		out_rep_calc_agg_child_cur		=>	v_out_rep_calc_agg_child_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_rep_calc_agg_child_cur INTO 
			v_parent_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_rep_calc_agg_child_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_parent_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 inds, found '||v_count);

	DELETE FROM csr.calc_dependency
	 WHERE ind_sid IN (v_ind_1_sid, v_ind_2_sid);

	IF v_ind_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_2_sid);
		v_ind_2_sid := NULL;
	END IF;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
END;

PROCEDURE TestGetAllGasFactors AS
	v_ind_1_sid							NUMBER;
	v_test_parent_factor_type_id		NUMBER;
	v_test_factor_type_id				NUMBER;
	v_test_std_measure_id				NUMBER;
	v_test_std_measure_conversion_id	NUMBER;

	v_count				NUMBER;
	v_out_cur			SYS_REFCURSOR;

	v_factor_type_id	NUMBER;
	v_gas_type_id		NUMBER;
	v_region_sid		NUMBER;
	v_geo_country		VARCHAR2(100);
	v_geo_region		VARCHAR2(100);
	v_egrid_ref			VARCHAR2(100);
	v_start_dtm			DATE;
	v_end_dtm			DATE;
	v_std_measure_conversion_id	NUMBER;
	v_value				NUMBER;
	v_is_virtual		NUMBER;
BEGIN
	Trace('TestGetAllGasFactors');

	val_datasource_pkg.GetAllGasFactors(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_factor_type_id,
			v_gas_type_id,
			v_region_sid,
			v_geo_country,
			v_geo_region,
			v_egrid_ref,
			v_start_dtm,
			v_end_dtm,
			v_std_measure_conversion_id,
			v_value,
			v_is_virtual
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_factor_type_id||v_gas_type_id);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 factors, found '||v_count);


	-- Sprinkle some data on.
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');

	v_test_factor_type_id := 1; -- unused id
	v_test_std_measure_id := 1; -- "constant"
	v_test_std_measure_conversion_id := 1; -- "constant"
	SELECT factor_type_id
	  INTO v_test_parent_factor_type_id
	  FROM factor_type
	 WHERE parent_id IS NULL;

	INSERT INTO factor_type (factor_type_id, parent_id, name, std_measure_id, egrid, enabled)
	VALUES (v_test_factor_type_id, v_test_parent_factor_type_id, 'Test factor', v_test_std_measure_id, 0, 0);

	INSERT INTO factor (factor_id, factor_type_id, gas_type_id, start_dtm, end_dtm, 
		geo_country, geo_region, egrid_ref, region_sid, value, note, std_factor_id, std_measure_conversion_id, is_selected)
		VALUES (999, 
			81,--factor_type_id
			1,--gas_type_id
			DATE '2016-01-01',--start_dtm
			NULL,--end_dtm
			NULL,--geo_country
			NULL,--geo_region
			NULL,--egrid_ref
			NULL,-- region_sid
			123,--value
			'note',--note
			543,--std_factor_id
			v_test_std_measure_conversion_id,--std_measure_conversion_id
			1--is_selected
	);

	UPDATE ind
	   SET factor_type_id = 81
	 WHERE ind_sid = v_ind_1_sid;

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);

	val_datasource_pkg.GetAllGasFactors(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_factor_type_id,
			v_gas_type_id,
			v_region_sid,
			v_geo_country,
			v_geo_region,
			v_egrid_ref,
			v_start_dtm,
			v_end_dtm,
			v_std_measure_conversion_id,
			v_value,
			v_is_virtual
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_factor_type_id||v_gas_type_id);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 factors, found '||v_count);


	DELETE FROM factor
	 WHERE factor_id = 999;

	DELETE FROM factor_type
	 WHERE factor_type_id = v_test_factor_type_id;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
END;


PROCEDURE TestGetIndDependencies AS
	v_count			NUMBER;
	v_out_cur		SYS_REFCURSOR;

	v_ind_1_sid		NUMBER;
	v_ind_2_sid		NUMBER;
	v_measure_sid	NUMBER;

	v_calc_ind_sid	NUMBER;
	v_ind_sid		NUMBER;
BEGIN
	Trace('TestGetIndDependencies');

	val_datasource_pkg.GetIndDependencies(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_calc_ind_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_calc_ind_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 deps, found '||v_count);

	-- Sprinkle some data on.
	BEGIN
		measure_pkg.CreateMeasure(in_name => 'VDSTestMeasure1', in_description => 'VDSTestMeasure1', 
			out_measure_sid => v_measure_sid);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT measure_sid
			  INTO v_measure_sid
			  FROM measure
			 WHERE name = 'VDSTestMeasure1';
	END;
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_ind_2_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_2');

	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_CALC,
			measure_sid = v_measure_sid
	 WHERE ind_sid = v_ind_1_sid;
	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_REPORT_CALC,
			measure_sid = v_measure_sid
	 WHERE ind_sid = v_ind_2_sid;

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	INSERT INTO ind_list (ind_sid) VALUES (v_ind_2_sid);

	BEGIN
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_1_sid, v_ind_2_sid, csr_data_pkg.DEP_ON_INDICATOR);
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_2_sid, v_ind_1_sid, csr_data_pkg.DEP_ON_INDICATOR);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	val_datasource_pkg.GetIndDependencies(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_calc_ind_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_calc_ind_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 deps, found '||v_count);

	DELETE FROM calc_dependency
	 WHERE ind_sid IN (v_ind_1_sid, v_ind_2_sid);

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

	IF v_ind_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_2_sid);
		v_ind_2_sid := NULL;
	END IF;

	IF v_measure_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_measure_sid);
		v_measure_sid := NULL;
	END IF;

END;

PROCEDURE TestGetAggregateIndDependencies AS
	v_count			NUMBER;
	v_out_cur		SYS_REFCURSOR;

	v_ind_1_sid		NUMBER;
	v_ind_2_sid		NUMBER;
	v_measure_sid	NUMBER;

	v_calc_ind_sid	NUMBER;
	v_ind_sid		NUMBER;
BEGIN
	Trace('TestGetAggregateIndDependencies');

	val_datasource_pkg.GetAggregateIndDependencies(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_calc_ind_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_calc_ind_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 deps, found '||v_count);

	-- Sprinkle some data on.
	BEGIN
		measure_pkg.CreateMeasure(in_name => 'VDSTestMeasure1', in_description => 'VDSTestMeasure1', 
			out_measure_sid => v_measure_sid);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT measure_sid
			  INTO v_measure_sid
			  FROM measure
			 WHERE name = 'VDSTestMeasure1';
	END;
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_ind_2_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_2');

	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_CALC,
			measure_sid = v_measure_sid
	 WHERE ind_sid = v_ind_1_sid;
	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_REPORT_CALC,
			measure_sid = v_measure_sid,
			parent_sid = v_ind_1_sid
	 WHERE ind_sid = v_ind_2_sid;

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	INSERT INTO ind_list (ind_sid) VALUES (v_ind_2_sid);

	BEGIN
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_1_sid, v_ind_2_sid, csr_data_pkg.DEP_ON_INDICATOR);
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_2_sid, v_ind_1_sid, csr_data_pkg.DEP_ON_CHILDREN);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	val_datasource_pkg.GetAggregateIndDependencies(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_calc_ind_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_calc_ind_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 deps, found '||v_count);

	DELETE FROM calc_dependency
	 WHERE ind_sid IN (v_ind_1_sid, v_ind_2_sid);

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

	IF v_ind_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_2_sid);
		v_ind_2_sid := NULL;
	END IF;

	IF v_measure_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_measure_sid);
		v_measure_sid := NULL;
	END IF;

END;

PROCEDURE TestGetAggregateChildren AS
	v_count			NUMBER;
	v_out_cur		SYS_REFCURSOR;

	v_ind_1_sid		NUMBER;
	v_ind_2_sid		NUMBER;
	v_measure_sid	NUMBER;

	v_calc_ind_sid	NUMBER;
	v_ind_sid		NUMBER;
BEGIN
	Trace('TestGetAggregateChildren');

	val_datasource_pkg.GetAggregateChildren(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_calc_ind_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_calc_ind_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 deps, found '||v_count);

	-- Sprinkle some data on.
	BEGIN
		measure_pkg.CreateMeasure(in_name => 'VDSTestMeasure1', in_description => 'VDSTestMeasure1', 
			out_measure_sid => v_measure_sid);
	EXCEPTION
		WHEN OTHERS THEN 
			SELECT measure_sid
			  INTO v_measure_sid
			  FROM measure
			 WHERE name = 'VDSTestMeasure1';
	END;
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_ind_2_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_2');

	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_CALC,
			measure_sid = v_measure_sid
	 WHERE ind_sid = v_ind_1_sid;
	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_REPORT_CALC,
			measure_sid = v_measure_sid,
			parent_sid = v_ind_1_sid
	 WHERE ind_sid = v_ind_2_sid;

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	INSERT INTO ind_list (ind_sid) VALUES (v_ind_2_sid);

	BEGIN
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_1_sid, v_ind_2_sid, csr_data_pkg.DEP_ON_INDICATOR);
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (v_ind_2_sid, v_ind_1_sid, csr_data_pkg.DEP_ON_CHILDREN);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	val_datasource_pkg.GetAggregateChildren(
		out_cur			=>	v_out_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO 
			v_calc_ind_sid,
			v_ind_sid
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_calc_ind_sid||v_ind_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 deps, found '||v_count);

	DELETE FROM calc_dependency
	 WHERE ind_sid IN (v_ind_1_sid, v_ind_2_sid);

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

	IF v_ind_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_2_sid);
		v_ind_2_sid := NULL;
	END IF;

	IF v_measure_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_measure_sid);
		v_measure_sid := NULL;
	END IF;

END;

PROCEDURE TestFetchResult AS
	v_count				NUMBER;
	v_ind_1_sid			NUMBER;
	v_region_1_sid		NUMBER;

	v_out_val_cur		SYS_REFCURSOR;
	v_out_file_cur		SYS_REFCURSOR;

	v_period_start_dtm	DATE;
	v_period_end_dtm	DATE;
	v_ind_sid			NUMBER;
	v_region_sid		NUMBER;
	v_val_number		NUMBER;
	v_error_code		NUMBER;
	v_changed_dtm		DATE;
	v_note				VARCHAR2(100);
	v_source			NUMBER;
	v_source_id			NUMBER;
	v_source_type_id	NUMBER;
	v_flags				NUMBER;
	v_is_merged			NUMBER;

	v_file_upload_sid	NUMBER;
	v_filename			VARCHAR2(100);
	v_mime_type			VARCHAR2(100);
BEGIN
	Trace('TestFetchResult');
	val_datasource_pkg.INTERNAL_FetchResult(
		out_val_cur			=>	v_out_val_cur,
		out_file_cur		=>	v_out_file_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_val_cur INTO 
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid, 
			v_val_number,
			v_error_code,
			v_changed_dtm,
			v_note,
			v_source,
			v_source_id,
			v_source_type_id,
			v_flags,
			v_is_merged
		;
		EXIT WHEN v_out_val_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_region_sid);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 val results, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_file_cur INTO 
			v_source_id,
			v_file_upload_sid,
			v_filename,
			v_mime_type
		;
		EXIT WHEN v_out_file_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_source_id||v_file_upload_sid||v_filename);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 file results, found '||v_count);

	-- Sprinkle some data...
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('VAL_DATASOURCE_REGION_1');
	v_source_id := 12;
	v_file_upload_sid := 222;

	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, 
		val_number, error_code, changed_dtm, note, flags, is_merged)
	VALUES (DATE '2022-01-01', DATE '2022-02-01', 0, v_source_id, 0, v_ind_1_sid, v_region_1_sid,
		789, NULL, SYSDATE, 'Note', NULL, 0);

	BEGIN
		INSERT INTO file_upload (file_upload_sid, filename, mime_type, parent_sid, data, sha1, last_modified_dtm)
		VALUES (v_file_upload_sid, 'fname', 'text/plain', 99, EMPTY_BLOB, dbms_crypto.hash(EMPTY_BLOB, dbms_crypto.hash_sh1), SYSDATE);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	BEGIN
		INSERT INTO val (val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
		VALUES (v_source_id, v_ind_1_sid, v_region_1_sid, DATE '2022-01-01', DATE '2022-02-01', 2, NULL, 2, 0);

		INSERT INTO val_file (val_id, file_upload_sid)
		VALUES (v_source_id, v_file_upload_sid);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	val_datasource_pkg.INTERNAL_FetchResult(
		out_val_cur			=>	v_out_val_cur,
		out_file_cur		=>	v_out_file_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_val_cur INTO 
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid, 
			v_val_number,
			v_error_code,
			v_changed_dtm,
			v_note,
			v_source,
			v_source_id,
			v_source_type_id,
			v_flags,
			v_is_merged
		;
		EXIT WHEN v_out_val_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_region_sid||v_note);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 val results, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_file_cur INTO 
			v_source_id,
			v_file_upload_sid,
			v_filename,
			v_mime_type
		;
		EXIT WHEN v_out_file_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_source_id||v_file_upload_sid||v_filename);
	END LOOP;

	-- This test returns zero because of the INTERNAL_FetchResult forcibly disabling any output into the cursor
	-- with a WHERE 1 = 0
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 file results, found '||v_count);

	DELETE FROM val_file
	 WHERE val_id = v_source_id;

	DELETE FROM val
	 WHERE val_id = v_source_id;

	DELETE FROM file_upload
	 WHERE file_upload_sid = v_file_upload_sid;

	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
END;

PROCEDURE TestGetStoredRecalcValues AS
	v_count				NUMBER;
	v_ind_1_sid			NUMBER;
	v_region_1_sid		NUMBER;

	v_in_start_dtm		DATE;
	v_in_end_dtm		DATE;
	v_out_val_cur		SYS_REFCURSOR;
	v_out_file_cur		SYS_REFCURSOR;

	v_period_start_dtm	DATE;
	v_period_end_dtm	DATE;
	v_ind_sid			NUMBER;
	v_region_sid		NUMBER;
	v_val_number		NUMBER;
	v_error_code		NUMBER;
	v_changed_dtm		DATE;
	v_note				VARCHAR2(100);
	v_source			NUMBER;
	v_source_id			NUMBER;
	v_source_type_id	NUMBER;
	v_flags				NUMBER;
	v_is_merged			NUMBER;

	v_file_upload_sid	NUMBER;
	v_filename			VARCHAR2(100);
	v_mime_type			VARCHAR2(100);
BEGIN
	Trace('TestGetStoredRecalcValues');

	v_in_start_dtm := DATE '2022-01-01';
	v_in_end_dtm := DATE '2022-02-01';

	val_datasource_pkg.GetStoredRecalcValues(
		in_start_dtm		=>	v_in_start_dtm,
		in_end_dtm			=>	v_in_end_dtm,
		out_val_cur			=>	v_out_val_cur,
		out_file_cur		=>	v_out_file_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_val_cur INTO 
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid, 
			v_val_number,
			v_error_code,
			v_changed_dtm,
			v_note,
			v_source,
			v_source_id,
			v_source_type_id,
			v_flags,
			v_is_merged
		;
		EXIT WHEN v_out_val_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_region_sid||v_note);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 val results, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_file_cur INTO 
			v_source_id,
			v_file_upload_sid,
			v_filename,
			v_mime_type
		;
		EXIT WHEN v_out_file_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_source_id||v_file_upload_sid||v_filename);
	END LOOP;

	-- This test returns zero because of the GetStoredRecalcValues forcibly disabling any output into the cursor
	-- with a WHERE 1 = 0
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 file results, found '||v_count);



	-- Sprinkle some data...
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('VAL_DATASOURCE_REGION_1');
	v_source_id := 12;

	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, 
		val_number, error_code, changed_dtm, note, flags, is_merged)
	VALUES (DATE '2022-01-01', DATE '2022-02-01', 0, v_source_id, 0, v_ind_1_sid, v_region_1_sid,
		789, NULL, SYSDATE, 'Note', NULL, 0);

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	INSERT INTO region_list (region_sid) VALUES (v_region_1_sid);
	
	BEGIN
		INSERT INTO val (val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
		VALUES (v_source_id, v_ind_1_sid, v_region_1_sid, DATE '2022-01-01', DATE '2022-02-01', 2, NULL, 2, 0);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;


	val_datasource_pkg.GetStoredRecalcValues(
		in_start_dtm		=>	v_in_start_dtm,
		in_end_dtm			=>	v_in_end_dtm,
		out_val_cur			=>	v_out_val_cur,
		out_file_cur		=>	v_out_file_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_val_cur INTO 
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid, 
			v_val_number,
			v_error_code,
			v_changed_dtm,
			v_note,
			v_source,
			v_source_id,
			v_source_type_id,
			v_flags,
			v_is_merged
		;
		EXIT WHEN v_out_val_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_region_sid||v_note);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 val results, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_file_cur INTO 
			v_source_id,
			v_file_upload_sid,
			v_filename,
			v_mime_type
		;
		EXIT WHEN v_out_file_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_source_id||v_file_upload_sid||v_filename);
	END LOOP;

	-- This test returns zero because of the GetStoredRecalcValues forcibly disabling any output into the cursor
	-- with a WHERE 1 = 0
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 file results, found '||v_count);


	DELETE FROM val
	 WHERE val_id = v_source_id;

	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

END;

PROCEDURE TestGetAllSheetValues AS
	v_count				NUMBER;

	v_ind_1_sid			NUMBER;
	v_region_1_sid		NUMBER;

	v_in_start_dtm		DATE;
	v_in_end_dtm		DATE;
	v_out_val_cur		SYS_REFCURSOR;
	v_out_file_cur		SYS_REFCURSOR;

	v_period_start_dtm	DATE;
	v_period_end_dtm	DATE;
	v_ind_sid			NUMBER;
	v_region_sid		NUMBER;
	v_val_number		NUMBER;
	v_error_code		NUMBER;
	v_changed_dtm		DATE;
	v_note				VARCHAR2(100);
	v_source			NUMBER;
	v_source_id			NUMBER;
	v_source_type_id	NUMBER;
	v_flags				NUMBER;
	v_is_merged			NUMBER;

	v_file_upload_sid	NUMBER;
	v_filename			VARCHAR2(100);
	v_mime_type			VARCHAR2(100);

BEGIN
	Trace('TestGetAllSheetValues');
	v_in_start_dtm := DATE '2022-01-01';
	v_in_end_dtm := DATE '2022-02-01';

	val_datasource_pkg.GetAllSheetValues(
		in_start_dtm		=>	v_in_start_dtm,
		in_end_dtm			=>	v_in_end_dtm,
		out_val_cur			=>	v_out_val_cur,
		out_file_cur		=>	v_out_file_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_val_cur INTO 
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid, 
			v_val_number,
			v_error_code,
			v_changed_dtm,
			v_note,
			v_source,
			v_source_id,
			v_source_type_id,
			v_flags,
			v_is_merged
		;
		EXIT WHEN v_out_val_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_region_sid||v_note);
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 val results, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_file_cur INTO 
			v_source_id,
			v_file_upload_sid,
			v_filename,
			v_mime_type
		;
		EXIT WHEN v_out_file_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_source_id||v_file_upload_sid||v_filename);
	END LOOP;

	-- This test always returns zero because of the WHERE 1 = 0
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 file results, found '||v_count);


	-- Sprinkle some data...
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('VAL_DATASOURCE_IND_1');
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('VAL_DATASOURCE_REGION_1');
	v_source_id := 12;

	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, 
		val_number, error_code, changed_dtm, note, flags, is_merged)
	VALUES (DATE '2022-01-01', DATE '2022-02-01', 0, v_source_id, 0, v_ind_1_sid, v_region_1_sid,
		789, NULL, SYSDATE, 'Note', NULL, 0);

	INSERT INTO ind_list (ind_sid) VALUES (v_ind_1_sid);
	INSERT INTO region_list (region_sid) VALUES (v_region_1_sid);
	
	BEGIN
		INSERT INTO val (val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
		VALUES (v_source_id, v_ind_1_sid, v_region_1_sid, DATE '2022-01-01', DATE '2022-02-01', 2, NULL, 2, 0);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;


	val_datasource_pkg.GetAllSheetValues(
		in_start_dtm		=>	v_in_start_dtm,
		in_end_dtm			=>	v_in_end_dtm,
		out_val_cur			=>	v_out_val_cur,
		out_file_cur		=>	v_out_file_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_out_val_cur INTO 
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid, 
			v_val_number,
			v_error_code,
			v_changed_dtm,
			v_note,
			v_source,
			v_source_id,
			v_source_type_id,
			v_flags,
			v_is_merged
		;
		EXIT WHEN v_out_val_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_ind_sid||v_region_sid||v_note);
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 val results, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_out_file_cur INTO 
			v_source_id,
			v_file_upload_sid,
			v_filename,
			v_mime_type
		;
		EXIT WHEN v_out_file_cur%NOTFOUND;
		v_count := v_count + 1;

		Trace(v_source_id||v_file_upload_sid||v_filename);
	END LOOP;

	-- This test returns zero because of the WHERE 1 = 0
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 file results, found '||v_count);


	DELETE FROM val
	 WHERE val_id = v_source_id;

	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

END;

--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
END;

END test_val_datasource_pkg;
/
