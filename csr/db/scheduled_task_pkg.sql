CREATE OR REPLACE PACKAGE CSR.scheduled_task_pkg AS

PROCEDURE LogTaskRunStart(
	in_task_group 		IN	csr.scheduled_task_stat.task_group%TYPE,
	in_task_name 		IN	csr.scheduled_task_stat.task_name%TYPE,
	in_ran_on			IN	csr.scheduled_task_stat.ran_on%TYPE,
	in_run_guid			IN	csr.scheduled_task_stat.run_guid%TYPE,
	out_run_id			OUT	csr.scheduled_task_stat.scheduled_task_stat_run_id%TYPE
);

PROCEDURE LogTaskRunComplete(
	in_run_id						IN	csr.scheduled_task_stat.scheduled_task_stat_run_id%TYPE,
	in_number_of_apps				IN	csr.scheduled_task_stat.number_of_apps%TYPE,
	in_number_of_items				IN	csr.scheduled_task_stat.number_of_items%TYPE,
	in_number_of_handled_failures	IN	csr.scheduled_task_stat.number_of_handled_failures%TYPE,
	in_fetch_time_secs				IN	csr.scheduled_task_stat.fetch_time_secs%TYPE,
	in_work_time_secs				IN	csr.scheduled_task_stat.work_time_secs%TYPE,
	in_was_unhandled_failure		IN	csr.scheduled_task_stat.was_unhandled_failure%TYPE
);

END scheduled_task_pkg;
/
