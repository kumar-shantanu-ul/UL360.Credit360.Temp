-- Please update version.sql too -- this keeps clean builds in sync
define version=44
@update_header


ALTER TABLE DONATION ADD (
    CUSTOM_61                     NUMBER(16, 2),
    CUSTOM_62                     NUMBER(16, 2),
    CUSTOM_63                     NUMBER(16, 2),
    CUSTOM_64                     NUMBER(16, 2),
    CUSTOM_65                     NUMBER(16, 2),
    CUSTOM_66                     NUMBER(16, 2),
    CUSTOM_67                     NUMBER(16, 2),
    CUSTOM_68                     NUMBER(16, 2),
    CUSTOM_69                     NUMBER(16, 2),
    CUSTOM_70                     NUMBER(16, 2),
    CUSTOM_71                     NUMBER(16, 2),
    CUSTOM_72                     NUMBER(16, 2),
    CUSTOM_73                     NUMBER(16, 2),
    CUSTOM_74                     NUMBER(16, 2),
    CUSTOM_75                     NUMBER(16, 2),
    CUSTOM_76                     NUMBER(16, 2),
    CUSTOM_77                     NUMBER(16, 2),
    CUSTOM_78                     NUMBER(16, 2),
    CUSTOM_79                     NUMBER(16, 2),
    CUSTOM_80                     NUMBER(16, 2),
    CUSTOM_81                     NUMBER(16, 2),
    CUSTOM_82                     NUMBER(16, 2),
    CUSTOM_83                     NUMBER(16, 2),
    CUSTOM_84                     NUMBER(16, 2),
    CUSTOM_85                     NUMBER(16, 2),
    CUSTOM_86                     NUMBER(16, 2),
    CUSTOM_87                     NUMBER(16, 2),
    CUSTOM_88                     NUMBER(16, 2),
    CUSTOM_89                     NUMBER(16, 2),
    CUSTOM_90                     NUMBER(16, 2)
);

@../donation_pkg
@../donation_body
@../budget_body
@../fields_body

@update_tail
