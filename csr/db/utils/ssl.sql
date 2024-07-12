declare
	v_act varchar(38);
	v_sid number(36);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_sid := securableobject_pkg.getSidFromPath(v_act, 0, '//aspen/applications/&&1/wwwroot');
	update security.web_resource set secure_only = 1 where web_root_sid_id = v_sid; --and path like '/csr/site/login%';
end;
/
commit;

