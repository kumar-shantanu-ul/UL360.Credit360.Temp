CREATE OR REPLACE PACKAGE csr.osha_pkg AS

PROCEDURE GetOshaMappings(
	out_osha_mappings_cur			OUT	SYS_REFCURSOR,
	out_osha_types_cur				OUT SYS_REFCURSOR
);

PROCEDURE SaveOshaMappings(
	in_osha_map_field_id			IN	osha_mapping.osha_map_field_id%TYPE,
	in_ind_sid						IN	osha_mapping.ind_sid%TYPE,
	in_cms_col_sid					IN	osha_mapping.cms_col_sid%TYPE,
	in_region_data_id				IN	osha_mapping.region_data_map_id%TYPE
);

PROCEDURE GetOshaConfig(
	out_osha_config_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SaveOshaConfig(
	in_cms_tab_sid					IN	osha_config.cms_tab_sid%TYPE,
	in_date_cms_col_sid				IN	osha_config.date_cms_col_sid%TYPE,
	in_region_cms_col_sid			IN	osha_config.region_cms_col_sid%TYPE
);

PROCEDURE GetOshaMapTypes(
	out_osha_map_types_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetOshaBaseData(
	out_osha_base_data_cur				OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetOsha300AMappingData(
	out_osha_mappings_cur			OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetOshaMappingData(
	out_osha_mappings_cur			OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetOshaConfig(
	out_osha_config_cur				OUT	SYS_REFCURSOR
);

END;
/
