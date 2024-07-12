create or replace package supplier.gt_supplier_pkg
IS

PROCEDURE SetSupplierAnswers (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
  	in_gt_sus_relation_type_id  	IN gt_supplier_answers.gt_sus_relation_type_id%TYPE,
	in_sf_supplier_approach     	IN gt_supplier_answers.sf_supplier_approach%TYPE,
	in_sf_supplier_assisted     	IN gt_supplier_answers.sf_supplier_assisted%TYPE,
	in_sust_audit_desc          	IN gt_supplier_answers.sust_audit_desc%TYPE,
	in_sust_doc_group_id        	IN gt_supplier_answers.sust_doc_group_id%TYPE,
	in_data_quality_type_id           IN gt_product_answers.data_quality_type_id%TYPE
);

PROCEDURE GetSupplierAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupRelationTypes(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE IncrementRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
);

PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE
);

END gt_supplier_pkg;
/
