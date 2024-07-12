CREATE OR REPLACE PACKAGE BODY csr.test_excel_export_pkg AS

v_dataview_sid			security.security_pkg.T_SID_ID;
v_appsid				security.security_pkg.T_SID_ID;
v_tag_group_id_ind1		NUMBER;
v_tag_group_id_ind2		NUMBER;
v_tag_group_id_ind4		NUMBER;
v_tag_group_id_ind5		NUMBER;
v_tag_group_id_reg6		NUMBER;
v_tag_group_id_reg7		NUMBER;
v_tag_group_id_reg8		NUMBER;
v_tag_group_id_reg14	NUMBER;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_parent_sid				security.security_pkg.T_SID_ID;
	v_dataview_name				VARCHAR(10);
BEGIN

	security.user_pkg.logonadmin(in_site_name);
	v_appsid := SYS_CONTEXT('security', 'APP');

	SELECT sid_id INTO v_parent_sid FROM security.securable_object
	 WHERE application_sid_id = v_appsid
	   AND name = 'Dataviews'
	   AND parent_sid_id = v_appsid;

	v_dataview_name :=  DBMS_RANDOM.string('a', 10);
	
	csr.dataview_pkg.savedataview(
		in_dataview_sid => null,
		in_parent_sid => v_parent_sid,
		in_name => v_dataview_name,
		in_start_dtm => '01 JAN 2022',
		in_end_dtm => '31 DEC 2022',
		in_group_by => 'region',
		in_period_set_id => 1,
		in_period_interval_id => 1,
		in_chart_config_xml => null,
		in_chart_style_xml => null,
		in_description => v_dataview_name,
		in_dataview_type_id => 1,
		in_show_calc_trace => 0,
		in_show_variance => 0,
		in_show_abs_variance => 0,
		in_show_variance_explanations => 0,
		in_include_parent_region_names => 0,
		in_sort_by_most_recent => 0,
		in_treat_null_as_zero => 0,
		in_rank_limit_left => 0,
		in_rank_limit_left_type => 0,
		in_rank_limit_right => 0,
		in_rank_limit_right_type => 0,
		in_rank_ind_sid => null,
		in_rank_filter_type => 0,
		in_rank_reverse => 0,
		in_region_grouping_tag_group => null,
		in_anonymous_region_names => 0,
		in_include_notes_in_table => 0,
		in_show_region_events => 0,
		in_suppress_unmerged_data_msg => 0,
		in_highlight_changed_since => 0,
		in_highlight_changed_since_dtm => NULL,
		in_show_layer_variance_pct => 0,
		in_show_layer_variance_abs => 0,
		in_show_layer_var_pct_base => 0,
		in_show_layer_var_abs_base => 0,
		in_show_layer_variance_start => 0,
		in_aggregation_period_id => null,
		out_dataview_sid_id => v_dataview_sid
	);


	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_inds)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_ind1;
	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_inds)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_ind2;
	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_inds)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_ind4;
	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_inds)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_ind5;

	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_regions)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_reg6;
	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_regions)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_reg7;
	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_regions)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_reg8;
	INSERT INTO tag_group (tag_group_id, app_sid, applies_to_regions)
		VALUES (tag_group_id_seq.nextval, v_appsid, 1)
	RETURNING tag_group_id INTO v_tag_group_id_reg14;

END;

PROCEDURE TestSaveOptions
AS
	v_ee_old_count				NUMBER;
	v_ee_new_count				NUMBER;
	v_reg_cat_count				NUMBER;
	v_ind_cat_count				NUMBER;
	v_ind_cat_sids				security_pkg.T_SID_IDS;
	v_region_cat_sids			security_pkg.T_SID_IDS;

BEGIN
	DELETE FROM excel_export_options
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid;

	SELECT COUNT(*) INTO v_ee_old_count
	  FROM excel_export_options
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid;

	v_ind_cat_sids(0) := v_tag_group_id_ind2;
	v_ind_cat_sids(1) := v_tag_group_id_ind5;
	v_ind_cat_sids(2) := v_tag_group_id_ind1;
	v_region_cat_sids(0) := v_tag_group_id_reg6;
	v_region_cat_sids(1) := v_tag_group_id_reg7;
	v_region_cat_sids(2) := v_tag_group_id_reg8;

	excel_export_pkg.SaveOptions(
		in_dataview_sid						=>	v_dataview_sid,
		in_ind_show_sid						=>	1,
		in_ind_show_info					=>	1,
		in_ind_show_tags					=>	1,
		in_ind_show_gas_factor				=>	1,
		in_region_show_sid 					=>	1,
		in_region_show_inactive				=>	1,
		in_region_show_info					=>	1,
		in_region_show_tags					=>	1,
		in_region_show_type					=>	1,
		in_region_show_ref 					=>	1,
		in_region_show_acquisition_dtm		=>	1,
		in_region_show_disposal_dtm			=>	1,
		in_region_show_roles 				=>	1,
		in_region_show_egrid 				=>	1,
		in_region_show_geo_country			=>	1,
		in_meter_show_ref					=>	1,
		in_meter_show_location 				=>	1,
		in_meter_show_source_type			=>	1,
		in_meter_show_note 					=>	1,
		in_meter_show_crc					=>	1,
		in_meter_show_ind					=>	1,
		in_meter_show_measure				=>	1,
		in_meter_show_cost_ind				=>	1,
		in_meter_show_cost_measure			=>	1,
		in_meter_show_days_ind				=>	1,
		in_meter_show_supplier 				=>	1,
		in_meter_show_contract				=>	1,
		in_scenario_pos						=>	'Column',
		in_ind_tag_sid_ids					=>	v_ind_cat_sids,
		in_region_tag_sid_ids				=>	v_region_cat_sids
	);

	SELECT COUNT(*) INTO v_ee_new_count
	  FROM excel_export_options
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid;

	SELECT COUNT(*) INTO v_reg_cat_count
	  FROM excel_export_options_tag_group
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid
	   AND applies_to = excel_export_pkg.applies_to_regions;

	SELECT COUNT(*) INTO v_ind_cat_count
	  FROM excel_export_options_tag_group
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid
	   AND applies_to = excel_export_pkg.applies_to_indicators;

	unit_test_pkg.AssertAreEqual((v_ee_old_count+ 1), v_ee_new_count, 'New Export Options must be added');
	unit_test_pkg.AssertAreEqual(v_ind_cat_count, v_ind_cat_sids.Count, 'Indicator Categories should be added');
	unit_test_pkg.AssertAreEqual(v_reg_cat_count, v_region_cat_sids.Count, 'Region Categories should be added');
END;

PROCEDURE TestUpdateOptions
AS
	v_ee_old_count				NUMBER;
	v_ee_new_count				NUMBER;
	v_reg_cat_count				NUMBER;
	v_ind_cat_count				NUMBER;
	v_ind_cat_sids				security_pkg.T_SID_IDS;
	v_region_cat_sids			security_pkg.T_SID_IDS;

BEGIN

	v_ind_cat_sids(0) := v_tag_group_id_ind1;
	v_ind_cat_sids(1) := v_tag_group_id_ind2;
	v_ind_cat_sids(2) := v_tag_group_id_ind5;
	v_region_cat_sids(0) := v_tag_group_id_reg6;
	v_region_cat_sids(1) := v_tag_group_id_reg7;
	v_region_cat_sids(2) := v_tag_group_id_reg8;

	excel_export_pkg.SaveOptions(
		in_dataview_sid						=>	v_dataview_sid,
		in_ind_show_sid						=>	1,
		in_ind_show_info					=>	1,
		in_ind_show_tags					=>	1,
		in_ind_show_gas_factor				=>	1,
		in_region_show_sid 					=>	1,
		in_region_show_inactive				=>	1,
		in_region_show_info					=>	1,
		in_region_show_tags					=>	1,
		in_region_show_type					=>	1,
		in_region_show_ref 					=>	1,
		in_region_show_acquisition_dtm		=>	1,
		in_region_show_disposal_dtm			=>	1,
		in_region_show_roles 				=>	1,
		in_region_show_egrid 				=>	1,
		in_region_show_geo_country			=>	1,
		in_meter_show_ref					=>	1,
		in_meter_show_location 				=>	1,
		in_meter_show_source_type			=>	1,
		in_meter_show_note 					=>	1,
		in_meter_show_crc					=>	1,
		in_meter_show_ind					=>	1,
		in_meter_show_measure				=>	1,
		in_meter_show_cost_ind				=>	1,
		in_meter_show_cost_measure			=>	1,
		in_meter_show_days_ind				=>	1,
		in_meter_show_supplier 				=>	1,
		in_meter_show_contract				=>	1,
		in_scenario_pos						=>	'Column',
		in_ind_tag_sid_ids					=>	v_ind_cat_sids,
		in_region_tag_sid_ids				=>	v_region_cat_sids
	);

	v_ind_cat_sids.DELETE();
	v_region_cat_sids.DELETE();
	v_ind_cat_sids(0) := v_tag_group_id_ind4;
	v_region_cat_sids(0) := v_tag_group_id_reg14;

	excel_export_pkg.SaveOptions(
		in_dataview_sid						=>	v_dataview_sid,
		in_ind_show_sid						=>	1,
		in_ind_show_info					=>	1,
		in_ind_show_tags					=>	1,
		in_ind_show_gas_factor				=>	1,
		in_region_show_sid 					=>	1,
		in_region_show_inactive				=>	1,
		in_region_show_info					=>	1,
		in_region_show_tags					=>	1,
		in_region_show_type					=>	1,
		in_region_show_ref 					=>	1,
		in_region_show_acquisition_dtm		=>	1,
		in_region_show_disposal_dtm			=>	1,
		in_region_show_roles 				=>	1,
		in_region_show_egrid 				=>	1,
		in_region_show_geo_country			=>	1,
		in_meter_show_ref					=>	1,
		in_meter_show_location 				=>	1,
		in_meter_show_source_type			=>	1,
		in_meter_show_note 					=>	1,
		in_meter_show_crc					=>	1,
		in_meter_show_ind					=>	1,
		in_meter_show_measure				=>	1,
		in_meter_show_cost_ind				=>	1,
		in_meter_show_cost_measure			=>	1,
		in_meter_show_days_ind				=>	1,
		in_meter_show_supplier 				=>	1,
		in_meter_show_contract				=>	1,
		in_scenario_pos						=>	'Column',
		in_ind_tag_sid_ids					=>	v_ind_cat_sids,
		in_region_tag_sid_ids				=>	v_region_cat_sids
	);
	
	SELECT COUNT(*) INTO v_reg_cat_count
	  FROM excel_export_options_tag_group
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid
	   AND applies_to = excel_export_pkg.applies_to_regions;

	SELECT COUNT(*) INTO v_ind_cat_count
	  FROM excel_export_options_tag_group
	 WHERE app_sid = v_appsid
	   AND dataview_sid = v_dataview_sid
	   AND applies_to = excel_export_pkg.applies_to_indicators;

	unit_test_pkg.AssertAreEqual(v_ind_cat_count, v_ind_cat_sids.Count, 'Indicator Categories should be updated');
	unit_test_pkg.AssertAreEqual(v_reg_cat_count, v_region_cat_sids.Count, 'Region Categories should be updated');
END;

PROCEDURE TestGetOptions
AS
	v_ind_cat_sids							security_pkg.T_SID_IDS;
	v_region_cat_sids						security_pkg.T_SID_IDS;
	v_out_cur_ee_option						security_pkg.T_OUTPUT_CUR;
	v_out_cur_ee_tg							security_pkg.T_OUTPUT_CUR;
	TYPE ee_options_rec IS RECORD(
		v_ind_show_sid						excel_export_options.ind_show_sid%TYPE,
		v_ind_show_info						excel_export_options.ind_show_info%TYPE,
		v_ind_show_tags						excel_export_options.ind_show_tags%TYPE,
		v_ind_show_gas_factor				excel_export_options.ind_show_gas_factor%TYPE,
		v_region_show_sid					excel_export_options.region_show_sid%TYPE,
		v_region_show_inactive				excel_export_options.region_show_inactive%TYPE,
		v_region_show_info					excel_export_options.region_show_info%TYPE,
		v_region_show_tags					excel_export_options.region_show_tags%TYPE,
		v_region_show_type					excel_export_options.region_show_type%TYPE,
		v_region_show_ref					excel_export_options.region_show_ref%TYPE,
		v_region_show_acquisition_dtm		excel_export_options.region_show_acquisition_dtm%TYPE,
		v_region_show_disposal_dtm			excel_export_options.region_show_disposal_dtm%TYPE,
		v_region_show_roles					excel_export_options.region_show_roles%TYPE,
		v_region_show_egrid					excel_export_options.region_show_egrid%TYPE,
		v_region_show_geo_country			excel_export_options.region_show_geo_country%TYPE,
		v_meter_show_ref					excel_export_options.meter_show_ref%TYPE,
		v_meter_show_location				excel_export_options.meter_show_location%TYPE,
		v_meter_show_source_type			excel_export_options.meter_show_source_type%TYPE,
		v_meter_show_note					excel_export_options.meter_show_note%TYPE,
		v_meter_show_crc					excel_export_options.meter_show_crc%TYPE,
		v_meter_show_ind					excel_export_options.meter_show_ind%TYPE,
		v_meter_show_measure				excel_export_options.meter_show_measure%TYPE,
		v_meter_show_cost_ind				excel_export_options.meter_show_cost_ind%TYPE,
		v_meter_show_cost_measure			excel_export_options.meter_show_cost_measure%TYPE,
		v_meter_show_days_ind				excel_export_options.meter_show_days_ind%TYPE,
		v_meter_show_supplier				excel_export_options.meter_show_supplier%TYPE,
		v_meter_show_contract				excel_export_options.meter_show_contract%TYPE,
		v_scenario_pos						excel_export_options.scenario_pos%TYPE
	);
	v_ee_options_rec						ee_options_rec;

BEGIN
	excel_export_pkg.SaveOptions(
		in_dataview_sid						=>	v_dataview_sid,
		in_ind_show_sid						=>	1,
		in_ind_show_info					=>	1,
		in_ind_show_tags					=>	0,
		in_ind_show_gas_factor				=>	1,
		in_region_show_sid 					=>	1,
		in_region_show_inactive				=>	1,
		in_region_show_info					=>	1,
		in_region_show_tags					=>	1,
		in_region_show_type					=>	1,
		in_region_show_ref 					=>	1,
		in_region_show_acquisition_dtm		=>	1,
		in_region_show_disposal_dtm			=>	1,
		in_region_show_roles 				=>	1,
		in_region_show_egrid 				=>	1,
		in_region_show_geo_country			=>	1,
		in_meter_show_ref					=>	1,
		in_meter_show_location 				=>	1,
		in_meter_show_source_type			=>	1,
		in_meter_show_note 					=>	1,
		in_meter_show_crc					=>	1,
		in_meter_show_ind					=>	1,
		in_meter_show_measure				=>	1,
		in_meter_show_cost_ind				=>	1,
		in_meter_show_cost_measure			=>	1,
		in_meter_show_days_ind				=>	1,
		in_meter_show_supplier 				=>	1,
		in_meter_show_contract				=>	1,
		in_scenario_pos						=>	'Column',
		in_ind_tag_sid_ids					=>	v_ind_cat_sids,
		in_region_tag_sid_ids				=>	v_region_cat_sids
	);

	excel_export_pkg.GetOptions(v_dataview_sid, v_out_cur_ee_option, v_out_cur_ee_tg);

	FETCH v_out_cur_ee_option INTO v_ee_options_rec;
	CLOSE v_out_cur_ee_option;

	unit_test_pkg.AssertIsFalse(sys.diutil.INT_TO_BOOL(v_ee_options_rec.v_ind_show_tags), 'Indicator Show Tag must be false');
	unit_test_pkg.AssertIsTrue(sys.diutil.INT_TO_BOOL(v_ee_options_rec.v_region_show_tags), 'Region Show Category must be true');
END;

PROCEDURE TearDownFixture
AS
BEGIN
	csr.dataview_pkg.DeleteObject(SYS_CONTEXT('SECURITY', 'ACT'), v_dataview_sid);

	DELETE FROM tag_group
	 WHERE tag_group_id IN (
		v_tag_group_id_ind1,
		v_tag_group_id_ind2,
		v_tag_group_id_ind4,
		v_tag_group_id_ind5,
		v_tag_group_id_reg6,
		v_tag_group_id_reg7,
		v_tag_group_id_reg8,
		v_tag_group_id_reg14
	);
END;

END test_excel_export_pkg;
/