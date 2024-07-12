-- Please update version.sql too -- this keeps clean builds in sync
define version=264
@update_header

ALTER TABLE section_status ADD (ICON_PATH VARCHAR2(256));
@../text/section_status_body

@update_tail
