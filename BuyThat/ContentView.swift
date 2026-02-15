//
//  ContentView.swift
//  BuyThat
//
//  Created by James Maguire on 30.11.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ToBuyView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Product.self,
            ProductVariant.self,
            Brand.self,
            Store.self,
            Tag.self,
            StoreVariantInfo.self,
            ToBuyItem.self,
            ItemList.self,
            ItemListEntry.self
        ], inMemory: true)
}
