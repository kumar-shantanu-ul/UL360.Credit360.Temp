-- Please update version.sql too -- this keeps clean builds in sync
define version=263
@update_header

UPDATE alert_type
   SET params_xml = 
   	'<params>' ||
	   	'<param name="FROM_NAME"/>' ||
	   	'<param name="FROM_EMAIL"/>' ||
	   	'<param name="LABEL"/>' ||
	   	'<param name="SHEET_LABEL"/>' ||
	   	'<param name="TO_NAME"/>' ||
	   	'<param name="TO_EMAIL"/>' ||
	   	'<param name="APPROVAL_STEP_ID"/>' ||
	   	'<param name="SHEET_KEY"/>' ||
 	'</params>'
 WHERE alert_type_id = 15;

@update_tail
