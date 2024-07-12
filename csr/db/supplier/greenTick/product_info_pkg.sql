create or replace package supplier.product_info_pkg
IS

PROCEDURE SetProductAnswers (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_gt_scope_notes 				IN gt_product_answers.gt_scope_notes%TYPE,
	in_gt_product_range_id 			IN gt_product_answers.gt_product_range_id%TYPE,
--	in_gt_product_type_id 			IN gt_product_type.gt_product_type_id%TYPE,
	in_product_volume 				IN gt_product_answers.product_volume%TYPE,
	in_product_volume_declared		IN gt_product_answers.product_volume_declared%TYPE,
    in_prod_weight         			IN gt_product_answers.prod_weight%TYPE,
	in_prod_weight_declared  			IN gt_product_answers.prod_weight_declared%TYPE,
    in_weight_inc_pkg         		IN gt_product_answers.weight_inc_pkg%TYPE,
	in_community_trade_pct 			IN gt_product_answers.community_trade_pct%TYPE,
	in_ct_doc_group_id 				IN gt_product_answers.ct_doc_group_id%TYPE,
	in_fairtrade_pct 				IN gt_product_answers.fairtrade_pct%TYPE,
	in_other_fair_pct 				IN gt_product_answers.other_fair_pct%TYPE,
	in_not_fair_pct 				IN gt_product_answers.not_fair_pct%TYPE,
	in_reduce_energy_use_adv		IN gt_product_answers.reduce_energy_use_adv%TYPE,
	in_reduce_water_use_adv			IN gt_product_answers.reduce_water_use_adv%TYPE,
	in_reduce_waste_adv				IN gt_product_answers.reduce_waste_adv%TYPE,
	in_on_pack_recycling_adv		IN gt_product_answers.on_pack_recycling_adv%TYPE,
	in_consumer_advice_3 			IN gt_product_answers.consumer_advice_3%TYPE,
	in_consumer_advice_3_dg 		IN gt_product_answers.consumer_advice_3_dg%TYPE,
	in_consumer_advice_4 			IN gt_product_answers.consumer_advice_4%TYPE,
	in_consumer_advice_4_dg 		IN gt_product_answers.consumer_advice_4_dg%TYPE,
	in_sustain_assess_1 			IN gt_product_answers.sustain_assess_1%TYPE,
	in_sustain_assess_1_dg 			IN gt_product_answers.sustain_assess_1_dg%TYPE,
	in_sustain_assess_2 			IN gt_product_answers.sustain_assess_2%TYPE,
	in_sustain_assess_2_dg 			IN gt_product_answers.sustain_assess_2_dg%TYPE,
	in_sustain_assess_3 			IN gt_product_answers.sustain_assess_3%TYPE,
	in_sustain_assess_3_dg 			IN gt_product_answers.sustain_assess_3_dg%TYPE,
	in_sustain_assess_4				IN gt_product_answers.sustain_assess_4%TYPE,
	in_sustain_assess_4_dg			IN gt_product_answers.sustain_assess_4_dg%TYPE,
	in_data_quality_type_id         IN gt_product_answers.data_quality_type_id%TYPE
);

PROCEDURE GetGTProductRevision (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN	product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION IsSubProduct (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE
) RETURN NUMBER;

PROCEDURE GetProductDataFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE,
	out_product_class_id		OUT	gt_product_class.gt_product_class_id%TYPE,
	out_product_class			OUT	gt_product_class.gt_product_class_name%TYPE,
	out_product_type_unit		OUT	gt_product_type.unit%TYPE
);

PROCEDURE GetProductDataFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE, 
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE,
	out_product_class_id		OUT	gt_product_class.gt_product_class_id%TYPE,
	out_product_class			OUT	gt_product_class.gt_product_class_name%TYPE,
	out_product_type_unit		OUT	gt_product_type.unit%TYPE
);

PROCEDURE GetProductDataFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetProductTypeFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE, 
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE
);

PROCEDURE GetProductTypeFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	out_product_type_id			OUT	gt_product_type.gt_product_type_id%TYPE,
	out_product_type			OUT	gt_product_type.description%TYPE
);

FUNCTION GetProductTypeId(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE
) RETURN NUMBER;

PROCEDURE GetProductClassFromTags (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE, 
	out_product_class_id		OUT	gt_product_class.gt_product_class_id%TYPE,
	out_product_class			OUT	gt_product_class.gt_product_class_name%TYPE
);

FUNCTION GetProductClassId(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE
) RETURN NUMBER;

PROCEDURE GetProductAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAbsentLinkedProducts(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id			IN all_product.product_id%TYPE,
	in_product_ids		IN product_pkg.T_PRODUCT_IDS
);

PROCEDURE GetLinkedProducts(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddLinkedProduct(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_link_product_id	IN gt_link_product.link_product_id%TYPE,
	in_count						IN gt_link_product.count%TYPE
);

PROCEDURE UpdateLinkedProduct(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_link_product_id	IN gt_link_product.link_product_id%TYPE,
	in_count						IN gt_link_product.count%TYPE
);

PROCEDURE DeleteLinkedProduct(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	in_link_product_id	IN gt_link_product.link_product_id%TYPE
);

PROCEDURE GetProductRanges(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTypes(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

/*PROCEDURE GetProductClass(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN all_product.product_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);*/


PROCEDURE GetProductTypes(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTypesByGroupId(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_group_id					IN gt_product_type_group.gt_product_type_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTypeGroups(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchProduct(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_name						IN all_product.description%TYPE,
	in_code						IN all_product.product_code%TYPE,
	in_product_id				IN all_product.product_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
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


-- tree handlers@
PROCEDURE GetTreeWithDepth(
	in_act_id   	IN  security_pkg.T_ACT_ID,
	in_product_id	IN	product.product_id%TYPE,
	in_fetch_depth	IN	NUMBER,
	in_group_id		IN product_questionnaire_group.group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_search_phrase	IN	VARCHAR2,
	in_group_id			IN product_questionnaire_group.group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	in_group_id			IN product_questionnaire_group.group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_group_id			IN product_questionnaire_group.group_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateProdVolumeWeight(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_product_volume				IN gt_product_answers.product_volume%TYPE,
	in_product_volume_declared		IN gt_product_answers.product_volume_declared%TYPE,
    in_prod_weight         			IN gt_product_answers.prod_weight%TYPE,
	in_prod_weight_declared  			IN gt_product_answers.prod_weight_declared%TYPE,
    in_weight_inc_pkg         		IN gt_product_answers.weight_inc_pkg%TYPE
);

PROCEDURE GetDataQualityTypes(
    in_act_id                   IN security_pkg.T_ACT_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFilteredProductTypes(
    in_act_id                   IN security_pkg.T_ACT_ID,
	in_group_filter				IN gt_product_group.gt_product_group_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductGroupData(
    in_act_id                   IN security_pkg.T_ACT_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END product_info_pkg;
/
