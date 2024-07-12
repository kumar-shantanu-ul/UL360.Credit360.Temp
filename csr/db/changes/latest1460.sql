-- Please update version.sql too -- this keeps clean builds in sync
define version=1460
@update_header

@..\chain\component_pkg
@..\chain\component_body

@..\chain\purchased_component_pkg
@..\chain\purchased_component_body

@update_tail