create or replace package body supplier.report_wood_pkg
IS

PROCEDURE RunWRMEReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_recycled_wood_type_id		 	wrme_wood_type.wrme_wood_type_id%TYPE;
	v_description_part_type_id   	part_type.part_type_id%TYPE;
	v_wood_part_type_id			 	part_type.part_type_id%TYPE;	
	t_items							csr.T_SPLIT_NUMERIC_TABLE;
	v_wood_questionnaire			questionnaire.questionnaire_id%TYPE;
BEGIN

	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	-- Security check for admin??
	-- TO DO
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);
	
	-- get recycled wood_type
	SELECT wrme_wood_type_id INTO v_recycled_wood_type_id FROM wrme_wood_type WHERE lower(description) = 'recycled'; 
	
	-- get part types - 
	SELECT part_type_id INTO v_description_part_type_id FROM part_type WHERE lower(class_name) = 'part_description';
	SELECT part_type_id INTO v_wood_part_type_id FROM part_type WHERE lower(class_name) = 'part_wood';
	
	-- get wood questionaire_id
	SELECT questionnaire_id INTO v_wood_questionnaire FROM questionnaire WHERE lower(class_name) = 'wood';
	
	OPEN out_cur FOR
		SELECT product_code, prt.description, tag brand, common_name, genus, species, cert_scheme_name, c.country, prt.forest_source_cat_code, fsc.name forest_source_cat_name, ROUND((wrme_per_unit * psv.volume),20) wrme, ROUND((weight_per_unit * psv.volume),20) base_weight_tonnes FROM 
		(
		    SELECT product_id, product_status_id, product_code, product_part_id, description, forest_source_cat_code, 
		    common_name, species, genus, country_code, cert_scheme_id, cert_scheme_name, 
		    (weight_metric_ton * (pct/100) * factor_per_metric_ton) wrme_per_unit, (weight_metric_ton * (pct/100)) weight_per_unit
		    FROM
		    (	    
		        -- the 2 different re-cycled types 
		        -- pre consumer
		        SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, 
		        	wwt.factor_per_metric_ton, 'Re-cycled' common_name, 'Re-cycled' species, 'Re-cycled' genus, 'Ri' forest_source_cat_code, 
		        	cs.cert_scheme_id, cs.name cert_scheme_name, wpd.pre_recycled_country_code country_code, 
		           (CASE wpd.weight_unit_id
		             WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		             WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		           END) weight_metric_ton, wpd.pre_recycled_pct pct 
		            FROM 
		            (
		            	-- want the status of the sust sourcing group - no such thing as product status anymore
						SELECT p.*, group_status_id product_status_id
						FROM product p, product_questionnaire_group pqg, questionnaire_group qg
						WHERE p.product_id = pqg.product_id
						AND pqg.GROUP_ID = qg.group_id 
						AND lower(qg.name) = 'sustainable sourcing'
		            ) p
		            , product_part pp, wood_part_description wpd, cert_scheme cs, wrme_wood_type wwt
		            WHERE   p.product_id = pp.product_id
		            AND     pp.product_part_id = wpd.product_part_id 
		            AND     wpd.pre_cert_scheme_id = cs.cert_scheme_id
		            AND     wwt.wrme_wood_type_id = v_recycled_wood_type_id -- constant for recycled
		            AND     pp.part_type_id = v_description_part_type_id -- description type 
		           -- AND     p.product_code = '4814894'
		            AND     wpd.pre_recycled_pct > 0
		      UNION
		      	-- post consumer	
		        SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, 
		        	wwt.factor_per_metric_ton, 'Re-cycled' common_name, 'Re-cycled' species, 'Re-cycled' genus, 'Rii' forest_source_cat_code, 
		        	cs.cert_scheme_id, cs.name cert_scheme_name, wpd.post_recycled_country_code country_code, 
		           (CASE wpd.weight_unit_id
		             WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		             WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		           END) weight_metric_ton,
		           wpd.post_recycled_pct pct 
		           FROM 		            
		            (
		            	-- want the status of the sust sourcing group - no such thing as product status anymore
						SELECT p.*, group_status_id product_status_id
						FROM product p, product_questionnaire_group pqg, questionnaire_group qg
						WHERE p.product_id = pqg.product_id
						AND pqg.GROUP_ID = qg.group_id 
						AND lower(qg.name) = 'sustainable sourcing'
		            ) p, product_part pp, wood_part_description wpd, cert_scheme cs, wrme_wood_type wwt
		            WHERE   p.product_id = pp.product_id
		            AND     pp.product_part_id = wpd.product_part_id 
		            AND     wpd.post_cert_scheme_id = cs.cert_scheme_id
		            AND     wwt.wrme_wood_type_id = v_recycled_wood_type_id -- constant for recycled
		            AND     pp.part_type_id = v_description_part_type_id -- description type
		            --AND     p.product_code = '4814894'
		            AND     wpd.post_recycled_pct > 0
		    ) 
		    --
		    UNION
		    --
		    -- normal wood parts
		    SELECT product_id, product_status_id, product_code, product_part_id, description, forest_source_cat_code, 
		    common_name, species, genus, country_code, cert_scheme_id,  cert_scheme_name,
		    (weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100) * factor_per_metric_ton) wrme_per_unit, (weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100)) weight_per_unit
		    FROM 
		    (
		        -- get the details of the different wood types 
		        SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, ts.common_name, ts.species, ts.genus, 
		        wwt.factor_per_metric_ton, part_wood_pkg.GetForestSourceCatCode(in_act_id, pp.product_part_id) forest_source_cat_code, 
		        cs.cert_scheme_id, cs.name cert_scheme_name, wpw.country_code country_code,
		            (CASE wpd.weight_UNIT_ID
		             WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		             WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		           END) weight_metric_ton, 
		           wpd.pre_recycled_pct, wpd.post_recycled_pct 
		        FROM 		            
		            (
		            	-- want the status of the sust sourcing group - no such thing as product status anymore
						SELECT p.*, group_status_id product_status_id
						FROM product p, product_questionnaire_group pqg, questionnaire_group qg
						WHERE p.product_id = pqg.product_id
						AND pqg.GROUP_ID = qg.group_id 
						AND lower(qg.name) = 'sustainable sourcing'
		            ) p, product_part pp, wood_part_wood wpw, cert_scheme cs, wrme_wood_type wwt, wood_part_description wpd, tree_species ts
		            WHERE   p.product_id = pp.product_id
		            AND     pp.product_part_id = wpw.product_part_id
		            AND     pp.parent_id = wpd.product_part_id
		            AND     wpw.cert_scheme_id = cs.cert_scheme_id
		            AND     wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
		            AND     ts.species_code = wpw.species_code
		            AND     pp.part_type_id = v_wood_part_type_id -- wood part 
		            --AND     P.product_code = '4814894'
		    ) recycled, 
		    (
		        -- get the proportions of the different wood types for a description part (parent) 
		        SELECT pp.parent_id,  count(*) cnt
		         FROM product p, product_part pp, wood_part_wood wpw
		                WHERE   p.product_id = pp.product_id
		                AND     pp.product_part_id = wpw.product_part_id
		                AND     pp.part_type_id = v_wood_part_type_id
		                --AND     p.product_code = '4814894'
		        GROUP BY pp.parent_id
		    ) wood
		    WHERE wood.parent_id = recycled.parent_id
		) prt, country c, product_sales_volume psv, tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq, forest_source_cat fsc
		WHERE prt.product_id = psv.product_id
		  AND prt.country_code = c.country_code
		  AND t.tag_id = tgm.tag_id
		  AND tgm.tag_group_sid = tg.tag_group_sid
		  AND tg.name = 'sale_type'
		  AND pt.tag_id = t.tag_id
		  AND prt.product_id = pt.product_id
		  AND prt.product_id = pq.product_id
          AND pq.questionnaire_id  = v_wood_questionnaire -- wood
		  AND psv.period_id = in_period_id 
		  AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- in_sale_type_tag_id  
		  AND ((prt.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		  AND (wrme_per_unit * psv.volume) > 0
		  AND UPPER(prt.forest_source_cat_code) = fsc.forest_source_cat_code (+)
		ORDER BY product_code;



END;


PROCEDURE RunWWFStyleWRMEReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_recycled_wood_type_id		 	wrme_wood_type.wrme_wood_type_id%TYPE;
	v_description_part_type_id   	part_type.part_type_id%TYPE;
	v_wood_part_type_id			 	part_type.part_type_id%TYPE;	
	t_items							csr.T_SPLIT_NUMERIC_TABLE;
	v_wood_questionnaire			questionnaire.questionnaire_id%TYPE;
BEGIN

	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	-- Security check for admin??
	-- TO DO
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);
	
	-- get recycled wood_type
	SELECT wrme_wood_type_id INTO v_recycled_wood_type_id FROM wrme_wood_type WHERE lower(description) = 'recycled'; 
	
	-- get part types - 
	SELECT part_type_id INTO v_description_part_type_id FROM part_type WHERE lower(class_name) = 'part_description';
	SELECT part_type_id INTO v_wood_part_type_id FROM part_type WHERE lower(class_name) = 'part_wood';
	
	-- get wood questionaire_id
	SELECT questionnaire_id INTO v_wood_questionnaire FROM questionnaire WHERE lower(class_name) = 'wood';
	
	OPEN out_cur FOR
		SELECT product_category, species, certification_scheme, accreditation_scheme, country, SUM(weight_tonnes) weight_tonnes, SUM(wrme) wrme FROM
		(
		     SELECT product_category, common_name || ' (' || genus || ' ' || species || ')' species, cert_scheme_name certification_scheme, fsc.name accreditation_scheme, country, base_weight_tonnes weight_tonnes, wrme FROM
		     (
		        -- product "category" (merchant type) - eg. lifestyle 
		        SELECT p.product_id, tag product_category
		        FROM product p, tag t, tag_group_member tgm, tag_group tg, product_tag pt
		            WHERE t.tag_id = tgm.tag_id
		            AND tgm.tag_group_sid = tg.tag_group_sid
		            AND tg.name = 'merchant_type'
		            AND t.tag_id = pt.tag_id
		            AND p.product_id = pt.product_id
		     ) pc, forest_source_cat fsc,
		     (
		            -- this is the old WRME report basically unchanged for ease - might slimline it later but Andrew needs report urgently
		            SELECT prt.product_id, prt.description, tag brand, common_name, genus, species, cert_scheme_name, c.country, forest_source_cat_code, null forest_source_cat_name, ROUND((wrme_per_unit * psv.volume),20) wrme, ROUND((weight_per_unit * psv.volume),20) base_weight_tonnes FROM 
		            (
		                SELECT product_id, product_status_id, product_code, product_part_id, description, forest_source_cat_code, 
		                common_name, species, genus, country_code, cert_scheme_id, cert_scheme_name, 
		                (weight_metric_ton * (pct/100) * factor_per_metric_ton) wrme_per_unit, (weight_metric_ton * (pct/100)) weight_per_unit
		                FROM
		                (
		                    -- the 2 different re-cycled types 
		                    -- pre consumer
		                    SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, 
		                        wwt.factor_per_metric_ton, 'Re-cycled' common_name, 'Re-cycled' species, 'Re-cycled' genus, 'Ri' forest_source_cat_code, 
		                        cs.cert_scheme_id, cs.name cert_scheme_name, wpd.pre_recycled_country_code country_code, 
		                       (CASE wpd.weight_unit_id
		                         WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		                         WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		                       END) weight_metric_ton, wpd.pre_recycled_pct pct 
		                        FROM 		            
				            	(
					            	-- want the status of the sust sourcing group - no such thing as product status anymore
									SELECT p.*, group_status_id product_status_id
									FROM product p, product_questionnaire_group pqg, questionnaire_group qg
									WHERE p.product_id = pqg.product_id
									AND pqg.GROUP_ID = qg.group_id 
									AND lower(qg.name) = 'sustainable sourcing'
				            	) p, product_part pp, wood_part_description wpd, cert_scheme cs, wrme_wood_type wwt
		                        WHERE   p.product_id = pp.product_id
		                        AND     pp.product_part_id = wpd.product_part_id 
		                        AND     wpd.pre_cert_scheme_id = cs.cert_scheme_id
		                        AND     wwt.wrme_wood_type_id = v_recycled_wood_type_id -- constant for recycled
		                        AND     pp.part_type_id = v_description_part_type_id -- description type 
		                       -- AND     p.product_code = '4814894'
		                        AND     wpd.pre_recycled_pct > 0
		                  UNION
		                      -- post consumer    
		                    SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, 
		                        wwt.factor_per_metric_ton, 'Re-cycled' common_name, 'Re-cycled' species, 'Re-cycled' genus, 'Rii' forest_source_cat_code, 
		                        cs.cert_scheme_id, cs.name cert_scheme_name, wpd.post_recycled_country_code country_code, 
		                       (CASE wpd.weight_unit_id
		                         WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		                         WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		                       END) weight_metric_ton,
		                       wpd.post_recycled_pct pct 
		                       FROM 		            
		                       (
					            	-- want the status of the sust sourcing group - no such thing as product status anymore
									SELECT p.*, group_status_id product_status_id
									FROM product p, product_questionnaire_group pqg, questionnaire_group qg
									WHERE p.product_id = pqg.product_id
									AND pqg.GROUP_ID = qg.group_id 
									AND lower(qg.name) = 'sustainable sourcing'
		            			) p, product_part pp, wood_part_description wpd, cert_scheme cs, wrme_wood_type wwt
		                        WHERE   p.product_id = pp.product_id
		                        AND     pp.product_part_id = wpd.product_part_id 
		                        AND     wpd.post_cert_scheme_id = cs.cert_scheme_id
		                        AND     wwt.wrme_wood_type_id = v_recycled_wood_type_id -- constant for recycled
		                        AND     pp.part_type_id = v_description_part_type_id -- description type
		                        --AND     p.product_code = '4814894'
		                        AND     wpd.post_recycled_pct > 0
		                ) 
		                --
		                UNION
		                --
		                -- normal wood parts
		                SELECT product_id, product_status_id, product_code, product_part_id, description, forest_source_cat_code, 
		                common_name, species, genus, country_code, cert_scheme_id,  cert_scheme_name,
		                (weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100) * factor_per_metric_ton) wrme_per_unit, (weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100)) weight_per_unit
		                FROM 
		                (
		                    -- get the details of the different wood types 
		                    SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, ts.common_name, ts.species, ts.genus, 
		                    wwt.factor_per_metric_ton, part_wood_pkg.GetForestSourceCatCode(in_act_id, pp.product_part_id) forest_source_cat_code, 
		                    cs.cert_scheme_id, cs.name cert_scheme_name, wpw.country_code country_code,
		                        (CASE wpd.weight_UNIT_ID
		                         WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		                         WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		                       END) weight_metric_ton, 
		                       wpd.pre_recycled_pct, wpd.post_recycled_pct
		                    	FROM 		            
		                    	(
		            				-- want the status of the sust sourcing group - no such thing as product status anymore
									SELECT p.*, group_status_id product_status_id
									FROM product p, product_questionnaire_group pqg, questionnaire_group qg
									WHERE p.product_id = pqg.product_id
									AND pqg.GROUP_ID = qg.group_id 
									AND lower(qg.name) = 'sustainable sourcing'
					            ) p, product_part pp, wood_part_wood wpw, cert_scheme cs, wrme_wood_type wwt, wood_part_description wpd, tree_species ts
		                        WHERE   p.product_id = pp.product_id
		                        AND     pp.product_part_id = wpw.product_part_id
		                        AND     pp.parent_id = wpd.product_part_id
		                        AND     wpw.cert_scheme_id = cs.cert_scheme_id
		                        AND     wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
		                        AND     ts.species_code = wpw.species_code
		                        AND     pp.part_type_id = v_wood_part_type_id -- wood part 
		                        --AND     P.product_code = '4814894'
		                ) recycled, 
		                (
		                    -- get the proportions of the different wood types for a description part (parent) 
		                    SELECT pp.parent_id,  count(*) cnt
		                     FROM product p, product_part pp, wood_part_wood wpw
		                            WHERE   p.product_id = pp.product_id
		                            AND     pp.product_part_id = wpw.product_part_id
		                            AND     pp.part_type_id = v_wood_part_type_id -- wood part 
		                            --AND     p.product_code = '4814894'
		                    GROUP BY pp.parent_id
		                ) wood
		                WHERE wood.parent_id = recycled.parent_id
		            ) prt, country c, product_sales_volume psv, tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		            WHERE prt.product_id = psv.product_id
						AND prt.country_code = c.country_code
						AND t.tag_id = tgm.tag_id
						AND tgm.tag_group_sid = tg.tag_group_sid
						AND tg.name = 'sale_type'
						AND pt.tag_id = t.tag_id
						AND prt.product_id = pt.product_id
						AND prt.product_id = pq.product_id
						AND pq.questionnaire_id  = v_wood_questionnaire -- wood
						AND psv.period_id = in_period_id 
						AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- in_sale_type_tag_id  
						AND ((prt.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
						AND (wrme_per_unit * psv.volume) > 0
		            ORDER BY product_code
		     ) prt
		     WHERE prt.product_id = pc.product_id
		     AND lower(fsc.forest_source_cat_code) = lower(prt.forest_source_cat_code)
		) 
		GROUP BY product_category, species, certification_scheme, accreditation_scheme, country
		ORDER BY product_category, species, certification_scheme, accreditation_scheme, country;



END;


PROCEDURE RunAccreditationValueReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_recycled_wood_type_id		 	wrme_wood_type.wrme_wood_type_id%TYPE;
	v_description_part_type_id   	part_type.part_type_id%TYPE;
	v_wood_part_type_id			 	part_type.part_type_id%TYPE;	
	t_items							csr.T_SPLIT_NUMERIC_TABLE;
	v_wood_questionnaire			questionnaire.questionnaire_id%TYPE;
BEGIN

	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	-- Security check for admin??
	-- TO DO
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);
	
	-- get recycled wood_type
	SELECT wrme_wood_type_id INTO v_recycled_wood_type_id FROM wrme_wood_type WHERE lower(description) = 'recycled'; 
	
	-- get part types - 
	SELECT part_type_id INTO v_description_part_type_id FROM part_type WHERE lower(class_name) = 'part_description';
	SELECT part_type_id INTO v_wood_part_type_id FROM part_type WHERE lower(class_name) = 'part_wood';
	
	-- get wood questionaire_id
	SELECT questionnaire_id INTO v_wood_questionnaire FROM questionnaire WHERE lower(class_name) = 'wood';
	
	OPEN out_cur FOR
    SELECT fsc.forest_source_cat_code, ROUND(NVL(value_gbp,0),2) value_gbp, NVL(wrme,0) wrme, NVL(weight_tonne,0) weight_tonne FROM forest_source_cat fsc, 
    (
        SELECT forest_source_cat_code, SUM(pct_for_part/100 * psv.value) value_gbp, sum(ROUND((wrme_per_unit * psv.volume),20)) wrme, sum(ROUND((weight_per_unit * psv.volume),20)) weight_tonne FROM
		(
		    SELECT product_id, product_status_id, product_code, product_part_id, description, forest_source_cat_code, 
		    common_name, species, genus, country_code, cert_scheme_id, cert_scheme_name, 
		    (weight_metric_ton * (pct/100) * factor_per_metric_ton) wrme_per_unit, (weight_metric_ton * (pct/100)) weight_per_unit, (pct) pct_for_part
		    FROM
		    (
		        -- the 2 different re-cycled types 
		        -- pre consumer
		        SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, 
		        	wwt.factor_per_metric_ton, 'Re-cycled' common_name, 'Re-cycled' species, 'Re-cycled' genus, 'RI' forest_source_cat_code, 
		        	cs.cert_scheme_id, cs.name cert_scheme_name, wpd.pre_recycled_country_code country_code, 
		           (CASE wpd.weight_unit_id
		             WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		             WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		           END) weight_metric_ton, wpd.pre_recycled_pct pct 
		            FROM 
		           	(
		            	-- want the status of the sust sourcing group - no such thing as product status anymore
						SELECT p.*, group_status_id product_status_id
						FROM product p, product_questionnaire_group pqg, questionnaire_group qg
						WHERE p.product_id = pqg.product_id
						AND pqg.GROUP_ID = qg.group_id 
						AND lower(qg.name) = 'sustainable sourcing'
		            ) p,
		            product_part pp, wood_part_description wpd, cert_scheme cs, wrme_wood_type wwt
		            WHERE   p.product_id = pp.product_id
		            AND     pp.product_part_id = wpd.product_part_id 
		            AND     wpd.pre_cert_scheme_id = cs.cert_scheme_id
		            AND     wwt.wrme_wood_type_id = v_recycled_wood_type_id -- constant for recycled
		            AND     pp.part_type_id = v_description_part_type_id -- description type 
		           -- AND     p.product_code = '4814894'
		            AND     wpd.pre_recycled_pct > 0
		      UNION
		      	-- post consumer	
		        SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, 
		        	wwt.factor_per_metric_ton, 'Re-cycled' common_name, 'Re-cycled' species, 'Re-cycled' genus, 'RII' forest_source_cat_code, 
		        	cs.cert_scheme_id, cs.name cert_scheme_name, wpd.post_recycled_country_code country_code, 
		           (CASE wpd.weight_unit_id
		             WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		             WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		           END) weight_metric_ton,
		           wpd.post_recycled_pct pct 
		           FROM 
		           (
		            	-- want the status of the sust sourcing group - no such thing as product status anymore
						SELECT p.*, group_status_id product_status_id
						FROM product p, product_questionnaire_group pqg, questionnaire_group qg
						WHERE p.product_id = pqg.product_id
						AND pqg.GROUP_ID = qg.group_id 
						AND lower(qg.name) = 'sustainable sourcing'
		            ) p,
		           product_part pp, wood_part_description wpd, cert_scheme cs, wrme_wood_type wwt
		            WHERE   p.product_id = pp.product_id
		            AND     pp.product_part_id = wpd.product_part_id 
		            AND     wpd.post_cert_scheme_id = cs.cert_scheme_id
		            AND     wwt.wrme_wood_type_id = v_recycled_wood_type_id -- constant for recycled
		            AND     pp.part_type_id = v_description_part_type_id -- description type
		            --AND     p.product_code = '4814894'
		            AND     wpd.post_recycled_pct > 0
		    ) 
		    --
		    UNION
		    --
		    -- normal wood parts
		    SELECT product_id, product_status_id, product_code, product_part_id, description, forest_source_cat_code, 
		    common_name, species, genus, country_code, cert_scheme_id,  cert_scheme_name, 
		    (weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100) * factor_per_metric_ton) wrme_per_unit,
            (weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100)) weight_per_unit, (((100 - pre_recycled_pct - post_recycled_pct)/cnt)) pct_for_part
		    FROM 
		    (
		        -- get the details of the different wood types 
		        SELECT p.product_id, p.product_status_id, parent_id, p.product_code, p.description, pp.product_part_id, ts.common_name, ts.species, ts.genus, 
		        wwt.factor_per_metric_ton, part_wood_pkg.GetForestSourceCatCode(in_act_id, pp.product_part_id) forest_source_cat_code, 
		        cs.cert_scheme_id, cs.name cert_scheme_name, wpw.country_code country_code,
		            (CASE wpd.weight_UNIT_ID
		             WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
		             WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
		           END) weight_metric_ton, 
		           wpd.pre_recycled_pct, wpd.post_recycled_pct
		        FROM 
		        	 (
		            	-- want the status of the sust sourcing group - no such thing as product status anymore
						SELECT p.*, group_status_id product_status_id
						FROM product p, product_questionnaire_group pqg, questionnaire_group qg
						WHERE p.product_id = pqg.product_id
						AND pqg.GROUP_ID = qg.group_id 
						AND lower(qg.name) = 'sustainable sourcing'
		            ) p,
		            product_part pp, wood_part_wood wpw, cert_scheme cs, wrme_wood_type wwt, wood_part_description wpd, tree_species ts
		            WHERE   p.product_id = pp.product_id
		            AND     pp.product_part_id = wpw.product_part_id
		            AND     pp.parent_id = wpd.product_part_id
		            AND     wpw.cert_scheme_id = cs.cert_scheme_id
		            AND     wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
		            AND     ts.species_code = wpw.species_code
		            AND     pp.part_type_id = v_wood_part_type_id -- wood part 
		            --AND     P.product_code = '4814894'
		    ) recycled, 
		    (
		        -- get the proportions of the different wood types for a description part (parent) 
		        SELECT pp.parent_id,  count(*) cnt
		         FROM product p, product_part pp, wood_part_wood wpw
		                WHERE   p.product_id = pp.product_id
		                AND     pp.product_part_id = wpw.product_part_id
		                AND     pp.part_type_id = v_wood_part_type_id
		                --AND     p.product_code = '4814894'
		        GROUP BY pp.parent_id
		    ) wood
		    WHERE wood.parent_id = recycled.parent_id
   		) prt, country c, product_sales_volume psv, tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq
		WHERE prt.product_id = psv.product_id
		  AND prt.country_code = c.country_code
		  AND t.tag_id = tgm.tag_id
		  AND tgm.tag_group_sid = tg.tag_group_sid
		  AND tg.name = 'sale_type'
		  AND pt.tag_id = t.tag_id
		  AND prt.product_id = pt.product_id
		  AND prt.product_id = pq.product_id
          AND pq.questionnaire_id  = v_wood_questionnaire -- wood
		  AND psv.period_id = in_period_id 
		  AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- in_sale_type_tag_id  
		  AND ((prt.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) -- in_report_only_on_approved 
		  AND (wrme_per_unit * psv.volume) > 0
        GROUP BY forest_source_cat_code
      ) prt 
      WHERE fsc.forest_source_cat_code = prt.forest_source_cat_code(+)
	  ORDER BY fsc.forest_source_cat_code;

END;

PROCEDURE RunWoodDataDumpReport(
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
	v_wood_questionnaire_id 	questionnaire.questionnaire_id%TYPE := NULL;
	v_wood_part_type_id 		part_type.part_type_id%TYPE := NULL;
	v_description_part_type_id 	part_type.part_type_id%TYPE := NULL;
	v_rec_factor_per_metric_ton	wrme_wood_type.factor_per_metric_ton%TYPE := NULL;
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
	
	SELECT questionnaire_id
	INTO v_wood_questionnaire_id
	FROM questionnaire
	WHERE LOWER(class_name) = 'wood';

	SELECT part_type_id
	INTO v_wood_part_type_id
	FROM part_type
	WHERE LOWER(class_name) = 'part_wood';

	SELECT part_type_id
	INTO v_description_part_type_id
	FROM part_type
	WHERE LOWER(class_name) = 'part_description';

	SELECT factor_per_metric_ton
	INTO v_rec_factor_per_metric_ton
	FROM wrme_wood_type
	WHERE LOWER(description) = 'recycled';
	
	OPEN out_cur FOR
	SELECT
		p.product_id, p.product_code, p.description product_description, t.tag product_category, gs.description product_status, 
		c.name supplier_company, cu.full_name product_declaration, per.volume product_sales_volume, NVL(wrme.wrme, 0) "WRME For All Sales (tonnes)",
		wp.description part_description, wp.number_in_product part_count, wp.weight_g "Part Total Weight (g)", 
		wp.pre_recycled_pct part_pre_recycled_pct, wp.pre_cert_scheme part_pre_cert_scheme, wp.pre_recycled_country part_pre_recycled_country,  
		wp.post_recycled_pct part_post_recycled_pct, wp.post_cert_scheme part_post_cert_scheme, wp.post_recycled_country part_post_recycled_country, 
		wp.wood_count part_wood_count, wp.common_name wood_common_name, wp.species wood_species, wp.genus wood_genus,
		wp.wrme_wood_type wrme_wood_type_description, wp.country wood_country, wp.region wood_region, wp.forest_source_cat_code wood_fcs_accreditation_type,
		wp.cert_scheme wood_cert_scheme, wp.bleaching_process wood_bleaching_process, wp.has_doc documents_attatched
	FROM supplier.product p 
	JOIN supplier.company c ON p.supplier_company_sid = c.company_sid
	
	JOIN supplier.product_questionnaire pq ON p.product_id = pq.product_id AND pq.questionnaire_id = v_wood_questionnaire_id --variable
	JOIN supplier.product_tag pt ON pq.product_id = pt.product_id
	JOIN supplier.tag t ON pt.tag_id = t.tag_id  
	JOIN supplier.tag_group_member tgm ON t.tag_id = tgm.tag_id
	JOIN supplier.tag_group tg ON tgm.tag_group_sid = tg.tag_group_sid AND LOWER(tg.name) = 'merchant_type'
	
	JOIN supplier.product_questionnaire_group pqg ON p.product_id = pqg.product_id
	JOIN supplier.questionnaire_group qg ON pqg.group_id = qg.group_id AND LOWER(qg.name) = 'sustainable sourcing'
	JOIN supplier.group_status gs ON pqg.group_status_id = gs.group_status_id
	LEFT JOIN csr.csr_user cu ON pqg.declaration_made_by_sid = cu.csr_user_sid
	
	JOIN supplier.product_questionnaire_group pqg2 ON p.product_id = pqg2.product_id AND (in_report_on_unapproved <> 0 OR pqg2.group_status_id = product_pkg.DATA_APPROVED) --variable
	JOIN supplier.questionnaire_group qg2 ON pqg2.group_id = qg2.group_id AND LOWER(qg2.name) = 'sustainable sourcing'
	
	JOIN supplier.product_tag pt2 ON p.product_id = pt2.product_id AND pt2.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- in_sale_type_tag_id
	JOIN supplier.tag_group_member tgm2 ON pt2.tag_id = tgm2.tag_id
	JOIN supplier.tag_group tg2 ON tgm2.tag_group_sid = tg2.tag_group_sid AND LOWER(tg2.name) = 'sale_type'

	LEFT JOIN supplier.product_sales_volume per ON p.product_id = per.product_id AND per.period_id = in_period_id --variable
	LEFT JOIN
	(
		SELECT prt.product_id, NVL(SUM(ROUND((wrme_per_unit * psv.volume),20)),0) wrme
		FROM
		(
			-- the 2 different re-cycled types
			-- pre consumer
			SELECT p.product_id,
			  CASE wpd.weight_unit_id
				WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000 -- grams
				WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000 -- kg
			  END * (wpd.pre_recycled_pct/100) * v_rec_factor_per_metric_ton wrme_per_unit --variable
			FROM supplier.product p
			JOIN supplier.product_part pp ON p.product_id = pp.product_id AND pp.part_type_id = v_description_part_type_id --variable
			JOIN supplier.wood_part_description wpd ON pp.product_part_id = wpd.product_part_id AND wpd.pre_recycled_pct > 0
			UNION ALL
			-- post consumer
			SELECT p.product_id,
			  CASE wpd.weight_unit_id
				WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000 -- grams
				WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000 -- kg
			  END * (wpd.post_recycled_pct/100) * v_rec_factor_per_metric_ton wrme_per_unit --variable
			FROM supplier.product p
			JOIN supplier.product_part pp ON p.product_id = pp.product_id AND pp.part_type_id = v_description_part_type_id --variable
			JOIN supplier.wood_part_description wpd ON pp.product_part_id = wpd.product_part_id AND wpd.post_recycled_pct > 0
			--
			UNION ALL
			--
			-- normal wood parts
			-- get the details of the different wood types
			SELECT pp.product_id,
				CASE wpd.weight_unit_id
					WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000 -- grams
					WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000 -- kg
				END --weight_metric_ton
				* (((100 - wpd.pre_recycled_pct - wpd.post_recycled_pct)/wood.cnt)/100) * wwt.factor_per_metric_ton wrme_per_unit
			FROM supplier.product_part pp
			JOIN supplier.wood_part_wood wpw ON pp.product_part_id = wpw.product_part_id
			JOIN supplier.wrme_wood_type wwt ON wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
			JOIN supplier.wood_part_description wpd ON pp.parent_id = wpd.product_part_id
			JOIN
			(
				-- get the proportions of the different wood types for a description part (parent)
				SELECT pp.parent_id, COUNT(*) cnt
				FROM supplier.product p
				JOIN supplier.product_part pp ON p.product_id = pp.product_id AND pp.part_type_id = v_wood_part_type_id --variable
				JOIN supplier.wood_part_wood wpw ON pp.product_part_id = wpw.product_part_id
				GROUP BY pp.parent_id
			) wood ON pp.parent_id = wood.parent_id
			WHERE pp.part_type_id = v_wood_part_type_id --variable
		) prt
		JOIN supplier.product_questionnaire pq ON prt.product_id = pq.product_id AND pq.questionnaire_id = v_wood_questionnaire_id --variable
		JOIN supplier.product_sales_volume psv ON prt.product_id = psv.product_id AND psv.period_id = in_period_id --variable
		GROUP BY prt.product_id
	) wrme ON p.product_id = wrme.product_id
	LEFT JOIN
	(
		SELECT
			-- wood desc
			pp.product_id, wpd.description, wpd.number_in_product,
			CASE wpd.weight_unit_id
			  WHEN 1 THEN wpd.weight * wpd.number_in_product -- grams
			  WHEN 2 THEN wpd.weight * wpd.number_in_product * 1000 -- kg
			END weight_g,
			wpd.pre_recycled_pct, cs_pre.name pre_cert_scheme, c_pre.country pre_recycled_country,
			wpd.post_recycled_pct, cs_post.name post_cert_scheme, c_post.country post_recycled_country,
			-- wood part
			wpwn.num_parts wood_count,
			wpw.common_name, wpw.species, wpw.genus, wpw.wrme_wood_type, wpw.country, wpw.region,
			wpw.forest_source_cat_code, wpw.cert_scheme, wpw.bleaching_process, wpw.has_doc
		FROM supplier.wood_part_description wpd
		JOIN supplier.product_part pp ON wpd.product_part_id = pp.product_part_id
		LEFT JOIN supplier.cert_scheme cs_pre ON wpd.pre_cert_scheme_id = cs_pre.cert_scheme_id
		LEFT JOIN supplier.cert_scheme cs_post ON wpd.post_cert_scheme_id = cs_post.cert_scheme_id
		LEFT JOIN supplier.country c_pre ON wpd.pre_recycled_country_code = c_pre.country_code
		LEFT JOIN supplier.country c_post ON wpd.post_recycled_country_code = c_post.country_code
		LEFT JOIN
		(
			SELECT parent_id, COUNT(product_part_id) num_parts
			FROM supplier.product_part
			GROUP BY parent_id
		) wpwn ON wpd.product_part_id = wpwn.parent_id
		LEFT JOIN
		(
			SELECT ts.common_name, ts.species, ts.genus, wwt.description wrme_wood_type,
				c.country, region, fsc.name forest_source_cat_code, cs.description cert_scheme, bp.name bleaching_process,
				DECODE (dg.has_doc, 0, 'N', NULL, 'N', 'Y') has_doc,
				pp.parent_id
			FROM supplier.wood_part_wood wpw
			JOIN supplier.product_part pp ON wpw.product_part_id = pp.product_part_id
			JOIN supplier.country c ON LOWER(wpw.country_code) = LOWER(c.country_code)
			JOIN supplier.cert_scheme cs ON wpw.cert_scheme_id = cs.cert_scheme_id
			LEFT JOIN supplier.bleaching_process bp ON wpw.bleaching_process_id = bp.bleaching_process_id
			JOIN supplier.tree_species ts ON LOWER(wpw.species_code) = LOWER(ts.species_code)
			LEFT JOIN supplier.wrme_wood_type wwt ON wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
			LEFT JOIN supplier.v$doc_group_has_doc dg ON wpw.cert_doc_group_id = dg.document_group_id
			LEFT JOIN supplier.forest_source_cat fsc ON DECODE(ts.means_verified + c.means_verified, 2, cs.verified_fscc, cs.non_verified_fscc) = fsc.forest_source_cat_code
		) wpw ON wpd.product_part_id = wpw.parent_id
	) wp ON p.product_id = wp.product_id 
	WHERE p.active = 1
	  AND p.app_sid = security.security_pkg.getApp
	ORDER BY p.product_code
	;
END;


PROCEDURE RunWoodDataDumpReportTEST(
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
	SELECT  p.* 
	FROM (
	------
				SELECT
				p.product_id, 
				p.product_code, 
				p.description product_description, 
				pi.product_category, 
				pi.product_status_description product_status, 
				c.name supplier_company, 
				pi.declaration_made_by_name product_declaration, 
				volume product_sales_volume, 
				NVL(wrme, 0) "WRME For All Sales (tonnes)",
				wp.description part_description, 
				number_in_product part_count, 
				weight_g "Part Total Weight (g)", 
				pre_recycled_pct part_pre_recycled_pct, 
				pre_cert_scheme part_pre_cert_scheme, 
				pre_recycled_country part_pre_recycled_country,  
				post_recycled_pct part_post_recycled_pct, 
				post_cert_scheme part_post_cert_scheme, 
				post_recycled_country part_post_recycled_country, 
				wood_count part_wood_count,
				common_name wood_common_name, 
				species wood_species, 
				genus wood_genus, 
				wrme_wood_type wrme_wood_type_description, 
				country wood_country, 
				region wood_region, 
				wp.forest_source_cat_code wood_fcs_accreditation_type, 
				cert_scheme wood_cert_scheme, 
				bleaching_process wood_bleaching_process, 
				has_doc documents_attatched
				FROM product p 
				JOIN company c ON p.supplier_company_sid = c.company_sid
				JOIN product_questionnaire pq ON p.product_id = pq.product_id
				JOIN questionnaire q on pq.questionnaire_id = q.questionnaire_id
				JOIN (
				  SELECT p.product_id, gs.description product_status_description, tag product_category, cu.full_name declaration_made_by_name
					FROM product p
					JOIN product_tag pt ON p.product_id = pt.product_id
					JOIN tag t ON pt.tag_id = t.tag_id  
					JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
					JOIN tag_group tg ON tgm.tag_group_sid = tg.tag_group_sid
					JOIN product_questionnaire_group pqg ON p.product_id = pqg.product_id
					JOIN questionnaire_group qg ON pqg.group_id = qg.group_id
					JOIN group_status gs ON pqg.group_status_id = gs.group_status_id
					LEFT JOIN csr.csr_user cu ON pqg.declaration_made_by_sid = cu.csr_user_sid
				   WHERE lower(tg.name) = 'merchant_type'
					 AND lower(qg.name) = 'sustainable sourcing'
				) pi ON p.product_id = pi.product_id
				LEFT JOIN (SELECT product_id, volume FROM supplier.product_sales_volume where period_id = in_period_id) per ON p.product_id = per.product_id
				LEFT JOIN (SELECT product_id, wrme FROM supplier.v$wrme where period_id = in_period_id) wrme ON p.product_id = wrme.product_id
				LEFT JOIN (        
						SELECT
							-- wood desc
							wpd.product_id, wpd.parent_id, wpd.product_part_id, wpd.description, number_in_product, weight, weight_unit_id, pre_recycled_pct, post_recycled_pct, pre_recycled_doc_group_id, post_recycled_doc_group_id, 
							pre_cert_scheme_id, pre_cert_scheme, post_cert_scheme_id, post_cert_scheme, pre_recycled_country_code, pre_recycled_country, post_recycled_country_code, post_recycled_country,
							weight_g,
							-- wood part
							species_code, common_name, genus, species, country, region, cert_doc_group_id, bleaching_process_id, bleaching_process, 
							wrme_wood_type_id, wrme_wood_type, cert_scheme_id, cert_scheme, fsc.name forest_source_cat_code, has_doc,
							wpwn.num_parts wood_count
						  FROM v$wood_part_description wpd 
						  LEFT JOIN (SELECT parent_id, COUNT(product_part_id) num_parts FROM product_part GROUP BY parent_id) wpwn ON wpd.product_part_id = wpwn.parent_id
						  LEFT JOIN v$wood_part_wood wpw ON wpd.product_part_id = wpw.parent_id        
						  LEFT JOIN forest_source_cat fsc ON wpw.forest_source_cat_code = fsc.forest_source_cat_code  
				) wp ON p.product_id = wp.product_id 
				WHERE lower(q.class_name) = 'wood' 
				  AND p.active = 1
				  AND p.app_sid = security.security_pkg.getApp
	------
		) p, tag t, tag_group_member tgm, tag_group tg, product_tag pt, product_questionnaire pq, 
		(
			-- want the status of the sust sourcing group - no such thing as product status anymore
			SELECT p.product_id, group_status_id product_status_id, declaration_made_by_sid
			FROM product p, product_questionnaire_group pqg, questionnaire_group qg
			WHERE p.product_id = pqg.product_id
			AND pqg.GROUP_ID = qg.group_id 
			AND lower(qg.name) = 'sustainable sourcing'
		) ps
		WHERE t.tag_id = tgm.tag_id
		AND tgm.tag_group_sid = tg.tag_group_sid
		AND tg.name = 'sale_type'
		AND pt.tag_id = t.tag_id
		AND pt.product_id = p.product_id
        AND p.product_id = pq.product_id
		AND p.product_id = ps.product_id
        AND pq.questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE lower(class_name) = 'wood')
		AND ((ps.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)) 
		AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE)))  
		ORDER BY p.product_code
		;

END;

END report_wood_pkg;
/
