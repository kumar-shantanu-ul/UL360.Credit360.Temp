-- Please update version.sql too -- this keeps clean builds in sync
define version=1395
@update_header

-- I've inserted this into the live db already as other update
-- scripts haven't been run yet. The delete will make sure the latest
-- still runs ok on live and updates the version num.
-- If it can't be deleted, ignore - the measure exists, there's no need to insert it.
BEGIN
	DELETE FROM csr.std_measure_conversion
	 WHERE description = 'g/t';
  
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (26163,1,'g/t',1000000,1,0);
EXCEPTION WHEN OTHERS THEN
	NULL;
END;
/

@update_tail