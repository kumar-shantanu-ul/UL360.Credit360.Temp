BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	-- Unregister table if there is one
	FOR r IN (
		SELECT oracle_table
		  FROM cms.tab
		 WHERE oracle_schema = 'RAG'
		   AND oracle_table IN ('USER_COMPANY_STAGING', 'USER_STAGING')
	)
	LOOP
		cms.tab_pkg.UnregisterTable(
			in_oracle_schema => 'RAG',
			in_oracle_table	 => r.oracle_table
		);
	END LOOP;

	-- Drop table if there is one
	FOR r IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'RAG' AND TABLE_NAME IN ('USER_COMPANY_STAGING', 'USER_STAGING'))
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE rag.'||r.TABLE_NAME;
	END LOOP;
END;
/

CREATE TABLE rag.USER_COMPANY_STAGING (
	COMPANY_STAGING_ID		NUMBER(10, 0) NOT NULL,
	COMPANY_ID				VARCHAR(64)	NOT NULL,
	COUNTRY					VARCHAR(64)	NOT NULL,
	NAME					VARCHAR(64)	NOT NULL,
	ACTIVE					NUMBER(1),
	BATCH_NUM				NUMBER(10),
	CONSTRAINT PK_USER_COMPANY_STAGING PRIMARY KEY (COMPANY_STAGING_ID),
	CONSTRAINT UC_USER_COMPANY_STAGING UNIQUE(COMPANY_ID, BATCH_NUM)
);

CREATE TABLE rag.USER_STAGING (
	USER_STAGING_ID			NUMBER(10, 0)	NOT NULL,
	COMPANY_ID				VARCHAR(64)	NOT NULL,
	USER_NAME				VARCHAR(64)	NULL,
	EMAIL					VARCHAR(128),
	FULL_NAME				VARCHAR(256),
	FIRST_NAME				VARCHAR(128),
	LAST_NAME				VARCHAR(128),
	FRIENDLY_NAME			VARCHAR(128),
	PHONE_NUM				VARCHAR(128),
	JOB						VARCHAR(128),
	CREATED_DTM				DATE,
	USER_REF				VARCHAR(128),
	ACTIVE					NUMBER(1),
	ROLE_1					NUMBER(1),
	ROLE_2					NUMBER(1),
	ROLE_3					NUMBER(1),
	ROLE_NOT_APPL			NUMBER(1),
	BATCH_NUM				NUMBER(10),
	CONSTRAINT PK_USER_STAGING PRIMARY KEY (USER_STAGING_ID)
);

GRANT SELECT, UPDATE, INSERT, DELETE ON RAG.USER_STAGING TO CHAIN;
GRANT SELECT, UPDATE, INSERT, DELETE ON RAG.USER_COMPANY_STAGING TO CHAIN;

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	cms.tab_pkg.RegisterTable(
		in_oracle_schema => 'RAG',
		in_oracle_table => 'USER_STAGING',
		in_managed => FALSE
	);

	cms.tab_pkg.RegisterTable(
		in_oracle_schema => 'RAG',
		in_oracle_table => 'USER_COMPANY_STAGING',
		in_managed => FALSE
	);
END;
/
--we are using the following tables for a combined test
@@create_cms_dedupe_staging