-- Please update version.sql too -- this keeps clean builds in sync
define version=43
@update_header


-- 
-- TABLE: CUSTOM_FIELD_DEPENDENCY 
--

CREATE TABLE CUSTOM_FIELD_DEPENDENCY(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FIELD_NUM              NUMBER(2, 0)     NOT NULL,
    DEPENDENT_FIELD_NUM    NUMBER(2, 0)     NOT NULL,
    CONSTRAINT PK109 PRIMARY KEY (APP_SID, FIELD_NUM, DEPENDENT_FIELD_NUM)
)
;

 
-- 
-- TABLE: CUSTOM_FIELD_DEPENDENCY 
--

ALTER TABLE CUSTOM_FIELD_DEPENDENCY ADD CONSTRAINT RefCUSTOM_FIELD168 
    FOREIGN KEY (APP_SID, DEPENDENT_FIELD_NUM)
    REFERENCES CUSTOM_FIELD(APP_SID, FIELD_NUM)
;

ALTER TABLE CUSTOM_FIELD_DEPENDENCY ADD CONSTRAINT RefCUSTOM_FIELD169 
    FOREIGN KEY (APP_SID, FIELD_NUM)
    REFERENCES CUSTOM_FIELD(APP_SID, FIELD_NUM)
;


INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Configure Community Involvement module', 0);
	

BEGIN
	FOR r IN (	
		SELECT DISTINCT c.host
		  FROM donations.scheme s
			JOIN csr.customer c ON s.app_sid = c.app_sid
	)
	LOOP
		BEGIN
			user_pkg.LogonAdmin(r.host);
			DBMS_OUTPUT.PUT_LINE('fixing '||r.host);
			csr.csr_data_pkg.EnableCapability('Configure Community Involvement module');
			security_pkg.SetApp(null);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				DBMS_OUTPUT.PUT_LINE(r.host || ' not found');
		END;
	END LOOP;
END;
/
	
@../fields_pkg
@../fields_body
@../rls

@update_tail
