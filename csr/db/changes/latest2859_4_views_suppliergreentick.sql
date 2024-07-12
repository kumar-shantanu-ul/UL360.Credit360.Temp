-- just a shortcut to get product with current product type 
-- Note - this only gets you current revision
CREATE OR REPLACE VIEW SUPPLIER.GT_PRODUCT AS 
SELECT p.*, gtp.gt_product_type_id, gtp.gt_product_type_group_id, 
       gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, hrs_used_per_month, mains_powered
  FROM product p, product_tag pt, gt_tag_product_type gtpt, gt_product_type gtp
 WHERE p.product_id = pt.product_id
   AND pt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id;
   
-- shortcut way of getting the link products with the maximum revision number - only want to pull these back
CREATE OR REPLACE VIEW SUPPLIER.GT_LINK_PRODUCT_MAX_REV AS
	SELECT product_id, link_product_id, revision_id, "COUNT"
	  FROM gt_link_product glp
	 WHERE revision_id = (
		SELECT NVL(MAX(revision_id), -1) FROM product_revision WHERE product_id = glp.product_id
	 );

CREATE OR REPLACE VIEW SUPPLIER.gt_product_rev
(product_id, revision_id, product_code, description, supplier_company_sid, 
 active, deleted, app_sid, gt_product_type_id, gt_product_type_group_id, 
 gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, 
 unit, hrs_used_per_month, mains_powered, gt_product_info_used, gt_packaging_used, gt_formulation_used, gt_transport_used, 
 gt_supplier_used, gt_product_design_used, gt_food_used, has_ingredients, has_packaging)
AS 
SELECT  p.product_id, (SELECT MAX(revision_id) FROM product_revision WHERE product_id = p.product_id) revision_id, 
        p.product_code,p.description,p.supplier_company_sid,p.active,p.deleted, p.app_sid, gtp.gt_product_type_id, gtp.gt_product_type_group_id,
        gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, hrs_used_per_month, mains_powered,
        gt_product_info_used, gt_packaging_used, gt_formulation_used, gt_transport_used, gt_supplier_used, gt_product_design_used, gt_food_used, (nvl(gt_product_design_used, 0)+nvl(gt_formulation_used,0)+nvl(gt_food_used,0)) has_ingredients, gt_packaging_used has_packaging
  FROM product p, product_tag pt, gt_tag_product_type gtpt, gt_product_type gtp, (
    SELECT  product_id, 
        MIN(DECODE(questionnaire_id, 8,   mapped, NULL)) gt_product_info_used,  
        MIN(DECODE(questionnaire_id, 9,   mapped, NULL)) gt_packaging_used,
        MIN(DECODE(questionnaire_id, 10,  mapped, NULL)) gt_formulation_used, 
        MIN(DECODE(questionnaire_id, 11,  mapped, NULL)) gt_transport_used, 
        MIN(DECODE(questionnaire_id, 12,  mapped, NULL)) gt_supplier_used, 
        MIN(DECODE(questionnaire_id, 13,  mapped, NULL)) gt_product_design_used,
        MIN(DECODE(questionnaire_id, 14,  mapped, NULL)) gt_food_used
      FROM product_tag pt, questionnaire_tag qt 
     WHERE pt.TAG_ID = qt.TAG_ID
     GROUP BY product_id
  ) pq
 WHERE p.product_id = pt.product_id
   AND pt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id
   AND p.product_id = pq.product_id
   UNION
SELECT p.product_id, pr.revision_id, p.product_code,p.description,p.supplier_company_sid,p.active,p.deleted, p.app_sid, gtp.gt_product_type_id, gtp.gt_product_type_group_id,
       gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, hrs_used_per_month, mains_powered,
       gt_product_info_used, gt_packaging_used, gt_formulation_used, gt_transport_used, gt_supplier_used, gt_product_design_used, gt_food_used, (nvl(gt_product_design_used, 0)+nvl(gt_formulation_used,0)+nvl(gt_food_used,0)) has_ingredients, gt_packaging_used has_packaging
  FROM product p, product_revision pr, product_revision_tag prt, gt_tag_product_type gtpt, gt_product_type gtp, (
    SELECT  product_id, revision_id,
            MIN(DECODE(questionnaire_id, 8,   mapped, NULL)) gt_product_info_used, 
            MIN(DECODE(questionnaire_id, 9,   mapped, NULL)) gt_packaging_used,
            MIN(DECODE(questionnaire_id, 10,  mapped, NULL)) gt_formulation_used, 
            MIN(DECODE(questionnaire_id, 11,  mapped, NULL)) gt_transport_used,
            MIN(DECODE(questionnaire_id, 12,  mapped, NULL)) gt_supplier_used, 
            MIN(DECODE(questionnaire_id, 13,  mapped, NULL)) gt_product_design_used,
            MIN(DECODE(questionnaire_id, 14,  mapped, NULL)) gt_food_used
      FROM product_revision_tag pt, questionnaire_tag qt  
     WHERE pt.TAG_ID = qt.TAG_ID
       AND revision_id < (SELECT MAX(revision_id) FROM product_revision WHERE product_id = pt.product_id)
     GROUP BY product_id, revision_id  
  ) pq
 WHERE p.product_id = pr.product_id
   AND pr.product_id = prt.product_id
   AND pr.revision_id = prt.revision_id
   AND prt.tag_id = gtpt.tag_id
   AND pr.product_id = pq.product_id
   AND pr.revision_id = pq.revision_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id
;
   

CREATE OR REPLACE VIEW SUPPLIER.GT_PROFILE_REPORT AS 
SELECT root.*, 
    pack_weight.retail_packaging_weight,
    DECODE(root.weight_inc_pkg, 1, root.prod_weight, 0, root.prod_weight + pack_weight.retail_packaging_weight) prod_total_weight,
    pack_material.pack_material_summary,
    trans_material.trans_pack_material_summary,
    -- Countries sold in, null implies the UK
    DECODE(sold_in.country_names, NULL, 'United Kingdom', sold_in.country_names) sold_in_countries
FROM
(
    SELECT
    p.product_id  product_id,
    p.description  product_name,
    p.product_code  product_code, prf.*, 
    DECODE(pack_risk_code, 'NS', 'Not set', 'LR', 'Low risk', 'HRNJ', 'High risk - not justified', 'High risk - justified') pack_risk_desc,
    DECODE(pack_risk_code, 'NS', 'black', 'LR', 'green', 'HRNJ', 'red', 'orange') pack_risk_colour,
    DECODE(NVL(LENGTH(just_report_explanation), 0), 0, 0, 1) just_rep_exp_present
    FROM product p,
    (SELECT
        p.product_id  product_id2,
        p.description  product_name2,
        p.product_code  product_code2,
        pr.revision_id revision_id, pr.description revision_description,
    --
        merc_tag.explanation merchant_type,
        gtpa.range_description gt_product_range,
        gtpt.description gt_product_type,
        DECODE(gtpt.unit, 'ml', product_volume || 'ml', 'g', prod_weight || 'g' || DECODE(weight_inc_pkg, 1, ' inc. packaging', 0, ' exc. packaging')) prod_weight_desc,
    --
        gtp.gt_low_anc_list  low_impact_am_used,
        gtp.gt_med_anc_list  medium_impact_am_used,
        gtp.gt_high_anc_list  high_impact_am_used,
    --
        CASE
            WHEN gts.score_water_in_prod<0 THEN 'No assessment made'
            WHEN gts.score_water_in_prod<=1 THEN 'No water requirement'
            WHEN gts.score_water_in_prod<=2 THEN 'Low water requirement'
            WHEN gts.score_water_in_prod<=3 THEN 'Moderate water requirement'
            WHEN gts.score_water_in_prod<5 THEN 'Significant water requirement'
            WHEN gts.score_water_in_prod>=5 THEN 'High water requirement'
            ELSE 'No assessment made'
                END water_content,
    --
        CASE
            WHEN gts.score_water_use<0 THEN 'No assessment made'
            WHEN gts.score_water_use<=1 THEN 'No water requirement'
            WHEN gts.score_water_use<=2 THEN 'Low water requirement'
            WHEN gts.score_water_use<=3 THEN 'Moderate water requirement'
            WHEN gts.score_water_use<5 THEN 'Significant water requirement'
            WHEN gts.score_water_use>=5 THEN 'High water requirement'
            ELSE 'No assessment made'
                END water_in_use,
    --
        CASE
             WHEN gts.score_prod_waste<0 THEN 'No assessment made'
             WHEN gts.score_prod_waste<=2 THEN 'Little or no potential product waste'
             WHEN gts.score_prod_waste<=3 THEN 'Some inaccessible product'
             WHEN gts.score_prod_waste<5 THEN 'Moderate inaccessible product'
             WHEN gts.score_prod_waste>=5 THEN 'Significant inaccessible product'
             ELSE 'No assessment made'
                 END available_product_waste,
    --
        -- Note:
            -- Changed the second case from <= 3.9 to <= 4 otherwise there's a gap
        CASE
            WHEN gts.score_energy_in_prod <= 2 THEN 'Low energy requirement'
            WHEN gts.score_energy_in_prod < 4 THEN 'Medium energy requirement'
            WHEN gts.score_energy_in_prod >= 4 THEN 'High energy requirement'
            ELSE 'No assessment made'
                END energy_in_production,
    --
        CASE
            WHEN gts.score_energy_use <= 2 THEN 'Low energy requirement'
            WHEN gts.score_energy_use < 4 THEN 'Medium energy requirement'
            WHEN gts.score_energy_use >= 4 THEN 'High energy requirement'
                END energy_in_use,
    --
        CASE
            WHEN gts.score_chemicals = 1 THEN 'Low Environmental Risk'
            WHEN gts.score_chemicals = 4 THEN 'Moderate Environmental Risk'
            WHEN gts.score_chemicals >= 4 THEN 'High Environmental Risk'
            ELSE 'No Assessment made'
                END envio_risk_level,
    --
        gtp.ratio_prod_pck_wght_pct  pct_pkg_to_product,
        DECODE (pka.refill_pack, NULL, NULL, 0, 'No', 'Yes')  refillable_reusable,
        DECODE (fa.concentrate, NULL, NULL, 0, 'No', 'Yes')  concentrates,
        gtp.renewable_pack_pct  materials_from_renewable_pct,
        gtp.biopolymer_used  biopolimers_used,
        --gtp.biopolymer_list  biopolimer_components,
        gtp.recyclable_pack_pct  recyclable_pct,
        gtp.recoverable_pack_pct  recoverable_pct,
        gtp.recycled_pack_cont_msg  pkg_recycled_content,
        gtp.score_pack_impact_raw  score_pack_impact_raw,
        --get the individual environmental impact scores of materials and packaging
        gtp.pack_ei,
        gtp.materials_ei,
        gtp.trans_pack_ei,
        gtp.sum_trans_weight total_trans_pack_weight,
        gtp.score_water_raw_mat,
        gtp.score_water_mnfct,
        gtp.score_water_wsr,
        gtp.score_water_contained,
        DECODE (gtp.recycled_pct, NULL, NULL, 0, 'DOES NOT contain recycled material', 'Contains ' || gtp.recycled_pct || '% recycled material by mass') tm_recycled_content,
        DECODE (pka.pack_meet_req, NULL, NULL, 0, 'DOES NOT meets Boots transit packaging requirements', 'Meets Boots transit packaging requirements')  boots_transit_pkg_requirements,
        DECODE (pka.pack_shelf_ready, NULL, NULL, 0, 'No shelf ready packaging', 'Contains shelf ready packaging')  shelf_ready_pkg,
        pka.num_packs_per_outer,
        tra.prod_in_cont_pct  rmdt_product_within_pct,
        tra.prod_btwn_cont_pct    rmdt_product_between_pct,
        tra.prod_cont_un_pct  rmdt_product_unknown_pct,
        tra.pack_in_cont_pct  rmdt_pkg_within_pct,
        tra.pack_btwn_cont_pct  rmdt_pkg_between_pct,
        tra.pack_cont_un_pct  rmdt_pkg_unknown_pct,
        --
        -- essential reqs
        CASE pack_style_type
           WHEN 1 THEN 
               DECODE(pack_risk, 0, 'NS', 1, 'LR', 2, DECODE(dbl_walled_jar_just, 255, 'HRJ', DECODE(NVL(LENGTH(just_report_explanation),0), 0, 'HRNJ', 'HRJ')))
           WHEN 2 THEN 
               DECODE(pack_risk, 0, 'NS', 1, 'LR', 2, DECODE(contain_tablets_just, 1023, 'HRJ', DECODE(NVL(LENGTH(just_report_explanation),0), 0, 'HRNJ', 'HRJ')))
           WHEN 3 THEN 
               DECODE(pack_risk, 0, 'NS', 1, 'LR', 2, DECODE(tablets_in_blister_tray, 255, 'HRJ', DECODE(NVL(LENGTH(just_report_explanation),0), 0, 'HRNJ', 'HRJ')))
           WHEN 4 THEN 
                DECODE(pack_risk, 0, 'NS', 1, 'LR', 2, DECODE(carton_gift_box_just + DECODE(carton_gift_box_vacuum_form, 1, 1, 2, 1, 0) + DECODE(carton_gift_box_clear_win, 1, 1, 2, 1, 0) + DECODE(carton_gift_box_sleeve, 1, 1, 2, 1, 0), 258, 'HRJ', DECODE(NVL(LENGTH(just_report_explanation),0), 0, 'HRNJ', 'HRJ')))
           WHEN 5 THEN 
               DECODE(pack_risk, 0, 'NS', 1, 'LR', 2, DECODE(NVL(LENGTH(other_prod_protection_just||other_pack_manu_proc_just||other_pack_fill_proc_just||other_logistics_just||other_prod_present_market_just||other_consumer_accept_just||other_prod_info_just||other_prod_safety_just||other_prod_legislation_just||other_issues_just),0), 0, 'HRNJ', 'HRJ'))
           ELSE 
               DECODE(pack_risk, 0, 'NS', 1, 'LR', 2, 'HRNJ')
        END pack_risk_code,
        CASE pack_style_type
           WHEN 5 THEN 
               NVL2(other_prod_protection_just, other_prod_protection_just || ' / ', null) || 
               NVL2(other_pack_manu_proc_just, other_pack_manu_proc_just || ' / ', null) || 
               NVL2(other_pack_fill_proc_just, other_pack_fill_proc_just || ' / ', null) || 
               NVL2(other_logistics_just, other_logistics_just || ' / ', null) || 
               NVL2(other_prod_present_market_just, other_prod_present_market_just || ' / ', null) || 
               NVL2(other_consumer_accept_just, other_consumer_accept_just || ' / ', null) || 
               NVL2(other_prod_info_just, other_prod_info_just || ' / ', null) || 
               NVL2(other_prod_safety_just, other_prod_safety_just || ' / ', null) || 
               NVL2(other_prod_legislation_just, other_prod_legislation_just || ' / ', null) || 
               NVL2(other_issues_just, other_issues_just || ' / ', null)
           ELSE 
               just_report_explanation
        END just_report_explanation,
        pack_risk ess_req_pack_risk, 
    --
        pka.vol_package packaging_volume,
        gtpa.product_volume,
        gtpa.product_volume_declared,
        gtpa.prod_weight,
        gtpa.prod_weight_declared,
        gtpa.weight_inc_pkg,
        DECODE(gtpa.product_volume, 0, NULL, ROUND((pka.vol_package * 100) / gtpa.product_volume, 3)) ratio_pack_product,
    --
        pka.vol_tran_pack total_prod_vol_per_outer,
        pka.vol_prod_tran_pack transit_pack_volume,
        DECODE(pka.vol_prod_tran_pack, 0, NULL, ROUND((pka.vol_tran_pack * 100) / pka.vol_prod_tran_pack, 3)) transit_pack_vol_ratio,
    --
        (SELECT description
           FROM gt_sus_relation_type
          WHERE gt_sus_relation_type_id = sua.gt_sus_relation_type_id)
              management_status,
    --
        gtp.country_made_in_list  country_of_origin,
    --
        -- We don't know what to do with this yet, need to ask Andrew
        ' '  fair_trade_status,
        gtpa.community_trade_pct,
        gtpa.fairtrade_pct,
        gtpa.other_fair_pct,
        gtpa.not_fair_pct,
        DECODE(gtpa.reduce_energy_use_adv, NULL, 'Not set', 1, 'Yes', 0, 'No') reduce_energy_use_adv,
        DECODE(gtpa.reduce_water_use_adv, NULL, 'Not set', 1, 'Yes', 0, 'No') reduce_water_use_adv,
        DECODE(gtpa.reduce_waste_adv, NULL, 'Not set', 1, 'Yes', 0, 'No') reduce_waste_adv,
        DECODE(gtpa.on_pack_recycling_adv, NULL, 'Not set', 1, 'Yes', 0, 'No') on_pack_recycling_adv,
        fadqt.description fadq,
        pkadqt.description pkadq,
        tradqt.description tradq,
        suadqt.description suadq,
        gtpdadqt.description gtpdadq,
        gtpadqt.description gtpadq,
        gtfooddqt.description gtfooddq
    --
    FROM product p,
         product_revision pr,
         gt_product_rev gtprv,
         gt_product_type gtpt,
         gt_formulation_answers fa,
         gt_profile gtp,
         gt_scores gts,
         gt_pdesign_answers gtpda,
         gt_packaging_answers pka,
         gt_transport_answers tra,
         gt_supplier_answers sua,
         gt_food_answers gtfood,
         data_quality_type fadqt,
         data_quality_type pkadqt,
         data_quality_type tradqt,
         data_quality_type suadqt,
         data_quality_type gtpdadqt,
         data_quality_type gtpadqt,
         data_quality_type gtfooddqt,
         (SELECT gtpa.*, gtpr.description range_description
           FROM gt_product_answers gtpa, gt_product_range gtpr
          WHERE gtpr.gt_product_range_id = gtpa.gt_product_range_id) gtpa,
         tag_group merc_tg,
         tag_group_member merc_tgm,
         tag merc_tag,
         product_tag merc_pt
         --
    WHERE p.product_id = pr.product_id
      AND pr.product_id = gtprv.product_id
      AND pr.revision_id = gtprv.revision_id
      AND gtprv.gt_product_type_id = gtpt.gt_product_type_id
     -- AND fa.product_id(+) = pr.product_id AND fa.revision_id(+)=pr.revision_id
      AND gtp.product_id(+) = pr.product_id  AND gtp.revision_id(+)=pr.revision_id
      AND gts.product_id(+) = pr.product_id  AND gts.revision_id(+)=pr.revision_id
      AND pka.product_id(+) = pr.product_id  AND pka.revision_id(+)=pr.revision_id
      AND tra.product_id(+) = pr.product_id  AND tra.revision_id(+)=pr.revision_id
      AND fa.product_id(+) = pr.product_id  AND fa.revision_id(+)=pr.revision_id
      AND sua.product_id(+) = pr.product_id  AND sua.revision_id(+)=pr.revision_id
      AND gtpa.product_id(+) = pr.product_id  AND gtpa.revision_id(+)=pr.revision_id
      AND gtpda.product_id(+) = pr.product_id AND gtpda.revision_id(+)=pr.revision_id
      AND gtfood.product_id(+) = pr.product_id AND gtfood.revision_id(+)=pr.revision_id
      -- For product category (single select)
      AND merc_tg.name = 'merchant_type'
      AND merc_tgm.tag_group_sid = merc_tg.tag_group_sid
      AND merc_tag.tag_id = merc_tgm.tag_id
      AND merc_tag.tag_id = merc_pt.tag_id
      AND merc_pt.product_id = p.product_id
      -- data quality tables
      AND fadqt.data_quality_type_id (+)= fa.data_quality_type_id
      AND pkadqt.data_quality_type_id(+) = pka.data_quality_type_id
      AND tradqt.data_quality_type_id (+)= tra.data_quality_type_id
      AND suadqt.data_quality_type_id (+)= sua.data_quality_type_id
      AND gtpdadqt.data_quality_type_id (+)= gtpda.data_quality_type_id
      AND gtpadqt.data_quality_type_id (+)= gtpa.data_quality_type_id
      AND gtfooddqt.data_quality_type_id (+)= gtfood.data_quality_type_id
      ) prf
      WHERE p.product_id = prf.product_id2(+)
) root, (
    SELECT p.product_id, pr.revision_id revision_id,
        SUM(pki.weight_grams) retail_packaging_weight
      FROM product p,
           product_revision pr,
           gt_pack_item pki
     WHERE p.product_id = pr.product_id
       AND pki.product_id = pr.product_id
       AND pki.revision_id = pr.revision_id
     GROUP BY p.product_id, pr.revision_id
) pack_weight,  (
    SELECT p.product_id, pr.revision_id revision_id,
        csr.stragg(REPLACE(pkst.description, ',', '')||'###'||REPLACE(pkmt.description, ',', '')||'###'||pki.weight_grams||'g###('||pki.pct_recycled||'% recycled)'||'###'||DECODE(pki.contains_biopolymer, 0, 'does not contain', 'contains')||' bioploymers') pack_material_summary
      FROM product p,
           product_revision pr,
           gt_pack_item pki,
           gt_pack_shape_type pkst,
           gt_pack_material_type pkmt
     WHERE p.product_id = pr.product_id
       AND pki.product_id = pr.product_id
       AND pki.revision_id = pr.revision_id
       AND pkst.gt_pack_shape_type_id = pki.gt_pack_shape_type_id
       AND pkmt.gt_pack_material_type_id = pki.gt_pack_material_type_id
     GROUP BY p.product_id, pr.revision_id
) pack_material, (
    SELECT p.product_id, pr.revision_id revision_id,
        csr.stragg(REPLACE(pkmt.description, ',', '')||'###'||pki.weight_grams||'g###('||pki.pct_recycled||'% recycled)') trans_pack_material_summary
      FROM product p,
           product_revision pr,
           gt_trans_item pki,
           gt_trans_material_type pkmt
     WHERE p.product_id = pr.product_id
       AND pki.product_id = pr.product_id
       AND pki.revision_id = pr.revision_id
       AND pkmt.gt_trans_material_type_id = pki.gt_trans_material_type_id
     GROUP BY p.product_id, pr.revision_id
) trans_material, (
    SELECT p.product_id, pr.revision_id revision_id,
        csr.stragg(ct.country) country_names
      FROM product p,
           product_revision pr,
           gt_country_sold_in si,
           country ct
     WHERE p.product_id = pr.product_id
       AND si.product_id = pr.product_id
       AND si.revision_id = pr.revision_id
       AND ct.country_code = si.country_code
     GROUP BY p.product_id, pr.revision_id
) sold_in
WHERE root.product_id = pack_weight.product_id(+)
  AND root.revision_id = pack_weight.revision_id(+)
  AND root.product_id = sold_in.product_id(+)
  AND root.revision_id = sold_in.revision_id(+)
  AND root.product_id = pack_material.product_id(+)
  AND root.revision_id = pack_material.revision_id(+)
  AND root.product_id = trans_material.product_id(+)
  AND root.revision_id = trans_material.revision_id(+)
;

