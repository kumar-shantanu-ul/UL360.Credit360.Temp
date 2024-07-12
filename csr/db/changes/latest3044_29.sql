-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.higg_config_module ADD score_type_id NUMBER(10);
ALTER TABLE csrimp.higg_config_module ADD score_type_id NUMBER(10);

ALTER TABLE chain.higg_module ADD score_type_lookup_key VARCHAR2(255);
ALTER TABLE chain.higg_module ADD score_type_format_mask VARCHAR2(20);

-- *** Grants ***
grant execute on chain.higg_setup_pkg to csr;

-- ** Cross schema constraints ***
ALTER TABLE chain.higg_config_module ADD CONSTRAINT FK_HIGG_MODULE_SCORE_TYPE_ID
    FOREIGN KEY (app_sid, score_type_id)
 REFERENCES csr.score_type(app_sid, score_type_id);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_social_score_type_lookup 		VARCHAR2(255) := 'HIGG_SOCIAL_SCORE';
	v_social_module_id 				NUMBER(10) := 5;
	v_social_format_mask			VARCHAR2(20) := '0';
	v_env_score_type_lookup 		VARCHAR2(255) := 'HIGG_ENV_SCORE';
	v_env_module_id 				NUMBER(10) := 6;
	v_env_format_mask				VARCHAR2(20) := '0';
BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE chain.higg_module
	   SET score_type_lookup_key = v_social_score_type_lookup,
		   score_type_format_mask = v_social_format_mask
	 WHERE higg_module_id = v_social_module_id;

	UPDATE chain.higg_module
	   SET score_type_lookup_key = v_env_score_type_lookup,
		   score_type_format_mask = v_env_format_mask
	 WHERE higg_module_id = v_env_module_id;

	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.higg_config
	)
	LOOP
		BEGIN
			INSERT INTO csr.score_type (app_sid, score_type_id, label, pos, hidden, allow_manual_set, lookup_key,
					applies_to_supplier, reportable_months, format_mask, ask_for_comment,
					applies_to_surveys, applies_to_non_compliances, applies_to_regions, applies_to_audits,
					min_score, max_score, start_score, normalise_to_max_score)
			VALUES (r.app_sid, csr.score_type_id_seq.nextval, 'Higg Social score', 0, 0, 0, v_social_score_type_lookup,
					1, 12, v_social_format_mask, 'none', 0, 0, 0, 1, NULL, NULL, 0, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO csr.score_type (app_sid, score_type_id, label, pos, hidden, allow_manual_set, lookup_key,
					applies_to_supplier, reportable_months, format_mask, ask_for_comment,
					applies_to_surveys, applies_to_non_compliances, applies_to_regions, applies_to_audits,
					min_score, max_score, start_score, normalise_to_max_score)
			VALUES (r.app_sid, csr.score_type_id_seq.nextval, 'Higg Social score', 0, 0, 0, v_env_score_type_lookup,
					1, 12, v_env_format_mask, 'none', 0, 0, 0, 1, NULL, NULL, 0, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	FOR r IN (
		SELECT hcm.app_sid, hcm.higg_config_id, hcm.higg_module_id, st.score_type_id
		  FROM chain.higg_config_module hcm
		  JOIN chain.higg_module hm ON hcm.higg_module_id = hm.higg_module_id
		  JOIN csr.score_type st ON st.lookup_key = hm.score_type_lookup_key AND st.app_sid = hcm.app_sid
	) LOOP
		UPDATE chain.higg_config_module
		   SET score_type_id = r.score_type_id
		 WHERE higg_module_id = r.higg_module_id
		   AND higg_config_id = r.higg_config_id
		   AND app_sid = r.app_sid;
	END LOOP;
END;
/

ALTER TABLE chain.higg_module MODIFY score_type_lookup_key NOT NULL;
ALTER TABLE chain.higg_config_module MODIFY score_type_id NOT NULL;
ALTER TABLE csrimp.higg_config_module MODIFY score_type_id NOT NULL;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/higg_pkg
@../chain/higg_setup_pkg

@../enable_body
@../chain/higg_body
@../chain/higg_setup_body
@../schema_body
@../csrimp/imp_body

@update_tail
