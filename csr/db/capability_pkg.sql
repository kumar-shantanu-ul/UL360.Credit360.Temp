CREATE OR REPLACE PACKAGE CSR.capability_pkg IS

PROCEDURE GetCapabilities(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE ChangeCapability(
	in_capability_name	IN CAPABILITY.name%TYPE,
	in_action			IN NUMBER
);

PROCEDURE LogChangeCapability(
	in_capability_name	IN CAPABILITY.name%TYPE,
	in_action			IN NUMBER,
	in_user_sid			IN security.security_pkg.T_SID_ID
);

END capability_pkg;
/
