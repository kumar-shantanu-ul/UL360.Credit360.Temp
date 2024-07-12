-- Please update version.sql too -- this keeps clean builds in sync
define version=74
@update_header


-- extra groups
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (7, 'Pre-assembled');
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (8, 'Recycled');

-- extra materials
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (22,'Soda Lime Glass (white)',0,1,4);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (23,'Carbon Steel',0,1,2);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (24,'Natural Rubber',1,2,5);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (25,'Latex (synthetic)',0,2,5);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (26,'Electronic circuit boards etc',0,5,7);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (27,'Aluminium 100% Recycled',0,2,8);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (28,'Steel 100% Recycled',0,1,8);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (29,'Hardwood (oak etc)',1,1,1);
INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (30,'MDF',1,1,1);

-- new manufact type
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (14, 'Paper making', 1, 1, 2);

-- update manufac scores (do all as quicker)
UPDATE gt_manufac_type SET energy_req_score=1, water_req_score=1, waste_score=2 WHERE gt_manufac_type_id = 1;
UPDATE gt_manufac_type SET energy_req_score=1, water_req_score=1, waste_score=2 WHERE gt_manufac_type_id = 14;
UPDATE gt_manufac_type SET energy_req_score=2, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 2;
UPDATE gt_manufac_type SET energy_req_score=1, water_req_score=1, waste_score=2 WHERE gt_manufac_type_id = 3;
UPDATE gt_manufac_type SET energy_req_score=5, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 4;
UPDATE gt_manufac_type SET energy_req_score=5, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 5;
UPDATE gt_manufac_type SET energy_req_score=2, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 6;
UPDATE gt_manufac_type SET energy_req_score=5, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 7;
UPDATE gt_manufac_type SET energy_req_score=4, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 8;
UPDATE gt_manufac_type SET energy_req_score=4, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 9;
UPDATE gt_manufac_type SET energy_req_score=1, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 10;
UPDATE gt_manufac_type SET energy_req_score=1, water_req_score=2, waste_score=1 WHERE gt_manufac_type_id = 11;
UPDATE gt_manufac_type SET energy_req_score=5, water_req_score=1, waste_score=1 WHERE gt_manufac_type_id = 12;
UPDATE gt_manufac_type SET energy_req_score=3, water_req_score=3, waste_score=1 WHERE gt_manufac_type_id = 13;

-- update mappings
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

-- map haz chems
INSERT INTO gt_pda_hc_mat_map (gt_material_id, gt_pda_haz_chem_id)
SELECT gt_material_id, gt_pda_haz_chem_id FROM gt_pda_haz_chem hc, gt_material m WHERE gt_material_id NOT IN (SELECT gt_material_id FROM gt_pda_hc_mat_map);




@update_tail