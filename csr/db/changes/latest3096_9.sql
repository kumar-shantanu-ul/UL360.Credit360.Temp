-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scrag_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scrag_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table => 'csr.scrag_queue'
	);
	COMMIT;
END;
/
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scragpp_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scragpp_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table => 'csr.scragpp_queue'
	);
	COMMIT;
END;
/
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.est_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.est_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table => 'csr.est_queue'
	);
	COMMIT;
END;
/

drop type csr.t_scrag_queue_entry;
drop type csr.t_batch_job_queue_entry;
drop type csr.t_est_queue_entry;

drop package aspen2.timezone_pkg;
drop TABLE ASPEN2.TIMEZONES_MAP_CLDR_TO_WIN;
drop TABLE ASPEN2.TIMEZONES_WIN_TO_CLDR;

-- *** Grants ***
exec dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', '255.255.255.255:998', 'connect,resolve' );

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***
	
-- *** Packages ***
@../batch_trigger_vsel
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../energy_star_job_pkg
@../energy_star_job_body
@../batch_job_body
@../degreedays_body
@../user_report_body

@update_tail
