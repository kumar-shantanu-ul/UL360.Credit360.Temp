-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
 ALTER TABLE csr.approval_dashboard_ind
RENAME COLUMN hidden_dtm TO deactivated_dtm;

 ALTER TABLE csrimp.approval_dashboard_ind
RENAME COLUMN hidden_dtm TO deactivated_dtm;

ALTER TABLE csr.approval_dashboard_ind
ADD is_hidden NUMBER(1) DEFAULT 0 NOT NULL; 

ALTER TABLE csrimp.approval_dashboard_ind
ADD is_hidden NUMBER(1) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
/* Eurgh, this isn't nice, but needs to be done. I messed up the date format on the inputs for this so the month and day are the wrong way around. This is
   causing issues in .net because the format is wrong, ie 2015-29-01 is the 29th january, but it wants YYYY-MM-DD and ther isn't a 29th month...
   So I've got to try and convert them. Same release fixes the format going in, so we only need to do this once
*/
DECLARE
	v_dtm		DATE;
	v_is_date	NUMBER;
BEGIN
 
	FOR r IN (
		SELECT source_detail, approval_dashboard_val_id, id
		  FROM csr.approval_dashboard_val_src
	)
	LOOP
	
		BEGIN
			-- Try the broken date format first so that we catch any which don't fail but are still wrong 
			v_dtm := TO_DATE(r.source_detail, 'yyyy-dd-mm hh24:mi:ss');
			v_is_date := 1;
		EXCEPTION WHEN others THEN
			-- Try the default
			BEGIN
			-- Try the broken date format first so that we catch any which don't fail but are still wrong 
				v_dtm := TO_DATE(r.source_detail, 'yyyy-dd-mm hh24:mi:ss');
				v_is_date := 1;
			EXCEPTION WHEN others THEN
				-- It's not a date, so we'll leave it alone
				v_is_date := 0;
			END;
		END;

		IF v_is_date = 1 THEN
			-- Write it back
			UPDATE csr.approval_dashboard_val_src
			   SET source_detail = to_char(v_dtm, 'yyyy-mm-dd hh24:mi:ss')
			 WHERE approval_dashboard_val_id = r.approval_dashboard_val_id
			   AND id = r.id
			   AND source_detail = r.source_detail;
		END IF;
  
	END LOOP;

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\approval_dashboard_pkg
@..\approval_dashboard_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
