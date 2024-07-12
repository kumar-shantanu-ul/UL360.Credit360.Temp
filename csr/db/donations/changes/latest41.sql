-- Please update version.sql too -- this keeps clean builds in sync
define version=41
@update_header

ALTER TABLE DONATION ADD (
    CUSTOM_41                     NUMBER(16, 2),
    CUSTOM_42                     NUMBER(16, 2),
    CUSTOM_43                     NUMBER(16, 2),
    CUSTOM_44                     NUMBER(16, 2),
    CUSTOM_45                     NUMBER(16, 2),
    CUSTOM_46                     NUMBER(16, 2),
    CUSTOM_47                     NUMBER(16, 2),
    CUSTOM_48                     NUMBER(16, 2),
    CUSTOM_49                     NUMBER(16, 2),
    CUSTOM_50                     NUMBER(16, 2),
    CUSTOM_51                     NUMBER(16, 2),
    CUSTOM_52                     NUMBER(16, 2),
    CUSTOM_53                     NUMBER(16, 2),
    CUSTOM_54                     NUMBER(16, 2),
    CUSTOM_55                     NUMBER(16, 2),
    CUSTOM_56                     NUMBER(16, 2),
    CUSTOM_57                     NUMBER(16, 2),
    CUSTOM_58                     NUMBER(16, 2),
    CUSTOM_59                     NUMBER(16, 2),
    CUSTOM_60                     NUMBER(16, 2)
);

@../donation_pkg
@../donation_body
@../budget_body
@../fields_body

@update_tail
