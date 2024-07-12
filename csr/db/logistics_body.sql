CREATE OR REPLACE PACKAGE BODY CSR.Logistics_Pkg AS

PROCEDURE GetHttpRequest(
	in_url		IN	http_request_cache.url%TYPE,
	in_hash		IN	http_request_cache.request_hash%TYPE,
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	UPDATE http_request_cache
	   SET last_used_dtm = SYSDATE
	 WHERE url = in_url
	   AND request_hash = in_hash;	

	OPEN out_cur FOR
		SELECT response, fetched_dtm, last_used_dtm, mime_type
		  FROM http_request_cache
		 WHERE url = in_url
		   AND request_hash = in_hash;		   
END;

PROCEDURE SetHttpRequest(
	in_url			IN	http_request_cache.url%TYPE,
	in_hash			IN	http_request_cache.request_hash%TYPE,
	in_response		IN	http_request_cache.response%TYPE,
	in_mime_type	IN	http_request_cache.mime_type%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO http_request_cache (url, request_hash, response, mime_type)
			VALUES (in_url, in_hash, in_response, in_mime_type);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE http_request_cache
			   SET fetched_dtm = SYSDATE, last_used_dtm = SYSDATE, mime_type = in_mime_type
			 WHERE url = in_url
			   AND request_hash = in_hash;		   
	END;
END;

PROCEDURE GetTables(
	in_permission_set	IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_WRITE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT ltm.tab_sid, NVL(t.description, t.oracle_table) description, t.oracle_schema, t.oracle_table
		  FROM logistics_tab_mode ltm
			JOIN cms.tab t ON ltm.tab_sid = t.tab_sid
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), ltm.tab_sid, in_permission_set) = 1
		 ORDER BY description;
END;

PROCEDURE RegisterTable(
	in_oracle_schema		IN	VARCHAR2,
	in_oracle_table			IN	VARCHAR2,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE,
	in_start_job_sp			IN  logistics_tab_mode.start_job_sp%TYPE,
	in_get_rows_sp			IN	logistics_tab_mode.get_rows_sp%TYPE 		DEFAULT NULL,
	in_set_distance_sp		IN  logistics_tab_mode.set_distance_sp%TYPE		DEFAULT NULL,
	in_delete_row_sp		IN  logistics_tab_mode.delete_row_sp%TYPE,
	in_get_aggregates_sp	IN	logistics_tab_mode.get_aggregates_sp%TYPE,
	in_location_changed_sp	IN	logistics_tab_mode.location_changed_sp%TYPE	DEFAULT NULL,
	in_processor_class		IN	logistics_processor_class.label%TYPE
)
AS
	v_tab_sid			security_pkg.T_SID_ID;
	v_proc_class_id		logistics_processor_class.processor_class_id%TYPE;
BEGIN
	-- XXX: doesn't throw any exceptions so hope for the best...
	v_tab_sid := cms.tab_pkg.GetTableSid(in_oracle_schema, in_oracle_table);
	
	SELECT processor_class_id
	  INTO v_proc_class_id
	  FROM logistics_processor_class
	 WHERE label = in_processor_class;

	BEGIN
		INSERT INTO logistics_tab_mode
			(app_sid, tab_sid, transport_mode_id, start_job_sp, set_distance_sp, 
				get_rows_sp, delete_row_sp, get_aggregates_sp, location_changed_sp, processor_class_id)
			VALUES
			(security_pkg.getApp, v_tab_sid, in_transport_mode_id, in_start_job_sp, in_set_distance_sp, 
				in_get_rows_sp, in_delete_row_sp, in_get_aggregates_sp, in_location_changed_sp, v_proc_class_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE logistics_tab_mode 
			   SET get_rows_sp = in_get_rows_sp,
					set_distance_sp = in_set_distance_sp,
					delete_row_sp = in_delete_row_sp,
					get_aggregates_sp = in_get_aggregates_sp,
					location_changed_sp = in_location_changed_sp,
					transport_mode_id = in_transport_mode_id,
					is_dirty = 1
			 WHERE tab_sid = v_tab_sid
			   AND processor_class_id = v_proc_class_id
			   AND start_job_sp = in_start_job_sp;
	END;
END;

-- TODO: this should take a SID but means messing with the import code which I can't do right now!
PROCEDURE MarkTableAsDirty(
	in_table_name		IN	VARCHAR2
)
AS
BEGIN
	-- timing issue?
	UPDATE logistics_tab_mode 
	   SET is_dirty = 1
	 WHERE tab_sid IN (
		SELECT tab_sid
		  FROM cms.tab
		 WHERE UPPER(oracle_table) = UPPER(in_table_name)
	 );
END;

PROCEDURE MarkTableAsDirty(
	in_schema_name		IN	VARCHAR2,
	in_table_name		IN	VARCHAR2
)
AS
BEGIN
	-- timing issue?
	UPDATE logistics_tab_mode 
	   SET is_dirty = 1
	 WHERE tab_sid IN (
		SELECT tab_sid
		  FROM cms.tab
		 WHERE UPPER(oracle_schema) = UPPER(in_schema_name)
		   AND UPPER(oracle_table) = UPPER(in_table_name)
	 );
END;

PROCEDURE ClearTabModesProcessing
AS
BEGIN
	-- clear up (and mark as dirty again) in case we died mid-way through last time
	UPDATE logistics_tab_mode 
	   SET processing = 0, is_dirty = 1
	 WHERE processing = 1;
END;

PROCEDURE MarkTabModeProcessed(
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_processor_class		IN	logistics_processor_class.label%TYPE
)
AS
	v_proc_class_id			logistics_processor_class.processor_class_id%TYPE;
BEGIN
	SELECT processor_class_id
	  INTO v_proc_class_id
	  FROM logistics_processor_class
	 WHERE label = in_processor_class;
	
	UPDATE logistics_tab_mode
	   SET processing = 0
	 WHERE processing = 1
	   AND app_sid = in_app_sid
	   AND tab_sid = in_tab_sid
	   AND processor_class_id = v_proc_class_id;
END;

PROCEDURE MarkTabModeFailed(
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_processor_class		IN	logistics_processor_class.label%TYPE
)
AS
	v_proc_class_id			logistics_processor_class.processor_class_id%TYPE;
BEGIN
	SELECT processor_class_id
	  INTO v_proc_class_id
	  FROM logistics_processor_class
	 WHERE label = in_processor_class;
	
	-- need to requeue this to go again
	UPDATE logistics_tab_mode
	   SET processing = 0, is_dirty = 1
	 WHERE processing = 1
	   AND app_sid = in_app_sid
	   AND tab_sid = in_tab_sid
	   AND processor_class_id = v_proc_class_id;
END;

PROCEDURE GetTabModesToProcess(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ltm.app_sid, ltm.tab_sid, c.host, ltm.transport_mode_id, lm.label transport_mode_label, t.oracle_schema, t.oracle_table,
			ltm.set_distance_sp, ltm.get_rows_sp, ltm.start_job_sp, ltm.get_aggregates_sp, lpc.label processor_class
		  FROM logistics_tab_mode ltm
		    JOIN logistics_processor_class lpc ON ltm.processor_class_id = lpc.processor_class_id
			JOIN transport_mode lm ON ltm.transport_mode_id = lm.transport_mode_id
			JOIN cms.tab t ON ltm.tab_sid = t.tab_sid AND ltm.app_sid = t.app_sid 
			JOIN customer c ON ltm.app_sid = c.app_sid
		 WHERE ltm.is_dirty = 1 AND ltm.processing = 0;	

	-- timing issue?
	UPDATE logistics_tab_mode 
	   SET is_dirty = 0, processing = 1
	 WHERE is_dirty = 1
	   AND processing = 0;
END;

PROCEDURE CreateImpSession(
	in_tab_sid			IN	security_pkg.T_SID_ID,
	in_processor_class		IN	logistics_processor_class.label%TYPE
)
AS
	-- returned by the cursor
	v_session_name		VARCHAR2(1024);
	v_ind				VARCHAR2(1024);
	v_region			VARCHAR2(1024);
	v_start_dtm			DATE;
	v_end_dtm			DATE;
	v_val_number		NUMBER;
	-- other bits we need
	v_parent_sid		security_pkg.T_SID_ID; -- parent for imp session
	v_sp				logistics_tab_mode.get_aggregates_sp%TYPE;
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_imp_session_sid	security_pkg.T_SID_ID;
	v_dummy_file_sid	security_pkg.T_SID_ID;
	v_imp_val_id		imp_val.imp_val_id%TYPE;
	v_proc_class_id		logistics_processor_class.processor_class_id%TYPE;
BEGIN
	SELECT processor_class_id
	  INTO v_proc_class_id
	  FROM logistics_processor_class
	 WHERE label = in_processor_class;
	
	SELECT get_aggregates_sp
	  INTO v_sp
	  FROM logistics_tab_mode
	 WHERE tab_sid = in_tab_sid
	   AND processor_class_id = v_proc_class_id;
	
	IF v_sp IS NULL THEN -- no aggregate procedure
		RETURN;
	END IF;

	EXECUTE IMMEDIATE 'begin '||v_sp||'(:1, :2); end;'
		USING OUT v_session_name, OUT v_cur;
		
	WHILE TRUE
	LOOP
		FETCH v_cur INTO v_ind, v_region, v_start_dtm, v_end_dtm, v_val_number;
		EXIT WHEN v_cur%NOTFOUND;
		
		IF v_imp_session_sid IS NULL THEN
			-- create a session and dummy file
			v_parent_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Imports');
			BEGIN
				-- TODO: -- / char in v_session_name would be bad news -- don't worry for now.
				Imp_Pkg.CreateImpSession(security_pkg.getACT,  v_parent_sid, security_pkg.getApp,
					v_session_name, 'Logistics', v_imp_session_sid);
				fileupload_pkg.createFileUpload(security_pkg.getACT, 'Logistics', 'text/plain', v_imp_session_sid, 
					EMPTY_BLOB(), v_dummy_file_sid); --'Logistics');	 -- (new UnicodeEncoding()).GetBytes(file)); // converetd to byte array
			EXCEPTION
				WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
					-- exists already -- reuse existing session
					v_imp_session_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, v_parent_sid, v_session_name);
					-- relies on the fact we just have one file -- we don't do anything with this anyway so no harm done.
					SELECT file_upload_sid
					  INTO v_dummy_file_sid
					  FROM file_upload
					 WHERE parent_sid = v_imp_session_sid;
					-- unmerge existing data data
					imp_pkg.RemoveMergedData(security_pkg.getACT, v_imp_session_sid);
					dbms_output.put_line('deleting data for file '||v_dummy_file_sid);
					imp_pkg.deleteFileData(security_pkg.getACT, v_dummy_file_sid);
			END;
		END IF;
		--dbms_output.put_line('writing '||v_ind||', '||v_region||', '||v_start_dtm||', '||v_val_number);	
		imp_pkg.AddValueUnsecured(v_imp_session_sid, security_pkg.getApp, 
			UPPER(v_ind),  --it doesn't handle mixed case properly
			UPPER(v_region),  -- it doesn't handle mixed case properly
			null, -- measure_description
			null, -- unknown
			v_start_dtm,
			v_end_dtm,
			v_val_number,
			null, -- note
			v_dummy_file_sid,
			v_imp_val_id
		);
	END LOOP;
	
	IF v_imp_session_sid IS NOT NULL THEN
		-- mark imp session as parsed
		UPDATE imp_session
		   SET parse_started_dtm = SYSDATE, parsed_dtm = SYSDATE
		 WHERE imp_session_sid = v_imp_session_sid;

		imp_pkg.insertConflicts(security_pkg.GetACT, v_imp_session_sid);
		-- merge...
		imp_pkg.mergeWithMainData(security_pkg.GetACT, v_imp_session_sid);
	END IF;
END;	





PROCEDURE SortOriginDest(
	in_id1			IN	location.location_id%TYPE,
	in_id2			IN	location.location_id%TYPE,
	out_id1			OUT	location.location_id%TYPE,
	out_id2			OUT	location.location_id%TYPE
)
AS
BEGIN
	-- no security, only run from other procedures
	
	IF in_id1 < in_id2 THEN
		out_id1 := in_id1;
		out_id2 := in_id2;
	ELSE
		out_id1 := in_id2;
		out_id2 := in_id1;
	END IF;
END;

-- no exceptions - returns null if not found
FUNCTION SQL_GetCountryCode(
	in_country			IN	VARCHAR2
) RETURN postcode.country.country%TYPE
AS
	v_country		postcode.country.country%TYPE;
BEGIN
	-- no security, only run from batch	
	IF in_country IS NULL THEN
		RETURN NULL;
	ELSE
		BEGIN
			SELECT country
			  INTO v_country
			  FROM (
				SELECT country, ROW_NUMBER() OVER (ORDER BY priority) p
				  FROM (					
					   SELECT country, 1 priority -- ISO2 country code has prescendence
						 FROM postcode.country
						WHERE LOWER(country) = LOWER(TRIM(in_country))
						UNION
					   SELECT country, 2 priority -- ISO3 country code next
						 FROM postcode.country
						WHERE LOWER(iso3) = LOWER(TRIM(in_country))
						UNION
					   SELECT country, 3 priority -- country name next
						 FROM postcode.country
						WHERE LOWER(name) = LOWER(TRIM(in_country))
						UNION
					   SELECT country, 4 priority -- aliases after that
						 FROM postcode.country_alias
						WHERE LOWER(alias) = LOWER(TRIM(in_country))
				  )
			  ) 
			WHERE p = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN NULL;
		END;
		RETURN v_country;
	END IF;
END;

FUNCTION GetCountryCode(
	in_country			IN	VARCHAR2
) RETURN postcode.country.country%TYPE
AS
	v_country		postcode.country.country%TYPE;
BEGIN
	-- no security, only run from batch	
	IF in_country IS NULL THEN
		RETURN NULL;
	ELSE
		v_country := SQL_GetCountryCode(in_country);
		IF v_country IS NULL THEN
			-- legacy behaviour
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_LOGISTICS_COUNTRY_INVALID, 'Country code not found for '''||in_country||'''');
		END IF; 
		RETURN v_country;
	END IF;
END;

FUNCTION GCD(
	in_origin_country 			IN	VARCHAR2,
	in_destination_country 		IN	VARCHAR2
) RETURN NUMBER
AS
	v_origin_lat		NUMBER;
	v_origin_lng		NUMBER;
	v_destination_lat	NUMBER;
	v_destination_lng	NUMBER;
BEGIN
	BEGIN
		SELECT latitude, longitude
		  INTO v_origin_lat, v_origin_lng
		  FROM postcode.country
		 WHERE country = SQL_GetCountryCode(in_origin_country);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN null;
	END;
	
	BEGIN
		SELECT latitude, longitude
		  INTO v_destination_lat, v_destination_lng
		  FROM postcode.country
		 WHERE country = SQL_GetCountryCode(in_destination_country);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN null;
	END;
	
	RETURN GCD(v_origin_lat, v_origin_lng, v_destination_lat, v_destination_lng);
END;

FUNCTION GCD(
	in_origin_lat 		IN	NUMBER,
	in_origin_lng 		IN	NUMBER,
	in_destination_lat 	IN	NUMBER,
	in_destination_lng 	IN	NUMBER
) RETURN NUMBER
AS
	c_sphere_radius CONSTANT NUMBER := 6372.8; -- 6372.8km (spherical radius of earth)
	a						NUMBER;
	v_d_lat					NUMBER;
	v_d_lng					NUMBER;
	v_origin_lat_rad 		NUMBER;
	v_destination_lat_rad 	NUMBER;
BEGIN
	-- convert to radians from degrees
	v_origin_lat_rad 		:= in_origin_lat / 57.2957795;
	v_destination_lat_rad 	:= in_destination_lat / 57.2957795;
	
	-- haversine formula
	v_d_lat := (in_destination_lat - in_origin_lat)  / 57.2957795;
	v_d_lng := (in_destination_lng - in_origin_lng)  / 57.2957795;

	a := SIN(v_d_lat/2) * SIN(v_d_lat/2) +
			SIN(v_d_lng/2) * SIN(v_d_lng/2) * COS(v_origin_lat_rad) * COS(v_destination_lat_rad); 
	RETURN ROUND(c_sphere_radius * 2 * ATAN2(SQRT(a), SQRT(1-a)), 3);  -- round it off for sanity
EXCEPTION
	WHEN OTHERS THEN
		RETURN NULL;
END;

FUNCTION EstInternalDistance(
	in_country			IN	postcode.country.country%TYPE
) RETURN NUMBER
AS
	v_area		postcode.country.area_in_sqkm%TYPE;
BEGIN
	SELECT area_in_sqkm
	  INTO v_area
	  FROM postcode.country
	 WHERE country = in_country;

	-- average distance between two points in a circle is approximately 90.54% of the radius of the circle.
	-- This is always going to be a bodge as we don't actually know the start and end points, but gives it 
	-- some spurious pseudo-scientific backing which auditors like.
	-- See: http://sites.google.com/site/jerrychiang/twopointsinacircle
	RETURN ROUND(SQRT(v_area / 3.141592653589793) * .9, 3); -- round it off for sanity
END;

PROCEDURE GetLocation(
	in_loc_type_id		IN	location.location_type_id%TYPE,
	in_hash				IN	custom_location.location_hash%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security, only run from batch
	OPEN out_cur FOR
		SELECT cl.name, cl.description, cl.address, cl.city, cl.province, cl.postcode, cl.is_approved, cl.country, cl.location_id,
			c.name country_name, l.longitude, l.latitude
		  FROM custom_location cl
			JOIN location l ON cl.location_id = l.location_Id
			JOIN postcode.country c ON cl.country = c.country
		 WHERE cl.location_hash = in_hash
		   AND cl.location_type_id = in_loc_type_id
		   AND cl.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetCustomLocationByAll(
	in_loc_type_id		IN	custom_location.location_type_id%TYPE,
	in_address			IN	custom_location.address%TYPE,
	in_city				IN	custom_location.city%TYPE,
	in_province			IN	custom_location.province%TYPE,
	in_postcode			IN	custom_location.postcode%TYPE,
	in_country			IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_country			custom_location.country%TYPE;
BEGIN
	-- no security, only run from batch
	
	v_country := GetCountryCode(in_country);
	
	OPEN out_cur FOR
		SELECT l.location_id, cl.address, cl.city, cl.province, cl.postcode, cl.country, cl.is_approved, 
			CASE WHEN longitude IS NULL AND latitude IS NULL THEN 1 ELSE 0 END is_search_fail, 
			l.latitude, l.longitude
		  FROM custom_location cl
			JOIN location l ON cl.location_id = l.location_id
		 WHERE cl.location_type_id = in_loc_type_id
		   AND ((cl.address IS NULL AND in_address IS NULL) OR cl.address = in_address)
		   AND ((cl.city IS NULL AND in_city IS NULL) OR cl.city = in_city)
		   AND ((cl.province IS NULL AND in_province IS NULL) OR cl.province = in_province)
		   AND ((cl.postcode IS NULL AND in_postcode IS NULL) OR cl.postcode = in_postcode)
		   AND ((cl.country IS NULL AND v_country IS NULL) OR cl.country = v_country)
		   AND cl.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION INTERNAL_CreateLocation(
	in_loc_type_id		IN	location.location_type_id%TYPE,
	in_lat				IN	location.latitude%TYPE,
	in_lng				IN	location.longitude%TYPE,
	in_country			IN	location.country%TYPE
) RETURN location.location_id%TYPE
AS
	v_location_id		location.location_id%TYPE;
BEGIN
	-- no security, only run from other procedures in this file
	
	-- TODO: constraint is lat/lng need to be unique, or both null
	
	BEGIN
		INSERT INTO location (location_id, location_type_id, name, latitude, longitude, country, is_approved)
			VALUES (location_id_seq.nextval, in_loc_type_id, TO_CHAR(in_lat) || ',' || TO_CHAR(in_lng), in_lat, in_lng, in_country, 1)
			RETURNING location_id INTO v_location_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT MIN(location_id)
			  INTO v_location_id
			  FROM location
			 WHERE location_type_id = in_loc_type_id
			   AND latitude = in_lat
			   AND longitude = in_lng;	
	END;
	
	RETURN v_location_id;
END;

FUNCTION CreateCustomLocation(
	in_loc_type_id		IN	custom_location.location_type_id%TYPE,
	in_name				IN	custom_location.name%TYPE,
	in_is_approved		IN	custom_location.is_approved%TYPE
) RETURN location.location_id%TYPE
AS
	v_location_id		location.location_id%TYPE;
BEGIN
	v_location_id := INTERNAL_CreateLocation(in_loc_type_id, NULL, NULL, NULL);
	
	BEGIN
		INSERT INTO custom_location (custom_location_id, location_type_id, name, location_hash, location_id, is_approved)
			VALUES (custom_location_id_seq.nextval, in_loc_type_id, in_name, GetCustomLocationHash(in_name), v_location_id, in_is_approved);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			DELETE FROM location
			 WHERE location_id = v_location_id;
			
			SELECT location_id
			  INTO v_location_id
			  FROM custom_location
			 WHERE location_type_id = in_loc_type_id
			   AND LOWER(name) = LOWER(in_name);
	END;
	
	RETURN v_location_id;
END;

FUNCTION GetCustomLocationHash(
	in_s		VARCHAR2
) RETURN RAW
AS
BEGIN
	RETURN DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(UPPER(in_s), 'AL32UTF8'), dbms_crypto.hash_sh1);
END;

PROCEDURE CreateCustomLocation(
	in_loc_type_id		IN	custom_location.location_type_id%TYPE,
	in_address			IN	custom_location.address%TYPE,
	in_city				IN	custom_location.city%TYPE,
	in_province			IN	custom_location.province%TYPE,
	in_postcode			IN	custom_location.postcode%TYPE,
	in_country			IN	VARCHAR2,
	in_lat				IN	location.latitude%TYPE,
	in_lng				IN	location.longitude%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_country			postcode.country.country%TYPE;
	v_location_id		location.location_id%TYPE;
	v_is_approved		custom_location.is_approved%TYPE;
	v_hash				custom_location.location_hash%TYPE;
BEGIN
	-- no security, only run from batch
	
	v_country := GetCountryCode(in_country);
	v_location_id := INTERNAL_CreateLocation(in_loc_type_id, in_lat, in_lng, v_country);
	
	v_is_approved := 0;
	IF in_lat IS NOT NULL AND in_lng IS NOT NULL THEN
		SELECT auto_approve_search_location
		  INTO v_is_approved
		  FROM logistics_default
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;	
	
	v_hash := GetCustomLocationHash(in_address||'|'||in_city||'|'||in_province||'|'||in_postcode||'|'||in_country);
	
	BEGIN
		INSERT INTO custom_location (custom_location_id, location_type_id, address, city, province, postcode, country, 
			location_id, location_hash, is_approved)
		VALUES (custom_location_id_seq.nextval, in_loc_type_id, in_address, in_city, in_province, in_postcode, v_country,
			v_location_id, v_hash, v_is_approved);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			DELETE FROM location
			 WHERE location_id = v_location_id;
			
			SELECT location_id, is_approved
			  INTO v_location_id, v_is_approved
			  FROM custom_location
			 WHERE location_type_id = in_loc_type_id
			   AND location_hash = v_hash;
	END;
	
	OPEN out_cur FOR
		SELECT v_location_id location_id, v_is_approved is_approved
		  FROM dual;
END;

PROCEDURE GetCustomLocations(
	in_trans_mode_id	IN	transport_mode.transport_mode_id%TYPE,
	in_start			IN	NUMBER,
	in_limit			IN	NUMBER,
	in_column			IN	VARCHAR2,
	in_dir				IN	VARCHAR2,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to view logistics locations.');
	END IF;
	
	OPEN out_cur FOR
		SELECT custom_location_id, name, description, address, city, province, postcode, country
		  FROM (
				SELECT custom_location_id, name, description, address, city, province, postcode, country, ROW_NUMBER() OVER (ORDER BY name, description, country, province, city, address ASC) rn
				  FROM custom_location
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (
						(in_trans_mode_id = 1 AND (location_type_id = 1 OR location_type_id = 2)) OR
						(in_trans_mode_id = 2 AND location_type_id = 3) OR
						(in_trans_mode_id = 3 AND location_type_id = 4) OR
						(in_trans_mode_id = 4 AND location_type_id = 5) OR
						(in_trans_mode_id = 5 AND location_type_id = 6)
				)
		)
		 WHERE rn >= in_start + 1
		   AND rn < (in_start + in_limit + 1);

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM custom_location
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (
			(in_trans_mode_id = 1 AND (location_type_id = 1 OR location_type_id = 2)) OR
			(in_trans_mode_id = 2 AND location_type_id = 3) OR
			(in_trans_mode_id = 3 AND location_type_id = 4) OR
			(in_trans_mode_id = 4 AND location_type_id = 5) OR
			(in_trans_mode_id = 5 AND location_type_id = 6)
	);
END;


-- XXX: this is in meters not Km
FUNCTION GetDistance(
	in_origin_hash			IN	custom_location.location_hash%TYPE,
	in_destination_hash		IN	custom_location.location_hash%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE
) RETURN NUMBER
AS
	val			distance.distance%TYPE;
BEGIN
	-- umm - doesn't work both ways round (i.e. swap origin/dest)
	BEGIN
		SELECT distance
		  INTO val
		  FROM (
				SELECT distance, ROW_NUMBER() OVER (ORDER BY priority) priority_rn
				  FROM (
					SELECT cd.distance, 1 priority
					  FROM custom_distance cd
						JOIN location lo ON cd.origin_id = lo.location_id
						JOIN location ld ON cd.destination_id = ld.location_id
						JOIN custom_location clo ON lo.location_id = clo.location_id AND clo.location_hash = in_origin_hash
						JOIN custom_location cld ON ld.location_id = cld.location_id AND cld.location_hash = in_destination_hash
					 WHERE cd.transport_mode_id = in_transport_mode_id
					 UNION
						SELECT d.distance, 2 priority
					  FROM distance d
						JOIN location lo ON d.origin_id = lo.location_id
						JOIN location ld ON d.destination_id = ld.location_id
						JOIN custom_location clo ON lo.location_id = clo.location_id AND clo.location_hash = in_origin_hash
						JOIN custom_location cld ON ld.location_id = cld.location_id AND cld.location_hash = in_destination_hash
					 WHERE d.transport_mode_id = in_transport_mode_id
				 )
		 )
		 WHERE priority_rn = 1;
		
		RETURN val;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN -1;
	END;
END;

-- XXX: this is in meters not Km
FUNCTION GetDistance(
	in_origin_id			IN	location.location_id%TYPE,
	in_destination_id		IN	location.location_id%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE
) RETURN NUMBER
AS
	o_id		distance.origin_id%TYPE;
	d_id		distance.destination_id%TYPE;
	val			distance.distance%TYPE;
BEGIN
	-- no security, only run from batch
	
	SortOriginDest(in_origin_id, in_destination_id, o_id, d_id);
	
	BEGIN
		SELECT distance
		  INTO val
		  FROM (
				SELECT distance, ROW_NUMBER() OVER (ORDER BY priority) priority_rn
				  FROM (
						SELECT distance, 1 priority
						  FROM custom_distance
						 WHERE transport_mode_id = in_transport_mode_id
						   AND origin_id = o_id
						   AND destination_id = d_id
						   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 UNION
						SELECT distance, 2 priority
						  FROM distance
						 WHERE transport_mode_id = in_transport_mode_id
						   AND origin_id = o_id
						   AND destination_id = d_id
				)
		)
		 WHERE priority_rn = 1;
		
		RETURN val;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN -1;
	END;
END;

PROCEDURE GetCustomDistances(
	in_transport_mode_id	IN	custom_distance.transport_mode_id%TYPE,
	in_start				IN	NUMBER,
	in_limit				IN	NUMBER,
	in_column				IN	VARCHAR2,
	in_dir					IN	VARCHAR2,
	out_total_rows			OUT	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to view logistics locations.');
	END IF;
	
	OPEN out_cur FOR
		SELECT transport_mode_id, distance, from_id, to_id,
				from_name, from_description, from_address, from_city, from_province, from_postcode, from_country, from_lat, from_lng,
				to_name, to_description, to_address, to_city, to_province, to_postcode, to_country, to_lat, to_lng
		  FROM (
				SELECT cd.transport_mode_id, cd.distance, cd.origin_id from_id, cd.destination_id to_id,
					-- origin
					o.name from_name, o.description from_description, o.address from_address,
					o.city from_city, o.province from_province, o.postcode from_postcode, oc.name from_country,
					origin_location.latitude from_lat, origin_location.longitude from_lng,
					-- destination stuff
					d.name to_name, d.description to_description, d.address to_address,
					d.city to_city, d.province to_province, d.postcode to_postcode, dc.name to_country,
					destination_location.latitude to_lat, destination_location.longitude to_lng,
					ROW_NUMBER() OVER (ORDER BY oc.name, o.province, o.city, o.postcode, o.address, o.name, o.description,
						dc.name, d.province, d.city, d.postcode, d.address, d.name, d.description ASC) rn
				  FROM custom_distance cd
					  JOIN location origin_location ON cd.origin_id = origin_location.location_id
					  JOIN location destination_location ON cd.destination_id = destination_location.location_id
					  JOIN custom_location o ON origin_location.location_id = o.location_id
					  JOIN custom_location d ON destination_location.location_id = d.location_id
					  LEFT JOIN postcode.country oc ON o.country = oc.country
					  LEFT JOIN postcode.country dc ON d.country = dc.country
				 WHERE cd.transport_mode_Id = in_transport_mode_id
				   AND cd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		 WHERE rn >= in_start + 1
		   AND rn < (in_start + in_limit + 1);
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM custom_distance cd
	  JOIN location origin_location ON cd.origin_id = origin_location.location_id
	  JOIN location destination_location ON cd.destination_id = destination_location.location_id
	  JOIN custom_location o ON origin_location.location_id = o.location_id
	  JOIN custom_location d ON destination_location.location_id = d.location_id
	  LEFT JOIN postcode.country oc ON o.country = oc.country
	  LEFT JOIN postcode.country dc ON d.country = dc.country
	 WHERE cd.transport_mode_Id = in_transport_mode_id
	   AND cd.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetDistance(
	in_transport_mode_id	IN	distance.transport_mode_id%TYPE,
	in_origin_id			IN	distance.origin_id%TYPE,
	in_destination_id		IN	distance.destination_id%TYPE,
	in_distance				IN	distance.distance%TYPE
)
AS
	o_id		distance.origin_id%TYPE;
	d_id		distance.destination_id%TYPE;
BEGIN
	-- no security, only run from batch
	
	SortOriginDest(in_origin_id, in_destination_id, o_id, d_id);
	
	BEGIN
		INSERT INTO distance (transport_mode_id, origin_id, destination_id, distance)
			VALUES (in_transport_mode_id, o_id, d_id, in_distance);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE distance
			   SET distance = in_distance
			 WHERE transport_mode_id = in_transport_mode_id
			   AND origin_id = o_id
			   AND destination_id = d_id;
	END;
END;

FUNCTION SetCustomDistance(
	in_transport_mode_id	IN	custom_distance.transport_mode_id%TYPE,
	in_origin_id			IN	custom_location.custom_location_id%TYPE,
	in_destination_id		IN	custom_location.custom_location_id%TYPE,
	in_distance				IN	custom_distance.distance%TYPE
) RETURN NUMBER
AS
	v_origin_id			custom_distance.origin_id%TYPE;
	v_destination_id	custom_distance.destination_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to view logistics locations.');
	END IF;
	
	SortOriginDest(in_origin_id, in_destination_id, v_origin_id, v_destination_id);
	
	SELECT location_id
	  INTO v_origin_id
	  FROM custom_location
	 WHERE custom_location_id = v_origin_id;
		
	SELECT location_id
	  INTO v_destination_id
	  FROM custom_location
	 WHERE custom_location_id = v_destination_id;
		
	BEGIN
		INSERT INTO custom_distance (transport_mode_id, origin_id, destination_id, distance)
			VALUES (in_transport_mode_id, v_origin_id, v_destination_id, in_distance);
		
		UPDATE logistics_tab_mode
		   SET is_dirty = 1
		 WHERE transport_mode_id = in_transport_mode_id;
		
		RETURN 1;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RETURN 0;
	END;
END;

PROCEDURE DeleteCustomDistance(
	in_from_id				IN	custom_distance.origin_id%TYPE,
	in_to_id				IN	custom_distance.destination_id%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to view logistics locations.');
	END IF;
	
	DELETE FROM custom_distance
	 WHERE origin_id = in_from_id
	   AND destination_id = in_to_id
	   AND transport_mode_id = in_transport_mode_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EditCustomDistance(
	in_from_id				IN	custom_distance.origin_id%TYPE,
	in_to_id				IN	custom_distance.destination_id%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE,
	in_distance				IN	custom_distance.distance%TYPE
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to view logistics locations.');
	END IF;
	
	UPDATE custom_distance
	   SET distance = in_distance
	 WHERE origin_id = in_from_id
	   AND destination_id = in_to_id
	   AND transport_mode_id = in_transport_mode_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetLocations(
	in_search_fail		IN	NUMBER,
	in_is_approved		IN	location.is_approved%TYPE,
	in_loc_type_id		IN	location_type.location_type_id%TYPE,
	in_start			IN	NUMBER,
	in_limit			IN	NUMBER,
	in_column			IN	VARCHAR2,
	in_dir				IN	VARCHAR2,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user approve locations.');
	END IF;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM location l
	 WHERE l.is_approved = in_is_approved
	   AND (
			(in_search_fail = 1 AND l.latitude IS NULL AND l.longitude IS NULL)
			OR
			(in_search_fail = 0 AND l.latitude IS NOT NULL AND l.longitude IS NOT NULL)
	)
	   AND l.location_type_id IN (csr_data_pkg.LOC_TYPE_AIRPORT, csr_data_pkg.LOC_TYPE_COUNTRY)
	   AND (in_loc_type_id = 0 OR l.location_type_id = in_loc_type_id);
	
	OPEN out_cur FOR
		SELECT location_id, name, description, latitude, longitude, location_type, country, is_search_fail
		  FROM (
				SELECT l.location_id, l.name, l.description, l.latitude, l.longitude, lt.name location_type, pc.name country,
					CASE WHEN l.latitude IS NULL AND l.longitude IS NULL THEN 1 ELSE 0 END is_search_fail,
					ROW_NUMBER() OVER (ORDER BY l.name) rn
				  FROM location l
					JOIN location_type lt ON l.location_type_id = lt.location_type_id
					LEFT JOIN postcode.country pc ON l.country = pc.country
				 WHERE l.is_approved = in_is_approved
				   AND (
						(in_search_fail = 1 AND l.latitude IS NULL AND l.longitude IS NULL)
						OR
						(in_search_fail = 0 AND l.latitude IS NOT NULL AND l.longitude IS NOT NULL)
				)
				   AND l.location_type_id IN (csr_data_pkg.LOC_TYPE_AIRPORT, csr_data_pkg.LOC_TYPE_COUNTRY)
				   AND (in_loc_type_id = 0 OR l.location_type_id = in_loc_type_id)
		)
		 WHERE rn >= in_start + 1
		   AND (in_limit = 0 OR rn < (in_start + in_limit + 1));
END;

PROCEDURE GetCustomLocations(
	in_search_fail		IN	NUMBER,
	in_is_approved		IN	custom_location.is_approved%TYPE,
	in_loc_type_id		IN	location_type.location_type_id%TYPE,
	in_start			IN	NUMBER,
	in_limit			IN	NUMBER,
	in_column			IN	VARCHAR2,
	in_dir				IN	VARCHAR2,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to approve locations.');
	END IF;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM custom_location cl
	  JOIN location l ON cl.location_id = l.location_id
	 WHERE cl.is_approved = in_is_approved
	   AND (
			(in_search_fail = 1 AND l.latitude IS NULL AND l.longitude IS NULL)
			OR
			(in_search_fail = 0 AND l.latitude IS NOT NULL AND l.longitude IS NOT NULL)
		)
	   AND (in_loc_type_id = 0 OR l.location_type_id = in_loc_type_id)
	   AND cl.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_cur FOR
		SELECT custom_location_id, location_id, is_search_fail,
				name, description, address, city, province, postcode, country,
				latitude, longitude, location_type, airport_code
		  FROM (
				SELECT cl.custom_location_id, l.location_id, 
						CASE WHEN l.latitude IS NULL AND l.longitude IS NULL THEN 1 ELSE 0 END is_search_fail,
						cl.name, cl.description, cl.address, cl.city, cl.province, cl.postcode, pc.name country,
						l.latitude, l.longitude, lt.name location_type,
						CASE WHEN l.location_type_id = 1 THEN l.name ELSE NULL END airport_code,
						ROW_NUMBER() OVER (ORDER BY pc.name, cl.postcode, cl.province, cl.city, cl.address, cl.description, cl.name) rn
				  FROM custom_location cl
				  JOIN location l ON cl.location_id = l.location_id
				  JOIN location_type lt ON cl.location_type_id = lt.location_type_id
				  LEFT JOIN postcode.country pc ON cl.country = pc.country
				 WHERE cl.is_approved = in_is_approved
				   AND (
						(in_search_fail = 1 AND l.latitude IS NULL AND l.longitude IS NULL)
						OR
						(in_search_fail = 0 AND l.latitude IS NOT NULL AND l.longitude IS NOT NULL)
					)
				   AND (in_loc_type_id = 0 OR l.location_type_id = in_loc_type_id)
				   AND cl.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		 WHERE rn >= in_start + 1
		   AND (in_limit = 0 OR rn < (in_start + in_limit + 1));
END;

PROCEDURE ApproveLocation(
	in_location_id		IN	location.location_id%TYPE
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user approve locations.');
	END IF;
	
	UPDATE location
	   SET is_approved = 1
	 WHERE location_id = in_location_id;
END;

PROCEDURE ApproveLocation(
	in_location_id		IN	location.location_id%TYPE,
	in_description		IN	location.description%TYPE,
	in_latitude			IN	location.latitude%TYPE,
	in_longitude		IN	location.longitude%TYPE
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user approve locations.');
	END IF;
	
	UPDATE location
	   SET is_approved = 1, description = in_description, latitude = in_latitude, longitude = in_longitude
	 WHERE location_id = in_location_id;
END;

PROCEDURE ApproveCustomLocation(
	in_custom_location_id		IN	custom_location.custom_location_id%TYPE
)
AS
	v_location_type_id			location_type.location_type_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to approve locations.');
	END IF;
	
	SELECT location_type_id
	  INTO v_location_type_id
	  FROM custom_location
	 WHERE custom_location_id = in_custom_location_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE custom_location
	   SET is_approved = 1
	 WHERE custom_location_id = in_custom_location_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE logistics_tab_mode
	   SET is_dirty = 1
	 WHERE (transport_mode_id = csr_data_pkg.TRANSPORT_MODE_AIR AND v_location_type_id = csr_data_pkg.LOC_TYPE_AIRPORT)
	    OR (transport_mode_id = csr_data_pkg.TRANSPORT_MODE_ROAD AND v_location_type_id = csr_data_pkg.LOC_TYPE_ROAD);
END;

PROCEDURE ApproveCustomLocation(
	in_custom_location_id		IN	custom_location.custom_location_id%TYPE,
	in_location_type			IN	location_type.name%TYPE,
	in_latitude					IN	location.latitude%TYPE,
	in_longitude				IN	location.longitude%TYPE
)
AS
	v_location_id		location.location_id%TYPE;
	v_orig_loc_id		location.location_id%TYPE;
	v_location_hash		custom_location.location_hash%TYPE;
	v_country			location.country%TYPE;
	v_location_type_id	location_type.location_type_id%TYPE;
	v_sp				logistics_tab_mode.location_changed_sp%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to approve locations.');
	END IF;
	
	SELECT location_type_id
	  INTO v_location_type_id
	  FROM location_type
	 WHERE name = in_location_type;
	
	SELECT location_id, location_hash
	  INTO v_orig_loc_id, v_location_hash
	  FROM custom_location
	 WHERE custom_location_id = in_custom_location_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT country
	  INTO v_country
	  FROM location
	 WHERE location_id = v_orig_loc_id;
	
	v_location_id := INTERNAL_CreateLocation(v_location_type_id, in_latitude, in_longitude, v_country);
	
	UPDATE custom_location
	   SET location_id = v_location_id, is_approved = 1
	 WHERE custom_location_id = in_custom_location_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	BEGIN
		DELETE FROM location
		 WHERE location_id = v_orig_loc_id;
	EXCEPTION
		WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT tab_sid, processor_class_id
		  FROM logistics_tab_mode
		 WHERE (transport_mode_id = csr_data_pkg.TRANSPORT_MODE_AIR AND v_location_type_id = csr_data_pkg.LOC_TYPE_AIRPORT)
		    OR (transport_mode_id = csr_data_pkg.TRANSPORT_MODE_ROAD AND v_location_type_id = csr_data_pkg.LOC_TYPE_ROAD)
	)
	LOOP
		SELECT location_changed_sp
		  INTO v_sp
		  FROM logistics_tab_mode
		 WHERE tab_sid = r.tab_sid
		   AND processor_class_id = r.processor_class_id;
		
		IF v_sp IS NOT NULL THEN
			EXECUTE IMMEDIATE 'BEGIN ' || v_sp || '(:1); END;'
				USING v_location_hash;
		END IF;
	END LOOP;
	
	UPDATE logistics_tab_mode
	   SET is_dirty = 1
	 WHERE (transport_mode_id = csr_data_pkg.TRANSPORT_MODE_AIR AND v_location_type_id = csr_data_pkg.LOC_TYPE_AIRPORT)
	    OR (transport_mode_id = csr_data_pkg.TRANSPORT_MODE_ROAD AND v_location_type_id = csr_data_pkg.LOC_TYPE_ROAD);
END;

PROCEDURE ApproveCustomLocation(
	in_custom_location_id		IN	custom_location.custom_location_id%TYPE,
	in_airport_code				IN	location.name%TYPE
)
AS
	v_location_id				location.location_id%TYPE;
	v_location_hash				custom_location.location_hash%TYPE;
	v_sp						logistics_tab_mode.location_changed_sp%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to approve locations.');
	END IF;
	
	SELECT location_id
	  INTO v_location_id
	  FROM location
	 WHERE LOWER(name) = LOWER(in_airport_code)
	   AND location_type_id = 1;
	
	SELECT location_hash
	  INTO v_location_hash
	  FROM custom_location
	 WHERE custom_location_id = in_custom_location_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE custom_location
	   SET location_id = v_location_id, is_approved = 1
	 WHERE custom_location_id = in_custom_location_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	FOR r IN (
		SELECT tab_sid, processor_class_id
		  FROM logistics_tab_mode
		 WHERE transport_mode_id = csr_data_pkg.TRANSPORT_MODE_AIR
	)
	LOOP
		SELECT location_changed_sp
		  INTO v_sp
		  FROM logistics_tab_mode
		 WHERE tab_sid = r.tab_sid
		   AND processor_class_id = r.processor_class_id;
		
		IF v_sp IS NOT NULL THEN
			EXECUTE IMMEDIATE 'BEGIN ' || v_sp || '(:1); END;'
				USING v_location_hash;
		END IF;
	END LOOP;
	
	UPDATE logistics_tab_mode
	   SET is_dirty = 1
	 WHERE transport_mode_id = csr_data_pkg.TRANSPORT_MODE_AIR;
END;

PROCEDURE ApproveAllCustomLocations
AS
BEGIN
	UPDATE custom_location
	   SET is_approved = 1
	 WHERE custom_location_id IN (
			SELECT cl.custom_location_id
			  FROM custom_location cl
			  JOIN location l ON cl.location_id = l.location_id
			 WHERE cl.is_approved = 0
			   AND (l.latitude IS NOT NULL AND l.longitude IS NOT NULL)
			   AND cl.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	);
END;

FUNCTION IsAutoCreateLocation 
RETURN logistics_default.auto_create_custom_location%TYPE
AS
	v_bool				logistics_default.auto_create_custom_location%TYPE;
BEGIN
	SELECT auto_create_custom_location
	  INTO v_bool
	  FROM logistics_default
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');	
	RETURN v_bool;
END;

FUNCTION IsSortColumn
RETURN logistics_default.sort_column%TYPE
AS
	v_bool				logistics_default.sort_column%TYPE;
BEGIN
	SELECT sort_column
	  INTO v_bool
	  FROM logistics_default
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');	
	RETURN v_bool;
END;

PROCEDURE AddErrorLog(
	in_tab_sid			IN	security_pkg.T_SID_ID,
	in_processor_class	IN	logistics_processor_class.label%TYPE,
	in_id				IN	logistics_error_log.id%TYPE,
	in_msg				IN	logistics_error_log.message%TYPE
)
AS
	v_proc_class_id			logistics_processor_class.processor_class_id%TYPE;
BEGIN
	-- no security, only run from batch
	
	SELECT processor_class_id
	  INTO v_proc_class_id
	  FROM logistics_processor_class
	 WHERE label = in_processor_class;
	
	-- TODO: previously Benny had message as part of the PK constraint -- consider impact of adding
	-- it in as part of a unique constraint. Not sure it really makes sense?
	INSERT INTO logistics_error_log (logistics_error_log_id, tab_sid, processor_class_id, id, message)
		VALUES (logistics_error_log_id_seq.nextval, in_tab_sid, v_proc_class_id, in_id, in_msg);
END;

PROCEDURE GetErrorLogs(
	in_loc_type_id		IN	location_type.location_type_id%TYPE,
	in_start			IN	NUMBER,
	in_limit			IN	NUMBER,
	in_column			IN	VARCHAR2,
	in_dir				IN	VARCHAR2,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to view error logs.');
	END IF;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM (
			SELECT DISTINCT app_sid, message, processor_class_id
			  FROM logistics_error_log lel
			 WHERE in_loc_type_id = 0 OR
					(lel.processor_class_id = 1 AND in_loc_type_id = 1) OR
					(lel.processor_class_id = 2 AND in_loc_type_id = 2) OR
					(lel.processor_class_id = 3 AND in_loc_type_id = 4) OR
					(lel.processor_class_id = 4 AND in_loc_type_id = 3) OR
					(lel.processor_class_id = 5 AND in_loc_type_id = 5) OR
					(lel.processor_class_id = 6 AND in_loc_type_id = 6)
	);
	
	OPEN out_cur FOR
		SELECT message, id, transport_mode, logistics_error_log_id
		  FROM (
				SELECT message, id, transport_mode, logistics_error_log_id,
						ROW_NUMBER() OVER (ORDER BY transport_mode, message, id) rn
				  FROM (
						SELECT message, STRAGG(id) id, transport_mode, MIN(logistics_error_log_id) logistics_error_log_id
						  FROM (
								SELECT message, id, transport_mode, logistics_error_log_id
								  FROM (
										SELECT lel.logistics_error_log_id, lel.message, lel.id, tm.label transport_mode,
												ROW_NUMBER() OVER (PARTITION BY lel.message, tm.label ORDER BY lel.logistics_error_log_id) rn
										  FROM logistics_error_log lel
										  JOIN logistics_tab_mode ltm ON lel.app_sid = ltm.app_sid AND lel.tab_sid = ltm.tab_sid AND lel.processor_class_id = ltm.processor_class_id
										  JOIN transport_mode tm ON ltm.transport_mode_id = tm.transport_mode_id
										 WHERE (
												in_loc_type_id = 0 OR
												(lel.processor_class_id = 1 AND in_loc_type_id = 1) OR
												(lel.processor_class_id = 2 AND in_loc_type_id = 2) OR
												(lel.processor_class_id = 3 AND in_loc_type_id = 4) OR
												(lel.processor_class_id = 4 AND in_loc_type_id = 3) OR
												(lel.processor_class_id = 5 AND in_loc_type_id = 5) OR
												(lel.processor_class_id = 6 AND in_loc_type_id = 6)
										)
								)
								 WHERE rn <= 10
						)
						 GROUP BY message, transport_mode
						 ORDER BY transport_mode, message, id
				)
		)
		 WHERE rn >= in_start + 1
		   AND (in_limit = 0 OR rn < (in_start + in_limit + 1));
END;

PROCEDURE RemoveErrorLog(
	in_logistics_error_log_id	IN	logistics_error_log.logistics_error_log_id%TYPE,
	in_delete					IN	NUMBER
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_id				logistics_error_log.id%TYPE;
	v_message			logistics_error_log.message%TYPE;
	v_delete_row_sp		logistics_tab_mode.delete_row_sp%TYPE;
	v_tab_sid			security_pkg.T_SID_ID;
	v_proc_class_id		logistics_tab_mode.processor_class_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to modify error logs.');
	END IF;
	
	SELECT lel.app_sid, lel.message, ltm.delete_row_sp, ltm.tab_sid, ltm.processor_class_id
	  INTO v_app_sid, v_message, v_delete_row_sp, v_tab_sid, v_proc_class_id
	  FROM logistics_error_log lel
	  JOIN logistics_tab_mode ltm ON lel.app_sid = ltm.app_sid AND lel.tab_sid = ltm.tab_sid AND lel.processor_class_id = ltm.processor_class_id
	 WHERE lel.logistics_error_log_id = in_logistics_error_log_id;
	
	IF in_delete = 1 THEN
		FOR r IN (
			SELECT lel.id
			  FROM logistics_error_log lel
			 WHERE app_sid = v_app_sid
			   AND message = v_message
			   AND processor_class_id = v_proc_class_id
		)
		LOOP
			EXECUTE IMMEDIATE 'BEGIN ' || v_delete_row_sp ||'(:1); END;' using r.id;
		END LOOP;
	END IF;
	
	DELETE FROM logistics_error_log
	 WHERE app_sid = v_app_sid
	   AND message = v_message
	   AND processor_class_id = v_proc_class_id;
	
	UPDATE logistics_tab_mode
	   SET is_dirty = 1
	 WHERE app_sid = v_app_sid
	   AND tab_sid = v_tab_sid
	   AND processor_class_id = v_proc_class_id;
END;

PROCEDURE RemoveAllErrorLogs(
	in_delete					IN	NUMBER
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_id				logistics_error_log.id%TYPE;
	v_message			logistics_error_log.message%TYPE;
	v_delete_row_sp		logistics_tab_mode.delete_row_sp%TYPE;
	v_tab_sid			security_pkg.T_SID_ID;
	v_proc_class_id		logistics_tab_mode.processor_class_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR csr_data_pkg.CheckCapability('Manage Logistics')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You don''t have administrative rights to modify error logs.');
	END IF;
	
	IF in_delete = 1 THEN
		FOR r IN (
			SELECT lel.id, ltm.delete_row_sp
			  FROM logistics_error_log lel
			  JOIN logistics_tab_mode ltm ON lel.app_sid = ltm.app_sid AND lel.tab_sid = ltm.tab_sid AND lel.processor_class_id = ltm.processor_class_id
			 WHERE lel.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		LOOP
			EXECUTE IMMEDIATE 'BEGIN ' || r.delete_row_sp ||'(:1); END;' using r.id;
		END LOOP;
	END IF;
	
	UPDATE logistics_tab_mode
	   SET is_dirty = 1
	 WHERE (app_sid, tab_sid, processor_class_id) IN (
			SELECT DISTINCT lel.app_sid, lel.tab_sid, lel.processor_class_id
			  FROM logistics_error_log lel
			 WHERE lel.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	);
	
	DELETE FROM logistics_error_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetTransportModes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT tm.transport_mode_id id, tm.label
		  FROM logistics_tab_mode ltm
		  JOIN transport_mode tm ON ltm.transport_mode_id = tm.transport_mode_id
		 WHERE ltm.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAirportList(
	in_filter			IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name code, description, latitude, longitude
		  FROM location
		 WHERE location_type_id = 1
		   AND LOWER(name) LIKE lower(in_filter) || '%'
		 ORDER BY name, description;
END;

END;
/
