-- Please update version.sql too -- this keeps clean builds in sync
define version=791
@update_header

ALTER TABLE CSR.LOGISTICS_DEFAULT
	ADD DISTANCE_BREAKDOWN VARCHAR2(255) DEFAULT '0' NOT NULL;

@update_tail
