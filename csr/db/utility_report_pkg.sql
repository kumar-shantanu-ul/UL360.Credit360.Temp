CREATE OR REPLACE PACKAGE CSR.utility_report_pkg IS

PROCEDURE GetRegionTreeForExtract(
	in_start_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetDocumentsForRegion (
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_proc_docs					OUT	SYS_REFCURSOR,
	out_proc_files					OUT	SYS_REFCURSOR,
	out_reading_files				OUT	SYS_REFCURSOR,
	out_contract					OUT	SYS_REFCURSOR,
	out_invoices					OUT	SYS_REFCURSOR
);

PROCEDURE SuppliersWithoutContracts (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterRoles (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE MetersWithoutContracts (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CRCMeterContractExpired (
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir						IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE MetersMissingPeriodData (
	in_period_months				IN	NUMBER,
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SpecialEventsForTree (
	in_start_sid					IN	security_pkg.T_SID_ID,
	in_show_inherited				IN	NUMBER,
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	in_start_dtm					IN EVENT.EVENT_DTM%TYPE,
	in_end_dtm						IN EVENT.EVENT_DTM%TYPE,	
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE MetersFlaggedCRCndicatorsNot (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE IndicatorsFlaggedCRCMetersNot (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetCRCMeterDump (
	out_roles						OUT	SYS_REFCURSOR,
	out_dump						OUT	SYS_REFCURSOR
);

PROCEDURE GetCRCMeterDump (
	in_from_dtm						IN DATE,
	in_to_dtm						IN DATE,
	out_roles						OUT	SYS_REFCURSOR,
	out_dump						OUT	SYS_REFCURSOR
);

PROCEDURE MeterConsumption (
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir						IN	VARCHAR2,
	in_from_dtm						IN DATE,
	in_to_dtm						IN DATE,
	out_consumption					OUT	SYS_REFCURSOR
);

PROCEDURE SetBatchJob(
	in_region_sid 					IN	batch_job_meter_extract.region_sid%TYPE, 
	in_start_dtm 					IN	batch_job_meter_extract.start_dtm%TYPE, 
	in_end_dtm 						IN	batch_job_meter_extract.end_dtm%TYPE, 
	in_period_set_id 				IN	batch_job_meter_extract.period_set_id%TYPE,
	in_period_interval_id 			IN	batch_job_meter_extract.period_set_id%TYPE,
	in_is_full						IN	batch_job_meter_extract.is_full%TYPE,
	in_user_sid						IN	batch_job_meter_extract.user_sid%TYPE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetBatchJob(
	in_batch_job_id					IN NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UpdateBatchJob(
	in_batch_job_id					IN NUMBER,
	in_report_data					IN batch_job_meter_extract.report_data%TYPE
);

PROCEDURE GetBatchJobReportData(
	in_batch_job_id					IN NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

END utility_report_pkg;
/
