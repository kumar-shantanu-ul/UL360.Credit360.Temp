create or replace package supplier.model_pd_pkg
IS

PROD_CLASS_FORMULATED	CONSTANT NUMBER(1) := 1;
PROD_CLASS_MANUFACTURED	CONSTANT NUMBER(1) := 2;
PROD_CLASS_PARENT_PACK	CONSTANT NUMBER(1) := 3;
PROD_CLASS_FOOD			CONSTANT NUMBER(1) := 4;

QUESTION_GT_PROD_INFO		CONSTANT NUMBER(2) := 8;
QUESTION_GT_PACKAGING		CONSTANT NUMBER(2) := 9;
QUESTION_GT_FORMULATION		CONSTANT NUMBER(2) := 10;
QUESTION_GT_TRANSPORT		CONSTANT NUMBER(2) := 11;
QUESTION_GT_SUPPLIER		CONSTANT NUMBER(2) := 12;
QUESTION_GT_PROD_DESIGN		CONSTANT NUMBER(2) := 13;
QUESTION_GT_FOOD			CONSTANT NUMBER(2) := 14;

PROD_TYPE_UNIT_ML		CONSTANT VARCHAR2(20) := 'ml';
PROD_TYPE_UNIT_G		CONSTANT VARCHAR2(20) := 'g';

FORMULATED_DURABILITY_TYPE	CONSTANT NUMBER(1) := 1;

-------------------------------------
--Scores that differ between classes
-------------------------------------

------------------------------
--	Sustainable Sourcing
------------------------------

PROCEDURE CalcNatDerivedIngScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score						OUT gt_scores.score_nat_derived%TYPE
);

PROCEDURE CalcChemRiskScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score						OUT gt_scores.score_chemicals%TYPE
);

PROCEDURE CalcBiodiversityScores(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_bio_prov_score				OUT gt_scores.score_source_biod%TYPE,
	out_bio_accred_score			OUT gt_scores.score_accred_biod%TYPE
);

------------------------------
--	What's in the product
------------------------------
--1
PROCEDURE CalcWhatsInProdScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_whats_in_prod_score			OUT gt_scores.score_whats_in_prod%TYPE,
	out_pack_ei						OUT gt_scores.score_whats_in_prod%TYPE,
	out_materials_ei				OUT gt_scores.score_whats_in_prod%TYPE,
	out_trans_pack_ei			OUT gt_scores.score_whats_in_prod%TYPE
);
-- 2 and 3
PROCEDURE CalcWaterEnergyManfctScore(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_water_in_prod			OUT gt_scores.score_water_in_prod%TYPE,
	out_score_energy_in_prod		OUT gt_scores.score_energy_in_prod%TYPE,
	out_score_water_raw_mat			OUT gt_profile.score_water_raw_mat%TYPE,
	out_score_water_contained		OUT gt_profile.score_water_contained%TYPE,
	out_score_water_mnfct			OUT gt_profile.score_water_mnfct%TYPE,
	out_score_water_wsr				OUT gt_profile.score_water_wsr%TYPE
);

--4
-- broken out as then can use same func for 
PROCEDURE CalcPackImpactScoreFromData(
	in_product_id					IN 	product.product_id%TYPE, 
	in_prod_class_id				IN 	gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN 	product_revision.revision_id%TYPE,
	in_prod_weight					IN	gt_product_answers.prod_weight%TYPE,
	in_inc_pkg						IN	gt_product_answers.weight_inc_pkg%TYPE,
	in_concentrate_pack				IN	gt_formulation_answers.concentrate%TYPE, 
	in_refill_pack					IN	gt_packaging_answers.refill_pack%TYPE,
	in_pack_weight_total			IN	gt_pack_item.weight_grams%TYPE, 
	out_score_pack_impact			OUT gt_scores.score_pack_impact%TYPE, 
	out_score_pack_impact_raw		OUT gt_scores.score_pack_impact%TYPE
);

PROCEDURE CalcPackImpactScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_pack_impact			OUT gt_scores.score_pack_impact%TYPE,
	out_score_pack_impact_raw		OUT gt_scores.score_pack_impact%TYPE
);

------------------------------
--	Product Supply
------------------------------
-- 6
PROCEDURE CalcEnergyDist(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_energy_dist			OUT gt_scores.score_energy_dist%TYPE
);
------------------------------
--	Use at Home
------------------------------

-- 1 , 2 
PROCEDURE CalcWaterEnergyUseScores(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_water_use				OUT gt_scores.score_water_use%TYPE,
	out_score_energy_use			OUT gt_scores.score_energy_use%TYPE
);

--3 
PROCEDURE CalcAncMatScore(
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_ancillary_req			OUT gt_scores.score_ancillary_req%TYPE, 
	out_gt_low_anc_list				OUT gt_profile.gt_low_anc_list%TYPE,
	out_gt_med_anc_list				OUT gt_profile.gt_med_anc_list%TYPE,
	out_gt_high_anc_list			OUT gt_profile.gt_high_anc_list%TYPE	
);

------------------------------
--	End of life
------------------------------

-- 1 
PROCEDURE CalcProductWaste(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE, 
	in_prod_class_id				IN gt_product_class.gt_product_class_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_score_prod_waste			OUT gt_scores.score_prod_waste%TYPE
);

END model_pd_pkg;
/