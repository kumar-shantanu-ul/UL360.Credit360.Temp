-- Please update version.sql too -- this keeps clean builds in sync
define version=1936
@update_header

insert into csr.std_alert_type_param(std_alert_type_id, field_name, description, help_text, repeats,display_pos)
values(5019, 'RESET_URL', 'Reset url', 'The URL for the user to reset the password', 0, 10);

@update_tail
