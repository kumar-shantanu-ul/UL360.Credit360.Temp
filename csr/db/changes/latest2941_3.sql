-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE OR REPLACE FUNCTION get_constraintname_text(
	p_cons_name IN VARCHAR2 
)RETURN VARCHAR2
AUTHID CURRENT_USER	IS
l_search_condition		all_constraints.search_condition%TYPE;
BEGIN
	SELECT search_condition INTO l_search_condition
	  FROM all_constraints
	 WHERE constraint_name = p_cons_name;

	RETURN l_search_condition;
END;
/

BEGIN
FOR R IN (
  SELECT constraint_name, table_name, owner 
    FROM (
	  SELECT constraint_name, table_name, get_constraintname_text(constraint_name), owner
		FROM all_constraints
	   WHERE table_name LIKE UPPER('METERING_OPTIONS')
		 AND owner LIKE UPPER('CSR')
		 AND constraint_name like 'SYS_%'
		 AND (get_constraintname_text(constraint_name) like 'ANALYTICS_CURRENT_MONTH IN(0,1)')
  )
)
LOOP
  EXECUTE IMMEDIATE ('ALTER TABLE CSR.METERING_OPTIONS DROP CONSTRAINT ' || r.constraint_name);
END LOOP;

FOR R IN (
  SELECT constraint_name, table_name, owner 
    FROM (
	  SELECT constraint_name, table_name, get_constraintname_text(constraint_name), owner
		FROM all_constraints
	   WHERE table_name LIKE UPPER('METERING_OPTIONS')
		 AND owner LIKE UPPER('CSRIMP')
		 AND constraint_name like 'SYS_%'
		 AND (get_constraintname_text(constraint_name) like 'ANALYTICS_CURRENT_MONTH IN(0,1)')
  )
)
LOOP
  EXECUTE IMMEDIATE ('ALTER TABLE CSRIMP.METERING_OPTIONS DROP CONSTRAINT ' || r.constraint_name);
END LOOP;

END;
/

ALTER TABLE CSR.METERING_OPTIONS ADD CONSTRAINT CK_MET_OPT_CURR_MON_0_1	CHECK (ANALYTICS_CURRENT_MONTH IN(0,1));
ALTER TABLE CSRIMP.METERING_OPTIONS ADD CONSTRAINT CK_MET_OPT_CURR_MON_0_1	CHECK (ANALYTICS_CURRENT_MONTH IN(0,1));

DROP FUNCTION get_constraintname_text;

ALTER TABLE CSR.METERING_OPTIONS ADD (
	METERING_HELPER_PKG VARCHAR2(255)
);

ALTER TABLE CSRIMP.METERING_OPTIONS ADD (
	METERING_HELPER_PKG VARCHAR2(255)
);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../tag_pkg
@../tag_body
@../meter_body
@update_tail
