define version=103
@update_header

insert into gt_ingred_accred_type (gt_ingred_accred_type_id, description, score, needs_note) values (7, 'Not available for this ingredient type', 2, 0);
insert into gt_fd_ingred_prov_type (gt_fd_ingred_prov_type_id, description, natural, score) values (20, 'Processed ingredient more than one step from starting material', 0, 3);
insert into gt_product_type (gt_product_class_id, unit, mains_powered, hrs_used_per_month, mnfct_water_score, gt_product_type_id, gt_product_type_group_id, description, water_in_prod_pd, gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_access_visc_type_id, use_energy_score) values (4, 'ml', 0, 0, 0, 261, 14, 'Flavoured waters', 1, 4, 1, 3, 3, 1);
insert into tag (tag, explanation, tag_id) values ('(Fd) Flavoured waters', '(Fd) Flavoured waters', 3358);
insert into gt_tag_product_type (gt_product_type_id, tag_id) values (261, 3358);
insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3358, 2);  
insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3358, 6);  
insert into tag_tag_attribute (tag_id, tag_attribute_id) values (3358, 7);  

insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 8, 1);
insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 9, 1);
insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 11, 1);
insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 12, 1);
insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 14, 1);
insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 10, 0);
insert into questionnaire_tag (tag_id, questionnaire_id, mapped) values (3358, 13, 0);
insert into tag_group_filter values (3358, 4);
insert into tag_group_member (tag_group_sid, tag_id, pos, is_visible) values (6655229, 3358, 3286, 1);
insert into gt_fd_ingred_group (description, gt_fd_ingred_group_id) values ('Water', 17);
insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (17, 43, 'Water (Still / sparkling)', 1, 1, 1, 1);
update gt_fd_scheme set description = 'Other recognised welfare standards' where gt_fd_scheme_id = 18;	
update gt_fd_scheme set description = 'Freedom Food (RSPCA)' where gt_fd_scheme_id = 14;
update gt_fd_scheme set description = 'Red Tractor (Assured Food Standards)' where gt_fd_scheme_id = 13;

insert into gt_ancillary_material (description, gt_score, pos, gt_ancillary_material_id) values ('No additional materials', 1, 25, 25);

insert into gt_sa_q_prod_type (gt_sa_question_id, gt_product_type_id) select gt_sa_question_id, 261 from gt_sa_question;

@update_tail
