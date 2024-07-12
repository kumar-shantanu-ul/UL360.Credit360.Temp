-- Please update version.sql too -- this keeps clean builds in sync
define version=1453
@update_header

-- based on latest286
DECLARE
	v_act				security.security_pkg.T_ACT_ID;
	v_class_id			security.security_pkg.T_SID_ID;
	v_attribute_id		security.security_pkg.T_ATTRIBUTE_ID;
BEGIN
	security.user_pkg.logonauthenticatedpath(0, '//builtin/administrator', 500, v_act);

	v_class_id := security.class_pkg.GetClassId('CSRData');

	BEGIN
		security.attribute_pkg.CreateDefinition(v_act, v_class_id, 'targetdashboard-show-target-first', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.attribute_pkg.CreateDefinition(v_act, v_class_id, 'targetdashboard-colour-text', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.attribute_pkg.CreateDefinition(v_act, v_class_id, 'targetdashboard-show-last-year', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.attribute_pkg.CreateDefinition(v_act, v_class_id, 'targetdashboard-show-change-from-last-year', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

COMMIT;

@update_tail
