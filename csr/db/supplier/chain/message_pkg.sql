CREATE OR REPLACE PACKAGE SUPPLIER.message_pkg
IS

SUBTYPE T_MESSAGE_TEMPLATE_FORMAT	IS MESSAGE_TEMPLATE_FORMAT.MESSAGE_TEMPLATE_FORMAT_ID%TYPE;
MTF_TEXT_ONLY						CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 0;
MTF_USER_COMPANY					CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 1;
MTF_USER_USER_COMPANY				CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 2;
MTF_USER_CONTACT_QNAIRE				CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 3;
MTF_USER_SUPPLIER_QNAIRE			CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 4;
MTF_USER_PROCURER_QNAIRE			CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 5;
MTF_SUPPLIER_QNAIRE					CONSTANT T_MESSAGE_TEMPLATE_FORMAT := 6;


SUBTYPE T_MESSAGE_TEMPLATE			IS MESSAGE_TEMPLATE.MESSAGE_TEMPLATE_ID%TYPE;
MT_WELCOME_MESSAGE					CONSTANT T_MESSAGE_TEMPLATE := 0;--  Welcome to the CHAIN!
MT_JOIN_COMPANY_REQUEST				CONSTANT T_MESSAGE_TEMPLATE := 1;--  {0} would like to be added as a user to {1}
MT_JOIN_COMPANY_GRANTED				CONSTANT T_MESSAGE_TEMPLATE := 2;--  {0} has added {1} as a user to {2}
MT_JOIN_COMPANY_DENIED				CONSTANT T_MESSAGE_TEMPLATE := 3;--  {0} has denied your request to be added as a user to {1}
MT_CONTACT_QI						CONSTANT T_MESSAGE_TEMPLATE := 4;--  {0} has invited {1} to complete the {2} questionnaire
MT_CONTACT_QI_REMINDER				CONSTANT T_MESSAGE_TEMPLATE := 5;--  {0} has reminded {1} to complete the {2} questionnaire
MT_CONTACT_QI_CANCELLED				CONSTANT T_MESSAGE_TEMPLATE := 6;--  {0} has cancelled the request for {1} to complete the {2} questionnaire
MT_QUESTIONNAIRE_REMINDER			CONSTANT T_MESSAGE_TEMPLATE := 7;--  {0} has reminded {1} to complete the {2} questionnaire
MT_ACCEPT_QUESTIONNAIRE				CONSTANT T_MESSAGE_TEMPLATE := 8;--  {0} has accepted the invitation from {1} to complete the {2} questionnaire
MT_QUESTIONNAIRE_ACCEPTED			CONSTANT T_MESSAGE_TEMPLATE := 9;--  {1} has accepted the invitation from {0} to complete the {2} questionnaire
MT_QUESTIONNAIRE_RECEIVED			CONSTANT T_MESSAGE_TEMPLATE := 10;-- {0} has released the {2} questionnaire that was requested by {1}
MT_QUESTIONNAIRE_RELEASED			CONSTANT T_MESSAGE_TEMPLATE := 11;-- {1} has released {2} questionnaire as requested by {0}
MT_SUPPLIER_REMINDER				CONSTANT T_MESSAGE_TEMPLATE := 12;-- {0} has reminded {1} to complete the {2} questionnaire

SUBTYPE T_MESSAGE_ID_TYPE			IS NUMBER;
MIDT_CONTACT						CONSTANT T_MESSAGE_ID_TYPE := 0;
MIDT_PROCURER						CONSTANT T_MESSAGE_ID_TYPE := 1;
MIDT_SUPPLIER						CONSTANT T_MESSAGE_ID_TYPE := 2;

/*
	Flavours of CreateMessage to save us from having to update loads of stuff when adding a new MTF
*/ 

-- MTF_TEXT_ONLY
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE
);

-- MTF_USER_COMPANY
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID
);

-- MTF_USER_USER_COMPANY
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid_1			IN  security_pkg.T_SID_ID,
	in_user_sid_2			IN  security_pkg.T_SID_ID
);

-- MTF_USER_CONTACT_QNAIRE, MTF_USER_SUPPLIER_QNAIRE, MTF_USER_PROCURER_QNAIRE
PROCEDURE CreateMessage (
	in_message_tpl_id		IN  T_MESSAGE_TEMPLATE,
	in_to_company_sid		IN  security_pkg.T_SID_ID,
	in_to_user_sid			IN  security_pkg.T_SID_ID,
	in_to_group_type		IN  company_group_pkg.T_GROUP_TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	in_id					IN  security_pkg.T_SID_ID,
	in_id_type				IN  T_MESSAGE_ID_TYPE
);


PROCEDURE GetMessages (
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);


END message_pkg;
/