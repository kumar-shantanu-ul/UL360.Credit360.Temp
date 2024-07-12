-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.aggregate_ind_val_detail
ADD LINK_URL varchar2(256);

ALTER TABLE csr.approval_dashboard_val_src
ADD LINK_URL varchar2(256);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\approval_dashboard_body

@update_tail