-- Please update version.sql too -- this keeps clean builds in sync
define version=863
@update_header

alter table csr.ind add calc_fixed_start_dtm date;
alter table csr.ind add calc_fixed_end_dtm date;
 
@../datasource_body
@../dataview_body
@../delegation_body
@../indicator_body
@../pending_body
@../pending_datasource_body
@../range_body
@../schema_body
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../val_datasource_body

@update_tail
