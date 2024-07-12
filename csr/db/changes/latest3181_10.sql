-- Please update version.sql too -- this keeps clean builds in sync
define version=3181
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.DATAVIEW_REGION_MEMBER ADD TAB_LEVEL NUMBER(10, 0);
ALTER TABLE CSRIMP.DATAVIEW_REGION_MEMBER ADD TAB_LEVEL NUMBER(10, 0);

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
@../dataview_pkg
@../dataview_body

@../csrimp/imp_body

@update_tail
