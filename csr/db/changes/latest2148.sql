-- Please update version.sql too -- this keeps clean builds in sync
define version=2148
@update_header

CREATE SEQUENCE CSR.AGGR_TAG_GROUP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.AGGR_TAG_GROUP(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    AGGR_TAG_GROUP_ID    NUMBER(10, 0)     NOT NULL,
    LOOKUP_KEY           VARCHAR2(256)     NOT NULL,
    LABEL                VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK_AGGR_TAG_GROUP PRIMARY KEY (APP_SID, AGGR_TAG_GROUP_ID)
);

CREATE TABLE CSR.AGGR_TAG_GROUP_MEMBER(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    AGGR_TAG_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    TAG_ID               NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_AGGR_TAG_GROUP_MEMBER PRIMARY KEY (APP_SID, AGGR_TAG_GROUP_ID, TAG_ID)
);

CREATE TABLE CSR.INITIATIVE_METRIC_TAG_IND(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INITIATIVE_METRIC_ID    NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    MEASURE_SID             NUMBER(10, 0)    NOT NULL,
    AGGR_TAG_GROUP_ID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_INITIATIVE_METRIC_TAG_IND PRIMARY KEY (APP_SID, INITIATIVE_METRIC_ID, AGGR_TAG_GROUP_ID)
);


ALTER TABLE CSR.INITIATIVES_OPTIONS ADD(
	CURRENT_REPORT_DATE     DATE
);

ALTER TABLE CSR.INITIATIVE_METRIC_IND RENAME TO INITIATIVE_METRIC_STATE_IND;

ALTER TABLE CSR.FLOW_STATE_GROUP_MEMBER ADD (
	BEFORE_REPORT_DATE     NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    AFTER_REPORT_DATE      NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CK_BEFORE_REPORT_DATE CHECK (BEFORE_REPORT_DATE IN(0,1)),
    CONSTRAINT CK_AFTER_REPORT_DATE CHECK (AFTER_REPORT_DATE IN(0,1))
);



ALTER TABLE CSR.AGGR_TAG_GROUP ADD CONSTRAINT FK_CUST_AGGRTAGGRP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.AGGR_TAG_GROUP_MEMBER ADD CONSTRAINT FK_AGGRTAGGRP_AGGRTAGGRPMBR 
    FOREIGN KEY (APP_SID, AGGR_TAG_GROUP_ID)
    REFERENCES CSR.AGGR_TAG_GROUP(APP_SID, AGGR_TAG_GROUP_ID)
;

ALTER TABLE CSR.AGGR_TAG_GROUP_MEMBER ADD CONSTRAINT FK_TAG_AGGRTAGGRPMBR 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSR.INITIATIVE_METRIC_TAG_IND ADD CONSTRAINT FK_AGGRTAGGRP_INITMETTAGIND 
    FOREIGN KEY (APP_SID, AGGR_TAG_GROUP_ID)
    REFERENCES CSR.AGGR_TAG_GROUP(APP_SID, AGGR_TAG_GROUP_ID)
;

ALTER TABLE CSR.INITIATIVE_METRIC_TAG_IND ADD CONSTRAINT FK_IND_INITMETTAGIND 
    FOREIGN KEY (APP_SID, IND_SID, MEASURE_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID, MEASURE_SID)
;

ALTER TABLE CSR.INITIATIVE_METRIC_TAG_IND ADD CONSTRAINT FK_INTIMET_INITMETTAGIND 
    FOREIGN KEY (APP_SID, INITIATIVE_METRIC_ID)
    REFERENCES CSR.INITIATIVE_METRIC(APP_SID, INITIATIVE_METRIC_ID)
;

ALTER TABLE CSR.INITIATIVE_METRIC_TAG_IND ADD CONSTRAINT FK_INTIMET_INITMETTAGIND_MEAS 
    FOREIGN KEY (APP_SID, INITIATIVE_METRIC_ID, MEASURE_SID)
    REFERENCES CSR.INITIATIVE_METRIC(APP_SID, INITIATIVE_METRIC_ID, MEASURE_SID)
;


CREATE INDEX CSR.IX_CUST_AGGRTAGGRP ON CSR.AGGR_TAG_GROUP(APP_SID);
CREATE INDEX CSR.IX_AGGRTAGGRP_AGGRTAGGRPMBR ON CSR.AGGR_TAG_GROUP_MEMBER(APP_SID, AGGR_TAG_GROUP_ID);
CREATE INDEX CSR.IX_TAG_AGGRTAGGRPMBR ON CSR.AGGR_TAG_GROUP_MEMBER(APP_SID, TAG_ID);
CREATE INDEX CSR.IX_AGGRTAGGRP_INITMETTAGIND ON CSR.INITIATIVE_METRIC_TAG_IND(APP_SID, AGGR_TAG_GROUP_ID);
CREATE INDEX CSR.IX_IND_INITMETTAGIND ON CSR.INITIATIVE_METRIC_TAG_IND(APP_SID, IND_SID, MEASURE_SID);
CREATE INDEX CSR.IX_INTIMET_INITMETTAGIND ON CSR.INITIATIVE_METRIC_TAG_IND(APP_SID, INITIATIVE_METRIC_ID);
CREATE INDEX CSR.IX_INTIMET_INITMETTAGIND_MEAS ON CSR.INITIATIVE_METRIC_TAG_IND(APP_SID, INITIATIVE_METRIC_ID, MEASURE_SID);


-- RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);
    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'AGGR_TAG_GROUP',
		'AGGR_TAG_GROUP_MEMBER',
		'INITIATIVE_METRIC_TAG_IND'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin
                    
                    -- verify that the table has an app_sid column (dev helper)
                    select count(*) 
                      into v_found
                      from all_tab_columns 
                     where owner = 'CSR' 
                       and table_name = UPPER(v_list(i))
                       and column_name = 'APP_SID';
                    
                    if v_found = 0 then
                        raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
                    end if;
                    
                    if v_i = 1 then
                        v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    else
                        v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
                    end if;
                    dbms_output.put_line('doing '||v_name);
                    dbms_rls.add_policy(
                        object_schema   => 'CSR',
                        object_name     => v_list(i),
                        policy_name     => v_name,
                        function_schema => 'CSR',
                        policy_function => 'appSidCheck',
                        statement_types => 'select, insert, update, delete',
                        update_check    => true,
                        policy_type     => dbms_rls.context_sensitive );
                    -- dbms_output.put_line('done  '||v_name);
                    exit;
                exception
                    when policy_already_exists then
                        v_i := v_i + 1;
                    WHEN FEATURE_NOT_ENABLED THEN
                        DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
                        exit;
                end;
            end loop;
        end;
    end loop;
end;
/


@../initiative_aggr_pkg
@../initiative_aggr_body
@../initiative_body

@update_tail
