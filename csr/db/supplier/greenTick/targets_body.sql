create or replace package body supplier.targets_pkg
IS
	
PROCEDURE GetTargetsForScorePage (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_type_id			IN	gt_product_type.gt_product_type_id%TYPE,
	in_range_id			IN	gt_product_answers.gt_product_range_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) 
AS
	v_cnt NUMBER;
	v_range_id_to_use	gt_product_answers.gt_product_range_id%TYPE;
BEGIN
	
	-- here if there is no set score for the range an type - we want to fall back to just the type (i.e. shampoo)
	SELECT COUNT(*) INTO v_cnt FROM gt_target_scores  
    WHERE gt_product_type_id = in_type_id
      AND gt_product_range_id = in_range_id
	  AND app_sid = in_app_sid;
	  
	v_range_id_to_use := in_range_id;
	IF v_cnt = 0 THEN -- no corresponding range type target scores - fallback 
		v_range_id_to_use := NULL;
	END IF;
	
	GetTargetsForRangeAndType(in_act_id, in_app_sid, in_type_id, v_range_id_to_use, out_cur);
	
END;
	
PROCEDURE GetTargetsForRangeAndType (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_type_id			IN	gt_product_type.gt_product_type_id%TYPE,
	in_range_id			IN	gt_product_answers.gt_product_range_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	
		
	
	  OPEN out_cur FOR 
				SELECT 
			   COUNT(*) OVER () total_rows,
			   gt_product_type_id, gt_product_range_id, 
			   NVL(min_score_nat_derived, -1)    min_score_nat_derived, 
			   NVL(max_score_nat_derived, -1)    max_score_nat_derived, 
			   NVL(min_score_chemicals, -1)      min_score_chemicals, 
			   NVL(max_score_chemicals, -1)      max_score_chemicals, 
			   NVL(min_score_source_biod, -1)    min_score_source_biod, 
			   NVL(max_score_source_biod, -1)    max_score_source_biod, 
			   NVL(min_score_accred_biod, -1)    min_score_accred_biod, 
			   NVL(max_score_accred_biod, -1)    max_score_accred_biod, 
			   NVL(min_score_fair_trade, -1)     min_score_fair_trade, 
			   NVL(max_score_fair_trade, -1)     max_score_fair_trade, 
			   NVL(min_score_renew_pack, -1)     min_score_renew_pack, 
			   NVL(max_score_renew_pack, -1)     max_score_renew_pack, 
			   NVL(min_score_whats_in_prod, -1)  min_score_whats_in_prod, 
			   NVL(max_score_whats_in_prod, -1)  max_score_whats_in_prod, 
			   NVL(min_score_water_in_prod, -1)  min_score_water_in_prod, 
			   NVL(max_score_water_in_prod, -1)  max_score_water_in_prod, 
			   NVL(min_score_energy_in_prod, -1) min_score_energy_in_prod, 
			   NVL(max_score_energy_in_prod, -1) max_score_energy_in_prod, 
			   NVL(min_score_pack_impact, -1)    min_score_pack_impact, 
			   NVL(max_score_pack_impact, -1)    max_score_pack_impact, 
			   NVL(min_score_pack_opt, -1)       min_score_pack_opt, 
			   NVL(max_score_pack_opt, -1)       max_score_pack_opt, 
			   NVL(min_score_recycled_pack, -1)  min_score_recycled_pack, 
			   NVL(max_score_recycled_pack, -1)  max_score_recycled_pack, 
			   NVL(min_score_supp_management, -1)min_score_supp_management, 
			   NVL(max_score_supp_management, -1)max_score_supp_management, 
			   NVL(min_score_trans_raw_mat, -1)  min_score_trans_raw_mat, 
			   NVL(max_score_trans_raw_mat, -1)  max_score_trans_raw_mat, 
			   NVL(min_score_trans_to_boots, -1) min_score_trans_to_boots, 
			   NVL(max_score_trans_to_boots, -1) max_score_trans_to_boots, 
			   NVL(min_score_trans_packaging, -1)min_score_trans_packaging, 
			   NVL(max_score_trans_packaging, -1)max_score_trans_packaging, 
			   NVL(min_score_trans_opt, -1)      min_score_trans_opt, 
			   NVL(max_score_trans_opt, -1)      max_score_trans_opt, 
			   NVL(min_score_energy_dist, -1)      min_score_energy_dist, 
			   NVL(max_score_energy_dist, -1)      max_score_energy_dist, 
			   NVL(min_score_water_use, -1)      min_score_water_use, 
			   NVL(max_score_water_use, -1)      max_score_water_use, 
			   NVL(min_score_energy_use, -1)     min_score_energy_use,
			   NVL(max_score_energy_use, -1)     max_score_energy_use, 
			   NVL(min_score_ancillary_req, -1)  min_score_ancillary_req, 
			   NVL(max_score_ancillary_req, -1)  max_score_ancillary_req, 
			   NVL(min_score_prod_waste, -1)     min_score_prod_waste, 
			   NVL(max_score_prod_waste, -1)     max_score_prod_waste, 
			   NVL(min_score_recyclable_pack, -1)min_score_recyclable_pack, 
			   NVL(max_score_recyclable_pack, -1)max_score_recyclable_pack, 
			   NVL(min_score_recov_pack, -1)     min_score_recov_pack, 
			   NVL(max_score_recov_pack, -1)     max_score_recov_pack
	 FROM gt_target_scores
	WHERE gt_product_type_id = in_type_id
	  AND app_sid = in_app_sid
	  AND ((in_range_id IS NULL AND gt_product_range_id IS NULL) OR (gt_product_range_id = in_range_id));

END;

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
	in_min_score_energy_dist       IN gt_target_scores.min_score_energy_dist%TYPE,      
	in_max_score_energy_dist       IN gt_target_scores.max_score_energy_dist%TYPE, 	
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
)   
AS  
	v_audit						VARCHAR2(4000); 
	v_audit_desc				gt_score_type.description%TYPE; 
	v_min_score_char			VARCHAR2(32);
	v_max_score_char			VARCHAR2(32);
	v_user_sid					security_pkg.T_SID_ID;
BEGIN
	
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	FOR r IN (
		SELECT * FROM 
			(SELECT ts.* FROM gt_target_scores ts, gt_product_type pt
			WHERE pt.gt_product_type_id = ts.gt_product_type_id(+)) t
		WHERE NVl(t.gt_product_range_id, -1) = NVL(in_range_id, -1)
		AND NVl(t.gt_product_type_id, -1) = in_type_id
	) 
	LOOP
		-- actually only ever going to be single row at most as product type and range type are primary key
		-- if no target score then audit the addition in the insert block below
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_NAT_DERIVED, r.min_score_nat_derived, in_min_score_nat_derived, r.max_score_nat_derived, in_max_score_nat_derived);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_CHEMICALS, r.min_score_chemicals, in_min_score_chemicals, r.max_score_chemicals, in_max_score_chemicals);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, r.min_score_source_biod, in_min_score_source_biod, r.max_score_source_biod, in_max_score_source_biod);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, r.min_score_accred_biod, in_min_score_accred_biod, r.max_score_accred_biod, in_max_score_accred_biod);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_FAIR_TRADE, r.min_score_fair_trade, in_min_score_fair_trade, r.max_score_fair_trade, in_max_score_fair_trade);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_RENEW_PACK, r.min_score_renew_pack, in_min_score_renew_pack, r.max_score_renew_pack, in_max_score_renew_pack);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_WHATS_IN_PROD, r.min_score_whats_in_prod, in_min_score_whats_in_prod, r.max_score_whats_in_prod, in_max_score_whats_in_prod);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_WATER_IN_PROD, r.min_score_water_in_prod, in_min_score_water_in_prod, r.max_score_water_in_prod, in_max_score_water_in_prod);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_ENERGY_IN_PROD  , r.min_score_energy_in_prod  , in_min_score_energy_in_prod  , r.max_score_energy_in_prod  , in_max_score_energy_in_prod  );
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_PACK_IMPACT, r.min_score_pack_impact, in_min_score_pack_impact, r.max_score_pack_impact, in_max_score_pack_impact);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_PACK_OPT, r.min_score_pack_opt, in_min_score_pack_opt, r.max_score_pack_opt, in_max_score_pack_opt);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_RECYCLED_PACK, r.min_score_recycled_pack, in_min_score_recycled_pack, r.max_score_recycled_pack, in_max_score_recycled_pack);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_SUPP_MANAGEMENT , r.min_score_supp_management , in_min_score_supp_management , r.max_score_supp_management , in_max_score_supp_management );
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, r.min_score_trans_raw_mat, in_min_score_trans_raw_mat, r.max_score_trans_raw_mat, in_max_score_trans_raw_mat);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_TRANS_TO_BOOTS  , r.min_score_trans_to_boots  , in_min_score_trans_to_boots  , r.max_score_trans_to_boots  , in_max_score_trans_to_boots  );
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_TRANS_PACKAGING , r.min_score_trans_packaging , in_min_score_trans_packaging , r.max_score_trans_packaging , in_max_score_trans_packaging );
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_TRANS_OPT, r.min_score_trans_opt, in_min_score_trans_opt, r.max_score_trans_opt, in_max_score_trans_opt);
		
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_ENERGY_DIST, r.min_score_energy_dist, in_min_score_energy_dist, r.max_score_energy_dist, in_max_score_energy_dist);

		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_WATER_USE, r.min_score_water_use, in_min_score_water_use, r.max_score_water_use, in_max_score_water_use);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_ENERGY_USE, r.min_score_energy_use, in_min_score_energy_use, r.max_score_energy_use, in_max_score_energy_use);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_ANCILLARY_REQ, r.min_score_ancillary_req, in_min_score_ancillary_req, r.max_score_ancillary_req, in_max_score_ancillary_req);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_PROD_WASTE, r.min_score_prod_waste, in_min_score_prod_waste, r.max_score_prod_waste, in_max_score_prod_waste);
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_RECYCLABLE_PACK , r.min_score_recyclable_pack , in_min_score_recyclable_pack , r.max_score_recyclable_pack , in_max_score_recyclable_pack );
		score_log_pkg.WriteToAuditTargetScoreLog(in_act_id, in_app_sid, in_type_id, in_range_id, score_log_pkg.ID_SCORE_RECOV_PACK, r.min_score_recov_pack, in_min_score_recov_pack, r.max_score_recov_pack, in_max_score_recov_pack);

	END LOOP;	
	
	
	-- Upsert 
	BEGIN
		INSERT INTO gt_target_scores 
		(
			app_sid,
			gt_product_type_id,
			gt_product_range_id,
			min_score_nat_derived,
			max_score_nat_derived,
			min_score_chemicals,
			max_score_chemicals,
			min_score_source_biod,
			max_score_source_biod,
			min_score_accred_biod,
			max_score_accred_biod,
			min_score_fair_trade,
			max_score_fair_trade,
			min_score_renew_pack,
			max_score_renew_pack,
			min_score_whats_in_prod,
			max_score_whats_in_prod,
			min_score_water_in_prod,
			max_score_water_in_prod,
			min_score_energy_in_prod,
			max_score_energy_in_prod,
			min_score_pack_impact,
			max_score_pack_impact,
			min_score_pack_opt,
			max_score_pack_opt,
			min_score_recycled_pack,
			max_score_recycled_pack,
			min_score_supp_management,
			max_score_supp_management,
			min_score_trans_raw_mat,
			max_score_trans_raw_mat,
			min_score_trans_to_boots,
			max_score_trans_to_boots,
			min_score_trans_packaging,
			max_score_trans_packaging,
			min_score_trans_opt,
			max_score_trans_opt,
			min_score_energy_dist,
			max_score_energy_dist,
			min_score_water_use,
			max_score_water_use,
			min_score_energy_use,
			max_score_energy_use,
			min_score_ancillary_req,
			max_score_ancillary_req,
			min_score_prod_waste,
			max_score_prod_waste,
			min_score_recyclable_pack,
			max_score_recyclable_pack,
			min_score_recov_pack,
			max_score_recov_pack			
		)
		VALUES
		(
			in_app_sid,
			in_type_id,
			in_range_id,
			in_min_score_nat_derived,
			in_max_score_nat_derived,
			in_min_score_chemicals,
			in_max_score_chemicals,
			in_min_score_source_biod,
			in_max_score_source_biod,
			in_min_score_accred_biod,
			in_max_score_accred_biod,
			in_min_score_fair_trade,
			in_max_score_fair_trade,
			in_min_score_renew_pack,
			in_max_score_renew_pack,
			in_min_score_whats_in_prod,
			in_max_score_whats_in_prod,
			in_min_score_water_in_prod,
			in_max_score_water_in_prod,
			in_min_score_energy_in_prod,
			in_max_score_energy_in_prod,
			in_min_score_pack_impact,
			in_max_score_pack_impact,
			in_min_score_pack_opt,
			in_max_score_pack_opt,
			in_min_score_recycled_pack,
			in_max_score_recycled_pack,
			in_min_score_supp_management,
			in_max_score_supp_management,
			in_min_score_trans_raw_mat,
			in_max_score_trans_raw_mat,
			in_min_score_trans_to_boots,
			in_max_score_trans_to_boots,
			in_min_score_trans_packaging,
			in_max_score_trans_packaging,
			in_min_score_trans_opt,
			in_max_score_trans_opt,
			in_min_score_energy_dist,
			in_max_score_energy_dist,
			in_min_score_water_use,
			in_max_score_water_use,
			in_min_score_energy_use,
			in_max_score_energy_use,
			in_min_score_ancillary_req,
			in_max_score_ancillary_req,
			in_min_score_prod_waste,
			in_max_score_prod_waste,
			in_min_score_recyclable_pack,
			in_max_score_recyclable_pack,
			in_min_score_recov_pack,
			in_max_score_recov_pack     
		 );
		 

		v_audit := 'New Targets: ';
		
		SELECT description, NVL(TO_CHAR(in_min_score_nat_derived), 'Not Set'), NVL(TO_CHAR(in_max_score_nat_derived), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_NAT_DERIVED;		
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';
		
		SELECT description, NVL(TO_CHAR(in_min_score_chemicals), 'Not Set'), NVL(TO_CHAR(in_max_score_chemicals), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_CHEMICALS;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_source_biod), 'Not Set'), NVL(TO_CHAR(in_max_score_source_biod), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_SOURCE_BIOD;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_accred_biod), 'Not Set'), NVL(TO_CHAR(in_max_score_accred_biod), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_ACCRED_BIOD;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_fair_trade), 'Not Set'), NVL(TO_CHAR(in_max_score_fair_trade), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_FAIR_TRADE;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_renew_pack), 'Not Set'), NVL(TO_CHAR(in_max_score_renew_pack), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_RENEW_PACK;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_whats_in_prod), 'Not Set'), NVL(TO_CHAR(in_max_score_whats_in_prod), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_WHATS_IN_PROD;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_water_in_prod), 'Not Set'), NVL(TO_CHAR(in_max_score_water_in_prod), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_WATER_IN_PROD;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_energy_in_prod), 'Not Set'), NVL(TO_CHAR(in_max_score_energy_in_prod), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_ENERGY_IN_PROD;  
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_pack_impact), 'Not Set'), NVL(TO_CHAR(in_max_score_pack_impact), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_PACK_IMPACT;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_pack_opt), 'Not Set'), NVL(TO_CHAR(in_max_score_pack_opt), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_PACK_OPT;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_recycled_pack), 'Not Set'), NVL(TO_CHAR(in_max_score_recycled_pack), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_RECYCLED_PACK;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_supp_management), 'Not Set'), NVL(TO_CHAR(in_max_score_supp_management), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_SUPP_MANAGEMENT; 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_trans_raw_mat), 'Not Set'), NVL(TO_CHAR(in_max_score_trans_raw_mat), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_TRANS_RAW_MAT	; 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_trans_to_boots), 'Not Set'), NVL(TO_CHAR(in_max_score_trans_to_boots), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_TRANS_TO_BOOTS;  
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_trans_packaging), 'Not Set'), NVL(TO_CHAR(in_max_score_trans_packaging), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_TRANS_PACKAGING; 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_trans_opt), 'Not Set'), NVL(TO_CHAR(in_max_score_trans_opt), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_TRANS_OPT;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';
		
		SELECT description, NVL(TO_CHAR(in_min_score_energy_dist), 'Not Set'), NVL(TO_CHAR(in_max_score_energy_dist), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_ENERGY_DIST;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_water_use), 'Not Set'), NVL(TO_CHAR(in_max_score_water_use), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_WATER_USE;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_energy_use), 'Not Set'), NVL(TO_CHAR(in_max_score_energy_use), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_ENERGY_USE;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_ancillary_req), 'Not Set'), NVL(TO_CHAR(in_max_score_ancillary_req), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_ANCILLARY_REQ;	 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_prod_waste), 'Not Set'), NVL(TO_CHAR(in_max_score_prod_waste), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_PROD_WASTE;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_recyclable_pack), 'Not Set'), NVL(TO_CHAR(in_max_score_recyclable_pack), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_RECYCLABLE_PACK; 
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';

		SELECT description, NVL(TO_CHAR(in_min_score_recov_pack), 'Not Set'), NVL(TO_CHAR(in_max_score_recov_pack), 'Not Set') INTO v_audit_desc, v_min_score_char, v_max_score_char FROM gt_score_type WHERE gt_score_type_id = score_log_pkg.ID_SCORE_RECOV_PACK;	     
		v_audit := v_audit || v_audit_desc || ' (Min: ' || v_min_score_char || ', Max: ' || v_max_score_char || '), ';
		
		INSERT INTO gt_target_scores_log (app_sid, gt_product_type_id, gt_product_range_id, user_sid, description, audit_date) 
			VALUES (in_app_sid, in_type_id, in_range_id, v_user_sid, v_audit, SYSDATE);
		 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN

		UPDATE gt_target_scores SET
			min_score_nat_derived =      in_min_score_nat_derived,        
			max_score_nat_derived =      in_max_score_nat_derived,        
			min_score_chemicals =        in_min_score_chemicals,          
			max_score_chemicals =        in_max_score_chemicals,          
			min_score_source_biod =      in_min_score_source_biod,        
			max_score_source_biod =      in_max_score_source_biod,        
			min_score_accred_biod =      in_min_score_accred_biod,        
			max_score_accred_biod =      in_max_score_accred_biod,        
			min_score_fair_trade =       in_min_score_fair_trade,         
			max_score_fair_trade =       in_max_score_fair_trade,         
			min_score_renew_pack =       in_min_score_renew_pack,         
			max_score_renew_pack =       in_max_score_renew_pack,         
			min_score_whats_in_prod =    in_min_score_whats_in_prod,      
			max_score_whats_in_prod =    in_max_score_whats_in_prod,      
			min_score_water_in_prod =    in_min_score_water_in_prod,      
			max_score_water_in_prod =    in_max_score_water_in_prod,      
			min_score_energy_in_prod =   in_min_score_energy_in_prod,     
			max_score_energy_in_prod =   in_max_score_energy_in_prod,     
			min_score_pack_impact =      in_min_score_pack_impact,        
			max_score_pack_impact =      in_max_score_pack_impact,        
			min_score_pack_opt =         in_min_score_pack_opt,           
			max_score_pack_opt =         in_max_score_pack_opt,           
			min_score_recycled_pack =    in_min_score_recycled_pack,      
			max_score_recycled_pack =    in_max_score_recycled_pack,      
			min_score_supp_management =  in_min_score_supp_management,    
			max_score_supp_management =  in_max_score_supp_management,    
			min_score_trans_raw_mat =    in_min_score_trans_raw_mat,      
			max_score_trans_raw_mat =    in_max_score_trans_raw_mat,      
			min_score_trans_to_boots =   in_min_score_trans_to_boots,     
			max_score_trans_to_boots =   in_max_score_trans_to_boots,     
			min_score_trans_packaging =  in_min_score_trans_packaging,    
			max_score_trans_packaging =  in_max_score_trans_packaging,    
			min_score_trans_opt =        in_min_score_trans_opt,          
			max_score_trans_opt =        in_max_score_trans_opt,          
			min_score_energy_dist =      in_min_score_energy_dist,          
			max_score_energy_dist =      in_max_score_energy_dist, 
			min_score_water_use =        in_min_score_water_use,          
			max_score_water_use =        in_max_score_water_use,          
			min_score_energy_use =       in_min_score_energy_use,         
			max_score_energy_use =       in_max_score_energy_use,         
			min_score_ancillary_req =    in_min_score_ancillary_req,      
			max_score_ancillary_req =    in_max_score_ancillary_req,      
			min_score_prod_waste =       in_min_score_prod_waste,         
			max_score_prod_waste =       in_max_score_prod_waste,         
			min_score_recyclable_pack =  in_min_score_recyclable_pack,    
			max_score_recyclable_pack =  in_max_score_recyclable_pack,    
			min_score_recov_pack =       in_min_score_recov_pack,         
			max_score_recov_pack =       in_max_score_recov_pack 
		WHERE gt_product_type_id = in_type_id
		  AND app_sid = in_app_sid
		  AND ((in_range_id IS NULL AND gt_product_range_id IS NULL) OR (gt_product_range_id = in_range_id));
		
		
	END;
    
END;

PROCEDURE GetTargetsSet (
	in_act_id					 IN	security_pkg.T_ACT_ID,
	in_app_sid					 IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	
	OPEN out_cur FOR
		SELECT ptr.gt_product_type_id, type_desc, ptr.gt_product_range_id, range_desc, DECODE(NVL2(gt.gt_product_type_id, 1, 0), 1, 'Yes', 0, 'No') usedYN, NVL2(gt.gt_product_type_id, 1, 0) used,
			min_score_nat_derived,    
			max_score_nat_derived,    
			min_score_chemicals,      
			max_score_chemicals,      
			min_score_source_biod,    
			max_score_source_biod,    
			min_score_accred_biod,    
			max_score_accred_biod,    
			min_score_fair_trade,     
			max_score_fair_trade,     
			min_score_renew_pack,     
			max_score_renew_pack,     
			min_score_whats_in_prod,  
			max_score_whats_in_prod,  
			min_score_water_in_prod,  
			max_score_water_in_prod,  
			min_score_energy_in_prod, 
			max_score_energy_in_prod, 
			min_score_pack_impact,    
			max_score_pack_impact,    
			min_score_pack_opt,       
			max_score_pack_opt,       
			min_score_recycled_pack,  
			max_score_recycled_pack,  
			min_score_supp_management,
			max_score_supp_management,
			min_score_trans_raw_mat,  
			max_score_trans_raw_mat,  
			min_score_trans_to_boots, 
			max_score_trans_to_boots, 
			min_score_trans_packaging,
			max_score_trans_packaging,
			min_score_trans_opt,      
			max_score_trans_opt,      
			min_score_energy_dist,      
			max_score_energy_dist, 
			min_score_water_use,      
			max_score_water_use,      
			min_score_energy_use,     
			max_score_energy_use,     
			min_score_ancillary_req,  
			max_score_ancillary_req,  
			min_score_prod_waste,     
			max_score_prod_waste,     
			min_score_recyclable_pack,
			max_score_recyclable_pack,
			min_score_recov_pack,     
			max_score_recov_pack
		FROM 
		(
			SELECT gt_product_type_id, NVL(gt_product_range_id, -1) gt_product_range_id,  
				min_score_nat_derived,    
				max_score_nat_derived,    
				min_score_chemicals,      
				max_score_chemicals,      
				min_score_source_biod,    
				max_score_source_biod,    
				min_score_accred_biod,    
				max_score_accred_biod,    
				min_score_fair_trade,     
				max_score_fair_trade,     
				min_score_renew_pack,     
				max_score_renew_pack,     
				min_score_whats_in_prod,  
				max_score_whats_in_prod,  
				min_score_water_in_prod,  
				max_score_water_in_prod,  
				min_score_energy_in_prod, 
				max_score_energy_in_prod, 
				min_score_pack_impact,    
				max_score_pack_impact,    
				min_score_pack_opt,       
				max_score_pack_opt,       
				min_score_recycled_pack,  
				max_score_recycled_pack,  
				min_score_supp_management,
				max_score_supp_management,
				min_score_trans_raw_mat,  
				max_score_trans_raw_mat,  
				min_score_trans_to_boots, 
				max_score_trans_to_boots, 
				min_score_trans_packaging,
				max_score_trans_packaging,
				min_score_trans_opt,      
				max_score_trans_opt, 
				min_score_energy_dist,      
				max_score_energy_dist, 				
				min_score_water_use,      
				max_score_water_use,      
				min_score_energy_use,     
				max_score_energy_use,     
				min_score_ancillary_req,  
				max_score_ancillary_req,  
				min_score_prod_waste,     
				max_score_prod_waste,     
				min_score_recyclable_pack,
				max_score_recyclable_pack,
				min_score_recov_pack,     
				max_score_recov_pack
			FROM gt_target_scores gt WHERE app_sid = in_app_sid
		) gt, 
		(
			SELECT gt_product_type_id, pt.description type_desc, gt_product_range_id, pr.description range_desc FROM gt_product_type pt, (SELECT gt_product_range_id, description FROM gt_product_range pr UNION SELECT -1 gt_product_range_id, '000 Default - No range set' description FROM dual) pr -- slight hack - 000 just ensures the rangeId not set record returns first
			ORDER BY LOWER(pt.description), LOWER(pr.description)
		) ptr
		WHERE ptr.gt_product_type_id = gt.gt_product_type_id(+)
		AND ptr.gt_product_range_id = gt.gt_product_range_id(+)
		ORDER BY LOWER(type_desc), gt_product_type_id, LOWER(range_desc), gt_product_range_id;
	
END;
    
END targets_pkg;
/   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    