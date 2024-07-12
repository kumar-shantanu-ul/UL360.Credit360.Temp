-- Please update version.sql too -- this keeps clean builds in sync
define version=1705
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

BEGIN
	UPDATE csr.factor_type
	SET std_measure_id =
	CASE
	  WHEN std_measure_id = 3 THEN 2
	  WHEN std_measure_id = 17 THEN 9
	  WHEN std_measure_id = 19 THEN 10
	  WHEN std_measure_id = 33 THEN 8
	  ELSE std_measure_id
	END
	WHERE factor_type_id > 7174;

	COMMIT;
END;
/

@update_tail


