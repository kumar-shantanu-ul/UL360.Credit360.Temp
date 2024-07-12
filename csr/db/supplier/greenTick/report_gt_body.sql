create or replace package body supplier.report_gt_pkg
IS

PROCEDURE RunGTProductInfoReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*, 
            psv.volume sales_volume, psv.value sales_value, 
		    CASE 
		        WHEN ((psv.volume IS NULL) AND (psv.value IS NULL)) THEN 'No sales value or volume set'
		        WHEN (psv.volume IS NULL) THEN 'No sales volume set'
		        WHEN (psv.value IS NULL) THEN 'No sales value set'
		        ELSE NULL
		    END sales_data_status,
		    report_gt_pkg.getFootPrintScore(in_act_id, p.product_id, null) foot_print_score
		FROM 
		(
			SELECT p.product_id, p.description, p.product_code, product_range, product_type, product_volume, NVL(num_linked_products, 0) num_linked_products,
			fairtrade_pct, other_fairtrade_pct, community_trade_pct, not_fairtrade_pct, reduce_energy_use_adv, reduce_water_use_adv, reduce_waste_adv, on_pack_recycling_adv,  			    
			DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete, data_quality -- scarily ineffiecient?
			FROM product p,
		    (
		        SELECT p.product_id, count(*) num_linked_products FROM gt_link_product pl, product p
		        WHERE p.product_id = pl.product_id
		        AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) pl,
			(
			    SELECT pa.product_id, pa.gt_product_range_id, pr.description product_range, gtp.gt_product_type_id, pt.description product_type,
			    DECODE(product_volume, -1, NULL, product_volume) product_volume, 
			    DECODE(pa.fairtrade_pct, -1, NULL, pa.fairtrade_pct) fairtrade_pct, 
			    DECODE(pa.other_fair_pct, -1, NULL, pa.other_fair_pct) other_fairtrade_pct, 
			    DECODE(pa.community_trade_pct, -1, NULL, pa.community_trade_pct) community_trade_pct, 
			    DECODE(pa.not_fair_pct, -1, NULL, pa.not_fair_pct) not_fairtrade_pct, 
				DECODE(pa.reduce_energy_use_adv, -1, NULL, pa.reduce_energy_use_adv) reduce_energy_use_adv, 
				DECODE(pa.reduce_water_use_adv, -1, NULL, pa.reduce_water_use_adv) reduce_water_use_adv, 
				DECODE(pa.reduce_waste_adv, -1, NULL, pa.reduce_waste_adv) reduce_waste_adv, 
				DECODE(pa.on_pack_recycling_adv, -1, NULL, pa.on_pack_recycling_adv) on_pack_recycling_adv,
				dqt.description data_quality
			    FROM gt_product_answers pa, gt_product_range pr, gt_product_type pt, gt_product gtp, data_quality_type dqt
			       WHERE pa.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = pa.product_id)
                   AND pa.product_id = gtp.product_id 
                   AND gtp.gt_product_type_id = pt.gt_product_type_id 
                   AND pa.gt_product_range_id = pr.gt_product_range_id(+)
				   AND dqt.data_quality_type_id = pa.data_quality_type_id
			) pa
			WHERE p.product_id = pa.product_id(+)
			AND p.product_id = pl.product_id(+)
			AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
		AND p.product_id = pt_filter.product_id --apply product type and range filters
        AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type

		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTFormulationReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
        	SELECT p.product_id, p.description, p.product_code, ingredient_count, 
	            -- anc mat
	            NVL(num_ancillary_materials, 0) num_ancillary_materials,
	            list_of_ancillary_materials,
	            concentrate,
	            no_haz_chem,
	            naturally_derived_pct,
	            -- chem
	            NVL(num_red_chemicals, 0) num_red_chemicals, 
	            list_of_red_chemicals,
	            NVL(num_orange_chemicals, 0) num_orange_chemicals, 
	            list_of_orange_chemicals,
	            -- prov
	            prov_mixed_agricultural_pct, 
	            prov_intensive_farmed_pct, 
	            prov_palm_oil_pct,  
	            prov_processed_palm_oil_pct, 
	            prov_wild_harvested_pct, 
	            prov_unknown_pct, 
	            prov_endangered_pct, 
	            prov_mineral_pct,  
	            -- accred                         
	            accredited_source_priority_pct, 
	            accredited_source_other_pct, 
	            accred_known_pct, 
	            accred_unknown_pct, 
	            accred_non_natural_pct,
	            DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete,
				data_quality
            FROM product p, 
            (
		        SELECT p.product_id, count(*) num_ancillary_materials, csr.stragg(anc.description) list_of_ancillary_materials FROM product p, 
                (   
                    SELECT anc.product_id, anc.gt_ancillary_material_id, description, revision_id 
                    FROM gt_fa_anc_mat anc, gt_ancillary_material am WHERE anc.gt_ancillary_material_id = am.gt_ancillary_material_id
                ) anc
		        WHERE p.product_id = anc.product_id(+)
		        AND anc.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) anc,
            (
		        SELECT p.product_id, count(*) num_red_chemicals, csr.stragg(haz.description) list_of_red_chemicals FROM product p, 
                (
                    SELECT fhc.product_id, haz.gt_hazzard_chemical_id, description, revision_id 
                    FROM gt_fa_haz_chem fhc, gt_hazzard_chemical haz WHERE fhc.gt_hazzard_chemical_id = haz.gt_hazzard_chemical_id
                    AND lower(haz.colour) = 'r'
                ) haz
		        WHERE p.product_id = haz.product_id(+)
		        AND haz.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) red,
            (
		        SELECT p.product_id, count(*) num_orange_chemicals, csr.stragg(haz.description) list_of_orange_chemicals FROM product p, 
                (
                    SELECT fhc.product_id, haz.gt_hazzard_chemical_id, description, revision_id 
                    FROM gt_fa_haz_chem fhc, gt_hazzard_chemical haz WHERE fhc.gt_hazzard_chemical_id = haz.gt_hazzard_chemical_id
                    AND lower(haz.colour) = 'o'
                ) haz
		        WHERE p.product_id = haz.product_id(+)
		        AND haz.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) orange,
            (
                SELECT pf.product_id, pf.ingredient_count, DECODE(pf.concentrate, 1, 'Yes', 0, 'No', null) concentrate, DECODE(pf.no_haz_chem, 1, 'Yes', 0, 'No', null) no_haz_chem,
                bp_crops_pct + bp_fish_pct + bp_palm_pct + bp_palm_processed_pct + bp_wild_pct naturally_derived_pct,     
                bp_crops_pct prov_mixed_agricultural_pct, 
                bp_fish_pct prov_intensive_farmed_pct, 
                bp_palm_pct prov_palm_oil_pct,  
                bp_palm_processed_pct prov_processed_palm_oil_pct, 
                bp_wild_pct prov_wild_harvested_pct, 
                bp_unknown_pct prov_unknown_pct, 
                bp_threatened_pct prov_endangered_pct, 
                bp_mineral_pct prov_mineral_pct,                           
                bs_accredited_priority_pct accredited_source_priority_pct, 
                bs_accredited_other_pct accredited_source_other_pct, 
                bs_known_pct accred_known_pct, 
                bs_unknown_pct accred_unknown_pct, 
                bs_no_natural_pct accred_non_natural_pct,
				dqt.description data_quality
			    FROM gt_formulation_answers pf, data_quality_type dqt
			       WHERE pf.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = pf.product_id)
				   AND dqt.data_quality_type_id = pf.data_quality_type_id
            ) pf
            WHERE p.product_id = pf.product_id(+)
            AND p.product_id = anc.product_id(+)
            AND p.product_id = red.product_id(+)
            AND p.product_id = orange.product_id(+)
            AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
		AND p.product_id = pt_filter.product_id --apply product type and range filters
        AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTProductDesignReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
        	SELECT p.product_id, p.description, p.product_code, ingredient_count, 
	            naturally_derived_pct,
	            -- chem
	            NVL(num_haz_chemicals, 0) num_haz_chemicals, 
	            list_of_haz_chemicals,
	            -- prov
	            prov_mixed_agricultural_pct, 
	            prov_intensive_farmed_pct, 
	            prov_palm_oil_pct,  
	            prov_processed_palm_oil_pct, 
	            prov_wild_harvested_pct, 
	            prov_unknown_pct, 
	            prov_endangered_pct, 
	            prov_mineral_pct,  
	            -- accred                         
	            accredited_source_priority_pct, 
	            accredited_source_other_pct, 
	            accred_known_pct, 
	            accred_unknown_pct, 
	            accred_non_natural_pct,
				materials_separate,
				endangered_pct,
	            -- anc mat
	            NVL(num_ancillary_materials, 0) num_ancillary_materials,
	            list_of_ancillary_materials,
	            DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete, data_quality
            FROM product p, 
            (
		        SELECT p.product_id, count(*) num_ancillary_materials, csr.stragg(anc.description) list_of_ancillary_materials FROM product p, 
                (   
                    SELECT anc.product_id, anc.gt_ancillary_material_id, description, revision_id 
                    FROM gt_pda_anc_mat anc, gt_ancillary_material am WHERE anc.gt_ancillary_material_id = am.gt_ancillary_material_id
                ) anc
		        WHERE p.product_id = anc.product_id(+)
		        AND anc.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) anc,
            (
		        SELECT p.product_id, count(*) num_haz_chemicals, csr.stragg(haz.description) list_of_haz_chemicals FROM product p, 
                (
                    SELECT DISTINCT mi.product_id, mi.revision_id, hc.description 
                      FROM gt_pda_material_item mi, gt_pda_hc_item hi, gt_pda_haz_chem hc
                     WHERE mi.gt_pda_material_item_id = hi.gt_pda_material_item_id
                       AND mi.product_id = hi.product_id
                       AND mi.revision_id = hi.revision_id
                       AND hi.gt_pda_haz_chem_id = hc.gt_pda_haz_chem_id
                ) haz
		        WHERE p.product_id = haz.product_id(+)
		        AND haz.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) chem,
			(
                SELECT  product_id, revision_id, 
                        SUM(bp_crops_pct) prov_mixed_agricultural_pct, 
                        SUM(bp_fish_pct) prov_intensive_farmed_pct, 
                        SUM(bp_palm_pct) prov_palm_oil_pct, 
                        SUM(bp_palm_processed_pct) prov_processed_palm_oil_pct, 
                        SUM(bp_wild_pct) prov_wild_harvested_pct, 
                        SUM(bp_unknown_pct) prov_unknown_pct, 
                        SUM(bp_threatened_pct) prov_endangered_pct, 
                        SUM(bp_mineral_pct) prov_mineral_pct
                  FROM
                (
                    SELECT p.product_id, revision_id, 
                           DECODE(mi.gt_pda_provenance_type_id, 1, pct_of_product, 0) bp_crops_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 2, pct_of_product, 0) bp_fish_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 3, pct_of_product, 0) bp_palm_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 4, pct_of_product, 0) bp_palm_processed_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 5, pct_of_product, 0) bp_wild_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 6, pct_of_product, 0) bp_unknown_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 7, pct_of_product, 0) bp_threatened_pct,
                           DECODE(mi.gt_pda_provenance_type_id, 8, pct_of_product, 0) bp_mineral_pct
                      FROM gt_pda_material_item mi, gt_pda_provenance_type pt, product p
                     WHERE mi.gt_pda_provenance_type_id = pt.gt_pda_provenance_type_id
                       AND p.product_id = mi.product_id
                       AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                 )  
                 GROUP BY product_id, revision_id 
			) prov,
			(
                SELECT  product_id, revision_id, 
                        SUM(bs_accredited_priority_pct) accredited_source_priority_pct, 
                        SUM(bs_accredited_other_pct) accredited_source_other_pct, 
                        SUM(bs_known_pct) accred_known_pct, 
                        SUM(bs_unknown_pct) accred_unknown_pct, 
                        SUM(bs_no_natural_pct) accred_non_natural_pct
                  FROM
                (
                    SELECT p.product_id, revision_id, 
                           DECODE(mi.gt_pda_accred_type_id, 1, pct_of_product, 0) bs_accredited_priority_pct,
                           DECODE(mi.gt_pda_accred_type_id, 2, pct_of_product, 0) bs_accredited_other_pct,
                           DECODE(mi.gt_pda_accred_type_id, 3, pct_of_product, 0) bs_known_pct,
                           DECODE(mi.gt_pda_accred_type_id, 4, pct_of_product, 0) bs_unknown_pct,
                           DECODE(mi.gt_pda_accred_type_id, 5, pct_of_product, 0) bs_no_natural_pct
                      FROM gt_pda_material_item mi, gt_pda_accred_type at, product p
                     WHERE mi.gt_pda_accred_type_id = at.gt_pda_accred_type_id
                       AND p.product_id = mi.product_id
                       AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                 )  
                 GROUP BY product_id, revision_id 
			) accred,
			(
                SELECT p.product_id, COUNT(*) ingredient_count, SUM(natural * mi.pct_of_product) naturally_derived_pct
                  FROM gt_pda_material_item mi, product p, gt_material m
                 WHERE p.product_id = mi.product_id
                   AND mi.gt_material_id = m.gt_material_id
                   AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                  GROUP BY p.product_id

			) mats,
            (
                SELECT 	pda.product_id, 
						DECODE(materials_separate, 1, 'Yes', 0, 'No', null) materials_separate, 
						endangered_pct, 
                        DECODE(electric_powered, 1, 'Yes', 0, 'No', null) electric_powered, 
                        DECODE(leaves_residue, 1, 'Yes', 0, 'No', null) leaves_residue, 
                        dt.description durability,
						dqt.description data_quality
			      FROM gt_pdesign_answers pda, gt_pda_durability_type dt, data_quality_type dqt
                 WHERE pda.gt_pda_durability_type_id = dt.gt_pda_durability_type_id(+)
			       AND pda.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = pda.product_id)
				   AND dqt.data_quality_type_id = pda.data_quality_type_id
            ) pda
            WHERE p.product_id = pda.product_id(+)
            AND p.product_id = anc.product_id(+)
            AND p.product_id = chem.product_id(+)
            AND p.product_id = prov.product_id(+)
            AND p.product_id = accred.product_id(+)		
			AND p.product_id = mats.product_id(+)			
            AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
		AND p.product_id = pt_filter.product_id --apply product type and range filters
        AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTFoodReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
        	SELECT p.product_id, p.description, p.product_code, ingredient_count, contains_GM, portion_type, SA_ingredient_issues "SA - Ingredient Issues", SA_marketing "SA - Marketing", SA_nutrition_and_health "SA - Nutrition and Health", SA_ingredients "SA - Ingredients",
	            -- chem
				-- no chemicals for food....
	            --NVL(num_haz_chemicals, 0) num_haz_chemicals, 
	            --list_of_haz_chemicals,
	            
				
				---- prov
				prov_mixed_agricultural_pct, 
				prov_intensive_farmed_pct, 
				prov_palm_oil_pct, 
				prov_processed_veg_oil_pct, 
				prov_wild_harvested_pct, 
				prov_fish_pole_and_line, 
				prov_fishing_nets, 
				prov_fish_long_line, 
				prov_unknown_pct, 
				prov_mineral_or_synth_pct,
	            ---- accred                         
	            accredited_source_priority_pct, 
	            accredited_source_other_pct, 
	            accred_known_pct, 
	            accred_unknown_pct, 
				--materials_separate,
				--endangered_pct,
	            -- anc mat
	            NVL(num_ancillary_materials, 0) num_ancillary_materials,
	            list_of_ancillary_materials,
	            DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete, data_quality
            FROM product p, 
            (
		        SELECT p.product_id, count(*) num_ancillary_materials, csr.stragg(anc.description) list_of_ancillary_materials FROM product p, 
                (   
                    SELECT anc.product_id, anc.gt_ancillary_material_id, description, revision_id 
                    FROM gt_food_anc_mat anc, gt_ancillary_material am WHERE anc.gt_ancillary_material_id = am.gt_ancillary_material_id
                ) anc
		        WHERE p.product_id = anc.product_id(+)
		        AND anc.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) anc,
			(
				SELECT p.product_id, CSR.STRAGG(sq.question_name || ' (' || DECODE(NVL(sq.default_gt_sa_score, -1), -1, 'No Social Issues', 0, 'Positive', 1, 'Low', 2, 'Medium', 3, 'High', 'Unknown Issue Severity') || ')') SA_ingredient_issues
                  FROM gt_sa_question sq, product p, gt_food_sa_q fq
                 WHERE p.product_id = fq.product_id
				   AND sq.gt_sa_issue_id = 1
                   AND fq.gt_sa_question_id = sq.gt_sa_question_id
                   AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                  GROUP BY p.product_id
			) socamp_ingred_issues,
			(
				SELECT p.product_id, CSR.STRAGG(sq.question_name || ' (' || DECODE(NVL(sq.default_gt_sa_score, -1), -1, 'No Social Issues', 0, 'Positive', 1, 'Low', 2, 'Medium', 3, 'High', 'Unknown Issue Severity') || ')') SA_marketing
                  FROM gt_sa_question sq, product p, gt_food_sa_q fq
                 WHERE p.product_id = fq.product_id
				   AND sq.gt_sa_issue_id = 3
                   AND fq.gt_sa_question_id = sq.gt_sa_question_id
                   AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                  GROUP BY p.product_id
			) socamp_marketing,
			(
				SELECT p.product_id, CSR.STRAGG(sq.question_name || ' (' || DECODE(NVL(sq.default_gt_sa_score, -1), -1, 'No Social Issues', 0, 'Positive', 1, 'Low', 2, 'Medium', 3, 'High', 'Unknown Issue Severity') || ')') SA_nutrition_and_health
                  FROM gt_sa_question sq, product p, gt_food_sa_q fq
                 WHERE p.product_id = fq.product_id
				   AND sq.gt_sa_issue_id = 2
                   AND fq.gt_sa_question_id = sq.gt_sa_question_id
                   AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                  GROUP BY p.product_id
			) socamp_nutrition,
			(
				SELECT p.product_id, CSR.STRAGG(it.description || ' (' || DECODE(NVL(it.default_gt_sa_score, -1), -1, 'No Social Issues', 0, 'Positive', 1, 'Low', 2, 'Medium', 3, 'High', 'Unknown Issue Severity') || ')') SA_ingredients
                  FROM gt_fd_ingred_type it, product p, gt_fd_ingredient ing
                 WHERE p.product_id = ing.product_id
				   AND it.gt_fd_ingred_type_id = ing.gt_fd_ingred_type_id
                   AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                  GROUP BY p.product_id
			) socamp_ingred,
			(
                SELECT  product_id, revision_id, 
                        SUM(bp_crops_pct) prov_mixed_agricultural_pct, 
                        SUM(bp_intense_farm) prov_intensive_farmed_pct, 
                        SUM(bp_palm_pct) prov_palm_oil_pct, 
                        SUM(bp_palm_processed_pct) prov_processed_veg_oil_pct, 
                        SUM(bp_wild_pct) prov_wild_harvested_pct, 
                        SUM(bp_fish_pole) prov_fish_pole_and_line, 
                        SUM(bp_fish_nets) prov_fishing_nets, 
                        SUM(bp_fish_line) prov_fish_long_line, 
                        SUM(bp_unknown) prov_unknown_pct, 
                        SUM(bp_mineral_pct) prov_mineral_or_synth_pct
                FROM
                (
                    SELECT p.product_id, revision_id, 
                           DECODE(fi.gt_fd_ingred_prov_type_id, 10, pct_of_product, 0) bp_crops_pct,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 11, pct_of_product, 0) bp_intense_farm,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 12, pct_of_product, 0) bp_palm_pct,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 13, pct_of_product, 0) bp_palm_processed_pct,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 14, pct_of_product, 0) bp_wild_pct,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 15, pct_of_product, 0) bp_fish_pole,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 16, pct_of_product, 0) bp_fish_nets,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 17, pct_of_product, 0) bp_fish_line,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 18, pct_of_product, 0) bp_unknown,
                           DECODE(fi.gt_fd_ingred_prov_type_id, 19, pct_of_product, 0) bp_mineral_pct
                      FROM gt_fd_ingredient fi, gt_fd_ingred_prov_type pt, product p
                     WHERE fi.gt_fd_ingred_prov_type_id = pt.gt_fd_ingred_prov_type_id
                       AND p.product_id = fi.product_id
                       AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                 )  
                 GROUP BY product_id, revision_id 
			) prov,
			(
                SELECT  product_id, revision_id, 
                        SUM(bs_accredited_priority_pct) accredited_source_priority_pct, 
                        SUM(bs_accredited_other_pct) accredited_source_other_pct, 
                        SUM(bs_known_pct) accred_known_pct, 
                        SUM(bs_unknown_pct) accred_unknown_pct
                  FROM
                (
                    SELECT p.product_id, revision_id, 
                           DECODE(fi.gt_ingred_accred_type_id, 6, pct_of_product, 0) bs_accredited_priority_pct,
                           DECODE(fi.gt_ingred_accred_type_id, 2, pct_of_product, 0) bs_accredited_other_pct,
                           DECODE(fi.gt_ingred_accred_type_id, 4, pct_of_product, 0) bs_known_pct,
                           DECODE(fi.gt_ingred_accred_type_id, 5, pct_of_product, 0) bs_unknown_pct
                      FROM gt_fd_ingredient fi, gt_ingred_accred_type at, product p
                     WHERE fi.gt_ingred_accred_type_id = at.gt_ingred_accred_type_id
                       AND p.product_id = fi.product_id
                       AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                 )  
                 GROUP BY product_id, revision_id 
			) accred,
			(
                SELECT p.product_id, COUNT(*) ingredient_count, DECODE(MAX(fi.contains_gm), 1, 'Yes', 'No') contains_GM
                  FROM gt_fd_ingredient fi, product p, gt_fd_ingred_type ft
                 WHERE p.product_id = fi.product_id
                   AND fi.gt_fd_ingred_type_id = ft.gt_fd_ingred_type_id
                   AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
                  GROUP BY p.product_id

			) ingreds,
            (
                SELECT 	fda.product_id, 
						pct_added_water,
						wsr.description water_stressed_region,
						pct_high_risk endangered_pct, 
                        dqt.description data_quality,
						pt.description portion_type
			      FROM gt_food_answers fda, data_quality_type dqt, gt_fd_portion_type pt, gt_water_stress_region wsr
                 WHERE fda.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = fda.product_id)
				   AND dqt.data_quality_type_id = fda.data_quality_type_id
				   AND wsr.gt_water_stress_region_id = fda.gt_water_stress_region_id
				   AND pt.gt_fd_portion_type_id = fda.gt_fd_portion_type_id
            ) fda
            WHERE p.product_id = fda.product_id(+)
            AND p.product_id = anc.product_id(+)
            AND p.product_id = prov.product_id(+)
            AND p.product_id = accred.product_id(+)		
			AND p.product_id = ingreds.product_id(+)	
			AND p.product_id = socamp_ingred_issues.product_id(+)
			AND p.product_id = socamp_marketing.product_id(+)
			AND p.product_id = socamp_nutrition.product_id(+)
			AND p.product_id = socamp_ingred.product_id(+)
            AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
		AND p.product_id = pt_filter.product_id --apply product type and range filters
        AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTPackagingReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
        	SELECT p.product_id, p.description, p.product_code, pack_type, viscosity_type, 
			DECODE(weight_inc_pkg, 1, weight, 0, (NVL(total_weight_of_pack_g, 0) + weight)) total_weight_inc_pack_g, 
			NVL(total_weight_of_pack_g, 0) total_weight_of_pack_g, 
            refill_pack, single_product_in_pack, settle_in_transit, gift_container_type, packaging_layers, total_prod_volume_ml, transit_product_volume_cc, transit_pack_volume_cc, correct_biopolymer_use,
            packaging_meets_requirements, packaging_shelf_ready,  transit_packaging_type, 
			DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete, data_quality
            FROM product p, 
            (
		        SELECT p.product_id, sum(weight_grams) total_weight_of_pack_g FROM gt_pack_item pki, product p
		        WHERE p.product_id = pki.product_id
		        AND revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id  
		    ) pki,
            (
                SELECT pk.product_id, pk.gt_access_pack_type_id, pt.description pack_type, pk.gt_access_visc_type_id, vt.description viscosity_type,
                prod_weight weight, weight_inc_pkg, 
                DECODE(refill_pack, 1, 'Yes', 0, 'No', null) refill_pack, 
                DECODE(single_in_pack, 1, 'Yes', 0, 'No', null) single_product_in_pack, 
                DECODE(settle_in_transit, 1, 'Yes', 0, 'No', null) settle_in_transit,
                gct.description gift_container_type, pl.description packaging_layers, 
                DECODE(vol_package, -1, null, vol_package) total_prod_volume_ml, 
                DECODE(vol_prod_tran_pack, -1, null, vol_prod_tran_pack)  transit_product_volume_cc, DECODE(vol_tran_pack , -1, null, vol_tran_pack)transit_pack_volume_cc,
                DECODE(correct_biopolymer_use, 1, 'Yes', 0, 'No', null) correct_biopolymer_use, 
                DECODE(pack_meet_req, 1, 'Yes', 0, 'No', null) packaging_meets_requirements, 
                DECODE(pack_shelf_ready, 1, 'Yes', 0, 'No', null) packaging_shelf_ready,         
                --DECODE(pack_consum_rcyld, 1, 'Yes', 0, 'No', null) uses_post_consumer_material,       
                tpt.description transit_packaging_type,
				pk.data_quality data_quality
			    FROM (
					SELECT gpt.gt_access_visc_type_id, gpa2.*, gpa. prod_weight, gpa.weight_inc_pkg, dqt.description data_quality
					  FROM gt_product_answers gpa, gt_product_type gpt, gt_packaging_answers gpa2, gt_product gtp, data_quality_type dqt
					 WHERE gpa.product_id = gtp.product_id
					   AND gtp.gt_product_type_id = gpt.gt_product_type_id
					   AND gpa.product_id = gpa2.product_id
					   AND gpa.revision_id = gpa2.revision_id
					   AND gpa2.data_quality_type_id = dqt.data_quality_type_id
					) pk, gt_access_pack_type pt, gt_access_visc_type vt, gt_gift_cont_type gct, gt_pack_layers_type pl, gt_trans_pack_type tpt
			       WHERE pk.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = pk.product_id)
			       AND pk.gt_access_pack_type_id = pt.gt_access_pack_type_id(+)
			       AND pk.gt_access_visc_type_id = vt.gt_access_visc_type_id(+) 
			       AND pk.gt_gift_cont_type_id = gct.gt_gift_cont_type_id(+) 
			       AND pk.gt_pack_layers_type_id = pl.gt_pack_layers_type_id(+) 
                   AND pk.gt_trans_pack_type_id = tpt.gt_trans_pack_type_id(+) 
            ) pk
            WHERE p.product_id = pk.product_id(+)
            AND pk.product_id = pki.product_id(+)
            AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTTransportReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN
	
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
        SELECT p.product_id, p.description, p.product_code, 
            product_same_continent_pct,
            product_between_continents_pct,
            product_unknown_continent_pct, 
            pack_same_continent_pct,
            pack_between_continents_pct,
            pack_unknown_continent_pct, 
            NVL(num_countries_sold_in, 0) num_countries_sold_in, list_countries_sold_in,
            DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete, ta.data_quality
            FROM product p, 
		    (
                SELECT p.product_id, count(*) num_countries_sold_in, csr.stragg(csi.country) list_countries_sold_in FROM product p, 
                (   
                    SELECT csi.product_id, country, revision_id 
                    FROM gt_country_sold_in csi, country c WHERE csi.country_code = c.country_code
                ) csi
		        WHERE p.product_id = csi.product_id(+)
		        AND csi.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		        GROUP BY p.product_id 
		    ) csi,
            (
                SELECT ta.product_id,
                    prod_in_cont_pct product_same_continent_pct,
                    prod_btwn_cont_pct product_between_continents_pct,
                    prod_cont_un_pct product_unknown_continent_pct,
                    pack_in_cont_pct pack_same_continent_pct,
                    pack_btwn_cont_pct pack_between_continents_pct,
                    pack_cont_un_pct pack_unknown_continent_pct,
					dqt.description data_quality
			    FROM gt_transport_answers ta, data_quality_type dqt
			       WHERE ta.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = ta.product_id)
				   AND dqt.data_quality_type_id = ta.data_quality_type_id
            ) ta
            WHERE p.product_id = ta.product_id(+)
            AND p.product_id = csi.product_id(+)
            AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTSupplierReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
        	SELECT p.product_id, p.description, p.product_code, supplier_relation_type,
            DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete, data_quality
            FROM product p, 
            (
                SELECT sa.product_id, rt.description supplier_relation_type,
				dqt.description data_quality
			    FROM gt_supplier_answers sa, gt_sus_relation_type rt, data_quality_type dqt
			       WHERE sa.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = sa.product_id)
                   AND sa.gt_sus_relation_type_id = rt.gt_sus_relation_type_id(+) 
				   AND dqt.data_quality_type_id = sa.data_quality_type_id
            ) sa
            WHERE p.product_id = sa.product_id(+)
            AND p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTPackagingItemReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
			SELECT p.product_id, p.description, p.product_code, st.description pack_shape, mt.description material, weight_grams, pct_recycled, DECODE(contains_biopolymer, 1, 'Yes', 'No') contains_biopolymer
			FROM gt_pack_item pi, product p, gt_pack_shape_type st, gt_pack_material_type mt
			WHERE p.product_id = pi.product_id
			AND pi.gt_pack_shape_type_id = st.gt_pack_shape_type_id
			AND pi.gt_pack_material_type_id = mt.gt_pack_material_type_id
			AND p.product_id IN 
			(
			    SELECT p.product_id
			    FROM product p
			    WHERE p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
			)
			AND pi.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTTransPackItemReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		(
			SELECT p.product_id, p.description, p.product_code, mt.description material, weight_grams, pct_recycled
			FROM gt_trans_item pi, product p, gt_trans_material_type mt
			WHERE p.product_id = pi.product_id
			AND pi.gt_trans_material_type_id = mt.gt_trans_material_type_id
			AND p.product_id IN 
			(
			    SELECT p.product_id
			    FROM product p
			    WHERE p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
			)
			AND pi.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;

PROCEDURE RunGTWaterImpactReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);
	
	OPEN out_cur FOR
		SELECT p.*
		FROM 
		--(
		--	SELECT p.product_id, p.description, p.product_code, gts.score_water_use water_use, gts.score_water_in_prod water_in_product, 
		--	gtp.score_water_raw_mat water_in_raw_materials, gtp.score_water_mnfct water_in_manufacture, gtp.score_water_wsr water_stressed_region_factor, 
		--	gtp.score_water_contained
		--	 FROM gt_scores gts, product p, gt_profile gtp
		--	WHERE p.product_id = gts.product_id (+)
		--	  AND p.product_id = gtp.product_id (+)
		--	
		--	AND (gts.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id) OR gts.revision_id IS NULL)            
		--	AND (gtp.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id) OR gtp.revision_id IS NULL)            
		--	AND p.product_id IN 
		--	(
		--	    SELECT p.product_id
		--	      FROM product p
		--	     WHERE p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
		--	)
		--) p, 
		(
			SELECT p.product_id, p.description, p.product_code, gts.score_water_use water_use, gts.score_water_in_prod water_in_product, 
			gtp.score_water_raw_mat water_in_raw_materials, gtp.score_water_mnfct water_in_manufacture, gtp.score_water_wsr water_stressed_region_factor, 
			gtp.score_water_contained, w.description_list
			 FROM gt_scores gts, gt_product p, gt_profile gtp, 
       (
        select product_id, revision_id, csr.stragg(description) description_list, 1 class_id 
        from gt_fa_wsr faw, gt_water_stress_region w 
        WHERE faw.gt_water_stress_region_id = w.gt_water_stress_region_id
        GROUP BY product_id, revision_id, 1
        UNION
        select product_id, revision_id, csr.stragg(description) description_list, class_id FROM
        (
        select DISTINCT product_id, revision_id, description, 2 class_id 
        from gt_pda_material_item mi, gt_water_stress_region w 
        WHERE mi.gt_water_stress_region_id = w.gt_water_stress_region_id
        )
        GROUP BY product_id, revision_id, class_id
       ) w
			WHERE p.product_id = gts.product_id (+)
			  AND p.product_id = gtp.product_id (+)		
        AND p.product_id = w.product_id (+)	
        AND p.gt_product_class_id = w.class_id(+)
			AND (gts.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id) OR gts.revision_id IS NULL)            
			AND (gtp.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id) OR gtp.revision_id IS NULL)    
      AND (w.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id) OR w.revision_id IS NULL) 
	  ) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
		AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;


PROCEDURE RunGTScoreReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,-- not used
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	SELECT app_sid INTO v_app_sid FROM customer_period WHERE period_id = in_period_id;

	-- do a general admin check
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	OPEN out_cur FOR
		SELECT 	
            p.description, p.product_code, psv.volume sales_volume,
				product_type_description, product_range_description,    
            DECODE(NVL(score_nat_derived, -1), -1, 'Not set',  score_nat_derived) score_nat_derived,   
            DECODE(NVL(score_chemicals, -1), -1, 'Not set',  score_chemicals) score_chemicals,         
            DECODE(NVL(score_source_biod, -1), -1, 'Not set',  score_source_biod) score_source_biod,       
            DECODE(NVL(score_accred_biod, -1), -1, 'Not set',  score_accred_biod) score_accred_biod,       
            DECODE(NVL(score_fair_trade, -1), -1, 'Not set',  score_fair_trade) score_fair_trade,        
            DECODE(NVL(score_renew_pack, -1), -1, 'Not set',  score_renew_pack) score_renew_pack,    
            DECODE(LEAST(NVL(score_nat_derived, -1), NVL(score_chemicals, -1), NVL(score_source_biod, -1), NVL(score_accred_biod, -1), NVL(score_fair_trade, -1), NVL(score_renew_pack, -1)), -1, 'Not set', CASE WHEN score_source_biod >= model_pkg.TRIP_SCORE_BIODIVERSITY THEN model_pkg.MAX_SCORE_SUSTAINABLE WHEN score_accred_biod >= model_pkg.TRIP_SCORE_BIODIVERSITY_ACC THEN model_pkg.MAX_SCORE_SUSTAINABLE WHEN score_chemicals >= model_pkg.TRIP_SCORE_CHEM_HAZ THEN model_pkg.MAX_SCORE_SUSTAINABLE ELSE score_nat_derived + score_chemicals + score_source_biod + score_accred_biod + score_fair_trade + score_renew_pack END) section_score_sust_sourced,
            DECODE(LEAST(NVL(score_nat_derived, -1), NVL(score_chemicals, -1), NVL(score_source_biod, -1), NVL(score_accred_biod, -1), NVL(score_fair_trade, -1), NVL(score_renew_pack, -1)), -1, 'Not set', score_nat_derived + score_chemicals + score_source_biod + score_accred_biod + score_fair_trade + score_renew_pack) raw_section_score_sust_sourced,
			
            DECODE(NVL(score_whats_in_prod, -1), -1, 'Not set',  score_whats_in_prod) score_impact_of_materials,     
            DECODE(NVL(score_water_in_prod, -1), -1, 'Not set',  score_water_in_prod) score_water_in_prod,     
            DECODE(NVL(score_energy_in_prod, -1), -1, 'Not set',  score_energy_in_prod) score_energy_in_prod,    
            DECODE(NVL(score_pack_impact, -1), -1, 'Not set',  score_pack_impact) score_pack_impact,       
            DECODE(NVL(score_pack_opt, -1), -1, 'Not set',  score_pack_opt) score_pack_opt,          
            DECODE(NVL(score_recycled_pack, -1), -1, 'Not set',  score_recycled_pack) score_recycled_pack,     
            DECODE(LEAST(NVL(score_whats_in_prod, -1), NVL(score_water_in_prod, -1), NVL(score_energy_in_prod, -1), NVL(score_pack_impact, -1), NVL(score_pack_opt, -1), NVL(score_recycled_pack, -1)), -1, 'Not set', CASE WHEN score_pack_impact >= model_pkg.TRIP_SCORE_PACK_IMPACT THEN model_pkg.MAX_SCORE_FORMULATION ELSE score_whats_in_prod + score_water_in_prod + score_energy_in_prod + score_pack_impact + score_pack_opt + score_recycled_pack END) section_score_design_and_mfr,
            DECODE(LEAST(NVL(score_whats_in_prod, -1), NVL(score_water_in_prod, -1), NVL(score_energy_in_prod, -1), NVL(score_pack_impact, -1), NVL(score_pack_opt, -1), NVL(score_recycled_pack, -1)), -1, 'Not set', score_whats_in_prod + score_water_in_prod + score_energy_in_prod + score_pack_impact + score_pack_opt + score_recycled_pack) raw_section_score_design_mfr,
			
            DECODE(NVL(score_supp_management, -1), -1, 'Not set',  score_supp_management) score_supp_management,   
            DECODE(NVL(score_trans_raw_mat, -1), -1, 'Not set',  score_trans_raw_mat) score_trans_raw_mat,     
            DECODE(NVL(score_trans_to_boots, -1), -1, 'Not set',  score_trans_to_boots) score_trans_to_boots,    
            DECODE(NVL(score_trans_packaging, -1), -1, 'Not set',  score_trans_packaging) score_trans_packaging,   
            DECODE(NVL(score_trans_opt, -1), -1, 'Not set',  score_trans_opt) score_trans_opt,        
            DECODE(NVL(score_energy_dist, -1), -1, 'Not set',  score_energy_dist) score_energy_dist,   			
            DECODE(LEAST(NVL(score_supp_management, -1), NVL(score_trans_raw_mat, -1), NVL(score_trans_to_boots, -1), NVL(score_trans_packaging, -1), NVL(score_trans_opt, -1), NVL(score_energy_dist, -1)), -1, 'Not set', CASE WHEN score_supp_management >= model_pkg.TRIP_SCORE_SUPP_MAN THEN model_pkg.MAX_SCORE_SUPPLY ELSE score_supp_management + score_trans_raw_mat + score_trans_to_boots + score_trans_packaging + score_trans_opt + score_energy_dist END) section_score_product_supply,
            DECODE(LEAST(NVL(score_supp_management, -1), NVL(score_trans_raw_mat, -1), NVL(score_trans_to_boots, -1), NVL(score_trans_packaging, -1), NVL(score_trans_opt, -1), NVL(score_energy_dist, -1)), -1, 'Not set', score_supp_management + score_trans_raw_mat + score_trans_to_boots + score_trans_packaging + score_trans_opt + score_energy_dist) raw_section_score_prod_supply,
			
            DECODE(NVL(score_water_use, -1), -1, 'Not set',  score_water_use) score_water_use,         
            DECODE(NVL(score_energy_use, -1), -1, 'Not set',  score_energy_use) score_energy_use,        
            DECODE(NVL(score_ancillary_req, -1), -1, 'Not set',  score_ancillary_req) score_ancillary_req,     
            DECODE(LEAST(NVL(score_water_use, -1), NVL(score_energy_use, -1), NVL(score_renew_pack, -1)), -1, 'Not set',score_water_use + score_energy_use + score_ancillary_req) section_score_use_at_home,
			
            DECODE(NVL(score_prod_waste, -1), -1, 'Not set',  score_prod_waste) score_prod_waste,        
            DECODE(NVL(score_recyclable_pack, -1), -1, 'Not set',  score_recyclable_pack) score_recyclable_pack,   
            DECODE(NVL(score_recov_pack, -1), -1, 'Not set',  score_recov_pack) score_recov_pack,
            DECODE(LEAST(NVL(score_prod_waste, -1), NVL(score_recyclable_pack, -1), NVL(score_recov_pack, -1)), -1, 'Not set',score_prod_waste + score_recyclable_pack + score_recov_pack) section_score_end_of_life,
			
            report_gt_pkg.getFootPrintScore(in_act_id, p.product_id, null) foot_print_score,
            DECODE(model_pkg.IsModelComplete(in_act_id, p.product_id, (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id)), 1, 'Yes', 0, 'No') is_model_complete
		FROM    
		(       
            SELECT p.product_id, p.description, p.product_code, NVL(product_type_description, 'No type set') product_type_description, NVL(product_range_description, 'No range set') product_range_description, 
				score_nat_derived, 
				score_chemicals, 
				score_source_biod, 
				score_accred_biod, 
				score_fair_trade, 
				score_renew_pack, 
				score_whats_in_prod, 
				score_water_in_prod, 
				score_energy_in_prod,
				score_pack_impact, 
				score_pack_opt, 
				score_recycled_pack, 
				score_supp_management,
				score_trans_raw_mat, 
				score_trans_to_boots,
				score_trans_packaging,
				score_trans_opt, 
				score_energy_dist,
				score_water_use, 
				score_energy_use, 
				score_ancillary_req, 
				score_prod_waste, 
				score_recyclable_pack,
				score_recov_pack
            FROM product p, gt_scores gts, 
            (
                SELECT pr.product_id,
                   product_type_description, product_range_description
                FROM product_revision pr, 
                (
                    SELECT pa.*, gtp.description product_type_description, gtr.description product_range_description 
					  FROM gt_product_answers pa, gt_product p, gt_product_type gtp, gt_product_range gtr 
                     WHERE pa.product_id = p.product_id
					   AND pa.gt_product_range_id = gtr.gt_product_range_id (+)
                       AND p.gt_product_type_id = gtp.gt_product_type_id 
                ) pa
                WHERE pr.product_id = pa.product_id (+)
                AND pr.revision_id = pa.revision_id (+)
                AND pr.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = pr.product_id)
            ) pa
            WHERE p.product_id = gts.product_id (+)
            AND p.product_id = pa.product_id(+)
            AND (gts.revision_id = (SELECT MAX(revision_id) from product_revision WHERE product_id = p.product_id) OR gts.revision_id IS NULL)            
            AND p.product_id IN 
            (
                SELECT p.product_id
                FROM product p
                WHERE p.app_sid = v_app_sid -- not strictly needed as sales type restricts to app by tag id
            )
		) p,
		(
    		-- want the status of the green tick group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.group_id = qg.group_id 
			AND lower(qg.name) = 'green tick'
		) ps,
		(
			SELECT pa.product_id 
			  FROM gt_product_answers pa, gt_product gtp,
				  (SELECT gt_product_type_id 
					 FROM gt_user_report_product_types 
					WHERE csr_user_sid = v_user_sid) urpt, 
				  (SELECT gt_product_range_id 
					 FROM gt_user_report_product_ranges 
					WHERE csr_user_sid = v_user_sid) urpr
			 WHERE revision_id = (SELECT MAX(revision_id) FROM gt_product_answers par WHERE par.product_id = pa.product_id) 
			   AND pa.product_id = gtp.product_id
			   AND gtp.gt_product_type_id = urpt.gt_product_type_id
			   AND pa.gt_product_range_id = urpr.gt_product_range_id
		) pt_filter,
		(SELECT * FROM product_sales_volume WHERE period_id = in_period_id) psv,
		tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND p.product_id = ps.product_id
        AND p.product_id = psv.product_id(+)
        AND p.product_id = pt_filter.product_id --apply product type and range filters
		AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'gtproductinfo')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- sales type
		ORDER BY LOWER(p.description);
END;


PROCEDURE ClearReportSettings(
	in_act_id				IN security_pkg.T_ACT_ID
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Delete existing settings
	DELETE FROM gt_user_report_product_types
	 WHERE csr_user_sid = v_user_sid;
	
	DELETE FROM gt_user_report_product_ranges
	 WHERE csr_user_sid = v_user_sid;	
END;


PROCEDURE SetReportSettings(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_type_groups	IN tag_pkg.T_TAG_IDS,
	in_product_types		IN tag_pkg.T_TAG_IDS,
	in_product_ranges		IN tag_pkg.T_TAG_IDS
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Delete existing settings
	DELETE FROM gt_user_report_product_types
	 WHERE csr_user_sid = v_user_sid;
	
	DELETE FROM gt_user_report_product_ranges
	 WHERE csr_user_sid = v_user_sid;
	
	-- Insert product ranges
	IF NOT (in_product_ranges.COUNT = 1 AND in_product_ranges(1) IS NULL) THEN
		FOR i IN in_product_ranges.FIRST .. in_product_ranges.LAST
		LOOP
			INSERT INTO gt_user_report_product_ranges (csr_user_sid, gt_product_range_id)
			  VALUES(v_user_sid, in_product_ranges(i));
		END LOOP;
	END IF;
	  
	-- Insert product types and groups
	
	-- both array should be distinctive, that is every product in in_product_types has group that
	-- doesn't exist in in_product_type_groups.
	
	IF NOT (in_product_types.COUNT = 1 AND in_product_types(1) IS NULL) THEN
		FOR i IN in_product_types.FIRST .. in_product_types.LAST
		LOOP
			INSERT INTO gt_user_report_product_types (csr_user_sid, gt_product_type_id)
			  VALUES(v_user_sid, in_product_types(i));
		END LOOP;
	END IF;
	
	IF NOT (in_product_type_groups.COUNT = 1 AND in_product_type_groups(1) IS NULL) THEN
		FOR i IN in_product_type_groups.FIRST .. in_product_type_groups.LAST
		LOOP
			INSERT INTO gt_user_report_product_types
			SELECT gt_product_type_id,v_user_sid 
			  FROM gt_product_type pt, gt_product_type_group ptg 
			 WHERE pt.gt_product_type_group_id = ptg.gt_product_type_group_id
			   AND pt.gt_product_type_group_id = in_product_type_groups(i)
			   AND gt_product_type_id NOT IN (
										SELECT gt_product_type_id 
										  FROM gt_user_report_product_types 
										 WHERE csr_user_sid = v_user_sid
										);
		END LOOP;
	END IF;
	
END;


PROCEDURE GetReportProductTypes(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	OPEN out_cur FOR
		
		SELECT pt.gt_product_type_id, pt.gt_product_type_group_id
		  FROM gt_user_report_product_types urpt,gt_product_type pt
		 WHERE urpt.gt_product_type_id = pt.gt_product_type_id
		   AND csr_user_sid = v_user_sid 
		   AND pt.gt_product_type_group_id NOT IN (
				SELECT actual.gt_product_type_group_id  
				  FROM (
					SELECT pt.gt_product_type_group_id,COUNT(urpt.gt_product_type_id) num_products
					  FROM (
						SELECT gt_product_type_id 
						  FROM gt_user_report_product_types 
						 WHERE csr_user_sid = v_user_sid
						) urpt,gt_product_type pt
					WHERE urpt.gt_product_type_id (+)= pt.gt_product_type_id
					GROUP BY pt.gt_product_type_group_id
				  ) actual,
				 (
				   SELECT pt.gt_product_type_group_id,COUNT(pt.gt_product_type_id) num_products
					 FROM gt_product_type pt
					GROUP BY pt.gt_product_type_group_id
				 ) avail
				WHERE actual.gt_product_type_group_id = avail.gt_product_type_group_id
				AND actual.num_products = avail.num_products);
		 
END;

PROCEDURE GetReportProductTypeGroups(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT actual.gt_product_type_group_id  
		  FROM (
			SELECT pt.gt_product_type_group_id,COUNT(urpt.gt_product_type_id) num_products
			  FROM (
				SELECT gt_product_type_id 
				  FROM gt_user_report_product_types 
				 WHERE csr_user_sid = v_user_sid
				) urpt,gt_product_type pt
			WHERE urpt.gt_product_type_id (+)= pt.gt_product_type_id
			GROUP BY pt.gt_product_type_group_id
		  ) actual,
		 (
		   SELECT pt.gt_product_type_group_id,COUNT(pt.gt_product_type_id) num_products
			 FROM gt_product_type pt
			GROUP BY pt.gt_product_type_group_id
		 ) avail
		WHERE actual.gt_product_type_group_id = avail.gt_product_type_group_id
		AND actual.num_products = avail.num_products;
		 
END;


PROCEDURE GetReportProductRanges(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT gt_product_range_id
		  FROM gt_user_report_product_ranges
		 WHERE csr_user_sid = v_user_sid;
END;


FUNCTION GetFootPrintScore (
    in_act_id       IN security_pkg.T_ACT_ID,
    in_product_id   IN product.product_id%TYPE,
    in_revision_id  IN product_revision.revision_id%TYPE
) RETURN NUMBER
AS
    v_revision_id   		product_revision.revision_id%TYPE;
    v_score_biod    		NUMBER(10, 2);
    v_score_accred_biod     NUMBER(10, 2);
    v_score_chemicals    	NUMBER(10, 2);
    v_score_pack_impact     NUMBER(10, 2);
    v_score_supp_management NUMBER(10, 2);
    v_sustainable   		NUMBER(10, 5);
    v_formulation   		NUMBER(10, 5);
    v_supply        		NUMBER(10, 5);
    v_use_at_home   		NUMBER(10, 5);
    v_end_of_line   		NUMBER(10, 5);
    v_graph_area    		NUMBER(10, 3);
BEGIN

    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- use max revision if null
	IF in_revision_id IS NULL 
        THEN SELECT MAX(revision_id) INTO v_revision_id FROM product_revision WHERE product_id = in_product_id;
        ELSE v_revision_id := in_revision_id;
	END IF;
	
	-- check if model is complete - otherwise return null
	IF model_pkg.IsModelComplete(in_act_id, in_product_id, v_revision_id) = 0
        THEN RETURN null;
    END IF;

    SELECT score_source_biod, score_accred_biod, score_chemicals, score_pack_impact, score_supp_management 
	  INTO v_score_biod, v_score_accred_biod, v_score_chemicals, v_score_pack_impact, v_score_supp_management 
	  FROM gt_scores 
	 WHERE product_id = in_product_id 
	   AND revision_id = v_revision_id;

	-- if the score for 
	--		biodiversity provenance >= 10 OR
	--		biodiversity accred >= 5 OR
	-- 		haz chemical score >= 10 OR	 
	-- MAX the score for this score group
    IF v_score_biod >= model_pkg.TRIP_SCORE_BIODIVERSITY OR v_score_accred_biod >= model_pkg.TRIP_SCORE_BIODIVERSITY_ACC OR v_score_chemicals >= model_pkg.TRIP_SCORE_CHEM_HAZ THEN
		v_sustainable := 100; 
	ELSE   
        SELECT (score_nat_derived + score_chemicals + score_source_biod + score_accred_biod + score_fair_trade + score_renew_pack) / model_pkg.MAX_SCORE_SUSTAINABLE * 100 
		  INTO v_sustainable 
		  FROM gt_scores 
		 WHERE product_id = in_product_id 
		   AND revision_id = v_revision_id;
    END IF;

	-- if the score for 
	--		pack impact >= 8 OR
	-- MAX the score for this score group	
    IF v_score_pack_impact >= model_pkg.TRIP_SCORE_PACK_IMPACT THEN 
		v_formulation := 100; 
	ELSE   
        SELECT (score_whats_in_prod + score_water_in_prod + score_energy_in_prod + score_pack_impact + score_pack_opt + score_recycled_pack) / model_pkg.MAX_SCORE_FORMULATION * 100 
		  INTO v_formulation 
		  FROM gt_scores 
		 WHERE product_id = in_product_id 
		   AND revision_id = v_revision_id;
    END IF;
	
	-- if the score for 
	--		pack impact >= 8 OR
	-- MAX the score for this score group	
    IF v_score_supp_management >= model_pkg.TRIP_SCORE_SUPP_MAN THEN 
		v_supply := 100; 
	ELSE   
        SELECT (score_supp_management + score_trans_raw_mat + score_trans_to_boots + score_trans_packaging + score_trans_opt + score_energy_dist) / model_pkg.MAX_SCORE_SUPPLY * 100 
		  INTO v_supply 
		  FROM gt_scores 
		 WHERE product_id = in_product_id 
		   AND revision_id = v_revision_id;
    END IF;
	
    SELECT (score_water_use + score_energy_use + score_ancillary_req) / model_pkg.MAX_SCORE_USE_AT_HOME * 100 
	  INTO v_use_at_home 
	  FROM gt_scores 
	 WHERE product_id = in_product_id 
	   AND revision_id = v_revision_id;
	   
    SELECT (score_prod_waste + score_recyclable_pack + score_recov_pack) / model_pkg.MAX_SCORE_END_OF_LINE * 100 
	  INTO v_end_of_line 
	  FROM gt_scores 
	 WHERE product_id = in_product_id 
	   AND revision_id = v_revision_id;
    
    v_graph_area := ((v_sustainable * v_formulation) + (v_formulation * v_supply) + (v_supply * v_use_at_home) + (v_use_at_home * v_end_of_line) + (v_end_of_line * v_sustainable)) * 0.475528258; -- sin(72)
    
	RETURN v_graph_area;
END;

END report_gt_pkg;
/
