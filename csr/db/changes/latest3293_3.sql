-- Please update version.sql too -- this keeps clean builds in sync
define version=3293
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- fix invalid FK constraints in csrimp
DECLARE
	v_count		NUMBER;
BEGIN
	FOR r IN (
		SELECT *
		  FROM all_constraints
		 WHERE owner = 'CSRIMP'
		   AND constraint_name IN ('FK_NON_COMP_TYP_CAPAB','FK_CAL_CI')
		)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE owner = 'CSRIMP'
	   AND constraint_name = 'FK_CAL_IS';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.compliance_audit_log ADD CONSTRAINT FK_CAL_IS FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
