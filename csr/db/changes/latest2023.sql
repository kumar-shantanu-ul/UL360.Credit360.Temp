-- Please update version.sql too -- this keeps clean builds in sync
define version=2023
@update_header

UPDATE csr.std_alert_type_param 
   SET repeats = 1
 WHERE std_alert_type_id IN (5010 /* Chain questionnaire invitation */, 5000 /* Chain invitation */)
   AND field_name IN ('QUESTIONNAIRE_NAME', 'QUESTIONNAIRE_DESCRIPTION');

@update_tail