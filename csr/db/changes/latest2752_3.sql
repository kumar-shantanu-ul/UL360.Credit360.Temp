-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.imp_session
ADD unmerged_dtm DATE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../imp_body

@update_tail
