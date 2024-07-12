prompt please enter host NAME AND usr (ie: foo.credit360.com, foobar)


set echo on
whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

define host='&&1'
define usr='&&2'

exec security.user_pkg.logonadmin('&&host');

DECLARE
    v_exists NUMBER;
BEGIN
    SELECT count(*)
      INTO v_exists
      FROM all_users
     WHERE username = upper('&&2');
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE 'create user &&2 identified by &&2 temporary tablespace temp default tablespace users quota unlimited on users';
    END IF;
END;
/

GRANT SELECT ON cms.CONTEXT TO &&2;
GRANT SELECT ON cms.fast_context TO &&2;
GRANT EXECUTE ON cms.tab_pkg TO &&2;
GRANT EXECUTE ON SECURITY.security_pkg TO &&2;

-- Drop relevent tables
DECLARE
    TYPE t_tabs IS TABLE OF VARCHAR2(40);
    v_list t_tabs := t_tabs(
        'CERTIFICATION',
        'CERTIFICATION_TYPE',
        'CERTIFICATION_LEVEL'
    );
BEGIN
    cms.tab_pkg.enabletrace;
    FOR i IN 1 .. v_list.count 
    LOOP
        -- USER, table_name, cascade, drop physical
        cms.tab_pkg.DropTable('&&usr', v_list(i), true, true);
    END LOOP;
END;
/
-- CERTIFICATION_TYPE
CREATE TABLE &&usr..CERTIFICATION_TYPE (
    CERTIFICATION_TYPE_ID    NUMBER(10) NOT NULL,
    LABEL                    VARCHAR2(255) NOT NULL,
    HIDDEN             NUMBER(1) DEFAULT 0 NOT NULL,
    POS                NUMBER(10) NOT NULL,
    CONSTRAINT PK_CERTIFICATION_TYPE PRIMARY KEY (CERTIFICATION_TYPE_ID)
);

BEGIN
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (1, 'BREEAM-In Use', 1);
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (2, 'BREEAM-NC', 2);
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (6, 'Green Globes-EB', 6);
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (7, 'Green Globes-NC', 7);
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (12, 'LEED-CS', 12);
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (13, 'LEED-EB', 13);
    INSERT INTO &&usr..CERTIFICATION_TYPE (CERTIFICATION_TYPE_ID, LABEL, POS) VALUES (14, 'LEED-NC', 14);
END;
/

COMMENT ON TABLE &&usr..CERTIFICATION_TYPE IS 'desc="Certification type"';
COMMENT ON COLUMN &&usr..CERTIFICATION_TYPE.CERTIFICATION_TYPE_ID IS 'desc="Ref",auto';
COMMENT ON COLUMN &&usr..CERTIFICATION_TYPE.LABEL IS 'desc="Certification Name"';
COMMENT ON COLUMN &&usr..CERTIFICATION_TYPE.HIDDEN IS 'desc="Hidden?",bool';
COMMENT ON COLUMN &&usr..CERTIFICATION_TYPE.POS IS 'desc="Position",pos';

-- CERTIFICATION_LEVEL
CREATE TABLE &&usr..CERTIFICATION_LEVEL (
    CERTIFICATION_TYPE_ID     NUMBER(10) NOT NULL,
    CERTIFICATION_LEVEL_ID    NUMBER(10) NOT NULL,
    LABEL                     VARCHAR2(255) NOT NULL,
    HIDDEN             NUMBER(1) DEFAULT 0 NOT NULL,
    POS                NUMBER(10) NOT NULL,
    CONSTRAINT PK_CERTIFICATION_LEVEL PRIMARY KEY (CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID)
);

ALTER TABLE &&usr..CERTIFICATION_LEVEL ADD CONSTRAINT FK_CERT_LVL_CERT_TYP
    FOREIGN KEY (CERTIFICATION_TYPE_ID) REFERENCES &&usr..CERTIFICATION_TYPE(CERTIFICATION_TYPE_ID);

BEGIN
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 1, 15,'Pass');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 12, 10,'Certified');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 13, 10,'Certified');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 14, 10,'Certified');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 2, 15,'Pass');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 6, 1,'1');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (1, 7, 1,'1');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 1, 13,'Good');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 12, 18,'Silver');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 13, 18,'Silver');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 14, 18,'Silver');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 2, 13,'Good');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 6, 2,'2');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (2, 7, 2,'2');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 1, 19,'Very Good');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 12, 12,'Gold');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 13, 12,'Gold');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 14, 12,'Gold');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 2, 19,'Very Good');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 6, 3,'3');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (3, 7, 3,'3');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 1, 11,'Excellent');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 12, 16,'Platinum');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 13, 16,'Platinum');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 14, 16,'Platinum');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 2, 11,'Excellent');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 6, 4,'4');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (4, 7, 4,'4');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (5, 1, 14,'Outstanding');
    INSERT INTO &&usr..CERTIFICATION_LEVEL (POS, CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID, LABEL) VALUES (5, 2, 14,'Outstanding');
END;
/

COMMENT ON TABLE &&usr..CERTIFICATION_LEVEL IS 'desc="Certification level"';
COMMENT ON COLUMN &&usr..CERTIFICATION_LEVEL.CERTIFICATION_LEVEL_ID IS 'desc="Ref",auto';
COMMENT ON COLUMN &&usr..CERTIFICATION_LEVEL.CERTIFICATION_TYPE_ID IS 'desc="Certification type",enum,enum_desc_col=label';
COMMENT ON COLUMN &&usr..CERTIFICATION_LEVEL.LABEL IS 'desc="Certification level name"';
COMMENT ON COLUMN &&usr..CERTIFICATION_LEVEL.HIDDEN IS 'desc="Hidden?",bool';
COMMENT ON COLUMN &&usr..CERTIFICATION_LEVEL.POS IS 'desc="Position",pos';

/********************************************************************************
 TABLES
 ********************************************************************************/
-- CERTIFICATION
CREATE TABLE &&usr..CERTIFICATION (
    CERTIFICATION_ID          NUMBER(10) NOT NULL,
    APP_SID                NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID             NUMBER(10) NOT NULL,
    CERTIFICATION_TYPE_ID     NUMBER(10) NOT NULL,
    CERTIFICATION_LEVEL_ID    NUMBER(10),
    REFERENCE                 VARCHAR2(32),
    EFFECTIVE_DATE            DATE,
    EXPIRATION_DATE            DATE,
    CONSTRAINT PK_CERTIFICATION PRIMARY KEY (CERTIFICATION_ID)
);

ALTER TABLE &&usr..CERTIFICATION ADD CONSTRAINT FK_CRTFCTION_CRTFCTION_LEVEL
    FOREIGN KEY (CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID)
    REFERENCES &&usr..CERTIFICATION_LEVEL(CERTIFICATION_TYPE_ID, CERTIFICATION_LEVEL_ID);


COMMENT ON TABLE &&usr..CERTIFICATION IS 'desc="Certification"';
COMMENT ON COLUMN &&usr..CERTIFICATION.CERTIFICATION_ID IS 'desc="Ref",auto';
COMMENT ON COLUMN &&usr..CERTIFICATION.APP_SID IS 'desc="Customer Ref",app';
COMMENT ON COLUMN &&usr..CERTIFICATION.REGION_SID IS 'desc="Region",region';
COMMENT ON COLUMN &&usr..CERTIFICATION.CERTIFICATION_TYPE_ID IS 'desc="Certification",cascade_enum,enum_desc_col=label,enum_hidden_col=hidden,enum_pos_col=pos';
COMMENT ON COLUMN &&usr..CERTIFICATION.CERTIFICATION_LEVEL_ID IS 'desc="Level",cascade_enum,enum_desc_col=label,enum_hidden_col=hidden,enum_pos_col=pos';
COMMENT ON COLUMN &&usr..CERTIFICATION.REFERENCE IS 'desc="Reference"';
COMMENT ON COLUMN &&usr..CERTIFICATION.EFFECTIVE_DATE IS 'desc="Effective date"';
COMMENT ON COLUMN &&usr..CERTIFICATION.EXPIRATION_DATE IS 'desc="Expiration date"';

/********************************************************************************
 CROSS-TABLE CONSTRAINTS
 ********************************************************************************/
/********************************************************************************
 TABLE REGISTRATION
 ********************************************************************************/
spool registerTables.log
BEGIN
    cms.tab_pkg.enabletrace;
    cms.tab_pkg.registertable(UPPER('&&usr'), 'CERTIFICATION_TYPE,CERTIFICATION_LEVEL', FALSE);
    cms.tab_pkg.registertable(UPPER('&&usr'), 'CERTIFICATION', TRUE);
END;
/

COMMIT;

 /************************** GRANTS ***************************************/
PROMPT >> GRANT PERMISSIONS FOR CSR

GRANT SELECT, REFERENCES ON &&2..CERTIFICATION TO csr;
GRANT SELECT, REFERENCES ON &&2..CERTIFICATION_TYPE TO csr;
GRANT SELECT, REFERENCES ON &&2..CERTIFICATION_LEVEL TO csr;

/************************** PROPERTY TABS ***************************************/
PROMPT >> TURN ON PROPERTY TABS

DECLARE
    v_plugin_id        NUMBER(10);
    v_dummy_cur        security.security_pkg.T_OUTPUT_CUR;
BEGIN
    security.user_pkg.logonadmin('&&host');
    v_plugin_id := csr.property_pkg.SetCmsPlugin(
        in_tab_sid            => cms.tab_pkg.GetTableSid(UPPER('&&usr'), 'CERTIFICATION'),
        in_form_path        => '/csr/forms/certification_grid.xml',
        in_description        => 'Certifications'
    );
    
    csr.property_pkg.SavePropertyTab(
        in_plugin_id        => v_plugin_id,
        in_tab_label        => 'Certifications',
        in_pos                => 3,
        out_cur                => v_dummy_cur
    );
END;
/


/************************** MENU ***************************************/
PROMPT >> ADD MENU ITEMS

DECLARE
    v_app_sid               SECURITY.SECURITY_PKG.T_SID_ID; 
    v_act_id                SECURITY.SECURITY_PKG.T_ACT_ID;
    v_www_sid               SECURITY.SECURITY_PKG.T_SID_ID;
    v_www_csr          SECURITY.SECURITY_PKG.T_SID_ID;
    v_registeredUsers_sid   SECURITY.SECURITY_PKG.T_SID_ID;
    v_administrators_sid    SECURITY.SECURITY_PKG.T_SID_ID;
    v_root_analysis_sid     SECURITY.SECURITY_PKG.T_SID_ID;
    v_root_setup_sid        SECURITY.SECURITY_PKG.T_SID_ID;
    v_cert_table_sid        SECURITY.SECURITY_PKG.T_SID_ID;
    v_forms_sid             SECURITY.SECURITY_PKG.T_SID_ID;
    v_cert_admin_sid        SECURITY.SECURITY_PKG.T_SID_ID;
    v_cert_level_admin_sid  SECURITY.SECURITY_PKG.T_SID_ID;
BEGIN 
    security.user_pkg.logonadmin('&&1');
    
    v_app_sid := security.security_pkg.GetApp;
    v_act_id := security.security_pkg.GetAct;
    v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
    v_www_csr := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr');
    v_registeredUsers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/RegisteredUsers');
    v_administrators_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/Administrators');
    v_root_analysis_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/Analysis');
    v_root_setup_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/Setup');
    v_cert_table_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'cms/"&&2"."CERTIFICATION"');
    
    BEGIN
        
        -- create menu for analysis/project pivot
        security.menu_pkg.CreateMenu(v_act_id, v_root_analysis_sid, 'csr_pivot_certs', 'Pivot Certifications', '/fp/cms/analysis/pivot.acds?tabSid='||v_cert_table_sid, -1, null, v_root_analysis_sid);
        security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_root_analysis_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_administrators_sid, security.security_pkg.PERMISSION_STANDARD_READ);
        
        -- create menu for Admin/Manage Certifications
        security.menu_pkg.CreateMenu(v_act_id, v_root_setup_sid, 'csr_cert_admin', 'Property Certifications', '/fp/cms/form.acds?_FORM_PATH=%2Fcsr%2Fforms%2FCERTIFICATION_TYPE_LIST.xml', -1, null, v_cert_admin_sid);
        
        -- create menu for Admin/Manage Certifications Levels
        security.menu_pkg.CreateMenu(v_act_id, v_root_setup_sid, 'csr_cert_level_admin', 'Property Certification Levels', '/fp/cms/form.acds?_FORM_PATH=%2Fcsr%2Fforms%2FCERTIFICATION_LEVEL_LIST.xml', -1, null, v_cert_level_admin_sid);

        --Create links to CSR folder for forms
        security.web_pkg.createResource(v_act_id, v_www_sid, v_www_csr, 'forms', v_forms_sid);
        security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_forms_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 1, v_registeredUsers_sid, security.security_pkg.PERMISSION_STANDARD_READ);

        --Give registered users the ability to write to the new Certification table
        security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cert_table_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 1, v_registeredUsers_sid, security.security_pkg.PERMISSION_STANDARD_ALL);


    END;
END;
/
 

commit;

spool off
 
exit;
