-- Please update version.sql too -- this keeps clean builds in sync
define version=608
@update_header

CREATE TABLE csr.SCENARIO_OPTIONS(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHOW_CHART         NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    SHOW_BAU_OPTION    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    BAU_DEFAULT        NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CHECK (SHOW_CHART IN(0,1)),
    CHECK (SHOW_BAU_OPTION IN(0,1)),
    CHECK (BAU_DEFAULT IN(0,1)),
    CONSTRAINT PK902 PRIMARY KEY (APP_SID)
)
;

ALTER TABLE csr.SCENARIO_OPTIONS ADD CONSTRAINT RefCUSTOMER1995 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

INSERT INTO csr.scenario_options (app_sid) (
	SELECT application_sid_id app_sid
	FROM security.securable_object
	WHERE parent_sid_id = application_sid_id
	AND name = 'Scenarios'
);

@../scenario_pkg
@../scenario_body

begin
  dbms_rls.add_policy(
      object_schema   => 'CSR',
      object_name     => 'SCENARIO_OPTIONS',
      policy_name     => 'SCENARIO_OPTIONS_POLICY',
      function_schema => 'CSR',
      policy_function => 'utilityInvoiceCheck',
      statement_types => 'select, insert, update, delete',
      update_check	=> true,
      policy_type     => dbms_rls.context_sensitive );
end;
/

@update_tail
