-- Please update version.sql too -- this keeps clean builds in sync
define version=2578
@update_header

@..\indicator_pkg
@..\indicator_body
@..\region_pkg
@..\region_body
@..\dataview_pkg
@..\dataview_body
@..\stored_calc_datasource_pkg
@..\stored_calc_datasource_body

@update_tail
