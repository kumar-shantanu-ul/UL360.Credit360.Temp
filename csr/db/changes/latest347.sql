-- Please update version.sql too -- this keeps clean builds in sync
define version=347
@update_header

-- Temporarily grant everyone full control over Pending datasets so that we can switch approval_step_id IDs to SIDs without having to put proper security checks
-- and permissions in place.

DECLARE
	v_act security_pkg.T_ACT_ID;
	v_app_sid security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	FOR so IN (SELECT * FROM security.securable_object WHERE name = 'Datasets' START WITH class_id = class_pkg.GetClassId('CSRDataset') CONNECT BY sid_id = PRIOR parent_sid_id AND (PRIOR name IS NULL OR PRIOR name <> 'Datasets'))
	LOOP
		SELECT application_sid_id INTO v_app_sid FROM security.securable_object WHERE application_sid_id IS NOT NULL START WITH sid_id = so.sid_id CONNECT BY sid_id = PRIOR parent_sid_id AND PRIOR application_sid_id IS NULL;

		acl_pkg.AddACE(v_act, so.dacl_id, -1, 1, 3, securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups/Everyone'), 1023);
		acl_pkg.PropogateACEs(v_act, so.sid_id);
	END LOOP;
END;
/

@update_tail
