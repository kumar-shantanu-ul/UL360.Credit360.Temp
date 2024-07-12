-- Please update version.sql too -- this keeps clean builds in sync
define version=62
@update_header

ALTER TABLE PROJECT ADD (
	POS_GROUP		NUMBER(10, 0),
    POS				NUMBER(10, 0)
);


ALTER TABLE PROJECT_IND_TEMPLATE ADD (
	INPUT_DP             NUMBER(10, 0)     DEFAULT 0 NOT NULL
);

ALTER TABLE CUSTOMER_OPTIONS ADD (
	INITIATIVE_HIDE_ONGOING_RADIO    NUMBER(1, 0)      DEFAULT 0 
	CHECK (INITIATIVE_HIDE_ONGOING_RADIO IN (0,1))
);

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
		'<param name="REFERENCE"/>' ||
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
		'<param name="REFERENCE"/>' ||
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
		'<param name="REFERENCE"/>' ||
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
		'<param name="REFERENCE"/>' ||
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
