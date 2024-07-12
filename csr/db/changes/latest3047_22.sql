-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_is_nullable		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'SCORE_TYPE'
	   AND column_name = 'APPLIES_TO_SURVEYS'
	   AND nullable = 'Y';
	
	IF v_is_nullable > 0 THEN
		UPDATE csr.score_type
		   SET applies_to_surveys = 0
		 WHERE applies_to_surveys IS NULL;
	
		EXECUTE IMMEDIATE 'ALTER TABLE csr.score_type MODIFY applies_to_surveys DEFAULT 0 NOT NULL';
	END IF;

	SELECT COUNT(*)
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'SCORE_TYPE'
	   AND column_name = 'APPLIES_TO_SURVEYS'
	   AND nullable = 'Y';
	
	IF v_is_nullable > 0 THEN
		UPDATE csrimp.score_type
		   SET applies_to_surveys = 0
		 WHERE applies_to_surveys IS NULL;
	
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.score_type MODIFY applies_to_surveys NOT NULL';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'SCORE_TYPE'
	   AND column_name = 'APPLIES_TO_NON_COMPLIANCES'
	   AND nullable = 'Y';
	
	IF v_is_nullable > 0 THEN
		UPDATE csr.score_type
		   SET applies_to_non_compliances = 0
		 WHERE applies_to_non_compliances IS NULL;
	
		EXECUTE IMMEDIATE 'ALTER TABLE csr.score_type MODIFY applies_to_non_compliances DEFAULT 0 NOT NULL';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'SCORE_TYPE'
	   AND column_name = 'APPLIES_TO_NON_COMPLIANCES'
	   AND nullable = 'Y';
	
	IF v_is_nullable > 0 THEN
		UPDATE csrimp.score_type
		   SET applies_to_non_compliances = 0
		 WHERE applies_to_non_compliances IS NULL;
	
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.score_type MODIFY applies_to_non_compliances NOT NULL';
	END IF;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
