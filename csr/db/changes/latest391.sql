-- Please update version.sql too -- this keeps clean builds in sync
define version=391
@update_header

ALTER TABLE csr.dataview DROP COLUMN hide_ind_folders;

@..\dataview_pkg.sql
@..\dataview_body.sql
@..\datasource_body.sql
@..\schema_body.sql

@update_tail
