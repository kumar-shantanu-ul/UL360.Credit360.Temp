-- Please update version.sql too -- this keeps clean builds in sync
define version=2708
@update_header

drop index csr.ix_non_comp_label_search ;

alter table csr.non_compliance modify label varchar2(2048);
alter table csrimp.non_compliance modify label varchar2(2048);

grant create table to csr;
create index csr.ix_non_comp_label_search on csr.non_compliance(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
revoke create table from csr;

@update_tail
