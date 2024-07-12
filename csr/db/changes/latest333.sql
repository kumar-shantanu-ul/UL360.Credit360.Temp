-- Please update version.sql too -- this keeps clean builds in sync
define version=333
@update_header

DECLARE
	v_act security_pkg.T_ACT_ID;
	v_pending_sid_id security_pkg.T_ACT_ID;
	v_new_sid_id security_pkg.T_ACT_ID;	
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	
	FOR app IN (SELECT app_sid FROM customer WHERE EXISTS (SELECT * FROM security.securable_object WHERE securable_object.sid_id = customer.app_sid AND securable_object.class_id = (SELECT class_id FROM security.securable_object_class WHERE class_name = 'CSRApp'))
			UNION SELECT app_sid FROM pending_dataset)
	LOOP
		BEGIN
			securableobject_pkg.CreateSO(v_act, app.app_sid, security_pkg.SO_CONTAINER, 'Pending', v_pending_sid_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_pending_sid_id := securableobject_pkg.GetSIDFromPath(v_act, app.app_sid, 'Pending');
		END;
		BEGIN
			securableobject_pkg.CreateSO(v_act, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			securableobject_pkg.CreateSO(v_act, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Datasets', v_new_sid_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
	
	user_pkg.LogOff(v_act);
END;
/

@update_tail
