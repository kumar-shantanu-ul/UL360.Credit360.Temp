define version=20
@update_header

begin
update chain.alert_entry_named_param set value = dbms_xmlgen.convert(value) where upper(name) in (
  'FOR_COMPANY_NAME'
, 'FOR_USER_FULL_NAME'
, 'FOR_USER_FRIENDLY_NAME'
, 'RELATED_COMPANY_NAME'
, 'RELATED_USER_FULL_NAME'
, 'RELATED_USER_FRIENDLY_NAME'
, 'RELATED_QUESTIONNAIRE_NAME'
);
end;
/

@..\action_body.sql
@..\event_body.sql
@..\scheduled_alert_body.sql

@update_tail
