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
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .onTapGesture {
                                if let link = item.link {
                                    openURL(link)
                                }
                            }
                    }
                    
                    if rssFeed.isLoading {
                        NewsFeedSkeleton()
                    }
                }
                .padding(.top, 19)
                .refreshable {
                    rssFeed.fetchRSSFeed()
                }
                .listStyle(.plain)
                .navigationTitle("Discover")
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
                    .font(.satoshi(size: 18, weight: .heavy))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 16)
                    Spacer()
            }
            .overlay(alignment: .topTrailing) {
                Image("feed_open_icon")
            }
            
            RSSPostPreview(item, size: size)
                .cornerRadius(16)
            
            Text(item.description)
                .font(.satoshi(size: 14, weight: .regular))
                .lineLimit(3)
                .truncationMode(.tail)
                .lineSpacing(5)
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
        .background(Color(red: 0.17, green: 0.19, blue: 0.2).opacity(0.3))
        .cornerRadius(16)
    }
    
    private func RSSPostPreview(_ item: RSSItem, size: CGSize) -> some View {
        WebImage(url: item.contentURL ?? item.thumbnailURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ProgressView()
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(width: size.width - 64)
        .frame(height: size.width * 0.4)
        .clipped()
    }
}

#Preview {
    NewsFeed()
}

struct NewsFeedSkeleton: View {
    var body: some View {
        ForEach(0..<5) { _ in
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 15)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(Color(red: 0.17, green: 0.19, blue: 0.2).opacity(0.3))
            .cornerRadius(16)
            .redacted(reason: .placeholder)
        }
    }
}
