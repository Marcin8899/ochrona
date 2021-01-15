/*Treść zadania 1: */

/* Z1
** Stworzymy narzędzia
** 0) Tabele/procedury mają działać dla wszyskich baz na naszym serwerze
**   dlatego można stworzyć specjalną bazę lub użyć DB_STAT - jak ja
** Narzędzia mają służyć do (wszystko procedurami SQL zapamiętanymi na uprzednio wspomnianej bazie):
** WA) Zapamiętywania stanu bazy
** - liczby rekordów
** - indeksow w tabeli
** - kluczy obcych
** WB) Ma być możliwość skasowania wszystkich kluczy obcych za pomocą procedury
**   W zadanie bazie !!!
**   Taka procedure ma najpierw zapamietac w tabeli jakie są klucze
**   a potem je skasowac
** WC) Ma być możliwość odtworzenia kluczy obcych procedurą na wybranej bazie
**  podajemy według jakiego stanu (ID stanu) jak NULL to 
**  - procedura szuka ostatniego stanu dla tej bazy i odtwarza ten stan
** Sprawozdanie umieszczmy w iSOD do 25.10.2020 do godziny 20.00 w kolumnie Z1
** Sprawozdanie w PDF lub pliku Z1_num_indeksu_imie_nazw(bez PL znakow).sql:
** Opis wymagan
** Opis sposobu realizacji
** Kod SQL z komentarzami
** Dowód ze dziala (np zapamietany stan liczby wierszy w bazie, skasowane klucze obce,odtworzone według stanu X)
*/

/*
CREATE DATABASE DB_STAT - baza danych z tabelami dotyczącymi stanów baz danych
*/
IF NOT EXISTS (SELECT d.name 
					FROM sys.databases d 
					WHERE	(d.database_id > 4) -- systemowe mają ID poniżej 5
					AND		(d.[name] = N'DB_STAT')
)
BEGIN
	CREATE DATABASE DB_STAT
END
GO

USE DB_STAT
GO
/* tabela główna zawierająca informacje o sprawdzeniu stanu bazy danych:
zawiera id wykonanej procedury, nazwę bazy danych, 
komentarz, datę wykonania, nazwę użytkownika, nazwę hosta
*/
IF NOT EXISTS 
(	SELECT 1
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_STAT')
		AND		(OBJECTPROPERTY(o.[ID],N'IsUserTable')=1)
)
BEGIN
	/* czyszczenie jak trzeba od nowa
		DROP TABLE DB_RCOUNT
		DROP TABLE DB_STAT
	*/
	/*
	Szukanie ostatniego stat_id dla ostatniego zrzutu kluczy
	SELECT MAX(o.stat_id)
		FROM DB_STAT o
		WHERE o.[db_nam] = @jaka_baza
		AND EXISTS ( SELECT 1 FROM db_fk f WHERE f.stat_id = o.stat_id)
	*/
	CREATE TABLE dbo.DB_STAT
	(	stat_id		int				NOT NULL IDENTITY /* samonumerująca kolumna */
			CONSTRAINT PK_DB_STAT PRIMARY KEY
	,	[db_nam]	nvarchar(20)	NOT NULL
	,	[comment]	nvarchar(20)	NOT NULL
	,	[when]		datetime		NOT NULL DEFAULT GETDATE()
	,	[usr_nam]	nvarchar(100)	NOT NULL DEFAULT USER_NAME()
	,	[host]		nvarchar(100)	NOT NULL DEFAULT HOST_NAME()
	)
END
GO

USE DB_STAT
GO
/*
Tabela z liczbą rekordów w tabelach
*/
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_RCOUNT')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)
BEGIN
	CREATE TABLE dbo.DB_RCOUNT
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_STAT__RCOUNT FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	[table]		nvarchar(100)	NOT NULL
	,	[RCOUNT]	int				NOT NULL DEFAULT 0
	,	[RDT]		datetime		NOT NULL DEFAULT GETDATE()
	)
END
GO




/*
Tabela do przechowywanie kluczy obcych
stat_id - id wykonanej procedury zapamiętania stanu bazy 
constraint_name - nazwa klucza
referencing_table_name - nazwa tabeli, w której występuje dany klucz
referencing_column_name - nazwa kolumny z ww. tabeli z kluczem obcym
referenced_table_name - nazwa tabeli, z której pochodzi klucz obcy
referenced_column_name - nazwa kolumny z ww. tabeli, która jest kluczem obcym
*/
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_FKEYS')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)

BEGIN
	USE DB_STAT
	CREATE TABLE dbo.DB_FKEYS
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_STAT__FKEYS FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	constraint_name					nvarchar(100)	NOT NULL
	,	[referencing_table_name]		nvarchar(100)	NOT NULL
	,	[referencing_column_name]		nvarchar(100)	NOT NULL
	,	[referenced_table_name]			nvarchar(100)	NOT NULL
	,   [referenced_column_name]		nvarchar(100)	NOT NULL
	)
END
GO
USE DB_STAT
GO

/* indeksy 
stat_id - id wykonanej procedury zapamiętania stanu bazy 
db_name - nazwa bazy danych
schema_name !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
table_name - nazwa tabeli
index_name - nazwa inkesu 
index_type - typ indeksu
*/
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_INDEXES')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)

BEGIN
	USE DB_STAT
	CREATE TABLE dbo.DB_INDEXES
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_STAT__INDEXES FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	 db_name			NVARCHAR(100)	NOT NULL
	,    schema_name        NVARCHAR(100)	NOT NULL
    ,    table_name			NVARCHAR(100)	NOT NULL
    ,    index_name			NVARCHAR(100)	NOT NULL
    ,    index_type			NVARCHAR(100)	NOT NULL
	)

END

GO

USE DB_STAT
GO

/* procedura do zapamiętywania stanu bazy danych */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_TC_STORE')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_STORE AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_TC_STORE (@db nvarchar(100), @commt nvarchar(20) = '<unkn>')
AS
	DECLARE @sql nvarchar(1000), @id int, @tab nvarchar(256), @cID nvarchar(20)
	
	SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy

	/* wstawiamy rekord do tabeli DB_STAT i zapamiętujemy ID jakie nadano nowemu wierszowi */
	INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam) VALUES (@commt, @db)
	SET  @id = SCOPE_IDENTITY()
	/* tekstowo ID aby ciągle nie konwetować w pętli */
	SET @cID = RTRIM(LTRIM(STR(@id,20,0)))

	CREATE TABLE #TC ([table] nvarchar(100) )

	/* w procedurze sp_sqlExec USE jakas_baza tymczasowo przechodzi w ramach polecenia TYLO */
	SET @sql = N'USE [' + @db + N']; INSERT INTO #TC ([table]) '
			+ N' SELECT o.[name] FROM sysobjects o '
			+ N' WHERE (OBJECTPROPERTY(o.[ID], N''isUserTable'') = 1)'
	/* for debug reason not execute but select */
	-- SELECT @sql 
	EXEC sp_sqlexec @sql

	-- SELECT * FROM #TC

	/* kursor po wszystkich tabelach uzytkownika */
	DECLARE CC INSENSITIVE CURSOR FOR 
			SELECT o.[table]
				FROM #TC o
				ORDER BY 1

	OPEN CC
	FETCH NEXT FROM CC INTO @tab

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @sql = N'USE [' + @db + N']; '
					+ N' INSERT INTO DB_STAT.dbo.DB_RCOUNT (stat_id,[table],rcount) SELECT '
					+ @cID 
					+ ',''' + RTRIM(@tab) + N''', COUNT(*) FROM [' +@db + ']..' + RTRIM(@tab)
		EXEC sp_sqlexec @sql
		--SELECT @sql as syntax
		/* przechodzimy do następnej tabeli */
		FETCH NEXT FROM CC INTO @tab
	END
	CLOSE CC
	DEALLOCATE CC

	SET @sql = N'USE [' + @db + N']; '
                    + N' INSERT INTO DB_STAT.dbo.DB_FKEYS  SELECT '
                    + @cID 
                    + '    ,    f.name constraint_name
                        ,    OBJECT_NAME(f.parent_object_id)
                        ,    COL_NAME(fc.parent_object_id, fc.parent_column_id)
                        ,    OBJECT_NAME (f.referenced_object_id)
                        ,    COL_NAME(fc.referenced_object_id, fc.referenced_column_id)
                        FROM sys.foreign_keys AS f
                        JOIN  sys.foreign_key_columns AS fc
                        ON f.[object_id] = fc.constraint_object_id
                        ORDER BY f.name' 

	EXEC sp_sqlexec @sql

	SET @sql = N'USE [' + @db + N']; '
                    + N' INSERT INTO DB_STAT.dbo.DB_INDEXES SELECT  '
                    + @cID 
                    + ' , DB_NAME() AS Database_Name
						, sc.name AS Schema_Name
						, o.name AS Table_Name
						, i.name AS Index_Name
						, i.type_desc AS Index_Type
						FROM sys.indexes i
						INNER JOIN  sys.objects o ON i.object_id = o.object_id
						INNER JOIN  sys.schemas sc ON o.schema_id = sc.schema_id
						WHERE i.name IS NOT NULL
						AND o.type = ''U''
						ORDER BY o.name, i.type'
	EXEC sp_sqlexec @sql

GO

/* test procedury */
EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'sprawdzenie', @db = N'pwx_db'
EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'test', @db = N'pwx_db'

SELECT * FROM DB_STAT 
/*stat_id     db_nam               comment              when                    usr_nam                                                                                              host
----------- -------------------- -------------------- ----------------------- ---------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------
1           pwx_db               test                 2020-10-15 11:18:22.167 dbo                                                                                                  MS-SOFT-TOSH
2           pwx_db               test                 2020-10-15 11:50:32.983 dbo                                                                                                  MS-SOFT-TOSH
3           pwx_db               test                 2020-10-15 14:44:28.880 dbo                                                                                                  MS-SOFT-TOSH

(3 row(s) affected)*/

SELECT * FROM DB_STAT.dbo.DB_RCOUNT WHERE stat_id=40
SELECT * FROM DB_STAT.dbo.DB_FKEYS WHERE stat_id=40
SELECT * FROM DB_STAT.dbo.DB_INDEXES WHERE stat_id=40
/*stat_id     table                                                                                                RCOUNT      RDT
----------- ---------------------------------------------------------------------------------------------------- ----------- -----------------------
3           A4                                                                                                   2           2020-10-15 14:44:28.910
3           AUTA                                                                                                 0           2020-10-15 14:44:28.913
3           CECHY                                                                                                2           2020-10-15 14:44:28.917
3           etaty                                                                                                19          2020-10-15 14:44:28.917
3           firmy                                                                                                4           2020-10-15 14:44:28.920
3           FIRMY_CECHY                                                                                          6           2020-10-15 14:44:28.920
3           miasta                                                                                               4           2020-10-15 14:44:28.920
3           NUM_MIES                                                                                             0           2020-10-15 14:44:28.923
3           osoby                                                                                                5           2020-10-15 14:44:28.927
3           osoby_backup                                                                                         5           2020-10-15 14:44:28.927
3           sysdiagrams                                                                                          1           2020-10-15 14:44:28.930
3           T_FA                                                                                                 3           2020-10-15 14:44:28.930
3           T_TOWAR                                                                                              2           2020-10-15 14:44:28.930
3           T_VAT                                                                                                2           2020-10-15 14:44:28.933
3           trace                                                                                                10          2020-10-15 14:44:28.937
3           TWY                                                                                                  1           2020-10-15 14:44:28.937
3           WARTOSCI_CECH                                                                                        5           2020-10-15 14:44:28.940
3           woj                                                                                                  3           2020-10-15 14:44:28.943
3           WYP_AUTA                                                                                             0           2020-10-15 14:44:28.947
3           WYPAS                                                                                                0           2020-10-15 14:44:28.947
3           ZM_NX                                                                                                2           2020-10-15 14:44:28.950
3           ZM_NX_DET                                                                                            10          2020-10-15 14:44:28.957

(22 row(s) affected)*/


/* mozna zrobić kursor po bazach i w petli wołąc procedurę i mieć zrzut dla wszystkich baz */
SELECT d.name FROM sys.databases d WHERE d.database_id > 4 -- ponizej 5 są systemowe

/* Można stworzyć procedurę do przechowywania liczby wierszy w KAZDEJ !!! bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_STORE_ALL')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_STORE_ALL AS '
	EXEC sp_sqlexec @stmt
END
GO


USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_STORE_ALL (@commt nvarchar(20) = N'<all>')
AS
	DECLARE CCA INSENSITIVE CURSOR FOR
			SELECT d.name 
			FROM sys.databases d 
			WHERE d.database_id > 4 -- ponizej 5 są systemowe
	DECLARE @db nvarchar(100)
	OPEN CCA
	FETCH NEXT FROM CCA INTO @db

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'test', @db = @db
		FETCH NEXT FROM CCA INTO @db
	END
	CLOSE CCA
	DEALLOCATE CCA
GO

USE DB_STAT
GO

/* procedura do usuwanie kluczy */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_REMOVE_FKEYS')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_REMOVE_FKEYS AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_REMOVE_FKEYS @db NVARCHAR(100)
as
	DECLARE @sql nvarchar(1000), @id int, @tab nvarchar(256), @cID nvarchar(20)
	
	SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy

	/* wstawiamy rekord do tabeli DB_STAT i zapamiętujemy ID jakie nadano nowemu wierszowi */
	INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam) VALUES ('Usuwanie kluczy', @db)
	SET  @id = SCOPE_IDENTITY()
	/* tekstowo ID aby ciągle nie konwetować w pętli */
	SET @cID = RTRIM(LTRIM(STR(@id,20,0)))

	SET @sql = N'USE [' + @db + N']; '
                    + N' INSERT INTO DB_STAT.dbo.DB_FKEYS  SELECT '
                    + @cID 
                    + '    ,    f.name constraint_name
                        ,    OBJECT_NAME(f.parent_object_id)
                        ,    COL_NAME(fc.parent_object_id, fc.parent_column_id)
                        ,    OBJECT_NAME (f.referenced_object_id)
                        ,    COL_NAME(fc.referenced_object_id, fc.referenced_column_id)
                        FROM sys.foreign_keys AS f
                        JOIN  sys.foreign_key_columns AS fc
                        ON f.[object_id] = fc.constraint_object_id
                        ORDER BY f.name' 

	EXEC sp_sqlexec @sql
    DECLARE @udb nvarchar(3000)
	/* w procedurze tworzymy tymczasową tabelę z aktualnymi kluczami, 
	identycznymi jak zapisane wyżej, co jednak jest wygodniejsze w dalszej części pro
	*/
    set @udb = 'use ' + @db +'
	
	    CREATE TABLE #TMP_FK(
        referenced_table_name NVARCHAR(100),
        referencing_table_name NVARCHAR(100),
        col_name NVARCHAR(100),
        constraint_name  NVARCHAR(100),
        db NVARCHAR(100),
    )

    INSERT INTO #TMP_FK select schema_name(fk_tab.schema_id) + ''.'' + 
		fk_tab.name as referenced_table_name,
        schema_name(pk_tab.schema_id) + ''.'' + pk_tab.name as primary_table,
        substring(column_names, 1, len(column_names)-1) as [col_name],
        fk.name as constraint_name, '+ ''''+@db+''''+' 
    from sys.foreign_keys fk
        INNER JOIN  sys.tables fk_tab ON fk_tab.object_id = fk.parent_object_id
        INNER JOIN  sys.tables pk_tab ON pk_tab.object_id = fk.referenced_object_id
        cross apply (select col.[name] + '', ''
                        from sys.foreign_key_columns fk_c
                            INNER JOIN  sys.columns col
                                ON fk_c.parent_object_id = col.object_id
                                and fk_c.parent_column_id = col.column_id
                        where fk_c.parent_object_id = fk_tab.object_id
                        and fk_c.constraint_object_id = fk.object_id
                                order by col.column_id
                                for xml path ('''') ) D (column_names)
    order by schema_name(fk_tab.schema_id) + ''.'' + fk_tab.name,
        schema_name(pk_tab.schema_id) + ''.'' + pk_tab.name
        
     
    DECLARE @name nvarchar(100)
    DECLARE @constraint nvarchar(100)

    DECLARE CCA INSENSITIVE CURSOR FOR
	SELECT referenced_table_name, constraint_name from #TMP_FK
	DECLARE @db nvarchar(100)
	OPEN CCA
	FETCH NEXT FROM CCA INTO @name, @constraint

	WHILE @@FETCH_STATUS = 0
	BEGIN
        DECLARE @sqlcmd VARCHAR(MAX)
        SET @sqlcmd = ''ALTER TABLE '' + PARSENAME(@name,1) + '' DROP CONSTRAINT '' +  PARSENAME(@constraint,1)
        select @sqlcmd
        EXEC (@sqlcmd)
		FETCH NEXT FROM CCA INTO @name, @constraint
	END
	CLOSE CCA
	DEALLOCATE CCA
        '
        
    execute sp_executesql @udb
go

EXEC DB_STAT.dbo.DB_REMOVE_FKEYS  @db = N'pwx_db'

EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'po_odnowieniu', @db = N'pwx_db'
SELECT * FROM DB_STAT.dbo.DB_FKEYS
SELECT * FROM DB_STAT.dbo.DB_STAT


/* 
use pwx_test_db
-- usuwanie klucza
ALTER TABLE etaty DROP CONSTRAINT fk_etaty_osoby

-- dodawanie kluczy do tabeli
USE baza;
ALTER TABLE dbo.nazwa_tabeli ADD CONSTRAINT nazwa_klucza FOREIGN KEY (kolumna) REFERENCES MasterTabela(kolumna_w_master)

*/
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_RESTORE_KEYS')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_RESTORE_KEYS AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO
/*
procedura przywraca klucze obce w bazie danych ze stanu o id podanym jako argument
gdy ten argument jest nullem przywraca ostatnio zapisane
*/
ALTER PROCEDURE dbo.DB_RESTORE_KEYS @db nvarchar(100), @id int
AS
    create table #tmp_fk(
        stat_id							int		
	,	constraint_name					nvarchar(100)	
	,	[referencing_table_name]		nvarchar(100)	
	,	[referencing_column_name]		nvarchar(100)	
	,	[referenced_table_name]			nvarchar(100)	
	,   [referenced_column_name]		nvarchar(100)	
    )

    if @id is NULL
    BEGIN
        SELECT @id =  MAX(dbo.DB_FKEYS.stat_id) FROM dbo.DB_FKEYS
		JOIN dbo.DB_STAT ON ( dbo.DB_STAT.stat_id = dbo.DB_FKEYS.stat_id )
		WHERE dbo.DB_STAT.db_nam = @db
    END

	DECLARE @tt NVARCHAR(4000)
    DECLARE @key NVARCHAR(100)
    DECLARE @key2 NVARCHAR(100)
	DECLARE @tb_1 NVARCHAR(100)
    DECLARE @tb_2 NVARCHAR(100)

    INSERT INTO #tmp_fk SELECT * FROM  dbo.DB_FKEYS where stat_id = @id
	DECLARE CC INSENSITIVE CURSOR FOR 
			SELECT referencing_table_name, referenced_table_name, referenced_column_name, referencing_column_name FROM #tmp_fk

	OPEN CC
	FETCH NEXT FROM CC INTO @tb_2,@tb_1,@key2,@key
    

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
        SELECT @tb_1,@tb_2,@key
        SET @tt = 'use ' + @db +' 
        ALTER TABLE '+@tb_2+' 
        ADD FOREIGN KEY ('+@key+') REFERENCES '+@tb_1+'('+@key2+')'
        execute sp_executesql @tt
		FETCH NEXT FROM CC INTO @tb_2,@tb_1,@key2, @key
	END
	CLOSE CC
	DEALLOCATE CC
    

EXEC DB_RESTORE_KEYS @db =  N'pwx_db', @id = 23

EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'po_odnowieniu', @db = N'pwx_db'

SELECT * FROM DB_FKEYS

