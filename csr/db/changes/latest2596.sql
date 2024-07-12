-- Please update version.sql too -- this keeps clean builds in sync
define version=2596
@update_header

-- Could skip this latest script if it blocks -- nothing too critical going on here

@..\dataview_pkg
@..\dataview_body

@..\region_pkg
@..\region_body

@update_tail
