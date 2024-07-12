-- Please update version.sql too -- this keeps clean builds in sync
define version=2944
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.EST_ERROR MODIFY (
    APP_SID            NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP'),
    ERROR_DTM          DATE              DEFAULT SYSDATE,
    ACTIVE             NUMBER(1, 0)      DEFAULT 1
);

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
@../energy_star_pkg

@../energy_star_body
@../energy_star_job_body

@update_tail
