DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_errm						VARCHAR2(1000);
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.internal_audit
		 WHERE flow_item_id IS NULL AND deleted = 0
		 UNION
		SELECT DISTINCT app_sid
		  FROM csr.internal_audit_type
		 WHERE flow_sid IS NULL
	)
	LOOP
		v_act_id := NULL;
		BEGIN
			security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 172800, r.app_sid, v_act_id);
		
		-- Don't need to log anything - ValidateSiteMigration does this
			IF csr.audit_migration_pkg.ValidateSiteMigration = csr.audit_migration_pkg.VALID_SUCCESS THEN
				csr.audit_migration_pkg.MigrateAudits;
				security.security_pkg.DebugMsg('Migrated non-WF audits for app sid ' || r.app_sid);
			ELSE
				security.security_pkg.DebugMsg('Unable to migrate non-WF audits for app sid ' || r.app_sid);
			END IF;
		
			security.user_pkg.Logoff(v_act_id);
			COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				v_errm := SUBSTR(SQLERRM, 1, 1000);
				ROLLBACK;
				IF v_act_id IS NOT NULL THEN
					security.user_pkg.Logoff(v_act_id);
				END IF;
				security.security_pkg.DebugMsg('Unexpected error migrating audits for app sid ' || r.app_sid || ' | ' || v_errm);
		END;
	END LOOP;
END;
/