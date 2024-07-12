-- Please update version.sql too -- this keeps clean builds in sync
define version=1887
@update_header

-- FB32708 new scenario rule
@..\scenario_pkg
@..\scenario_body

@update_tail
