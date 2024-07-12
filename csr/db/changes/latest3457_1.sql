-- Please update version.sql too -- this keeps clean builds in sync
define version=3457
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
UPDATE csr.tag_group_description
   SET name = 'RBA Audit Type'
 WHERE tag_group_id IN (SELECT tag_group_id FROM csr.tag_group WHERE lookup_key = 'RBA_AUDIT_CATEGORY');
 
UPDATE csr.tag_group
   SET lookup_key = 'RBA_AUDIT_TYPE'
 WHERE lookup_key = 'RBA_AUDIT_CATEGORY';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
