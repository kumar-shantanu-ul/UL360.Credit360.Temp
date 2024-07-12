-- Please update version.sql too -- this keeps clean builds in sync
define version=2417
@update_header

/*
 *  Fully support chain in csrexp/csrimp.
 *  Part 1 - clear up some tables.
*/

-- delete ghost columns (removed from live without latest script) if exist
BEGIN
	FOR r IN (SELECT *
				FROM all_tab_columns
			   WHERE owner='CHAIN' AND (table_name, column_name) IN (
			   	('QUESTIONNAIRE_TYPE', 'XX_ALLOW_AUTO_APPROVE'),
			   	('QUESTIONNAIRE_TYPE', 'XX_ENABLE_AUTO_APPROVE'),
				('EMAIL_STUB', 'IS_AUTO_APPROVE'),
				('EMAIL_STUB', 'IS_STUB_REGISTRATION'),
				('COMPANY_TAG_GROUP', 'APPLIES_TO_SUPPLIER'))
			  ) LOOP
    BEGIN
		EXECUTE IMMEDIATE 'alter table '||r.owner||'.'||r.table_name||' drop column '||r.column_name;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
		
	END LOOP;
END;
/

BEGIN
	FOR r IN (SELECT *
				FROM all_tab_columns
			   WHERE owner='CSRIMP' AND (table_name, column_name) IN (
			   	('CHAIN_QUESTIONNAIRE_TYPE', 'XX_ALLOW_AUTO_APPROVE'),
			   	('CHAIN_QUESTIONNAIRE_TYPE', 'XX_ENABLE_AUTO_APPROVE'),
				('CHAIN_EMAIL_STUB', 'IS_AUTO_APPROVE'),
				('CHAIN_EMAIL_STUB', 'IS_STUB_REGISTRATION'),
				('CHAIN_COMPANY_TAG_GROUP', 'APPLIES_TO_SUPPLIER'))
			  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'alter table '||r.owner||'.'||r.table_name||' drop column '||r.column_name;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
		
	END LOOP;
END;
/

--Unique (csrimp counts on them when fills map tables)
ALTER TABLE chain.message_definition_lookup ADD CONSTRAINT UK_ID_DEF_PRIMARY_SECONDARY UNIQUE (message_definition_id, secondary_lookup_id, primary_lookup_id);
ALTER TABLE chain.group_capability ADD CONSTRAINT UK_ID_CAP_COMP_GROUP_PERM UNIQUE (capability_id, company_group_type_id, permission_set);


-- Drop ghost REFFILE_GROUP_FILE907 constraint
DECLARE 
	cnt NUMBER;
BEGIN
	SELECT COUNT(*)
		INTO cnt
		FROM ALL_CONSTRAINTS
	   WHERE CONSTRAINT_NAME = 'REFFILE_GROUP_FILE907'
         AND TABLE_NAME = 'FILE_GROUP' 
         AND OWNER = 'CHAIN';

	IF (cnt > 0) THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.file_group DROP CONSTRAINT REFFILE_GROUP_FILE907';
	END IF;
END;
/

--csrimp.home_page needs host column otherwise csrimp could fail (PK violation)
DROP TABLE CSRIMP.HOME_PAGE;

CREATE TABLE CSRIMP.HOME_PAGE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SID_ID     NUMBER(10, 0)    NOT NULL,
    URL        VARCHAR2(900)    NOT NULL,
	HOST       VARCHAR2(255)    NOT NULL,		--new column
    CONSTRAINT PK_HOME_PAGE PRIMARY KEY (CSRIMP_SESSION_ID, SID_ID, HOST),
    CONSTRAINT FK_HOME_PAGE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on security.home_page to csrimp;
grant insert,select,update,delete on csrimp.home_page to web_user;

--MODESEQ column must be imported as well
ALTER TABLE CSRIMP.MAIL_MESSAGE ADD MODSEQ NUMBER(20, 0) DEFAULT 1 NOT NULL;

@update_tail