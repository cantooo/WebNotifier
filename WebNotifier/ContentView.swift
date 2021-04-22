//
//  ContentView.swift
//  WebNotifier
//
//  Created by Simone Cantoni on 05/04/21.
//

import SwiftUI

struct Url: Hashable {
    var url:String
    var id = UUID()
}

struct ContentView: View {
    @State var input:String = ""
    @State var urls:[Url] = []
    
    var body: some View {
        NavigationView(content: {
            Form(content: {
                Section(header: Text("INSERIMENTO")) {
                    TextField("URL da controllare", text: $input)
                    Button("Inizia a controllare") {
                        if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            urls.append(Url(url: input))
                        }
                        input = ""
                    }
                }
                Section(header: Text("CONTROLLO IN CORSO")) {
                    List{
                        ForEach(urls, id: \.self) { e in
                            Text(e.url)
                        }.onDelete(perform: { indexSet in
                            urls.remove(atOffsets: indexSet)
                        })
                    }
                }
            })
            .navigationTitle("WebNotifier")
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
