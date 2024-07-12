-- Please update version.sql too -- this keeps clean builds in sync
define version=2251
@update_header

--ddl
ALTER TABLE CSRIMP.CHAIN_COMPAN_TYPE_CAPABI MODIFY PRIMARY_COMPANY_GROUP_TYPE_ID NULL;
ALTER TABLE CSRIMP.CHAIN_COMPAN_TYPE_CAPABI ADD PRIMARY_COMPANY_TYPE_ROLE_SID NUMBER(10);

ALTER TABLE CSRIMP.CHAIN_COMPANY ADD COUNTRY_IS_HIDDEN NUMBER(1);

ALTER TABLE CSRIMP.QUICK_SURVEY DROP CONSTRAINT CHK_QUICK_SURVEY_AUDIENCE;
ALTER TABLE CSRIMP.QUICK_SURVEY ADD CONSTRAINT CHK_QUICK_SURVEY_AUDIENCE CHECK (AUDIENCE IN ('everyone','existing','chain','audit', 'chain.product'));

CREATE TABLE CSRIMP.CHAIN_COMPANY_TYPE_ROLE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	ROLE_SID			NUMBER(10, 0)	NOT NULL,
	POS					NUMBER(10)		NOT NULL,
	MANDATORY			NUMBER(1)		NOT NULL,
	CASCADE_TO_SUPPLIER	NUMBER(1)		NOT NULL,
	CONSTRAINT PK_CHAIN_COMPANY_TYPE_ROLE		PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, ROLE_SID),
	CONSTRAINT FK_CHAIN_COMPANY_TYPE_ROLE_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_SUPPLIER_RELATIONSHIP (
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PURCHASER_COMPANY_SID		NUMBER(10, 0)	NOT NULL,
	SUPPLIER_COMPANY_SID		NUMBER(10, 0)	NOT NULL,
	ACTIVE						NUMBER(1) NOT NULL,
	DELETED						NUMBER(1) NOT NULL,
	VIRTUALLY_ACTIVE_UNTIL_DTM		TIMESTAMP(6),
	VIRTUALLY_ACTIVE_KEY		NUMBER(10),
	SUPP_REL_CODE				VARCHAR2(100),
	FLOW_ITEM_ID				NUMBER(10),
	CONSTRAINT PK_CHAIN_SUPPLIER_RELATIONSHIP	PRIMARY KEY (CSRIMP_SESSION_ID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID),
	CONSTRAINT FK_CHAIN_SUPP_RELATIONSHIP_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CARD(
	CSRIMP_SESSION_ID 	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CARD_ID          NUMBER(10, 0)     NOT NULL,
	DESCRIPTION      VARCHAR2(4000)    NOT NULL,
	CLASS_TYPE       VARCHAR2(1000)    NOT NULL,
	JS_CLASS_TYPE    VARCHAR2(1000)    NOT NULL,
	JS_INCLUDE       VARCHAR2(1000)    NOT NULL,
	CSS_INCLUDE      VARCHAR2(1000),
	CONSTRAINT PK_CHAIN_CARD PRIMARY KEY (CARD_ID),
	CONSTRAINT UC_CHAIN_CARD_JS  UNIQUE (JS_CLASS_TYPE),
	CONSTRAINT FK_CHAIN_CARD_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CARD(
	CSRIMP_SESSION_ID 	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CARD_ID			NUMBER(10, 0)	NOT NULL,
	NEW_CARD_ID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CARD  PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CARD_ID),
	CONSTRAINT UK_MAP_CHAIN_CARD  UNIQUE (CSRIMP_SESSION_ID, NEW_CARD_ID),
	CONSTRAINT FK_MAP_CHAIN_CARD_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CARD_GROUP_CARD(
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CARD_GROUP_ID              NUMBER(10, 0)    NOT NULL,
	CARD_ID                    NUMBER(10, 0)    NOT NULL,
	POSITION                   NUMBER(10, 0)    NOT NULL,
	REQUIRED_PERMISSION_SET    NUMBER(10, 0),
	REQUIRED_CAPABILITY_ID     NUMBER(10, 0),
	INVERT_CAPABILITY_CHECK    NUMBER(1, 0)    NOT NULL,
	FORCE_TERMINATE            NUMBER(1, 0)    NOT NULL,
	CONSTRAINT PK_CHAIN_CARD_GROUP_CARD PRIMARY KEY (CSRIMP_SESSION_ID, CARD_GROUP_ID, CARD_ID),
	CONSTRAINT FK_CHAIN_CARD_GROUP_CARD_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CARD_GROUP_PROGRESSION(
    CSRIMP_SESSION_ID 	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    CARD_GROUP_ID       NUMBER(10, 0)    NOT NULL,
    FROM_CARD_ID        NUMBER(10, 0)    NOT NULL,
    FROM_CARD_ACTION    VARCHAR2(100)    NOT NULL,
    TO_CARD_ID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CHAIN_CARD_GROUP_PROGR PRIMARY KEY (CSRIMP_SESSION_ID, CARD_GROUP_ID, FROM_CARD_ID, FROM_CARD_ACTION),
	CONSTRAINT FK_CHAIN_CARD_GROUP_PROGR_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
)
;

CREATE TABLE CSRIMP.CHAIN_CARD_INIT_PARAM(
	CSRIMP_SESSION_ID 	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    CARD_ID          NUMBER(10, 0)    NOT NULL,
    PARAM_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    KEY              VARCHAR2(255)    NOT NULL,
    VALUE            VARCHAR2(255)    NOT NULL,
    CARD_GROUP_ID    NUMBER(10, 0),
	CONSTRAINT CHK_CHAIN_CARD_INIT_PARAM_TYPE CHECK ((PARAM_TYPE_ID = 0 /* GLOBAL */ AND CARD_GROUP_ID IS NULL) OR (PARAM_TYPE_ID = 1 /* SPECIFIC */ AND CARD_GROUP_ID IS NOT NULL)),
	CONSTRAINT FK_CHAIN_CARD_INIT_PARAM_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
)
;

-- grants
grant select, insert, update, delete on csrimp.chain_company_type_role to web_user;
grant select, insert, update, delete on csrimp.chain_supplier_relationship to web_user;
grant select, insert, update, delete on csrimp.chain_card to web_user;
grant select, insert, update, delete on csrimp.chain_card_group_card to web_user;
grant select, insert, update, delete on csrimp.chain_card_group_progression to web_user;
grant select, insert, update, delete on csrimp.chain_card_init_param to web_user;

grant select, insert, update on chain.company_type_role to csrimp;
grant select, insert, update on chain.company_type_role to CSR;

grant select on chain.card to csrimp;
grant select on chain.card to csr;

grant select, insert, update on chain.supplier_relationship to csrimp;
grant select, insert, update on chain.supplier_relationship to CSR;

grant select, insert, update on chain.card_group_progression to csrimp;
grant select, insert, update on chain.card_group_progression to CSR;

grant select, insert, update on chain.card_group_card to csrimp;
grant select, insert, update on chain.card_group_card to CSR;

grant select, insert, update on chain.card_init_param to csrimp;
grant select, insert, update on chain.card_init_param to CSR;


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
