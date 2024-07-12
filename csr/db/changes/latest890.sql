-- Please update version.sql too -- this keeps clean builds in sync
define version=890
@update_header

-- For the workflow, since the alert is on the transition, then provide screen to define N alerts
-- for the workflow and bind each alert to each transition -> probably more sensible.
-- i.e. some central workflow alerts editing page. 


-- just in case
CREATE TABLE CSR.XX_ALERT_BATCH_RUN AS SELECT * FROM CSR.ALERT_BATCH_RUN;
CREATE TABLE CSR.XX_ALERT_TEMPLATE_BODY AS SELECT * FROM CSR.ALERT_TEMPLATE_BODY;
CREATE TABLE CSR.XX_ALERT_TEMPLATE AS SELECT * FROM CSR.ALERT_TEMPLATE;
CREATE TABLE CSR.XX_CUSTOMER_ALERT_TYPE AS SELECT * FROM CSR.CUSTOMER_ALERT_TYPE;

-- drop constraints and primary keys prior to change 
ALTER TABLE CSR.ALERT_TEMPLATE DROP CONSTRAINT FK_ALERT_TPL_CUST_ALERT_TYPE;
ALTER TABLE CSR.ALERT_TEMPLATE_BODY DROP CONSTRAINT FK_ALERT_TPL_BDY_ALERT_TPL;
ALTER TABLE CSR.ALERT_BATCH_RUN DROP CONSTRAINT FK_ALERT_BATCH_RUN_ALERT_TYPE;

-- these ones had dodgy generated names, so clean them up safely (we recreate later)
BEGIN
    FOR r IN (
         SELECT owner, constraint_name, table_name
           FROM all_constraints
          WHERE owner = 'CSR' AND R_constraint_name in (
           select constraint_name from all_constraints where owner ='CSR' and table_name ='ALERT_TYPE' and constraint_type='P'
         ) AND table_name = 'CUSTOMER_ALERT_TYPE'
    )
    LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
    END LOOP;
END;
/

BEGIN
    FOR r IN (
         SELECT owner, constraint_name, table_name
           FROM all_constraints
          WHERE owner = 'CSR' AND R_constraint_name in (
           select constraint_name from all_constraints where owner ='CSR' and table_name ='ALERT_TYPE' and constraint_type='P'
         ) AND table_name = 'ALERT_TYPE'
    )
    LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
    END LOOP;
END;
/


ALTER TABLE CSR.ALERT_TEMPLATE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.ALERT_TEMPLATE_BODY DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.ALERT_BATCH_RUN DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.CUSTOMER_ALERT_TYPE DROP PRIMARY KEY DROP INDEX;

-- add the new columns to customer_alert_type (and child tables)
ALTER TABLE CSR.CUSTOMER_ALERT_TYPE ADD (
     CUSTOMER_ALERT_TYPE_ID     NUMBER(10, 0)   NULL,
     GET_PARAMs_SP				VARCHAR2(255)	NULL
);

ALTER TABLE CSR.ALERT_TEMPLATE ADD (
     CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NULL
);

ALTER TABLE CSR.ALERT_TEMPLATE_BODY ADD (
     CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NULL
);

ALTER TABLE CSR.ALERT_BATCH_RUN ADD (
     CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NULL
);

-- new customer_alert_type_param table
CREATE TABLE CSR.CUSTOMER_ALERT_TYPE_PARAM(
    APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    FIELD_NAME       		  VARCHAR2(100)     NOT NULL,
    DESCRIPTION      		  VARCHAR2(200)     NOT NULL,
    HELP_TEXT        		  VARCHAR2(2000)    NOT NULL,
    REPEATS          		  NUMBER(1, 0)      NOT NULL,
    DISPLAY_POS      		  NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_CUS_ALERT_TYPE_PARAM PRIMARY KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID, FIELD_NAME)
);

 
 
-- set customer_alert_type_id values, make primary key, and propagate down to child tables 
CREATE SEQUENCE CSR.CUSTOMER_ALERT_TYPE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER;

UPDATE CSR.CUSTOMER_ALERT_TYPE 
   SET CUSTOMER_ALERT_TYPE_ID = csr.CUSTOMER_ALERT_TYPE_ID_SEQ.nextval;
   
ALTER TABLE CSR.CUSTOMER_ALERT_TYPE MODIFY CUSTOMER_ALERT_TYPE_ID NOT NULL;

ALTER TABLE CSR.CUSTOMER_ALERT_TYPE ADD
     CONSTRAINT PK_CUSTOMER_ALERT_TYPE PRIMARY KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID);

-- recreate these two which we dropped earlier in order to give them proper names
ALTER TABLE CSR.CUSTOMER_ALERT_TYPE ADD CONSTRAINT FK_STD_ALT_CUS_ALT 
    FOREIGN KEY (ALERT_TYPE_ID)
    REFERENCES CSR.ALERT_TYPE(ALERT_TYPE_ID);

ALTER TABLE CSR.ALERT_TYPE ADD CONSTRAINT FK_STD_ALT_STD_ALT
    FOREIGN KEY (PARENT_ALERT_TYPE_ID)
    REFERENCES CSR.ALERT_TYPE(ALERT_TYPE_ID);

ALTER TABLE CSR.CUSTOMER_ALERT_TYPE_PARAM ADD CONSTRAINT FK_CUS_AL_TYPE_PARM_AL_TYPE 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.CUSTOMER_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID);


BEGIN
	FOR r IN (
		SELECT app_sid, alert_type_id, customer_alert_type_id 
		  FROM csr.customer_alert_type
 	)
	LOOP
		UPDATE csr.alert_template
		   SET customer_alert_type_id = r.customer_alert_type_id
		 WHERE app_sid = r.app_sid AND alert_type_id = r.alert_type_id;

		UPDATE csr.alert_template_body
		   SET customer_alert_type_id = r.customer_alert_type_id
		 WHERE app_sid = r.app_sid AND alert_type_id = r.alert_type_id;

		UPDATE csr.alert_batch_run
		   SET customer_alert_type_id = r.customer_alert_type_id
		 WHERE app_sid = r.app_sid AND alert_type_id = r.alert_type_id;
	END LOOP;
END;
/

-- clear out unused stuff
DELETE FROM CSR.ALERT_BATCH_RUN WHERE CUSTOMER_ALERT_TYPE_ID IS NULL;

-- make columns not null prior to sticking on PKs
ALTER TABLE CSR.ALERT_TEMPLATE_BODY MODIFY CUSTOMER_ALERT_TYPE_ID NOT NULL;
ALTER TABLE CSR.ALERT_TEMPLATE MODIFY CUSTOMER_ALERT_TYPE_ID NOT NULL;
ALTER TABLE CSR.ALERT_BATCH_RUN MODIFY CUSTOMER_ALERT_TYPE_ID NOT NULL;

-- stick on some primary keys
ALTER TABLE CSR.ALERT_TEMPLATE_BODY ADD 
    CONSTRAINT PK_ALERT_TEMPLATE_BODY PRIMARY KEY (APP_SID, LANG, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.ALERT_TEMPLATE ADD
     CONSTRAINT PK_ALERT_TEMPLATE PRIMARY KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.ALERT_BATCH_RUN ADD
     CONSTRAINT PK_ALERT_BATCH_RUN PRIMARY KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID, CSR_USER_SID);

-- add constraints back
ALTER TABLE CSR.ALERT_TEMPLATE_BODY ADD CONSTRAINT FK_ALERT_TPL_BDY_ALERT_TPL 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.ALERT_TEMPLATE(APP_SID, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.ALERT_TEMPLATE ADD CONSTRAINT FK_ALERT_TPL_CUST_ALERT_TYPE 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.CUSTOMER_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID);
 
ALTER TABLE CSR.ALERT_BATCH_RUN ADD CONSTRAINT FK_AL_BATCH_RUN_CUS_AL_TYPE 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.CUSTOMER_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID);


-- rename everything to STD_
ALTER TABLE CSR.ALERT_TYPE RENAME TO STD_ALERT_TYPE;
ALTER TABLE CSR.ALERT_TYPE_PARAM RENAME TO STD_ALERT_TYPE_PARAM;

ALTER TABLE CSR.STD_ALERT_TYPE RENAME COLUMN ALERT_TYPE_ID TO STD_ALERT_TYPE_ID;
ALTER TABLE CSR.STD_ALERT_TYPE_PARAM RENAME COLUMN ALERT_TYPE_ID TO STD_ALERT_TYPE_ID;
ALTER TABLE CSR.CUSTOMER_ALERT_TYPE RENAME COLUMN ALERT_TYPE_ID TO STD_ALERT_TYPE_ID;
ALTER TABLE CSR.DEFAULT_ALERT_TEMPLATE_BODY RENAME COLUMN ALERT_TYPE_ID TO STD_ALERT_TYPE_ID;
ALTER TABLE CSR.DEFAULT_ALERT_TEMPLATE RENAME COLUMN ALERT_TYPE_ID TO STD_ALERT_TYPE_ID;


CREATE UNIQUE INDEX CSR.UK_CUSTOMER_ALERT_TYPE ON CSR.CUSTOMER_ALERT_TYPE(APP_SID, NVL2(STD_ALERT_TYPE_ID, 'S'||STD_ALERT_TYPE_ID, 'C'||CUSTOMER_ALERT_TYPE_ID));


-- fix up temp table
DROP TABLE CSR.TEMP_ALERT_BATCH_RUN;

-- i've kept in std_alert_type_id because it gets used quite a bit so faster/easier to keep it in?
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_ALERT_BATCH_RUN
(
	customer_alert_type_id			NUMBER(10) NOT NULL,
	std_alert_type_id				NUMBER(10) NULL,
	app_sid							NUMBER(10) NOT NULL,
	csr_user_sid					NUMBER(10) NOT NULL,
	prev_fire_time_gmt				TIMESTAMP(6),
	this_fire_time					TIMESTAMP(6) NOT NULL,
	this_fire_time_gmt				TIMESTAMP(6) NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE INDEX CSR.IX_TEMP_ALERT_BATCH_RUN ON CSR.TEMP_ALERT_BATCH_RUN (customer_alert_type_id, app_sid, csr_user_sid);

grant select, references on csr.temp_alert_batch_run to actions;

-- new table for CMS_TAB_ALERTs
CREATE TABLE CSR.CMS_TAB_ALERT_TYPE(
    APP_SID          		  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TAB_SID          		  NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    HAS_REPEATS      		  NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	FILTER_XML		 		  SYS.XMLType,
    CONSTRAINT CHK_CMS_ALERT_HAS_REPEATS CHECK (HAS_REPEATS IN (0,1)),
    CONSTRAINT PK_CMS_TAB_ALERT_TYPE PRIMARY KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
);


DECLARE
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
BEGIN	
	v_list := t_tabs(
		'CMS_TAB_ALERT_TYPE'
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
END;
/

ALTER TABLE CSR.CMS_TAB_ALERT_TYPE ADD CONSTRAINT FK_CST_ALRT_TYPE_TAB_ALRT_TYPE
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.CUSTOMER_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID) ON DELETE CASCADE;


ALTER TABLE CSR.CMS_TAB_ALERT_TYPE ADD CONSTRAINT FK_CMS_TAB_TAB_ALERT_TYPE
    FOREIGN KEY (APP_SID, TAB_SID)
    REFERENCES CMS.TAB(APP_SID, TAB_SID) ON DELETE CASCADE;

CREATE INDEX CSR.IX_CMS_TAB_ALERT_TAB_SID ON CSR.CMS_TAB_ALERT_TYPE (APP_SID, TAB_SID);

GRANT SELECT ON cms.tab TO csr;
GRANT SELECT ON cms.tab_column TO csr;

create global temporary table csrimp.map_customer_alert_type(
	old_customer_alert_type_id				number(10)	not null,
	new_customer_alert_type_id				number(10)	not null,
	constraint pk_map_customer_alert_type primary key (old_customer_alert_type_id) using index,
	constraint uk_map_customer_alert_type unique (new_customer_alert_type_id) using index
) on commit delete rows;


DROP TABLE CSRIMP.ALERT_TEMPLATE PURGE;
CREATE GLOBAL TEMPORARY TABLE CSRIMP.ALERT_TEMPLATE(
    CUSTOMER_ALERT_TYPE_ID  NUMBER(10, 0)    NOT NULL,
    ALERT_FRAME_ID    		NUMBER(10, 0)    NOT NULL,
    SEND_TYPE         		VARCHAR2(10)     NOT NULL,
    REPLY_TO_NAME     		VARCHAR2(255),
    REPLY_TO_EMAIL    		VARCHAR2(255),
    CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE CHECK (SEND_TYPE IN ('manual', 'automatic')),
    CONSTRAINT PK_ALERT_TEMPLATE PRIMARY KEY (CUSTOMER_ALERT_TYPE_ID)
) ON COMMIT DELETE ROWS;


DROP TABLE CSRIMP.ALERT_TEMPLATE_BODY PURGE;
CREATE GLOBAL TEMPORARY TABLE CSRIMP.ALERT_TEMPLATE_BODY(
    CUSTOMER_ALERT_TYPE_ID  NUMBER(10, 0)    NOT NULL,
    LANG            		VARCHAR2(10)     NOT NULL,
    SUBJECT          		CLOB             NOT NULL,
    BODY_HTML        		CLOB             NOT NULL,
    ITEM_HTML        		CLOB             NOT NULL,
    CONSTRAINT PK_ALERT_TEMPLATE_BODY PRIMARY KEY (CUSTOMER_ALERT_TYPE_ID, LANG)
) ON COMMIT DELETE ROWS;


DROP TABLE CSRIMP.CUSTOMER_ALERT_TYPE PURGE;
CREATE GLOBAL TEMPORARY TABLE CSRIMP.CUSTOMER_ALERT_TYPE(
	CUSTOMER_ALERT_TYPE_ID		NUMBER(10, 0)    NOT NULL,
    STD_ALERT_TYPE_ID    		NUMBER(10, 0)    NULL,
    CONSTRAINT PK356 PRIMARY KEY (CUSTOMER_ALERT_TYPE_ID)
) ON COMMIT DELETE ROWS;


grant select on csr.customer_alert_type to csrimp;
grant select on csr.customer_alert_type_id_seq to csrimp;
grant select on csr.customer_alert_type_id_seq to chain;

ALTER TABLE CSR.ALERT_TEMPLATE_BODY DROP COLUMN ALERT_TYPE_ID;
ALTER TABLE CSR.ALERT_TEMPLATE DROP COLUMN ALERT_TYPE_ID;
ALTER TABLE CSR.ALERT_BATCH_RUN DROP COLUMN ALERT_TYPE_ID;

/*
-- clean everything up

DROP TABLE XX_ALERT_BATCH_RUN PURGE;
DROP TABLE XX_ALERT_TEMPLATE_BODY PURGE;
DROP TABLE XX_ALERT_TEMPLATE PURGE
DROP TABLE XX_CUSTOMER_ALERT_TYPE PURGE;
*/


@..\alert_pkg
@..\schema_pkg
@..\delegation_pkg
@..\csrimp\imp_pkg

@..\csr_data_body
@..\alert_body
@..\delegation_body
@..\sheet_body
@..\issue_body
@..\pending_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\setup_body
@..\actions\periodic_alert_body

-- also changed:
-- utils\enableBatchedDelegationStateChangeAlert.sql
-- utils\enableDocLib.sql
-- utils\enableEnquiries.sql
-- utils\enableEthics.sql
-- utils\enablePending.sql
-- utils\enableSheets2.sql

@update_tail
