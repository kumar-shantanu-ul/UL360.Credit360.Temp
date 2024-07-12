-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.COMPANY_TYPE ADD (
	CREATE_DOC_LIBRARY_FOLDER 		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_CREATE_DOC_LIB_FOLDER_1_0 CHECK (CREATE_DOC_LIBRARY_FOLDER IN (1, 0))
);

ALTER TABLE CSR.DOC_FOLDER ADD (
	COMPANY_SID 					NUMBER(10),
	CONSTRAINT FK_DOC_FOLDER_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
);

ALTER TABLE CSR.DOC_FOLDER ADD (
	IS_SYSTEM_MANAGED 				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_DOC_FOLDER_IS_SYS_MNGD_1_0 CHECK (IS_SYSTEM_MANAGED IN (1, 0))
);


ALTER TABLE CSRIMP.CHAIN_COMPANY_TYPE ADD (
	CREATE_DOC_LIBRARY_FOLDER		NUMBER(1)
);

UPDATE csrimp.chain_company_type SET create_doc_library_folder = 0;
ALTER TABLE csrimp.chain_company_type MODIFY create_doc_library_folder NOT NULL;
ALTER TABLE csrimp.chain_company_type ADD CONSTRAINT chk_create_doc_lib_folder_1_0 CHECK (create_doc_library_folder IN (1, 0));

ALTER TABLE CSRIMP.DOC_FOLDER ADD (
	COMPANY_SID						NUMBER(10),
	IS_SYSTEM_MANAGED				NUMBER(1)
);

UPDATE csrimp.doc_folder SET is_system_managed = 0;
ALTER TABLE csrimp.doc_folder MODIFY is_system_managed NOT NULL;
ALTER TABLE csrimp.doc_folder ADD CONSTRAINT chk_doc_folder_is_sys_mngd_1_0 CHECK (is_system_managed IN (1, 0));

CREATE INDEX csr.ix_doc_folder_company_sid ON csr.doc_folder (app_sid, company_sid);
	  
-- *** Grants ***
GRANT INSERT, UPDATE ON csr.doc_folder TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (26, 'Add missing company folders in chain document library', 'Creates any missing company folders in the chain document library if the "Create document library folder" setting is set on the company type.', 'AddMissingCompanyDocFolders', NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../doc_folder_pkg
@../supplier_pkg
@../chain/company_type_pkg
@../util_script_pkg

@../csr_app_body
@../doc_folder_body
@../doc_lib_body
@../doc_body
@../initiative_doc_body
@../supplier_body
@../schema_body
@../chain/company_type_body
@../util_script_body
@../csrimp/imp_body


@update_tail
