-- Please update version.sql too -- this keeps clean builds in sync
define version=3310
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM csr.tag_group
 WHERE tag_group_id NOT IN (SELECT tag_group_id FROM csr.tag_group_description)
   AND tag_group_id NOT IN (SELECT tag_group_id FROM csr.tag_group_member);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_body

@../tag_body

@update_tail
