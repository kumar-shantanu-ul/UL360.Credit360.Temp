-- Please update version.sql too -- this keeps clean builds in sync
define version=3068
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
begin
	for r in (select * from all_audit_policies) loop
		dbms_fga.drop_policy(r.object_schema, r.object_name, r.policy_name);
	end loop;
end;
/

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_body

@update_tail
