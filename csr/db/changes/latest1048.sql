define version=1048
@update_header

ALTER TABLE supplier.gt_product_answers ADD (PRODUCT_VOLUME_declared NUMBER(10,2));
ALTER TABLE supplier.gt_product_answers ADD (PROD_WEIGHT_declared NUMBER(10,2));

BEGIN
  FOR r IN (SELECT Revision_id, product_id, Product_Volume, Prod_Weight FROM supplier.gt_product_answers)
  LOOP
    UPDATE supplier.gt_product_answers SET product_volume_declared = r.product_volume, prod_weight_declared = r.prod_weight, 
      gt_scope_notes = gt_scope_notes||'Declared values copied to actual values for calculation purposes. Needs updating.' 
     WHERE revision_id = r.revision_id AND product_id = r.product_id;
  END LOOP;
END;
/

@../supplier/greentick/create_views
@../supplier/greentick/product_info_pkg
@../supplier/greentick/product_info_body
@../supplier/greentick/gt_packaging_pkg
@../supplier/greentick/gt_packaging_body
@../supplier/greentick/profile_body
@../supplier/greentick/revision_body

@update_tail