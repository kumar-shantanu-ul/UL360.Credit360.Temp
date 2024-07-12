-- Please update version.sql too -- this keeps clean builds in sync
define version=25
@update_header

CREATE OR REPLACE VIEW GT_PRODUCT_REV AS 
	SELECT p."PRODUCT_ID", (select max(revision_id) from product_revision where product_id = p.product_id) revision_id, p."PRODUCT_CODE",p."DESCRIPTION",p."SUPPLIER_COMPANY_SID",p."ACTIVE",p."DELETED",p."APP_SID", gtp.gt_product_type_id, gtp.gt_product_type_group_id, 
       av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit
  FROM product p, product_tag pt, gt_tag_product_type gtpt, gt_product_type gtp
 WHERE p.product_id = pt.product_id 
   AND pt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id
   UNION 
SELECT p."PRODUCT_ID", pr.revision_id, p."PRODUCT_CODE",p."DESCRIPTION",p."SUPPLIER_COMPANY_SID",p."ACTIVE",p."DELETED",p."APP_SID", gtp.gt_product_type_id, gtp.gt_product_type_group_id, 
       av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit
  FROM product p, product_revision pr, product_revision_tag prt, gt_tag_product_type gtpt, gt_product_type gtp
 WHERE p.product_id = pr.product_id
   AND pr.product_id = prt.product_id
   AND pr.revision_id = prt.revision_id
   AND prt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id
	 ;

	
@update_tail