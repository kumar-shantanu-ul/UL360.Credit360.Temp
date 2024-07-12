-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=34
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

BEGIN
	INSERT INTO chain.filter_type (filter_type_id, description, helper_pkg, card_id ) 
	SELECT chain.filter_type_id_seq.NEXTVAL, 'Chain Company Cms Filter', 'chain.company_filter_pkg', card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyCmsFilterAdapter');
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE chain.filter_type
		   SET description = 'Chain Company Cms Filter',
			   helper_pkg = 'chain.company_filter_pkg'
		 WHERE card_id IN (
		 	SELECT card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyCmsFilterAdapter'));
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
