-- Please update version.sql too -- this keeps clean builds in sync
define version=551
@update_header

ALTER TABLE customer ADD helper_pkg VARCHAR2(255);
ALTER TABLE delegation_region ADD visibility VARCHAR2(255) DEFAULT 'SHOW' NOT NULL;

@@..\delegation_pkg
@@..\delegation_body
@@..\sheet_body

@update_tail
