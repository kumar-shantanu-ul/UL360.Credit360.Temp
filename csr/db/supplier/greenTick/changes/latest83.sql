-- Please update version.sql too -- this keeps clean builds in sync
define version=83
@update_header
	
	-- add new environmental impact score for each type of packaging
	ALTER TABLE gt_pack_material_type ADD env_impact_score NUMBER(10, 2);
	
	UPDATE gt_pack_material_type SET env_impact_score = 5 WHERE gt_pack_material_type_id = 1;
	UPDATE gt_pack_material_type SET env_impact_score = 2.5 WHERE gt_pack_material_type_id = 2;
	UPDATE gt_pack_material_type SET env_impact_score = 2 WHERE gt_pack_material_type_id = 3;
	UPDATE gt_pack_material_type SET env_impact_score = 3 WHERE gt_pack_material_type_id = 4;
	UPDATE gt_pack_material_type SET env_impact_score = 3.5 WHERE gt_pack_material_type_id = 5;
	UPDATE gt_pack_material_type SET env_impact_score = 1 WHERE gt_pack_material_type_id = 6;
	UPDATE gt_pack_material_type SET env_impact_score = 2.5 WHERE gt_pack_material_type_id = 7;
	UPDATE gt_pack_material_type SET env_impact_score = 3 WHERE gt_pack_material_type_id = 8;
	UPDATE gt_pack_material_type SET env_impact_score = 4 WHERE gt_pack_material_type_id = 10;
	UPDATE gt_pack_material_type SET env_impact_score = 2 WHERE gt_pack_material_type_id = 11;
	UPDATE gt_pack_material_type SET env_impact_score = 2.5 WHERE gt_pack_material_type_id = 12;
	UPDATE gt_pack_material_type SET env_impact_score = 3 WHERE gt_pack_material_type_id = 13;
	UPDATE gt_pack_material_type SET env_impact_score = 1.5 WHERE gt_pack_material_type_id = 14;
	UPDATE gt_pack_material_type SET env_impact_score = 3 WHERE gt_pack_material_type_id = 15;
	UPDATE gt_pack_material_type SET env_impact_score = 4 WHERE gt_pack_material_type_id = 16;
	UPDATE gt_pack_material_type SET env_impact_score = 3.5 WHERE gt_pack_material_type_id = 17;
	UPDATE gt_pack_material_type SET env_impact_score = 4 WHERE gt_pack_material_type_id = 18;
	UPDATE gt_pack_material_type SET env_impact_score = 4 WHERE gt_pack_material_type_id = 19;
	UPDATE gt_pack_material_type SET env_impact_score = 2.5 WHERE gt_pack_material_type_id = 20;
	UPDATE gt_pack_material_type SET env_impact_score = 1.5 WHERE gt_pack_material_type_id = 21;
	UPDATE gt_pack_material_type SET env_impact_score = 1.5 WHERE gt_pack_material_type_id = 22;
	
	--WARNING: need to check the values in these new rows
	INSERT INTO gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (23,'Wood',20,23, 1.5);
	INSERT INTO gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (24,'ABS / SAN',20,24, 1.5);	
	
	-- WOOD shapes
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,23 ,1,1,1,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,23 ,1,1,1,0 );
	-- ABS / SAN shapes
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,24 ,0,1,0,0 );
	INSERT INTO GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (18 ,24 ,0,1,0,0 );

	
	-- now make it not null
	
	ALTER TABLE gt_pack_material_type MODIFY env_impact_score NOT NULL;
	
	ALTER TABLE gt_profile ADD pack_ei NUMBER(10, 2);
	ALTER TABLE gt_profile ADD materials_ei NUMBER(10, 2);

@update_tail