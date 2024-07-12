-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

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

	EXECUTE IMMEDIATE 'ALTER TABLE csr.delegation_user DROP CONSTRAINT PK_DELEGATION_USER';
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

	EXECUTE IMMEDIATE 'ALTER TABLE csr.delegation_role DROP CONSTRAINT PK_DELEGATION_ROLE';
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

	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_user DROP CONSTRAINT PK_DELEGATION_USER';
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_user ADD CONSTRAINT PK_DELEGATION_USER PRIMARY KEY (csrimp_session_id, delegation_sid, user_sid, inherited_from_sid)';

	EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.DELEGATION_ROLE ADD (
		DELEG_PERMISSION_SET			NUMBER(10, 0) NOT NULL,
		INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
	)';

	EXECUTE IMMEDIATE 'UPDATE csrimp.delegation_role SET inherited_from_sid = delegation_sid';

	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_role DROP CONSTRAINT PK_DELEGATION_ROLE';
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.delegation_role ADD CONSTRAINT PK_DELEGATION_ROLE PRIMARY KEY (csrimp_session_id, delegation_sid, role_sid, inherited_from_sid)';

	EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_deleg_role_inherited ON csr.delegation_role (app_sid, inherited_from_sid)';
	EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_deleg_user_inherited ON csr.delegation_user (app_sid, inherited_from_sid)';

	EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.acl TO csr';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
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

-- *** Data changes ***
-- RLS

-- Data
 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../delegation_pkg
@../deleg_admin_pkg
@../sheet_pkg

@../auto_approve_body
@../delegation_body
@../deleg_admin_body
@../deleg_plan_body
@../issue_body
@../role_body
@../schema_body
@../sheet_body
@../supplier_body
@../user_cover_body
@../val_datasource_body

@../csrimp/imp_body

@update_tail
