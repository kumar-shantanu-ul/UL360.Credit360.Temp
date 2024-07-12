-- Please update version.sql too -- this keeps clean builds in sync
define version=275
@update_header

update alert_type set description = 'Notify user' where alert_type_id = 1;

update alert_type set params_xml = 
	'<params>'||
		'<param name="DELEGATOR_FULL_NAME"/>'||
		'<param name="DELEGATOR_EMAIL"/>'||
		'<param name="USER_NAME"/>'||
		'<param name="FULL_NAME"/>'||
		'<param name="FRIENDLY_NAME"/>'||
		'<param name="EMAIL"/>'||
		'<param name="DELEGATION_NAME"/>'||
		'<param name="SUBMISSION_DTM_FMT"/>'||
		'<param name="SHEET_URL"/>'||
	'</params>'
 where alert_type_id = 2;
 
commit;

@..\alert_body
		
@update_tail
