create or replace package supplier.natural_product_pkg
IS

PROCEDURE SetProductAnswers(
	in_act					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	np_product_answers.product_id%TYPE,
	in_note					IN	np_product_answers.note%TYPE
);

PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE, -- not used yet
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE -- not used yet
);

PROCEDURE GetProductAnswers(
	in_act					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	np_product_answers.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

---------------------------------------

PROCEDURE GetKingdomList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductionProcessList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

END natural_product_pkg;
/