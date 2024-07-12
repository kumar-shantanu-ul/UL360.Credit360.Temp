-- Please update version.sql too -- this keeps clean builds in sync
define version=3194
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
create index csr.ix_osha_mapping_ind_sid on csr.osha_mapping (ind_sid);
create index csr.ix_osha_mapping_osha_base_dat on csr.osha_mapping (osha_base_data_id);
-- Alter tables

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
