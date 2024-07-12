-- Please update version.sql too -- this keeps clean builds in sync
define version=38
@update_header

DECLARE
	v_class_id 	                        security_pkg.T_SID_ID;
	v_act 			                    security_pkg.T_ACT_ID;
	PERMISSION_UPDATE_PROGRESS_XML	    NUMBER(10) := 2097152; -- hardcoded so we don't have to recompile pacakges (which might not recompile any more if we're too far behind)
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- project
    v_class_id:=class_pkg.GetClassId('ActionsProject');
    class_pkg.AddPermission(v_act, v_class_id, PERMISSION_UPDATE_PROGRESS_XML, 'Update progress text');
    class_pkg.CreateMapping(v_act, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_WRITE, v_class_id, PERMISSION_UPDATE_PROGRESS_XML);
    -- task
    v_class_id:=class_pkg.GetClassId('ActionsTask');
	class_pkg.AddPermission(v_act, v_class_id, PERMISSION_UPDATE_PROGRESS_XML, 'Update progress text');
END;
/

-- fix up existing permissions in security
begin
	for r in (
		select acl.rowid rid, bitwise_pkg.bitor(permission_set, 2097152) permission_set
		  from security.acl acl, security.securable_object so, security.securable_object_class soc
		 where so.dacl_id = acl.acl_id
		   and so.class_id =soc.class_id
		   and soc.class_name in ('ActionsTask', 'ActionsProject')
		   and bitand(permission_set, 131072) = 131072
	)
	loop
		update security.acl set permission_set = r.permission_set where rowid = r.rid;
	end loop;
end;
/

update actions.role 
   set permission_set_on_task = bitwise_pkg.bitor(permission_set_on_task, 2097152) 
 where bitand(permission_set_on_task, 131072) = 131072;

commit;

@..\task_pkg
@..\task_body

@update_tail
