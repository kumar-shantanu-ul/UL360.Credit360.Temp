-- Please update version.sql too -- this keeps clean builds in sync
define version=1583
@update_header

ALTER TABLE csr.dataview ADD rank_reverse NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.dataview ADD rank_reverse NUMBER(1) DEFAULT 0 NOT NULL;

@../dataview_pkg
@../dataview_body
@../schema_body
@../csrimp/imp_body

@update_tail
