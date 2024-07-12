CREATE OR REPLACE PACKAGE CSR.energy_star_attr_pkg IS

PROCEDURE SetType(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_basic_type		IN	est_attr_type.basic_type%TYPE
);

PROCEDURE SetBuildingAttr(
	in_attr_name		IN	est_attr_for_building.attr_name%TYPE,
	in_type_name		IN	est_attr_for_building.type_name%TYPE,
	in_is_mandatory		IN	est_attr_for_building.is_mandatory%TYPE
);

PROCEDURE SetSpaceAttr(
	in_attr_name		IN	est_attr_for_space.attr_name%TYPE,
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_notes			IN	est_attr_for_space.notes%TYPE
);

PROCEDURE SetUnit(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_uom				IN	est_attr_unit.uom%TYPE
);

PROCEDURE SetEnum(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_enum				IN	est_attr_enum.enum%TYPE,
	in_pos				IN	est_attr_enum.pos%TYPE
);

PROCEDURE SetSpaceTypeAttr(
	in_est_space_type	IN	est_space_type_attr.est_space_type%TYPE,
	in_attr_name		IN	est_space_type_attr.attr_name%TYPE,
	in_is_mandatory		IN	est_space_type_attr.is_mandatory%TYPE
);

PROCEDURE InstallPropertyTypes
;

PROCEDURE InstallSpaceTypes
;

PROCEDURE GetAttributeData(
	in_est_account_sid	IN	security_pkg.T_SID_ID,
	out_attrs			OUT	security_pkg.T_OUTPUT_CUR,
	out_types			OUT	security_pkg.T_OUTPUT_CUR,
	out_enums			OUT	security_pkg.T_OUTPUT_CUR,
	out_units			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetMeasure(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_measure_sid		IN	security_pkg.T_SID_ID,
	in_uoms				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_conv_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetIndicators(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateIndicator(
	in_attr_name		IN	est_attr_for_space.attr_name%TYPE,	
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MapIndicator(
	in_attr_name		IN	est_attr_for_space.attr_name%TYPE,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAttributeMappings(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	in_attr_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_ind_sids				IN	security_pkg.T_SID_IDS,
	in_uoms					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_convs				IN	security_pkg.T_SID_IDS,
	in_space_flags			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetMeterTypes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEnergyStarMeterTypes(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	out_types				OUT	security_pkg.T_OUTPUT_CUR,
	out_convs				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetMeterType(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	in_meter_type			IN	est_meter_type_mapping.meter_type%TYPE,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_uoms					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_convs				IN	security_pkg.T_SID_IDS
);

END;
/
