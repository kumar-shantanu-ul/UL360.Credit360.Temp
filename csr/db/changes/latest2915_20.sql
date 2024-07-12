-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=20
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
BEGIN
	-- UPDATE
	UPDATE csr.module
	   SET module_name = 'Metering - base',
	       enable_sp = 'EnableMeteringBase',
	       description = 'Enables the basic metering module'
	 WHERE module_id = 20;


	-- UPDATE
	UPDATE csr.module
	   SET module_name = 'Metering - quick charts',
	       enable_sp = 'EnableMeterReporting',
	       description = 'Enables meter data quick charts'
	 WHERE module_id = 58;

	-- UPDATE
	UPDATE csr.module
	   SET module_name = 'Metering - urjanet',
	       enable_sp = 'EnableUrjanet',
	       description = 'Enables Urjanet integration pages and settings'
	 WHERE module_id = 60;

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (68, 'Metering - data feeds', 'EnableMeteringFeeds', 'Enables pages to set-up meter data feeds');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (69, 'Metering - monitoring', 'EnableMeterMonitoring', 'Enables pages for data feeds and alarms');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (70, 'Metering - utilities', 'EnableMeterUtilities', 'Enables pages for invoices, contracts and suppliers');

END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_pkg

@../enable_body
@../meter_monitor_body
@../meter_alarm_body
@../utility_report_body

@update_tail
