create or replace PACKAGE BODY     csr.meter_pkg IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);
/*
Fixed for cost indicator: (check c#)
	Getmeter
	MakeMeter
	PropogateMeterDetails

Need fixing for cost indicator:
	getmeterlist
	getmeterlistforexport
	GetFullMeterListForExport
	GetRates
*/

-- Not super efficient to keep calling as a function, but the query would be nasty
-- Other option would be to add a column to meter called "location_sid" or something
-- and then adjust this when thigns get moved around the region tree.
-- and then adjust this when thigns get moved around the region tree.
-- XXX: this currently ignores region soft links
FUNCTION INTERNAL_GetProperty(
    in_region_sid	IN	security_pkg.T_SID_ID
)
RETURN VARCHAR2
AS
    v_property_sid  security_pkg.T_SID_ID;
    v_description   region_description.description%TYPE;
    v_city_name		region_description.description%TYPE;
BEGIN
    WITH pro AS (               
         SELECT region_sid, description, region_type
           FROM v$region 
          WHERE CONNECT_BY_ISLEAF = 1
          START WITH region_sid = in_region_sid
        CONNECT BY PRIOR parent_sid = region_sid
            AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
     )
    SELECT CASE 
            WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.region_sid 
            ELSE pr.region_sid -- just use parent
           END property_sid,
           CASE 
            WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.description
            ELSE pr.description -- just use parent
           END LOCATION,
           c.city_name
      INTO v_property_sid, v_description, v_city_name
      FROM pro, region r
        JOIN v$region pr ON pr.region_sid = r.parent_sid
        LEFT JOIN postcode.city c ON r.geo_city_id = c.city_id
     WHERE r.region_sid = in_region_sid;
    
   /* IF v_city_name IS NOT NULL THEN
		RETURN v_description || ' ('||v_city_name||')';
    ELSE
    */
		-- for now we've removed the city name as it was confusing on some sites
		RETURN v_description;
	--END IF;
END;

-- The indicator package's version of delete val does some security checks that are not 
-- performed if calling SetValueWithReasonWithSid directly, to make the required permissions 
-- the same as for setting values through metering use our own delete val procedure which 
-- calls SetValueWithReasonWithSid directly.
PROCEDURE INTERNAL_DeleteVal(
	in_val_id	IN	val.val_id%TYPE
)
AS
	CURSOR c IS		
		SELECT ind_sid, region_sid, period_start_dtm, period_end_dtm
		  FROM val
		 WHERE val_id = in_val_id;
	r	c%ROWTYPE;
	v_val_id	val.val_id%TYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	indicator_pkg.SetValueWithReasonWithSid(
		security_pkg.GetSID, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, 
		NULL, 0, csr_data_pkg.SOURCE_TYPE_DIRECT, NULL, NULL, NULL, NULL, 0, 'Value deleted by metering', NULL, v_val_id);
END;

PROCEDURE INTERNAL_RecomputeValueData(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_has_rates				BOOLEAN;
	v_count					NUMBER;
	v_min_dtm				DATE;
	v_max_dtm				DATE;
	v_region_type			region.region_type%TYPE;
BEGIN 
	FOR r IN (
		SELECT region_sid, region_type
		  FROM region
		 WHERE parent_sid = in_region_sid
	) LOOP
		INTERNAL_RecomputeValueData(r.region_sid);
		IF r.region_type = csr_data_pkg.REGION_TYPE_RATE THEN
			v_has_rates := TRUE;
		END IF;
	END LOOP;
	
	-- Only process at the leaf node level
	IF v_has_rates THEN
		RETURN;
	END IF;
	
	-- Remove any old data
	 FOR v IN (
		SELECT val_id 
		  FROM val
		 WHERE region_sid = in_region_sid
		   AND (source_type_id = csr_data_pkg.SOURCE_TYPE_METER
		     OR source_type_id = csr_data_pkg.SOURCE_TYPE_REALTIME_METER)
	) LOOP
		INTERNAL_DeleteVal(v.val_id);
	END LOOP;

	SELECT region_type
	  INTO v_region_type
	  FROM region
	 WHERE region_sid = in_region_sid;

	IF v_region_type = csr_data_pkg.REGION_TYPE_METER OR 
	   v_region_type = csr_data_pkg.REGION_TYPE_RATE THEN
		-- This is a normal meter - recompute system 
		-- data from existing meter readings
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$meter_reading
		 WHERE region_sid = in_region_sid;
		
		IF v_count > 0 THEN
			-- Get the min and max reading dates
			SELECT MIN(start_dtm), NVL(MAX(end_dtm), MAX(start_dtm))
			  INTO v_min_dtm, v_max_dtm
			  FROM v$meter_reading
			 WHERE region_sid = in_region_sid;
			-- Recalcualte new values data based on current meter readings
			SetValTableForPeriod(in_region_sid, 0, v_min_dtm, v_max_dtm);
		END IF;
		
	ELSIF v_region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER THEN
		-- This is a real-time meter, re-export the system 
		-- values from the real-time metering module
		meter_monitor_pkg.ExportSystemValues(in_region_sid);
	END IF;
	
END;

PROCEDURE INTERNAL_RefreshSubMeterAggr(
	in_region_sid			security_pkg.T_SID_ID
)
AS
BEGIN
	-- Check for calculated sub meters...
	FOR r IN (
		-- Where there's a child calculated sub-meter
		SELECT DISTINCT 1
		  FROM all_meter cm
		  JOIN region cr ON cm.region_sid = cr.region_sid
		  JOIN meter_source_type mst ON cm.meter_source_type_id = mst.meter_source_type_id
		 WHERE cr.parent_sid = in_region_sid
		   AND mst.is_calculated_sub_meter = 1
		UNION
		-- Where there's a sibling calculated sub-meter
		SELECT DISTINCT 1
		  FROM all_meter sm
		  JOIN region sr ON sm.region_sid = sr.region_sid
		  JOIN region pr ON sr.parent_sid = pr.region_sid
		  JOIN region r ON pr.region_sid = r.parent_sid
		  JOIN meter_source_type mst ON sm.meter_source_type_id = mst.meter_source_type_id
		 WHERE r.region_sid = in_region_sid
		   AND mst.is_calculated_sub_meter = 1
	) LOOP
		-- Only one or zero rows will ever be returned from the loop query
		FOR g IN (
			SELECT name
			  FROM aggregate_ind_group
			 WHERE name = 'CalculatedSubMeter'
		) LOOP
			-- Refresh the aggregate group
			aggregate_ind_pkg.RefreshGroup(g.name);
		END LOOP;
	END LOOP;
END;

PROCEDURE INTERNAL_ImportRealtimeRows
AS
BEGIN
	FOR region IN (
		SELECT DISTINCT tmrr.region_sid, tmrr.unit_of_measure
		  FROM temp_meter_reading_rows tmrr
		  JOIN all_meter am ON tmrr.region_sid = am.region_sid
		  JOIN meter_input_aggr_ind ai ON ai.region_sid = tmrr.region_sid AND ai.meter_input_id = tmrr.meter_input_id AND ai.aggregator = 'SUM'
		 WHERE (am.manual_data_entry = 0 OR tmrr.priority IS NOT NULL)
		   AND tmrr.error_msg IS NULL 
	)
	LOOP
		meter_monitor_pkg.ClearInsertData();

		FOR row IN (
			SELECT tmrr.source_row, tmrr.start_dtm, tmrr.end_dtm, tmrr.meter_input_id,
			       tmrr.consumption, tmrr.priority, tmrr.note, tmrr.statement_id
			  FROM temp_meter_reading_rows tmrr
			  JOIN all_meter am ON tmrr.region_sid = am.region_sid
			  JOIN meter_input_aggr_ind ai ON ai.region_sid = tmrr.region_sid AND ai.meter_input_id = tmrr.meter_input_id AND ai.aggregator = 'SUM'
			 WHERE (am.manual_data_entry = 0 OR tmrr.priority IS NOT NULL)
			   AND tmrr.region_sid = region.region_sid
			   AND tmrr.error_msg IS NULL
			   AND ((tmrr.unit_of_measure  = region.unit_of_measure) OR (tmrr.unit_of_measure IS NULL AND region.unit_of_measure IS NULL))
		) LOOP
			IF csr_data_pkg.IsPeriodLocked(SYS_CONTEXT('SECURITY', 'APP'), row.start_dtm, row.end_dtm) = 1 THEN
				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Reading date inside data lock period'
				 WHERE region_sid = region.region_sid
				   AND source_row = row.source_row
				   AND meter_input_id = row.meter_input_id;
			ELSIF row.consumption IS NOT NULL THEN
				meter_monitor_pkg.PrepareInsertData(
					in_start_dtm		=>	row.start_dtm,
					in_end_dtm			=>	row.end_dtm,
					in_consumption		=>	row.consumption,
					in_meter_input_id	=>	row.meter_input_id,
					in_source_row		=>	row.source_row,
					in_priority			=> 	row.priority,
					in_note				=>	row.note,
					in_statement_id		=>	row.statement_id
				);
			ELSE
				UPDATE temp_meter_reading_rows
				   SET error_msg = 'The value must be specified.'
				 WHERE region_sid = region.region_sid
				   AND source_row = row.source_row
				   AND meter_input_id = row.meter_input_id;
			END IF;
		END LOOP;

		BEGIN
			-- Hand off to the raw_data importer
			meter_monitor_pkg.InsertLiveData(
				in_region_sid	=>	region.region_sid,
				in_raw_data_id	=>	NULL,
				in_uom			=>	region.unit_of_measure,
				in_is_estimate	=>	0,
				in_raise_issues	=>	0
			);
		EXCEPTION
			-- Skip the region and unit measure combination.
			WHEN meter_monitor_pkg.NO_CONVERSION_FOUND THEN
				DECLARE v_error VARCHAR(4000) := SQLERRM;
				BEGIN
					UPDATE temp_meter_reading_rows
					   SET error_msg = v_error
					 WHERE region_sid = region.region_sid
					   AND ((unit_of_measure  = region.unit_of_measure) OR (unit_of_measure IS NULL AND region.unit_of_measure IS NULL));
				END;
		END;

		-- Copy any error messages generated by InsertLiveData to temp_meter_reading_rows
		UPDATE temp_meter_reading_rows tmrr
		   SET error_msg =
				(SELECT mid.error_msg
				   FROM meter_insert_data mid
				  WHERE mid.source_row = tmrr.source_row
				    AND meter_input_id = tmrr.meter_input_id)
		 WHERE (tmrr.source_row,tmrr.meter_input_id) IN
				(SELECT source_row, meter_input_id
				   FROM meter_insert_data
				  WHERE error_msg IS NOT NULL)
		   AND tmrr.region_sid = region.region_sid
		   AND ((tmrr.unit_of_measure  = region.unit_of_measure) OR (tmrr.unit_of_measure IS NULL AND region.unit_of_measure IS NULL))
		   AND tmrr.error_msg IS NULL;
	END LOOP;

	-- Export indicator values for all processed meter regions
	meter_monitor_pkg.BatchExportSystemValues;
END;

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_Id
)
AS
	v_helper_pkg		metering_options.metering_helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one
	BEGIN
		SELECT metering_helper_pkg
		  INTO v_helper_pkg
		  FROM metering_options
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

FUNCTION IsMeteringEnabled
RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM customer_region_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_type = csr_data_pkg.REGION_TYPE_METER;
	
	IF v_count > 0 THEN 
		v_count := 1;
	END IF;
	
	RETURN v_count;
END;

/*
PROCEDURE SetCostValDataForPeriod(	
	in_meter_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE
)	
AS
	v_cur					SYS_REFCURSOR;
	v_peirods_tbl		 	T_NORMALISED_VAL_TABLE;
	v_val_id				VAL.VAL_ID%TYPE;
	v_cost_ind_sid			security_pkg.T_SID_ID;
	v_cost_conv_id			all_meter.cost_measure_conversion_id%TYPE;
	v_period_set_id			meter_source_type.period_set_id%TYPE;
	v_period_interval_id	meter_source_type.period_interval_id%TYPE;
BEGIN
	SELECT cost_ind_sid, cost_measure_conversion_id, st.period_set_id, st.period_interval_id
	  INTO v_cost_ind_sid, v_cost_conv_id, v_period_set_id, v_period_interval_id
	  FROM all_meter m, meter_source_type st
	 WHERE region_sid = in_meter_sid
	   AND st.meter_source_type_id = m.meter_source_type_id;
	 
	IF v_cost_ind_sid IS NULL THEN
		-- no ind_sid, nothing to do...
		RETURN;
	END IF;
	
	OPEN v_cur FOR	 
		SELECT r.region_sid, r.start_dtm, r.end_dtm, r.cost val_number
		  FROM v$meter_reading r
		  JOIN meter m ON r.region_sid = m.region_sid
		 WHERE r.start_dtm < in_end_dtm
		   AND r.end_dtm > in_start_dtm
		   AND r.region_sid = in_meter_sid
		 ORDER BY r.start_dtm;
	 	 
	v_peirods_tbl := period_pkg.AggregateOverTime(v_cur, in_start_dtm, in_end_dtm, v_period_set_id, v_period_interval_id);
	
	FOR r IN (
		SELECT region_sid, start_dtm, end_dtm, val_number
		  FROM TABLE(v_peirods_tbl)
	)
	LOOP
		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 			=> security_pkg.getSid,
			in_ind_sid 				=> v_cost_ind_sid,
			in_region_sid 			=> r.region_sid,
			in_period_start 		=> r.start_dtm,
			in_period_end 			=> r.end_dtm,
			in_val_number			=> measure_pkg.UNSEC_GetBaseValue(r.val_number, v_cost_conv_id, r.start_dtm),
			in_entry_val_number		=> r.val_number,
			in_entry_conversion_id	=> v_cost_conv_id,
			in_reason				=> 'Merged from meter',
			in_source_type_id		=> csr_data_pkg.SOURCE_TYPE_METER,
			out_val_id				=> v_val_id
		);
	END LOOP;
	
END;
*/

PROCEDURE SetDaysValDataForPeriod(	
	in_meter_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE
)	
AS
	v_cur					SYS_REFCURSOR;
	v_peirods_tbl 			T_NORMALISED_VAL_TABLE;
	v_val_id				VAL.VAL_ID%TYPE;
	v_days_ind_sid			security_pkg.T_SID_ID;
	v_period_set_id			metering_options.period_set_id%TYPE;
	v_period_interval_id	metering_options.period_interval_id%TYPE;
BEGIN
	SELECT days_ind_sid
	  INTO v_days_ind_sid
	  FROM v$legacy_meter m
	 WHERE region_sid = in_meter_sid;
	   
	SELECT period_set_id, period_interval_id
	  INTO v_period_set_id, v_period_interval_id
	  FROM metering_options;
	 
	IF v_days_ind_sid IS NULL THEN
		-- no ind_sid, nothing to do...
		RETURN;
	END IF;
	
	OPEN v_cur FOR
		SELECT r.region_sid, r.start_dtm, r.end_dtm, r.end_dtm - r.start_dtm val_number
		  FROM v$meter_reading r
		  JOIN v$meter m ON r.region_sid = m.region_sid
		 WHERE r.start_dtm < in_end_dtm
		   AND r.end_dtm > in_start_dtm -- restrict to the requested period
		   AND r.region_sid = in_meter_sid
		   AND r.val_number IS NOT NULL
		 ORDER BY r.start_dtm;
	 	 
	v_peirods_tbl := period_pkg.AggregateOverTime(v_cur, in_start_dtm, in_end_dtm, v_period_set_id, v_period_interval_id);
	
	FOR r IN (
		SELECT region_sid, start_dtm, end_dtm, val_number
		  FROM TABLE(v_peirods_tbl)
	)
	LOOP
		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 		=> security_pkg.getSid,
			in_ind_sid 			=> v_days_ind_sid,
			in_region_sid 		=> r.region_sid,
			in_period_start 	=> r.start_dtm,
			in_period_end 		=> r.end_dtm,
			in_val_number		=> r.val_number,
			in_reason			=> 'Merged from meter',
			in_source_type_id	=> csr_data_pkg.SOURCE_TYPE_METER,
			out_val_id			=> v_val_id
		);
	END LOOP;
	
END;

PROCEDURE SetCostDaysValDataForPeriod(	
	in_meter_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE
)	
AS
	v_cur					SYS_REFCURSOR;
	v_peirods_tbl 			T_NORMALISED_VAL_TABLE;
	v_val_id				VAL.VAL_ID%TYPE;
	v_days_ind_sid			security_pkg.T_SID_ID;
	v_period_set_id			metering_options.period_set_id%TYPE;
	v_period_interval_id	metering_options.period_interval_id%TYPE;
BEGIN
	SELECT costdays_ind_sid
	  INTO v_days_ind_sid
	  FROM v$legacy_meter m
	 WHERE region_sid = in_meter_sid;
  	   
  	SELECT period_set_id, period_interval_id
  	  INTO v_period_set_id, v_period_interval_id
  	  FROM metering_options;
	 
	IF v_days_ind_sid IS NULL THEN
		-- no ind_sid, nothing to do...
		RETURN;
	END IF;
	
	OPEN v_cur FOR
		SELECT r.region_sid, r.start_dtm, r.end_dtm, r.end_dtm - r.start_dtm val_number
		  FROM v$meter_reading r
		  JOIN v$meter m ON r.region_sid = m.region_sid
		 WHERE r.start_dtm < in_end_dtm
		   AND r.end_dtm > in_start_dtm -- restrict to the requested period
		   AND r.region_sid = in_meter_sid
		   AND r.cost IS NOT NULL
		 ORDER BY r.start_dtm;
		
	 	 
	v_peirods_tbl := period_pkg.AggregateOverTime(v_cur, in_start_dtm, in_end_dtm, v_period_set_id, v_period_interval_id);
	
	FOR r IN (
		SELECT region_sid, start_dtm, end_dtm, val_number
		  FROM TABLE(v_peirods_tbl)
	)
	LOOP
		-- currently we ignore costdays_measure_conversion_id
		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 		=> security_pkg.getSid,
			in_ind_sid 			=> v_days_ind_sid,
			in_region_sid 		=> r.region_sid,
			in_period_start 	=> r.start_dtm,
			in_period_end 		=> r.end_dtm,
			in_val_number		=> r.val_number,
			in_reason			=> 'Merged from meter',
			in_source_type_id	=> csr_data_pkg.SOURCE_TYPE_METER,
			out_val_id			=> v_val_id
		);
	END LOOP;
	
END;

/* in_is_delete_reading_id => if you are calculating for a row you're about to delete,
   then this should be the reading_id for the row you're going to delete. If you're updating
   or have inserted, then it should be null
 */
PROCEDURE SetValTableForPeriod(
	in_meter_sid			IN	security_pkg.T_SID_ID,
	in_is_delete_reading_id	IN	security_pkg.T_SID_ID,
	in_min_dtm 				IN	DATE, 
	in_max_dtm 				IN	DATE
)
AS
	v_fwd_estimate_meters	metering_options.fwd_estimate_meters%TYPE;
	v_max_end_dtm			DATE;
	v_max_end_period		DATE;
	v_period_set_id			metering_options.period_set_id%TYPE;
	v_period_interval_id	metering_options.period_interval_id%TYPE;
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;
	v_descending			meter_source_type.descending%TYPE;
	v_region_date_clipping	metering_options.region_date_clipping%TYPE;
	v_data_priority			meter_data_priority.priority%TYPE;
	v_estimate_priority		meter_data_priority.priority%TYPE;
	v_consumption_input_id	meter_input.meter_input_id%TYPE;
	v_cost_input_id			meter_input.meter_input_id%TYPE;
	v_min_dtm				DATE;
	v_max_dtm				DATE;
	v_metering_version		all_meter.metering_version%TYPE;
BEGIN
	-- Collect some useful information
	SELECT st.arbitrary_period, st.descending, mdp.priority, m.metering_version
	  INTO v_arbitrary_period, v_descending, v_data_priority, v_metering_version
	  FROM all_meter m, meter_source_type st, meter_data_priority mdp
	  WHERE m.region_sid = in_meter_sid
	   AND st.meter_source_type_id = m.meter_source_type_id
	   AND mdp.is_input = 1
	   AND mdp.lookup_key = 'LO_RES';

	BEGIN
		SELECT mdp.priority
		  INTO v_estimate_priority
		  FROM all_meter m, meter_source_type st, meter_data_priority mdp
		 WHERE m.region_sid = in_meter_sid
		   AND st.meter_source_type_id = m.meter_source_type_id
		   AND mdp.is_input = 1
		   AND mdp.lookup_key = 'ESTIMATE';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_estimate_priority := v_data_priority;
	END;

	SELECT region_date_clipping, period_set_id, period_interval_id
	  INTO v_region_date_clipping, v_period_set_id, v_period_interval_id
	  FROM metering_options;
	
	SELECT meter_input_id
	  INTO v_consumption_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';

	SELECT meter_input_id
	  INTO v_cost_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'COST';

	-- 1. Convert the data into consumption style data for both point and arbitrary period data and select into a temp table.
	-- 2. Do any pro rata extension in the temp table.
	-- 3. Pass off to the real-time metering module for final processing

	-- Fill in the temporary table with consumption style data
	-- This temp table might be used more than once per transaction (imports)
	-- but is only used in this procedure so delete all existing rows befroe we start
	DELETE FROM temp_meter_consumption;
	
	IF v_arbitrary_period = 0 THEN
		-- Point in time
		INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, per_diem)
			SELECT region_sid, v_consumption_input_id, DECODE(is_estimate, 0, v_data_priority, v_estimate_priority), start_dtm, end_dtm, consumption,
				CASE WHEN start_dtm < end_dtm THEN
					consumption / (end_dtm - start_dtm)
				ELSE NULL END per_diem
			  FROM (
				SELECT r.region_sid, r.start_dtm, LEAD(r.start_dtm) OVER (ORDER BY r.start_dtm) end_dtm,
					-- Just add-up the is_estimate flags, if > 0 then this is an estimate (decoded above).
					r.is_estimate + LEAD(r.is_estimate) OVER (ORDER BY r.start_dtm) is_estimate,
					CASE WHEN v_descending = 0 THEN
						-- Normal ascending meter (electricity etc.)
						LEAD(r.val_number) OVER (ORDER BY r.start_dtm) + NVL(LEAD(r.baseline_val) OVER (ORDER BY r.start_dtm), 0) - r.val_number - NVL(r.baseline_val, 0)
					ELSE
						-- Descending meter (oil tank etc.)
						r.val_number + NVL(r.baseline_val, 0) - LEAD(r.val_number) OVER (ORDER BY r.start_dtm) - NVL(LEAD(r.baseline_val) OVER (ORDER BY r.start_dtm), 0)
					END consumption
				  FROM v$meter_reading r
				 WHERE r.region_sid = in_meter_sid
				   AND r.meter_reading_id != NVL(in_is_delete_reading_id, -1)
				   AND r.val_number IS NOT NULL
			 )
			 WHERE end_dtm IS NOT NULL;
	ELSE
		-- Arbitrary period
		INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, per_diem)
			SELECT region_sid, v_consumption_input_id, DECODE(is_estimate, 0, v_data_priority, v_estimate_priority), start_dtm, end_dtm, val_number,
				CASE WHEN start_dtm < end_dtm THEN
					val_number / (end_dtm - start_dtm)
				ELSE NULL END per_diem
			  FROM v$meter_reading
			 WHERE region_sid = in_meter_sid
			   AND meter_reading_id != NVL(in_is_delete_reading_id, -1);

		-- Add the cost data to the temp table (computation moved into real-time metering) [cost only valid for arbitrary period meters]
		INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, per_diem)
			SELECT r.region_sid, v_cost_input_id, DECODE(r.is_estimate, 0, v_data_priority, v_estimate_priority), r.start_dtm, r.end_dtm, r.cost, 
				CASE WHEN r.start_dtm < r.end_dtm THEN
						r.cost / (r.end_dtm - r.start_dtm)
					ELSE NULL END per_diem
			  FROM v$meter_reading r
			 WHERE r.region_sid = in_meter_sid
			   AND r.meter_reading_id != NVL(in_is_delete_reading_id, -1);
	END IF;
	
	-- should we pro-rata data forward (currently to end of the month although this
	-- is really quite illogical -- it should be done on a batch basis forward in time
	-- to the present day for this to be sensible). 
	SELECT fwd_estimate_meters 
	  INTO v_fwd_estimate_meters
	  FROM metering_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	 IF v_fwd_estimate_meters != 0 THEN
		SELECT max_end_dtm, period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, max_end_dtm, 1)
		  INTO v_max_end_dtm, v_max_end_period
		  FROM (
			SELECT NVL(MAX(end_dtm), MAX(start_dtm)) max_end_dtm -- Point in time meters always have a null end_dtm in the reading table
			  FROM v$meter_reading
			 WHERE region_sid = in_meter_sid
		 );
		
		FOR r IN (
			SELECT region_sid, start_dtm, end_dtm, per_diem
			  FROM temp_meter_consumption
			 WHERE region_sid = in_meter_sid
			   AND meter_input_id = v_consumption_input_id
			   AND priority = v_data_priority
			   AND end_dtm = v_max_end_dtm
		) LOOP
			-- Only one row representing the last reading period
			UPDATE temp_meter_consumption
			   SET end_dtm = v_max_end_period,
			       val_number = r.per_diem * (v_max_end_period - r.start_dtm)
			 WHERE region_sid = r.region_sid
			   AND meter_input_id = v_consumption_input_id
			   AND priority = v_data_priority
			   AND start_dtm = r.start_dtm
			   AND end_dtm = r.end_dtm;
		END LOOP;
	END IF;	

	
	-- Lazy recomputation of all meter data for this meter when moving to the next metering version
	IF v_metering_version < CURRENT_METERING_VERSION THEN
		SELECT MIN(start_dtm), MAX(NVL(end_dtm, start_dtm))
		  INTO v_min_dtm, v_max_dtm
		  FROM temp_meter_consumption
		 WHERE region_sid = in_meter_sid
		   AND meter_input_id = v_consumption_input_id
		   AND priority = v_data_priority;

		UPDATE all_meter
		  SET metering_version = CURRENT_METERING_VERSION
		WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND region_sid = in_meter_sid;
	END IF;

	-- temp_meter_consumption might contain no data
	-- (the meter existed before the upgrade to the latest version but there was no data)
	v_min_dtm := NVL(v_min_dtm, in_min_dtm);
	v_max_dtm := NVL(v_max_dtm, in_max_dtm);

	
	-- Pass off the writing of data into the main system to the real-time metering module
	-- We also want the data to end-up in the real-time metering buckets where 
	-- it can be further processed/analysed by the real-time metering toolset
	meter_monitor_pkg.ComputePeriodicData(in_meter_sid, v_min_dtm, v_max_dtm, NULL);
	meter_monitor_pkg.BatchExportSystemValues;
	
	-- Compute days coverage data (not moved to real-time metering at this time)
	SetDaysValDataForPeriod(in_meter_sid, in_min_dtm, in_max_dtm);
	SetCostDaysValDataForPeriod(in_meter_sid, in_min_dtm, in_max_dtm);
	
	-- Nasty sub-meter thing
	INTERNAL_RefreshSubMeterAggr(in_meter_sid);
	
	-- Update the meter list cache table for this meter
	UpdateMeterListCache(in_meter_sid);
END;


/* inserts or clears data in monthly chunks to make aggregation up regions easier */
PROCEDURE INTERNAL_SetValTableForReading(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_meter_reading_id	IN	security_pkg.T_SID_ID,
	in_is_a_delete		IN  NUMBER,
	in_extend_min_dtm	IN	DATE,
	in_extend_max_dtm	IN	DATE
)
AS
	v_meter_sid			security_pkg.T_SID_ID;
	v_min_dtm			DATE;
	v_max_dtm			DATE;
BEGIN	
	-- figure out the meter sid
	SELECT region_sid
      INTO v_meter_sid
      FROM v$meter_reading
 	 WHERE meter_reading_id = in_meter_reading_id;

 	-- Find the least minimum dtm and the greatest 
 	-- maximum dtm (from that passed and from the reading).
 	SELECT LEAST(NVL(in_extend_min_dtm, min_dtm), min_dtm), GREATEST(NVL(in_extend_max_dtm, max_dtm), max_dtm)
	  INTO v_min_dtm, v_max_dtm
	  FROM (
		SELECT min_start_dtm min_dtm, NVL(max_end_dtm, max_start_dtm) max_dtm
		  FROM (     
			SELECT meter_reading_id,
				NVL(LAG(start_dtm) OVER (ORDER BY start_dtm), start_dtm) min_start_dtm,
				NVL(LEAD(start_dtm) OVER (ORDER BY start_dtm), start_dtm) max_start_dtm,
				NVL(LEAD(end_dtm) OVER (ORDER BY start_dtm), end_dtm) max_end_dtm
			  FROM v$meter_reading
			 WHERE region_sid = v_meter_sid
		 )
		 WHERE meter_reading_id = in_meter_reading_id
	);

	-- now update all affected data
	IF in_is_a_delete = 1 THEN
		SetValTableForPeriod(v_meter_sid, in_meter_reading_id, v_min_dtm, v_max_dtm);
	ELSE
		SetValTableForPeriod(v_meter_sid, null, v_min_dtm, v_max_dtm);
	END IF; 
END;

PROCEDURE SetValTableForReading(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_meter_reading_id	IN	security_pkg.T_SID_ID,
	in_is_a_delete		IN  NUMBER
)
AS
BEGIN
	INTERNAL_SetValTableForReading(
		in_act_id, 
		in_meter_reading_id, 
		in_is_a_delete, 
		NULL,
		NULL
	);
END;

PROCEDURE RecalcValTableForLastReading(
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN	
	-- Find the last reading for this meter (if any) and 
	-- recompute the val table entries for that reading.
	FOR r IN (
		SELECT meter_reading_id 
          FROM v$meter_reading mr, (
	          SELECT region_sid, MAX(start_dtm) max_reading_dtm 
	            FROM v$meter_reading
	           WHERE region_sid = in_region_sid
	           	GROUP BY region_sid
        	) x
         WHERE mr.region_sid = x.region_sid
           AND mr.start_dtm = x.max_reading_dtm
	) LOOP
		SetValTableForReading(security_pkg.GetACT, r.meter_reading_id, 0);
	END LOOP;
END;

PROCEDURE RecalcValtableFromDtm (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_from_dtm			IN	DATE
)
AS
	v_min_dtm			DATE;
	v_max_dtm			DATE;
BEGIN	
	v_min_dtm := in_from_dtm;

	IF v_min_dtm IS NULL THEN
		SELECT MIN(start_dtm)
		  INTO v_min_dtm
		  FROM v$meter_reading
		 WHERE region_sid = in_region_sid;
	END IF;
		
	SELECT NVL(MAX(end_dtm), MAX(start_dtm))
	  INTO v_max_dtm
	  FROM v$meter_reading
	 WHERE region_sid = in_region_sid;
	
	IF v_min_dtm IS NOT NULL AND v_max_dtm IS NOT NULL THEN
		SetValTableForPeriod(in_region_sid, NULL, v_min_dtm, v_max_dtm);
	END IF;
END;

PROCEDURE UtilityInvoiceFromReading (
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE
)
AS
	v_crc_metering_enabled	customer.crc_metering_enabled%TYPE;
BEGIN
	-- CRC Metering must be enabled to create an invoice entry
	SELECT crc_metering_enabled
	  INTO v_crc_metering_enabled
	  FROM customer;
	IF NVL(v_crc_metering_enabled, 0) = 0 THEN
		RETURN;
	END IF;

	-- Save the invoice data
	utility_pkg.SaveIvoiceFromReading(in_reading_id);
END;

/**
 * Set the meter reading for a given meter / reading_id 
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid              The meter sid (region sid)
 * @param    in_meter_reading_id        The meter reading id (null / 0 for new reading)
 * @param    in_reading_dtm             Date of reading
 * @param    in_val                     Meter value
 * @param    in_note                    Notes for reading
 * @param    in_user_sid                User sid of editor
 * @param    out_reading_id             The reading id of the reading just added
 *
 */
 PROCEDURE SetMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_note                 in meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
BEGIN
	SetMeterReading(
	    in_act_id               => in_act_id,
	    in_region_sid           => in_region_sid,
	    in_meter_reading_id     => in_meter_reading_id,
		in_entry_dtm			=> in_entry_dtm,
	    in_reading_dtm          => in_reading_dtm,
	    in_val                  => in_val,
	    in_note                 => in_note,
	    in_reference			=> in_reference,
	    in_cost					=> in_cost,
	    in_doc_id				=> in_doc_id,
	    in_cache_key			=> in_cache_key,
	    in_reset_val			=> NULL,
	    out_reading_id          => out_reading_id
	);
END;

PROCEDURE SetMeterReading(
	in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE	DEFAULT NULL,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
BEGIN
	SetMeterReading(
	    in_act_id               => in_act_id,
	    in_region_sid           => in_region_sid,
	    in_meter_reading_id     => in_meter_reading_id,
		in_entry_dtm			=> in_entry_dtm,
	    in_reading_dtm          => in_reading_dtm,
	    in_val                  => in_val,
	    in_val_conv_id          => in_val_conv_id,
	    in_note                 => in_note,
	    in_reference			=> in_reference,
	    in_cost					=> in_cost,
	    in_cost_conv_id			=> in_cost_conv_id,
	    in_doc_id				=> in_doc_id,
	    in_cache_key			=> in_cache_key,
	    in_reset_val			=> in_reset_val,
	    in_is_estimate				=> 0,
	    out_reading_id          => out_reading_id
	);
END;


PROCEDURE SetMeterReading(
	in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE	DEFAULT NULL,
    in_is_estimate			IN meter_reading.val_number%TYPE	DEFAULT 0,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
	v_prim_conv_id			measure_conversion.measure_conversion_id%TYPE;
	v_cost_conv_id			measure_conversion.measure_conversion_id%TYPE;
BEGIN
	
	SELECT primary_measure_conversion_id, cost_measure_conversion_id
	  INTO v_prim_conv_id, v_cost_conv_id
	  FROM v$legacy_meter
	 WHERE region_sid = in_region_sid;
	
	SetMeterReading(
		in_act_id,
	    in_region_sid,
	    in_meter_reading_id,
		in_entry_dtm,
	    in_reading_dtm,
	    measure_pkg.UNSEC_GetConvertedValue(
	    		measure_pkg.UNSEC_GetBaseValue(in_val, in_val_conv_id, in_reading_dtm), 
	    	v_prim_conv_id, in_reading_dtm),
	    in_note,
	    in_reference,
	    measure_pkg.UNSEC_GetConvertedValue(
	    		measure_pkg.UNSEC_GetBaseValue(in_cost, in_cost_conv_id, in_reading_dtm), 
	    	v_cost_conv_id, in_reading_dtm),
	    in_doc_id,
	    in_cache_key,
	    in_reset_val,
		in_is_estimate,
	    out_reading_id
	);
END;

PROCEDURE SetMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
BEGIN
	SetMeterReading(
	    in_act_id               => in_act_id,
	    in_region_sid           => in_region_sid,
	    in_meter_reading_id     => in_meter_reading_id,
		in_entry_dtm			=> in_entry_dtm,
	    in_reading_dtm          => in_reading_dtm,
	    in_val                  => in_val,
	    in_note                 => in_note,
	    in_reference			=> in_reference,
	    in_cost					=> in_cost,
	    in_doc_id				=> in_doc_id,
	    in_cache_key			=> in_cache_key,
	    in_reset_val			=> in_reset_val,
	    in_is_estimate			=> 0,
	    out_reading_id          => out_reading_id
	);
END;

FUNCTION INTERNAL_GetBaselineVal(
	in_meter_reading_id		IN	meter_reading.meter_reading_id%TYPE
) RETURN meter_reading.baseline_val%TYPE
AS
	v_baseline_val			meter_reading.baseline_val%TYPE;
BEGIN
	SELECT COALESCE(baseline_val, last_baseline_val, 0)
	  INTO v_baseline_val
	  FROM (
		SELECT meter_reading_id, baseline_val, LAG(baseline_val) OVER (ORDER BY start_dtm) last_baseline_val
		  FROM v$meter_reading_head
		 WHERE region_sid = (
		 	SELECT region_sid
		 	  FROM v$meter_reading_head
		 	 WHERE meter_reading_id = in_meter_reading_id
		 )
	 )
	 WHERE meter_reading_id = in_meter_reading_id;
	RETURN v_baseline_val;
END;
 
FUNCTION INTERNAL_GetPrevBaselineVal(
	in_meter_reading_id		IN	meter_reading.meter_reading_id%TYPE
) RETURN meter_reading.baseline_val%TYPE
AS
	v_baseline_val			meter_reading.baseline_val%TYPE;
BEGIN
	SELECT NVL(last_baseline_val, 0)
	  INTO v_baseline_val
	  FROM (
		SELECT meter_reading_id, LAG(baseline_val) OVER (ORDER BY start_dtm) last_baseline_val
		  FROM v$meter_reading_head
		 WHERE region_sid = (
		 	SELECT region_sid
		 	  FROM v$meter_reading_head
		 	 WHERE meter_reading_id = in_meter_reading_id
		 )
	 )
	 WHERE meter_reading_id = in_meter_reading_id;
	RETURN v_baseline_val;
END;

PROCEDURE INTERNAL_UpdateBaselineVal(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	in_reset_val			IN	meter_reading.val_number%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_val					meter_reading.val_number%TYPE;
	v_baseline				meter_reading.baseline_val%TYPE;
	v_new_baseline			meter_reading.baseline_val%TYPE;
	v_prev_baseline			meter_reading.baseline_val%TYPE;
	v_reading_dtm			meter_reading.start_dtm%TYPE;
	v_allow_reset			meter_source_type.allow_reset%TYPE;
	v_req_approval			meter_type.req_approval%TYPE;
BEGIN
	
	SELECT mr.val_number, mr.region_sid, mr.start_dtm, st.allow_reset, mt.req_approval
	  INTO v_val, v_region_sid, v_reading_dtm, v_allow_reset, v_req_approval
	  FROM v$meter_reading_all mr
	  JOIN all_meter m ON m.app_sid = mr.app_sid AND m.region_sid = mr.region_sid
	  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
	  JOIN meter_type mt ON m.app_sid = mt.app_sid AND m.meter_type_id = mt.meter_type_id
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.meter_reading_id = in_reading_id;

	-- Get the baseline vlaues
   	v_baseline := INTERNAL_GetBaselineVal(in_reading_id);
   	v_prev_baseline := INTERNAL_GetPrevBaselineVal(in_reading_id);
   	
   	-- If this reading is already a reset and the passed arguments 
   	-- contain a null reset val then clear the reset
   	IF v_baseline != v_prev_baseline AND
   	   in_reset_val IS NULL THEN
   	   	
   	   	UPDATE meter_reading
		   SET baseline_val = v_prev_baseline
		 WHERE region_sid = v_region_sid
		   AND meter_reading_id = in_reading_id;
		
		-- Update baseline and reading values after this change,
		-- up until the next time the baseline changes.
		-- We need to defer this step if approval is required.
		IF v_req_approval = 0 THEN 
			UPDATE meter_reading
			   SET val_number = NVL(baseline_val, 0) - v_prev_baseline + val_number,
			       baseline_val = v_prev_baseline
			 WHERE region_sid = v_region_sid
			   AND start_dtm > v_reading_dtm
			   AND NVL(baseline_val, 0) = v_baseline;
   	   	END IF;
   	   	
   	   	-- Now use the previous baseline
   	   	v_baseline := v_prev_baseline;
   	END IF;
   	
   	-- If this is a reset then we need to adjust the baseline
   	IF in_reset_val IS NOT NULL THEN
		
		-- Compute the new baseline value (recompute using the previous baseline value)
		v_new_baseline := v_val - in_reset_val + v_prev_baseline;
		
		-- Offset the current reading
		UPDATE meter_reading
		   SET val_number = in_reset_val
		 WHERE region_sid = v_region_sid
		   AND meter_reading_id = in_reading_id;
		
		-- Update baseline and reading values after this change,
		-- up until the next time the baseline changes.
		-- We need to defer this step if approval is required.
		IF v_req_approval = 0 THEN
			UPDATE meter_reading
			   SET val_number = val_number + NVL(baseline_val, 0) - v_new_baseline,
			       baseline_val = v_new_baseline
			 WHERE region_sid = v_region_sid
			   AND start_dtm > v_reading_dtm
			   AND NVL(baseline_val, 0) = v_baseline;
		END IF;
		
		-- Now use the new baseline
		v_baseline := v_new_baseline;
		
	END IF;
	
	-- Set the baseline for the reading
	IF v_baseline != 0 THEN
		UPDATE meter_reading
		   SET baseline_val = v_baseline
		 WHERE region_sid = v_region_sid
		   AND meter_reading_id = in_reading_id;
    END IF;
END;
 
PROCEDURE INTERNAL_CheckOptions(
	in_region_sid			IN security_pkg.T_SID_ID,
	in_entry_dtm			IN DATE,
	in_start_dtm			IN meter_reading.start_dtm%TYPE,
	in_end_dtm				IN meter_reading.end_dtm%TYPE,
	in_val					IN meter_reading.val_number%TYPE,
	in_note					IN meter_reading.note%TYPE
)
AS
	v_prevent_future_dates NUMBER := 0;
BEGIN
	SELECT prevent_manual_future_readings
	  INTO v_prevent_future_dates
	  FROM metering_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_prevent_future_dates > 0 AND (in_start_dtm > in_entry_dtm OR in_end_dtm > in_entry_dtm)
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_PREVENT_FUTURE_DATES, 'Reading dates can not be in the future');
	END IF;
END;

PROCEDURE INTERNAL_CheckTolerances(
    in_region_sid          IN security_pkg.T_SID_ID,
    in_start_dtm           IN meter_reading.start_dtm%TYPE, -- only used to fill v_start_dtm, don't use directly
    in_end_dtm             IN meter_reading.end_dtm%TYPE,
    in_val                 IN meter_reading.val_number%TYPE,
    in_note                IN meter_reading.note%TYPE
)
AS
    v_start_dtm                  meter_reading.end_dtm%TYPE;
    v_percentage_change          NUMBER(10,2);
    v_lower_threshold_percentage NUMBER(10,2);
    v_upper_threshold_percentage NUMBER(10,2);
    v_threshold_period_in_months NUMBER;
    v_val            		       meter_reading.val_number%TYPE;
BEGIN

  -- Oracle doesn't follow the ANSI SQL standard and treats empty strings as NULL
  -- so TRIM('   ') IS NULL would evaluate as true
    IF TRIM(in_note) IS NULL THEN
  
        -- tolerance_type : 0 = none, 1 = last period (which we assume to be 1 month), 2 = last year
        SELECT (1 - ind.pct_lower_tolerance) * 100,
               (ind.pct_upper_tolerance - 1) * 100,
               case when tolerance_type = 1 then -1 when tolerance_type = 2 then -12 else 0 end
        INTO   v_lower_threshold_percentage,
               v_upper_threshold_percentage,
               v_threshold_period_in_months
        FROM   v$legacy_meter am,
               ind
        WHERE  am.region_sid = in_region_sid
        AND    ind.ind_sid = am.primary_ind_sid;

        IF in_start_dtm IS NULL THEN
          -- it's a point in time meter, find the previous reading's date and use this as the start date
          -- this could be NULL if there is no previous reading
          SELECT MAX(mr.start_dtm) INTO v_start_dtm FROM csr.meter_reading mr WHERE mr.start_dtm < in_end_dtm  and mr.REGION_SID = 21457704;
        ELSE
          SELECT in_start_dtm INTO v_start_dtm FROM DUAL;
        END IF;

        IF in_start_dtm IS NULL THEN
            -- it's a point in time meter, find the previous reading's value and delete this from the current value
            -- this could be NULL if there is no previous reading
            -- Can't use the LAG keyword as the current meter reading hasn't been stored yet
            SELECT in_val - (
                SELECT val_number
                  FROM csr.meter_reading mr3
                 WHERE mr3.region_sid = in_region_sid
                   AND mr3.start_dtm = (
                    SELECT MAX(mr2.start_dtm)
                      FROM csr.meter_reading mr2
                     WHERE mr2.start_dtm < in_end_dtm
                       AND mr2.region_sid = in_region_sid
                   )
            )
            INTO v_val
            FROM DUAL;
        ELSE
            SELECT in_val INTO v_val FROM DUAL;
        END IF;
      
        IF (    v_threshold_period_in_months < 0
            AND (v_upper_threshold_percentage IS NOT NULL OR v_lower_threshold_percentage IS NOT NULL)
            AND v_start_dtm IS NOT NULL
        ) THEN

            SELECT CASE WHEN old_daily_rate > 0 THEN (new_daily_rate - old_daily_rate) * 100 / old_daily_rate ELSE 0 END percentage_change
            INTO v_percentage_change
            FROM (
                SELECT SUM(days_included) total_days_included,
                       SUM(val_included) total_val_included,
                       CASE WHEN SUM(days_included) > 0 THEN SUM(val_included) / SUM(days_included) ELSE 0 END old_daily_rate,
                       CASE WHEN (in_end_dtm - v_start_dtm) != 0 THEN v_val / (in_end_dtm - v_start_dtm) ELSE 0 END new_daily_rate
                  FROM (   
                    SELECT (mr3.end_dtm - mr3.start_dtm) days,
                           -- days in this meter reading that are in the period we are looking
                           (LEAST(mr3.end_dtm, add_months(in_end_dtm, v_threshold_period_in_months)) - GREATEST(mr3.start_dtm, add_months(v_start_dtm, v_threshold_period_in_months))) days_included,
                           -- val_number multiplied by days_included (above)
                           (mr3.VAL_NUMBER * (LEAST(mr3.end_dtm, add_months(in_end_dtm, v_threshold_period_in_months)) - GREATEST(mr3.start_dtm, add_months(v_start_dtm, v_threshold_period_in_months))) / (mr3.end_dtm - mr3.start_dtm)) val_included
                      FROM (
                        -- The database stores the "point in time" meter reading date in the wrong column
                        -- when you enter a "point in time" meter reading it is the end of a period, but it is stored in the "start_dtm" column
                        -- and a NULL is stored in the "end_dtm" column
                      
                        -- If end_dtm IS NULL then "Point in time" so get the previous reading's date, otherwise "arbitrary period" so use start_dtm for start date
                        SELECT (CASE WHEN mr.end_dtm IS NULL
                                     THEN LAG (start_dtm,1) over (ORDER BY start_dtm)
                                     ELSE mr.start_dtm END) start_dtm,
                                   
                                -- If end_dtm IS NULL then "Point in time" so use start_dtm for end date, otherwise "arbitrary period" so use end_dtm for end date
                               (CASE WHEN mr.end_dtm IS NULL
                                     THEN mr.start_dtm
                                     ELSE mr.end_dtm END) end_dtm,
                                   
                                -- If end_dtm IS NULL then "Point in time" so find the previous reading and subtract its val_number from the current val_number
                               (CASE WHEN mr.end_dtm IS NULL
                                     THEN val_number - (LAG (val_number,1) over (ORDER BY start_dtm))
                                     ELSE val_number END) val_number
                          FROM csr.meter_reading mr
                         WHERE mr.region_sid = in_region_sid
                      ) mr3
                     WHERE mr3.end_dtm > add_months(v_start_dtm, v_threshold_period_in_months)
                       AND mr3.start_dtm < add_months(in_end_dtm, v_threshold_period_in_months)
                       AND mr3.val_number IS NOT NULL
                  )
            );

            IF v_upper_threshold_percentage IS NOT NULL AND v_percentage_change > v_upper_threshold_percentage THEN
                RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_READING_OVER_THRESHOLD, '$' || v_upper_threshold_percentage || '$' || v_threshold_period_in_months || '$');
            ELSIF v_lower_threshold_percentage IS NOT NULL AND v_percentage_change < (v_lower_threshold_percentage * -1) THEN
                RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_READING_UNDER_THRESHOLD, '$' || v_lower_threshold_percentage || '$' || v_threshold_period_in_months || '$');
            END IF;
          
        END IF;
    END IF;
END;

PROCEDURE SetMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE,
    in_is_estimate			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
	v_val_before_update     meter_reading.val_number%TYPE;
	v_from_previous			meter_reading.val_number%TYPE;
	v_to_next				meter_reading.val_number%TYPE;
	v_doc_id				meter_document.meter_document_id%TYPE;
	v_source				meter_reading.meter_source_type_id%TYPE;
	v_req_approval			meter_type.req_approval%TYPE;
	v_approved_reading_id	meter_reading.meter_reading_id%TYPE;
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_descending			meter_source_type.descending%TYPE;
	v_allow_reset			meter_source_type.allow_reset%TYPE;
	v_old_dtm				DATE;
	v_lock_end_dtm			DATE;
BEGIN
	-- check permission....
	-- note that we are using "read" here on the premise that if you can see the region (i.e. it's below your
	-- mount point) then you are allowed to fiddle with meter data.  Somebody entering data typically won't
	-- have write permission on the region because that implies they can edit the properties of the region object.
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter sid '||in_region_sid);
	END IF;
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;
	
	SELECT lock_end_dtm
	  INTO v_lock_end_dtm
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF in_reading_dtm < v_lock_end_dtm THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_WITHIN_LOCK_PERIOD, 'Meter data prior to ' || TO_CHAR(v_lock_end_dtm) || ' cannot be modified due to the system data lock');
	END IF;	

	SELECT m.meter_source_type_id, mt.req_approval, mt.flow_sid, st.descending, st.allow_reset
	  INTO v_source, v_req_approval, v_flow_sid, v_descending, v_allow_reset
	  FROM all_meter m
	  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
	  JOIN meter_type mt ON mt.app_sid = m.app_sid AND mt.meter_type_id = m.meter_type_id
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.region_sid = in_region_sid;

	IF v_allow_reset = 0 AND in_reset_val IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(ERR_RESET_NOT_ALLOWED, 'Reset not allowed for meter with sid '||in_region_sid);
	END IF;

	-- XXX: WHAT IF THERE'S A DATE CLASH
	-- XXX: CURRENTLY THIS CAUSES AN ERROR IN THE NORMALISATION CODE!

	-- We may need to modify this later 
	-- based on the approval requirement
	v_doc_id := in_doc_id;

    IF NVL(in_meter_reading_id, 0) = 0 THEN
        -- A new reading (no audit required)
        INSERT INTO meter_reading 
        	(region_sid, meter_reading_id, start_dtm,
			 val_number, note, entered_by_user_sid, entered_dtm, cost, meter_source_type_id, is_estimate,
			 req_approval, replaces_reading_id)
		  VALUES (in_region_sid, meter_reading_id_seq.NEXTVAL, in_reading_dtm,
				  in_val, in_note, security_pkg.GetSID, SYSDATE, in_cost, v_source, in_is_estimate,
				  v_req_approval, DECODE(v_req_approval, 0, NULL, DECODE(in_meter_reading_id, 0, NULL, NULL)))
		  RETURNING meter_reading_id INTO out_reading_id;
    ELSE
    	
    	-- Fetch the current value (before update)
		SELECT start_dtm, val_number 
		  INTO v_old_dtm, v_val_before_update
		  FROM v$meter_reading_all
		 WHERE region_sid = in_region_sid
		   AND meter_reading_id = in_meter_reading_id;
    	
    	-- Try and fetch the reading from the view of approved readings 
		-- (this will  tell us if it's been approved or not)
		BEGIN
	    	SELECT meter_reading_id
    		  INTO v_approved_reading_id
    		  FROM v$meter_reading
    		 WHERE meter_reading_id = in_meter_reading_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_approved_reading_id := NULL;
		END;
		
		IF v_approved_reading_id IS NOT NULL AND
		   v_req_approval != 0 THEN
		    -- The edit applies to an already approved reading.
		    -- Clear the doc id so we don't overwite the existing document before approval
		    v_doc_id := NULL;
		    
		    -- Insert a replacement reading pending approval
		    INSERT INTO meter_reading 
	        	(region_sid, meter_reading_id, start_dtm,
				val_number, note, entered_by_user_sid, entered_dtm, cost, meter_source_type_id, is_estimate,
				req_approval, replaces_reading_id)
			  VALUES (in_region_sid, meter_reading_id_seq.NEXTVAL, in_reading_dtm,
					in_val, in_note, security_pkg.GetSID, SYSDATE, in_cost, v_source,in_is_estimate,
					v_req_approval, DECODE(in_meter_reading_id, 0, NULL, in_meter_reading_id))
			  RETURNING meter_reading_id INTO out_reading_id;
    	
    		-- Audit the reading submission
    		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, in_region_sid, 
				'Meter reading submitted (pending approval) for {0} value changed from {1} to {2}', TO_CHAR(in_reading_dtm,'dd Mon yyyy'), v_val_before_update, in_val);
    	ELSE	   
			-- Now we can update the reading itself
	        UPDATE meter_reading
	           SET start_dtm = in_reading_dtm,
	               val_number = in_val,
	               note = in_note,
	               entered_by_user_sid = security_pkg.GetSID,
	               entered_dtm = SYSDATE,
	               reference = in_reference,
	               cost = in_cost,
	               meter_source_type_id = v_source,
				   is_estimate = in_is_estimate,
	               req_approval = v_req_approval
			 WHERE region_sid = in_region_sid
			   AND meter_reading_id = in_meter_reading_id;
			
			out_reading_id := in_meter_reading_id;
			
			-- Audit the reading change
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, in_region_sid, 
				'Meter reading for {0} changed from {1} to {2}', TO_CHAR(in_reading_dtm,'dd Mon yyyy'), v_val_before_update, in_val);
		END IF;
		
    END IF;
    
    -- Update the baseline if requred
    INTERNAL_UpdateBaselineVal(out_reading_id, in_reset_val); 
   
    -- check to see if it's up or down
	SELECT from_previous, to_next 
	  INTO v_from_previous, v_to_next
  	  FROM (
		 SELECT meter_reading_id, 
		 	val_number + NVL(baseline_val, 0) - LAG(val_number) OVER (ORDER BY start_dtm) - NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0) from_previous,
			LEAD(val_number) OVER (ORDER BY start_dtm) + NVL(LEAD(baseline_val) OVER (ORDER BY start_dtm), 0) - val_number - NVL(baseline_val, 0) to_next
		  FROM v$meter_reading_head 
		 WHERE region_sid = in_region_sid
     )
	 WHERE meter_reading_id = out_reading_id;

	-- Check the reading is in the correct range
	IF v_descending = 0 THEN
		IF v_from_previous < 0 THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_LOW, 'Meter reading too low');
		ELSIF v_to_next < 0 THEN 
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_HIGH, 'Meter reading too high');
		END IF;
    ELSE
    	IF v_from_previous > 0 THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_HIGH, 'Meter reading too high');
		ELSIF v_to_next > 0 THEN 
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_LOW, 'Meter reading too low');
		END IF;
	END IF;

	-- These will raise an error if the check fails
	INTERNAL_CheckTolerances(in_region_sid, NULL, in_reading_dtm, in_val, in_note);
	INTERNAL_CheckOptions(in_region_sid, in_entry_dtm, NULL, in_reading_dtm, in_val, in_note);

    -- Create a flow item if required
    IF v_flow_sid IS NOT NULL THEN
    	CreateFlowItemForReading(v_flow_sid, out_reading_id, v_flow_item_id);
    END IF;
	
	-- If no approval is required then v_doc_id = in_doc_id
	-- If approval is required then v_doc_id = NULL
	UpdateMeterDocFromCache(in_region_sid, v_doc_id, in_cache_key, v_doc_id);
	
	UPDATE meter_reading
	   SET meter_document_id = v_doc_id
	 WHERE meter_reading_id = out_reading_id;
	
	-- Only recompute system values or create invoices 
	-- if the reading didn't require approval
	-- New system values or invoices will be generated on approval if required
    IF v_req_approval = 0 THEN
		INTERNAL_SetValTableForReading(in_act_id, out_reading_id, 0, v_old_dtm, v_old_dtm);
		UtilityInvoiceFromReading(out_reading_id);
		-- Create energy star jobs if required
		energy_star_job_pkg.OnMeterReadingChange(in_region_sid, out_reading_id);
	END IF; 
END;

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
BEGIN
	SetArbitraryPeriod(
	    in_region_sid           => in_region_sid,
	    in_meter_reading_id     => in_meter_reading_id,
		in_entry_dtm			=> in_entry_dtm,
	    in_start_dtm          	=> in_start_dtm,
	    in_end_dtm          	=> in_end_dtm,
	    in_val                  => in_val,
	    in_val_conv_id          => in_val_conv_id,
	    in_note                 => in_note,
	    in_reference			=> in_reference,
	    in_cost					=> in_cost,
	    in_cost_conv_id			=> in_cost_conv_id,
	    in_doc_id				=> in_doc_id,
	    in_cache_key			=> in_cache_key,
	    in_is_estimate			=> 0,
	    out_reading_id          => out_reading_id
	);
END;

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
   in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_is_estimate			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
	v_prim_conv_id			measure_conversion.measure_conversion_id%TYPE;
	v_cost_conv_id			measure_conversion.measure_conversion_id%TYPE;
BEGIN
	
	SELECT primary_measure_conversion_id, cost_measure_conversion_id
	  INTO v_prim_conv_id, v_cost_conv_id
	  FROM v$legacy_meter
	 WHERE region_sid = in_region_sid;
	
	SetArbitraryPeriod(
	    in_region_sid,
	    in_meter_reading_id,
		in_entry_dtm,
	    in_start_dtm,
	    in_end_dtm,
	    measure_pkg.UNSEC_GetConvertedValue(
	    	measure_pkg.UNSEC_GetBaseValue(in_val, in_val_conv_id, in_start_dtm), 
	    	v_prim_conv_id, in_start_dtm),
	    in_note,
	    in_reference,
	    measure_pkg.UNSEC_GetConvertedValue(
	    	measure_pkg.UNSEC_GetBaseValue(in_cost, in_cost_conv_id, in_start_dtm), 
	    	v_cost_conv_id, in_start_dtm),
	    in_doc_id,
	    in_cache_key,
		in_is_estimate,
	    out_reading_id
	);
END;

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
)
AS
BEGIN
	SetArbitraryPeriod(
	    in_region_sid           => in_region_sid,
	    in_meter_reading_id     => in_meter_reading_id,
		in_entry_dtm			=> in_entry_dtm,
	    in_start_dtm          	=> in_start_dtm,
	    in_end_dtm          	=> in_end_dtm,
	    in_val                  => in_val,
	    in_note                 => in_note,
	    in_reference			=> in_reference,
	    in_cost					=> in_cost,
	    in_doc_id				=> in_doc_id,
	    in_cache_key			=> in_cache_key,
	    in_is_estimate			=> 0,
	    out_reading_id          => out_reading_id
	);
END;

PROCEDURE SetArbitraryPeriod(
	in_region_sid			IN security_pkg.T_SID_ID,
	in_meter_reading_id		IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
	in_start_dtm			IN meter_reading.start_dtm%TYPE,
	in_end_dtm				IN meter_reading.end_dtm%TYPE,
	in_val					IN meter_reading.val_number%TYPE,
	in_note					IN meter_reading.note%TYPE,
	in_reference			IN meter_reading.reference%TYPE,
	in_cost					IN meter_reading.cost%TYPE,
	in_doc_id				IN meter_document.meter_document_id%TYPE,
	in_cache_key			IN aspen2.filecache.cache_key%TYPE,
	in_is_estimate			IN meter_reading.val_number%TYPE,
	out_reading_id			OUT meter_reading.meter_reading_id%TYPE
)
AS
	v_doc_id				meter_document.meter_document_id%TYPE;
	v_source				meter_reading.meter_source_type_id%TYPE;
	v_req_approval			meter_type.req_approval%TYPE;
	v_approved_reading_id	meter_reading.meter_reading_id%TYPE;
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_old_start_dtm			DATE;
	v_old_end_dtm			DATE;
	v_lock_end_dtm			DATE;
BEGIN
	-- check permission - see rational in SetMeterReading
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter sid '||in_region_sid);
	END IF;
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;
	
	SELECT lock_end_dtm
	  INTO v_lock_end_dtm
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF in_start_dtm < v_lock_end_dtm OR in_end_dtm < v_lock_end_dtm THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_WITHIN_LOCK_PERIOD, 'Meter data prior to ' || TO_CHAR(v_lock_end_dtm) || ' cannot be modified due to the system data lock');
	END IF;

	SELECT m.meter_source_type_id, mt.req_approval, mt.flow_sid
	  INTO v_source, v_req_approval, v_flow_sid
	  FROM all_meter m
	  JOIN meter_source_type st ON st.meter_source_type_id = m.meter_source_type_id
	  JOIN meter_type mt ON mt.meter_type_id = m.meter_type_id
	 WHERE region_sid = in_region_sid;

	-- check the new period doesn't overlap an existing period
	-- (exclude the period being edited from the check)
	-- USE THE *HEAD* VIEW WHICH RETURNS LATEST READINGS EVEN IF THEY REQUIRE APPROVAL?
	FOR r IN (
		SELECT start_dtm, end_dtm
		  FROM v$meter_reading_head r
		 WHERE r.region_sid = in_region_sid
		   AND r.meter_reading_id != NVL(in_meter_reading_id, -1)
		   AND in_start_dtm < r.end_dtm 
		   AND in_end_dtm > r.start_dtm
	) LOOP
		 RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_PERIOD_OVERLAP, 'Entered period overlaps existing period');
	END LOOP;
	
	-- These will raise an error if the check fails
	INTERNAL_CheckTolerances(in_region_sid, in_start_dtm, in_end_dtm, in_val, in_note);
	INTERNAL_CheckOptions(in_region_sid, in_entry_dtm, in_start_dtm, in_end_dtm, in_val, in_note);

	-- We may need to modify this later 
	-- based on the approvl requirement
	v_doc_id := in_doc_id;
	
	IF NVL(in_meter_reading_id, 0) = 0 THEN
	   	-- A new reading (no audit required)
        INSERT INTO meter_reading 
        	(region_sid, meter_reading_id, start_dtm, end_dtm, val_number, 
        		entered_by_user_sid, entered_dtm, note, reference, cost, meter_source_type_id,
        		req_approval,is_estimate)
		  VALUES (in_region_sid, meter_reading_id_seq.NEXTVAL, in_start_dtm, in_end_dtm, in_val,
		  		security_pkg.GetSID, SYSDATE, in_note, in_reference, in_cost, v_source,
		  		v_req_approval,in_is_estimate)
		  RETURNING meter_reading_id INTO out_reading_id;
    ELSE
		-- Try and fetch the reading from the view of approved readings 
		-- (this will  tell us if it's been approved or not)
		BEGIN
	    	SELECT meter_reading_id
    		  INTO v_approved_reading_id
    		  FROM v$meter_reading
    		 WHERE meter_reading_id = in_meter_reading_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_approved_reading_id := NULL;
		END;
		
		-- Action the request based on requirement for approval 
		-- and whether or not the reading is already approved
		IF v_approved_reading_id IS NOT NULL AND
		   v_req_approval != 0 THEN
			-- The edit applies to an already approved reading
			-- Clear the doc id so we don't overwite the existing document before approval
		    v_doc_id := NULL;
		    
			-- Insert a replacement pending approval of said replacement
    		INSERT INTO meter_reading 
	        	(region_sid, meter_reading_id, start_dtm, end_dtm, val_number, 
	        		entered_by_user_sid, entered_dtm, note, reference, cost, meter_source_type_id,
	        		req_approval,is_estimate, replaces_reading_id)
			  VALUES (in_region_sid, meter_reading_id_seq.NEXTVAL, in_start_dtm, in_end_dtm, in_val,
			  		security_pkg.GetSID, SYSDATE, in_note, in_reference, in_cost, v_source,
			  		v_req_approval, in_is_estimate, DECODE(in_meter_reading_id, 0, NULL, in_meter_reading_id))
			  RETURNING meter_reading_id INTO out_reading_id;
			
			-- Audit the reading submission
			csr_data_pkg.WriteAuditLogEntry(
		  		security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, in_region_sid, 
				'Meter reading submitted (pending approval) for period {0} to {1}', 
				TO_CHAR(in_start_dtm,'dd Mon yyyy'), 
				TO_CHAR(in_end_dtm,'dd Mon yyyy'));
		ELSE
			-- The edit applies to a reading already pending
			-- approvel or approval is not required for new readings,
			-- simply update the existing reading

			-- Get the old start/end dates
			SELECT start_dtm, end_dtm
			  INTO v_old_start_dtm, v_old_end_dtm
			  FROM v$meter_reading
			 WHERE region_sid = in_region_sid
			   AND meter_reading_id = in_meter_reading_id;

			UPDATE meter_reading
	           SET start_dtm = in_start_dtm,
	           	   end_dtm = in_end_dtm,
	               val_number = in_val,
	               entered_by_user_sid = security_pkg.GetSID,
	               entered_dtm = SYSDATE,
	               note = in_note,
	               reference = in_reference,
	               cost = in_cost,
	               meter_source_type_id = v_source,
	               req_approval = v_req_approval,
				   is_estimate = in_is_estimate
			 WHERE region_sid = in_region_sid
			   AND meter_reading_id = in_meter_reading_id;
			out_reading_id := in_meter_reading_id;
		
			csr_data_pkg.WriteAuditLogEntry(
		  		security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, in_region_sid, 
				'Meter reading changed for period {0} to {1}', 
				TO_CHAR(in_start_dtm,'dd Mon yyyy'), 
				TO_CHAR(in_end_dtm,'dd Mon yyyy'));
		END IF;      
    END IF;
	
	-- Create a flow item if required
    IF v_flow_sid IS NOT NULL THEN
    	CreateFlowItemForReading(v_flow_sid, out_reading_id, v_flow_item_id);
    END IF;
	
	-- If no approval is required then v_doc_id = in_doc_id
	-- If approval is required then v_doc_id = NULL
	UpdateMeterDocFromCache(in_region_sid, v_doc_id, in_cache_key, v_doc_id);
	
	UPDATE meter_reading
	   SET meter_document_id = v_doc_id
	 WHERE meter_reading_id = out_reading_id;		 

	-- Only recompute system values or create invoices 
	-- if the reading didn't require approval
	-- New system values or invoices will be generated on approval if required
	IF v_req_approval = 0 THEN
		INTERNAL_SetValTableForReading(security_pkg.GetACT, out_reading_id, 0, v_old_start_dtm, v_old_end_dtm);
		UtilityInvoiceFromReading(out_reading_id);
		-- Create energy star jobs if required
		energy_star_job_pkg.OnMeterReadingChange(in_region_sid, out_reading_id);
	END IF;	
END;

PROCEDURE INTERNAL_DeleteMeterReading(
	in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE
)
AS
    v_region_sid 			security_pkg.T_SID_ID;
    v_start_dtm				meter_reading.start_dtm%TYPE;
    v_end_dtm				meter_reading.end_dtm%TYPE;
    v_invoice_id			utility_invoice.utility_invoice_id%TYPE;
BEGIN
	SELECT region_sid, start_dtm, end_dtm, created_invoice_id
	  INTO v_region_sid, v_start_dtm, v_end_dtm, v_invoice_id
	  FROM v$meter_reading
	 WHERE meter_reading_id = in_meter_reading_id;
	 
	-- Update system values and delete the reading row
	SetValTableForReading(security_pkg.GetACT, in_meter_reading_id, 1);
	DELETE FROM meter_reading WHERE meter_reading_id = in_meter_reading_id;
	
	-- If an invoice was created from this reading then delete it now
	IF v_invoice_id IS NOT NULL THEN
		DELETE FROM utility_invoice
		 WHERE utility_invoice_id = v_invoice_id;
	END IF;
	
	UpdateMeterListCache(v_region_sid);
END;

/**
 * Delete a meter reading 
 *
 * @param    in_act_id                  Access token
 * @param    in_meter_reading_id        The meter reading id 
 */
PROCEDURE DeleteMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_source_type_id		meter_source_type.meter_source_type_id%TYPE;
	v_req_approval			meter_type.req_approval%TYPE;
	v_flow_sid				security_pkg.T_SID_ID;
	v_start_dtm				meter_reading.start_dtm%TYPE;
	v_end_dtm				meter_reading.end_dtm%TYPE;
	v_new_reading_id		meter_reading.meter_reading_id%TYPE;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_lock_end_dtm			DATE;

BEGIN
	SELECT region_sid,start_dtm,end_dtm
	  INTO v_region_sid, v_start_dtm, v_end_dtm
	  FROM v$meter_reading
	 WHERE meter_reading_id = in_meter_reading_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT lock_end_dtm
	  INTO v_lock_end_dtm
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_start_dtm < v_lock_end_dtm OR v_end_dtm < v_lock_end_dtm THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_WITHIN_LOCK_PERIOD, 'Meter data prior to ' || TO_CHAR(v_lock_end_dtm) || ' cannot be deleted due to the system data lock');
	END IF;

	-- Get some information from the reading
	SELECT mr.region_sid, mr.meter_source_type_id, mt.req_approval, mt.flow_sid, mr.start_dtm, mr.end_dtm
	  INTO v_region_sid, v_source_type_id, v_req_approval, v_flow_sid, v_start_dtm, v_end_dtm
	  FROM meter_reading mr
	  JOIN meter_source_type st ON st.meter_source_type_id = mr.meter_source_type_id
	  JOIN all_meter am ON mr.app_sid = am.app_sid AND mr.region_sid = am.region_sid
	  JOIN meter_type mt ON mt.meter_type_id = am.meter_type_id
	 WHERE mr.meter_reading_id = in_meter_reading_id;
	 
	-- check permission - see rational in SetMeterReading
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting reading from meter sid '||v_region_sid);
	END IF;
	
	-- Can we simply delete the reading here and now?
	IF v_req_approval = 0 THEN
		-- Create energy star jobs if required (before we actually delete the row)
		energy_star_job_pkg.OnMeterReadingChange(v_region_sid, in_meter_reading_id);
		-- Delete the reading
		INTERNAL_DeleteMeterReading(in_meter_reading_id);
		-- Add the audit log
		IF v_end_dtm IS NULL THEN		
		    csr_data_pkg.WriteAuditLogEntry(
		    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
		    	'Meter reading for {0} deleted', TO_CHAR(v_start_dtm,'dd Mon yyyy'));		
		ELSE
		    csr_data_pkg.WriteAuditLogEntry(
		    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
		    	'Meter reading period {0} to {1} deleted', 
		    	TO_CHAR(v_start_dtm,'dd Mon yyyy'), TO_CHAR(v_end_dtm,'dd Mon yyyy'));		
		END IF;
		-- All done
		RETURN;
	END IF;
	
	-- Ok so deletes need approval
	-- Insert a row to represent the pending delete operation
	INSERT INTO meter_reading 
    	(region_sid, meter_reading_id, start_dtm, end_dtm, 
    	entered_by_user_sid, entered_dtm, meter_source_type_id,
    	req_approval, replaces_reading_id, is_delete) 
	VALUES (v_region_sid, meter_reading_id_seq.NEXTVAL, v_start_dtm, v_end_dtm,
  		security_pkg.GetSID, SYSDATE, v_source_type_id,
  		v_req_approval, in_meter_reading_id, 1 /*delete*/)
	RETURNING meter_reading_id INTO v_new_reading_id;
	
	IF v_flow_sid IS NOT NULL THEN
		CreateFlowItemForReading(v_flow_sid, v_new_reading_id, v_flow_item_id);
	END IF;
	
	-- Audit the pending delete
	csr_data_pkg.WriteAuditLogEntry(
    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
    	'Delete request submitted (pending approval) for reading {0}', TO_CHAR(v_start_dtm,'dd Mon yyyy'));
END;

/**
 * Get a single meter reading
 *
 * @param    in_meter_sid				The meter sid 
 * @param    in_meter_reading_id        The meter reading id 
 * @param    out_cur                    The reading
 */
PROCEDURE GetMeterReading(
    in_meter_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
    out_cur                 OUT SYS_REFCURSOR
)
AS
	v_manual_entry			all_meter.manual_data_entry%TYPE;
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;
	v_descending			meter_source_type.descending%TYPE;
	v_region_sids			security.T_SID_TABLE;
BEGIN
	 -- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_meter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_meter_sid);
	END IF;

	SELECT m.manual_data_entry, t.arbitrary_period, descending
	  INTO v_manual_entry, v_arbitrary_period, v_descending
	  FROM all_meter m, meter_source_type t
	 WHERE m.region_sid = in_meter_sid
	   AND t.meter_source_type_id = m.meter_source_type_id;
	
	SELECT r.region_sid BULK COLLECT INTO v_region_sids
	  FROM all_meter m, v$region r
	 WHERE r.active = 1 AND m.active = 1
	   AND ((r.region_sid = in_meter_sid AND (r.region_type = csr_data_pkg.REGION_TYPE_METER OR
											  r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER)) OR
			(r.parent_sid = in_meter_sid AND r.region_type = csr_data_pkg.REGION_TYPE_RATE));

	IF v_manual_entry = 0 THEN
		-- We don't want to show the data in this case, return a cursor with correct columns but no rows
		OPEN out_cur FOR
			SELECT NULL rate_sid, NULL meter_reading_id, NULL reading_dtm, NULL val, 
				NULL avg_consumpation, NULL note, NULL entered_by_user_sid, NULL entered_dtm, 
				NULL total_rows, NULL user_name,
				NULL reference, NULL cost
			  FROM DUAL
			 WHERE 1 = 2;
			 			 
	ELSIF v_arbitrary_period = 0 THEN		
		OPEN out_cur FOR
			SELECT CASE WHEN region_sid = in_meter_sid THEN NULL ELSE region_sid END rate_sid,
				meter_reading_id, reading_dtm, val_number val, val_number + NVL(baseline_val, 0) total_val,
				CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
				note, entered_by_user_sid, entered_dtm, total_rows, full_name user_name,
				reference, cost, DECODE(baseline_val, last_baseline_val, 0, 1) is_reset,
				md.meter_document_id, md.file_name
			  FROM ( 
			    	SELECT region_sid, 
						meter_reading_id, start_dtm reading_dtm, val_number, NVL(baseline_val, 0) baseline_val,
			    		(val_number + NVL(baseline_val, 0) - LAG(val_number, 1, 0) OVER (PARTITION BY region_sid order by start_dtm) - NVL(LAG(baseline_val) OVER (PARTITION BY region_sid order by start_dtm), 0)) * DECODE(v_descending, 0, 1, -1) consumption, -- difference between values
						TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY region_sid ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
						note, entered_by_user_sid, entered_dtm, full_name, COUNT(*) OVER (PARTITION BY region_sid) AS total_rows, reference, cost,
						NVL(LAG(baseline_val) OVER (PARTITION BY region_sid ORDER BY start_dtm), 0) last_baseline_val,
						meter_document_id
					 FROM v$meter_reading, csr_user cu
				    WHERE region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
					  AND csr_user_sid = entered_by_user_sid
						ORDER BY start_dtm DESC 
			 ) t LEFT JOIN meter_document md ON md.meter_document_id = t.meter_document_id
			  WHERE meter_reading_id = in_meter_reading_id;
	ELSE
		OPEN out_cur FOR
				SELECT CASE WHEN region_sid = in_meter_sid THEN NULL ELSE region_sid END rate_sid,
				  meter_reading_id, note, entered_by_user_sid, 
				  entered_dtm, full_name user_name, reference, cost, total_rows,
				  start_dtm, end_dtm, start_val, end_val, consumption, val_number val,
				  CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
				  md.meter_document_id, md.file_name
				 FROM (
				   SELECT r.region_sid, 
					  r.meter_reading_id, r.note, r.entered_by_user_sid, 
				      r.entered_dtm, cu.full_name, r.reference, r.cost,
				      r.start_dtm, r.end_dtm, 
				      NVL(SUM(val_number) OVER (PARTITION BY region_sid ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) start_val,
				      NVL(SUM(val_number) OVER (PARTITION BY region_sid ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) end_val,
				      r.val_number, r.val_number consumption,
				      TRUNC(r.end_dtm,'dd') - TRUNC(r.start_dtm, 'dd') day_interval,
				      COUNT(*) OVER (PARTITION BY region_sid) AS total_rows,
					  meter_document_id
				    FROM v$meter_reading r, csr_user cu
				    WHERE r.region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
				     AND cu.csr_user_sid = r.entered_by_user_sid
				     	ORDER BY r.start_dtm DESC
				) t LEFT JOIN meter_document md ON md.meter_document_id = t.meter_document_id
				WHERE meter_reading_id = in_meter_reading_id;
	END IF;
END;

/**
 * Get list of meter readings 
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid               The meter sid (region sid)
 * @param    in_start_row               Start row
 * @param    in_end_row                 End row 
 * @param    out_cur                    The note details
 *
 * The output rowset is of the form:
 *  meter_reading_id, reading_dtm, val_number, note entered_by_user_sid, entered_by_user_name, entered_dtm
 */
PROCEDURE GetMeterReadingList(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_start_row            IN number,
    in_end_row              IN number,
    out_cur                 OUT SYS_REFCURSOR
) 
AS
	v_manual_entry			all_meter.manual_data_entry%TYPE;
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;
	v_descending			meter_source_type.descending%TYPE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_region_sid);
	END IF;
	
	SELECT m.manual_data_entry, t.arbitrary_period, descending
	  INTO v_manual_entry, v_arbitrary_period, v_descending
	  FROM all_meter m, meter_source_type t
	 WHERE m.region_sid = in_region_sid
	   AND t.meter_source_type_id = m.meter_source_type_id;
	
	IF v_manual_entry = 0 THEN
		-- We don't want to show the data in this case, return a cursor with correct columns but no rows
		OPEN out_cur FOR
			SELECT NULL meter_reading_id, NULL reading_dtm, NULL val, 
				NULL avg_consumpation, NULL note, NULL entered_by_user_sid, NULL entered_dtm, 
				NULL total_rows, NULL user_name,
				NULL reference, NULL cost
			  FROM DUAL
			 WHERE 1 = 2;
			 			 
	ELSIF v_arbitrary_period = 0 THEN		
		OPEN out_cur FOR
			SELECT meter_reading_id, reading_dtm, val_number val, val_number + NVL(baseline_val, 0) total_val,
				CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
				note, entered_by_user_sid, entered_dtm, total_rows, full_name user_name,
				reference, cost, DECODE(baseline_val, last_baseline_val, 0, 1) is_reset,
				meter_document_id
			  FROM ( 
			  SELECT x.*, ROWNUM rn
			    FROM (
			    	SELECT meter_reading_id, start_dtm reading_dtm, val_number, NVL(baseline_val, 0) baseline_val,
			    		(val_number + NVL(baseline_val, 0) - LAG(val_number, 1, 0) OVER (order by start_dtm) - NVL(LAG(baseline_val) OVER (order by start_dtm), 0)) * DECODE(v_descending, 0, 1, -1) consumption, -- difference between values
						TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
						note, entered_by_user_sid, entered_dtm, full_name, COUNT(*) OVER () AS total_rows, reference, cost,
						NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0) last_baseline_val,
						meter_document_id
					 FROM v$meter_reading, csr_user cu
				    WHERE region_sid = in_region_sid
					  AND csr_user_sid = entered_by_user_sid
						ORDER BY start_dtm DESC 
				 )x WHERE ROWNUM <= in_end_row
			 ) WHERE rn > in_start_row;
	ELSE
		OPEN out_cur FOR
			SELECT * 
			  FROM (
				SELECT ROWNUM rn, meter_reading_id, note, entered_by_user_sid, 
				  entered_dtm, full_name user_name, reference, cost, total_rows,
				  start_dtm, end_dtm, start_val, end_val, consumption, val_number val,
				  CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption
				 FROM (
				   SELECT r.meter_reading_id, r.note, r.entered_by_user_sid, 
				      r.entered_dtm, cu.full_name, r.reference, r.cost,
				      r.start_dtm, r.end_dtm, 
				      NVL(SUM(val_number) OVER (ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) start_val,
				      NVL(SUM(val_number) OVER (ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) end_val,
				      r.val_number, r.val_number consumption,
				      TRUNC(r.end_dtm,'dd') - TRUNC(r.start_dtm, 'dd') day_interval,
				      COUNT(*) OVER () AS total_rows
				    FROM v$meter_reading r, csr_user cu
				   WHERE r.region_sid = in_region_sid
				     AND cu.csr_user_sid = r.entered_by_user_sid
				     	ORDER BY r.start_dtm DESC
				) WHERE ROWNUM <= in_end_row
			 ) WHERE rn > in_start_row;
	END IF;
END;

/**
 * Get list of meter readings including rates for a date period
 *
 * @param    in_meter_sid               The meter sid (region sid)
 * @param    in_start_dtm               Start date
 * @param    in_end_dtm                 End date 
 * @param    out_cur                    The note details
 *
 */
PROCEDURE GetMeterAndRateReadings(
    in_meter_sid           IN security_pkg.T_SID_ID,
    in_start_dtm           IN meter_reading.start_dtm%TYPE,
    in_end_dtm             IN meter_reading.end_dtm%TYPE,
    out_cur                OUT SYS_REFCURSOR
) 
AS
	v_manual_entry			all_meter.manual_data_entry%TYPE;
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;
	v_descending			meter_source_type.descending%TYPE;
	v_region_sids			security.T_SID_TABLE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_meter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_meter_sid);
	END IF;
	
	SELECT m.manual_data_entry, t.arbitrary_period, descending
	  INTO v_manual_entry, v_arbitrary_period, v_descending
	  FROM all_meter m, meter_source_type t
	 WHERE m.region_sid = in_meter_sid
	   AND t.meter_source_type_id = m.meter_source_type_id;
	
	SELECT r.region_sid BULK COLLECT INTO v_region_sids
	  FROM all_meter m, v$region r
	 WHERE r.active = 1 AND m.active = 1
	   AND ((r.region_sid = in_meter_sid AND (r.region_type = csr_data_pkg.REGION_TYPE_METER OR
											  r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER)) OR
			(r.parent_sid = in_meter_sid AND r.region_type = csr_data_pkg.REGION_TYPE_RATE));

	IF v_manual_entry = 0 THEN
		-- We don't want to show the data in this case, return a cursor with correct columns but no rows
		OPEN out_cur FOR
			SELECT NULL rate_sid, NULL meter_reading_id, NULL reading_dtm, NULL val, 
				NULL avg_consumpation, NULL note, NULL entered_by_user_sid, NULL entered_dtm, 
				NULL total_rows, NULL user_name,
				NULL reference, NULL cost
			  FROM DUAL
			 WHERE 1 = 2;
			 			 
	ELSIF v_arbitrary_period = 0 THEN		
		OPEN out_cur FOR
			SELECT CASE WHEN region_sid = in_meter_sid THEN NULL ELSE region_sid END rate_sid,
				meter_reading_id, reading_dtm, val_number val, val_number + NVL(baseline_val, 0) total_val,
				CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
				note, entered_by_user_sid, entered_dtm, total_rows, full_name user_name,
				reference, cost, DECODE(baseline_val, last_baseline_val, 0, 1) is_reset,
				md.meter_document_id, md.file_name
			  FROM ( 
			    	SELECT region_sid, 
						meter_reading_id, start_dtm reading_dtm, val_number, NVL(baseline_val, 0) baseline_val,
			    		(val_number + NVL(baseline_val, 0) - LAG(val_number, 1, 0) OVER (PARTITION BY region_sid order by start_dtm) - NVL(LAG(baseline_val) OVER (PARTITION BY region_sid order by start_dtm), 0)) * DECODE(v_descending, 0, 1, -1) consumption, -- difference between values
						TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY region_sid ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
						note, entered_by_user_sid, entered_dtm, full_name, COUNT(*) OVER (PARTITION BY region_sid) AS total_rows, reference, cost,
						NVL(LAG(baseline_val) OVER (PARTITION BY region_sid ORDER BY start_dtm), 0) last_baseline_val,
						meter_document_id
					 FROM v$meter_reading, csr_user cu
				    WHERE region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
					  AND csr_user_sid = entered_by_user_sid
						ORDER BY start_dtm DESC 
			 ) t LEFT JOIN meter_document md ON md.meter_document_id = t.meter_document_id
			   WHERE reading_dtm <= in_end_dtm
				 AND reading_dtm >= in_start_dtm;
	ELSE
		OPEN out_cur FOR
				SELECT CASE WHEN region_sid = in_meter_sid THEN NULL ELSE region_sid END rate_sid,
				  meter_reading_id, note, entered_by_user_sid, 
				  entered_dtm, full_name user_name, reference, cost, total_rows,
				  start_dtm, end_dtm, start_val, end_val, consumption, val_number val,
				  CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
				  md.meter_document_id, md.file_name
				 FROM (
				   SELECT r.region_sid, 
					  r.meter_reading_id, r.note, r.entered_by_user_sid, 
				      r.entered_dtm, cu.full_name, r.reference, r.cost,
				      r.start_dtm, r.end_dtm, 
				      NVL(SUM(val_number) OVER (PARTITION BY region_sid ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) start_val,
				      NVL(SUM(val_number) OVER (PARTITION BY region_sid ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) end_val,
				      r.val_number, r.val_number consumption,
				      TRUNC(r.end_dtm,'dd') - TRUNC(r.start_dtm, 'dd') day_interval,
				      COUNT(*) OVER (PARTITION BY region_sid) AS total_rows,
					  meter_document_id
				    FROM v$meter_reading r, csr_user cu
				    WHERE r.region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
				     AND cu.csr_user_sid = r.entered_by_user_sid
				     	ORDER BY r.start_dtm DESC
				) t LEFT JOIN meter_document md ON md.meter_document_id = t.meter_document_id
				WHERE start_dtm <= in_end_dtm
				  AND end_dtm >= in_start_dtm;
	END IF;
END;

/**
 * Get list of meter readings for export to Excel
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid               The meter sid (region sid)
 * @param    out_cur                    The note details
 *
 * The output rowset is of the form:
 *  meter_reading_id, reading_dtm, val_number, note entered_by_user_sid, entered_by_user_name, entered_dtm
 */
PROCEDURE GetMeterReadingForExport(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid            IN security_pkg.T_SID_ID,
    out_cur                 OUT SYS_REFCURSOR
) 
AS
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;	
	v_allow_reset			meter_source_type.allow_reset%TYPE;	
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_region_sid);
	END IF;
	
	SELECT t.arbitrary_period, allow_reset
	  INTO v_arbitrary_period, v_allow_reset
	  FROM all_meter m, meter_source_type t
	 WHERE m.region_sid = in_region_sid
	   AND t.meter_source_type_id = m.meter_source_type_id;
			 			 
	IF v_arbitrary_period = 0 THEN	
		IF v_allow_reset = 0 THEN
			OPEN out_cur FOR
				SELECT start_dtm "Reading date", val_number "Reading",
					CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
					user_name "Entered by user", entered_dtm "Date of entry", note
				  FROM ( 
				  	SELECT 
						meter_reading_id, start_dtm, val_number, NVL(baseline_val, 0) baseline_val,
						val_number + NVL(baseline_val, 0) - LAG(val_number, 1, 0) OVER (order by start_dtm) - NVL(LAG(baseline_val) OVER (order by start_dtm), 0) AS consumption, -- different between values
				  		TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
				  		note, entered_by_user_sid, entered_dtm, user_name, COUNT(*) OVER () AS total_rows, rownum rn,
				  		NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0) last_baseline_val
					  FROM v$meter_reading, csr_user cu
					 WHERE region_sid = in_region_sid
					   AND csr_user_sid = entered_by_user_sid
				     ORDER BY start_dtm DESC 
				 );
		ELSE
			OPEN out_cur FOR
				SELECT start_dtm "Reading date", val_number "Reading", val_number + baseline_val "Running total",
					DECODE(baseline_val, last_baseline_val, 'No', 'Yes') "Reset",
					CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
					user_name "Entered by user", entered_dtm "Date of entry", note
				  FROM ( 
				  	SELECT 
						meter_reading_id, start_dtm, val_number, NVL(baseline_val, 0) baseline_val,
						val_number + NVL(baseline_val, 0) - LAG(val_number, 1, 0) OVER (order by start_dtm) - NVL(LAG(baseline_val) OVER (order by start_dtm), 0) AS consumption, -- different between values
				  		TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
				  		note, entered_by_user_sid, entered_dtm, user_name, COUNT(*) OVER () AS total_rows, rownum rn,
				  		NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0) last_baseline_val
					  FROM v$meter_reading, csr_user cu
					 WHERE region_sid = in_region_sid
					   AND csr_user_sid = entered_by_user_sid
				     ORDER BY start_dtm DESC 
				 );
		END IF;
	ELSE		
		OPEN out_cur FOR
			SELECT
			  start_dtm "Start date", end_dtm "End date", consumption "Units used", 
			  CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS "Avg consumption / day",
			  full_name "Entered by user", entered_dtm "Date of entry", reference, cost, note
			 FROM (
			   SELECT r.meter_reading_id, r.note, r.entered_by_user_sid, 
			      r.entered_dtm, cu.full_name, r.reference, r.cost,
			      r.start_dtm, r.end_dtm, 
			      NVL(SUM(val_number) OVER (ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) start_val,
				  NVL(SUM(val_number) OVER (ORDER BY start_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) end_val,
			      r.val_number consumption,
			      TRUNC(r.end_dtm,'dd') - TRUNC(r.start_dtm, 'dd') day_interval
			    FROM v$meter_reading r, csr_user cu
			   WHERE r.region_sid = in_region_sid
			     AND cu.csr_user_sid = r.entered_by_user_sid
			) ORDER BY start_dtm DESC;	 
	END IF;    
END;

/* 
 * Pull most recent row from list cache - useful for updates when we enter new readings.
 */
PROCEDURE GetMeterListCache(
	in_region_sid 			IN  security_pkg.T_SID_ID,
	out_cur 				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		-- pull out the most recent value from the cache
		SELECT region_sid, last_reading_dtm, entered_dtm, val_number, avg_consumption, cost_number, read_by_sid,
			realtime_last_period, realtime_consumption, first_reading_dtm, reading_count,
			CASE WHEN SYSDATE - NVL(last_reading_dtm, SYSDATE) BETWEEN 30 AND 37 then 1 else 0 end is_almost_overdue,
			CASE WHEN SYSDATE - NVL(last_reading_dtm, SYSDATE) > 37 then 1 else 0 end is_overdue
		  FROM meter_list_cache
		 WHERE region_sid = in_region_sid;	
END;

PROCEDURE GetMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_meter					OUT	SYS_REFCURSOR,
	out_primary_conversions		OUT	SYS_REFCURSOR,
	out_cost_conversions		OUT	SYS_REFCURSOR,
	out_days_conversions		OUT	SYS_REFCURSOR,
	out_cost_days_conversions	OUT	SYS_REFCURSOR,
	out_contracts				OUT	SYS_REFCURSOR,
	out_meter_input_aggr_inds	OUT	SYS_REFCURSOR,
	out_tags_cur			 	OUT SYS_REFCURSOR,
	out_metric_values_cur	 	OUT SYS_REFCURSOR,
	out_photos_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_region_sid);
	END IF;

	OPEN out_meter FOR
		  SELECT /*+ALL_ROWS*/ m.region_sid, r.parent_sid, m.meter_type_id, mi.label meter_type_label,
		  	   note, r.active, m.reference, m.meter_source_type_id, m.is_core,
			   m.primary_ind_sid, m.primary_measure_conversion_id, pri.description primary_ind_description, 
			   pri.ind_activity_type_id primary_activity_type_id, pri.core primary_core,
			   prim.description primary_ind_base_measure, 
			   m.cost_ind_sid, m.cost_measure_conversion_id, 
			   m.days_ind_sid, m.days_measure_conversion_id, 
			   m.costdays_ind_sid, m.costdays_measure_conversion_id,
			   coi.description cost_ind_description, coi.ind_activity_type_id cost_activity_type_id, coi.core cost_core, coim.description cost_ind_base_measure, 
			   doi.description days_ind_description, doi.ind_activity_type_id days_activity_type_id, doi.core days_core, doim.description days_ind_base_measure, 
			   cdoi.description costdays_ind_description, cdoi.ind_activity_type_id costdays_activity_type_id, cdoi.core costdays_core, cdoim.description costdays_ind_base_measure, 
			   r.description, crc_meter,
			   ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
			   m.manual_data_entry, ms.arbitrary_period, ms.add_invoice_data, 
			   ms.show_in_meter_list, m.approved_dtm, m.approved_by_sid, usr.full_name approved_by_name, m.meter_type_id, ms.allow_reset,
               CASE 
                WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.region_sid 
                ELSE pr.region_sid -- just use parent
               END location_sid,
               CASE 
                WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.description
                ELSE pr.description -- just use parent
               END LOCATION,
			   mlc.last_reading_dtm, mlc.val_number last_reading, mlc.cost_number,
			   mlc.read_by_sid, mlc.realtime_last_period, mlc.realtime_consumption,
			   mlc.first_reading_dtm, mlc.reading_count,
			   security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), m.region_sid, security_pkg.PERMISSION_WRITE) allow_edit,
			   m.urjanet_meter_id,
			   CASE WHEN pr.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN pr.region_sid ELSE NULL END space_sid,
			   CASE WHEN pr.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN pr.description ELSE NULL END parent_space_description,
			   CASE WHEN pro.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN pro.region_sid ELSE NULL END property_sid,
			   CASE WHEN pro.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN pro.description ELSE NULL END parent_property_description,
			   p.street_addr_1, p.street_addr_2, p.city, p.state, p.country_name, p.postcode,
			   r.acquisition_dtm, r.disposal_dtm
		  FROM v$legacy_meter m
            JOIN v$region r ON m.region_sid = r.region_sid AND m.app_sid = r.app_sid
            JOIN meter_type mi ON mi.meter_type_id = m.meter_type_id AND mi.app_sid = m.app_sid
            JOIN meter_source_type ms ON m.meter_source_type_id = ms.meter_source_type_id AND m.app_sid = ms.app_sid
			LEFT JOIN meter_list_cache mlc ON m.region_sid = mlc.region_sid AND m.app_sid = mlc.app_sid
			LEFT JOIN v$region pr ON r.parent_sid = pr.region_sid  AND r.app_sid = pr.app_sid
			LEFT JOIN v$ind pri ON m.primary_ind_sid = pri.ind_sid AND m.app_sid = pri.app_sid
			LEFT JOIN measure prim ON pri.measure_sid = prim.measure_sid AND pri.app_sid = prim.app_sid
			LEFT JOIN v$ind coi ON m.cost_ind_sid = coi.ind_sid AND m.app_sid = coi.app_sid
			LEFT JOIN measure coim ON coi.measure_sid = coim.measure_sid AND coi.app_sid = coim.app_sid
			LEFT JOIN v$ind doi ON m.days_ind_sid = doi.ind_sid AND m.app_sid = doi.app_sid
			LEFT JOIN measure doim ON doi.measure_sid = doim.measure_sid AND doi.app_sid = doim.app_sid
			LEFT JOIN v$ind cdoi ON m.costdays_ind_sid = cdoi.ind_sid AND m.app_sid = cdoi.app_sid
			LEFT JOIN measure cdoim ON cdoi.measure_sid = cdoim.measure_sid AND cdoi.app_sid = cdoim.app_sid
			LEFT JOIN csr_user usr ON m.approved_by_sid = usr.csr_user_sid, (
			--LEFT JOIN utility_supplier us ON us.utility_supplier_id = uc.utility_supplier_id, (
				 SELECT region_sid, description, region_type
				   FROM v$region 
				  WHERE CONNECT_BY_ISLEAF = 1
				  START WITH region_sid = in_region_sid
				CONNECT BY PRIOR parent_sid = region_sid
					AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
			)pro
			LEFT JOIN v$property p ON pro.region_sid = p.region_sid
		 WHERE m.region_sid = in_region_sid;
		 
	OPEN out_primary_conversions FOR
		SELECT mc.measure_conversion_id, mc.description conversion_description
		  FROM v$legacy_meter mtr, ind i, measure m, measure_conversion mc
		 WHERE mtr.region_sid = in_region_sid
		   AND mtr.primary_ind_sid = i.ind_sid
		   AND i.measure_sid = m.measure_sid 
		   AND m.measure_sid = mc.measure_sid(+);
		   
	OPEN out_cost_conversions FOR
		SELECT mc.measure_conversion_id, mc.description conversion_description
		  FROM v$legacy_meter mtr, ind i, measure m, measure_conversion mc
		 WHERE mtr.region_sid = in_region_sid
		   AND mtr.cost_ind_sid = i.ind_sid
		   AND i.measure_sid = m.measure_sid 
		   AND m.measure_sid = mc.measure_sid(+);
		   
	OPEN out_days_conversions FOR
		SELECT mc.measure_conversion_id, mc.description conversion_description
		  FROM v$legacy_meter mtr, ind i, measure m, measure_conversion mc
		 WHERE mtr.region_sid = in_region_sid
		   AND mtr.days_ind_sid = i.ind_sid
		   AND i.measure_sid = m.measure_sid 
		   AND m.measure_sid = mc.measure_sid(+);
		   
	OPEN out_cost_days_conversions FOR
		SELECT mc.measure_conversion_id, mc.description conversion_description
		  FROM v$legacy_meter mtr, ind i, measure m, measure_conversion mc
		 WHERE mtr.region_sid = in_region_sid
		   AND mtr.costdays_ind_sid = i.ind_sid
		   AND i.measure_sid = m.measure_sid 
		   AND m.measure_sid = mc.measure_sid(+);
		   
	OPEN out_contracts FOR
		SELECT uc.utility_contract_id, uc.account_ref contract_ref, muc.active contract_active, us.utility_supplier_id, us.supplier_name
		  FROM meter_utility_contract muc, utility_contract uc, utility_supplier us
		 WHERE muc.region_sid = in_region_sid
		   AND uc.utility_contract_id = muc.utility_contract_id
		   AND uc.utility_supplier_id = us.utility_supplier_id(+); -- seems odd that this is an outer join?
		   
	OPEN out_meter_input_aggr_inds FOR
		SELECT ai.region_sid, ai.meter_input_id, ai.aggregator, ai.measure_sid, ai.measure_conversion_id, 
		       ai.meter_type_id, ip.lookup_key, NVL(mc.description, m.description) measure_desc, ip.is_consumption_based
		  FROM meter_input_aggr_ind ai
		  JOIN meter_input ip ON ip.app_sid = ai.app_sid AND ip.meter_input_id = ai.meter_input_id
		  LEFT JOIN measure m ON m.app_sid = ai.app_sid AND m.measure_sid = ai.measure_sid
		  LEFT JOIN measure_conversion mc ON mc.app_sid = ai.app_sid AND mc.measure_sid = ai.measure_sid AND mc.measure_conversion_id = ai.measure_conversion_id
		 WHERE ai.region_sid = in_region_sid;
		 
	OPEN out_tags_cur FOR
		SELECT r.region_sid, tgm.tag_group_id, t.tag_id, t.tag
		  FROM region r
		  JOIN region_tag rt ON r.region_sid = rt.region_sid AND r.app_sid = rt.app_sid
		  JOIN v$tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
		  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
		 WHERE r.region_sid = in_region_sid
		 ORDER BY tgm.tag_group_id, tgm.pos;

	OPEN out_metric_values_cur FOR
		SELECT rmv.region_sid, rmv.ind_sid, rmv.effective_dtm, rmv.entry_val val, rmv.note, 
		       rmv.entry_measure_conversion_id measure_conversion_id, rmv.measure_sid,
			   NVL(mc.description, m.description) measure_description,
			   NVL(i.format_mask, m.format_mask) format_mask, rm.show_measure
		  FROM (
		    SELECT
		        ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid, ind_sid ORDER BY effective_dtm DESC) rn,
		        FIRST_VALUE(region_metric_val_id) OVER (PARTITION BY app_sid, region_sid, ind_sid ORDER BY effective_dtm DESC) region_metric_val_id
		      FROM region_metric_val
		     WHERE effective_dtm < SYSDATE  -- we only want to show the current applicable value
		       AND region_sid = in_region_sid
		    ) rmvl
		  JOIN region_metric_val rmv ON rmvl.region_metric_val_id = rmv.region_metric_val_id
		  JOIN region_metric rm ON rmv.ind_sid = rm.ind_sid AND rmv.app_sid = rm.app_sid
		  JOIN ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		  JOIN measure m ON rmv.measure_sid = m.measure_sid AND rmv.app_sid = m.app_sid
	 LEFT JOIN measure_conversion mc ON rmv.entry_measure_conversion_id = mc.measure_conversion_id AND rmv.measure_sid = mc.measure_sid AND rmv.app_sid = mc.app_sid
		 WHERE rmvl.rn = 1
	  ORDER BY rmv.effective_dtm DESC;

	OPEN out_photos_cur FOR
		SELECT mp.meter_photo_id, mp.region_sid, mp.filename, mp.mime_type
		  FROM meter_photo mp
		 WHERE region_sid = in_region_sid
		 ORDER BY meter_photo_id;
END;

FUNCTION IsMultiRateMeter (
	in_region_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM region
	 WHERE parent_sid = in_region_sid
	   AND region_type = csr_data_pkg.REGION_TYPE_RATE;
	
	IF v_count > 0 THEN 
		v_count := 1;
	END IF;
	
	RETURN v_count;
END;

PROCEDURE GetAndCheckRootRegionSids(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	region.region_sid%TYPE,
	out_user_sid					OUT	security_pkg.T_SID_ID,
	out_root_region_sids			OUT	security.T_SID_TABLE,
	out_num_root_region_sids		OUT	NUMBER
)
AS
BEGIN
	user_pkg.GetSid(in_act_id, out_user_sid);

	-- if root_region_sid is null then we need to figure things out for ourselves
	IF in_root_region_sid IS NOT NULL THEN
		out_root_region_sids := security.T_SID_TABLE();
		out_root_region_sids.extend;
		out_root_region_sids(out_root_region_sids.count) := in_root_region_sid;
	ELSE
		-- do they have 'View all meters' capability?
		IF csr_data_pkg.CheckCapability(in_act_id, 'View all meters') THEN
			-- use the user's root_region_sids
			SELECT region_sid
			  BULK COLLECT INTO out_root_region_sids
			  FROM region_start_point
			 WHERE user_sid = out_user_sid;
		ELSE
			-- we'll be using their roles
			out_root_region_sids := security.T_SID_TABLE();
		END IF;
	END IF;
	
	-- check permission....
	-- assumption is that if they can see the root, they can see the children
	FOR r IN (
		SELECT column_value sid_id
		  FROM TABLE(out_root_region_sids)
		 MINUS
		SELECT sid_id
		  FROM TABLE(securableObject_pkg.GetSIDsWithPermAsTable(in_act_id, out_root_region_sids, security_pkg.PERMISSION_READ))
	) LOOP
		-- note: only reports the first sid that the user doesn't have access on
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||r.sid_id);
	END LOOP;

	out_num_root_region_sids := out_root_region_sids.count;
END;

PROCEDURE UNSEC_GetContracts(
	in_meter_sids	IN	security_pkg.T_SID_IDS,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	t		security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_meter_sids);	
	-- this is used for the meterlist portlet and should be somehow connected with GetMeterList -- i.e. GetMeterList
	-- should write the meters into a temp table and then we could select from that. However, that would need a fair
	-- bit of restructuring of the query in GetMeterList which isn't going to happen right now as it needs to be out
	-- for a pre-sales thing in 40 minutes. :(
	OPEN out_cur FOR
		SELECT m.region_sid, us.supplier_name, uc.account_ref, uc.utility_contract_id, from_dtm, to_dtm, muc.active
		  FROM v$meter m
			JOIN TABLE(t)x ON m.region_sid = x.column_value
			JOIN meter_utility_contract muc ON m.region_sid = muc.region_sid AND m.app_sid = muc.app_sid
			JOIN utility_contract uc ON muc.utility_contract_id = uc.utility_contract_id AND muc.app_sid = uc.app_sid
			JOIN utility_supplier us ON uc.utility_supplier_id = us.utility_supplier_id AND uc.app_sid = us.app_sid;
END;

PROCEDURE GetMeterList(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_filter						IN	VARCHAR2,
	in_root_region_sid				IN	security_pkg.T_SID_ID, -- if null, will find all meters that apply to this user
	in_show_hidden					IN	NUMBER,
    in_start_row					IN	NUMBER,
    in_end_row						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_filter						VARCHAR2(1024);
	v_user_sid						security_pkg.T_SID_ID;
	v_root_region_sids				security.T_SID_TABLE;
	v_selected_region_sids			security.T_SID_TABLE;
	v_num_root_region_sids			NUMBER;
BEGIN
	-- Get the root region sid for the list (also checks permissions)
	GetAndCheckRootRegionSids(in_act_id, in_root_region_sid, v_user_sid, v_root_region_sids, v_num_root_region_sids);
	
	-- Excape filter string
	v_filter := utils_pkg.RegexpEscape(in_filter);
	
	-- Replace any number of white spaces with \s+
	v_filter := REGEXP_REPLACE(v_filter, '\s+', '\s+');

	SELECT region_sid
	  BULK COLLECT INTO v_selected_region_sids
	  FROM (
		SELECT region_sid
		  FROM region
			-- this block won't run if it's empty which is what we want
			START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_region_sids))
			CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		UNION 
		SELECT region_sid -- use roles if no region sid provided
		  FROM role r
		  JOIN region_role_member rrm ON r.role_sid = rrm.role_sid
		 WHERE r.is_metering = 1
		   -- only return this roles chunk if we're not doing 'meters under region sid'
		   AND v_num_root_region_sids = 0
		   AND rrm.user_sid = v_user_sid
	) WHERE region_sid NOT IN (
		SELECT linked_meter_sid 
		  FROM linked_meter 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	);

	OPEN out_cur FOR
		SELECT * 
		  FROM (
			SELECT x.*, ROWNUM rn
			  FROM (
				SELECT x.*, COUNT(*) OVER () AS total_rows, 
					MAX(x.last_reading_dtm) OVER (PARTITION BY x.region_sid) sort_dtm
				  FROM (
					SELECT 
						x.region_active, x.class_name, x.ind, x.uom, x.cst_ind, x.cst_uom, 
						x.last_reading_dtm, x.val_number, x.cost_number, x.read_by, 
						x.realtime_last_period, x.realtime_consumption, x.location,
						x.reference, us.utility_supplier_id, us.supplier_name, uc.utility_contract_id, uc.account_ref,
						x.region_type, x.lookup_key, x.meter_source_type_id,
						x.region_sid raw_region_sid, x.parent_region_sid raw_parent_region_sid,
						x.primary_ind_sid, x.primary_measure_conversion_id,
						x.cost_ind_sid, x.cost_measure_conversion_id,
						DECODE(x.is_parent_multi_rate, 0, x.region_sid, x.parent_region_sid) region_sid,
						DECODE(x.is_parent_multi_rate, 0, x.description, x.parent_description) description,
						DECODE(x.is_parent_multi_rate, 0, NULL, x.region_sid) rate_region_sid,
						DECODE(x.is_parent_multi_rate, 0, NULL, x.description) rate_description,
                  		CASE WHEN SYSDATE - NVL(x.last_reading_dtm, SYSDATE) BETWEEN 30 AND 37 then 1 else 0 end is_almost_overdue,
                  		CASE WHEN SYSDATE - NVL(x.last_reading_dtm, SYSDATE) > 37 then 1 else 0 end is_overdue,
						security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), x.region_sid, security_pkg.PERMISSION_WRITE) allow_edit
					  FROM meter_utility_contract muc, utility_contract uc, utility_supplier us, (
						  SELECT x.*, cu.full_name read_by,
							  	INTERNAL_GetProperty(x.region_sid) location,
							  	IsMultiRateMeter(x.region_sid) is_multi_rate,
								IsMultiRateMeter(x.parent_sid) is_parent_multi_rate
						    FROM (
								SELECT m.region_sid, r.parent_sid, r.description, r.active region_active, rt.class_name, 
								    r.region_type, r.lookup_key,
									pr.region_sid parent_region_sid, pr.description parent_description,
									m.primary_ind_sid, m.primary_measure_conversion_id,
									pri.description ind, NVL(primc.description, prim.description) uom,
									m.cost_ind_sid, m.cost_measure_conversion_id,
									cst.description cst_ind, NVL(cstmc.description, cstm.description) cst_uom,
									mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
									mlc.read_by_sid, mlc.realtime_last_period, mlc.realtime_consumption,
									m.reference, m.meter_source_type_id
								  FROM v$meter m
								  JOIN TABLE(v_selected_region_sids) sel ON sel.column_value = m.region_sid
								  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id 
								  JOIN v$region r ON r.region_sid = m.region_sid
								  JOIN region_type rt ON rt.region_type = r.region_type
								  JOIN v$ind pri ON pri.ind_sid = m.primary_ind_sid
								  JOIN measure prim ON prim.measure_sid = pri.measure_sid
								  LEFT JOIN measure_conversion primc ON primc.measure_conversion_id = m.primary_measure_conversion_id
								  LEFT JOIN v$ind cst ON cst.ind_sid = m.cost_ind_sid
								  LEFT JOIN measure cstm ON cstm.measure_sid = cst.measure_sid 
								  LEFT JOIN measure_conversion cstmc ON cstmc.measure_conversion_id = m.cost_measure_conversion_id
								  LEFT JOIN v$region pr ON pr.region_sid = r.parent_sid
								  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
								 WHERE st.show_in_meter_list = 1 				-- Only show meters with a source type that specifies they should be shown
								   AND (r.active = 1 OR in_show_hidden = 1) 	-- Only show active meters unless pareameter specifies otherwise
						  ) x
						  LEFT JOIN csr_user cu ON cu.csr_user_sid = x.read_by_sid
					  ) x
					  WHERE x.is_multi_rate = 0
						AND (in_filter IS NULL 
						 OR REGEXP_LIKE(x.description, v_filter, 'i')
						 OR REGEXP_LIKE(x.location, v_filter, 'i')
						 OR REGEXP_LIKE(x.read_by, v_filter, 'i')
						 OR REGEXP_LIKE(x.reference, v_filter, 'i')
						 OR REGEXP_LIKE(ind, v_filter, 'i') 
						)
						-- Active contract and associated supplier if exists
						AND muc.region_sid(+) = x.region_sid
				        AND muc.active(+) = 1
				        AND uc.utility_contract_id(+) = muc.utility_contract_id
				   	    AND us.utility_supplier_id(+) = uc.utility_supplier_id
				  ) x
			  	  ORDER BY sort_dtm DESC NULLS LAST, description, rate_description
				) x
		   )
		   WHERE rn > in_start_row 
		     AND rn <= in_end_row;
		
END;

PROCEDURE GetMeterAndRates(
	in_meter_sid			IN	security_pkg.T_SID_ID,
	out_meter_cur			OUT SYS_REFCURSOR,
	out_rates_cur			OUT SYS_REFCURSOR,
	out_child_meters_cur	OUT SYS_REFCURSOR,
	out_contracts_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_meter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_meter_sid);
	END IF;

	OPEN out_meter_cur FOR
		SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active,
			   m.reference, m.meter_source_type_id,
			   m.primary_ind_sid, m.primary_measure_conversion_id,
			   m.cost_ind_sid, m.cost_measure_conversion_id,
			   mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
			   mlc.read_by_sid, mlc.realtime_last_period, mlc.realtime_consumption,			   
			   mlc.first_reading_dtm, mlc.reading_count,
			   mi.label group_label, mi.group_key,
			   m.days_ind_sid, m.days_measure_conversion_id, 
			   m.costdays_ind_sid, m.costdays_measure_conversion_id,
			   security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), m.region_sid, security_pkg.PERMISSION_WRITE) allow_edit
		  FROM v$region r
		  JOIN v$legacy_meter m ON r.region_sid = m.region_sid
		  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
		  LEFT JOIN meter_type mi ON m.meter_type_id = mi.meter_type_id
		 WHERE r.region_sid = in_meter_sid
		   AND (r.region_type = csr_data_pkg.REGION_TYPE_METER OR 
				r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER)
		   AND r.active = 1 AND m.active = 1;
		  
	OPEN out_rates_cur FOR
		SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active,
			   mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
			   mlc.read_by_sid, mlc.realtime_last_period, mlc.realtime_consumption,	   
			   mlc.first_reading_dtm, mlc.reading_count
		  FROM v$region r
		  JOIN v$legacy_meter m ON r.region_sid = m.region_sid
		  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
		 WHERE r.parent_sid = in_meter_sid
	       AND r.region_type = csr_data_pkg.REGION_TYPE_RATE
		   AND r.active = 1 AND m.active = 1
	  ORDER BY r.region_sid;
		   
	OPEN out_child_meters_cur FOR
		SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active,
			   m.reference, m.meter_source_type_id,
			   m.primary_ind_sid, m.primary_measure_conversion_id,
			   m.cost_ind_sid, m.cost_measure_conversion_id,
			   mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
			   mlc.read_by_sid, mlc.realtime_last_period, mlc.realtime_consumption,	   
			   mlc.first_reading_dtm, mlc.reading_count,
			   mi.label group_label, mi.group_key
		  FROM v$region r
		  JOIN v$legacy_meter m ON r.region_sid = m.region_sid
		  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
		  LEFT JOIN meter_type mi ON m.meter_type_id = mi.meter_type_id
		 WHERE r.parent_sid = in_meter_sid
		   AND (r.region_type = csr_data_pkg.REGION_TYPE_METER OR 
				r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER)
		   AND r.active = 1 AND m.active = 1
	  ORDER BY r.region_sid;
		   
	OPEN out_contracts_cur FOR
		SELECT uc.utility_contract_id, uc.account_ref, uc.file_name,
			   muc.active, uc.from_dtm, uc.to_dtm,
			   us.utility_supplier_id, us.supplier_name utility_supplier_name
		  FROM meter_utility_contract muc, utility_contract uc, utility_supplier us
		 WHERE muc.region_sid = in_meter_sid
		   AND uc.utility_contract_id = muc.utility_contract_id
		   AND uc.utility_supplier_id = us.utility_supplier_id(+); -- copied from GetMeter(), seems odd that this is an outer join?

END;

PROCEDURE GetMetersAndRates(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_meters_cur					OUT SYS_REFCURSOR,
	out_rates_cur					OUT SYS_REFCURSOR
)
AS
	v_meter_sids					security.T_SID_TABLE;
	v_user_sid						security_pkg.T_SID_ID;
	v_root_region_sids				security.T_SID_TABLE;
	v_num_root_region_sids			NUMBER;
BEGIN
	-- Get the root region sid for the list (also checks permissions)
	GetAndCheckRootRegionSids(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, v_user_sid,
		v_root_region_sids, v_num_root_region_sids);

	SELECT r.region_sid BULK COLLECT INTO v_meter_sids
	  FROM all_meter m, v$region r, meter_source_type st
	 WHERE r.region_sid = m.region_sid
	   AND r.active = 1 AND m.active = 1
	   AND (r.region_type = csr_data_pkg.REGION_TYPE_METER OR
			r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER)
	   AND st.meter_source_type_id = m.meter_source_type_id
	   AND st.show_in_meter_list = 1
	   AND m.region_sid in (
			-- XXX: doesn't support secondary region trees?
			SELECT region_sid
			  FROM region
				   -- this block won't run if it's empty which is what we want
				   START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_region_sids))
				   CONNECT BY PRIOR region_sid = parent_sid
			 UNION 
			SELECT region_sid -- use roles if no region sid provided
			  FROM role r
			  JOIN region_role_member rrm ON r.role_sid = rrm.role_sid
			 WHERE r.is_metering = 1
			   -- only return this roles chunk if we're not doing 'meters under region sid'
			   AND v_num_root_region_sids = 0
			   AND rrm.user_sid = v_user_sid
	   )
	   AND m.region_sid NOT IN (
		   SELECT linked_meter_sid FROM linked_meter WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   );

	OPEN out_meters_cur FOR
		SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active,
			   m.reference, m.meter_source_type_id,
			   m.primary_ind_sid, m.primary_measure_conversion_id,
			   m.cost_ind_sid, m.cost_measure_conversion_id,
			   mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
			   mlc.read_by_sid, mlc.realtime_last_period, mlc.realtime_consumption,	   
			   mlc.first_reading_dtm, mlc.reading_count,
			   mi.label group_label, mi.group_key
		  FROM v$region r
		  JOIN v$legacy_meter m ON r.region_sid = m.region_sid
		  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
		  LEFT JOIN meter_type mi ON m.meter_type_id = mi.meter_type_id
		 WHERE r.region_sid IN (SELECT column_value FROM TABLE(v_meter_sids))
	  ORDER BY r.region_sid;
		  
	OPEN out_rates_cur FOR
		SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active,
			   mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
			   mlc.read_by_sid,  mlc.realtime_last_period, mlc.realtime_consumption,	   
			   mlc.first_reading_dtm, mlc.reading_count
		  FROM v$region r
		  JOIN all_meter m ON r.region_sid = m.region_sid
		  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
		 WHERE r.parent_sid IN (SELECT column_value FROM TABLE(v_meter_sids))
	       AND r.region_type = csr_data_pkg.REGION_TYPE_RATE
		   AND r.active = 1 AND m.active = 1
	  ORDER BY r.region_sid;
									
END;

-- passing NULL will refresh all
PROCEDURE UpdateMeterListCache(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_data_found					BOOLEAN := FALSE;
	v_duration_id					meter_bucket.meter_bucket_id%TYPE;
	v_consumption_input_id			meter_input.meter_input_id%TYPE;
	v_cost_input_id					meter_input.meter_input_id%TYPE;
BEGIN
	-- Get the consumption and cost input ids
	SELECT meter_input_id
	  INTO v_consumption_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';

	BEGIN
		SELECT meter_input_id
		  INTO v_cost_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'COST';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_cost_input_id := NULL;
	END;


	-- Get the "system period" duration to 
	-- query the live meter data table against
	BEGIN
		SELECT meter_bucket_id
		  INTO v_duration_id
		  FROM meter_bucket
		 WHERE is_export_period = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_duration_id := NULL;
	END;

	IF in_region_sid IS NULL THEN
		-- if we're doing all then the v_data_found thing to clear out meters with empty 
		-- readings won't work, so just clear everything out.
		DELETE FROM meter_list_cache WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	END IF;
	
	-- Update the cache.
	-- The first_reading_dtm and reading_count are for use by the REST API.
	FOR r IN (
		-- First and last meter reading values for point in time meters
		-- First and last consumption values for arbitrary period meters
		SELECT
			region_sid,
			-- XXX: Should the last reading date be the last sgtart date for arbitrary periods?
			-- This will use the last end date because that's the behaviour from before the
			-- reading data storage was refactored.
			FIRST_VALUE(NVL(end_dtm, start_dtm)) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) last_reading_dtm,
			FIRST_VALUE(entered_dtm) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) last_entered_dtm,
			FIRST_VALUE(val_number) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) val_number,
			FIRST_VALUE(cost) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) cost_number,
			FIRST_VALUE(entered_by_user_sid) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) read_by_sid,
			FIRST_VALUE(CASE WHEN day_interval > 0 THEN ROUND(consumption / day_interval, 2) ELSE 0 END) 
				   OVER (PARTITION BY region_sid ORDER BY start_dtm DESC) avg_consumption,
			NULL realtime_last_period,
			NULL realtime_consumption,
			LAST_VALUE(start_dtm) OVER (PARTITION BY region_sid ORDER BY start_dtm DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) first_reading_dtm,
			COUNT(*) OVER (PARTITION BY region_sid) reading_count
		  FROM (	
			SELECT
				mr.region_sid,
				start_dtm,
				end_dtm,
				entered_dtm,
				val_number,
				cost,
				mr.entered_by_user_sid,
				CASE WHEN st.arbitrary_period = 0 THEN
					val_number - LAG(val_number, 1, 0) OVER (PARTITION BY mr.region_sid ORDER BY start_dtm)
				ELSE
					val_number
				END consumption,
				CASE WHEN st.arbitrary_period = 0 THEN
					TRUNC(start_dtm,'dd') - TRUNC(LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY m.region_sid ORDER BY start_dtm), 'dd')
				ELSE
					TRUNC(start_dtm,'dd') - TRUNC(end_dtm, 'dd')
				END day_interval
			  FROM region r, all_meter m, v$meter_reading mr, meter_source_type st
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (r.region_type = csr_data_pkg.REGION_TYPE_METER
			     OR r.region_type = csr_data_pkg.REGION_TYPE_RATE
			   )
			   AND r.region_sid = m.region_sid
			   AND mr.region_sid = m.region_sid
			   AND st.app_sid = m.app_sid
			   AND m.meter_source_type_id = st.meter_source_type_id
			   AND m.urjanet_meter_id IS NULL -- non-urjanet meters
			   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
		  )
		UNION
		-- Last meter_source_data entry for urjanet meters (can't use this for all real-time meters as finding the last reading just doesn't perform)
		SELECT region_sid, 
			MAX(last_reading_dtm) last_reading_dtm, 
			NULL last_entered_dtm, 
			MAX(val_number) val_number, 
			MAX(cost_number) cost_number,
			NULL read_by_sid, 
			MAX(avg_consumption) avg_consumption,
			NULL realtime_last_period,
			NULL realtime_consumption,
			MIN(first_reading_dtm) first_reading_dtm,
			MAX(reading_count) reading_count
		  FROM (
			SELECT m.region_sid,
				CAST(FIRST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) AS DATE) last_reading_dtm,
				FIRST_VALUE(msd.consumption) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) val_number,
				NULL cost_number,
				NULL read_by_sid,
				FIRST_VALUE(CASE WHEN CAST(msd.end_dtm AS DATE) - CAST(msd.start_dtm AS DATE)  > 0 THEN ROUND(consumption / (CAST(msd.end_dtm AS DATE) - CAST(msd.start_dtm AS DATE)), 2) ELSE 0 END) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) avg_consumption,
				CAST(LAST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE)first_reading_dtm,
				COUNT(*) OVER (PARTITION BY m.region_sid) reading_count
			  FROM meter_source_data msd
			  JOIN all_meter m on m.region_sid = msd.region_sid
			 WHERE msd.meter_input_id = v_consumption_input_id
			   AND m.urjanet_meter_id IS NOT NULL
			   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
			UNION
			SELECT m.region_sid,
				CAST(FIRST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) AS DATE)last_reading_dtm,
				NULL val_number,
				FIRST_VALUE(msd.consumption) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC) cost_number,
				NULL read_by_sid,
				NULL avg_consumption,
				CAST(LAST_VALUE(msd.start_dtm) OVER (PARTITION BY m.region_sid ORDER BY msd.start_dtm DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE) first_reading_dtm,
				COUNT(*) OVER (PARTITION BY m.region_sid) reading_count
			  FROM meter_source_data msd
			  JOIN all_meter m on m.region_sid = msd.region_sid
			 WHERE msd.meter_input_id = v_cost_input_id
			   AND m.urjanet_meter_id IS NOT NULL
			   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
		) GROUP BY region_sid
		UNION
		-- Last system period value for real-time meters (non-urjanet)
		SELECT
			m.region_sid, 
			NULL last_reading_dtm,
			NULL last_entered_dtm,
			NULL val_number,
			NULL cost_number,
			NULL read_by_sid,
			NULL avg_consumption,
			FIRST_VALUE(start_dtm) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_last_period,
			FIRST_VALUE(consumption) OVER (PARTITION BY rmr.region_sid ORDER BY start_dtm DESC) realtime_consumption,
			NULL first_reading_dtm,
			NULL reading_count
		  FROM region r, all_meter m, meter_live_data rmr
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER
		   AND r.region_sid = m.region_sid
		   AND rmr.region_sid = m.region_sid
		   AND rmr.meter_bucket_id(+) = v_duration_id
		   AND m.urjanet_meter_id IS NULL -- non-urjanet meters
		   AND m.region_sid = NVL(in_region_sid, m.region_sid) -- if null, do all
	) LOOP
		BEGIN
			INSERT INTO meter_list_cache
				(region_sid, last_reading_dtm, entered_dtm, val_number, avg_consumption, cost_number, read_by_sid, realtime_last_period, realtime_consumption, first_reading_dtm, reading_count)
			  VALUES (r.region_sid, r.last_reading_dtm, r.last_entered_dtm, r.val_number, r.avg_consumption, r.cost_number, r.read_by_sid, r.realtime_last_period, r.realtime_consumption, r.first_reading_dtm, r.reading_count);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_list_cache
				   SET last_reading_dtm = r.last_reading_dtm,
				       entered_dtm = r.last_entered_dtm,
				       val_number = r.val_number,
				       avg_consumption = r.avg_consumption,
				       cost_number = r.cost_number, 
				       read_by_sid = r.read_by_sid, 
				       realtime_last_period = r.realtime_last_period, 
				       realtime_consumption = r.realtime_consumption,
					   first_reading_dtm = r.first_reading_dtm,
					   reading_count = r.reading_count
				 WHERE region_sid = r.region_sid;
		END;	
		v_data_found := TRUE;			
	END LOOP;

	IF NOT v_data_found THEN
		-- nothing doing - must have been last reading
		DELETE FROM meter_list_cache
		 WHERE region_sid = in_region_sid;
	END IF;
END;

PROCEDURE GetMeterTagsForExport(
	in_root_region_sids				IN	security.T_SID_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT rt.region_sid, tg.name tag_group_name, t.tag
		  FROM v$tag_group tg, tag_group_member tgm, region_tag rt, v$tag t
		 WHERE tgm.tag_id = rt.tag_id
		   AND tg.tag_group_id = tgm.tag_group_id
		   AND t.tag_id = rt.tag_id
		   AND rt.region_sid IN (
		   		SELECT region_sid
		   		  FROM region
		   		 WHERE region_type = csr_data_pkg.REGION_TYPE_METER
		   		    OR region_type = csr_data_pkg.REGION_TYPE_RATE
		   		   		START WITH region_sid IN (SELECT column_value FROM TABLE(in_root_region_sids))
		   		   		CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		   );
END;

/**
 * Get list of meters for export to Excel
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid               The meter sid (region sid)
 * @param    out_cur                    output cursor
 *
 */
PROCEDURE GetMeterListForExport(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags						OUT	SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_root_region_sids				security.T_SID_TABLE;
	v_selected_region_sids			security.T_SID_TABLE;
	v_num_root_region_sids			NUMBER;
BEGIN
	-- Get the root region sid for the list (also checks permissions)
	GetAndCheckRootRegionSids(in_act_id, in_root_region_sid, v_user_sid, v_root_region_sids, v_num_root_region_sids);
	
	-- Fetch region tags for amy meters we're going to export
	GetMeterTagsForExport(v_root_region_sids, out_tags);

	SELECT region_sid
	  BULK COLLECT INTO v_selected_region_sids
	  FROM (
		SELECT region_sid
		  FROM region
			   -- this block won't run if it's empty which is what we want
			   START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_region_sids))
	   		   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	     UNION
	     SELECT region_sid -- use roles if no region sid provided
		  FROM ROLE r
		  JOIN region_role_member rrm ON r.role_sid = rrm.role_sid
		 WHERE r.is_metering = 1
		   -- only return this roles chunk if we're not doing 'meters under region sid'
		   AND v_num_root_region_sids = 0
		   AND rrm.user_sid = v_user_sid
	);

	OPEN out_cur FOR
		SELECT 
			x.location "Location", 
			x.description "Description", 
			x.region_type_label "Region type", 
			x.source_type_desc "Meter reading type", 
			x.ind "Type",
			x.last_reading_dtm "Last reading date",
			x.val_number "Last reading value",
			x.avg_consumption "Last avg consumption/day value",
			x.uom "Unit",
			x.entered_dtm "Entered date",
			x.read_by "Read by",
			x.reference "Reference", 
			x.active "Active", 
			x.note "Note", 
			x.region_sid
		  FROM (
			  SELECT x.*, cu.full_name read_by,
				  	INTERNAL_GetProperty(x.region_sid) location,
				  	IsMultiRateMeter(x.region_sid) is_multi_rate,
					DECODE (x.region_active, 0,  'No', 'Yes') active
			    FROM (
					SELECT m.region_sid, r.description, r.active region_active,
						pri.description ind, NVL(primc.description, prim.description) uom,
						cst.description cst_ind, NVL(cstmc.description, cstm.description) cst_uom,
						mlc.last_reading_dtm, mlc.val_number, mlc.cost_number,
						mlc.read_by_sid, st.description source_type_desc, m.reference, m.note, 
						rt.label region_type_label, mlc.entered_dtm, mlc.avg_consumption
					  FROM v$legacy_meter m
					   JOIN TABLE(v_selected_region_sids) sel ON sel.column_value = m.region_sid
					   JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
					   JOIN v$region r ON r.region_sid = m.region_sid
					   JOIN region_type rt ON rt.region_type = r.region_type
					   JOIN v$ind pri ON pri.ind_sid = m.primary_ind_sid
					   JOIN measure prim ON prim.measure_sid = pri.measure_sid
					   LEFT JOIN measure_conversion primc ON primc.measure_conversion_id = m.primary_measure_conversion_id
					   LEFT JOIN v$ind cst ON cst.ind_sid = m.cost_ind_sid
					   LEFT JOIN measure cstm ON cstm.measure_sid = cst.measure_sid 
					   LEFT JOIN measure_conversion cstmc ON cstmc.measure_conversion_id = m.cost_measure_conversion_id
					   LEFT JOIN v$region pr ON pr.region_sid = r.parent_sid
					   LEFT JOIN meter_list_cache mlc ON mlc.region_sid = m.region_sid
					 WHERE st.show_in_meter_list = 1 	-- Only select meters with a source type that specifies they should be shown
			  ) x
			  LEFT JOIN csr_user cu ON cu.csr_user_sid = x.read_by_sid
		  ) x
		  WHERE x.is_multi_rate = 0
		  ORDER BY x.active DESC, x.last_reading_dtm ASC NULLS FIRST; -- never read = at top
END;


/**
 * Get list of meters and all readings for export to Excel
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid               The meter sid (region sid)
 * @param    out_cur                    output cursor
 *
 */
PROCEDURE GetFullMeterListForExport(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags						OUT	SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_root_region_sids				security.T_SID_TABLE;
	v_selected_region_sids			security.T_SID_TABLE;
	v_num_root_region_sids			NUMBER;
BEGIN
	-- Get the root region sid for the list (also checks permissions)
	GetAndCheckRootRegionSids(in_act_id, in_root_region_sid, v_user_sid, v_root_region_sids, v_num_root_region_sids);

	-- Fetch region tags for amy meters we're going to export
	GetMeterTagsForExport(v_root_region_sids, out_tags);

	SELECT region_sid
	  BULK COLLECT INTO v_selected_region_sids
	  FROM (
		SELECT region_sid
		 FROM region
		 START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_region_sids))
	   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
       UNION 	
       SELECT region_sid -- use roles if no region sid provided
	     FROM role r
		 JOIN region_role_member rrm ON r.role_sid = rrm.role_sid
	    WHERE r.is_metering = 1
	      AND rrm.user_sid = v_user_sid
	   MINUS
	   -- excludes meters that have rates
	   SELECT DISTINCT p.region_sid
	     FROM region c, region p
	    WHERE p.region_sid = c.parent_sid
	      AND c.region_type = csr_data_pkg.REGION_TYPE_RATE
	);

	GetFullMeterListForExport(v_selected_region_sids, out_cur);
END;

PROCEDURE GetFullMeterListForExport(
	in_selected_region_sids			IN  security.T_SID_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_consumption_input_id			meter_input.meter_input_id%TYPE;
	v_cost_input_id					meter_input.meter_input_id%TYPE;
	v_low_res_priority				meter_data_priority.priority%TYPE;
	v_estimate_priority				meter_data_priority.priority%TYPE;
BEGIN
	-- Get the consumption and cost input ids
	SELECT meter_input_id
	  INTO v_consumption_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';

	BEGIN
		SELECT meter_input_id
		  INTO v_cost_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'COST';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_cost_input_id := NULL;
	END;

	BEGIN
		SELECT priority
		  INTO v_low_res_priority
		  FROM meter_data_priority
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'LO_RES';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_low_res_priority := NULL;
	END;

	BEGIN
		SELECT priority
		  INTO v_estimate_priority
		  FROM meter_data_priority
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'ESTIMATE';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_estimate_priority := NULL;
	END;

	OPEN out_cur FOR
        SELECT 
        	x.location "Location", 
        	x.description "Description", 
        	x.region_type_label "Region type", 
        	x.source_type_desc "Meter reading type", 
        	x.TYPE "Type", 
        	x.reading_dtm "Reading date",
			x.start_dtm "Start Date",
			x.end_dtm "End Date",
			x.priority "Priority number",
			x.priority_label "Priority label",
        	DECODE(x.arbitrary_period, 1, NULL, x.reading_value)  "Reading value",
        	x.consumption "Consumption Original", 
			nvl(x.o_unit, x.c_unit) "Original Consumption Unit", 
			CASE WHEN x.start_dtm IS NULL THEN NULL ELSE ROUND(measure_pkg.UNSEC_GetBaseValue(x.consumption, mcid, x.start_dtm), 2) END "Consumption Converted",
			x.c_unit "Converted Consumption Unit",
            CASE WHEN x.start_dtm IS NOT NULL AND day_interval > 0 THEN ROUND(measure_pkg.UNSEC_GetBaseValue(x.consumption, mcid, x.start_dtm) / day_interval, 2) ELSE 0 END "Avg consumption per day",
            x.day_interval "Days", 
			x.cst_ind "Cost Type",	
			x.cost "Cost Original",
			nvl(x.o_cst_uom, x.c_cst_uom) "Original Cost Unit",
			CASE WHEN x.start_dtm IS NULL THEN NULL ELSE ROUND(measure_pkg.UNSEC_GetBaseValue(x.cost, cstmcid, x.start_dtm), 2) END "Cost Converted",
			x.c_cst_uom "Converted Cost Unit",
			CASE WHEN x.start_dtm IS NOT NULL AND cost_interval > 0 THEN ROUND(measure_pkg.UNSEC_GetBaseValue(x.consumption, cstmcid, x.start_dtm) / cost_interval, 2) ELSE 0 END "Avg consumption per cost day",
            x.cost_interval "Cost Days",
            x.entered_dtm "Entered date",
            read_by "Read by", 
            reference "Reference", 
            active "Active", 
            note "Note", 
            region_sid,
			DECODE(x.meter_document_id, null, null, x.host||'/csr/site/meter/document/download.aspx?docId='||x.meter_document_id) "Uploaded document"
            FROM (           
                SELECT INTERNAL_GetProperty(r.region_sid) location, 
                 	DECODE(r.region_type, csr_data_pkg.REGION_TYPE_RATE, pr.description || ' - ' || r.description, r.description) description,
                 	pri.description type, entered_dtm, val_number reading_value, m.reference,
					CASE WHEN st.arbitrary_period = 0 THEN
						val_number - LAG(val_number, 1, 0) OVER (PARTITION BY m.region_sid  ORDER BY start_dtm) -- difference between values
					ELSE
						val_number
					END consumption,
					CASE WHEN st.arbitrary_period = 0 THEN
						TRUNC(start_dtm, 'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY m.region_sid ORDER BY start_dtm), 'dd') -- difference between dates
					ELSE
						TRUNC(end_dtm, 'dd') - TRUNC(start_dtm, 'dd')
					END day_interval,
				 	prim.description c_unit,
					primc.description o_unit,
					cu.full_name read_by,
					CASE WHEN r.active = 1 THEN 'Yes' ELSE 'No' END active, m.note, r.region_sid,
					rt.label region_type_label, st.description source_type_desc, st.arbitrary_period,
					cst.description cst_ind, cstm.description c_cst_uom, cstmc.description o_cst_uom, cstmc.measure_conversion_id cstmcid, mr.cost, mr.meter_document_id, c.host,
					CASE WHEN mr.cost IS NULL THEN NULL
					WHEN st.arbitrary_period = 0 THEN
						TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY m.region_sid ORDER BY start_dtm), 'dd')
					ELSE
						 TRUNC(end_dtm, 'dd') - TRUNC(start_dtm, 'dd')
					END cost_interval,
					CASE WHEN st.arbitrary_period = 0 THEN
						LAG(start_dtm, 1, start_dtm) OVER (PARTITION BY m.region_sid ORDER BY start_dtm)
					ELSE
						start_dtm
					END start_dtm, start_dtm reading_dtm, end_dtm,
					primc.measure_conversion_id mcid,
					mr.priority, 
					CASE 
						-- We have the priority number, use the join (mdp)
						WHEN mr.priority IS NOT NULL THEN mdp.label
						-- No priority number available but it's a low reolution meter and we know if it was an estimate or not
						WHEN mr.is_estimate IS NOT NULL THEN DECODE(mr.is_estimate, 0, 'Low resolution', 'Estimate')
						-- Default is NULL when no case match, which is what we want if neither of the above is true
					END priority_label

				  FROM v$legacy_meter m
				  JOIN TABLE(in_selected_region_sids) sel ON sel.column_value = m.region_sid
				  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
				  JOIN customer c ON c.app_sid = m.app_sid
				  JOIN v$region r ON r.region_sid = m.region_sid
				  JOIN region_type rt ON rt.region_type = r.region_type
				  JOIN v$ind pri ON  pri.ind_sid = m.primary_ind_sid
				  JOIN measure prim ON prim.measure_sid = pri.measure_sid
				  LEFT JOIN measure_conversion primc ON primc.measure_conversion_id = m.primary_measure_conversion_id
				  LEFT JOIN v$ind cst ON  cst.ind_sid = m.cost_ind_sid
				  LEFT JOIN measure cstm ON cstm.measure_sid = cst.measure_sid
				  LEFT JOIN measure_conversion cstmc ON cstmc.measure_conversion_id = m.cost_measure_conversion_id
				  LEFT JOIN v$region pr ON pr.region_sid = r.parent_sid
				  LEFT JOIN (
				  	-- Mangle the "mormal" meter readings and source data for urjanet meters together
				  	SELECT mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost, mr.entered_dtm, mr.entered_by_user_sid, mr.meter_document_id,
				  		DECODE(mr.is_estimate, 0, v_low_res_priority, v_estimate_priority) priority, is_estimate
				  	  FROM v$meter_reading mr
				  	  JOIN TABLE(in_selected_region_sids) sel ON sel.column_value = mr.region_sid
				  	  JOIN all_meter m ON m.region_sid = mr.region_sid
				  	 WHERE m.urjanet_meter_id IS NULL
				  	UNION 
				  	SELECT region_sid, start_dtm, end_dtm, consumption, cost, NULL entered_dtm, NULL entered_by_user_sid, NULL meter_document_id, 
				  		priority, NULL is_estimate
				  	  FROM (
				  	  	-- Merge cost and consumption parts into single row (where possible)
				  		SELECT region_sid, start_dtm, end_dtm, MAX(consumption) consumption, MAX(cost) cost, 
				  			MAX(priority) priority, REPLACE(STRAGG(note), ',', '; ')
						  FROM (
						  	-- Consmuption part	(take priority from consumption part too)
							SELECT m.region_sid, msd.start_dtm, msd.end_dtm, msd.consumption, NULL cost, priority, msd.note
							  FROM meter_source_data msd
							  JOIN TABLE(in_selected_region_sids) sel ON sel.column_value = msd.region_sid
							  JOIN all_meter m on m.region_sid = msd.region_sid
							 WHERE msd.meter_input_id = v_consumption_input_id
							   AND m.urjanet_meter_id IS NOT NULL
							UNION
							-- Cost part	
							SELECT m.region_sid, msd.start_dtm, msd.end_dtm, NULL consumption, msd.consumption cost, NULL priority, msd.note
							  FROM meter_source_data msd
							  JOIN TABLE(in_selected_region_sids) sel ON sel.column_value = msd.region_sid
							  JOIN all_meter m on m.region_sid = msd.region_sid
							 WHERE msd.meter_input_id = v_cost_input_id
							   AND m.urjanet_meter_id IS NOT NULL
						)
						GROUP BY region_sid, start_dtm, end_dtm
					  )
				  ) mr ON mr.region_sid = m.region_sid
				  LEFT JOIN csr_user cu ON  cu.csr_user_sid = mr.entered_by_user_sid
				  LEFT JOIN meter_data_priority mdp ON mdp.priority = mr.priority
				 WHERE st.show_in_meter_list = 1
            ) x
          ORDER BY active desc, location, description, region_sid, start_dtm desc;
END;


PROCEDURE LegacyMakeMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_primary_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_cost_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL
)
AS
	CURSOR c IS 
		SELECT  m.primary_measure_conversion_id, mc.measure_conversion_id primary_measure_conv_desc, 
				m.cost_measure_conversion_id, cmc.measure_conversion_id cost_measure_conv_desc 
		  FROM v$legacy_meter m
		  LEFT JOIN measure_conversion mc ON  mc.measure_conversion_id = m.primary_measure_conversion_id
		  LEFT JOIN measure_conversion cmc ON cmc.measure_conversion_id = m.cost_measure_conversion_id
		 WHERE m.region_sid = in_region_sid;
		 
	old c%ROWTYPE;
	new c%ROWTYPE;

	v_audit_changes				NUMBER := 1;
	v_consumption_input_id		meter_input.meter_input_id%TYPE;
	v_cost_input_id				meter_input.meter_input_id%TYPE;
	v_consumption_measure_sid	security_pkg.T_SID_ID;
	v_cost_measure_sid			security_pkg.T_SID_ID;
	v_needs_recompute			NUMBER;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter with region sid = '||in_region_sid);
	END IF;

	OPEN c;
	FETCH c INTO old;
	IF c%NOTFOUND THEN 
		v_audit_changes := 0;
	END IF;
	CLOSE c;

	SELECT i.meter_input_id, mii.measure_sid
	  INTO v_consumption_input_id, v_consumption_measure_sid
	  FROM meter_input i
	  JOIN meter_type_input mii ON mii.app_sid = i.app_sid AND mii.meter_type_id = in_meter_type_id AND mii.meter_input_id = i.meter_input_id AND mii.aggregator = 'SUM'
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.lookup_key = 'CONSUMPTION';

	BEGIN
		SELECT i.meter_input_id, mii.measure_sid
		  INTO v_cost_input_id, v_cost_measure_sid
		  FROM meter_input i
		  JOIN meter_type_input mii ON mii.app_sid = i.app_sid AND mii.meter_type_id = in_meter_type_id AND mii.meter_input_id = i.meter_input_id AND mii.aggregator = 'SUM'
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.lookup_key = 'COST';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_cost_input_id := NULL;
			v_cost_measure_sid := NULL;
	END;
	
	-- Call main method
	MakeMeter(
	 	in_act_id,
	 	in_region_sid,
	 	in_meter_type_id,
	 	in_note,
	 	in_days_conversion_id,
		in_costdays_conversion_id,
		in_source_type_id,
		in_manual_data_entry,
		in_reference,
		in_contract_ids,
		in_active_contract_id,
		in_crc_meter,
		in_is_core,
		in_urjanet_meter_id,
	 	v_needs_recompute
	);

	BEGIN
		INSERT INTO meter_input_aggr_ind (region_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id)
		VALUES (in_region_sid, v_consumption_input_id, 'SUM', in_meter_type_id, v_consumption_measure_sid, in_primary_conversion_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE meter_input_aggr_ind
			   SET meter_type_id = in_meter_type_id,
			       measure_sid = v_consumption_measure_sid,
			       measure_conversion_id = in_primary_conversion_id
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = v_consumption_input_id
			   AND aggregator = 'SUM';
	END;

	IF v_cost_input_id IS NOT NULL THEN
		BEGIN
			INSERT INTO meter_input_aggr_ind (region_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id)
			VALUES (in_region_sid, v_cost_input_id, 'SUM', in_meter_type_id, v_cost_measure_sid, in_cost_conversion_id);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE meter_input_aggr_ind
				   SET meter_type_id = in_meter_type_id,
				       measure_sid = v_cost_measure_sid,
				       measure_conversion_id = in_cost_conversion_id
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_input_id = v_cost_input_id
				   AND aggregator = 'SUM';
		END;
	END IF;
	
	-- Audit if requred (only changes unique to this procedure)
	IF v_audit_changes != 0 THEN
		OPEN c;
		FETCH c INTO new;
		CLOSE c;
		
		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s primary unit of measure', old.primary_measure_conversion_id, new.primary_measure_conversion_id, old.primary_measure_conv_desc, new.primary_measure_conv_desc);

		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s cost unit of measure', old.cost_measure_conversion_id, new.cost_measure_conversion_id, old.cost_measure_conv_desc, new.cost_measure_conv_desc);
		
	END IF;

	-- Recompute if required
	IF v_needs_recompute != 0 OR
	   NVL(old.primary_measure_conversion_id, -1) <> NVL(in_primary_conversion_id, -1) OR
	   NVL(old.cost_measure_conversion_id, -1) <> NVL(in_cost_conversion_id, -1) THEN
		INTERNAL_RecomputeValueData(in_region_sid);
	END IF;

END;

PROCEDURE MakeMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL
) 
AS
	v_needs_recompute			NUMBER;
BEGIN
	MakeMeter(
		in_act_id,
		in_region_sid,
		in_meter_type_id,
		in_note,
		in_days_conversion_id,
		in_costdays_conversion_id,
		in_source_type_id,
		in_manual_data_entry,
		in_reference,
		in_contract_ids,
		in_active_contract_id,
		in_crc_meter,
		in_is_core,
		in_urjanet_meter_id,
		v_needs_recompute
	);

	-- Recompute if required
	IF v_needs_recompute != 0 THEN
		INTERNAL_RecomputeValueData(in_region_sid);
	END IF;
END;

PROCEDURE MakeMeter(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_meter_type_id				IN	meter_type.meter_type_id%TYPE,
	in_note							IN	all_meter.note%TYPE,
	in_days_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id				IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry			IN  all_meter.manual_data_entry%TYPE,
	in_reference					IN	all_meter.reference%TYPE,
	in_contract_ids					IN	security_pkg.T_SID_IDS,
	in_active_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter					IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core						IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id				IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	out_needs_recompute				OUT	NUMBER
) 
AS
    v_old_region_type				region.region_type%TYPE;
    v_old_measure_sid				security_pkg.T_SID_ID;
    v_old_measure_conversion_id		meter_input_aggr_ind.measure_conversion_id%TYPE;
	v_old_measure_conv_desc			measure_conversion.description%TYPE;
    v_audit_changes					NUMBER(1);
    v_parent_sid					security_pkg.T_SID_ID;
    t_contract_ids					security.T_SID_TABLE;
    v_region_type					region_type.region_type%TYPE;
    
    CURSOR c IS 
		SELECT  mi.meter_type_id, mi.label meter_type_label,
				m.days_measure_conversion_id, NVL(dmc.description, dmc.measure_conversion_id) days_measure_conv_desc, 
				m.costdays_measure_conversion_id, NVL(cdmc.description, cdmc.measure_conversion_id) costdays_measure_conv_desc, 
				m.note, m.meter_source_type_id, m.reference, m.crc_meter, m.is_core,
				st.description meter_source_type_desc, m.urjanet_meter_id, m.manual_data_entry,
				CASE WHEN m.manual_data_entry = 1 THEN 'Manual' ELSE 'Feed' END manual_data_entry_desc
		  FROM all_meter m, meter_type mi, meter_source_type st,
			measure_conversion dmc,
			measure_conversion cdmc
		 WHERE m.region_sid = in_region_sid
		   AND mi.meter_type_id = m.meter_type_id
		   AND dmc.measure_conversion_id(+) = m.days_measure_conversion_id
		   AND cdmc.measure_conversion_id(+) = m.costdays_measure_conversion_id
		   AND st.meter_source_type_id(+) = m.meter_source_type_id;
		 
	old c%ROWTYPE;
	new c%ROWTYPE;
	
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter with region sid = '||in_region_sid);
	END IF;
	
	out_needs_recompute := 0;

	OPEN c;
	FETCH c INTO old;
	v_audit_changes := 1;
	IF c%NOTFOUND THEN 
		v_audit_changes := 0;
	END IF;
	CLOSE c;
	
	-- get app_sid and old region type for audit 
	SELECT region_type, parent_sid
	  INTO v_old_region_type, v_parent_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	-- Set the region type	
	IF in_manual_data_entry = 0 THEN
		v_region_type := csr_data_pkg.REGION_TYPE_REALTIME_METER;
	ELSE
		v_region_type := csr_data_pkg.REGION_TYPE_METER;
	END IF;	
	 
	region_pkg.SetRegionType(in_region_sid, v_region_type);
	
	DELETE FROM meter_input_aggr_ind
	      WHERE region_sid = in_region_sid
		    AND meter_type_id != in_meter_type_id;
	  
	-- Create or update (will reactivate a meter)
	BEGIN
		INSERT INTO all_meter
			(region_sid, meter_type_id, note, meter_source_type_id, manual_data_entry, reference, crc_meter, 
			 is_core, active, days_measure_conversion_id, costdays_measure_conversion_id, urjanet_meter_id)
		  VALUES (in_region_sid, in_meter_type_id, in_note, in_source_type_id, in_manual_data_entry, in_reference, in_crc_meter, 
				in_is_core, 1, in_days_conversion_id, in_costdays_conversion_id, in_urjanet_meter_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_meter
			   SET meter_type_id = in_meter_type_id,
				   note = in_note,
				   days_measure_conversion_id = in_days_conversion_id,
				   costdays_measure_conversion_id = in_costdays_conversion_id,
				   meter_source_type_id = in_source_type_id,
				   manual_data_entry = in_manual_data_entry,
				   reference = in_reference,
				   crc_meter = in_crc_meter,
				   is_core = in_is_core,
				   active = 1,
				   urjanet_meter_id = in_urjanet_meter_id
			 WHERE region_sid = in_region_sid;
	END;
	
	DELETE FROM meter_input_aggr_ind
	      WHERE region_sid = in_region_sid
		    AND (meter_input_id, aggregator) NOT IN (
				SELECT meter_input_id, aggregator
				  FROM meter_type_input
				 WHERE meter_type_id = in_meter_type_id
			);
			
	FOR r IN (
		SELECT mii.meter_input_id, mii.aggregator, mii.measure_sid, tmiai.measure_conversion_id,
		       mi.label input_label, NVL(mc.description, tmiai.measure_conversion_id) new_measure_conv_desc
		  FROM meter_type_input mii
		  JOIN meter_input mi ON mii.meter_input_id = mi.meter_input_id
		  LEFT JOIN temp_meter_input_aggr_ind tmiai 
		    ON mii.meter_input_id = tmiai.meter_input_id 
		   AND mii.aggregator = tmiai.aggregator 
		   AND mii.measure_sid = tmiai.measure_sid 
		   AND tmiai.region_sid = in_region_sid 
		   AND tmiai.meter_type_id = in_meter_type_id
		  LEFT JOIN measure_conversion mc ON tmiai.measure_conversion_id = mc.measure_conversion_id
		 WHERE mii.meter_type_id = in_meter_type_id
	) LOOP
		BEGIN
			INSERT INTO meter_input_aggr_ind (region_sid, meter_input_id, aggregator, meter_type_id, 
											  measure_sid, measure_conversion_id)
				 VALUES (in_region_sid, r.meter_input_id, r.aggregator, in_meter_type_id, 
						 r.measure_sid, r.measure_conversion_id);
			
			out_needs_recompute := 1;
		EXCEPTION
			WHEN dup_val_on_index THEN
				SELECT miai.measure_sid, miai.measure_conversion_id, NVL(mc.description, miai.measure_conversion_id)
				  INTO v_old_measure_sid, v_old_measure_conversion_id, v_old_measure_conv_desc
				  FROM meter_input_aggr_ind miai
				  LEFT JOIN measure_conversion mc ON miai.measure_conversion_id = mc.measure_conversion_id
				 WHERE miai.region_sid = in_region_sid
				   AND miai.meter_input_id = r.meter_input_id
				   AND miai.aggregator = r.aggregator;
				   
				IF NVL(v_old_measure_sid, -1) <> NVL(r.measure_sid, -1) OR
				   NVL(v_old_measure_conversion_id, -1) <> NVL(r.measure_conversion_id, -1) THEN
					out_needs_recompute := 1;
					
					csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
						'Meter''s '||r.input_label||' unit of measure', v_old_measure_conversion_id, r.measure_conversion_id, v_old_measure_conv_desc, r.new_measure_conv_desc);
				END IF;
			
				UPDATE meter_input_aggr_ind
				   SET measure_sid = r.measure_sid,
				       measure_conversion_id = r.measure_conversion_id,
					   meter_type_id = in_meter_type_id
				 WHERE region_sid = in_region_sid
				   AND meter_input_id = r.meter_input_id
				   AND aggregator = r.aggregator;
		END;
	END LOOP;
	
	EmptyTempMeterInputAggrInd;
	
	IF v_old_region_type != csr_data_pkg.REGION_TYPE_METER AND 
	   v_old_region_type != csr_data_pkg.REGION_TYPE_REALTIME_METER THEN
		v_audit_changes := 0;
	END IF;
	
	-- Audit meter property changes
	IF v_audit_changes <> 0 THEN 	
		OPEN c;
		FETCH c INTO new;
		CLOSE c;
		
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter Note', old.note, new.note);
			
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter Reference', old.reference, new.reference);
		
		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s type', old.meter_type_id, new.meter_type_id, old.meter_type_label, new.meter_type_label);
		
		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s source type', old.meter_source_type_id, new.meter_source_type_id, old.meter_source_type_desc, new.meter_source_type_desc);
		
		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s data entry type', old.manual_data_entry, new.manual_data_entry, old.manual_data_entry_desc, new.manual_data_entry_desc);
		
		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s days unit of measure', old.days_measure_conversion_id, new.days_measure_conversion_id, old.days_measure_conv_desc, new.days_measure_conv_desc);
		
		csr_data_pkg.AuditValueDescChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s days of cost data unit of measure', old.costdays_measure_conversion_id, new.costdays_measure_conversion_id, old.costdays_measure_conv_desc, new.costdays_measure_conv_desc);
			
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s CRC flag', old.crc_meter, new.crc_meter);
			
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s core flag', old.is_core, new.is_core);
			
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Meter''s urjanet meter id', old.urjanet_meter_id, new.urjanet_meter_id);
	END IF;
	
	
	-- Update meter contract associations
	t_contract_ids := security_pkg.SidArrayToTable(in_contract_ids);
  	
  	-- Delete removed ids
  	FOR r IN (
  		SELECT utility_contract_id, account_ref
  		  FROM utility_contract
  		 WHERE utility_contract_id IN (
	  		SELECT utility_contract_id
	  		  FROM meter_utility_contract
	  		 WHERE region_sid = in_region_sid
	  		MINUS
	  		SELECT column_value utility_contract_id
	  		  FROM TABLE(t_contract_ids)
	  	)
  	) LOOP
  		-- Delete
  		DELETE FROM meter_utility_contract
  		 WHERE region_sid = in_region_sid
  		   AND utility_contract_id = r.utility_contract_id;
  		-- Audit
  		IF v_audit_changes <> 0 THEN 
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
				'Contract with reference "'||r.account_ref||'" removed from meter');
		END IF;
  	END LOOP;

	-- Add new ids
  	FOR r IN (
		SELECT utility_contract_id, account_ref
  		  FROM utility_contract
  		 WHERE utility_contract_id IN (
	  		SELECT column_value utility_contract_id
	  		  FROM TABLE(t_contract_ids)	  		
	  	)
  	) LOOP
  		-- Insert
  		BEGIN
	  		INSERT INTO meter_utility_contract
	  			(region_sid, utility_contract_id, active)
	  		  VALUES (in_region_sid, r.utility_contract_id, DECODE(r.utility_contract_id, in_active_contract_id, 1, 0));
	  		-- Audit
	  		IF v_audit_changes <> 0 THEN 
				csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
					'Contract with reference "'||r.account_ref||'" added to meter');
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_utility_contract
				   SET active = DECODE(r.utility_contract_id, in_active_contract_id, 1, 0)
				 WHERE region_sid = in_region_sid
				   AND utility_contract_id = r.utility_contract_id;
		END;
  	END LOOP;

	-- Check for and update any child reate meters
	UpdateChildRateMeters(in_region_sid);
	
	-- Check to see if the indicator, UOM or source type have changed
	IF old.meter_type_id <> in_meter_type_id OR
	   NVL(old.days_measure_conversion_id, -1) <> NVL(in_days_conversion_id, -1) OR
	   NVL(old.costdays_measure_conversion_id, -1) <> NVL(in_costdays_conversion_id, -1) OR
	   NVL(old.meter_source_type_id, -1) <> NVL(in_source_type_id, -1) THEN
	    out_needs_recompute := 1;
	END IF;
	
	IF NVL(old.meter_source_type_id, -1) <> NVL(in_source_type_id, -1) THEN
		UPDATE meter_reading
		   SET meter_source_type_id = in_source_type_id
		 WHERE meter_source_type_id != in_source_type_id
		   AND app_sid = security_pkg.GetApp
		   AND region_sid = in_region_sid;
	END IF;

	INTERNAL_CallHelperPkg('OnMakeMeter', in_region_sid);
END;

PROCEDURE EmptyTempMeterInputAggrInd
AS
BEGIN
	-- no security, just temp tables
	DELETE FROM temp_meter_input_aggr_ind;
END;

PROCEDURE AddTempMeterInputAggrInd (
	in_region_sid				IN  temp_meter_input_aggr_ind.region_sid%TYPE,
	in_meter_input_id			IN  temp_meter_input_aggr_ind.meter_input_id%TYPE,
	in_aggregator				IN  temp_meter_input_aggr_ind.aggregator%TYPE,
	in_meter_type_id			IN  temp_meter_input_aggr_ind.meter_type_id%TYPE,
	in_measure_sid				IN  temp_meter_input_aggr_ind.measure_sid%TYPE,
	in_measure_conversion_id	IN  temp_meter_input_aggr_ind.measure_conversion_id%TYPE
)
AS
BEGIN
	-- no security, just temp tables
	INSERT INTO csr.temp_meter_input_aggr_ind (region_sid, meter_input_id, aggregator, meter_type_id, 
				measure_sid, measure_conversion_id)
	     VALUES (in_region_sid, in_meter_input_id, in_aggregator, in_meter_type_id, in_measure_sid,
		         in_measure_conversion_id);
END;

PROCEDURE MakeRate (
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	-- Get parent sid
	SELECT parent_sid
	  INTO v_parent_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	-- Parent must be a meter
	ValidateIsMeter(v_parent_sid);
	
	-- Set region type
	region_pkg.SetRegionType(in_region_sid, csr_data_pkg.REGION_TYPE_RATE);
	
	-- Propgate details from parent meter	
	PropogateMeterDetails(in_region_sid, v_parent_sid);
END;


PROCEDURE ValidateIsMeter (
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_region_type		region.region_type%TYPE;
BEGIN
	-- Get the parent region's type
	SELECT region_type
	  INTO v_region_type
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	-- Validate, region must me of type meter	
	IF v_region_type <> csr_data_pkg.REGION_TYPE_METER THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_PARENT_MUST_BE_METER, 'The parent of a rate meter must be a normal meter');
	END IF;
END;

FUNCTION ValidMeterType(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_region_type		IN	region.region_type%TYPE
) RETURN region.region_type%TYPE
AS
	v_parent_type		region.region_type%TYPE;
BEGIN
	IF in_region_type = csr_data_pkg.REGION_TYPE_RATE THEN
		-- Get the parent region type
		SELECT region_type
		  INTO v_parent_type
		  FROM region
		 WHERE region_sid = in_parent_sid;
		-- Rate types can only be children on meter types	
		IF v_parent_type <> csr_data_pkg.REGION_TYPE_METER THEN
			-- retuen a normal meter type if the parent is not a meter
			RETURN csr_data_pkg.REGION_TYPE_METER;
		END IF;
	END IF;
	
	-- If we get here requested type was valid
	RETURN in_region_type;
END;

FUNCTION IsMeterType (
	in_region_type		IN	region.region_type%TYPE
) RETURN BOOLEAN
AS
BEGIN
	 RETURN (in_region_type = csr_data_pkg.REGION_TYPE_METER OR
	  		 in_region_type = csr_data_pkg.REGION_TYPE_RATE);
END;

FUNCTION IsMeterTypeRegion (
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_region_type		region.region_type%TYPE;
BEGIN
	SELECT region_type
	  INTO v_region_type
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	 RETURN IsMeterType(v_region_type);
END;


PROCEDURE OnRegionMoved (
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_parent_type		region.region_type%TYPE;
	v_region_type		region.region_type%TYPE;
	v_cnt				NUMBER(10);
BEGIN
	-- We're ony interested in regions that are a meter
	IF NOT IsMeterTypeRegion(in_region_sid) THEN
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM trash
	 WHERE trash_sid = in_region_sid;
	 
	-- ignore if this is being trashed
	IF v_cnt > 0 THEN
		RETURN;
	END IF;
	
	-- Get the parent region's type
	BEGIN
		SELECT c.parent_sid, p.region_type, c.region_type
		  INTO v_parent_sid, v_parent_type, v_region_type
		  FROM region c, region p
		 WHERE c.region_sid = in_region_sid
		   AND p.region_sid = c.parent_sid;
		  
		IF v_region_type = csr_data_pkg.REGION_TYPE_RATE AND 
		   IsMeterType(v_parent_type) THEN
			-- Region is a rate meter and parent is a meter - inherit properties
			PropogateMeterDetails(in_region_sid, v_parent_sid);
		ELSE
			-- Parent not a meter type or this region is not a rate type meter - set the region's type correctly
			UPDATE region
			   SET region_type = ValidMeterType(region_sid, parent_sid, region_type)
			 WHERE region_sid = in_region_sid;
		END IF;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			-- Ignore this exception, it should only 
			-- happen when the object is trashed.
			NULL;
	END;
		
END;

PROCEDURE UpdateChildRateMeters (
	in_region_sid 		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT region_sid, parent_sid
		  FROM region
		 WHERE parent_sid = in_region_sid
		   AND region_type = csr_data_pkg.REGION_TYPE_RATE
	) LOOP
		PropogateMeterDetails(r.region_sid, r.parent_sid);
	END LOOP;
END;

PROCEDURE PropogateMeterDetails (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID
)
AS
	v_meter_type_id		all_meter.meter_type_id%TYPE;
BEGIN
	SELECT meter_type_id
	  INTO v_meter_type_id
	  FROM all_meter
	 WHERE region_sid = in_parent_sid;

	BEGIN
		INSERT INTO all_meter
			(region_sid, meter_type_id, note, meter_source_type_id, reference, crc_meter, active,
			days_measure_conversion_id, costdays_measure_conversion_id)
			SELECT in_region_sid, meter_type_id, note, meter_source_type_id, reference, crc_meter, active,
				days_measure_conversion_id, costdays_measure_conversion_id
			  FROM all_meter
			 WHERE region_sid = in_parent_sid;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_meter
			   SET (meter_type_id, note, meter_source_type_id, reference, crc_meter, active,
					days_measure_conversion_id, costdays_measure_conversion_id
				) = (
					SELECT meter_type_id, note, meter_source_type_id, reference, crc_meter, active,
						days_measure_conversion_id, costdays_measure_conversion_id
					  FROM all_meter
					 WHERE region_sid = in_parent_sid
				)
			 WHERE region_sid = in_region_sid;
	END;

	-- Update meter_input_aggr_ind entries
	FOR i IN (
		SELECT meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id
		  FROM meter_input_aggr_ind
		 WHERE region_sid = in_parent_sid
	) LOOP
		BEGIN
			INSERT INTO meter_input_aggr_ind (region_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id)
			VALUES (in_region_sid, i.meter_input_id, i.aggregator, i.meter_type_id, i.measure_sid, i.measure_conversion_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_input_aggr_ind
				   SET meter_type_id = i.meter_type_id,
				       measure_sid = i.measure_sid,
				       measure_conversion_id = i.measure_conversion_id
				 WHERE region_sid = in_region_sid
				   AND meter_input_id = i.meter_input_id
				   AND aggregator = i.aggregator;
		END;
	END LOOP;
	
	-- Dlete any existing contract association
	DELETE FROM meter_utility_contract
	 WHERE region_sid = in_region_sid;
	
	-- Copy new associations from parent
	INSERT INTO meter_utility_contract
	  (region_sid, utility_contract_id, active)
    	SELECT in_region_sid, utility_contract_id, active
	  	  FROM meter_utility_contract
	 	 WHERE region_sid = in_parent_sid;
		 
	INTERNAL_CallHelperPkg('OnMakeMeter', in_region_sid);	
END;

PROCEDURE GetRates (
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.description, m.note, m.primary_ind_sid, m.primary_measure_conversion_id,
			   m.meter_source_type_id, m.reference, m.crc_meter, r.active
		  FROM v$region r, v$legacy_meter m
		 WHERE m.region_sid = r.region_sid
		   AND r.parent_sid = in_region_sid
		   AND r.region_type = csr_data_pkg.REGION_TYPE_RATE;
END;

PROCEDURE UnmakeMeter(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	UnmakeMeter(in_act_id, in_region_sid, csr_data_pkg.REGION_TYPE_NORMAL);
END;

PROCEDURE UnmakeMeter(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_region_type		IN	region.region_type%TYPE
) 
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter with sid '||in_region_sid);
	END IF;
	 
	-- TODO: look for "Meter" tag group and remove
	
	-- Set region type to normal
	region_pkg.SetRegionType(in_region_sid, in_region_type);
	
	-- deactivate the meter tbale entry
	UPDATE all_meter
	   SET active = 0
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE GetMeterSourceType (
	in_source_type_id	IN	meter_source_type.meter_source_type_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT meter_source_type_id, name, description, arbitrary_period, show_in_meter_list,
			   descending, allow_reset, allow_null_start_dtm
		  FROM meter_source_type
		 WHERE meter_source_type_id = in_source_type_id;
END;

PROCEDURE GetMeterSourceTypes (
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- meter_source_type is APP_SID keyed so RLS will deal with access rights.
	OPEN out_cur FOR 
		SELECT meter_source_type_id, name, description, arbitrary_period, show_in_meter_list,
			   descending, allow_reset, allow_null_start_dtm
		  FROM meter_source_type
		 ORDER BY arbitrary_period DESC, meter_source_type_id;
END;

PROCEDURE GetMeterPriorities (
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security, just base data
	OPEN out_cur FOR
		SELECT priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch
		  FROM meter_data_priority;
END;

PROCEDURE GetPeriodData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter with sid '||in_region_sid);
	END IF;
		 
	OPEN out_cur FOR
		SELECT meter_reading_id, val_number, start_dtm, end_dtm, note, reference, cost, meter_document_id
		  FROM v$meter_reading
		 WHERE region_sid = in_region_sid
		   AND meter_reading_id = in_reading_id;
END;

PROCEDURE GetMeterDocData (
	in_doc_id				IN	meter_document.meter_document_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN

	-- THE EXPLICIT RELATIONSHIP BETWEEN A METER_DOCUMENT ROW AND A REGION 
	-- HAS BEEN REMOVED, WE'LL HAVE TO RELY ONLY ON RLS IN THIS PROCEDURE
	/*
	SELECT region_sid
	  INTO v_region_sid
	  FROM meter_reading
	 WHERE meter_document_id = in_doc_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||v_region_sid);
	END IF;
	*/
	
	OPEN out_cur FOR
		SELECT meter_document_id, mime_type, file_name, data
		  FROM meter_document
		 WHERE meter_document_id = in_doc_id;
END;

PROCEDURE UpdateMeterDocFromCache (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_doc_id				IN	meter_document.meter_document_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_id					OUT	meter_document.meter_document_id%TYPE
)
AS
	v_region_sid 			security_pkg.T_SID_ID;
BEGIN
	-- check permission - see rational in SetMeterReading
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter sid '||in_region_sid);
	END IF;
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;
	
	out_id := in_doc_id;
	IF out_id < 0 THEN
		out_id := NULL;
	END IF;
	
	IF in_cache_key IS NOT NULL THEN
		IF NVL(in_doc_id, -1) < 0 THEN
			SELECT meter_document_id_seq.NEXTVAL
			  INTO out_id
			  FROM dual;
			  
			INSERT INTO meter_document
			  (meter_document_id, mime_type, file_name, data)
				SELECT out_id, mime_type, filename, object
			  	  FROM aspen2.filecache 
			 	 WHERE cache_key = in_cache_key;
		ELSE
			UPDATE meter_document
			   SET (mime_type, file_name, data) = (
			   		SELECT mime_type, filename, object
				  	  FROM aspen2.filecache 
				 	 WHERE cache_key = in_cache_key
			   )
			 WHERE meter_document_id = in_doc_id;
		END IF;
	END IF;
	
END;

FUNCTION MissingReadingInPastMonths(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_months		IN	NUMBER
) RETURN NUMBER
AS
	v_missing_reading	NUMBER(1);
BEGIN
	SELECT CASE
		WHEN m.region_sid IS NULL THEN NULL
		WHEN TRUNC(SYSDATE, 'MONTH') > ADD_MONTHS(TRUNC(MAX(r.start_dtm), 'MONTH'), in_months) THEN 1 
		ELSE 0
	END missing_reading
	  INTO v_missing_reading
	  FROM all_meter m, v$meter_reading r
	 WHERE m.region_sid = in_region_sid
	   AND r.region_sid = m.region_sid
	   	GROUP BY m.region_sid;
	 
	RETURN v_missing_reading;
END;

/*
PROCEDURE MeterTypeChangeHelper
AS
	v_min_dtm	DATE;
	v_max_dtm	DATE;
	v_count		NUMBER;
BEGIN
	FOR r IN (
		SELECT region_sid, new_ind_sid, from_dtm, to_dtm, note
		  FROM meter_type_change
	) LOOP
		-- Remove any existing data derived from meter readings in the given period
		FOR v IN (
			SELECT val_id
			  FROM val
			 WHERE source_type_id IN(
			 	csr_data_pkg.SOURCE_TYPE_METER, 
			 	csr_data_pkg.SOURCE_TYPE_REALTIME_METER)
			   AND region_sid = r.region_sid
			   AND period_start_dtm >= NVL(r.from_dtm, period_start_dtm)
			   AND period_end_dtm <= NVL(r.to_dtm, period_end_dtm)
		) LOOP
			indicator_pkg.DeleteVal(security_pkg.GetACT, v.val_id, NVL(r.note, 'Indicator change'));
		END LOOP;
		
		-- Switch the meter's indicator (assumes measure sid should stay the same)
		UPDATE all_meter
		   SET primary_ind_sid = r.new_ind_sid
		 WHERE region_sid = r.region_sid;
		
		-- Count readings in the specified period (or all readings if the perid is not specified)
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$meter_reading
		 WHERE region_sid = r.region_sid
		   AND start_dtm >= NVL(r.from_dtm, start_dtm)
		   AND NVL(end_dtm, start_dtm) <= NVL(r.to_dtm, NVL(end_dtm, start_dtm));
		
		-- only recompute if there are readings in range
		IF v_count > 0 THEN
			-- Get min and max dates for computation
			SELECT NVL(r.from_dtm, min_reading_dtm), NVL(r.to_dtm, max_reading_dtm)
			  INTO v_min_dtm, v_max_dtm 
			  FROM (
				SELECT MIN(start_dtm) min_reading_dtm, NVL(MAX(end_dtm), MAX(start_dtm)) max_reading_dtm
				  FROM v$meter_reading m
				 WHERE m.region_sid = r.region_sid
			);
			-- Recompute system data based on meter readings (now using the new indicator)
			meter_pkg.SetValTableForPeriod(r.region_sid, 0, v_min_dtm, v_max_dtm);				
		END IF;
	END LOOP;
END;
*/

FUNCTION GetIssueMeterUrl(
	in_issue_meter_id	IN	issue_meter.issue_meter_id%TYPE
) RETURN VARCHAR2
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT app_sid, region_sid
		  INTO v_app_sid, v_region_sid
		  FROM issue_meter
		 WHERE issue_meter_id = in_issue_meter_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	RETURN GetMeterPageUrl(v_app_sid)||'?meterSid='||v_region_sid;
END;


PROCEDURE ApproveMeterState(
    in_flow_sid                 IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  csr.flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT adi.region_sid, start_dtm, end_dtm
		  FROM flow_Item fi
			JOIN approval_dashboard_instance adi ON fi.dashboard_instance_id = adi.dashboard_instance_id
		 WHERE fi.flow_item_Id = in_flow_item_id
	)
	LOOP
		UPDATE all_meter
		   SET approved_dtm = SYSDATE,
		   	   approved_by_sid = SYS_CONTEXT('SECURITY', 'SID')
		 WHERE region_sid IN (
			-- this will find any meter under the region
			SELECT region_sid 
			  FROM region
			 START WITH region_sid = r.region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
		 );
	END LOOP;
END;

PROCEDURE IndicatorChanged(
	in_ind_sid					IN	security.security_pkg.T_SID_ID
)
AS
	v_crc_metering_enabled		customer.crc_metering_enabled%TYPE;
	v_crc_metering_ind_core		customer.crc_metering_ind_core%TYPE;
	v_ind_core_flag				ind.core%TYPE;
BEGIN
	-- If we're using legacy crc core flag support then update the core flag
	-- on any meter that uses this indicator as it's promary indicator
	SELECT crc_metering_enabled, crc_metering_ind_core
	  INTO v_crc_metering_enabled, v_crc_metering_ind_core
	  FROM customer;
	
	-- Default to ind core enabled if the attribute is null
	IF NVL(v_crc_metering_enabled, 0) != 0 AND
	   NVL(v_crc_metering_ind_core, 0) != 0 THEN
	   	
	   	SELECT core
	   	  INTO v_ind_core_flag
	   	  FROM ind
	   	 WHERE ind_sid = in_ind_sid;
	   	
	   	UPDATE all_meter
	   	   SET is_core = v_ind_core_flag
	   	 WHERE region_sid IN (
	   	 	SELECT region_sid
	   	 	  FROM v$legacy_meter
		   	 WHERE primary_ind_sid = in_ind_sid
		   	   AND is_core <> v_ind_core_flag
		  );
	END IF;
END;

-- Intended to be called using an array bind
PROCEDURE PrepMeterReadingImportRow(
	in_source_row					IN temp_meter_reading_rows.source_row%TYPE,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_start_dtm		 			IN meter_reading.start_dtm%TYPE,
	in_end_dtm						IN meter_reading.end_dtm%TYPE,
	in_meter_input_id				IN temp_meter_reading_rows.meter_input_id%TYPE,
	in_unit_of_measure				IN temp_meter_reading_rows.unit_of_measure%TYPE,
	in_val							IN meter_reading.val_number%TYPE,
	in_reference					IN meter_reading.reference%TYPE,
	in_note							IN meter_reading.note%TYPE,
	in_reset_val					IN meter_reading.val_number%TYPE DEFAULT NULL,
	in_priority						IN temp_meter_reading_rows.priority%TYPE DEFAULT NULL,
	in_statement_id					IN meter_source_data.statement_id%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	  VALUES (in_source_row, in_region_sid, in_start_dtm, in_end_dtm, in_meter_input_id, in_val, 
			in_reference, in_note, in_reset_val, in_priority, in_unit_of_measure, in_statement_id);
END;

PROCEDURE ImportMeterReadingRows(
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_reading_id				meter_reading.meter_reading_id%TYPE;
	v_reset_val					meter_reading.val_number%TYPE;
	v_invalid_reset_cnt			NUMBER;
	v_min_dtm					DATE;
	v_max_dtm					DATE;
	v_trash_sid					security_pkg.T_SID_ID;
	v_approval_pending			NUMBER;
	v_meter_reading				meter_reading%ROWTYPE;
	v_have_meter_reading		NUMBER;
	v_consumption_input_id  	meter_input.meter_input_id%TYPE;--!!new
	v_cost_input_id				meter_input.meter_input_id%TYPE;
	v_cons_measure_sid			meter_input_aggr_ind.measure_sid%TYPE;
	v_cons_measure_conv_id		meter_input_aggr_ind.measure_conversion_id%TYPE;
	v_cost_measure_sid			meter_input_aggr_ind.measure_sid%TYPE;
	v_cost_measure_conv_id		meter_input_aggr_ind.measure_conversion_id%TYPE;
	v_test_measure				NUMBER(1,0);
	v_test_measure_conv			NUMBER;
	v_prevent_future_readings	NUMBER;
	v_reference_dups_present	NUMBER(1,0);
BEGIN

	v_reference_dups_present := 0;

	UPDATE temp_meter_reading_rows
	   SET error_msg = 'Reference matches meter numbers on multiple meters/regions'
	 WHERE reference IN (
		SELECT m.reference
		  FROM all_meter m
		  JOIN temp_meter_reading_rows t ON m.reference = t.reference
		 WHERE t.region_sid IS NULL
		 GROUP BY m.reference
		HAVING COUNT(DISTINCT m.region_sid) > 1
	);	

	-- Multiple meters having the same reference has a side effect on other parts of the meter import.
	-- So we mark all rows with an error message explaining that rows with references to multpile meters/regions
	-- need fixing first
	IF SQL%ROWCOUNT != 0 THEN
		v_reference_dups_present := 1;
		
		UPDATE temp_meter_reading_rows
	       SET error_msg = 'Row not imported due to references matching multiple meters/regions on other row(s)'
	     WHERE error_msg IS NULL;
	END IF;

	IF v_reference_dups_present = 0 THEN
		-- There should be a consumption input for normal meters
		-- but what if this is a real-time meter, could be somethign esle,
		-- best check
		BEGIN
			SELECT meter_input_id
			  INTO v_consumption_input_id
			  FROM meter_input
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND lookup_key = 'CONSUMPTION';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_consumption_input_id := NULL;
		END;

		-- There's not always a cost input
		BEGIN
			SELECT meter_input_id
			  INTO v_cost_input_id
			  FROM meter_input
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND lookup_key = 'COST';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_cost_input_id := NULL;
		END;

		SELECT trash_sid
		  INTO v_trash_sid
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
		
		   -- Detect invalid region sids
		UPDATE temp_meter_reading_rows
		   SET error_msg = 'Invalid meter region SID'
		 WHERE region_sid IN (
			SELECT region_sid 
			  FROM temp_meter_reading_rows t
			MINUS
			SELECT t.region_sid
			  FROM all_meter am, temp_meter_reading_rows t
			 WHERE am.region_sid = t.region_sid
		 );
		
		-- Detect invalid references (only where there's no region_sid)
		UPDATE temp_meter_reading_rows
		   SET error_msg = 'Invalid meter reference'
		 WHERE region_sid IS NULL
		   AND reference IN (
			SELECT reference
			  FROM temp_meter_reading_rows t
			MINUS
			SELECT t.reference
			  FROM all_meter am, temp_meter_reading_rows t
			 WHERE am.reference = t.reference
		 );

		 -- Detect future dates if user has set them to be not allowed
		 SELECT prevent_manual_future_readings
		   INTO v_prevent_future_readings
		   FROM metering_options;

		IF (v_prevent_future_readings = 1) THEN
			UPDATE temp_meter_reading_rows
			   SET error_msg = 'Reading dates can not be in the future'
			 WHERE source_row IN (
				SELECT t.source_row
				  FROM temp_meter_reading_rows t
				 WHERE t.start_dtm > SYSDATE
					OR t.end_dtm > SYSDATE
		 );
		END IF;
		
		-- Map REFERENCE -> REGION_SID
		MERGE INTO temp_meter_reading_rows t
		USING (
			SELECT DISTINCT am.region_sid, t.reference
			  FROM temp_meter_reading_rows t, all_meter am
			 WHERE am.reference = t.reference
			   AND t.region_sid IS NULL
		) x ON (t.reference = x.reference)
		WHEN MATCHED THEN
			UPDATE SET t.region_sid = x.region_sid;


		UPDATE temp_meter_reading_rows
		   SET error_msg = 'Cannot import meter reading as the meter or parent has been deleted'
		 WHERE region_sid IN (
				SELECT sid_id
				  FROM security.securable_object
				 START WITH sid_id = v_trash_sid
			   CONNECT BY PRIOR sid_id = parent_sid_id
		   );

		-- Detect invalid inputs (where the meter doesn't support the input but the input's column has data)
		UPDATE temp_meter_reading_rows
		   SET error_msg = 'Meter does not have an input for a column containing data'
		 WHERE source_row IN (
			SELECT t.source_row
			  FROM temp_meter_reading_rows t
			 WHERE consumption IS NOT NULL
			   AND error_msg IS NULL
			   AND NOT EXISTS (
				SELECT 1
				  FROM meter_input_aggr_ind ai
				 WHERE ai.region_sid = t.region_sid
				   AND ai.meter_input_id = t.meter_input_id
				   AND aggregator = 'SUM'
			 )
		 );

		INTERNAL_ImportRealtimeRows();
	END IF;

	-- Process each region/reference match
	FOR r IN (
		SELECT DISTINCT t.region_sid, am.meter_source_type_id, st.arbitrary_period,
			mt.req_approval, st.descending, st.allow_reset
		  FROM v$temp_meter_reading_rows t
		  JOIN all_meter am ON t.region_sid = am.region_sid
		  JOIN meter_source_type st ON am.app_sid = st.app_sid AND am.meter_source_type_id = st.meter_source_type_id
		  JOIN meter_type mt ON am.app_sid = mt.app_sid AND am.meter_type_id = mt.meter_type_id
		 WHERE t.priority IS NULL 
		   AND am.manual_data_entry = 1
		   AND t.cons_error_msg IS NULL
		   AND t.cost_error_msg IS NULL
	) LOOP	
		
		SELECT MAX(req_approval)
		  INTO v_approval_pending
		  FROM v$meter_reading_all
		 WHERE region_sid = r.region_sid;
		 
		SELECT MAX(reset_val)
		  INTO v_reset_val
		  FROM v$temp_meter_reading_rows
		 WHERE region_sid = r.region_sid;
		 
		SELECT COUNT(*)
		  INTO v_invalid_reset_cnt
		  FROM v$temp_meter_reading_rows
		 WHERE region_sid = r.region_sid
		   AND consumption IS NULL
		   AND reset_val IS NOT NULL;
		
		IF r.req_approval != 0 AND 
			  v_approval_pending != 0 THEN 
			-- Add an error for all rows with this region sid
			UPDATE temp_meter_reading_rows
			   SET error_msg = 'Cannot import into a meter with readings pending approval.'
			 WHERE region_sid = r.region_sid;
			 
		ELSIF (r.arbitrary_period = 1 OR r.allow_reset = 0) AND
			  v_reset_val IS NOT NULL THEN
			-- Add an error for all rows with this region sid
			UPDATE temp_meter_reading_rows
			   SET error_msg = 'Reset not allowed for this meter'
			 WHERE region_sid = r.region_sid;
			 
		ELSIF v_invalid_reset_cnt > 0 THEN
			-- Reset values must hav an associated pre-reset reading
			UPDATE temp_meter_reading_rows
			   SET error_msg = 'Reset must have an accompanying pre-reset reading. Not importing entire meter.'
			 WHERE region_sid = r.region_sid;
	
		ELSE
			-- Detect no consumption and no value data
			FOR i IN (
				SELECT source_row
				  FROM v$temp_meter_reading_rows
				 WHERE region_sid = r.region_sid
				   AND consumption IS NULL
				   AND cost IS NULL
			) LOOP
				UPDATE temp_meter_reading_rows
				   SET error_msg = 'The units used or the cost must be specified.'
				 WHERE region_sid = r.region_sid
				   AND source_row = i.source_row;
			END LOOP;
			
			--Lookup CONSUMPTION measure sids and conversion_ids (if any) for this meter (region_sid)
			v_cons_measure_sid := NULL;
			v_cons_measure_conv_id := NULL;
			IF v_consumption_input_id IS NOT NULL THEN

				BEGIN
					SELECT measure_sid, measure_conversion_id
					  INTO v_cons_measure_sid, v_cons_measure_conv_id
					  FROM meter_input_aggr_ind
					 WHERE region_sid = r.region_sid
					   AND meter_input_id = v_consumption_input_id
					   AND aggregator = 'SUM';
					
					UPDATE temp_meter_reading_rows
					   SET measure_sid = v_cons_measure_sid,
						   meter_conversion_id = v_cons_measure_conv_id
					 WHERE region_sid = r.region_sid
					   AND meter_input_id = v_consumption_input_id;
				EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL; --Ignore
                END;
			END IF;

			--Lookup COST measure sids and conversion_ids (if any) for this meter (region_sid)
			v_cost_measure_sid := NULL;
			v_cost_measure_conv_id := NULL;
			IF v_cost_input_id IS NOT NULL THEN

				BEGIN
					SELECT measure_sid, measure_conversion_id
					  INTO v_cost_measure_sid, v_cost_measure_conv_id
					  FROM meter_input_aggr_ind
					 WHERE region_sid = r.region_sid
					   AND meter_input_id = v_cost_input_id
					   AND aggregator = 'SUM';
					   
					UPDATE temp_meter_reading_rows
					   SET measure_sid = v_cost_measure_sid,
						   meter_conversion_id = v_cost_measure_conv_id
					 WHERE region_sid = r.region_sid
					   AND meter_input_id = v_cost_input_id;
				EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL; --Ignore
                END;
			END IF;

			FOR u IN (
				SELECT DISTINCT measure_sid, unit_of_measure
				  FROM temp_meter_reading_rows
				 WHERE region_sid = r.region_sid
				   AND unit_of_measure IS NOT NULL --only do the following loop if the user has provided units of measure
				 ORDER BY measure_sid, unit_of_measure
			) LOOP

				v_test_measure	:= 0;
				v_test_measure_conv := NULL;
				
				--deal with null inputted units of measure first
				IF u.unit_of_measure IS NULL THEN
					UPDATE temp_meter_reading_rows
					   SET import_conversion_id = NULL  --just use default uom
					 WHERE region_sid = r.region_sid
					   AND measure_sid = u.measure_sid
					   AND unit_of_measure IS NULL;
				ELSE

					-- test the measure table for the inputted unit
					SELECT COUNT(*) 
					  INTO v_test_measure
					  FROM csr.measure m   
					 WHERE LOWER(m.description) = LOWER(u.unit_of_measure)
					   AND m.measure_sid = u.measure_sid;
					   
				
					IF v_test_measure > 0 THEN-- if it matches then set temp tables import_conversion_id to NULL 
						UPDATE temp_meter_reading_rows 
						   SET import_conversion_id = NULL
						 WHERE region_sid = r.region_sid
						   AND measure_sid = u.measure_sid
						   AND unit_of_measure = u.unit_of_measure;
					ELSE
						BEGIN
							-- test measure_conversion table for the inputted unit
							SELECT mc.measure_conversion_id 
							  INTO v_test_measure_conv
							  FROM csr.measure_conversion mc
							 WHERE LOWER(mc.description) = LOWER(u.unit_of_measure)
							   AND mc.measure_sid = u.measure_sid;
							   
						EXCEPTION
						WHEN no_data_found THEN
							v_test_measure_conv := NULL;
						END;
						
						IF v_test_measure_conv IS NOT NULL THEN 
							UPDATE temp_meter_reading_rows -- If matched then import_conversion_id := v_test_measure_conv
							   SET import_conversion_id = v_test_measure_conv
							 WHERE region_sid = r.region_sid 
							   AND measure_sid = u.measure_sid
							   AND LOWER(unit_of_measure) = LOWER(u.unit_of_measure);
						ELSE
							UPDATE temp_meter_reading_rows
							   SET error_msg = 'Could not convert using the supplied unit of measure'
							 WHERE region_sid = r.region_sid 
							   AND measure_sid = u.measure_sid
							   AND LOWER(unit_of_measure) = LOWER(u.unit_of_measure);
						END IF;
					END IF;
				END IF;
			END LOOP;
			--end
			
			IF r.arbitrary_period = 0 THEN
				-- Detect null reading dates
				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Reading date is required'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND start_dtm IS NULL;
				
				-- Detect locked reading date
				UPDATE temp_meter_reading_rows tmrr
				   SET error_msg = 'Reading date inside data lock period'
				 WHERE error_msg IS NULL
				   AND EXISTS (
						SELECT NULL
						  FROM customer c
						  LEFT JOIN (SELECT app_sid, MAX(start_dtm) start_dtm FROM meter_reading WHERE region_sid = tmrr.region_sid GROUP BY app_sid) mmr ON mmr.app_sid = c.app_sid
						  LEFT JOIN (SELECT app_sid, MIN(start_dtm) start_dtm FROM meter_reading WHERE region_sid = tmrr.region_sid AND start_dtm > tmrr.start_dtm GROUP BY app_sid) nmr ON nmr.app_sid = c.app_sid
						 WHERE
							CASE WHEN mmr.start_dtm < tmrr.start_dtm
							THEN csr_data_pkg.IsPeriodLocked(c.app_sid, mmr.start_dtm, tmrr.start_dtm)
							ELSE csr_data_pkg.IsPeriodLocked(c.app_sid, tmrr.start_dtm, NVL(nmr.start_dtm, SYSDATE))
							END = 1
					);
				
				-- Detect invalid dates for point-in-time type readings
				FOR i IN (
					SELECT source_row, next_source_row
					  FROM (
						SELECT source_row, start_dtm, 
							LEAD(source_row) OVER (ORDER BY start_dtm) next_source_row,
							LEAD(start_dtm) OVER (ORDER BY start_dtm) next_start_dtm
						  FROM v$temp_meter_reading_rows
						 WHERE region_sid = r.region_sid
					  ) WHERE start_dtm = next_start_dtm
				) LOOP
					UPDATE temp_meter_reading_rows
					   SET error_msg = 'Start dates for readings can''t be the same.'
					 WHERE region_sid = r.region_sid
					   AND error_msg IS NULL
					   AND (source_row = i.source_row OR source_row = i.next_source_row);
				END LOOP;
				
				-- Detect readings out of sequence
				FOR i IN (
					SELECT *
					  FROM (
						SELECT source_row, start_dtm, val, is_reset,
							   LAG(val) OVER (ORDER BY start_dtm) next_val
						  FROM (
							SELECT source_row, start_dtm start_dtm, consumption val,
								   DECODE(LAG(reset_val) OVER (ORDER BY start_dtm), NULL, 0, 1) is_reset
							  FROM v$temp_meter_reading_rows
							 WHERE region_sid = r.region_sid
							   AND cons_error_msg IS NULL
							   AND cost_error_msg IS NULL
							UNION
							SELECT NULL source_row, start_dtm, val_number val, 
								   DECODE(baseline_val, LAG(baseline_val) OVER (ORDER BY start_dtm), 0, 1) is_reset
							  FROM v$meter_reading
							 WHERE region_sid = r.region_sid
						)
					 )
					 WHERE DECODE(r.descending, 1, next_val - val, val - next_val) < 0 
					   AND is_reset = 0
				) LOOP
					UPDATE temp_meter_reading_rows 
					   SET error_msg = 
							'Inconsistent meter reading values, next reading less than current ' || 
							'reading. Possibly a conflict with existing reading data. Inconsistent ' ||
							'reading and subsequent readings not imported. '
					 WHERE region_sid = r.region_sid
					   AND error_msg IS NULL
					   AND start_dtm >= i.start_dtm;
					EXIT;
				END LOOP;
				
				-- Update data where reading already exists
				FOR emr IN (
				    SELECT tmr.start_dtm, tmr.region_sid, tmr.consumption, tmr.cost, omr.val_number old_consumption, 
						   omr.cost old_cost, omr.meter_reading_id,
						   cons_import_conv_id, cons_meter_conv_id, cost_import_conv_id, cost_meter_conv_id
				      FROM v$temp_meter_reading_rows  tmr
					  JOIN meter_reading omr
					    ON omr.region_sid = tmr.region_sid
					   AND omr.start_dtm = tmr.start_dtm
					 WHERE omr.region_sid = r.region_sid
					   AND omr.meter_source_type_id = r.meter_source_type_id
					   AND cons_error_msg IS NULL
					   AND cost_error_msg IS NULL
				) LOOP
				
					UPDATE meter_reading
					   SET val_number = NVL2(emr.consumption, 
										meter_monitor_pkg.UNSEC_ConvertMeterValue(emr.consumption, emr.cons_meter_conv_id, emr.cons_import_conv_id, emr.start_dtm),
										emr.old_consumption),
						   cost	= NVL2(emr.cost, 
										meter_monitor_pkg.UNSEC_ConvertMeterValue(emr.cost, emr.cost_meter_conv_id, emr.cost_import_conv_id, emr.start_dtm),
										emr.old_cost),
						   entered_dtm = TRUNC(SYSDATE, 'DD'),
						   entered_by_user_sid = security_pkg.GetSID
					 WHERE meter_reading_id = emr.meter_reading_id;
				END LOOP;
				
			  
				-- Insert valid reading data
				FOR mr IN (
					SELECT start_dtm, consumption, security_pkg.GetSID, 
						TRUNC(SYSDATE, 'DD'), note, reference, cost, r.meter_source_type_id, reset_val,
						cons_import_conv_id, cons_meter_conv_id, cost_import_conv_id, cost_meter_conv_id
				    FROM v$temp_meter_reading_rows
				   WHERE region_sid = r.region_sid
				     AND cons_error_msg IS NULL
				     AND cost_error_msg IS NULL
					 AND start_dtm NOT IN(
						SELECT start_dtm
						  FROM meter_reading
						 WHERE region_sid = r.region_sid
						   AND meter_source_type_id = r.meter_source_type_id
						)
				     	ORDER BY start_dtm
				) LOOP
					-- Insert the reading
					INSERT INTO meter_reading (meter_reading_id, region_sid, start_dtm, val_number, entered_by_user_sid, entered_dtm, note, reference, cost, meter_source_type_id)
						VALUES(meter_reading_id_seq.NEXTVAL, r.region_sid, mr.start_dtm,
							meter_monitor_pkg.UNSEC_ConvertMeterValue(mr.consumption, mr.cons_meter_conv_id, mr.cons_import_conv_id, mr.start_dtm), 
							security_pkg.GetSID, TRUNC(SYSDATE, 'DD'), mr.note, mr.reference, 
							meter_monitor_pkg.UNSEC_ConvertMeterValue(mr.cost, mr.cost_meter_conv_id, mr.cost_import_conv_id, mr.start_dtm), 
							r.meter_source_type_id)
						RETURNING meter_reading_id INTO v_reading_id;
					-- Set the baseline value
					INTERNAL_UpdateBaselineVal(v_reading_id, mr.reset_val);
					-- Create energy star jobs if required
					-- XXX: Could do with some sort of bulk procedure for imports
					energy_star_job_pkg.OnMeterReadingChange(r.region_sid, v_reading_id);
				END LOOP;
				     
				
			ELSIF r.arbitrary_period = 1 THEN
				
				-- Detect invalid dates
				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Arbitrary periods require a start and end date.'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND start_dtm IS NULL
				   AND end_dtm IS NULL;

				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Arbitrary periods require a start date.'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND start_dtm IS NULL;

				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Arbitrary periods require an end date.'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND end_dtm IS NULL;

				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Start date can''t be the same or greater than the end date.'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND start_dtm >= end_dtm;
				
				-- Detect locked reading date
				UPDATE temp_meter_reading_rows tmrr
				   SET error_msg = 'Reading date inside data lock period'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND csr_data_pkg.IsPeriodLocked(SYS_CONTEXT('SECURITY', 'APP'), tmrr.start_dtm, tmrr.end_dtm) = 1; 
				
				-- Detect overlaps
				FOR i IN (
					SELECT source_row, next_source_row
					  FROM (
						SELECT source_row, end_dtm, 
							LEAD(source_row) OVER (ORDER BY start_dtm) next_source_row,
							LEAD(start_dtm) OVER (ORDER BY start_dtm) next_start_dtm
						  FROM v$temp_meter_reading_rows
						 WHERE region_sid = r.region_sid
					 )
					 WHERE end_dtm > next_start_dtm
					   AND source_row != next_source_row
				) LOOP
					UPDATE temp_meter_reading_rows
					   SET error_msg = 'Reading periods can''t overlap.'
					 WHERE region_sid = r.region_sid
					   AND error_msg IS NULL
					   AND (source_row = i.source_row OR source_row = i.next_source_row);
				END LOOP;

				-- Check for overlaps with existing periods
				UPDATE temp_meter_reading_rows
				   SET error_msg = 'Entered period overlaps existing period.'
				 WHERE region_sid = r.region_sid
				   AND error_msg IS NULL
				   AND source_row IN (
					SELECT t.source_row
					  FROM v$temp_meter_reading_rows t, v$meter_reading mr
					 WHERE mr.region_sid = r.region_sid
					   AND t.region_sid = mr.region_sid
					   AND t.start_dtm < mr.end_dtm 
					   AND t.end_dtm > mr.start_dtm
					   AND t.start_dtm <> mr.start_dtm
					   AND t.end_dtm <> mr.end_dtm
				 );
				 
				-- Update data where reading already exist
				FOR emr IN (				
				    SELECT tmr.start_dtm, tmr.end_dtm, tmr.region_sid, tmr.consumption, tmr.cost, 
					       omr.val_number old_consumption, omr.cost old_cost, omr.meter_reading_id,
						   cons_import_conv_id, cons_meter_conv_id, cost_import_conv_id, cost_meter_conv_id
				      FROM v$temp_meter_reading_rows  tmr
					  JOIN meter_reading omr
					    ON omr.region_sid = tmr.region_sid
					   AND omr.start_dtm = tmr.start_dtm
					   AND omr.end_dtm = tmr.end_dtm
					 WHERE omr.region_sid = r.region_sid
					   AND omr.meter_source_type_id = r.meter_source_type_id
					   AND cons_error_msg IS NULL
					   AND cost_error_msg IS NULL
				) LOOP
				
					UPDATE meter_reading
					   SET val_number = NVL2(emr.consumption, 
										meter_monitor_pkg.UNSEC_ConvertMeterValue(emr.consumption, emr.cons_meter_conv_id, emr.cons_import_conv_id, emr.start_dtm),
										emr.old_consumption),
						   cost = NVL2(emr.cost, 
										meter_monitor_pkg.UNSEC_ConvertMeterValue(emr.cost, emr.cost_meter_conv_id, emr.cost_import_conv_id, emr.start_dtm),
										emr.old_cost),
						   entered_dtm = TRUNC(SYSDATE, 'DD'),
						   entered_by_user_sid = security_pkg.GetSID
					WHERE meter_reading_id = emr.meter_reading_id;
				END LOOP;
				
				-- Insert valid reading data
				FOR mr IN (
					SELECT meter_reading_id_seq.NEXTVAL, region_sid, start_dtm, end_dtm, consumption, security_pkg.GetSID, TRUNC(SYSDATE, 'DD'), note, reference, cost, r.meter_source_type_id,
					cons_import_conv_id, cons_meter_conv_id, cost_import_conv_id, cost_meter_conv_id
					  FROM v$temp_meter_reading_rows
					 WHERE region_sid = r.region_sid
					   AND cons_error_msg IS NULL
					   AND cost_error_msg IS NULL
					   AND (start_dtm, end_dtm) NOT IN (
						SELECT start_dtm, end_dtm
						  FROM meter_reading
						 WHERE region_sid = r.region_sid
						   AND meter_source_type_id = r.meter_source_type_id
						)
				) LOOP
					v_have_meter_reading:=1;
					BEGIN
						SELECT *
						  INTO v_meter_reading 
						  FROM meter_reading omr
						 WHERE mr.region_sid = omr.region_sid
						   AND omr.meter_source_type_id = mr.meter_source_type_id
						   AND omr.start_dtm = mr.start_dtm 
						   AND omr.end_dtm = mr.end_dtm;
					 EXCEPTION
						WHEN NO_DATA_FOUND THEN v_have_meter_reading:=0;
					 END;
					IF v_have_meter_reading = 0 OR
					   mr.start_dtm != v_meter_reading.start_dtm OR
					   mr.end_dtm != v_meter_reading.end_dtm OR
					   mr.consumption != v_meter_reading.val_number OR
					   NVL(mr.note,'null') != NVL(v_meter_reading.note,'null') OR
					   NVL(mr.reference,'null') != NVL(v_meter_reading.reference,'null') OR
					   mr.cost != v_meter_reading.cost OR
					   mr.meter_source_type_id != v_meter_reading.meter_source_type_id
					THEN
						INSERT INTO meter_reading (meter_reading_id, region_sid, start_dtm, end_dtm, val_number, entered_by_user_sid, entered_dtm, note, reference, cost, meter_source_type_id)
						VALUES (meter_reading_id_seq.NEXTVAL, r.region_sid, mr.start_dtm, mr.end_dtm, 
								meter_monitor_pkg.UNSEC_ConvertMeterValue(mr.consumption, mr.cons_meter_conv_id, mr.cons_import_conv_id, mr.start_dtm), 
								security_pkg.GetSID, TRUNC(SYSDATE, 'DD'), mr.note, mr.reference, 
								meter_monitor_pkg.UNSEC_ConvertMeterValue(mr.cost, mr.cost_meter_conv_id, mr.cost_import_conv_id, mr.start_dtm), 
								r.meter_source_type_id)
							RETURNING meter_reading_id INTO v_reading_id;
						-- Create energy star jobs if required
						-- XXX: Could do with some sort of bulk procedure for imports
						energy_star_job_pkg.OnMeterReadingChange(r.region_sid, v_reading_id);
					END IF;
				END LOOP;	   
			END IF;
		END IF;

		-- Get min and max month for computation of system values
		SELECT MIN(start_dtm) min_reading_dtm, NVL(MAX(end_dtm), MAX(start_dtm)) max_reading_dtm
		  INTO v_min_dtm, v_max_dtm 
		  FROM v$temp_meter_reading_rows
		 WHERE region_sid = r.region_sid
		   AND cons_error_msg IS NULL
		   AND cost_error_msg IS NULL;

		-- If this is point in time then we need to find the dates for readings before to the
		-- min and after the max dtms, or just use the min/max if the before/after don't exist
		IF r.arbitrary_period = 0 THEN

			-- Get existing reading date directly before 
			-- min dtm (or min_dtm if reading does not exist)
			SELECT NVL(MAX(start_dtm), v_min_dtm)
			  INTO v_min_dtm
			  FROM v$meter_reading
			 WHERE region_sid = r.region_sid
			   AND start_dtm < v_min_dtm;

			-- Get exsting reading date directly after 
			-- max dtm (or max_dtm if reading does not exist)
			SELECT NVL(MIN(start_dtm), v_max_dtm)
			  INTO v_max_dtm
			  FROM v$meter_reading
			 WHERE region_sid = r.region_sid
			   AND start_dtm > v_max_dtm;
		END IF;

		-- If there are values, recompute system values between min/max dates
		IF v_min_dtm IS NOT NULL AND v_max_dtm IS NOT NULL THEN
			SetValTableForPeriod(r.region_sid, NULL, v_min_dtm, v_max_dtm);
		END IF;

	END LOOP;
	
	-- Return results
	OPEN out_cur FOR
		SELECT source_row, LISTAGG(error_msg, ',') WITHIN GROUP	(ORDER BY meter_input_id) error_msg		
		  FROM temp_meter_reading_rows
		 WHERE error_msg IS NOT NULL
	  GROUP BY source_row
      ORDER BY source_row;
END;

-- Intended to be called using an array bind
PROCEDURE PrepMeterImportRow(
    in_source_row			IN temp_meter_import_rows.source_row%TYPE,
    in_parent_sid         	IN temp_meter_import_rows.parent_sid%TYPE,
    in_meter_name          	IN temp_meter_import_rows.meter_name%TYPE,
    in_meter_ref         	IN temp_meter_import_rows.meter_ref%TYPE,
    in_cons_sid            	IN temp_meter_import_rows.consumption_sid%TYPE,
    in_cons_uom				IN temp_meter_import_rows.consumption_uom%TYPE,
    in_cost_sid				IN temp_meter_import_rows.cost_sid%TYPE,
    in_cost_uom				IN temp_meter_import_rows.cost_uom%TYPE
)
AS
BEGIN
	INSERT INTO temp_meter_import_rows
		(source_row, parent_sid, meter_name, meter_ref, consumption_sid, consumption_uom, cost_sid, cost_uom)
	  VALUES (in_source_row, in_parent_sid, in_meter_name, in_meter_ref, in_cons_sid, in_cons_uom, in_cost_sid, in_cost_uom);
END;

PROCEDURE INTERNAL_AppendImportRowError(
	in_source_row			IN	temp_meter_import_rows.source_row%TYPE,
	in_msg					IN	temp_meter_import_rows.error_msg%TYPE
)
AS
BEGIN
	UPDATE temp_meter_import_rows
	   SET error_msg = NVL(error_msg, '') || NVL2(error_msg, CHR(10), '') || in_msg
	 WHERE source_row = in_source_row;
END;

PROCEDURE ImportMeterRows(
	in_source_type_id		IN	all_meter.meter_source_type_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_error					BOOLEAN;
	v_val_conv_id			measure_conversion.measure_conversion_id%TYPE;
	v_val_measure_sid		security_pkg.T_SID_ID;
	v_cost_conv_id			measure_conversion.measure_conversion_id%TYPE;
	v_cost_measure_sid		security_pkg.T_SID_ID;
	v_meter_type_id			meter_type.meter_type_id%TYPE;
	v_region_sid			security_pkg.T_SID_ID;
	v_empty_ids				security_pkg.T_SID_IDS;
BEGIN
	-- Detect invalid parent region sids
	UPDATE temp_meter_import_rows
	   SET error_msg = 'Invalid parent region SID'
	 WHERE parent_sid IN (
	 	SELECT parent_sid 
	 	  FROM temp_meter_import_rows t
	 	MINUS
	 	SELECT t.parent_sid
	 	  FROM region r, temp_meter_import_rows t
	 	 WHERE r.region_sid = t.parent_sid
	 );

	-- Detect invalid consumption indicator sids
	UPDATE temp_meter_import_rows
	   SET error_msg = 'Invalid consumption indicator SID'
	 WHERE consumption_sid IN (
	 	SELECT consumption_sid 
	 	  FROM temp_meter_import_rows t
	 	MINUS
	 	SELECT t.consumption_sid
	 	  FROM ind i, temp_meter_import_rows t
	 	 WHERE i.ind_sid = t.consumption_sid
	 );
	 
	-- Detect invalid cost indicator sids
	UPDATE temp_meter_import_rows
	   SET error_msg = 'Invalid cost indicator SID'
	 WHERE cost_sid IN (
	 	SELECT cost_sid 
	 	  FROM temp_meter_import_rows t
	 	MINUS
	 	SELECT t.cost_sid
	 	  FROM ind i, temp_meter_import_rows t
	 	 WHERE i.ind_sid = t.cost_sid
	 );

	-- XXX: References need to be unique.
	-- XXX: What about trashed meters
	
	-- Dettect duplicate references within the import
	FOR r IN (
		SELECT source_row, lag_source_row, meter_ref
		  FROM (
			SELECT source_row, LAG(source_row) OVER (ORDER BY meter_ref) lag_source_row,
				meter_ref, LAG(meter_ref) OVER (ORDER BY meter_ref) lag_meter_ref
		  	  FROM temp_meter_import_rows
		 ) WHERE meter_ref = lag_meter_ref
	) LOOP
		INTERNAL_AppendImportRowError(r.source_row, 'Duplicate meter reference '||r.meter_ref||' found in source file');
		INTERNAL_AppendImportRowError(r.lag_source_row, 'Duplicate meter reference '||r.meter_ref||' found in source file');
	END LOOP;
	
	-- Detect clashes with existing meter references
	FOR r IN (
		SELECT source_row, meter_ref
		  FROM temp_meter_import_rows t, v$meter m
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.meter_ref = m.reference
		   AND m.region_sid NOT IN (
		   		SELECT trash_sid
		   		  FROM trash
		   )
	) LOOP
		INTERNAL_AppendImportRowError(r.source_row, 'Meter reference '||r.meter_ref||' already exists on system');
	END LOOP;
	
	-- Now try and import the remaining rows
	FOR r IN (	 
		SELECT t.source_row, t.parent_sid, t.meter_name, t.meter_ref, 
			t.consumption_sid, t.consumption_uom, t.cost_sid, t.cost_uom,
			vi.measure_sid consumption_measure_sid, ci.measure_sid cost_measure_sid
	 	  FROM region r, temp_meter_import_rows t, ind vi, ind ci
	 	 WHERE r.region_sid = t.parent_sid
	 	   AND vi.ind_sid = t.consumption_sid
	 	   AND ci.ind_sid(+) = t.cost_sid
	 	   AND t.error_msg IS NULL -- ignore anything that is already in an error state
	) LOOP
		
		v_error := FALSE;
		
		-- Try to find the measure conversion for consumption data
		v_val_conv_id := NULL;
		IF r.consumption_uom IS NOT NULL THEN
			-- Look for a matching conversion
			BEGIN
				SELECT measure_conversion_id
				  INTO v_val_conv_id
				  FROM measure_conversion
				 WHERE measure_sid = r.consumption_measure_sid
				   AND LOWER(description) = LOWER(r.consumption_uom);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				BEGIN
					-- No conversion matches, just check that base measure name is a match
					SELECT measure_sid
					  INTO v_val_measure_sid
					  FROM measure
					 WHERE measure_sid = r.consumption_measure_sid
					   AND LOWER(description) = LOWER(r.consumption_uom);		
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						INTERNAL_AppendImportRowError(r.source_row, 'Consumption UOM '||r.consumption_uom||' not found');
						v_error := TRUE;
				END;
			END;
		END IF;
		
		-- Try to find the measure conversion for cost data (if required)
		v_cost_conv_id := NULL;
		IF r.cost_sid IS NOT NULL AND
		   r.cost_uom IS NOT NULL THEN
			-- Look for a matching conversion
			BEGIN
				SELECT measure_conversion_id
				  INTO v_cost_conv_id
				  FROM measure_conversion
				 WHERE measure_sid = r.cost_measure_sid
				   AND LOWER(description) = LOWER(r.cost_uom);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				BEGIN
					-- No conversion matches, just check that base measure name is a match
					SELECT measure_sid
					  INTO v_cost_measure_sid
					  FROM measure
					 WHERE measure_sid = r.cost_measure_sid
					   AND LOWER(description) = LOWER(r.cost_uom);		
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						INTERNAL_AppendImportRowError(r.source_row, 'Cost UOM '||r.cost_uom||' not found');
						v_error := TRUE;
				END;
			END;
		END IF;
		
		-- Update the meter ind id if a match can be found
		BEGIN
			SELECT mi.meter_type_id
			  INTO v_meter_type_id
	   		  FROM (
	   		  		SELECT mi.meter_type_id, ii.ind_sid consumption_ind_sid, cii.ind_sid cost_ind_sid
					  FROM meter_type mi
					  JOIN meter_input inp ON inp.app_sid = mi.app_sid AND inp.lookup_key = 'CONSUMPTION'
					  JOIN meter_type_input ii ON ii.app_sid = mi.app_sid AND ii.meter_type_id = mi.meter_type_id AND ii.meter_input_id = inp.meter_input_id
					  LEFT JOIN meter_input cinp ON cinp.app_sid = mi.app_sid AND cinp.lookup_key = 'COST'
					  LEFT JOIN meter_type_input cii ON cii.app_sid = mi.app_sid AND cii.meter_type_id = mi.meter_type_id AND cii.meter_input_id = cinp.meter_input_id
	   		  ) mi
	   		 WHERE mi.consumption_ind_sid = r.consumption_sid
	   		   AND NVL(mi.cost_ind_sid, -1) = NVL(r.cost_sid, -1);
			
			 
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				INTERNAL_AppendImportRowError(r.source_row, 
					'More than one METER_TYPE matches consumption ind sid = '||r.consumption_sid||' and cost ind sid = '||NVL(r.cost_sid, '(NULL)'));
				v_error := TRUE;
				
			WHEN NO_DATA_FOUND THEN
				-- Meter ind required
				-- XXX: Chang importer so it can use the meter ind or it's lookup key instead of the ind_sids
				INTERNAL_AppendIMportRowError(r.source_row, 
					'No METER_TYPE matches consumption ind sid = '||r.consumption_sid||' and cost ind sid = '||NVL(r.cost_sid, '(NULL)'));
				v_error := TRUE;
		END;
		
		-- If there are no errors then create the meter
		IF NOT v_error THEN
			
			-- Create the region
			region_pkg.CreateRegion(		
				in_parent_sid		=>	r.parent_sid,
				in_name				=>	r.meter_name,
				in_description		=>	r.meter_name,
				in_acquisition_dtm 	=> 	NULL,
				out_region_sid		=>	v_region_sid
			);

			-- Make the region into a meter
			LegacyMakeMeter(
				in_act_id					=> security_pkg.GETACT,
				in_region_sid				=> v_region_sid,
				in_meter_type_id			=> v_meter_type_id,
				in_note						=> 'Created by meter import',
				in_primary_conversion_id	=> v_val_conv_id,
				in_cost_conversion_id		=> v_cost_conv_id,
				in_source_type_id			=> in_source_type_id,
				in_manual_data_entry		=> 1,
				in_reference				=> r.meter_ref,
				in_contract_ids				=> v_empty_ids,
				in_active_contract_id		=> NULL
			);
			
		END IF;
	END LOOP;
	
	-- Return results
	OPEN out_cur FOR
		SELECT source_row, error_msg
		  FROM temp_meter_import_rows
		 WHERE error_msg IS NOT NULL
		 	ORDER BY source_row;
END;

PROCEDURE GetCalcSubMeterAggr(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetCalcSubMeterAggr');
	END IF;

    OPEN out_cur FOR  
        SELECT c.primary_ind_sid ind_sid,
            c.calc_region_sid region_sid,
            NVL(p.period_start_dtm, c.period_start_dtm) period_start_dtm, 
            NVL(p.period_end_dtm, c.period_end_dtm) period_end_dtm,
            csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id,
            (p.val - NVL(c.val,0)) / NVL(CASE WHEN calc_sibling_cnt = 0 THEN 1 ELSE calc_sibling_cnt END,1) val_number,
            null error_code
          FROM (
            SELECT /*+ALL_ROWS*/pr.description, pm.primary_ind_sid, pm.region_sid, v.period_start_dtm, v.period_end_dtm, sum(val_number) val
              FROM v$legacy_meter pm 
              JOIN v$region pr ON pm.region_sid = pr.region_sid 
              JOIN val v ON pm.primary_ind_sid = v.ind_sid AND pm.region_sid = v.region_sid
             WHERE pm.region_sid IN (
                SELECT DISTINCT r.parent_sid
                  FROM all_meter m
                  JOIN meter_source_type mst ON m.meter_source_type_id = mst.meter_source_type_id AND mst.is_calculated_sub_meter = 1
                  JOIN region r ON m.region_sid = r.region_sid AND m.app_sid = r.app_sid
             )
               AND v.period_start_dtm >= in_start_dtm
               AND v.period_end_dtm <= in_end_dtm
             GROUP BY pr.description, pm.primary_ind_sid, pm.region_sid, v.period_start_dtm, v.period_end_dtm
          )p RIGHT JOIN (
            SELECT primary_ind_sid, calc_region_sid, period_start_dtm, period_end_dtm, is_calculated_sub_meter, parent_sid,
                calc_sibling_cnt, SUM(val_number) val
              FROM (
                SELECT /*+ALL_ROWS*/sr.description, m.region_sid calc_region_sid, m.primary_ind_sid, sibm.region_sid, v.period_start_dtm, v.period_end_dtm, 
                    sibmst.is_calculated_sub_meter, r.parent_sid,
                    COUNT(DISTINCT CASE WHEN sibmst.is_calculated_sub_meter = 1 THEN sibm.region_sid ELSE NULL END) OVER (PARTITION BY r.parent_sid) calc_sibling_cnt,
                    val_number
                  FROM v$legacy_meter m
                  JOIN meter_source_type mst ON m.meter_source_type_id = mst.meter_source_type_id AND mst.is_calculated_sub_meter = 1
                  JOIN region r ON m.region_sid = r.region_sid AND m.app_sid = r.app_sid
                  JOIN region sib ON r.parent_sid = sib.parent_sid AND r.app_sid = sib.app_sid AND r.region_sid != sib.region_sid
                  JOIN v$legacy_meter sibm ON sib.region_sid = sibm.region_sid AND r.app_sid = sibm.app_sid
                  JOIN meter_source_type sibmst ON sibm.meter_source_type_id = sibmst.meter_source_type_id
                  JOIN v$region sr ON sibm.region_sid = sr.region_sid 
                  LEFT JOIN val v ON sibm.primary_ind_sid = v.ind_sid AND sibm.region_sid = v.region_sid
                 WHERE v.period_start_dtm >= in_start_dtm
                   AND v.period_end_dtm <= in_end_dtm
              )
              WHERE is_calculated_sub_meter = 0
              GROUP BY primary_ind_sid, calc_region_sid, period_start_dtm, period_end_dtm, is_calculated_sub_meter, parent_sid, calc_sibling_cnt    
         )c ON p.region_sid = c.parent_sid AND p.period_start_dtm = c.period_start_dtm AND p.period_end_dtm = c.period_end_dtm
         ORDER BY c.primary_ind_sid, c.calc_region_sid, period_start_dtm;
END;

PROCEDURE ApproveReading(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_source_type_id		meter_source_type.meter_source_type_id%TYPE;
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;
	v_req_approval			meter_reading.req_approval%TYPE;
	v_is_delete				meter_reading.is_delete%TYPE;
	v_replaces_reading_id	meter_reading.meter_reading_id%TYPE;
	v_from_previous			meter_reading.val_number%TYPE;
	v_to_next				meter_reading.val_number%TYPE;
	v_start_dtm				meter_reading.start_dtm%TYPE;
	v_end_dtm				meter_reading.end_dtm%TYPE;
	v_descending			meter_source_type.descending%TYPE;
	v_baseline				meter_reading.baseline_val%TYPE;
	v_prev_baseline			meter_reading.baseline_val%TYPE;
	v_replaced_baseline		meter_reading.baseline_val%TYPE;
BEGIN
	-- We have to check that approving readings doesn't cause overlaps. 
	-- Although new readings are checked against the head version when 
	-- they are entered approval out of order can cause overlaps.
	
	-- Get some information from the reading
	SELECT mr.region_sid, mr.meter_source_type_id, st.arbitrary_period, mr.req_approval, mr.start_dtm, mr.end_dtm, replaces_reading_id, is_delete, st.descending
	  INTO v_region_sid, v_source_type_id, v_arbitrary_period, v_req_approval, v_start_dtm, v_end_dtm, v_replaces_reading_id, v_is_delete, v_descending
	  FROM meter_reading mr, meter_source_type st
	 WHERE mr.meter_reading_id = in_reading_id
	   AND st.meter_source_type_id = mr.meter_source_type_id;
	   
	IF v_req_approval = 0 THEN
		-- XXX: Probably don't need to raise an error, just silently exit as it may have been approved 'in the meantime'?
		--RAISE_APPLICATION_ERROR(meter_pkg.ERR_ALREADY_APPROVED, 'Meter reading does not require approval');
		-- Nothing to do
		RETURN;
	END IF;
	
	-- XXX: We might want to put the validation code on a seperate procedure 
	-- so we report which readings are overlapped when approving the given reading?
	
	-- Point in time - Check reading data is sequential
	-- Note thet in this case we're going to compare reading for approval with 
	-- readings already approved as the approved data set needs to be valid
	IF v_arbitrary_period = 0 THEN
		-- Get previous and next values for comparison
		SELECT from_previous, to_next 
		  INTO v_from_previous, v_to_next
	  	  FROM (
			 SELECT meter_reading_id, 
			 	val_number + NVL(baseline_val, 0) - LAG(val_number) OVER (ORDER BY start_dtm) - NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0) from_previous,
				LEAD(val_number) OVER (ORDER BY start_dtm) + NVL(LEAD(baseline_val) OVER (ORDER BY start_dtm), 0) - val_number - NVL(baseline_val, 0)  to_next
			  FROM meter_reading
			 WHERE region_sid = v_region_sid
			   AND meter_source_type_id = v_source_type_id
			   AND active = 1
			   AND (req_approval = 0 OR (req_approval = 1 AND meter_reading_id = in_reading_id)) -- Compare this reading with already approved data
	     )
		 WHERE meter_reading_id = in_reading_id;
		 
		-- Check the reading is in the correct range
		IF v_descending = 0 THEN
			IF v_from_previous < 0 THEN
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_LOW, 'Meter reading too low');
			ELSIF v_to_next < 0 THEN 
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_HIGH, 'Meter reading too high');
			END IF;
	    ELSE
	    	IF v_from_previous > 0 THEN
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_HIGH, 'Meter reading too high');
			ELSIF v_to_next > 0 THEN 
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_READING_TOO_LOW, 'Meter reading too low');
			END IF;
	    END IF;
	
	-- Arbitrary period - Check for overlaps of reading to be approved with existing data
	-- Note thet in this case we're going to compare reading for approval with 
	-- readings already approved as the approved data set needs to be valid
	ELSE
		FOR r IN (
			SELECT start_dtm, end_dtm
			  FROM meter_reading r
			 WHERE r.region_sid = v_region_sid
			   AND r.meter_reading_id != in_reading_id
			   AND v_start_dtm < r.end_dtm 
			   AND v_end_dtm > r.start_dtm
			   AND meter_source_type_id = v_source_type_id
			   AND active = 1
			   AND (req_approval = 0 OR (req_approval = 1 AND meter_reading_id = in_reading_id)) -- Compare this reading with already approved data
			   AND meter_reading_id <> NVL(v_replaces_reading_id, -1) -- Excluding the reading it replaces (if set)
		) LOOP
			 RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_PERIOD_OVERLAP, 'Approved reading period overlaps existing reading period');
		END LOOP;
		
	END IF;
	
	
	-- Ok, what do we need to do to approve...
	
	IF v_replaces_reading_id IS NOT NULL THEN
		
		-- Get the start/end dates fom the reading being replaced
		SELECT start_dtm, end_dtm, NVL(baseline_val, 0)
		  INTO v_start_dtm, v_end_dtm, v_replaced_baseline
		  FROM v$meter_reading_all
		 WHERE meter_reading_id = v_replaces_reading_id;
		 
		-- Remove the reference to the reading to be replaced
		UPDATE meter_reading
		   SET replaces_reading_id = NULL
		 WHERE region_sid = v_region_sid
		   AND meter_reading_id = in_reading_id;
		
		-- Create energy star jobs if required (before we actually delete the row)
		energy_star_job_pkg.OnMeterReadingChange(v_region_sid, v_replaces_reading_id);
		
		-- Delete the reading
		INTERNAL_DeleteMeterReading(v_replaces_reading_id);
		
	END IF;
	
	-- This is a delete, we've deleted the indicated reading, 
	-- now get rid of the row indicating the delete was required.
	-- This shouldn't have any dependencies to remove.
	IF v_is_delete != 0 THEN
		
		-- Remove the delete 'marker' reading
		DELETE FROM meter_reading
		 WHERE meter_reading_id = in_reading_id;
		 
		-- Write an audit log entry
		IF v_end_dtm IS NULL THEN
			csr_data_pkg.WriteAuditLogEntry(
		    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
		    	'Delete request approved (reading deleted) for reading {0}', 
		    	TO_CHAR(v_start_dtm,'dd Mon yyyy')
		    );
		ELSE
			csr_data_pkg.WriteAuditLogEntry(
		    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
		    	'Delete request approved (reading deleted) for reading from {0} to {1}', 
		    	TO_CHAR(v_start_dtm,'dd Mon yyyy'),
		    	TO_CHAR(v_end_dtm,'dd Mon yyyy')
		    );
		END IF;
		
		-- ALL DONE
		RETURN;
	END IF;
	
	-- Integrate the apprvoed row
	UPDATE meter_reading
	   SET req_approval = 0,
	   	   active = 1,
	       replaces_reading_id = NULL,
	       approved_dtm = SYSDATE,
	       approved_by_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE meter_reading_id = in_reading_id;
	 
	-- Get the baseline vlaues for this reading and the previous reading
   	v_baseline := INTERNAL_GetBaselineVal(in_reading_id);
   	v_prev_baseline := INTERNAL_GetPrevBaselineVal(in_reading_id);
   	
   	-- Adjust the baseline if it has changed because if this reading
   	IF v_baseline != v_prev_baseline OR
   	   v_baseline != v_replaced_baseline THEN
		-- This step will have been defered from SetMeterReading.
		-- Update baseline and reading values after this change,
		-- up until the next time the baseline changes.
		UPDATE meter_reading
		   SET val_number = val_number + NVL(baseline_val, 0) - v_baseline,
		       baseline_val = v_baseline
		 WHERE region_sid = v_region_sid
		   AND start_dtm > v_start_dtm
		   AND NVL(baseline_val, 0) = DECODE(v_baseline, v_replaced_baseline, v_prev_baseline, v_replaced_baseline)
		;
	END IF;
	
	-- Write an audit log entry
	IF v_end_dtm IS NULL THEN
		csr_data_pkg.WriteAuditLogEntry(
	    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
	    	'Meter reading approved for reading {0}', 
	    	TO_CHAR(v_start_dtm,'dd Mon yyyy')
	    );
	ELSE
		csr_data_pkg.WriteAuditLogEntry(
	    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
	    	'Meter reading approved for reading from {0} to {1}', 
	    	TO_CHAR(v_start_dtm,'dd Mon yyyy'),
	    	TO_CHAR(v_end_dtm,'dd Mon yyyy')
	    );
	END IF;
	
	-- Update system values
	INTERNAL_SetValTableForReading(security_pkg.GetACT, in_reading_id, 0, v_start_dtm, NVL(v_end_dtm, v_start_dtm));
	
	-- Create invoice if required
	UtilityInvoiceFromReading(in_reading_id);
	
	-- Create energy star jobs if required
	energy_star_job_pkg.OnMeterReadingChange(v_region_sid, in_reading_id);
	
END;

PROCEDURE SetReadingActiveFlag(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	in_active				IN	meter_reading.active%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_start_dtm				meter_reading.start_dtm%TYPE;
	v_end_dtm				meter_reading.end_dtm%TYPE;
	v_active_state			VARCHAR2(32);
BEGIN
	-- Set the flag
	UPDATE meter_reading
	   SET active = in_active
	 WHERE meter_reading_id = in_reading_id;
	
	-- Update system values
	SetValTableForReading(security_pkg.GetACT, in_reading_id, 0);
	
	SELECT region_sid, start_dtm, end_dtm, DECODE(active, 0, 'inactive', 'active')
	  INTO v_region_sid, v_start_dtm, v_end_dtm, v_active_state
	  FROM meter_reading mr
	 WHERE mr.meter_reading_id = in_reading_id;
	
	-- Write an entry to the audit log
	IF v_end_dtm IS NULL THEN
		csr_data_pkg.WriteAuditLogEntry(
	    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
	    	'Meter reading set {0} for reading {1}', 
	    	v_active_state,
	    	TO_CHAR(v_start_dtm,'dd Mon yyyy')
	    );
	ELSE
		csr_data_pkg.WriteAuditLogEntry(
	    	security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_METER_READING, security_pkg.GetAPP, v_region_sid, 
	    	'Meter reading set {0} for reading from {1} to {2}', 
	    	v_active_state,
	    	TO_CHAR(v_start_dtm,'dd Mon yyyy'),
	    	TO_CHAR(v_end_dtm,'dd Mon yyyy')
	    );
	END IF;
END;


PROCEDURE CreateFlowItemForReading (
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	out_flow_item_id		OUT	flow_item.flow_item_id%TYPE
)
AS
	v_flow_state_id			flow_state.flow_state_id%TYPE;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
BEGIN
	SELECT f.default_state_id
	  INTO v_flow_state_id
	  FROM flow f
	 WHERE f.flow_sid = in_flow_sid;
	
	INSERT INTO flow_item (flow_item_id, flow_sid, current_state_id)
	VALUES (flow_item_id_seq.NEXTVAL, in_flow_sid, v_flow_state_id)
		RETURNING flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := flow_pkg.AddToLog(in_flow_item_id => out_flow_item_id);
	
	UPDATE meter_reading
	   SET flow_item_id = out_flow_item_id
	 WHERE meter_reading_id = in_reading_id;
END;


FUNCTION INTERNAL_ReadingFromFlowItem(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE
) RETURN meter_reading.meter_reading_id%TYPE
AS 
	v_reading_id			meter_reading.meter_reading_id%TYPE;
BEGIN
	-- Fetch the meter reading id
	SELECT meter_reading_id
	  INTO v_reading_id
	  FROM meter_reading mr
	  JOIN all_meter am ON mr.app_sid = am.app_sid AND mr.region_sid = am.region_sid
	  JOIN meter_type mt ON am.app_sid = mt.app_sid AND am.meter_type_id = mt.meter_type_id
	 WHERE mt.flow_sid = in_flow_sid
	   AND mr.flow_item_id = in_flow_item_id;
	   
	RETURN v_reading_id;
END;

-- These can be called as helpers form the work-flow
PROCEDURE WF_ApproveReading(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_from_state_id		IN	flow_state.flow_state_id%TYPE,
	in_to_state_id			IN	flow_state.flow_state_id%TYPE,
	in_lookup_key			IN	flow_State_transition.lookup_key%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ApproveReading(INTERNAL_ReadingFromFlowItem(in_flow_sid, in_flow_item_id));
END;

PROCEDURE WF_MarkActive(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_from_state_id		IN	flow_state.flow_state_id%TYPE,
	in_to_state_id			IN	flow_state.flow_state_id%TYPE,
	in_lookup_key			IN	flow_State_transition.lookup_key%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
)
AS
	
BEGIN
	SetReadingActiveFlag(INTERNAL_ReadingFromFlowItem(in_flow_sid, in_flow_item_id), 1);
END;

PROCEDURE WF_MarkInactive(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_from_state_id		IN	flow_state.flow_state_id%TYPE,
	in_to_state_id			IN	flow_state.flow_state_id%TYPE,
	in_lookup_key			IN	flow_State_transition.lookup_key%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
)
AS
	
BEGIN
	SetReadingActiveFlag(INTERNAL_ReadingFromFlowItem(in_flow_sid, in_flow_item_id), 0);
END;

--TODO: Still we need to specify a flow_alert_class for meter workflow so this helper SP will be called
FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM v$meter_reading_all
	 WHERE app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id;
	
	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM v$meter_reading_all
	 WHERE app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id;
	   
	RETURN v_count;
END;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT y.app_sid, y.flow_state_transition_id, y.flow_item_generated_alert_id,
			   y.customer_alert_type_id, y.flow_state_log_id, y.from_state_label, y.to_state_label, 
			   y.set_by_user_sid, y.set_by_email, y.set_by_full_name, y.set_by_user_name,
			   y.to_user_sid, y.flow_item_Id,
			   y.flow_alert_helper, r.description meter_name, y.comment_text, y.to_initiator,
			INTERNAL_GetProperty(y.region_sid) property_name, y.start_dtm, y.end_dtm,
			mru.full_name entered_by_full_name, mru.email entered_by_email, y.val_number,
			y.cost, y.note, y.entered_dtm
		  FROM (
		  	SELECT x.app_sid, x.flow_state_transition_id, x.flow_item_generated_alert_id,
				   x.customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label, 
				   x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
				   x.to_user_sid, x.flow_item_Id,
				   x.flow_alert_helper,
				   mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, val_number, cost, note,
				   mr.entered_by_user_sid, mr.entered_dtm, mr.replaces_reading_id, mr.is_delete,
				   x.comment_text, x.to_initiator
			  FROM v$open_flow_item_gen_alert x
			  JOIN v$meter_reading_all mr ON x.flow_item_id = mr.flow_item_id AND x.app_sid = mr.app_sid
		  ) y
		  JOIN v$region r ON y.region_sid = r.region_sid AND y.app_sid = r.app_sid
		  JOIN csr_user mru ON mru.csr_user_sid = y.entered_by_user_sid AND mru.app_sid = y.app_sid
		 ORDER BY y.app_sid, y.customer_alert_type_id, y.to_user_sid, y.flow_item_id, LOWER(r.description), y.start_dtm -- Order matters!
		;
END;

PROCEDURE GetMeterInputs(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, its basically base data
	OPEN out_cur FOR
		SELECT meter_input_id, label, lookup_key, is_consumption_based, is_virtual
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY meter_input_id;
END;

PROCEDURE SaveMeterInput(
	in_meter_input_id				IN  meter_input.meter_input_id%TYPE,
	in_label						IN  meter_input.label%TYPE,
	in_lookup_key					IN  meter_input.lookup_key%TYPE,
	in_is_consumption_based			IN  meter_input.is_consumption_based%TYPE,
	in_aggregators					IN  security.security_pkg.T_VARCHAR2_ARRAY,
	out_meter_input_id				OUT meter_input.meter_input_id%TYPE
)
AS
	v_aggregators_tbl				security.T_VARCHAR2_TABLE;
	v_label_count					NUMBER(10);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter inputs');
	END IF;
	
	IF in_meter_input_id IS NULL THEN
		SELECT COUNT(*) INTO v_label_count 
		  FROM meter_input
		 WHERE lookup_key = in_lookup_key;
		   
		IF v_label_count > 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'lookup_key already in use: '||in_lookup_key);
		ELSE
			INSERT INTO meter_input (meter_input_id, label, lookup_key, is_consumption_based)
				VALUES (meter_input_id_seq.NEXTVAL, in_label, in_lookup_key, in_is_consumption_based)
			RETURNING meter_input_id INTO out_meter_input_id;
		END IF;
		  
	ELSE
		SELECT COUNT(*) INTO v_label_count 
		  FROM meter_input
		 WHERE lookup_key = in_lookup_key
		   AND meter_input_id != in_meter_input_id;
		
		IF v_label_count > 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'lookup_key already in use: '||in_lookup_key);
		ELSE
			UPDATE meter_input
			   SET label = in_label,
				   lookup_key = in_lookup_key,
				   is_consumption_based = in_is_consumption_based
			 WHERE meter_input_id = in_meter_input_id;
			 
			out_meter_input_id := in_meter_input_id;
		END IF;
	END IF;
	
	 IF in_aggregators IS NULL OR (in_aggregators.COUNT = 1 AND in_aggregators(1) IS NULL) THEN
		-- do nothing, should always have at least one aggregator, so don't clear down the table
        NULL;
    ELSE
		v_aggregators_tbl := security_pkg.Varchar2ArrayToTable(in_aggregators);
		
		DELETE FROM meter_input_aggregator
		      WHERE meter_input_id = out_meter_input_id
			    AND aggregator NOT IN (
					SELECT value FROM TABLE(v_aggregators_tbl)
				 );
				 
		INSERT INTO meter_input_aggregator (meter_input_id, aggregator)
		     SELECT out_meter_input_id, t.value
			   FROM TABLE(v_aggregators_tbl) t
			   LEFT JOIN meter_input_aggregator mia ON t.value = mia.aggregator AND mia.meter_input_id = out_meter_input_id
			  WHERE mia.aggregator IS NULL;			  
	END IF;	
END;

PROCEDURE DeleteMeterInput(
	in_meter_input_id				IN  meter_input.meter_input_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter inputs');
	END IF;

	DELETE FROM meter_input_aggr_ind
	 WHERE meter_input_id = in_meter_input_id;

	DELETE FROM meter_input_aggregator
	      WHERE meter_input_id = in_meter_input_id;
		  
	DELETE FROM meter_input
	      WHERE meter_input_id = in_meter_input_id;
END;

PROCEDURE SaveMeterInputAggregator(
	in_meter_input_id				IN  meter_input_aggregator.meter_input_id%TYPE,
	in_aggregator					IN  meter_input_aggregator.aggregator%TYPE,
	in_is_mandatory					IN  meter_input_aggregator.is_mandatory%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter inputs');
	END IF;
	
	BEGIN
		INSERT INTO meter_input_aggregator (meter_input_id, aggregator, is_mandatory)
		     VALUES (in_meter_input_id, in_aggregator, in_is_mandatory );
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE meter_input_aggregator
			   SET is_mandatory = in_is_mandatory
			 WHERE meter_input_id = in_meter_input_id
			   AND aggregator = in_aggregator
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE GetMeterInputAggregators(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, its basically base data
	OPEN out_cur FOR
		SELECT i.meter_input_id, i.aggregator, a.label, i.is_mandatory
		  FROM meter_input_aggregator i
		  JOIN meter_aggregator a ON a.aggregator = i.aggregator
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetMeterAggregators(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, its base data
	OPEN out_cur FOR
		SELECT a.label, a.aggregator
		  FROM meter_aggregator a;
END;

PROCEDURE GetMeterType(
	in_meter_type_id			meter_type.meter_type_id%TYPE,
	out_meter_type_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_meter_type_cur FOR
		SELECT DISTINCT -- Crunch up multiple matches on ES meter type mapping
			mi.meter_type_id, mi.label, mi.group_key, 
			pm.measure_sid primary_measure_sid, pm.description primary_measure_description,
			cm.measure_sid cost_measure_sid, cm.description cost_measure_description,
			DECODE(mtm.meter_type, NULL, 0, 1) is_est_compatible,
			mi.consumption_ind_sid, mi.cost_ind_sid, mi.days_ind_sid, mi.costdays_ind_sid,
			pi.description consumption_ind_description,
			ci.description cost_ind_description, di.description days_ind_description,
			cdi.description cost_days_ind_description,
			DECODE(pi.ind_activity_type_id, NULL, METER_IND_ACTIVITY_TYPE_NA, pi.ind_activity_type_id) activity_type,
			DECODE(pi.core, NULL, 0, pi.core) core
		  FROM v$meter_type mi
			LEFT JOIN v$ind pi ON mi.consumption_ind_sid = pi.ind_sid AND mi.app_sid = pi.app_sid
			LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
			LEFT JOIN v$ind ci ON mi.cost_ind_sid = ci.ind_sid AND mi.app_sid = ci.app_sid
			LEFT JOIN v$ind di ON mi.days_ind_sid = di.ind_sid AND mi.app_sid = di.app_sid
			LEFT JOIN v$ind cdi ON mi.costdays_ind_sid = cdi.ind_sid AND mi.app_sid = cdi.app_sid
			-- This is used to check for Energy Star comaptibility
			LEFT JOIN est_options op ON mi.app_sid = op.app_sid
			LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
			LEFT JOIN est_meter_type_mapping mtm ON mi.app_sid = mtm.app_sid AND mi.meter_type_id = mtm.meter_type_id AND mtm.est_account_sid = op.default_account_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND mi.meter_type_id = in_meter_type_id;
END;

PROCEDURE GetMeterTypes(
	out_meter_types_cur				OUT	SYS_REFCURSOR,
	out_meter_types_conv_cur		OUT	SYS_REFCURSOR,
	out_meter_type_input_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN

	-- XXX: Property module uses this:
	-- It needs the primary and cost ind information to ask the user to select the untis
	-- It's not possible to manage real-time meters in the property module at this time
	-- It's not possiblt to collect anything other than consumption and cost in a *normal* meter at this time
	-- So leave the procedure returning the primary/cost information only
	-- Later on, when it's supported for all meters, we'll need to return information for all available meter inputs
	OPEN out_meter_types_cur FOR
		SELECT DISTINCT -- Crunch up multiple matches on ES meter type mapping
			mi.meter_type_id, mi.label, mi.group_key, 
			pm.measure_sid primary_measure_sid, pm.description primary_measure_description,
			cm.measure_sid cost_measure_sid, cm.description cost_measure_description,
			DECODE(mtm.meter_type, NULL, 0, 1) is_est_compatible,
			mi.consumption_ind_sid, mi.cost_ind_sid, 
			mi.days_ind_sid, di.measure_sid days_measure_sid, di.description days_ind_description,
			mi.costdays_ind_sid, cdi.measure_sid costdays_measure_sid, cdi.description costdays_ind_description, 
			DECODE(pi.ind_activity_type_id, NULL, METER_IND_ACTIVITY_TYPE_NA, pi.ind_activity_type_id) activity_type,
			DECODE(pi.core, NULL, 0, pi.core) core
		  FROM v$meter_type mi
			LEFT JOIN v$ind pi ON mi.consumption_ind_sid = pi.ind_sid AND mi.app_sid = pi.app_sid
			LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
			LEFT JOIN v$ind ci ON mi.cost_ind_sid = ci.ind_sid AND mi.app_sid = ci.app_sid
			LEFT JOIN v$ind di ON mi.days_ind_sid = di.ind_sid AND mi.app_sid = di.app_sid
			LEFT JOIN v$ind cdi ON mi.costdays_ind_sid = cdi.ind_sid AND mi.app_sid = cdi.app_sid
			-- This is used to check for Energy Star comaptibility
			LEFT JOIN est_options op ON mi.app_sid = op.app_sid
			LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
			LEFT JOIN est_meter_type_mapping mtm ON mi.app_sid = mtm.app_sid AND mi.meter_type_id = mtm.meter_type_id AND mtm.est_account_sid = op.default_account_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY','APP')
		 ORDER BY mi.group_key, mi.label, pm.description;

	OPEN out_meter_types_conv_cur FOR
		SELECT meter_type_id, measure_sid, measure_conversion_id, description, is_conversion, is_est_compatible
		  FROM (
			SELECT
				mi.meter_type_id, i.measure_sid, mc.measure_conversion_id, mc.description,
				DECODE(mc.measure_conversion_id, NULL, 0, 1) is_conversion,
				DECODE(mcm.meter_type, NULL, 0, 1) is_est_compatible
			  FROM (
				SELECT app_sid, meter_type_id, days_ind_sid ind_sid
				  FROM meter_type
				 UNION
				SELECT app_sid, meter_type_id, costdays_ind_sid ind_sid
				  FROM meter_type
				 UNION
				SELECT app_sid, meter_type_id, ind_sid
				  FROM meter_type_input
			  ) mi
			  JOIN ind i ON mi.ind_sid = i.ind_sid AND mi.app_sid = i.app_sid
			  JOIN (
					-- Include dummy (null) conversion ber base measure
					SELECT app_sid, measure_sid, null measure_conversion_id, description
					  FROM measure
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					UNION
					SELECT app_sid, measure_sid, measure_conversion_id, description
					  FROM measure_conversion
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				) mc ON i.measure_sid = mc.measure_sid AND i.app_sid = mc.app_sid
			  -- This is used to check for Energy Star comaptibility
			  LEFT JOIN est_options op ON mi.app_sid = op.app_sid
			  LEFT JOIN est_meter_type_mapping mtm ON mi.app_sid = mtm.app_sid AND mi.meter_type_id = mtm.meter_type_id AND mtm.est_account_sid = op.default_account_sid
			  LEFT JOIN est_conv_mapping mcm ON mtm.app_sid = mcm.app_sid AND mtm.meter_type = mcm.meter_type 
			   AND i.measure_sid = mcm.measure_sid
			   AND NVL(mc.measure_conversion_id, -1) = NVL(mcm.measure_conversion_id, -1)
			   AND mcm.est_account_sid = op.default_account_sid
			   AND mtm.est_account_sid = mcm.est_account_sid
			   AND mtm.meter_type = mcm.meter_type
			 WHERE mi.app_sid = SYS_CONTEXT('SECURITY','APP')
		 )
		 GROUP BY meter_type_id, measure_sid, measure_conversion_id, description, is_conversion, is_est_compatible
		 ORDER BY measure_sid, is_conversion, description;
	
	OPEN out_meter_type_input_cur FOR
		SELECT mii.meter_type_id, mii.meter_input_id, mii.aggregator, mii.ind_sid, 
				mii.measure_sid, i.description ind_description, mi.is_virtual, mi.label, mi.lookup_key
		  FROM meter_type_input mii
		  JOIN meter_input mi ON mii.meter_input_id = mi.meter_input_id AND mii.app_sid = mi.app_sid
		  JOIN v$ind i ON mii.ind_sid = i.ind_sid AND mii.app_sid = i.app_sid;
END;

PROCEDURE SaveMeterType(
	in_meter_type_id				IN  meter_type.meter_type_id%TYPE,
	in_label						IN  meter_type.label%TYPE,
	in_group_key					IN  meter_type.group_key%TYPE,
	in_days_ind_sid					IN  meter_type.days_ind_sid%TYPE,
	in_costdays_ind_sid				IN  meter_type.costdays_ind_sid%TYPE,
	out_meter_type_id				OUT meter_type.meter_type_id%TYPE
)
AS
	v_measure_sid					security.security_pkg.T_SID_ID;
	v_days_ind_sid					security.security_pkg.T_SID_ID;
	v_costdays_ind_sid				security.security_pkg.T_SID_ID;
	v_batch_job_id					batch_job.batch_job_id%TYPE;
	v_meter_type_ids				security_pkg.T_SID_IDS;
	v_meter_input_ids				security_pkg.T_SID_IDS;
	v_aggregators					security_pkg.T_VARCHAR2_ARRAY;
	v_needs_recompute				NUMBER := 0;
	v_region_sids					security_pkg.T_SID_IDS;
	v_job_id						batch_job.batch_job_id%TYPE;				
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter types');
	END IF;
			
	IF in_meter_type_id IS NULL THEN
		INSERT INTO meter_type (meter_type_id, label, group_key, days_ind_sid, costdays_ind_sid)
		     VALUES (meter_type_id_seq.NEXTVAL, in_label, in_group_key, in_days_ind_sid, in_costdays_ind_sid)
		  RETURNING meter_type_id INTO out_meter_type_id;
	ELSE
		SELECT days_ind_sid, costdays_ind_sid
		  INTO v_days_ind_sid, v_costdays_ind_sid
		  FROM meter_type
		 WHERE meter_type_id = in_meter_type_id;
		 
		-- If days/costdays change, clear out all_meter measure conversion ids
		IF null_pkg.ne(in_days_ind_sid, v_days_ind_sid) THEN
			UPDATE all_meter
			   SET days_measure_conversion_id = NULL
			 WHERE meter_type_id = in_meter_type_id;
			 
			v_needs_recompute := 1;
		END IF;
		
		IF null_pkg.ne(in_costdays_ind_sid, v_costdays_ind_sid) THEN
			UPDATE all_meter
			   SET costdays_measure_conversion_id = NULL
			 WHERE meter_type_id = in_meter_type_id;
			 
			v_needs_recompute := 1;
		END IF;
	
		UPDATE meter_type
		   SET label = NVL(in_label, label),
			   group_key = in_group_key,
		       days_ind_sid = in_days_ind_sid,
		       costdays_ind_sid = in_costdays_ind_sid
		 WHERE meter_type_id = in_meter_type_id;
		
		out_meter_type_id := in_meter_type_id;
	END IF;	
	


	-- If inputs removed then create a job to delete from meter_input_aggr_ind etc.
	FOR r IN (
		SELECT ROWNUM rn, mti.meter_input_id, mti.aggregator
		  FROM meter_type_input mti
		  LEFT JOIN temp_meter_type_input tmti ON mti.meter_input_id = tmti.meter_input_id AND mti.aggregator = tmti.aggregator
		 WHERE tmti.meter_input_id IS NULL
		   AND meter_type_id = out_meter_type_id
	) LOOP

		v_meter_type_ids(r.rn) := out_meter_type_id;
		v_meter_input_ids(r.rn) := r.meter_input_id;
		v_aggregators(r.rn) := r.aggregator;

		DELETE FROM meter_input_aggr_ind
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND meter_type_id = out_meter_type_id
			AND meter_input_id = r.meter_input_id
			AND aggregator = r.aggregator;
		
		DELETE FROM meter_type_input
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND meter_type_id = out_meter_type_id
			AND meter_input_id = r.meter_input_id
			AND aggregator = r.aggregator;

	END LOOP;

	-- Add a job to deal with the potentially long running delete process.
	-- If the arrays are empty then this will not create a job.
	AddMeterTypeChangeBatchJob(v_meter_type_ids, v_meter_input_ids, v_aggregators, v_batch_job_id);

	FOR r IN (
		SELECT tmii.meter_input_id, tmii.aggregator, tmii.ind_sid, mi.is_virtual
		  FROM temp_meter_type_input tmii
		  JOIN meter_input mi ON tmii.meter_input_id = mi.meter_input_id
		  LEFT JOIN meter_type_input mii 
		    ON tmii.meter_input_id = mii.meter_input_id 
		   AND tmii.aggregator = mii.aggregator 
		   AND tmii.ind_sid = mii.ind_sid
		   AND mii.meter_type_id = out_meter_type_id
		 WHERE mii.meter_type_id IS NULL -- make sure stuff has actually changed
	) LOOP	
		SELECT measure_sid
		  INTO v_measure_sid
		  FROM ind
		 WHERE ind_sid = r.ind_sid;
	
		BEGIN
			INSERT INTO meter_type_input (meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid)
				 VALUES (out_meter_type_id, r.meter_input_id, r.aggregator, r.ind_sid, v_measure_sid);
				 
			-- If inputs added, add to meter_input_aggr_ind for all meters using that type
			INSERT INTO meter_input_aggr_ind (region_sid, meter_input_id, aggregator, measure_sid, meter_type_id)
			     SELECT am.region_sid, r.meter_input_id, r.aggregator, v_measure_sid, out_meter_type_id
				   FROM all_meter am
				  WHERE am.meter_type_id = out_meter_type_id;
			
			IF r.is_virtual = 1 THEN
				v_needs_recompute := 1;
			END IF;
		EXCEPTION
			WHEN dup_val_on_index THEN
				
				v_needs_recompute := 1;
				
				UPDATE meter_input_aggr_ind
				   SET measure_sid = NULL,
					   measure_conversion_id = NULL
				 WHERE meter_type_id = out_meter_type_id
				   AND meter_input_id = r.meter_input_id
				   AND aggregator = r.aggregator;
			
				UPDATE meter_type_input
				   SET ind_sid = r.ind_sid,
					   measure_sid = v_measure_sid
				 WHERE meter_type_id = out_meter_type_id
				   AND meter_input_id = r.meter_input_id
				   AND aggregator = r.aggregator;
				   
				UPDATE meter_input_aggr_ind
				   SET measure_sid = v_measure_sid
				 WHERE meter_type_id = out_meter_type_id
				   AND meter_input_id = r.meter_input_id
				   AND aggregator = r.aggregator;
		END;
	END LOOP;
			
	EmptyTempMeterTypeInput;
	
	IF v_needs_recompute = 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM all_meter 
		 WHERE meter_type_id = out_meter_type_id;
		 
		 AddRecomputeBatchJob(v_region_sids, v_job_id);
	END IF;
END;



PROCEDURE EmptyTempMeterTypeInput
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter types');
	END IF;
	
	DELETE FROM temp_meter_type_input;
END;

PROCEDURE AddTempMeterTypeInput(
	in_meter_input_id				IN  temp_meter_type_input.meter_input_id%TYPE,
	in_aggregator					IN  temp_meter_type_input.aggregator%TYPE,
	in_ind_sid						IN  temp_meter_type_input.ind_sid%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter types');
	END IF;
	
	INSERT INTO temp_meter_type_input (meter_input_id, aggregator, ind_sid)
		 VALUES (in_meter_input_id, in_aggregator, in_ind_sid);
END;

PROCEDURE DeleteMeterType(
	in_meter_type_id				IN  meter_type.meter_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit meter types');
	END IF;
	
	DELETE FROM meter_type_input
	      WHERE meter_type_id = in_meter_type_id;
	
	-- let it blow up if the type is in use in all_meter
	DELETE FROM meter_type
	      WHERE meter_type_id = in_meter_type_id;
END;

PROCEDURE GetMeteringOptions(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT analytics_months, analytics_current_month, meter_page_url, show_inherited_roles,
		       period_set_id, period_interval_id, show_invoice_reminder, invoice_reminder,
			   supplier_data_mandatory, region_date_clipping, fwd_estimate_meters, reference_mandatory,
			   realtime_metering_enabled, prevent_manual_future_readings,
			   proc_use_service, proc_api_base_uri, proc_local_path, proc_kick_timeout, proc_api_key
		  FROM metering_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SaveMeteringOptions(
	in_analytics_months				IN	metering_options.analytics_months%TYPE,
	in_analytics_current_month		IN	metering_options.analytics_current_month%TYPE,
	in_show_inherited_roles			IN	metering_options.show_inherited_roles%TYPE,
	in_reference_mandatory			IN	metering_options.reference_mandatory%TYPE,
	in_supplier_data_mandatory		IN	metering_options.supplier_data_mandatory%TYPE,
	in_show_invoice_reminder		IN	metering_options.show_invoice_reminder%TYPE,
	in_invoice_reminder				IN	metering_options.invoice_reminder%TYPE,
	in_prevent_manual_future_rdgs	IN	metering_options.prevent_manual_future_readings%TYPE,
	in_proc_use_service				IN	metering_options.proc_use_service%TYPE,
	in_proc_api_base_uri			IN	metering_options.proc_api_base_uri%TYPE,
	in_proc_local_path				IN	metering_options.proc_local_path%TYPE,
	in_proc_kick_timeout			IN	metering_options.proc_kick_timeout%TYPE,
	in_proc_api_key					IN	metering_options.proc_api_key%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit metering options');
	END IF;
	
	BEGIN
		INSERT INTO metering_options (analytics_months, analytics_current_month, show_inherited_roles,
						reference_mandatory, supplier_data_mandatory, show_invoice_reminder,
						invoice_reminder, period_set_id, period_interval_id, prevent_manual_future_readings,
						proc_use_service, proc_api_base_uri, proc_local_path, proc_kick_timeout, proc_api_key)
		VALUES (in_analytics_months, in_analytics_current_month, in_show_inherited_roles,
			 		in_reference_mandatory, in_supplier_data_mandatory, in_show_invoice_reminder,
					in_invoice_reminder, 1, 1, in_prevent_manual_future_rdgs,
					in_proc_use_service, in_proc_api_base_uri, in_proc_local_path, in_proc_kick_timeout, in_proc_api_key);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE metering_options
			   SET analytics_months = in_analytics_months,
				   analytics_current_month = in_analytics_current_month,
				   show_inherited_roles = in_show_inherited_roles,
				   reference_mandatory = in_reference_mandatory,
				   supplier_data_mandatory = in_supplier_data_mandatory,
				   show_invoice_reminder = in_show_invoice_reminder,
				   invoice_reminder = in_invoice_reminder,
				   prevent_manual_future_readings = in_prevent_manual_future_rdgs,
				   proc_use_service = in_proc_use_service,
				   proc_api_base_uri = in_proc_api_base_uri,
				   proc_local_path = in_proc_local_path,
				   proc_kick_timeout = in_proc_kick_timeout,
				   proc_api_key = in_proc_api_key
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

FUNCTION GetMeterPageUrl (
	in_app_sid						security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
RETURN VARCHAR2
AS
	v_meter_page_url				metering_options.meter_page_url%TYPE;
BEGIN
	BEGIN
		SELECT meter_page_url
		  INTO v_meter_page_url
		  FROM metering_options
		 WHERE app_sid = in_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_meter_page_url := '/csr/site/meter/meter.acds';
	END;
	
	RETURN v_meter_page_url;
END;

PROCEDURE LegacyCreateMeter(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_description				IN	region_description.description%TYPE,
	in_reference				IN	all_meter.reference%TYPE DEFAULT NULL,
	in_note						IN	all_meter.note%TYPE	DEFAULT NULL,
	in_source_type_id			IN  all_meter.meter_source_type_id%TYPE DEFAULT 2, -- arbitrary period
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_consump_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_cost_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_region_type				IN	region.region_type%TYPE DEFAULT csr_data_pkg.REGION_TYPE_METER,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	out_region_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_contract_ids				security_pkg.T_SID_IDS;
	v_duplicates				NUMBER;
	v_count						NUMBER := 1;
	v_name						region.name%TYPE;
BEGIN

	v_name := REPLACE(in_description,'/','\');
	
	--ensure that the name is unique
	SELECT COUNT(*) INTO v_duplicates
	  FROM csr.region
	 WHERE parent_sid = in_parent_sid
	   AND LOWER(name) = LOWER(v_name);
	
	WHILE v_duplicates > 0 LOOP
		v_count := v_count + 1;
		v_name := REPLACE(in_description,'/','\') || ' ' || v_count;

		SELECT COUNT(*) INTO v_duplicates
		  FROM csr.region
		 WHERE parent_sid = in_parent_sid
		   AND LOWER(name) = LOWER(v_name);
	END LOOP;

	-- create region will do our permission checks
	region_pkg.CreateRegion(
		in_parent_sid	=> in_parent_sid,
		in_name			=> v_name,
		in_description	=> in_description,
		in_region_type	=> in_region_type,
		out_region_sid	=> out_region_sid
	);

	-- Make the new region into a meter
	LegacyMakeMeter(
		in_act_id					=> SYS_CONTEXT('SECURITY','ACT'),
		in_region_sid				=> out_region_sid,
		in_meter_type_id			=> in_meter_type_id,
		in_note						=> in_note,
		in_primary_conversion_id	=> in_consump_conversion_id,
		in_cost_conversion_id		=> in_cost_conversion_id,
		in_source_type_id			=> in_source_type_id,
		in_manual_data_entry		=> in_manual_data_entry,
		in_reference				=> in_reference,
		in_contract_ids				=> v_contract_ids,
		in_active_contract_id		=> null,
		in_urjanet_meter_id			=> in_urjanet_meter_id
	);

	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(out_region_sid);
END;

PROCEDURE CreateMeter(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_description				IN	region_description.description%TYPE,
	in_reference				IN	all_meter.reference%TYPE DEFAULT NULL,
	in_note						IN	all_meter.note%TYPE	DEFAULT NULL,
	in_source_type_id			IN  all_meter.meter_source_type_id%TYPE DEFAULT 2, -- arbitrary period
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_region_type				IN	region.region_type%TYPE DEFAULT csr_data_pkg.REGION_TYPE_METER,
	in_region_ref				IN	region.region_ref%TYPE DEFAULT NULL,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	out_region_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_contract_ids				security_pkg.T_SID_IDS;
BEGIN
	-- create region will do our permission checks
	region_pkg.CreateRegion(
		in_parent_sid	=> in_parent_sid,
		in_name			=> REPLACE(in_description,'/','\'), --'
		in_description	=> in_description,
		in_region_type	=> in_region_type,
		in_region_ref	=> in_region_ref,
		out_region_sid	=> out_region_sid
	);

	-- Make the new region into a meter
	MakeMeter(
		in_act_id					=> SYS_CONTEXT('SECURITY','ACT'),
		in_region_sid				=> out_region_sid,
		in_meter_type_id			=> in_meter_type_id,
		in_note						=> in_note,
		in_source_type_id			=> in_source_type_id,
		in_manual_data_entry		=> in_manual_data_entry,
		in_reference				=> in_reference,
		in_contract_ids				=> v_contract_ids,
		in_active_contract_id		=> null,
		in_urjanet_meter_id			=> in_urjanet_meter_id
	);

	-- Create eneergy star job if required
	energy_star_job_pkg.OnRegionChange(out_region_sid);
END;

-- URJANET PROCEDURES

PROCEDURE CreateOrFindMeter(
	in_raw_data_id			IN 	NUMBER,
	in_name					IN	VARCHAR2,
	in_region_ref			IN	VARCHAR2,
	in_urjanet_meter_id		IN	VARCHAR2,
	in_service_type			IN	VARCHAR2,
	in_meter_number			IN	VARCHAR2,
	out_exists				OUT	NUMBER
)	
AS
	v_source_type_id		meter_source_type.meter_source_type_id%TYPE;
	v_region_ref			region.region_ref%TYPE;
	v_service_type			urjanet_service_type.service_type%TYPE;
	v_reference				all_meter.reference%TYPE;
	v_meter_type_id			meter_type.meter_type_id%TYPE;
	v_region_sid			security_pkg.T_SID_ID;
	v_meter_sid				security_pkg.T_SID_ID;
	v_error_id				meter_raw_data_error.error_id%TYPE;
BEGIN
	out_exists:= 0; 
	
	-- Pick the "urjanet kludge" data source if it exists
	-- and if the raw data is tied to an urjanet auto import class
	SELECT MIN(mst.meter_source_type_id)
	  INTO v_source_type_id
	  FROM meter_source_type mst
	  JOIN meter_raw_data mrd ON mrd.app_sid = mst.app_sid
	  JOIN meter_raw_data_source mrds ON mrds.app_sid = mrd.app_sid AND mrds.raw_data_source_id = mrd.raw_data_source_id
	  JOIN automated_import_class aic ON aic.app_sid = mrds.app_sid AND aic.automated_import_class_sid = mrds.automated_import_class_sid
	 WHERE mst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mst.arbitrary_period = 1
	   AND mst.allow_null_start_dtm = 1
	   AND mrd.meter_raw_data_id = in_raw_data_id
	   AND aic.lookup_key = 'URJANET_IMPORTER';

	IF v_source_type_id IS NULL THEN
		-- ...if not then try the normal data source
		SELECT MIN(mst.meter_source_type_id)
		  INTO v_source_type_id
		  FROM meter_source_type mst
		 WHERE arbitrary_period = 1;
		-- If still not foind then error
		IF v_source_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(ERR_METER_TYPE_NOT_CONFIGURED, 'An arbitrary period source type is missing for this site.');
		END IF;
	END IF;

	-- No point continuing if the service type isn't configured. Issues have already been created for these.
	BEGIN
		SELECT meter_type_id
		  INTO v_meter_type_id
		  FROM urjanet_service_type us
		  JOIN meter_raw_data mrd ON mrd.raw_data_source_id = us.raw_data_source_id
		 WHERE LOWER(service_type) = LOWER(in_service_type)
		   AND mrd.meter_raw_data_id = in_raw_data_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			meter_duff_region_pkg.MarkDuffRegion(
				in_urjanet_meter_id 			=> in_urjanet_meter_id,
				in_meter_name 					=> in_name,
				in_meter_number 				=> in_meter_number,
				in_region_ref 					=> in_region_ref,
				in_service_type					=> in_service_type,
				in_meter_raw_data_id 			=> in_raw_data_id,
				in_message						=> 'Service type ''' || in_service_type || ''' cannot be found',
				in_error_type_id				=> meter_duff_region_pkg.DUFF_METER_SVC_TYPE_NOT_FOUND
			);

			RETURN;
	END;
	
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM all_meter
		 WHERE LOWER(urjanet_meter_id) = LOWER(in_urjanet_meter_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			BEGIN
				SELECT m.region_sid
				  INTO v_region_sid
				  FROM all_meter m 
				  JOIN v$region mr ON mr.region_sid = m.region_sid
				  JOIN v$region p ON mr.parent_sid = p.region_sid
			 LEFT JOIN meter_type mi ON mi.meter_type_id = m.meter_type_id
			 LEFT JOIN urjanet_service_type us ON us.meter_type_id = mi.meter_type_id
				  JOIN meter_raw_data mrd ON mrd.raw_data_source_id = us.raw_data_source_id AND mrd.meter_raw_data_id =  in_raw_data_id
				 WHERE in_meter_number IS NOT NULL
				   AND in_service_type IS NOT NULL 	   
				   AND ((in_region_ref IS NOT NULL
				   AND p.region_ref IS NOT NULL
				   AND LOWER(p.region_ref) = LOWER(in_region_ref))
					OR p.region_ref IS NULL
					OR in_region_ref IS NULL)
				   AND LOWER(in_meter_number) = LOWER(m.reference)
				   AND LOWER(us.service_type) = LOWER(in_service_type);
				   
				UPDATE all_meter
				   SET urjanet_meter_id = in_urjanet_meter_id
				 WHERE region_sid = v_region_sid;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
	END;
	
	IF v_region_sid IS NULL THEN 
		BEGIN
			BEGIN
				SELECT region_sid
				  INTO v_region_sid
				  FROM region
				 WHERE LOWER(region_ref) = LOWER(in_region_ref)
				   AND region_type = csr_data_pkg.REGION_TYPE_PROPERTY;
			EXCEPTION
				WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
					BEGIN
						SELECT holding_region_sid 
						  INTO v_region_sid
						  FROM csr.meter_raw_data_source mrds
						  JOIN meter_raw_data mrd ON mrd.raw_data_source_id = mrds.raw_data_source_id
						 WHERE mrd.meter_raw_data_id = in_raw_data_id;
						IF v_region_sid IS NULL THEN
							BEGIN
								SELECT region_sid
								  INTO v_region_sid
								  FROM region
								 WHERE UPPER(lookup_key) = 'HOLDING';
							EXCEPTION
								WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
									meter_duff_region_pkg.MarkDuffRegion(
										in_urjanet_meter_id 			=> in_urjanet_meter_id,
										in_meter_name 					=> in_name,
										in_meter_number 				=> in_meter_number,
										in_region_ref 					=> in_region_ref,
										in_service_type					=> in_service_type,
										in_meter_raw_data_id 			=> in_raw_data_id,
										in_message						=> 'Holding region cannot be not found',
										in_error_type_id				=> meter_duff_region_pkg.DUFF_METER_HOLDING_NOT_FOUND
									);

									RETURN;
							END;
						END IF;
					END;
			END;		
			
			BEGIN			
				CreateMeter(
					in_parent_sid			=>	v_region_sid,
					in_meter_type_id		=>	v_meter_type_id,
					in_description			=>	in_name,
					in_reference 			=>	in_meter_number,
					in_source_type_id		=>	v_source_type_id,
					in_manual_data_entry	=> 0,
					in_region_type			=>	csr_data_pkg.REGION_TYPE_REALTIME_METER,
					in_region_ref			=>	in_region_ref,
					in_urjanet_meter_id		=>	in_urjanet_meter_id,
					out_region_sid			=>	v_meter_sid
				);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					-- the name we have generated is not unique to this parent region, 
					-- the only unique thing left is the urjanet ID, so stick it in the
					-- name
					CreateMeter(
						in_parent_sid			=>	v_region_sid,
						in_meter_type_id		=>	v_meter_type_id,
						in_description			=>	in_name||' - '||in_urjanet_meter_id,
						in_reference 			=>	in_meter_number,
						in_source_type_id		=>	v_source_type_id,
						in_manual_data_entry	=> 0,
						in_region_type			=>	csr_data_pkg.REGION_TYPE_REALTIME_METER,
						in_region_ref			=>	in_region_ref,
						in_urjanet_meter_id		=>	in_urjanet_meter_id,
						out_region_sid			=>	v_meter_sid
					);
			END;
			out_exists := 1;
		END;
	ELSE
		-- The meter might be in the trash
		IF trash_pkg.IsInTrash(security_pkg.GetACT, v_region_sid) != 0 THEN
			meter_duff_region_pkg.LogErrorAndMarkDuffRegion(
				in_meter_raw_data_id 		=> in_raw_data_id,
				in_region_sid				=> v_region_sid,
				in_message					=> 'Meter region with Urjanet meter id ' || in_urjanet_meter_id || ' and region sid ' || v_region_sid || ' is in the trash. ',
				in_detail					=> 'Meter region with Urjanet meter id ' || in_urjanet_meter_id || ' and region sid ' || v_region_sid || ' is in the trash. ',
				in_urjanet_meter_id 		=> in_urjanet_meter_id,
				in_meter_name 				=> in_name,
				in_meter_number 			=> in_meter_number,
				in_region_ref 				=> in_region_ref,
				in_service_type				=> in_service_type,
				in_error_type_id			=> meter_duff_region_pkg.DUFF_METER_GENERIC
			);

			RETURN;

		END IF;

		BEGIN
			 SELECT p.region_ref, us.service_type, m.reference, m.region_sid 
			   INTO v_region_ref, v_service_type, v_reference, v_region_sid
			   FROM all_meter m 
			   JOIN v$region mr ON mr.region_sid= m.region_sid
			   JOIN v$region p ON mr.parent_sid = p.region_sid
		  LEFT JOIN meter_type mi ON mi.meter_type_id = m.meter_type_id
		  LEFT JOIN (
			  SELECT ust.*
				FROM urjanet_service_type ust
				JOIN meter_raw_data mrd ON mrd.raw_data_source_id = ust.raw_data_source_id AND mrd.meter_raw_data_id = in_raw_data_id
			  ) us ON us.meter_type_id = mi.meter_type_id AND LOWER(us.service_type) = LOWER(in_service_type)
			  WHERE LOWER(m.urjanet_meter_id) = LOWER(in_urjanet_meter_id);
		   
			IF in_region_ref IS NOT NULL AND LOWER(v_region_ref) != LOWER(in_region_ref) THEN 
				meter_duff_region_pkg.LogErrorAndMarkDuffRegion(
					in_meter_raw_data_id 		=> in_raw_data_id,
					in_region_sid				=> v_region_sid,
					in_message					=> 'Region reference mismatch between Urjanet meter id ' || in_urjanet_meter_id || ' and region ' || v_region_sid || '. ',
					in_detail					=> 'Region ref found: ' || v_region_ref || CHR(13) ||' Region ref provided: ' || in_region_ref,
					in_urjanet_meter_id 		=> in_urjanet_meter_id,
					in_meter_name 				=> in_name,
					in_meter_number 			=> in_meter_number,
					in_region_ref 				=> in_region_ref,
					in_service_type				=> in_service_type,
					in_error_type_id			=> meter_duff_region_pkg.DUFF_METER_EXISTING_MISMATCH
				);

				RETURN;
			END IF;

			IF v_service_type IS NULL THEN 
				SELECT STRAGG(us.service_type)
			      INTO v_service_type
			      FROM all_meter m 
				  LEFT JOIN meter_type mi ON mi.meter_type_id = m.meter_type_id
				  LEFT JOIN urjanet_service_type us ON us.meter_type_id = mi.meter_type_id
					  JOIN meter_raw_data mrd ON mrd.raw_data_source_id = us.raw_data_source_id AND mrd.meter_raw_data_id = in_raw_data_id
			     WHERE LOWER(m.urjanet_meter_id) = LOWER(in_urjanet_meter_id);
			
				meter_duff_region_pkg.LogErrorAndMarkDuffRegion(
					in_meter_raw_data_id 		=> in_raw_data_id,
					in_region_sid				=> v_region_sid,
					in_message					=> 'Service type mismatch between Urjanet meter id ' || in_urjanet_meter_id || ' and region ' || v_region_sid || '. ',
					in_detail					=> 'Service type(s) found: ' || v_service_type || CHR(13) || ' Service type provided: ' || in_service_type,
					in_urjanet_meter_id 		=> in_urjanet_meter_id,
					in_meter_name 				=> in_name,
					in_meter_number 			=> in_meter_number,
					in_region_ref 				=> in_region_ref,
					in_service_type				=> in_service_type,
					in_error_type_id			=> meter_duff_region_pkg.DUFF_METER_SVC_TYPE_MISMATCH
				);

				RETURN;
			END IF;
			
			IF in_meter_number IS NOT NULL AND LOWER(v_reference) != LOWER(in_meter_number) THEN 
				meter_duff_region_pkg.LogErrorAndMarkDuffRegion(
					in_meter_raw_data_id 		=> in_raw_data_id,
					in_region_sid				=> v_region_sid,
					in_message					=> 'Meter number mismatch between Urjanet meter id ' || in_urjanet_meter_id || ' and region ' || v_region_sid || '. ',
					in_detail					=> 'Meter number found: ' || v_reference || CHR(13) || ' Meter number provided: ' || in_meter_number,
					in_urjanet_meter_id 		=> in_urjanet_meter_id,
					in_meter_name 				=> in_name,
					in_meter_number 			=> in_meter_number,
					in_region_ref 				=> in_region_ref,
					in_service_type				=> in_service_type,
					in_error_type_id			=> meter_duff_region_pkg.DUFF_METER_EXISTING_MISMATCH
				);

				RETURN;
			END IF;
			
			out_exists :=1;
		END;
	END IF;


END;

PROCEDURE CheckServiceTypeExists(
	in_raw_data_id			IN 	NUMBER,
	in_service_type			IN	VARCHAR2
)	
AS
	v_meter_type_id			meter_type.meter_type_id%TYPE;
	v_issue_id				issue.issue_id%TYPE;
BEGIN
	BEGIN
		SELECT meter_type_id
		  INTO v_meter_type_id
		  FROM urjanet_service_type us
		  JOIN meter_raw_data mrd ON mrd.raw_data_source_id = us.raw_data_source_id
		 WHERE LOWER(service_type) = LOWER(in_service_type)
		   AND mrd.meter_raw_data_id = in_raw_data_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			meter_monitor_pkg.AddUniqueRawDataIssue (
				in_raw_data_id		=> in_raw_data_id,
				in_region_sid		=> NULL,
				in_label			=> 'Service Type ' || in_service_type || ' hasn''t been configured in the system.',
				in_description		=> 'Service Type ' || in_service_type || ' hasn''t been configured in the system.',
				out_issue_id		=> v_issue_id
			);
	END;	
END;

FUNCTION IsExternalMeterCreationEnabled 
RETURN NUMBER
AS
	v_count							NUMBER;
BEGIN
	-- no security required
	SELECT COUNT(*)
	  INTO v_count
	  FROM meter_raw_data_source
	 WHERE create_meters = 1;
	 
	IF v_count > 0 THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

PROCEDURE GetUrjanetServiceTypes(
	in_raw_data_source_id			IN	urjanet_service_type.raw_data_source_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- base data, no security check required
	OPEN out_cur FOR
		SELECT service_type, meter_type_id
		  FROM urjanet_service_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = in_raw_data_source_id;
END; 

PROCEDURE SaveUrjanetServiceType(
	in_service_type					IN	urjanet_service_type.service_type%TYPE,
	in_meter_type_id				IN	urjanet_service_type.meter_type_id%TYPE,
	in_raw_data_source_id			IN	urjanet_service_type.raw_data_source_id%TYPE
)
AS
	v_raw_data_source_id			urjanet_service_type.raw_data_source_id%TYPE := in_raw_data_source_id;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit service types');
	END IF;
	
	BEGIN
		INSERT INTO urjanet_service_type (service_type, meter_type_id, raw_data_source_id)
			 VALUES (in_service_type, in_meter_type_id, in_raw_data_source_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE urjanet_service_type
			   SET meter_type_id = in_meter_type_id
			 WHERE service_type = in_service_type
			   AND raw_data_source_id = in_raw_data_source_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;


PROCEDURE ClearUrjanetServiceTypes (
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE
)
AS 
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit service types');
	END IF;

	DELETE FROM urjanet_service_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_raw_data_source_id;
END;

PROCEDURE GetMeterDataImporterOptions (
	in_automated_import_class_sid	IN	auto_imp_importer_settings.automated_import_class_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit urjanet options');
	END IF;

	OPEN out_cur FOR
		SELECT aiis.auto_imp_importer_settings_id, aiis.mapping_xml, aiis.automated_import_file_type_id, aiis.automated_import_class_sid,
			   aiis.dsv_separator, NVL(aiis.dsv_quotes_as_literals, 0) dsv_quotes_as_literals, NVL(aiis.excel_worksheet_index, 0) excel_worksheet_index,
			   NVL(aiis.excel_row_index, 0)  excel_row_index, NVL(aiis.all_or_nothing, 0) all_or_nothing, mrds.raw_data_source_id
		  FROM auto_imp_importer_settings aiis
		  JOIN meter_raw_data_source mrds ON mrds.automated_import_class_sid = aiis.automated_import_class_sid
		 WHERE aiis.automated_import_class_sid = in_automated_import_class_sid;
END;

PROCEDURE GetUrjanetOptions (
	in_automated_import_class_sid	IN	auto_imp_importer_settings.automated_import_class_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_automated_import_class_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit urjanet options');
	END IF;
	
	v_automated_import_class_sid := in_automated_import_class_sid;
	IF v_automated_import_class_sid IS NULL THEN
		SELECT automated_import_class_sid
		  INTO v_automated_import_class_sid
		  FROM automated_import_class
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'URJANET_IMPORTER';
	END IF;

	OPEN out_cur FOR
		SELECT aiis.mapping_xml, aiis.automated_import_class_sid
		  FROM auto_imp_importer_settings aiis
		 WHERE aiis.automated_import_class_sid = v_automated_import_class_sid;
END;

PROCEDURE UrjanetEnabled(
	out_enabled						OUT	NUMBER
)
AS
	v_automated_import_class_sid	security_pkg.T_SID_ID;
BEGIN
	out_enabled := 1;
	BEGIN
		SELECT automated_import_class_sid
		  INTO v_automated_import_class_sid
		  FROM automated_import_class
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'URJANET_IMPORTER';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_enabled := 0;
	END;
END;

-- END OF URJANET PROCEDURES

PROCEDURE AddRecomputeBatchJob(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
)
AS
	v_region_sids					security_pkg.T_SID_IDS;
BEGIN
	v_region_sids(1) := in_region_sid;
	AddRecomputeBatchJob(v_region_sids, out_job_id);
END;

PROCEDURE AddRecomputeBatchJob(
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	IF in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(in_region_sids.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays
		RETURN; -- Nothig to do, no job created
    END IF;

	-- Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_METER_RECOMPUTE,
		in_description => 'Recompute meter data',
		out_batch_job_id => out_job_id
	);
	
	-- Fill in the job regions
	FOR i IN in_region_sids.FIRST .. in_region_sids.LAST
	LOOP
		IF in_region_sids.EXISTS(i) THEN
			BEGIN
				INSERT INTO meter_recompute_batch_job (batch_job_id, region_sid)
				VALUES(out_job_id, in_region_sids(i));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore
			END;
		END IF;
	END LOOP;
END;

PROCEDURE ProcessRecomputeBatchJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
)
AS
	v_count							NUMBER;
	v_i								NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM meter_recompute_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;

	-- Recompute each meter region
	FOR r IN (
		SELECT region_sid
		  FROM meter_recompute_batch_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND batch_job_id = in_batch_job_id
	) LOOP
		-- Progress
		batch_job_pkg.SetProgress(in_batch_job_id, v_i, v_count);
		INTERNAL_RecomputeValueData(r.region_sid);
		v_i := v_i + 1;
	END LOOP;

	-- Clean up
	DELETE FROM meter_recompute_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;

	-- Complete
	batch_job_pkg.SetProgress(in_batch_job_id, v_count, v_count);
	out_result_desc := 'Meter data recomputed successfully';
	out_result_url := NULL;
END;

PROCEDURE AddMeterTypeChangeBatchJob (
	in_meter_type_id				IN	meter_type_input.meter_type_id%TYPE,
	in_meter_input_id				IN	meter_type_input.meter_input_id%TYPE,
	in_aggregator					IN	meter_type_input.aggregator%TYPE,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
)
AS
	v_meter_type_ids				security_pkg.T_SID_IDS;
	v_meter_input_ids				security_pkg.T_SID_IDS;
	v_aggregators					security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	v_meter_type_ids(1) := in_meter_type_id;
	v_meter_input_ids(1) := in_meter_input_id;
	v_aggregators(1) := in_aggregator;

	AddMeterTypeChangeBatchJob(v_meter_type_ids, v_meter_input_ids, v_aggregators, out_job_id);
END;

PROCEDURE AddMeterTypeChangeBatchJob(
	in_meter_type_ids				IN	security_pkg.T_SID_IDS,
	in_meter_input_ids				IN	security_pkg.T_SID_IDS,
	in_aggregators					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	IF in_meter_type_ids.COUNT = 0 OR (in_meter_type_ids.COUNT = 1 AND in_meter_type_ids(in_meter_type_ids.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays
		RETURN; -- Nothig to do, no job created
    END IF;

	-- Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_METER_TYPE_CHANGE,
		in_description => 'Process meter type change',
		out_batch_job_id => out_job_id
	);
	
	-- Fill in the job details
	FOR i IN in_meter_type_ids.FIRST .. in_meter_type_ids.LAST
	LOOP
		IF in_meter_type_ids.EXISTS(i) THEN
			BEGIN
				INSERT INTO meter_type_change_batch_job (meter_type_id, meter_input_id, aggregator, batch_job_id)
				VALUES (in_meter_type_ids(i), in_meter_input_ids(i), in_aggregators(i), out_job_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore
			END;
		END IF;
	END LOOP;
END;

PROCEDURE ProcessMeterTypeChangeBatchJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
)
AS
	v_count							NUMBER;
	v_i								NUMBER := 0;
BEGIN
	-- Update this too
	SELECT COUNT(*)
	  INTO v_count
	  FROM meter_type_change_batch_job j
	  JOIN all_meter m ON j.app_sid = m.app_sid AND j.meter_type_id = m.meter_type_id
	 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND j.batch_job_id = in_batch_job_id
	   AND NOT EXISTS ( -- Ensure the input is "still deleted" by the time the job runs
	   		SELECT 1
	   		  FROM meter_type_input mti
	   		 WHERE mti.app_sid = j.app_sid
	   		   AND mti.meter_type_id = j.meter_type_id
	   		   AND mti.meter_input_id = j.meter_input_id
	   		   AND mti.aggregator = j.aggregator
	  );

	-- Progress
	batch_job_pkg.SetProgress(in_batch_job_id, 0, v_count);

	-- Recompute each meter region and clean-up meter data
	FOR r IN (
		SELECT j.meter_type_id, j.meter_input_id, j.aggregator, m.region_sid
		  FROM meter_type_change_batch_job j
		  JOIN all_meter m ON j.app_sid = m.app_sid AND j.meter_type_id = m.meter_type_id
		 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND j.batch_job_id = in_batch_job_id
		   AND NOT EXISTS ( -- Ensure the input is "still deleted" by the time the job runs
		   		SELECT 1
		   		  FROM meter_type_input mti
		   		 WHERE mti.app_sid = j.app_sid
		   		   AND mti.meter_type_id = j.meter_type_id
		   		   AND mti.meter_input_id = j.meter_input_id
		   		   AND mti.aggregator = j.aggregator
		  )
	) LOOP
		-- Clean-up meter data
		DELETE FROM meter_live_data
		 WHERE (app_sid, region_sid, meter_input_id, aggregator) IN (
			SELECT app_sid, region_sid, meter_input_id, aggregator
			  FROM meter_input_aggr_ind
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND meter_type_id = r.meter_type_id
			   AND meter_input_id = r.meter_input_id
			   AND aggregator = r.aggregator
		  );

		-- Recompute meter's indicator data
		INTERNAL_RecomputeValueData(r.region_sid);
		
		-- Progress
		v_i := v_i + 1;
		batch_job_pkg.SetProgress(in_batch_job_id, v_i, v_count);
	END LOOP;

	-- Clean up
	DELETE FROM meter_type_change_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;

	-- Complete
	batch_job_pkg.SetProgress(in_batch_job_id, v_count, v_count);
	out_result_desc := 'Meter data recomputed successfully';
	out_result_url := NULL;
END;

PROCEDURE IndMeasureSidChanged(
	in_ind_sid						IN  security_pkg.T_SID_ID,
	in_measure_sid					IN  security_pkg.T_SID_ID
)
AS
	v_new_measure_desc				measure.description%TYPE;
	v_region_sids					security_pkg.T_SID_IDS;
	v_measure_sids					security_pkg.T_SID_IDS;
	v_measure_descs					security_pkg.T_VARCHAR2_ARRAY;
	v_input_descs					security_pkg.T_VARCHAR2_ARRAY;
	v_aggr_descs					security_pkg.T_VARCHAR2_ARRAY;
	v_job_id						batch_job.batch_job_id%TYPE;
BEGIN
	BEGIN
		SELECT NVL(description, name)
		  INTO v_new_measure_desc
		  FROM measure
		 WHERE measure_sid = in_measure_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_new_measure_desc := NULL;
	END;


	SELECT region_sid, input_label, aggr_label, measure_sid, measure_desc
	  BULK COLLECT INTO v_region_sids, v_input_descs, v_aggr_descs, v_measure_sids, v_measure_descs
	  FROM (
	  	-- Meter inputs
		SELECT mia.region_sid, mi.label input_label, agg.label aggr_label, mia.measure_sid, NVL(m.description, m.name) measure_desc
		  FROM meter_input_aggr_ind mia
		  JOIN meter_input mi ON mia.app_sid = mi.app_sid AND mia.meter_input_id = mi.meter_input_id
		  JOIN meter_aggregator agg ON mia.aggregator = agg.aggregator 
		  LEFT JOIN measure m ON mia.app_sid = m.app_sid AND mia.measure_sid = m.measure_sid
		 WHERE (mia.meter_type_id, mia.meter_input_id, mia.aggregator) IN (
				SELECT meter_type_id, meter_input_id, aggregator
				  FROM meter_type_input
				 WHERE ind_sid = in_ind_sid
			)
		UNION
		-- Days
		SELECT am.region_sid, 'Days (fixed)' input_label, 'n/a' aggr_label, m.measure_sid, NVL(m.description, m.name) measure_desc
		  FROM meter_type mt
		  JOIN ind i ON mt.app_sid = i.app_sid AND mt.days_ind_sid = i.ind_sid
		  JOIN all_meter am ON mt.app_sid = am.app_sid AND mt.meter_type_id = am.meter_type_id
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		 WHERE mt.days_ind_sid = in_ind_sid
		UNION
		-- Costdays
		SELECT am.region_sid, 'Costdays (fixed)' input_label, 'n/a' aggr_label, m.measure_sid, NVL(m.description, m.name) measure_desc
		  FROM meter_type mt
		  JOIN ind i ON mt.app_sid = i.app_sid AND mt.costdays_ind_sid = i.ind_sid
		  JOIN all_meter am ON mt.app_sid = am.app_sid AND mt.meter_type_id = am.meter_type_id
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		 WHERE mt.costdays_ind_sid = in_ind_sid
	);

	-- Meter inputs
	UPDATE meter_type_input
	   SET measure_sid = in_measure_sid
	 WHERE ind_sid = in_ind_sid;
	 
	UPDATE meter_input_aggr_ind
	   SET measure_sid = in_measure_sid,
	       measure_conversion_id = NULL
	 WHERE (meter_type_id, meter_input_id, aggregator) IN (
			SELECT meter_type_id, meter_input_id, aggregator
			  FROM meter_type_input
			 WHERE ind_sid = in_ind_sid
		);

	-- Days
	UPDATE all_meter
	   SET days_measure_conversion_id = NULL
	 WHERE meter_type_id IN (
	 	SELECT meter_type_id
	 	  FROM meter_type
	 	 WHERE days_ind_sid = in_ind_sid
	 );

	-- Costdays
	UPDATE all_meter
	   SET costdays_measure_conversion_id = NULL
	 WHERE meter_type_id IN (
	 	SELECT meter_type_id
	 	  FROM meter_type
	 	 WHERE costdays_ind_sid = in_ind_sid
	 );

	IF v_region_sids IS NOT NULL AND v_region_sids.COUNT > 0 THEN
		FOR i IN v_region_sids.FIRST .. v_region_sids.LAST
		LOOP
			IF v_region_sids.EXISTS(i) THEN
				csr_data_pkg.AuditValueDescChange(security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, v_region_sids(i), 
					'Meter''s measure (via indicator change) for input '''||v_input_descs(i)||''' and aggregator '''||v_aggr_descs(i)||'''', 
					v_measure_sids(i), in_measure_sid, v_measure_descs(i), v_new_measure_desc);
			END IF;
		END LOOP;

		AddRecomputeBatchJob(v_region_sids, v_job_id);
	END IF;

END;

-- Meter tab procedures
PROCEDURE GetMeterTabs(
	in_meter_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_is_super_admin				NUMBER := csr_user_pkg.IsSuperAdmin;
BEGIN
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, mt.tab_label, mt.pos,
			   p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, p.use_reporting_period, 
			   p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid
		  FROM plugin p
		  JOIN meter_tab mt ON p.plugin_id = mt.plugin_id
		  JOIN meter_tab_group mtg ON mt.plugin_id = mtg.plugin_id
		  LEFT JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y
		    ON mtg.group_sid = y.column_value
		  LEFT JOIN region_role_member rrm 
		    ON rrm.region_sid = in_meter_sid AND rrm.role_sid = mtg.role_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		 WHERE in_meter_sid IS NULL
		    OR v_is_super_admin = 1
		    OR (mtg.group_sid IS NOT NULL AND y.column_value IS NOT NULL)
		    OR (mtg.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL)
		 GROUP BY p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, mt.tab_label, mt.pos,
			   p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, 
			   p.use_reporting_period, p.saved_filter_sid, p.result_mode, p.form_sid, p.pre_filter_sid
		 ORDER BY mt.pos;
END;

PROCEDURE SaveMeterTab (
	in_plugin_id					IN  meter_tab.plugin_id%TYPE,
	in_tab_label					IN  meter_tab.tab_label%TYPE,
	in_pos							IN  meter_tab.pos%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS	
	v_pos 							meter_tab.pos%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update meter tabs.');
	END IF;
	
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM meter_tab;
	END IF;
	 
	BEGIN
		INSERT INTO meter_tab (plugin_type_id, plugin_id, pos, tab_label)
			VALUES (csr_data_pkg.PLUGIN_TYPE_METER_TAB, in_plugin_id, v_pos, in_tab_label);
			
		-- default access
		INSERT INTO csr.meter_tab_group (plugin_id, group_sid)
		     VALUES (in_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE meter_tab
			   SET tab_label = in_tab_label,
				   pos = v_pos
			 WHERE plugin_id = in_plugin_id;
	END;
		 
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
		       p.details, p.preview_image_path, mt.pos, mt.tab_label
		  FROM plugin p
		  JOIN meter_tab mt ON p.plugin_id = mt.plugin_id
		 WHERE mt.plugin_id = in_plugin_id;

END;

PROCEDURE RemoveMeterTab(
	in_plugin_id					IN  meter_tab.plugin_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify meter plugins');
	END IF;
	
	DELETE FROM meter_tab_group
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;
	   
	DELETE FROM meter_tab
	 WHERE plugin_id = in_plugin_id
	   AND app_sid = security_pkg.GetApp;
END;
-- End of meter tab procedures

-- Meter header element procedures
PROCEDURE GetMeterHeaderElements (
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no permission checks, its just layout config
	OPEN out_cur FOR
		SELECT mhe.app_sid, mhe.meter_header_element_id, mhe.pos, mhe.col, mhe.meter_header_core_element_id,
		       mhe.ind_sid, i.description, mhe.tag_group_id, tg.name tag_group_name, rm.show_measure
		  FROM meter_header_element mhe
		  LEFT JOIN v$ind i ON mhe.ind_sid = i.ind_sid
		  LEFT JOIN region_metric rm ON mhe.ind_sid = rm.ind_sid
		  LEFT JOIN v$tag_group tg ON mhe.tag_group_id = tg.tag_group_id;
END;

PROCEDURE SaveMeterHeaderElement (
	in_meter_header_element_id		IN	meter_header_element.meter_header_element_id%TYPE,
	in_pos							IN	meter_header_element.pos%TYPE,
	in_col							IN	meter_header_element.col%TYPE,
	in_ind_sid						IN  meter_header_element.ind_sid%TYPE,
	in_tag_group_id					IN  meter_header_element.tag_group_id%TYPE,
	in_meter_header_core_el_id		IN  meter_header_element.meter_header_core_element_id%TYPE,
	in_show_measure					IN  region_metric.show_measure%TYPE,
	out_meter_header_element_id		OUT	meter_header_element.meter_header_element_id%TYPE
)
AS
	v_count							NUMBER;
BEGIN	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit meter elements.');
	END IF;
	
	IF in_ind_sid IS NOT NULL THEN
		-- make ind a metric if it isn't already
		SELECT COUNT(*)
		  INTO v_count
		  FROM region_metric
		 WHERE ind_sid = in_ind_sid;
		 
		IF v_count = 0 THEN
			region_metric_pkg.SetMetric(in_ind_sid);
		END IF;

		BEGIN
			INSERT INTO region_type_metric (region_type, ind_sid)
				 VALUES (csr_data_pkg.REGION_TYPE_METER, in_ind_sid);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
		
		UPDATE region_metric
		   SET show_measure = in_show_measure
		 WHERE ind_sid = in_ind_sid;
	END IF;

	--Changed to upsert means if someone tries to add a new item with same name will update the other but ListControl doesn't tell you if it is a edit save or a new save.
	IF in_meter_header_element_id IS NULL THEN
		INSERT INTO meter_header_element (meter_header_element_id, pos, col, ind_sid, tag_group_id, meter_header_core_element_id)
		VALUES (meter_header_element_id_seq.nextval, in_pos, in_col, in_ind_sid, in_tag_group_id, in_meter_header_core_el_id)
		RETURNING meter_header_element_id INTO out_meter_header_element_id;
	ELSE
		UPDATE meter_header_element
		   SET pos = in_pos,
		       col = in_col
		 WHERE meter_header_element_id = in_meter_header_element_id;
		
		out_meter_header_element_id := in_meter_header_element_id;
	END IF;
END;

PROCEDURE DeleteMeterHeaderElement (
	in_meter_header_element_id		IN	meter_header_element.meter_header_element_id%TYPE
)
AS
	v_ind_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit meter elements.');
	END IF;

	SELECT ind_sid
	  INTO v_ind_sid
	  FROM meter_header_element
	 WHERE meter_header_element_id = in_meter_header_element_id;

	DELETE FROM meter_header_element
	 WHERE meter_header_element_id = in_meter_header_element_id
	   AND app_sid = security.security_pkg.GetApp;
	   
	IF v_ind_sid IS NOT NULL THEN
		-- clean up any region type metrics that are no longer in use
		DELETE FROM region_type_metric
			  WHERE region_type = csr_data_pkg.REGION_TYPE_METER
				AND ind_sid NOT IN (
					SELECT ind_sid 
					  FROM meter_element_layout
					 WHERE ind_sid IS NOT NULL
					 UNION 
					SELECT ind_sid 
					  FROM meter_header_element
					 WHERE ind_sid IS NOT NULL
				);
	END IF;
END;

-- End of meter header element procedures

-- Meter photo procedures
PROCEDURE AddMeterPhoto (
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_cache_key					IN	aspen2.filecache.cache_key%TYPE,
	out_meter_photo_id				OUT	meter_photo.meter_photo_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the meter with sid '||in_region_sid);
	END IF;
	
	out_meter_photo_id := meter_photo_id_seq.nextval;
	
	INSERT INTO meter_photo (meter_photo_id, region_sid, filename, mime_type, data) 
	SELECT out_meter_photo_id, in_region_sid, f.filename, f.mime_type, f.object
	  FROM aspen2.filecache f
	 WHERE f.cache_key = in_cache_key;
END;

PROCEDURE DeleteMeterPhoto (
	in_meter_photo_id				IN	meter_photo.meter_photo_id%TYPE
)
AS
	v_region_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM meter_photo
	 WHERE meter_photo_id = in_meter_photo_id;
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the meter with sid '||v_region_sid);
	END IF;
	
	DELETE FROM meter_photo
	 WHERE meter_photo_id = in_meter_photo_id;
END;

PROCEDURE GetMeterPhoto (
	in_meter_photo_id				IN	meter_photo.meter_photo_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_region_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM meter_photo
	 WHERE meter_photo_id = in_meter_photo_id;
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to the meter with sid '||v_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT meter_photo_id, region_sid, filename, mime_type, data
		  FROM meter_photo
		 WHERE meter_photo_id = in_meter_photo_id;
END;
-- End of meter photo procedures

PROCEDURE GetIssues(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the meter with sid '||in_region_sid);
	END IF;	

	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.description, i.due_dtm, i.raised_dtm, i.resolved_dtm, i.manual_completion_dtm,
			   i.region_sid, i.region_name,
			   i.assigned_to_role_sid, i.assigned_to_role_name,
			   i.assigned_to_user_sid, i.assigned_to_full_name,
			   i.raised_by_user_sid, 
			   i.raised_full_name raised_by_full_name, -- ugh
			   i.closed_dtm,
			   i.issue_type_id, i.label issue_type_label, i.status, i.is_closed, 
			   i.is_resolved, i.is_rejected, i.is_overdue, i.is_critical
		  FROM v$issue i
		 WHERE i.region_sid = in_region_sid;
END;

PROCEDURE AddIssue(
	in_region_sid 		IN 	security_pkg.T_SID_ID,
	in_label			IN	issue.label%TYPE,
	in_description		IN	issue_log.message%TYPE,
	in_due_dtm			IN	issue.due_dtm%TYPE,
	in_is_urgent		IN	NUMBER,
	in_is_critical		IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id		OUT issue.issue_id%TYPE
)
AS
	v_issue_log_id		issue_log.issue_log_id%TYPE;
BEGIN
	issue_pkg.CreateIssue(
		in_label					=> in_label,
		in_description				=> in_description,
		in_source_label				=> null,
		in_issue_type_id			=> csr_data_pkg.ISSUE_METER,
		in_correspondent_id			=> null,
		in_raised_by_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_role_sid		=> null,
		in_priority_id				=> null,
		in_due_dtm					=> in_due_dtm,
		in_region_sid				=> in_region_sid,
		in_is_urgent				=> in_is_urgent,
		in_is_critical				=> in_is_critical,
		out_issue_id				=> out_issue_id
	);
	
	INSERT INTO issue_meter (
		app_sid, issue_meter_id, region_sid, issue_dtm)
	VALUES (
		security_pkg.GetAPP, issue_meter_id_seq.NEXTVAL, in_region_sid, in_due_dtm
	);

	UPDATE csr.issue
	   SET issue_meter_id = issue_meter_id_seq.CURRVAL
	 WHERE issue_id = out_issue_id;
END;

PROCEDURE GetRawMeterData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_from_row				IN	NUMBER,
	in_to_row				IN	NUMBER,
	in_from_dtm				IN	DATE,
	in_to_dtm				IN	DATE,
	in_filter				IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_filter				VARCHAR2(1024);
BEGIN
	-- Excape filter string
	v_filter := utils_pkg.RegexpEscape(in_filter);
	
	-- Replace any number of white spaces with \s+
	v_filter := REGEXP_REPLACE(v_filter, '\s+', '\s+');

	OPEN out_cur FOR
		SELECT MAX(total_rows) OVER () total_rows,
			region_sid, start_dtm, end_dtm, val, uom,
			meter_input_id, meter_input_label,
			priority, priority_label,
			meter_raw_data_id, data_source,
			entered_dtm, statement_id
		  FROM (
		  	-- Place-holder for extra total rows row - "trick" to use a reader to 
		  	-- get the count out of the first row, the rest of the data we're 
		  	-- actually exporint being on subsequent rows. The paged grid will 
		  	-- never see rn = 0, the extra row is not included in the total count.
		  	-- The export method can fetch the extra row by specifying a from row of -1
		  	SELECT 0 rn, NULL total_rows, 
            	NULL region_sid, NULL start_dtm, NULL end_dtm, NULL val, NULL uom, 
            	NULL meter_input_id, NULL meter_input_label, 
            	NULL priority, NULL priority_label, 
            	NULL meter_raw_data_id, NULL data_source, 
            	NULL entered_dtm, NULL statement_id
		  	  FROM DUAL
		  	UNION ALL
			SELECT ROWNUM rn, COUNT(*) OVER() total_rows, x.*
			  FROM (
				SELECT 
					x.region_sid, x.start_dtm, x.end_dtm, x.val, 
					NVL(x.uom, NVL(mc.description, m.description)) uom, 
					x.meter_input_id, i.label meter_input_label,
					x.priority, p.label priority_label,
					x.meter_raw_data_id, x.data_source,
					x.entered_dtm, x.statement_id
				FROM (
					SELECT
						CAST (d.start_dtm AS DATE) start_dtm, CAST (d.end_dtm AS DATE) end_dtm, 
						d.region_sid, d.raw_consumption val, d.raw_uom uom,
						d.meter_input_id, d.priority, d.meter_raw_data_id,
						DECODE(d.meter_raw_data_id, NULL, 'Manual import', 'Data feed') data_source,
						mrd.received_dtm entered_dtm, statement_id
					  FROM meter_source_data d
					  LEFT JOIN meter_raw_data mrd on d.meter_raw_data_id = mrd.meter_raw_data_id
					 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND d.region_sid = in_region_sid
					   AND NOT EXISTS (
						SELECT 1
						  FROM meter_reading_data rd
						 WHERE rd.region_sid = d.region_sid
						   AND rd.meter_input_id = d.meter_input_id
						   AND rd.priority = d.priority
						   AND reading_dtm = d.start_dtm
						)
					UNION ALL
					SELECT 
						CAST (d.reading_dtm AS DATE) start_dtm, NULL end_dtm, 
						d.region_sid, d.raw_val, d.raw_uom uom,
						d.meter_input_id, d.priority, d.meter_raw_data_id,
						DECODE(d.meter_raw_data_id, NULL, 'Manual import', 'Data feed') data_source,
						NULL entered_dtm, NULL statement_id
					  FROM meter_reading_data d
					 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND d.region_sid = in_region_sid
					UNION ALL
					SELECT
						d.start_dtm, d.end_dtm,
						d.region_sid, d.consumption val, NULL uom,
						d.meter_input_id, d.priority, NULL meter_raw_data_id,
						'Patch' data_source, d.updated_dtm entered_dtm, NULL statement_id
					  FROM meter_patch_data d
					 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND d.region_sid = in_region_sid
					UNION ALL
					SELECT
						d.start_dtm, d.end_dtm,
						d.region_sid, d.val_number val, NULL uom,
						i.meter_input_id, p.priority, NULL meter_raw_data_id,
						'User reading' data_source, d.entered_dtm, NULL statement_id
					  FROM v$meter_reading d
					  JOIN meter_input_aggr_ind ai ON ai.app_sid = d.app_sid AND ai.region_sid = d.region_sid
					  JOIN meter_input i ON i.app_sid = ai.app_sid AND i.meter_input_id = ai.meter_input_id AND i.lookup_key = 'CONSUMPTION'
					  JOIN meter_data_priority p ON p.app_sid = ai.app_sid AND p.lookup_key = 'LO_RES'
					 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND d.region_sid = in_region_sid
					UNION ALL
					SELECT
						d.start_dtm, d.end_dtm,
						d.region_sid, d.cost val, NULL uom,
						i.meter_input_id, p.priority, NULL meter_raw_data_id,
						'User reading' data_source, d.entered_dtm, NULL statement_id
					  FROM v$meter_reading d
					  JOIN meter_input_aggr_ind ai ON ai.app_sid = d.app_sid AND ai.region_sid = d.region_sid
					  JOIN meter_input i ON i.app_sid = ai.app_sid AND i.meter_input_id = ai.meter_input_id AND i.lookup_key = 'COST'
					  JOIN meter_data_priority p ON p.app_sid = ai.app_sid AND p.lookup_key = 'LO_RES'
					 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND d.region_sid = in_region_sid
					) x
					  JOIN meter_input i ON i.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND i.meter_input_id = x.meter_input_id
					  JOIN meter_data_priority p ON p.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND p.priority = x.priority
					  LEFT JOIN meter_input_aggr_ind ai ON ai.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ai.region_sid = x.region_sid 
					   AND i.meter_input_id = ai.meter_input_id AND ai.aggregator = 'SUM'
					  LEFT JOIN measure m ON m.app_sid = ai.app_sid AND m.measure_sid = ai.measure_sid
					  LEFT JOIN measure_conversion mc ON mc.app_sid = ai.app_sid AND mc.measure_sid = ai.measure_sid AND mc.measure_conversion_id = ai.measure_conversion_id
					-- Filtering
					 WHERE start_dtm <= NVL(in_to_dtm, start_dtm)
					   AND NVL(end_dtm, start_dtm) >= NVL(in_from_dtm, NVL(end_dtm, start_dtm))
					   AND (in_filter IS NULL 
						OR REGEXP_LIKE(NVL(x.uom, NVL(mc.description, m.description)), v_filter, 'i')
						OR REGEXP_LIKE(i.label, v_filter, 'i')
						OR REGEXP_LIKE(p.label, v_filter, 'i')
						OR REGEXP_LIKE(x.data_source, v_filter, 'i')
						OR REGEXP_LIKE(x.statement_id, v_filter, 'i')
					  )
					ORDER BY x.start_dtm DESC, x.end_dtm DESC, LOWER(i.label), priority desc
				) x
			) x
		 -- Page
		 WHERE x.rn > in_from_row
		   AND x.rn <= in_to_row
		;
END;

PROCEDURE GetRawMeterDataForExport (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_from_dtm				IN	DATE,
	in_to_dtm				IN	DATE,
	in_filter				IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetRawMeterData(
		in_region_sid,
		-1, 			-- Fetch the extra row containing just the total row count
		1048576,		-- Excel row limit
		in_from_dtm,
		in_to_dtm,
		in_filter,
		out_cur
	);
END;

PROCEDURE GetMeterReadingListForTab(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_start_row            IN NUMBER,
    in_end_row              IN NUMBER,
    out_cur                 OUT SYS_REFCURSOR
) 
AS
BEGIN
	GetMeterReadingListForTab(
	    in_region_sid			=> in_region_sid,
	    in_start_row			=> in_start_row,
	    in_end_row				=> in_end_row,
	    in_include_auto_src		=> 1,
	    out_cur					=> out_cur
	); 
END;

PROCEDURE GetMeterReadingListForTab(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_start_row            IN NUMBER,
    in_end_row              IN NUMBER,
    in_include_auto_src		IN NUMBER, -- as far as I can tell, we only ever call this with 1
    out_cur                 OUT SYS_REFCURSOR
) 
AS
	v_manual_entry			all_meter.manual_data_entry%TYPE;
	v_arbitrary_period		meter_source_type.arbitrary_period%TYPE;
	v_descending			meter_source_type.descending%TYPE;
	v_offset_months         NUMBER;
	v_year_offset			NUMBER;
	v_urjanet_meter_id		all_meter.urjanet_meter_id%TYPE;
	v_format_mask			ind.format_mask%TYPE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading meter sid '||in_region_sid);
	END IF;
	
	-- tolerance_type : 0 = none, 1 = last period, 2 = last year
	v_year_offset := -12;
	SELECT CASE WHEN i.tolerance_type = 1 THEN -1 WHEN i.tolerance_type = 2 THEN v_year_offset ELSE 0 END,
		   NVL(i.format_mask, m.format_mask)
	  INTO v_offset_months, v_format_mask
	  FROM v$legacy_meter am
	  JOIN ind i ON i.ind_sid = am.primary_ind_sid
	  JOIN measure m ON i.measure_sid = m.measure_sid
	 WHERE am.region_sid = in_region_sid;
	
	SELECT 
		DECODE(m.urjanet_meter_id, NULL, m.manual_data_entry, 1) manual_data_entry,	-- So the readings show up in the reading tab
		DECODE(m.urjanet_meter_id, NULL, t.arbitrary_period, 1) arbitrary_period,	-- Always arbitrary period if urjanet (for now at least)
		DECODE(m.urjanet_meter_id, NULL, descending, 0) descending,					-- Urjanet never descending
		m.urjanet_meter_id
	  INTO v_manual_entry, v_arbitrary_period, v_descending, v_urjanet_meter_id
	  FROM all_meter m, meter_source_type t
	 WHERE m.region_sid = in_region_sid
	   AND t.meter_source_type_id = m.meter_source_type_id;
	
	IF v_manual_entry = 0 OR (in_include_auto_src = 0 AND v_urjanet_meter_id IS NOT NULL) THEN
		-- We don't want to show the data in this case, return a cursor with correct columns but no rows
		OPEN out_cur FOR
			SELECT NULL meter_reading_id, NULL reading_dtm, NULL val, 
				NULL avg_consumpation, NULL note, NULL entered_by_user_sid, NULL entered_dtm, 
				NULL total_rows, NULL user_name,
				NULL reference, NULL cost, NULL pct_change, NULL is_estimate, NULL format_mask
			  FROM DUAL
			 WHERE 1 = 2;
		RETURN;
	END IF;
	
	IF v_urjanet_meter_id IS NULL THEN
		IF v_arbitrary_period = 0 THEN
			IF v_offset_months != v_year_offset THEN
				-- point in time meter, previous reading for comparison, legacy meter
				OPEN out_cur FOR
					SELECT rn, meter_reading_id, reading_dtm, val, total_val, avg_consumption,
						note, entered_by_user_sid, entered_dtm, is_estimate, format_mask, total_rows, user_name, reference, cost, is_reset,
						DECODE (is_reset, 0, NULL, val) reset_val, baseline_val, total_val,
						LAG(baseline_val) OVER (ORDER BY reading_dtm) prev_baseline_val,
						CASE WHEN avg_consumption = 0 OR LAG(avg_consumption) OVER (ORDER BY reading_dtm) = 0 THEN null ELSE
							ROUND((avg_consumption - LAG(avg_consumption) OVER (ORDER BY reading_dtm)) * 100 / LAG(avg_consumption) OVER (ORDER BY reading_dtm), 2)
						END pct_change, consumption consumption,
						d.meter_document_id doc_id, d.mime_type doc_mime_type, d.file_name doc_file_name
					  FROM meter_document d, (
						SELECT rn, meter_reading_id, reading_dtm, val_number val, baseline_val, val_number + NVL(baseline_val, 0) total_val,
							CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
							note, entered_by_user_sid, entered_dtm, total_rows, full_name user_name,
							reference, cost, DECODE(baseline_val, last_baseline_val, 0, 1) is_reset,
							meter_document_id, consumption, is_estimate, format_mask
						  FROM ( 
						  SELECT x.*, ROWNUM rn
							FROM (
								SELECT meter_reading_id, start_dtm reading_dtm, val_number, NVL(baseline_val, 0) baseline_val,
									(val_number + NVL(baseline_val, 0) - LAG(val_number) OVER (order by start_dtm) - NVL(LAG(baseline_val) OVER (order by start_dtm), 0)) * DECODE(v_descending, 0, 1, -1) consumption, -- difference between values
									TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
									note, entered_by_user_sid, entered_dtm, is_estimate, v_format_mask format_mask, full_name, COUNT(*) OVER () AS total_rows, reference, cost,
									NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0) last_baseline_val,
									meter_document_id
								 FROM meter_reading mr, csr_user cu
								WHERE region_sid = in_region_sid
								  AND csr_user_sid = entered_by_user_sid
								  AND mr.active = 1
								  AND mr.req_approval = 0
								ORDER BY start_dtm DESC
							 ) x 
							 WHERE ROWNUM <= in_end_row
						 ) 
						 WHERE rn > in_start_row
					) x 
					WHERE d.meter_document_id(+) = x.meter_document_id
						ORDER BY reading_dtm DESC;
			ELSE
				-- point in time meter, last years reading for comparison, legacy meter
				OPEN out_cur FOR
					SELECT 	r2.rn, r.meter_reading_id, r2.reading_dtm reading_dtm, r.val_number val, r2.total_val, r2.avg_consumption, r.note, 
							r.entered_by_user_sid, r.entered_dtm, r.is_estimate, v_format_mask format_mask, r2.total_rows, cu.user_name, r.reference, r.cost, is_reset,
							DECODE (is_reset, 0, NULL, val) reset_val, 
							r2.baseline_val, 
							LAG(r2.baseline_val) OVER (ORDER BY r2.reading_dtm) prev_baseline_val,
							CASE WHEN r2.avg_consumption = 0 OR r2.prev_avg = 0 THEN null
								 ELSE ROUND(((r2.avg_consumption - r2.prev_avg) * 100) / r2.prev_avg , 2)
							END pct_change,
							r2.consumption consumption,
							d.meter_document_id doc_id, d.mime_type doc_mime_type, d.file_name doc_file_name
					  FROM meter_reading r
					  JOIN csr_user cu ON cu.csr_user_sid = r.entered_by_user_sid
					  LEFT JOIN meter_document d ON d.meter_document_id = r.meter_document_id
					  JOIN (
							SELECT  rn, meter_reading_id, reading_dtm, val_number val, baseline_val, 
									val_number + NVL(baseline_val, 0) total_val,
									CASE WHEN day_interval > 0 THEN ROUND(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
									DECODE(baseline_val, last_baseline_val, 0, 1) is_reset,
									consumption, offset_consumption, offset_day_interval,
									CASE WHEN offset_day_interval > 0 THEN ROUND(offset_consumption / offset_day_interval, 2) ELSE 0 END AS prev_avg,
									total_rows
							  FROM ( 
								  SELECT ROWNUM rn, meter_reading_id, reading_dtm, val_number, baseline_val, consumption, day_interval, last_baseline_val, 
										 offset_consumption, offset_day_interval, total_rows
									FROM (
										SELECT  meter_reading_id, reading_dtm, val_number, baseline_val,
												(val_number + baseline_val - LAG(val_number) OVER (ORDER BY reading_dtm) - LAG(baseline_val) OVER (ORDER BY reading_dtm)) * DECODE(v_descending, 0, 1, -1) consumption,
												TRUNC(reading_dtm,'dd') - trunc(LAG(reading_dtm, 1, reading_dtm) OVER (ORDER BY reading_dtm), 'dd') AS day_interval,
												NVL(LAG(baseline_val) OVER (ORDER BY reading_dtm), 0) last_baseline_val,
												SUM(NVL(offset_consumption, 0)) offset_consumption,
												SUM(offset_day_interval) offset_day_interval,
												COUNT(*) OVER () AS total_rows
										  FROM (
											  SELECT  r1.meter_reading_id meter_reading_id, r1.start_dtm reading_dtm, r1.val_number val_number, 
													  NVL(r1.baseline_val, 0) baseline_val,
													  omr.offset_consumption, omr.offset_day_interval
												FROM meter_reading r1
												LEFT JOIN (
													 SELECT region_sid, start_dtm offset_reading_dtm,
															(val_number + NVL(baseline_val, 0) - LAG(val_number) OVER (ORDER BY start_dtm) - NVL(LAG(baseline_val) OVER (ORDER BY start_dtm), 0)) * DECODE(v_descending, 0, 1, -1) offset_consumption, 
															TRUNC(start_dtm,'dd') - TRUNC(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS offset_day_interval
													   FROM meter_reading
													  WHERE region_sid = in_region_sid
														AND val_number IS NOT NULL 
														AND active = 1
														AND req_approval = 0
												) omr ON omr.region_sid = r1.region_sid 
													 AND omr.offset_reading_dtm = ADD_MONTHS(r1.start_dtm, v_offset_months)
											   WHERE r1.region_sid = in_region_sid
											     AND r1.active = 1
											     AND r1.req_approval = 0
											  ) s1
										 GROUP BY meter_reading_id, reading_dtm, baseline_val, val_number
										 ORDER BY reading_dtm DESC
									) s2
							 )  s3
					  ) r2 ON r2.meter_reading_id = r.meter_reading_id AND r2.rn > in_start_row AND r2.rn <= in_end_row
					 WHERE r.region_sid = in_region_sid
					   AND r.active = 1
					   AND r.req_approval = 0
					 ORDER BY r.start_dtm DESC;	
			END IF;
		ELSIF v_offset_months = v_year_offset THEN
			-- arbitrary period meter reading, last years reading for comparison, legacy meter
			OPEN out_cur FOR	
				SELECT  r2.rn, r.meter_reading_id, r.note, r.entered_by_user_sid, r.is_estimate, v_format_mask format_mask, r2.avg_consumption, 
						CASE WHEN r2.avg_consumption = 0 OR r2.prev_avg = 0 THEN NULL
							 ELSE ROUND(((r2.avg_consumption - r2.prev_avg) * 100) / r2.prev_avg , 2)
						END pct_change,
						r.entered_dtm, cu.user_name, r.reference, r.cost, r2.total_rows, r.start_dtm, r.end_dtm, r.val_number consumption,
						d.meter_document_id doc_id, d.mime_type doc_mime_type, d.file_name doc_file_name
				  FROM meter_reading r
				  JOIN csr_user cu ON cu.csr_user_sid = r.entered_by_user_sid
				  LEFT JOIN meter_document d ON d.meter_document_id = r.meter_document_id
				  JOIN (
						SELECT ROWNUM rn, meter_reading_id,
								CASE WHEN offset_day_interval > 0 THEN ROUND(offset_consumption / offset_day_interval, 2) ELSE 0 END AS prev_avg,
								CASE WHEN (TRUNC(end_dtm, 'dd') - TRUNC(start_dtm, 'dd')) > 0 THEN ROUND(consumption / (TRUNC(end_dtm, 'dd') - TRUNC(start_dtm, 'dd')), 2) ELSE 0 END AS avg_consumption,
								total_rows
						  FROM (
								SELECT  r1.meter_reading_id meter_reading_id,
										SUM(omr.val_number) offset_consumption, 
										TRUNC(MAX(omr.end_dtm), 'dd') - TRUNC(MIN(omr.start_dtm), 'dd') offset_day_interval, 
										r1.end_dtm end_dtm, r1.start_dtm start_dtm, r1.val_number consumption,
										COUNT(*) OVER () AS total_rows
								  FROM meter_reading r1
								  LEFT JOIN (
											 SELECT region_sid, end_dtm, start_dtm, val_number
											   FROM meter_reading
											  WHERE region_sid = in_region_sid
												AND val_number IS NOT NULL 
												AND active = 1
												AND req_approval = 0
								 ) omr ON omr.region_sid = r1.region_sid
									  AND omr.end_dtm > ADD_MONTHS(r1.start_dtm, v_offset_months)
									  AND omr.start_dtm < ADD_MONTHS(r1.end_dtm, v_offset_months)           
								 WHERE r1.region_sid = in_region_sid
								   AND r1.active = 1
								   AND r1.req_approval = 0
								 GROUP BY r1.meter_reading_id, r1.start_dtm, r1.end_dtm, r1.val_number
								 ORDER BY r1.start_dtm DESC
							 ) 
					 ) r2 ON r2.meter_reading_id = r.meter_reading_id 
						 AND r2.rn > in_start_row 
						 AND r2.rn <= in_end_row
				 WHERE r.region_sid = in_region_sid
				   AND r.active = 1
				   AND r.req_approval = 0
				 ORDER BY r.start_dtm DESC;
		ELSE
			-- arbitrary period meter reading, previous reading for comparison, legacy meters only, legacy meter
			OPEN out_cur FOR
				SELECT rn, meter_reading_id, note, entered_by_user_sid, is_estimate, format_mask, avg_consumption, 
					  CASE WHEN LAG(avg_consumption) OVER (ORDER BY start_dtm) = 0 THEN null ELSE
							ROUND((avg_consumption - LAG(avg_consumption) OVER (ORDER BY start_dtm)) * 100 / LAG(avg_consumption) OVER (ORDER BY start_dtm), 2)
					  END pct_change,
					  entered_dtm, user_name, reference, cost, total_rows, start_dtm, end_dtm, consumption,
					  d.meter_document_id doc_id, d.mime_type doc_mime_type, d.file_name doc_file_name
				  FROM meter_document d, (
						SELECT ROWNUM rn, meter_reading_id, note, entered_by_user_sid, 
						  entered_dtm, is_estimate, format_mask, full_name user_name, reference, cost, total_rows,
						  start_dtm, end_dtm, consumption, meter_document_id,
						  CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption
					 FROM (
					   SELECT r.meter_reading_id, r.note, r.entered_by_user_sid, 
						  r.entered_dtm, cu.full_name, r.reference, r.cost,
						  r.start_dtm, r.end_dtm, r.is_estimate, v_format_mask format_mask, -- we could look up the format mask from the indicator/measure, but it's very expensive
						  r.val_number consumption,
						  r.meter_document_id,
						  TRUNC(r.end_dtm, 'dd') - TRUNC(r.start_dtm, 'dd') day_interval,
						  COUNT(*) OVER () AS total_rows
						FROM meter_reading r
						JOIN csr_user cu ON cu.csr_user_sid = r.entered_by_user_sid
					   WHERE r.region_sid = in_region_sid
						 AND r.active = 1
						 AND r.req_approval = 0
					   ORDER BY r.start_dtm DESC
					 ) 
					WHERE ROWNUM <= in_end_row
				 ) x
				 WHERE x.rn > in_start_row
				   AND d.meter_document_id(+) = x.meter_document_id
					ORDER BY start_dtm DESC;
		END IF;

	ELSE -- urjanet meters - the data is in a different table
		IF v_arbitrary_period = 0 THEN
			IF v_offset_months != v_year_offset THEN
				-- point in time meter, previous reading for comparison, urjanet meter
				OPEN out_cur FOR
					SELECT rn, rn meter_reading_id, reading_dtm, val, val total_val, avg_consumption,
						note, 3 entered_by_user_sid, null entered_dtm, 0 is_estimate, v_format_mask format_mask, total_rows, (SELECT full_name FROM csr_user WHERE csr_user_sid = 3) user_name,
						NULL reset_val, 0 baseline_val, 0 prev_baseline_val, null reference, cost, 0 is_reset,
						CASE WHEN avg_consumption = 0 OR LAG(avg_consumption) OVER (ORDER BY reading_dtm) = 0 THEN null ELSE
							ROUND((avg_consumption - LAG(avg_consumption) OVER (ORDER BY reading_dtm)) * 100 / LAG(avg_consumption) OVER (ORDER BY reading_dtm), 2)
						END pct_change, consumption,
						null doc_id, null doc_mime_type, null doc_file_name
					  FROM (
						SELECT rn, reading_dtm, val_number val, note, total_rows, cost,consumption,
							CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption
						  FROM ( 
						  SELECT x.*, ROWNUM rn
							FROM (
								SELECT start_dtm reading_dtm, val_number,
									   (val_number - LAG(val_number) OVER (order by start_dtm)) * DECODE(v_descending, 0, 1, -1) consumption, -- difference between values
									   TRUNC(start_dtm,'dd') - trunc(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS day_interval, -- difference between dates
									   note, COUNT(*) OVER () AS total_rows, cost
								  FROM v$meter_reading_urjanet
								 WHERE region_sid = in_region_sid
								 ORDER BY start_dtm DESC
							 ) x 
							 WHERE ROWNUM <= in_end_row
						 ) 
						 WHERE rn > in_start_row
					 ) x 
					 ORDER BY rn;
			ELSE
				-- point in time meter, last years reading for comparison, urjanet meter
				OPEN out_cur FOR
					SELECT r2.rn, r2.rn meter_reading_id, r2.reading_dtm reading_dtm, r2.val val, r2.val total_val, r2.avg_consumption, r2.note, 
							3 entered_by_user_sid, NULL entered_dtm, 0 is_estimate, v_format_mask format_mask, r2.total_rows, (SELECT full_name FROM csr_user WHERE csr_user_sid = 3) user_name, null reference,
							r2.cost, 0 is_reset, NULL reset_val, 0 baseline_val, 0 prev_baseline_val,
							CASE WHEN r2.avg_consumption = 0 OR r2.prev_avg = 0 THEN null
								 ELSE ROUND(((r2.avg_consumption - r2.prev_avg) * 100) / r2.prev_avg , 2)
							END pct_change,
							r2.consumption consumption,
							null doc_id, null doc_mime_type, null doc_file_name
					  FROM (
							SELECT rn, reading_dtm, val_number val, 
									CASE WHEN day_interval > 0 THEN ROUND(consumption / day_interval, 2) ELSE 0 END AS avg_consumption,
									consumption, offset_consumption, offset_day_interval,
									CASE WHEN offset_day_interval > 0 THEN ROUND(offset_consumption / offset_day_interval, 2) ELSE 0 END AS prev_avg,
									total_rows, cost, note
							  FROM ( 
								  SELECT ROWNUM rn, reading_dtm, val_number, consumption, day_interval, offset_consumption, offset_day_interval, total_rows, cost, note
									FROM (
										SELECT  reading_dtm, val_number,
												(val_number - LAG(val_number) OVER (ORDER BY reading_dtm)) * DECODE(v_descending, 0, 1, -1) consumption,
												TRUNC(reading_dtm,'dd') - trunc(LAG(reading_dtm, 1, reading_dtm) OVER (ORDER BY reading_dtm), 'dd') AS day_interval,
												SUM(NVL(offset_consumption, 0)) offset_consumption,
												SUM(offset_day_interval) offset_day_interval,
												COUNT(*) OVER () AS total_rows, cost, note
										  FROM (
											  SELECT r1.start_dtm reading_dtm, r1.val_number val_number, r1.cost,
													  omr.offset_consumption, omr.offset_day_interval, r1.note
												FROM v$meter_reading_urjanet r1
												LEFT JOIN (
													 SELECT region_sid, start_dtm offset_reading_dtm,
															(val_number - LAG(val_number) OVER (ORDER BY start_dtm)) * DECODE(v_descending, 0, 1, -1) offset_consumption, 
															TRUNC(start_dtm,'dd') - TRUNC(LAG(start_dtm, 1, start_dtm) OVER (ORDER BY start_dtm), 'dd') AS offset_day_interval
													   FROM v$meter_reading_urjanet
													  WHERE region_sid = in_region_sid
														AND val_number IS NOT NULL 
												) omr ON omr.region_sid = r1.region_sid 
													 AND omr.offset_reading_dtm = ADD_MONTHS(r1.start_dtm, v_offset_months)
											   WHERE r1.region_sid = in_region_sid
											  ) s1
										 ORDER BY reading_dtm DESC
									) s2
							 )  s3
					  ) r2
					 WHERE r2.rn > in_start_row
					   AND r2.rn <= in_end_row
					 ORDER BY r2.rn;
			END IF;
		ELSIF v_offset_months = v_year_offset THEN
			-- arbitrary period meter reading, last years reading for comparison, urjanet meter
			OPEN out_cur FOR	
				SELECT  r2.rn, r2.rn meter_reading_id, r2.note, 3 entered_by_user_sid, 0 is_estimate, v_format_mask format_mask, r2.avg_consumption, 
						CASE WHEN r2.avg_consumption = 0 OR r2.prev_avg = 0 THEN NULL
							 ELSE ROUND(((r2.avg_consumption - r2.prev_avg) * 100) / r2.prev_avg , 2)
						END pct_change,
						null entered_dtm, (SELECT full_name FROM csr_user WHERE csr_user_sid = 3) user_name, null reference, r2.cost,
						r2.total_rows, r2.start_dtm, r2.end_dtm, r2.consumption, null doc_id, null doc_mime_type, null doc_file_name
				  FROM (
						SELECT ROWNUM rn,
								CASE WHEN offset_day_interval > 0 THEN ROUND(offset_consumption / offset_day_interval, 2) ELSE 0 END AS prev_avg,
								CASE WHEN (TRUNC(end_dtm, 'dd') - TRUNC(start_dtm, 'dd')) > 0 THEN ROUND(consumption / (TRUNC(end_dtm, 'dd') - TRUNC(start_dtm, 'dd')), 2) ELSE 0 END AS avg_consumption,
								total_rows, start_dtm, end_dtm, consumption, note, cost
						  FROM (
							SELECT SUM(omr.val_number) offset_consumption, 
									TRUNC(MAX(omr.end_dtm), 'dd') - TRUNC(MIN(omr.start_dtm), 'dd') offset_day_interval, 
									r1.end_dtm end_dtm, r1.start_dtm start_dtm, r1.val_number consumption, r1.cost,
									COUNT(*) OVER () AS total_rows, r1.note
							  FROM v$meter_reading_urjanet r1
							  LEFT JOIN (
									 SELECT region_sid, end_dtm, start_dtm, val_number
									   FROM v$meter_reading_urjanet
									  WHERE region_sid = in_region_sid
										AND val_number IS NOT NULL 
							 ) omr ON omr.region_sid = r1.region_sid
								  AND omr.end_dtm > ADD_MONTHS(r1.start_dtm, v_offset_months)
								  AND omr.start_dtm < ADD_MONTHS(r1.end_dtm, v_offset_months)           
							 WHERE r1.region_sid = in_region_sid
							 GROUP BY r1.start_dtm, r1.end_dtm, r1.val_number
							 ORDER BY r1.start_dtm DESC
						 )
					 ) r2
				 WHERE r2.rn > in_start_row 
				   AND r2.rn <= in_end_row
				 ORDER BY r2.rn;
		ELSE
			-- arbitrary period meter reading, previous reading for comparison, urjanet meter
			OPEN out_cur FOR
				SELECT rn, meter_reading_id, note, 3 entered_by_user_sid, 0 is_estimate, v_format_mask format_mask, avg_consumption, 
					  CASE WHEN LAG(avg_consumption) OVER (ORDER BY start_dtm) = 0 THEN null ELSE
							ROUND((avg_consumption - LAG(avg_consumption) OVER (ORDER BY start_dtm)) * 100 / LAG(avg_consumption) OVER (ORDER BY start_dtm), 2)
					  END pct_change,
					  NULL entered_dtm, (SELECT full_name FROM csr_user WHERE csr_user_sid = 3) user_name, NULL reference, cost,
					  total_rows, start_dtm, end_dtm, consumption,
					  NULL doc_id, NULL doc_mime_type, NULL doc_file_name
				  FROM (
						SELECT ROWNUM rn, meter_reading_id, note, cost, total_rows, start_dtm, end_dtm, consumption,
						  CASE WHEN day_interval > 0 THEN round(consumption / day_interval, 2) ELSE 0 END AS avg_consumption
					 FROM (
						SELECT ROW_NUMBER() OVER (ORDER BY r.start_dtm) meter_reading_id, r.note, r.cost,
							   r.start_dtm, r.end_dtm, 0 is_estimate, NULL format_mask, r.val_number consumption,
							   TRUNC(r.end_dtm, 'dd') - TRUNC(r.start_dtm, 'dd') day_interval,
							   COUNT(*) OVER () AS total_rows
						  FROM v$meter_reading_urjanet r
						 WHERE r.region_sid = in_region_sid
					   ORDER BY r.start_dtm DESC
					 ) 
					WHERE ROWNUM <= in_end_row
				 ) x
				 WHERE x.rn > in_start_row
					ORDER BY start_dtm DESC;

		END IF;

	END IF;
END;

PROCEDURE MoveAndRenameMeter(
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_description				IN	region_description.description%TYPE
)
AS
	v_old_parent_sid		security_pkg.T_SID_ID;
	v_old_name				VARCHAR2(1024);
BEGIN

	SELECT r.parent_sid, r.description
	  INTO v_old_parent_sid, v_old_name
	  FROM v$region r
	 WHERE r.region_sid = in_region_sid;

	IF in_parent_sid IS NOT NULL AND v_old_parent_sid != in_parent_sid THEN
		-- move it -- could be slow. Hmm...
		securableobject_pkg.MoveSO(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, in_parent_sid);
	END IF;

	IF v_old_name != in_description THEN
		region_pkg.RenameRegion(in_region_sid, in_description);
	END IF;	

END;

PROCEDURE UNSEC_AmendMeterActive(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_active					IN	region.active%TYPE,
	in_acquisition_dtm			IN	region.acquisition_dtm%TYPE,
	in_disposal_dtm				IN	region.disposal_dtm%TYPE
)
AS
	v_acquisition_dtm			region.acquisition_dtm%TYPE;
	v_disposal_dtm				region.disposal_dtm%TYPE;
	v_fast						NUMBER := 1;
BEGIN
	-- Get the existing acquisition dtm
	SELECT acquisition_dtm
	  INTO v_acquisition_dtm
	  FROM region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;

	-- Sanity check
	IF in_acquisition_dtm IS NOT NULL AND in_disposal_dtm IS NOT NULL AND in_acquisition_dtm > in_disposal_dtm THEN
		RAISE_APPLICATION_ERROR(-20001, 'Acquisiton date can not be after disposal date');
	END IF;

	-- Set the acquisition dtm if requied
	IF v_acquisition_dtm != in_acquisition_dtm OR
		(v_acquisition_dtm IS NULL AND in_acquisition_dtm IS NOT NULL) OR
		(v_acquisition_dtm IS NOT NULL AND in_acquisition_dtm IS NULL) THEN
		-- Need full processing later
		v_fast := 0;
		-- Set the acquisition dtm on the region
		UPDATE region
		   SET acquisition_dtm = in_acquisition_dtm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid;
	END IF;

	-- Get the existing disposal dtm
	SELECT disposal_dtm
	  INTO v_disposal_dtm
	  FROM region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;

	-- Set the disposal dtm if requied
	IF v_disposal_dtm != in_disposal_dtm OR
		(v_disposal_dtm IS NULL AND in_disposal_dtm IS NOT NULL) OR
		(v_disposal_dtm IS NOT NULL AND in_disposal_dtm IS NULL) THEN
		-- Need full processing later
		v_fast := 0;
		-- Set the disposal dtm on the region
		UPDATE region
		   SET disposal_dtm = in_disposal_dtm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid;
	END IF;

	-- Get the region_pkg to do it's stuff
	region_pkg.UNSEC_AmendRegionActive(
		security_pkg.GetACT,
		in_region_sid,
		in_active,
		v_acquisition_dtm,
		v_disposal_dtm,
		v_fast
	);
END;

PROCEDURE SetMeter(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_description				IN	region_description.description%TYPE,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	in_active					IN	region.active%TYPE,
	in_acquisition_dtm			IN	region.acquisition_dtm%TYPE,
	in_disposal_dtm				IN	region.disposal_dtm%TYPE
)
AS
	v_acquisition_dtm			region.acquisition_dtm%TYPE;
	v_disposal_dtm				region.disposal_dtm%TYPE;
	v_fast						NUMBER := 1;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the meter with sid '||in_region_sid);
	END IF;

	MoveAndRenameMeter(
		in_region_sid, 
		in_parent_sid, 
		in_description
	);

	MakeMeter(
		security_pkg.GetACT,
		in_region_sid,
		in_meter_type_id,
		in_note,
		in_days_conversion_id,
		in_costdays_conversion_id,
		in_source_type_id,
		in_manual_data_entry,
		in_reference,
		in_contract_ids,
		in_active_contract_id,
		in_crc_meter,
		in_is_core,
		in_urjanet_meter_id
	);

	UNSEC_AmendMeterActive(
		in_region_sid,
		in_active,
		in_acquisition_dtm,
		in_disposal_dtm
	);

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

-- Version of measure_pkg.GetAllMeasures which only returns measures in use by the metering module
PROCEDURE GetAllMeteringMeasures(
	out_measure_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_measure_conv_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_measure_conv_date_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_measure_cur FOR
		SELECT m.measure_sid, m.format_mask, m.scale, m.name, m.description, m.custom_field,
			   m.pct_ownership_applies, m.std_measure_conversion_id, m.divisibility,
			   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, 
			   NVL(m.s, sm.s) s, NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol) mol,
			   NVL(m.cd, sm.cd) cd,
			   CASE WHEN m.description IS NULL THEN '('||m.name||')' ELSE m.description END label,
			   m.option_set_id, smc.description std_measure_description,
			   m.lookup_key
		  FROM measure m
		  LEFT JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		  JOIN meter_type_input mti ON m.measure_sid = mti.measure_sid
		 ORDER BY m.description;

	OPEN out_measure_conv_cur FOR
		SELECT c.measure_conversion_id, c.measure_sid, c.std_measure_conversion_id,
			   c.description, c.a, c.b, c.c, c.lookup_key
		  FROM measure_conversion c
		  JOIN meter_type_input mti ON c.measure_sid = mti.measure_sid;
		  
	OPEN out_measure_conv_date_cur FOR
		SELECT p.measure_conversion_id, p.start_dtm, p.end_dtm, p.a, p.b, p.c
		  FROM measure_conversion_period p
		  JOIN measure_conversion c ON p.measure_conversion_id = c.measure_conversion_id
		  JOIN meter_type_input mti ON c.measure_sid = mti.measure_sid;
END;

END meter_pkg;
/
