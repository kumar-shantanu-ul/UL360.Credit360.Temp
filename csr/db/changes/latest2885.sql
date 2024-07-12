-- Please update version.sql too -- this keeps clean builds in sync
define version=2885
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
set serveroutput on
declare
	type t_objs is table of varchar2(30);
	v_list t_objs;
	v_sid number;
	v_sa_sid number;
begin	
	v_list := t_objs(
		'Charts',
		'Workspace',
		'CMS Filters',
		'Pivot tables'
	);	
	v_sa_sid := security.securableobject_pkg.getsidfrompath(null,0,'//csr/users');

	for i in 1 .. v_list.count loop	
		security.user_pkg.logonadmin;
		for r in (select sop.parent_sid_id, cu.csr_user_sid, max(cu.app_sid) app_sid, count(*) cnt
					from csr.csr_user cu
					join security.securable_object sop on cu.csr_user_sid = sop.sid_id
					left join security.securable_object so 
					  on cu.csr_user_sid = so.parent_sid_id and lower(so.name) = lower(v_list(i))
				   where so.sid_id is null
				     and so.sid_id not in (3,5)
				   group by sop.parent_sid_id, cu.csr_user_sid) loop
			if r.cnt > 1 then
				if r.parent_sid_id != v_sa_sid then
					raise_application_error(-20001, 'cross app user that isn''t an sa: '||r.csr_user_sid);
				end if;
				security.security_pkg.setapp(null);
			else
				security.security_pkg.setapp(r.app_sid);
			end if;
			--dbms_output.put_line('doin ' ||r.csr_user_sid || '.'||v_list(i));
			security.securableobject_pkg.createSO(sys_context('security', 'act'), r.csr_user_sid, security.security_pkg.SO_CONTAINER, v_list(i), v_sid);
		end loop;
	end loop;	
end;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
