define version=3162
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
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


ALTER TABLE chain.dedupe_mapping ADD fill_nulls_under_ui_source NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_fill_nulls_zero_one CHECK (fill_nulls_under_ui_source IN (0,1));
ALTER TABLE csrimp.chain_dedupe_mapping ADD fill_nulls_under_ui_source NUMBER(1);
BEGIN
	-- Remove existing PK
	FOR r IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSRIMP'
		   AND table_name = 'METER_LIVE_DATA'
		   AND constraint_type = 'P'
	) LOOP
		EXECUTE IMMEDIATE('ALTER TABLE CSRIMP.METER_LIVE_DATA DROP CONSTRAINT  '||r.constraint_name||' DROP INDEX');
	END LOOP;
END;
/
ALTER TABLE CSRIMP.METER_LIVE_DATA ADD(
	CONSTRAINT PK_METER_LIVE_DATA PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, METER_BUCKET_ID, METER_INPUT_ID, AGGREGATOR, PRIORITY, START_DTM)
);
ALTER TABLE CSR.TAB_DESCRIPTION ADD CONSTRAINT FK_TAB_DESCRIPTION_TAB
	FOREIGN KEY (APP_SID, TAB_ID)
	REFERENCES CSR.TAB(APP_SID, TAB_ID)
	ON DELETE CASCADE
;


GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_history TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_region_tag TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_root_regions TO tool_user;
grant select,insert,update,delete on csrimp.tab_description to tool_user;
grant insert on csr.tab_description to csrimp;




CREATE OR REPLACE VIEW csr.v$tab_user AS
SELECT t.tab_id, t.app_sid, t.layout, NVL(td.description, t.name) name , t.is_shared, t.is_hideable, t.override_pos, tu.user_sid, tu.pos, tu.is_owner, tu.is_hidden, t.portal_group
  FROM csr.tab t
  JOIN csr.tab_user tu ON t.app_sid = tu.app_sid AND t.tab_id = tu.tab_id
  LEFT JOIN csr.tab_description td ON td.app_sid = tu.app_sid AND t.tab_id = td.tab_id AND td.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');




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






@..\chain\dedupe_admin_pkg
@..\chain\company_pkg
@..\portlet_pkg
@..\schema_pkg
@..\csr_app_pkg


@..\factor_body
@..\chain\dedupe_admin_body
@..\chain\company_dedupe_body
@..\csrimp\imp_body
@..\schema_body
@..\permit_body
@..\compliance_body
@..\chain\company_body
@..\enable_body
@..\portlet_body
@..\csr_app_body



@update_tail
