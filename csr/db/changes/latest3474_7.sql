-- Please update version.sql too -- this keeps clean builds in sync
define version=3474
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.failed_notification ADD retry_count NUMBER(10, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.failed_notification_archive ADD retry_count NUMBER(10, 0) DEFAULT 0 NOT NULL;

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
@../notification_body

@update_tail
