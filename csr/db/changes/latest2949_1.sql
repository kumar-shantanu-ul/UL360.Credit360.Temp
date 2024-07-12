-- Please update version.sql too -- this keeps clean builds in sync
define version=2949
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX csr.uk_imp_region_desc;

ALTER TABLE csr.imp_region
  MODIFY description VARCHAR2(4000);

CREATE UNIQUE INDEX csr.uk_imp_region_desc ON csr.imp_region(app_sid, LOWER(description));  

ALTER TABLE csrimp.imp_region
  MODIFY description VARCHAR2(4000);

DROP INDEX csr.uk_imp_ind_desc;

ALTER TABLE csr.imp_ind
  MODIFY description VARCHAR2(4000);

CREATE UNIQUE INDEX csr.uk_imp_ind_desc ON csr.imp_ind(app_sid, LOWER(description))

ALTER TABLE csrimp.imp_ind
  MODIFY description VARCHAR2(4000);

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
@../indicator_pkg
@../indicator_body
@../imp_body

@update_tail
