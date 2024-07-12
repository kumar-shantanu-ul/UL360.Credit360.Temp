-- Please update version.sql too -- this keeps clean builds in sync
define version=3446
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.std_factor_set ADD (
	info_note 			CLOB
);

ALTER TABLE csr.custom_factor_set ADD (
	info_note 			CLOB
);

ALTER TABLE csr.factor_type ADD (
	info_note 			CLOB
);

ALTER TABLE csrimp.custom_factor_set ADD (
	info_note 			CLOB
);

DECLARE 
v_max_is_id NUMBER;
v_next NUMBER;
BEGIN
	security.user_pkg.logonadmin;
	
	SELECT NVL(MAX(factor_set_group_id), 1)
	  INTO v_max_is_id
	  FROM csr.factor_set_group;
	
	SELECT csr.factor_set_grp_id_seq.NEXTVAL
	  INTO v_next
	  FROM dual;

	EXECUTE IMMEDIATE 'ALTER SEQUENCE csr.factor_set_grp_id_seq INCREMENT BY ' || (v_max_is_id - v_next);
	
	SELECT csr.factor_set_grp_id_seq.NEXTVAL
	  INTO v_max_is_id
	  FROM dual;
	
	EXECUTE IMMEDIATE 'ALTER SEQUENCE csr.factor_set_grp_id_seq INCREMENT BY 1';
END;
/

DECLARE 
v_max_is_id NUMBER;
v_next NUMBER;
BEGIN
	security.user_pkg.logonadmin;
	
	SELECT NVL(MAX(std_factor_id), 1)
	  INTO v_max_is_id
	  FROM csr.std_factor;
	
	SELECT csr.std_factor_id_seq.NEXTVAL
	  INTO v_next
	  FROM dual;

	EXECUTE IMMEDIATE 'ALTER SEQUENCE csr.std_factor_id_seq INCREMENT BY ' || (v_max_is_id - v_next);
	
	SELECT csr.std_factor_id_seq.NEXTVAL
	  INTO v_max_is_id
	  FROM dual;
	
	EXECUTE IMMEDIATE 'ALTER SEQUENCE csr.std_factor_id_seq INCREMENT BY 1';
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$factor_type
AS 
  SELECT f.factor_type_id, f.parent_id, f.name, f.info_note, f.std_measure_id, f.egrid, af.active, uf.in_use, mf.mapped, f.enabled
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_pkg
@../factor_set_group_pkg

@../factor_body
@../factor_set_group_body
@../schema_body
@../csrimp/imp_body

@update_tail
