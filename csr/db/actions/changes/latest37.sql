-- Please update version.sql too -- this keeps clean builds in sync
define version=37
@update_header

@..\web_grants

@update_tail
