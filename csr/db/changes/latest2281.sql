-- Please update version.sql too -- this keeps clean builds in sync
define version=2281
@update_header

INSERT INTO aspen2.lang(lang, description, lang_id,parent_lang_id,override_lang)
VALUES ('kh', 'Khmer - Cambodia', 202, NULL, NULL);

@update_tail