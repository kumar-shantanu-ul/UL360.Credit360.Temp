define version=3385
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

CREATE TABLE csr.sustainability_essentials_enable(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	version					VARCHAR2(100) NOT NULL,
	enabled_modules_json	CLOB,
	CONSTRAINT pk_sustainability_essentials_enable PRIMARY KEY (app_sid)
);
CREATE TABLE csr.sustainability_essentials_object_map(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	object_ref				VARCHAR2(1024) NOT NULL,
	created_object_id		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_sustainability_essentials_object_map PRIMARY KEY (app_sid, object_ref, created_object_id)
);


ALTER TABLE csr.region_certificates
ADD external_certificate_id VARCHAR2(255);
ALTER TABLE csrimp.region_certificates
ADD external_certificate_id VARCHAR2(255);
ALTER TABLE csr.region_certificates
ADD CONSTRAINT UK_REG_CERT_EXT_ID UNIQUE (app_sid, region_sid, certification_id, certification_level_id, external_certificate_id);
DROP TABLE csr.region_certificates;
DROP TABLE csrimp.region_certificates;
DROP TABLE csr.region_energy_ratings;
DROP TABLE csrimp.region_energy_ratings;
CREATE SEQUENCE CSR.REGION_CERTIFICATE_ID_SEQ;
CREATE TABLE CSR.REGION_CERTIFICATE (
	APP_SID						NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_CERTIFICATE_ID		NUMBER(24,0) NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_LEVEL_ID		NUMBER(10,0),
	CERTIFICATE_NUMBER			NUMBER(10,0),
	FLOOR_AREA					NUMBER(10,2) NOT NULL,
	ISSUED_DTM					DATE,
	EXPIRY_DTM					DATE,
	EXTERNAL_CERTIFICATE_ID		NUMBER(10,0),
	DELETED						NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_REGION_CERTS PRIMARY KEY (APP_SID, REGION_CERTIFICATE_ID),
	CONSTRAINT UK_REG_CERT_EXT_ID UNIQUE (APP_SID, REGION_SID, CERTIFICATION_ID, CERTIFICATION_LEVEL_ID, EXTERNAL_CERTIFICATE_ID),
	CONSTRAINT CHK_REGION_CERT_EXP_AFTER_ISS CHECK ((ISSUED_DTM IS NULL OR EXPIRY_DTM IS NULL) OR (ISSUED_DTM IS NOT NULL AND EXPIRY_DTM IS NOT NULL AND ISSUED_DTM < EXPIRY_DTM)),
	CONSTRAINT CK_REGION_CERT_DELETED CHECK (DELETED in (0,1))
)
;
ALTER TABLE CSR.REGION_CERTIFICATE ADD CONSTRAINT FK_REG_CERT_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.REGION_CERTIFICATE ADD CONSTRAINT FK_REG_CERT_CERT_ID
	FOREIGN KEY (CERTIFICATION_ID)
	REFERENCES CSR.CERTIFICATION(CERTIFICATION_ID)
;
ALTER TABLE CSR.REGION_CERTIFICATE ADD CONSTRAINT FK_REG_CERT_CERT_LVL
	FOREIGN KEY (CERTIFICATION_LEVEL_ID, CERTIFICATION_ID)
	REFERENCES CSR.CERTIFICATION_LEVEL(CERTIFICATION_LEVEL_ID, CERTIFICATION_ID)
;
CREATE TABLE CSRIMP.REGION_CERTIFICATE (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_LEVEL_ID		NUMBER(10,0),
	CERTIFICATE_NUMBER			NUMBER(10,0),
	FLOOR_AREA					NUMBER(10,2) NOT NULL,
	ISSUED_DTM					DATE,
	EXPIRY_DTM					DATE,
	EXTERNAL_CERTIFICATE_ID		NUMBER(10,0),
	DELETED						NUMBER(1, 0) NOT NULL,
	CONSTRAINT CK_REGION_CERT_DELETED CHECK (DELETED in (0,1))
);
CREATE TABLE CSR.REGION_ENERGY_RATING (
	APP_SID						NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	ENERGY_RATING_ID			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,2) NOT NULL,
	ISSUED_DTM					DATE,
	EXPIRY_DTM					DATE,
	CONSTRAINT PK_REGION_ENERGY_RAT PRIMARY KEY (APP_SID, REGION_SID),
	CONSTRAINT CHK_REGION_ENERGY_RAT_EXP_AFTER_ISS CHECK ((ISSUED_DTM IS NULL OR EXPIRY_DTM IS NULL) OR (ISSUED_DTM IS NOT NULL AND EXPIRY_DTM IS NOT NULL AND ISSUED_DTM < EXPIRY_DTM))
)
;
ALTER TABLE CSR.REGION_ENERGY_RATING ADD CONSTRAINT FK_REG_ENE_RAT_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.REGION_ENERGY_RATING ADD CONSTRAINT FK_REG_ENE_RAT_ID
	FOREIGN KEY (ENERGY_RATING_ID)
	REFERENCES CSR.ENERGY_RATING(ENERGY_RATING_ID)
;
CREATE TABLE CSRIMP.REGION_ENERGY_RATING (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	ENERGY_RATING_ID			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,2) NOT NULL,
	ISSUED_DTM					DATE,
	EXPIRY_DTM					DATE
);
CREATE INDEX CSR.IX_REGION_CERTIF_CERTIFICATION ON CSR.REGION_CERTIFICATE (CERTIFICATION_ID);
CREATE INDEX CSR.IX_REGION_CERTIF_CERTIF_LEVEL ON CSR.REGION_CERTIFICATE (CERTIFICATION_LEVEL_ID, CERTIFICATION_ID);
CREATE INDEX CSR.IX_REGION_ENERGY_ENERGY_RATING ON CSR.REGION_ENERGY_RATING (ENERGY_RATING_ID);
ALTER TABLE csr.integration_question_answer RENAME COLUMN answer TO answer_old;
ALTER TABLE csr.integration_question_answer ADD answer CLOB;
UPDATE csr.integration_question_answer
   SET answer = answer_old;
ALTER TABLE csr.integration_question_answer DROP COLUMN answer_old;
ALTER TABLE csrimp.integration_question_answer RENAME COLUMN answer TO answer_old;
ALTER TABLE csrimp.integration_question_answer ADD answer CLOB;
UPDATE csrimp.integration_question_answer
   SET answer = answer_old;
ALTER TABLE csrimp.integration_question_answer DROP COLUMN answer_old;


grant select on csr.region_certificate_id_seq to csrimp;
grant select,insert, update on csr.region_certificate to csrimp;
grant select,insert,update,delete on csrimp.region_certificate to tool_user;
grant select,insert, update on csr.region_energy_rating to csrimp;
grant select,insert,update,delete on csrimp.region_energy_rating to tool_user;








INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1160,1,'certifications','Certifications','GRESB asset certifications.',NULL,NULL,1,'Property certifications');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1161, 1, 'ratings', 'Ratings', 'GRESB asset ratings.', NULL, NULL, 1, 'Property ratings');




create or replace package CSR.SUSTAIN_ESSENTIALS_PKG as
procedure dummy;
end;
/
create or replace package body CSR.SUSTAIN_ESSENTIALS_PKG as
procedure dummy
as
begin
	null;
end;
end;
/
GRANT EXECUTE ON CSR.SUSTAIN_ESSENTIALS_PKG TO WEB_USER;
GRANT EXECUTE ON CSR.SUSTAIN_ESSENTIALS_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.FACTOR_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.PORTLET_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.INDICATOR_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.CALC_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.MEASURE_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.INDICATOR_API_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.TAG_PKG TO TOOL_USER;


@..\property_pkg
@..\region_certificate_pkg
@..\unit_test_pkg
@..\schema_pkg
@..\integration_question_answer_pkg
@..\integration_question_answer_report_pkg
@..\enable_pkg
@..\sustain_essentials_pkg
@..\image_upload_portlet_pkg
@..\alert_pkg
@..\indicator_api_pkg


@..\delegation_body
@..\region_certificate_body
@..\schema_body
@..\csrimp\imp_body
@..\csr_app_body
@..\integration_question_answer_body
@..\integration_question_answer_report_body
@..\enable_body
@..\sustain_essentials_body
@..\image_upload_portlet_body
@..\alert_body
@..\indicator_api_body
@..\scenario_run_body



@update_tail
