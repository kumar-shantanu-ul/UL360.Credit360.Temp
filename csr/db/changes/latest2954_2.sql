-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=2
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

CREATE OR REPLACE FUNCTION csr.Temp_SetCorePlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
			         in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE plugin 
			   SET description = in_description,
			   	   js_include = in_js_include,
			   	   cs_class = in_cs_class,
			   	   details = in_details,
			   	   preview_image_path = in_preview_image_path,
			   	   form_path = in_form_path
			 WHERE plugin_type_id = in_plugin_type_id
			   AND js_class = in_js_class
			   AND app_sid IS NULL
			   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
		 	RETURNING plugin_id INTO v_plugin_id;
	END;
	RETURN v_plugin_id;
END;
/

DECLARE
	v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Credit360.Calendars.Audits',
		in_description			=> 'Audits',
		in_js_include			=> '/csr/shared/calendar/includes/audits.js',
		in_cs_class				=> 'Credit360.Audit.AuditCalendarDto'
	);

	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Credit360.Calendars.Initiatives',
		in_description			=> 'Events',
		in_js_include			=> '/csr/shared/calendar/includes/initiatives.js'
	);

	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Credit360.Calendars.Issues',
		in_description			=> 'Issues coming due',
		in_js_include			=> '/csr/shared/calendar/includes/issues.js',
		in_cs_class				=> 'Credit360.Issues.IssueCalendarDto'
	);

	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Credit360.Calendars.Teamrooms',
		in_description			=> 'Teamroom events',
		in_js_include			=> '/csr/shared/calendar/includes/teamrooms.js'
	);

	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Credit360.Calendars.Activities',
		in_description			=> 'Activities',
		in_js_include			=> '/csr/shared/calendar/includes/activities.js',
		in_cs_class				=> 'Credit360.Chain.Activities.ActivityCalendarDto'
	);

	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Teamroom.Calendars.Issues',
		in_description			=> 'Teamroom actions',
		in_js_include			=> '/csr/site/teamroom/controls/calendar/issues.js'
	);

	v_plugin_id := csr.Temp_SetCorePlugin(
		in_plugin_type_id		=> 12, --csr.csr_data_pkg.PLUGIN_TYPE_CALENDAR,
		in_js_class				=> 'Credit360.Initiatives.Calendars.Issues',
		in_description			=> 'Actions',
		in_js_include			=> '/csr/site/initiatives/calendar/issues.js'
	);
END;
/

DROP FUNCTION csr.Temp_SetCorePlugin;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
