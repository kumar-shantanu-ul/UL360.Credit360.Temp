-- Please update version.sql too -- this keeps clean builds in sync
define version=485
@update_header

ALTER TABLE factor_type
	ADD egrid NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
