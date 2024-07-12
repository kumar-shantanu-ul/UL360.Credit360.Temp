-- Please update version.sql too -- this keeps clean builds in sync
define version=2877
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_exists	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND constraint_name = 'UK_AGG_IND_GRP_NAME';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.aggregate_ind_group DROP CONSTRAINT uk_agg_ind_grp_name';
	END IF;

	-- local db has unique index but it is not on live
	v_exists := 0;
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'UK_AGGR_IND_GROUP';
  
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX csr.uk_aggr_ind_group ON csr.aggregate_ind_group (app_sid, UPPER(name))';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
