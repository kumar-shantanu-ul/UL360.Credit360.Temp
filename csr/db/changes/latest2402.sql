-- Please update version.sql too -- this keeps clean builds in sync
define version=2402
@update_header

@../schema_pkg
@../schema_body

@update_tail
