-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.TAB_DESCRIPTION(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_ID				NUMBER(10, 0)	NOT NULL,
	LANG				VARCHAR2(10)	NOT NULL,
	DESCRIPTION			VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAB_DESCRIPTION PRIMARY KEY (APP_SID, TAB_ID, LANG)
)
;
CREATE TABLE CSRIMP.TAB_DESCRIPTION(
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_ID				NUMBER(10, 0)	NOT NULL,
	LANG				VARCHAR2(10)	NOT NULL,
	DESCRIPTION			VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAB_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAB_ID, LANG),
	CONSTRAINT FK_TAB_DESCRIPTION FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
CREATE TABLE CSR.TAB_PORTLET_DESCRIPTION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_PORTLET_ID				NUMBER(10, 0)	NOT NULL,
	LANG						VARCHAR2(10)	NOT NULL,
	DESCRIPTION					VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM			DATE,
	CONSTRAINT PK_TAB_PORTLET_DESCRIPTION PRIMARY KEY (APP_SID, TAB_PORTLET_ID, LANG)
)
;
CREATE TABLE CSRIMP.TAB_PORTLET_DESCRIPTION(
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_PORTLET_ID				NUMBER(10, 0)	NOT NULL,
	LANG						VARCHAR2(10)	NOT NULL,
	DESCRIPTION					VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM			DATE,
	CONSTRAINT PK_TAB_PORTLET_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAB_PORTLET_ID, LANG),
	CONSTRAINT FK_TAB_PORTLET_DESC_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;

-- Alter tables
ALTER TABLE CSR.TAB_DESCRIPTION ADD CONSTRAINT FK_TAB_DESCRIPTION_TAB
	FOREIGN KEY (APP_SID, TAB_ID)
	REFERENCES CSR.TAB(APP_SID, TAB_ID)
	ON DELETE CASCADE
;
ALTER TABLE CSR.TAB_PORTLET_DESCRIPTION ADD CONSTRAINT FK_TAB_PORTLET_DESCRIPTION
	FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
	REFERENCES CSR.TAB_PORTLET(APP_SID, TAB_PORTLET_ID)
	ON DELETE CASCADE
;

-- *** Grants ***
grant select,insert,update,delete on csrimp.tab_description to tool_user;
grant insert on csr.tab_description to csrimp;
grant select,insert,update,delete on csrimp.tab_portlet_description to tool_user;
grant insert on csr.tab_portlet_description to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

CREATE OR REPLACE VIEW csr.v$tab_user AS
SELECT t.tab_id, t.app_sid, t.layout, NVL(td.description, tden.description) name , t.is_shared, t.is_hideable, t.override_pos, tu.user_sid, tu.pos, tu.is_owner, tu.is_hidden, t.portal_group
  FROM csr.tab t
  JOIN csr.tab_user tu ON t.app_sid = tu.app_sid AND t.tab_id = tu.tab_id
  LEFT JOIN csr.tab_description td ON td.app_sid = tu.app_sid AND t.tab_id = td.tab_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
  LEFT JOIN csr.tab_description tden ON tden.app_sid = tu.app_sid AND t.tab_id = tden.tab_id AND tden.lang = 'en';

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.tab_description(app_sid, tab_id, lang, description, last_changed_dtm)
		SELECT t.app_sid, t.tab_id, ts.lang, NVL(td.translated, t.name), SYSDATE
		  FROM csr.tab t 
		  JOIN aspen2.translation_set ts ON ts.application_sid = t.app_sid
		LEFT JOIN aspen2.translation tr ON tr.original = t.name
		AND tr.application_sid = t.app_sid
		LEFT JOIN aspen2.translated td ON td.original_hash = tr.original_hash
		AND td.application_sid = tr.application_sid 
		AND td.lang = ts.lang
		 WHERE NOT EXISTS
			(SELECT 1 FROM csr.tab_description WHERE tab_id = t.tab_id AND lang = ts.lang AND app_sid = t.app_sid);
END;
/

BEGIN
	INSERT INTO csr.tab_portlet_description(app_sid,tab_portlet_id, lang, description, last_changed_dtm)
	SELECT cp.app_sid, tp.tab_portlet_id, l.lang, COALESCE(SUBSTR(REGEXP_SUBSTR(dbms_lob.substr(tp.state,255,1),'portletTitle":"[^"]*',1),16), td.translated, p.name) description, SYSDATE
	  FROM csr.customer_portlet cp
	  JOIN csr.tab_portlet tp ON cp.customer_portlet_sid = tp.customer_portlet_sid AND cp.app_sid = tp.app_sid
	  JOIN csr.portlet p ON p.portlet_id = cp.portlet_id
	  JOIN (
		SELECT application_sid, lang
		  FROM aspen2.translation_set
		UNION
		SELECT app_sid, 'en'
		  FROM csr.customer_portlet
		) l ON l.application_sid = cp.app_sid
	  LEFT JOIN aspen2.translation tr ON p.name = tr.original AND tr.application_sid = cp.app_sid
	  LEFT JOIN aspen2.translated td ON tr.original_hash = td.original_hash AND tr.application_sid = td.application_sid AND td.lang = l.lang;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../portlet_pkg
@../portlet_body
@../enable_body
@../schema_pkg
@../schema_body
@../csr_app_pkg
@../csr_app_body
@../csrimp/imp_body

@update_tail
