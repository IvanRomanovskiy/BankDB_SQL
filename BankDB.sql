USE master
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'BankDB')
DROP DATABASE BankDB

CREATE DATABASE BankDB

GO

USE BankDB

GO

CREATE TABLE SocialStatus
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	StatusName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_SocialStatus_Id PRIMARY KEY (Id)
)
CREATE TABLE Client
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	FirstName NVARCHAR(30) NOT NULL,
	LastName  NVARCHAR(30) NOT NULL,
	FatherName NVARCHAR(30) NOT NULL,
	SocialStatusId INT NOT NULL,

	CONSTRAINT PK_Client_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Client_IdSocialStatus FOREIGN KEY (SocialStatusId) REFERENCES SocialStatus (Id)
)
CREATE TABLE Bank
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	BankName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_Bank_Id PRIMARY KEY (Id)
)
CREATE TABLE Account
(
	IdClient INT NOT NULL,
	IdBank INT NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT FK_Account_IdClient FOREIGN KEY (IdClient) REFERENCES Client (Id),
	CONSTRAINT FK_Account_IdBank FOREIGN KEY (IdBank) REFERENCES Bank (Id),
	CONSTRAINT PK_Account_Ids_IdClient_IdBank PRIMARY KEY (IdClient,IdBank)

)
CREATE TABLE BankCard
(
    CardNumber VARCHAR(16) NOT NULL CHECK (CardNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	IdClient INT NOT NULL,
	IdBank INT NOT NULL,
	ValidThru DATE NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT FK_BankCard_IdClient FOREIGN KEY (IdClient,IdBank) REFERENCES Account (IdClient,IdBank),
	CONSTRAINT PK_BankCard_Ids_IdClient_IdBank PRIMARY KEY (CardNumber)
)
CREATE TABLE City
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	CityName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_City_Id PRIMARY KEY (Id)
)
CREATE TABLE Subsidiary
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	IdBank INT NOT NULL,
	IdCity INT NOT NULL,
	Street NVARCHAR(30) NOT NULL,
	BuildingNumber INT NOT NULL,

	CONSTRAINT PK_Subsidiary_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Subsidiary_IdBank FOREIGN KEY (IdBank) REFERENCES Bank (Id),
	CONSTRAINT FK_Subsidiary_IdCity FOREIGN KEY (IdCity) REFERENCES City (Id)
)


GO

CREATE VIEW [C����� ������ � ��������� � �����������]
AS SELECT BankName
FROM Bank
INNER JOIN Subsidiary ON Bank.Id = Subsidiary.IdBank
INNER JOIN City ON Subsidiary.IdCity = City.Id
WHERE CityName LIKE ('����������')
GROUP BY BankName

GO

CREATE VIEW [������ ��������]
AS SELECT C.LastName AS �������,C.FirstName AS ���,C.FatherName AS ��������,BC.Balance AS ������,B.BankName AS [�������� �����]
FROM BankCard AS BC
INNER JOIN Account AS A ON A.IdBank = BC.IdBank AND A.IdClient = BC.IdClient
INNER JOIN Bank AS B ON B.Id = A.IdBank
INNER JOIN Client AS C ON C.Id = A.IdClient

GO

CREATE VIEW [������ ���������� ��������� � ������� ������ �� ��������� � ������ ������� �� ���������]
AS SELECT C.LastName AS �������,C.FirstName AS ���,C.FatherName AS ��������,B.BankName AS [�������� �����], �������
FROM 
(
SELECT BC.IdClient,BC.IdBank,A.Balance - SUM(BC.Balance) AS �������
FROM BankCard AS BC
INNER JOIN Account AS A ON A.IdBank = BC.IdBank AND A.IdClient = BC.IdClient
INNER JOIN Bank AS B ON B.Id = A.IdBank
INNER JOIN Client AS C ON C.Id = A.IdClient
GROUP BY BC.IdClient,BC.IdBank,A.Balance
HAVING A.Balance - SUM(BC.Balance) <> 0
) AS T
INNER JOIN Bank AS B ON B.Id = T.IdBank
INNER JOIN Client AS C ON C.Id = T.IdClient

GO

CREATE VIEW [���������� ���������� �������� ��� ������� ����������� ������� (GROUP BY)]
AS SELECT SS.StatusName AS [���������� ������], ISNULL(COUNT(BC.CardNumber),0) AS [���������� ����]
FROM BankCard AS BC
RIGHT JOIN Account AS A ON A.IdClient = BC.IdClient AND A.IdBank = BC.IdBank
LEFT JOIN Client AS C ON C.Id = A.IdClient
RIGHT JOIN SocialStatus AS SS ON SS.Id = C.SocialStatusId
GROUP BY SS.StatusName



GO

CREATE VIEW [���������� ���������� �������� ��� ������� ����������� ������� (���������)]
AS SELECT SS.Id,SS.StatusName AS [���������� ������], 
(SELECT COUNT(*)
FROM BankCard AS BC
INNER JOIN Account AS A ON A.IdBank = BC.IdBank AND A.IdClient = BC.IdClient
INNER JOIN Client AS C ON C.Id = A.IdClient
WHERE SS.Id = C.SocialStatusId
) AS [���������� ����]
FROM SocialStatus AS SS

GO

CREATE VIEW [C����� ��������� ������� ��� ������� ������� � �����]
AS SELECT C.Id AS [Id �������],A.IdBank AS [Id �����],C.LastName AS �������,C.FirstName AS ���,C.FatherName AS ��������,B.BankName AS [�������� �����],AccountBalance AS [����� �� ��������] ,[��������� �����]
FROM 
(
SELECT A.IdClient,A.IdBank, SUM(A.Balance) / COUNT(A.IdBank) AS AccountBalance,ISNULL(SUM(ISNULL(BC.Balance,0)),0) AS [��������� �����]
FROM Client AS C
INNER JOIN Account AS A ON A.IdClient = C.Id
INNER JOIN Bank AS B ON B.Id = A.IdBank
LEFT JOIN BankCard AS BC ON BC.IdBank = B.Id AND BC.IdClient = C.Id
GROUP BY A.IdBank,A.IdClient
) AS T
INNER JOIN Account AS A ON A.IdClient = T.IdClient AND A.IdBank = T.IdBank
INNER JOIN Bank AS B ON B.Id = T.IdBank
INNER JOIN Client AS C ON C.Id = T.IdClient

GO

CREATE VIEW [C����� ��������� ������� ��� ������� ������� � ����� �� ���� ��� ������]
AS 
SELECT clientView.[Id �������],clientView.�������,clientView.���,clientView.��������,
SUM(clientView.[����� �� ��������]) AS [����� �� ���������],SUM(clientView.[��������� �����]) AS [��������� �����]
FROM [C����� ��������� ������� ��� ������� ������� � �����] AS clientView
GROUP BY clientView.[Id �������],clientView.�������,clientView.���,clientView.��������

GO

CREATE TRIGGER AccountBalanceTrigger
ON Account
AFTER INSERT, UPDATE
AS
BEGIN
	
	IF 
	(SELECT COUNT(*) 
	 FROM 
	 	 (SELECT ISNULL(SUM(ISNULL(INSERTED.Balance,0.0)),0.0) AS Sums FROM Account
		 INNER JOIN INSERTED ON INSERTED.IdBank = Account.IdBank AND INSERTED.IdClient = Account.IdClient) AS T1,
		 (SELECT Account.Balance FROM Account
		 INNER JOIN INSERTED ON INSERTED.IdBank = Account.IdBank AND INSERTED.IdClient = Account.IdClient
		 WHERE INSERTED.IdBank = Account.IdBank AND INSERTED.IdClient = Account.IdClient) AS T2
		 WHERE T1.Sums < T2.Balance
	) > 0
	BEGIN
	ROLLBACK TRANSACTION
	RAISERROR('�� �������� ������ ������, ��� �� ���� ������ � �����',0,1)
	RETURN 
	END
	
END


GO

CREATE TRIGGER BankCardsBalanceTrigger
ON BankCard
AFTER INSERT, UPDATE
AS
BEGIN
SET nocount ON

		IF  
		(SELECT COUNT(*) 
		 FROM 
		 (SELECT ISNULL(SUM(ISNULL(INSERTED.Balance,0.0)),0.0) AS Sums FROM Account
		 INNER JOIN INSERTED ON INSERTED.IdBank = Account.IdBank AND INSERTED.IdClient = Account.IdClient) AS T1,
		 (SELECT Account.Balance FROM Account
		 INNER JOIN INSERTED ON INSERTED.IdBank = Account.IdBank AND INSERTED.IdClient = Account.IdClient
		 WHERE INSERTED.IdBank = Account.IdBank AND INSERTED.IdClient = Account.IdClient) AS T2
		 WHERE T1.Sums > T2.Balance 
		) > 0
		BEGIN
		ROLLBACK TRANSACTION
		RAISERROR('����� ������� �� ������ ������, ��� ������ �� ��������',0,1)
		RETURN 
		END

END


GO

CREATE PROCEDURE GiveMoneyBySocialStatus
	@StatusId INT,
	@Money MONEY
AS 
BEGIN
SET XACT_ABORT, NOCOUNT ON

IF @StatusId NOT IN(SELECT Id FROM SocialStatus) 
BEGIN
RAISERROR('���� @StatusId �� ���������� � ������� SocialStatus',1,1)
RETURN
END
IF @Money <= 0
BEGIN
RAISERROR('���� @Money ������ ���� ����� 0',0,1)
RETURN
END
IF (SELECT COUNT(*) FROM Account
INNER JOIN Client ON Client.Id = Account.IdClient
WHERE Client.SocialStatusId = @StatusId) = 0
BEGIN
RAISERROR('� ���� @StatusId ��� ����������� ���������',0,1)
RETURN
END

UPDATE Account
SET Balance = Balance + @Money
FROM Account AS A
INNER JOIN Client AS C ON C.Id = A.IdClient
INNER JOIN SocialStatus AS SS ON SS.Id = C.SocialStatusId
WHERE SS.Id = @StatusId
END

GO

CREATE PROCEDURE TransferMoneyFromAccountToCard
	@ClientId INT,
	@BankId INT,
	@Money MONEY,
	@CardNumber VARCHAR(16)
AS 
BEGIN
SET XACT_ABORT, NOCOUNT ON

IF @Money <= 0
BEGIN
RAISERROR('���� @Money ������ ���� ����� 0',0,1)
RETURN
END
IF @ClientId NOT IN(SELECT Id FROM Client) 
BEGIN
RAISERROR('���� @StatusId �� ���������� � ������� Client',0,1)
RETURN
END
IF @BankId NOT IN(SELECT Id FROM Bank) 
BEGIN
RAISERROR('���� @BankId �� ���������� � ������� Bank',0,1)
RETURN
END
IF (SELECT COUNT(*) FROM Account
	WHERE Account.IdBank = @BankId AND Account.IdClient = @ClientId) = 0
BEGIN
RAISERROR('���� @BankId � @StatusId �� ���������� � ������� Account',0,1)
RETURN
END
IF @CardNumber NOT IN(SELECT CardNumber FROM BankCard) 
BEGIN
RAISERROR('���� @CardNumber �� ���������� � ������� BankCard',0,1)
RETURN
END

IF (SELECT COUNT(*) FROM Account AS A
	INNER JOIN BankCard AS BC ON BC.IdBank = A.IdBank AND BC.IdClient = A.IdClient
	WHERE BC.IdClient = @ClientId AND BC.IdBank = @BankId AND BC.CardNumber = @CardNumber) <> 1
BEGIN
RAISERROR('���� @CardNumber �� ���������� �� �������� � ������ @BankId � @ClientId',0,1)
RETURN
END

DECLARE @MoneyCanTransfer MONEY

SELECT @MoneyCanTransfer = List.[����� �� ��������] - List.[��������� �����]
FROM [C����� ��������� ������� ��� ������� ������� � �����] AS List
WHERE List.[Id �������] = @ClientId AND List.[Id �����] = @BankId

IF @MoneyCanTransfer < @Money
BEGIN
RAISERROR('���� @Money ������ ��������� ��������� �������',0,1)
RETURN
END


BEGIN TRY
BEGIN TRANSACTION

UPDATE BankCard SET Balance = Balance + @Money
WHERE BankCard.CardNumber = @CardNumber

END TRY
BEGIN CATCH
ROLLBACK TRANSACTION
RETURN
END CATCH
COMMIT TRANSACTION

END
GO

INSERT INTO SocialStatus (StatusName)
VALUES 
('���������'),
('�������'),
('�������'),
('�����������'),
('�������')

INSERT INTO Client (LastName,FirstName,FatherName, SocialStatusId)
VALUES
('����������','��������','����������',1),
('��������','�������','����������',2),
('����������','���������','�����������',3),
('����������','���������','����������',3),
('����������','���������','��������',4)

INSERT INTO Bank (BankName)
VALUES
('�����������'),
('��������'),
('����� ����'),
('�������������'),
('���������������')

INSERT INTO Account (IdClient,IdBank,Balance)VALUES (1,2,100.0)
INSERT INTO BankCard (CardNumber,IdClient,IdBank,ValidThru,Balance) VALUES('3571379056321684',1,2,'01.05.2024',30.5)
INSERT INTO Account (IdClient,IdBank,Balance)VALUES (2,4,50.0)
INSERT INTO BankCard (CardNumber,IdClient,IdBank,ValidThru,Balance) VALUES('2846528656568174',2,4,'01.09.2025',15.0)
INSERT INTO BankCard (CardNumber,IdClient,IdBank,ValidThru,Balance) VALUES('8158925677275355',2,4,'01.01.2026',35.0)
INSERT INTO Account (IdClient,IdBank,Balance)VALUES (2,3,50.0)
INSERT INTO BankCard (CardNumber,IdClient,IdBank,ValidThru,Balance) VALUES('6862866224365636',2,3,'01.06.2023',12.0)
INSERT INTO Account (IdClient,IdBank,Balance)VALUES (3,1,20.0)
INSERT INTO Account (IdClient,IdBank,Balance)VALUES (4,5,120.5)
INSERT INTO Account (IdClient,IdBank,Balance)VALUES (5,1,45.5)
INSERT INTO BankCard (CardNumber,IdClient,IdBank,ValidThru,Balance) VALUES('9357935382345254',5,1,'01.02.2025',20.0)
INSERT INTO BankCard (CardNumber,IdClient,IdBank,ValidThru,Balance) VALUES('2776864688675633',5,1,'01.08.2026',25.5)

INSERT INTO City (CityName)
VALUES
('����������'),
('�����'),
('���������'),
('�����'),
('�������')

INSERT INTO Subsidiary(IdBank,IdCity,Street,BuildingNumber)
VALUES
(1,1,'����������',242),
(1,1,'������������',53),
(2,3,'�������������',22),
(3,2,'����������',13),
(4,5,'������',56),
(5,4,'�������������',7)

GO

SELECT *
FROM Account

EXEC GiveMoneyBySocialStatus 3,10

SELECT *
FROM Account


SELECT *
FROM BankCard

EXEC TransferMoneyFromAccountToCard 1,2,50,'3571379056321684'

SELECT *
FROM BankCard