define version=3447
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE CSR.ISSUE_ACTION_LOG ADD (
	IS_PUBLIC					NUMBER(1, 0),
	INVOLVED_USER_SID			NUMBER(10, 0),
	INVOLVED_USER_SID_REMOVED	NUMBER(10, 0)
);
ALTER TABLE CSRIMP.ISSUE_ACTION_LOG ADD (
	IS_PUBLIC					NUMBER(1, 0),
	INVOLVED_USER_SID			NUMBER(10, 0),
	INVOLVED_USER_SID_REMOVED	NUMBER(10, 0)
);
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
DROP TABLE CSRIMP.CHAIN_BSCI_OPTIONS;
DROP TABLE CSRIMP.CHAIN_BSCI_SUPPLIER;
DROP TABLE CSRIMP.CHAIN_BSCI_SUPPLIER_DET;
DROP TABLE CSRIMP.CHAIN_BSCI_AUDIT;
DROP TABLE CSRIMP.CHAIN_BSCI_2009_AUDIT;
DROP TABLE CSRIMP.CHAIN_BSCI_2009_A_FINDING;
DROP TABLE CSRIMP.CHAIN_BSCI_2009_A_ASSOCIATE;
DROP TABLE CSRIMP.CHAIN_BSCI_2014_AUDIT;
DROP TABLE CSRIMP.CHAIN_BSCI_2014_A_FINDING;
DROP TABLE CSRIMP.CHAIN_BSCI_2014_A_ASSOCIATE;
DROP TABLE CSRIMP.CHAIN_BSCI_EXT_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_SUPPLIER;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2009_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2014_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_EXT_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2009_A_FIND;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2009_A_ASSOC;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2014_A_FIND;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2014_A_ASSOC;
DROP TABLE CHAIN.BSCI_OPTIONS;






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




BEGIN
	BEGIN
		INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) 
			VALUES (13,'Issues',6);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) 
		VALUES (25/*CSR.CSR_DATA_PKG.IAT_IS_PUBLIC_CHANGED*/, 'Public status changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) 
		VALUES (26/*CSR.CSR_DATA_PKG.IAT_INVOLVED_USER_ASSIGNED*/, 'Involved user assigned');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) 
		VALUES (27/*CSR.CSR_DATA_PKG.IAT_INVOLVED_USER_SID_REMOVED*/, 'Involved user removed');
END;
/
declare
   job_doesnt_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT( job_doesnt_exist, -27475 );
begin
   dbms_scheduler.drop_job(job_name => 'chain.BsciImport');
exception when job_doesnt_exist then
   null;
end;
/






@..\delegation_pkg
@..\csr_data_pkg
@..\issue_pkg
@..\factor_pkg
@..\factor_set_group_pkg
@..\chain\bsci_pkg
@..\csrimp\imp_pkg
@..\schema_pkg


@..\delegation_body
@..\csrimp\imp_body
@..\issue_body
@..\schema_body
@..\factor_body
@..\factor_set_group_body
@..\user_report_body
@..\chain\bsci_body
@..\chain\chain_body
@..\sheet_report_body



@update_tail
