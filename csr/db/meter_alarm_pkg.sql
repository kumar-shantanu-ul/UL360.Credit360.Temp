#CREATE OR REPLACE PACKAGE CSR.meter_alarm_pkg IS

PROCEDURE InheritAlarmsFromParent(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveInheritedAlarms(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE DEFAULT NULL
);

PROCEDURE PropagateAlarms(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE OnNewRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE OnMoveRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE OnCopyRegion(
	in_from_region_sid		IN	security_pkg.T_SID_ID,
	in_new_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE OnDeleteRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE OnTrashRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE OnConvertRegionToLink(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE AssignAlarmToRegion(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_ignore				IN	region_meter_alarm.ignore%TYPE,
	in_ignore_children		IN	region_meter_alarm.ignore_children%TYPE
);

PROCEDURE SetAlarm(
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_inheritable			IN	meter_alarm.inheritable%TYPE,
	in_enabled				IN	meter_alarm.enabled%TYPE,
	in_name					IN	meter_alarm.name%TYPE,
	in_test_time_id			IN	meter_alarm.test_time_id%TYPE,
	in_look_at_stat_id		IN	meter_alarm.look_at_statistic_id%TYPE,
	in_comp_stat_id			IN	meter_alarm.compare_statistic_id%TYPE,
	in_comp_id				IN	meter_alarm.comparison_id%TYPE,
	in_comp_val				IN	meter_alarm.comparison_val%TYPE,
	in_issue_period_id		IN	meter_alarm.issue_period_id%TYPE,
	in_issue_trigger_cnt	IN	meter_alarm.issue_trigger_count%TYPE,
	out_alarm_id			OUT	meter_alarm.meter_alarm_id%TYPE
);

PROCEDURE SetAlarmForRegion(
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_inheritable			IN	meter_alarm.inheritable%TYPE,
	in_enabled				IN	meter_alarm.enabled%TYPE,
	in_name					IN	meter_alarm.name%TYPE,
	in_test_time_id			IN	meter_alarm.test_time_id%TYPE,
	in_look_at_stat_id		IN	meter_alarm.look_at_statistic_id%TYPE,
	in_comp_stat_id			IN	meter_alarm.compare_statistic_id%TYPE,
	in_comp_id				IN	meter_alarm.comparison_id%TYPE,
	in_comp_val				IN	meter_alarm.comparison_val%TYPE,
	in_issue_period_id		IN	meter_alarm.issue_period_id%TYPE,
	in_issue_trigger_cnt	IN	meter_alarm.issue_trigger_count%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ignore				IN	region_meter_alarm.ignore%TYPE,
	in_ignore_children		IN	region_meter_alarm.ignore_children%TYPE,
	out_alarm_id			OUT	meter_alarm.meter_alarm_id%TYPE
);

PROCEDURE SetInheritable(
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_inheritable			IN	meter_alarm.inheritable%TYPE
);

PROCEDURE SetIgnore(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_ignore				IN	region_meter_alarm.ignore%TYPE
);

PROCEDURE SetIgnoreChildren(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_ignore_children		IN	region_meter_alarm.ignore_children%TYPE
);

PROCEDURE RemoveAlarm(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE
);

PROCEDURE GetAlarm (
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlarmsForRegion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlarmsForRegion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_inherited			OUT	security_pkg.T_OUTPUT_CUR,
	out_this_level			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveAlarms(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComparisons(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTestTimes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIssuePeriods(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatistics(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlarmDlgOptions (
	out_comparisons			OUT	security_pkg.T_OUTPUT_CUR,
	out_test_times			OUT	security_pkg.T_OUTPUT_CUR,
	out_issue_periods		OUT	security_pkg.T_OUTPUT_CUR,
	out_statistics			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddAlarmEvent (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_data_dtm				IN	DATE
);

PROCEDURE IssuePeriodLastIssue (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm				DATE,
	out_raise				OUT NUMBER
);

PROCEDURE IssuePeriodLastRollingMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm				DATE,
	out_raise				OUT NUMBER
);

PROCEDURE IssuePeriodLastCalendarMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm				DATE,
	out_raise				OUT NUMBER
);

PROCEDURE IssuePeriodLastRollingQuarter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm				DATE,
	out_raise				OUT NUMBER
);

PROCEDURE IssuePeriodLastCalendarQuarter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm				DATE,
	out_raise				OUT NUMBER
);

PROCEDURE TestEveryDay (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_statistic_id			IN	meter_alarm_statistic.statistic_id%TYPE,
	in_test_dtm				IN	DATE,
	out_do_test				OUT	NUMBER
);

PROCEDURE TestFirstDayOfMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_statistic_id			IN	meter_alarm_statistic.statistic_id%TYPE,
	in_test_dtm				IN	DATE,
	out_do_test				OUT	NUMBER
);

PROCEDURE TestLastDayOfMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_statistic_id			IN	meter_alarm_statistic.statistic_id%TYPE,
	in_test_dtm				IN	DATE,
	out_do_test				OUT	NUMBER
);

PROCEDURE AddIssue (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_label				IN  issue.label%TYPE,
	in_issue_dtm			IN	issue_meter.issue_dtm%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_issue_id			OUT issue.issue_id%TYPE
);

PROCEDURE GetIssue(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetAlarmUrl(
	in_issue_meter_alarm_id	IN	issue_meter_alarm.issue_meter_alarm_id%TYPE
) RETURN VARCHAR2;

PROCEDURE GetAlarmEvents(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE PrepCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE InsertCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_time			IN	core_working_hours.start_time%TYPE,
	in_end_time				IN	core_working_hours.end_time%TYPE,
	in_mon					IN	NUMBER,
	in_tue					IN	NUMBER,
	in_wed					IN	NUMBER,
	in_thu					IN	NUMBER,
	in_fri					IN	NUMBER,
	in_sat					IN	NUMBER,
	in_sun					IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateCoreWorkingHours(
	in_cwh_id				IN	core_working_hours.core_working_hours_id%TYPE,
	in_start_time			IN	core_working_hours.start_time%TYPE,
	in_end_time				IN	core_working_hours.end_time%TYPE,
	in_mon					IN	NUMBER,
	in_tue					IN	NUMBER,
	in_wed					IN	NUMBER,
	in_thu					IN	NUMBER,
	in_fri					IN	NUMBER,
	in_sat					IN	NUMBER,
	in_sun					IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteCoreWorkingHours(
	in_cwh_id				IN	core_working_hours.core_working_hours_id%TYPE
);

PROCEDURE GetCoreWorkingHoursBucket (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CheckAlarmCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_alarm_id		IN	meter_alarm.meter_alarm_id%TYPE
) RETURN NUMBER;

END meter_alarm_pkg;
/
