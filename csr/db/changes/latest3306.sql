define version=3306
define minor_version=0
define is_combined=1
@update_header

set serveroutput on

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

BEGIN
	FOR r IN (
		SELECT owner
		  FROM all_constraints
		 WHERE owner IN ('CSR','CSRIMP')
		   AND table_name = 'IND'
		   AND constraint_name = 'CK_IND_AGGR'
		)
	LOOP
		dbms_output.put_line('Dropping constraint CK_IND_AGGR from '||r.owner||'.IND...');
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||'IND DROP CONSTRAINT CK_IND_AGGR';
	END LOOP;
END;
/

ALTER TABLE CSR.IND 
  ADD CONSTRAINT CK_IND_AGGR CHECK (aggregate IN ('SUM', 'FORCE SUM', 'AVERAGE', 'NONE', 'DOWN', 'FORCE DOWN', 'LOWEST', 'FORCE LOWEST', 'HIGHEST', 'FORCE HIGHEST'));
ALTER TABLE CSRIMP.IND 
  ADD CONSTRAINT CK_IND_AGGR CHECK (aggregate IN ('SUM', 'FORCE SUM', 'AVERAGE', 'NONE', 'DOWN', 'FORCE DOWN', 'LOWEST', 'FORCE LOWEST', 'HIGHEST', 'FORCE HIGHEST'));
ALTER TABLE CSR.CUSTOMER ADD PREVIEW_BETA_MENU NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_PREVIEW_BETA_MENU CHECK (PREVIEW_BETA_MENU IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD PREVIEW_BETA_MENU NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (PREVIEW_BETA_MENU DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_PREVIEW_BETA_MENU CHECK (PREVIEW_BETA_MENU IN (0,1));
DROP TABLE csr.enhesa_account;
ALTER TABLE csr.enhesa_options ADD (
	username	VARCHAR2(1024),
	password	VARCHAR2(1024)
);
ALTER TABLE csrimp.enhesa_options ADD (
	username	VARCHAR2(1024),
	password	VARCHAR2(1024)
);
  
  
  
ALTER TABLE CSR.DATA_BUCKET_VAL
DROP COLUMN VAL_KEY;
ALTER TABLE CSR.DATA_BUCKET_VAL
ADD VAL_KEY NUMBER(10);
ALTER TABLE CSR.DATA_BUCKET_SOURCE_DETAIL
DROP COLUMN VAL_KEY;
ALTER TABLE CSR.DATA_BUCKET_SOURCE_DETAIL
ADD VAL_KEY NUMBER(10) NOT NULL;










UPDATE security.securable_object 
   SET class_id = (
		SELECT class_id 
		  FROM security.securable_object_class 
		 WHERE class_name = 'CSRApp') 
 WHERE sid_id IN (
203969,
63132193,
638204,
713533,
2871935,
2043314,
1945714,
1846924,
1518185,
1542409,
1288503,
1223164
)
   AND class_id = (
		SELECT class_id 
		  FROM security.securable_object_class 
		 WHERE class_name = 'AspenApp');
UPDATE csr.enhesa_options SET username = 'ulehss', password = 'PwWn4Mx7kj1HmyIJQhAcYv3ONQWEhSjhZM4erjf1hKXKm8uks08pW2hC2uVVplYh' WHERE client_id = '632';
UPDATE csr.enhesa_options SET username = 'UL.Integration.Ingrammicro', password = 'ujXU9pDN7sfCjw3ieCTBBss2qtr0tcPiUxX7TmS36SK4MJ97iXlS133cYZwRsSwG' WHERE client_id = '784';
UPDATE csr.enhesa_options SET username = 'UL.Integration.Biogen', password = 'ujXU9pDN7sfCjw3ieCTBBss2qtr0tcPiUxX7TmS36SK4MJ97iXlS133cYZwRsSwG' WHERE client_id = '712';
UPDATE csr.enhesa_options SET username = 'UL.Integration.Centrica', password = 'ujXU9pDN7sfCjw3ieCTBBss2qtr0tcPiUxX7TmS36SK4MJ97iXlS133cYZwRsSwG' WHERE client_id = '674';
INSERT INTO csr.module_param (module_id, param_name, pos)
VALUES (80, 'ENHESA Username', 1);
INSERT INTO csr.module_param (module_id, param_name, pos)
VALUES (80, 'ENHESA Password', 2);
DELETE FROM csr.module_param WHERE module_id = 80 AND pos = 1;
DELETE FROM csr.module_param WHERE module_id = 80 AND pos = 2;






@..\region_api_pkg
@..\branding_pkg
@..\compliance_pkg
@..\enable_pkg
@..\data_bucket_pkg
@..\superadmin_api_pkg
@..\unit_test_pkg
GRANT EXECUTE ON csr.superadmin_api_pkg TO support_users;


@..\supplier_body
@..\audit_body
@..\issue_body
@..\indicator_body
@..\region_body
@..\region_api_body
@..\branding_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body
@..\compliance_body
@..\enable_body
@..\data_bucket_body
@..\aggregate_ind_body
@..\superadmin_api_body
@..\unit_test_body


@update_tail
