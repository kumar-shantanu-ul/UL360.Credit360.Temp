-- Please update version.sql too -- this keeps clean builds in sync
define version=61
@update_header

begin
update csr.alert_type set params_xml =	
	'<params>' ||
		'<param name="SUBMITTED_BY_FULL_NAME"/>' ||
		'<param name="SUBMITTED_BY_FRIENDLY_NAME"/>' ||
		'<param name="SUBMITTED_BY_USER_NAME"/>' ||
		'<param name="SUBMITTED_BY_EMAIL"/>' ||
		'<param name="COORDINATOR_FULL_NAME"/>' ||
		'<param name="COORDINATOR_FRIENDLY_NAME"/>' ||
		'<param name="COORDINATOR_USER_NAME"/>' ||
		'<param name="COORDINATOR_EMAIL"/>' ||
		'<param name="NAME"/>' ||
		'<param name="DESCRIPTION"/>' ||
		'<param name="START_DTM"/>' ||
		'<param name="END_DTM"/>' ||
		'<param name="VIEW_URL"/>' ||
		'<param name="PROPERTY"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="QUERY"/>' ||
	'</params>'
where alert_type_id = 2000;

update csr.alert_type set params_xml =	'<params>' ||
		'<param name="SUBMITTED_BY_FULL_NAME"/>' ||
		'<param name="SUBMITTED_BY_FRIENDLY_NAME"/>' ||
		'<param name="SUBBMITTED_BY_USER_NAME"/>' ||
		'<param name="SUBMITTED_BY_EMAIL"/>' ||
		'<param name="COORDINATOR_FULL_NAME"/>' ||
		'<param name="COORDINATOR_FRIENDLY_NAME"/>' ||
		'<param name="COORDINATOR_USER_NAME"/>' ||
		'<param name="COORDINATOR_EMAIL"/>' ||
		'<param name="NAME"/>' ||
		'<param name="DESCRIPTION"/>' ||
		'<param name="START_DTM"/>' ||
		'<param name="END_DTM"/>' ||
		'<param name="VIEW_URL"/>' ||
		'<param name="PROPERTY"/>' ||
		'<param name="COMMENT"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="QUERY"/>' ||
	'</params>'
where alert_type_id = 2001;

update csr.alert_type set params_xml ='<params>' ||
		'<param name="SUBMITTED_BY_FULL_NAME"/>' ||
		'<param name="SUBMITTED_BY_FRIENDLY_NAME"/>' ||
		'<param name="SUBMITTED_BY_USER_NAME"/>' ||
		'<param name="SUBMITTED_BY_EMAIL"/>' ||
		'<param name="COORDINATOR_FULL_NAME"/>' ||
		'<param name="COORDINATOR_FRIENDLY_NAME"/>' ||
		'<param name="COORDINATOR_USER_NAME"/>' ||
		'<param name="COORDINATOR_EMAIL"/>' ||
		'<param name="NAME"/>' ||
		'<param name="DESCRIPTION"/>' ||
		'<param name="START_DTM"/>' ||
		'<param name="END_DTM"/>' ||
		'<param name="VIEW_URL"/>' ||
		'<param name="PROPERTY"/>' ||
		'<param name="COMMENT"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="QUERY"/>' ||
	'</params>'
where alert_type_id = 2002;


update csr.alert_type set params_xml ='<params>' ||
		'<param name="SUBMITTED_BY_FULL_NAME"/>' ||
		'<param name="SUBMITTED_BY_FRIENDLY_NAME"/>' ||
		'<param name="SUBMITTED_BY_USER_NAME"/>' ||
		'<param name="SUBMITTED_BY_EMAIL"/>' ||
		'<param name="COORDINATOR_FULL_NAME"/>' ||
		'<param name="COORDINATOR_FRIENDLY_NAME"/>' ||
		'<param name="COORDINATOR_USER_NAME"/>' ||
		'<param name="COORDINATOR_EMAIL"/>' ||
		'<param name="NAME"/>' ||
		'<param name="DESCRIPTION"/>' ||
		'<param name="START_DTM"/>' ||
		'<param name="END_DTM"/>' ||
		'<param name="VIEW_URL"/>' ||
		'<param name="PROPERTY"/>' ||
		'<param name="HOST"/>' ||
		'<param name="PATH"/>' ||
		'<param name="QUERY"/>' ||
	'</params>'
where alert_type_id = 2003;
end;
/


@update_tail
