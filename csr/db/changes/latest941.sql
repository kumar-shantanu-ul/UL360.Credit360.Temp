-- Please update version.sql too -- this keeps clean builds in sync
define version=941
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from csr.std_alert_type
	 where std_alert_type_id = 2014;
	 
	if v_exists = 0 then
		-- Newer (nore generic) submitted alert
		INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM) 
			VALUES (2014, NULL, 'Initiative submitted', 'An initiative is submitted.', 'The submitting user.');
		
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'NAME', 'Name', 'The initiative name', 0, 9);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2014, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	end if;
	
	select count(*)
	  into v_exists
	  from csr.std_alert_type
	 where std_alert_type_id = 2015;
	
	if v_exists = 0 then
		-- Newer (nore generic) rejectedalert
		INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM) 
			VALUES (2015, NULL, 'Initiative rejected (more information required)', 'The initiative is returned to the owner for more information.', 'The reviewing user.');
		
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'NAME', 'Name', 'The initiative name', 0, 9);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2015, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);	
	end if;
end;
/

@update_tail
