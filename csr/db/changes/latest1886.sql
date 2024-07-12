--Please update version.sql too -- this keeps clean builds in sync
define version=1886
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'DONATIONS'
	   AND table_name = 'CUSTOMER_OPTIONS'
	   AND column_name = 'FC_GRID_DEF_SORT_COLUMN';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE donations.customer_options ADD fc_grid_def_sort_column VARCHAR2(40)';
	END IF;
END;
/

@..\donations\options_body

@update_tail
