-- Please update version.sql too -- this keeps clean builds in sync
define version=21
@update_header

       -- shortcut way of getting the link products with the maximum revision number - only want to pull these back
 CREATE OR REPLACE VIEW GT_LINK_PRODUCT_MAX_REV AS
SELECT * FROM gt_link_product glp WHERE revision_id = (SELECT NVL(MAX(revision_id), -1) FROM product_revision WHERE product_id = glp.product_id) ;

@update_tail