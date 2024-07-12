-- Please update version.sql too -- this keeps clean builds in sync
define version=37
@update_header

set define off;

INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (1, 'WOOD / PAPER');	
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(1,'Softwood (pine etc)',1, 1, 1);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(2,'Paper and Cardboard (bleached)',1, 2, 1);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(3,'Packaging Card (Cfb)',1, 1, 1);
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (2, 'METALS');	
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(4,'Zinc Die Cast High grade',0, 1, 2);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(5,'Aluminium average',0, 3, 2);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(6,'Stainless Steel 18% CR',0, 1, 2);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(7,'Tool Steel (cold rolled)',0, 1, 2);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(8,'Precious Metals',0, 10, 2);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(9,'Nickel Alloys',0, 2, 2);
	
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (3, 'PLASTICS');	
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(10,'HDPE',0, 1, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(11,'PP',0, 1, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(12,'Nylons',0, 5, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(13,'PET',0, 2, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(14,'PVC bulk',0, 2, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(15,'PS HIPS',0, 1, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(16,'ABS',0, 1, 3);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(17,'Polyester (thermosetting)',0, 1, 3);
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (4, 'GLASS');	
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(18,'Container Glass (53% cullet)',0, 1, 4);
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (5, 'OTHER');	
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(19,'Ceramic (china clay)',0, 1, 5);
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(20,'Leather Veg Tanned',1, 3, 5);
INSERT INTO gt_material_group (gt_material_group_id, description) VALUES (6, 'TEXTILES');	
	INSERT INTO gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(21,'cotton',1, 8, 6);

		
		
@update_tail