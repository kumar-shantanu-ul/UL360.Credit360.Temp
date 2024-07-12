-- Please update version.sql too -- this keeps clean builds in sync
define version=564
@update_header

ALTER TABLE excel_export_options
	ADD IND_SHOW_GAS_FACTOR NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
