-- Please update version.sql too -- this keeps clean builds in sync
define version=68
@update_header


-- set any materials with Threatened or endangered prov types
UPDATE gt_pda_material_item
SET gt_pda_provenance_type_id = 5 
WHERE gt_pda_provenance_type_id = 7;

-- move mineral up one to replace threatened
UPDATE gt_pda_material_item
SET gt_pda_provenance_type_id = 7 
WHERE gt_pda_provenance_type_id = 8;


-- remove threatened 
DELETE FROM gt_pda_mat_prov_mapping
WHERE gt_pda_provenance_type_id = 7;

DELETE FROM gt_pda_prov_acc_mapping
WHERE gt_pda_provenance_type_id = 7;



-- move mineral up one to replace threatened
UPDATE gt_pda_prov_acc_mapping
SET gt_pda_provenance_type_id = 7
WHERE gt_pda_provenance_type_id = 8;

UPDATE gt_pda_mat_prov_mapping
SET gt_pda_provenance_type_id = 7
WHERE gt_pda_provenance_type_id = 8;

UPDATE gt_pda_provenance_type
SET description = 'Mineral derived / synthetic materials',
natural = 0,
score = 1
WHERE gt_pda_provenance_type_id = 7;

DELETE FROM gt_pda_provenance_type WHERE gt_pda_provenance_type_id = 8;


@update_tail