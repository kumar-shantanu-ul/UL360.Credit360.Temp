-- Please update version.sql too -- this keeps clean builds in sync
define version=519
@update_header

INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage any portal', 0);

BEGIN
	FOR r IN (
		SELECT DISTINCT host 
		  FROM customer c
			JOIN tab t ON c.app_sid = t.app_sid
	)
	LOOP
		user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('Fixing '||r.host||'...');
		BEGIN
			csr_data_pkg.enableCapability('Manage any portal');
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN				
				NULL;-- exists already
		END;
		user_pkg.logonadmin(null);
	END LOOP;
END;
/

@..\portlet_body

@update_tail

