-- Please update version.sql too -- this keeps clean builds in sync
define version=2842
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.est_job add attempts number (10) default 0 not null ;
alter table csr.est_job add notified number (1) default 0 not null ;
alter table csr.est_job add constraint ck_est_job_notified check (notified in (0,1));
alter table csr.customer add est_job_notify_address varchar2(512) default 'support@credit360.com';
alter table csr.customer add est_job_notify_after_attempts number(10) default 3;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../energy_star_job_pkg
@../energy_star_job_body

@update_tail
