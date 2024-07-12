CREATE OR REPLACE PACKAGE nn_supplier_pkg
IS
	
PART_MAN_SITE_CLASS_NAME		CONSTANT VARCHAR2(255) := 'NN_PART_MANUFACTURING_SITE';

PROCEDURE GetAnswers(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAnswersAndAssocProducts(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_answers					OUT security_pkg.T_OUTPUT_CUR,
	out_assoc_products			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAnswers(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	in_manufacturing_cats		IN nn_supplier_answers.manufacturing_cats%TYPE,
	in_notes					IN nn_supplier_answers.notes%TYPE,
	in_doc_group_id				IN nn_supplier_answers.document_group_id%TYPE,
	in_other_product_info		IN nn_supplier_answers.other_product_info%TYPE
);

PROCEDURE GetManufacturingSites(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

END nn_supplier_pkg;
/
