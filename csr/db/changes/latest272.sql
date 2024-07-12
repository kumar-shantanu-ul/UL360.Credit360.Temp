-- Please update version.sql too -- this keeps clean builds in sync
define version=272
@update_header

DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	Attribute_Pkg.CreateDefinition(v_act, class_pkg.GetClassId('CSRData'), 'delegations-always-show-advanced-options', 0, NULL, v_attribute_id);
END;
/

@update_tail
