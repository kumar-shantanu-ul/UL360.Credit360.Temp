SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 

SET DEFINE OFF;

BEGIN
	INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name) values 
	(13	,'gtProductDesign',	'Product Design',	'Product Design',	'gt_product_design_pkg');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN  
		null; -- just in case clean is run multiple times
END;
/

BEGIN

-- basedata

INSERT INTO SUPPLIER.GT_PDA_ACCRED_TYPE (GT_PDA_ACCRED_TYPE_ID, DESCRIPTION, SCORE) VALUES (1, 'Accredited source (priority)', 1);
INSERT INTO SUPPLIER.GT_PDA_ACCRED_TYPE (GT_PDA_ACCRED_TYPE_ID, DESCRIPTION, SCORE) VALUES (2, 'Accredited source (other)', 2);
INSERT INTO SUPPLIER.GT_PDA_ACCRED_TYPE (GT_PDA_ACCRED_TYPE_ID, DESCRIPTION, SCORE) VALUES (3, 'Known legal source ', 4);
INSERT INTO SUPPLIER.GT_PDA_ACCRED_TYPE (GT_PDA_ACCRED_TYPE_ID, DESCRIPTION, SCORE) VALUES (4, 'Unknown source', 5);
INSERT INTO SUPPLIER.GT_PDA_ACCRED_TYPE (GT_PDA_ACCRED_TYPE_ID, DESCRIPTION, SCORE) VALUES (5, 'Non Natural (synthetic or mineral)', 0);

INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (8, 'Mineral derived / synthetic materials', 0, 0); 
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (7, 'Threatened or endangered species', 1, 10); 
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (6, 'Unknown Sources', 1, 5); 
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (5, 'Wild Harvested', 1, 4); 
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (4, 'Processed materials derived from palm or vegetable oils', 1, 4);
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (3, 'Palm Oil and close derivatives', 1, 4);
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (2, 'Intensively farmed materials', 1, 3); 
INSERT INTO SUPPLIER.GT_PDA_PROVENANCE_TYPE (GT_PDA_PROVENANCE_TYPE_ID, DESCRIPTION, NATURAL, SCORE) VALUES (1, 'Grown on established mixed agricultural land', 1, 2); 


-- insert accred / prov mappings
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (7,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (7,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (6,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,1);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,2);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,1);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,2);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,1);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,2);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,1);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,2);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,1);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,2);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (8,3);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (8,4);
INSERT INTO SUPPLIER.gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (8,5);




INSERT INTO SUPPLIER.GT_PDA_DURABILITY_TYPE (GT_PDA_DURABILITY_TYPE_ID, DESCRIPTION, SCORE) VALUES (1, 'Formulated / Consumables', 1);
INSERT INTO SUPPLIER.GT_PDA_DURABILITY_TYPE (GT_PDA_DURABILITY_TYPE_ID, DESCRIPTION, SCORE) VALUES (2, 'Durable - long life', 2);
INSERT INTO SUPPLIER.GT_PDA_DURABILITY_TYPE (GT_PDA_DURABILITY_TYPE_ID, DESCRIPTION, SCORE) VALUES (3, 'Durable - short life', 3);
INSERT INTO SUPPLIER.GT_PDA_DURABILITY_TYPE (GT_PDA_DURABILITY_TYPE_ID, DESCRIPTION, SCORE) VALUES (4, 'Single use / Disposable', 5);

-- new anc mat
INSERT INTO SUPPLIER.GT_ANCILLARY_MATERIAL (GT_ANCILLARY_MATERIAL_ID, DESCRIPTION, GT_SCORE, POS) VALUES (15, 'Filter cartridges', 2, 15);

-- GT_PRODUCT_TYPE_GROUP
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (10,'Manufactured (other)');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (11,'Parent pack');


-- manufactured product types
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(153,10,'Healthcare - Family planning',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(154,10,'Healthcare -Smoking cessation',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(155,10,'Healthcare -Bandages/plasters/dressings',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(156,10,'Healthcare - Fitness Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(157,10,'Healthcare -Footcare Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(158,10,'Healthcare - Anti-allergy bedding',3,3,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(159,10,'Healthcare -Travel Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(160,10,'Helthcare - First Aid Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(161,10,'Photo Frames',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(162,10,'Photo Albums',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(163,10,'Photo -Blank media (film etc)',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(164,10,'Photo -Novelty Items',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(165,10,'Photo Accessories (cases etc)',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(166,10,'Photo -Printer Inks (Photo)',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(167,10,'Cotton Wool product',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(168,10,'Baby - Feeding',3,2,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(169,10,'Baby -Nappies (Disposable)',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(170,10,'Baby - Nappies (Toweling)',3,3,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(171,10,'Wipes (non formulated)',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(172,10,'Baby -Changing Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(173,10,'Baby - Home safety',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(174,10,'Baby - Teethers / dummies',3,2,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(175,10,'Baby -Bath accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(176,10,'Baby - Transport',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(177,10,'Lifestyle - water filters',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(178,10,'Lifestyle - Home Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(179,10,'Beauty Accessories - manicure',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(180,10,'Lifestyle - Sunglasses',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(181,10,'Lifestyle -Clothing',3,3,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(182,10,'Lifestyle - Travel Accessories - purses / wallets',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(183,10,'Beauty Accessories - hair',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(184,10,'Beauty Accessories - manicure',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(185,10,'Beauty Accessories - make up',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(186,10,'Tissues',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(187,10,'Beauty Accessories - Fashion',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(188,10,'Hot water bottles',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(189,10,'Beauty Accessories - make up',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(190,10,'Wipes (non formulated)',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(191,10,'Dental Accessories',0,0,2,4,'g', -1, 4, -1);
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(192,10,'Toys',0,0,2,4,'g', -1, 4, -1);
                                                                                                                                                                                                                          
							-- single parent pack - effectively manufacured item                                                                                                                                                                      
INSERT INTO SUPPLIER.gt_product_type (gt_product_type_id, gt_product_type_group_id, description, water_usage_factor, use_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, av_water_content_pct, gt_water_use_type_id, mnfct_energy_score) VALUES	(193,10,'Parent pack',0,0,3,4,'g', -1, 4, -1);

-- haz chem scores
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (1 ,'Phthalate plasticisers: - DEHP, DBP and BBP' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (2 ,'HBCDD' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (3 ,'SCCP' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (4 ,'TBTO' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (5 ,'Cobalt dichloride' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (6 ,'Diarsenic pentoxide' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (7 ,'Diarsenic trioxide' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (8 ,'MDA' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (9 ,'Anthracene' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (10 ,'Sodium dichromate (dehydrate form)' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (11 ,'Musk xylene' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (12 ,'Lead hydrogen arsenate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (13 ,'Triethyl arsenate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (14 ,'Plasticiser: DIBP' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (15 ,'Flame retardant: Tris(2-chloroethyl) phosphate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (16 ,'Lead chromate, lead chromate molybdate sulfate red, lead sulfochromate yellow' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (17 ,'2,4 – Dinitrotoluene' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (18 ,'Five variants of anthracene oils and pastes' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (19 ,'Aluminosilicate and Zirconia Aluminosilicate refractory ceramic fibres' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (20 ,'Coal tar pitch' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (21 ,'Trichloroethylene' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (22 ,'Salts of Arsenic acid' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (23 ,'Residues & Distillates (Coal Tar), pitch distillates' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (24 ,'Disodium Tetraborate Decahydrate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (25 ,'Sodium chromate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (26 ,'Ammonium dichromate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (27 ,'Potassium dichromate' ,10 );
INSERT INTO SUPPLIER.gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (28 ,'Potassium chromate' ,10 );

-- materials
INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (1, 'WOOD / PAPER');	
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(1,'Softwood (pine etc)',1, 1, 1);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(2,'Paper and Cardboard (bleached)',1, 2, 1);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(3,'Packaging Card (Cfb)',1, 1, 1);
INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (2, 'METALS');	
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(4,'Zinc Die Cast High grade',0, 1, 2);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(5,'Aluminium average',0, 3, 2);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(6,'Stainless Steel 18% CR',0, 1, 2);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(7,'Tool Steel (cold rolled)',0, 1, 2);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(8,'Precious Metals',0, 10, 2);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(9,'Nickel Alloys',0, 2, 2);
	
INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (3, 'PLASTICS');	
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(10,'HDPE',0, 1, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(11,'PP',0, 1, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(12,'Nylons',0, 5, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(13,'PET',0, 2, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(14,'PVC bulk',0, 2, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(15,'PS HIPS',0, 1, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(16,'ABS',0, 1, 3);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(17,'Polyester (thermosetting)',0, 1, 3);
INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (4, 'GLASS');	
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(18,'Container Glass (53% cullet)',0, 1, 4);

INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (5, 'OTHER');	
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(19,'Ceramic (china clay)',0, 1, 5);
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(20,'Leather Veg Tanned',1, 3, 5);
INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (6, 'TEXTILES');	
	INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES(21,'cotton',1, 8, 6);
INSERT INTO SUPPLIER.gt_material_group (gt_material_group_id, description) VALUES (7, 'Pre-assembled');



INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (23,'Carbon Steel',0,1,2);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (24,'Natural Rubber',1,2,5);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (25,'Latex (synthetic)',0,2,5);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (26,'Electronic circuit boards etc',0,5,7);

INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (29,'Hardwood (oak etc)',1,1,1);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (30,'MDF',1,1,1);	
-- insert new materials
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (31,'Recycled',1,1,1);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (32,'Aluminium (over 20% recycled)',0,2,2);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (33,'Steel 100% Recycled',0,1,2);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (34,'Recycled Plastic (over 50% content)',0,1,3);
INSERT INTO SUPPLIER.gt_material (gt_material_id, description, natural, env_impact_score, gt_material_group_id) VALUES (35,'Small multi material components',0,5,7);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (39,'Viscose (cellophane / rayon)', 0, 1, 6, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (40,'Viscose (cellophane / rayon)', 0, 1, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (41,'Silicones', 0, 2, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (42,'Sponges (natural)', 1, 2, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (43,'Sponges (synthetic)', 0, 2, 3, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (44,'Natural Bristles / Hair', 1, 1, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (45,'Pumice Stone', 1, 2, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (46,'Shells', 1, 1, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (47,'Polyurethane (PU)', 1, 3, 3, 5);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (48,'EVA', 1, 1, 3, 2);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (39,'Viscose (cellophane / rayon)', 0, 1, 6, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (40,'Viscose (cellophane / rayon)', 0, 1, 5, 1);
INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (41,'Silicones', 0, 2, 5, 1);


INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (42,'Sponges (natural)', 1, 2, 5, 1);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (43,'Sponges (synthetic)', 0, 2, 3, 1);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (44,'Natural Bristles / Hair', 1, 1, 5, 1);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (45,'Pumice Stone', 1, 2, 5, 1);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (46,'Shells', 1, 1, 5, 1);

INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (47,'Polyurethane (PU)', 0, 3, 3, 5);


INSERT INTO SUPPLIER.GT_MATERIAL (GT_MATERIAL_ID, DESCRIPTION, NATURAL, ENV_IMPACT_SCORE, GT_MATERIAL_GROUP_ID, WATER_IMPACT_SCORE) VALUES (48,'EVA', 0, 1, 3, 2);

-- processing / manufac

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (1,'Construction (forming)',1,1,3);

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (2,'Casting',2,1,2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (3,'Deforming',1,1,3);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (4,'Complex assemblies (eg Electronics)',5,1,2);

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (5,'Moulding',5,1,2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (6,'Extrusion',2,1,2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (7,'Complex assemblies (eg Electronics)',5,1,2);

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (8,'Moulding',4,1,2);

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (9,'Rubber Moulding',4,1,2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (10,'Rubber Extrusion',1,1,2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (11,'Construction ceramics',1,2,2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (12,'Complex assemblies (eg Electronics)',5,1,2);

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES (13,'Weaving',3,3,2);

INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES  (14, 'Paper making', 1, 1, 2);
INSERT INTO SUPPLIER.gt_manufac_type (gt_manufac_type_id, description, energy_req_score, water_req_score, waste_score) VALUES  (15, 'Product Assembly (simple processes)', 5, 1, 1);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (17, 'Non-woven manufacture', 2, 1, 1);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (18, 'Bleaching (Chemical process)', 1, 2, 2);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (19, 'Agricultural production / fishing', 1, 2, 2);
INSERT INTO SUPPLIER.GT_MANUFAC_TYPE (GT_MANUFAC_TYPE_ID, DESCRIPTION, ENERGY_REQ_SCORE, WATER_REQ_SCORE, WASTE_SCORE) VALUES (20, 'Mining / quarrying', 2, 2, 3);




-- mapping between materials and manufac process
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (29, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (1, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (3, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (30, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (31, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (2, 1);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (32, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (7, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (6, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (8, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (9, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (5, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (4, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (23, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (33, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (32, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (33, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (9, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (4, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (8, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (7, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (6, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (5, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (23, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (8, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (7, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (6, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (5, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (4, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (9, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (33, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (32, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (23, 4);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (14, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (13, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (12, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (11, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (17, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (15, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (10, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (16, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (34, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (10, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (11, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (12, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (13, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (14, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (15, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (16, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (17, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (34, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (14, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (34, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (17, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (16, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (15, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (13, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (10, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (11, 7);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (12, 7);
--INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (22, 8);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (18, 8);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (19, 9);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (24, 9);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (25, 9);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (20, 9);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (19, 10);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (20, 10);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (25, 10);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (24, 10);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (25, 11);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (19, 11);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (24, 11);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (20, 11);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (19, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (25, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (24, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (20, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (21, 13);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (30, 14);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (29, 14);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (2, 14);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (31, 14);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (3, 14);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (1, 14);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (35, 15);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (26, 15);

INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (39, 17);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (40, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (41, 2);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (41, 3);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (41, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (42, 18);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (42, 19);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (43, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (44, 19);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (45, 20);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (46, 19);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (47, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (47, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (47, 6);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (48, 5);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (48, 12);
INSERT INTO SUPPLIER.gt_mat_man_mappiing (gt_material_id, gt_manufac_type_id) VALUES (48, 6);



	-- map haz chems to mats
	INSERT INTO SUPPLIER.gt_pda_hc_mat_map (gt_material_id, gt_pda_haz_chem_id)
	SELECT gt_material_id, gt_pda_haz_chem_id FROM SUPPLIER.gt_pda_haz_chem hc, gt_material m WHERE gt_material_id NOT IN (SELECT gt_material_id FROM gt_pda_hc_mat_map);

	-- map prov types to mats
	INSERT INTO SUPPLIER.gt_pda_mat_prov_mapping (gt_material_id, gt_pda_provenance_type_id) 
		SELECT gt_material_id, gt_pda_provenance_type_id 
		  FROM SUPPLIER.gt_material m, SUPPLIER.gt_pda_provenance_type pt 
		 WHERE m.natural = pt.natural
		   AND gt_material_id NOT IN (SELECT gt_material_id FROM SUPPLIER.gt_pda_mat_prov_mapping);
	   
	   
	-- set up battery type
	INSERT INTO SUPPLIER.gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, RECHARGABLE) VALUES (1, 'Primary Battery', -1, -1, 1, 0);
	INSERT INTO SUPPLIER.gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, RECHARGABLE) VALUES (2, 'Rechargeable Battery', 1, 1, 2, 1);
	INSERT INTO SUPPLIER.gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, RECHARGABLE) VALUES (3, 'Fixed Battery - primary', 5, 5, 1, 0);
	INSERT INTO SUPPLIER.gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, RECHARGABLE) VALUES (4, 'Fixed Battery - rechargeable', 4, 1, 2, 1);

	-- set up battery use
	INSERT INTO SUPPLIER.gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (1, 'Occasional use', 1);
	INSERT INTO SUPPLIER.gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (2, '<1 battery / month', 1);
	INSERT INTO SUPPLIER.gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (3, '2-5 batteries /month', 2);
	INSERT INTO SUPPLIER.gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (4, '5+ batteries / month', 3);
	
	---- insert battery chem data
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (1 ,'Ni-Cd' ,3 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (2 ,'Alkaline' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (3 ,'Li-Ion' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (4 ,'Li-Pol' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (5 ,'Lithium' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (6 ,'Ni-Mh' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (7 ,'Silver Oxide' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (8 ,'Zinc Carbon' ,1 );
	INSERT INTO SUPPLIER.GT_BATTERY_CHEM (GT_BATTERY_CHEM_ID, DESCRIPTION, ENV_SCORE) VALUES (9 ,'Zn-air' ,1 );
	
	---- insert battery base data
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (1 ,'LR03' ,2 ,11.04125 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (2 ,'LR14' ,2 ,68.075 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (3 ,'LR20' ,2 ,140.1597 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (4 ,'LR43' ,2 ,1.45 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (5 ,'LR44' ,2 ,3.355 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (6 ,'LR54' ,2 ,1.1 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (7 ,'LR55' ,2 ,0.9 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (8 ,'LR6' ,2 ,23.4325 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (9 ,'LR61' ,2 ,6.25 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (10 ,'LR9' ,2 ,4.5 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (11 ,'LR1' ,2 ,9.17 , 1.9,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (12 ,'3LR12' ,2 ,160 , 4.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (13 ,'4LR44' ,2 ,14 , 6,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (14 ,'6LR61' ,2 ,45.418 , 9,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (15 ,'MN21' ,2 ,7.4 , 12,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (16 ,'4LR61' ,2 ,30 , 6,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (17 ,'LR41' ,2 ,0.7 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (18 ,'LR48' ,2 ,0.92 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (19 ,'18500' ,3 ,35 , 3.6,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (20 ,'BP508' ,3 ,76 , 7.4,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (21 ,'ICR18650' ,3 ,44 , 3.7,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (22 ,'LP401230' ,4 ,2.5 , 3.7,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (23 ,'FR6' ,5 ,13.85 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (24 ,'CP3553' ,5 ,36.6 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (25 ,'CR1216' ,5 ,0.666667 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (26 ,'CR1220' ,5 ,0.926667 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (27 ,'CR123A' ,5 ,16.625 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (28 ,'CR1616' ,5 ,1.165 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (29 ,'CR1620' ,5 ,1.268 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (30 ,'CR17335' ,5 ,13.8365 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (31 ,'CR2' ,5 ,11.048 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (32 ,'CR2016' ,5 ,1.758 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (33 ,'CR2025' ,5 ,2.38 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (34 ,'CR2032' ,5 ,2.945 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (35 ,'CR2320' ,5 ,3 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (36 ,'CR2430' ,5 ,4.2225 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (37 ,'CR2450' ,5 ,6.375 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (38 ,'CRV3' ,5 ,36.95 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (39 ,'2CR5' ,5 ,38.86667 , 6,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (40 ,'CRP2' ,5 ,37.5 , 6,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (41 ,'CR1225' ,5 ,0.9 , 3,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (42 ,'INR18500' ,5 ,20 , 3.7,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (43 ,'L92' ,5 ,7.4 , 1.5,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (44 ,'PX 28L' ,5 ,9.4 , 6,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (45 ,'R6' ,1 ,22 , 1.5,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (46 ,'Sub C' ,1 ,47 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (47 ,'HR03' ,6 ,13 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (48 ,'HR14' ,6 ,67.98667 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (49 ,'HR20' ,6 ,76 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (50 ,'HR6' ,6 ,29.5 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (51 ,'HR6F22' ,6 ,43.36667 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (52 ,'1/2HR6' ,6 ,11 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (53 ,'1/3AA' ,6 ,8 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (54 ,'1/3AAA' ,6 ,21 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (55 ,'2/3A' ,6 ,20 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (56 ,'2/3AA' ,6 ,13 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (57 ,'4/5A' ,6 ,35 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (58 ,'4/5AA' ,6 ,22 , 1.2,1);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (59 ,'SR41' ,7 ,0.6725 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (60 ,'SR42' ,7 ,1.245 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (61 ,'SR43' ,7 ,1.726667 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (62 ,'SR44' ,7 ,2.3325 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (63 ,'SR45' ,7 ,1.055 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (64 ,'SR48' ,7 ,1.066667 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (65 ,'SR54' ,7 ,1.27 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (66 ,'SR55' ,7 ,0.9 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (67 ,'SR57' ,7 ,0.79 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (68 ,'SR58' ,7 ,0.416 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (69 ,'SR59' ,7 ,0.5225 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (70 ,'SR60' ,7 ,0.34 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (71 ,'SR62' ,7 ,0.18 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (72 ,'SR63' ,7 ,0.235 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (73 ,'SR64' ,7 ,0.285 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (74 ,'SR65' ,7 ,0.25 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (75 ,'SR66' ,7 ,0.397 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (76 ,'SR67' ,7 ,0.37 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (77 ,'SR68' ,7 ,0.516667 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (78 ,'SR69' ,7 ,0.636667 , 1.55,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (79 ,'6F22 ' ,8 ,36 , 9,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (80 ,'PR41' ,9 ,0.5025 , 1.4,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (81 ,'PR44' ,9 ,1.833333 , 1.4,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (82 ,'PR48' ,9 ,0.8 , 1.4,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (83 ,'PR63' ,9 ,0.19 , 1.4,0);
	INSERT INTO SUPPLIER.GT_BATTERY (GT_BATTERY_CODE_ID, GT_BATTERY_CODE, GT_BATTERY_CHEM_ID, AVERAGE_WEIGHT_G, VOLTAGE, RECHARCHABLE) VALUES	 (84 ,'PR70' ,9 ,0.3 , 1.4,0);
	
-- set up the mappings between battery and battery type - based on rechargable / not rechargeable for convenience atm but that is not a hard rule
INSERT INTO SUPPLIER.GT_BATTERY_BATTERY_TYPE (GT_BATTERY_CODE_ID, GT_BATTERY_TYPE_ID) 
    SELECT GT_BATTERY_CODE_ID, bt.GT_BATTERY_TYPE_ID FROM gt_battery_type bt, gt_battery b WHERE b.RECHARCHABLE = bt.RECHARGABLE;
END;
/
	
commit;
exit;