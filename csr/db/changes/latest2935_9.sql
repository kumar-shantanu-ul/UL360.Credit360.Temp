-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.dataview_arbitrary_period (
	APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
	DATAVIEW_SID		NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD PRIMARY KEY (APP_SID, DATAVIEW_SID, START_DTM),
	CONSTRAINT FK_DATAVIEW_FROM_DATAVIEW_AP	FOREIGN KEY (APP_SID, DATAVIEW_SID) REFERENCES csr.dataview (APP_SID, DATAVIEW_SID)
);

CREATE TABLE csr.dataview_arbitrary_period_hist (
	APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
	DATAVIEW_SID		NUMBER(10)			NOT NULL,
	VERSION_NUM         NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_HIST_ARB_PERIOD PRIMARY KEY (APP_SID, DATAVIEW_SID, VERSION_NUM, START_DTM),
	CONSTRAINT FK_DATAVIEW_FROM_DATAVIEW_APH	FOREIGN KEY (APP_SID, DATAVIEW_SID) REFERENCES csr.dataview (APP_SID, DATAVIEW_SID)
);

CREATE TABLE CSRIMP.DATAVIEW_ARBITRARY_PERIOD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID		NUMBER(10),
	START_DTM			DATE,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, START_DTM),
    CONSTRAINT FK_DATAVIEW_ARB_PERIOD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.DATAVIEW_ARBITRARY_PERIOD_HIST (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID		NUMBER(10),
	VERSION_NUM         NUMBER(10),
	START_DTM			DATE,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD_HIST PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, VERSION_NUM, START_DTM),
    CONSTRAINT FK_DATAVIEW_ARB_PERIOD_HIST_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT INSERT,SELECT,UPDATE ON csr.dataview_arbitrary_period TO csrimp;
GRANT INSERT,SELECT,UPDATE ON csr.dataview_arbitrary_period_hist TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.dataview_arbitrary_period TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.dataview_arbitrary_period_hist TO csrimp;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.dataview_arbitrary_period to web_user;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.dataview_arbitrary_period_hist to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../dataview_pkg
@../dataview_body
@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
