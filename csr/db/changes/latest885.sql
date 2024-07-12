-- Please update version.sql too -- this keeps clean builds in sync
define version=885
@update_header

alter table csr.customer add unmerged_consistent number(1) default 0;
alter table csr.customer add constraint ck_unmerged_consistent check (unmerged_consistent in (0,1));

@../val_datasource_body

@update_tail
