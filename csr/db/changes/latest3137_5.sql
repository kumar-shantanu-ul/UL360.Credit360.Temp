-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.FACTOR ADD IS_VIRTUAL NUMBER (1,0) DEFAULT 0;
ALTER TABLE CSR.FACTOR ADD CONSTRAINT CK_FACTOR_IS_VIRTUAL CHECK (IS_VIRTUAL IN (1, 0));

ALTER TABLE CSRIMP.FACTOR ADD IS_VIRTUAL NUMBER (1,0);
ALTER TABLE CSRIMP.FACTOR ADD CONSTRAINT CK_FACTOR_IS_VIRTUAL CHECK (IS_VIRTUAL IN (1, 0));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Region Emission Factor Cascading', 0, 'Emission Factors: Cascade region level factors to child regions.');
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (100, 'Region Emission Factor cascading', 'EnableRegionEmFactorCascading', 'Enables Region Emission Factor cascading.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../factor_pkg

@../enable_body
@../factor_body
@../schema_body
@../stored_calc_datasource_body

@update_tail
