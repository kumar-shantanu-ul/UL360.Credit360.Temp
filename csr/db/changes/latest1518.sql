-- Please update version.sql too -- this keeps clean builds in sync
define version=1518
@update_header

CREATE TABLE CSR.AUDIT_CLOSURE_TYPE(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    AUDIT_CLOSURE_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    LABEL                      VARCHAR2(255)    NOT NULL,
    RE_AUDIT_DUE_AFTER         NUMBER(10, 0),
    RE_AUDIT_DUE_AFTER_TYPE    CHAR(1),
    REMINDER_OFFSET_DAYS       NUMBER(10, 0),
    REPORTABLE_FOR_MONTHS      NUMBER(10, 0),
    ICON_IMAGE                 BLOB,
    ICON_IMAGE_FILENAME        VARCHAR2(255),
    ICON_IMAGE_MIME_TYPE       VARCHAR2(255),
    CONSTRAINT CHK_CHK_DUE_AFTER_VALID CHECK ((RE_AUDIT_DUE_AFTER IS NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NULL) OR (RE_AUDIT_DUE_AFTER IS NOT NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NOT NULL)),
    CONSTRAINT CHK_DUE_AFTER_TYPE_VLD CHECK (RE_AUDIT_DUE_AFTER_TYPE IN ('d','w','m','y')),
    CONSTRAINT CHK_RPRTBLE_MNTHS_POS CHECK (REPORTABLE_FOR_MONTHS > 0),
    CONSTRAINT PK_AUDIT_CLOSURE_TYPE PRIMARY KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID)
)
;


ALTER TABLE CSR.INTERNAL_AUDIT ADD AUDIT_CLOSURE_TYPE_ID     NUMBER(10, 0);

ALTER TABLE CSR.INTERNAL_AUDIT RENAME CONSTRAINT PK661 TO PK_INTERNAL_AUDIT;

CREATE INDEX CSR.IX_AUDIT_CLSR_IAT ON CSR.AUDIT_CLOSURE_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID)
;

CREATE INDEX CSR.IX_INT_AUD_CLSR_TYPE ON CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID)
;

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE ADD CONSTRAINT FK_AUDIT_CLSR_IAT 
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
    REFERENCES CSR.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID)
;

ALTER TABLE CSR.INTERNAL_AUDIT ADD CONSTRAINT FK_INT_AUD_CLSR_TYPE 
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID)
    REFERENCES CSR.AUDIT_CLOSURE_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID)
;

CREATE SEQUENCE CSR.AUDIT_CLOSURE_TYPE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'AUDIT_CLOSURE_TYPE'
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

CREATE OR REPLACE VIEW csr.v$audit_next_due AS
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
		   ia.audit_dtm, act.audit_closure_type_id, ia.app_sid,
		   CASE (re_audit_due_after_type)
				WHEN 'd' THEN ia.audit_dtm + re_audit_due_after
				WHEN 'w' THEN ia.audit_dtm + (re_audit_due_after*7)
				WHEN 'm' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after)
				WHEN 'y' THEN ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12)
		   END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn,
			   audit_closure_type_id, app_sid
		  FROM internal_audit
		 WHERE audit_closure_type_id IS NOT NULL
	       ) ia
	  JOIN audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
	   AND ia.app_sid = act.app_sid
	  JOIN region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND act.re_audit_due_after IS NOT NULL
	   AND r.active=1;

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Close audits', 0);
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can import audit non-compliances', 0);

CREATE TABLE CSRIMP.AUDIT_CLOSURE_TYPE(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    INTERNAL_AUDIT_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    AUDIT_CLOSURE_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    LABEL                      VARCHAR2(255)    NOT NULL,
    RE_AUDIT_DUE_AFTER         NUMBER(10, 0),
    RE_AUDIT_DUE_AFTER_TYPE    CHAR(1),
    REMINDER_OFFSET_DAYS       NUMBER(10, 0),
    REPORTABLE_FOR_MONTHS      NUMBER(10, 0),
    ICON_IMAGE                 BLOB,
    ICON_IMAGE_FILENAME        VARCHAR2(255),
    ICON_IMAGE_MIME_TYPE       VARCHAR2(255),
    CONSTRAINT CHK_CHK_DUE_AFTER_VALID CHECK ((RE_AUDIT_DUE_AFTER IS NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NULL) OR (RE_AUDIT_DUE_AFTER IS NOT NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NOT NULL)),
    CONSTRAINT CHK_DUE_AFTER_TYPE_VLD CHECK (RE_AUDIT_DUE_AFTER_TYPE IN ('d','w','m','y')),
    CONSTRAINT CHK_RPRTBLE_MNTHS_POS CHECK (REPORTABLE_FOR_MONTHS > 0),
    CONSTRAINT PK_AUDIT_CLOSURE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID),
    CONSTRAINT FK_AUDIT_CLOSURE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

ALTER TABLE CSRIMP.INTERNAL_AUDIT ADD AUDIT_CLOSURE_TYPE_ID     NUMBER(10, 0);

CREATE TABLE csrimp.map_audit_closure_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_audit_closure_type_id		NUMBER(10)	NOT NULL,
	new_audit_closure_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_audit_closure_type PRIMARY KEY (old_audit_closure_type_id) USING INDEX,
	CONSTRAINT uk_map_audit_closure_type UNIQUE (new_audit_closure_type_id) USING INDEX,
    CONSTRAINT FK_MAP_AUDIT_CLOSURE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'AUDIT_CLOSURE_TYPE',
		policy_name     => 'AUDIT_CLOSURE_TYPE_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
END;
/

grant select on csr.audit_closure_type_id_seq to csrimp;
grant insert on csr.audit_closure_type to csrimp;
grant select,insert,update,delete on csrimp.audit_closure_type to web_user;

@..\audit_pkg
@..\schema_pkg

@..\audit_body
@..\schema_body
@..\csrimp\imp_body


@update_tail
