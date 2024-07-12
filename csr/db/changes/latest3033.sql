-- Please update version.sql too -- this keeps clean builds in sync
define version=3033
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
	v_count NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CHAIN'
	   AND index_name = 'IX_DEDUPE_MAPPIN_DESTINATION_T';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index chain.ix_dedupe_mappin_destination_t on chain.dedupe_mapping (app_sid, destination_tab_sid, destination_col_sid)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CMS'
	   AND index_name = 'IX_TAB_ENUM_TRANSLAT';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index cms.ix_tab_enum_translat on cms.tab (app_sid, enum_translation_tab_sid)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTOMATED_IMP_MAILBOX_SID_M';
	   
	IF v_count = 0 THEN
		
		EXECUTE IMMEDIATE 'create index csr.ix_automated_imp_mailbox_sid_m on csr.automated_import_instance (app_sid, mailbox_sid, mail_message_uid)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_MAILBOX_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_mailbox_sid on csr.auto_imp_mail (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAILBOX_MBOX_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mailbox_mbox_sid on csr.auto_imp_mailbox (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_MATCHED_IMP_C';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_matched_imp_c on csr.auto_imp_mailbox (app_sid, matched_imp_class_sid_for_body)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_ATT_FILT_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_att_filt_sid on csr.auto_imp_mail_attach_filter (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_MATCHED_IMPOR';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_matched_impor on csr.auto_imp_mail_attach_filter (app_sid, matched_import_class_sid)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_FILE_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_file_sid on csr.auto_imp_mail_file (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_MSG_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_msg_sid on csr.auto_imp_mail_msg (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_SENDER_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_sender_sid on csr.auto_imp_mail_sender_filter (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_AUTO_IMP_MAIL_SUBJECT_SID';
	   
	IF v_count = 0 THEN
		BEGIN
			EXECUTE IMMEDIATE 'create index csr.ix_auto_imp_mail_subject_sid on csr.auto_imp_mail_subject_filter (mailbox_sid)';
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_CALC_JOB_FETC_CALC_JOB_ID';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_calc_job_fetc_calc_job_id on csr.calc_job_fetch_stat (app_sid, calc_job_id)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_CALC_JOB_STAT_SCENARIO_RUN_';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_calc_job_stat_scenario_run_ on csr.calc_job_stat (app_sid, scenario_run_sid)';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
