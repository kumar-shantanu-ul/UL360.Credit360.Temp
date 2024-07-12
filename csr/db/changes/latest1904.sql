-- Please update version.sql too -- this keeps clean builds in sync
define version=1904
@update_header

@..\val_datasource_body
@..\dataview_body
@..\delegation_body
@..\stored_calc_datasource_body
@..\range_body

@update_tail
