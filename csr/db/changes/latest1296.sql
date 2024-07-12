-- Please update version.sql too -- this keeps clean builds in sync
define version=1296
@update_header

drop table csrimp.map_delegation;
drop table csrimp.map_deleg_plan;
drop table csrimp.map_reporting_period;
drop table csrimp.map_role;

@../csrimp/imp_body

@update_tail
