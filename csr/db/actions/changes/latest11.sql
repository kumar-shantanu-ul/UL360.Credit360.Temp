
CREATE TABLE TASK_REGION(
    TASK_SID        NUMBER(10, 0)    NOT NULL,
    REGION_SID      NUMBER(10, 0)    NOT NULL,
    USE_FOR_CALC    NUMBER(1, 0),
    CONSTRAINT PK39 PRIMARY KEY (TASK_SID, REGION_SID)
)
;

ALTER TABLE TASK_REGION ADD CONSTRAINT RefTASK52 
    FOREIGN KEY (TASK_SID)
    REFERENCES TASK(TASK_SID)
;

CREATE TABLE CUSTOMER_OPTIONS(
    APP_SID               NUMBER(10, 0)    NOT NULL,
    SHOW_REGIONS          NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    RESTRICT_BY_REGION    NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT PK41 PRIMARY KEY (APP_SID)
)
;

INSERT INTO customer_options (
	SELECT app_sid, 0, 0
	  FROM csr.customer
);

COMMIT;

connect csr/csr@&&1;
grant select, references on region to actions;

connect security/security@&&1;
grant execute on securableobject_pkg to actions;
