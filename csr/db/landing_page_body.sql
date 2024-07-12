CREATE OR REPLACE PACKAGE BODY CSR.landing_page_pkg AS

PROCEDURE GetDefaultHomePage(
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_default_home_page			security.home_page.url%TYPE;
	v_application_home_page		aspen2.application.default_url%TYPE;
BEGIN
	security.web_pkg.GetHomePage(
		in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
		out_url => v_default_home_page
	);

	SELECT default_url
	  INTO v_application_home_page
	  FROM aspen2.application
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur FOR
		SELECT v_default_home_page AS default_home_page, v_application_home_page AS application_home_page
		  FROM DUAL;
END;

PROCEDURE GetLandingPages(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT so.sid_id, url AS path, so.name, priority
		FROM security.home_page hp
		LEFT JOIN security.securable_object so ON so.sid_id = hp.sid_id
		WHERE hp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		ORDER BY so.name;
END;

PROCEDURE InsertLandingPage(
	in_sid_id		IN	security.security_pkg.T_SID_ID,
	in_path			IN	VARCHAR2,
	in_priority		IN	NUMBER
)
AS
	v_host			VARCHAR(255);
	v_count			NUMBER;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied inserting Landing Page.');
	END IF;
	
	SELECT host
	  INTO v_host
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT COUNT(*)
	  INTO v_count
	  FROM security.home_page
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sid_id = in_sid_id;
	
	IF NVL(v_count, 0) <> 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Landing Page already exists.');
	END IF;

	security.web_pkg.SetHomePage(
		in_act_id		=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid		=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_sid_id		=>	in_sid_id,
		in_url			=>	in_path,
		in_host			=>	v_host,
		in_priority		=>	in_priority
	);

	csr_data_pkg.WriteAuditLogEntry(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		csr_data_pkg.AUDIT_TYPE_LANDING_PAGE,
		SYS_CONTEXT('SECURITY', 'APP'),
		in_sid_id,
		'Add Landing Page',
		in_path,
		in_priority
	);
END;

PROCEDURE UpsertLandingPage(
	in_sid_id		IN	security.security_pkg.T_SID_ID,
	in_path			IN	VARCHAR2,
	in_priority		IN	NUMBER
)
AS
	v_host			VARCHAR(255);
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating Landing Page.');
	END IF;
	
	SELECT host
	  INTO v_host
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	security.web_pkg.SetHomePage(
		in_act_id		=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid		=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_sid_id		=>	in_sid_id,
		in_url			=>	in_path,
		in_host			=>	v_host,
		in_priority		=>	in_priority
	);

	csr_data_pkg.WriteAuditLogEntry(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		csr_data_pkg.AUDIT_TYPE_LANDING_PAGE,
		SYS_CONTEXT('SECURITY', 'APP'),
		in_sid_id,
		'Set Landing Page',
		in_path,
		in_priority
	);
END;

PROCEDURE DeleteLandingPage(
	in_sid_id			IN	security.security_pkg.T_SID_ID
)
AS
	v_url				security.home_page.url%TYPE;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting Landing Page.');
	END IF;

	SELECT url
	  INTO v_url
	  FROM security.home_page hp
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sid_id = in_sid_id;

	security.web_pkg.DeleteHomePage(
		in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
		in_sid_id => in_sid_id
	);

	csr_data_pkg.WriteAuditLogEntry(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		csr_data_pkg.AUDIT_TYPE_LANDING_PAGE,
		SYS_CONTEXT('SECURITY', 'APP'),
		in_sid_id,
		'Delete Landing Page',
		v_url
	);
END;


END landing_page_pkg;
/
