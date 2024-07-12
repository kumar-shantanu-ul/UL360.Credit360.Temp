-- Please update version.sql too -- this keeps clean builds in sync
define version=3220
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	/*
	Expected working sites are:
		-- biogen.credit360.com
		-- lendleasefootprint.credit360.com
		-- hyatt.credit360.com
	
	Leaving pilot sites as is:
		--'lendlease-pilot.credit360.com',
		--'vattenfall-pilot.credit360.com',
		--'biogen-copy.credit360.com',
		--'metrogroup-pilot.credit360.com',
		--'psjh-pilot.credit360.com',
		--'capitaland-pilot.credit360.com',
		--'volvocars-pilot.credit360.com',
		--'tesla-pilot.credit360.com',
	*/
	FOR r IN (SELECT app_sid FROM csr.customer WHERE name IN (
		'prop.credit360.com',
		'chandra-liyanage-demo.credit360.com',
		'bdclone.credit360.com',
		'phyllis-davies.credit360.com',
		'tinabean.credit360.com',
		'rs-prop.credit360.com',
		'msdemo.credit360.com',
		'jk-prop1.credit360.com',
		'shsusdemo.credit360.com',
		'lenanewkold.credit360.com',
		'mmdemo.credit360.com',
		'ambermehta.credit360.com',
		'sam-mw.credit360.com',
		'kimberly-ake-demo.credit360.com',
		'andreacoberly.credit360.com',
		'latamclone.credit360.com',
		'jmsusdemo.credit360.com',
		'salmanrashid.credit360.com',
		'amsusdemo.credit360.com'))
	LOOP
		UPDATE csr.Degreeday_Settings
		   SET download_enabled = 0
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
