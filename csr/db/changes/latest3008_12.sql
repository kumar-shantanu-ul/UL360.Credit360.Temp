-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CMS.ENUM_GROUP_TAB (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	LABEL							VARCHAR2(255) NOT NULL,
	REPLACE_EXISTING_FILTERS		NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_TAB PRIMARY KEY (APP_SID, TAB_SID),
	CONSTRAINT CHK_ENUM_G_TAB_REP_FILTER_1_0 CHECK (REPLACE_EXISTING_FILTERS IN (1,0)),
	CONSTRAINT FK_ENUM_GROUP_TAB_TAB FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID, TAB_SID)
);


CREATE TABLE CMS.ENUM_GROUP (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	GROUP_LABEL						VARCHAR2(255),
	CONSTRAINT PK_ENUM_GROUP PRIMARY KEY (APP_SID, ENUM_GROUP_ID),
	CONSTRAINT FK_EMUM_GROUP_ENUM_GROUP_TAB FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.ENUM_GROUP_TAB (APP_SID, TAB_SID)
);

CREATE SEQUENCE CMS.ENUM_GROUP_ID_SEQ;

CREATE TABLE CMS.ENUM_GROUP_MEMBER(
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	ENUM_GROUP_MEMBER_ID	 		NUMBER(10) NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_MEMBER PRIMARY KEY (APP_SID, ENUM_GROUP_ID, ENUM_GROUP_MEMBER_ID),
	CONSTRAINT FK_ENUM_GROUP_MBR_ENUM_GROUP FOREIGN KEY (APP_SID, ENUM_GROUP_ID) REFERENCES CMS.ENUM_GROUP (APP_SID, ENUM_GROUP_ID)
);

CREATE INDEX CMS.IX_ENUM_GROUP_TAB_SID ON CMS.ENUM_GROUP (APP_SID, TAB_SID);
CREATE INDEX CMS.IX_ENUM_GROUP_MEMBER_GROUP_ID ON CMS.ENUM_GROUP_MEMBER (APP_SID, ENUM_GROUP_ID);

CREATE TABLE CSRIMP.CMS_ENUM_GROUP_TAB (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	LABEL							VARCHAR2(255) NOT NULL,
	REPLACE_EXISTING_FILTERS		NUMBER(1) NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_TAB PRIMARY KEY (CSRIMP_SESSION_ID, TAB_SID),
	CONSTRAINT CHK_ENUM_G_TAB_REP_FILTER_1_0 CHECK (REPLACE_EXISTING_FILTERS IN (1,0)),
	CONSTRAINT FK_CMS_ENUM_GROUP_TAB_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_ENUM_GROUP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	GROUP_LABEL						VARCHAR2(255),
	CONSTRAINT PK_ENUM_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, ENUM_GROUP_ID),
	CONSTRAINT FK_CMS_ENUM_GROUP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_ENUM_GROUP_MEMBER(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	ENUM_GROUP_MEMBER_ID	 		NUMBER(10) NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, ENUM_GROUP_ID, ENUM_GROUP_MEMBER_ID),
	CONSTRAINT FK_CMS_ENUM_GROUP_MEMBER_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CMS_ENUM_GROUP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ENUM_GROUP_ID				NUMBER(10) NOT NULL,
	NEW_ENUM_GROUP_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CMS_ENUM_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ENUM_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CMS_ENUM_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_ENUM_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CMS_ENUM_GROUP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
grant select on cms.enum_group_id_seq to csrimp;
grant insert on cms.enum_group_tab to csrimp;
grant insert on cms.enum_group to csrimp;
grant insert on cms.enum_group_member to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg

@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/filter_body
@../csrimp/imp_body

@update_tail
