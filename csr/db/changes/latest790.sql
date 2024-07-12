-- Please update version.sql too -- this keeps clean builds in sync
define version=790
@update_header

grant select on csr.gas_type to actions;

CREATE TABLE ACTIONS.INSTANCE_GAS_IND(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TASK_SID                NUMBER(10, 0)    NOT NULL,
    FROM_IND_TEMPLATE_ID    NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    GAS_METRIC_ID           NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK156 PRIMARY KEY (APP_SID, TASK_SID, FROM_IND_TEMPLATE_ID, IND_SID)
)
;

ALTER TABLE ACTIONS.INSTANCE_GAS_IND ADD CONSTRAINT RefTASK_IND_TEMPLATE_INSTAN314 
    FOREIGN KEY (APP_SID, TASK_SID, FROM_IND_TEMPLATE_ID)
    REFERENCES ACTIONS.TASK_IND_TEMPLATE_INSTANCE(APP_SID, TASK_SID, FROM_IND_TEMPLATE_ID)
;

ALTER TABLE ACTIONS.INSTANCE_GAS_IND ADD CONSTRAINT FK_IND_INST_GAS_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

-- FK indexes
create index actions.ix_inst_inst_gas_ind on actions.instance_gas_ind (app_sid, task_sid, from_ind_template_id);
create index actions.ix_ind_inst_gas_ind on actions.instance_gas_ind (app_sid, ind_sid);


@../actions/task_body
@../actions/options_body
@../actions/initiative_body
@../actions/ind_template_body

@update_tail
