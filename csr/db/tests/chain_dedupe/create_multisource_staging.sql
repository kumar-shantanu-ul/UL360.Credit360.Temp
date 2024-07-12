DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(30); --table names
	v_list t_tabs := t_tabs(
		'COMPANY_STAGING',
		'USER_STAGING',
		'CMS_STAGING',
		'PRODUCT',
		'COMPANY_PRODUCT',
		'SCORE_BAND',
		'COMPANY_EXTRA'
	); 
BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	-- Unregister table if there is one
	FOR i IN 1 .. v_list.COUNT 
	LOOP
		FOR r IN (
			SELECT oracle_table
			  FROM cms.tab 
			 WHERE oracle_schema = 'RAG' 
			   AND oracle_table = v_list(i)
		)
		LOOP
			cms.tab_pkg.UnregisterTable(
				in_oracle_schema => 'RAG',
				in_oracle_table	 => r.oracle_table
			);
		END LOOP;
	END LOOP;

	FOR i IN 1 .. v_list.COUNT 
	LOOP
		cms.tab_pkg.DropTable('RAG', v_list(i), true);
	END LOOP;
END;
/

CREATE TABLE rag.COMPANY_STAGING (
	COMPANY_STAGING_ID		NUMBER(10, 0)	NOT NULL,
	BATCH_NUM				NUMBER			NOT NULL,
	COMPANY_ID				VARCHAR2(255)	NOT NULL,
	SOURCE					VARCHAR2(255)	NOT NULL,
	NAME					VARCHAR2(255)	NOT NULL,
	COUNTRY					VARCHAR2(255)	NOT NULL,
	REVENUE					NUMBER(10,2),
	SCORE_BAND				VARCHAR2(255),
	SCORE					NUMBER(10,2),
	ASSESSMENT_DATE			DATE,
	COMMENTS				VARCHAR2(255),
	EXPENSES_STRING			VARCHAR2(255),
	PURCHASER_SID			NUMBER(10)		DEFAULT NULL,
	CONSTRAINT PK_COMPANY_STAGING PRIMARY KEY (COMPANY_STAGING_ID),
	CONSTRAINT UC_COMPANY_STAGING UNIQUE(COMPANY_ID, BATCH_NUM, SOURCE)
);

COMMENT ON COLUMN rag.COMPANY_STAGING.COMPANY_STAGING_ID IS 'auto';

CREATE TABLE rag.USER_STAGING(
	USER_STAGING_ID			NUMBER(10, 0)	NOT NULL,
	BATCH_NUM				NUMBER			NOT NULL,
	COMPANY_ID				VARCHAR2(255)	NOT NULL,
	SOURCE					VARCHAR2(255)	NOT NULL,
	FULLNAME				VARCHAR2(255)	NOT NULL,
	USERNAME				VARCHAR2(255)	NOT NULL,
	EMAIL					VARCHAR2(255),
	ROLE_1					NUMBER(1),
	CONSTRAINT PK_USER_STAGING PRIMARY KEY (USER_STAGING_ID)
);

CREATE TABLE rag.CMS_STAGING(
	CMS_STAGING_ID		NUMBER(10, 0)	NOT NULL,
	COMPANY_ID			VARCHAR2(255)	NOT NULL,
	SOURCE				VARCHAR2(255)	NULL,
	BATCH_NUM			NUMBER(10, 0)	NULL, 
	REVENUE				VARCHAR2(255)	NOT NULL,
	PRODUCT_DESCRIPTION	VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_CMS_STAGING PRIMARY KEY (CMS_STAGING_ID)
);

CREATE TABLE rag.PRODUCT(
	PRODUCT_ID			NUMBER(10, 0)	NOT NULL,
	DESCRIPTION			VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_PRODUCT PRIMARY KEY (PRODUCT_ID)
);

CREATE TABLE rag.COMPANY_PRODUCT (
	COMPANY_PRODUCT_ID		NUMBER(10, 0)	NOT NULL,
	COMPANY_SID				NUMBER(10, 0)	NOT NULL,
	REVENUE					VARCHAR2(255)	NOT NULL,
	PRODUCT_ID				NUMBER			NOT NULL,
	CONSTRAINT PK_COMPANY_PRODUCT PRIMARY KEY (COMPANY_PRODUCT_ID),
	CONSTRAINT UC_COMPANY_PRODUCT UNIQUE (COMPANY_SID, PRODUCT_ID)
);

ALTER TABLE rag.COMPANY_PRODUCT ADD CONSTRAINT FK_COMPANY_PRODUCT
	FOREIGN KEY (PRODUCT_ID)
	REFERENCES rag.PRODUCT(PRODUCT_ID);

COMMENT ON COLUMN rag.COMPANY_PRODUCT.COMPANY_PRODUCT_ID IS 'auto';
COMMENT ON COLUMN rag.COMPANY_PRODUCT.PRODUCT_ID IS 'desc="Product",enum,enum_desc_col=description';
COMMENT ON COLUMN rag.COMPANY_PRODUCT.COMPANY_SID IS 'desc="Company",company';

CREATE TABLE rag.SCORE_BAND (
	SCORE_BAND_ID			NUMBER(10, 0) NOT NULL,
	DESCRIPTION				VARCHAR2(255),
	CONSTRAINT PK_SCORE_BAND PRIMARY KEY (SCORE_BAND_ID)
);

CREATE TABLE rag.COMPANY_EXTRA (
	COMPANY_SID				NUMBER(10, 0)	NOT NULL,
	REVENUE					NUMBER(10,2),
	SCORE_BAND_ID			NUMBER(10),
	SCORE					NUMBER(10,2),
	ASSESSMENT_DATE			DATE,
	COMMENTS				VARCHAR2(255),
	EXPENSES_STRING			VARCHAR2(255),
	PURCHASER_SID			NUMBER(10),
	CONSTRAINT PK_COMPANY_EXTRA PRIMARY KEY (COMPANY_SID)
);

ALTER TABLE rag.COMPANY_EXTRA ADD CONSTRAINT FK_COMPANY_EXTRA_BAND
	FOREIGN KEY (SCORE_BAND_ID)
	REFERENCES rag.SCORE_BAND(SCORE_BAND_ID);

COMMENT ON COLUMN rag.COMPANY_EXTRA.COMPANY_SID IS 'company';
COMMENT ON COLUMN rag.COMPANY_EXTRA.SCORE_BAND_ID IS 'desc="Band",enum,enum_desc_col=description';

GRANT SELECT, INSERT, UPDATE, DELETE ON RAG.COMPANY_PRODUCT TO CHAIN;
GRANT SELECT, INSERT, DELETE ON RAG.PRODUCT TO CHAIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON RAG.COMPANY_STAGING TO CHAIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON RAG.USER_STAGING TO CHAIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON RAG.CMS_STAGING TO CHAIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON RAG.COMPANY_EXTRA TO CHAIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON RAG.SCORE_BAND TO CHAIN;

DECLARE
	v_tabs VARCHAR2(4000);
BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	v_tabs := 'PRODUCT,COMPANY_PRODUCT,COMPANY_STAGING,USER_STAGING,CMS_STAGING,SCORE_BAND,COMPANY_EXTRA';
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => 'RAG',
		in_oracle_table => v_tabs,
		in_managed => FALSE
	);
END;
/
