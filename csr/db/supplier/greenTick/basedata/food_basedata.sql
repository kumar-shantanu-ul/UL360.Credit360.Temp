SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 

SET DEFINE OFF;


BEGIN

	BEGIN
		insert into supplier.gt_product_class (GT_PRODUCT_CLASS_ID, GT_PRODUCT_CLASS_NAME, GT_PRODUCT_CLASS_DESC) values (4, 'Food', 'A food product');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN  
			null; -- just in case clean is run multiple times
	END;
	
	BEGIN
		INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name, app_sid) values 
		(14	,'gtFood',		'GT Food',		'Food',		'gt_food_pkg', security_pkg.getApp);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN  
			null; -- just in case clean is run multiple times
	END;
	
	BEGIN
		insert into supplier.questionnaire_group_membership (QUESTIONNAIRE_ID, GROUP_ID, POS) values (14, 2, 14);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN  
			null; -- just in case clean is run multiple times
	END;

END;
/



BEGIN

	--insert new water use type "cooking" for food product types
	insert into gt_water_use_type (gt_water_use_type_id, description, water_capacity_ltr) values (6, 'Cooking', 2);

	insert into gt_ingred_accred_type (gt_ingred_accred_type_id, description, score, needs_note) values (6, 'Accredited source (priority)', 1, 0);
	insert into gt_ingred_accred_type (gt_ingred_accred_type_id, description, score, needs_note) values (2, 'Accredited source (other)', 2, 0);
	insert into gt_ingred_accred_type (gt_ingred_accred_type_id, description, score, needs_note) values (4, 'Known legal source', 4, 0);
	insert into gt_ingred_accred_type (gt_ingred_accred_type_id, description, score, needs_note) values (5, 'Unknown source', 5, 0);
	insert into gt_ingred_accred_type (gt_ingred_accred_type_id, description, score, needs_note) values (7, 'Not available for this ingredient type', 2, 0);

	insert into gt_fd_scheme (gt_fd_scheme_id, description, score) values (13, 'Red Tractor', 1);
	insert into gt_fd_scheme (gt_fd_scheme_id, description, score) values (14, 'Freedom food', 1);
	insert into gt_fd_scheme (gt_fd_scheme_id, description, score) values (15, 'Good Egg Awards', 1);

	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (10, 'Mixed Agricultural', 1, 2);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (11, 'Intensive farming', 1, 4);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (12, 'Palm oil', 1, 4);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (13, 'Processed Veg oils', 1, 4);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (14, 'Wild Harvested', 1, 3);

	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (15, 'Pole and Line', 1, 2);

	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (16, 'Nets', 1, 4);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (17, 'Long Line', 1, 3);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (18, 'Unknown', 1, 5);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (19, 'Mineral / synthetic', 0, 1);
	insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (20, 'Processed ingredient more than one step from starting material', 0, 3);


	insert into gt_fd_portion_type (gt_fd_portion_type_id, description, score) values (5, 'Single Serving', 1);
	insert into gt_fd_portion_type (gt_fd_portion_type_id, description, score) values (2, 'Multi pack', 2);
	insert into gt_fd_portion_type (gt_fd_portion_type_id, description, score) values (3, 'Bulk', 3);
	insert into gt_fd_portion_type (gt_fd_portion_type_id, description, score) values (4, 'BOGOF / 3 for 2', 4);


	--new food data

	--new product type groups....

	insert into gt_product_type_group (gt_product_type_group_id, description) values (13, 'Sandwiches / Wraps');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (14, 'Drinks');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (15, 'Desserts');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (16, 'Crisps');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (17, 'Confectionery');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (18, 'Biscuits');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (19, 'Snacks');
	insert into gt_product_type_group (gt_product_type_group_id, description) values (20, 'Salads');


	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 242, 13, 'Sandwiches / Wraps', 3, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 243, 20, 'Salads', 3, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 244, 14, 'Juice / Smoothie', 5, 1, 1, 5, 3, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 245, 14, 'Shapers (500ml) still and sparkling', 3, 1, 1, 5, 3, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 246, 19, 'Sushi', 5, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 247, 15, 'Fruit Salad', 3, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 248, 19, 'Snacks - Chilled', 3, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 249, 19, 'Pasta snacks', 3, 1, 1, 5, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 250, 19, 'Carrot snacks', 1, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 251, 15, 'Yogurts', 1, 1, 1, 3, 2, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 252, 14, 'Bottled water', 1, 1, 1, 3, 3, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 253, 16, 'Crisps', 1, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 254, 17, 'Confectionery  Bars', 1, 1, 1, 5, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 255, 17, 'Diabetic Chocolate', 1, 1, 1, 5, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 256, 17, 'Belgian chocolates', 1, 1, 1, 5, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 257, 17, 'Maltitol bar', 3, 1, 1, 5, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 258, 18, 'Shortbread', 1, 1, 1, 1, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 259, 18, 'Cookies', 1, 1, 1, 1, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'g', 0, 0, 0, 260, 19, 'Sugar free summer fruit', 3, 1, 1, 3, 4, 1, 1);
	insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score, av_water_content_pct) values (4, 'ml', 0, 0, 0, 261, 14, 'Flavoured waters', 1, 4, 1, 3, 3, 1, 1);

	-- associated tag groups...

	insert into tag (tag, explanation, tag_id) values ('(Fd) Sandwiches / Wraps', '(Fd) Sandwiches / Wraps', 3339);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Salads', '(Fd) Salads', 3340);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Juice / Smoothie', '(Fd) Juice / Smoothie', 3341);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Shapers (500ml) still and sparkling', '(Fd) Shapers (500ml) still and sparkling', 3342);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Sushi', '(Fd) Sushi', 3343);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Fruit Salad', '(Fd) Fruit Salad', 3344);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Snacks - Chilled', '(Fd) Snacks - Chilled', 3345);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Pasta snacks', '(Fd) Pasta snacks', 3346);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Carrot snacks', '(Fd) Carrot snacks', 3347);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Yogurts', '(Fd) Yogurts', 3348);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Bottled water', '(Fd) Bottled water', 3349);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Crisps', '(Fd) Crisps', 3350);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Confectionery  Bars', '(Fd) Confectionery  Bars', 3351);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Diabetic Chocolate', '(Fd) Diabetic Chocolate', 3352);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Belgian chocolates', '(Fd) Belgian chocolates', 3353);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Maltitol bar', '(Fd) Maltitol bar', 3354);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Shortbread', '(Fd) Shortbread', 3355);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Cookies', '(Fd) Cookies', 3356);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Sugar free summer fruit', '(Fd) Sugar free summer fruit', 3357);
	insert into tag (tag, explanation, tag_id) values ('(Fd) Flavoured waters', '(Fd) Flavoured waters', 3358);

	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (242, 3339);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (243, 3340);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (244, 3341);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (245, 3342);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (246, 3343);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (247, 3344);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (248, 3345);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (249, 3346);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (250, 3347);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (251, 3348);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (252, 3349);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (253, 3350);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (254, 3351);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (255, 3352);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (256, 3353);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (257, 3354);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (258, 3355);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (259, 3356);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (260, 3357);
	insert into gt_tag_product_type (gt_product_type_id, tag_id) values (261, 3358);

	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3339, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3340, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3341, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3342, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3343, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3344, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3345, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3346, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3347, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3348, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3349, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3350, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3351, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3352, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3353, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3354, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3355, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3356, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3357, 2);  
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3358, 2); 

	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3339, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3340, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3341, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3342, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3343, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3344, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3345, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3346, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3347, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3348, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3349, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3350, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3351, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3352, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3353, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3354, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3355, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3356, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3357, 6);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3358, 6);  

	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3339, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3340, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3341, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3342, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3343, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3344, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3345, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3346, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3347, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3348, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3349, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3350, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3351, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3352, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3353, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3354, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3355, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3356, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3357, 7);
	insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3358, 7);  

	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 8, 1);

	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 9, 1);
								  
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 11, 1);

	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 12, 1);
								  
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 14, 1);
								  
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 10, 0);
								  
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3339, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3340, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3341, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3342, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3343, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3344, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3345, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3346, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3347, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3348, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3349, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3350, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3351, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3352, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3353, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3354, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3355, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3356, 13, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3357, 13, 0);

	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 8, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 9, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 11, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 12, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 14, 1);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 10, 0);
	insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 13, 0);

	--ingredient groups

	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Additives', 3);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Bread', 4);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Chocolate', 5);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Dairy', 6);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Egg', 7);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Fish', 8);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Fruit and Vegetables', 9);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Honey', 10);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Meat', 11);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Oils and Dressings', 12);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Poultry', 13);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Pulses', 14);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Salt', 15);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Sugar', 16);
	insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Water', 17);

	-- new fd_schemes...

	insert into gt_fd_scheme (gt_fd_scheme_id, description, score) values (16, 'Sustainably sourced fish - MSC (Marine Stewardship Council) certified', 1);
	insert into gt_fd_scheme (gt_fd_scheme_id, description, score) values (17, 'Organic Farmers and Growers, Soil Association', 1);
	insert into gt_fd_scheme (gt_fd_scheme_id, description, score) values (18, 'Other higher welfare standards', 1);

	-- ingredient types -- need to add the new column on live
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 3, 'Artificial Sweetners', 1, 1, 2, 1);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 4, 'Natural Flavours', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 5, 'Natural Colours', 1, 1, 2, 1);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 6, 'Artificial Preservatives', 1, 1, 2, 1);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 7, 'Emulsifiers', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 8, 'Stabilisers', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 9, 'Acidity Regulators', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (3, 10, 'Bulking Agents', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (4, 11, 'Breads', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (5, 12, 'Chocolate', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (6, 13, 'Milk', 1, 1, 3, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (6, 14, 'Cheese', 1, 1, 3, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (6, 15, 'Yoghurt', 1, 1, 3, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (6, 16, 'Butter', 1, 1, 3, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (7, 17, 'Egg', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 18, 'Shellfish', 1, 2, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 19, 'Salmon', 1, 2, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 20, 'Tuna - Pole and Line', 1, 2, 1, 2);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 21, 'Lettuce / Leaf', 2, 3, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 22, 'Vegetables', 2, 3, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 23, 'Fresh Fruit', 2, 3, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 24, 'Fruit Puree and Juices', 2, 2, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 25, 'Dried Fruit', 2, 2, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 26, 'Herbs', 1, 2, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (9, 27, 'Nuts', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (10, 28, 'Honey', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (11, 29, 'Beef', 4, 1, 3, 1);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (11, 30, 'Pork', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (12, 31, 'Vegetable Oil', 1, 1, 3, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (12, 32, 'Mayonnaise / Dressing', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (12, 33, 'Soy Sauce', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (12, 34, 'Vinegars', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (13, 35, 'Chicken', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (13, 36, 'Duck', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (13, 37, 'Turkey', 1, 1, 2, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (14, 38, 'Pasta', 2, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (14, 39, 'Rice', 2, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (14, 40, 'Cereals', 2, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (15, 41, 'Salt', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (16, 42, 'Sugar', 1, 1, 1, 0);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (17, 43, 'Water (Still / sparkling)', 1, 1, 1, 1);


	update gt_fd_ingred_type set default_gt_sa_score = default_gt_sa_score + 1;

	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 44, 'Tuna - Net Caught', 1, 2, 1, 3);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 45, 'Tuna - Long Line', 1, 2, 1, 3);

	-- endangered/high risk species

	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 41, 'Cod (Atlantic Source)', 3);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 42, 'Eel (European and Conger)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 43, 'Haddock (Scottish)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 44, 'Hake (Spain and Portugal)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 45, 'Halibut (Wild caught, Atlantic)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 46, 'Herring (Ireland)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 47, 'Ling (trawled fish)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 48, 'Lobster (New England USA)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 49, 'Plaice (West coast of Britain)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 50, 'Prawns - Tiger and King Prawn,(Wild Caught)', 3);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 51, 'Ray (ALL Sources)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 52, 'Salmon (Atlantic, wild caught)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 53, 'Scampi (Spain and Portugal)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 54, 'Seabass (trawled)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 55, 'Shark (ALL Sources)', 3);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 56, 'Skate (ALL Sources)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 57, 'Sole (Irish)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 58, 'Swordfish (ALL Sources)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 59, 'Trout - Brown or Sea (Baltic sea)', 2);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 60, 'Tuna - Albacore (Net Caught)', 3);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 61, 'Tuna - Big Eye (ALL Sources)', 3);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('H', 62, 'Tuna - Bluefin (ALL Sources)', 5);
	insert into gt_endangered_species (risk_level, gt_endangered_species_id, description, risk_score) values ('M', 63, 'Turbot (Trawled fish)', 2);

	-- and map them to the food class
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 41);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 42);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 43);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 44);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 45);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 46);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 47);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 48);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 49);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 50);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 51);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 52);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 53);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 54);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 55);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 56);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 57);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 58);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 59);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 60);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 61);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 62);
	insert into gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) values (4, 63);

	-- remember to delete the existing ones for food from the table - ie delete from gt_endangered_prod_class_map where gt_product_class_id = 4


	--ancillar materials...
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Spoon / Fork / Knife (disposable)', 2, 16, 16);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Plates / cups (disposable)', 2, 17, 17);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Cutlery / Crockery (Reusable)', 1, 18, 18);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Napkins / Tissues', 2, 19, 19);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Bags - Single Use (eg Meal deal)', 2, 20, 20);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Bags - Reusable', 1, 21, 21);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Milk', 2, 22, 22);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Water', 1, 23, 23);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('Condiments', 2, 24, 24);
	insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('No additional materials', 1, 25, 25);

	--palm ingredients

	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Elaeis Guineensis (Palm Oil)', 1, 16);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Hydrogenated palm oil', 1, 17);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Hydrogenated palm glycerides', 1, 18);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('isomerised palm oil', 1, 19);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Elaeis Guineensis (Palm kernel oil)', 1, 20);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Hydrogenated palm kernel oil', 1, 21);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Hydrogenated palm kernel glycerides', 1, 22);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm kernel wax', 1, 23);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm kernel glycerides', 1, 24);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm kernel acid', 1, 25);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm kernel alcohol', 1, 26);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm acid', 1, 27);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm glycerides', 1, 28);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Palm alcohol', 1, 29);
	insert into gt_palm_ingred (description, palm_confirmed, gt_palm_ingred_id) values ('Hydrogenated palm acid', 1, 30);

	--new social amplification issues (thats not questions - the groupings of question

	insert into gt_sa_issue (gt_sa_issue_id, description) values (1, 'Ingredients');
	insert into gt_sa_issue (gt_sa_issue_id, description) values (2, 'Nutrition and Health');
	insert into gt_sa_issue (gt_sa_issue_id, description) values (3, 'Marketing');

	--new social amplification questions....
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (1,'Ingredients Risk', 'Are these ingredients used in the product?', 1, 1, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (2,'Artificial colours or flavours', 'Does the product contain artificial colours or flavours?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (3,'Flavour enhancers - monosodium glutamate', 'Does the product contain Flavour enhancers - monosodium glutamate?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (4,'Sodium benzoate (preservative)', 'Does the product contain Sodium benzoate (preservative)?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (5,'Aspartame (artificial sweetener)', 'Does the product contain Aspartame (artificial sweetener)?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (6,'Hydrolysed vegetable / plant protein', 'Does the product contain Hydrolysed vegetable / plant protein?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (7,'Hydrogenated / partially hydrogenated vegetable oils', 'Are any ingredients hudrogenated or partially hydrogenated?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (8,'Minimise the use of trans fatty acids to 2% of fats used', 'Are trans fatty acid levels above 2%?', 1, 0, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (9,'Irradiated ingredients', 'Are any ingredients from irradiated sources?', 1, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (10,'GM Ingredients or GM Derived Ingredients', 'Are any ingredients from GM sources?', 1, 3, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (11,'Pesticide Residue Free', 'Are these ingredients declared pesticide residue free?', 1, 0, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (12,'Materials from accredited sources (eg Sustainable palm oil, cocoa, coffee etc)', 'Are the ingredients used from an accredited source?', 1, 0, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (13,'Product contains palm oil (as declared ingredient) not certified Sustainable', 'Does the product contain palm oil as an ingredient?', 1, 1, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (14,'Fat ', 'Does the product display a Red traffic light for Fat content?', 2, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (15,'Saturated fat ', 'Does the product display a Red traffic light for Saturated Fat content?', 2, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (16,'Salt ', 'Does the product display a Red traffic light for Salt content?', 2, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (17,'FSA 2012 salt reduction target ', 'Does the product Meet FSA salt reduction target?', 2, 3, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (18,'Sugars ', 'Does the product display a Red traffic light for Sugar content?', 2, 2, '');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (19,'Advertised to appeal to children', 'Is the product advertised as appealing to children?', 3, 3, 'Sweets / confectionary not developed for under 3s. Salty foods aimed under 3s');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (20,'Children''s confectionery product displayed by the till ', 'Is this childrens confectionery product displayed by till points?', 3, 2, 'Sweets displayed by till seen as persuasive to children');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (21,'Confectionery product displayed by the till', 'Is this confectionery product displayed by till points?', 3, 1, 'Adult confectionery displayed by till seen as persuasive to children');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (22,'Alcoholic product ', 'Does this product contain alcahol?', 3, 1, 'Issues of alcahol abuse');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (23,'Front of pack labelling -', 'Does the product carry traffic light and / or % GDA (Guideline Daily Amount) on front of pack?', 3, 0, 'Front of pack labelling is a positive in terms of consumer information.');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (24,'Calorie value listed on front of pack', 'Is the calorie value listed on front of pack?', 3, 0, 'Front of pack labelling is a positive in terms of consumer information.');
	insert into gt_sa_question (gt_sa_question_id, question_name, default_question_text, gt_sa_issue_id, default_gt_sa_score, help_text) values (25,'Product Encourages a healthy lifestyle (include information / advice)', 'Are the positive health benefits of the product described?', 3, 0, 'Positive health benefits should be promoted');
	insert into gt_sa_q_prod_type (gt_sa_question_id, gt_product_type_id) select gt_sa_question_id, 261 from gt_sa_question;



	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (16, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (17, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (18, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (19, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (20, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (21, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (22, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (23, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (24, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (15, 4);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (25, 4);

	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (1 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (2 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (3 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (4 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (5 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (6 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (7 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (8 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (9 , 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (10, 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (12, 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (13, 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (14, 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (15, 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (20, 2);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (21, 2);

	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (1 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (2 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (3 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (4 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (5 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (6 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (7 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (8 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (9 , 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (10, 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (12, 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (13, 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (14, 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (15, 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (20, 1);
	insert into gt_anc_mat_prod_class_map (gt_ancillary_material_id, gt_product_class_id) values (21, 1);
END;
/

commit;
exit;