-- Please update version.sql too -- this keeps clean builds in sync
define version=2121
@update_header

ALTER TABLE aspen2.lang ADD (override_lang VARCHAR2(10));

update ASPEN2.lang set OVERRIDE_LANG='za' where lang='af';
update ASPEN2.lang set OVERRIDE_LANG='al' where lang='sq';
update ASPEN2.lang set OVERRIDE_LANG='arabic' where lang='ar';
update ASPEN2.lang set OVERRIDE_LANG='am' where lang='hy';
update ASPEN2.lang set OVERRIDE_LANG='az' where lang='az-az-cyrl';
update ASPEN2.lang set OVERRIDE_LANG='az' where lang='az-az-latn';
update ASPEN2.lang set OVERRIDE_LANG='basque' where lang='eu';
update ASPEN2.lang set OVERRIDE_LANG='basque' where lang='eu-es';
update ASPEN2.lang set OVERRIDE_LANG='by' where lang='be';
update ASPEN2.lang set OVERRIDE_LANG='catalonia' where lang='ca';
update ASPEN2.lang set OVERRIDE_LANG='catalonia' where lang='ca-es';
update ASPEN2.lang set OVERRIDE_LANG='dk' where lang='da';
update ASPEN2.lang set OVERRIDE_LANG='mv' where lang='div';
update ASPEN2.lang set OVERRIDE_LANG='ee' where lang='et';
update ASPEN2.lang set OVERRIDE_LANG='ir' where lang='fa';
update ASPEN2.lang set OVERRIDE_LANG='galician' where lang='gl';
update ASPEN2.lang set OVERRIDE_LANG='galician' where lang='gl-es';
update ASPEN2.lang set OVERRIDE_LANG='ge' where lang='ka';
update ASPEN2.lang set OVERRIDE_LANG='gr' where lang='el';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='gu';
update ASPEN2.lang set OVERRIDE_LANG='il' where lang='he';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='hi';
update ASPEN2.lang set OVERRIDE_LANG='jp' where lang='ja';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='kn';
update ASPEN2.lang set OVERRIDE_LANG='kz' where lang='kk';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='kok';
update ASPEN2.lang set OVERRIDE_LANG='kr' where lang='ko';
update ASPEN2.lang set OVERRIDE_LANG='kg' where lang='ky';
update ASPEN2.lang set OVERRIDE_LANG='my' where lang='ms';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='mr';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='pa';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='sa';
update ASPEN2.lang set OVERRIDE_LANG='sp' where lang='sr-sp-cyrl';
update ASPEN2.lang set OVERRIDE_LANG='sp' where lang='sr-sp-latn';
update ASPEN2.lang set OVERRIDE_LANG='si' where lang='sl';
update ASPEN2.lang set OVERRIDE_LANG='ke' where lang='sw';
update ASPEN2.lang set OVERRIDE_LANG='sy' where lang='syr';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='ta';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='tt';
update ASPEN2.lang set OVERRIDE_LANG='in' where lang='te';
update ASPEN2.lang set OVERRIDE_LANG='ua' where lang='uk';
update ASPEN2.lang set OVERRIDE_LANG='pk' where lang='ur';
update ASPEN2.lang set OVERRIDE_LANG='uz' where lang='uz-uz-cyrl';
update ASPEN2.lang set OVERRIDE_LANG='uz' where lang='uz-uz-latn';
update ASPEN2.lang set OVERRIDE_LANG='vn' where lang='vi';

/*
update ASPEN2.lang set LANG='no-nb' where lang='nb-no';
update ASPEN2.lang set LANG='no-nn' where lang='nn-no';
*/

update ASPEN2.lang set PARENT_LANG_ID='134' where LANG_ID='135';
update ASPEN2.lang set PARENT_LANG_ID='134' where LANG_ID='136';

/*
update ASPEN2.lang set OVERRIDE_LANG='no' where lang='no-nb';
update ASPEN2.lang set OVERRIDE_LANG='no' where lang='no-nn';
*/

--commit;

@..\..\..\aspen2\npsl.translation\db\tr_body

@update_tail
