-- Please update version.sql too -- this keeps clean builds in sync
define version=3167
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	-- Ethics was optional module that is being trashed.
	-- Conditionally remove packages / cross schema constraints
	FOR r IN (
		SELECT object_name
		  FROM all_objects
		 WHERE owner = 'ETHICS'
		   AND object_type = 'PACKAGE'
		   AND object_name IN ('QUESTION_PKG','PARTICIPANT_PKG','ETHICS_PKG','DEMO_PKG','COURSE_PKG','COMPANY_USER_PKG','COMPANY_PKG')
	) LOOP
		EXECUTE IMMEDIATE 'DROP PACKAGE ETHICS.'||r.object_name;
	END LOOP;
	
	FOR r IN (
		SELECT owner, table_name, constraint_name
		  FROM all_constraints
		 WHERE r_owner != 'ETHICS'
		   AND owner = 'ETHICS'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE ETHICS.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	
	DELETE FROM csr.module_param WHERE module_id = 13;
	DELETE FROM csr.module WHERE module_id = 13;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu 
		 WHERE LOWER(action) LIKE '%/csr/site/ethics%'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
