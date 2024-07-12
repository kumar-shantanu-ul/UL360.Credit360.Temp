-- Please update version.sql too -- this keeps clean builds in sync
define version=881
@update_header

ALTER TABLE CSR.IND_VALIDATION_RULE ADD (IND_VALIDATION_RULE_ID NUMBER(10, 0), POSITION NUMBER(10, 0));

CREATE SEQUENCE CSR.IND_VALIDATION_RULE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

DECLARE
	v_pos		CSR.IND_VALIDATION_RULE.POSITION%TYPE;
BEGIN
	FOR r IN (
		SELECT UNIQUE app_sid, ind_sid FROM CSR.IND_VALIDATION_RULE
	) LOOP
		v_pos := 0;
		FOR p IN (
			SELECT * FROM CSR.IND_VALIDATION_RULE WHERE app_sid = r.app_sid and ind_sid = r.ind_sid
		) LOOP
			
			UPDATE CSR.IND_VALIDATION_RULE
			   SET IND_VALIDATION_RULE_id = CSR.IND_VALIDATION_RULE_id_seq.nextval, position = v_pos
			 WHERE app_sid = p.app_sid
			   AND ind_sid = p.ind_sid
			   AND expr = p.expr
			   AND message = p.message;
			   
			v_pos := v_pos + 1;
		END LOOP;
	END LOOP;
END;
/

ALTER TABLE CSR.IND_VALIDATION_RULE MODIFY (POSITION NOT NULL);
ALTER TABLE CSR.IND_VALIDATION_RULE MODIFY (IND_VALIDATION_RULE_ID NOT NULL);
ALTER TABLE CSR.IND_VALIDATION_RULE ADD CONSTRAINT PK_IND_VALIDATION_RULE PRIMARY KEY (IND_VALIDATION_RULE_ID);

@..\indicator_pkg
@..\indicator_body

@update_tail
