create or replace package supplier.natural_product_evidence_pkg
IS

PART_EVIDENCE_DESCRIPTION_CLS	CONSTANT VARCHAR2(255) := 'NP_PART_EVIDENCE_DESCRIPTION';

PROCEDURE CreateComponentEvidence(
	in_act							IN	security_pkg.T_ACT_ID,
	in_product_id					IN	product_part.product_id%TYPE,
	in_parent_part_id				IN	product_part.product_part_id%TYPE,
	in_details						IN	np_part_evidence.details%TYPE,
	in_docuemnt_group_id			IN	np_part_evidence.document_group_id%TYPE,
	in_evidence_class_id			IN	np_part_evidence.np_evidence_class_id%TYPE,
	in_evidence_type_id				IN	np_part_evidence.np_evidence_type_id%TYPE,
	out_product_part_id				OUT	product_part.product_part_id%TYPE
);

PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
);

PROCEDURE UpdateComponentEvidence(
	in_act							IN	security_pkg.T_ACT_ID,
	in_part_id						IN	product_part.product_part_id%TYPE,
	in_details						IN	np_part_evidence.details%TYPE,
	in_document_group_id			IN	np_part_evidence.document_group_id%TYPE,
	in_evidence_class_id			IN	np_part_evidence.np_evidence_class_id%TYPE,
	in_evidence_type_id				IN	np_part_evidence.np_evidence_type_id%TYPE
);

PROCEDURE DeletePart(
	in_act					IN	security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
);

PROCEDURE GetComponentEvidence(
	in_act					IN	security_pkg.T_ACT_ID,
	in_part_id				IN	product_part.product_part_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvidenceClassList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvidenceTypeList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
);

END natural_product_evidence_pkg;
/