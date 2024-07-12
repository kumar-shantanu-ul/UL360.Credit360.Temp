SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 


SET DEFINE OFF;

BEGIN
	INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name) values 
	(8	,'gtProductInfo',	'Product Info',		'Product Info',		'product_info_pkg');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN  
		null; -- just in case clean is run multiple times
END;
/

-- WATER_USE_TYPE 
--PROMPT WATER_USE_TYPE 
BEGIN
	INSERT INTO SUPPLIER.gt_water_use_type (gt_water_use_type_id, description, water_capacity_ltr) VALUES (1, 'Shower', 15);
	INSERT INTO SUPPLIER.gt_water_use_type (gt_water_use_type_id, description, water_capacity_ltr) VALUES (2, 'Bath', 68);
	INSERT INTO SUPPLIER.gt_water_use_type (gt_water_use_type_id, description, water_capacity_ltr) VALUES (3, 'Sink (rinse)', 5);
	INSERT INTO SUPPLIER.gt_water_use_type (gt_water_use_type_id, description, water_capacity_ltr) VALUES (4, 'None', 0);
	INSERT INTO SUPPLIER.gt_water_use_type (gt_water_use_type_id, description, water_capacity_ltr) VALUES (5, 'Sink', 5);
END;
/

-- GT_PRODUCT_TYPE_GROUP
--PROMPT GT_PRODUCT_TYPE_GROUP
BEGIN
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (1,'Washing & Bathing');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (2,'Mens');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (3,'Hand & Body');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (4,'Skin');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (5,'Hair');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (6,'Cosmetics');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (7,'Suncare');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (8,'Other (Accessories)');
	INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (9,'Dental');
	--INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (10,'Manufactured (other)');
	--INSERT INTO SUPPLIER.gt_product_type_group (gt_product_type_group_id, description) VALUES (11,'Parent pack');
END;
/
-- GT_PRODUCT_CLASS
BEGIN
	INSERT INTO SUPPLIER.GT_PRODUCT_CLASS (GT_PRODUCT_CLASS_ID, GT_PRODUCT_CLASS_NAME, GT_PRODUCT_CLASS_DESC) VALUES (1, 'Formulated', 'Formulated');
	INSERT INTO SUPPLIER.GT_PRODUCT_CLASS (GT_PRODUCT_CLASS_ID, GT_PRODUCT_CLASS_NAME, GT_PRODUCT_CLASS_DESC) VALUES (2, 'Manufactured', 'Manufactured');
	INSERT INTO SUPPLIER.GT_PRODUCT_CLASS (GT_PRODUCT_CLASS_ID, GT_PRODUCT_CLASS_NAME, GT_PRODUCT_CLASS_DESC) VALUES (3, 'Gift Packaging', 'Gift Packaging');
END;
/
-- gt_access_visc_type
BEGIN
	INSERT INTO SUPPLIER.gt_access_visc_type (gt_access_visc_type_id, description, pos) VALUES (1 , 'Low', 1);
	INSERT INTO SUPPLIER.gt_access_visc_type (gt_access_visc_type_id, description, pos) VALUES (2 , 'Medium', 2);
	INSERT INTO SUPPLIER.gt_access_visc_type (gt_access_visc_type_id, description, pos) VALUES (3 , 'High', 3);
	INSERT INTO SUPPLIER.gt_access_visc_type (gt_access_visc_type_id, description, pos) VALUES (4 , 'Solid', 4);
END;
/
-- GT_PRODUCT_TYPE
--PROMPT GT_PRODUCT_TYPE
BEGIN
    --(1,'Washing & Bathing');	
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,1,'Shower Gel / Cream',75,1,20,2,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,2,'Hair & Body wash',75,1,20,2,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,3,'Bath Foam /soak',75,2,20,2,4,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,4,'Bubble bath',75,2,20,2,4,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,5,'Hand Wash',75,3,20,4,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,6,'Bath Oil',0,2,20,2,4,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,7,'Bath Salts',0,2,20,2,4,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,8,'Detergent Body Scrub',62.5,1,20,2,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,9,'Emulsion Body Scrub',80,1,20,4,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,10,'Salt / Sugar Scrub',0,1,20,4,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,11,'Soap (Bar)',0,2,20,0,4,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (1,12,'Talc',0,4,10,2,0,1);
    --(2,'Mens');	                                                                                                                                                                            
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (2,13,'Pre shave',0,4,10,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (2,14,'Mens aftershave lotion / balm',75,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (2,15,'Shave gel',75,4,20,4,0,1);
                                                                                                                                                                                           
    --(3,'Hand & Body');	                                                                                                                                                                    
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (3,16,'Hand Cream',77.5,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (3,17,'Hand Cream SPF',65,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (3,18,'Body Cream',70,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (3,19,'Body Lotion',80,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (3,20,'Body / massage oil',0,4,20,2,0,1);
    --(4,'Skin');	                                                                                                                                                                            
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,21,'Cleanser',75,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,22,'Toner',87.5,4,20,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,23,'Day Cream',62.5,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,24,'Night Cream',75,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,25,'Serum - W/S',32.5,4,10,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,26,'Serum - O/W',82.5,4,10,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,27,'Exfoliator (Detergent)',77.5,4,10,2,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,28,'Exfoliator (Emulsion)',77.5,4,10,4,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,29,'Facial Wash (Detergent)',75,4,20,3,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,30,'Facial Wash (Emulsion)',77.5,4,20,4,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,31,'Moisturiser',75,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,32,'Eye Cream',77.5,4,5,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,33,'Wipes',7.5,4,2,1,0,1); -- water mnfct score a guess
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,34,'Lip Salve (Oily)',0,4,2,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (4,35,'Lip Cream',60,4,2,3,0,1);
    --(5,'Hair');	                                                                                                                                                                            
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,36,'Shampoo',75,1,20,2,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,37,'Conditioner (including Intensive)',88,1,20,4,3,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,38,'Conditioner (Leave In)',96.5,4,20,4,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,39,'Serum (Silicone)',0,4,10,2,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,40,'Heat Spray',50,4,5,2,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,41,'Styling Spray',0,4,10,2,2,1); -- water content a guess
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,42,'Hair Spray (non aerosol)',27.5,4,10,2,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,43,'Wax',0,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,44,'Gel',94,4,20,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,45,'Clay',0,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,46,'Ringing Gel',30,4,10,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,47,'Shine Spray (Si / ETOH)',0,4,10,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,48,'Straightening / curling balm',96.5,4,20,4,2,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,49,'Curl cream',88.5,4,10,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,50,'Waterproof Gellee',21,4,10,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (5,51,'Putty',47.5,4,5,4,0,1);
    --(6,'Cosmetics');	                                                                                                                                                                        
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,52,'Nail Polish',0,4,2,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,53,'Lipsticks',0,4,2,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,54,'Foundation W/S',35,4,2,3,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,55,'Foundation O/W',60,4,2,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,56,'Eyeshadow',0,4,2,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,57,'EMUR pads',0,4,2,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,58,'EMUR Lotion',62.5,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,59,'EMUR Gel',82.5,4,20,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,60,'Antiaging Cream',65,4,20,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,61,'Mascara - Waterproof',0,4,2,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,62,'Mascara - Emulsion',50,4,2,4,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (6,63,'Mascara - Gel',95,4,2,4,0,1);
    --(7,'Suncare');	                                                                                                                                                                        
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (7,64,'Sun Spray',60,4,2,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (7,65,'Aftersun gel',72.5,4,2,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (7,66,'Aftersun spray',67.5,4,2,2,0,1);
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (7,67,'Aftersun lotion',82.5,4,2,4,0,1);
                                                                                                                                                                                                
    --(8,'Other (Accessories)');	                                                                                                                                                            
    INSERT INTO SUPPLIER.gt_product_type (gt_product_type_group_id, gt_product_type_id, description, av_water_content_pct, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, use_energy_score, gt_product_class_id) 	VALUES (8,68,'sponges',0,3,20,2,0,3);

END;
/

-- GT_PRODUCT_RANGE
--PROMPT GT_PRODUCT_RANGE
BEGIN
	-- TBC
	INSERT INTO SUPPLIER.gt_product_range (gt_product_range_id, description) values (1, 'Botanics');
	INSERT INTO SUPPLIER.gt_product_range (gt_product_range_id, description) values (2, 'Organics');
END;
/
commit;
exit;

