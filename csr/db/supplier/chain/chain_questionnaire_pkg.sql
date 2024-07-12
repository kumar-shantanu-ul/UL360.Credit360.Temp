CREATE OR REPLACE PACKAGE SUPPLIER.chain_questionnaire_pkg
IS

SUBTYPE T_REQUEST_STATUS 			IS REQUEST_STATUS.REQUEST_STATUS_ID%TYPE;
RS_PENDING_ACCEPT					CONSTANT T_REQUEST_STATUS := 0;
RS_ACCEPTED							CONSTANT T_REQUEST_STATUS := 1;
RS_SHARED							CONSTANT T_REQUEST_STATUS := 2;
	
SUBTYPE T_RESPONSE_STATUS 			IS QUESTIONNAIRE_RESPONSE_STATUS.RESPONSE_STATUS_ID%TYPE;
QRS_NOT_COMPLETE					CONSTANT T_RESPONSE_STATUS := 0;
QRS_SUBMITTED_FOR_APPROVAL			CONSTANT T_RESPONSE_STATUS := 1;
QRS_APPPROVED_FOR_RELEASE			CONSTANT T_RESPONSE_STATUS := 2;


SUBTYPE T_ORDER_BY IS NUMBER(10);
OB_COMPANY							CONSTANT T_ORDER_BY := 0;
OB_QUESTIONNAIRE					CONSTANT T_ORDER_BY := 1;

PROCEDURE GetQuestionnaires (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaire (
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatusSummary(
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireOutbox ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_procurer_user_sid  	IN  company_user.csr_user_sid%TYPE,
	in_procurer_company_sid	IN  company_user.company_sid%TYPE,
	in_request_status_id	IN  T_REQUEST_STATUS,	
	in_order_by				IN  T_ORDER_BY,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetQuestionnaireInbox ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_supplier_user_sid  	IN  company_user.csr_user_sid%TYPE,
	in_supplier_company_sid	IN  company_user.company_sid%TYPE,
	in_request_status_id	IN  T_REQUEST_STATUS,	
	in_order_by				IN  T_ORDER_BY,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetQuickSurveyResults (
	in_survey_sid			IN  security_pkg.T_SID_ID,
	in_flag					IN  varchar2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SubmitQuestionnaire (
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE
);

PROCEDURE ReleaseQuestionnaire (
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	in_procurer_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE SendingReminder (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_questionnaire_id		IN  invite_questionnaire.chain_questionnaire_id%TYPE,
	out_cur_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur		OUT security_pkg.T_OUTPUT_CUR
);



END chain_questionnaire_pkg;
/

