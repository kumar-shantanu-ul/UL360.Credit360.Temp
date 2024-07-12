-- Please update version.sql too -- this keeps clean builds in sync
define version=2505
@update_header

ALTER TABLE CSR.EST_ERROR RENAME TO EST_ERROR_LEGACY;

CREATE SEQUENCE CSR.EST_ERROR_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE TABLE CSR.EST_ERROR(
    APP_SID            NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EST_ERROR_ID       NUMBER(10, 0)     NOT NULL,
    REGION_SID         NUMBER(10, 0),
    EST_ACCOUNT_SID    NUMBER(10, 0),
    PM_CUSTOMER_ID     VARCHAR2(256),
    PM_BUILDING_ID     VARCHAR2(256),
    PM_SPACE_ID        VARCHAR2(256),
    PM_METER_ID        VARCHAR2(256),
    ERROR_LEVEL        NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    ERROR_DTM          DATE              DEFAULT SYSDATE NOT NULL,
    ERROR_CODE         NUMBER(10, 0)     NOT NULL,
    ERROR_MESSAGE      VARCHAR2(4000)    NOT NULL,
    REQUEST_URL        VARCHAR2(1024),
    REQUEST_HEADER     VARCHAR2(4000),
    REQUEST_BODY       VARCHAR2(4000),
    RESPONSE           VARCHAR2(4000),
    CONSTRAINT PK_EST_ERROR PRIMARY KEY (APP_SID, EST_ERROR_ID)
)
;

ALTER TABLE CSR.EST_ERROR ADD CONSTRAINT FK_CUSTOMER_EST_ERROR 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

CREATE INDEX CSR.IX_CUSTOMER_EST_ERROR ON CSR.EST_ERROR (APP_SID);
CREATE INDEX CSR.IX_EST_ERROR_REGION ON CSR.EST_ERROR (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_EST_ERROR_ACCOUNT ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID);
CREATE INDEX CSR.IX_EST_ERROR_CUSTOMER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID);
CREATE INDEX CSR.IX_EST_ERROR_BUILDING ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID);
CREATE INDEX CSR.IX_EST_ERROR_SPACE ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID);
CREATE INDEX CSR.IX_EST_ERROR_METER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_METER_ID);
CREATE INDEX CSR.IX_EST_ERROR_SPACE_METER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID);


CREATE SEQUENCE CSR.EST_ACCOUNT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.EST_ACCOUNT_GLOBAL(
    EST_ACCOUNT_ID          NUMBER(10, 0)    NOT NULL,
    USER_NAME               VARCHAR2(256)    NOT NULL,
    PASSWORD                VARCHAR2(245)    NOT NULL,
    BASE_URL				VARCHAR2(256)	 NOT NULL,
    CONNECT_JOB_INTERVAL    NUMBER(10, 0),
    LAST_CONNECT_JOB_DTM    DATE,
    CONSTRAINT PK_EST_ACCOUNT_GLOBAL PRIMARY KEY (EST_ACCOUNT_ID)
)
;

CREATE UNIQUE INDEX CSR.UK_EST_ACCOUNT_GLOBAL_UNAME ON CSR.EST_ACCOUNT_GLOBAL(USER_NAME)
;

CREATE TABLE CSR.EST_CUSTOMER_GLOBAL(
    PM_CUSTOMER_ID    VARCHAR2(256)    NOT NULL,
    ORG_NAME          VARCHAR2(256)    NOT NULL,
    EMAIL             VARCHAR2(256),
    CONSTRAINT PK_EST_CUSTOMER_GLOBAL PRIMARY KEY (PM_CUSTOMER_ID)
)
;

CREATE UNIQUE INDEX CSR.UK_EST_CUSTOMER_SID ON CSR.EST_CUSTOMER(APP_SID, EST_ACCOUNT_SID, EST_CUSTOMER_SID)
;

ALTER TABLE CSR.EST_ACCOUNT ADD (
	EST_ACCOUNT_ID		NUMBER(10),
	AUTO_MAP_CUSTOMER	NUMBER(1)	DEFAULT 0	NOT NULL,
	ALLOW_DELETE		NUMBER(1)	DEFAULT 0	NOT NULL,
	CHECK (AUTO_MAP_CUSTOMER IN (0,1)),
	CHECK (ALLOW_DELETE IN (0,1))
)
;

BEGIN
	-- Move account and customer data into new tables
	INSERT INTO csr.est_account_global (est_account_id, user_name, password, base_url)
		SELECT csr.est_account_id_seq.NEXTVAL, x.user_name, x.password, 'https://portfoliomanager.energystar.gov/ws/'
		  FROM (
		  	SELECT user_name, min(password) password
		  	  FROM csr.est_account
		  	 GROUP BY user_name
		  ) x
	;
	
	FOR r IN (
		SELECT user_name, est_account_id
		  FROM csr.est_account_global
	) LOOP
		UPDATE csr.est_account
		   SET est_account_id = r.est_account_id
		 WHERE user_name = r.user_name;
	END LOOP;
	
	INSERT INTO csr.est_customer_global (pm_customer_id, org_name, email)
		SELECT pm_customer_id, MIN(NVL(org_name, pm_customer_id)), MIN(email)
		  FROM csr.est_customer
		 GROUP BY pm_customer_id
	;
	
	DELETE FROM csr.est_customer
	 WHERE est_customer_sid IS NULL;
END;
/

ALTER TABLE CSR.EST_ACCOUNT MODIFY (
	EST_ACCOUNT_ID		NUMBER(10)		NOT NULL
)
;

CREATE UNIQUE INDEX CSR.UK_EST_ACCOUNT_SID ON CSR.EST_ACCOUNT(APP_SID, EST_ACCOUNT_ID)
;

ALTER TABLE CSR.EST_ACCOUNT ADD CONSTRAINT FK_EST_ACCOUNT_GLOBAL 
    FOREIGN KEY (EST_ACCOUNT_ID)
    REFERENCES CSR.EST_ACCOUNT_GLOBAL(EST_ACCOUNT_ID)
;

ALTER TABLE CSR.EST_CUSTOMER ADD CONSTRAINT FK_EST_CUST_GLOBAL_APP 
    FOREIGN KEY (PM_CUSTOMER_ID)
    REFERENCES CSR.EST_CUSTOMER_GLOBAL(PM_CUSTOMER_ID)
;

-- FK INDEXES
CREATE INDEX CSR.IX_EST_ACCOUNT_GLOBAL ON CSR.EST_ACCOUNT (EST_ACCOUNT_ID);
CREATE INDEX CSR.IX_EST_CUST_GLOBAL_APP ON CSR.EST_CUSTOMER (PM_CUSTOMER_ID);


ALTER TABLE CSR.EST_ACCOUNT DROP (USER_NAME, PASSWORD, CONNECT_JOB_INTERVAL, LAST_CONNECT_JOB_DTM);
ALTER TABLE CSR.EST_CUSTOMER DROP (ORG_NAME, EMAIL, USER_NAME);

ALTER TABLE CSR.EST_CUSTOMER MODIFY (
	EST_CUSTOMER_SID	NUMBER(10)	NOT NULL
);

CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.password, g.base_url,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;

CREATE OR REPLACE VIEW csr.v$est_customer AS
	SELECT a.app_sid, a.est_account_sid, a.pm_customer_id, a.est_customer_sid,
  		g.org_name, g.email
  	  FROM csr.est_customer a
  	  JOIN csr.est_customer_global g ON a.pm_customer_id = g.pm_customer_id
;

-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_nullable VARCHAR2(1);
begin	
	v_list := t_tabs(
		'EST_ERROR'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin					
					-- verify that the table has an app_sid column (dev helper)
					BEGIN
						SELECT nullable 
						  INTO v_nullable
						  FROM all_tab_columns 
						 WHERE owner = 'CSR' 
						   AND table_name = UPPER(v_list(i))
						   AND column_name = 'APP_SID';
					EXCEPTION
						WHEN no_data_found THEN
							raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					END;
					
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
				        policy_function => (CASE WHEN v_nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
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

@../property_pkg
@../energy_star_pkg;
@../energy_star_job_pkg;
@../energy_star_job_data_pkg;

@../property_body
@../energy_star_body;
@../energy_star_job_body;
@../energy_star_job_data_body;

@update_tail
