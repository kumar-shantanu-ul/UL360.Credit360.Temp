-- Please update version.sql too -- this keeps clean builds in sync
define version=288
@update_header

ALTER TABLE DELEGATION ADD (
	IS_FLAG_MANDATORY       NUMBER(1, 0)     DEFAULT 0 NOT NULL
);
    

SET DEFINE OFF

@..\delegation_pkg
@..\delegation_body
@..\sheet_pkg
@..\sheet_body


SET DEFINE ON

@update_tail
