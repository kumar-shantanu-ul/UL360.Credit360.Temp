
alter table donation_Status add (
    INCLUDE_VALUE_IN_REPORTS    NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    MEANS_PAID    NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    POS    NUMBER(10, 0)      DEFAULT 0 NOT NULL);

alter table tag_group_member add (
    IS_VISIBLE       NUMBER(1, 0)      DEFAULT 1 NOT NULL);

alter table tag_group add (
    RENDER_AS        CHAR(1)           DEFAULT 'X' NOT NULL,
    RENDER_IN        CHAR(1)           DEFAULT 'V' NOT NULL);

alter table scheme_tag_group add (
    POS              NUMBER(10, 0)     DEFAULT 0 NOT NULL);


CREATE SEQUENCE DONATION_STATUS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
