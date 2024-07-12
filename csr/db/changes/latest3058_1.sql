-- Please update version.sql too -- this keeps clean builds in sync
define version=3058
define minor_version=1
@update_header

-- XXX: Not again!
GRANT SELECT ON MAIL.ACCOUNT TO CSR;
GRANT SELECT ON MAIL.ACCOUNT_ALIAS TO CSR;
GRANT SELECT, UPDATE ON MAIL.MAILBOX TO CSR;
GRANT SELECT, UPDATE ON MAIL.MAILBOX_MESSAGE TO CSR;

@@latestDE4741_packages

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
DECLARE
	v_inbox_sid		NUMBER(10);
BEGIN
	-- Add the validator for the email body where required
	FOR r in (
		SELECT ds.automated_import_class_sid, ds.process_body
		  FROM csr.meter_raw_data_source ds
		  JOIN csr.auto_imp_mailbox mb ON mb.app_sid = ds.app_sid AND mb.matched_imp_class_sid_for_body = ds.automated_import_class_sid
	) LOOP
		UPDATE csr.auto_imp_mailbox
		   SET matched_imp_class_sid_for_body = DECODE(r.process_body, 0, NULL, r.automated_import_class_sid),
		       body_validator_plugin = DECODE(r.process_body, 0, NULL, 'Credit360.ExportImport.Automated.Import.Mail.MailValidation.MeterRawDataValidatorPlugin')
		;
	END LOOP;

	-- Make sure all mail from the last process before the release (that caused the issue) is not marked as read
	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_raw_data_source ds
		  JOIN csr.customer c ON c.app_sid = ds.app_sid
		 WHERE ds.automated_import_class_sid IS NOT NULL
	) LOOP
		security.user_pkg.logonadmin(a.host);

		FOR r IN (
			SELECT DISTINCT mbox.mailbox_name source_email
			  FROM csr.meter_raw_data_source ds
			  -- There should always be a wildcard email filter (so use that to find the email address(es)
			  JOIN csr.auto_imp_mail_attach_filter mfilt ON  mfilt.app_sid = a.app_sid AND mfilt.matched_import_class_sid = ds.automated_import_class_sid AND mfilt.is_wildcard = 1 AND mfilt.filter_string = '*'
			  JOIN mail.mailbox mbox ON mbox.mailbox_sid = mfilt.mailbox_sid 
			 WHERE ds.app_sid = a.app_sid
			   AND ds.automated_import_class_sid IS NOT NULL
		) LOOP

			BEGIN
				v_inbox_sid := csr.TEMP_DE4741_PACKAGE.getInboxSIDFromEmail(r.source_email);

				FOR m IN (
					SELECT message_uid 
					  FROM mail.mailbox_message 
					 WHERE mailbox_sid = v_inbox_sid
					   AND received_dtm > TO_DATE('2017-04-24 01:00:00', 'YYYY-MM-DD HH24:MI:SS')
					   AND bitand(flags, 4 /*mail_pkg.Flag_Seen*/) != 0
				) LOOP
					csr.TEMP_DE4741_PACKAGE.MarkMessageAsUnread(v_inbox_sid, m.message_uid);
				END LOOP;

			EXCEPTION
				WHEN csr.TEMP_DE4741_PACKAGE.MAILBOX_NOT_FOUND THEN
					NULL; -- Ignore
			END;
		
		END LOOP;

		security.user_pkg.logonadmin;

	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

DROP PACKAGE CSR.TEMP_DE4741_PACKAGE;

@update_tail
