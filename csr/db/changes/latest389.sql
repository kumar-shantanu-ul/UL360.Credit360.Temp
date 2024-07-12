-- Please update version.sql too -- this keeps clean builds in sync
define version=389
@update_header

ALTER TABLE csr.dataview ADD hide_ind_folders NUMBER(1) DEFAULT 1 NOT NULL;

@../dataview_pkg.sql
@../dataview_body.sql
@../datasource_body.sql

@update_tail
