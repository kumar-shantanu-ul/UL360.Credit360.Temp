SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 


SET DEFINE OFF;

BEGIN
	INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name) values 
	(9	,'gtPackaging',		'Packaging',		'Packaging',		'gt_packaging_pkg');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN  
		null; -- just in case clean is run multiple times
END;
/

-- gt_pack_material_type
BEGIN
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (1,'Aluminium',20,1, 5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (2,'Bio / compostable',20,2, 2.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (3,'Ceramics, type 1 glass, black glass',20,3, 0);  -- this doesnt seem to be wanted by andrew (judging by LIST 3A GT ... dec 3.xls
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (4,'Composite (tetra pak)',20,4, 3);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (5,'Degradeable',20,5, 3.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (6,'Glass',50,6, 1);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (7,'HDPE',25,7, 2.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (8,'LDPE',20,8, 3);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (9,'Mixed materials',20,9, 4);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (10,'Mixed materials (laminates)',20,10, 0); -- this doesnt seem to be wanted by andrew (judging by LIST 3A GT ... dec 3.xls
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (11,'Other (ceramics)',20,11, 2);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (12,'Other (Type 1 / Black glass)',20,12, 2.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (13,'Other plastics',20,13, 3);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (14,'Paper / card - non FSC',50,14, 1.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (15,'PE Blend',20,17, 3);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (16,'PET',25,18, 4);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (17,'PP',20,19, 3.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (18,'PS',20,20, 4);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (19,'PVC',20,21, 4);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (20,'Steel',20,22, 2.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (21,'Paper / card - FSC mixed',50,15, 1.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (22,'Paper / card - FSC pure',50,16, 1.5);
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (23,'Wood',20,23, 1.5); --only the env_impact score is  definitely right for these last two - have put in 20% recycled threshold
	INSERT INTO SUPPLIER.gt_pack_material_type (gt_pack_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (24,'ABS / SAN',20,24, 1.5);	
END;
/

BEGIN
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (1,'Aluminium',20,1, 5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (2,'Bio / compostable',20,2, 2.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (3,'Ceramics, type 1 glass, black glass',20,3, 0);  -- this doesnt seem to be wanted by andrew (judging by LIST 3A GT ... dec 3.xls
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (4,'Composite (tetra pak)',20,4, 3);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (5,'Degradeable',20,5, 3.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (6,'Glass',50,6, 1);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (7,'HDPE',25,7, 2.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (8,'LDPE',20,8, 3);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (9,'Mixed materials',20,9, 4);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (10,'Mixed materials (laminates)',20,10, 0); -- this doesnt seem to be wanted by andrew (judging by LIST 3A GT ... dec 3.xls
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (11,'Other (ceramics)',20,11, 2);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (12,'Other (Type 1 / Black glass)',20,12, 2.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (13,'Other plastics',20,13, 3);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (14,'Paper / card - non FSC',50,14, 1.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (15,'PE Blend',20,17, 3);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (16,'PET',25,18, 4);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (17,'PP',20,19, 3.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (18,'PS',20,20, 4);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (19,'PVC',20,21, 4);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (20,'Steel',20,22, 2.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (21,'Paper / card - FSC mixed',50,15, 1.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (22,'Paper / card - FSC pure',50,16, 1.5);
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (23,'Wood',20,23, 1.5); --only the env_impact score is  definitely right for these last two - have put in 20% recycled threshold
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (24,'ABS / SAN',20,24, 1.5);	
	-- also inserting a row specifically for transit packaging material associated with existing products when this set of changes is applied... 
	INSERT INTO SUPPLIER.gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (25,'Unknown',20,25, 5);	

		
END;
/


-- gt_pack_shape_type
BEGIN
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (1,'Box / Carton / Case',1);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (2,'Card / Sleeve',2);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (3,'Vac Forms Blisters / Pots',3);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (4,'Injection Moulded / Moulded Containers',4);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (5,'Bottle / Jar',5);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (6,'Can / Tin / Aerosol',6);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (7,'Tube (+ Cap)',7);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (8,'Bag / Sachet / Pouch',8);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (9,'Tray / Moulding',9);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (10,'Seal /Lidding',10);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (11,'Closure',11);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (12,'Wrapping',12);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (13,'Label / Swing Ticket',13);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (14,'Void Filler',14);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (15,'Tape / Strap',15);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (16,'Layering Pad / Piece',16);
	INSERT INTO SUPPLIER.gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (17,'Other',17);
END;
/
BEGIN	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,1 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,20 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,2 ,0,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,5 ,0,1,0,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,4 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,11 ,0,0,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,6 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,1 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,9 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,6 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,1 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,20 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,16 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,7 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,17 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,19 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,13 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,12 ,0,0,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (6 ,1 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (6 ,20 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (6 ,10 ,1,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,1 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,20 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,15 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (8 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,1 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,20 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,1 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,1 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,20 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (12 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (13 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (14 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (16 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,1 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,20 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,14 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,16 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,7 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,8 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,17 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,18 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,19 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,13 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,2 ,0,1,1,1 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,5 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,10 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,3 ,0,0,0,0 );
	
	-- WOOD shapes
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,23 ,1,1,1,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,23 ,1,1,1,0 );
	-- ABS / SAN shapes
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (1 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (2 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (3 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (5 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (7 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (9 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (10 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (11 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (15 ,24 ,0,1,0,0 );
	INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (17 ,24 ,0,1,0,0 );
	--INSERT INTO SUPPLIER.GT_SHAPE_MATERIAL_MAPPING (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (18 ,24 ,0,1,0,0 );

END;
/
-- gt_access_visc_type -- gt_access_pack_type -- gt_access_pack_mapping
BEGIN

	
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (1,'Jars / Pots - Easy to access and wipe with fingers',1);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (2,'Jars / Pots - Difficult to access',2);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (3,'Aerosol - Used in upright position',3);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (4,'Aerosol - Not used upright so propellant is lost',4);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (5,'Spray pump - Correct diptube length (to within 1mm of base of container)',5);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (6,'Spray pump - Incorrect diptube length',6);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (7,'Dispensing Pump - Correct diptube length (to within 1mm of base of container)',7);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (8,'Dispensing Pump - Incorrect diptube length',8);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (9,'Pump pack',9);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (10,'Bottle / cap - with good drainage',10);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (11,'Bottle / cap - product clings to bottle sides or dispensing cap "holds" product',11);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (12,'Cap / tube',12);
	INSERT INTO SUPPLIER.gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (13,'Pouch pack',13);
	
	-- Phase 3
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (14,'Cartons',14);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (15,'Sleeve / Backing card',15);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (16,'Overwrap',16);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (17,'Label / swing ticket',17);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (18,'Blister Packs',18);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (19,'Godet',19);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (20,'Compact',20);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (21,'Mascara',21);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID, DESCRIPTION, POS) VALUES (22,'Stick Mechanism',22);

		
		
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (1 ,1 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (2 ,1 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (3 ,1 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (4 ,1 ,3 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (5 ,1 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (6 ,1 ,3 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (7 ,1 ,4 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (8 ,1 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (9 ,1 ,4 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (10 ,1 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (11 ,1 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (12 ,1 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (13 ,1 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (1 ,2 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (2 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (3 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (4 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (5 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (6 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (7 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (8 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (9 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (10 ,2 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (11 ,2 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (12 ,2 ,4 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (13 ,2 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (1 ,3 ,2 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (2 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (3 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (4 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (5 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (6 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (7 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (8 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (9 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (10 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (11 ,3 ,5 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (12 ,3 ,4 );
	INSERT INTO SUPPLIER.gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) values (13 ,3 ,4 );
	
	
	-- Phase 3 - new pack type / visc type mappings
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (1, 4, 1);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (2, 4, 2);	
	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (14, 4, 1);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (15, 4, 1);	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (16, 4, 1);
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (17, 4, 1);	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (18, 4, 1);
	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (19, 3, 2);	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (19, 4, 2);	
	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (20, 2, 2);		
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (20, 3, 3);		
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (20, 4, 1);		
	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (21, 2, 2);		
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (21, 3, 3);		
	
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (22, 3, 4);		
	INSERT INTO SUPPLIER.GT_ACCESS_PACK_MAPPING (GT_ACCESS_PACK_TYPE_ID, GT_ACCESS_VISC_TYPE_ID, GT_ACCESS_SCORE) VALUES (22, 4, 5);		
	
END;
/
-- gt_gift_cont_type
BEGIN
	INSERT INTO SUPPLIER.gt_gift_cont_type (gt_gift_cont_type_id, description, pos) VALUES (1 , 'No', 1);
	INSERT INTO SUPPLIER.gt_gift_cont_type (gt_gift_cont_type_id, description, pos) VALUES (2 , 'Yes - displayed open', 2);
	INSERT INTO SUPPLIER.gt_gift_cont_type (gt_gift_cont_type_id, description, pos) VALUES (3 , 'Yes displayed closed', 3);
END;
/
-- gt_trans_pack_type
BEGIN
	INSERT INTO SUPPLIER.gt_pack_layers_type (gt_pack_layers_type_id, description, pos) VALUES (1 , '1', 1);
	INSERT INTO SUPPLIER.gt_pack_layers_type (gt_pack_layers_type_id, description, pos) VALUES (2 , '2', 2);
	INSERT INTO SUPPLIER.gt_pack_layers_type (gt_pack_layers_type_id, description, pos) VALUES (3 , '3 or more', 3);
END;
/
-- gt_trans_pack_type
BEGIN
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (1 , 'Bulk single trip outers for singles to store delivery', 1, 1);
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (2 , 'One layer of shipping packaging', 2, 2);
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (3 , 'Inner bagged / overwrapped collations in an outer case', 3, 3);
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (4 , 'Dividers / bent pieces / bubble wrap in an outer case', 3.5, 4);
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (5 , 'Inner case(s) in an outer case', 4, 5);
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (6 , 'Inner case / divisions / bubble wrap / bent piece / outer case', 5, 6);
	INSERT INTO SUPPLIER.gt_trans_pack_type (gt_trans_pack_type_id, description, gt_score, pos) VALUES (7, 'Reusable transit trays / outers', 7, 0.5);	

END;
/

BEGIN
 -- pack style type for ess req
INSERT INTO SUPPLIER.GT_PACK_STYLE_TYPE (GT_PACK_STYLE_TYPE_ID, DESCRIPTION, POS) VALUES (1, 'Doubled walled jar', 1);
INSERT INTO SUPPLIER.GT_PACK_STYLE_TYPE (GT_PACK_STYLE_TYPE_ID, DESCRIPTION, POS) VALUES (2, 'Contains loose filled tablets in bottles/jars/tubs (eg: vitamins)', 1);
INSERT INTO SUPPLIER.GT_PACK_STYLE_TYPE (GT_PACK_STYLE_TYPE_ID, DESCRIPTION, POS) VALUES (3, 'Blister trays of tablets in cartons', 1);
INSERT INTO SUPPLIER.GT_PACK_STYLE_TYPE (GT_PACK_STYLE_TYPE_ID, DESCRIPTION, POS) VALUES (4, 'Gift set in a carton', 1);
INSERT INTO SUPPLIER.GT_PACK_STYLE_TYPE (GT_PACK_STYLE_TYPE_ID, DESCRIPTION, POS) VALUES (5, 'Other', 1);
END;
/

commit;
exit;