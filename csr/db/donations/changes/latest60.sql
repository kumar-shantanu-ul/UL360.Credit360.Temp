-- Please update version.sql too -- this keeps clean builds in sync
define version=60
@update_header

ALTER TABLE donations.DONATION ADD (
	CUSTOM_221                     NUMBER(16, 2),
	CUSTOM_222                     NUMBER(16, 2),
	CUSTOM_223                     NUMBER(16, 2),
	CUSTOM_224                     NUMBER(16, 2),
	CUSTOM_225                     NUMBER(16, 2),
	CUSTOM_226                     NUMBER(16, 2),
	CUSTOM_227                     NUMBER(16, 2),
	CUSTOM_228                     NUMBER(16, 2),
	CUSTOM_229                     NUMBER(16, 2),
	CUSTOM_230                     NUMBER(16, 2),
	CUSTOM_231                     NUMBER(16, 2),
	CUSTOM_232                     NUMBER(16, 2),
	CUSTOM_233                     NUMBER(16, 2),
	CUSTOM_234                     NUMBER(16, 2),
	CUSTOM_235                     NUMBER(16, 2),
	CUSTOM_236                     NUMBER(16, 2),
	CUSTOM_237                     NUMBER(16, 2),
	CUSTOM_238                     NUMBER(16, 2),
	CUSTOM_239                     NUMBER(16, 2),
	CUSTOM_240                     NUMBER(16, 2),
	CUSTOM_241                     NUMBER(16, 2),
	CUSTOM_242                     NUMBER(16, 2),
	CUSTOM_243                     NUMBER(16, 2),
	CUSTOM_244                     NUMBER(16, 2),
	CUSTOM_245                     NUMBER(16, 2),
	CUSTOM_246                     NUMBER(16, 2),
	CUSTOM_247                     NUMBER(16, 2),
	CUSTOM_248                     NUMBER(16, 2),
	CUSTOM_249                     NUMBER(16, 2),
	CUSTOM_250                     NUMBER(16, 2),
	CUSTOM_251                     NUMBER(16, 2),
	CUSTOM_252                     NUMBER(16, 2),
	CUSTOM_253                     NUMBER(16, 2),
	CUSTOM_254                     NUMBER(16, 2),
	CUSTOM_255                     NUMBER(16, 2),
	CUSTOM_256                     NUMBER(16, 2),
	CUSTOM_257                     NUMBER(16, 2),
	CUSTOM_258                     NUMBER(16, 2),
	CUSTOM_259                     NUMBER(16, 2),
	CUSTOM_260                     NUMBER(16, 2)
);

@../donation_pkg
@../donation_body
@../budget_body
@../fields_body

@update_tail
