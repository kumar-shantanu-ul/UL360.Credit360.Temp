CREATE OR REPLACE PACKAGE CSR.meter_duff_region_pkg IS

DUFF_METER_GENERIC				CONSTANT NUMBER(10) :=  1; -- in use
DUFF_METER_MATCH_SERIAL			CONSTANT NUMBER(10) :=  2; -- in use
DUFF_METER_MATCH_UOM			CONSTANT NUMBER(10) :=  3; -- in use
DUFF_METER_OVERLAP				CONSTANT NUMBER(10) :=  4; -- in use
DUFF_METER_EXISTING_MISMATCH	CONSTANT NUMBER(10) :=  5; -- in use
DUFF_METER_PARENT_NOT_FOUND		CONSTANT NUMBER(10) :=  6;
DUFF_METER_HOLDING_NOT_FOUND	CONSTANT NUMBER(10) :=  7; -- in use
DUFF_METER_SVC_TYPE_NOT_FOUND	CONSTANT NUMBER(10) :=  8; -- in use
DUFF_METER_SVC_TYPE_MISMATCH	CONSTANT NUMBER(10) :=  9; -- in use
DUFF_METER_NOT_SET_UP			CONSTANT NUMBER(10) := 10;

PROCEDURE SaveMarkedDuffRegions
;

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
);

PROCEDURE ClearDuffRegion(
	in_urjanet_meter_id 				IN	duff_meter_region.urjanet_meter_id%TYPE
);

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
);

PROCEDURE RetryDuffRegions(
	in_wait_for_locks					IN	NUMBER,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDuffMeterRegionList(
	in_text					IN	VARCHAR2,
	in_start_row			IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOverlapsWithLiveData(
	in_serial_id			meter_orphan_data.serial_id%TYPE,
	in_start_row			IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOverlapsWithSelf(
	in_serial_id			meter_orphan_data.serial_id%TYPE,
	in_start_row			IN	NUMBER,
	in_row_limit			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteOrphanData(
	in_serial_id			IN	meter_orphan_data.serial_id%TYPE,
	in_meter_input_id		IN	meter_orphan_data.meter_input_id%TYPE,
	in_priority				IN	meter_orphan_data.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

PROCEDURE DeleteDuffRegionsAndOrphanData(
	in_meter_raw_data_id	IN	meter_raw_data.meter_raw_data_id%TYPE
);

END meter_duff_region_pkg;
/
