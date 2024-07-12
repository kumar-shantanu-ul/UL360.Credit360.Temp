VARIABLE version NUMBER
BEGIN :version := 25; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM supplier.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/
--
DECLARE
    v_act            security_pkg.T_ACT_ID;
    v_csr_root_sid    security_pkg.T_SID_ID;
BEGIN
    user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
    v_csr_root_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/bootssupplier.credit360.com/csr');
    INSERT INTO PRODUCT_CODE_STEM VALUES (1, 'GNFR');
    INSERT INTO PRODUCT_CODE_STEM VALUES (2, 'AWAIT');
    INSERT INTO PRODUCT_CODE_STEM_TAG              
            SELECT 1, t.tag_id 
                FROM tag t, tag_group tg, tag_group_member tgm
                 WHERE t.TAG_ID = tgm.TAG_ID
                    AND tgm.TAG_GROUP_SID = tg.TAG_GROUP_SID
                    AND tg.NAME = 'sale_type'
                    AND t.TAG = 'GNFR'
                    AND csr_root_sid = v_csr_root_sid;          
    INSERT INTO PRODUCT_CODE_STEM_TAG              
            SELECT 2, t.tag_id
                FROM tag t, tag_group tg, tag_group_member tgm
                 WHERE t.TAG_ID = tgm.TAG_ID
                    AND tgm.TAG_GROUP_SID = tg.TAG_GROUP_SID
                    AND tg.NAME = 'sale_type'
                    AND NOT t.TAG = 'GNFR'
                    AND csr_root_sid = v_csr_root_sid;    
    v_csr_root_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/bootstest.credit360.com/csr');
    INSERT INTO PRODUCT_CODE_STEM_TAG              
            SELECT 1, t.tag_id 
                FROM tag t, tag_group tg, tag_group_member tgm
                 WHERE t.TAG_ID = tgm.TAG_ID
                    AND tgm.TAG_GROUP_SID = tg.TAG_GROUP_SID
                    AND tg.NAME = 'sale_type'
                    AND t.TAG = 'GNFR'
                    AND csr_root_sid = 
                    v_csr_root_sid;  
    INSERT INTO PRODUCT_CODE_STEM_TAG              
            SELECT 2, t.tag_id
                FROM tag t, tag_group tg, tag_group_member tgm
                 WHERE t.TAG_ID = tgm.TAG_ID
                    AND tgm.TAG_GROUP_SID = tg.TAG_GROUP_SID
                    AND tg.NAME = 'sale_type'
                    AND NOT t.TAG = 'GNFR'
                    AND csr_root_sid = v_csr_root_sid;     
END;
/
--
--
-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
