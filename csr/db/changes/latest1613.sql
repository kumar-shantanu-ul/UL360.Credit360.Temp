-- Please update version.sql too -- this keeps clean builds in sync
define version=1613
@update_header

ALTER TABLE csr.delegation ADD hide_sheet_period NUMBER(1, 0) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.delegation ADD hide_sheet_period NUMBER(1, 0);

UPDATE csrimp.delegation SET hide_sheet_period = 0;

ALTER TABLE csrimp.delegation MODIFY hide_sheet_period NOT NULL;

@../delegation_body
@../schema_body
@../csrimp/imp_body
@update_tail
