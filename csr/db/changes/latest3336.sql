define version=3336
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



ALTER TABLE csr.auto_exp_retrieval_dataview ADD (
	region_selection_type_id				NUMBER(10, 0) DEFAULT 6 NOT NULL,
	tag_id									NUMBER(10, 0)
);
ALTER TABLE csr.auto_exp_retrieval_dataview
ADD CONSTRAINT fk_auto_exp_rdv_tag FOREIGN KEY (app_sid, tag_id) REFERENCES csr.tag(app_sid, tag_id);
CREATE INDEX csr.ix_auto_exp_retr_tag_id ON csr.auto_exp_retrieval_dataview (app_sid, tag_id);






	INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('amfori', 3, 'Amfori Platform Service user', 1);










@..\automated_export_pkg
@..\audit_pkg
@..\chain\integration_pkg


@..\enable_body
@..\permit_body
@..\quick_survey_body
@..\automated_export_body
@..\audit_body
@..\chain\integration_body



@update_tail
