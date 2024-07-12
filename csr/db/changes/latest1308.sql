-- Please update version.sql too -- this keeps clean builds in sync
define version=1308
@update_header

-- SHA-1 and MD5 use a 512-bit block-size (longer keys are hashed), so a 64-byte field for the shared secret is sufficient.

create table csr.hmac(
	app_sid number(10) default sys_context('security', 'app') not null,
	shared_secret raw(64) not null
);

alter table csr.hmac add constraint pk_hmac primary key (app_sid);
alter table csr.hmac add constraint fk_hmac_customer foreign key (app_sid) references csr.customer (app_sid);

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin
	v_list := t_tabs(
		'HMAC'
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
					dbms_rls.add_policy(
						object_schema   => 'CSR',
						object_name     => v_list(i),
						policy_name     => v_name,
						function_schema => 'CSR',
						policy_function => 'appSidCheck',
						statement_types => 'select, insert, update, delete',
						update_check	=> true,
						policy_type     => dbms_rls.context_sensitive);
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

@..\saml_pkg
@..\saml_body

@update_tail