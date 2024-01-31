//
//  SwiftRater+SwiftUI.swift
//  SwiftRater
//
//  Created by Emil Landron on 1/31/24.
//  Copyright © 2024 com.takecian. All rights reserved.
//

import SwiftUI
import StoreKit

@MainActor
final class SwiftRaterAlertPresenterImplementation: SwiftRaterAlertPresenter, ObservableObject {
    
    @Published var alert: SwiftRaterAlert?
    var requestReviewHandler: (() -> Void)?
    
    func present(_ alert: SwiftRaterAlert) {
        self.alert = alert
    }
    
    func requestReview() {
        requestReviewHandler?()
    }
}

struct SwiftRaterViewModifier: ViewModifier {
    
    @StateObject private var alertPresenter = SwiftRaterAlertPresenterImplementation()
    @State private var sheetContentHeight: CGFloat = 0

    @Environment(\.requestReview) var requestReview
    
    private var isSwiftRateAlertPresented: Binding<Bool> {
        .init {
            alertPresenter.alert != nil
        } set: { isPresented in
            guard !isPresented else { return }
            alertPresenter.alert = nil
        }
    }

    func body(content: Content) -> some View {
        
        content
            .task {
                alertPresenter.requestReviewHandler = {
                    requestReview()
                }
                SwiftRater.alertPresenter = alertPresenter
            }
            .sheet(item: $alertPresenter.alert) { alert in
                
                VStack(alignment: .leading, spacing: 44) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(alert.title)
                            .font(.title3)
                            .bold()
                        
                        Text(alert.message)
                            .frame(minHeight: 64)
                    }
                    
                    VStack(spacing: 16) {
                        
                        if let laterAction = alert.laterAction {
                            Button(laterAction.title) {
                                laterAction.handler()
                                alertPresenter.alert = nil
                            }
                        }
                        else {
                            Button(alert.cancelAction.title) {
                                alert.cancelAction.handler()
                                alertPresenter.alert = nil
                            }
                        }
                        
                        Button {
                            alert.rateAction.handler()
                            alertPresenter.alert = nil
                        } label: {
                            Text(alert.rateAction.title)
                                .fixedSize(horizontal: true, vertical: true)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .controlSize(.large)
                .background {
                    //This is done in the background otherwise GeometryReader tends to expand to all the space given to it like color or shape.
                    GeometryReader { proxy in
                        Color.clear
                            .task {
                                sheetContentHeight = proxy.size.height + 20
                            }
                    }
                }
                .presentationDetents([.height(sheetContentHeight)])
                .interactiveDismissDisabled()
            }
    }
}

public extension View {
    
    func configureSwiftRaterAlertPresenter() -> some View {
        self
            .modifier(SwiftRaterViewModifier())
    }
}

#Preview {
    
    Group {
        if #available(iOS 16.0, *) {
            List {
                
            }
            .configureSwiftRaterAlertPresenter()
            .task {
                SwiftRater.shouldShowRequestNextSignificantEvent = true
                SwiftRater.check()
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
