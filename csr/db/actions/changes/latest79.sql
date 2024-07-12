-- Please update version.sql too -- this keeps clean builds in sync
define version=79
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	USE_STANDARD_REGION_PICKER       NUMBER(1, 0)      DEFAULT 0 NOT NULL
                                     CHECK (USE_STANDARD_REGION_PICKER IN(0,1))
);

@../options_body

@update_tail
