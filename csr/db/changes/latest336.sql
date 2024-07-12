-- Please update version.sql too -- this keeps clean builds in sync
define version=336
@update_header

DECLARE
	v_act security_pkg.T_ACT_ID;
	v_datasets_sid security_pkg.T_SID_ID;
	v_dataset_sid security_pkg.T_SID_ID;
	v_csrdataset_class_id security.securable_object.class_id%TYPE;
BEGIN
	v_csrdataset_class_id := class_pkg.GetClassId('CSRDataset');
	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	
	FOR app IN (SELECT app_sid FROM customer WHERE EXISTS (SELECT * FROM security.securable_object WHERE securable_object.sid_id = customer.app_sid AND securable_object.class_id = (SELECT class_id FROM security.securable_object_class WHERE class_name = 'CSRApp'))
			UNION SELECT app_sid FROM pending_dataset)
	LOOP
		v_datasets_sid := securableobject_pkg.GetSIDFromPath(v_act, app.app_sid, 'Pending/Datasets');
		
		FOR ds IN (SELECT * FROM pending_dataset WHERE app_sid = app.app_sid AND new_sid IS NULL FOR UPDATE)
		LOOP
			securableobject_pkg.CreateSO(v_act, v_datasets_sid, v_csrdataset_class_id, NULL, v_dataset_sid);

			UPDATE pending_dataset SET new_sid = v_dataset_sid WHERE pending_dataset_id = ds.pending_dataset_id;
		END LOOP;
	END LOOP;
	
	user_pkg.LogOff(v_act);
END;
/

@update_tail
