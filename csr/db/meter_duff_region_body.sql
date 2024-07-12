CREATE OR REPLACE PACKAGE BODY CSR.meter_duff_region_pkg IS

PROCEDURE SaveMarkedDuffRegions
AS
BEGIN
	FOR r IN (
		SELECT urjanet_meter_id, meter_name, meter_number, region_ref, service_type,
			meter_raw_data_id, meter_raw_data_error_id,
			region_sid, issue_id, message, error_type_id
		  FROM temp_duff_meter_region
	) LOOP
		BEGIN
			INSERT INTO duff_meter_region (urjanet_meter_id, meter_name, meter_number, region_ref, service_type,
				meter_raw_data_id, meter_raw_data_error_id,
				region_sid, issue_id, message, error_type_id)
			VALUES (r.urjanet_meter_id, r.meter_name, r.meter_number, r.region_ref, r.service_type, 
				r.meter_raw_data_id, r.meter_raw_data_error_id,
				r.region_sid, r.issue_id, r.message, r.error_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE duff_meter_region
				   SET meter_name = r.meter_name,
					   meter_number = r.meter_number, 
					   region_ref = r.region_ref, 
					   service_type = r.service_type, 
					   meter_raw_data_id = r.meter_raw_data_id,
					   meter_raw_data_error_id = r.meter_raw_data_error_id,
					   region_sid = r.region_sid,
					   issue_id = r.issue_id,
					   message = r.message,
					   error_type_id = r.error_type_id,
					   updated_dtm = SYSDATE
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND urjanet_meter_id = r.urjanet_meter_id
				   -- Avoid unnecessary updates (in case the job is run frequently)
				   AND (
					   meter_name != r.meter_name
				    OR meter_number != r.meter_number
				    OR region_ref != r.region_ref
				    OR service_type != r.service_type
				    OR meter_raw_data_id != r.meter_raw_data_id
				    OR meter_raw_data_error_id != r.meter_raw_data_error_id
				    OR region_sid != r.region_sid
				    OR issue_id != r.issue_id
				    OR message != r.message
				    OR error_type_id != r.error_type_id
				 );
		END;
	END LOOP;
END;

PROCEDURE MarkDuffRegion(
	in_urjanet_meter_id 				IN	duff_meter_region.urjanet_meter_id%TYPE,
	in_meter_name 						IN	duff_meter_region.meter_name%TYPE,
	in_meter_number 					IN	duff_meter_region.meter_number%TYPE,
	in_region_ref 						IN	duff_meter_region.region_ref%TYPE,
	in_service_type						IN	duff_meter_region.service_type%TYPE,
	in_meter_raw_data_id				IN	duff_meter_region.meter_raw_data_id%TYPE DEFAULT NULL,
	in_meter_raw_data_error_id 			IN	duff_meter_region.meter_raw_data_error_id%TYPE DEFAULT NULL,
	in_region_sid						IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_issue_id							IN	duff_meter_region.issue_id%TYPE DEFAULT NULL,
	in_message							IN	duff_meter_region.message%TYPE DEFAULT NULL,
	in_error_type_id					IN	duff_meter_error_type.error_type_id%TYPE
)
AS
BEGIN

	BEGIN
		INSERT INTO temp_duff_meter_region (urjanet_meter_id, meter_name, meter_number, region_ref, service_type, 
			meter_raw_data_id, meter_raw_data_error_id,
			region_sid, issue_id, message, error_type_id)
		VALUES (in_urjanet_meter_id, in_meter_name, in_meter_number, in_region_ref, in_service_type, 
			in_meter_raw_data_id, in_meter_raw_data_error_id,
			in_region_sid, in_issue_id, in_message, in_error_type_id);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE temp_duff_meter_region
			   SET meter_name = in_meter_name,
				   meter_number = in_meter_number, 
				   region_ref = in_region_ref, 
				   service_type = in_service_type,
				   meter_raw_data_id = in_meter_raw_data_id,
				   meter_raw_data_error_id = in_meter_raw_data_error_id,
				   region_sid = in_region_sid,
				   issue_id = in_issue_id,
				   message = in_message,
				   error_type_id = in_error_type_id
			 WHERE urjanet_meter_id = in_urjanet_meter_id;


	END;
END;

PROCEDURE ClearDuffRegion(
	in_urjanet_meter_id 				IN	duff_meter_region.urjanet_meter_id%TYPE
)
AS
	v_log_cur							SYS_REFCURSOR;
	v_action_cur						SYS_REFCURSOR;
BEGIN
	-- Mark any outstanding issues (actions) as closed
	FOR r IN (
		SELECT DISTINCT issue_id
		  FROM duff_meter_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND urjanet_meter_id = in_urjanet_meter_id
		   AND issue_id IS NOT NULL
	) LOOP
		issue_pkg.MarkAsClosed(
			security_pkg.GetACT,
			r.issue_id,
			'Issue has been resolved automatically by the metering system',
			null, null,
			v_log_cur,
			v_action_cur
		);
	END LOOP;

	-- Remove any associated raw data errors
	DELETE FROM meter_raw_data_error
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND error_id IN (
	 	SELECT meter_raw_data_error_id
	 	  FROM duff_meter_region
	 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND urjanet_meter_id = in_urjanet_meter_id
	 );

	-- Remove the duff region
	DELETE FROM duff_meter_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND urjanet_meter_id = in_urjanet_meter_id;
END;


PROCEDURE LogErrorAndMarkDuffRegion(
	in_urjanet_meter_id 				IN	duff_meter_region.urjanet_meter_id%TYPE,
	in_meter_name 						IN	duff_meter_region.meter_name%TYPE,
	in_meter_number 					IN	duff_meter_region.meter_number%TYPE,
	in_region_ref 						IN	duff_meter_region.region_ref%TYPE,
	in_service_type						IN	duff_meter_region.service_type%TYPE,
	in_meter_raw_data_id		 		IN	duff_meter_region.meter_raw_data_id%TYPE,
	in_region_sid						IN	security_pkg.T_SID_ID,
	in_message							IN	VARCHAR2,
	in_detail							IN	VARCHAR2,
	in_error_type_id					IN	duff_meter_error_type.error_type_id%TYPE
)
AS
	v_meter_raw_data_id					meter_raw_data.meter_raw_data_id%TYPE;
	v_error_id							meter_raw_data_error.error_id%TYPE;
	v_issue_id							issue.issue_id%TYPE;
BEGIN
	meter_monitor_pkg.AddUniqueRawDataIssue (
		in_raw_data_id			=> in_meter_raw_data_id,
		in_region_sid			=> in_region_sid,
		in_label				=> in_message,
		in_description			=> in_detail,
		out_issue_id			=> v_issue_id
	);
	MarkDuffRegion(
		in_urjanet_meter_id 			=> in_urjanet_meter_id,
		in_meter_name 					=> in_meter_name,
		in_meter_number 				=> in_meter_number,
		in_region_ref 					=> in_region_ref,
		in_service_type					=> in_service_type,
		in_meter_raw_data_id 			=> in_meter_raw_data_id,
		in_region_sid					=> in_region_sid,
		in_issue_id						=> v_issue_id,
		in_message						=> in_message,
		in_error_type_id				=> in_error_type_id
	);
END;

PROCEDURE RetryDuffRegions(
	in_wait_for_locks					IN	NUMBER,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_exists							NUMBER;
	v_lock_id							NUMBER;
	v_lock_result 						INTEGER;
	v_lock_timeout						INTEGER := CASE WHEN in_wait_for_locks = 0 THEN 0 ELSE dbms_lock.maxwait END;
BEGIN
	FOR r IN (
		SELECT urjanet_meter_id, meter_name, meter_number, region_ref, service_type, meter_raw_data_id, region_sid
		  FROM duff_meter_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		-- Try to take out a lock for this app_sid/urjanet_meter_id
		-- XXX: AVOID USING ALLOCATE_UNQUE AS IT COMMITS!
		SELECT ORA_HASH('DUFF_REGION_LOCK_'||SYS_CONTEXT('SECURITY', 'APP')||'_'||r.urjanet_meter_id, 1073741823)
		  INTO v_lock_id
		  FROM DUAL;

		v_lock_result := dbms_lock.request(
			id					=> v_lock_id,
			lockmode 			=> dbms_lock.x_mode, 
			timeout 			=> v_lock_timeout, 
			release_on_commit	=> TRUE
		);



		-- Only run if we got a lock
		IF v_lock_result = 0 /*success*/ THEN
			-- Just run the standard create/find procedure
			-- We don't need to call SaveMarkedDuffRegions at 
			-- the end as we're processing the duff region list
			meter_pkg.CreateOrFindMeter(
				in_raw_data_id		=> r.meter_raw_data_id,
				in_name				=> r.meter_name,
				in_region_ref		=> r.region_ref,
				in_urjanet_meter_id	=> r.urjanet_meter_id,
				in_service_type		=> r.service_type,
				in_meter_number		=> r.meter_number,
				out_exists			=> v_exists
			);

			If v_exists != 0 THEN
				-- Keep track of regions that were fixed (now able to be found/created)
				BEGIN
					INSERT INTO temp_fixed_duff_meter_region (urjanet_meter_id)
					VALUES (r.urjanet_meter_id);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL; -- ignore dupes
				END;

				-- Clean up the duff region
				ClearDuffRegion(r.urjanet_meter_id);
			END IF;

		END IF;

		-- Release the lock
		v_lock_result := dbms_lock.release(
			id => v_lock_id
		);
		
	END LOOP;

	-- Return list of serial ids (urjanet_meter_id) for all matched meter regions
	OPEN out_cur FOR
		SELECT urjanet_meter_id serial_id
		  FROM temp_fixed_duff_meter_region;
END;

PROCEDURE GetDuffMeterRegionList(
	in_text					IN	VARCHAR2,
	in_start_row			IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(4000);
	v_order_by		VARCHAR2(32);
BEGIN

	-- TODO: Can we do some sort of security check?

	v_order_by := 'created_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		utils_pkg.ValidateOrderBy(v_order_by, 'source_type,source_label,message,created_dtm,updated_dtm,serial_id,start_dtm,end_dtm,meter_input_label,consumption,has_overlap,error_type_label');
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
		SELECT * FROM (
			SELECT ROWNUM rn, x.*
			  FROM (
				SELECT COUNT(*) OVER () total_count, x.*, mi.label meter_input_label, mdp.label priority_label, r.description region_desc, et.label error_type_label
				  FROM (
					SELECT
						'Automated import' source_type,
						ods.label source_label,
						NULL automated_import_instance_id,
						dr.message,
						dr.urjanet_meter_id serial_id,
						ods.meter_input_id,
						ods.priority,
						dr.created_dtm,
						dr.updated_dtm,
						dr.meter_raw_data_id,
						dr.meter_raw_data_error_id,
						dr.error_type_id,
						ods.start_dtm,
						ods.end_dtm,
						ods.consumption,
						NVL(ods.has_overlap, 0) has_overlap,
						ods.region_sid
					  FROM duff_meter_region dr
					  LEFT JOIN v$meter_orphan_data_summary ods ON ods.app_sid = dr.app_sid AND ods.serial_id = dr.urjanet_meter_id
					 WHERE dr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					UNION
					SELECT
						'Automated import' source_type,
						ods.label source_label,
						NULL automated_import_instance_id,
						DECODE(ods.has_overlap, 0, 'Orphan meter data', 'Incoming data overlaps existing meter data') message,
						ods.serial_id,
						ods.meter_input_id,
						ods.priority,
						ods.created_dtm,
						ods.updated_dtm,
						NULL meter_raw_data_id,
						NULL meter_raw_data_error_id,
						ods.error_type_id,
						ods.start_dtm,
						ods.end_dtm,
						ods.consumption,
						NVL(ods.has_overlap, 0) has_overlap,
						ods.region_sid
					  FROM v$meter_orphan_data_summary ods
					 WHERE ods.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND NOT EXISTS (
							SELECT 1
							  FROM duff_meter_region dr
							 WHERE dr.urjanet_meter_id = ods.serial_id
					   )
				) x
				 LEFT JOIN meter_input mi ON mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mi.meter_input_id = x.meter_input_id
				 LEFT JOIN meter_data_priority mdp ON mdp.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mdp.priority = x.priority
				 LEFT JOIN v$region r ON r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = x.region_sid
				 JOIN duff_meter_error_type et ON et.error_type_id = x.error_type_id
				WHERE ( -- Filter
					   REGEXP_LIKE(x.source_type, v_search, 'i')
					OR REGEXP_LIKE(x.source_label, v_search, 'i')
					OR REGEXP_LIKE(x.automated_import_instance_id, v_search, 'i')
					OR REGEXP_LIKE(x.message, v_search, 'i')
					OR REGEXP_LIKE(x.serial_id, v_search, 'i')
					OR REGEXP_LIKE(r.description, v_search, 'i')
					OR REGEXP_LIKE(mi.label, v_search, 'i')
					OR REGEXP_LIKE(et.label, v_search, 'i')
				)
				ORDER BY	
					-- Ascending
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'SERIAL_ID' THEN LOWER(serial_id) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'SOURCE_TYPE' THEN LOWER(source_type) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'SOURCE_LABEL' THEN LOWER(source_label) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'MESSAGE' THEN LOWER(message) || LOWER(r.description) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'CREATED_DTM' THEN created_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'UPDATED_DTM' THEN updated_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'START_DTM' THEN start_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'END_DTM' THEN end_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'CONSUMPTION' THEN consumption ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ERROR_TYPE_LABEL' THEN et.label ELSE NULL END ASC,
					-- Descending
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'SERIAL_ID' THEN LOWER(serial_id) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'SOURCE_TYPE' THEN LOWER(source_type) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'SOURCE_LABEL' THEN LOWER(source_label) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'MESSAGE' THEN LOWER(message) || LOWER(r.description) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'CREATED_DTM' THEN created_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'UPDATED_DTM' THEN updated_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'START_DTM' THEN start_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'END_DTM' THEN end_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'CONSUMPTION' THEN consumption ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ERROR_TYPE_LABEL' THEN et.label ELSE NULL END DESC,
					-- Keep the meter inputs consistent (unless ordering by them specifically)
					CASE WHEN UPPER(v_order_by) != 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END ASC -- ASC inentional
			) x
		)
		 WHERE rn >= in_start_row
		   AND ROWNUM <= in_row_limit
		;
END;

PROCEDURE GetOverlapsWithLiveData(
	in_serial_id			meter_orphan_data.serial_id%TYPE,
	in_start_row			IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_order_by				VARCHAR2(32);
BEGIN
	v_order_by := 'orphan_start_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter_input_label,orphan_start_dtm,orphan_end_dtm,orphan_consumption,live_start_dtm,live_end_dtm,live_consumption');
	END IF;

	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT ROWNUM rn, COUNT(*) OVER () total_count, x.*
			  FROM (
				SELECT DISTINCT
					l.serial_id, l.meter_input_id, l.priority, mi.label meter_input_label,
					CAST(l.start_dtm AS DATE) orphan_start_dtm, CAST(l.end_dtm AS DATE) orphan_end_dtm, l.consumption orphan_consumption, 
					r.start_dtm live_start_dtm, r.end_dtm live_end_dtm, r.consumption live_consumption
				  FROM csr.meter_orphan_data l
				  JOIN csr.all_meter m ON NVL(m.urjanet_meter_id, m.reference) = l.serial_id
				  JOIN csr.meter_source_data r ON r.region_sid = m.region_sid
				  JOIN meter_input mi ON mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mi.meter_input_id = l.meter_input_id
				 WHERE l.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND l.serial_id = in_serial_id
				   AND l.meter_input_id = r.meter_input_id
				   AND l.priority = r.priority
				   AND NOT (CAST(l.start_dtm AS DATE) = r.start_dtm AND CAST(l.end_dtm AS DATE) = r.end_dtm)
				   AND l.start_dtm < r.end_dtm
				   AND l.end_dtm > r.start_dtm
				 ORDER BY	
					-- Ascending
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN orphan_start_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ORPHAN_START_DTM' THEN orphan_start_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ORPHAN_END_DTM' THEN orphan_end_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ORPHAN_CONSUMPTION' THEN l.consumption ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'LIVE_START_DTM' THEN r.start_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'LIVE_END_DTM' THEN r.end_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'LIVE_CONSUMPTION' THEN r.consumption ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' THEN LOWER(mi.label) ELSE NULL END ASC,
					-- Descending
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN orphan_start_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ORPHAN_START_DTM' THEN orphan_start_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ORPHAN_END_DTM' THEN orphan_end_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ORPHAN_CONSUMPTION' THEN l.consumption ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'LIVE_START_DTM' THEN r.start_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'LIVE_END_DTM' THEN r.end_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'LIVE_CONSUMPTION' THEN r.consumption ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' THEN LOWER(mi.label) ELSE NULL END DESC
			) x
		)
		 WHERE rn >= in_start_row
		   AND ROWNUM <= in_row_limit
		;
END;

PROCEDURE GetOverlapsWithSelf(
	in_serial_id			meter_orphan_data.serial_id%TYPE,
	in_start_row			IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_order_by				VARCHAR2(32);
BEGIN
	v_order_by := 'orphan_start_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter_input_label,orphan_start_dtm,orphan_end_dtm,orphan_consumption');
	END IF;

	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT ROWNUM rn, COUNT(*) OVER () total_count, x.*
			  FROM (
				SELECT DISTINCT
					l.serial_id, l.meter_input_id, l.priority, mi.label meter_input_label, 
					CAST(l.start_dtm AS DATE) orphan_start_dtm, CAST(l.end_dtm AS DATE) orphan_end_dtm, l.consumption orphan_consumption
				  FROM csr.meter_orphan_data l
				  JOIN meter_input mi ON mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mi.meter_input_id = l.meter_input_id
				 CROSS JOIN csr.meter_orphan_data r
				 WHERE l.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND l.serial_id = in_serial_id
				   AND l.serial_id = r.serial_id
				   AND l.meter_input_id = r.meter_input_id
				   AND l.priority = r.priority
				   AND NOT (l.start_dtm = r.start_dtm AND l.end_dtm = r.end_dtm)
				   AND l.start_dtm < r.end_dtm
				   AND l.end_dtm > r.start_dtm 
				 ORDER BY	
					-- Ascending
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN orphan_start_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ORPHAN_START_DTM' THEN orphan_start_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ORPHAN_END_DTM' THEN orphan_end_dtm ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' AND UPPER(v_order_by) = 'ORPHAN_CONSUMPTION' THEN l.consumption ELSE NULL END ASC,
					CASE WHEN UPPER(in_sort_dir) = 'ASC' THEN LOWER(mi.label) ELSE NULL END ASC, 
					-- Descending
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN LOWER(mi.label) ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'METER_INPUT_LABEL' THEN orphan_start_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ORPHAN_START_DTM' THEN orphan_start_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ORPHAN_END_DTM' THEN orphan_end_dtm ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' AND UPPER(v_order_by) = 'ORPHAN_CONSUMPTION' THEN l.consumption ELSE NULL END DESC,
					CASE WHEN UPPER(in_sort_dir) = 'DESC' THEN LOWER(mi.label) ELSE NULL END DESC
			) x
		)
		 WHERE rn >= in_start_row
		   AND ROWNUM <= in_row_limit
		;
END;

PROCEDURE DeleteOrphanData(
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	in_meter_input_id		IN	meter_orphan_data.meter_input_id%TYPE,
	in_priority				IN	meter_orphan_data.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
)
AS
	v_nvl_date				DATE := TO_DATE('0001-01-01',  'YYYY-MM-DD');
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	DELETE FROM meter_orphan_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_input_id = in_meter_input_id
	   AND priority = in_priority
	   AND CAST(start_dtm AS DATE) = in_start_dtm
	   AND NVL(CAST(end_dtm AS DATE), v_nvl_date) = NVL(in_end_dtm, v_nvl_date);
END;

PROCEDURE DeleteDuffRegionsAndOrphanData(
	in_meter_raw_data_id	IN	meter_raw_data.meter_raw_data_id%TYPE
)
AS
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	DELETE FROM duff_meter_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id;

	DELETE FROM meter_orphan_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id;
END;

END meter_duff_region_pkg;
/
