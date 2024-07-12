-- Please update version.sql too -- this keeps clean builds in sync
define version=19
@update_header

-- product with gt prod type => just shows current revision 
CREATE OR REPLACE VIEW GT_PRODUCT AS 
SELECT p.*, gtp.gt_product_type_id, gtp.gt_product_type_group_id, 
       av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit
  FROM product p, product_tag pt, gt_tag_product_type gtpt, gt_product_type gtp
 WHERE p.product_id = pt.product_id
   AND pt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id;



@update_tail