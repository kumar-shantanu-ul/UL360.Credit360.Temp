DECLARE
	in_product_id NUMBER;
BEGIN
	
	in_product_id := 1;
	
	DELETE FROM gt_product_answers WHERE product_id = in_product_id;
	DELETE FROM gt_formulation_answers WHERE product_id = in_product_id;
		DELETE FROM gt_pack_item WHERE product_id = in_product_id;
	DELETE FROM gt_packaging_answers WHERE product_id = in_product_id;
	DELETE FROM gt_transport_answers WHERE product_id = in_product_id;	
	DELETE FROM gt_supplier_answers WHERE product_id = in_product_id;	
	
	-- product info
	INSERT INTO gt_product_answers (
	   product_id, gt_scope_notes, gt_product_range_id, 
	   gt_product_type_id, product_volume, community_trade_pct, 
	   ct_doc_group_id, fairtrade_pct, other_fair_pct, 
	   not_fair_pct, consumer_advice_1, consumer_advice_1_dg, 
	   consumer_advice_2, consumer_advice_2_dg, consumer_advice_3, 
	   consumer_advice_3_dg, consumer_advice_4, consumer_advice_4_dg, 
	   sustain_assess_1, sustain_assess_1_dg, sustain_assess_2, 
	   sustain_assess_2_dg, sustain_assess_3, sustain_assess_3_dg, 
	   sustain_assess_4, sustain_assess_4_dg) 
	VALUES (in_product_id , NULL, 1,
	    28, 100, 0,
	    NULL, 0, 0,
	    100, NULL, NULL,
	    NULL, NULL, NULL,
	    NULL, NULL, NULL,
	    NULL, NULL, NULL,
	    NULL, NULL, NULL,
	    NULL, NULL);

	-- gt formulation
	INSERT INTO gt_formulation_answers (
	   product_id, ingredient_count, sf_ingredients, 
	   sf_additional_materials, sf_special_materials, bp_crops_pct, 
	   bp_fish_pct, bp_palm_pct, bp_wild_pct, 
	   bp_unknown_pct, bp_threatened_pct, bp_mineral_pct, 
	   sf_biodiversity, bs_accredited_priority_pct, bs_accredited_other_pct, 
	   bs_known_pct, bs_unknown_pct, bs_no_natural_pct, 
	   bs_document_group) 
	VALUES (in_product_id, 18, NULL,
	    NULL, NULL, 49,
	    0, 17, 24,
	    0, 0, 10,
	    NULL, 87, 0,
	    0, 0, 0, 13);
	    

	-- gt packaging	    
	INSERT INTO gt_packaging_answers (
	   product_id, gt_access_pack_type_id, gt_access_visc_type_id, 
	   prod_weight_inc_pack, concentrate_pack, refill_pack, 
	   sf_innovation, sf_novel_refill, single_in_pack, 
	   settle_in_transit, gt_gift_cont_type_id, gt_pack_layers_type_id, 
	   vol_package, retail_packs_stackable, 
	   vol_prod_tran_pack, vol_tran_pack, correct_biopolymer_use, 
	   sf_recycled_threshold, sf_novel_material, pack_meet_req, 
	   pack_shelf_ready, pack_consum_rcyld, pack_consum_pct, 
	   pack_consum_mat, gt_trans_pack_type_id, sf_innovation_transit) 
	VALUES (in_product_id, 1, 2, -- not recorded
	    82.68, 0, 0,
	    NULL, NULL, 1,
	    0, 1, 1,
	    1, NULL, 1,
	    NULL, NULL, 0,
	    NULL, NULL, 1,
	    0, 0, NULL,
	    NULL, 1, NULL);
	    
	INSERT INTO gt_pack_item (
	   product_id, gt_pack_item_id, gt_pack_shape_type_id, gt_pack_material_type_id, 
	   weight_grams, pct_recycled, contains_biopolymer) 
	VALUES (in_product_id, 1, 7, 7,
	    20, 0, 0);
	    
	INSERT INTO gt_pack_item (
	   product_id, gt_pack_item_id, gt_pack_shape_type_id, gt_pack_material_type_id, 
	   weight_grams, pct_recycled, contains_biopolymer) 
	VALUES (in_product_id, 2, 11, 7,
	    5, 0, 0);
	    
	--- gt_transport
	INSERT INTO gt_transport_answers (
	   product_id, made_internally, gt_transport_type_id, 
	   prod_in_cont_pct, prod_btwn_cont_pct, prod_cont_un_pct, 
	   pack_in_cont_pct, pack_btwn_cont_pct, pack_cont_un_pct) 
	VALUES (in_product_id, 1, 2,
	    85.7, 14.3, 0,
	    100, 0, 0);
	    
	 --- gt_supplier
	INSERT INTO gt_supplier_answers (
	   product_id, gt_sus_relation_type_id, sf_supplier_approach, 
	   sf_supplier_assisted, sust_audit_desc, sust_doc_group_id) 
	VALUES (in_product_id, 3, NULL,
	    NULL, NULL, NULL);
	
END;
/