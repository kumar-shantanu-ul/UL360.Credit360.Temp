-- Please update version.sql too -- this keeps clean builds in sync
define version=59
@update_header

set define off;

-- update existing materials
--"Bio / compostible" -> "Bio - Plastics"
UPDATE gt_pack_material_type SET description = 'Bio - Plastics' WHERE gt_pack_material_type_id = 2;
--Degradable -> Oxydegradeable plastic
UPDATE gt_pack_material_type SET description = 'Oxydegradeable plastic' WHERE gt_pack_material_type_id = 5;

-- insert new pack shape option for mixed materials laminates
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (4, 10, 0, 1, 0, 0);

-- Update all items with mixed materials to mixed materials - laminates
UPDATE gt_pack_item SET gt_pack_material_type_id = 10 WHERE gt_pack_material_type_id = 9;

-- Update "Mixed Materials (laminates) -> "Mixed Materials"
UPDATE gt_pack_material_type SET description = 'Mixed Materials' WHERE gt_pack_material_type_id = 10;
UPDATE gt_pack_material_type SET description = 'Mixed Materials - OLD' WHERE gt_pack_material_type_id = 9;

-- Delete  "Mixed Materials - OLD"
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 9;
DELETE FROM gt_pack_material_type WHERE gt_pack_material_type_id = 9;


--- UPDATE existing mapping properties for bio - plactics
UPDATE GT_SHAPE_MATERIAL_MAPPING
SET   
       RECYCLABLE               = 0,
       RECOVERABLE              = 1,
       RENEWABLE                = 1,
       BIOPOLYMER               = 1
WHERE gt_pack_material_type_id = 2;


-- insert new pack shape types - and the allowed mappings
INSERT INTO gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (18, 'Pump', 18);
INSERT INTO gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (19, 'Overcap', 19);
INSERT INTO gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (20, 'Godet', 20);
INSERT INTO gt_pack_shape_type (gt_pack_shape_type_id, description, pos) VALUES (21, 'Pump Pack (no dip tube)', 21);


INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (18, 10, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 1, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 20, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 14, 1, 1, 1, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 21, 1, 1, 1, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 22, 1, 1, 1, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 16, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 7, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 8, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 17, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 18, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 19, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 13, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 2, 0, 1, 1, 1);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (19, 10, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 20, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 1, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 18, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 16, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 13, 0, 1, 0, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 14, 1, 1, 1, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 21, 1, 1, 1, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (20, 22, 1, 1, 1, 0);
INSERT INTO gt_shape_material_mapping (gt_pack_shape_type_id, gt_pack_material_type_id, recyclable, recoverable, renewable, biopolymer) VALUES (21, 10, 0, 1, 0, 0);

-- remove invalid oxydegradable options
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 1;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 2;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 3;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 4;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 5;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 7;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 9;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 11;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 13;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 14;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 15;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 16;
DELETE FROM gt_shape_material_mapping WHERE gt_pack_material_type_id = 5 AND gt_pack_shape_type_id = 17;

-- update 1 shape type
UPDATE gt_pack_shape_type SET description = 'Bottle / Tottle / Jar' WHERE gt_pack_shape_type_id = 5;

-- update mapping scores
UPDATE supplier.gt_shape_material_mapping
SET    recyclable               = 0,
       recoverable              = 0,
       renewable                = 0,
       biopolymer               = 0
WHERE  gt_pack_shape_type_id    = 8
AND    gt_pack_material_type_id = 5;


UPDATE supplier.gt_shape_material_mapping
SET    recyclable               = 0,
       recoverable              = 0,
       renewable                = 0,
       biopolymer               = 0
WHERE  gt_pack_shape_type_id    = 10
AND    gt_pack_material_type_id = 5;

UPDATE supplier.gt_shape_material_mapping
SET    recyclable               = 0,
       recoverable              = 0,
       renewable                = 0,
       biopolymer               = 0
WHERE  gt_pack_shape_type_id    = 12
AND    gt_pack_material_type_id = 5;

@update_tail