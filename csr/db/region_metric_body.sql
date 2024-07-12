CREATE OR REPLACE PACKAGE BODY CSR.region_metric_pkg AS

/**
 * Slightly specific helper procedure to quickly set measures, particularly
 * for pick-lists
 */
PROCEDURE SetMeasure(
	in_description  IN  measure.description%TYPE,
	out_measure_sid	OUT security_pkg.T_SID_ID
)
AS
	v_custom_field	measure.custom_field%TYPE := null;
	v_split_char	VARCHAR(1) := '/';
	v_description	measure.description%TYPE;
BEGIN
	-- if we find a name that matches then use it
	SELECT MIN(measure_sid)
	  INTO out_measure_sid
	  FROM measure
	 WHERE LOWER(description) = LOWER(in_description);

	IF out_measure_sid IS NOT NULL THEN
		RETURN;
	END IF;

	v_description := in_description;
	-- Yes/No type of thing or PICKLIST: foo, bar, bla
	IF INSTR(v_description, v_split_char) > 0 OR UPPER(v_description) LIKE 'PICKLIST:%' THEN

		-- Picklist: Chemical, Biological, Chemical/Biological, Physical, Combination/Other
		IF UPPER(v_description) LIKE 'PICKLIST:%' THEN
			v_description := SUBSTR(v_description,10);
			v_split_char := ',';
		END IF;

		-- split string, trim, and combine with CRLF separator
		SELECT REPLACE(LTRIM(SYS_CONNECT_BY_PATH(item, '|'),'|'),'|',CHR(13)||CHR(10))		  
		  INTO v_custom_field
	      FROM (
	        SELECT TRIM(item) item, POS
	          FROM TABLE(aspen2.utils_pkg.SplitString(v_description, v_split_char))
	      )
	      WHERE CONNECT_BY_ISLEAF = 1
	      START WITH pos = 1
	     CONNECT BY PRIOR pos = pos - 1;	
	END IF;

	measure_pkg.createMeasure(
		in_name 					=> LOWER(v_description),
		in_description 				=> v_description,
		in_custom_field 			=> v_custom_field,
		in_pct_ownership_applies	=> 0,
		in_format_mask				=> '#,##0',
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> out_measure_sid
	);
END;

PROCEDURE MakeMetric(
	in_ind_parent_sid	IN  security_pkg.T_SID_ID,
	in_description		IN  ind_description.description%TYPE,
	in_measure 			IN  VARCHAR2,
	out_ind_sid			OUT security_pkg.T_SID_ID
)
AS
	v_ind_sid		security_pkg.T_SID_ID;
	v_lookup_key	ind.lookup_key%TYPE;
	v_measure_sid 	security_pkg.T_SID_ID;
	v_aggregate		ind.aggregate%TYPE;
BEGIN
	-- not super robust but good enough for a helper stored proc
	SELECT MIN(ind_sid)
	  INTO v_ind_sid
	  FROM v$ind
	 WHERE UPPER(description) = UPPER(in_description)
	   AND parent_sid = in_ind_parent_sid;

	IF v_ind_sid IS NULL THEN
		-- first create the measure
		SetMeasure(in_measure, v_measure_sid);

		SELECT CASE WHEN custom_field IS NOT NULL THEN 'NONE' ELSE 'SUM' END
		  INTO v_aggregate
		  FROM measure
		 WHERE measure_sid = v_measure_sid;

		v_lookup_key := UPPER(REGEXP_REPLACE(REPLACE(in_description,' ','_'), '[^A-Za-z_]*',''));
		indicator_pkg.CreateIndicator(
	        in_parent_sid_id	=> in_ind_parent_sid,
	        in_name 			=> in_description,
	        in_description 		=> in_description,
	        in_measure_sid		=> v_measure_sid,
	        in_aggregate		=> v_aggregate,
	        in_lookup_key		=> v_lookup_key,
	        out_sid_id			=> v_ind_sid
		);
	END IF;
	SetMetric(v_ind_sid);
	out_ind_sid := v_ind_sid;
END;

PROCEDURE SetMetric(
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS 
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting region metric indicator with sid '||in_ind_sid);
	END IF;
	
	BEGIN
		INSERT INTO region_metric
			(ind_sid, measure_sid)
			SELECT ind_sid, measure_sid
			  FROM ind
			WHERE ind_sid = in_ind_sid;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE UnsetMetric(
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS 
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied unsetting region metric indicator with sid '||in_ind_sid);
	END IF;
	
	-- error if there is data
	FOR r IN (
		SELECT 1 
		  FROM DUAL 
		 WHERE EXISTS (
			SELECT null 
			  FROM region_metric_val 
			 WHERE ind_sid = in_ind_sid
		 )
	) LOOP
		RAISE_APPLICATION_ERROR(-20001, 'Can''t delete region metric with sid '||in_ind_sid||' as it has values associated with it');
	END LOOP;
	
	-- clean up layout/space type tables
	DELETE FROM benchmark_dashboard_char
	      WHERE ind_sid = in_ind_sid;
		  
	DELETE FROM meter_element_layout
	      WHERE ind_sid = in_ind_sid;

	DELETE FROM property_character_layout
	      WHERE ind_sid = in_ind_sid;

	DELETE FROM property_element_layout
	      WHERE ind_sid = in_ind_sid;

	DELETE FROM space_type_region_metric
	      WHERE ind_sid = in_ind_sid;
		  
	DELETE FROM meter_header_element
		  WHERE ind_sid = in_ind_sid;

	DELETE FROM region_type_metric
	      WHERE ind_sid = in_ind_sid;

	DELETE FROM region_metric
	      WHERE ind_sid = in_ind_sid;
END;

FUNCTION AreIndsAllMetrics (
	in_ind_sids				IN  security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	v_non_metric_count		NUMBER;
	v_ind_sids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_ind_sids);
BEGIN
	SELECT COUNT(*)
	  INTO v_non_metric_count
	  FROM TABLE(v_ind_sids) i
	  LEFT JOIN region_metric rm ON i.column_value = rm.ind_sid
	 WHERE rm.ind_sid IS NULL;
	 
	IF v_non_metric_count = 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE GetMetricsForType(
	in_region_type			IN	region_type_metric.region_type%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- XXX: we don't check ind_sid permissions - should we?

	OPEN out_cur FOR
		SELECT rm.ind_sid, m.measure_sid,
		    NVL(i.format_mask, m.format_mask) format_mask, i.lookup_Key, i.description,
		    rm.is_mandatory
		  FROM region_type_metric rtm
		    JOIN region_metric rm ON rtm.ind_sid = rm.ind_sid AND rtm.app_sid = rm.app_sid
		    JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		    JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid        
		 WHERE rtm.region_type = in_region_type
		 ORDER BY description;
END;

PROCEDURE INTERNAL_BeginAuditMetrics(
	in_region_sid				IN  security_pkg.T_SID_ID,
	out_metrics					OUT T_REGION_METRIC_AUDIT_TABLE
)
AS
BEGIN
	SELECT T_REGION_METRIC_AUDIT_ROW(region_metric_val_id, ind_sid, entry_measure_conversion_id, entry_val, effective_dtm)
	  BULK COLLECT INTO out_metrics
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
END;

PROCEDURE INTERNAL_EndAuditMetrics(
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_metrics					IN  T_REGION_METRIC_AUDIT_TABLE
)
AS
BEGIN
	-- Look for removed metrics...
	FOR r IN (
		SELECT x.region_metric_val_id, i.description, x.val, x.effective_dtm
		  FROM TABLE(in_metrics) x
		  JOIN v$ind i ON i.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND i.ind_sid = x.ind_sid
		 WHERE NOT EXISTS (
		 	SELECT 1
		 	  FROM region_metric_val v
		 	 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND v.region_sid = in_region_sid
		 	   AND v.region_metric_val_id = x.region_metric_val_id
		 )
	) LOOP
		-- Removed
		csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=>	security_pkg.GetACT,
			in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_REGION_METRIC,
			in_app_sid			=>	security_pkg.GetAPP,
			in_object_sid		=>	in_region_sid,
			in_description		=>	'Metric "{0}" with the value of {1} and an effective date of {2} removed.',
			in_param_1			=>	r.description,
			in_param_2			=>	r.val,
			in_param_3			=>	r.effective_dtm
		);
	END LOOP;
	
	-- Look for added metrics...
	FOR r IN (
		SELECT v.region_metric_val_id, i.description, v.entry_val, v.effective_dtm
		  FROM region_metric_val v
		  JOIN v$ind i ON i.app_sid = v.app_sid AND i.ind_sid = v.ind_sid
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.region_sid = in_region_sid
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM TABLE(in_metrics) x
		 	 WHERE x.region_metric_val_id = v.region_metric_val_id
		 )
	) LOOP
		-- Added
		csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=>	security_pkg.GetACT,
			in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_REGION_METRIC,
			in_app_sid			=>	security_pkg.GetAPP,
			in_object_sid		=>	in_region_sid,
			in_description		=>	'Metric "{0}" with the value of {1} and an effective date of {2} added.',
			in_param_1			=>	r.description,
			in_param_2			=>	r.entry_val,
			in_param_3			=>	r.effective_dtm
		);
	END LOOP;
	
	-- Look for values that have changed (present in both tables, before and after)
	FOR r IN (
		SELECT v.region_metric_val_id, i.description,
				v.entry_val new_val, v.entry_measure_conversion_id new_conversion_id, NVL(mcn.description, ms.description) new_conversion_desc,
				x.val old_val, x.conversion_id old_conversion_id, NVL(mco.description, ms.description) old_conversion_desc,
				v.effective_dtm new_effective_dtm, x.effective_dtm old_effective_dtm
		  FROM region_metric_val v
		  JOIN TABLE(in_metrics) x ON v.region_metric_val_id = x.region_metric_val_id
		  JOIN v$ind i ON i.app_sid = v.app_sid AND i.ind_sid = x.ind_sid
		  JOIN measure ms ON ms.app_sid = v.app_sid AND ms.measure_sid = v.measure_sid
		  LEFT JOIN measure_conversion mcn ON mcn.app_sid = ms.app_sid AND mcn.measure_sid = ms.measure_sid AND mcn.measure_conversion_id = v.entry_measure_conversion_id
		  LEFT JOIN measure_conversion mco ON mco.app_sid = ms.app_sid AND mco.measure_sid = ms.measure_sid AND mco.measure_conversion_id = x.conversion_id
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.region_sid = in_region_sid
	) LOOP
		-- Audit value cahnges
		csr_data_pkg.AuditValueChange(
			in_act				=>	security_pkg.GetACT,
			in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_REGION_METRIC,
			in_app_sid			=>	security_pkg.GetAPP,
			in_object_sid		=>	in_region_sid,
			in_field_name		=>	'Metric "'||r.description||'"',
			in_old_value		=>	r.old_val,
			in_new_value		=>	r.new_val
		);

		-- Audit conversion changes
		csr_data_pkg.AuditValueDescChange(
			in_act				=>	security_pkg.GetACT,
			in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_REGION_METRIC,
			in_app_sid			=>	security_pkg.GetAPP,
			in_object_sid		=>	in_region_sid,
			in_field_name		=>	'Metric measure for "'||r.description||'"',
			in_old_value		=>	r.old_conversion_id,
			in_new_value		=>	r.new_conversion_id,
			in_old_desc			=>	r.old_conversion_desc,
			in_new_desc			=>	r.new_conversion_desc
		);
	END LOOP;
END;

PROCEDURE DeleteMetricValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
	v_audit_table			T_REGION_METRIC_AUDIT_TABLE;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid '||in_region_sid);
	END IF;
	
	INTERNAL_BeginAuditMetrics(in_region_sid, v_audit_table);
	
	-- Create energy star jobs if required
	FOR r IN (
		SELECT region_metric_val_id
		  FROM region_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND ind_sid = in_ind_sid
	) LOOP
		-- Create energy star jobs if required
		energy_star_job_pkg.OnRegionMetricChange(in_region_sid, r.region_metric_val_id);
		-- Remove any reference held by a space attribute
		UPDATE est_space_attr
		   SET region_metric_val_id = NULL
		 WHERE region_metric_val_id = r.region_metric_val_id;
	END LOOP;

	-- Have to update imp_val before deleting region_metric_val
	UPDATE imp_val
	   SET set_region_metric_val_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND set_region_metric_val_id IN (
		SELECT region_metric_val_id
		  FROM region_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND ind_sid = in_ind_sid);

	DELETE FROM val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid
	   AND (source_type_id = csr_data_pkg.SOURCE_TYPE_REGION_METRIC OR 
			source_type_id IN (
				SELECT source_type_id
				  FROM region_metric_val
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND ind_sid = in_ind_sid
				)
			);
	
	DELETE FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid;
	   
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	calc_pkg.AddJobsForVal(
		in_ind_sid,
		in_region_sid,
		v_calc_start_dtm,
		v_calc_end_dtm
	);
	
	INTERNAL_EndAuditMetrics(in_region_sid, v_audit_table);
	
END;

PROCEDURE GetMetricValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT rmv.region_sid, rmv.ind_sid, rmv.effective_dtm, rmv.entered_by_sid, rmv.entered_dtm, rmv.entry_val as val, rmv.note, rmv.region_metric_val_id,
			   rmv.entry_measure_conversion_id AS measure_conversion_id, rmv.measure_sid,
			   NVL(mc.description, m.description) measure_description,
			   NVL(i.format_mask, m.format_mask) format_mask,
			   rm.show_measure,
			   CASE WHEN rmv.effective_dtm > SYSDATE THEN 1 ELSE 0 END is_future_value
		  FROM region_metric_val rmv
			   JOIN region_metric rm ON rmv.ind_sid = rm.ind_sid AND rmv.app_sid = rm.app_sid
			   JOIN ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
			   JOIN measure m ON rmv.measure_sid = m.measure_sid AND rmv.app_sid = m.app_sid
		  LEFT JOIN measure_conversion mc ON rmv.entry_measure_conversion_id = mc.measure_conversion_id AND rmv.measure_sid = mc.measure_sid AND rmv.app_sid = mc.app_sid
		 WHERE rmv.region_sid = in_region_sid
		   AND rmv.ind_sid = in_ind_sid
		 ORDER BY rmv.effective_dtm DESC; -- order matters - we return the most recent value first
END;

FUNCTION GetCurrentMetricVal (
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_lookup_key					IN  ind.lookup_key%TYPE
) RETURN NUMBER
AS
	v_val							NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid '||in_region_sid);
	END IF;

	SELECT val
	  INTO v_val
	  FROM (
		SELECT v.val
		  FROM region_metric_val v
		  JOIN region_metric m ON v.ind_sid = m.ind_sid AND v.app_sid = m.app_sid
		  JOIN ind i ON m.ind_sid = i.ind_sid AND v.app_sid = m.app_sid
		 WHERE v.region_sid = in_region_sid
		   AND i.lookup_key = in_lookup_key
		 ORDER BY effective_dtm DESC
	  )
	 WHERE ROWNUM <= 1;
	 
	RETURN v_val;
END;

PROCEDURE BulkSetMetricValue(
	in_region_sid					 IN	security_pkg.T_SID_ID,
	in_ind_sid						 IN	security_pkg.T_SID_ID,
	in_effective_dtm				 IN	region_metric_val.effective_dtm%TYPE,
	in_val							 IN	region_metric_val.val%TYPE,
	in_note							 IN	region_metric_val.note%TYPE,
	in_replace_dtm					 IN	region_metric_val.effective_dtm%TYPE				DEFAULT NULL, -- Set this if the metric is to be replaced with a different dtm
	in_entry_measure_conversion_id	 IN	region_metric_val.entry_measure_conversion_id%TYPE	DEFAULT NULL,
	in_source_type_id				 IN	region_metric_val.source_type_id%TYPE				DEFAULT NULL,
	out_min_dtm						OUT	DATE,
	out_max_dtm						OUT DATE,
	out_region_metric_val_id		OUT region_metric_val.region_metric_val_id%TYPE
)
AS
	v_measure_sid					region_metric_val.measure_sid%TYPE;
	v_val_id						region_metric_val.region_metric_val_id%TYPE;
	v_effective_dtm					DATE := TRUNC(in_effective_dtm, 'DD');
	v_audit_table					T_REGION_METRIC_AUDIT_TABLE;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	-- XXX: what permissions should we use? The age-old region permission question. Write is probably
	-- too harsh as it means you can alter attributes of the region. If you can see it you can change it?
	-- Hmm... seems to lax. Use a capability like meters?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on region with sid '||in_region_sid);
	END IF;

	INTERNAL_BeginAuditMetrics(in_region_sid, v_audit_table);
	
	SELECT measure_sid
	  INTO v_measure_sid
	  FROM region_metric
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ind_sid = in_ind_sid;

	IF in_replace_dtm IS NOT NULL THEN
		BEGIN
			-- Get the val id
			SELECT region_metric_val_id
			  INTO v_val_id
			  FROM region_metric_val
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND ind_sid = in_ind_sid
			   AND effective_dtm = in_replace_dtm;
			-- supress delete audit, as we are changing effective dtm
			DeleteMetricValue(v_val_id, 0);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- Ignore
		END;
	END IF;

	BEGIN
		INSERT INTO region_metric_val (
				region_metric_val_id,
				region_sid,
				ind_sid,
				effective_dtm,
				entered_by_sid,
				entered_dtm,
				val,
				note,
				measure_sid,
				source_type_id,
				entry_measure_conversion_id,
				entry_val
			)
		VALUES (
				region_metric_val_id_seq.nextval,
				in_region_sid,
				in_ind_sid,
				v_effective_dtm,
				security_pkg.GetSID,
				SYSDATE,
				csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_entry_measure_conversion_id, v_effective_dtm),
				in_note,
				v_measure_sid,
				NVL(in_source_type_id, csr_data_pkg.SOURCE_TYPE_REGION_METRIC),
				in_entry_measure_conversion_id,
				in_val
			)
		RETURNING region_metric_val_id INTO out_region_metric_val_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE region_metric_val
			   SET entered_by_sid = security_pkg.GetSID,
			       entered_dtm = SYSDATE,
			       val = csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_entry_measure_conversion_id, v_effective_dtm),
			       note = in_note,
				   measure_sid = v_measure_sid,
				   source_type_id = NVL(in_source_type_id, csr_data_pkg.SOURCE_TYPE_REGION_METRIC),
			       entry_measure_conversion_id = in_entry_measure_conversion_id,
			       entry_val = in_val
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   	   AND region_sid = in_region_sid
		   	   AND ind_sid = in_ind_sid
		   	   AND effective_dtm = v_effective_dtm
		 RETURNING region_metric_val_id INTO out_region_metric_val_id;
	END;

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- Determine min dtm (previous value dtm or new value dtm if no previous value exists)
	SELECT LEAST(GREATEST(NVL(MAX(effective_dtm), v_effective_dtm), v_calc_start_dtm), v_calc_end_dtm)
	  INTO out_min_dtm
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid
	   AND effective_dtm < GREATEST(NVL(in_replace_dtm, v_effective_dtm), v_effective_dtm);

	-- Determine max dtm (next value or calc end)
	SELECT GREATEST(LEAST(NVL(MIN(effective_dtm), v_calc_end_dtm), v_calc_end_dtm), v_calc_start_dtm)
	  INTO out_max_dtm
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid
	   AND effective_dtm > LEAST(NVL(in_replace_dtm, v_effective_dtm), v_effective_dtm);

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionMetricChange(in_region_sid, out_region_metric_val_id);
	INTERNAL_EndAuditMetrics(in_region_sid, v_audit_table);
END;

PROCEDURE SetMetricValue(
	in_region_sid					 IN	security_pkg.T_SID_ID,
	in_ind_sid						 IN	security_pkg.T_SID_ID,
	in_effective_dtm				 IN	region_metric_val.effective_dtm%TYPE,
	in_val							 IN	region_metric_val.val%TYPE,
	in_note							 IN	region_metric_val.note%TYPE,
	in_replace_dtm					 IN	region_metric_val.effective_dtm%TYPE				DEFAULT NULL, -- Set this if the metric is to be replaced with a different dtm
	in_entry_measure_conversion_id	 IN	region_metric_val.entry_measure_conversion_id%TYPE	DEFAULT NULL,
	in_source_type_id				 IN	region_metric_val.source_type_id%TYPE				DEFAULT NULL,
	out_region_metric_val_id		OUT region_metric_val.region_metric_val_id%TYPE
)
AS
	v_min_dtm 						DATE;
	v_max_dtm						DATE;
BEGIN
	-- Set the metric value
	BulkSetMetricValue(
		in_region_sid,
		in_ind_sid,
		in_effective_dtm,
		in_val,
		in_note,
		in_replace_dtm,
		in_entry_measure_conversion_id,
		in_source_type_id,
		v_min_dtm,
		v_max_dtm,
		out_region_metric_val_id
	);

	-- Update the val table
	SetSystemValues(
		in_region_sid,
		in_ind_sid,
		v_min_dtm,
		v_max_dtm
	);

	csr.property_pkg.INTERNAL_CallHelperPkg('RegionMetricUpdated', in_region_sid);

END;

PROCEDURE SetMetricValue(
	in_region_metric_val_id			 IN region_metric_val.region_metric_val_id%TYPE,
	in_effective_dtm				 IN	region_metric_val.effective_dtm%TYPE,
	in_val							 IN	region_metric_val.val%TYPE,
	in_note							 IN	region_metric_val.note%TYPE,
	in_entry_measure_conversion_id	 IN	region_metric_val.entry_measure_conversion_id%TYPE	DEFAULT NULL,
	in_source_type_id				 IN	region_metric_val.source_type_id%TYPE				DEFAULT NULL
)
AS
	v_ind_sid						region_metric_val.ind_sid%TYPE;
	v_region_sid					region_metric_val.region_sid%TYPE;
	v_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_min_dtm						DATE;
	v_max_dtm						DATE;
	v_calc_end_dtm					DATE;
BEGIN
	SELECT rmv.ind_sid, rmv.region_sid, rmv.effective_dtm, c.calc_end_dtm
	  INTO v_ind_sid, v_region_sid, v_effective_dtm, v_calc_end_dtm
	  FROM region_metric_val rmv, csr.customer c
	 WHERE c.app_sid = rmv.app_sid
	   AND rmv.region_metric_val_id = in_region_metric_val_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on region with sid '||v_region_sid);
	END IF;

	UPDATE region_metric_val
	   SET effective_dtm = TRUNC(in_effective_dtm, 'DD'),
	   	   val = csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_entry_measure_conversion_id, TRUNC(in_effective_dtm, 'DD')),
	   	   entry_val = in_val,
	   	   note = in_note,
	   	   entry_measure_conversion_id = in_entry_measure_conversion_id,
	   	   source_type_id = NVL(in_source_type_id, csr_data_pkg.SOURCE_TYPE_REGION_METRIC)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_metric_val_id = in_region_metric_val_id;

	-- Determine min dtm (previous value or old value if none exists)
	SELECT NVL(MAX(effective_dtm), v_effective_dtm)
	  INTO v_min_dtm
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = v_region_sid
	   AND ind_sid = v_ind_sid
	   AND effective_dtm < v_effective_dtm;

	-- Determine max dtm (next value or calc end)
	SELECT NVL(MIN(effective_dtm), v_calc_end_dtm)
	  INTO v_max_dtm
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = v_region_sid
	   AND ind_sid = v_ind_sid
	   AND effective_dtm > v_effective_dtm;

	-- Update the val table
	SetSystemValues(
		v_region_sid,
		v_ind_sid,
		v_min_dtm,
		v_max_dtm
	);

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionMetricChange(v_region_sid, in_region_metric_val_id);
END;

PROCEDURE DeleteMetricValue(
	in_region_metric_val_id	IN 	region_metric_val.region_metric_val_id%TYPE,
	in_audit_delete			IN	NUMBER DEFAULT 1
)
AS
	v_ind_sid						region_metric_val.ind_sid%TYPE;
	v_region_sid					region_metric_val.region_sid%TYPE;
	v_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_min_dtm						DATE;
	v_max_dtm						DATE;
	v_audit_table					T_REGION_METRIC_AUDIT_TABLE;
	v_calc_end_dtm					DATE;
BEGIN

	SELECT rmv.ind_sid, rmv.region_sid, rmv.effective_dtm, c.calc_end_dtm
	  INTO v_ind_sid, v_region_sid, v_effective_dtm, v_calc_end_dtm
	  FROM region_metric_val rmv, csr.customer c
	 WHERE c.app_sid = rmv.app_sid
	   AND rmv.region_metric_val_id = in_region_metric_val_id;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on region with sid '||v_region_sid);
	END IF;
	
	INTERNAL_BeginAuditMetrics(v_region_sid, v_audit_table);
	
	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionMetricChange(v_region_sid, in_region_metric_val_id);
	
	-- Remove any reference held by a space attribute
	UPDATE est_space_attr
	   SET region_metric_val_id = NULL
	 WHERE region_metric_val_id = in_region_metric_val_id;
	
	-- Have to update imp_val before deleting region_metric_val
	UPDATE imp_val
	   SET set_region_metric_val_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND set_region_metric_val_id = in_region_metric_val_id;
	
	DELETE FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_metric_val_id = in_region_metric_val_id;
	
	-- Determine min dtm (previous value or old value if none exists)
	SELECT NVL(MAX(effective_dtm), v_effective_dtm)
	  INTO v_min_dtm
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = v_region_sid
	   AND ind_sid = v_ind_sid
	   AND effective_dtm < v_effective_dtm;
	
	-- Determine max dtm (next value or calc end)
	SELECT NVL(MIN(effective_dtm), v_calc_end_dtm)
	  INTO v_max_dtm
	  FROM region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = v_region_sid
	   AND ind_sid = v_ind_sid
	   AND effective_dtm > v_effective_dtm;
	
	-- Update the val table
	SetSystemValues(
		v_region_sid,
		v_ind_sid,
		v_min_dtm,
		v_max_dtm
	);
	
	-- #audit metric value delete
	IF in_audit_delete = 1 THEN
		INTERNAL_EndAuditMetrics(v_region_sid, v_audit_table);
	END IF;
END;

PROCEDURE INTERNAL_UpsertVal(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	region_metric_val.effective_dtm%TYPE,
	in_end_dtm				IN	region_metric_val.effective_dtm%TYPE,
	in_val					IN	val.val_number%TYPE,
	in_note					IN	val.note%TYPE,
	in_source_type_id		IN	val.source_type_id%TYPE
)
AS
	v_val_id				val.val_id%TYPE;
	v_file_uploads			security_pkg.T_SID_IDS; -- empty
BEGIN
	-- Call SetValue as it's more robust than inserting directly into val
	-- SetValueWithReasonWithSid doesn't check security -- this mirrors the previous
	-- behaviour. We ought to do the security check in region_metric_pkg somewhere.
	indicator_pkg.SetValueWithReasonWithSid(
		in_user_sid				=> security_pkg.GetSid,
		in_ind_sid				=> in_ind_sid,
		in_region_sid			=> in_region_sid,
		in_period_start			=> in_start_dtm,
		in_period_end			=> in_end_dtm,
		in_val_number			=> in_val,
		in_flags				=> 0,
		in_source_type_id		=> in_source_type_id,
		in_entry_conversion_id	=> NULL,
		in_entry_val_number		=> in_val,
		in_note					=> in_note,
		in_reason				=> 'Region metric',
		in_have_file_uploads	=> 0,
		in_file_uploads			=> v_file_uploads,
		out_val_id				=> v_val_id
	);
END;

PROCEDURE SetSystemValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	region_metric_val.effective_dtm%TYPE,
	in_end_dtm				IN	region_metric_val.effective_dtm%TYPE
)
AS
	v_cur						SYS_REFCURSOR;
	v_months_tbl 				T_NORMALISED_VAL_TABLE;
	v_divisibility				NUMBER(1);
	v_cust_field				measure.custom_field%TYPE;
	v_min_dtm					DATE;
	v_max_dtm					DATE;
	v_end_dtm					DATE;
	v_calc_start_dtm			customer.calc_start_dtm%TYPE;
	v_calc_end_dtm				customer.calc_end_dtm%TYPE;

	v_count number;
BEGIN
	v_min_dtm := TRUNC(in_start_dtm, 'MONTH');
	v_max_dtm := ADD_MONTHS(TRUNC(in_end_dtm, 'MONTH'), 1);
	v_end_dtm := TRUNC(in_end_dtm, 'MONTH');
	--dbms_output.put_line('v_min_dtm '||v_min_dtm||'; v_max_dtm '||v_max_dtm||'; v_end_dtm '||v_end_dtm);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- Get the measure's custom field
	SELECT custom_field
	  INTO v_cust_field
	  FROM measure m, ind i
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.ind_sid = in_ind_sid
	   AND m.measure_sid = i.measure_sid;

	-- Delete anything overlapping the affected period
	DELETE FROM imp_conflict_val icv
     WHERE EXISTS(
		SELECT NULL
          FROM csr.imp_val iv
         WHERE imp_val_id = icv.imp_val_id  
		   AND EXISTS (
				SELECT NULL
                  FROM csr.VAL
                 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
                   AND region_sid = in_region_sid
                   AND ind_sid = in_ind_sid
                   AND period_start_dtm < v_end_dtm
                   AND period_end_dtm > v_min_dtm
                   AND source_type_id IN (SELECT source_type_id FROM csr.region_metric_val WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_region_sid AND ind_sid = in_ind_sid)
                   AND val_id = iv.SET_VAL_ID
			)
    ); 
	
	DELETE FROM imp_val iv
	WHERE EXISTS (SELECT NULL
					FROM VAL
				   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				     AND region_sid = in_region_sid
				     AND ind_sid = in_ind_sid
				     AND period_start_dtm < v_end_dtm
				     AND period_end_dtm > v_min_dtm
				     AND source_type_id IN (SELECT source_type_id FROM region_metric_val WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_region_sid AND ind_sid = in_ind_sid)
					 AND val_id = iv.SET_VAL_ID);

	DELETE FROM val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid
	   AND period_start_dtm < v_end_dtm
	   AND period_end_dtm > v_min_dtm
	   AND source_type_id IN (SELECT source_type_id FROM region_metric_val WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_region_sid AND ind_sid = in_ind_sid);

	-- Pre select a set of region metric values that have an effective date no sooner than 
	-- CALC_START but ensuring the any latest value beofre CALC start is still inserted into the main system
	DELETE FROM temp_region_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid;
	   
	INSERT INTO temp_region_metric_val (app_sid, region_sid, ind_sid, effective_dtm, val, note, source_type_id)
		-- Take latest entry with effective_dtm <= CALC_START and simulate an entry on CALC_START with that value
		SELECT r1.app_sid, r1.region_sid, r1.ind_sid, v_calc_start_dtm effective_dtm, r1.val, r1.note, r1.source_type_id
		  FROM region_metric_val r1
		    LEFT JOIN region_metric_val r2
		      ON (r2.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		      AND r1.ind_sid = r2.ind_sid
		      AND r1.region_sid = r2.region_sid
		      AND r2.effective_dtm <= v_calc_start_dtm
		      AND r1.effective_dtm < r2.effective_dtm
		   )
		 WHERE r1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r1.region_sid = in_region_sid
		   AND r1.ind_sid = in_ind_sid
		   AND r1.effective_dtm <= v_calc_start_dtm
		   AND r2.region_sid IS NULL
		   AND r2.ind_sid IS NULL
		UNION
		-- get everything else > CALC_START
		SELECT r1.app_sid, r1.region_sid, r1.ind_sid,
				r1.effective_dtm,
				r1.val, r1.note, r1.source_type_id
		  FROM region_metric_val r1
		 WHERE r1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r1.region_sid = in_region_sid
		   AND r1.ind_sid = in_ind_sid
		   AND r1.effective_dtm > v_calc_start_dtm
	;

	-- Get the value data
	OPEN v_cur FOR
		SELECT *
		  FROM (
			SELECT 
				region_sid,
				LEAST(effective_dtm, v_calc_end_dtm) start_dtm,
				LEAST(NVL(LEAD(effective_dtm) OVER (ORDER BY effective_dtm), v_calc_end_dtm), v_calc_end_dtm) end_dtm, -- Clamp the end dtm
				val val_number
			  FROM temp_region_metric_val
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND ind_sid = in_ind_sid
		) WHERE start_dtm < end_dtm
			ORDER BY start_dtm;

	-- Normalise the value data, we're interested in the weighted averages for the intersecting
	-- months unless the measure specifies a custom field in which case use last period...
	v_divisibility := csr_data_pkg.DIVISIBILITY_AVERAGE;
	IF v_cust_field IS NOT NULL THEN
		v_divisibility := csr_data_pkg.DIVISIBILITY_LAST_PERIOD;
	END IF;
	
	v_months_tbl := val_pkg.NormaliseToPeriodSpan(v_cur, v_min_dtm, v_max_dtm, 1, v_divisibility);

	-- ...pick out the intersecting bits we want and insert them into the val table	
	FOR r IN (
		SELECT v.effective_dtm, v.region_sid, v.start_dtm, v.val_number,
			DECODE(v.ongoing_val, NULL, v.ongoing_end_dtm, v.nv_end_dtm) end_dtm,
			v.ongoing_val, note, v.ongoing_end_dtm, v.source_type_id
		  FROM (
			SELECT rmv.effective_dtm, nv.region_sid, nv.start_dtm, nv.val_number, nv.end_dtm nv_end_dtm, 
				NVL(TRUNC(LEAD(rmv.effective_dtm) OVER (ORDER BY rmv.effective_dtm), 'MONTH'), v_calc_end_dtm) ongoing_end_dtm,
				DECODE(nv.start_dtm, rmv.effective_dtm, NULL, rmv.val) ongoing_val, rmv.note, rmv.source_type_id
			  FROM temp_region_metric_val rmv, TABLE(v_months_tbl) nv
			 WHERE rmv.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND rmv.region_sid = in_region_sid
			   AND rmv.ind_sid = in_ind_sid
			   AND rmv.effective_dtm >= in_start_dtm
			   AND rmv.effective_dtm <= v_calc_end_dtm -- need to select values for 'lead'
			   AND nv.start_dtm(+) = TRUNC(rmv.effective_dtm, 'MONTH')
		  ) v
		 WHERE start_dtm <> ongoing_end_dtm
		 ORDER BY effective_dtm
	) LOOP
		--dbms_output.put_line('intersection  effective_dtm='||r.effective_dtm||' start_dtm='||r.start_dtm||' end_dtm='||r.end_dtm||' val_number='||r.val_number||
		--	' note='||r.note||' ongoing_val='||r.ongoing_val||' ongoing_end_dtm='||r.ongoing_end_dtm||' v_max_dtm='||v_max_dtm);
		
		-- Bail out once we get to the end of the date span
		EXIT WHEN r.end_dtm > v_calc_end_dtm;

		-- If the values differ	
		IF r.ongoing_val IS NOT NULL AND r.end_dtm <> r.ongoing_end_dtm AND r.val_number != r.ongoing_val THEN
			-- Insert the weighted average values and then insert full values following
			INTERNAL_UpsertVal(in_region_sid, in_ind_sid, r.start_dtm, r.end_dtm, r.val_number, r.note, r.source_type_id);
			INTERNAL_UpsertVal(in_region_sid, in_ind_sid, r.end_dtm, r.ongoing_end_dtm, r.ongoing_val, r.note, r.source_type_id);
			v_max_dtm := GREATEST(v_max_dtm, r.ongoing_end_dtm);
		ELSE
			-- Just insert one value rather than multiple intersections with the same value
			INTERNAL_UpsertVal(in_region_sid, in_ind_sid, r.start_dtm, r.ongoing_end_dtm, r.val_number, r.note, r.source_type_id);
		END IF;

	END LOOP;
	
	calc_pkg.AddJobsForVal(
		in_ind_sid,	
		in_region_sid,
		in_start_dtm,
		in_end_dtm
	);	

END;

PROCEDURE UpdateSpaceTypeMetrics(
	in_space_type_id	in space_type_region_metric.space_type_id%type,
	in_ind_sids			in VARCHAR2
)
AS
	v_split_char	VARCHAR(1) := ',';
	v_table			ASPEN2.T_SPLIT_NUMERIC_TABLE := ASPEN2.T_SPLIT_NUMERIC_TABLE();
BEGIN
	v_table := aspen2.utils_pkg.SplitNumericString(in_ind_sids, v_split_char);
	
	FOR r IN (
		SELECT i.item ind_sid, rm.ind_sid rm_ind_sid
		  FROM TABLE(v_table) i
		  LEFT JOIN region_metric rm ON i.item = rm.ind_sid
	) LOOP
		IF r.rm_ind_sid IS NULL THEN
			SetMetric(r.ind_sid);
		END IF;
	
		BEGIN
			INSERT INTO region_type_metric (region_type, ind_sid)
			     VALUES (csr_data_pkg.REGION_TYPE_SPACE, r.ind_sid);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
	
	DELETE FROM space_type_region_metric
	      WHERE space_type_id = in_space_type_id
	        AND ind_sid NOT IN (SELECT t.item FROM TABLE(v_table) t);
	
	INSERT INTO space_type_region_metric (app_sid, space_type_id, region_type, ind_sid)
		 SELECT security.security_pkg.getapp app_sid,
				in_space_type_id space_type_id,
				csr_data_pkg.REGION_TYPE_SPACE region_type,
				t.item ind_sid
		   FROM TABLE(v_table) t
		  WHERE t.item NOT IN (SELECT ind_sid FROM space_type_region_metric WHERE space_type_id = in_space_type_id);
	
	-- clean up any region type metrics that are no longer in use
	DELETE FROM region_type_metric
	      WHERE region_type = csr_data_pkg.REGION_TYPE_SPACE
	        AND ind_sid NOT IN (SELECT ind_sid FROM space_type_region_metric);
END;

PROCEDURE GetRegionTypeLookup(
	out_cur		out		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT rt.region_type, rt.label, rt.class_name
			FROM csr.region_type rt
			JOIN csr.customer_region_type crt ON rt.region_type = crt.region_type AND crt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			ORDER BY label ASC;
END;

PROCEDURE GetAllRegionMetrics(
	out_cur						out		security_pkg.T_OUTPUT_CUR,
	out_region_types_cur		out		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT  rm.Ind_Sid, 
				rm.Is_Mandatory,
				i.Description,
				pel.pos element_pos,
				rm.show_measure
		  FROM CSR.REGION_METRIC rm
		  JOIN CSR.V$IND i ON i.IND_SID = rm.IND_SID
	 LEFT JOIN property_element_layout pel ON (i.ind_sid = pel.ind_sid) OR (i.ind_sid IS NULL AND pel.element_name = i.lookup_key);
	
	OPEN out_region_types_cur FOR
		SELECT 	Region_Type,
				Ind_Sid
			FROM CSR.REGION_TYPE_METRIC;
END;

PROCEDURE SyncFilterAggregateTypes
AS
	v_customer_aggregate_type_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT rtm.ind_sid
		  FROM region_type_metric rtm
		  JOIN ind i ON rtm.app_sid = i.app_sid AND rtm.ind_sid = i.ind_sid
		  JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		  LEFT JOIN chain.customer_aggregate_type cuat ON rtm.ind_sid = cuat.ind_sid AND cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_PROPERTY
		 WHERE m.custom_field IS NULL -- numerical ones only
		   AND rtm.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
		   AND cuat.customer_aggregate_type_id IS NULL
	) LOOP
		v_customer_aggregate_type_id := chain.filter_pkg.UNSEC_AddCustomerAggregateType(
			in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_PROPERTY,
			in_ind_sid					=> r.ind_sid
		);
	END LOOP;
	
	FOR r IN (
		SELECT customer_aggregate_type_id
		  FROM chain.customer_aggregate_type
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_PROPERTY
		   AND ind_sid IS NOT NULL
		   AND ind_sid NOT IN (
			SELECT rtm.ind_sid
			  FROM region_type_metric rtm
			  JOIN ind i ON rtm.app_sid = i.app_sid AND rtm.ind_sid = i.ind_sid
			  JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
			 WHERE m.custom_field IS NULL -- numerical ones only
			   AND rtm.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
			)
	) LOOP
		chain.filter_pkg.UNSEC_RemoveCustomerAggType(r.customer_aggregate_type_id);
	END LOOP;
END;

PROCEDURE SaveRegionMetric(
	in_ind_sid				IN	region_metric.ind_sid%TYPE,
	in_is_mandatory			IN	space_type.is_tenantable%TYPE,
	in_element_pos			IN	property_element_layout.pos%TYPE,
	in_region_types			IN	VARCHAR2,
	in_show_measure			IN	region_metric.show_measure%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_region_types_cur	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_ind_lookup_key		ind.lookup_key%TYPE;
	v_ind_description		property_element_layout.element_name%TYPE;
	v_measure_sid			region_metric.measure_sid%TYPE;
	v_records_count			NUMBER;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit region metrics');
	END IF;
	
	SELECT COUNT(ind_sid) INTO v_records_count
		FROM region_metric
		WHERE ind_sid = in_ind_sid;

	SELECT SUBSTR(description, 1, 255), lookup_key, measure_sid 
	  INTO v_ind_description, v_ind_lookup_key, v_measure_sid
	  FROM v$ind
	 WHERE ind_sid = in_ind_sid;
		
	-- if records count is 0 this is new metric
	IF v_records_count = 0 THEN
		BEGIN
			INSERT INTO region_metric (app_sid, measure_sid, ind_sid, is_mandatory, show_measure) 
				 VALUES (security.security_pkg.getapp, v_measure_sid, in_ind_sid, in_is_mandatory, in_show_measure);
		END;
	ELSE
		BEGIN
			UPDATE region_metric 
			   SET is_mandatory = in_is_mandatory,
					show_measure = in_show_measure
			 WHERE ind_sid = in_ind_sid;
		END;
	END IF;

	IF in_element_pos IS NULL THEN
		DELETE FROM property_element_layout 
			  WHERE ind_sid = in_ind_sid;
		
		IF v_ind_lookup_key IS NOT NULL THEN
			DELETE FROM property_element_layout 
			      WHERE element_name = v_ind_lookup_key;
		END IF;
	ELSE
		BEGIN
			INSERT INTO property_element_layout (element_name, pos, ind_sid)
				 VALUES (NVL(v_ind_lookup_key, v_ind_description), in_element_pos, in_ind_sid);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE property_element_layout
				   SET pos = in_element_pos
				 WHERE ind_sid = in_ind_sid
				    OR (ind_sid IS NULL AND element_name = v_ind_lookup_key);
		END;
	END IF;
	
	UpdateRegionTypeMetrics(in_ind_sid, in_region_types);	
	
	SyncFilterAggregateTypes;
	
	-- Output cursors
	OPEN out_cur FOR
		SELECT rm.ind_sid, 
			   rm.is_mandatory,
			   i.description,
			   pel.pos element_pos
		  FROM region_metric rm
		  JOIN v$ind i ON i.ind_sid = rm.ind_sid
	 LEFT JOIN property_element_layout pel ON pel.ind_sid = i.ind_sid OR (pel.ind_sid IS NULL AND pel.element_name = i.lookup_key)
		 WHERE rm.ind_sid = in_ind_sid;
	
	OPEN out_region_types_cur FOR
		SELECT region_type, ind_sid
		  FROM region_type_metric
		 WHERE ind_sid = in_ind_sid;
END;

PROCEDURE UpdateRegionTypeMetrics(
	in_ind_sid			in region_type_metric.ind_sid%type,
	in_region_types		in VARCHAR2
)
AS
	v_split_char	VARCHAR(1) := ',';
	v_table			ASPEN2.T_SPLIT_NUMERIC_TABLE := ASPEN2.T_SPLIT_NUMERIC_TABLE();
BEGIN
	v_table := aspen2.utils_pkg.SplitNumericString(in_region_types, v_split_char);
	
	DELETE FROM CSR.SPACE_TYPE_REGION_METRIC
		WHERE IND_SID = in_ind_sid
		  AND REGION_TYPE NOT IN (SELECT t.ITEM FROM TABLE(v_table) t);
	
	DELETE FROM CSR.REGION_TYPE_METRIC
		WHERE IND_SID = in_ind_sid
		  AND REGION_TYPE NOT IN (SELECT t.ITEM FROM TABLE(v_table) t);
	
	INSERT INTO CSR.REGION_TYPE_METRIC (APP_SID, REGION_TYPE, IND_SID)
		SELECT 	SECURITY.SECURITY_PKG.GETAPP APP_SID,
				t.ITEM REGION_TYPE,
				in_ind_sid IND_SID
			FROM TABLE(v_table) t
			WHERE t.ITEM NOT IN (SELECT REGION_TYPE FROM CSR.REGION_TYPE_METRIC WHERE IND_SID = in_ind_sid);
END;

PROCEDURE RefreshSystemValues
AS
BEGIN
	FOR h IN (
		SELECT DISTINCT c.host
		  FROM region_metric_val rmv
		  JOIN customer c ON rmv.app_sid = c.app_sid
	)
	LOOP
		security.user_pkg.logonadmin(h.host);
		FOR r IN (
			WITH region_metric_vals AS (
				SELECT rmv.app_sid, rmv.region_sid, rmv.ind_sid, GREATEST(c.calc_start_dtm, rmv.effective_dtm) start_dtm, rmv.source_type_id
				  FROM region_metric_val rmv
				  JOIN customer c ON rmv.app_sid = c.app_sid
				 WHERE NOT EXISTS (
					SELECT null
					  FROM csr.region_metric_val
					 WHERE app_sid = rmv.app_sid
					   AND ind_sid = rmv.ind_sid
					   AND region_sid = rmv.region_sid
					   AND effective_dtm > rmv.effective_dtm
				)
			)
			SELECT v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, c.calc_start_dtm, c.calc_end_dtm, rmv.start_dtm
			  FROM region_metric_vals rmv
			  JOIN customer c ON rmv.app_sid = c.app_sid
			  JOIN val v ON rmv.app_sid = v.app_sid AND rmv.ind_sid = v.ind_sid AND rmv.region_sid = v.region_sid
				AND TRUNC(rmv.start_dtm, 'MON') = v.period_start_dtm AND v.source_type_id = rmv.source_type_id
			 WHERE period_end_dtm < calc_end_dtm
		) LOOP
			SetSystemValues(
				in_region_sid   => r.region_sid,
				in_ind_sid      => r.ind_sid,
				in_start_dtm    => r.start_dtm,
				in_end_dtm      => r.calc_end_dtm
			);
		END LOOP;
		COMMIT;
		security.user_pkg.logonadmin();
	END LOOP;
END;

-- filter procedures
PROCEDURE FilterRegionMetricText (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_group_by_index	IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ind_sid				NUMBER;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	SELECT chain.T_FILTERED_OBJECT_ROW(rmv.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region_metric_val rmv
	  JOIN (
			SELECT region_sid, ind_sid, MAX(effective_dtm) effective_dtm
			  FROM region_metric_val crmv	-- Current
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON crmv.region_sid = t.object_id
			 WHERE ind_sid = v_ind_sid
			   AND effective_dtm <= SYSDATE
			 GROUP BY region_sid, ind_sid
		) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
	  JOIN chain.filter_value fv ON LOWER(rmv.note) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionMetricDate (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date				DATE;
	v_max_date				DATE;
	v_ind_sid				NUMBER;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(TO_DATE('30-12-1899', 'DD-MM-YYYY') + val), MAX(TO_DATE('30-12-1899', 'DD-MM-YYYY') + val)
		  INTO v_min_date, v_max_date
		  FROM region_metric_val rmv
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rmv.region_sid = t.object_id
		 WHERE rmv.ind_sid = v_ind_sid;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(rmv.region_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region_metric_val rmv
	  JOIN (
			SELECT region_sid, ind_sid, MAX(effective_dtm) effective_dtm
			  FROM region_metric_val crmv	-- Current
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON crmv.region_sid = t.object_id
			 WHERE ind_sid = v_ind_sid
			   AND effective_dtm <= SYSDATE
			 GROUP BY region_sid, ind_sid
		) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
	  JOIN chain.tt_filter_date_range dr 
		ON TO_DATE('30-12-1899', 'DD-MM-YYYY') + val >= NVL(dr.start_dtm, TO_DATE('30-12-1899', 'DD-MM-YYYY') + val)
	   AND (dr.end_dtm IS NULL OR TO_DATE('30-12-1899', 'DD-MM-YYYY') + val < dr.end_dtm)
	 WHERE TO_DATE('30-12-1899', 'DD-MM-YYYY') + val IS NOT NULL;
END;

PROCEDURE FilterRegionMetricCombo (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name 	IN chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ind_sid				NUMBER;
	v_custom_field			measure.custom_field%TYPE;
	t_custom_field			T_SPLIT_TABLE;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		SELECT custom_field
		  INTO v_custom_field
		  FROM ind i
		  JOIN measure m on i.measure_sid = m.measure_sid
		 WHERE i.ind_sid = v_ind_sid;
		
		-- If checkbox insert Yes/No as we're displaying it as a combo instead.
		IF v_custom_field = 'x' THEN
			INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.value, o.description
			  FROM (
				SELECT 1 value, 'Yes' description FROM dual
				UNION ALL SELECT 0, 'No' FROM dual
			  ) o
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = o.value
			 );
		ELSE
			t_custom_field := utils_pkg.SplitString(v_custom_field, CHR(13)||CHR(10));
			
			FOR r IN (
				SELECT t.item, t.pos
				  FROM TABLE(t_custom_field) t
				 WHERE NOT EXISTS (
					 SELECT *
					  FROM chain.filter_value fv
					 WHERE fv.filter_field_id = in_filter_field_id
					   AND fv.num_value = t.pos
				)
			)
			LOOP
				INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
				VALUES (chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, r.pos, r.item);
			END LOOP;
		END IF;
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(rmv.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region_metric_val rmv
	  JOIN (
			SELECT region_sid, ind_sid, MAX(effective_dtm) effective_dtm
			  FROM region_metric_val crmv	-- Current
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON crmv.region_sid = t.object_id
			 WHERE ind_sid = v_ind_sid
			   AND effective_dtm <= SYSDATE
			 GROUP BY region_sid, ind_sid
		) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
	  JOIN chain.filter_value fv ON rmv.val = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionMetricNumber (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ind_sid				NUMBER;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, rmv.val, rmv.val
		  FROM (
			  SELECT DISTINCT rmv.val
				FROM region_metric_val rmv
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rmv.region_sid = t.object_id
			   WHERE rmv.ind_sid = v_ind_sid
		) rmv -- numbers
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = rmv.val
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	
	
	SELECT chain.T_FILTERED_OBJECT_ROW(rmv.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region_metric_val rmv
	  JOIN (
			SELECT region_sid, ind_sid, MAX(effective_dtm) effective_dtm
			  FROM region_metric_val crmv	-- Current
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON crmv.region_sid = t.object_id
			 WHERE ind_sid = v_ind_sid
			   AND effective_dtm <= SYSDATE
			 GROUP BY region_sid, ind_sid
		) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(rmv.val, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE UNSEC_GetMetricsForRegions (
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_metrics_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_metrics_cur FOR
		SELECT rmv.region_sid, rmv.ind_sid, rmv.val, rmv.effective_dtm, rmv.note, rmv.measure_sid
		  FROM region_metric_val rmv
		  JOIN (
				SELECT region_sid, ind_sid, MAX(effective_dtm) effective_dtm
				  FROM region_metric_val crmv	-- Current
				  JOIN TABLE(in_id_list) t ON crmv.region_sid = t.sid_id
				 WHERE effective_dtm <= SYSDATE
				 GROUP BY region_sid, ind_sid
			) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm;
END;

END region_metric_pkg;
/
