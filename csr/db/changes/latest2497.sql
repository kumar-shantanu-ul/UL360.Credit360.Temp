-- Please update version.sql too -- this keeps clean builds in sync
define version=2497
@update_header

UPDATE csr.calculation_type
   SET description = 'Rolling 12 month total'
 WHERE calculation_type_id = 7 
   AND description = 'Rolling 12 months';

BEGIN
	INSERT INTO csr.calculation_type (
	  calculation_type_id, description
	) values (
	  11, 'Rolling 12 month average'
	);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail
