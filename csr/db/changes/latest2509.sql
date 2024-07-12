-- Please update version.sql too -- this keeps clean builds in sync
define version=2509
@update_header

alter table csr.ind modify lookup_key varchar2(255);
alter table csrimp.ind modify lookup_key varchar2(255);

@update_tail