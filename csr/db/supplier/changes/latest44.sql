-- Please update version.sql too -- this keeps clean builds in sync
define version=44
@update_header

PROMPT add FSC pure and mixed paper material types 
UPDATE GT_PACK_MATERIAL_TYPE SET pos = pos+2
WHERE pos >= 15;

UPDATE GT_PACK_MATERIAL_TYPE SET description = 'Paper / card - non FSC'
WHERE GT_PACK_MATERIAL_TYPE_ID=14;

INSERT INTO gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos) VALUES (21,'Paper / card - FSC mixed',50,15);
INSERT INTO gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos) VALUES (22,'Paper / card - FSC pure',50,16);

INSERT INTO GT_SHAPE_MATERIAL_MAPPING
SELECT 
GT_PACK_SHAPE_TYPE_ID, 21, RECYCLABLE, 
   RECOVERABLE, RENEWABLE, BIOPOLYMER
FROM GT_SHAPE_MATERIAL_MAPPING
where GT_PACK_MATERIAL_TYPE_ID=14;

INSERT INTO GT_SHAPE_MATERIAL_MAPPING
SELECT 
GT_PACK_SHAPE_TYPE_ID, 22, RECYCLABLE, 
   RECOVERABLE, RENEWABLE, BIOPOLYMER
FROM GT_SHAPE_MATERIAL_MAPPING
where GT_PACK_MATERIAL_TYPE_ID=14;

@update_tail
