BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	-- Unregister table if there is one
	FOR r IN (
		SELECT oracle_table
		  FROM cms.tab 
		 WHERE oracle_schema = 'RAG' 
		   AND oracle_table IN ('COMPANY_STAGING')
	)
	LOOP
		cms.tab_pkg.UnregisterTable(
			in_oracle_schema => 'RAG',
			in_oracle_table	 => r.oracle_table
		);
	END LOOP;

	-- Drop table if there is one
	FOR r IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'RAG' AND TABLE_NAME IN ('COMPANY_STAGING'))
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE rag.'||r.TABLE_NAME;
	END LOOP;
END;
/

CREATE TABLE rag.COMPANY_STAGING (
	COMPANY_STAGING_ID		NUMBER(10, 0)	NOT NULL,
	VENDOR_NUM				VARCHAR2(255)	NOT NULL,
	VENDOR_NAME				VARCHAR2(255)	NOT NULL,
	CITY	 			 	VARCHAR2(255),
	POSTAL_CODE				VARCHAR2(255),
	STREET					VARCHAR2(255),
	COUNTRY					VARCHAR2(255),
	STATE					VARCHAR2(255),
	WEBSITE					VARCHAR2(255),
	FACILITY_TYPE			VARCHAR2(255),
	EMAIL					VARCHAR(255),
	ADDRESS_1				VARCHAR2(255),
	ADDRESS_2				VARCHAR2(255),
	ADDRESS_3				VARCHAR2(255),
	ADDRESS_4				VARCHAR2(255),
	CONSTRAINT PK_COMPANY_STAGING PRIMARY KEY (COMPANY_STAGING_ID),
	CONSTRAINT UC_COMPANY_STAGING UNIQUE(VENDOR_NUM)
);

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => 'RAG',
		in_oracle_table => 'COMPANY_STAGING',
		in_managed => FALSE
	);
END;
/

grant all on rag.COMPANY_STAGING to chain;
