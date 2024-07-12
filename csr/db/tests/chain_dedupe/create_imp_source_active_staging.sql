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
			in_oracle_schema	=> 'RAG',
			in_oracle_table		=> r.oracle_table
		);
	END LOOP;

	-- Drop table if there is one
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'RAG'
		   AND table_name IN ('COMPANY_STAGING')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE rag.'||r.table_name;
	END LOOP;
END;
/

CREATE TABLE rag.company_staging (
	company_staging_id		NUMBER(10, 0)	NOT NULL,
	vendor_num				NUMBER(10, 0)	NOT NULL,
	batch_num				NUMBER(10, 0)	NOT NULL,
	vendor_name				VARCHAR2(255)	NOT NULL,
	city	 			 	VARCHAR2(255),
	country					VARCHAR2(255),
	active					NUMBER(1, 0),
	activated_dtm			DATE,
	deactivated_dtm			DATE,
	CONSTRAINT pk_company_staging PRIMARY KEY (company_staging_id),
	CONSTRAINT uc_company_staging UNIQUE(vendor_num, batch_num)
);

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema		=> 'RAG',
		in_oracle_table			=> 'COMPANY_STAGING',
		in_managed				=> FALSE
	);
END;
/
GRANT SELECT, INSERT, UPDATE, DELETE ON rag.company_staging TO chain;

