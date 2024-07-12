-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=41
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_imp_core_data_settings
ADD financial_year_start_month NUMBER(2);

UPDATE csr.auto_imp_core_data_settings
   SET financial_year_start_month = 3
 WHERE zero_indexed_month_indices = 1;

UPDATE csr.auto_imp_core_data_settings
   SET financial_year_start_month = 4
 WHERE financial_year_start_month IS NULL;
 
 ALTER TABLE csr.auto_imp_core_data_settings
MODIFY financial_year_start_month NUMBER(2) NOT NULL;


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
@../automated_import_pkg
@../automated_import_body

@update_tail
