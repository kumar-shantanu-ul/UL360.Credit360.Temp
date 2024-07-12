-- Please update version.sql too -- this keeps clean builds in sync
define version=3300
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.AGGREGATE_IND_GROUP_AUDIT_LOG (
    APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    AGGREGATE_IND_GROUP_ID    NUMBER(10, 0)     NOT NULL,
    CHANGE_DTM                DATE              NOT NULL,
    CHANGE_DESCRIPTION        VARCHAR2(4000)    NOT NULL,
    CHANGED_BY_USER_SID       NUMBER(10, 0)     NOT NULL
);

CREATE INDEX CSR.IX_AGG_IND_GRP_LOG ON CSR.AGGREGATE_IND_GROUP_AUDIT_LOG(APP_SID, AGGREGATE_IND_GROUP_ID)
;

CREATE TABLE CSRIMP.AGGREGATE_IND_GROUP_AUDIT_LOG (
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    AGGREGATE_IND_GROUP_ID			NUMBER(10, 0)     NOT NULL,
    CHANGE_DTM						DATE              NOT NULL,
    CHANGE_DESCRIPTION				VARCHAR2(4000)    NOT NULL,
    CHANGED_BY_USER_SID				NUMBER(10, 0)     NOT NULL,
    CONSTRAINT FK_AGGR_IND_GROUP_AUDIT_LOG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.aggregate_ind_group
ADD LOOKUP_KEY VARCHAR2(255);

CREATE UNIQUE INDEX CSR.UK_AGGR_IND_GROUP_LOOKUP_KEY ON CSR.AGGREGATE_IND_GROUP(APP_SID, NVL(UPPER(LOOKUP_KEY), TO_CHAR(AGGREGATE_IND_GROUP_ID)))
;

ALTER TABLE CSR.AGGREGATE_IND_GROUP_AUDIT_LOG ADD CONSTRAINT FK_AGG_IND_GRP_USER
    FOREIGN KEY (APP_SID, CHANGED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE csrimp.aggregate_ind_group
ADD LOOKUP_KEY VARCHAR2(255);

create index csr.ix_aggregate_ind_changed_by_us on csr.aggregate_ind_group_audit_log (app_sid, changed_by_user_sid);

-- *** Grants ***
grant insert on csr.aggregate_ind_group_audit_log to csrimp;
grant select,insert,update,delete on csrimp.aggregate_ind_group_audit_log to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../aggregate_ind_pkg
@../schema_pkg
@../indicator_pkg

@../aggregate_ind_body
@../schema_body
@../indicator_body
@../csr_app_body
@../csrimp/imp_body


@update_tail
