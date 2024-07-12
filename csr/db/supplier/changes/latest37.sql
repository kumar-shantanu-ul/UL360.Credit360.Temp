VARIABLE version NUMBER
BEGIN :version := 37; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

-- diff local machines may have diff products on 
update
all_company
set country_code = 'UK'
where country_code in (
'GBA',
'ENG',
'SC',
'WA'
);

update
wood_part_wood
set country_code = 'UK'
where country_code in (
'GBA',
'ENG',
'SC',
'WA'
);

update
wood_part_description
set pre_recycled_country_code = 'UK'
where pre_recycled_country_code in (
'GBA',
'ENG',
'SC',
'WA'
);

update
wood_part_description
set post_recycled_country_code = 'UK'
where post_recycled_country_code in (
'GBA',
'ENG',
'SC',
'WA'
);

-- delete unwanted 
delete from gt_country_region where country_code in 
(
'GBA',
'BFPO',
'CRE',
'ENG',
'GU',
'GBM',
'GBJ',
'SC',
'V',
'WA',
--stuff we insert again
'AFR',
'ASI',
'ASL',
'CRB',
'EQG',
'EU',
'FE',
'GBI',
'MAD',
'ME',
'NA',
'OCN',
'ROG',
'SA',
'USP'
);

delete from country where country_code in 
(
'GBA',
'BFPO',
'CRE',
'ENG',
'GU',
'GBM',
'GBJ',
'SC',
'V',
'WA',
--stuff we insert again
'AFR',
'ASI',
'ASL',
'CRB',
'EQG',
'EU',
'FE',
'GBI',
'MAD',
'ME',
'NA',
'OCN',
'ROG',
'SA',
'USP'
);

INSERT INTO COUNTRY (country_code, country) values ('AFR','Africa');
INSERT INTO COUNTRY (country_code, country) values ('ASI','Asia');
INSERT INTO COUNTRY (country_code, country) values ('ASL','Australasia');
INSERT INTO COUNTRY (country_code, country) values ('CRB','Caribbean');
INSERT INTO COUNTRY (country_code, country) values ('EQG','Equatorial Guinea');
INSERT INTO COUNTRY (country_code, country) values ('EU','Europe');
INSERT INTO COUNTRY (country_code, country) values ('FE','Far East');
INSERT INTO COUNTRY (country_code, country) values ('GBI','Guinea Bissau');
INSERT INTO COUNTRY (country_code, country) values ('MAD','Madagascar');
INSERT INTO COUNTRY (country_code, country) values ('ME','Middle East');
INSERT INTO COUNTRY (country_code, country) values ('NA','North America');
INSERT INTO COUNTRY (country_code, country) values ('OCN','Oceania');
INSERT INTO COUNTRY (country_code, country) values ('ROG','Republic of Guinea');
INSERT INTO COUNTRY (country_code, country) values ('SA','South America');
INSERT INTO COUNTRY (country_code, country) values ('USP','Unspecified');

INSERT INTO gt_country_region (country_code, gt_region_id) values ('AFR',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('ASI',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('ASL',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('CRB',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('EQG',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('EU',3);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('FE',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('GBI',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('MAD',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('ME',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('NA',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('OCN',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('ROG',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('SA',4);
INSERT INTO gt_country_region (country_code, gt_region_id) values ('USP',4);


-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
