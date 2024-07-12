-- Please update version.sql too -- this keeps clean builds in sync
define version=1292
@update_header

CREATE GLOBAL TEMPORARY TABLE CSRIMP.ACCOUNT_POLICY(
    SID_ID                         NUMBER(10, 0)    NOT NULL,
    MAX_LOGON_FAILURES             NUMBER(10, 0),
    EXPIRE_INACTIVE                NUMBER(10, 0),
    MAX_PASSWORD_AGE               NUMBER(10, 0),
    REMEMBER_PREVIOUS_PASSWORDS    NUMBER(10, 0),
    REMEMBER_PREVIOUS_DAYS         NUMBER(10, 0),
    SINGLE_SESSION                 NUMBER(1, 0)     NOT NULL,
    CONSTRAINT PK_ACCOUNT_POLICY PRIMARY KEY (SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.PASSWORD_REGEXP (
  APPLICATION_SID_ID    NUMBER(10,0),
  PASSWORD_REGEXP_ID    NUMBER(10,0) NOT NULL,
  REGEXP                VARCHAR2(256) NOT NULL,
  DESCRIPTION           VARCHAR2(2000) NOT NULL,
  CONSTRAINT PK_PWD_REGEX PRIMARY KEY (PASSWORD_REGEXP_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.ACC_POLICY_PWD_REGEXP (
  ACCOUNT_POLICY_SID     NUMBER(10,0) NOT NULL,
  PASSWORD_REGEXP_ID    NUMBER(10,0) NOT NULL,
  CONSTRAINT PK_ACC_POLICY_PWD_REGEXP PRIMARY KEY(ACCOUNT_POLICY_SID, PASSWORD_REGEXP_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.ACL(
    ACL_ID            NUMBER(10, 0)    NOT NULL,
    ACL_INDEX         NUMBER(10, 0)    NOT NULL,
    ACE_TYPE          NUMBER(10, 0)    NOT NULL,
    ACE_FLAGS         NUMBER(10, 0)    NOT NULL,
    SID_ID            NUMBER(10, 0)    NOT NULL,
    PERMISSION_SET    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ACL PRIMARY KEY (ACL_ID, ACL_INDEX)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.APPLICATION(
    APPLICATION_SID_ID    NUMBER(10, 0)    NOT NULL,
    EVERYONE_SID_ID       NUMBER(10, 0)    NOT NULL,
    LANGUAGE              VARCHAR2(20),
    CULTURE               VARCHAR2(20),
    TIMEZONE              VARCHAR2(100),
    CONSTRAINT PK_APPLICATION PRIMARY KEY (APPLICATION_SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.ATTRIBUTES(
    ATTRIBUTE_ID    NUMBER(10, 0)    NOT NULL,
    CLASS_ID        NUMBER(10, 0)    NOT NULL,
    NAME            VARCHAR2(255),
    FLAGS           NUMBER(10, 0)    NOT NULL,
    EXTERNAL_PKG    VARCHAR2(255),
    CONSTRAINT PK_ATTRIBUTES PRIMARY KEY (ATTRIBUTE_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.HOME_PAGE(
    APP_SID    NUMBER(10, 0)    NOT NULL,
    SID_ID     NUMBER(10, 0)    NOT NULL,
    URL        VARCHAR2(900)    NOT NULL,
    CONSTRAINT PK_HOME_PAGE PRIMARY KEY (APP_SID, SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.IP_RULE(
    IP_RULE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_IP_RULE PRIMARY KEY (IP_RULE_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.IP_RULE_ENTRY(
    IP_RULE_ID       NUMBER(10, 0)    NOT NULL,
    IP_RULE_INDEX    NUMBER(10, 0)    NOT NULL,
    IPV4_ADDRESS     NUMBER(10, 0),
    IPV4_BITMASK     NUMBER(10, 0),
    REQUIRE_SSL      NUMBER(1, 0),
    ALLOW            NUMBER(1, 0),
    CONSTRAINT PK_IP_RULE_ENTRY PRIMARY KEY (IP_RULE_ID, IP_RULE_INDEX)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.PERMISSION_MAPPING(
    PARENT_CLASS_ID      NUMBER(10, 0)    NOT NULL,
    PARENT_PERMISSION    NUMBER(10, 0)    NOT NULL,
    CHILD_CLASS_ID       NUMBER(10, 0)    NOT NULL,
    CHILD_PERMISSION     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_PERMISSION_MAPPING PRIMARY KEY (PARENT_CLASS_ID, PARENT_PERMISSION, CHILD_CLASS_ID, CHILD_PERMISSION)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.PERMISSION_NAME(
    CLASS_ID           NUMBER(10, 0)    NOT NULL,
    PERMISSION         NUMBER(10, 0)    NOT NULL,
    PERMISSION_NAME    VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_PERMISSION_NAME PRIMARY KEY (CLASS_ID, PERMISSION)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SECURABLE_OBJECT(
    SID_ID                NUMBER(10, 0)    NOT NULL,
    PARENT_SID_ID         NUMBER(10, 0),
    DACL_ID               NUMBER(10, 0),
    CLASS_ID              NUMBER(10, 0)    NOT NULL,
    NAME                  VARCHAR2(255),
    FLAGS                 NUMBER(10, 0),
    OWNER                 NUMBER(10, 0),
    LINK_SID_ID           NUMBER(10, 0),
    APPLICATION_SID_ID    NUMBER(10, 0),
    CONSTRAINT PK_SECURABLE_OBJECT PRIMARY KEY (SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SECURABLE_OBJECT_ATTRIBUTES(
    SID_ID          NUMBER(10, 0)     NOT NULL,
    ATTRIBUTE_ID    NUMBER(10, 0)     NOT NULL,
    STRING_VALUE    VARCHAR2(511),
    NUMBER_VALUE    NUMBER(36, 10),
    DATE_VALUE      DATE,
    BLOB_VALUE      BLOB,
    ISOBJECT        NUMBER(1, 0),
    CLOB_VALUE      CLOB,
    CONSTRAINT PK_SEC_OBJ_ATTRIBUTES PRIMARY KEY (SID_ID, ATTRIBUTE_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SECURABLE_OBJECT_CLASS(
    CLASS_ID           NUMBER(10, 0)    NOT NULL,
    CLASS_NAME         VARCHAR2(255)    NOT NULL,
    HELPER_PKG         VARCHAR2(255),
    HELPER_PROG_ID     VARCHAR2(255),
    PARENT_CLASS_ID    NUMBER(10, 0),
    CONSTRAINT PK_SECURABLE_OBJECT_CLASS PRIMARY KEY (CLASS_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SECURABLE_OBJECT_KEYED_ACL(
    SID_ID    NUMBER(10, 0)    NOT NULL,
    KEY_ID    NUMBER(10, 0)    NOT NULL,
    ACL_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECURABLE_OBJECT_KEYED_ACL PRIMARY KEY (SID_ID, KEY_ID, ACL_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.GROUP_MEMBERS(
    GROUP_SID_ID     NUMBER(10, 0)    NOT NULL,
    MEMBER_SID_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GROUP_MEMBERS PRIMARY KEY (GROUP_SID_ID, MEMBER_SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.GROUP_TABLE(
    SID_ID        NUMBER(10, 0)    NOT NULL,
    GROUP_TYPE    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GROUP_TABLE PRIMARY KEY (SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MENU(
    SID_ID         NUMBER(10, 0)     NOT NULL,
    DESCRIPTION    VARCHAR2(1000)    NOT NULL,
    ACTION         VARCHAR2(2000)    NOT NULL,
    POS            NUMBER(10, 0)     NOT NULL,
    CONTEXT        NUMBER(10, 0),
    CONSTRAINT PK_MENU PRIMARY KEY (SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.USER_CERTIFICATES(
    SID_ID          NUMBER(10, 0)    NOT NULL,
    CERT_HASH       RAW(64)          NOT NULL,
    CERT            BLOB             NOT NULL,
    WEBSITE_NAME    VARCHAR2(256),
    CONSTRAINT PK_USER_CERTIFICATES PRIMARY KEY (SID_ID, CERT_HASH)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.USER_PASSWORD_HISTORY(
    SID_ID                 NUMBER(10, 0)    NOT NULL,
    SERIAL                 NUMBER(10, 0)    NOT NULL,
    LOGIN_PASSWORD         VARCHAR2(127),
    LOGIN_PASSWORD_SALT    NUMBER(10, 0),
    RETIRED_DTM            DATE             NOT NULL,
    CONSTRAINT PK_USER_PASSWORD_HISTORY PRIMARY KEY (SID_ID, SERIAL)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.USER_TABLE(
    SID_ID                   NUMBER(10, 0)    NOT NULL,
    LOGIN_PASSWORD           VARCHAR2(127),
    LOGIN_PASSWORD_SALT      NUMBER(10, 0),
    ACCOUNT_ENABLED          NUMBER(1, 0)     NOT NULL
                             CHECK (ACCOUNT_ENABLED IN (0,1)),
    LAST_PASSWORD_CHANGE     DATE             NOT NULL,
    LAST_LOGON               DATE             NOT NULL,
    LAST_BUT_ONE_LOGON       DATE             NOT NULL,
    FAILED_LOGON_ATTEMPTS    NUMBER(10, 0)    NOT NULL,
    EXPIRATION_DTM           DATE,
    LANGUAGE                 VARCHAR2(20),
    CULTURE                  VARCHAR2(20),
    TIMEZONE                 VARCHAR2(100),
    CONSTRAINT PK_USER_TABLE PRIMARY KEY (SID_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.WEB_RESOURCE(
    WEB_ROOT_SID_ID    NUMBER(10, 0)    NOT NULL,
    PATH               VARCHAR2(900)    NOT NULL,
    SID_ID             NUMBER(10, 0)    NOT NULL,
    IP_RULE_ID         NUMBER(10, 0),
    REWRITE_PATH       VARCHAR2(900),
    CONSTRAINT PK_WEB_RESOURCE PRIMARY KEY (WEB_ROOT_SID_ID, PATH)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.WEBSITE(
    WEBSITE_NAME          VARCHAR2(256)    NOT NULL,
    SERVER_GROUP          VARCHAR2(256),
    WEB_ROOT_SID_ID       NUMBER(10, 0)    NOT NULL,
    DENIED_PAGE           VARCHAR2(256)    NOT NULL,
    ACT_TIMEOUT           NUMBER(10, 0)    NOT NULL,
    CERT_ACT_TIMEOUT      NUMBER(10, 0)    NOT NULL,
    SECURE_ONLY           NUMBER(1, 0)     NOT NULL
                          CHECK (SECURE_ONLY IN (0, 1)),
    HTTP_ONLY_COOKIES     NUMBER(1, 0)     NOT NULL
                          CHECK (HTTP_ONLY_COOKIES IN (0, 1)),
    XSRF_CHECK_ENABLED    NUMBER(1, 0)     NOT NULL
                          CHECK (XSRF_CHECK_ENABLED IN (0, 1)),
    APPLICATION_SID_ID    NUMBER(10, 0)    NOT NULL,
    PROXY_SECURE          NUMBER(1, 0)     NOT NULL
                          CHECK (PROXY_SECURE IN (0, 1)),
    IP_RULE_ID            NUMBER(10, 0)
) ON COMMIT DELETE ROWS;

create global temporary table csrimp.map_sid(
	old_sid							number(10)	not null,
	new_sid							number(10)	not null,
	constraint pk_map_sid primary key (old_sid) using index,
	constraint uk_map_sid unique (new_sid) using index
) on commit delete rows;

create global temporary table csrimp.map_acl(
	old_acl_id						number(10)	not null,
	new_acl_id						number(10)	not null,
	constraint pk_map_acl primary key (old_acl_id) using index,
	constraint uk_map_acl unique (new_acl_id) using index
) on commit delete rows;

create global temporary table csrimp.map_password_regexp(
	old_password_regexp_id			number(10)	not null,
	new_password_regexp_id			number(10)	not null,
	constraint pk_map_password_regexp primary key (old_password_regexp_id) using index,
	constraint uk_map_password_regexp unique (new_password_regexp_id) using index
) on commit delete rows;

create global temporary table csrimp.map_ip_rule(
	old_ip_rule_id			number(10)	not null,
	new_ip_rule_id			number(10)	not null,
	constraint pk_map_ip_rule primary key (old_ip_rule_id) using index,
	constraint uk_map_ip_rule unique (new_ip_rule_id) using index
) on commit delete rows;

alter table csrimp.csr_user add (
    SHOW_SAVE_CHART_WARNING        NUMBER(1, 0)     NOT NULL,
    ENABLE_ARIA                    NUMBER(1, 0)     NOT NULL,
    CREATED_DTM                    DATE             NOT NULL,
    IMP_SESSION_MOUNT_POINT_SID    NUMBER(10, 0)
);
alter table csrimp.csr_user drop column is_sys_user;
alter table csrimp.csr_user drop column active;


alter table csrimp.role add (
    REGION_PERMISSION_SET    NUMBER(10, 0),
    IS_SUPPLIER              NUMBER(1, 0)     NOT NULL
   );
alter table csrimp.role add 
    CONSTRAINT CHK_ROLE_IS_SUPPLIER CHECK (IS_SUPPLIER IN (0,1));

alter table csrimp.delegation add SHOW_AGGREGATE number(1) not null;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.DELEGATION_GRID_AGGREGATE_IND(
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    AGGREGATE_TO_IND_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DELEGATION_GRID_AGGR_IND PRIMARY KEY (IND_SID, AGGREGATE_TO_IND_SID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MASTER_DELEG(
    DELEGATION_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_MASTER_DELEG PRIMARY KEY (DELEGATION_SID)
) ON COMMIT DELETE ROWS;

alter table csrimp.deleg_plan_col add (
    QS_CAMPAIGN_SID             NUMBER(10, 0)
);

drop table csrimp.customer;
CREATE GLOBAL TEMPORARY TABLE CSRIMP.CUSTOMER(
    NAME                             VARCHAR2(255)     NOT NULL,
    HOST                             VARCHAR2(255)     NOT NULL,
    SYSTEM_MAIL_ADDRESS              VARCHAR2(255)     NOT NULL,
    TRACKER_MAIL_ADDRESS             VARCHAR2(255)     NOT NULL,
    ALERT_MAIL_ADDRESS               VARCHAR2(255)     NOT NULL,
    ALERT_MAIL_NAME                  VARCHAR2(255)     NOT NULL,
    ALERT_BATCH_RUN_TIME             INTERVAL DAY (2) TO SECOND (6) NOT NULL,
    TRASH_SID                        NUMBER(10, 0)     NOT NULL,
    AGGREGATION_ENGINE_VERSION       NUMBER(1, 0)      NOT NULL,
    CONTACT_EMAIL                    VARCHAR2(255),
    EDITING_URL                      VARCHAR2(255)     NOT NULL,
    MESSAGE                          CLOB,
    IND_INFO_XML_FIELDS              SYS.XMLType,
    REGION_INFO_XML_FIELDS           SYS.XMLType,
    USER_INFO_XML_FIELDS             SYS.XMLType,
    RAISE_REMINDERS                  NUMBER(1, 0)      NOT NULL,
    ACCOUNT_POLICY_SID               NUMBER(10, 0)     NOT NULL,
    STATUS                           NUMBER(2, 0)      NOT NULL,
    RAISE_SPLIT_DELEG_ALERTS         NUMBER(10, 0)     NOT NULL,
    CURRENT_REPORTING_PERIOD_SID     NUMBER(10, 0),
    LOCK_START_DTM                   DATE              NOT NULL,
    LOCK_END_DTM                     DATE              NOT NULL,
    REGION_ROOT_SID                  NUMBER(10, 0),
    IND_ROOT_SID                     NUMBER(10, 0),
    CASCADE_REJECT                   NUMBER(1, 0)      NOT NULL,
    APPROVER_RESPONSE_WINDOW         NUMBER(10, 0)     NOT NULL,
    SELF_REG_GROUP_SID               NUMBER(10, 0),
    SELF_REG_NEEDS_APPROVAL          NUMBER(1, 0)      NOT NULL,
    SELF_REG_APPROVER_SID            NUMBER(10, 0),
    ALLOW_PARTIAL_SUBMIT             NUMBER(1, 0)      NOT NULL,
    HELPER_ASSEMBLY                  VARCHAR2(255),
    APPROVAL_STEP_SHEET_URL          VARCHAR2(255)     NOT NULL,
    USE_TRACKER                      NUMBER(1, 0)      NOT NULL,
    USE_USER_SHEETS                  NUMBER(1, 0)      NOT NULL,
    ALLOW_VAL_EDIT                   NUMBER(1, 0)      NOT NULL,
    FULLY_HIDE_SHEETS                NUMBER(1, 0)      NOT NULL,
    CALC_SUM_ZERO_FILL               NUMBER(1, 0)      NOT NULL,
    CREATE_SHEETS_AT_PERIOD_END      NUMBER(1, 0)      NOT NULL,
    AUDIT_CALC_CHANGES               NUMBER(1, 0)      NOT NULL,
    ORACLE_SCHEMA                    VARCHAR2(255),
    IND_CMS_TABLE                    VARCHAR2(255),
    TARGET_LINE_COL_FROM_GRADIENT    NUMBER(1, 0)      NOT NULL,
    USE_CARBON_EMISSION              NUMBER(1, 0)      NOT NULL,
    HELPER_PKG                       VARCHAR2(255),
    CHAIN_INVITE_LANDING_PREABLE     VARCHAR2(4000),
    CHAIN_INVITE_LANDING_QSTN        VARCHAR2(4000),
    ALLOW_DELEG_PLAN                 NUMBER(1, 0)      NOT NULL,
    SUPPLIER_REGION_ROOT_SID         NUMBER(10, 0),
    TRUCOST_COMPANY_ID               NUMBER(10, 0),
    TRUCOST_PORTLET_TAB_ID           NUMBER(10, 0),
    FOGBUGZ_IXPROJECT                NUMBER(10, 0),
    FOGBUGZ_SAREA                    VARCHAR2(50),
    FWD_ESTIMATE_METERS              NUMBER(1, 0)      NOT NULL,
    PROPAGATE_DELEG_VALUES_DOWN      NUMBER(1, 0)      NOT NULL,
    ENABLE_SAVE_CHART_WARNING        NUMBER(1, 0)      NOT NULL,
    ISSUE_EDITOR_URL                 VARCHAR2(200)     NOT NULL,
    ALLOW_MAKE_EDITABLE              NUMBER(1, 0)      NOT NULL,
    ALERT_URI_FORMAT                 VARCHAR2(250),
    UNMERGED_CONSISTENT              NUMBER(1, 0)      NOT NULL,
    UNMERGED_SCENARIO_RUN_SID        NUMBER(10, 0),
    IND_SELECTIONS_ENABLED           NUMBER(1, 0)      NOT NULL,
    CHECK_TOLERANCE_AGAINST_ZERO     NUMBER(1, 0)      NOT NULL,
    SCENARIOS_ENABLED                NUMBER(1, 0)      NOT NULL,
    CALC_JOB_PRIORITY                NUMBER(10, 0)     NOT NULL,
    COPY_VALS_TO_NEW_SHEETS          NUMBER(1, 0)      NOT NULL,
    USE_VAR_EXPL_GROUPS              NUMBER(1, 0)      NOT NULL,
    CHECK (ALLOW_PARTIAL_SUBMIT IN (0,1)),
    CHECK (USE_TRACKER IN (0,1)),
    CONSTRAINT CK_CUST_USE_USER_SHEETS CHECK (USE_USER_SHEETS IN (0,1)),
    CONSTRAINT CK_AGGREGATION_ENGINE_VERSION CHECK (AGGREGATION_ENGINE_VERSION IN (4)),
    CHECK (ALLOW_VAL_EDIT IN (0,1)),
    CONSTRAINT CK_CUST_FULLY_HIDE_SHEETS CHECK (FULLY_HIDE_SHEETS IN (0,1)),
    CONSTRAINT CK_CUSTOMER_CALC_SUM_0_FILL CHECK (CALC_SUM_ZERO_FILL IN (0,1)),
    CONSTRAINT CK_CUSTOMER_AUDIT_CALC_CHANGES CHECK (AUDIT_CALC_CHANGES IN (0,1)),
    CHECK (TARGET_LINE_COL_FROM_GRADIENT IN (0,1)),
    CHECK (USE_CARBON_EMISSION IN (0,1)),
    CHECK (ALLOW_DELEG_PLAN IN (0,1)),
    CONSTRAINT CK_CUSTOMER_FWD_EST_METERS CHECK (FWD_ESTIMATE_METERS IN (0,1)),
    CONSTRAINT CK_UNMERGED_CONSISTENT CHECK (unmerged_consistent in (0,1)),
    CONSTRAINT CK_CUSTOMER_IND_SEL_ENABLED CHECK (IND_SELECTIONS_ENABLED IN (0,1)),
    CONSTRAINT CHK_CUS_CHK_TOL_ZERO CHECK (CHECK_TOLERANCE_AGAINST_ZERO IN (0,1)),
    CONSTRAINT CK_CUSTOMER_SCENARIOS_ENABLED CHECK (scenarios_enabled in (0,1)),
    CONSTRAINT CHK_CPY_VAL_TO_NEW_SHT CHECK (COPY_VALS_TO_NEW_SHEETS IN (0,1)),
    CONSTRAINT CK_USE_VAR_EXPL_GROUPS CHECK (USE_VAR_EXPL_GROUPS IN (0,1))
) ON COMMIT DELETE ROWS
;
grant insert,select,update,delete on csrimp.customer to web_user;
grant insert,select,update,delete on csrimp.csr_user to web_user;

alter table csrimp.tag_group add (
    APPLIES_TO_NON_COMPLIANCES    NUMBER(1, 0)     NOT NULL,
    APPLIES_TO_SUPPLIERS          NUMBER(1, 0)     NOT NULL
    );

alter table csrimp.tag add (
    LOOKUP_KEY     VARCHAR2(30)
);

alter table csrimp.customer_alert_type add (
    GET_PARAMS_SP             VARCHAR2(255)
);


alter table CSRIMP.MEASURE add (
    REGIONAL_AGGREGATION         VARCHAR2(255)     NOT NULL,
    FACTOR                       NUMBER(10, 0),
    M                            NUMBER(10, 0),
    KG                           NUMBER(10, 0),
    S                            NUMBER(10, 0),
    A                            NUMBER(10, 0),
    K                            NUMBER(10, 0),
    MOL                          NUMBER(10, 0),
    CD                           NUMBER(10, 0),
    CONSTRAINT CK_MEASURE_SI_DETAIL CHECK (( factor is not null and m is not null and kg is not null and s is not null and a is not null and k is not null and mol is not null and cd is not null ) or
	( factor is null and m is null and kg is null and s is null and a is null and k is null and mol is null and cd is null ))
);

alter table csrimp.ind add (
    CALC_END_DTM_ADJUSTMENT      NUMBER(10, 0)     NOT NULL,
    CONSTRAINT CK_IND_START_MONTH CHECK (start_month between 1 and 12),
    CONSTRAINT CK_IND_MUST_BE_MANAGED CHECK (( gas_type_id is not null and is_system_managed = 1 ) or 
	( ind_type = 3 and is_system_managed = 1 ) or 
	( ind_type != 3 and gas_type_id is null ))
);

drop table csrimp.map_folder;
drop table csrimp.map_measure;
drop table csrimp.map_ind;
drop table csrimp.map_region;
drop table csrimp.map_group;
drop table csrimp.map_user;
drop table csrimp.map_form;
drop table csrimp.map_dataview;
drop table csrimp.map_pending_dataset;
drop table csrimp.map_approval_step;

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='REGION' and column_name='FLAG';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.region add FLAG                    NUMBER(1, 0)      NOT NULL';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='REGION' and column_name='EGRID_REF_OVERRIDDEN';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.region add EGRID_REF_OVERRIDDEN    NUMBER(1, 0)      NOT NULL';
	end if;
end;
/


CREATE GLOBAL TEMPORARY TABLE CSRIMP.SUPERADMIN(
    CSR_USER_SID     NUMBER(10, 0)    NOT NULL,
    EMAIL            VARCHAR2(256),
    GUID             CHAR(36)         NOT NULL,
    FULL_NAME        VARCHAR2(256),
    USER_NAME        VARCHAR2(256)    NOT NULL,
    FRIENDLY_NAME    VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_SUPERADMIN PRIMARY KEY (CSR_USER_SID)
) ON COMMIT DELETE ROWS
;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.CUSTOMER_REGION_TYPE(
    REGION_TYPE    NUMBER(2, 0)     NOT NULL,
    CONSTRAINT PK_CUSTOMER_REGION_TYPE PRIMARY KEY (REGION_TYPE)
) ON COMMIT DELETE ROWS;


CREATE GLOBAL TEMPORARY TABLE CSRIMP.SECTION_STATUS(
    SECTION_STATUS_SID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    COLOUR                NUMBER(10, 0)    NOT NULL,
    POS                   NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    ICON_PATH             VARCHAR2(256),
    CONSTRAINT PK543 PRIMARY KEY (SECTION_STATUS_SID)
) ON COMMIT DELETE ROWS;

alter table csrimp.section_module drop column name;
-- not used yet - in the model but not on live
--alter table CSRIMP.SECTION_MODULE add (
--    FLOW_SID              NUMBER(10, 0),
--    REGION_SID            NUMBER(10, 0)
--);
alter table csrimp.section drop column name;

alter table csrimp.form_allocation_item modify ind_sid not null;
alter table csrimp.form_allocation_item rename column ind_sid to item_sid;
alter table csrimp.form_allocation_item drop column region_sid;
alter table csrimp.imp_file_upload rename to file_upload;
drop table csrimp.map_imp_session;
drop table csrimp.map_img_chart;

alter table csrimp.img_chart add
    PARENT_SID           NUMBER(10, 0)     NOT NULL;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MAIL_ACCOUNT(
    ACCOUNT_SID         NUMBER(10, 0)    NOT NULL,
    EMAIL_ADDRESS       VARCHAR2(255)    NOT NULL,
    ROOT_MAILBOX_SID    NUMBER(10, 0),
    INBOX_SID           NUMBER(10, 0),
    PASSWORD            VARCHAR2(255),
    PASSWORD_SALT       NUMBER(10, 0),
    APOP_SECRET         VARCHAR2(255),
    DESCRIPTION         VARCHAR2(511),
    CONSTRAINT PK_ACCOUNT PRIMARY KEY (ACCOUNT_SID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MAIL_MAILBOX(
    MAILBOX_SID                    NUMBER(10, 0)    NOT NULL,
    PARENT_SID                     NUMBER(10, 0),
    LINK_TO_MAILBOX_SID            NUMBER(10, 0),
    MAILBOX_NAME                   VARCHAR2(255)    NOT NULL,
    LAST_MESSAGE_UID               NUMBER(38, 0)    NOT NULL,
    FLAGS_SERIAL                   NUMBER(10, 0)    NOT NULL,
    INSERT_SERIAL                  NUMBER(10, 0)    NOT NULL,
    DELETE_SERIAL                  NUMBER(10, 0)    NOT NULL,
    FILTER_DUPLICATE_MESSAGE_ID    NUMBER(1, 0)     NOT NULL
                                   CHECK (FILTER_DUPLICATE_MESSAGE_ID IN (0,1)),
    CONSTRAINT PK_MAILBOX PRIMARY KEY (MAILBOX_SID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MAIL_MESSAGE(
    MAILBOX_SID        NUMBER(10, 0)    NOT NULL,
    MESSAGE_UID        NUMBER(10, 0)    NOT NULL,
    PARENT_SID         NUMBER(10, 0),
    FLAGS              NUMBER(10, 0)    NOT NULL,
    SUBJECT            VARCHAR2(255),
    MESSAGE_DTM        DATE,
    MESSAGE_ID         VARCHAR2(255),
    IN_REPLY_TO        VARCHAR2(255),
    PRIORITY           NUMBER(1, 0),
    HAS_ATTACHMENTS    NUMBER(1, 0)     NOT NULL,
    RECEIVED_DTM       DATE             NOT NULL,
    BODY               BLOB,
    CONSTRAINT PK_MESSAGE PRIMARY KEY (MAILBOX_SID, MESSAGE_UID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MAIL_MESSAGE_ADDRESS_FIELD(
    MAILBOX_SID    NUMBER(10, 0)    NOT NULL,
    MESSAGE_UID    NUMBER(10, 0)    NOT NULL,
    FIELD_ID       NUMBER(10, 0)    NOT NULL,
    POSITION       NUMBER(10, 0)    NOT NULL,
    ADDRESS        VARCHAR2(255),
    NAME           VARCHAR2(255),
    CONSTRAINT PK_MESSAGE_ADDRESS_FIELD PRIMARY KEY (MAILBOX_SID, MESSAGE_UID, FIELD_ID, POSITION)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.MAIL_MESSAGE_HEADER(
    MAILBOX_SID    NUMBER(10, 0)     NOT NULL,
    MESSAGE_UID    NUMBER(10, 0)     NOT NULL,
    POSITION       NUMBER(10, 0)     NOT NULL,
    NAME           VARCHAR2(255)     NOT NULL,
    VALUE          VARCHAR2(1023),
    CONSTRAINT PK_MESSAGE_HEADER PRIMARY KEY (MAILBOX_SID, MESSAGE_UID, POSITION)
) ON COMMIT DELETE ROWS;

drop table csrimp.map_section;
drop table csrimp.map_section_module;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SO_RENAME(
    SID_ID                NUMBER(10, 0)    NOT NULL,
    NAME                  VARCHAR2(255)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SHEET_VALUE_FILE(
    SHEET_VALUE_ID     NUMBER(10, 0)    NOT NULL,
    FILE_UPLOAD_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEET_VALUE_FILE PRIMARY KEY (SHEET_VALUE_ID, FILE_UPLOAD_SID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.KNOWN_SO(
	SID_ID					NUMBER(10) NOT NULL,
	PATH					VARCHAR2(4000) NOT NULL,
	CONSTRAINT PK_KNOWN_SO PRIMARY KEY (SID_ID)
) ON COMMIT DELETE ROWS;

alter table csrimp.deleg_plan_deleg_region drop column maps_to_root_deleg_sid;
begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='DELEG_PLAN_DELEG_REGION' and column_name='MAPS_TO_ROOT_DELEG_SID') loop
		execute immediate 'alter table csr.deleg_plan_deleg_region drop column maps_to_root_deleg_sid';
	end loop;
end;
/

grant insert,select,update,delete on csrimp.account_policy to web_user;
grant insert,select,update,delete on csrimp.acc_policy_pwd_regexp to web_user;
grant insert,select,update,delete on csrimp.acl to web_user;
grant insert,select,update,delete on csrimp.application to web_user;
grant insert,select,update,delete on csrimp.attributes to web_user;
grant insert,select,update,delete on csrimp.delegation_grid_aggregate_ind to web_user;
grant insert,select,update,delete on csrimp.home_page to web_user;
grant insert,select,update,delete on csrimp.group_members to web_user;
grant insert,select,update,delete on csrimp.group_table to web_user;
grant insert,select,update,delete on csrimp.ip_rule to web_user;
grant insert,select,update,delete on csrimp.ip_rule_entry to web_user;
grant insert,select,update,delete on csrimp.menu to web_user;
grant insert,select,update,delete on csrimp.password_regexp to web_user;
grant insert,select,update,delete on csrimp.permission_mapping to web_user;
grant insert,select,update,delete on csrimp.permission_name to web_user;
grant insert,select,update,delete on csrimp.securable_object to web_user;
grant insert,select,update,delete on csrimp.securable_object_attributes to web_user;
grant insert,select,update,delete on csrimp.securable_object_class to web_user;
grant insert,select,update,delete on csrimp.securable_object_keyed_acl to web_user;
grant insert,select,update,delete on csrimp.user_certificates to web_user;
grant insert,select,update,delete on csrimp.user_password_history to web_user;
grant insert,select,update,delete on csrimp.user_table to web_user;
grant insert,select,update,delete on csrimp.web_resource to web_user;
grant insert,select,update,delete on csrimp.website to web_user;

grant select,insert,update on csr.customer to csrimp;
grant select on csr.superadmin to csrimp;
grant insert on csr.deleg_plan to csrimp;
grant insert on csr.reporting_period to csrimp;

grant insert on csr.img_chart to csrimp;
grant insert on csr.form to csrimp;
grant insert on csr.range_region_member to csrimp;
grant insert on csr.range_ind_member to csrimp;
grant insert on csr.section_status to csrimp;
grant insert on csr.form_allocation to csrimp;
grant insert on csr.form_allocation_item to csrimp;
grant insert on csr.form_allocation_user to csrimp;
grant insert on csr.form_comment to csrimp;
grant insert on csr.pending_dataset to csrimp;
grant insert on csr.approval_step to csrimp;
grant insert on csr.approval_step_sheet to csrimp;
grant insert on csr.approval_step_user to csrimp;
grant insert on csr.approval_step_role to csrimp;
grant insert on csr.measure to csrimp;
grant insert on csr.customer_region_type to csrimp;
grant insert on csr.csr_user to csrimp;
grant insert on csr.sheet_value_file to csrimp;
grant insert,select,update,delete on csrimp.customer_region_type to web_user;
grant insert,select,update,delete on csrimp.known_so to web_user;
grant update on security.securable_object_attributes to csrimp;
grant select on csr.form_allocation_id_seq to csrimp;
grant insert on csr.file_upload to csrimp;
grant select on csr.pending_ind_id_seq to csrimp;
grant select on csr.pending_region_id_seq to csrimp;
grant select on csr.pending_period_id_seq to csrimp;
grant insert on csr.pending_ind to csrimp;
grant insert on csr.pending_region to csrimp;
grant insert on csr.pending_period to csrimp;
grant insert on csr.pending_val_accuracy_type_opt to csrimp;
grant insert on csr.pending_ind_accuracy_type to csrimp;
grant select on csr.attachment_id_seq to csrimp;
grant insert on csr.attachment to csrimp;
grant insert on csr.section_module to csrimp;
grant insert on csr.section to csrimp;
grant insert on csr.section_version to csrimp;
grant insert on csr.section_comment to csrimp;
grant select on csr.section_comment_id_seq to csrimp;
grant insert on csr.section_approvers to csrimp;
grant insert on csr.root_section_user to csrimp;
grant insert,select,update,delete on csrimp.mail_account to web_user;
grant insert,select,update,delete on csrimp.mail_mailbox to web_user;
grant insert,select,update,delete on csrimp.mail_message to web_user;
grant insert,select,update,delete on csrimp.mail_message_address_field to web_user;
grant insert,select,update,delete on csrimp.mail_message_header to web_user;
grant insert,select,update,delete on csrimp.sheet_value_file to web_user;
grant insert,select,update,delete on csrimp.section_status to web_user;

grant insert,update on mail.mailbox to csrimp;
grant insert on mail.account_alias to csrimp;
grant insert on mail.account to csrimp;
grant insert on mail.message to csrimp;
grant insert on mail.message_header to csrimp;
grant insert on mail.message_address_field to csrimp;
grant execute on mail.mail_pkg to csrimp;

grant select on mail.mailbox to csr;
grant select on mail.message_header to csr;
grant select on mail.message_address_field to csr;

grant insert on csr.tag_group to csrimp;
grant select on csr.tag_id_seq to csrimp;
grant select on csr.accuracy_type_id_seq to csrimp;
grant select on csr.accuracy_type_option_id_seq to csrimp;

grant insert,select,update,delete on csrimp.superadmin to web_user;

grant insert on csr.tag to csrimp;
grant insert on csr.tag_group_member to csrimp;
grant insert on csr.accuracy_type to csrimp;
grant insert on csr.accuracy_type_option to csrimp;
grant insert on csr.customer_alert_type to csrimp;
grant select on csr.alert_frame_id_seq to csrimp;	  
grant select on csr.measure_conversion_id_seq to csrimp;
grant insert on csr.measure_conversion to csrimp;
grant insert on csr.measure_conversion_period to csrimp;
grant insert on csr.region_tree to csrimp;
grant insert on csr.ind to csrimp;
grant insert on csr.region to csrimp;
grant insert on csr.form to csrimp;
grant insert, update on csr.dataview to csrimp;

grant select on security.acl_id_seq to csrimp;
grant select on security.attribute_id_seq to csrimp;
grant select on security.ip_rule_id_seq to csrimp;
grant select on security.sid_id_seq to csrimp;
grant select on csr.tag_group_id_seq to csrimp;

grant select, insert on security.acl to csrimp;
grant insert on security.account_policy to csrimp;
grant insert on security.acc_policy_pwd_regexp to csrimp;
grant insert on security.application to csrimp;
grant select, insert on security.attributes to csrimp;
grant insert on security.group_members to csrimp;
grant insert on security.group_table to csrimp;
grant insert on security.home_page to csrimp;
grant insert on security.ip_rule to csrimp;
grant insert on security.ip_rule_entry to csrimp;
grant insert on security.menu to csrimp;
grant insert on security.password_regexp to csrimp;
grant select on security.password_regexp_id_seq to csrimp;
grant select, insert on security.permission_name to csrimp;
grant select, insert on security.permission_mapping to csrimp;
grant insert, update on security.securable_object to csrimp;
grant insert on security.securable_object_attributes to csrimp;
grant select, insert, update on security.securable_object_class to csrimp;
grant insert on security.securable_object_keyed_acl to csrimp;
grant insert on security.user_certificates to csrimp;
grant insert on security.user_password_history to csrimp;
grant insert on security.user_table to csrimp;
grant insert on security.web_resource to csrimp;
grant insert, select on security.website to csrimp;

drop table csrimp.attribute;
drop table csrimp.group_member;
drop table csrimp.folder;
drop table csrimp.so_group;

grant select on security.permission_mapping to csr;
grant select on security.attributes to csr;
grant select on security.securable_object_attributes to csr;
grant select on security.user_certificates to csr;
grant select on security.securable_object_keyed_acl to csr;
grant select on security.permission_name to csr;
grant select on security.account_policy to csr;
grant select on security.password_regexp to csr;
grant select on security.acc_policy_pwd_regexp to csr;
grant select on security.group_table to csr;
grant select on security.user_password_history to csr;
grant select on security.ip_rule_entry to csr;
grant select on security.ip_rule to csr;
grant select on security.home_page to csr;
grant select on security.menu to csr;

@../io_pkg
@../schema_pkg
@../csr_data_body
@../img_chart_body
@../indicator_body
@../io_body
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
