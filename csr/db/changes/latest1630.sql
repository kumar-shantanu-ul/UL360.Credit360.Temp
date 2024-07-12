-- Please update version.sql too -- this keeps clean builds in sync
define version=1630
@update_header

DECLARE
	v_class_id 		security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);	
	
	BEGIN
		security.class_pkg.CreateClass(v_act, null, 'ChainCompoundFilter', 'chain.filter_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/
commit;


-- security functions will rely on filter_pkg being valid
@latest1630_packages

BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Clean up any filter SIDs that aren't in the saved_filter table - these were created when filters
	-- were in their infancy (there's only a few hundred of them but they make the SO structure look untidy)
	FOR r IN (
		SELECT so.sid_id
		  FROM security.securable_object so
		  LEFT JOIN chain.saved_filter sf ON so.sid_id = sf.saved_filter_sid
		 WHERE so.class_id = security.class_pkg.GetClassID('ChainCompoundFilter')
		   AND sf.saved_filter_sid IS NULL
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
END;
/

DECLARE
	v_filter_folder_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- For filters created directly under users, move these to a filter folder
	FOR r IN (
		SELECT so.sid_id, ut.sid_id user_sid
		  FROM security.securable_object so
		  JOIN chain.saved_filter sf ON so.sid_id = sf.saved_filter_sid
		  JOIN security.user_table ut ON so.parent_sid_id = ut.sid_id
		 WHERE so.class_id = security.class_pkg.GetClassID('ChainCompoundFilter')
	) LOOP
		BEGIN
			v_filter_folder_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, r.user_sid, 'Filters');
		EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.SecurableObject_pkg.CreateSO(security.security_pkg.GetAct, r.user_sid, 
				security.security_pkg.SO_CONTAINER, 'Filters', v_filter_folder_sid);
		END;
		security.securableobject_pkg.MoveSO(security.security_pkg.GetAct, r.sid_id, v_filter_folder_sid);
	END LOOP;
	
END;
/

ALTER TABLE CHAIN.SAVED_FILTER ADD (
    CARD_GROUP_ID         NUMBER(10, 0)    NULL,
    PARENT_SID            NUMBER(10, 0)    NULL
)
;

UPDATE chain.saved_filter sf
   SET (parent_sid) = (
	SELECT parent_sid_id
	  FROM security.securable_object so
	 WHERE so.sid_id = sf.saved_filter_sid
	);

UPDATE chain.saved_filter sf
   SET (card_group_id) = (
	SELECT card_group_id
	  FROM chain.compound_filter cf
	 WHERE cf.compound_filter_id = sf.compound_filter_id
	);

ALTER TABLE CHAIN.SAVED_FILTER MODIFY CARD_GROUP_ID NOT NULL;
ALTER TABLE CHAIN.SAVED_FILTER MODIFY PARENT_SID NOT NULL;

ALTER TABLE CHAIN.COMPOUND_FILTER ADD CONSTRAINT UK_CMP_FIL_ID_CRD_GRP_ID  UNIQUE (APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;

ALTER TABLE CHAIN.SAVED_FILTER DROP CONSTRAINT FK_SAVED_FILTER_CMP_ID
;

ALTER TABLE CHAIN.SAVED_FILTER ADD CONSTRAINT FK_SAVED_FILTER_CMP_ID 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;


BEGIN
	-- Find non-unique names and make them unique
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT * FROM (
			SELECT app_sid, saved_filter_sid, card_group_id, parent_sid, name, 
				   ROW_NUMBER() OVER (PARTITION BY app_sid, card_group_id, parent_sid, LOWER(name) ORDER BY compound_filter_id) rn
			  FROM chain.saved_filter
			)
		 WHERE rn > 1
	) LOOP
		UPDATE chain.saved_filter
		   SET name = r.name||' ('||r.rn||')'
		 WHERE saved_filter_sid = r.saved_filter_sid;
	END LOOP;
END;
/

CREATE UNIQUE INDEX CHAIN.UK_SAVED_FILTER_NAME ON CHAIN.SAVED_FILTER(APP_SID, CARD_GROUP_ID, PARENT_SID, LOWER(NAME))
;



DECLARE
	v_global_filter_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer
	) LOOP
		BEGIN
			security.SecurableObject_pkg.CreateSO(security.security_pkg.GetAct, r.app_sid, 
				security.security_pkg.SO_CONTAINER, 'Filters', v_global_filter_sid);
		EXCEPTION WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_global_filter_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct,
				r.app_sid, 'Filters');
		END;
		-- Default permissions is registered users have read access to all shared filters
		security.acl_pkg.AddACE(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_global_filter_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, r.app_sid, 'Groups/RegisteredUsers'),
			security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/

@..\chain\filter_pkg
@..\chain\filter_body
@..\csr_data_body

@update_tail
