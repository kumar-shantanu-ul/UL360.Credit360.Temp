define version=3281
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
CREATE TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COMPLIANCE_ITEM_VERSION_LOG_ID	NUMBER(10, 0) NOT NULL,
	COMPLIANCE_ITEM_ID				NUMBER(10, 0) NOT NULL,
	CHANGE_TYPE						NUMBER(10, 0),
	MAJOR_VERSION					NUMBER(10, 0) NOT NULL,
	MINOR_VERSION					NUMBER(10, 0) NOT NULL,
	IS_MAJOR_CHANGE					NUMBER(1, 0),
	DESCRIPTION						CLOB,
	CHANGE_DTM						DATE,
	LANG_ID							NUMBER(10, 0),
	CONSTRAINT PK_COMPLIANCE_ITEM_VERSION_LOG PRIMARY KEY (APP_SID, COMPLIANCE_ITEM_VERSION_LOG_ID)
);
CREATE SEQUENCE CSR.COMP_ITEM_VERSION_LOG_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE INDEX CSR.IX_CIVL_CI ON CSR.COMPLIANCE_ITEM_VERSION_LOG (APP_SID, COMPLIANCE_ITEM_ID);
CREATE INDEX CSR.IX_CIVL_CI_CT ON CSR.COMPLIANCE_ITEM_VERSION_LOG (CHANGE_TYPE);
CREATE TABLE CSRIMP.COMPLIANCE_ITEM_VERSION_LOG (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPLIANCE_ITEM_VERSION_LOG_ID	NUMBER(10, 0) NOT NULL,
	COMPLIANCE_ITEM_ID				NUMBER(10, 0) NOT NULL,
	CHANGE_TYPE						NUMBER(10, 0),
	MAJOR_VERSION					NUMBER(10, 0) NOT NULL,
	MINOR_VERSION					NUMBER(10, 0) NOT NULL,
	IS_MAJOR_CHANGE					NUMBER(1, 0),
	DESCRIPTION						CLOB,
	CHANGE_DTM					 	DATE NOT NULL,
	LANG_ID							NUMBER(10, 0),
	CONSTRAINT PK_COMPLIANCE_ITEM_VERSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_ITEM_VERSION_LOG_ID),
	CONSTRAINT FK_COMP_ITEM_VERSION_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID)
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_COMP_ITEM_VERSION_LOG (
	CSRIMP_SESSION_ID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMP_ITEM_VERSION_LOG_ID			NUMBER(10) NOT NULL,
	NEW_COMP_ITEM_VERSION_LOG_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMP_ITEM_VERSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMP_ITEM_VERSION_LOG_ID),
	CONSTRAINT UK_MAP_COMP_ITEM_VERSION_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_COMP_ITEM_VERSION_LOG_ID),
	CONSTRAINT FK_MAP_COMP_ITEM_VERSION_LOG FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.gresb_property_sub_type (
    gresb_property_type_id      NUMBER(10),
    gresb_property_sub_type_id  NUMBER(10),
    name                        VARCHAR2(255),
    gresb_code                  VARCHAR2(255),
    pos                         NUMBER(2),
    CONSTRAINT pk_gresb_property_sub_type PRIMARY KEY (gresb_property_type_id, gresb_property_sub_type_id),
    CONSTRAINT uk_gresb_prop_sub_type_code UNIQUE (gresb_code)
);


ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG ADD CONSTRAINT UK_CIVL_I
	UNIQUE (APP_SID, COMPLIANCE_ITEM_ID, MAJOR_VERSION, MINOR_VERSION, IS_MAJOR_CHANGE);
;
ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG ADD CONSTRAINT FK_CIVL_CI
	FOREIGN KEY (APP_SID, COMPLIANCE_ITEM_ID)
	REFERENCES CSR.COMPLIANCE_ITEM(APP_SID, COMPLIANCE_ITEM_ID)
;
ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG ADD CONSTRAINT FK_CIVL_CI_CT 
	FOREIGN KEY (change_type)
	REFERENCES csr.compliance_item_change_type (compliance_item_change_type_id)
;
ALTER TABLE csr.property_type DROP COLUMN gresb_prop_type_code;
ALTER TABLE csr.property_type ADD (gresb_property_type_id NUMBER(10));
ALTER TABLE csr.property_sub_type ADD (
	gresb_property_type_id NUMBER(10),
	gresb_property_sub_type_id NUMBER(10)
);
TRUNCATE TABLE csr.gresb_property_type;
ALTER TABLE csr.gresb_property_type DROP PRIMARY KEY CASCADE DROP INDEX;
ALTER TABLE csr.gresb_property_type DROP COLUMN code;
ALTER TABLE csr.gresb_property_type ADD (
    gresb_property_type_id  NUMBER(10),
    pos                     NUMBER(2)
);
ALTER TABLE csr.gresb_property_type ADD CONSTRAINT pk_gresb_property_type PRIMARY KEY (gresb_property_type_id);
ALTER TABLE csr.property_type ADD CONSTRAINT fk_prop_type_gresb_prop_type
	FOREIGN KEY (gresb_property_type_id)
	REFERENCES csr.gresb_property_type(gresb_property_type_id);
ALTER TABLE csr.property_sub_type ADD CONSTRAINT fk_prop_stype_gresb_prop_stype
	FOREIGN KEY (gresb_property_type_id, gresb_property_sub_type_id)	
	REFERENCES csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id);
ALTER TABLE csrimp.property_type DROP COLUMN gresb_prop_type_code;
ALTER TABLE csrimp.property_type ADD (gresb_property_type_id NUMBER(10));
ALTER TABLE csrimp.property_sub_type ADD (
	gresb_property_type_id NUMBER(10),
	gresb_property_sub_type_id NUMBER(10)
);
CREATE INDEX csr.ix_prop_sub_type_gresb ON csr.property_sub_type (gresb_property_type_id, gresb_property_sub_type_id);
CREATE INDEX csr.ix_prop_type_gresb ON csr.property_type (gresb_property_type_id);


GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_version_log TO csrimp;
GRANT SELECT ON csr.comp_item_version_log_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_version_log TO tool_user;








INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (1, 'Retail', 0);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (2, 'Office', 1);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (3, 'Industrial', 2);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (4, 'Residential', 3);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (5, 'Hotel', 4);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (6, 'Lodging, Leisure '||CHR(38)||' Recreation', 5);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (7, 'Education', 6);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (8, 'Technology/Science', 7);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (9, 'Healthcare', 8);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (10, 'Mixed use', 9);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (11, 'Other', 10);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 1, 'High Street', 'REHS', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 2, 'Retail Centers: Shopping Center', 'RCSC', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 3, 'Retail Centers: Strip Mall', 'RCSM', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 4, 'Retail Centers: Lifestyle Center', 'RCLC', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 5, 'Retail Centers: Warehouse', 'RCWH', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 6, 'Restaurants/Bars', 'RRBA', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 7, 'Other', 'REOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 1, 'Corporate: Low-Rise Office', 'OCLO', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 2, 'Corporate: Mid-Rise Office', 'OCMI', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 3, 'Corporate: High-Rise Office', 'OCHI', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 4, 'Medical Office', 'OFMO', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 5, 'Business Park', 'OFBP', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 6, 'Other', 'OFOT', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 1, 'Distribution Warehouse', 'INDW', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 2, 'Industrial Park', 'INIP', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 3, 'Manufacturing', 'INMA', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 4, 'Other', 'INOT', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 1, 'Multi-Family: Low-Rise Multi-Family', 'RMFL', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 2, 'Multi-Family: Mid-Rise Multi Family', 'RMFM', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 3, 'Multi-Family: High-Rise Multi-Family', 'RMFH', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 4, 'Family Homes', 'RSFH', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 5, 'Student Housing', 'RSSH', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 6, 'Retirement Living', 'RSRL', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 7, 'Other', 'RSOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (5, 1, 'Hotel', 'HTL', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 1, 'Lodging, Leisure '||CHR(38)||' Recreation', 'LLO', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 2, 'Indoor Arena', 'LLIA', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 3, 'Fitness Center', 'LLFC', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 4, 'Performing Arts', 'LLPA', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 5, 'Swimming Center', 'LLSC', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 6, 'Museum/Gallery', 'LLMG', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 7, 'Other', 'LLOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 1, 'School', 'EDSC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 2, 'University', 'EDUN', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 3, 'Library', 'EDLI', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 4, 'Other', 'EDOT', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 1, 'Data Center', 'TSDC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 2, 'Laboratory/Life Sciences', 'TSLS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 3, 'Other', 'TSOT', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 1, 'Healthcare Center', 'HEHC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 2, 'Senior Homes', 'HESH', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 3, 'Other', 'HEOT', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 1, 'Office/Retail', 'XORE', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 2, 'Office/Residential', 'XORS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 3, 'Office/Industrial', 'XOIN', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 4, 'Other', 'XOTH', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 1, 'Parking (Indoors)', 'OTPI', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 2, 'Self-Storage', 'OTSS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 3, 'Other', 'OTHR', 2);
UPDATE csr.module SET license_warning = 1 WHERE license_warning IS NULL AND module_id = 84; 
DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_www_root			security.security_pkg.T_SID_ID;
	v_www_api_security	security.security_pkg.T_SID_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin;
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		  JOIN security.website w ON c.app_sid = w.application_sid_id AND LOWER(c.host) = LOWER(w.website_name)
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_act_id := security.security_pkg.getact;
		v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		-- web resource for the api
		BEGIN
			v_www_api_security := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'api.translations');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'api.translations', v_www_api_security);
		END;
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_security), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/






@..\compliance_pkg
@..\schema_pkg
@..\property_pkg


@..\factor_body
@..\csr_user_body
@..\compliance_body
@..\schema_body
@..\csrimp\imp_body
 
@..\property_body
@..\region_body
@..\util_script_body
@..\branding_body



@update_tail
