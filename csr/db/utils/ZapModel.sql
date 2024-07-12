set serveroutput on
define old_feedback=&&feedback
define feedback=0
set feedback &&feedback

variable model_sid number

BEGIN
	:model_sid := &1;
END;
/

DECLARE
	v_act security_pkg.t_act_id;
	v_count number;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	SELECT COUNT(*) INTO v_count FROM security.securable_object WHERE sid_id = :model_sid AND class_id = class_pkg.GetClassId('CSRModel');

	IF v_count <> 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Model ' || :model_sid || ' not found.');
	END IF;

	FOR instance IN (SELECT model_instance_sid FROM model_instance WHERE base_model_sid = :model_sid)
	LOOP
		securableobject_pkg.DeleteSO(v_act, instance.model_instance_sid);
	END LOOP;

	securableobject_pkg.DeleteSO(v_act, :model_sid);

	dbms_output.put_line('Model deleted. Commit or rollback.');
END;
/

define feedback=&&old_feedback
set feedback &&feedback
