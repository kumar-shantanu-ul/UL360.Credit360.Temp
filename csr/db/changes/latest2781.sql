-- Please update version.sql too -- this keeps clean builds in sync
define version=2781
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.aggregate_ind_val_detail modify description varchar2(4000);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
