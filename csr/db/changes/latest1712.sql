-- Please update version.sql too -- this keeps clean builds in sync
define version=1712
@update_header

ALTER TABLE CHAIN.CAPABILITY DROP CONSTRAINT CHK_CAPABILITY_IS_SUPPLIER;
ALTER TABLE CHAIN.CAPABILITY ADD CONSTRAINT CHK_CAPABILITY_IS_SUPPLIER CHECK (CAPABILITY_TYPE_ID IN (0, 3) OR (CAPABILITY_TYPE_ID IN (1, 2) AND CAPABILITY_TYPE_ID = IS_SUPPLIER + 1));

ALTER TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP RENAME COLUMN COMPANY_TYPE_ID TO PRIMARY_COMPANY_TYPE_ID;
ALTER TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP RENAME COLUMN RELATED_COMPANY_TYPE_ID TO SECONDARY_COMPANY_TYPE_ID;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY RENAME COLUMN COMPANY_TYPE_ID TO PRIMARY_COMPANY_TYPE_ID;
ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY RENAME COLUMN RELATED_COMPANY_TYPE_ID TO SECONDARY_COMPANY_TYPE_ID;
ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD TERTIARY_COMPANY_TYPE_ID NUMBER(10, 0);

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_CTR_RELATIONSHIP_2 
    FOREIGN KEY (APP_SID, SECONDARY_COMPANY_TYPE_ID, TERTIARY_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY RENAME COLUMN COMPANY_GROUP_TYPE_ID TO PRIMARY_COMPANY_GROUP_TYPE_ID;

BEGIN
	INSERT INTO CHAIN.CAPABILITY_TYPE (CAPABILITY_TYPE_ID, DESCRIPTION) VALUES (3, 'Checks for performing actions on behalf of another company');
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Send questionnaire invitations on behalf of', 3, 1, 1);
	
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
	SELECT i.app_sid, i.company_type_id, i.on_behalf_of_company_type_id, i.can_invite_company_type_id, g.company_group_type_id, c.capability_id, 2
	  FROM chain.invite_on_behalf_of i, chain.capability c, chain.company_group_type g
	 WHERE c.capability_type_id = 3
	   AND c.capability_name = 'Send questionnaire invitations on behalf of'
	   AND g.name = 'Users';
END;
/

ALTER TABLE CHAIN.INVITE_ON_BEHALF_OF RENAME TO XXX_INVITE_ON_BEHALF_OF;

CREATE OR REPLACE TYPE CHAIN.T_CAPABILITY_CHECK_ROW AS 
	OBJECT ( 
		CAPABILITY_ID				NUMBER(10),
		PRIMARY_COMPANY_TYPE_ID		NUMBER(10),
		SECONDARY_COMPANY_TYPE_ID	NUMBER(10),
		TERTIARY_COMPANY_TYPE_ID	NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_CAPABILITY_CHECK_TABLE AS 
	TABLE OF CHAIN.T_CAPABILITY_CHECK_ROW;
/

grant select on chain.tt_sid_link_lookup to public;
grant execute on chain.t_capability_check_row to public;
grant execute on chain.t_capability_check_table to public;

@..\chain\chain_pkg
@..\chain\type_capability_pkg
@..\chain\setup_pkg
@..\chain\capability_pkg

@..\chain\type_capability_body
@..\chain\setup_body
@..\chain\invitation_body
@..\chain\company_body
@..\chain\capability_body

-- leave this last
CREATE UNIQUE INDEX CHAIN.UC_UNIQUE_LINK_PKG ON CHAIN.IMPLEMENTATION(APP_SID, LINK_PKG);

@update_tail
