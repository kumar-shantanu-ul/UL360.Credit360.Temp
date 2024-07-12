CREATE OR REPLACE PACKAGE SUPPLIER.invite_pkg
IS

SUBTYPE T_INVITE_STATUS			IS INVITE.INVITE_STATUS_ID%TYPE;
INVITE_SENT						CONSTANT T_INVITE_STATUS := 0;
INVITE_CANCELLED				CONSTANT T_INVITE_STATUS := 1;
INVITE_ACCEPTED					CONSTANT T_INVITE_STATUS := 2;
INVITE_REJECTED					CONSTANT T_INVITE_STATUS := 3;

TYPE   T_CONTACT_IDS			IS TABLE OF contact.contact_id%TYPE INDEX BY PLS_INTEGER;
TYPE   T_QUESTIONAIRE_IDS		IS TABLE OF chain_questionnaire.chain_questionnaire_id%TYPE INDEX BY PLS_INTEGER;
TYPE   T_VARCHAR    			IS TABLE OF VARCHAR2(8) INDEX BY PLS_INTEGER;

PROCEDURE AddQuestionnaireInvite (
	in_contact_ids			IN  T_CONTACT_IDS,
	in_questionnaire_ids	IN  T_QUESTIONAIRE_IDS,
	in_due_dates			IN  T_VARCHAR,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SendingReminder (
	in_invite_id			IN  invite_questionnaire.invite_id%TYPE,
	in_questionnaire_id		IN  invite_questionnaire.chain_questionnaire_id%TYPE,
	out_cur_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_contact_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CancelInvite (
	in_invite_id			IN  invite.invite_id%TYPE
);

PROCEDURE GetInvitesForGuid (
	in_contact_guid			IN  contact.contact_guid%TYPE,
	out_invite_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_contact_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetContactByGuid (
	in_contact_guid			IN  contact.contact_guid%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END invite_pkg;
/
