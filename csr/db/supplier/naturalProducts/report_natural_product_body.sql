create or replace package body supplier.report_natural_product_pkg
IS

PROCEDURE RunNPDataDumpReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_items						csr.T_SPLIT_NUMERIC_TABLE;
	v_app_sid 					security_pkg.T_SID_ID;
	v_companies_sid 			security_pkg.T_SID_ID;
BEGIN

	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;
	
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	-- Check write permission on companies folder in security
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);
	
	
	OPEN out_cur FOR
		SELECT p.* FROM (
                    SELECT  p.product_id, 
                            product_code, description, product_category, product_status_description product_status, supplier_company, note, product_status_id, declaration_made_by_name, psv.period_id, NVL(psv.volume, 0) sales_volume,
                            part_count, part_description, part_code, natural_claim, num_component_parts, component_description, component_code, component_natural_claim, kingdom, common_name, genus, species, country, region, collection_desc,
                            env_process_safeguard_desc,  env_harvest_safeguard_desc, production_processes , num_evidence_items 
                    FROM
                    (
                        SELECT p.product_id, product_code, description, product_category, NVL(pp.part_count, 0) part_count, 
								product_status_description, declaration_made_by_name, product_status_id, note, supplier_company
						FROM 
                        (
                                SELECT p.product_id, p.product_code, p.description, product_status_description, MAX(DECODE (tag_group_name, 'merchant_type', tag, NULL)) product_category, 
								       cu.full_name declaration_made_by_name, product_status_id, p.supplier_company_sid, p.supplier_company
                                FROM csr.csr_user cu,  
                                (
                                    SELECT p.product_id, p.description, p.product_code, p.supplier_company_sid, c.name supplier_company,
                                        p.declaration_made_by_sid, t.tag, tg.name tag_group_name, gs.description product_status_description, p.product_status_id
                                      FROM 
                                        (
                                            -- want the status of the sust sourcing group - no such thing as product status anymore
                                            SELECT p.*, group_status_id product_status_id, declaration_made_by_sid
                                              FROM product p, product_questionnaire_group pqg, questionnaire_group qg
                                             WHERE p.product_id = pqg.product_id
                                               AND pqg.group_id = qg.group_id 
                                               AND LOWER(qg.name) = 'sustainable sourcing'
                                        ) p,                                    
                                      product_tag pt, tag t, tag_group_member tgm, tag_group tg, group_status gs, company c
                                       WHERE p.active = 1
                                         AND p.product_id = pt.product_id
										 AND p.supplier_company_sid = c.company_sid
                                         AND p.product_status_id = gs.group_status_id
                                         AND pt.tag_id = t.tag_id
                                         AND tgm.tag_id = t.tag_id
                                         AND tgm.tag_group_sid = tg.tag_group_sid 
                                         AND p.app_sid = v_app_sid
                                )p
                                WHERE cu.csr_user_sid(+) = p.declaration_made_by_sid
                                GROUP BY product_id, description, product_code, product_status_description, p.supplier_company_sid, supplier_company, cu.full_name, product_status_id
                        ) p, np_product_answers npa,
                        (
                            SELECT product_id, COUNT(*) part_count FROM product_part pp WHERE pp.part_type_id = 3 GROUP BY product_id
                        ) pp  
                        WHERE p.product_id = pp.product_id(+)
                          AND p.product_id = npa.product_id(+)
                    ) p, 
                    (
                        SELECT period_id, volume, product_id FROM product_sales_volume psv WHERE period_id = 1
                    ) psv,
                    (
                        SELECT 
                            npd.product_id,
                            part_description, 
                            part_code,
                            natural_claim, 
                            num_component_parts,
                            component_description,
                            component_code,
							component_natural_claim,
                            kingdom, 
                            common_name, 
                            genus, 
							species,
                            country, 
                            region, 
                            collection_desc,
                            env_process_safeguard_desc,
                            env_harvest_safeguard_desc,
                            production_processes ,
                            num_evidence_items 
                        FROM 
                        (        
                            SELECT pp.product_part_id, pp.product_id, description part_description, part_code, decode(natural_claim, 1, 'Yes', 'No') natural_claim, count(pp2.product_part_id) num_component_parts 
                              FROM product_part pp, np_part_description npd, product_part pp2
                             WHERE pp.product_part_id = npd.product_part_id
                               AND pp.product_part_id = pp2.parent_id(+)
                            GROUP BY pp.product_part_id, pp.product_id, description, part_code, natural_claim
                         ) npd,
                         (
                         SELECT pp.product_part_id, pp.parent_id, common_name, npcd.genus, npcd.species, npcd.description component_description, component_code, decode(natural_claim, 1, 'Yes', 'No') component_natural_claim, c.country, region, 
                                k.description kingdom, TO_CHAR(collection_desc) collection_desc, TO_CHAR(env_process_safeguard_desc) env_process_safeguard_desc, TO_CHAR(env_harvest_safeguard_desc) env_harvest_safeguard_desc, 
                                count(pp2.product_part_id) num_evidence_items , g.production_processes 
                           FROM product_part pp, np_component_description npcd, country c, np_kingdom k, product_part pp2,
                           (                      
								SELECT g.np_production_process_group_id, csr.stragg(pp.description) production_processes 
								  FROM np_production_process_group g, np_pp_group_member gm,  np_production_process pp
								 WHERE g.np_production_process_group_id = gm.np_production_process_group_id
								   AND gm.np_production_process_id = pp.np_production_process_id
								 GROUP BY  g.np_production_process_group_id
							) g
                          WHERE pp.product_part_id = npcd.product_part_id
                            AND npcd.country_of_origin = c.country_code
                            AND npcd.np_kingdom_id = k.np_kingdom_id
                            AND pp.product_part_id = pp2.parent_id(+)
                            AND npcd.np_production_process_group_id = g.np_production_process_group_id(+)
                          GROUP BY pp.product_part_id, pp.parent_id, common_name, npcd.genus, npcd.species, npcd.description, component_code, natural_claim, c.country, region, 
                                k.description, TO_CHAR(collection_desc), TO_CHAR(env_process_safeguard_desc), TO_CHAR(env_harvest_safeguard_desc), g.production_processes 
                         ) npcd
                         WHERE npd.product_part_id = npcd.parent_id                      
                    ) npp
                    WHERE p.product_id = psv.product_id(+)
                    AND p.product_id = npp.product_id(+)
		) p, tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
        AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'naturalproduct')
		AND ((p.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- in_sale_type_tag_id  
		ORDER BY LOWER(product_code), LOWER(part_description), LOWER(part_code), (component_description), LOWER(component_code);

END;

END report_natural_product_pkg;
/