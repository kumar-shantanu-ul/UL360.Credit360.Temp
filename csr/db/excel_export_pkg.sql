CREATE OR REPLACE PACKAGE CSR.excel_export_pkg AS

FUNCTION EmptySidIds
RETURN security_pkg.T_SID_IDS;

APPLIES_TO_INDICATORS			CONSTANT NUMBER := 1;
APPLIES_TO_REGIONS				CONSTANT NUMBER := 2;

PROCEDURE GetOptions(
	in_dataview_sid						IN	security_pkg.T_SID_ID,
	out_cur_ee_options					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_ee_options_tg				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveOptions(
	in_dataview_sid						IN	security_pkg.T_SID_ID,
	in_ind_show_sid						IN	excel_export_options.ind_show_sid%TYPE,
	in_ind_show_info					IN	excel_export_options.ind_show_info%TYPE,
	in_ind_show_tags					IN	excel_export_options.ind_show_tags%TYPE,
	in_ind_show_gas_factor				IN	excel_export_options.ind_show_gas_factor%TYPE,
	in_region_show_sid 					IN	excel_export_options.region_show_sid%TYPE,
	in_region_show_inactive				IN	excel_export_options.region_show_inactive%TYPE,
	in_region_show_info					IN	excel_export_options.region_show_info%TYPE,
	in_region_show_tags					IN	excel_export_options.region_show_tags%TYPE,
	in_region_show_type					IN	excel_export_options.region_show_type%TYPE,
	in_region_show_ref 					IN	excel_export_options.region_show_ref%TYPE,
	in_region_show_acquisition_dtm		IN	excel_export_options.region_show_acquisition_dtm%TYPE,
	in_region_show_disposal_dtm			IN	excel_export_options.region_show_disposal_dtm%TYPE,
	in_region_show_roles 				IN	excel_export_options.region_show_roles%TYPE,
	in_region_show_egrid 				IN	excel_export_options.region_show_egrid%TYPE,
	in_region_show_geo_country			IN	excel_export_options.region_show_geo_country%TYPE,
	in_meter_show_ref					IN	excel_export_options.meter_show_ref%TYPE,
	in_meter_show_location 				IN	excel_export_options.meter_show_location%TYPE,
	in_meter_show_source_type			IN	excel_export_options.meter_show_source_type%TYPE,
	in_meter_show_note 					IN	excel_export_options.meter_show_note%TYPE,
	in_meter_show_crc					IN	excel_export_options.meter_show_crc%TYPE,
	in_meter_show_ind					IN	excel_export_options.meter_show_ind%TYPE,
	in_meter_show_measure				IN	excel_export_options.meter_show_measure%TYPE,
	in_meter_show_cost_ind				IN	excel_export_options.meter_show_cost_ind%TYPE,
	in_meter_show_cost_measure			IN	excel_export_options.meter_show_cost_measure%TYPE,
	in_meter_show_days_ind				IN	excel_export_options.meter_show_days_ind%TYPE,
	in_meter_show_supplier 				IN	excel_export_options.meter_show_supplier%TYPE,
	in_meter_show_contract				IN	excel_export_options.meter_show_supplier%TYPE,
	in_scenario_pos						IN	excel_export_options.scenario_pos%TYPE,
	in_ind_tag_sid_ids					IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_region_tag_sid_ids				IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds
);

END;
/