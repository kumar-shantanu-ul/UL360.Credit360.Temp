-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=16
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
	v_card_id	NUMBER(10);
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Property.Filters.PropertyIssuesFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Property Issues Filter', 'csr.property_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***


@update_tail
