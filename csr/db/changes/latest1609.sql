-- Please update version.sql too -- this keeps clean builds in sync
define version=1609
@update_header

ALTER TABLE csr.customer_portlet MODIFY app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');

@update_tail