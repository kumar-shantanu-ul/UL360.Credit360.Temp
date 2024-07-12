-- Please update version.sql too -- this keeps clean builds in sync
define version=309
@update_header

ALTER TABLE REGION ADD (
	LOOKUP_KEY VARCHAR2(64)
);

@update_tail
