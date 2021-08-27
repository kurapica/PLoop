--===========================================================================--
--                                                                           --
--                         System.Net.Protocol.Snap7                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/21                                               --
-- Update Date  :   2021/08/21                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    __Sealed__() __Final__()
    interface "System.Net.Snap7" (function(_ENV)

        import "System.Net"

        export {
            Date, TimeSpan,

            strchar             = string.char,
            strbyte             = string.byte,
            strsub              = string.sub,
            band                = Toolset.band,
            bor                 = Toolset.bor,
            lshift              = Toolset.lshift,
            rshift              = Toolset.rshift,
            inttoreal           = Toolset.inttoreal,
            realtoint           = Toolset.realtoint,
            tconcat             = table.concat,
            unpack              = _G.unpack or table.unpack,
            isObjectType        = Class.IsObjectType,
            type                = type,
            throw               = throw,
        }

        local function BCDtoByte(b)
            return (rshift(b, 4) * 10) + band(b, 0x0F)
        end

        local function ByteToBCD(byte)
            return band(lshift(floor(byte / 10), 4) + byte % 10, 0xFF)
        end

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        do
            __Static__() function DataSizeByte(wordLen)
                if wordLen == S7WordLength.BIT      then return 1 end
                if wordLen == S7WordLength.BYTE     then return 1 end
                if wordLen == S7WordLength.CHAR     then return 1 end
                if wordLen == S7WordLength.WORD     then return 2 end
                if wordLen == S7WordLength.INT      then return 2 end
                if wordLen == S7WordLength.DWORD    then return 4 end
                if wordLen == S7WordLength.DINT     then return 4 end
                if wordLen == S7WordLength.REAL     then return 4 end
                if wordLen == S7WordLength.DOUBLE   then return 8 end
                if wordLen == S7WordLength.STRING   then return 16 end
                return 0
            end

            --- Set|Get the bit
            __Static__()
            function GetBitAt(buffer, pos, bit)
                return band(rshift(buffer[pos], (not bit or bit < 0) and 0 or bit > 7 and 7 or bit), 1) == 1
            end

            __Static__() function SetBitAt(buffer, pos, bit, value)
                buffer[pos]         = value and lshift(1, (not bit or bit < 0) and 0 or bit > 7 and 7 or bit) or 0
            end

            --- 8 bit signed value (S7 SInt) -128..127
            __Static__() function GetSIntAt(buffer, pos)
                local val           = buffer[pos]
                return val and (val < 128 and val or (val - 256))
            end

            __Static__() function SetSIntAt(buffer, pos, value)
                buffer[pos]         = value < -128 and 128 or value > 127 and 127 or value < 0 and (value + 256) or value
            end

            --- 16 bit signed value (S7 int) -32768..32767
            __Static__() function GetIntAt(buffer, pos)
                local value         = lshift(buffer[pos], 8) + buffer[pos + 1]
                return value > 32767 and (value - 65536) or value
            end

            __Static__() function SetIntAt(buffer, pos, value)
                value               = value < -32768 and 32768 or value > 32767 and 32767 or value < 0 and (value + 65536) or value
                buffer[pos]         = rshift(value, 8)
                buffer[pos + 1]     = band(value, 0xFF)
            end

            --- 32 bit signed value (S7 DInt) -2147483648..2147483647
            __Static__() function GetDIntAt(buffer, pos)
                pos                 = pos or 1
                local b1, b2, b3, b4= strbyte(buffer, pos, pos + 3)
                if not b4 then return end

                local value         = lshift(buffer[pos], 24) + lshift(buffer[pos + 1], 16) + lshift(buffer[pos + 2], 8) + buffer[pos + 3]
                return value > 2147483647 and (value - 4294967296) or value
            end

            __Static__() function SetDIntAt(buffer, pos, value)
                value               = value < -2147483648 and 2147483648 or value > 2147483647 and 2147483647 or value < 0 and (value + 4294967296) or value

                buffer[pos]         = rshift(value, 24)
                buffer[pos + 1]     = band(rshift(value, 16), 0xFF)
                buffer[pos + 2]     = band(rshift(value, 8), 0xFF)
                buffer[pos + 3]     = band(value, 0xFF)
            end

            --- 8 bit unsigned value (S7 USInt) 0..255
            __Static__() function GetUSIntAt(buffer, pos)
                return buffer[pos]
            end

            __Static__() function SetUSIntAt(buffer, pos, value)
                buffer[pos]         = band(value < 0 and 0 or value, 0xFF)
            end

            --- 16 bit unsigned value (S7 UInt) 0..65535
            __Static__() function GetUIntAt(buffer, pos)
                return lshift(buffer[pos], 8) + buffer[pos + 1]
            end

            __Static__() function SetUIntAt(buffer, pos, value)
                value               = value < 0 and 0 or value > 65535 and 65535 or value
                buffer[pos]         = rshift(value, 8)
                buffer[pos + 1]     = band(value, 0xFF)
            end

            --- 32 bit unsigned value (S7 UDInt) 0..4294967295
            __Static__() function GetUDIntAt(buffer, pos)
                return lshift(buffer[pos], 24) + lshift(buffer[pos + 1], 16) + lshift(buffer[pos + 2], 8) + buffer[pos + 3]
            end

            __Static__() function SetUDIntAt(buffer, pos, value)
                value               = value < 0 and 0 or value > 4294967295 and 4294967295 or value
                buffer[pos]         = rshift(value, 24)
                buffer[pos + 1]     = band(rshift(value, 16), 0xFF)
                buffer[pos + 2]     = band(rshift(value, 8), 0xFF)
                buffer[pos + 3]     = band(value, 0xFF)
            end

            --- 8 bit word (S7 Byte) 16#00..16#FF
            __Static__() GetByteAt  = GetUSIntAt
            __Static__() SetByteAt  = SetUSIntAt

            --- 16 bit word (S7 Word) 16#0000..16#FFFF
            __Static__() GetWordAt  = GetUIntAt
            __Static__() SetWordAt  = SetUIntAt

            --- 32 bit word (S7 DWord) 16#00000000..16#FFFFFFFF
            __Static__() GetDWordAt = GetUDIntAt
            __Static__() SetDWordAt = SetUDIntAt

            --- 32 bit floating point number (S7 Real) (Range of Single)
            __Static__() function GetRealAt(buffer, pos)
                local value         = GetUDIntAt(buffer, pos)
                if value then return inttoreal(value) end
            end

            __Static__() function SetRealAt(buffer, pos, value)
                local value         = realtoint(value)
                return SetUDIntAt(buffer, pos, value)
            end

            --- DateTime (S7 DATE_AND_TIME)
            __Static__() function GetDateTimeAt(buffer, pos)
                pos                 = pos or 1

                local b1, b2, b3, b4, b5, b6, b7, b8 = strbyte(buffer, pos, pos + 7)
                if not b8 then return end

                local year          = BCDtoByte(buffer[pos])
                year                = year < 90 and (year + 2000) or (year + 1900)

                local month         = BCDtoByte(buffer[pos + 1])
                local day           = BCDtoByte(buffer[pos + 2])
                local hour          = BCDtoByte(buffer[pos + 3])
                local min           = BCDtoByte(buffer[pos + 4])
                local sec           = BCDtoByte(buffer[pos + 5])
                local msec          = floor(BCDtoByte(buffer[pos + 6]) * 10 + BCDtoByte(buffer[pos + 7]) / 10)

                return Date(year, month, day, hour, min, sec, msec)
            end

            __Static__() function SetDateTimeAt(buffer, pos, value)
                buffer[pos]         = ByteToBCD(value.Year > 1999 and (value.Year - 2000) or (value.Year - 1900))
                buffer[pos + 1]     = ByteToBCD(value.Month)
                buffer[pos + 2]     = ByteToBCD(value.Day)
                buffer[pos + 3]     = ByteToBCD(value.Hour)
                buffer[pos + 4]     = ByteToBCD(value.Minutes)
                buffer[pos + 5]     = ByteToBCD(value.Second)
                buffer[pos + 6]     = ByteToBCD(floor(value.Milliseconds/10))
                buffer[pos + 7]     = ByteToBCD(value.Milliseconds % 10 * 10 + value.DayOfWeek + 1)
            end

            --- DATE (S7 DATE)
            __Static__() function GetDateAt(buffer, pos)
                return Date(1990, 1, 1 + GetIntAt(buffer, pos), 0, 0, 0)
            end

            __Static__() function SetDateAt(buffer, pos, value)
                return SetIntAt(buffer, pos, (value - Date(1990, 1, 1, 0, 0, 0)).Days)
            end

            --- Counter
            __Static__() function GetCounter(value)
                return BCDtoByte(band(value, 0xFF)) * 100 + BCDtoByte(band(rshift(value, 8), 0xFF))
            end

            __Static__() function GetCounterAt(buffer, pos)
                return GetCounter(lshift(buffer[pos], 8) + buffer[pos + 1])
            end

            __Static__() function ToCounter(value)
                return band(ByteToBCD(floor(value / 100)) + lshift(ByteToBCD(value % 100), 8), 0xFFFF)
            end

            __Static__() function SetCounterAt(buffer, pos, value)
                local value         = ToCounter(value)
                buffer[pos]         = rshift(value, 8)
                buffer[pos + 1]     = band(value, 0xFF)
            end

            --- Timer
            __Static__() function GetS7TimerAt(buffer, pos)
                return S7Timer{ unpack(buffer, pos, pos + 11) }
            end

            __Static__() function SetS7TimespanAt(buffer, pos, value)
                return SetDIntAt(buffer, pos, band(floor(value.TotalMilliseconds), 0xFFFFFFFF))
            end

            __Static__() function GetS7TimespanAt(buffer, pos)
                return TimeSpan(0, 0, 0, 0, lshift(buffer[pos], 24) + lshift(buffer[pos + 1], 16) + lshift(buffer[pos + 2], 8) + buffer[pos + 3])
            end

            __Static__() function GetCharsAt(buffer, pos, size)
                return strchar(unpack(buffer, pos, pos + size - 1))
            end

            __Static__() function SetCharsAt(buffer, pos, value)
                for i = 1, #value do
                    buffer[pos]     = strbyte(value, i)
                    pos             = pos + 1
                end
            end
        end

        -----------------------------------------------------------------------
        --                           feature types                           --
        -----------------------------------------------------------------------
        __Sealed__()
        enum "S7Exception"          { Exception }

        __Sealed__()
        enum "S7ErrorCode"          {
            TCPSOCKETCREATION       = 0x00000001,
            TCPCONNECTIONTIMEOUT    = 0x00000002,
            TCPCONNECTIONFAILED     = 0x00000003,
            TCPRECEIVETIMEOUT       = 0x00000004,
            TCPDATARECEIVE          = 0x00000005,
            TCPSENDTIMEOUT          = 0x00000006,
            TCPDATASEND             = 0x00000007,
            TCPCONNECTIONRESET      = 0x00000008,
            TCPNOTCONNECTED         = 0x00000009,
            TCPUNREACHABLEHOST      = 0x00002751,

            ISOCONNECT              = 0x00010000,
            ISOINVALIDPDU           = 0x00030000,
            ISOINVALIDDATASIZE      = 0x00040000,

            CLINEGOTIATINGPDU       = 0x00100000,
            CLIINVALIDPARAMS        = 0x00200000,
            CLIJOBPENDING           = 0x00300000,
            CLITOOMANYITEMS         = 0x00400000,
            CLIINVALIDWORDLEN       = 0x00500000,
            CLIPARTIALDATAWRITTEN   = 0x00600000,
            CLISIZEOVERPDU          = 0x00700000,
            CLIINVALIDPLCANSWER     = 0x00800000,
            CLIADDRESSOUTOFRANGE    = 0x00900000,
            CLIINVALIDTRANSPORTSIZE = 0x00A00000,
            CLIWRITEDATASIZEMISMATCH= 0x00B00000,
            CLIITEMNOTAVAILABLE     = 0x00C00000,
            CLIINVALIDVALUE         = 0x00D00000,
            CLICANNOTSTARTPLC       = 0x00E00000,
            CLIALREADYRUN           = 0x00F00000,
            CLICANNOTSTOPPLC        = 0x01000000,
            CLICANNOTCOPYRAMTOROM   = 0x01100000,
            CLICANNOTCOMPRESS       = 0x01200000,
            CLIALREADYSTOP          = 0x01300000,
            CLIFUNNOTAVAILABLE      = 0x01400000,
            CLIUPLOADSEQUENCEFAILED = 0x01500000,
            CLIINVALIDDATASIZERECVD = 0x01600000,
            CLIINVALIDBLOCKTYPE     = 0x01700000,
            CLIINVALIDBLOCKNUMBER   = 0x01800000,
            CLIINVALIDBLOCKSIZE     = 0x01900000,
            CLINEEDPASSWORD         = 0x01D00000,
            CLIINVALIDPASSWORD      = 0x01E00000,
            CLINOPASSWORDTOSETORCLEAR = 0x01F00000,
            CLIJOBTIMEOUT           = 0x02000000,
            CLIPARTIALDATAREAD      = 0x02100000,
            CLIBUFFERTOOSMALL       = 0x02200000,
            CLIFUNCTIONREFUSED      = 0x02300000,
            CLIDESTROYING           = 0x02400000,
            CLIINVALIDPARAMNUMBER   = 0x02500000,
            CLICANNOTCHANGEPARAM    = 0x02600000,
            CLIFUNCTIONNOTIMPLEMENTED = 0x02700000,
        }

        __Sealed__()
        enum "S7Area"               {
            PE                      = 0x81,
            PA                      = 0x82,
            MK                      = 0x83,
            DB                      = 0x84,
            CT                      = 0x1C,
            TM                      = 0x1D,
        }

        __Sealed__()
        enum "S7WordLength"         {
            BIT                     = 0x01,
            BYTE                    = 0x02,
            CHAR                    = 0x03,
            WORD                    = 0x04,
            INT                     = 0x05,
            DWORD                   = 0x06,
            DINT                    = 0x07,
            REAL                    = 0x08,
            DOUBLE                  = 0x1A,
            STRING                  = 0x1B,
            COUNTER                 = 0x1C,
            TIMER                   = 0x1D,
        }

        __Sealed__()
        enum "S7PLCStatus"          {
            UNKNOWN                 = 0x00,
            RUN                     = 0x08,
            STOP                    = 0x04,
        }

        __Sealed__()
        enum "S7Block"              {
            OB                      = 0x38,
            DB                      = 0x41,
            SDB                     = 0x42,
            FC                      = 0x43,
            SFC                     = 0x44,
            FB                      = 0x45,
            SFB                     = 0x46,
        }

        __Sealed__()
        enum "S7SubBlock"           {
            OB                      = 0x08,
            DB                      = 0x0A,
            SDB                     = 0x0B,
            FC                      = 0x0C,
            SFC                     = 0x0D,
            FB                      = 0x0E,
            SFB                     = 0x0F,
        }

        __Sealed__()
        enum "S7BlockLanguage"      {
            AWL                     = 0x01,
            KOP                     = 0x02,
            FUP                     = 0x03,
            SCL                     = 0x04,
            DB                      = 0x05,
            GRAPH                   = 0x06,
        }

        __Sealed__()
        enum "S7ConnectionType"     {
            PG                      = 0x01, -- Connect to the PLC as a PG
            OP                      = 0x02, -- Connect to the PLC as an OP
            BASIC                   = 0x03, -- Basic connection
        }

        __Sealed__()
        struct "S7Tag"              {
            { name = "area",        type = Int32 },
            { name = "dbnumber",    type = Int32 },
            { name = "start",       type = Int32 },
            { name = "elements",    type = Int32 },
            { name = "wordlen",     type = Int32 },
        }

        __Sealed__()
        struct "S7DataItem"        {
            { name = "Area",        type = Integer },
            { name = "WordLen",     type = Integer },
            { name = "Result",      type = Integer },
            { name = "DBNumber",    type = Integer },
            { name = "Start",       type = Integer },
            { name = "Amount",      type = Integer },
            { name = "pData",       type = Table },
        }

        -- Order Code + Version
        __Sealed__()
        struct "S7OrderCode"        {
            { name = "Code",        type = String }, -- such as "6ES7 151-8AB01-0AB0"
            { name = "V1",          type = Byte },     -- Version 1st digit
            { name = "V2",          type = Byte },     -- Version 2nd digit
            { name = "V3",          type = Byte },     -- Version 3th digit
        }

        -- CPU Info
        __Sealed__()
        struct "S7CpuInfo"        {
            { name = "ModuleTypeName",  type = String },
            { name = "SerialNumber",    type = String },
            { name = "ASName",          type = String },
            { name = "Copyright",       type = String },
            { name = "ModuleName",      type = String },
        }

        __Sealed__()
        struct "S7CpInfo"           {
            { name = "MaxPduLength",    type = Integer },
            { name = "MaxConnections",  type = Integer },
            { name = "MaxMpiRate",      type = Integer },
            { name = "MaxBusRate",      type = Integer },
        }

        --  Block List
        __Sealed__()
        struct "S7BlocksList"       {
            { name = "OBCount",     type = Int32, default = 0 },
            { name = "FBCount",     type = Int32, default = 0 },
            { name = "FCCount",     type = Int32, default = 0 },
            { name = "SFBCount",    type = Int32, default = 0 },
            { name = "SFCCount",    type = Int32, default = 0 },
            { name = "DBCount",     type = Int32, default = 0 },
            { name = "SDBCount",    type = Int32, default = 0 },
        }

        --  Managed Block Info
        __Sealed__()
        struct "S7BlockInfo"        {
            { name = "BlkType",     type = Integer },
            { name = "BlkNumber",   type = Integer },
            { name = "BlkLang",     type = Integer },
            { name = "BlkFlags",    type = Integer },
            { name = "MC7Size",     type = Integer },  --  The real size in bytes
            { name = "LoadSize",    type = Integer },
            { name = "LocalData",   type = Integer },
            { name = "SBBLength",   type = Integer },
            { name = "CheckSum",    type = Integer },
            { name = "Version",     type = Integer },
            --  Chars info
            { name = "CodeDate",    type = String },
            { name = "IntfDate",    type = String },
            { name = "Author",      type = String },
            { name = "Family",      type = String },
            { name = "Header",      type = String },
        }

        --  See §33.1 of "System Software for S7-300/400 System and Standard Functions and see SFC51 description too
        __Sealed__()
        struct "SZL_HEADER"         {
            { name = "LENTHDR",     type = UInt16 },
            { name = "N_DR",        type = UInt16 },
        }

        __Sealed__()
        struct "S7SZL"              {
            { name = "Header",      type = SZL_HEADER },
            { name = "Data",        type = Table }, -- byte[]
        }

        --  SZL List of available SZL IDs : same as SZL but List items are big-endian adjusted
        __Sealed__()
        struct "S7SZLList"          {
            { name = "Header",      type = SZL_HEADER },
            { name = "Data",        type = Table }, -- UInt16[]
        }

        --  S7 Protection
        --  See §33.19 of "System Software for S7-300/400 System and Standard Functions"
        __Sealed__()
        struct "S7Protection"       {
            { name = "sch_schal",   type = UInt16 },
            { name = "sch_par",     type = UInt16 },
            { name = "sch_rel",     type = UInt16 },
            { name = "bart_sch",    type = UInt16 },
            { name = "anl_sch",     type = UInt16 },
        }

        __Sealed__()
        class "S7Timer"             (function(_ENV)
            export { TimeSpan, lshift = Toolset.lshift, band = Toolset.band }

            -----------------------------------------------------------------------
            --                             property                              --
            -----------------------------------------------------------------------
            property "PT"           { type = TimeSpan }
            property "ET"           { type = TimeSpan }
            property "IN"           { type = Boolean, default = false }
            property "Q"            { type = Boolean, default = false }

            -----------------------------------------------------------------------
            --                           constructor                             --
            -----------------------------------------------------------------------
            __Arguments__{ Table }
            function __ctor(self, buffer)
                if (#buffer ~= 12) then
                    self.PT         = TimeSpan(0)
                    self.ET         = TimeSpan(0)
                else
                    self.PT         = TimeSpan(0, 0, 0, 0, lshift(buffer[1], 24) + lshift(buffer[2], 16) + lshift(buffer[3], 8) + buffer[4])
                    self.ET         = TimeSpan(0, 0, 0, 0, lshift(buffer[5], 24) + lshift(buffer[6], 16) + lshift(buffer[7], 8) + buffer[8])
                    self.IN         = band(buffer[9], 0x01) == 0x01
                    self.Q          = band(buffer[9], 0x02) == 0x02
                end
            end
        end)

        --- The Snap7 Lua Client
        __Sealed__()
        class "Client"              (function(_ENV)
            inherit "System.Context"
            extend "System.IAutoClose"

            -- Only use this for test or client side only
            local SocketType        = System.Net.Socket

            export {
                S7Exception, S7ErrorCode, S7Area, S7WordLength,
                S7PLCStatus, S7Block, S7SubBlock, S7BlockLanguage, S7ConnectionType,
                S7CpInfo, S7BlocksList, S7BlockInfo, SZL_HEADER, S7SZL, S7SZLList, S7Protection,
                TimeoutException,

                strbyte             = strbyte,
                strchar             = strchar,
                unpack              = _G.unpack or table.unpack,
                rawset              = rawset,
                pcall               = pcall,
                error               = error,
                clone               = Toolset.clone,
                lshift              = Toolset.lshift,
                rshift              = Toolset.rshift,
                band                = Toolset.band,
                bxor                = Toolset.bxor,
                floor               = math.floor,
                isObjectType        = Class.IsObjectType,
                Trace               = Logger.Default[Logger.LogLevel.Trace],

                DataSizeByte        = DataSizeByte,
                GetBitAt            = GetBitAt,
                SetBitAt            = SetBitAt,
                GetSIntAt           = GetSIntAt,
                SetSIntAt           = SetSIntAt,
                GetIntAt            = GetIntAt,
                SetIntAt            = SetIntAt,
                GetDIntAt           = GetDIntAt,
                SetDIntAt           = SetDIntAt,
                GetUSIntAt          = GetUSIntAt,
                SetUSIntAt          = SetUSIntAt,
                GetUIntAt           = GetUIntAt,
                SetUIntAt           = SetUIntAt,
                GetUDIntAt          = GetUDIntAt,
                SetUDIntAt          = SetUDIntAt,
                GetRealAt           = GetRealAt,
                SetRealAt           = SetRealAt,
                GetDateTimeAt       = GetDateTimeAt,
                SetDateTimeAt       = SetDateTimeAt,
                GetDateAt           = GetDateAt,
                SetDateAt           = SetDateAt,
                GetCounter          = GetCounter,
                GetCounterAt        = GetCounterAt,
                ToCounter           = ToCounter,
                SetCounterAt        = SetCounterAt,
                GetS7TimerAt        = GetS7TimerAt,
                SetS7TimespanAt     = SetS7TimespanAt,
                GetS7TimespanAt     = GetS7TimespanAt,
                GetCharsAt          = GetCharsAt,
                SetCharsAt          = SetCharsAt,

                GetByteAt           = GetByteAt,
                SetByteAt           = SetByteAt,
                GetWordAt           = GetWordAt,
                SetWordAt           = SetWordAt,
                GetDWordAt          = GetDWordAt,
                SetDWordAt          = SetDWordAt,

                TS_ResBit           = 0x03,
                TS_ResByte          = 0x04,
                TS_ResInt           = 0x05,
                TS_ResReal          = 0x07,
                TS_ResOctet         = 0x09,

                Code7Ok                     = 0x0000,
                Code7AddressOutOfRange      = 0x0005,
                Code7InvalidTransportSize   = 0x0006,
                Code7WriteDataSizeMismatch  = 0x0007,
                Code7ResItemNotAvailable    = 0x000A,
                Code7ResItemNotAvailable1   = 0xD209,
                Code7InvalidValue           = 0xDC01,
                Code7NeedPassword           = 0xD241,
                Code7InvalidPassword        = 0xD602,
                Code7NoPasswordToClear      = 0xD604,
                Code7NoPasswordToSet        = 0xD605,
                Code7FunNotAvailable        = 0x8104,
                Code7DataOverPDU            = 0x8500,

                Size_RD                     = 31, -- Header Size when Reading
                Size_WR                     = 35, -- Header Size when Writing

                pduStart                    = 0x28, -- CPU start
                pduStop                     = 0x29, -- CPU stop
                pduAlreadyStarted           = 0x02, -- CPU already in run mode
                pduAlreadyStopped           = 0x07, -- CPU already in stop mode

                -- Defaults
                ISOTCP                      = 102, -- ISOTCP Port
                MinPduSize                  = 16,
                MinPduSizeToRequest         = 240,
                MaxPduSizeToRequest         = 960,
                DefaultTimeout              = 2000,
                IsoHSize                    = 7, -- TPKT+COTP Header Size
            }

            INIT_TABLES             = {
                -- ISO Connection Request telegram (contains also ISO Header and COTP Header)
                ISO_CR              = {
                    -- TPKT (RFC1006 Header)
                    [0] = 0x03, -- RFC 1006 ID (3)
                    0x00, -- Reserved, always 0
                    0x00, -- High part of packet lenght (entire frame, payload and TPDU included)
                    0x16, -- Low part of packet lenght (entire frame, payload and TPDU included)
                    -- COTP (ISO 8073 Header)
                    0x11, -- PDU Size Length
                    0xE0, -- CR - Connection Request ID
                    0x00, -- Dst Reference HI
                    0x00, -- Dst Reference LO
                    0x00, -- Src Reference HI
                    0x01, -- Src Reference LO
                    0x00, -- Class + Options Flags
                    0xC0, -- PDU Max Length ID
                    0x01, -- PDU Max Length HI
                    0x0A, -- PDU Max Length LO
                    0xC1, -- Src TSAP Identifier
                    0x02, -- Src TSAP Length (2 bytes)
                    0x01, -- Src TSAP HI (will be overwritten)
                    0x00, -- Src TSAP LO (will be overwritten)
                    0xC2, -- Dst TSAP Identifier
                    0x02, -- Dst TSAP Length (2 bytes)`
                    0x01, -- Dst TSAP HI (will be overwritten)
                    0x02  -- Dst TSAP LO (will be overwritten)
                },

                -- TPKT + ISO COTP Header (Connection Oriented Transport Protocol)
                TPKT_ISO            = { -- 7 bytes
                    [0] = 0x03,0x00,
                    0x00,0x1f,      -- Telegram Length (Data Size + 31 or 35)
                    0x02,0xf0,0x80  -- COTP (see above for info)
                },

                -- S7 PDU Negotiation Telegram (contains also ISO Header and COTP Header)
                S7_PN               = {
                    [0] = 0x03, 0x00, 0x00, 0x19,
                    0x02, 0xf0, 0x80, -- TPKT + COTP (see above for info)
                    0x32, 0x01, 0x00, 0x00,
                    0x04, 0x00, 0x00, 0x08,
                    0x00, 0x00, 0xf0, 0x00,
                    0x00, 0x01, 0x00, 0x01,
                    0x00, 0x1e        -- PDU Length Requested = HI-LO Here Default 480 bytes
                },

                -- S7 Read/Write Request Header (contains also ISO Header and COTP Header)
                S7_RW               = { -- 31-35 bytes
                    [0] = 0x03,0x00,
                    0x00,0x1f,       -- Telegram Length (Data Size + 31 or 35)
                    0x02,0xf0, 0x80, -- COTP (see above for info)
                    0x32,            -- S7 Protocol ID
                    0x01,            -- Job Type
                    0x00,0x00,       -- Redundancy identification
                    0x05,0x00,       -- PDU Reference
                    0x00,0x0e,       -- Parameters Length
                    0x00,0x00,       -- Data Length = Size(bytes) + 4
                    0x04,            -- Function 4 Read Var, 5 Write Var
                    0x01,            -- Items count
                    0x12,            -- Var spec.
                    0x0a,            -- Length of remaining bytes
                    0x10,            -- Syntax ID
                    S7WordLength.BYTE,  -- Transport Size idx=22
                    0x00,0x00,       -- Num Elements
                    0x00,0x00,       -- DB Number (if any, else 0)
                    0x84,            -- Area Type
                    0x00,0x00,0x00,  -- Area Offset
                    -- WR area
                    0x00,            -- Reserved
                    0x04,            -- Transport size
                    0x00,0x00,       -- Data Length * 8 (if not bit or timer or counter)
                },

                -- S7 Variable MultiRead Header
                S7_MRD_HEADER       = {
                    [0] = 0x03,0x00,
                    0x00,0x1f,       -- Telegram Length
                    0x02,0xf0, 0x80, -- COTP (see above for info)
                    0x32,            -- S7 Protocol ID
                    0x01,            -- Job Type
                    0x00,0x00,       -- Redundancy identification
                    0x05,0x00,       -- PDU Reference
                    0x00,0x0e,       -- Parameters Length
                    0x00,0x00,       -- Data Length = Size(bytes) + 4
                    0x04,            -- Function 4 Read Var, 5 Write Var
                    0x01             -- Items count (idx 18)
                },

                -- S7 Variable MultiRead Item
                S7_MRD_ITEM         = {
                    [0] = 0x12,      -- Var spec.
                    0x0a,            -- Length of remaining bytes
                    0x10,            -- Syntax ID
                    S7WordLength.BYTE,  -- Transport Size idx=3
                    0x00,0x00,       -- Num Elements
                    0x00,0x00,       -- DB Number (if any, else 0)
                    0x84,            -- Area Type
                    0x00,0x00,0x00   -- Area Offset
                },

                -- S7 Variable MultiWrite Header
                S7_MWR_HEADER       = {
                    [0] = 0x03,0x00,
                    0x00,0x1f,       -- Telegram Length
                    0x02,0xf0, 0x80, -- COTP (see above for info)
                    0x32,            -- S7 Protocol ID
                    0x01,            -- Job Type
                    0x00,0x00,       -- Redundancy identification
                    0x05,0x00,       -- PDU Reference
                    0x00,0x0e,       -- Parameters Length (idx 13)
                    0x00,0x00,       -- Data Length = Size(bytes) + 4 (idx 15)
                    0x05,            -- Function 5 Write Var
                    0x01             -- Items count (idx 18)
                },

                -- S7 Variable MultiWrite Item (Param)
                S7_MWR_PARAM        = {
                    [0] = 0x12,      -- Var spec.
                    0x0a,            -- Length of remaining bytes
                    0x10,            -- Syntax ID
                    S7WordLength.BYTE,  -- Transport Size idx=3
                    0x00,0x00,       -- Num Elements
                    0x00,0x00,       -- DB Number (if any, else 0)
                    0x84,            -- Area Type
                    0x00,0x00,0x00,  -- Area Offset
                },

                -- SZL First telegram request
                S7_SZL_FIRST        = {
                    [0] = 0x03, 0x00, 0x00, 0x21,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00,
                    0x05, 0x00, -- Sequence out
                    0x00, 0x08, 0x00,
                    0x08, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x44, 0x01,
                    0x00, 0xff, 0x09, 0x00,
                    0x04,
                    0x00, 0x00, -- ID (29)
                    0x00, 0x00  -- Index (31)
                },

                -- SZL Next telegram request
                S7_SZL_NEXT         = {
                    [0] = 0x03, 0x00, 0x00, 0x21,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x06,
                    0x00, 0x00, 0x0c, 0x00,
                    0x04, 0x00, 0x01, 0x12,
                    0x08, 0x12, 0x44, 0x01,
                    0x01, -- Sequence
                    0x00, 0x00, 0x00, 0x00,
                    0x0a, 0x00, 0x00, 0x00
                },

                -- Get Date/Time request
                S7_GET_DT           = {
                    [0] = 0x03, 0x00, 0x00, 0x1d,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x38,
                    0x00, 0x00, 0x08, 0x00,
                    0x04, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x47, 0x01,
                    0x00, 0x0a, 0x00, 0x00,
                    0x00
                },

                -- Set Date/Time command
                S7_SET_DT           = {
                    [0] = 0x03, 0x00, 0x00, 0x27,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x89,
                    0x03, 0x00, 0x08, 0x00,
                    0x0e, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x47, 0x02,
                    0x00, 0xff, 0x09, 0x00,
                    0x0a, 0x00,
                    0x19, -- Hi part of Year (idx=30)
                    0x13, -- Lo part of Year
                    0x12, -- Month
                    0x06, -- Day
                    0x17, -- Hour
                    0x37, -- Min
                    0x13, -- Sec
                    0x00, 0x01 -- ms + Day of week
                },

                -- S7 Set Session Password
                S7_SET_PWD          = {
                    [0] = 0x03, 0x00, 0x00, 0x25,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x27,
                    0x00, 0x00, 0x08, 0x00,
                    0x0c, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x45, 0x01,
                    0x00, 0xff, 0x09, 0x00,
                    0x08,
                    -- 8 Char Encoded Password
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00
                },

                -- S7 Clear Session Password
                S7_CLR_PWD          = {
                    [0] = 0x03, 0x00, 0x00, 0x1d,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x29,
                    0x00, 0x00, 0x08, 0x00,
                    0x04, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x45, 0x02,
                    0x00, 0x0a, 0x00, 0x00,
                    0x00
                },

                -- S7 STOP request
                S7_STOP             = {
                    [0] = 0x03, 0x00, 0x00, 0x21,
                    0x02, 0xf0, 0x80, 0x32,
                    0x01, 0x00, 0x00, 0x0e,
                    0x00, 0x00, 0x10, 0x00,
                    0x00, 0x29, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x09,
                    0x50, 0x5f, 0x50, 0x52,
                    0x4f, 0x47, 0x52, 0x41,
                    0x4d
                },

                -- S7 HOT Start request
                S7_HOT_START        = {
                    [0] = 0x03, 0x00, 0x00, 0x25,
                    0x02, 0xf0, 0x80, 0x32,
                    0x01, 0x00, 0x00, 0x0c,
                    0x00, 0x00, 0x14, 0x00,
                    0x00, 0x28, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0xfd, 0x00, 0x00, 0x09,
                    0x50, 0x5f, 0x50, 0x52,
                    0x4f, 0x47, 0x52, 0x41,
                    0x4d
                },

                -- S7 COLD Start request
                S7_COLD_START       = {
                    [0] = 0x03, 0x00, 0x00, 0x27,
                    0x02, 0xf0, 0x80, 0x32,
                    0x01, 0x00, 0x00, 0x0f,
                    0x00, 0x00, 0x16, 0x00,
                    0x00, 0x28, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0xfd, 0x00, 0x02, 0x43,
                    0x20, 0x09, 0x50, 0x5f,
                    0x50, 0x52, 0x4f, 0x47,
                    0x52, 0x41, 0x4d
                },

                -- S7 Get PLC Status
                S7_GET_STAT         = {
                    [0] = 0x03, 0x00, 0x00, 0x21,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x2c,
                    0x00, 0x00, 0x08, 0x00,
                    0x08, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x44, 0x01,
                    0x00, 0xff, 0x09, 0x00,
                    0x04, 0x04, 0x24, 0x00,
                    0x00
                },

                -- S7 Get Block Info Request Header (contains also ISO Header and COTP Header)
                S7_BI               = {
                    [0] = 0x03, 0x00, 0x00, 0x25,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x05,
                    0x00, 0x00, 0x08, 0x00,
                    0x0c, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x43, 0x03,
                    0x00, 0xff, 0x09, 0x00,
                    0x08, 0x30,
                    0x41, -- Block Type
                    0x30, 0x30, 0x30, 0x30, 0x30, -- ASCII Block Number
                    0x41
                },

                -- S7 List Blocks Request Header
                S7_LIST_BLOCKS      = {
                    [0] = 0x03, 0x00, 0x00, 0x1d,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x08, 0x00,
                    0x04, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x43, 0x01, -- 0x43 0x01 = ListBlocks
                    0x00, 0x0a, 0x00, 0x00,
                    0x00
                },

                -- S7 List Blocks Of Type Request Header
                S7_LIST_BLOCKS_OF_TYPE = {
                    [0] = 0x03, 0x00, 0x00, 0x1f,
                    0x02, 0xf0, 0x80, 0x32,
                    0x07, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x08, 0x00,
                    0x06, 0x00, 0x01, 0x12,
                    0x04, 0x11, 0x43, 0x02, -- 0x43 0x02 = ListBlocksOfType
                    0x00 -- ... append ReqData
                },
            }

            ERROR_MSG_MAP           = {
                [0]             = "OK",
                [S7ErrorCode.TCPSOCKETCREATION]           = "SYS : Error creating the Socket",
                [S7ErrorCode.TCPCONNECTIONTIMEOUT]        = "TCP : Connection Timeout",
                [S7ErrorCode.TCPCONNECTIONFAILED]         = "TCP : Connection Error",
                [S7ErrorCode.TCPRECEIVETIMEOUT]           = "TCP : Data receive Timeout",
                [S7ErrorCode.TCPDATARECEIVE]              = "TCP : Error receiving Data",
                [S7ErrorCode.TCPSENDTIMEOUT]              = "TCP : Data send Timeout",
                [S7ErrorCode.TCPDATASEND]                 = "TCP : Error sending Data",
                [S7ErrorCode.TCPCONNECTIONRESET]          = "TCP : Connection reset by the Peer",
                [S7ErrorCode.TCPNOTCONNECTED]             = "CLI : Client not connected",
                [S7ErrorCode.TCPUNREACHABLEHOST]          = "TCP : Unreachable host",
                [S7ErrorCode.ISOCONNECT]                  = "ISO : Connection Error",
                [S7ErrorCode.ISOINVALIDPDU]               = "ISO : Invalid PDU received",
                [S7ErrorCode.ISOINVALIDDATASIZE]          = "ISO : Invalid Buffer passed to Send/Receive",
                [S7ErrorCode.CLINEGOTIATINGPDU]           = "CLI : Error in PDU negotiation",
                [S7ErrorCode.CLIINVALIDPARAMS]            = "CLI : invalid param(s) supplied",
                [S7ErrorCode.CLIJOBPENDING]               = "CLI : Job pending",
                [S7ErrorCode.CLITOOMANYITEMS]             = "CLI : too may items (>20) in multi read/write",
                [S7ErrorCode.CLIINVALIDWORDLEN]           = "CLI : invalid S7WordLength",
                [S7ErrorCode.CLIPARTIALDATAWRITTEN]       = "CLI : Partial data written",
                [S7ErrorCode.CLISIZEOVERPDU]              = "CPU : total data exceeds the PDU size",
                [S7ErrorCode.CLIINVALIDPLCANSWER]         = "CLI : invalid CPU answer",
                [S7ErrorCode.CLIADDRESSOUTOFRANGE]        = "CPU : Address out of range",
                [S7ErrorCode.CLIINVALIDTRANSPORTSIZE]     = "CPU : Invalid Transport size",
                [S7ErrorCode.CLIWRITEDATASIZEMISMATCH]    = "CPU : Data size mismatch",
                [S7ErrorCode.CLIITEMNOTAVAILABLE]         = "CPU : Item not available",
                [S7ErrorCode.CLIINVALIDVALUE]             = "CPU : Invalid value supplied",
                [S7ErrorCode.CLICANNOTSTARTPLC]           = "CPU : Cannot start PLC",
                [S7ErrorCode.CLIALREADYRUN]               = "CPU : PLC already RUN",
                [S7ErrorCode.CLICANNOTSTOPPLC]            = "CPU : Cannot stop PLC",
                [S7ErrorCode.CLICANNOTCOPYRAMTOROM]       = "CPU : Cannot copy RAM to ROM",
                [S7ErrorCode.CLICANNOTCOMPRESS]           = "CPU : Cannot compress",
                [S7ErrorCode.CLIALREADYSTOP]              = "CPU : PLC already STOP",
                [S7ErrorCode.CLIFUNNOTAVAILABLE]          = "CPU : Function not available",
                [S7ErrorCode.CLIUPLOADSEQUENCEFAILED]     = "CPU : Upload sequence failed",
                [S7ErrorCode.CLIINVALIDDATASIZERECVD]     = "CLI : Invalid data size received",
                [S7ErrorCode.CLIINVALIDBLOCKTYPE]         = "CLI : Invalid block type",
                [S7ErrorCode.CLIINVALIDBLOCKNUMBER]       = "CLI : Invalid block number",
                [S7ErrorCode.CLIINVALIDBLOCKSIZE]         = "CLI : Invalid block size",
                [S7ErrorCode.CLINEEDPASSWORD]             = "CPU : Function not authorized for current protection level",
                [S7ErrorCode.CLIINVALIDPASSWORD]          = "CPU : Invalid password",
                [S7ErrorCode.CLINOPASSWORDTOSETORCLEAR]   = "CPU : No password to set or clear",
                [S7ErrorCode.CLIJOBTIMEOUT]               = "CLI : Job Timeout",
                [S7ErrorCode.CLIFUNCTIONREFUSED]          = "CLI : function refused by CPU (Unknown error)",
                [S7ErrorCode.CLIPARTIALDATAREAD]          = "CLI : Partial data read",
                [S7ErrorCode.CLIBUFFERTOOSMALL]           = "CLI : The buffer supplied is too small to accomplish the operation",
                [S7ErrorCode.CLIDESTROYING]               = "CLI : Cannot perform (destroying)",
                [S7ErrorCode.CLIINVALIDPARAMNUMBER]       = "CLI : Invalid Param Number",
                [S7ErrorCode.CLICANNOTCHANGEPARAM]        = "CLI : Cannot change this param now",
                [S7ErrorCode.CLIFUNCTIONNOTIMPLEMENTED]   = "CLI : Function not implemented",
            }

            CPU_ERROR_MAP           = {
                [0]                         = 0,
                [Code7AddressOutOfRange]    = S7ErrorCode.CLIADDRESSOUTOFRANGE,
                [Code7InvalidTransportSize] = S7ErrorCode.CLIINVALIDTRANSPORTSIZE,
                [Code7WriteDataSizeMismatch]= S7ErrorCode.CLIWRITEDATASIZEMISMATCH,
                [Code7ResItemNotAvailable]  = S7ErrorCode.CLIITEMNOTAVAILABLE,
                [Code7ResItemNotAvailable1] = S7ErrorCode.CLIITEMNOTAVAILABLE,
                [Code7DataOverPDU]          = S7ErrorCode.CLISIZEOVERPDU,
                [Code7InvalidValue]         = S7ErrorCode.CLIINVALIDVALUE,
                [Code7FunNotAvailable]      = S7ErrorCode.CLIFUNNOTAVAILABLE,
                [Code7NeedPassword]         = S7ErrorCode.CLINEEDPASSWORD,
                [Code7InvalidPassword]      = S7ErrorCode.CLIINVALIDPASSWORD,
                [Code7NoPasswordToSet]      = S7ErrorCode.CLINOPASSWORDTOSETORCLEAR,
                [Code7NoPasswordToClear]    = S7ErrorCode.CLINOPASSWORDTOSETORCLEAR,
            }

            local function cloneArray(tbl)
                return { [0] = tbl[0], unpack(tbl) }
            end

            local function trimZero(str)
                if not str then return "" end

                local s, e          = 1, #str

                while strbyte(str, s) == 0 do s = s + 1 end
                while strbyte(str, e) == 0 do e = e - 1 end

                return str:sub(s, e)
            end

            local function throwException(code)
                throw(S7Exception(ERROR_MSG_MAP[code] or ("CLI : Unknown error (0x%x)"):format(code), code))
            end

            local function SiemensTimestamp(EncodedDate)
                return Date(1984, 1, 1, 0, 0, 0):AddSeconds(EncodedDate * 86400):ToString()
            end

            local function arrayCopy(src, pos, target, tpos, size)
                for i = 0, size - 1 do
                    target[tpos + i] = src[pos + i]
                end
            end

            local function RecvIsoPacket(self)
                local done          = false
                local size          = 0
                local PDU           = self.PDU

                -- Need check receive time out
                while (self._LastError == 0 or self._LastError == S7ErrorCode.TCPRECEIVETIMEOUT) and not done do
                    -- Get TPKT (4 bytes)
                    self:RecvPacket(PDU, 0, 4)

                    if (self._LastError == 0) then
                        size        = GetWordAt(PDU, 2)
                        -- Check 0 bytes Data Packet (only TPKT+COTP = 7 bytes)
                        if (size == IsoHSize) then
                            self:RecvPacket(PDU, 4, 3) -- Skip remaining 3 bytes and done is still false
                        else
                            if ((size > self._PduSizeRequested + IsoHSize) or (size < MinPduSize)) then
                                self._LastError = S7ErrorCode.ISOINVALIDPDU
                            else
                                done = true -- a valid Length !=7 && >16 && <247
                            end
                        end
                    end
                end

                if (self._LastError == 0) then
                    self:RecvPacket(PDU, 4, 3) -- Skip remaining 3 COTP bytes
                    self.LastPDUType = PDU[5]   -- Stores PDU Type, we need it

                    -- Receives the S7 Payload
                    self:RecvPacket(PDU, 7, size - IsoHSize)
                end

                return self._LastError == 0 and size or 0
            end

            local function ISOConnect(self)
                self.ISO_CR[16]     = self.LocalTSAP_HI
                self.ISO_CR[17]     = self.LocalTSAP_LO
                self.ISO_CR[20]     = self.RemoteTSAP_HI
                self.ISO_CR[21]     = self.RemoteTSAP_LO

                -- Sends the connection request telegram
                self:SendPacket(self.ISO_CR)

                if (self._LastError == 0) then
                    -- Gets the reply (if any)
                    local size      = RecvIsoPacket(self)

                    if (self._LastError == 0) then
                        if (size == 22) then
                            if (self.LastPDUType ~= 0xD0) then -- 0xD0 = CC Connection confirm
                                self._LastError = S7ErrorCode.ISOCONNECT
                            end
                        else
                            self._LastError = S7ErrorCode.ISOINVALIDPDU
                        end
                    end
                end
                return self._LastError
            end

            local function NegotiatePduLength(self)
                local length
                local PDU           = self.PDU

                -- Set PDU Size Requested
                SetWordAt(self.S7_PN, 23, self._PduSizeRequested)

                -- Sends the connection request telegram
                self:SendPacket(self.S7_PN)

                if (self._LastError == 0) then
                    length          = RecvIsoPacket(self)
                    if (self._LastError == 0) then
                        -- check S7 Error
                        if ((length == 27) and (PDU[17] == 0) and (PDU[18] == 0)) then  -- 20 = size of Negotiate Answer
                            -- Get PDU Size Negotiated
                            self._PDULength     = GetWordAt(PDU, 25)
                            if (self._PDULength <= 0) then
                                self._LastError = S7ErrorCode.CLINEGOTIATINGPDU
                            end
                        else
                            self._LastError = S7ErrorCode.CLINEGOTIATINGPDU
                        end
                    end
                end
                return self._LastError
            end

            local function CpuError(error)
                return CPU_ERROR_MAP[error] or S7ErrorCode.CLIFUNCTIONREFUSED
            end

            local function GetNextWord(self)
                self.cntword    = self.cntword + 1
                return self.cntword
            end

            -----------------------------------------------------------------------
            --                          static property                          --
            -----------------------------------------------------------------------
            --- Max number of vars (multiread/write)
            __Static__() property "MaxVars" { set = false, default = 20 }

            -----------------------------------------------------------------------
            --                           field setting                           --
            -----------------------------------------------------------------------
            field {
                _PDULength          = 0,
                _PduSizeRequested   = 480,
                _LastError          = 0,

                LocalTSAP_HI        = 0,
                LocalTSAP_LO        = 0,
                RemoteTSAP_HI       = 0,
                RemoteTSAP_LO       = 0,
                LastPDUType         = 0,
                cntword             = 0,
                Time_ms             = 0,
                PDU                 = {},
            }

            -----------------------------------------------------------------------
            --                             property                              --
            -----------------------------------------------------------------------
            --- The server address to be connected
            property "Address"              { type = String, default = "127.0.0.1" }

            --- All MODBUS/TCP ADU are sent via TCP to registered port 502
            property "Port"                 { type = NaturalNumber, default = ISOTCP }

            --- The socket object
            property "Socket"               { type = ISocket, default = SocketType and function(self) return SocketType() end }

            --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out
            property "ReceiveTimeout"       { type = Number, default = DefaultTimeout, handler = function(self, timeout) if self.Socket then self.Socket.ReceiveTimeout = timeout end end }

            --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out
            property "SendTimeout"          { type = Number, default = DefaultTimeout, handler = function(self, timeout) if self.Socket then self.Socket.SendTimeout = timeout end end }

            --- Gets or sets a value that specifies the amount of time after which a synchronous Connect call will time out
            property "ConnectTimeout"       { type = Number, default = DefaultTimeout, handler = function(self, timeout) if self.Socket then self.Socket.ConnectTimeout = timeout end end }

            --- Gets the requested PDU length
            property "PduSizeRequested"     { set = false, field = "_PduSizeRequested", handler = function(self, val) if val < MinPduSizeToRequest then self.PduSizeRequested = MinPduSizeToRequest elseif val > MaxPduSizeToRequest then self.PduSizeRequested = MaxPduSizeToRequest end end }

            --- Gets the Negotiated PDU Length
            property "PduSizeNegotiated"    { set = false, field = "_PDULength" }

            --- The connection type
            property "ConnectionType"       { type = UInt16, default = S7ConnectionType.BASIC }

            --- The last error code
            property "LastError"            { set = false, field = "_LastError" }


            -----------------------------------------------------------------------
            --                           common method                           --
            -----------------------------------------------------------------------
            --- Open the message publisher on the server side client, do nothing for the client side
            function Open(self)
                -- self:Connect()

                -- if self._LastError ~= 0 then
                --     throwException(self._LastError)
                -- end
            end

            --- Close the message publisher on the server side client and close the socket
            function Close(self)
                return self.Socket.Connected and self.Socket:Close()
            end

            --- Try receive and save the packet into the buffer
            function RecvPacket(self, buffer, pos, size)
                local ok, err       = pcall(self.Socket.Receive, self.Socket, size)
                if ok then
                    for i = 1, size do
                        buffer[pos + i - 1] = strbyte(err, i)
                    end
                    Trace("[RecvPacket]%s", buffer)
                    self._LastError = 0
                elseif isObjectType(err, TimeoutException) then
                    self._LastError = S7ErrorCode.TCPRECEIVETIMEOUT
                else
                    self._LastError = S7ErrorCode.TCPDATARECEIVE
                end
            end

            --- Try Send the packet
            function SendPacket(self, str, len)
                if type(str) == "table" then
                    Trace("[SendPacket]%s", str)

                    if str[0] then
                        str         = strchar(unpack(str, 0, len and (len - 1) or nil))
                    else
                        str         = strchar(unpack(str, 1, len))
                    end
                elseif len then
                    str             = str:sub(1, len)
                end

                local ok, err       = pcall(self.Socket.Send, self.Socket, str)
                if ok then
                    self._LastError = 0
                elseif isObjectType(err, TimeoutException) then
                    self._LastError = S7ErrorCode.TCPSENDTIMEOUT
                else
                    self._LastError = S7ErrorCode.TCPDATASEND
                end
            end

            --- Start the connection
            function Connect(self)
                -- Init the socket with timeout
                self.Socket.ConnectTimeout  = self.ConnectTimeout
                self.Socket.ReceiveTimeout  = self.ReceiveTimeout
                self.Socket.SendTimeout     = self.SendTimeout

                self.Socket:Connect(self.Address, self.Port)

                ISOConnect(self)

                if self._LastError == 0 then
                    NegotiatePduLength(self)
                end

                if self._LastError ~= 0 then
                    -- Close the connection
                    self.Socket:Close()
                    throwException(self._LastError)
                end
            end

            __Arguments__{ String, NaturalNumber, NaturalNumber }
            function ConnectTo(self, address, rack, slot)
                local remoteTSAP    = band( lshift(self.ConnectionType, 8) + (rack * 0x20) + slot, 0xFFFF)
                self:SetConnectionParams(address, 0x0100, remoteTSAP)
                return self:Connect()
            end

            __Arguments__{ String, UInt16, UInt16 }
            function SetConnectionParams(self, address, localTSAP, remoteTSAP)
                self.Address        = address

                self.LocalTSAP_HI   = rshift(localTSAP, 8)
                self.LocalTSAP_LO   = band(localTSAP, 0xFF)
                self.RemoteTSAP_HI  = rshift(remoteTSAP, 8)
                self.RemoteTSAP_LO  = band(remoteTSAP, 0xFF)
            end

            __Arguments__{ UInt16 }
            function SetConnectionType(self, connectionType)
                self.ConnectionType = connectionType
            end

            -----------------------------------------------------------------------
            --                      Data I/O main functions                      --
            -----------------------------------------------------------------------
            __Arguments__{ Integer, Integer, Integer, Integer, Integer }
            function ReadArea(self, Area, DBNumber, Start, Amount, WordLen)
                local Address, NumElements, MaxElements, TotElements, SizeRequested, Length
                local Offset        = 1 -- Start with offset 1
                local WordSize      = 1
                local Buffer        = {}
                local PDU           = self.PDU

                self._LastError     = 0

                -- Some adjustment
                if (Area == S7Area.CT) then
                    WordLen         = S7WordLength.COUNTER
                elseif (Area == S7Area.TM) then
                    WordLen         = S7WordLength.TIMER
                end

                -- Calc Word size
                WordSize            = DataSizeByte(WordLen)
                if (WordSize == 0) then
                    self._LastError = S7ErrorCode.CLIINVALIDWORDLEN
                    return
                end

                if (WordLen == S7WordLength.BIT) then
                    Amount          = 1  -- Only 1 bit can be transferred at time
                elseif ((WordLen ~= S7WordLength.COUNTER) and (WordLen ~= S7WordLength.TIMER)) then
                    Amount          = Amount * WordSize
                    WordSize        = 1
                    WordLen         = S7WordLength.BYTE
                end

                MaxElements         = floor((self._PDULength - 18) / WordSize) -- 18 = Reply telegram header
                TotElements         = Amount

                while ((TotElements > 0) and (self._LastError == 0)) do
                    NumElements     = TotElements
                    if (NumElements > MaxElements) then
                        NumElements = MaxElements
                    end

                    SizeRequested   = NumElements * WordSize

                    -- Setup the telegram
                    arrayCopy(INIT_TABLES.S7_RW, 0, PDU, 0, Size_RD)

                    -- Set DB Number
                    PDU[27]         = band(Area, 0xFF)

                    -- Set Area
                    if (Area == S7Area.DB) then
                        SetWordAt(PDU, 25, DBNumber)
                    end

                    -- Adjusts Start and word length
                    if ((WordLen == S7WordLength.BIT) or (WordLen == S7WordLength.COUNTER) or (WordLen == S7WordLength.TIMER)) then
                        Address     = Start
                        PDU[22]     = WordLen
                    else
                        Address     = lshift(Start, 3)
                    end

                    -- Num elements
                    SetWordAt(PDU, 23, NumElements)

                    -- Address into the PLC (only 3 bytes)
                    PDU[30]         = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    PDU[29]         = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    PDU[28]         = band(Address, 0x0FF)

                    self:SendPacket(PDU, Size_RD)

                    if (self._LastError == 0) then
                        Length      = RecvIsoPacket(self)

                        if (self._LastError == 0) then
                            if (Length < 25) then
                                self._LastError = S7ErrorCode.ISOINVALIDDATASIZE
                            else
                                if (PDU[21] ~= 0xFF) then
                                    self._LastError = CpuError(PDU[21])
                                else
                                    arrayCopy(PDU, 25, Buffer, Offset, SizeRequested)
                                    Offset = Offset + SizeRequested
                                end
                            end
                        end
                    end
                    TotElements     = TotElements - NumElements
                    Start           = Start + NumElements * WordSize
                end

                return self._LastError == 0 and Buffer or nil
            end

            __Arguments__{ Integer, Integer, Integer, Integer, Integer, Table }
            function WriteArea(self, Area, DBNumber, Start, Amount, WordLen, Buffer)
                local Address, NumElements, MaxElements, TotElements, DataSize, IsoSize, Length
                local Offset        = Buffer[0] and 0 or 1 -- Check the base
                local WordSize      = 1
                local PDU           = self.PDU

                self._LastError     = 0

                -- Some adjustment
                if (Area == S7Area.CT) then
                    WordLen         = S7WordLength.COUNTER
                elseif (Area == S7Area.TM) then
                    WordLen         = S7WordLength.TIMER
                end

                -- Calc Word size
                WordSize            = DataSizeByte(WordLen)
                if (WordSize == 0) then
                    self._LastError = S7ErrorCode.CLIINVALIDWORDLEN
                    return 0
                end

                if (WordLen == S7WordLength.BIT) then -- Only 1 bit can be transferred at time
                    Amount          = 1
                elseif ((WordLen ~= S7WordLength.COUNTER) and (WordLen ~= S7WordLength.TIMER)) then
                    Amount          = Amount * WordSize
                    WordSize        = 1
                    WordLen         = S7WordLength.BYTE
                end

                MaxElements         = floor((self._PDULength - 35) / WordSize) -- 35 = Reply telegram header
                TotElements         = Amount

                while ((TotElements > 0) and (self._LastError == 0)) do
                    NumElements     = TotElements
                    if (NumElements > MaxElements) then
                        NumElements = MaxElements
                    end

                    DataSize        = NumElements * WordSize
                    IsoSize         = Size_WR + DataSize

                    -- Setup the telegram
                    arrayCopy(INIT_TABLES.S7_RW, 0, PDU, 0, Size_WR)

                    -- Whole telegram Size
                    SetWordAt(PDU, 2, IsoSize)

                    -- Data Length
                    Length          = DataSize + 4
                    SetWordAt(PDU, 15, Length)

                    -- Function
                    PDU[17]         = 0x05

                    -- Set DB Number
                    PDU[27]         = band(Area, 0xFF)

                    if (Area == S7Area.DB) then
                        SetWordAt(PDU, 25, DBNumber)
                    end

                    -- Adjusts Start and word length
                    if ((WordLen == S7WordLength.BIT) or (WordLen == S7WordLength.COUNTER) or (WordLen == S7WordLength.TIMER)) then
                        Address     = Start
                        Length      = DataSize
                        PDU[22]     = band(WordLen, 0xFF)
                    else
                        Address     = lshift(Start, 3)
                        Length      = lshift(DataSize, 3)
                    end

                    -- Num elements
                    SetWordAt(PDU, 23, NumElements)

                    -- Address into the PLC
                    PDU[30]         = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    PDU[29]         = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    PDU[28]         = band(Address, 0x0FF)

                    -- Transport Size
                    if WordLen == S7WordLength.BIT then
                        PDU[32]     = TS_ResBit
                    elseif WordLen == S7WordLength.COUNTER or WordLen == S7WordLength.TIMER then
                        PDU[32]     = TS_ResOctet
                    else
                        PDU[32]     = TS_ResByte -- byte/word/dword etc.
                    end

                    -- Length
                    SetWordAt(PDU, 33, Length)

                    -- Copies the Data
                    arrayCopy(Buffer, Offset, PDU, 35, DataSize)

                    self:SendPacket(PDU, IsoSize)

                    if (self._LastError == 0) then
                        Length      = RecvIsoPacket(self)

                        if (self._LastError == 0) then
                            if (Length == 22) then
                                if (PDU[21] ~= 0xFF) then
                                    self._LastError = CpuError(PDU[21])
                                end
                            else
                                self._LastError = S7ErrorCode.ISOINVALIDPDU
                            end
                        end
                    end
                    Offset          = Offset + DataSize
                    TotElements     = TotElements - NumElements
                    Start           = Start + NumElements * WordSize
                end

                return self._LastError == 0 and Offset or 0
            end

            __Arguments__{ struct { S7DataItem }, Integer/nil }
            function ReadMultiVars(self, Items, ItemsCount)
                local Offset, Length, ItemSize

                local S7ItemLength  = 12
                local S7Item        = {}
                local S7ItemRead    = {}
                local PDU           = self.PDU

                ItemsCount          = ItemsCount or (#Items + Items[0] and 1 or 0)

                self._LastError     = 0

                -- Checks items
                if (ItemsCount > self.MaxVars) then
                    self._LastError = S7ErrorCode.CLITOOMANYITEMS
                    return self._LastError
                end

                -- Fills Header
                arrayCopy(INIT_TABLES.S7_MRD_HEADER, 0, PDU, 0, #INIT_TABLES.S7_MRD_HEADER + 1)
                SetWordAt(PDU, 13, (ItemsCount * S7ItemLength + 2))
                PDU[18]             = band(ItemsCount, 0xFF)

                -- Fills the Items
                Offset              = 19
                for c = Items[0] and 0 or 1, ItemsCount - (Items[0] and 1 or 0) do
                    arrayCopy(INIT_TABLES.S7_MRD_ITEM, 0, S7Item, 0, S7ItemLength)

                    S7Item[3]       = band(Items[c].WordLen, 0xFF)

                    SetWordAt(S7Item, 4, Items[c].Amount)

                    if (Items[c].Area == S7Area.DB) then
                        SetWordAt(S7Item, 6, Items[c].DBNumber)
                    end

                    S7Item[8]       = band(Items[c].Area, 0xFF)

                    -- Address into the PLC
                    local Address   = Items[c].Start
                    S7Item[11]      = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    S7Item[10]      = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    S7Item[09]      = band(Address, 0x0FF)

                    arrayCopy(S7Item, 0, PDU, Offset, S7ItemLength)
                    Offset          = Offset + S7ItemLength
                end

                if (Offset > self._PDULength) then
                    self._LastError = S7ErrorCode.CLISIZEOVERPDU
                    return self._LastError
                end

                SetWordAt(PDU, 2, Offset) -- Whole size
                self:SendPacket(PDU, Offset)

                if (self._LastError ~= 0) then
                    return self._LastError
                end

                -- Get Answer
                Length              = RecvIsoPacket(self)
                if (self._LastError ~= 0) then
                    return self._LastError
                end

                -- Check ISO Length
                if (Length < 22) then
                    self._LastError = S7ErrorCode.ISOINVALIDPDU -- PDU too Small
                    return self._LastError
                end

                -- Check Global Operation Result
                self._LastError     = CpuError(GetWordAt(PDU, 17))
                if (self._LastError ~= 0) then
                    return self._LastError
                end

                -- Get true ItemsCount
                local ItemsRead     = GetByteAt(PDU, 20)
                if ((ItemsRead ~= ItemsCount) or (ItemsRead > self.MaxVars)) then
                    self._LastError = S7ErrorCode.CLIINVALIDPLCANSWER
                    return self._LastError
                end

                -- Get Data
                Offset              = 21
                for c = Items[0] and 0 or 1, ItemsCount - (Items[0] and 1 or 0) do
                    -- Get the Item
                    arrayCopy(PDU, Offset, S7ItemRead, 0, Length - Offset)

                    if (S7ItemRead[0] == 0xff) then
                        ItemSize    = GetWordAt(S7ItemRead, 2)

                        if ((S7ItemRead[1] ~= TS_ResOctet) and (S7ItemRead[1] ~= TS_ResReal) and (S7ItemRead[1] ~= TS_ResBit)) then
                            ItemSize= rshift(ItemSize, 3)
                        end

                        Items[c].pData = Items[c].pData or {}
                        arrayCopy(S7ItemRead, 4, Items[c].pData, 1, ItemSize) -- Use 1 as base for the pData

                        Items[c].Result = 0
                        if (ItemSize % 2 ~= 0) then
                            ItemSize= ItemSize + 1 -- Odd size are rounded
                        end
                        Offset      = Offset + 4 + ItemSize
                    else
                        Items[c].Result = CpuError(S7ItemRead[0])
                        Offset      = Offset + 4 -- Skip the Item header
                    end
                end

                return self._LastError
            end

            __Arguments__{ struct { S7DataItem }, Integer/nil }
            function WriteMultiVars(self, Items, ItemsCount)
                local Offset, ParLength, DataLength, ItemDataSize

                local S7ParamLength = #INIT_TABLES.S7_MWR_PARAM + 1
                local S7HeadLength  = #INIT_TABLES.S7_MWR_HEADER + 1

                local S7ParItem     = {}
                local S7DataItem    = {}
                local PDU           = self.PDU

                ItemsCount          = ItemsCount or (#Items + (Items[0] and 1 or 0))

                self._LastError     = 0

                -- Checks items
                if (ItemsCount > self.MaxVars) then
                    self._LastError = S7ErrorCode.CLITOOMANYITEMS
                    return self._LastError
                end

                -- Fills Header
                arrayCopy(INIT_TABLES.S7_MWR_HEADER, 0, PDU, 0, S7HeadLength)
                ParLength           = ItemsCount * S7ParamLength + 2
                SetWordAt(PDU, 13, ParLength)
                PDU[18]             = band(ItemsCount, 0xFF)

                -- Fills Params
                Offset              = S7HeadLength
                for c = Items[0] and 0 or 1, ItemsCount - (Items[0] and 1 or 0) do
                    arrayCopy(INIT_TABLES.S7_MWR_PARAM, 0, S7ParItem, 0, S7ParamLength)
                    S7ParItem[3]    = band(Items[c].WordLen, 0xFF)
                    S7ParItem[8]    = band(Items[c].Area, 0xFF)
                    SetWordAt(S7ParItem, 4, Items[c].Amount)
                    SetWordAt(S7ParItem, 6, Items[c].DBNumber)

                    -- Address into the PLC
                    local Address   = Items[c].Start
                    S7ParItem[11]   = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    S7ParItem[10]   = band(Address, 0x0FF)
                    Address         = rshift(Address, 8)
                    S7ParItem[09]   = band(Address, 0x0FF)

                    arrayCopy(S7ParItem, 0, PDU, Offset, S7ParamLength)
                    Offset          = Offset + S7ParamLength
                end

                -- Fills Data
                DataLength          = 0
                for c = Items[0] and 0 or 1, ItemsCount - (Items[0] and 1 or 0) do
                    S7DataItem[0]   = 0x00

                    if Items[c].WordLen == S7WordLength.BIT then
                        S7DataItem[1] = TS_ResBit
                    elseif Items[c].WordLen == S7WordLength.COUNTER or Items[c].WordLen == S7WordLength.TIMER then
                        S7DataItem[1] = TS_ResOctet
                    else
                        S7DataItem[1] = TS_ResByte -- byte/word/dword etc.
                    end

                    if ((Items[c].WordLen == S7WordLength.TIMER) or (Items[c].WordLen == S7WordLength.COUNTER)) then
                        ItemDataSize = Items[c].Amount * 2
                    else
                        ItemDataSize = Items[c].Amount
                    end

                    if ((S7DataItem[1] ~= TS_ResOctet) and (S7DataItem[1] ~= TS_ResBit)) then
                        SetWordAt(S7DataItem, 2, (ItemDataSize * 8))
                    else
                        SetWordAt(S7DataItem, 2, ItemDataSize)
                    end

                    arrayCopy(Items[c].pData, Items[c].pData[0] and 0 or 1, S7DataItem, 4, ItemDataSize)

                    if (ItemDataSize % 2 ~= 0) then
                        S7DataItem[ItemDataSize + 4] = 0x00
                        ItemDataSize    = ItemDataSize + 1
                    end

                    arrayCopy(S7DataItem, 0, PDU, Offset, ItemDataSize + 4)
                    Offset              = Offset + ItemDataSize + 4
                    DataLength          = DataLength + ItemDataSize + 4
                end

                -- Checks the size
                if (Offset > _PDULength) then
                    self._LastError     = S7ErrorCode.CLISIZEOVERPDU
                    return self._LastError
                end

                SetWordAt(PDU, 2, Offset) -- Whole size
                SetWordAt(PDU, 15, DataLength) -- Whole size
                self:SendPacket(PDU, Offset)

                RecvIsoPacket(self)

                if (self._LastError == 0) then
                    -- Check Global Operation Result
                    self._LastError     = CpuError(GetWordAt(PDU, 17))
                    if (self._LastError ~= 0) then
                        return self._LastError
                    end

                    -- Get true ItemsCount
                    local ItemsWritten = GetByteAt(PDU, 20)
                    if ((ItemsWritten ~= ItemsCount) or (ItemsWritten > self.MaxVars)) then
                        self._LastError = S7ErrorCode.CLIINVALIDPLCANSWER
                        return self._LastError
                    end

                    for c = Items[0] and 0 or 1, ItemsCount - (Items[0] and 1 or 0) do
                        if (PDU[c + 21] == 0xFF) then
                            Items[c].Result = 0
                        else
                            Items[c].Result = CpuError(PDU[c + 21])
                        end
                    end
                end

                return self._LastError
            end

            -----------------------------------------------------------------------
            --                      Data I/O lean functions                      --
            -----------------------------------------------------------------------
            __Arguments__{ Integer, Integer, Integer }
            function DBRead(self, DBNumber, Start, Size)
                return self:ReadArea(S7Area.DB, DBNumber, Start, Size, S7WordLength.BYTE)
            end

            __Arguments__{ Integer, Integer }
            function MBRead(self, Start, Size)
                return self:ReadArea(S7Area.MK, 0, Start, Size, S7WordLength.BYTE)
            end

            __Arguments__{ Integer, Integer }
            function EBRead(self, Start, Size)
                return self:ReadArea(S7Area.PE, 0, Start, Size, S7WordLength.BYTE)
            end

            __Arguments__{ Integer, Integer }
            function ABRead(self, Start, Size)
                return self:ReadArea(S7Area.PA, 0, Start, Size, S7WordLength.BYTE)
            end

            __Arguments__{ Integer, Integer, Integer, Table }
            function DBWrite(self, DBNumber, Start, Size, Buffer)
                return self:WriteArea(S7Area.DB, DBNumber, Start, Size, S7WordLength.BYTE, Buffer)
            end

            __Arguments__{ Integer, Integer, Table }
            function MBWrite(self, Start, Size, Buffer)
                return self:WriteArea(S7Area.MK, 0, Start, Size, S7WordLength.BYTE, Buffer)
            end

            __Arguments__{ Integer, Integer, Table }
            function EBWrite(self, Start, Size, Buffer)
                return self:WriteArea(S7Area.PE, 0, Start, Size, S7WordLength.BYTE, Buffer)
            end

            __Arguments__{ Integer, Integer, Table }
            function ABWrite(self, Start, Size, Buffer)
                return self:WriteArea(S7Area.PA, 0, Start, Size, S7WordLength.BYTE, Buffer)
            end

            __Arguments__{ Integer, Integer }
            function TMRead(self, Start, Amount)
                local sBuffer       = self:ReadArea(S7Consts.S7AreaTM, 0, Start, Amount, S7WordLength.TIMER)
                if (self._LastError == 0) then
                    local Buffer    = {}
                    for c = 1, Amount do
                        Buffer[c]   = lshift(sBuffer[c * 2], 8) + sBuffer[c * 2 - 1]
                    end
                    return Buffer
                end
            end

            __Arguments__{ Integer, Integer, Table } -- ushort[]
            function TMWrite(self, Start, Amount, Buffer)
                local sBuffer       = {}
                local base          = buffer[0] and 0 or 1

                for c = 0, Amount - 1 do
                    local val       = Buffer[base]
                    sBuffer[c*2 + 1]= val and rshift(val, 8) or 0
                    sBuffer[c*2]    = val and band(val, 0xFF) or 0

                    base            = base + 1
                end

                return self:WriteArea(S7Consts.S7AreaTM, 0, Start, Amount, S7WordLength.TIMER, sBuffer)
            end

            __Arguments__{ Integer, Integer }
            function CTRead(self, Start, Amount)
                local sBuffer       = ReadArea(S7Consts.S7AreaCT, 0, Start, Amount, S7WordLength.COUNTER, sBuffer)
                if (self._LastError == 0) then
                    local Buffer    = {}
                    for c = 1, Amount do
                        Buffer[c]   = lshift(sBuffer[c * 2], 8) + sBuffer[c * 2 - 1]
                    end
                    return Buffer
                end
            end

            __Arguments__{ Integer, Integer, Table } -- ushort[]
            function CTWrite(self, Start, Amount, Buffer)
                local sBuffer       = {}
                local base          = buffer[0] and 0 or 1

                for c = 0, Amount - 1 do
                    local val       = Buffer[base]
                    sBuffer[c*2 + 1]= val and rshift(val, 8) or 0
                    sBuffer[c*2]    = val and band(val, 0xFF) or 0

                    base            = base + 1
                end

                return self:WriteArea(S7Consts.S7AreaCT, 0, Start, Amount, S7WordLength.COUNTER, sBuffer)
            end

            -----------------------------------------------------------------------
            --                        Directory functions                        --
            -----------------------------------------------------------------------
            function ListBlocks(self)
                local List          = S7BlocksList()

                local Sequence      = GetNextWord(self)
                local lenListBlocks = #INIT_TABLES.S7_LIST_BLOCKS + 1
                local PDU           = self.PDU
                self._LastError     = 0

                arrCopy(INIT_TABLES.S7_LIST_BLOCKS, 0, PDU, 0, lenListBlocks)
                PDU[0x0b]           = band(Sequence, 0xff)
                PDU[0x0c]           = rshift(Sequence, 8)

                self:SendPacket(PDU, lenListBlocks)

                if (self._LastError ~= 0) then return self._LastError end

                local Length        = RecvIsoPacket(self)

                if (Length <= 32) then-- the minimum expected
                    self._LastError = S7ErrorCode.ISOINVALIDPDU
                    return
                end

                local Result        = GetWordAt(PDU, 27)
                if (Result ~= 0) then
                    self._LastError = CpuError(Result)
                    return
                end

                local BlocksSize    = GetWordAt(PDU, 31)

                if (Length <= 32 + BlocksSize) then
                    self._LastError = S7ErrorCode.ISOINVALIDPDU
                    return
                end

                local BlocksCount   = rshift(BlocksSize, 2)
                for blockNum = 0, BlocksCount - 1 do
                    local Count     = GetWordAt(PDU, lshift(blockNum, 2) + 35)
                    local val       = GetByteAt(PDU, lshift(blockNum, 2) + 34) --BlockType

                    if val == S7Block.OB then
                        List.OBCount = Count
                    elseif val == S7Block.DB then
                        List.DBCount = Count
                    elseif val == S7Block.SDB then
                        List.SDBCount = Count
                    elseif val == S7Block.FC then
                        List.FCCount = Count
                    elseif val == S7Block.SFC then
                        List.SFCCount = Count
                    elseif val == S7Block.FB then
                        List.FBCount = Count
                    elseif val == S7Block.SFB then
                        List.SFBCount = Count
                    end
                end

                return List
            end

            __Arguments__{ Integer, Integer }
            function GetAgBlockInfo(self, BlockType, BlockNum)
                local Info          = S7BlockInfo()
                local PDU           = self.PDU

                self._LastError     = 0

                self.S7_BI[30]      = band(BlockType, 0xFF)
                -- Block Number
                self.S7_BI[31]      = band((floor(BlockNum / 10000) + 0x30), 0xFF)
                BlockNum            = BlockNum % 10000
                self.S7_BI[32]      = band((floor(BlockNum / 1000) + 0x30), 0xFF)
                BlockNum            = BlockNum % 1000
                self.S7_BI[33]      = band((floor(BlockNum / 100) + 0x30), 0xFF)
                BlockNum            = BlockNum % 100
                self.S7_BI[34]      = band((floor(BlockNum / 10) + 0x30), 0xFF)
                BlockNum            = BlockNum % 10
                self.S7_BI[35]      = band((floor(BlockNum / 1) + 0x30), 0xFF)

                self:SendPacket(self.S7_BI)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (Length > 32) then -- the minimum expected
                        local Result= GetWordAt(PDU, 27)

                        if (Result == 0) then
                            Info.BlkFlags   = PDU[42]
                            Info.BlkLang    = PDU[43]
                            Info.BlkType    = PDU[44]
                            Info.BlkNumber  = GetWordAt(PDU, 45)
                            Info.LoadSize   = GetDIntAt(PDU, 47)
                            Info.CodeDate   = SiemensTimestamp(GetWordAt(PDU, 59))
                            Info.IntfDate   = SiemensTimestamp(GetWordAt(PDU, 65))
                            Info.SBBLength  = GetWordAt(PDU, 67)
                            Info.LocalData  = GetWordAt(PDU, 71)
                            Info.MC7Size    = GetWordAt(PDU, 73)
                            Info.Author     = trimZero(GetCharsAt(PDU, 75, 8))
                            Info.Family     = trimZero(GetCharsAt(PDU, 83, 8))
                            Info.Header     = trimZero(GetCharsAt(PDU, 91, 8))
                            Info.Version    = PDU[99]
                            Info.CheckSum   = GetWordAt(PDU, 101)
                        else
                            self._LastError = CpuError(Result)
                        end
                    else
                        self._LastError     = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return Info
            end

            __Arguments__{ Integer, Integer/nil }
            function ListBlocksOfType(self, BlockType, ItemsCount)
                local First         = true
                local Done          = false
                local In_Seq        = 0
                local Count         = 0 --Block 1...n
                local PduLength
                local List          = {}
                local lenBlockOfType= #INIT_TABLES.S7_LIST_BLOCKS_OF_TYPE + 1
                local PDU           = self.PDU

                --Consequent packets have a different ReqData
                local ReqData       = { [0] = 0xff, 0x09, 0x00, 0x02, 0x30, band(BlockType, 0xFF) }
                local ReqDataContinue = { [0] = 0x00, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00 }

                self._LastError     = 0

                repeat
                    PduLength       = lenBlockOfType + (#ReqData + 1)
                    local Sequence  = GetNextWord(self)

                    arrCopy(INIT_TABLES.S7_LIST_BLOCKS_OF_TYPE, 0, PDU, 0, lenBlockOfType)
                    SetWordAt(PDU, 0x02, PduLength)
                    PDU[0x0b]       = band(Sequence, 0xff)
                    PDU[0x0c]       = rshift(Sequence, 8)

                    if (not First) then
                        SetWordAt(PDU, 0x0d, 12) --ParLen
                        SetWordAt(PDU, 0x0f, 4) --DataLen
                        PDU[0x14]   = 8 --PLen
                        PDU[0x15]   = 0x12 --Uk
                    end

                    PDU[0x17]       = 0x02
                    PDU[0x18]       = In_Seq
                    arrayCopy(ReqData, 0, PDU, 0x19, #ReqData + 1)

                    self:SendPacket(PDU, PduLength)
                    if (self._LastError ~= 0) then return end

                    PduLength       = RecvIsoPacket(self)
                    if (self._LastError ~= 0) then return self._LastError end

                    if (PduLength <= 32) then-- the minimum expected
                        self._LastError = S7ErrorCode.ISOINVALIDPDU
                        return
                    end

                    local Result    = GetWordAt(PDU, 0x1b)
                    if (Result ~= 0) then
                        self._LastError = CpuError(Result)
                        return
                    end

                    if (PDU[0x1d] ~= 0xFF) then
                        self._LastError = S7ErrorCode.CLIITEMNOTAVAILABLE
                        return
                    end

                    Done            = PDU[0x1a] == 0
                    In_Seq          = PDU[0x18]

                    local CThis     = rshift(GetWordAt(PDU, 0x1f), 2) --Amount of blocks in this message

                    for c = 0, CThis - 1 do
                        if (Count >= ItemsCount) then --RoomError
                            self._LastError = S7ErrorCode.CLIPARTIALDATAREAD
                            return
                        end

                        Count       = Count + 1
                        List[Count] = GetWordAt(PDU, 0x21 + 4 * c)
                        if Count == 0x8000 then Done = true end --but why?
                    end

                    if (First) then
                        ReqData     = ReqDataContinue
                        First       = false
                    end
                until (self._LastError ~= 0 or Done)

                if (self._LastError == 0) then
                    return List, Count
                end
            end

            -----------------------------------------------------------------------
            --                         Blocks functions                          --
            -----------------------------------------------------------------------
            function DBGet(self, DBNumber)
                local BI        = self:GetAgBlockInfo(S7Block.DB, DBNumber)

                if (self._LastError == 0) then
                    local data  = self:DBRead(DBNumber, 0, BI.MC7Size)
                    if (self._LastError == 0) then
                        return data
                    end
                end
            end

            function DBFill(self, DBNumber, FillChar)
                local BI        = self:GetAgBlockInfo(S7Block.DB, DBNumber)

                if (self._LastError == 0) then
                    local Buffer= {}
                    FillChar    = band(FillChar, 0xFF)

                    for c = 0, BI.MC7Size - 1 do
                        Buffer[c] = FillChar
                    end
                    self:DBWrite(DBNumber, 0, BI.MC7Size, Buffer)
                end
            end

            -----------------------------------------------------------------------
            --                        Date/Time functions                        --
            -----------------------------------------------------------------------
            function GetPlcDateTime(self)
                local PDU           = self.PDU

                self:SendPacket(INIT_TABLES.S7_GET_DT)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (Length > 30) then -- the minimum expected
                        if ((GetWordAt(PDU, 27) == 0) and (PDU[29] == 0xFF)) then
                            return GetDateTimeAt(PDU, 35)
                        else
                            self._LastError = S7ErrorCode.CLIINVALIDPLCANSWER
                        end
                    else
                        self._LastError = S7ErrorCode.ISOINVALIDPDU
                    end
                end
            end

            __Arguments__{ Date }
            function SetPlcDateTime(self, DT)
                local PDU           = self.PDU

                self._LastError     = 0

                SetDateTimeAt(self.S7_SET_DT, 31, DT)
                self:SendPacket(self.S7_SET_DT)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (Length > 30) then -- the minimum expected
                        if (GetWordAt(PDU, 27) ~= 0) then
                            self._LastError = S7ErrorCode.CLIINVALIDPLCANSWER
                        end
                    else
                        self._LastError = S7ErrorCode.ISOINVALIDPDU
                    end
                end
            end

            function SetPlcSystemDateTime(self)
                return self:SetPlcDateTime(Date.Now)
            end

            -----------------------------------------------------------------------
            --                       System Info functions                       --
            -----------------------------------------------------------------------
            function ReadSZL(self, ID, Index)
                local SZL           = S7SZL( SZL_HEADER(), {} )
                local Length, DataSZL
                local Offset        = 1
                local Done          = false
                local First         = true
                local Seq_in        = 0x00
                local Seq_out       = 0x0000
                local PDU           = self.PDU

                self._LastError     = 0
                SZL.Header.LENTHDR  = 0

                repeat
                    if (First) then
                        Seq_out     = Seq_out + 1
                        SetWordAt(self.S7_SZL_FIRST, 11, Seq_out)
                        SetWordAt(self.S7_SZL_FIRST, 29, ID)
                        SetWordAt(self.S7_SZL_FIRST, 31, Index)
                        self:SendPacket(self.S7_SZL_FIRST)
                    else
                        Seq_out     = Seq_out + 1
                        SetWordAt(self.S7_SZL_NEXT, 11, Seq_out)
                        PDU[24]     = band(Seq_in, 0xFF)
                        self:SendPacket(self.S7_SZL_NEXT)
                    end

                    if (self._LastError ~= 0) then return end

                    Length          = RecvIsoPacket(self)
                    if (self._LastError == 0) then
                        if (First) then
                            if (Length > 32) then -- the minimum expected
                                if ((GetWordAt(PDU, 27) == 0) and (PDU[29] == 0xFF)) then
                                    -- Gets Amount of this slice
                                    DataSZL             = GetWordAt(PDU, 31) - 8 -- Skips extra params (ID, Index ...)
                                    Done                = PDU[26] == 0x00
                                    Seq_in              = PDU[24] -- Slice sequence
                                    SZL.Header.LENTHDR  = GetWordAt(PDU, 37)
                                    SZL.Header.N_DR     = GetWordAt(PDU, 39)
                                    arrayCopy(PDU, 41, SZL.Data, Offset, DataSZL)
                                    --                                SZL.Copy(PDU, 41, Offset, DataSZL)
                                    Offset              = Offset + DataSZL
                                    SZL.Header.LENTHDR  = SZL.Header.LENTHDR + SZL.Header.LENTHDR
                                else
                                    self._LastError     = S7ErrorCode.CLIINVALIDPLCANSWER
                                end
                            else
                                self._LastError         = S7ErrorCode.ISOINVALIDPDU
                            end
                        else
                            if (Length > 32) then -- the minimum expected
                                if ((GetWordAt(PDU, 27) == 0) and (PDU[29] == 0xFF)) then
                                    -- Gets Amount of this slice
                                    DataSZL             = GetWordAt(PDU, 31)
                                    Done                = PDU[26] == 0x00
                                    Seq_in              = PDU[24] -- Slice sequence
                                    arrayCopy(PDU, 37, SZL.Data, Offset, DataSZL)
                                    Offset              = Offset + DataSZL
                                    SZL.Header.LENTHDR  = SZL.Header.LENTHDR + SZL.Header.LENTHDR
                                else
                                    self._LastError     = S7ErrorCode.CLIINVALIDPLCANSWER
                                end
                            else
                                self._LastError         = S7ErrorCode.ISOINVALIDPDU
                            end
                        end
                    end
                    First           = false
                until (Done or (self._LastError ~= 0))

                return self._LastError == 0 and SZL or nil
            end

            function GetOrderCode(self)
                local Info          = S7OrderCode()
                self._LastError     = 0

                local SZL           = self:ReadSZL(0x0011, 0x000)
                if (self._LastError == 0) then
                    local Size      = SZL.Header.LENTHDR
                    local offset    = SZL.Data[0] and 0 or 1

                    Info.Code       = GetCharsAt(SZL.Data, 2 + offset, 20)
                    Info.V1         = SZL.Data[Size - 3 + offset]
                    Info.V2         = SZL.Data[Size - 2 + offset]
                    Info.V3         = SZL.Data[Size - 1 + offset]

                    return Info
                end
            end

            function GetCpuInfo(self)
                local Info          = S7CpuInfo()
                self._LastError     = 0

                local SZL           = self:ReadSZL(0x001C, 0x000)

                if (self._LastError == 0) then
                    local Size      = SZL.Header.LENTHDR
                    local offset    = SZL.Data[0] and 0 or 1

                    Info.ModuleTypeName = GetCharsAt(SZL.Data, 172 + offset, 32)
                    Info.SerialNumber   = GetCharsAt(SZL.Data, 138 + offset, 24)
                    Info.ASName         = GetCharsAt(SZL.Data, 2 + offset, 24)
                    Info.Copyright      = GetCharsAt(SZL.Data, 104 + offset, 26)
                    Info.ModuleName     = GetCharsAt(SZL.Data, 36 + offset, 24)

                    return Info
                end
            end

            function GetCpInfo(self)
                local Info          = S7CpuInfo()
                self._LastError     = 0

                local SZL           = self:ReadSZL(0x0131, 0x001)

                if (self._LastError == 0) then
                    local Size      = SZL.Header.LENTHDR
                    local offset    = SZL.Data[0] and 0 or 1
                    local PDU       = self.PDU

                    Info.MaxPduLength   = GetIntAt(PDU, 2 + base)
                    Info.MaxConnections = GetIntAt(PDU, 4 + base)
                    Info.MaxMpiRate     = GetDIntAt(PDU, 6 + base)
                    Info.MaxBusRate     = GetDIntAt(PDU, 10 + base)

                    return Info
                end
            end

            -----------------------------------------------------------------------
            --                         Control functions                         --
            -----------------------------------------------------------------------
            function PlcHotStart(self)
                local PDU           = self.PDU
                self._LastError     = 0

                self:SendPacket(INIT_TABLES.S7_HOT_START)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)

                    if (Length > 18) then -- 18 is the minimum expected
                        if (PDU[19] ~= pduStart) then
                            self._LastError     = S7ErrorCode.CLICANNOTSTARTPLC
                        else
                            if (PDU[20] == pduAlreadyStarted) then
                                self._LastError = S7ErrorCode.CLIALREADYRUN
                            else
                                self._LastError = S7ErrorCode.CLICANNOTSTARTPLC
                            end
                        end
                    else
                        self._LastError         = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return self._LastError
            end

            function PlcColdStart(self)
                local PDU           = self.PDU
                self._LastError     = 0

                self:SendPacket(INIT_TABLES.S7_COLD_START)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)

                    if (Length > 18) then -- 18 is the minimum expected
                        if (PDU[19] ~= pduStart) then
                            self._LastError     = S7ErrorCode.CLICANNOTSTARTPLC
                        else
                            if (PDU[20] == pduAlreadyStarted) then
                                self._LastError = S7ErrorCode.CLIALREADYRUN
                            else
                                self._LastError = S7ErrorCode.CLICANNOTSTARTPLC
                            end
                        end
                    else
                        self._LastError         = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return self._LastError
            end

            function PlcStop(self)
                local PDU           = self.PDU
                self._LastError     = 0

                self:SendPacket(INIT_TABLES.S7_STOP)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (Length > 18) then -- 18 is the minimum expected
                        if (PDU[19] ~= pduStop) then
                            self._LastError     = S7ErrorCode.CLICANNOTSTOPPLC
                        else
                            if (PDU[20] == pduAlreadyStopped) then
                                self._LastError = S7ErrorCode.CLIALREADYSTOP
                            else
                                self._LastError = S7ErrorCode.CLICANNOTSTOPPLC
                            end
                        end
                    else
                        self._LastError         = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return self._LastError
            end

            function PlcGetStatus(self)
                local PDU           = self.PDU
                local Status        = 0
                self._LastError     = 0

                self:SendPacket(INIT_TABLES.S7_GET_STAT)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (Length > 30) then -- the minimum expected
                        local Result= GetWordAt(PDU, 27)
                        if (Result == 0) then
                            if PDU[44] == S7PLCStatus.UNKNOWN or PDU[44] == S7PLCStatus.RUN or PDU[44] == S7PLCStatus.STOP then
                                Status = PDU[44]
                            else
                                -- Since RUN status is always 0x08 for all CPUs and CPs, STOP status
                                -- sometime can be coded as 0x03 (especially for old cpu...)
                                Status = S7PLCStatus.STOP
                            end
                        else
                            self._LastError = CpuError(Result)
                        end
                    else
                        self._LastError = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return self._LastError == 0 and Status or nil
            end

            -----------------------------------------------------------------------
            --                        Security functions                         --
            -----------------------------------------------------------------------
            function SetSessionPassword(self, Password)
                local pwd           = { [0] = 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20 }
                local PDU           = self.PDU
                local Length

                self._LastError     = 0

                -- Encodes the Password
                SetCharsAt(pwd, 0, Password)

                pwd[0]              = bxor(pwd[0], 0x55)
                pwd[1]              = bxor(pwd[1], 0x55)

                for c = 2, 7 do
                    pwd[c]          = bxor(bxor(pwd[c], 0x55), pwd[c - 2])
                end

                arrayCopy(pwd, 0, self.S7_SET_PWD, 29, 8)

                -- Sends the telegrem
                self:SendPacket(self.S7_SET_PWD)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (Length > 32) then -- the minimum expected
                        local Result= GetWordAt(PDU, 27)
                        if (Result ~= 0) then
                            self._LastError = CpuError(Result)
                        end
                    else
                        self._LastError = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return self._LastError
            end

            function ClearSessionPassword(self)
                local PDU           = self.PDU
                self._LastError     = 0

                self:SendPacket(INIT_TABLES.S7_CLR_PWD)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)

                    if (Length > 30) then -- the minimum expected
                        local Result= GetWordAt(PDU, 27)
                        if (Result ~= 0) then
                            self._LastError = CpuError(Result)
                        end
                    else
                        self._LastError = S7ErrorCode.ISOINVALIDPDU
                    end
                end

                return self._LastError
            end

            function GetProtection(self)
                local SZL           = self:ReadSZL(0x0232, 0x0004)

                if (self._LastError == 0) then
                    local Protection    = S7Protection()
                    Protection.sch_schal= GetWordAt(SZL.Data, 2)
                    Protection.sch_par  = GetWordAt(SZL.Data, 4)
                    Protection.sch_rel  = GetWordAt(SZL.Data, 6)
                    Protection.bart_sch = GetWordAt(SZL.Data, 8)
                    Protection.anl_sch  = GetWordAt(SZL.Data, 10)

                    return Protection
                end
            end

            -----------------------------------------------------------------------
            --                             Low Level                             --
            -----------------------------------------------------------------------
            function IsoExchangeBuffer(self, Buffer, Size)
                local PDU           = self.PDU
                self._LastError     = 0
                local lenTPKT       = #INIT_TABLES.TPKT_ISO + 1

                arrCopy(INIT_TABLES.TPKT_ISO, 0, PDU, 0, lenTPKT)
                SetWordAt(PDU, 2, Size + lenTPKT)

                arrCopy(Buffer, 0, PDU, lenTPKT, Size)

                self:SendPacket(PDU, lenTPKT + Size)

                if (self._LastError == 0) then
                    local Length    = RecvIsoPacket(self)
                    if (self._LastError == 0) then
                        arrayCopy(PDU, lenTPKT, Buffer, 0, Length - lenTPKT)
                        Size        = Length - lenTPKT
                    end
                end

                return self._LastError == 0 and Size or 0
            end


            -----------------------------------------------------------------------
            --                            meta-method                            --
            -----------------------------------------------------------------------
            function __index(self, key)
                if INIT_TABLES[key] then
                    local val   = cloneArray(INIT_TABLES[key])
                    rawset(self, key, val)
                    return val
                end
            end
        end)
    end)
end)