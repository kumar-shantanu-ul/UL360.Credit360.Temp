define version=3188
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/


ALTER TABLE csr.customer
ADD REQUIRE_SA_LOGIN_REASON NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csr.customer
ADD CONSTRAINT CK_REQUIRE_SA_LOGIN_REASON CHECK (REQUIRE_SA_LOGIN_REASON IN (0,1));
ALTER TABLE csrimp.customer
ADD REQUIRE_SA_LOGIN_REASON NUMBER(1) NOT NULL;
ALTER TABLE csrimp.customer
ADD CONSTRAINT CK_REQUIRE_SA_LOGIN_REASON CHECK (REQUIRE_SA_LOGIN_REASON IN (0,1));
ALTER TABLE CSR.AUDIT_LOG
ADD ORIGINAL_USER_SID NUMBER(10, 0);
ALTER TABLE CSR.AUDIT_LOG
MODIFY ORIGINAL_USER_SID DEFAULT SYS_CONTEXT('SECURITY', 'ORIGINAL_LOGIN_SID');
COMMENT ON TABLE CSR.USER_PROFILE
IS 'contains_pii = "yes"';
COMMENT ON TABLE CSR.USER_PROFILE_STAGED_RECORD
IS 'contains_pii = "yes"';
BEGIN 
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_USER ADD (
		DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 3 NOT NULL,
		INHERITED_FROM_SID				NUMBER(10, 0) 
	)';
	EXECUTE IMMEDIATE 'UPDATE csr.delegation_user SET inherited_from_sid = delegation_sid';
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_USER MODIFY (
		DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 0,
		INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
	)';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.delegation_user DROP CONSTRAINT PK_DELEGATION_USER DROP INDEX';
	
	EXECUTE IMMEDIATE 'ALTER TABLE csr.delegation_user ADD CONSTRAINT PK_DELEGATION_USER PRIMARY KEY (app_sid, delegation_sid, user_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_ROLE ADD (
		DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 3 NOT NULL,
		INHERITED_FROM_SID				NUMBER(10, 0)
	)';
	EXECUTE IMMEDIATE 'UPDATE csr.delegation_role SET inherited_from_sid = delegation_sid';
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_ROLE MODIFY (
		DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 0,
		INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
	)';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.delegation_role DROP CONSTRAINT PK_DELEGATION_ROLE DROP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.delegation_role ADD CONSTRAINT PK_DELEGATION_ROLE PRIMARY KEY (app_sid, delegation_sid, role_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_USER ADD CONSTRAINT FK_DELEG_USER_DELEG2
		FOREIGN KEY (APP_SID, INHERITED_FROM_SID)
		REFERENCES CSR.DELEGATION(APP_SID, DELEGATION_SID)'
	;
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_ROLE ADD CONSTRAINT FK_DELEG_ROLE_DELEG2
		FOREIGN KEY (APP_SID, INHERITED_FROM_SID)
		REFERENCES CSR.DELEGATION(APP_SID, DELEGATION_SID)'
	;
	EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.DELEGATION_USER ADD (
		DELEG_PERMISSION_SET			NUMBER(10, 0) NOT NULL,
		INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
	)';
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_user DROP CONSTRAINT PK_DELEGATION_USER DROP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_user ADD CONSTRAINT PK_DELEGATION_USER PRIMARY KEY (csrimp_session_id, delegation_sid, user_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.DELEGATION_ROLE ADD (
		DELEG_PERMISSION_SET			NUMBER(10, 0) NOT NULL,
		INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
	)';
	EXECUTE IMMEDIATE 'UPDATE csrimp.delegation_role SET inherited_from_sid = delegation_sid';
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_role DROP CONSTRAINT PK_DELEGATION_ROLE DROP INDEX';
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_role ADD CONSTRAINT PK_DELEGATION_ROLE PRIMARY KEY (csrimp_session_id, delegation_sid, role_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_deleg_role_inherited ON csr.delegation_role (app_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_deleg_user_inherited ON csr.delegation_user (app_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.acl TO csr';

END;
/


grant select on aspen2.lang to csrimp;




CREATE OR REPLACE VIEW csr.v$delegation_user AS
	SELECT app_sid, delegation_sid, user_sid
      FROM csr.delegation_user
	 WHERE inherited_from_sid = delegation_sid
     UNION ALL
    SELECT DISTINCT d.app_sid, d.delegation_sid, rrm.user_sid
      FROM csr.delegation d
      JOIN csr.delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = dlr.delegation_sid
      JOIN csr.delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
      JOIN csr.region_role_member rrm ON rrm.region_sid = dr.region_sid AND rrm.role_sid = dlr.role_sid AND rrm.app_sid = d.app_sid
	 WHERE NOT EXISTS (
		SELECT NULL
		  FROM csr.delegation_user
		 WHERE user_sid = rrm.user_sid
		   AND delegation_sid = d.delegation_sid);




UPDATE csr.module
   SET module_name = 'Suggestions',
	   enable_sp = 'EnableSuggestions',
	   description = 'Enables Suggestions.'
 WHERE enable_sp = 'EnableSuggestionsApi';

-- Update for US15446
--
-- This was originally run as a separate ad-hoc script as it took too long to run
-- during a release. It is required, and not running it will result in permissions being lost
-- when running a later update, so has been added in retrospectively to ensure that it is run
-- for other environments, such as on-premises installations.
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE OWNER = SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND TABLE_NAME = 'US15446_PROCESSED_DELEGS';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE us15446_processed_delegs (delegation_sid NUMBER(10,0))';
	END IF;
END;
/

DECLARE
	PROCEDURE AddDELEG(
		in_delegation_sid	NUMBER
	) AS PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		INSERT INTO us15446_processed_delegs VALUES(in_delegation_sid);
		COMMIT;
	END;
BEGIN
	FOR r IN (
		SELECT app_sid, delegation_sid
		  FROM csr.delegation d
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM us15446_processed_delegs
			 WHERE delegation_sid = d.delegation_sid
			)
		 ORDER BY delegation_sid ASC
		)
	LOOP
		MERGE INTO csr.delegation_user du
		USING (
			SELECT app_sid, DECODE(permission_set, 995, 3, 263139, 11, 3) permission_set, delegation_sid, inherited_from_sid, csr_user_sid
			  FROM (
				SELECT d.app_sid, MAX(permission_set) permission_set, d.delegation_sid, d2.delegation_sid inherited_from_sid, cu.csr_user_sid
				  FROM csr.delegation d
				  JOIN security.securable_object so ON d.delegation_sid = so.sid_id AND so.application_sid_id = d.app_sid
				  JOIN security.acl ON so.dacl_id = acl.acl_id
				  JOIN csr.delegation d2 ON acl.sid_id = d2.delegation_sid
				  JOIN security.group_members gm ON gm.group_sid_id = d2.delegation_sid
				  JOIN csr.csr_user cu ON cu.csr_user_sid = gm.member_sid_id
				 WHERE d.app_sid = r.app_sid AND d.delegation_sid = r.delegation_sid
				 GROUP BY d.app_sid, d.delegation_sid, d2.delegation_sid, cu.csr_user_sid
				)
			) n
		   ON (du.app_sid = n.app_sid AND du.delegation_sid = n.delegation_sid AND du.user_sid = n.csr_user_sid AND du.inherited_from_sid = n.inherited_from_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET du.deleg_permission_set = GREATEST(du.deleg_permission_set, n.permission_set)
		 WHEN NOT MATCHED THEN
			INSERT (du.app_sid, du.deleg_permission_set, du.delegation_sid, du.inherited_from_sid, du.user_sid)
			VALUES (n.app_sid, n.permission_set, n.delegation_sid, n.inherited_from_sid, n.csr_user_sid);
		
		COMMIT;
		
		MERGE INTO csr.delegation_role dr
		USING (
			SELECT app_sid, DECODE(permission_set, 995, 3, 263139, 11, 3) permission_set, delegation_sid, inherited_from_sid, role_sid
			  FROM (
				SELECT d.app_sid, MAX(permission_set) permission_set, d.delegation_sid, d2.delegation_sid inherited_from_sid, r.role_sid
				  FROM csr.delegation d
				  JOIN security.securable_object so ON d.delegation_sid = so.sid_id AND so.application_sid_id = d.app_sid
				  JOIN security.acl ON so.dacl_id = acl.acl_id
				  JOIN csr.delegation d2 ON acl.sid_id = d2.delegation_sid
				  JOIN security.group_members gm ON gm.group_sid_id = d2.delegation_sid
				  JOIN csr.role r ON r.role_sid = gm.member_sid_id
				 WHERE d.app_sid = r.app_sid AND d.delegation_sid = r.delegation_sid
				 GROUP BY d.app_sid, d.delegation_sid, d2.delegation_sid, r.role_sid
				)
			) n
		   ON (dr.app_sid = n.app_sid AND dr.delegation_sid = n.delegation_sid AND dr.role_sid = n.role_sid AND dr.inherited_from_sid = n.inherited_from_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET dr.deleg_permission_set = GREATEST(dr.deleg_permission_set, n.permission_set)
		 WHEN NOT MATCHED THEN
			INSERT (dr.app_sid, dr.deleg_permission_set, dr.delegation_sid, dr.inherited_from_sid, dr.role_sid)
			VALUES (n.app_sid, n.permission_set, n.delegation_sid, n.inherited_from_sid, n.role_sid);
			
		COMMIT;
		
		AddDELEG(r.delegation_sid);
	END LOOP;
END;
/
-- End of US15446 update

@..\csr_data_pkg
@..\enable_pkg
@..\role_pkg
@..\chain\chain_pkg
@..\chain\company_type_pkg
@..\delegation_pkg
@..\deleg_admin_pkg
@..\sheet_pkg


@..\chain\company_type_body
@..\delegation_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body
@..\csr_data_body
@..\csr_user_body
@..\enable_body
@..\csr_app_body
@..\chain\helper_body
@..\chain\product_body
@..\chain\product_type_body
@..\indicator_body
@..\factor_body
@..\role_body
@..\auto_approve_body
@..\deleg_admin_body
@..\deleg_plan_body
@..\issue_body
@..\sheet_body
@..\supplier_body
@..\user_cover_body
@..\val_datasource_body



@update_tail
