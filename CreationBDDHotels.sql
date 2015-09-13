CREATE TABLE Reservations (
	NumCL numeric(10) REFERENCES CLIENTS,
	NumHo numeric(10) REFERENCES Hotels,
	NumTy numeric(10) REFERENCES TypesChambre,
	DateA TIMESTAMP(0),
	NbJours INTERVAL DAY TO SECOND(0) default INTERVAL '1' DAY NOT NULL,
	NbChambres numeric(10) default 1 NOT NULL,
	PRIMARY KEY (NumCl, NumHo, NumTy, DateA)
);

CREATE TABLE Hotels (
	NumHo numeric(10),
	NomHo VARCHAR(99),
	RueAdrHo VARCHAR(99),
	VilleHo VARCHAR(99),
	NbEtoilesHo numeric(1),
	PRIMARY KEY (NumHo)
);

CREATE TABLE TypesChambre (
	NumTy numeric(10),
	NomTy VARCHAR(99),
	PrixTy integer,
	PRIMARY KEY (NumTy)
);

CREATE TABLE Chambres (
	NumCh numeric(10),
	NumHo numeric(10) REFERENCES Hotels,
	NumTy numeric(10) REFERENCES TypesChambre,
	PRIMARY KEY (NumCh, NumHo)
);

CREATE TABLE Clients (
	NumCl numeric(10),
	NomCl VARCHAR(99),
	PrenomCl VARCHAR(99),
	RueAdrCl VARCHAR(99),
	VilleCl VARCHAR(99),
	Primary KEY (NumCl)
);

CREATE TABLE Occupations (
	NumCl numeric(10) REFERENCES Clients,
	NumHo numeric(10) REFERENCES Hotels,
	NumCh numeric(10) REFERENCES Chambres,
	DateA TIMESTAMP(0) REFERENCES Reservations,
	DateD TIMESTAMP(0),
	PRIMARY KEY (NumHo, NumCh, DateA)
);