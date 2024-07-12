-- Please update version.sql too -- this keeps clean builds in sync
define version=1924
@update_header

ALTER TABLE CSR.INITIATIVE_SAVING_TYPE ADD (
    IS_DURING         NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    IS_RUNNING        NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CHECK (IS_DURING IN(0,1)),
    CHECK (IS_RUNNING IN(0,1))
);

BEGIN
UPDATE CSR.INITIATIVE_SAVING_TYPE SET is_during = 1 WHERE saving_type_id = 1;
UPDATE CSR.INITIATIVE_SAVING_TYPE SET is_running = 1 WHERE saving_type_id = 2;
END;
/

@../initiative_body

@update_tail
