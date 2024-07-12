-- Please update version.sql too -- this keeps clean builds in sync
define version=2768
define minor_version=0
@update_header

@..\objective_pkg
@..\objective_body

@update_tail
