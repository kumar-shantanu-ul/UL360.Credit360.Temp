-- Please update version.sql too -- this keeps clean builds in sync
define version=57
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	INITIATIVE_REMINDER_ALERTS		NUMBER(1,0)	DEFAULT 0 NOT NULL,
		CHECK (INITIATIVE_REMINDER_ALERTS IN (0,1))
);

@update_tail
