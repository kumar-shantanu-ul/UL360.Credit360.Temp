-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

exec security.user_pkg.logonadmin('');

ALTER TABLE CHAIN.BSCI_OPTIONS ADD (
	USE_TEST_SERVER		 			NUMBER(1) DEFAULT 0 NOT NULL,
	UPDATE_LATEST_AUDIT_ONLY		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_SUPPLIER_SYNC_ENABLED CHECK (SUPPLIER_SYNC_ENABLED IN (0,1)),
	CONSTRAINT CHK_USE_TEST_SERVER CHECK (USE_TEST_SERVER IN (0,1)),
	CONSTRAINT CHK_UPDATE_LATEST_AUDIT_ONLY CHECK (UPDATE_LATEST_AUDIT_ONLY IN (0,1))
);


ALTER TABLE CHAIN.BSCI_FINDING DROP CONSTRAINT FK_BSCI_AUDIT_REF_FIND;
ALTER TABLE CHAIN.BSCI_ASSOCIATE DROP CONSTRAINT FK_BSCI_AUDIT_REF_ASS;
ALTER TABLE CHAIN.BSCI_AUDIT DROP CONSTRAINT PK_BSCI_AUDIT;
ALTER TABLE CHAIN.BSCI_AUDIT ADD CONSTRAINT PK_BSCI_AUDIT PRIMARY KEY (APP_SID, COMPANY_SID, AUDIT_REF);


ALTER TABLE CHAIN.BSCI_FINDING ADD COMPANY_SID NUMBER(10,0) NULL;
UPDATE chain.bsci_finding bf SET company_sid = (SELECT company_sid FROM chain.bsci_audit ba WHERE ba.audit_ref = bf.audit_ref AND ba.app_sid = bf.app_sid);
DELETE FROM chain.bsci_finding WHERE company_sid IS NULL;
ALTER TABLE CHAIN.BSCI_FINDING MODIFY COMPANY_SID NOT NULL;
ALTER TABLE CHAIN.BSCI_FINDING ADD CONSTRAINT FK_BSCI_AUDIT_REF_FIND FOREIGN KEY (APP_SID, COMPANY_SID, AUDIT_REF) REFERENCES CHAIN.BSCI_AUDIT (APP_SID, COMPANY_SID, AUDIT_REF);

ALTER TABLE CHAIN.BSCI_ASSOCIATE ADD COMPANY_SID NUMBER(10,0) NULL;
UPDATE chain.bsci_associate bs SET company_sid = (SELECT company_sid FROM chain.bsci_audit ba WHERE ba.audit_ref = bs.audit_ref AND ba.app_sid = bs.app_sid);
DELETE FROM chain.bsci_associate WHERE company_sid IS NULL;
ALTER TABLE CHAIN.BSCI_ASSOCIATE MODIFY COMPANY_SID NOT NULL;
ALTER TABLE CHAIN.BSCI_ASSOCIATE ADD CONSTRAINT FK_BSCI_AUDIT_REF_ASS FOREIGN KEY (APP_SID, COMPANY_SID, AUDIT_REF) REFERENCES CHAIN.BSCI_AUDIT (APP_SID, COMPANY_SID, AUDIT_REF);


ALTER TABLE CSRIMP.CHAIN_BSCI_OPTIONS ADD (
	USE_TEST_SERVER		 			NUMBER(1) NOT NULL,
	UPDATE_LATEST_AUDIT_ONLY		NUMBER(1) NOT NULL
);

ALTER TABLE CHAIN.BSCI_SUPPLIER DROP CONSTRAINT UK_BSCI_SUPPLIER_ID;
ALTER TABLE CHAIN.BSCI_SUPPLIER DROP CONSTRAINT UK_BSCI_SUP_NAME_COUNTRY;
ALTER TABLE CHAIN.BSCI_SUPPLIER MODIFY ADDRESS VARCHAR2(255) NULL;
ALTER TABLE CHAIN.BSCI_SUPPLIER MODIFY CITY VARCHAR2(255) NULL;

ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER MODIFY ADDRESS VARCHAR2(255) NULL;
ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER MODIFY CITY VARCHAR2(255) NULL;

ALTER TABLE CSRIMP.CHAIN_BSCI_FINDING ADD COMPANY_SID NUMBER(10,0) NOT NULL;
ALTER TABLE CSRIMP.CHAIN_BSCI_ASSOCIATE ADD COMPANY_SID NUMBER(10,0) NOT NULL;

ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT DROP CONSTRAINT PK_BSCI_AUDIT;
ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT ADD CONSTRAINT PK_BSCI_AUDIT PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID, AUDIT_REF);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (75, 'in_allow_duplicate_companies', 7, 'Should duplicate BSCI IDs be allowed? Y/N');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (75, 'in_use_test_server', 8, 'Use test BSCI server? Y/N');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (75, 'in_update_latest_audit_only', 9, 'Only update latest audit? Y/N');

-- dsg specific bit

BEGIN
	BEGIN
		security.user_pkg.logonadmin('dsg-responsibleprocurement.credit360.com');
		UPDATE chain.reference SET reference_uniqueness_id = 0 WHERE lookup_key = 'BSCI_ID';
		security.user_pkg.logonadmin('');
	EXCEPTION
		WHEN others THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
	
@../audit_pkg
@../enable_pkg
@../chain/bsci_pkg

@../audit_body
@../enable_body
@../chain/bsci_body
@../csrimp/imp_body
@../schema_body

@update_tail
