define version=17
@update_header

ALTER TABLE customer_options ADD (OVERRIDE_SEND_QI_PATH VARCHAR2(2000));

update customer_options set OVERRIDE_SEND_QI_PATH = 'QuestionnaireInvitation2.acds' where CHAIN_IMPLEMENTATION = 'MAERSK';

@update_tail
