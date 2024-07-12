-- Please update version.sql too -- this keeps clean builds in sync
define version=21
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	SHOW_ACTION_TYPE		NUMBER(1,0)	DEFAULT 0	NOT NULL,
	GREYOUT_UNASSOC_TASKS	NUMBER(1,0)	DEFAULT 0	NOT NULL
);

@update_tail
