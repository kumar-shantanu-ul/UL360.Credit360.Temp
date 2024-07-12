-- Please update version.sql too -- this keeps clean builds in sync
define version=954
@update_header

-- recreate as this was wrong in the model
alter table csr.customer drop constraint fk_customer_scenario_Run;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT FK_CUSTOMER_SCENARIO_RUN 
    FOREIGN KEY (APP_SID, UNMERGED_SCENARIO_RUN_SID)
    REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID)
;

@update_tail
