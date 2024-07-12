create or replace package supplier.gt_packaging_pkg
IS

PROCEDURE SetPackagingAnswers (
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_access_pack_type_id       IN  gt_packaging_answers.gt_access_pack_type_id%TYPE,
    in_prod_volume         			IN  gt_product_answers.product_volume%TYPE, -- can be set from eiher PI or Pk questionnaire
    in_prod_weight         			IN  gt_product_answers.prod_weight%TYPE,-- can be set from eiher PI or Pk questionnaire
	in_prod_volume_declared			IN  gt_product_answers.product_volume_declared%TYPE, -- can be set from eiher PI or Pk questionnaire
    in_prod_weight_declared			IN  gt_product_answers.prod_weight_declared%TYPE,-- can be set from eiher PI or Pk questionnaire
    in_weight_inc_pkg         		IN  gt_product_answers.weight_inc_pkg%TYPE, -- can be set from eiher PI or Pk questionnaire
    in_refill_pack                  IN  gt_packaging_answers.refill_pack%TYPE,
    in_sf_innovation                IN  gt_packaging_answers.sf_innovation%TYPE,
    in_sf_novel_refill              IN  gt_packaging_answers.sf_novel_refill%TYPE,
    in_single_in_pack               IN  gt_packaging_answers.single_in_pack%TYPE,
    in_settle_in_transit            IN  gt_packaging_answers.settle_in_transit%TYPE,
    in_gt_gift_cont_type_id         IN  gt_packaging_answers.gt_gift_cont_type_id%TYPE,
    in_gt_pack_layers_type_id       IN  gt_packaging_answers.gt_pack_layers_type_id%TYPE,
    in_vol_package                  IN  gt_packaging_answers.vol_package%TYPE,
    in_retail_packs_stackable       IN  gt_packaging_answers.retail_packs_stackable%TYPE,
    in_num_packs_per_outer       	IN  gt_packaging_answers.num_packs_per_outer%TYPE,
    in_vol_prod_tran_pack           IN  gt_packaging_answers.vol_prod_tran_pack%TYPE,
    in_vol_tran_pack                IN  gt_packaging_answers.vol_tran_pack%TYPE,
    in_correct_biopolymer_use       IN  gt_packaging_answers.correct_biopolymer_use%TYPE,
    in_sf_recycled_threshold        IN  gt_packaging_answers.sf_recycled_threshold%TYPE,
    in_sf_novel_material            IN  gt_packaging_answers.sf_novel_material%TYPE,
    in_pack_meet_req                IN  gt_packaging_answers.pack_meet_req%TYPE,
    in_pack_shelf_ready             IN  gt_packaging_answers.pack_shelf_ready%TYPE,
    in_gt_trans_pack_type_id        IN  gt_packaging_answers.gt_trans_pack_type_id%TYPE,
    in_sf_innovation_transit        IN  gt_packaging_answers.sf_innovation_transit%TYPE,
	in_prod_pack_occupation 		IN  gt_packaging_answers.prod_pack_occupation%TYPE,
	in_pack_style_type	 			IN  gt_packaging_answers.pack_style_type%TYPE, 
	in_dbl_walled_jar_just 			IN  gt_packaging_answers.dbl_walled_jar_just%TYPE,
    in_contain_tablets_just   		IN  gt_packaging_answers.contain_tablets_just%TYPE,
	in_tablets_in_blister_tray 		IN  gt_packaging_answers.tablets_in_blister_tray%TYPE,
	in_carton_gift_box_just			IN  gt_packaging_answers.carton_gift_box_just%TYPE,
	in_carton_gift_box_vacuum_form	IN  gt_packaging_answers.carton_gift_box_vacuum_form%TYPE,
	in_carton_gift_box_clear_win	IN  gt_packaging_answers.carton_gift_box_clear_win%TYPE,
	in_carton_gift_box_sleeve		IN  gt_packaging_answers.carton_gift_box_sleeve%TYPE,
	in_other_prod_protection_just	IN  gt_packaging_answers.other_prod_protection_just%TYPE, 
	in_other_pack_manu_proc_just	IN  gt_packaging_answers.other_pack_manu_proc_just%TYPE,  
	in_other_pack_fill_proc_just	IN  gt_packaging_answers.other_pack_fill_proc_just%TYPE,  
	in_other_logistics_just			IN  gt_packaging_answers.other_logistics_just%TYPE,
	in_other_prod_pres_market_just  IN  gt_packaging_answers.other_prod_present_market_just%TYPE,
	in_other_consumer_accept_just	IN  gt_packaging_answers.other_consumer_accept_just%TYPE,
	in_other_prod_info_just			IN  gt_packaging_answers.other_prod_info_just%TYPE,
	in_other_prod_safety_just		IN  gt_packaging_answers.other_prod_safety_just%TYPE,
	in_other_prod_legislation_just	IN  gt_packaging_answers.other_prod_legislation_just%TYPE,
	in_other_issues_just			IN  gt_packaging_answers.other_issues_just%TYPE,
	in_just_report_explanation		IN  gt_packaging_answers.just_report_explanation%TYPE,
	in_pack_risk					IN  gt_packaging_answers.pack_risk%TYPE,
	in_data_quality_type_id           IN gt_product_answers.data_quality_type_id%TYPE
);


PROCEDURE GetPackagingAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
    in_revision_id				 IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccessPackageType(
    in_act_id                    IN security_pkg.T_ACT_ID,
	in_gt_product_type_id		 IN gt_product_type.gt_product_type_id%TYPE,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTransitPackType(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPackMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);
/*
PROCEDURE GetPackMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
	in_shape_id					 IN gt_pack_shape_type.description%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);
*/
PROCEDURE GetPackMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
	in_shape_id					 IN gt_pack_shape_type.gt_pack_shape_type_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTransMaterial(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetPackShape(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductPackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
    in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTransPackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
   	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT    security_pkg.T_OUTPUT_CUR
);

FUNCTION GetPackItemsString
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE
) RETURN VARCHAR2;

FUNCTION GetTransPackItemsString
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE
) RETURN VARCHAR2;

PROCEDURE DoPackItemsAudit
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE, 
	in_old_pack_list			 IN VARCHAR2,
	in_new_pack_list			 IN VARCHAR2 
);

PROCEDURE DoTransPackItemsAudit
(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE, 
	in_old_transit_pack_list			 IN VARCHAR2,
	in_new_transit_pack_list			 IN VARCHAR2    
);

PROCEDURE DeletePackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE
);

PROCEDURE DeleteTransPackItems(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE
);

PROCEDURE AddPackItem(
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_pack_item_id              in  gt_pack_item.gt_pack_item_id%TYPE,
    in_gt_pack_shape_type_id        in  gt_pack_item.gt_pack_shape_type_id%TYPE,
    in_gt_pack_material_type_id     in  gt_pack_item.gt_pack_material_type_id%TYPE,
    in_weight_grams                 in  gt_pack_item.weight_grams%TYPE,
    in_pct_recycled                 in  gt_pack_item.pct_recycled%TYPE,
    in_contains_biopolymer          in  gt_pack_item.contains_biopolymer%TYPE
);

PROCEDURE AddTransPackItem(
    in_act_id                       IN  security_pkg.T_ACT_ID,
    in_product_id                   IN  all_product.product_id%TYPE,
    in_gt_trans_item_id              IN  gt_trans_item.gt_trans_item_id%TYPE,
    in_gt_trans_material_type_id     IN  gt_trans_item.gt_trans_material_type_id%TYPE,
    in_weight_grams                 IN  gt_trans_item.weight_grams%TYPE,
    in_pct_recycled                 IN  gt_pack_item.pct_recycled%TYPE
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

/*PROCEDURE UpdateProductWeightExcPack(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_product_weight				IN gt_packaging_answers.prod_weight_exc_pack%TYPE
);*/

END gt_packaging_pkg;
/
