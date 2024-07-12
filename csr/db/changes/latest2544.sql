-- Please update version.sql too -- this keeps clean builds in sync
define version=2544
@update_header

ALTER TABLE csr.sheet ADD is_copied_forward NUMBER(1, 0) DEFAULT 0 NOT NULL;

@../sheet_body

@update_tail
