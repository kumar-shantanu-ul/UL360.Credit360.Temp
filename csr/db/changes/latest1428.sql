-- Please update version.sql too -- this keeps clean builds in sync
define version=1428
@update_header

--
-- SEQUENCE: CSR.SECTION_TRANS_COMMENT_ID_SEQ 
--

CREATE SEQUENCE CSR.SECTION_TRANS_COMMENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;



-- 
-- TABLE: CSR.SECTION_TRANS_COMMENT 
--

CREATE TABLE CSR.SECTION_TRANS_COMMENT(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SECTION_TRANS_COMMENT_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID                 NUMBER(10, 0)    NOT NULL,
    ENTERED_BY_SID              NUMBER(10, 0)    NOT NULL,
    ENTERED_DTM                 DATE             NOT NULL,
    COMMENT_TEXT                CLOB             NOT NULL,
    CONSTRAINT PK_SECTION_TRANS_COMMENT PRIMARY KEY (APP_SID, SECTION_TRANS_COMMENT_ID)
)
;

-- 
-- TABLE: CSR.SECTION_TRANS_COMMENT 
--

ALTER TABLE CSR.SECTION_TRANS_COMMENT ADD CONSTRAINT FK_ST_COMMENT_SECTION 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
;

ALTER TABLE CSR.SECTION_TRANS_COMMENT ADD CONSTRAINT FK_ST_COMMENT_USER 
    FOREIGN KEY (APP_SID, ENTERED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

-- RLS
declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'SECTION_TRANS_COMMENT'
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

@../section_pkg
@../section_body

@update_tail
