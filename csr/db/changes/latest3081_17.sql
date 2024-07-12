-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_ROLLOUTLVL_RT AS
	OBJECT (
		REGION_SID					NUMBER(10),
		REGION_TYPE					NUMBER(2)
	);
/

CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_RLLVL_RT_TABLE AS
	TABLE OF CSR.T_COMPLIANCE_ROLLOUTLVL_RT;
/

-- Alter tables
ALTER TABLE CSR.COMPLIANCE_ROOT_REGIONS ADD (ROLLOUT_LEVEL NUMBER(10,0) DEFAULT 1);

ALTER TABLE CSRIMP.COMPLIANCE_ROOT_REGIONS ADD (ROLLOUT_LEVEL NUMBER(10,0));

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

@../compliance_pkg
@../compliance_body
@../schema_body
@../csrimp/imp_body

@update_tail
