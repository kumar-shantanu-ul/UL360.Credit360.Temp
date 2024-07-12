-- Please update version.sql too -- this keeps clean builds in sync
define version=89
@update_header
	
-- Update gt_material water and energy scores
UPDATE gt_material SET env_impact_score=1.5, water_impact_score=1 WHERE gt_material_id=3;
UPDATE gt_material SET env_impact_score=1, water_impact_score=3 WHERE gt_material_id=6;
UPDATE gt_material SET env_impact_score=2.5, water_impact_score=1 WHERE gt_material_id=7;
UPDATE gt_material SET env_impact_score=2, water_impact_score=6 WHERE gt_material_id=32;
UPDATE gt_material SET env_impact_score=2.5, water_impact_score=2 WHERE gt_material_id=10;
UPDATE gt_material SET env_impact_score=3.5, water_impact_score=3 WHERE gt_material_id=11;
UPDATE gt_material SET env_impact_score=4, water_impact_score=2 WHERE gt_material_id=15;
UPDATE gt_material SET env_impact_score=3.5, water_impact_score=3 WHERE gt_material_id=16;
UPDATE gt_material SET env_impact_score=3.5, water_impact_score=2 WHERE gt_material_id=17;
UPDATE gt_material SET env_impact_score=2.5, water_impact_score=1 WHERE gt_material_id=19;
UPDATE gt_material SET env_impact_score=1.5, water_impact_score=4 WHERE gt_material_id=2;
UPDATE gt_material SET env_impact_score=2, water_impact_score=3 WHERE gt_material_id=9;
UPDATE gt_material SET env_impact_score=4, water_impact_score=3 WHERE gt_material_id=13;
UPDATE gt_material SET env_impact_score=4, water_impact_score=4 WHERE gt_material_id=14;
UPDATE gt_material SET env_impact_score=5, water_impact_score=6 WHERE gt_material_id=5;
UPDATE gt_material SET env_impact_score=3, water_impact_score=5 WHERE gt_material_id=20;
UPDATE gt_material SET env_impact_score=5, water_impact_score=8 WHERE gt_material_id=12;
UPDATE gt_material SET env_impact_score=8, water_impact_score=8 WHERE gt_material_id=21;
UPDATE gt_material SET env_impact_score=10, water_impact_score=10 WHERE gt_material_id=8;



@update_tail