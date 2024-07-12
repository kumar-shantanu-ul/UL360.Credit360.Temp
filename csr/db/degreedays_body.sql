CREATE OR REPLACE PACKAGE BODY csr.degreedays_pkg AS

/**
 *	Raises an ERR_ACCESS_DENIED application error if the logged in user is not the built-in admin or a user 
 *	with the 'System managment' capability. 
 */
PROCEDURE AssertSystemManager
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Only the built-in admin or a user with system management capability can perform the requested task.'
		);
	END IF;
END;

PROCEDURE GetSettings(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ds.app_sid,
			   c.host,
			   ds.account_name,
			   ds.download_enabled,
			   ds.earliest_fetch_dtm,
			   ds.average_years,
			   ds.heating_base_temp_ind_sid,
			   ds.cooling_base_temp_ind_sid,
			   ds.heating_degree_days_ind_sid,
			   ds.cooling_degree_days_ind_sid,
			   ds.heating_average_ind_sid,
			   ds.cooling_average_ind_sid,
			   ds.last_sync_dtm
		  FROM degreeday_settings ds, csr.customer c
		 WHERE c.app_sid = ds.app_sid;
END;

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
)
AS
BEGIN
	AssertSystemManager;

	BEGIN
		INSERT INTO degreeday_settings 
			(app_sid, account_name, download_enabled, earliest_fetch_dtm, average_years, 
			 heating_base_temp_ind_sid, cooling_base_temp_ind_sid, heating_degree_days_ind_sid,
			 cooling_degree_days_ind_sid, heating_average_ind_sid, cooling_average_ind_sid) 
		VALUES 
			(security.security_pkg.GetApp, in_account_name, in_download_enabled, in_earliest_fetch_dtm, 
			 in_average_years, in_heating_base_temp_ind_sid, in_cooling_base_temp_ind_sid, 
			 in_heating_degree_days_ind_sid, in_cooling_degree_days_ind_sid, in_heating_average_ind_sid, 
			 in_cooling_average_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE degreeday_settings SET
					account_name				= in_account_name,
					download_enabled			= in_download_enabled,
					earliest_fetch_dtm			= in_earliest_fetch_dtm,
					average_years				= in_average_years,
					heating_base_temp_ind_sid	= in_heating_base_temp_ind_sid,
					cooling_base_temp_ind_sid	= in_cooling_base_temp_ind_sid,
					heating_degree_days_ind_sid	= in_heating_degree_days_ind_sid,
					cooling_degree_days_ind_sid	= in_cooling_degree_days_ind_sid,
					heating_average_ind_sid		= in_heating_average_ind_sid,
					cooling_average_ind_sid		= in_cooling_average_ind_sid
			 WHERE app_sid = security_pkg.GetApp;
	END;
END;

PROCEDURE SetLastSync(
	in_date							IN DATE
)
AS
BEGIN
	AssertSystemManager;

	UPDATE degreeday_settings 
	   SET last_sync_dtm = in_date 
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE GetAccount(
	in_account_name					IN	degreeday_account.account_name%TYPE,
	out_accounts					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: permisions?

	OPEN out_accounts FOR 
		SELECT account_name, account_key, security_key
		  FROM degreeday_account
		 WHERE in_account_name IS NULL
			OR in_account_name = account_name;
END;

PROCEDURE GetLocations(
	out_regions						OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertSystemManager;

	OPEN out_regions FOR
		SELECT /* Fields to satisfy Region constructor */
			   r.region_sid, r.parent_sid, r.description, r.active, r.pos, 
			   EXTRACT(r.info_xml,'/').getClobVal() info_xml,
			   r.name, r.link_to_region_sid, r.geo_latitude, r.geo_longitude, r.geo_country,
			   r.map_entity, r.egrid_ref, r.geo_region, r.geo_city_id, r.geo_type, r.region_type,
			   r.lookup_key, r.region_ref, r.disposal_dtm, r.acquisition_dtm,
			   /* Extra data */
			   dr.station_id
		  FROM v$region r
		  LEFT JOIN degreeday_region dr ON r.region_sid = dr.region_sid AND r.app_sid = dr.app_sid
		 WHERE r.geo_type = region_pkg.REGION_GEO_TYPE_LOCATION 
		   AND ((r.geo_latitude IS NOT NULL AND r.geo_longitude IS NOT NULL) OR station_id IS NOT NULL);
END;

PROCEDURE UpdateWeatherStation(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_station_id					IN	degreeday_region.station_id%TYPE,
	in_station_description			IN	degreeday_region.station_description%TYPE
)
AS
BEGIN
	AssertSystemManager;

	IF in_station_id IS NULL THEN
		DELETE FROM degreeday_region 
		 WHERE region_sid = in_region_sid
		   AND app_sid = security_pkg.GetApp;
	ELSE
		BEGIN
			INSERT INTO degreeday_region (region_sid, station_id, station_description)
			VALUES (in_region_sid, in_station_id, in_station_description);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE degreeday_region
				   SET station_id = in_station_id,
					   station_description = in_station_description
				 WHERE region_sid = in_region_sid
				   AND app_sid = security_pkg.GetApp;
		END;
	END IF;
END;

PROCEDURE UpdateIndicators(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_start_dtm					IN val.period_start_dtm%TYPE,
	in_end_dtm						IN val.period_start_dtm%TYPE,
	in_hdd_value					IN degreeday_data.degree_days%TYPE,
	in_cdd_value					IN degreeday_data.degree_days%TYPE,
	in_hdd_average					IN degreeday_data.degree_days%TYPE,
	in_cdd_average					IN degreeday_data.degree_days%TYPE
)
AS
	v_heating_degree_days_ind_sid	security_pkg.T_SID_ID;
   	v_cooling_degree_days_ind_sid	security_pkg.T_SID_ID;
  	v_heating_average_ind_sid		security_pkg.T_SID_ID;
	v_cooling_average_ind_sid		security_pkg.T_SID_ID;
	v_average_years					degreeday_settings.average_years%TYPE;
	v_val_id						val.val_id%TYPE;
	v_station_id					degreeday_region.station_id%TYPE;
	v_station_description			degreeday_region.station_description%TYPE;
	v_note							val.note%TYPE;
BEGIN
	AssertSystemManager;

	SELECT heating_degree_days_ind_sid, 
		   cooling_degree_days_ind_sid, 
		   heating_average_ind_sid, 
		   cooling_average_ind_sid,
		   average_years
	  INTO v_heating_degree_days_ind_sid, 
		   v_cooling_degree_days_ind_sid, 
		   v_heating_average_ind_sid, 
		   v_cooling_average_ind_sid,
		   v_average_years
	  FROM degreeday_settings
	 WHERE app_sid = security_pkg.GetApp;

	SELECT station_id, station_description
	  INTO v_station_id, v_station_description 
	  FROM degreeday_region
	 WHERE region_sid = in_region_sid
	   AND app_sid = security_pkg.GetApp;

	IF v_heating_degree_days_ind_sid IS NOT NULL THEN
		v_note := 'Station: ' || v_station_id || ', ' || v_station_description || '. Source: degreedays.net';
		IF in_hdd_value IS NULL THEN
			v_note := v_note || ' (data not available)';
		END IF;

		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 		=> security_pkg.GetSid,
			in_ind_sid 			=> v_heating_degree_days_ind_sid,
			in_region_sid 		=> in_region_sid,
			in_period_start 	=> in_start_dtm,
			in_period_end 		=> in_end_dtm,
			in_val_number		=> in_hdd_value,
			in_reason			=> 'Value set by degreedays.net import',
			in_note				=> v_note,
			in_source_type_id	=> csr_data_pkg.SOURCE_TYPE_DIRECT, -- TODO: new source type?
			out_val_id			=> v_val_id
		);
	END IF;

	IF v_cooling_degree_days_ind_sid IS NOT NULL THEN
		v_note := 'Station: ' || v_station_id || ', ' || v_station_description || '. Source: degreedays.net';
		IF in_cdd_value IS NULL THEN
			v_note := v_note || ' (data not available)';
		END IF;

		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 		=> security_pkg.GetSid,
			in_ind_sid 			=> v_cooling_degree_days_ind_sid,
			in_region_sid 		=> in_region_sid,
			in_period_start 	=> in_start_dtm,
			in_period_end 		=> in_end_dtm,
			in_val_number		=> in_cdd_value,
			in_reason			=> 'Value set by degreedays.net import',
			in_note				=> v_note,
			in_source_type_id	=> csr_data_pkg.SOURCE_TYPE_DIRECT, 
			out_val_id			=> v_val_id
		);
	END IF;

	IF v_heating_average_ind_sid IS NOT NULL THEN
		v_note := 'Station: ' || v_station_id || ', ' || v_station_description || '. ' ||
				  'Coverage: ' || v_average_years || '-year average. Source: degreedays.net';

		IF in_hdd_average IS NULL THEN
			v_note := v_note || ' (data not available)';
		END IF;

		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 		=> security_pkg.GetSid,
			in_ind_sid 			=> v_heating_average_ind_sid,
			in_region_sid 		=> in_region_sid,
			in_period_start 	=> in_start_dtm,
			in_period_end 		=> in_end_dtm,
			in_val_number		=> in_hdd_average,
			in_reason			=> 'Value set by degreedays.net import',
			in_note				=> v_note,
			in_source_type_id	=> csr_data_pkg.SOURCE_TYPE_DIRECT, 
			out_val_id			=> v_val_id
		);
	END IF;

	IF v_cooling_average_ind_sid IS NOT NULL THEN
		v_note := 'Station: ' || v_station_id || ', ' || v_station_description || '. ' ||
				  'Coverage: ' || v_average_years || '-year average. Source: degreedays.net';

		IF in_cdd_average IS NULL THEN
			v_note := v_note || ' (data not available)';
		END IF;

		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 		=> security_pkg.GetSid,
			in_ind_sid 			=> v_cooling_average_ind_sid,
			in_region_sid 		=> in_region_sid,
			in_period_start 	=> in_start_dtm,
			in_period_end 		=> in_end_dtm,
			in_val_number		=> in_cdd_average,
			in_reason			=> 'Value set by degreedays.net import',
			in_note				=> v_note,
			in_source_type_id	=> csr_data_pkg.SOURCE_TYPE_DIRECT, 
			out_val_id			=> v_val_id
		);
	END IF;
END;

PROCEDURE UpdateCachedValue(
	in_station_id					IN degreeday_data.station_id%TYPE,
	in_calculation_type				IN degreeday_data.calculation_type%TYPE,
	in_period_dtm					IN degreeday_data.period_dtm%TYPE,
	in_base_temp					IN degreeday_data.base_temp%TYPE,
	in_degree_days					IN degreeday_data.degree_days%TYPE
)
AS
BEGIN
	AssertSystemManager;

	BEGIN
		INSERT INTO degreeday_data (station_id, calculation_type, period_dtm, base_temp, degree_days)
		VALUES (in_station_id, in_calculation_type, in_period_dtm, in_base_temp, in_degree_days);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE degreeday_data
			   SET degree_days = in_degree_days
			 WHERE station_id = in_station_id
			   AND calculation_type = in_calculation_type
			   AND period_dtm = in_period_dtm
			   AND base_temp = in_base_temp
			   AND degree_days = in_degree_days;
	END;
END;

PROCEDURE FetchCachedValues(
	in_station_ids					IN security_pkg.T_VARCHAR2_ARRAY,
	in_calculation_types			IN security_pkg.T_SID_IDS,
	in_period_dtms					IN security_pkg.T_VARCHAR2_ARRAY,
	in_base_temps					IN security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_station_ids					security.T_VARCHAR2_TABLE;
	v_calculation_types				security.T_ORDERED_SID_TABLE;
	v_period_dtms					security.T_VARCHAR2_TABLE;
	v_base_temps					security.T_VARCHAR2_TABLE;
BEGIN
	AssertSystemManager;

	-- TODO: 
	--  Pass these as appropriately typed arrays instead (security currently lacks the support types and 
	--  functions to do this).
	v_station_ids := security_pkg.Varchar2ArrayToTable(in_station_ids);
	v_calculation_types := security_pkg.SidArrayToOrderedTable(in_calculation_types);
	v_period_dtms := security_pkg.Varchar2ArrayToTable(in_period_dtms);
	v_base_temps := security_pkg.Varchar2ArrayToTable(in_base_temps);

	-- All these casts are probably going to mess up the query plan. Oh well.
	OPEN out_cur FOR
		SELECT dd.station_id, dd.calculation_type, dd.period_dtm, dd.base_temp, dd.degree_days
		  FROM csr.degreeday_data dd
		  JOIN (SELECT s.value station_id, 
					   c.sid_id calculation_type,
					   TO_DATE(p.value, 'YYYY-MM-DD') period_dtm,
					   TO_NUMBER(b.value) base_temp
				  FROM TABLE(v_station_ids) s
				  JOIN TABLE(v_calculation_types) c ON s.pos = c.pos
				  JOIN TABLE(v_period_dtms) p ON s.pos = p.pos
				  JOIN TABLE(v_base_temps) b ON s.pos = b.pos) filter
			 ON filter.station_id = dd.station_id
			AND filter.calculation_type = dd.calculation_type
			AND filter.period_dtm = dd.period_dtm
			AND filter.base_temp = dd.base_temp;
END;

END degreedays_pkg;
/
