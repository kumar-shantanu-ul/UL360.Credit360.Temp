-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=3
@update_header

alter table csr.temp_delegation_detail add rid number(10);
alter table csr.temp_delegation_detail add root_delegation_sid number(10);
alter table csr.temp_delegation_detail add parent_sid number(10);

@../delegation_pkg
@../pending_pkg
@../delegation_body
@../pending_body

@update_tail
