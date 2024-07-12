-- Please update version.sql too -- this keeps clean builds in sync
define version=3472
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
-- temp table for pagination internal audits
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

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_pkg
@..\audit_body

@update_tail
