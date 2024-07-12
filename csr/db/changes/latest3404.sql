define version=3404
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;













INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Legacy Chart Wrappers (UD-13034)', 0, 'Legacy: Use legacy chart wrapper generation.');
DECLARE
	v_tenant_id     VARCHAR2(255);
    v_act           security.security_pkg.T_ACT_ID;
    v_builtin_admin security.security_pkg.T_SID_ID := 3;
    v_5_min         NUMBER := 30000;
    v_batched       NUMBER := 5;
BEGIN
	security.user_pkg.logonadmin();
	FOR c IN (
		SELECT c.app_sid
		  FROM csr.customer c
		  LEFT JOIN security.tenant t ON c.app_sid = t.application_sid_id
		 WHERE t.tenant_id IS NULL
	) LOOP
        security.user_pkg.LogonAuthenticated(
            in_sid_id       => v_builtin_admin,
            in_act_timeout  => v_5_min,
            in_app_sid      => c.app_sid,
            in_logon_type   => v_batched,
            out_act_id      => v_act
        );    
		v_tenant_id := LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '^([0-9A-F]{8})([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{12})$', '\1-\2-\3-\4-\5'));
		security.security_pkg.AddTenantIdToApp(v_tenant_id);
		COMMIT;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/






@..\deleg_plan_pkg


@..\compliance_library_report_body
@..\compliance_register_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\deleg_plan_body



@update_tail
