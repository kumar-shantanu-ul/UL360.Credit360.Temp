-- Please update version.sql too -- this keeps clean builds in sync
define version=3409
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

SET SERVEROUTPUT ON
BEGIN
	FOR o IN (
		SELECT object_type, owner, object_name
		  FROM all_objects
		 WHERE (object_type = 'VIEW' AND (
					(owner = 'CMS' AND object_name IN ('ITEM_DESCRIPTION_15412849','ITEM_DESCRIPTION_15940801','ITEM_DESCRIPTION_28621458') OR
					(owner = 'MCDSC_FORMS_STAGE2' AND object_name = 'PALM_VIEW')))
				)
			OR (object_type = 'PACKAGE' AND owner = 'MCDSC_FORMS_SANDBOX' AND object_name = 'IMPORT_CMS_PKG')
	)
	LOOP
		dbms_output.put_line('Dropping '||o.object_type||' '||o.owner||'.'||o.object_name||'...');
		EXECUTE IMMEDIATE 'DROP '||o.object_type||' '||o.owner||'.'||o.object_name;
	END LOOP;
END;
/

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
