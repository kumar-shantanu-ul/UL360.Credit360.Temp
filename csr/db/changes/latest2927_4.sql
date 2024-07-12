-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

update chain.filter_value dest
   set (num_value, str_value, filter_type) = (
	  select regexp_substr(str_value, '^([0-9]+)_', 1, 1, null, 1), null, 1
		from chain.v$filter_value src
	   where dest.app_sid = src.app_sid
		 and dest.filter_value_id = src.filter_value_id) 
 where regexp_like(str_value, '^([0-9]+)_')
   and exists(
	  select * 
		from chain.filter_field ff
	   where ff.name = 'MeterType'
		 and ff.app_sid = dest.app_sid
		 and ff.filter_field_id = dest.filter_field_id);

update chain.filter_value dest
   set (num_value, str_value, filter_type) = (
	  select str_value, null, 1
		from chain.v$filter_value src
	   where dest.app_sid = src.app_sid
		 and dest.filter_value_id = src.filter_value_id) 
 where regexp_like(str_value, '^([0-9]+)$')
   and exists(
	  select * 
		from chain.filter_field ff
	   where ff.name = 'MeterType'
		 and ff.app_sid = dest.app_sid
		 and ff.filter_field_id = dest.filter_field_id);

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_report_pkg
@../meter_report_body

@update_tail
