-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.CALC_JOB_STAT (
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALC_JOB_ID               NUMBER(10, 0)    NOT NULL,
    SCENARIO_RUN_SID          NUMBER(10, 0),
    VERSION					  NUMBER(10, 0),
    START_DTM                 DATE             NOT NULL,
    END_DTM                   DATE             NOT NULL,
    CALC_JOB_INDS			  NUMBER(10, 0)	   NOT NULL,
    ATTEMPTS                  NUMBER(10, 0)    NOT NULL,
    CALC_JOB_TYPE             NUMBER(10, 0)    NOT NULL,
    PRIORITY                  NUMBER(10, 0)    NOT NULL,
    FULL_RECOMPUTE            NUMBER(1, 0)     NOT NULL,       
    CREATED_DTM				  DATE			   NOT NULL,
    RAN_DTM					  DATE			   NOT NULL,
    RAN_ON					  VARCHAR2(256)	   NOT NULL,
    SCENARIO_FILE_SIZE		  NUMBER(20)	   NOT NULL,
    HEAP_ALLOCATED			  NUMBER(20)	   NOT NULL,
    TOTAL_TIME				  NUMBER(10, 2)	   NOT NULL,
    FETCH_TIME				  NUMBER(10, 2)	   NOT NULL,
    CALC_TIME				  NUMBER(10, 2)	   NOT NULL,
    LOAD_FILE_TIME			  NUMBER(10, 2)	   NOT NULL,
    LOAD_METADATA_TIME		  NUMBER(10, 2)	   NOT NULL,
    LOAD_VALUES_TIME	  	  NUMBER(10, 2)	   NOT NULL,
    LOAD_AGGREGATES_TIME	  NUMBER(10, 2)	   NOT NULL,
    SCENARIO_RULES_TIME		  NUMBER(10, 2)	   NOT NULL,
    SAVE_FILE_TIME			  NUMBER(10, 2)	   NOT NULL,    
    TOTAL_VALUES			  NUMBER(20)	   NOT NULL,    
    AGGREGATE_VALUES		  NUMBER(20)	   NOT NULL,
    CALC_VALUES				  NUMBER(20)	   NOT NULL,
    NORMAL_VALUES		  	  NUMBER(20)	   NOT NULL,
    EXTERNAL_AGGREGATE_VALUES NUMBER(20)	   NOT NULL,
    CALCS_RUN				  NUMBER(10)	   NOT NULL,
	INDS					  NUMBER(10)	   NOT NULL,
	REGIONS					  NUMBER(10)	   NOT NULL,
    CONSTRAINT CK_CALC_JOB_STAT_DATES CHECK(END_DTM > START_DTM AND TRUNC(END_DTM,'DD') = END_DTM AND TRUNC(START_DTM,'DD') = START_DTM),
    CONSTRAINT CK_CALC_JOB_ST_FULL_RECOMPUTE CHECK (FULL_RECOMPUTE IN (0,1)),
    CONSTRAINT PK_CALC_JOB_STAT PRIMARY KEY (APP_SID, CALC_JOB_ID)
)
;

CREATE TABLE CSR.CALC_JOB_FETCH_STAT (
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALC_JOB_ID               NUMBER(10, 0)    NOT NULL,
    FETCH_SP				  VARCHAR2(256),
    FETCH_TIME				  NUMBER(10, 2)	   NOT NULL
);

-- Alter tables

ALTER TABLE CSR.CALC_JOB_STAT ADD CONSTRAINT FK_CALC_JOB_STAT_SCN_RUN
	FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
	REFERENCES CSR.SCENARIO_RUN (APP_SID, SCENARIO_RUN_SID);

ALTER TABLE CSR.CALC_JOB_FETCH_STAT ADD CONSTRAINT FK_CALC_JOB_FTCH_STAT_CALC_JB
	FOREIGN KEY (APP_SID, CALC_JOB_ID)
	REFERENCES CSR.CALC_JOB_STAT (APP_SID, CALC_JOB_ID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
