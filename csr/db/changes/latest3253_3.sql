-- Please update version.sql too -- this keeps clean builds in sync
define version=3253
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSRIMP.FLOW_STATE RENAME COLUMN MOVE_TO_FLOW_STATE_ID TO MOVE_FROM_FLOW_STATE_ID;

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
@../csrimp/imp_body
@../schema_body

@update_tail
