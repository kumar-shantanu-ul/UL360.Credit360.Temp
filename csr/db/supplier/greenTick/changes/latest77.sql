-- Please update version.sql too -- this keeps clean builds in sync
define version=77
@update_header

UPDATE gt_product_type SET MAINS_POWERED=1 WHERE GT_PRODUCT_TYPE_ID=156;
UPDATE gt_product_type SET MAINS_POWERED=1 WHERE GT_PRODUCT_TYPE_ID=159;
UPDATE gt_product_type SET MAINS_POWERED=1 WHERE GT_PRODUCT_TYPE_ID=164;
UPDATE gt_product_type SET MAINS_POWERED=1 WHERE GT_PRODUCT_TYPE_ID=173;
UPDATE gt_product_type SET MAINS_POWERED=1 WHERE GT_PRODUCT_TYPE_ID=178;
UPDATE gt_product_type SET MAINS_POWERED=1 WHERE GT_PRODUCT_TYPE_ID=192;



@update_tail