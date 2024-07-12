-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=18
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

-- Set the correct meter source type on all non-urjanet meters 
-- that have inadvertently picked up the start date kludge type
DECLARE
	v_arb_period	NUMBER(10);
	v_cnt			NUMBER(10);
BEGIN
	FOR c IN (
		SELECT DISTINCT c.app_sid, c.host, st.meter_source_type_id
		  FROM csr.meter_source_type st
		  JOIN csr.customer c ON c.app_sid = st.app_sid
		 WHERE st.allow_null_start_dtm = 1
	) LOOP
		
		security.user_pkg.logonadmin(c.host);

		SELECT COUNT(*) 
		  INTO v_cnt
		  FROM csr.meter_source_type
		 WHERE name = 'period';

		IF v_cnt > 0 THEN
			SELECT DISTINCT meter_source_type_id
			  INTO v_arb_period
			  FROM csr.meter_source_type
			 WHERE name = 'period';
			
			UPDATE csr.all_meter
			   SET meter_source_type_id = v_arb_period
			 WHERE app_sid = c.app_sid
			   AND meter_source_type_id =  c.meter_source_type_id
			   AND urjanet_meter_id IS NULL;
		END IF;

		security.user_pkg.logonadmin;

	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../meter_pkg
@../meter_body

@update_tail
