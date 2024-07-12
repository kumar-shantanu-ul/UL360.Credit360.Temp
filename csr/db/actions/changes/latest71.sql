-- Please update version.sql too -- this keeps clean builds in sync
define version=71
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	GANTT_PERIOD_COLOUR              NUMBER(1, 0)      DEFAULT 0 NOT NULL
                                     CHECK (GANTT_PERIOD_COLOUR IN (0,1))
);

@../options_body
	
@update_tail
