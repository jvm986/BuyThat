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
                    ManageItemListsView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Lists")
                            Text("Reusable template lists")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
                .accessibilityIdentifier("ListsButton")
            } header: {
                Text("Lists")
            }

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
                .accessibilityIdentifier("TagsButton")

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
                .accessibilityIdentifier("BrandsButton")

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
                .accessibilityIdentifier("ProductsButton")

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
                .accessibilityIdentifier("ProductVariantsButton")
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
                .accessibilityIdentifier("StoresButton")

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
                .accessibilityIdentifier("StoreItemsButton")
            } header: {
                Text("Stores")
            }
            Section {
                NavigationLink {
                    PurchaseHistoryView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Purchase History")
                            Text("Past shopping trips")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                .accessibilityIdentifier("PurchaseHistoryButton")
            } header: {
                Text("Purchase History")
            }

            Section {
                NavigationLink {
                    APIKeyManagementView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Receipt Scanning")
                            Text("OpenAI API key for receipt analysis")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "doc.text.viewfinder")
                    }
                }
                .accessibilityIdentifier("ReceiptScanningButton")
            } header: {
                Text("Receipt Scanning")
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

