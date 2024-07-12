define version=3290
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
CREATE OR REPLACE TYPE CSR.T_AUDIT_PERMISSIBLE_NCT AS
	OBJECT (
		AUDIT_SID					NUMBER(10),
		NON_COMPLIANCE_TYPE_ID		NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_PERMISSIBLE_NCT_TABLE AS
	TABLE OF CSR.T_AUDIT_PERMISSIBLE_NCT;
/
--Failed to locate all sections of latest3284_2.sql
CREATE TABLE csr.property_gresb(
	app_sid			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	region_sid		NUMBER(10, 0)	NOT NULL,
	asset_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_gresb PRIMARY KEY (app_sid, region_sid),
	CONSTRAINT uk_property_gresb_asset_id UNIQUE (app_sid, asset_id),
	CONSTRAINT fk_property_gresb_region FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid)
);
CREATE TABLE csrimp.property_gresb(
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10, 0)	NOT NULL,
	asset_id						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_gresb PRIMARY KEY (csrimp_session_id, region_sid),
	CONSTRAINT uk_property_gresb_asset_id UNIQUE (csrimp_session_id, asset_id),
	CONSTRAINT fk_property_gresb FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);


ALTER TABLE CSR.NON_COMPLIANCE_TYPE ADD FLOW_CAPABILITY_ID NUMBER(10, 0);
ALTER TABLE CSR.NON_COMPLIANCE_TYPE ADD CONSTRAINT FK_NON_COMP_TYP_CAPAB
	FOREIGN KEY (APP_SID, FLOW_CAPABILITY_ID)
	REFERENCES CSR.CUSTOMER_FLOW_CAPABILITY(APP_SID, FLOW_CAPABILITY_ID)
;
CREATE INDEX csr.ix_non_complianc_flow_capabili ON csr.non_compliance_type (app_sid, flow_capability_id);
ALTER TABLE CSRIMP.NON_COMPLIANCE_TYPE ADD FLOW_CAPABILITY_ID NUMBER(10, 0);
ALTER TABLE CSRIMP.NON_COMPLIANCE_TYPE ADD CONSTRAINT FK_NON_COMP_TYP_CAPAB
	FOREIGN KEY (CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID)
	REFERENCES CSRIMP.CUSTOMER_FLOW_CAPABILITY(CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID)
;
ALTER TABLE csr.gresb_indicator_type ADD (
	pos	NUMBER(2) DEFAULT 0 NOT NULL
);
ALTER TABLE csr.gresb_indicator ADD (
	system_managed	NUMBER(1) DEFAULT 0 NOT NULL,
	sm_description  VARCHAR2(4000),
	CONSTRAINT ck_gresb_indicator_managed CHECK (system_managed IN (0,1))
);


GRANT SELECT, INSERT, UPDATE ON csr.property_gresb TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.property_gresb TO tool_user;








INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (92, 'Delegation Plan Status export', 'batch-exporter', 0, 'support@credit360.com', 3, 360);
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (92, 'Delegation Plan Status export', 'Credit360.ExportImport.Export.Batched.Exporters.DelegPlanStatusExporter');
UPDATE csr.gresb_indicator_type SET required = 1, pos = gresb_indicator_type_id + 1 WHERE gresb_indicator_type_id > 1 AND gresb_indicator_type_id < 6;
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (6, 'Efficiency', 1, 1);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (7, 'Reporting', 1, 2);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1001,1,'asset_name','Text(255)','Name of the asset as displayed to the users with access to this portfolio in the Asset Portal.','',NULL,1,'Region''s description');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1002,1,'optional_information','Text(255)','Any additional information - displayed in the Asset Portal.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1003,1,'property_type_code','Text(255)','GRESB property type classification for the asset.','',NULL,1,'Property''s GRESB property type code calculated from GRESB property sub type.');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1004,1,'country','Text(255)','ISO3166 country code.','',NULL,1,'Property''s country');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1005,1,'state_province','Text(255)','State, province, or region.','',NULL,1,'Property''s state');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1006,1,'city','Text(255)','City, town, or village.','',NULL,1,'Property''s city');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1007,1,'address','Text(255)','Physical street or postal address.','',NULL,1,'Comma seperated list using the property''s: Street address line 1, Street address line 2, City, State/Region, Zip/Postcode; skipping any blanks items');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1008,1,'lat','Decimal','Latitude.','',NULL,1,'Property''s latitude');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1009,1,'lng','Decimal','Longitude.','',NULL,1,'Property''s longitude');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1010,1,'construction_year','Integer','Year in which the asset was completed and ready for use.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1011,1,'asset_gav','Decimal','Gross asset value of the asset at the end of the reporting period.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1012,1,'asset_size','Decimal','The total floor area size of the asset - without outdoor/exterior areas. Use the same area metric as reported in RC3.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1013,6,'en_emr_tba','Y/N','Has a technical building assessment to identify energy efficiency improvements been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1014,6,'en_emr_amr','Y/N','Energy efficiency measure: Have automatic meter readings for energy been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1015,6,'en_emr_asur','Y/N','Energy efficiency measure: Have automation system upgrades/replacements been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1016,6,'en_emr_msur','Y/N','Energy efficiency measure: Have management system upgrades/replacements been implememted in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1017,6,'en_emr_ihee','Y/N','Energy efficiency measure: Have high-efficiency equipment and/or appliances been installed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1018,6,'en_emr_iren','Y/N','Energy efficiency measure: Has on-site renewable energy been installed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1019,6,'en_emr_oce','Y/N','Energy efficiency measure: Have occupier engagement/informational technology improvements been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1020,6,'en_emr_sbt','Y/N','Energy efficiency measure: Have smart grid or smart building technologies been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1021,6,'en_emr_src','Y/N','Energy efficiency measure: Has systems commissioning or retro-commissioning been implememted in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1022,6,'en_emr_wri','Y/N','Energy efficiency measure: Has the wall and/or roof insulation been replaced or modified to improve energy efficiency in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1023,6,'en_emr_wdr','Y/N','Energy efficiency measure: Have windows been replaced to improve energy efficiency in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1024,6,'wat_emr_tba','Y/N','Has a technical building assessment to identify water efficiency improvements been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1025,6,'wat_emr_amr','Y/N','Water efficiency measure: Have automatic meter readings for water been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1026,6,'wat_emr_clt','Y/N','Water efficiency measure: Have cooling towers been introduced in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1027,6,'wat_emr_dsi','Y/N','Water efficiency measure: Have smart or drip irrigation methods been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1028,6,'wat_emr_dtnl','Y/N','Water efficiency measure: Has drought-tolerant and/or native landscaping been introduced in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1029,6,'wat_emr_hedf','Y/N','Water efficiency measure: Have high-efficiency and/or dry fixtures been introduced in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1030,6,'wat_emr_lds','Y/N','Water efficiency measure: Has a leak detection system been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1031,6,'wat_emr_mws','Y/N','Water efficiency measure: Has the installation of water sub-meters been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1032,6,'wat_emr_owwt','Y/N','Water efficiency measure: Has a system or process of on-site water treatment been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1033,6,'wat_emr_rsgw','Y/N','Water efficiency measure: Has a system or process to reuse storm and/or grey water been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1034,6,'was_emr_tba','Y/N','Has a technical building assessment to identify waste efficiency improvements been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1035,6,'was_emr_clfw','Y/N','Waste efficiency measure: Has composting landscape and/or food waste been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1036,6,'was_emr_opm','Y/N','Waste efficiency measure: Has a system or process of ongoing monitoring of waste performance been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1037,6,'was_emr_rec','Y/N','Waste efficiency measure: Has a program for local waste recycling been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1038,6,'was_emr_wsm','Y/N','Waste efficiency measure: Has a program of waste management been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1039,6,'was_emr_wsa','Y/N','Waste efficiency measure: Has a waste stream audit been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1040,7,'tenant_ctrl','Y/N','Is the whole building tenant-controlled (Y) or does the landlord have at least some operational control (N)?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1041,7,'asset_vacancy','Decimal','The average percent vacancy rate.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1042,7,'owned_entire_period','Y/N','Has the asset been owned for the entire reporting year (Y) or was the asset purchased or sold during the reporting year (N)?','',NULL,1,'True if region aquisition date and disposal date encompass the whole year');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1043,7,'ownership_from','Date','If asset was not owned for entire reporting period, date when the asset was purchased or acquired within the reporting year.','',NULL,1,'If owned_entire_period is false then region''s aquisition date');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1044,7,'ownership_to','Date','If asset was not owned for entire reporting period, date when the asset was sold within the reporting year.','',NULL,1,'If owned_entire_period is false then region''s disposal date');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1045,7,'ncmr_status','Text(255)','The operational status of the asset: standing investment, major renovation, or new construction, within the reporting year.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1046,7,'ncmr_from','Date','If the asset was under major renovation or new construction, the start date of the project within the reporting year.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1047,7,'ncmr_to','Date','If the asset was under major renovation or new construction, the end date of the project within the reporting year.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1048,1,'whole_building','Y/N','Is the energy consumption data of the asset collected for the whole building (Y) or separately for base building and tenant space (N)?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1049,1,'asset_size_common','Decimal','Floor area of the common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1050,1,'asset_size_shared','Decimal','Floor area of the shared spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1051,1,'asset_size_tenant','Decimal','Floor area of all tenant spaces (all lettable area).','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1052,1,'asset_size_tenant_landlord','Decimal','Floor area of tenant spaces where the landlord purchases energy.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1053,1,'asset_size_tenant_tenant','Decimal','Floor area of tenant spaces where the tenant purchases energy.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1054,2,'en_data_from','Date','Date within reporting year from which energy data is available.','',NULL,1,'The start date of the period that provided data covers');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1055,2,'en_data_to','Date','Date within reporting year to which energy data is available.','',NULL,1,'The end date of the period that provided data covers');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1056,2,'en_abs_wf','Decimal','Absolute and non-normalized fuel consumption for assets reporting on whole building.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1057,2,'en_cov_wf','Decimal','Covered floor area where fuel consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1058,2,'en_tot_wf','Decimal','Total floor area where fuel supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1059,2,'en_abs_wd','Decimal','Absolute and non-normalized district heating and cooling consumption for assets reporting on whole building.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1060,2,'en_cov_wd','Decimal','Covered floor area where district heating and cooling consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1061,2,'en_tot_wd','Decimal','Total floor area where district heating and cooling supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1062,2,'en_abs_we','Decimal','Absolute and non-normalized electricity consumption for assets reporting on whole building.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1063,2,'en_cov_we','Decimal','Covered floor area where electricity consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1064,2,'en_tot_we','Decimal','Total floor area where electricity supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1065,2,'en_abs_lc_bsf','Decimal','Absolute and non-normalized fuel consumption for shared services.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1066,2,'en_cov_lc_bsf','Decimal','Covered floor area where fuel consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1067,2,'en_tot_lc_bsf','Decimal','Total floor area where fuel supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1068,2,'en_abs_lc_bsd','Decimal','Absolute and non-normalized district heating and cooling consumption for shared services.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1069,2,'en_cov_lc_bsd','Decimal','Covered floor area where district heating and cooling consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1070,2,'en_tot_lc_bsd','Decimal','Total floor area where district heating and cooling supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1071,2,'en_abs_lc_bse','Decimal','Absolute and non-normalized electricity consumption for shared services.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1072,2,'en_cov_lc_bse','Decimal','Covered floor area where electricity consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1073,2,'en_tot_lc_bse','Decimal','Total floor area where electricity supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1074,2,'en_abs_lc_bcf','Decimal','Absolute and non-normalized fuel consumption for common areas.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1075,2,'en_cov_lc_bcf','Decimal','Covered floor area where fuel consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1076,2,'en_tot_lc_bcf','Decimal','Total floor area where fuel supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1077,2,'en_abs_lc_bcd','Decimal','Absolute and non-normalized district heating and cooling consumption for common areas.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1078,2,'en_cov_lc_bcd','Decimal','Covered floor area where district heating and cooling consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1079,2,'en_tot_lc_bcd','Decimal','Total floor area where district heating and cooling supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1080,2,'en_abs_lc_bce','Decimal','Absolute and non-normalized electricity consumption for common areas.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1081,2,'en_cov_lc_bce','Decimal','Covered floor area where electricity consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1082,2,'en_tot_lc_bce','Decimal','Total floor area where electricity supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1083,2,'en_abs_lc_tf','Decimal','Absolute and non-normalized fuel consumption for landlord-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1084,2,'en_cov_lc_tf','Decimal','Covered floor area where fuel consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1085,2,'en_tot_lc_tf','Decimal','Total floor area where fuel supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1086,2,'en_abs_lc_td','Decimal','Absolute and non-normalized district heating and cooling consumption for landlord-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1087,2,'en_cov_lc_td','Decimal','Covered floor area where district heating and cooling consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1088,2,'en_tot_lc_td','Decimal','Total floor area where district heating and cooling supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1089,2,'en_abs_lc_te','Decimal','Absolute and non-normalized electricity consumption for landlord-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1090,2,'en_cov_lc_te','Decimal','Covered floor area where electricity consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1091,2,'en_tot_lc_te','Decimal','Total floor area where electricity supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1092,2,'en_abs_tc_tf','Decimal','Absolute and non-normalized fuel consumption for tenant-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1093,2,'en_cov_tc_tf','Decimal','Covered floor area where fuel consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1094,2,'en_tot_tc_tf','Decimal','Total floor area where fuel supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1095,2,'en_abs_tc_td','Decimal','Absolute and non-normalized district heating and cooling consumption for tenant-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1096,2,'en_cov_tc_td','Decimal','Covered floor area where district heating and cooling consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1097,2,'en_tot_tc_td','Decimal','Total floor area where district heating and cooling supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1098,2,'en_abs_tc_te','Decimal','Absolute and non-normalized electricity consumption for tenant-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1099,2,'en_cov_tc_te','Decimal','Covered floor area where electricity consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1100,2,'en_tot_tc_te','Decimal','Total floor area where electricity supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1101,2,'en_abs_lc_of','Decimal','Absolute and non-normalized fuel consumption for landlord-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1102,2,'en_abs_lc_oe','Decimal','Absolute and non-normalized electricity consumption for landlord-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1103,2,'en_abs_tc_of','Decimal','Absolute and non-normalized fuel consumption for tenant-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1104,2,'en_abs_tc_oe','Decimal','Absolute and non-normalized electricity consumption for tenant-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1105,2,'en_ren_ons_con','Decimal','Renewable energy generated and consumed on-site by the landlord.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1106,2,'en_ren_ons_exp','Decimal','Renewable energy generated on-site and exported by the landlord.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1107,2,'en_ren_ons_tpt','Decimal','Renewable energy generated and consumed on-site by the tenant or a third party.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1108,2,'en_ren_ofs_pbl','Decimal','Renewable energy generated off-site and purchased by the landlord.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1109,2,'en_ren_ofs_pbt','Decimal','Renewable energy generated off-site and purchased by the tenant.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1110,3,'ghg_abs_s1_w','Decimal','GHG scope 1 emissions generated by the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1111,3,'ghg_cov_s1_w','Decimal','Covered floor area where GHG scope 1 emissions data is collected.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1112,3,'ghg_tot_s1_w','Decimal','Total floor area where GHG scope 1 emissions can exist.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1113,3,'ghg_abs_s1_o','Decimal','GHG scope 1 emissions generated by the outdoor spaces associated with the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1114,3,'ghg_abs_s2_lb_w','Decimal','GHG scope 2 emissions generated by the asset, calculated using the location-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1115,3,'ghg_cov_s2_lb_w','Decimal','Covered floor area where GHG scope 2 emissions data is collected, calculated using the location-based method.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1116,3,'ghg_tot_s2_lb_w','Decimal','Total floor area where GHG scope 2 emissions can exist, calculated using the location-based method.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1117,3,'ghg_abs_s2_lb_o','Decimal','GHG scope 2 emissions generated by the outdoor spaces associated with the asset, calculated using the location-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1118,3,'ghg_abs_s2_mb_w','Decimal','GHG scope 2 emissions generated by the asset, calculated using the market-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1119,3,'ghg_abs_s2_mb_o','Decimal','GHG scope 2 emissions generated by the outdoor spaces associated with the asset, calculated using the market-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1120,3,'ghg_abs_s3_w','Decimal','GHG scope 3 emissions generated by the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1121,3,'ghg_cov_s3_w','Decimal','Covered floor area where GHG scope 3 emissions data is collected.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1122,3,'ghg_tot_s3_w','Decimal','Total floor area where GHG scope 3 emissions can exist.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1123,3,'ghg_abs_s3_o','Decimal','GHG scope 3 emissions generated by the outdoor spaces associated with the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1124,3,'ghg_abs_offset','Decimal','GHG offsets purchased.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1125,4,'wat_data_from','Date','Date within reporting year from which water data is available.','',NULL,1,'The start date of the period that provided data covers');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1126,4,'wat_data_to','Date','Date within reporting year to which water data is available.','',NULL,1,'The end date of the period that provided data covers');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1127,4,'wat_abs_w','Decimal','Absolute and non-normalized water consumption for assets reporting on whole building.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1128,4,'wat_cov_w','Decimal','Covered floor area where water consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1129,4,'wat_tot_w','Decimal','Total floor area where water supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1130,4,'wat_abs_lc_bs','Decimal','Absolute and non-normalized water consumption for shared services.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1131,4,'wat_cov_lc_bs','Decimal','Covered floor area where water consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1132,4,'wat_tot_lc_bs','Decimal','Total floor area where water supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1133,4,'wat_abs_lc_bc','Decimal','Absolute and non-normalized water consumption for common areas.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1134,4,'wat_cov_lc_bc','Decimal','Covered floor area where water consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1135,4,'wat_tot_lc_bc','Decimal','Total floor area where water supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1136,4,'wat_abs_lc_t','Decimal','Absolute and non-normalized water consumption for landlord-controlled tenant spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1137,4,'wat_cov_lc_t','Decimal','Covered floor area where water consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1138,4,'wat_tot_lc_t','Decimal','Total floor area where water supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1139,4,'wat_abs_tc_t','Decimal','Absolute and non-normalized water consumption for tenant-controlled tenant spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1140,4,'wat_cov_tc_t','Decimal','Covered floor area where water consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1141,4,'wat_tot_tc_t','Decimal','Total floor area where water supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1142,4,'wat_abs_lc_o','Decimal','Absolute and non-normalized water consumption for landlord-controlled outdoor spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1143,4,'wat_abs_tc_o','Decimal','Absolute and non-normalized water consumption for tenant-controlled outdoor spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1144,4,'wat_rec_ons_reu','Decimal','Volume of greywater and/or blackwater reused in on-site activities.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1145,4,'wat_rec_ons_cap','Decimal','Volume of rainwater, fog, or condensate that is treated and purified for reuse and/or recycling.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1146,4,'wat_rec_ons_ext','Decimal','Volume of extracted groundwater that is treated and purified for reuse and/or recycling.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1147,4,'wat_rec_ofs_pur','Decimal','Volume of recycled water purchased from a third party.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1148,5,'was_data_from','Date','Date within reporting year from which waste data is available.','',NULL,1,'The start date of the period that provided data covers');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1149,5,'was_data_to','Date','Date within reporting year to which waste data is available.','',NULL,1,'The end date of the period that provided data covers');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1150,5,'was_abs_haz','Decimal','Absolute and non-normalized hazardous waste produced by asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1151,5,'was_abs_nhaz','Decimal','Absolute and non-normalized non-hazardous waste produced by asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1152,5,'was_pcov','Decimal','Percent coverage out of total asset size where waste data is collected.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1153,5,'was_pabs_lf','Decimal','Percentage of total waste sent to landfill.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1154,5,'was_pabs_in','Decimal','Percentage of total waste incinerated.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1155,5,'was_pabs_ru','Decimal','Percentage of total waste reused.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1156,5,'was_pabs_wte','Decimal','Percentage of total waste converted to energy.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1157,5,'was_pabs_rec','Decimal','Percentage of total waste recycled.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1158,5,'was_pabs_oth','Decimal','Percentage of total waste where disposal route is other or unknown.','%',NULL);
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1104 WHERE gresb_indicator_id = 58;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1103 WHERE gresb_indicator_id = 57;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1077 WHERE gresb_indicator_id = 4;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1078 WHERE gresb_indicator_id = 5;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1079 WHERE gresb_indicator_id = 6;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1080 WHERE gresb_indicator_id = 7;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1081 WHERE gresb_indicator_id = 8;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1082 WHERE gresb_indicator_id = 9;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1074 WHERE gresb_indicator_id = 1;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1075 WHERE gresb_indicator_id = 2;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1076 WHERE gresb_indicator_id = 3;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1102 WHERE gresb_indicator_id = 20;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1101 WHERE gresb_indicator_id = 19;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1068 WHERE gresb_indicator_id = 13;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1069 WHERE gresb_indicator_id = 14;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1070 WHERE gresb_indicator_id = 15;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1071 WHERE gresb_indicator_id = 16;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1072 WHERE gresb_indicator_id = 17;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1073 WHERE gresb_indicator_id = 18;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1065 WHERE gresb_indicator_id = 10;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1066 WHERE gresb_indicator_id = 11;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1067 WHERE gresb_indicator_id = 12;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1086 WHERE gresb_indicator_id = 24;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1087 WHERE gresb_indicator_id = 25;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1088 WHERE gresb_indicator_id = 26;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1089 WHERE gresb_indicator_id = 27;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1090 WHERE gresb_indicator_id = 28;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1091 WHERE gresb_indicator_id = 29;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1083 WHERE gresb_indicator_id = 21;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1084 WHERE gresb_indicator_id = 22;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1085 WHERE gresb_indicator_id = 23;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1095 WHERE gresb_indicator_id = 33;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1096 WHERE gresb_indicator_id = 34;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1097 WHERE gresb_indicator_id = 35;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1098 WHERE gresb_indicator_id = 36;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1099 WHERE gresb_indicator_id = 37;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1100 WHERE gresb_indicator_id = 38;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1092 WHERE gresb_indicator_id = 30;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1093 WHERE gresb_indicator_id = 31;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1094 WHERE gresb_indicator_id = 32;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1124 WHERE gresb_indicator_id = 68;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1110 WHERE gresb_indicator_id = 59;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1111 WHERE gresb_indicator_id = 60;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1112 WHERE gresb_indicator_id = 61;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1115 WHERE gresb_indicator_id = 63;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1116 WHERE gresb_indicator_id = 64;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1120 WHERE gresb_indicator_id = 65;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1121 WHERE gresb_indicator_id = 66;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1122 WHERE gresb_indicator_id = 67;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1157 WHERE gresb_indicator_id = 100;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1156 WHERE gresb_indicator_id = 99;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1154 WHERE gresb_indicator_id = 96;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1153 WHERE gresb_indicator_id = 97;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1158 WHERE gresb_indicator_id = 102;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1143 WHERE gresb_indicator_id = 89;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1133 WHERE gresb_indicator_id = 70;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1134 WHERE gresb_indicator_id = 71;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1135 WHERE gresb_indicator_id = 72;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1142 WHERE gresb_indicator_id = 76;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1130 WHERE gresb_indicator_id = 73;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1131 WHERE gresb_indicator_id = 74;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1132 WHERE gresb_indicator_id = 75;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1136 WHERE gresb_indicator_id = 77;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1137 WHERE gresb_indicator_id = 78;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1138 WHERE gresb_indicator_id = 79;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1139 WHERE gresb_indicator_id = 80;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1140 WHERE gresb_indicator_id = 81;
UPDATE csr.gresb_indicator_mapping SET gresb_indicator_id = 1141 WHERE gresb_indicator_id = 82;
DELETE FROM csr.gresb_indicator_mapping WHERE gresb_indicator_id < 1000;
DELETE FROM csr.gresb_indicator WHERE gresb_indicator_id < 1000;
BEGIN
	FOR r IN (
		SELECT issue_id, parent_id
		  FROM csr.issue
		 WHERE issue_type_id = 1 --csr.csr_data_pkg.ISSUE_DATA_ENTRY
		   AND deleted = 0
		   AND parent_id IS NOT NULL
		   AND issue_sheet_value_id IS NULL
	) LOOP
		UPDATE csr.issue
		   SET issue_sheet_value_id = (
				SELECT issue_sheet_value_id
				  FROM csr.issue
				 WHERE issue_id = r.parent_id
			)
		 WHERE issue_id = r.issue_id;
	END LOOP;
END;
/






@..\unit_test_pkg
@..\audit_pkg
@..\factor_pkg
@..\property_pkg
@..\schema_pkg
@..\tests\issue_test_pkg


@..\unit_test_body
@..\factor_body
@..\audit_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\chain_body
@..\non_compliance_report_body
@..\enable_body
@..\gresb_config_body
@..\csr_app_body
@..\property_body
@..\property_report_body
@..\region_body
@..\issue_body
@..\tests\issue_test_body



@update_tail
