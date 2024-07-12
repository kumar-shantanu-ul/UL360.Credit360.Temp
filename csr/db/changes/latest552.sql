-- Please update version.sql too -- this keeps clean builds in sync
define version=552
@update_header

ALTER TABLE delegation_region ADD CONSTRAINT CK_DELEG_REGION_VISIBLE CHECK (VISIBILITY IN ('SHOW', 'HIDE', 'READONLY'));

@@..\delegation_pkg
@@..\delegation_body

@update_tail
