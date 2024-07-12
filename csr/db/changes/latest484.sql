-- Please update version.sql too -- this keeps clean builds in sync
define version=484
@update_header

ALTER TABLE attachment
	ADD url VARCHAR2(1023) NULL;

@update_tail
