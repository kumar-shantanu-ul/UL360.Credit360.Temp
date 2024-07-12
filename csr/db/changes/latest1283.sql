-- Please update version.sql too -- this keeps clean builds in sync
define version=1283
@update_header

@..\delegation_pkg
@..\delegation_body

@update_tail
