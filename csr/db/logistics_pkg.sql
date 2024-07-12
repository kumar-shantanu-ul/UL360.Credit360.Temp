CREATE OR REPLACE PACKAGE CSR.Logistics_Pkg AS

PROCEDURE GetHttpRequest(
	in_url		IN	http_request_cache.url%TYPE,
	in_hash		IN	http_request_cache.request_hash%TYPE,
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE SetHttpRequest(
	in_url			IN	http_request_cache.url%TYPE,
	in_hash			IN	http_request_cache.request_hash%TYPE,
	in_response		IN	http_request_cache.response%TYPE,
	in_mime_type	IN	http_request_cache.mime_type%TYPE
);

FUNCTION GetCustomLocationHash(
	in_s		VARCHAR2
) RETURN RAW;
--PRAGMA RESTRICT_REFERENCES(GetCustomLocationHash, WNDS);

PROCEDURE GetTables(
	in_permission_set	IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_WRITE,
	out_cur				OUT	SYS_REFCURSOR
);

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
);

PROCEDURE MarkTableAsDirty(
	in_table_name		IN	VARCHAR2
);

PROCEDURE MarkTableAsDirty(
	in_schema_name		IN	VARCHAR2,
	in_table_name		IN	VARCHAR2
);

PROCEDURE SortOriginDest(
	in_id1			IN	location.location_id%TYPE,
	in_id2			IN	location.location_id%TYPE,
	out_id1			OUT	location.location_id%TYPE,
	out_id2			OUT	location.location_id%TYPE
);

FUNCTION SQL_GetCountryCode(
	in_country			IN	VARCHAR2
) RETURN postcode.country.country%TYPE;

FUNCTION GetCountryCode(
	in_country			IN	VARCHAR2
) RETURN postcode.country.country%TYPE;

FUNCTION GCD(
	in_origin_lat 		IN	NUMBER,
	in_origin_lng 		IN	NUMBER,
	in_destination_lat 	IN	NUMBER,
	in_destination_lng 	IN	NUMBER
) RETURN NUMBER;

FUNCTION GCD(
	in_origin_country 			IN	VARCHAR2,
	in_destination_country 		IN	VARCHAR2
) RETURN NUMBER;

FUNCTION EstInternalDistance(
	in_country			IN	postcode.country.country%TYPE
) RETURN NUMBER;

PROCEDURE GetLocation(
	in_loc_type_id		IN	location.location_type_id%TYPE,
	in_hash				IN	custom_location.location_hash%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomLocationByAll(
	in_loc_type_id		IN	custom_location.location_type_id%TYPE,
	in_address			IN	custom_location.address%TYPE,
	in_city				IN	custom_location.city%TYPE,
	in_province			IN	custom_location.province%TYPE,
	in_postcode			IN	custom_location.postcode%TYPE,
	in_country			IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CreateCustomLocation(
	in_loc_type_id		IN	custom_location.location_type_id%TYPE,
	in_name				IN	custom_location.name%TYPE,
	in_is_approved		IN	custom_location.is_approved%TYPE
) RETURN location.location_id%TYPE;

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
);

PROCEDURE GetCustomLocations(
	in_trans_mode_id	IN	transport_mode.transport_mode_id%TYPE,
	in_start			IN	NUMBER,
	in_limit			IN	NUMBER,
	in_column			IN	VARCHAR2,
	in_dir				IN	VARCHAR2,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


-- XXX: this is in meters not Km
FUNCTION GetDistance(
	in_origin_hash			IN	custom_location.location_hash%TYPE,
	in_destination_hash		IN	custom_location.location_hash%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE
) RETURN NUMBER;

-- XXX: this is in meters not Km
FUNCTION GetDistance(
	in_origin_id				IN	location.location_id%TYPE,
	in_destination_id			IN	location.location_id%TYPE,
	in_transport_mode_id		IN	transport_mode.transport_mode_id%TYPE
) RETURN NUMBER;

PROCEDURE GetCustomDistances(
	in_transport_mode_id	IN	custom_distance.transport_mode_id%TYPE,
	in_start				IN	NUMBER,
	in_limit				IN	NUMBER,
	in_column				IN	VARCHAR2,
	in_dir					IN	VARCHAR2,
	out_total_rows			OUT	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDistance(
	in_transport_mode_id		IN	distance.transport_mode_id%TYPE,
	in_origin_id				IN	distance.origin_id%TYPE,
	in_destination_id			IN	distance.destination_id%TYPE,
	in_distance					IN	distance.distance%TYPE
);

FUNCTION SetCustomDistance(
	in_transport_mode_id	IN	custom_distance.transport_mode_id%TYPE,
	in_origin_id			IN	custom_location.custom_location_id%TYPE,
	in_destination_id		IN	custom_location.custom_location_id%TYPE,
	in_distance				IN	custom_distance.distance%TYPE
) RETURN NUMBER;

PROCEDURE DeleteCustomDistance(
	in_from_id				IN	custom_distance.origin_id%TYPE,
	in_to_id				IN	custom_distance.destination_id%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE
);

PROCEDURE EditCustomDistance(
	in_from_id				IN	custom_distance.origin_id%TYPE,
	in_to_id				IN	custom_distance.destination_id%TYPE,
	in_transport_mode_id	IN	transport_mode.transport_mode_id%TYPE,
	in_distance				IN	custom_distance.distance%TYPE
);

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
);

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
);

PROCEDURE ApproveLocation(
	in_location_id		IN	location.location_id%TYPE
);

PROCEDURE ApproveLocation(
	in_location_id		IN	location.location_id%TYPE,
	in_description		IN	location.description%TYPE,
	in_latitude			IN	location.latitude%TYPE,
	in_longitude		IN	location.longitude%TYPE
);

PROCEDURE ApproveCustomLocation(
	in_custom_location_id		IN	custom_location.custom_location_id%TYPE
);

PROCEDURE ApproveCustomLocation(
	in_custom_location_id		IN	custom_location.custom_location_id%TYPE,
	in_location_type			IN	location_type.name%TYPE,
	in_latitude					IN	location.latitude%TYPE,
	in_longitude				IN	location.longitude%TYPE
);

PROCEDURE ApproveCustomLocation(
	in_custom_location_id		IN	custom_location.custom_location_id%TYPE,
	in_airport_code				IN	location.name%TYPE
);

PROCEDURE ApproveAllCustomLocations;

FUNCTION IsAutoCreateLocation RETURN logistics_default.auto_create_custom_location%TYPE;

FUNCTION IsSortColumn RETURN logistics_default.sort_column%TYPE;

PROCEDURE AddErrorLog(
	in_tab_sid			IN	security_pkg.T_SID_ID,
	in_processor_class	IN	logistics_processor_class.label%TYPE,
	in_id				IN	logistics_error_log.id%TYPE,
	in_msg				IN	logistics_error_log.message%TYPE
);

PROCEDURE GetErrorLogs(
	in_loc_type_id		IN	location_type.location_type_id%TYPE,
	in_start			IN	NUMBER,
	in_limit			IN	NUMBER,
	in_column			IN	VARCHAR2,
	in_dir				IN	VARCHAR2,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveErrorLog(
	in_logistics_error_log_id	IN	logistics_error_log.logistics_error_log_id%TYPE,
	in_delete					IN	NUMBER
);

PROCEDURE RemoveAllErrorLogs(
	in_delete					IN	NUMBER
);

PROCEDURE ClearTabModesProcessing;

PROCEDURE MarkTabModeProcessed(	
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_processor_class		IN	logistics_processor_class.label%TYPE
);

PROCEDURE MarkTabModeFailed(	
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_processor_class		IN	logistics_processor_class.label%TYPE
);

PROCEDURE GetTabModesToProcess(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateImpSession(
	in_tab_sid			IN	security_pkg.T_SID_ID,
	in_processor_class		IN	logistics_processor_class.label%TYPE
);

PROCEDURE GetTransportModes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAirportList(
	in_filter			IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END;
/
