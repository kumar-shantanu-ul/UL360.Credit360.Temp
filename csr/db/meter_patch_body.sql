CREATE OR REPLACE PACKAGE BODY CSR.meter_patch_pkg IS

FUNCTION MeterPatchDataToTable(
	in_start			IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_end				IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_consumption		IN	meter_monitor_pkg.T_VAL_ARRAY
) RETURN T_METER_PATCH_DATA_TABLE
AS
	v_table T_METER_PATCH_DATA_TABLE := T_METER_PATCH_DATA_TABLE();
BEGIN
	IF in_start.COUNT != in_end.COUNT OR in_start.COUNT != in_consumption.COUNT THEN
		RETURN v_table;
	END IF;
	
	IF in_start.COUNT = 0 OR (in_start.COUNT = 1 AND in_start(in_start.FIRST) IS NULL) THEN
	-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
	END IF;

	FOR i IN in_start.FIRST .. in_start.LAST
	LOOP
		v_table.extend;
		v_table(v_table.COUNT) := T_METER_PATCH_DATA_ROW(i, in_start(i), in_end(i), null, in_consumption(i));
	END LOOP;
	
	RETURN v_table;
END;

FUNCTION MeterPatchDataToTable(
	in_start			IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_end				IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_period_type		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_consumption		IN	meter_monitor_pkg.T_VAL_ARRAY
) RETURN T_METER_PATCH_DATA_TABLE
AS
	v_table T_METER_PATCH_DATA_TABLE := T_METER_PATCH_DATA_TABLE();
BEGIN
	IF in_start.COUNT != in_end.COUNT OR in_start.COUNT != in_consumption.COUNT THEN
		RETURN v_table;
	END IF;
	
	IF in_start.COUNT = 0 OR (in_start.COUNT = 1 AND in_start(in_start.FIRST) IS NULL) THEN
	-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
	END IF;

	FOR i IN in_start.FIRST .. in_start.LAST
	LOOP
		v_table.extend;
		v_table(v_table.COUNT) := T_METER_PATCH_DATA_ROW(i, in_start(i), in_end(i), in_period_type(i), in_consumption(i));
	END LOOP;
	
	RETURN v_table;
END;

-- XXX: A version of the procedure to recmpute for only a given input migth be useful
PROCEDURE INTERNAL_RecomputeMeterData(
	in_region_sid					IN	security_pkg.T_SID_ID,
	--in_meter_input_id				IN	meter_input.meter_input_id%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE
)
AS
	v_manual_data_entry				all_meter.manual_data_entry%TYPE;
BEGIN
	-- High or low resolution (real-time or normal metering)
	SELECT manual_data_entry
	  INTO v_manual_data_entry
	  FROM all_meter am
	 WHERE am.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND am.region_sid = in_region_sid;

	-- XXX: USE METER INPUT ID?

	-- Reprocess patched bucket and system data
	IF v_manual_data_entry = 1 THEN
		-- Normal meter, could have both normal readings and raw readings
		meter_pkg.SetValTableForPeriod(in_region_sid, NULL, in_start_dtm, in_end_dtm);
		meter_monitor_pkg.ComputePeriodicDataFromRaw(in_region_sid, in_start_dtm, in_end_dtm, NULL);
	ELSE
		-- Real-time meter, only has raw readings
		meter_monitor_pkg.ComputePeriodicDataFromRaw(in_region_sid, in_start_dtm, in_end_dtm, NULL);
	END IF;
	-- Export the indicator values to the main system
	meter_monitor_pkg.BatchExportSystemValues;
END;

-- This procedure operates over data in the temp_meter_consumption table and is designed
-- for use during data processing rather than beign called stand-alone without context.
PROCEDURE INTERNAL_RmvRedntAutoPatches
AS
	v_auto_patch_priority		meter_data_priority.priority%TYPE;
	v_count						NUMBER;
BEGIN
	SELECT priority
	  INTO v_auto_patch_priority
	  FROM meter_data_priority
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_auto_patch = 1;
	
	-- Check for auto patch data
	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_meter_consumption
	 WHERE priority = v_auto_patch_priority;

	-- There's no need to run the expensive code below 
	-- if there's no auto patch data in the temp table
	IF v_count = 0 THEN
		RETURN;
	END IF;

	-- For each region/input/priority...
	FOR pr IN (
		SELECT DISTINCT t.priority, t.region_sid, t.meter_input_id
		  FROM temp_meter_consumption t
		  JOIN meter_input_aggr_ind i
		    ON i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.region_sid = t.region_sid
		   AND i.meter_input_id = t.meter_input_id
		  JOIN meter_data_priority p 
		    ON p.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND p.priority = t.priority 
		   AND p.is_input = 1
	) LOOP
		-- For each contiguous data block for this region/input/priority...
		FOR cd IN (
			SELECT MIN(start_dtm) start_dtm, MAX(end_dtm) end_dtm
			  FROM (
				SELECT ROWNUM rn, start_dtm, NULL end_dtm
				FROM (
					SELECT 
						start_dtm, end_dtm, 
						LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm,
						LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
					  FROM temp_meter_consumption
					 WHERE region_sid = pr.region_sid
					   AND meter_input_id = pr.meter_input_id
					   AND priority = pr.priority
				 ) 
				 WHERE last_end_dtm IS NULL
				    OR last_end_dtm != start_dtm
				UNION
				SELECT ROWNUM rn, NULL start_dtm, end_dtm
				  FROM (
					SELECT 
						start_dtm, end_dtm, 
						LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm,
						LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
					  FROM temp_meter_consumption
					 WHERE region_sid = pr.region_sid
					   AND meter_input_id = pr.meter_input_id
					   AND priority = pr.priority
				)
				 WHERE next_start_dtm IS NULL
				    OR next_start_dtm != end_dtm
			) 
			GROUP BY rn
		) LOOP
			-- Delete any auto patches completely overlapped by the contiguous data block
			DELETE FROM meter_patch_data
			  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			    AND region_sid = pr.region_sid
			    AND meter_input_id = pr.meter_input_id
			    AND priority = v_auto_patch_priority
			    AND start_dtm >= cd.start_dtm
			    AND end_dtm <= cd.end_dtm;
		END LOOP;
	END LOOP;
END;

PROCEDURE INTERNAL_UpdatePatchData(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtms		IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_end_dtms			IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_vals				IN	meter_monitor_pkg.T_VAL_ARRAY,
	out_min_dtm			OUT	DATE,
	out_max_dtm			OUT DATE
)
AS
	v_tbl				T_METER_PATCH_DATA_TABLE;
	v_is_consumption	meter_input.is_consumption_based%TYPE;
BEGIN
	SELECT is_consumption_based
	  INTO v_is_consumption
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_input_id = in_meter_input_id;
	
	v_tbl := MeterPatchDataToTable(in_start_dtms, in_end_dtms, in_vals);
	
	-- Get the min/max date range
	SELECT MIN(start_dtm), MAX(end_dtm)
	  INTO out_min_dtm, out_max_dtm
	  FROM TABLE(v_tbl);
	
	-- Extend the date range to the beginning/end of any patched that were overalpping and that were clipped when inserting the new patch data
	--
	-- For example the recompute date range is A to D
	--     A         B    C     D
	--OLD: |---------|    |-----|
	--NEW:        |----------|
	--            X          Y
	--
	-- For example the recompute date range is X to D
	--                    C     D
	--OLD:                |-----|
	--NEW:        |----------|
	--            X          Y
	--
	-- For example the recompute date range is A to Y
	--     A         B
	--OLD: |---------|
	--NEW:        |----------|
	--            X          Y
	--
	SELECT MIN(start_dtm), MAX(end_dtm)
	  INTO out_min_dtm, out_max_dtm
	  FROM ( 
		SELECT start_dtm, end_dtm
		  FROM TABLE(v_tbl)
		UNION
		SELECT start_dtm, end_dtm
		  FROM meter_patch_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND meter_input_id = in_meter_input_id
		   AND priority = in_priority
		   AND start_dtm < out_max_dtm
		   AND end_dtm > out_min_dtm
	);
	
	-- Process the patches
	FOR r IN (
		SELECT start_dtm, end_dtm, consumption
		  FROM TABLE(v_tbl)
		 ORDER BY pos
	) LOOP
		-- Remove any completely covered patces
		DELETE FROM meter_patch_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND meter_input_id = in_meter_input_id
		   AND priority = in_priority
		   AND start_dtm >= r.start_dtm
		   AND end_dtm <= r.end_dtm;
		
		-- Clipping for consumption type data only
		IF v_is_consumption = 1 THEN
		
			-- Overlap both sides of new data
			-- Note: We insert the end clipping part here and let the "Overlp with beginning of new data" 
			-- clipping update below update the existing overlapping row to become the beginning part.
			-- NEW:       |--------|
			-- OLD: |---------------------|
			INSERT INTO meter_patch_data (region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption)
				SELECT region_sid, meter_input_id, priority, r.end_dtm, end_dtm, consumption * (end_dtm - r.end_dtm) / (end_dtm - start_dtm)
				  FROM meter_patch_data
				  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_input_id = in_meter_input_id
				   AND priority = in_priority
				   AND start_dtm < r.start_dtm
				   AND end_dtm > r.end_dtm;
			
			-- Overlp with beginning of new data
			-- Clip the end of the old data
			-- NEW:       |--------|
			-- OLD: |----------|
			-- OUT: |-----|--------|
			UPDATE meter_patch_data
			   SET end_dtm = r.start_dtm,
			       consumption = consumption * (r.start_dtm - start_dtm) / (end_dtm - start_dtm)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = in_meter_input_id
			   AND priority = in_priority
			   AND end_dtm > r.start_dtm
			   AND start_dtm < r.start_dtm;
			
			-- Overlp with end of new data
			-- Clip the beginning of the old data
			-- NEW: |--------|
			-- OLD:     |----------|
			-- OUT: |--------|-----|
			UPDATE meter_patch_data
			   SET start_dtm = r.end_dtm,
			       consumption = consumption * (end_dtm - r.end_dtm) / (end_dtm - start_dtm)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = in_meter_input_id
			   AND priority = in_priority
			   AND start_dtm < r.end_dtm
			   AND end_dtm > r.end_dtm;		
		
		END IF; -- End is_consumption
		
		-- Upsert the new patch data
		IF r.consumption IS NOT NULL THEN
			BEGIN
				INSERT INTO meter_patch_data (region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption)
				VALUES (in_region_sid, in_meter_input_id, in_priority, r.start_dtm, r.end_dtm, r.consumption);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE meter_patch_data
					   SET consumption = r.consumption,
					       end_dtm = r.end_dtm,
					       updated_dtm = SYSDATE
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND region_sid = in_region_sid
					   AND meter_input_id = in_meter_input_id
					   AND priority = in_priority
					   AND start_dtm = r.start_dtm;
			END;
		END IF;
	END LOOP;
END;

PROCEDURE INTERNAL_UpdatePatchData(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	in_val				IN	meter_patch_data.consumption%TYPE,
	out_min_dtm			OUT	DATE,
	out_max_dtm			OUT DATE
)
AS
	v_start_dtms		meter_monitor_pkg.T_DATE_ARRAY;
	v_end_dtms			meter_monitor_pkg.T_DATE_ARRAY;
	v_vals				meter_monitor_pkg.T_VAL_ARRAY;
BEGIN
	v_start_dtms(0) := in_start_dtm;
	v_end_dtms(0) := in_end_dtm;
	v_vals(0) := in_val;
	
	INTERNAL_UpdatePatchData(
		in_region_sid,
		in_meter_input_id,
		in_priority,
		v_start_dtms,
		v_end_dtms,
		v_vals,
		out_min_dtm,
		out_max_dtm
	);
END;

PROCEDURE ProcessBatchJob(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_result_desc		OUT	batch_job.result%TYPE,
	out_result_url		OUT	batch_job.result_url%TYPE
)
AS
	v_min_dtm			DATE;
	v_max_dtm			DATE;
	v_add_min_dtm		DATE;
	v_add_max_dtm		DATE;
	v_region_sid		security_pkg.T_SID_ID;
	v_is_remove			meter_patch_batch_job.is_remove%TYPE;
	v_start_dtms		meter_monitor_pkg.T_DATE_ARRAY;
	v_end_dtms			meter_monitor_pkg.T_DATE_ARRAY;
	v_vals				meter_monitor_pkg.T_VAL_ARRAY;
BEGIN
	
	-- Noddy progress
	batch_job_pkg.SetProgress(in_batch_job_id, 0, 2);
	
	-- Get job info
	BEGIN
		SELECT region_sid, is_remove
		  INTO v_region_sid, v_is_remove
		  FROM meter_patch_batch_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND batch_job_id = in_batch_job_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Job data has been removed
			batch_job_pkg.SetProgress(in_batch_job_id, 2, 2);
			RETURN;
	END;

	-- Add/remove the patch data specified by the job	
	FOR r IN (
		SELECT DISTINCT d.meter_input_id, d.priority, i.is_consumption_based
		  FROM meter_patch_batch_data d
		  JOIN meter_input i ON i.app_sid = d.app_sid AND i.meter_input_id = d.meter_input_id
		 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND d.batch_job_id = in_batch_job_id
		   	ORDER BY meter_input_id, priority
	) LOOP
		SELECT start_dtm, end_dtm,
			CASE r.is_consumption_based
				WHEN 0 THEN consumption
				ELSE CASE period_type
					WHEN 'ABSOLUTE' THEN consumption
					WHEN 'DAILY' THEN consumption * (end_dtm - start_dtm)
					WHEN 'MONTHLY' THEN consumption * MONTHS_BETWEEN(end_dtm, start_dtm)
					WHEN 'ANNUAL' THEN consumption * MONTHS_BETWEEN(end_dtm, start_dtm) / 12
					ELSE NULL
				END
			END consumption
		  BULK COLLECT INTO v_start_dtms, v_end_dtms, v_vals
		  FROM meter_patch_batch_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND batch_job_id = in_batch_job_id
		   AND meter_input_id = r.meter_input_id
		   AND priority = r.priority
		   	ORDER BY start_dtm;
		
			INTERNAL_UpdatePatchData(
				v_region_sid,
				r.meter_input_id,
				r.priority,
				v_start_dtms,
				v_end_dtms,
				v_vals,
				v_add_min_dtm,
				v_add_max_dtm
			);
		
		-- Keep track of the overall affected date range
		v_min_dtm := LEAST(NVL(v_min_dtm, v_add_min_dtm), v_add_min_dtm);
		v_max_dtm := GREATEST(NVL(v_max_dtm, v_add_max_dtm), v_add_max_dtm);
	END LOOP;
	
	-- Noddy progress
	batch_job_pkg.SetProgress(in_batch_job_id, 1, 2);
	
	-- Recompute meter data for affected date range
	INTERNAL_RecomputeMeterData(
		v_region_sid, 
		/*in_meter_input_id,*/ 
		v_min_dtm, 
		v_max_dtm
	);
	
	-- Delete the job data
	DELETE FROM meter_patch_batch_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;
	   
	-- Delete the job data info
	DELETE FROM meter_patch_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;
	
	-- Set result
	out_result_desc := 'Patch applied successfully';
	out_result_url := meter_pkg.GetMeterPageUrl||'?meterSid='||v_region_sid;

	-- Noddy progress
	batch_job_pkg.SetProgress(in_batch_job_id, 2, 2);
END;

PROCEDURE AddPatchDataBatch(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtms		IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_end_dtms			IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_period_types		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals				IN	meter_monitor_pkg.T_VAL_ARRAY,
	in_notes			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_tbl				T_METER_PATCH_DATA_TABLE;
	v_desc				audit_log.description%TYPE;
	v_x					NUMBER := 1;
BEGIN
	-- Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_METER_PATCH,
		in_description => 'Apply patches to meter data',
		out_batch_job_id => out_job_id
	);
	
	-- Store the job
	INSERT INTO meter_patch_batch_job (batch_job_id, region_sid)
	VALUES (out_job_id, in_region_sid);

	v_tbl := MeterPatchDataToTable(in_start_dtms, in_end_dtms, in_period_types, in_vals);
	
	-- Add the job data
	FOR r IN (
		SELECT start_dtm, end_dtm, period_type, consumption
		  FROM TABLE(v_tbl)
		 ORDER BY pos
	) LOOP
		-- Upsert patch data
		BEGIN
			INSERT INTO meter_patch_batch_data (batch_job_id, meter_input_id, priority, start_dtm, end_dtm, period_type, consumption)
			VALUES (out_job_id, in_meter_input_id, in_priority, r.start_dtm, r.end_dtm, r.period_type, r.consumption);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_patch_batch_data
				   SET period_type = r.period_type,
				       consumption = r.consumption,
				       end_dtm = r.end_dtm
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND batch_job_id = out_job_id
				   AND meter_input_id = in_meter_input_id
				   AND priority = in_priority
				   AND start_dtm = r.start_dtm;
		END;
		
		-- Build audit log string conditionally based on what we have.
		v_desc := '';
		
		IF r.consumption IS NOT NULL THEN
			v_desc := v_desc||'Patch created. Start: {0}, end: {1}';
		ELSE
			v_desc := v_desc||'Patch cleared. Start: {0}, end: {1}';
		END IF;
		
		IF r.period_type IS NOT NULL THEN
			v_desc := v_desc||', level: "'||r.period_type||'"';
		END IF;
		
		IF r.consumption IS NOT NULL THEN
			v_desc := v_desc||', value: '||r.consumption;
		END IF;
		
		IF in_notes(v_x) IS NOT NULL THEN
			v_desc := v_desc||', note: "{2}"';
		END IF;
		
		-- Add audit log entry against region.
		csr_data_pkg.WriteAuditLogEntryForSid(
			in_sid_id			=>	SYS_CONTEXT('SECURITY', 'SID'),
			in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_METER_PATCH,
			in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'),
			in_object_sid		=>	in_region_sid,
			in_description		=>	v_desc,
			in_param_1			=>	r.start_dtm,
			in_param_2			=>	r.end_dtm,
			in_param_3			=>	in_notes(v_x)
		);
		
		v_x := v_x + 1;
	END LOOP;
END;

PROCEDURE AddPatchDataBatch(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	in_period_type		IN	meter_patch_batch_data.period_type%TYPE,
	in_val				IN	meter_patch_data.consumption%TYPE,
	in_note				IN	audit_log.description%TYPE,
	out_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_start_dtms		meter_monitor_pkg.T_DATE_ARRAY;
	v_end_dtms			meter_monitor_pkg.T_DATE_ARRAY;
	v_period_types		security_pkg.T_VARCHAR2_ARRAY;
	v_vals				meter_monitor_pkg.T_VAL_ARRAY;
	v_notes				security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	v_start_dtms(1) := in_start_dtm;
	v_end_dtms(1) := in_end_dtm;
	v_period_types(1) := in_period_type;
	v_vals(1) := in_val;
	v_notes(1) := in_note;
	
	AddPatchDataBatch(
		in_region_sid, 
		in_meter_input_id, 
		in_priority, 
		v_start_dtms, 
		v_end_dtms, 
		v_period_types,
		v_vals,
		v_notes,
		out_job_id
	);
END;

PROCEDURE AddPatchDataImmediate(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	in_val				IN	meter_patch_data.consumption%TYPE
)
AS
	v_start_dtms		meter_monitor_pkg.T_DATE_ARRAY;
	v_end_dtms			meter_monitor_pkg.T_DATE_ARRAY;
	v_vals				meter_monitor_pkg.T_VAL_ARRAY;
	v_min_dtm			DATE;
	v_max_dtm			DATE;
BEGIN
	v_start_dtms(0) := in_start_dtm;
	v_end_dtms(0) := in_end_dtm;
	v_vals(0) := in_val;
	
	INTERNAL_UpdatePatchData(
		in_region_sid, 
		in_meter_input_id, 
		in_priority, 
		v_start_dtms, 
		v_end_dtms, 
		v_vals, 
		v_min_dtm, 
		v_max_dtm
	);
	
	INTERNAL_RecomputeMeterData(
		in_region_sid, 
		/*in_meter_input_id,*/ 
		v_min_dtm, 
		v_max_dtm
	);
END;

PROCEDURE RemovePatchDataRangeImmediate(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE
)
AS
	v_min_dtm			DATE;
	v_max_dtm			DATE;
BEGIN
	INTERNAL_UpdatePatchData(
		in_region_sid,
		in_meter_input_id,
		in_priority,
		in_start_dtm,
		in_end_dtm,
		null,
		v_min_dtm, 	-- out (recalc full affected date range)
		v_max_dtm	-- out (recalc full affected date range)
	);
	
	INTERNAL_RecomputeMeterData(
		in_region_sid, 
		/*in_meter_input_id,*/ 
		v_min_dtm, 
		v_max_dtm
	);
END;

PROCEDURE RemovePatchDataRangeBatch(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	out_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_min_dtm			DATE;
	v_max_dtm			DATE;
BEGIN
	--Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_METER_PATCH,
		in_description => 'Apply patches to meter data',
		out_batch_job_id => out_job_id
	);
	
	-- Store the job
	INSERT INTO meter_patch_batch_job (batch_job_id, region_sid, is_remove)
	VALUES (out_job_id, in_region_sid, 1);
	
	-- Add the job data
	INSERT INTO meter_patch_batch_data (batch_job_id, meter_input_id, priority, start_dtm, end_dtm)
	VALUES (out_job_id, in_meter_input_id, in_priority, in_start_dtm, in_end_dtm);
END;


PROCEDURE INT_InsertConsumptionNoDup(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	security_pkg.T_SID_ID,
	in_this_priority		IN	meter_data_priority.priority%TYPE,
	in_last_priority		IN	meter_data_priority.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_exists	NUMBER;
BEGIN
	FOR r IN (
		SELECT region_sid, meter_input_id, in_this_priority priority, start_dtm, end_dtm, val_number
		  FROM temp_meter_consumption
		 WHERE region_sid = in_region_sid
		   AND meter_input_id = in_meter_input_id
		   AND priority = in_last_priority
		   AND start_dtm >= in_start_dtm
		   AND end_dtm <= in_end_dtm)
	LOOP
		SELECT COUNT(*)
		  INTO v_exists
		  FROM temp_meter_consumption
		 WHERE region_sid = r.region_sid
		   AND meter_input_id = r.meter_input_id
		   AND priority = r.priority
		   AND start_dtm = r.start_dtm
		   AND end_dtm = r.end_dtm
		   AND (val_number = r.val_number OR (val_number IS NULL AND r.val_number IS NULL));
		
		IF NVL(v_exists, 0) = 0 THEN
			--dbms_output.put_line('insertwd '||r.region_sid||' '||r.meter_input_id||' '||r.priority||' '||r.start_dtm||' '||r.end_dtm||' '||r.val_number);
			INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
			VALUES (r.region_sid, r.meter_input_id, r.priority, r.start_dtm, r.end_dtm, r.val_number);
		--ELSE
			--dbms_output.put_line('insertwd ignore dup '||r.region_sid||' '||r.meter_input_id||' '||r.priority||' '||r.start_dtm||' '||r.end_dtm||' '||r.val_number);
		END IF;
	END LOOP;
END;

PROCEDURE ApplyDataPatches(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_dtm				IN	DATE,
	in_max_dtm				IN	DATE
)
AS
	v_patch_count			NUMBER;
	v_priority_count		NUMBER;
	v_output_priority		meter_data_priority.priority%TYPE;
	v_max_patch_priority	meter_data_priority.priority%TYPE;
	v_min_dtm				DATE;
	v_max_dtm				DATE;
	v_start_dtm				DATE;
BEGIN
	-- Before applying patches look for and remove any redundant auto patches
	INTERNAL_RmvRedntAutoPatches;
	
	-- For each meter input
	FOR i IN (
		SELECT meter_input_id, is_consumption_based
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		-- The temp table might be empty for this input in the supplied 
		-- date range, but we still want to apply any patches to the data 
		-- range as the patch is likely to be correcting for missing data.
		v_min_dtm := meter_monitor_pkg.GetMinBucketBound(in_min_dtm, 1);
		v_max_dtm := meter_monitor_pkg.GetMaxBucketBound(in_max_dtm, 1);
		
		-- Count patches in range
		SELECT COUNT(*)
		  INTO v_patch_count
		  FROM meter_patch_data
		  WHERE region_sid = in_region_sid
		   AND meter_input_id = i.meter_input_id
		   AND start_dtm < v_max_dtm
	  	   AND end_dtm > v_min_dtm
	  	   AND priority IN (
	  	   	SELECT priority
	  	   	  FROM meter_data_priority
	  	   	 WHERE is_patch = 1
	  	  );
	  	
	  	-- Count input priorities in range
	  	SELECT COUNT(*)
	  	  INTO v_priority_count
	  	  FROM (
		  	SELECT DISTINCT priority
		  	  FROM temp_meter_consumption
		  	  WHERE region_sid = in_region_sid
			   AND meter_input_id = i.meter_input_id
			   AND start_dtm < v_max_dtm
		  	   AND end_dtm > v_min_dtm
		  	   AND priority IN (
		  	   	SELECT priority
		  	   	  FROM meter_data_priority
		  	   	 WHERE is_input = 1
		  	  )
		);
		
	  	-- Only run the patching code if there are 
		-- patches or if there is more than one patch level 
	  	-- present in the input data for given date range
		IF v_patch_count > 0 OR v_priority_count > 1 THEN
			
			-- Get the output priority
			SELECT priority
			  INTO v_output_priority
			  FROM meter_data_priority
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND is_output = 1;
			
			-- Insert patched "OUTPUT" data into temp table (so we get bucketed result data)
			-- All the data required to generate the output set should already be in the temp table at this point
			
			-- For each priority in use, in ascending order
			FOR p IN (
				SELECT is_patch, this_priority, last_priority
				  FROM (
					SELECT is_patch, is_output, priority this_priority, lag(priority) OVER (ORDER BY priority) last_priority
					  FROM meter_data_priority mdp
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND (
					   -- Select input priorities containing data (already in the temp table)
					   EXISTS (
					   		SELECT 1
					   		  FROM temp_meter_consumption tmp
					   		 WHERE tmp.region_sid = in_region_sid
					   		   AND tmp.meter_input_id = i.meter_input_id
					   		   AND tmp.priority = mdp.priority
					   )
					   -- Select patch priorities containing data
					   OR EXISTS (
					   		SELECT 1
					   		  FROM meter_patch_data mpde
					   		  WHERE mpde.region_sid = in_region_sid
					   		   AND mpde.meter_input_id = i.meter_input_id
					   		   AND mpde.priority = mdp.priority
					   		   AND mpde.start_dtm < v_max_dtm
					  	  	   AND mpde.end_dtm > v_min_dtm
					   )
				 	)
				 )
				 WHERE is_output = 0
				 ORDER BY this_priority
			) LOOP
				-- Keep track of the last patch priority we processed
				v_max_patch_priority := p.this_priority;
				--dbms_output.put_line('v_max_patch_priority='||v_max_patch_priority);
				
				-- Back-up the input data set
				IF p.is_patch = 0 THEN
					INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, raw_data_id)
						SELECT -region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, raw_data_id
						  FROM temp_meter_consumption
						 WHERE region_sid = in_region_sid
						   AND meter_input_id = i.meter_input_id
						   AND priority = p.this_priority;
				END IF;
				
				-- Compute values for overlapping fragments from last priority and insert the fragemnts
				
				IF p.is_patch = 1 THEN
					--dbms_output.put_line('ispatch');
					-- Select the dtm ranges of contiguous patch data sets 
					-- (patch over using higher priority)
					FOR d IN (
						SELECT MIN(start_dtm) start_dtm, MAX(end_dtm) end_dtm
						  FROM (
							SELECT ROWNUM rn, start_dtm, NULL end_dtm
							  FROM (
								SELECT 
									start_dtm, end_dtm, 
									LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm,
									LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
								  FROM meter_patch_data
								 WHERE region_sid = in_region_sid
								   AND meter_input_id = i.meter_input_id
								   AND priority = p.this_priority
								   AND start_dtm < v_max_dtm
						  	  	   AND end_dtm > v_min_dtm
							 ) 
							 WHERE last_end_dtm IS NULL
								OR last_end_dtm != start_dtm
							UNION
							SELECT ROWNUM rn, NULL start_dtm, end_dtm
							  FROM (
								SELECT 
									start_dtm, end_dtm, 
									LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm,
									LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
								FROM meter_patch_data
								WHERE region_sid = in_region_sid
								  AND meter_input_id = i.meter_input_id
								  AND priority = p.this_priority
								  AND start_dtm < v_max_dtm
						  	  	  AND end_dtm > v_min_dtm
							 )
							 WHERE next_start_dtm IS NULL
								OR next_start_dtm != end_dtm
						) 
						GROUP BY rn
					) LOOP
						IF i.is_consumption_based = 0 THEN
							DELETE FROM temp_meter_consumption
							 WHERE region_sid = in_region_sid
							   AND meter_input_id = i.meter_input_id
							   AND priority = p.last_priority
							   AND start_dtm >= d.start_dtm
							   AND end_dtm <= d.end_dtm;
						ELSE
							FOR r IN (
								-- Select data from last priority which overlaps the contiguous patch data range 
								SELECT region_sid, priority, start_dtm, end_dtm, val_number
								  FROM temp_meter_consumption
								 WHERE region_sid = in_region_sid
								   AND meter_input_id = i.meter_input_id
								   AND priority = p.last_priority
								   AND start_dtm < d.end_dtm
								   AND end_dtm > d.start_dtm
							) LOOP
								IF r.start_dtm != r.end_dtm THEN
									
									-- Beginning of last data to beginning of patch
									-- r.start_dtm -> d.start_dtm
									IF r.start_dtm < d.start_dtm THEN
										INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
											VALUES(in_region_sid, i.meter_input_id, p.this_priority, r.start_dtm, d.start_dtm, 
												(r.val_number * (d.start_dtm - r.start_dtm)) / (r.end_dtm - r.start_dtm)
											);
									END IF;
										
									-- End of patch to end of last data
									-- d.end_dtm -> r.end_dtm
									IF r.end_dtm > d.end_dtm THEN
										INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
											VALUES(in_region_sid, i.meter_input_id, p.this_priority, d.end_dtm, r.end_dtm, 
												(r.val_number * (r.end_dtm - d.end_dtm)) / (r.end_dtm - r.start_dtm)
											);
									END IF;
									
								END IF;
							END LOOP;
						END IF;
					END LOOP;
					
					-- Always insert the patch data from this priority
					INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
						SELECT region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption
						  FROM meter_patch_data
						 WHERE region_sid = in_region_sid
						   AND meter_input_id = i.meter_input_id
						   AND priority = p.this_priority
						   AND start_dtm < v_max_dtm
						   AND end_dtm > v_min_dtm;	
				
				ELSIF p.last_priority IS NOT NULL THEN
					--dbms_output.put_line('!ispatch');
					-- Select the dtm ranges of contiguous input data gaps 
					-- (patch through from lower priority)
					FOR d IN (
						SELECT MIN(start_dtm) start_dtm, MAX(end_dtm) end_dtm
						  FROM (
							SELECT ROWNUM rn, end_dtm start_dtm, NULL end_dtm
							  FROM (
								SELECT end_dtm, LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
								FROM temp_meter_consumption
								WHERE region_sid = in_region_sid
								  AND meter_input_id = i.meter_input_id
								  AND priority = p.this_priority
							 ) 
							 WHERE end_dtm != next_start_dtm
							UNION
							SELECT ROWNUM rn, NULL start_dtm, start_dtm end_dtm
							  FROM (
								SELECT start_dtm, LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm
								  FROM temp_meter_consumption
								 WHERE region_sid = in_region_sid
								   AND meter_input_id = i.meter_input_id
								   AND priority = p.this_priority
							 )
							 WHERE start_dtm != last_end_dtm
						) 
						GROUP BY rn
					) LOOP
						FOR r IN (
							SELECT start_dtm, end_dtm,
								GREATEST(d.start_dtm, start_dtm) result_start_dtm, 
								LEAST(d.end_dtm, end_dtm) result_end_dtm, 
								val_number
							  FROM temp_meter_consumption
							 WHERE region_sid = in_region_sid
							   AND meter_input_id = i.meter_input_id
							   AND priority = p.last_priority
							   AND start_dtm < d.end_dtm
							   AND end_dtm > d.start_dtm
						) LOOP
							--dbms_output.put_line('  start_dtm='||r.start_dtm||', end_dtm='||r.end_dtm);
							IF r.start_dtm != r.end_dtm THEN
								--dbms_output.put_line('    insert='||r.val_number||' p='||p.this_priority);
								INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
									VALUES(in_region_sid, i.meter_input_id, p.this_priority, r.result_start_dtm, r.result_end_dtm, 
										(r.val_number * (r.result_end_dtm - r.result_start_dtm)) / (r.end_dtm - r.start_dtm)
									);				
							END IF;
						END LOOP;
					END LOOP;
				END IF;
			
				-- Find contiguous date ranges from this priority and use them to 
				-- insert the non-overlapping data from last priority chunk by chunk
				IF p.last_priority IS NOT NULL THEN
					--dbms_output.put_line('haslastpriority');
					v_start_dtm := v_min_dtm;
					
					FOR r IN (
						SELECT MAX(start_dtm) start_dtm, MAX(end_dtm) end_dtm
						  FROM (
							SELECT ROWNUM rn, start_dtm, NULL end_dtm
							  FROM (
								SELECT 
									start_dtm, end_dtm, 
									LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm,
									LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
								  FROM temp_meter_consumption
								 WHERE region_sid = in_region_sid
								   AND meter_input_id = i.meter_input_id
								   AND priority = p.this_priority
							 ) 
							 WHERE last_end_dtm IS NULL
								OR last_end_dtm != start_dtm
							UNION
							SELECT ROWNUM rn, NULL start_dtm, end_dtm
							  FROM (
								SELECT 
									start_dtm, end_dtm, 
									LAG(end_dtm) over (ORDER BY start_dtm) last_end_dtm,
									LEAD(start_dtm) over (ORDER BY start_dtm) next_start_dtm
								FROM temp_meter_consumption
								WHERE region_sid = in_region_sid
								  AND meter_input_id = i.meter_input_id
								  AND priority = p.this_priority
							 )
							 WHERE next_start_dtm IS NULL
								OR next_start_dtm != end_dtm
						) 
						GROUP BY rn
					) LOOP
						-- Insert each non-overlapping chunk
						INT_InsertConsumptionNoDup(in_region_sid, i.meter_input_id, p.this_priority, p.last_priority, v_start_dtm, r.start_dtm);
						v_start_dtm := r.end_dtm;
					END LOOP;
					
					-- Insert the last chunk
					--dbms_output.put_line('last chunk');
					INT_InsertConsumptionNoDup(in_region_sid, i.meter_input_id, p.this_priority, p.last_priority, v_start_dtm, v_max_dtm);
				END IF;
			END LOOP; -- End loop over priorities
			
			-- The last patch layer to be processed is actually equivalent to the output data we want, 
			-- just update the priority of the final priority layer to identify it as the output data
			UPDATE temp_meter_consumption
			   SET priority = v_output_priority
			  WHERE region_sid = in_region_sid
			    AND meter_input_id = i.meter_input_id
			    AND priority = v_max_patch_priority;
			
			-- Clear down the working data from the above process
			DELETE FROM temp_meter_consumption
			 WHERE region_sid = in_region_sid
			   AND meter_input_id = i.meter_input_id
			   AND priority IN (
			   		SELECT priority
			   		  FROM meter_data_priority
			   		 WHERE is_output = 0
			 );
			
			-- Insert the patch data so we get buckets representing just the patches
			INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
				SELECT region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption
				  FROM meter_patch_data
				 WHERE region_sid = in_region_sid
				   AND meter_input_id = i.meter_input_id
				   AND priority IN (
				   		SELECT priority
				   		  FROM meter_data_priority
				   		 WHERE is_patch = 1
				 );
				   
			-- Restore the input data
			UPDATE temp_meter_consumption
			  SET region_sid = -region_sid
			WHERE region_sid = -in_region_sid
			  AND meter_input_id = i.meter_input_id;
		
		END IF; -- End no data check
	END LOOP; -- End for each meter input
END;

PROCEDURE AddAutoPatchJobsForMeter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
BEGIN	
	BEGIN
		INSERT INTO meter_patch_job (region_sid, meter_input_id, start_dtm, end_dtm)
			SELECT in_region_sid, in_meter_input_id, in_start_dtm, in_end_dtm
			  FROM DUAL
			 WHERE EXISTS (
				-- Only insert a job if auto patching is set-up and the 
				-- input has a gap finder and patch helper assigned to it
				SELECT 1
				  FROM all_meter m
				  JOIN meter_input_aggr_ind ai ON ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid
				  JOIN meter_input i ON i.app_sid = ai.app_sid AND i.meter_input_id = ai.meter_input_id
				 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND m.region_sid = in_region_sid
				   AND ai.meter_input_id = in_meter_input_id
				   AND i.patch_helper IS NOT NULL
				   AND i.gap_finder IS NOT NULL
			);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE meter_patch_job
			   SET start_dtm = LEAST(start_dtm, in_start_dtm),
			       end_dtm = GREATEST(end_dtm, in_end_dtm)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = in_meter_input_id;
	END;
END;

PROCEDURE GetAppsToPatch(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM meter_patch_job;
END;

PROCEDURE INTERNAL_FindDataGaps
AS
BEGIN
	DELETE FROM temp_meter_gaps;
	
	FOR r IN (
		-- XXX: Could avoid DISTINCT if were told which aggregator's data to look at
		SELECT DISTINCT i.gap_finder, i.meter_input_id, j.region_sid, j.start_dtm, j.end_dtm
		  FROM meter_input i
		  JOIN meter_input_aggr_ind ai ON ai.app_sid = i.app_sid AND ai.meter_input_id = i.meter_input_id
		  JOIN meter_patch_job j ON j.app_sid = ai.app_sid AND j.region_sid = ai.region_sid AND j.meter_input_id = ai.meter_input_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.gap_finder IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM meter_live_data d
			 WHERE d.app_sid = ai.app_sid
			   AND d.region_sid = ai.region_sid
			)
	) LOOP
		-- The gap finder will populate the temp_meter_gaps table
		EXECUTE IMMEDIATE 'BEGIN '||r.gap_finder||'(:1,:2,:3,:4);END;' USING r.region_sid, r.meter_input_id, r.start_dtm, r.end_dtm;
	END LOOP;
END;

PROCEDURE FindAndPatchDataGaps
AS
BEGIN
	-- Find data gaps for outstanding jobs
	INTERNAL_FindDataGaps;
	
	FOR r IN (
		SELECT DISTINCT region_sid, meter_input_id, start_dtm, end_dtm
		  FROM temp_meter_gaps
		 ORDER by region_sid, meter_input_id, start_dtm
	) LOOP
		AutoCreatePatches(r.region_sid, r.meter_input_id, r.start_dtm, r.end_dtm);
	END LOOP;
	
	-- Recompute the meter data now that the new patches have been added
	FOR r IN (
		SELECT region_sid, /*meter_input_id,*/ MIN(start_dtm) start_dtm, MAX(end_dtm) end_dtm
		  FROM temp_meter_gaps
		 GROUP BY region_sid --, meter_input_id
	) LOOP
		INTERNAL_RecomputeMeterData(r.region_sid, /*r.meter_input_id,*/ r.start_dtm, r.end_dtm);
	END LOOP;
	
	-- Remove processed jobs
	DELETE FROM meter_patch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE AutoCreatePatches(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_priority				meter_data_priority.priority%TYPE;
BEGIN
	SELECT priority
	  INTO v_priority
	  FROM meter_data_priority
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_auto_patch = 1;
	   
	FOR r IN (
		SELECT meter_input_id, patch_helper
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_input_id = in_meter_input_id
		   AND patch_helper IS NOT NULL
	) LOOP
		-- Call the patch helper
		EXECUTE IMMEDIATE 'BEGIN '||r.patch_helper||'(:1,:2,:3,:4,:5);END;' USING in_region_sid, r.meter_input_id, v_priority, in_start_dtm, in_end_dtm;
	END LOOP;
END;


-------


PROCEDURE GenericGapFinder(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_bucket_id				meter_bucket.meter_bucket_id%TYPE;
BEGIN
	meter_monitor_pkg.GetFinestDurationId(in_region_sid, v_bucket_id);
	
	INSERT INTO temp_meter_gaps (region_sid, meter_input_id, start_dtm, end_dtm)
		SELECT DISTINCT -- Data might be from multiple aggregators for the same input (the agaps should all be the same though)
			in_region_sid, in_meter_input_id, x.end_dtm missing_period_start, x.next_start_dtm missing_period_end
		  FROM (
			SELECT end_dtm, LEAD(start_dtm) OVER (PARTITION BY region_sid, meter_input_id, aggregator ORDER BY start_dtm) next_start_dtm
			  FROM v$patched_meter_live_data 
			 WHERE region_sid = in_region_sid
			   AND meter_input_id = in_meter_input_id
			   AND meter_bucket_id = v_bucket_id
			   AND consumption IS NOT NULL
			   AND start_dtm < in_end_dtm
			   AND end_dtm > in_start_dtm
		 ) x
		 WHERE x.end_dtm != x.next_start_dtm;
END;

PROCEDURE DayOfWeekPatcher(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_id					security_pkg.T_SID_IDS;
BEGIN
	-- Get the statistic ID for each week day average
	SELECT statistic_id
	  INTO v_id(1)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'MONDAY_AVG';
	
	SELECT statistic_id
	  INTO v_id(2)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'TUESDAY_AVG';
	   
	SELECT statistic_id
	  INTO v_id(3)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'WEDNESDAY_AVG';
	   
	SELECT statistic_id
	  INTO v_id(4)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'THURSDAY_AVG';
	   
	SELECT statistic_id
	  INTO v_id(5)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'FRIDAY_AVG';
	   
	SELECT statistic_id
	  INTO v_id(6)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'SATURDAY_AVG';
	   
	SELECT statistic_id
	  INTO v_id(7)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'SUNDAY_AVG';
	
	-- Insert the average day value for each day overlapping the input period
	FOR r IN (
		SELECT x.statistic_dtm, x.val
		  FROM (
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(1)
			   AND TO_CHAR(statistic_dtm, 'D') = 1
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(2)
			   AND TO_CHAR(statistic_dtm, 'D') = 2
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(3)
			   AND TO_CHAR(statistic_dtm, 'D') = 3
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(4)
			   AND TO_CHAR(statistic_dtm, 'D') = 4
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(5)
			   AND TO_CHAR(statistic_dtm, 'D') = 5
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(6)
			   AND TO_CHAR(statistic_dtm, 'D') = 6
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(7)
			   AND TO_CHAR(statistic_dtm, 'D') = 7
		 ) x
		 WHERE (x.statistic_dtm + 1) > in_start_dtm
		   AND x.statistic_dtm < in_end_dtm
		   AND val IS NOT NULL
	) LOOP
		BEGIN
			INSERT INTO meter_patch_data (region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption)
			VALUES (in_region_sid, in_meter_input_id, in_priority, r.statistic_dtm, r.statistic_dtm + 1, r.val);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_patch_data
			 	   SET end_dtm = r.statistic_dtm + 1,
			 	       consumption = r.val
			 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 	   AND region_sid = in_region_sid
			 	   AND meter_input_id = in_meter_input_id
			 	   AND priority = in_priority
			 	   AND start_dtm = r.statistic_dtm;
		END;
	END LOOP;
END;

PROCEDURE DayOfWeekCostPatcher(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_id					security_pkg.T_SID_IDS;
BEGIN
	-- Get the statistic ID for each week day average
	SELECT statistic_id
	  INTO v_id(1)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'MONDAY_AVG_COST';
	
	SELECT statistic_id
	  INTO v_id(2)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'TUESDAY_AVG_COST';
	   
	SELECT statistic_id
	  INTO v_id(3)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'WEDNESDAY_AVG_COST';
	   
	SELECT statistic_id
	  INTO v_id(4)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'THURSDAY_AVG_COST';
	   
	SELECT statistic_id
	  INTO v_id(5)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'FRIDAY_AVG_COST';
	   
	SELECT statistic_id
	  INTO v_id(6)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'SATURDAY_AVG_COST';
	   
	SELECT statistic_id
	  INTO v_id(7)
	  FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'SUNDAY_AVG_COST';
	
	-- Insert the average day value for each day overlapping the input period
	FOR r IN (
		SELECT x.statistic_dtm, x.val
		  FROM (
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(1)
			   AND TO_CHAR(statistic_dtm, 'D') = 1
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(2)
			   AND TO_CHAR(statistic_dtm, 'D') = 2
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(3)
			   AND TO_CHAR(statistic_dtm, 'D') = 3
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(4)
			   AND TO_CHAR(statistic_dtm, 'D') = 4
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(5)
			   AND TO_CHAR(statistic_dtm, 'D') = 5
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(6)
			   AND TO_CHAR(statistic_dtm, 'D') = 6
			UNION
			SELECT statistic_dtm, val
			  FROM meter_alarm_statistic_period
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND statistic_id = v_id(7)
			   AND TO_CHAR(statistic_dtm, 'D') = 7
		 ) x
		 WHERE (x.statistic_dtm + 1) > in_start_dtm
		   AND x.statistic_dtm < in_end_dtm
		   AND val IS NOT NULL
	) LOOP
		BEGIN
			INSERT INTO meter_patch_data (region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption)
			VALUES (in_region_sid, in_meter_input_id, in_priority, r.statistic_dtm, r.statistic_dtm + 1, r.val);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_patch_data
			 	   SET end_dtm = r.statistic_dtm + 1,
			 	       consumption = r.val
			 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 	   AND region_sid = in_region_sid
			 	   AND meter_input_id = in_meter_input_id
			 	   AND priority = in_priority
			 	   AND start_dtm = r.statistic_dtm;
		END;
	END LOOP;
END;

PROCEDURE PrepMeterPatchImportRow(
	in_source_row			IN	temp_meter_reading_rows.source_row%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_patch_level			IN	meter_patch_data.priority%TYPE,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	meter_reading.start_dtm%TYPE,
	in_end_dtm				IN	meter_reading.end_dtm%TYPE,
	in_val					IN	meter_reading.val_number%TYPE,
	in_note					IN	audit_log.description%TYPE
)
AS
BEGIN
	INSERT INTO temp_meter_patch_import_rows
		(source_row, region_sid, priority, meter_input_id, start_dtm, end_dtm, val, note)
	  VALUES (in_source_row, in_region_sid, in_patch_level, in_meter_input_id, in_start_dtm, in_end_dtm, in_val, in_note);
END;

PROCEDURE ImportPatchRows(
	out_result				OUT	security_pkg.T_OUTPUT_CUR,
	out_jobs				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_start_dtms			meter_monitor_pkg.T_DATE_ARRAY;
	v_end_dtms				meter_monitor_pkg.T_DATE_ARRAY;
	v_period_types			security_pkg.T_VARCHAR2_ARRAY;
	v_vals					meter_monitor_pkg.T_VAL_ARRAY;
	v_notes					security_pkg.T_VARCHAR2_ARRAY;
	v_created_jobs			security_pkg.T_SID_IDS;
	t_created_jobs			security.T_SID_TABLE;
BEGIN
	-- First check for invalid data
	FOR r IN (
		SELECT DISTINCT region_sid, meter_input_id, priority
		  FROM temp_meter_patch_import_rows
		 WHERE error_msg IS NULL
	) LOOP
		-- Detect overlaps
		FOR i IN (
			SELECT source_row, next_source_row
			  FROM (
				SELECT source_row, end_dtm, 
					LEAD(source_row) OVER (ORDER BY start_dtm) next_source_row,
					LEAD(start_dtm) OVER (ORDER BY start_dtm) next_start_dtm
				  FROM temp_meter_patch_import_rows
				 WHERE region_sid = r.region_sid
				   AND meter_input_id = r.meter_input_id
				   AND priority = r.priority
			 )
			 WHERE end_dtm > next_start_dtm
		) LOOP
			UPDATE temp_meter_patch_import_rows
			   SET error_msg = 'Patch periods can''t overlap.'
			 WHERE region_sid = r.region_sid
			   AND meter_input_id = r.meter_input_id
			   AND priority = r.priority
			   AND (source_row = i.source_row OR source_row = i.next_source_row);
		END LOOP;

		-- Detect invalid start/end dates
		UPDATE temp_meter_patch_import_rows
		   SET error_msg = 'Start date/time can''t be the same as or greater than the end date/time.'
		 WHERE region_sid = r.region_sid
		   AND meter_input_id = r.meter_input_id
		   AND priority = r.priority
		   AND start_dtm >= end_dtm;
	END LOOP;

	-- Throw out all rows for regions with any errros?
	/*
	UPDATE temp_meter_patch_import_rows
	   SET error_msg = 'Row not imported because other rows for this meter region have errors'
	 WHERE error_msg IS NULL 
	   AND region_sid IN (
	   		SELECT region_sid
	   		  FROM temp_meter_patch_import_rows
	   		 WHERE error_msg IS NOT NULL
	   );
	*/
	
	-- import any remaining valid data
	FOR r IN (
		SELECT DISTINCT region_sid, meter_input_id, priority
		  FROM temp_meter_patch_import_rows
		 WHERE error_msg IS NULL
	) LOOP
		-- Collect the input data arrays
		SELECT start_dtm, end_dtm, 'ABSOLUTE', val, note
		  BULK COLLECT INTO v_start_dtms, v_end_dtms, v_period_types, v_vals, v_notes
		  FROM temp_meter_patch_import_rows
		 WHERE error_msg IS NULL
		   AND region_sid = r.region_sid
		   AND meter_input_id = r.meter_input_id
		   AND priority = r.priority
		 ORDER BY start_dtm;

		-- Kick-off the batch job
		AddPatchDataBatch(
			in_region_sid		=> r.region_sid,
			in_meter_input_id	=> r.meter_input_id,
			in_priority			=> r.priority,
			in_start_dtms		=> v_start_dtms,
			in_end_dtms			=> v_end_dtms,
			in_period_types		=> v_period_types,
			in_vals				=> v_vals,
			in_notes			=> v_notes,
			out_job_id			=> v_created_jobs(v_created_jobs.COUNT)
		);

	END LOOP;

	OPEN out_result FOR
		SELECT source_row, error_msg
		  FROM temp_meter_patch_import_rows
		 WHERE error_msg IS NOT NULL;

	t_created_jobs := security_pkg.SidArrayToTable(v_created_jobs);

	OPEN out_jobs FOR
		SELECT column_value batch_job_id
		  FROM TABLE(t_created_jobs);
END;

END meter_patch_pkg;
/
