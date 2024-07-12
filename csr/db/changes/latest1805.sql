-- Please update version too -- this keeps clean builds in sync
define version=1805
@update_header

-- XXX Restore kosovo deleted in 1804 - there are a lot of tables with no ref integ on this table - so just nuking it will orphan stuff potentially

begin
insert into postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3) values ('xk', 'Kosovo', 42.36, 20.51, 10887, 'EU', 'EUR', 'xxk');
exception when dup_val_on_index then null;
end;
/

@update_tail