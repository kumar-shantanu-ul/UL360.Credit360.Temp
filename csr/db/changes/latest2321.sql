-- Please update version.sql too -- this keeps clean builds in sync
define version=2321
@update_header

ALTER TABLE chain.invitation_batch ADD lang VARCHAR2(20);

ALTER TABLE chain.invitation_batch ADD CONSTRAINT FK_INVIT_BATCH_TRANSLATION_SET
	FOREIGN KEY(app_sid, lang) REFERENCES aspen2.translation_set(application_sid, lang);

@../chain/invitation_pkg

@../chain/invitation_body

@update_tail