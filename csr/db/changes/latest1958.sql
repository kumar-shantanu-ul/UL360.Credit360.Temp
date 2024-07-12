-- Please update version.sql too -- this keeps clean builds in sync
define version=1958
@update_header

ALTER TABLE csr.calendar ADD IS_GLOBAL NUMBER(1, 0) DEFAULT 1 NOT NULL;
ALTER TABLE csr.calendar ADD APPLIES_TO_TEAMROOMS NUMBER(1, 0) DEFAULT 0 NOT NULL;

@..\calendar_pkg
@..\teamroom_pkg

@..\calendar_body
@..\teamroom_body

@update_tail