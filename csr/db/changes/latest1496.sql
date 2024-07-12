-- Please update version.sql too -- this keeps clean builds in sync
define version=1496
@update_header

-- add new ref code cols to supplier relationship
ALTER TABLE CHAIN.SUPPLIER_RELATIONSHIP
 ADD (SUPP_REL_CODE  VARCHAR2(100));
 
 CREATE UNIQUE INDEX CHAIN.UK_SUPP_REL_CODE ON CHAIN.SUPPLIER_RELATIONSHIP(CASE WHEN SUPP_REL_CODE IS NULL THEN NULL ELSE APP_SID||'-'||PURCHASER_COMPANY_SID||'-'||SUPP_REL_CODE END)
;

 -- add new ref code cols to UNINVITED_SUPPLIER
ALTER TABLE CHAIN.UNINVITED_SUPPLIER
 ADD (SUPP_REL_CODE  VARCHAR2(100));
 ALTER TABLE CHAIN.UNINVITED_SUPPLIER ADD CONSTRAINT CHK_UNINVITED_SUPP_CACS_SRC CHECK (((created_as_company_sid IS NULL) OR (SUPP_REL_CODE IS NULL)));

 -- add default supp code name and mand flag to company
 ALTER TABLE CHAIN.COMPANY
 ADD (SUPP_REL_CODE_LABEL  VARCHAR2(100));


BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies 
		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND object_owner = 'CHAIN'
		   AND object_name IN ('COMPANY')
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => 'CHAIN',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/
 
 ALTER TABLE CHAIN.COMPANY
 ADD (SUPP_REL_CODE_LABEL_MAND  NUMBER(10, 0)     DEFAULT 0 NOT NULL CHECK (SUPP_REL_CODE_LABEL_MAND IN (1,0))) ;

BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CHAIN' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
		   AND t.table_name IN ('COMPANY')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => r.owner,
			policy_function => (CASE WHEN r.nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
	
END;
/
 
 -- add a default supplier rel code label - if populated all new companies created with a supplier code label
 CREATE TABLE CHAIN.DEFAULT_SUPP_REL_CODE_LABEL(
    APP_SID      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    LABEL        VARCHAR2(100)    NOT NULL,
    MANDATORY    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (MANDATORY IN (1,0)),
    CONSTRAINT PK_DEF_SUPP_REL_CODE_LAB PRIMARY KEY (APP_SID)
)
;
ALTER TABLE CHAIN.DEFAULT_SUPP_REL_CODE_LABEL ADD CONSTRAINT RefCUSTOMER_OPTIONS1100 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;




CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id, c.reference_id_1, c.reference_id_2, c.reference_id_3,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, supp_rel_code_label, supp_rel_code_label_mand
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

CREATE OR REPLACE VIEW CHAIN.v$supplier_relationship AS
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, active, deleted, virtually_active_until_dtm, virtually_active_key, supp_rel_code   
	  FROM supplier_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
-- either the relationship is active, or it is virtually active for a very short period so that we can send invitations
	   AND (active = 1 OR SYSDATE < virtually_active_until_dtm)
;

@..\chain\card_pkg
@..\chain\card_body
@..\chain\company_pkg
@..\chain\company_body
@..\chain\invitation_pkg
@..\chain\invitation_body
@..\chain\uninvited_pkg
@..\chain\uninvited_body
@..\chain\company_type_pkg
@..\chain\company_type_body
@..\chain\purchased_component_pkg
@..\chain\purchased_component_body
@..\chain\dev_pkg
@..\chain\dev_body
@..\chain\setup_pkg
@..\chain\setup_body


@update_tail
