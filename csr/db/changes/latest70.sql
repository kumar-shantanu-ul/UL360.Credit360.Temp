-- Please update version.sql too -- this keeps clean builds in sync
define version=70
@update_header

VARIABLE version NUMBER
BEGIN :version := 70; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	


WHENEVER SQLERROR CONTINUE

alter table approval_step add (layout_type number(10) default 0 not null);
alter table approval_step add (max_values number(10) default 0 not null);

ALTER table aspen2.filecache modify cache_key varchar2(255);

-- 
-- TABLE: PENDING_ELEMENT_TYPE 
--

CREATE TABLE PENDING_ELEMENT_TYPE(
    ELEMENT_TYPE    NUMBER(10, 0)    NOT NULL,
    IS_NUMBER       NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    IS_STRING       NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    LABEL           VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK302 PRIMARY KEY (ELEMENT_TYPE)
)
;

BEGIN
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (1, 0, 0, 'Text line');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (2, 0, 0, 'Text block');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (3, 0, 0, 'Section');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (4, 1, 1, 'Numeric');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (5, 0, 0, 'Table');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (6, 1, 0, 'Checkbox');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (7, 1, 0, 'Radio');
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (8, 1, 1, 'Dropdown');
END;
/
COMMIT;


ALTER TABLE PENDING_IND ADD CONSTRAINT RefPENDING_ELEMENT_TYPE528 
    FOREIGN KEY (ELEMENT_TYPE)
    REFERENCES PENDING_ELEMENT_TYPE(ELEMENT_TYPE)
;



CREATE OR REPLACE TYPE T_PENDING_VAL_ROW AS 
  OBJECT ( 
	PENDING_IND_ID			NUMBER(10),
	PENDING_REGION_ID		NUMBER(10),
	ROOT_REGION_ID			NUMBER(10),
	PENDING_PERIOD_ID		NUMBER(10),
	APPROVAL_STEP_ID		NUMBER(10),
	PENDING_VAL_ID			NUMBER(10)  
  );
/
CREATE OR REPLACE TYPE T_PENDING_VAL_TABLE AS 
  TABLE OF T_PENDING_VAL_ROW;
/

-- prob need to recompile sps before running this
@..\pending_pkg
@..\pending_body

BEGIN 
    FOR r IN (
    	SELECT approval_step_id FROM approval_step
    )
    LOOP
		pending_pkg.SetMaxValues(r.approval_step_id);
    END LOOP;
END;
/


UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
