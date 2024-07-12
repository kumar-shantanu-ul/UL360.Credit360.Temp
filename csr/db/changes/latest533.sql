-- Please update version.sql too -- this keeps clean builds in sync
define version=533
@update_header

ALTER TABLE doc_current
	ADD pending_approval NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
