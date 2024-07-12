define version=3297
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
CREATE TABLE CSR.SHEET_VALUE_FILE_HIDDEN_CACHE(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_VALUE_ID                 NUMBER(10, 0)     NOT NULL,
	FILE_UPLOAD_SID                NUMBER(10,0)      NOT NULL,
    CONSTRAINT PK_SVFHC PRIMARY KEY (APP_SID, SHEET_VALUE_ID, FILE_UPLOAD_SID)
)
;
CREATE TABLE CSRIMP.SHEET_VALUE_FILE_HIDDEN_CACHE(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_VALUE_ID                 NUMBER(10, 0)     NOT NULL,
	FILE_UPLOAD_SID                NUMBER(10,0)      NOT NULL,
    CONSTRAINT PK_SVFHC PRIMARY KEY (APP_SID, SHEET_VALUE_ID, FILE_UPLOAD_SID)
)
;


ALTER TABLE CSR.SHEET_VALUE_FILE_HIDDEN_CACHE ADD CONSTRAINT FK_SVFHC_FU
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES CSR.FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
;
ALTER TABLE CSR.SHEET_VALUE_FILE_HIDDEN_CACHE ADD CONSTRAINT FK_SVFHC_SV
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES CSR.SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
;
CREATE INDEX CSR.IX_SVFHC_FU ON CSR.SHEET_VALUE_FILE_HIDDEN_CACHE(APP_SID, FILE_UPLOAD_SID);
CREATE INDEX CSR.IX_SVFHC_SV ON CSR.SHEET_VALUE_FILE_HIDDEN_CACHE(APP_SID, SHEET_VALUE_ID);
DELETE FROM cms.tab_column_link
 WHERE column_sid_1 = column_sid_2
   AND item_id_1 = item_id_2;
ALTER TABLE cms.tab_column_link ADD (
	CONSTRAINT ck_tab_column_link_self CHECK (column_sid_1 <> column_sid_2 OR item_id_1 <> item_id_2)
);


GRANT INSERT ON CSR.SHEET_VALUE_FILE_HIDDEN_CACHE TO CSRIMP;
GRANT INSERT,SELECT,UPDATE,DELETE ON CSRIMP.SHEET_VALUE_FILE_HIDDEN_CACHE TO TOOL_USER;








DECLARE
	v_act					security.security_pkg.T_ACT_ID;
	v_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		-- Somehow some sites don't have this web resource... So try creating it (again) first.
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.users', v_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.web_root_sid_id, 'api.users');
		END;
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, security.securableObject_pkg.GetSIDFromPath(v_act, 0, '//BuiltIn/Administrators'), security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/


 




@..\delegation_pkg
@..\schema_pkg
@..\sheet_pkg
@..\customer_pkg
@..\site_name_management_pkg
@..\region_pkg


@..\chain\company_body
@..\csr_app_body
@..\delegation_body
@..\deleg_admin_body
@..\schema_body
@..\sheet_body
@..\csrimp\imp_body
@..\audit_body
@..\enable_body
@..\customer_body
@..\role_body
 
@..\site_name_management_body
@..\region_body
@..\chain\company_request_report_body



@update_tail
