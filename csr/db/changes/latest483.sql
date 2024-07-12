-- Please update version.sql too -- this keeps clean builds in sync
define version=483
@update_header

alter table csr.customer_alert_type add reply_to_name varchar2(255) null;

alter table csr.customer_alert_type add reply_to_email varchar2(255) null;

@..\alert_pkg.sql
@..\alert_body.sql

@update_tail
