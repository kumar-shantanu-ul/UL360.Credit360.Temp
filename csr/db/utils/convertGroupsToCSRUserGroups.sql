
DECLARE
v_act VARCHAR(38);
v_sid NUMBER(10);
v_class_id NUMBER(10);
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	SELECT securableobject_pkg.GetSIDFromPath(v_act,0,'//aspen/applications/&&AppName/groups') INTO v_sid FROM dual;
	v_class_id := class_pkg.getclassid('csrusergroup');
	UPDATE security.securable_object 
	   SET class_id = v_class_id
	 WHERE Parent_sid_id = v_sid AND class_id = security_pkg.SO_GROUP;
END;
/
commit;
exit
