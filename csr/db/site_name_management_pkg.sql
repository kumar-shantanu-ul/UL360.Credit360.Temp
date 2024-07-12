CREATE OR REPLACE PACKAGE CSR.site_name_management_pkg IS

PROCEDURE RenameSite(
	in_to_host			IN	csr.customer.host%TYPE
);

PROCEDURE GetSoftlinks(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CreateSoftLink(
	in_softlink_name	IN	csr.customer.host%TYPE
);

PROCEDURE DeleteSoftLink(
	in_softlink_name	IN	csr.customer.host%TYPE
);

END site_name_management_pkg;
/
