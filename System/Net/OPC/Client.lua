--===========================================================================--
--                                                                           --
--                   System.Net.Protocol.OPC.Services                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/13                                               --
-- Update Date  :   2021/08/13                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"

    export { Date, strformat = string.format }

    ---------------------------------------------------
    --                  Application                  --
    ---------------------------------------------------
    __Sealed__()
    class "Application"         (function(_ENV)

        local function getRequestHandle(self)
            local handle        = (self.__RequestHandle or 0) + 1
            self.__RequestHandle= handle
            return handle
        end

        ---------------------------------------------------
        --                   Services                    --
        ---------------------------------------------------
        --- returns the Servers known to a Server or Discovery Server
        __Arguments__{
            LocaleIds,              -- List of locales to use
            Strings/nil             -- List of servers to return
        }
        __Return__ {
            ResponseHeader,         -- Common response parameters
            ApplicationDescriptions -- List of Servers that meet criteria specified in the request
        }
        function FindServers(self, localeIds, serverUris)
            --- Common request parameters. The authenticationToken is always null
            local requestHeader = RequestHeader{
                    requestHandle = getRequestHandle(self),
                    timestamp   = Date.Now.Time,
                    AuthToken   = self.Config.AuthToken,
            }

            --- The network address that the Client used to access the DiscoveryEndpoint
            local endpointUrl   = strformat("opc.tcp://%s:%s", self.Config.Endpoint.Address, self.Config.Endpoint.Port)

            return responseHeader, servers
        end

        --- returns the Servers known to a Discovery Server, Unlike FindServers, this Service is only implemented by Discovery Servers
        __Arguments__{
            Counter/0,              -- Only records with an identifier greater than this number will be returned
            UInt32/0,               -- The maximum number of records to return in the response
            Strings/nil             -- List of Server capability filters
        }
        __Return__{
            ResponseHeader,         -- Common response parameters
            UtcTime,                -- The last time the counters were reset
            ServerOnNetworks,       -- List of DNS service records that meet criteria specified in the request
            UInt32,                 -- A unique identifier for the record
            String,                 -- The name of the Server specified in the mDNS announcement
            String,                 -- The URL of the DiscoveryEndpoint
            Strings,                -- The set of Server capabilities supported by the Server
        }
        function FindServersOnNetwork(self, startingRecordId, maxRecordsToReturn, serverCapabilityFilter)
            --- Common request parameters. The authenticationToken is always null
            local requestHeader = RequestHeader{
                    requestHandle = getRequestHandle(self),
                    timestamp   = Date.Now.Time,
                    AuthToken   = self.Config.AuthToken,
            }

            return responseHeader, lastCounterResetTime, servers, recordId, serverName, discoveryUrl, serverCapabilities
        end

        --- returns the Endpoints supported by a Server and all of the configuration information required to establish a SecureChannel and a Session
        __Arguments__{
            LocaleIds,              -- List of locales to use
            Strings/nil             -- List of Transport Profile that the returned Endpoints shall support
        }
        __Return__ {
            ResponseHeader,         -- Common response parameters
            EndpointDescriptions    -- List of Servers that meet criteria specified in the request
        }
        function GetEndpoints(self, localeIds, profileUris)
            --- Common request parameters. The authenticationToken is always null
            local requestHeader = RequestHeader{
                    requestHandle = getRequestHandle(self),
                    timestamp   = Date.Now.Time,
                    AuthToken   = self.Config.AuthToken,
            }

            --- The network address that the Client used to access the DiscoveryEndpoint
            local endpointUrl   = strformat("opc.tcp://%s:%s", self.Config.Endpoint.Address, self.Config.Endpoint.Port)

            return responseHeader, endpoints
        end

        --- registers a Server with a Discovery Server. This Service will be called by a Server or a separate configuration utility
        __Arguments__{
            RegisteredServer        -- The Server to register
        }
        __Return__{
            ResponseHeader
        }
        function RegisterServer(self, server)
            --- Common request parameters. The authenticationToken is always null
            local requestHeader = RequestHeader{
                    requestHandle = getRequestHandle(self),
                    timestamp   = Date.Now.Time,
                    AuthToken   = self.Config.AuthToken,
            }

            -- Bad_InvalidArgument
            -- Bad_ServerUriInvalid
            -- Bad_ServerNameMissing        No ServerName was specified.
            -- Bad_DiscoveryUrlMissing      No discovery URL was specified.
            -- Bad_SemaphoreFileMissing     The semaphore file specified is not valid.
            return responseHeader
        end


        ---------------------------------------------------
        --                   Property                    --
        ---------------------------------------------------
        property "Config"       { type = Any }
    end)
end)