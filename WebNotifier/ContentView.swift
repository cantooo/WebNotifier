//
//  ContentView.swift
//  WebNotifier
//
//  Created by Simone Cantoni on 05/04/21.
//

import SwiftUI

let userDefaults = UserDefaults.standard
let urlsKey = "WebNotifierUrls"

struct ContentView: View {
    @State var input:String = ""
    @State var urls:[String] = userDefaults.object(forKey: urlsKey) as? [String] ?? []
    @State var alert = false
    
    var body: some View {
        NavigationView(content: {
            Form(content: {
                Section(header: Text("INSERIMENTO")) {
                    TextField("URL da controllare", text: $input)
                    Button("Inizia a controllare") {
                        let url = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        
                        if !url.isEmpty {
                            if !checkWebpage(at: url) {
                                alert.toggle()
                            } else {
                                urls.append(url)
                                userDefaults.set(urls, forKey: urlsKey)
                            }
                        }
                        input = ""
                    }.alert(isPresented: $alert) {
                        Alert(title: Text("URL errato"), message: Text("L'URL fornito non sembra corrispondere a un URL valido."), dismissButton: .default(Text("Ok")))
                    }
                }
                Section(header: Text("CONTROLLO IN CORSO")) {
                    List{
                        ForEach(urls, id: \.self) { e in
                            Text(e)
                        }.onDelete(perform: { indexSet in
                            urls.remove(atOffsets: indexSet)
                            userDefaults.set(urls, forKey: urlsKey)
                        })
                    }
                }
            })
            .navigationTitle("WebNotifier")
        })
    }
    
    func checkWebpage (at url:String)->Bool {
        let html = fetchHTML(at: url) ?? ""
        
        if html != "" {
            return true
        }
        
        return false
    }
    
//  Fetches the HTML of the webpage at the given url
    func fetchHTML (at url: String)->String? {
        var html = ""
        
        do {
            html = try String(contentsOf: URL(string: url)!, encoding: .ascii)
        } catch let error {
            print(error.localizedDescription)
            print("Non sono riuscito a caricare la pagina", url, ".")
            return nil
        }
        
        return html
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
