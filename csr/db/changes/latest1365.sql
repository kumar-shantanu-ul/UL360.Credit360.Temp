-- Please update version.sql too -- this keeps clean builds in sync
define version=1365
@update_header 



-- 
-- SEQUENCE: CSR.ROUTE_ID_SEQ 
--
declare
	v_exists number;
begin
	select count(*) 
	  into v_exists
	  from all_sequences
	 where sequence_owner='CSR' and sequence_name='ROUTE_ID_SEQ';

	if v_exists = 0 then
		execute immediate 'CREATE SEQUENCE CSR.ROUTE_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 5 NOORDER';
	end if;

	select count(*) 
	  into v_exists
	  from all_sequences
	 where sequence_owner='CSR' and sequence_name='ROUTE_STEP_ID_SEQ';

	if v_exists = 0 then
		execute immediate 'CREATE SEQUENCE CSR.ROUTE_STEP_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 5 NOORDER';
	end if;
	
	select count(*) 
	  into v_exists
	  from all_sequences
	 where sequence_owner='CSR' and sequence_name='SECTION_CART_ID_SEQ';

	if v_exists = 0 then
		execute immediate 'CREATE SEQUENCE CSR.SECTION_CART_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 5 NOORDER';
	end if;

	select count(*) 
	  into v_exists
	  from all_sequences
	 where sequence_owner='CSR' and sequence_name='SECTION_TAG_ID_SEQ';

	if v_exists = 0 then
		execute immediate 'CREATE SEQUENCE CSR.SECTION_TAG_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 5 NOORDER';
	end if;

	select count(*) 
	  into v_exists
	  from all_tables
	 where owner='CSR' and table_name='ROUTE';

	for r in (select table_name
				from all_tables
			   where owner = 'CSR' and table_name in (
			   	'ROUTE', 'ROUTE_STEP', 'ROUTE_STEP_USER', 
			   	'SECTION_CART', 'SECTION_CART_MEMBER', 'SECTION_TAG',
			   	'SECTION_TAG_MEMBER', 'SECTION_ROUTED_FLOW_STATE',
			   	'SECTION_FLOW')) loop
		execute immediate 'drop table csr.'||r.table_name||' cascade constraints';
	end loop;
end;
/
-- 
-- TABLE: CSR.ROUTE 
--

-- TABLE: CSR.ROUTE 
--
CREATE TABLE CSR.ROUTE(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ROUTE_ID         NUMBER(10, 0)    NOT NULL,
    SECTION_SID      NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_SID         NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ROUTE PRIMARY KEY (APP_SID, ROUTE_ID)
);



    
-- 
-- TABLE: CSR.ROUTE_STEP 
--

CREATE TABLE CSR.ROUTE_STEP(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ROUTE_STEP_ID       NUMBER(10, 0)    NOT NULL,
    ROUTE_ID            NUMBER(10, 0)    NOT NULL,
    WORK_DAYS_OFFSET    NUMBER(2, 0)     NOT NULL,
    DUE_DTM             DATE             NOT NULL,
    CONSTRAINT PK_ROUTE_STEP PRIMARY KEY (APP_SID, ROUTE_STEP_ID)
)
;



-- 
-- TABLE: CSR.ROUTE_STEP_USER 
--

CREATE TABLE CSR.ROUTE_STEP_USER(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ROUTE_STEP_ID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ROUTE_STEP_USER PRIMARY KEY (APP_SID, ROUTE_STEP_ID, CSR_USER_SID)
)
;




-- 
-- TABLE: CSR.SECTION_CART 
--

CREATE TABLE CSR.SECTION_CART(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SECTION_CART_ID    NUMBER(10, 0)    NOT NULL,
    NAME               VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_SECTION_CART PRIMARY KEY (APP_SID, SECTION_CART_ID)
)
;



-- 
-- TABLE: CSR.SECTION_CART_MEMBER 
--

CREATE TABLE CSR.SECTION_CART_MEMBER(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SECTION_CART_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_CART_MEMBER PRIMARY KEY (APP_SID, SECTION_CART_ID, SECTION_SID)
)
;


-- 
-- TABLE: CSR.SECTION_TAG 
--

CREATE TABLE CSR.SECTION_TAG(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PARENT_ID         NUMBER(10, 0),
    SECTION_TAG_ID    NUMBER(10, 0)    NOT NULL,
    TAG               VARCHAR2(255)    NOT NULL,
    ACTIVE            NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CK_SECTION_TAG_ACTIVE CHECK (ACTIVE IN (0,1)),
    CONSTRAINT PK_SECTION_TAG PRIMARY KEY (APP_SID, SECTION_TAG_ID)
)
;



-- 
-- TABLE: CSR.SECTION_TAG_MEMBER 
--

CREATE TABLE CSR.SECTION_TAG_MEMBER(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SECTION_TAG_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_TAG_MEMBER PRIMARY KEY (APP_SID, SECTION_TAG_ID, SECTION_SID)
)
;

-- 
-- TABLE: CSR.SECTION_ROUTED_FLOW_STATE 
--

CREATE TABLE CSR.SECTION_ROUTED_FLOW_STATE(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID         NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_ROUTED_FLOW_STATE PRIMARY KEY (APP_SID, FLOW_SID, FLOW_STATE_ID)
)
;


-- 
-- TABLE: CSR.SECTION_FLOW 
--

CREATE TABLE CSR.SECTION_FLOW(
    APP_SID     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_FLOW PRIMARY KEY (APP_SID, FLOW_SID)
)
;





declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSR' and table_name='SECTION' and column_name='FLOW_ITEM_ID';
	if v_exists = 0 then
		execute immediate 'alter table csr.section add FLOW_ITEM_ID	              NUMBER(10, 0)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSR' and table_name='SECTION' and column_name='CURRENT_ROUTE_STEP_ID';
	if v_exists = 0 then
		execute immediate 'alter table csr.section add CURRENT_ROUTE_STEP_ID	              NUMBER(10, 0)';
	end if;

	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSR' and table_name='SECTION' and column_name='IS_SPLIT';
	if v_exists = 0 then
		execute immediate 'alter table csr.section add IS_SPLIT                      NUMBER(1, 0)      DEFAULT 0 NOT NULL';
	end if;
	
	select count(*)
	  into v_exists
	  from all_constraints
	 where owner='CSR' and constraint_name='CK_SECTION_IS_SPLIT';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE CSR.SECTION ADD CONSTRAINT CK_SECTION_IS_SPLIT CHECK (IS_SPLIT IN (0,1))';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSR' and table_name='SECTION_MODULE' and column_name='FLOW_SID';
	if v_exists = 0 then
		execute immediate 'alter table csr.SECTION_MODULE add FLOW_SID              NUMBER(10, 0)';
	end if;
     
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSR' and table_name='SECTION_MODULE' and column_name='REGION_SID';
	if v_exists = 0 then
		execute immediate 'alter table csr.SECTION_MODULE add REGION_SID              NUMBER(10, 0)';
	end if;
end;
/

-- 
-- TABLE: CSR.ROUTE 
--

ALTER TABLE CSR.ROUTE ADD CONSTRAINT RefCUSTOMER3237 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.ROUTE ADD CONSTRAINT FK_SECTION_ROUTE 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
;

ALTER TABLE CSR.ROUTE ADD CONSTRAINT FK_SECTION_ROUTED_FS_ROUTE 
    FOREIGN KEY (APP_SID, FLOW_SID, FLOW_STATE_ID)
    REFERENCES CSR.SECTION_ROUTED_FLOW_STATE(APP_SID, FLOW_SID, FLOW_STATE_ID)
;


-- 
-- TABLE: CSR.ROUTE_STEP 
--

ALTER TABLE CSR.ROUTE_STEP ADD CONSTRAINT FK_ROUTE_ROUTE_STEP 
    FOREIGN KEY (APP_SID, ROUTE_ID)
    REFERENCES CSR.ROUTE(APP_SID, ROUTE_ID)
;


-- 
-- TABLE: CSR.ROUTE_STEP_USER 
--

ALTER TABLE CSR.ROUTE_STEP_USER ADD CONSTRAINT FK_CSR_USER_ROUTE_STEP_USER 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.ROUTE_STEP_USER ADD CONSTRAINT FK_ROUTE_STEP_USER 
    FOREIGN KEY (APP_SID, ROUTE_STEP_ID)
    REFERENCES CSR.ROUTE_STEP(APP_SID, ROUTE_STEP_ID)
;

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_constraints
	 where owner='CSR' and constraint_name='FK_FLOW_ITEM_SECTION';

	if v_exists = 0 then
		execute immediate 'ALTER TABLE CSR.SECTION ADD CONSTRAINT FK_FLOW_ITEM_SECTION  FOREIGN KEY (APP_SID, FLOW_ITEM_ID) REFERENCES CSR.FLOW_ITEM(APP_SID, FLOW_ITEM_ID)';
	end if;
end;
/

ALTER TABLE CSR.SECTION ADD CONSTRAINT FK_ROUTE_STEP_SECTION 
    FOREIGN KEY (APP_SID, CURRENT_ROUTE_STEP_ID)
    REFERENCES CSR.ROUTE_STEP(APP_SID, ROUTE_STEP_ID)
;


-- 
-- TABLE: CSR.SECTION_CART 
--

ALTER TABLE CSR.SECTION_CART ADD CONSTRAINT FK_CUST_SECTION_CART 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;


-- 
-- TABLE: CSR.SECTION_CART_MEMBER 
--

ALTER TABLE CSR.SECTION_CART_MEMBER ADD CONSTRAINT FK_SECTION_SECTION_CART_MEMBER 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
;


ALTER TABLE CSR.SECTION_CART_MEMBER ADD CONSTRAINT FK_SECTION_CART_CART_MEMB 
    FOREIGN KEY (APP_SID, SECTION_CART_ID)
    REFERENCES CSR.SECTION_CART(APP_SID, SECTION_CART_ID)
;


-- 
-- TABLE: CSR.SECTION_MODULE 
--
declare
	v_exists number;
	v_constraint_name varchar2(30);
begin
	select count(*)
	  into v_exists
	  from all_constraints
	 where owner='CSR' and constraint_name='FK_REGION_SECTION_MODULE';

	if v_exists = 0 then		
		select min(ac.constraint_name)
		  into v_constraint_name
		  from all_constraints ac, all_cons_columns acc1, all_cons_columns acc2
		 where ac.owner='CSR' and ac.table_name='SECTION_MODULE' and ac.r_constraint_name='PK_REGION' 
		   and ac.owner = acc1.owner and ac.constraint_name = acc1.constraint_name
		   and acc1.column_name = 'APP_SID'
		   and ac.owner = acc2.owner and ac.constraint_name = acc2.constraint_name
		   and acc2.column_name = 'REGION_SID'
		 ;
		if v_constraint_name is not null then
			execute immediate 'alter table csr.section_module drop constraint '||v_constraint_name;
		end if;
		execute immediate 'ALTER TABLE CSR.SECTION_MODULE ADD CONSTRAINT FK_REGION_SECTION_MODULE FOREIGN KEY (APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)';
	end if;

	select count(*)
	  into v_exists
	  from all_constraints
	 where owner='CSR' and constraint_name='FK_SECTION_FLOW_SECTION_MODULE';

	if v_exists = 0 then
		select min(ac.constraint_name)
		  into v_constraint_name
		  from all_constraints ac, all_cons_columns acc1, all_cons_columns acc2
		 where ac.owner='CSR' and ac.table_name='SECTION_MODULE' and ac.r_constraint_name='PK_FLOW' 
		   and ac.owner = acc1.owner and ac.constraint_name = acc1.constraint_name
		   and acc1.column_name = 'APP_SID'
		   and ac.owner = acc2.owner and ac.constraint_name = acc2.constraint_name
		   and acc2.column_name = 'FLOW_SID'
		 ;
		if v_constraint_name is not null then
			execute immediate 'alter table csr.section_module drop constraint '||v_constraint_name;
		end if;
		execute immediate 'ALTER TABLE CSR.SECTION_MODULE ADD CONSTRAINT FK_SECTION_FLOW_SECTION_MODULE FOREIGN KEY (APP_SID, FLOW_SID) REFERENCES CSR.SECTION_FLOW(APP_SID, FLOW_SID)';
	end if;
end;
/


-- 
-- TABLE: CSR.SECTION_TAG 
--

ALTER TABLE CSR.SECTION_TAG ADD CONSTRAINT FK_CUST_SECTION_TAG 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.SECTION_TAG ADD CONSTRAINT RefSECTION_TAG3249 
    FOREIGN KEY (APP_SID, PARENT_ID)
    REFERENCES CSR.SECTION_TAG(APP_SID, SECTION_TAG_ID)
;


-- 
-- TABLE: CSR.SECTION_TAG_MEMBER 
--


ALTER TABLE CSR.SECTION_TAG_MEMBER ADD CONSTRAINT FK_SECTION_SECTION_TAG_MEMB 
    FOREIGN KEY (APP_SID, SECTION_SID)
    REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
;

ALTER TABLE CSR.SECTION_TAG_MEMBER ADD CONSTRAINT FK_SECTION_TAG_TAG_MEMBER 
    FOREIGN KEY (APP_SID, SECTION_TAG_ID)
    REFERENCES CSR.SECTION_TAG(APP_SID, SECTION_TAG_ID)
;

-- 
-- TABLE: CSR.SECTION_ROUTED_FLOW_STATE 
--

ALTER TABLE CSR.SECTION_ROUTED_FLOW_STATE ADD CONSTRAINT FK_FS_SECTION_ROUTED_FS 
    FOREIGN KEY (APP_SID, FLOW_STATE_ID, FLOW_SID)
    REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID, FLOW_SID)
;

ALTER TABLE CSR.SECTION_ROUTED_FLOW_STATE ADD CONSTRAINT FK_SECTION_FLOW_SR_FLOW_STATE 
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.SECTION_FLOW(APP_SID, FLOW_SID)
;


-- 
-- TABLE: CSR.SECTION_FLOW 
--

ALTER TABLE CSR.SECTION_FLOW ADD CONSTRAINT FK_FLOW_SECTION_FLOW 
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID)
;

-- 
-- TEMPORARY TABLE: CSR.TEMP_SECTION_FILTER
--

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_SECTION_FILTER
(
	SECTION_SID						NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;

--
-- RLS
-- 


declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'ROUTE',
		'ROUTE_STEP',
		'ROUTE_STEP_USER',
		'SECTION_CART',
		'SECTION_CART_MEMBER',
		'SECTION_FLOW',
		'SECTION_ROUTED_FLOW_STATE',
		'SECTION_TAG',
		'SECTION_TAG_MEMBER'
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



/* SECTION TEXT INDEX */
grant create table to csr;
create index csr.ix_section_body_search on csr.section_version(body) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
revoke create table from csr;

------------------------
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.section_body_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_section_body_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise section body text indexes');
       COMMIT;       
END;
/

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit section tags', 0);
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can view section tags', 0);
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can see routed flow transitions', 0);
END;
/

@../flow_pkg
@../flow_body
@../section_pkg
@../section_body

@update_tail
