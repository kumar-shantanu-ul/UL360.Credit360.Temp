create or replace package supplier.targets_pkg
IS

PROCEDURE GetTargetsForScorePage (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_type_id			IN	gt_product_type.gt_product_type_id%TYPE,
	in_range_id			IN	gt_product_answers.gt_product_range_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) ;

PROCEDURE GetTargetsForRangeAndType (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_type_id			IN	gt_product_type.gt_product_type_id%TYPE,
	in_range_id			IN	gt_product_answers.gt_product_range_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) ;

PROCEDURE SetTargetsForRangeAndType (
	in_act_id					 IN	security_pkg.T_ACT_ID,
	in_app_sid					 IN	security_pkg.T_SID_ID,
	in_type_id					 IN	gt_product_type.gt_product_type_id%TYPE,
	in_range_id					 IN	gt_product_answers.gt_product_range_id%TYPE,
	in_min_score_nat_derived     IN gt_target_scores.min_score_nat_derived%TYPE,    
	in_max_score_nat_derived     IN gt_target_scores.max_score_nat_derived%TYPE,    
	in_min_score_chemicals       IN gt_target_scores.min_score_chemicals%TYPE,      
	in_max_score_chemicals       IN gt_target_scores.max_score_chemicals%TYPE,      
	in_min_score_source_biod     IN gt_target_scores.min_score_source_biod%TYPE,    
	in_max_score_source_biod     IN gt_target_scores.max_score_source_biod%TYPE,    
	in_min_score_accred_biod     IN gt_target_scores.min_score_accred_biod%TYPE,    
	in_max_score_accred_biod     IN gt_target_scores.max_score_accred_biod%TYPE,    
	in_min_score_fair_trade      IN gt_target_scores.min_score_fair_trade%TYPE,     
	in_max_score_fair_trade      IN gt_target_scores.max_score_fair_trade%TYPE,     
	in_min_score_renew_pack      IN gt_target_scores.min_score_renew_pack%TYPE,     
	in_max_score_renew_pack      IN gt_target_scores.max_score_renew_pack%TYPE,     
	in_min_score_whats_in_prod   IN gt_target_scores.min_score_whats_in_prod%TYPE,  
	in_max_score_whats_in_prod   IN gt_target_scores.max_score_whats_in_prod%TYPE,  
	in_min_score_water_in_prod   IN gt_target_scores.min_score_water_in_prod%TYPE,  
	in_max_score_water_in_prod   IN gt_target_scores.max_score_water_in_prod%TYPE,  
	in_min_score_energy_in_prod  IN gt_target_scores.min_score_energy_in_prod%TYPE, 
	in_max_score_energy_in_prod  IN gt_target_scores.max_score_energy_in_prod%TYPE, 
	in_min_score_pack_impact     IN gt_target_scores.min_score_pack_impact%TYPE,    
	in_max_score_pack_impact     IN gt_target_scores.max_score_pack_impact%TYPE,    
	in_min_score_pack_opt        IN gt_target_scores.min_score_pack_opt%TYPE,       
	in_max_score_pack_opt        IN gt_target_scores.max_score_pack_opt%TYPE,       
	in_min_score_recycled_pack   IN gt_target_scores.min_score_recycled_pack%TYPE,  
	in_max_score_recycled_pack   IN gt_target_scores.max_score_recycled_pack%TYPE,  
	in_min_score_supp_management IN gt_target_scores.min_score_supp_management%TYPE,
	in_max_score_supp_management IN gt_target_scores.max_score_supp_management%TYPE,
	in_min_score_trans_raw_mat   IN gt_target_scores.min_score_trans_raw_mat%TYPE,  
	in_max_score_trans_raw_mat   IN gt_target_scores.max_score_trans_raw_mat%TYPE,  
	in_min_score_trans_to_boots  IN gt_target_scores.min_score_trans_to_boots%TYPE, 
	in_max_score_trans_to_boots  IN gt_target_scores.max_score_trans_to_boots%TYPE, 
	in_min_score_trans_packaging IN gt_target_scores.min_score_trans_packaging%TYPE,
	in_max_score_trans_packaging IN gt_target_scores.max_score_trans_packaging%TYPE,
	in_min_score_trans_opt       IN gt_target_scores.min_score_trans_opt%TYPE,      
	in_max_score_trans_opt       IN gt_target_scores.max_score_trans_opt%TYPE,      
	in_min_score_energy_dist     IN gt_target_scores.min_score_energy_dist%TYPE,      
	in_max_score_energy_dist     IN gt_target_scores.max_score_energy_dist%TYPE, 	
	in_min_score_water_use       IN gt_target_scores.min_score_water_use%TYPE,      
	in_max_score_water_use       IN gt_target_scores.max_score_water_use%TYPE,      
	in_min_score_energy_use      IN gt_target_scores.min_score_energy_use%TYPE,     
	in_max_score_energy_use      IN gt_target_scores.max_score_energy_use%TYPE,     
	in_min_score_ancillary_req   IN gt_target_scores.min_score_ancillary_req%TYPE,  
	in_max_score_ancillary_req   IN gt_target_scores.max_score_ancillary_req%TYPE,  
	in_min_score_prod_waste      IN gt_target_scores.min_score_prod_waste%TYPE,     
	in_max_score_prod_waste      IN gt_target_scores.max_score_prod_waste%TYPE,     
	in_min_score_recyclable_pack IN gt_target_scores.min_score_recyclable_pack%TYPE,
	in_max_score_recyclable_pack IN gt_target_scores.max_score_recyclable_pack%TYPE,
	in_min_score_recov_pack      IN gt_target_scores.min_score_recov_pack%TYPE,     
	in_max_score_recov_pack      IN gt_target_scores.max_score_recov_pack%TYPE
);

PROCEDURE GetTargetsSet (
	in_act_id					 IN	security_pkg.T_ACT_ID,
	in_app_sid					 IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END targets_pkg;
/
