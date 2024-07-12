-- Please update version.sql too -- this keeps clean builds in sync
define version=1894
@update_header

/* various grants */
grant execute on csr.audit_pkg to chain;
grant select, references on csr.internal_audit to chain;
grant select on csr.region_role_member to chain;
grant select on csr.internal_audit_type to chain;
grant select on csr.v$audit to chain;

/* Add invitation_id, also chain_company can be null */
CREATE OR REPLACE VIEW chain.v$company_invitation_status AS
SELECT i.company_sid, i.invitation_status_id, st.filter_description invitation_status_description, i.invitation_id
  FROM (
	SELECT to_company_sid company_sid, invitation_status_id, invitation_id FROM (
		SELECT to_company_sid,
				NVL(DECODE(invitation_status_id,
					6, 7,--chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.REJECTED_NOT_EMPLOYEE
					4, 5),--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
					invitation_status_id) invitation_status_id,
				ROW_NUMBER() OVER (PARTITION BY to_company_sid ORDER BY DECODE(invitation_status_id, 
					5, 1,--chain_pkg.ACCEPTED, 1,
					4, 1,--chain_pkg.PROVISIONALLY_ACCEPTED, 1,
					1, 2,--chain_pkg.ACTIVE, 2,
					2, 3, --chain_pkg.EXPIRED, 3,
					3, 3, --chain_pkg.CANCELLED, 3,
					6, 3, --chain_pkg.REJECTED_NOT_EMPLOYEE, 3,
					7, 3 --chain_pkg.REJECTED_NOT_SUPPLIER, 3
				), sent_dtm DESC) rn,
				invitation_id
		  FROM invitation
		 WHERE from_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), from_company_sid)
		)
	 WHERE rn = 1
	 UNION
	SELECT company_sid, 10 /* chain_pkg.NOT_INVITED */, NULL invitation_id
	  FROM v$company
	 WHERE company_sid NOT IN (
		SELECT to_company_sid
		  FROM invitation
		 WHERE from_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), from_company_sid)
		)
	) i
  JOIN invitation_status st on i.invitation_status_id = st.invitation_status_id;
  

/* Create SUPPLIER_AUDIT TABLE */  
CREATE TABLE CHAIN.SUPPLIER_AUDIT(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    AUDIT_SID                 NUMBER(10, 0)    NOT NULL,
    AUDITOR_COMPANY_SID       NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID      NUMBER(10, 0)    NOT NULL,
    CREATED_BY_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SUPPLIER_AUDIT PRIMARY KEY (APP_SID, AUDIT_SID)
)
;
ALTER TABLE CHAIN.SUPPLIER_AUDIT ADD CONSTRAINT FK_AUDIT_AUDITOR_COMPANY 
    FOREIGN KEY (APP_SID, AUDITOR_COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;
ALTER TABLE CHAIN.SUPPLIER_AUDIT ADD CONSTRAINT FK_AUDIT_CREATED_BY_COMPANY 
    FOREIGN KEY (APP_SID, CREATED_BY_COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;
ALTER TABLE CHAIN.SUPPLIER_AUDIT ADD CONSTRAINT FK_AUDIT_SUPPLIER_COMPANY 
    FOREIGN KEY (APP_SID, SUPPLIER_COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;  
--cross_schema_constraint
ALTER TABLE CHAIN.SUPPLIER_AUDIT ADD CONSTRAINT FK_SUPPL_AUDIT_INTERNAL_AUDIT
	FOREIGN KEY (APP_SID, AUDIT_SID)
	REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID)
;

/*  rls policy for chain.supplier_audit */
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CHAIN',
			object_name     => 'SUPPLIER_AUDIT',
			policy_name     => 'SUPPLIER_AUDIT_POLICY',
			function_schema => 'CHAIN',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive 
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
		WHEN FEATURE_NOT_ENABLED THEN
			dbms_output.put_line('RLS policies not applied for "CHAIN.SUPPLIER_AUDIT" as feature not enabled');
	END;
END;
/

/*Add supplier audit card*/
@@latest1894_packages
BEGIN
	security.user_pkg.logonadmin;
	
	dbms_output.put_line('Creating SupplierAudit card');	
	-- SupplierAudit
	chain.temp_card_pkg.RegisterCard(
		'View of the supplier''s audits',
		'Credit360.Chain.Cards.SupplierAudit',
		'/csr/site/chain/cards/supplierAudit.js', 
		'Chain.Cards.SupplierAudit'
	);		
END;
/

/*Add new supplier audit capabilities */
BEGIN
	security.user_pkg.logonadmin;
	dbms_output.put_line('Add new supplier audit capabilities');
	
	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.CREATE_SUPPL_AUDIT_ON_BEHLF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY); */
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Create supplier audit on behalf of', 3, 1, 1);
	
	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_SUPPLIER_AUDITS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY); */
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'View supplier audits', 2, 1, 1);
END;
/

@../chain/chain_pkg
@../chain/supplier_audit_pkg

@../supplier_body
@../chain/chain_body
@../chain/company_body
@../chain/supplier_audit_body

DROP PACKAGE chain.temp_card_pkg;
  
@update_tail
