-- Please update version.sql too -- this keeps clean builds in sync
define version=25
@update_header

alter table delegation add (fully_delegated number(1,0) default 0 not null);


CREATE SEQUENCE REASON_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;


ALTER TABLE val ADD (
    FILE_UPLOAD_SID    NUMBER(10, 0) );

ALTER TABLE VAL ADD CONSTRAINT RefFILE_UPLOAD241 
    FOREIGN KEY (FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(FILE_UPLOAD_SID)
;




DECLARE
	v_is_fully_delegated NUMBER(10);
BEGIN
	FOR r IN (SELECT delegation_sid, ROWID rid FROM delegation)
    LOOP
    	v_is_fully_delegated := delegation_pkg.isFullyDelegated(r.delegation_sid);
		UPDATE delegation SET Fully_Delegated = v_is_fully_delegated WHERE ROWID = r.rid;
	END LOOP;
END; 
/
commit;



@update_tail
