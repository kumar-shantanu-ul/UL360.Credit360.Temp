-- Please update version.sql too -- this keeps clean builds in sync
define version=2771
--define minor_version=x
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX csr.uk_non_compliance_ref_type;
ALTER TABLE csr.non_compliance MODIFY non_compliance_ref VARCHAR2(255);
ALTER TABLE csrimp.non_compliance MODIFY non_compliance_ref VARCHAR2(255);

CREATE UNIQUE INDEX csr.uk_non_compliance_ref 
		ON csr.non_compliance (
			CASE WHEN non_compliance_ref IS NULL THEN NULL 
				 ELSE app_sid ||'_' || non_compliance_ref END
		);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../issue_pkg
@../issue_body

@update_tail
