CREATE DATABASE TestErrorWhileLockedInTrigger

USE TestErrorWhileLockedInTrigger

CREATE TABLE TableToTriggerAndLock
(
  RowID INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
  Value NVARCHAR(100) NULL
)

CREATE TABLE TableToGenerateError
(
  RowID INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
  NotNullableColumn INT NOT NULL
)

GO

CREATE TRIGGER TR_TableToTriggerAndLock_Insert ON TableToTriggerAndLock INSTEAD OF INSERT
AS

SELECT TOP 0 *
  FROM TableToTriggerAndLock WITH (TABLOCKX, HOLDLOCK)

INSERT INTO TableToGenerateError (NotNullableColumn) VALUES (NULL)

GO

CREATE PROCEDURE TableToTriggerAndLock_Insert
  @Value NVARCHAR(100)
AS
DECLARE @Results TABLE (RowID INT NOT NULL, Value NVARCHAR(100) NULL)

INSERT INTO TableToTriggerAndLock (Value) OUTPUT INSERTED.* INTO @Results VALUES (@Value)

SELECT * FROM @Results
