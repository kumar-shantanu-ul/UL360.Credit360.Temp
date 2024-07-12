-- Please update version.sql too -- this keeps clean builds in sync
define version=1760
@update_header

@../chain/component_pkg
@../chain/component_body
	
@update_tail