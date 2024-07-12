-- Please update version.sql too -- this keeps clean builds in sync
define version=1816
@update_header

ALTER TABLE csr.customer ADD (translation_checkbox NUMBER(1) DEFAULT 0 NOT NULL);

@update_tail