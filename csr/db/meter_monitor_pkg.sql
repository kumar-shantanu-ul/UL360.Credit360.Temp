CREATE OR REPLACE PACKAGE CSR.meter_monitor_pkg IS

NO_CONVERSION_FOUND EXCEPTION;
ERR_NO_CONVERSION_FOUND	CONSTANT NUMBER := -20600;
PRAGMA EXCEPTION_INIT(NO_CONVERSION_FOUND, -20600);

MULTIPLE_SERIAL_MATCHES EXCEPTION;
ERR_MULTIPLE_SERIAL_MATCHES	CONSTANT NUMBER := -20601;
PRAGMA EXCEPTION_INIT(MULTIPLE_SERIAL_MATCHES, -20601);

OVERLAPPING_DATA EXCEPTION;
ERR_OVERLAPPING_DATA	CONSTANT NUMBER := -20603;
PRAGMA EXCEPTION_INIT(OVERLAPPING_DATA, -20603);


-- Array of dates
TYPE T_DATE_ARRAY IS TABLE OF DATE INDEX BY PLS_INTEGER;

-- Array of values
TYPE T_VAL_ARRAY IS TABLE OF NUMBER(24, 10) INDEX BY PLS_INTEGER;

-- Raw data status
RAW_DATA_STATUS_NEW				CONSTANT NUMBER(10) := 1;
RAW_DATA_STATUS_RETRY			CONSTANT NUMBER(10) := 2;
RAW_DATA_STATUS_PROCESSING		CONSTANT NUMBER(10) := 3;
RAW_DATA_STATUS_HAS_ERRORS		CONSTANT NUMBER(10) := 4;
RAW_DATA_STATUS_SUCCESS			CONSTANT NUMBER(10) := 5;
RAW_DATA_STATUS_PRE_ERRORS		CONSTANT NUMBER(10) := 6;
RAW_DATA_STATUS_PRE_PENDING		CONSTANT NUMBER(10) := 7;
RAW_DATA_STATUS_REVERTING		CONSTANT NUMBER(10) := 8;
RAW_DATA_STATUS_REVERTED		CONSTANT NUMBER(10) := 9;
RAW_DATA_STATUS_QUEUED_EXT		CONSTANT NUMBER(10) := 10;	-- Queued for external processing
RAW_DATA_STATUS_MERGE_EXT		CONSTANT NUMBER(10) := 11;	-- Merging external processing results

ISO_DATE_TIME_FORMAT			CONSTANT VARCHAR2(35) := 'YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM';

FUNCTION EmptySerialIds
RETURN security_pkg.T_VARCHAR2_ARRAY;

FUNCTION ConsumptionDataToTable(
	in_start			IN	T_DATE_ARRAY,
	in_end				IN	T_DATE_ARRAY,
	in_consumption		IN	T_VAL_ARRAY
) RETURN T_CONSUMPTION_TABLE;

FUNCTION UNSEC_ConvertMeterValue(
	in_val					IN	meter_live_data.consumption%TYPE,
	in_meter_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_data_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_date					IN	DATE
) RETURN meter_live_data.consumption%TYPE;

FUNCTION GetIssueUserFromSource(
	in_raw_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION GetIssueUserFromRaw(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION GetIssueUserFromRegion(
	in_region_sid			security_pkg.T_SID_ID,
	in_data_dtm				DATE
) RETURN security_pkg.T_SID_ID;

-- DEFAULT HELPER TO MATCH SERIAL NUMBERS TO REGION SIDS
PROCEDURE HELPER_MatchSerialNumber(
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	out_region_sid			OUT	security_pkg.T_SID_ID
);

-- CALLER CAN USE THIS TO EXECUTE THE CORRECT HELPER FOR THE GIVEN RAW DATA ID
PROCEDURE MatchSerialNumber(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	out_region_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE MatchSerialNumber(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	out_match				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearInsertData
;

PROCEDURE PrepareInsertData(
	in_start_dtm					IN	TIMESTAMP WITH TIME ZONE,
	in_end_dtm						IN	TIMESTAMP WITH TIME ZONE,
	in_consumption					IN	meter_live_data.consumption%TYPE,
	in_note							IN	meter_insert_data.note%TYPE,
	in_meter_input_lookup_key		IN  meter_input.lookup_key%TYPE,
	in_source_row					IN	meter_insert_data.source_row%TYPE DEFAULT NULL,
	in_statement_id					IN	meter_source_data.statement_id%TYPE DEFAULT NULL
);

PROCEDURE PrepareInsertData(
	in_start_dtm					IN	TIMESTAMP WITH TIME ZONE,
	in_end_dtm						IN	TIMESTAMP WITH TIME ZONE,
	in_consumption					IN	meter_live_data.consumption%TYPE,
	in_note							IN	meter_insert_data.note%TYPE,
	in_meter_input_id				IN  meter_input.meter_input_id%TYPE,
	in_source_row					IN	meter_insert_data.source_row%TYPE,
	in_priority						IN  meter_insert_data.priority%TYPE,
	in_statement_id					IN	meter_source_data.statement_id%TYPE DEFAULT NULL
);

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_file_name			IN	meter_raw_data.file_name%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	in_imp_instance_id		IN 	NUMBER,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_message_uid			IN	meter_raw_data.message_uid%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_file_name			IN	meter_raw_data.file_name%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE InsertRawData(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_mime_type			IN	meter_raw_data.mime_type%TYPE,
	in_encoding_name		IN	meter_raw_data.encoding_name%TYPE,
	in_message_uid			IN	meter_raw_data.message_uid%TYPE,
	in_file_name			IN	meter_raw_data.file_name%TYPE,
	in_data					IN	meter_raw_data.data%TYPE,
	in_status_id			IN  meter_raw_data.status_id%TYPE DEFAULT RAW_DATA_STATUS_NEW,
	out_raw_data_id			OUT	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE SetRawDataDateRange(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_start_dtm			IN	meter_raw_data.start_dtm%TYPE,
	in_end_dtm				IN	meter_raw_data.end_dtm%TYPE
);

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
);

PROCEDURE InsertLiveData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_uom					IN	meter_orphan_data.uom%TYPE,
	in_is_estimate			IN  NUMBER,
	in_raise_issues			IN	NUMBER DEFAULT 1
);

PROCEDURE ComputePeriodicDataFromRaw(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_raw_dtm			IN	TIMESTAMP WITH TIME ZONE,
	in_max_raw_dtm			IN	TIMESTAMP WITH TIME ZONE,
	in_raw_data_id			IN	meter_orphan_data.meter_raw_data_id%TYPE
);


PROCEDURE ComputePeriodicData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_dtm				IN	DATE,
	in_max_dtm				IN	DATE,
	in_raw_data_id			IN	meter_orphan_data.meter_raw_data_id%TYPE
);

PROCEDURE ProcessHelperInputs(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_dtm				IN	DATE,
	in_max_dtm				IN	DATE
);

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
);

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
);

PROCEDURE CreateMatchJobsForApps;

PROCEDURE QueueMatchBatchJob(
	in_meter_raw_data_id	IN	meter_match_batch_job.meter_raw_data_id%TYPE DEFAULT NULL,
	out_batch_job_id		OUT	meter_match_batch_job.batch_job_id%TYPE
);

PROCEDURE GetMatchBatchJob(
	in_batch_job_id			IN	meter_match_batch_job.batch_job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAppsToMatch(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE QueueRawDataImportJob(
	in_import_class_sid		IN	NUMBER,
	in_import_instance_id	IN	NUMBER,
	in_step_number			IN	NUMBER
);

PROCEDURE CreateRawDataJobsForApps;

PROCEDURE GetRawDataImportJob(
	in_batch_job_id			IN	meter_raw_data_import_job.batch_job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindMeterConversion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_uom					IN	meter_orphan_data.uom%TYPE,
	out_meter_conversion_id	OUT	measure_conversion.measure_conversion_id%TYPE,
	out_data_conversion_id	OUT	measure_conversion.measure_conversion_id%TYPE
);

PROCEDURE MatchOrphanData(
	in_raw_data_id			IN	meter_orphan_data.meter_raw_data_id%TYPE DEFAULT NULL,
	in_serial_ids			IN	security_pkg.T_VARCHAR2_ARRAY DEFAULT EmptySerialIds
);

PROCEDURE GetAppsToProcess (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_MarkRawDataQueuedExt(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE UNSEC_MarkRawDataMergeExt(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE GetRawDataJob(
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_wait					IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQueuedRawDataIds (
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE	DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AbortRawDataProcessing (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE AbortRawDataProcessing (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_error_dtms			IN	T_DATE_ARRAY
);

PROCEDURE LogRawDataErrors (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_error_dtms			IN	T_DATE_ARRAY
);

PROCEDURE LogRawDataErrors (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_region_sids	IN	security_pkg.T_SID_IDS,
	in_error_messages		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_error_dtms			IN	T_DATE_ARRAY
);

PROCEDURE LogRawDataError (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_error_message		IN	meter_raw_data_error.message%TYPE,
	in_error_dtm			IN	meter_raw_data_error.data_dtm%TYPE,
	out_error_id			OUT	meter_raw_data_error.error_id%TYPE
);

PROCEDURE LogRawDataError (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_error_message		IN	meter_raw_data_error.message%TYPE,
	in_error_dtm			IN	meter_raw_data_error.data_dtm%TYPE,
	out_error_id			OUT	meter_raw_data_error.error_id%TYPE
);

PROCEDURE CompleteRawDataProcessing (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE	DEFAULT NULL
);

PROCEDURE GetDurations(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLinkedMeters(
	in_region_sid  		IN  security_pkg.T_SID_ID,
	out_cur 			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_duration_id			IN	meter_bucket.meter_bucket_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_input_id				IN	meter_input.meter_input_id%TYPE,
	in_aggregator			IN	meter_aggregator.aggregator%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_duration_id			IN	meter_bucket.meter_bucket_id%TYPE,
	in_min_dtm				IN	meter_live_data.start_dtm%TYPE,
	in_max_dtm				IN	meter_live_data.start_dtm%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFinestDurationId(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_duration_id			OUT	meter_bucket.meter_bucket_id%TYPE
);

PROCEDURE GetSmallestBucket(
	in_high_resolution		NUMBER,
	out_duration_id			OUT	meter_bucket.meter_bucket_id%TYPE
);

PROCEDURE GetBestDurationId (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_max_points			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLastMeterDataDtm (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLastMeterDataDtm (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_duration_id			IN	meter_bucket.meter_bucket_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOrphanData (
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	in_data_limit			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddIssue (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_label				IN  issue.label%TYPE,
	in_issue_dtm			IN	issue_meter.issue_dtm%TYPE,
	out_issue_id			OUT issue.issue_id%TYPE
);


PROCEDURE GetIssue(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDataSources(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateDataSourceOrphanCount(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE
);

PROCEDURE GetDataSourceById(
	in_data_source_id				IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_high_res_inputs_cur			OUT SYS_REFCURSOR,
	out_meter_type_mappings_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetDataSourceExcelOption(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_option				OUT	security_pkg.T_OUTPUT_CUR,
	out_mapping				OUT	security_pkg.T_OUTPUT_CUR
);

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
);

PROCEDURE SaveExcelOption(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_worksheet_index		IN	meter_excel_option.worksheet_index%TYPE,
	in_row_index			IN	meter_excel_option.row_index%TYPE,
	in_csv_delimiter		IN	meter_excel_option.csv_delimiter%TYPE,
	in_field_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_column_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_column_indexes		IN	security_pkg.T_SID_IDS,
	in_create_meter_types	IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SaveDataSourceXml(
	in_data_source_id			IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_data_type				IN	auto_imp_importer_settings.data_type%TYPE,
	in_excel_worksheet_index	IN	auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_excel_row_index			IN	auto_imp_importer_settings.excel_row_index%TYPE,
	in_xml						IN 	auto_imp_importer_settings.mapping_xml%TYPE
);

PROCEDURE GetDataSourceXmlOption(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_cur					OUT	SECURITY_PKG.T_OUTPUT_CUR
);

PROCEDURE DeleteDataSource(
	in_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE
);

PROCEDURE GetRawDataList(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRawDataList(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_orphan_serial_id		IN	meter_orphan_data.serial_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRawDataListForProperty(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateRawDataOrphanCount (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE GetRawDataInfo (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_info				OUT	security_pkg.T_OUTPUT_CUR,
	out_errors				OUT	security_pkg.T_OUTPUT_CUR,
	out_pipeline_info		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRawDataFile (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOriginalRawDataFile (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOrphanMeterList(
	in_text					IN	VARCHAR2,
	in_start_row	    	IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChartMeterExtraInfo(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChartMeterExtraInfo(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_input_id			IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserPatchLevels(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddRawDataSourceIssue(
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE,
	in_label				IN	issue.label%TYPE,
	in_description			IN	issue.description%TYPE,
	out_issue_id			OUT	issue.issue_id%TYPE
);

PROCEDURE AddRawDataIssue (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_label				IN  issue.label%TYPE,
	in_start_dtm			IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	in_end_dtm				IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	out_issue_id			OUT issue.issue_id%TYPE
);

PROCEDURE AddUniqueRawDataIssue (
	in_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_label				IN  issue.label%TYPE,
	in_description			IN	issue.description%TYPE,
	in_start_dtm			IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	in_end_dtm				IN	TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	out_issue_id			OUT issue.issue_id%TYPE
);

PROCEDURE GetRawDataIssue(
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);


FUNCTION GetDataSourceUrl(
	in_raw_data_source_id		IN	issue_meter_data_source.issue_meter_data_source_id%TYPE
) RETURN VARCHAR2;

FUNCTION GetRawDataUrl(
	in_issue_meter_raw_data_id	IN	issue_meter_raw_data.issue_meter_raw_data_id%TYPE
) RETURN VARCHAR2;

PROCEDURE LogExportSystemValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE DEFAULT NULL,
	in_end_dtm				IN	DATE DEFAULT NULL
);

PROCEDURE BatchExportSystemValues
;

PROCEDURE ExportSystemValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE DEFAULT NULL,
	in_end_dtm				IN	DATE DEFAULT NULL
);

PROCEDURE GetProcessedFileNames (
	in_raw_data_source_id		IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MissingDataReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateMeterMissingDataIssue(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN  date,
	in_end_dtm				IN	date,
	in_label				IN  issue.label%TYPE
	--out_issue_id			OUT issue.issue_id%TYPE
);

PROCEDURE GetMissingDataIssue(
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetMissingDataUrl(
	in_issue_meter_missing_data_id	IN	issue_meter_missing_data.issue_meter_missing_data_id%TYPE
) RETURN VARCHAR2;

PROCEDURE GetMeterMissingDataInfo(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterMissingDataInfo(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMetersWithMissingData(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMetersWithMissingData(
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAppsToProcessMissingData (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMetersMissingDataDetails (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE MissingDataCheckNewValues
;

PROCEDURE GetWidestBucketBounds(
	in_dtm				IN	DATE,
	in_hi_res			IN	NUMBER,
	out_min_dtm			OUT	DATE,
	out_max_dtm			OUT DATE
);

FUNCTION GetMinBucketBound(
	in_dtm			IN	DATE,
	in_hi_res		IN	NUMBER
) RETURN DATE;

FUNCTION GetMaxBucketBound(
	in_dtm			IN	DATE,
	in_hi_res		IN	NUMBER
) RETURN DATE;

PROCEDURE UpdateLatestFileData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_file_name					IN	meter_raw_data.file_name%TYPE,
	in_mime_type					IN	meter_raw_data.mime_type%TYPE,
	in_new_data						IN	meter_raw_data.data%TYPE
);

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_file_name					IN	meter_raw_data.file_name%TYPE,
	in_mime_type					IN	meter_raw_data.mime_type%TYPE,
	in_new_data						IN	meter_raw_data.data%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResubmitOriginalRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ScheduleRawDataImportRevert(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ProcessRawDataImportRevert(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
);

PROCEDURE SubmitRawDataFromCache(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_cache_key					IN	aspen2.filecache.cache_key%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AuditRawDataChange(
	in_meter_raw_data_id		IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_text						IN	meter_raw_data_log.log_text%TYPE
);

PROCEDURE AuditRawDataChange(
	in_meter_raw_data_id		IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_text						IN	meter_raw_data_log.log_text%TYPE,
	in_mime_type				IN	meter_raw_data_log.mime_type%TYPE,
	in_file_name				IN	meter_raw_data_log.file_name%TYPE,
	in_data						IN	meter_raw_data_log.data%TYPE
);

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
);


PROCEDURE AddRecomputeBucketsJob(
	in_raw_data_source_id			IN	meter_raw_data_source.raw_data_source_id%TYPE,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE ProcessRecomputeBucketsJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
);

END meter_monitor_pkg;
/
