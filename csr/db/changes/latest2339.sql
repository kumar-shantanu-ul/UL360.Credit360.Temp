-- Please update version.sql too -- this keeps clean builds in sync
define version=2339
@update_header

@..\indicator_body
@..\region_body

@update_tail
