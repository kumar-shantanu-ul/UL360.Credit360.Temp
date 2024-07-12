CREATE OR REPLACE PACKAGE BODY csr.test_indicator_pkg AS

v_site_name					VARCHAR2(200);
v_test_ind_sid				security.security_pkg.T_SID_ID;
v_test_ind_root_sid			security.security_pkg.T_SID_ID;


PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE RemoveSid(
	v_sid					security_pkg.T_SID_ID
)
AS
BEGIN
	security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
END;

PROCEDURE RemoveSids(
	v_sids					security_pkg.T_SID_IDS
)
AS
BEGIN
	IF v_sids.COUNT > 0 THEN
		FOR i IN v_sids.FIRST..v_sids.LAST
		LOOP
			RemoveSid(v_sids(i));
		END LOOP;
	END IF;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_region_root_sid			security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUpFixture');
	v_site_name	:= in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	v_test_ind_sid := unit_test_pkg.GetOrCreateInd('TestIndicators_IND_1');
	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_test_ind_sid,
		in_description 					=> 'TestIndicators_IND_1',
		in_lookup_key					=> 'TestIndicators_IND_1',
		in_tolerance_number_of_periods	=> 5,
		in_tolerance_number_of_standard_deviations_from_average => 0.5
	);

	SELECT ind_root_sid
	  INTO v_test_ind_root_sid
	  FROM customer;
END;

PROCEDURE SetUp
AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;

-- HELPER PROCS
PROCEDURE CheckTolerance(
	in_lookup_key VARCHAR2,
	in_expected_tolerance_number_of_periods NUMBER DEFAULT NULL,
	in_expected_tolerance_number_of_standard_deviations_from_average NUMBER DEFAULT NULL
)
AS
	v_tolerance_number_of_periods NUMBER;
	v_tolerance_number_of_standard_deviations_from_average NUMBER;
BEGIN
	-- check record shows expected value
	SELECT tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average
	  INTO v_tolerance_number_of_periods, v_tolerance_number_of_standard_deviations_from_average
	  FROM ind
	 WHERE lookup_key = in_lookup_key;

	unit_test_pkg.AssertAreEqual(in_expected_tolerance_number_of_periods, v_tolerance_number_of_periods, 'Unexpected value');
	unit_test_pkg.AssertAreEqual(in_expected_tolerance_number_of_standard_deviations_from_average, v_tolerance_number_of_standard_deviations_from_average, 'Unexpected value');

	-- check view shows expected value
	SELECT tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average
	  INTO v_tolerance_number_of_periods, v_tolerance_number_of_standard_deviations_from_average
	  FROM v$ind
	 WHERE lookup_key = in_lookup_key;

	unit_test_pkg.AssertAreEqual(in_expected_tolerance_number_of_periods, v_tolerance_number_of_periods, 'Unexpected value');
	unit_test_pkg.AssertAreEqual(in_expected_tolerance_number_of_standard_deviations_from_average, v_tolerance_number_of_standard_deviations_from_average, 'Unexpected value');
END;

-- Tests

PROCEDURE TestAmendIndicator
AS
	v_ind_sid				security.security_pkg.T_SID_ID;
BEGIN
	unit_test_pkg.StartTest('TestAmendIndicator');

	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestAmendIndicator_IND_1');

	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_ind_sid,
		in_description 					=> 'TestAmendIndicator_IND_1',
		in_lookup_key					=> 'TestAmendIndicator_IND_1',
		in_tolerance_number_of_periods	=> 11,
		in_tolerance_number_of_standard_deviations_from_average => 2
	);

	CheckTolerance('TestAmendIndicator_IND_1', 11, 2);

	RemoveSid(v_ind_sid);
END;

PROCEDURE TestCreateIndicator
AS
	v_ind_sid				security.security_pkg.T_SID_ID;

	v_ind_root_sid			security_pkg.T_SID_ID;
	v_measure_sid			security_pkg.T_SID_ID;
	v_test_name				VARCHAR2(30);
BEGIN
	unit_test_pkg.StartTest('TestCreateIndicator');

	-- bare min, using unit_test_pkg.GetOrCreateInd
	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestCreateIndicator_IND_1');

	CheckTolerance('TestCreateIndicator_IND_1');

	RemoveSid(v_ind_sid);


	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;
	v_measure_sid := unit_test_pkg.GetOrCreateMeasure('MEASURE_1');
	v_test_name := 'TestCreateIndicator_IND_2';
	indicator_pkg.CreateIndicator(
		in_parent_sid_id => v_ind_root_sid,
		in_name => v_test_name,
		in_description => v_test_name,
		in_lookup_key => v_test_name,
		in_measure_sid => v_measure_sid,
		in_aggregate => 'SUM',
		in_tolerance_number_of_periods => 12,
		in_tolerance_number_of_standard_deviations_from_average => 3,
		out_sid_id => v_ind_sid
	);

	CheckTolerance('TestCreateIndicator_IND_2', 12, 3);

	RemoveSid(v_ind_sid);

END;

PROCEDURE TestCopyIndicator
AS
	v_ind_sid				security.security_pkg.T_SID_ID;
	v_copied_ind_sid		security.security_pkg.T_SID_ID;
	v_ind_root_sid			security_pkg.T_SID_ID;
BEGIN
	unit_test_pkg.StartTest('TestCopyIndicator');

	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestCopyIndicator_IND_1');
	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_ind_sid,
		in_description 					=> 'TestCopyIndicator_IND_1',
		in_lookup_key					=> 'TestCopyIndicator_IND_1',
		in_tolerance_number_of_periods	=> 10,
		in_tolerance_number_of_standard_deviations_from_average => 1
	);
	CheckTolerance('TestCopyIndicator_IND_1', 10, 1);


	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;

	indicator_pkg.CopyIndicator(
		in_act_id		 		=> security.security_pkg.GetAct,
		in_copy_ind_sid 		=> v_ind_sid,
		in_parent_sid_id		=> v_ind_root_sid,
		out_sid_id				=> v_copied_ind_sid
	);
	UPDATE ind
	   SET lookup_key = 'TestCopyIndicator_IND_2'
	 WHERE ind_sid = v_copied_ind_sid;

	CheckTolerance('TestCopyIndicator_IND_2', 10, 1);

	RemoveSid(v_copied_ind_sid);
	RemoveSid(v_ind_sid);
END;

PROCEDURE TestGetDataOverviewIndicators AS
	v_count					NUMBER;

	v_ind1_sid				security_pkg.T_SID_ID;
	v_ind2_sid				security_pkg.T_SID_ID;
	v_ind3_sid				security_pkg.T_SID_ID;
	v_ind4_sid				security_pkg.T_SID_ID;

	v_root_indicator_sids	security_pkg.T_SID_IDS;
	v_app_sid				security_pkg.T_SID_ID;
	v_cur					SYS_REFCURSOR;
	v_tag_groups_cur		SYS_REFCURSOR;
	v_ind_tag_cur			SYS_REFCURSOR;
	v_flags_cur				SYS_REFCURSOR;
	v_ind_baseline_cur		SYS_REFCURSOR;


	v_ind_sid					NUMBER;
	v_description				VARCHAR2(100);
	v_measure_sid				NUMBER;
	v_calc_xml					VARCHAR2(100);
	v_measure_description		VARCHAR2(100);
	v_ind_type					NUMBER;
	v_so_level					NUMBER;
	v_info_xml					VARCHAR2(100);
	v_custom_field				VARCHAR2(100);
	v_aggregate					VARCHAR2(100); 
	v_format_mask				VARCHAR2(100);
	v_pct_upper_tolerance		VARCHAR2(100);
	v_pct_lower_tolerance		VARCHAR2(100);
	v_tolerance_number_of_periods	NUMBER;
	v_tolerance_number_of_standard_deviations_from_average	NUMBER;
	v_tolerance_type			NUMBER;
	v_scale						NUMBER;
	v_divisibility				NUMBER;
	v_active					NUMBER;
	v_roll_forward				NUMBER;
	v_calc_description			VARCHAR2(100); 
	v_do_temporal_aggregation	NUMBER;
	v_period_set_id				NUMBER;
	v_period_interval_id		NUMBER;
	v_factor_name				VARCHAR2(100);
	v_gas_name					VARCHAR2(100); 
	v_gas_measure_description	VARCHAR2(100); 
	v_target_direction			NUMBER;
	v_normalize					NUMBER;
	v_start_month				NUMBER;
	v_lookup_key				VARCHAR2(100);
	v_is_region_metric			NUMBER;
	v_parent_sid				NUMBER;

BEGIN
	unit_test_pkg.StartTest('TestGetDataOverviewIndicators');

	v_ind1_sid := unit_test_pkg.GetOrCreateInd('2020 v1.03');
	v_ind2_sid := unit_test_pkg.GetOrCreateInd('2021 v1.01');
	v_ind3_sid := unit_test_pkg.GetOrCreateInd('2020 v1.06');
	v_ind4_sid := unit_test_pkg.GetOrCreateInd('2020 v1.02');

	v_root_indicator_sids(1) := v_ind1_sid;
	v_root_indicator_sids(2) := v_ind2_sid;
	v_root_indicator_sids(3) := v_ind3_sid;
	v_root_indicator_sids(4) := v_ind4_sid;

	indicator_pkg.GetDataOverviewIndicators(
		in_act_id				=> security_pkg.getACT,
		in_root_indicator_sids	=> v_root_indicator_sids,
		in_app_sid				=> security_pkg.getAPP,
		out_cur					=> v_cur,
		out_tag_groups_cur		=> v_tag_groups_cur,
		out_ind_tag_cur			=> v_ind_tag_cur,
		out_flags_cur			=> v_flags_cur,
		out_ind_baseline_cur	=> v_ind_baseline_cur
	);
	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_ind_sid,
			v_description,
			v_measure_sid,
			v_calc_xml,
			v_measure_description,
			v_ind_type,
			v_so_level,
			v_info_xml,
			v_custom_field,
			v_aggregate, 
			v_format_mask,
			v_tolerance_type,
			v_pct_upper_tolerance,
			v_pct_lower_tolerance,
			v_tolerance_number_of_periods,
			v_tolerance_number_of_standard_deviations_from_average,
			v_scale,
			v_divisibility,
			v_active,
			v_roll_forward,
			v_calc_description, 
			v_do_temporal_aggregation,
			v_period_set_id,
			v_period_interval_id,
			v_factor_name,
			v_gas_name, 
			v_gas_measure_description, 
			v_target_direction,
			v_normalize,
			v_start_month,
			v_lookup_key,
			v_is_region_metric,
			v_parent_sid
		;
		EXIT WHEN v_cur%NOTFOUND;

		Trace('v_ind_sid='||v_ind_sid||'v_description='||v_description);
		v_count := v_count + 1;

		IF v_count = 1 THEN 
			unit_test_pkg.AssertAreEqual(v_ind_sid, v_ind4_sid, 'Unexpected order');
		END IF;
		IF v_count = 2 THEN 
			unit_test_pkg.AssertAreEqual(v_ind_sid, v_ind1_sid, 'Unexpected order');
		END IF;
		IF v_count = 3 THEN 
			unit_test_pkg.AssertAreEqual(v_ind_sid, v_ind3_sid, 'Unexpected order');
		END IF;
		IF v_count = 4 THEN 
			unit_test_pkg.AssertAreEqual(v_ind_sid, v_ind2_sid, 'Unexpected order');
		END IF;
	END LOOP;

	unit_test_pkg.AssertAreEqual(4, v_count, 'Unexpected count');

	security.securableobject_pkg.deleteso(security_pkg.getact, v_ind1_sid);
	security.securableobject_pkg.deleteso(security_pkg.getact, v_ind2_sid);
	security.securableobject_pkg.deleteso(security_pkg.getact, v_ind3_sid);
	security.securableobject_pkg.deleteso(security_pkg.getact, v_ind4_sid);
END;

PROCEDURE TestGetIndicator
AS
	v_ind_sid		security.security_pkg.T_SID_ID;
	v_cur			SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetIndicator');

	indicator_pkg.GetIndicator(
		in_act_id		=>	security.security_pkg.GetAct,
		in_ind_sid		=>	v_test_ind_sid,
		out_cur			=>	v_cur
	);

	/* The returned cur is:
	LOOP
		FETCH v_cur INTO 
			v_ind_sid,
			v_name,
			v_description,
			v_lookup_key,
			v_measure_name,
			v_measure_description,
			v_measure_sid,
			v_gri,
			v_multiplier,
			v_scale,
			v_format_mask,
			v_active,
			v_actual_scale,
			v_actual_format_mask,
			v_calc_xml,
			v_divisibility,
			v_actual_divisibility,
			v_start_month,
			v_node_type,
			v_ind_type,
			v_calc_start_dtm_adjustment,
			v_calc_end_dtm_adjustment,
			v_period_set_id,
			v_period_interval_id,
			v_do_temporal_aggregation,
			v_calc_description, 
			v_target_direction,
			v_last_modified_dtm,
			v_info_xml,
			v_parent_sid,
			v_pos,
			v_aggregate, 
			v_tolerance_type,
			v_pct_lower_tolerance,
			v_pct_upper_tolerance,
			v_tolerance_number_of_periods,
			v_tolerance_number_of_standard_deviations_from_average,
			v_factor_type_id,
			v_ind_activity_type_id, 
			v_gas_measure_sid,
			v_gas_type_id,
			v_map_to_ind_sid,
			v_name factor_type_name,
			v_normalize,
			v_core,
			v_roll_forward,
			v_prop_down_region_tree_sid,
			v_is_system_managed,
			v_calc_fixed_start_dtm,
			v_calc_fixed_end_dtm,
			v_calc_output_round_dp,
			v_aggregate_ind_group,
			v_has_values,
			v_is_region_metric,
			v_has_region_metric_values,
			v_name factor_type_description
		;
		EXIT WHEN v_cur%NOTFOUND;
	END LOOP;
	*/

END;

PROCEDURE TestGetIndicatorChildren
AS
	v_ind_sid		security.security_pkg.T_SID_ID;
	v_ind_root_sid	security_pkg.T_SID_ID;
	v_cur			SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetIndicatorChildren');


	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestGetIndicatorChildren_IND_1');
	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_ind_sid,
		in_description 					=> 'TestGetIndicatorChildren_IND_1',
		in_lookup_key					=> 'TestGetIndicatorChildren_IND_1',
		in_tolerance_number_of_periods	=> 9,
		in_tolerance_number_of_standard_deviations_from_average => 4
	);

	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;

	indicator_pkg.GetIndicatorChildren(
		in_act_id		=>	security.security_pkg.GetAct,
		in_parent_sid	=>	v_ind_root_sid,
		out_cur			=>	v_cur
	);

	/* The returned cur is:
	LOOP
		FETCH v_cur INTO 
			v_ind_sid,
			v_name,
			v_description,
			v_lookup_key,
			v_measure_name,
			v_measure_description,
			v_measure_sid,
			v_gri,
			v_multiplier,
			v_scale,
			v_format_mask,
			v_active,
			v_actual_scale,
			v_actual_format_mask,
			v_calc_xml, 
			v_divisibility,
			v_actual_divisibility,
			v_start_month,
			v_node_type,
			v_ind_type,
			v_calc_start_dtm_adjustment,
			v_calc_end_dtm_adjustment,
			v_period_set_id,
			v_period_interval_id, 
			v_do_temporal_aggregation,
			v_calc_description,
			v_target_direction,
			v_last_modified_dtm,
			v_info_xml,
			v_parent_sid,
			v_pos,
			v_aggregate, 
			v_tolerance_type,
			v_pct_lower_tolerance,
			v_pct_upper_tolerance, 
			v_tolerance_number_of_periods,
			v_tolerance_number_of_standard_deviations_from_average,
			v_ind_activity_type_id, 
			v_core,
			v_roll_forward,
			v_gas_measure_sid,
			v_gas_type_id,
			v_map_to_ind_sid,
			v_factor_type_id,
			v_normalize,
			v_prop_down_region_tree_sid,
			v_is_system_managed
		;
		EXIT WHEN v_cur%NOTFOUND;
	END LOOP;
	*/

END;

PROCEDURE TestGetIndicators
AS
	v_ind_sid			security.security_pkg.T_SID_ID;
	v_ind_root_sid		security_pkg.T_SID_ID;

	v_inds_cur			SYS_REFCURSOR;
	v_tags_cur			SYS_REFCURSOR;
	v_trashed_inds_cur	SYS_REFCURSOR;

	v_ind_sids			security.security_pkg.T_SID_IDS;
BEGIN
	unit_test_pkg.StartTest('TestGetIndicators');

	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestGetIndicatorChildren_IND_1');
	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_ind_sid,
		in_description 					=> 'TestGetIndicatorChildren_IND_1',
		in_lookup_key					=> 'TestGetIndicatorChildren_IND_1',
		in_tolerance_number_of_periods	=> 9,
		in_tolerance_number_of_standard_deviations_from_average => 4
	);

	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;

	v_ind_sids(1) := v_ind_sid;

	indicator_pkg.GetIndicators(
		in_ind_sids		=>	v_ind_sids,
		out_ind_cur		=>	v_inds_cur,
		out_tag_cur		=>	v_tags_cur,
		out_trashed_inds=>	v_trashed_inds_cur
	);

	/* v_inds_cur is:
			v_ind_sid, v_name, v_description, v_lookup_key, v_measure_name, v_measure_description, v_measure_sid,
			v_gri, v_multiplier, v_scale, v_format_mask, v_active,
			v_scale actual_scale, v_actual_format_mask, v_calc_xml,
			v_divisibility, v_actual_divisibility, v_start_month,
			v_node_type, v_ind_type, v_calc_start_dtm_adjustment, v_calc_end_dtm_adjustment,
			v_period_set_id, v_period_interval_id, v_do_temporal_aggregation, v_calc_description, 
			v_target_direction, v_last_modified_dtm, v_info_xml, v_parent_sid, v_pos, v_aggregate, 
			v_tolerance_type, v_pct_lower_tolerance, v_pct_upper_tolerance,
			v_tolerance_number_of_periods, v_tolerance_number_of_standard_deviations_from_average,
			v_factor_type_id, v_ind_activity_type_id, 
			v_gas_measure_sid, v_gas_type_id, v_map_to_ind_sid, v_factor_type_name, v_normalize,
			v_core, v_roll_forward, v_prop_down_region_tree_sid, v_is_system_managed, v_calc_fixed_start_dtm, v_calc_fixed_end_dtm,
			v_calc_output_round_dp, v_path, v_class_name	
	*/

END;

PROCEDURE TestGetIndicatorsForList
AS
	v_cur				SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetIndicatorsForList');

	indicator_pkg.GetIndicatorsForList(
		in_act_id			=>	security.security_pkg.GetAct,
		in_indicator_list	=>	''||v_test_ind_sid||'',
		out_cur				=>	v_cur
	);

	/* v_cur is:
			v_ind_sid,
			v_name,
			v_description,
			v_lookup_key,
			v_measure_name,
			v_measure_description,
			v_measure_sid,
			v_gri,
			v_multiplier,
			v_scale,
			v_format_mask,
			v_active,
			v_actual_scale,
			v_actual_format_mask,
			v_calc_xml,
			v_divisibility,
			v_actual_divisibility,
			v_start_month,
			v_node_type,
			v_ind_type,
			v_calc_start_dtm_adjustment,
			v_calc_end_dtm_adjustment,
			v_target_direction,
			v_last_modified_dtm,
			v_info_xml,
			v_parent_sid,
			v_pos, 
			v_tolerance_type,
			v_pct_lower_tolerance,
			v_pct_upper_tolerance,
			v_tolerance_number_of_periods,
			v_tolerance_number_of_standard_deviations_from_average,
			v_ind_activity_type_id,
			v_core,
			v_roll_forward	
	*/
END;

PROCEDURE TestGetTreeSinceDate
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetTreeSinceDate');

	v_ind_sids(1) := v_test_ind_sid;

	indicator_pkg.GetTreeSinceDate(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_modified_since_dtm			=>	SYSDATE-1,
		out_cur							=>	v_cur
	);

	-- todo check loop
END;

PROCEDURE TestGetTreeWithDepth
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetTreeWithDepth');

	v_ind_sids(1) := v_test_ind_sid;

	indicator_pkg.GetTreeWithDepth(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_fetch_depth					=>	1,
		out_cur							=>	v_cur
	);

	-- todo check loop

END;

PROCEDURE TestGetTreeWithSelect
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetTreeWithSelect');

	v_ind_sids(1) := v_test_ind_root_sid;

	indicator_pkg.GetTreeWithSelect(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_select_sid					=>	v_test_ind_sid,
		in_fetch_depth					=>	1,
		out_cur							=>	v_cur
	);

	-- todo check loop
END;

PROCEDURE TestGetTreeTextFiltered
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetTreeTextFiltered');

	v_ind_sids(1) := v_test_ind_root_sid;

	indicator_pkg.GetTreeTextFiltered(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_app_sid   					=>  security.security_pkg.GetApp,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_search_phrase				=>	'Test',
		out_cur							=>	v_cur
	);

	-- todo check loop
END;

PROCEDURE TestGetTreeTagFiltered
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetTreeTagFiltered');

	v_ind_sids(1) := v_test_ind_root_sid;

	indicator_pkg.GetTreeTagFiltered(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_app_sid   					=>  security.security_pkg.GetApp,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_search_phrase				=>	'Test',
		in_tag_group_count				=>	1,
		out_cur							=>	v_cur
	);

	-- todo check loop
END;

PROCEDURE TestGetListTagFiltered
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetListTagFiltered');

	v_ind_sids(1) := v_test_ind_root_sid;

	indicator_pkg.GetListTagFiltered(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_show_inactive				=>	1,
		in_search_phrase				=>	'Test',
		in_tag_group_count				=>	1,
		in_fetch_limit					=>	1,
		out_cur							=>	v_cur
	);

	-- todo check loop
END;

PROCEDURE TestGetListTextFiltered
AS
	v_ind_sids	security_pkg.T_SID_IDS;
	v_cur		SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('TestGetListTextFiltered');

	v_ind_sids(1) := v_test_ind_root_sid;

	indicator_pkg.GetListTextFiltered(
		in_act_id   					=>  security.security_pkg.GetAct,
		in_parent_sids					=>	v_ind_sids,
		in_include_root					=>	1,
		in_show_inactive				=>	1,
		in_search_phrase				=>	'Test',
		in_fetch_limit					=>	1,
		out_cur							=>	v_cur
	);

	-- todo check loop
END;

PROCEDURE TestSetActivityType AS
	v_count				NUMBER;
	
	v_sid_id			security_pkg.T_SID_ID;
	v_activity_type_id	ind_activity_type.ind_activity_type_id%TYPE;
	v_parent_sid_id		NUMBER;
	v_description		VARCHAR2(1024);
BEGIN
	unit_test_pkg.StartTest('TestSetActivityType');

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$tag_group
	 WHERE app_sid = security_pkg.getApp;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0, found '||v_count);


	v_sid_id := unit_test_pkg.GetOrCreateInd('INDICATOR_ACTIVITY_TYPE_TEST_1');
	SELECT ind_activity_type_id
	  INTO v_activity_type_id
	  FROM ind
	 WHERE ind_sid = v_sid_id
	   AND app_sid = security_pkg.getApp;
	unit_test_pkg.AssertIsTrue(v_activity_type_id IS NULL, 'Expected null, found '||v_activity_type_id);


	indicator_pkg.SetActivityType(
		in_ind_sid				=>	v_sid_id,
		in_activity_type_id		=>	1
	);
	SELECT ind_activity_type_id
	  INTO v_activity_type_id
	  FROM ind
	 WHERE ind_sid = v_sid_id
	   AND app_sid = security_pkg.getApp;
	unit_test_pkg.AssertIsTrue(v_activity_type_id = 1, 'Expected 1, found '||v_activity_type_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$tag_group
	 WHERE app_sid = security_pkg.getApp;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, found '||v_count);



	indicator_pkg.SetActivityType(
		in_ind_sid				=>	v_sid_id,
		in_activity_type_id		=>	2
	);
	SELECT ind_activity_type_id
	  INTO v_activity_type_id
	  FROM ind
	 WHERE ind_sid = v_sid_id
	   AND app_sid = security_pkg.getApp;
	unit_test_pkg.AssertIsTrue(v_activity_type_id = 2, 'Expected 2, found '||v_activity_type_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$tag_group
	 WHERE app_sid = security_pkg.getApp;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, found '||v_count);


	-- clean up
	IF v_sid_id IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid_id);
		v_sid_id := NULL;

		DELETE FROM TAG_GROUP_DESCRIPTION;
		DELETE FROM TAG_GROUP_MEMBER;
		DELETE FROM TAG_GROUP;
	END IF;
END;

PROCEDURE TestSetAggregateIndicator
AS
	v_ind_sid			security.security_pkg.T_SID_ID;
BEGIN
	unit_test_pkg.StartTest('TestSetAggregateIndicator');

	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestSetAggregateIndicator_IND_1');
	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_ind_sid,
		in_description 					=> 'TestSetAggregateIndicator_IND_1',
		in_lookup_key					=> 'TestSetAggregateIndicator_IND_1',
		in_tolerance_number_of_periods	=> 7,
		in_tolerance_number_of_standard_deviations_from_average => 5
	);

	indicator_pkg.SetAggregateIndicator(
		in_act_id			=>	security.security_pkg.GetAct,
		in_ind_sid			=>	v_ind_sid,
		in_is_aggregate_ind	=>	1
	);

	CheckTolerance('TestSetAggregateIndicator_IND_1', 7, 5);

	RemoveSid(v_ind_sid);
END;

PROCEDURE TestSetTolerance
AS
	v_ind_sid			security.security_pkg.T_SID_ID;
BEGIN
	unit_test_pkg.StartTest('TestSetTolerance');

	v_ind_sid := unit_test_pkg.GetOrCreateInd('TestSetTolerance_IND_1');
	indicator_pkg.AmendIndicator(
		in_ind_sid		 				=> v_ind_sid,
		in_description 					=> 'TestSetTolerance_IND_1',
		in_lookup_key					=> 'TestSetTolerance_IND_1',
		in_tolerance_number_of_periods	=> 6,
		in_tolerance_number_of_standard_deviations_from_average => 1
	);
	CheckTolerance('TestSetTolerance_IND_1', 6, 1);

	indicator_pkg.SetTolerance(
		in_act_id			=>	security.security_pkg.GetAct,
		in_ind_sid			=> 	v_ind_sid,
		in_tolerance_type	=>	1,
		in_lower_tolerance	=>	2,
		in_upper_tolerance	=>	3,
		in_tolerance_number_of_periods	=>	4,
		in_tolerance_number_of_standard_deviations_from_average	=>	5
	);

	CheckTolerance('TestSetTolerance_IND_1', 4, 5);

	RemoveSid(v_ind_sid);
END;


PROCEDURE TestSetTranslationAndUpdateGasChildren
AS
	v_ind1_sid	NUMBER;
	v_ind2_sid	NUMBER;
	v_desc		VARCHAR(200);
BEGIN
	unit_test_pkg.StartTest('TestSetTranslationAndUpdateGasChildren');

	v_ind1_sid := unit_test_pkg.GetOrCreateInd('TestSetTranslationAndUpdateGasChildren Ind1');
	indicator_pkg.SetTranslationAndUpdateGasChildren(
		in_ind_sid		=> 	v_ind1_sid,
		in_lang			=>	'en',
		in_description	=>	'TestSetTranslationAndUpdateGasChildren Ind1 en'
	);

	SELECT description
	  INTO v_desc
	  FROM v$ind
	 WHERE ind_sid = v_ind1_sid;

	unit_test_pkg.AssertAreEqual('TestSetTranslationAndUpdateGasChildren Ind1 en', v_desc, 'Unexpected desc');

	-- Create a non gas child ind
	v_ind2_sid := unit_test_pkg.GetOrCreateInd(
		in_lookup_key => 'TestSetTranslationAndUpdateGasChildren Ind2',
		in_parent_sid => v_ind1_sid);

	-- update parent and child should not change
	indicator_pkg.SetTranslationAndUpdateGasChildren(
		in_ind_sid		=> 	v_ind1_sid,
		in_lang			=>	'en',
		in_description	=>	'TestSetTranslationAndUpdateGasChildren Ind1 en 1'
	);

	SELECT description
	  INTO v_desc
	  FROM v$ind
	 WHERE ind_sid = v_ind1_sid;

	unit_test_pkg.AssertAreEqual('TestSetTranslationAndUpdateGasChildren Ind1 en 1', v_desc, 'Unexpected desc');

	SELECT description
	  INTO v_desc
	  FROM v$ind
	 WHERE ind_sid = v_ind2_sid;

	unit_test_pkg.AssertAreEqual('TestSetTranslationAndUpdateGasChildren Ind2', v_desc, 'Unexpected desc');

	-- create child gas inds, but without setting gas measure on the parent
	indicator_pkg.CreateGasIndicators(v_ind1_sid);
	indicator_pkg.SetTranslationAndUpdateGasChildren(
		in_ind_sid		=> 	v_ind1_sid,
		in_lang			=>	'en',
		in_description	=>	'TestSetTranslationAndUpdateGasChildren Ind1 en with gas'
	);

	SELECT description
	  INTO v_desc
	  FROM v$ind
	 WHERE ind_sid = v_ind1_sid;

	unit_test_pkg.AssertAreEqual('TestSetTranslationAndUpdateGasChildren Ind1 en with gas', v_desc, 'Unexpected desc');

	FOR r IN (
		SELECT description, ind_type, gas_type_id
		  FROM v$ind
		 WHERE parent_sid = v_ind1_sid
	) LOOP
		IF r.ind_type = 2 THEN
			TRACE('gasind: ' || r.description);
			IF r.gas_type_id = 1 THEN
				unit_test_pkg.AssertAreEqual('CO2 of TestSetTranslationAndUpdateGasChildren Ind1 en with gas', r.description, 'Unexpected desc');
			END IF;
			IF r.gas_type_id = 2 THEN
				unit_test_pkg.AssertAreEqual('CO2e of TestSetTranslationAndUpdateGasChildren Ind1 en with gas', r.description, 'Unexpected desc');
			END IF;
			IF r.gas_type_id = 3 THEN
				unit_test_pkg.AssertAreEqual('CH4 of TestSetTranslationAndUpdateGasChildren Ind1 en with gas', r.description, 'Unexpected desc');
			END IF;
			IF r.gas_type_id = 4 THEN
				unit_test_pkg.AssertAreEqual('N2O of TestSetTranslationAndUpdateGasChildren Ind1 en with gas', r.description, 'Unexpected desc');
			END IF;
		ELSE
			TRACE('normal ind: ' || r.description);
			unit_test_pkg.AssertAreEqual('TestSetTranslationAndUpdateGasChildren Ind2', r.description, 'Unexpected desc');
		END IF;
	END LOOP;


	security.securableobject_pkg.deleteso(security_pkg.getact, v_ind2_sid);
	security.securableobject_pkg.deleteso(security_pkg.getact, v_ind1_sid);
END;

--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');

	RemoveSid(v_test_ind_sid);

	security.user_pkg.logonadmin(v_site_name);
END;

END test_indicator_pkg;
/
