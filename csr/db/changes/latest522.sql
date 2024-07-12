-- Please update version.sql too -- this keeps clean builds in sync
define version=522
@update_header


ALTER TABLE axis ADD (
	LEFT_SIDE_LABEL	VARCHAR2(255),
	RIGHT_SIDE_LABEL VARCHAR2(255)
);


-- it's just frontenac ATM
UPDATE axis 
   SET left_side_label = 'Axis' 
 WHERE left_side_type = 1;

UPDATE axis 
   SET left_side_label = 'Projects' 
 WHERE left_side_type = 2;
 
UPDATE axis 
   SET left_side_label = 'Indicators' 
 WHERE left_side_type = 3;
 
UPDATE axis 
   SET right_side_label = 'Axis' 
 WHERE right_side_type = 1;

UPDATE axis 
   SET right_side_label = 'Projects' 
 WHERE right_side_type = 2;
 
UPDATE axis 
   SET right_side_label = 'Indicators' 
 WHERE right_side_type = 3;


ALTER TABLE axis MODIFY LEFT_SIDE_LABEL NOT NULL;
ALTER TABLE axis MODIFY RIGHT_SIDE_LABEL NOT NULL;

ALTER TABLE axis MODIFY LEFT_SIDE_TYPE  NULL;
ALTER TABLE axis MODIFY RIGHT_SIDE_TYPE  NULL;

ALTER TABLE AXIS DROP CONSTRAINT CS_RIGHT_SIDE;
ALTER TABLE AXIS DROP CONSTRAINT CS_LEFT_SIDE;

ALTER TABLE AXIS ADD CONSTRAINT CS_RIGHT_SIDE CHECK 
((RIGHT_SIDE_TYPE = 1 AND RIGHT_SIDE_AXIS_ID IS NOT NULL) OR (RIGHT_SIDE_TYPE IN (2,3) AND RIGHT_SIDE_AXIS_ID IS NULL))
DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE AXIS ADD CONSTRAINT CS_LEFT_SIDE CHECK 
((LEFT_SIDE_TYPE = 1 AND LEFT_SIDE_AXIS_ID IS NOT NULL) OR (LEFT_SIDE_TYPE IN (2,3) AND LEFT_SIDE_AXIS_ID IS NULL))
DEFERRABLE INITIALLY DEFERRED;


@..\strategy_pkg
@..\strategy_body

@update_tail


