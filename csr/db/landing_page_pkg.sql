CREATE OR REPLACE PACKAGE CSR.landing_page_pkg AS

PROCEDURE GetDefaultHomePage(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetLandingPages(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE InsertLandingPage(
	in_sid_id		IN	security.security_pkg.T_SID_ID,
	in_path			IN	VARCHAR2,
	in_priority		IN	NUMBER
);

PROCEDURE UpsertLandingPage(
	in_sid_id		IN	security.security_pkg.T_SID_ID,
	in_path			IN	VARCHAR2,
	in_priority		IN	NUMBER
);

PROCEDURE DeleteLandingPage(
	in_sid_id			IN	security.security_pkg.T_SID_ID
);

END landing_page_pkg;
/
