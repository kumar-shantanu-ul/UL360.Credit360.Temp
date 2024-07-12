-- Please update version.sql too -- this keeps clean builds in sync
define version=2695
@update_header

@..\..\..\aspen2\db\utils_pkg
@..\..\..\aspen2\db\utils_body
@..\stored_calc_datasource_pkg
@..\stored_calc_datasource_body

@update_tail
