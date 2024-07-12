DECLARE
	TYPE T_ROLE_NAMES IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_role_names		T_ROLE_NAMES;
	v_role_sid		security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonadmin('&&1');
	
	v_role_names(1) := 'Data Providers';
	v_role_names(2) := 'Data Approvers';
	
	FOR i IN v_role_names.FIRST..v_role_names.LAST
	LOOP	
		UPDATE role
		   SET name = v_role_names(i)
		 WHERE LOWER(name) = LOWER(v_role_names(i))
		   AND app_sid = security_pkg.getApp
		 RETURNING role_sid INTO v_role_sid;

		IF SQL%ROWCOUNT = 0 THEN
			
			v_role_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups/'||v_role_names(i));
			
			UPDATE security.securable_object
			   SET class_id = class_pkg.GetClassId('CSRRole')
			 WHERE sid_id = v_role_sid;

			INSERT INTO role 
				(role_sid, app_sid, name) 
			VALUES 
				(v_role_sid, security_pkg.getApp, v_role_names(i));
		END IF;
	END LOOP;
	COMMIT;
END;
/

exit

