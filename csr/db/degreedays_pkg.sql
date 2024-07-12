CREATE OR REPLACE PACKAGE csr.degreedays_pkg AS

/**
 *	Fetches site specific degree day settings for the logged in site (or all sites if not logged in).
 *
 *	@param out_sites				A cursor that yields the result set:
 *
 *									 Name                                      Null?    Type
 * 									 ----------------------------------------- -------- ---------------------
 * 									 APP_SID                                   NOT NULL NUMBER(10)
 * 									 ACCOUNT_NAME                              NOT NULL VARCHAR2(128)
 * 									 DOWNLOAD_ENABLED                          NOT NULL NUMBER(1)
 * 									 EARLIEST_FETCH_DTM                        NOT NULL DATE
 * 									 AVERAGE_YEARS                             NOT NULL NUMBER(3)
 * 									 HEATING_BASE_TEMP_IND_SID                          NUMBER(10)
 * 									 COOLING_BASE_TEMP_IND_SID                          NUMBER(10)
 * 									 HEATING_DEGREE_DAYS_IND_SID                        NUMBER(10)
 * 									 COOLING_DEGREE_DAYS_IND_SID                        NUMBER(10)
 * 									 HEATING_AVERAGE_IND_SID                            NUMBER(10)
 * 									 COOLING_AVERAGE_IND_SID                            NUMBER(10)
 * 									 LAST_SYNC_DTM                                      DATE
 */
PROCEDURE GetSettings(
	out_cur							OUT SYS_REFCURSOR
);

/**
 *	Updates site settings for the logged in site.
 */
PROCEDURE SetSettings(
	in_account_name					IN degreeday_settings.account_name%TYPE,
	in_download_enabled				IN degreeday_settings.download_enabled%TYPE,
	in_earliest_fetch_dtm			IN degreeday_settings.earliest_fetch_dtm%TYPE,
	in_average_years				IN degreeday_settings.average_years%TYPE,
	in_heating_base_temp_ind_sid	IN degreeday_settings.heating_base_temp_ind_sid%TYPE,
	in_cooling_base_temp_ind_sid	IN degreeday_settings.cooling_base_temp_ind_sid%TYPE,
	in_heating_degree_days_ind_sid	IN degreeday_settings.heating_degree_days_ind_sid%TYPE,
	in_cooling_degree_days_ind_sid	IN degreeday_settings.cooling_degree_days_ind_sid%TYPE,
	in_heating_average_ind_sid		IN degreeday_settings.heating_average_ind_sid%TYPE,
	in_cooling_average_ind_sid		IN degreeday_settings.cooling_average_ind_sid%TYPE
);

PROCEDURE SetLastSync(
	in_date							IN DATE
);

/**
 *	Fetches Degree Days account records. 
 *
 *	@param in_account_name			The name of the single account to retrieve, or NULL to fetch all 
 *									accounts.
 *
 *	@param out_sites				A cursor that yields the result set:
 *
 *									 Name                                      Null?    Type
 *									 ----------------------------------------- -------- ---------------------
 *									 ACCOUNT_NAME                              NOT NULL VARCHAR2(128)
 *									 ACCOUNT_KEY                               NOT NULL VARCHAR2(1024)
 *									 SECURITY_KEY                              NOT NULL VARCHAR2(1024)
 */
PROCEDURE GetAccount(
	in_account_name					IN	degreeday_account.account_name%TYPE DEFAULT NULL,
	out_accounts					OUT SYS_REFCURSOR
);

/**
 *	Gets region and station data for all geo-located regions.
 */
PROCEDURE GetLocations(
	out_regions						OUT SYS_REFCURSOR
);

/**
 *	Sets the weather station id associated a region.
 *
 *	@param	in_region_sid			The sid of the region to update.
 *	@param	in_station_id			The sid of the region to update.
 */
PROCEDURE UpdateWeatherStation(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_station_id					IN	degreeday_region.station_id%TYPE,
	in_station_description			IN	degreeday_region.station_description%TYPE DEFAULT NULL
);

/**
 *	Sets indicator values for a given region and period.
 */
PROCEDURE UpdateIndicators(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_start_dtm					IN val.period_start_dtm%TYPE,
	in_end_dtm						IN val.period_start_dtm%TYPE,
	in_hdd_value					IN degreeday_data.degree_days%TYPE,
	in_cdd_value					IN degreeday_data.degree_days%TYPE,
	in_hdd_average					IN degreeday_data.degree_days%TYPE,
	in_cdd_average					IN degreeday_data.degree_days%TYPE
);

PROCEDURE UpdateCachedValue(
	in_station_id					IN degreeday_data.station_id%TYPE,
	in_calculation_type				IN degreeday_data.calculation_type%TYPE,
	in_period_dtm					IN degreeday_data.period_dtm%TYPE,
	in_base_temp					IN degreeday_data.base_temp%TYPE,
	in_degree_days					IN degreeday_data.degree_days%TYPE
);

PROCEDURE FetchCachedValues(
	in_station_ids					IN security_pkg.T_VARCHAR2_ARRAY,
	in_calculation_types			IN security_pkg.T_SID_IDS,
	in_period_dtms					IN security_pkg.T_VARCHAR2_ARRAY,
	in_base_temps					IN security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT SYS_REFCURSOR
);

END degreedays_pkg;
/
