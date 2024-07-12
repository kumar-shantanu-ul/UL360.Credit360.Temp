-- Please update version.sql too -- this keeps clean builds in sync
define version=3157
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(
		'TAB_DESCRIPTION',
		'TAB_PORTLET_DESCRIPTION'
    );
	v_count			number(10);
BEGIN
	FOR i IN 1 .. v_list.COUNT
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM all_tables
		 WHERE owner = 'CSR'
		   AND table_name = UPPER(v_list(i));
		IF v_count = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE CSR.'||v_list(i)||' CASCADE CONSTRAINTS';
		END IF;
	END LOOP;
END;
/

DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(
		'TAB_DESCRIPTION',
		'TAB_PORTLET_DESCRIPTION'
    );
	v_count			number(10);
BEGIN
	FOR i IN 1 .. v_list.COUNT
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM all_tables
		 WHERE owner = 'CSRIMP'
		   AND table_name = UPPER(v_list(i));
		IF v_count = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE CSRIMP.'||v_list(i)||' CASCADE CONSTRAINTS';
		END IF;
	END LOOP;
END;
/
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$tab_user AS
  SELECT t.tab_id, t.app_sid, t.layout, t.name, t.is_shared, t.is_hideable, t.override_pos, tu.user_sid, tu.pos, tu.is_owner, tu.is_hidden, t.portal_group
	FROM tab t, tab_user tu
   WHERE t.tab_id = tu.tab_id;

 -- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../portlet_pkg
@../portlet_body
@../enable_body
@../schema_pkg
@../schema_body
@../csr_app_pkg
@../csr_app_body
@../csrimp/imp_body

@update_tail
