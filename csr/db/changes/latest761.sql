-- Please update version.sql too -- this keeps clean builds in sync
define version=761
@update_header

BEGIN
	FOR r IN (
		select uc.table_name, uc.constraint_name
		  from all_constraints uc 
			join all_constraints ucr on uc.r_owner = ucr.owner and uc.r_constraint_name = ucr.constraint_name 
		  where uc.owner = 'CSR' and uc.table_name IN ('DELEG_PLAN_DELEG_REGION', 'DELEG_PLAN_DELEG_DELEG')
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.'||r.table_name||' drop constraint '||r.constraint_name;
	END LOOP;
END;
/

-- copy data to new tables and drop later
ALTER TABLE csr.DELEG_PLAN_DELEG_REGION RENAME TO XX_DELEG_PLAN_DELEG_REGION;
ALTER TABLE csr.DELEG_PLAN_DELEG RENAME TO XX_DELEG_PLAN_DELEG;



CREATE SEQUENCE csr.DELEG_PLAN_COL_DELEG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.DELEG_PLAN_COL_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.DELEG_PLAN_COL_SURVEY_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;


CREATE TABLE csr.DELEG_PLAN_COL(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_PLAN_SID              NUMBER(10, 0)    NOT NULL,
    DELEG_PLAN_COL_ID           NUMBER(10, 0)    NOT NULL,
    IS_HIDDEN                   NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    DELEG_PLAN_COL_DELEG_ID     NUMBER(10, 0),
    DELEG_PLAN_COL_SURVEY_ID    NUMBER(10, 0),
    CONSTRAINT CHK_DELEG_PLAN_ENTITY_HIDDEN CHECK (IS_HIDDEN IN (0,1)),
    CONSTRAINT PK_DELEG_PLAN_COL PRIMARY KEY (APP_SID, DELEG_PLAN_COL_ID)
 );
 
 
 
CREATE TABLE csr.DELEG_PLAN_COL_DELEG(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_PLAN_COL_DELEG_ID    NUMBER(10, 0)    NOT NULL,
    DELEGATION_SID             NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DELEG_PLAN_COL_DELEG PRIMARY KEY (APP_SID, DELEG_PLAN_COL_DELEG_ID)
);


CREATE TABLE csr.DELEG_PLAN_COL_SURVEY(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_PLAN_COL_SURVEY_ID    NUMBER(10, 0)    NOT NULL,
    SURVEY_SID                  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DELEG_PLAN_COL_SURVEY PRIMARY KEY (APP_SID, DELEG_PLAN_COL_SURVEY_ID, SURVEY_SID),
    CONSTRAINT UK_DELEG_PLAN_COL_SURVEY  UNIQUE (APP_SID, DELEG_PLAN_COL_SURVEY_ID)
);


CREATE TABLE csr.DELEG_PLAN_DELEG_REGION(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_PLAN_COL_DELEG_ID    NUMBER(10, 0)    NOT NULL,
    REGION_SID                 NUMBER(10, 0)    NOT NULL,
    MAPS_TO_ROOT_DELEG_SID     NUMBER(10, 0),
    HAS_MANUAL_AMENDS          NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    PENDING_DELETION		   NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_DELEG_PLAN_DR_AMENDS CHECK (HAS_MANUAL_AMENDS IN (0,1)),
    CONSTRAINT CHK_DELEG_PLAN_DR_PENDING_DEL CHECK (PENDING_DELETION IN (0,1)),
    CONSTRAINT PK_DELEG_PLAN_DELEG_REGION PRIMARY KEY (APP_SID, DELEG_PLAN_COL_DELEG_ID, REGION_SID)
);


CREATE TABLE csr.DELEG_PLAN_SURVEY_REGION(
    APP_SID                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_PLAN_COL_SURVEY_ID      NUMBER(10, 0)    NOT NULL,
    REGION_SID                    NUMBER(10, 0)    NOT NULL,
    SURVEY_SID                    NUMBER(10, 0)    NOT NULL,
    MAPS_TO_SURVEY_RESPONSE_ID    NUMBER(10, 0),
    HAS_MANUAL_AMENDS             NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    PENDING_DELETION		   	  NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_DELEG_PLAN_SR_AMENDS CHECK (HAS_MANUAL_AMENDS IN (0,1)),
    CONSTRAINT CHK_DELEG_PLAN_SR_PENDING_DEL CHECK (PENDING_DELETION IN (0,1)),
    CONSTRAINT PK_DELEG_PLAN_SURVEY_REGION PRIMARY KEY (APP_SID, DELEG_PLAN_COL_SURVEY_ID, REGION_SID, SURVEY_SID)
);

ALTER TABLE csr.DELEG_PLAN_COL ADD CONSTRAINT FK_CUS_DELEG_PLAN_COL 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID);
 
ALTER TABLE csr.DELEG_PLAN_COL ADD CONSTRAINT FK_DELEG_PLAN_DLG_PLN_COL 
     FOREIGN KEY (APP_SID, DELEG_PLAN_SID)
     REFERENCES DELEG_PLAN(APP_SID, DELEG_PLAN_SID);
 
ALTER TABLE csr.DELEG_PLAN_COL ADD CONSTRAINT FK_DLG_PLN_COL_DLG_DPC 
    FOREIGN KEY (APP_SID, DELEG_PLAN_COL_DELEG_ID)
    REFERENCES DELEG_PLAN_COL_DELEG(APP_SID, DELEG_PLAN_COL_DELEG_ID) ON DELETE CASCADE;
 
ALTER TABLE csr.DELEG_PLAN_COL ADD CONSTRAINT FK_DLG_PLN_COL_SRV_DPC 
    FOREIGN KEY (APP_SID, DELEG_PLAN_COL_SURVEY_ID)
    REFERENCES DELEG_PLAN_COL_SURVEY(APP_SID, DELEG_PLAN_COL_SURVEY_ID) ON DELETE CASCADE;


ALTER TABLE csr.DELEG_PLAN_COL_DELEG ADD CONSTRAINT FK_CUS_DLG_PLN_COL_DLG
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID);

ALTER TABLE csr.DELEG_PLAN_COL_DELEG ADD CONSTRAINT FK_MSTR_DLG_DLG_PLN_COL_DLG 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES MASTER_DELEG(APP_SID, DELEGATION_SID);


ALTER TABLE csr.DELEG_PLAN_COL_SURVEY ADD CONSTRAINT FK_CUS_DLG_PLN_COL_SRV
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID);

ALTER TABLE csr.DELEG_PLAN_COL_SURVEY ADD CONSTRAINT FK_QUICK_SRV_DLG_PLN_COL_SRV 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES QUICK_SURVEY(APP_SID, SURVEY_SID);


ALTER TABLE csr.DELEG_PLAN_DELEG_REGION ADD CONSTRAINT FK_DELEG_DLG_PLN_DLG_REG 
    FOREIGN KEY (APP_SID, MAPS_TO_ROOT_DELEG_SID)
     REFERENCES DELEGATION(APP_SID, DELEGATION_SID);
 
ALTER TABLE csr.DELEG_PLAN_DELEG_REGION ADD CONSTRAINT FK_DLG_PL_COL_DLG_DPDR 
    FOREIGN KEY (APP_SID, DELEG_PLAN_COL_DELEG_ID)
    REFERENCES DELEG_PLAN_COL_DELEG(APP_SID, DELEG_PLAN_COL_DELEG_ID);

ALTER TABLE csr.DELEG_PLAN_DELEG_REGION ADD CONSTRAINT FK_REG_DLG_PLAN_DLG_REG 
     FOREIGN KEY (APP_SID, REGION_SID)
     REFERENCES REGION(APP_SID, REGION_SID);
 
 
ALTER TABLE csr.DELEG_PLAN_SURVEY_REGION ADD CONSTRAINT FK_DLG_PL_COL_SRV_DPSR 
    FOREIGN KEY (APP_SID, DELEG_PLAN_COL_SURVEY_ID, SURVEY_SID)
    REFERENCES DELEG_PLAN_COL_SURVEY(APP_SID, DELEG_PLAN_COL_SURVEY_ID, SURVEY_SID);

ALTER TABLE csr.DELEG_PLAN_SURVEY_REGION ADD CONSTRAINT FK_QSR_DLG_PLN_SRV_REG 
    FOREIGN KEY (APP_SID, SURVEY_SID, MAPS_TO_SURVEY_RESPONSE_ID)
    REFERENCES QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_SID, SURVEY_RESPONSE_ID);

ALTER TABLE csr.DELEG_PLAN_SURVEY_REGION ADD CONSTRAINT FK_REG_DLG_PLAN_SRV_REG 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID);


DECLARE
	v_deleg_plan_col_id			NUMBER(10);
	v_deleg_plan_col_deleg_Id	NUMBER(10);
BEGIN
	FOR r IN (
		SELECT app_sid,deleg_plan_sid, delegation_sid, is_hidden
		  FROM csr.xx_deleg_plan_deleg
	)
	LOOP
		INSERT INTO csr.deleg_plan_col (app_sid, deleg_plan_col_id, deleg_plan_sid, is_hidden)
			VALUES (r.app_sid, deleg_plan_col_id_seq.nextval, r.deleg_plan_sid, r.is_hidden)
			RETURNING deleg_plan_col_id INTO v_deleg_plan_col_id;
		INSERT INTO csr.deleg_plan_col_deleg (app_sid, deleg_plan_col_deleg_Id, delegation_sid)
			VALUES (r.app_sid, deleg_plan_col_deleg_Id_seq.nextval, r.delegation_sid)
			RETURNING deleg_plan_col_deleg_Id INTO v_deleg_plan_col_deleg_Id;
		UPDATE csr.deleg_plan_col
		    SET deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_Id
		  WHERE deleg_plan_col_id = v_deleg_plan_col_id;
			
		INSERT INTO csr.deleg_plan_deleg_region (app_sid, deleg_plan_col_deleg_Id, region_sid,	
			maps_to_root_deleg_sid)
			SELECT app_sid, v_deleg_plan_col_deleg_Id, region_sid, maps_to_deleg_sid
			  FROM csr.XX_DELEG_PLAN_DELEG_REGION
			 WHERE deleg_plan_sid = r.deleg_plan_sid
			   AND delegation_sid = r.delegation_sid;
	END LOOP;
END;
/

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'DELEG_PLAN',
		'DELEG_PLAN_REGION',
		'DELEG_PLAN_ROLE',
		'DELEG_PLAN_COL',
		'DELEG_PLAN_COL_DELEG',
		'DELEG_PLAN_COL_SURVEY',
		'DELEG_PLAN_DELEG_REGION',
		'DELEG_PLAN_SURVEY_REGION',
		'MASTER_DELEG'
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

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		dpcd.delegation_sid, dpdr.region_sid, dpdr.maps_to_root_deleg_sid, 
		dpdr.has_manual_amends, dpdr.pending_deletion
	  FROM deleg_plan_deleg_region dpdr
		JOIN deleg_plan_col_deleg dpcd ON dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_SURVEY_REGION AS
	SELECT dpc.deleg_plan_sid, dpsr.deleg_plan_col_survey_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		dpcs.survey_sid, dpsr.region_sid, dpsr.maps_to_survey_response_id, 
		dpsr.has_manual_amends, dpsr.pending_deletion
	  FROM deleg_plan_survey_region dpsr
		JOIN deleg_plan_col_survey dpcs ON dpsr.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN deleg_plan_col dpc ON dpcs.deleg_plan_col_survey_id = dpc.deleg_plan_col_survey_id;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_COL AS
	SELECT deleg_plan_col_id, deleg_plan_sid, d.name label, dpc.is_hidden, 'Delegation' type
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN delegation d ON dpcd.delegation_sid = d.delegation_sid
	 UNION
	SELECT deleg_plan_col_id, deleg_plan_sid, qs.label, dpc.is_hidden, 'Survey' type
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_survey dpcs ON dpc.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN quick_survey qs ON dpcs.survey_sid = qs.survey_sid
	;
	

--DROP TABLE XX_DELEG_PLAN_DELEG_REGION;
--DROP TABLE XX_DELEG_PLAN_DELEG;

@..\delegation_pkg
@..\deleg_plan_pkg

@..\delegation_body
@..\deleg_plan_body


@update_tail
