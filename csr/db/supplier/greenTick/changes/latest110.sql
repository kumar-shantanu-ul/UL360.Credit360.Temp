-- Please update version.sql too -- this keeps clean builds in sync
define version=110
@update_header 

-- pack shape type
UPDATE SUPPLIER.GT_PACK_SHAPE_TYPE
   SET DESCRIPTION = 'Label / Swing Ticket'
 WHERE GT_PACK_SHAPE_TYPE_ID = 13;

UPDATE SUPPLIER.GT_MANUFAC_TYPE
   SET DESCRIPTION = 'Product Assembly (simple processes)'
WHERE  GT_MANUFAC_TYPE_ID = 15;

INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (17, 'Non-woven manufacture', 2, 1, 1);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (18, 'Bleaching (Chemical process)', 1, 2, 2);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (19, 'Agricultural production / fishing', 1, 2, 2);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (20, 'Mining / quarrying', 2, 2, 3);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (39,'Viscose (cellophane / rayon)', 0, 1, 6, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (39, 17);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (40,'Viscose (cellophane / rayon)', 0, 1, 5, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (40, 6);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (41,'Silicones', 0, 2, 5, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (41, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (41, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (41, 12);


INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (42,'Sponges (natural)', 1, 2, 5, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (42, 18);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (42, 19);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (43,'Sponges (synthetic)', 0, 2, 3, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (43, 5);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (44,'Natural Bristles / Hair', 1, 1, 5, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (44, 19);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (45,'Pumice Stone', 1, 2, 5, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (45, 20);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (46,'Shells', 1, 1, 5, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (46, 19);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (47,'Polyurethane (PU)', 0, 3, 3, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (47, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (47, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (47, 6);


INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (48,'EVA', 0, 1, 3, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (48, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (48, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (48, 6);



@update_tail