-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=49
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

-- Migrate Down
-- ALTER TABLE aspen2.translation_set         RENAME CONSTRAINT fk_lang_ts       TO RefLANG4;
-- ALTER TABLE aspen2.translated              RENAME CONSTRAINT fk_translated_ts TO RefTRANSLATION_SET3;
-- ALTER TABLE aspen2.translation_set_include RENAME CONSTRAINT fk_ts_to_tsi     TO RefTRANSLATION_SET6;
-- ALTER TABLE aspen2.translation_set_include RENAME CONSTRAINT fk_ts_tsi        TO RefTRANSLATION_SET7;

-- Migrate Up. Yuck. These were changed in create schema back in 2008, but never made it to any latest scripts. Until Now.
-- ALTER TABLE aspen2.translation_set         RENAME CONSTRAINT RefLANG4 TO fk_lang_ts;
-- ALTER TABLE aspen2.translated              RENAME CONSTRAINT RefTRANSLATION_SET3 TO fk_translated_ts;
-- ALTER TABLE aspen2.translation_set_include RENAME CONSTRAINT RefTRANSLATION_SET6 TO fk_ts_to_tsi;
-- ALTER TABLE aspen2.translation_set_include RENAME CONSTRAINT RefTRANSLATION_SET7 TO fk_ts_tsi;

DECLARE
	v_exists number;
	v_constraint_name varchar2(40);
BEGIN

	
	SELECT constraint_name
		INTO v_constraint_name
		FROM dba_constraints 
		WHERE owner = 'ASPEN2' AND table_name = 'LANG_DEFAULT_INCLUDE' AND CONSTRAINT_TYPE = 'R' AND R_CONSTRAINT_NAME='PK_LANG' AND ROWNUM = 1;

	IF v_constraint_name IS NOT NULL AND v_constraint_name != 'FK_LANG_LANG_DEF_INC' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.LANG_DEFAULT_INCLUDE RENAME CONSTRAINT ' || v_constraint_name || ' TO FK_LANG_LANG_DEF_INC';
	END IF;
	
	SELECT count(constraint_name) 
		into v_exists 
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATION_SET' AND owner = 'ASPEN2' AND constraint_name = 'REFLANG4';

	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATION_SET RENAME CONSTRAINT REFLANG4 TO FK_LANG_TS';
	END IF;

	SELECT count(constraint_name)
		INTO v_exists
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATED' AND owner = 'ASPEN2' AND constraint_name = 'REFTRANSLATION_SET3';
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATED RENAME CONSTRAINT REFTRANSLATION_SET3 TO FK_TRANSLATED_TS';
	END IF;

	SELECT count(constraint_name)
		INTO v_exists
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATION_SET_INCLUDE' AND owner = 'ASPEN2' AND constraint_name = 'REFTRANSLATION_SET6';
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATION_SET_INCLUDE RENAME CONSTRAINT REFTRANSLATION_SET6 TO FK_TS_TO_TSI';
	END IF;

	SELECT count(constraint_name)
		INTO v_exists
		FROM all_cons_columns 
		WHERE table_name = 'TRANSLATION_SET_INCLUDE' AND owner = 'ASPEN2' AND constraint_name = 'REFTRANSLATION_SET7';
	
		
	IF v_exists > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE ASPEN2.TRANSLATION_SET_INCLUDE RENAME CONSTRAINT REFTRANSLATION_SET7 TO FK_TS_TSI';
	END IF;
	
	SELECT COUNT(*) INTO v_exists FROM all_constraints WHERE owner = 'CSR' and constraint_name = 'FK_REGION_DESC_ASPEN2_TS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.REGION_DESCRIPTION ADD CONSTRAINT FK_REGION_DESC_ASPEN2_TS
			FOREIGN KEY (APP_SID, LANG)
			REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)';
	END IF;

	SELECT COUNT(*) INTO v_exists FROM all_constraints WHERE owner = 'CSR' and constraint_name = 'FK_REGION_DESC_ASPEN2_TS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.REGION_DESCRIPTION ADD CONSTRAINT FK_REGION_DESC_ASPEN2_TS
			FOREIGN KEY (APP_SID, LANG)
			REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)';
	END IF;

	SELECT COUNT(*) INTO v_exists FROM all_constraints WHERE owner = 'CSR' and constraint_name = 'FK_DELEG_REG_DESC_ASPEN2_TS';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEGATION_REGION_DESCRIPTION ADD CONSTRAINT FK_DELEG_REG_DESC_ASPEN2_TS
			FOREIGN KEY (APP_SID, LANG)
			REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG)';
	END IF;
END;
/

ALTER TABLE aspen2.translation_set         DISABLE CONSTRAINT fk_lang_ts;
ALTER TABLE aspen2.translated              DISABLE CONSTRAINT fk_translated_ts;
ALTER TABLE aspen2.translation_set_include DISABLE CONSTRAINT fk_ts_to_tsi;
ALTER TABLE aspen2.translation_set_include DISABLE CONSTRAINT fk_ts_tsi;
ALTER TABLE aspen2.lang_default_include	   DISABLE CONSTRAINT fk_lang_lang_def_inc;
ALTER TABLE csr.ind_description            DISABLE CONSTRAINT fk_ind_description_aspen2_ts;
ALTER TABLE csr.region_description         DISABLE CONSTRAINT fk_region_desc_aspen2_ts;
ALTER TABLE csr.delegation_ind_description DISABLE CONSTRAINT fk_deleg_ind_desc_aspen2_ts;
ALTER TABLE csr.delegation_region_description DISABLE CONSTRAINT fk_deleg_reg_desc_aspen2_ts;
ALTER TABLE csr.dataview_ind_description   DISABLE CONSTRAINT fk_dv_ind_desc_aspen2_ts;

ALTER TABLE csr.alert_frame_body           DISABLE CONSTRAINT fk_alert_frm_bdy_tran_set;
ALTER TABLE csr.alert_template_body        DISABLE CONSTRAINT fk_alt_tpl_bdy_bdy_tran_set;

DECLARE
	PROCEDURE MigrateLanguageCode (
		in_obsolete_lang	VARCHAR2,
		in_valid_lang		VARCHAR2
	)
	AS
		v_obsolete_lang		VARCHAR2(10) := lower(in_obsolete_lang);
		v_valid_lang		VARCHAR2(10) := lower(in_valid_lang);
	BEGIN
		UPDATE aspen2.lang                    SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translation_set         SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translated              SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translation_set_include SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE aspen2.translation_set_include SET  to_lang = v_valid_lang WHERE  to_lang = v_obsolete_lang;
		UPDATE aspen2.lang_default_include    SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.ind_description            SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.region_description         SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.delegation_description     SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.delegation_ind_description SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.delegation_region_description SET  lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.dataview_ind_description   SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;		
		UPDATE csr.alert_frame_body           SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE csr.alert_template_body        SET     lang = v_valid_lang WHERE     lang = v_obsolete_lang;
		UPDATE security.user_table            SET language = v_valid_lang WHERE language = v_obsolete_lang;
	END;
	
BEGIN
	MigrateLanguageCode('az-AZ-Cyrl', 'az-Cyrl-AZ');
	MigrateLanguageCode('az-AZ-Latn', 'az-Latn-AZ');
	MigrateLanguageCode('div', 'dv');
	MigrateLanguageCode('div-MV', 'dv-MV');
	MigrateLanguageCode('en-CB', 'en-029');
	MigrateLanguageCode('kh', 'km');
	MigrateLanguageCode('ky-kz', 'ky-kg');
	MigrateLanguageCode('sr-SP-Cyrl', 'sr-Cyrl-RS');
	MigrateLanguageCode('sr-SP-Latn', 'sr-Latn-RS');
	MigrateLanguageCode('uz-UZ-Cyrl', 'uz-Cyrl-UZ');
	MigrateLanguageCode('uz-UZ-Latn', 'uz-Latn-UZ');

	-- We don't need to fix these as Microsoft aliased them. Also they appear in tr.xml.
	-- { "zh-CHT", "zh-Hant" },
	-- { "zh-CHS", "zh-Hans" }

END;
/

ALTER TABLE aspen2.translation_set         ENABLE CONSTRAINT fk_lang_ts;
ALTER TABLE aspen2.translated              ENABLE CONSTRAINT fk_translated_ts;
ALTER TABLE aspen2.translation_set_include ENABLE CONSTRAINT fk_ts_to_tsi;
ALTER TABLE aspen2.translation_set_include ENABLE CONSTRAINT fk_ts_tsi;
ALTER TABLE aspen2.lang_default_include	   ENABLE CONSTRAINT fk_lang_lang_def_inc;
ALTER TABLE csr.ind_description            ENABLE CONSTRAINT fk_ind_description_aspen2_ts;
ALTER TABLE csr.region_description         ENABLE CONSTRAINT fk_region_desc_aspen2_ts;
ALTER TABLE csr.delegation_ind_description ENABLE CONSTRAINT fk_deleg_ind_desc_aspen2_ts;
ALTER TABLE csr.delegation_region_description ENABLE CONSTRAINT fk_deleg_reg_desc_aspen2_ts;
ALTER TABLE csr.dataview_ind_description   ENABLE CONSTRAINT fk_dv_ind_desc_aspen2_ts;

ALTER TABLE csr.alert_frame_body           ENABLE CONSTRAINT fk_alert_frm_bdy_tran_set;
ALTER TABLE csr.alert_template_body        ENABLE CONSTRAINT fk_alt_tpl_bdy_bdy_tran_set;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
