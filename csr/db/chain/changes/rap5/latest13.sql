define rap5_version=13
@update_header

@..\..\chain_pkg
	
BEGIN
	user_pkg.logonadmin;
	
	-- UPLOADED FILE
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.UPLOADED_FILE, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.UPLOADED_FILE, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.UPLOADED_FILE, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.UPLOADED_FILE, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.UPLOADED_FILE, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ);

	FOR r IN (
		SELECT * FROM v$chain_host
	) LOOP
		user_pkg.logonadmin(r.host);
		
		FOR c IN (
			SELECT * FROM company WHERE app_sid = security_pkg.GetApp
		) LOOP
			capability_pkg.RefreshCompanyCapabilities(c.company_sid);
		END LOOP;
		
	END LOOP;
	
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE file_upload DROP COLUMN parent_sid';
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
/

ALTER TABLE file_upload MODIFY company_sid DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

@..\..\upload_pkg
@..\..\upload_body

@update_tail