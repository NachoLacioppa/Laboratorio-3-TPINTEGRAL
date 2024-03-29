--TP INTEGRADOR LABORATORIO III 2019 2C
--IGNACIO LACIOPPA, LEGAJO 19992, DNI 38788859

--ej 1 ok
--ej 2 ok
--ej 3 ok
--ej 4 ok
--ej 5 ok
--EJ 6 ok
--EJ 7 FALTA!!!

use banco

--1 - Elaborar una vista que permita conocer para cada cliente: el apellido y nombres, los n�meros de
--cuenta, el saldo de la cuenta, la cantidad de movimientos realizados por cada cuenta y el saldo
--acumulado entre todas las cuentas de cada cliente.

create view Vista_ej1 as(
select cli.APELLIDO, cli.NOMBRE, cue.IDCUENTA, cue.SALDO,
(select count(*) from MOVIMIENTOS  where IDCUENTA=cue.IDCUENTA) as 'Cant Mov',
(select sum(saldo) from CUENTAS where IDCLIENTE= cli.IDCLIENTE) as 'Saldo Total'
from clientes as cli
inner join CUENTAS as cue on cli.IDCLIENTE=cue.IDCLIENTE
)

select*from Vista_ej1

--2 - Elaborar un procedimiento almacenado que permita crear una cuenta. El procedimiento debe recibir:
--@IDCliente, @Tipo y @Limite. Debe permitir cumplir la siguiente condici�n:
--Los tipos de cuenta pueden ser: CA - Caja de ahorro y CC - Cuenta corriente. De lo contrario, impedir el ingreso.
--- Si el tipo es Caja de Ahorro entonces el l�mite de la cuenta debe ser obligatoriamente cero.
--- Si el tipo es Cuenta corriente entonces el l�mite puede ser cualquier n�mero mayor o igual que
--cero. Tener en cuenta que en el l�mite siempre se almacena con un valor negativo.
--- El saldo siempre ser� cero y el estado siempre ser� uno.
--Ejemplo:
--EXEC SP_NuevaCuenta 1, 'CC', 5000
--Deber� registrar lo siguiente:
--INSERT INTO Cuentas (IDCliente, Tipo, Limite, Saldo, Estado) VALUES (1, 'CC', -5000, 0, 1)
--En cambio:
--EXEC SP_NuevaCuenta 1, 'CA', 5000
--Deber� registrar lo siguiente:
--INSERT INTO Cuentas (IDCliente, Tipo, Limite, Saldo, Estado) VALUES (1, 'CA', 0, 0, 1)

SELECT * FROM CUENTAS

CREATE PROCEDURE PR_AGREGARCUENTA @IDCLIENTE BIGINT , @TIPO VARCHAR(2) , @LIMITE MONEY
AS
IF( @TIPO = 'cc' OR @TIPO = 'CC' )
BEGIN
IF @LIMITE <= 0 
BEGIN
INSERT INTO CUENTAS VALUES( @idCliente, @tipo, @limite, 0 ,1)
END
ELSE BEGIN
RAISERROR ('limite incorrecto',16, 1)
END
END
ELSE IF( @TIPO = 'ca' or @TIPO = 'CA')

BEGIN
  insert into CUENTAS VALUES (@IDCLIENTE,@TIPO,0,0,1)
END

EXEC PR_AGREGARCUENTA 3,CA,0

--3 - Realizar un trigger que al registrar una nueva cuenta le sea otorgada una tarjeta de d�bito. La misma
--se identifica con un valor 'D' en el Tipo de la tarjeta.

CREATE TRIGGER TG_ASIGNAR_DEBITO ON CUENTAS
AFTER INSERT
AS
declare @idCuenta   bigint
select @idCuenta=IDCUENTA FROM inserted
INSERT INTO TARJETAS VALUES ( @idCuenta,'D',1)


INSERT INTO CUENTAS VALUES (4, 'CC',0 , 0 ,1) 

SELECT * FROM CUENTAS
SELECT * FROM TARJETAS


--4 - Realizar un trigger que al registrar un nuevo usuario le sea otorgada una Caja de Ahorro nueva.
create trigger TG_ASIGNAR_CUENTA on CLIENTES
AFTER INSERT
AS
declare @idCliente bigint
select @idCliente= IDCLIENTE from inserted
INSERT INTO CUENTAS VALUES (@idCliente,'CA',0,0,1)

insert into CLIENTES values (5,'LACIOPPA','NACHO',1)
select * from clientes
select * from CUENTAS

--5 - Realizar un trigger que al eliminar un usuario realice la baja l�gica del mismo. Si se elimina un usuario
--que ya se encuentra dado de baja l�gica y dicho usuario no registra ni cuentas ni tarjetas, proceder a la
--baja f�sica del usuario.

CREATE TRIGGER TR_ELIMINAR_CLIENTE ON CLIENTES
INSTEAD OF DELETE
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
	DECLARE @IDCLIENTE BIGINT
	DECLARE @ESTADO BIT
	DECLARE @CANTIDAD_TARJETAS INT
	DECLARE @CANTIDAD_CUENTAS INT

	SELECT @IDCLIENTE = IDCLIENTE, @ESTADO = ESTADO FROM DELETED
	SELECT @CANTIDAD_CUENTAS = COUNT(*) FROM CUENTAS WHERE IDCLIENTE = @IDCLIENTE

	SELECT @CANTIDAD_TARJETAS = COUNT(*) FROM TARJETAS AS T
	INNER JOIN CUENTAS AS C ON C.IDCUENTA = T.IDCUENTA
	INNER JOIN CLIENTES AS CL ON CL.IDCLIENTE = C.IDCLIENTE
	WHERE C.IDCLIENTE = @IDCLIENTE
	
	IF @ESTADO = 1
	BEGIN
		UPDATE CLIENTES SET ESTADO = 0 WHERE IDCLIENTE = @IDCLIENTE
	END

	ELSE IF @ESTADO = 0  AND @CANTIDAD_TARJETAS = 0 AND @CANTIDAD_CUENTAS = 0
	BEGIN
		DELETE FROM CLIENTES WHERE IDCLIENTE = @IDCLIENTE
	END
	COMMIT TRANSACTION

	END TRY

	BEGIN CATCH
		RAISERROR('cliente dado de baja y con cuentas/tarjetas activas',16,1)
		ROLLBACK TRANSACTION
	END CATCH

END

SELECT * FROM CLIENTES
--6 - Realizar un trigger que al registrar un nuevo movimiento, actualice el saldo de la cuenta. Deber�
--acreditar o debitar dinero en la cuenta dependiendo del tipo de movimiento ('D' - D�bito y 'C' - Cr�dito). Se
--deber�:
--- Registrar el movimiento
--- Actualizar el saldo de la cuenta
CREATE TRIGGER TG_ACTUALIZAR_SALDO on MOVIMIENTOS
AFTER INSERT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @tipoMov varchar, @importe float, @idCuenta bigint
			select @tipoMov= tipo,@importe=importe,@idCuenta=IDCUENTA from inserted
			IF(@tipoMov='C')
			BEGIN
				UPDATE CUENTAS set SALDO = SALDO+@importe where IDCUENTA=@idCuenta
			END
			IF(@tipoMov='D')
			BEGIN
				UPDATE CUENTAS set SALDO = SALDO-@importe where IDCUENTA=@idCuenta
			END
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
END

--7 - Realizar un trigger que al registrar una nueva transferencia, registre los movimientos y actualice los
--saldos de las cuenta. Deber� verificar que las cuentas de origen y destino sean distintas. Se deber�:
--- Registrar la transferencia
--- Registrar el movimiento de la cuenta de origen
--- Registrar el movimiento de la cuenta de destino
--NOTA: La acci�n deber�a generar una reacci�n en cadena si se realiz� correctamente el Trigger de (6).




	
	


