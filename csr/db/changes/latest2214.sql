-- Please update version.sql too -- this keeps clean builds in sync
define version=2214
@update_header

grant execute on mail.smtp_pkg to csr, web_user;
grant insert, delete, update on mail.temp_message to csr;
grant delete on mail.temp_message_address_field to csr, web_user;
grant delete on mail.temp_message_header to csr, web_user;
grant insert, update on mail.temp_message to web_user;

@update_tail