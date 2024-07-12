CREATE OR REPLACE PACKAGE BODY csr.zap_pkg AS

PROCEDURE GetSitesToZap_Regex(
	in_expr						IN	VARCHAR2,
	in_ignore_activity_window	IN	NUMBER DEFAULT 1440, --24hours
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT host 
		  FROM csr.customer 
		 WHERE REGEXP_LIKE (host, in_expr)
		   AND app_sid in (
				SELECT app_sid 
				  FROM (
					SELECT app_sid, (SELECT MAX(audit_date) FROM csr.audit_log WHERE app_sid = c.app_sid) max_date
					  FROM csr.customer c 
					) la
				WHERE (
					(la.max_date IS NOT NULL AND la.max_date < SYSDATE - NUMTODSINTERVAL(in_ignore_activity_window, 'MINUTE'))
					OR
					(la.max_date IS NULL)
				)
			);
END;

PROCEDURE GetSiteInfo(
	in_host_name			IN	VARCHAR2,
	out_info_cur			OUT	SYS_REFCURSOR,
	out_cms_schema_cur		OUT	SYS_REFCURSOR,
	out_website_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid				csr.customer.app_sid%TYPE;
BEGIN

	SELECT app_sid
	  INTO v_app_sid
	  FROM csr.customer
	 WHERE lower(host) = lower(in_host_name);

	OPEN out_info_cur FOR
		SELECT c.host, c.app_sid, t.tenant_id, c.oracle_schema
		  FROM csr.customer c
		  LEFT JOIN security.tenant t on t.application_sid_id = c.app_sid
		 WHERE c.app_sid = v_app_sid;

	OPEN out_cms_schema_cur FOR
		SELECT aps.oracle_schema cms_oracle_schema
		  FROM csr.customer c
		  JOIN cms.app_schema aps on aps.app_sid = c.app_sid
		 WHERE c.app_sid = v_app_sid
		 MINUS
		SELECT oracle_schema
		  FROM cms.sys_schema;

	OPEN out_website_cur FOR
		select website_name
		  from security.website
		 where application_sid_id = v_app_sid;
END;

PROCEDURE DeleteCMSDelegDependencies
AS
BEGIN
	DELETE FROM csr.delegation_grid_aggregate_ind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM csr.deleg_grid_variance
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM csr.delegation_grid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DoZap
AS
BEGIN

	DeleteCMSDelegDependencies;

	cms.zap_pkg.DoZap;

	csr.csr_app_pkg.DeleteApp(
		in_reduce_contention => 1,
		in_debug_log_deletes => 1,
		in_logoff_before_delete_so => 1
	);

END;

END;
/
