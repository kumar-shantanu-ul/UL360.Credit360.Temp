-- Please update version.sql too -- this keeps clean builds in sync
define version=3248
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.factor_type ADD (enabled NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.factor_type ADD CONSTRAINT CK_FCTR_TYPE_EGRID CHECK (egrid IN (1, 0));
ALTER TABLE csr.factor_type ADD CONSTRAINT CK_FCTR_TYPE_ENABLED CHECK (enabled IN (1, 0));

UPDATE csr.factor_type
   SET enabled = 1;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$factor_type AS
SELECT f.factor_type_id, f.parent_id, f.name, f.std_measure_id, f.egrid, af.active, uf.in_use, mf.mapped, f.enabled
  FROM csr.factor_type f
  LEFT JOIN (
    SELECT factor_type_id, 1 mapped FROM (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.ind i ON i.factor_type_id = f.factor_type_id
                 AND i.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
        )) mf ON f.factor_type_id = mf.factor_type_id
  LEFT JOIN (
    SELECT factor_type_id, 1 active FROM (
          SELECT DISTINCT af.factor_type_id
            FROM csr.factor_type af
           START WITH af.factor_type_id
            IN (
              SELECT DISTINCT aaf.factor_type_id
                FROM csr.factor_type aaf
                JOIN csr.std_factor sf ON sf.factor_type_id = aaf.factor_type_id
                JOIN csr.std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
            )
           CONNECT BY PRIOR parent_id = af.factor_type_id
          UNION
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
                 AND sf.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
          UNION
          SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
            FROM dual
        )) af ON f.factor_type_id = af.factor_type_id
   LEFT JOIN (
    SELECT factor_type_id, 1 in_use FROM (
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR parent_id = factor_type_id
      UNION
      SELECT DISTINCT f.factor_type_id
        FROM csr.factor_type f
             START WITH f.factor_type_id
              IN (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
            JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
             AND sf.app_sid = security.security_pkg.getApp
           WHERE std_measure_id IS NOT NULL
        )
      CONNECT BY PRIOR parent_id = f.factor_type_id
      UNION
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR factor_type_id = parent_id
      UNION
      SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
        FROM dual
        )) uf ON f.factor_type_id = uf.factor_type_id;



-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can delete factor type', 0);

-- api.emissionfactor - webresource required, but only for the sites that need it.
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_api						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id
		  FROM security.securable_object
		 WHERE name = 'Can import std factor set'
	)
	LOOP
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');

		BEGIN
			v_www_api := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.emissionfactor');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				security.security_pkg.SetApp(r.application_sid_id);
				security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.emissionfactor', v_www_api);

				v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.application_sid_id, 'Groups');
				v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
				security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_api), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				security.security_pkg.SetApp(null);
			END;
		END;
		
	END LOOP;
	security.user_pkg.LogOff(v_act);
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_pkg
@../measure_pkg

@../factor_body
@../measure_body

@update_tail
