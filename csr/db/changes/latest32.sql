-- Please update version.sql too -- this keeps clean builds in sync
define version=32
@update_header

alter table alert_type add (params_xml clob null);

BEGIN
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="EMAIL"/><param name="USER_NAME"/></params>' WHERE alert_type_id = 1;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="DELEGATOR_FULL_NAME"/><param name="DELEGATOR_EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="EMAIL"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/><param name="DELEGATION_SID"/><param name="SHEET_ID"/></params>' WHERE alert_type_id = 2;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="EMAIL  "/><param name="USER_NAME"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/></params>' WHERE alert_type_id = 3;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FROM_NAME"/><param name="FULL_NAME"/><param name="FROM_EMAIL"/><param name="TO_NAME"/><param name="TO_EMAIL"/><param name="DESCRIPTION"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/><param name="NOTE"/></params>' WHERE alert_type_id = 4;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="EMAIL"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/></params>' WHERE alert_type_id = 5;
END;
/

COMMIT;

@update_tail
