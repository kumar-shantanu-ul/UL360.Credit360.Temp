-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (SELECT table_name, constraint_name
			    FROM all_constraints
			   WHERE owner='CSRIMP'
			     AND constraint_name IN ('FK_BSCI_AUDIT_2009_COMPANY_SID', 'FK_BSCI_AUDIT_2014_COMPANY_SID', 'FK_BSCI_AUDIT_2009_REF', 'FK_BSCI_AUDIT_2014_REF', 'FK_BSCI_AUDIT_TYPE_ID', 'FK_BSCI_AUDIT_REF_ASS_2014', 'FK_BSCI_AUDIT_REF_ASS_2009', 'FK_BSCI_SUPPLIER_COMP')
    ) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
