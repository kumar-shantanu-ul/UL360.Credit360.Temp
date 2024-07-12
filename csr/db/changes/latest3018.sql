-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
begin
	for r in (
		select distinct app_sid, dataview_sid
		  from csr.dataview_trend) loop
		for s in (
			SELECT rowid rid, name, title, ind_sid, region_sid, months, rounding_method, rounding_digits, rownum rn
			  FROM csr.dataview_trend
			 WHERE app_sid = r.app_sid and dataview_sid = r.dataview_sid) loop
			 update csr.dataview_trend
			    set pos = s.rn
			  where rowid = s.rid;
		end loop;
	end loop;
end;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
