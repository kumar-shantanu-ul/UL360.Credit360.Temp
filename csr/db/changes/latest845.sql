-- Please update version.sql too -- this keeps clean builds in sync
define version=845
@update_header

ALTER TABLE CSR.TAB ADD OVERRIDE_POS NUMBER(10) NULL;

@..\portlet_pkg
@..\portlet_body

@update_tail
