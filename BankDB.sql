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

	CONSTRAINT PK_Client_Id PRIMARY KEY (Id)
)
CREATE TABLE Client_SocialStatus
(
	IdClient INT NOT NULL,
	IdSocialStatus INT NOT NULL,

	CONSTRAINT FK_Client_SocialStatus_IdClient FOREIGN KEY (IdClient) REFERENCES Client (Id),
	CONSTRAINT FK_Client_SocialStatus_IdSocialStatus FOREIGN KEY (IdSocialStatus) REFERENCES Socialstatus (Id),

	CONSTRAINT PK_Client_SocialStatus_Ids_Client_SocialStatus PRIMARY KEY (IdClient,IdSocialStatus)
)

CREATE TABLE Bank
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	BankName NVARCHAR(30) UNIQUE NOT NULL,

	CONSTRAINT PK_Bank_Id PRIMARY KEY (Id)
)

CREATE TABLE Account
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	IdClient INT NOT NULL,
	IdBank INT NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT PK_Account_Id PRIMARY KEY (Id),
	CONSTRAINT FK_Account_IdClient FOREIGN KEY (IdClient) REFERENCES Client (Id),
	CONSTRAINT FK_Account_IdBank FOREIGN KEY (IdBank) REFERENCES Bank (Id)
)

CREATE TABLE BankCard
(
	Id INT IDENTITY(1,1) UNIQUE NOT NULL,
	IdAccount INT NOT NULL,
	Balance MONEY NOT NULL,

	CONSTRAINT PK_BankCard_Id PRIMARY KEY (Id),
	CONSTRAINT FK_BankCard_IdAccount FOREIGN KEY (IdAccount) REFERENCES Account (Id)
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

INSERT INTO SocialStatus (StatusName)
VALUES 
('Пенсионер'),
('Инвалид'),
('Студент'),
('Инностранец'),
('Ветеран')

INSERT INTO Client (LastName,FirstName,FatherName)
VALUES
('Степаненко','Виктория','Дмитриевна'),
('Якушенко','Николай','Викторович'),
('Романовский','Иван','Васильевич'),
('Григоренко','Елизовета','Николаевна'),
('Степаненко','Екатерина','Ивановна')

INSERT INTO Client_SocialStatus (IdClient,IdSocialStatus)
VALUES
(1,1),
(1,1),
(1,2),
(1,3),
(1,4)