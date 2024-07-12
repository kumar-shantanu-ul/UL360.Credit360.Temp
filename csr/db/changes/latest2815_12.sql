-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

ALTER TABLE csr.customer ADD tplreportperiodextension NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD tplreportperiodextension NUMBER(2)  DEFAULT 1 NOT NULL;


-- Data
UPDATE csr.customer
   SET TPLREPORTPERIODEXTENSION = 5
 WHERE name='hyatt.credit360.com';


-- ** New package grants **

-- *** Packages ***
@../csr_app_body

@update_tail
