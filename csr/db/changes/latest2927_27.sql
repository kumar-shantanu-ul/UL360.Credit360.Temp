-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

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
		   AND js_class = 'Credit360.Metering.MeterRawDataTab';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
			VALUES (csr.plugin_id_seq.NEXTVAL, 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 
				'Raw meter data', '/csr/site/meter/controls/meterRawDataTab.js', 
				'Credit360.Metering.MeterRawDataTab', 'Credit360.Metering.Plugins.MeterRawData', 'Display, filter, search, and export raw readings for the meter.')
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
			VALUES (v_plugin_id, 16/*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 2, 'Raw meter data');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Administrators'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter administrator'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter reader'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../meter_body

@update_tail
