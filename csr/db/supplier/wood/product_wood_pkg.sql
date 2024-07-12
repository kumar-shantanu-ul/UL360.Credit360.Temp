create or replace package supplier.product_wood_pkg
IS

-- Wood specific product information retreval
PROCEDURE GetProductAnswers(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWoodTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

-- Wood specific data update/insert
PROCEDURE SetProductAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE
);

PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE, -- not used yet
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE -- not used yet
);

-- TODO: move these out into another package
PROCEDURE GetDocumentList(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_group_id			IN document_group.document_group_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDocumentData(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_id				IN document.document_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

END product_wood_pkg;
/
