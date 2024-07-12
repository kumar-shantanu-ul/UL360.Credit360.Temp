-- Please update version.sql too -- this keeps clean builds in sync
define version=2991
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
begin
	for r in (
		select 'revoke '||p.privilege||' on csrimp.'||at.table_name||' from web_user' s
		  from dba_tab_privs p, all_tables at where p.grantee='WEB_USER' and p.owner='CSRIMP'
		   and p.owner = at.owner and p.table_name = at.table_name and at.dropped = 'NO') loop
		execute immediate r.s;
	end loop;
end;
/

grant select,insert,update,delete on csrimp.scheduled_stored_proc to tool_user;
grant select, insert, update, delete on csrimp.init_tab_element_layout to tool_user;
grant select, insert, update, delete on csrimp.init_create_page_el_layout to tool_user;
grant select, insert, update, delete on csrimp.initiative_header_element to tool_user;

GRANT SELECT, INSERT, UPDATE ON csrimp.custom_factor_set TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.custom_factor TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.emission_factor_profile TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.emission_factor_profile_factor TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail
