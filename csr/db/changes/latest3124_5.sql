-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


-- Remove the fallout from the tag description change

ALTER TABLE csr.tag DROP COLUMN tag_old;
ALTER TABLE csr.tag DROP COLUMN explanation_old;
ALTER TABLE csr.tag_group DROP COLUMN name_old;

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
