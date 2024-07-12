CREATE OR REPLACE PACKAGE CSR.space_pkg IS

PROCEDURE CreateSpace(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	region_description.description%TYPE,
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_region_ref		IN  region.region_ref%TYPE DEFAULT NULL,
	in_active			IN	region.active%TYPE DEFAULT 1,
	in_disposal_dtm		IN	region.disposal_dtm%TYPE DEFAULT NULL,
	out_region_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE UpdateSpace(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	region_description.description%TYPE,
	in_space_type_id	IN	space_type.space_type_id%TYPE	DEFAULT NULL,
	in_active			IN	region.active%TYPE,
	in_disposal_dtm		IN	region.disposal_dtm%TYPE
);

PROCEDURE RemoveSpace(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE MakeSpace(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_space_type_id		IN	space.space_type_id%TYPE DEFAULT NULL,
	in_is_create			IN	NUMBER
);

PROCEDURE UnmakeSpace(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_type			IN	region.region_type%TYPE
);

PROCEDURE GetSpace(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpace(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_region_ref		IN	region.region_ref%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateMeter(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id				IN	meter_type.meter_type_id%TYPE,
	in_description				IN	region_description.description%TYPE,
	in_reference				IN	all_meter.reference%TYPE DEFAULT NULL,
	in_note						IN	all_meter.note%TYPE	DEFAULT NULL,
	in_source_type_id			IN  all_meter.meter_source_type_id%TYPE DEFAULT 2, -- arbitrary period
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_consump_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_cost_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_active					IN	region.active%TYPE,
	in_acquisition_dtm			IN	region.acquisition_dtm%TYPE,
	in_disposal_dtm				IN	region.disposal_dtm%TYPE,
	out_region_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE AmendMeter(
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_change_reason			IN  VARCHAR2,
	in_meter_type_id				IN	meter_type.meter_type_id%TYPE,
	in_description				IN	region_description.description%TYPE,
	in_reference				IN	all_meter.reference%TYPE DEFAULT NULL,
	in_note						IN	all_meter.note%TYPE	DEFAULT NULL,
	in_source_type_id			IN  all_meter.meter_source_type_id%TYPE DEFAULT 2, -- arbitrary period
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_consump_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_cost_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_active					IN	region.active%TYPE,
	in_acquisition_dtm			IN	region.acquisition_dtm%TYPE,
	in_disposal_dtm				IN	region.disposal_dtm%TYPE
);

END;
/
