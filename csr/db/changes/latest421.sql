-- Please update version.sql too -- this keeps clean builds in sync
define version=421
@update_header

-- 
-- TABLE: SCENARIO 
--

CREATE TABLE SCENARIO(
    APP_SID         NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION     VARCHAR2(1000)    NOT NULL,
    START_DTM       DATE              NOT NULL,
    END_DTM         DATE,
    INTERVAL        VARCHAR2(1)       NOT NULL,
    CONSTRAINT CK_SCENARIO_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND (END_DTM IS NULL OR (END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM))),
    CONSTRAINT CK_SCENARIO_INTERVAL CHECK (INTERVAL IN ('m','q','h','y')),
    CONSTRAINT PK_SCENARIO PRIMARY KEY (APP_SID, SCENARIO_SID)
)
;



-- 
-- TABLE: SCENARIO_IND 
--

CREATE TABLE SCENARIO_IND(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID    NUMBER(10, 0)    NOT NULL,
    IND_SID         NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SCENARIO_IND PRIMARY KEY (APP_SID, SCENARIO_SID, IND_SID)
)
;



-- 
-- TABLE: SCENARIO_REGION 
--

CREATE TABLE SCENARIO_REGION(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID    NUMBER(10, 0)    NOT NULL,
    REGION_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SCENARIO_REGION PRIMARY KEY (APP_SID, SCENARIO_SID, REGION_SID)
)
;



-- 
-- TABLE: SCENARIO_RULE 
--

CREATE TABLE SCENARIO_RULE(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID             NUMBER(10, 0)     NOT NULL,
    RULE_ID                  NUMBER(10, 0)     NOT NULL,
    DESCRIPTION              VARCHAR2(1000)    NOT NULL,
    RULE_TYPE                NUMBER(1, 0)      NOT NULL,
    AMOUNT                   NUMBER(24, 10)    NOT NULL,
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    START_DTM                DATE              NOT NULL,
    END_DTM                  DATE              NOT NULL,
    CONSTRAINT CK_SCENARIO_RULE_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND (END_DTM IS NULL OR (END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM))),
    CONSTRAINT PK_SCENARIO_RULE PRIMARY KEY (APP_SID, SCENARIO_SID, RULE_ID)
)
;



-- 
-- TABLE: SCENARIO_RULE_IND 
--

CREATE TABLE SCENARIO_RULE_IND(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID    NUMBER(10, 0)    NOT NULL,
    RULE_ID         NUMBER(10, 0)    NOT NULL,
    IND_SID         NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SCENARIO_RULE_IND PRIMARY KEY (APP_SID, SCENARIO_SID, RULE_ID, IND_SID)
)
;



-- 
-- TABLE: SCENARIO_RULE_REGION 
--

CREATE TABLE SCENARIO_RULE_REGION(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID    NUMBER(10, 0)    NOT NULL,
    RULE_ID         NUMBER(10, 0)    NOT NULL,
    REGION_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SCENARIO_RULE_REGION PRIMARY KEY (APP_SID, SCENARIO_SID, RULE_ID, REGION_SID)
)
;

-- 
-- TABLE: SCENARIO 
--

ALTER TABLE SCENARIO ADD CONSTRAINT FK_SCENARIO_CUSTOMER 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


-- 
-- TABLE: SCENARIO_IND 
--

ALTER TABLE SCENARIO_IND ADD CONSTRAINT RefSCENARIO1485 
    FOREIGN KEY (APP_SID, SCENARIO_SID)
    REFERENCES SCENARIO(APP_SID, SCENARIO_SID)
;

ALTER TABLE SCENARIO_IND ADD CONSTRAINT FK_SCENARIO_IND_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;


-- 
-- TABLE: SCENARIO_REGION 
--

ALTER TABLE SCENARIO_REGION ADD CONSTRAINT RefSCENARIO1487 
    FOREIGN KEY (APP_SID, SCENARIO_SID)
    REFERENCES SCENARIO(APP_SID, SCENARIO_SID)
;

ALTER TABLE SCENARIO_REGION ADD CONSTRAINT FK_SCENARIO_REGION_REGION 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;


-- 
-- TABLE: SCENARIO_RULE 
--

ALTER TABLE SCENARIO_RULE ADD CONSTRAINT FK_SCENARIO_RULE_MEAS_CONV 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE SCENARIO_RULE ADD CONSTRAINT FK_SCENARIO_RULE_SCENARIO 
    FOREIGN KEY (APP_SID, SCENARIO_SID)
    REFERENCES SCENARIO(APP_SID, SCENARIO_SID)
;


-- 
-- TABLE: SCENARIO_RULE_IND 
--

ALTER TABLE SCENARIO_RULE_IND ADD CONSTRAINT FK_SCENARIO_RULE_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE SCENARIO_RULE_IND ADD CONSTRAINT FK_SCENARIO_RULE_IND_SCENARIO 
    FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID)
    REFERENCES SCENARIO_RULE(APP_SID, SCENARIO_SID, RULE_ID)
;


-- 
-- TABLE: SCENARIO_RULE_REGION 
--

ALTER TABLE SCENARIO_RULE_REGION ADD CONSTRAINT FK_SCENARIO_RULE_REG_REG 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE SCENARIO_RULE_REGION ADD CONSTRAINT FK_SCENARIO_RULE_REG_SCENARIO 
    FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID)
    REFERENCES SCENARIO_RULE(APP_SID, SCENARIO_SID, RULE_ID)
;


CREATE GLOBAL TEMPORARY TABLE TEMP_IND_TREE
(
    APP_SID                       NUMBER(10, 0),
    IND_SID                       NUMBER(10, 0),
    PARENT_SID                    NUMBER(10, 0),
    DESCRIPTION                   VARCHAR2(1023),
    IND_TYPE                      NUMBER(10, 0),
    MEASURE_SID                   NUMBER(10, 0),
    ACTIVE                        NUMBER(10, 0)
) ON COMMIT DELETE ROWS;

CREATE OR REPLACE VIEW v$calc_dependency (app_sid, calc_ind_sid, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, cd.dep_type, cd.ind_sid, i.ind_type, ci.calc_start_dtm_adjustment
	  FROM calc_dependency cd, ind i, ind ci
	 WHERE cd.app_sid = ci.app_sid AND cd.calc_ind_sid = ci.ind_sid
	   AND cd.app_sid = i.app_sid AND cd.ind_sid = i.ind_sid
	   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND cd.dep_type = 1--csr_data_pkg.DEP_ON_INDICATOR
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, cd.dep_type, i.ind_sid, i.ind_type, ci.calc_start_dtm_adjustment
	  FROM calc_dependency cd, ind i, ind ci
	 WHERE cd.app_sid = ci.app_sid AND cd.calc_ind_sid = ci.ind_sid
	   AND cd.app_sid = i.app_sid AND cd.ind_sid = i.parent_sid
	   AND cd.dep_type = 2 --csr_data_pkg.DEP_ON_CHILDREN
	   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND i.active = 1 -- active child inds only
;

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SCENARIO',
        policy_name     => 'SCENARIO_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SCENARIO_IND',
        policy_name     => 'SCENARIO_IND_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SCENARIO_REGION',
        policy_name     => 'SCENARIO_REGION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SCENARIO_RULE',
        policy_name     => 'SCENARIO_RULE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SCENARIO_RULE_IND',
        policy_name     => 'SCENARIO_RULE_IND_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SCENARIO_RULE_REGION',
        policy_name     => 'SCENARIO_RULE_REGION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

DECLARE
	v_class_id security_pkg.T_CLASS_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY', 'ACT'), NULL, 'CSRScenario', 'csr.scenario_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

@..\scenario_pkg
@..\scenario_body
@..\region_body

grant execute on scenario_pkg to web_user;
grant execute on scenario_pkg to security;

@update_tail
