-- Please update version too -- this keeps clean builds in sync
define version=1834
@update_header

alter table csrimp.mail_mailbox drop column insert_serial;
alter table csrimp.mail_mailbox drop column delete_serial;
alter table csrimp.mail_mailbox drop column flags_serial;

@../../../yam/db/webmail_pkg
@../../../yam/db/webmail_body
@../../../yam/db/mailshot_pkg
@../../../yam/db/mailshot_body
@../../../yam/db/reader_body
@../csrimp/imp_body
@../flow_body
@../schema_body

@update_tail
