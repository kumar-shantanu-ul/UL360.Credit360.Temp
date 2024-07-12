-- Please update version.sql too -- this keeps clean builds in sync
define version=1304
@update_header

CREATE SEQUENCE CHAIN.COMPANY_TYPE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE CT.SUPPLIER MODIFY APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP');

ALTER TABLE CHAIN.SECTOR ADD (
	IS_OTHER            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CHECK (IS_OTHER IN (0, 1))
);

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (
	USE_TYPE_CAPABILITIES            NUMBER(1, 0)      DEFAULT 0 NOT NULL,
	CHECK (USE_TYPE_CAPABILITIES IN (0, 1))
);

ALTER TABLE CHAIN.CAPABILITY ADD (
	IS_SUPPLIER           NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CHECK (IS_SUPPLIER IN (0, 1))
);

BEGIN
	UPDATE CHAIN.CAPABILITY SET IS_SUPPLIER = 1 WHERE CAPABILITY_TYPE_ID = 2;
	UPDATE CHAIN.CAPABILITY SET IS_SUPPLIER = 1 WHERE CAPABILITY_NAME IN ('Approve questionnaire', 'Change supplier follower', 'Send questionnaire invitation', 'Suppliers');
END;
/

ALTER TABLE CHAIN.CAPABILITY ADD (CONSTRAINT CHK_CAPABILITY_IS_SUPPLIER CHECK (CAPABILITY_TYPE_ID = 0 OR (CAPABILITY_TYPE_ID = 1 AND IS_SUPPLIER = 0) OR (CAPABILITY_TYPE_ID = 2 AND IS_SUPPLIER = 1)));

ALTER TABLE CHAIN.COMPANY ADD (COMPANY_TYPE_ID NUMBER(10, 0));

ALTER TABLE CHAIN.GROUP_CAPABILITY ADD (
	COMPANY_GROUP_TYPE_ID NUMBER(10, 0),
	PERMISSION_SET NUMBER(10, 0) DEFAULT 0 NOT NULL
);


CREATE TABLE CHAIN.COMPANY_GROUP(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID              NUMBER(10, 0)    NOT NULL,
    COMPANY_GROUP_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    GROUP_SID                NUMBER(10, 0),
    CONSTRAINT PK_COMPANY_GROUP PRIMARY KEY (APP_SID, COMPANY_SID, COMPANY_GROUP_TYPE_ID)
)
;

CREATE TABLE CHAIN.COMPANY_GROUP_TYPE(
    COMPANY_GROUP_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    NAME                     VARCHAR2(100)    NOT NULL,
    IS_GLOBAL                NUMBER(1, 0)     NOT NULL,
    CHECK (IS_GLOBAL IN (0, 1)),
    CONSTRAINT PK_COMPANY_GROUP_TYPE PRIMARY KEY (COMPANY_GROUP_TYPE_ID)
)
;

CREATE TABLE CHAIN.COMPANY_TYPE(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_TYPE_ID             NUMBER(10, 0)    NOT NULL,
    LOOKUP_KEY          		VARCHAR2(100)    NOT NULL,
    SINGULAR                    VARCHAR2(100)    NOT NULL,
    PLURAL                      VARCHAR2(100)    NOT NULL,
    ALLOW_LOWER_CASE            NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    IS_DEFAULT                  NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    IS_TOP_COMPANY              NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    POSITION		            NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CHECK (ALLOW_LOWER_CASE IN (0, 1)),
    CHECK (IS_TOP_COMPANY IN (0, 1)),
    CHECK (IS_DEFAULT IN (0, 1)),
    CHECK (LOOKUP_KEY = UPPER(TRIM(LOOKUP_KEY))),
    CONSTRAINT PK_COMPANY_TYPE PRIMARY KEY (APP_SID, COMPANY_TYPE_ID)
)
;

CREATE TABLE CHAIN.COMPANY_TYPE_CAPABILITY(
    APP_SID                           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_TYPE_ID                   NUMBER(10, 0)    NOT NULL,
    RELATED_COMPANY_TYPE_ID           NUMBER(10, 0),
    COMPANY_GROUP_TYPE_ID             NUMBER(10, 0)    NOT NULL,
    CAPABILITY_ID                     NUMBER(10, 0)    NOT NULL,
    INHERITED_FROM_COMPANY_TYPE_ID    NUMBER(10, 0),
    PERMISSION_SET                    NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_CTC_INHERITABLE CHECK (INHERITED_FROM_COMPANY_TYPE_ID IS NULL OR (INHERITED_FROM_COMPANY_TYPE_ID IS NOT NULL AND RELATED_COMPANY_TYPE_ID IS NOT NULL))
)
;

CREATE TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_TYPE_ID            NUMBER(10, 0)    NOT NULL,
    RELATED_COMPANY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_COMPANY_TYPE_RELATIONSHIP PRIMARY KEY (APP_SID, COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
)
;

CREATE UNIQUE INDEX CHAIN.UNIQUE_GROUP_TYPE_NAME ON CHAIN.COMPANY_GROUP_TYPE(UPPER(TRIM(NAME)))
;

CREATE UNIQUE INDEX CHAIN.UC_DEFAULT_COMPANY_TYPE ON CHAIN.COMPANY_TYPE(APP_SID, CASE WHEN IS_DEFAULT = 1 THEN 1 ELSE COMPANY_TYPE_ID + 10 END)
;

CREATE UNIQUE INDEX CHAIN.UK_COMPANY_TYPE_LOOKUP_KEY ON CHAIN.COMPANY_TYPE(APP_SID, LOOKUP_KEY)
;

CREATE UNIQUE INDEX CHAIN.UK_CTC_UNIQUE_PERMISSION_SET ON CHAIN.COMPANY_TYPE_CAPABILITY(APP_SID, COMPANY_TYPE_ID, COMPANY_GROUP_TYPE_ID, CAPABILITY_ID, NVL2(RELATED_COMPANY_TYPE_ID, 'R'||RELATED_COMPANY_TYPE_ID, 'C'||COMPANY_TYPE_ID))
;


ALTER TABLE CHAIN.COMPANY ADD CONSTRAINT FK_COMPANY_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE ADD CONSTRAINT FK_COMPANY_TYPE_CO 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.COMPANY_GROUP ADD CONSTRAINT FK_CG_COMPANY 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE CHAIN.COMPANY_GROUP ADD CONSTRAINT FK_CG_COMPANY_GROUP_TYPE 
    FOREIGN KEY (COMPANY_GROUP_TYPE_ID)
    REFERENCES CHAIN.COMPANY_GROUP_TYPE(COMPANY_GROUP_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP ADD CONSTRAINT FK_CTR_COMPANY_TYPE_1 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP ADD CONSTRAINT FK_CTR_COMPANY_TYPE_2 
    FOREIGN KEY (APP_SID, RELATED_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_CAPABILITY 
    FOREIGN KEY (CAPABILITY_ID)
    REFERENCES CHAIN.CAPABILITY(CAPABILITY_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_COMPANY_GROUP_TYPE 
    FOREIGN KEY (COMPANY_GROUP_TYPE_ID)
    REFERENCES CHAIN.COMPANY_GROUP_TYPE(COMPANY_GROUP_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_CTR_INHERITED 
    FOREIGN KEY (APP_SID, INHERITED_FROM_COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY ADD CONSTRAINT FK_CTC_CTR_RELATIONSHIP 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
;



BEGIN
	UPDATE CHAIN.SECTOR
	   SET is_other = 1
	 WHERE LOWER(description) = 'other';
	
	INSERT INTO CHAIN.COMPANY_TYPE
	(APP_SID, COMPANY_TYPE_ID, LOOKUP_KEY, SINGULAR, PLURAL, IS_DEFAULT)
	SELECT app_sid, chain.company_type_id_seq.nextval, 'DEFAULT', 'Company', 'Companies', 1
	  FROM chain.customer_options
	 WHERE (app_sid, 1) NOT IN (SELECT app_sid, is_default FROM chain.company_type);

	UPDATE chain.company c
	   SET company_type_id = (
			SELECT company_type_id
			  FROM chain.company_type ct
			 WHERE c.app_sid = ct.app_sid
	   )
	 WHERE company_type_id IS NULL;

	INSERT INTO CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID, NAME, IS_GLOBAL) VALUES (1, 'Administrators', 0);
	INSERT INTO CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID, NAME, IS_GLOBAL) VALUES (2, 'Users', 0);
	INSERT INTO CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID, NAME, IS_GLOBAL) VALUES (3, 'Pending Users', 0);
	INSERT INTO CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID, NAME, IS_GLOBAL) VALUES (4, 'Chain Administrators', 1);
	INSERT INTO CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID, NAME, IS_GLOBAL) VALUES (5, 'Chain Users', 1);
	
	-- insert company groups
	INSERT INTO CHAIN.COMPANY_GROUP
	(APP_SID, COMPANY_SID, COMPANY_GROUP_TYPE_ID, GROUP_SID)
	SELECT c.app_sid, c.company_sid, cgt.company_group_type_id, so.sid_id
	  FROM security.securable_object so, chain.company c, chain.company_group_type cgt
	 WHERE so.parent_sid_id = c.company_sid
	   AND so.name = cgt.name
	   AND cgt.is_global = 0;

	-- insert global groups
	INSERT INTO CHAIN.COMPANY_GROUP
	(APP_SID, COMPANY_SID, COMPANY_GROUP_TYPE_ID, GROUP_SID)
	SELECT aso.sid_id, c.company_sid, cgt.company_group_type_id, gso.sid_id
	  FROM security.securable_object gso, chain.company_group_type cgt, security.securable_object gcso, security.securable_object aso, chain.company c
	 WHERE gso.name = cgt.name
	   AND cgt.is_global = 1
	   AND gcso.sid_id = gso.parent_sid_id
	   AND aso.sid_id = gcso.parent_sid_id
	   AND c.app_sid = aso.sid_id;

	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage chain capabilities', 0);
	
	UPDATE chain.group_capability gc
	   SET company_group_type_id = (
	   		SELECT company_group_type_id
	   		  FROM chain.company_group_type cgt
	   		 WHERE gc.company_group_name = cgt.name
	   );
	   
	UPDATE chain.group_capability gc
	   SET permission_set = (
	   		SELECT permission_set
	   		  FROM chain.group_capability_perm gcp
	   		 WHERE gcp.group_capability_id = gc.group_capability_id
	   )
	 WHERE group_capability_id IN (
	 	SELECT group_capability_id 
	 	  FROM chain.group_capability_perm
	 );
END;
/
   
ALTER TABLE CHAIN.COMPANY MODIFY (COMPANY_TYPE_ID NOT NULL);

ALTER TABLE CHAIN.GROUP_CAPABILITY MODIFY (COMPANY_GROUP_TYPE_ID NOT NULL);
ALTER TABLE CHAIN.GROUP_CAPABILITY DROP CONSTRAINT UNIQUE_GROUP_CAPABILITY DROP INDEX; 
ALTER TABLE CHAIN.GROUP_CAPABILITY ADD (CONSTRAINT UNIQUE_GROUP_CAPABILITY  UNIQUE (COMPANY_GROUP_TYPE_ID, CAPABILITY_ID));
ALTER TABLE CHAIN.GROUP_CAPABILITY DROP COLUMN COMPANY_GROUP_NAME;

CREATE OR REPLACE VIEW CHAIN.v$group_capability_permission AS
	SELECT gc.group_capability_id, cgt.name company_group_name, gc.capability_id, ps.permission_set
	  FROM group_capability gc, company_group_type cgt, (
			SELECT group_capability_id, 0 hide_group_capability, permission_set
			  FROM group_capability
			 WHERE group_capability_id NOT IN (
					SELECT group_capability_id
					  FROM group_capability_override
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
			UNION ALL
			SELECT group_capability_id, hide_group_capability, permission_set_override permission_set
			  FROM group_capability_override
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) ps
	 WHERE ps.hide_group_capability = 0
	   AND ps.group_capability_id = gc.group_capability_id
	   AND gc.company_group_type_id = cgt.company_group_type_id
;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_USER_GROUPS
(
	USER_SID					NUMBER(10) NOT NULL,
	COMPANY_SID					NUMBER(10) NOT NULL,
	GROUP_SID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_TT_USER_GROUPS PRIMARY KEY (USER_SID, COMPANY_SID, GROUP_SID)
)
ON COMMIT DELETE ROWS;

ALTER TABLE CHAIN.CAPABILITY DROP CONSTRAINT UC_CAP_NAME_TYPE;
ALTER TABLE CHAIN.CAPABILITY DROP COLUMN APP_SID;
ALTER TABLE CHAIN.CAPABILITY ADD CONSTRAINT UC_CAP_NAME_TYPE  UNIQUE (CAPABILITY_TYPE_ID, CAPABILITY_NAME);

DROP VIEW CHAIN.v$capability;
DROP TABLE CHAIN.GROUP_CAPABILITY_PERM;


-- create stub for grant
CREATE OR REPLACE PACKAGE CHAIN.type_capability_pkg IS END type_capability_pkg;
/
CREATE OR REPLACE PACKAGE BODY CHAIN.type_capability_pkg IS END type_capability_pkg;
/
CREATE OR REPLACE PACKAGE CHAIN.company_type_pkg IS END company_type_pkg;
/
CREATE OR REPLACE PACKAGE BODY CHAIN.company_type_pkg IS END company_type_pkg;
/

grant execute on chain.type_capability_pkg to web_user;
grant execute on chain.company_type_pkg to web_user;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'COMPANY_GROUP',
		'COMPANY_GROUP_TYPE',
		'COMPANY_TYPE',
		'COMPANY_TYPE_CAPABILITY',
		'COMPANY_TYPE_RELATIONSHIP'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 26)||'_POL';
					else
						v_name := SUBSTR(v_list(i), 1, 24)||'_POL_'||v_i;
					end if;
				    dbms_rls.add_policy(
				        object_schema   => 'CHAIN',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CHAIN',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.static );
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

@..\chain\chain_pkg
@..\chain\capability_pkg
@..\chain\company_type_pkg
@..\chain\company_pkg
@..\chain\helper_pkg
@..\chain\setup_pkg
@..\chain\type_capability_pkg

@..\chain\capability_body
@..\chain\company_type_body
@..\chain\company_body
@..\chain\helper_body
@..\chain\setup_body
@..\chain\type_capability_body

@..\ct\supplier_body

@update_tail
