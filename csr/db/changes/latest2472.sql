-- Please update version.sql too -- this keeps clean builds in sync
define version=2472
@update_header

alter table csr.delegation modify name null;

@../delegation_body

@update_tail
