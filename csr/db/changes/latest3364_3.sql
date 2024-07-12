-- Please update version.sql too -- this keeps clean builds in sync
define version=3364
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.scheduled_task_stat ADD run_guid VARCHAR2(38);

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
@../scheduled_task_pkg
@../scheduled_task_body

@update_tail
