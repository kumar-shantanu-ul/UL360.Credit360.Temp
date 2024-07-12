-- Please update version.sql too -- this keeps clean builds in sync
define version=1113
@update_header

INSERT INTO ct.distance_unit (distance_unit_id, description, symbol, conversion_to_km) VALUES (1, 'Kilometers', 'km', 1);
INSERT INTO ct.distance_unit (distance_unit_id, description, symbol, conversion_to_km) VALUES (2, 'Miles', 'miles', 1.609344);

ALTER TABLE ct.breakdown_group ADD IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE ct.breakdown_group ADD CONSTRAINT CC_BD_GROUP_IS_DEFAULT CHECK (IS_DEFAULT IN (1,0));

@..\ct\emp_commute_pkg
@..\ct\emp_commute_body

@update_tail
