-- Please update version.sql too -- this keeps clean builds in sync
define version=304
@update_header

INSERT INTO csr.alert_type 
	(alert_type_id, parent_alert_type_id, description, get_data_sp, params_xml) 
 VALUES (27, NULL, 'Custom mail alert', NULL, 
	'<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/></params>');

@update_tail
