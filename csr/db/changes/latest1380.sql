-- Please update version.sql too -- this keeps clean builds in sync
define version=1380
@update_header

-- tables
CREATE TABLE CSRIMP.ROUTE(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    ROUTE_ID         NUMBER(10, 0)    NOT NULL,
    SECTION_SID      NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_SID         NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ROUTE PRIMARY KEY (CSRIMP_SESSION_ID, ROUTE_ID),
    CONSTRAINT FK_ROUTE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ROUTE_STEP(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    ROUTE_STEP_ID       NUMBER(10, 0)    NOT NULL,
    ROUTE_ID            NUMBER(10, 0)    NOT NULL,
    WORK_DAYS_OFFSET    NUMBER(2, 0)     NOT NULL,
    DUE_DTM             DATE             NOT NULL,
    CONSTRAINT PK_ROUTE_STEP PRIMARY KEY (CSRIMP_SESSION_ID, ROUTE_STEP_ID),
    CONSTRAINT FK_ROUTE_STEP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


CREATE TABLE CSRIMP.ROUTE_STEP_USER(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    ROUTE_STEP_ID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ROUTE_STEP_USER PRIMARY KEY (CSRIMP_SESSION_ID, ROUTE_STEP_ID, CSR_USER_SID),
    CONSTRAINT FK_ROUTE_STEP_USER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SECTION_CART(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SECTION_CART_ID    NUMBER(10, 0)    NOT NULL,
    NAME               VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_SECTION_CART PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_CART_ID),
    CONSTRAINT FK_SECTION_CART_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SECTION_CART_MEMBER(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SECTION_CART_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_CART_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_CART_ID, SECTION_SID),
    CONSTRAINT FK_SECTION_CART_MEMBER FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SECTION_TAG(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    PARENT_ID         NUMBER(10, 0),
    SECTION_TAG_ID    NUMBER(10, 0)    NOT NULL,
    TAG               VARCHAR2(255)    NOT NULL,
    ACTIVE            NUMBER(1, 0)     NOT NULL,
    CONSTRAINT PK_SECTION_TAG PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_TAG_ID),
    CONSTRAINT FK_SECTION_TAG FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SECTION_TAG_MEMBER(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SECTION_TAG_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_TAG_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_TAG_ID, SECTION_SID),
    CONSTRAINT FK_SECTION_TAG_MEMBER FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SECTION_ROUTED_FLOW_STATE(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_SID         NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_ROUTED_FLOW_STATE PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_SID, FLOW_STATE_ID),
    CONSTRAINT FK_SECTION_ROUT_FLOW_STATE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SECTION_FLOW(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_FLOW PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_SID),
    CONSTRAINT FK_SECTION_FLOW_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- map tables
CREATE TABLE csrimp.map_section_cart (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_cart_id				NUMBER(10)	NOT NULL,
	new_section_cart_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_cart PRIMARY KEY (old_section_cart_id) USING INDEX,
	CONSTRAINT uk_map_section_cart UNIQUE (new_section_cart_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_CART_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_tag (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_tag_id				NUMBER(10)	NOT NULL,
	new_section_tag_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_tag PRIMARY KEY (old_section_tag_id) USING INDEX,
	CONSTRAINT uk_map_section_tag UNIQUE (new_section_tag_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_TAG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_route (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_route_id					NUMBER(10)	NOT NULL,
	new_route_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_route PRIMARY KEY (old_route_id) USING INDEX,
	CONSTRAINT uk_map_route UNIQUE (new_route_id) USING INDEX,
    CONSTRAINT FK_MAP_ROUTE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_route_step (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_route_step_id					NUMBER(10)	NOT NULL,
	new_route_step_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_route_step PRIMARY KEY (old_route_step_id) USING INDEX,
	CONSTRAINT uk_map_route_step UNIQUE (new_route_step_id) USING INDEX,
    CONSTRAINT FK_MAP_ROUTE_STEP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- add new columns
declare
	v_exists number;
begin
	-- this column is missing on live csrimp
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='SECTION' and column_name='HELP_TEXT';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.section add HELP_TEXT                      CLOB';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='SECTION' and column_name='FLOW_ITEM_ID';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.section add FLOW_ITEM_ID	              NUMBER(10, 0)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='SECTION' and column_name='CURRENT_ROUTE_STEP_ID';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.section add CURRENT_ROUTE_STEP_ID	              NUMBER(10, 0)';
	end if;

	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='SECTION' and column_name='IS_SPLIT';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.section add IS_SPLIT                      NUMBER(1, 0)      NOT NULL';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='SECTION_MODULE' and column_name='FLOW_SID';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.SECTION_MODULE add FLOW_SID              NUMBER(10, 0)';
	end if;
     
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CSRIMP' and table_name='SECTION_MODULE' and column_name='REGION_SID';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.SECTION_MODULE add REGION_SID              NUMBER(10, 0)';
	end if;
end;
/	

-- grants

grant insert,select on csr.route to csrimp;
grant insert,select on csr.route_step to csrimp;
grant insert,select on csr.route_step_user to csrimp;
grant insert,select on csr.section_cart to csrimp;
grant insert,select on csr.section_cart_member to csrimp;
grant insert,select on csr.section_flow to csrimp;
grant insert,select on csr.section_tag to csrimp;
grant insert,select on csr.section_tag_member to csrimp;
grant insert,select on csr.section_routed_flow_state to csrimp;
grant select on csr.route_id_seq to csrimp;
grant select on csr.route_step_id_seq to csrimp;
grant select on csr.section_cart_id_seq to csrimp;
grant select on csr.section_tag_id_seq to csrimp;


grant insert,select,update,delete on csrimp.route to web_user;
grant insert,select,update,delete on csrimp.route_step to web_user;
grant insert,select,update,delete on csrimp.route_step_user to web_user;
grant insert,select,update,delete on csrimp.section_cart to web_user;
grant insert,select,update,delete on csrimp.section_cart_member to web_user;
grant insert,select,update,delete on csrimp.section_flow to web_user;
grant insert,select,update,delete on csrimp.section_routed_flow_state to web_user;
grant insert,select,update,delete on csrimp.section_tag to web_user;
grant insert,select,update,delete on csrimp.section_tag_member to web_user;

-- TODO: the rls on csrimp should be done here

-- pkgs
@../schema_pkg
@../schema_body
@../csr_data_body
@../csrimp/imp_body



@update_tail
