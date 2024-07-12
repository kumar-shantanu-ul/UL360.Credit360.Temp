-- Please update version.sql too -- this keeps clean builds in sync
define version=1627
@update_header


@../pending_pkg
@../delegation_pkg

@../pending_body
@../delegation_body
							 
@update_tail


