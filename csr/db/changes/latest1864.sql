-- Please update version.sql too -- this keeps clean builds in sync
define version=1864
@update_header

/* Restrict email domains, when updating users, to the email domain stubs set for the company */
ALTER TABLE chain.customer_options ADD(
	restrict_change_email_domains     		NUMBER(1, 0)   --   DEFAULT 0 NOT NULL,
	CONSTRAINT chk_co_restrict_email_domains CHECK (restrict_change_email_domains IN (0, 1))
);
UPDATE chain.customer_options SET restrict_change_email_domains = 0;
ALTER TABLE chain.customer_options MODIFY restrict_change_email_domains DEFAULT 0 NOT NULL;

/* send alert when email changes customer option */
ALTER TABLE chain.customer_options ADD(
	send_change_email_alert     		NUMBER(1, 0)   --   DEFAULT 0 NOT NULL,
	CONSTRAINT chk_co_change_email_alert CHECK (send_change_email_alert IN (0, 1))
);
UPDATE chain.customer_options SET send_change_email_alert = 0;
ALTER TABLE chain.customer_options MODIFY send_change_email_alert DEFAULT 0 NOT NULL;

@../chain/helper_pkg
@../chain/company_user_pkg

@../chain/helper_body
@../chain/company_user_body

@update_tail