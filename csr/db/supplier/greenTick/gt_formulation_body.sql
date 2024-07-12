create or replace package body supplier.gt_formulation_pkg
IS

PROCEDURE SetFormulationAnswers (
    in_act_id                                  IN  security_pkg.T_ACT_ID,
    in_product_id                              IN  all_product.product_id%TYPE,
    in_numberOfIngredients                     IN  gt_formulation_answers.ingredient_count%type,
    in_comparablePerformance                   IN  gt_formulation_answers.sf_ingredients%type,
    in_needForAdditionalMaterials              IN  gt_formulation_answers.sf_additional_materials%type,
    in_deliverConcentrate                      IN  gt_formulation_answers.concentrate%type,
    in_noHazChem                  			   IN  gt_formulation_answers.no_haz_chem%type,
    in_greenChemistry                          IN  gt_formulation_answers.sf_special_materials%type,
    in_ancillaryMaterials                      IN  gt_formulation_pkg.t_ancillary_materials,
    in_chemicalsPresent                        IN  gt_formulation_pkg.t_chemicals_present,
    in_waterPct		                           IN  gt_formulation_answers.water_pct%type,
    in_naturalCrops                            IN  gt_formulation_answers.bp_crops_pct%type,
    in_naturalFish                             IN  gt_formulation_answers.bp_fish_pct%type,
    in_naturalPalm                             IN  gt_formulation_answers.bp_palm_pct%type,
    in_naturalPalmProcessed                    IN  gt_formulation_answers.bp_palm_processed_pct%type,
    in_naturalWild                             IN  gt_formulation_answers.bp_wild_pct%type,
    in_naturalUnknown                          IN  gt_formulation_answers.bp_unknown_pct%type,
    in_naturalEndangered                       IN  gt_formulation_answers.bp_threatened_pct%type,
    in_naturalMineral                          IN  gt_formulation_answers.bp_mineral_pct%type,
    in_wsr	                                   IN  gt_formulation_pkg.t_wsr,
    in_palmOil                                 IN  gt_formulation_pkg.t_palm_oil,
    in_endangeredSpecies                       IN  gt_formulation_pkg.t_endangered_species,
    in_bioDiversitySteps                       IN  gt_formulation_answers.sf_biodiversity%type,
    in_accreditedPriority                      IN  gt_formulation_answers.bs_accredited_priority_pct%type,
    in_accreditedPrioritySource                IN  gt_formulation_answers.bs_accredited_priority_src%type,
    in_accreditedOther                         IN  gt_formulation_answers.bs_accredited_other_pct%type,
    in_accreditedOtherSource                   IN  gt_formulation_answers.bs_accredited_other_src%type,
    in_knownSource                             IN  gt_formulation_answers.bs_known_pct%type,
    in_unknownSource                           IN  gt_formulation_answers.bs_unknown_pct%type,
    in_noNatural                               IN  gt_formulation_answers.bs_no_natural_pct%type,
    in_formulationDocGroupId                   IN  gt_formulation_answers.bs_document_group%type,
	in_data_quality_type_id       			   IN gt_product_answers.data_quality_type_id%TYPE
)
AS
	v_max_revision_id					product_revision.revision_id%TYPE;

	v_old_chemical_list					VARCHAR(2048);
	v_old_ancillary_list				VARCHAR(2048);
	v_old_palm_list						VARCHAR(2048);
	v_old_endangered_list				VARCHAR(2048);
	v_old_wsr_list						VARCHAR(2048);
	v_new_chemical_list					VARCHAR(2048);
	v_new_ancillary_list				VARCHAR(2048);
	v_new_palm_list						VARCHAR(2048);
	v_new_endangered_list				VARCHAR(2048);
	v_new_wsr_list						VARCHAR(2048);	
BEGIN

    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	FOR r IN (
		SELECT 
			   pr.product_id, pr.revision_id, ingredient_count, 
			   concentrate, no_haz_chem, water_pct, bp_crops_pct, bp_fish_pct, 
			   bp_palm_pct, bp_wild_pct, bp_unknown_pct, 
			   bp_threatened_pct, bp_mineral_pct,
			   bs_accredited_priority_pct, bs_accredited_priority_src, bs_accredited_other_pct, 
			   bs_accredited_other_src, bs_known_pct, bs_unknown_pct, 
			   bs_no_natural_pct, bs_document_group, bp_palm_processed_pct
		FROM gt_formulation_answers fa, product_revision pr
            WHERE pr.product_id=fa.product_id (+)
            AND pr.REVISION_ID = fa.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
	) 
	LOOP
		-- actually only ever going to be single row as product id and revision id are PK
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WHATS_IN_PROD, null, 'Number of ingredients', r.ingredient_count, in_numberOfIngredients);

		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_PACK_IMPACT, null, 'Is the formulation a concentrate', r.concentrate, in_deliverConcentrate);
		
		score_log_pkg.LogYesNoValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'No hazardous chemicals from list present', r.no_haz_chem, in_noHazChem);
		
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Water %', r.water_pct, in_waterPct);

		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Grown on established mixed agricultural land %', r.bp_crops_pct, in_naturalCrops);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Intensively farmed materials %', r.bp_fish_pct, in_naturalFish);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Palm Oil and close derivatives %', r.bp_palm_pct, in_naturalPalm);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Processed materials derived from palm oil %', r.bp_palm_processed_pct, in_naturalPalmProcessed);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Wild Harvested %', r.bp_wild_pct, in_naturalWild);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Unknown Sources %', r.bp_unknown_pct, in_naturalUnknown);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Threatened or endangered species %', r.bp_threatened_pct, in_naturalEndangered);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SOURCE_BIOD, null, 'Mineral derived %', r.bp_mineral_pct, in_naturalMineral);

		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Accredited source (priority) %', r.bs_accredited_priority_pct, in_accreditedPriority);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Accredited source (other) %', r.bs_accredited_other_pct, in_accreditedOther);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Known source %', r.bs_known_pct, in_knownSource);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'Unknown source %', r.bs_unknown_pct, in_unknownSource);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ACCRED_BIOD, null, 'No natural ingredients  %', r.bs_no_natural_pct, in_noNatural);

	END LOOP;

    begin
        insert into gt_formulation_answers (
            product_id, revision_id, ingredient_count, concentrate, no_haz_chem,
            sf_ingredients, sf_additional_materials, sf_special_materials, water_pct,
            bp_crops_pct, bp_fish_pct, bp_palm_pct, bp_palm_processed_pct, bp_wild_pct,
            bp_unknown_pct, bp_threatened_pct, bp_mineral_pct,
            sf_biodiversity,
            bs_accredited_priority_pct, bs_accredited_priority_src,
            bs_accredited_other_pct, bs_accredited_other_src,
            bs_known_pct, bs_unknown_pct, bs_no_natural_pct,
            bs_document_group,
			data_quality_type_id
        ) values (
            in_product_id, v_max_revision_id, in_numberOfIngredients, in_deliverConcentrate, in_noHazChem,
            in_comparablePerformance, in_needForAdditionalMaterials, in_greenChemistry, in_waterPct,
            in_naturalCrops, in_naturalFish, in_naturalPalm, in_naturalPalmProcessed, in_naturalWild,
            in_naturalUnknown, in_naturalEndangered, in_naturalMineral,
            in_bioDiversitySteps,
            in_accreditedPriority, in_accreditedPrioritySource,
            in_accreditedOther, in_accreditedOtherSource,
            in_knownSource, in_unknownSource, in_noNatural,
            in_formulationDocGroupId, 
			in_data_quality_type_id
        );
    exception
        when dup_val_on_index then
            update gt_formulation_answers set
                 ingredient_count = in_numberOfIngredients,
                 concentrate = in_deliverConcentrate,
                 no_haz_chem = in_noHazChem,
                 sf_ingredients = in_comparablePerformance,
                 sf_additional_materials = in_needForAdditionalMaterials,
                 sf_special_materials = in_greenChemistry,
				 water_pct = in_waterPct,
                 bp_crops_pct = in_naturalCrops,
                 bp_fish_pct = in_naturalFish,
                 bp_palm_pct = in_naturalPalm,
                 bp_palm_processed_pct = in_naturalPalmProcessed,
                 bp_wild_pct = in_naturalWild,
                 bp_unknown_pct = in_naturalUnknown,
                 bp_threatened_pct = in_naturalEndangered,
                 bp_mineral_pct = in_naturalMineral,
                 sf_biodiversity = in_bioDiversitySteps,
                 bs_accredited_priority_pct = in_accreditedPriority,
                 bs_accredited_priority_src = in_accreditedPrioritySource,
                 bs_accredited_other_pct = in_accreditedOther,
                 bs_accredited_other_src = in_accreditedOtherSource,
                 bs_known_pct = in_knownSource,
                 bs_unknown_pct = in_unknownSource,
                 bs_no_natural_pct = in_noNatural,
                 bs_document_group = in_formulationDocGroupId,
				 data_quality_type_id = in_data_quality_type_id
             where product_id = in_product_id
             AND revision_id = v_max_revision_id;
    end;
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_chemical_list FROM (
            SELECT fac.description 
            	FROM (SELECT hc.description, fac.product_id, fac.revision_id FROM gt_fa_haz_chem fac, gt_hazzard_chemical hc WHERE hc.gt_hazzard_chemical_id = fac.gt_hazzard_chemical_id) fac, 
				product_revision pr
            WHERE pr.product_id=fac.PRODUCT_ID (+)
            AND pr.REVISION_ID = fac.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(fac.description)
	);

    delete from gt_fa_haz_chem where product_id = in_product_id AND revision_id = v_max_revision_id;
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_ancillary_list FROM (
            SELECT anc.description 
            	FROM (SELECT am.description, anc.product_id, anc.revision_id FROM gt_fa_anc_mat anc, gt_ancillary_material am WHERE am.gt_ancillary_material_id = anc.gt_ancillary_material_id) anc, 
				product_revision pr
            WHERE pr.product_id=anc.PRODUCT_ID (+)
            AND pr.REVISION_ID = anc.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(anc.description)
	);
    
    delete from gt_fa_anc_mat where product_id = in_product_id AND revision_id = v_max_revision_id;

	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_palm_list FROM (
            SELECT pm.description 
            	FROM (SELECT plm.description, pm.product_id, pm.revision_id FROM gt_fa_palm_ind pm, gt_palm_ingred plm WHERE plm.gt_palm_ingred_id = pm.gt_palm_ingred_id) pm, 
				product_revision pr
            WHERE pr.product_id=pm.PRODUCT_ID (+)
            AND pr.REVISION_ID = pm.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(pm.description)
	);
    
    delete from gt_fa_palm_ind where product_id = in_product_id AND revision_id = v_max_revision_id;
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_wsr_list FROM (
            SELECT wsr.description 
                FROM (SELECT wsr.description, fw.product_id, fw.revision_id FROM gt_fa_wsr fw, gt_water_stress_region wsr WHERE wsr.gt_water_stress_region_id = fw.gt_water_stress_region_id) wsr, 
                product_revision pr
            WHERE pr.product_id=wsr.PRODUCT_ID (+)
            AND pr.REVISION_ID = wsr.revision_id(+)
            AND pr.product_id = in_product_id
            AND pr.revision_id = v_max_revision_id
            ORDER BY LOWER(wsr.description)
	);
    
    delete from gt_fa_wsr where product_id = in_product_id AND revision_id = v_max_revision_id;
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_endangered_list FROM (
            SELECT en.description 
            	FROM (SELECT en.description, el.product_id, el.revision_id FROM gt_fa_endangered_sp el, gt_endangered_species en WHERE en.gt_endangered_species_id = el.gt_endangered_species_id) en, 
				product_revision pr
            WHERE pr.product_id=en.PRODUCT_ID (+)
            AND pr.REVISION_ID = en.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(en.description)
	);

    delete from gt_fa_endangered_sp where product_id = in_product_id AND revision_id = v_max_revision_id;

    if ((in_chemicalsPresent.count>0) AND (in_chemicalsPresent(1) is not null)) then
        for i in in_chemicalsPresent.first .. in_chemicalsPresent.last loop
            insert into gt_fa_haz_chem (gt_hazzard_chemical_id, product_id, revision_id) values (in_chemicalsPresent(i), in_product_id, v_max_revision_id);
        end loop;
    end if;

    if ((in_ancillaryMaterials.count>0) AND (in_ancillaryMaterials(1) is not null)) then
        for i in in_ancillaryMaterials.first .. in_ancillaryMaterials.last loop
            insert into gt_fa_anc_mat (gt_ancillary_material_id, product_id, revision_id) values (in_ancillaryMaterials(i), in_product_id, v_max_revision_id);
        end loop;
    end if;

    if ((in_palmOil.count>0) AND (in_palmOil(1) is not null)) then
        for i in in_palmOil.first .. in_palmOil.last loop
            insert into gt_fa_palm_ind (gt_palm_ingred_id, product_id, revision_id) values (in_palmOil(i), in_product_id, v_max_revision_id);
        end loop;
    end if;
	
    if ((in_wsr.count>0) AND (in_wsr(1) is not null)) then
        for i in in_wsr.first .. in_wsr.last loop
            insert into gt_fa_wsr (gt_water_stress_region_id, product_id, revision_id) values (in_wsr(i), in_product_id, v_max_revision_id);
        end loop;
    end if;

    if ((in_endangeredSpecies.count>0) AND (in_endangeredSpecies(1) is not null)) then
        for i in in_endangeredSpecies.first .. in_endangeredSpecies.last loop
            insert into gt_fa_endangered_sp (gt_endangered_species_id, product_id, revision_id) values (in_endangeredSpecies(i), in_product_id, v_max_revision_id);
        end loop;
    end if;
    
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_chemical_list FROM (
            SELECT fac.description 
            	FROM (SELECT hc.description, fac.product_id, fac.revision_id FROM gt_fa_haz_chem fac, gt_hazzard_chemical hc WHERE hc.GT_HAZZARD_CHEMICAL_ID = fac.GT_HAZZARD_CHEMICAL_ID) fac, 
				product_revision pr
            WHERE pr.product_id=fac.PRODUCT_ID (+)
            AND pr.REVISION_ID = fac.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(fac.description)
	);
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_ancillary_list FROM (
            SELECT anc.description 
            	FROM (SELECT am.description, anc.product_id, anc.revision_id FROM gt_fa_anc_mat anc, gt_ancillary_material am WHERE am.gt_ancillary_material_id = anc.gt_ancillary_material_id) anc, 
				product_revision pr
            WHERE pr.product_id=anc.PRODUCT_ID (+)
            AND pr.REVISION_ID = anc.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(anc.description)
	);
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_palm_list FROM (
            SELECT pm.description 
            	FROM (SELECT plm.description, pm.product_id, pm.revision_id FROM gt_fa_palm_ind pm, gt_palm_ingred plm WHERE plm.gt_palm_ingred_id = pm.gt_palm_ingred_id) pm, 
				product_revision pr
            WHERE pr.product_id=pm.PRODUCT_ID (+)
            AND pr.REVISION_ID = pm.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(pm.description)
	);
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_wsr_list FROM (
            SELECT wsr.description 
                FROM (SELECT wsr.description, fw.product_id, fw.revision_id FROM gt_fa_wsr fw, gt_water_stress_region wsr WHERE wsr.gt_water_stress_region_id = fw.gt_water_stress_region_id) wsr, 
                product_revision pr
            WHERE pr.product_id=wsr.PRODUCT_ID (+)
            AND pr.REVISION_ID = wsr.revision_id(+)
            AND pr.product_id = in_product_id
            AND pr.revision_id = v_max_revision_id
            ORDER BY LOWER(wsr.description)
	);
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_endangered_list FROM (
            SELECT en.description 
            	FROM (SELECT en.description, el.product_id, el.revision_id FROM gt_fa_endangered_sp el, gt_endangered_species en WHERE en.gt_endangered_species_id = el.gt_endangered_species_id) en, 
				product_revision pr
            WHERE pr.product_id=en.PRODUCT_ID (+)
            AND pr.REVISION_ID = en.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(en.description)
	);
	
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_CHEMICALS, null, 'Hazzardous Chemicals', v_old_chemical_list, v_new_chemical_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_ANCILLARY_REQ, null, 'Ancillary Materials', v_old_ancillary_list, v_new_ancillary_list);
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Palm Oil Materials', v_old_palm_list, v_new_palm_list);
 	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Endangered Species', v_old_endangered_list, v_new_endangered_list);  

	 	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_WATER_IN_PROD, null, 'Water Stressed Regions', v_old_wsr_list, v_new_wsr_list);  

	
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);

END;


PROCEDURE GetFormulationAnswers(
    in_act_id                    IN  security_pkg.T_ACT_ID,
    in_product_id                IN  all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_gt_product_type_id		gt_product_type.gt_product_type_id%TYPE;
	v_gt_product_type			gt_product_type.description%TYPE;
BEGIN
    IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
    END IF;

	product_info_pkg.GetProductTypeFromTags(in_act_id, in_product_id, in_revision_id, v_gt_product_type_id, v_gt_product_type);

    OPEN out_cur FOR
        SELECT  NVL(fa.revision_id, 1) revision_id, p.description product_name, p.product_id, p.product_code, v_gt_product_type as product_type,
                fa.*, DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by 
				 FROM gt_formulation_answers fa, product p,  product_questionnaire pq
                WHERE p.product_id=in_product_id 
				  AND p.product_id = pq.product_id
				  AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_FORMULATION
				  AND p.product_id = fa.product_id (+)
                  AND ((fa.revision_id IS NULL) OR (fa.revision_id = in_revision_id));
END;

PROCEDURE GetFormulationChemicals(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- TODO: grouping
    OPEN out_cur FOR
        select
            hc.*,
            (
                select count(*)
                        from gt_fa_haz_chem a
                        where a.gt_hazzard_chemical_id = hc.gt_hazzard_chemical_id
                        and a.revision_id=in_revision_id
                        and a.product_id=in_product_id
            ) as included_boo
        from gt_hazzard_chemical hc
        order by hc.gt_hazzard_chemical_id;
END;


PROCEDURE GetFormulationPalmOils(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
as
begin
    OPEN out_cur FOR
        SELECT  p.gt_palm_ingred_id, p.description, p.palm_confirmed,
                case when product_id is null then 0 else 1 end as included_boo
          FROM  gt_palm_ingred p, gt_fa_palm_ind pi
          where p.gt_palm_ingred_id = pi.gt_palm_ingred_id (+)
          and (pi.product_id=in_product_id or pi.product_id is null)
          AND ((pi.revision_id IS NULL) OR (pi.revision_id = in_revision_id))
          order by p.gt_palm_ingred_id;
end;


PROCEDURE GetFormulationAncillary(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN    all_product.product_id%TYPE,
 	in_revision_id				 IN  product_revision.revision_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
as
begin
    OPEN out_cur FOR
        SELECT  m.gt_ancillary_material_id, m.description, m.pos,
                case when am.product_id is null then 0 else 1 end as included_boo
          FROM gt_ancillary_material m, (SELECT * FROM gt_fa_anc_mat am WHERE product_id = in_product_id AND revision_id = in_revision_id) am, gt_anc_mat_prod_class_map pcm
          WHERE m.gt_ancillary_material_id = am.gt_ancillary_material_id (+)
		  AND pcm.gt_ancillary_material_id = m.gt_ancillary_material_id
		  AND pcm.gt_product_class_id = 1
          ORDER BY m.pos asc;
end;

PROCEDURE IncrementRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
)
AS
BEGIN
	CopyAnswers(in_act_id, in_product_id, in_from_rev, in_product_id, in_from_rev+1);
END;

PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE
)
AS
	v_old_doc_group					document_group.document_group_id%TYPE;
	v_new_doc_group					document_group.document_group_id%TYPE;
BEGIN

	-- copy the sust doc group
	document_pkg.CreateDocumentGroup(in_act_id, v_new_doc_group);
	BEGIN
		SELECT bs_document_group INTO v_old_doc_group FROM gt_formulation_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_doc_group, v_new_doc_group);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;

	-- we always want to overwrite so lets just get rid of the row
	DELETE FROM gt_fa_anc_mat WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	DELETE FROM gt_fa_haz_chem WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	DELETE FROM gt_fa_palm_ind WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	DELETE FROM gt_fa_endangered_sp WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	DELETE FROM gt_fa_wsr WHERE product_id = in_to_product_id AND revision_id = in_to_rev;
	
	DELETE FROM gt_formulation_answers WHERE product_id = in_to_product_id AND revision_id = in_to_rev;

	INSERT INTO gt_formulation_answers (
	   product_id, 
	   revision_id, 
	   ingredient_count,
	   sf_ingredients, 
	   sf_additional_materials, 
	   sf_special_materials,
	   concentrate, 
	   no_haz_chem, 
	   water_pct, 
	   bp_crops_pct, 
	   bp_fish_pct,
	   bp_palm_pct, 
	   bp_palm_processed_pct, 
	   bp_wild_pct, 
	   bp_unknown_pct,
	   bp_threatened_pct, 
	   bp_mineral_pct, 
	   sf_biodiversity,
	   bs_accredited_priority_pct, 
	   bs_accredited_priority_src, 
	   bs_accredited_other_pct,
	   bs_accredited_other_src, 
	   bs_known_pct, 
	   bs_unknown_pct,
	   bs_no_natural_pct, 
	   bs_document_group,
	   data_quality_type_id)
	SELECT
	   in_to_product_id, in_to_rev, ingredient_count,
	   sf_ingredients, sf_additional_materials, sf_special_materials,
	   concentrate, no_haz_chem, water_pct, bp_crops_pct, bp_fish_pct,
	   bp_palm_pct, bp_palm_processed_pct, bp_wild_pct, bp_unknown_pct,
	   bp_threatened_pct, bp_mineral_pct, sf_biodiversity,
	   bs_accredited_priority_pct, bs_accredited_priority_src, bs_accredited_other_pct,
	   bs_accredited_other_src, bs_known_pct, bs_unknown_pct,
	   bs_no_natural_pct, v_new_doc_group, data_quality_type_id
	FROM gt_formulation_answers
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_fa_anc_mat (
   		gt_ancillary_material_id, product_id, revision_id)
	SELECT
		gt_ancillary_material_id, in_to_product_id, in_to_rev
	FROM gt_fa_anc_mat
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

	INSERT INTO gt_fa_haz_chem (
	  	gt_hazzard_chemical_id, product_id, revision_id)
	SELECT
		gt_hazzard_chemical_id, in_to_product_id, in_to_rev
	FROM gt_fa_haz_chem
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;
		
	INSERT INTO gt_fa_palm_ind (
	   gt_palm_ingred_id, product_id, revision_id)
	SELECT
		gt_palm_ingred_id, in_to_product_id, in_to_rev
	FROM gt_fa_palm_ind
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;
		
	INSERT INTO gt_fa_wsr (
	   gt_water_stress_region_id, product_id, revision_id)
	SELECT
		gt_water_stress_region_id, in_to_product_id, in_to_rev
	FROM gt_fa_wsr
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;
		
	INSERT INTO gt_fa_endangered_sp (
	   gt_endangered_species_id, product_id, revision_id)
	SELECT
		gt_endangered_species_id, in_to_product_id, in_to_rev
	FROM gt_fa_endangered_sp
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

END;

PROCEDURE GetFormulationEndangered(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
          SELECT    es.gt_endangered_species_id, es.description || DECODE(es.details, NULL, NULL, ' (' || es.details || ')') || ' - Risk: ' || es.risk_level as description, 
                    REPLACE(es.notes, '#', '') as notes , 
                    CASE WHEN pes.product_id IS NULL THEN 0 ELSE 1 END AS included_boo
           FROM gt_endangered_species es, gt_endangered_prod_class_map ecp, (SELECT * FROM gt_fa_endangered_sp WHERE product_id = in_product_id AND revision_id = in_revision_id) pes
          WHERE es.gt_endangered_species_id = ecp.gt_endangered_species_id
            AND es.gt_endangered_species_id = pes.gt_endangered_species_id (+)
            AND ecp.gt_product_class_id = model_pd_pkg.PROD_CLASS_FORMULATED
          ORDER BY LOWER(es.description);
END;

PROCEDURE GetFormulationWSR(
    in_act_id                    IN security_pkg.T_ACT_ID,
    in_product_id                IN all_product.product_id%TYPE,
    in_revision_id               IN  product_revision.revision_id%TYPE,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT  wsr.gt_water_stress_region_id, wsr.description, 
                CASE WHEN fw.product_id IS NULL THEN 0 ELSE 1 END AS selected
          FROM gt_water_stress_region wsr, (SELECT * FROM gt_fa_wsr fw WHERE product_id = in_product_id AND revision_id = in_revision_id) fw
          WHERE wsr.gt_water_stress_region_id =fw.gt_water_stress_region_id (+)
          ORDER BY pos asc;
END;

PROCEDURE GetAccessPackageType(
    in_act_id                    IN security_pkg.T_ACT_ID,
    out_cur                      OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT gt_access_pack_type_id, description
          FROM gt_access_pack_type
              ORDER BY pos ASC;
END;

END gt_formulation_pkg;
/
