// SPDX-License-Identifier: MIT
// Copyright © 2018-2021 WireGuard LLC. All Rights Reserved.

import Foundation
import Network

public struct InterfaceConfiguration {
    public var privateKey: PrivateKey
    public var addresses = [IPAddressRange]()
    public var Jc: UInt16?
    public var Jmin: UInt16?
    public var Jmax: UInt16?
    public var S1: UInt16?
    public var S2: UInt16?
    public var S3: UInt16?
    public var S4: UInt16?
    public var H1: String?
    public var H2: String?
    public var H3: String?
    public var H4: String?
    public var I1: String?
    public var I2: String?
    public var I3: String?
    public var I4: String?
    public var I5: String?
    public var listenPort: UInt16?
    public var mtu: UInt16?
    public var dns = [DNSServer]()
    public var dnsSearch = [String]()

    public init(privateKey: PrivateKey) {
        self.privateKey = privateKey
    }
}

extension InterfaceConfiguration: Equatable {
    public static func == (lhs: InterfaceConfiguration, rhs: InterfaceConfiguration) -> Bool {
        let lhsAddresses = lhs.addresses.filter { $0.address is IPv4Address } + lhs.addresses.filter { $0.address is IPv6Address }
        let rhsAddresses = rhs.addresses.filter { $0.address is IPv4Address } + rhs.addresses.filter { $0.address is IPv6Address }

        return lhs.privateKey == rhs.privateKey &&
            lhsAddresses == rhsAddresses &&
            lhs.Jc == rhs.Jc &&
            lhs.Jmin == rhs.Jmin &&
            lhs.Jmax == rhs.Jmax &&
            lhs.S1 == rhs.S1 &&
            lhs.S2 == rhs.S2 &&
            lhs.S3 == rhs.S3 &&
            lhs.S4 == rhs.S4 &&
            lhs.H1 == rhs.H1 &&
            lhs.H2 == rhs.H2 &&
            lhs.H3 == rhs.H3 &&
            lhs.H4 == rhs.H4 &&
            lhs.I1 == rhs.I1 &&
            lhs.I2 == rhs.I2 &&
            lhs.I3 == rhs.I3 &&
            lhs.I4 == rhs.I4 &&
            lhs.I5 == rhs.I5 &&
            lhs.listenPort == rhs.listenPort &&
            lhs.mtu == rhs.mtu &&
            lhs.dns == rhs.dns &&
            lhs.dnsSearch == rhs.dnsSearch
    }
}
