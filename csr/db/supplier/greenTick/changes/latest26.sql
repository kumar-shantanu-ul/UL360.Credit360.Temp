-- Please update version.sql too -- this keeps clean builds in sync
define version=26
@update_header

CREATE OR REPLACE VIEW GT_PROFILE_REPORT AS 
SELECT root.*, 
    pack_weight.retail_packaging_weight,
    DECODE(root.weight_inc_pkg, 1, root.prod_weight, 0, root.prod_weight + pack_weight.retail_packaging_weight) prod_total_weight, 
    pack_material.pack_weights,
    pack_material.pack_contains_biopoly,
    pack_material.shape_descriptions,
    pack_material.material_descriptions,
    pack_material.material_recycled_pcts,
    -- Countries sold in, null implies the UK
    DECODE(sold_in.country_names, NULL, 'United Kingdom', sold_in.country_names) sold_in_countries 
FROM  
(
    SELECT 
    p.product_id  product_id,
    p.description  product_name,
    p.product_code  product_code, prf.*
    FROM product p,
    (SELECT
        p.product_id  product_id2,
        p.description  product_name2,
        p.product_code  product_code2,
        pr.revision_id revision_id,
    --
        merc_tag.explanation merchant_type,
        gtpa.range_description gt_product_range,
        gtpt.description gt_product_type,        
    --
        fa.ingredient_count  number_ingredients,
        (SELECT DECODE(COUNT(*), 0, 'No', 'Yes') 
           FROM gt_fa_anc_mat 
          WHERE product_id = p.product_id
          AND gt_ancillary_material_id <> 1) 
              am_required,
    --    
        gtp.gt_low_anc_list  low_impact_am_used,
        gtp.gt_med_anc_list  medium_impact_am_used,
        gtp.gt_high_anc_list  high_impact_am_used,
    --    
        CASE gts.score_water_in_prod 
            WHEN 1 THEN 'No water requirement' 
            WHEN 2 THEN 'Low water requirement'
            WHEN 3 THEN 'Moderate water requirement'
            WHEN 4 THEN 'Significant water requirement'
            WHEN 5 THEN 'High water requirement'
            ELSE 'No assessment made' 
                END water_content,
    --      
        CASE gts.score_water_use 
            WHEN 1 THEN 'No water requirement' 
            WHEN 2 THEN 'Low water requirement'
            WHEN 3 THEN 'Moderate water requirement'
            WHEN 4 THEN 'Significant water requirement'
            WHEN 5 THEN 'High water requirement'
            ELSE 'No assessment made' 
                END water_in_use,
    --    
        CASE gts.score_prod_waste
             WHEN 2 THEN 'Little or no potential product waste'
             WHEN 3 THEN 'Some inaccessable product'
             WHEN 4 THEN 'Moderate inaccessable product'
             WHEN 5 THEN 'Significant Inaccessable Produc'
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
        -- The sum of the naturally derived 
        -- percentages that make up the formulation
        (fa.bp_crops_pct + 
         fa.bp_fish_pct +
         fa.bp_palm_pct +
         fa.bp_wild_pct +
         fa.bp_threatened_pct)
            renewale_natural_derived_pct,
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
        gtp.biopolymer_list  biopolimer_components,
        gtp.recyclable_pack_pct  recyclable_pct,
        gtp.recoverable_pack_pct  recoverable_pct,
        gtp.recycled_pack_cont_msg  pkg_recycled_content,
        DECODE (pka.pack_meet_req, NULL, NULL, 0, 'DOES NOT meets Boots transit packaging requirements', 'Meets Boots transit packaging requirements')  boots_transit_pkg_requirements,
        DECODE (pka.pack_shelf_ready, NULL, NULL, 0, 'No shelf ready packaging', 'Contains shelf ready packaging')  shelf_ready_pkg,
        DECODE (pka.pack_consum_rcyld, NULL, NULL, 0, 'DOES NOT contain recycled material', 'DOES contain recycled material ' || NVL2(pka.pack_consum_pct, '- ' || pka.pack_consum_pct || '% ', NULL)  || pka.pack_consum_mat)  tm_recycled_content,
        tra.prod_in_cont_pct  rmdt_product_within_pct,
        tra.prod_btwn_cont_pct    rmdt_product_between_pct,
        tra.prod_cont_un_pct  rmdt_product_unknown_pct,
        tra.pack_in_cont_pct  rmdt_pkg_within_pct,
        tra.pack_btwn_cont_pct  rmdt_pkg_between_pct,
        tra.pack_cont_un_pct  rmdt_pkg_unknown_pct,
    --
        pka.vol_package packaging_volume,
        gtpa.product_volume,
        gtpa.prod_weight,
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
        -- We don't know what to do with this tet, need to ask Andrew
        ' '  fair_trade_status,
        gtpa.community_trade_pct, 
        gtpa.fairtrade_pct,
        gtpa.other_fair_pct,
        gtpa.not_fair_pct,
    --    
        -- Notes, TODO...
        'TODO'  rationalising_ingredients_note,
        'TODO'  redicing_need_for_am_note,
        'TODO'  green_chem_note,
        'TODO'  biodiversity_protection_note,
        'TODO'  pkg_waste_reeduction_note,
        'TODO'  refil_reuse_note,
        'TODO'  novel_use_materials_note,
        'TODO'  recycled_above_threshold_note,
        'TODO'  reduction_transit_mat_note,
        'TODO'  supplier_commitment_note,
        'TODO'  boots_contribution_note
    --    
    FROM product p, 
         product_revision pr,
         gt_product_rev gtprv,
         gt_product_type gtpt, 
         gt_formulation_answers fa,
         gt_profile gtp,
         gt_scores gts,
         gt_packaging_answers pka,
         gt_transport_answers tra,
         gt_supplier_answers sua,
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
      AND fa.product_id(+) = pr.product_id AND fa.revision_id(+)=pr.revision_id
      AND gtp.product_id(+) = pr.product_id  AND gtp.revision_id(+)=pr.revision_id
      AND gts.product_id(+) = pr.product_id  AND gts.revision_id(+)=pr.revision_id
      AND pka.product_id(+) = pr.product_id  AND pka.revision_id(+)=pr.revision_id
      AND tra.product_id(+) = pr.product_id  AND tra.revision_id(+)=pr.revision_id
      AND sua.product_id(+) = pr.product_id  AND sua.revision_id(+)=pr.revision_id
      AND gtpa.product_id(+) = pr.product_id  AND gtpa.revision_id(+)=pr.revision_id
      -- For product category (single select)
      AND merc_tg.name = 'merchant_type'
      AND merc_tgm.tag_group_sid = merc_tg.tag_group_sid
      AND merc_tag.tag_id = merc_tgm.tag_id
      AND merc_tag.tag_id = merc_pt.tag_id
      AND merc_pt.product_id = p.product_id) prf
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
       csr.STRAGG(pki.weight_grams) pack_weights,
       csr.STRAGG(pki.contains_biopolymer) pack_contains_biopoly,
       csr.STRAGG(pkst.description) shape_descriptions,
       csr.STRAGG(pkmt.description) material_descriptions,
       csr.STRAGG(pkmt.recycled_pct_theshold) material_recycled_pcts
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
;
	
@update_tail