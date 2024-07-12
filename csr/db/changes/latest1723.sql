-- Please update version.sql too -- this keeps clean builds in sync
define version=1723
@update_header

/********** CREATE NEW TABLES **********/
CREATE TABLE CHAIN.COMPANY_REFERENCE(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    LOOKUP_KEY          VARCHAR2(255)    NOT NULL,
    COMPANY_SID         NUMBER(10, 0)    NOT NULL,
    VALUE               VARCHAR2(200),
    CONSTRAINT PK_COMPANY_REFERENCE PRIMARY KEY (APP_SID, LOOKUP_KEY, COMPANY_SID)
);

CREATE TABLE CHAIN.REFERENCE(
    APP_SID                          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    LOOKUP_KEY                       VARCHAR2(255)    NOT NULL,
    DEPRICATED_REFERENCE_NUMBER      NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    FOR_COMPANY_TYPE_ID              NUMBER(10, 0),
    LABEL                            VARCHAR2(255)    NOT NULL,
    MANDATORY                        NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    REFERENCE_UNIQUENESS_ID          NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    SUPPLIER_REF_ACCESS_LEVEL_ID     NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    PURCHASER_REF_ACCESS_LEVEL_ID    NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    REFERENCE_LOCATION_ID            NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_REF_LOOKUP_KEY CHECK (LOOKUP_KEY = UPPER(TRIM(LOOKUP_KEY))),
    CONSTRAINT CHK_REF_MAND_BOOL CHECK (MANDATORY IN (0,1)),
    CONSTRAINT PK_REFERENCE PRIMARY KEY (APP_SID, LOOKUP_KEY)
);

CREATE TABLE CHAIN.REFERENCE_ACCESS_LEVEL(
    REFERENCE_ACCESS_LEVEL_ID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION                  VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK_REFERENCE_ACCESS_LEVEL PRIMARY KEY (REFERENCE_ACCESS_LEVEL_ID)
);

CREATE TABLE CHAIN.REFERENCE_LOCATION(
    REFERENCE_LOCATION_ID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION              VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK_REFERENCE_LOCATION PRIMARY KEY (REFERENCE_LOCATION_ID)
);

CREATE TABLE CHAIN.REFERENCE_UNIQUENESS(
    REFERENCE_UNIQUENESS_ID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION                VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK_REFERENCE_UNIQUENESS PRIMARY KEY (REFERENCE_UNIQUENESS_ID)
);

/********** CREATE NEW TABLE CONSTRAINTS **********/
ALTER TABLE CHAIN.COMPANY_REFERENCE ADD CONSTRAINT FK_COMPANY_COMPANY_REF 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE CHAIN.COMPANY_REFERENCE ADD CONSTRAINT FK_REF_COMPANY_REF 
    FOREIGN KEY (APP_SID, LOOKUP_KEY)
    REFERENCES CHAIN.REFERENCE(APP_SID, LOOKUP_KEY)
;

ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_CO_REFERENCE 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_CT_REFERENCE 
    FOREIGN KEY (APP_SID, FOR_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_REF_AC_REF_PURCHASER 
    FOREIGN KEY (PURCHASER_REF_ACCESS_LEVEL_ID)
    REFERENCES CHAIN.REFERENCE_ACCESS_LEVEL(REFERENCE_ACCESS_LEVEL_ID)
;

ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_REF_AC_REF_SUPPLIER 
    FOREIGN KEY (SUPPLIER_REF_ACCESS_LEVEL_ID)
    REFERENCES CHAIN.REFERENCE_ACCESS_LEVEL(REFERENCE_ACCESS_LEVEL_ID)
;

ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_REF_LOCATION_REF 
    FOREIGN KEY (REFERENCE_LOCATION_ID)
    REFERENCES CHAIN.REFERENCE_LOCATION(REFERENCE_LOCATION_ID)
;

ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_REF_UNIQUENESS_REF 
    FOREIGN KEY (REFERENCE_UNIQUENESS_ID)
    REFERENCES CHAIN.REFERENCE_UNIQUENESS(REFERENCE_UNIQUENESS_ID)
;

/********** INSERT BASEDATA **********/
BEGIN

	security.user_pkg.logonadmin;
	
	INSERT INTO CHAIN.REFERENCE_UNIQUENESS (REFERENCE_UNIQUENESS_ID, DESCRIPTION) VALUES (0, 'None'); 
	INSERT INTO CHAIN.REFERENCE_UNIQUENESS (REFERENCE_UNIQUENESS_ID, DESCRIPTION) VALUES (1, 'Country'); 
	INSERT INTO CHAIN.REFERENCE_UNIQUENESS (REFERENCE_UNIQUENESS_ID, DESCRIPTION) VALUES (2, 'Global');
	
	INSERT INTO CHAIN.REFERENCE_ACCESS_LEVEL (REFERENCE_ACCESS_LEVEL_ID, DESCRIPTION) VALUES (0, 'Hidden');
	INSERT INTO CHAIN.REFERENCE_ACCESS_LEVEL (REFERENCE_ACCESS_LEVEL_ID, DESCRIPTION) VALUES (1, 'Readable');
	INSERT INTO CHAIN.REFERENCE_ACCESS_LEVEL (REFERENCE_ACCESS_LEVEL_ID, DESCRIPTION) VALUES (2, 'Writable');
	
	INSERT INTO CHAIN.REFERENCE_LOCATION (REFERENCE_LOCATION_ID, DESCRIPTION) VALUES (0, 'Show on the company details card');
	INSERT INTO CHAIN.REFERENCE_LOCATION (REFERENCE_LOCATION_ID, DESCRIPTION) VALUES (1, 'Show on the company reference label card');
	
	chain.card_pkg.RegisterCard(
		'Company reference labels (with location set to display in ReferenceLabel card)', 
		'Credit360.Chain.Cards.CompanyReferenceLabel',
		'/csr/site/chain/cards/companyReferenceLabel.js', 
		'Chain.Cards.CompanyReferenceLabel'
	);
	/*
	card_pkg.SetGroupCards('My Company', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyReferenceLabel', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.ViewCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, TRUE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.EditCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, FALSE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CompanyReferenceLabel', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, FALSE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain_pkg.CT_COMPANY, chain_pkg.CREATE_USER, FALSE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION, FALSE);
	
	card_pkg.SetGroupCards('Supplier Details', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyReferenceLabel', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.IssuesBrowser', 'Chain.Cards.SupplierRelationship'));
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.ViewCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, TRUE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.EditCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, FALSE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.CompanyReferenceLabel', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, FALSE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.IssuesBrowser', chain_pkg.IS_TOP_COMPANY, FALSE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.SupplierRelationship', chain_pkg.IS_TOP_COMPANY, FALSE);
	*/
END;
/

/********** MOVE EXISTING DATA TO NEW STRUCTURE **********/
BEGIN

	-- transition the data from reference_id_label to the new reference table
	INSERT INTO CHAIN.REFERENCE 
	(APP_SID, LOOKUP_KEY, DEPRICATED_REFERENCE_NUMBER, FOR_COMPANY_TYPE_ID, LABEL, MANDATORY, REFERENCE_UNIQUENESS_ID, SUPPLIER_REF_ACCESS_LEVEL_ID, PURCHASER_REF_ACCESS_LEVEL_ID)
	SELECT app_sid, UPPER(TRIM(label)), reference_number, company_type_id, label, mandatory,
			DECODE(uniqueness, 'N', 0, 'C', 1, 'G', 2), DECODE(supplier_acc_lvl, 'H', 0, 'R', 1, 'W', 2), DECODE(purchaser_acc_lvl, 'H', 0, 'R', 1, 'W', 2)
	  FROM chain.reference_id_label;
	
	-- transition the data from reference values from the company table to the new company_reference table (reference_id_1)
	INSERT INTO CHAIN.COMPANY_REFERENCE
	(APP_SID, COMPANY_SID, LOOKUP_KEY, VALUE)
	SELECT c.app_sid, c.company_sid, r.lookup_key, c.reference_id_1
	  FROM chain.company c, chain.reference r
	 WHERE c.app_sid = r.app_sid
	   AND c.reference_id_1 IS NOT NULL
	   AND r.DEPRICATED_reference_number = 1;
	   
	-- transition the data from reference values from the company table to the new company_reference table (reference_id_2)
	INSERT INTO CHAIN.COMPANY_REFERENCE
	(APP_SID, COMPANY_SID, LOOKUP_KEY, VALUE)
	SELECT c.app_sid, c.company_sid, r.lookup_key, c.reference_id_2
	  FROM chain.company c, chain.reference r
	 WHERE c.app_sid = r.app_sid
	   AND c.reference_id_2 IS NOT NULL
	   AND r.DEPRICATED_reference_number = 2;

	-- transition the data from reference values from the company table to the new company_reference table (reference_id_3)
	INSERT INTO CHAIN.COMPANY_REFERENCE
	(APP_SID, COMPANY_SID, LOOKUP_KEY, VALUE)
	SELECT c.app_sid, c.company_sid, r.lookup_key, c.reference_id_3
	  FROM chain.company c, chain.reference r
	 WHERE c.app_sid = r.app_sid
	   AND c.reference_id_3 IS NOT NULL
	   AND r.DEPRICATED_reference_number = 3;
END;
/

/********** RECOMPILE PACKAGES **********/
@..\chain\chain_pkg
@..\chain\company_pkg
@..\chain\company_type_pkg
@..\chain\helper_pkg
@..\chain\type_capability_pkg

/********** RECOMPILE PACKAGE BODIES **********/

@..\chain\card_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\company_type_body
@..\chain\dev_body
@..\chain\helper_body
@..\chain\report_body
@..\chain\setup_body
@..\ct\supplier_body

/********** TEMPORARY TABLES AND VIEWS ***********/

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_REFERENCE_LABELS
(
	COMPANY_SID					NUMBER(10) 		NOT NULL,
	NAME										VARCHAR2(255)	NOT NULL,
	LOOKUP_KEY						VARCHAR2(255)	NOT NULL
)
ON COMMIT DELETE ROWS;

-- Should pull the views out that changed, not run a script that might have been updated since
--@..\chain\create_views

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, supp_rel_code_label, supp_rel_code_label_mand
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

/********** DEPRICATE OLD TABLES AND COLUMNS (TO BE REMOVED IN THE FUTURE) **********/
ALTER TABLE CHAIN.REFERENCE_ID_LABEL RENAME TO XXX_REFERENCE_ID_LABEL;

ALTER TABLE CHAIN.COMPANY RENAME COLUMN REFERENCE_ID_1 TO XXX_REFERENCE_ID_1;
ALTER TABLE CHAIN.COMPANY RENAME COLUMN REFERENCE_ID_2 TO XXX_REFERENCE_ID_2;
ALTER TABLE CHAIN.COMPANY RENAME COLUMN REFERENCE_ID_3 TO XXX_REFERENCE_ID_3;

@update_tail
