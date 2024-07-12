-- Please update version.sql too -- this keeps clean builds in sync
define version=910
@update_header

BEGIN
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2005,
	'Initiative submitted to GES',
	NULL,
	'An initiative is submitted at the GES level.',
	'The submitting user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2006,
	'Initiative submitted to regional co-ordinator',
	NULL,
	'An initiative is submitted at the regional co-ordinator level.',
	'The submitting user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2007,
	'More information required',
	NULL,
	'The initiative is returned to the owner for more information',
	'The reviewing user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2008,
	'Initiative is a duplicate',
	NULL,
	'The initiative has been deemed to be a duplicate and has been rejected',
	'The reviewing user.');

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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2009,
	'Initiative not validated',
	NULL,
	'The initiative has been rejected for some reason',
	'The reviewing user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2010,
	'Initiative not approved',
	NULL,
	'The initiative has been rejected for some reason.',
	'The reviewing user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2011,
	'Pending business case',
	NULL,
	'The initiative has been returned to the owner pending a business case.',
	'The reviewing user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2012,
	'Initiative approved',
	NULL,
	'The initiative has been approved and is active',
	'The reviewing user.');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN	
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2013,
	'Initiatives periodic reminder',
	NULL,
	'Periodically, the recurrence schedule is configurable.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2016,
	'Initiative approved',
	NULL,
	'The initiative has been approved and is active.',
	'The reviewing user.');
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'SUBMITTED_BY_FULL_NAME',
	'Submitted by full name',
	'The full name of the submitting user',
	0,
	1);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'SUBMITTED_BY_FRIENDLY_NAME',
	'Submitted by friendly name',
	'The friendly name of the submitting user',
	0,
	2);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'SUBMITTED_BY_USER_NAME',
	'Submitted user name',
	'The user name of the submitting user',
	0,
	3);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'SUBMITTED_BY_EMAIL',
	'Submitted e-Mmail',
	'The e-mail address of the submitting user',
	0,
	4);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'TO_FULL_NAME',
	'Recipient full name',
	'The full name of the user who is responsible for the next action on the initiative',
	0,
	5);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'TO_FRIENDLY_NAME',
	'Recipient friendly name',
	'The friendly name of the user who is responsible for the next action on the initiative',
	0,
	6);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'TO_USER_NAME',
	'Recipient user name',
	'The user name of the user who is responsible for the next action on the initiative',
	0,
	7);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'TO_EMAIL',
	'Recipient e-mail',
	'The e-mail address of the user who is responsible for the next action on the initiative',
	0,
	8);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'NAME',
	'Name',
	'The initiative name',
	0,
	9);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'REFERENCE',
	'Reference',
	'The initiative reference',
	0,
	10);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'INITIATIVE_SUB_TYPE',
	'Type',
	'The initiative type',
	0,
	11);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'START_DTM',
	'Start date',
	'The initiative start date',
	0,
	12);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'END_DTM',
	'End date',
	'The initiative end date',
	0,
	13);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'VIEW_URL',
	'View link',
	'A link to the initiative',
	0,
	14);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'REGION_DESC',
	'Property',
	'The property the initiative relates to',
	0,
	15);
	INSERT INTO "CSR"."STD_ALERT_TYPE_PARAM" (
	STD_ALERT_TYPE_ID, FIELD_NAME, DESCRIPTION, HELP_TEXT, REPEATS, DISPLAY_POS) VALUES (2016,
	'COMMENT',
	'Comment',
	'The comment entered by the reviewing user',
	0,
	16);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2017,
	'Initiatives reminder (to owners)',
	NULL,
	'Periodically, to the owner of an initiative. The recurrence schedule is configurable.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/


BEGIN
	INSERT INTO "CSR"."STD_ALERT_TYPE" (
	STD_ALERT_TYPE_ID, DESCRIPTION, PARENT_ALERT_TYPE_ID, SEND_TRIGGER, SENT_FROM) VALUES (2018,
	'Initiatives reminder (next action)',
	NULL,
	'Periodically, to the person(s) responsible for actioning the initiative in its current state. The recurrence schedule is configurable.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
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
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail
