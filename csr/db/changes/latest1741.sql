-- Please update version.sql too -- this keeps clean builds in sync
define version=1741
@update_header


CREATE TABLE CHAIN.TERTIARY_RELATIONSHIPS(
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    PRIMARY_COMPANY_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    SECONDARY_COMPANY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    TERTIARY_COMPANY_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TERTIARY_RELATIONSHIPS PRIMARY KEY (APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID, TERTIARY_COMPANY_TYPE_ID)
);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'TERTIARY_RELATIONSHIPS',
		policy_name     => 'TERTIARY_RELATIONSHIPS_POL', 
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
END;
/

BEGIN
	INSERT INTO CHAIN.TERTIARY_RELATIONSHIPS
	(app_sid, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id)
	SELECT UNIQUE app_sid, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id
	  FROM chain.company_type_capability
	 WHERE primary_company_type_id IS NOT NULL
	   AND secondary_company_type_id IS NOT NULL
	   AND tertiary_company_type_id IS NOT NULL;
END;
/

ALTER TABLE CHAIN.TERTIARY_RELATIONSHIPS ADD CONSTRAINT FK_TR_CTR_RELATIONSHIP 
    FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.TERTIARY_RELATIONSHIPS ADD CONSTRAINT FK_TR_CTR_RELATIONSHIP_2 
    FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ID, TERTIARY_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_TR_RELATIONSHIP 
    FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID, TERTIARY_COMPANY_TYPE_ID)
    REFERENCES CHAIN.TERTIARY_RELATIONSHIPS(APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID, TERTIARY_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY DROP CONSTRAINT FK_CTC_CTR_RELATIONSHIP_2;


@..\chain\chain_link_pkg
@..\supplier_pkg
@..\chain\company_type_pkg

@..\chain\chain_link_body
@..\chain\chain_body
@..\chain\company_body
@..\supplier_body
@..\chain\company_type_body
@..\chain\type_capability_body

@update_tail
