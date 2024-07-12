alter table project_role add (project_role_sid number(10) not null);

-- zap old classes
declare
	v_act varchar(38);
	v_sid number(36);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	class_pkg.DeleteClass(v_act, class_pkg.GetClassId('ActionsProject'));
	class_pkg.DeleteClass(v_act, class_pkg.GetClassId('ActionsTask'));
end;
/

@\cvs\csr\db\actions\create_classes.sql
commit;
