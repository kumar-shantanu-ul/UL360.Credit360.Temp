-- Please update version.sql too -- this keeps clean builds in sync
define version=299
@update_header

update alert_type set params_xml='<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="MESSAGE"/></params>'
where alert_type_id=1;

@update_tail
