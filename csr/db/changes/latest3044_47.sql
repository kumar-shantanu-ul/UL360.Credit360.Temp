-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=47
@update_header


-- XXX: Need to grant access to some mail tables to get 
-- this temp package to compile - not ideal really!
-- Tried moving the package into UPD, but still didn't work.
GRANT SELECT ON MAIL.ACCOUNT TO CSR;
GRANT SELECT ON MAIL.ACCOUNT_ALIAS TO CSR;
GRANT SELECT, UPDATE ON MAIL.MAILBOX TO CSR;
GRANT SELECT, UPDATE ON MAIL.MAILBOX_MESSAGE TO CSR;

@@latestUS6151_2_packages;

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	LABEL						VARCHAR2(1024)
);

ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN SOURCE_EMAIL TO XX_SOURCE_EMAIL;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN SOURCE_FOLDER TO XX_SOURCE_FOLDER;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN FILE_MATCH_RX TO XX_FILE_MATCH_RX;
ALTER TABLE CSR.METER_RAW_DATA_SOURCE RENAME COLUMN RAW_DATA_SOURCE_TYPE_ID TO XX_RAW_DATA_SOURCE_TYPE_ID;

ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE ADD (
	LABEL						VARCHAR2(1024)	NOT NULL
);

ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN SOURCE_EMAIL;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN SOURCE_FOLDER;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN FILE_MATCH_RX;
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE DROP COLUMN RAW_DATA_SOURCE_TYPE_ID;

-- Make back-up column nullable
ALTER TABLE CSR.METER_RAW_DATA_SOURCE MODIFY (
	XX_RAW_DATA_SOURCE_TYPE_ID			NUMBER(10)	NULL
);

ALTER TABLE CSR.METER_RAW_DATA_SOURCE DROP CONSTRAINT FK_METER_RAW_DATA_SOURCE_TYPE;
DROP TABLE CSR.METER_RAW_DATA_SOURCE_TYPE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

CREATE OR REPLACE VIEW CSR.V$METER_ORPHAN_DATA_SUMMARY AS
	SELECT od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.label,
		MIN(rd.received_dtm) created_dtm, MAX(rd.received_dtm) updated_dtm, 
		MIN(od.start_dtm) start_dtm, NVL(MAX(od.end_dtm), MAX(od.start_dtm)) end_dtm, 
		SUM(od.consumption) consumption,
		MAX(od.has_overlap) has_overlap,
		MAX(od.region_sid) region_sid,
		MAX(od.error_type_id) KEEP (DENSE_RANK LAST ORDER BY rd.received_dtm) error_type_id
	  FROM meter_orphan_data od
	  JOIN meter_raw_data rd ON rd.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND rd.meter_raw_data_id = od.meter_raw_data_id
	  JOIN meter_raw_data_source ds ON ds.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ds.raw_data_source_id = rd.raw_data_source_id
	 WHERE od.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 GROUP BY od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.label
;

-- *** Data changes ***
-- RLS

-- Data
--
-- *** WHEN TESTED ON IMPDB AND WEMBLEY THIS UPDATE TOOK ABOUT
-- *** 3 (THREE) MINUTES TO RUN (due to marking historic mail as read) ***
--
DECLARE
	v_auto_imports_container_sid	NUMBER(10);
	v_automated_import_class_sid	NUMBER(10);
	v_ftp_profile_id				NUMBER(10);
	v_ftp_settings_id				NUMBER(10);
	v_inbox_sid						NUMBER(10);
	v_root_mailbox_sid				NUMBER(10);
	v_file_type_id					NUMBER(10);
BEGIN
	FOR cust IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_raw_data_source rds
		  JOIN csr.customer c ON c.app_sid = rds.app_sid
		 WHERE rds.automated_import_class_sid IS NULL
	) LOOP
		
		security.user_pkg.logonadmin(cust.host);

		-- Automated imports must be enabled
		BEGIN
			v_auto_imports_container_sid := security.securableobject_pkg.GetSidFromPath(
				security.security_pkg.GetACT, security.security_pkg.GetAPP, 'AutomatedImports');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				csr.TEMP_US6151_PACKAGE.EnableAutomatedExportImport;
		END;

		FOR rds IN (
			SELECT rds.raw_data_source_id, rds.xx_source_email source_email, rds.xx_source_folder source_folder, rds.process_body, eo.csv_delimiter,
				DECODE(rds.xx_raw_data_source_type_id, 1, NULL, cust.host || '/' || rds.xx_source_folder) ftp_path, 
				REPLACE(REPLACE(REPLACE(
					REGEXP_REPLACE(rds.xx_file_match_rx, '^(.*)\[.+\](.*)$', '\1\2'),	-- Remove anything in square brackets
					'.+', '*'),															-- Replace .+ with *
					'.*', '*'),															-- Replace .* with *
					'\.', '.')															-- Replace \. with .
				ftp_file_mask,
				CASE LOWER(rds.parser_type)
					WHEN 'csv' THEN 'dsv'
					WHEN 'excel' THEN 'excel'
					WHEN 'excel2' THEN 'excel'
					WHEN 'csvtimebycolumn' THEN 'dsv'
					WHEN 'exceltimebycolumn' THEN 'excel'
					WHEN 'xml' THEN 'xml'
					WHEN 'ediel' THEN 'ediel'
					WHEN 'wi5' THEN 'wi5'
				END file_type
			FROM csr.meter_raw_data_source rds
			LEFT JOIN csr.meter_excel_option eo ON eo.app_sid = rds.app_sid AND eo.raw_data_source_id = rds.raw_data_source_id
			WHERE rds.automated_import_class_sid IS NULL
		) LOOP

			-- Create Automated import class etc.
			csr.TEMP_US6151_PACKAGE.CreateClass(
				in_label						=> 'Meter data source ' || rds.raw_data_source_id,
				in_lookup_key					=> 'METER_DATA_SOURCE_' || rds.raw_data_source_id,
				in_schedule_xml					=> XMLType('<recurrences><daily/></recurrences>'),
				in_abort_on_error				=> 0,
				in_email_on_error				=> 'support@credit360.com',
				in_email_on_partial				=> NULL,
				in_email_on_success				=> NULL,
				in_on_completion_sp				=> NULL,
				in_import_plugin				=> NULL,
				in_process_all_pending_files	=> 1,
				out_class_sid					=> v_automated_import_class_sid
			);

			-- Make the schedule run at midnight
			UPDATE csr.automated_import_class
			   SET last_scheduled_dtm = TRUNC(SYSDATE, 'DD')
			 WHERE app_sid = cust.app_sid
			   AND automated_import_class_sid = v_automated_import_class_sid;

			-- FTP file readers for FTP sources
			IF rds.ftp_path IS NOT NULL THEN
				
				-- create FTP profile
				v_ftp_profile_id := csr.TEMP_US6151_PACKAGE.CreateCr360FTPProfile;
				
				-- create FTP settings
				v_ftp_settings_id := csr.TEMP_US6151_PACKAGE.MakeFTPReaderSettings(
					in_ftp_profile_id				=> v_ftp_profile_id,
					in_payload_path					=> '/' || rds.ftp_path || '/',
					in_file_mask					=> rds.ftp_file_mask,
					in_sort_by						=> 'DATE',
					in_sort_by_direction			=> 'ASC',
					in_move_to_path_on_success		=> '/' || rds.ftp_path || '/processed/',
					in_move_to_path_on_error		=> '/' || rds.ftp_path || '/error/',
					in_delete_on_success			=> 0,
					in_delete_on_error				=> 0
				);
				
				-- create step
				csr.TEMP_US6151_PACKAGE.AddFtpClassStep(
					in_import_class_sid				=> v_automated_import_class_sid,
					in_step_number					=> 1,
					in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
					in_days_to_retain_payload		=> 30,
					in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
					in_ftp_settings_id				=> v_ftp_settings_id,
					in_importer_plugin_id			=> csr.TEMP_US6151_PACKAGE.IMPORT_PLUGIN_TYPE_METER_RD
				);

			END IF;

			-- Specific settings for email sources
			IF rds.source_email IS NOT NULL THEN

				v_inbox_sid := NULL;

				csr.TEMP_US6151_PACKAGE.AddClassStep(
					in_import_class_sid				=> v_automated_import_class_sid,
					in_step_number					=> 1,
					in_on_completion_sp				=> 'csr.meter_monitor_pkg.QueueRawDataImportJob',
					in_days_to_retain_payload		=> 30,
					in_plugin						=> 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
					in_importer_plugin_id			=> csr.TEMP_US6151_PACKAGE.IMPORT_PLUGIN_TYPE_METER_RD,
					in_fileread_plugin_id			=> 3 /* Manual Instance Reader */
				);

				-- Get/create the inbox sid from the email address
				BEGIN
					v_inbox_sid := csr.TEMP_US6151_PACKAGE.getInboxSIDFromEmail(rds.source_email);

					-- We want the root mailbox sid
					-- TODO: Check it is the root mailbox we need
					SELECT root_mailbox_sid
					  INTO v_root_mailbox_sid
					  FROM mail.account
					 WHERE inbox_sid = v_inbox_sid;

					-- Associate the email/mailbox with the auto imp class sid 
					-- (extracted from automated_import_pkg.CreateMailbox as we 
					-- don't want to create a new mailbox here becasue it already exists)
					INSERT INTO csr.auto_imp_mailbox (address, mailbox_sid, 
						body_validator_plugin, 
						use_full_mail_logging, matched_imp_class_sid_for_body)
					VALUES (rds.source_email, v_root_mailbox_sid, 
						CASE rds.process_body WHEN 0 THEN NULL ELSE 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin' END, 
						1, v_automated_import_class_sid);
				
				EXCEPTION
					WHEN csr.TEMP_US6151_PACKAGE.MAILBOX_NOT_FOUND THEN
						-- Mailbox not found, create a new one
						csr.TEMP_US6151_PACKAGE.CreateMailbox(
							in_email_address				=> rds.source_email,
							in_body_plugin					=> CASE rds.process_body WHEN 0 THEN NULL ELSE 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin' END,
							in_use_full_logging				=> 1,
							in_matched_class_sid_for_body	=> v_automated_import_class_sid,
							in_user_sid						=> security.security_pkg.GetSID,
							out_new_sid						=> v_root_mailbox_sid
						);
						-- Get the new inbox sid
						v_inbox_sid := csr.TEMP_US6151_PACKAGE.getInboxSIDFromEmail(rds.source_email);
				END;

				-- Add an attachment filter too
				csr.TEMP_US6151_PACKAGE.AddAttachmentFilter(
					in_mailbox_sid					=> v_root_mailbox_sid,
					in_pos							=> 0,
					in_filter_string				=> '*',
					in_is_wildcard					=> 1,
					in_matched_import_class_sid		=> v_automated_import_class_sid,
					in_required_mimetype			=> NULL,
					in_attachment_validator_plugin	=> 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin'
				);

				-- Mark all existing mail in the inbox as read
				IF v_inbox_sid IS NOT NULL THEN
					FOR m IN (
						SELECT message_uid 
						  FROM mail.mailbox_message 
						 WHERE mailbox_sid = v_inbox_sid
						   AND bitand(flags, 4 + 2 /*mail_pkg.Flag_Seen + mail_pkg.Flag_Deleted*/) = 0
					) LOOP
						csr.TEMP_US6151_PACKAGE.MarkMessageAsRead(v_inbox_sid, m.message_uid);
					END LOOP;
				END IF;

			END IF;

			-- Get file type id
			SELECT automated_import_file_type_id
			  INTO v_file_type_id
			  FROM csr.automated_import_file_type
			 WHERE LOWER(label) = LOWER(rds.file_type);

			-- We're not converting the settings in the update script we'll get the code to 
			-- fall-back to the old settings tables if the xml does not specify the settings. 
			-- The next time the settings are saved they will be converted to the new format.
			csr.TEMP_US6151_PACKAGE.SetGenericImporterSettings(
				in_import_class_sid			=> v_automated_import_class_sid,
				in_step_number				=> 1,
				in_mapping_xml				=> XMLTYPE('<xml/>'),
				in_imp_file_type_id			=> v_file_type_id,
				in_dsv_separator			=> rds.csv_delimiter,
				in_dsv_quotes_as_literals	=> 0,
				in_excel_worksheet_index	=> 0,
				in_excel_row_index			=> 0,
				in_all_or_nothing			=> 0
			);

			-- Update meter_raw_data_source table
			UPDATE csr.meter_raw_data_source
			   SET automated_import_class_sid = v_automated_import_class_sid
			 WHERE app_sid = cust.app_sid
			   AND raw_data_source_id = rds.raw_data_source_id;

		END LOOP;

		security.user_pkg.logonadmin;

	END LOOP;
END;
/

-- Set the raw data source labels before making the column not null
BEGIN
	FOR r IN (
		 SELECT rds.app_sid, rds.raw_data_source_id, NVL(aic.label, 'Meter data source ' || rds.raw_data_source_id) label
		   FROM csr.meter_raw_data_source rds
		   LEFT JOIN csr.automated_import_class aic ON aic.app_sid = rds.app_sid AND aic.automated_import_class_sid = rds.automated_import_class_sid
	) LOOP
		UPDATE csr.meter_raw_data_source
		   SET label = r.label
		 WHERE app_sid = r.app_sid
		   AND raw_data_source_id = r.raw_data_source_id;
	END LOOP;
END;
/

ALTER TABLE CSR.METER_RAW_DATA_SOURCE MODIFY (
	LABEL						VARCHAR2(1024)	NOT NULL
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

DROP PACKAGE CSR.TEMP_US6151_PACKAGE;

revoke select on mail.account_alias from csr;
revoke update on mail.mailbox from csr;
revoke update on mail.mailbox_message from csr;

@../meter_monitor_pkg
@../automated_import_pkg

@../schema_body
@../automated_import_body
@../meter_monitor_body
@../meter_duff_region_body
@../enable_body

@../csrimp/imp_body

@update_tail
