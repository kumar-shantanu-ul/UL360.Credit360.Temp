CREATE OR REPLACE PACKAGE BODY CSR.scheduled_task_pkg AS

PROCEDURE LogTaskRunStart(
	in_task_group 		IN	csr.scheduled_task_stat.task_group%TYPE,
	in_task_name 		IN	csr.scheduled_task_stat.task_name%TYPE,
	in_ran_on			IN	csr.scheduled_task_stat.ran_on%TYPE,
	in_run_guid			IN	csr.scheduled_task_stat.run_guid%TYPE,
	out_run_id			OUT	csr.scheduled_task_stat.scheduled_task_stat_run_id%TYPE
)
AS
BEGIN
	INSERT INTO scheduled_task_stat
		(scheduled_task_stat_run_id, task_group, task_name, ran_on, run_guid)
	VALUES(scheduled_task_stat_id.nextval, in_task_group, in_task_name, in_ran_on, in_run_guid)
	RETURNING scheduled_task_stat_run_id INTO out_run_id;
END;

PROCEDURE LogTaskRunComplete(
	in_run_id						IN	csr.scheduled_task_stat.scheduled_task_stat_run_id%TYPE,
	in_number_of_apps				IN	csr.scheduled_task_stat.number_of_apps%TYPE,
	in_number_of_items				IN	csr.scheduled_task_stat.number_of_items%TYPE,
	in_number_of_handled_failures	IN	csr.scheduled_task_stat.number_of_handled_failures%TYPE,
	in_fetch_time_secs				IN	csr.scheduled_task_stat.fetch_time_secs%TYPE,
	in_work_time_secs					IN	csr.scheduled_task_stat.work_time_secs%TYPE,
	in_was_unhandled_failure		IN	csr.scheduled_task_stat.was_unhandled_failure%TYPE
)
AS
BEGIN
	UPDATE scheduled_task_stat
	   SET run_end_dtm = SYSDATE,
		   number_of_apps 				= in_number_of_apps,
		   number_of_items 				= in_number_of_items,
		   number_of_handled_failures 	= in_number_of_handled_failures,
		   fetch_time_secs 				= in_fetch_time_secs,
		   work_time_secs 				= in_work_time_secs,
		   was_unhandled_failure 		= in_was_unhandled_failure
	 WHERE scheduled_task_stat_run_id = in_run_id;
END;


END;
/
