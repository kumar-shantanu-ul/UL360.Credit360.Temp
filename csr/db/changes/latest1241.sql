-- Please update version.sql too -- this keeps clean builds in sync
define version=1241
@update_header

ALTER TABLE csr.delegation ADD (show_aggregate NUMBER(1) DEFAULT 0 NOT NULL);

@../delegation_pkg
@../delegation_body

@update_tail
