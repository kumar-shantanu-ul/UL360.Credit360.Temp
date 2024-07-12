-- Please update version.sql too -- this keeps clean builds in sync
define version=2387
@update_header


INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
	VALUES (36, 'Measure Conversions', 'EnableMeasureConversions', 'Enable Measure Conversions');

@../enable_pkg
@../enable_body

@update_tail
