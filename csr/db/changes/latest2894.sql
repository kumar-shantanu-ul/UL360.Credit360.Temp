-- Please update version.sql too -- this keeps clean builds in sync
define version=2894
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
grant select, insert, update, delete on csrimp.non_compliance_type_tag_group to web_user;
grant select, insert, update, delete on csrimp.internal_audit_type_tag_group to web_user;
grant select, insert, update, delete on csrimp.internal_audit_tag to web_user;
grant select, insert, update, delete on csrimp.chain_company_type_tag_group to web_user;

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
