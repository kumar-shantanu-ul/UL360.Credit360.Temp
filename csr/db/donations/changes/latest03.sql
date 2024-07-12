
alter table donation_Status add (
    MEANS_DONATED    NUMBER(1, 0)      DEFAULT 1 NOT NULL
);


alter table donation modify donated_dtm null;
