-- Please update version.sql too -- this keeps clean builds in sync
define version=59
@update_header


ALTER TABLE CUSTOMER ADD (
	FILTER_RECIPIENT_REGIONGP	NUMBER(1)	NULL
);

-- Default filter state is off
UPDATE customer
   SET filter_recipient_regiongp = 0;

-- Do not allow nulls
ALTER TABLE CUSTOMER MODIFY (
	FILTER_RECIPIENT_REGIONGP	NUMBER(1)	NOT NULL
);

COMMIT;

@update_tail
