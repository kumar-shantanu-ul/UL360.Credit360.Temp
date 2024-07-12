whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DEFINE host = '&&1'
DEFINE usr = '&&2'

spool createHoldingTable.log;

PROMPT ====================================================
PROMPT > Creating and registering holding table
PROMPT ===================================================

DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(30);  --table names
	v_list t_tabs := t_tabs(
		'COMPANY_STAGING');
	v_count			NUMBER(10);
BEGIN
	--cms.tab_pkg.enabletrace;
	SELECT count(*) 
	  INTO v_count
	  FROM all_users 
	 WHERE username = upper('&&usr');
	 
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE USER &&usr IDENTIFIED BY &&usr TEMPORARY TABLESPACE TEMP DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS';
	ELSE
		security.user_pkg.LogonAdmin('&&host');
		cms.tab_pkg.enabletrace;
		FOR i IN 1 .. v_list.COUNT 
		LOOP
			cms.tab_pkg.DropTable('&&usr', v_list(i), true);
		END LOOP;
	END IF;

END;
/

CREATE TABLE &&usr..COMPANY_STAGING(
	COMPANY_STAGING_ID		NUMBER(10, 0)	NOT NULL,
	COMPANY_REF				NUMBER(10, 0)	NOT NULL,
	FEED_ID					NUMBER(10, 0)	NOT NULL,
	COMPANY_TYPE_LOOKUP		VARCHAR2(255),
	CREATED_DTM				DATE	DEFAULT SYSDATE,
	NAME					VARCHAR2(255)	NOT NULL,
	ACTIVATED_DTM			DATE,
	ACTIVE					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ADDRESS_1				VARCHAR2(255),
	ADDRESS_2				VARCHAR2(255),
	ADDRESS_3				VARCHAR2(255),
	ADDRESS_4				VARCHAR2(255),
	STATE					VARCHAR2(255),
	POSTCODE				VARCHAR2(255),
	COUNTRY_CODE			VARCHAR2(2)	NOT NULL,
	PHONE					VARCHAR2(255),
	FAX						VARCHAR2(255),
	WEBSITE					VARCHAR2(1000),
	EMAIL					VARCHAR2(255),
	DELETED					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	SECTOR			 		VARCHAR2(255),
	SUPP_REL_CODE_LABEL		VARCHAR2(100),
	CITY	 			 	VARCHAR2(255),
	DEACTIVATED_DTM			DATE,
	CONSTRAINT COMPANY_STAGING PRIMARY KEY (COMPANY_STAGING_ID),
	CONSTRAINT UC_COMPANY_STAGING UNIQUE (COMPANY_REF, FEED_ID)
);

BEGIN
	security.user_pkg.logonadmin('&&host');
	cms.tab_pkg.enabletrace;
	cms.tab_pkg.registertable(UPPER('&&usr'),'COMPANY_STAGING', FALSE);	
END;
/

GRANT SELECT ON &&usr..COMPANY_STAGING TO CHAIN;

@populateCompanyStaging

spool off;

