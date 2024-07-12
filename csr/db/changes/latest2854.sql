define version=2854
define minor_version=0
@update_header

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (58, 'Meter reporting', 'EnableMeterReporting', 'Enables quick-chart reporting on the metering module');	 
	 
UPDATE csr.meter_bucket
   SET description = 'Monthly'
 WHERE description = 'System'
   AND (app_sid, period_set_id) IN (
	SELECT app_sid, period_set_id
	  FROM csr.period_set
	 WHERE label = 'Calendar months'
   );

@..\enable_pkg
@..\enable_body

@update_tail
