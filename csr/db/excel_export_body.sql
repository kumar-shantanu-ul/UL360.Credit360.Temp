CREATE OR REPLACE PACKAGE BODY CSR.excel_export_pkg AS

FUNCTION EmptySidIds
RETURN security_pkg.T_SID_IDS
AS
	v_empty_array	security_pkg.T_SID_IDS;
BEGIN
	RETURN v_empty_array;
END;

PROCEDURE GetOptions(
	in_dataview_sid						IN	security_pkg.T_SID_ID,
	out_cur_ee_options					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_ee_options_tg				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur_ee_options FOR
		SELECT
			ind_show_sid,
			ind_show_info,
			ind_show_tags,
			ind_show_gas_factor,
			region_show_sid,
			region_show_inactive,
			region_show_info,
			region_show_tags,
			region_show_type,
			region_show_ref,
			region_show_acquisition_dtm,
			region_show_disposal_dtm,
			region_show_roles,
			region_show_egrid,
			region_show_geo_country,
			meter_show_ref,
			meter_show_location,
			meter_show_source_type,
			meter_show_note,
			meter_show_crc,
			meter_show_ind,
			meter_show_measure,
			meter_show_cost_ind,
			meter_show_cost_measure,
			meter_show_days_ind,
			meter_show_supplier,
			meter_show_contract,
			scenario_pos
		  FROM excel_export_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND dataview_sid = in_dataview_sid;

	OPEN out_cur_ee_options_tg FOR
		SELECT eeotg.applies_to, eeotg.tag_group_id, tgd.name
		  FROM excel_export_options_tag_group eeotg
		  JOIN v$tag_group tgd ON 
			tgd.tag_group_id = eeotg.tag_group_id
			AND tgd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 WHERE eeotg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND eeotg.dataview_sid = in_dataview_sid;
END;

PROCEDURE SaveOptions(
	in_dataview_sid						IN	security_pkg.T_SID_ID,
	in_ind_show_sid						IN	excel_export_options.ind_show_sid%TYPE,
	in_ind_show_info					IN	excel_export_options.ind_show_info%TYPE,
	in_ind_show_tags					IN	excel_export_options.ind_show_tags%TYPE,
	in_ind_show_gas_factor				IN	excel_export_options.ind_show_gas_factor%TYPE,
	in_region_show_sid					IN	excel_export_options.region_show_sid%TYPE,
	in_region_show_inactive				IN	excel_export_options.region_show_inactive%TYPE,
	in_region_show_info					IN	excel_export_options.region_show_info%TYPE,
	in_region_show_tags					IN	excel_export_options.region_show_tags%TYPE,
	in_region_show_type					IN	excel_export_options.region_show_type%TYPE,
	in_region_show_ref					IN	excel_export_options.region_show_ref%TYPE,
	in_region_show_acquisition_dtm		IN	excel_export_options.region_show_acquisition_dtm%TYPE,
	in_region_show_disposal_dtm			IN	excel_export_options.region_show_disposal_dtm%TYPE,
	in_region_show_roles				IN	excel_export_options.region_show_roles%TYPE,
	in_region_show_egrid				IN	excel_export_options.region_show_egrid%TYPE,
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
)
AS
	v_ind_tag_sid_table					security.T_SID_TABLE;
	v_region_tag_sid_table				security.T_SID_TABLE;
	v_app_sid							security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');

BEGIN
	BEGIN
		INSERT INTO excel_export_options (
			dataview_sid,
			ind_show_sid,
			ind_show_info,
			ind_show_tags,
			ind_show_gas_factor,
			region_show_sid,
			region_show_inactive,
			region_show_info,
			region_show_tags,
			region_show_type,
			region_show_ref,
			region_show_acquisition_dtm,
			region_show_disposal_dtm,
			region_show_roles,
			region_show_egrid,
			region_show_geo_country,
			meter_show_ref,
			meter_show_location,
			meter_show_source_type,
			meter_show_note,
			meter_show_crc,
			meter_show_ind,
			meter_show_cost_ind,
			meter_show_cost_measure,
			meter_show_days_ind,	
			meter_show_measure,
			meter_show_supplier,
			meter_show_contract,
			scenario_pos
		) VALUES (
			in_dataview_sid,
			in_ind_show_sid,
			in_ind_show_info,
			in_ind_show_tags,
			in_ind_show_gas_factor,
			in_region_show_sid,
			in_region_show_inactive,
			in_region_show_info,
			in_region_show_tags,
			in_region_show_type,
			in_region_show_ref,
			in_region_show_acquisition_dtm,
			in_region_show_disposal_dtm,
			in_region_show_roles,
			in_region_show_egrid,
			in_region_show_geo_country,
			in_meter_show_ref,
			in_meter_show_location,
			in_meter_show_source_type,
			in_meter_show_note,
			in_meter_show_crc,
			in_meter_show_ind,
			in_meter_show_cost_ind,
			in_meter_show_cost_measure,
			in_meter_show_days_ind,
			in_meter_show_measure,
			in_meter_show_supplier,
			in_meter_show_contract,
			in_scenario_pos
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE excel_export_options
			   SET 	ind_show_sid = in_ind_show_sid,
					ind_show_info = in_ind_show_info,
					ind_show_tags = in_ind_show_tags,
					ind_show_gas_factor = in_ind_show_gas_factor,
					region_show_sid = in_region_show_sid,
					region_show_inactive = in_region_show_inactive,
					region_show_info = in_region_show_info,
					region_show_tags = in_region_show_tags,
					region_show_type = in_region_show_type,
					region_show_ref = in_region_show_ref,
					region_show_acquisition_dtm = in_region_show_acquisition_dtm,
					region_show_disposal_dtm = in_region_show_disposal_dtm,
					region_show_roles = in_region_show_roles,
					region_show_egrid = in_region_show_egrid,
					region_show_geo_country = in_region_show_geo_country,
					meter_show_ref = in_meter_show_ref,
					meter_show_location = in_meter_show_location,
					meter_show_source_type = in_meter_show_source_type,
					meter_show_note = in_meter_show_note,
					meter_show_crc = in_meter_show_crc,
					meter_show_ind = in_meter_show_ind,
					meter_show_cost_ind = in_meter_show_cost_ind,
					meter_show_cost_measure = in_meter_show_cost_measure,
					meter_show_days_ind = in_meter_show_days_ind,
					meter_show_measure = in_meter_show_measure,
					meter_show_supplier = in_meter_show_supplier,
					meter_show_contract = in_meter_show_contract,
					scenario_pos = in_scenario_pos
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   	   AND dataview_sid = in_dataview_sid;
	END;

	BEGIN
		v_ind_tag_sid_table := security_pkg.SidArrayToTable(in_ind_tag_sid_ids);
		v_region_tag_sid_table := security_pkg.SidArrayToTable(in_region_tag_sid_ids);

		-- Clear the existing category option and save new / modified option for the dataview.
		DELETE FROM csr.excel_export_options_tag_group
		 WHERE app_sid = v_app_sid
		   AND dataview_sid = in_dataview_sid;

		FOR i IN 1 .. v_ind_tag_sid_table.COUNT LOOP
			BEGIN
				INSERT INTO csr.excel_export_options_tag_group(
					app_sid,
					dataview_sid,
					applies_to,
					tag_group_id
				) VALUES(
					v_app_sid,
					in_dataview_sid,
					excel_export_pkg.applies_to_indicators,
					v_ind_tag_sid_table(i)
				);
			END;
		END LOOP;

		FOR i IN 1 .. v_region_tag_sid_table.COUNT LOOP
			BEGIN
				INSERT INTO csr.excel_export_options_tag_group(
					app_sid,
					dataview_sid,
					applies_to,
					tag_group_id
				) VALUES(
					v_app_sid,
					in_dataview_sid,
					excel_export_pkg.applies_to_regions,
					v_region_tag_sid_table(i)
				);
			END;
		END LOOP;
	END;
END;

END;
/