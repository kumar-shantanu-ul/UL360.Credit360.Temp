create or replace package supplier.revision_pkg
IS

PROCEDURE CreateNewProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE,
	out_new_rev						OUT product_revision.revision_id%TYPE
);
	

-- Currently this is only called internally
PROCEDURE CreateNewProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	out_new_rev						OUT product_revision.revision_id%TYPE
);

PROCEDURE EditProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE
);
	
	
-- Currently this is only called internally
PROCEDURE EditProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE
);

PROCEDURE DeleteProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE
);	

-- Currently this is only called internally
PROCEDURE DeleteProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE
);

--only called internally, only to revert tags to last revision
PROCEDURE DeleteProductTagRevision(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN all_product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE
);

PROCEDURE GetProductRevisions(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_start						IN NUMBER,
	in_page_size					IN NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductRevisionsCount(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	out_count						OUT NUMBER
);

PROCEDURE GetProductRevisionQuestion(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

END revision_pkg;
/
