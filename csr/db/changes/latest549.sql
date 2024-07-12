-- Please update version.sql too -- this keeps clean builds in sync
define version=549
@update_header

alter table csr.customer_portlet add portal_group varchar2(50);
alter table csr.tab add portal_group varchar2(50);

@@..\portlet_pkg
@@..\portlet_body

@update_tail
