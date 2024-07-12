-- Please update version.sql too -- this keeps clean builds in sync
define version=2590
@update_header

@../chain/purchased_component_pkg
@../chain/purchased_component_body

@update_tail


