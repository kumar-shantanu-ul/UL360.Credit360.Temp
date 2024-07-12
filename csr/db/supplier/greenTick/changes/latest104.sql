define version=104
@update_header

create table gt_anc_mat_prod_class_map (gt_ancillary_material_id number(10), gt_product_class_id number(10));
alter table gt_anc_mat_prod_class_map add constraint fk_ampcmam foreign key (gt_ancillary_material_id) references gt_ancillary_material(gt_ancillary_material_id);
alter table gt_anc_mat_prod_class_map add constraint fk_ampcmpc foreign key (gt_product_class_id) references gt_product_class(gt_product_class_id);

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


@update_tail
