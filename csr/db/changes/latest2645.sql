-- Please update version.sql too -- this keeps clean builds in sync
define version=2645
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT execute ON csr.section_tree_pkg TO web_user;
-- ** Cross schema constraints ***

-- *** Views ***

-- *** Jobs ***

-- FB66032 - use correct owner for user_pkg
DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_check
	  FROM sys.dba_scheduler_jobs
	 WHERE OWNER = 'CSR'
	   AND JOB_NAME = 'CMSDATAIMPORT';

	IF v_check = 1 THEN
		DBMS_SCHEDULER.DROP_JOB(
			job_name =>   'CSR.CMSDATAIMPORT',
			force => TRUE
		);
		COMMIT;
	END IF;

	DBMS_SCHEDULER.CREATE_JOB (
		job_name        	=> 'CSR.CMSDATAIMPORT',
		job_type        	=> 'PLSQL_BLOCK',
		job_action      	=> '   
			BEGIN
				security.user_pkg.logonadmin();
				csr.cms_data_imp_pkg.ScheduleRun();
				COMMIT;
			END;
		',
		job_class       	=> 'low_priority_job',
		start_date      	=> SYSTIMESTAMP,
		repeat_interval 	=> 'FREQ=HOURLY',
		enabled         	=> TRUE,
		auto_drop       	=> FALSE,
		comments        	=> 'Cms data import schedule. Check for new imports to queue in batch jobs.'
	);
END;
/

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.capability 
   SET name = 'Can edit date locked logging forms' 
 WHERE name = 'Can edit logging form restricted or locked dates';
 
UPDATE security.securable_object 
   SET name = 'Can edit date locked logging forms' 
 WHERE name = 'Can edit logging form restricted or locked dates';

-- FB64444 Centrica ImageButton portlet
INSERT INTO csr.portlet(
	portlet_id,
	name,
	type,
	script_path)
VALUES(
	1054, 
	'Image button',
	'Credit360.Portlets.ImageButton',
	'/csr/site/portal/portlets/ImageButton.js');

-- *** Packages ***

@../audit_body
@../division_body

@update_tail