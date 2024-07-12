-- Please update version.sql too -- this keeps clean builds in sync
define version=101
@update_header

VARIABLE version NUMBER
BEGIN :version := 101; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

declare
	v_count 	number;
begin
	select count(*)
	  into v_count
	  from source_type
	 where source_type_id=7;
	if v_count = 0 then
		insert into source_type (source_type_id, description, helper_pkg, audit_url) values (7, 'Pending', null, null);
	end if;
end;
/

update sheet_action set description ='Pending approval with modifications' where sheet_action_id = 11;

   
CREATE OR REPLACE VIEW V$ACTIVE_USER AS
	SELECT cu.csr_user_sid, cu.email, cu.region_mount_point_sid,
	  cu.indicator_mount_point_sid, cu.csr_root_sid, cu.full_name,
	  cu.user_name, cu.info_xml, cu.send_alerts,
	  cu.guid, cu.friendly_name
	  FROM csr_user cu, security.user_table ut
	 WHERE cu.csr_user_sid = ut.sid_id
	   AND ut.account_enabled = 1;

ALTER TABLE ind RENAME COLUMN info_xml TO info_xml_2;
ALTER TABLE ind ADD (info_xml XMLType);
UPDATE ind SET info_xml = XMLType(info_xml_2) WHERE info_xml_2 IS NOT NULL AND LENGTH(info_xml_2) > 1;

ALTER TABLE ind RENAME COLUMN calc_xml TO calc_xml_2;
ALTER TABLE ind ADD (calc_xml XMLType);
UPDATE ind SET calc_xml = XMLType(calc_xml_2) WHERE calc_xml_2 IS NOT NULL AND LENGTH(calc_xml_2) > 1;

ALTER TABLE region RENAME COLUMN info_xml TO info_xml_2;
ALTER TABLE region ADD (info_xml XMLType);
UPDATE region SET info_xml = XMLType(info_xml_2) WHERE info_xml_2 IS NOT NULL AND LENGTH(info_xml_2) > 1;

ALTER TABLE csr_user RENAME COLUMN info_xml TO info_xml_2;
ALTER TABLE csr_user ADD (info_xml XMLType);
UPDATE csr_user SET info_xml = XMLType(info_xml_2) WHERE info_xml_2 IS NOT NULL AND LENGTH(info_xml_2) > 1;

ALTER TABLE customer RENAME COLUMN ind_info_xml_fields TO ind_info_xml_fields_2;
ALTER TABLE customer ADD (ind_info_xml_fields XMLType);
UPDATE customer SET ind_info_xml_fields = XMLType(ind_info_xml_fields_2) WHERE ind_info_xml_fields_2 IS NOT NULL AND LENGTH(ind_info_xml_fields_2) > 1;

ALTER TABLE customer RENAME COLUMN region_info_xml_fields TO region_info_xml_fields_2;
ALTER TABLE customer ADD (region_info_xml_fields XMLType);
UPDATE customer SET region_info_xml_fields = XMLType(region_info_xml_fields_2) WHERE region_info_xml_fields_2 IS NOT NULL AND LENGTH(region_info_xml_fields_2) > 1;

ALTER TABLE customer RENAME COLUMN user_info_xml_fields TO user_info_xml_fields_2;
ALTER TABLE customer ADD (user_info_xml_fields XMLType);
UPDATE customer SET user_info_xml_fields = XMLType(user_info_xml_fields_2) WHERE user_info_xml_fields_2 IS NOT NULL AND LENGTH(user_info_xml_fields_2) > 1;

ALTER TABLE pending_ind RENAME COLUMN format_xml TO format_xml_2;
ALTER TABLE pending_ind ADD (format_xml XMLType);
UPDATE pending_ind SET format_xml = XMLType(format_xml_2) WHERE format_xml_2 IS NOT NULL AND LENGTH(format_xml_2) > 1;

ALTER TABLE pending_ind RENAME COLUMN info_xml TO info_xml_2;
ALTER TABLE pending_ind ADD (info_xml XMLType);
UPDATE pending_ind SET info_xml = XMLType(info_xml_2) WHERE info_xml_2 IS NOT NULL AND LENGTH(info_xml_2) > 1;





ALTER TABLE ind DROP COLUMN info_xml_2;
ALTER TABLE ind DROP COLUMN calc_xml_2;
ALTER TABLE region DROP COLUMN info_xml_2;
ALTER TABLE csr_user DROP COLUMN info_xml_2;
ALTER TABLE customer DROP COLUMN ind_info_xml_fields_2;
ALTER TABLE customer DROP COLUMN region_info_xml_fields_2;
ALTER TABLE customer DROP COLUMN user_info_xml_fields_2;
ALTER TABLE pending_ind DROP COLUMN format_xml_2;
ALTER TABLE pending_ind DROP COLUMN info_xml_2;



UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
