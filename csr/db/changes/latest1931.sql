-- Please update version.sql too -- this keeps clean builds in sync
define version=1931
@update_header

DECLARE
    new_class_id    security.security_pkg.T_SID_ID;
    v_act           security.security_pkg.T_ACT_ID;
BEGIN
    security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act); 
    BEGIN   
        security.class_pkg.CreateClass(v_act, null, 'Teamroom', 'csr.teamroom_pkg', null, new_class_id);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            new_class_id := security.class_pkg.getClassId('Teamroom');
    END;
    BEGIN
        security.class_pkg.AddPermission(v_act, new_class_id, 65536, 'Administer teamroom');
        security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_TAKE_OWNERSHIP, new_class_id, 65536);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
END;
/

CREATE SEQUENCE CSR.TEAMROOM_EVENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE CSR.TEAMROOM_TYPE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE CSR.USER_MSG_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE CSR.USER_MSG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

ALTER TABLE CSR.DATAVIEW_ZONE ADD (
    CONSTRAINT CHK_DATAVIEW_ZONE_TAR CHECK (IS_TARGET IN (0,1)),
    CONSTRAINT CHK_DATAVIEW_ZONE_DIR CHECK (TARGET_DIRECTION IN (-1,0,1))
);
 
CREATE TABLE CSR.TEAMROOM(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_SID             NUMBER(10, 0)     NOT NULL,
    NAME                     VARCHAR2(255),
    DESCRIPTION              CLOB,
    TEAMROOM_TYPE_ID         NUMBER(10, 0)     NOT NULL,
    DOC_LIBRARY_SID          NUMBER(10, 0),
    IMG_DATA                 BLOB,
    IMG_SHA1                 RAW(20),
    IMG_LAST_MODIFIED_DTM    DATE,
    IMG_MIME_TYPE            VARCHAR2(2000),
    CONSTRAINT CK_TEAMROOM_IMG CHECK ((IMG_DATA IS NULL AND IMG_SHA1 IS NULL AND IMG_LAST_MODIFIED_DTM IS NULL AND IMG_MIME_TYPE IS NULL) OR (IMG_DATA IS NOT NULL AND IMG_SHA1 IS NOT NULL AND IMG_LAST_MODIFIED_DTM IS NOT NULL AND IMG_MIME_TYPE IS NOT NULL)),
    CONSTRAINT PK_TEAMROOM PRIMARY KEY (APP_SID, TEAMROOM_SID)
);

CREATE TABLE CSR.TEAMROOM_EVENT(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_EVENT_ID    NUMBER(10, 0)     NOT NULL,
    TEAMROOM_SID         NUMBER(10, 0)     NOT NULL,
    DESCRIPTION          VARCHAR2(4000),
    START_DTM            DATE              NOT NULL,
    END_DTM              DATE,
    CREATED_BY_SID       NUMBER(10, 0)     NOT NULL,
    CREATED_DTM          DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT CK_TEAMROOM_EVENT_DTM CHECK (END_DTM IS NULL OR END_DTM >= START_DTM),
    CONSTRAINT PK_TEAMROOM_EVENT PRIMARY KEY (APP_SID, TEAMROOM_EVENT_ID)
);

CREATE TABLE CSR.TEAMROOM_ISSUE(
    APP_SID         NUMBER(10, 0)    NOT NULL,
    TEAMROOM_SID    NUMBER(10, 0)    NOT NULL,
    ISSUE_ID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TEAMROOM_ISSUE PRIMARY KEY (APP_SID, TEAMROOM_SID, ISSUE_ID)
);

CREATE TABLE CSR.TEAMROOM_MEMBER(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_SID         NUMBER(10, 0)    NOT NULL,
    USER_SID             NUMBER(10, 0)    NOT NULL,
    INVITED_DTM          DATE             DEFAULT SYSDATE NOT NULL,
    INVITED_BY_SID       NUMBER(10, 0)    NOT NULL,
    ACCEPTED_DTM         DATE,
    DEACTIVATED_DTM      DATE,
    CAN_INVITE_OTHERS    NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CK_TEAMROOM_MBR_CAN_INV CHECK (CAN_INVITE_OTHERS IN (0,1)),
    CONSTRAINT PK_TEAMROOM_MEMBER PRIMARY KEY (APP_SID, TEAMROOM_SID, USER_SID)
);

CREATE TABLE CSR.TEAMROOM_TYPE(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    LABEL               VARCHAR2(255),
    BASE_CSS_CLASS      VARCHAR2(255)    NOT NULL,
    HIDDEN              NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_TEAMROOM_TYPE_HIDDEN CHECK (HIDDEN IN (0,1)),
    CONSTRAINT PK_TEAMROOM_TYPE PRIMARY KEY (APP_SID, TEAMROOM_TYPE_ID)
);

CREATE TABLE CSR.TEAMROOM_TYPE_TAB(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    PLUGIN_ID           NUMBER(10, 0)    NOT NULL,
    PLUGIN_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    POS                 NUMBER(10, 0)    NOT NULL,
    TAB_LABEL           VARCHAR2(50),
    CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE CHECK (PLUGIN_TYPE_ID=5),
    CONSTRAINT PK_TEAMROOM_TYPE_TAB PRIMARY KEY (APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID)
);

CREATE TABLE CSR.TEAMROOM_TYPE_TAB_GROUP(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    PLUGIN_ID           NUMBER(10, 0)    NOT NULL,
    GROUP_SID           NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TEAMROOM_TAB_GROUP PRIMARY KEY (APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID, GROUP_SID)
);

CREATE TABLE CSR.TEAMROOM_USER_MSG(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_SID    NUMBER(10, 0)    NOT NULL,
    USER_MSG_ID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TEAMROOM_USER_MSG PRIMARY KEY (APP_SID, TEAMROOM_SID, USER_MSG_ID)
);

CREATE TABLE CSR.USER_MSG(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USER_MSG_ID        NUMBER(10, 0)    NOT NULL,
    USER_SID           NUMBER(10, 0)    NOT NULL,
    REPLY_TO_MSG_ID    NUMBER(10, 0),
    MSG_TEXT           CLOB             NOT NULL,
    MSG_DTM            DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_USER_MSG PRIMARY KEY (APP_SID, USER_MSG_ID)
);

CREATE TABLE CSR.USER_MSG_FILE(
    APP_SID             NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USER_MSG_FILE_ID    NUMBER(10, 0)     NOT NULL,
    USER_MSG_ID         NUMBER(10, 0)     NOT NULL,
    FILENAME            VARCHAR2(2000)    NOT NULL,
    DATA                BLOB              NOT NULL,
    SHA1                RAW(20)           NOT NULL,
    MIME_TYPE           VARCHAR2(2000)    NOT NULL,
    CONSTRAINT PK_USER_MSG_FILE PRIMARY KEY (APP_SID, USER_MSG_FILE_ID)
);

CREATE TABLE CSR.USER_MSG_LIKE(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USER_MSG_ID          NUMBER(10, 0)    NOT NULL,
    LIKED_BY_USER_SID    NUMBER(10, 0)    NOT NULL,
    LIKED_DTM            DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_USER_MSG_LIKE PRIMARY KEY (APP_SID, USER_MSG_ID, LIKED_BY_USER_SID)
);

CREATE TABLE CSR.TEAMROOM_INITIATIVE(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_SID      NUMBER(10, 0)    NOT NULL,
    INITIATIVE_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TEAMROOM_INITIATIVES PRIMARY KEY (APP_SID, TEAMROOM_SID, INITIATIVE_SID)
);

ALTER TABLE CSR.TEAMROOM ADD CONSTRAINT FK_TEAMROOM_DOCLIB 
    FOREIGN KEY (APP_SID, DOC_LIBRARY_SID)
    REFERENCES CSR.DOC_LIBRARY(APP_SID, DOC_LIBRARY_SID);

ALTER TABLE CSR.TEAMROOM ADD CONSTRAINT FK_TEAMROOM_TMRM_TYPE 
    FOREIGN KEY (APP_SID, TEAMROOM_TYPE_ID)
    REFERENCES CSR.TEAMROOM_TYPE(APP_SID, TEAMROOM_TYPE_ID);

ALTER TABLE CSR.TEAMROOM_EVENT ADD CONSTRAINT FK_TMRM_EVENT_TMRM 
    FOREIGN KEY (APP_SID, TEAMROOM_SID)
    REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID);

ALTER TABLE CSR.TEAMROOM_EVENT ADD CONSTRAINT FK_TMRM_EVENT_USER 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CSR.TEAMROOM_ISSUE ADD CONSTRAINT FK_TMRM_ISSUE_ISSUE 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID);

ALTER TABLE CSR.TEAMROOM_ISSUE ADD CONSTRAINT FK_TMRM_ISSUE_TMRM 
    FOREIGN KEY (APP_SID, TEAMROOM_SID)
    REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID);

ALTER TABLE CSR.TEAMROOM_MEMBER ADD CONSTRAINT FK_TMRM_MBR_TMRM 
    FOREIGN KEY (APP_SID, TEAMROOM_SID)
    REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID);

ALTER TABLE CSR.TEAMROOM_MEMBER ADD CONSTRAINT FK_TMRM_MEMBER_INV_BY 
    FOREIGN KEY (APP_SID, INVITED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CSR.TEAMROOM_MEMBER ADD CONSTRAINT FK_TMRM_MEMBER_USER 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CSR.TEAMROOM_TYPE_TAB ADD CONSTRAINT FK_TMRM_TYPE_TAB_TMRM_TYPE 
    FOREIGN KEY (APP_SID, TEAMROOM_TYPE_ID)
    REFERENCES CSR.TEAMROOM_TYPE(APP_SID, TEAMROOM_TYPE_ID);

ALTER TABLE CSR.TEAMROOM_TYPE_TAB_GROUP ADD CONSTRAINT FK_TEAMROOM_TYPE_TAB_PLUGIN 
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID);

ALTER TABLE CSR.TEAMROOM_TYPE_TAB_GROUP ADD CONSTRAINT FK_TMRM_TYP_TB_GRP_TMRM_TYP 
    FOREIGN KEY (APP_SID, TEAMROOM_TYPE_ID)
    REFERENCES CSR.TEAMROOM_TYPE(APP_SID, TEAMROOM_TYPE_ID);

ALTER TABLE CSR.TEAMROOM_USER_MSG ADD CONSTRAINT FK_TMRM_TMRM_USR_MSG 
    FOREIGN KEY (APP_SID, TEAMROOM_SID)
    REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID);

ALTER TABLE CSR.TEAMROOM_USER_MSG ADD CONSTRAINT FK_USR_MSG_TMRM_USR_MSG 
    FOREIGN KEY (APP_SID, USER_MSG_ID)
    REFERENCES CSR.USER_MSG(APP_SID, USER_MSG_ID) ON DELETE CASCADE;

ALTER TABLE CSR.USER_MSG ADD CONSTRAINT FK_USER_MSG 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CSR.USER_MSG ADD CONSTRAINT FK_USER_MSG_REPLY 
    FOREIGN KEY (APP_SID, REPLY_TO_MSG_ID)
    REFERENCES CSR.USER_MSG(APP_SID, USER_MSG_ID);

ALTER TABLE CSR.USER_MSG_FILE ADD CONSTRAINT FK_USR_MSG_FILE_USR_MSG 
    FOREIGN KEY (APP_SID, USER_MSG_ID)
    REFERENCES CSR.USER_MSG(APP_SID, USER_MSG_ID) ON DELETE CASCADE;

ALTER TABLE CSR.USER_MSG_LIKE ADD CONSTRAINT FK_USR_MSG_LIKE_USER 
    FOREIGN KEY (APP_SID, LIKED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID) ON DELETE CASCADE;

ALTER TABLE CSR.USER_MSG_LIKE ADD CONSTRAINT FK_USR_MSG_LIKE_USR_MSG 
    FOREIGN KEY (APP_SID, USER_MSG_ID)
    REFERENCES CSR.USER_MSG(APP_SID, USER_MSG_ID) ON DELETE CASCADE;

ALTER TABLE CSR.TEAMROOM_INITIATIVE ADD CONSTRAINT FK_TMRM_INITVE_INITVE 
    FOREIGN KEY (APP_SID, INITIATIVE_SID)
    REFERENCES CSR.INITIATIVE(APP_SID, INITIATIVE_SID) ON DELETE CASCADE;

ALTER TABLE CSR.TEAMROOM_INITIATIVE ADD CONSTRAINT FK_TMRM_INITVE_TMRM 
    FOREIGN KEY (APP_SID, TEAMROOM_SID)
    REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID) ON DELETE CASCADE;


CREATE OR REPLACE VIEW CSR.V$USER_MSG AS
    SELECT um.user_msg_id, um.user_sid, cu.full_name, cu.email, um.msg_dtm, um.msg_text
      FROM user_msg um 
      JOIN csr_user cu ON um.user_sid = cu.csr_user_sid AND um.app_sid = cu.app_sid;

CREATE OR REPLACE VIEW CSR.V$USER_MSG_FILE AS
    SELECT umf.user_msg_file_id, umf.user_msg_id, cast(umf.sha1 as varchar2(40)) sha1, umf.mime_type, 
        um.msg_dtm last_modified_dtm
      FROM user_msg um 
      JOIN user_msg_file umf ON um.user_msg_id = umf.user_msg_id;

CREATE OR REPLACE VIEW CSR.V$USER_MSG_LIKE AS
    SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, cu.full_name, cu.email
      FROM user_msg_like uml 
      JOIN csr_user cu ON uml.liked_by_user_sid = cu.csr_user_sid AND uml.app_sid = cu.app_sid;


DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN   
    v_list := t_tabs(  
        'TEAMROOM',
        'TEAMROOM_EVENT',
        'TEAMROOM_INITIATIVE',
        'TEAMROOM_ISSUE',
        'TEAMROOM_MEMBER',
        'TEAMROOM_TYPE',
        'TEAMROOM_TYPE_TAB',
        'TEAMROOM_TYPE_TAB_GROUP',
        'TEAMROOM_USER_MSG',
        'USER_MSG',
        'USER_MSG_FILE',
        'USER_MSG_LIKE'
    );
    FOR I IN 1 .. v_list.count 
    LOOP
        BEGIN           
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CSR',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CSR',
                policy_function => 'appSidCheck',
                statement_types => 'select, insert, update, delete',
                update_check    => true,
                policy_type     => dbms_rls.context_sensitive );
                DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
        EXCEPTION
            WHEN POLICY_ALREADY_EXISTS THEN
                DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));              
            WHEN FEATURE_NOT_ENABLED THEN
                DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
        END;
    END LOOP;
END;
/

CREATE OR REPLACE PACKAGE CSR.teamroom_pkg
AS
END;
/

GRANT EXECUTE ON csr.teamroom_pkg TO WEB_USER;
GRANT EXECUTE ON csr.teamroom_pkg TO SECURITY;

@..\csr_data_pkg

@..\teamroom_pkg
@..\teamroom_body


CREATE FUNCTION csr.SetPlugin(
    in_plugin_type_id   IN  plugin.plugin_type_id%TYPE,
    in_js_class         IN  plugin.js_class%TYPE,
    in_description      IN  plugin.description%TYPE,
    in_js_include       IN  plugin.js_include%TYPE,
    in_cs_class         IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto'
) RETURN plugin.plugin_id%TYPE
AS
    v_plugin_id     plugin.plugin_id%TYPE;
BEGIN
    BEGIN
        INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
             VALUES (csr.plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, in_cs_class)
          RETURNING plugin_id INTO v_plugin_id;
    EXCEPTION WHEN dup_val_on_index THEN
        UPDATE csr.plugin 
           SET description = in_description,
            js_include = in_js_include,
            cs_class = in_cs_class
         WHERE plugin_type_id = in_plugin_type_id
           AND js_class = in_js_class
        RETURNING plugin_id INTO v_plugin_id;
    END;
      
    RETURN v_plugin_id;
END;
/


DECLARE
    v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (5, 'Teamroom tab');
    -- now added specific plugins
    v_plugin_id := csr.SetPlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.SummaryPanel',
        in_description      => 'Summary',
        in_js_include       => '/csr/site/teamroom/controls/SummaryPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.SetPlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.DocumentsPanel',
        in_description      => 'Documents',
        in_js_include       => '/csr/site/teamroom/controls/DocumentsPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.SetPlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.CalendarPanel',
        in_description      => 'Calendar',
        in_js_include       => '/csr/site/teamroom/controls/CalendarPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.SetPlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.IssuesPanel',
        in_description      => 'Actions',
        in_js_include       => '/csr/site/teamroom/controls/IssuesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
END;
/

drop function csr.setplugin;


@update_tail
