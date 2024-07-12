-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.dedupe_processed_record ADD created_company_sid NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedup_proce_record ADD created_company_sid NUMBER(10, 0);

ALTER TABLE chain.dedupe_processed_record ADD CONSTRAINT fk_dedupe_proc_record_company
	FOREIGN KEY (app_sid, created_company_sid)
	REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.tt_dedupe_processed_row ADD created_company_sid NUMBER(10, 0);
ALTER TABLE chain.tt_dedupe_processed_row ADD created_company_name VARCHAR(512);

CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_COMPANY_ROW AS 
	OBJECT ( 
		NAME				VARCHAR2(255),
		PARENT_COMPANY_NAME	VARCHAR2(255),
		COMPANY_TYPE		VARCHAR2(255),
		CREATED_DTM			DATE,
		ACTIVATED_DTM		DATE,
		ACTIVE				NUMBER(1),
		ADDRESS				VARCHAR2(512),
		STATE				VARCHAR2(255),
		POSTCODE			VARCHAR2(32),
		COUNTRY_CODE		VARCHAR2(255),
		PHONE				VARCHAR2(255),
		FAX					VARCHAR2(255),
		WEBSITE				VARCHAR2(255),
		EMAIL				VARCHAR2(255),
		DELETED				NUMBER(1),
		SECTOR				VARCHAR2(255),
		CITY				VARCHAR2(255),
		DEACTIVATED_DTM		DATE,
		CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
		RETURN self AS RESULT
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_DEDUPE_COMPANY_ROW AS
  CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
	RETURN SELF AS RESULT
	AS
	BEGIN
		RETURN;
	END;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_pkg
@../chain/company_dedupe_pkg

@../chain/company_body
@../chain/company_dedupe_body

@../schema_body
@../csrimp/imp_body

@update_tail
