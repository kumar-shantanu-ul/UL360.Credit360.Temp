-- Please update version.sql too -- this keeps clean builds in sync
define version=383
@update_header

ALTER TABLE REGION_ROLE_MEMBER ADD (
	INHERITED_FROM_SID    NUMBER(10, 0)   NULL
)
;

BEGIN
	UPDATE region_role_member
	   SET inherited_from_sid = region_sid;
	COMMIT;
END;
/

ALTER TABLE REGION_ROLE_MEMBER MODIFY (
	INHERITED_FROM_SID    NUMBER(10, 0)   NOT NULL
)
;

ALTER TABLE REGION_ROLE_MEMBER DROP CONSTRAINT PK_REGION_ROLE_MEMBER DROP INDEX;
;

ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT PK_REGION_ROLE_MEMBER 
	PRIMARY KEY(APP_SID, USER_SID, REGION_SID, ROLE_SID, INHERITED_FROM_SID)
;

ALTER TABLE REGION_ROLE_MEMBER ADD CONSTRAINT RefREGION1369 
    FOREIGN KEY (APP_SID, INHERITED_FROM_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

@../role_pkg
@../region_pkg
@../schema_pkg

@../role_body
@../region_body
@../schema_body


-- Propogate inheritance for existing roles
BEGIN
	FOR a IN (
		SELECT DISTINCT host
		  FROM customer
		 WHERE app_sid IS NOT NULL
	) LOOP
		BEGIN
			user_pkg.logonadmin(a.host);
			FOR r IN (
				SELECT role_sid, region_sid
				  FROM region_role_member
				 WHERE region_sid = inherited_from_sid
			) LOOP
				role_pkg.PropagateRoleMembership(r.role_sid, r.region_sid);
			END LOOP;
			security_pkg.SetAPP(NULL);		
		EXCEPTION
			WHEN security_pkg.object_not_found THEN
				NULL;
		END;
	END LOOP;
END;
/

@update_tail
