-- Please update version.sql too -- this keeps clean builds in sync
define version=1976
@update_header

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (55, 'Teamroom membership termination',
  'A user is removed from a teamroom.',
  'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (55, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (55, 0, 'TEAMROOM_NAME', 'Teamroom name', 'The name of the teamroom the user has been removed from', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (55, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 3);

@update_tail
