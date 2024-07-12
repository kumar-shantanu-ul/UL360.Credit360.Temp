-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSRIMP.PORTAL_DASHBOARD(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    PORTAL_SID              NUMBER(10, 0)    NOT NULL,
    PORTAL_GROUP            VARCHAR2(50)     NOT NULL,
    MENU_SID                NUMBER(10, 0),
    MESSAGE                 VARCHAR2(2048),
    CONSTRAINT PK_PORTAL_DASHBOARD PRIMARY KEY (CSRIMP_SESSION_ID, PORTAL_SID),
    CONSTRAINT FK_PORTAL_DASHBOARD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables

alter table csrimp.ASPEN2_TRANSLATED drop constraint PK_ASPEN2_TRANSLATED;
alter table csrimp.ASPEN2_TRANSLATED add constraint PK_ASPEN2_TRANSLATED  PRIMARY KEY (CSRIMP_SESSION_ID, LANG, ORIGINAL_HASH);

alter table csrimp.ASPEN2_TRANSLATION drop constraint PK_ASPEN2_TRANSLATION;
alter table csrimp.ASPEN2_TRANSLATION add constraint PK_ASPEN2_TRANSLATION  PRIMARY KEY (CSRIMP_SESSION_ID, ORIGINAL_HASH);

alter table csrimp.ASPEN2_TRANSLATION_SET drop constraint PK_ASPEN2_TRANSLATION_SET;
alter table csrimp.ASPEN2_TRANSLATION_SET add constraint PK_ASPEN2_TRANSLATION_SET PRIMARY KEY (CSRIMP_SESSION_ID, LANG);

alter table csrimp.ASPEN2_TRANSLATION_SET_INCL drop constraint PK_ASPEN2_TRANS_SET_INCL;
alter table csrimp.ASPEN2_TRANSLATION_SET_INCL add constraint PK_ASPEN2_TRANS_SET_INCL PRIMARY KEY (CSRIMP_SESSION_ID, LANG, POS);

alter table csrimp.ROUTE add (
	COMPLETED_DTM DATE
);

-- *** Grants ***
grant select, insert on csr.portal_dashboard to csrimp;
-- adding grant for update on menu to csrimp as we're updating sids on multiple_portal menu items
grant insert, update on security.menu to csrimp;
grant insert,select,update,delete on csrimp.portal_dashboard to web_user;
-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS
@../csrimp/rls
-- Data

-- ** New package grants **

-- *** Packages ***

@../schema_pkg
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body
-- leftover from FB70887
@../region_picker_body 

@update_tail
