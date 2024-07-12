create or replace package body supplier.revision_pkg
IS
	
-- from latest revision
PROCEDURE CreateNewProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE,
	out_new_rev						OUT product_revision.revision_id%TYPE
)
AS
	v_max_revision_id 				product_revision.revision_id%TYPE;
	out_cur							security_pkg.T_OUTPUT_CUR;
BEGIN
	
	-- always create a new revision one more than the highest one for that product
	SELECT MAX(revision_id)+1 INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	CreateNewProductRevision(in_act_id, in_product_id, in_group_id, in_description, v_max_revision_id, out_new_rev);
	
END;
	

-- Currently this is only called internally
PROCEDURE CreateNewProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	out_new_rev						OUT product_revision.revision_id%TYPE
)
AS
	v_max_revision_id 			product_revision.revision_id%TYPE;
	v_user_sid					security_pkg.T_SID_ID;
	v_rev_check					product_revision.revision_id%TYPE;
	v_new_sust_doc_group		document_group.document_group_id%TYPE;
	v_ct_doc_group_id			gt_product_answers.ct_doc_group_id%TYPE;

	v_consumer_advice_3_dg		gt_product_answers.consumer_advice_3_dg%TYPE;
	v_consumer_advice_4_dg		gt_product_answers.consumer_advice_4_dg%TYPE;
	v_sustain_assess_1_dg		gt_product_answers.sustain_assess_1_dg%TYPE;
	v_sustain_assess_2_dg		gt_product_answers.sustain_assess_2_dg%TYPE;
	v_sustain_assess_3_dg		gt_product_answers.sustain_assess_3_dg%TYPE;
	v_sustain_assess_4_dg		gt_product_answers.sustain_assess_4_dg%TYPE;
	v_bs_document_group			document_group.document_group_id%TYPE;
    v_ancillaryMaterials        gt_formulation_pkg.T_ANCILLARY_MATERIALS;
	
    v_f_chemicalsPresent          gt_formulation_pkg.T_CHEMICALS_PRESENT;
    v_f_palmOil                   gt_formulation_pkg.T_PALM_OIL;
    v_f_wsr                  	 gt_formulation_pkg.T_WSR;
    v_f_endangeredSpecies         gt_formulation_pkg.T_ENDANGERED_SPECIES;

    v_pda_palmOil               gt_product_design_pkg.T_PALM_OIL;
    v_pda_endangeredSpecies     gt_product_design_pkg.T_ENDANGERED_SPECIES;
	
	v_socamp_qs					gt_food_pkg.T_SOCIAL_AMP_QUESTIONS;
	v_food_esp					gt_food_pkg.T_ENDANGERED_SPECIES;
	v_food_palmOil				gt_food_pkg.T_PALM_OIL;

BEGIN
	
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- if we are creating a new revision the current revision must be approved and the new one must be open for review
	--UPDATE product_questionnaire_group SET group_status_id = DATA_BEING_REVIEWED WHERE product_id = in_product_id and group_id = in_group_id;
	
	security.user_pkg.GetSID(in_act_id, v_user_sid);	
	
	-- always create a new revision one more than the highest one for that product
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
		
	
	-- capture current product tags (NOTE: ONLY THOSE THAT MAPS TO THE GIVEN QUESTIONNAIRE GROUP)
	INSERT INTO product_revision_tag (product_id, revision_id, tag_id, group_id, note, num)
	 SELECT product_id, v_max_revision_id ,tag_id, in_group_id, note, num  
	  FROM product_tag 
	 WHERE product_id = in_product_id
	   AND tag_id IN (
      SELECT tag_id 
        FROM questionnaire_tag 
       WHERE questionnaire_id IN (
        SELECT questionnaire_id 
          FROM questionnaire_group_membership 
         WHERE group_id = in_group_id
         )
	   );
	
	-- TO DO - if the product has never had any answers saved need to save null check
	
	-- gt supplier
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_supplier_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		document_pkg.CreateDocumentGroup(in_act_id, v_new_sust_doc_group);
		gt_supplier_pkg.SetSupplierAnswers (
			in_act_id,
			in_product_id,
		  	NULL,
			NULL,
			NULL,
			NULL,
			v_new_sust_doc_group,
			NULL
); 
	END IF;
	
	-- gt prod info
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_product_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		document_pkg.CreateDocumentGroup(in_act_id, v_ct_doc_group_id);

		document_pkg.CreateDocumentGroup(in_act_id, v_consumer_advice_3_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_consumer_advice_4_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_1_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_2_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_3_dg);
		document_pkg.CreateDocumentGroup(in_act_id, v_sustain_assess_4_dg);
    
		product_info_pkg.SetProductAnswers (
			in_act_id,
			in_product_id,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			v_ct_doc_group_id ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			NULL ,
			v_consumer_advice_3_dg ,
			NULL ,
			v_consumer_advice_4_dg ,
			NULL ,
			v_sustain_assess_1_dg ,
			NULL ,
			v_sustain_assess_2_dg ,
			NULL ,
			v_sustain_assess_3_dg ,
			NULL,
			v_sustain_assess_4_dg,
			NULL
		);
	END IF;
	
	-- gt pack
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_packaging_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		gt_packaging_pkg.SetPackagingAnswers (
		in_act_id,	--	    in_act_id                ,
		in_product_id,	--	    in_product_id        ,
		NULL,	--	    in_gt_access_pack_type_id    ,
		NULL,	--	    in_prod_volume		         ,
		NULL,	--	    in_prod_weight		         ,
		NULL,	--		in_prod_volume_declared		 ,
		NULL,	--		in_prod_weight_declared		 ,
		NULL,	--	    in_weight_inc_pkg	         ,
		-1 ,	--	    in_refill_pack               ,
		NULL ,	--	    in_sf_innovation             ,
		NULL ,	--	    in_sf_novel_refill           ,
		-1,		--	    in_single_in_pack            ,
		-1 ,	--	    in_settle_in_transit         ,
		NULL,	--	    in_gt_gift_cont_type_id      ,
		NULL,	--	    in_gt_pack_layers_type_id    ,
		NULL ,	--	    in_vol_package               ,
		-1,		--	    in_retail_packs_stackable    ,
		NULL,	-- 		in_num_packs_per_outer
		NULL,	--	    in_vol_prod_tran_pack        ,
		NULL ,	--	    in_vol_tran_pack             ,
		-1,		--	    in_correct_biopolymer_use    ,
		NULL ,	--	    in_sf_recycled_threshold     ,
		NULL ,	--	    in_sf_novel_material         ,
		-1 ,	--	    in_pack_meet_req             ,
		-1,		--	    in_pack_shelf_ready          ,
		NULL ,	--	    in_gt_trans_pack_type_id     ,
		NULL ,	--	    in_sf_innovation_transit     ,
		NULL, 	-- 		in_prod_pack_occupation 		
		NULL, 	-- 		in_pack_style_type	 			
		NULL, 	-- 		in_dbl_walled_jar_just 			
		NULL, 	-- 		in_contain_tablets_just   		
		NULL, 	-- 		in_tablets_in_blister_tray 		
		NULL, 	-- 		in_carton_gift_box_just			
		NULL, 	-- 		in_carton_gift_box_vacuum_form	
		NULL, 	-- 		in_carton_gift_box_clear_win	
		NULL, 	-- 		in_carton_gift_box_sleeve		
		NULL, 	-- 		in_other_prod_protection_just	
		NULL, 	-- 		in_other_pack_manu_proc_just	
		NULL, 	-- 		in_other_pack_fill_proc_just	
		NULL, 	-- 		in_other_logistics_just			
		NULL, 	-- 		in_other_prod_pres_market_jus
		NULL, 	-- 		in_other_consumer_accept_just	
		NULL, 	-- 		in_other_prod_info_just			
		NULL, 	-- 		in_other_prod_safety_just		
		NULL, 	-- 		in_other_prod_legislation_just	
		NULL, 	-- 		in_other_issues_just			
        NULL, 	-- 		in_just_report_explanation		
        NULL, 	-- 		in_pack_risk
		NULL    --		in_data_quality_type_id
		);
	END IF;
	
	-- gt formulation
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_formulation_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		document_pkg.CreateDocumentGroup(in_act_id, v_bs_document_group);
		gt_formulation_pkg.SetFormulationAnswers (
			in_act_id,
			in_product_id,
			NULL,
			NULL,
			NULL,
			-1,
			0,
			NULL,
			v_ancillaryMaterials,
			v_f_chemicalsPresent,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			v_f_wsr,
			v_f_palmOil,
			v_f_endangeredSpecies,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			v_bs_document_group,
			NULL
		);
	END IF;
	
	-- gt prod design
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_pdesign_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		gt_product_design_pkg.SetProdDesignAnswers (
			in_act_id,
			in_product_id,
			NULL,    
			NULL,
			v_pda_palmOil,		
			v_pda_endangeredSpecies,	
			NULL,
			v_ancillaryMaterials,	
			NULL,     
			NULL,         
			NULL ,
			NULL
		);
	END IF;
	
	-- gt transport
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_transport_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		gt_transport_pkg.SetTransportAnswers (
			in_act_id,
			in_product_id,
		  	NULL,
		  	NULL,
		  	NULL,
		  	NULL,
		  	NULL,
		  	NULL,
		  	NULL					
		);
	END IF;
	
	-- gt food
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_food_answers WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		gt_food_pkg.SetFoodAnswers (
			in_act_id,
			in_product_id,
		  	NULL,
		  	NULL,
		  	NULL,
		  	v_ancillaryMaterials,
			v_socamp_qs,
		  	v_food_esp,
		  	v_food_palmOil,
		  	NULL,
		  	NULL
		);
		
	END IF;
	
	-- gt scores (profile calc by same call)
	SELECT NVL(MAX(revision_id),-1) INTO v_rev_check FROM gt_scores WHERE product_id = in_product_id;
	IF v_rev_check = -1 THEN -- should only ever be one rev behind if never saved - which should only happen first time this is called
		-- empty values
		model_pkg.CalcProductScores(
			in_act_id,
			in_product_id,
			1
		);
	END IF;
	
	
	INSERT INTO product_revision (product_id, revision_id, description, created_by_sid, created_dtm) 
		VALUES (in_product_id, v_max_revision_id+1, in_description, v_user_sid, sysdate)
	RETURNING revision_id into out_new_rev;
	
	-- this is not totally generic
	gt_supplier_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	product_info_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	gt_packaging_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	gt_formulation_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	gt_product_design_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	gt_transport_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	gt_food_pkg.IncrementRevision(in_act_id, in_product_id, v_max_revision_id);
	-- recalc scores - we used to copy scores but actually easier just to recalc
	-- the only way they should be diff is if the model has changed - in which case the scores for all products should have been recalc'd
		model_pkg.CalcProductScores(
			in_act_id,
			in_product_id,
			v_max_revision_id + 1);

END;

PROCEDURE EditProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE
)
AS
	v_max_revision_id 				product_revision.revision_id%TYPE;
BEGIN
	
	-- always create a new revision one more than the highest one for that product
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	EditProductRevision(in_act_id, in_product_id, in_group_id, in_description, v_max_revision_id);
	
END;
	
	
-- Currently this is only called internally
PROCEDURE EditProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_description					IN product_revision.description%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE
)
AS
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE product_revision SET description = in_description WHERE product_id = in_product_id AND revision_id = in_revision_id;
	
END;


--  latest revision
PROCEDURE DeleteProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE
)
AS
	v_max_revision_id 				product_revision.revision_id%TYPE;
	out_cur							security_pkg.T_OUTPUT_CUR;
BEGIN
	
	-- always create a new revision one more than the highest one for that product
	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	DeleteProductRevision(in_act_id, in_product_id, in_group_id, v_max_revision_id);
	
END;
	

-- Currently this is only called internally
PROCEDURE DeleteProductRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_group_id						IN product_questionnaire_group.group_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE
)
AS

	v_doc_group		document_group.document_group_id%TYPE;
	
	v_ct_doc_group_id			gt_product_answers.ct_doc_group_id%TYPE;

	v_consumer_advice_3_dg		gt_product_answers.consumer_advice_3_dg%TYPE;
	v_consumer_advice_4_dg		gt_product_answers.consumer_advice_4_dg%TYPE;
	v_sustain_assess_1_dg		gt_product_answers.sustain_assess_1_dg%TYPE;
	v_sustain_assess_2_dg		gt_product_answers.sustain_assess_2_dg%TYPE;
	v_sustain_assess_3_dg		gt_product_answers.sustain_assess_3_dg%TYPE;
	v_sustain_assess_4_dg		gt_product_answers.sustain_assess_4_dg%TYPE;

BEGIN
	
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- gt supplier
	SELECT sust_doc_group_id INTO v_doc_group FROM gt_supplier_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;

	DELETE FROM gt_supplier_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	document_pkg.DeleteDocumentGroup(in_act_id, v_doc_group);
 

	
	-- gt prod info
	SELECT 
		ct_doc_group_id,
		consumer_advice_3_dg,
		consumer_advice_4_dg,
		sustain_assess_1_dg,
		sustain_assess_2_dg,
		sustain_assess_3_dg,
		sustain_assess_4_dg
	 INTO 
		v_ct_doc_group_id,
		v_consumer_advice_3_dg,
		v_consumer_advice_4_dg,
		v_sustain_assess_1_dg,
		v_sustain_assess_2_dg,
		v_sustain_assess_3_dg,
		v_sustain_assess_4_dg 
	 FROM gt_product_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	
	DELETE FROM gt_link_product WHERE product_id = in_product_id AND revision_id = in_revision_id;	
	DELETE FROM gt_country_sold_in WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_product_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	 
	document_pkg.DeleteDocumentGroup(in_act_id, v_ct_doc_group_id);
	document_pkg.DeleteDocumentGroup(in_act_id, v_consumer_advice_3_dg);
	document_pkg.DeleteDocumentGroup(in_act_id, v_consumer_advice_4_dg);
	document_pkg.DeleteDocumentGroup(in_act_id, v_sustain_assess_1_dg);
	document_pkg.DeleteDocumentGroup(in_act_id, v_sustain_assess_2_dg);
	document_pkg.DeleteDocumentGroup(in_act_id, v_sustain_assess_3_dg);
	document_pkg.DeleteDocumentGroup(in_act_id, v_sustain_assess_4_dg);

		
	
	-- gt pack
	DELETE FROM gt_pack_item WHERE product_id = in_product_id AND revision_id = in_revision_id;	
	DELETE FROM gt_trans_item WHERE product_id = in_product_id AND revision_id = in_revision_id;	
	DELETE FROM gt_packaging_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;	

	-- gt formulation
	SELECT bs_document_group INTO v_doc_group FROM gt_formulation_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fa_anc_mat WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fa_haz_chem WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fa_palm_ind WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fa_endangered_sp WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fa_wsr WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_formulation_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	document_pkg.DeleteDocumentGroup(in_act_id, v_doc_group);
	
	-- gt Product Design
	DELETE FROM gt_pda_anc_mat WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_pda_battery WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_pda_endangered_sp WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_pda_hc_item WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_pda_material_item WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_pda_palm_ind WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_pdesign_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;

	-- gt Food
	DELETE FROM gt_fd_answer_scheme WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fd_ingredient WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fd_palm_ind WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_food_anc_mat WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_fd_endangered_sp WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_food_sa_q WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_food_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	
	-- gt transport
	DELETE FROM gt_country_made_in WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_transport_answers WHERE product_id = in_product_id AND revision_id = in_revision_id;
	
	DELETE FROM gt_scores WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_scores_combined WHERE product_id = in_product_id AND revision_id = in_revision_id;
	DELETE FROM gt_profile WHERE product_id = in_product_id AND revision_id = in_revision_id;	
	
	-- TAGS
	-- restore tags from previous revision and execute questionnaires mapping procedure
	IF in_revision_id > 1  THEN
		DeleteProductTagRevision(in_act_id,in_product_id,in_revision_id-1,in_group_id);
	END IF;
	
	DELETE FROM product_revision WHERE product_id = in_product_id AND revision_id = in_revision_id;

END;

--only called internally, only to revert tags to last revision
PROCEDURE DeleteProductTagRevision(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN all_product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE
)
AS
	v_app_sid 				security_pkg.T_SID_ID;
	v_old_tag_ids			tag_pkg.T_TAG_IDS;
	v_new_tag_ids			tag_pkg.T_TAG_IDS;
	v_index					NUMBER;
BEGIN
		SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
		
		-- need to do audit logging here as deleteing old tags before inserting new tags (NOTE: ONLY THOSE THAT MAPS TO THE GIVEN QUESTIONNAIRE GROUP)
		--loop over groups
		FOR r_group IN (
			SELECT tag_group_sid,name,description 
			  FROM tag_group 
			 WHERE app_sid = v_app_sid
		)
		LOOP			
			-- get an array of olds
			v_old_tag_ids.delete;
			v_index := 1;
			FOR r IN (
				SELECT tag_id FROM product_tag
				 WHERE product_id = in_product_id
				   AND tag_id IN (  -- belongs to the tag group of this interation
					SELECT tag_id
					  FROM tag_group_member
					 WHERE tag_group_sid = r_group.tag_group_sid
					)
				   AND tag_id IN (  -- maps to questionnaires of a specific questionnaire group
				    SELECT tag_id 
					  FROM questionnaire_tag 
				     WHERE questionnaire_id IN (
					   SELECT questionnaire_id 
					     FROM questionnaire_group_membership 
					    WHERE group_id = in_group_id
					 )
				   ) 
			)
			LOOP
				v_old_tag_ids(v_index) := r.tag_id;
				v_index := v_index + 1;
			END LOOP;
			
			-- get an array of news
			v_new_tag_ids.delete;
			v_index := 1;
			FOR r IN (
				SELECT tag_id FROM product_revision_tag
				 WHERE product_id = in_product_id
				   AND revision_id = in_revision_id
				   AND group_id = in_group_id
				   AND tag_id IN (
					SELECT tag_id
					  FROM tag_group_member
					 WHERE tag_group_sid = r_group.tag_group_sid
					)
			)
			LOOP
				v_new_tag_ids(v_index) := r.tag_id;
				v_index := v_index + 1;
			END LOOP;
			
			--audit
			IF v_old_tag_ids IS NOT NULL OR v_new_tag_ids IS NOT NULL THEN
				audit_pkg.AuditTagChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_TAG_CHANGED, v_app_sid, v_app_sid, r_group.description,
					v_old_tag_ids, v_new_tag_ids, 1, in_product_id);
			END IF;
		
		END LOOP;
		
		
		-- Now, do the actual revision revert
		-- Delete relevant tags (NOTE: ONLY THOSE THAT MAPS TO THE GIVEN QUESTIONNAIRE GROUP)
		DELETE FROM product_tag 
		 WHERE product_id = in_product_id
		   AND tag_id IN (
			SELECT tag_id 
			  FROM questionnaire_tag 
			 WHERE questionnaire_id IN (
			   SELECT questionnaire_id 
				 FROM questionnaire_group_membership 
				WHERE group_id = in_group_id
			 )
		  );
		
		-- insert tags from stored tags
		INSERT INTO product_tag (product_id, tag_id, note, num) 
		SELECT prt.product_id, prt.tag_id, prt.note, prt.num 
		  FROM product_revision_tag prt
		 WHERE prt.revision_id = in_revision_id
		   AND prt.product_id = in_product_id
		   AND prt.group_id   = in_group_id;
		
		-- delete stored tags
		DELETE FROM product_revision_tag 
		 WHERE product_id = in_product_id 
		   AND revision_id = in_revision_id
		   AND group_id = in_group_id;
		
		--  remap tags<->questionnaires
		questionnaire_pkg.MapQuestionnaire(in_act_id,in_product_id);
		
END;


-- doesn't return the last revision
PROCEDURE GetProductRevisions(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_start						IN NUMBER,
	in_page_size					IN NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	OPEN out_cur FOR
	SELECT * FROM 
	(
		SELECT rownum rn, pr.* FROM
		(
			SELECT 
			product_id, revision_id, pr.description, 
			   created_by_sid, cu.full_name created_by_name, pr.created_dtm
			FROM product_revision pr, csr.csr_user cu
			WHERE product_id = in_product_id
			AND pr.created_by_sid = cu.csr_user_sid
			AND revision_id != v_max_revision_id
			ORDER BY revision_id desc
		) pr WHERE rownum <= in_start+in_page_size
	)
	WHERE rn > in_start	;
	
END;

PROCEDURE GetProductRevisionsCount(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	out_count						OUT NUMBER
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
    	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
		SELECT 
		COUNT(*) INTO out_count
		FROM product_revision
		WHERE product_id = in_product_id
		AND revision_id != v_max_revision_id;
	
END;


-- Returns the set of questionnaires according to the tags of the revision
PROCEDURE GetProductRevisionQuestion(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
	SELECT q.questionnaire_id,q.class_name,q.description,qgm.group_id   
		FROM (
			SELECT questionnaire_id, COUNT(questionnaire_id), SUM(mapped) 
			  FROM questionnaire_tag qt, product_revision_tag prt
			 WHERE prt.tag_id = qt.tag_id
			   AND product_id = in_product_id 
			   AND revision_id = in_revision_id
			 GROUP BY questionnaire_id
			HAVING COUNT(questionnaire_id) = SUM(mapped)
		) q_rev, questionnaire q,questionnaire_group_membership qgm
	WHERE q.questionnaire_id = q_rev.questionnaire_id
	AND qgm.questionnaire_id = q.questionnaire_id;
END;

END revision_pkg;
/
