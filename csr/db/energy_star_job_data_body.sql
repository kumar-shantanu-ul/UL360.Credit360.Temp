CREATE OR REPLACE PACKAGE BODY CSR.energy_star_job_data_pkg IS

-- Get the property information for a specific job
PROCEDURE GetBuildingAndMetricsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_building				OUT	security_pkg.T_OUTPUT_CUR,
    out_metrics					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBuildingForJob(in_job_id, out_building);
	GetBuildingMetricsForJob(in_job_id, out_metrics);
END;

PROCEDURE GetBuildingForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_job_type					est_job.est_job_type_id%TYPE;
	v_region_sid				security_pkg.T_SID_ID;
	v_est_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id			est_meter.pm_customer_id%TYPE;
	v_pm_building_id			est_meter.pm_building_id%TYPE;
	v_year_built				est_building.year_built%TYPE;
BEGIN

	-- Get some information about the job and the current state of the ES space object
	SELECT NVL(b.region_sid, j.region_sid), j.est_account_sid, j.pm_customer_id, 
			NVL(j.pm_building_id, rb.pm_building_id),
			CASE WHEN j.est_job_type_id = energy_star_job_pkg.JOB_TYPE_REGION AND rb.pm_building_id IS NOT NULL THEN
				-- If this is a region job (create in ES) but the property already exists 
				-- and is mapped (rb) then actually run a property type job (update in ES)
				energy_star_job_pkg.JOB_TYPE_PROPERTY
			ELSE 
				j.est_job_type_id
			END
	  INTO v_region_sid, v_est_account_sid, v_pm_customer_id, v_pm_building_id, v_job_type
	  FROM est_job j
	  -- Match by pm_building_id
	  LEFT JOIN est_building b ON j.app_sid = b.app_sid AND j.est_account_sid = b.est_account_sid 
	  		AND j.pm_customer_id = b.pm_customer_id AND j.pm_building_id = b.pm_building_id
	  -- Match by region_sid (in case property was created after a second region job type was created)
	  LEFT JOIN est_building rb ON j.app_sid = rb.app_sid AND j.est_account_sid = rb.est_account_sid 
	  		AND j.pm_customer_id = rb.pm_customer_id AND j.region_sid = rb.region_sid
	 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND j.est_job_id = in_job_id;

	-- Try and get the year built from the region metric
	BEGIN
		SELECT val
		  INTO v_year_built
		  FROM (
			SELECT 
			    ROW_NUMBER() OVER (ORDER BY v.effective_dtm DESC) rn,
			    FIRST_VALUE(v.val) OVER (ORDER BY v.effective_dtm DESC) val
			  FROM region_metric_val v
			  JOIN est_other_mapping m ON v.app_sid = m.app_sid AND v.ind_sid = m.ind_sid
			 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND v.region_sid = v_region_sid
			   AND m.est_account_sid = v_est_account_sid
			   AND m.mapping_name = 'yearBuilt'
		 )
		 WHERE rn = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_year_built := NULL;
	END;
	
	-- New property (not in est_building yet so all info derives from region or uses default values)
	IF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION AND v_pm_building_id IS NULL AND v_region_sid IS NOT NULL THEN
			
		-- Check the key is valid
		IF v_pm_customer_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not determine the "PM customer ID" while processing a new property region. Job ID: '||in_job_id);
		END IF;
		
		-- Return the drived building information
		OPEN out_cur FOR
			SELECT r.region_sid,
				v_est_account_sid est_account_sid, v_pm_customer_id pm_customer_id, v_pm_building_id pm_building_id,
				r.description building_name, p.street_addr_1 address, p.street_addr_2 address2, p.city, p.postcode zip_code, 
				UPPER(r.geo_country) country,
				DECODE(UPPER(r.geo_country), 'US', p.state, 'CA', p.state, NULL) state,
				DECODE(UPPER(r.geo_country), 'US', NULL, 'CA', NULL, p.state) other_state,
				v_year_built year_built,
				map.est_property_type primary_function,
				-- Defaults not specified by the cr360 system
				'Existing' construction_status, NULL notes, 1 write_access,
				NULL federal_owner, NULL federal_agency, NULL federal_agency_region, NULL federal_campus,
				NULL import_dtm, NULL last_poll_dtm, NULL last_job_dtm
			  FROM est_job j
			  JOIN v$region r ON j.app_sid = r.app_sid AND j.region_sid = r.region_sid
			  JOIN property p ON j.app_sid = p.app_sid AND j.region_sid = p.region_sid
			  JOIN est_property_type_map map ON p.app_sid = map.app_sid AND p.property_type_id = map.property_type_id
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			;
	
	-- Existing property (merge current region info with est_building)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_PROPERTY AND v_pm_building_id IS NOT NULL AND v_region_sid IS NOT NULL THEN
		OPEN out_cur FOR
			SELECT r.region_sid,
				v_est_account_sid est_account_sid, v_pm_customer_id pm_customer_id, v_pm_building_id pm_building_id,
				r.description building_name, NVL(p.street_addr_1, b.address) address, 
				NVL(p.street_addr_2, b.address2) address2, NVL(p.city, b.city) city,
				NVL(p.postcode, b.zip_code) zip_code, NVL(UPPER(r.geo_country), b.country) country,
				NVL(DECODE(NVL(UPPER(r.geo_country), b.country), 'US', p.state, 'CA', p.state, NULL), b.state) state,
				NVL(DECODE(NVL(UPPER(r.geo_country), b.country), 'US', NULL, 'CA', NULL, p.state), b.other_state) other_state,
				NVL(v_year_built, b.year_built) year_built,
				NVL(map.est_property_type, b.primary_function) primary_function,
				b.construction_status, b.notes, b.write_access,
				b.federal_owner, b.federal_agency, b.federal_agency_region, b.federal_campus,
				b.import_dtm, b.last_poll_dtm, b.last_job_dtm
			  FROM est_job j
			  JOIN est_building b ON j.app_sid = b.app_sid AND j.est_account_sid = b.est_account_sid 
			  		AND j.pm_customer_id = b.pm_customer_id  AND v_pm_building_id = b.pm_building_id
			  JOIN v$region r ON b.app_sid = r.app_sid AND b.region_sid = r.region_sid
			  JOIN property p ON b.app_sid = p.app_sid AND b.region_sid = p.region_sid
			  JOIN est_property_type_map map ON p.app_sid = map.app_sid AND p.property_type_id = map.property_type_id
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			;
	
	-- Deleted property (no region sid)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_PROPERTY AND v_pm_building_id IS NOT NULL AND v_region_sid IS NULL THEN
		energy_star_pkg.GetBuilding(
			v_est_account_sid,
			v_pm_customer_id,
			v_pm_building_id,
			out_cur
		);
	
	-- Unknown 	
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Could not determine how to get property object data for job: '||in_job_id);
	END IF;
END;

PROCEDURE GetBuildingMetricsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_job_type					est_job.est_job_type_id%TYPE;
BEGIN
	SELECT est_job_type_id
	  INTO v_job_type
	  FROM est_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_job_id = in_job_id;
	   
	IF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION THEN
		OPEN out_cur FOR
			SELECT m.metric_name, v.effective_dtm period_end_dtm, m.uom,
				CASE WHEN mes.custom_field IS NULL THEN DECODE(aty.basic_type, 'INT', ROUND(v.entry_val * m.divisor), v.entry_val * m.divisor) ELSE NULL END val,
				CASE WHEN mes.custom_field IS NULL THEN v.note ELSE energy_star_helper_pkg.UNSEC_CustomFromVal(v.ind_sid, v.val) END str
			  FROM est_job j
			  JOIN region_metric_val v ON j.app_sid = v.app_sid AND j.region_sid = v.region_sid
			  JOIN measure mes ON v.app_sid = mes.app_sid AND v.measure_sid = mes.measure_sid
			  JOIN est_building_metric_mapping m ON j.app_sid = m.app_sid AND j.est_account_sid = m.est_account_sid 
			  		AND v.ind_sid = m.ind_sid AND NVL(v.entry_measure_conversion_id, -1) = NVL(m.measure_conversion_id, -1)
			  LEFT JOIN est_attr_for_building ab ON ab.attr_name = m.metric_name
			  LEFT JOIN est_attr_type aty ON aty.type_name = ab.type_name
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			   AND m.simulated = 1
			   AND m.read_only = 0;
	ELSE
		OPEN out_cur FOR
			SELECT m.metric_name, v.effective_dtm period_end_dtm, m.uom,
				CASE WHEN mes.custom_field IS NULL THEN DECODE(aty.basic_type, 'INT', ROUND(v.entry_val * m.divisor), v.entry_val * m.divisor) ELSE NULL END val,
				CASE WHEN mes.custom_field IS NULL THEN v.note ELSE energy_star_helper_pkg.UNSEC_CustomFromVal(v.ind_sid, v.val) END str
			  FROM est_job j
			  JOIN est_building b ON j.app_sid = b.app_sid AND j.pm_customer_id = b.pm_customer_id AND j.pm_building_id = b.pm_building_id
			  JOIN region_metric_val v ON j.app_sid = v.app_sid AND b.region_sid = v.region_sid
			  JOIN measure mes ON v.app_sid = mes.app_sid AND v.measure_sid = mes.measure_sid
			  JOIN est_building_metric_mapping m ON j.app_sid = m.app_sid AND j.est_account_sid = m.est_account_sid 
			  		AND v.ind_sid = m.ind_sid AND NVL(v.entry_measure_conversion_id, -1) = NVL(m.measure_conversion_id, -1)
			  LEFT JOIN est_attr_for_building ab ON ab.attr_name = m.metric_name
			  LEFT JOIN est_attr_type aty ON aty.type_name = ab.type_name
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			   AND m.simulated = 1
			   AND m.read_only = 0;
	END IF;
END;

-- Get both the space and attribute data for a specific job
PROCEDURE GetSpaceAndAttrsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_space					OUT	security_pkg.T_OUTPUT_CUR,
    out_attrs					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSpaceForJob(in_job_id, out_space);
	GetSpaceAttrsForJob(in_job_id, out_attrs);
END;

-- Get the space information for a specific job
PROCEDURE GetSpaceForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_job_type					est_job.est_job_type_id%TYPE;
	v_update_pm_object			est_job.update_pm_object%TYPE;
	v_region_sid				security_pkg.T_SID_ID;
	v_est_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id			est_meter.pm_customer_id%TYPE;
	v_pm_building_id			est_meter.pm_building_id%TYPE;
	v_pm_space_id				est_meter.pm_space_id%TYPE;
	
BEGIN

	-- Get some information about the job and the current state of the ES space object
	SELECT j.update_pm_object, NVL(s.region_sid, j.region_sid), j.est_account_sid, j.pm_customer_id, 
			NVL(j.pm_building_id, rs.pm_building_id), NVL(j.pm_space_id, rs.pm_space_id),
			CASE WHEN j.est_job_type_id = energy_star_job_pkg.JOB_TYPE_REGION AND rs.pm_space_id IS NOT NULL THEN
				-- If this is a region job (create in ES) but the space already exists 
				-- and is mapped (rs) then actually run a space type job (update in ES)
				energy_star_job_pkg.JOB_TYPE_SPACE
			ELSE 
				j.est_job_type_id
			END
	  INTO v_update_pm_object, v_region_sid, v_est_account_sid, v_pm_customer_id, v_pm_building_id, v_pm_space_id, v_job_type
	  FROM est_job j
	   -- Match by pm_building_id / pm_space_id
	  LEFT JOIN est_space s ON j.app_sid = s.app_sid AND j.est_account_sid = s.est_account_sid AND j.pm_customer_id = s.pm_customer_id 
	  		AND j.pm_building_id = s.pm_building_id AND j.pm_space_id = s.pm_space_id
	  -- Match by region_sid (in case space was created after a second region job type was created)
	  LEFT JOIN est_space rs ON j.app_sid = rs.app_sid AND j.est_account_sid = rs.est_account_sid AND j.pm_customer_id = rs.pm_customer_id 
	  		AND j.region_sid = rs.region_sid
	 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND j.est_job_id = in_job_id;
	
	-- If we're not updating the space object (just attribute data) then we can just return 
	-- the current space object without merging in latest space region derived information
	IF v_job_type = energy_star_job_pkg.JOB_TYPE_SPACE AND v_update_pm_object = 0 THEN
		energy_star_pkg.GetSpace(
			v_est_account_sid,
			v_pm_customer_id,
			v_pm_building_id,
			v_pm_space_id,
			out_cur
		);
	
	-- New space (not in est_space yet so all info derives from region or uses default values)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION AND v_pm_space_id IS NULL AND v_region_sid IS NOT NULL THEN
		
		-- Get the correct est_space key information from parent region node (the parent must be mapped to a region)
		-- The space must be the direct descendent of the property region.
		SELECT pm_customer_id, pm_building_id
		  INTO v_pm_customer_id, v_pm_building_id
		  FROM (
		  	SELECT b.pm_customer_id, b.pm_building_id
		  	  FROM region r
		  	  JOIN est_building b ON r.app_sid = b.app_sid AND r.parent_sid = b.region_sid
		  	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  	   AND r.region_sid = v_region_sid
		  	   AND b.est_account_sid = v_est_account_sid
		  );
		
		-- Check the key is valid
		IF v_pm_customer_id IS NULL OR v_pm_building_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not determine energy star key for new space region processing job: '||in_job_id);
		END IF;
		
		-- Return the drived space information
		OPEN out_cur FOR
			SELECT r.region_sid,
				v_est_account_sid est_account_sid, v_pm_customer_id pm_customer_id, v_pm_building_id pm_building_id, NULL pm_space_id,
				r.description space_name, map.est_space_type space_type
			  FROM est_job j
			  JOIN v$region r ON j.app_sid = r.app_sid AND j.region_sid = r.region_sid
			  JOIN space s ON j.app_sid = s.app_sid AND j.region_sid = s.region_sid
			  JOIN space_type st ON s.app_sid = st.app_sid AND s.space_type_id = st.space_type_id
			  JOIN est_space_type_map map ON s.app_sid = map.app_sid AND s.space_type_id = map.space_type_id
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			;
	
	-- Existing space (merge current region info with est_space) 
	-- XXX: Only name changes allowed by ES at this time so don't bother getting type!
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_SPACE AND v_pm_space_id IS NOT NULL AND v_region_sid IS NOT NULL THEN
		OPEN out_cur FOR
			SELECT 
				s.region_sid,
				s.est_account_sid, s.pm_customer_id, s.pm_building_id, s.pm_space_id,
				r.description space_name, s.space_type
			  FROM est_job j
			  JOIN est_space s ON j.app_sid = s.app_sid AND j.est_account_sid = s.est_account_sid AND j.pm_customer_id = s.pm_customer_id 
			  		AND v_pm_building_id = s.pm_building_id AND v_pm_space_id = s.pm_space_id
			  LEFT JOIN v$region r ON j.app_sid = r.app_sid AND s.region_sid = r.region_sid
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			;
	
	-- Deleted space (no region sid)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_SPACE AND v_pm_space_id IS NOT NULL AND v_region_sid IS NULL THEN
		energy_star_pkg.GetSpace(
			v_est_account_sid,
			v_pm_customer_id,
			v_pm_building_id,
			v_pm_space_id,
			out_cur
		);
	
	-- Unknown 	
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Could not determine how to get space object data for job: '||in_job_id);
	END IF;
END;

-- Get the space attribute data for a specific job
PROCEDURE GetSpaceAttrsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_job_type					est_job.est_job_type_id%TYPE;
BEGIN
	SELECT est_job_type_id
	  INTO v_job_type
	  FROM est_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_job_id = in_job_id;
	   
	IF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION THEN
		-- New space, fetch all the attribute data from the region metrics
		OPEN out_cur FOR
			SELECT NULL pm_val_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id,
				map.attr_name, v.effective_dtm effective_date, v.region_metric_val_id, 1 push,
				DECODE(map.uom, '<null>', NULL, map.uom) uom,
				CASE WHEN mes.custom_field IS NULL THEN DECODE(aty.basic_type, 'INT', ROUND(v.entry_val * map.divisor), v.entry_val * map.divisor) ELSE NULL END val,
				CASE WHEN mes.custom_field IS NULL THEN v.note ELSE energy_star_helper_pkg.UNSEC_CustomFromVal(v.ind_sid, v.val) END str
			  FROM est_job j
			  JOIN est_space_attr_mapping map ON j.app_sid = map.app_sid AND j.est_account_sid = map.est_account_sid
			  JOIN region_metric_val v ON j.app_sid = v.app_sid AND j.region_sid = v.region_sid AND map.ind_sid = v.ind_sid
			  	   AND NVL(map.measure_conversion_id, -1) = NVL(v.entry_measure_conversion_id, -1)
			  JOIN measure mes ON v.app_sid = mes.app_sid AND v.measure_sid = mes.measure_sid
			  LEFT JOIN est_attr_for_space afs ON afs.attr_name = map.attr_name
			  LEFT JOIN est_attr_type aty ON aty.type_name = afs.type_name
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id;
	ELSE
		-- Normal space attribute update (existing space)
		OPEN out_cur FOR
			SELECT pm_val_id, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, attr_name, 
				effective_date, uom, region_metric_val_id, push, val, str
			  FROM (
				-- UNMODIFIED: We pass these back so that saving the space back doesn't delete the non-modified space attribute data
				-- A better solution might be to seperate out the saving process and give the caller more control over the behaviour.
				SELECT sa.pm_val_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id, sa.attr_name, 
					sa.effective_date, sa.uom, v.region_metric_val_id, 0 push,
					sa.val, -- no divisor needed wehen selecting val directly from est_space_attr
					sa.str -- select enumeration string directly from est_space_attr
				  FROM est_job j
				  JOIN est_space s ON j.app_sid = s.app_sid AND j.est_account_sid = s.est_account_sid AND j.pm_customer_id = s.pm_customer_id
				  		AND j.pm_building_id = s.pm_building_id AND j.pm_space_id = s.pm_space_id
				  JOIN est_space_attr sa ON j.app_sid = sa.app_sid AND j.est_account_sid = sa.est_account_sid AND j.pm_customer_id = sa.pm_customer_id
				  		AND j.pm_building_id = sa.pm_building_id AND j.pm_space_id = sa.pm_space_id
				  LEFT JOIN est_space_attr_mapping map ON j.app_sid = map.app_sid AND j.est_account_sid = map.est_account_sid AND sa.attr_name = map.attr_name AND NVL(sa.uom, '<null>') = map.uom
				  LEFT JOIN region_metric_val v ON s.app_sid = v.app_sid AND s.region_sid = v.region_sid AND map.ind_sid = v.ind_sid AND sa.region_metric_val_id = v.region_metric_val_id
				  			AND NVL(map.measure_conversion_id, -1) = NVL(v.entry_measure_conversion_id, -1)
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				   AND NOT EXISTS (
				   		SELECT 1
				   		  FROM est_job_attr ja
				   		 WHERE ja.est_job_id = j.est_job_id
				   		   AND ja.region_metric_val_id = v.region_metric_val_id
				   )
				   AND NOT EXISTS (
				   		SELECT 1
				   		  FROM est_job_attr ja
				   		 WHERE ja.est_job_id = j.est_job_id
		             	   AND ja.pm_val_id = sa.pm_val_id
				   )
				UNION
				-- MODIFIED or NEW: Specified by job and exists in the region metric table
				SELECT NVL(sa.pm_val_id, ja.pm_val_id) pm_val_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id,
					map.attr_name, v.effective_dtm effective_date, DECODE(map.uom, '<null>', NULL, map.uom) uom, v.region_metric_val_id, 1 push,
					CASE WHEN mes.custom_field IS NULL THEN DECODE(aty.basic_type, 'INT', ROUND(v.entry_val * map.divisor), v.entry_val * map.divisor) ELSE NULL END val,
					CASE WHEN mes.custom_field IS NULL THEN v.note ELSE energy_star_helper_pkg.UNSEC_CustomFromVal(v.ind_sid, v.val) END str
				  FROM est_job j
				  JOIN est_job_attr ja ON j.app_sid = ja.app_sid AND j.est_job_id = ja.est_job_id
				  JOIN est_space s ON j.app_sid = s.app_sid AND j.est_account_sid = s.est_account_sid AND j.pm_customer_id = s.pm_customer_id
						AND j.pm_building_id = s.pm_building_id AND j.pm_space_id = s.pm_space_id
				  JOIN est_space_attr_mapping map ON j.app_sid = map.app_sid AND j.est_account_sid = map.est_account_sid 
				  JOIN region_metric_val v ON s.app_sid = v.app_sid AND s.region_sid = v.region_sid AND ja.region_metric_val_id = v.region_metric_val_id
					   AND map.ind_sid = v.ind_sid AND NVL(map.measure_conversion_id, -1) = NVL(v.entry_measure_conversion_id, -1)
				  JOIN measure mes ON v.app_sid = mes.app_sid AND v.measure_sid = mes.measure_sid
				  LEFT JOIN est_space_attr sa ON j.app_sid = sa.app_sid AND ja.pm_val_id = sa.pm_val_id
				  LEFT JOIN est_attr_for_space afs ON afs.attr_name = map.attr_name
			  	  LEFT JOIN est_attr_type aty ON aty.type_name = afs.type_name
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				UNION
				-- REMOVED: In the space attr table and specified by the job but not associated with a region metric
				SELECT sa.pm_val_id, j.est_account_sid, j.pm_customer_id, j.pm_building_id, j.pm_space_id, sa.attr_name, 
					sa.effective_date, sa.uom, NULL region_metric_val_id, 1 push,
					sa.val, -- no divisor needed selecting val directly from est_space_attribute
					sa.str
				  FROM est_job j
				  JOIN est_job_attr ja ON j.app_sid = ja.app_sid AND j.est_job_id = ja.est_job_id
				  JOIN est_space_attr sa ON j.app_sid = sa.app_sid AND j.est_account_sid = sa.est_account_sid AND j.pm_customer_id = sa.pm_customer_id
				  		AND j.pm_building_id = sa.pm_building_id AND j.pm_space_id = sa.pm_space_id
				  JOIN est_space_attr_mapping map ON j.app_sid = map.app_sid AND j.est_account_sid = map.est_account_sid AND sa.attr_name = map.attr_name AND NVL(sa.uom, '<null>') = map.uom
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				   AND ja.pm_val_id = sa.pm_val_id
				   AND sa.region_metric_val_id IS NULL
			)
			ORDER BY attr_name, effective_date, push;
	END IF;
END;

-- Get meter information for specific job
PROCEDURE GetMeterForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_job_type					est_job.est_job_type_id%TYPE;
	v_update_pm_object			est_job.update_pm_object%TYPE;
	v_region_sid				security_pkg.T_SID_ID;
	v_est_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id			est_meter.pm_customer_id%TYPE;
	v_pm_building_id			est_meter.pm_building_id%TYPE;
	v_pm_space_id				est_meter.pm_space_id%TYPE;
	v_pm_meter_id				est_meter.pm_meter_id%TYPE;
	v_first_bill_dtm			DATE;
BEGIN

	-- Get some information about the job and the current state of the ES meter object
	SELECT j.update_pm_object, NVL(m.region_sid, j.region_sid), j.est_account_sid, j.pm_customer_id, 
			NVL(j.pm_building_id, rm.pm_building_id), NVL(j.pm_meter_id, rm.pm_meter_id),
			CASE WHEN j.est_job_type_id = energy_star_job_pkg.JOB_TYPE_REGION AND rm.pm_meter_id IS NOT NULL THEN
				-- If this is a region job (create in ES) but the meter already exists 
				-- and is mapped (rm) then actually run a meter type (update in ES) job
				energy_star_job_pkg.JOB_TYPE_METER
			ELSE 
				j.est_job_type_id
			END
	  INTO v_update_pm_object, v_region_sid, v_est_account_sid, v_pm_customer_id, v_pm_building_id, v_pm_meter_id, v_job_type
	  FROM est_job j
	  -- Match by pm_building_id / pm_meter_id
	  LEFT JOIN est_meter m ON j.app_sid = m.app_sid AND j.est_account_sid = m.est_account_sid AND j.pm_customer_id = m.pm_customer_id 
	  		AND j.pm_building_id = m.pm_building_id AND j.pm_meter_id = m.pm_meter_id
	  -- Match by region_sid (in case meter was created after a second region job type was created)
	  LEFT JOIN est_meter rm ON j.app_sid = rm.app_sid AND j.est_account_sid = rm.est_account_sid AND j.pm_customer_id = rm.pm_customer_id
	  		AND j.region_sid = rm.region_sid 
	 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND j.est_job_id = in_job_id;
	
	-- Attempt to find a value for the first bill date in priority order:
	-- 1. The acquisition date
	-- 2. The first reading date (or the disposal date if it's not null and is earlier)
	-- 3. The first bill date from the ES schema
	-- 4. The disposal date (if the disposal date is set then we can't set the first bill date before that date)
	-- 5. The current date
	BEGIN
		SELECT 
			-- Case statement is easier to read than nested NVLs
			CASE
				WHEN r.acquisition_dtm IS NOT NULL THEN r.acquisition_dtm
				WHEN MIN(mr.start_dtm) IS NOT NULL THEN LEAST(NVL(r.disposal_dtm, MIN(mr.start_dtm)), MIN(mr.start_dtm)) -- Meter could be disposed of before first reading date
				WHEN m.first_bill_dtm IS NOT NULL THEN m.first_bill_dtm
				WHEN r.disposal_dtm IS NOT NULL THEN r.disposal_dtm
				ELSE SYSDATE
			END
		  INTO v_first_bill_dtm
		  FROM region r
		  JOIN est_job j ON j.app_sid = r.app_sid 
		   AND j.est_job_id = in_job_id
		  LEFT JOIN v$meter_reading mr on mr.app_sid = r.app_sid 
		   AND mr.region_sid = r.region_sid
		  LEFT JOIN est_meter m ON m.app_sid = j.app_sid 
		   AND m.est_account_sid = j.est_account_sid 
		   AND m.pm_customer_id = j.pm_customer_id 
		   AND m.pm_building_id = j.pm_building_id 
		   AND m.pm_meter_id = j.pm_meter_id
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v_region_sid
		 GROUP BY mr.region_sid, r.acquisition_dtm, m.first_bill_dtm, r.disposal_dtm;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_first_bill_dtm := NULL;
	END;

	-- If we're not updating the meter object (just consumption data) then we can just return 
	-- the current meter object data without merging in latest meter region derived information
	IF v_job_type = energy_star_job_pkg.JOB_TYPE_METER AND v_update_pm_object = 0 THEN
		energy_star_pkg.GetMeter(
			v_est_account_sid,
			v_pm_customer_id,
			v_pm_building_id,
			v_pm_meter_id,
			out_cur
		);

	-- New meter (not in est_meter yet so all info derives from region or uses default values)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION AND v_pm_meter_id IS NULL AND v_region_sid IS NOT NULL THEN
		
		-- Get the correct est_meter key information from parent region node (the parent must be mapped to a region)
		-- The meter must be the direct descendent of the property or the space region.
		SELECT pm_customer_id, pm_building_id, pm_space_id
		  INTO v_pm_customer_id, v_pm_building_id, v_pm_space_id
		  FROM (
		  	SELECT b.pm_customer_id, b.pm_building_id, NULL pm_space_id
		  	  FROM region r
		  	  JOIN est_building b ON r.app_sid = b.app_sid AND r.parent_sid = b.region_sid
		  	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  	   AND r.region_sid = v_region_sid
		  	   AND b.est_account_sid = v_est_account_sid
		  	UNION 
		  	SELECT s.pm_customer_id, s.pm_building_id, s.pm_space_id
		  	  FROM region r
		  	  JOIN est_space s ON r.app_sid = s.app_sid AND r.parent_sid = s.region_sid
		  	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  	   AND r.region_sid = v_region_sid
		  	   AND s.est_account_sid = v_est_account_sid
		  );
		
		-- Check the key is valid
		IF v_pm_customer_id IS NULL OR v_pm_building_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not determine energy star key for new meter region processing job: '||in_job_id);
		END IF;

		-- Return the drived meter information
		OPEN out_cur FOR
			SELECT r.region_sid,
				-- est_meter key
				v_est_account_sid est_account_sid, v_pm_customer_id pm_customer_id, 
				v_pm_building_id pm_building_id, v_pm_space_id pm_space_id,
				-- Information derived from meter region
				r.description meter_name, tm.meter_type, cm.uom, 
				r.active, 
				DECODE(r.active, 1, NULL, NVL(r.disposal_dtm, SYSDATE)) inactive_dtm,
				-- Defaults that can not be determined from the property/region information
				NULL pm_meter_id, NULL other_desc, NULL last_entry_date, 
				v_first_bill_dtm first_bill_dtm,
				1 write_access, 0 sellback, 0 enviro_attr_owned, 1 add_to_total
			  FROM est_job j
			  JOIN v$region r ON j.app_sid = r.app_sid AND j.region_sid = r.region_sid
			  JOIN v$legacy_meter m ON r.app_sid = m.app_sid AND r.region_sid = m.region_sid
			  JOIN ind i ON m.app_sid = i.app_sid AND i.ind_sid = m.primary_ind_sid
			  -- Determine the correct type and uom mappings for the meter ind and measure/conversion
			  JOIN est_meter_type_mapping tm ON j.app_sid = tm.app_sid AND j.est_account_sid = tm.est_account_sid AND m.meter_type_id = tm.meter_type_id
			  JOIN est_conv_mapping cm ON tm.app_sid = cm.app_sid AND tm.est_account_sid = cm.est_account_sid AND tm.meter_type = cm.meter_type
			  		AND i.measure_sid = cm.measure_sid AND NVL(m.primary_measure_conversion_id, -1) = NVL(cm.measure_conversion_id, -1)
			 -- The specified job
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			;
	
	-- Existing meter (merge current region info with est_meter)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_METER AND v_pm_meter_id IS NOT NULL AND v_region_sid IS NOT NULL THEN
		OPEN out_cur FOR
			SELECT 
				-- These values directly from est_meter
				em.est_account_sid, em.pm_customer_id, em.pm_building_id, em.pm_meter_id, em.pm_space_id, em.region_sid,
				em.other_desc, em.last_entry_date, em.write_access, em.sellback, em.enviro_attr_owned, em.add_to_total,
				-- These values derived from the meter region if available, 
				-- otherwise just the values in est_meter (used for push updates):
				NVL(r.description, em.meter_name) meter_name, 
				NVL(tm.meter_type, em.meter_type) meter_type, 
				NVL(cm.uom, em.uom) uom, 
				r.active, 
				DECODE(r.active, 1, NULL, NVL(r.disposal_dtm, NVL(em.inactive_dtm, SYSDATE))) inactive_dtm,
				NVL(v_first_bill_dtm, em.first_bill_dtm) first_bill_dtm
			  FROM est_job j
			  -- Information from est_meter table:
			  JOIN est_meter em ON j.app_sid = em.app_sid AND j.est_account_sid = em.est_account_sid AND j.pm_customer_id = em.pm_customer_id 
			  		AND v_pm_building_id = em.pm_building_id AND v_pm_meter_id = em.pm_meter_id
			  -- Information from region/meter/meter ind:
			  LEFT JOIN v$region r ON j.app_sid = r.app_sid AND em.region_sid = r.region_sid
			  LEFT JOIN v$legacy_meter m ON r.app_sid = m.app_sid AND r.region_sid = m.region_sid
			  LEFT JOIN ind i ON m.app_sid = i.app_sid AND i.ind_sid = m.primary_ind_sid
			  LEFT JOIN est_meter_type_mapping tm ON em.app_sid = tm.app_sid AND em.est_account_sid = tm.est_account_sid AND m.meter_type_id = tm.meter_type_id
			  LEFT JOIN est_conv_mapping cm ON tm.app_sid = cm.app_sid AND tm.est_account_sid = cm.est_account_sid AND tm.meter_type = cm.meter_type
			  		AND i.measure_sid = cm.measure_sid AND NVL(m.primary_measure_conversion_id, -1) = NVL(cm.measure_conversion_id, -1)
			 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND j.est_job_id = in_job_id
			;
	
	-- Deleted meter (no region sid)
	ELSIF v_job_type = energy_star_job_pkg.JOB_TYPE_METER AND v_pm_meter_id IS NOT NULL AND v_region_sid IS NULL THEN
		energy_star_pkg.GetMeter(
			v_est_account_sid,
			v_pm_customer_id,
			v_pm_building_id,
			v_pm_meter_id,
			out_cur
		);
	
	-- Unknown 	
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Could not determine how to get meter object data for job: '||in_job_id);
	END IF;
END;

-- Get meter reading data for specific job (the job will be tied to a single meter)
PROCEDURE GetMeterReadingsForJob(
    in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_job_type					est_job.est_job_type_id%TYPE;
	v_region_sid				security_pkg.T_SID_ID;
	v_arbitrary_period			meter_source_type.arbitrary_period%TYPE;
BEGIN
	
	-- TODO: Add some kind of support for real-time meters
	
	-- Get the job type and the region sid. Either the region sid should be specified by 
	-- the job or the ES meter object sholld be specified and have a valid region sid
	SELECT j.est_job_type_id, NVL(j.region_sid, em.region_sid)
	  INTO v_job_type, v_region_sid
	  FROM est_job j
	  LEFT JOIN est_meter em ON j.app_sid = em.app_sid AND j.est_account_sid = em.est_account_sid
	  		AND j.pm_customer_id = em.pm_customer_id AND j.pm_building_id = em.pm_building_id AND j.pm_meter_id = em.pm_meter_id
	 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND j.est_job_id = in_job_id;
	
	IF v_region_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not determine meter''s region sid processing job: '||in_job_id);
	END IF;
	
	-- We have to deal with arbitrary period meters and 
	-- point in time meters slightly differently
	SELECT st.arbitrary_period
	  INTO v_arbitrary_period
	  FROM all_meter m
	  JOIN meter_source_type st ON m.app_sid = st.app_sid AND m.meter_source_type_id = st.meter_source_type_id
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.region_sid = v_region_sid;
	   
	IF v_arbitrary_period = 0 THEN
		IF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION THEN
			OPEN out_cur FOR
				SELECT mr.meter_reading_id, mr.pm_reading_id, mr.start_dtm, mr.end_dtm, 
					mr.consumption val_number, NULL cost, 0 is_deleted, mr.is_estimate
				  FROM est_job j
				  JOIN (
				  		SELECT region_sid, meter_reading_id, pm_reading_id, is_estimate, start_dtm, end_dtm, consumption, val_number, baseline_val
						  FROM (
							SELECT mr.region_sid, mr.meter_reading_id, mr.pm_reading_id, mr.is_estimate,
								mr.start_dtm, LEAD(mr.start_dtm) OVER (ORDER BY mr.start_dtm) end_dtm,
								mr.val_number, mr.baseline_val,
								CASE WHEN st.descending = 0 THEN
									LEAD(mr.val_number) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm)
										+ NVL(LEAD(mr.baseline_val) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm), 0)
										- mr.val_number - NVL(mr.baseline_val, 0)
								ELSE
									mr.val_number + NVL(mr.baseline_val, 0) 
										- LEAD(mr.val_number) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm) 
										- NVL(LEAD(mr.baseline_val) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm), 0)
								END consumption
							  FROM v$meter_reading mr
							  JOIN all_meter am ON am.app_sid = mr.app_sid AND am.region_sid = mr.region_sid
							  JOIN meter_source_type st ON st.meter_source_type_id = am.meter_source_type_id
							 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
							   AND mr.val_number IS NOT NULL
							   AND mr.end_dtm IS NULL
						)
						WHERE consumption IS NOT NULL
				  ) mr ON j.region_sid = mr.region_sid
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				;
		ELSE
			OPEN out_cur FOR
				SELECT jr.meter_reading_id, jr.pm_reading_id, mr.start_dtm, mr.end_dtm, 
					mr.consumption val_number, NULL cost, 
					DECODE(mr.meter_reading_id, NULL, 1, 0) is_deleted, mr.is_estimate
				  FROM est_job j
				  JOIN est_job_reading jr ON j.app_sid = jr.app_sid AND j.est_job_id = jr.est_job_id
				  JOIN est_meter em ON em.app_sid = j.app_sid AND em.est_account_sid = j.est_account_sid
						AND em.pm_customer_id = j.pm_customer_id AND em.pm_building_id = j.pm_building_id AND j.pm_meter_id = em.pm_meter_id
				  LEFT JOIN (
				  		SELECT region_sid, meter_reading_id, pm_reading_id, is_estimate, start_dtm, end_dtm, consumption, val_number, baseline_val
						  FROM (
							SELECT mr.region_sid, mr.meter_reading_id, mr.pm_reading_id, mr.is_estimate,
								mr.start_dtm, LEAD(mr.start_dtm) OVER (ORDER BY mr.start_dtm) end_dtm,
								mr.val_number, mr.baseline_val,
								CASE WHEN st.descending = 0 THEN
									LEAD(mr.val_number) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm) 
										+ NVL(LEAD(mr.baseline_val) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm), 0) 
										- mr.val_number - NVL(mr.baseline_val, 0)
								ELSE
									mr.val_number + NVL(mr.baseline_val, 0) 
										- LEAD(mr.val_number) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm) 
										- NVL(LEAD(mr.baseline_val) OVER (PARTITION BY mr.region_sid ORDER BY mr.start_dtm), 0)
								END consumption
							  FROM v$meter_reading mr
							  JOIN all_meter am ON am.app_sid = mr.app_sid AND am.region_sid = mr.region_sid
							  JOIN meter_source_type st ON st.meter_source_type_id = am.meter_source_type_id
							 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
							   AND mr.val_number IS NOT NULL
							   AND mr.end_dtm IS NULL
						)
				  ) mr ON em.region_sid = mr.region_sid AND jr.meter_reading_id = mr.meter_reading_id
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				   AND em.region_sid IS NOT NULL
				   AND (mr.meter_reading_id IS NULL OR mr.consumption IS NOT NULL)
				;
		END IF;
	ELSE
		IF v_job_type = energy_star_job_pkg.JOB_TYPE_REGION THEN
			OPEN out_cur FOR
				SELECT mr.meter_reading_id, mr.pm_reading_id, 
					mr.start_dtm, mr.end_dtm, 
					mr.val_number, mr.cost, 
					0 is_deleted, mr.is_estimate
				  FROM est_job j
				  JOIN v$meter_reading mr ON j.app_sid = mr.app_sid AND j.region_sid = mr.region_sid
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				;
		ELSE
			OPEN out_cur FOR
				SELECT jr.meter_reading_id, jr.pm_reading_id,	
					mr.start_dtm, mr.end_dtm, 
					mr.val_number, mr.cost,
					DECODE(mr.meter_reading_id, NULL, 1, 0) is_deleted, mr.is_estimate
				  FROM est_job j
				  JOIN est_job_reading jr ON j.app_sid = jr.app_sid AND j.est_job_id = jr.est_job_id
				  JOIN est_meter em ON em.app_sid = j.app_sid AND em.est_account_sid = j.est_account_sid
						AND em.pm_customer_id = j.pm_customer_id AND em.pm_building_id = j.pm_building_id AND j.pm_meter_id = em.pm_meter_id
				  LEFT JOIN v$meter_reading mr ON em.app_sid = mr.app_sid AND em.region_sid = mr.region_sid AND jr.meter_reading_id = mr.meter_reading_id
				 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND j.est_job_id = in_job_id
				   AND em.region_sid IS NOT NULL
				;
		END IF;
	END IF;   
END;

END;
/


