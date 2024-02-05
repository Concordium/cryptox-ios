//
//  PageIndicator.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 25/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int
    
    private struct PageIndex: Identifiable {
        let page: Int
        let selected: Bool
        let isFilled: Bool
        
        var id: Int { page }
    }
    
    private var pages: [PageIndex] {
        (0..<numberOfPages).map { page in
            PageIndex(page: page, selected: page == currentPage, isFilled: page < currentPage)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(pages) { page in
                if page.page > 0 {
                    Rectangle()
                        .frame(width: 24, height: 2)
                }
                ZStack {
                    if page.selected {
                        Circle()
                            .frame(width: 16, height: 16)
                    }
                    PageDot(selected: page.selected, isFilled: page.isFilled)
                        .frame(width: 10, height: 10)
                        .foregroundColor(page.selected ? .white : .blackAditional)
                }
            }
        }.foregroundColor(.blackAditional)
    }
}

private struct PageDot: Shape {
    let selected: Bool
    let isFilled: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = Path(ellipseIn: rect)
        
        if selected {
            return path
        } else if isFilled {
            return path
        } else {
            return path.strokedPath(.init(lineWidth: 2))
        }
    }
}

struct PageIndicator_Previews: PreviewProvider {
    static var previews: some View {
        PageIndicator(numberOfPages: 4, currentPage: 2)
    }
}
