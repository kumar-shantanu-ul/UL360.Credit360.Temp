-- Please update version.sql too -- this keeps clean builds in sync
define version=286
@update_header

DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_class_id			security_pkg.T_SID_ID;
	v_attribute_id		security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0, '//builtin/administrator', 500, v_act);
	--
	v_class_id := class_pkg.GetClassId('CSRData');
	--
	BEGIN
		attribute_pkg.CreateDefinition(v_act, v_class_id, 'targetdashboard-hide-totals', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	--
	BEGIN
		attribute_pkg.CreateDefinition(v_act, v_class_id, 'targetdashboard-ignore-estimated', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

COMMIT;

@update_tail
