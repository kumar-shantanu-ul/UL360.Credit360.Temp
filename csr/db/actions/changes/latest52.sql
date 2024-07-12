-- Please update version.sql too -- this keeps clean builds in sync
define version=52
@update_header


ALTER TABLE PROJECT_IND_TEMPLATE ADD (
	POS_GROUP            NUMBER(10, 0)     DEFAULT 0 NOT NULL
);

@update_tail
