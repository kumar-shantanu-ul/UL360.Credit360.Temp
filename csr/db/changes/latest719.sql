-- Please update version.sql too -- this keeps clean builds in sync
define version=719
@update_header

BEGIN
	INSERT INTO csr.source_type (source_type_id, description)
	  VALUES (10, 'Real-time meter');
END;
/	

@../csr_data_pkg
@../meter_monitor_pkg
@../meter_monitor_body

@update_tail
