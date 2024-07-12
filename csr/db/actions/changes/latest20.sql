-- Please update version.sql too -- this keeps clean builds in sync
define version=20
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	SHOW_WEIGHTINGS	NUMBER(1,0)	DEFAULT 0	NOT NULL
);

@update_tail