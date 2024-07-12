define version=3396
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



DROP INDEX csr.ix_ci_title_search;   
ALTER TABLE csr.compliance_item_description MODIFY title VARCHAR2(2048);
CREATE INDEX csr.ix_ci_title_search on csr.compliance_item_description(title) indextype IS ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');










INSERT INTO ASPEN2.LANG (LANG, DESCRIPTION, LANG_ID, PARENT_LANG_ID, OVERRIDE_LANG)
VALUES('zh', 'Chinese', 204, NULL, NULL);
UPDATE aspen2.lang SET parent_lang_id = 204 WHERE lang_id in (38,41);






@..\compliance_pkg
@..\period_pkg


@..\csr_app_body
@..\compliance_body
@..\period_body



@update_tail
