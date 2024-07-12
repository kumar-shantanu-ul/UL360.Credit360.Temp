alter table project_role drop column project_role_sid;


declare
	v_act varchar(38);
	v_sid number(36);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	update security.securable_object_class set helper_pkg = null where class_name='ActionsProjectRole';
	v_sid := class_pkg.GetClassId('ActionsProjectRole');
	for r in (select sid_id from security.securable_object where class_id = v_sid)
	loop
		securableobject_pkg.deleteso(v_act, r.sid_id);
	end loop;
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	class_pkg.DeleteClass(v_act, v_sid);
END;
/


alter table role add (multi_select number(10) default(1) not null);

CREATE TABLE REF(
    APP_SID     NUMBER(10, 0)    NOT NULL,
    NEXT_VAL    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK35 PRIMARY KEY (APP_SID)
)
;


