CREATE OR REPLACE PACKAGE BODY CSR.space_pkg IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_Id
)
AS
	v_helper_pkg		property_options.property_helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one, to setup custom forms
	BEGIN
		SELECT property_helper_pkg
		  INTO v_helper_pkg
		  FROM property_options
		 WHERE app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;
	
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1);end;'
				USING in_region_sid;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE CreateSpace(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	region_description.description%TYPE,
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_region_ref		IN  region.region_ref%TYPE DEFAULT NULL,
	in_active			IN	region.active%TYPE DEFAULT 1,
	in_disposal_dtm		IN	region.disposal_dtm%TYPE DEFAULT NULL,
	out_region_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_property_type_id  property.property_type_id%TYPE;
BEGIN
	-- create region will do our permission checks
	region_pkg.CreateRegion(
		in_parent_sid	=> in_parent_sid,
		in_name			=> REPLACE(in_description,'/','\'), --'
		in_description	=> in_description,
		in_region_type	=> csr_data_pkg.REGION_TYPE_SPACE,
		in_region_ref	=> in_region_ref,
		in_active		=> in_active,
		in_disposal_dtm	=> in_disposal_dtm,
		out_region_sid	=> out_region_sid
	);
	
	SELECT property_type_id
	  INTO v_property_type_id
	  FROM property
	 WHERE region_sid = in_parent_sid;

	INSERT INTO all_space (region_sid, space_type_id, property_region_sid, property_type_id)
		VALUES (out_region_sid, in_space_type_id, in_parent_sid, v_property_type_id);
	
	
	CallHelperPkg('SpaceCreated', out_region_sid);
	
	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(out_region_sid);
END;

PROCEDURE UpdateSpace(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	region_description.description%TYPE,
	in_space_type_id	IN	space_type.space_type_id%TYPE	DEFAULT NULL,
	in_active			IN	region.active%TYPE,
	in_disposal_dtm		IN	region.disposal_dtm%TYPE
)
AS
	v_property_sid		NUMBER(10);
	v_property_type_id	NUMBER(10);
	CURSOR c IS
		SELECT active, geo_type, info_xml, region_ref, acquisition_dtm, region_type
		  FROM region
		 WHERE region_Sid = in_region_sid;
	r c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	CLOSE c;

	-- create region will do our permission checks
	region_pkg.AmendRegion(
		in_act_id			=> SYS_CONTEXT('SECURITY','ACT'), 
		in_region_sid		=> in_region_sid,
		in_description		=> in_description,
		in_active			=> in_active,
		in_pos				=> 0,
		in_geo_type			=> region_pkg.REGION_GEO_TYPE_INHERITED,
		in_info_xml			=> r.info_xml,
		in_geo_country		=> null, 
		in_geo_region		=> null, 
		in_geo_city			=> null, 
		in_map_entity		=> null, 
		in_egrid_ref		=> null, 
		in_region_ref		=> r.region_ref,
		in_acquisition_dtm	=> r.acquisition_dtm,
		in_disposal_dtm		=> in_disposal_Dtm,
		in_region_type		=> csr_data_pkg.REGION_TYPE_SPACE
	);
	
	-- Get the details we need about the property. Assume it's the parent of the space.
	SELECT r.parent_sid, p.property_type_id
	  INTO v_property_sid, v_property_type_id
	  FROM csr.region r
	  JOIN csr.v$property p ON p.region_sid = r.parent_sid
	 WHERE r.region_sid = in_region_sid;

	BEGIN
		INSERT INTO all_space (region_sid, space_type_id, property_region_sid, property_type_id)
		VALUES (in_region_sid, in_space_type_id, v_property_sid, v_property_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_space
			   SET space_type_id = NVL(in_space_type_id, space_type_id)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid;
	END;
		
	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

PROCEDURE RemoveSpace(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting space with sid '||in_region_sid);
	END IF;
	
	region_pkg.TrashObject(in_act_id, in_region_sid);
END;

PROCEDURE MakeSpace(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_space_type_id		IN	space.space_type_id%TYPE DEFAULT NULL,
	in_is_create			IN	NUMBER
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_property_type_id  property.property_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to space with sid '||in_region_sid);
	END IF;

	SELECT parent_sid
	  INTO v_parent_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	SELECT property_type_id
	  INTO v_property_type_id
	  FROM property
	 WHERE region_sid = v_parent_sid;
	
	region_pkg.SetRegionType(in_region_sid, csr_data_pkg.REGION_TYPE_SPACE);

	BEGIN
		INSERT INTO all_space (region_sid, space_type_id, property_region_sid, property_type_id)
				   VALUES (in_region_sid, in_space_type_id, v_parent_sid, v_property_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_space
			   SET space_type_id = in_space_type_id,
			       property_type_id = v_property_type_id
			 WHERE region_sid = in_region_sid;
	END;

	IF in_is_create = 1 THEN
		CallHelperPkg('SpaceCreated', in_region_sid);
	END IF;
	
	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);

END;

PROCEDURE UnmakeSpace(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_type			IN	region.region_type%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to space with sid '||in_region_sid);
	END IF;

	-- Set region type to new type
	region_pkg.SetRegionType(in_region_sid, in_region_type);
	
	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

PROCEDURE GetSpace(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_region_ref		IN	region.region_ref%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_space_sid			security_pkg.T_SID_ID;
BEGIN
	-- security check
	IF in_parent_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_parent_sid);
		END IF;		
	END IF;
	
	SELECT region_sid
	  INTO v_space_sid
	  FROM v$region
	 WHERE parent_sid = NVL(in_parent_sid, parent_sid)
	   AND region_ref = in_region_ref;

	GetSpace(v_space_sid, out_cur);
END;

PROCEDURE GetSpace(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	   
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the space with sid '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT s.region_sid, s.description, s.space_type_id, s.space_type_label, s.current_lease_id, s.current_tenant_name, s.active
		  FROM v$space s
		 WHERE s.region_sid = in_region_sid;
END;

PROCEDURE CreateMeter(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
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
)
AS
BEGIN

	meter_pkg.LegacyCreateMeter(
		in_parent_sid				=> in_parent_sid,
		in_meter_type_id			=> in_meter_type_id,
		in_description				=> in_description,
		in_reference				=> in_reference,
		in_note						=> in_note,
		in_source_type_id			=> in_source_type_id,
		in_manual_data_entry		=> in_manual_data_entry,
		in_consump_conversion_id	=> in_consump_conversion_id,
		in_cost_conversion_id		=> in_cost_conversion_id,
		out_region_sid				=> out_region_sid
	);

	meter_pkg.UNSEC_AmendMeterActive(
		out_region_sid,
		in_active,
		in_acquisition_dtm,
		in_disposal_dtm
	);

	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(out_region_sid);
END;



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
)
AS
	v_contract_ids			security_pkg.T_SID_IDS;
	v_active_contract_id	meter_utility_contract.utility_contract_id%TYPE;
	v_old_parent_sid		security_pkg.T_SID_ID;
	v_urjanet_meter_id		all_meter.urjanet_meter_id%TYPE;
BEGIN

	SELECT r.parent_sid, m.urjanet_meter_id
	  INTO v_old_parent_sid, v_urjanet_meter_id
	  FROM v$legacy_meter m
	  JOIN region r ON m.region_sid = r.region_sid AND m.app_sid = r.app_sid
	 WHERE m.region_sid = in_region_sid;

	IF v_old_parent_sid != in_parent_sid THEN
		-- move it -- could be slow. Hmm...
		securableobject_pkg.MoveSO(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, in_parent_sid);
	END IF;

	-- has the name changed? 
	region_pkg.RenameRegion(in_region_sid, in_description);

	SELECT MIN(utility_contract_id)
	  INTO v_active_contract_id
	  FROM meter_utility_contract
	 WHERE region_sid = in_region_sid;

	SELECT utility_contract_id
	  BULK COLLECT INTO v_contract_ids
	  FROM meter_utility_contract
	 WHERE region_sid = in_region_sid;


	meter_pkg.LegacyMakeMeter(
		in_act_id					=> SYS_CONTEXT('SECURITY','ACT'),
		in_region_sid				=> in_region_sid,
		in_meter_type_id			=> in_meter_type_id,
		in_note						=> in_note,
		in_primary_conversion_id	=> in_consump_conversion_id,
		in_cost_conversion_id		=> in_cost_conversion_id,
		in_source_type_id			=> in_source_type_id,
		in_manual_data_entry		=> in_manual_data_entry,
		in_reference				=> in_reference,
		in_contract_ids				=> v_contract_ids,
		in_active_contract_id		=> v_active_contract_id,
		in_urjanet_meter_id			=> v_urjanet_meter_id
	);

	meter_pkg.UNSEC_AmendMeterActive(
		in_region_sid,
		in_active,
		in_acquisition_dtm,
		in_disposal_dtm
	);

	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

END;
/
