-- Please update version.sql too -- this keeps clean builds in sync
define version=1921
@update_header

SET DEFINE OFF;
BEGIN
	UPDATE csr.std_factor
	   SET value = 2.6569
	 WHERE std_factor_id = 184324208;

	UPDATE csr.std_factor
	   SET value = 2.6769
	 WHERE std_factor_id = 184324792;

	UPDATE csr.std_factor
	   SET value = 0.0000428571
	 WHERE std_factor_id = 184324500;

	UPDATE csr.std_factor
	   SET value = 0.0000616129
	 WHERE std_factor_id = 184325084;
END;
/

@update_tail