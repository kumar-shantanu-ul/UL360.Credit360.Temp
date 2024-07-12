-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(
		'XXX_BSCI_SUPPLIER',
		'XXX_BSCI_AUDIT'
    );
	v_count			number(10);
BEGIN
	FOR i IN 1 .. v_list.COUNT
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM all_tables
		 WHERE owner = 'CHAIN'
		   AND table_name = UPPER(v_list(i));
		IF v_count = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE CHAIN.'||v_list(i)||' CASCADE CONSTRAINTS';
		END IF;
	END LOOP;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/bsci_body

@update_tail
