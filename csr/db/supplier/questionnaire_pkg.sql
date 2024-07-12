CREATE OR REPLACE PACKAGE SUPPLIER.questionnaire_pkg 
IS

-- product status constants
QUESTIONNAIRE_OPEN				CONSTANT NUMBER(10) := 1;
QUESTIONNAIRE_CLOSED			CONSTANT NUMBER(10) := 2;

Q_WORKFLOW_SIMPLE			CONSTANT NUMBER(10) := 1;
Q_WORKFLOW_OPEN				CONSTANT NUMBER(10) := 2;
Q_WORKFLOW_SUPP_INVITE			CONSTANT NUMBER(10) := 3;

TYPE T_QUESTIONNAIRE_CLASSES IS TABLE OF questionnaire.class_name%TYPE INDEX BY VARCHAR2(256);

TYPE T_QUESTIONNAIRE_IDS IS TABLE OF questionnaire.questionnaire_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_Q_GROUP_IDS IS TABLE OF questionnaire_group.group_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE GetQuestionnaireInfo(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_questionnaire_id		IN 	questionnaire.questionnaire_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireInfo(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_class_name			IN 	questionnaire.class_name%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductGroupQuestionnaires(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_group_id					IN	questionnaire_group.group_id%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireIdByClass(
	in_class_name				IN  questionnaire.class_name%TYPE
) RETURN NUMBER;

PROCEDURE SetQuestionnaireStatus(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_questionnaire_id			IN	product_questionnaire.questionnaire_id%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE
);

PROCEDURE SetQuestionnaireStatus(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_class_name				IN	questionnaire.class_name%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE
);

PROCEDURE SetQuestStatusesForProdGroup(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_group_id					IN product_questionnaire_group.group_id%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE
);

PROCEDURE CopyQsToNewProd(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_old_product_id		IN product.product_id%TYPE,
	in_new_product_id		IN product.product_id%TYPE,
	in_package_name			IN 	questionnaire.class_name%TYPE
);

PROCEDURE CopyQsToNewProd(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_old_product_id		IN product.product_id%TYPE,
	in_new_product_id		IN product.product_id%TYPE,
	in_questionnaire_id		IN 	questionnaire.questionnaire_id%TYPE
);

PROCEDURE MapQuestionnaire(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_product_id			IN	all_product.product_id%TYPE
);

PROCEDURE SetQuestionnaireDueDate(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_product_id			IN	all_product.product_id%TYPE,
	in_questionnaire_id		IN	questionnaire.questionnaire_id%TYPE,
	in_due_date				IN  all_product_questionnaire.due_date%TYPE
);

END questionnaire_pkg;
/
