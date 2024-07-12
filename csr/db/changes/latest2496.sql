-- Please update version.sql too -- this keeps clean builds in sync
define version=2496
@update_header

begin
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM) 
		VALUES (2050, NULL, 'Project identified', 'The initiative is moved from the new to the project identified status.', 'The user who changed the status.');
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
exception
	when dup_val_on_index then
		null;
end;
/

begin
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'NAME', 'Name', 'The initiative name', 0, 9);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM) 
		VALUES (2051, NULL, 'Project evaluated', 'The initiative is moved from the project identified to the project evaluated status.', 'The user who changed the status.');
exception
	when dup_val_on_index then
		null;
end;
/

begin		
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'NAME', 'Name', 'The initiative name', 0, 9);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM) 
		VALUES (2052, NULL, 'Project validation', 'The initiative is moved from the completed to the validation status.', 'The user who changed the status.');
exception
	when dup_val_on_index then
		null;
end;
/

begin		
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'NAME', 'Name', 'The initiative name', 0, 9);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
exception
	when dup_val_on_index then
		null;
end;
/

begin	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);
exception
	when dup_val_on_index then
		null;
end;
/

@update_tail
