define version=84
@update_header

ALTER TABLE chain.customer_options ADD (allow_new_user_request NUMBER(1) DEFAULT 0 NOT NULL);

UPDATE chain.customer_options
   SET allow_new_user_request=1
 WHERE chain_implementation='MAERSK';

@..\chain_body

@update_tail