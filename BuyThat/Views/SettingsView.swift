//
//  SettingsView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ManageTagsView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Tags")
                            Text("Categorize products")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "tag.fill")
                    }
                }

                NavigationLink {
                    ManageBrandsView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Brands")
                            Text("Product manufacturers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "building.2.fill")
                    }
                }

                NavigationLink {
                    ManageProductsView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Products")
                            Text("Base product types")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "cube.fill")
                    }
                }

                NavigationLink {
                    ManageProductVariantsView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Product Variants")
                            Text("Sizes and quantities")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.stack.3d.up.fill")
                    }
                }
            } header: {
                Text("Products")
            }

            Section {
                NavigationLink {
                    ManageStoresView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Stores")
                            Text("Shopping locations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "storefront.fill")
                    }
                }

                NavigationLink {
                    ManageStoreVariantInfoView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Store Items")
                            Text("Products with prices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "cart.fill")
                    }
                }
            } header: {
                Text("Stores")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewContainer.sample)
}

