-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.custom_factor 
ADD ( region_sid	NUMBER(10, 0) );

ALTER TABLE csrimp.custom_factor 
ADD ( region_sid	NUMBER(10, 0) );
 
ALTER TABLE csr.emission_factor_profile
MODIFY (start_dtm NULL, applied DEFAULT 0);

ALTER TABLE csr.emission_factor_profile_factor
DROP CONSTRAINT PK_EMISSION_FCTR_PROFILE_FCTR DROP INDEX;

ALTER TABLE csr.emission_factor_profile_factor
ADD CONSTRAINT UK_EMISSION_FCTR_PROFILE_FCTR UNIQUE (app_sid,
	profile_id,
	factor_type_id,
	std_factor_set_id,
	custom_factor_set_id,
	region_sid,
	geo_country,
	geo_region,
	egrid_ref);
	
ALTER TABLE csrimp.emission_factor_profile
MODIFY (start_dtm NULL);

ALTER TABLE csrimp.emission_factor_profile_factor
DROP CONSTRAINT PK_EMISSION_FCTR_PROFILE_FCTR DROP INDEX;

ALTER TABLE csrimp.emission_factor_profile_factor
ADD CONSTRAINT UK_EMISSION_FCTR_PROFILE_FCTR UNIQUE (csrimp_session_id,
	profile_id,
	factor_type_id,
	std_factor_set_id,
	custom_factor_set_id,
	region_sid,
	geo_country,
	geo_region,
	egrid_ref);
	
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$factor_type AS
SELECT f.factor_type_id, f.parent_id, f.name, f.std_measure_id, f.egrid, af.active, uf.in_use, decode(i.factor_type_id, NULL, 0, 1) mapped
  FROM csr.factor_type f
  LEFT JOIN (SELECT DISTINCT factor_type_id FROM csr.ind) i ON f.factor_type_id = i.factor_type_id
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
          SELECT 3 factor_type_id
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
      SELECT 3 factor_type_id
        FROM dual
    )) uf ON f.factor_type_id = uf.factor_type_id;

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) 
VALUES (1, 28, 'Factor');

UPDATE csr.std_factor_set SET factor_set_group_id = 16 WHERE std_factor_set_id in (65, 66);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_data_pkg
@../region_pkg
@../factor_pkg

@../region_body
@../factor_body
@../schema_body

@../csrimp/imp_body

@update_tail
