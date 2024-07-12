define version=3473
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

CREATE TABLE csr.failed_notification (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	failed_notification_id			NUMBER(10, 0)	NOT NULL,
	notification_type_id			VARCHAR2(36)	NOT NULL,
	to_user							VARCHAR2(36)	NOT NULL,
	channel							VARCHAR2(255)	NOT NULL,
	failure_code					VARCHAR2(255)	NOT NULL,
	from_user						VARCHAR2(36),
	merge_fields					CLOB,
	repeating_merge_fields			CLOB,
	CONSTRAINT pk_failed_notification PRIMARY KEY (app_sid, failed_notification_id)
);
ALTER TABLE csr.failed_notification ADD CONSTRAINT fk_failed_notification_notif_type_id
    FOREIGN KEY (app_sid, notification_type_id)
    REFERENCES csr.notification_type(app_sid, notification_type_id);
CREATE SEQUENCE csr.failed_notification_id_seq CACHE 5;
create index csr.ix_failed_notifi_notification_ on csr.failed_notification (app_sid, notification_type_id);
CREATE GLOBAL TEMPORARY TABLE CSR.TT_NC_AUDIT (
    non_compliance_id               NUMBER(10,0) NOT NULL,
    label                           VARCHAR2(2048),
    detail                          CLOB,
    created_dtm                     DATE DEFAULT SYSDATE NOT NULL,
    created_by_user_sid             NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    non_compliance_ref              VARCHAR2(255),
    internal_audit_sid              NUMBER(10,0),
    sid_id                          NUMBER(10,0),
    audit_label                     VARCHAR2(2048),
    created_by_full_name            VARCHAR2(256 BYTE),
    closed_issues                   NUMBER,
    total_issues                    NUMBER,
    root_cause                      CLOB,
    suggested_action                CLOB,
    open_issues                     NUMBER,
    region_sid                      NUMBER(10,0),
    region_description              VARCHAR2(255),
    non_compliance_type_id          NUMBER(10,0),
    non_compliance_type_label       CLOB,
    is_closed                       NUMBER(1,0),
    override_score                  NUMBER(15,5),
    is_repeat                       NUMBER,
    repeat_of_audit_sid             NUMBER(10,0),
    repeat_of_non_compliance_id     NUMBER(10,0)
) ON COMMIT DELETE ROWS;


ALTER TABLE CMS.CK_CONS MODIFY CONSTRAINT_NAME VARCHAR2(128);
ALTER TABLE CMS.FK_CONS MODIFY CONSTRAINT_NAME VARCHAR2(128);
ALTER TABLE CMS.UK_CONS MODIFY CONSTRAINT_NAME VARCHAR2(128);


GRANT SELECT ON cms.app_schema TO csr;








DELETE FROM csr.capability 
 WHERE name = 'HAProxyTest';






@..\aggregate_ind_pkg
@..\zap_pkg
@..\notification_pkg
@..\audit_pkg


@..\aggregate_ind_body
@..\zap_body
@..\notification_body
@..\audit_body



@update_tail
