-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
UPDATE csr.issue_type 
   SET helper_pkg = 'csr.permit_pkg' 
 WHERE issue_type_id = 22;

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\enable_body
@update_tail
