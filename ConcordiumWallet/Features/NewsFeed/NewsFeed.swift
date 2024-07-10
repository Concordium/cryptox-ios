//
//  NewsFeed.swift
//  CryptoX
//
//  Created by Max on 10.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct NewsFeed: View {
    @StateObject var rssFeed = RSSFeed()
    @SwiftUI.Environment(\.openURL) var openURL
        
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                List {
                    ForEach(rssFeed.items) { item in
                        RSSItemView(item, size: proxy.size)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                if let link = item.link {
                                    openURL(link)
                                }
                            }
                    }
                    
                    if rssFeed.isLoading {
                        HStack(alignment: .center) {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .refreshable {
                    rssFeed.fetchRSSFeed()
                }
                .listStyle(.plain)
                .navigationTitle("Concordium News")
                .onAppear {
                    rssFeed.fetchRSSFeed()
                }
                .clipped()
            }
            .modifier(AppBackgroundModifier())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func RSSItemView(_ item: RSSItem, size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12){
                Text(item.title)
                    .font(.satoshi(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 16)
                    Spacer()
            }
            .overlay(alignment: .topTrailing) {
                Image("feed_open_icon")
            }
            
            RSSPostPreview(item, size: size)
            
            Text(item.description)
                .font(.satoshi(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .opacity(item.description.isEmpty ? 0 : 1.0)
            
            Text(item.pubDate, style: .date)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.62, green: 0.67, blue: 0.66))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color(red: 0.08, green: 0.1, blue: 0.11))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color(red: 0.16, green: 0.2, blue: 0.23), lineWidth: 1)
        )
    }
    
    private func RSSPostPreview(_ item: RSSItem, size: CGSize) -> some View {
        WebImage(url: item.contentURL ?? item.thumbnailURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
        } placeholder: {
            ProgressView()
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity)
        .frame(height: size.width * 0.6)
    }
}

#Preview {
    NewsFeed()
}
