-- Please update version.sql too -- this keeps clean builds in sync
define version=30
@update_header

CREATE SEQUENCE IND_TEMPLATE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE TABLE IND_TEMPLATE(
    IND_TEMPLATE_ID        NUMBER(10, 0)     NOT NULL,
    NAME                   VARCHAR2(255)     NOT NULL,
    DESCRIPTION            VARCHAR2(1023)    NOT NULL,
    APP_SID                NUMBER(10, 0)     NOT NULL,
    TOLERANCE_TYPE         NUMBER(2, 0)      DEFAULT 0 NOT NULL,
    PCT_UPPER_TOLERANCE    NUMBER(10, 4)     DEFAULT 1 NOT NULL,
    PCT_LOWER_TOLERANCE    NUMBER(10, 4)     DEFAULT 1 NOT NULL,
    MEASURE_SID            NUMBER(10, 0),
    SCALE                  NUMBER(10, 0)     DEFAULT 0,
    FORMAT_MASK            VARCHAR2(255)     DEFAULT '#,##0',
    TARGET_DIRECTION       NUMBER(10, 0)     DEFAULT 1,
    INFO_XML               SYS.XMLType,
    DIVISIBLE              NUMBER(10, 0)     DEFAULT 1,
    AGGREGATE              VARCHAR2(24)      DEFAULT 'SUM',
    CONSTRAINT PK1_1 PRIMARY KEY (IND_TEMPLATE_ID)
)
;

CREATE TABLE ROOT_IND_TEMPLATE_INSTANCE(
    APP_SID                 NUMBER(10, 0)    NOT NULL,
    FROM_IND_TEMPLATE_ID    NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK72 PRIMARY KEY (APP_SID, FROM_IND_TEMPLATE_ID)
)
;

CREATE TABLE PROJECT_IND_TEMPLATE(
    PROJECT_SID          NUMBER(10, 0)    NOT NULL,
    IND_TEMPLATE_ID      NUMBER(10, 0)    NOT NULL,
    POS                  NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    IS_MANDATORY         NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    UPDATE_PER_PERIOD    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK_PROJECT_IND_TEMPLATE PRIMARY KEY (PROJECT_SID, IND_TEMPLATE_ID)
)
;

CREATE TABLE PROJECT_IND_TEMPLATE_INSTANCE(
    PROJECT_SID             NUMBER(10, 0)    NOT NULL,
    FROM_IND_TEMPLATE_ID    NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK73 PRIMARY KEY (PROJECT_SID, FROM_IND_TEMPLATE_ID)
)
;

CREATE TABLE TASK_IND_TEMPLATE_INSTANCE(
    TASK_SID                NUMBER(10, 0)    NOT NULL,
    FROM_IND_TEMPLATE_ID    NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TASK_IND_TEMPLATE_INSTANCE PRIMARY KEY (TASK_SID, FROM_IND_TEMPLATE_ID)
)
;

ALTER TABLE PROJECT_IND_TEMPLATE ADD CONSTRAINT RefIND_TEMPLATE87 
    FOREIGN KEY (IND_TEMPLATE_ID)
    REFERENCES IND_TEMPLATE(IND_TEMPLATE_ID)
;

ALTER TABLE PROJECT_IND_TEMPLATE ADD CONSTRAINT RefPROJECT88 
    FOREIGN KEY (PROJECT_SID)
    REFERENCES PROJECT(PROJECT_SID)
;

ALTER TABLE PROJECT_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefPROJECT94 
    FOREIGN KEY (PROJECT_SID)
    REFERENCES PROJECT(PROJECT_SID)
;

ALTER TABLE PROJECT_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefIND_TEMPLATE95 
    FOREIGN KEY (FROM_IND_TEMPLATE_ID)
    REFERENCES IND_TEMPLATE(IND_TEMPLATE_ID)
;

ALTER TABLE ROOT_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefIND_TEMPLATE96 
    FOREIGN KEY (FROM_IND_TEMPLATE_ID)
    REFERENCES IND_TEMPLATE(IND_TEMPLATE_ID)
;

ALTER TABLE TASK_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefIND_TEMPLATE89 
    FOREIGN KEY (FROM_IND_TEMPLATE_ID)
    REFERENCES IND_TEMPLATE(IND_TEMPLATE_ID)
;

ALTER TABLE TASK_IND_TEMPLATE_INSTANCE ADD CONSTRAINT RefTASK90 
    FOREIGN KEY (TASK_SID)
    REFERENCES TASK(TASK_SID)
;

-- acton_progress
DECLARE
	v_measure_sid 		security_pkg.T_SID_ID;
	v_ind_template_id 	ind_template.ind_template_id%TYPE;
	v_pos				NUMBER;
BEGIN
	FOR r IN (
        SELECT DISTINCT c.app_sid
          FROM csr.customer c, project p 
         WHERE c.app_sid = p.app_sid
    ) LOOP
    	SELECT measure_sid 
    	  INTO v_measure_sid
    	  FROM csr.measure
	 	 WHERE app_sid = r.app_sid
	 	   AND LOWER(name) = 'action_progress';
	 	--
	 	INSERT INTO ind_template
	 		(ind_template_id, name, description, app_sid, 
	 		 tolerance_type, pct_upper_tolerance, pct_lower_tolerance, 
	 		 measure_sid, scale, format_mask, target_direction, info_xml, 
	 		 divisible, aggregate)
	 	  VALUES (ind_template_id_seq.NEXTVAL, 'action_progress', 'Progress', r.app_sid,
	 	  		  0, 1, 1, v_measure_sid, NULL, NULL, 1, NULL, 0, 'AVERAGE');
	 	--
	 	-- We're not going to put this progress template into the project_ind_template 
	 	-- table as it's a special case and is implicitly used by all projects. 
	 	-- Furthermore we don't want the progress indicator appearing in any list 
	 	-- of indicators the user is collecting for their project and the 
	 	-- project_ind_template table will likely be used for this purpose.
    END LOOP;
END;
/

COMMIT;

@update_tail
