-- Please update version.sql too -- this keeps clean builds in sync
define version=3425
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

alter table csr.automated_export_class drop column last_fetched_date;
alter table csr.automated_export_class drop column fetched_count;
alter table csr.automated_export_instance add last_fetched_date date;
alter table csr.automated_export_instance add fetched_count number(10) default 0 not null;

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
@../automated_export_pkg
@../automated_export_body

@update_tail
