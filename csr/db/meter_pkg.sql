CREATE OR REPLACE PACKAGE CSR.meter_pkg IS

CURRENT_METERING_VERSION    CONSTANT NUMBER(10) := 2;

INVALID_DATE EXCEPTION;
ERR_INVALID_DATE	CONSTANT NUMBER := -20650;
PRAGMA EXCEPTION_INIT(INVALID_DATE, -20650);

ALREADY_APPROVED EXCEPTION;
ERR_ALREADY_APPROVED	CONSTANT NUMBER := -20651;
PRAGMA EXCEPTION_INIT(ALREADY_APPROVED, -20651);

RESET_NOT_ALLOWED EXCEPTION;
ERR_RESET_NOT_ALLOWED	CONSTANT NUMBER := -20652;
PRAGMA EXCEPTION_INIT(RESET_NOT_ALLOWED, -20652);

PARENT_PROPERTY_NOT_FOUND EXCEPTION;
ERR_PARENT_PROPERTY_NOT_FOUND	CONSTANT NUMBER := -20653;
PRAGMA EXCEPTION_INIT(PARENT_PROPERTY_NOT_FOUND, -20653);

SERVICE_TYPE_NOT_FOUND EXCEPTION;
ERR_SERVICE_TYPE_NOT_FOUND	CONSTANT NUMBER := -20654;
PRAGMA EXCEPTION_INIT(SERVICE_TYPE_NOT_FOUND, -20654);

METER_TYPE_NOT_CONFIGURED EXCEPTION;
ERR_METER_TYPE_NOT_CONFIGURED	CONSTANT NUMBER := -20655;
PRAGMA EXCEPTION_INIT(METER_TYPE_NOT_CONFIGURED, -20655);

METER_HEADER_SERIAL_NUMBER				CONSTANT NUMBER(10) := 1;
METER_HEADER_METER_TYPE					CONSTANT NUMBER(10) := 2;
METER_HEADER_METER_SOURCE				CONSTANT NUMBER(10) := 3;
METER_HEADER_PARENT_SPACE				CONSTANT NUMBER(10) := 4;
METER_HEADER_URJANET_METER_ID			CONSTANT NUMBER(10) := 5;
METER_HEADER_ADDRESS					CONSTANT NUMBER(10) := 6;
METER_HEADER_SUPPLIER					CONSTANT NUMBER(10) := 7;

METER_IND_ACTIVITY_TYPE_NA				CONSTANT NUMBER(10) := 1;
METER_IND_ACTIVITY_TYPE_GAS				CONSTANT NUMBER(10) := 2;
METER_IND_ACTIVITY_TYPE_ELEC			CONSTANT NUMBER(10) := 3;

FUNCTION INTERNAL_GetProperty(
    in_region_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(INTERNAL_GetProperty, WNDS, WNPS);

FUNCTION IsMeteringEnabled
RETURN NUMBER;

/**
 * Set the meter reading for a given meter / reading_id 
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid              The meter sid (region sid)
 * @param	 in_is_delete_reading_Id	If you are calculating for a row you're about to delete,
   										then this should be the reading_id for the row you're going 
   										to delete. If you're updating or have inserted, then it 
   										should be null
 * @param	 in_min_dtm					Start date (e.g. 1st Feb 2009)
 * @param 	 in_max_dtm					End date (e.g. 1st Apr 2009 to update Feb + Mar)
 */
PROCEDURE SetValTableForPeriod(
	in_meter_sid			IN	security_pkg.T_SID_ID,
	in_is_delete_reading_id	IN	security_pkg.T_SID_ID,
	in_min_dtm 				IN	DATE, 
	in_max_dtm 				IN	DATE
);

/* inserts or clears data in monthly chunks to make aggregation up regions easier */
PROCEDURE SetValTableForReading(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_meter_reading_id	IN	security_pkg.T_SID_ID,
	in_is_a_delete		IN  number
);

PROCEDURE RecalcValTableForLastReading(
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE RecalcValtableFromDtm (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_from_dtm			IN	DATE
);

/**
 * Set the meter reading for a given meter / reading_id 
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid               The meter sid (region sid)
 * @param    in_meter_reading_id        The meter reading id (null / 0 for new reading)
 * @param    in_reading_dtm             Date of reading
 * @param    in_val                     Meter value
 * @param    in_note                    Notes for reading
 * @param    in_user_sid                User sid of editor
 * @param    out_reading_id             The reading id of the reading just added
 *
 */

PROCEDURE SetMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_note                 in meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetMeterReading(
	in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE	DEFAULT NULL,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetMeterReading(
	in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE	DEFAULT NULL,
    in_is_estimate			IN meter_reading.val_number%TYPE	DEFAULT 0,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_note                 in meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_reading_dtm          IN meter_reading.start_dtm%TYPE,
    in_val                  IN meter_reading.val_number%TYPE,
    in_note                 in meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_reset_val			IN meter_reading.val_number%TYPE,
    in_is_estimate			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_val_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_cost_conv_id			IN measure_conversion.measure_conversion_id%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_is_estimate			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetArbitraryPeriod(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
	in_entry_dtm			IN DATE DEFAULT SYSDATE,
    in_start_dtm          	IN meter_reading.start_dtm%TYPE,
    in_end_dtm          	IN meter_reading.end_dtm%TYPE,
    in_val            		IN meter_reading.val_number%TYPE,
    in_note                 IN meter_reading.note%TYPE,
    in_reference			IN meter_reading.reference%TYPE,
    in_cost					IN meter_reading.cost%TYPE,
    in_doc_id				IN meter_document.meter_document_id%TYPE,
    in_cache_key			IN aspen2.filecache.cache_key%TYPE,
    in_is_estimate			IN meter_reading.val_number%TYPE,
    out_reading_id          OUT meter_reading.meter_reading_id%TYPE
);
	
/**
 * Get a meter reading 
 *
 * @param    in_meter_sid				The meter sid 
 * @param    in_meter_reading_id        The meter reading id 
 */
PROCEDURE GetMeterReading(
    in_meter_sid	        IN security_pkg.T_SID_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE,
    out_cur                 OUT SYS_REFCURSOR
);

/**
 * Delete a meter reading 
 *
 * @param    in_act_id                  Access token
 * @param    in_meter_reading_id        The meter reading id 
 */
PROCEDURE DeleteMeterReading(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_meter_reading_id     IN meter_reading.meter_reading_id%TYPE
);


/**
 * Get list of meter readings 
 *
 * @param    in_act_id                  Access token
 * @param    in_region_sid               The meter sid (region sid)
 * @param    out_cur                    The note details
 * @param    in_start_row               Start row
 * @param    in_end_row                 End row 
 *
 * The output rowset is of the form:
 *  meter_reading_id, reading_dtm, val_number, note entered_by_user_sid, entered_by_user_name, entered_dtm
 */
PROCEDURE GetMeterReadingList(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid            IN security_pkg.T_SID_ID,
    in_start_row            IN number,
    in_end_row              IN number,
    out_cur                 OUT SYS_REFCURSOR
);

PROCEDURE GetMeterAndRateReadings(
    in_meter_sid           IN security_pkg.T_SID_ID,
    in_start_dtm           IN meter_reading.start_dtm%TYPE,
    in_end_dtm             IN meter_reading.end_dtm%TYPE,
    out_cur                OUT SYS_REFCURSOR
);

PROCEDURE GetMeterReadingForExport(
    in_act_id               IN security_pkg.T_ACT_ID,
    in_region_sid            IN security_pkg.T_SID_ID,
    out_cur                 OUT SYS_REFCURSOR
);

PROCEDURE GetMeterListCache(
	in_region_sid 			IN  security_pkg.T_SID_ID,
	out_cur 				OUT SYS_REFCURSOR
);

PROCEDURE GetMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_meter					OUT	SYS_REFCURSOR,
	out_primary_conversions		OUT	SYS_REFCURSOR,
	out_cost_conversions		OUT	SYS_REFCURSOR,
	out_days_conversions		OUT	SYS_REFCURSOR,
	out_cost_days_conversions	OUT	SYS_REFCURSOR,
	out_contracts				OUT	SYS_REFCURSOR,
	out_meter_input_aggr_inds	OUT	SYS_REFCURSOR,
	out_tags_cur			 	OUT SYS_REFCURSOR,
	out_metric_values_cur	 	OUT SYS_REFCURSOR,
	out_photos_cur				OUT	SYS_REFCURSOR
);

FUNCTION IsMultiRateMeter (
	in_region_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetAndCheckRootRegionSids(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	region.region_sid%TYPE,
	out_user_sid					OUT	security_pkg.T_SID_ID,
	out_root_region_sids			OUT	security.T_SID_TABLE,
	out_num_root_region_sids		OUT	NUMBER
);

PROCEDURE UNSEC_GetContracts(
	in_meter_sids	IN	security_pkg.T_SID_IDS,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterList(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_filter						IN	VARCHAR2,
	in_root_region_sid				IN	security_pkg.T_SID_ID, -- if null, will find all meters that apply to this user
	in_show_hidden					IN	NUMBER,
    in_start_row					IN	NUMBER,
    in_end_row						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterAndRates(
	in_meter_sid			IN	security_pkg.T_SID_ID,
	out_meter_cur			OUT SYS_REFCURSOR,
	out_rates_cur			OUT SYS_REFCURSOR,
	out_child_meters_cur	OUT SYS_REFCURSOR,
	out_contracts_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetMetersAndRates(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_meters_cur					OUT SYS_REFCURSOR,
	out_rates_cur					OUT SYS_REFCURSOR
);

PROCEDURE UpdateMeterListCache(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetMeterTagsForExport (
	in_root_region_sids				IN	security.T_SID_TABLE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterListForExport(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags						OUT	SYS_REFCURSOR
);

PROCEDURE GetFullMeterListForExport(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags						OUT	SYS_REFCURSOR
);

PROCEDURE GetFullMeterListForExport(
	in_selected_region_sids			IN  security.T_SID_TABLE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE LegacyMakeMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_primary_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_cost_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL
);

PROCEDURE MakeMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL
);

PROCEDURE MakeMeter(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	out_needs_recompute			OUT	NUMBER
);

PROCEDURE EmptyTempMeterInputAggrInd;

PROCEDURE AddTempMeterInputAggrInd (
	in_region_sid				IN  temp_meter_input_aggr_ind.region_sid%TYPE,
	in_meter_input_id			IN  temp_meter_input_aggr_ind.meter_input_id%TYPE,
	in_aggregator				IN  temp_meter_input_aggr_ind.aggregator%TYPE,
	in_meter_type_id			IN  temp_meter_input_aggr_ind.meter_type_id%TYPE,
	in_measure_sid				IN  temp_meter_input_aggr_ind.measure_sid%TYPE,
	in_measure_conversion_id	IN  temp_meter_input_aggr_ind.measure_conversion_id%TYPE
);

PROCEDURE MakeRate (
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE ValidateIsMeter (
	in_region_sid		IN	security_pkg.T_SID_ID
);

FUNCTION ValidMeterType (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_region_type		IN	region.region_type%TYPE
) RETURN region.region_type%TYPE
;

PROCEDURE OnRegionMoved (
	in_region_sid		IN	security_pkg.T_SID_ID
);

FUNCTION IsMeterTypeRegion (
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
;

FUNCTION IsMeterType(
	in_region_type		IN	region.region_type%TYPE
) RETURN BOOLEAN
;

PROCEDURE PropogateMeterDetails (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE UpdateChildRateMeters (
	in_region_sid 		IN	security_pkg.T_SID_ID
);

PROCEDURE GetRates (
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE UnmakeMeter(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE UnmakeMeter(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_region_type		IN	region.region_type%TYPE
);

PROCEDURE GetMeterSourceType (
	in_source_type_id	IN	meter_source_type.meter_source_type_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterSourceTypes (
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterPriorities (
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetPeriodData (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterDocData (
	in_doc_id				IN	meter_document.meter_document_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UpdateMeterDocFromCache (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_doc_id				IN	meter_document.meter_document_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_id					OUT	meter_document.meter_document_id%TYPE
);

FUNCTION MissingReadingInPastMonths(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_months		IN	NUMBER
) RETURN NUMBER;

PROCEDURE INTERNAL_RecomputeValueData(
	in_region_sid			IN	security_pkg.T_SID_ID
);

/*
PROCEDURE MeterTypeChangeHelper
;
*/

FUNCTION GetIssueMeterUrl(
	in_issue_meter_id	IN	issue_meter.issue_meter_id%TYPE
) RETURN VARCHAR2;

PROCEDURE ApproveMeterState(
    in_flow_sid                 IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  csr.flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE IndicatorChanged(
	in_ind_sid					IN	security.security_pkg.T_SID_ID
);

PROCEDURE PrepMeterReadingImportRow(
	in_source_row					IN temp_meter_reading_rows.source_row%TYPE,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_start_dtm		 			IN meter_reading.start_dtm%TYPE,
	in_end_dtm						IN meter_reading.end_dtm%TYPE,
	in_meter_input_id				IN temp_meter_reading_rows.meter_input_id%TYPE,
	in_unit_of_measure				IN temp_meter_reading_rows.unit_of_measure%TYPE,
	in_val							IN meter_reading.val_number%TYPE,
	in_reference					IN meter_reading.reference%TYPE,
	in_note							IN meter_reading.note%TYPE,
	in_reset_val					IN meter_reading.val_number%TYPE DEFAULT NULL,
	in_priority						IN temp_meter_reading_rows.priority%TYPE DEFAULT NULL,
	in_statement_id					IN meter_source_data.statement_id%TYPE DEFAULT NULL
);

PROCEDURE ImportMeterReadingRows(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE PrepMeterImportRow(
    in_source_row			IN temp_meter_import_rows.source_row%TYPE,
    in_parent_sid         	IN temp_meter_import_rows.parent_sid%TYPE,
    in_meter_name          	IN temp_meter_import_rows.meter_name%TYPE,
    in_meter_ref         	IN temp_meter_import_rows.meter_ref%TYPE,
    in_cons_sid            	IN temp_meter_import_rows.consumption_sid%TYPE,
    in_cons_uom				IN temp_meter_import_rows.consumption_uom%TYPE,
    in_cost_sid				IN temp_meter_import_rows.cost_sid%TYPE,
    in_cost_uom				IN temp_meter_import_rows.cost_uom%TYPE
);

PROCEDURE ImportMeterRows(
	in_source_type_id		IN	all_meter.meter_source_type_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetCalcSubMeterAggr(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE ApproveReading(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE
);

PROCEDURE SetReadingActiveFlag(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	in_active				IN	meter_reading.active%TYPE
);

PROCEDURE CreateFlowItemForReading (
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	out_flow_item_id		OUT	flow_item.flow_item_id%TYPE
);

-- These can be called as helpers form the work-flow
PROCEDURE WF_ApproveReading(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_from_state_id		IN	flow_state.flow_state_id%TYPE,
	in_to_state_id			IN	flow_state.flow_state_id%TYPE,
	in_lookup_key			IN	flow_State_transition.lookup_key%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE WF_MarkActive(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_from_state_id		IN	flow_state.flow_state_id%TYPE,
	in_to_state_id			IN	flow_state.flow_state_id%TYPE,
	in_lookup_key			IN	flow_State_transition.lookup_key%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE WF_MarkInactive(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_from_state_id		IN	flow_state.flow_state_id%TYPE,
	in_to_state_id			IN	flow_state.flow_state_id%TYPE,
	in_lookup_key			IN	flow_State_transition.lookup_key%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

-- DEBUGGING
FUNCTION INTERNAL_GetBaselineVal(
	in_meter_reading_id		IN	meter_reading.meter_reading_id%TYPE
) RETURN meter_reading.baseline_val%TYPE;

PROCEDURE GetMeterInputs(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SaveMeterInput(
	in_meter_input_id				IN  meter_input.meter_input_id%TYPE,
	in_label						IN  meter_input.label%TYPE,
	in_lookup_key					IN  meter_input.lookup_key%TYPE,
	in_is_consumption_based			IN  meter_input.is_consumption_based%TYPE,
	in_aggregators					IN  security.security_pkg.T_VARCHAR2_ARRAY,
	out_meter_input_id				OUT meter_input.meter_input_id%TYPE
);

PROCEDURE DeleteMeterInput(
	in_meter_input_id				IN  meter_input.meter_input_id%TYPE
);

PROCEDURE SaveMeterInputAggregator(
	in_meter_input_id				IN  meter_input_aggregator.meter_input_id%TYPE,
	in_aggregator					IN  meter_input_aggregator.aggregator%TYPE,
	in_is_mandatory					IN  meter_input_aggregator.is_mandatory%TYPE
);

PROCEDURE GetMeterInputAggregators(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterAggregators(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterType(
	in_meter_type_id			meter_type.meter_type_id%TYPE,
	out_meter_type_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterTypes(
	out_meter_types_cur				OUT	SYS_REFCURSOR,
	out_meter_types_conv_cur		OUT	SYS_REFCURSOR,
	out_meter_type_input_cur		OUT	SYS_REFCURSOR
);

PROCEDURE SaveMeterType(
	in_meter_type_id				IN  meter_type.meter_type_id%TYPE,
	in_label						IN  meter_type.label%TYPE,
	in_group_key					IN  meter_type.group_key%TYPE,
	in_days_ind_sid					IN  meter_type.days_ind_sid%TYPE,
	in_costdays_ind_sid				IN  meter_type.costdays_ind_sid%TYPE,
	out_meter_type_id				OUT meter_type.meter_type_id%TYPE
);

PROCEDURE EmptyTempMeterTypeInput;

PROCEDURE AddTempMeterTypeInput(
	in_meter_input_id				IN  temp_meter_type_input.meter_input_id%TYPE,
	in_aggregator					IN  temp_meter_type_input.aggregator%TYPE,
	in_ind_sid						IN  temp_meter_type_input.ind_sid%TYPE
);

PROCEDURE DeleteMeterType(
	in_meter_type_id				IN  meter_type.meter_type_id%TYPE
);

PROCEDURE GetMeteringOptions(
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SaveMeteringOptions(
	in_analytics_months				IN	metering_options.analytics_months%TYPE,
	in_analytics_current_month		IN	metering_options.analytics_current_month%TYPE,
	in_show_inherited_roles			IN	metering_options.show_inherited_roles%TYPE,
	in_reference_mandatory			IN	metering_options.reference_mandatory%TYPE,
	in_supplier_data_mandatory		IN	metering_options.supplier_data_mandatory%TYPE,
	in_show_invoice_reminder		IN	metering_options.show_invoice_reminder%TYPE,
	in_invoice_reminder				IN	metering_options.invoice_reminder%TYPE,
	in_prevent_manual_future_rdgs	IN	metering_options.prevent_manual_future_readings%TYPE,
	in_proc_use_service				IN	metering_options.proc_use_service%TYPE,
	in_proc_api_base_uri			IN	metering_options.proc_api_base_uri%TYPE,
	in_proc_local_path				IN	metering_options.proc_local_path%TYPE,
	in_proc_kick_timeout			IN	metering_options.proc_kick_timeout%TYPE,
	in_proc_api_key					IN	metering_options.proc_api_key%TYPE
);

FUNCTION GetMeterPageUrl (
	in_app_sid						security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
) RETURN VARCHAR2;

PROCEDURE LegacyCreateMeter(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_description				IN	region_description.description%TYPE,
	in_reference				IN	all_meter.reference%TYPE DEFAULT NULL,
	in_note						IN	all_meter.note%TYPE	DEFAULT NULL,
	in_source_type_id			IN  all_meter.meter_source_type_id%TYPE DEFAULT 2, -- arbitrary period
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_consump_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_cost_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_region_type				IN	region.region_type%TYPE DEFAULT csr_data_pkg.REGION_TYPE_METER,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	out_region_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateMeter(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_description				IN	region_description.description%TYPE,
	in_reference				IN	all_meter.reference%TYPE DEFAULT NULL,
	in_note						IN	all_meter.note%TYPE	DEFAULT NULL,
	in_source_type_id			IN  all_meter.meter_source_type_id%TYPE DEFAULT 2, -- arbitrary period
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_region_type				IN	region.region_type%TYPE DEFAULT csr_data_pkg.REGION_TYPE_METER,
	in_region_ref				IN	region.region_ref%TYPE DEFAULT NULL,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	out_region_sid				OUT	security_pkg.T_SID_ID
);

-- URJANET PROCEDURES

PROCEDURE CreateOrFindMeter(
	in_raw_data_id			IN 	NUMBER,
	in_name					IN	VARCHAR2,
	in_region_ref			IN	VARCHAR2,
	in_urjanet_meter_id		IN	VARCHAR2,
	in_service_type			IN	VARCHAR2,
	in_meter_number			IN	VARCHAR2,
	out_exists				OUT	NUMBER
);

PROCEDURE CheckServiceTypeExists(
	in_raw_data_id			IN 	NUMBER,
	in_service_type			IN	VARCHAR2
);

FUNCTION IsExternalMeterCreationEnabled 
RETURN NUMBER;

PROCEDURE GetUrjanetServiceTypes(
	in_raw_data_source_id			IN	urjanet_service_type.raw_data_source_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveUrjanetServiceType(
	in_service_type					IN	urjanet_service_type.service_type%TYPE,
	in_meter_type_id				IN	urjanet_service_type.meter_type_id%TYPE,
	in_raw_data_source_id			IN	urjanet_service_type.raw_data_source_id%TYPE
);

PROCEDURE ClearUrjanetServiceTypes (
	in_raw_data_source_id			IN	meter_raw_data_source.raw_data_source_id%TYPE
);

PROCEDURE GetMeterDataImporterOptions (
	in_automated_import_class_sid	IN	auto_imp_importer_settings.automated_import_class_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetUrjanetOptions (
	in_automated_import_class_sid	IN	auto_imp_importer_settings.automated_import_class_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE UrjanetEnabled(
	out_enabled						OUT	NUMBER
);

-- END OF URJANET PROCEDURES

PROCEDURE AddRecomputeBatchJob(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddRecomputeBatchJob(
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE ProcessRecomputeBatchJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
);

PROCEDURE AddMeterTypeChangeBatchJob (
	in_meter_type_id				IN	meter_type_input.meter_type_id%TYPE,
	in_meter_input_id				IN	meter_type_input.meter_input_id%TYPE,
	in_aggregator					IN	meter_type_input.aggregator%TYPE,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddMeterTypeChangeBatchJob(
	in_meter_type_ids				IN	security_pkg.T_SID_IDS,
	in_meter_input_ids				IN	security_pkg.T_SID_IDS,
	in_aggregators					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_job_id						OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE ProcessMeterTypeChangeBatchJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
);

PROCEDURE IndMeasureSidChanged(
	in_ind_sid						IN  security_pkg.T_SID_ID,
	in_measure_sid					IN  security_pkg.T_SID_ID
);

-- Meter tab procedures
PROCEDURE GetMeterTabs(
	in_meter_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveMeterTab (
	in_plugin_id					IN  meter_tab.plugin_id%TYPE,
	in_tab_label					IN  meter_tab.tab_label%TYPE,
	in_pos							IN  meter_tab.pos%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RemoveMeterTab(
	in_plugin_id					IN  meter_tab.plugin_id%TYPE
);
-- End of meter tab procedures

-- Meter header element procedures
PROCEDURE GetMeterHeaderElements (
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveMeterHeaderElement (
	in_meter_header_element_id		IN	meter_header_element.meter_header_element_id%TYPE,
	in_pos							IN	meter_header_element.pos%TYPE,
	in_col							IN	meter_header_element.col%TYPE,
	in_ind_sid						IN  meter_header_element.ind_sid%TYPE,
	in_tag_group_id					IN  meter_header_element.tag_group_id%TYPE,
	in_meter_header_core_el_id		IN  meter_header_element.meter_header_core_element_id%TYPE,
	in_show_measure					IN  region_metric.show_measure%TYPE,
	out_meter_header_element_id		OUT	meter_header_element.meter_header_element_id%TYPE
);

PROCEDURE DeleteMeterHeaderElement (
	in_meter_header_element_id		IN	meter_header_element.meter_header_element_id%TYPE
);

-- End of meter header element procedures

-- Meter photo procedures
PROCEDURE AddMeterPhoto (
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_cache_key					IN	aspen2.filecache.cache_key%TYPE,
	out_meter_photo_id				OUT	meter_photo.meter_photo_id%TYPE
);

PROCEDURE DeleteMeterPhoto (
	in_meter_photo_id				IN	meter_photo.meter_photo_id%TYPE
);

PROCEDURE GetMeterPhoto (
	in_meter_photo_id				IN	meter_photo.meter_photo_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);
-- End of meter photo procedures

PROCEDURE GetIssues(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE AddIssue(
	in_region_sid 		IN 	security_pkg.T_SID_ID,
	in_label			IN	issue.label%TYPE,
	in_description		IN	issue_log.message%TYPE,
	in_due_dtm			IN	issue.due_dtm%TYPE,
	in_is_urgent		IN	NUMBER,
	in_is_critical		IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id		OUT issue.issue_id%TYPE
);

PROCEDURE GetRawMeterData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_from_row				IN	NUMBER,
	in_to_row				IN	NUMBER,
	in_from_dtm				IN	DATE,
	in_to_dtm				IN	DATE,
	in_filter				IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRawMeterDataForExport (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_from_dtm				IN	DATE,
	in_to_dtm				IN	DATE,
	in_filter				IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterReadingListForTab(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_start_row            IN NUMBER,
    in_end_row              IN NUMBER,
    out_cur                 OUT SYS_REFCURSOR
);

PROCEDURE GetMeterReadingListForTab(
    in_region_sid           IN security_pkg.T_SID_ID,
    in_start_row            IN NUMBER,
    in_end_row              IN NUMBER,
    in_include_auto_src		IN NUMBER,
    out_cur                 OUT SYS_REFCURSOR
);

PROCEDURE MoveAndRenameMeter(
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_description				IN	region_description.description%TYPE
);

PROCEDURE UNSEC_AmendMeterActive(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_active					IN	region.active%TYPE,
	in_acquisition_dtm			IN	region.acquisition_dtm%TYPE,
	in_disposal_dtm				IN	region.disposal_dtm%TYPE
);

PROCEDURE SetMeter(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_description				IN	region_description.description%TYPE,
	in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
	in_note						IN	all_meter.note%TYPE,
	in_days_conversion_id		IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_costdays_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE DEFAULT NULL,
	in_source_type_id			IN	all_meter.meter_source_type_id%TYPE,
	in_manual_data_entry		IN  all_meter.manual_data_entry%TYPE,
	in_reference				IN	all_meter.reference%TYPE,
	in_contract_ids				IN	security_pkg.T_SID_IDS,
	in_active_contract_id		IN	utility_contract.utility_contract_id%TYPE,
	in_crc_meter				IN	all_meter.crc_meter%TYPE DEFAULT 0,
	in_is_core					IN	all_meter.is_core%TYPE DEFAULT 0,
	in_urjanet_meter_id			IN	all_meter.urjanet_meter_id%TYPE DEFAULT NULL,
	in_active					IN	region.active%TYPE,
	in_acquisition_dtm			IN	region.acquisition_dtm%TYPE,
	in_disposal_dtm				IN	region.disposal_dtm%TYPE
);

PROCEDURE GetAllMeteringMeasures(
	out_measure_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_measure_conv_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_measure_conv_date_cur		OUT	security_pkg.T_OUTPUT_CUR
);

END meter_pkg;
/
