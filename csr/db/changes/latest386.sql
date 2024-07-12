-- Please update version.sql too -- this keeps clean builds in sync
define version=386
@update_header

ALTER TABLE csr.dataview ADD include_parent_region_names NUMBER(10) DEFAULT 0 NOT NULL;

@../dataview_pkg.sql
@../dataview_body.sql

@update_tail
