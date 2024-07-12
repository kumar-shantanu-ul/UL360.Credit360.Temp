-- Please update version.sql too -- this keeps clean builds in sync
define version=444
@update_header

BEGIN	
	FOR r IN (
		SELECT constraint_name
	  	  FROM user_constraints
		 WHERE table_name = 'PROPERTY_DIVISION'
		   and constraint_type = 'R'
	) 
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.property_division DROP CONSTRAINT ' || r.constraint_name;
	END LOOP;
END;
/

ALTER TABLE division
DROP PRIMARY KEY;

ALTER TABLE division
	ADD CONSTRAINT PK760 PRIMARY KEY (DIVISION_ID, APP_SID);
	
ALTER TABLE property
DROP PRIMARY KEY;

ALTER TABLE property
	ADD CONSTRAINT PK761 PRIMARY KEY (PROPERTY_ID, APP_SID);

ALTER TABLE DIVISION ADD CONSTRAINT RefCUSTOMER1633 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE PROPERTY ADD CONSTRAINT RefCUSTOMER1634 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE PROPERTY_DIVISION ADD CONSTRAINT RefPROPERTY1617 
    FOREIGN KEY (PROPERTY_ID, APP_SID)
    REFERENCES PROPERTY(PROPERTY_ID, APP_SID)
;

ALTER TABLE PROPERTY_DIVISION ADD CONSTRAINT RefDIVISION1618 
    FOREIGN KEY (DIVISION_ID, APP_SID)
    REFERENCES DIVISION(DIVISION_ID, APP_SID)
;


@update_tail
