CREATE OR REPLACE VIEW V$WOOD_PART_WOOD
AS 
SELECT
   pp.product_id, pp.parent_id, pp.product_part_id, 
   wpw.species_code, ts.common_name, ts.genus, ts.species, ts.means_verified, 
   wpw.country_code, c.country,
   region, cert_doc_group_id, 
   wpw.bleaching_process_id, bp.name bleaching_process,
   wrme_wood_type_id, wwt.description wrme_wood_type,
   wpw.cert_scheme_id, cs.description cert_scheme,
   part_wood_pkg.GetForestSourceCatCode(security.security_pkg.getAct, pp.product_part_id) forest_source_cat_code, 
   DECODE (dg.has_doc, 0, 'N', null, 'N', 'Y') has_doc
FROM supplier.wood_part_wood wpw
JOIN supplier.product_part pp ON pp.product_part_id = wpw.product_part_id
LEFT JOIN supplier.country c ON wpw.country_code = c.country_code
LEFT JOIN supplier.cert_scheme cs ON wpw.cert_scheme_id = cs.cert_scheme_id
LEFT JOIN supplier.bleaching_process bp ON wpw.bleaching_process_id = bp.bleaching_process_id
LEFT JOIN supplier.tree_species ts ON wpw.species_code = ts.species_code
LEFT JOIN supplier.wrme_wood_type wwt ON wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
LEFT JOIN supplier.v$doc_group_has_doc dg ON wpw.cert_doc_group_id = dg.document_group_id
/

CREATE OR REPLACE VIEW V$DOC_GROUP_HAS_DOC
AS
SELECT document_group_id, count(document_id) has_doc FROM supplier.document_group_member 
GROUP BY document_group_id
/

CREATE OR REPLACE VIEW V$WOOD_PART_DESCRIPTION
AS
SELECT
	pp.product_id, pp.parent_id, pp.product_part_id, wpd.description, number_in_product, 
	weight, weight_unit_id, 
	(CASE wpd.weight_UNIT_ID
	  WHEN 1 THEN wpd.weight * wpd.number_in_product    -- grams 
	  WHEN 2 THEN wpd.weight * wpd.number_in_product * 1000      -- kg 
	END) weight_g,
	pre_recycled_pct, 
	post_recycled_pct, pre_recycled_doc_group_id, post_recycled_doc_group_id, 
	pre_cert_scheme_id, cs_pre.name pre_cert_scheme, 
	post_cert_scheme_id, cs_post.name post_cert_scheme, 
	pre_recycled_country_code, c_pre.country pre_recycled_country, 
	post_recycled_country_code, c_post.country post_recycled_country
FROM supplier.wood_part_description wpd
JOIN supplier.product_part pp ON pp.product_part_id = wpd.product_part_id
LEFT JOIN supplier.cert_scheme cs_pre ON wpd.pre_cert_scheme_id = cs_pre.cert_scheme_id
LEFT JOIN supplier.cert_scheme cs_post ON wpd.post_cert_scheme_id = cs_post.cert_scheme_id
LEFT JOIN supplier.country c_pre ON wpd.pre_recycled_country_code = c_pre.country_code
LEFT JOIN supplier.country c_post ON wpd.post_recycled_country_code = c_post.country_code
/


CREATE OR REPLACE VIEW V$WRME
AS
SELECT period_id, product_id, NVL(SUM(wrme),0) wrme, volume FROM 
(    
		SELECT period_id, prt.product_id, product_code, prt.description, ROUND((wrme_per_unit * psv.volume),20) wrme, psv.volume FROM 
		(
			SELECT product_id, product_code, product_part_id, description, weight_metric_ton,
			(weight_metric_ton * (pct/100) * factor_per_metric_ton) wrme_per_unit
			FROM
			(
				-- the 2 different re-cycled types 
				-- pre consumer
				SELECT p.product_id, pp.parent_id, p.product_code, p.description, pp.product_part_id, 
					wwt.factor_per_metric_ton, 
				   (CASE wpd.weight_unit_id
					 WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
					 WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
				   END) weight_metric_ton, wpd.pre_recycled_pct pct 
					FROM product p, product_part pp, wood_part_description wpd, wrme_wood_type wwt
					WHERE   p.product_id = pp.product_id
					AND     pp.product_part_id = wpd.product_part_id 
					AND     wwt.wrme_wood_type_id = (SELECT wrme_wood_type_id FROM wrme_wood_type WHERE lower(description) = 'recycled') -- constant for recycled
					AND     pp.part_type_id = (SELECT part_type_id FROM part_type WHERE lower(class_name) = 'part_description') -- description type 
					AND     wpd.pre_recycled_pct > 0
			  UNION
				  -- post consumer    
				SELECT p.product_id, pp.parent_id, p.product_code, p.description, pp.product_part_id, 
					wwt.factor_per_metric_ton, 
				   (CASE wpd.weight_unit_id
					 WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
					 WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
				   END) weight_metric_ton, wpd.post_recycled_pct pct 
				   FROM product p, product_part pp, wood_part_description wpd, wrme_wood_type wwt
					WHERE   p.product_id = pp.product_id
					AND     pp.product_part_id = wpd.product_part_id 
					AND     wwt.wrme_wood_type_id = (SELECT wrme_wood_type_id FROM wrme_wood_type WHERE lower(description) = 'recycled') -- constant for recycled
					AND     pp.part_type_id = (SELECT part_type_id FROM part_type WHERE lower(class_name) = 'part_description') -- description type
					AND     wpd.post_recycled_pct > 0
			) 
			--
			UNION
			--
			-- normal wood parts
			SELECT product_id, product_code, product_part_id, description, weight_metric_ton,
			(weight_metric_ton * (((100 - pre_recycled_pct - post_recycled_pct)/cnt)/100) * factor_per_metric_ton) wrme_per_unit
			FROM 
			(
				-- get the details of the different wood types 
				SELECT p.product_id, pp.parent_id, p.product_code, p.description, pp.product_part_id,  
				wwt.factor_per_metric_ton, wpw.forest_source_cat_code, 
				wpw.country_code country_code,
					(CASE wpd.weight_UNIT_ID
					 WHEN 1 THEN wpd.weight * wpd.number_in_product / 1000000   -- grams 
					 WHEN 2 THEN wpd.weight * wpd.number_in_product / 1000      -- kg 
				   END) weight_metric_ton, 
				   wpd.pre_recycled_pct, wpd.post_recycled_pct
				FROM product p, product_part pp, v$wood_part_wood wpw, wrme_wood_type wwt, wood_part_description wpd
					WHERE   p.product_id = pp.product_id
					AND     pp.product_part_id = wpw.product_part_id
					AND     pp.parent_id = wpd.product_part_id
					AND     wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
					AND     pp.part_type_id = (SELECT part_type_id FROM part_type WHERE lower(class_name) = 'part_wood') -- wood part '
			) recycled, 
			(
				-- get the proportions of the different wood types for a description part (parent) 
				SELECT pp.parent_id,  count(*) cnt
				 FROM product p, product_part pp, wood_part_wood wpw
						WHERE   p.product_id = pp.product_id
						AND     pp.product_part_id = wpw.product_part_id
						AND     pp.part_type_id = (SELECT part_type_id FROM part_type WHERE lower(class_name) = 'part_wood')
				GROUP BY pp.parent_id
			) wood
			WHERE wood.parent_id = recycled.parent_id
		) prt, product_sales_volume psv, product_questionnaire pq, questionnaire q
		WHERE prt.product_id = psv.product_id(+)
		  AND prt.product_id = pq.product_id
		  AND pq.questionnaire_id  = q.questionnaire_id
		  AND lower(q.class_name) = 'wood'
		ORDER BY product_code
) GROUP BY period_id, product_id, volume
/