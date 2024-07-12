CREATE OR REPLACE PACKAGE BODY CSR.energy_star_helper_pkg IS

FUNCTION UNSEC_ValFromCustom (
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_custom_value				IN	measure.custom_field%TYPE
) RETURN val.val_number%TYPE
AS
	v_num						val.val_number%TYPE;
	v_measure_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT measure_sid
	  INTO v_measure_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	
	BEGIN
		SELECT pos
		  INTO v_num
		  FROM TABLE(
		  	utils_pkg.SplitString((
		  		SELECT custom_field 
		  		  FROM measure 
		  		 WHERE measure_sid = v_measure_sid
		  	), CHR(13)||CHR(10))
		  )
		 WHERE LOWER(item) = LOWER(in_custom_value);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_num := NULL;
	END;
	
	RETURN v_num;
END;

FUNCTION UNSEC_CustomFromVal (
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_num						IN	val.val_number%TYPE
) RETURN measure.custom_field%TYPE
AS
	
	v_custom					measure.custom_field%TYPE;
	v_measure_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT measure_sid
	  INTO v_measure_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	
	BEGIN
		SELECT item
		  INTO v_custom
		  FROM TABLE(
		  	utils_pkg.SplitString((
		  		SELECT custom_field 
		  		  FROM measure 
		  		 WHERE measure_sid = v_measure_sid
		  	), CHR(13)||CHR(10))
		  )
		 WHERE pos = in_num;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_custom := NULL;
	END;
	
	RETURN v_custom;
END;

-- Check a given building region (passed region sid should be for a 
-- building) for child spaces that have freezers etc.
-- Other mapping name: refrigCases
PROCEDURE HelperRefrigCases(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
)
AS
	v_val_yes					val.val_number%TYPE;
	v_val_no					val.val_number%TYPE;
	v_val_id					val.val_id%TYPE;
BEGIN
	
	-- This will ensure the region metric is set-up correctly
	region_metric_pkg.SetMetric(in_ind_sid);

	-- Clear any existing metric values
	region_metric_pkg.DeleteMetricValues(
		in_region_sid,
		in_ind_sid
	);
	
	-- Fetch custom field's corrasponding val number	
	v_val_yes := UNSEC_ValFromCustom(in_ind_sid, 'Yes');
	v_val_no := UNSEC_ValFromCustom(in_ind_sid, 'No');
	
	-- For each date that has some refrig units insert some metric data
	FOR r IN (
		SELECT SUM(sa.val) total, sa.effective_date
		  FROM est_space s, est_space_attr sa
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND sa.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.region_sid = in_region_sid
		   AND s.est_account_sid = in_est_account_sid
		   AND sa.est_account_sid = s.est_account_sid
		   AND sa.pm_customer_id = s.pm_customer_id
		   AND sa.pm_building_id = s.pm_building_id
		   AND sa.pm_space_id = s.pm_space_id
		   AND NVL(sa.val, 0) > 0
		   AND attr_name IN (
		   	'numberOfCommercialRefrigerationUnits',
			'numberOfOpenRefrigerationUnits',
			'numberOfWalkInRefrigerationUnits'
		   )
			GROUP BY sa.effective_date
	) LOOP		
		-- Set the region metric 
		region_metric_pkg.SetMetricValue(
			in_region_sid,
			in_ind_sid,
			r.effective_date,
			CASE WHEN r.total > 0 THEN v_val_yes ELSE v_val_no END,
			NULL,
			NULL,
			in_measure_conversion_id,
			csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
			v_val_id
		);
	END LOOP;
END;

PROCEDURE HelperYesNoSpaceAttr(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
)
AS
	v_val_id					val.val_id%TYPE;
	v_val_yes					val.val_number%TYPE;
	v_val_no					val.val_number%TYPE;
BEGIN
	
	-- This will ensure the region metric is set-up correctly
	region_metric_pkg.SetMetric(in_ind_sid);
	
	-- Clear any existing metric values
	region_metric_pkg.DeleteMetricValues(
		in_region_sid,
		in_ind_sid
	);
	
	-- Get the yes/no val
	v_val_yes := UNSEC_ValFromCustom(in_ind_sid, 'Yes');
	v_val_no := UNSEC_ValFromCustom(in_ind_sid, 'No');
	
	FOR r IN (
		SELECT effective_date, LOWER(str) str_val
		  FROM est_space s, est_space_attr sa
		 WHERE s.region_sid = in_region_sid
		   AND s.est_account_sid = in_est_account_sid
		   AND sa.est_account_sid = s.est_account_sid
		   AND sa.pm_customer_id = s.pm_customer_id
		   AND sa.pm_building_id = s.pm_building_id
		   AND sa.pm_space_id = s.pm_space_id
		   AND LOWER(sa.attr_name) = LOWER(in_mapping_name)
		   AND sa.str IS NOT NULL
	) LOOP
		-- Set the region metric 
		region_metric_pkg.SetMetricValue(
			in_region_sid,
			in_ind_sid,
			r.effective_date,
			CASE WHEN r.str_val = 'yes' OR r.str_val = 'y' THEN v_val_yes ELSE v_val_no END,
			NULL,
			NULL,
			in_measure_conversion_id,
			csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
			v_val_id
		);
	END LOOP;
END;

PROCEDURE HelperCustomSpaceAttr(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
)
AS
	v_val_id					val.val_id%TYPE;
	v_val						val.val_number%TYPE;
BEGIN	
	-- This will ensure the region metric is set-up correctly
	region_metric_pkg.SetMetric(in_ind_sid);

	-- Clear any existing metric values
	region_metric_pkg.DeleteMetricValues(
		in_region_sid,
		in_ind_sid
	);
	
	FOR r IN (
		SELECT effective_date, str
		  FROM est_space s, est_space_attr sa
		 WHERE s.region_sid = in_region_sid
		   AND s.est_account_sid = in_est_account_sid
		   AND sa.est_account_sid = s.est_account_sid
		   AND sa.pm_customer_id = s.pm_customer_id
		   AND sa.pm_building_id = s.pm_building_id
		   AND sa.pm_space_id = s.pm_space_id
		   AND LOWER(sa.attr_name) = LOWER(in_mapping_name)
		   AND sa.str IS NOT NULL
	) LOOP 
		-- Fetch custom field's corrasponding val number
		v_val := UNSEC_ValFromCustom(in_ind_sid, r.str);
		IF v_val IS NOT NULL THEN
			-- Set the region metric 
			region_metric_pkg.SetMetricValue(
				in_region_sid,
				in_ind_sid,
				r.effective_date,
				v_val,
				NULL,
				NULL,
				in_measure_conversion_id,
				csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
				v_val_id
			);
		END IF;
	END LOOP;
END;

PROCEDURE HelperDistributionCenter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
)
AS
	v_val_id					val.val_id%TYPE;
	v_val						val.val_number%TYPE;
	v_count						NUMBER;
	v_year_built				est_building.year_built%TYPE;
BEGIN	
	
	-- Fetch the building's year built
	SELECT year_built
	  INTO v_year_built
	  FROM est_building b, est_space s
	 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND s.est_account_sid = in_est_account_sid
	   AND s.region_sid = in_region_sid
	   AND b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND b.est_account_sid = in_est_account_sid
	   AND b.pm_building_id = s.pm_building_id;

	-- Is this space a distribution center
	SELECT COUNT(*)
	  INTO v_count
	  FROM est_space s
	 WHERE s.region_sid = in_region_sid
	   AND s.space_type = 'distributionCenter';
	
	-- This will ensure the region metric is set-up correctly
	region_metric_pkg.SetMetric(in_ind_sid);

	-- Don't clear existing values
	   
	IF v_count = 0 THEN
		v_val := UNSEC_ValFromCustom(in_ind_sid, 'No');
	ELSE
		v_val := UNSEC_ValFromCustom(in_ind_sid, 'Yes');
	END IF;
	
	IF v_val IS NOT NULL THEN
		-- Set the region metric for current period
		region_metric_pkg.SetMetricValue(
			in_region_sid,
			in_ind_sid,
			TRUNC(SYSDATE, 'MONTH'),
			v_val,
			NULL,
			NULL,
			in_measure_conversion_id,
			csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
			v_val_id
		);
		-- Set the region metric for year built if available
		IF v_year_built IS NOT NULL THEN
			region_metric_pkg.SetMetricValue(
				in_region_sid,
				in_ind_sid,
				TRUNC(TO_DATE(v_year_built, 'YYYY'), 'YEAR'),
				v_val,
				NULL,
				NULL,
				in_measure_conversion_id,
				csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
				v_val_id
			);
		END IF;
	END IF;
	
END;

PROCEDURE HelperOfficeCooledHeated(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
)
AS
	v_val_id					val.val_id%TYPE;
	v_str_none_cool				VARCHAR2(20) := 'Not Air Conditioned';
	v_str_none_heat				VARCHAR2(20) := 'Not Heated';
	v_str_less					VARCHAR2(20) := 'Less than 50%';
	v_str_more					VARCHAR2(20) := '50% or more';
	v_val_none					val.val_number%TYPE := 0.00;
	v_val_less					val.val_number%TYPE := 0.25;
	v_val_more					val.val_number%TYPE := 0.75;
BEGIN
	
	-- This will ensure the region metric is set-up correctly
	region_metric_pkg.SetMetric(in_ind_sid);
	
	-- Clear any existing metric values
	region_metric_pkg.DeleteMetricValues(
		in_region_sid,
		in_ind_sid
	);
	
	FOR r IN (
		SELECT effective_date, str str_val
		  FROM est_space s, est_space_attr sa
		 WHERE s.region_sid = in_region_sid
		   AND s.est_account_sid = in_est_account_sid
		   AND sa.est_account_sid = s.est_account_sid
		   AND sa.pm_customer_id = s.pm_customer_id
		   AND sa.pm_building_id = s.pm_building_id
		   AND sa.pm_space_id = s.pm_space_id
		   AND LOWER(sa.attr_name) = LOWER(in_mapping_name)
		   AND sa.str IN (
		   		v_str_none_cool, 
		   		v_str_none_heat, 
		   		v_str_less, 
		   		v_str_more
		   )
	) LOOP
		-- Set the region metric 
		region_metric_pkg.SetMetricValue(
			in_region_sid,
			in_ind_sid,
			r.effective_date,
			CASE 
				WHEN r.str_val = v_str_none_cool THEN v_val_none
				WHEN r.str_val = v_str_none_heat THEN v_val_none
				WHEN r.str_val = v_str_less THEN v_val_less
				WHEN r.str_val = v_str_more THEN v_val_more
			END,
			NULL,
			NULL,
			in_measure_conversion_id,
			csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
			v_val_id
		);
	END LOOP;
END;

END;
/
