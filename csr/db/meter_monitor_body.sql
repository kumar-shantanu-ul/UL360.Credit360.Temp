CREATE OR REPLACE PACKAGE BODY CSR.meter_monitor_pkg IS

FUNCTION EmptySerialIds
RETURN security_pkg.T_VARCHAR2_ARRAY
AS
	v security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	RETURN v;
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

PROCEDURE INTERNAL_DeleteValData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT v.val_id
		  FROM val v
		 WHERE v.region_sid = in_region_sid
		   AND v.ind_sid = in_ind_sid
		   AND v.source_type_id IN (
		   	csr_data_pkg.SOURCE_TYPE_METER,
		   	csr_data_pkg.SOURCE_TYPE_REALTIME_METER
		   )
	) LOOP
		INTERNAL_DeleteVal(r.val_id);
	END LOOP;
END;

FUNCTION UNSEC_ConvertMeterValue(
	in_val					IN	meter_live_data.consumption%TYPE,
	in_meter_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_data_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_date					IN	DATE
) RETURN meter_live_data.consumption%TYPE
AS
BEGIN
	-- Check to see if conversion is required
	IF (in_meter_conversion_id IS NULL AND in_data_conversion_id IS NULL) OR
		in_meter_conversion_id = in_data_conversion_id THEN
		RETURN in_val;
	END IF;
	-- Convert data unit -> base unit -> meter unit
	RETURN measure_pkg.UNSEC_GetConvertedValue(
		measure_pkg.UNSEC_GetBaseValue(in_val, in_data_conversion_id, in_date), 
		in_meter_conversion_id, in_date
	);
END;

PROCEDURE INTERNAL_RefreshCoverageAggr(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_group_id				aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	BEGIN
		v_group_id := aggregate_ind_pkg.GetGroupId('METER_COVERAGE_DAYS');
		aggregate_ind_pkg.RefreshGroup(v_group_id, TRUNC(in_start_dtm, 'DD'), TRUNC(in_end_dtm, 'DD') + 1);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- If the group was not found the coverage is not enabled, ignore
	END;
END;

FUNCTION TsWithTimeZone(
	dtm			IN	DATE, 
	tz_hours	IN	NUMBER,
	tz_minutes	IN	NUMBER
) RETURN TIMESTAMP WITH TIME ZONE
AS
	v_ts	TIMESTAMP WITH TIME ZONE;
BEGIN
	RETURN TO_TIMESTAMP_TZ(TO_CHAR(
		dtm ,'YYYY-MM-DD HH24:MI:SS ') || 
		TO_CHAR(tz_hours,'FM99') || ':' || TO_CHAR(tz_minutes,'FM00'), 
		'YYYY-MM-DD HH24:MI:SS TZH:TZM');
END;

FUNCTION TsWithTimeZone(
	dtm			IN	DATE, 
	ts_tz		IN	TIMESTAMP WITH TIME ZONE
) RETURN TIMESTAMP WITH TIME ZONE
AS
	v_ts	TIMESTAMP WITH TIME ZONE;
BEGIN
	RETURN TsWithTimeZone(dtm, EXTRACT(TIMEZONE_HOUR FROM ts_tz), EXTRACT(TIMEZONE_MINUTE FROM ts_tz));
END;

FUNCTION GetIssueUserFromSource(
	in_raw_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
BEGIN
	-- Get the default issue user from the data source
	BEGIN
		SELECT ds.default_issue_user_sid
		  INTO v_issue_user_sid
		  FROM meter_raw_data_source ds
		 WHERE ds.raw_data_source_id = in_raw_data_source_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_issue_user_sid := NULL;
	END;
	
	IF v_issue_user_sid IS NULL THEN
		v_issue_user_sid := security_pkg.GetSID;
	END IF;
	
	RETURN v_issue_user_sid;
END;

FUNCTION GetIssueUserFromRaw(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
BEGIN
	-- Get the default issue user from the data source
	BEGIN
		SELECT ds.default_issue_user_sid
		  INTO v_issue_user_sid
		  FROM meter_raw_data rd, meter_raw_data_source ds
		 WHERE rd.meter_raw_data_id = in_raw_data_id
		   AND ds.raw_data_source_id = rd.raw_data_source_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_issue_user_sid := NULL;
	END;
	
	IF v_issue_user_sid IS NULL THEN
		v_issue_user_sid := security_pkg.GetSID;
	END IF;
	   
	RETURN v_issue_user_sid;
END;

FUNCTION GetIssueUserFromRegion(
	in_region_sid			security_pkg.T_SID_ID,
	in_data_dtm				DATE
) RETURN security_pkg.T_SID_ID
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
BEGIN
	-- Get the default issue user from the region
	BEGIN  
		-- Not ideal, there might be more than one match if the data source that provides data for this region was ever changed.
		-- We're going to pick the most recent match data source match over the raw data for this region.
		SELECT default_issue_user_sid
		  INTO v_issue_user_sid
		  FROM (
			SELECT default_issue_user_sid
			  FROM (
				SELECT ds.default_issue_user_sid, rd.received_dtm, 
					MAX(received_dtm) OVER (PARTITION BY ds.raw_data_source_id) max_dtm
				  FROM meter_raw_data_source ds, meter_raw_data rd
				 WHERE ds.raw_data_source_id = rd.raw_data_source_id
				   AND in_data_dtm >= start_dtm
				   AND in_data_dtm < end_dtm
				   AND meter_raw_data_id IN (
				    	SELECT meter_raw_data_id 
					      FROM meter_live_data 
					     WHERE region_sid = in_region_sid
					)
			) WHERE received_dtm = max_dtm
		) WHERE ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_issue_user_sid := NULL;
	END;
	
	IF v_issue_user_sid IS NULL THEN
		v_issue_user_sid := security_pkg.GetSID;
	END IF;
	   
	RETURN v_issue_user_sid;
END;

-- private
FUNCTION EdielErrorToTable(
	in_msg				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_dtm				IN	T_DATE_ARRAY,
	in_sid				IN	security_pkg.T_SID_IDS
) RETURN T_EDIEL_ERROR_TABLE
AS
	v_table T_EDIEL_ERROR_TABLE := T_EDIEL_ERROR_TABLE();
BEGIN
	IF in_msg.COUNT != in_dtm.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'Message count ('||in_msg.COUNT||') does not equal dtm count ('||in_dtm.COUNT||')');
	END IF;
	
	IF in_msg.COUNT = 0 OR (in_msg.COUNT = 1 AND in_msg(in_msg.FIRST) IS NULL) THEN
	-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
	END IF;

	FOR i IN in_msg.FIRST .. in_msg.LAST
	LOOP
		v_table.extend;
		v_table(v_table.COUNT) := T_EDIEL_ERROR_ROW(i, in_msg(i), in_dtm(i), in_sid(i));
	END LOOP;
	
	RETURN v_table;
END;

FUNCTION ConsumptionDataToTable(
	in_start			IN	T_DATE_ARRAY,
	in_end				IN	T_DATE_ARRAY,
	in_consumption		IN	T_VAL_ARRAY
) RETURN T_CONSUMPTION_TABLE
AS
	v_table T_CONSUMPTION_TABLE := T_CONSUMPTION_TABLE();
BEGIN
	IF in_start.COUNT != in_end.COUNT OR in_start.COUNT != in_consumption.COUNT THEN
		-- TODO Raise exception
		RETURN v_table;
	END IF;
	
	IF in_start.COUNT = 0 OR (in_start.COUNT = 1 AND in_start(in_start.FIRST) IS NULL) THEN
	-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
	END IF;

	FOR i IN in_start.FIRST .. in_start.LAST
	LOOP
		v_table.extend;
		v_table(v_table.COUNT) := T_CONSUMPTION_ROW(i, in_start(i), in_end(i), in_consumption(i));
	END LOOP;
	
	RETURN v_table;
END;

-- DEFAULT HELPER TO MATCH SERIAL NUMBERS TO REGION SIDS
PROCEDURE HELPER_MatchSerialNumber(
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	out_region_sid			OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		-- first check all meters
		SELECT m.region_sid
		  INTO out_region_sid
		  FROM all_meter m, region r, meter_source_type mst
		 WHERE ((m.urjanet_meter_id IS NULL AND LOWER(m.reference) = LOWER(in_serial_id))
		    OR (m.urjanet_meter_id IS NOT NULL AND LOWER(m.urjanet_meter_id) = LOWER(in_serial_id)))
		   AND r.region_sid = m.region_sid
		   AND m.meter_source_type_id = mst.meter_source_type_id
		   AND r.active = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_region_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			BEGIN
				-- if multiple matches are found, just check feed-only meters
				SELECT m.region_sid
				  INTO out_region_sid
				  FROM all_meter m, region r, meter_source_type mst
				 WHERE ((m.urjanet_meter_id IS NULL AND LOWER(m.reference) = LOWER(in_serial_id))
				    OR (m.urjanet_meter_id IS NOT NULL AND LOWER(m.urjanet_meter_id) = LOWER(in_serial_id)))
				   AND r.region_sid = m.region_sid
				   AND m.meter_source_type_id = mst.meter_source_type_id
				   AND m.manual_data_entry = 0
				   AND r.active = 1;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					out_region_sid := -1;
				WHEN TOO_MANY_ROWS THEN
					RAISE_APPLICATION_ERROR(ERR_MULTIPLE_SERIAL_MATCHES, 'Multiple meters match the serial number "'||in_serial_id||'"');
			END;
	END;
END;

-- CALLER CAN USE THIS TO EXECUTE THE CORRECT HELPER FOR THE GIVEN RAW DATA ID
PROCEDURE MatchSerialNumber(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	out_region_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_helper_pkg			meter_raw_data_source.helper_pkg%TYPE;
BEGIN
	-- Fetch the helper package
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM meter_raw_data_source rds, meter_raw_data mrd
	 WHERE mrd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mrd.meter_raw_data_id = in_raw_data_id
	   AND rds.raw_data_source_id = mrd.raw_data_source_id;
	
	-- Try and match the serial id to a region sid (outputs -1 if not found)   
	EXECUTE IMMEDIATE 'BEGIN '||v_helper_pkg||'.HELPER_MatchSerialNumber(:1,:2);END;' USING IN in_serial_id, OUT out_region_sid;
END;

PROCEDURE MatchSerialNumber(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	out_match				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	-- Try and match the serial number
	MatchSerialNumber(in_raw_data_id, in_serial_id, v_region_sid);
	
	-- Return some extended information about the matched meter
	-- TODO: need to return extended information for each meter input (the caller needs to understand this)
	OPEN out_match FOR
		SELECT am.region_sid, r.description region_desc
		  FROM all_meter am, v$region r
		 WHERE am.region_sid = v_region_sid
		   AND r.region_sid = am.region_sid;
END;

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_file_name			IN	meter_raw_data.file_name%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	in_imp_instance_id		IN 	NUMBER,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
)
AS
	v_raw_data_source_id	meter_raw_data_source.raw_data_source_id%TYPE;
BEGIN
	-- Avoid multiple raw data rows for a single auto import instance id
	BEGIN
		SELECT meter_raw_data_id
		  INTO out_raw_data_id
		  FROM meter_raw_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_instance_id = in_imp_instance_id;

		UPDATE meter_raw_data
		   SET file_name = NVL(in_file_name, file_name),
		       mime_type = NVL(in_mime_type, mime_type),
		       data = in_data
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = out_raw_data_id;

		AuditRawDataChange(
			out_raw_data_id,
			'Raw data updated by automated import instance id '||in_imp_instance_id
		);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- No existing raw data for this auto import instance
			out_raw_data_id := NULL;
	END;

	IF out_raw_data_id IS NULL THEN
		-- Insert a new raw data row
		InsertRawData(in_data_source_id, in_mime_type, in_encoding_name, null, in_file_name, in_data, RAW_DATA_STATUS_NEW, out_raw_data_id);
		
		-- Set the automated import instance id on the raw data table
		UPDATE meter_raw_data
		   SET automated_import_instance_id = in_imp_instance_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = out_raw_data_id;
	END IF;
END;

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_message_uid			IN	meter_raw_data.message_uid%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	InsertRawData(in_data_source_id, in_mime_type, in_encoding_name, in_message_uid, null, in_data, RAW_DATA_STATUS_NEW, out_raw_data_id);
END;

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_file_name			IN	meter_raw_data.file_name%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	InsertRawData(in_data_source_id, in_mime_type, in_encoding_name, null, in_file_name, in_data, RAW_DATA_STATUS_NEW, out_raw_data_id);
END;

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_message_uid			IN	meter_raw_data.message_uid%TYPE,
	in_file_name			IN	meter_raw_data.file_name%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	in_status_id			IN  meter_raw_data.status_id%TYPE DEFAULT RAW_DATA_STATUS_NEW,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	INSERT INTO meter_raw_data
		(meter_raw_data_id, raw_data_source_id, status_id, received_dtm, 
			encoding_name, message_uid, mime_type, file_name, data)
	VALUES 
		(meter_raw_data_id_seq.NEXTVAL, in_data_source_id, in_status_id, SYSDATE, 
			in_encoding_name, in_message_uid, in_mime_type, in_file_name, in_data)
	RETURNING meter_raw_data_id INTO out_raw_data_id;

	AuditRawDataChange(
		out_raw_data_id,
		'New raw data file created'
	);
END;

PROCEDURE SetRawDataDateRange(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_start_dtm			IN	meter_raw_data.start_dtm%TYPE,
	in_end_dtm				IN	meter_raw_data.end_dtm%TYPE
)
AS
BEGIN
	UPDATE meter_raw_data
	   SET start_dtm = in_start_dtm,
	   	   end_dtm = in_end_dtm
	 WHERE meter_raw_data_id = in_raw_data_id;
END;

PROCEDURE ClearInsertData
AS
BEGIN
	DELETE FROM meter_insert_data;
END;

PROCEDURE PrepareInsertData(
	in_start_dtm					IN	TIMESTAMP WITH TIME ZONE,
	in_end_dtm						IN	TIMESTAMP WITH TIME ZONE,
	in_consumption					IN	meter_live_data.consumption%TYPE,
	in_note							IN	meter_insert_data.note%TYPE,
	in_meter_input_lookup_key		IN  meter_input.lookup_key%TYPE,
	in_source_row					IN	meter_insert_data.source_row%TYPE DEFAULT NULL,
	in_statement_id					IN	meter_source_data.statement_id%TYPE DEFAULT NULL
)
AS
	v_meter_input_id				meter_input.meter_input_id%TYPE;
BEGIN
	-- Find the input type 
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = NVL(in_meter_input_lookup_key, 'CONSUMPTION');
	
	INSERT INTO meter_insert_data 
	 	(meter_input_id, start_dtm, end_dtm, consumption, source_row, note, statement_id) 
	  VALUES(v_meter_input_id, in_start_dtm, in_end_dtm, in_consumption, in_source_row, in_note, in_statement_id);
END;


PROCEDURE PrepareInsertData(
	in_start_dtm					IN	TIMESTAMP WITH TIME ZONE,
	in_end_dtm						IN	TIMESTAMP WITH TIME ZONE,
	in_consumption					IN	meter_live_data.consumption%TYPE,
	in_note							IN	meter_insert_data.note%TYPE,
	in_meter_input_id				IN  meter_input.meter_input_id%TYPE,
	in_source_row					IN	meter_insert_data.source_row%TYPE,
	in_priority						IN  meter_insert_data.priority%TYPE,
	in_statement_id					IN	meter_source_data.statement_id%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO meter_insert_data 
	 	(meter_input_id, start_dtm, end_dtm, consumption, source_row, priority, note, statement_id) 
	  VALUES(in_meter_input_id, in_start_dtm, in_end_dtm, in_consumption, in_source_row, in_priority, in_note, in_statement_id);
END;

PROCEDURE InsertOrphanData(
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_uom					IN	meter_orphan_data.uom%TYPE,
	in_is_estimate			IN  NUMBER,
	in_error_type_id		IN	duff_meter_error_type.error_type_id%TYPE,
	in_has_overlap			IN	NUMBER DEFAULT 0,
	in_region_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm			IN	meter_orphan_data.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm				IN	meter_orphan_data.end_dtm%TYPE DEFAULT NULL
)
AS
	v_default_priority				meter_data_priority.priority%TYPE;
BEGIN
	-- Get the priority based on whether or not its an estimate - if it is, 
	-- then its low res, else its high res
	SELECT priority
	  INTO v_default_priority
	  FROM meter_data_priority
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_input = 1
	   AND ((in_is_estimate = 0 AND lookup_key = 'HI_RES')
	    OR (in_is_estimate = 1 AND lookup_key = 'ESTIMATE'));
	   
	-- Insert the orphan data
	FOR r IN (
		SELECT meter_input_id, start_dtm, end_dtm, consumption, priority, note, statement_id
		  FROM meter_insert_data
		 WHERE start_dtm = NVL(in_start_dtm, start_dtm)
		   AND end_dtm = NVL(in_end_dtm, end_dtm)
	) LOOP
		BEGIN
			INSERT INTO meter_orphan_data
				(serial_id, meter_input_id, priority, start_dtm, end_dtm, consumption, uom, note, meter_raw_data_id, error_type_id, has_overlap, region_sid, statement_id)
			  VALUES (in_serial_id, r.meter_input_id, NVL(r.priority, v_default_priority), r.start_dtm, r.end_dtm, 
			  	r.consumption, in_uom, r.note, in_raw_data_id, in_error_type_id, in_has_overlap, in_region_sid, r.statement_id);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE meter_orphan_data
				   SET consumption = r.consumption,
				   	   uom = in_uom,
				   	   note = r.note,
				   	   meter_raw_data_id = in_raw_data_id,
				   	   error_type_id = in_error_type_id,
				   	   has_overlap = DECODE(has_overlap, 0, in_has_overlap, has_overlap), -- Preserve existing overlap flag
				   	   region_sid = NVL(in_region_sid, region_sid), -- Preserve region sid
				   	   statement_id = r.statement_id
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND serial_id = in_serial_id
				   AND meter_input_id = r.meter_input_id
				   AND priority = NVL(r.priority, v_default_priority)
				   AND start_dtm = r.start_dtm
				   AND end_dtm = r.end_dtm;
		END;		
	END LOOP;
	
	-- Update orphan/matched counts
	UpdateRawDataOrphanCount(in_raw_data_id);
END;

PROCEDURE INTERNAL_UpsertSrcData(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_input_id					IN	meter_input.meter_input_id%TYPE,
	in_priority					IN	meter_data_priority.priority%TYPE,
	in_raw_data_id				IN	meter_source_data.meter_raw_data_id%TYPE,
	in_uom						IN	meter_source_data.raw_uom%TYPE,
	in_meter_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_data_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_start_dtm				IN	meter_source_data.start_dtm%TYPE,
	in_end_dtm					IN	meter_source_data.end_dtm%TYPE,
	in_consumption				IN	meter_source_data.consumption%TYPE,
	in_note						IN	meter_source_data.note%TYPE,
	in_source_row				IN	meter_insert_data.source_row%TYPE DEFAULT NULL,
	in_statement_id				IN	meter_source_data.statement_id%TYPE DEFAULT NULL
)
AS
	v_consumption					meter_source_data.consumption%TYPE;
BEGIN
	-- Convert consumption value (conversion only takes place if required)
	v_consumption := UNSEC_ConvertMeterValue(in_consumption, in_meter_conversion_id, in_data_conversion_id, in_start_dtm);

	-- Special processing for urjanet data with a statement id (arrgh again)
	-- Remove anything that matches (from any file) but has a different statement id
	IF in_statement_id IS NOT NULL THEN
		DELETE FROM meter_source_data
		 WHERE region_sid = in_region_sid
		   AND meter_input_id = in_input_id
		   AND priority = in_priority
		   AND end_dtm = in_end_dtm
		   AND (
			-- start_dtm could be null (urjanet kludge thing):
			   start_dtm = in_start_dtm
			OR start_dtm IS NULL AND in_start_dtm IS NULL
		   )
		   AND (
			-- statement id does *not* match or raw data id does *not* match
			   DECODE(statement_id, in_statement_id, NULL, 1) = 1
			OR DECODE (meter_raw_data_id, in_raw_data_id, NULL, 1) = 1
		   );
	END IF;
	
	BEGIN
		INSERT INTO meter_source_data
			(region_sid, meter_input_id, priority, start_dtm, end_dtm, raw_uom, raw_consumption, consumption, note, meter_raw_data_id, statement_id)
		  VALUES (in_region_sid, in_input_id, in_priority, in_start_dtm, in_end_dtm, in_uom, in_consumption, v_consumption, in_note, in_raw_data_id, in_statement_id);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE meter_source_data
			   SET raw_uom = in_uom,
			   	   raw_consumption = in_consumption,
			   	   consumption = v_consumption,
			   	   note = in_note,
			   	   meter_raw_data_id = in_raw_data_id,
			   	   statement_id = in_statement_id
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = in_input_id
			   AND priority = in_priority
			   AND start_dtm = in_start_dtm
			   AND end_dtm = in_end_dtm;
	END;
END;

FUNCTION INTRNL_UpsertSrcDataOverlapChk(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_input_id					IN	meter_input.meter_input_id%TYPE,
	in_priority					IN	meter_data_priority.priority%TYPE,
	in_raw_data_id				IN	meter_source_data.meter_raw_data_id%TYPE,
	in_uom						IN	meter_source_data.raw_uom%TYPE,
	in_meter_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_data_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_start_dtm				IN	meter_source_data.start_dtm%TYPE,
	in_end_dtm					IN	meter_source_data.end_dtm%TYPE,
	in_consumption				IN	meter_source_data.consumption%TYPE,
	in_note						IN	meter_source_data.note%TYPE,
	in_source_row				IN	meter_insert_data.source_row%TYPE DEFAULT NULL,
	in_statement_id				IN	meter_source_data.statement_id%TYPE DEFAULT NULL,
	in_raise_issues				IN	NUMBER DEFAULT 1
) RETURN BOOLEAN
AS
	v_issue_id						issue.issue_id%TYPE;
	v_error_msg						VARCHAR(4000);
	v_start_dtm						TIMESTAMP WITH TIME ZONE;
	v_end_dtm						TIMESTAMP WITH TIME ZONE;
BEGIN
	IF in_start_dtm > in_end_dtm THEN
		v_start_dtm := in_start_dtm;
		v_end_dtm := in_end_dtm;
		v_error_msg := 'Invalid reading period';
	ELSE 
		-- Check that the entry does not overlap with an existing period
		-- Explicit UNION here for performance, rahter than using the merged view
		FOR r IN (
			SELECT /*+ FIRST_ROWS(1) */
				start_dtm, end_dtm
			  FROM meter_source_data
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = in_input_id
			   AND priority = in_priority
			   AND end_dtm > in_start_dtm
			   AND start_dtm < in_end_dtm
			   AND rownum = 1
		) LOOP
			-- Exact matches are okay - these entries just get replaced
			-- It's quite a bit quicker to check this in the loop rather than determine it in the loop query
			IF NOT (in_start_dtm = r.start_dtm AND in_end_dtm = r.end_dtm) THEN
				v_start_dtm := in_start_dtm;
				v_end_dtm := in_end_dtm;
				v_error_msg := 'Incoming source period overlaps with existing data';
			END IF;
		END LOOP;
	END IF;

	IF v_error_msg IS NOT NULL THEN
		IF in_source_row IS NOT NULL THEN
			-- Hmmm, formatted date string string ends up in meter error message too
			UPDATE meter_insert_data SET error_msg = v_error_msg || ' (' || TO_CHAR(v_start_dtm, ISO_DATE_TIME_FORMAT) || ' - ' ||  TO_CHAR(v_start_dtm, ISO_DATE_TIME_FORMAT) || ')'
			 WHERE source_row = in_source_row;
		END IF;

		IF in_raise_issues = 1 AND in_raw_data_id IS NOT NULL THEN
			AddRawDataIssue(
				in_raw_data_id	=>	in_raw_data_id, 
				in_region_sid	=>	in_region_sid, 
				in_label		=>	'RAW DATA PROCESSOR: ' || v_error_msg,
				in_start_dtm	=>	v_start_dtm,
				in_end_dtm		=>	v_end_dtm,
				out_issue_id	=>	v_issue_id
			);
		END IF;

		RETURN FALSE;
	END IF;

	INTERNAL_UpsertSrcData(
		in_region_sid			=> in_region_sid,
		in_input_id				=> in_input_id,
		in_priority				=> in_priority,
		in_raw_data_id			=> in_raw_data_id,
		in_uom					=> in_uom,
		in_meter_conversion_id	=> in_meter_conversion_id,
		in_data_conversion_id	=> in_data_conversion_id,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_consumption			=> in_consumption,
		in_note					=> in_note,
		in_statement_id			=> in_statement_id,
		in_source_row			=> in_source_row
	);
	RETURN TRUE;
END;

PROCEDURE INTERNAL_UpsertReadingData(
	in_region_sid				IN	security_pkg.T_SID_ID, 
	in_input_id					IN	meter_input.meter_input_id%TYPE,
	in_priority					IN	meter_data_priority.priority%TYPE,
	in_raw_data_id				IN	meter_reading_data.meter_raw_data_id%TYPE,
	in_raw_uom	 				IN	meter_reading_data.raw_uom%TYPE,
	in_meter_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_data_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_reading_dtm	 			IN	meter_reading_data.reading_dtm%TYPE,
	in_raw_val	 				IN	meter_reading_data.raw_val%TYPE,
	in_note						IN	meter_reading_data.note%TYPE
)
AS
	v_val						meter_reading_data.val%TYPE;
BEGIN
	v_val := UNSEC_ConvertMeterValue(in_raw_val, in_meter_conversion_id, in_data_conversion_id, in_reading_dtm);
	
	BEGIN
		INSERT INTO meter_reading_data
			(region_sid, meter_input_id, priority, reading_dtm, raw_uom, raw_val, meter_raw_data_id, val, note)
		  VALUES (in_region_sid, in_input_id, in_priority, in_reading_dtm, in_raw_uom, in_raw_val, in_raw_data_id, v_val, in_note);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE meter_reading_data
			   SET raw_uom = in_raw_uom,
			   	   raw_val = in_raw_val,
			   	   meter_raw_data_id = in_raw_data_id,
			   	   val = v_val,
			   	   note = in_note
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = in_input_id
			   AND priority = in_priority
			   AND reading_dtm = in_reading_dtm;
	END;
END;

PROCEDURE INTERNAL_ReadingsToConsumption(
	in_region_sid			IN		security_pkg.T_SID_ID,
	inout_min_dtm			IN OUT	TIMESTAMP WITH TIME ZONE, 
	in_max_dtm				IN		TIMESTAMP WITH TIME ZONE,
	in_meter_conversion_id	IN		measure_conversion.measure_conversion_id%TYPE,
	in_data_conversion_id	IN		measure_conversion.measure_conversion_id%TYPE
)
AS
	v_min_reading_dtm		TIMESTAMP WITH TIME ZONE;
BEGIN
	SELECT /*+ INDEX(METER_READING_DATA IX_METRDNG_RGNDTM) */
		MAX(reading_dtm) 
	  INTO v_min_reading_dtm
	  FROM meter_reading_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND reading_dtm < inout_min_dtm;
	
	FOR r IN (
		SELECT meter_input_id, priority, meter_raw_data_id, raw_uom, note,
			LAG(reading_dtm) OVER (PARTITION BY meter_input_id, priority ORDER BY reading_dtm) start_dtm, 
			reading_dtm end_dtm, raw_val - LAG(raw_val) OVER (PARTITION BY meter_input_id, priority ORDER BY reading_dtm) consumption
		  FROM meter_reading_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND reading_dtm >= NVL(v_min_reading_dtm, inout_min_dtm)
		   AND reading_dtm <= in_max_dtm
	) LOOP
		IF r.consumption IS NOT NULL THEN
			-- The UK on the table now includes end_dtm, so we need
			-- to deal with same start_dtm, different end_dtm here as
			-- the reading with the stme start_dtm will not automatically
			-- overwrite the old reading (with a different end_dtm) 
			-- when it's upserted.
			DELETE FROM meter_source_data
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
			   AND meter_input_id = r.meter_input_id
			   AND priority = r.priority
			   AND start_dtm = r.start_dtm
			   AND end_dtm != r.end_dtm;

			-- Point in time data is upserted without the overlap check
			INTERNAL_UpsertSrcData(
				in_region_sid			=> in_region_sid,
				in_input_id				=> r.meter_input_id,
				in_priority				=> r.priority,
				in_raw_data_id			=> r.meter_raw_data_id,
				in_uom					=> r.raw_uom,
				in_meter_conversion_id	=> in_meter_conversion_id,
				in_data_conversion_id	=> in_data_conversion_id,
				in_start_dtm			=> r.start_dtm,
				in_end_dtm				=> r.end_dtm,
				in_consumption			=> r.consumption,
				in_note					=> r.note
			);
			
			inout_min_dtm := LEAST(r.start_dtm, inout_min_dtm);

		END IF;
	END LOOP;
END;

PROCEDURE INTERNAL_UrjKludgeChkPHolders (
	in_region_sid			IN		security_pkg.T_SID_ID,
	in_meter_input_id		IN		meter_input.meter_input_id%TYPE,
	inout_min_raw_dtm		IN OUT	TIMESTAMP WITH TIME ZONE
)
AS
BEGIN
	-- Modify any overlaps caused by a new end_dtm reading being inserted into an existing reading's date range 
	-- (this will cause the start_dtm to be the same and the end dates to differ)
	FOR r IN (
		SELECT DISTINCT sd1.end_dtm new_start_dtm, sd2.start_dtm old_start_dtm, sd2.end_dtm, sd2.priority
		  FROM meter_source_data sd1
		  JOIN meter_source_data sd2 
				ON sd2.app_sid = sd1.app_sid 
			   AND sd2.region_sid = sd1.region_sid
			   AND sd2.meter_input_id = sd1.meter_input_id
			   AND sd2.priority = sd1.priority
			   AND sd2.start_dtm = sd1.start_dtm
			   AND sd2.end_dtm > sd1.end_dtm
		 WHERE sd1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND sd1.region_sid = in_region_sid
		   AND sd1.meter_input_id = in_meter_input_id
	) LOOP

		-- Update the overlapping reading
		UPDATE meter_source_data
		   SET start_dtm = r.new_start_dtm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND meter_input_id = in_meter_input_id
		   AND priority = r.priority
		   AND start_dtm = r.old_start_dtm
		   AND end_dtm = r.end_dtm;

		 -- Ensure the min dtm is up-to-date
		inout_min_raw_dtm := LEAST(NVL(inout_min_raw_dtm, r.new_start_dtm), r.new_start_dtm);

	END LOOP;

	-- Check for place-holders (start_dtm = end_dtm) which might need updating
	FOR p IN (
		SELECT DISTINCT priority, start_dtm, end_dtm
		  FROM (
			SELECT priority, LAG(end_dtm) OVER (PARTITION BY priority ORDER BY end_dtm) start_dtm, end_dtm,
				DECODE(start_dtm, end_dtm, 1, 0) is_placeholder
			  FROM meter_source_data
			 WHERE region_sid = in_region_sid
			   AND meter_input_id = in_meter_input_id
		 )
		 WHERE is_placeholder = 1
		 ORDER BY priority, end_dtm
	) LOOP
		IF p.start_dtm IS NOT NULL THEN
			
			-- Update the start date on the placeholder
			UPDATE meter_source_data
			   SET start_dtm = p.start_dtm
			 WHERE region_sid = in_region_sid
			   AND meter_input_id = in_meter_input_id
			   AND priority = p.priority
			   AND start_dtm = p.end_dtm
			   AND end_dtm = p.end_dtm;

			-- Ensure the min dtm is up-to-date
			inout_min_raw_dtm := LEAST(NVL(inout_min_raw_dtm, p.start_dtm), p.start_dtm);
		END IF;
	END LOOP;
END;

PROCEDURE InsertLiveData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_uom					IN	meter_orphan_data.uom%TYPE,
	in_is_estimate			IN  NUMBER,
	in_raise_issues			IN	NUMBER DEFAULT 1
)
AS
	v_default_priority		meter_data_priority.priority%TYPE;
	v_min_raw_dtm			TIMESTAMP WITH TIME ZONE;	
	v_max_raw_dtm			TIMESTAMP WITH TIME ZONE;
	v_meter_conversion_id	measure_conversion.measure_conversion_id%TYPE;
	v_data_conversion_id	measure_conversion.measure_conversion_id%TYPE;

	v_serial_id				VARCHAR2(256);

	v_allow_null_start_dtm	NUMBER(1);
	v_start_dtm				TIMESTAMP WITH TIME ZONE;
	v_end_dtm				TIMESTAMP WITH TIME ZONE;

	v_issue_id				issue.issue_id%TYPE;
	v_error_msg				VARCHAR(4000);
	v_has_error				BOOLEAN;

	v_error_id				NUMBER(10);
BEGIN
	-- Urjanet kludge (allow null start dtm)?
	SELECT st.allow_null_start_dtm
	  INTO v_allow_null_start_dtm
	  FROM all_meter m
	  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.region_sid = in_region_sid;

	-- More urjanet kludging.
	-- Remove any existing data in the meter_source_data table for this region and product (UOM) which already came from this file.
	-- We have to filter by UOM here as this procedure may get called more than once for a given region/file if there are several products (UOMs) to insert.
	DELETE FROM meter_source_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_raw_data_id
	   AND region_sid = in_region_sid
	   AND raw_uom = in_uom
	   AND statement_id IS NOT NULL;

	-- Get the priority based on whether or not its an estimate
	SELECT priority
	  INTO v_default_priority
	  FROM meter_data_priority
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_input = 1
	   AND ((in_is_estimate = 0 AND lookup_key = 'HI_RES')
	    OR (in_is_estimate = 1 AND lookup_key = 'ESTIMATE'));
	
	-- Log errors if there are data in the insert table specifying inputs that are not mapped for this meter
	FOR e IN (
		SELECT DISTINCT mi.meter_input_id, mi.label
		  FROM meter_insert_data d
		  JOIN meter_input mi ON mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mi.meter_input_id = d.meter_input_id
		  LEFT JOIN meter_input_aggr_ind ai ON ai.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ai.region_sid = in_region_sid AND ai.meter_input_id = mi.meter_input_id
		 WHERE ai.region_sid IS NULL
	) LOOP
		LogRawDataError(
			in_raw_data_id		=> in_raw_data_id,
			in_region_sid		=> in_region_sid,
			in_error_message	=> 'WARNING: Data present for meter input "'||e.label||'" ('||e.meter_input_id||') but meter with region sid '||in_region_sid||' does not have a meter input type mapping for that input.',
			in_error_dtm		=> SYSDATE,
			out_error_id		=> v_error_id
		);
	END LOOP;

	-- For each input type (in-use by this meter)
	FOR i IN (
		SELECT DISTINCT d.meter_input_id, mi.is_consumption_based
		  FROM meter_insert_data d
		  JOIN meter_input mi ON mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mi.meter_input_id = d.meter_input_id
		  JOIN meter_input_aggr_ind ai ON ai.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ai.region_sid = in_region_sid AND ai.meter_input_id = mi.meter_input_id
	) LOOP
	
		-- Try to find the correct conversion for the given uom
		FindMeterConversion(in_region_sid, i.meter_input_id, in_uom, v_meter_conversion_id, v_data_conversion_id);
		
		-- Get the min and max raw dates
		SELECT MIN(NVL(start_dtm, end_dtm)), MAX(end_dtm)
		  INTO v_min_raw_dtm, v_max_raw_dtm
		  FROM meter_insert_data
		 WHERE meter_input_id = i.meter_input_id;
		
		-- Determine if we are we dealing with consumption 
		-- data or point in time meter reading data
		IF v_max_raw_dtm IS NULL /*OR i.is_consumption_based = 0*/ THEN
			
			-- This is "point in time" reading data.
			-- Insert the reading data into the meter_reading_data table.
			FOR r IN (
				SELECT start_dtm, consumption, priority, note
				  FROM meter_insert_data
				 WHERE meter_input_id = i.meter_input_id
			) LOOP
				-- Insert the reading data
				INTERNAL_UpsertReadingData(in_region_sid, i.meter_input_id, NVL(r.priority, v_default_priority), 
					in_raw_data_id, in_uom, v_meter_conversion_id, v_data_conversion_id, r.start_dtm, r.consumption, r.note);
			END LOOP;
			
			-- Get a valid max dtm
			SELECT MAX(start_dtm)
			  INTO v_max_raw_dtm
			  FROM meter_insert_data
			 WHERE meter_input_id = i.meter_input_id;
			
			-- If the data is "consumption based" then convert it into consumption data, eg:
			-- 	Power => consumption based
			-- 	Cost => consumption based
			-- 	Temperature => not consumption based
			IF i.is_consumption_based != 0 THEN
				-- Process the data into a set of consumptions and insert those consumption
				-- figures into the meter_source_data table for further processing.
				INTERNAL_ReadingsToConsumption(in_region_sid, v_min_raw_dtm, v_max_raw_dtm, v_meter_conversion_id, v_data_conversion_id);
			END IF;
			
		ELSE
			-- This is consumption based data, insert it 
			-- directly into the meter_source_data table.
			FOR r IN (
				SELECT start_dtm, end_dtm, consumption, source_row, priority, note, statement_id
				  FROM meter_insert_data
				 WHERE meter_input_id = i.meter_input_id
				 ORDER BY priority, start_dtm
			) LOOP

				v_has_error := FALSE;
				v_start_dtm := r.start_dtm;

				-- IS this "urjanet kludge" type data?
				IF r.start_dtm IS NULL AND r.end_dtm IS NOT NULL THEN
					-- Is the kludge allowed for this meter?
					IF v_allow_null_start_dtm = 0  THEN
						v_has_error := TRUE;
						v_error_msg := 'Null start date/time not allowed for this meter';
						-- Mark the row in error (is possible)
						IF r.source_row IS NOT NULL THEN
							UPDATE meter_insert_data SET error_msg = v_error_msg
							 WHERE source_row = r.source_row;
						END IF;
						-- Raise an issue if required
						IF in_raise_issues = 1 AND in_raw_data_id IS NOT NULL THEN
							AddRawDataIssue(
								in_raw_data_id	=>	in_raw_data_id, 
								in_region_sid	=>	in_region_sid, 
								in_label		=>	'RAW DATA PROCESSOR: ' || v_error_msg,
								in_start_dtm	=>	r.start_dtm,
								in_end_dtm		=>	r.end_dtm,
								out_issue_id	=>	v_issue_id
							);
						END IF;
					ELSE
						-- Try and determine a start date for the reading
						-- GO FOR OVERLAPPING READING'S START DATE
						BEGIN
							SELECT DISTINCT start_dtm
							  INTO v_start_dtm
							  FROM meter_source_data
							 WHERE region_sid = in_region_sid
							   AND meter_input_id = i.meter_input_id
							   AND priority = NVL(r.priority, v_default_priority)
							   AND start_dtm < r.end_dtm
							   AND end_dtm >= r.end_dtm;
						EXCEPTION 
							WHEN NO_DATA_FOUND THEN
								-- GO FOR PREVIOUS READING'S END DATE
								BEGIN
									SELECT end_dtm
									  INTO v_start_dtm
									  FROM (
										SELECT DISTINCT end_dtm
										  FROM meter_source_data
										 WHERE region_sid = in_region_sid
										   AND meter_input_id = i.meter_input_id
										   AND priority = NVL(r.priority, v_default_priority)
										   AND end_dtm < r.end_dtm
										 ORDER BY end_dtm DESC 
									 ) WHERE ROWNUM = 1;
								EXCEPTION
									WHEN NO_DATA_FOUND THEN
										-- We want it to insert a place-holder reading with no time span
										v_start_dtm := r.end_dtm;
								END;
						END;

						-- Urjanet kludge - don't error on overlaps
						INTERNAL_UpsertSrcData(
							in_region_sid			=>	in_region_sid,
							in_input_id				=>	i.meter_input_id,
							in_priority				=>	NVL(r.priority, v_default_priority),
							in_raw_data_id			=>	in_raw_data_id,
							in_uom					=>	in_uom,
							in_meter_conversion_id	=>	v_meter_conversion_id,
							in_data_conversion_id	=>	v_data_conversion_id,
							in_start_dtm			=>	v_start_dtm,
							in_end_dtm				=>	r.end_dtm,
							in_consumption			=>	r.consumption,
							in_note					=>	r.note,
							in_source_row			=>	r.source_row,
							in_statement_id			=>	r.statement_id
						);
					END IF;
				ELSE
					-- Normal upsert with overlap check
					IF NOT INTRNL_UpsertSrcDataOverlapChk(
						in_region_sid			=>	in_region_sid,
						in_input_id				=>	i.meter_input_id,
						in_priority				=>	NVL(r.priority, v_default_priority),
						in_raw_data_id			=>	in_raw_data_id,
						in_uom					=>	in_uom,
						in_meter_conversion_id	=>	v_meter_conversion_id,
						in_data_conversion_id	=>	v_data_conversion_id,
						in_start_dtm			=>	v_start_dtm,
						in_end_dtm				=>	r.end_dtm,
						in_consumption			=>	r.consumption,
						in_note					=>	r.note,
						in_source_row			=>	r.source_row,
						in_statement_id			=>	r.statement_id,
						in_raise_issues			=>	in_raise_issues
					) AND in_raw_data_id IS NOT NULL THEN
						-- Find the serial ID of the meter
						SELECT NVL(urjanet_meter_id, reference)
						  INTO v_serial_id
						  FROM all_meter
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND region_sid = in_region_sid;
						-- Orphan the overlapping data row
						InsertOrphanData(v_serial_id, in_raw_data_id, in_uom, in_is_estimate, 
							meter_duff_region_pkg.DUFF_METER_OVERLAP,  1 /*has_overlap*/, 
							in_region_sid, v_start_dtm, r.end_dtm);
					END IF;
				END IF;

				-- If null start dtms are allowed for this meter we should check for placeholders etc.
				IF v_allow_null_start_dtm != 0 THEN
					INTERNAL_UrjKludgeChkPHolders(
						in_region_sid		=> in_region_sid,
						in_meter_input_id	=> i.meter_input_id,
						inout_min_raw_dtm	=> v_min_raw_dtm
					);
				END IF;

			END LOOP;

		END IF;
	END LOOP;
	
	
	-- v_min_raw_dtm will be null if there's nothing to do 
	-- (none of the inputs matched this meter for example)
	IF v_min_raw_dtm IS NOT NULL THEN
		-- Compute all the affected periodic data from the new raw data
		ComputePeriodicDataFromRaw(in_region_sid, v_min_raw_dtm, v_max_raw_dtm, in_raw_data_id);
	END IF;
	
	-- Update orphan/matched counts
	UpdateRawDataOrphanCount(in_raw_data_id);

END;

PROCEDURE ComputePeriodicDataFromRaw(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_raw_dtm			IN	TIMESTAMP WITH TIME ZONE,
	in_max_raw_dtm			IN	TIMESTAMP WITH TIME ZONE,
	in_raw_data_id			IN	meter_orphan_data.meter_raw_data_id%TYPE
)
AS
	v_min_dtm				TIMESTAMP WITH TIME ZONE;
	v_max_dtm				TIMESTAMP WITH TIME ZONE;
BEGIN
	-- We need to put enough data into the temp table to cover 
	-- the widest date range over all intersecting buckets
	v_min_dtm := TsWithTimeZone(GetMinBucketBound(in_min_raw_dtm, 1), in_min_raw_dtm);
	v_max_dtm := TsWithTimeZone(GetMaxBucketBound(in_max_raw_dtm, 1), in_max_raw_dtm);
	
	-- Ensure the temp table is clean for this region
	DELETE FROM temp_meter_consumption
	 WHERE region_sid = in_region_sid;
	
	-- Fill in the temp table from the raw source data
	FOR i IN (
		SELECT DISTINCT i.meter_input_id, i.is_consumption_based
		  FROM meter_input i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.is_virtual = 0
	) LOOP
		IF i.is_consumption_based = 0 THEN
			-- Insert point like data
			INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, raw_data_id)
				-- Data can be in reading_data...
				SELECT in_region_sid, meter_input_id, priority, CAST(reading_dtm AS DATE), CAST(reading_dtm AS DATE), val, meter_raw_data_id
				  FROM meter_reading_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_input_id = i.meter_input_id
				   AND reading_dtm >= v_min_dtm
				   AND reading_dtm <= v_max_dtm
				UNION
				-- Or data can be in source_data
				SELECT in_region_sid, meter_input_id, priority, CAST(start_dtm AS DATE), CAST(end_dtm AS DATE), consumption, meter_raw_data_id
				  FROM v$aggr_meter_source_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_input_id = i.meter_input_id
				   AND start_dtm < v_max_dtm
				   AND end_dtm > v_min_dtm
				   AND start_dtm != end_dtm;
		ELSE
			-- Insert consumption like data
			INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number, raw_data_id)
				-- We can now throw away the time-zone part
				SELECT in_region_sid, meter_input_id, priority, CAST(start_dtm AS DATE), CAST(end_dtm AS DATE), consumption, meter_raw_data_id
				  FROM v$aggr_meter_source_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_input_id = i.meter_input_id
				   AND start_dtm < v_max_dtm
				   AND end_dtm > v_min_dtm
				   AND start_dtm != end_dtm;
		END IF;
	END LOOP;
	
	-- Compute bucket periods
	ComputePeriodicData(
		in_region_sid, 
		CAST(in_min_raw_dtm AS DATE),
		CAST(in_max_raw_dtm AS DATE),
		in_raw_data_id
	);
END;

	
PROCEDURE ComputePeriodicData(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_min_dtm						IN	DATE,
	in_max_dtm						IN	DATE,
	in_raw_data_id					IN	meter_orphan_data.meter_raw_data_id%TYPE
)
AS
	v_raw_data_source_id			meter_raw_data.raw_data_source_id%TYPE;
	v_base_dtm						DATE;	-- The previous start boundary (day of week, month of year)
	v_start_period_dtm				DATE;	-- The start dtm of the first period
	v_period_start_dtm				DATE;	-- The start dtm of the current period
	v_period_end_dtm				DATE;	-- The end dtm of the current period
	v_min_dtm						DATE;
	v_max_dtm						DATE;
	v_has_hi_res_data				NUMBER;
BEGIN
	-- Apply any data patches to temp table and write output data
	meter_patch_pkg.ApplyDataPatches(in_region_sid, in_min_dtm, in_max_dtm);
	
	-- Recompute bucket data for each input type and each aggregator set-up for that input
	FOR i IN (
		SELECT i.meter_input_id, i.is_consumption_based, ag.aggregator, NVL(ag.aggr_proc, a.aggr_proc) aggr_proc
		  FROM meter_input i
		  JOIN meter_input_aggregator ag ON ag.app_sid = i.app_sid AND ag.meter_input_id = i.meter_input_id
		  JOIN meter_aggregator a ON a.aggregator = ag.aggregator
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.is_virtual = 0 -- Don't process virtual inputs
	) LOOP
	
		-- Recompute all affected periodic data based on input data values
		FOR d IN (
			SELECT meter_bucket_id, duration, high_resolution_only,
				is_minutes, is_hours,
				is_weeks, week_start_day,
				is_months, start_month,
				period_set_id, period_interval_id
			  FROM meter_bucket
			 WHERE (duration IS NOT NULL
			    OR (period_set_id IS NOT NULL AND period_interval_id IS NOT NULL))
			 ORDER BY is_export_period, is_months, is_hours, is_minutes, duration
		) LOOP
		
			IF d.high_resolution_only = 1 THEN
				
				-- if the meter has data for any source that has high res data 
				BEGIN
					SELECT 1
					  INTO v_has_hi_res_data
					  FROM meter_source_data msd
					  JOIN meter_raw_data mrd ON msd.app_sid = mrd.app_sid AND msd.meter_raw_data_id = mrd.meter_raw_data_id
					  JOIN meter_data_source_hi_res_input mshi 
					    ON msd.app_sid = mshi.app_sid 
					   AND mrd.raw_data_source_id = mshi.raw_data_source_id 
					   AND msd.meter_input_id = mshi.meter_input_id
					 WHERE msd.region_sid = in_region_sid
					   AND msd.meter_input_id = i.meter_input_id
					   AND ROWNUM = 1;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						v_has_hi_res_data := 0;
				END;
				
				IF v_has_hi_res_data = 0 THEN
					-- OR if the meter already has hi res data for this bucket/input/aggregator
					-- from a difference source then we need to carry on filling it in to avoid gaps
					BEGIN
						SELECT 1
						  INTO v_has_hi_res_data
						  FROM meter_live_data
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND region_sid = in_region_sid
						   AND meter_bucket_id = d.meter_bucket_id
						   AND meter_input_id = i.meter_input_id
						   AND aggregator = i.aggregator
						   AND ROWNUM = 1;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							v_has_hi_res_data := 0;
					END;
				END IF;
			ELSE
				v_has_hi_res_data :=  0;
			END IF;
			
			-- Recompute the bucket values at each priority level but only 
			-- if there's either data in the temp table for that priority or
			-- if data already exists in the bucket set for that priority.
			FOR p IN (
				SELECT p.priority
				  FROM meter_data_priority p
				  JOIN temp_meter_consumption t
				    ON t.region_sid = in_region_sid
				   AND t.meter_input_id = i.meter_input_id 
				   AND t.priority = p.priority
				  LEFT JOIN meter_raw_data mrd ON t.raw_data_id = mrd.meter_raw_data_id
				  LEFT JOIN meter_data_source_hi_res_input mshi ON mshi.app_sid = p.app_sid 
	 			   AND mshi.meter_input_id = i.meter_input_id 
	 			   AND mshi.raw_data_source_id = mrd.raw_data_source_id
				 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (d.high_resolution_only = DECODE(mshi.meter_input_id, NULL, 0, d.high_resolution_only)
				    OR v_has_hi_res_data = 1)
				 UNION
				SELECT p.priority
				  FROM meter_data_priority p
				  JOIN meter_live_data t
				    ON t.region_sid = in_region_sid 
				   AND t.meter_input_id = i.meter_input_id
				   AND t.aggregator = i.aggregator
				   AND t.priority = p.priority 
				   AND t.meter_bucket_id = d.meter_bucket_id
				   AND t.end_dtm > in_min_dtm
				   AND t.start_dtm < in_max_dtm
 				  LEFT JOIN meter_raw_data mrd ON t.meter_raw_data_id = mrd.meter_raw_data_id
 				  LEFT JOIN meter_data_source_hi_res_input mshi ON mshi.app_sid = p.app_sid 
 	 			   AND mshi.meter_input_id = i.meter_input_id 
 	 			   AND mshi.raw_data_source_id = mrd.raw_data_source_id
				 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (d.high_resolution_only = DECODE(mshi.meter_input_id, NULL, 0, d.high_resolution_only)
				    OR v_has_hi_res_data = 1)
				 ORDER BY priority
			) LOOP
		
				IF d.is_minutes = 1 THEN
					-- Minutes case
					v_start_period_dtm := TRUNC(in_min_dtm, 'YEAR') + FLOOR((TRUNC(in_min_dtm, 'MI') - TRUNC(in_min_dtm, 'YEAR')) * 1440 / d.duration) * d.duration / 1440;
					v_period_start_dtm := v_start_period_dtm;
					v_period_end_dtm := v_period_start_dtm + d.duration / 1440;
					LOOP
						-- Compute value for period
						ComputePeriodConsumption(i.aggregator, i.aggr_proc, in_region_sid, i.meter_input_id, d.meter_bucket_id, p.priority, v_period_start_dtm, v_period_end_dtm, in_raw_data_id);
						
						-- Move to next period
						v_period_start_dtm := v_period_end_dtm;
						v_period_end_dtm := v_period_end_dtm + d.duration / 1440;
						EXIT WHEN v_period_start_dtm >= in_max_dtm;
						
					END LOOP;
				
				ELSIF d.is_hours = 1 THEN
					-- Hours case
					v_start_period_dtm := TRUNC(in_min_dtm, 'YEAR') + FLOOR((TRUNC(in_min_dtm, 'HH') - TRUNC(in_min_dtm, 'YEAR')) * 24 / d.duration) * d.duration / 24;
					v_period_start_dtm := v_start_period_dtm;
					v_period_end_dtm := v_period_start_dtm + d.duration / 24;
					LOOP
						-- Compute value for period
						ComputePeriodConsumption(i.aggregator, i.aggr_proc, in_region_sid, i.meter_input_id, d.meter_bucket_id, p.priority, v_period_start_dtm, v_period_end_dtm, in_raw_data_id);
						
						-- Move to next period
						v_period_start_dtm := v_period_end_dtm;
						v_period_end_dtm := v_period_end_dtm + d.duration / 24;
						EXIT WHEN v_period_start_dtm >= in_max_dtm;
						
					END LOOP;
					
				ELSIF d.is_weeks = 1 THEN
					-- Weeks case, allows start day of week to be specified
					-- Start day = 1 means midnight Monday
					v_base_dtm := TRUNC(in_min_dtm, 'DAY') + d.week_start_day;
					IF v_base_dtm > TRUNC(in_min_dtm, 'DD') THEN
						v_base_dtm := v_base_dtm - 7;
					END IF;
					
					v_start_period_dtm := v_base_dtm + FLOOR((TRUNC(in_min_dtm, 'DD') - v_base_dtm) / (d.duration * 7)) * d.duration * 7;
					v_period_start_dtm := v_start_period_dtm;
					v_period_end_dtm := v_period_start_dtm + d.duration * 7;
					LOOP
						-- Compute value for period
						ComputePeriodConsumption(i.aggregator, i.aggr_proc, in_region_sid, i.meter_input_id, d.meter_bucket_id, p.priority, v_period_start_dtm, v_period_end_dtm, in_raw_data_id);
						
						-- Move to next period
						v_period_start_dtm := v_period_end_dtm;
						v_period_end_dtm := v_period_end_dtm + d.duration * 7;
						EXIT WHEN v_period_start_dtm >= in_max_dtm;
						
					END LOOP;
					
				ELSIF d.is_months = 1 THEN
					-- Months case, allows start month to be specified
					-- Start month = 1 means January
					v_base_dtm := ADD_MONTHS(TRUNC(TRUNC(in_min_dtm, 'YEAR'),'MONTH'), d.start_month - 1);
					IF v_base_dtm > TRUNC(in_min_dtm, 'MONTH') THEN
						v_base_dtm := v_base_dtm - 12;
					END IF;
					
					v_start_period_dtm := ADD_MONTHS(v_base_dtm, FLOOR(MONTHS_BETWEEN(TRUNC(in_min_dtm, 'MONTH'), v_base_dtm) / d.duration) * d.duration);
					v_period_start_dtm := v_start_period_dtm;
					v_period_end_dtm := ADD_MONTHS(v_period_start_dtm, d.duration);
					LOOP
						-- Compute value for period
						ComputePeriodConsumption(i.aggregator, i.aggr_proc, in_region_sid, i.meter_input_id, d.meter_bucket_id, p.priority, v_period_start_dtm, v_period_end_dtm, in_raw_data_id);
						
						-- Move to next period
						v_period_start_dtm := v_period_end_dtm;
						v_period_end_dtm := TsWithTimeZone(ADD_MONTHS(v_period_end_dtm, d.duration), in_min_dtm);
						EXIT WHEN v_period_start_dtm >= in_max_dtm;
						
					END LOOP;
				
				ELSIF d.period_set_id IS NOT NULL AND d.period_interval_id IS NOT NULL THEN
					-- We're using a period defined by the main system for this bucket (supports 13p)
					
					-- We need to expand the min and max dates to the start/end of the periods spanned (we want to update the entire intersecting set of periods)
					-- Otherwise each bit of raw data overwrites the whole period value but only with it's contributing consumption,
					-- overwriting the previously processed raw data frogment's cotribution (raw fragemnts are normally smaller than the period)
					v_period_start_dtm := period_pkg.TruncToPeriodStart(d.period_set_id, in_min_dtm);
					v_period_end_dtm := period_pkg.TruncToPeriodEnd(d.period_set_id, in_max_dtm);
					
					-- Insert some period dates, within the output range, into temp_period_dtms, if required
					period_pkg.GenerateAnnualPeriodDates(d.period_set_id, in_min_dtm, in_max_dtm);
					
					-- For each output period interval...
					FOR opi IN (
						-- This part selects out the dates for arbitrary period intervals (should be mutually exclusive with below)
						SELECT start_dtm, end_dtm
						  FROM (
							SELECT spd.start_dtm, epd.end_dtm
							  FROM period_interval_member m
							  JOIN period_set s ON s.period_set_id = m.period_set_id AND annual_periods = 0
							  JOIN period sp ON sp.period_set_id = m.period_set_id AND sp.period_id = m.start_period_id
							  JOIN period_dates spd ON spd.period_set_id = m.period_set_id AND spd.period_id = sp.period_id
							  JOIN period ep ON ep.period_set_id = m.period_set_id AND ep.period_id = m.end_period_id
							  JOIN period_dates epd ON epd.period_set_id = m.period_set_id AND epd.period_id = ep.period_id
							WHERE m.period_set_id = d.period_set_id
							  AND m.period_interval_id = d.period_interval_id
							  AND spd.year = epd.year
							UNION
							-- This part selects out the dates for annual period intervals (should be mutually exclusive with above)
							SELECT spd.start_dtm, epd.end_dtm
							  FROM period_interval_member m
							  JOIN period_set s ON s.period_set_id = m.period_set_id AND annual_periods = 1
							  JOIN period sp ON sp.period_set_id = m.period_set_id AND sp.period_id = m.start_period_id
							  JOIN period ep ON ep.period_set_id = m.period_set_id AND ep.period_id = m.end_period_id
							  JOIN temp_period_dtms spd ON spd.period_id = sp.period_id
							  JOIN temp_period_dtms epd ON epd.period_id = ep.period_id
							 WHERE m.period_set_id = d.period_set_id
							   AND m.period_interval_id = d.period_interval_id
							   AND spd.year = epd.year
						 )
						 WHERE start_dtm < v_period_end_dtm
						   AND end_dtm > v_period_start_dtm
						   	ORDER BY start_dtm
					) LOOP
						ComputePeriodConsumption(i.aggregator, i.aggr_proc, in_region_sid, i.meter_input_id, d.meter_bucket_id, p.priority, opi.start_dtm, opi.end_dtm, in_raw_data_id);
					END LOOP;
				END IF;
			
				-- Trim any nulls off the beginning and end of thre bucket data
				SELECT MIN(start_dtm), MAX(end_dtm)
				  INTO v_min_dtm, v_max_dtm
				  FROM meter_live_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_bucket_id = d.meter_bucket_id
				   AND meter_input_id = i.meter_input_id
				   AND aggregator = i.aggregator
				   AND priority = p.priority
				   AND consumption IS NOT NULL;
				   
				-- Delete before min and after max
				DELETE FROM meter_live_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_bucket_id = d.meter_bucket_id
				   AND meter_input_id = i.meter_input_id
				   AND aggregator = i.aggregator
				   AND priority = p.priority
				   AND (start_dtm < v_min_dtm OR end_dtm > v_max_dtm)
				   AND consumption IS NULL;
				
				-- Delete if all the values are null (above trim will not pick up the "all values null" case) 
				DELETE FROM meter_live_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_bucket_id = d.meter_bucket_id
				   AND meter_input_id = i.meter_input_id
				   AND aggregator = i.aggregator
				   AND priority = p.priority
				   AND NOT EXISTS (
				   		SELECT 1
				   		  FROM meter_live_data
				   		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						    AND region_sid = in_region_sid
						    AND meter_bucket_id = d.meter_bucket_id
						    AND meter_input_id = i.meter_input_id
				   			AND aggregator = i.aggregator
						    AND priority = p.priority
						    AND consumption IS NOT NULL
				   );
				   
			END LOOP;
		END LOOP;
		
		-- Insert jobs to look for gaps
		meter_patch_pkg.AddAutoPatchJobsForMeter(in_region_sid, i.meter_input_id, in_min_dtm, in_max_dtm);
		
	END LOOP;

	-- Process any inputs which derive their values from a helper procedure
	ProcessHelperInputs(in_region_sid, in_min_dtm, in_max_dtm);

	-- Exports data to the main system if required
	LogExportSystemValues(in_region_sid, in_min_dtm, in_max_dtm);
	
	-- Insert a jobs to recompute statistics
	meter_alarm_stat_pkg.AddStatJobsForMeter(in_region_sid, in_min_dtm);
	
	-- Update the meter list cache table for this meter
	meter_pkg.UpdateMeterListCache(in_region_sid);

END;

PROCEDURE ProcessHelperInputs(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_dtm				IN	DATE,
	in_max_dtm				IN	DATE
)
AS
BEGIN
	FOR i IN (
		SELECT mi.meter_input_id, mia.aggregator, mi.value_helper
		  FROM meter_input mi
		  JOIN meter_input_aggr_ind mia ON mi.app_sid = mia.app_sid AND mi.meter_input_id = mia.meter_input_id AND mia.region_sid = in_region_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mi.is_virtual = 1
		   AND mi.value_helper IS NOT NULL
	) LOOP
		EXECUTE IMMEDIATE 'BEGIN '||i.value_helper||'(:1,:2,:3,:4,:5);END;' USING i.meter_input_id, i.aggregator, in_region_sid, in_min_dtm, in_max_dtm;
	END LOOP;
END;


PROCEDURE UpsertMeterLiveData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_bucket_id		IN	meter_bucket.meter_bucket_id%TYPE,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_aggregator			IN	meter_input_aggregator.aggregator%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_period_start_dtm		IN	meter_live_data.start_dtm%TYPE,
	in_period_end_dtm		IN	meter_live_data.end_dtm%TYPE,
	in_period_val			IN	meter_live_data.consumption%TYPE,
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	UPDATE meter_live_data
		SET end_dtm = in_period_end_dtm,
			modified_dtm = SYSDATE,
			consumption = in_period_val,
			meter_raw_data_id = NVL(in_raw_data_id, meter_raw_data_id)
		WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND region_sid = in_region_sid
		AND meter_bucket_id = in_meter_bucket_id
		AND meter_input_id = in_meter_input_id
		AND aggregator = in_aggregator
		AND priority = in_priority
		AND start_dtm = in_period_start_dtm;
	
	IF SQL%ROWCOUNT = 0 THEN
		-- The data
		INSERT INTO meter_live_data
			(region_sid, meter_bucket_id, meter_input_id, aggregator, priority, 
				start_dtm, end_dtm, consumption, meter_raw_data_id, meter_data_id)
			VALUES (in_region_sid, in_meter_bucket_id, in_meter_input_id, in_aggregator, in_priority, 
					in_period_start_dtm, in_period_end_dtm, in_period_val, in_raw_data_id, meter_data_id_seq.NEXTVAL);
	END IF;
END; 

PROCEDURE ComputePeriodConsumption(
	in_aggregator			IN	meter_input_aggregator.aggregator%TYPE,
	in_aggr_proc			IN	meter_input_aggregator.aggr_proc%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_meter_bucket_id		IN	meter_bucket.meter_bucket_id%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_period_start_dtm		IN	meter_live_data.start_dtm%TYPE,
	in_period_end_dtm		IN	meter_live_data.end_dtm%TYPE,
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE DEFAULT NULL
)
AS
	v_period_val			meter_live_data.consumption%TYPE;
	v_raw_data_id			meter_raw_data.meter_raw_data_id%TYPE;
	v_patch_count			NUMBER;
	v_is_sparse				NUMBER;
	v_is_output				NUMBER;
BEGIN
	
	SELECT p.is_output, DECODE(p.is_output, 1, 1, p.is_patch) is_sparse
	  INTO v_is_output, v_is_sparse
	  FROM meter_data_priority p
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.priority = in_priority;
	
	-- Reset sum for this peirod/priority
	v_period_val := NULL;
	
	-- Call the correct aggregation procedure
	EXECUTE IMMEDIATE 'BEGIN '||in_aggr_proc||'(:1,:2,:3,:4,:5,:6,:7);END;' 
		USING in_region_sid, in_meter_input_id, in_priority, in_period_start_dtm, in_period_end_dtm, OUT v_period_val, OUT v_raw_data_id;
	
	-- Always use the passed raw data id if provided (not null)
	v_raw_data_id := NVL(in_raw_data_id, v_raw_data_id);

	-- Only write a value for the output bucket if there are overlapping priority levels.
	-- We process the buckets in order we can just count the number of buckets for this bucket period/input_id/aggregator
	IF v_is_output = 1 THEN
		SELECT COUNT(*)
		  INTO v_patch_count
		  FROM meter_live_data mld
		  JOIN meter_data_priority mdp ON mdp.app_sid = mld.app_sid AND mdp.priority = mld.priority
		 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mld.region_sid = in_region_sid
		   AND mld.meter_bucket_id = in_meter_bucket_id
		   AND mld.meter_input_id = in_meter_input_id
		   AND mld.aggregator = in_aggregator
		   AND mld.start_dtm = in_period_start_dtm;
		
		-- No output bucket vlaue if there are no patches 
		-- (we use the original data in that case to save duplicating it)
		IF v_patch_count < 2 THEN
			v_period_val := NULL;
		END IF;
	END IF;
	
	-- Update the value for this period/priority
	IF v_period_val IS NOT NULL OR v_is_sparse = 0 THEN

		UpsertMeterLiveData(
			in_region_sid => in_region_sid,
			in_meter_bucket_id => in_meter_bucket_id,
			in_meter_input_id => in_meter_input_id,
			in_aggregator => in_aggregator,
			in_priority => in_priority,
			in_period_start_dtm => in_period_start_dtm,
			in_period_end_dtm => in_period_end_dtm,
			in_period_val => v_period_val,
			in_raw_data_id => v_raw_data_id
		);
		
	ELSIF v_is_sparse = 1 THEN
		DELETE FROM meter_live_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND meter_bucket_id = in_meter_bucket_id
		   AND meter_input_id = in_meter_input_id
		   AND aggregator = in_aggregator
		   AND priority = in_priority
		   AND start_dtm = in_period_start_dtm;	
	END IF;
END;


PROCEDURE CreateMatchJobsForApps
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_batch_job_id			meter_match_batch_job.batch_job_id%TYPE;
BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM meter_orphan_data
		UNION
		SELECT DISTINCT app_sid
		  FROM duff_meter_region
	) LOOP
		security_pkg.setApp(r.app_sid);
		QueueMatchBatchJob(
			out_batch_job_id => v_batch_job_id
		);
	END LOOP;

	security_pkg.setApp(v_app_sid);
END;

PROCEDURE QueueMatchBatchJob(
	in_meter_raw_data_id	IN	meter_match_batch_job.meter_raw_data_id%TYPE DEFAULT NULL,
	out_batch_job_id		OUT	meter_match_batch_job.batch_job_id%TYPE
)
AS
BEGIN
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_METER_MATCH,
		out_batch_job_id => out_batch_job_id
	);

	INSERT INTO meter_match_batch_job (batch_job_id, meter_raw_data_id)
	VALUES (out_batch_job_id, in_meter_raw_data_id);
END;

PROCEDURE GetMatchBatchJob(
	in_batch_job_id			IN	meter_match_batch_job.batch_job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT batch_job_id, meter_raw_data_id
		  FROM meter_match_batch_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND batch_job_id = in_batch_job_id;
END;

PROCEDURE GetAppsToMatch(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM meter_orphan_data;
END;

PROCEDURE INTERNAL_QueueRawDataImportJob(
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE DEFAULT NULL,
	in_meter_raw_data_id	IN	meter_raw_data_import_job.meter_raw_data_id%TYPE DEFAULT NULL,
	out_batch_job_id		OUT	meter_raw_data_import_job.batch_job_id%TYPE
)
AS
	v_raw_data_source_id	meter_raw_data_source.raw_data_source_id%TYPE := in_raw_data_source_id;
BEGIN
	IF v_raw_data_source_id IS NULL AND in_meter_raw_data_id IS NOT NULL THEN
		SELECT raw_data_source_id
		  INTO v_raw_data_source_id
		  FROM meter_raw_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = in_meter_raw_data_id;
	END IF;

	batch_job_pkg.Enqueue(
		in_in_order_group => 'RAW_DATA_SOURCE_ID_' || v_raw_data_source_id,
		in_batch_job_type_id => csr.batch_job_pkg.JT_METER_RAW_DATA,
		out_batch_job_id => out_batch_job_id
	);

	IF in_raw_data_source_id IS NOT NULL OR in_meter_raw_data_id IS NOT NULL THEN
		INSERT INTO meter_raw_data_import_job (batch_job_id, raw_data_source_id, meter_raw_data_id)
		VALUES (out_batch_job_id, in_raw_data_source_id, in_meter_raw_data_id);
	END IF;
END;

PROCEDURE QueueRawDataImportJob(
	in_import_class_sid				IN	NUMBER,
	in_import_instance_id			IN	NUMBER,
	in_step_number					IN	NUMBER
)
AS
	v_raw_data_source_id			meter_raw_data_import_job.raw_data_source_id%TYPE;
	v_meter_raw_data_id				meter_raw_data_import_job.meter_raw_data_id%TYPE;
	v_batch_job_id 					meter_raw_data_import_job.batch_job_id%TYPE;
BEGIN
	BEGIN
		SELECT raw_data_source_id, meter_raw_data_id
		  INTO v_raw_data_source_id, v_meter_raw_data_id
		  FROM meter_raw_data
		 WHERE automated_import_instance_id = in_import_instance_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	INTERNAL_QueueRawDataImportJob(
		in_raw_data_source_id => v_raw_data_source_id,
		in_meter_raw_data_id => v_meter_raw_data_id,
		out_batch_job_id => v_batch_job_id
	);
END;

PROCEDURE CreateRawDataJobsForApps
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_batch_job_id			meter_match_batch_job.batch_job_id%TYPE;
BEGIN
	FOR r IN (
		-- Don't worry about locking stuff for update etc at this stage, if the app has 
		-- already been processed by the time we get to it then there'll just be nothing to do
		SELECT DISTINCT app_sid, raw_data_source_id
		  FROM meter_raw_data
		 WHERE status_id = RAW_DATA_STATUS_PROCESSING
		    OR status_id IN (
	   		SELECT status_id
	   		  FROM meter_raw_data_status
	   		 WHERE needs_processing = 1)
		 ORDER BY app_sid
	) LOOP
		security_pkg.setApp(r.app_sid);
		INTERNAL_QueueRawDataImportJob(
			in_raw_data_source_id => r.raw_data_source_id,
			out_batch_job_id => v_batch_job_id
		);
	END LOOP;

	security_pkg.setApp(v_app_sid);
END;

PROCEDURE GetRawDataImportJob(
	in_batch_job_id			IN	meter_raw_data_import_job.batch_job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_enabled				NUMBER;
BEGIN
	SELECT raw_feed_data_jobs_enabled
	  INTO v_enabled
	  FROM metering_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	IF v_enabled = 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_FEATURE_DISABLED, 'Disabled');
	END IF;

	OPEN out_cur FOR
		SELECT in_batch_job_id batch_job_id, mrdij.meter_raw_data_id, NVL(mrd.raw_data_source_id, rds.raw_data_source_id) raw_data_source_id
		  FROM dual
		  LEFT JOIN meter_raw_data_import_job mrdij ON in_batch_job_id = mrdij.batch_job_id
		  LEFT JOIN meter_raw_data mrd ON mrdij.meter_raw_data_id = mrd.meter_raw_data_id
		  LEFT JOIN meter_raw_data_source rds ON mrdij.raw_data_source_id = rds.raw_data_source_id
		;
END;

PROCEDURE FindMeterConversion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_uom					IN	meter_orphan_data.uom%TYPE,
	out_meter_conversion_id	OUT	measure_conversion.measure_conversion_id%TYPE,
	out_data_conversion_id	OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
	v_meter_measure_sid 	security_pkg.T_SID_ID;
	v_meter_measure_desc 	measure.description%TYPE;
	v_meter_conversion_desc	measure_conversion.description%TYPE;
BEGIN

	BEGIN
		SELECT measure_sid
		  INTO v_meter_measure_sid
		  FROM meter_input_aggr_ind
		 WHERE region_Sid = in_region_sid
		   AND meter_input_id = in_meter_input_id;

		-- If there's no measure specified on the meter_input_aggr_ind 
		-- table then just use the base measure (conversion_id is null)
		IF v_meter_measure_sid IS NULL THEN
			out_meter_conversion_id := NULL;
			out_data_conversion_id := NULL;
			RETURN;
		END IF;

		-- Fetch the meter input's measure/conversion (conversion may be null)   
		SELECT m.measure_sid, m.description, c.measure_conversion_id, c.description
		  INTO v_meter_measure_sid, v_meter_measure_desc, out_meter_conversion_id, v_meter_conversion_desc
		  FROM all_meter am
		  JOIN meter_input_aggr_ind ai ON ai.app_sid = am.app_sid AND ai.region_sid = am.region_sid AND meter_input_id = in_meter_input_id
		  JOIN measure m ON m.app_sid = ai.app_sid AND m.measure_sid = ai.measure_sid
		  LEFT JOIN measure_conversion c ON c.app_sid = ai.app_sid AND c.measure_conversion_id = ai.measure_conversion_id
		 WHERE am.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND am.region_sid = in_region_sid;
		
		-- If the UOM is null then default to the meter's default measure conversion
		IF in_uom IS NULL THEN
			out_data_conversion_id := out_meter_conversion_id;
			RETURN;
		END IF;
		
		-- Does the meter's measure or conversion match the passed uom
		IF LOWER(NVL(v_meter_conversion_desc, v_meter_measure_desc)) = LOWER(in_uom) THEN
			out_data_conversion_id := out_meter_conversion_id;
			RETURN;
		END IF;
		
		-- If the meter has a conversion we need to try it's base measure for a match
		IF out_meter_conversion_id IS NOT NULL AND 
			LOWER(v_meter_measure_desc) = LOWER(in_uom) THEN
				out_data_conversion_id := NULL;
				RETURN;
		END IF;
		
		-- Try other conversions of the meter's measure
		FOR r IN (
			SELECT measure_conversion_id, description
			  FROM measure_conversion 
			 WHERE measure_sid = v_meter_measure_sid
		) LOOP
			IF LOWER(r.description) = LOWER(in_uom) THEN
				out_data_conversion_id := r.measure_conversion_id;
				RETURN;
			END IF;
		END LOOP;
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Meter input notmapped so can't find conversion
	END;

	-- No conversion found that matches the passed UOM
	RAISE_APPLICATION_ERROR(ERR_NO_CONVERSION_FOUND, 
		'Failed to find valid measure/conversion on meter input "'||in_meter_input_id||
		'" for UOM "'||in_uom||
		'" on meter with region sid '||in_region_sid);
END;


PROCEDURE MatchOrphanData(
	in_raw_data_id			IN	meter_orphan_data.meter_raw_data_id%TYPE DEFAULT NULL,
	in_serial_ids			IN	security_pkg.T_VARCHAR2_ARRAY DEFAULT EmptySerialIds
)
AS
	t_serial_ids			security.T_VARCHAR2_TABLE;

	v_region_sid			security_pkg.T_SID_ID;
	v_min_dtm				TIMESTAMP WITH TIME ZONE;
	v_max_dtm				TIMESTAMP WITH TIME ZONE;
	v_consumption			meter_orphan_data.consumption%TYPE;
	v_meter_conversion_id	measure_conversion.measure_conversion_id%TYPE;
	v_data_conversion_id	measure_conversion.measure_conversion_id%TYPE;
	v_error_id				meter_raw_data_error.error_id%TYPE;
	v_match					BOOLEAN;
	v_data_source_ids		security_pkg.T_SID_IDS;
	t_data_source_ids		security.T_SID_TABLE;

	v_lock_id				NUMBER;
	v_lock_result 			INTEGER;
	v_lock_timeout			INTEGER := 0; -- Default to no wait
	v_allow_null_start_dtm	NUMBER(1);
BEGIN
	v_region_sid := NULL;
	
	t_serial_ids := security_pkg.Varchar2ArrayToTable(in_serial_ids);
	
	FOR rid IN (
		SELECT meter_raw_data_id
		  FROM meter_orphan_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = NVL(in_raw_data_id, meter_raw_data_id)
		UNION
		SELECT o.meter_raw_data_id
		  FROM meter_orphan_data o
		  JOIN TABLE(t_serial_ids) s ON s.value = o.serial_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP

		-- If the raw data id was passed in (not null) then wait for 
		-- the lock, if not then skip over anything we can't lock 
		IF in_raw_data_id IS NOT NULL THEN
			v_lock_timeout := dbms_lock.maxwait;
		END IF;

		-- Try to take out a lock for this app_sid/meter_raw_data_id
		-- XXX: AVOID USING ALLOCATE_UNQUE AS IT COMMITS!
		SELECT ORA_HASH('METER_MATCH_LOCK_'||SYS_CONTEXT('SECURITY', 'APP')||'_'||rid.meter_raw_data_id, 1073741823)
		  INTO v_lock_id
		  FROM DUAL;
		v_lock_result := dbms_lock.request(
			id					=> v_lock_id,
			lockmode 			=> dbms_lock.x_mode, 
			timeout 			=> v_lock_timeout, 
			release_on_commit	=> TRUE
		);

		-- Only run for this meter raw data id if we got a lock
		IF v_lock_result = 0 /*success*/ THEN

			-- Data could be for differeing input types...
			FOR serial IN (
				SELECT DISTINCT od.serial_id, od.meter_raw_data_id, od.uom, rd.raw_data_source_id, od.meter_input_id, mi.is_consumption_based
				  FROM meter_orphan_data od
				  JOIN meter_raw_data rd ON rd.app_sid = od.app_sid AND rd.meter_raw_data_id = od.meter_raw_data_id
				  JOIN meter_input mi ON  mi.app_sid = od.app_sid AND mi.meter_input_id = od.meter_input_id
				  -- If the row's raw data id matches the id specified in the input argument 
				  -- then return any serial id for that raw data id otherwise only return rows 
				  -- that match the passed in list of serial ids for the given raw data id.
				  -- If the raw data id was not provided match anything.
				  LEFT JOIN TABLE(t_serial_ids) ser ON od.serial_id = DECODE(od.meter_raw_data_id, NVL(in_raw_data_id, od.meter_raw_data_id), od.serial_id, ser.value)
				 WHERE od.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND od.meter_raw_data_id = rid.meter_raw_data_id
			) LOOP
				
				v_match := FALSE;
				
				BEGIN
					MatchSerialNumber(serial.meter_raw_data_id, serial.serial_id, v_region_sid);
					IF v_region_sid > 0 THEN
						BEGIN
							-- Try to find the correct conversion for the given meter/input type/uom
							FindMeterConversion(v_region_sid, serial.meter_input_id, serial.uom, v_meter_conversion_id, v_data_conversion_id);
							
							-- Fetch the min and max dates
							SELECT MIN(start_dtm), MAX(end_dtm)
							  INTO v_min_dtm, v_max_dtm
							  FROM meter_orphan_data
							 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
							   AND meter_raw_data_id = serial.meter_raw_data_id
							   AND serial_id = serial.serial_id
							   AND meter_input_id = serial.meter_input_id;
							
							IF v_max_dtm IS NULL THEN
								-- This is "point in time" reading data
								FOR r IN (
									SELECT priority, start_dtm, uom, meter_raw_data_id, consumption, note
									  FROM meter_orphan_data
									 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
									   AND meter_raw_data_id = serial.meter_raw_data_id
									   AND serial_id = serial.serial_id
									   AND meter_input_id = serial.meter_input_id
								) LOOP
									INTERNAL_UpsertReadingData(v_region_sid, serial.meter_input_id, r.priority, serial.meter_raw_data_id, 
										r.uom, v_meter_conversion_id, v_data_conversion_id, r.start_dtm, r.consumption, r.note);
								END LOOP;
								
								-- Get a valid max dtm
								SELECT MAX(start_dtm)
								  INTO v_max_dtm
								  FROM meter_orphan_data
								 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
								   AND meter_raw_data_id = serial.meter_raw_data_id
								   AND serial_id = serial.serial_id
								   AND meter_input_id = serial.meter_input_id;
								
								IF serial.is_consumption_based != 0 THEN
									-- Process the data into a set of consumptions and insert those consumption
									-- figures into the meter_source_data table for further processing.
									INTERNAL_ReadingsToConsumption(v_region_sid, v_min_dtm, v_max_dtm, v_meter_conversion_id, v_data_conversion_id);
								END IF;

								-- Remove the matched orphan data
								DELETE FROM meter_orphan_data
								 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
								   AND meter_raw_data_id = serial.meter_raw_data_id
								   AND serial_id = serial.serial_id
								   AND meter_input_id = serial.meter_input_id;
							ELSE
								
								-- Urjanet kludge (allow null start dtm)?
								SELECT st.allow_null_start_dtm
								  INTO v_allow_null_start_dtm
								  FROM all_meter m
								  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
								 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
								   AND m.region_sid = v_region_sid;

								-- This is consumpton based data
								FOR r IN (
									SELECT priority, start_dtm, end_dtm, uom, meter_raw_data_id, consumption, note, statement_id
									  FROM meter_orphan_data
									 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
									   AND meter_raw_data_id = serial.meter_raw_data_id
									   AND serial_id = serial.serial_id
									   AND meter_input_id = serial.meter_input_id
								) LOOP
									IF INTRNL_UpsertSrcDataOverlapChk(
										in_region_sid			=> v_region_sid,
										in_input_id				=> serial.meter_input_id,
										in_priority				=> r.priority,
										in_raw_data_id			=> r.meter_raw_data_id,
										in_uom					=> r.uom,
										in_meter_conversion_id	=> v_meter_conversion_id,
										in_data_conversion_id	=> v_data_conversion_id,
										in_start_dtm			=> r.start_dtm,
										in_end_dtm				=> r.end_dtm,
										in_consumption			=> r.consumption,
										in_note					=> r.note,
										in_raise_issues			=> 0,
										in_statement_id			=> r.statement_id
									) THEN
										-- Upserted successfully, remove the orphan data
										DELETE FROM meter_orphan_data
										 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
										   AND meter_raw_data_id = serial.meter_raw_data_id
										   AND serial_id = serial.serial_id
										   AND meter_input_id = serial.meter_input_id
										   AND priority = r.priority
										   AND start_dtm = r.start_dtm
										   AND end_dtm = r.end_dtm
										   AND (
											   statement_id = r.statement_id
											OR statement_id IS NULL AND r.statement_id IS NULL
										   );

										-- Deal with placeholders (start_dtm = end_dtm) that 
										-- might have been created by the "urjanet kludge"
										IF v_allow_null_start_dtm != 0 THEN
											INTERNAL_UrjKludgeChkPHolders(
												in_region_sid		=> v_region_sid,
												in_meter_input_id	=> serial.meter_input_id,
												inout_min_raw_dtm	=> v_min_dtm
											);
										END IF;

									END IF;
								END LOOP;
							END IF;
												
							-- Recompute the periodic data for the period
							ComputePeriodicDataFromRaw(v_region_sid, v_min_dtm, v_max_dtm, serial.meter_raw_data_id);
						
							-- Flag that a match was made
							v_match := TRUE;
						
						EXCEPTION
							-- Catch measure conversion exception and continue processing 
							WHEN NO_CONVERSION_FOUND THEN
								LogRawDataError(serial.meter_raw_data_id,
										'MATCHER: Meter with serial number '''||serial.serial_id||''' matched region with sid '''||v_region_sid||'''.'||CHR(13)||CHR(10)||
										'The UOM of the raw data does not match that of the meter and no acceptable conversion could be found.'||CHR(13)||CHR(10)||
										'Raw data UOM is '''||serial.uom||'''.', v_min_dtm, v_error_id
								);
						END;
					END IF;
					
				EXCEPTION
					WHEN MULTIPLE_SERIAL_MATCHES THEN
					-- A serial number matched more than one meter, log an error
					LogRawDataError(
						serial.meter_raw_data_id,
						'MATCHER: Serial number '|| serial.serial_id ||' matched more than one meter region',
						SYSDATE,
						v_error_id
					);
				END;
				
				-- If we found a match then we need to update the orphaned/matched 
				-- counts in the raw data source and raw data tables.
				IF v_match THEN
					UpdateRawDataOrphanCount(serial.meter_raw_data_id);
					v_data_source_ids(v_data_source_ids.COUNT) := serial.raw_data_source_id;
				END IF;

			END LOOP;
	
			-- Release the lock for this raw data id
			v_lock_result := dbms_lock.release(
				id	=> v_lock_id
			);
			IF v_lock_result NOT IN (0, 4) THEN -- 0 = success, 4 = lock not held
				RAISE_APPLICATION_ERROR(-20001, 'Releasing the meter match lock for raw data id '||rid.meter_raw_data_id||' failed with '||v_lock_result);
			END IF;

		END IF;
	END LOOP;

	-- Process counts for any data sources that are associated with raw 
	-- data that is associated with any we matched meters we found
	t_data_source_ids := security_pkg.SidArrayToTable(v_data_source_ids);
	FOR r IN (
		SELECT DISTINCT column_value data_source_id
		  FROM TABLE(t_data_source_ids)
	) LOOP
		UpdateDataSourceOrphanCount(r.data_source_id);
	END LOOP;

	-- Export any system values for all regions logged during the matching process
	BatchExportSystemValues;
END;

PROCEDURE GetAppsToProcess (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Don't worry about locking stuff for update etc at this stage, if the app has 
	-- already been processed by the time we get to it then there'll just be nothing to do
	OPEN out_cur FOR
		SELECT app_sid, COUNT(app_sid) AS job_count
		  FROM meter_raw_data
		 WHERE status_id = RAW_DATA_STATUS_PROCESSING
		    OR status_id IN (
	   		SELECT status_id
	   		  FROM meter_raw_data_status
	   		 WHERE needs_processing = 1
	 	)
        GROUP BY app_sid
        ORDER BY job_count
	 	;
END;

PROCEDURE INTERNAL_MarkRawDataProcessing(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_PROCESSING
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_raw_data_id;

	COMMIT;
END;

PROCEDURE UNSEC_MarkRawDataQueuedExt(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_QUEUED_EXT
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_raw_data_id;
END;

PROCEDURE UNSEC_MarkRawDataMergeExt(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_MERGE_EXT
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_raw_data_id;
END;

FUNCTION INTERNAL_GetRawDataLockId(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
) RETURN NUMBER
AS
	v_lock_id				NUMBER;
BEGIN
	-- Generate lock id
	SELECT ORA_HASH('METER_RAW_DATA_LOCK_'||SYS_CONTEXT('SECURITY', 'APP')||'_'||in_raw_data_id, 1073741823)
	  INTO v_lock_id
	  FROM DUAL;
	RETURN v_lock_id;
END;

PROCEDURE GetRawDataJob(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_wait					IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_lock_id				NUMBER;
	v_lock_result 			INTEGER;
	v_lock_timeout			INTEGER := 0;
BEGIN
	-- Get the lock ID
	-- XXX: AVOID USING ALLOCATE_UNQUE AS IT COMMITS!
	v_lock_id := INTERNAL_GetRawDataLockId(in_raw_data_id);

	-- Do we wait for the lock
	IF in_wait != 0 THEN
		v_lock_timeout := dbms_lock.maxwait;
	END IF;

	-- Try and lock
	v_lock_result := dbms_lock.request(
		id					=> v_lock_id,
		lockmode 			=> dbms_lock.x_mode, 
		timeout 			=> v_lock_timeout, 
		release_on_commit	=> TRUE
	);

	-- Mark the job as processing (autonomous trnasaction)
	IF v_lock_result = 0 /*success*/ THEN
		INTERNAL_MarkRawDataProcessing(in_raw_data_id);
	END IF;

	-- Get the job data
	OPEN out_cur FOR
		SELECT mrd.meter_raw_data_id, mrd.raw_data_source_id, mrd.status_id, 
			mrd.received_dtm, mrd.start_dtm, mrd.end_dtm, mrd.mime_type, mrd.encoding_name, mrd.data,
			rds.parser_type, rds.helper_pkg
		  FROM meter_raw_data mrd
		  JOIN meter_raw_data_source rds ON rds.app_sid = mrd.app_sid AND rds.raw_data_source_id = mrd.raw_data_source_id
		 WHERE mrd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mrd.meter_raw_data_id = in_raw_data_id
		   AND v_lock_result = 0 -- ONLY RETURN THE INFORMATION IF WE GOT A LOCK
		;
END;

PROCEDURE GetQueuedRawDataIds (
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE	DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT raw_data_source_id, meter_raw_data_id
		  FROM meter_raw_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = NVL(in_raw_data_source_id, raw_data_source_id)
		   AND status_id IN (
		   	SELECT status_id
		   	  FROM meter_raw_data_status
		   	 WHERE status_id = RAW_DATA_STATUS_PROCESSING
		   	    OR needs_processing = 1
		   )
		 ORDER BY raw_data_source_id, received_dtm, meter_raw_data_id;
END;

PROCEDURE AbortRawDataProcessing (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_null_dates			T_DATE_ARRAY;
BEGIN
	-- hack for ODP.NET which doesn't support empty arrays - just return nothing
	IF in_error_messages.COUNT = 0 OR (in_error_messages.COUNT = 1 AND in_error_messages(in_error_messages.FIRST) IS NULL) THEN
		RETURN;
	END IF;
	
	FOR i IN in_error_messages.FIRST .. in_error_messages.LAST
	LOOP
		v_null_dates(i) := NULL;
	END LOOP;
	
	AbortRawDataProcessing(in_raw_data_id, in_error_messages, v_null_dates);
END;

PROCEDURE AbortRawDataProcessing (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_error_dtms			IN	T_DATE_ARRAY
)
AS
BEGIN
	-- Log any errors
	LogRawDataErrors(in_raw_data_id, in_error_messages, in_error_dtms);
END;

PROCEDURE LogRawDataErrors (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_error_dtms			IN	T_DATE_ARRAY
)
AS
	v_null_sids				security_pkg.T_SID_IDS;
BEGIN
	FOR i IN in_error_messages.FIRST .. in_error_messages.LAST
	LOOP
		v_null_sids(i) := NULL;
	END LOOP;
	LogRawDataErrors(in_raw_Data_id, v_null_sids, in_error_messages, in_error_dtms);
END;

PROCEDURE LogRawDataErrors (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_region_sids	IN	security_pkg.T_SID_IDS,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_error_dtms			IN	T_DATE_ARRAY
)
AS
	t_errors				T_EDIEL_ERROR_TABLE;
	v_error_id				meter_raw_data_error.error_id%TYPE;
BEGIN
	t_errors := EdielErrorToTable(in_error_messages, in_error_dtms, in_error_region_sids);
	FOR r IN (
		SELECT msg, dtm, sid
		  FROM TABLE(t_errors)
		  	ORDER BY pos
	) LOOP
		LogRawDataError(in_raw_data_id, r.sid, r.msg, r.dtm, v_error_id);
	END LOOP;
END;

PROCEDURE LogRawDataError (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_message		IN	meter_raw_data_error.message%TYPE,
	in_error_dtm			IN	meter_raw_data_error.data_dtm%TYPE,
	out_error_id			OUT	meter_raw_data_error.error_id%TYPE
)
AS
BEGIN
	LogRawDataError(in_raw_data_id, NULL, in_error_message, in_error_dtm, out_error_id);
END;

PROCEDURE LogRawDataError (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_error_message		IN	meter_raw_data_error.message%TYPE,
	in_error_dtm			IN	meter_raw_data_error.data_dtm%TYPE,
	out_error_id			OUT	meter_raw_data_error.error_id%TYPE
)
AS
	v_issue_id				issue.issue_id%TYPE;
BEGIN
	-- Check if this error message is already logged
	SELECT MIN(error_id)
	  INTO out_error_id
	  FROM meter_raw_data_error
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_raw_data_id
	   AND message = in_error_message;

	IF out_error_id IS NULL THEN
			-- It's a new error (based solely on the error text), insert it
			INSERT INTO meter_raw_data_error
				(meter_raw_data_id, error_id, raised_dtm, data_dtm, message)
			  VALUES (in_raw_data_id, meter_raw_data_error_id_seq.NEXTVAL, SYSDATE, in_error_dtm, in_error_message)
			  	RETURNING error_id INTO out_error_id;
			
			-- Generate an issue too
			AddRawDataIssue(
				in_raw_data_id	=> in_raw_data_id,
				in_region_sid	=> in_region_sid,
				in_label		=> in_error_message,
				out_issue_id	=> v_issue_id
			);
	END IF;

	-- Update status
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_HAS_ERRORS
	 WHERE meter_raw_data_id = in_raw_data_id
	   AND status_id = RAW_DATA_STATUS_PROCESSING;
END;

PROCEDURE CompleteRawDataProcessing (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE	DEFAULT NULL
)
AS
BEGIN   
	-- Processing is done in a transaction
	UPDATE meter_raw_data
	   SET status_id = DECODE (status_id, RAW_DATA_STATUS_HAS_ERRORS, RAW_DATA_STATUS_HAS_ERRORS, RAW_DATA_STATUS_SUCCESS)
	 WHERE meter_raw_data_id = NVL(in_raw_data_id, meter_raw_data_id)
	   AND status_id = RAW_DATA_STATUS_PROCESSING;
END;

PROCEDURE GetDurations(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT meter_bucket_id, duration, description, is_minutes, is_hours, 
			is_weeks, week_start_day, is_months, start_month, is_export_period,
			period_set_id, period_interval_id
		  FROM meter_bucket
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND (duration IS NOT NULL OR period_set_id IS NOT NULL)
		   	ORDER BY is_minutes DESC, is_hours DESC, is_weeks DESC, is_months DESC, duration NULLS LAST;
END;

PROCEDURE GetLinkedMeters(
	in_region_sid  		IN  security_pkg.T_SID_ID,
	out_cur 			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read region with sid ' || in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT linked_meter_sid
		  FROM linked_meter
		 WHERE region_sid = in_region_sid
		 ORDER BY pos;
END;

PROCEDURE GetMeterData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_duration_id			IN	meter_bucket.meter_bucket_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_meter_input_id		meter_input.meter_input_id%TYPE;
BEGIN
	-- XXX: Restrict to consumption data until UI is updated
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM meter_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';
	
	-- Return all periods
	OPEN out_cur FOR
		SELECT region_sid, meter_bucket_id, start_dtm, end_dtm, consumption, meter_raw_data_id
		  FROM v$patched_meter_live_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND meter_input_id = v_meter_input_id
		   AND aggregator = 'SUM' -- Restrict aggregator type until UI is updated
		   AND meter_bucket_id = in_duration_id
		   	ORDER BY start_dtm ASC;
END;

PROCEDURE GetMeterData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_input_id				IN	meter_input.meter_input_id%TYPE,
	in_aggregator			IN	meter_aggregator.aggregator%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_duration_id			IN	meter_bucket.meter_bucket_id%TYPE,
	in_min_dtm				IN	meter_live_data.start_dtm%TYPE,
	in_max_dtm				IN	meter_live_data.start_dtm%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Priority vs. resultant output
	IF in_priority IS NULL THEN
	 
		-- Return all intersectiong periods
		OPEN out_cur FOR
			SELECT * FROM (
				SELECT region_sid, ldd.meter_bucket_id,
					mi.label meter_input, ma.label aggregator_type, ldd.description duration_description,
					start_dtm, end_dtm, consumption, meter_raw_data_id
				  FROM v$patched_meter_live_data mld
					JOIN meter_bucket ldd ON mld.meter_bucket_id = ldd.meter_bucket_id
					JOIN meter_input mi ON mi.meter_input_id = mld.meter_input_id
					JOIN meter_aggregator ma ON ma.aggregator = mld.aggregator
				 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND mld.region_sid = in_region_sid
				   AND mld.meter_input_id = in_input_id
				   AND mld.aggregator = in_aggregator
				   AND mld.meter_bucket_id = in_duration_id
				   AND mld.end_dtm > in_min_dtm
				   AND mld.start_dtm < in_max_dtm
				   AND mld.consumption IS NOT NULL -- Single null for gaps provided by part of query below
				UNION ALL	
				SELECT
					x.region_sid region_sid,
					x.meter_bucket_id meter_bucket_id,
					x.meter_input, 
					x.aggregator_type, 
					x.duration_description duration_description,
					x.end_dtm start_dtm,
					x.next_start_dtm end_dtm,
					null consumption,
					null meter_row_data_id
				 FROM (
					SELECT 
						region_sid,
						ldd.meter_bucket_id,
						end_dtm, 
						LEAD(start_dtm) over (partition by region_sid order by start_dtm) next_start_dtm,
						mi.label meter_input, ma.label aggregator_type, ldd.description duration_description
					FROM v$patched_meter_live_data mld
						JOIN meter_bucket ldd ON mld.meter_bucket_id = ldd.meter_bucket_id
						JOIN meter_input mi ON mi.meter_input_id = mld.meter_input_id
						JOIN meter_aggregator ma ON ma.aggregator = mld.aggregator
						JOIN customer c ON mld.app_sid = c.app_sid AND c.LIVE_METERING_SHOW_GAPS = 1
					WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					  AND mld.region_sid = in_region_sid
					  AND mld.meter_input_id = in_input_id
					  AND mld.aggregator = in_aggregator
					  AND mld.meter_bucket_id = in_duration_id
				      AND mld.start_dtm > in_min_dtm
					  AND mld.end_dtm < in_max_dtm
					  AND mld.consumption IS NOT NULL -- Treat null consumption as no data
					) x
				 WHERE x.end_dtm != x.next_start_dtm
				UNION ALL
				SELECT
				  r.region_sid region_sid,
				  ldd.meter_bucket_id, 
				  mi.label meter_input,
				  ma.label aggregator_type,
				  ldd.description duration_description,
				  CASE
					WHEN(r.ACQUISITION_DTM < in_min_dtm) THEN in_min_dtm
					ELSE r.ACQUISITION_DTM
				  END start_dtm,
				  mld.start_dtm end_dtm,
				  null consumption,
				  null meter_row_data_id
				FROM (
				  SELECT 
						MIN(start_dtm) start_dtm,
						app_sid,
						region_sid,
						meter_input_id,
						aggregator,
						meter_bucket_id
				    FROM v$patched_meter_live_data
				   WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
				     AND region_sid = in_region_sid
				     AND meter_input_id = in_input_id
				     AND aggregator = in_aggregator
				     AND meter_bucket_id = in_duration_id
				     AND consumption IS NOT NULL -- Treat null consumption as no data
				   		GROUP BY app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id
				  ) mld
				  JOIN v$region r ON mld.region_sid = r.region_sid
				  JOIN customer c ON mld.app_sid = c.APP_SID AND c.LIVE_METERING_SHOW_GAPS = 1 AND c.METERING_GAPS_FROM_ACQUISITION = 1
				  JOIN meter_bucket ldd ON mld.meter_bucket_id = ldd.meter_bucket_id
				  JOIN meter_input mi ON mi.meter_input_id = mld.meter_input_id
				JOIN meter_aggregator ma ON ma.aggregator = mld.aggregator
				WHERE mld.start_dtm > in_min_dtm 
				  AND mld.start_dtm > r.ACQUISITION_DTM
			) y ORDER BY y.start_dtm ASC;

	ELSE
		OPEN out_cur FOR
			SELECT * FROM (
				SELECT region_sid, ldd.meter_bucket_id, 
					mi.label meter_input, ma.label aggregator_type, mp.label priority_level, ldd.description duration_description,
					start_dtm, end_dtm, consumption, meter_raw_data_id
				  FROM meter_live_data mld
					JOIN meter_bucket ldd ON mld.meter_bucket_id = ldd.meter_bucket_id
					JOIN meter_input mi ON mi.meter_input_id = mld.meter_input_id
					JOIN meter_aggregator ma ON ma.aggregator = mld.aggregator
					JOIN meter_data_priority mp ON mp.priority = mld.priority
				 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND mld.region_sid = in_region_sid
				   AND mld.meter_input_id = in_input_id
				   AND mld.aggregator = in_aggregator
				   AND mld.priority = in_priority
				   AND mld.meter_bucket_id = in_duration_id
				   AND mld.end_dtm > in_min_dtm
				   AND mld.start_dtm < in_max_dtm
				   AND mld.consumption IS NOT NULL -- Single null for gaps provided by part of query below
				UNION ALL	
				SELECT
					x.region_sid region_sid,
					x.meter_bucket_id meter_bucket_id,
					x.meter_input,
				  	x.aggregator_type,
				  	x.priority_level,
				  	x.duration_description,
					x.end_dtm start_dtm,
					x.next_start_dtm end_dtm,
					null consumption,
					null meter_row_data_id
				 FROM (
					SELECT 
						region_sid,
						ldd.meter_bucket_id,
						end_dtm, 
						LEAD(start_dtm) over (partition by region_sid order by start_dtm) next_start_dtm,
						mi.label meter_input, ma.label aggregator_type, mp.label priority_level, ldd.description duration_description
					FROM meter_live_data mld
						JOIN meter_bucket ldd ON mld.meter_bucket_id = ldd.meter_bucket_id
						JOIN meter_input mi ON mi.meter_input_id = mld.meter_input_id
						JOIN meter_aggregator ma ON ma.aggregator = mld.aggregator
						JOIN meter_data_priority mp ON mp.priority = mld.priority
						JOIN customer c ON mld.app_sid = c.app_sid AND c.LIVE_METERING_SHOW_GAPS = 1
					WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					  AND mld.region_sid = in_region_sid
					  AND mld.meter_input_id = in_input_id
					  AND mld.aggregator = in_aggregator
					  AND mld.priority = in_priority
					  AND mld.meter_bucket_id = in_duration_id
				      AND mld.start_dtm > in_min_dtm
					  AND mld.end_dtm < in_max_dtm
					  AND mld.consumption IS NOT NULL -- Treat null consumption as no data
					) x
				 WHERE x.end_dtm != x.next_start_dtm
			) y ORDER BY y.start_dtm ASC; 
	END IF;
END;

PROCEDURE GetFinestDurationId(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_duration_id			OUT	meter_bucket.meter_bucket_id%TYPE
)
AS
	v_high_resolution		NUMBER := 1;
BEGIN
	
	IF in_region_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_high_resolution
		  FROM meter_live_data mld
		  JOIN meter_bucket mb ON mb.app_sid = mld.app_sid AND mb.meter_bucket_id = mld.meter_bucket_id
		 WHERE mb.high_resolution_only = 1
		   AND mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mld.region_sid = in_region_sid
		   AND rownum = 1;
	END IF;
	
	GetSmallestBucket(v_high_resolution, out_duration_id);
END;

PROCEDURE GetSmallestBucket(
	in_high_resolution		NUMBER,
	out_duration_id			OUT	meter_bucket.meter_bucket_id%TYPE
)
AS
BEGIN
	-- Find the most granualr resolution.
	-- We approximate the number of days in a month to be 30, 
	-- this is very unlikely to cause any issues.
	SELECT meter_bucket_id 
	  INTO out_duration_id
	  FROM (
		SELECT meter_bucket_id, duration, MIN(duration) OVER () min_duration 
		  FROM (
		  	SELECT meter_bucket_id, duration
		  	  FROM meter_bucket
		  	 WHERE app_sid = security_pkg.GetAPP
		  	   AND high_resolution_only = DECODE(in_high_resolution, 0, 0, high_resolution_only)
		  	   AND duration IS NOT NULL
		  	   AND is_minutes = 1
		  	UNION 
			SELECT meter_bucket_id, duration * 60
		  	  FROM meter_bucket
		  	 WHERE app_sid = security_pkg.GetAPP
		  	   AND high_resolution_only = DECODE(in_high_resolution, 0, 0, high_resolution_only)
		  	   AND duration IS NOT NULL
		  	   AND is_hours = 1
		  	UNION 
		  	SELECT meter_bucket_id, duration * 7 * 1440 duration
		  	  FROM meter_bucket
		  	 WHERE app_sid = security_pkg.GetAPP
		  	   AND high_resolution_only = DECODE(in_high_resolution, 0, 0, high_resolution_only)
		  	   AND duration IS NOT NULL
		  	   AND is_weeks = 1
		  	UNION
		  	SELECT meter_bucket_id, duration * 30 * 1440 duration
		  	  FROM meter_bucket
		  	 WHERE app_sid = security_pkg.GetAPP
		  	   AND high_resolution_only = DECODE(in_high_resolution, 0, 0, high_resolution_only)
		  	   AND duration IS NOT NULL
		  	   AND is_months = 1
			)
		)
	WHERE duration = min_duration;
END;

PROCEDURE GetBestDurationId (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_max_points			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_best_id				meter_bucket.meter_bucket_id%TYPE;
	v_finest_id				meter_bucket.meter_bucket_id%TYPE;
BEGIN
	-- Get the finest available ID
	GetFinestDurationId(in_region_sid, v_finest_id);
	
	BEGIN
		SELECT MAX(meter_bucket_id)
		  INTO v_best_id
		  FROM (
			SELECT meter_bucket_id, cnt, MAX(cnt) over() max_cnt  
			  FROM (
		  		SELECT meter_bucket_id, COUNT(*) cnt 
		  		  FROM v$patched_meter_live_data 
		  		 WHERE region_sid = in_region_sid
		  		   AND start_dtm >= in_start_dtm
		  		   AND end_dtm < in_end_dtm
		  		 	GROUP BY meter_bucket_id
			) WHERE cnt < in_max_points
		) WHERE cnt = max_cnt;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_best_id := v_finest_id;
	END;
	
	IF v_best_id IS NULL THEN
		v_best_id := v_finest_id;
	END IF;
	
	OPEN out_cur FOR
		SELECT b.meter_bucket_id best_duration_id, f.meter_bucket_id finest_duration_id
		  FROM meter_bucket b, meter_bucket f
		 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.meter_bucket_id = v_best_id
		   AND f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND f.meter_bucket_id = v_finest_id
		;
END;

PROCEDURE GetLastMeterDataDtm (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_duration_id			meter_bucket.meter_bucket_id%TYPE;
BEGIN
	-- Retrieve the end point for finest resolution.
	GetFinestDurationId(in_region_sid, v_duration_id);
	GetLastMeterDataDtm(in_region_sid, v_duration_id, out_cur);
END;

PROCEDURE GetLastMeterDataDtm (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_duration_id			IN	meter_bucket.meter_bucket_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT MAX(start_dtm) last_dtm
		  FROM v$patched_meter_live_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND meter_bucket_id = in_duration_id;
END;

PROCEDURE GetOrphanData (
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	in_data_limit			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT serial_id, start_dtm, end_dtm, consumption, statement_id
		  FROM meter_orphan_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND serial_id = in_serial_id
		   	ORDER BY start_dtm ASC;
END;


PROCEDURE AddIssue (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_label				IN  issue.label%TYPE,
	in_issue_dtm			IN	issue_meter.issue_dtm%TYPE,
	out_issue_id			OUT issue.issue_id%TYPE
)
AS
	v_issue_log_id			issue_log.issue_log_id%TYPE;
BEGIN
	-- Just checking read here as adding an issue shouldn't require the same level of permissions that lets you
	-- alter the actual meter (this is the same level of checks for adding readings)
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read region with sid ' || in_region_sid);
	END IF;
	
	issue_pkg.CreateIssue(
		in_label			=> in_label,
		in_source_label		=> 'Meter monitor',
		in_issue_type_id	=> csr_data_pkg.ISSUE_METER_MONITOR,
		in_region_sid		=> in_region_sid,
		out_issue_id		=> out_issue_id
	);

	INSERT INTO issue_meter (
		app_sid, issue_meter_id, region_sid, issue_dtm)
	VALUES (
		security_pkg.GetAPP, issue_meter_id_seq.NEXTVAL, in_region_sid, in_issue_dtm
	);

	UPDATE csr.issue
	   SET issue_meter_id = issue_meter_id_seq.CURRVAL
	 WHERE issue_id = out_issue_id;
	 
	-- No alert mail will be sent just because we create a new issue, we have to 
	-- actually add a log entry to that isssue befor the mail will be generated.
	issue_pkg.AddLogEntry(security_pkg.GetACT, out_issue_id, 1, in_label, null, null, null, v_issue_log_id);
END;

PROCEDURE GetIssue(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, i.manual_completion_dtm, im.issue_dtm,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved
		  FROM issue i, issue_meter im
		 WHERE i.app_sid = im.app_sid
		   AND i.issue_id = in_issue_id
		   AND i.issue_meter_id = im.issue_meter_id
		   AND im.region_sid = in_region_sid;
END;

-- Procedure for getting data sources for the data 
-- source list page (includes last raw data dtm)
PROCEDURE GetDataSources(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT x.label, x.raw_data_source_id, x.parser_type, x.helper_pkg, 
			x.export_system_values, x.export_after_dtm, x.default_issue_user_sid,
			x.orphan_count, x.matched_count, x.last_raw_data_dtm,
			x.create_meters, x.holding_region_sid, x.automated_import_class_sid,
			x.meter_date_format, x.process_body, x.proc_use_remote_service,
			hr.description holding_region_desc,
			REGEXP_REPLACE(ftp.payload_path, '(^/|/$)', '') source_folder, -- Strip starting or ending slash
			ftp.file_mask, 
			REPLACE(STRAGG(mbox.mailbox_name), ',', ';') source_email
		  FROM (
			SELECT ds.label, ds.raw_data_source_id, ds.parser_type, ds.helper_pkg, 
				ds.export_system_values, ds.export_after_dtm, ds.default_issue_user_sid,
				ds.orphan_count, ds.matched_count, MAX(rd.received_dtm) last_raw_data_dtm,
				ds.create_meters, ds.holding_region_sid, ds.automated_import_class_sid,
				ds.meter_date_format, ds.process_body, ds.proc_use_remote_service
			  FROM meter_raw_data_source ds
			  LEFT JOIN meter_raw_data rd ON rd.app_sid = ds.app_sid AND rd.raw_data_source_id = ds.raw_data_source_id
			 WHERE ds.app_sid = SYS_CONTEXT('SECURITY','APP')
			 GROUP BY ds.label, ds.raw_data_source_id, ds.parser_type, ds.helper_pkg, 
				ds.export_system_values, ds.export_after_dtm, ds.default_issue_user_sid,
				ds.orphan_count, ds.matched_count,
				ds.create_meters, ds.holding_region_sid, ds.automated_import_class_sid,
				ds.meter_date_format, ds.process_body, ds.proc_use_remote_service
		  ) x
		  LEFT JOIN v$region hr ON hr.app_sid = SYS_CONTEXT('SECURITY','APP') AND hr.region_sid = x.holding_region_sid
		  LEFT JOIN automated_import_class_step step ON step.app_sid = SYS_CONTEXT('SECURITY','APP') AND step.automated_import_class_sid = x.automated_import_class_sid AND step.step_number = 1
		  LEFT JOIN auto_imp_fileread_ftp ftp ON ftp.app_sid = SYS_CONTEXT('SECURITY','APP') AND ftp.auto_imp_fileread_ftp_id = step.auto_imp_fileread_ftp_id
		  LEFT JOIN auto_imp_mail_attach_filter mfilt ON  mfilt.app_sid = SYS_CONTEXT('SECURITY','APP') AND mfilt.matched_import_class_sid = x.automated_import_class_sid AND mfilt.is_wildcard = 1 AND mfilt.filter_string = '*'
		  LEFT JOIN mail.mailbox mbox ON mbox.mailbox_sid = mfilt.mailbox_sid
		 GROUP BY x.label, x.raw_data_source_id, x.parser_type, x.helper_pkg, 
			x.export_system_values, x.export_after_dtm, x.default_issue_user_sid,
			x.orphan_count, x.matched_count, x.last_raw_data_dtm,
			x.create_meters, x.holding_region_sid, x.automated_import_class_sid,
			x.meter_date_format, x.process_body, x.proc_use_remote_service, hr.description,
			ftp.payload_path, ftp.file_mask
		 ORDER BY LOWER(x.label);
END;

PROCEDURE UpdateDataSourceOrphanCount(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE
)
AS
	v_duration_id			meter_bucket.meter_bucket_id%TYPE;
	v_orphan_count			NUMBER;
	v_matched_count			NUMBER;
BEGIN
	-- Use the system duration ID to pick a much smaller data set (using the table index)
	-- from the live data table when trying to find distinct region sids we have matched.
	SELECT meter_bucket_id
	  INTO v_duration_id
	  FROM meter_bucket
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND IS_EXPORT_PERIOD = 1;
	
	FOR r IN (
		SELECT raw_data_source_id
		  FROM meter_raw_data_source
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = NVL(in_data_source_id, raw_data_source_id)
	) LOOP
		BEGIN
			SELECT COUNT(DISTINCT od.serial_id) orphan_count
			  INTO v_orphan_count
			  FROM csr.meter_raw_data_source ds
			  JOIN csr.meter_raw_data rd ON rd.app_sid = SYS_CONTEXT('SECURITY','APP') AND rd.raw_data_source_id = ds.raw_data_source_id
			  JOIN csr.meter_orphan_data od ON od.app_sid = SYS_CONTEXT('SECURITY','APP') AND od.meter_raw_data_id = rd.meter_raw_data_id
			 WHERE ds.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND ds.raw_data_source_id = r.raw_data_source_id
			 GROUP BY ds.raw_data_source_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_orphan_count := 0;
		END;

		BEGIN
			SELECT COUNT(DISTINCT ld.region_sid) matched_count
			  INTO v_matched_count
			  FROM csr.meter_raw_data_source ds
			  JOIN csr.meter_raw_data rd ON rd.app_sid = SYS_CONTEXT('SECURITY','APP') AND rd.raw_data_source_id = ds.raw_data_source_id
			  JOIN csr.meter_live_data ld ON ld.app_sid = SYS_CONTEXT('SECURITY','APP') AND ld.meter_raw_data_id = rd.meter_raw_data_id AND ld.meter_raw_data_id = rd.meter_raw_data_id
			 WHERE ds.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND ds.raw_data_source_id = r.raw_data_source_id
			   AND ld.meter_bucket_id = v_duration_id
			 GROUP BY ds.raw_data_source_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_matched_count := 0;
		END;

		UPDATE meter_raw_data_source
		   SET orphan_count = v_orphan_count,
		       matched_count = v_matched_count
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = r.raw_data_source_id;

	END LOOP;
END;

PROCEDURE GetDataSourceById(
	in_data_source_id				IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_high_res_inputs_cur			OUT SYS_REFCURSOR,
	out_meter_type_mappings_cur		OUT SYS_REFCURSOR
)
As
BEGIN
	OPEN out_cur FOR
		SELECT x.label, x.raw_data_source_id, x.parser_type, x.helper_pkg, 
				x.export_system_values, x.export_after_dtm, x.default_issue_user_sid,
				x.orphan_count, x.matched_count, x.last_raw_data_dtm,
				x.create_meters, x.holding_region_sid, x.automated_import_class_sid, 
				x.meter_date_format, x.process_body, x.proc_use_remote_service,
				hr.description holding_region_desc, ftp.file_mask,
				REGEXP_REPLACE(ftp.payload_path, '(^/|/$)', '') source_folder, -- Strip starting or ending slash
				REPLACE(STRAGG(mbox.mailbox_name), ',', ';') source_email
		  FROM (
			SELECT ds.label, ds.raw_data_source_id, ds.parser_type, ds.helper_pkg, 
					ds.export_system_values, ds.export_after_dtm, ds.default_issue_user_sid,
					ds.orphan_count, ds.matched_count, MAX(rd.received_dtm) last_raw_data_dtm,
					ds.create_meters, ds.holding_region_sid, ds.automated_import_class_sid, 
					ds.meter_date_format, ds.process_body, ds.proc_use_remote_service
			  FROM meter_raw_data_source ds
			  LEFT JOIN meter_raw_data rd ON rd.app_sid = ds.app_sid AND rd.raw_data_source_id = ds.raw_data_source_id
			 WHERE ds.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND ds.raw_data_source_id = in_data_source_id
			   	GROUP BY ds.label, ds.raw_data_source_id, ds.parser_type, ds.helper_pkg,
			   		ds.export_system_values, ds.export_after_dtm, ds.default_issue_user_sid,
			   		ds.orphan_count, ds.matched_count,
					ds.create_meters, ds.holding_region_sid, ds.automated_import_class_sid, 
					ds.meter_date_format, ds.process_body, ds.proc_use_remote_service
		  ) x
		  LEFT JOIN v$region hr ON hr.app_sid = SYS_CONTEXT('SECURITY','APP') AND hr.region_sid = x.holding_region_sid
		  LEFT JOIN automated_import_class_step step ON step.app_sid = SYS_CONTEXT('SECURITY','APP') AND step.automated_import_class_sid = x.automated_import_class_sid AND step.step_number = 1
		  LEFT JOIN auto_imp_fileread_ftp ftp ON ftp.app_sid = SYS_CONTEXT('SECURITY','APP') AND ftp.auto_imp_fileread_ftp_id = step.auto_imp_fileread_ftp_id
		  LEFT JOIN auto_imp_mail_attach_filter mfilt ON  mfilt.app_sid = SYS_CONTEXT('SECURITY','APP') AND mfilt.matched_import_class_sid = x.automated_import_class_sid AND mfilt.is_wildcard = 1 AND mfilt.filter_string = '*'
		  LEFT JOIN mail.mailbox mbox ON mbox.mailbox_sid = mfilt.mailbox_sid
		GROUP BY 
			x.label, x.raw_data_source_id, x.parser_type, x.helper_pkg, 
			x.export_system_values, x.export_after_dtm, x.default_issue_user_sid,
			x.orphan_count, x.matched_count, x.last_raw_data_dtm,
			x.create_meters, x.holding_region_sid, x.automated_import_class_sid, 
			x.meter_date_format, x.process_body, x.proc_use_remote_service,
			hr.description, ftp.payload_path, ftp.file_mask
		;

	OPEN out_high_res_inputs_cur FOR
		SELECT raw_data_source_id, meter_input_id
		  FROM meter_data_source_hi_res_input
		 WHERE raw_data_source_id = in_data_source_id;
		 
	meter_pkg.GetUrjanetServiceTypes(in_data_source_id, out_meter_type_mappings_cur);
END;

PROCEDURE GetDataSourceExcelOption(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_option				OUT	security_pkg.T_OUTPUT_CUR,
	out_mapping				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_option FOR
		SELECT raw_data_source_id, worksheet_index, row_index, csv_delimiter
		  FROM meter_excel_option
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = in_data_source_id;

	OPEN out_mapping FOR
		SELECT raw_data_source_id, field_name, column_name, column_index, create_meters_map_column
		  FROM meter_excel_mapping
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = in_data_source_id;
END;

PROCEDURE GetDataSourceXmlOption(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_cur					OUT	SECURITY_PKG.T_OUTPUT_CUR
)
AS
	v_automated_import_class_sid	security_pkg.T_SID_ID;
BEGIN
	-- Select the xml options from the correct place
	-- (if auto_imp_importer_settings.data_type is null then use the old settings)
	OPEN out_cur FOR
		select * from (
			SELECT 2 priority, raw_data_source_id, data_type, xslt
			  FROM meter_xml_option
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND raw_data_source_id = in_data_source_id
			UNION ALL
			SELECT 1 priority, r.raw_data_source_id, s.data_type, s.mapping_xml xslt
			  FROM auto_imp_importer_settings s
			  JOIN meter_raw_data_source r ON r.app_sid = s.app_sid AND r.automated_import_class_sid = s.automated_import_class_sid
			 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND r.raw_data_source_id = in_data_source_id
			   AND s.data_type IS NOT NULL
			 ORDER BY priority
		) where rownum = 1;
END;

PROCEDURE SaveDataSource(
	in_data_source_id			IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_label					IN	meter_raw_data_source.label%TYPE,
	in_parser_type				IN	meter_raw_data_source.parser_type%TYPE,
	in_export_system_values		IN	meter_raw_data_source.export_system_values%TYPE,
	in_export_after_dtm			IN	meter_raw_data_source.export_after_dtm%TYPE,
	in_default_user_sid			IN	meter_raw_data_source.default_issue_user_sid%TYPE,
	in_create_meters			IN	meter_raw_data_source.create_meters%TYPE,
	in_holding_region_sid		IN	meter_raw_data_source.holding_region_sid%TYPE,
	in_meter_date_format		IN	meter_raw_data_source.meter_date_format%TYPE,
	in_high_res_input_ids		IN  security_pkg.T_SID_IDS,
	in_process_body				IN	meter_raw_data_source.process_body%TYPE,
	in_proc_use_remote_service	IN	meter_raw_data_source.proc_use_remote_service%TYPE,
	out_data_source_id			OUT	meter_raw_data_source.raw_data_source_id%TYPE
)
AS
	v_count					NUMBER;
	v_system_duration_id	meter_bucket.meter_bucket_id%TYPE;
	v_nvl_dtm				DATE;
	v_high_res_input_ids	security.T_SID_TABLE := security_pkg.SidArrayToTable(in_high_res_input_ids);
	v_job_id				batch_job.batch_job_id%TYPE;
BEGIN
	
	out_data_source_id := in_data_source_id;
	IF out_data_source_id < 0 THEN
		out_data_source_id := NULL;
	END IF;
	
	v_count := 0;

	IF out_data_source_id IS NULL THEN
		INSERT INTO meter_raw_data_source
			(raw_data_source_id, label, parser_type, export_system_values, export_after_dtm, default_issue_user_sid, create_meters, holding_region_sid, meter_date_format, process_body, proc_use_remote_service)
		  VALUES (raw_data_source_id_seq.NEXTVAL, in_label, in_parser_type, in_export_system_values, in_export_after_dtm, in_default_user_sid, in_create_meters, in_holding_region_sid, in_meter_date_format, in_process_body, in_proc_use_remote_service)
		  	RETURNING raw_data_source_id INTO out_data_source_id;
	ELSE
		v_nvl_dtm := TO_DATE('01JAN1900', 'DDMONYYYY');
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM meter_raw_data_source
		 WHERE raw_data_source_id = in_data_source_id
		   AND (
		   	  export_system_values <> in_export_system_values
		   OR NVL(export_after_dtm, v_nvl_dtm) <> NVL(in_export_after_dtm, v_nvl_dtm)
		  );
		
		UPDATE meter_raw_data_source
		   SET label = in_label,
			   parser_type = in_parser_type,
			   export_system_values = in_export_system_values,
			   export_after_dtm = in_export_after_dtm, 
			   default_issue_user_sid = in_default_user_sid,
			   create_meters = in_create_meters,
			   holding_region_sid = in_holding_region_sid,
			   meter_date_format = in_meter_date_format,
			   process_body = in_process_body,
			   proc_use_remote_service = in_proc_use_remote_service
		 WHERE raw_data_source_id = out_data_source_id;

		 -- Check for hi-res input changes
		FOR r IN (
			SELECT meter_input_id
			  FROM meter_data_source_hi_res_input hri
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND raw_data_source_id = out_data_source_id
			   AND meter_input_id NOT IN (
					SELECT column_value
					 FROM TABLE(v_high_res_input_ids)
			)
			UNION
			SELECT column_value
			  FROM TABLE(v_high_res_input_ids)
			 WHERE column_value NOT IN (
				SELECT meter_input_id
				  FROM meter_data_source_hi_res_input hri
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND raw_data_source_id = out_data_source_id
			)
		) LOOP
			-- Create a batch job to recompute buckets
			AddRecomputeBucketsJob(out_data_source_id, v_job_id);
			-- Only ever create one job
			EXIT;
		END LOOP;
	END IF;
	
	DELETE FROM meter_data_source_hi_res_input
	      WHERE raw_data_source_id = out_data_source_id
		    AND meter_input_id NOT IN (SELECT column_value FROM TABLE(v_high_res_input_ids));

	INSERT INTO meter_data_source_hi_res_input (raw_data_source_id, meter_input_id)
		SELECT out_data_source_id, t.column_value
		  FROM TABLE(v_high_res_input_ids) t
		 WHERE NOT EXISTS (
		 	SELECT 1
			  FROM meter_data_source_hi_res_input
			 WHERE raw_data_source_id = out_data_source_id
			   AND meter_input_id = t.column_value
		 );
	
	IF v_count > 0 THEN
		-- Get the system duration id
		SELECT meter_bucket_id
		  INTO v_system_duration_id
		  FROM meter_bucket
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND IS_EXPORT_PERIOD = 1;
		-- For each region that has data originating from this data source...
		FOR r IN (
			SELECT DISTINCT ld.region_sid
			  FROM meter_live_data ld, meter_raw_data rd
			 WHERE ld.meter_raw_data_id = rd.meter_raw_data_id
			   AND ld.meter_bucket_id = v_system_duration_id
			   AND rd.raw_data_source_id = out_data_source_id
		) LOOP
			-- Delete existing values
			FOR v IN (
				SELECT val_id
				  FROM val
				 WHERE source_type_id = csr_data_pkg.SOURCE_TYPE_REALTIME_METER
				   AND region_sid = r.region_sid
			) LOOP
				indicator_pkg.DeleteVal(SYS_CONTEXT('SECURITY', 'ACT'), v.val_id, 'Raw data source export properties changed');
			END LOOP;
			-- Export system values using the new settings
			ExportSystemValues(r.region_sid);
		END LOOP;
	END IF;
END;

PROCEDURE SaveExcelOption(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_worksheet_index		IN	meter_excel_option.worksheet_index%TYPE,
	in_row_index			IN	meter_excel_option.row_index%TYPE,
	in_csv_delimiter		IN	meter_excel_option.csv_delimiter%TYPE,
	in_field_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_column_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_column_indexes		IN	security_pkg.T_SID_IDS,
	in_create_meter_types	IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	t_field_names			security.T_VARCHAR2_TABLE;
	t_column_names			security.T_VARCHAR2_TABLE;
	t_column_indexes		security.T_ORDERED_SID_TABLE;
	t_create_meter_types	security.T_VARCHAR2_TABLE;
BEGIN
	t_field_names := security_pkg.Varchar2ArrayToTable(in_field_names);
	t_column_names := security_pkg.Varchar2ArrayToTable(in_column_names);
	t_column_indexes := security_pkg.SidArrayToOrderedTable(in_column_indexes);
	t_create_meter_types := security_pkg.Varchar2ArrayToTable(in_create_meter_types);
	
	BEGIN
		INSERT INTO meter_excel_option
			(raw_data_source_id, worksheet_index, row_index, csv_delimiter)
		  VALUES (in_data_source_id, in_worksheet_index, in_row_index, in_csv_delimiter);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
	 		UPDATE meter_excel_option
	 		   SET worksheet_index = in_worksheet_index,
	 		   	   row_index = in_row_index,
	 		   	   csv_delimiter = in_csv_delimiter
	 		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	 		   AND raw_data_source_id = in_data_source_id;
	END;
	
	DELETE FROM meter_excel_mapping
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND raw_data_source_id = in_data_source_id;

	INSERT INTO meter_excel_mapping
		(raw_data_source_id, field_name, column_name, column_index, create_meters_map_column)
		SELECT in_data_source_id, fn.value, cn.value, ci.sid_id, cmt.value
		  FROM TABLE(t_field_names) fn, TABLE(t_column_names) cn, TABLE(t_column_indexes) ci, TABLE(t_create_meter_types) cmt
		 WHERE cn.pos = fn.pos
		   AND ci.pos = fn.pos
		   AND cmt.pos = fn.pos;
	
END;

PROCEDURE SaveDataSourceXml(
	in_data_source_id			IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_data_type				IN	auto_imp_importer_settings.data_type%TYPE,
	in_excel_worksheet_index	IN	auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_excel_row_index			IN	auto_imp_importer_settings.excel_row_index%TYPE,
	in_xml						IN 	auto_imp_importer_settings.mapping_xml%TYPE
)
AS
	v_automated_import_class_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT automated_import_class_sid
	  INTO v_automated_import_class_sid
	  FROM meter_raw_data_source
	 WHERE raw_data_source_id = in_data_source_id;

	UPDATE auto_imp_importer_settings
	   SET data_type = in_data_type,
		   excel_worksheet_index = in_excel_worksheet_index,
		   excel_row_index = in_excel_row_index,
		   mapping_xml = in_xml
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = v_automated_import_class_sid;
END;

PROCEDURE DeleteDataSource(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE
)
AS
BEGIN
	DELETE FROM urjanet_service_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;

	DELETE FROM meter_excel_mapping
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;
	
	DELETE FROM meter_excel_option
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;
	
	DELETE FROM meter_xml_option
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;
	
	DELETE FROM meter_data_source_hi_res_input
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;

	DELETE FROM meter_raw_data_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;
	 
	UPDATE meter_raw_data
	   SET automated_import_instance_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND raw_data_source_id = in_data_source_id;
END;

PROCEDURE GetRawDataList(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRawDataList(in_text, in_start_row, in_row_limit, in_sort_by, in_sort_dir, NULL, NULL, out_cur);
END;

PROCEDURE GetRawDataList(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_orphan_serial_id		IN	meter_orphan_data.serial_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(4000);
	v_order_by		VARCHAR2(4000);
BEGIN	   
	v_order_by := 'received_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'received_dtm,start_dtm,end_dtm,label,status_name,live_count,orphan_count');
	END IF;
	
	IF in_text IS NULL THEN
		v_search := '*';
	ELSE
		v_search := in_text;
		-- Excape filter string
		v_search := utils_pkg.RegexpEscape(v_search);
		-- Replace any number of white spaces with \s+
		v_search := REGEXP_REPLACE(v_search, '\s+', '\s+');   
	END IF;
		    
	IF in_region_sid IS NOT NULL THEN
		
		-- Only show entries relating to the passed region sid
		OPEN out_cur FOR
			' SELECT * ' ||
			   ' FROM (' ||
			  	' SELECT ROWNUM rn, COUNT(*) OVER() total_count, x.* FROM (' ||
			  	  ' SELECT * FROM (' ||
				  	  ' SELECT MAX(meter_raw_data_id), orphan_count, live_count,' ||
					       ' meter_raw_data_id, raw_data_source_id, received_dtm,' ||
					       ' start_dtm, end_dtm, status_id, source, status_name FROM (' ||
						' SELECT' ||
						 ' rd.orphan_count, rd.matched_count live_count,' ||
						 ' rd.meter_raw_data_id, rd.raw_data_source_id, rd.received_dtm,' ||
						 ' rd.start_dtm, rd.end_dtm, rd.status_id, ds.label, rds.description status_name,' ||
						 ' rd.automated_import_instance_id' ||
						  ' FROM meter_raw_data rd, meter_raw_data_source ds, meter_raw_data_status rds, meter_source_data sd' ||
						 ' WHERE rd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND ds.raw_data_source_id = rd.raw_data_source_id' ||
						   ' AND rds.status_id = rd.status_id' ||
						   ' AND sd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND sd.meter_raw_data_id = rd.meter_raw_data_id ' ||
						   ' AND sd.region_sid = :1 ' ||
						' ) ' ||
						' GROUP BY orphan_count, live_count,' ||
							' meter_raw_data_id, raw_data_source_id, received_dtm,' ||
							' start_dtm, end_dtm, status_id, label, file_name, status_name ' ||
					  ' ORDER BY '||v_order_by||
					' )' ||
				' ) x' ||
				' WHERE (' ||
					' REGEXP_LIKE(label, :2, ''i'')' ||
				 ' OR REGEXP_LIKE(status_name, :3, ''i'')' ||
				' )' ||
			' )' ||
			' WHERE rn >= :4' ||
			  ' AND ROWNUM <= :5'
				USING in_region_sid, v_search, v_search, in_start_row, in_row_limit;
	
	ELSIF in_orphan_serial_id IS NOT NULL THEN
		
		-- Only show entries realting to the passed serial id
		OPEN out_cur FOR
			' SELECT * ' ||
			   ' FROM (' ||
			  	' SELECT ROWNUM rn, COUNT(*) OVER() total_count, x.* FROM (' ||
			  	  ' SELECT * FROM (' ||
				  	  ' SELECT MAX(meter_raw_data_id), orphan_count, live_count,' ||
					       ' meter_raw_data_id, raw_data_source_id, received_dtm,' ||
					       ' start_dtm, end_dtm, status_id, label, status_name FROM (' ||
						' SELECT' ||
						 ' rd.orphan_count, rd.matched_count live_count,' ||
						 ' rd.meter_raw_data_id, rd.raw_data_source_id, rd.received_dtm,' ||
						 ' rd.start_dtm, rd.end_dtm, rd.status_id, ds.label, rds.description status_name,' ||
						 ' rd.automated_import_instance_id' ||
						  ' FROM meter_raw_data rd, meter_raw_data_source ds, meter_raw_data_status rds, meter_orphan_data od' ||
						 ' WHERE rd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND ds.raw_data_source_id = rd.raw_data_source_id' ||
						   ' AND rds.status_id = rd.status_id' ||
						   ' AND od.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND od.meter_raw_data_id = rd.meter_raw_data_id ' ||
						   ' AND od.serial_id = :1 ' ||
						' UNION ' ||
						' SELECT' ||
						 ' rd.orphan_count, rd.matched_count live_count,' ||
						 ' rd.meter_raw_data_id, rd.raw_data_source_id, rd.received_dtm,' ||
						 ' rd.start_dtm, rd.end_dtm, rd.status_id, ds.label, rds.description status_name,' ||
						 ' rd.automated_import_instance_id' ||
						  ' FROM meter_raw_data rd, meter_raw_data_source ds, meter_raw_data_status rds, duff_meter_region dr' ||
						 ' WHERE rd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND ds.raw_data_source_id = rd.raw_data_source_id' ||
						   ' AND rds.status_id = rd.status_id' ||
						   ' AND dr.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND dr.meter_raw_data_id = rd.meter_raw_data_id ' ||
						   ' AND dr.urjanet_meter_id = :2 ' ||
						' ) ' ||
						' GROUP BY orphan_count, live_count,' ||
							' meter_raw_data_id, raw_data_source_id, received_dtm,' ||
							' start_dtm, end_dtm, status_id, label, status_name ' ||
					  ' ORDER BY '||v_order_by||
					' )' ||
				' ) x' ||
				' WHERE (' ||
					' REGEXP_LIKE(label, :3, ''i'')' ||
				 ' OR REGEXP_LIKE(status_name, :4, ''i'')' ||
				' )' ||
			' )' ||
			' WHERE rn >= :5' ||
			  ' AND ROWNUM <= :6'
				USING in_orphan_serial_id, in_orphan_serial_id, v_search, v_search, in_start_row, in_row_limit;
	ELSE
		-- Normal operation, show everything
		OPEN out_cur FOR
			' SELECT *' ||
			  ' FROM (' ||
				 ' SELECT ROWNUM rn, COUNT(*) OVER() total_count, x.*' ||
				   ' FROM (' ||
					' SELECT *' ||
					  ' FROM (' ||
						' SELECT rd.orphan_count, rd.matched_count live_count,' ||
						  	' rd.meter_raw_data_id, rd.raw_data_source_id, rd.received_dtm,' ||
						  	' rd.start_dtm, rd.end_dtm, rd.status_id, ds.label, rds.description status_name,' ||
						  	' rd.automated_import_instance_id' ||
						  ' FROM meter_raw_data rd, meter_raw_data_source ds, meter_raw_data_status rds' ||
						 ' WHERE rd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
						   ' AND ds.raw_data_source_id = rd.raw_data_source_id' ||
						   ' AND rds.status_id = rd.status_id' ||
						   ' AND (REGEXP_LIKE(ds.label, :1, ''i'')' ||
							 ' OR REGEXP_LIKE(rds.description, :2, ''i''))' ||
					' ) x' ||
					' ORDER BY '||v_order_by||
				' ) x' ||
			' ) x' ||
			' WHERE rn >= :3' ||
			  ' AND ROWNUM <= :4'
				USING v_search, v_search, in_start_row, in_row_limit;
	END IF;
		    
END;

PROCEDURE GetRawDataListForProperty(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(4000);
	v_order_by		VARCHAR2(4000);
BEGIN	   
	v_order_by := 'received_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'received_dtm,start_dtm,end_dtm,source,status_name,live_count,orphan_count');
	END IF;
	
	IF in_text IS NULL THEN
		v_search := '*';
	ELSE
		v_search := in_text;
		-- Excape filter string
		v_search := utils_pkg.RegexpEscape(v_search);
		-- Replace any number of white spaces with \s+
		v_search := REGEXP_REPLACE(v_search, '\s+', '\s+');   
	END IF;
	
	-- Only show entries relating to the passed region sid
	OPEN out_cur FOR
		' SELECT * ' ||
		   ' FROM (' ||
			' SELECT ROWNUM rn, COUNT(*) OVER() total_count, x.* FROM (' ||
			  ' SELECT * FROM (' ||
				  ' SELECT MAX(meter_raw_data_id), orphan_count, live_count,' ||
					   ' meter_raw_data_id, raw_data_source_id, received_dtm, ' ||
					   ' start_dtm, end_dtm, status_id, source, status_name FROM (' ||
					' SELECT' ||
					 ' rd.orphan_count, rd.matched_count live_count,' ||
					 ' rd.meter_raw_data_id, rd.raw_data_source_id, rd.received_dtm,' ||
					 ' rd.start_dtm, rd.end_dtm, rd.status_id, NVL(e.source_email, rd.file_name) source, rds.description status_name' ||
					  ' FROM meter_raw_data rd' ||
					  ' JOIN meter_raw_data_source ds ON ds.raw_data_source_id = rd.raw_data_source_id' ||
					  ' JOIN meter_raw_data_status rds ON rds.status_id = rd.status_id ' ||
					  ' JOIN meter_source_data sd ON sd.meter_raw_data_id = rd.meter_raw_data_id' ||
					  ' LEFT JOIN (' ||
						' SELECT step.automated_import_class_sid, REPLACE(STRAGG(mbox.mailbox_name), '','', '';'') source_email' ||
						'   FROM automated_import_class_step step' ||
						'   LEFT JOIN auto_imp_fileread_ftp ftp ON ftp.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') AND ftp.auto_imp_fileread_ftp_id = step.auto_imp_fileread_ftp_id' ||
						'   LEFT JOIN auto_imp_mail_attach_filter mfilt ON  mfilt.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') AND mfilt.matched_import_class_sid = step.automated_import_class_sid AND mfilt.is_wildcard = 1 AND mfilt.filter_string = ''*''' ||
						'   LEFT JOIN mail.mailbox mbox ON mbox.mailbox_sid = mfilt.mailbox_sid' ||
						'  WHERE step.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') AND step.step_number = 1' ||
						'  GROUP BY step.automated_import_class_sid' ||
					  ' ) e ON e.automated_import_class_sid = ds.automated_import_class_sid' ||
					 ' WHERE rd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
					   ' AND sd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
					   ' AND sd.region_sid IN (SELECT region_sid from csr.v$region r CONNECT BY PRIOR r.region_sid = r.parent_sid ' ||
					   ' START WITH parent_sid = :1) ' ||
					' ) ' ||
					' GROUP BY orphan_count, live_count,' ||
						' meter_raw_data_id, raw_data_source_id, received_dtm,' ||
						' start_dtm, end_dtm, status_id, source, status_name ' ||
				  ' ORDER BY '||v_order_by||
				' )' ||
			' ) x' ||
			' WHERE (' ||
				' REGEXP_LIKE(source, :2, ''i'')' ||
			 ' OR REGEXP_LIKE(status_name, :3, ''i'')' ||
			' )' ||
		' )' ||
		' WHERE rn >= :4' ||
		  ' AND ROWNUM <= :5'
			USING in_region_sid, v_search, v_search, in_start_row, in_row_limit;
		    
END;

PROCEDURE UpdateRawDataOrphanCount (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	UPDATE meter_raw_data rdu
	   SET (orphan_count, matched_count) = 
	   (
		SELECT MAX(orphan_count) orphan_count, MAX(matched_count) matched_count
		  FROM ( 
			SELECT rd.meter_raw_data_id, COUNT(DISTINCT od.serial_id) orphan_count, NULL matched_count
			  FROM meter_raw_data rd, meter_orphan_data od 
			 WHERE rd.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND rd.meter_raw_data_id = NVL(in_raw_data_id, rd.meter_raw_data_id)
			   AND od.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP') 
			   AND od.meter_raw_data_id(+) = rd.meter_raw_data_id  
				GROUP BY NULL, rd.meter_raw_data_id
			UNION 
			SELECT rd.meter_raw_data_id, NULL orphan_count, COUNT(DISTINCT sd.region_sid) matched_count
			  FROM meter_raw_data rd, meter_source_data sd 
			 WHERE rd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND rd.meter_raw_data_id = NVL(in_raw_data_id, rd.meter_raw_data_id)
			   AND sd.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP') 
			   AND sd.meter_raw_data_id(+) = rd.meter_raw_data_id
				GROUP BY NULL, rd.meter_raw_data_id
		) x 
		WHERE rdu.meter_raw_data_id = x.meter_raw_data_id
		GROUP BY meter_raw_data_id
	)
	WHERE rdu.meter_raw_data_id = NVL(in_raw_data_id, rdu.meter_raw_data_id);
END;

PROCEDURE GetRawDataInfo (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_info				OUT	security_pkg.T_OUTPUT_CUR,
	out_errors				OUT	security_pkg.T_OUTPUT_CUR,
	out_pipeline_info		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_info FOR
		SELECT rd.meter_raw_data_id, rd.raw_data_source_id, rd.received_dtm,
			rd.start_dtm, rd.end_dtm, rd.status_id, 
			ds.label, rd.file_name, 
			rds.description status_name,
			rd.automated_import_instance_id,
			CASE WHEN data IS NULL THEN 0 ELSE 1 END has_data,
			CASE WHEN original_data IS NULL THEN 0 ELSE 1 END has_original_data
		  FROM meter_raw_data rd, meter_raw_data_source ds, meter_raw_data_status rds
		 WHERE rd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ds.raw_data_source_id = rd.raw_data_source_id
		   AND rds.status_id = rd.status_id
		   AND rd.meter_raw_data_id = in_raw_data_id;
		   
	OPEN out_errors FOR
		SELECT error_id, message, raised_dtm, data_dtm
		  FROM meter_raw_data_error
		 WHERE meter_raw_data_id = in_raw_data_id;
		   
	OPEN out_pipeline_info FOR
		SELECT pi.job_id, pi.pipeline_status, pi.pipeline_message, pi.pipeline_run_start, pi.pipeline_last_updated, pi.pipeline_la_name, pi.pipeline_la_status, pi.pipeline_la_errorcode, pi.pipeline_la_errormessage
		  FROM meter_processing_pipeline_info pi
		  JOIN meter_processing_job j ON j.meter_raw_data_id = in_raw_data_id;
END;


PROCEDURE GetRawDataFile (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT d.raw_data_source_id, d.meter_raw_data_id, d.received_dtm, d.mime_type, d.encoding_name, d.data, s.parser_type, d.file_name
		  FROM meter_raw_data d, meter_raw_data_source s
		 WHERE d.meter_raw_data_id = in_raw_data_id
		  AND d.raw_data_source_id = s.raw_data_source_id;
END;

PROCEDURE GetOriginalRawDataFile (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT d.raw_data_source_id, d.meter_raw_data_id, d.received_dtm, d.mime_type, d.encoding_name, d.original_data data, s.parser_type, d.file_name
		  FROM meter_raw_data d, meter_raw_data_source s
		 WHERE d.meter_raw_data_id = in_raw_data_id
		  AND d.raw_data_source_id = s.raw_data_source_id;
END;

PROCEDURE GetOrphanMeterList(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(4000);
	v_order_by		VARCHAR2(4000);
BEGIN	   
	v_order_by := 'serial_id';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'serial_id,start_dtm,end_dtm,consumption,source_email');
	END IF;
	
	
	IF in_text IS NULL THEN
		v_search := '*';
	ELSE
		v_search := in_text;
		-- Excape filter string
		v_search := utils_pkg.RegexpEscape(v_search);
		-- Replace any number of white spaces with \s+
		v_search := REGEXP_REPLACE(v_search, '\s+', '\s+');   
	END IF;
	
	OPEN out_cur FOR
		' SELECT * FROM (' ||
			' SELECT ROWNUM rn, x.* FROM (' ||
				' SELECT COUNT(*) OVER() total_count,' ||
					' serial_id, MIN(od.start_dtm) start_dtm, MAX(od.end_dtm) end_dtm, SUM(od.consumption) consumption, e.source_email' ||
				  ' FROM meter_orphan_data od' ||
				  ' JOIN meter_raw_data rd ON rd.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') AND rd.meter_raw_data_id = od.meter_raw_data_id' ||
				  ' JOIN meter_raw_data_source ds ON ds.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') AND ds.raw_data_source_id = rd.raw_data_source_id' ||
				    ' LEFT JOIN (' ||
						' SELECT step.automated_import_class_sid, REPLACE(STRAGG(mbox.mailbox_name), '','', '';'') source_email' ||
						'   FROM automated_import_class_step step' ||
						'   LEFT JOIN auto_imp_fileread_ftp ftp ON ftp.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') AND ftp.auto_imp_fileread_ftp_id = step.auto_imp_fileread_ftp_id' ||
						'   LEFT JOIN auto_imp_mail_attach_filter mfilt ON  mfilt.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') AND mfilt.matched_import_class_sid = step.automated_import_class_sid AND mfilt.is_wildcard = 1 AND mfilt.filter_string = ''*''' ||
						'   LEFT JOIN mail.mailbox mbox ON mbox.mailbox_sid = mfilt.mailbox_sid' ||
						'  WHERE step.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') AND step.step_number = 1' ||
						'  GROUP BY step.automated_import_class_sid' ||
					  ' ) e ON e.automated_import_class_sid = ds.automated_import_class_sid' ||
				 ' WHERE od.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')' ||
				   ' AND (' || -- Filter
				   		' REGEXP_LIKE(od.serial_id, :1, ''i'')' ||
				   	 ' OR REGEXP_LIKE(e.source_email, :2, ''i'')' ||
				   ' )' ||
				   ' GROUP BY od.serial_id, e.source_email'||
				   ' ORDER BY '||v_order_by||
			') x' ||
		' ) WHERE rn >= :3' ||
		    ' AND ROWNUM <= :4'
		    USING v_search, v_search, in_start_row, in_row_limit;
END;

PROCEDURE GetChartMeterExtraInfo(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.description region_desc, 
			   i.ind_sid, i.description ind_desc, 
			   m.measure_sid, NVL(mc.description, m.description) measure_desc,
			   meter_pkg.INTERNAL_GetProperty(r.region_sid) property_desc,
			   mia.meter_input_id, mi.label input_desc, mia.aggregator, agg.label aggr_desc,
			   DECODE(p.is_output, 1, NULL, p.label)  priority_desc, 
			   DECODE(p.is_output, 1, NULL, p.priority) priority
		  FROM v$region r
		  JOIN all_meter am ON am.app_sid = r.app_sid AND am.region_sid = r.region_sid
		  JOIN meter_input_aggr_ind mia ON mia.app_sid = am.app_sid AND mia.region_sid = am.region_sid
		  JOIN meter_type_input mii ON mii.app_sid = am.app_sid AND mii.meter_type_id = am.meter_type_id AND mii.meter_input_id = mia.meter_input_id AND mii.aggregator = mia.aggregator
		  JOIN meter_aggregator agg ON agg.aggregator = mia.aggregator
		  JOIN meter_input mi ON mi.app_sid = mia.app_sid AND mi.meter_input_id = mia.meter_input_id
		  LEFT JOIN v$ind i ON i.app_sid = mii.app_sid AND i.ind_sid = mii.ind_sid
		  LEFT JOIN measure m ON m.app_sid = mii.app_sid AND m.measure_sid = mii.measure_sid
		  LEFT JOIN measure_conversion mc ON mc.app_sid = mia.app_sid AND mc.measure_conversion_id = mia.measure_conversion_id
		  JOIN meter_data_priority p ON p.app_sid = r.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND r.region_sid = in_region_sid
		   AND (p.is_output = 1 OR EXISTS (
		   		SELECT 1
		   		  FROM meter_live_data mld
		   		 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   		   AND mld.region_sid = in_region_sid
		   		   AND mld.meter_input_id = mia.meter_input_id
		   		   AND mld.aggregator = mia.aggregator
		   		   AND mld.priority = p.priority
		   ))
		   AND EXISTS (
		   		SELECT 1
		   		  FROM meter_live_data mld
		   		 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   		   AND mld.region_sid = in_region_sid
		   		   AND mld.meter_input_id = mia.meter_input_id
		   		   AND mld.aggregator = mia.aggregator
		   )
		 ORDER BY mia.meter_input_id ASC, mia.aggregator ASC, p.is_output DESC, p.priority ASC
		;
END;

PROCEDURE GetChartMeterExtraInfo(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_input_id			IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.description region_desc, 
			   i.ind_sid, i.description ind_desc, 
			   m.measure_sid, NVL(mc.description, m.description) measure_desc,
			   meter_pkg.INTERNAL_GetProperty(r.region_sid) property_desc,
			   mia.meter_input_id, mi.label input_desc, mia.aggregator, agg.label aggr_desc,
			   DECODE(p.is_output, 1, NULL, p.label) priority_desc, 
			   DECODE(p.is_output, 1, NULL, p.priority) priority
		  FROM v$region r
		  JOIN all_meter am ON am.app_sid = r.app_sid AND am.region_sid = r.region_sid
		  JOIN meter_input_aggr_ind mia ON mia.app_sid = am.app_sid AND mia.region_sid = am.region_sid
		  JOIN meter_type_input mii ON mii.app_sid = am.app_sid AND mii.meter_type_id = am.meter_type_id AND mii.meter_input_id = mia.meter_input_id AND mii.aggregator = mia.aggregator
		  JOIN meter_aggregator agg ON agg.aggregator = mia.aggregator
		  JOIN meter_input mi ON mi.app_sid = mia.app_sid AND mi.meter_input_id = mia.meter_input_id
		  LEFT JOIN v$ind i ON i.app_sid = mii.app_sid AND i.ind_sid = mii.ind_sid
		  LEFT JOIN measure m ON m.app_sid = mii.app_sid AND m.measure_sid = mii.measure_sid
		  LEFT JOIN measure_conversion mc ON mc.app_sid = mia.app_sid AND mc.measure_conversion_id = mia.measure_conversion_id
		  JOIN meter_data_priority p ON p.app_sid = r.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND r.region_sid = in_region_sid
		   AND mia.meter_input_id = in_input_id
		   AND mia.aggregator = in_aggregator
		   AND (p.is_output = 1 OR EXISTS (
		   		SELECT 1
		   		  FROM meter_live_data mld
		   		 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   		   AND mld.region_sid = in_region_sid
		   		   AND mld.meter_input_id = mia.meter_input_id
		   		   AND mld.aggregator = mia.aggregator
		   		   AND mld.priority = p.priority
		   ))
		   AND EXISTS (
		   		SELECT 1
		   		  FROM meter_live_data mld
		   		 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   		   AND mld.region_sid = in_region_sid
		   		   AND mld.meter_input_id = mia.meter_input_id
		   		   AND mld.aggregator = mia.aggregator
		   )
		 ORDER BY p.is_output DESC, p.priority ASC
		;
END;

PROCEDURE GetUserPatchLevels(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	OPEN out_cur FOR
		SELECT label, priority
		  FROM meter_data_priority
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_patch = 1
		   AND is_auto_patch = 0
		   	ORDER BY priority;
END;

PROCEDURE AddRawDataSourceIssue(
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_label				IN	issue.label%TYPE,
	in_description			IN	issue.description%TYPE,
	out_issue_id			OUT	issue.issue_id%TYPE
)
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
BEGIN
	
	v_issue_user_sid := GetIssueUserFromSource(in_raw_data_source_id);
	issue_pkg.CreateIssue(
		in_label => in_label,
		in_description => in_description,
		in_source_label => 'Meter raw data source',
		in_issue_type_id => csr_data_pkg.ISSUE_METER_DATA_SOURCE,
		in_raised_by_user_sid => v_issue_user_sid,
		in_assigned_to_user_sid => v_issue_user_sid,
		in_due_dtm => NULL,
		out_issue_id => out_issue_id
	);

	INSERT INTO issue_meter_data_source (
		app_sid, issue_meter_data_source_id, raw_data_source_id)
	VALUES (
		security_pkg.GetAPP, issue_meter_data_source_id_seq.NEXTVAL, in_raw_data_source_id
	);
 	
 	UPDATE csr.issue
	   SET issue_meter_data_source_id = issue_meter_data_source_id_seq.CURRVAL
	 WHERE issue_id = out_issue_id;
	 
	-- No alert mail will be sent just because we create a new issue, we have to 
	-- actually add a log entry to that isssue before the mail will be generated.
	issue_pkg.AddLogEntry(security_pkg.GetACT, out_issue_id, 1, in_label, null, null, null, v_issue_log_id);
END;

PROCEDURE INTERNAL_AddRawDataIssue (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_label				IN  issue.label%TYPE,
	in_description			IN	issue.description%TYPE DEFAULT NULL,
	in_issue_id				IN  issue.issue_id%TYPE, 
	in_start_dtm			IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	in_end_dtm				IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	out_issue_id			OUT issue.issue_id%TYPE
)
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
	v_out_cur				security_pkg.T_OUTPUT_CUR;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_iso_start_dtm			VARCHAR2(48);
	v_iso_end_dtm			VARCHAR2(48);
	v_count					NUMBER;
	v_log_msg				VARCHAR2(4000) := in_label;
BEGIN
	v_issue_user_sid := GetIssueUserFromRaw(in_raw_data_id);
	out_issue_id := in_issue_id;

	-- Dates -> ISO strings (split into 3 cases so we can correctly produce the descripton formating)
	IF in_Start_dtm IS NOT NULL AND in_end_dtm IS NOT NULL THEN
		-- Both dates specified
		v_iso_start_dtm := TO_CHAR(in_start_dtm, ISO_DATE_TIME_FORMAT);
		v_iso_end_dtm := TO_CHAR(in_end_dtm, ISO_DATE_TIME_FORMAT);
		v_log_msg := v_log_msg || ' ({0:ISO} - {1:ISO})';
	ELSIF in_start_dtm IS NOT NULL THEN
		-- Start date only specified
		v_iso_start_dtm := TO_CHAR(in_start_dtm, ISO_DATE_TIME_FORMAT);
		v_log_msg := v_log_msg || ' ({0:ISO})';
	ELSIF in_end_dtm IS NOT NULL THEN
		-- End date only specified
		v_iso_end_dtm := TO_CHAR(in_end_dtm, ISO_DATE_TIME_FORMAT);
		v_log_msg := v_log_msg || ' ({1:ISO})';
	END IF;

	-- If we have a region sid then try and get a user from the associated role
	IF out_issue_id IS NULL THEN
		IF in_region_sid IS NOT NULL THEN
			BEGIN
			 	-- Add users in that role for this region
			 	FOR r IN (
			 		SELECT rrm.user_sid
			 		  FROM region_role_member rrm
			 		  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid
			 		 WHERE region_sid = in_region_sid
			 		   AND LOWER(r.name) IN ('meter raw data errors', 'meter administrator')
			 	) LOOP
			 		IF out_issue_id IS NULL THEN
						issue_pkg.CreateIssue(
							in_label => in_label,
							in_source_label => 'Meter raw data',
							in_issue_type_id => csr_data_pkg.ISSUE_METER_RAW_DATA,
							in_raised_by_user_sid => v_issue_user_sid,
							in_assigned_to_user_sid => r.user_sid,
							in_due_dtm => NULL,
							in_region_sid => in_region_sid,
							out_issue_id => out_issue_id
						);
			 		ELSE
			 			SELECT COUNT(*)
			 			  INTO v_count
			 			  FROM issue_involvement
			 			 WHERE issue_id = out_issue_id
			 			   AND user_sid = r.user_sid;
			 			IF v_count = 0 THEN
			 				issue_pkg.AddUser(security_pkg.GetACT, out_issue_id, r.user_sid, v_out_cur);
			 			END IF;
			 		END IF;
			 	END LOOP;
		 	EXCEPTION
		 		WHEN NO_DATA_FOUND THEN
		 			NULL;
		 	END;
	 	END IF;
	 	
	 	-- If we still need to create the issue then there's no region, no role or no user could be found for the given region/role
	 	IF out_issue_id IS NULL THEN
			issue_pkg.CreateIssue(
				in_label 				=>	in_label,
				in_description			=>	in_description,
				in_source_label			=>	'Meter raw data',
				in_issue_type_id		=>	csr_data_pkg.ISSUE_METER_RAW_DATA,
				in_raised_by_user_sid	=>	v_issue_user_sid,
				in_assigned_to_user_sid	=>	v_issue_user_sid,
				in_due_dtm				=>	NULL,
				in_region_sid			=>	in_region_sid,
				out_issue_id			=>	out_issue_id
			);
	 	END IF;
	
		INSERT INTO issue_meter_raw_data (
			app_sid, issue_meter_raw_data_id, meter_raw_data_id, region_sid)
		VALUES (
			security_pkg.GetAPP, issue_meter_raw_data_id_seq.NEXTVAL, in_raw_data_id, in_region_sid
		);
	 	
	 	UPDATE csr.issue
		   SET issue_meter_raw_data_id = issue_meter_raw_data_id_seq.CURRVAL
		 WHERE issue_id = out_issue_id;
		 
	END IF;
		
	-- Always add the isse log entry, even if it's a new issue
	issue_pkg.AddLogEntry(security_pkg.GetACT, out_issue_id, 1, v_log_msg, v_iso_start_dtm, v_iso_end_dtm, null, v_issue_log_id);
END;	

PROCEDURE AddRawDataIssue (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_label				IN  issue.label%TYPE,
	in_start_dtm			IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	in_end_dtm				IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	out_issue_id			OUT issue.issue_id%TYPE
)
AS
	v_issue_id				issue.issue_id%TYPE;
BEGIN
	-- See if we can group the issue up with something related
	-- Note that if we are going to group the information into 
	-- another issue that issue must be active and not resolved
	BEGIN
		SELECT MIN(issue_id)
		  INTO v_issue_id
		  FROM issue i, issue_meter_raw_data rd
		 WHERE i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
		   AND i.resolved_dtm IS NULL
		   AND i.closed_dtm IS NULL
		   AND rd.meter_raw_data_id = in_raw_data_id
		   AND NVL(rd.region_sid, -1) = NVL(in_region_sid, -1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_issue_id := NULL;
	END;

	INTERNAL_AddRawDataIssue(
		in_raw_data_id	=>	in_raw_Data_id,
		in_region_sid	=>	in_region_sid,	
		in_label		=>	in_label,	
		in_issue_id		=>	v_issue_id,
		in_start_dtm	=>	in_start_dtm,
		in_end_dtm		=>	in_end_dtm,
		out_issue_id	=>	out_issue_id
	);
END;

PROCEDURE AddUniqueRawDataIssue (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_label				IN  issue.label%TYPE,
	in_description			IN	issue.description%TYPE,
	in_start_dtm			IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	in_end_dtm				IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	out_issue_id			OUT issue.issue_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT issue_id
		  INTO out_issue_id
		  FROM issue i, issue_meter_raw_data rd
		 WHERE i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
		   AND i.resolved_dtm IS NULL
		   AND i.closed_dtm IS NULL
		   AND rd.meter_raw_data_id = in_raw_data_id
		   AND NVL(rd.region_sid, -1) = NVL(in_region_sid, -1)
		   AND LOWER(i.label) = LOWER(in_label);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INTERNAL_AddRawDataIssue(
				in_raw_data_id	=>	in_raw_data_id,
				in_region_sid	=>	in_region_sid,
				in_label		=>	in_label,
				in_description	=>	in_description,
				in_issue_id		=>	out_issue_id,
				in_start_dtm	=>	in_start_dtm,
				in_end_dtm		=>	in_end_dtm,
				out_issue_id	=>	out_issue_id
			);
	END;
END;

PROCEDURE GetRawDataIssue(
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, i.manual_completion_dtm, rd.meter_raw_data_id, rd.region_sid,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved
		  FROM issue i, issue_meter_raw_data rd
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND i.app_sid = rd.app_sid
		   AND i.issue_id = in_issue_id
		   AND i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id;
END;


FUNCTION GetDataSourceUrl(
	in_raw_data_source_id		IN	issue_meter_data_source.issue_meter_data_source_id%TYPE
) RETURN VARCHAR2
AS
	v_raw_data_source_id		issue_meter_data_source.raw_data_source_id%TYPE;
BEGIN
	
	-- There's no page to show the single data source so take the  
	-- user to the list instead (the list is typically very short)
	/*
	BEGIN
		SELECT raw_data_source_id
		  INTO v_raw_data_source_id
		  FROM issue_meter_data_source
		 WHERE issue_meter_data_source_id = in_issue_meter_data_source_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	*/
	
	RETURN '/csr/site/meter/monitor/dataSourceList.acds';
END;

FUNCTION GetRawDataUrl(
	in_issue_meter_raw_data_id	IN	issue_meter_raw_data.issue_meter_raw_data_id%TYPE
) RETURN VARCHAR2
AS
	v_raw_data_id				issue_meter_raw_data.meter_raw_data_id%TYPE;
BEGIN
	BEGIN
		SELECT meter_raw_data_id
		  INTO v_raw_data_id
		  FROM issue_meter_raw_data
		 WHERE issue_meter_raw_data_id = in_issue_meter_raw_data_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	RETURN '/csr/site/meter/monitor/RawDataInfo.acds?rawDataId='||v_raw_data_id;
END;

PROCEDURE LogExportSystemValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE DEFAULT NULL,
	in_end_dtm				IN	DATE DEFAULT NULL
)
AS
	v_start_dtm				DATE;
	v_end_dtm				DATE;
BEGIN
	BEGIN
		INSERT INTO temp_export_system_values (region_sid, start_dtm, end_dtm)
		VALUES (in_region_sid, in_start_dtm, in_end_dtm);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- Get the extended date range (we want null if either in_* or v_* is null)
			SELECT LEAST(in_start_dtm, start_dtm), GREATEST(in_end_dtm, end_dtm)
			  INTO v_start_dtm, v_end_dtm
			  FROM temp_export_system_values
			 WHERE region_sid = in_region_sid;

			UPDATE temp_export_system_values
			   SET start_dtm = v_start_dtm,
			       end_dtm = v_end_dtm
			 WHERE region_sid = in_region_sid;
	END;
END;

PROCEDURE BatchExportSystemValues
AS
BEGIN
	FOR r IN (
		SELECT region_sid, start_dtm, end_dtm
		  FROM temp_export_system_values
		 ORDER BY region_sid, start_dtm
	) LOOP
		-- Write out indicator values
		ExportSystemValues(
			r.region_sid,
			r.start_dtm,
			r.end_dtm
		);
		-- Delete processed region
		DELETE FROM temp_export_system_values
		 WHERE region_sid = r.region_sid;
	END LOOP;
END;

PROCEDURE ExportSystemValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE DEFAULT NULL,
	in_end_dtm				IN	DATE DEFAULT NULL
)
AS
	v_val_id		    	val.val_id%TYPE;
	v_region_date_clipping	metering_options.region_date_clipping%TYPE;
	v_acquisition_dtm		region.acquisition_dtm%TYPE;
	v_disposal_dtm			region.disposal_dtm%TYPE;
	v_daily_bucket_id		meter_bucket.meter_bucket_id%TYPE;
	v_region_sid			security_pkg.T_SID_ID;
	v_normalised			meter_live_data.consumption%TYPE;
	v_min_dtm				DATE;
	v_max_dtm				DATE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN --- Age old region acccess permission dilemma
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to meter sid '||in_region_sid);
	END IF;
	
	-- Don't export system values (fill in indicator values) for meters which are in the trash
	-- as this could cause issues with date clipping, where we get acquisition and disposal
	-- dates from the parent region.
	IF trash_pkg.IsInTrashHierarchical(security_pkg.GetACT, in_region_sid) != 0 THEN
		RETURN; -- Noting to do if the meter is in the trash.
	END IF;

	SELECT region_date_clipping
	  INTO v_region_date_clipping
	  FROM metering_options;
	
	-- Collect some useful information
	SELECT
		CASE WHEN v_region_date_clipping = 0 THEN NULL
			 WHEN r.region_type = csr_data_pkg.REGION_TYPE_RATE AND r.acquisition_dtm IS NULL THEN TRUNC(p.acquisition_dtm, 'DD')
			 ELSE TRUNC(r.acquisition_dtm, 'DD')
	   	END acquisition_dtm,
	   		 -- XXX: Legacy behaviour is to clip on disposal date even if the v_region_date_clipping flag is not set
		CASE -- WHEN st.region_date_clipping = 0 THEN NULL
			 WHEN r.region_type = csr_data_pkg.REGION_TYPE_RATE AND r.disposal_dtm IS NULL THEN TRUNC(p.disposal_dtm, 'DD')
			 ELSE TRUNC(r.disposal_dtm, 'DD')
	   	END disposal_dtm
	  INTO v_acquisition_dtm, v_disposal_dtm
	  FROM all_meter m
	  JOIN meter_source_type st ON st.app_sid = m.app_sid AND st.meter_source_type_id = m.meter_source_type_id
	  JOIN region r ON r.app_sid = m.app_sid AND r.region_sid = m.region_sid
	  JOIN region p ON p.app_sid = r.app_sid AND p.region_sid = r.parent_sid
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.region_sid = in_region_sid;
	
	-- For each meter input/aggregator with an indicator setting...
	FOR i IN (
		SELECT iai.meter_input_id, iai.aggregator, iip.ind_sid, iai.measure_conversion_id
		  FROM meter_input_aggr_ind iai
		  JOIN meter_type_input iip ON iip.app_sid = iai.app_sid AND iip.meter_type_id = iai.meter_type_id AND iip.meter_input_id = iai.meter_input_id AND iip.aggregator = iai.aggregator
		 WHERE iai.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND iai.region_sid = in_region_sid
		   AND iip.ind_sid IS NOT NULL -- meter_type_id is not nullable
	) LOOP
		-- Completely encompassed system periods...
		FOR r IN (
			SELECT d.start_dtm, d.end_dtm, d.consumption
			  FROM v$patched_meter_live_data d
			  JOIN meter_bucket b ON b.app_sid = d.app_sid AND b.meter_bucket_id = d.meter_bucket_id
			  JOIN all_meter m ON m.app_sid = d.app_sid AND m.region_sid = d.region_sid
			  LEFT JOIN meter_raw_data rd ON rd.app_sid = d.app_sid AND rd.meter_raw_data_id = d.meter_raw_data_id
			  LEFT JOIN meter_raw_data_source rds ON rds.app_sid = rd.app_sid AND rds.raw_data_source_id = rd.raw_data_source_id
			 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND d.region_sid = in_region_sid
			   AND d.meter_input_id = i.meter_input_id
			   AND d.aggregator = i.aggregator
			   AND b.is_export_period = 1
			   -- start limits
			   AND d.start_dtm >= DECODE(in_start_dtm, NULL, d.start_dtm, period_pkg.TruncToPeriodStart(b.period_set_id, in_start_dtm))
			   AND d.start_dtm >= NVL(m.export_live_data_after_dtm, d.start_dtm)
			   AND d.start_dtm >= NVL(rds.export_after_dtm, d.start_dtm)
			   AND d.start_dtm >= NVL(v_acquisition_dtm, d.start_dtm)
			   -- end limits	
			   AND d.end_dtm <= DECODE(in_end_dtm, NULL, d.end_dtm, period_pkg.TruncToPeriodEnd(b.period_set_id, in_end_dtm))
			   AND d.end_dtm <= NVL(v_disposal_dtm, d.end_dtm)
			   
		) LOOP
			Indicator_Pkg.SetValueWithReasonWithSid(
				in_user_sid						=> security_pkg.GetSID,
				in_ind_sid						=> i.ind_sid,
				in_region_sid					=> in_region_sid,
				in_period_start					=> r.start_dtm,
				in_period_end					=> r.end_dtm,
				in_val_number					=> measure_pkg.UNSEC_GetBaseValue(r.consumption, i.measure_conversion_id, r.start_dtm),
				in_source_type_id				=> csr_data_pkg.SOURCE_TYPE_REALTIME_METER, -- TODO: base this on the original source
				in_entry_conversion_id			=> i.measure_conversion_id,
				in_entry_val_number				=> r.consumption,
				in_reason						=> 'Value set by real-time metering',
				out_val_id						=> v_val_id
			);
		END LOOP;
		
		-- Try and find a daily bucket
		BEGIN
			SELECT meter_bucket_id
			  INTO v_daily_bucket_id
			  FROM meter_bucket
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND is_hours = 1
			   AND duration = 24;
		EXCEPTION
			WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
				v_daily_bucket_id := NULL;
		END;
			
		
		-- System periods with acquisition or disposal dates falling part way thorugh them
		FOR r IN (
			SELECT d.start_dtm period_start_dtm, d.end_dtm period_end_dtm,
				v_acquisition_dtm data_start_dtm, d.end_dtm data_end_dtm,
				d.consumption / (d.end_dtm - d.start_dtm) per_diem
			  FROM v$patched_meter_live_data d
			  JOIN meter_bucket b ON b.app_sid = d.app_sid AND b.meter_bucket_id = d.meter_bucket_id
			  JOIN all_meter m ON m.app_sid = d.app_sid AND m.region_sid = d.region_sid
			  LEFT JOIN meter_raw_data rd ON rd.app_sid = d.app_sid AND rd.meter_raw_data_id = d.meter_raw_data_id
			  LEFT JOIN meter_raw_data_source rds ON rds.app_sid = rd.app_sid AND rds.raw_data_source_id = rd.raw_data_source_id
			 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND d.region_sid = in_region_sid
			   AND d.meter_input_id = i.meter_input_id
			   AND d.aggregator = i.aggregator
			   AND b.is_export_period = 1
			   -- start limits
			   AND d.start_dtm >= DECODE(in_start_dtm, NULL, d.start_dtm, period_pkg.TruncToPeriodStart(b.period_set_id, in_start_dtm))
			   AND d.start_dtm >= NVL(m.export_live_data_after_dtm, d.start_dtm)
			   AND d.start_dtm >= NVL(rds.export_after_dtm, d.start_dtm)
			   AND d.start_dtm < v_acquisition_dtm
			   -- end limits
			   AND d.end_dtm <= DECODE(in_end_dtm, NULL, d.end_dtm, period_pkg.TruncToPeriodEnd(b.period_set_id, in_end_dtm))
			   AND d.end_dtm > v_acquisition_dtm
			UNION
			SELECT d.start_dtm period_start_dtm, d.end_dtm period_end_dtm,
				d.start_dtm data_start_dtm, v_disposal_dtm data_end_dtm,
				d.consumption / (d.end_dtm - d.start_dtm) per_diem
			  FROM v$patched_meter_live_data d
			  JOIN meter_bucket b ON b.app_sid = d.app_sid AND b.meter_bucket_id = d.meter_bucket_id
			  JOIN all_meter m ON m.app_sid = d.app_sid AND m.region_sid = d.region_sid
			  LEFT JOIN meter_raw_data rd ON rd.app_sid = d.app_sid AND rd.meter_raw_data_id = d.meter_raw_data_id
			  LEFT JOIN meter_raw_data_source rds ON rds.app_sid = rd.app_sid AND rds.raw_data_source_id = rd.raw_data_source_id
			 WHERE d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND d.region_sid = in_region_sid
			   AND d.meter_input_id = i.meter_input_id
			   AND d.aggregator = i.aggregator
			   AND b.is_export_period = 1
			   -- start limitis
			   AND d.start_dtm >= DECODE(in_start_dtm, NULL, d.start_dtm, period_pkg.TruncToPeriodStart(b.period_set_id, in_start_dtm))
			   AND d.start_dtm >= NVL(m.export_live_data_after_dtm, d.start_dtm)
			   AND d.start_dtm >= NVL(rds.export_after_dtm, d.start_dtm)
			   AND d.start_dtm < v_disposal_dtm
			   -- end limits
			   AND d.end_dtm <= DECODE(in_end_dtm, NULL, d.end_dtm, period_pkg.TruncToPeriodEnd(b.period_set_id, in_end_dtm))
			   AND d.end_dtm > v_disposal_dtm
		) LOOP
			-- Try for better resolution when clipping dates part way through a system period
			IF v_daily_bucket_id IS NOT NULL THEN
				-- We have a daily bucket, sum over the clipped period
				SELECT SUM(consumption)
				  INTO v_normalised
				  FROM v$patched_meter_live_data
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND meter_input_id = i.meter_input_id
				   AND aggregator = i.aggregator
				   AND meter_bucket_id = v_daily_bucket_id
				   AND start_dtm >= r.data_start_dtm
				   AND end_dtm <= r.data_end_dtm;
			ELSE
				-- No daily bucket normalise the value for the system period	
				v_normalised := r.per_diem * (r.data_end_dtm - r.data_start_dtm);
			END IF;
			
			-- Set the sayatem indicator value
			Indicator_Pkg.SetValueWithReasonWithSid(
				in_user_sid						=> security_pkg.GetSID,
				in_ind_sid						=> i.ind_sid,
				in_region_sid					=> in_region_sid,
				in_period_start					=> r.period_start_dtm,
				in_period_end					=> r.period_end_dtm,
				in_val_number					=> measure_pkg.UNSEC_GetBaseValue(v_normalised, i.measure_conversion_id, r.period_start_dtm),
				in_source_type_id				=> csr_data_pkg.SOURCE_TYPE_REALTIME_METER, -- TODO: base this on the original source
				in_entry_conversion_id			=> i.measure_conversion_id,
				in_entry_val_number				=> v_normalised,
				in_reason						=> 'Value set by real-time metering',
				out_val_id						=> v_val_id
			);
			
		END LOOP;
		
		-- Do some housekeeping on val
		BEGIN
			-- Fetch the consumption data range form the system bucket
			-- accounting for acquisition and disposal dates as required
			SELECT region_sid, 
				GREATEST(min_dtm, NVL(v_acquisition_dtm, min_dtm)), 
				LEAST(max_dtm, NVL(v_disposal_dtm, max_dtm))
				INTO v_region_sid,  -- force exception if no data
				  	 v_min_dtm, v_max_dtm
			  FROM (
				SELECT d.region_sid, MIN(d.start_dtm) min_dtm, MAX(d.end_dtm) max_dtm
				  FROM v$patched_meter_live_data d
				  JOIN meter_bucket b ON b.app_sid = d.app_sid AND b.meter_bucket_id = d.meter_bucket_id AND b.is_export_period = 1
				 WHERE d.region_sid = in_region_sid
				   AND d.meter_input_id = i.meter_input_id
				   AND d.aggregator = i.aggregator
				   AND d.consumption IS NOT NULL
				 	GROUP BY d.region_sid
			  );
			
			-- Delete anything outside the data range
			FOR r IN (
				SELECT v.val_id
				  FROM val v
				 WHERE v.region_sid = v_region_sid
				   AND v.ind_sid = i.ind_sid
				   AND v.source_type_id IN (
				   	csr_data_pkg.SOURCE_TYPE_METER,
				   	csr_data_pkg.SOURCE_TYPE_REALTIME_METER)
				   AND (
				   		   v.period_end_dtm <= v_min_dtm
					   	OR v.period_start_dtm >= v_max_dtm
				   )
			) LOOP
				INTERNAL_DeleteVal(r.val_id);
			END LOOP;
			
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- No more readings in the system buckets, remove everything from val
				INTERNAL_DeleteValData(in_region_sid, i.ind_sid);
		END;
		
	END LOOP; -- End for each meter input

	-- Refresh the coverage aggregate ind group
	INTERNAL_RefreshCoverageAggr(in_Start_dtm, in_end_dtm);
END;

PROCEDURE GetProcessedFileNames (
	in_raw_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT file_name
		  FROM meter_raw_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND raw_data_source_id = in_raw_data_source_id
		   AND file_name IS NOT NULL
	;
END;

PROCEDURE MissingDataReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_duration_id				meter_bucket.meter_bucket_id%TYPE;				
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('csr.meter_monitor_pkg.MissingDataReport') THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied creating report.');
	END IF;
	
	GetFinestDurationId(NULL, v_duration_id);
	
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT meter_pkg.INTERNAL_GetProperty(x.region_sid) property_name, 
				x.region_sid meter_sid, r.description meter_name, 
				x.end_dtm missing_period_start, x.next_start_dtm missing_period_end
			 FROM (
				SELECT region_sid, end_dtm, 
					   LEAD(start_dtm) over (partition by region_sid ORDER BY start_dtm) next_start_dtm
				  FROM v$patched_meter_live_data 
				 WHERE meter_bucket_id = v_duration_id
			) x
			  JOIN v$region r ON  x.region_sid = r.region_sid
			  JOIN all_meter m ON m.region_sid = x.region_sid
			 WHERE x.end_dtm != x.next_start_dtm
			   AND m.manual_data_entry = 0
		) ORDER BY property_name, meter_name, missing_period_start;
END;

PROCEDURE CreateMeterMissingDataIssue(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN  date,
	in_end_dtm				IN	date,
	in_label				IN  issue.label%TYPE
	--out_issue_id			OUT issue.issue_id%TYPE
)
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
	v_out_cur				security_pkg.T_OUTPUT_CUR;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_count					NUMBER;
	v_issue_id				issue.issue_id%TYPE;
BEGIN
	v_issue_user_sid := security_pkg.GetSID;
	
	-- check if the issue was already marked
	BEGIN
		SELECT issue_id
		  INTO v_issue_id
		  FROM issue i
		  JOIN issue_meter_missing_data md ON i.issue_meter_missing_data_id = md.issue_meter_missing_data_id
		 WHERE i.resolved_dtm IS NULL
		   AND i.closed_dtm IS NULL
		   AND md.start_dtm = in_start_dtm
		   AND md.end_dtm = in_end_dtm
		   AND md.region_sid = in_region_sid;
		
		-- Stop spamming the issue_log table with the same error, over and over.
		RETURN;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_issue_id := NULL;
	END;
	
	-- If we have a region sid then try and get a user from the associated role
	IF in_region_sid IS NOT NULL THEN
		BEGIN
			-- Add users in that role for this region
			FOR r IN (
				SELECT user_sid
					FROM region_role_member rrm
					JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid
					WHERE region_sid = in_region_sid
					AND LOWER(r.name) IN ('meter missing data errors', 'meter administrator')
			) LOOP
				IF v_issue_id IS NULL THEN
					issue_pkg.CreateIssue(
						in_label => in_label,
						in_source_label => 'Meter missing data',
						in_issue_type_id => csr_data_pkg.ISSUE_METER_MISSING_DATA,
						in_raised_by_user_sid => v_issue_user_sid,
						in_assigned_to_user_sid => r.user_sid,
						in_due_dtm => NULL,
						in_region_sid => in_region_sid,
						out_issue_id => v_issue_id
					);
				ELSE
					SELECT COUNT(*)
						INTO v_count
						FROM issue_involvement
						WHERE issue_id = v_issue_id
						AND user_sid = r.user_sid;
					IF v_count = 0 THEN
						issue_pkg.AddUser(security_pkg.GetACT, v_issue_id, r.user_sid, v_out_cur);
					END IF;
				END IF;
			END LOOP;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	
	-- If we still need to create the issue then there's no region, no role or no user could be found for the given region/role
	IF v_issue_id IS NULL THEN
		issue_pkg.CreateIssue(
			in_label => in_label,
			in_source_label => 'Meter missing data',
			in_issue_type_id => csr_data_pkg.ISSUE_METER_MISSING_DATA,
			in_raised_by_user_sid => v_issue_user_sid,
			in_assigned_to_user_sid => v_issue_user_sid,
			in_due_dtm => NULL,
			in_region_sid => in_region_sid,
			out_issue_id => v_issue_id
		);
	END IF;

	INSERT INTO issue_meter_missing_data (
		app_sid, region_sid, issue_meter_missing_data_id, start_dtm, end_dtm)
	VALUES (
		security_pkg.GetAPP, in_region_sid, issue_meter_missing_data_seq.NEXTVAL, in_start_dtm, in_end_dtm
	);
	
	UPDATE csr.issue
		SET issue_meter_missing_data_id = issue_meter_missing_data_seq.CURRVAL
		WHERE issue_id = v_issue_id;
	

 	issue_pkg.AddLogEntry(security_pkg.GetACT, v_issue_id, 1, in_label, null, null, null, v_issue_log_id);
END;

PROCEDURE GetMissingDataIssue(
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
			i.issue_id,
			i.label,
			i.resolved_dtm,
			i.manual_completion_dtm,
			md.issue_meter_missing_data_id,
			md.region_sid,
			CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved
		  FROM issue i
			JOIN issue_meter_missing_data md ON i.issue_meter_missing_data_id = md.issue_meter_missing_data_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND i.app_sid = md.app_sid
		   AND i.issue_id = in_issue_id;
END;

FUNCTION GetMissingDataUrl(
	in_issue_meter_missing_data_id	IN	issue_meter_missing_data.issue_meter_missing_data_id%TYPE
) RETURN VARCHAR2
AS
	v_region_sid				issue_meter_missing_data.region_sid%TYPE;
BEGIN
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM issue_meter_missing_data
		 WHERE issue_meter_missing_data_id = in_issue_meter_missing_data_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	RETURN '/csr/site/meter/monitor/MeterMissingData.acds?meterSid='||v_region_sid;
END;

PROCEDURE GetMeterMissingDataInfo(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	  SELECT
		  immd.REGION_SID METER_ID,
		  immd.ISSUE_METER_MISSING_DATA_ID METER_MISSING_DATA_ID,
		  i.ISSUE_ID,
		  immd.START_DTM MISSING_PERIOD_START,
		  immd.END_DTM MISSING_PERIOD_END,
		  i.RAISED_DTM ISSUE_REGISTERED
		FROM issue_meter_missing_data immd
		  JOIN issue i on immd.issue_meter_missing_data_id = i.issue_meter_missing_data_id AND i.DELETED = 0
		WHERE immd.region_sid = in_region_sid
	  ORDER BY MISSING_PERIOD_START;
END;

PROCEDURE GetMeterMissingDataInfo(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_order_by		VARCHAR2(4000);
BEGIN
	v_order_by := 'start_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'raised_dtm,start_dtm,end_dtm');
	END IF;
	
	OPEN out_cur FOR
	    ' SELECT * FROM ( ' ||
			' SELECT ROWNUM rn, x.* FROM ( ' ||
				' SELECT ' ||
					' COUNT(*) OVER() total_count, ' ||
					' immd.REGION_SID, ' ||
					' immd.ISSUE_METER_MISSING_DATA_ID, ' ||
					' i.ISSUE_ID, ' ||
					' i.RAISED_DTM, ' ||
					' immd.START_DTM, ' ||
					' immd.END_DTM ' ||
				  ' FROM issue_meter_missing_data immd ' ||
					' JOIN issue i on immd.issue_meter_missing_data_id = i.issue_meter_missing_data_id and i.DELETED = 0 ' ||
				  ' WHERE immd.region_sid = :1 ' ||
				  ' ORDER BY '||v_order_by||
				' ) x ' ||
			' ) ' ||
			' WHERE rn >= :2 ' ||
			  ' AND ROWNUM <= :3 '
			USING in_region_sid, in_start_row, in_row_limit;
END;

PROCEDURE GetMetersWithMissingData(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT
			r.description DESCRIPTION,
			immd.region_sid METER_ID,
			csr.meter_pkg.INTERNAL_GetProperty(immd.region_sid) LOCATION,
			COUNT (immd.ISSUE_METER_MISSING_DATA_ID) NUMBER_OF_MISSING_PERIODS
		 FROM csr.issue_meter_missing_data immd
			JOIN csr.v$region r ON immd.REGION_SID = r.REGION_SID
			JOIN csr.issue i on immd.issue_meter_missing_data_id = i.issue_meter_missing_data_id AND i.DELETED = 0
		 WHERE immd.app_sid = SYS_CONTEXT('SECURITY','APP')
		 GROUP BY immd.region_sid, r.description
		 ORDER BY LOCATION, DESCRIPTION;
END;

PROCEDURE GetMetersWithMissingData(
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_order_by		VARCHAR2(4000);
BEGIN
	v_order_by := 'property_name';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter_sid,gaps_count,meter_name,property_name,');
	END IF;

	OPEN out_cur FOR
		' SELECT * FROM ( ' ||
			' SELECT ROWNUM rn, x.* FROM ( ' ||
				' SELECT ' ||
					' COUNT(*) OVER() total_count, ' ||
					' immd.region_sid meter_sid, ' ||
					' COUNT (immd.ISSUE_METER_MISSING_DATA_ID) gaps_count, ' ||
					' r.description meter_name, ' ||
					' csr.meter_pkg.INTERNAL_GetProperty(immd.region_sid) property_name ' ||
				 ' FROM csr.issue_meter_missing_data immd ' ||
					' JOIN csr.v$region r ON immd.REGION_SID = r.REGION_SID ' ||
					' JOIN csr.issue i on immd.issue_meter_missing_data_id = i.issue_meter_missing_data_id AND i.DELETED = 0 ' ||
				 ' WHERE immd.app_sid = SYS_CONTEXT(''SECURITY'',''APP'') ' ||
				 ' GROUP BY immd.region_sid, r.description ' ||
				 ' ORDER BY '||v_order_by||
				' ) x ' ||
			' ) ' ||
			' WHERE rn >= :1 ' ||
			  ' AND ROWNUM <= :2 '	 
			USING in_start_row, in_row_limit;
END;

PROCEDURE GetAppsToProcessMissingData (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		select crt.app_sid
			from customer_region_type crt
				join customer c on crt.app_sid = c.app_sid and c.LIVE_METERING_SHOW_GAPS = 1
			where region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER;
END;

PROCEDURE MissingDataCheckNewValues
AS
	v_issue_user_sid	security.security_pkg.T_SID_ID;
	v_now				date DEFAULT SYSDATE;
BEGIN
	v_issue_user_sid := security.security_pkg.GetSID;
 
	UPDATE issue 
	   SET deleted = 1, 
	       resolved_dtm = v_now, 
		   closed_dtm = v_now, 
		   resolved_by_user_sid = v_issue_user_sid, 
		   closed_by_user_sid = v_issue_user_sid
	 WHERE issue_id IN (
		SELECT DISTINCT i.issue_id 
		  FROM issue i
		  JOIN issue_meter_missing_data immd ON immd.issue_meter_missing_data_id = i.issue_meter_missing_data_id 
		  JOIN v$patched_meter_live_data mld ON mld.app_sid = i.app_sid
		   AND mld.region_sid = i.region_sid
		   AND immd.start_dtm <= mld.start_dtm
		   AND immd.end_dtm >= mld.end_dtm
		   AND consumption IS NOT NULL
		 WHERE i.app_sid = security.security_pkg.GetApp
		   AND i.deleted = 0
	   );

END;

PROCEDURE GetWidestBucketBounds(
	in_dtm				IN	DATE,
	in_hi_res			IN	NUMBER,
	out_min_dtm			OUT	DATE,
	out_max_dtm			OUT DATE
)
AS
	v_base_dtm			DATE;
	v_period_start_dtm	DATE;
	v_period_end_dtm	DATE;
BEGIN
	out_min_dtm := NULL;
	out_max_dtm := NULL;
	
	FOR d IN (
		SELECT meter_bucket_id, duration, 
			is_minutes, is_hours,
			is_weeks, week_start_day,
			is_months, start_month,
			period_set_id, period_interval_id
		  FROM meter_bucket
		 WHERE high_resolution_only = DECODE(in_hi_res, 1, high_resolution_only, 0)
		   AND (duration IS NOT NULL
		    OR (period_set_id IS NOT NULL AND period_interval_id IS NOT NULL))
		 ORDER BY is_export_period, is_months, is_hours, is_minutes, duration DESC
	) LOOP
		IF d.is_minutes = 1 THEN
			-- Minutes case
			v_period_start_dtm := TRUNC(in_dtm, 'YEAR') + ROUND((TRUNC(in_dtm, 'MI') - TRUNC(in_dtm, 'YEAR')) * 1440 / d.duration) * d.duration / 1440;
			v_period_end_dtm := v_period_start_dtm + d.duration / 1440;
		
		ELSIF d.is_hours = 1 THEN
			-- Hours case
			v_period_start_dtm := TRUNC(in_dtm, 'YEAR') + ROUND((TRUNC(in_dtm, 'HH') - TRUNC(in_dtm, 'YEAR')) * 24 / d.duration) * d.duration / 24;
			v_period_end_dtm := v_period_start_dtm + d.duration / 24;
			
		ELSIF d.is_weeks = 1 THEN
			-- Weeks case, allows start day of week to be specified
			-- Start day = 1 means midnight Monday
			v_base_dtm := TRUNC(in_dtm, 'DAY') + d.week_start_day;
			IF v_base_dtm > TRUNC(in_dtm, 'DD') THEN
				v_base_dtm := v_base_dtm - 7;
			END IF;
			
			v_period_start_dtm := v_base_dtm + ROUND((TRUNC(in_dtm, 'DD') - v_base_dtm) / (d.duration * 7)) * d.duration * 7;
			v_period_end_dtm := v_period_start_dtm + d.duration * 7;
			
		ELSIF d.is_months = 1 THEN
			-- Months case, allows start month to be specified
			-- Start month = 1 means January
			v_base_dtm := ADD_MONTHS(TRUNC(TRUNC(in_dtm, 'YEAR'),'MONTH'), d.start_month - 1);
			IF v_base_dtm > TRUNC(in_dtm, 'MONTH') THEN
				v_base_dtm := v_base_dtm - 12;
			END IF;
			
			v_period_start_dtm := ADD_MONTHS(v_base_dtm, ROUND(MONTHS_BETWEEN(TRUNC(in_dtm, 'MONTH'), v_base_dtm) / d.duration) * d.duration);
			v_period_end_dtm := ADD_MONTHS(v_period_start_dtm, d.duration);
		
		ELSIF d.period_set_id IS NOT NULL AND d.period_interval_id IS NOT NULL THEN
			-- We're using a period defined by the main system for this bucket (supports 13p)
			v_period_start_dtm := period_pkg.TruncToPeriodStart(d.period_set_id, in_dtm);
			v_period_end_dtm := period_pkg.TruncToPeriodEnd(d.period_set_id, in_dtm);
		END IF;
		
		-- Find the bounding dates
		out_min_dtm := LEAST(NVL(out_min_dtm, v_period_start_dtm), v_period_start_dtm);
		out_max_dtm := GREATEST(NVL(out_max_dtm, v_period_end_dtm), v_period_end_dtm); 
		
	END LOOP;
END;

FUNCTION GetMinBucketBound(
	in_dtm			IN	DATE,
	in_hi_res		IN	NUMBER
) RETURN DATE
AS
	v_min_dtm		DATE;
	v_max_dtm		DATE;
BEGIN
	GetWidestBucketBounds(
		in_dtm,
		in_hi_res,
		v_min_dtm,
		v_max_dtm
	);
	RETURN v_min_dtm;
END;

FUNCTION GetMaxBucketBound(
	in_dtm			IN	DATE,
	in_hi_res		IN	NUMBER
) RETURN DATE
AS
	v_min_dtm		DATE;
	v_max_dtm		DATE;
BEGIN
	GetWidestBucketBounds(
		in_dtm,
		in_hi_res,
		v_min_dtm,
		v_max_dtm
	);
	RETURN v_max_dtm;
END;




PROCEDURE GetMetersMissingDataDetails (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_duration_id				meter_bucket.meter_bucket_id%TYPE;
BEGIN
	GetFinestDurationId(NULL, v_duration_id);
	
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT * FROM (
				SELECT
					x.region_sid meter_sid, r.description meter_name, 
					x.end_dtm missing_period_start, x.next_start_dtm missing_period_end
				 FROM (
					SELECT region_sid, end_dtm, 
						   LEAD(start_dtm) over (partition by region_sid ORDER BY start_dtm) next_start_dtm
					  FROM v$patched_meter_live_data mld
					  JOIN customer c ON mld.app_sid = c.app_sid and c.live_metering_show_gaps = 1
					 WHERE meter_bucket_id = v_duration_id
					   AND mld.app_sid = SYS_CONTEXT('SECURITY','APP')
					   AND mld.consumption IS NOT NULL	
				 ) x
				  JOIN v$region r ON x.region_sid = r.region_sid
				  JOIN all_meter m ON m.region_sid = x.region_sid
				  JOIN customer c ON r.app_sid = c.app_sid
				 WHERE m.manual_data_entry = 0
				   AND x.end_dtm != x.next_start_dtm
				   AND (
						c.metering_gaps_from_acquisition = 0
						OR
						r.acquisition_dtm IS NULL
						OR
						x.end_dtm >= r.acquisition_dtm
					   )
				   AND (
						c.metering_gaps_from_acquisition = 0
						OR
						r.disposal_dtm IS NULL
						OR
						x.next_start_dtm <= r.disposal_dtm
					   )
			)
			UNION ALL
			SELECT
			  r.region_sid meter_sid,
			  r.description meter_name, 
			  r.ACQUISITION_DTM missing_period_start,
			  mld.start_dtm missing_period_end
			from (
			  select 
				min(start_dtm) start_dtm,
				app_sid,
				region_sid
				from v$patched_meter_live_data
				where meter_bucket_id = v_duration_id
				  and app_sid = SYS_CONTEXT('SECURITY','APP')
				  AND consumption IS NOT NULL
				group by app_sid, region_sid
			  ) mld
			  join csr.v$region r on mld.region_sid = r.region_sid
			  join csr.customer c on mld.app_sid = c.APP_SID and c.LIVE_METERING_SHOW_GAPS = 1 and c.METERING_GAPS_FROM_ACQUISITION = 1
			where TRUNC(mld.start_dtm, 'DD') > TRUNC(r.ACQUISITION_DTM, 'DD') + 0 /* tolerance in days */
		)
		ORDER BY meter_sid, missing_period_start;

END;

PROCEDURE UpdateLatestFileData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_file_name					IN	meter_raw_data.file_name%TYPE,
	in_mime_type					IN	meter_raw_data.mime_type%TYPE,
	in_new_data						IN	meter_raw_data.data%TYPE
)
AS
BEGIN
	IF in_new_data IS NOT NULL THEN

		UPDATE meter_raw_data
		   SET original_mime_type = mime_type,
		       original_file_name = file_name,
		       original_data = data
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = in_meter_raw_data_id
  		   AND original_data IS NULL;

		UPDATE meter_raw_data
		   SET file_name = NVL(in_file_name, file_name),
		       mime_type = NVL(in_mime_type, mime_type),
		       data = in_new_data
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = in_meter_raw_data_id;

  		AuditRawDataChange(
			in_meter_raw_data_id,
			'Latest raw data file updated',
			in_mime_type,
			in_file_name,
			in_new_data
		);
  	END IF;
END;

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_file_name					IN	meter_raw_data.file_name%TYPE,
	in_mime_type					IN	meter_raw_data.mime_type%TYPE,
	in_new_data						IN	meter_raw_data.data%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_batch_job_id					batch_job.batch_job_id%TYPE;
	v_automated_import_instance_id	automated_import_instance.automated_import_instance_id%TYPE;
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	-- Is this a normal real-time meter resubmission or is it an automated import
	SELECT automated_import_instance_id
	  INTO v_automated_import_instance_id
	  FROM meter_raw_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id;

	AuditRawDataChange(
		in_meter_raw_data_id,
		'Raw data resubmitted'
	);

	-- Submint a new data file
	UpdateLatestFileData(
		in_meter_raw_data_id,
		in_file_name,
		in_mime_type,
		in_new_data
	);

	-- XXX: We no longer get urjanet data files (with duff regions) in the meter_raw_data table.
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_RETRY
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = in_meter_raw_data_id;

		-- Clear down old errors here as we're reprocessing the file
		-- (there's no good place to clear them down just before rocessing starts)
		DELETE FROM meter_raw_data_error
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = in_meter_raw_data_id;

  		-- Clear down old errors here as we're reprocessing the file
  		-- (there's no good place to clear them down just before processing starts)
  		DELETE FROM meter_raw_data_error
  		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = in_meter_raw_data_id;

	AuditRawDataChange(
		in_meter_raw_data_id,
		'Status set to retry'
	);

	-- Create raw batch job to reprocess the raw data
	INTERNAL_QueueRawDataImportJob(
		in_meter_raw_data_id	=> in_meter_raw_data_id,
		out_batch_job_id		=> v_batch_job_id
	);

	OPEN out_cur FOR
		SELECT v_batch_job_id batch_job_id, 
			v_automated_import_instance_id automated_import_instance_id
		  FROM DUAL;
END;

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	ResubmitRawData(
		in_meter_raw_data_id,
		NULL, NULL, NULL, -- No file update
		out_cur
	);
END;

PROCEDURE ScheduleRawDataImportRevert(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_batch_job_id					batch_job.batch_job_id%TYPE;
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	-- Clear down old errors here as we're reprocessing the file
	-- (there's no good place to clear them down just before processing starts)
	DELETE FROM meter_raw_data_error
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id;

	-- Set status to reverting
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_REVERTING
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id;

	-- Create the job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_METER_IMPORT_REVERT,
		in_description => 'Raw meter data import revert',
		out_batch_job_id => v_batch_job_id
	);

	-- Store meter_raw_data_id
	INSERT INTO meter_import_revert_batch_job(batch_job_id, meter_raw_data_id)
		 VALUES (v_batch_job_id, in_meter_raw_data_id);

	AuditRawDataChange(
		in_meter_raw_data_id,
		'Raw meter data import has been scheduled for reversion.'
	);

	OPEN out_cur FOR
		SELECT v_batch_job_id AS batch_job_id
		  FROM dual;
END;

PROCEDURE ProcessRawDataImportRevert (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
)
AS
	v_meter_raw_data_id				meter_raw_data.meter_raw_data_id%TYPE;
	v_count							NUMBER;
	v_i								NUMBER := 0;
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	-- Fetch meter_raw_data_id
	SELECT meter_raw_data_id
	  INTO v_meter_raw_data_id
	  FROM meter_import_revert_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;

	SELECT COUNT(DISTINCT region_sid) + 1
	  INTO v_count
	  FROM meter_source_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = v_meter_raw_data_id;

	batch_job_pkg.SetProgress(in_batch_job_id, v_i, v_count);

	-- Revert
	FOR r IN (
		SELECT region_sid, MIN(start_dtm) AS start_dtm, MAX(end_dtm) AS end_dtm
		  FROM meter_source_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = v_meter_raw_data_id
		  GROUP BY region_sid
	) LOOP
		-- Gotta recompute first because of a bug that doesn't set meter_raw_data_id in meter_live_data
		meter_patch_pkg.INTERNAL_RecomputeMeterData(r.region_sid, r.start_dtm, r.end_dtm);

		DELETE FROM meter_reading_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = v_meter_raw_data_id
		   AND region_sid = r.region_sid;

		DELETE FROM meter_source_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = v_meter_raw_data_id
		   AND region_sid = r.region_sid;

		DELETE FROM meter_live_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = v_meter_raw_data_id
		   AND region_sid = r.region_sid;

		FOR i IN (
			SELECT DISTINCT i.issue_id
			  FROM issue_meter_raw_data imrd
			  JOIN issue i ON imrd.issue_meter_raw_data_id = i.issue_meter_raw_data_id
			 WHERE imrd.meter_raw_data_id = v_meter_raw_data_id
			   AND imrd.region_sid = r.region_sid
		) LOOP
			issue_pkg.UNSEC_DeleteIssue(i.issue_id);
		END LOOP;

		-- Recompute
		meter_patch_pkg.INTERNAL_RecomputeMeterData(r.region_sid, r.start_dtm, r.end_dtm);

		v_i := v_i + 1;
		batch_job_pkg.SetProgress(in_batch_job_id, v_i, v_count);
	END LOOP;

	DELETE FROM meter_orphan_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = v_meter_raw_data_id;

	-- Clean up
	DELETE FROM meter_import_revert_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;

	-- Complete
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_REVERTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = v_meter_raw_data_id;

	AuditRawDataChange(
		v_meter_raw_data_id,
		'Raw meter data import has been reverted.'
	);

	batch_job_pkg.SetProgress(in_batch_job_id, v_count, v_count);

	out_result_desc := 'Raw meter data import has been successfully reverted.';
	out_result_url := NULL;
END;

PROCEDURE ResubmitOriginalRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	UPDATE meter_raw_data
	   SET mime_type = original_mime_type,
	       file_name = original_file_name,
	       data = original_data
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id
	   AND original_data IS NOT NULL;

	ResubmitRawData(
		in_meter_raw_data_id,
		out_cur
	);
END;

PROCEDURE SubmitRawDataFromCache(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_cache_key					IN	aspen2.filecache.cache_key%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_file_name						meter_raw_data.file_name%TYPE;
	v_mime_type						meter_raw_data.mime_type%TYPE;
	v_data							meter_raw_data.data%TYPE;
BEGIN

	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	SELECT filename, mime_type, object
	  INTO v_file_name, v_mime_type, v_data
	  FROM aspen2.filecache 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cache_key = in_cache_key;

	ResubmitRawData(
		in_meter_raw_data_id,
		v_file_name,
		v_mime_type,
		v_data,
		out_cur
	);
END;

PROCEDURE AuditRawDataChange(
	in_meter_raw_data_id		IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_text						IN	meter_raw_data_log.log_text%TYPE
)
AS
BEGIN
	AuditRawDataChange(
		in_meter_raw_data_id,
		in_text,
		NULL, NULL, NULL
	);
END;

PROCEDURE AuditRawDataChange(
	in_meter_raw_data_id		IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_text						IN	meter_raw_data_log.log_text%TYPE,
	in_mime_type				IN	meter_raw_data_log.mime_type%TYPE,
	in_file_name				IN	meter_raw_data_log.file_name%TYPE,
	in_data						IN	meter_raw_data_log.data%TYPE
)
AS
BEGIN
	INSERT INTO meter_raw_data_log (meter_raw_data_id, log_id, log_text, data)
	VALUES (in_meter_raw_data_id, meter_raw_data_log_id_seq.NEXTVAL, in_text, in_data);
END;

PROCEDURE SetupAutoCreateMeters(
	in_automated_import_class_sid	IN  security_pkg.T_SID_ID,
	in_data_source_id				IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mapping_xml					IN	VARCHAR2,
	in_delimiter					IN 	VARCHAR2,
	in_ftp_path						IN	VARCHAR2,
	in_file_mask					IN	VARCHAR2,
	in_file_type					IN	VARCHAR2,
	in_source_email					IN	VARCHAR2,
	in_process_body					IN	NUMBER,
	out_class_sid					OUT NUMBER
)
AS
	v_automated_import_class_sid	security.security_pkg.T_SID_ID := in_automated_import_class_sid;
	v_ftp_profile_id				auto_imp_fileread_ftp.ftp_profile_id%TYPE;
	v_ftp_settings_id				automated_import_class_step.auto_imp_fileread_ftp_id%TYPE;
	v_raw_data_source_id			meter_raw_data_source.raw_data_source_id%TYPE;
	v_file_type_id					automated_import_file_type.automated_import_file_type_id%TYPE;
	v_root_mailbox_sid				security_pkg.T_SID_ID;
	v_inbox_sid						security_pkg.T_SID_ID;
	v_parent						security.security_pkg.T_SID_ID;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied configuring importers, only BuiltinAdministrator or super admins can create email and ftp settings.');
	END IF;

	-- create class
	IF v_automated_import_class_sid IS NULL THEN
		BEGIN
			SELECT automated_import_class_sid
			  INTO v_automated_import_class_sid
			  FROM automated_import_class
			 WHERE lookup_key = 'METER_DATA_SOURCE_' || in_data_source_id;
		EXCEPTION
			WHEN no_data_found THEN
				v_parent := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
				automated_import_pkg.CreateClass(
					in_parent						=> v_parent,
					in_label						=> 'Meter data source ' || in_data_source_id,
					in_lookup_key					=> 'METER_DATA_SOURCE_' || in_data_source_id,
					in_schedule_xml					=> XMLType('<recurrences><daily/></recurrences>'),
					in_abort_on_error				=> 0,
					in_email_on_error				=> 'support@credit360.com',
					in_email_on_partial				=> NULL,
					in_email_on_success				=> NULL,
					in_on_completion_sp				=> NULL,
					in_import_plugin				=> NULL,
					in_process_all_pending_files	=> 1,
					out_class_sid					=> v_automated_import_class_sid
				);
		END;
	END IF;
	
	--
	-- filereader_plugin_id // FTP reader = 1, manual reader (email) = 3
	
	-- FTP settings
	IF in_ftp_path IS NOT NULL THEN

		-- create FTP profile if required
		BEGIN
			v_ftp_profile_id := automated_export_import_pkg.CreateCr360FTPProfile;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				SELECT ftp_profile_id
				  INTO v_ftp_profile_id
				  FROM ftp_profile
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND LOWER(label) = 'cr360 sftp';
		END;
		
		-- create FTP settings
		BEGIN
			SELECT auto_imp_fileread_ftp_id
			  INTO v_ftp_settings_id
			  FROM auto_imp_fileread_ftp
			 WHERE ftp_profile_id = v_ftp_profile_id
			   AND payload_path = '/' || in_ftp_path || '/'
			   AND file_mask = in_file_mask;
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				RAISE_APPLICATION_ERROR(-20001, 'Multiple auto_imp_fileread_ftp records for path /'||in_ftp_path||'/ and mask '||in_file_mask);
			WHEN no_data_found THEN
				v_ftp_settings_id := automated_import_pkg.MakeFTPReaderSettings(
					in_ftp_profile_id				=> v_ftp_profile_id,
					in_payload_path					=> '/' || in_ftp_path || '/',
					in_file_mask					=> in_file_mask,
					in_sort_by						=> 'DATE',
					in_sort_by_direction			=> 'ASC',
					in_move_to_path_on_success		=> '/' || in_ftp_path || '/processed/',
					in_move_to_path_on_error		=> '/' || in_ftp_path || '/error/',
					in_delete_on_success			=> 0,
					in_delete_on_error				=> 0
				);
		END;
		
		-- create step
		BEGIN
			automated_import_pkg.AddFtpClassStep(
				in_import_class_sid				=> v_automated_import_class_sid,
				in_step_number					=> 1,
				in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
				in_days_to_retain_payload		=> 30,
				in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
				in_ftp_settings_id				=> v_ftp_settings_id,
				in_importer_plugin_id			=> automated_import_pkg.IMPORT_PLUGIN_TYPE_METER_RD
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				automated_import_pkg.UpdateImportClassStep(
					in_automated_import_class_sid		=> v_automated_import_class_sid,
					in_step_number						=> 1,
					in_on_completion_sp					=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
					in_days_to_retain_payload			=> 30,
					in_plugin							=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
					in_fileread_plugin_id				=> 1, /* FTP Reader */
					in_fileread_ftp_id					=> v_ftp_settings_id
				);
		END;
	END IF;

	-- email settings
	automated_import_pkg.ClearMailboxClassAssociation(v_automated_import_class_sid);
	IF in_source_email IS NOT NULL THEN
		-- create manual instance reader step only if no FTP step is created above
		IF in_ftp_path IS NULL THEN
			BEGIN
				automated_import_pkg.AddClassStep(
					in_import_class_sid				=> v_automated_import_class_sid,
					in_step_number					=> 1,
					in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
					in_days_to_retain_payload		=> 30,
					in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
					in_importer_plugin_id			=> automated_import_pkg.IMPORT_PLUGIN_TYPE_METER_RD,
					in_fileread_plugin_id			=> 3 /* Manual Instance Reader */
				);
			EXCEPTION
				WHEN dup_val_on_index THEN
					automated_import_pkg.UpdateImportClassStep(
						in_automated_import_class_sid		=> v_automated_import_class_sid,
						in_step_number						=> 1,
						in_on_completion_sp					=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
						in_days_to_retain_payload			=> 30,
						in_plugin							=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
						in_fileread_plugin_id				=> 3,	-- Manual Instance Reader
						in_fileread_ftp_id					=> -1	-- Null out-up the fileread_ftp_id (yuck)
					);
			END;
		END IF;

		-- Set/create the inbox sid from the email address
		automated_import_pkg.SetMailbox(
			in_email_address				=> in_source_email,
			in_body_plugin					=> CASE in_process_body WHEN 0 THEN NULL ELSE 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin' END,
			in_use_full_logging				=> 1,
			in_matched_class_sid_for_body	=> v_automated_import_class_sid,
			in_user_sid						=> security_pkg.GetSID,
			out_sid							=> v_root_mailbox_sid
		);

		-- Always add an attachment filter
		automated_import_pkg.SetAttachmentFilter(
			in_mailbox_sid					=> v_root_mailbox_sid,
			in_pos							=> 0,
			in_filter_string				=> '*',
			in_is_wildcard					=> 1,
			in_matched_import_class_sid		=> v_automated_import_class_sid,
			in_required_mimetype			=> NULL,
			in_attachment_validator_plugin	=> 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin'
		);
	END IF;
	
	SELECT automated_import_file_type_id
	  INTO v_file_type_id
	  FROM automated_import_file_type
	 WHERE LOWER(label) = LOWER(in_file_type);
	
	automated_import_pkg.SetGenericImporterSettings(
		in_import_class_sid			=> v_automated_import_class_sid,
		in_step_number				=> 1,
		in_mapping_xml				=> XMLTYPE(in_mapping_xml), 
		in_imp_file_type_id			=> v_file_type_id,
		in_dsv_separator			=> in_delimiter,
		in_dsv_quotes_as_literals	=> 0,
		in_excel_worksheet_index	=> 0,
		in_excel_row_index			=> 0,
		in_all_or_nothing			=> 0);
	
	UPDATE meter_raw_data_source
	   SET automated_import_class_sid = v_automated_import_class_sid
	 WHERE raw_data_source_id = in_data_source_id;
	 
	 out_class_sid := v_automated_import_class_sid;
END;

PROCEDURE AddRecomputeBucketsJob(
	in_raw_data_source_id			IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	-- Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_METER_RECOMPUTE_BUCKETS,
		out_batch_job_id => out_job_id
	);
	
	-- Fill in the job regions
	FOR r IN (
		SELECT DISTINCT out_job_id, region_sid
		  FROM meter_source_data sd
		  JOIN meter_raw_data rd ON rd.app_sid = sd.app_sid AND rd.meter_raw_data_id = sd.meter_raw_data_id
		 WHERE sd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rd.raw_data_source_id = in_raw_data_source_id
	) LOOP
		BEGIN
			INSERT INTO meter_recompute_batch_job (batch_job_id, region_sid)
			VALUES(out_job_id, r.region_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore
		END;
	END LOOP;
END;

PROCEDURE ProcessRecomputeBucketsJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
)
AS
	v_count							NUMBER;
	v_i								NUMBER := 0;
	v_min_dtm						DATE;
	v_max_dtm						DATE;
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
		
		-- Get min/max dates
		SELECT MIN(CAST (start_dtm AS DATE)), MAX(CAST (end_dtm AS DATE))
		  INTO v_min_dtm, v_max_dtm
		  FROM meter_source_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = r.region_sid;

		-- Recompute buckets and export system values
		ComputePeriodicData(r.region_sid, v_min_dtm, v_max_dtm, NULL);
		v_i := v_i + 1;
	END LOOP;

	-- Clean up
	DELETE FROM meter_recompute_batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND batch_job_id = in_batch_job_id;

	-- Export any system values for all regions logged during the above process (in ComputePeriodicData)
	BatchExportSystemValues;

	-- Complete
	batch_job_pkg.SetProgress(in_batch_job_id, v_count, v_count);
	out_result_desc := 'Meter buckets recomputed successfully';
	out_result_url := NULL;
END;


END meter_monitor_pkg;
/
