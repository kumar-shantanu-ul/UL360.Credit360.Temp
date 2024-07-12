-- Please update version.sql too -- this keeps clean builds in sync
define version=3158
define minor_version=11
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

-- Alter tables
ALTER TABLE CSR.TAB_DESCRIPTION ADD CONSTRAINT FK_TAB_DESCRIPTION_TAB
	FOREIGN KEY (APP_SID, TAB_ID)
	REFERENCES CSR.TAB(APP_SID, TAB_ID)
	ON DELETE CASCADE
;

-- *** Grants ***
grant select,insert,update,delete on csrimp.tab_description to tool_user;
grant insert on csr.tab_description to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$tab_user AS
SELECT t.tab_id, t.app_sid, t.layout, NVL(td.description, t.name) name , t.is_shared, t.is_hideable, t.override_pos, tu.user_sid, tu.pos, tu.is_owner, tu.is_hidden, t.portal_group
  FROM csr.tab t
  JOIN csr.tab_user tu ON t.app_sid = tu.app_sid AND t.tab_id = tu.tab_id
  LEFT JOIN csr.tab_description td ON td.app_sid = tu.app_sid AND t.tab_id = td.tab_id AND td.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.tab_description(app_sid, tab_id, lang, description, last_changed_dtm)
		SELECT t.app_sid, t.tab_id, ts.lang, NVL(td.translated, t.name), SYSDATE
		  FROM csr.tab t 
		  JOIN aspen2.translation_set ts ON ts.application_sid = t.app_sid
		LEFT JOIN aspen2.translation tr ON tr.original = t.name AND tr.application_sid = t.app_sid
		LEFT JOIN aspen2.translated td ON td.original_hash = tr.original_hash AND td.application_sid = tr.application_sid 
		AND td.lang = ts.lang
		 WHERE NOT EXISTS
			(SELECT 1 FROM csr.tab_description WHERE tab_id = t.tab_id AND lang = ts.lang AND app_sid = t.app_sid);
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
