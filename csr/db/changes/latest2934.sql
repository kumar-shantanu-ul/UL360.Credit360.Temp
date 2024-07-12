-- Please update version.sql too -- this keeps clean builds in sync
define version=2934
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
drop table csr.dataview_arbitrary_period cascade constraints;
drop table csr.dataview_arbitrary_period_hist cascade constraints;
drop table CSRIMP.DATAVIEW_ARBITRARY_PERIOD cascade constraints;
drop table CSRIMP.DATAVIEW_ARBITRARY_PERIOD_HIST cascade constraints;

-- Alter tables

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
@../csr_app_body
@../dataview_pkg
@../dataview_body
@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
