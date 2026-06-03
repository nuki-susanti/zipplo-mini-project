-- create operational database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ZipploDB')
BEGIN
    CREATE DATABASE ZipploDB;
    PRINT 'Database ZipploDB created successfully.';
END
ELSE
BEGIN
    PRINT 'Database ZipploDB already exists.';
END

-- create data warehouse database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ZipploDW')
BEGIN
    CREATE DATABASE ZipploDW;
    PRINT 'Database ZipploDW created successfully.';
END
ELSE
BEGIN
    PRINT 'Database ZipploDW already exists.';
END