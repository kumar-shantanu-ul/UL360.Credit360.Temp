-- Please update version.sql too -- this keeps clean builds in sync
define version=2162
@update_header

GRANT SELECT, REFERENCES ON SECURITY.USER_TABLE TO CSR WITH GRANT OPTION;

CREATE OR REPLACE VIEW csr.V$MY_USER AS
  SELECT ut.account_enabled, CASE WHEN cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END is_direct_report, cu.*
    FROM csr.csr_user cu
    JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
   START WITH cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID')
  CONNECT BY PRIOR cu.csr_user_sid = cu.line_manager_sid;


ALTER TABLE CSR.INITIATIVE_USER_GROUP ADD (
    SYNCH_ISSUES                NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_INIT_USR_GRP_SYNCH_ISS CHECK (SYNCH_ISSUES IN (0,1))
);

@..\initiative_body

@update_tail