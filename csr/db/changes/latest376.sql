-- Please update version.sql too -- this keeps clean builds in sync
define version=376
@update_header

ALTER TABLE pending_ind ADD (allow_file_upload NUMBER(1) DEFAULT 1 NOT NULL);

@..\pending_pkg.sql
@..\pending_body.sql
@..\pending_datasource_body.sql

@update_tail
