create or replace package body supplier.public_data_pkg
IS

PROCEDURE GetProductsByCode(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
	   	SELECT product_id, description, product_code, active, supplier_company_sid,
				max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
				max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		 FROM
		(
			SELECT p.product_id, p.description, p.product_code, p.active, 
				p.supplier_company_sid, t.tag_id, tg.name tag_group_name
			  FROM product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			 WHERE p.app_sid = in_app_sid 
		   	   AND (in_product_code IS NULL OR LOWER(p.product_code) = LOWER(in_product_code)) 
			   AND p.product_id = pt.product_id
			   AND pt.tag_id = t.tag_id
			   AND tgm.tag_id = t.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   	ORDER BY p.product_code ASC
		)
		   GROUP BY product_id, description, product_code, active,
				supplier_company_sid;
END;


PROCEDURE GetProductProfile (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN 	product_revision.revision_id%TYPE,
	out_profile			OUT	security_pkg.T_OUTPUT_CUR,
	out_biodiv			OUT	security_pkg.T_OUTPUT_CUR,
	out_source			OUT	security_pkg.T_OUTPUT_CUR,
	out_transport		OUT	security_pkg.T_OUTPUT_CUR,
	out_scores			OUT	security_pkg.T_OUTPUT_CUR,
	out_socamp			OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	
	profile_pkg.GetProductProfileData(in_act_id, in_product_id, in_revision_id, out_profile);
	profile_pkg.GetBiodiversityChartData(in_act_id, in_product_id, in_revision_id, out_biodiv);
	profile_pkg.GetSourceChartData(in_act_id, in_product_id, in_revision_id, out_source);
	profile_pkg.GetTransportToBootsData(in_act_id, in_product_id, in_revision_id, out_transport);
	model_pkg.GetSAProfile(in_act_id, in_product_id, in_revision_id, out_socamp);
	
	-- TODO!!! -- Recalc scores
	--model_pkg.CalcProductScores(in_act_id, in_product_id, in_revision_id);
	
	-- Get the score data
	OPEN out_scores FOR
		SELECT product_id, revision_id,
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
			score_water_use,
			score_energy_use,
			score_ancillary_req,
			score_prod_waste,
			score_recyclable_pack,
			score_recov_pack
		FROM gt_scores
	   WHERE product_id = in_product_id
	     AND revision_id = in_revision_id;
END;



END public_data_pkg;
/