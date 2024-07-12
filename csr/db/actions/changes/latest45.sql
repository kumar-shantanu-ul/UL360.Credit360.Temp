-- Please update version.sql too -- this keeps clean builds in sync
define version=45
@update_header

ALTER TABLE PROJECT_IND_TEMPLATE ADD (
	DEFAULT_VALUE        NUMBER(24, 10)
);

@update_tail
