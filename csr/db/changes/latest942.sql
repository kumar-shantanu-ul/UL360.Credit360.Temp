-- Please update version.sql too -- this keeps clean builds in sync
define version=942
@update_header


ALTER TABLE donations.CUSTOMER_OPTIONS ADD SHOW_ALL_YEARS_BY_DEFAULT NUMBER(1, 0) DEFAULT 0 NOT NULL;

@..\donations\options_body


@update_tail