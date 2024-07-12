-- Please update version.sql too -- this keeps clean builds in sync
define version=1729
@update_header

@..\chain\setup_pkg
@..\chain\setup_body
@..\supplier_body

@update_tail
