define version=120
@update_header

ALTER TABLE chain.QUESTIONNAIRE_TYPE ADD (
    ACTIVE                   NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_HIDDEN_0_OR_1 CHECK (ACTIVE IN (0,1))
);

@latest120_chain_pkg

BEGIN
	user_pkg.logonadmin();
	chain.capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.CREATE_QUESTIONNAIRE_TYPE, chain_pkg.BOOLEAN_PERMISSION);
	
END;
/

BEGIN
	-- refresh all capabilities
	-- THIS MIGHT BE SLOW!
	FOR r IN (
		SELECT *
		  FROM chain.v$chain_host
	) LOOP
		user_pkg.logonadmin(r.host);
		
		FOR cmp IN (
			SELECT company_sid
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid <> 5
		) LOOP
			chain.capability_pkg.RefreshCompanyCapabilities(cmp.company_sid);
		END LOOP;
		
		user_pkg.Logoff(security_pkg.GetAct);
	END LOOP;
END;
/
commit;


@..\chain_pkg
@..\questionnaire_pkg
@..\questionnaire_body

@update_tail
