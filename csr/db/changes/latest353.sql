-- Please update version.sql too -- this keeps clean builds in sync
define version=353
@update_header

update alert_type
   set params_xml = 
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
			'<param name="SHEET_PERIOD_FMT"/>'||
		'</params>'
 where alert_type_id = 2;

update alert_type
   set params_xml = 
		'<params>'||
			'<param name="FULL_NAME"/>'||
			'<param name="FRIENDLY_NAME"/>'||
			'<param name="EMAIL  "/>'||
			'<param name="USER_NAME"/>'||
			'<param name="DELEGATION_NAME"/>'||
			'<param name="SUBMISSION_DTM_FMT"/>'||
			'<param name="SHEET_URL"/>'||
			'<param name="SHEET_PERIOD_FMT"/>'||
		'</params>'
 where alert_type_id = 3;

update alert_type
   set params_xml = 
		'<params><param name="FROM_NAME"/>'||
			'<param name="FULL_NAME"/>'||
			'<param name="FRIENDLY_NAME"/>'||
			'<param name="FROM_EMAIL"/>'||
			'<param name="TO_NAME"/>'||
			'<param name="TO_EMAIL"/>'||
			'<param name="DESCRIPTION"/>'||
			'<param name="DELEGATION_NAME"/>'||
			'<param name="SUBMISSION_DTM_FMT"/>'||
			'<param name="SHEET_URL"/>'||
			'<param name="NOTE"/>'||
			'<param name="SHEET_PERIOD_FMT"/>'||
		'</params>'
 where alert_type_id = 4;

update alert_type
   set params_xml = 
		'<params>'||
			'<param name="FULL_NAME"/>'||
			'<param name="FRIENDLY_NAME"/>'||
			'<param name="EMAIL"/>'||
			'<param name="DELEGATION_NAME"/>'||
			'<param name="USER_NAME"/>'||
			'<param name="SHEET_URL"/>'||
			'<param name="SUBMISSION_DTM_FMT"/>'||
			'<param name="SHEET_PERIOD_FMT"/>'||
		'</params>'
 where alert_type_id = 5;

@update_tail
