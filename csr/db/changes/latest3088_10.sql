-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15780,11158,'Fugitive Gas - R-1270 Propene (Propylene)',1,0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15781,11158,'Fugitive Gas - R-448A',1,0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15782,11158,'Fugitive Gas - R-449A',1,0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15783,11158,'Fugitive Gas - R-728 Nitrogen',1,0);
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
