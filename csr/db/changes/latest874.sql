-- Please update version.sql too -- this keeps clean builds in sync
define version=874
@update_header

alter table csr.customer add (alert_uri_format varchar2(250));

@../csr_app_body

@update_tail
