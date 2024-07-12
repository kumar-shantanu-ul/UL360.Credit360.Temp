-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- db/create_views
CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM meter_source_data sd
			 WHERE sd.app_sid = m.app_sid
			   AND sd.region_sid = m.region_sid
		) 
	)
	--
	-- Legacy meter readings part
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost, 
		mr.baseline_val, mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, 
		mr.meter_document_id, mr.created_invoice_id, mr.approved_dtm, mr.approved_by_sid, 
		mr.is_estimate, mr.flow_item_id, mr.pm_reading_id, mr.format_mask,
		m.auto_source
	  FROM m
	  JOIN csr.v$meter_reading mr on mr.app_sid = m.app_sid AND mr.region_sid = m.legacy_region_sid
	--
	-- Source data part
	UNION
	SELECT MAX(x.app_sid) app_sid, ROW_NUMBER() OVER (ORDER BY x.start_dtm) meter_reading_id, 
		MAX(x.region_sid) region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, NULL note, NULL reference, 
		NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid, 
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask,
		x.auto_source
	FROM (
		-- Consumption
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.raw_consumption val_number, NULL cost, m.auto_source
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.raw_consumption cost, m.auto_source
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/
		   AND js_class = 'Credit360.Metering.MeterReadingTab';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
			VALUES (csr.plugin_id_seq.NEXTVAL, 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 
				'Readings', '/csr/site/meter/controls/meterReadingTab.js', 
				'Credit360.Metering.MeterReadingTab', 'Credit360.Metering.Plugins.MeterReading', 
				'Enter readings and check percentage tolerances.', '/csr/shared/plugins/screenshots/meter_readings.png')
			RETURNING plugin_id INTO v_plugin_id;
	END;

	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_source_type s
		  JOIN csr.customer c ON c.app_sid = s.app_sid
	) LOOP
		security.user_pkg.logonadmin(a.host);
		BEGIN
			INSERT INTO csr.meter_tab(plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_plugin_id, 16/*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 1, 'Readings');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Administrators'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the group/role is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter administrator'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the group/role  is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter reader'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the group/role  is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/

BEGIN
	UPDATE csr.plugin
	   SET details = 'Display a simple chart showing total and average consumption for the lifetime of the meter.',
	       preview_image_path = '/csr/shared/plugins/screenshots/meter_low_res_chart.png'
	 WHERE js_class = 'Credit360.Metering.MeterLowResChartTab';

	UPDATE csr.plugin
	   SET details = 'Display a detailed interactive chart showing all inputs for the meter, and patch data for the meter.',
	       preview_image_path = '/csr/shared/plugins/screenshots/meter_hi_res_chart.png'
	 WHERE js_class = 'Credit360.Metering.MeterHiResChartTab';

	UPDATE csr.plugin
	   SET details = 'Display, filter, search, and export raw readings for the meter.',
	       preview_image_path = '/csr/shared/plugins/screenshots/meter_raw_data.png'
	 WHERE js_class = 'Credit360.Metering.MeterRawDataTab';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../property_pkg

@../meter_body
@../property_body

@update_tail
