CREATE OR REPLACE PACKAGE  ACTIONS.file_upload_pkg
IS

TYPE T_FILE_IDS IS TABLE OF file_upload.file_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE GetFileData(
	in_file_id			IN	file_upload.file_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE InsertTaskFileFromCache(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_id				OUT	file_upload.file_id%TYPE
);

PROCEDURE InsertTaskFileFromCache(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	in_group_id			IN	file_upload_group.file_upload_group_id%TYPE,
	out_id				OUT	file_upload.file_id%TYPE
);

PROCEDURE InsertTaskPeriodFileFromCache(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_id				OUT	file_upload.file_id%TYPE
);

PROCEDURE GetFilesForTask(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFilesForTaskPeriod(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAbsentTaskFiles(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_file_ids			IN	T_FILE_IDS
);

PROCEDURE DeleteAbsentTaskPeriodFiles(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_file_ids			IN	T_FILE_IDS
);

PROCEDURE GetGroups(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END file_upload_pkg;
/

