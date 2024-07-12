-- Please update version.sql too -- this keeps clean builds in sync
define version=902
@update_header

ALTER TABLE csr.section ADD help_text CLOB;

@update_tail
