-- Please update version.sql too -- this keeps clean builds in sync
define version=527
@update_header

DECLARE
	v_count					NUMBER(10);
	v_id					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor_type
	 WHERE name = 'Factor types';
	
	IF (v_count = 0) THEN
		INSERT INTO factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
			values(factor_type_id_seq.nextval, NULL, 'Factor types', NULL, 0);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor_type
	 WHERE name = 'Unspecified';
	
	IF (v_count = 0) THEN
		SELECT factor_type_id
		  INTO v_id
		  FROM factor_type
		 WHERE name = 'Factor types';
	 
		INSERT INTO factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
			values(factor_type_id_seq.nextval, v_id, 'Unspecified', 1, 0);
	END IF;
END;
/

@update_tail


