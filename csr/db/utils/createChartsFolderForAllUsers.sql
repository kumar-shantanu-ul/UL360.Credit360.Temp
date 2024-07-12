

DECLARE	
	v_act 	security_pkg.T_ACT_ID;
	v_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN (
		SELECT * FROM csr_user WHERE app_sid = (select app_sid from customer where host='&&1')
	   )
	LOOP
		BEGIN
	    	v_sid := securableobject_pkg.getsidfrompath(v_act, r.csr_user_sid, 'Charts');
        EXCEPTION
        	WHEN security_pkg.OBJECT_NOT_FOUND THEN
				securableobject_pkg.createSO(v_act, r.csr_user_sid, security_pkg.SO_CONTAINER, 'Charts',v_sid);
        END;		
	END LOOP;
END;
/
commit;
