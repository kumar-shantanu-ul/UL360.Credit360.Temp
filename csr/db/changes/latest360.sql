-- Please update version.sql too -- this keeps clean builds in sync
define version=360
@update_header

ALTER TABLE file_upload ADD (sha1 RAW(20));
DELETE FROM donations.donation_doc WHERE document_sid IN (SELECT file_upload_sid FROM file_upload WHERE data IS NULL);
DELETE FROM pending_val_file_upload WHERE file_upload_sid IN (SELECT file_upload_sid FROM file_upload WHERE data IS NULL);
DELETE FROM sheet_value_file WHERE file_upload_sid IN (SELECT file_upload_sid FROM file_upload WHERE data IS NULL);
DELETE FROM val_file WHERE file_upload_sid IN (SELECT file_upload_sid FROM file_upload WHERE data IS NULL);
DELETE FROM file_upload WHERE data IS NULL;
ALTER TABLE file_upload MODIFY (data NOT NULL);
-- 3 is dbms_crypto.hash_sh1 but not allowed to use this in SQL...
UPDATE file_upload
   SET sha1 = dbms_crypto.hash(data, 3);
ALTER TABLE file_upload MODIFY (sha1 NOT NULL);

@..\fileupload_body.sql
@..\null_body.sql
@..\indicator_pkg.sql
@..\indicator_body.sql
@..\sheet_pkg.sql
@..\sheet_body.sql

@update_tail
