CREATE DATABASE TestErrorWhileLockedInTrigger

USE TestErrorWhileLockedInTrigger

CREATE TABLE TableToTriggerAndLock
(
  RowID INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
  ShouldLockTable BIT NOT NULL
)

CREATE TABLE TableToGenerateError
(
  RowID INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
  NotNullableColumn INT NOT NULL
)

GO

CREATE TRIGGER TR_TableToTriggerAndLock_Insert ON TableToTriggerAndLock INSTEAD OF INSERT
AS

DECLARE @ShouldLockTable BIT

SELECT @ShouldLockTable = ShouldLockTable
  FROM INSERTED

INSERT INTO TableToTriggerAndLock (ShouldLockTable)
SELECT ShouldLockTable
  FROM INSERTED

IF @ShouldLockTable <> 0
BEGIN
  SELECT TOP 0 *
    FROM TableToTriggerAndLock WITH (TABLOCKX, HOLDLOCK)
END

BEGIN TRY
  INSERT INTO TableToGenerateError (NotNullableColumn) VALUES (NULL)
END TRY
BEGIN CATCH
  WAITFOR DELAY '00:00:02'
  ROLLBACK TRANSACTION;

  DECLARE @ErrorMessage NVARCHAR(2047) = REPLACE(ERROR_MESSAGE(), '%', '%%')

  RAISERROR (@ErrorMessage, 20, 1) WITH LOG
END CATCH

GO

CREATE PROCEDURE TableToTriggerAndLock_Insert
  @ShouldLockTable BIT
AS
DECLARE @Results TABLE (RowID INT NOT NULL, ShouldLockTable BIT NOT NULL)

INSERT INTO TableToTriggerAndLock (ShouldLockTable) OUTPUT INSERTED.* INTO @Results VALUES (@ShouldLockTable)

SELECT * FROM @Results
