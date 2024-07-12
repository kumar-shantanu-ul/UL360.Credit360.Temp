-- Please update version.sql too -- this keeps clean builds in sync
define version=38
@update_header

set define off;


-- manufacturing types
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (1,'Construction (forming)',1,1,3);

INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (2,'Casting',2,1,2);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (3,'Deforming',1,1,3);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (4,'Complex assemblies (eg Electronics)',5,1,2);

INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (5,'Moulding',5,1,2);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (6,'Extrusion',2,1,2);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (7,'Complex assemblies (eg Electronics)',5,1,2);

INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (8,'Moulding',4,1,2);


INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (9,'Rubber Moulding',4,1,2);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (10,'Rubber Extrusion',1,1,2);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (11,'Construction ceramics',1,2,2);
INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (12,'Complex assemblies (eg Electronics)',5,1,2);


INSERT INTO gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (13,'Weaving',3,3,2);


-- durability types
UPDATE GT_PDA_DURABILITY_TYPE set score=10 where GT_PDA_DURABILITY_TYPE_ID=4;
		
		
@update_tail