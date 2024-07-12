CREATE OR REPLACE PACKAGE ct.link_pkg
IS

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany (
	in_company_sid			IN security_pkg.T_SID_ID
);

PROCEDURE InviteCreated (
	in_invitation_id			IN	chain.invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE InvitationAccepted (
	in_invitation_id			IN  chain.invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE NukeChain;

END link_pkg;
/
