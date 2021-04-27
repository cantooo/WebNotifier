//
//  ContentView.swift
//  WebNotifier
//
//  Created by Simone Cantoni on 05/04/21.
//

import SwiftUI

let userDefaults = UserDefaults.standard
let urlsKey = "WebNotifierUrls"
let htmlsKey = "WebNotifierHTMLs"

struct ContentView: View {
    @State var input = ""
    @State var urls:[String] = userDefaults.stringArray(forKey: urlsKey) ?? []
    @State var htmls:[String] = userDefaults.stringArray(forKey: htmlsKey) ?? []
    @State var incorrectUrlAlert = false
    @State var changedUrlAlert = false
    @State var changedUrl = ""
    
    var body: some View {
        NavigationView(content: {
            Form(content: {
                Section(header: Text("INSERIMENTO")) {
                    TextField("URL da controllare", text: $input)
                    Button("Inizia a controllare") {
                        let url = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        
                        if !url.isEmpty {
                            let html = fetchHTML(at: url) ?? ""
                            if html == "" {
                                incorrectUrlAlert.toggle()
                            } else {
                                urls.append(url)
                                userDefaults.set(urls, forKey: urlsKey)
                                htmls.append(html)
                                userDefaults.set(htmls, forKey: htmlsKey)
                            }
                        }
                        input = ""
                    }.alert(isPresented: $incorrectUrlAlert) {
                        Alert(title: Text("URL errato"), message: Text("L'URL fornito non sembra corrispondere a un URL valido."), dismissButton: .default(Text("Ok")))
                    }
                }
                Section(header: Text("CONTROLLO IN CORSO")) {
                    Button("Controlla modifiche") {
                        checkChangesInApp()
                    }.alert(isPresented: $changedUrlAlert, content: {
                        Alert(title: Text("La pagina è cambiata"), message: Text("La pagina \(changedUrl) è cambiata."), dismissButton: .default(Text("Ok")))
                    })
                    List{
                        ForEach(urls, id: \.self) { e in
                            Text(e)
                                .contextMenu {
                                    Button {
                                        if let url = URL(string: e) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        Label("Apri", systemImage: "safari")
                                    }
                                }
                        }.onDelete(perform: { indexSet in
                            urls.remove(atOffsets: indexSet)
                            userDefaults.set(urls, forKey: urlsKey)
                            htmls.remove(atOffsets: indexSet)
                            userDefaults.set(htmls, forKey: htmlsKey)
                        })
                    }
                }
            })
            .navigationTitle("WebNotifier")
        })
    }
    
//  Fetches the HTML of the webpage at the given url
    func fetchHTML (at url: String)->String? {
        var html = ""
        
        do {
            html = try String(contentsOf: URL(string: url)!)
        } catch let error {
            print(error.localizedDescription)
            print("Non sono riuscito a caricare la pagina", url, ".")
            return nil
        }
        
        return html
    }
    
//  Fetches every HTML of every URL and checkes for changes, appearing as an inapp Alert
//  Need to find a solution for dynamic webpages
    func checkChangesInApp() {
        changedUrl = ""
        
        for i in 0..<urls.count {
            let url = urls[i]
            let htmlNew = fetchHTML(at: url) ?? ""
            let htmlOld = htmls[i]
            
            if htmlNew != "" && htmlNew != htmlOld {
                htmls[i] = htmlNew
                userDefaults.set(htmls, forKey: htmlsKey)
                
                if !changedUrlAlert {
                    changedUrlAlert.toggle()
                }
                
                changedUrl += "\(url), "
            }
        }
        
        if changedUrl != "" {
            changedUrl.popLast()
            changedUrl.popLast()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
