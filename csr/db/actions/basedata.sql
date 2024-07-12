
DECLARE 
	ALERT_GROUP_INITIATIVES	NUMBER(10) := 11;
BEGIN
	-- Initiative submitted alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
	VALUES (2000, 'Initiative submitted alert', 'An initiative is submitted.', 'The submitting user.', ALERT_GROUP_INITIATIVES);

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-mail', 'The e-mail address of the submitting user', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'NAME', 'Name', 'The initiative name', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2000, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
	
	-- Initiative approved alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(2001, 
	'Initiative approved alert', 'An initiative is approved.', 'The approving user.', ALERT_GROUP_INITIATIVES);

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-mail', 'The e-mail address of the submitting user', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'NAME', 'Name', 'The initiative name', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2001, 0, 'COMMENT', 'Comment', 'A comment made by the approver', 16);
	
	-- Initiative rejected alert	
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(2002, 
	'Initiative rejected alert', 'An initiative is rejected.', 'The rejecting user.', ALERT_GROUP_INITIATIVES);

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-mail', 'The e-mail address of the submitting user', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'NAME', 'Name', 'The initiative name', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2002, 0, 'COMMENT', 'Comment', 'A comment made by the approver', 16);
	
	-- Initiative reminder alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(2003, 
	'Initiative reminder alert', 'An initiative has not been approved or rejected for some time.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_INITIATIVES);

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-mail', 'The e-mail address of the submitting user', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'NAME', 'Name', 'The initiative name', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2003, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);

	-- Initiative Property Manager Alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
	VALUES(2004, 
	'Initiative Property Manager Alert',
	'On the first day of every month to relevant users.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2004, 0, 'REGION_DESC', 'Region description', 'The region description', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (2004, 0, 'INITIATIVE_LIST', 'Initiative list', 'The initiative list', 2);

	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2005,
	'Initiative submitted to GES',
	NULL,
	'An initiative is submitted at the GES level.',
	'The submitting user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2005,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);

	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2006,
	'Initiative submitted to regional co-ordinator',
	NULL,
	'An initiative is submitted at the regional co-ordinator level.',
	'The submitting user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2006,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2007,
	'More information required',
	NULL,
	'The initiative is returned to the owner for more information',
	'The reviewing user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2007,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);

	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2008,
	'Initiative is a duplicate',
	NULL,
	'The initiative has been deemed to be a duplicate and has been rejected',
	'The reviewing user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2008,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2009,
	'Initiative not validated',
	NULL,
	'The initiative has been rejected for some reason',
	'The reviewing user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2009,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2010,
	'Initiative not approved',
	NULL,
	'The initiative has been rejected for some reason.',
	'The reviewing user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2010,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2011,
	'Pending business case',
	NULL,
	'The initiative has been returned to the owner pending a business case.',
	'The reviewing user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2011,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);	
	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2012,
	'Initiative approved',
	NULL,
	'The initiative has been approved and is active',
	'The reviewing user.',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2012,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);
	
	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2013,
	'Initiatives periodic reminder',
	NULL,
	'Periodically, the recurrence schedule is configurable.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2013,
	'TO_NAME',
	'Recipient name',
	'The full name of the user who is responsible for the next action on the initiative.',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2013,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative.',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2013,
	'INITIATIVE_LIST',
	'Initiative list',
	'A list of the initiatives assigned to the user.',
	0,
	3);

	-- Newer (nore generic) submitted alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) 
		VALUES (2014, NULL, 'Initiative submitted', 'An initiative is submitted.', 'The submitting user.', ALERT_GROUP_INITIATIVES);
	
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

	
	-- Newer (nore generic) rejectedalert
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) 
		VALUES (2015, NULL, 'Initiative rejected (more information required)', 'The initiative is returned to the owner for more information.', 'The reviewing user.', ALERT_GROUP_INITIATIVES);
	
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
			
	
	-- Newer (nore generic) approved alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) 
		VALUES (2016, NULL, 'Initiative approved', 'The initiative has been approved and is active.', 'The reviewing user.', ALERT_GROUP_INITIATIVES);
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'NAME', 'Name', 'The initiative name', 0, 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2016, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);

	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2017,
	'Initiatives reminder (to owners)',
	NULL,
	'Periodically, to the owner of an initiative. The recurrence schedule is configurable.',
	'The configured system e-mail address (this defaults to no-reply@credit360.com, but can be changed from the site setup page).',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2017,
	'TO_NAME',
	'Recipient name',
	'The full name of the user who is responsible for the next action on the initiative.',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2017,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative.',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2017,
	'INITIATIVE_LIST',
	'Initiative list',
	'A list of the initiatives assigned to the user.',
	0,
	3);


	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2018,
	'Initiatives reminder (next action)',
	NULL,
	'Periodically, to the person(s) responsible for actioning the initiative in its current state. The recurrence schedule is configurable.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_INITIATIVES);
	
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2018,
	'TO_NAME',
	'Recipient name',
	'The full name of the user who is responsible for the next action on the initiative.',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2018,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative.',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2018,
	'INITIATIVE_LIST',
	'Initiative list',
	'A list of the initiatives assigned to the user.',
	0,
	3);

	-- Generic status change alert
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) 
		VALUES (2019, NULL, 'Initiative status changed', 'The initiative status has changed.', 'The user who changed the status.', ALERT_GROUP_INITIATIVES);
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'NAME', 'Name', 'The initiative name', 0, 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TRANSITION_NAME', 'Action', 'The action performed that caused the transition', 0, 17);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'FROM_STATUS_NAME', 'From status', 'The status the initiative was in before the action was taken', 0, 18);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_STATUS_NAME', 'To status', 'The status the initiative is in due to the action taken', 0, 19);

	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) 
		VALUES (2050, NULL, 'Project identified', 'The initiative is moved from the new to the project identified status.', 'The user who changed the status.', ALERT_GROUP_INITIATIVES);
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'NAME', 'Name', 'The initiative name', 0, 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2050, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);

	
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, std_alert_type_group_id) 
		VALUES (2051, NULL, 'Project evaluated', 'The initiative is moved from the project identified to the project evaluated status.', 'The user who changed the status.', ALERT_GROUP_INITIATIVES);
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'NAME', 'Name', 'The initiative name', 0, 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2051, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);


	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, DESCRIPTION, SEND_TRIGGER, SENT_FROM, std_alert_type_group_id) 
		VALUES (2052, NULL, 'Project validation', 'The initiative is moved from the completed to the validation status.', 'The user who changed the status.', ALERT_GROUP_INITIATIVES);
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'NAME', 'Name', 'The initiative name', 0, 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2052, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);

END;
/

COMMIT;
