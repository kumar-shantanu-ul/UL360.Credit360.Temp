-- Please update version.sql too -- this keeps clean builds in sync
define version=2392
@update_header

ALTER TABLE CSR.FLOW_ITEM DROP CONSTRAINT FK_APP_DASH_INST_FLOW_ITEM;

ALTER TABLE CSR.FLOW_ITEM ADD CONSTRAINT FK_APP_DASH_INST_FLOW_ITEM 
    FOREIGN KEY (APP_SID, DASHBOARD_INSTANCE_ID)
    REFERENCES CSR.APPROVAL_DASHBOARD_INSTANCE(APP_SID, DASHBOARD_INSTANCE_ID) DEFERRABLE INITIALLY DEFERRED;


DROP SEQUENCE CSR.MAP_POSTIT_SEQ;
DROP SEQUENCE CSR.MAP_NON_COMPLIANCE_FILE_SEQ;

grant select on csr.postit_id_seq to csrimp;
grant select on csr.non_compliance_file_id_seq to csrimp;

@..\csrimp\imp_body

@update_tail