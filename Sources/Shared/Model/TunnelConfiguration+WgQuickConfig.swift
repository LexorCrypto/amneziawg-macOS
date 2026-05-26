// SPDX-License-Identifier: MIT
// Copyright © 2018-2021 WireGuard LLC. All Rights Reserved.

import Foundation

extension TunnelConfiguration {

    enum ParserState {
        case inInterfaceSection
        case inPeerSection
        case notInASection
    }

    enum ParseError: Error {
        case invalidLine(String.SubSequence)
        case noInterface
        case multipleInterfaces
        case interfaceHasNoPrivateKey
        case interfaceHasInvalidPrivateKey(String)
        case interfaceHasInvalidListenPort(String)
        case interfaceHasInvalidAddress(String)
        case interfaceHasInvalidDNS(String)
        case interfaceHasInvalidMTU(String)
        case interfaceHasUnrecognizedKey(String)
        case interfaceHasInvalidCustomParam(String)
        case peerHasNoPublicKey
        case peerHasInvalidPublicKey(String)
        case peerHasInvalidPreSharedKey(String)
        case peerHasInvalidAllowedIP(String)
        case peerHasInvalidEndpoint(String)
        case peerHasInvalidPersistentKeepAlive(String)
        case peerHasInvalidTransferBytes(String)
        case peerHasInvalidLastHandshakeTime(String)
        case peerHasUnrecognizedKey(String)
        case multiplePeersWithSamePublicKey
        case multipleEntriesForKey(String)
    }

    convenience init(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) throws {
        var interfaceConfiguration: InterfaceConfiguration?
        var peerConfigurations = [PeerConfiguration]()

        let lines = wgQuickConfig.split { $0.isNewline }

        var parserState = ParserState.notInASection
        var attributes = [String: String]()

        for (lineIndex, line) in lines.enumerated() {
            var trimmedLine: String
            if let commentRange = line.range(of: "#") {
                trimmedLine = String(line[..<commentRange.lowerBound])
            } else {
                trimmedLine = String(line)
            }

            trimmedLine = trimmedLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercasedLine = trimmedLine.lowercased()

            if !trimmedLine.isEmpty {
                if let equalsIndex = trimmedLine.firstIndex(of: "=") {
                    // Line contains an attribute
                    let keyWithCase = trimmedLine[..<equalsIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    let key = keyWithCase.lowercased()
                    let value = trimmedLine[trimmedLine.index(equalsIndex, offsetBy: 1)...].trimmingCharacters(in: .whitespacesAndNewlines)
                    let keysWithMultipleEntriesAllowed: Set<String> = ["address", "allowedips", "dns"]
                    if let presentValue = attributes[key] {
                        if keysWithMultipleEntriesAllowed.contains(key) {
                            attributes[key] = presentValue + "," + value
                        } else {
                            throw ParseError.multipleEntriesForKey(keyWithCase)
                        }
                    } else {
                        attributes[key] = value
                    }
                    let interfaceSectionKeys: Set<String> = [
                        "privatekey", "listenport", "address", "dns", "mtu",
                        "jc", "jmin", "jmax",
                        "s1", "s2", "s3", "s4",
                        "h1", "h2", "h3", "h4",
                        "i1", "i2", "i3", "i4", "i5"
                    ]
                    let peerSectionKeys: Set<String> = ["publickey", "presharedkey", "allowedips", "endpoint", "persistentkeepalive"]
                    if parserState == .inInterfaceSection {
                        guard interfaceSectionKeys.contains(key) else {
                            throw ParseError.interfaceHasUnrecognizedKey(keyWithCase)
                        }
                    } else if parserState == .inPeerSection {
                        guard peerSectionKeys.contains(key) else {
                            throw ParseError.peerHasUnrecognizedKey(keyWithCase)
                        }
                    }
                } else if lowercasedLine != "[interface]" && lowercasedLine != "[peer]" {
                    throw ParseError.invalidLine(line)
                }
            }

            let isLastLine = lineIndex == lines.count - 1

            if isLastLine || lowercasedLine == "[interface]" || lowercasedLine == "[peer]" {
                // Previous section has ended; process the attributes collected so far
                if parserState == .inInterfaceSection {
                    let interface = try TunnelConfiguration.collate(interfaceAttributes: attributes)
                    guard interfaceConfiguration == nil else { throw ParseError.multipleInterfaces }
                    interfaceConfiguration = interface
                } else if parserState == .inPeerSection {
                    let peer = try TunnelConfiguration.collate(peerAttributes: attributes)
                    peerConfigurations.append(peer)
                }
            }

            if lowercasedLine == "[interface]" {
                parserState = .inInterfaceSection
                attributes.removeAll()
            } else if lowercasedLine == "[peer]" {
                parserState = .inPeerSection
                attributes.removeAll()
            }
        }

        let peerPublicKeysArray = peerConfigurations.map { $0.publicKey }
        let peerPublicKeysSet = Set<PublicKey>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            throw ParseError.multiplePeersWithSamePublicKey
        }

        if let interfaceConfiguration = interfaceConfiguration {
            self.init(name: name, interface: interfaceConfiguration, peers: peerConfigurations)
        } else {
            throw ParseError.noInterface
        }
    }

    func asWgQuickConfig() -> String {
        var output = "[Interface]\n"
        output.append("PrivateKey = \(interface.privateKey.base64Key)\n")
        if let listenPort = interface.listenPort {
            output.append("ListenPort = \(listenPort)\n")
        }
        if let Jc = interface.Jc {
            output.append("Jc = \(Jc)\n")
        }
        if let Jmin = interface.Jmin {
            output.append("Jmin = \(Jmin)\n")
        }
        if let Jmax = interface.Jmax {
            output.append("Jmax = \(Jmax)\n")
        }
        if let S1 = interface.S1 {
            output.append("S1 = \(S1)\n")
        }
        if let S2 = interface.S2 {
            output.append("S2 = \(S2)\n")
        }
        if let S3 = interface.S3 {
            output.append("S3 = \(S3)\n")
        }
        if let S4 = interface.S4 {
            output.append("S4 = \(S4)\n")
        }
        if let H1 = interface.H1 {
            output.append("H1 = \(H1)\n")
        }
        if let H2 = interface.H2 {
            output.append("H2 = \(H2)\n")
        }
        if let H3 = interface.H3 {
            output.append("H3 = \(H3)\n")
        }
        if let H4 = interface.H4 {
            output.append("H4 = \(H4)\n")
        }
        if let I1 = interface.I1 {
            output.append("I1 = \(I1)\n")
        }
        if let I2 = interface.I2 {
            output.append("I2 = \(I2)\n")
        }
        if let I3 = interface.I3 {
            output.append("I3 = \(I3)\n")
        }
        if let I4 = interface.I4 {
            output.append("I4 = \(I4)\n")
        }
        if let I5 = interface.I5 {
            output.append("I5 = \(I5)\n")
        }
        if !interface.addresses.isEmpty {
            let addressString = interface.addresses.map { $0.stringRepresentation }.joined(separator: ", ")
            output.append("Address = \(addressString)\n")
        }
        if !interface.dns.isEmpty || !interface.dnsSearch.isEmpty {
            var dnsLine = interface.dns.map { $0.stringRepresentation }
            dnsLine.append(contentsOf: interface.dnsSearch)
            let dnsString = dnsLine.joined(separator: ", ")
            output.append("DNS = \(dnsString)\n")
        }
        if let mtu = interface.mtu {
            output.append("MTU = \(mtu)\n")
        }

        for peer in peers {
            output.append("\n[Peer]\n")
            output.append("PublicKey = \(peer.publicKey.base64Key)\n")
            if let preSharedKey = peer.preSharedKey?.base64Key {
                output.append("PresharedKey = \(preSharedKey)\n")
            }
            if !peer.allowedIPs.isEmpty {
                let allowedIPsString = peer.allowedIPs.map { $0.stringRepresentation }.joined(separator: ", ")
                output.append("AllowedIPs = \(allowedIPsString)\n")
            }
            if let endpoint = peer.endpoint {
                output.append("Endpoint = \(endpoint.stringRepresentation)\n")
            }
            if let persistentKeepAlive = peer.persistentKeepAlive {
                output.append("PersistentKeepalive = \(persistentKeepAlive)\n")
            }
        }

        return output
    }

    private static func collate(interfaceAttributes attributes: [String: String]) throws -> InterfaceConfiguration {
        guard let privateKeyString = attributes["privatekey"] else {
            throw ParseError.interfaceHasNoPrivateKey
        }
        guard let privateKey = PrivateKey(base64Key: privateKeyString) else {
            throw ParseError.interfaceHasInvalidPrivateKey(privateKeyString)
        }
        var interface = InterfaceConfiguration(privateKey: privateKey)
        if let listenPortString = attributes["listenport"] {
            guard let listenPort = UInt16(listenPortString) else {
                throw ParseError.interfaceHasInvalidListenPort(listenPortString)
            }
            interface.listenPort = listenPort
        }
        if let addressesString = attributes["address"] {
            var addresses = [IPAddressRange]()
            for addressString in addressesString.splitToArray(trimmingCharacters: .whitespacesAndNewlines) {
                guard let address = IPAddressRange(from: addressString) else {
                    throw ParseError.interfaceHasInvalidAddress(addressString)
                }
                addresses.append(address)
            }
            interface.addresses = addresses
        }
        if let dnsString = attributes["dns"] {
            var dnsServers = [DNSServer]()
            var dnsSearch = [String]()
            for dnsServerString in dnsString.splitToArray(trimmingCharacters: .whitespacesAndNewlines) {
                if let dnsServer = DNSServer(from: dnsServerString) {
                    dnsServers.append(dnsServer)
                } else {
                    dnsSearch.append(dnsServerString)
                }
            }
            interface.dns = dnsServers
            interface.dnsSearch = dnsSearch
        }
        if let mtuString = attributes["mtu"] {
            guard let mtu = UInt16(mtuString) else {
                throw ParseError.interfaceHasInvalidMTU(mtuString)
            }
            interface.mtu = mtu
        }
        if let JcString = attributes["jc"] {
            guard let jc = UInt16(JcString) else {
                throw ParseError.interfaceHasInvalidCustomParam(JcString)
            }
            interface.Jc = jc
        }
        if let JminString = attributes["jmin"] {
            guard let jmin = UInt16(JminString) else {
                throw ParseError.interfaceHasInvalidCustomParam(JminString)
            }
            interface.Jmin = jmin
        }
        if let JmaxString = attributes["jmax"] {
            guard let jmax = UInt16(JmaxString) else {
                throw ParseError.interfaceHasInvalidCustomParam(JmaxString)
            }
            interface.Jmax = jmax
        }
        if let S1String = attributes["s1"] {
            guard let s1 = UInt16(S1String) else {
                throw ParseError.interfaceHasInvalidCustomParam(S1String)
            }
            interface.S1 = s1
        }
        if let S2String = attributes["s2"] {
            guard let s2 = UInt16(S2String) else {
                throw ParseError.interfaceHasInvalidCustomParam(S2String)
            }
            interface.S2 = s2
        }
        if let S3String = attributes["s3"] {
            guard let s3 = UInt16(S3String) else {
                throw ParseError.interfaceHasInvalidCustomParam(S3String)
            }
            interface.S3 = s3
        }
        if let S4String = attributes["s4"] {
            guard let s4 = UInt16(S4String) else {
                throw ParseError.interfaceHasInvalidCustomParam(S4String)
            }
            interface.S4 = s4
        }
        if let H1String = attributes["h1"] {
            interface.H1 = try TunnelConfiguration.collate(customString: H1String)
        }
        if let H2String = attributes["h2"] {
            interface.H2 = try TunnelConfiguration.collate(customString: H2String)
        }
        if let H3String = attributes["h3"] {
            interface.H3 = try TunnelConfiguration.collate(customString: H3String)
        }
        if let H4String = attributes["h4"] {
            interface.H4 = try TunnelConfiguration.collate(customString: H4String)
        }
        if let I1String = attributes["i1"] {
            interface.I1 = try TunnelConfiguration.collate(customString: I1String)
        }
        if let I2String = attributes["i2"] {
            interface.I2 = try TunnelConfiguration.collate(customString: I2String)
        }
        if let I3String = attributes["i3"] {
            interface.I3 = try TunnelConfiguration.collate(customString: I3String)
        }
        if let I4String = attributes["i4"] {
            interface.I4 = try TunnelConfiguration.collate(customString: I4String)
        }
        if let I5String = attributes["i5"] {
            interface.I5 = try TunnelConfiguration.collate(customString: I5String)
        }
        return interface
    }

    private static func collate(customString value: String) throws -> String {
        guard !value.isEmpty else {
            throw ParseError.interfaceHasInvalidCustomParam(value)
        }
        return value
    }

    private static func collate(peerAttributes attributes: [String: String]) throws -> PeerConfiguration {
        guard let publicKeyString = attributes["publickey"] else {
            throw ParseError.peerHasNoPublicKey
        }
        guard let publicKey = PublicKey(base64Key: publicKeyString) else {
            throw ParseError.peerHasInvalidPublicKey(publicKeyString)
        }
        var peer = PeerConfiguration(publicKey: publicKey)
        if let preSharedKeyString = attributes["presharedkey"] {
            guard let preSharedKey = PreSharedKey(base64Key: preSharedKeyString) else {
                throw ParseError.peerHasInvalidPreSharedKey(preSharedKeyString)
            }
            peer.preSharedKey = preSharedKey
        }
        if let allowedIPsString = attributes["allowedips"] {
            var allowedIPs = [IPAddressRange]()
            for allowedIPString in allowedIPsString.splitToArray(trimmingCharacters: .whitespacesAndNewlines) {
                guard let allowedIP = IPAddressRange(from: allowedIPString) else {
                    throw ParseError.peerHasInvalidAllowedIP(allowedIPString)
                }
                allowedIPs.append(allowedIP)
            }
            peer.allowedIPs = allowedIPs
        }
        if let endpointString = attributes["endpoint"] {
            guard let endpoint = Endpoint(from: endpointString) else {
                throw ParseError.peerHasInvalidEndpoint(endpointString)
            }
            peer.endpoint = endpoint
        }
        if let persistentKeepAliveString = attributes["persistentkeepalive"] {
            guard let persistentKeepAlive = UInt16(persistentKeepAliveString) else {
                throw ParseError.peerHasInvalidPersistentKeepAlive(persistentKeepAliveString)
            }
            peer.persistentKeepAlive = persistentKeepAlive
        }
        return peer
    }

}
