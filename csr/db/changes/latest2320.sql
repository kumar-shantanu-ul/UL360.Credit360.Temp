-- Please update version.sql too -- this keeps clean builds in sync
define version=2320
@update_header

	UPDATE CSR.std_measure_conversion
       SET a 				= 10000, 
		   std_measure_id 	= 29
	 WHERE std_measure_conversion_id = 28124;

@update_tail