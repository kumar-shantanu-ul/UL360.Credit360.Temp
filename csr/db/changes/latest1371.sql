-- Please update version.sql too -- this keeps clean builds in sync
define version=1371
@update_header

CREATE TABLE CSR.SHEET_VALUE_HIDDEN_CACHE(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SHEET_VALUE_ID				NUMBER(10,0)	NOT NULL,
	VAL_NUMBER					NUMBER(24,10),
	NOTE						CLOB,
	ENTRY_MEASURE_CONVERSION_ID	NUMBER(10, 0),
	ENTRY_VAL_NUMBER			NUMBER(24, 10),
	CONSTRAINT PK_SHEET_VALUE_HIDDEN_CACHE PRIMARY KEY (APP_SID, SHEET_VALUE_ID)
)
;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'SHEET_VALUE_HIDDEN_CACHE'
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
				    -- dbms_output.put_line('done  '||v_name);
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

@../sheet_pkg
@../sheet_body
@../delegation_pkg
@../delegation_body

@update_tail
