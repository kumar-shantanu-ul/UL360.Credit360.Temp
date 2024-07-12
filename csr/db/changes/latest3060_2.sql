-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=2
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
UPDATE csr.batch_job_type
   SET sp = NULL, plugin_name = 'batch-exporter'
 WHERE batch_job_type_id = 59; -- Product Type export

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/product_type_pkg
@../chain/product_type_body

@update_tail
