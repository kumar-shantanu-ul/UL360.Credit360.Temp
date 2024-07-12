-- Please update version.sql too -- this keeps clean builds in sync
define version=12
@update_header

UPDATE gt_product_class SET units_desc = 'volume' WHERE units_desc = 'Volume';
UPDATE gt_product_class SET units_desc = 'weight' WHERE units_desc = 'Weight';

@update_tail