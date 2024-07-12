-- Please update version.sql too -- this keeps clean builds in sync
define version=1141
@update_header

ALTER TABLE CT.WORKSHEET_COLUMN_TYPE RENAME COLUMN JS_KEY TO KEY;

@..\ct\excel_pkg
@..\ct\excel_body

@update_tail
