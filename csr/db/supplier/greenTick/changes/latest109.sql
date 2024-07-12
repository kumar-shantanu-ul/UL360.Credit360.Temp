-- Please update version.sql too -- this keeps clean builds in sync
define version=109
@update_header 

	update gt_fd_ingred_type set description = 'Tuna - Pole and Line', default_gt_sa_score = 1 where gt_fd_ingred_type_id = 20;

	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 44, 'Tuna - Net Caught', 1, 2, 1, 3);
	insert into gt_fd_ingred_type (gt_fd_ingred_group_id, gt_fd_ingred_type_id, description, water_impact_score, pesticide_score, env_impact_score, default_gt_sa_score) values (8, 45, 'Tuna - Long Line', 1, 2, 1, 3);

@update_tail