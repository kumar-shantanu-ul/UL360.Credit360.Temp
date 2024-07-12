-- Please update version.sql too -- this keeps clean builds in sync
define version=507
@update_header

ALTER TABLE ind
	ADD NORMALIZE NUMBER(1, 0) DEFAULT 0 NOT NULL;

@..\dataview_pkg.sql
@..\indicator_pkg.sql

@..\delegation_body.sql
@..\datasource_body.sql
@..\dataview_body.sql
@..\indicator_body.sql
@..\measure_body.sql
@..\pending_body.sql
@..\pending_datasource_body.sql
@..\range_body.sql
@..\schema_body.sql

@update_tail
