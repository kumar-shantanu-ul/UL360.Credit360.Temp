define version=3240
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
CREATE SEQUENCE csr.compliance_item_desc_hist_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE csr.compliance_item_desc_hist (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	compliance_item_desc_hist_id	NUMBER(10, 0)	NOT NULL,
	compliance_item_id				NUMBER(10, 0)	NOT NULL,
	compliance_language_id			NUMBER(10, 0)	NOT NULL,
	major_version					NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	title							VARCHAR2(1024)	NOT NULL,
	summary							VARCHAR2(4000),
	details							CLOB,
	citation						VARCHAR2(4000),
	description						CLOB,
	change_dtm						DATE,
	CONSTRAINT pk_compliance_item_desc_hist PRIMARY KEY (app_sid, compliance_item_desc_hist_id),
	CONSTRAINT fk_comp_item_dsc_hst_comp_item
		FOREIGN KEY (app_sid, compliance_item_id)
		REFERENCES csr.compliance_item (app_sid, compliance_item_id),
	CONSTRAINT fk_comp_item_dsc_hst_comp_lang
		FOREIGN KEY (app_sid, compliance_language_id)
		REFERENCES csr.compliance_language (app_sid, compliance_language_id)
);
CREATE TABLE csrimp.compliance_item_desc_hist (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_desc_hist_id	NUMBER(10, 0)	NOT NULL,
	compliance_item_id				NUMBER(10, 0)	NOT NULL,
	compliance_language_id			NUMBER(10, 0)	NOT NULL,
	major_version					NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	title							VARCHAR2(1024)	NOT NULL,
	summary							VARCHAR2(4000),
	details							CLOB,
	citation						VARCHAR2(4000),
	description						CLOB,
	change_dtm						DATE,
	CONSTRAINT pk_compliance_item_desc_hist PRIMARY KEY (csrimp_session_id, compliance_item_desc_hist_id),
	CONSTRAINT fk_compliance_item_desc_hist
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);
CREATE TABLE csrimp.map_compliance_item_desc_hist (
	csrimp_session_id					NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_item_desc_hist_id			NUMBER(10)	NOT NULL,
	new_comp_item_desc_hist_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_comp_item_desc_hist PRIMARY KEY (csrimp_session_id, old_comp_item_desc_hist_id),
	CONSTRAINT uk_map_comp_item_desc_hist UNIQUE (csrimp_session_id, new_comp_item_desc_hist_id),
	CONSTRAINT fk_map_comp_item_desc_hist FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE INDEX csr.ix_comp_item_desc_hist_comp_it ON csr.compliance_item_desc_hist (app_sid, compliance_item_id);
CREATE INDEX csr.ix_comp_item_desc_hist_comp_lg ON csr.compliance_item_desc_hist (app_sid, compliance_language_id);


ALTER TABLE csr.gresb_submission_log MODIFY (gresb_response_id NULL);
ALTER TABLE csr.gresb_submission_log ADD gresb_entity_id VARCHAR2(255);
ALTER TABLE csr.gresb_submission_log ADD gresb_asset_id VARCHAR2(255);
ALTER TABLE csr.gresb_submission_log ADD
CONSTRAINT CK_GRESB_SL_ID_VALID CHECK ((gresb_response_id IS NOT NULL AND gresb_entity_id IS NULL) OR (gresb_response_id IS NULL AND gresb_entity_id IS NOT NULL));
ALTER TABLE csrimp.gresb_submission_log MODIFY (gresb_response_id NULL);
ALTER TABLE csrimp.gresb_submission_log ADD gresb_entity_id VARCHAR2(255);
ALTER TABLE csrimp.gresb_submission_log ADD gresb_asset_id VARCHAR2(255);
ALTER TABLE csr.compliance_item_description ADD (
	major_version				NUMBER(10)		DEFAULT 1 NOT NULL,
	minor_version				NUMBER(10)		DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.compliance_item_description ADD (
	major_version				NUMBER(10)		DEFAULT 1 NOT NULL,
	minor_version				NUMBER(10)		DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.doc_folder MODIFY (
	description				NULL
);


GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_desc_hist TO csrimp;
GRANT SELECT ON csr.compliance_item_desc_hist_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_desc_hist TO tool_user;








UPDATE csr.gresb_service_config 
   SET client_id = '0344060dc551526374f7cc9ed81f1f4fdfe91aeb9583702bebfe22e0b6ee354a',
	   client_secret = 'c87b4fbf1a47dae958ac885818708c6e322457bce2c7060a745eca9545063bdc'
 WHERE name = 'sandbox';
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (105, 1, 'new_construction', '[Y, N, null]', 'Was the asset under construction during the reporting period?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (106, 1, 'new_construction_completed', '[Y, N, null]', 'Was the new construction project completed during the last year of the reporting period?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (107, 1, 'major_renovation_completed', '[Y, N, null]', 'Was the major renovation completed during the last year of the reporting period?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (108, 1, 'asset_size_common', 'x > 0', 'Floor area size of the common areas in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (109, 1, 'asset_size_shared', 'x > 0', 'Floor area size of the shared service areas in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (110, 1, 'asset_size_tenant', 'x > 0', 'Floor area size of the entire Tenant Space in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (111, 1, 'asset_size_tenant_landlord', 'x > 0', 'Floor area size of the tenant space areas where energy was purchased by the landlord in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (112, 1, 'asset_size_tenant_tenant', 'x > 0', 'Floor area size of the tenant space areas where energy was purchased by the tenant in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
UPDATE csr.compliance_item_description cid
   SET (cid.major_version, cid.minor_version) =
		(SELECT ci.major_version, ci.minor_version
		  FROM csr.compliance_item ci
		 WHERE ci.app_sid = cid.app_sid
		   AND ci.compliance_item_id = cid.compliance_item_id
		)
;
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (113, 1, 'asset_gav', 'x > 0', 'Gross asset value of the asset at the end of the reporting period. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (114, 1, 'directly_managed', '[Y, N, null]', 'Did the company/fund manager have operational control over the asset?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (115, 1, 'whole_building', '[Y, N, null]', 'Is the energy consumption data of the asset collected for the whole building (TRUE) or separately for base building and tenant space (FALSE)?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (116, 1, 'dc_change_energy', '[Y, N, null]', 'Did the energy data coverage for this asset change over the last two years? ', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (117, 1, 'dc_change_water', '[Y, N, null]', 'Did the water data coverage for this asset change over the last two years?', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (118, 1, 'asset_vacancy', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Average annual vacancy.', '%', NULL);






@..\gresb_config_pkg
@..\compliance_pkg
@..\schema_pkg


@..\csr_app_body
@..\enable_body
@..\gresb_config_body
@..\indicator_body
@..\scenario_body
@..\scenario_run_body
@..\schema_body
@..\csrimp\imp_body
@..\compliance_body
@..\meter_monitor_body
@..\issue_body



@update_tail
