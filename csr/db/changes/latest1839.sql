-- Please update version too -- this keeps clean builds in sync
define version=1839
@update_header

ALTER TABLE chain.customer_options ADD (company_user_create_alert NUMBER(1));
UPDATE chain.customer_options SET company_user_create_alert = 0;
ALTER TABLE chain.customer_options MODIFY company_user_create_alert DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options DROP COLUMN xxx_chain_implementation;
ALTER TABLE chain.customer_options DROP COLUMN xxx_company_helper_sp;

BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5019,
			'Chain Create User',
			'A user has been created from the company details, create user tab.',
			'The user that created the new user.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain Create User',
				send_trigger = 'A user has been created from the company details, create user tab.',
				sent_from = 'The user that created the new user.'
			WHERE std_alert_type_id = 5019;
END;
/
@../chain/helper_body

@update_tail
