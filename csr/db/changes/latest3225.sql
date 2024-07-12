define version=3225
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


ALTER TABLE csr.tpl_report_tag_suggestion MODIFY (
  campaign_sid NUMBER(10, 0) NULL
);
ALTER TABLE csr.tpl_report_tag_suggestion ADD (
  survey_sid  NUMBER(10,0),
  CONSTRAINT chk_tpl_report_tag_suggestion CHECK ((campaign_sid IS NULL AND survey_sid IS NOT NULL) OR (campaign_sid IS NOT NULL AND survey_sid IS NULL))
);
ALTER TABLE csrimp.tpl_report_tag_suggestion MODIFY (
  campaign_sid NUMBER(10, 0) NULL
);
ALTER TABLE csrimp.tpl_report_tag_suggestion ADD (
  survey_sid  NUMBER(10,0)
);

BEGIN
	-- Missing basedata related to imp/exp. Prod is fine as it run the latest, but any newer databases won't be, so putting this
	-- in to try and set all databases to the correct set.
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (1, 'DataView Exporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (2, 'DataView Exporter (Xml Mappable)');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (3, 'Batched Exporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (4, 'Stored Procedure Exporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 1 WHERE plugin_id = 1;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 1 WHERE plugin_id = 2;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 1 WHERE plugin_id = 3;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 4 WHERE plugin_id = 13;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 3 WHERE plugin_id = 19;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 2 WHERE plugin_id = 21;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 2 WHERE plugin_id = 22;
END;
/

CREATE OR REPLACE PACKAGE campaigns.campaign_treeview_pkg AS
END;
/
GRANT EXECUTE ON campaigns.campaign_treeview_pkg TO csr;
GRANT EXECUTE ON campaigns.campaign_treeview_pkg TO web_user;


@..\indicator_pkg
@..\templated_report_pkg
@..\campaigns\campaign_treeview_pkg


@..\campaigns\campaign_body
@..\indicator_body
@..\templated_report_body
@..\schema_body
@..\csrimp\imp_body
@..\campaigns\campaign_treeview_body



@update_tail
