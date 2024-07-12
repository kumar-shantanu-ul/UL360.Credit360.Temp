-- Please update version.sql too -- this keeps clean builds in sync
define version=35
@update_header

PROMPT Enter connection name: (e.g. ASPEN)
connect csr/csr@&&1
grant select, references on file_upload to donations;

connect donations/donations@&&1

-- put stuff back that got accidentally nuked
insert into csr.file_upload
    select fuo.file_upload_sid, filename, mime_type, parent_sid, data, dd.app_sid 
      from csr.old_file_upload_orphans fuo, 
        (select distinct document_sid, app_sid from donations.donation_doc minus select file_upload_sid, app_sid from csr.file_Upload) dd
     where fuo.file_upload_sid = dd.document_sid;

-- delete junk rows
delete from donation_doc where document_sid = -1;
 
-- shove on a constraint
ALTER TABLE DONATION_DOC ADD CONSTRAINT RefFILE_UPLOAD153 
    FOREIGN KEY (DOCUMENT_SID, APP_SID)
    REFERENCES CSR.FILE_UPLOAD(FILE_UPLOAD_SID, APP_SID)
;

@update_tail
