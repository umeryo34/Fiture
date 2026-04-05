//
//  RunView.swift
//  Fiture
//
//  Created by 梅澤遼 on 2025/02/02.
//

import SwiftUI

struct RunView: View {
    @State private var showingRunSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Run")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 20) {
                    Image("run")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    Text("モードを選んでRunを開始")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Button(action: {
                        showingRunSession = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                            Text("Runを開始")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingRunSession) {
            RunModeSelectionView()
        }
    }
}

#Preview {
    RunView()
}
