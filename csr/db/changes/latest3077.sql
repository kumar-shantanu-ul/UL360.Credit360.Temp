-- Please update version.sql too -- this keeps clean builds in sync
define version=3077
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Make the lookup key big enough to hold all of the excluded tags.
ALTER TABLE csr.temp_question_option MODIFY (lookup_key VARCHAR2(1000));

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

@update_tail
