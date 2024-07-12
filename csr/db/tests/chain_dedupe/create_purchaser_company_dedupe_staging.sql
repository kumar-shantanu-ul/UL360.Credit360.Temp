BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	-- Unregister table if there is one
	FOR r IN (
		SELECT oracle_table
		  FROM cms.tab 
		 WHERE oracle_schema = 'RAG' 
		   AND oracle_table IN ('COMPANY_PURCHASER_STAGING')
	)
	LOOP
		cms.tab_pkg.UnregisterTable(
			in_oracle_schema => 'RAG',
			in_oracle_table	 => r.oracle_table
		);
	END LOOP;

	-- Drop table if there is one
	FOR r IN (SELECT table_name FROM all_tables WHERE owner = 'RAG' AND table_name IN ('COMPANY_PURCHASER_STAGING'))
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE RAG.'||r.table_name;
	END LOOP;
END;
/

CREATE TABLE RAG.COMPANY_PURCHASER_STAGING (
	COMPANY_STAGING_ID			NUMBER(10, 0)	NOT NULL,
	BATCH_NUM					NUMBER(10, 0)	NOT NULL,
	VENDOR_NUM					VARCHAR2(255)	NOT NULL,
	VENDOR_NAME					VARCHAR2(255)	NOT NULL,
	CITY	 			 		VARCHAR2(255),
	POSTAL_CODE					VARCHAR2(255),
	COUNTRY						VARCHAR2(255),
	COMPANY_TYPE				VARCHAR2(255),
	PURCHASER_COMPANY_SID		NUMBER(10, 0),
	CONSTRAINT PK_COMPANY_PURCHASER_STAGING PRIMARY KEY (COMPANY_STAGING_ID),
	CONSTRAINT UC_COMPANY_PURCHASER_STAGING UNIQUE(VENDOR_NUM)
);
COMMENT ON COLUMN rag.COMPANY_PURCHASER_STAGING.COMPANY_STAGING_ID IS 'auto';
COMMENT ON COLUMN RAG.COMPANY_PURCHASER_STAGING.PURCHASER_COMPANY_SID IS 'desc="Purchaser Company",company';

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => 'RAG',
		in_oracle_table => 'COMPANY_PURCHASER_STAGING',
		in_managed => FALSE
	);
END;
/

GRANT ALL ON RAG.COMPANY_PURCHASER_STAGING TO chain;
