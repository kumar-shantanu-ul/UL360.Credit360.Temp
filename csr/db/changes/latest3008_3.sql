-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=3
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
	INSERT INTO csr.util_script (
	  util_script_id, util_script_name, description, util_script_sp, wiki_article
	) VALUES (
	  28, 'Clear last used measure conversions', 'Clears all last used measure conversions for the specified user. See wiki about functioning of last used measure conversion.',
	  'ClearLastUsdMeasureConversions', 'W1179'
	);
	INSERT INTO csr.util_script_param (
	  util_script_id, param_name, param_hint, pos
	) VALUES (
	  28, 'User SID', 'SID', 0
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
