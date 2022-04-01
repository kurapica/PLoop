--===========================================================================--
--                                                                           --
--                      System.Net.Protocol.Modbus-TCP                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/16                                               --
-- Update Date  :   2021/08/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.Modbus"

    import "System.Net"

    export                              {
        strchar                         = string.char,
        strbyte                         = string.byte,
        strsub                          = string.sub,
        band                            = Toolset.band,
        lshift                          = Toolset.lshift,
        rshift                          = Toolset.rshift,
        tconcat                         = table.concat,
        isObjectType                    = Class.IsObjectType,
        type                            = type,
        throw                           = throw,
    }

    -- Encoding as big-Endian
    local function encodeByte(code, length)
        if length == 4 then
            return strchar( band(rshift(code, 24), 255), band(rshift(code, 16), 255), band(rshift(code, 8), 255), band(code, 255) )
        elseif length == 3 then
            return strchar( band(rshift(code, 16), 255), band(rshift(code, 8), 255), band(code, 255) )
        elseif length == 2 then
            return strchar( band(rshift(code, 8), 255), band(code, 255) )
        else
            return strchar(band(code, 255))
        end
    end

    ---------------------------------------------------
    --                The Modbus Type                --
    ---------------------------------------------------
    --- The Modbus Exception
    __Sealed__()
    class "ModbusException"             { Exception }

    --- The Modbus-TCP Function Code
    __Sealed__()
    enum "PublicFunctionCode"           {
        READ_COILS                      = 1,
        READ_DISCRETE_INPUTS            = 2,
        READ_HOLDING_REGISTERS          = 3,
        READ_INPUT_REGISTERS            = 4,
        WRITE_SINGLE_COIL               = 5,
        WRITE_SINGLE_REGISTER           = 6,
        READ_EXCEPTION_STATUS           = 7, -- Serial Line only, not supported
        DIAGNOSTICS                     = 8, -- Serial Line only, not supported
        GET_COMM_EVENT_COUNTER          =11, -- Serial Line only, not supported
        GET_COMM_EVENT_LOG              =12, -- Serial Line only, not supported
        WRITE_MULTIPLE_COILS            =15,
        WRITE_MULTIPLE_REGISTERS        =16,
        REPORT_SLAVE_ID                 =17, -- Serial Line only, not supported
        READ_FILE_RECORD                =20,
        WRITE_FILE_RECORD               =21,
        MASK_WRITE_REGISTER             =22,
        READ_WRITE_MULTIPLE_REGISTERS   = 23,
        READ_FIFO_QUEUE                 =24,
        ENCAPSULATED_INTERFACE_TRANSPORT=43,
    }

    --- The Exception Code
    __Sealed__()
    enum "ExceptionCode"                {
        ILLEGAL_FUNCTION                = 0x1,
        ILLEGAL_DATA_ADDRESS            = 0x2,
        ILLEGAL_DATA_VALUE              = 0x3,
        SLAVE_DEVICE_FAILURE            = 0x4,
        ACKNOWLEDGE                     = 0x5,
        SLAVE_DEVICE_BUSY               = 0x6,
        MEMORY_PARITY_ERROR             = 0x8,
        GATEWAY_PATH_UNAVAILABLE        = 0xA,
        GATEWAY_TARGET_DEVICE_FAILED_TO_RESPOND = 0xB,
    }

    --- The ON/OFF State
    __Sealed__()
    enum "OnOffState"                   {
        ON                              = 0xFF00,
        OFF                             = 0x0000,
    }

    --- The quantity limit
    __Sealed__()
    struct "Quantity"                   { __base = NaturalNumber, function(val, onlyvalid) return (val < 1 or val > 0x7D0) and (onlyvalid or "The %s must between 1 and 0x7D0") end }

    --- The quantity limit
    __Sealed__()
    struct "QuantityRegister"           { __base = NaturalNumber, function(val, onlyvalid) return (val < 1 or val > 0x007D) and (onlyvalid or "The %s must between 1 and 0x007D") end }

    --- The quantity limit
    __Sealed__()
    struct "QuantityOutput"             { __base = NaturalNumber, function(val, onlyvalid) return (val < 1 or val > 0x07B0) and (onlyvalid or "The %s must between 1 and 0x07B0") end }

    --- The file number
    __Sealed__()
    struct "FileNumber"                 { __base = UInt16, function(val, onlyvalid) return val < 1 and (onlyvalid or "The %s must between 1 and 0xFFFF") end }

    --- The Record Number
    __Sealed__()
    struct "RecordNumber"               { __base = NaturalNumber, function(val, onlyvalid) return val > 0x270F and (onlyvalid or "The %s must between 0 and 0x270F") end }

    --- PDU
    __Sealed__()
    struct "ProtocolDataUnit"           {
        { name = "funcCode",            type = UInt16, require = true },
        { name = "data",                type = String },
        { name = "exception",           type = NaturalNumber }
    }

    --- The Read File Record
    __Sealed__()
    struct "FileReadRecord"             {
        { name = "file",                type = FileNumber,   require = true },
        { name = "record",              type = RecordNumber, require = true },
        { name = "length",              type = RecordNumber, require = true },
    }

    --- The Write File Record
    __Sealed__()
    struct "FileWriteRecord"            {
        { name = "file",                type = FileNumber,   require = true },
        { name = "record",              type = RecordNumber, require = true },
        { name = "data",                type = struct { UInt16 }, require = true },
    }

    ---------------------------------------------------
    --              The Modbus Protocol              --
    ---------------------------------------------------
    --- the Modbus Protocol
    System.Net.Protocol "Modbus"        {
        make                            = function(transId, unitId, pdu)
            return tconcat              {
                -- byte 0: transaction identifier – copied by server – usually 0
                -- byte 1: transaction identifier – copied by server – usually 0
                encodeByte(transId, 2),

                -- byte 2: protocol identifier = 0
                -- byte 3: protocol identifier = 0
                encodeByte(0, 2),

                -- byte 4: length field (upper byte) = 0 (since all messages are smaller than 256)
                -- byte 5: length field (lower byte) = number of bytes following
                encodeByte(2 + (pdu.data and #pdu.data or 0), 2),

                -- byte 6: unit identifier (previously ‘slave address’)
                encodeByte(unitId, 1),

                -- byte 7: MODBUS function code
                encodeByte(pdu.funcCode, 1),

                -- byte 8 on:  data as needed
                pdu.data
            }
        end,
        parse                           = function(socket)
            if type(socket) == "string" then
                if #socket < 7 then throw(ModbusException("The packet length is not valid")) end

                -- Check MODBUS Application Protocol header
                local b1, b2, b3, b4, b5, b6, b7 = strbyte(socket, 1, 7)
                if b3 ~= 0 or b4 ~= 0 then throw(ModbusException("The Protocol Identifier is not valid")) end

                local tid               = lshift(b1, 8) + b2
                local length            = lshift(b5, 8) + b6
                local unitId            = b7

                if length + 6 ~= #socket then throw(ModbusException("The protocol data unit length not match")) end

                local funcCode          = strbyte(socket, 8)

                if funcCode >= 128 then
                    -- With Exception
                    return tid, unitId, { funcCode = funcCode, exception = strbyte(socket, 9) }
                else
                    return tid, unitId, { funcCode = funcCode, data = strsub(9, -1) }
                end
            else
                if not isObjectType(socket, ISocket) then
                    throw(ModbusException("The protocol can't read data from the given object", ReasonCode.MALFORMED_PACKET))
                end

                -- Check MODBUS Application Protocol header
                local mbap              = socket:Receive(6)
                if not mbap then return end -- timeout

                local b1, b2, b3, b4, b5, b6 = strbyte(mbap, 1, 6)
                if b3 ~= 0 or b4 ~= 0 then throw(ModbusException("The Protocol Identifier is not valid")) end

                local tid               = lshift(b1, 8) + b2
                local length            = lshift(b5, 8) + b6

                local rest              = socket:Receive(length)
                if not rest then return end -- timeout

                local unitId, funcCode  = strbyte(rest, 1, 2)

                if funcCode >= 128 then
                    -- With Exception
                    return tid, unitId, { funcCode = funcCode, exception = strbyte(rest, 3) }
                else
                    return tid, unitId, { funcCode = funcCode, data = strsub(rest, 3, -1) }
                end
            end
        end
    }

    ---------------------------------------------------
    --               The Modbus Client               --
    ---------------------------------------------------
    --- Represents the Modbus client object
    __Sealed__()
    class "Client"                      (function(_ENV)
        inherit "System.Context"
        extend "System.IAutoClose"

        export {
            System.Net.Protocol.Modbus, PublicFunctionCode, ModbusException, TimeoutException,
            ProtocolDataUnit, OnOffState, List, XList,

            throw                       = throw,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
            type                        = type,
            strbyte                     = string.byte,
            strchar                     = string.char,
            tconcat                     = table.concat,
            band                        = Toolset.band,
            rshift                      = Toolset.rshift,
            isObjectType                = Class.IsObjectType,
            Trace                       = Logger.Default[Logger.LogLevel.Trace],
        }


        -- Only use this for test or client side only
        local SocketType                = System.Net.Socket

        local function convertByte(byte, shift)
            if type(byte) == "number" then
                return lshift( byte > 0 and 1 or 0, shift )
            else
                return lshift( byte and 1 or 0, shift )
            end
        end

        local function receiveFlags(self, identifier, quantity)
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return data array                - if successs
            if dataUnit then
                if dataUnit.exception then return false, dataUnit.exception end

                local data              = dataUnit.data

                -- Byte count
                local count             = strbyte(data, 1)
                local rets              = {}
                local index             = 0

                for i = 2, count + 1 do
                    local status        = strbyte(data, i) or 0

                    for j = 0, 7 do
                        index           = index + 1
                        if index > quantity then break end

                        rets[index]     = band(rshift(status, j), 1)
                    end
                end

                while index < quantity do
                    index               = index + 1
                    rets[index]         = 0
                end

                return rets
            end
        end

        local function returnValues(self, identifier, quantity)
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return data array                - if successs
            if dataUnit then
                if dataUnit.exception then return false, dataUnit.exception end

                local data              = dataUnit.data

                -- Byte count
                local count             = strbyte(data, 1)
                local rets              = {}
                local index             = 0

                for i = 2, count + 1, 2 do
                    index               = index + 1
                    if index > quantity then break end

                    rets[index]         = lshift(strbyte(data, i), 8) + strbyte(data, i + 1)
                end

                while index < quantity do
                    index               = index + 1
                    rets[index]         = 0
                end

                return rets
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The server address to be connected
        property "Address"              { type = String, default = "127.0.0.1" }

        --- All MODBUS/TCP ADU are sent via TCP to registered port 502
        property "Port"                 { type = NaturalNumber, default = 502 }

        --- The socket object
        property "Socket"               { type = ISocket, default = SocketType and function(self) return SocketType() end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out
        property "ReceiveTimeout"       { type = Number, handler = function(self, timeout) if self.Socket then self.Socket.ReceiveTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out
        property "SendTimeout"          { type = Number, handler = function(self, timeout) if self.Socket then self.Socket.SendTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Connect call will time out
        property "ConnectTimeout"       { type = Number, handler = function(self, timeout) if self.Socket then self.Socket.ConnectTimeout = timeout end end }

        --- The current transfer identifier
        property "TransferIdentifier"   { type = NaturalNumber, default = 0 }

        --- The Unit Identifier
        property "UnitIdentifier"       { type = NaturalNumber, default = 0 }

        -----------------------------------------------------------------------
        --                           common method                           --
        -----------------------------------------------------------------------
        --- Open the message publisher on the server side client, do nothing for the client side
        function Open(self)
            -- Init the socket with timeout
            self.Socket.ConnectTimeout  = self.ConnectTimeout
            self.Socket.ReceiveTimeout  = self.ReceiveTimeout
            self.Socket.SendTimeout     = self.SendTimeout

            self.Socket:Connect(self.Address, self.Port)
        end

        --- Close the message publisher on the server side client and close the socket
        function Close(self)
            self.Socket:Close()
        end

        --- Send the transfer data unit
        __Arguments__{ ProtocolDataUnit }
        function SendDataUnit(self, dataUnit)
            local identifier            = self.TransferIdentifier + 1
            identifier                  = identifier > 0xFFF and 1 or identifier
            self.TransferIdentifier     = identifier

            -- Trace("[MODBUS][SEND][%s] %s - %s", identifier, PublicFunctionCode(dataUnit.funcCode), dataUnit.data and { strbyte(dataUnit.data, 1, -1) } or "nil")

            self.Socket:Send(Modbus.MakePacket( identifier, self.UnitIdentifier, dataUnit ))

            return identifier
        end

        --- Receive the response data
        function ReceiveDataUnit(self)
            local ok, tid, unitId, dataUnit
            if self.ReceiveTimeout and self.ReceiveTimeout > 0 then
                ok, tid, unitId, dataUnit = pcall(Modbus.ParsePacket, self.Socket)
            else
                ok, tid, unitId, dataUnit = true, Modbus.ParsePacket(self.Socket)
            end

            if ok then
                -- if tid then Trace("[MODBUS][RECEIVE][%s] %s - %s", tid, dataUnit and PublicFunctionCode(dataUnit.funcCode) or "nil", dataUnit and dataUnit.data and { strbyte(dataUnit.data, 1, -1) } or "nil") end
                return tid, unitId, dataUnit
            elseif not isObjectType(tid, TimeoutException) then
                error(tid)
            end
        end

        -----------------------------------------------------------------------
        --                           client method                           --
        -----------------------------------------------------------------------
        --- read from 1 to 2000 contiguous status of coils in a remote device
        __Arguments__{ UInt16, Quantity }
        function ReadCoils(self, startAddress, quantity)
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_COILS,
                                            encodeByte(startAddress, 2) ..  -- Starting Address 2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(quantity, 2)         -- Quantity of coils 2 Bytes 1 to 2000 (0x7D0)
                                        ))
            return receiveFlags(self, identifier, quantity)
        end

        ---  read from 1 to 2000 contiguous status of discrete inputs in a remote device
        __Arguments__{ UInt16, Quantity }
        function ReadDiscreteInputs(self, startAddress, quantity)
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_DISCRETE_INPUTS,
                                            encodeByte(startAddress, 2) ..  -- Starting Address 2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(quantity, 2)         -- Quantity of coils 2 Bytes 1 to 2000 (0x7D0)
                                        ))
            return receiveFlags(self, identifier, quantity)
        end

        --- read the contents of a contiguous block of holding registers in a remote device
        __Arguments__{ UInt16, QuantityRegister }
        function ReadHoldingRegisters(self, startAddress, quantity)
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_HOLDING_REGISTERS,
                                            encodeByte(startAddress, 2) ..  -- Starting Address 2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(quantity, 2)         -- Quantity of coils 2 Bytes 1 to 125 (0x7D)
                                        ))
            return returnValues(self, identifier, quantity)
        end

        --- read from 1 to 125 contiguous input registers in a remote device
        __Arguments__{ UInt16, QuantityRegister }
        function ReadInputRegisters(self, startAddress, quantity)
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_INPUT_REGISTERS,
                                            encodeByte(startAddress, 2) ..  -- Starting Address 2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(quantity, 2)         -- Quantity of coils 2 Bytes 1 to 125 (0x7D)
                                        ))
            return returnValues(self, identifier, quantity)
        end

        --- write a single output to either ON or OFF in a remote device
        __Arguments__{ UInt16, OnOffState + Boolean }
        function WriteSingleCoil(self, outAddress, state)
            if type(state) == "boolean" then state = state and OnOffState.ON or OnOffState.OFF end

            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.WRITE_SINGLE_COIL,
                                            encodeByte(outAddress, 2) ..    -- Output Address  2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(state, 2)            -- Output Value    2 Bytes 0x0000 or 0xFF00
                                        ))

            -- Response:
            --      Output Address  2 Bytes 0x0000 to 0xFFFF
            --      Output Value    2 Bytes 0x0000 or 0xFF00
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return OnOffState                - if successs
            if dataUnit then
                if dataUnit.exception or #dataUnit.data < 4 then return false, dataUnit.exception end

                local b1, b2, b3, b4    = strbyte(dataUnit.data, 1, 4)
                return lshift(b1, 8) + b2 == outAddress and lshift(b3, 8) + b4
            end
        end

        --- write a single holding register in a remote device
        __Arguments__{ UInt16, UInt16 }
        function WriteSingleRegister(self, regAddress, regValue)
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.WRITE_SINGLE_REGISTER,
                                            encodeByte(regAddress, 2) ..    -- Register Address 2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(regValue, 2)         -- Register Value   2 Bytes 0x0000 to 0xFFFF
                                        ))

            -- Response:
            --      Register Address 2 Bytes 0x0000 to 0xFFFF
            --      Register Value   2 Bytes 0x0000 to 0xFFFF
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return value
            if dataUnit then
                if dataUnit.exception or #dataUnit.data < 4 then return false, dataUnit.exception end

                local b1, b2, b3, b4    = strbyte(dataUnit.data, 1, 4)
                return lshift(b1, 8) + b2 == regAddress and lshift(b3, 8) + b4
            end
        end

        --- force each coil in a sequence of coils to either ON or OFF in a remote device
        __Arguments__{ UInt16, (Byte + Boolean) * 1 }
        function WriteMultipleCoils(self, startAddress, ...)
            local bytes                 = {}
            local quantity              = select("#", ...)
            local count                 = 0

            if quantity > 0x07B0 then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

            for i = 1, quantity, 8 do
                local b1, b2, b3, b4, b5, b6, b7, b8 = select(i, ...)
                count                   = count + 1
                bytes[count]            = convertByte(b1, 0) + convertByte(b2, 1) + convertByte(b3, 2) + convertByte(b4, 3) + convertByte(b5, 4) + convertByte(b6, 5) + convertByte(b7, 6) + convertByte(b8, 7)
            end

            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.WRITE_MULTIPLE_COILS,
                                            encodeByte(startAddress, 2) ..  -- Starting Address    2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(quantity, 2) ..      -- Quantity of Outputs 2 Bytes 0x0001 to 0x07B0
                                            encodeByte(count, 1) ..         -- Byte Count          1 Byte N*
                                            strchar(unpack(bytes))          -- Outputs Value       N* x 1 Byte
                                        ))

            -- Response:
            --      Starting Address    2 Bytes 0x0000 to 0xFFFF
            --      Quantity of Outputs 2 Bytes 0x0001 to 0x07B0
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return quantity
            if dataUnit then
                if dataUnit.exception or #dataUnit.data < 4 then return false, dataUnit.exception end

                local b1, b2, b3, b4    = strbyte(dataUnit.data, 1, 4)
                return lshift(b1, 8) + b2 == startAddress and lshift(b3, 8) + b4
            end
        end

        --- write a block of contiguous registers (1 to 123 registers) in a remote device
        __Arguments__{ UInt16, UInt16 * 1 }
        function WriteMultipleRegisters(self, startAddress, ...)
            local bytes                 = {}
            local quantity              = select("#", ...)
            local count                 = 0

            if quantity > 0x007B then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.WRITE_MULTIPLE_REGISTERS,
                                            encodeByte(startAddress, 2) ..  -- Starting Address        2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(quantity, 2) ..      -- Quantity of Registers   2 Bytes 0x0001 to 0x007B
                                            encodeByte(quantity * 2, 1) ..  -- Byte Count              1 Byte 2 x N*
                                            List{ ... }:Map(function(val)   -- Registers Value         N* x 2 Bytes value
                                                return encodeByte(val, 2)
                                            end):Join()
                                        ))

            -- Response:
            --      Starting Address    2 Bytes 0x0000 to 0xFFFF
            --      Quantity of Outputs 2 Bytes 0x0001 to 0x07B0
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return quantity
            if dataUnit then
                if dataUnit.exception or #dataUnit.data < 4 then return false, dataUnit.exception end

                local b1, b2, b3, b4    = strbyte(dataUnit.data, 1, 4)
                return lshift(b1, 8) + b2 == startAddress and lshift(b3, 8) + b4
            end
        end

        --- perform a file record read
        __Arguments__{ FileReadRecord * 1 }
        function ReadFileRecord(self, ...)
            local count                 = select("#", ...) * 7
            if count > 0xF5 then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_FILE_RECORD,
                                            encodeByte(count, 2) ..             -- Byte Count 1 Byte 0x07 to 0xF5 bytes
                                            List{ ... }:Map(function(req)
                                                return encodeByte(6, 1) ..      -- Sub-Req. x, Reference Type   1 Byte
                                                    encodeByte(req.file, 2) ..  -- Sub-Req. x, File Number      2 Bytes
                                                    encodeByte(req.record, 2) ..-- Sub-Req. x, Record Number    2 Bytes
                                                    encodeByte(req.length, 2)   -- Sub-Req. x, Record Length    2 Bytes
                                            end):Join()
                                        ))

            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return record array
            if dataUnit then
                if dataUnit.exception then return false, dataUnit.exception end

                local data              = dataUnit.data
                local length            = strbyte(data, 1) -- Resp. data Length
                if length + 1 ~= #data then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

                local index             = 2
                local rets              = {}
                local rindex            = 0

                while index <= length do
                    local rlen          = strbyte(data, index)  -- Sub-Req. x, File Resp. length
                    if rlen % 2 == 0 then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

                    rlen                = index + rlen
                    index               = index + 2             -- Skip Reference Type

                    local subret        = {}
                    local sindex        = 0

                    while index < rlen do
                        local b1, b2    = strbyte(data, index, index + 1)

                        sindex          = sindex + 1
                        subret[sindex]  = lshift(b1, 8) + b2

                        index           = index + 2
                    end

                    rindex              = rindex + 1
                    rets[rindex]        = subret
                end

                return rets
            end
        end

        --- perform a file record write
        __Arguments__{ FileWriteRecord * 1 }
        function WriteFileRecord(self, ...)
            local data                  = List{ ... }:Map(function(req)
                                            return encodeByte(6, 1) ..          -- Sub-Req. x, Reference Type   1 Byte
                                                encodeByte(req.file, 2) ..      -- Sub-Req. x, File Number      2 Bytes
                                                encodeByte(req.record, 2) ..    -- Sub-Req. x, Record Number    2 Bytes
                                                encodeByte(#req.data, 2) ..     -- Sub-Req. x, Record Length    2 Bytes
                                                XList(req.data):Map(function(v) -- Sub-Req. x, Record data N  x 2 Bytes
                                                    return encodeByte(v, 2)
                                                end):Join()
                                        end):Join()

            local count                 = #data     -- Byte Count 1 Byte 0x09 to 0xFB
            if count > 0xFB then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

            local identifier            = self:SendDataUnit(ProtocolDataUnit( PublicFunctionCode.WRITE_FILE_RECORD, encodeByte(count, 1) .. data ))

            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return record array
            if dataUnit then
                if dataUnit.exception then return false, dataUnit.exception end

                local data              = dataUnit.data
                local length            = strbyte(data, 1) -- Resp. data Length
                if length + 1 ~= #data then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

                local index             = 2
                local rets              = {}
                local rindex            = 0

                while index < length do
                    index               = index + 1     -- Skip Reference Type 1 Byte

                    local b1, b2, b3, b4, b5, b6 = strbyte(data, index, index + 5)
                    if not b6 then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

                    local record        = {
                        file            = lshift(b1, 8) + b2, -- Sub-Req. x, File Number 2 Bytes 0x0001 to 0xFFFF
                        record          = lshift(b3, 8) + b4, -- Sub-Req. x, Record number 2 Bytes 0x0000 to 0x270F
                        data            = {}
                    }

                    rindex              = rindex + 1
                    rets[rindex]        = record

                    local length        = lshift(b5, 8) + b6  -- Sub-Req. x, Record length 2 Bytes N
                    index               = index + 6

                    -- Sub-Req. x, Record Data N x 2 Bytes
                    for i = 1, length do
                        b1, b2          = strbyte(data, index, index + 1)

                        record.data[i]  = lshift(b1, 8) + b2
                        index           = index + 2
                    end
                end

                return rets
            end
        end

        --- modify the contents of a specified holding register using a combination of an AND mask, an OR mask, and the register's current contents
        __Arguments__{ UInt16, UInt16, UInt16 }
        function MaskWriteRegister(self, refAddress, andMask, orMask)
            -- Result = (Current Contents AND And_Mask) OR (Or_Mask AND (NOT And_Mask))
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.MASK_WRITE_REGISTER,
                                            encodeByte(refAddress, 2) ..    -- Reference Address   2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(andMask, 2) ..       -- And_Mask            2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(orMask, 2)           -- Or_Mask             2 Bytes 0x0000 to 0xFFFF
                                        ))

            -- Response:
            --      Reference Address 2 Bytes 0x0000 to 0xFFFF
            --      And_Mask 2 Bytes 0x0000 to 0xFFFF
            --      Or_Mask 2 Bytes 0x0000 to 0xFFFF
            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return true                      - if successs
            if dataUnit then
                if dataUnit.exception then return false, dataUnit.exception end
                return true
            end
        end

        --- performs a combination of one read operation and one write operation in a single MODBUS transaction
        __Arguments__{ UInt16, QuantityRegister, UInt16, UInt16 * 1 }
        function ReadWriteMultipleregisters(self, readAddress, readQuantity, writeAddress, ...)
            local writeQuantity         = select("#", ...)
            if writeQuantity > 0X0079 then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_WRITE_MULTIPLE_REGISTERS,
                                            encodeByte(readAddress, 2) ..       -- Read Starting Address    2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(readQuantity, 2) ..      -- Quantity to Read         2 Bytes 0x0001 to 0x007D
                                            encodeByte(writeAddress, 2) ..      -- Write Starting Address   2 Bytes 0x0000 to 0xFFFF
                                            encodeByte(writeQuantity, 2) ..     -- Quantity to Write        2 Bytes 0x0001 to 0X0079
                                            encodeByte(writeQuantity * 2, 1) .. -- Write Byte Count         1 Byte 2 x N*
                                            List{ ... }:Map(function(reg)       -- Write Registers Value    N*x 2 Bytes
                                                return encodeByte(reg, 2)
                                            end):Join()
                                        ))

            return returnValues(self, identifier, readQuantity)
        end

        --- read the contents of a First-In-First-Out (FIFO) queue of register in a remote device
        __Arguments__{ UInt16 }
        function ReadQueue(self, pointAddress)
            local identifier            = self:SendDataUnit(ProtocolDataUnit(
                                            PublicFunctionCode.READ_FIFO_QUEUE,
                                            encodeByte(pointAddress, 2)         -- FIFO Pointer Address
                                        ))

            local tid, uid, dataUnit    = self:ReceiveDataUnit()

            -- Skip the preivous response
            while tid and tid ~= identifier do
                tid, uid, dataUnit      = self:ReceiveDataUnit()
            end

            -- Return nil                       - if time out
            -- return false, exception code     - if return error
            -- return queue array
            if dataUnit then
                local length            = dataUnit.data and #dataUnit.data
                if dataUnit.exception or length < 4 then return false, dataUnit.exception end

                local data              = dataUnit.data
                local b1, b2, b3, b4    = strbyte(data, 1, 4)

                local byteCount         = lshift(b1, 8) + b2
                local fifoCount         = lshift(b3, 8) + b4

                if byteCount + 2 ~= length or fifoCount * 2 + 4 ~= length then return false, ExceptionCode.ILLEGAL_DATA_VALUE end

                local index             = 5
                local rets              = {}
                for i = 1, fifoCount do
                    b1, b2              = strbyte(data, index, index + 1)
                    rets[i]             = lshift(b1, 8) + b2
                    index               = index + 2
                end

                return rets
            end
        end
    end)
end)