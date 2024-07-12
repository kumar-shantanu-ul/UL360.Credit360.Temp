-- Please update version.sql too -- this keeps clean builds in sync
define version=3180
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_exists			NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_constraints
	 WHERE owner = 'CHAIN'
	   AND constraint_name = 'CHK_SUPP_REL_SRC_TYPE';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE ('ALTER TABLE chain.supplier_relationship_source DROP CONSTRAINT CHK_SUPP_REL_SRC_TYPE');
	END IF;
END;
/

ALTER TABLE chain.supplier_relationship_source
  ADD CONSTRAINT CHK_SUPP_REL_SRC_TYPE CHECK (source_type IN (0, 1, 2, 3));

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
@../chain/chain_pkg

@../chain/chain_body
@../chain/business_relationship_body

@update_tail
