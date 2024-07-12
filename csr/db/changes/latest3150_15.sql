-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=15
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
DECLARE
	v_card_id		NUMBER(10);
BEGIN
	-- log off first
	security.user_pkg.LogonAdmin;
	
	SELECT MIN(card_id)
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Region.Filters.RegionFilter';
	
	-- disable region filter card for sites that aren't using it
	-- as its slowing page loads down a lot
	DELETE FROM chain.card_group_card
	 WHERE card_id = v_card_id
	   AND app_sid NOT IN (
		SELECT f.app_sid
		  FROM chain.filter_type ft
		  JOIN chain.filter f ON ft.filter_type_id = f.filter_type_id
		 WHERE ft.card_id = v_card_id
		 UNION
		SELECT fic.app_sid
		  FROM chain.filter_item_config fic
		 WHERE LOWER(fic.item_name) LIKE 'regionfilter%'
		   AND fic.include_in_filter = 1
	);
END;
/

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (101, 'Extended region filtering', 'EnableRegionFiltering', 'Enable region filtering adapters on CMS and compliance pages, to allow filtering records by fields on a region. NOTE: This is disabled by default as it can have a significant impact on the page load times, especially for sites with large numbers of tags/tag groups.');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
