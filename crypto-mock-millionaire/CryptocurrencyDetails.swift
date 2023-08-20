//
//  CryptocurrencyDetails.swift
//  crypto-mock-millionaire
//
//  Created by Adam Pagels on 2023-08-20.
//

import SwiftUI

struct CryptocurrencyDetails: View {
    let cryptocurrency: String

    var body: some View {
        if !cryptocurrency.isEmpty {
            Text(cryptocurrency)
        } else {
            Text("Bitcoin")
        }
    }
}

struct CryptocurrencyDetails_Previews: PreviewProvider {
    static var previews: some View {
        CryptocurrencyDetails(cryptocurrency: String())
    }
}
