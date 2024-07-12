-- Please update version.sql too -- this keeps clean builds in sync
define version=58
@update_header

set define off;

-- insert new types 
INSERT INTO gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (23, 'Bottle and Cap / Applicator', 23);
INSERT INTO gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (24, 'Tube / Pump', 24);
INSERT INTO gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (25, 'Bottle / Cap', 25);
INSERT INTO gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (26, 'Sachet', 26);
INSERT INTO gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (27, 'Pen Pack', 27);
INSERT INTO gt_access_pack_type (gt_access_pack_type_id, description, pos) VALUES (28, 'Flow Wrap', 28);

-- insert new mappings and scores
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (23, 1, 3);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (23, 2, 5);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (23, 3, 5);

INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (24, 1, 3);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (24, 2, 5);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (24, 3, 5);

INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (25, 1, 2);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (25, 2, 2);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (25, 3, 5);

INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (26, 1, 2);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (26, 2, 2);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (26, 3, 4);

INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (27, 1, 3);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (27, 2, 4);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (27, 3, 4);

INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (28, 1, 1);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (28, 2, 1);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (28, 3, 1);
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (28, 4, 1);




-- update descrptions
UPDATE gt_access_pack_type SET description = 'Pump pack	- No dip tube' WHERE gt_access_pack_type_id = 9;
UPDATE gt_access_pack_type SET description = 'Tube / cap' WHERE gt_access_pack_type_id = 12;
UPDATE gt_access_pack_type SET description = 'Blister / Blister Packs' WHERE gt_access_pack_type_id = 18;
UPDATE gt_access_pack_type SET description = 'Stick Pack - Lipsticks / Roll-ons' WHERE gt_access_pack_type_id = 22;

-- update score
INSERT INTO gt_access_pack_mapping (gt_access_pack_type_id, gt_access_visc_type_id, gt_access_score) VALUES (18, 3, 1);
UPDATE gt_access_pack_mapping SET gt_access_score=4 WHERE gt_access_pack_type_id = 11 AND gt_access_visc_type_id = 1;

-- delete access package options not used 

-- delete Spray pump	Incorrect diptube length 
UPDATE gt_packaging_answers SET gt_access_pack_type_id = 5 WHERE gt_access_pack_type_id = 6;
DELETE FROM gt_access_pack_mapping WHERE gt_access_pack_type_id = 6;
DELETE FROM gt_access_pack_type WHERE gt_access_pack_type_id = 6;

-- delete Dispensing Pump	Incorrect diptube length 
UPDATE gt_packaging_answers SET gt_access_pack_type_id = 7 WHERE gt_access_pack_type_id = 8;
DELETE FROM gt_access_pack_mapping WHERE gt_access_pack_type_id = 8;
DELETE FROM gt_access_pack_type WHERE gt_access_pack_type_id = 8;

-- delete Mascara 
UPDATE gt_packaging_answers SET gt_access_pack_type_id = 23 WHERE gt_access_pack_type_id = 21;
DELETE FROM gt_access_pack_mapping WHERE gt_access_pack_type_id = 21;
DELETE FROM gt_access_pack_type WHERE gt_access_pack_type_id = 21;



@update_tail