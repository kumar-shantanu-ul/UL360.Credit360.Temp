-- Please update version.sql too -- this keeps clean builds in sync
define version=2175
@update_header

create index chain.ix_company_parent_company on chain.company(app_sid,parent_sid); 
 
@../supplier_body

@update_tail