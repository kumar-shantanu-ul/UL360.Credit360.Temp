-- Please update version.sql too -- this keeps clean builds in sync
define version=349
@update_header

-- Update application_sid_id for SOs added for Pending forms by recent scripts.

DECLARE
	v_act security_pkg.T_ACT_ID;
	v_app_sid security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	FOR so IN (SELECT DISTINCT sid_id FROM security.securable_object WHERE application_sid_id IS NULL START WITH class_id = class_pkg.GetClassId('CSRApprovalStep') CONNECT BY sid_id = PRIOR parent_sid_id AND (PRIOR name IS NULL OR PRIOR name <> 'Pending'))
	LOOP
		SELECT application_sid_id INTO v_app_sid FROM security.securable_object WHERE application_sid_id IS NOT NULL START WITH sid_id = so.sid_id CONNECT BY sid_id = PRIOR parent_sid_id AND PRIOR application_sid_id IS NULL;

		UPDATE security.securable_object SET application_sid_id = v_app_sid WHERE sid_id = so.sid_id AND application_sid_id IS NULL;
	END LOOP;
END;
/

@update_tail
