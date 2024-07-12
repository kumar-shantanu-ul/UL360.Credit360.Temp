-- Please update version.sql too -- this keeps clean builds in sync
define version=38
@update_header

DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	new_class_id:=class_pkg.GetClassId('DonationsScheme');
	class_pkg.AddPermission(v_act, new_class_id, 4194304, 'View donations at my site'); -- donations.SCHEME_pkg.PERMISSION_VIEW_REGION
	class_pkg.CreateMapping(v_act, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_READ, new_class_id, 4194304);
	class_pkg.AddPermission(v_act, new_class_id, 8388608, 'Update donations at my site');
	class_pkg.CreateMapping(v_act, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_WRITE, new_class_id, 8388608); -- donations.SCHEME_pkg.PERMISSION_UPDATE_REGION
END;
/

DROP TYPE T_BUDGET_ID_TABLE;

CREATE OR REPLACE TYPE T_BUDGET_ID_ROW AS OBJECT (
	BUDGET_ID		NUMBER(10),
	CAN_VIEW_ALL	NUMBER(1),
	CAN_VIEW_MINE	NUMBER(1),
	CAN_VIEW_REGION	NUMBER(1)
);
/

CREATE OR REPLACE TYPE T_BUDGET_ID_TABLE AS TABLE OF T_BUDGET_ID_ROW;
/

@../donation_pkg
@../donation_body
@../budget_pkg
@../budget_body

@update_tail
