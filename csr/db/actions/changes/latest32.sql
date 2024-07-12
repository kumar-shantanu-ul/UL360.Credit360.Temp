-- Please update version.sql too -- this keeps clean builds in sync
define version=32
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD(
	ACTION_GRID_PATH	VARCHAR2(1024) 	NULL
);

@update_tail
