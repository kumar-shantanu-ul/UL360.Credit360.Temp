-- Please update version.sql too -- this keeps clean builds in sync
define version=1937
@update_header


DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_tab_cols
	 WHERE owner ='CSR' 
	   AND table_name='EST_BUILDING'
	   AND column_name = 'MISSING';
	
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE '
		ALTER TABLE CSR.EST_BUILDING ADD (
		    MISSING           NUMBER(1, 0)      DEFAULT 0 NOT NULL,
		    CHECK (MISSING IN(0,1))
		)';
	END IF;
END;
/


@../energy_star_pkg
@../energy_star_body

@update_tail
