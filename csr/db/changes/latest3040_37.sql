-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.higg_module_tag_group
 DROP CONSTRAINT pk_higg_mod_tag_grp;

ALTER TABLE chain.higg_module_tag_group
  ADD CONSTRAINT pk_higg_mod_tag_grp PRIMARY KEY (app_sid, higg_module_id, tag_group_id);

ALTER TABLE csrimp.higg_module_tag_group
 DROP CONSTRAINT pk_higg_module_tag_group;
 
ALTER TABLE csrimp.higg_module_tag_group
  ADD CONSTRAINT pk_higg_module_tag_group PRIMARY KEY (csrimp_session_id, higg_module_id, tag_group_id);

-- *** Grants ***

GRANT SELECT ON chain.higg_module TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\higg_pkg
@..\chain\higg_body
@..\enable_body

@update_tail
