-- Please update version.sql too -- this keeps clean builds in sync
define version=1463
@update_header

ALTER TABLE CSR.IMPORT_FEED_REQUEST DROP COLUMN ERRORS;

ALTER TABLE CSR.IMPORT_FEED_REQUEST ADD (
	ERRORS		NUMBER(10) NULL
);

@..\import_feed_pkg
@..\import_feed_body

@update_tail