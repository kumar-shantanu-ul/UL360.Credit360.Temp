-- Please update version.sql too -- this keeps clean builds in sync
define version=1891
@update_header

@..\delegation_pkg
@..\delegation_body

@update_tail