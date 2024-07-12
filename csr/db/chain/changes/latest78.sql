define version=78
@update_header

ALTER TABLE chain.supplier_relationship ADD (DELETED NUMBER(1) DEFAULT 0 NOT NULL);

CREATE OR REPLACE VIEW chain.v$supplier_relationship AS
	SELECT *
	  FROM supplier_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
-- either the relationship is active, or it is virtually active for a very short period so that we can send invitations
	   AND (active = 1 OR SYSDATE < virtually_active_until_dtm)
;

CREATE TABLE chain.UCD_LOGON(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    UCD_ACT_ID              CHAR(36)         NOT NULL,
    PREVIOUS_USER_SID       NUMBER(10, 0)    NOT NULL,
    PREVIOUS_ACT_ID         CHAR(36)         NOT NULL,
    PREVIOUS_COMPANY_SID    NUMBER(10, 0),
    CONSTRAINT PK319 PRIMARY KEY (APP_SID, UCD_ACT_ID)
)
;

ALTER TABLE chain.UCD_LOGON ADD CONSTRAINT RefCUSTOMER_OPTIONS798 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

DECLARE
	v_ucd_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonadmin;
	
	FOR r IN (
		SELECT * FROM v$chain_host
	) LOOP
			v_ucd_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, r.app_sid, 'users/UserCreatorDaemon');
			
			FOR s IN (
				SELECT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, r.app_sid, 'users') sid_id FROM DUAL
				 UNION ALL
				SELECT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, r.app_sid, 'Trash') sid_id FROM DUAL
				 UNION ALL
				SELECT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, r.app_sid, 'chain/companies') sid_id FROM DUAL
			) LOOP
		
				acl_pkg.AddACE(
					security_pkg.GetAct, 
					acl_pkg.GetDACLIDForSID(s.sid_id), 
					security_pkg.ACL_INDEX_LAST, 
					security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_DEFAULT, 
					v_ucd_sid, 
					security_pkg.PERMISSION_STANDARD_ALL
				);	

				acl_pkg.PropogateACEs(security_pkg.GetAct, s.sid_id);
		
		END LOOP;
	
	END LOOP;
END;
/

@update_tail