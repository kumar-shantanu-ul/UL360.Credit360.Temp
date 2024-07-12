CREATE OR REPLACE PACKAGE BODY ACTIONS.file_upload_pkg
IS

PROCEDURE GetFileData(
	in_file_id			IN	file_upload.file_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_access_allowed	NUMBER;
BEGIN
	-- To be able to read the file the user must have 
	-- read access on a task associated with the file
	v_access_allowed := 0;
	FOR r IN (
		SELECT task_sid
		  FROM task_file_upload
		 WHERE file_id = in_file_id
		UNION
		SELECT task_sid
		  FROM task_period_file_upload
		 WHERE file_id = in_file_id
	) LOOP
		IF security_pkg.IsAccessAllowedSID(security_pkg.GetACT, r.task_sid, security_pkg.PERMISSION_READ) THEN
			v_access_allowed := 1;
			EXIT; -- No need to look any further
		END IF;
	END LOOP;
	
	-- Check to see if access was allowed
	IF v_access_allowed = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading file with ID ' || in_file_id);
	END IF;
	
	-- Get the file data
	OPEN out_cur FOR
		SELECT file_id, file_name, mime_type, data
		  FROM file_upload
		 WHERE file_id = in_file_id;
END;

PROCEDURE InsertTaskFileFromCache(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_id				OUT	file_upload.file_id%TYPE
)
AS
BEGIN
	InsertTaskFileFromCache(in_task_sid, in_cache_key, NULL, out_id);
END;

PROCEDURE InsertTaskFileFromCache(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	in_group_id			IN	file_upload_group.file_upload_group_id%TYPE,
	out_id				OUT	file_upload.file_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, task_pkg.PERMISSION_ADD_COMMENT) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied inserting file for task with SID ' || in_task_sid);
	END IF;
	
	SELECT file_upload_id_seq.nextval
	  INTO out_id
	  FROM DUAL;
	
	INSERT INTO file_upload
		(file_id, file_name, mime_type, data)
		SELECT out_id, filename, mime_type, object
		  FROM aspen2.filecache 
		 WHERE cache_key = in_cache_key;
		 
	INSERT INTO task_file_upload
		(task_sid, file_id)
	  VALUES (in_task_sid, out_id);
	
	-- Add to group if requested
	IF in_group_id IS NOT NULL THEN	
		INSERT INTO file_upload_group_member
			(file_upload_group_id, file_id)
		  VALUES(in_group_id, out_id);
	END IF;
END;

PROCEDURE InsertTaskPeriodFileFromCache(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_id				OUT	file_upload.file_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, task_pkg.PERMISSION_ADD_COMMENT) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied inserting file for task with SID ' || in_task_sid);
	END IF;
	
	
	SELECT file_upload_id_seq.nextval 
	  INTO out_id 
	  FROM DUAL;
	
	INSERT INTO file_upload
		(file_id, file_name, mime_type, data)
		SELECT out_id, filename, mime_type, object
		  FROM aspen2.filecache 
		 WHERE cache_key = in_cache_key;
		 
	INSERT INTO task_period_file_upload
		(task_sid, start_dtm, region_sid, file_id)
		VALUES (in_task_sid, in_start_dtm, in_region_sid, out_id);
END;

PROCEDURE GetFilesForTask(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading file list for task with SID ' || in_task_sid);
	END IF;
	
	OPEN out_cur FOR 
		SELECT f.file_id, f.file_name, f.mime_type, 
				g.file_upload_group_id group_id, g.name group_name, g.label group_label
		  FROM file_upload f, task_file_upload t, file_upload_group g, file_upload_group_member gm
		 WHERE t.task_sid = in_task_sid
		   AND f.file_id = t.file_id
		   AND gm.file_id(+) = f.file_id
		   AND g.file_upload_group_id(+) = gm.file_upload_group_id;
END;

PROCEDURE GetFilesForTaskPeriod(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading file list for task with SID ' || in_task_sid);
	END IF;
	
	OPEN out_cur FOR 
		SELECT f.file_id, f.file_name, f.mime_type
		  FROM file_upload f, task_period_file_upload t
		 WHERE t.task_sid = in_task_sid
		   AND t.start_dtm = in_start_dtm
		   AND t.region_sid = in_region_sid
		   AND f.file_id = t.file_id;
END;

PROCEDURE DeleteAbsentTaskFiles(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_file_ids			IN	T_FILE_IDS
)
AS
	v_current_ids		T_FILE_IDS;
BEGIN
	-- Get current ids
	FOR r IN (
		SELECT f.file_id
		  FROM file_upload f, task_file_upload t
		 WHERE t.task_sid = in_task_sid
		   AND f.file_id = t.file_id
	) LOOP
		v_current_ids(r.file_id) := r.file_id;
	END LOOP;
	
	-- Remove any file ids present in the input array
	IF in_file_ids(1) IS NOT NULL THEN
		FOR i IN in_file_ids.FIRST .. in_file_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_file_ids(i)) THEN
				v_current_ids.DELETE(in_file_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining
	IF v_current_ids.COUNT > 0 THEN
		FOR i IN v_current_ids.FIRST .. v_current_ids.LAST
		LOOP
			DELETE FROM file_upload_group_member WHERE file_id = v_current_ids(i);
			DELETE FROM task_file_upload WHERE file_id = v_current_ids(i);
			DELETE FROM file_upload WHERE file_id = v_current_ids(i);
		END LOOP;
	END IF;
END;

PROCEDURE DeleteAbsentTaskPeriodFiles(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_file_ids			IN	T_FILE_IDS
)
AS
	v_current_ids		T_FILE_IDS;
BEGIN
	-- Get current ids
	FOR r IN (
		SELECT f.file_id
		  FROM file_upload f, task_period_file_upload t
		 WHERE t.task_sid = in_task_sid
		   AND t.start_dtm = in_start_dtm
		   AND t.region_sid = in_region_sid
		   AND f.file_id = t.file_id
	) LOOP
		v_current_ids(r.file_id) := r.file_id;
	END LOOP;
	
	-- Remove any file ids present in the input array
	IF in_file_ids(1) IS NOT NULL THEN
		FOR i IN in_file_ids.FIRST .. in_file_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_file_ids(i)) THEN
				v_current_ids.DELETE(in_file_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining
	IF v_current_ids.COUNT > 0 THEN
		FOR i IN v_current_ids.FIRST .. v_current_ids.LAST
		LOOP
			DELETE FROM task_period_file_upload WHERE file_id = v_current_ids(i);
			DELETE FROM file_upload WHERE file_id = v_current_ids(i);
		END LOOP;
	END IF;
END;

PROCEDURE GetGroups(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT file_upload_group_id, name, label
		  FROM file_upload_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END file_upload_pkg;
/
