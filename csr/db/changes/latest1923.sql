-- Please update version.sql too -- this keeps clean builds in sync
define version=1923
@update_header

CREATE TABLE CSR.INITIATIVE_SAVING_TYPE(
    SAVING_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    LOOKUP_KEY                   VARCHAR2(256)     NOT NULL,
    LABEL                        VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK_INITIATIVE_SAVING_TYPE PRIMARY KEY (SAVING_TYPE_ID)
);

CREATE UNIQUE INDEX CSR.UK_INIT_SAVING_TYPE_LOOKUP ON CSR.INITIATIVE_SAVING_TYPE(LOOKUP_KEY);

CREATE TABLE CSR.CUSTOMER_INIT_SAVING_TYPE(
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SAVING_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CUSTOMER_INIT_SAVING_TYPE PRIMARY KEY (APP_SID, SAVING_TYPE_ID)
);

CREATE TABLE CSR.DEFAULT_INITIATIVE_USER_STATE(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_SID         NUMBER(10, 0),
    IS_EDITABLE      NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_EDITABLE IN(0,1)),
    CONSTRAINT PK_DEF_INITIATIVE_USER_STATE PRIMARY KEY (APP_SID, FLOW_STATE_ID)
);

ALTER TABLE CSR.INITIATIVE ADD(
	SAVING_TYPE_ID    NUMBER(10, 0)
);

ALTER TABLE CSR.CUSTOMER_INIT_SAVING_TYPE ADD CONSTRAINT FK_CUST_CUST_INIT_SAV_TYPE 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.CUSTOMER_INIT_SAVING_TYPE ADD CONSTRAINT FK_INIT_SAVT_CUST_SAVT 
    FOREIGN KEY (SAVING_TYPE_ID)
    REFERENCES CSR.INITIATIVE_SAVING_TYPE(SAVING_TYPE_ID)
;

ALTER TABLE CSR.INITIATIVE ADD CONSTRAINT FK_CUST_INIT_SAV_TYPE_INIT 
    FOREIGN KEY (APP_SID, SAVING_TYPE_ID)
    REFERENCES CSR.CUSTOMER_INIT_SAVING_TYPE(APP_SID, SAVING_TYPE_ID)
;

ALTER TABLE CSR.DEFAULT_INITIATIVE_USER_STATE ADD CONSTRAINT FK_FLST_DEF_INIT_USER_FLST 
    FOREIGN KEY (APP_SID, FLOW_STATE_ID, FLOW_SID)
    REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID, FLOW_SID)
;

CREATE INDEX CSR.IX_CUST_CUST_INIT_SAV_TYPE ON CSR.CUSTOMER_INIT_SAVING_TYPE(APP_SID);
CREATE INDEX CSR.IX_INIT_SAVT_CUST_SAVT ON CSR.CUSTOMER_INIT_SAVING_TYPE(SAVING_TYPE_ID);
CREATE INDEX CSR.IX_CUST_INIT_SAV_TYPE_INIT ON CSR.INITIATIVE(APP_SID, SAVING_TYPE_ID);
CREATE INDEX CSR.IX_FLST_DEF_INIT_USER_FLST ON CSR.DEFAULT_INITIATIVE_USER_STATE(APP_SID, FLOW_STATE_ID, FLOW_SID);

-- Base data
BEGIN
	INSERT INTO CSR.INITIATIVE_SAVING_TYPE (SAVING_TYPE_ID, lookup_key, label) VALUES(1, 'temporary', 'Temporary saving');
	INSERT INTO CSR.INITIATIVE_SAVING_TYPE (SAVING_TYPE_ID, lookup_key, label) VALUES(2, 'ongoing', 'Ongoing saving');
END;
/

-- Update any existing initiatives
DECLARE
	v_temp_tag_id	csr.tag.tag_id%TYPE;
	v_ong_tag_id	csr.tag.tag_id%TYPE;
BEGIN
	FOR a IN (
		SELECT DISTINCT app_sid
		  FROM csr.initiative i
	) LOOP
		-- Customer -> saving type mappings
		BEGIN
			INSERT INTO csr.customer_init_saving_type (app_sid, saving_type_id) VALUES (a.app_sid, 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN 
				NULL;
		END;
		BEGIN
			INSERT INTO csr.customer_init_saving_type (app_sid, saving_type_id) VALUES (a.app_sid, 2);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN 
				NULL;
		END;
		
		-- Try and get the associated tag ids
		BEGIN
			-- Temporary
			SELECT t.tag_id
			  INTO v_temp_tag_id
			  FROM csr.tag_group g, csr.tag_group_member m, csr.tag t
			 WHERE g.app_sid = a.app_sid
			   AND m.app_sid = a.app_sid
			   AND t.app_sid = a.app_sid
			   AND LOWER(g.name) = 'savings profile'
			   AND m.tag_group_id = g.tag_group_id
			   AND t.tag_id = m.tag_id
			   AND LOWER(t.tag) = 'temporary saving';
			-- Ongoing
			SELECT t.tag_id 
			  INTO v_ong_tag_id
			  FROM csr.tag_group g, csr.tag_group_member m, csr.tag t
			 WHERE g.app_sid = a.app_sid
			   AND m.app_sid = a.app_sid
			   AND t.app_sid = a.app_sid
			   AND LOWER(g.name) = 'savings profile'
			   AND m.tag_group_id = g.tag_group_id
			   AND t.tag_id = m.tag_id
			   AND LOWER(t.tag) = 'ongoing saving';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_temp_tag_id := NULL;
				v_ong_tag_id := NULL;
		END;
		
		-- Default to temporary if tag group/members can't be found
		IF v_temp_tag_id IS NULL THEN
			UPDATE csr.initiative
			   SET saving_type_id = 1
			 WHERE app_sid = a.app_sid;
		
		-- Else set based on tag
		ELSE
			-- With temporary tag set
			UPDATE csr.initiative
			   SET saving_type_id = 1
			 WHERE app_sid = a.app_sid
			   AND initiative_sid IN (
			   	SELECT initiative_sid
			   	  FROM csr.initiative_tag
			   	 WHERE app_sid = a.app_sid
			   	   AND tag_id = v_temp_tag_id
			);
			-- With ongoing tag set
			UPDATE csr.initiative
			   SET saving_type_id = 2
			 WHERE app_sid = a.app_sid
			   AND initiative_sid IN (
			   	SELECT initiative_sid
			   	  FROM csr.initiative_tag
			   	 WHERE app_sid = a.app_sid
			   	   AND tag_id = v_ong_tag_id
			);
			-- Mop up any initiatives not assigned a saving type tag
			UPDATE csr.initiative
			   SET saving_type_id = 1
			 WHERE app_sid = a.app_sid
			   AND saving_type_id IS NULL;
		END IF;
	END LOOP;
END;
/

-- Switch to non nullable column
ALTER TABLE CSR.INITIATIVE MODIFY (
	SAVING_TYPE_ID    NUMBER(10, 0)     NOT NULL
);

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
		'CUSTOMER_INIT_SAVING_TYPE',
		'DEFAULT_INITIATIVE_USER_STATE'
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
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

-- Recompile packages
@../initiative_pkg
@../initiative_body
@../initiative_import_body

@update_tail