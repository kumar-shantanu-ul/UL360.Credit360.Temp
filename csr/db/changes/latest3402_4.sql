-- Please update version.sql too -- this keeps clean builds in sync
define version=3402
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
