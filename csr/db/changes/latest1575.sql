-- Please update version.sql too -- this keeps clean builds in sync
define version=1575
@update_header

ALTER TABLE csr.dataview ADD rank_limit_left_type          NUMBER(10, 0)      DEFAULT 0 NOT NULL;
ALTER TABLE csr.dataview ADD rank_limit_right_type         NUMBER(10, 0)      DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.dataview ADD rank_limit_left_type       NUMBER(10, 0)      DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.dataview ADD rank_limit_right_type      NUMBER(10, 0)      DEFAULT 0 NOT NULL;

@../dataview_pkg
@../dataview_body
@../csrimp/imp_body
@../schema_body

@update_tail
