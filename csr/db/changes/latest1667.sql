-- Please update version.sql too -- this keeps clean builds in sync
define version=1667
@update_header

/* ---------------------------------------------------------------------- */
/* Tables                                                                 */
/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/* Add table "DELEG_REPORT"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.DELEG_REPORT (
    APP_SID NUMBER(10) NOT NULL,
    DELEG_REPORT_SID NUMBER(10) NOT NULL,
    NAME VARCHAR2(255) NOT NULL,
    DELEG_REPORT_TYPE_ID NUMBER(1) NOT NULL,
    START_DTM DATE NOT NULL,
    END_DTM DATE,
    INTERVAL VARCHAR2(1) NOT NULL,
    CONSTRAINT PK_DELEG_REPORT PRIMARY KEY (APP_SID, DELEG_REPORT_SID),
    CONSTRAINT CHK_DELEG_REPORT CHECK (DELEG_REPORT_TYPE_ID IN (0,1))
);

/* ---------------------------------------------------------------------- */
/* Add table "DELEG_REPORT_DELEG_PLAN"                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.DELEG_REPORT_DELEG_PLAN (
    APP_SID NUMBER(10) NOT NULL,
    DELEG_REPORT_SID NUMBER(10) NOT NULL,
    DELEG_PLAN_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_DELEG_REPORT_DELEG_PLAN PRIMARY KEY (APP_SID, DELEG_REPORT_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "DELEG_REPORT_REGION"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CSR.DELEG_REPORT_REGION (
    APP_SID NUMBER(10) NOT NULL,
    DELEG_REPORT_SID NUMBER(10) NOT NULL,
    ROOT_REGION_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_DELEG_REPORT_REGION PRIMARY KEY (APP_SID, DELEG_REPORT_SID)
);

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */

ALTER TABLE CSR.DELEG_REPORT_DELEG_PLAN ADD CONSTRAINT FK_DLG_RPT_DLG_PLAN_DLG_RPT
    FOREIGN KEY (APP_SID, DELEG_REPORT_SID) REFERENCES CSR.DELEG_REPORT (APP_SID,DELEG_REPORT_SID);

ALTER TABLE CSR.DELEG_REPORT_REGION ADD CONSTRAINT FK_DELEG_RPT_DELEG_RPT_REGION 
    FOREIGN KEY (APP_SID, DELEG_REPORT_SID) REFERENCES CSR.DELEG_REPORT (APP_SID,DELEG_REPORT_SID);

ALTER TABLE CSR.DELEG_REPORT_DELEG_PLAN ADD CONSTRAINT FK_DELEG_RPT_DLG_PLAN_DLG_PLAN
    FOREIGN KEY (APP_SID, DELEG_PLAN_SID) REFERENCES CSR.DELEG_PLAN(APP_SID, DELEG_PLAN_SID);
    
ALTER TABLE CSR.DELEG_REPORT_REGION ADD CONSTRAINT FK_DELEG_REPORT_REGION
    FOREIGN KEY (APP_SID, ROOT_REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID);    

create or replace package csr.deleg_report_pkg as
	procedure dummy;
end;
/

create or replace package body csr.deleg_report_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'DELEG_REPORT',
		'DELEG_REPORT_DELEG_PLAN',
		'DELEG_REPORT_REGION'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
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
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

@..\deleg_report_pkg
@..\deleg_report_body

@update_tail