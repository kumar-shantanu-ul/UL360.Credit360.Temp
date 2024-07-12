grant select, update, references on csr.csr_user to donations;
grant select, references on csr.region to donations;
grant select, references on csr.region_owner to donations;
grant select, references on csr.customer to donations;
grant update, select, references on csr.supplier to donations;
grant select, update, references on csr.file_upload to donations;
grant select, references, delete on csr.postit to donations;
grant select, references on csr.postit_file to donations;
grant select, references on csr.tag TO donations;
grant select, references on csr.tag_group to donations;
grant select, references on csr.tag_group_member TO donations;
grant select, references on csr.region_tag TO donations;

grant select, references on postcode.country to donations;

grant select on aspen2.filecache to donations;
GRANT SELECT  ON csr.val TO donations;
GRANT SELECT  ON csr.val_change TO donations;
GRANT SELECT  ON csr.ind TO donations;