-- Please update version.sql too -- this keeps clean builds in sync
define version=2664
@update_header

ALTER TABLE POSTCODE.COUNTRY ADD (
    IS_STANDARD     NUMBER(1,0)      DEFAULT 1 NOT NULL
);

update postcode.country set is_standard = 0 where country in ('ac','ep','lm','mi','nm','of','oa','ol','aa','hc','ay','ap','eu');

-- we leave csr region as they are unless they're suppliers (so we don't bugger up carbon calcs)
update chain.company set country_code = 'cn' where country_code = 'hc';
update csr.region set geo_country = 'cn' where geo_country = 'hc' and region_sid in (select region_sid from csr.supplier);

CREATE OR REPLACE VIEW CHAIN.v$country AS
	SELECT country country_code, name
	  FROM postcode.country
	 WHERE latitude IS NOT NULL AND longitude IS NOT NULL
	   AND is_standard = 1
;

@update_tail
