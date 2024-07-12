-- Please update version.sql too -- this keeps clean builds in sync
define version=2326
@update_header

/* Show visibility options in edit user page*/
ALTER TABLE chain.customer_options ADD(
	enable_user_visibility_options	NUMBER(1, 0)   
	CONSTRAINT chk_co_visibility_options CHECK (enable_user_visibility_options IN (0, 1))
);

--leave it on for existing clients (although quite few of them already override it using an init_param)
UPDATE chain.customer_options SET enable_user_visibility_options = 1;

--disable it for future implementations
ALTER TABLE chain.customer_options MODIFY enable_user_visibility_options DEFAULT 0 NOT NULL;

@../chain/helper_pkg

@../chain/helper_body
@../chain/company_user_body

@update_tail