-- Please update version.sql too -- this keeps clean builds in sync
define version=47
@update_header

ALTER TABLE DONATION ADD (
	CUSTOM_91                     NUMBER(16, 2),
	CUSTOM_92                     NUMBER(16, 2),
	CUSTOM_93                     NUMBER(16, 2),
	CUSTOM_94                     NUMBER(16, 2),
	CUSTOM_95                     NUMBER(16, 2),
	CUSTOM_96                     NUMBER(16, 2),
	CUSTOM_97                     NUMBER(16, 2),
	CUSTOM_98                     NUMBER(16, 2),
	CUSTOM_99                     NUMBER(16, 2),
	CUSTOM_100                     NUMBER(16, 2),
	CUSTOM_101                     NUMBER(16, 2),
	CUSTOM_102                     NUMBER(16, 2),
	CUSTOM_103                     NUMBER(16, 2),
	CUSTOM_104                     NUMBER(16, 2),
	CUSTOM_105                     NUMBER(16, 2),
	CUSTOM_106                     NUMBER(16, 2),
	CUSTOM_107                     NUMBER(16, 2),
	CUSTOM_108                     NUMBER(16, 2),
	CUSTOM_109                     NUMBER(16, 2),
	CUSTOM_110                     NUMBER(16, 2),
	CUSTOM_111                     NUMBER(16, 2),
	CUSTOM_112                     NUMBER(16, 2),
	CUSTOM_113                     NUMBER(16, 2),
	CUSTOM_114                     NUMBER(16, 2),
	CUSTOM_115                     NUMBER(16, 2),
	CUSTOM_116                     NUMBER(16, 2),
	CUSTOM_117                     NUMBER(16, 2),
	CUSTOM_118                     NUMBER(16, 2),
	CUSTOM_119                     NUMBER(16, 2),
	CUSTOM_120                     NUMBER(16, 2)
);

@../donation_pkg
@../donation_body
@../budget_body
@../fields_body


@update_tail
