-- Please update version.sql too -- this keeps clean builds in sync
define version=2579
@update_header

begin
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (56, 'Section document now available notification',
		'A document for a section has been checked in and is now available for user to change.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  
exception
	when dup_val_on_index then
		null;
end;
/
begin
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'TO_FULLNAME', 'To Full Name', 'The user that requested to be alerted.', 1);
exception
	when dup_val_on_index then
		update csr.std_alert_type_param
		   set display_pos = 1
		 where std_alert_type_id = 56 and field_name = 'TO_FULLNAME';
end;
/
begin
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'FIN_FULLNAME', 'Full Name', 'The user that has finished editing the document.', 2);
exception
	when dup_val_on_index then
		update csr.std_alert_type_param
		   set display_pos = 2
		 where std_alert_type_id = 56 and field_name = 'FIN_FULLNAME';
end;
/


begin
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 3);
exception
	when dup_val_on_index then
		update csr.std_alert_type_param
		   set display_pos = 3
		 where std_alert_type_id = 56 and field_name = 'TO_FRIENDLY_NAME';
end;
/

begin
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'FILENAME', 'Filename', 'The file that has become available for editing.', 4);
exception
	when dup_val_on_index then
		update csr.std_alert_type_param
		   set display_pos = 4
		 where std_alert_type_id = 56 and field_name = 'FILENAME';
end;
/

begin
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'QUESTION_LABEL', 'Question Name', 'The questions title.', 5);
exception
	when dup_val_on_index then
		update csr.std_alert_type_param
		   set display_pos = 5
		 where std_alert_type_id = 56 and field_name = 'QUESTION_LABEL';
end;
/

@update_tail
