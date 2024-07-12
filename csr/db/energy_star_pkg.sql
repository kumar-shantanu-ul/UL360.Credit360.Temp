CREATE OR REPLACE PACKAGE CSR.energy_star_pkg IS

ERR_GENERIC_BUILDING	CONSTANT NUMBER := 1000;
ERR_GENERIC_SPACE		CONSTANT NUMBER := 2000;
ERR_GENERIC_METER		CONSTANT NUMBER := 3000;

SUBQUERY_CARDINALITY EXCEPTION;
ERR_SUBQUERY_CARDINALITY	CONSTANT NUMBER := -01427;
PRAGMA EXCEPTION_INIT(SUBQUERY_CARDINALITY, -01427);

TYPE T_DATE_ARRAY IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE T_VAL_ARRAY IS TABLE OF NUMBER(24, 10) INDEX BY PLS_INTEGER;

FUNCTION AttrsToTable(
	in_names					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals						IN	T_VAL_ARRAY,
	in_strs						IN	security_pkg.T_VARCHAR2_ARRAY
) RETURN T_EST_ATTR_TABLE;

FUNCTION AttrsToTable(
	in_names					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals						IN	T_VAL_ARRAY,
	in_strs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_dtms						IN	T_DATE_ARRAY,
	in_uoms						IN	security_pkg.T_VARCHAR2_ARRAY
) RETURN T_EST_ATTR_TABLE;

FUNCTION AttrsToTable(
	in_ids						IN	security_pkg.T_SID_IDS,
	in_region_metric_ids		IN	security_pkg.T_SID_IDS,
	in_names					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals						IN	T_VAL_ARRAY,
	in_strs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_dtms						IN	T_DATE_ARRAY,
	in_uoms						IN	security_pkg.T_VARCHAR2_ARRAY
) RETURN T_EST_ATTR_TABLE;

-- PROCEDURE UNSEC_AddAccount(
	-- in_user_name				IN	est_account_global.user_name%TYPE,
	-- in_base_url					IN	est_account_global.base_url%TYPE DEFAULT 'https://portfoliomanager.energystar.gov/ws/',
	-- out_account_id				OUT	est_account_global.est_account_id%TYPE
-- );

PROCEDURE GetOptions(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetOptions(
	in_default_account_sid		IN	est_options.default_account_sid%TYPE,
	in_default_customer_id		IN	est_options.default_customer_id%TYPE,
	in_auto_create_prop_type	IN	est_options.auto_create_prop_type%TYPE,
	in_auto_create_space_type	IN	est_options.auto_create_space_type%TYPE,
	in_show_compat_icons		IN	est_options.show_compat_icons%TYPE,
	in_trash_when_sharing		IN	est_options.trash_when_sharing%TYPE,
	in_trash_when_polling		IN	est_options.trash_when_polling%TYPE
);

-- Map an account to the logged on app
PROCEDURE MapAccount(
	in_account_id				IN	est_account_global.est_account_id%TYPE,
	out_account_Sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE GetAccounts(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccount(
	in_account_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomer(
	in_account_sid				IN	security_pkg.T_SID_ID,	
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- Get the customers associated with this app/account
PROCEDURE GetCustomers(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetAllCustomers(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_GetUnmappedCustomers(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_SetCustomer(
	in_pm_customer_id			IN	est_customer_global.pm_customer_id%TYPE,
	in_org_name					IN	est_customer_global.org_name%TYPE,
	in_email					IN	est_customer_global.email%TYPE
);

PROCEDURE SetCustomer(
	in_pm_customer_id			IN	est_customer_global.pm_customer_id%TYPE,
	in_org_name					IN	est_customer_global.org_name%TYPE,
	in_email					IN	est_customer_global.email%TYPE
);

PROCEDURE MapCustomer(
	in_account_sid				IN	security_pkg.T_SID_ID,	
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	out_customer_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE UnmapCustomer(
	in_account_sid				IN	security_pkg.T_SID_ID,	
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	out_customer_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE GetBuilding (
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBuildingMetrics(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBuildingAndMetrics (
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_building				OUT	security_pkg.T_OUTPUT_CUR,
    out_metrics					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetBuilding(
    in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_source_pm_customer_id	IN	est_building.source_pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_building_name			IN	est_building.building_name%TYPE,
    in_address					IN	est_building.address%TYPE,
    in_address2					IN	est_building.address2%TYPE,
    in_city						IN	est_building.city%TYPE,
    in_state					IN	est_building.state%TYPE,
    in_zip_code					IN	est_building.zip_code%TYPE,
    in_country					IN	est_building.country%TYPE,
    in_year_built				IN	est_building.year_built%TYPE,
    in_primary_function			IN	est_building.primary_function%TYPE,
    in_construction_status		IN	est_building.construction_status%TYPE,
    in_notes					IN	est_building.notes%TYPE,
    in_write_access				IN	est_building.write_access%TYPE,
    -- Federap property
    in_is_federal_property		IN	est_building.is_federal_property%TYPE,
    in_federal_owner			IN	est_building.federal_owner%TYPE,
    in_federal_agency			IN	est_building.federal_agency%TYPE,
    in_federal_agency_region	IN	est_building.federal_agency_region%TYPE,
    in_federal_campus			IN	est_building.federal_campus%TYPE,
	-- Building metrics
	in_metric_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_vals				IN	T_VAL_ARRAY,
	in_metric_strs				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_end_dtms			IN	T_DATE_ARRAY,
	in_metric_uoms				IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetBuildingMetrics(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_metric_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_vals				IN	T_VAL_ARRAY,
	in_metric_strs				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_end_dtms			IN	T_DATE_ARRAY,
	in_metric_uoms				IN	security_pkg.T_VARCHAR2_ARRAY
);

-- Output region sid, null if not mapped or can not be mapped
-- Does not create a region, the building level region must laready exist to be mapped
PROCEDURE MapBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceAttrs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceAndAttrs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_space					OUT	security_pkg.T_OUTPUT_CUR,
    out_attrs					OUT	security_pkg.T_OUTPUT_CUR
);

-- Set/create space information in energy star schema
PROCEDURE SetSpace(
    in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_space_name				IN	est_space.space_name%TYPE,
    in_space_type				IN	est_space.space_type%TYPE,
    -- Space attributes
    in_attr_ids					IN	security_pkg.T_SID_IDS,
    in_region_metric_ids		IN	security_pkg.T_SID_IDS,
    in_attr_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_attr_vals				IN	T_VAL_ARRAY,
	in_attr_strs				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_attr_dtms				IN	T_DATE_ARRAY,
	in_attr_uoms				IN	security_pkg.T_VARCHAR2_ARRAY
);

-- This creates spaces and returns the region sid for the new space unless the space 
-- is already mapped to a region sid in which case it returns that region sid
PROCEDURE MapSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterAndSiblings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_meter					OUT	security_pkg.T_OUTPUT_CUR,
    out_siblings				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterSiblings(
	in_region_sid				IN	security_pkg.T_SID_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterSiblings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- Set/create energy meter information in energy star schema
PROCEDURE SetMeter(
    in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_source_pm_customer_id	IN	est_building.source_pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    in_pm_space_id				IN	est_meter.pm_space_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_meter_name				IN	est_meter.meter_name%TYPE,
    in_meter_type				IN	est_meter.meter_type%TYPE,
    in_uom						IN	est_meter.uom%TYPE,
    in_active					IN	est_meter.active%TYPE,
    in_inactive_dtm				IN	est_meter.inactive_dtm%TYPE,
    in_add_to_total				IN	est_meter.add_to_total%TYPE,
    in_first_bill_dtm			IN	est_meter.first_bill_dtm%TYPE,
    in_last_entry_date			IN	est_meter.last_entry_date%TYPE,
    in_write_access				IN	est_meter.write_access%TYPE,
    in_other_desc				IN	est_meter.other_desc%TYPE
);

-- Try to create a meter and return the region sid, the meter 
-- type to indicator mapping must be valid for this to succeed
PROCEDURE MapMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    in_pm_space_id				IN	est_meter.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateMeterReadings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
	in_pm_ids					IN	security_pkg.T_SID_IDS,
	in_start_dates				IN	T_DATE_ARRAY,
	in_end_dates				IN	T_DATE_ARRAY,
	in_consumptions				IN	T_VAL_ARRAY,
	in_costs					IN	T_VAL_ARRAY,
	in_estimates				IN	security_pkg.T_SID_IDS
);

PROCEDURE OnDeleteRegion(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/*
PROCEDURE GetBuildingsForDetailPoll(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_poll_interval_hrs		IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMetersForReadingPoll(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_poll_interval_hrs		IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);
*/

/**
 *	Gets a paged list of building mappings.
 *
 *	@param in_include_mapped		If zero causes buildings that have not been mapped to a region to be 
 *									excluded from the results.
 *	@param in_include_ignored		If zero causes buildings that have been marked as ignored to be 
 *									excluded from the results.
 *	@param in_first					The one-based index of the first row to return.
 *	@param in_count					The maximum number of rows to return.
 *	@param out_total				The total number of rows available.
 */
PROCEDURE GetBuildingMappings(
	in_include_mapped				IN	NUMBER DEFAULT 1,
	in_include_ignored				IN	NUMBER DEFAULT 1,
	in_first						IN	NUMBER DEFAULT 1,
	in_count						IN	NUMBER DEFAULT NULL,
	out_total						OUT NUMBER,
    out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBuildingMappingReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterErrorsReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBuildingsNoMetersReport(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DisposeBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
);

PROCEDURE FlagMissingBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
);

PROCEDURE FlagIgnoredBuilding(
	in_est_account_sid				IN	security_pkg.T_SID_ID,
    in_pm_customer_id				IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id				IN	est_building.pm_building_id%TYPE,
	in_ignore						IN	NUMBER DEFAULT 1
);

PROCEDURE TrashDeadChildObjects(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_live_space_pmids			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_live_meter_pmids			IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE TrashOrphanObjects(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
);

PROCEDURE GetBuildingRatingReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MapNewBrSpaces(
	in_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE
);

PROCEDURE GetMetricsToRequest(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	in_read_only			IN	est_building_metric_mapping.read_only%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UnmapMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE
);

PROCEDURE UnmapSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE
);

PROCEDURE UnmapBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
);

PROCEDURE MappingHelper (
	in_est_account_sid		security_pkg.T_SID_ID,
	in_region_sid			security_pkg.T_SID_ID,
	in_pm_building_id		est_building.pm_building_id%TYPE,
	in_trash_orphans		NUMBER DEFAULT 1
);

PROCEDURE CreateOutstandingReqJob(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOutstandingReqJob(
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterReadings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterReadings(
    in_region_sid				IN	security_pkg.T_SID_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdatePmReadingIds(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
	in_reading_ids				IN	security_pkg.T_SID_IDS,
	in_pm_ids					IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE
);

PROCEDURE DeleteSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_space_id				IN	est_space.pm_space_id%TYPE
);

PROCEDURE DeleteMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE
);

PROCEDURE AddError(
	in_app_sid					IN	security_pkg.T_SID_ID			DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_region_sid				IN	security_pkg.T_SID_ID			DEFAULT NULL,
	in_est_account_sid			IN	security_pkg.T_SID_ID			DEFAULT NULL,
	in_pm_customer_id			IN	est_error.pm_customer_id%TYPE	DEFAULT NULL,
	in_pm_building_id			IN	est_error.pm_building_id%TYPE	DEFAULT NULL,
	in_pm_space_id				IN	est_error.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_error.pm_meter_id%TYPE		DEFAULT NULL,
	in_error_level				IN	est_error.error_level%TYPE		DEFAULT 0,
	in_error_code				IN	est_error.error_code%TYPE,
	in_error_message			IN	est_error.error_message%TYPE,
	in_request_url				IN	est_error.request_url%TYPE		DEFAULT NULL,
	in_request_header			IN	est_error.request_header%TYPE	DEFAULT NULL,
	in_request_body				IN	est_error.request_body%TYPE		DEFAULT NULL,
	in_response					IN	est_error.response%TYPE			DEFAULT NULL
);

PROCEDURE GetDbTimestamp(
	-- We don't have a RunSP/RunSF return date
	out_cur						OUT security_pkg.T_OUTPUT_CUR 
);

PROCEDURE MarkErrorsInactive(
	in_before_dtm				IN	DATE,
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_error.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_error.pm_building_id%TYPE,
	in_pm_space_id				IN	est_error.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_error.pm_meter_id%TYPE		DEFAULT NULL
);

PROCEDURE MarkErrorsInactive(
	in_before_dtm				IN	DATE,
	in_region_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE MarkErrorInactive(
	in_error_id					IN	est_error.est_error_id%TYPE,
	in_property_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE PurgeInactiveErrors
;

PROCEDURE GetError (
	in_est_error_id				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetErrorsForProperty (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetErrorsForProperty (
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_include_inactive			IN	NUMBER	DEFAULT 0,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetErrsForPropertyAndChildren (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetErrsForPropertyAndChildren (
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPropertySettings (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPropertySettingsAndErrors (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_settings				OUT	security_pkg.T_OUTPUT_CUR,
	out_errors					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllErrors (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AssocSpaceTypeRgnMetrics(
	in_space_type_id			IN	space_type.space_type_id%TYPE,
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE
);

PROCEDURE CreateAndAssocSpaceType(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_space_type_id			OUT	space_type.space_type_id%TYPE
);

PROCEDURE GetUnmappedCustomers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMappedCustomers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceTypeMappings (
	out_space_type_mappings		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveSpaceTypeMappings (
	in_es_space_type_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_space_type_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetESSpaceTypes(
	out_space_types				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPropertyTypeMappings (
	out_prop_type_mappings		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePropertyTypeMappings (
	in_es_prop_type_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_prop_type_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetESPropertyTypes(
	out_prop_types				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEnergyStarErrors (
	in_start_row				IN	NUMBER,
	in_limit					IN	NUMBER,
	in_search_term				IN	VARCHAR2,
	out_cur_total				OUT	SYS_REFCURSOR,
	out_cur_props				OUT	SYS_REFCURSOR,
	out_cur_props_errors		OUT	SYS_REFCURSOR
);

-- Test interface for INTERNAL_PrepConsumptionData
PROCEDURE Test_PrepConsumptionData(
	in_pm_ids					IN	security_pkg.T_SID_IDS,
	in_start_dates				IN	T_DATE_ARRAY,
	in_end_dates				IN	T_DATE_ARRAY,
	in_consumptions				IN	T_VAL_ARRAY,
	in_costs					IN	T_VAL_ARRAY,
	in_estimates				IN	security_pkg.T_SID_IDS,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ignore_lock				IN	BOOLEAN DEFAULT FALSE
);

END;
/

