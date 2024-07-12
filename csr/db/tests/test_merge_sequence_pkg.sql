CREATE OR REPLACE PACKAGE csr.test_merge_sequence_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

-- Tests
PROCEDURE MergeWithInlineSequenceWithNoRecords;
PROCEDURE MergeWithInlineSequenceWithRecords;
PROCEDURE MergeWithJITSequenceWithNoRecords;
PROCEDURE MergeWithJITSequenceWithRecords;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_merge_sequence_pkg;
/
