-- Please update version.sql too -- this keeps clean builds in sync
define version=1179
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	FROM all_constraints
	WHERE constraint_name = 'CHK_DATAVIEW_INCL_PAR_REG' AND owner = 'CSRIMP' AND table_name = 'DATAVIEW';

	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.dataview DROP CONSTRAINT chk_dataview_incl_par_reg';
	END IF;
END;
/

@update_tail
