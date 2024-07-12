-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX csr.ix_tag_grp_mem_tag;

ALTER TABLE CSR.TAG_GROUP_MEMBER ADD CONSTRAINT UK_TAG_GROUP_MEMBER UNIQUE (APP_SID, TAG_ID);

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
