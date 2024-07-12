-- Please update version.sql too -- this keeps clean builds in sync
define version=1544
@update_header

CREATE TABLE CSR.LOGON_TYPE (
    LOGON_TYPE_ID   NUMBER(10) NOT NULL,
    LABEL           VARCHAR(255) NOT NULL,
    CONSTRAINT PK_LOGON_TYPE PRIMARY KEY (LOGON_TYPE_ID)
);

BEGIN
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (0, 'Unspecified');
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (1, 'Full');
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (2, 'Authenticated');
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (3, 'Certificate');
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (4, 'Logoff'); -- to match security_pkg.LOGON_TYPE_LOGOFF
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (100, 'SSO');  -- start at 100 for security_pkg headroom
INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (101, 'SU');  
END;
/

ALTER TABLE CSR.CSR_USER ADD (
    LAST_LOGON_TYPE_ID   NUMBER(10) DEFAULT 0 NOT NULL,
    CONSTRAINT FK_CSR_USER_LOGON_TYPE FOREIGN KEY (LAST_LOGON_TYPE_ID) REFERENCES CSR.LOGON_TYPE(LOGON_TYPE_ID)
);

CREATE OR REPLACE VIEW csr.v$csr_user AS
    SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.region_mount_point_sid, cu.full_name, cu.user_name, cu.send_alerts,
           cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
           cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
           ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

ALTER TABLE CSR.RULESET_RUN_FINDING DROP PRIMARY KEY CASCADE DROP INDEX;

ALTER TABLE CSR.RULESET_RUN_FINDING ADD (
    FINDING_KEY VARCHAR2(255) NOT NULL,
    LABEL       VARCHAR2(2000) NOT NULL,
    PARAM_1     VARCHAR2(255),
    PARAM_2     VARCHAR2(255),
    PARAM_3     VARCHAR2(255),
    ENTRY_VAL_NUMBER                NUMBER(24, 10),
    ENTRY_MEASURE_CONVERSION_ID     NUMBER(10)
);

ALTER TABLE CSR.RULESET_RUN_FINDING ADD (
    CONSTRAINT PK_RULESET_RUN_FINDING PRIMARY KEY (APP_SID, RULESET_SID, REGION_SID, IND_SID, FINDING_KEY)
);

ALTER TABLE CSR.RULESET_RUN_FINDING ADD CONSTRAINT FK_MEAS_CONV_RLST_RUN_FND 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID);

ALTER TABLE CSR.RULESET_RUN_FINDING RENAME COLUMN APPROVED_BY_SID TO APPROVED_BY_USER_SID;

CREATE OR REPLACE PACKAGE CSR.ruleset_pkg
AS
END;
/

GRANT EXECUTE ON csr.ruleset_pkg TO WEB_USER;

@..\ruleset_pkg
@..\csr_data_pkg

@..\ruleset_body
@..\csr_user_body

@update_tail