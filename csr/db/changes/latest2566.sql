-- Please update version.sql too -- this keeps clean builds in sync
define version=2566
@update_header

@..\role_pkg
@..\role_body

@update_tail