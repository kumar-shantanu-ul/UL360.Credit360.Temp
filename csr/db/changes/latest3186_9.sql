-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.DELEGATION_USER ADD (
	DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 3 NOT NULL,
	INHERITED_FROM_SID				NUMBER(10, 0) 
);

UPDATE csr.delegation_user SET inherited_from_sid = delegation_sid;

ALTER TABLE CSR.DELEGATION_USER MODIFY (
	DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 0,
	INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
);

ALTER TABLE csr.delegation_user DROP CONSTRAINT PK_DELEGATION_USER;
ALTER TABLE csr.delegation_user ADD CONSTRAINT PK_DELEGATION_USER PRIMARY KEY (app_sid, delegation_sid, user_sid, inherited_from_sid);

ALTER TABLE CSR.DELEGATION_ROLE ADD (
	DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 3 NOT NULL,
	INHERITED_FROM_SID				NUMBER(10, 0)
);

UPDATE csr.delegation_role SET inherited_from_sid = delegation_sid;

ALTER TABLE CSR.DELEGATION_ROLE MODIFY (
	DELEG_PERMISSION_SET			NUMBER(10, 0) DEFAULT 0,
	INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
);

ALTER TABLE csr.delegation_role DROP CONSTRAINT PK_DELEGATION_ROLE;
ALTER TABLE csr.delegation_role ADD CONSTRAINT PK_DELEGATION_ROLE PRIMARY KEY (app_sid, delegation_sid, role_sid, inherited_from_sid);

ALTER TABLE CSR.DELEGATION_USER ADD CONSTRAINT FK_DELEG_USER_DELEG2
    FOREIGN KEY (APP_SID, INHERITED_FROM_SID)
    REFERENCES CSR.DELEGATION(APP_SID, DELEGATION_SID)
;

ALTER TABLE CSR.DELEGATION_ROLE ADD CONSTRAINT FK_DELEG_ROLE_DELEG2
    FOREIGN KEY (APP_SID, INHERITED_FROM_SID)
    REFERENCES CSR.DELEGATION(APP_SID, DELEGATION_SID)
;

ALTER TABLE CSRIMP.DELEGATION_USER ADD (
	DELEG_PERMISSION_SET			NUMBER(10, 0) NOT NULL,
	INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
);

ALTER TABLE csrimp.delegation_user DROP CONSTRAINT PK_DELEGATION_USER;
ALTER TABLE csrimp.delegation_user ADD CONSTRAINT PK_DELEGATION_USER PRIMARY KEY (csrimp_session_id, delegation_sid, user_sid, inherited_from_sid);

ALTER TABLE CSRIMP.DELEGATION_ROLE ADD (
	DELEG_PERMISSION_SET			NUMBER(10, 0) NOT NULL,
	INHERITED_FROM_SID				NUMBER(10, 0) NOT NULL
);

UPDATE csrimp.delegation_role SET inherited_from_sid = delegation_sid;

ALTER TABLE csrimp.delegation_role DROP CONSTRAINT PK_DELEGATION_ROLE;
ALTER TABLE csrimp.delegation_role ADD CONSTRAINT PK_DELEGATION_ROLE PRIMARY KEY (csrimp_session_id, delegation_sid, role_sid, inherited_from_sid);

CREATE INDEX csr.ix_deleg_role_inherited ON csr.delegation_role (app_sid, inherited_from_sid);
CREATE INDEX csr.ix_deleg_user_inherited ON csr.delegation_user (app_sid, inherited_from_sid);
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
MERGE INTO csr.delegation_user du
	USING (Select app_sid, decode(permission_set, 995, 3, 263139, 11, 3) permission_set, delegation_sid, inherited_from_sid, csr_user_sid
			 FROM (
				select cu.app_sid, MAX(permission_set) permission_set, d2.delegation_sid, d.delegation_sid inherited_from_sid, cu.csr_user_sid
				  from csr.csr_user cu
				  JOIN security.group_members gm ON cu.csr_user_sid = GM.MEMBER_SID_ID
				  JOIN csr.delegation d ON GM.GROUP_SID_ID = d.delegation_sid AND cu.app_sid = d.app_sid
				  JOIN security.acl ON acl.sid_id = d.delegation_sid
				  JOIN security.securable_object so ON so.dacl_id = acl.acl_id
				  JOIN csr.delegation d2 ON d2.delegation_sid = so.sid_id AND d2.app_sid = so.application_sid_id
				 WHERE d2.delegation_sid != d.delegation_sid
				 GROUP BY cu.app_sid, d2.delegation_sid, cu.csr_user_sid, d.delegation_sid
			)
		) n
	ON (du.app_sid = n.app_sid AND du.delegation_sid = n.delegation_sid AND du.user_sid = n.csr_user_sid AND du.inherited_from_sid = n.inherited_from_sid)
	WHEN MATCHED THEN UPDATE
	   SET du.deleg_permission_set = GREATEST(du.deleg_permission_set, n.permission_set)
	WHEN NOT MATCHED THEN
		INSERT (du.app_sid, du.deleg_permission_set, du.delegation_sid, du.inherited_from_sid, du.user_sid)
		VALUES (n.app_sid, n.permission_set, n.delegation_sid, n.inherited_from_sid, n.csr_user_sid);

MERGE INTO csr.delegation_role dr
	USING (Select app_sid, decode(permission_set, 995, 3, 263139, 11, 3) permission_set, delegation_sid, inherited_from_sid, role_sid
			 FROM (
				select r.app_sid, MAX(permission_set) permission_set, d2.delegation_sid, d.delegation_sid inherited_from_sid, r.role_sid
				  from csr.role r
				  JOIN security.group_members gm ON r.role_sid = GM.MEMBER_SID_ID
				  JOIN csr.delegation d ON GM.GROUP_SID_ID = d.delegation_sid
				  JOIN security.acl ON acl.sid_id = d.delegation_sid
				  JOIN security.securable_object so ON so.dacl_id = acl.acl_id
				  JOIN csr.delegation d2 ON d2.delegation_sid = so.sid_id AND d2.app_sid = so.application_sid_id
				 WHERE d2.delegation_sid != d.delegation_sid
				 GROUP BY r.app_sid, d2.delegation_sid, r.role_sid, d.delegation_sid
			)
		) n
	ON (dr.app_sid = n.app_sid AND dr.delegation_sid = n.delegation_sid AND dr.role_sid = n.role_sid AND dr.inherited_from_sid = n.inherited_from_sid)
	WHEN MATCHED THEN UPDATE
	   SET dr.deleg_permission_set = GREATEST(dr.deleg_permission_set, n.permission_set)
	WHEN NOT MATCHED THEN
		INSERT (dr.app_sid, dr.deleg_permission_set, dr.delegation_sid, dr.inherited_from_sid, dr.role_sid)
		VALUES (n.app_sid, n.permission_set, n.delegation_sid, n.inherited_from_sid, n.role_sid);

DELETE
  FROM security.group_members gm
 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = gm.group_sid_id);
 
DELETE
  FROM security.group_table gt
 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = gt.sid_id);

-- Analyze could potentially be slow but has been reduced to only the 4 tables I care about.
DECLARE
BEGIN
	FOR r IN (
		SELECT owner, table_name 
		  FROM ALL_TABLES
		 WHERE TABLE_NAME IN ('GROUP_MEMBERS', 'GROUP_TABLE', 'DELEGATION_USER', 'DELEGATION_ROLE')
		   AND OWNER IN ('SECURITY','CSR')
	)
	LOOP
		EXECUTE IMMEDIATE 'ANALYZE TABLE '||r.owner||'.'||r.table_name||' ESTIMATE STATISTICS';
	END LOOP;
END;
/
 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../delegation_pkg
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
