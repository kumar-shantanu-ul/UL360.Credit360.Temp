-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- remove dupes before adding unique constraint
BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT app_sid, filter_id, filter_field_id
		  FROM (
			SELECT app_sid, filter_id, filter_field_id, ROW_NUMBER() OVER (PARTITION BY app_sid, filter_id, name ORDER BY app_sid, filter_id, filter_field_id) rn
			  FROM chain.filter_field
		)
		 WHERE rn > 1
	) LOOP
		-- This cascade deletes the filter values
		DELETE FROM chain.filter_field
		 WHERE filter_field_id = r.filter_field_id
		   AND app_sid = r.app_sid;

		-- reshuffle group by indexes so there aren't any gaps
		FOR ff IN (
			SELECT filter_field_id, ROWNUM rn
			  FROM chain.filter_field
			 WHERE filter_id = r.filter_id
			   AND app_sid = r.app_sid
			   AND group_by_index IS NOT NULL
			 ORDER BY group_by_index
		) LOOP
			UPDATE chain.filter_field
			   SET group_by_index = ff.rn
			 WHERE filter_field_id = ff.filter_field_id
			   AND app_sid = r.app_sid;
		END LOOP;
	END LOOP;
END;
/

ALTER TABLE chain.filter_field ADD CONSTRAINT uk_filter_field_name UNIQUE (app_sid, filter_id, name);

ALTER TABLE chain.compound_filter ADD (
	read_only_saved_filter_sid			NUMBER(10),
	is_read_only_group_by				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_comp_fltr_is_ro_grp_by_1_0 CHECK (is_read_only_group_by IN (1, 0)),
	CONSTRAINT fk_comp_fltr_ro_saved_fltr FOREIGN KEY (app_sid, read_only_saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);

create index chain.ix_compound_filt_read_only_sav on chain.compound_filter (app_sid, read_only_saved_filter_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Clean up duplicate filter values
	DELETE FROM chain.filter_value fv
	 WHERE EXISTS (
		SELECT app_sid, filter_value_id 
		  FROM (
			SELECT app_sid, filter_value_id, 
				   ROW_NUMBER() OVER 
				   (PARTITION BY app_sid, filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid, user_sid, min_num_val, 
				    max_num_val, compound_filter_id_value, saved_filter_sid_value, period_set_id, period_interval_id, start_period_id, filter_type, null_filter 
					ORDER BY app_sid, filter_value_id) rn
			 FROM chain.filter_value
		 )
	 	 WHERE rn > 1 
		   AND app_sid = fv.app_sid 
		   AND filter_value_id = fv.filter_value_id
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/filter_body
@../chain/filter_body
@../chain/chain_body
@../schema_body

@update_tail
