-- Please update version.sql too -- this keeps clean builds in sync
define version=2428
@update_header


INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
	VALUES (41, 'Rest API', 'EnableRestAPI', 'Enable Rest API');

@../enable_pkg
@../enable_body

@update_tail
