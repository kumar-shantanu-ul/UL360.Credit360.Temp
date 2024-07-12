-- Please update version.sql too -- this keeps clean builds in sync
define version=355
@update_header

ALTER TABLE METER_SOURCE_TYPE ADD (
	REFERENCE_MANDATORY        NUMBER(1, 0)     DEFAULT 1 NOT NULL,
	CHECK (REFERENCE_MANDATORY IN (0,1))
);

@update_tail
