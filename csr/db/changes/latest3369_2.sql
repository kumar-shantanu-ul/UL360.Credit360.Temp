-- Please update version.sql too -- this keeps clean builds in sync
define version=3369
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER SEQUENCE CSR.METER_DATA_ID_SEQ NOCACHE;
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
@..\csr_data_pkg
@..\csr_data_body
@..\meter_processing_job_body
@update_tail
