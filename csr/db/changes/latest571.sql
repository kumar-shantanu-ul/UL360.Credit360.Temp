-- Please update version.sql too -- this keeps clean builds in sync
define version=571
@update_header

ALTER TABLE excel_export_options
	ADD region_show_egrid NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
