-- Please update version.sql too -- this keeps clean builds in sync
define version=3421
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.PROJECT_INITIATIVE_METRIC DROP CONSTRAINT FK_PRJ_PRJ_INIT_MET;

ALTER TABLE CSR.PROJECT_INITIATIVE_METRIC ADD CONSTRAINT FK_PRJ_PRJ_INIT_MET 
    FOREIGN KEY (APP_SID, PROJECT_SID, FLOW_SID)
    REFERENCES CSR.INITIATIVE_PROJECT(APP_SID, PROJECT_SID, FLOW_SID)
    DEFERRABLE INITIALLY DEFERRED;

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

@../initiative_project_pkg
@../initiative_project_body

@update_tail
