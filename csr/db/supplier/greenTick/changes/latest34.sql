-- Please update version.sql too -- this keeps clean builds in sync
define version=34
@update_header

ALTER TABLE SUPPLIER.GT_PRODUCT_TYPE
MODIFY(GT_WATER_USE_TYPE_ID  NULL);


-- new anc mat
INSERT INTO SUPPLIER.GT_ANCILLARY_MATERIAL (GT_ANCILLARY_MATERIAL_ID, DESCRIPTION, GT_SCORE, POS) VALUES (15, 'Filter cartridges', 2, 15);

-- new type groups (not sed atm)
INSERT INTO SUPPLIER.GT_PRODUCT_TYPE_GROUP (
   GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION) 
VALUES (10, 'Manufactured (Other)');
INSERT INTO SUPPLIER.GT_PRODUCT_TYPE_GROUP (
   GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION) 
VALUES (11, 'Parent Pack');



-- new manufactured types
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(153,10,'Healthcare - Family planning',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(154,10,'Healthcare -Smoking cessation',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(155,10,'Healthcare -Bandages/plasters/dressings',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(156,10,'Healthcare - Fitness Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(157,10,'Healthcare -Footcare Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(158,10,'Healthcare - Anti-allergy bedding',3,3,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(159,10,'Healthcare -Travel Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(160,10,'Helthcare - First Aid Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(161,10,'Photo Frames',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(162,10,'Photo Albums',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(163,10,'Photo -Blank media (film etc)',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(164,10,'Photo -Novelty Items',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(165,10,'Photo Accessories (cases etc)',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(166,10,'Photo -Printer Inks (Photo)',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(167,10,'Cotton Wool product',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(168,10,'Baby - Feeding',3,2,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(169,10,'Baby -Nappies (Disposable)',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(170,10,'Baby - Nappies (Toweling)',3,3,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(171,10,'Wipes (non formulated)',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(172,10,'Baby -Changing Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(173,10,'Baby - Home safety',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(174,10,'Baby - Teethers / dummies',3,2,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(175,10,'Baby -Bath accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(176,10,'Baby - Transport',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(177,10,'Lifestyle - water filters',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(178,10,'Lifestyle - Home Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(179,10,'Beauty Accessories - manicure',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(180,10,'Lifestyle - Sunglasses',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(181,10,'Lifestyle -Clothing',3,3,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(182,10,'Lifestyle - Travel Accessories - purses / wallets',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(183,10,'Beauty Accessories - hair',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(184,10,'Beauty Accessories - manicure',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(185,10,'Beauty Accessories - make up',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(186,10,'Tissues',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(187,10,'Beauty Accessories - Fashion',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(188,10,'Hot water bottles',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(189,10,'Beauty Accessories - make up',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(190,10,'Wipes (non formulated)',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(191,10,'Dental Accessories',0,0,2,4,'g');
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(192,10,'Toys',0,0,2,4,'g');

-- single parent pack - effectively manufacured item
INSERT INTO gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit) VALUES	(193,10,'Parent pack',0,0,3,4,'g');
		
		
@update_tail