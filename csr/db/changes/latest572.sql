-- Please update version.sql too -- this keeps clean builds in sync
define version=572
@update_header


ALTER TABLE REGION_TREE ADD (
    IS_DIVISIONS            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_DIVISIONS IN (0,1))
);

UPDATE region_tree
   SET is_divisions = 1
 WHERE region_tree_root_sid in (
	SELECT region_sid
	  FROM region
	 WHERE region_type = 2 -- csr_data_pkg.REGION_TYPE_ROOT
	   AND description = 'Divisions' 
 );

@@..\division_pkg
@@..\division_body



@update_tail
