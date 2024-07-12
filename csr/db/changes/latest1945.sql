-- Please update version.sql too -- this keeps clean builds in sync
define version=1945
@update_header

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (54, 'Teamroom invitation',
  'A teamroom invitation is created.',
  'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'TEAMROOM_NAME', 'Teamroom name', 'The name of the teamroom the user has been invited to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'LINK', 'Link', 'A hyperlink to the invitation acceptance page', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'MESSAGE', 'Message', 'The message from the user the alert is being sent from', 5);

UPDATE csr.calendar
SET js_include = '/csr/shared/calendar/includes/issues.js'
WHERE js_include = '/csr/site/calendar/includes/issues.js';

UPDATE csr.calendar
SET js_include = '/csr/shared/calendar/includes/audits.js'
WHERE js_include = '/csr/site/calendar/includes/audits.js';

@update_tail
