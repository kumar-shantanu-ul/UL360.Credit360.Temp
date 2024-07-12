create or replace package supplier.model_pkg
IS
	
-- CalcScoreSustainableGroup model factors - put here for convenience - might want putting into table later
-- 3 Biodiversity
FCT_BP_CROP			CONSTANT NUMBER(1) := 2;
FCT_BP_FISH			CONSTANT NUMBER(1) := 4;
FCT_BP_PALM			CONSTANT NUMBER(1) := 4;
FCT_BP_PALM_PROC	CONSTANT NUMBER(1) := 4;
FCT_BP_WILD			CONSTANT NUMBER(1) := 3;
FCT_BP_UNKNOWN		CONSTANT NUMBER(1) := 5;
FCT_BP_THREATENED	CONSTANT NUMBER(2) := 10; -- actually any threatened max's score to 10 in logic anyway
FCT_BP_MINERAL		CONSTANT NUMBER(1) := 0;

-- 4  Biodiversity Source / Accreditation
FCT_BS_ACCRED		CONSTANT NUMBER(1) := 1;
FCT_BS_ACCRED_OTHER	CONSTANT NUMBER(1) := 2;
FCT_BS_KNOWN		CONSTANT NUMBER(1) := 4;
FCT_BS_UNKNOWN		CONSTANT NUMBER(1) := 5;
FCT_BS_NO_NAT		CONSTANT NUMBER(1) := 0;
 
-- 5 Fair / Community trade
FCT_COMMUNITY		CONSTANT NUMBER(1) := 2;
FCT_FAIR			CONSTANT NUMBER(1) := 1;
FCT_OTHER_FAIR		CONSTANT NUMBER(1) := 2;
FCT_NOT_FAIR		CONSTANT NUMBER(1) := 5;

-- CalcScoreSupplyGroup model factors - put here for convenience - might want putting into table later
-- 2 Transport - Raw Materials
FCT_PROD_IN_CONT		CONSTANT NUMBER(1) := 2;
FCT_PROD_BTWN_CONT		CONSTANT NUMBER(1) := 5;
FCT_PROD_CONT_UN		CONSTANT NUMBER(1) := 3;
FCT_PACK_IN_CONT		CONSTANT NUMBER(1) := 2;
FCT_PACK_BTWN_CONT		CONSTANT NUMBER(1) := 5;
FCT_PACK_CONT_UN		CONSTANT NUMBER(1) := 3;

-- CalcScoreFormulationGroup
-- 5 Packaging Optimization
PACK_REUSEABLE_NO			CONSTANT NUMBER(1) := 1;
PACK_REUSEABLE_YES_OPEN		CONSTANT NUMBER(1) := 2;
PACK_REUSEABLE_YES_CLOSED	CONSTANT NUMBER(1) := 3;

PACK_LAYERS_1			 	CONSTANT NUMBER(1) := 1;
PACK_LAYERS_2			 	CONSTANT NUMBER(1) := 2;
PACK_LAYERS_3_OR_MORE	 	CONSTANT NUMBER(1) := 3;
PACK_LAYERS_DOUBLE_WALL		CONSTANT NUMBER(1) := 4;

PACK_SETTLE_NO					CONSTANT NUMBER(1) := 1;
PACK_SETTLE_YES_LESS_25_PCT		CONSTANT NUMBER(1) := 2;
PACK_SETTLE_YES_MORE_25_PCT		CONSTANT NUMBER(1) := 3;

ESS_REQ_PACK_RISK_LOW			CONSTANT NUMBER(1) := 1;
ESS_REQ_PACK_RISK_HIGH			CONSTANT NUMBER(1) := 2;

ESS_REQ_PACK_TYPE_DWJAR		CONSTANT NUMBER(1) := 1;
ESS_REQ_PACK_TYPE_LOOSE_TAB	CONSTANT NUMBER(1) := 2;
ESS_REQ_PACK_TYPE_BLIS_TAB	CONSTANT NUMBER(1) := 3;
ESS_REQ_PACK_TYPE_CARTON	CONSTANT NUMBER(1) := 4;
ESS_REQ_PACK_TYPE_OTHER		CONSTANT NUMBER(1) := 5;

-- don't like this
NUM_OF_DBL_WALLED_JAR_Q 				CONSTANT NUMBER(1) :=  8;
NUM_OF_LOOSE_TABLETS_JUST_Q 			CONSTANT NUMBER(2) :=  10;
NUM_OF_TABS_IN_BLISTRAY_JUST_Q 			CONSTANT NUMBER(1) :=  8;
NUM_OF_CARTON_GIFT_BOX_JUST_Q 			CONSTANT NUMBER(1) :=  8;

-- Max scores for each group
MAX_SCORE_SUSTAINABLE		 CONSTANT NUMBER(2) := 40;
MAX_SCORE_FORMULATION		 CONSTANT NUMBER(2) := 31;
MAX_SCORE_SUPPLY		 	 CONSTANT NUMBER(2) := 38;
MAX_SCORE_USE_AT_HOME		 CONSTANT NUMBER(2) := 15;
MAX_SCORE_END_OF_LINE		 CONSTANT NUMBER(2) := 15;

-- FSC Paper all grouped
MAT_ID_NON_FSC_PAPER  		CONSTANT NUMBER(2) := 14;
MAT_ID_FSC_MIXED			CONSTANT NUMBER(2) := 21;
MAT_ID_FSC_PURE	  			CONSTANT NUMBER(2) := 22;

TRIP_SCORE_CHEM_HAZ			CONSTANT NUMBER(2) := 10;
TRIP_SCORE_BIODIVERSITY		CONSTANT NUMBER(2) := 10;
TRIP_SCORE_BIODIVERSITY_ACC	CONSTANT NUMBER(2) := 5;
TRIP_SCORE_SUPP_MAN			CONSTANT NUMBER(2) := 8;
TRIP_SCORE_PACK_IMPACT		CONSTANT NUMBER(2) := 8;

-- Not set message
CANNOT_EVALUATE				CONSTANT VARCHAR2(100) := 'Not enough information recorded to evaluate';


ERR_INVALID_ARG				CONSTANT NUMBER := -20302;
INVALID_ARG					EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_ARG, -20302);


	
PROCEDURE GetProductScores(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_sustainable_cur 			OUT	security_pkg.T_OUTPUT_CUR,
	out_formulation_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_supply_cur 					OUT	security_pkg.T_OUTPUT_CUR,
	out_use_at_home_cur 			OUT	security_pkg.T_OUTPUT_CUR,
	out_end_of_life_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CalcProductScores(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE
);

PROCEDURE CalcProductScores(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID
);

PROCEDURE GetBestMatchTargetScore (
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_product_id					IN  security_pkg.T_SID_ID,
	in_revision_id					IN  product_revision.revision_id%TYPE,
	out_actual_type_id				OUT gt_product_type.gt_product_type_id%TYPE,
	out_matched_type_id				OUT gt_product_type.gt_product_type_id%TYPE,
	out_actual_range_id				OUT gt_product_answers.gt_product_range_id%TYPE,
	out_matched_range_id			OUT gt_product_answers.gt_product_range_id%TYPE
);

---------------------------------------------
-- Gift scoring - basic
---------------------------------------------

PROCEDURE SetCombinedScore(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE
);

---------------------------------------------
-- Sustainably Sourced
---------------------------------------------

PROCEDURE GetScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_nat_derived	IN gt_scores.score_nat_derived%TYPE,
	in_score_chemicals		IN gt_scores.score_chemicals%TYPE,
	in_score_source_biod	IN gt_scores.score_source_biod%TYPE,
	in_score_accred_biod	IN gt_scores.score_accred_biod%TYPE,
	in_score_fair_trade		IN gt_scores.score_fair_trade%TYPE,
	in_score_renew_pack		IN gt_scores.score_renew_pack%TYPE
);

/*PROCEDURE SetGiftScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_nat_derived	IN gt_scores.score_nat_derived%TYPE,
	in_score_chemicals		IN gt_scores.score_chemicals%TYPE,
	in_score_source_biod	IN gt_scores.score_source_biod%TYPE,
	in_score_accred_biod	IN gt_scores.score_accred_biod%TYPE,
	in_score_fair_trade		IN gt_scores.score_fair_trade%TYPE,
	in_score_renew_pack		IN gt_scores.score_renew_pack%TYPE
);*/

PROCEDURE SetProfileSustainableGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_renewable_pack_pct       IN gt_profile.renewable_pack_pct%TYPE
);

PROCEDURE CalcScoreSustainableGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id		IN security_pkg.T_SID_ID,
	in_revision_id			IN product_revision.revision_id%TYPE
);

---------------------------------------------
-- Whats in the Product - formulation
---------------------------------------------

PROCEDURE GetScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_whats_in_prod	IN gt_scores.score_whats_in_prod%TYPE,
	in_score_water_in_prod	IN gt_scores.score_water_in_prod%TYPE,
	in_score_energy_in_prod	IN gt_scores.score_energy_in_prod%TYPE,
	in_score_pack_impact	IN gt_scores.score_pack_impact%TYPE,
	in_score_pack_opt		IN gt_scores.score_pack_opt%TYPE,
	in_score_recycled_pack	IN gt_scores.score_recycled_pack%TYPE
);

/* SetGiftScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_score_whats_in_prod	IN gt_scores.score_whats_in_prod%TYPE,
	in_score_water_in_prod	IN gt_scores.score_water_in_prod%TYPE,
	in_score_energy_in_prod	IN gt_scores.score_energy_in_prod%TYPE,
	in_score_pack_impact	IN gt_scores.score_pack_impact%TYPE,
	in_score_pack_opt		IN gt_scores.score_pack_opt%TYPE,
	in_score_recycled_pack	IN gt_scores.score_recycled_pack%TYPE
);*/

PROCEDURE SetProfileFormulationGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
    in_recycled_pack_cont_msg   IN gt_profile.recycled_pack_cont_msg%TYPE,
	in_score_pack_impact_raw	IN gt_scores.score_pack_impact%TYPE,
	in_pack_ei					IN gt_scores.score_whats_in_prod%TYPE,
	in_materials_ei				IN gt_scores.score_whats_in_prod%TYPE,
	in_trans_pack_ei			IN gt_scores.score_whats_in_prod%TYPE,
	in_score_water_raw_mat		IN gt_profile.score_water_raw_mat%TYPE,
	in_score_water_contained	IN gt_profile.score_water_contained%TYPE,
	in_score_water_mnfct		IN gt_profile.score_water_mnfct%TYPE,
	in_score_water_wsr 			IN gt_profile.score_water_wsr%TYPE
);

PROCEDURE CalcScoreFormulationGroup(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id		IN security_pkg.T_SID_ID,
	in_revision_id			IN product_revision.revision_id%TYPE
);

---------------------------------------------
-- Product supply
---------------------------------------------

PROCEDURE GetScoreSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetScoreSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_supp_management	IN gt_scores.score_supp_management%TYPE,
    in_score_trans_raw_mat		IN gt_scores.score_trans_raw_mat%TYPE,
    in_score_trans_to_boots		IN gt_scores.score_trans_to_boots%TYPE,
    in_score_trans_packaging	IN gt_scores.score_trans_packaging%TYPE,
    in_score_trans_opt			IN gt_scores.score_trans_opt%TYPE,
    in_score_energy_dist		IN gt_scores.score_energy_dist%TYPE
);

/*PROCEDURE SetGiftScoreSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_supp_management	IN gt_scores.score_supp_management%TYPE,
    in_score_trans_raw_mat		IN gt_scores.score_trans_raw_mat%TYPE,
    in_score_trans_to_boots		IN gt_scores.score_trans_to_boots%TYPE,
    in_score_trans_packaging	IN gt_scores.score_trans_packaging%TYPE,
    in_score_trans_opt			IN gt_scores.score_trans_opt%TYPE
);*/

PROCEDURE SetProfileSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	in_country_made_in_list		IN gt_profile.country_made_in_list%TYPE
);

PROCEDURE CalcScoreSupplyGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN security_pkg.T_SID_ID,
	in_revision_id				IN  product_revision.revision_id%TYPE
);

---------------------------------------------
-- Product use at home
---------------------------------------------


PROCEDURE GetScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_water_use			IN gt_scores.score_water_use%TYPE,
    in_score_energy_use			IN gt_scores.score_energy_use%TYPE,
    in_score_ancillary_req		IN gt_scores.score_ancillary_req%TYPE
);

/*PROCEDURE SetGiftScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
    in_score_water_use			IN gt_scores.score_water_use%TYPE,
    in_score_energy_use			IN gt_scores.score_energy_use%TYPE,
    in_score_ancillary_req		IN gt_scores.score_ancillary_req%TYPE
);*/

PROCEDURE SetProfileUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_low_anc_list				IN gt_profile.gt_low_anc_list%TYPE,
	in_med_anc_list				IN gt_profile.gt_med_anc_list%TYPE,
	in_high_anc_list			IN gt_profile.gt_high_anc_list%TYPE
);

PROCEDURE CalcScoreUseAtHomeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE
);

---------------------------------------------
-- Product end of life
---------------------------------------------

PROCEDURE GetScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_prod_waste			IN gt_scores.score_prod_waste%TYPE,
    in_score_recyclable_pack	IN gt_scores.score_recyclable_pack%TYPE,
    in_score_recov_pack			IN gt_scores.score_recov_pack%TYPE
);

/*PROCEDURE SetGiftScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
    in_score_prod_waste			IN gt_scores.score_prod_waste%TYPE,
    in_score_recyclable_pack	IN gt_scores.score_recyclable_pack%TYPE,
    in_score_recov_pack			IN gt_scores.score_recov_pack%TYPE
);*/


PROCEDURE SetProfileEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_ratio_prod_pck_wght_pct  IN gt_profile.ratio_prod_pck_wght_pct%TYPE,
    in_biopolymer_used          IN gt_profile.biopolymer_used%TYPE, 
    in_biopolymer_list          IN gt_profile.biopolymer_list%TYPE, 
    in_recyclable_pack_pct      IN gt_profile.recyclable_pack_pct%TYPE,  
    in_recoverable_pack_pct     IN gt_profile.recoverable_pack_pct%TYPE
);

PROCEDURE CalcScoreEndOfLifeGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE
);

-- if we genericise the open workflow completely (pretty generic currently) then this will need to be done on a questionnaire group basis
FUNCTION IsLastRevisionModelComplete(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE
) RETURN NUMBER;

-- if we genericise the open workflow completely (pretty generic currently) then this will need to be done on a questionnaire group basis
FUNCTION IsModelComplete(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_product_id				IN product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE
) RETURN NUMBER;


PROCEDURE GetSocialAmplificationScores (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_sustainable_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSAFootprint (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_socamp_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSAChildFootprint (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_socamp_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSAProfile (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN security_pkg.T_SID_ID,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_socamp_cur					OUT	security_pkg.T_OUTPUT_CUR
);

END model_pkg;
/