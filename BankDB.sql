USE master
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'BankDB')
DROP DATABASE BankDB

CREATE DATABASE BankDB

GO

USE BankDB

GO

CREATE TABLE SocialStatuses
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	StatusName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_SocialStatuses_Id PRIMARY KEY (Id)
)
CREATE TABLE Clients
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	FirstName NVARCHAR(30) NOT NULL,
	LastName  NVARCHAR(30) NOT NULL,
	FatherName NVARCHAR(30) NOT NULL,
	SocialStatusId INT NOT NULL,

	CONSTRAINT PK_Clients_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Clients_SocialStatusId FOREIGN KEY (SocialStatusId) REFERENCES SocialStatuses (Id)
)
CREATE TABLE Banks
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	BankName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_Banks_Id PRIMARY KEY (Id)
)
CREATE TABLE Accounts
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	ClientId INT NOT NULL,
	BankId INT NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT FK_Accounts_ClientId FOREIGN KEY (ClientId) REFERENCES Clients (Id),
	CONSTRAINT FK_Accounts_BankId FOREIGN KEY (BankId) REFERENCES Banks (Id),
	CONSTRAINT PK_Accounts_Id PRIMARY KEY (Id),
	CONSTRAINT Accounts_ClientId_BankId_Unique UNIQUE (ClientId ,BankId)
)
CREATE TABLE BankCards
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
    CardNumber CHAR(16) NOT NULL,
	AccountId INT NOT NULL,
	ValidThru DATE NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT CardNumber_NumbersCheck CHECK (CardNumber NOT LIKE '%[^0-9]%'),
	CONSTRAINT FK_BankCards_AccountId FOREIGN KEY (AccountId) REFERENCES Accounts (Id),
	CONSTRAINT PK_BankCards_Id PRIMARY KEY (Id)
	
)
CREATE TABLE Cities
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	CityName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_Cities_Id PRIMARY KEY (Id)
)
CREATE TABLE Subsidiaries
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	BankId INT NOT NULL,
	CityId INT NOT NULL,
	Street NVARCHAR(30) NOT NULL,
	BuildingNumber INT NOT NULL,

	CONSTRAINT PK_Subsidiaries_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Subsidiaries_BankId FOREIGN KEY (BankId) REFERENCES Banks (Id),
	CONSTRAINT FK_Subsidiaries_CityId FOREIGN KEY (CityId) REFERENCES Cities (Id)
)


GO

--------------------------------------------------------- Задание 9
/*
Написать триггер на таблицы Account/Cards чтобы нельзя была занести значения в поле баланс
если это противоречит условиям  (то есть нельзя изменить значение в Account на меньшее, чем
сумма балансов по всем карточкам. И соответственно нельзя изменить баланс карты если в итоге
сумма на картах будет больше чем баланс аккаунта)
*/


CREATE TRIGGER AccountBalanceTrigger
ON Accounts
AFTER INSERT, UPDATE
AS
BEGIN
	
	IF 
	(SELECT COUNT(*) 
	 FROM 
	 	 (SELECT ISNULL(SUM(ISNULL(INSERTED.Balance,0.0)),0.0) AS Sums FROM Accounts
		 INNER JOIN INSERTED ON INSERTED.Id = Accounts.Id) AS T1,
		 (SELECT Accounts.Balance FROM Accounts
		 INNER JOIN INSERTED ON INSERTED.Id = Accounts.Id
		 WHERE INSERTED.Id = Accounts.Id) AS T2
		 WHERE T1.Sums < T2.Balance
	) > 0
	BEGIN
	ROLLBACK TRANSACTION
	RAISERROR('На аккаунте баланс меньше, чем на всех картах в сумме',0,1)
	RETURN 
	END
	
END


GO

CREATE TRIGGER BankCardsBalanceTrigger
ON BankCards
AFTER INSERT, UPDATE
AS
BEGIN
SET nocount ON

		IF  
		(SELECT COUNT(*) 
		 FROM 
		 (SELECT ISNULL(SUM(ISNULL(INSERTED.Balance,0.0)),0.0) AS Sums FROM Accounts
		 INNER JOIN INSERTED ON INSERTED.AccountId = Accounts.Id) AS T1,
		 (SELECT Accounts.Balance FROM Accounts
		 INNER JOIN INSERTED ON INSERTED.AccountId = Accounts.Id
		 WHERE INSERTED.AccountId = Accounts.Id) AS T2
		 WHERE T1.Sums > T2.Balance 
		) > 0
		BEGIN
		ROLLBACK TRANSACTION
		RAISERROR('Сумма баланса на картах больше, чем баланс на аккаунте',0,1)
		RETURN 
		END

END


GO

---------------------------------------------------------
--------------------------------------------------------- Задание 1
/*
Прочитать условия запросов и создать структуру базы.
Заполнить базу значениями.
В каждой таблице-словаре минимум по 5 значений.
*/

INSERT INTO SocialStatuses (StatusName)
VALUES 
('Пенсионер'),
('Инвалид'),
('Студент'),
('Инностранец'),
('Ветеран')

INSERT INTO Clients (LastName,FirstName,FatherName, SocialStatusId)
VALUES
('Степаненко','Виктория','Дмитриевна',1),
('Якушенко','Николай','Викторович',2),
('Петрушенко','Василилий','Григорьевич',3),
('Григоренко','Елизовета','Николаевна',3),
('Степаненко','Екатерина','Ивановна',4)

INSERT INTO Banks (BankName)
VALUES
('Беларусбанк'),
('Сбербанк'),
('Альфа банк'),
('Белинвестбанк'),
('Белагропромбанк')

INSERT INTO Accounts (ClientId,BankId,Balance)VALUES (1,2,100.0)
INSERT INTO BankCards (CardNumber,AccountId,ValidThru,Balance) VALUES('3571379056321684',1,'01.05.2024',30.5)
INSERT INTO Accounts (ClientId,BankId,Balance)VALUES (2,4,50.0)
INSERT INTO BankCards (CardNumber,AccountId,ValidThru,Balance) VALUES('2846528656568174',2,'01.09.2025',15.0)
INSERT INTO BankCards (CardNumber,AccountId,ValidThru,Balance) VALUES('8158925677275355',2,'01.01.2026',35.0)
INSERT INTO Accounts (ClientId,BankId,Balance)VALUES (2,3,50.0)
INSERT INTO BankCards (CardNumber,AccountId,ValidThru,Balance) VALUES('6862866224365636',3,'01.06.2023',12.0)
INSERT INTO Accounts (ClientId,BankId,Balance)VALUES (3,1,20.0)
INSERT INTO Accounts (ClientId,BankId,Balance)VALUES (4,5,120.5)
INSERT INTO Accounts (ClientId,BankId,Balance)VALUES (5,1,45.5)
INSERT INTO BankCards (CardNumber,AccountId,ValidThru,Balance) VALUES('9357935382345254',6,'01.02.2025',20.0)
INSERT INTO BankCards (CardNumber,AccountId,ValidThru,Balance) VALUES('2776864688675633',6,'01.08.2026',25.5)

INSERT INTO Cities(CityName)
VALUES
('Новополоцк'),
('Минск'),
('Молодечно'),
('Брест'),
('Витебск')

INSERT INTO Subsidiaries(BankId,CityId,Street,BuildingNumber)
VALUES
(1,1,'Молодежная',242),
(1,1,'Строительная',53),
(2,3,'Комсомольская',22),
(3,2,'Пионерская',13),
(4,5,'Ленина',56),
(5,4,'Комсомольская',7)


---------------------------------------------------------
--------------------------------------------------------- Задание 2
/*
Покажи мне список банков у которых есть филиалы в городе X (выбери один из городов)
*/
GO
CREATE VIEW [Cписок банков с филиалами в Новополоцке]
AS SELECT BankName, Subsidiaries.Street, Subsidiaries.BuildingNumber
FROM Banks
INNER JOIN Subsidiaries ON Banks.Id = Subsidiaries.BankId
INNER JOIN Cities ON Subsidiaries.CityId = Cities.Id
WHERE CityName LIKE ('Новополоцк')
GO

SELECT * FROM [Cписок банков с филиалами в Новополоцке]

---------------------------------------------------------
--------------------------------------------------------- Задание 3
/*
Получить список карточек с указанием имени владельца, баланса и названия банка
*/
GO
CREATE VIEW [Список карточек]
AS SELECT C.LastName AS Фамилия,C.FirstName AS Имя,C.FatherName AS Отчество,BC.Balance AS Баланс,B.BankName AS [Название банка]
FROM BankCards AS BC
INNER JOIN Accounts AS A ON A.Id = BC.AccountId
INNER JOIN Banks AS B ON B.Id = A.BankId
INNER JOIN Clients AS C ON C.Id = A.ClientId
GO

SELECT * FROM [Список карточек]

---------------------------------------------------------
--------------------------------------------------------- Задание 4
/*
Показать список банковских аккаунтов у которых баланс не совпадает с суммой баланса по
карточкам. В отдельной колонке вывести разницу
*/

GO
CREATE VIEW [Список банковских аккаунтов у которых баланс не совпадает с суммой баланса по карточкам]
AS SELECT C.LastName AS Фамилия,C.FirstName AS Имя,C.FatherName AS Отчество,B.BankName AS [Название банка], Разница
FROM 
(
SELECT A.ClientId,A.BankId,A.Balance - SUM(BC.Balance) AS Разница
FROM BankCards AS BC
INNER JOIN Accounts AS A ON A.Id = BC.AccountId
INNER JOIN Banks AS B ON B.Id = A.BankId
INNER JOIN Clients AS C ON C.Id = A.ClientId
GROUP BY A.ClientId,A.BankId,A.Balance
HAVING A.Balance - SUM(BC.Balance) <> 0
) AS T
INNER JOIN Banks AS B ON B.Id = T.BankId
INNER JOIN Clients AS C ON C.Id = T.ClientId
GO

SELECT * FROM [Список банковских аккаунтов у которых баланс не совпадает с суммой баланса по карточкам]

---------------------------------------------------------
--------------------------------------------------------- Задание 5
/*
Вывести кол-во банковских карточек для каждого соц статуса (2 реализации, GROUP BY и
подзапросом)
*/
GO
CREATE VIEW [Количество банковских карточек для каждого социального статуса (GROUP BY)]
AS SELECT SS.StatusName AS [Социальный статус], ISNULL(COUNT(BC.CardNumber),0) AS [Количество карт]
FROM BankCards AS BC
RIGHT JOIN Accounts AS A ON A.Id = BC.AccountId
LEFT JOIN Clients AS C ON C.Id = A.ClientId
RIGHT JOIN SocialStatuses AS SS ON SS.Id = C.SocialStatusId
GROUP BY SS.StatusName
GO
CREATE VIEW [Количество банковских карточек для каждого социального статуса (подзапрос)]
AS SELECT SS.Id,SS.StatusName AS [Социальный статус], 
(SELECT COUNT(*)
FROM BankCards AS BC
INNER JOIN Accounts AS A ON A.Id = BC.AccountId
INNER JOIN Clients AS C ON C.Id = A.ClientId
WHERE SS.Id = C.SocialStatusId
) AS [Количество карт]
FROM SocialStatuses AS SS

GO

SELECT * FROM [Количество банковских карточек для каждого социального статуса (GROUP BY)]
SELECT * FROM [Количество банковских карточек для каждого социального статуса (подзапрос)]

---------------------------------------------------------
--------------------------------------------------------- Задание 6
/*
Написать stored procedure которая будет добавлять по 10$ на каждый банковский аккаунт для
определенного соц статуса (У каждого клиента бывают разные соц. статусы. Например, пенсионер,
инвалид и прочее). Входной параметр процедуры - Id социального статуса. Обработать
исключительные ситуации (например, был введен неверные номер соц. статуса. Либо когда у этого
статуса нет привязанных аккаунтов).
*/
GO
CREATE PROCEDURE GiveMoneyBySocialStatus
	@StatusId INT
AS 
BEGIN
SET XACT_ABORT, NOCOUNT ON

IF @StatusId NOT IN(SELECT Id FROM SocialStatuses) 
BEGIN
RAISERROR('Поле @StatusId не содержится в таблице SocialStatuses',1,1)
RETURN
END
IF (SELECT COUNT(*) FROM Accounts
INNER JOIN Clients ON Clients.Id = Accounts.ClientId
WHERE Clients.SocialStatusId = @StatusId) = 0
BEGIN
RAISERROR('У поля @StatusId нет привязанный аккаунтов',0,1)
RETURN
END

UPDATE Accounts
SET Balance = Balance + 10
FROM Accounts AS A
INNER JOIN Clients AS C ON C.Id = A.ClientId
INNER JOIN SocialStatuses AS SS ON SS.Id = C.SocialStatusId
WHERE SS.Id = @StatusId
END
GO

SELECT * FROM Accounts
EXEC GiveMoneyBySocialStatus 3
SELECT * FROM Accounts


SELECT * FROM Accounts
EXEC GiveMoneyBySocialStatus 999999
SELECT * FROM Accounts
EXEC GiveMoneyBySocialStatus 5
SELECT * FROM Accounts

---------------------------------------------------------
--------------------------------------------------------- Задание 7
/*
Получить список доступных средств для каждого клиента. То есть если у клиента на банковском
аккаунте 60 рублей, и у него 2 карточки по 15 рублей на каждой, то у него доступно 30 рублей для
перевода на любую из карт
*/
GO
CREATE VIEW [Cписок доступных средств для каждого клиента в банке]
AS SELECT A.Id AS [Id Аккаунта],C.LastName AS Фамилия,C.FirstName AS Имя,C.FatherName AS Отчество,B.BankName AS [Название банка],AccountBalance AS [Сумма на аккаунте] ,[Доступная сумма]
FROM 
(
SELECT A.ClientId,A.BankId, SUM(A.Balance) / COUNT(A.BankId) AS AccountBalance,ISNULL(SUM(ISNULL(BC.Balance,0)),0) AS [Доступная сумма]
FROM Clients AS C
INNER JOIN Accounts AS A ON A.ClientId = C.Id
INNER JOIN Banks AS B ON B.Id = A.BankId
LEFT JOIN BankCards AS BC ON A.Id = BC.AccountId
GROUP BY A.BankId,A.ClientId
) AS T
INNER JOIN Accounts AS A ON A.ClientId = T.ClientId AND A.BankId = T.BankId
INNER JOIN Banks AS B ON B.Id = T.BankId
INNER JOIN Clients AS C ON C.Id = T.ClientId
GO
CREATE VIEW [Cписок доступных средств для каждого клиента в сумме со всех его банков]
AS 
SELECT clientView.Фамилия,clientView.Имя,clientView.Отчество,
SUM(clientView.[Сумма на аккаунте]) AS [Сумма на аккаунтах],SUM(clientView.[Доступная сумма]) AS [Доступная сумма]
FROM [Cписок доступных средств для каждого клиента в банке] AS clientView
GROUP BY clientView.Фамилия,clientView.Имя,clientView.Отчество

GO

SELECT * FROM [Cписок доступных средств для каждого клиента в банке]
SELECT * FROM [Cписок доступных средств для каждого клиента в сумме со всех его банков]

---------------------------------------------------------
--------------------------------------------------------- Задание 8
/*
Написать процедуру которая будет переводить определённую сумму со счёта на карту этого
аккаунта. При этом будем считать что деньги на счёту все равно останутся, просто сумма средств
на карте увеличится. Например, у меня есть аккаунт на котором 1000 рублей и две карты по 300
рублей на каждой. Я могу перевести 200 рублей на одну из карт, при этом баланс аккаунта
останется 1000 рублей, а на картах будут суммы 300 и 500 рублей соответственно. После этого я
уже не смогу перевести 400 рублей с аккаунта ни на одну из карт, так как останется всего 200
свободных рублей (1000-300-500). Переводить БЕЗОПАСНО. То есть использовать транзакцию.
*/

GO
CREATE PROCEDURE TransferMoneyFromAccountToCard
	@AccountId INT,
	@Money MONEY,
	@CardNumber VARCHAR(16)
AS 
BEGIN
SET XACT_ABORT, NOCOUNT ON

IF @Money <= 0
BEGIN
RAISERROR('Поле @Money меньше либо равно 0',0,1)
RETURN
END
IF @AccountId NOT IN(SELECT Id FROM Accounts) 
BEGIN
RAISERROR('Поле @AccountId не содержится в таблице Accounts',0,1)
RETURN
END
IF @CardNumber NOT IN(SELECT CardNumber FROM BankCards) 
BEGIN
RAISERROR('Поле @CardNumber не содержится в таблице BankCard',0,1)
RETURN
END

IF (SELECT COUNT(*) FROM Accounts AS A
	INNER JOIN BankCards AS BC ON A.Id = BC.AccountId
	WHERE A.Id = @AccountId AND BC.CardNumber = @CardNumber) <> 1
BEGIN
RAISERROR('Поле @CardNumber не содержится на аккаунте @AccountId',0,1)
RETURN
END

DECLARE @MoneyCanTransfer MONEY

SELECT @MoneyCanTransfer = List.[Сумма на аккаунте] - List.[Доступная сумма]
FROM [Cписок доступных средств для каждого клиента в банке] AS List
WHERE List.[Id Аккаунта] = @AccountId

IF @MoneyCanTransfer < @Money
BEGIN
RAISERROR('Поле @Money больше возможной пересылки средств',0,1)
RETURN
END


BEGIN TRY
BEGIN TRANSACTION

UPDATE BankCards SET Balance = Balance + @Money
WHERE BankCards.CardNumber = @CardNumber

END TRY
BEGIN CATCH
ROLLBACK TRANSACTION
RETURN
END CATCH
COMMIT TRANSACTION

END
GO


SELECT * FROM BankCards
EXEC TransferMoneyFromAccountToCard 1,50,'3571379056321684'
SELECT * FROM BankCards


SELECT * FROM BankCards
EXEC TransferMoneyFromAccountToCard 1,0,'3571379056321684'
SELECT * FROM BankCards
EXEC TransferMoneyFromAccountToCard 99999,10,'3571379056321684'
SELECT * FROM BankCards
EXEC TransferMoneyFromAccountToCard 1,10,'1111111111111111'
SELECT * FROM BankCards
EXEC TransferMoneyFromAccountToCard 1,10,'6862866224365636'
SELECT * FROM BankCards
EXEC TransferMoneyFromAccountToCard 1,999999,'3571379056321684'
SELECT * FROM BankCards



---------------------------------------------------------
