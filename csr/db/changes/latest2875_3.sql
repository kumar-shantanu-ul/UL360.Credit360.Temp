-- Please update version.sql too -- this keeps clean builds in sync
define version=2875
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


-- Moved to the aggregate ind group, below
ALTER TABLE csr.approval_dashboard_val_src
DROP COLUMN link_url;

ALTER TABLE csr.aggregate_ind_group
ADD source_url VARCHAR2(1027);

/* source_detail is just a string. We are using it to store a date but this isn't set in stone so need to replace LAST_DATE with it
   so that we are covered. The date here isn't used in any calculations, etc so a string of it is fine. */
ALTER TABLE csr.approval_dashboard_val_src
ADD source_detail VARCHAR(1024);

UPDATE csr.approval_dashboard_val_src
   SET source_detail = last_date;
   
ALTER TABLE csr.approval_dashboard_val_src
DROP COLUMN last_date;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@..\aggregate_ind_pkg
@..\aggregate_ind_body
@..\approval_dashboard_pkg
@..\approval_dashboard_body
@..\stored_calc_datasource_body

@update_tail
