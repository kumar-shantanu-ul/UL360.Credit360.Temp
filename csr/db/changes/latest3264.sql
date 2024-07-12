define version=3264
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/












INSERT INTO chain.grid_extension (grid_extension_id, base_card_group_id, extension_card_group_id, record_name)
VALUES (14, 25, 42, 'nonCompliance');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit cscript inds', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can create cscript inds', 0);
DECLARE
	v_max NUMBER;
BEGIN
	security.user_pkg.logonadmin();
	FOR c in (SELECT app_sid, host FROM csr.customer WHERE name IN ('hyatt.credit360.com', 'JM Family'))
	LOOP
		security.user_pkg.logonadmin(c.host);
    
		FOR r in (
			SELECT UNIQUE l.app_sid, l.ftp_profile_id, MAX(l.auto_imp_fileread_ftp_id) fileread_ftp_id
			  FROM csr.auto_imp_fileread_ftp l
			  JOIN csr.auto_imp_fileread_ftp r ON 
				   l.auto_imp_fileread_ftp_id != r.auto_imp_fileread_ftp_id AND
				   l.app_sid = r.app_sid AND 
				   l.ftp_profile_id = r.ftp_profile_id AND
				   l.payload_path = r.payload_path AND
				   l.file_mask = r.file_mask
			 GROUP BY l.app_sid, l.ftp_profile_id
		)
		LOOP
			--dbms_output.put_line(c.host ||' App '||r.app_sid||' Id '||r.ftp_profile_id||', DELETE all but '||r.fileread_ftp_id);
			DELETE FROM csr.auto_imp_fileread_ftp
			 WHERE app_sid = r.app_sid AND ftp_profile_id = r.ftp_profile_id AND auto_imp_fileread_ftp_id != r.fileread_ftp_id;
		END LOOP;
    
	security.user_pkg.logonadmin();
	END LOOP;
END;
/
UPDATE csr.period_dates
   SET end_dtm = ADD_MONTHS(end_dtm, 12)
 WHERE start_dtm > end_dtm;
ALTER TABLE csr.period_dates ADD CONSTRAINT CK_PERIOD_DATES_SPAN CHECK (start_dtm < end_dtm);
ALTER TABLE csrimp.period_dates ADD CONSTRAINT CK_PERIOD_DATES_SPAN CHECK (start_dtm < end_dtm);
UPDATE security.menu
   SET action = '/csr/site/admin/translations/translationsImport.acds'
 WHERE action = '''/csr/site/admin/translations/translationsImport.acds';






@..\indicator_pkg
@..\calc_pkg
@..\automated_import_pkg
@..\csr_user_pkg
@..\portlet_pkg


@..\issue_body
@..\issue_report_body
@..\indicator_body
@..\calc_body
@..\automated_import_body
@..\meter_monitor_body
@..\branding_body
@..\csr_user_body
@..\portlet_body



@update_tail
