-- Please update version.sql too -- this keeps clean builds in sync
define version=2252
@update_header

--ddl
begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

ALTER TABLE CSRIMP.SECTION_CART ADD SECTION_CART_FOLDER_ID	NUMBER(10, 0) NOT NULL;

CREATE TABLE CSRIMP.SECTION_CART_FOLDER (
	CSRIMP_SESSION_ID 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SECTION_CART_FOLDER_ID	NUMBER(10, 0)	NOT NULL,
	PARENT_ID				NUMBER(10, 0),
	NAME					VARCHAR2(255)	NOT NULL,
	IS_VISIBLE				NUMBER(1, 0)	NOT NULL,
	IS_ROOT					NUMBER(1, 0)	NOT NULL,
	CONSTRAINT PK_CSRIMP_SECTION_CART_FOLDER PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_CART_FOLDER_ID),
	CONSTRAINT CK_CSRIMP_SECTION_CART_FOLDER CHECK ((PARENT_ID IS NULL AND IS_ROOT = 1) OR (PARENT_ID IS NOT NULL)),
	CONSTRAINT FK_SECTION_CART_FOLDER_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SECTION_CART_FOLDER (
	CSRIMP_SESSION_ID 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SECTION_CART_FOLDER_ID	NUMBER(10, 0)	NOT NULL,
	NEW_SECTION_CART_FOLDER_ID	NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_MAP_SECTION_CART_FOLDER  PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SECTION_CART_FOLDER_ID),
	CONSTRAINT UK_MAP_SECTION_CART_FOLDER  UNIQUE (CSRIMP_SESSION_ID, NEW_SECTION_CART_FOLDER_ID),
	CONSTRAINT FK_MAP_SECTION_CART_FOLDER_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_SUPPLIER_FOLLOWER (
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PURCHASER_COMPANY_SID		NUMBER(10, 0)	NOT NULL,
	SUPPLIER_COMPANY_SID		NUMBER(10, 0)	NOT NULL,
	USER_SID					NUMBER(10, 0)	NOT NULL,
	IS_PRIMARY					NUMBER(1)		NULL,
	CONSTRAINT PK_CHAIN_SUPPLIER_FOLLOWER PRIMARY KEY (CSRIMP_SESSION_ID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID, USER_SID),
	CONSTRAINT FK_CHAIN_SUPPLIER_FOLLOWER_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- grants
grant select, insert, update, delete on csrimp.chain_supplier_follower to web_user;
grant select, insert, update, delete on csrimp.section_cart_folder to web_user;

grant select on csr.section_cart_folder_id_seq to csrimp;
grant select, insert, update on csr.section_cart_folder to csrimp;
grant select, insert, update on chain.supplier_follower to csrimp;
grant select, insert, update on chain.supplier_follower to CSR;

-- although not normally a good plan this only affects csrimp, not the website
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE pf_owner = 'CSRIMP' AND function IN ('SESSIONIDCHECK')
		   AND object_owner IN ('CSRIMP', 'CMS')
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => r.object_owner,
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS', 'CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

@@../schema_pkg
@@../schema_body

@@../csrimp/imp_pkg
@@../csrimp/imp_body

@update_tail
