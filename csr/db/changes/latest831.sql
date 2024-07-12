-- Please update version.sql too -- this keeps clean builds in sync
define version=831
@update_header

ALTER TABLE csr.customer ADD allow_make_editable NUMBER(1) DEFAULT(1) NOT NULL;

@update_tail