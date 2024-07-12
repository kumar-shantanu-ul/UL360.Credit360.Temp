-- Please update version.sql too -- this keeps clean builds in sync
define version=64
@update_header

set define off;

delete from gt_fa_palm_ind;
delete from gt_palm_ingred;
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (1,'Elaeis Guineensis (Palm Oil)', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (2,'Hydrogenated palm oil', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (3,'Hydrogenated palm glycerides', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (4,'isomerised palm oil', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (5,'Elaeis Guineensis (Palm kernel oil)', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (6,'Hydrogenated palm kernel oil', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (7,'Hydrogenated palm kernel glycerides', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (8,'Palm kernel wax', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (9,'Palm kernel glycerides', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (10,'Palm kernel acid', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (11,'Palm kernel alcohol', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (12,'Palm acid', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (13,'Palm glycerides', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (14,'Palm alcohol', 1);
insert into gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (15,'Hydrogenated palm acid', 1);


commit;

@update_tail
