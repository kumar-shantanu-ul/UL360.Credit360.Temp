CREATE OR REPLACE PACKAGE BODY csr.osha_pkg AS

PROCEDURE GetOshaMappings(
	out_osha_mappings_cur			OUT	SYS_REFCURSOR,
	out_osha_types_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to read OSHA mappings');
	END IF;	
	
	OPEN out_osha_mappings_cur FOR
		SELECT omf.osha_map_field_id, omf.label, omf.pos, omp.ind_sid, omp.cms_col_sid, dsc.description as ind_description, omp.region_data_map_id, rdm.description region_data_map_desc
		  FROM osha_map_field omf
		  LEFT JOIN osha_mapping omp ON omf.osha_map_field_id = omp.osha_map_field_id AND omp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN v$ind dsc ON omp.ind_sid = dsc.ind_sid AND dsc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN region_data_map rdm ON omp.region_data_map_id = rdm.region_data_map_id
		 ORDER BY omf.pos;
		 
	OPEN out_osha_types_cur FOR
		SELECT osha_map_field_id, osha_map_type_id
		  FROM osha_map_field_type;
END;

PROCEDURE SaveOshaMappings(
	in_osha_map_field_id			IN	osha_mapping.osha_map_field_id%TYPE,
	in_ind_sid						IN	osha_mapping.ind_sid%TYPE,
	in_cms_col_sid					IN	osha_mapping.cms_col_sid%TYPE,
	in_region_data_id				IN	osha_mapping.region_data_map_id%TYPE
)
AS
	v_upsert_check	NUMBER(1);
	v_data_type		NUMBER(1);
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to save OSHA mappings');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_upsert_check
	  FROM osha_mapping
	 WHERE app_sid = v_app_sid
	   AND osha_map_field_id = in_osha_map_field_id;

	IF v_upsert_check = 0 THEN
		INSERT INTO osha_mapping
		(app_sid, osha_map_field_id, ind_sid, cms_col_sid, region_data_map_id)
		VALUES
		(v_app_sid, in_osha_map_field_id, in_ind_sid, in_cms_col_sid, in_region_data_id);
	ELSE
		UPDATE osha_mapping
		   SET osha_map_field_id = in_osha_map_field_id,
			   ind_sid = in_ind_sid, 
			   cms_col_sid = in_cms_col_sid,
			   region_data_map_id = in_region_data_id
		 WHERE app_sid = v_app_sid
		   AND osha_map_field_id = in_osha_map_field_id;
	END IF;
END;


PROCEDURE GetOshaConfig(
	out_osha_config_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to read OSHA config');
	END IF;

	UNSEC_GetOshaConfig(out_osha_config_cur);
END;

PROCEDURE SaveOshaConfig(
	in_cms_tab_sid					IN	osha_config.cms_tab_sid%TYPE,
	in_date_cms_col_sid				IN	osha_config.date_cms_col_sid%TYPE,
	in_region_cms_col_sid			IN	osha_config.region_cms_col_sid%TYPE
)
AS
	v_upsert_check					NUMBER(1);
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to save OSHA config');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_upsert_check
	  FROM osha_config
	 WHERE app_sid = v_app_sid;

	IF v_upsert_check = 0 THEN
		INSERT INTO osha_config
		(app_sid, cms_tab_sid, date_cms_col_sid, region_cms_col_sid)
		VALUES
		(v_app_sid, in_cms_tab_sid, in_date_cms_col_sid, in_region_cms_col_sid);
	ELSE
		UPDATE osha_config
		   SET cms_tab_sid = in_cms_tab_sid, 
			   date_cms_col_sid = in_date_cms_col_sid,
			   region_cms_col_sid = in_region_cms_col_sid
		 WHERE app_sid = v_app_sid;
	END IF;
END;

PROCEDURE GetOshaMapTypes(
	out_osha_map_types_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_osha_map_types_cur FOR
		SELECT osha_map_type_id, label
		  FROM osha_map_type;
END;

PROCEDURE GetOshaBaseData(
	out_osha_base_data_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_osha_base_data_cur FOR
		SELECT obd.osha_base_data_id, obd.data_element, obd.agg_type, obd.definition_and_validations, obd.format, obd.length, obd.required, obd.osha_map_field_id
		  FROM osha_base_data obd;
END;

--Export
--Used for osha csv export, no permission check required
PROCEDURE UNSEC_GetOsha300AMappingData(
	out_osha_mappings_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_osha_mappings_cur FOR
		SELECT obd.osha_base_data_id, obd.data_element, obd.agg_type, obd.required, om.ind_sid, om.cms_col_sid, om.region_data_map_id
		  FROM osha_base_data obd
		  JOIN osha_map_field omf ON obd.osha_map_field_id = omf.osha_map_field_id
		  LEFT JOIN osha_mapping om ON omf.osha_map_field_id = om.osha_map_field_id AND om.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

--Export
--Used for osha excel export, no permission check required
PROCEDURE UNSEC_GetOshaMappingData(
	out_osha_mappings_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_osha_mappings_cur FOR
		SELECT omf.label, NVL(obd.osha_base_data_id, 0) AS osha_base_data_id,
			NVL(obd.data_element, SUBSTR(regexp_replace(REPLACE(LOWER(omf.label), ' ', '_'), '[''|.|,|/]', ''), 0, 35)) AS data_element, 
			NVL(obd.agg_type, 0) AS agg_type, NVL(obd.required, 0) AS required, om.ind_sid, om.cms_col_sid, om.region_data_map_id
		FROM csr.osha_map_field omf
		LEFT JOIN csr.osha_base_data obd ON omf.osha_map_field_id = obd.osha_map_field_id
		LEFT JOIN csr.osha_mapping om ON omf.osha_map_field_id = om.osha_map_field_id AND om.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

--Used for osha export, no permission check required
PROCEDURE UNSEC_GetOshaConfig(
	out_osha_config_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_osha_config_cur FOR
		SELECT MIN(cms_tab_sid) cms_tab_sid, MIN(date_cms_col_sid) date_cms_col_sid, MIN(region_cms_col_sid) region_cms_col_sid
		  FROM osha_config
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END;
/