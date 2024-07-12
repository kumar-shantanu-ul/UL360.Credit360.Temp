-- Please update version.sql too -- this keeps clean builds in sync
define version=76
@update_header

-- change name of one mat
UPDATE gt_material 
SET description = 'Container Glass (53% recycled cullet)'
WHERE gt_material_id = 18;

-- delete the recycled material group and materials 
DELETE FROM GT_MAT_MAN_MAPPIING WHERE gt_material_id IN 
(
SELECT GT_MATERIAL_ID FROM GT_MATERIAL WHERE GT_MATERIAL_group_id = 8
);

DELETE FROM GT_PDA_HC_MAT_MAP WHERE gt_material_id IN 
(
SELECT GT_MATERIAL_ID FROM GT_MATERIAL WHERE GT_MATERIAL_group_id = 8
);

DELETE FROM GT_PDA_MAT_PROV_MAPPING WHERE gt_material_id IN 
(
SELECT GT_MATERIAL_ID FROM GT_MATERIAL WHERE GT_MATERIAL_group_id = 8
);


DELETE FROM GT_MATERIAL WHERE GT_MATERIAL_group_id = 8;
DELETE FROM GT_MATERIAL_GROUP WHERE GT_MATERIAL_group_id = 8;

-- insert new materials
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (31,'Recycled',1,1,1);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (32,'Aluminium (over 20% recycled)',0,2,2);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (33,'Steel 100% Recycled',0,1,2);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (34,'Recycled Plastic (over 50% content)',0,1,3);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (35,'Small multi material components',0,5,7);



-- add manufacturing type for pre-assembled
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (
   GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, 
   WATER_REQ_SCORE, WASTE_SCORE) 
VALUES (15, 'Component manufacture and assembly', 5, 1, 1);

-- add single material from this pre-assembled group
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (
   GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
VALUES (26, 15);

-- add material /manufac mappings - updates all - TO DO put this in a script
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 1 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 1 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 1);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 14 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 1 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 14);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 2 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 2 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 2);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 3 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 2 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 3);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 4 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 2 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 4);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 5 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 3 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 5);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 6 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 3 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 6);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 7 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 3 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 7);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 8 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 4 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 8);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 9 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 5 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 9);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 10 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 5 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 10);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 11 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 5 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 11);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 12 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 5 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 12);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 13 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 6 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 13);
INSERT INTO GT_MAT_MAN_MAPPIING ( gt_material_id, gt_manufac_type_id) SELECT gt_material_id, 15 gt_manufac_type_id FROM gt_material WHERE gt_material_group_id = 7 AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_mat_man_mappiing WHERE gt_manufac_type_id = 15);



-- map haz chems to new mats
INSERT INTO gt_pda_hc_mat_map (gt_material_id, gt_pda_haz_chem_id)
SELECT gt_material_id, gt_pda_haz_chem_id FROM gt_pda_haz_chem hc, gt_material m WHERE gt_material_id NOT IN (SELECT gt_material_id FROM gt_pda_hc_mat_map);

-- map prov types to new mats
INSERT INTO gt_pda_mat_prov_mapping (gt_material_id, gt_pda_provenance_type_id) 
    SELECT gt_material_id, gt_pda_provenance_type_id 
      FROM gt_material m, gt_pda_provenance_type pt 
     WHERE m.natural = pt.natural
       AND gt_material_id NOT IN (SELECT gt_material_id FROM gt_pda_mat_prov_mapping);

@update_tail