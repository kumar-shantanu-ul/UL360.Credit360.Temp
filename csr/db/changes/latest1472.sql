-- Please update version.sql too -- this keeps clean builds in sync
define version=1472
@update_header

GRANT SELECT, REFERENCES ON CSR.TAG_GROUP TO CHAIN;
GRANT SELECT ON CSR.TAG_GROUP_MEMBER TO CHAIN;
GRANT REFERENCES ON CSR.TAG TO CHAIN;

CREATE TABLE CHAIN.COMPANY_TAG_GROUP (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COMPANY_SID					NUMBER(10, 0)	NOT NULL,
	TAG_GROUP_ID				NUMBER(10, 0)	NOT NULL,
	APPLIES_TO_COMPONENT		NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	APPLIES_TO_PURCHASE			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_COMP_TAG_GROUP PRIMARY KEY (APP_SID, COMPANY_SID, TAG_GROUP_ID)
);

ALTER TABLE CHAIN.COMPANY_TAG_GROUP ADD CONSTRAINT FK_COMP_TAG_GROUP_COMPANY 
	FOREIGN KEY (APP_SID, COMPANY_SID)
	REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID);
	
ALTER TABLE CHAIN.COMPANY_TAG_GROUP ADD CONSTRAINT FK_COMP_TAG_GROUP_TAG_GROUP
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP (APP_SID, TAG_GROUP_ID);
	
create index chain.ix_company_tag_g_tag_group_id on chain.company_tag_group (app_sid, tag_group_id);

CREATE TABLE CHAIN.COMPONENT_TAG (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	TAG_ID						NUMBER(10, 0)	NOT NULL,
	COMPONENT_ID				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_COMPONENT_TAG PRIMARY KEY (APP_SID, TAG_ID, COMPONENT_ID)
);

ALTER TABLE CHAIN.COMPONENT_TAG ADD CONSTRAINT FK_COMPONENT_TAG_TAG
	FOREIGN KEY (APP_SID, TAG_ID)
	REFERENCES CSR.TAG (APP_SID, TAG_ID);
	
ALTER TABLE CHAIN.COMPONENT_TAG ADD CONSTRAINT FK_COMPONENT_TAG_COMPONENT
	FOREIGN KEY (APP_SID, COMPONENT_ID)
	REFERENCES CHAIN.COMPONENT (APP_SID, COMPONENT_ID);
	
create index chain.ix_component_tag_component_id on chain.component_tag (app_sid, component_id);

CREATE TABLE CHAIN.PURCHASE_TAG (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	TAG_ID						NUMBER(10, 0)	NOT NULL,
	PURCHASE_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_PURCHASE_TAG PRIMARY KEY (APP_SID, TAG_ID, PURCHASE_ID)
);

ALTER TABLE CHAIN.PURCHASE_TAG ADD CONSTRAINT FK_PURCHASE_TAG_TAG
	FOREIGN KEY (APP_SID, TAG_ID)
	REFERENCES CSR.TAG (APP_SID, TAG_ID);
	
ALTER TABLE CHAIN.PURCHASE_TAG ADD CONSTRAINT FK_PURCHASE_TAG_COMPONENT
	FOREIGN KEY (APP_SID, PURCHASE_ID)
	REFERENCES CHAIN.PURCHASE (APP_SID, PURCHASE_ID);
	
create index chain.ix_purchase_tag_purchase_id on chain.purchase_tag (app_sid, purchase_id);
	
ALTER TABLE CSR.TAG_GROUP ADD APPLIES_TO_CHAIN NUMBER(1,0) DEFAULT 0 NOT NULL;

create or replace package chain.company_tag_pkg as
	procedure dummy;
end;
/
create or replace package body chain.company_tag_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on chain.company_tag_pkg to web_user;

@..\tag_pkg
@..\tag_body

@..\..\..\postcode\db\geo_region_pkg
@..\..\..\postcode\db\geo_region_body

@..\chain\company_pkg
@..\chain\component_pkg
@..\chain\purchased_component_pkg
@..\chain\company_tag_pkg

@..\chain\chain_body
@..\chain\company_body
@..\chain\company_user_body
@..\chain\component_body
@..\chain\purchased_component_body
@..\chain\company_tag_body

@update_tail