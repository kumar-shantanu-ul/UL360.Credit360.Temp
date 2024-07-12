-- Please update version.sql too -- this keeps clean builds in sync
define version=442
@update_header

alter table csr.customer_portlet modify app_sid default sys_context('SECURITY', 'APP');

@update_tail
